# What's out on the road at night that shouldn't be (game/truck.gd keeps one). Once in a drive,
# maybe twice, never on a schedule he can learn:
#
#   the figure    somebody very tall on the gravel ahead, in the headlights, turned to the truck,
#                 its eyes giving back the light the way a deer's do. The radio goes under as he
#                 nears it and a voice comes through every station. He passes it. In the mirror it's
#                 still there, in the red of the tail lamps, watching him go. Turn round and look:
#                 there's nobody on the road. Stop and get out: nobody.
#   the lights    headlights in the mirror, a long way back, closing slowly, keeping his speed. He
#                 slows, they slow. He stops, they stop. Over his shoulder, out the back window:
#                 nothing, no car, no road lit. Then they go out.
#
# Both live on a layer only the rearview mirror's camera draws (MIRROR_LAYER): the eye never sees
# what the mirror does, which is the whole of it.
class_name TruckOdd
extends Node3D

const MIRROR_LAYER := 17
const FIG_AHEAD := 95.0

var truck                       # game/truck.gd
var figure: Node3D
var eyes: Array = []
var lamps: Node3D               # the headlights that aren't there
var state := ""                 # "", "figure", "lights"
var flicker := 0.0              # the truck's own lamps dip near it (game/truck.gd reads it)
var _parts: Array = []          # every mesh of the figure, to move between the layers
var _lamp_parts: Array = []
var _rng := RandomNumberGenerator.new()
var _driven := 0.0
var _next := 80.0
var _done := {}
var _t := 0.0
var _d := 0.0                   # where it is along the road (the road's own distance)
var _dir := 1.0                 # which way he was going when it began: 1 north, -1 south
var _passed := false
var _passed_t := 0.0
var _still := 0.0
var _gap := 90.0
var _len := 60.0
var _fade := 1.0
var _say := ""


func setup(t) -> void:
	truck = t
	_rng.randomize()
	name = "odd"
	truck.road.add_child(self)
	for c in [truck.view.cam, truck.view.mcam]:
		if c != null:
			(c as Camera3D).set_cull_mask_value(MIRROR_LAYER, false)
	_build_figure()
	_build_lamps()
	end_all()


func begin() -> void:
	end_all()
	_driven = 0.0
	_done.clear()
	_next = _rng.randf_range(55.0, 95.0)


func end_all() -> void:
	state = ""
	flicker = 0.0
	figure.visible = false
	lamps.visible = false
	if truck != null and truck.radio != null:
		truck.radio.interfere = 0.0
		truck.radio.bleed = ""


# begin one now (tests, and the next one when its time comes)
func start(what: String) -> bool:
	var a: Array = truck.road.along(truck.sim.pos)
	if float(a[1]) > 40.0:
		return false              # off the road somewhere: nothing out here
	var dir: Vector3 = truck.road.dirs[int(a[3])]
	var fwd: Vector3 = truck.sim.forward()
	_dir = 1.0 if fwd.dot(dir) >= 0.0 else -1.0
	_t = 0.0
	_done[what] = true
	if what == "figure":
		_d = float(a[0]) + _dir * FIG_AHEAD
		_passed = false
		_still = 0.0
		_say = ""
		var p := _road_point(_d, 4.9 * _dir)
		figure.global_position = p
		_layers(_parts, true)
		_eyes_color(Color(0.85, 1.0, 0.8))
		figure.visible = true
		state = "figure"
		return true
	if what == "lights":
		_gap = 95.0
		_len = _rng.randf_range(45.0, 70.0)
		_fade = 1.0
		_place_lamps(float(a[0]))
		lamps.visible = true
		state = "lights"
		return true
	return false


func step(dt: float) -> void:
	var sim: TruckSim = truck.sim
	var spd := absf(sim.speed)
	# on his feet: whatever it was, it isn't
	if truck.foot.out:
		if state != "":
			end_all()
		return
	if spd > 8.0:
		_driven += dt
	if state == "" and _driven > _next:
		var what := ""
		if not _done.has("figure") and spd > 12.0:
			what = "figure"
		elif not _done.has("lights") and spd > 8.0:
			what = "lights"
		if what != "" and start(what):
			_next = _driven + _rng.randf_range(120.0, 240.0)
		else:
			_next = _driven + 20.0
	match state:
		"figure":
			_figure(dt)
		"lights":
			_lights(dt)


