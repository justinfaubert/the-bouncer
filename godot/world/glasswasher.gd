# The glasswasher on the end of the back bar, by the till: a conveyor machine somebody bought used
# from a hotel that closed, too big for the bar, never moved. Racks of empties go in on the belt at
# the till end of it, under the curtain of plastic strips, through the spray, and come out at the
# door end clean and steaming, where they sit till Jim takes them off. A switch on its front, ON and
# OFF, with an amber lamp over it.
#
# Jim keeps it running all night. Switch it off and the belt stops where it is, a rack half in the
# spray if that's where it was; leave it off long enough and he'll switch it back on, when he thinks
# nobody's looking (he always looks). The racks go round on their own while it runs: when the clean
# one has sat at the end long enough and nobody's looking at it, Jim's had it off and put up the
# glasses, and the next rack of empties is waiting on the belt where it goes in.
#
# Built by world/dressing.gd; flipped by game/main.gd (toy "washer_switch"). Claude's, all of it.
class_name Glasswasher
extends Node3D

signal flipped(on: bool, by_jim: bool)

const X0 := 0.03            # the machine's back, against the west wall's back bar
const X1 := 0.6             # its front, toward the bartender
const Z0 := 6.6             # the till end, where the empties go in
const Z1 := 7.68            # the door end, where they come out
const BED := 0.985          # the belt's top
const HOOD := [6.88, 7.4]   # the hood over the spray
const SPEED := 0.05         # metres a second
const LOAD_Z := 6.79        # a rack's middle, waiting to go in
const OUT_Z := 7.49         # a rack's middle, at the end stop
const RACK := 0.36
const SLAT := 0.045         # the belt's slats, this far apart
const JIM_AFTER := 140.0    # seconds off before he switches it back on
const TAKE_AFTER := 9.0     # seconds a clean rack sits before he can take it off

var on := true
var flips := 0
var loads := 0              # racks of empties put on since the night began
var washed := 0             # and come out clean
var pub: Pub
var racks: Array = []       # [{node, z, clean, out_t, hidden}]
var slats: Array = []
var strips: Array = []      # the curtain's strips: [node, end (0 in, 1 out)]
var lamp: MeshInstance3D
var lever: Node3D
var hum: AudioStreamPlayer3D
var steam: CPUParticles3D
var _phase := 0.0
var _off_t := 0.0
var _sway := [0.0, 0.0]     # the two curtains: how hard a rack's just pushed through
var _hum_level := 1.0


