# The truck: the jade green 1978 F-250 Camper Special, drawn, sat in and driven (game/truck_sim.gd
# is the physics, game/truck_sound.gd its sound, world/island_road.gd the road). The first slice of
# the design in "LAST CALL: the truck and the island road": it's in the Sov's lot at night, in the
# rain, and he can drive it out onto the highway, north past the motel and over the bluff to the
# mill road, or south past the church and up through the cut to the ferry sign. Nothing on the
# screen helps him hold it. The gauges are in the dash.
#
# The controls (on the keys card, game/keys_card.gd, like every toy; F1 brings it back):
#   W / up        the gas         S / down    the brake (no ABS: stand on it and they lock)
#   A D / left right   the wheel  (four turns lock to lock; let go and it comes back)
#   R / F         the column shifter up toward P / down toward 1     E   the key
#   L             the headlights, H the high beams     V the wipers     Space the horn
#   the mouse     his head round the cab, out the side window, into the mirror
#   C             his eyes in the cab / behind the truck (the rehearsal's view)
#   Esc           park it and get out
# A gamepad: right trigger the gas, left trigger the brake, the left stick the wheel.
class_name Truck
extends Node

signal left

const KEYS_ROWS := [["E", "the key (in P or N)"], ["R / F", "the shifter, up toward P, down toward 1"],
	["W / S", "gas / brake"], ["A / D", "the wheel"], ["L  H  V", "lights, high beams, wipers"],
	["Space", "the horn"], ["Mouse", "his head round the cab"], ["C", "in the cab / behind the truck"]]

const EYE := Vector3(-0.40, 0.80, 0.16)         # his eyes on the bench seat: six foot four, his hair near the headliner
const PARK_AT := Vector3(4.0, 0.0, 21.0)        # where it's parked in the lot, nose to the highway
const JADE := Color("3f6f55")
const SELECTOR := ["P", "R", "N", "D", "2", "1"]
const MPH := 2.23694
# the headlamps' light on the road: brightest a few metres out, gone by the far end, a soft edge
const BEAM_POOL := """shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float energy = 0.0;
void fragment() {
	if ((CAMERA_VISIBLE_LAYERS & 524288u) != 0u) {
		discard;
	}
	float along = 1.0 - UV.y;
	float across = abs(UV.x - 0.5) * 2.0;
	float spread = mix(0.55, 1.0, along);
	float k = clamp(1.0 - across / spread, 0.0, 1.0);
	float fall = smoothstep(0.0, 0.08, along) * pow(1.0 - along, 1.6);
	ALBEDO = tint.rgb * energy * k * k * fall;
}
"""

var main
var pub: Pub
var view: View
var road: IslandRoad
var sim: TruckSim
var sound: TruckSound
var body: Node3D                 # the truck, at the sim's middle of mass
var wheels: Array = []           # [steer pivot, spinning tire]
var wheel_node: Node3D           # the steering wheel
var needle: Node3D
var fuel_needle: Node3D
var temp_needle: Node3D
var prnd: Label3D
var beams: Array = []
var beam_pools: Array = []        # low, high: the light on the road ahead, printed as a pool
var head_glow: Array = []
var tail_glow: Array = []
var dash_light: OmniLight3D
var dome: OmniLight3D
var wipers: Array = []
var black: ColorRect
var active := false
var rehearsal := false
var chase := false
var lights := 1                  # 0 off, 1 on
var high := false
var wipe := true
var _wipe_t := 0.0
var _acc := 0.0
var _gas := 0.0
var _brk := 0.0
var _sel := 0
var _t := 0.0
var _blank := 0.0                # a lost second or two, drunk
var _next_blank := 30.0
var _chase_pos := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var traffic: Array = []
var _rain: AudioStreamPlayer
var M := {}


func setup(m) -> void:
	main = m
	pub = m.pub
	view = m.view
	process_priority = -10
	set_process(false)
	set_process_input(false)
	sound = TruckSound.new()
	add_child(sound)
	_rng.randomize()


func _build_once() -> void:
	if road != null:
		return
	road = IslandRoad.new()
	road.name = "island_road"
	pub.add_child(road)
	road.build_for(pub)
	sim = TruckSim.new()
	sim.ground = road.ground
	_build_truck()
	_build_traffic()
	black = ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.root.add_child(black)
	_rain = AudioStreamPlayer.new()
	# the rain on the roof: the room's own take of it, its own copy, looped
	var st = main.audio._stream("rain_roof", 0)
	if st == null:
		st = main.audio._stream("amb_rain_roof", 0)
	if st != null:
		st = main.audio._looping(st.duplicate())
	_rain.stream = st
	_rain.volume_db = -14.0
	add_child(_rain)


