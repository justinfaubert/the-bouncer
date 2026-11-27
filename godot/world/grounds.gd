# The grounds round the Sov, at night, on his own feet (Hutch, 2026-11-22: "There are areas that the
# player should be able to walk around in outside of the bar. More freedom and more incentive for
# exploration will enhance the experience by orders of magnitude.")
#
# Out the front door the night used to end at the edge of the lot. Now his feet go anywhere a man
# could walk: round the east side past the hotel's own front door and its buzzers, round the back
# where the kitchen door's propped and the dumpster is and the hill comes down to a chain-link fence,
# up the alley between the kitchen and the beer store; across the highway (the cars don't stop for
# him) to the seawall, where a man's fishing with nothing on his hook; down the steps through the
# wall onto the beach, the logs and the kelp line and somebody's fire still warm; and a hundred and
# fifty metres down the shoulder to the Esso, past a white cross on the guardrail post, where the
# payphone on the end wall is ringing. Every one of those minutes is a minute nobody's on the door.
#
# This builds what wasn't there (the back of the hotel and its upper floors, the yard, the alley,
# the beach, the steps through the seawall, the things lying about), keeps the town (world/town.gd)
# out at night while he's outdoors so the Esso is there to walk to, sends cars down the highway,
# carries the rain with him, and keeps the walk map for out here: where a man can stand, as a
# distance to the nearest thing he'd walk into, the same as world/nav.gd's map is for the ground
# floor (game/feet.gd walks him on it). It's worked out from shapes, not baked: the lot in front of
# the building is still Nav's (its map has the cars and the pickup in it), and everything past it is
# here.
#
# Units are metres, as in the Sov: +x north along the shore, +z east out to the water. The ground
# round the back and down the east side is a step below the lot (the gravel's at -0.25); the beach
# runs from the foot of the seawall, a little under the road, down into the water at about z 44.
class_name Grounds
extends Node3D

# where Nav's walk map has the lot (inside it, both maps are asked and the closer thing wins)
const LOT := Rect2(-5.6, 10.3, 28.0, 14.5)
# where a man can walk out here, each a rectangle on the ground (x, z); they overlap where they
# meet, so the join between two is never an edge. Named, for where he is.
const AREAS := [
	["lot", Rect2(-10.0, 10.0, 38.0, 19.0)],
	["side", Rect2(18.45, -13.0, 12.6, 24.0)],
	["back", Rect2(-10.0, -13.0, 41.0, 10.4)],
	["alley", Rect2(-10.0, -13.0, 9.9, 24.0)],
	["road", Rect2(-170.0, 25.0, 232.0, 10.65)],
	["steps", Rect2(13.35, 34.8, 1.3, 2.4)],
	["beach", Rect2(-14.0, 36.25, 54.0, 9.4)],
	["esso", Rect2(-169.0, 1.5, 38.0, 26.5)],
	# up the old main street from the highway, sidewalk to sidewalk, to its top (world/town.gd), and
	# the highway on past the Esso to the foot of it
	["main", Rect2(Town.MAIN_X - Town.WALK + 0.2, Town.TOP_Z + 2.0, (Town.WALK - 0.2) * 2.0, Town.FOOT - Town.TOP_Z)],
	["road_w", Rect2(-215.0, 25.0, 50.0, 10.65)],
]
# the names that come up the first time he walks into each (and what the voices answer to:
# ears:out_<area> in content/rules/barks.yaml)
const BANNER := {"side": "THE HOTEL'S FRONT DOOR", "back": "BEHIND THE SOV", "alley": "THE ALLEY",
	"road": "THE HIGHWAY", "seawall": "THE SEAWALL", "beach": "THE BEACH", "shoulder": "THE SHOULDER",
	"esso": "THE ESSO", "main": "THE OLD MAIN STREET"}
const STEP_X := Vector2(13.35, 14.65)     # the gap in the seawall, the steps down through it
const WALL_Z := Vector2(35.65, 36.15)     # the seawall, its road side and its sea side
const LANES := [29.6, 33.6]               # the highway's two lanes: to the Esso, and up island
# Things lying about, as footprints on the ground: [middle (x, z), half its size (x, z), turned
# (degrees)]. Built from these and walked round from these, so the two never disagree.
const BOXES := {
	# the building: the bar, the back strip, the beer store, the hotel's lobby, the deck and its rail
	"sov": [Vector2(8.05, 3.68), Vector2(8.29, 6.6), 0.0],
	"store": [Vector2(-3.33, 7.06), Vector2(3.24, 3.2), 0.0],
	"lobby": [Vector2(17.93, -1.0), Vector2(1.95, 1.9), 0.0],
	"deck": [Vector2(17.35, 7.82), Vector2(1.15, 2.18), 0.0],
	"deck_end": [Vector2(17.35, 4.32), Vector2(1.15, 0.09), 0.0],
	"hotel_step": [Vector2(18.875, 1.08), Vector2(0.62, 0.22), 0.0],
	"kitchen_step": [Vector2(-0.45, -1.54), Vector2(0.38, 0.58), 0.0],
	# the alley and the back
	"dumpster": [Vector2(-3.4, 3.12), Vector2(1.02, 0.62), 3.0],
	"drums": [Vector2(-5.95, -0.6), Vector2(0.34, 0.66), 0.0],
	"pallets": [Vector2(-6.2, 2.6), Vector2(0.3, 0.62), 0.0],
	"crate": [Vector2(-1.35, -2.6), Vector2(0.2, 0.2), 12.0],
	"freezer": [Vector2(11.6, -3.45), Vector2(0.78, 0.4), -2.0],
	"mattress": [Vector2(22.0, -12.65), Vector2(0.95, 0.2), 4.0],
	"cart": [Vector2(26.3, -9.2), Vector2(0.32, 0.5), 33.0],
	"tv": [Vector2(15.2, -5.2), Vector2(0.36, 0.3), -20.0],
	"car_blocks": [Vector2(27.0, -4.0), Vector2(0.95, 2.2), -4.0],
	"bins": [Vector2(-1.1, 1.6), Vector2(0.38, 0.85), 0.0],
	"news_box": [Vector2(20.75, 1.45), Vector2(0.26, 0.24), -6.0],
	"bike": [Vector2(20.05, -1.0), Vector2(0.14, 0.85), 0.0],
	# the seawall, either side of the steps
	"wall_n": [Vector2((STEP_X.x - 72.0) / 2.0, 35.9), Vector2((STEP_X.x + 72.0) / 2.0, 0.25), 0.0],
	"wall_s": [Vector2((STEP_X.y + 88.0) / 2.0, 35.9), Vector2((88.0 - STEP_X.y) / 2.0, 0.25), 0.0],
	# the beach: the logs washed up and the fire's
	"log_a": [Vector2(4.0, 38.6), Vector2(3.6, 0.3), 9.0],
	"log_b": [Vector2(19.0, 37.9), Vector2(2.9, 0.26), -14.0],
	"log_c": [Vector2(23.2, 41.6), Vector2(1.9, 0.22), 28.0],
	"log_d": [Vector2(26.4, 39.4), Vector2(1.5, 0.24), -71.0],
	"log_e": [Vector2(-8.0, 40.2), Vector2(2.6, 0.3), -22.0],
	"log_f": [Vector2(33.0, 38.0), Vector2(2.2, 0.28), 5.0],
	"beach_cart": [Vector2(31.0, 43.9), Vector2(0.32, 0.5), 70.0],
	# the Esso: the store, the islands, the propane cage and the freezer by the door
	"esso_store": [Vector2(-150.5, 7.55), Vector2(7.5, 4.6), 0.0],
	"island_a": [Vector2(-150.0, 19.0), Vector2(5.0, 0.6), 0.0],
	"island_b": [Vector2(-150.0, 23.0), Vector2(5.0, 0.6), 0.0],
	"propane": [Vector2(-157.0, 12.5), Vector2(0.75, 0.4), 0.0],
	"ice": [Vector2(-147.3, 12.4), Vector2(0.62, 0.36), 0.0],
	"bench": [Vector2(-192.25, -48.5), Vector2(0.3, 0.9), 0.0],
}
const ROUNDS := {
	# posts and poles: the lot's lamp, the highway's, the price sign's, the cross on the shoulder
	"lot_pole": [Vector2(15.8, 21.5), 0.12],
	"cobra_a": [Vector2(-50.0, 26.2), 0.14],
	"cobra_b": [Vector2(-84.0, 26.2), 0.14],
	"cobra_c": [Vector2(-118.0, 26.2), 0.14],
	"cross": [Vector2(-38.0, 26.75), 0.22],
	"price_sign": [Vector2(-134.5, 26.4), 0.2],
	"esso_can": [Vector2(-155.9, 23.0), 0.32],
	"urn": [Vector2(19.55, 1.55), 0.2],
	"merle": [Vector2(2.0, 35.15), 0.32],
	# up the old main street: the meter outside Gary's, the Legion's board, the sign at the highway
	"meter": [Vector2(-193.75, -78.6), 0.12],
	"legion_board": [Vector2(-191.2, -4.0), 0.25],
	"pop_sign": [Vector2(-212.0, 26.1), 0.2],
	"bucket": [Vector2(2.75, 35.2), 0.18],
	"fire": [Vector2(24.5, 40.4), 0.55],
	# the big rocks at the foot of the wall and the two points of the beach
	"rock_a": [Vector2(-12.6, 39.0), 1.6], "rock_b": [Vector2(-11.0, 42.8), 1.3], "rock_c": [Vector2(38.4, 40.0), 1.7],
	"rock_d": [Vector2(37.0, 44.2), 1.2], "rock_e": [Vector2(9.5, 36.6), 0.42], "rock_f": [Vector2(17.2, 36.7), 0.5],
	"rock_g": [Vector2(-2.5, 36.7), 0.45], "rock_h": [Vector2(28.4, 36.75), 0.5],
}
# how big each thing he can look at out here is, for his eyes to rest on it (game/hotspots.gd)
const RADIUS := {"rat_gap": 0.3, "lot_pole": 0.5, "buzzers": 0.22, "news_box": 0.35, "hotel_urn": 0.25,
	"kitchen_door": 0.6, "dumpster": 1.0, "drums": 0.6, "cook_crate": 0.3, "back_freezer": 0.7, "vent": 0.3,
	"caps": 0.35, "fence": 1.4, "trail": 1.2, "back_tv": 0.4, "blocks_car": 1.6, "mattress": 0.9,
	"cross": 0.5, "merle": 0.5, "plaque": 0.35, "sea_steps": 0.7, "beach_fire": 0.6, "kelp": 0.7,
	"beach_cart": 0.6, "far_shore": 6.0, "esso_phone": 0.35, "esso_pumps": 1.2, "esso_clerk": 1.6,
	"esso_prices_n": 1.4, "hotel_back": 2.0,
	"night_slot": 0.3, "meter": 0.3, "legion_board": 0.9, "bench": 0.8, "capsule": 0.35, "pop_sign": 1.2,
	"drain": 0.4}