func _road_point(d: float, side: float) -> Vector3:
	var r: Array = truck.road.at_dist(d - truck.road.zero)
	var p: Vector3 = r[0]
	var dir: Vector3 = r[1]
	var s := Vector3(-dir.z, 0.0, dir.x)
	var q := p + s * side
	# the road's own height, not the bank's: height() out on the gravel can find the cut beside it
	return Vector3(q.x, minf(truck.road.height(q.x, q.z), p.y + 0.05), q.z)


func _figure(dt: float) -> void:
	_t += dt
	var sim: TruckSim = truck.sim
	var radio: TruckRadio = truck.radio
	var to := figure.global_position - sim.pos
	to.y = 0.0
	var dist := to.length()
	# it turns to him as he goes by, all of it, slowly
	var want := atan2(-to.x, -to.z) + PI
	figure.rotation.y = lerp_angle(figure.rotation.y, want, 1.0 - exp(-dt * 1.4))
	var a: Array = truck.road.along(sim.pos)
	var ahead := (_d - float(a[0])) * _dir
	if not _passed and ahead < -1.5:
		# past it: from here it's only in the mirror
		_passed = true
		_passed_t = 0.0
		_layers(_parts, false)
		_eyes_color(Color(1.0, 0.25, 0.18))
		# and in the mirror it isn't on the shoulder now: it's out in the road behind him, in his
		# lane, in the red of the tail lamps. Nobody saw it step out.
		figure.global_position = _road_point(_d, 1.6 * _dir)
	var near := smoothstep(70.0, 12.0, dist)
	if _passed:
		_passed_t += dt
		near = smoothstep(40.0, 10.0, dist) * clampf(1.0 - _passed_t / 3.0, 0.0, 1.0)
		if _passed_t > 7.0 or dist > 120.0:
			end_all()
			return
	radio.interfere = near
	# and through every station, the flat voice: the last thing he said tonight, or where he is
	if near > 0.6:
		if _say == "":
			_say = ("\"" + str(radio.his_words[radio.his_words.size() - 1]) + "\"") if not radio.his_words.is_empty() \
				else TruckRadio.place_name(float(a[0]) - truck.road.zero) + "."
		radio.bleed = _say
	else:
		radio.bleed = ""
	flicker = near * 0.7
	# its eyes: the headlamps given back, when they're on it
	var lit: float = 1.0 if truck.lights > 0 and not _passed else (0.6 if truck.lights > 0 else 0.1)
	for e in eyes:
		((e as MeshInstance3D).material_override as StandardMaterial3D).emission_energy_multiplier = lit * (2.5 + 2.0 * near)
	# he's stopped short of it, and looks away: it isn't there when he looks back
	if not _passed:
		if absf(sim.speed) < 1.0:
			_still += dt
		else:
			_still = 0.0
		if _still > 2.5 and not _looking_at(figure.global_position + Vector3(0, 1.5, 0)):
			end_all()
			return
		if dist > 180.0:
			end_all()


func _looking_at(p: Vector3) -> bool:
	var cam: Camera3D = truck.view.cam
	var f := -cam.global_transform.basis.z
	var to := (p - cam.global_position).normalized()
	return f.dot(to) > cos(deg_to_rad(40.0))


func _lights(dt: float) -> void:
	_t += dt
	var sim: TruckSim = truck.sim
	var spd := absf(sim.speed)
	# closing, slowly, while he goes; holding when he slows; stopping when he stops
	if spd > 3.0:
		_gap = maxf(22.0, _gap - dt * 1.1)
	var a: Array = truck.road.along(sim.pos)
	_place_lamps(float(a[0]))
	truck.radio.interfere = 0.22 * _fade
	if _t > _len:
		# they go out, all at once, like a hand on a switch
		_fade = maxf(0.0, _fade - dt * 4.0)
		for m in _lamp_parts:
			var mat := (m as MeshInstance3D).material_override as StandardMaterial3D
			mat.emission_energy_multiplier = float(m.get_meta("e")) * _fade
		if _fade <= 0.0:
			for m in _lamp_parts:
				((m as MeshInstance3D).material_override as StandardMaterial3D).emission_energy_multiplier = float(m.get_meta("e"))
			end_all()


func _place_lamps(at: float) -> void:
	var d := at - _dir * _gap
	var p := _road_point(d, 1.8 * _dir)
	var ahead := _road_point(d + _dir * 2.0, 1.8 * _dir)
	lamps.global_position = p
	var f := ahead - p
	lamps.rotation.y = atan2(-f.x, -f.z)


# ---------------------------------------------------------------- drawn

