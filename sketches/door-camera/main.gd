# The door post, through his eyes: a camera test for The Bouncer.
#
# Builds the pub, the vestibule and the lot out of grey shapes, sits the camera on his stool beside
# the main door, and renders stills and a head turn into renders/. Grey shapes on purpose: this is
# about where he sits and what he sees from there, not how the game will look.
#
#   godot --path . --rendering-driver opengl3 --resolution 1600x900      (needs a display; xvfb-run works)
#
# Units are metres. The pub runs x 0..16 along the front and z 0..10 from the back wall to the front
# wall (the main door and the front window); the gravel lot is out the front, z > 10.2. Looking out
# of the door, +x is on the left. The layout follows the floor sketch in the browser build
# (prototype/web/src/ui/views.js): the bar along the side wall, running from the back to near the
# main door, his stool just inside the door, table 28 in the front window, the pool table in the
# middle, the kitchen behind the bar, the washrooms off the back, the deck door on the far wall.
extends Node3D

const OUT := "res://renders/"
const EYE := Vector3(1.7, 1.62, 8.85)         # his eyes, sitting on the stool beside the door
const WORLD_W := 0.655                         # the share of the screen the world gets; the text column has the rest

const INK := Color("eae2d3")
const MUTED := Color("9c9285")
const FATHER := Color("dcab5e")
const WRONGMAN := Color("a5c2a6")
const RED := Color("ff5141")
const PAPER := Color("15110e")

const TABLES := [Vector3(4.3, 0, 4.45), Vector3(13.1, 0, 4.9), Vector3(5.4, 0, 8.3), Vector3(13.4, 0, 8.2)]
const T28 := Vector3(9.4, 0, 8.1)
const POOL := Vector3(9.4, 0, 3.9)
const DOOR_W := 2.3                            # the main door runs x 2.3..4.1
const DOOR_E := 4.1