static var _boxes: Array = []      # [middle, half, cos, sin]
static var _rounds: Array = []     # [middle, radius]

var pub: Pub
var _night_only: Array = []      # nodes only out there at night
var rng := RandomNumberGenerator.new()
var M := {}
var out_here := false             # he's outdoors at the Sov (the lot, round the back, across the road)
var area := ""                    # which part of it
var seen := {}                    # the parts he's walked into, for the names
var cars: Array = []              # [node, lane, speed, x, dir, swerve, honked]
var _car_t := 4.0
var _flicker: Array = []          # [light, base energy, how fast]
var _fire: OmniLight3D
var _rain_home := Vector3.ZERO
var _phone_rang := false
var _mix_t := 0.0
var banner: Label
var _banner_t := 0.0


# ---------------------------------------------------------------- the walk map

static func _layout() -> void:
	if not _boxes.is_empty():
		return
	for k in BOXES:
		var b: Array = BOXES[k]
		var a := deg_to_rad(float(b[2]))
		_boxes.append([b[0], b[1], cos(a), sin(a)])
	for k in ROUNDS:
		_rounds.append(ROUNDS[k])


# How far it is from p to the nearest thing a man would walk into, out here (0 where he can't stand
# at all): the edge of where there's ground to walk, the building, everything lying about. In the
# lot in front of the building, Nav's map has its say too.
static func clearance(p: Vector3) -> float:
	_layout()
	var q := Vector2(p.x, p.z)
	var room := 0.0
	for ar in AREAS:
		var r: Rect2 = ar[1]
		var d := minf(minf(q.x - r.position.x, r.end.x - q.x), minf(q.y - r.position.y, r.end.y - q.y))
		room = maxf(room, d)
	if room <= 0.0:
		return 0.0
	for b in _boxes:
		var rel: Vector2 = q - (b[0] as Vector2)
		var lx: float = rel.x * b[2] - rel.y * b[3]
		var lz: float = rel.x * b[3] + rel.y * b[2]
		var h: Vector2 = b[1]
		var dx := absf(lx) - h.x
		var dz := absf(lz) - h.y
		var d := Vector2(maxf(dx, 0.0), maxf(dz, 0.0)).length() if (dx > 0.0 or dz > 0.0) else 0.0
		room = minf(room, d)
		if room <= 0.0:
			return 0.0
	for c in _rounds:
		room = minf(room, maxf(0.0, q.distance_to(c[0]) - float(c[1])))
	if LOT.has_point(q):
		room = minf(room, Nav.clearance(p))
	return clampf(room, 0.0, 2.55)


# The ground's height under him out here: the lot level with the floor inside, round the back and
# down the east side a step lower, the road, the steps down through the seawall, the beach going
# down to the water.
static func ground_y(x: float, z: float) -> float:
	# up the old main street the ground is the street's, rising off the highway
	if x < -185.0 and z < WALL_Z.x - 0.4:
		return Town.ground_y(x, z) + 0.02
	if z > WALL_Z.y:
		var t := clampf((z - WALL_Z.y) / 8.6, 0.0, 1.0)
		return lerpf(-0.24, -0.4, t) + 0.025 * sin(x * 0.61 + z * 0.37)
	if z > WALL_Z.x - 0.4 and x > STEP_X.x and x < STEP_X.y:
		return lerpf(0.0, -0.24, clampf((z - (WALL_Z.x - 0.4)) / 0.9, 0.0, 1.0))
	if z >= 10.4:
		return 0.0
	if z > 10.1:
		return lerpf(_low(x, 10.1), 0.0, (z - 10.1) / 0.3)
	return _low(x, z)


# round the back and down the sides: the town's lie of the land (world/town.gd) just under the
# gravel, and down the east side the Sov's own gravel a step below the lot (world/pub.gd)
static func _low(x: float, z: float) -> float:
	var y := Town.ground_y(x, z) + 0.02
	if x > 16.0 and x < 30.0 and z > -3.0:
		y = maxf(y, -0.25)
	return y


# Whether a part of the world (Hotspots.zone_of) is out of doors at the Sov, where he walks out here.
static func outdoor_zone(zone: String) -> bool:
	return zone in ["lot", "yard", "town"]


# Out of doors past where Nav's map goes: round the back, across the road, down at the Esso. A walk
# the night takes him on from out here starts with the page going blank (game/view.gd).
static func far_out(p: Vector3) -> bool:
	var z := Hotspots.zone_of(Vector3(p.x, 1.0 + ground_y(p.x, p.z), p.z))
	if z == "yard" or z == "town":
		return true
	return z == "lot" and not LOT.grow(-0.3).has_point(Vector2(p.x, p.z))


# Round the back of the building or down the east side of it, out of doors: not the lot in front,
# not across the highway, not inside.
static func in_yard(p: Vector3) -> bool:
	if p.y > 3.3 or p.y < -1.2:
		return false
	if p.x > 18.45 and p.z < 10.15 and not (p.x < 19.9 and p.z < 0.9 and p.z > -2.95):
		return true
	if p.z < -2.95 and p.x > -12.0 and p.x < 33.0:
		return true
	if p.x < -0.25 and p.z < 3.85 and p.x > -12.0:
		return true
	return p.x < -6.6 and p.z < 10.15 and p.x > -12.0


# which part of the grounds a spot's in, by name (for the names and the voices)
static func area_of(p: Vector3) -> String:
	var q := Vector2(p.x, p.z)
	if q.y > WALL_Z.x - 0.1 and q.y < WALL_Z.y + 0.8 and q.x > STEP_X.x - 0.6 and q.x < STEP_X.y + 0.6:
		return "beach"
	if q.y > WALL_Z.y:
		return "beach"
	if q.y > 33.4 and q.x > -40.0 and q.x < 50.0:
		return "seawall"
	if q.x < -131.0 and q.y < 28.0:
		return "esso"
	if q.y > 26.4:
		return "road" if q.x > -26.0 else "shoulder"
	if q.x < -14.0 and q.y > 24.0:
		return "shoulder"
	if q.x < -0.25 and q.y < 10.1:
		return "alley"
	if q.y < -2.95:
		return "back"
	if q.x > 18.45 and q.y < 10.1:
		return "side"
	return "lot"


# ---------------------------------------------------------------- built

func build_for(p: Pub) -> void:
	pub = p
	rng.seed = 2026
	_layout()
	_materials()
	_hotel_back()
	_yard()
	_alley()
	_side()
	_lot_things()
	_seawall()
	_beach()
	_shoulder()
	_esso_night()
	_main_finds()
	_traffic()
	visible = false
	if pub.dyn.has("rain"):
		_rain_home = (pub.dyn.rain as Node3D).position


func _materials() -> void:
	M.rust = pub.mat(Color("6a4a36"), 0.8, 0.3, 2, Vector3.UP, 5.0, 0.9)
	M.green = pub.mat(Color("3e5244"), 0.7, 0.2, 2, Vector3.UP, 5.0, 0.9)          # the dumpster's old paint
	M.blue = pub.mat(Color("3d5266"), 0.5, 0.0, 0, Vector3.UP, 6.0, 0.8)
	M.stone = pub.mat(Color("57534c"), 0.9, 0.0, 0, Vector3.UP, 6.0, 0.7)
	M.sand = pub.mat(Color("3e3a33"), 0.95, 0.0, 1, Vector3(1, 0, 0.3), 7.0, 0.35)
	M.wet_sand = pub.mat(Color("2a2925"), 0.2, 0.1, 1, Vector3(1, 0, 0.3), 7.0, 0.2)
	M.drift = pub.mat(Color("8d877b"), 0.9, 0.0, 1, Vector3(1, 0, 0), 5.0, 0.9)    # logs gone silver
	M.kelp = pub.mat(Color("2c2a1c"), 0.3, 0.0, 1, Vector3(1, 0, 0.2), 6.0, 0.4)
	M.ash = pub.mat(Color("2a2725"), 0.95, 0.0, 0, Vector3.UP, 7.0, 0.2)
	M.ember = pub.glow(Color("ff5a1a"), 1.6)
	M.fence = pub.mat(Color("6c706e"), 0.5, 0.6, 2, Vector3.UP, 4.0, 1.0)
	M.mesh = pub.glass(Color("8a8f8c"), 0.18)                                        # chain-link, seen through
	M.bramble = pub.mat(Color("1d211c"), 0.9, 0.0, 0, Vector3.UP, 6.0, 0.6)
	M.white = pub.mat(Color("d8d4ca"), 0.7, 0.0, 0, Vector3.UP, 6.0, 0.9)
	M.rose = pub.mat(Color("8a2a34"), 0.6, 0.0, 0, Vector3.UP, 6.0, 0.8)
	M.bug = pub.glow(Color("ffd070"), 3.2)                                           # a yellow bug bulb
	M.bare = pub.glow(Color("ffcf90"), 5.0)                                          # a bare bulb, old
	M.lit_win = pub.glow(Color("ffc27a"), 1.2)
	M.tv_blue = pub.glow(Color("8fb4c8"), 0.9)
	M.paper = pub.M.paper
	M.tar = pub.mat(Color("232224"), 0.6, 0.0, 1, Vector3(1, 0, 0), 7.0, 0.3)