# ---------------------------------------------------------------- in and out

func begin(rehearse := true, from := {}) -> void:
	_build_once()
	active = true
	rehearsal = rehearse
	var drinks := int(from.get("drinks", 0))
	view.drinks = drinks
	view.hurt = int(from.get("hurt", 0))
	view.tension = int(from.get("tension", 0))
	sim.drunk = clampf((drinks - 2) / 7.0, 0.0, 1.0)
	sim.wet = true
	road.rain_on = true
	view.jump_to("lot")
	view.daylight(1300, true)
	pub.town.set_outdoors(true)
	pub.grounds.visible = true
	view.ride = body
	view.ride_eye = EYE
	view.yaw = 0.0
	view.pitch = -0.08
	view.want_yaw = 0.0
	view.want_pitch = -0.08
	view.focus_fov = 0.0
	sim.selector = "P"
	_sel = 0
	sim.running = false
	sim.throttle = 0.0
	sim.brake = 0.0
	sim.place(PARK_AT + Vector3(0, 0, 0), PI)
	sim.running = false
	sim.rpm = 0.0
	_sync_body()
	lights = 0
	high = false
	wipe = false
	chase = false
	_lights()
	body.visible = true
	main.lay_out(1.0)
	main.column.visible = false
	main.audio.unlock()
	main.audio.ambience("none")
	main.audio.place("lot", 1300)
	main.audio.out_mix = {"rain_out": 0.25, "sea": 0.15}
	main.audio._mix()
	sound.wet = true
	sound.start()
	sound.running = false
	if _rain.stream != null:
		_rain.play()
	main.keys.show_for("truck", KEYS_ROWS, "In the cab")
	_next_blank = _rng.randf_range(25.0, 50.0)
	for c in traffic:
		_spawn_car(c, true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_process(true)
	set_process_input(true)


func end() -> void:
	if not active:
		return
	active = false
	set_process(false)
	set_process_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	view.ride = null
	sound.stop()
	_rain.stop()
	main.keys.hide_card()
	black.color.a = 0.0
	main.column.visible = true
	main.lay_out(View.WORLD_W)
	pub.town.set_outdoors(false)
	for c in traffic:
		(c.node as Node3D).visible = false
	left.emit()


# ---------------------------------------------------------------- his hands and feet

func _input(e: InputEvent) -> void:
	if not active:
		return
	if e is InputEventMouseMotion:
		var m := e as InputEventMouseMotion
		var k := 0.0024 * float(main.settings.get("look_speed", 1.0))
		if chase:
			view.want_yaw -= m.relative.x * k
			view.want_pitch = clampf(view.want_pitch - m.relative.y * k, -0.6, 0.3)
		else:
			view.want_yaw = clampf(view.want_yaw - m.relative.x * k, -2.5, 2.5)
			view.want_pitch = clampf(view.want_pitch - m.relative.y * k, -0.9, 0.5)
		get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_MIDDLE:
		view.want_yaw = 0.0
		view.want_pitch = -0.08
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		var key := (e as InputEventKey).physical_keycode
		match key:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				end()
				return
			KEY_E:
				_key()
			KEY_R:
				_shift(-1)
			KEY_F:
				_shift(1)
			KEY_L:
				lights = 1 - lights
				_lights()
				main.audio.sfx("click", 0.5)
			KEY_H:
				high = not high
				_lights()
				main.audio.sfx("click", 0.4, 0.8)
			KEY_V:
				wipe = not wipe
				main.audio.sfx("click", 0.4, 0.7)
			KEY_C:
				chase = not chase
				view.ride = null if chase else body
				view.want_yaw = 0.0 if not chase else sim.yaw()
				view.yaw = view.want_yaw
				view.want_pitch = -0.08 if not chase else -0.22
				_chase_pos = sim.pos - sim.forward() * 9.0 + Vector3(0, 3.0, 0)
				sound.outside = chase
			_:
				return
		get_viewport().set_input_as_handled()
	if e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed:
		match (e as InputEventJoypadButton).button_index:
			JOY_BUTTON_Y:
				_key()
			JOY_BUTTON_RIGHT_SHOULDER:
				_shift(1)
			JOY_BUTTON_LEFT_SHOULDER:
				_shift(-1)
			JOY_BUTTON_B:
				end()
			JOY_BUTTON_X:
				lights = 1 - lights
				_lights()


func _key() -> void:
	main.keys.used()
	if sim.running:
		sim.running = false
		sound.running = false
		main.audio.sfx("click", 0.6, 0.6)
		return
	if sim.selector != "P" and sim.selector != "N":
		# it won't crank in gear: the neutral safety switch
		main.audio.sfx("click", 0.5, 0.5)
		return
	sound.cranking = 1.1 if not sim.drunk > 0.6 else 1.8
	main.audio.sfx("click", 0.6, 0.6)
	var t := get_tree().create_timer(sound.cranking)
	t.timeout.connect(func():
		if active and (sim.selector == "P" or sim.selector == "N"):
			sim.running = true
			sim.rpm = 1100.0
			sound.running = true)


func _shift(d: int) -> void:
	main.keys.used()
	var to := clampi(_sel + d, 0, SELECTOR.size() - 1)
	# out of P or into it only with a foot on the brake, slow
	if (SELECTOR[_sel] == "P" or SELECTOR[to] == "P") and absf(sim.speed) > 1.0:
		main.audio.sfx("ratchet", 0.4, 1.4)
		return
	if SELECTOR[to] == "R" and sim.speed > 2.0:
		main.audio.sfx("ratchet", 0.5, 0.8)       # the C6 won't take R rolling forward: it grinds and stays
		return
	_sel = to
	sim.selector = SELECTOR[_sel]
	main.audio.sfx("clack", 0.45, 0.9)


func _pedals(dt: float) -> void:
	var up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var dn := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	var lf := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var rt := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	# a foot goes down over half a second and comes off quicker
	_gas = move_toward(_gas, 1.0 if up else 0.0, dt * (1.8 if up else 4.0))
	_brk = move_toward(_brk, 1.0 if dn else 0.0, dt * (2.2 if dn else 5.0))
	var pad_gas := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	var pad_brk := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	var pad_steer := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	sim.throttle = maxf(_gas, pad_gas)
	sim.brake = maxf(_brk, pad_brk)
	if absf(pad_steer) > 0.08:
		sim.steer_direct = true
		sim.steer_in = pad_steer * absf(pad_steer)
	else:
		sim.steer_direct = false
		sim.steer_in = (1.0 if rt else 0.0) - (1.0 if lf else 0.0)
	sound.horn = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)