func _mat(c: Color, rough: float, emit := Color.BLACK, e := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = e
	return m


func _part(mesh: Mesh, pos: Vector3, m: Material, rot := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	(parent if parent != null else figure).add_child(mi)
	_parts.append(mi)
	return mi


func _build_figure() -> void:
	figure = Node3D.new()
	figure.name = "figure"
	add_child(figure)
	# too tall by a head, too thin, a long coat soaked black, stooped a little, its head on one side
	var coat := _mat(Color(0.035, 0.035, 0.04), 0.35)
	var skin := _mat(Color(0.16, 0.15, 0.14), 0.7)
	var body := Node3D.new()
	body.rotation_degrees = Vector3(-6.0, 0.0, 2.0)
	figure.add_child(body)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.17
	cm.bottom_radius = 0.27
	cm.height = 1.45
	cm.radial_segments = 10
	_part(cm, Vector3(0, 0.78, 0), coat, Vector3.ZERO, body)
	var ch := CapsuleMesh.new()
	ch.radius = 0.2
	ch.height = 0.62
	_part(ch, Vector3(0, 1.66, 0.02), coat, Vector3(0, 0, 90), body)
	var neck := CylinderMesh.new()
	neck.top_radius = 0.045
	neck.bottom_radius = 0.06
	neck.height = 0.26
	_part(neck, Vector3(0, 1.9, 0.05), skin, Vector3(14, 0, 0), body)
	var head := SphereMesh.new()
	head.radius = 0.105
	head.height = 0.25
	var hd := _part(head, Vector3(0.02, 2.1, 0.09), skin, Vector3(0, 0, 11), body)
	# the arms: down past where the knees would be, the hands open
	for sx in [-1.0, 1.0]:
		var arm := CylinderMesh.new()
		arm.top_radius = 0.06
		arm.bottom_radius = 0.045
		arm.height = 1.15
		arm.radial_segments = 8
		_part(arm, Vector3(sx * 0.31, 1.12, 0.02), coat, Vector3(0, 0, sx * 4.0), body)
		var hand := BoxMesh.new()
		hand.size = Vector3(0.05, 0.2, 0.09)
		_part(hand, Vector3(sx * 0.35, 0.47, 0.03), skin, Vector3(0, 0, sx * 6.0), body)
	# its eyes: nothing but what they give back
	for sx in [-1.0, 1.0]:
		var em := SphereMesh.new()
		em.radius = 0.014
		em.height = 0.028
		var e := _part(em, Vector3(sx * 0.038, 0.01, -0.095), _mat(Color.BLACK, 1.0, Color(0.85, 1.0, 0.8), 3.0), Vector3.ZERO, hd)
		eyes.append(e)


func _eyes_color(c: Color) -> void:
	for e in eyes:
		((e as MeshInstance3D).material_override as StandardMaterial3D).emission = c


func _build_lamps() -> void:
	lamps = Node3D.new()
	lamps.name = "lights_behind"
	add_child(lamps)
	# two round lamps a car's width apart, and the glare round each, facing up the road at him
	for sx in [-0.72, 0.72]:
		var q := QuadMesh.new()
		q.size = Vector2(0.24, 0.24)
		var core := MeshInstance3D.new()
		core.mesh = q
		core.material_override = _mat(Color.BLACK, 1.0, Color(1.0, 0.9, 0.7), 9.0)
		(core.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		core.position = Vector3(sx, 0.72, 0)
		core.set_meta("e", 9.0)
		lamps.add_child(core)
		_lamp_parts.append(core)
		var g := QuadMesh.new()
		g.size = Vector2(1.6, 1.6)
		var glare := MeshInstance3D.new()
		glare.mesh = g
		var gm := _mat(Color.BLACK, 1.0, Color(1.0, 0.85, 0.6), 1.2)
		gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.albedo_texture = _glare_tex()
		gm.albedo_color = Color(1.0, 0.85, 0.6)
		gm.emission_enabled = false
		glare.material_override = gm
		glare.position = Vector3(sx, 0.72, -0.05)
		lamps.add_child(glare)
	_layers(lamps.get_children(), false)


func _glare_tex() -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / (n * 0.5)
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.2)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


# on the eye's layer and the mirror's, or the mirror's alone
func _layers(parts: Array, both: bool) -> void:
	for p in parts:
		if p is VisualInstance3D:
			(p as VisualInstance3D).layers = (1 if both else 0) | (1 << (MIRROR_LAYER - 1))


func eye_sees_figure() -> bool:
	return ((_parts[0] as VisualInstance3D).layers & 1) != 0
