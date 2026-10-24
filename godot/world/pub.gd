# The Sov: the pub on the ground floor of the Sovereign Hotel, built in code, and everything round
# it he can get to on a Wednesday night: the back hall and the washrooms, the kitchen, the keg room
# under the bar, the smoking deck, the gravel lot out front, and a room upstairs.
#
# Units are metres. The bar room runs x 0..16 along the front and z 0..10 from its back wall to the
# front wall (the main door and the front window). Looking out of the main door, +x is on the left.
# Behind the back wall a strip 2.64 deep holds the kitchen (x 0..4.8) and the back hall (x 4.8..16)
# with the washrooms off it. The keg room is under the bar. The deck runs along the outside of the
# east wall. The lot is out the front, z > 10.2; past it the highway and the seawall and the strait.
# The layout follows the floor sketch (prototype/web/src/ui/views.js); the door and the room come
# from the look test (sketches/door-look/main.gd), where the way they're printed is explained.
class_name Pub
extends Node3D

const EYE_DOOR := Vector3(1.7, 1.62, 8.85)       # his eyes, sitting on the stool beside the door
const TABLES := [Vector3(4.3, 0, 4.45), Vector3(13.1, 0, 4.9), Vector3(5.4, 0, 8.3), Vector3(13.4, 0, 8.2)]
const T28 := Vector3(9.4, 0, 8.1)
const POOL := Vector3(9.4, 0, 3.9)
const SERVICE_Z := 5.0                         # the gap in the bar's stools, across from the bartender
const DOOR_W := 2.3                            # the main door runs x 2.3..4.1
const DOOR_E := 4.1
const ZF := 10.1                               # the front wall
const BACK := -2.64                            # the back of the back strip
const HALL_Z := -1.21                          # the washrooms' fronts, on the hall
const KEG_Y := -2.5                            # the keg room's floor
const UP_Y := 3.4                              # the upstairs floor
const MASK_LAYER := 20
const PEOPLE_LAYER := 3                        # the people are on it as well as the first: a light of their own (view.gd)
# The light of each place picks its ink (look/press.gdshader): the bar's lamps warm, the tubes in the
# back and the screens a green-white, the lot's sodium orange, the sign red.
const TUBE_LIGHT := "b0f0dc"                   # the back hall's tubes, the kitchen's and the washrooms'
const COLD_LIGHT := "cdeedd"                   # the cooler's glass behind the bar
# the night's colour: the lamps lean warm at eight and paler after midnight, and at last call the
# house lights come up white on everything (set_clock)
const EARLY := Color("ffa04a")
const LATE := Color("ffe4c4")

var M := {}
var rng := RandomNumberGenerator.new()
var anchors := {}          # named points: posts, hotspots, marks
var lights := {}           # named lights, for the clock and the posts
var dyn := {}              # things that change with the night: doors, glasses, chairs up
var lamps: Array = []      # the room's lamps, dimmed and brightened with the clock
var shadowed: Array = []   # [light, near: Vector3]: shadows only where he is
var town: Town             # the town round the Sov, Gary's office in it (world/town.gd): out only while he's away

var SURFACE := preload("res://look/surface.gdshader")
var GLASS := preload("res://look/glass.gdshader")


func build() -> void:
	rng.seed = 28
	_materials()
	_room()
	_vestibule()
	_bar()
	_floor_things()
	_back_strip()
	_keg_room()
	_deck()
	_outside()
	_facade()
	_store()
	_truck()
	_upstairs()
	_rain()
	_lights()
	_lobby()
	_town()


# The town, built last with its own dice so nothing in the building moves, and put away: it's out
# only while he's somewhere away from the Sov (away()), and its ground round the building at dusk.
func _town() -> void:
	town = Town.new()
	town.name = "town"
	add_child(town)
	town.build_for(self)


# Away from the Sov, or back (game/view.gd, as he gets somewhere): the town out or put away.
func away(where: String, clock: int, frame := "") -> void:
	if town != null:
		town.show_for(where, clock, frame)


const DEAD := Color(0.16, 0.1, 0.1)       # a neon letter with no light in it
var _as_built := {}                      # the lights dusk() turns, as they were built: the night's

# The Sov by the clock before the night has it (game/view.gd's daylight, with where he is): the
# signs on the roof and over the door come on at half past four, the lot's sodium lamp at twenty to
# five, warming up from nothing over a quarter of an hour, the far shore's lights as the sky goes.
# From the night's own hour on, and before there's a clock at all, everything is as it was built,
# exactly. And the town's own lights and how much of it is out (world/town.gd).
func dusk(c: float, where: String) -> void:
	if _as_built.is_empty():
		_as_built = {"neon": M.neon.get_shader_parameter("emission_energy"), "sodium": M.sodium.get_shader_parameter("emission_energy"),
			"far": M.far.get_shader_parameter("emission_energy"), "sign": (lights.sign as Light3D).light_energy,
			"roof_sign": (lights.roof_sign as Light3D).light_energy, "sodium_l": (lights.sodium as Light3D).light_energy}
	var night := c >= Town.NIGHT or c < 900.0
	var lit := night or c >= 990.0
	var warm := 1.0 if night else clampf((c - 1000.0) / 15.0, 0.0, 1.0)
	var dark := 1.0 if night else clampf((c - 975.0) / 85.0, 0.0, 1.0)
	M.neon.set_shader_parameter("emission_energy", _as_built.neon if lit else 0.0)
	(lights.sign as Light3D).light_energy = _as_built.sign if lit else 0.0
	(lights.roof_sign as Light3D).light_energy = _as_built.roof_sign if lit else 0.0
	for l in dyn.get("neon", []):
		(l as Label3D).modulate = (l as Label3D).get_meta("lit") if lit else DEAD
	# a sodium lamp coming on glows a dull orange and takes its time to get to its colour
	M.sodium.set_shader_parameter("emission_energy", _as_built.sodium if night else (_as_built.sodium * (0.2 + 0.8 * warm) if c >= 1000.0 else 0.0))
	(lights.sodium as Light3D).light_energy = _as_built.sodium_l * warm * warm
	M.far.set_shader_parameter("emission_energy", _as_built.far * dark)
	if town != null:
		town.by_clock(c, where)


# ---------------------------------------------------------------- materials and shapes

# A surface. `cut` is how the key block is cut on it (look/surface.gdshader): 0 strokes at a
# constant height, 1 strokes across the floor at right angles to `dir`, 2 strokes across the
# object's own `dir`, 3 none, 4 strokes that wrap round a form (faces, heads).
func mat(c: Color, rough := 0.9, metal := 0.0, cut := 0, dir := Vector3.UP, px := 7.0, lines := 1.0) -> ShaderMaterial:
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
func glow(c: Color, e: float) -> ShaderMaterial:
	var m := mat(c, 1.0, 0.0, 3)
	m.set_shader_parameter("emission", c)
	m.set_shader_parameter("emission_energy", e)
	return m


func screen_quad(size: Vector2, pos: Vector3, picture: String, energy: float, rot_y := 0.0, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	var sm := glow(Color(1, 1, 1), energy)
	sm.set_shader_parameter("albedo", Color(0.04, 0.04, 0.05))
	sm.set_shader_parameter("emission_tex", tex("res://textures/" + picture + ".png"))
	mi.material_override = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(mi)
	return mi


func surfaced(m: ShaderMaterial, t: String, size: float) -> ShaderMaterial:
	m.set_shader_parameter("albedo_tex", tex("res://textures/" + t + ".png"))
	m.set_shader_parameter("mapping", 1)
	m.set_shader_parameter("tex_size", size)
	return m


static var _glb_cache := {}


# A model from models/, straight from its .glb, its materials swapped for the print's by name.
func model(path: String, at := Vector3.ZERO, parent: Node = null) -> Node3D:
	var root: Node3D
	if _glb_cache.has(path):
		root = (_glb_cache[path] as PackedScene).instantiate()
	else:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(path, state)
		if err != OK:
			push_warning("model " + path + ": " + str(err))
			return Node3D.new()
		root = doc.generate_scene(state) as Node3D
		_reprint(root, _who(path))
		# the people (not his hands, nor Gary's) are on a layer of their own too, for the light from
		# his eyes
		if "/people/" in path and not path.get_file().begins_with("his_") and not path.get_file().begins_with("gary_"):
			for mi in root.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).set_layer_mask_value(PEOPLE_LAYER, true)
		var ps := PackedScene.new()
		_own(root, root)
		ps.pack(root)
		_glb_cache[path] = ps
		# the scene the file made is only the pattern now: free it, or it's still holding its
		# meshes when the game quits
		root.free()
		root = ps.instantiate()
	(parent if parent else self).add_child(root)
	root.position = at
	return root


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


func _reprint(n: Node, who := "") -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := _from_model(mi.mesh.surface_get_material(i), who)
			if mi.skin != null:
				m = _rest_cut(m, mi.mesh, i)
			mi.set_surface_override_material(i, m)
	for c in n.get_children():
		_reprint(c, who)


# whose model a file is, for what they wear (WEARS): the longest name there that the file's name
# starts with
static func _who(path: String) -> String:
	var base := path.get_file().get_basename()
	var best := ""
	for k in WEARS:
		var ks := str(k)
		if ks.length() > best.length() and (base == ks or base.begins_with(ks + "_")):
			best = ks
	return best


var _rest_cache := {}


# A person with bones (tools/rig.py) carries where each point of them is in their pose in a set of
# UVs (the second, where the first has a picture on it), so that the strokes round the form are cut
# by that, and stay put on them as they move (look/surface.gdshader's rest_uv).
func _rest_cut(m: Material, mesh: Mesh, surface: int) -> Material:
	var sm := m as ShaderMaterial
	if sm == null or sm.shader != SURFACE or not int(sm.get_shader_parameter("cut")) in [2, 4]:
		return m
	if not Vector3(sm.get_shader_parameter("cut_dir")).normalized().is_equal_approx(Vector3.UP):
		return m
	var fmt := (mesh as ArrayMesh).surface_get_format(surface)
	var which := 2 if fmt & Mesh.ARRAY_FORMAT_TEX_UV2 else (1 if fmt & Mesh.ARRAY_FORMAT_TEX_UV else 0)
	if which == 0:
		return m
	var key := str(sm.get_instance_id()) + ":" + str(which)
	if not _rest_cache.has(key):
		var r := sm.duplicate() as ShaderMaterial
		r.set_shader_parameter("rest_uv", which)
		_rest_cache[key] = r
	return _rest_cache[key]


const GLOWS := {"headlight": 9.0, "taillight": 3.0, "bulb": 4.0, "screen": 0.8, "phone_screen": 0.45, "juke_light": 0.9,
	"dome": 2.5, "amber_marker": 2.0}
const SCREENS := {"phone_screen": "phone_screen"}
# red is the sign's and blood's: a red flannel would print as either, so the flannels are brown, and
# so are the red hair, the rose cardigan and the tie. The women from upstairs drink white wine.
const RECOLOUR := {"vinyl": Color("4c2622"), "paint": Color("6e2a24"), "flannel": Color("5b4a36"),
	"hair_red": Color("5a4028"), "cardigan_c": Color("5e5048"), "tie": Color("2c3345"), "wine": Color("d8c78c"),
	# fair hair printed as pale as the skin, and a woman's long hair read as part of her head; grey
	# hair between the dark and the white
	"hair_blonde": Color("8a6a3c"), "hair_grey": Color("6e7276")}