func build(p: Pub) -> void:
	pub = p
	name = "glasswasher"
	var steel: Material = pub.M.steel
	var dark := pub.mat(Color("2a2c2e"), 0.6, 0.2, 3)
	# the cabinet under it, steel, standing on the floor past the end of the back bar
	pub.box(Vector3(X1 - X0, 0.955, Z1 - Z0), Vector3((X0 + X1) / 2.0, 0.4775, (Z0 + Z1) / 2.0), steel, 0.0, self)
	# a kick plate, dented, and the drain hose out of its side to the floor drain
	var kick := pub.box(Vector3(0.01, 0.12, Z1 - Z0 - 0.06), Vector3(X1 + 0.004, 0.08, (Z0 + Z1) / 2.0), dark, 0.0, self)
	kick.rotation.y = deg_to_rad(0.6)
	pub._stick(Vector3(0.3, 0.3, Z1 + 0.005), Vector3(0.36, 0.02, Z1 + 0.09), 0.018, pub.M.black, self, 8)
	# the bed: two rails along it, the belt between
	for x in [X0 + 0.035, X1 - 0.035]:
		pub.box(Vector3(0.02, 0.05, Z1 - Z0 + 0.02), Vector3(x, BED + 0.012, (Z0 + Z1) / 2.0), steel, 0.0, self)
	pub.box(Vector3(X1 - X0 - 0.09, 0.012, Z1 - Z0), Vector3((X0 + X1) / 2.0, BED - 0.016, (Z0 + Z1) / 2.0), pub.M.black, 0.0, self)
	var belt := Node3D.new()
	belt.name = "belt"
	add_child(belt)
	var n := int((Z1 - Z0) / SLAT)
	for i in n:
		var s := pub.box(Vector3(X1 - X0 - 0.1, 0.008, 0.012), Vector3((X0 + X1) / 2.0, BED - 0.004, Z0 + i * SLAT), dark, 0.0, belt)
		slats.append(s)
	# the hood: steel, its ends open, a strip curtain in each
	var hz := (HOOD[0] + HOOD[1]) / 2.0
	var hl: float = HOOD[1] - HOOD[0]
	pub.box(Vector3(X1 - X0, 0.025, hl), Vector3((X0 + X1) / 2.0, 1.49, hz), steel, 0.0, self)
	for x in [X0 + 0.0125, X1 - 0.0125]:
		pub.box(Vector3(0.025, 0.5, hl), Vector3(x, 1.24, hz), steel, 0.0, self)
	for end in 2:
		var z: float = HOOD[end]
		pub.box(Vector3(X1 - X0, 0.06, 0.03), Vector3((X0 + X1) / 2.0, 1.45, z), steel, 0.0, self)
		var curtain := glass_strip()
		var k := 0
		var x := X0 + 0.05
		while x < X1 - 0.04:
			var hinge := Node3D.new()
			hinge.position = Vector3(x, 1.43, z)
			add_child(hinge)
			var st := pub.box(Vector3(0.05, 0.42, 0.003), Vector3(0, -0.21, 0), curtain, 0.0, hinge)
			st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			strips.append([hinge, end, k])
			x += 0.052
			k += 1
	# on the hood's front: the maker's plate, the gauge, the amber lamp, and the switch
	var face := X1 + 0.002
	var plate := pub.box(Vector3(0.004, 0.05, 0.16), Vector3(face, 1.42, hz - 0.12), pub.M.brass, 0.0, self)
	plate.rotation.x = deg_to_rad(1.2)
	var gauge := pub.cyl(0.03, 0.03, 0.012, Vector3(face + 0.004, 1.32, hz - 0.13), pub.M.paper, self, 16)
	gauge.rotation.z = PI / 2.0
	var needle := pub.box(Vector3(0.002, 0.024, 0.003), Vector3(face + 0.011, 1.326, hz - 0.13), pub.M.black, 0.0, self)
	needle.rotation.x = deg_to_rad(-35)
	var sw := Node3D.new()
	sw.name = "switch"
	sw.position = Vector3(face, 1.27, hz + 0.1)
	add_child(sw)
	pub.box(Vector3(0.012, 0.11, 0.07), Vector3(0.006, 0, 0), pub.M.black, 0.0, sw)
	var on_lbl := pub.box(Vector3(0.002, 0.012, 0.03), Vector3(0.0125, 0.042, 0), pub.M.paper, 0.0, sw)
	on_lbl.name = "on_label"
	pub.box(Vector3(0.002, 0.012, 0.03), Vector3(0.0125, -0.042, 0), pub.mat(Color("8a8a84"), 0.8, 0.0, 3), 0.0, sw)
	lever = Node3D.new()
	lever.position = Vector3(0.012, 0, 0)
	sw.add_child(lever)
	var lv := pub.cyl(0.006, 0.008, 0.045, Vector3(0.022, 0, 0), steel, lever, 10)
	lv.rotation.z = PI / 2.0
	pub.ball(0.009, Vector3(0.045, 0, 0), pub.M.black, lever)
	lamp = pub.ball(0.011, Vector3(face + 0.006, 1.36, hz + 0.1), pub.glow(Color("ffb040"), 2.2), self)
	# its sound, from inside the hood: the motor and the spray
	hum = AudioStreamPlayer3D.new()
	hum.position = Vector3((X0 + X1) / 2.0, 1.2, hz)
	hum.unit_size = 1.6
	hum.max_distance = 18.0
	hum.max_db = -4.0
	hum.attenuation_filter_cutoff_hz = 7000.0
	var st = _wav("washer_run", true)
	if st != null:
		hum.stream = st
		hum.volume_db = -14.0
		hum.autoplay = false
	add_child(hum)
	# the steam out of the door end and off the clean glasses
	steam = CPUParticles3D.new()
	steam.position = Vector3((X0 + X1) / 2.0, 1.12, HOOD[1] + 0.05)
	steam.amount = 26
	steam.lifetime = 2.6
	steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	steam.emission_box_extents = Vector3(0.2, 0.06, 0.12)
	steam.direction = Vector3(0.1, 1, 0.3)
	steam.spread = 18.0
	steam.gravity = Vector3(0, 0.05, 0)
	steam.initial_velocity_min = 0.04
	steam.initial_velocity_max = 0.1
	steam.scale_amount_min = 0.6
	steam.scale_amount_max = 1.4
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.albedo_color = Color(0.85, 0.82, 0.76, 0.06)
	sm.albedo_texture = _puff()
	sm.vertex_color_use_as_albedo = true
	q.material = sm
	steam.mesh = q
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.add_point(0.25, Color(1, 1, 1, 1.0))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0.0))
	steam.color_ramp = ramp
	steam.emitting = true
	add_child(steam)
	# two racks: a rack of empties waiting to go in, and one done at the end stop
	racks.append(_rack(LOAD_Z, false))
	racks.append(_rack(OUT_Z, true))
	racks[1].out_t = 0.0
	_show()
	pub.anchors["glasswasher"] = Vector3(X1 - 0.05, 1.42, hz)
	pub.anchors["washer_switch"] = sw.position + Vector3(0.02, 0, 0)


