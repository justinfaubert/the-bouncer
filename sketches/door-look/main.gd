# The door post, printed: a look test for The Bouncer.
#
# The door scene from sketches/door-camera (his stool beside the main door, 7:50 pm on Wednesday,
# the kid coming in out of the rain), run through the press: three inks on cream stock, a key block
# cut in strokes that follow the surfaces, lines printed in the light and cut out in the dark.
# Renders stills and a head turn into renders/.
#
#   godot --path . --rendering-driver opengl3 --resolution 1920x1080      (needs a display; xvfb-run works)
#
# How the picture is made (look/):
#   the eye      a camera on the room, lit as usual, into a SubViewport
#   the mask     a second camera on the same room, same place, that sees visual layer 20: every
#                surface draws there how the key block is cut on it (look/surface.gdshader), and a
#                quad over its view finds the room's edges and creases in the depth (look/lines.gdshader)
#   the press    a shader over the eye's picture that separates it into the three inks, cuts the key
#                block with the mask and prints it all on the paper (look/press.gdshader)
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
const MASK_LAYER := 20                         # the visual layer only the mask camera sees

# the stock and the three inks; the same as tools/press.py, which makes the separation table
const STOCK := Color("eae2cf")
const NIGHT := Color("1b2130")
const LAMP := Color("f0a23c")
const NEON := Color("d9382c")

# the column's type, knocked out of the night ink or printed in the voices' colours
const INK := Color("eae2cf")
const MUTED := Color("8f8a82")
const FATHER := Color("e3ad5c")
const WRONGMAN := Color("a5c2a6")
const RED := Color("ec5a47")

const TABLES := [Vector3(4.3, 0, 4.45), Vector3(13.1, 0, 4.9), Vector3(5.4, 0, 8.3), Vector3(13.4, 0, 8.2)]
const T28 := Vector3(9.4, 0, 8.1)
const POOL := Vector3(9.4, 0, 3.9)
const DOOR_W := 2.3                            # the main door runs x 2.3..4.1
const DOOR_E := 4.1

var cam: Camera3D
var mcam: Camera3D
var view: SubViewport
var mask_view: SubViewport
var env: Environment
var press: ShaderMaterial
var slip := 0.0
var scale_k := 1.0
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

var SURFACE := preload("res://look/surface.gdshader")
var GLASS := preload("res://look/glass.gdshader")