# Each of them in a colour of their own, in what they wear, so they tell apart across the room and
# the press gives each their own ink or two (by the start of the model's file name, which all of a
# person's poses share; everyone else wears what tools/export_people.py gave them). Still no red.
const WEARS := {
	"hoodie": {"hoodie": Color("2f6a66")},                    # the kid: a teal hoodie
	"driver": {"jacket": Color("5e2a16")},                    # his sister: a rust canvas jacket
	"crew_a": {"hivis": Color("8ee03c")},                     # the mill crew's hi-vis
	"hivis": {"hivis": Color("8ee03c")},                      # and room eleven's
	"constable": {"uniform": Color("1f2a44"), "uniform_trim": Color("141a2a")},   # the constable's navy
	"team_jacket": {"jacket": Color("1f4438"), "jacket_trim": Color("d8b25a")},   # the team's green and gold
	"hearing_aid": {"flannel": Color("6e5a2c")},              # the work flannels: mustard,
	"bigman": {"flannel": Color("5a3424")},                   # brick,
	"crew_b": {"flannel": Color("3a5a48")},                   # green,
	"patron_a": {"flannel": Color("4c4a5a")},                 # and grey
	"cardigan": {"cardigan": Color("8a6c3c")},                # camel
	"glasses": {"tshirt": Color("4c6470")},                   # slate
	"buddy": {"tshirt": Color("8c7c46")},                     # khaki
	"vape": {"hoodie": Color("b08a2c")},                      # a mustard hoodie
	"ballcap": {"hoodie": Color("4a2418")},                   # a brown one
	"raincoat": {"raincoat": Color("c0a66a")},                # an ochre raincoat
	"slippers": {"cardigan": Color("4a7a66")},                # a sage cardigan
	"cook": {"tshirt": Color("dcd8ce")},                      # a white tee
	"patron_f": {"cardigan_c": Color("7a5a3a")},              # a brown cardigan
}
# how the key block is cut on the people's and the props' materials: [cut, direction, spacing, line weight].
# His own hand (models/people/his_right_*.glb) is "skin" too, and Hutch likes it as it prints, the
# strokes running round the fingers like wood grain (14 October): if the faces want a different
# cut, give the hand a material of its own rather than changing it.
const CUTS := {
	"skin": [4, Vector3.UP, 4.5, 0.7], "eye": [3, Vector3.UP, 5.0, 0.0], "iris": [3, Vector3.UP, 5.0, 0.0], "hair": [4, Vector3.UP, 3.5, 0.5],
	"hoodie": [4, Vector3.UP, 5.5, 0.8], "jeans": [2, Vector3.UP, 5.5, 0.7], "cord": [3, Vector3.UP, 5.0, 0.0],
	"paint": [2, Vector3(0.25, 1, 0), 6.0, 1.0], "tire": [2, Vector3(0, 1, 0), 6.0, 1.0],
	"felt": [1, Vector3(0, 0, 1), 7.0, 0.5], "laminate": [1, Vector3(0, 0, 1), 7.0, 1.0],
	"slacks": [2, Vector3.UP, 5.5, 0.7], "khaki": [2, Vector3.UP, 5.5, 0.7], "trousers": [2, Vector3.UP, 5.5, 0.7],
	"flannel": [4, Vector3.UP, 5.5, 0.8], "jacket": [4, Vector3.UP, 5.5, 0.8], "coat": [4, Vector3.UP, 5.5, 0.8],
	"cardigan": [4, Vector3.UP, 5.5, 0.8], "tweed": [4, Vector3.UP, 5.5, 0.8], "tshirt": [4, Vector3.UP, 5.5, 0.8],
	"apron": [4, Vector3.UP, 5.5, 0.8], "hivis": [4, Vector3.UP, 5.5, 0.8], "sweatshirt": [4, Vector3.UP, 5.5, 0.8],
	"suit": [4, Vector3.UP, 5.0, 0.8], "raincoat": [4, Vector3.UP, 5.5, 0.8], "whites": [4, Vector3.UP, 5.5, 0.8],
	"sweater": [4, Vector3.UP, 5.5, 0.8], "fleece": [4, Vector3.UP, 5.5, 0.8], "workjacket": [4, Vector3.UP, 5.5, 0.8],
	"cardigan_b": [4, Vector3.UP, 5.5, 0.8], "cardigan_c": [4, Vector3.UP, 5.5, 0.8], "doorman_jacket": [4, Vector3.UP, 5.0, 0.8],
	"shirt_white": [4, Vector3.UP, 5.5, 0.8], "shirt_dark": [4, Vector3.UP, 5.5, 0.8],
	"denim": [2, Vector3.UP, 5.5, 0.7], "jeans_black": [2, Vector3.UP, 5.5, 0.7], "jeans_light": [2, Vector3.UP, 5.5, 0.7],
	"skirt": [2, Vector3.UP, 5.5, 0.7],
	"hair_grey": [4, Vector3.UP, 3.5, 0.5], "hair_white": [4, Vector3.UP, 3.5, 0.5], "hair_blonde": [4, Vector3.UP, 3.5, 0.5],
	"hair_red": [4, Vector3.UP, 3.5, 0.5], "hair_dark": [4, Vector3.UP, 3.5, 0.5], "stubble": [4, Vector3.UP, 3.5, 0.5],
	"card": [1, Vector3(0, 0, 1), 7.0, 1.0], "card_back": [1, Vector3(0, 0, 1), 7.0, 1.0], "cardboard": [2, Vector3.UP, 6.0, 1.0],
	"uniform": [4, Vector3.UP, 5.0, 0.8], "uniform_trim": [4, Vector3.UP, 5.0, 0.8], "flannel_b": [4, Vector3.UP, 5.5, 0.8],
	"badge": [1, Vector3(0, 0, 1), 7.0, 1.0], "lanyard": [3, Vector3.UP, 5.0, 0.0],
	# the doorman's scar and his mala; the bookkeeper's ledger; Gary's own hand in his office, cut
	# like the doorman's (the grain round the fingers), with its hairs, spots, cuff and ring
	"scar": [4, Vector3.UP, 4.5, 0.7], "mala": [3, Vector3.UP, 5.0, 0.0], "tassel": [3, Vector3.UP, 5.0, 0.0],
	"ledger": [2, Vector3.UP, 6.0, 1.0],
	"skin_pale": [4, Vector3.UP, 4.5, 0.7], "age_spot": [4, Vector3.UP, 4.5, 0.7], "hand_hair": [4, Vector3.UP, 3.5, 0.5],
	"oxford": [4, Vector3.UP, 5.5, 0.8], "gold": [3, Vector3.UP, 5.0, 0.0],
	# the faces: lips cut like the skin they are, a shade darker; the lashes a solid line, and the dark
	# of a mouth behind the lips solid
	"lip": [4, Vector3.UP, 4.5, 0.7], "lash": [3, Vector3.UP, 5.0, 0.0], "mouth": [3, Vector3.UP, 5.0, 0.0],
}
var from_model_cache := {}


func _from_model(src: Material, who := "") -> Material:
	if src == null:
		return M.wall
	var key := src.resource_name
	var wears: Dictionary = WEARS.get(who, {})
	var ck := key + "@" + who if wears.has(key) else key
	if from_model_cache.has(ck):
		return from_model_cache[ck]
	var sm := src as BaseMaterial3D
	var c := sm.albedo_color if sm else Color(0.7, 0.7, 0.7)
	if RECOLOUR.has(key):
		c = RECOLOUR[key]
	if wears.has(key):
		c = wears[key]
	var out: Material
	if key == "wood":
		out = M.top
	elif key == "glass" or (sm and sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
		out = glass(c, clampf(c.a, 0.08, 0.5))
	elif GLOWS.has(key):
		var e := sm.emission if sm and sm.emission_enabled else c
		out = glow(e, GLOWS[key])
		if SCREENS.has(key):
			out.set_shader_parameter("albedo", Color(0.04, 0.04, 0.05))
			out.set_shader_parameter("emission", Color(1, 1, 1))
			out.set_shader_parameter("emission_tex", tex("res://textures/" + SCREENS[key] + ".png"))
	else:
		var cut: Array = CUTS.get(key, [0, Vector3.UP, 6.0, 1.0])
		out = mat(c, sm.roughness if sm else 0.8, sm.metallic if sm else 0.0, cut[0], cut[1], cut[2], cut[3])
	from_model_cache[ck] = out
	return out


static var _tex_cache := {}


func tex(path: String, mips := true) -> ImageTexture:
	return tex_static(path, mips)


static func tex_static(path: String, mips := true) -> ImageTexture:
	var key := path + ("" if mips else "#nomip")
	if _tex_cache.has(key):
		return _tex_cache[key]
	# read as bytes: the pictures are kept as they are in the export (their .import says "keep"),
	# so this works the same in the editor and in the game
	var img := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	var err := img.load_png_from_buffer(bytes) if path.ends_with(".png") else img.load_jpg_from_buffer(bytes)
	if err != OK or img.is_empty():
		push_warning("texture " + path + " didn't load")
		img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 0, 1))
	if mips:
		img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex_cache[key] = t
	return t