# ---------------------------------------------------------------- each frame

func _process(dt: float) -> void:
	if not active:
		return
	_t += dt
	_pedals(dt)
	view.keys_turn = Vector2.ZERO
	view.keys_feet = Vector2.ZERO
	sim.walls = road.walls_near(sim.pos, 22.0) + _car_walls()
	_acc += minf(dt, 0.1)
	var steps := 0
	while _acc >= TruckSim.DT and steps < 30:
		sim.step()
		_acc -= TruckSim.DT
		steps += 1
		if sim.hit > 0.8:
			sound.knock(sim.hit / 6.0)
			if sim.hit > 3.0:
				main.audio.sfx("thump", clampf(sim.hit / 8.0, 0.3, 1.0), 0.7)
	_sync_body()
	_gauges(dt)
	_traffic(dt)
	road.tick(_t)
	# the sound
	sound.rpm = sim.rpm
	sound.load = sim.throttle
	sound.speed = sim.speed
	sound.surface = sim.surf[2]
	# the rain on the roof, louder at a stop
	_rain.volume_db = -13.0 - clampf(absf(sim.speed) / 25.0, 0.0, 1.0) * 6.0
	# his head in the cab: a little of the road comes up through the seat
	if not chase:
		var bump := clampf(absf(sim.speed) / 30.0, 0.0, 1.0)
		view.ride_eye = EYE + Vector3(0, sin(_t * 13.0) * 0.002 * bump, 0)
	else:
		var want := sim.pos - sim.forward() * 8.5 + Vector3(0, 2.9, 0)
		_chase_pos = _chase_pos.lerp(want, 1.0 - exp(-dt * 3.0))
		view.eye_pos = _chase_pos
		var look := sim.pos + Vector3(0, 0.6, 0) - _chase_pos
		view.want_yaw = atan2(-look.x, -look.z)
		view.want_pitch = atan2(look.y, Vector2(look.x, look.z).length())
	# drink: now and then he loses a second or two, and it all went on without him
	if sim.drunk > 0.45 and sim.running:
		_next_blank -= dt
		if _next_blank <= 0.0 and _blank <= 0.0:
			_blank = _rng.randf_range(0.8, 2.2) * sim.drunk
			_next_blank = _rng.randf_range(20.0, 45.0) / sim.drunk
	if _blank > 0.0:
		_blank -= dt
		black.color.a = move_toward(black.color.a, 1.0, dt * 8.0)
	else:
		black.color.a = move_toward(black.color.a, 0.0, dt * 3.0)