func glass_strip() -> Material:
	var m := pub.glass(Color("cfd8c8"), 0.32)
	return m


# A rack: the grey plastic grid, and nine pints upside down in it, dirty or clean.
func _rack(z: float, clean: bool) -> Dictionary:
	var r := Node3D.new()
	r.position = Vector3((X0 + X1) / 2.0, BED, z)
	add_child(r)
	var grey := pub.mat(Color("4e5a64"), 0.7, 0.0, 3)
	var h := RACK / 2.0
	for s in [-1.0, 1.0]:
		pub.box(Vector3(RACK, 0.07, 0.01), Vector3(0, 0.035, s * h), grey, 0.0, r)
		pub.box(Vector3(0.01, 0.07, RACK), Vector3(s * h, 0.035, 0), grey, 0.0, r)
	for k in [-1, 0, 1]:
		pub.box(Vector3(RACK, 0.006, 0.008), Vector3(0, 0.004, k * 0.06 + 0.03), grey, 0.0, r)
		pub.box(Vector3(0.008, 0.006, RACK), Vector3(k * 0.06 + 0.03, 0.004, 0), grey, 0.0, r)
	var gl := Node3D.new()
	gl.name = "glasses"
	r.add_child(gl)
	var dirt := Node3D.new()
	dirt.name = "dirt"
	r.add_child(dirt)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(z * 1000.0)
	for i in 3:
		for j in 3:
			var at := Vector3((i - 1) * 0.112 + rng.randf_range(-0.006, 0.006), 0.006, (j - 1) * 0.112 + rng.randf_range(-0.006, 0.006))
			# upside down: the wide mouth on the rack
			var g := pub.cyl(0.034, 0.042, 0.15, at + Vector3(0, 0.075, 0), pub.M.pint, gl, 12)
			g.rotation.z = rng.randf_range(-0.03, 0.03)
			# the empties: the dregs run down to the rim, and the lace dried on the inside
			var d := pub.cyl(0.041, 0.041, 0.014, at + Vector3(0, 0.009, 0), pub.M.dregs, dirt, 12)
			d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var lace := pub.cyl(0.036, 0.04, rng.randf_range(0.05, 0.09), at + Vector3(0, 0.05, 0), pub.M.lace, dirt, 12)
			(lace.mesh as CylinderMesh).cap_top = false
			(lace.mesh as CylinderMesh).cap_bottom = false
	var rk := {"node": r, "z": z, "clean": clean, "out_t": -1.0, "hidden": false}
	_dirty(rk, not clean)
	return rk


func _dirty(rk: Dictionary, dirty: bool) -> void:
	rk.clean = not dirty
	((rk.node as Node3D).get_node("dirt") as Node3D).visible = dirty


func _wav(n: String, loop: bool) -> AudioStream:
	var path := "res://audio/" + n + ".wav"
	if not FileAccess.file_exists(path):
		return null
	var st := AudioStreamWAV.load_from_file(path)
	if st != null and loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = int(st.get_length() * st.mix_rate)
	return st


func _puff() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 2))
	return ImageTexture.create_from_image(img)


# The switch, flipped by him (or, with by_jim, by Jim).
func flip(by_jim := false) -> bool:
	on = not on
	flips += 1
	_off_t = 0.0
	_clack()
	_show()
	flipped.emit(on, by_jim)
	return on


func set_on(v: bool) -> void:
	if v != on:
		on = v
		_show()


func _show() -> void:
	if lever == null:
		return
	lever.rotation.z = deg_to_rad(28.0 if on else -28.0)
	(lamp.material_override as ShaderMaterial).set_shader_parameter("emission_energy", 2.2 if on else 0.0)
	(lamp.material_override as ShaderMaterial).set_shader_parameter("albedo", Color("ffb040") if on else Color("5a4020"))
	if hum.stream != null and is_inside_tree():
		if on and not hum.playing:
			hum.play(randf() * 3.0)


func _clack() -> void:
	var st = _wav("washer_clack", false)
	if st == null or not is_inside_tree():
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = st
	p.position = lever.global_position if lever.is_inside_tree() else Vector3(X1, 1.27, 7.24)
	p.unit_size = 1.2
	p.volume_db = -6.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _ready() -> void:
	_show()