func glass(c: Color, a: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLASS
	m.set_shader_parameter("albedo", Color(c.r, c.g, c.b, a))
	return m


func _materials() -> void:
	var across := Vector3(1, 0, 0.3)
	var along := Vector3(0, 0, 1)
	M.wall = surfaced(mat(Color(1, 1, 1)), "plaster", 2.0)
	M.wall.set_shader_parameter("split_y", 1.0)
	M.wall.set_shader_parameter("albedo_tex2", tex("res://textures/panel.png"))
	M.plain = surfaced(mat(Color(0.92, 0.9, 0.86)), "plaster", 2.0)          # the back strip's walls: no wainscot
	M.tile = mat(Color("b9b8b0"), 0.35, 0.0, 1, Vector3(1, 0, 1), 6.0, 0.6)    # washrooms and the kitchen
	M.lino = mat(Color("6c6a5f"), 0.5, 0.0, 1, Vector3(1, 0, 0.2), 7.0, 0.4)
	M.steel = mat(Color("9aa0a3"), 0.35, 0.7, 2, Vector3.UP, 5.0, 1.0)
	M.ceiling = mat(Color("8e8a83"), 0.9, 0.0, 1, across)
	M.carpet = surfaced(mat(Color(1, 1, 1), 0.9, 0.0, 1, across, 7.0, 0.4), "carpet", 0.9)
	M.carpet.set_shader_parameter("wear_tex", tex("res://textures/wear.png"))
	M.carpet.set_shader_parameter("wear_rect", Vector4(0, 0, 16, 10))
	M.carpet.set_shader_parameter("worn", Color("66594b"))
	M.wood = surfaced(mat(Color(1, 1, 1), 0.7), "wood", 1.2)
	M.top = surfaced(mat(Color(1, 1, 1), 0.45, 0.0, 1, along), "top", 1.0)
	M.boards = surfaced(mat(Color(0.78, 0.76, 0.72), 0.6, 0.0, 1, Vector3(0, 0, 1), 6.0, 0.8), "wood", 1.6)
	M.dark = mat(Color("4a4843"), 0.6)
	M.black = mat(Color("1f1e22"), 0.5)
	M.frame = mat(Color("3d3a36"), 0.45, 0.35)
	M.felt = mat(Color("6f716c"), 0.9, 0.0, 1, along)
	M.paper = mat(Color("d9d4c8"), 0.9, 0.0, 3)
	M.burn = mat(Color("2c2825"), 0.9, 0.0, 3, Vector3.UP, 7.0, 0.0)
	M.person = mat(Color("b1aca3"), 0.9, 0.0, 0, Vector3.UP, 6.0)
	M.gravel = mat(Color("4a4946"), 0.34, 0.0, 1, Vector3(1, 0, 0.15), 7.0, 0.3)
	M.dirt = mat(Color("3c3530"), 0.95, 0.0, 1, Vector3(1, 0, 0.4), 7.0, 0.3)
	M.concrete = mat(Color("6d6b66"), 0.9, 0.0, 0, Vector3.UP, 7.0, 0.8)
	M.brick = mat(Color("6a4a3e"), 0.9, 0.0, 0, Vector3.UP, 5.0, 0.8)
	M.siding = mat(Color("8c8778"), 0.8, 0.0, 0, Vector3.UP, 5.0, 0.9)
	M.paint = mat(Color("80473a"), 0.8, 0.0, 0, Vector3.UP, 5.0, 0.9)
	M.puddle = mat(Color("1b1c1f"), 0.04, 0.2, 1, Vector3(1, 0, 0.15), 7.0, 0.0)
	M.road = mat(Color("333336"), 0.28, 0.0, 1, Vector3(0, 0, 1), 7.0, 0.3)
	M.water = mat(Color("111317"), 0.1, 0.2, 1, Vector3(0, 0, 1), 7.0, 0.0)
	M.seat = mat(Color("2e2d2f"), 0.8)
	M.bottle = mat(Color("7a776f"), 0.2)
	M.keg = mat(Color("a4a8aa"), 0.3, 0.8, 0, Vector3.UP, 4.0, 1.0)
	M.mirror = mat(Color("2e3033"), 0.04, 0.95)
	M.porcelain = mat(Color("dcdad2"), 0.15, 0.0, 3, Vector3.UP, 5.0, 1.0)
	M.bed = mat(Color("8a8272"), 0.9, 0.0, 1, Vector3(1, 0, 0), 6.0, 0.8)
	M.glass = glass(Color("a9bccb"), 0.12)
	M.pint = glass(Color("d8cfb5"), 0.5)
	M.drop = glass(Color("eef2f6"), 0.5)
	# the screens, the cooler and the tubes are the cold ink's green-white; the jukebox is the neon's
	M.tv = glow(Color("a9dcc8"), 1.1)
	M.juke = glow(Color("d0103a"), 0.9)
	M.lamp = glow(Color("ffdfae"), 3.0)
	M.bulb = glow(Color("ffd9a0"), 4.0)
	M.led = glow(Color("c4e2ee"), 4.0)
	M.shade = glow(Color("f0c890"), 0.9)
	# the reds are picked for after the eye's tonemapper, which turns a bright red salmon: this one
	# comes out as the neon ink itself (tests/agx_probe.gd)
	M.neon = glow(Color("cc001a"), 1.0)
	M.screen = glow(Color("d6f0e4"), 0.8)
	M.lotto = glow(Color("c8e6a0"), 1.2)
	M.cooler = glow(Color("cdeedd"), 1.2)
	M.sodium = glow(Color("ffac40"), 6.0)
	M.tail = glow(Color("cc001a"), 1.0)
	M.head = glow(Color("f4f6ff"), 9.0)
	M.far = glow(Color("ffd49a"), 7.0)
	M.tube = glow(Color("d8f5e4"), 3.5)
	M.exit = glow(Color("cc0a1a"), 1.0)
	M.window_lit = glow(Color("ffcf8a"), 1.6)


func box(size: Vector3, pos: Vector3, m: Material, rot_y := 0.0, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	(parent if parent else self).add_child(mi)
	return mi


func cyl(r_top: float, r_bot: float, h: float, pos: Vector3, m: Material, parent: Node = null, seg := 20) -> MeshInstance3D:
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


func ball(r: float, pos: Vector3, m: Material, parent: Node = null) -> MeshInstance3D:
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


# A floor, ceiling or wall cut into tiles, so every lamp near a tile reaches it: the Compatibility
# renderer lights each mesh with its nearest few lights only.
func tiled(size: Vector3, center: Vector3, m: Material, tile := 2.0, parent: Node = null) -> void:
	var nx := maxi(1, ceili(size.x / tile))
	var ny := maxi(1, ceili(size.y / tile))
	var nz := maxi(1, ceili(size.z / tile))
	var s := Vector3(size.x / nx, size.y / ny, size.z / nz)
	for i in nx:
		for j in ny:
			for k in nz:
				box(s, center - size / 2.0 + Vector3(s.x * (i + 0.5), s.y * (j + 0.5), s.z * (k + 0.5)), m, 0.0, parent)


# A wall from a to b on the floor (x, z), `h` high from `y0`, with openings: [from, to] along it and
# [bottom, top] up it. Tiled.
func wall(a: Vector2, b: Vector2, h: float, m: Material, holes: Array = [], y0 := 0.0, thick := 0.2) -> void:
	var d := b - a
	var L := d.length()
	var dir := d / L
	var along_x: bool = absf(dir.x) > absf(dir.y)
	var spans: Array = [[0.0, L, 0.0, h]]
	for hole in holes:
		var cut: Array = []
		for s in spans:
			var o0: float = hole[0]
			var o1: float = hole[1]
			if o1 <= s[0] or o0 >= s[1]:
				cut.append(s)
				continue
			if o0 > s[0]:
				cut.append([s[0], o0, s[2], s[3]])
			if o1 < s[1]:
				cut.append([o1, s[1], s[2], s[3]])
			# over and under the opening
			if hole[3] < s[3]:
				cut.append([maxf(o0, s[0]), minf(o1, s[1]), hole[3], s[3]])
			if hole[2] > s[2]:
				cut.append([maxf(o0, s[0]), minf(o1, s[1]), s[2], hole[2]])
		spans = cut
	for s in spans:
		var run: float = s[1] - s[0]
		var hh: float = s[3] - s[2]
		if run < 0.01 or hh < 0.01:
			continue
		var mid: Vector2 = a + dir * (s[0] + run / 2.0)
		var size := Vector3(run, hh, thick) if along_x else Vector3(thick, hh, run)
		tiled(size, Vector3(mid.x, y0 + s[2] + hh / 2.0, mid.y), m, 2.0)


func omni(pos: Vector3, c: Color, e: float, r: float, shadow := false, name := "") -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = c
	l.light_energy = e
	l.omni_range = r
	l.shadow_enabled = false
	add_child(l)
	if shadow:
		shadowed.append([l, pos])
	if name != "":
		lights[name] = l
	return l


func spot(pos: Vector3, target: Vector3, c: Color, e: float, r: float, angle: float, shadow := false, parent: Node = null) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.spot_range = r
	l.spot_angle = angle
	l.spot_angle_attenuation = 1.6
	l.shadow_enabled = false
	(parent if parent else self).add_child(l)
	l.global_position = pos
	var d := (target - pos).normalized()
	l.look_at(target, Vector3.UP if absf(d.y) < 0.98 else Vector3.FORWARD)
	if shadow:
		shadowed.append([l, pos])
	return l


# A door he's going through swings open ahead of him and falls to behind him.
func swing_door(which: String, open: bool, now := false) -> void:
	var list: Array = []
	match which:
		"main":
			list = [[dyn.leaf_l, -68.0 * float(dyn.leaf_l.get_meta("dir"))], [dyn.leaf_r, -64.0 * float(dyn.leaf_r.get_meta("dir"))]]
		"swing":
			list = [[dyn.swing, 75.0]]
		"deck":
			list = [[dyn.deck_door, 80.0]]
		"hotel":
			list = [[dyn.hotel_door, -86.0]]
		"wc_men", "wc_women", "wc_single":
			list = [[dyn[which], 80.0]]           # into the washroom
	for pair in list:
		var n: Node3D = pair[0]
		_still(n)
		# at once: whoever had it open isn't walking through it any more (a walk cut short)
		if now:
			n.rotation.y = deg_to_rad(pair[1]) if open else float(n.get_meta("rest", 0.0))
			continue
		var tw := n.create_tween()
		n.set_meta("swinging", tw)
		if open:
			tw.tween_property(n, "rotation:y", deg_to_rad(pair[1]), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			tw.tween_interval(0.5)
			tw.tween_property(n, "rotation:y", float(n.get_meta("rest", 0.0)), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# a door's swing stopped where it is, for the next one (or the prop) to take it from there
func _still(n: Node3D) -> void:
	if not n.has_meta("swinging"):
		return
	var tw = n.get_meta("swinging")
	if tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	n.remove_meta("swinging")


# The trapdoor behind the bar: lifted back on its hinge to go down the ladder, let down after. Now:
# at once (the page is blank).
func lift_trap(open: bool, now := false) -> void:
	var n: Node3D = dyn.get("trapdoor")
	if n == null:
		return
	var a := deg_to_rad(84.0) if open else 0.0
	if now:
		n.rotation.z = a
		return
	var tw := n.create_tween()
	tw.tween_property(n, "rotation:z", a, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)


# The doors the night props open or shuts: the deck door on its folded coaster, the kitchen's back
# door for the fryer, the hotel door on its wedge.
func prop_door(which: String, open: bool) -> void:
	var n: Node3D = dyn.get(which)
	if n == null:
		return
	var a := 0.0
	match which:
		"deck_door":
			a = deg_to_rad(9.0) if open else 0.0
			dyn.coaster.visible = open
		"kitchen_door":
			a = deg_to_rad(-72.0) if open else 0.0
		"hotel_door":
			# all the way back against the wall: the night clerk props it to see down the hall
			a = deg_to_rad(-88.0) if open else 0.0
			dyn.hotel_wedge.visible = open
	_still(n)
	n.set_meta("rest", a)
	n.rotation.y = a


# The room's light by the clock: the lamps warm at eight, paler after midnight; at last call they're
# up a little and the house lights come up white, the ones nobody's meant to see the room by, and at
# two all the way.
func set_clock(clock: int) -> void:
	if clock == int(dyn.get("clock", -1)):
		return
	dyn.clock = clock
	var up := 1.0
	var work := 0.0
	if clock >= Look.CLOSE_TIME:
		up = 1.35
		work = 1.0
	elif clock >= Look.LAST_CALL:
		up = 1.15
		work = 0.55
	# warm at eight, the lamps as built by eleven, paler from midnight on
	var early := clampf((1320.0 - clock) / 120.0, 0.0, 1.0) if clock >= 900 else 0.0
	var late := clampf(float(clock - Look.MIDNIGHT) / float(Look.LAST_CALL - Look.MIDNIGHT), 0.0, 1.0) if clock >= 900 else 1.0
	for l in lamps:
		var li := l as Light3D
		if not li.has_meta("base"):
			li.set_meta("base", li.light_energy)
			li.set_meta("tint", li.light_color)
		li.light_energy = float(li.get_meta("base")) * up
		li.light_color = (li.get_meta("tint") as Color).lerp(EARLY, 0.45 * early).lerp(LATE, 0.6 * late)
	for l in dyn.get("work", []):
		(l as Light3D).light_energy = 0.9 * work
		(l as Light3D).visible = work > 0.0


# Shadows from the lights near where he is, and none from the rest: they cost a pass each.
func shadows_near(p: Vector3, reach := 7.5) -> void:
	for pair in shadowed:
		var l: Light3D = pair[0]
		l.shadow_enabled = (pair[1] as Vector3).distance_to(p) < reach


# ---------------------------------------------------------------- the bar room

func _room() -> void:
	tiled(Vector3(16, 0.1, 10), Vector3(8, -0.05, 5), M.carpet)
	tiled(Vector3(16, 0.1, 10), Vector3(8, 3.25, 5), M.ceiling)
	for z in [2.9, 5.6, 8.3]:                                            # the old dining room's beams
		tiled(Vector3(16, 0.28, 0.24), Vector3(8, 3.06, z), M.wood, 4.0)
	# the west wall, behind the bar
	tiled(Vector3(0.2, 3.2, 10), Vector3(-0.1, 1.6, 5), M.wall)
	# the back wall: the kitchen's swing door behind the bar, and the way through to the back hall
	wall(Vector2(0, -0.1), Vector2(16, -0.1), 3.2, M.wall, [[2.8, 3.7, 0.0, 2.1], [5.9, 7.1, 0.0, 2.3]])
	# the swing door: a leaf with a porthole, on double-acting hinges
	var sw := Node3D.new()
	sw.position = Vector3(2.8, 0, -0.1)
	add_child(sw)
	box(Vector3(0.9, 2.08, 0.05), Vector3(0.45, 1.05, 0), M.dark, 0.0, sw)
	var porthole := cyl(0.14, 0.14, 0.06, Vector3(0.45, 1.55, 0.0), M.lamp, sw, 20)
	porthole.rotation.x = deg_to_rad(90)
	dyn.swing = sw
	# the east wall, with the deck door
	wall(Vector2(16.1, 0), Vector2(16.1, 10), 3.2, M.wall, [[6.5, 7.7, 0.0, 2.3]])
	var dk := Node3D.new()
	dk.position = Vector3(16.06, 0, 6.5)
	add_child(dk)
	box(Vector3(0.06, 2.28, 1.18), Vector3(0, 1.14, 0.6), M.dark, 0.0, dk)
	box(Vector3(0.07, 0.8, 0.6), Vector3(0, 1.5, 0.6), M.glass, 0.0, dk)
	box(Vector3(0.1, 0.03, 0.14), Vector3(-0.07, 1.0, 1.04), M.frame, 0.0, dk)        # the push bar
	dyn.deck_door = dk
	box(Vector3(0.3, 0.1, 1.2), Vector3(16.13, -0.05, 7.1), M.wood)                  # the sill, worn
	# the coaster folded in its latch
	dyn.coaster = box(Vector3(0.012, 0.05, 0.03), Vector3(16.02, 1.02, 7.66), M.paper)
	# the front wall: the main door at x 2.3..4.1, the front window at x 6.2..12.6
	tiled(Vector3(2.3, 3.2, 0.2), Vector3(1.15, 1.6, ZF), M.wall)
	box(Vector3(1.8, 0.9, 0.2), Vector3(3.2, 2.75, ZF), M.wall)
	tiled(Vector3(2.1, 3.2, 0.2), Vector3(5.15, 1.6, ZF), M.wall)
	tiled(Vector3(6.4, 0.9, 0.2), Vector3(9.4, 0.45, ZF), M.wall)
	tiled(Vector3(6.4, 0.8, 0.2), Vector3(9.4, 2.8, ZF), M.wall)
	tiled(Vector3(3.4, 3.2, 0.2), Vector3(14.3, 1.6, ZF), M.wall)
	box(Vector3(6.4, 1.5, 0.03), Vector3(9.4, 1.65, ZF), M.glass)
	for x in [6.2, 7.8, 9.4, 11.0, 12.6]:
		box(Vector3(0.07, 1.5, 0.14), Vector3(x, 1.65, ZF), M.frame)
	box(Vector3(6.5, 0.07, 0.3), Vector3(9.4, 0.93, ZF - 0.05), M.wood)
	# the exit sign over the deck door
	box(Vector3(0.05, 0.14, 0.34), Vector3(16.0, 2.45, 7.1), M.exit)
	anchors["deck_door"] = Vector3(16.0, 1.2, 7.1)
	anchors["hall_way"] = Vector3(6.5, 1.3, -0.1)
	anchors["swing_door"] = Vector3(3.25, 1.3, -0.1)


func _vestibule() -> void:
	# the door frame and its two glass leaves; they open out to the lot
	model("res://models/door_frame.glb", Vector3((DOOR_W + DOOR_E) / 2.0, 0, ZF))
	dyn.leaf_l = _leaf(DOOR_W + 0.04, 1.0)
	dyn.leaf_r = _leaf(DOOR_E - 0.04, -1.0)
	# the screen between the vestibule and the room: panelled to the waist, glass above
	box(Vector3(0.1, 1.05, 1.2), Vector3(4.55, 0.525, 9.5), M.wood)
	box(Vector3(0.14, 0.06, 1.24), Vector3(4.55, 1.08, 9.5), M.frame)
	box(Vector3(0.14, 0.08, 1.24), Vector3(4.55, 2.24, 9.5), M.frame)
	box(Vector3(0.12, 2.28, 0.08), Vector3(4.55, 1.14, 8.92), M.frame)
	box(Vector3(0.02, 1.1, 1.1), Vector3(4.55, 1.66, 9.5), M.glass)
	var sign := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(0.21, 0.28)
	sign.mesh = sq
	sign.position = Vector3(4.535, 1.6, 9.72)
	sign.rotation.y = deg_to_rad(-90)
	var sm := mat(Color(1, 1, 1), 0.5, 0.0, 3)
	sm.set_shader_parameter("albedo_tex", tex("res://textures/sign_id.png"))
	sign.material_override = sm
	add_child(sign)
	# the ledge along the front wall, by his right hand: the scanner, the incident book, and the old
	# cigarette burns
	box(Vector3(1.85, 1.0, 0.45), Vector3(1.275, 0.5, 9.78), M.wood)
	box(Vector3(1.95, 0.05, 0.55), Vector3(1.275, 1.025, 9.75), M.top)
	for i in 11:
		# burnt into it, not lying on it: a die that comes down on one covers it
		var b := cyl(0.012, 0.012, 0.0004, Vector3(rng.randf_range(0.4, 2.15), 1.0502, rng.randf_range(9.55, 9.96)), M.burn, null, 8)
		b.scale = Vector3(rng.randf_range(1.0, 2.6), 1, 1)
	# masking tape on the wall beside the door, with the night's sum on it in marker: born on this
	# date or before, you're nineteen tonight
	var tape := MeshInstance3D.new()
	var tq := QuadMesh.new()
	tq.size = Vector2(0.15, 0.042)
	tape.mesh = tq
	tape.position = Vector3(2.157, 1.4, 9.996)
	tape.rotation = Vector3(0, deg_to_rad(180), deg_to_rad(-2.5))
	var tm := mat(Color(1, 1, 1), 0.8, 0.0, 3, Vector3.UP, 7.0, 0.3)
	tm.set_shader_parameter("albedo_tex", tex("res://textures/tape_date.png"))
	tm.set_shader_parameter("alpha_scissor", 0.5)
	tape.material_override = tm
	add_child(tape)
	var things := model("res://models/ledge_props.glb")
	var spots := {"scanner": [Vector3(1.92, 1.05, 9.72), 184.0],
		"book": [Vector3(1.05, 1.05, 9.74), 172.0], "lighter": [Vector3(0.72, 1.05, 9.82), 140.0],
		"mug": [Vector3(0.48, 1.05, 9.7), 190.0]}
	for c in things.get_children():
		# the model has a tally counter on the ledge too; the door here doesn't count
		if String(c.name) == "clicker":
			(c as Node3D).visible = false
		if spots.has(String(c.name)):
			var sp: Array = spots[String(c.name)]
			c.position = sp[0]
			c.rotation = Vector3(0, deg_to_rad(sp[1]), 0)
			dyn["ledge_" + String(c.name)] = c
	# his stool, and the mat inside the door
	stool(Vector3(EYE_DOOR.x, 0, EYE_DOOR.z), 0.78)
	box(Vector3(1.8, 0.012, 1.0), Vector3((DOOR_W + DOOR_E) / 2.0, 0.006, 9.45), M.dark)
	anchors["tape"] = Vector3(2.157, 1.4, 9.99)
	anchors["id_sign"] = Vector3(4.52, 1.6, 9.72)
	anchors["ledge"] = Vector3(1.3, 1.06, 9.72)
	anchors["main_door"] = Vector3(3.2, 1.2, 10.1)
	anchors["scanner"] = Vector3(1.92, 1.1, 9.72)


func _leaf(hinge_x: float, dir: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(hinge_x, 0, 10.12)
	add_child(pivot)
	var w := 0.86
	model("res://models/door_leaf_" + ("left" if dir > 0.0 else "right") + ".glb", Vector3.ZERO, pivot)
	var letters := MeshInstance3D.new()
	var lq := QuadMesh.new()
	lq.size = Vector2(w - 0.1, (w - 0.1) * 2.0)
	letters.mesh = lq
	letters.position = Vector3(dir * w / 2.0, 1.35, 0.012)
	var lm := glass(Color(1, 1, 1), 1.0)
	lm.set_shader_parameter("albedo_tex", tex("res://textures/door_glass_" + ("left" if dir > 0.0 else "right") + ".png"))
	lm.set_shader_parameter("roughness", 0.35)
	lm.set_shader_parameter("metallic", 0.0)
	letters.material_override = lm
	letters.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(letters)
	for i in 34:
		box(Vector3(0.005, rng.randf_range(0.012, 0.07), 0.003), Vector3(dir * rng.randf_range(0.1, w - 0.1), rng.randf_range(0.3, 2.05), 0.016), M.drop, 0.0, pivot)
	pivot.set_meta("dir", dir)
	return pivot


func _bar() -> void:
	# the bar runs along the west wall, from near the back to near the door
	tiled(Vector3(0.6, 1.06, 6.7), Vector3(1.9, 0.53, 4.35), M.wood)
	tiled(Vector3(0.8, 0.06, 6.8), Vector3(1.95, 1.09, 4.35), M.top)
	box(Vector3(0.05, 0.05, 6.7), Vector3(2.34, 0.22, 4.35), M.frame)
	# the beer tower: a steel bar on two legs, six faucets on the bartender's side, their handles
	# in the brewers' colours facing the room, and a drip tray under them
	var tz0 := 1.9
	var tlen := 1.3
	var tmid := tz0 + tlen / 2.0
	for tz in [tz0 + 0.1, tz0 + tlen - 0.1]:
		cyl(0.024, 0.03, 0.24, Vector3(1.72, 1.24, tz), M.steel, null, 12)
	box(Vector3(0.07, 0.07, tlen), Vector3(1.72, 1.39, tmid), M.steel)
	box(Vector3(0.16, 0.02, tlen + 0.06), Vector3(1.62, 1.13, tmid), M.black)
	var inks := ["d8cfb5", "a8382b", "2e3b4c", "d99a3c", "506142", "1f1e22"]
	for i in 6:
		var z := tz0 + 0.18 + i * (tlen - 0.36) / 5.0
		box(Vector3(0.1, 0.03, 0.03), Vector3(1.66, 1.38, z), M.steel)
		cyl(0.008, 0.008, 0.06, Vector3(1.62, 1.34, z), M.steel, null, 8)
		var hm := mat(Color(inks[i]), 0.5)
		if i % 3 == 1:
			box(Vector3(0.018, 0.2, 0.06), Vector3(1.68, 1.53, z), hm)
		else:
			cyl(0.013, 0.019, 0.19 + 0.03 * (i % 2), Vector3(1.68, 1.52, z), hm, null, 10)
	box(Vector3(0.36, 0.26, 0.32), Vector3(1.75, 1.25, 7.3), M.dark)          # the till, at the door end
	var lot := box(Vector3(0.5, 0.34, 0.05), Vector3(2.0, 1.36, 6.7), M.dark, 90.0)
	screen_quad(Vector2(0.44, 0.28), Vector3(0, 0, 0.03), "lotto", 1.2, 0.0, lot)
	tiled(Vector3(0.5, 0.95, 6.2), Vector3(0.25, 0.475, 4.3), M.wood)
	box(Vector3(0.04, 1.35, 4.4), Vector3(0.03, 1.82, 4.4), M.mirror)
	for y in [1.28, 1.66, 2.04]:
		box(Vector3(0.3, 0.03, 4.4), Vector3(0.17, y, 4.4), M.wood)
		# not a library: bottles with shoulders and necks, a few squat ones, the odd gap where
		# something's been poured out and not put back
		var z := 2.3
		while z < 6.5:
			if rng.randf() < 0.08:
				z += rng.randf_range(0.12, 0.3)
				continue
			var squat := rng.randf() < 0.2
			var h := rng.randf_range(0.13, 0.17) if squat else rng.randf_range(0.17, 0.23)
			var r := rng.randf_range(0.038, 0.048) if squat else rng.randf_range(0.027, 0.036)
			var bx := rng.randf_range(0.12, 0.2)
			cyl(r, r, h, Vector3(bx, y + 0.015 + h / 2.0, z), M.bottle, null, 10)
			var nh := rng.randf_range(0.05, 0.07) if squat else rng.randf_range(0.07, 0.11)
			cyl(0.011, r * 0.8, nh, Vector3(bx, y + 0.015 + h + nh / 2.0, z), M.bottle, null, 8)
			z += r * 2.0 + rng.randf_range(0.012, 0.05)
	box(Vector3(0.4, 0.05, 4.6), Vector3(0.4, 2.75, 4.4), M.dark)
	box(Vector3(0.3, 0.01, 4.4), Vector3(0.4, 2.72, 4.4), M.lamp)
	box(Vector3(0.62, 2.1, 1.0), Vector3(0.31, 1.05, 0.7), M.dark)
	box(Vector3(0.02, 1.84, 0.86), Vector3(0.63, 1.1, 0.7), M.cooler)
	for sy in [0.55, 0.95, 1.35, 1.75]:
		box(Vector3(0.02, 0.02, 0.86), Vector3(0.645, sy, 0.7), M.frame)
	# the trapdoor to the keg room behind the bar, at the far end: a hole with a hinged lid
	var trap := Node3D.new()
	trap.position = Vector3(0.6, 0.0, 1.4)
	add_child(trap)
	box(Vector3(0.9, 0.04, 1.0), Vector3(0.45, 0.02, 0.5), M.dark, 0.0, trap)
	box(Vector3(0.05, 0.02, 0.2), Vector3(0.75, 0.05, 0.5), M.frame, 0.0, trap)    # the ring pull
	dyn.trapdoor = trap
	# the stools along the bar, but for one gap across from the bartender, where people come to order
	# and staff stand (he does, at the bar): two steel rails on the bar top either side of it, to
	# keep it clear
	var z2 := 1.6
	while z2 < 7.4:
		if absf(z2 - SERVICE_Z) > 0.1:
			stool(Vector3(2.65, 0, z2), 0.76)
		else:
			rng.randf()        # the turn the stool would have had, so the rest of the room's as it was
		z2 += 0.85
	for rz in [SERVICE_Z - 0.44, SERVICE_Z + 0.44]:
		box(Vector3(0.66, 0.026, 0.022), Vector3(1.95, 1.133, rz), M.steel)
	# the binder and the incident book under the till
	box(Vector3(0.28, 0.06, 0.34), Vector3(1.55, 0.92, 7.3), M.black)
	# where he looks for things, from the room: the till's face (the lotto screen's beside it), the
	# bar top's edge (its middle's behind the till from the door), and the air over the trapdoor (the
	# trapdoor's behind the bar, under the taps, and nobody sees it from out here)
	anchors["till"] = Vector3(1.93, 1.27, 7.3)
	anchors["bar_top"] = Vector3(2.25, 1.13, 5.8)
	anchors["cooler"] = Vector3(0.63, 1.2, 0.7)
	anchors["trapdoor"] = Vector3(1.05, 0.1, 1.9)
	anchors["trap_over"] = Vector3(1.05, 1.75, 1.9)
	anchors["lotto"] = Vector3(2.04, 1.36, 6.7)
	anchors["taps"] = Vector3(1.68, 1.5, 2.55)
	anchors["bottles"] = Vector3(0.2, 1.7, 4.4)


func stool(at: Vector3, seat := 0.64) -> Node3D:
	var s := model("res://models/stool_" + ("bar" if seat >= 0.7 else "low") + ".glb", at)
	s.rotation.y = rng.randf_range(0.0, TAU)
	return s


func table(at: Vector3, round := false) -> Node3D:
	return model("res://models/table_" + ("round" if round else "square") + ".glb", at)


func sconce(at: Vector3, rot_y: float) -> void:
	var n := Node3D.new()
	n.position = at
	n.rotation.y = deg_to_rad(rot_y)
	add_child(n)
	box(Vector3(0.09, 0.14, 0.03), Vector3(0, -0.04, 0.015), M.frame, 0.0, n)
	box(Vector3(0.02, 0.02, 0.14), Vector3(0, -0.04, 0.09), M.frame, 0.0, n)
	cyl(0.05, 0.075, 0.12, Vector3(0, 0.02, 0.16), M.shade, n, 14)
	ball(0.028, Vector3(0, -0.03, 0.16), M.bulb, n)
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
		lamps.append(sp)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 0.0, 0.3)
	l.light_color = Color("ffc98a")
	l.light_energy = 0.18
	l.omni_range = 2.0
	n.add_child(l)


func pint(at: Vector3, parent: Node = null) -> MeshInstance3D:
	return cyl(0.042, 0.034, 0.15, at + Vector3(0, 0.075, 0), M.pint, parent, 12)


func pendant(p: Vector3, drop := 2.35) -> void:
	cyl(0.005, 0.005, 3.2 - drop - 0.1, Vector3(p.x, (3.2 + drop + 0.1) / 2.0, p.z), M.frame, null, 6)
	var lamp := model("res://models/pendant.glb", Vector3(p.x, drop + 0.1, p.z))
	lamp.rotation.y = rng.randf_range(0.0, TAU)


func _floor_things() -> void:
	# the pool table, a coin-op, with its lamp; the balls where the big man's buddy left them
	model("res://models/pool_table.glb", POOL)
	var balls := [[Vector2(-0.62, -0.28), "e8e4d8"], [Vector2(-0.45, 0.06), "b8342a"], [Vector2(0.58, -0.38), "d9a52e"],
		[Vector2(0.21, 0.3), "2a3a78"], [Vector2(-0.88, 0.16), "d86a2a"], [Vector2(0.77, 0.24), "6a2430"], [Vector2(0.05, -0.12), "141414"]]
	for b in balls:
		ball(0.0286, POOL + Vector3(b[0].x, 0.8286, b[0].y), mat(Color(b[1]), 0.2, 0.0, 3, Vector3.UP, 5.0, 0.3))
	model("res://models/pool_light.glb", POOL + Vector3(0, 2.06, 0))
	box(Vector3(0.015, 1.2, 0.015), POOL + Vector3(-0.7, 2.65, 0), M.frame)
	box(Vector3(0.015, 1.2, 0.015), POOL + Vector3(0.7, 2.65, 0), M.frame)
	# a cue on the rack by the back wall, and the chalk
	var rack := box(Vector3(0.6, 0.9, 0.04), Vector3(11.6, 1.4, 0.03), M.wood)
	for i in 4:
		var cue := cyl(0.006, 0.012, 1.45, Vector3(11.4 + i * 0.13, 0.78, 0.07), M.wood, null, 8)
		cue.rotation.z = deg_to_rad(rng.randf_range(-3, 3))
	# table 28, the big round one in the front window, with its glasses and six stools
	table(T28, true)
	var glasses := Node3D.new()
	add_child(glasses)
	dyn.t28_glasses = glasses
	for k in 6:
		var a2 := TAU * k / 6.0 + 0.25
		stool(T28 + Vector3(cos(a2) * 1.18, 0, sin(a2) * 1.18))
	pendant(T28)
	# the other tables
	for t in TABLES:
		table(t)
		for s in [Vector3(0.62, 0, 0), Vector3(-0.62, 0, 0), Vector3(0, 0, 0.62)]:
			stool(t + s)
		pendant(t)
	for z in [2.4, 4.4, 6.4]:
		pendant(Vector3(1.95, 0, z), 2.3)
	# the jukebox on the back wall, a screen that takes a card and plays anything
	var juke := model("res://models/jukebox.glb", Vector3(13.2, 0.95, 0.0))
	juke.rotation.y = PI
	var jq := screen_quad(Vector2(0.43, 0.31), Vector3(0, 0.7205, -0.268), "jukebox", 1.0, 180.0, juke)
	jq.rotation.x = deg_to_rad(-4.3)
	# a TV on the back wall that table 28 watches, on the hockey, and one on the east wall on the news
	for tv in [[Vector3(9.4, 2.45, 0.0), 180.0, "tv_hockey"], [Vector3(16.0, 2.35, 4.0), 90.0, "tv_news"]]:
		var set := model("res://models/tv.glb", tv[0])
		set.rotation.y = deg_to_rad(tv[1])
		screen_quad(Vector2(1.21, 0.69), Vector3(0, 0.0025, -0.107), tv[2], 1.1, 180.0, set)
	# the dartboard on the east wall, and the oche on the carpet at 2.37 m
	var board := model("res://models/dartboard.glb", Vector3(16.0, 1.73, 2.3))
	board.rotation.y = PI / 2.0
	box(Vector3(0.04, 0.008, 0.6), Vector3(16.0 - 2.37, 0.004, 2.3), M.frame)
	anchors["pool_table"] = POOL + Vector3(0, 0.85, 0)
	anchors["t28"] = T28 + Vector3(0, 0.8, 0)
	anchors["jukebox"] = Vector3(13.2, 1.5, 0.25)
	anchors["tv"] = Vector3(9.4, 2.45, 0.1)
	anchors["tv_news"] = Vector3(15.9, 2.35, 4.0)
	anchors["dartboard"] = Vector3(15.9, 1.73, 2.3)
	anchors["cue_rack"] = Vector3(11.6, 1.4, 0.06)
	anchors["t28_under"] = T28 + Vector3(0.3, 0.1, 0.9)
	anchors["t28_wall"] = Vector3(9.4, 0.7, 9.95)        # under the sill: seen over the table from its stools


# Table 28's glasses: each of the five with theirs in front of them, near the edge where they can
# reach it (world/life.gd: they lean in for a sip), at the stools they sit at (world/stage.gd, t28_0
# to t28_5 but the fourth), left there if they're out on the deck or gone; and in the middle the
# empties of a round's worth for each round they've ordered since the last clear, up to what the
# table holds.
func set_t28_glasses(rounds: int, cleared: bool) -> void:
	var g: Node3D = dyn.t28_glasses
	for c in g.get_children():
		c.queue_free()
	if cleared:
		return
	var r := RandomNumberGenerator.new()
	r.seed = 2828
	for k in [0, 1, 2, 3, 5]:
		var a := TAU * float(k) / 6.0 + 0.25 - r.randf_range(-0.02, 0.06)
		var at := r.randf_range(0.79, 0.81)
		pint(T28 + Vector3(cos(a) * at, 0.785, sin(a) * at), g)
	for i in clampi(rounds * 2, 0, 17):
		var a := TAU * i / 11.0 + r.randf() * 0.3
		pint(T28 + Vector3(cos(a) * r.randf_range(0.15, 0.55), 0.785, sin(a) * r.randf_range(0.15, 0.55)), g)


# ---------------------------------------------------------------- behind the back wall

func _back_strip() -> void:
	var y := 2.6          # the back strip's ceiling is lower
	# floors and ceilings
	tiled(Vector3(4.8, 0.1, 2.64), Vector3(2.4, -0.05, BACK / 2.0), M.tile)
	tiled(Vector3(11.2, 0.1, 2.64), Vector3(10.4, -0.05, BACK / 2.0), M.lino)
	tiled(Vector3(16, 0.1, 2.64), Vector3(8, y + 0.05, BACK / 2.0), M.ceiling)
	# the back wall of the building, with the kitchen's back door (propped for the fryer)
	wall(Vector2(0, BACK - 0.1), Vector2(16, BACK - 0.1), y, M.plain)
	wall(Vector2(-0.1, BACK), Vector2(-0.1, 0), y, M.plain, [[0.66, 1.54, 0.0, 2.05]])
	# the kitchen's side of things: the wall between it and the hall
	wall(Vector2(4.8, BACK), Vector2(4.8, 0), y, M.plain)
	# the washrooms: three fronts on the hall, each with its door
	for w in [[6.4, 8.64, 7.1, 7.84, "men"], [8.64, 10.88, 9.34, 10.08, "women"], [10.88, 13.12, 11.58, 12.3, "single"]]:
		wall(Vector2(w[0], HALL_Z), Vector2(w[1], HALL_Z), y, M.plain, [[w[2] - w[0], w[3] - w[0], 0.0, 2.05]], 0.0, 0.1)
		var door := Node3D.new()
		door.position = Vector3(w[2], 0, HALL_Z)
		add_child(door)
		box(Vector3(w[3] - w[2] - 0.02, 2.02, 0.04), Vector3((w[3] - w[2]) / 2.0, 1.01, 0), M.dark, 0.0, door)
		box(Vector3(0.12, 0.05, 0.05), Vector3((w[3] - w[2]) - 0.12, 1.02, 0.04), M.frame, 0.0, door)
		# the little window in the handle: VACANT or OCCUPIED, and a sign on each door
		box(Vector3(0.16, 0.16, 0.01), Vector3((w[3] - w[2]) / 2.0, 1.55, 0.025), M.paper, 0.0, door)
		dyn["wc_" + w[4]] = door
		anchors["wc_" + w[4]] = Vector3((w[2] + w[3]) / 2.0, 1.3, HALL_Z)
		# inside: tile, a sink and a mirror; a stall or a urinal
		tiled(Vector3(w[1] - w[0], 0.1, BACK * -1.0 - 1.21), Vector3((w[0] + w[1]) / 2.0, 0.0, (BACK + HALL_Z) / 2.0), M.tile)
		cyl(0.2, 0.16, 0.14, Vector3(w[0] + 0.35, 0.82, BACK + 0.3), M.porcelain, null, 14)
		box(Vector3(0.5, 0.6, 0.02), Vector3(w[0] + 0.35, 1.55, BACK + 0.02), M.mirror)
		box(Vector3(0.06, 0.06, 0.06), Vector3(w[0] + 0.35, 2.4, (BACK + HALL_Z) / 2.0), M.tube)
	for x in [6.4, 8.64, 10.88, 13.12]:
		wall(Vector2(x, BACK), Vector2(x, HALL_Z), y, M.tile, [], 0.0, 0.1)
	# the payphone, dead, and forty years of numbers round it: a steel box with the card that says
	# how to use it behind its scratched window, the coin slot, twelve keys, the coin return; the
	# handset on its hook down the left side, on a steel cord into the bottom of the box
	var pz := BACK + 0.14                                                              # its face
	box(Vector3(0.24, 0.42, 0.14), Vector3(13.86, 1.45, BACK + 0.07), M.steel)
	box(Vector3(0.15, 0.065, 0.003), Vector3(13.85, 1.6, pz + 0.0015), M.paper)          # the card
	for k in 4:
		var lw: float = [0.11, 0.09, 0.115, 0.06][k]
		box(Vector3(lw, 0.004, 0.001), Vector3(13.787 + lw / 2.0, 1.618 - k * 0.012, pz + 0.0035), M.dark)
	box(Vector3(0.008, 0.032, 0.004), Vector3(13.955, 1.6, pz + 0.002), M.black)        # the slot
	box(Vector3(0.11, 0.125, 0.004), Vector3(13.86, 1.435, pz + 0.002), M.black)
	for row in 4:
		for col in 3:
			box(Vector3(0.026, 0.02, 0.008), Vector3(13.826 + col * 0.034, 1.475 - row * 0.027, pz + 0.006), M.porcelain)
	box(Vector3(0.055, 0.04, 0.03), Vector3(13.92, 1.285, pz + 0.015), M.steel)         # the coin return
	box(Vector3(0.042, 0.022, 0.004), Vector3(13.92, 1.28, pz + 0.031), M.black)
	box(Vector3(0.02, 0.035, 0.05), Vector3(13.735, 1.655, pz - 0.02), M.steel)         # the hook
	box(Vector3(0.04, 0.16, 0.045), Vector3(13.712, 1.5, pz + 0.025), M.black)          # the handset
	box(Vector3(0.056, 0.05, 0.062), Vector3(13.712, 1.6, pz + 0.03), M.black)
	box(Vector3(0.056, 0.05, 0.062), Vector3(13.712, 1.4, pz + 0.03), M.black)
	cyl(0.006, 0.006, 0.14, Vector3(13.712, 1.305, pz + 0.025), M.steel, null, 8)       # the cord
	var cord := cyl(0.006, 0.006, 0.07, Vector3(13.745, 1.235, pz + 0.025), M.steel, null, 8)
	cord.rotation.z = PI / 2.0
	# the ink on the wall round it (sketches/door-look/tools/textures.py phone_wall), only the ink:
	# the plaster shows between
	var ink := MeshInstance3D.new()
	var iq := QuadMesh.new()
	iq.size = Vector2(1.2, 1.0)
	ink.mesh = iq
	ink.position = Vector3(13.86, 1.5, BACK + 0.003)
	var im := mat(Color(1, 1, 1), 0.9, 0.0, 3, Vector3.UP, 7.0, 0.0)
	im.set_shader_parameter("albedo_tex", tex("res://textures/phone_wall.png"))
	im.set_shader_parameter("alpha_scissor", 0.5)
	ink.material_override = im
	add_child(ink)
	# the hotel door at the end of the hall: to the front desk and the stairs up
	wall(Vector2(16.1, BACK), Vector2(16.1, 0), y, M.plain, [[1.6, 2.48, 0.0, 2.05]])
	var hd := Node3D.new()
	hd.position = Vector3(16.08, 0, BACK + 1.6)
	add_child(hd)
	box(Vector3(0.05, 2.02, 0.86), Vector3(0, 1.01, 0.43), M.wood, 0.0, hd)
	box(Vector3(0.03, 0.4, 0.3), Vector3(-0.02, 1.5, 0.43), M.glass, 0.0, hd)
	dyn.hotel_door = hd
	dyn.hotel_wedge = box(Vector3(0.12, 0.03, 0.06), Vector3(15.17, 0.015, BACK + 1.66), M.wood, deg_to_rad(90.0))
	# the hall's light: two tubes
	for x in [9.0, 14.5]:
		box(Vector3(1.2, 0.04, 0.08), Vector3(x, y - 0.03, -0.6), M.tube)
	# the kitchen: the fryer, the steel counter, the pass, the walk-in's door
	box(Vector3(0.7, 0.9, 0.7), Vector3(0.45, 0.45, BACK + 0.45), M.steel)          # the fryer
	box(Vector3(0.62, 0.05, 0.62), Vector3(0.45, 0.93, BACK + 0.45), M.black)
	box(Vector3(1.8, 0.9, 0.62), Vector3(2.0, 0.45, BACK + 0.4), M.steel)           # the counter
	box(Vector3(1.8, 0.04, 0.66), Vector3(2.0, 0.92, BACK + 0.4), M.steel)
	box(Vector3(1.0, 0.7, 0.5), Vector3(0.9, 2.1, BACK + 0.3), M.steel)             # the hood
	box(Vector3(0.9, 2.0, 0.06), Vector3(4.0, 1.0, BACK + 0.04), M.steel)           # the walk-in
	box(Vector3(0.5, 0.9, 0.5), Vector3(4.3, 0.45, -0.5), M.steel)                  # the dish pit
	box(Vector3(0.06, 0.06, 1.4), Vector3(2.4, y - 0.05, -1.3), M.tube)
	# the fryer's baskets hung up to drain over the oil, its splash-back; the flat-top on the
	# counter, scraped; shelves over it, the plates and the pots and the cook's radio; the pass
	# under its heat lamp with tonight's tickets on the rail; a mop bucket by the back door
	box(Vector3(0.7, 0.55, 0.04), Vector3(0.45, 1.2, BACK + 0.12), M.steel)
	for bx in [0.29, 0.61]:
		box(Vector3(0.24, 0.12, 0.3), Vector3(bx, 1.08, BACK + 0.36), M.frame)
		box(Vector3(0.03, 0.03, 0.3), Vector3(bx, 1.16, BACK + 0.66), M.black)
	box(Vector3(0.7, 0.03, 0.55), Vector3(1.45, 0.955, BACK + 0.4), M.black)
	box(Vector3(0.7, 0.08, 0.03), Vector3(1.45, 1.0, BACK + 0.12), M.steel)
	for sy in [1.55, 1.95]:
		box(Vector3(1.8, 0.03, 0.32), Vector3(2.0, sy, BACK + 0.18), M.steel)
	for k in 3:
		cyl(0.12, 0.12, 0.012 * 9, Vector3(2.5 + k * 0.1, 1.57 + 0.054, BACK + 0.2), M.porcelain, null, 16)
	cyl(0.16, 0.15, 0.22, Vector3(1.55, 1.97 + 0.11, BACK + 0.19), M.steel, null, 14)
	cyl(0.12, 0.12, 0.16, Vector3(1.9, 1.97 + 0.08, BACK + 0.19), M.steel, null, 14)
	box(Vector3(0.3, 0.17, 0.12), Vector3(2.55, 2.055, BACK + 0.14), M.dark)          # the radio
	for k in 4:
		cyl(0.028, 0.03, 0.2, Vector3(1.25 + k * 0.08, 1.57 + 0.1, BACK + 0.12), M.bottle, null, 8)
	var heat := glow(Color("ffa050"), 0.9)
	box(Vector3(0.9, 0.05, 0.22), Vector3(2.45, 1.4, BACK + 0.6), M.steel)
	box(Vector3(0.8, 0.02, 0.14), Vector3(2.45, 1.375, BACK + 0.6), heat)
	omni(Vector3(2.45, 1.2, BACK + 0.6), Color("ffa050"), 0.8, 1.4, false, "heat_lamp")
	box(Vector3(0.9, 0.02, 0.02), Vector3(2.45, 1.52, BACK + 0.72), M.steel)          # the ticket rail
	for k in 4:
		box(Vector3(0.08, 0.13, 0.004), Vector3(2.1 + k * 0.2 + rng.randf_range(-0.03, 0.03), 1.45, BACK + 0.73), M.paper)
	cyl(0.17, 0.14, 0.3, Vector3(0.35, 0.15, -0.5), mat(Color("a58a3a"), 0.6), null, 14)   # the bucket
	var mop := cyl(0.012, 0.012, 1.4, Vector3(0.4, 0.75, -0.45), M.wood, null, 6)
	mop.rotation = Vector3(deg_to_rad(8.0), 0.0, deg_to_rad(-10.0))
	for k in 3:
		box(Vector3(0.4, 0.3, 0.55), Vector3(4.47 + rng.randf_range(-0.03, 0.03), 0.15 + k * 0.3, -1.5), M.dark)   # crates by the walk-in
	var kd := Node3D.new()
	kd.position = Vector3(-0.1, 0, BACK + 0.66)
	add_child(kd)
	box(Vector3(0.05, 2.02, 0.86), Vector3(0, 1.01, 0.43), M.steel, 0.0, kd)
	dyn.kitchen_door = kd
	anchors["fryer"] = Vector3(0.45, 1.0, BACK + 0.45)
	anchors["pass"] = Vector3(2.45, 1.25, BACK + 0.6)
	anchors["radio"] = Vector3(2.55, 2.06, BACK + 0.15)
	anchors["walk_in"] = Vector3(4.0, 1.2, BACK + 0.1)
	anchors["kitchen_back"] = Vector3(-0.1, 1.2, BACK + 1.1)
	anchors["payphone"] = Vector3(13.86, 1.5, BACK + 0.1)
	anchors["hotel_door"] = Vector3(16.05, 1.2, BACK + 2.04)
	anchors["hall_end"] = Vector3(15.0, 1.3, -0.6)


# ---------------------------------------------------------------- the front desk, through the hotel door

# Through the hotel door at the end of the back hall: the hotel's front desk, a counter with a bell
# on it and a key board with most of the keys still on their hooks, the night clerk's stool behind
# it (Terry sits on it: world/stage.gd), his lamp, and the stairs up. He props the door so he can
# watch the bar's TV down the hall, so it's all in line with the doorway: from the far end of the
# hall, a warm room the size of a stamp at the end of the cold one. Built last, with its own dice,
# so nothing else in the building moves.
func _lobby() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1958
	var y := 2.6
	var x0 := 16.0
	var x1 := 19.5
	var z1 := 0.6
	var carpet := surfaced(mat(Color(0.74, 0.7, 0.66), 0.9, 0.0, 1, Vector3(1, 0, 0.3), 7.0, 0.4), "carpet", 0.7)
	var brass := mat(Color("8a7444"), 0.4, 0.6, 2, Vector3.UP, 5.0, 1.0)
	tiled(Vector3(x1 - x0, 0.1, z1 - BACK), Vector3((x0 + x1) / 2.0, -0.05, (BACK + z1) / 2.0), carpet)
	# the walls: the building's back wall carried on, the east wall, the south wall with the hotel's
	# own front door in it, shut for the night
	wall(Vector2(x0, BACK - 0.1), Vector2(x1 + 0.2, BACK - 0.1), y, M.plain)
	wall(Vector2(x1 + 0.1, BACK), Vector2(x1 + 0.1, z1 + 0.2), y, M.plain)
	wall(Vector2(x0, z1 + 0.1), Vector2(x1 + 0.2, z1 + 0.1), y, M.plain, [[2.45, 3.3, 0.0, 2.1]])
	box(Vector3(0.85, 2.08, 0.05), Vector3(x0 + 2.875, 1.04, z1 + 0.1), M.wood)
	box(Vector3(0.36, 0.5, 0.02), Vector3(x0 + 2.875, 1.5, z1 + 0.07), M.glass)
	# outside: siding over the lobby's two outer walls and the bar's east wall up to the deck
	wall(Vector2(x0 + 0.2, z1 + 0.22), Vector2(x1 + 0.22, z1 + 0.22), 3.4, M.siding, [], 0.0, 0.04)
	wall(Vector2(x1 + 0.22, BACK - 0.2), Vector2(x1 + 0.22, z1 + 0.24), 3.4, M.siding, [], 0.0, 0.04)
	wall(Vector2(16.25, z1 + 0.24), Vector2(16.25, 3.6), 3.4, M.siding, [], 0.0, 0.05)
	# the stairs up, along the back wall from beside the hotel door into the dark, carpet runner up
	# the middle; a ceiling over the rest, open over the stairs
	var sz0 := BACK
	var sz1 := BACK + 0.9
	var run := 0.25
	var rise := 0.2
	for k in 13:
		var sx := 16.25 + run * k
		box(Vector3(run, rise * (k + 1), sz1 - sz0), Vector3(sx + run / 2.0, rise * (k + 1) / 2.0, (sz0 + sz1) / 2.0), M.wood)
		box(Vector3(run + 0.01, 0.012, 0.56), Vector3(sx + run / 2.0, rise * (k + 1) + 0.006, (sz0 + sz1) / 2.0), carpet)
	# the handrail, a metre over the nosings, on its balusters, from the newel post up
	var rail_a := Vector3(16.25, rise + 1.02, sz1 - 0.03)
	var rail_b := Vector3(16.25 + run * 12.0, rise * 13.0 + 1.02, sz1 - 0.03)
	var rail := box(Vector3(0.05, 0.05, rail_a.distance_to(rail_b)), (rail_a + rail_b) / 2.0, M.frame)
	rail.basis = Basis.looking_at(rail_b - rail_a, Vector3.UP)
	for k in 13:
		var bx := 16.25 + run * k + run / 2.0
		box(Vector3(0.025, 1.02, 0.025), Vector3(bx, rise * (k + 1) + 0.51, sz1 - 0.03), M.frame)
	box(Vector3(0.09, 1.25, 0.09), Vector3(16.3, 0.625, sz1 - 0.03), M.wood)
	tiled(Vector3(x1 - x0 + 0.2, 0.1, z1 - sz1 + 0.2), Vector3((x0 + x1 + 0.2) / 2.0, y + 0.05, (sz1 + z1 + 0.2) / 2.0), M.ceiling)
	tiled(Vector3(1.0, 0.1, sz1 - sz0), Vector3(16.5, y + 0.05, (sz0 + sz1) / 2.0), M.ceiling)
	# the stairwell over it, dark, going up
	wall(Vector2(17.0, sz1), Vector2(x1 + 0.2, sz1), 2.8, M.plain, [], y, 0.1)
	wall(Vector2(17.0, sz0), Vector2(17.0, sz1), 2.8, M.plain, [], y, 0.1)
	wall(Vector2(17.0, sz0 - 0.1), Vector2(x1 + 0.2, sz0 - 0.1), 2.8, M.plain, [], y, 0.1)
	wall(Vector2(x1 + 0.1, sz0), Vector2(x1 + 0.1, sz1), 2.8, M.plain, [], y, 0.1)
	box(Vector3(x1 - 16.9, 0.1, sz1 - sz0 + 0.1), Vector3((16.9 + x1) / 2.0, y + 2.85, (sz0 + sz1) / 2.0), M.dark)
	# the counter, square to the hotel door: a guest ledge at the front with the bell and the
	# register on it, and behind and below that the clerk's own surface, his phone face down on it,
	# his mug, his lamp at the end
	var cz0 := -1.5
	var cz1 := -0.22
	var czm := (cz0 + cz1) / 2.0
	var cl := cz1 - cz0
	box(Vector3(0.06, 1.1, cl), Vector3(17.47, 0.55, czm), M.wood)
	box(Vector3(0.4, 0.04, cl + 0.06), Vector3(17.58, 1.12, czm), M.top)
	box(Vector3(0.5, 0.035, cl), Vector3(17.93, 0.9625, czm), M.top)
	box(Vector3(0.5, 0.96, 0.04), Vector3(17.75, 0.48, cz0), M.wood)
	box(Vector3(0.5, 0.96, 0.04), Vector3(17.75, 0.48, cz1), M.wood)
	box(Vector3(0.04, 0.12, cl), Vector3(17.5, 0.06, czm), M.dark)                     # a kick plate, scuffed
	cyl(0.036, 0.042, 0.014, Vector3(17.6, 1.147, -0.98), M.dark, null, 16)             # the bell
	var dome := ball(0.03, Vector3(17.6, 1.157, -0.98), M.steel)
	dome.scale = Vector3(1.0, 0.75, 1.0)
	cyl(0.004, 0.004, 0.02, Vector3(17.6, 1.19, -0.98), M.steel, null, 6)
	box(Vector3(0.24, 0.012, 0.32), Vector3(17.6, 1.146, -0.62), M.dark)                # the register
	box(Vector3(0.22, 0.01, 0.15), Vector3(17.6, 1.156, -0.7), M.paper)
	box(Vector3(0.22, 0.01, 0.15), Vector3(17.6, 1.156, -0.54), M.paper)
	box(Vector3(0.012, 0.004, 0.14), Vector3(17.65, 1.163, -0.48), M.black)             # its pen
	box(Vector3(0.075, 0.009, 0.155), Vector3(17.86, 0.985, -1.12), M.black)            # his phone, face down
	cyl(0.04, 0.038, 0.1, Vector3(18.06, 1.03, -0.3), M.porcelain, null, 14)            # his mug
	cyl(0.065, 0.075, 0.022, Vector3(17.97, 0.991, -1.36), M.frame, null, 14)            # the lamp
	cyl(0.009, 0.009, 0.32, Vector3(17.97, 1.16, -1.36), M.frame, null, 8)
	var shade := cyl(0.05, 0.1, 0.09, Vector3(17.97, 1.34, -1.36), M.shade, null, 16)
	shade.rotation.z = deg_to_rad(18.0)
	ball(0.022, Vector3(17.95, 1.3, -1.36), M.bulb)
	omni(Vector3(17.9, 1.25, -1.3), Color("ffc285"), 1.05, 3.2, true, "desk_lamp")
	# his stool, four legs and a ring for his feet
	var st := Vector3(18.35, 0, -0.62)
	cyl(0.17, 0.17, 0.05, st + Vector3(0, 0.735, 0), M.seat, null, 18)
	for c in [Vector2(0.12, 0.12), Vector2(-0.12, 0.12), Vector2(0.12, -0.12), Vector2(-0.12, -0.12)]:
		cyl(0.014, 0.016, 0.72, st + Vector3(c.x, 0.36, c.y), M.frame, null, 6)
	for c in [[Vector3(0.12, 0.25, 0), 0.0], [Vector3(-0.12, 0.25, 0), 0.0], [Vector3(0, 0.25, 0.12), 90.0], [Vector3(0, 0.25, -0.12), 90.0]]:
		box(Vector3(0.02, 0.02, 0.24), st + c[0], M.frame, deg_to_rad(c[1]))
	# the key board behind him: twenty-one hooks in three rows, a brass fob on most of them
	var kx := x1 - 0.02
	box(Vector3(0.025, 0.62, 0.92), Vector3(kx, 1.56, -0.62), M.wood)
	for row in 3:
		for col in 7:
			var hy := 1.78 - row * 0.21
			var hz := -0.95 + col * 0.11
			box(Vector3(0.035, 0.007, 0.007), Vector3(kx - 0.03, hy, hz), M.steel)
			if r.randf() < 0.24:
				continue
			box(Vector3(0.008, 0.05, 0.004), Vector3(kx - 0.045, hy - 0.03, hz), M.steel)
			var fob := box(Vector3(0.012, 0.075, 0.034), Vector3(kx - 0.046, hy - 0.085, hz), brass)
			fob.rotation.x = r.randf_range(-0.06, 0.06)
	# on the walls: a sign over the board, and a picture of the ferry by the door
	box(Vector3(0.02, 0.09, 0.5), Vector3(kx - 0.005, 1.98, -0.62), M.paper)
	box(Vector3(0.03, 0.42, 0.58), Vector3(16.22, 1.62, 0.25), M.frame)
	box(Vector3(0.01, 0.34, 0.5), Vector3(16.24, 1.62, 0.25), M.paper)
	box(Vector3(0.012, 0.06, 0.36), Vector3(16.25, 1.56, 0.25), M.dark)
	# the light: one bulb in a frosted dish
	cyl(0.17, 0.12, 0.06, Vector3(18.0, y - 0.04, -0.3), M.shade, null, 18)
	omni(Vector3(18.0, y - 0.25, -0.3), Color("f2d2a2"), 0.45, 3.6, false, "lobby")
	anchors["front_desk"] = Vector3(17.6, 1.15, -0.85)
	anchors["desk_bell"] = Vector3(17.6, 1.17, -0.98)
	anchors["key_board"] = Vector3(kx, 1.56, -0.62)


# ---------------------------------------------------------------- the keg room, under the bar

func _keg_room() -> void:
	var y0 := KEG_Y
	var h := 2.3
	# a cellar under the bar and the kitchen: stone walls, a dirt floor at the far end, the lines up
	tiled(Vector3(4.8, 0.1, 6.0), Vector3(2.4, y0 - 0.05, 2.0), M.concrete)
	tiled(Vector3(4.8, 0.1, 2.6), Vector3(2.4, y0 - 0.04, -1.2), M.dirt)
	for w in [[Vector2(-0.1, -2.5), Vector2(-0.1, 5.0)], [Vector2(4.9, -2.5), Vector2(4.9, 5.0)], [Vector2(0, -2.6), Vector2(4.8, -2.6)], [Vector2(0, 5.1), Vector2(4.8, 5.1)]]:
		wall(w[0], w[1], h, M.concrete, [], y0)
	# the ceiling is the underside of the floor above: boards on joists, with a hole for the ladder
	tiled(Vector3(4.8, 0.08, 2.2), Vector3(2.4, -0.15, -1.5), M.boards)
	tiled(Vector3(4.8, 0.08, 1.8), Vector3(2.4, -0.15, 0.5), M.boards)
	tiled(Vector3(4.8, 0.08, 2.6), Vector3(2.4, -0.15, 3.7), M.boards)
	tiled(Vector3(3.3, 0.08, 1.0), Vector3(3.15, -0.15, 1.9), M.boards)
	var jz := -2.3
	while jz < 5.0:
		if absf(jz - 1.9) > 0.55:
			box(Vector3(4.8, 0.2, 0.09), Vector3(2.4, -0.29, jz), M.dark)
		jz += 0.6
	# the ladder down from the trapdoor
	for i in 9:
		box(Vector3(0.6, 0.04, 0.12), Vector3(1.05, y0 + 0.25 + i * 0.27, 2.25 - i * 0.07), M.wood)
	box(Vector3(0.05, 2.6, 0.08), Vector3(0.73, y0 + 1.25, 2.0), M.wood)
	box(Vector3(0.05, 2.6, 0.08), Vector3(1.37, y0 + 1.25, 2.0), M.wood)
	# kegs on pallets in two rows down the room, the lines going up through the ceiling to the taps;
	# an upturned one in the aisle between the rows to sit on
	for row_x in [2.65, 4.2]:
		box(Vector3(0.95, 0.12, 3.4), Vector3(row_x, y0 + 0.06, 2.0), M.wood)
		for k in 6:
			var p := Vector3(row_x, y0 + 0.12 + 0.3, 3.45 - k * 0.58)
			cyl(0.2, 0.2, 0.6, p, M.keg, null, 16)
			cyl(0.035, 0.035, 0.08, p + Vector3(0, 0.34, 0), M.black, null, 8)          # the coupler
			cyl(0.006, 0.006, 1.55, p + Vector3(0, 1.1, 0), M.black, null, 6)          # its line
	box(Vector3(3.0, 0.06, 0.1), Vector3(3.2, -0.14, 2.0), M.black)                    # the bundle, to the bar
	cyl(0.2, 0.2, 0.6, Vector3(3.42, y0 + 0.3, 1.25), M.keg, null, 16)
	# the gas: two cylinders chained to the wall; the compressor ticking over in the corner
	for gz in [4.35, 4.75]:
		cyl(0.11, 0.11, 1.3, Vector3(0.25, y0 + 0.65, gz), M.steel, null, 12)
	box(Vector3(0.02, 0.02, 0.7), Vector3(0.12, y0 + 1.0, 4.55), M.frame)
	box(Vector3(0.7, 0.55, 0.5), Vector3(4.4, y0 + 0.28, 4.7), M.dark)
	box(Vector3(0.02, 0.4, 0.36), Vector3(4.04, y0 + 0.3, 4.7), M.frame)
	# cases of stock along the front wall
	for k in 5:
		box(Vector3(0.5, 0.28, 0.35), Vector3(1.6 + k * 0.52, y0 + 0.14 + (k % 2) * 0.28, 4.85), M.dark)
	# past the last kegs the concrete gives out to dirt, and the foundation runs on into the dark over
	# the black stumps of old pilings
	for k in 9:
		var sp := Vector3(rng.randf_range(0.4, 4.4), 0.0, rng.randf_range(-2.3, -0.4))
		# none of them between where he stands down here and the rats' way in, at the far wall
		if absf(sp.x - 2.95) < 0.4:
			sp.x += 0.8 if sp.x > 2.95 else -0.8
		var sh := rng.randf_range(0.2, 0.7)
		cyl(rng.randf_range(0.11, 0.17), rng.randf_range(0.14, 0.2), sh, Vector3(sp.x, y0 + sh / 2.0, sp.z), M.burn, null, 9)
	box(Vector3(0.3, 0.22, 0.12), Vector3(2.9, y0 + 0.11, -2.52), M.black)             # their way in and out
	# a bare bulb on a cord, over the kegs; nothing lights the dirt
	cyl(0.004, 0.004, 0.4, Vector3(2.9, y0 + h - 0.2, 2.6), M.frame, null, 6)
	ball(0.05, Vector3(2.9, y0 + h - 0.42, 2.6), M.bulb)
	anchors["keg_hole"] = Vector3(2.9, y0 + 0.15, -2.45)
	anchors["compressor"] = Vector3(4.4, y0 + 0.5, 4.7)
	anchors["gas"] = Vector3(0.25, y0 + 1.0, 4.55)
	anchors["pilings"] = Vector3(2.2, y0 + 0.4, -1.4)
	anchors["kegs"] = Vector3(3.4, y0 + 0.6, 2.4)
	anchors["keg_ladder"] = Vector3(1.05, y0 + 1.2, 2.0)


# ---------------------------------------------------------------- the deck, on the water side

func _deck() -> void:
	var x0 := 16.2
	var x1 := 18.4
	# boards, level with the bar's floor through the door, a rail, a tin awning, plastic chairs, the
	# coffee can
	tiled(Vector3(x1 - x0, 0.1, 5.6), Vector3((x0 + x1) / 2.0, -0.05, 7.1), M.boards, 1.5)
	tiled(Vector3(x1 - x0 + 0.4, 0.04, 5.8), Vector3((x0 + x1) / 2.0 + 0.2, 2.75, 7.1), M.steel, 2.0)
	for z in [4.3, 5.7, 7.1, 8.5, 9.9]:
		box(Vector3(0.08, 2.8, 0.08), Vector3(x1, 1.35, z), M.wood)
	# the long rail, open at the back between the last two posts for the steps
	box(Vector3(0.06, 0.06, 4.2), Vector3(x1, 1.0, 7.8), M.wood)
	box(Vector3(0.04, 0.04, 4.2), Vector3(x1, 0.5, 7.8), M.wood)
	# the front end's rail, where you stand to look at the water, and the back end's
	for z in [9.9, 4.3]:
		box(Vector3(x1 - x0, 0.06, 0.06), Vector3((x0 + x1) / 2.0, 1.0, z), M.wood)
		box(Vector3(x1 - x0, 0.04, 0.04), Vector3((x0 + x1) / 2.0, 0.5, z), M.wood)
	# the deck steps, two down to the gravel along the side of the building: the way round from the
	# lot, for whoever wasn't let in the front (deck.ink)
	box(Vector3(0.3, 0.125, 1.22), Vector3(x1 + 0.15, -0.1875, 5.0), M.boards)
	box(Vector3(0.04, 0.04, 1.22), Vector3(x1 + 0.28, -0.13, 5.0), M.wood)
	# the boards' edge down to the ground, so the deck sits on something
	box(Vector3(0.03, 0.16, 5.6), Vector3(x1 + 0.015, -0.17, 7.1), M.wood)
	box(Vector3(x1 - x0, 0.16, 0.03), Vector3((x0 + x1) / 2.0, -0.17, 9.915), M.wood)
	box(Vector3(x1 - x0, 0.16, 0.03), Vector3((x0 + x1) / 2.0, -0.17, 4.285), M.wood)
	# the rain off the tin awning in ropes, along its two open edges
	var zr := 4.4
	while zr < 9.95:
		box(Vector3(0.012, 2.75, 0.012), Vector3(x1 + 0.38, 1.37, zr), M.drop)
		zr += rng.randf_range(0.22, 0.38)
	var xr := x0 + 0.15
	while xr < x1 + 0.4:
		box(Vector3(0.012, 2.75, 0.012), Vector3(xr, 1.37, 10.02), M.drop)
		xr += rng.randf_range(0.22, 0.38)
	# the chairs where people sit in them (stage.gd's deck_chair spots), each turned the way its
	# sitter faces, give or take, and a fourth at the back for the mill crew
	var chairs := [[Vector3(17.3, 0, 5.0), Vector3(18.4, 0, 6.2)], [Vector3(17.8, 0, 6.6), Vector3(18.4, 0, 6.6)],
			[Vector3(17.3, 0, 8.2), Vector3(18.4, 0, 8.2)], [Vector3(16.75, 0, 5.35), Vector3(17.6, 0, 6.4)]]
	for i in chairs.size():
		var c := Node3D.new()
		var to: Vector3 = chairs[i][1] - chairs[i][0]
		c.position = chairs[i][0]
		c.rotation.y = atan2(to.x, to.z) + (rng.randf_range(0, TAU) - PI) * 0.04 if i < 3 else atan2(to.x, to.z)
		add_child(c)
		box(Vector3(0.44, 0.04, 0.42), Vector3(0, 0.42, 0), M.porcelain, 0.0, c)
		box(Vector3(0.44, 0.4, 0.04), Vector3(0, 0.64, -0.2), M.porcelain, 0.0, c)
		for s in [Vector2(-0.19, -0.18), Vector2(0.19, -0.18), Vector2(-0.19, 0.18), Vector2(0.19, 0.18)]:
			box(Vector3(0.03, 0.42, 0.03), Vector3(s.x, 0.21, s.y), M.porcelain, 0.0, c)
	# the coffee can for the butts, in the front corner by the rail
	cyl(0.08, 0.08, 0.18, Vector3(18.1, 0.09, 9.6), M.steel, null, 12)
	# the building's outside wall, siding
	wall(Vector2(16.25, 3.6), Vector2(16.25, 10.4), 3.4, M.siding, [[2.9, 4.1, 0.0, 2.3]], 0.0, 0.05)
	# a bulb over the door in a cage: someone's put a cold LED in it
	ball(0.05, Vector3(16.4, 2.5, 7.1), M.led)
	anchors["deck_rail"] = Vector3(18.3, 1.0, 7.1)
	anchors["deck_can"] = Vector3(18.1, 0.2, 9.6)


# ---------------------------------------------------------------- outside

func _outside() -> void:
	tiled(Vector3(40, 0.1, 18), Vector3(8, -0.05, 19.2), M.gravel, 3.0)
	for p in [Vector3(4.2, 0, 11.7), Vector3(6.8, 0, 12.5), Vector3(5.6, 0, 14.8), Vector3(10.6, 0, 13.3), Vector3(12.5, 0, 17.9), Vector3(3.0, 0, 16.4)]:
		box(Vector3(rng.randf_range(0.8, 1.9), 0.01, rng.randf_range(0.5, 1.1)), p + Vector3(0, 0.003, 0), M.puddle, rng.randf_range(-30.0, 30.0))
	# the ground along the east side, from the hotel's front door past the deck to the lot, a step
	# below it, with the lot's timber edge where it ends
	tiled(Vector3(14, 0.1, 14), Vector3(23, -0.3, 4.0), M.gravel, 3.0)
	box(Vector3(9.6, 0.27, 0.2), Vector3(23.2, -0.115, 10.1), M.wood)
	# the foundation under the siding, the hotel's front door and the bar's east wall, down to it,
	# and the hotel door's step
	box(Vector3(3.56, 0.27, 0.06), Vector3(17.96, -0.135, 0.86), M.dark)
	box(Vector3(0.06, 0.27, 3.7), Vector3(19.76, -0.135, -1.0), M.dark)
	box(Vector3(0.06, 0.27, 3.5), Vector3(16.27, -0.135, 2.58), M.dark)
	box(Vector3(1.2, 0.125, 0.4), Vector3(18.875, -0.1875, 1.08), M.dark)
	box(Vector3(160, 0.1, 6), Vector3(8, -0.06, 30.6), M.gravel)
	box(Vector3(160, 0.02, 8), Vector3(8, 0.0, 31.6), M.road)
	for x in range(-60, 80, 6):
		box(Vector3(2.5, 0.01, 0.12), Vector3(x, 0.02, 31.6), M.wall)
	box(Vector3(160, 0.9, 0.5), Vector3(8, 0.2, 35.9), M.dark)
	box(Vector3(900, 0.02, 900), Vector3(8, -0.4, 486), M.water)
	for i in 16:
		ball(rng.randf_range(0.5, 1.1), Vector3(rng.randf_range(-260, 420), rng.randf_range(0.5, 6.0), 420 + rng.randf_range(0, 40)), M.far)
	# outside the door: the step, and the sign over it
	box(Vector3(2.6, 0.12, 1.2), Vector3(3.2, 0.06, 10.8), M.dark)
	box(Vector3(4.6, 1.0, 0.12), Vector3(4.3, 3.85, 10.3), M.black)
	box(Vector3(4.3, 0.07, 0.04), Vector3(4.3, 3.62, 10.37), M.neon)
	box(Vector3(4.3, 0.07, 0.04), Vector3(4.3, 4.08, 10.37), M.neon)
	# the lamp on a pole at the edge of the lot
	cyl(0.07, 0.09, 6.5, Vector3(15.8, 3.25, 21.5), M.frame, null, 10)
	box(Vector3(0.9, 0.12, 0.35), Vector3(15.4, 6.5, 21.5), M.frame)
	box(Vector3(0.7, 0.02, 0.25), Vector3(15.4, 6.43, 21.5), M.sodium)
	# cars on the highway
	ball(0.09, Vector3(19.0, 0.7, 30.3), M.head)
	ball(0.09, Vector3(19.0, 0.7, 31.1), M.head)
	ball(0.07, Vector3(-9.0, 0.75, 32.2), M.tail)
	ball(0.07, Vector3(-9.0, 0.75, 33.0), M.tail)
	# two more cars in the lot, parked nose in
	for c in [[Vector3(13.0, 0, 12.4), 0.0], [Vector3(-1.5, 0, 13.4), 8.0]]:
		var car := Node3D.new()
		car.position = c[0]
		car.rotation.y = deg_to_rad(c[1])
		add_child(car)
		box(Vector3(1.8, 0.7, 4.3), Vector3(0, 0.55, 0), M.seat, 0.0, car)
		box(Vector3(1.6, 0.55, 2.2), Vector3(0, 1.15, 0.2), M.seat, 0.0, car)
		box(Vector3(1.55, 0.45, 0.02), Vector3(0, 1.15, -0.91), M.glass, 0.0, car)
	anchors["lot"] = Vector3(8.0, 1.0, 15.0)
	anchors["sign"] = Vector3(4.3, 3.85, 10.4)


# The hotel over the pub, as it's seen from the lot: two floors of rooms, the windows, the fire
# escape, his window the one lit at the end of the night.
func _facade() -> void:
	var z := ZF + 0.12
	# three storeys of old wood, painted a red that had faded to the colour of brick
	# the second floor: the boards, with a hole for his window at the east end, so he can see out
	wall(Vector2(-0.6, z - 0.05), Vector2(16.6, z - 0.05), 3.3, M.paint, [[14.7, 15.7, 0.45, 1.75]], 3.4, 0.2)
	tiled(Vector3(17.2, 3.1, 0.2), Vector3(8.0, 6.7 + 1.55, z - 0.05), M.paint, 3.0)
	# the ground floor's outside: the same boards, round the door and the front window
	wall(Vector2(-0.1, ZF + 0.13), Vector2(16.3, ZF + 0.13), 3.4, M.paint, [[DOOR_W + 0.1, DOOR_E + 0.1, 0.0, 2.3], [6.3, 12.7, 0.9, 2.4]], 0.0, 0.04)
	# on the roof the sign: SOVEREIGN in red neon with the second E dead, and HOTEL under it, all
	# five letters working
	var word := "SOVEREIGN"
	for i in word.length():
		_neon(word[i], Vector3(8.0 + (i - 4) * 1.02, 11.35, z + 0.35), 1.0, i != 5)
	var h2 := "HOTEL"
	for i in h2.length():
		_neon(h2[i], Vector3(8.0 + (i - 2) * 0.62, 10.5, z + 0.35), 0.58, true)
	# the rack they're bolted to, behind them, its posts clear of the letters
	box(Vector3(10.2, 0.08, 0.08), Vector3(8.0, 10.86, z + 0.2), M.frame)
	for x in [3.3, 8.31, 12.7]:
		box(Vector3(0.08, 1.9, 0.08), Vector3(x, 10.95, z + 0.2), M.frame)
	# its light: the roof's edge and the top floor, gone by the second
	var glow_l := omni(Vector3(8.0, 10.9, z + 1.6), Color("ff3a28"), 1.3, 5.5, false, "roof_sign")
	glow_l.omni_attenuation = 1.3
	anchors["roof_sign"] = Vector3(8.0, 11.0, z + 0.35)
	box(Vector3(17.6, 0.3, 1.2), Vector3(8.0, 9.9, z - 0.4), M.dark)
	var wins: Array = []
	for row in [4.5, 7.8]:
		for x in [1.4, 3.6, 5.8, 8.0, 10.2, 12.4, 14.6]:
			var w := box(Vector3(1.0, 1.3, 0.05), Vector3(x, row, z + 0.03), M.black)
			box(Vector3(1.12, 0.08, 0.1), Vector3(x, row - 0.7, z + 0.06), M.wood)
			wins.append(w)
	dyn.windows = wins
	# a window or two lit: residents up late
	wins[3].material_override = M.window_lit
	wins[9].material_override = M.window_lit
	# his, at the east end of the second floor: glass
	wins[6].material_override = M.glass
	# the fire escape on the east end
	for fy in [4.0, 7.3]:
		box(Vector3(2.2, 0.05, 1.0), Vector3(15.8, fy - 0.9, z + 0.55), M.frame)
		box(Vector3(2.2, 0.9, 0.03), Vector3(15.8, fy - 0.45, z + 1.05), M.frame)
	# the side of the building, over the deck
	tiled(Vector3(0.2, 6.6, 10.2), Vector3(16.3, 3.2 + 3.3, 5.0), M.siding, 3.0)
	anchors["his_window"] = Vector3(14.6, 4.5, z)


# A letter of the roof sign: neon, lit or dead.
func _neon(ch: String, at: Vector3, h: float, lit: bool) -> void:
	var l := Label3D.new()
	l.text = ch
	l.font = Look.font("ui_b")
	l.font_size = 192
	l.pixel_size = h / 150.0
	l.outline_size = 0
	l.modulate = Color("cc001a") if lit else DEAD
	l.position = at
	l.double_sided = false
	l.shaded = false
	l.no_depth_test = false
	add_child(l)
	# dark till half past four (dusk())
	l.set_meta("lit", l.modulate)
	if not dyn.has("neon"):
		dyn.neon = []
	dyn.neon.append(l)


# The cold beer and wine store at the west end, its lights on; the big man's work truck nose-in by
# it, a toolbox across the bed.
func _store() -> void:
	var x0 := -6.4
	var x1 := -0.15
	wall(Vector2(x0, ZF + 0.1), Vector2(x1, ZF + 0.1), 3.4, M.paint, [[1.2, 4.4, 0.5, 2.5], [4.8, 5.8, 0.0, 2.3]], 0.0, 0.12)
	wall(Vector2(x0, 4.0), Vector2(x0, ZF + 0.1), 3.4, M.paint, [], 0.0, 0.12)
	tiled(Vector3(x1 - x0, 0.2, 6.3), Vector3((x0 + x1) / 2.0, 3.5, 7.0), M.dark, 3.0)
	box(Vector3(3.2, 2.0, 0.03), Vector3(x0 + 2.8, 1.5, ZF + 0.1), M.window_lit)
	box(Vector3(1.0, 2.3, 0.03), Vector3(x0 + 5.3, 1.15, ZF + 0.1), M.window_lit)
	var sign := Label3D.new()
	sign.text = "COLD BEER & WINE"
	sign.font = Look.font("ui_b")
	sign.font_size = 96
	sign.pixel_size = 0.0042
	sign.modulate = Color(1.0, 0.93, 0.8)
	sign.shaded = false
	sign.position = Vector3((x0 + x1) / 2.0, 2.95, ZF + 0.2)
	add_child(sign)
	var spill := omni(Vector3((x0 + x1) / 2.0, 2.0, ZF + 1.4), Color("ffe6bf"), 1.4, 7.5, false, "store")
	spill.omni_attenuation = 1.2
	var wt := model("res://models/truck.glb", Vector3(-3.4, 0, 13.6))
	wt.look_at(Vector3(-3.4, 0, 20.0), Vector3.UP)
	wt.rotate_y(PI)
	_repaint(wt, Color("b9b6ad"))
	box(Vector3(1.7, 0.45, 0.5), Vector3(0, 1.2, 1.3), mat(Color("8f9396"), 0.4, 0.7, 2), 0.0, wt)
	dyn.work_truck = wt
	# the cab, over the roof of the car parked by it
	anchors["work_truck"] = wt.to_global(Vector3(0, 1.6, -1.0))
	anchors["store"] = Vector3((x0 + x1) / 2.0, 1.5, ZF + 0.2)


# a model's painted parts in another colour (the same model, a different truck)
func _repaint(n: Node, c: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i)
			if m is ShaderMaterial and (m as ShaderMaterial).get_shader_parameter("albedo") == RECOLOUR.paint:
				var m2 := (m as ShaderMaterial).duplicate() as ShaderMaterial
				m2.set_shader_parameter("albedo", c)
				mi.set_surface_override_material(i, m2)
	for ch in n.get_children():
		_repaint(ch, c)


# The pickup the kid got out of: nose in, facing the door, the engine running and the lights on.
func _truck() -> void:
	var t := Node3D.new()
	t.position = Vector3(9.2, 0, 15.8)
	add_child(t)
	t.look_at(Vector3(3.2, 0, 10.1), Vector3.UP)
	model("res://models/truck.glb", Vector3.ZERO, t)
	dyn.truck = t
	var dome := OmniLight3D.new()
	dome.position = Vector3(0, 1.72, -0.3)
	dome.light_color = Color("ffe0b0")
	dome.light_energy = 0.7
	dome.omni_range = 2.0
	t.add_child(dome)
	dyn.truck_dome = dome
	var beams: Array = []
	for sx in [-0.72, 0.72]:
		var beam := spot(Vector3.ZERO, Vector3(0, -0.5, -10), Color("eef2ff"), 4.5, 22.0, 22.0, true, t)
		beam.position = Vector3(sx, 0.95, -3.0)
		beam.look_at(t.to_global(Vector3(sx * 1.4, 0.2, -12.0)), Vector3.UP)
		beams.append(beam)
	dyn.truck_beams = beams
	anchors["truck"] = t.to_global(Vector3(0, 1.3, 0))
	anchors["truck_cab"] = t.to_global(Vector3(-0.45, 1.35, -0.2))


# ---------------------------------------------------------------- upstairs

# His room on the second floor, at the east end over the lot: a bed, a sink, a chair, the window
# with the sign's red coming up through it.
func _upstairs() -> void:
	var y0 := UP_Y
	var x0 := 13.4
	var x1 := 16.0
	var z0 := 6.4
	var z1 := 9.95
	var worn := mat(Color("4e4a3f"), 0.95, 0.0, 1, Vector3(1, 0, 0.3), 7.0, 0.5)
	tiled(Vector3(x1 - x0, 0.1, z1 - z0), Vector3((x0 + x1) / 2.0, y0 - 0.05, (z0 + z1) / 2.0), worn)
	tiled(Vector3(x1 - x0, 0.1, z1 - z0), Vector3((x0 + x1) / 2.0, y0 + 2.6, (z0 + z1) / 2.0), M.ceiling)
	wall(Vector2(x0, z0), Vector2(x1, z0), 2.6, M.plain, [[0.3, 1.1, 0.0, 2.0]], y0, 0.1)
	wall(Vector2(x0, z0), Vector2(x0, z1), 2.6, M.plain, [], y0, 0.1)
	wall(Vector2(x1, z0), Vector2(x1, z1), 2.6, M.plain, [], y0, 0.1)
	# the window lines up with its hole in the front of the building (the facade's second-floor row)
	wall(Vector2(x0, z1), Vector2(x1, z1), 2.6, M.plain, [[0.7, 1.7, 0.45, 1.75]], y0, 0.1)
	box(Vector3(1.0, 1.3, 0.02), Vector3(x0 + 1.2, y0 + 1.1, z1), M.glass)
	# the bed, the chair, the sink
	box(Vector3(1.0, 0.45, 2.0), Vector3(x1 - 0.6, y0 + 0.22, z0 + 1.4), M.bed)
	box(Vector3(1.0, 0.12, 0.3), Vector3(x1 - 0.6, y0 + 0.5, z0 + 0.55), M.porcelain)
	box(Vector3(0.45, 0.45, 0.45), Vector3(x0 + 0.5, y0 + 0.22, z1 - 1.3), M.wood)
	# the one bag he came with, on the chair
	var bag := cyl(0.16, 0.16, 0.55, Vector3(x0 + 0.5, y0 + 0.61, z1 - 1.3), M.dark, null, 12)
	bag.rotation.z = deg_to_rad(90.0)
	bag.rotation.y = deg_to_rad(20.0)
	# the radiator under the window
	for k in 8:
		box(Vector3(0.05, 0.34, 0.1), Vector3(x0 + 0.85 + k * 0.1, y0 + 0.23, z1 - 0.14), M.frame)
	cyl(0.18, 0.14, 0.14, Vector3(x0 + 0.25, y0 + 0.85, z0 + 0.5), M.porcelain, null, 12)
	box(Vector3(0.02, 0.5, 0.4), Vector3(x0 + 0.06, y0 + 1.5, z0 + 0.5), M.mirror)
	ball(0.05, Vector3((x0 + x1) / 2.0, y0 + 2.45, (z0 + z1) / 2.0), M.bulb)
	anchors["his_bed"] = Vector3(x1 - 0.6, y0 + 0.5, z0 + 1.4)
	anchors["up_window"] = Vector3(x0 + 1.2, y0 + 1.1, z1)


func _rain() -> void:
	var rain := CPUParticles3D.new()
	rain.amount = 3000
	rain.lifetime = 1.1
	rain.preprocess = 3.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(12.0, 0.3, 7.5)
	rain.position = Vector3(8.0, 7.5, 17.5)
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
	dyn.rain = rain
	# and past the deck's rail
	var r2 := rain.duplicate() as CPUParticles3D
	r2.amount = 900
	r2.emission_box_extents = Vector3(2.0, 0.3, 5.0)
	r2.position = Vector3(20.2, 6.0, 7.0)
	add_child(r2)


# ---------------------------------------------------------------- light

func _lights() -> void:
	# the vestibule: the lamp over the door and his stool
	omni(Vector3(2.25, 2.95, 9.2), Color("ffc27a"), 1.8, 4.6, true, "door_lamp")
	cyl(0.16, 0.16, 0.05, Vector3(2.25, 3.17, 9.2), M.lamp)
	omni(Vector3(2.3, 1.95, 8.1), Color("ffcf93"), 0.55, 3.2)
	omni(Vector3(4.1, 3.4, 11.1), Color("ff3a28"), 0.7, 7.0, true, "sign")
	# the lot's sodium, the lamp ink's own orange, so its pool on the wet lot prints in that ink
	var s := omni(Vector3(15.4, 6.2, 21.5), Color("ffac40"), 5.0, 16.0, true, "sodium")
	s.omni_attenuation = 1.4
	var pl := spot(POOL + Vector3(0, 1.86, 0), POOL, Color("fff0d6"), 7.0, 3.2, 58.0, true)
	lights["pool"] = pl
	lamps.append(pl)
	var t28l := spot(T28 + Vector3(0, 2.2, 0), T28, Color("ffb865"), 3.2, 3.6, 55.0, true)
	lamps.append(t28l)
	for t in TABLES:
		lamps.append(spot(t + Vector3(0, 2.2, 0), t, Color("ffb865"), 3.0, 3.6, 55.0))
	for z in [2.4, 4.4, 6.4]:
		lamps.append(spot(Vector3(1.95, 2.15, z), Vector3(1.95, 0, z), Color("ffb865"), 2.6, 3.4, 52.0, z > 5.0))
	for sc in [[Vector3(4.8, 2.05, 0.1), 0.0], [Vector3(11.6, 2.05, 0.1), 0.0], [Vector3(15.9, 2.05, 6.0), -90.0],
			[Vector3(15.9, 2.05, 9.3), -90.0], [Vector3(14.3, 2.05, 9.98), 180.0]]:
		sconce(sc[0], sc[1])
	lamps.append(omni(Vector3(0.7, 2.5, 4.4), Color("ffcf93"), 1.2, 4.5, false, "back_bar"))
	# the cooler's glass and the two televisions, green-white; the jukebox, red
	omni(Vector3(1.1, 1.2, 0.7), Color(COLD_LIGHT), 0.5, 2.6)
	omni(Vector3(9.4, 2.3, 0.7), Color("9fdcc6"), 0.55, 4.5)
	omni(Vector3(15.2, 2.3, 4.0), Color("9fdcc6"), 0.45, 4.0)
	omni(Vector3(13.2, 1.6, 0.7), Color("ff3355"), 1.0, 3.0, false, "juke")
	# the house lights, off until last call, when they come up white, and hard on everything at two
	var work: Array = []
	for p in [Vector3(4.0, 3.0, 2.5), Vector3(12.0, 3.0, 2.5), Vector3(4.0, 3.0, 7.5), Vector3(12.0, 3.0, 7.5)]:
		var w := omni(p, Color("eef3f5"), 0.0, 7.5)
		w.visible = false
		work.append(w)
	dyn.work = work
	# the room's middle: a little light off the ceiling so the depth reads (the review: frame 3)
	for p in [Vector3(5.5, 2.6, 3.0), Vector3(12.5, 2.6, 3.0), Vector3(6.5, 2.6, 7.2), Vector3(12.0, 2.6, 7.0)]:
		lamps.append(omni(p, Color("e8b87a"), 0.28, 5.5))
	# behind the back wall: the hall's tubes, the kitchen's, the washrooms', all of them the cold
	# ink's green-white
	omni(Vector3(9.0, 2.3, -0.6), Color(TUBE_LIGHT), 0.9, 4.5, true, "hall")
	omni(Vector3(14.5, 2.3, -0.6), Color(TUBE_LIGHT), 0.8, 4.0, false, "hall2")
	omni(Vector3(2.4, 2.3, -1.3), Color(TUBE_LIGHT), 1.1, 4.5, true, "kitchen")
	for x in [7.5, 9.8, 12.0]:
		omni(Vector3(x, 2.2, -1.9), Color(TUBE_LIGHT), 0.5, 2.2)
	# the keg room's bare bulb
	omni(Vector3(2.9, KEG_Y + 1.85, 2.6), Color("ffcf93"), 1.3, 3.9, true, "keg")
	# the deck's caged bulb, a cold LED: the deck's the blue of rain at night
	omni(Vector3(16.6, 2.45, 7.1), Color("c4e2ee"), 1.1, 4.5, true, "deck")
	# upstairs: the bulb, and the sign's red up through the window
	omni(Vector3(14.7, UP_Y + 2.3, 8.2), Color("ffcf93"), 0.8, 4.0, true, "upstairs")
	omni(Vector3(14.6, UP_Y + 0.6, 10.6), Color("ff3a28"), 0.6, 3.5)