func _sync_body() -> void:
	body.global_transform = Transform3D(sim.rot, sim.pos)
	for i in 4:
		var w: Array = wheels[i]
		var piv: Node3D = w[0]
		var tire: Node3D = w[1]
		var m: Vector3 = sim.mount[i]
		piv.position = Vector3(m.x, m.y - float(sim.length[i]), m.z)
		piv.rotation.y = float(sim.turn[i]) if i < 2 else 0.0
		tire.rotation.x = -float(sim.roll_angle[i])
	wheel_node.rotation.z = deg_to_rad(sim.wheel_deg)


func _gauges(dt: float) -> void:
	var mph := absf(sim.speed) * MPH
	# 0 at the left, 100 at the right, a 240 degree sweep; the needle shivers a little at speed
	var a := -120.0 + clampf(mph, 0.0, 100.0) * 2.4 + sin(_t * 31.0) * 0.4 * clampf(mph / 40.0, 0.0, 1.0)
	needle.rotation.z = -deg_to_rad(a)
	fuel_needle.rotation.z = -deg_to_rad(-40.0 + 52.0)
	temp_needle.rotation.z = -deg_to_rad(-40.0 + (36.0 if sim.running else 0.0))
	var txt := ""
	for s in SELECTOR:
		txt += ("[" + s + "]" if s == sim.selector else " " + s + " ")
	prnd.text = txt
	# wipers
	if wipe:
		_wipe_t += dt
	elif fmod(_wipe_t, 1.6) > 0.05:
		_wipe_t += dt
	var ph := fmod(_wipe_t, 1.6) / 1.6
	var sweep := (1.0 - cos(ph * TAU)) / 2.0
	for w in wipers:
		(w as Node3D).rotation.z = deg_to_rad(-6.0 - sweep * 92.0) * (1.0 if w.get_meta("side") < 0 else 1.0)
	# brake lights
	for t in tail_glow:
		((t as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("emission_energy", (2.6 if sim.brake > 0.05 else (0.9 if lights > 0 else 0.0)))
	if dome != null:
		dome.visible = false


func _lights() -> void:
	for i in beams.size():
		var b: SpotLight3D = beams[i]
		b.visible = lights > 0
		b.spot_range = 105.0 if high else 48.0
		b.spot_angle = 17.0 if high else 26.0
		b.light_energy = 240.0 if high else 120.0
		b.rotation_degrees.x = -1.2 if high else -4.0
	(beam_pools[0].material_override as ShaderMaterial).set_shader_parameter("energy", 0.42 if lights > 0 and not high else (0.18 if lights > 0 else 0.0))
	(beam_pools[1].material_override as ShaderMaterial).set_shader_parameter("energy", 0.36 if lights > 0 and high else 0.0)
	for g in head_glow:
		((g as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("emission_energy", (2.4 if lights > 0 else 0.0))
	dash_light.visible = lights > 0


# ---------------------------------------------------------------- the truck, drawn

func _m(c: Color, rough := 0.6, metal := 0.0, cut := 2) -> ShaderMaterial:
	return pub.mat(c, rough, metal, cut, Vector3(0, 1, 0))


func _bx(size: Vector3, pos: Vector3, m: Material, parent: Node3D, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _cy(r: float, h: float, pos: Vector3, m: Material, parent: Node3D, rot := Vector3.ZERO, seg := 18) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


# Body local: the middle of mass at 0, the ground about 0.87 down, -z ahead.
func _build_truck() -> void:
	M.jade = _m(JADE, 0.45, 0.25)
	M.white = _m(Color("d9d5c8"), 0.55, 0.1)
	M.chrome = _m(Color("b8bcbe"), 0.25, 0.85)
	M.black = _m(Color("141414"), 0.8)
	M.dark = _m(Color("232320"), 0.85)
	M.rubber = _m(Color("161616"), 0.95, 0.0, 4)
	M.glass = pub.M.get("glass", _m(Color(0.1, 0.12, 0.13), 0.1, 0.0, 3))
	M.vinyl = _m(Color("5a4a36"), 0.7)
	M.dash = _m(Color("2c3a30"), 0.75)
	M.dial = _m(Color("0e100e"), 0.9, 0.0, 3)
	M.needle = pub.glow(Color("ff8a3a"), 1.2)
	M.numbers = pub.glow(Color("cfe8d8"), 0.6)
	body = Node3D.new()
	body.name = "truck"
	pub.add_child(body)
	var J: Material = M.jade
	var W: Material = M.white
	# the frame and the running gear under it
	_bx(Vector3(0.9, 0.2, 5.1), Vector3(0, -0.5, 0.05), M.black, body)
	# the front: bumper, grille, the headlights in their bezels, the long hood, the fenders
	_bx(Vector3(2.02, 0.2, 0.16), Vector3(0, -0.36, -2.78), M.chrome, body)
	_bx(Vector3(1.62, 0.5, 0.08), Vector3(0, -0.02, -2.71), M.chrome, body)
	for k in 6:
		_bx(Vector3(1.5, 0.03, 0.06), Vector3(0, -0.2 + k * 0.075, -2.74), M.black, body)
	for sx in [-0.62, 0.62]:
		_bx(Vector3(0.3, 0.22, 0.06), Vector3(sx, 0.06, -2.76), M.chrome, body)
		var g := _bx(Vector3(0.24, 0.16, 0.03), Vector3(sx, 0.06, -2.79), pub.glow(Color("fff2cc"), 0.0), body)
		head_glow.append(g)
		var b := SpotLight3D.new()
		b.position = Vector3(sx, 0.06, -2.85)
		b.light_color = Color("ffe9bc")
		b.spot_attenuation = 0.9
		b.spot_angle_attenuation = 1.4
		b.shadow_enabled = sx < 0.0
		b.light_size = 0.12
		body.add_child(b)
		beams.append(b)
	_bx(Vector3(1.86, 0.1, 1.78), Vector3(0, 0.27, -1.86), J, body, Vector3(-2.0, 0, 0))
	for sx in [-0.93, 0.93]:
		_bx(Vector3(0.18, 0.6, 1.8), Vector3(sx, -0.02, -1.86), J, body)
		var badge := Label3D.new()
		badge.text = "CAMPER SPECIAL"
		badge.pixel_size = 0.0016
		badge.font_size = 48
		badge.modulate = Color("e8e4d4")
		badge.position = Vector3(sx + signf(sx) * 0.095, 0.08, -1.45)
		badge.rotation.y = PI / 2.0 * signf(sx)
		badge.shaded = true
		body.add_child(badge)
	_bx(Vector3(1.8, 0.04, 0.5), Vector3(0, -0.34, -2.45), M.black, body)
	# the cab: below the beltline jade, the roof white, the pillars, the glass
	_bx(Vector3(1.96, 0.82, 1.56), Vector3(0, -0.05, -0.18), J, body)
	_bx(Vector3(1.78, 0.07, 1.24), Vector3(0, 1.02, -0.08), W, body)
	for sx in [-0.86, 0.86]:
		_bx(Vector3(0.07, 0.72, 0.08), Vector3(sx, 0.66, -0.78), J, body, Vector3(-24.0, 0, 0))   # A pillars
		_bx(Vector3(0.07, 0.68, 0.08), Vector3(sx, 0.68, 0.53), W, body)                           # B pillars
		_bx(Vector3(0.05, 0.03, 1.22), Vector3(sx, 1.0, -0.12), M.chrome, body)                   # drip rails
	_bx(Vector3(1.74, 0.06, 0.08), Vector3(0, 0.98, -0.62), W, body)                              # windshield header
	var ws := _bx(Vector3(1.68, 0.7, 0.012), Vector3(0, 0.67, -0.79), M.glass, body, Vector3(-24.0, 0, 0))
	ws.transparency = 0.82
	ws.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bx(Vector3(1.74, 0.62, 0.05), Vector3(0, 0.68, 0.56), W, body)                               # the back wall
	var rw := _bx(Vector3(1.2, 0.36, 0.012), Vector3(0, 0.72, 0.53), M.glass, body)
	rw.transparency = 0.6
	# the wipers, parked at the bottom of the glass
	for sx in [-0.62, 0.08]:
		var piv := Node3D.new()
		piv.position = Vector3(sx, 0.36, -0.95)
		piv.rotation.x = deg_to_rad(-24.0)
		body.add_child(piv)
		var arm := Node3D.new()
		arm.set_meta("side", sx)
		piv.add_child(arm)
		_bx(Vector3(0.52, 0.018, 0.018), Vector3(0.26, 0.0, 0.02), M.black, arm)
		arm.rotation.z = deg_to_rad(-6.0)
		wipers.append(arm)
	# the West Coast mirrors on their arms
	for sx in [-1.0, 1.0]:
		_bx(Vector3(0.24, 0.03, 0.03), Vector3(sx * 1.05, 0.5, -0.72), M.chrome, body)
		_bx(Vector3(0.03, 0.34, 0.03), Vector3(sx * 1.17, 0.58, -0.72), M.chrome, body)
		_bx(Vector3(0.16, 0.3, 0.04), Vector3(sx * 1.19, 0.6, -0.7), M.chrome, body)
		_bx(Vector3(0.13, 0.27, 0.01), Vector3(sx * 1.19, 0.6, -0.68), M.glass, body)
	# inside: the dash, the cluster, the wheel and its column, the shifter, the bench seat. Laid out
	# from where his eyes are: the hood shows over the dash, the cluster over the wheel's rim.
	_bx(Vector3(1.76, 0.36, 0.34), Vector3(0, 0.32, -0.81), M.dash, body)          # the dash's face, its top at 0.50
	_bx(Vector3(1.78, 0.05, 0.42), Vector3(0, 0.505, -0.84), M.dark, body)         # the pad on top of it
	_bx(Vector3(0.62, 0.05, 0.06), Vector3(EYE.x, 0.535, -0.64), M.dark, body)      # the hood over the cluster
	var cluster := Node3D.new()
	cluster.position = Vector3(EYE.x, 0.44, -0.636)
	cluster.rotation.x = deg_to_rad(14.0)
	body.add_child(cluster)
	_bx(Vector3(0.56, 0.16, 0.02), Vector3(0, 0, -0.012), M.dial, cluster)
	_cy(0.068, 0.006, Vector3(0, 0, -0.001), M.dial, cluster, Vector3(90, 0, 0), 24)
	needle = Node3D.new()
	needle.position = Vector3(0, 0, 0.006)
	cluster.add_child(needle)
	_bx(Vector3(0.005, 0.06, 0.002), Vector3(0, 0.028, 0), M.needle, needle)
	for k in 6:
		var a := deg_to_rad(-120.0 + k * 48.0)
		var lab := Label3D.new()
		lab.text = str(k * 20)
		lab.pixel_size = 0.0006
		lab.font_size = 40
		lab.modulate = Color("d8f2e0")
		lab.position = Vector3(sin(a) * 0.05, cos(a) * 0.05, 0.004)
		lab.shaded = false
		cluster.add_child(lab)
	var mph_l := Label3D.new()
	mph_l.text = "MPH"
	mph_l.pixel_size = 0.0005
	mph_l.font_size = 32
	mph_l.position = Vector3(0, -0.032, 0.004)
	mph_l.modulate = Color("9fc8b0")
	mph_l.shaded = false
	cluster.add_child(mph_l)
	for side in [-1.0, 1.0]:
		_cy(0.034, 0.006, Vector3(side * 0.17, 0, -0.001), M.dial, cluster, Vector3(90, 0, 0), 18)
		var nd := Node3D.new()
		nd.position = Vector3(side * 0.17, -0.012, 0.006)
		cluster.add_child(nd)
		_bx(Vector3(0.004, 0.03, 0.002), Vector3(0, 0.015, 0), M.needle, nd)
		var gl := Label3D.new()
		gl.text = "E    F" if side < 0.0 else "C    H"
		gl.pixel_size = 0.00045
		gl.font_size = 32
		gl.position = Vector3(side * 0.17, 0.018, 0.004)
		gl.modulate = Color("9fc8b0")
		gl.shaded = false
		cluster.add_child(gl)
		if side < 0.0:
			fuel_needle = nd
		else:
			temp_needle = nd
	dash_light = OmniLight3D.new()
	dash_light.position = Vector3(0, 0.03, 0.06)
	dash_light.light_color = Color("bfe8cf")
	dash_light.light_energy = 0.02
	dash_light.omni_range = 0.25
	cluster.add_child(dash_light)
	# the steering wheel: a thin black rim, three chrome spokes, the horn pad, leaned well back the
	# way an old truck's is, on its column down into the dash
	var col := Node3D.new()
	col.position = Vector3(EYE.x, 0.38, -0.36)
	var n := Vector3(0, 0.8, 0.6)
	col.basis = Basis(Vector3(1, 0, 0), n, Vector3(1, 0, 0).cross(n))
	body.add_child(col)
	_cy(0.024, 0.46, Vector3(0, -0.24, 0), M.dark, col)
	wheel_node = Node3D.new()
	col.add_child(wheel_node)
	var rim := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.186
	tor.outer_radius = 0.204
	tor.rings = 32
	tor.ring_segments = 8
	rim.mesh = tor
	rim.material_override = M.black
	wheel_node.add_child(rim)
	for k in 3:
		var a := deg_to_rad(90.0 + k * 120.0)
		var sp := _bx(Vector3(0.19, 0.008, 0.022), Vector3(cos(a) * 0.095, 0.0, sin(a) * 0.095), M.chrome, wheel_node)
		sp.rotation.y = -a
	_cy(0.05, 0.03, Vector3.ZERO, M.chrome, wheel_node, Vector3.ZERO, 16)
	# the column shifter and its quadrant: P R N D 2 1
	var lever := _bx(Vector3(0.012, 0.012, 0.24), Vector3(EYE.x + 0.16, 0.44, -0.44), M.chrome, body, Vector3(0, -55, -18))
	lever.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	prnd = Label3D.new()
	prnd.pixel_size = 0.0006
	prnd.font_size = 40
	prnd.modulate = Color("f0dca8")
	prnd.position = Vector3(EYE.x, 0.395, -0.62)
	prnd.rotation.x = deg_to_rad(14.0)
	prnd.shaded = false
	body.add_child(prnd)
	# the light the headlamps throw on the road ahead: a pool, the way the town's lamps' are printed
	for k in 2:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(9.0, 30.0) if k == 0 else Vector2(10.0, 70.0)
		qm.orientation = PlaneMesh.FACE_Y
		q.mesh = qm
		var pm := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = BEAM_POOL
		pm.shader = sh
		pm.set_shader_parameter("energy", 0.0)
		q.material_override = pm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.position = Vector3(0, -0.8, -2.9 - qm.size.y / 2.0)
		body.add_child(q)
		beam_pools.append(q)
	# the bench seat
	_bx(Vector3(1.66, 0.16, 0.52), Vector3(0, -0.1, 0.22), M.vinyl, body)
	_bx(Vector3(1.66, 0.6, 0.12), Vector3(0, 0.24, 0.47), M.vinyl, body, Vector3(-8.0, 0, 0))
	# the doors' insides, the floor
	for sx in [-0.95, 0.95]:
		_bx(Vector3(0.05, 0.5, 1.2), Vector3(sx, 0.1, -0.2), M.dash, body)
	_bx(Vector3(1.8, 0.04, 1.5), Vector3(0, -0.4, -0.2), M.black, body)
	# the bed: a Styleside eight-foot, the tailgate, the rear fenders in it, the bumper
	_bx(Vector3(1.92, 0.05, 2.36), Vector3(0, -0.22, 1.86), M.dark, body)
	for sx in [-0.96, 0.96]:
		_bx(Vector3(0.06, 0.62, 2.4), Vector3(sx, 0.08, 1.86), J, body)
		_bx(Vector3(0.08, 0.04, 2.4), Vector3(sx, 0.4, 1.86), W, body)
	_bx(Vector3(1.92, 0.6, 0.06), Vector3(0, 0.08, 3.05), J, body)
	_bx(Vector3(1.94, 0.18, 0.14), Vector3(0, -0.36, 3.15), M.chrome, body)
	_bx(Vector3(1.86, 0.62, 0.05), Vector3(0, 0.08, 0.66), J, body)
	for sx in [-0.86, 0.86]:
		var tl := _bx(Vector3(0.1, 0.2, 0.03), Vector3(sx, 0.0, 3.09), pub.glow(Color("ff2a1a"), 0.0), body)
		tail_glow.append(tl)
	# the plate: Alberta, twenty years expired
	var plate := Label3D.new()
	plate.text = "ALBERTA  WILD ROSE COUNTRY\nBGX 417"
	plate.pixel_size = 0.0011
	plate.font_size = 48
	plate.modulate = Color("2a3a7a")
	plate.outline_size = 0
	plate.position = Vector3(0, -0.3, 3.23)
	plate.shaded = true
	body.add_child(plate)
	_bx(Vector3(0.32, 0.16, 0.01), Vector3(0, -0.3, 3.225), M.white, body)
	# the wheels: each a pivot (steers) and a tire (spins), with a white-painted rim and a hubcap
	for i in 4:
		var piv := Node3D.new()
		body.add_child(piv)
		var tire := Node3D.new()
		piv.add_child(tire)
		var sx := -1.0 if i % 2 == 0 else 1.0
		_cy(TruckSim.RADIUS, 0.25, Vector3.ZERO, M.rubber, tire, Vector3(0, 0, 90), 20)
		_cy(0.21, 0.26, Vector3.ZERO, M.white, tire, Vector3(0, 0, 90), 16)
		_cy(0.12, 0.27, Vector3.ZERO, M.chrome, tire, Vector3(0, 0, 90), 12)
		# a tread block so the turning shows
		_bx(Vector3(0.24, 0.05, 0.08), Vector3(0, TruckSim.RADIUS - 0.01, 0), M.black, tire)
		wheels.append([piv, tire])
	dome = OmniLight3D.new()
	dome.position = Vector3(0, 0.95, -0.1)
	dome.light_color = Color("ffe0b0")
	dome.light_energy = 0.4
	dome.omni_range = 1.4
	dome.visible = false
	body.add_child(dome)
	body.visible = false


# ---------------------------------------------------------------- the other cars on the road

func _build_traffic() -> void:
	var colors := [Color("6a2a22"), Color("8a8a84"), Color("2a3a4a"), Color("4a4030")]
	for k in 4:
		var n := Node3D.new()
		pub.add_child(n)
		var m := _m(colors[k], 0.5, 0.2)
		_bx(Vector3(1.8, 0.6, 4.6), Vector3(0, 0.55, 0), m, n)
		_bx(Vector3(1.6, 0.5, 2.3), Vector3(0, 1.1, 0.25), m, n)
		_bx(Vector3(1.55, 0.42, 0.02), Vector3(0, 1.1, -0.91), M.glass, n)
		for sx in [-0.65, 0.65]:
			_bx(Vector3(0.22, 0.14, 0.03), Vector3(sx, 0.62, -2.31), pub.glow(Color("fff0d0"), 2.2), n)
			_bx(Vector3(0.2, 0.12, 0.03), Vector3(sx, 0.7, 2.31), pub.glow(Color("ff2a1a"), 1.0), n)
		var beam := SpotLight3D.new()
		beam.position = Vector3(0, 0.62, -2.4)
		beam.light_color = Color("fff0d0")
		beam.spot_range = 45.0
		beam.spot_angle = 30.0
		beam.light_energy = 3.0
		beam.rotation_degrees.x = -4.0
		n.add_child(beam)
		n.visible = false
		traffic.append({"node": n, "s": 0.0, "dir": 1.0, "v": 20.0, "want": 20.0, "honked": false, "stopped": false})


func _spawn_car(c: Dictionary, first := false) -> void:
	var me: float = road.along(sim.pos)[0] - road.zero
	c.dir = 1.0 if _rng.randf() < 0.5 else -1.0
	# from ahead or behind, out of sight, coming toward where he is or going his way
	var off := _rng.randf_range(250.0, 520.0) * (1.0 if _rng.randf() < 0.7 else -1.0)
	c.s = clampf(me + off, -road.length_s() + 60.0, road.length_n() - 60.0)
	if (c.s - me) * c.dir > 0.0 and absf(c.s - me) < 200.0:
		c.s = me - c.dir * 300.0
	c.v = _rng.randf_range(18.0, 25.0)
	c.want = c.v
	c.honked = false
	c.stopped = false
	(c.node as Node3D).visible = true
	if first:
		c.s += _rng.randf_range(-100.0, 100.0)


func _traffic(dt: float) -> void:
	var me: float = road.along(sim.pos)[0] - road.zero
	for c in traffic:
		var n: Node3D = c.node
		var lane := 1.9 * float(c.dir)       # keep right: north in the east lane
		var a := road.at_dist(float(c.s))
		var p: Vector3 = a[0]
		var dir: Vector3 = a[1]
		var side := Vector3(-dir.z, 0.0, dir.x)
		# him in its lane ahead of it: the horn, and it brakes
		var ahead := (me - float(c.s)) * float(c.dir)
		var his_u: float = road.along(sim.pos)[1]
		var in_lane := absf(his_u - lane) < 2.2
		if in_lane and ahead > 0.0 and ahead < 60.0:
			if not c.honked and ahead < 45.0:
				c.honked = true
				main.audio.at("horn", n.position + Vector3(0, 1, 0), 1.0, 14.0)
			c.v = move_toward(float(c.v), 0.0 if ahead < 14.0 else 8.0, dt * 7.0)
		elif not c.stopped:
			c.v = move_toward(float(c.v), float(c.want), dt * 2.0)
		c.s = float(c.s) + float(c.dir) * float(c.v) * dt
		var at := p + side * lane
		at.y = IslandRoad.profile(lane, p.y) if not IslandRoad.in_sov(at.x) else 0.0
		n.position = at
		n.look_at(at + dir * float(c.dir), Vector3.UP)
		if absf(float(c.s) - me) < 6.0 and absf(his_u - lane) < 5.0 and float(c.v) > 8.0 and not c.get("gusted", false):
			c.gusted = true
			main.audio.at("gust", n.position + Vector3(0, 1, 0), 0.9, 6.0)
		if absf(float(c.s) - me) > 600.0 or float(c.s) < -road.length_s() + 30.0 or float(c.s) > road.length_n() - 30.0:
			c.gusted = false
			_spawn_car(c)


func _car_walls() -> Array:
	var out: Array = []
	for c in traffic:
		var n: Node3D = c.node
		if not n.visible:
			continue
		if n.position.distance_to(sim.pos) > 20.0:
			continue
		var f := -n.global_transform.basis.z
		out.append([Vector2(n.position.x, n.position.z), Vector2(0.9, 2.3), atan2(f.x, -f.z), n.position.y + 1.4])
		if sim.hit > 1.0 and n.position.distance_to(sim.pos) < 6.0:
			c.v = 0.0
			c.stopped = true
	return out