func _process(dt: float) -> void:
	tick(dt, _seen_by_him())


# What he can see of the end stop now: from the camera, in its frustum and near enough to notice.
func _seen_by_him() -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return false
	var p := Vector3((X0 + X1) / 2.0, 1.1, OUT_Z)
	return cam.global_position.distance_to(p) < 9.0 and cam.is_position_in_frustum(p)


# The machine for dt seconds: the belt, the racks on it, the curtains, the steam, the hum; Jim, if
# it's been off too long. `seen`: whether he's looking at it (Jim waits till he isn't).
func tick(dt: float, seen: bool) -> void:
	# the hum runs down when it's switched off, and up when it's on
	_hum_level = move_toward(_hum_level, 1.0 if on else 0.0, dt / (0.6 if on else 1.8))
	if hum.stream != null:
		if _hum_level <= 0.001:
			if hum.playing:
				hum.stop()
		else:
			hum.volume_db = -14.0 + linear_to_db(maxf(_hum_level, 0.001))
			hum.pitch_scale = 0.75 + 0.25 * _hum_level
	steam.emitting = _hum_level > 0.3 or _steaming()
	for i in 2:
		_sway[i] = move_toward(_sway[i], 0.0, dt * 0.9)
	var t := Time.get_ticks_msec() / 1000.0
	for s in strips:
		var h: Node3D = s[0]
		var end: int = s[1]
		var k: int = s[2]
		h.rotation.x = -_sway[end] * (0.45 + 0.25 * sin(k * 1.7)) * (0.6 + 0.4 * sin(t * 7.0 + k)) + (0.015 * sin(t * 1.3 + k * 0.6) if on else 0.0)
	if not on:
		_off_t += dt
		if _off_t > JIM_AFTER and not seen:
			flip(true)
		return
	# the belt
	_phase = fmod(_phase + SPEED * dt, SLAT)
	for i in slats.size():
		var s: MeshInstance3D = slats[i]
		var z := Z0 + fmod(i * SLAT + _phase, Z1 - Z0)
		s.position.z = z
		# the slats go under at the ends and come back beneath
		s.visible = z > Z0 + 0.01 and z < Z1 - 0.01
	var a: Dictionary = racks[0]
	var b: Dictionary = racks[1]
	for rk in racks:
		if rk.hidden:
			continue
		var ahead_free := true
		for other in racks:
			if other != rk and not other.hidden and float(other.z) > float(rk.z) and float(other.z) - float(rk.z) < RACK + 0.01:
				ahead_free = false
		if float(rk.z) < OUT_Z - 0.0005 and ahead_free:
			var was := float(rk.z)
			rk.z = minf(OUT_Z, float(rk.z) + SPEED * dt)
			# through a curtain: it swings
			for e in 2:
				var edge: float = HOOD[e]
				if (was - RACK / 2.0 < edge and float(rk.z) + RACK / 2.0 > edge) or (was + RACK / 2.0 < edge and float(rk.z) + RACK / 2.0 >= edge):
					_sway[e] = minf(1.0, _sway[e] + dt * 3.0)
			# in the spray (under the hood, out of sight), the empties come clean
			if not rk.clean and float(rk.z) > (HOOD[0] + HOOD[1]) / 2.0:
				_dirty(rk, false)
				washed += 1
			if float(rk.z) >= OUT_Z - 0.0005:
				rk.out_t = 0.0
		(rk.node as Node3D).position.z = rk.z
	# at the end stop: steaming, then Jim takes it off when nobody's looking
	for rk in racks:
		if rk.hidden or float(rk.out_t) < 0.0:
			continue
		rk.out_t = float(rk.out_t) + dt
		if float(rk.out_t) > TAKE_AFTER and not seen:
			rk.hidden = true
			rk.out_t = -1.0
			(rk.node as Node3D).visible = false
	# and the next rack of empties goes on where it goes in, if the place is clear
	for rk in racks:
		if not rk.hidden:
			continue
		var clear := true
		for other in racks:
			if other != rk and not other.hidden and float(other.z) < LOAD_Z + RACK + 0.01:
				clear = false
		if clear and not seen:
			rk.hidden = false
			loads += 1
			rk.z = LOAD_Z
			_dirty(rk, true)
			(rk.node as Node3D).position.z = LOAD_Z
			(rk.node as Node3D).visible = true


func _steaming() -> bool:
	for rk in racks:
		if not rk.hidden and float(rk.out_t) >= 0.0 and float(rk.out_t) < 40.0:
			return true
	return false