var cam: Camera3D
var view: SubViewport
var env: Environment
var marks: Control
var story: VBoxContainer
var phone: Node3D
var kid_lot: Node3D
var kid_door: Node3D
var mark_on := false
var F := {}
var M := {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 28
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_fonts()
	_materials()
	_environment()
	_room()
	_vestibule()
	_bar()
	_floor_things()
	_outside()
	_truck()
	_rain()
	_people()
	_lights()
	_screen()
	await _shoot()
	get_tree().quit()


# ---------------------------------------------------------------- materials and shapes

func _mat(c: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _glow(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


func _glass(c: Color, a: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.06
	m.metallic = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _materials() -> void:
	M.wall = _mat(Color("cfcac1"))
	M.ceiling = _mat(Color("8e8a83"))
	M.carpet = _mat(Color("6e6963"))
	M.wood = _mat(Color("a59e93"), 0.7)
	M.top = _mat(Color("7f796f"), 0.45)
	M.dark = _mat(Color("4a4843"), 0.6)
	M.black = _mat(Color("1f1e22"), 0.5)
	M.frame = _mat(Color("3d3a36"), 0.45, 0.35)
	M.felt = _mat(Color("6f716c"))
	M.paper = _mat(Color("d9d4c8"))
	M.burn = _mat(Color("2c2825"))
	M.person = _mat(Color("b1aca3"))
	M.hoodie = _mat(Color("5c5953"))
	M.jeans = _mat(Color("4e5159"))
	M.skin = _mat(Color("c7c0b4"))
	M.gravel = _mat(Color("4a4946"), 0.34)
	M.puddle = _mat(Color("1b1c1f"), 0.04, 0.2)
	M.road = _mat(Color("333336"), 0.28)
	M.water = _mat(Color("111317"), 0.1, 0.2)
	M.truck = _mat(Color("5f5c57"), 0.35, 0.3)
	M.seat = _mat(Color("2e2d2f"), 0.8)
	M.bottle = _mat(Color("7a776f"), 0.2)
	M.mirror = _mat(Color("2e3033"), 0.04, 0.95)
	M.glass = _glass(Color("a9bccb"), 0.12)
	M.pint = _glass(Color("d8cfb5"), 0.5)
	M.drop = _glass(Color("eef2f6"), 0.5)
	M.tv = _glow(Color("b5c6de"), 1.1)
	M.juke = _glow(Color("e0708e"), 0.9)
	M.lamp = _glow(Color("ffdfae"), 3.0)
	M.bulb = _glow(Color("ffd9a0"), 4.0)
	M.neon = _glow(Color("ff3b2b"), 5.0)
	M.screen = _glow(Color("e6eefc"), 0.8)
	M.lotto = _glow(Color("c8e6a0"), 1.2)
	M.scanner = _glow(Color("9fe0b0"), 1.8)
	M.cooler = _glow(Color("dfe9f2"), 1.2)
	M.sodium = _glow(Color("ffb060"), 6.0)
	M.tail = _glow(Color("ff2a1a"), 3.0)
	M.head = _glow(Color("f4f6ff"), 9.0)
	M.dome = _glow(Color("ffe2b8"), 2.5)
	M.blue = _glow(Color("9fc4ff"), 3.0)
	M.far = _glow(Color("ffd49a"), 7.0)
	M.far.disable_fog = true


func _box(size: Vector3, pos: Vector3, m: Material, rot_y := 0.0, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	(parent if parent else self).add_child(mi)
	return mi


func _cyl(r_top: float, r_bot: float, h: float, pos: Vector3, m: Material, parent: Node = null, seg := 20) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	(parent if parent else self).add_child(mi)
	return mi


func _ball(r: float, pos: Vector3, m: Material, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 20
	sm.rings = 12
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	(parent if parent else self).add_child(mi)
	return mi


# A capsule from a to b: a leg, an arm, a body.
func _limb(a: Vector3, b: Vector3, r: float, m: Material, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	var d := b - a
	c.radius = r
	c.height = d.length() + r * 2.0
	c.radial_segments = 14
	c.rings = 4
	mi.mesh = c
	mi.material_override = m
	parent.add_child(mi)
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD) if absf(y.dot(Vector3.FORWARD)) < 0.98 else y.cross(Vector3.RIGHT)
	x = x.normalized()
	mi.basis = Basis(x, y, x.cross(y))
	mi.position = (a + b) / 2.0
	return mi


# A floor, ceiling or wall cut into tiles, so every lamp near a tile reaches it: the Compatibility
# renderer lights each mesh with its nearest few lights only.
func _tiled(size: Vector3, center: Vector3, m: Material, tile := 2.0) -> void:
	var nx := maxi(1, ceili(size.x / tile))
	var ny := maxi(1, ceili(size.y / tile))
	var nz := maxi(1, ceili(size.z / tile))
	var s := Vector3(size.x / nx, size.y / ny, size.z / nz)
	for i in nx:
		for j in ny:
			for k in nz:
				_box(s, center - size / 2.0 + Vector3(s.x * (i + 0.5), s.y * (j + 0.5), s.z * (k + 0.5)), m)


func _omni(pos: Vector3, c: Color, e: float, r: float, shadow := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = c
	l.light_energy = e
	l.omni_range = r
	l.shadow_enabled = shadow
	add_child(l)
	return l


func _spot(pos: Vector3, target: Vector3, c: Color, e: float, r: float, angle: float, shadow := false, parent: Node = null) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.spot_range = r
	l.spot_angle = angle
	l.spot_angle_attenuation = 1.6
	l.shadow_enabled = shadow
	(parent if parent else self).add_child(l)
	l.global_position = pos
	var d := (target - pos).normalized()
	l.look_at(target, Vector3.UP if absf(d.y) < 0.98 else Vector3.FORWARD)
	return l


# ---------------------------------------------------------------- the pub

func _environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0a0b0f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("3b4250")
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color("16181e")
	env.fog_density = 0.01
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _room() -> void:
	_tiled(Vector3(16, 0.1, 10), Vector3(8, -0.05, 5), M.carpet)
	_tiled(Vector3(16, 0.1, 10), Vector3(8, 3.25, 5), M.ceiling)
	for z in [2.9, 5.6, 8.3]:                                            # the old dining room's beams
		_tiled(Vector3(16, 0.28, 0.24), Vector3(8, 3.06, z), M.wood, 4.0)
	# the west wall, behind the bar
	_tiled(Vector3(0.2, 3.2, 10), Vector3(-0.1, 1.6, 5), M.wall)
	# the back wall: the kitchen's swing door behind the bar, and the way through to the washrooms
	_box(Vector3(2.8, 3.2, 0.2), Vector3(1.4, 1.6, -0.1), M.wall)
	_box(Vector3(0.9, 1.1, 0.2), Vector3(3.25, 2.65, -0.1), M.wall)
	_box(Vector3(0.9, 2.1, 0.05), Vector3(3.25, 1.05, -0.03), M.dark)
	var porthole := _cyl(0.14, 0.14, 0.01, Vector3(3.25, 1.55, 0.0), M.lamp, null, 20)
	porthole.rotation.x = deg_to_rad(90)
	_tiled(Vector3(2.2, 3.2, 0.2), Vector3(4.8, 1.6, -0.1), M.wall)
	_box(Vector3(1.2, 0.9, 0.2), Vector3(6.5, 2.75, -0.1), M.wall)
	_tiled(Vector3(8.9, 3.2, 0.2), Vector3(11.55, 1.6, -0.1), M.wall)
	_box(Vector3(1.2, 2.3, 0.1), Vector3(6.5, 1.15, -2.6), M.dark)          # the back hall, dim
	_tiled(Vector3(0.1, 2.3, 2.5), Vector3(5.9, 1.15, -1.35), M.wall)
	_tiled(Vector3(0.1, 2.3, 2.5), Vector3(7.1, 1.15, -1.35), M.wall)
	_ball(0.05, Vector3(6.5, 2.2, -2.2), M.bulb)
	# the east wall, with the deck door
	_tiled(Vector3(0.2, 3.2, 6.5), Vector3(16.1, 1.6, 3.25), M.wall)
	_box(Vector3(0.2, 0.9, 1.2), Vector3(16.1, 2.75, 7.1), M.wall)
	_tiled(Vector3(0.2, 3.2, 2.3), Vector3(16.1, 1.6, 8.85), M.wall)
	_box(Vector3(0.08, 2.3, 1.2), Vector3(16.04, 1.15, 7.1), M.dark)
	_box(Vector3(0.09, 0.8, 0.6), Vector3(16.0, 1.5, 7.1), M.glass)
	# the front wall: the main door at x 2.3..4.1, the front window at x 6.2..12.6
	var zf := 10.1
	_tiled(Vector3(2.3, 3.2, 0.2), Vector3(1.15, 1.6, zf), M.wall)
	_box(Vector3(1.8, 0.9, 0.2), Vector3(3.2, 2.75, zf), M.wall)
	_tiled(Vector3(2.1, 3.2, 0.2), Vector3(5.15, 1.6, zf), M.wall)
	_tiled(Vector3(6.4, 0.9, 0.2), Vector3(9.4, 0.45, zf), M.wall)
	_tiled(Vector3(6.4, 0.8, 0.2), Vector3(9.4, 2.8, zf), M.wall)
	_tiled(Vector3(3.4, 3.2, 0.2), Vector3(14.3, 1.6, zf), M.wall)
	_box(Vector3(6.4, 1.5, 0.03), Vector3(9.4, 1.65, zf), M.glass)
	for x in [6.2, 7.8, 9.4, 11.0, 12.6]:
		_box(Vector3(0.07, 1.5, 0.14), Vector3(x, 1.65, zf), M.frame)
	_box(Vector3(6.5, 0.07, 0.3), Vector3(9.4, 0.93, zf - 0.05), M.wood)      # the sill


func _vestibule() -> void:
	var zf := 10.1
	# the door frame and its two glass leaves; they open out to the lot
	_box(Vector3(0.09, 2.34, 0.16), Vector3(DOOR_W, 1.17, zf), M.frame)
	_box(Vector3(0.09, 2.34, 0.16), Vector3(DOOR_E, 1.17, zf), M.frame)
	_box(Vector3(1.9, 0.09, 0.16), Vector3((DOOR_W + DOOR_E) / 2.0, 2.33, zf), M.frame)
	_leaf(DOOR_W + 0.04, 1.0)
	_leaf(DOOR_E - 0.04, -1.0)
	# the screen between the vestibule and the room: panelled to the waist, glass above
	_box(Vector3(0.1, 1.05, 1.2), Vector3(4.55, 0.525, 9.5), M.wood)
	_box(Vector3(0.14, 0.06, 1.24), Vector3(4.55, 1.08, 9.5), M.frame)
	_box(Vector3(0.14, 0.08, 1.24), Vector3(4.55, 2.24, 9.5), M.frame)
	_box(Vector3(0.12, 2.28, 0.08), Vector3(4.55, 1.14, 8.92), M.frame)
	_box(Vector3(0.02, 1.1, 1.1), Vector3(4.55, 1.66, 9.5), M.glass)
	# the ledge along the front wall, by his right hand: the scanner, the clicker, the incident
	# book, and the old cigarette burns
	_box(Vector3(1.85, 1.0, 0.45), Vector3(1.275, 0.5, 9.78), M.wood)
	_box(Vector3(1.95, 0.05, 0.55), Vector3(1.275, 1.025, 9.75), M.top)
	for i in 11:
		var b := _cyl(0.012, 0.012, 0.002, Vector3(rng.randf_range(0.4, 2.15), 1.051, rng.randf_range(9.55, 9.96)), M.burn, null, 8)
		b.scale = Vector3(rng.randf_range(1.0, 2.6), 1, 1)
	_box(Vector3(0.2, 0.07, 0.13), Vector3(1.92, 1.085, 9.72), M.dark)
	_box(Vector3(0.12, 0.004, 0.07), Vector3(1.92, 1.122, 9.69), M.scanner)
	_cyl(0.028, 0.028, 0.035, Vector3(1.55, 1.07, 9.74), M.frame, null, 14)
	_box(Vector3(0.3, 0.02, 0.23), Vector3(1.05, 1.06, 9.73), M.paper, 8.0)
	# his stool, and the mat inside the door
	_stool(Vector3(EYE.x, 0, EYE.z), 0.78)
	_box(Vector3(1.8, 0.012, 1.0), Vector3((DOOR_W + DOOR_E) / 2.0, 0.006, 9.45), M.dark)


func _leaf(hinge_x: float, dir: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(hinge_x, 0, 10.12)
	add_child(pivot)
	var w := 0.86
	_box(Vector3(w, 0.14, 0.05), Vector3(dir * w / 2.0, 0.07, 0), M.frame, 0.0, pivot)
	_box(Vector3(w, 0.1, 0.05), Vector3(dir * w / 2.0, 2.22, 0), M.frame, 0.0, pivot)
	_box(Vector3(0.07, 2.25, 0.05), Vector3(dir * 0.035, 1.13, 0), M.frame, 0.0, pivot)
	_box(Vector3(0.07, 2.25, 0.05), Vector3(dir * (w - 0.035), 1.13, 0), M.frame, 0.0, pivot)
	_box(Vector3(w - 0.14, 0.04, 0.05), Vector3(dir * w / 2.0, 1.02, -0.05), M.frame, 0.0, pivot)   # the push bar
	_box(Vector3(w - 0.1, 2.0, 0.015), Vector3(dir * w / 2.0, 1.17, 0), M.glass, 0.0, pivot)
	# rain on the outside of the glass
	for i in 34:
		_box(Vector3(0.005, rng.randf_range(0.012, 0.07), 0.003), Vector3(dir * rng.randf_range(0.08, w - 0.08), rng.randf_range(0.25, 2.1), 0.013), M.drop, 0.0, pivot)
	return pivot


func _bar() -> void:
	# the bar runs along the west wall, from near the back to near the door
	_tiled(Vector3(0.6, 1.06, 6.7), Vector3(1.9, 0.53, 4.35), M.wood)
	_tiled(Vector3(0.8, 0.06, 6.8), Vector3(1.95, 1.09, 4.35), M.top)
	_box(Vector3(0.05, 0.05, 6.7), Vector3(2.34, 0.22, 4.35), M.frame)        # the brass rail
	for i in 6:
		_box(Vector3(0.04, 0.28, 0.04), Vector3(1.72, 1.26, 3.4 + i * 0.26), M.frame)
	_box(Vector3(0.36, 0.26, 0.32), Vector3(1.75, 1.25, 7.3), M.dark)          # the till, at the door end
	# the lottery screen on the bar, that table 28 plays all afternoon
	var lot := _box(Vector3(0.5, 0.34, 0.05), Vector3(2.0, 1.36, 6.7), M.dark, 90.0)
	_box(Vector3(0.44, 0.28, 0.01), Vector3(0, 0, 0.03), M.lotto, 0.0, lot)
	# behind it: the back counter with the bottles and the mirror, a cooler, and the trapdoor to the
	# keg room at the far end
	_tiled(Vector3(0.5, 0.95, 6.2), Vector3(0.25, 0.475, 4.3), M.wood)
	_box(Vector3(0.04, 1.35, 4.4), Vector3(0.03, 1.82, 4.4), M.mirror)
	for y in [1.28, 1.66, 2.04]:
		_box(Vector3(0.3, 0.03, 4.4), Vector3(0.17, y, 4.4), M.wood)
		var z := 2.3
		while z < 6.5:
			var h := rng.randf_range(0.24, 0.33)
			_cyl(0.026, 0.034, h, Vector3(rng.randf_range(0.12, 0.2), y + 0.015 + h / 2.0, z), M.bottle, null, 10)
			z += rng.randf_range(0.075, 0.12)
	_box(Vector3(0.4, 0.05, 4.6), Vector3(0.4, 2.75, 4.4), M.dark)
	_box(Vector3(0.3, 0.01, 4.4), Vector3(0.4, 2.72, 4.4), M.lamp)
	_box(Vector3(0.62, 2.1, 1.0), Vector3(0.31, 1.05, 0.7), M.dark)
	_box(Vector3(0.02, 1.84, 0.86), Vector3(0.63, 1.1, 0.7), M.cooler)
	for sy in [0.55, 0.95, 1.35, 1.75]:
		_box(Vector3(0.02, 0.02, 0.86), Vector3(0.645, sy, 0.7), M.frame)
	_box(Vector3(0.9, 0.012, 1.0), Vector3(1.05, 0.006, 1.9), M.dark)
	var z2 := 1.6
	while z2 < 7.4:
		_stool(Vector3(2.65, 0, z2), 0.76)
		z2 += 0.85


func _stool(at: Vector3, seat := 0.64) -> void:
	_cyl(0.18, 0.18, 0.06, at + Vector3(0, seat, 0), M.dark, null, 18)
	_cyl(0.025, 0.025, seat, at + Vector3(0, seat / 2.0, 0), M.frame, null, 10)
	_cyl(0.2, 0.2, 0.02, at + Vector3(0, 0.01, 0), M.frame, null, 18)


func _table(at: Vector3, round := false, size := 0.8) -> void:
	if round:
		_cyl(size, size, 0.05, at + Vector3(0, 0.76, 0), M.top, null, 36)
		_cyl(0.07, 0.09, 0.74, at + Vector3(0, 0.37, 0), M.frame)
		_cyl(0.38, 0.38, 0.03, at + Vector3(0, 0.015, 0), M.frame)
	else:
		_box(Vector3(size, 0.05, size), at + Vector3(0, 0.76, 0), M.top)
		_box(Vector3(0.1, 0.74, 0.1), at + Vector3(0, 0.37, 0), M.frame)
		_box(Vector3(0.55, 0.03, 0.55), at + Vector3(0, 0.015, 0), M.frame)


func _pint(at: Vector3) -> void:
	_cyl(0.042, 0.034, 0.15, at + Vector3(0, 0.075, 0), M.pint, null, 12)


func _pendant(p: Vector3, drop := 2.35) -> void:
	_cyl(0.005, 0.005, 3.2 - drop - 0.1, Vector3(p.x, (3.2 + drop + 0.1) / 2.0, p.z), M.frame, null, 6)
	_cyl(0.07, 0.24, 0.2, Vector3(p.x, drop, p.z), M.dark, null, 18)
	_ball(0.06, Vector3(p.x, drop - 0.1, p.z), M.bulb)


func _floor_things() -> void:
	# the pool table, with its lamp
	_box(Vector3(2.7, 0.14, 1.55), POOL + Vector3(0, 0.76, 0), M.wood)
	_box(Vector3(2.5, 0.02, 1.35), POOL + Vector3(0, 0.84, 0), M.felt)
	for p in [Vector2(-1.15, -0.6), Vector2(1.15, -0.6), Vector2(-1.15, 0.6), Vector2(1.15, 0.6)]:
		_box(Vector3(0.15, 0.7, 0.15), POOL + Vector3(p.x, 0.35, p.y), M.wood)
	for b in [Vector2(-0.6, -0.3), Vector2(-0.45, 0.05), Vector2(0.6, -0.4), Vector2(0.2, 0.3), Vector2(-0.9, 0.15)]:
		_ball(0.028, POOL + Vector3(b.x, 0.88, b.y), M.person)
	_box(Vector3(1.8, 0.16, 0.44), POOL + Vector3(0, 1.98, 0), M.dark)
	_box(Vector3(1.7, 0.01, 0.36), POOL + Vector3(0, 1.895, 0), M.lamp)
	_box(Vector3(0.015, 1.2, 0.015), POOL + Vector3(-0.7, 2.65, 0), M.frame)
	_box(Vector3(0.015, 1.2, 0.015), POOL + Vector3(0.7, 2.65, 0), M.frame)
	# table 28, the big round one in the front window, with its glasses and six stools
	_table(T28, true, 0.85)
	for i in 11:
		var a := TAU * i / 11.0 + rng.randf() * 0.3
		_pint(T28 + Vector3(cos(a) * rng.randf_range(0.25, 0.62), 0.785, sin(a) * rng.randf_range(0.25, 0.62)))
	for k in 6:
		var a2 := TAU * k / 6.0 + 0.25
		_stool(T28 + Vector3(cos(a2) * 1.18, 0, sin(a2) * 1.18))
	_pendant(T28)
	# the other tables
	for t in TABLES:
		_table(t)
		for s in [Vector3(0.62, 0, 0), Vector3(-0.62, 0, 0), Vector3(0, 0, 0.62)]:
			_stool(t + s)
		_pendant(t)
	for z in [2.4, 4.4, 6.4]:
		_pendant(Vector3(1.95, 0, z), 2.3)
	# the jukebox against the back wall
	_box(Vector3(0.7, 1.55, 0.62), Vector3(13.2, 0.78, 0.35), M.dark)
	_box(Vector3(0.5, 0.9, 0.02), Vector3(13.2, 1.0, 0.67), M.juke)
	# a TV on the back wall that table 28 watches, and one on the east wall
	_box(Vector3(1.25, 0.74, 0.08), Vector3(9.4, 2.45, 0.08), M.black)
	_box(Vector3(1.15, 0.64, 0.01), Vector3(9.4, 2.45, 0.125), M.tv)
	_box(Vector3(0.08, 0.74, 1.25), Vector3(15.95, 2.35, 4.0), M.black)
	_box(Vector3(0.01, 0.64, 1.15), Vector3(15.905, 2.35, 4.0), M.tv)
	# the dartboard on the east wall
	var dart := _cyl(0.23, 0.23, 0.04, Vector3(15.97, 1.73, 2.3), M.dark, null, 24)
	dart.rotation.z = deg_to_rad(90)


# ---------------------------------------------------------------- outside

func _outside() -> void:
	# the gravel lot, wet, with puddles; the highway; the water past it
	_tiled(Vector3(40, 0.1, 18), Vector3(8, -0.05, 19.2), M.gravel, 3.0)
	for p in [Vector3(4.2, 0, 11.7), Vector3(6.8, 0, 12.5), Vector3(5.6, 0, 14.8), Vector3(10.6, 0, 13.3), Vector3(12.5, 0, 17.9), Vector3(3.0, 0, 16.4)]:
		var pd := _box(Vector3(rng.randf_range(0.8, 1.9), 0.01, rng.randf_range(0.5, 1.1)), p + Vector3(0, 0.003, 0), M.puddle, rng.randf_range(-30.0, 30.0))
		pd.scale = Vector3.ONE
	_box(Vector3(160, 0.1, 6), Vector3(8, -0.06, 30.6), M.gravel)
	_box(Vector3(160, 0.02, 8), Vector3(8, 0.0, 31.6), M.road)
	for x in range(-60, 80, 6):
		_box(Vector3(2.5, 0.01, 0.12), Vector3(x, 0.02, 31.6), M.wall)
	_box(Vector3(160, 0.9, 0.5), Vector3(8, 0.2, 35.9), M.dark)                 # the seawall
	_box(Vector3(900, 0.02, 900), Vector3(8, -0.4, 486), M.water)
	# lights across the water
	for i in 16:
		_ball(rng.randf_range(0.5, 1.1), Vector3(rng.randf_range(-260, 420), rng.randf_range(0.5, 6.0), 420 + rng.randf_range(0, 40)), M.far)
	# outside the door: the step, and the sign over it
	_box(Vector3(2.6, 0.12, 1.2), Vector3(3.2, 0.06, 10.8), M.dark)
	_box(Vector3(4.6, 1.0, 0.12), Vector3(4.3, 3.85, 10.3), M.black)
	_box(Vector3(4.3, 0.07, 0.04), Vector3(4.3, 3.62, 10.37), M.neon)
	_box(Vector3(4.3, 0.07, 0.04), Vector3(4.3, 4.08, 10.37), M.neon)
	# the lamp on a pole at the edge of the lot
	_cyl(0.07, 0.09, 6.5, Vector3(15.8, 3.25, 21.5), M.frame, null, 10)
	_box(Vector3(0.9, 0.12, 0.35), Vector3(15.4, 6.5, 21.5), M.frame)
	_box(Vector3(0.7, 0.02, 0.25), Vector3(15.4, 6.43, 21.5), M.sodium)
	# a car going by on the highway, and one going the other way
	_ball(0.09, Vector3(19.0, 0.7, 30.3), M.head)
	_ball(0.09, Vector3(19.0, 0.7, 31.1), M.head)
	_ball(0.07, Vector3(-9.0, 0.75, 32.2), M.tail)
	_ball(0.07, Vector3(-9.0, 0.75, 33.0), M.tail)


# The pickup the kid got out of: nose in, facing the door, the engine running and the lights on.
# The passenger door is open, so the dome light is on: his sister at the wheel with her phone,
# someone lying across the back seat.
func _truck() -> void:
	var t := Node3D.new()
	t.position = Vector3(9.2, 0, 15.8)
	add_child(t)
	t.look_at(Vector3(3.2, 0, 10.1), Vector3.UP)
	_box(Vector3(1.96, 0.72, 5.5), Vector3(0, 0.8, 0), M.truck, 0.0, t)
	_box(Vector3(1.9, 0.1, 1.3), Vector3(0, 1.2, -2.1), M.truck, 0.0, t)
	_box(Vector3(1.3, 0.34, 0.04), Vector3(0, 0.95, -2.76), M.black, 0.0, t)       # the grille
	# the crew cab: roof, back, pillars and glass
	var cz := -0.3
	var cl := 2.3
	_box(Vector3(1.86, 0.07, cl), Vector3(0, 2.0, cz), M.truck, 0.0, t)
	_box(Vector3(1.86, 0.84, 0.07), Vector3(0, 1.58, cz + cl / 2.0), M.truck, 0.0, t)
	for sx in [-0.9, 0.9]:
		for pz in [cz - cl / 2.0, cz, cz + cl / 2.0 - 0.04]:
			_box(Vector3(0.07, 0.84, 0.08), Vector3(sx, 1.58, pz), M.truck, 0.0, t)
		_box(Vector3(0.14, 0.12, 0.2), Vector3(sx * 1.2, 1.45, cz - cl / 2.0 - 0.05), M.black, 0.0, t)   # mirrors
	_box(Vector3(1.76, 0.7, 0.02), Vector3(0, 1.58, cz - cl / 2.0), M.glass, 0.0, t)
	_box(Vector3(0.02, 0.7, cl - 0.1), Vector3(-0.92, 1.6, cz), M.glass, 0.0, t)
	_box(Vector3(0.02, 0.7, cl / 2.0 - 0.1), Vector3(0.92, 1.6, cz + cl / 4.0), M.glass, 0.0, t)
	# the passenger door, open
	var hinge := Node3D.new()
	hinge.position = Vector3(0.95, 0, cz - cl / 2.0)
	hinge.rotation.y = deg_to_rad(52)
	t.add_child(hinge)
	_box(Vector3(0.07, 0.74, cl / 2.0), Vector3(0, 0.8, cl / 4.0), M.truck, 0.0, hinge)
	_box(Vector3(0.02, 0.66, cl / 2.0 - 0.1), Vector3(0, 1.58, cl / 4.0), M.glass, 0.0, hinge)
	# inside: the seats, the sister at the wheel lit by her phone, somebody across the back seat
	for sx in [-0.45, 0.45]:
		_box(Vector3(0.52, 0.64, 0.12), Vector3(sx, 1.42, -0.45), M.seat, -8.0 if sx < 0 else 8.0, t)
	_box(Vector3(1.7, 0.6, 0.12), Vector3(0, 1.4, 0.72), M.seat, 0.0, t)
	var d := Node3D.new()
	t.add_child(d)
	_limb(Vector3(-0.45, 1.1, -0.62), Vector3(-0.45, 1.55, -0.66), 0.16, M.person, d)
	_ball(0.1, Vector3(-0.45, 1.74, -0.7), M.skin, d)
	_box(Vector3(0.07, 0.13, 0.01), Vector3(-0.4, 1.46, -0.95), M.blue, 20.0, t)
	_limb(Vector3(-0.7, 1.2, 0.45), Vector3(0.55, 1.26, 0.45), 0.16, M.person, t)
	_box(Vector3(0.3, 0.02, 0.2), Vector3(0, 1.96, -0.3), M.dome, 0.0, t)
	var dome := OmniLight3D.new()
	dome.position = Vector3(0, 1.88, -0.3)
	dome.light_color = Color("ffe0b0")
	dome.light_energy = 0.7
	dome.omni_range = 2.0
	t.add_child(dome)
	var glow := OmniLight3D.new()
	glow.position = Vector3(-0.42, 1.55, -0.95)
	glow.light_color = Color("8fb8ff")
	glow.light_energy = 0.5
	glow.omni_range = 0.8
	t.add_child(glow)
	# wheels, lamps
	for w in [Vector3(-0.95, 0.4, -1.75), Vector3(0.95, 0.4, -1.75), Vector3(-0.95, 0.4, 1.75), Vector3(0.95, 0.4, 1.75)]:
		var wh := _cyl(0.4, 0.4, 0.3, w, M.black, t, 18)
		wh.rotation.z = deg_to_rad(90)
	for sx in [-0.72, 0.72]:
		_box(Vector3(0.34, 0.14, 0.03), Vector3(sx, 1.0, -2.76), M.head, 0.0, t)
		_box(Vector3(0.12, 0.26, 0.03), Vector3(sx * 1.2, 0.98, 2.76), M.tail, 0.0, t)
		var beam := _spot(Vector3.ZERO, Vector3.ZERO + Vector3(0, -0.5, -10), Color("eef2ff"), 4.5, 22.0, 22.0, true, t)
		beam.position = Vector3(sx, 1.0, -2.82)
		beam.look_at(t.to_global(Vector3(sx * 1.4, 0.2, -12.0)), Vector3.UP)


func _rain() -> void:
	var rain := CPUParticles3D.new()
	rain.amount = 3000
	rain.lifetime = 1.1
	rain.preprocess = 3.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(10.0, 0.3, 6.2)
	rain.position = Vector3(6.5, 7.5, 16.5)
	rain.direction = Vector3(0.06, -1.0, 0.0)
	rain.spread = 1.5
	rain.gravity = Vector3(0, -6.0, 0)
	rain.initial_velocity_min = 7.0
	rain.initial_velocity_max = 8.5
	var q := QuadMesh.new()
	q.size = Vector2(0.007, 0.34)
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.9, 0.9, 0.95, 0.5)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	rm.billboard_keep_scale = true
	rm.roughness = 0.2
	q.material = rm
	rain.mesh = q
	add_child(rain)


# ---------------------------------------------------------------- people, as plain grey figures

func _person_root(at: Vector3, face_to: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = at
	add_child(n)
	n.look_at(Vector3(face_to.x, at.y, face_to.z), Vector3.UP)
	return n


func _standing(at: Vector3, face_to: Vector3, h := 1.78, bulk := 1.0) -> Node3D:
	var n := _person_root(at, face_to)
	var m: Material = M.person
	var hip := h * 0.53
	var sh := h * 0.815
	for s in [-1.0, 1.0]:
		_limb(Vector3(0.1 * bulk * s, hip, 0), Vector3(0.11 * bulk * s, 0.07, 0.01), 0.075 * bulk, m, n)
		_limb(Vector3(0.21 * bulk * s, sh, 0), Vector3(0.25 * bulk * s, h * 0.48, 0.03), 0.052 * bulk, m, n)
	_limb(Vector3(0, hip + 0.05, 0), Vector3(0, sh - 0.02, 0), 0.17 * bulk, m, n)
	_limb(Vector3(-0.19 * bulk, sh, 0), Vector3(0.19 * bulk, sh, 0), 0.07 * bulk, m, n)
	_ball(0.105, Vector3(0, h - 0.115, 0), m, n)
	return n


# Sitting on a stool at `at`, facing `face_to`, forearms on a table or the bar at height `rest`.
func _seated(at: Vector3, face_to: Vector3, seat := 0.64, rest := 0.8, bulk := 1.0) -> Node3D:
	var n := _person_root(at, face_to)
	var m: Material = M.person
	var hip := seat + 0.1
	var sh := seat + 0.6
	var foot := 0.07 if seat < 0.7 else seat - 0.42
	for s in [-1.0, 1.0]:
		var knee := Vector3(0.12 * bulk * s, hip + 0.02, -0.42)
		_limb(Vector3(0.1 * bulk * s, hip, 0.02), knee, 0.08 * bulk, m, n)
		_limb(knee, Vector3(0.12 * bulk * s, foot, -0.46), 0.065 * bulk, m, n)
		var elbow := Vector3(0.25 * bulk * s, rest + 0.02, -0.22)
		_limb(Vector3(0.21 * bulk * s, sh, -0.02), elbow, 0.052 * bulk, m, n)
		_limb(elbow, Vector3(0.1 * s, rest + 0.04, -0.46), 0.048 * bulk, m, n)
	_limb(Vector3(0, hip + 0.04, 0.02), Vector3(0, sh - 0.02, -0.04), 0.17 * bulk, m, n)
	_limb(Vector3(-0.19 * bulk, sh, -0.03), Vector3(0.19 * bulk, sh, -0.03), 0.07 * bulk, m, n)
	_ball(0.105, Vector3(0, sh + 0.2, -0.07), m, n)
	return n


func _people() -> void:
	# table 28: five of them round the big table, one stool empty
	for k in 6:
		if k == 4:
			continue
		var a := TAU * k / 6.0 + 0.25
		_seated(T28 + Vector3(cos(a) * 1.18, 0, sin(a) * 1.18), T28, 0.64, 0.8, 1.06 if k % 2 == 0 else 1.0)
	# the big man at the pool table with his cue, and the one he's playing
	var big := _standing(POOL + Vector3(1.8, 0, 1.0), POOL, 1.96, 1.36)
	_limb(Vector3(0.36, 0.02, -0.16), Vector3(0.34, 1.46, -0.12), 0.012, M.wood, big)
	_standing(POOL + Vector3(-1.9, 0, 1.2), POOL, 1.74, 0.95)
	# the bartender behind the bar, one on a stool at it, a couple at a table, one at the jukebox
	_standing(Vector3(1.0, 0, 4.8), Vector3(6.0, 0, 4.8), 1.66, 0.95)
	_seated(Vector3(2.65, 0, 3.3), Vector3(0.0, 0, 3.3), 0.76, 1.12, 1.1)
	_seated(TABLES[1] + Vector3(-0.62, 0, 0), TABLES[1])
	_seated(TABLES[1] + Vector3(0, 0, 0.62), TABLES[1], 0.64, 0.8, 0.9)
	_standing(Vector3(13.2, 0, 1.2), Vector3(13.2, 0, 0.0), 1.7, 1.0)
	# the kid: first coming across the gravel from the pickup, hood up, hands in his pouch
	kid_lot = _kid(Vector3(5.3, 0, 13.4), Vector3(3.2, 0, 10.1), false)
	# then in front of the stool, holding his phone up
	kid_door = _kid(Vector3(2.62, 0, 9.62), EYE, true)
	kid_door.visible = false


func _kid(at: Vector3, face_to: Vector3, phone_up: bool) -> Node3D:
	var n := _person_root(at, face_to)
	var hood: Material = M.hoodie
	# jeans and shoes
	for s in [-1.0, 1.0]:
		_limb(Vector3(0.09 * s, 0.93, 0), Vector3(0.1 * s, 0.08, 0.0), 0.07, M.jeans, n)
		_box(Vector3(0.11, 0.08, 0.28), Vector3(0.1 * s, 0.04, -0.05), M.dark, 0.0, n)
	# the sweatshirt, loose, with the hood up and his face set back in it
	_limb(Vector3(0, 0.98, 0.0), Vector3(0, 1.4, 0.01), 0.185, hood, n)
	_limb(Vector3(-0.17, 1.44, 0.01), Vector3(0.17, 1.44, 0.01), 0.075, hood, n)
	_ball(0.135, Vector3(0, 1.65, 0.02), hood, n)
	_ball(0.093, Vector3(0, 1.63, -0.035), M.skin, n)
	if phone_up:
		# his right arm up, holding the phone out to the stool; the left hand in the pouch
		var elbow := Vector3(0.25, 1.24, -0.2)
		var hand := Vector3(0.12, 1.46, -0.44)
		_limb(Vector3(0.2, 1.44, 0.0), elbow, 0.058, hood, n)
		_limb(elbow, hand, 0.052, hood, n)
		_limb(Vector3(-0.2, 1.44, 0.0), Vector3(-0.25, 1.16, -0.06), 0.058, hood, n)
		_limb(Vector3(-0.25, 1.16, -0.06), Vector3(-0.08, 1.05, -0.2), 0.052, hood, n)
		_box(Vector3(0.26, 0.12, 0.07), Vector3(0, 1.04, -0.17), hood, 0.0, n)
		phone = Node3D.new()
		phone.position = hand + Vector3(0, 0.08, -0.03)
		n.add_child(phone)
		_box(Vector3(0.075, 0.155, 0.01), Vector3.ZERO, M.black, 0.0, phone)
		_box(Vector3(0.066, 0.138, 0.002), Vector3(0, 0, -0.006), M.screen, 0.0, phone)
	else:
		for s in [-1.0, 1.0]:
			var elbow2 := Vector3(0.25 * s, 1.17, -0.03)
			_limb(Vector3(0.2 * s, 1.44, 0.0), elbow2, 0.058, hood, n)
			_limb(elbow2, Vector3(0.07 * s, 1.03, -0.2), 0.052, hood, n)
		_box(Vector3(0.26, 0.12, 0.07), Vector3(0, 1.04, -0.17), hood, 0.0, n)
	return n


# ---------------------------------------------------------------- light

func _lights() -> void:
	# the vestibule: the lamp over the door and his stool
	_omni(Vector3(2.25, 2.95, 9.2), Color("ffd7a8"), 1.4, 4.6, true)
	_cyl(0.16, 0.16, 0.05, Vector3(2.25, 3.17, 9.2), M.lamp)
	# the sign's red over the step and the lot
	_omni(Vector3(4.1, 3.4, 11.1), Color("ff3a28"), 1.0, 7.0, true)
	# the lamp at the edge of the lot
	var s := _omni(Vector3(15.4, 6.2, 21.5), Color("ffa04a"), 5.0, 16.0, true)
	s.omni_attenuation = 1.4
	# the pool table's lamp
	_spot(POOL + Vector3(0, 1.86, 0), POOL, Color("fff0d6"), 7.0, 3.2, 58.0, true)
	# the pendants: over the tables (table 28's throws shadows) and three over the bar
	_spot(T28 + Vector3(0, 2.2, 0), T28, Color("ffc88a"), 3.2, 3.6, 55.0, true)
	for t in TABLES:
		_spot(t + Vector3(0, 2.2, 0), t, Color("ffc88a"), 3.0, 3.6, 55.0)
	for z in [2.4, 4.4, 6.4]:
		_spot(Vector3(1.95, 2.15, z), Vector3(1.95, 0, z), Color("ffc88a"), 2.6, 3.4, 52.0)
	# the back bar, the cooler, the TVs and the jukebox
	_omni(Vector3(0.7, 2.5, 4.4), Color("ffcf93"), 1.2, 4.5)
	_omni(Vector3(1.1, 1.2, 0.7), Color("dfe9f2"), 0.5, 2.6)
	_omni(Vector3(9.4, 2.3, 0.7), Color("a9c0e8"), 0.55, 4.5)
	_omni(Vector3(15.2, 2.3, 4.0), Color("a9c0e8"), 0.45, 4.0)
	_omni(Vector3(13.2, 1.0, 1.1), Color("f07aa0"), 0.8, 3.0)


# ---------------------------------------------------------------- the screen: the world, the column, the marks

func _fonts() -> void:
	for pair in [["read", "newsreader-400.woff2"], ["father", "zilla-slab-400.woff2"], ["father_b", "zilla-slab-600.woff2"],
			["wrong", "cormorant-garamond-400-italic.woff2"], ["ui_b", "barlow-condensed-600.woff2"]]:
		var f := FontFile.new()
		var err := f.load_dynamic_font("res://fonts/" + pair[1])
		if err != OK:
			push_warning("font " + pair[1] + ": " + str(err))
		F[pair[0]] = f


func _screen() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# the world, in the left part of the screen, seen by his eyes
	var box := SubViewportContainer.new()
	box.stretch = true
	box.anchor_right = WORLD_W
	box.anchor_bottom = 1.0
	layer.add_child(box)
	view = SubViewport.new()
	view.msaa_3d = Viewport.MSAA_4X
	view.positional_shadow_atlas_size = 4096
	box.add_child(view)
	cam = Camera3D.new()
	cam.fov = 58.0
	cam.near = 0.05
	cam.far = 900.0
	cam.environment = env
	view.add_child(cam)
	# the voices' marks, drawn over the world where the thing they mark is
	marks = Control.new()
	marks.anchor_right = WORLD_W
	marks.anchor_bottom = 1.0
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(marks)
	marks.draw.connect(_draw_marks)
	# the text column: the newest lines at the bottom, the older ones going up and away
	var panel := Panel.new()
	panel.anchor_left = WORLD_W
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_width_left = 1
	sb.border_color = Color("3b322b")
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	var head := Label.new()
	head.text = "WEDNESDAY  ·  7:50 PM  ·  ON THE DOOR"
	head.add_theme_font_override("font", F.ui_b)
	head.add_theme_font_size_override("font_size", 17)
	head.add_theme_color_override("font_color", MUTED)
	head.position = Vector2(44, 40)
	panel.add_child(head)
	var clip := Control.new()
	clip.clip_contents = true
	clip.anchor_right = 1.0
	clip.anchor_bottom = 1.0
	clip.offset_left = 44
	clip.offset_right = -40
	clip.offset_top = 92
	clip.offset_bottom = -34
	panel.add_child(clip)
	story = VBoxContainer.new()
	story.anchor_top = 1.0
	story.anchor_right = 1.0
	story.anchor_bottom = 1.0
	story.grow_vertical = Control.GROW_DIRECTION_BEGIN
	story.add_theme_constant_override("separation", 15)
	clip.add_child(story)
	var g := Gradient.new()
	g.set_color(0, PAPER)
	g.set_color(1, Color(PAPER.r, PAPER.g, PAPER.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 64
	var fade := TextureRect.new()
	fade.texture = gt
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.anchor_right = 1.0
	fade.offset_bottom = 70
	clip.add_child(fade)


func _say(parts: Array, dim := false) -> void:
	# parts: [[font key, size, colour, text], ...] run together as one paragraph
	var r := RichTextLabel.new()
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_constant_override("line_separation", 5)
	for p in parts:
		r.push_font(F[p[0]], p[1])
		r.push_color(p[2])
		r.add_text(p[3])
		r.pop()
		r.pop()
	if dim:
		r.modulate.a = 0.5
	story.add_child(r)


func _gap(h: int) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	story.add_child(c)


# The column at each moment, in the words of content/ink/door.ink, except the Father's line when
# he looks away from the kid, which is a stand-in to show the voices noticing where he looks.
func _page(which: String) -> void:
	for c in story.get_children():
		story.remove_child(c)
		c.queue_free()
	var lot := "The passenger door of the pickup opened. A kid got out and came across the gravel with his hood up and his hands in the pouch of his sweatshirt, not hurrying, getting soaked."
	if which == "lot":
		_say([["read", 24, INK, lot]])
		return
	_say([["read", 24, INK, lot]], true)
	_say([["read", 24, INK, "He stopped in front of the stool and held up his phone. On the screen was a photo of a driver's licence."]])
	_say([["ui_b", 17, MUTED, "HOODIE   "], ["read", 24, INK, "yeah"]])
	_say([["read", 24, INK, "He had earbuds in. He didn't take them out."]])
	_say([["ui_b", 17, FATHER, "THE FATHER   "], ["father", 24, FATHER, "A picture of a card isn't a card."]])
	_say([["ui_b", 17, WRONGMAN, "THE WRONG MAN   "], ["wrong", 28, WRONGMAN, "Everybody in that story came in out of the rain. Every one of them."]])
	if which == "room":
		_say([["ui_b", 17, FATHER, "THE FATHER   "], ["father", 24, FATHER, "He's in front of you. Not over there."]])
	_gap(6)
	_say([["read", 22, RED, "1.  "], ["read", 22, INK, "Take the phone and look at the photo."]])
	_say([["read", 22, RED, "2.  "], ["father_b", 18, FATHER, "[THE FATHER · Medium 8]  "], ["read", 22, INK, "Look at him, not the phone."]])
	_say([["read", 22, RED, "3.  "], ["ui_b", 18, WRONGMAN, "[THE WRONG MAN · Medium 8]  "], ["read", 22, INK, "Look past him at the truck."]])
	_say([["read", 22, RED, "4.  "], ["read", 22, INK, "“Rough night to be out in.”"]])


# The Wrong Man's mark from door.ink (#mark: door.door): a box round the door, in his hand, a broken
# line that wanders and runs a little past where it started. It's drawn on the room itself, so it
# stays on the door as he turns his head.
func _draw_marks() -> void:
	if not mark_on:
		return
	var m := 0.08
	var world := [Vector3(DOOR_W - m, 0.04, 10.0), Vector3(DOOR_E + m, 0.04, 10.0), Vector3(DOOR_E + m, 2.38 + m, 10.0), Vector3(DOOR_W - m, 2.38 + m, 10.0)]
	var corners := []
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for w in world:
		if cam.is_position_behind(w):
			return
		corners.append(cam.unproject_position(w) + Vector2(r.randf_range(-6, 6), r.randf_range(-6, 6)))
	corners.append(corners[0].lerp(corners[1], 0.14) + Vector2(0, -3))
	var fine := PackedVector2Array()
	for i in corners.size() - 1:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[i + 1]
		var bow := r.randf_range(-7.0, 7.0)
		var nrm := (b - a).orthogonal().normalized()
		for k in 16:
			var t := k / 16.0
			fine.append(a.lerp(b, t) + nrm * sin(t * PI) * bow)
	fine.append(corners[corners.size() - 1])
	_dashes(fine, 13.0, 8.0, Color(WRONGMAN, 0.95), 2.8)


func _dashes(pts: PackedVector2Array, on: float, off: float, c: Color, w: float) -> void:
	var drawing := true
	var left := on
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var seg := a.distance_to(b)
		var pos := 0.0
		while pos < seg:
			var step := minf(left, seg - pos)
			if drawing:
				marks.draw_line(a.lerp(b, pos / seg), a.lerp(b, (pos + step) / seg), c, w, true)
			pos += step
			left -= step
			if left <= 0.0:
				drawing = not drawing
				left = on if drawing else off


# ---------------------------------------------------------------- the camera

# Look from his eyes so that `subject` sits at `x_frac` across the world and `y_frac` down it.
func _aim(subject: Vector3, x_frac := 0.5, y_frac := 0.5) -> void:
	cam.position = EYE
	cam.look_at(subject, Vector3.UP)
	var vp := Vector2(view.size)
	var tv := tan(deg_to_rad(cam.fov) / 2.0)
	var th := tv * vp.x / vp.y
	cam.rotate(Vector3.UP, atan((x_frac * 2.0 - 1.0) * th))
	cam.rotate_object_local(Vector3.RIGHT, atan((y_frac * 2.0 - 1.0) * tv))


func _grab(name: String) -> void:
	marks.queue_redraw()
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	print("saved ", name)


func _shoot() -> void:
	# let the rain fall and the column settle
	for i in 24:
		await get_tree().process_frame
	# 1. out through the door: the kid coming across the lot from the pickup
	_page("lot")
	_aim(Vector3(3.45, 1.25, 10.1), 0.5, 0.5)
	await _grab("1-door")
	# 2. the kid in front of the stool with his phone up; the Wrong Man marks the door behind him
	kid_lot.visible = false
	kid_door.visible = true
	_page("kid")
	mark_on = true
	var kid_aim := Vector3(2.35, 1.52, 9.4)
	_aim(kid_aim)
	await _grab("2-kid")
	# 3. turned to the room, the kid still there in front of him
	var room_aim := Vector3(7.76, 1.15, 5.35)
	_page("room")
	_aim(room_aim)
	await _grab("3-room")
	# the turn, from the kid to the room
	_page("kid")
	var d0 := (kid_aim - EYE).normalized()
	var d1 := (room_aim - EYE).normalized()
	var yaw0 := atan2(d0.x, d0.z)
	var yaw1 := atan2(d1.x, d1.z)
	var steps := 24
	for i in steps + 1:
		var t := float(i) / steps
		t = t * t * (3.0 - 2.0 * t)
		var yaw := lerp_angle(yaw0, yaw1, t)
		var pitch := lerpf(asin(d0.y), asin(d1.y), t)
		_aim(EYE + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 4.0)
		if i == steps / 2:
			_page("room")
		await _grab("turn-%02d" % i)