# A surface. `cut` is how the key block is cut on it (look/surface.gdshader): 0 strokes at a
# constant height, 1 strokes across the floor at right angles to `dir`, 2 strokes across the
# object's own `dir`, 3 none.
func _mat(c: Color, rough := 0.9, metal := 0.0, cut := 0, dir := Vector3.UP, px := 7.0, lines := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SURFACE
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("roughness", rough)
	m.set_shader_parameter("metallic", metal)
	m.set_shader_parameter("cut", cut)
	m.set_shader_parameter("cut_dir", dir)
	m.set_shader_parameter("cut_px", px)
	m.set_shader_parameter("lines", lines)
	return m


# Something that gives light: the key block is left solid or cut clean away, nothing between.
func _glow(c: Color, e: float) -> ShaderMaterial:
	var m := _mat(c, 1.0, 0.0, 3)
	m.set_shader_parameter("emission", c)
	m.set_shader_parameter("emission_energy", e)
	return m


# A screen: a quad of dark glass lit by its picture, facing +z unless turned by rot_y degrees.
func _screen_quad(size: Vector2, pos: Vector3, picture: String, energy: float, rot_y := 0.0, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	var sm := _glow(Color(1, 1, 1), energy)
	sm.set_shader_parameter("albedo", Color(0.04, 0.04, 0.05))
	sm.set_shader_parameter("emission_tex", _tex("res://textures/" + picture + ".png"))
	mi.material_override = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(mi)
	return mi


# A surface with a picture on it, projected from the world (so walls and floors tile across
# their boxes without seams), `size` metres to a repeat.
func _surfaced(m: ShaderMaterial, tex: String, size: float) -> ShaderMaterial:
	m.set_shader_parameter("albedo_tex", _tex("res://textures/" + tex + ".png"))
	m.set_shader_parameter("mapping", 1)
	m.set_shader_parameter("tex_size", size)
	return m


# A model from models/, straight from its .glb (so the project runs without the editor having
# imported it), its materials swapped for the print's by name.
func _model(path: String, at := Vector3.ZERO, parent: Node = null) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		push_warning("model " + path + ": " + str(err))
		return Node3D.new()
	var root := doc.generate_scene(state) as Node3D
	_reprint(root)
	(parent if parent else self).add_child(root)
	root.position = at
	return root


func _reprint(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			mi.set_surface_override_material(i, _from_model(mi.mesh.surface_get_material(i)))
	for c in n.get_children():
		_reprint(c)


# How each of the models' materials prints: which light-giving ones glow and how brightly, and how
# the key block is cut on the rest ([cut, direction, stroke spacing in px, line weight]).
const GLOWS := {"headlight": 9.0, "taillight": 3.0, "bulb": 4.0, "screen": 0.8, "phone_screen": 0.45, "juke_light": 0.9,
	"dome": 2.5, "amber_marker": 2.0}
const SCREENS := {"phone_screen": "phone_screen"}      # what's on which screen
const RECOLOUR := {"vinyl": Color("4c2622"), "paint": Color("6e2a24")}   # oxblood stools; the truck's red, gone to rust
const CUTS := {
	"skin": [0, Vector3.UP, 5.0, 0.6], "eye": [3, Vector3.UP, 5.0, 0.0], "iris": [3, Vector3.UP, 5.0, 0.0], "hair": [0, Vector3.UP, 4.0, 0.5],
	"hoodie": [0, Vector3.UP, 5.5, 0.7], "jeans": [0, Vector3.UP, 5.5, 0.7], "cord": [3, Vector3.UP, 5.0, 0.0],
	"paint": [2, Vector3(0.25, 1, 0), 6.0, 1.0], "tire": [2, Vector3(0, 1, 0), 6.0, 1.0],
	"felt": [1, Vector3(0, 0, 1), 7.0, 0.5], "laminate": [1, Vector3(0, 0, 1), 7.0, 1.0],
	"slacks": [0, Vector3.UP, 5.5, 0.7], "khaki": [0, Vector3.UP, 5.5, 0.7], "trousers": [0, Vector3.UP, 5.5, 0.7],
	"flannel": [0, Vector3.UP, 5.5, 0.7], "jacket": [0, Vector3.UP, 5.5, 0.7], "coat": [0, Vector3.UP, 5.5, 0.7],
	"cardigan": [0, Vector3.UP, 5.5, 0.7], "tweed": [0, Vector3.UP, 5.5, 0.7], "tshirt": [0, Vector3.UP, 5.5, 0.7],
	"apron": [0, Vector3.UP, 5.5, 0.7], "hivis": [0, Vector3.UP, 5.5, 0.7], "sweatshirt": [0, Vector3.UP, 5.5, 0.7],
}
var from_model_cache := {}


func _from_model(src: Material) -> Material:
	if src == null:
		return M.wall
	var key := src.resource_name
	if from_model_cache.has(key):
		return from_model_cache[key]
	var sm := src as BaseMaterial3D
	var c := sm.albedo_color if sm else Color(0.7, 0.7, 0.7)
	if RECOLOUR.has(key):
		c = RECOLOUR[key]
	var out: Material
	if key == "wood":
		out = M.top                              # tables and the like: the room's own worn varnish
	elif key == "glass" or (sm and sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
		out = _glass(c, clampf(c.a, 0.08, 0.5))
	elif GLOWS.has(key):
		var e := sm.emission if sm and sm.emission_enabled else c
		out = _glow(e, GLOWS[key])
		if SCREENS.has(key):
			# a screen: dark glass lit by its picture
			out.set_shader_parameter("albedo", Color(0.04, 0.04, 0.05))
			out.set_shader_parameter("emission", Color(1, 1, 1))
			out.set_shader_parameter("emission_tex", _tex("res://textures/" + SCREENS[key] + ".png"))
	else:
		var cut: Array = CUTS.get(key, [0, Vector3.UP, 6.0, 1.0])
		out = _mat(c, sm.roughness if sm else 0.8, sm.metallic if sm else 0.0, cut[0], cut[1], cut[2], cut[3])
	from_model_cache[key] = out
	return out


# A texture straight from its PNG, so the project runs without the editor having imported it.
func _tex(path: String, mips := true) -> ImageTexture:
	var img := Image.load_from_file(path)
	if mips:
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _glass(c: Color, a: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLASS
	m.set_shader_parameter("albedo", Color(c.r, c.g, c.b, a))
	return m


func _materials() -> void:
	var across := Vector3(1, 0, 0.3)          # floor strokes that run into the room from the door
	var along := Vector3(0, 0, 1)             # strokes that run along the front, across the room
	# the walls: nicotine plaster over a dark wainscot, a rail between at a metre
	M.wall = _surfaced(_mat(Color(1, 1, 1)), "plaster", 2.0)
	M.wall.set_shader_parameter("split_y", 1.0)
	M.wall.set_shader_parameter("albedo_tex2", _tex("res://textures/panel.png"))
	M.ceiling = _mat(Color("8e8a83"), 0.9, 0.0, 1, across)
	M.carpet = _surfaced(_mat(Color(1, 1, 1), 0.9, 0.0, 1, across, 7.0, 0.4), "carpet", 0.9)
	M.carpet.set_shader_parameter("wear_tex", _tex("res://textures/wear.png"))      # past the mat, along the bar
	M.carpet.set_shader_parameter("wear_rect", Vector4(0, 0, 16, 10))
	M.carpet.set_shader_parameter("worn", Color("66594b"))
	M.wood = _surfaced(_mat(Color(1, 1, 1), 0.7), "wood", 1.2)
	M.top = _surfaced(_mat(Color(1, 1, 1), 0.45, 0.0, 1, along), "top", 1.0)
	M.dark = _mat(Color("4a4843"), 0.6)
	M.black = _mat(Color("1f1e22"), 0.5)
	M.frame = _mat(Color("3d3a36"), 0.45, 0.35)
	M.felt = _mat(Color("6f716c"), 0.9, 0.0, 1, along)
	M.paper = _mat(Color("d9d4c8"), 0.9, 0.0, 3)
	M.burn = _mat(Color("2c2825"), 0.9, 0.0, 3, Vector3.UP, 7.0, 0.0)
	M.person = _mat(Color("b1aca3"), 0.9, 0.0, 0, Vector3.UP, 6.0)
	M.hoodie = _mat(Color("5c5953"), 0.9, 0.0, 0, Vector3.UP, 6.0)
	M.jeans = _mat(Color("4e5159"), 0.9, 0.0, 0, Vector3.UP, 6.0)
	M.skin = _mat(Color("c7c0b4"), 0.8, 0.0, 0, Vector3.UP, 5.0)
	M.gravel = _mat(Color("4a4946"), 0.34, 0.0, 1, Vector3(1, 0, 0.15), 7.0, 0.3)
	M.puddle = _mat(Color("1b1c1f"), 0.04, 0.2, 1, Vector3(1, 0, 0.15), 7.0, 0.0)
	M.road = _mat(Color("333336"), 0.28, 0.0, 1, Vector3(0, 0, 1), 7.0, 0.3)
	M.water = _mat(Color("111317"), 0.1, 0.2, 1, Vector3(0, 0, 1), 7.0, 0.0)
	M.truck = _mat(Color("5f5c57"), 0.35, 0.3, 2, Vector3(0.3, 1, 0), 6.0)
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
	M.shade = _glow(Color("f0c890"), 0.9)                 # a fabric shade, lit through
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
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.5
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
	_model("res://models/door_frame.glb", Vector3((DOOR_W + DOOR_E) / 2.0, 0, zf))
	_leaf(DOOR_W + 0.04, 1.0)
	_leaf(DOOR_E - 0.04, -1.0)
	# the screen between the vestibule and the room: panelled to the waist, glass above
	_box(Vector3(0.1, 1.05, 1.2), Vector3(4.55, 0.525, 9.5), M.wood)
	_box(Vector3(0.14, 0.06, 1.24), Vector3(4.55, 1.08, 9.5), M.frame)
	_box(Vector3(0.14, 0.08, 1.24), Vector3(4.55, 2.24, 9.5), M.frame)
	_box(Vector3(0.12, 2.28, 0.08), Vector3(4.55, 1.14, 8.92), M.frame)
	_box(Vector3(0.02, 1.1, 1.1), Vector3(4.55, 1.66, 9.5), M.glass)
	var sign := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(0.21, 0.28)
	sign.mesh = sq
	sign.position = Vector3(4.535, 1.6, 9.72)
	sign.rotation.y = deg_to_rad(-90)
	var sm := _mat(Color(1, 1, 1), 0.5, 0.0, 3)
	sm.set_shader_parameter("albedo_tex", _tex("res://textures/sign_id.png"))
	sign.material_override = sm
	add_child(sign)
	# the ledge along the front wall, by his right hand: the scanner, the clicker, the incident
	# book, and the old cigarette burns
	_box(Vector3(1.85, 1.0, 0.45), Vector3(1.275, 0.5, 9.78), M.wood)
	_box(Vector3(1.95, 0.05, 0.55), Vector3(1.275, 1.025, 9.75), M.top)
	for i in 11:
		var b := _cyl(0.012, 0.012, 0.002, Vector3(rng.randf_range(0.4, 2.15), 1.051, rng.randf_range(9.55, 9.96)), M.burn, null, 8)
		b.scale = Vector3(rng.randf_range(1.0, 2.6), 1, 1)
	# masking tape on the wall beside the door, where he looks from a licence, with the night's sum
	# on it in marker: born on this date or before, you're nineteen tonight
	var tape := MeshInstance3D.new()
	var tq := QuadMesh.new()
	tq.size = Vector2(0.15, 0.042)
	tape.mesh = tq
	tape.position = Vector3(2.157, 1.4, 9.996)
	tape.rotation = Vector3(0, deg_to_rad(180), deg_to_rad(-2.5))
	var tm := _mat(Color(1, 1, 1), 0.8, 0.0, 3, Vector3.UP, 7.0, 0.3)
	tm.set_shader_parameter("albedo_tex", _tex("res://textures/tape_date.png"))
	tm.set_shader_parameter("alpha_scissor", 0.5)
	tape.material_override = tm
	add_child(tape)
	# (made facing whoever works them from the lot's side; turned round to face him)
	var things := _model("res://models/ledge_props.glb")
	var spots := {"scanner": [Vector3(1.92, 1.05, 9.72), 184.0], "clicker": [Vector3(1.55, 1.05, 9.76), 200.0],
		"book": [Vector3(1.05, 1.05, 9.74), 172.0], "lighter": [Vector3(0.72, 1.05, 9.82), 140.0],
		"mug": [Vector3(0.48, 1.05, 9.7), 190.0]}
	for c in things.get_children():
		if spots.has(String(c.name)):
			var spot: Array = spots[String(c.name)]
			c.position = spot[0]
			c.rotation = Vector3(0, deg_to_rad(spot[1]), 0)
	# his stool, and the mat inside the door
	_stool(Vector3(EYE.x, 0, EYE.z), 0.78)
	_box(Vector3(1.8, 0.012, 1.0), Vector3((DOOR_W + DOOR_E) / 2.0, 0.006, 9.45), M.dark)


func _leaf(hinge_x: float, dir: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(hinge_x, 0, 10.12)
	add_child(pivot)
	var w := 0.86
	_model("res://models/door_leaf_" + ("left" if dir > 0.0 else "right") + ".glb", Vector3.ZERO, pivot)
	# the gold leaf on the outside of the glass, to be read from the lot: from his stool, backwards
	var letters := MeshInstance3D.new()
	var lq := QuadMesh.new()
	lq.size = Vector2(w - 0.1, (w - 0.1) * 2.0)
	letters.mesh = lq
	letters.position = Vector3(dir * w / 2.0, 1.35, 0.012)
	var lm := _glass(Color(1, 1, 1), 1.0)
	lm.set_shader_parameter("albedo_tex", _tex("res://textures/door_glass_" + ("left" if dir > 0.0 else "right") + ".png"))
	lm.set_shader_parameter("roughness", 0.35)
	lm.set_shader_parameter("metallic", 0.0)
	letters.material_override = lm
	letters.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(letters)
	# rain on the outside of the glass
	for i in 34:
		_box(Vector3(0.005, rng.randf_range(0.012, 0.07), 0.003), Vector3(dir * rng.randf_range(0.1, w - 0.1), rng.randf_range(0.3, 2.05), 0.016), M.drop, 0.0, pivot)
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
	_screen_quad(Vector2(0.44, 0.28), Vector3(0, 0, 0.03), "lotto", 1.2, 0.0, lot)
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
	var s := _model("res://models/stool_" + ("bar" if seat >= 0.7 else "low") + ".glb", at)
	s.rotation.y = rng.randf_range(0.0, TAU)


func _table(at: Vector3, round := false, _size := 0.8) -> void:
	_model("res://models/table_" + ("round" if round else "square") + ".glb", at)


func _sconce(at: Vector3, rot_y: float) -> void:
	var n := Node3D.new()
	n.position = at
	n.rotation.y = deg_to_rad(rot_y)
	add_child(n)
	_box(Vector3(0.09, 0.14, 0.03), Vector3(0, -0.04, 0.015), M.frame, 0.0, n)          # the plate
	_box(Vector3(0.02, 0.02, 0.14), Vector3(0, -0.04, 0.09), M.frame, 0.0, n)           # the arm
	_cyl(0.05, 0.075, 0.12, Vector3(0, 0.02, 0.16), M.shade, n, 14)
	_ball(0.028, Vector3(0, -0.03, 0.16), M.bulb, n)
	# the shade sends the light up and down the wall in two scallops with hard edges, the kind the
	# press cuts cleanly, and a little into the room
	for d in [1.0, -1.0]:
		var sp := SpotLight3D.new()
		sp.position = Vector3(0, 0.02 * d, 0.16)
		sp.rotation.x = deg_to_rad(90.0 * d)
		sp.light_color = Color("ffc98a")
		sp.light_energy = 1.5 if d > 0.0 else 1.0
		sp.spot_range = 2.4
		sp.spot_angle = 44.0
		sp.spot_angle_attenuation = 4.0
		n.add_child(sp)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 0.0, 0.3)
	l.light_color = Color("ffc98a")
	l.light_energy = 0.18
	l.omni_range = 2.0
	n.add_child(l)


func _pint(at: Vector3) -> void:
	_cyl(0.042, 0.034, 0.15, at + Vector3(0, 0.075, 0), M.pint, null, 12)


# A lamp on a cord over a table, its shade's top at drop + 0.1 and its rim at drop - 0.1.
func _pendant(p: Vector3, drop := 2.35) -> void:
	_cyl(0.005, 0.005, 3.2 - drop - 0.1, Vector3(p.x, (3.2 + drop + 0.1) / 2.0, p.z), M.frame, null, 6)
	var lamp := _model("res://models/pendant.glb", Vector3(p.x, drop + 0.1, p.z))
	lamp.rotation.y = rng.randf_range(0.0, TAU)


func _floor_things() -> void:
	# the pool table, a coin-op, with its lamp; the balls where the big man's buddy left them, the
	# eight still down
	_model("res://models/pool_table.glb", POOL)
	var balls := [[Vector2(-0.62, -0.28), "e8e4d8"], [Vector2(-0.45, 0.06), "b8342a"], [Vector2(0.58, -0.38), "d9a52e"],
		[Vector2(0.21, 0.3), "2a3a78"], [Vector2(-0.88, 0.16), "d86a2a"], [Vector2(0.77, 0.24), "6a2430"], [Vector2(0.05, -0.12), "141414"]]
	for b in balls:
		_ball(0.0286, POOL + Vector3(b[0].x, 0.8286, b[0].y), _mat(Color(b[1]), 0.2, 0.0, 3, Vector3.UP, 5.0, 0.3))
	_model("res://models/pool_light.glb", POOL + Vector3(0, 2.06, 0))
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
	# the jukebox on the back wall, a screen that takes a card and plays anything (models face -z
	# as they come; turned round to face the room). The pictures on the screens are quads laid over
	# the models' own glass, which has no UVs.
	var juke := _model("res://models/jukebox.glb", Vector3(13.2, 0.95, 0.0))
	juke.rotation.y = PI
	var jq := _screen_quad(Vector2(0.43, 0.31), Vector3(0, 0.7205, -0.268), "jukebox", 1.0, 180.0, juke)
	jq.rotation.x = deg_to_rad(-4.3)                      # the screen leans back
	# a TV on the back wall that table 28 watches, on the hockey, and one on the east wall on the
	# news (bible/06_THE_HOTEL.md)
	for tv in [[Vector3(9.4, 2.45, 0.0), 180.0, "tv_hockey"], [Vector3(16.0, 2.35, 4.0), 90.0, "tv_news"]]:
		var set := _model("res://models/tv.glb", tv[0])
		set.rotation.y = deg_to_rad(tv[1])
		_screen_quad(Vector2(1.21, 0.69), Vector3(0, 0.0025, -0.107), tv[2], 1.1, 180.0, set)
	# the dartboard on the east wall, its doors open on the chalked scores, and the oche on the
	# carpet at 2.37 m
	var board := _model("res://models/dartboard.glb", Vector3(16.0, 1.73, 2.3))
	board.rotation.y = PI / 2.0
	_box(Vector3(0.04, 0.008, 0.6), Vector3(16.0 - 2.37, 0.004, 2.3), M.frame)


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
	_model("res://models/truck.glb", Vector3.ZERO, t)
	# inside: the sister at the wheel lit by her phone, her boyfriend across the back seat
	_person("driver", Vector3(-0.45, 0, -0.2), Vector3.ZERO, t)
	_person("vape", Vector3(0.4, 0, 0.75), Vector3.ZERO, t)
	var dome := OmniLight3D.new()
	dome.position = Vector3(0, 1.72, -0.3)
	dome.light_color = Color("ffe0b0")
	dome.light_energy = 0.7
	dome.omni_range = 2.0
	t.add_child(dome)
	# the headlights' beams
	for sx in [-0.72, 0.72]:
		var beam := _spot(Vector3.ZERO, Vector3.ZERO + Vector3(0, -0.5, -10), Color("eef2ff"), 4.5, 22.0, 22.0, true, t)
		beam.position = Vector3(sx, 0.95, -3.0)
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
	var rm := ShaderMaterial.new()
	rm.shader = preload("res://look/rain.gdshader")
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
	# table 28: five of them round the big table, one stool empty (k 4)
	var t28 := ["team_jacket", "hearing_aid", "scratch", "cardigan", "", "glasses"]
	for k in 6:
		if t28[k] == "":
			continue
		var a := TAU * k / 6.0 + 0.25
		_person(t28[k], T28 + Vector3(cos(a) * 1.18, 0, sin(a) * 1.18), T28)
	# the big man at the pool table with his cue, and his buddy, the one he's letting win
	_person("bigman", POOL + Vector3(1.8, 0, 1.0), POOL)
	_person("buddy", POOL + Vector3(-1.9, 0, 1.2), POOL)
	# behind the bar, the lifer; at it, Hi-Vis four beers in, and at the far end, the man nobody
	# saw come in
	_person("bartender", Vector3(1.15, 0, 4.8), Vector3(6.0, 0, 4.8))
	_person("hivis", Vector3(2.65, 0, 3.3), Vector3(0.0, 0, 3.3))
	_person("endbar", Vector3(2.65, 0, 1.6), Vector3(0.0, 0, 1.6))
	# two more of the work crew at a table; a resident down from upstairs at the jukebox
	_person("crew_a", TABLES[1] + Vector3(-0.62, 0, 0), TABLES[1])
	_person("crew_b", TABLES[1] + Vector3(0, 0, 0.62), TABLES[1])
	_person("slippers", Vector3(13.2, 0, 1.2), Vector3(13.2, 0, 0.0))
	# the kid: first coming across the gravel from the pickup, hood up, hands in his pouch
	kid_lot = _kid(Vector3(5.3, 0, 13.4), Vector3(3.2, 0, 10.1), false)
	# then in front of the stool, holding his phone up
	kid_door = _kid(Vector3(2.62, 0, 9.62), EYE, true)
	kid_door.visible = false


# One of the people, sculpted (tools/people.py), standing at `at` or sitting on the stool there,
# facing `face_to`.
func _person(name: String, at: Vector3, face_to: Vector3, parent: Node = null) -> Node3D:
	var n: Node3D
	if parent != null:
		n = _model("res://models/people/" + name + ".glb", at, parent)
	else:
		n = _person_root(at, face_to)
		_model("res://models/people/" + name + ".glb", Vector3.ZERO, n)
	var anchors := _anchors(name)
	if anchors.has("phone"):
		# the screen's light, on the hand round it and the face over it
		var ph := OmniLight3D.new()
		var at_phone: Array = anchors.phone
		var facing: Array = anchors.phone_facing
		ph.position = Vector3(at_phone[0], at_phone[1], at_phone[2]) + Vector3(facing[0], facing[1], facing[2]) * 0.05
		ph.light_color = Color("dfe8ff")
		ph.light_energy = 0.35
		ph.omni_range = 0.7
		n.add_child(ph)
	return n


func _kid(at: Vector3, face_to: Vector3, phone_up: bool) -> Node3D:
	return _person("hoodie_door" if phone_up else "hoodie_lot", at, face_to)


# Where things are on a person (their phone, head, hands), written beside their model.
func _anchors(name: String) -> Dictionary:
	var f := FileAccess.open("res://models/people/" + name + ".json", FileAccess.READ)
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text())


# ---------------------------------------------------------------- light

func _lights() -> void:
	# the vestibule: the lamp over the door and his stool
	_omni(Vector3(2.25, 2.95, 9.2), Color("ffc27a"), 1.8, 4.6, true)
	_cyl(0.16, 0.16, 0.05, Vector3(2.25, 3.17, 9.2), M.lamp)
	# the room's light behind him, spilling past his shoulder onto whoever's in front of the stool
	_omni(Vector3(2.3, 1.95, 8.1), Color("ffcf93"), 0.55, 3.2)
	# the sign's red over the step and the lot
	_omni(Vector3(4.1, 3.4, 11.1), Color("ff3a28"), 0.7, 7.0, true)
	# the lamp at the edge of the lot
	var s := _omni(Vector3(15.4, 6.2, 21.5), Color("ffa04a"), 5.0, 16.0, true)
	s.omni_attenuation = 1.4
	# the pool table's lamp
	_spot(POOL + Vector3(0, 1.86, 0), POOL, Color("fff0d6"), 7.0, 3.2, 58.0, true)
	# the pendants: over the tables (table 28's throws shadows) and three over the bar
	_spot(T28 + Vector3(0, 2.2, 0), T28, Color("ffb865"), 3.2, 3.6, 55.0, true)
	for t in TABLES:
		_spot(t + Vector3(0, 2.2, 0), t, Color("ffb865"), 3.0, 3.6, 55.0)
	for z in [2.4, 4.4, 6.4]:
		_spot(Vector3(1.95, 2.15, z), Vector3(1.95, 0, z), Color("ffb865"), 2.6, 3.4, 52.0)
	# the old dining room's sconces, still on the walls: small pools of lamp on the plaster
	for sc in [[Vector3(4.8, 2.05, 0.1), 0.0], [Vector3(11.6, 2.05, 0.1), 0.0], [Vector3(15.9, 2.05, 6.0), -90.0],
			[Vector3(15.9, 2.05, 9.3), -90.0], [Vector3(14.3, 2.05, 9.98), 180.0]]:
		_sconce(sc[0], sc[1])
	# the back bar, the cooler, the TVs and the jukebox
	_omni(Vector3(0.7, 2.5, 4.4), Color("ffcf93"), 1.2, 4.5)
	_omni(Vector3(1.1, 1.2, 0.7), Color("dfe9f2"), 0.5, 2.6)
	_omni(Vector3(9.4, 2.3, 0.7), Color("a9c0e8"), 0.55, 4.5)
	_omni(Vector3(15.2, 2.3, 4.0), Color("a9c0e8"), 0.45, 4.0)
	_omni(Vector3(13.2, 1.6, 0.7), Color("f07aa0"), 0.8, 3.0)


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
	var win := get_viewport().get_visible_rect().size
	var size := Vector2i(roundi(win.x * WORLD_W), roundi(win.y))
	# the eye: the room as he sees it
	view = SubViewport.new()
	view.size = size
	view.msaa_3d = Viewport.MSAA_4X
	view.positional_shadow_atlas_size = 4096
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	cam = Camera3D.new()
	cam.fov = 58.0
	cam.near = 0.05
	cam.far = 900.0
	cam.environment = env
	cam.set_cull_mask_value(MASK_LAYER, false)
	view.add_child(cam)
	# the mask: the same room from the same place, drawn as the key block's cut, with the lines
	# found over it (the Compatibility renderer can't read the depth of a multisampled view, so the
	# mask gets its own)
	mask_view = SubViewport.new()
	mask_view.size = size
	mask_view.world_3d = view.find_world_3d()
	mask_view.positional_shadow_atlas_size = 256
	mask_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(mask_view)
	var menv := Environment.new()
	menv.background_mode = Environment.BG_COLOR
	menv.background_color = Color(0.5, 0.0, 0.0)
	menv.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	menv.ambient_light_color = Color.BLACK
	menv.ambient_light_energy = 0.0
	menv.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	mcam = Camera3D.new()
	mcam.fov = cam.fov
	mcam.near = cam.near
	mcam.far = cam.far
	mcam.environment = menv
	mcam.cull_mask = 0xFFFFF
	mask_view.add_child(mcam)
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	quad.mesh = qm
	var lm := ShaderMaterial.new()
	lm.shader = preload("res://look/lines.gdshader")
	quad.material_override = lm
	quad.layers = 0
	quad.set_layer_mask_value(MASK_LAYER, true)
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mcam.add_child(quad)
	quad.position = Vector3(0, 0, -1)

	var layer := CanvasLayer.new()
	add_child(layer)
	# the press, over the world's part of the screen
	var sheet := TextureRect.new()
	sheet.texture = view.get_texture()
	sheet.anchor_right = WORLD_W
	sheet.anchor_bottom = 1.0
	sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.stretch_mode = TextureRect.STRETCH_SCALE
	press = ShaderMaterial.new()
	press.shader = preload("res://look/press.gdshader")
	press.set_shader_parameter("scene", view.get_texture())
	press.set_shader_parameter("cut_mask", mask_view.get_texture())
	press.set_shader_parameter("separation", _tex("res://press/separation.png", false))
	press.set_shader_parameter("grain", _tex("res://press/grain.png", false))
	press.set_shader_parameter("paper_tex", _tex("res://press/paper.png", false))
	press.set_shader_parameter("paper", STOCK)
	press.set_shader_parameter("ink_night", NIGHT)
	press.set_shader_parameter("ink_lamp", LAMP)
	press.set_shader_parameter("ink_neon", NEON)
	press.set_shader_parameter("view_px", Vector2(size))
	sheet.material = press
	layer.add_child(sheet)
	# the voices' marks, in pen over the print, where the thing they mark is
	marks = Control.new()
	marks.anchor_right = WORLD_W
	marks.anchor_bottom = 1.0
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(marks)
	marks.draw.connect(_draw_marks)
	# the text column: a solid of the night ink with the words knocked out; the newest lines at the
	# bottom, the older ones going up and away
	var panel := ColorRect.new()
	panel.anchor_left = WORLD_W
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://look/column.gdshader")
	cm.set_shader_parameter("paper_tex", _tex("res://press/paper.png", false))
	cm.set_shader_parameter("paper", STOCK)
	cm.set_shader_parameter("ink_night", NIGHT)
	panel.material = cm
	layer.add_child(panel)
	var k := win.y / 900.0                    # the column was laid out at 900 px high
	var head := Label.new()
	head.text = "WEDNESDAY  ·  7:50 PM  ·  ON THE DOOR"
	head.add_theme_font_override("font", F.ui_b)
	head.add_theme_font_size_override("font_size", roundi(17 * k))
	head.add_theme_color_override("font_color", MUTED)
	head.position = Vector2(44, 40) * k
	panel.add_child(head)
	var clip := Control.new()
	clip.clip_contents = true
	clip.anchor_right = 1.0
	clip.anchor_bottom = 1.0
	clip.offset_left = 44 * k
	clip.offset_right = -40 * k
	clip.offset_top = 92 * k
	clip.offset_bottom = -34 * k
	panel.add_child(clip)
	story = VBoxContainer.new()
	story.anchor_top = 1.0
	story.anchor_right = 1.0
	story.anchor_bottom = 1.0
	story.grow_vertical = Control.GROW_DIRECTION_BEGIN
	story.add_theme_constant_override("separation", roundi(15 * k))
	clip.add_child(story)
	scale_k = k


func _say(parts: Array, dim := false) -> void:
	# parts: [[font key, size, colour, text], ...] run together as one paragraph
	var r := RichTextLabel.new()
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_constant_override("line_separation", roundi(5 * scale_k))
	for p in parts:
		r.push_font(F[p[0]], roundi(p[1] * scale_k))
		r.push_color(p[2])
		r.add_text(p[3])
		r.pop()
		r.pop()
	if dim:
		r.modulate.a = 0.45
	story.add_child(r)


func _gap(h: int) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h * scale_k)
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
	var m := 0.05
	var world := [Vector3(DOOR_W - m, 0.04, 10.0), Vector3(DOOR_E + m, 0.04, 10.0), Vector3(DOOR_E + m, 2.38 + m, 10.0), Vector3(DOOR_W - m, 2.38 + m, 10.0)]
	var corners := []
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for w in world:
		if cam.is_position_behind(w):
			return
		corners.append(cam.unproject_position(w) + Vector2(r.randf_range(-6, 6), r.randf_range(-6, 6)) * scale_k)
	corners.append(corners[0].lerp(corners[1], 0.14) + Vector2(0, -3))
	var fine := PackedVector2Array()
	for i in corners.size() - 1:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[i + 1]
		var bow := r.randf_range(-7.0, 7.0) * scale_k
		var nrm := (b - a).orthogonal().normalized()
		for k in 16:
			var t := k / 16.0
			fine.append(a.lerp(b, t) + nrm * sin(t * PI) * bow)
	fine.append(corners[corners.size() - 1])
	_dashes(fine, 13.0 * scale_k, 8.0 * scale_k, Color(WRONGMAN, 0.95), 2.8 * scale_k)


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
	mcam.transform = cam.transform
	_pin_press()


# Tell the press where he's looking, so the grain and the paper stay put as he turns his head.
# The grain repeats a whole number of times round the circle, so there's no seam behind him.
func _pin_press() -> void:
	var half := deg_to_rad(cam.fov) / 2.0
	var ppr := (view.size.y / 2.0) / tan(half)
	var grain_px := 1.5
	var tile := 512.0 * grain_px                # the paper's repeat; the grain's (128) divides it
	ppr = roundf(TAU * ppr / tile) * tile / TAU
	press.set_shader_parameter("cam_basis", cam.global_transform.basis)
	press.set_shader_parameter("tan_half_fov", tan(half))
	press.set_shader_parameter("px_per_rad", ppr)
	press.set_shader_parameter("grain_px", grain_px)
	press.set_shader_parameter("paper_px", grain_px)
	press.set_shader_parameter("slip", slip)


func _grab(name: String) -> void:
	marks.queue_redraw()
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	if OS.get_environment("RAW") != "":
		view.get_texture().get_image().save_png(OUT + name + "-eye.png")
		mask_view.get_texture().get_image().save_png(OUT + name + "-mask.png")
	print("saved ", name)


func _shoot() -> void:
	# let the rain fall and the column settle
	_aim(Vector3(3.45, 1.25, 10.1))
	for i in 24:
		await get_tree().process_frame
	var only := OS.get_environment("SHOT")
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
	# 4. the same as 2, four drinks in: the plates slip
	_page("kid")
	slip = 6.0
	press.set_shader_parameter("time", 2.0)
	_aim(kid_aim)
	await _grab("4-drunk")
	slip = 0.0
	if only != "":
		return
	# the turn, from the kid to the room
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
