# What's far off, so the island isn't the whole world (world/island_road.gd keeps one). Across the
# strait to the east, the mainland's mountains in three ranges, each paler and higher than the one
# in front of it, snow on the far peaks; a string of town lights along its shore. Inland to the
# west, the island's own spine. On the water, a lighthouse on the rock in the strait turning its
# beam, and the ferry crossing with its lights on, slower than you'd think. On the hill, the radio
# station's mast with its red lamps (CKTD: game/truck_radio.gd).
#
# All of it is kilometres off, further than the camera draws. Each layer is drawn smaller and
# nearer by the same factor round the eye (a homothety: drawn = eye + (true - eye) * s), so from
# where he is it covers exactly what it would at its true distance, and moves past exactly as
# slowly as it would. Every frame the layers are re-centred on the eye.
class_name IslandFar
extends Node3D

const DRAW := 540.0                 # how far off it's drawn
const STRAIT_Z := 9000.0            # the mainland's shore

var layers: Array = []              # [node, true distance]
var cam: Camera3D
var _beam: Node3D
var _flash: MeshInstance3D
var _ferry: Node3D
var _mast_lamps: Array = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func build(camera: Camera3D) -> void:
	cam = camera
	_rng.seed = 1311
	name = "far"
	# the mainland: foothills, the range, the peaks
	_range(7200.0, 380.0, 820.0, Color("0b1016"), Color("0b1016"), 0.0, 3)
	_range(11000.0, 900.0, 1750.0, Color("111822"), Color("26303c"), 0.82, 7)
	_range(16500.0, 1500.0, 2700.0, Color("18202b"), Color("3c4654"), 0.7, 11)
	# the island's spine, inland
	_range(-3200.0, 180.0, 520.0, Color("0a0e0d"), Color("0a0e0d"), 0.0, 17)
	_range(-5600.0, 420.0, 900.0, Color("0e1416"), Color("1a2228"), 0.85, 23)
	_shore_lights()
	_lighthouse()
	_ferry_build()
	_mast()


func _process(dt: float) -> void:
	_t += dt
	if cam == null or not is_instance_valid(cam):
		return
	var c := cam.global_position
	for l in layers:
		var n: Node3D = l[0]
		var s: float = DRAW / float(l[1])
		n.transform = Transform3D(Basis.from_scale(Vector3(s, s, s)), c * (1.0 - s))
	# the lighthouse: one turn every nine seconds; the lamp flares when the beam comes round to him
	if _beam != null:
		_beam.rotation.y = fmod(_t * TAU / 9.0, TAU)
		var to := (c - _beam.global_position)
		var face := Vector2(-sin(_beam.rotation.y), -cos(_beam.rotation.y)).dot(Vector2(to.x, to.z).normalized())
		(_flash.material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.95, 0.8) * (0.25 + 3.0 * pow(maxf(face, 0.0), 40.0))
	# the ferry: across and back, twenty minutes a crossing
	if _ferry != null:
		var k := fmod(_t / 1200.0, 2.0)
		var x := lerpf(-3200.0, 2600.0, k if k < 1.0 else 2.0 - k)
		_ferry.position.x = x
		_ferry.rotation.y = 0.0 if k < 1.0 else PI
	# the mast: its red lamps, once a second, together
	var on := fmod(_t, 1.6) < 0.8
	for m in _mast_lamps:
		(m as MeshInstance3D).visible = on


func _layer(true_dist: float) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	layers.append([n, absf(true_dist)])
	return n