func b(size: Vector3, pos: Vector3, m: Material, rot := 0.0, parent: Node = null) -> MeshInstance3D:
	return pub.box(size, pos, m, rot, parent if parent != null else self)


func c(rt: float, rb: float, h: float, pos: Vector3, m: Material, seg := 12, parent: Node = null) -> MeshInstance3D:
	return pub.cyl(rt, rb, h, pos, m, parent if parent != null else self, seg)


# a footprint from BOXES as a box h high off the ground, in m
func _foot(key: String, h: float, m: Material) -> MeshInstance3D:
	var f: Array = BOXES[key]
	var mid: Vector2 = f[0]
	var half: Vector2 = f[1]
	var y0 := ground_y(mid.x, mid.y) - 0.02
	return b(Vector3(half.x * 2.0, h, half.y * 2.0), Vector3(mid.x, y0 + h / 2.0, mid.y), m, -float(f[2]))


# the ground's height at x, z, for putting things on it
func g(x: float, z: float) -> float:
	return ground_y(x, z)


# gravel over a rectangle of the ground, in squares that each sit on the land where they are
func _gravel(r: Rect2, m: Material) -> void:
	var nx := maxi(1, ceili(r.size.x / 2.0))
	var nz := maxi(1, ceili(r.size.y / 2.0))
	var sx := r.size.x / nx
	var sz := r.size.y / nz
	for i in nx:
		for j in nz:
			var cx := r.position.x + sx * (i + 0.5)
			var cz := r.position.y + sz * (j + 0.5)
			var y := ground_y(cx, cz)
			b(Vector3(sx + 0.06, 0.12, sz + 0.06), Vector3(cx, y - 0.06, cz), m)


# a stick from a to b, r thick
func _stick(a: Vector3, z: Vector3, r: float, m: Material, parent: Node = null) -> MeshInstance3D:
	var mi := c(r, r, a.distance_to(z), (a + z) / 2.0, m, 6, parent)
	var d := (z - a).normalized()
	if absf(d.dot(Vector3.UP)) < 0.999:
		mi.basis = Basis(Quaternion(Vector3.UP, d))
	return mi


