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
#   Q             the door: out when it's still (into P first), a bail when it isn't; back in at the door
#   T             the radio on and off      , .  (or the wheel)  tune it      1-5  its buttons
#   Esc           leave the rehearsal
# A gamepad: right trigger the gas, left trigger the brake, the left stick the wheel, B the door.
# Out of it on his feet: game/truck_foot.gd. The radio: game/truck_radio.gd. What's out on the road
# that shouldn't be, and the rearview mirror it shows in: game/truck_odd.gd.
class_name Truck
extends Node

signal left

const KEYS_ROWS := [["Q", "the door: out (moving, he bails)"], ["E", "the key (in P or N)"], ["R / F", "the shifter, up toward P, down toward 1"],
	["W / S", "gas / brake"], ["A / D", "the wheel"], ["L  H  V", "lights, high beams, wipers"],
	["Space", "the horn"], ["T", "the radio"], [",  .  or the wheel", "tune it"], ["1 to 5", "its buttons (somebody set them)"],
	["Mouse", "his head round the cab"], ["C", "in the cab / behind the truck"]]

const HINGE := Vector3(-0.945, 0.0, -0.85)      # the driver's door's hinges, its front edge
const ODO_START := 86402.0                      # the odometer when it turned up: five drums, been round once
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
var radio: TruckRadio
var odd: TruckOdd
var mirror_vp: SubViewport       # the rearview mirror: what's behind, drawn by its own camera
var mirror_cam: Camera3D
var tail_light: SpotLight3D      # the tail lamps' red on the road behind
var caption: Label               # what can be made out of the radio
var _dial_lab: Label3D
var _dial_map: Array = []        # [kHz, x on the dial]
var _tune_held := 0.0
var _horns := 0
var _horn_was := false
var _dark_t := 0.0
var _out_t := 0.0
var body: Node3D                 # the truck, at the sim's middle of mass
var wheels: Array = []           # [steer pivot, spinning tire]
var wheel_node: Node3D           # the steering wheel
var _hit_cool := 0.0
var _temp := 0.0
var _g_local := Vector3.ZERO       # what the cab's doing, in its own terms, smoothed
var _head := Vector3.ZERO
var tree: Node3D                 # the cardboard pine on the mirror
var odo: Label3D
var warn_lamps: Array = []
var high_lamp: MeshInstance3D
var radio_ptr: MeshInstance3D
var lamp_knob: Node3D
var wiper_knob: Node3D
var key_node: Node3D
var fob: Node3D
var door_node: Node3D            # the driver's door, on its hinges
var door_geom: Node3D
var door_open := 0.0             # 0 shut, 1 wide
var _door_want := 0.0
var _door_shut_at := -1.0        # when it swings shut on its own (he's stepped away, or he's in)
var _left_open := false          # he bailed: it stays as he left it
var _roll_brk := 0.0             # nobody's foot: it rolls to a stop
var foot: TruckFoot
var _tree_th := [0.0, 0.0]
var _tree_w := [0.0, 0.0]
var _last_vel := Vector3.ZERO
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
var chase_at := Vector3(0.0, 2.5, 7.2)   # the outside view: to his side, up, behind (the truck's own frame)
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
	radio = TruckRadio.new()
	add_child(radio)
	foot = TruckFoot.new(self)
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
	odd = TruckOdd.new()
	odd.setup(self)
	_build_mirror()
	caption = Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(760, 0)
	caption.offset_left = -380.0
	caption.offset_right = 380.0
	caption.offset_top = -120.0
	caption.offset_bottom = -40.0
	caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	caption.add_theme_font_size_override("font_size", 17)
	caption.add_theme_color_override("font_color", Color("e8c070"))
	caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	caption.add_theme_constant_override("shadow_offset_x", 1)
	caption.add_theme_constant_override("shadow_offset_y", 1)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.root.add_child(caption)
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
	_rain.volume_db = -22.0
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
	view.keys_off = true
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
	foot.get_in()
	door_open = 0.0
	_door_want = 0.0
	_door_shut_at = -1.0
	_left_open = false
	_roll_brk = 0.0
	sound.outside = false
	sound.volume = 1.0
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
	var vars := {}
	var path: Array = []
	if main.game != null and main.game.story != null:
		vars = main.game.vars()
		path = main.game.path
	radio.begin(vars, path)
	radio.start()
	odd.begin()
	_horns = 0
	_dark_t = 0.0
	_out_t = 0.0
	mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
	view.keys_off = false
	view.lean_roll = 0.0
	foot.out = false
	sound.stop()
	radio.stop()
	odd.end_all()
	caption.text = ""
	mirror_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
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
		if foot.out:
			view.want_yaw -= m.relative.x * k
			view.want_pitch = clampf(view.want_pitch - m.relative.y * k, -1.2, 1.0)
		elif chase:
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
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and not foot.out:
		var wb := (e as InputEventMouseButton).button_index
		if wb == MOUSE_BUTTON_WHEEL_UP or wb == MOUSE_BUTTON_WHEEL_DOWN:
			if not radio.on:
				radio.toggle()
			radio.tune(4.0 if wb == MOUSE_BUTTON_WHEEL_UP else -4.0)
			get_viewport().set_input_as_handled()
			return
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		var key := (e as InputEventKey).physical_keycode
		if key == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			end()
			return
		if key == KEY_Q or (foot.out and key == KEY_E):
			_door()
			get_viewport().set_input_as_handled()
			return
		if foot.out:
			return
		match key:
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
			KEY_T:
				radio.toggle()
				main.keys.used()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5:
				var i := (key - KEY_1) if key <= KEY_5 else (key - KEY_KP_1)
				radio.preset(i)
				main.keys.used()
			KEY_C:
				chase = not chase
				view.ride = null if chase else body
				view.want_yaw = 0.0 if not chase else sim.yaw()
				view.yaw = view.want_yaw
				view.want_pitch = -0.08 if not chase else -0.22
				_chase_pos = sim.pos + sim.rot * Vector3(chase_at.x, 0.0, chase_at.z) + Vector3(0, chase_at.y, 0)
				sound.outside = chase
			_:
				return
		get_viewport().set_input_as_handled()
	if e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed:
		var bi := (e as InputEventJoypadButton).button_index
		if bi == JOY_BUTTON_B:
			_door()
			return
		if bi == JOY_BUTTON_BACK:
			end()
			return
		if foot.out:
			return
		match bi:
			JOY_BUTTON_Y:
				_key()
			JOY_BUTTON_RIGHT_SHOULDER:
				_shift(1)
			JOY_BUTTON_LEFT_SHOULDER:
				_shift(-1)
			JOY_BUTTON_X:
				lights = 1 - lights
				_lights()
			JOY_BUTTON_DPAD_UP:
				radio.toggle()
			JOY_BUTTON_DPAD_DOWN:
				# the buttons in turn
				var near: Array = radio.nearest()
				var at := TruckRadio.PRESETS.find(near[0].f if near[0] != null and float(near[1]) > 0.5 else -1.0)
				radio.preset((at + 1) % TruckRadio.PRESETS.size())


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