func _unshaded(c: Color, add := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	m.albedo_color = c
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if add:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.no_depth_test = false
	return m


# a range of mountains along z = d (east if d > 0), from its foot to a ragged ridge between lo and
# hi metres, with snow above snow_k of the way up (0 for none)
func _range(d: float, lo: float, hi: float, c: Color, top: Color, snow_k: float, seed_: int) -> void:
	var n := _layer(d)
	var noise := FastNoiseLite.new()
	noise.seed = seed_
	noise.frequency = 1.0 / (absf(d) * 0.18)
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.55
	var reach := absf(d) * 1.25
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := absf(d) / 90.0
	var x := -reach
	var prev: Array = []
	while x <= reach:
		# the ridge, and a little wander in and out so it isn't a wall
		var r := clampf(noise.get_noise_1d(x) * 0.5 + 0.5, 0.0, 1.0)
		var h := lerpf(lo, hi, pow(r, 1.4))
		var z := d + noise.get_noise_1d(x * 0.5 + 9000.0) * absf(d) * 0.08
		var cur := [Vector3(x, -80.0, z), Vector3(x, h, z), h]
		if not prev.is_empty():
			var a: Vector3 = prev[0]
			var b: Vector3 = prev[1]
			var cc: Vector3 = cur[1]
			var dd: Vector3 = cur[0]
			for v in [[a, c], [b, _top(c, top, snow_k, lo, hi, float(prev[2]))], [cc, _top(c, top, snow_k, lo, hi, h)],
					[a, c], [cc, _top(c, top, snow_k, lo, hi, h)], [dd, c]]:
				st.set_color(v[1])
				st.add_vertex(v[0])
		prev = cur
		x += step
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := _unshaded(Color.WHITE)
	m.vertex_color_use_as_albedo = true
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	n.add_child(mi)


func _top(c: Color, top: Color, snow_k: float, lo: float, hi: float, h: float) -> Color:
	if snow_k <= 0.0:
		return c
	var k := smoothstep(lo + (hi - lo) * snow_k * 0.8, hi, h)
	return c.lerp(top, k)


func _dots(n: Node3D, at: Array, size: float, col: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mm.mesh = q
	mm.instance_count = at.size()
	for k in at.size():
		mm.set_instance_transform(k, Transform3D(Basis(), at[k]))
		mm.set_instance_color(k, col[k])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := _unshaded(Color.WHITE, true)
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _glow_tex()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	n.add_child(mi)
	return mi


# the mainland's towns along its shore: three clusters and a scatter, sodium and the odd white
func _shore_lights() -> void:
	var n := _layer(STRAIT_Z)
	var at: Array = []
	var col: Array = []
	for town in [[-6000.0, 900.0, 40], [-1400.0, 500.0, 26], [4200.0, 1300.0, 55], [9000.0, 600.0, 20]]:
		for k in int(town[2]):
			var x: float = float(town[0]) + _rng.randfn(0.0, float(town[1]) * 0.5)
			var y: float = 6.0 + absf(_rng.randfn(0.0, 40.0))
			at.append(Vector3(x, y, STRAIT_Z + _rng.randf_range(-200.0, 300.0)))
			col.append(Color(1.0, 0.72, 0.38) * _rng.randf_range(0.6, 1.2) if _rng.randf() < 0.8 else Color(0.85, 0.9, 1.0) * 0.8)
	for k in 30:
		at.append(Vector3(_rng.randf_range(-11000.0, 11000.0), _rng.randf_range(5.0, 300.0), STRAIT_Z + _rng.randf_range(0.0, 800.0)))
		col.append(Color(1.0, 0.75, 0.45) * _rng.randf_range(0.3, 0.7))
	_dots(n, at, 70.0, col)


# the light on the rock in the strait, four kilometres out
func _lighthouse() -> void:
	var d := 4200.0
	var n := _layer(d)
	var at := Vector3(900.0, 0.0, d)
	var tower := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.5
	cm.bottom_radius = 4.0
	cm.height = 24.0
	tower.mesh = cm
	tower.material_override = _unshaded(Color("1a1c20"))
	tower.position = at + Vector3(0, 12.0, 0)
	tower.extra_cull_margin = 16384.0
	n.add_child(tower)
	_flash = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(60.0, 60.0)
	_flash.mesh = q
	var fm := _unshaded(Color(1.0, 0.95, 0.8), true)
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.albedo_texture = _glow_tex()
	_flash.material_override = fm
	_flash.position = at + Vector3(0, 26.0, 0)
	_flash.extra_cull_margin = 16384.0
	n.add_child(_flash)
	# the beam: a long faint blade of light turning over the water
	_beam = Node3D.new()
	_beam.position = at + Vector3(0, 26.0, 0)
	n.add_child(_beam)
	for side: float in [1.0, -1.0]:
		var bm := MeshInstance3D.new()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var L := 2600.0 * side
		st.set_color(Color(1.0, 0.95, 0.8, 0.22))
		st.add_vertex(Vector3(0, 0, 0))
		st.set_color(Color(1.0, 0.95, 0.8, 0.0))
		st.add_vertex(Vector3(-160.0, -10.0, -L))
		st.add_vertex(Vector3(160.0, -10.0, -L))
		bm.mesh = st.commit()
		var m := _unshaded(Color.WHITE, true)
		m.vertex_color_use_as_albedo = true
		bm.material_override = m
		bm.extra_cull_margin = 16384.0
		_beam.add_child(bm)


# the ferry, three kilometres out, crossing: a dark hull, rows of lit windows, its mast lamps
func _ferry_build() -> void:
	var d := 3000.0
	var n := _layer(d)
	_ferry = Node3D.new()
	_ferry.position = Vector3(-1000.0, 0.0, d)
	n.add_child(_ferry)
	var hull := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(130.0, 14.0, 22.0)
	hull.mesh = bm
	hull.material_override = _unshaded(Color("101216"))
	hull.position = Vector3(0, 7.0, 0)
	hull.extra_cull_margin = 16384.0
	_ferry.add_child(hull)
	var at: Array = []
	var col: Array = []
	for row in 2:
		for k in 22:
			if _rng.randf() < 0.8:
				at.append(Vector3(-55.0 + k * 5.0, 9.0 + row * 5.0, -11.5))
				col.append(Color(1.0, 0.85, 0.6) * 0.9)
	at.append(Vector3(30.0, 34.0, 0.0))
	col.append(Color(1, 1, 1) * 1.4)
	at.append(Vector3(-40.0, 26.0, 0.0))
	col.append(Color(1, 1, 1) * 1.2)
	at.append(Vector3(0.0, 18.0, -12.0))
	col.append(Color(0.2, 1.0, 0.3) * 1.2)
	_dots(_ferry, at, 9.0, col)


# CKTD's mast on the hill behind the town, two and a half kilometres inland
func _mast() -> void:
	var d := -2500.0
	var n := _layer(d)
	var at := Vector3(-300.0, 260.0, d)
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 2.0
	cm.height = 150.0
	m.mesh = cm
	m.material_override = _unshaded(Color("0c0e10"))
	m.position = at + Vector3(0, 75.0, 0)
	m.extra_cull_margin = 16384.0
	n.add_child(m)
	for h in [50.0, 100.0, 150.0]:
		var dot := _dots(n, [at + Vector3(0, h, 0)], 26.0, [Color(1.0, 0.12, 0.08) * 1.6])
		_mast_lamps.append(dot)


static var _glow: ImageTexture

static func _glow_tex() -> ImageTexture:
	if _glow != null:
		return _glow
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x - s * 0.5 + 0.5, y - s * 0.5 + 0.5).length() / (s * 0.5)
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.5)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_glow = ImageTexture.create_from_image(img)
	return _glow