func _light(pos: Vector3, col: Color, e: float, r: float, flicker := 0.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = e
	l.omni_range = r
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	add_child(l)
	if flicker > 0.0:
		_flicker.append([l, e, flicker])
	return l


func _label(text: String, pos: Vector3, h: float, col: Color, rot_y := 0.0, parent: Node = null) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = Look.font("ui_b")
	l.font_size = 64
	l.pixel_size = h / 64.0
	l.outline_size = 0
	l.modulate = col
	l.shaded = true
	l.double_sided = false
	l.position = pos
	l.rotation.y = deg_to_rad(rot_y)
	(parent if parent != null else self).add_child(l)
	return l


func _anchor(name: String, at: Vector3) -> void:
	pub.anchors[name] = at


# ---------------------------------------------------------------- the hotel from behind

# The Sovereign from round the back: its back wall three storeys up, the upper floors' west side
# hanging out a little past the kitchen's, the lobby a storey with a flat roof, the tar roof and
# what's on it. Rooms' windows dark but one, with a TV going in it, and the fire escape coming down
# to a ladder that stops two metres off the ground.
func _hotel_back() -> void:
	var zb := -2.88
	var top := 9.8
	# the back wall, outside: the old boards, up to the roof over the building, and the lobby's
	pub.wall(Vector2(-0.62, zb), Vector2(16.62, zb), top, pub.M.paint, [], 0.0, 0.06)
	pub.wall(Vector2(16.62, zb), Vector2(19.92, zb), 3.2, pub.M.siding, [], 0.0, 0.06)
	# the west side: the kitchen's wall at the ground with its back door, and over it the upper
	# floors, hung out a little past it on the old joists
	pub.wall(Vector2(-0.24, zb), Vector2(-0.24, 3.86), 2.6, pub.M.siding, [[0.95, 1.75, 0.0, 2.05]], 0.0, 0.05)
	pub.wall(Vector2(-0.62, zb), Vector2(-0.62, 3.86), top - 2.6, pub.M.paint, [], 2.6, 0.06)
	pub.wall(Vector2(-0.62, 3.86), Vector2(-0.62, 10.12), top - 3.55, pub.M.paint, [], 3.55, 0.06)
	b(Vector3(0.4, 0.08, 6.74), Vector3(-0.42, 2.62, 0.49), pub.M.dark)
	# the east side, over the lobby (the rest of it is over the deck: world/pub.gd)
	pub.wall(Vector2(16.32, zb), Vector2(16.32, -0.1), top - 3.2, pub.M.siding, [], 3.2, 0.05)
	# the lobby's flat roof, and its edge
	b(Vector3(3.6, 0.14, 3.86), Vector3(18.12, 3.25, -1.0), M.tar)
	b(Vector3(3.62, 0.22, 0.06), Vector3(18.12, 3.32, 0.93), pub.M.dark)
	b(Vector3(0.06, 0.22, 3.86), Vector3(19.94, 3.32, -1.0), pub.M.dark)
	# the roof: tar, flat, a lip round it, the chimney, two vent stacks, the dish
	b(Vector3(17.4, 0.16, 13.2), Vector3(8.0, top + 0.06, 3.62), M.tar)
	for e in [[Vector3(17.4, 0.4, 0.12), Vector3(8.0, top + 0.2, zb)], [Vector3(0.12, 0.4, 13.0), Vector3(-0.66, top + 0.2, 3.62)],
			[Vector3(0.12, 0.4, 13.0), Vector3(16.66, top + 0.2, 3.62)]]:
		b(e[0], e[1], pub.M.dark)
	b(Vector3(0.9, 1.8, 0.7), Vector3(2.6, top + 0.9, -1.4), pub.M.brick, 3.0)
	b(Vector3(1.02, 0.12, 0.82), Vector3(2.6, top + 1.84, -1.4), pub.M.concrete, 3.0)
	for v in [Vector3(7.4, 0, 0.2), Vector3(12.9, 0, -1.9)]:
		c(0.07, 0.07, 0.9, Vector3(v.x, top + 0.45, v.z), pub.M.steel, 8)
		c(0.11, 0.11, 0.06, Vector3(v.x, top + 0.93, v.z), pub.M.steel, 8)
	var dish := c(0.38, 0.05, 0.12, Vector3(14.6, 7.4, zb - 0.32), pub.M.porcelain, 16)
	dish.rotation = Vector3(deg_to_rad(-70.0), deg_to_rad(12.0), 0.0)
	b(Vector3(0.04, 0.04, 0.36), Vector3(14.6, 7.3, zb - 0.16), pub.M.steel)
	# the rooms' windows: two floors, dark, the blinds of one broken; one with a TV's light
	var k := 0
	for row in [4.6, 7.9]:
		for x in [1.6, 4.4, 7.2, 10.0, 12.8, 15.4]:
			var m: Material = pub.M.black
			if k == 7:
				m = M.tv_blue
			elif k == 3:
				m = M.lit_win
			var w := b(Vector3(1.0, 1.25, 0.04), Vector3(x + rng.randf_range(-0.05, 0.05), row, zb - 0.04), m)
			w.rotation.z = deg_to_rad(rng.randf_range(-0.6, 0.6))
			b(Vector3(1.14, 0.08, 0.12), Vector3(x, row - 0.67, zb - 0.07), pub.M.wood)
			k += 1
	var tv := _light(Vector3(10.0, 7.9, zb - 1.2), Color("9fc4dc"), 0.5, 4.5, 2.5)
	tv.light_cull_mask = 1
	# the fire escape down the back: landings at each floor, and a ladder that stops short
	for fy in [4.0, 7.3]:
		b(Vector3(2.2, 0.05, 0.95), Vector3(5.8, fy - 0.9, zb - 0.5), pub.M.frame)
		b(Vector3(2.2, 0.9, 0.03), Vector3(5.8, fy - 0.45, zb - 0.97), pub.M.frame)
		b(Vector3(0.03, 0.9, 0.95), Vector3(6.9, fy - 0.45, zb - 0.5), pub.M.frame)
	for lx in [6.55, 6.85]:
		b(Vector3(0.03, 3.4, 0.03), Vector3(lx, 3.1 - 1.7 + 1.1, zb - 0.8), pub.M.frame)
	var ry := 2.2
	while ry < 4.9:
		b(Vector3(0.3, 0.025, 0.025), Vector3(6.7, ry, zb - 0.8), pub.M.frame)
		ry += 0.3
	# a clothesline from the fire escape to a post at the fence, a shirt still on it in the rain
	var post := Vector3(9.0, g(9.0, -12.4), -12.4)
	c(0.05, 0.06, 2.6, post + Vector3(0, 1.05, 0), pub.M.wood, 6)
	_stick(Vector3(6.0, 3.15, zb - 0.95), post + Vector3(0, 2.3, 0), 0.006, pub.M.black)
	var shirt := b(Vector3(0.5, 0.62, 0.02), Vector3(7.3, 2.45, -6.6), M.white, -78.0)
	shirt.rotation.z = deg_to_rad(6.0)
	# the hotel's name painted on the back wall in the fifties, mostly gone
	_label("SOVEREIGN HOTEL  ·  ROOMS", Vector3(8.0, 2.95, zb - 0.07), 0.42, Color(0.6, 0.55, 0.48, 0.55), 180.0)
	_anchor("hotel_back", Vector3(8.0, 5.0, zb))


# ---------------------------------------------------------------- the yard behind

# Round the back: the gravel a step below the lot, the hill coming down to a chain-link fence with a
# gap in it where a trail goes up into the firs; the grease trap's lid, somebody's chest freezer
# padlocked and humming on an orange cord, a TV with its screen kicked in, a car on blocks, a
# mattress, a shopping cart. The rats' way out of the crawlspace under the kitchen, and what's been
# laid out in front of it.
func _yard() -> void:
	# the gravel: round the back, the alley, west of the beer store, and out past the deck
	_gravel(Rect2(-11.0, -13.6, 43.0, 10.75), pub.M.gravel)
	_gravel(Rect2(-11.0, -2.9, 10.8, 13.05), pub.M.gravel)
	_gravel(Rect2(29.9, -3.0, 2.2, 13.1), pub.M.gravel)
	# the hill behind, coming down to the fence (the land's the town's): bramble along the foot of
	# it, a few firs
	for i in 34:
		var x := -12.0 + i * 1.32 + rng.randf_range(-0.4, 0.4)
		var s := rng.randf_range(0.7, 1.5)
		pub.ball(s, Vector3(x, g(x, -14.2) + s * 0.3 + 0.12 * (i % 3), -14.0 - rng.randf_range(0.0, 1.2)), M.bramble, self).scale = Vector3(1.4, 0.8, 1.0)
	for f in [Vector3(-7.0, 0, -18.0), Vector3(2.0, 0, -21.0), Vector3(12.5, 0, -17.5), Vector3(21.0, 0, -22.0), Vector3(28.0, 0, -16.5)]:
		var h := rng.randf_range(11.0, 16.0)
		var y0 := Town.ground_y(f.x, f.z)
		c(0.16, 0.22, h * 0.35, Vector3(f.x, y0 + h * 0.17, f.z), pub.M.dark, 6)
		for k in 3:
			var hh := h * (0.48 - 0.08 * k)
			c(0.0, h * 0.2 * (1.0 - 0.24 * k), hh, Vector3(f.x, y0 + h * (0.2 + 0.23 * k) + hh / 2.0, f.z), M.bramble, 7)
	# the chain-link fence along the foot of the hill, sagging, with a gap where it's been cut and
	# pulled back; posts every three metres, none quite plumb
	var x := -10.0
	while x < 31.0:
		var x1 := x + 3.0
		var lean := rng.randf_range(-3.5, 3.5)
		var p := c(0.03, 0.03, 1.9, Vector3(x, g(x, -13.2) + 0.9, -13.2), M.fence, 6)
		p.rotation.z = deg_to_rad(lean)
		if not (x >= 5.0 and x < 8.0):
			var mesh := b(Vector3(3.0, 1.75 - rng.randf_range(0.0, 0.25), 0.01), Vector3((x + x1) / 2.0, g(x + 1.5, -13.2) + 0.85, -13.2), M.mesh)
			_stick(Vector3(x, g(x, -13.2) + 1.72, -13.2), Vector3(x1, g(x1, -13.2) + 1.66, -13.2), 0.02, M.fence)
			mesh.rotation.x = deg_to_rad(rng.randf_range(-4.0, 4.0))
		else:
			var flap := b(Vector3(1.4, 1.6, 0.01), Vector3(x + 0.7, g(x + 0.7, -12.6) + 0.8, -12.6), M.mesh, 38.0)
			flap.rotation.z = deg_to_rad(4.0)
		x = x1
	_anchor("fence", Vector3(14.0, 0.8, -13.2))
	# the trail up through the gap, worn into the hill
	var trail := b(Vector3(1.0, 0.05, 9.0), Vector3(6.6, Town.ground_y(6.6, -17.5) + 0.03, -17.5), pub.M.dirt)
	trail.rotation.x = atan2(Town.ground_y(6.6, -22.0) - Town.ground_y(6.6, -13.0), 9.0)
	_anchor("trail", Vector3(6.6, 1.2, -15.0))
	# the grease trap's lid, round, iron, set in the gravel
	c(0.42, 0.42, 0.03, Vector3(10.2, g(10.2, -5.0) + 0.012, -5.0), pub.M.frame, 18)
	# somebody's chest freezer against the back wall, padlocked, humming, on an orange cord that goes
	# in under the kitchen window
	_foot("freezer", 0.86, M.white)
	b(Vector3(1.6, 0.05, 0.84), Vector3(11.6, g(11.6, -3.45) + 0.86, -3.45), M.white, 2.0)
	b(Vector3(0.08, 0.12, 0.05), Vector3(11.6, g(11.6, -3.45) + 0.74, -3.88), pub.M.steel)
	_stick(Vector3(10.85, g(10.85, -3.2) + 0.4, -3.2), Vector3(10.3, g(10.3, -3.0) + 0.01, -3.0), 0.008, pub.M.yellow)
	_stick(Vector3(10.3, g(10.3, -3.0) + 0.01, -3.0), Vector3(9.0, 0.9, -2.93), 0.008, pub.M.yellow)
	_anchor("back_freezer", Vector3(11.6, 0.7, -3.45))
	# a TV face down with its screen kicked in, a car on blocks, a mattress against the fence, a cart
	_foot("tv", 0.5, pub.M.black)
	b(Vector3(0.5, 0.36, 0.02), Vector3(15.2, g(15.2, -5.2) + 0.25, -4.92), pub.M.glass, 20.0)
	_anchor("back_tv", Vector3(15.2, 0.1, -5.2))
	var car := Node3D.new()
	car.position = Vector3(27.0, g(27.0, -4.0) - 0.02, -4.0)
	car.rotation.y = deg_to_rad(4.0)
	add_child(car)
	b(Vector3(1.8, 0.62, 4.3), Vector3(0, 0.7, 0), M.rust, 0.0, car)
	b(Vector3(1.62, 0.5, 2.1), Vector3(0, 1.26, 0.25), M.rust, 0.0, car)
	b(Vector3(1.56, 0.42, 0.02), Vector3(0, 1.26, -0.82), pub.M.black, 0.0, car)
	for s in [Vector2(-0.8, -1.4), Vector2(0.8, -1.4), Vector2(-0.8, 1.4), Vector2(0.8, 1.4)]:
		b(Vector3(0.36, 0.38, 0.36), Vector3(s.x, 0.19, s.y), pub.M.concrete, 0.0, car)
	var wheel := c(0.33, 0.33, 0.22, Vector3(28.6, g(28.6, -6.4) + 0.1, -6.4), pub.M.black, 14)
	wheel.rotation.z = PI / 2.0
	_anchor("blocks_car", Vector3(27.0, 1.0, -4.0))
	var mat := _foot("mattress", 1.85, M.white)
	mat.rotation.x = deg_to_rad(-9.0)
	_anchor("mattress", Vector3(22.0, 0.8, -12.6))
	_cart(Vector3(26.3, g(26.3, -9.2), -9.2), 33.0, 0.0)
	# the rats' way out: under the kitchen, a vent in the foundation with its grille bent out, the
	# gravel worn smooth from it to the dumpster round the corner, and in front of it, laid out in a
	# spiral the size of a dinner plate, bottle caps, every one face up
	b(Vector3(0.46, 0.22, 0.04), Vector3(3.4, -0.08, -2.92), pub.M.black)
	var gr := b(Vector3(0.44, 0.2, 0.012), Vector3(3.4, -0.06, -3.0), pub.M.steel)
	gr.rotation.x = deg_to_rad(28.0)
	_anchor("vent", Vector3(3.4, -0.05, -2.95))
	var a := 0.0
	var r := 0.03
	for i in 26:
		a += 0.62
		r += 0.0085
		var cap := c(0.0145, 0.0145, 0.007, Vector3(3.4 + cos(a) * r, g(3.4, -3.42) + 0.004, -3.42 + sin(a) * r), pub.M.steel if i % 4 else pub.M.brass, 8)
		cap.rotation.y = a
	_anchor("caps", Vector3(3.4, g(3.4, -3.42) + 0.05, -3.42))
	# the run, worn into the gravel along the foot of the wall to the alley
	b(Vector3(3.8, 0.004, 0.16), Vector3(1.4, g(1.4, -3.05) + 0.003, -3.05), pub.M.dirt)
	# a bare bulb in a cage high on the back wall over the freezer: the only light back here
	b(Vector3(0.14, 0.14, 0.12), Vector3(11.0, 2.6, -2.96), pub.M.frame)
	pub.ball(0.04, Vector3(11.0, 2.55, -3.02), M.bare, self)
	_light(Vector3(11.0, 2.5, -3.3), Color("ffbf80"), 0.9, 7.0, 1.2)


func _cart(at: Vector3, yaw: float, tip: float) -> void:
	var n := Node3D.new()
	n.position = at
	n.rotation = Vector3(0, deg_to_rad(yaw), deg_to_rad(tip))
	add_child(n)
	b(Vector3(0.56, 0.02, 0.86), Vector3(0, 0.55, 0), M.fence, 0.0, n)
	for s in [-1.0, 1.0]:
		b(Vector3(0.012, 0.42, 0.86), Vector3(s * 0.28, 0.76, 0), M.fence, 0.0, n)
	b(Vector3(0.56, 0.42, 0.012), Vector3(0, 0.76, 0.43), M.fence, 0.0, n)
	b(Vector3(0.56, 0.42, 0.012), Vector3(0, 0.76, -0.43), M.fence, 0.0, n)
	b(Vector3(0.6, 0.03, 0.03), Vector3(0, 1.02, -0.55), pub.M.dark, 0.0, n)
	for s in [Vector2(-0.24, -0.36), Vector2(0.24, -0.36), Vector2(-0.24, 0.36), Vector2(0.24, 0.36)]:
		b(Vector3(0.02, 0.5, 0.02), Vector3(s.x, 0.28, s.y), M.fence, 0.0, n)
		c(0.05, 0.05, 0.03, Vector3(s.x, 0.05, s.y), pub.M.black, 8, n).rotation.z = PI / 2.0


# ---------------------------------------------------------------- the alley

# Between the kitchen and the beer store: the kitchen's back door propped with a brick for the
# fryer's heat, a bulb over it, the cook's milk crate and his coffee can of butts, the dumpster
# against the store's back wall, the grease drums, pallets, the blue bins with the bar's empties.
func _alley() -> void:
	# the kitchen door, propped open on a brick, the light of the kitchen in it
	var door := Node3D.new()
	door.position = Vector3(-0.24, 0, -1.94)
	door.rotation.y = deg_to_rad(-62.0)
	add_child(door)
	b(Vector3(0.05, 2.02, 0.84), Vector3(-0.03, 1.01, 0.42), pub.M.steel, 0.0, door)
	b(Vector3(0.22, 0.07, 0.11), Vector3(-0.45, 0.035, -1.12), pub.M.brick, 12.0)
	b(Vector3(0.76, 0.25, 1.16), Vector3(-0.45, -0.125, -1.54), pub.M.concrete)
	b(Vector3(0.02, 1.95, 0.78), Vector3(-0.2, 1.0, -1.54), pub.glow(Color("cfeedd"), 0.5))
	_anchor("kitchen_door", Vector3(-0.3, 1.2, -1.54))
	# the bulb over it in a cage
	b(Vector3(0.14, 0.14, 0.14), Vector3(-0.36, 2.35, -1.54), pub.M.frame)
	pub.ball(0.045, Vector3(-0.42, 2.3, -1.54), M.bare, self)
	_light(Vector3(-0.8, 2.25, -1.54), Color("ffc890"), 1.3, 6.5, 0.6)
	# the cook's milk crate, upside down, and his coffee can of butts beside it
	_foot("crate", 0.3, M.blue)
	c(0.07, 0.07, 0.16, Vector3(-1.75, g(-1.75, -2.35) + 0.08, -2.35), pub.M.steel, 10)
	for i in 5:
		var butt := c(0.005, 0.005, 0.03, Vector3(-1.6 + rng.randf_range(-0.4, 0.4), g(-1.6, -2.2) + 0.006, -2.2 + rng.randf_range(-0.4, 0.4)), M.white, 5)
		butt.rotation = Vector3(PI / 2.0, rng.randf() * TAU, 0)
	_anchor("cook_crate", Vector3(-1.35, 0.1, -2.6))
	# the dumpster against the store's back wall, lid up on one side, rust down its corners
	var dm := _foot("dumpster", 1.15, M.green)
	dm.name = "dumpster"
	var dy := g(-3.4, 3.12) + 0.23
	var lid := b(Vector3(1.0, 0.04, 1.26), Vector3(-3.9, dy + 1.05, 2.6), pub.M.black, -3.0)
	lid.rotation.z = deg_to_rad(-52.0)
	b(Vector3(1.0, 0.04, 1.26), Vector3(-2.88, dy + 0.92, 3.12), pub.M.black, -3.0)
	for cx in [-4.35, -2.45]:
		b(Vector3(0.1, 1.0, 0.04), Vector3(cx, dy + 0.35, 2.49), M.rust, -3.0)
	b(Vector3(0.7, 0.3, 0.4), Vector3(-4.0, dy + 1.0, 2.9), pub.M.black, 20.0)
	_anchor("dumpster", Vector3(-3.4, 0.9, 3.0))
	# the grease drums, the pallets against the store, the blue bins
	for z in [-0.92, -0.28]:
		c(0.3, 0.3, 0.88, Vector3(-5.95, g(-5.95, z) + 0.42, z), M.blue, 14)
		c(0.31, 0.31, 0.03, Vector3(-5.95, g(-5.95, z) + 0.87, z), pub.M.dark, 14)
	_anchor("drums", Vector3(-5.95, 0.6, -0.6))
	for i in 4:
		var pl := b(Vector3(0.12, 1.2, 1.2), Vector3(-6.32 + i * 0.13, g(-6.3, 2.6) + 0.56, 2.6), pub.M.wood)
		pl.rotation.z = deg_to_rad(-14.0 + i * 1.6)
	for z in [1.05, 2.15]:
		b(Vector3(0.66, 0.95, 0.6), Vector3(-1.1, g(-1.1, z) + 0.46, z), M.blue)
		b(Vector3(0.7, 0.05, 0.64), Vector3(-1.1, g(-1.1, z) + 0.95, z), pub.M.dark)
	# the beer store's back door, shut, a sign on it
	b(Vector3(0.9, 2.05, 0.05), Vector3(-1.6, g(-1.6, 3.6) + 1.0, 3.84), pub.M.steel)
	_label("NO PARKING  DELIVERIES", Vector3(-1.6, 1.75, 3.83), 0.08, Color(0.85, 0.82, 0.75), 180.0)


# ---------------------------------------------------------------- down the east side

# The hotel's own front door, shut for the night, under a yellow bug bulb: the urn of sand by it, the
# buzzers on the wall with the rooms' names, the newspaper box, a bike locked to the downpipe with
# its front wheel gone.
func _side() -> void:
	# the porch bulb, yellow, the kind that keeps the moths off, and doesn't
	pub.ball(0.05, Vector3(18.875, 2.38, 1.0), M.bug, self)
	b(Vector3(0.16, 0.06, 0.12), Vector3(18.875, 2.46, 0.94), pub.M.frame)
	_light(Vector3(18.875, 2.2, 1.6), Color("ffcf6a"), 1.0, 5.5, 0.0)
	# the buzzers: a brass plate by the door, a column of buttons, the names in their slots
	b(Vector3(0.2, 0.42, 0.02), Vector3(19.58, 1.45, 0.89), pub.M.brass)
	for i in 12:
		pub.ball(0.007, Vector3(19.64, 1.63 - i * 0.032, 0.905), pub.M.black, self)
		b(Vector3(0.1, 0.022, 0.004), Vector3(19.55, 1.63 - i * 0.032, 0.902), M.paper if i != 6 else pub.M.brass)
	_anchor("buzzers", Vector3(19.58, 1.45, 0.96))
	# the urn of sand, a hundred butts in it
	c(0.17, 0.2, 0.62, Vector3(19.55, 0.06, 1.55), pub.M.dark, 12)
	c(0.18, 0.18, 0.02, Vector3(19.55, 0.38, 1.55), M.ash, 12)
	_anchor("hotel_urn", Vector3(19.55, 0.4, 1.55))
	# the newspaper box, the paper in its window
	var nb := _foot("news_box", 1.0, M.blue)
	nb.name = "news_box"
	b(Vector3(0.36, 0.3, 0.01), Vector3(20.75, 0.48, 1.705), pub.M.glass, 6.0)
	b(Vector3(0.32, 0.26, 0.005), Vector3(20.75, 0.48, 1.7), M.paper, 6.0)
	_anchor("news_box", Vector3(20.75, 0.5, 1.6))
	# the bike locked to the downpipe at the lobby's corner, no front wheel
	c(0.04, 0.04, 3.3, Vector3(19.96, 1.4, 0.75), pub.M.steel, 8)
	var bk := Node3D.new()
	bk.position = Vector3(20.05, -0.25, -1.0)
	add_child(bk)
	var rear := c(0.33, 0.33, 0.03, Vector3(0, 0.33, 0.55), pub.M.black, 16, bk)
	rear.rotation.z = PI / 2.0
	_stick(Vector3(0, 0.33, 0.55), Vector3(0, 0.82, -0.05), 0.016, M.rust, bk)
	_stick(Vector3(0, 0.82, -0.05), Vector3(0, 0.5, -0.62), 0.016, M.rust, bk)
	_stick(Vector3(0, 0.5, -0.62), Vector3(0, 0.0, -0.78), 0.016, M.rust, bk)
	b(Vector3(0.08, 0.04, 0.22), Vector3(0, 0.92, 0.42), pub.M.black, 0.0, bk)


# ---------------------------------------------------------------- the lot's own things

# Out front: the rats' gap in the skirting under the window by table 28, with the grease off their
# backs round it; the posters stapled up the lamp pole.
func _lot_things() -> void:
	# under the front window, at the foot of the wall, the boards' bottom edge chewed out to a gap
	b(Vector3(0.22, 0.09, 0.03), Vector3(9.62, 0.045, 10.19), pub.M.black, 0.0, pub)
	b(Vector3(0.4, 0.14, 0.008), Vector3(9.62, 0.08, 10.215), M.ash, 0.0, pub)
	_anchor("rat_gap", Vector3(9.62, 0.06, 10.22))
	# the posters on the pole, layered, stapled over each other, the rain in them
	var posters := [[0.0, 1.55, 0.3, 0.4, M.paper], [25.0, 1.4, 0.28, 0.36, M.white], [-30.0, 1.7, 0.24, 0.3, M.paper],
		[160.0, 1.5, 0.3, 0.42, M.white], [200.0, 1.25, 0.22, 0.28, M.paper]]
	for p in posters:
		var a := deg_to_rad(float(p[0]))
		var at := Vector3(15.8 - sin(a) * 0.1, p[1], 21.5 - cos(a) * 0.1)
		var pm := b(Vector3(p[2], p[3], 0.004), at, p[4], float(p[0]) + 180.0, pub)
		pm.rotation.z = deg_to_rad(rng.randf_range(-5.0, 5.0))
	_anchor("lot_pole", Vector3(15.8, 1.5, 21.4))


# ---------------------------------------------------------------- the seawall

# The wall's own things: the plaque on its road side, the gap with the steps down through it, and
# the man fishing off it with a bucket at his feet.
func _seawall() -> void:
	# the steps: three, concrete, worn, down through the gap to the beach
	for k in 3:
		var y := -0.08 - k * 0.08
		b(Vector3(STEP_X.y - STEP_X.x, 0.1, 0.34), Vector3((STEP_X.x + STEP_X.y) / 2.0, y - 0.05, 35.7 + k * 0.32), pub.M.concrete)
	# a pipe rail down one side
	_stick(Vector3(STEP_X.y - 0.08, 0.95, 35.45), Vector3(STEP_X.y - 0.08, 0.7, 36.65), 0.02, pub.M.steel)
	for z in [35.45, 36.65]:
		_stick(Vector3(STEP_X.y - 0.08, 0.95 if z < 36 else 0.7, z), Vector3(STEP_X.y - 0.08, -0.25, z), 0.02, pub.M.steel)
	_anchor("sea_steps", Vector3((STEP_X.x + STEP_X.y) / 2.0, 0.2, 36.0))
	# the plaque on the road side of the wall, by the steps
	b(Vector3(0.6, 0.36, 0.02), Vector3(12.4, 0.36, WALL_Z.x - 0.01), pub.M.brass)
	_label("THIS WALL WAS BUILT IN 1958", Vector3(12.4, 0.44, WALL_Z.x - 0.025), 0.03, Color(0.25, 0.2, 0.12), 180.0)
	_label("BY THE MEN OF LOCAL 14", Vector3(12.4, 0.38, WALL_Z.x - 0.025), 0.03, Color(0.25, 0.2, 0.12), 180.0)
	_label("TO HOLD BACK THE SEA", Vector3(12.4, 0.31, WALL_Z.x - 0.025), 0.03, Color(0.25, 0.2, 0.12), 180.0)
	_anchor("plaque", Vector3(12.4, 0.36, WALL_Z.x))
	# Merle, fishing off the wall in the rain with nothing on his hook: standing at the wall, facing
	# the water, the rod out over it, the bucket at his feet with nothing in it
	var man := pub.model("res://models/people/patron_c.glb", Vector3(2.0, 0.0, 35.12), self)
	man.rotation.y = PI
	man.name = "merle"
	var hand := Vector3(2.12, 1.12, 35.42)
	var tip := Vector3(2.35, 2.25, 37.4)
	_stick(hand + Vector3(0, -0.3, -0.25), tip, 0.01, pub.M.black)
	_stick(tip, Vector3(2.4, -0.39, 38.6), 0.0015, pub.M.porcelain)
	c(0.16, 0.13, 0.32, Vector3(2.75, 0.16, 35.2), M.white, 12)
	_anchor("merle", Vector3(2.0, 1.45, 35.12))
	# a lantern on the wall's top beside him, kerosene, low
	c(0.06, 0.07, 0.2, Vector3(1.3, 0.75, 35.9), pub.M.frame, 8)
	pub.ball(0.04, Vector3(1.3, 0.78, 35.9), M.bug, self)
	_night_only.append(man)
	_night_only.append(_light(Vector3(1.3, 1.0, 35.6), Color("ffb860"), 0.75, 4.0, 1.8))


# ---------------------------------------------------------------- the beach

# Down on the beach below the wall: sand and stones going down into the water, the riprap at the
# foot of the wall, logs gone silver washed up where the storms left them, the kelp line, a fire
# somebody left an hour ago still glowing, a shopping cart out in the tide, and the two rocky points
# that close it in.
func _beach() -> void:
	var x0 := -16.0
	var x1 := 42.0
	# the beach: one long slope from the foot of the wall down under the water, dry sand above the
	# tide line and wet below it
	var fall := atan2(0.16, 8.6)
	var dry := b(Vector3(x1 - x0, 0.12, 5.6), Vector3((x0 + x1) / 2.0, ground_y(12.0, 39.0) - 0.06, 39.0), M.sand)
	dry.rotation.x = fall
	var wet := b(Vector3(x1 - x0, 0.12, 6.0), Vector3((x0 + x1) / 2.0, ground_y(12.0, 44.6) - 0.065, 44.6), M.wet_sand)
	wet.rotation.x = fall
	# stones, scattered, more of them toward the wall
	for i in 140:
		var sx := rng.randf_range(x0, x1)
		var sz := WALL_Z.y + pow(rng.randf(), 1.8) * 9.0
		var s := rng.randf_range(0.04, 0.16)
		var st := pub.ball(s, Vector3(sx, ground_y(sx, sz) - s * 0.35, sz), M.stone, self)
		st.scale = Vector3(1.0, rng.randf_range(0.45, 0.8), rng.randf_range(0.8, 1.3))
	# the riprap along the foot of the wall, and the points either end
	for key in ["rock_a", "rock_b", "rock_c", "rock_d", "rock_e", "rock_f", "rock_g", "rock_h"]:
		var rr: Array = ROUNDS[key]
		var at: Vector2 = rr[0]
		var r: float = rr[1]
		var rock := pub.ball(r * 1.05, Vector3(at.x, ground_y(at.x, at.y) + r * 0.25, at.y), M.stone, self)
		rock.scale = Vector3(1.0, rng.randf_range(0.55, 0.85), rng.randf_range(0.8, 1.2))
		rock.rotation.y = rng.randf() * TAU
	for i in 22:
		var rx := rng.randf_range(x0 + 4.0, x1 - 4.0)
		if rx > STEP_X.x - 1.0 and rx < STEP_X.y + 1.0:
			continue
		var rs := rng.randf_range(0.22, 0.4)
		var rk := pub.ball(rs, Vector3(rx, ground_y(rx, 36.35) + rs * 0.1, WALL_Z.y + 0.18 + rng.randf_range(0.0, 0.25)), M.stone, self)
		rk.scale = Vector3(1.2, 0.7, 1.0)
	# the logs
	for key in ["log_a", "log_b", "log_c", "log_d", "log_e", "log_f"]:
		var f: Array = BOXES[key]
		var mid: Vector2 = f[0]
		var half: Vector2 = f[1]
		var lg := c(half.y * 0.95, half.y, half.x * 2.0, Vector3(mid.x, ground_y(mid.x, mid.y) + half.y * 0.8, mid.y), M.drift, 9)
		lg.rotation = Vector3(0, -deg_to_rad(float(f[2])), PI / 2.0)
		# a root ball on the end of the big one
		if key == "log_a":
			var rb := pub.ball(0.7, Vector3(mid.x + half.x * cos(deg_to_rad(float(f[2]))), 0.2, mid.y - half.x * sin(deg_to_rad(float(f[2])))), M.drift, self)
			rb.scale = Vector3(0.6, 1.0, 1.1)
	# the kelp line, where the last tide left it, ragged
	var kx := x0 + 1.0
	while kx < x1 - 1.0:
		var w := rng.randf_range(0.6, 2.2)
		var kz := 43.3 + sin(kx * 0.23) * 0.5 + rng.randf_range(-0.2, 0.2)
		var kl := b(Vector3(w, 0.015, rng.randf_range(0.18, 0.45)), Vector3(kx + w / 2.0, ground_y(kx, kz) + 0.01, kz), M.kelp, rng.randf_range(-25.0, 25.0))
		kl.name = "kelp"
		kx += w * rng.randf_range(0.7, 1.4)
	# and in it, a licence, face up
	b(Vector3(0.085, 0.003, 0.054), Vector3(-4.5, ground_y(-4.5, 44.0) + 0.02, 44.0), M.white, 23.0)
	_anchor("kelp", Vector3(-4.5, ground_y(-4.5, 44.0) + 0.04, 44.0))
	# the fire: a ring of stones, charred ends, embers still going, the logs round it for sitting
	var fc := Vector3(24.5, ground_y(24.5, 40.4), 40.4)
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf_range(-0.1, 0.1)
		var st := pub.ball(0.14, fc + Vector3(cos(a) * 0.5, 0.05, sin(a) * 0.5), M.stone, self)
		st.scale = Vector3(1.0, 0.7, 1.2)
	c(0.42, 0.42, 0.03, fc + Vector3(0, 0.01, 0), M.ash, 14)
	for i in 4:
		var a2 := TAU * i / 4.0 + 0.4
		var br := _stick(fc + Vector3(cos(a2) * 0.38, 0.02, sin(a2) * 0.38), fc + Vector3(cos(a2) * 0.05, 0.12, sin(a2) * 0.05), 0.035, pub.M.burn)
		br.name = "brand"
	for i in 7:
		pub.ball(rng.randf_range(0.02, 0.045), fc + Vector3(rng.randf_range(-0.16, 0.16), 0.04, rng.randf_range(-0.16, 0.16)), M.ember, self)
	_fire = _light(fc + Vector3(0, 0.35, 0), Color("ff7a30"), 0.8, 3.6, 3.0)
	_night_only.append(_fire)
	# two empties by the fire, and a sneaker, one
	for e in [Vector3(25.3, 0, 41.2), Vector3(23.6, 0, 39.9)]:
		var bt := c(0.03, 0.035, 0.24, Vector3(e.x, ground_y(e.x, e.z) + 0.035, e.z), pub.M.bottle, 8)
		bt.rotation = Vector3(PI / 2.0, rng.randf() * TAU, 0)
	b(Vector3(0.11, 0.09, 0.27), Vector3(26.9, ground_y(26.9, 40.9) + 0.045, 40.9), M.white, 40.0)
	_anchor("beach_fire", fc + Vector3(0, 0.2, 0))
	# the cart out in the tide, on its side
	_cart(Vector3(31.0, ground_y(31.0, 43.9) - 0.05, 43.9), 70.0, 80.0)
	_anchor("beach_cart", Vector3(31.0, 0.1, 43.9))
	_anchor("far_shore", Vector3(8.0, 8.0, 500.0))


# ---------------------------------------------------------------- the shoulder

# Down the shoulder toward the Esso: the white cross zip-tied to a guardrail post, plastic roses,
# a photograph gone white, a scarf; the guardrail itself, a short stretch of it where the road bends.
func _shoulder() -> void:
	var at := Vector3(-38.0, 0.0, 26.75)
	# the guardrail along there, on its posts
	var gx := -46.0
	while gx < -30.0:
		b(Vector3(0.1, 0.62, 0.1), Vector3(gx, 0.31, 26.55), pub.M.wood)
		gx += 2.0
	b(Vector3(16.2, 0.3, 0.05), Vector3(-38.1, 0.56, 26.6), pub.M.steel)
	# the cross, white, zip-tied to the post, leaning
	var cr := Node3D.new()
	cr.position = at + Vector3(0, 0, 0.12)
	cr.rotation = Vector3(deg_to_rad(-4.0), 0, deg_to_rad(6.0))
	add_child(cr)
	b(Vector3(0.06, 0.9, 0.04), Vector3(0, 0.45, 0), M.white, 0.0, cr)
	b(Vector3(0.44, 0.06, 0.04), Vector3(0, 0.66, 0), M.white, 0.0, cr)
	_label("DARLENE", Vector3(0, 0.66, 0.025), 0.045, Color(0.12, 0.12, 0.14), 0.0, cr)
	b(Vector3(0.12, 0.16, 0.006), Vector3(0, 0.46, 0.025), M.white, 0.0, cr)
	# the roses, plastic, red gone to the colour of a scab; a scarf
	for i in 6:
		var rp := Vector3(rng.randf_range(-0.18, 0.18), rng.randf_range(0.0, 0.12), 0.06)
		_stick(at + Vector3(rp.x, 0.0, 0.2), at + Vector3(rp.x * 1.4, 0.32 + rp.y, 0.24), 0.005, pub.M.dark)
		pub.ball(0.035, at + Vector3(rp.x * 1.4, 0.34 + rp.y, 0.24), M.rose, self)
	var sc := b(Vector3(0.12, 0.5, 0.01), Vector3(-37.85, 0.5, 26.68), M.blue, 0.0)
	sc.rotation.z = deg_to_rad(-14.0)
	_anchor("cross", at + Vector3(0, 0.6, 0.12))



# ---------------------------------------------------------------- up the old main street

# What there is to find walking up the old main street on his own, by day or night: the dead bank's
# night slot across from Gary's, a meter outside Gary's, the Legion's letter board, a bench with a
# name on it, a plate in the sidewalk, the town's sign out at the highway, and a drain at the foot
# of the street. Each is a look (things.ink, toy_<id>), and some of them more than that.
func _main_finds() -> void:
	var ink := Color(0.1, 0.1, 0.11)
	# the night deposit, brass, in the bank's last pier before Gary's side of the street
	var sx := Town.MAIN_X - Town.WALK + 0.01
	var sz := -81.5
	var sy := Town.street_y(-76.0) + Town.KERB + 0.3 + 1.15
	b(Vector3(0.03, 0.42, 0.56), Vector3(sx + 0.015, sy, sz), pub.M.brass)
	b(Vector3(0.012, 0.05, 0.4), Vector3(sx + 0.034, sy + 0.08, sz), pub.M.black)
	b(Vector3(0.02, 0.03, 0.44), Vector3(sx + 0.04, sy + 0.115, sz), pub.M.brass)
	_label("NIGHT DEPOSIT", Vector3(sx + 0.033, sy - 0.07, sz), 0.04, Color(0.22, 0.17, 0.08), 90.0)
	# a paper corner caught in the flap
	var pc := b(Vector3(0.002, 0.03, 0.07), Vector3(sx + 0.042, sy + 0.06, sz + 0.09), M.white)
	pc.rotation.x = deg_to_rad(18.0)
	_anchor("night_slot", Vector3(sx + 0.05, sy, sz))
	# the meter outside Gary's: a post, the head, the window gone yellow
	var mp := Vector3(-193.75, g(-193.75, -78.6), -78.6)
	_stick(mp, mp + Vector3(0, 1.1, 0), 0.03, pub.M.steel)
	var hd := Node3D.new()
	hd.position = mp + Vector3(0, 1.25, 0)
	hd.rotation = Vector3(0, deg_to_rad(-90.0), deg_to_rad(3.0))
	add_child(hd)
	b(Vector3(0.2, 0.28, 0.14), Vector3.ZERO, pub.M.steel, 0.0, hd)
	c(0.1, 0.1, 0.14, Vector3(0, 0.14, 0), pub.M.steel, 12, hd).rotation.x = PI / 2.0
	b(Vector3(0.13, 0.08, 0.01), Vector3(0, 0.15, 0.075), M.paper, 0.0, hd)
	b(Vector3(0.012, 0.06, 0.004), Vector3(0.03, 0.15, 0.081), M.rose, 0.0, hd).rotation.z = deg_to_rad(-55.0)
	b(Vector3(0.05, 0.03, 0.02), Vector3(0, -0.08, 0.075), pub.M.black, 0.0, hd)
	_anchor("meter", mp + Vector3(0, 1.3, 0))
	# the Legion's board on two posts on its lawn, black letters on white, some of them on the grass
	var lb := Vector3(-191.2, g(-191.2, -4.0), -4.0)
	for dz in [-0.8, 0.8]:
		_stick(lb + Vector3(0, 0, dz), lb + Vector3(0, 1.3, dz), 0.04, pub.M.steel)
	b(Vector3(0.1, 0.78, 1.9), lb + Vector3(0, 1.15, 0), pub.M.dark)
	b(Vector3(0.02, 0.66, 1.78), lb + Vector3(-0.05, 1.15, 0), M.white)
	_label("THE LEGION BR. 61", lb + Vector3(-0.065, 1.42, 0), 0.07, ink, -90.0)
	_label("MEAT DRAW FRI", lb + Vector3(-0.065, 1.27, 0), 0.08, ink, -90.0)
	_label("KARAOKE CANCELED", lb + Vector3(-0.065, 1.13, 0), 0.08, ink, -90.0)
	_label("YOU KNOW WHY", lb + Vector3(-0.065, 0.99, 0), 0.08, ink, -90.0)
	_label("LEST WE", lb + Vector3(-0.065, 0.86, 0), 0.08, ink, -90.0)
	# the ones on the grass, in a row, as if somebody had laid them out
	var word := "LISTEN"
	for i in word.length():
		var at := Vector3(-191.3, 0.0, -4.5 + i * 0.2)
		at.y = g(at.x, at.z) + 0.025
		b(Vector3(0.11, 0.004, 0.13), at, M.white).rotation.y = deg_to_rad(rng.randf_range(-6.0, 6.0))
		var l := _label(word[i], at + Vector3(0, 0.004, 0), 0.1, ink, 0.0)
		l.rotation = Vector3(-PI / 2.0, deg_to_rad(-90.0), 0)
	_anchor("legion_board", lb + Vector3(-0.1, 1.1, 0))
	# the bench, against the library's railing, facing the road; a plaque on its back
	var bp := Vector3(-192.25, g(-192.25, -48.5), -48.5)
	for dz in [-0.75, 0.75]:
		b(Vector3(0.42, 0.44, 0.06), bp + Vector3(0, 0.22, dz), pub.M.black)
	for k in 3:
		b(Vector3(0.12, 0.035, 1.8), bp + Vector3(-0.14 + k * 0.13, 0.46, 0), pub.M.wood)
	for k in 2:
		var sl := b(Vector3(0.035, 0.12, 1.8), bp + Vector3(0.2, 0.62 + k * 0.16, 0), pub.M.wood)
		sl.rotation.z = deg_to_rad(-8.0)
	b(Vector3(0.006, 0.07, 0.3), bp + Vector3(0.175, 0.7, 0), pub.M.brass)
	_label("ROSE PAQUETTE", bp + Vector3(0.17, 0.72, 0), 0.022, Color(0.2, 0.15, 0.07), -90.0)
	_label("SHE SAW EVERYTHING", bp + Vector3(0.17, 0.69, 0), 0.016, Color(0.2, 0.15, 0.07), -90.0)
	# the sleeve the roses came in, under it
	var sv := b(Vector3(0.28, 0.006, 0.09), bp + Vector3(0.02, 0.012, 0.3), M.white)
	sv.rotation.y = deg_to_rad(23.0)
	_anchor("bench", bp + Vector3(0, 0.6, 0))
	# the time capsule's plate, set in the sidewalk outside the library
	var cp := Vector3(-193.2, Town.street_y(-55.5) + Town.KERB + 0.004, -55.5)
	b(Vector3(0.36, 0.012, 0.52), cp + Vector3(0, 0.004, 0), pub.M.brass)
	var t1 := _label("TIME CAPSULE 1988", cp + Vector3(0.06, 0.012, 0), 0.04, Color(0.62, 0.53, 0.36))
	t1.rotation = Vector3(-PI / 2.0, deg_to_rad(-90.0), 0)
	var t2 := _label("TO BE OPENED 2038", cp + Vector3(0.0, 0.012, 0), 0.04, Color(0.62, 0.53, 0.36))
	t2.rotation = Vector3(-PI / 2.0, deg_to_rad(-90.0), 0)
	var t3 := _label("don't", cp + Vector3(-0.11, 0.012, 0.12), 0.03, Color(0.55, 0.5, 0.42))
	t3.rotation = Vector3(-PI / 2.0, deg_to_rad(-80.0), 0)
	_anchor("capsule", cp + Vector3(0, 0.02, 0))
	# the town's sign at the highway, green, on two posts, facing traffic up island
	var ps := Vector3(-212.0, g(-212.0, 26.1), 26.1)
	var green := pub.mat(Color("2c4a36"), 0.6, 0.1, 0, Vector3.UP, 6.0, 0.8)
	for dx in [-0.9, 0.9]:
		_stick(ps + Vector3(dx, 0, 0), ps + Vector3(dx, 2.6, 0), 0.04, pub.M.steel)
	b(Vector3(2.3, 1.1, 0.04), ps + Vector3(0, 2.15, 0.03), green)
	_label("POP.", ps + Vector3(-0.55, 2.3, 0.056), 0.22, Color(0.9, 0.9, 0.85))
	# the number, painted over and painted over, each patch a shade newer than the last
	var shades := [Color("2f4d39"), Color("32523d"), Color("365741")]
	for i in 3:
		b(Vector3(0.95 - i * 0.12, 0.3, 0.005), ps + Vector3(0.38 + i * 0.03, 2.0 - i * 0.015, 0.052 + i * 0.002),
			pub.mat(shades[i], 0.6, 0.0, 0, Vector3.UP, 6.0, 0.8))
	_label("1,409", ps + Vector3(0.42, 2.0, 0.06), 0.2, Color(0.9, 0.9, 0.85))
	_label("1,408", ps + Vector3(0.45, 1.75, 0.056), 0.1, Color(0.75, 0.7, 0.62))
	_anchor("pop_sign", ps + Vector3(0, 2.1, 0.1))
	# the storm drain at the foot of the street, in the gutter on the Gary side
	var dp := Vector3(-194.45, Town.street_y(24.5) + 0.012, 24.5)
	b(Vector3(0.42, 0.01, 0.7), dp, pub.M.black)
	for k in 6:
		b(Vector3(0.36, 0.014, 0.03), dp + Vector3(0, 0.006, -0.27 + k * 0.108), pub.M.steel)
	_anchor("drain", dp + Vector3(0, 0.05, 0))

# ---------------------------------------------------------------- the Esso at night

# What the Esso has at night that the walk to work didn't: the payphone on the store's end wall (the
# kind with the steel cord), and the clerk through the night window. The rest is world/town.gd's.
func _esso_night() -> void:
	var y := Town.APRON
	var ph := Vector3(-142.86, y, 10.6)
	b(Vector3(0.14, 0.5, 0.26), ph + Vector3(0.07, 1.45, 0), pub.M.steel)
	b(Vector3(0.05, 0.22, 0.07), ph + Vector3(0.16, 1.5, 0.06), pub.M.black)
	_stick(ph + Vector3(0.16, 1.38, 0.06), ph + Vector3(0.16, 1.05, -0.02), 0.008, pub.M.steel)
	b(Vector3(0.25, 0.85, 0.5), ph + Vector3(0.12, 1.65, 0), pub.M.dark)
	_anchor("esso_phone", ph + Vector3(0.15, 1.5, 0.0))
	_anchor("esso_pumps", Vector3(-150.0, 1.2, 21.0))
	_anchor("esso_clerk", Vector3(-144.8, 1.5, 12.0))
	_anchor("esso_prices_n", Vector3(-134.5, 6.0, 26.4))
	# the clerk: a shape behind the counter through the glass, under the till's light
	var clerk := pub.model("res://models/people/patron_e.glb", Vector3(-144.8, y, 10.9), self)
	clerk.rotation.y = PI
	clerk.name = "clerk"


# ---------------------------------------------------------------- the highway's cars

# A car or a truck now and then, both ways, at highway speed, its lights coming a long way off: a
# body, a cab, the lamps and the beams. They don't stop for him. Walk out in front of one and it
# leans on the horn and swerves.
func _traffic() -> void:
	for i in 3:
		var n := Node3D.new()
		n.visible = false
		add_child(n)
		var paint: Material = [M.rust, M.blue, pub.M.seat][i]
		var long := 4.4 if i != 2 else 7.5
		b(Vector3(1.8, 0.7, long), Vector3(0, 0.6, 0), paint, 0.0, n)
		b(Vector3(1.6, 0.55, 2.0 if i != 2 else 2.4), Vector3(0, 1.2, -0.2 if i != 2 else -long / 2.0 + 1.4), paint, 0.0, n)
		for s in [-0.65, 0.65]:
			pub.ball(0.09, Vector3(s, 0.68, -long / 2.0 - 0.02), pub.M.head, n)
			pub.ball(0.07, Vector3(s, 0.72, long / 2.0 + 0.02), pub.M.tail, n)
			var beam := SpotLight3D.new()
			beam.light_color = Color("eef2ff")
			beam.light_energy = 3.5
			beam.spot_range = 30.0
			beam.spot_angle = 24.0
			beam.shadow_enabled = false
			beam.position = Vector3(s, 0.7, -long / 2.0 - 0.1)
			beam.rotation.x = deg_to_rad(-4.0)
			n.add_child(beam)
		cars.append({"node": n, "lane": 0, "v": 0.0, "x": 0.0, "dir": 1.0, "swerve": 0.0, "honked": false, "long": long, "on": false})


# ---------------------------------------------------------------- while he's out here

# Every frame (game/feet.gd): whether he's outdoors, which part of the grounds he's in, and the
# rain, the light, the cars and the sound with him.
func tick(main, dt: float) -> void:
	var view: View = main.view
	var zone := Hotspots.zone_of(view.eye_pos)
	# out of doors anywhere he's walked on his own feet, the Esso and the old main street by day too;
	# what's only there at night (Merle on the wall, the fire on the beach) only then
	var out: bool = view.place != "office" and (outdoor_zone(zone) or zone == "deck") and main.in_game
	var night: bool = int(view.clock) >= Town.NIGHT or int(view.clock) < 360
	for n in _night_only:
		if is_instance_valid(n):
			n.visible = night
	if out != out_here:
		out_here = out
		visible = out
		pub.town.set_outdoors(out)
		if not out:
			for car in cars:
				car.on = false
				(car.node as Node3D).visible = false
			if pub.dyn.has("rain"):
				(pub.dyn.rain as Node3D).position = _rain_home
			main.audio.out_mix = {}
			main.audio._mix()
	if not out_here:
		return
	var p := view.eye_pos
	# the rain with him, out past the lot
	if pub.dyn.has("rain"):
		var rain: Node3D = pub.dyn.rain
		var to := _rain_home if LOT.has_point(Vector2(p.x, p.z)) else Vector3(p.x, p.y + 6.0, p.z + 2.0)
		if rain.position.distance_to(to) > 6.0:
			rain.position = to
	for f in _flicker:
		var l: OmniLight3D = f[0]
		var t := Time.get_ticks_msec() / 1000.0 * float(f[2])
		l.light_energy = float(f[1]) * (0.82 + 0.12 * sin(t * 7.3) + 0.08 * sin(t * 13.1 + 1.0) - (0.5 if fmod(t, 9.7) < 0.08 else 0.0))
	_cars(main, dt)
	var now := area_of(p) if zone != "deck" else "deck"
	if now != area:
		area = now
		if BANNER.has(now) and not seen.has(now):
			seen[now] = true
			_banner(main, BANNER[now])
			main.heard("out:" + now)
	_banner_fade(dt)
	# the payphone at the Esso rings the first time he comes down the shoulder near enough to hear it
	if not _phone_rang and p.x < -120.0 and p.z < 30.0:
		_phone_rang = true
		main.audio.at("ring", pub.anchors["esso_phone"], 1.0, 8.0)
		main.game.set_var("esso_rang", true)
	_mix_t -= dt
	if _mix_t <= 0.0:
		_mix_t = 0.5
		_sound(main, p)


# the sea louder the nearer the water, the highway's traffic from it, the Esso's canopy hum there,
# the rain all the way
func _sound(main, p: Vector3) -> void:
	var to_sea := clampf(1.0 - (WALL_Z.y - p.z) / 30.0, 0.15, 1.0)
	var to_road := clampf(1.0 - absf(31.6 - p.z) / 25.0, 0.1, 1.0)
	var to_esso := clampf(1.0 - Vector2(p.x + 150.0, p.z - 18.0).length() / 28.0, 0.0, 1.0)
	var behind := p.z < -2.95
	var mix := {"rain_out": 0.9, "sea": 0.25 + 0.6 * to_sea, "traffic": 0.15 + 0.45 * to_road, "canopy": 0.8 * to_esso}
	if behind:
		mix.sea = 0.15
		mix.traffic = 0.08
	var was: Dictionary = main.audio.out_mix
	var moved := was.is_empty()
	for k in mix:
		if absf(float(was.get(k, 0.0)) - float(mix[k])) > 0.04:
			moved = true
	if moved:
		main.audio.out_mix = mix
		main.audio._mix()


func _cars(main, dt: float) -> void:
	var p: Vector3 = main.view.eye_pos
	_car_t -= dt
	if _car_t <= 0.0:
		_car_t = rng.randf_range(9.0, 34.0)
		for car in cars:
			if car.on:
				continue
			car.on = true
			car.lane = rng.randi_range(0, 1)
			car.dir = -1.0 if car.lane == 0 else 1.0
			car.x = p.x - car.dir * rng.randf_range(160.0, 220.0)
			car.v = rng.randf_range(19.0, 25.0)
			car.swerve = 0.0
			car.honked = false
			car.passed = false
			(car.node as Node3D).visible = true
			break
	for car in cars:
		if not car.on:
			continue
		var n: Node3D = car.node
		var lz: float = LANES[car.lane]
		# him in its lane ahead of it: the horn, and it swerves into the other lane and slows
		var ahead: float = (p.x - car.x) * car.dir
		var in_lane := absf(p.z - lz) < 1.6 and p.z > 27.4 and p.z < 35.7
		if in_lane and ahead > 0.0 and ahead < 55.0:
			if not car.honked:
				car.honked = true
				main.audio.at("horn", n.position + Vector3(0, 1, 0), 1.0, 12.0)
				main.heard("out:horn")
			car.swerve = move_toward(car.swerve, 1.0, dt * 1.4)
			car.v = move_toward(car.v, 11.0, dt * 9.0)
		else:
			car.swerve = move_toward(car.swerve, 0.0, dt * 0.6)
		var other: float = LANES[1 - car.lane]
		var z := lerpf(lz, other, smoothstep(0.0, 1.0, car.swerve))
		car.x += car.dir * car.v * dt
		n.position = Vector3(car.x, 0.0, z)
		n.rotation.y = (PI / 2.0 if car.dir > 0.0 else -PI / 2.0) + (other - lz) * 0.04 * car.swerve * car.dir
		if not car.get("passed", false) and absf(car.x - p.x) < 4.0 and absf(z - p.z) < 9.0:
			car.passed = true
			main.audio.at("gust", n.position + Vector3(0, 1, 0), 0.9, 6.0)
		if absf(car.x - p.x) > 260.0 and ahead < 0.0:
			car.on = false
			n.visible = false


# The name of a part of the grounds the first time he walks into it, at the top of the picture, the
# way a map in an old game named a place as you came into it.
func _banner(main, text: String) -> void:
	if banner == null:
		banner = Label.new()
		banner.add_theme_font_override("font", UiBits.spaced("ui_b", 6))
		banner.add_theme_font_size_override("font_size", 22)
		banner.add_theme_color_override("font_color", Color(Look.STOCK, 0.92))
		banner.add_theme_color_override("font_outline_color", Color(Look.NIGHT, 0.9))
		banner.add_theme_constant_override("outline_size", 8)
		banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.anchor_left = 0.0
		banner.anchor_right = 1.0
		banner.offset_top = 38
		banner.offset_bottom = 70
		main.root.add_child(banner)
	banner.text = text
	banner.anchor_right = main.view.world_w
	banner.modulate.a = 0.0
	_banner_t = 4.2


func _banner_fade(dt: float) -> void:
	if banner == null or _banner_t <= 0.0:
		return
	_banner_t -= dt
	var age := 4.2 - _banner_t
	banner.modulate.a = clampf(minf(age / 0.8, _banner_t / 1.2), 0.0, 1.0)