# Q: the door. Still, he steps out (and puts it in P first, the way a man does); moving, he bails,
# and how that goes depends on how fast. Out, at the driver's door, he gets back in.
func _door() -> void:
	main.keys.used()
	if not foot.out:
		var still := absf(sim.speed) < 0.7
		if still and SELECTOR[_sel] != "P" and SELECTOR[_sel] != "N":
			_sel = 0
			sim.selector = "P"
			main.audio.sfx("clack", 0.4, 0.9)
		var how := foot.get_out()
		_door_want = 1.0
		_left_open = not still
		_door_shut_at = _t + 1.3 if still else -1.0
		_roll_brk = 0.0
		chase = false
		sound.outside = true
		main.keys.set_rows(TruckFoot.KEYS_ROWS, "On his feet")
		if how > 0:
			radio.saw("bail")
		match how:
			0:
				main.audio.sfx("clack", 0.35, 0.7)
			1:
				main.audio.sfx("thump", 0.4, 0.9)
			2:
				main.audio.sfx("thump", 0.8, 0.7)
				view.hurt += 1
				_blank = 0.25
				Input.start_joy_vibration(0, 0.6, 0.9, 0.4)
			3:
				main.audio.sfx("thump", 1.0, 0.55)
				view.hurt += 2
				_blank = 1.6
				Input.start_joy_vibration(0, 1.0, 1.0, 0.8)
		return
	if foot.near_door() and absf(sim.speed) < 2.0:
		foot.get_in()
		view.ride = body
		view.ride_eye = EYE
		_door_want = 1.0
		door_open = maxf(door_open, 0.6)
		_door_shut_at = _t + 0.5
		_left_open = false
		_roll_brk = 0.0
		sound.outside = false
		sound.volume = 1.0
		main.keys.set_rows(KEYS_ROWS, "In the cab")


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
	if foot.out:
		# nobody's foot on anything: it rolls on in whatever gear it was left in, slowing to a stop
		_gas = 0.0
		_brk = 0.0
		sim.throttle = 0.0
		var cap := 0.11 if absf(sim.speed) > 1.5 else 0.4
		_roll_brk = move_toward(_roll_brk, cap, dt * (0.03 if absf(sim.speed) > 1.5 else 0.2))
		sim.brake = _roll_brk
		sim.steer_direct = false
		sim.steer_in = 0.0
		sound.horn = false
		return
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
		# a knock once for each new hit, not every step it's against the thing
		if sim.hit > 0.8 and _hit_cool <= 0.0:
			sound.knock(clampf(sim.hit / 7.0, 0.15, 1.0))
			if sim.hit > 2.5:
				radio.saw("hit")
			_hit_cool = 0.45
	_hit_cool -= dt
	_sync_body()
	_swing(dt)
	_gauges(dt)
	_traffic(dt)
	road.tick(_t)
	_radio_and_mirror(dt)
	# the sound
	sound.rpm = sim.rpm
	sound.load = sim.throttle
	sound.speed = sim.speed
	sound.surface = sim.surf[2]
	# the rain on the roof, louder at a stop
	_rain.volume_db = -21.0 - clampf(absf(sim.speed) / 25.0, 0.0, 1.0) * 6.0
	if foot.out:
		foot.step(dt)
		# the truck heard from out here: further, quieter
		var dist := foot.pos.distance_to(sim.pos)
		sound.volume = clampf(4.0 / maxf(dist, 1.0), 0.06, 1.0)
		_rain.volume_db = -30.0
	# his head in the cab: a little of the road comes up through the seat
	elif not chase:
		# his head in the cab: thrown a little against what the truck does (late, the way a body
		# is), and the road coming up through the seat, more on gravel
		var bump := clampf(absf(sim.speed) / 30.0, 0.0, 1.0) * (2.6 if sim.surf[2] == TruckSim.Surf.GRAVEL else 1.0)
		var g := (-_g_local * 0.0045).limit_length(0.06)
		_head = _head.lerp(g, 1.0 - exp(-dt * 5.0))
		var shake := (sin(_t * 13.0) * 0.6 + sin(_t * 29.0 + 1.3) * 0.4) * 0.0022 * bump
		view.ride_eye = EYE + Vector3(_head.x, shake + _head.y * 0.3, _head.z)
	else:
		var want := sim.pos + sim.rot * Vector3(chase_at.x, 0.0, chase_at.z) + Vector3(0, chase_at.y, 0)
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
	wheel_node.rotation.y = deg_to_rad(sim.wheel_deg)    # round its column (local y): + is to the left, anticlockwise to him


func _gauges(dt: float) -> void:
	var kmh := absf(sim.speed) * 3.6
	# 0 at the left, 160 at the right over the top; the needle shivers a little at speed
	var a := -90.0 + clampf(kmh, 0.0, 160.0) / 160.0 * 180.0 + sin(_t * 31.0) * 0.5 * clampf(kmh / 60.0, 0.0, 1.0)
	needle.rotation.z = -deg_to_rad(a)
	fuel_needle.rotation.z = -deg_to_rad(30.0 if sim.running or sound.cranking > 0.0 else -50.0)
	_temp = move_toward(_temp, 1.0 if sim.running else 0.0, dt * 0.02)
	temp_needle.rotation.z = -deg_to_rad(-50.0 + _temp * 48.0)
	var txt := ""
	for s in SELECTOR:
		txt += ("[" + s + "]" if s == sim.selector else " " + s + " ")
	prnd.text = txt
	var km := ODO_START + sim.odometer / 1000.0
	odo.text = "%05d %d" % [int(km) % 100000, int(km * 10.0) % 10]
	for w in warn_lamps:
		(w as Label3D).modulate.a = 0.25 if sim.running else (0.95 if sound.cranking > 0.0 or w.text != "BRAKE" else 0.25)
	(high_lamp.material_override as ShaderMaterial).set_shader_parameter("emission_energy", 2.0 if high and lights > 0 else 0.0)
	lamp_knob.position.z = -0.636 + (0.03 if lights > 0 else 0.0)
	wiper_knob.rotation.z = -1.1 if wipe else 0.0
	key_node.rotation.x = 0.8 if sim.running or sound.cranking > 0.0 else 0.0
	fob.rotation = Vector3(float(_tree_th[1]) * 0.7, 0.0, float(_tree_th[0]) * 0.7)
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
	# the door, and the dome lamp while it's open; the key's buzzer while it's open with the engine on
	if _door_shut_at > 0.0 and _t >= _door_shut_at:
		_door_want = 0.0
		_door_shut_at = -1.0
	var was := door_open
	door_open = move_toward(door_open, _door_want, dt * (2.6 if _door_want > door_open else 3.4))
	door_node.rotation.y = -deg_to_rad(64.0) * smoothstep(0.0, 1.0, door_open)
	if was > 0.02 and door_open <= 0.0:
		main.audio.sfx("thump", 0.35, 1.1)
	if dome != null:
		dome.visible = door_open > 0.05
	sound.buzzer = door_open > 0.05 and sim.running


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
	if tail_light != null:
		tail_light.visible = lights > 0
	(M.face as ShaderMaterial).set_shader_parameter("emission_energy", 0.5 if lights > 0 else 0.0)


# ---------------------------------------------------------------- the radio, the mirror, the road

var _flickering := false

func _radio_and_mirror(dt: float) -> void:
	# his hand on the tuning knob: a nudge, then a sweep the longer it's held
	var dir := 0.0
	if not foot.out:
		if Input.is_physical_key_pressed(KEY_PERIOD) or Input.is_physical_key_pressed(KEY_BRACKETRIGHT) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
			dir += 1.0
		if Input.is_physical_key_pressed(KEY_COMMA) or Input.is_physical_key_pressed(KEY_BRACKETLEFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
			dir -= 1.0
	if dir != 0.0:
		if _tune_held == 0.0:
			if not radio.on:
				radio.toggle()
			radio.tune(dir * 3.0)
		_tune_held += dt
		if _tune_held > 0.25:
			radio.tune(dir * dt * lerpf(30.0, 160.0, clampf((_tune_held - 0.25) / 1.2, 0.0, 1.0)))
	else:
		_tune_held = 0.0
	radio.rpm = sim.rpm if sim.running else 0.0
	var a: Array = road.along(sim.pos)
	radio.drive = {"odo": int(odo_value()), "where": TruckRadio.place_name(float(a[0]) - road.zero), "out": foot.out}
	if foot.out:
		var dist := foot.pos.distance_to(sim.pos)
		radio.volume = clampf(3.0 / maxf(dist, 1.0), 0.0, 1.0) * (1.0 if door_open > 0.3 else 0.35)
		radio.muffle = 1.0
	else:
		radio.volume = 1.0
		radio.muffle = 0.6 if chase else 0.0
	# the pointer on the dial, and its light
	if _dial_map.is_empty():
		_make_dial_map()
	radio_ptr.position.x = _dial_x(radio.dial)
	radio_ptr.visible = true
	(radio_ptr.material_override as ShaderMaterial).set_shader_parameter("emission_energy", 0.9 if radio.on else 0.0)
	# what can be made out of it
	var c := ""
	if radio.caption != "" and not foot.out:
		c = (radio.caption_from + "    " if radio.caption_from != "" else "") + radio.caption
	elif radio.caption != "" and foot.out and door_open > 0.3 and foot.pos.distance_to(sim.pos) < 4.0:
		c = radio.caption
	caption.text = c
	# the things that tell the island's radio about him
	var kmh := absf(sim.speed) * 3.6
	if kmh > 118.0:
		radio.saw("fast")
	if sound.horn and not _horn_was:
		_horns += 1
		if _horns >= 4:
			radio.saw("horn")
	_horn_was = sound.horn
	_dark_t = _dark_t + dt if lights == 0 and kmh > 40.0 else 0.0
	if _dark_t > 15.0:
		radio.saw("dark")
	_out_t = _out_t + dt if foot.out and absf(float(a[1])) < 6.0 else 0.0
	if _out_t > 20.0:
		radio.saw("out")
	# what's out there
	odd.step(dt)
	if odd.flicker > 0.01:
		_flickering = true
		for b in beams:
			(b as SpotLight3D).light_energy = (240.0 if high else 120.0) * (1.0 - odd.flicker * _rng.randf_range(0.0, 1.0) * (1.0 if _rng.randf() < 0.3 else 0.3))
	elif _flickering:
		_flickering = false
		_lights()
	# the mirror's camera: on the glass, looking back, through the back window
	mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if not foot.out and not chase else SubViewport.UPDATE_DISABLED
	var mt := body.global_transform * Transform3D(Basis.from_euler(Vector3(deg_to_rad(-2.5), PI, 0.0)), Vector3(0.0, 0.88, -0.53))
	mirror_cam.global_transform = mt


func odo_value() -> float:
	return ODO_START + sim.odometer / 1000.0


func _make_dial_map() -> void:
	var f: Font = _dial_lab.font if _dial_lab.font != null else ThemeDB.fallback_font
	var text := _dial_lab.text
	var px := _dial_lab.pixel_size
	var fs := _dial_lab.font_size
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * px
	var x0 := _dial_lab.position.x - w * 0.5
	var at := 0
	for tok in text.split(" ", false):
		var i := text.find(tok, at)
		var pre := f.get_string_size(text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * px
		var tw := f.get_string_size(tok, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * px
		_dial_map.append([float(tok) * 10.0, x0 + pre + tw * 0.5])
		at = i + tok.length()


func _dial_x(khz: float) -> float:
	var m := _dial_map
	if khz <= float(m[0][0]):
		var k0 := (khz - float(m[0][0])) / (float(m[1][0]) - float(m[0][0]))
		return lerpf(float(m[0][1]), float(m[1][1]), k0)
	for i in range(1, m.size()):
		if khz <= float(m[i][0]):
			var k := (khz - float(m[i - 1][0])) / (float(m[i][0]) - float(m[i - 1][0]))
			return lerpf(float(m[i - 1][1]), float(m[i][1]), k)
	return float(m[m.size() - 1][1])


func _build_mirror() -> void:
	mirror_vp = SubViewport.new()
	mirror_vp.size = Vector2i(352, 80)
	mirror_vp.world_3d = view.eye.find_world_3d()
	mirror_vp.positional_shadow_atlas_size = 0
	mirror_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	mirror_vp.audio_listener_enable_3d = false
	add_child(mirror_vp)
	mirror_cam = Camera3D.new()
	mirror_cam.keep_aspect = Camera3D.KEEP_WIDTH
	mirror_cam.fov = 30.0
	mirror_cam.near = 0.9            # past the cab's own inside, up to its back wall and the window in it
	mirror_cam.far = 400.0
	mirror_cam.environment = view.cam.environment
	mirror_cam.cull_mask = 0xFFFFF
	mirror_cam.set_cull_mask_value(View.MASK_LAYER, false)
	mirror_vp.add_child(mirror_cam)
	# the glass: what the camera sees, the right way round for a mirror, a little dark and a
	# little smeared, the way a mirror in a truck this age is
	var q := QuadMesh.new()
	q.size = Vector2(0.236, 0.052)
	var glass := MeshInstance3D.new()
	glass.mesh = q
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = """shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;
uniform sampler2D tex : filter_linear, source_color;
void fragment() {
	vec2 uv = vec2(1.0 - UV.x, UV.y);
	// night in a mirror: what little light there is, lifted, so a shape can be made out
	vec3 t = texture(tex, uv).rgb;
	float lum = dot(t, vec3(0.3, 0.55, 0.15));
	vec3 c = (1.0 - exp(-t * 22.0)) * 0.8 + vec3(1.0 - exp(-max(lum - 0.006, 0.0) * 30.0)) * 0.35;
	float edge = smoothstep(0.0, 0.06, UV.x) * smoothstep(0.0, 0.06, 1.0 - UV.x) * smoothstep(0.0, 0.2, UV.y) * smoothstep(0.0, 0.2, 1.0 - UV.y);
	float smear = 0.03 * sin(UV.x * 23.0 + UV.y * 7.0) * sin(UV.x * 5.0 - UV.y * 11.0);
	ALBEDO = c * mix(0.55, 1.0, edge) + vec3(0.012 + smear * 0.4);
}
"""
	sm.set_shader_parameter("tex", mirror_vp.get_texture())
	glass.material_override = sm
	glass.position = Vector3(0, 0.88, -0.5325)
	body.add_child(glass)
	# the tail lamps' red, on the road and whatever's standing on it behind (a spot, so none of it
	# comes forward into the cab)
	tail_light = SpotLight3D.new()
	tail_light.light_color = Color("ff2a1a")
	tail_light.light_energy = 2.0
	tail_light.spot_range = 18.0
	tail_light.spot_angle = 55.0
	tail_light.spot_attenuation = 1.4
	tail_light.shadow_enabled = false
	tail_light.position = Vector3(0, -0.1, 3.45)
	tail_light.rotation_degrees = Vector3(-8.0, 180.0, 0.0)
	tail_light.visible = false
	body.add_child(tail_light)


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


func _lab(t: String, px: float, fs: int, c: Color, parent: Node3D) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.pixel_size = px
	l.font_size = fs
	l.modulate = c
	l.outline_size = 0
	l.shaded = false
	parent.add_child(l)
	return l


# a woodgrain applique's grain: thin dark lines across it, a little off level, never two alike
func _grain(parent: Node3D, at: Vector3, size: Vector2) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = int(at.x * 1000.0) + 78
	var n := int(size.y / 0.012)
	for k in n:
		var y := -size.y / 2.0 + (k + r.randf_range(0.2, 0.8)) * size.y / n
		var w := size.x * r.randf_range(0.5, 0.98)
		var x := r.randf_range(-(size.x - w) / 2.0, (size.x - w) / 2.0)
		var g := _bx(Vector3(w, 0.0016, 0.001), at + Vector3(x, y, 0.0), M.grain, parent)
		g.rotation.z = r.randf_range(-0.012, 0.012)
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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
	M.wood = _m(Color("6e4a2c"), 0.55)
	M.grain = _m(Color("432a17"), 0.7)
	M.alu = _m(Color("9a9c98"), 0.35, 0.7)
	M.face = pub.glow(Color("1c4a30"), 0.0)        # the gauges' faces, lit green from behind with the lamps on
	body = Node3D.new()
	body.name = "truck"
	pub.add_child(body)
	var J: Material = M.jade
	var W: Material = M.white
	_build_body(J, W)
	# inside: the dash, the cluster, the wheel and its column, the shifter, the bench seat. Laid out
	# from where his eyes are: the hood shows over the dash, the cluster over the wheel's rim.
	# the dash, a '78's: a tall flat face, the pad rolled over the top of it and cracked from the
	# sun, the cluster in its own hooded binnacle in front of him, and across the rest a woodgrain
	# panel with the radio, the heater's levers, the ashtray and the glovebox in it
	_prism(_pts([[-0.98, 0.12], [-0.64, 0.12], [-0.64, 0.45], [-0.68, 0.505], [-0.76, 0.525], [-0.98, 0.535]]),
		-0.88, 0.88, 0.02, M.dash, body)
	_prism(_pts([[-0.98, 0.50], [-0.72, 0.50], [-0.66, 0.52], [-0.70, 0.545], [-0.98, 0.55]]), -0.885, 0.885, 0.012, M.dark, body)
	for k in 3:
		_bx(Vector3(0.05, 0.003, 0.004), Vector3(0.18 + k * 0.04, 0.551, -0.78 + k * 0.012), M.black, body, Vector3(0, 25 - k * 40, 0))
	for k in 6:
		_bx(Vector3(0.1, 0.002, 0.01), Vector3(-0.6 + k * 0.24, 0.552, -0.9), M.black, body)     # the defrost slots
	# the binnacle: a brow over the cluster, its sides
	_prism(_pts([[-0.68, 0.535], [-0.625, 0.535], [-0.615, 0.548], [-0.68, 0.558]]), EYE.x - 0.32, EYE.x + 0.32, 0.008, M.dark, body)
	var cluster := Node3D.new()
	cluster.position = Vector3(EYE.x, 0.458, -0.612)
	cluster.rotation.x = deg_to_rad(-18.0)     # tipped back, its face up toward his eyes
	body.add_child(cluster)
	# woodgrain round it, a brushed rim on that, then the gauges' black faces
	_bx(Vector3(0.62, 0.19, 0.012), Vector3(0, 0, -0.018), M.wood, cluster)
	_grain(cluster, Vector3(0, 0, -0.011), Vector2(0.6, 0.18))
	_bx(Vector3(0.58, 0.15, 0.006), Vector3(0, 0, -0.012), M.alu, cluster)
	# the speedometer: a wide face, kilometres an hour round the top in white and miles inside in
	# red the way a Canadian truck had them, the needle from the bottom middle
	_bx(Vector3(0.25, 0.135, 0.004), Vector3(0, 0, -0.009), M.face, cluster)
	var pv := Vector2(0.0, -0.045)
	for k in 17:
		var a := deg_to_rad(180.0 - k * 180.0 / 16.0)
		var r := 0.083
		var tk := _bx(Vector3(0.0018, 0.008 if k % 2 == 0 else 0.004, 0.001), Vector3(pv.x + cos(a) * r, pv.y + sin(a) * r, -0.006), M.numbers, cluster)
		tk.rotation.z = a - PI / 2.0
	for k in 9:
		var a := deg_to_rad(180.0 - k * 22.5)
		var lab := _lab(str(k * 20), 0.00058, 30, Color("f2fbf4"), cluster)
		lab.position = Vector3(pv.x + cos(a) * 0.098, pv.y + sin(a) * 0.098, -0.005)
	for k in 6:
		var a := deg_to_rad(180.0 - k * 20.0 * 1.609 * 180.0 / 160.0)
		var lab := _lab(str(k * 20), 0.00042, 24, Color("ff8a6a"), cluster)
		lab.position = Vector3(pv.x + cos(a) * 0.058, pv.y + sin(a) * 0.058, -0.005)
	_lab("km/h", 0.0003, 24, Color("c8dccf"), cluster).position = Vector3(0, -0.012, -0.005)
	_lab("MPH", 0.00026, 22, Color("ff7a5a"), cluster).position = Vector3(0, -0.024, -0.005)
	needle = Node3D.new()
	needle.position = Vector3(pv.x, pv.y, -0.003)
	cluster.add_child(needle)
	_bx(Vector3(0.0035, 0.085, 0.0015), Vector3(0, 0.036, 0), M.needle, needle)
	_cy(0.009, 0.004, Vector3(pv.x, pv.y, -0.002), M.black, cluster, Vector3(90, 0, 0), 12)
	# the odometer, five drums and the tenth, rolled over once already
	_bx(Vector3(0.05, 0.012, 0.002), Vector3(0, -0.038, -0.006), M.black, cluster)
	odo = _lab("", 0.00028, 28, Color("e8e4d4"), cluster)
	odo.position = Vector3(0, -0.038, -0.004)
	# the shift quadrant along the speedometer's foot
	prnd = _lab("", 0.0003, 30, Color("f0dca8"), cluster)
	prnd.position = Vector3(0, -0.058, -0.005)
	# fuel to the left, temperature to the right, each in its own square pod; the warning lamps
	for side in [-1.0, 1.0]:
		var cx: float = side * 0.2
		_bx(Vector3(0.11, 0.115, 0.004), Vector3(cx, 0.0, -0.009), M.face, cluster)
		var nd := Node3D.new()
		nd.position = Vector3(cx, -0.03, -0.003)
		cluster.add_child(nd)
		_bx(Vector3(0.003, 0.05, 0.0015), Vector3(0, 0.022, 0), M.needle, nd)
		_lab("E        F" if side < 0.0 else "C        H", 0.00042, 26, Color("c8dccf"), cluster).position = Vector3(cx, 0.012, -0.005)
		_lab("FUEL" if side < 0.0 else "TEMP", 0.00036, 22, Color("8fb09c"), cluster).position = Vector3(cx, -0.045, -0.005)
		if side < 0.0:
			fuel_needle = nd
		else:
			temp_needle = nd
	var warn := [["ALT", -0.2, 0.038], ["OIL", 0.2, 0.038], ["BRAKE", 0.2, -0.008]]
	for w in warn:
		var wl := _lab(w[0], 0.00024, 22, Color("ff3a2a"), cluster)
		wl.position = Vector3(float(w[1]), float(w[2]), -0.005)
		wl.modulate.a = 0.25
		warn_lamps.append(wl)
	high_lamp = _bx(Vector3(0.016, 0.008, 0.002), Vector3(0.105, -0.058, -0.006), pub.glow(Color("4a8aff"), 0.0), cluster)
	dash_light = OmniLight3D.new()
	dash_light.position = Vector3(0, 0.04, 0.05)
	dash_light.light_color = Color("bfe8cf")
	dash_light.light_energy = 0.02
	dash_light.omni_range = 0.25
	cluster.add_child(dash_light)
	# the woodgrain panel across the rest of the face, edged in brushed trim
	_bx(Vector3(0.98, 0.22, 0.008), Vector3(0.37, 0.31, -0.636), M.wood, body)
	_grain(body, Vector3(0.37, 0.31, -0.631), Vector2(0.96, 0.2))
	_bx(Vector3(0.98, 0.008, 0.012), Vector3(0.37, 0.424, -0.634), M.alu, body)
	_bx(Vector3(0.98, 0.008, 0.012), Vector3(0.37, 0.196, -0.634), M.alu, body)
	# the radio: a push-button AM, its dial, its pointer, five buttons, two knobs
	var rx := 0.1
	_bx(Vector3(0.24, 0.085, 0.014), Vector3(rx, 0.33, -0.628), M.alu, body)
	_bx(Vector3(0.14, 0.026, 0.004), Vector3(rx, 0.345, -0.62), M.dial, body)
	_dial_lab = _lab("55  60  70  80  100  120  140  160", 0.00019, 22, Color("e8c88a"), body)
	_dial_lab.position = Vector3(rx, 0.349, -0.617)
	_lab("AM", 0.0002, 22, Color("e8c88a"), body).position = Vector3(rx - 0.055, 0.338, -0.617)
	radio_ptr = _bx(Vector3(0.0016, 0.022, 0.001), Vector3(rx - 0.03, 0.345, -0.6175), pub.glow(Color("ff5030"), 0.6), body)
	for k in 5:
		_bx(Vector3(0.02, 0.014, 0.02), Vector3(rx - 0.05 + k * 0.025, 0.308, -0.618), M.chrome, body)
	for kx in [-0.1, 0.1]:
		_cy(0.017, 0.028, Vector3(rx + kx, 0.33, -0.612), M.chrome, body, Vector3(90, 0, 0), 12)
		_cy(0.01, 0.012, Vector3(rx + kx, 0.33, -0.596), M.dark, body, Vector3(90, 0, 0), 10)
	# the heater: two levers in their slots, the words under them
	var hx := 0.37
	_bx(Vector3(0.15, 0.075, 0.008), Vector3(hx, 0.335, -0.628), M.dark, body)
	for k in 2:
		_bx(Vector3(0.11, 0.004, 0.002), Vector3(hx, 0.355 - k * 0.032, -0.623), M.black, body)
		_bx(Vector3(0.012, 0.018, 0.02), Vector3(hx - 0.03 + k * 0.05, 0.355 - k * 0.032, -0.615), M.black, body)
	_lab("OFF   VENT   HEAT   DEF", 0.00017, 20, Color("c8c0a8"), body).position = Vector3(hx, 0.343, -0.622)
	_lab("COOL              WARM", 0.00017, 20, Color("c8c0a8"), body).position = Vector3(hx, 0.311, -0.622)
	# the ashtray and the lighter under the radio
	_bx(Vector3(0.16, 0.034, 0.012), Vector3(rx, 0.23, -0.628), M.alu, body)
	_bx(Vector3(0.05, 0.006, 0.006), Vector3(rx, 0.236, -0.621), M.black, body)
	_cy(0.012, 0.02, Vector3(rx + 0.13, 0.23, -0.622), M.chrome, body, Vector3(90, 0, 0), 10)
	# the glovebox: its door's line and the button
	for e in [[Vector3(0.3, 0.004, 0.004), Vector3(0.68, 0.39, -0.63)], [Vector3(0.3, 0.004, 0.004), Vector3(0.68, 0.23, -0.63)],
			[Vector3(0.004, 0.16, 0.004), Vector3(0.53, 0.31, -0.63)], [Vector3(0.004, 0.16, 0.004), Vector3(0.83, 0.31, -0.63)]]:
		_bx(e[0], e[1], M.black, body)
	_bx(Vector3(0.04, 0.016, 0.014), Vector3(0.68, 0.37, -0.625), M.chrome, body)
	# left of the wheel: the headlamp knob (it pulls out when they're on) and the wipers' knob
	lamp_knob = Node3D.new()
	lamp_knob.position = Vector3(-0.76, 0.37, -0.636)
	body.add_child(lamp_knob)
	_cy(0.004, 0.04, Vector3(0, 0, 0.02), M.chrome, lamp_knob, Vector3(90, 0, 0), 8)
	_cy(0.016, 0.02, Vector3(0, 0, 0.042), M.chrome, lamp_knob, Vector3(90, 0, 0), 12)
	wiper_knob = Node3D.new()
	wiper_knob.position = Vector3(-0.76, 0.28, -0.62)
	body.add_child(wiper_knob)
	_cy(0.015, 0.02, Vector3.ZERO, M.chrome, wiper_knob, Vector3(90, 0, 0), 12)
	_bx(Vector3(0.004, 0.024, 0.004), Vector3(0, 0.0, 0.012), M.black, wiper_knob)
	# on the pad by the glass, sun-faded, curling: the bill of sale from twenty years ago
	var slip := Node3D.new()
	slip.position = Vector3(0.48, 0.556, -0.83)
	slip.rotation = Vector3(deg_to_rad(-84.0), deg_to_rad(8.0), 0.0)
	body.add_child(slip)
	_bx(Vector3(0.09, 0.12, 0.001), Vector3.ZERO, _m(Color("d8cfb4"), 0.95), slip)
	var bill := _lab("CEREAL CITY AUTO SALVAGE\nBATTLE CREEK, MICH.\n\n1 - '78 F-250 CAMPER SPL\nJADE   NO MOTOR\nSOLD AS IS\n\n$ 1,150.00  CASH\nNO RETURNS", 0.00011, 22, Color("40382c"), slip)
	bill.position = Vector3(0, 0, 0.001)
	bill.shaded = true
	# the steering wheel, the '78's: a thin black rim, two spokes a little below the middle and a
	# wide horn pad between them; leaned well back on its column down into the dash
	var col := Node3D.new()
	col.position = Vector3(EYE.x, 0.32, -0.33)
	var n := Vector3(0, 0.8, 0.6)
	col.basis = Basis(Vector3(1, 0, 0), n, Vector3(1, 0, 0).cross(n))
	body.add_child(col)
	_cy(0.026, 0.46, Vector3(0, -0.24, 0), M.dark, col)
	_cy(0.034, 0.06, Vector3(0, -0.06, 0), M.dark, col)
	# the turn signal's stalk to the left, the key in the column's right side and what hangs off it
	_bx(Vector3(0.15, 0.01, 0.01), Vector3(-0.1, -0.07, 0.01), M.chrome, col, Vector3(0, 0, 0))
	_cy(0.011, 0.03, Vector3(0.04, -0.13, 0.0), M.chrome, col, Vector3(0, 0, 90), 10)
	key_node = Node3D.new()
	key_node.position = Vector3(0.058, -0.13, 0.0)
	col.add_child(key_node)
	_bx(Vector3(0.012, 0.024, 0.004), Vector3(0.012, 0.0, 0.0), M.chrome, key_node)
	_bx(Vector3(0.02, 0.032, 0.005), Vector3(0.03, 0.0, 0.0), M.alu, key_node)
	fob = Node3D.new()
	fob.position = Vector3(0.042, -0.012, 0.0)
	key_node.add_child(fob)
	_cy(0.012, 0.003, Vector3(0, -0.012, 0), M.chrome, fob, Vector3(0, 0, 90), 12)
	_bx(Vector3(0.026, 0.04, 0.003), Vector3(0, -0.04, 0), _m(Color("a07a3a"), 0.4, 0.8), fob)
	wheel_node = Node3D.new()
	col.add_child(wheel_node)
	var rim := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.186
	tor.outer_radius = 0.204
	tor.rings = 40
	tor.ring_segments = 8
	rim.mesh = tor
	rim.material_override = M.black
	wheel_node.add_child(rim)
	for sx in [-1.0, 1.0]:
		var sp := _bx(Vector3(0.12, 0.012, 0.034), Vector3(sx * 0.13, 0.008, 0.045), M.black, wheel_node)
		sp.rotation.y = -sx * 0.18
	_prism(_pts([[-0.035, -0.01], [0.075, -0.01], [0.085, 0.02], [0.07, 0.035], [-0.025, 0.035], [-0.045, 0.02]]), -0.085, 0.085, 0.01, M.black, wheel_node)
	_bx(Vector3(0.15, 0.002, 0.004), Vector3(0, 0.037, 0.0), M.chrome, wheel_node)
	_bx(Vector3(0.15, 0.002, 0.004), Vector3(0, 0.037, 0.07), M.chrome, wheel_node)
	# the column shifter and its knob
	var lever := _bx(Vector3(0.012, 0.012, 0.24), Vector3(EYE.x + 0.16, 0.39, -0.41), M.chrome, body, Vector3(0, -55, -18))
	lever.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cy(0.016, 0.04, Vector3(EYE.x + 0.255, 0.355, -0.345), M.black, body, Vector3(0, 0, 70), 10)
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
	_build_cab_inside()
	_build_bed_and_wheels(J, W)
	dome = OmniLight3D.new()
	dome.position = Vector3(0, 0.95, -0.1)
	dome.light_color = Color("ffe0b0")
	dome.light_energy = 0.4
	dome.omni_range = 1.4
	dome.visible = false
	body.add_child(dome)
	body.visible = false


# ---------------------------------------------------------------- the body, from its side lines
# Each panel is a side profile (z ahead-back, y up) pushed out across the truck from x0 to x1, its
# long edges bevelled, so the print's line finds the fender's crown and the arch's lip the way a
# pencil would, not a box's corners.

func _pts(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in a:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


# an arch cut up out of a panel's bottom edge at y = bottom, round a wheel at (z, cy) radius r:
# the points from the front of it, over, to the back
func _arch(z: float, cy: float, r: float, bottom: float, n := 12) -> Array:
	var out := []
	var a0 := asin(clampf((bottom - cy) / r, -1.0, 1.0))
	for k in n + 1:
		var a := lerpf(PI - a0, a0, float(k) / n)
		out.append([z + cos(a) * r, cy + sin(a) * r])
	return out


func _prism(prof: PackedVector2Array, x0: float, x1: float, bevel: float, m: Material, parent: Node3D) -> MeshInstance3D:
	var area := 0.0
	for i in prof.size():
		var p := prof[i]
		var q := prof[(i + 1) % prof.size()]
		area += p.x * q.y - q.x * p.y
	if area < 0.0:
		prof.reverse()
	var n := prof.size()
	# each edge's outward normal (the profile now runs anticlockwise in z, y)
	var en: Array = []
	for i in n:
		var d := prof[(i + 1) % n] - prof[i]
		en.append(Vector2(d.y, -d.x).normalized())
	var b := minf(bevel, (x1 - x0) * 0.3)
	var inner := PackedVector2Array()
	for i in n:
		var n0: Vector2 = en[(i - 1 + n) % n]
		var n1: Vector2 = en[i]
		var mid := (n0 + n1).normalized()
		inner.append(prof[i] - mid * b / maxf(mid.dot(n1), 0.35))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var V := func(z: float, y: float, x: float) -> Vector3: return Vector3(x, y, z)
	# the band round the outline, between the bevels
	for i in n:
		var p := prof[i]
		var q := prof[(i + 1) % n]
		var out3 := Vector3(0, (en[i] as Vector2).y, (en[i] as Vector2).x)
		_quad(st, V.call(p.x, p.y, x0 + b), V.call(q.x, q.y, x0 + b), V.call(q.x, q.y, x1 - b), V.call(p.x, p.y, x1 - b), out3)
		# the bevels, each side
		var pi := inner[i]
		var qi := inner[(i + 1) % n]
		_quad(st, V.call(p.x, p.y, x1 - b), V.call(q.x, q.y, x1 - b), V.call(qi.x, qi.y, x1), V.call(pi.x, pi.y, x1), out3 + Vector3(1, 0, 0))
		_quad(st, V.call(p.x, p.y, x0 + b), V.call(q.x, q.y, x0 + b), V.call(qi.x, qi.y, x0), V.call(pi.x, pi.y, x0), out3 - Vector3(1, 0, 0))
	# the two flat sides
	var tri := Geometry2D.triangulate_polygon(inner)
	if tri.is_empty():
		# the inset outline folded on itself somewhere tight: its points still match the outline's
		tri = Geometry2D.triangulate_polygon(prof)
	if tri.is_empty():
		push_warning("truck: a panel's side wouldn't triangulate (%d points)" % inner.size())
	for k in range(0, tri.size(), 3):
		var a := inner[tri[k]]
		var c := inner[tri[k + 1]]
		var d := inner[tri[k + 2]]
		_tri(st, V.call(a.x, a.y, x1), V.call(c.x, c.y, x1), V.call(d.x, d.y, x1), Vector3(1, 0, 0))
		_tri(st, V.call(a.x, a.y, x0), V.call(c.x, c.y, x0), V.call(d.x, d.y, x0), Vector3(-1, 0, 0))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	parent.add_child(mi)
	return mi


# a triangle wound so its face looks the way `out` does
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, out: Vector3) -> void:
	if (b - a).cross(c - a).dot(out) > 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, out: Vector3) -> void:
	if (a - b).length_squared() < 1e-8 and (c - d).length_squared() < 1e-8:
		return
	_tri(st, a, b, c, out)
	_tri(st, a, c, d, out)


# Body local: the middle of mass at 0, the ground about 0.87 down, -z ahead. The wheels at z -1.42
# and 1.96, their middles about 0.48 down.
func _build_body(J: Material, W: Material) -> void:
	var WY := -0.48
	# the frame, the splash pans under the hood, the cross-member
	_bx(Vector3(0.9, 0.2, 5.1), Vector3(0, -0.5, 0.05), M.black, body)
	_bx(Vector3(1.36, 0.4, 1.86), Vector3(0, -0.26, -1.8), M.black, body)
	# the front fenders: the crown along the top, the arch round the wheel, the lip at the nose
	for sx in [-1.0, 1.0]:
		var f := [[-2.76, -0.40]] + _arch(-1.42, WY, 0.47, -0.40) + [[-0.85, -0.40], [-0.85, 0.27], [-1.4, 0.272],
			[-2.66, 0.255], [-2.75, 0.215], [-2.78, 0.15]]
		_prism(_pts(f), 0.70 * sx if sx > 0 else -0.99, 0.99 if sx > 0 else -0.70, 0.045, J, body)
		# the wheel well, dark behind the arch
		_bx(Vector3(0.05, 0.5, 1.0), Vector3(sx * 0.69, -0.2, -1.42), M.black, body)
		# the marker lamp on the fender's side, near the nose
		_bx(Vector3(0.012, 0.05, 0.11), Vector3(sx * 0.995, 0.08, -2.55), pub.glow(Color("ff9a2a"), 0.25), body)
		# the side spear: a thin chrome line along the fender and on down the door and the bed
		_bx(Vector3(0.01, 0.018, 1.6), Vector3(sx * 0.996, 0.0, -1.78), M.chrome, body)
		var badge := Label3D.new()
		badge.text = "CAMPER SPECIAL"
		badge.pixel_size = 0.0013
		badge.font_size = 44
		badge.modulate = Color("e8e4d4")
		badge.position = Vector3(sx * 0.998, 0.12, -1.12)
		badge.rotation.y = PI / 2.0 * sx
		badge.shaded = true
		body.add_child(badge)
	# the hood between them: flat, a shallow crown, rising a touch to the cowl
	_prism(_pts([[-2.72, -0.06], [-2.72, 0.2], [-2.67, 0.245], [-1.8, 0.29], [-0.85, 0.31], [-0.85, -0.06]]), -0.70, 0.70, 0.03, J, body)
	# the cowl and its vent under the glass
	_prism(_pts([[-0.85, 0.2], [-0.85, 0.32], [-0.80, 0.42], [-0.70, 0.43], [-0.70, 0.2]]), -0.95, 0.95, 0.02, J, body)
	_bx(Vector3(1.4, 0.008, 0.06), Vector3(0, 0.36, -0.82), M.black, body, Vector3(-60, 0, 0))
	# the front: the bumper, the grille's chrome surround and its bars, the round lamps in square bezels
	_prism(_pts([[-2.98, -0.46], [-2.80, -0.46], [-2.80, -0.24], [-2.92, -0.24], [-2.99, -0.30]]), -1.02, 1.02, 0.03, M.chrome, body)
	_prism(_pts([[-2.80, -0.36], [-2.74, -0.36], [-2.74, 0.20], [-2.80, 0.20]]), -0.95, 0.95, 0.02, M.chrome, body)
	_bx(Vector3(1.62, 0.44, 0.02), Vector3(0, -0.06, -2.805), M.black, body)
	for k in 4:
		_bx(Vector3(0.92, 0.022, 0.03), Vector3(0, -0.24 + k * 0.12, -2.81), M.chrome, body)
	for k in 5:
		_bx(Vector3(0.022, 0.44, 0.03), Vector3(-0.44 + k * 0.22, -0.06, -2.812), M.chrome, body)
	for sx in [-0.66, 0.66]:
		_bx(Vector3(0.3, 0.27, 0.05), Vector3(sx, -0.03, -2.81), M.chrome, body)
		_cy(0.095, 0.03, Vector3(sx, -0.03, -2.84), M.dark, body, Vector3(90, 0, 0), 20)
		var g := _cy(0.085, 0.02, Vector3(sx, -0.03, -2.855), pub.glow(Color("fff2cc"), 0.0), body, Vector3(90, 0, 0), 20)
		head_glow.append(g)
		var bl := SpotLight3D.new()
		bl.position = Vector3(sx, -0.03, -2.9)
		bl.light_color = Color("ffe9bc")
		bl.spot_attenuation = 0.9
		bl.spot_angle_attenuation = 1.4
		bl.shadow_enabled = sx < 0.0
		bl.light_size = 0.12
		body.add_child(bl)
		beams.append(bl)
		# the parking lamps, set in the bumper
		_bx(Vector3(0.16, 0.06, 0.02), Vector3(sx * 1.05, -0.35, -2.99), pub.glow(Color("ffb050"), 0.15), body)
	# the doors: each its own panel, the seam round it, the handle, the hinge side square. The
	# driver's hangs on its hinges at the front edge and opens (door_node); the rest is drawn in the
	# body's own terms under door_geom, so it all swings together.
	door_node = Node3D.new()
	door_node.position = HINGE
	body.add_child(door_node)
	door_geom = Node3D.new()
	door_geom.position = -HINGE
	door_node.add_child(door_geom)
	for sx in [-1.0, 1.0]:
		var P: Node3D = door_geom if sx < 0 else body
		var d := [[-0.85, -0.46], [0.64, -0.46], [0.64, 0.45], [-0.78, 0.45], [-0.85, 0.31]]
		_prism(_pts(d), -0.99 if sx < 0 else 0.90, -0.90 if sx < 0 else 0.99, 0.035, J, P)
		for zz in [-0.80, 0.56]:
			_bx(Vector3(0.006, 0.84, 0.008), Vector3(sx * 0.993, -0.02, zz), M.black, P)
		_bx(Vector3(0.006, 0.008, 1.34), Vector3(sx * 0.993, -0.42, -0.12), M.black, P)
		_bx(Vector3(0.025, 0.03, 0.16), Vector3(sx * 1.0, 0.32, 0.42), M.chrome, P)
		_bx(Vector3(0.01, 0.018, 1.36), Vector3(sx * 0.996, 0.0, -0.12), M.chrome, P)
		# the rocker under it
		_bx(Vector3(0.12, 0.08, 1.5), Vector3(sx * 0.93, -0.47, -0.1), M.black, body)
	# the cab's back wall, behind the seat, up to the roof
	_prism(_pts([[0.56, -0.44], [0.66, -0.44], [0.66, 0.54], [0.56, 0.54]]), -0.95, 0.95, 0.03, J, body)
	_prism(_pts([[0.56, 0.90], [0.64, 0.90], [0.64, 0.96], [0.60, 1.0], [0.56, 1.0]]), -0.9, 0.9, 0.02, W, body)
	for sx in [-1.0, 1.0]:
		_bx(Vector3(0.24, 0.36, 0.08), Vector3(sx * 0.74, 0.72, 0.6), W, body)
	# the greenhouse: the white roof, a bit narrower than the doors, its drip rails, the pillars
	_prism(_pts([[-0.53, 0.98], [0.62, 0.98], [0.62, 1.03], [0.56, 1.07], [-0.40, 1.075], [-0.52, 1.03]]), -0.87, 0.87, 0.045, W, body)
	for sx in [-1.0, 1.0]:
		_prism(_pts([[-0.80, 0.43], [-0.74, 0.43], [-0.47, 0.99], [-0.53, 0.99]]), sx * 0.82 - 0.04, sx * 0.82 + 0.04, 0.012, J, body)
		_prism(_pts([[0.50, 0.44], [0.62, 0.44], [0.62, 0.99], [0.50, 0.99]]), sx * 0.86 - 0.04, sx * 0.86 + 0.04, 0.012, W, body)
		_bx(Vector3(0.03, 0.025, 1.12), Vector3(sx * 0.9, 1.0, 0.02), M.chrome, body)
		# the side glass and the vent wing's post: the door's
		var G: Node3D = door_geom if sx < 0 else body
		var sg := _bx(Vector3(0.008, 0.52, 1.3), Vector3(sx * 0.9, 0.72, -0.1), M.glass, G)
		sg.transparency = 0.88
		sg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_bx(Vector3(0.02, 0.5, 0.02), Vector3(sx * 0.9, 0.72, -0.42), M.chrome, G, Vector3(-12, 0, 0))
		_bx(Vector3(0.02, 0.02, 1.08), Vector3(sx * 0.9, 0.975, 0.02), M.chrome, G)
	_bx(Vector3(1.66, 0.05, 0.06), Vector3(0, 0.975, -0.55), W, body)                              # windshield header
	var ws := _bx(Vector3(1.6, 0.62, 0.012), Vector3(0, 0.71, -0.645), M.glass, body, Vector3(-27.0, 0, 0))
	ws.transparency = 0.86
	ws.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rw := _bx(Vector3(1.24, 0.36, 0.012), Vector3(0, 0.72, 0.555), M.glass, body)
	rw.transparency = 0.6
	# the wipers, parked at the bottom of the glass
	for sx in [-0.62, 0.08]:
		var piv := Node3D.new()
		piv.position = Vector3(sx, 0.44, -0.80)
		piv.rotation.x = deg_to_rad(-27.0)
		body.add_child(piv)
		var arm := Node3D.new()
		arm.set_meta("side", sx)
		piv.add_child(arm)
		_bx(Vector3(0.52, 0.018, 0.018), Vector3(0.26, 0.0, 0.02), M.black, arm)
		arm.rotation.z = deg_to_rad(-6.0)
		wipers.append(arm)
	# the West Coast mirrors, the camper special's, out on their arms
	for sx in [-1.0, 1.0]:
		_bx(Vector3(0.26, 0.025, 0.025), Vector3(sx * 1.08, 0.5, -0.66), M.chrome, body)
		_bx(Vector3(0.26, 0.025, 0.025), Vector3(sx * 1.08, 0.86, -0.62), M.chrome, body, Vector3(0, 0, sx * 4.0))
		_bx(Vector3(0.025, 0.4, 0.025), Vector3(sx * 1.2, 0.68, -0.64), M.chrome, body)
		_bx(Vector3(0.17, 0.3, 0.04), Vector3(sx * 1.22, 0.68, -0.62), M.chrome, body)
		_bx(Vector3(0.14, 0.27, 0.01), Vector3(sx * 1.22, 0.68, -0.60), M.glass, body)


func _build_cab_inside() -> void:
	# the bench seat, its pleats, the back leaned a little
	_prism(_pts([[-0.05, -0.18], [0.46, -0.18], [0.46, -0.02], [0.40, 0.0], [0.0, -0.01], [-0.06, -0.05]]), -0.84, 0.84, 0.04, M.vinyl, body)
	_prism(_pts([[0.36, -0.02], [0.50, -0.02], [0.58, 0.58], [0.52, 0.62], [0.44, 0.6]]), -0.84, 0.84, 0.04, M.vinyl, body)
	for k in 7:
		_bx(Vector3(0.006, 0.5, 0.01), Vector3(-0.72 + k * 0.24, 0.3, 0.47), M.dark, body, Vector3(-8, 0, 0))
	# the doors' insides: the panel, the armrest, the window crank, the lock knob
	for sx in [-1.0, 1.0]:
		var P: Node3D = door_geom if sx < 0 else body
		_bx(Vector3(0.03, 0.62, 1.3), Vector3(sx * 0.885, 0.08, -0.12), M.dash, P)
		_bx(Vector3(0.07, 0.05, 0.36), Vector3(sx * 0.85, 0.14, 0.1), M.vinyl, P)
		_cy(0.012, 0.05, Vector3(sx * 0.85, 0.3, -0.25), M.chrome, P, Vector3(0, 0, 90), 8)
		_bx(Vector3(0.01, 0.1, 0.012), Vector3(sx * 0.83, 0.27, -0.25), M.chrome, P)
		_cy(0.008, 0.04, Vector3(sx * 0.86, 0.47, 0.38), M.chrome, P, Vector3.ZERO, 8)
		# the inside handle
		_bx(Vector3(0.02, 0.025, 0.1), Vector3(sx * 0.86, 0.3, -0.45), M.chrome, P)
		# the sun visor, flat up against the headliner
		_bx(Vector3(0.55, 0.015, 0.2), Vector3(sx * 0.42, 0.955, -0.42), M.vinyl, body)
	# the floor and its rubber mat, the transmission hump
	_bx(Vector3(1.8, 0.04, 1.5), Vector3(0, -0.4, -0.2), M.black, body)
	_bx(Vector3(0.36, 0.12, 0.7), Vector3(0, -0.34, -0.55), M.rubber, body)
	# the mirror on the glass, and what hangs from it: a cardboard pine gone pale, that swings
	_bx(Vector3(0.03, 0.06, 0.03), Vector3(0, 0.93, -0.56), M.dark, body)
	_bx(Vector3(0.26, 0.07, 0.025), Vector3(0, 0.88, -0.55), M.dark, body)
	var mg := _bx(Vector3(0.24, 0.055, 0.004), Vector3(0, 0.88, -0.536), M.glass, body)
	mg.material_override = M.chrome
	tree = Node3D.new()
	tree.position = Vector3(0.02, 0.845, -0.56)
	body.add_child(tree)
	_bx(Vector3(0.002, 0.08, 0.002), Vector3(0, -0.04, 0), M.white, tree)
	var pine := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.034, 0.055, 0.003)
	pine.mesh = pm
	pine.material_override = _m(Color("8fa88a"), 0.9)
	pine.position = Vector3(0, -0.105, 0)
	tree.add_child(pine)


func _build_bed_and_wheels(J: Material, W: Material) -> void:
	var WY := -0.48
	# the bed: a Styleside eight-foot, its sides with the arch over the wheel, the rail caps, the
	# floor, the tubs inside, the front wall, the tailgate and its latch handle
	for sx in [-1.0, 1.0]:
		var side := [[0.70, -0.42]] + _arch(1.96, WY, 0.47, -0.42) + [[3.08, -0.42], [3.08, 0.40], [3.04, 0.44], [0.74, 0.44], [0.70, 0.40]]
		_prism(_pts(side), -0.99 if sx < 0 else 0.86, -0.86 if sx < 0 else 0.99, 0.035, J, body)
		_bx(Vector3(0.16, 0.035, 2.38), Vector3(sx * 0.925, 0.455, 1.89), W, body)
		_bx(Vector3(0.05, 0.5, 1.0), Vector3(sx * 0.70, -0.2, 1.96), M.black, body)
		_bx(Vector3(0.2, 0.3, 0.9), Vector3(sx * 0.72, -0.08, 1.96), M.dark, body)
		_bx(Vector3(0.01, 0.018, 0.7), Vector3(sx * 0.996, 0.0, 1.08), M.chrome, body)
		_bx(Vector3(0.01, 0.018, 0.6), Vector3(sx * 0.996, 0.0, 2.75), M.chrome, body)
		_bx(Vector3(0.012, 0.05, 0.09), Vector3(sx * 0.995, 0.1, 2.98), pub.glow(Color("ff2a1a"), 0.2), body)
		# a mud flap behind the rear wheel
		_bx(Vector3(0.24, 0.3, 0.012), Vector3(sx * 0.84, -0.64, 2.5), M.rubber, body)
	_bx(Vector3(1.72, 0.04, 2.36), Vector3(0, -0.24, 1.88), M.dark, body)
	_prism(_pts([[0.68, -0.26], [0.76, -0.26], [0.76, 0.42], [0.68, 0.42]]), -0.88, 0.88, 0.015, J, body)
	_prism(_pts([[3.04, -0.42], [3.11, -0.42], [3.11, 0.40], [3.08, 0.43], [3.04, 0.43]]), -0.86, 0.86, 0.02, J, body)
	_bx(Vector3(0.22, 0.05, 0.02), Vector3(0, 0.3, 3.115), M.chrome, body)
	# the rear bumper, the tail lamps, the plate
	_prism(_pts([[3.12, -0.46], [3.30, -0.46], [3.31, -0.32], [3.26, -0.26], [3.12, -0.26]]), -1.0, 1.0, 0.03, M.chrome, body)
	for sx in [-0.93, 0.93]:
		_bx(Vector3(0.1, 0.24, 0.04), Vector3(sx, 0.02, 3.1), M.chrome, body)
		var tl := _bx(Vector3(0.08, 0.2, 0.02), Vector3(sx, 0.02, 3.12), pub.glow(Color("ff2a1a"), 0.0), body)
		tail_glow.append(tl)
	var plate := Label3D.new()
	plate.text = "ALBERTA  WILD ROSE COUNTRY\nBGX 417"
	plate.pixel_size = 0.0011
	plate.font_size = 48
	plate.modulate = Color("2a3a7a")
	plate.outline_size = 0
	plate.position = Vector3(0, -0.36, 3.322)
	plate.shaded = true
	body.add_child(plate)
	_bx(Vector3(0.32, 0.16, 0.01), Vector3(0, -0.36, 3.316), M.white, body)
	# the tailpipe, out from under the left side behind the wheel
	_cy(0.032, 0.4, Vector3(-0.62, -0.62, 2.95), M.dark, body, Vector3(90, 0, 0), 10)
	# the wheels: each a pivot (steers) and a tire (spins); the tire's shoulders rounded, a white
	# steel wheel deep in it, the hubcap, eight lugs' worth of chrome, two tread blocks so it turns
	for i in 4:
		var piv := Node3D.new()
		body.add_child(piv)
		var tire := Node3D.new()
		piv.add_child(tire)
		var sx := -1.0 if i % 2 == 0 else 1.0
		_cy(TruckSim.RADIUS, 0.21, Vector3.ZERO, M.rubber, tire, Vector3(0, 0, 90), 24)
		for e in [-1.0, 1.0]:
			var sh := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = TruckSim.RADIUS - 0.03 if e > 0 else TruckSim.RADIUS
			cm.bottom_radius = TruckSim.RADIUS if e > 0 else TruckSim.RADIUS - 0.03
			cm.height = 0.022
			cm.radial_segments = 24
			cm.rings = 1
			sh.mesh = cm
			sh.material_override = M.rubber
			sh.position = Vector3(e * 0.116, 0, 0)
			sh.rotation_degrees = Vector3(0, 0, -90)
			tire.add_child(sh)
		_cy(0.22, 0.2, Vector3(sx * 0.02, 0, 0), M.white, tire, Vector3(0, 0, 90), 18)
		_cy(0.11, 0.22, Vector3(sx * 0.03, 0, 0), M.chrome, tire, Vector3(0, 0, 90), 14)
		for k in 2:
			_bx(Vector3(0.2, 0.04, 0.08), Vector3(0, TruckSim.RADIUS - 0.012, 0).rotated(Vector3.RIGHT, k * PI), M.black, tire)
		wheels.append([piv, tire])


# the pine on the mirror swings with what the truck does: a pendulum hung in the cab, pushed by
# the cab's own acceleration
func _swing(dt: float) -> void:
	if dt <= 0.0 or tree == null:
		return
	var a := (sim.vel - _last_vel) / dt
	_last_vel = sim.vel
	var local := sim.rot.inverse() * (a + Vector3(0, 9.8, 0))
	_g_local = _g_local.lerp(sim.rot.inverse() * a, 1.0 - exp(-dt * 8.0))
	for k in 2:
		var push := (-local.x if k == 0 else local.z) / 9.8
		var acc := -18.0 * sin(float(_tree_th[k]) - atan(push)) - 1.6 * float(_tree_w[k])
		_tree_w[k] = float(_tree_w[k]) + acc * dt
		_tree_th[k] = clampf(float(_tree_th[k]) + float(_tree_w[k]) * dt, -1.2, 1.2)
	tree.rotation = Vector3(float(_tree_th[1]), 0.0, float(_tree_th[0]))


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
