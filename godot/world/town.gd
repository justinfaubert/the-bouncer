# The town round the Sov, built in code the way the Sov is (world/pub.gd, whose helpers it uses):
# the highway on along the shore both ways, the Esso a hundred and fifty metres south of the Sov,
# and past it the old main street coming down off the hill to the highway, the government wharf at
# its foot, and up it, across from the old bank, Gary's office.
#
# He's away from the Sov only before the night has started (the interview at four, the walk to
# work at dusk), so all of it is put away while he's at the Sov, but for the ground round the
# building at dusk, so the windows don't look out on nothing before the night has it (by_clock).
# From the night's own hour on, at the Sov, none of it is there: the Sov is as it was built.
#
# Units are metres, as in the Sov: +x north along the shore, +z east, out to the water. The main
# street runs inland (-z) from the highway at x -200, a metre up in every twenty-five. Everything
# that doesn't move is baked into a few meshes, one for each material in each 24 m square (every
# mesh is a draw call, and the Compatibility renderer lights a mesh with its nearest few lights),
# and almost none of the lamps are lights: a lamp is its glowing head and a pool of light laid on
# the ground under it. Gary's front room is on a visual layer of its own (OFFICE), lit only by its
# own lamp and its window: nothing outside reaches it.
class_name Town
extends Pub

const NIGHT := 1100.0            # the night's hour: from here on the Sov's as it was built, and the town's lamps all lit
const MAIN_X := -200.0           # the middle of the old main street
const FOOT := 27.6               # where it comes down to the highway (the highway's inland edge)
const RISE := 0.04               # a metre up in every twenty-five
const TOP_Z := FOOT - 160.0      # its top end
const CURB := 6.0                # the curbs, either side of the middle: two lanes and parking both sides
const WALK := 8.5                # the sidewalks' outer edges
const KERB := 0.15               # a sidewalk over the road
const APRON := 0.05              # the Esso's concrete
const WHARF_X := -200.0          # the government wharf, out from the foot of the street
const WHARF_Y := 1.1             # its deck
const WHARF_Z0 := 41.6           # where the deck starts, at the top of the ramp up off the highway
const WHARF_Z1 := 96.0           # its end
# Gary's front room: the inside of the front wall at OFFICE_X, the middle of the room across at
# OFFICE_Z, the old fir floor at OFFICE_Y, two feet up off the sidewalk
const OFFICE_X := -188.2
const OFFICE_Z := -82.4
const OFFICE_Y := 5.15
const OFFICE_D := 5.2            # from the front wall to the back
const OFFICE_W := 4.6
const OFFICE_H := 2.7
const OFFICE := 2                # its visual layer (layer 2): only its own lights are on it
const OUTDOORS := 0xFFFFD        # every layer but the front room's: the lights outside
# where the office's posts look from and at (world/posts.gd): Gary's eyes in his chair behind the
# desk; the man in the chair across it; the man in the doorway as he comes in; the bookkeeper at
# her desk against the wall on Gary's right
const GARY := Vector3(OFFICE_X + 4.15, OFFICE_Y + 1.2, OFFICE_Z)
const VISITOR := Vector3(OFFICE_X + 1.8, OFFICE_Y + 1.25, OFFICE_Z)
const DOORWAY := Vector3(OFFICE_X + 0.45, OFFICE_Y + 1.72, OFFICE_Z - 1.1)
const BOOKKEEPER := Vector3(OFFICE_X + 3.15, OFFICE_Y + 1.12, OFFICE_Z - 1.35)
# on the sidewalk at the foot of Gary's porch steps, standing (1.76: Posts.STAND)
const STREET_EYE := Vector3(-192.6, (FOOT + 81.0) * RISE + KERB + 1.76, -81.0)
const CHUNK := 24.0
# the ground kept flat under the things that sit flat on it: [where (x, z), height, how far it
# takes to come back to the lie of the land]. The Esso's concrete; the Sov's gravel, under it; the
# step down along the Sov's east side.
const PADS := [
	[Rect2(-168.0, 2.0, 36.0, 25.6), APRON - 0.08, 8.0],
	[Rect2(-12.5, -6.0, 41.0, 34.2), -0.09, 7.0],
	[Rect2(15.5, -3.5, 15.0, 14.5), -0.34, 0.8],
]
# when the lamps come on, a few minutes apart: the street's four circuits, the highway's, the wharf's
const LAMPS_ON := [992.0, 996.0, 1000.0, 1004.0, 994.0, 998.0]
# when the lights go on in the windows of the houses, a few at a time; the last never
const WIN_ON := [0.0, 978.0, 996.0, 1014.0, 1040.0, 9999.0]
# where the rain falls for each place he can be (a box over what he's looking at): its middle, and
# how far out it goes each way
const RAIN_AT := {
	"office": [Vector3(OFFICE_X - 8.6, OFFICE_Y + 4.0, OFFICE_Z + 3.0), Vector3(5.6, 0.3, 7.0)],
	"street": [Vector3(-197.0, STREET_EYE.y + 2.5, -69.0), Vector3(9.0, 0.3, 11.0)],
	"esso": [Vector3(-131.0, 7.0, 27.0), Vector3(10.0, 0.3, 7.0)],
	"esso:kid": [Vector3(-148.5, 6.0, 13.9), Vector3(6.0, 0.3, 0.9)],
	"seawall": [Vector3(8.0, 6.5, 30.5), Vector3(12.0, 0.3, 5.0)],
	"street:wharf": [Vector3(-200.0, 7.5, 89.6), Vector3(8.0, 0.3, 9.0)],
	"street:highway": [Vector3(-170.0, 7.0, 30.0), Vector3(16.0, 0.3, 7.0)],
}
# the pictures and lettering, drawn once into one texture (_draw_plates): where each is in it, in pixels
const PLATES := {
	"photo58": Rect2(0, 0, 1200, 840),
	"letter": Rect2(1200, 0, 600, 780),
	"desk_photo": Rect2(1800, 0, 248, 320),
	"ice": Rect2(1800, 330, 248, 110),
	"chalk": Rect2(1800, 450, 248, 330),
	"door": Rect2(0, 850, 1024, 300),
	"calendar": Rect2(1030, 850, 340, 480),
	"licence": Rect2(1380, 850, 380, 480),
	"church": Rect2(1770, 850, 278, 200),
	"lease": Rect2(1770, 1060, 278, 180),
	"shirt": Rect2(0, 1160, 600, 190),
	"legion": Rect2(0, 1360, 1024, 120),
	"library": Rect2(0, 1490, 1024, 110),
	"bank": Rect2(0, 1610, 700, 150),
	"thrift": Rect2(0, 1770, 1024, 120),
	"video": Rect2(0, 1900, 800, 140),
}
const ATLAS := 2048.0

# A lamp's light on the ground under it, added to whatever's there; for the eye only (the press
# cuts the ground as it is). It fades with the distance the way the fog would.
const GLOW_POOL := """shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 tint : source_color = vec4(1.0, 0.82, 0.6, 1.0);
uniform float energy = 0.0;
uniform float fog = 0.007;
void fragment() {
	if ((CAMERA_VISIBLE_LAYERS & 524288u) != 0u) {
		discard;
	}
	float r = length(UV - vec2(0.5)) * 2.0;
	float k = clamp(1.0 - r, 0.0, 1.0);
	ALBEDO = tint.rgb * energy * k * k * exp(-fog * length(VERTEX));
}
"""
# The Sov's sign seen from far down the highway, nearly edge on: the red it throws into the wet air,
# turned to face him, and only from a long way off (from the seawall the letters are there to read).
const GLOW_HALO := """shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 tint : source_color = vec4(0.8, 0.0, 0.1, 1.0);
uniform float energy = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
	if ((CAMERA_VISIBLE_LAYERS & 524288u) != 0u) {
		discard;
	}
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float k = clamp(1.0 - length(p), 0.0, 1.0);
	float off = smoothstep(50.0, 120.0, length(VERTEX));
	ALBEDO = tint.rgb * energy * k * k * off;
}
"""

var near: Node3D                 # the ground round the Sov, the hill behind it, the far shore: out at dusk wherever he is
var far: Node3D                  # all the rest, Gary's office in it: out only while he's away from the Sov
var key: DirectionalLight3D      # the cloud's own light, out of doors (game/view.gd turns it with the clock)
var T := {}                      # the town's own materials (the Sov's, in M, are shared)
var _bk := {}                    # what's being built: material, square, layer and group -> its pieces
var _prims := {}                 # boxes and the rest, by size, as flat triangle lists
var _grp: Node3D
var _layer := 1
var _xf := Transform3D.IDENTITY  # the frame of whatever's being built (a car, a house): its pieces are in it
var _pv := PackedVector3Array()
var _pn := PackedVector3Array()
var _pu := PackedVector2Array()
var _lamps: Array = []           # [head, pool, on at, the head's light, the pool's]
var _wins: Array = []            # the window lights, one material for each of WIN_ON
var _at := ""                    # where he is
var _halo: MeshInstance3D
var _rainfall: CPUParticles3D
var _day_spot: SpotLight3D       # the daylight in through Gary's window
var _atlas: SubViewport
var _pics: Array = []            # the materials the plates are on
var _keep: Array = []            # the photograph's grain and its dark corners, till the plates are drawn
var _fonts := {}                 # the town's own copies of the fonts (_font())
var _po := Vector2.ZERO          # while a picture's drawn in metres: where its 0, 0 is in the texture
var _ps := 46.0                  # and how many pixels to the metre


# ---------------------------------------------------------------- built, and put away

func build_for(pub: Pub) -> void:
	M = pub.M
	from_model_cache = pub.from_model_cache
	rng.seed = 1958
	near = Node3D.new()
	near.name = "near"
	add_child(near)
	far = Node3D.new()
	far.name = "far"
	add_child(far)
	_town_materials()
	_plates_start()
	_grp = near
	_terrain()
	_far_shore()
	_round_the_sov()
	_grp = far
	_shore()
	_main_street()
	_north_side()
	_south_side()
	_garys_house()
	_layer = OFFICE
	_office()
	_layer = 1
	_esso()
	_harbour()
	_back_lots()
	_bake()
	_halo_on()
	_town_rain()
	_key_light()
	for k in anchors:
		pub.anchors[k] = anchors[k]
	near.visible = false
	far.visible = false
	_keep_pictures.call_deferred()


# He's somewhere (game/view.gd, as he gets there): the town out if it's away from the Sov, the rain
# over what he's looking at, the light for the clock.
func show_for(where: String, clock: int, frame := "") -> void:
	_at = where
	if _rainfall != null:
		var r: Array = RAIN_AT.get(where + ":" + frame, RAIN_AT.get(where, []))
		if Posts.away(where) and not r.is_empty():
			_rainfall.position = r[0]
			_rainfall.emission_box_extents = r[1]
			_rainfall.emitting = true
			_rainfall.restart()
		else:
			_rainfall.emitting = false
	by_clock(float(clock), where)


# The town by the clock (Pub.dusk, with where he is): out or put away, and its lamps and windows.
# The lamps come on a circuit at a time from eight minutes to five, each warming up over ten
# minutes; the lights in the houses go on a few at a time from twenty past four; the daylight in
# Gary's window goes with the sky. Before there's a clock, and from the night's hour on, every lamp
# is lit; at the Sov then, none of it is out.
func by_clock(c: float, where: String) -> void:
	var away := Posts.away(where)
	var night := c >= NIGHT or c < 900.0
	near.visible = away or not night
	far.visible = away
	for l in _lamps:
		var on: float = l[2]
		var k := 1.0 if night else clampf((c - on) / 10.0, 0.0, 1.0)
		var lit := night or c >= on
		(l[0] as ShaderMaterial).set_shader_parameter("emission_energy", float(l[3]) * (0.12 + 0.88 * k) if lit else 0.0)
		(l[1] as ShaderMaterial).set_shader_parameter("energy", float(l[4]) * k * k)
	var dusk := 1.0 if night else clampf((c - 960.0) / 80.0, 0.0, 1.0)
	for i in _wins.size():
		var lit_w := (night and i < WIN_ON.size() - 1) or c >= float(WIN_ON[i])
		(_wins[i] as ShaderMaterial).set_shader_parameter("emission_energy", (0.5 + 1.1 * dusk) if lit_w else 0.0)
	T.shop.set_shader_parameter("emission_energy", 0.75 + 0.6 * dusk)
	if _day_spot != null:
		_day_spot.light_energy = 0.0 if night else 1.5 * clampf((1045.0 - c) / 85.0, 0.0, 1.0)
	if _halo != null:
		_halo.visible = away and (night or c >= 990.0)
	if T.has("store_spill"):
		(T.store_spill as Light3D).light_energy = 1.3 if night else lerpf(0.7, 1.3, dusk)


# ---------------------------------------------------------------- the lie of the land

static func street_y(z: float) -> float:
	return maxf(0.0, FOOT - z) * RISE


# The ground's height: level across the main street, lawns at the sidewalks' height beside it; flat
# along the shore and rising behind it into the hill; kept flat under the Esso and the Sov.
static func ground_y(x: float, z: float) -> float:
	var dx := absf(x - MAIN_X)
	var s := street_y(z)
	var by_street := s + 0.12
	if dx < WALK:
		by_street = lerpf(s - 0.14, s + 0.12, clampf((dx - CURB) / (WALK - CURB), 0.0, 1.0))
	var shore := -0.05 + maxf(0.0, -12.0 - z) * 0.07
	var y := lerpf(by_street, shore, smoothstep(34.0, 70.0, dx))
	for p in PADS:
		var d := _out_of(p[0], x, z)
		if d < float(p[2]):
			y = lerpf(y, float(p[1]), 1.0 - smoothstep(0.0, float(p[2]), d))
	return y


static func _out_of(r: Rect2, x: float, z: float) -> float:
	var dx := maxf(maxf(r.position.x - x, 0.0), x - r.end.x)
	var dz := maxf(maxf(r.position.y - z, 0.0), z - r.end.y)
	return Vector2(dx, dz).length()


# Whether a point's in Gary's front room, and whether it's anywhere in the town, out of the Sov's
# grounds (game/hotspots.gd: the parts of the world he sees from where)
static func in_office(p: Vector3) -> bool:
	return p.x > OFFICE_X - 0.3 and p.x < OFFICE_X + OFFICE_D and absf(p.z - OFFICE_Z) < OFFICE_W / 2.0 + 0.1 \
		and p.y > OFFICE_Y - 0.3 and p.y < OFFICE_Y + OFFICE_H + 0.1


static func in_town(p: Vector3) -> bool:
	return p.x < -14.0 or p.x > 32.0 or p.z > 28.3


# ---------------------------------------------------------------- building it

# A piece, into whatever's being built: its triangles, where it goes, what it's made of.
func _put(p: Array, xf: Transform3D, m: Material) -> void:
	var t := _xf * xf
	var o := t.origin
	var k := "%d %d %d %d %d" % [m.get_instance_id(), floori(o.x / CHUNK), floori(o.z / CHUNK), _layer, _grp.get_instance_id()]
	if not _bk.has(k):
		_bk[k] = [m, _layer, _grp, []]
	(_bk[k][3] as Array).append([p, t])


# Everything built so far, a mesh for each material in each square.
func _bake() -> void:
	for k in _bk:
		var b: Array = _bk[k]
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var u := PackedVector2Array()
		for it in b[3]:
			var p: Array = it[0]
			var t: Transform3D = it[1]
			v.append_array(t * (p[0] as PackedVector3Array))
			n.append_array(Transform3D(t.basis, Vector3.ZERO) * (p[1] as PackedVector3Array))
			u.append_array(p[2])
		_mesh_node([v, n, u], b[0], b[2], b[1])
	_bk.clear()


func _mesh_node(p: Array, m: Material, parent: Node3D, layer := 1) -> MeshInstance3D:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = p[0]
	arr[Mesh.ARRAY_NORMAL] = p[1]
	arr[Mesh.ARRAY_TEX_UV] = p[2]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = m
	mi.layers = layer
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# a primitive's triangles, one vertex each corner (no index): ready to be moved and appended
func _flat(a: Array) -> Array:
	var sv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var sn: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var su: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var u := PackedVector2Array()
	for i in idx:
		v.append(sv[i])
		n.append(sn[i])
		u.append(su[i])
	return [v, n, u]


func _box(size: Vector3) -> Array:
	var k := "b%.3f %.3f %.3f" % [size.x, size.y, size.z]
	if not _prims.has(k):
		var bm := BoxMesh.new()
		bm.size = size
		_prims[k] = _flat(bm.get_mesh_arrays())
	return _prims[k]


func _cyl(rt: float, rb: float, h: float, seg: int) -> Array:
	var k := "c%.3f %.3f %.3f %d" % [rt, rb, h, seg]
	if not _prims.has(k):
		var cm := CylinderMesh.new()
		cm.top_radius = rt
		cm.bottom_radius = rb
		cm.height = h
		cm.radial_segments = seg
		cm.rings = 1
		cm.cap_top = rt > 0.0
		_prims[k] = _flat(cm.get_mesh_arrays())
	return _prims[k]


func _sph(r: float, seg: int) -> Array:
	var k := "s%.3f %d" % [r, seg]
	if not _prims.has(k):
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = seg
		sm.rings = maxi(4, seg / 2)
		_prims[k] = _flat(sm.get_mesh_arrays())
	return _prims[k]


func _bx(size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> void:
	_put(_box(size), Transform3D(Basis.from_euler(rot * (PI / 180.0)), pos), m)


func _bb(size: Vector3, pos: Vector3, m: Material, b: Basis) -> void:
	_put(_box(size), Transform3D(b, pos), m)


func _cy(rt: float, rb: float, h: float, pos: Vector3, m: Material, seg := 12, rot := Vector3.ZERO) -> void:
	_put(_cyl(rt, rb, h, seg), Transform3D(Basis.from_euler(rot * (PI / 180.0)), pos), m)


func _sp(r: float, pos: Vector3, m: Material, seg := 12) -> void:
	_put(_sph(r, seg), Transform3D(Basis.IDENTITY, pos), m)


# triangles of my own: begun, added to, and taken
func _begin() -> void:
	_pv = PackedVector3Array()
	_pn = PackedVector3Array()
	_pu = PackedVector2Array()


# one facing n, wound the way Godot wants a front face (clockwise, seen from in front)
func _tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	_pv.append_array(PackedVector3Array([a, b, c]))
	_pn.append_array(PackedVector3Array([n, n, n]))
	_pu.append_array(PackedVector2Array([ua, ub, uc]))


func _end() -> Array:
	return [_pv, _pn, _pu]


# a flat rectangle w by h facing +z, its picture the part `uv` of a texture
func _quad_p(w: float, h: float, uv := Rect2(0, 0, 1, 1)) -> Array:
	_begin()
	var a := Vector3(-w / 2.0, -h / 2.0, 0.0)
	var b := Vector3(-w / 2.0, h / 2.0, 0.0)
	var c := Vector3(w / 2.0, h / 2.0, 0.0)
	var d := Vector3(w / 2.0, -h / 2.0, 0.0)
	var ua := Vector2(uv.position.x, uv.end.y)
	var ub := uv.position
	var uc := Vector2(uv.end.x, uv.position.y)
	var ud := uv.end
	_tri(a, b, c, Vector3.BACK, ua, ub, uc)
	_tri(a, c, d, Vector3.BACK, ua, uc, ud)
	return _end()


# a plate from the pictures, w by h, at pos, facing the way the basis's +z does
func _plate(name: String, w: float, h: float, pos: Vector3, b: Basis, m: Material) -> void:
	var r: Rect2 = PLATES[name]
	_put(_quad_p(w, h, Rect2(r.position / ATLAS, r.size / ATLAS)), Transform3D(b, pos), m)


# the basis for something flat on a wall facing `face`: its +z out of the wall, up up
static func facing(face: Vector3) -> Basis:
	return Basis.looking_at(-face, Vector3.UP)


# a convex outline (x, z), stood up from y0 to y1: a hull, a plinth
func _extrude_p(outline: Array, y0: float, y1: float) -> Array:
	_begin()
	var n := outline.size()
	var mid := Vector2.ZERO
	for q in outline:
		mid += q
	mid /= float(n)
	for i in n:
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % n]
		var out := Vector3(b.y - a.y, 0.0, -(b.x - a.x)).normalized()
		var to_mid := Vector3(mid.x - a.x, 0.0, mid.y - a.y)
		if out.dot(to_mid) > 0.0:
			out = -out
		var a0 := Vector3(a.x, y0, a.y)
		var b0 := Vector3(b.x, y0, b.y)
		var a1 := Vector3(a.x, y1, a.y)
		var b1 := Vector3(b.x, y1, b.y)
		_tri(a0, a1, b1, out)
		_tri(a0, b1, b0, out)
		_tri(Vector3(mid.x, y1, mid.y), a1, b1, Vector3.UP)
		_tri(Vector3(mid.x, y0, mid.y), b0, a0, Vector3.DOWN)
	return _end()


# A wall from a to b on the ground (x, z), h high from y0, with openings in it: [from, to] along
# it, [bottom, top] up it (Pub.wall's way, into what's being built).
func _wallh(a: Vector2, b: Vector2, y0: float, h: float, m: Material, holes: Array = [], thick := 0.2) -> void:
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
			if hole[3] < s[3]:
				cut.append([maxf(o0, s[0]), minf(o1, s[1]), hole[3], s[3]])
			if hole[2] > s[2]:
				cut.append([maxf(o0, s[0]), minf(o1, s[1]), s[2], hole[2]])
		spans = cut
	for s in spans:
		var run: float = s[1] - s[0]
		var hh: float = s[3] - s[2]
		if run < 0.005 or hh < 0.005:
			continue
		var mid: Vector2 = a + dir * (s[0] + run / 2.0)
		var size := Vector3(run, hh, thick) if along_x else Vector3(thick, hh, run)
		_bx(size, Vector3(mid.x, y0 + s[2] + hh / 2.0, mid.y), m)


# A gable roof over x0..x1, z0..z1 from eaves at y, `rise` up to its ridge: the ridge along x if
# `along_x`, along z if not; the gable ends filled in `wall_m`.
func _roof(x0: float, x1: float, z0: float, z1: float, y: float, rise: float, along_x: bool, roof_m: Material, wall_m: Material, over := 0.35) -> void:
	var span := (z1 - z0) if along_x else (x1 - x0)
	var length := ((x1 - x0) if along_x else (z1 - z0)) + over * 2.0
	var half := span / 2.0
	var pitch := atan2(rise, half)
	var slope := sqrt(rise * rise + half * half)
	var ext := over / cos(pitch)
	var thick := 0.14
	var xm := (x0 + x1) / 2.0
	var zm := (z0 + z1) / 2.0
	for s in [-1.0, 1.0]:
		var along := (slope + ext) / 2.0
		var c := Vector3(xm, y + rise, zm)
		var nrm: Vector3
		if along_x:
			c += Vector3(0.0, -sin(pitch) * along, s * cos(pitch) * along)
			nrm = Vector3(0.0, cos(pitch), s * sin(pitch))
			_bb(Vector3(length, thick, slope + ext), c + nrm * thick / 2.0, roof_m, Basis.from_euler(Vector3(s * pitch, 0.0, 0.0)))
		else:
			c += Vector3(s * cos(pitch) * along, -sin(pitch) * along, 0.0)
			nrm = Vector3(s * sin(pitch), cos(pitch), 0.0)
			_bb(Vector3(slope + ext, thick, length), c + nrm * thick / 2.0, roof_m, Basis.from_euler(Vector3(0.0, 0.0, -s * pitch)))
	# the gable ends
	_begin()
	if along_x:
		for e in [[x0, -1.0], [x1, 1.0]]:
			var ex: float = e[0]
			_tri(Vector3(ex, y, z0), Vector3(ex, y, z1), Vector3(ex, y + rise, zm), Vector3(e[1], 0.0, 0.0))
	else:
		for e in [[z0, -1.0], [z1, 1.0]]:
			var ez: float = e[0]
			_tri(Vector3(x0, y, ez), Vector3(x1, y, ez), Vector3(xm, y + rise, ez), Vector3(0.0, 0.0, e[1]))
	_put(_end(), Transform3D.IDENTITY, wall_m)


# A window in a wall facing `face`, its middle at c on the wall's face: the frame round it, the
# glass (or the light in it), the sill; `bars`, the cross of an old sash.
func _win(c: Vector3, face: Vector3, w: float, h: float, glass_m: Material, trim: Material, bars := false) -> void:
	var xf := Transform3D(facing(face), c)
	_put(_box(Vector3(w + 0.16, h + 0.16, 0.05)), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.025)), trim)
	_put(_box(Vector3(w, h, 0.05)), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.04)), glass_m)
	_put(_box(Vector3(w + 0.26, 0.06, 0.12)), xf * Transform3D(Basis.IDENTITY, Vector3(0, -h / 2.0 - 0.07, 0.06)), trim)
	if bars:
		_put(_box(Vector3(w, 0.045, 0.03)), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.075)), trim)
		_put(_box(Vector3(0.04, h, 0.03)), xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.075)), trim)


# the frame a street building is built in: its front's middle at the sidewalk's height there (and
# `raise` over it), its front facing the street (+z), along the street on x, back from it on -z
func _on_street(side: int, d: float, z0: float, z1: float, raise := 0.0) -> Transform3D:
	var zc := (z0 + z1) / 2.0
	return Transform3D(Basis.from_euler(Vector3(0.0, deg_to_rad(-90.0 * side), 0.0)), Vector3(MAIN_X + side * d, street_y(zc) + KERB + raise, zc))


# how far a street building's walls go down below its floor, to meet the ground at its low end
func _drop(z1: float, floor_y: float) -> float:
	return floor_y - (street_y(z1) + 0.12) + 0.3


# ---------------------------------------------------------------- materials

func _town_materials() -> void:
	var up := Vector3.UP
	T.grass = mat(Color("4d5243"), 0.95, 0.0, 1, Vector3(1, 0, 0.35), 7.0, 0.25)
	T.asphalt = mat(Color("3a3a3d"), 0.32, 0.0, 1, Vector3(1, 0, 0.05), 7.0, 0.3)
	T.walk = mat(Color("8e8d88"), 0.85, 0.0, 1, Vector3(1, 0, 0.12), 7.0, 0.5)
	T.yellow = mat(Color("a48c3e"), 0.6, 0.0, 3, up, 7.0, 0.2)
	T.apron = mat(Color("85847e"), 0.75, 0.0, 1, Vector3(1, 0, 0.3), 7.0, 0.4)
	T.trim = mat(Color("e4e2da"), 0.7, 0.0, 0, up, 5.0, 0.9)
	T.trim_dk = mat(Color("3f4441"), 0.7, 0.0, 0, up, 5.0, 0.9)
	T.roof = mat(Color("3d3e41"), 0.85, 0.0, 0, up, 4.5, 0.8)
	T.roof_b = mat(Color("4f4b45"), 0.85, 0.0, 0, up, 4.5, 0.8)
	T.roof_g = mat(Color("4a5550"), 0.6, 0.3, 0, up, 4.5, 0.8)
	T.stucco = mat(Color("b8b3a4"), 0.9, 0.0, 0, up, 6.0, 0.8)
	T.stucco_b = mat(Color("c7c2b2"), 0.9, 0.0, 0, up, 6.0, 0.8)
	T.brick = mat(Color("6b5242"), 0.9, 0.0, 0, up, 4.0, 0.8)
	T.sandstone = mat(Color("b9a57e"), 0.9, 0.0, 0, up, 5.5, 0.8)
	T.stone = mat(Color("7e807d"), 0.9, 0.0, 0, up, 5.0, 0.8)
	T.white = mat(Color("dddbd2"), 0.8, 0.0, 0, up, 4.0, 0.9)
	# clapboard, strokes at a constant height the way the boards run
	T.clap = []
	for c in ["dddbd2", "8f9a8c", "c7bda2", "6e7b87", "4f5c4c", "a89a7a"]:
		T.clap.append(mat(Color(c), 0.85, 0.0, 0, up, 4.0, 0.9))
	T.glass_dk = mat(Color("25292e"), 0.15, 0.3, 3, up, 7.0, 0.6)
	T.pole = mat(Color("2c3330"), 0.5, 0.3, 2, up, 5.0, 1.0)
	T.wood_pole = mat(Color("4a4036"), 0.9, 0.0, 2, up, 5.0, 1.0)
	T.paper_win = mat(Color("cdc4ab"), 0.9, 0.0, 3, up, 7.0, 0.4)
	T.olive = mat(Color("4f5541"), 0.6, 0.2, 2, up, 5.0, 1.0)
	T.planks = mat(Color("807a70"), 0.85, 0.0, 1, Vector3(0, 0, 1), 6.0, 0.7)
	T.piling = mat(Color("3b342d"), 0.95, 0.0, 2, up, 5.0, 1.0)
	T.hull_w = mat(Color("dcdcd6"), 0.5, 0.0, 2, up, 5.0, 1.0)
	T.hull_n = mat(Color("2b3b56"), 0.5, 0.0, 2, up, 5.0, 1.0)
	T.hull_g = mat(Color("3f5a48"), 0.5, 0.0, 2, up, 5.0, 1.0)
	T.ridge = mat(Color("2b2f35"), 0.95, 0.0, 3, up, 7.0, 0.0)
	T.conifer = mat(Color("2f3a33"), 0.95, 0.0, 4, up, 5.0, 0.6)
	T.bark = mat(Color("3e3832"), 0.95, 0.0, 2, up, 5.0, 0.8)
	T.tire = mat(Color("1e1e20"), 0.8, 0.0, 2, up, 6.0, 1.0)
	T.chrome = mat(Color("a7abad"), 0.25, 0.8, 2, up, 5.0, 1.0)
	T.tail = mat(Color("5a3a2a"), 0.4, 0.0, 3)
	T.cars = []
	for c in ["2f3640", "9aa0a4", "263a5c", "8a7f6a", "33463a", "d9d9d4", "4a4a4e", "6b5c48"]:
		T.cars.append(mat(Color(c), 0.35, 0.5, 2, Vector3(0.25, 1, 0), 6.0, 1.0))
	# the windows: one for each lot that has its lights put on together, and the shops' (on all day)
	for i in WIN_ON.size():
		var w := glow(Color("ffcf8a"), 0.0)
		w.set_shader_parameter("albedo", Color("2a2c2f"))
		_wins.append(w)
	T.shop = glow(Color("fff0d6"), 1.0)
	T.shop.set_shader_parameter("albedo", Color("cfc8b8"))
	# the lamps: the street's heads warm, the highway's sodium, the wharf's the cold ink's green-white
	var cols := ["ffd7a0", "ffd7a0", "ffd7a0", "ffd7a0", "ffac40", "d2f2e2"]
	var head_e := [4.5, 4.5, 4.5, 4.5, 6.0, 5.0]
	var pool_e := [0.42, 0.42, 0.42, 0.42, 0.55, 0.35]
	var sh := Shader.new()
	sh.code = GLOW_POOL
	for i in LAMPS_ON.size():
		var head := glow(Color(cols[i]), 0.0)
		head.set_shader_parameter("albedo", Color("bdbab2"))
		var pool := ShaderMaterial.new()
		pool.shader = sh
		pool.set_shader_parameter("tint", Color(cols[i]))
		_lamps.append([head, pool, LAMPS_ON[i], head_e[i], pool_e[i]])
	# the Esso
	T.canopy = mat(Color("e8eaeb"), 0.6, 0.0, 0, up, 5.0, 0.9)
	T.band = mat(Color("2c3b5c"), 0.5, 0.0, 3, up, 7.0, 0.8)
	T.canopy_lit = glow(Color("d2f6e4"), 2.6)
	T.pump = mat(Color("d6d8da"), 0.5, 0.0, 2, up, 5.0, 1.0)
	T.ice = mat(Color("eceeef"), 0.4, 0.0, 2, up, 5.0, 1.0)
	T.store_in = glow(Color("cff2e0"), 0.95)
	T.can = mat(Color("3d4a40"), 0.6, 0.2, 2, up, 5.0, 1.0)
	T.bucket = mat(Color("3a5d7c"), 0.5, 0.0, 2, up, 5.0, 1.0)
	T.tank = mat(Color("dcdcd8"), 0.4, 0.2, 2, up, 5.0, 1.0)
	T.goods = []
	for c in ["6a7d8c", "8a7a4a", "4d6a52", "9a8c74", "5a5f72", "b0a58a"]:
		T.goods.append(mat(Color(c), 0.6, 0.0, 3, up, 7.0, 0.5))
	# Gary's front room
	T.fir = surfaced(mat(Color(0.92, 0.64, 0.42), 0.55, 0.0, 1, Vector3(0, 0, 1), 6.0, 0.7), "wood", 1.3)
	T.paper_wall = mat(Color(1, 1, 1), 0.9, 0.0, 0, up, 6.0, 0.8)
	T.paper_wall.set_shader_parameter("albedo_tex", _wallpaper())
	T.paper_wall.set_shader_parameter("mapping", 1)
	T.paper_wall.set_shader_parameter("tex_size", 0.53)
	T.paper_wall.set_shader_parameter("split_y", OFFICE_Y + 0.95)
	T.paper_wall.set_shader_parameter("albedo_tex2", tex("res://textures/panel.png"))
	T.paper_wall.set_shader_parameter("albedo2", Color(0.66, 0.52, 0.38))
	T.ceil = mat(Color("cdc8bc"), 0.9, 0.0, 1, Vector3(1, 0, 0.3), 7.0, 0.6)
	T.trim_in = mat(Color("d9d2bf"), 0.6, 0.0, 2, up, 5.0, 1.0)
	T.oak = surfaced(mat(Color(0.95, 0.78, 0.56), 0.45, 0.0, 1, Vector3(1, 0, 0), 6.0, 0.8), "top", 0.8)
	T.oak_side = surfaced(mat(Color(0.82, 0.63, 0.43), 0.6, 0.0, 2, up, 6.0, 1.0), "wood", 0.9)
	T.brass = mat(Color("a08447"), 0.35, 0.7, 2, up, 5.0, 1.0)
	T.shade = glow(Color("f3d7a6"), 1.25)
	T.cabinet = mat(Color("6c7166"), 0.45, 0.45, 2, up, 5.0, 1.0)
	T.safe = mat(Color("2c332f"), 0.4, 0.5, 2, up, 5.0, 1.0)
	T.cardboard = mat(Color("a5845a"), 0.9, 0.0, 2, up, 6.0, 1.0)
	T.shirt = mat(Color("1c1c1f"), 0.95, 0.0, 4, up, 5.0, 0.7)
	T.plastic = mat(Color("e2e2dc"), 0.5, 0.0, 2, up, 5.0, 1.0)
	T.beige = mat(Color("c9c3b4"), 0.5, 0.0, 2, up, 5.0, 1.0)
	T.radiator = mat(Color("d4d1c7"), 0.4, 0.2, 2, up, 5.0, 1.0)
	T.monitor = mat(Color("29292c"), 0.4, 0.0, 2, up, 5.0, 1.0)
	T.mon_glow = glow(Color("c2e6d6"), 0.5)
	T.knit = mat(Color("6c7079"), 0.95, 0.0, 4, up, 5.0, 0.8)
	T.chair = surfaced(mat(Color(0.74, 0.54, 0.37), 0.6, 0.0, 2, up, 6.0, 1.0), "wood", 0.7)
	T.coat = mat(Color("3a3c3a"), 0.9, 0.0, 4, up, 5.0, 0.8)
	T.door_paint = mat(Color("47564f"), 0.6, 0.0, 2, up, 5.0, 1.0)
	T.blind = mat(Color("d8d3c4"), 0.6, 0.0, 3, up, 7.0, 0.6)
	T.mug_b = mat(Color("2d3f5c"), 0.3, 0.0, 2, up, 5.0, 1.0)


# The paper on Gary's walls, painted over long ago: a stripe and a small lozenge, all but gone
# under the paint.
func _wallpaper() -> ImageTexture:
	var img := Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
	var base := Color(0.8, 0.8, 0.7)
	for y in 128:
		for x in 128:
			var s := 0.5 + 0.5 * cos(float(x) / 128.0 * TAU * 4.0)
			var cx := float((x + 16) % 32) - 16.0
			var cy := float((y + (16 if (x >> 5) % 2 == 0 else 0)) % 32) - 16.0
			var loz := 1.0 - clampf((absf(cx) + absf(cy)) / 9.0, 0.0, 1.0)
			var k := 1.0 - 0.035 * s - 0.06 * loz
			img.set_pixel(x, y, Color(base.r * k, base.g * k, base.b * k))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- the ground, the shore, the far side

# The land inland of the highway, a mesh for each 24 m square: 4 m cells through the town and round
# the Sov, 8 m out past them, and the street's edges on cell lines so the lawns can step up to the
# sidewalks.
func _terrain() -> void:
	var xs: Array = []
	var x := -340.0
	while x <= 320.0:
		xs.append(x)
		x += 4.0 if x >= -264.0 and x < 44.0 else 8.0
	var edges := [MAIN_X - WALK, MAIN_X - CURB, MAIN_X + CURB, MAIN_X + WALK]
	var keep: Array = []
	for v in xs:
		var close := false
		for e in edges:
			if absf(float(v) - float(e)) < 0.8:
				close = true
		if not close:
			keep.append(v)
	keep.append_array(edges)
	keep.sort()
	xs = keep
	var zs: Array = []
	var z := -164.0
	while z < FOOT - 1.0:
		zs.append(z)
		z += 4.0
	zs.append(FOOT)
	var h: Array = []
	for j in zs.size():
		var row := PackedFloat32Array()
		for i in xs.size():
			row.append(ground_y(xs[i], zs[j]))
		h.append(row)
	var nrm: Array = []
	for j in zs.size():
		var row: Array = []
		for i in xs.size():
			var i0 := maxi(i - 1, 0)
			var i1 := mini(i + 1, xs.size() - 1)
			var j0 := maxi(j - 1, 0)
			var j1 := mini(j + 1, zs.size() - 1)
			var dydx: float = (h[j][i1] - h[j][i0]) / (float(xs[i1]) - float(xs[i0]))
			var dydz: float = (h[j1][i] - h[j0][i]) / (float(zs[j1]) - float(zs[j0]))
			row.append(Vector3(-dydx, 1.0, -dydz).normalized())
		nrm.append(row)
	# the cells by chunk first (a packed array held in an Array is copied when it's taken out, so
	# each chunk's are built where they're kept)
	var cells := {}
	for j in zs.size() - 1:
		for i in xs.size() - 1:
			var cx: float = (float(xs[i]) + float(xs[i + 1])) / 2.0
			var cz: float = (float(zs[j]) + float(zs[j + 1])) / 2.0
			var ck := Vector2i(floori(cx / CHUNK), floori(cz / CHUNK))
			if not cells.has(ck):
				cells[ck] = []
			(cells[ck] as Array).append(Vector2i(i, j))
	for ck in cells:
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		for cell in cells[ck]:
			var i: int = cell.x
			var j: int = cell.y
			var p00 := Vector3(xs[i], h[j][i], zs[j])
			var p10 := Vector3(xs[i + 1], h[j][i + 1], zs[j])
			var p01 := Vector3(xs[i], h[j + 1][i], zs[j + 1])
			var p11 := Vector3(xs[i + 1], h[j + 1][i + 1], zs[j + 1])
			# seen from above, x right and z down the page: clockwise
			v.append_array(PackedVector3Array([p00, p10, p11, p00, p11, p01]))
			n.append_array(PackedVector3Array([nrm[j][i], nrm[j][i + 1], nrm[j + 1][i + 1], nrm[j][i], nrm[j + 1][i + 1], nrm[j + 1][i]]))
		var u := PackedVector2Array()
		u.resize(v.size())
		var mid := (float(ck.x) + 0.5) * CHUNK
		_mesh_node([v, n, u], T.grass, near if mid > -100.0 and mid < 130.0 else far)


# The highway on along the shore, its line, the seawall (open where the wharf goes out). The Sov's
# own stretch of it, x -72 to 88, is the Sov's (Pub._outside).
func _shore() -> void:
	for seg in [[-340.0, -72.0], [88.0, 320.0]]:
		var x := float(seg[0])
		while x < float(seg[1]) - 0.01:
			var x1 := minf(x + CHUNK, float(seg[1]))
			_bx(Vector3(x1 - x, 0.02, 8.0), Vector3((x + x1) / 2.0, 0.0, 31.6), M.road)
			# the seawall, but where the wharf goes out
			var a := x
			var b := x1
			if a < WHARF_X + 2.6 and b > WHARF_X - 2.6:
				if WHARF_X - 2.6 - a > 0.01:
					_bx(Vector3(WHARF_X - 2.6 - a, 0.9, 0.5), Vector3((a + WHARF_X - 2.6) / 2.0, 0.2, 35.9), M.dark)
				if b - (WHARF_X + 2.6) > 0.01:
					_bx(Vector3(b - WHARF_X - 2.6, 0.9, 0.5), Vector3((b + WHARF_X + 2.6) / 2.0, 0.2, 35.9), M.dark)
			else:
				_bx(Vector3(b - a, 0.9, 0.5), Vector3((a + b) / 2.0, 0.2, 35.9), M.dark)
			x = x1
	# its centre line on the Sov's spacing (the Sov's dashes are every 6 m from -60 to 78)
	var dx := -66.0
	while dx > -340.0:
		_bx(Vector3(2.5, 0.01, 0.12), Vector3(dx, 0.02, 31.6), M.wall)
		dx -= 6.0
	dx = 84.0
	while dx < 320.0:
		_bx(Vector3(2.5, 0.01, 0.12), Vector3(dx, 0.02, 31.6), M.wall)
		dx += 6.0
	# the water off the seawall, in front of the Sov
	anchors["seawall_water"] = Vector3(8.0, -0.3, 48.0)
	# the highway's lamps between the Esso and the Sov, on the inland side, sodium
	for lx in [-118.0, -84.0, -50.0, -230.0, -262.0]:
		_cobra(Vector3(lx, 0.0, 26.2))


# a highway lamp: a pole, its arm out over the road, the head; its pool on the road
func _cobra(at: Vector3) -> void:
	var g := 4
	_cy(0.09, 0.12, 8.6, at + Vector3(0, 4.3, 0), T.pole, 8)
	_bx(Vector3(0.08, 0.08, 2.4), at + Vector3(0, 8.45, 1.2), T.pole)
	_bx(Vector3(0.34, 0.14, 0.7), at + Vector3(0, 8.38, 2.5), T.pole)
	_bx(Vector3(0.26, 0.03, 0.5), at + Vector3(0, 8.3, 2.5), _lamps[g][0])
	_pool(at + Vector3(0, 0.03, 3.2), 13.0, g)


# a pool of a lamp's light on the ground, size across, flat (or along a slope, basis b)
func _pool(c: Vector3, size: float, g: int, b := Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))) -> void:
	_put(_quad_p(size, size), Transform3D(b, c), _lamps[g][1])


# The far shore across the strait: low hills, a long way off, behind its few lights.
func _far_shore() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var x := -900.0
	while x < 900.0:
		var w := r.randf_range(160.0, 320.0)
		var hh := r.randf_range(9.0, 26.0)
		_bx(Vector3(w, hh, 60.0), Vector3(x + w / 2.0, -0.4 + hh / 2.0, 505.0 + r.randf_range(-15.0, 15.0)), T.ridge, Vector3(0, r.randf_range(-6.0, 6.0), 0))
		x += w * 0.7


# Round the Sov: a few houses on the hill behind it and along the highway, and the trees.
func _round_the_sov() -> void:
	var houses := [[Vector3(-34, 0, -30), 0.0, 2, 1], [Vector3(12, 0, -52), 0.0, 1, 2], [Vector3(44, 0, -38), 8.0, 2, 3],
		[Vector3(72, 0, -64), -6.0, 1, 4], [Vector3(-60, 0, -18), 10.0, 1, 1], [Vector3(54, 0, 6), 0.0, 2, 2],
		[Vector3(-42, 0, 7), 0.0, 1, 3], [Vector3(96, 0, -20), 0.0, 2, 0], [Vector3(-86, 0, -40), 4.0, 2, 2]]
	var spots: Array = []
	for i in houses.size():
		var hs: Array = houses[i]
		var at: Vector3 = hs[0]
		at.y = ground_y(at.x, at.z) + 0.5
		_house(at, hs[1], 8.0, 8.5, hs[2], T.clap[i % T.clap.size()], [T.roof, T.roof_b, T.roof_g][i % 3], i % 2 == 0, hs[3], 0.9)
		spots.append(Vector2(at.x, at.z - 4.0))
	var n := 0
	var guard := 0
	while n < 46 and guard < 400:
		guard += 1
		var p := Vector2(rng.randf_range(-110.0, 125.0), rng.randf_range(-130.0, -14.0))
		if p.x > -16.0 and p.x < 34.0 and p.y > -16.0:
			continue
		var ok := true
		for s in spots:
			if p.distance_to(s) < 9.0:
				ok = false
		if not ok:
			continue
		spots.append(p)
		_pine(Vector3(p.x, ground_y(p.x, p.y), p.y), rng.randf_range(9.0, 17.0))
		n += 1
	# along the highway's inland side, a line of them past the houses
	for px in [-70.0, -64.0, 66.0, 74.0, 110.0, 118.0]:
		_pine(Vector3(px, ground_y(px, 14.0), 14.0 + rng.randf_range(-3.0, 3.0)), rng.randf_range(10.0, 15.0))


# a fir, a few stacked cones on a trunk
func _pine(at: Vector3, h: float) -> void:
	_cy(0.16, 0.2, h * 0.3, at + Vector3(0, h * 0.15, 0), T.bark, 6)
	var r := h * 0.22
	for k in 3:
		var y0 := h * (0.18 + 0.24 * k)
		var hh := h * (0.5 - 0.08 * k)
		_cy(0.0, r * (1.0 - 0.25 * k), hh, at + Vector3(0, y0 + hh / 2.0, 0), T.conifer, 7)


# a maple with its leaves gone: the trunk and a few limbs
func _bare(at: Vector3, h: float) -> void:
	_cy(0.12, 0.2, h * 0.45, at + Vector3(0, h * 0.225, 0), T.bark, 6)
	for k in 6:
		var a := TAU * k / 6.0 + rng.randf_range(-0.3, 0.3)
		var tilt := rng.randf_range(28.0, 48.0)
		var lh := h * rng.randf_range(0.35, 0.55)
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(tilt))
		var top := at + Vector3(0, h * 0.42, 0)
		_put(_cyl(0.025, 0.08, lh, 5), Transform3D(b, top + b * Vector3(0, lh / 2.0, 0)), T.bark)


# A house: its front's middle at `at` on its floor, facing `yaw` (0: +z, toward the water), w wide
# and `deep` back, one or two storeys; the gable to the front or the side; its windows' lights the
# lot WIN_ON[g]; `drop` how far its walls go down to the ground; a porch on the front.
func _house(at: Vector3, yaw: float, w: float, deep: float, storeys: int, wall_m: Material, roof_m: Material, gable_front: bool, g: int, drop: float, porch := true) -> void:
	var keep := _xf
	_xf = _xf * Transform3D(Basis.from_euler(Vector3(0.0, deg_to_rad(yaw), 0.0)), at)
	var hh := 2.75 * storeys
	_bx(Vector3(w, hh + drop, deep), Vector3(0, (hh - drop) / 2.0, -deep / 2.0), wall_m)
	var lit: Material = _wins[g]
	var dark: Material = T.glass_dk
	_win(Vector3(-w * 0.28, 1.45, 0.0), Vector3.BACK, 1.0, 1.35, lit, T.trim, true)
	_win(Vector3(w * 0.3, 1.45, 0.0), Vector3.BACK, 1.0, 1.35, dark if g % 2 == 0 else lit, T.trim, true)
	_bx(Vector3(0.95, 2.1, 0.08), Vector3(w * 0.02, 1.05, 0.03), M.dark)
	_bx(Vector3(1.15, 0.12, 0.1), Vector3(w * 0.02, 2.16, 0.05), T.trim)
	if storeys > 1:
		_win(Vector3(-w * 0.28, 4.15, 0.0), Vector3.BACK, 0.95, 1.25, dark, T.trim, true)
		_win(Vector3(w * 0.28, 4.15, 0.0), Vector3.BACK, 0.95, 1.25, _wins[(g + 2) % _wins.size()], T.trim, true)
	_win(Vector3(-w / 2.0, 1.45, -deep * 0.55), Vector3.LEFT, 0.9, 1.2, dark, T.trim)
	_win(Vector3(w / 2.0, 1.45, -deep * 0.4), Vector3.RIGHT, 0.9, 1.2, _wins[(g + 1) % _wins.size()], T.trim)
	if gable_front:
		_roof(-w / 2.0, w / 2.0, -deep, 0.0, hh, w * 0.42, false, roof_m, wall_m)
		if storeys == 1:
			_win(Vector3(0.0, hh + 0.9, 0.0), Vector3.BACK, 0.7, 0.9, dark, T.trim)
	else:
		_roof(-w / 2.0, w / 2.0, -deep, 0.0, hh, deep * 0.36, true, roof_m, wall_m)
	if porch:
		var pw := w - 0.8
		_bx(Vector3(pw, 0.12, 2.0), Vector3(0, -0.11, 1.0), T.planks)
		_bx(Vector3(pw, maxf(drop - 0.17, 0.05), 0.06), Vector3(0, -0.17 - maxf(drop - 0.17, 0.05) / 2.0, 1.97), M.dark)
		for px in [-pw / 2.0 + 0.08, pw / 2.0 - 0.08]:
			_bx(Vector3(0.12, 2.45, 0.12), Vector3(px, 1.17, 1.9), T.trim)
		_bx(Vector3(pw + 0.3, 0.1, 2.3), Vector3(0, 2.48, 1.05), roof_m, Vector3(-6.0, 0, 0))
		var steps := maxi(1, ceili((drop - 0.2) / 0.18))
		for k in steps:
			var sy := -0.05 - 0.18 * (k + 1)
			_bx(Vector3(1.3, 0.18, 0.3), Vector3(w * 0.02, sy + 0.09, 2.15 + 0.3 * k), T.walk)
	_xf = keep


# ---------------------------------------------------------------- the main street

func _main_street() -> void:
	# the road, curb to curb; the sidewalks a step up either side, their faces the curbs
	_along(MAIN_X, CURB * 2.0, 0.01, 0.3, T.asphalt)
	for s in [-1.0, 1.0]:
		_along(MAIN_X + s * (CURB + WALK) / 2.0, WALK - CURB, KERB, 0.6, T.walk)
	# its centre line, worn
	var a := atan(RISE)
	var z := FOOT - 3.0
	while z > TOP_Z + 2.0:
		_bx(Vector3(0.12, 0.012, 3.0), Vector3(MAIN_X, street_y(z) + 0.016, z), T.yellow, Vector3(rad_to_deg(a), 0, 0))
		z -= 7.0
	# the heritage lamps, both sides, and their light on the sidewalk and the road
	var i := 0
	for lz in [21.0, -1.0, -23.0, -45.0, -67.0, -91.0, -113.0]:
		for s in [-1, 1]:
			_lamp_post(Vector3(MAIN_X + s * (CURB + 0.45), street_y(lz) + KERB, lz), s, i % 4)
			i += 1
	_power_lines()
	# parked cars, both sides, nose uphill on the north side, down on the south; a pickup outside
	# the old bank
	var cars := [[1, 13.0, 0], [1, -3.0, 1], [1, -31.0, 2], [1, -58.0, 3], [1, -70.0, 4], [1, -104.0, 5],
		[-1, 18.5, 6], [-1, 5.0, 7], [-1, -40.0, 0], [-1, -64.0, 2], [-1, -90.0, 5]]
	for c in cars:
		_car(int(c[0]), float(c[1]), T.cars[int(c[2])])
	var pz := -77.5
	var pickup := model("res://models/truck.glb", Vector3(MAIN_X - 4.8, street_y(pz) + 0.01, pz), far)
	pickup.rotation = Vector3(-a, PI, 0.0)
	_repaint(pickup, Color("5d6b78"))
	anchors["street_pickup"] = pickup.position + Vector3(0, 1.3, 0)


# a strip along the main street (its middle at x, w across), its top `top` over the road's line,
# `thick` deep: in pieces of about a square each, tilted with the street
func _along(x: float, w: float, top: float, thick: float, m: Material) -> void:
	var a := atan(RISE)
	var n := Vector3(0.0, 1.0, RISE).normalized()
	var z0 := FOOT
	while z0 > TOP_Z + 0.01:
		var z1 := maxf(z0 - CHUNK, TOP_Z)
		var zc := (z0 + z1) / 2.0
		var c := Vector3(x, street_y(zc) + top, zc) - n * thick / 2.0
		_bx(Vector3(w, thick, (z0 - z1) / cos(a) + 0.02), c, m, Vector3(rad_to_deg(a), 0, 0))
		z0 = z1


# A lamp post on the sidewalk, its globe on top: its light on the walk and the road beside it.
func _lamp_post(at: Vector3, side: int, g: int) -> void:
	_cy(0.15, 0.18, 0.55, at + Vector3(0, 0.275, 0), T.pole, 10)
	_cy(0.055, 0.07, 3.4, at + Vector3(0, 2.2, 0), T.pole, 8)
	_cy(0.11, 0.06, 0.26, at + Vector3(0, 4.03, 0), T.pole, 10)
	_sp(0.23, at + Vector3(0, 4.36, 0), _lamps[g][0], 12)
	_cy(0.02, 0.13, 0.15, at + Vector3(0, 4.64, 0), T.pole, 10)
	var a := atan(RISE)
	var b := Basis(Vector3.RIGHT, a) * Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))
	_pool(at + Vector3(-side * 1.4, 0.02, 0), 9.0, g, b)


# the wires along the south side, pole to pole, sagging
func _power_lines() -> void:
	var tops: Array = []
	for z in [24.0, -7.0, -37.0, -61.0, -95.0, -126.0]:
		var base := Vector3(MAIN_X - 7.9, street_y(z) + KERB, z)
		_cy(0.13, 0.17, 10.0, base + Vector3(0, 5.0, 0), T.wood_pole, 8)
		_bx(Vector3(2.0, 0.11, 0.12), base + Vector3(0, 9.45, 0), T.wood_pole)
		for ox in [-0.85, 0.0, 0.85]:
			_cy(0.035, 0.045, 0.14, base + Vector3(ox, 9.58, 0), M.porcelain, 6)
		tops.append(base + Vector3(0, 9.68, 0))
	for i in range(tops.size() - 1):
		for ox in [-0.85, 0.0, 0.85]:
			_wire(tops[i] + Vector3(ox, 0, 0), tops[i + 1] + Vector3(ox, 0, 0), 0.55)
	# a transformer on the pole across from the bank
	_cy(0.3, 0.3, 0.9, Vector3(MAIN_X - 7.6, street_y(-61.0) + KERB + 7.6, -61.0), M.steel, 10)


func _wire(a: Vector3, b: Vector3, sag: float) -> void:
	var prev := a
	for k in range(1, 9):
		var t := k / 8.0
		var p := a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		var d := p - prev
		_bb(Vector3(0.04, 0.04, d.length()), (p + prev) / 2.0, M.black, Basis.looking_at(d, Vector3.UP))
		prev = p


# A car parked along the curb: north side nose uphill, south side nose down.
func _car(side: int, z: float, paint: Material) -> void:
	var a := atan(RISE)
	var keep := _xf
	var yaw := 0.0 if side > 0 else PI
	_xf = Transform3D(Basis.from_euler(Vector3(a if side > 0 else -a, yaw, 0.0)), Vector3(MAIN_X + side * 4.75, street_y(z) + 0.01, z))
	_bx(Vector3(1.78, 0.62, 4.4), Vector3(0, 0.6, 0), paint)
	_bx(Vector3(1.6, 0.5, 2.25), Vector3(0, 1.15, 0.25), paint)
	_bx(Vector3(1.5, 0.42, 0.04), Vector3(0, 1.13, -0.86), T.glass_dk, Vector3(35, 0, 0))
	_bx(Vector3(1.5, 0.4, 0.04), Vector3(0, 1.13, 1.37), T.glass_dk, Vector3(-30, 0, 0))
	for sx in [-0.81, 0.81]:
		_bx(Vector3(0.03, 0.36, 1.9), Vector3(sx, 1.16, 0.25), T.glass_dk)
		for wz in [-1.35, 1.4]:
			_cy(0.33, 0.33, 0.22, Vector3(sx * 0.95, 0.33, wz), T.tire, 12, Vector3(0, 0, 90))
	for sx in [-0.6, 0.6]:
		_bx(Vector3(0.3, 0.1, 0.03), Vector3(sx, 0.72, -2.2), M.porcelain)
		_bx(Vector3(0.28, 0.12, 0.03), Vector3(sx, 0.75, 2.2), T.tail)
	_bx(Vector3(1.8, 0.1, 0.06), Vector3(0, 0.38, -2.22), T.chrome)
	_bx(Vector3(1.8, 0.1, 0.06), Vector3(0, 0.38, 2.22), T.chrome)
	_xf = keep


# ---------------------------------------------------------------- up the north side

func _north_side() -> void:
	_legion()
	_library()
	var z0 := -40.0
	var z1 := -31.0
	var f := street_y(z1) + KERB + 0.45
	_house(Vector3(MAIN_X + 12.0, street_y((z0 + z1) / 2.0) + KERB + 0.45, (z0 + z1) / 2.0), -90.0, z1 - z0, 10.0, 2, T.clap[0], T.roof, true, 1, _drop(z1, f) + 0.3)
	_white_church()
	z0 = -73.0
	z1 = -64.5
	f = street_y((z0 + z1) / 2.0) + KERB + 0.45
	_house(Vector3(MAIN_X + 11.5, f, (z0 + z1) / 2.0), -90.0, z1 - z0, 9.0, 1, T.clap[1], T.roof_b, false, 2, _drop(z1, f))
	var more := [[-99.0, -90.0, 12.0, 2, 2, T.roof, true, 3], [-112.0, -103.0, 12.5, 3, 1, T.roof_g, false, 0],
		[-126.0, -116.0, 11.0, 4, 2, T.roof, true, 4]]
	for m in more:
		f = street_y((float(m[0]) + float(m[1])) / 2.0) + KERB + 0.45
		_house(Vector3(MAIN_X + float(m[2]), f, (float(m[0]) + float(m[1])) / 2.0), -90.0, float(m[1]) - float(m[0]), 10.0, int(m[4]),
			T.clap[int(m[3])], m[5], m[6], int(m[7]), _drop(float(m[1]), f))
	# a maple on the lawn by the library, another up by the church
	_bare(Vector3(MAIN_X + 9.6, street_y(-12.0) + KERB, -12.0), 9.0)
	_bare(Vector3(MAIN_X + 9.8, street_y(-62.0) + KERB, -62.0), 8.0)


# The Legion: a long low hall set back behind its lawn, a gun on a plinth out front, a plain sign.
func _legion() -> void:
	var z0 := -9.0
	var z1 := 15.0
	var len := z1 - z0
	var d := 14.0
	var keep := _xf
	_xf = _on_street(1, d, z0, z1, 0.3)
	var f := _xf.origin.y
	var drop := _drop(z1, f)
	var deep := 13.0
	_bx(Vector3(len, 4.0 + drop, deep), Vector3(0, (4.0 - drop) / 2.0, -deep / 2.0), T.stucco)
	_roof(-len / 2.0, len / 2.0, -deep, 0.0, 4.0, 1.4, true, T.roof_g, T.stucco, 0.5)
	# its windows, small and high, the bar behind them lit
	for wx in [-9.0, -5.5, 6.0, 9.5]:
		_win(Vector3(wx, 2.0, 0.0), Vector3.BACK, 1.2, 0.9, _wins[1], T.trim)
	# the porch over the doors, the doors, the walk out to the sidewalk
	var ex := -3.0
	_bx(Vector3(3.2, 3.0 + drop, 1.6), Vector3(ex, (3.0 - drop) / 2.0, 0.8), T.stucco)
	_roof(ex - 1.6, ex + 1.6, 0.0, 1.8, 3.0, 0.8, false, T.roof_g, T.stucco, 0.25)
	_bx(Vector3(1.8, 2.2, 0.08), Vector3(ex, 1.1, 1.62), M.dark)
	_bx(Vector3(0.03, 2.1, 0.09), Vector3(ex, 1.1, 1.67), T.trim_dk)
	_bx(Vector3(1.6, 0.3, 4.4), Vector3(ex, -0.15 - drop * 0.3, 3.8), T.walk)
	_plate("legion", 4.2, 0.49, Vector3(ex, 3.45, 0.02), Basis.IDENTITY, T.pic)
	anchors["street_legion"] = _xf * Vector3(0, 2.4, 0)
	# the gun, on its plinth on the lawn, aimed up the street at the old bank's door (walk.ink)
	var g := _xf * Vector3(10.0, 0.0, 3.0)
	_xf = keep
	g.y = ground_y(g.x, g.z)
	_gun(g, Vector3(MAIN_X - WALK, 0.0, -76.0))


# A field gun, an old one, on a concrete plinth, aimed at `aim` (in its own frame, along -x)
func _gun(at: Vector3, aim: Vector3) -> void:
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, atan2(aim.z - at.z, at.x - aim.x)), at)
	at = Vector3.ZERO
	_bx(Vector3(1.7, 0.7, 3.0), at + Vector3(0, 0.35, 0), M.concrete)
	var top := at + Vector3(0, 0.7, 0)
	for sz in [-0.78, 0.78]:
		_cy(0.6, 0.6, 0.09, top + Vector3(0, 0.6, sz), T.olive, 14, Vector3(90, 0, 0))
		_cy(0.12, 0.12, 0.14, top + Vector3(0, 0.6, sz), T.olive, 8, Vector3(90, 0, 0))
	_cy(0.05, 0.05, 1.6, top + Vector3(0, 0.6, 0), T.olive, 8, Vector3(90, 0, 0))
	_bx(Vector3(0.04, 1.0, 1.4), top + Vector3(-0.28, 1.05, 0), T.olive, Vector3(0, 0, -10))
	_cy(0.055, 0.09, 2.4, top + Vector3(-0.75, 1.0, 0), T.olive, 10, Vector3(0, 0, 82))
	_bx(Vector3(0.5, 0.26, 0.34), top + Vector3(0.2, 0.86, 0), T.olive)
	_bx(Vector3(2.3, 0.18, 0.22), top + Vector3(1.15, 0.42, 0), T.olive, Vector3(0, 0, -14))
	anchors["street_gun"] = _xf * (top + Vector3(0, 0.9, 0))
	_xf = keep


# The library: small, brick, up a flight of steps, a stone sign carved over the door; a lamp on in
# one window.
func _library() -> void:
	var z0 := -27.0
	var z1 := -14.0
	var len := z1 - z0
	var keep := _xf
	_xf = _on_street(1, 10.5, z0, z1, 1.05)
	var f := _xf.origin.y
	var drop := _drop(z1, f)
	var deep := 11.0
	_bx(Vector3(len, 4.4 + drop, deep), Vector3(0, (4.4 - drop) / 2.0, -deep / 2.0), T.brick)
	_bx(Vector3(len + 0.12, drop, deep + 0.12), Vector3(0, -drop / 2.0, -deep / 2.0), T.sandstone)
	_bx(Vector3(len + 0.6, 0.4, 0.5), Vector3(0, 4.2, 0.05), T.sandstone)
	_bx(Vector3(len, 0.7, deep), Vector3(0, 4.75, -deep / 2.0), T.brick)
	_bx(Vector3(len + 0.2, 0.12, 0.4), Vector3(0, 5.15, 0.0), T.sandstone)
	# the door in its stone surround, the sign over it, the steps
	_bx(Vector3(2.3, 3.2, 0.12), Vector3(0, 1.6, 0.06), T.sandstone)
	_bx(Vector3(1.5, 2.4, 0.06), Vector3(0, 1.2, 0.13), M.dark)
	_bx(Vector3(0.03, 2.3, 0.07), Vector3(0, 1.2, 0.165), T.trim_dk)
	_plate("library", 3.6, 0.39, Vector3(0, 3.55, 0.03), Basis.IDENTITY, T.carved)
	var steps := 6
	for k in steps:
		var sy := -0.175 * (k + 1)
		_bx(Vector3(3.0, 0.175 + 0.3, 0.32), Vector3(0, sy + 0.0875 - 0.15, 0.3 + 0.3 * k), M.concrete)
	for sx in [-1.25, 1.25]:
		_bx(Vector3(0.04, 0.04, 2.1), Vector3(sx, 0.0, 1.2), M.steel, Vector3(-28, 0, 0))
	# the windows: tall, stone sills and heads; the lamp's on in one of them
	for wx in [-4.5, -2.7, 2.7, 4.5]:
		_win(Vector3(wx, 1.85, 0.0), Vector3.BACK, 1.1, 2.3, T.shop if wx == 2.7 else T.glass_dk, T.sandstone, true)
	anchors["street_library"] = _xf * Vector3(0, 2.0, 0)
	_xf = keep


# The white church: wooden, its gable to the street, the steeple over its doors.
func _white_church() -> void:
	var z0 := -59.0
	var z1 := -49.0
	var w := z1 - z0
	var keep := _xf
	_xf = _on_street(1, 11.0, z0, z1, 0.6)
	var f := _xf.origin.y
	var drop := _drop(z1, f)
	var deep := 18.0
	_bx(Vector3(w, 6.0 + drop, deep), Vector3(0, (6.0 - drop) / 2.0, -deep / 2.0), T.white)
	_roof(-w / 2.0, w / 2.0, -deep, 0.0, 6.0, 4.6, false, T.roof, T.white, 0.4)
	# the tower, out a little from the front; the belfry; the spire
	_bx(Vector3(3.4, 9.8 + drop, 3.4), Vector3(0, (9.8 - drop) / 2.0, 0.6 - 1.7), T.white)
	_bx(Vector3(3.0, 2.2, 3.0), Vector3(0, 10.9, -1.1), T.white)
	for face in [Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD]:
		_put(_box(Vector3(1.4, 1.4, 0.06)), Transform3D(facing(face), Vector3(0, 10.9, -1.1) + face * 1.51), M.dark)
	_bx(Vector3(3.3, 0.2, 3.3), Vector3(0, 12.05, -1.1), T.trim)
	_cy(0.0, 2.15, 9.0, Vector3(0, 16.6, -1.1), T.roof, 8)
	_bx(Vector3(0.08, 1.1, 0.08), Vector3(0, 21.6, -1.1), M.black)
	_bx(Vector3(0.6, 0.08, 0.08), Vector3(0, 21.8, -1.1), M.black)
	# its doors, under a pointed head; the window over them; the steps
	_bx(Vector3(1.7, 2.6, 0.08), Vector3(0, 1.3, 0.63), M.dark)
	_pointed(Vector3(0, 2.6, 0.62), 1.7, 0.6, M.dark)
	_win(Vector3(0, 5.6, 0.6), Vector3.BACK, 0.8, 1.6, T.glass_dk, T.trim)
	_pointed(Vector3(0, 6.48, 0.66), 0.96, 0.4, T.trim)
	for k in 3:
		_bx(Vector3(2.6, 0.2, 0.3), Vector3(0, -0.1 - 0.2 * k, 0.85 + 0.3 * k), M.concrete)
	# pointed windows down its sides and either side of the tower
	for wx in [-3.4, 3.4]:
		_win(Vector3(wx, 2.6, 0.0), Vector3.BACK, 0.9, 2.4, T.glass_dk, T.trim)
		_pointed(Vector3(wx, 3.88, 0.04), 1.06, 0.45, T.trim)
	for zz in [-4.0, -8.0, -12.0, -16.0]:
		for s in [-1.0, 1.0]:
			_win(Vector3(s * w / 2.0, 2.8, zz), Vector3(s, 0, 0), 1.0, 2.6, T.glass_dk, T.trim)
	# its board on the lawn
	_bx(Vector3(0.08, 1.0, 0.08), Vector3(-2.4, -0.1, 2.6), M.dark)
	_bx(Vector3(0.08, 1.0, 0.08), Vector3(-0.8, -0.1, 2.6), M.dark)
	_bx(Vector3(1.8, 1.25, 0.08), Vector3(-1.6, 0.85, 2.6), T.trim)
	_plate("church", 1.6, 1.15, Vector3(-1.6, 0.85, 2.65), Basis.IDENTITY, T.pic)
	anchors["street_church"] = _xf * Vector3(0, 9.0, -1.1)
	_xf = keep


# a pointed head over a door or a window: a triangle, its foot `w` wide at c, `rise` up
func _pointed(c: Vector3, w: float, rise: float, m: Material) -> void:
	_begin()
	_tri(c + Vector3(-w / 2.0, 0, 0), c + Vector3(w / 2.0, 0, 0), c + Vector3(0, rise, 0), Vector3.BACK)
	_put(_end(), Transform3D.IDENTITY, m)


# ---------------------------------------------------------------- down the south side

func _south_side() -> void:
	_video()
	_thrift()
	_barber()
	var houses := [[-25.0, -16.0, 11.0, 1, 2, T.roof, true, 2], [-40.0, -29.0, 12.0, 2, 1, T.roof_b, false, 1],
		[-68.0, -58.0, 11.0, 5, 2, T.roof, true, 3], [-94.0, -86.0, 11.5, 0, 1, T.roof_g, false, 4],
		[-130.0, -121.0, 11.0, 3, 2, T.roof_b, true, 2]]
	for m in houses:
		var f := street_y((float(m[0]) + float(m[1])) / 2.0) + KERB + 0.45
		_house(Vector3(MAIN_X - float(m[2]), f, (float(m[0]) + float(m[1])) / 2.0), 90.0, float(m[1]) - float(m[0]), 10.0, int(m[4]),
			T.clap[int(m[3])], m[5], m[6], int(m[7]), _drop(float(m[1]), f))
	_bank()
	_stone_church()
	_bare(Vector3(MAIN_X - 9.7, street_y(-52.0) + KERB, -52.0), 9.5)


# A shop front at the sidewalk: the glass from x0 to x1 (along the street, in the building's frame)
# and `h` up from the floor, and through it the shop, lit, `deep` back: its back wall and sides
# giving the light, its floor, and whatever's in it (`things`, built in the same frame).
func _shop_front(x0: float, x1: float, h: float, deep: float, lit: Material, things := Callable()) -> void:
	var w := x1 - x0
	var xm := (x0 + x1) / 2.0
	_bx(Vector3(w, h, 0.02), Vector3(xm, h / 2.0, -0.05), M.glass)
	_bx(Vector3(w, h, 0.04), Vector3(xm, h / 2.0, -deep), lit)
	_bx(Vector3(0.04, h, deep), Vector3(x0, h / 2.0, -deep / 2.0), lit)
	_bx(Vector3(0.04, h, deep), Vector3(x1, h / 2.0, -deep / 2.0), lit)
	_bx(Vector3(w, 0.04, deep), Vector3(xm, 0.0, -deep / 2.0), T.walk)
	_bx(Vector3(w, 0.04, deep), Vector3(xm, h, -deep / 2.0), M.dark)
	for fx in [x0, x1]:
		_bx(Vector3(0.12, h, 0.12), Vector3(fx, h / 2.0, -0.02), T.trim_dk)
	_bx(Vector3(w + 0.12, 0.14, 0.14), Vector3(xm, h, -0.02), T.trim_dk)
	_bx(Vector3(w + 0.12, 0.35, 0.16), Vector3(xm, 0.17, 0.0), T.trim_dk)
	if things.is_valid():
		things.call()


# The video store, shut for years: its windows papered over, the sign still up, a lease notice.
func _video() -> void:
	var z0 := 13.0
	var z1 := 25.0
	var len := z1 - z0
	var keep := _xf
	_xf = _on_street(-1, WALK, z0, z1)
	var f := _xf.origin.y
	var drop := _drop(z1, f)
	_bx(Vector3(len, 4.3 + drop, 14.0), Vector3(0, (4.3 - drop) / 2.0, -7.0), T.stucco_b)
	_bx(Vector3(len + 0.2, 1.1, 0.3), Vector3(0, 4.05, 0.1), T.trim)
	_plate("video", 5.2, 0.9, Vector3(0, 4.05, 0.26), Basis.IDENTITY, T.pic)
	for wx in [-3.6, 3.6]:
		_bx(Vector3(4.0, 2.3, 0.08), Vector3(wx, 1.65, 0.02), T.paper_win)
		_bx(Vector3(4.15, 2.45, 0.05), Vector3(wx, 1.65, 0.0), T.trim_dk)
	_plate("lease", 0.6, 0.39, Vector3(3.2, 1.7, 0.07), Basis.IDENTITY, T.pic)
	_bx(Vector3(1.1, 2.2, 0.06), Vector3(0, 1.1, 0.03), T.glass_dk)
	_bx(Vector3(1.25, 2.3, 0.04), Vector3(0, 1.15, 0.0), T.trim_dk)
	_xf = keep


# The thrift store: two storeys of old boards, the shop lit, racks of coats in the window.
func _thrift() -> void:
	var z0 := 1.0
	var z1 := 12.0
	var len := z1 - z0
	var keep := _xf
	_xf = _on_street(-1, WALK, z0, z1)
	var f := _xf.origin.y
	var drop := _drop(z1, f)
	var deep := 16.0
	_bx(Vector3(len, 7.2 + drop, deep - 1.9), Vector3(0, (7.2 - drop) / 2.0, -1.9 - (deep - 1.9) / 2.0), T.clap[2])
	_bx(Vector3(len, 3.8, 1.9), Vector3(0, 3.4 + 1.9, -0.95), T.clap[2])
	_bx(Vector3(len, drop, 1.9), Vector3(0, -drop / 2.0, -0.95), T.clap[2])
	for px in [-len / 2.0 + 0.5, len / 2.0 - 0.5]:
		_bx(Vector3(1.0, 3.4, 1.9), Vector3(px, 1.7, -0.95), T.clap[2])
	_shop_front(-len / 2.0 + 1.0, len / 2.0 - 1.0, 2.8, 1.8, T.shop, func():
		for rx in [-3.2, -1.2, 1.6, 3.4]:
			_bx(Vector3(1.4, 1.3, 0.5), Vector3(rx, 0.95, -1.0), T.goods[int(absf(rx * 2.0)) % T.goods.size()])
			_bx(Vector3(1.6, 0.04, 0.04), Vector3(rx, 1.65, -1.0), M.steel))
	_bx(Vector3(len + 0.3, 0.6, 0.12), Vector3(0, 3.1, 0.06), T.trim_dk)
	_plate("thrift", 5.6, 0.66, Vector3(0, 3.1, 0.13), Basis.IDENTITY, T.pic)
	_bx(Vector3(len + 0.5, 0.35, 0.4), Vector3(0, 7.2, 0.1), T.trim_dk)
	for wx in [-3.5, 0.0, 3.5]:
		_win(Vector3(wx, 5.1, 0.0), Vector3.BACK, 1.0, 1.5, _wins[2] if wx == 0.0 else T.glass_dk, T.trim, true)
	_xf = keep


# A shop shut down, its blind down; somebody living over it.
func _barber() -> void:
	var z0 := -12.0
	var z1 := -1.0
	var len := z1 - z0
	var keep := _xf
	_xf = _on_street(-1, WALK, z0, z1)
	var f := _xf.origin.y
	var drop := _drop(z1, f)
	_bx(Vector3(len, 7.0 + drop, 14.0), Vector3(0, (7.0 - drop) / 2.0, -7.0), T.clap[5])
	_bx(Vector3(7.0, 2.4, 0.06), Vector3(-1.2, 1.6, 0.03), T.glass_dk)
	_bx(Vector3(7.0, 1.2, 0.07), Vector3(-1.2, 2.2, 0.04), T.blind)
	_bx(Vector3(7.2, 2.6, 0.04), Vector3(-1.2, 1.6, 0.0), T.trim_dk)
	_bx(Vector3(1.0, 2.2, 0.06), Vector3(3.6, 1.1, 0.03), M.dark)
	_bx(Vector3(len + 0.4, 0.3, 0.35), Vector3(0, 7.0, 0.1), T.trim)
	for wx in [-3.5, 0.0, 3.5]:
		_win(Vector3(wx, 4.9, 0.0), Vector3.BACK, 1.0, 1.4, _wins[3] if wx == -3.5 else T.glass_dk, T.trim, true)
	_xf = keep


# The old bank, a cafe now: a sandstone front, two columns at the door, BANK still carved over it;
# the chalkboard out on the sidewalk. Across the street from Gary's window.
func _bank() -> void:
	var z0 := -82.0
	var z1 := -70.0
	var len := z1 - z0
	var keep := _xf
	_xf = _on_street(-1, WALK, z0, z1, 0.3)
	var f := _xf.origin.y
	var drop := _drop(z1, f)
	var deep := 15.0
	_bx(Vector3(len, 7.8 + drop, deep - 2.0), Vector3(0, (7.8 - drop) / 2.0, -2.0 - (deep - 2.0) / 2.0), T.brick)
	# the front, sandstone, with its windows' shops behind
	_bx(Vector3(len, 4.4, 2.0), Vector3(0, 3.4 + 2.2, -1.0), T.sandstone)
	_bx(Vector3(len, drop, 2.0), Vector3(0, -drop / 2.0, -1.0), T.sandstone)
	for px in [-5.5, -2.4, 2.4, 5.5]:
		_bx(Vector3(1.0 if absf(px) > 5.0 else 0.8, 3.4, 2.0), Vector3(px, 1.7, -1.0), T.sandstone)
	var cafe := func():
		for tx in [-0.6, 0.7]:
			_cy(0.32, 0.32, 0.04, Vector3(tx, 0.74, -1.1), M.dark, 12)
			_cy(0.03, 0.03, 0.72, Vector3(tx, 0.36, -1.1), M.dark, 6)
			_bx(Vector3(0.4, 0.04, 0.4), Vector3(tx + 0.45, 0.46, -0.9), M.dark)
	for wx in [-3.95, 3.95]:
		_xf = _xf * Transform3D(Basis.IDENTITY, Vector3(wx, 0, 0))
		_shop_front(-1.1, 1.1, 2.9, 1.9, T.shop, cafe)
		_xf = _xf * Transform3D(Basis.IDENTITY, Vector3(-wx, 0, 0))
	# the doors, glass, the cafe through them
	_xf = _xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.4))
	_shop_front(-1.6, 1.6, 2.7, 2.2, T.shop)
	_xf = _xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.4))
	_bx(Vector3(0.05, 2.7, 0.05), Vector3(0, 1.35, -0.42), T.trim_dk)
	_bx(Vector3(3.6, 0.6, 2.0), Vector3(0, 3.1, -1.0), T.sandstone)
	# the columns, the beam over them with the word on it
	for cx in [-1.6, 1.6]:
		_bx(Vector3(0.75, 0.35, 0.75), Vector3(cx, 0.175, 0.55), T.sandstone)
		_cy(0.26, 0.29, 4.3, Vector3(cx, 2.5, 0.55), T.sandstone, 14)
		_bx(Vector3(0.8, 0.3, 0.8), Vector3(cx, 4.8, 0.55), T.sandstone)
	_bx(Vector3(4.4, 0.95, 1.0), Vector3(0, 5.42, 0.4), T.sandstone)
	_plate("bank", 3.3, 0.71, Vector3(0, 5.42, 0.91), Basis.IDENTITY, T.carved)
	_bx(Vector3(4.9, 0.25, 1.2), Vector3(0, 6.0, 0.4), T.sandstone)
	# the cornice, the windows upstairs
	_bx(Vector3(len + 0.8, 0.5, 0.8), Vector3(0, 7.55, 0.1), T.sandstone)
	_bx(Vector3(len, 0.7, 0.4), Vector3(0, 8.1, -0.2), T.sandstone)
	for wx in [-3.95, 3.95]:
		_win(Vector3(wx, 6.55, 0.0), Vector3.BACK, 1.3, 1.5, _wins[4] if wx < 0.0 else T.glass_dk, T.sandstone, true)
	for k in 2:
		_bx(Vector3(3.6, 0.15, 0.32), Vector3(0, -0.075 - 0.15 * k, 0.75 + 0.3 * k), T.sandstone)
	anchors["street_bank"] = _xf * Vector3(0, 4.5, 0.5)
	# the chalkboard on the sidewalk, toward the street
	var cb := _xf * Vector3(2.6, -0.3, 1.6)
	cb.y = street_y(cb.z) + KERB
	_xf = keep
	for s in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, deg_to_rad(-12.0 * s))
		_bb(Vector3(0.62, 0.92, 0.03), cb + Vector3(s * 0.1, 0.45, 0), M.wood, b)
	var face := Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, deg_to_rad(-12.0))
	_put(_quad_p(0.54, 0.74, Rect2(PLATES.chalk.position / ATLAS, PLATES.chalk.size / ATLAS)), Transform3D(face, cb + Vector3(0.122, 0.47, 0) + face * Vector3(0, 0, 0.018)), T.pic)


# The grey stone church further up, its square tower at the corner.
func _stone_church() -> void:
	var z0 := -112.0
	var z1 := -100.0
	var w := z1 - z0
	var keep := _xf
	_xf = _on_street(-1, 10.0, z0, z1, 0.5)
	var f := _xf.origin.y
	var drop := _drop(z1, f) + 0.4
	var deep := 20.0
	_bx(Vector3(w, 6.5 + drop, deep), Vector3(0, (6.5 - drop) / 2.0, -deep / 2.0), T.stone)
	_roof(-w / 2.0, w / 2.0, -deep, 0.0, 6.5, 5.2, false, T.roof, T.stone, 0.3)
	# the tower beside it, on the downhill side (in this frame, -x)
	var tx := -w / 2.0 - 2.25
	_bx(Vector3(4.5, 15.0 + drop, 4.5), Vector3(tx, (15.0 - drop) / 2.0, -2.25), T.stone)
	for k in 4:
		for s in [-1.0, 1.0]:
			_bx(Vector3(0.6, 0.7, 0.5), Vector3(tx - 1.6 + k * 1.07, 15.35, -2.25 + s * 2.0), T.stone)
			_bx(Vector3(0.5, 0.7, 0.6), Vector3(tx + s * 2.0, 15.35, -3.85 + k * 1.07), T.stone)
	_bx(Vector3(1.4, 2.4, 0.08), Vector3(tx, 1.2, 0.04), M.dark)
	_pointed(Vector3(tx, 2.4, 0.05), 1.4, 0.5, M.dark)
	_win(Vector3(tx, 9.5, 0.0), Vector3.BACK, 0.7, 2.0, T.glass_dk, T.stone)
	# the great window in the gable, lancets down the side he can see
	_win(Vector3(0, 3.6, 0.0), Vector3.BACK, 1.8, 4.0, T.glass_dk, T.stone)
	_pointed(Vector3(0, 5.68, 0.05), 1.96, 0.9, T.stone)
	for zz in [-7.0, -11.5, -16.0]:
		for s in [-1.0, 1.0]:
			_win(Vector3(s * w / 2.0, 3.0, zz), Vector3(s, 0, 0), 0.9, 2.8, T.glass_dk, T.stone)
	_xf = keep


# ---------------------------------------------------------------- Gary's house, from outside

# Two storeys of old boards on the north side, across from the bank: the porch along its front, the
# steps down to the sidewalk, the door with the name on its glass, the front room's window.
func _garys_house() -> void:
	var x0 := OFFICE_X - 0.2           # the front's outside
	var x1 := -177.0
	var z0 := OFFICE_Z - OFFICE_W / 2.0 - 0.2
	var z1 := -76.6
	var y := OFFICE_Y
	var ground := street_y(z1) + 0.12
	var wall_m: Material = T.clap[1]
	# the front, round the room's window and door and the other room's window
	var holes := [[OFFICE_W / 2.0 + 0.2 - 1.55, OFFICE_W / 2.0 + 0.2 - 0.65, 0.0, 2.1],
		[OFFICE_W / 2.0 + 0.2 + 0.35, OFFICE_W / 2.0 + 0.2 + 1.75, 0.8, 2.25], [5.9, 7.2, 0.8, 2.25]]
	_wallh(Vector2(x0 + 0.075, z0), Vector2(x0 + 0.075, z1), y - 0.12, 3.07, wall_m, holes, 0.15)
	# the other room behind its window: dark
	_bx(Vector3(x1 - x0 - 0.2, 2.95, z1 - OFFICE_Z - OFFICE_W / 2.0 - 0.1), Vector3((x0 + x1) / 2.0 + 0.1, y + 1.475, (OFFICE_Z + OFFICE_W / 2.0 + 0.1 + z1) / 2.0), wall_m)
	_win(Vector3(x0, y + 1.525, z0 + 6.55), Vector3.LEFT, 1.3, 1.45, T.glass_dk, T.trim, true)
	# the room's side wall, outside; the rooms behind it
	_bx(Vector3(x1 - x0, 3.07, 0.2), Vector3((x0 + x1) / 2.0, y - 0.12 + 1.535, z0 + 0.1), wall_m)
	_bx(Vector3(x1 - (OFFICE_X + OFFICE_D) - 0.05, 3.07, OFFICE_W), Vector3((OFFICE_X + OFFICE_D + 0.05 + x1) / 2.0, y - 0.12 + 1.535, OFFICE_Z), wall_m)
	_win(Vector3((x0 + x1) / 2.0 + 1.5, y + 1.5, z0), Vector3.FORWARD, 1.0, 1.3, _wins[2], T.trim, true)
	# upstairs, and the roof, its gable to the street
	_bx(Vector3(x1 - x0, 2.65, z1 - z0), Vector3((x0 + x1) / 2.0, y + 2.95 + 1.325, (z0 + z1) / 2.0), wall_m)
	for wz in [z0 + 2.2, z1 - 2.2]:
		_win(Vector3(x0, y + 4.25, wz), Vector3.LEFT, 1.0, 1.4, T.glass_dk, T.trim, true)
	_roof(x0, x1, z0, z1, y + 5.6, 3.2, true, T.roof, wall_m, 0.4)
	_win(Vector3(x0, y + 6.6, (z0 + z1) / 2.0), Vector3.LEFT, 0.7, 0.9, T.glass_dk, T.trim)
	# the foundation, under it all
	_bx(Vector3(x1 - x0, y - 0.12 - ground + 0.4, z1 - z0), Vector3((x0 + x1) / 2.0, (y - 0.12 + ground - 0.4) / 2.0, (z0 + z1) / 2.0), M.concrete)
	# the front door's frame, outside, and the room's window's
	_bx(Vector3(0.06, 2.22, 0.12), Vector3(x0 - 0.02, y + 1.11, OFFICE_Z - 1.6), T.trim)
	_bx(Vector3(0.06, 2.22, 0.12), Vector3(x0 - 0.02, y + 1.11, OFFICE_Z - 0.6), T.trim)
	_bx(Vector3(0.06, 0.14, 1.12), Vector3(x0 - 0.02, y + 2.17, OFFICE_Z - 1.1), T.trim)
	_bx(Vector3(0.08, 1.6, 0.12), Vector3(x0 - 0.02, y + 1.525, OFFICE_Z + 0.29), T.trim)
	_bx(Vector3(0.08, 1.6, 0.12), Vector3(x0 - 0.02, y + 1.525, OFFICE_Z + 1.81), T.trim)
	_bx(Vector3(0.08, 0.12, 1.64), Vector3(x0 - 0.02, y + 2.31, OFFICE_Z + 1.05), T.trim)
	_bx(Vector3(0.16, 0.06, 1.7), Vector3(x0 - 0.06, y + 0.77, OFFICE_Z + 1.05), T.trim)
	# the porch: its deck, the lattice under it, the posts and the rail, its roof
	var px := x0 - 2.4
	_bx(Vector3(2.4, 0.1, z1 - z0 + 0.4), Vector3(x0 - 1.2, y - 0.1, (z0 + z1) / 2.0), T.planks)
	_bx(Vector3(0.06, y - 0.15 - ground + 0.3, z1 - z0 + 0.4), Vector3(px + 0.05, (y - 0.15 + ground - 0.3) / 2.0, (z0 + z1) / 2.0), M.dark)
	var posts := [z0 - 0.1, OFFICE_Z - 0.4, OFFICE_Z + 2.8, z1 + 0.1]
	for pz in posts:
		_bx(Vector3(0.12, 2.7, 0.12), Vector3(px + 0.12, y + 1.3, pz), T.trim)
	for i in range(1, posts.size() - 1):
		var a: float = posts[i]
		var b: float = posts[i + 1]
		_bx(Vector3(0.07, 0.08, b - a), Vector3(px + 0.12, y + 0.86, (a + b) / 2.0), T.trim)
		_bx(Vector3(0.07, 0.06, b - a), Vector3(px + 0.12, y + 0.08, (a + b) / 2.0), T.trim)
		var bz := a + 0.12
		while bz < b - 0.06:
			_bx(Vector3(0.035, 0.76, 0.035), Vector3(px + 0.12, y + 0.47, bz), T.trim)
			bz += 0.14
	var pitch := atan2(0.33, 2.7)
	_bb(Vector3(2.8, 0.1, z1 - z0 + 0.6), Vector3(x0 - 1.35, y + 2.78, (z0 + z1) / 2.0), T.roof, Basis.from_euler(Vector3(0, 0, pitch)))
	_bx(Vector3(0.06, 0.22, z1 - z0 + 0.6), Vector3(px - 0.05, y + 2.55, (z0 + z1) / 2.0), T.trim)
	# the steps down to the sidewalk, at the door
	var top := y - 0.05
	var walk_y := street_y(OFFICE_Z - 1.1) + KERB
	var n := 3
	var rise := (top - walk_y) / float(n)
	for k in n:
		var sy := top - rise * (k + 1)
		_bx(Vector3(0.3, sy - walk_y + 0.3, 1.25), Vector3(px - 0.15 - 0.28 * k, (sy + walk_y - 0.3) / 2.0, OFFICE_Z - 1.1), T.planks)
	# a lamp by the door, and the box for the mail
	_bx(Vector3(0.1, 0.22, 0.14), Vector3(x0 - 0.06, y + 2.05, OFFICE_Z - 1.85), M.dark)
	_sp(0.07, Vector3(x0 - 0.13, y + 1.98, OFFICE_Z - 1.85), _lamps[1][0], 8)
	_bx(Vector3(0.12, 0.32, 0.36), Vector3(x0 - 0.08, y + 1.3, OFFICE_Z - 2.0), M.black)


# ---------------------------------------------------------------- Gary's office

# The front room he runs things from: 4.6 by 5.2, an old fir floor, the wallpaper painted over above
# the wainscot, the ceiling light off. His oak desk faces the front door; the man across it in the
# wooden armchair; the bookkeeper's desk against the wall on his right; the window on his left, the
# blinds half up, the bank across the street through the rain; behind him his father's picture of
# the Sov in 1958. At four o'clock: the grey from the window, and the warm pool of his lamp.
func _office() -> void:
	var u0 := OFFICE_X
	var zc := OFFICE_Z
	var y := OFFICE_Y
	var hw := OFFICE_W / 2.0
	# floor, ceiling, walls
	_bx(Vector3(OFFICE_D, 0.1, OFFICE_W), Vector3(u0 + OFFICE_D / 2.0, y - 0.05, zc), T.fir)
	_bx(Vector3(OFFICE_D, 0.05, OFFICE_W), Vector3(u0 + OFFICE_D / 2.0, y + OFFICE_H + 0.025, zc), T.ceil)
	_bx(Vector3(0.05, OFFICE_H, OFFICE_W), Vector3(u0 + OFFICE_D + 0.025, y + OFFICE_H / 2.0, zc), T.paper_wall)
	_bx(Vector3(OFFICE_D, OFFICE_H, 0.05), Vector3(u0 + OFFICE_D / 2.0, y + OFFICE_H / 2.0, zc + hw + 0.025), T.paper_wall)
	_bx(Vector3(OFFICE_D, OFFICE_H, 0.05), Vector3(u0 + OFFICE_D / 2.0, y + OFFICE_H / 2.0, zc - hw - 0.025), T.paper_wall)
	_wallh(Vector2(u0 - 0.025, zc - hw), Vector2(u0 - 0.025, zc + hw), y, OFFICE_H, T.paper_wall,
		[[hw - 1.55, hw - 0.65, 0.0, 2.1], [hw + 0.35, hw + 1.75, 0.8, 2.25]], 0.05)
	# the skirting, the picture rail
	for s in [-1.0, 1.0]:
		_bx(Vector3(OFFICE_D, 0.12, 0.02), Vector3(u0 + OFFICE_D / 2.0, y + 0.06, zc + s * (hw - 0.01)), T.oak_side)
		_bx(Vector3(OFFICE_D, 0.04, 0.025), Vector3(u0 + OFFICE_D / 2.0, y + 2.25, zc + s * (hw - 0.012)), T.oak_side)
	_bx(Vector3(0.02, 0.12, OFFICE_W), Vector3(u0 + OFFICE_D - 0.01, y + 0.06, zc), T.oak_side)
	_bx(Vector3(0.025, 0.04, OFFICE_W), Vector3(u0 + OFFICE_D - 0.012, y + 2.25, zc), T.oak_side)
	# the window's reveal and casing, its sill; the glass, the rain on it
	var wz0 := zc + 0.35
	var wz1 := zc + 1.75
	var wm := (wz0 + wz1) / 2.0
	_bx(Vector3(0.2, 0.02, 1.4), Vector3(u0 - 0.1, y + 0.81, wm), T.trim_in)
	_bx(Vector3(0.2, 0.02, 1.4), Vector3(u0 - 0.1, y + 2.24, wm), T.trim_in)
	_bx(Vector3(0.2, 1.45, 0.02), Vector3(u0 - 0.1, y + 1.525, wz0 + 0.01), T.trim_in)
	_bx(Vector3(0.2, 1.45, 0.02), Vector3(u0 - 0.1, y + 1.525, wz1 - 0.01), T.trim_in)
	_bx(Vector3(0.025, 0.1, 1.6), Vector3(u0 + 0.0125, y + 2.3, wm), T.trim_in)
	_bx(Vector3(0.025, 1.6, 0.08), Vector3(u0 + 0.0125, y + 1.5, wz0 - 0.04), T.trim_in)
	_bx(Vector3(0.025, 1.6, 0.08), Vector3(u0 + 0.0125, y + 1.5, wz1 + 0.04), T.trim_in)
	_bx(Vector3(0.09, 0.035, 1.62), Vector3(u0 + 0.045, y + 0.8, wm), T.trim_in)
	_bx(Vector3(0.025, 0.09, 1.5), Vector3(u0 + 0.0125, y + 0.74, wm), T.trim_in)
	_bx(Vector3(0.02, 1.43, 1.38), Vector3(u0 - 0.12, y + 1.525, wm), M.glass)
	_bx(Vector3(0.04, 0.04, 1.38), Vector3(u0 - 0.12, y + 1.525, wm), T.trim_in)
	var r := RandomNumberGenerator.new()
	r.seed = 404
	for i in 70:
		var long := r.randf() < 0.18
		_bx(Vector3(0.003, r.randf_range(0.09, 0.24) if long else r.randf_range(0.008, 0.035), 0.005 if long else r.randf_range(0.005, 0.012)),
			Vector3(u0 - 0.135, y + r.randf_range(0.86, 2.2), r.randf_range(wz0 + 0.04, wz1 - 0.04)), M.drop)
	# the blinds, half up: slats tilted open over the top half, the rest of them stacked on the
	# bottom rail, the cords
	_bx(Vector3(0.06, 0.05, 1.44), Vector3(u0 + 0.06, y + 2.2, wm), T.blind)
	var sy := y + 2.15
	while sy > y + 1.58:
		_bx(Vector3(0.05, 0.004, 1.38), Vector3(u0 + 0.065, sy, wm), T.blind, Vector3(0, 0, 38))
		sy -= 0.022
	_bx(Vector3(0.055, 0.07, 1.4), Vector3(u0 + 0.065, y + 1.535, wm), T.blind)
	_bx(Vector3(0.06, 0.02, 1.42), Vector3(u0 + 0.065, y + 1.49, wm), T.blind)
	for cz in [wz0 + 0.3, wz1 - 0.3]:
		_bx(Vector3(0.003, 0.62, 0.003), Vector3(u0 + 0.065, y + 1.87, cz), M.paper)
	_bx(Vector3(0.004, 0.95, 0.004), Vector3(u0 + 0.08, y + 1.7, wz1 - 0.05), M.paper)
	_cy(0.008, 0.012, 0.05, Vector3(u0 + 0.08, y + 1.2, wz1 - 0.05), T.oak_side, 6)
	anchors["office_window"] = Vector3(u0 - 0.1, y + 1.5, wm)
	# the front door: panelled to the waist, glass above with the name on it in gold, backwards
	# from in here
	var dz := zc - 1.1
	var dx := u0 - 0.11
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.2, 2.1, 0.02), Vector3(u0 - 0.1, y + 1.05, dz + s * 0.44), T.trim_in)
		_bx(Vector3(0.025, 2.22, 0.08), Vector3(u0 + 0.0125, y + 1.11, dz + s * 0.49), T.trim_in)
	_bx(Vector3(0.2, 0.02, 0.9), Vector3(u0 - 0.1, y + 2.1, dz), T.trim_in)
	_bx(Vector3(0.025, 0.1, 1.06), Vector3(u0 + 0.0125, y + 2.17, dz), T.trim_in)
	_bx(Vector3(0.045, 1.0, 0.86), Vector3(dx, y + 0.5, dz), T.door_paint)
	_bx(Vector3(0.045, 0.16, 0.86), Vector3(dx, y + 2.0, dz), T.door_paint)
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.045, 0.94, 0.12), Vector3(dx, y + 1.53, dz + s * 0.37), T.door_paint)
	_bx(Vector3(0.01, 0.92, 0.62), Vector3(dx, y + 1.53, dz), M.glass)
	_put(_quad_p(0.6, 0.176, Rect2(PLATES.door.position / ATLAS, PLATES.door.size / ATLAS)), Transform3D(facing(Vector3.LEFT), Vector3(dx - 0.008, y + 1.66, dz)), T.gilt)
	_bx(Vector3(0.02, 0.18, 0.7), Vector3(dx + 0.03, y + 0.55, dz), T.door_paint)
	_sp(0.03, Vector3(dx + 0.06, y + 1.0, dz + 0.36), T.brass, 8)
	_sp(0.03, Vector3(dx - 0.06, y + 1.0, dz + 0.36), T.brass, 8)
	_bx(Vector3(0.7, 0.012, 0.9), Vector3(u0 + 0.45, y + 0.006, dz), M.dark)
	# the old document over the door's side, framed
	var b_in := facing(Vector3.RIGHT)
	_bb(Vector3(0.03, 0.56, 0.46), Vector3(u0 + 0.015, y + 1.95, zc - 0.12), T.oak_side, Basis.IDENTITY)
	_plate("licence", 0.38, 0.48, Vector3(u0 + 0.032, y + 1.95, zc - 0.12), b_in, T.pic_clean)
	anchors["office_licence"] = Vector3(u0 + 0.04, y + 1.95, zc - 0.12)
	# behind Gary, his father's picture of the Sov, the summer of 1958
	var b_back := facing(Vector3.LEFT)
	_bx(Vector3(0.04, 0.84, 1.16), Vector3(u0 + OFFICE_D - 0.02, y + 1.78, zc), M.frame)
	_bx(Vector3(0.01, 0.76, 1.08), Vector3(u0 + OFFICE_D - 0.042, y + 1.78, zc), M.paper)
	_plate("photo58", 0.96, 0.672, Vector3(u0 + OFFICE_D - 0.049, y + 1.78, zc), b_back, T.pic_clean)
	anchors["office_photo"] = Vector3(u0 + OFFICE_D - 0.05, y + 1.78, zc)
	# the ceiling light, off
	_cy(0.2, 0.12, 0.08, Vector3(u0 + 2.6, y + OFFICE_H - 0.07, zc), M.porcelain, 16)
	_cy(0.05, 0.05, 0.03, Vector3(u0 + 2.6, y + OFFICE_H - 0.015, zc), M.frame, 10)
	_desk(u0, zc, y)
	_armchair(Vector3(u0 + 1.9, y, zc))
	_bookkeeping(u0, zc, y)
	_corners(u0, zc, y)
	_office_light(u0, zc, y)


# His desk, square to the door, and what's on it.
func _desk(u0: float, zc: float, y: float) -> void:
	var dm := u0 + 3.35
	_bx(Vector3(0.84, 0.04, 1.56), Vector3(dm, y + 0.74, zc), T.oak)
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.76, 0.72, 0.4), Vector3(dm, y + 0.36, zc + s * 0.56), T.oak_side)
		for k in 3:
			var ky := y + 0.6 - k * 0.22
			_bx(Vector3(0.012, 0.19, 0.36), Vector3(dm + 0.385, ky, zc + s * 0.56), T.oak_side)
			_bx(Vector3(0.02, 0.018, 0.1), Vector3(dm + 0.4, ky, zc + s * 0.56), T.brass)
	_bx(Vector3(0.02, 0.5, 0.72), Vector3(dm - 0.37, y + 0.47, zc), T.oak_side)
	_bx(Vector3(0.6, 0.06, 0.7), Vector3(dm + 0.08, y + 0.69, zc), T.oak_side)
	var top := y + 0.76
	# the lamp: brass, a pleated shade, on
	var lp := Vector3(u0 + 3.12, top, zc + 0.52)
	_cy(0.07, 0.085, 0.025, lp + Vector3(0, 0.0125, 0), T.brass, 16)
	_cy(0.012, 0.012, 0.32, lp + Vector3(0, 0.185, 0), T.brass, 8)
	_put(_pleat_p(0.085, 0.145, 0.17, 18), Transform3D(Basis.IDENTITY, lp + Vector3(0, 0.38, 0)), T.shade)
	_sp(0.03, lp + Vector3(0, 0.34, 0), M.bulb, 8)
	_cy(0.006, 0.006, 0.05, lp + Vector3(0.03, 0.31, 0), T.brass, 6)
	anchors["office_lamp"] = lp + Vector3(0, 0.38, 0)
	# the adding machine, its roll of paper, the tape over the back
	var am := Transform3D(Basis(Vector3.UP, deg_to_rad(-15.0)), Vector3(u0 + 3.47, top, zc - 0.42))
	_put(_box(Vector3(0.26, 0.07, 0.3)), am * Transform3D(Basis.IDENTITY, Vector3(0, 0.035, 0)), T.beige)
	_put(_box(Vector3(0.18, 0.025, 0.16)), am * Transform3D(Basis(Vector3.BACK, deg_to_rad(-12.0)), Vector3(0.03, 0.08, 0)), M.dark)
	for kx in 4:
		for kz in 4:
			_put(_box(Vector3(0.022, 0.012, 0.022)), am * Transform3D(Basis.IDENTITY, Vector3(-0.03 + kx * 0.035, 0.094 - kx * 0.007, -0.052 + kz * 0.035)), T.plastic)
	_put(_cyl(0.035, 0.035, 0.12, 12), am * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(-0.12, 0.11, 0)), M.paper)
	_put(_box(Vector3(0.002, 0.2, 0.11)), am * Transform3D(Basis(Vector3.BACK, deg_to_rad(-25.0)), Vector3(-0.19, 0.06, 0)), M.paper)
	# the spike, the invoices on it
	var sp := Vector3(u0 + 3.07, top, zc - 0.62)
	_cy(0.045, 0.05, 0.015, sp + Vector3(0, 0.0075, 0), M.dark, 12)
	_cy(0.002, 0.003, 0.15, sp + Vector3(0, 0.09, 0), M.steel, 4)
	for k in 7:
		_bx(Vector3(0.1, 0.0015, 0.14), sp + Vector3(r_off(k, 0.008), 0.02 + k * 0.006, r_off(k + 3, 0.008)), M.paper, Vector3(0, k * 13.0 - 30.0, 0))
	# the mug of pens
	var mp := Vector3(u0 + 3.07, top, zc + 0.18)
	_cy(0.042, 0.04, 0.1, mp + Vector3(0, 0.05, 0), T.mug_b, 14)
	var pen_m := [M.black, T.mug_b, T.yellow, M.steel, M.black]
	for k in 5:
		_cy(0.005, 0.005, 0.15, mp + Vector3(r_off(k, 0.02), 0.11, r_off(k + 7, 0.02)), pen_m[k], 6, Vector3(r_off(k + 1, 12.0), 0, r_off(k + 2, 12.0)))
	# his phone, face down
	_bx(Vector3(0.075, 0.009, 0.155), Vector3(u0 + 3.56, top + 0.0045, zc + 0.36), M.black, Vector3(0, 22, 0))
	# the letter, square in front of him: the inspection notice, one word ringed
	var read := Basis(Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)) * Basis(Vector3.BACK, deg_to_rad(4.0))
	_plate("letter", 0.216, 0.28, Vector3(u0 + 3.5, top + 0.0015, zc - 0.06), read, T.pic_clean)
	anchors["office_notice"] = Vector3(u0 + 3.5, top + 0.01, zc - 0.06)
	# the small photo in its frame, turned to him
	var nrm := Vector3(cos(deg_to_rad(10.0)), sin(deg_to_rad(10.0)), 0.18).normalized()
	var fb := Basis.looking_at(-nrm, Vector3.UP)
	var fp := Vector3(u0 + 3.0, top + 0.09, zc + 0.3)
	_bb(Vector3(0.15, 0.2, 0.012), fp, M.frame, fb)
	_put(_quad_p(0.12, 0.155, Rect2(PLATES.desk_photo.position / ATLAS, PLATES.desk_photo.size / ATLAS)), Transform3D(fb, fp + nrm * 0.007), T.pic_clean)
	_bb(Vector3(0.012, 0.18, 0.012), fp - nrm * 0.05 + Vector3(0, -0.01, 0), M.frame, fb * Basis(Vector3.RIGHT, deg_to_rad(-25.0)))


# a small turn of the dice for the things on the desk, the same every time
func r_off(k: int, amount: float) -> float:
	return sin(k * 12.9898 + 4.1) * amount


# a lamp shade, pleated: a cone's side folded in and out round it, inside and out
func _pleat_p(rt: float, rb: float, h: float, n: int) -> Array:
	_begin()
	var pts := 2 * n
	for i in pts:
		var a0 := TAU * i / pts
		var a1 := TAU * (i + 1) / pts
		var k0 := 1.0 if i % 2 == 0 else 0.9
		var k1 := 0.9 if i % 2 == 0 else 1.0
		var t0 := Vector3(cos(a0) * rt * k0, h / 2.0, sin(a0) * rt * k0)
		var t1 := Vector3(cos(a1) * rt * k1, h / 2.0, sin(a1) * rt * k1)
		var b0 := Vector3(cos(a0) * rb * k0, -h / 2.0, sin(a0) * rb * k0)
		var b1 := Vector3(cos(a1) * rb * k1, -h / 2.0, sin(a1) * rb * k1)
		var out := Vector3(cos((a0 + a1) / 2.0), (rb - rt) / h, sin((a0 + a1) / 2.0)).normalized()
		_tri(t0, b0, b1, out)
		_tri(t0, b1, t1, out)
		_tri(t0, b1, b0, -out)
		_tri(t0, t1, b1, -out)
	return _end()


# The wooden armchair across the desk: seat 0.46, its arms at 0.66, a foot apart either side of
# the middle (the doorman's model sits in it: models/people/him_desk.json).
func _armchair(at: Vector3) -> void:
	var c := at
	_bx(Vector3(0.5, 0.05, 0.54), c + Vector3(0, 0.435, 0), T.chair)
	for sx in [-0.22, 0.22]:
		for sz in [-0.24, 0.24]:
			_bx(Vector3(0.045, 0.43, 0.045), c + Vector3(sx, 0.215, sz), T.chair)
	for sz in [-0.3, 0.3]:
		_bx(Vector3(0.5, 0.035, 0.07), c + Vector3(0.02, 0.645, sz), T.chair)
		_bx(Vector3(0.04, 0.2, 0.04), c + Vector3(0.22, 0.545, sz), T.chair)
		_bx(Vector3(0.04, 0.55, 0.04), c + Vector3(-0.23, 0.68, sz), T.chair)
	_bx(Vector3(0.04, 0.08, 0.62), c + Vector3(-0.25, 0.93, 0), T.chair)
	for sz in [-0.15, 0.0, 0.15]:
		_bx(Vector3(0.025, 0.42, 0.06), c + Vector3(-0.245, 0.68, sz), T.chair)


# The bookkeeper's corner, against the wall on Gary's right: her desk, her screen, the ledger, her
# mug; her chair with the cardigan over its back; the oil-filled heater, not on.
func _bookkeeping(u0: float, zc: float, y: float) -> void:
	var wz := zc - OFFICE_W / 2.0
	var dm := u0 + 3.15
	_bx(Vector3(1.4, 0.03, 0.66), Vector3(dm, y + 0.725, wz + 0.34), T.oak)
	for dx in [-0.67, 0.67]:
		_bx(Vector3(0.03, 0.71, 0.62), Vector3(dm + dx, y + 0.355, wz + 0.33), T.oak_side)
	_bx(Vector3(1.3, 0.45, 0.02), Vector3(dm, y + 0.45, wz + 0.04), T.oak_side)
	var top := y + 0.74
	# the screen, the keyboard
	_cy(0.09, 0.1, 0.015, Vector3(dm + 0.05, top + 0.0075, wz + 0.17), T.monitor, 12)
	_bx(Vector3(0.04, 0.2, 0.03), Vector3(dm + 0.05, top + 0.11, wz + 0.15), T.monitor)
	_bx(Vector3(0.52, 0.33, 0.035), Vector3(dm + 0.05, top + 0.36, wz + 0.17), T.monitor)
	_bx(Vector3(0.48, 0.29, 0.005), Vector3(dm + 0.05, top + 0.36, wz + 0.19), T.mon_glow)
	_bx(Vector3(0.42, 0.02, 0.14), Vector3(dm - 0.05, top + 0.01, wz + 0.42), T.monitor)
	# the ledger, open, a pen in its gutter
	_bx(Vector3(0.24, 0.012, 0.32), Vector3(dm - 0.18, top + 0.006, wz + 0.55), M.paper, Vector3(0, 0, 2.0))
	_bx(Vector3(0.24, 0.012, 0.32), Vector3(dm + 0.06, top + 0.006, wz + 0.55), M.paper, Vector3(0, 0, -2.0))
	_bx(Vector3(0.49, 0.008, 0.33), Vector3(dm - 0.06, top + 0.002, wz + 0.55), T.mug_b)
	# her mug
	var mg := Vector3(dm + 0.48, top, wz + 0.5)
	_cy(0.042, 0.04, 0.1, mg + Vector3(0, 0.05, 0), M.porcelain, 14)
	_bx(Vector3(0.012, 0.06, 0.04), mg + Vector3(0.05, 0.05, 0), M.porcelain)
	anchors["bk_mug"] = mg + Vector3(0, 0.08, 0)
	# her chair: five feet on castors, the column, the seat, the back with her cardigan over it
	var ch := Vector3(dm, y, zc - 1.15)
	for k in 5:
		var a := TAU * k / 5.0
		_bx(Vector3(0.3, 0.035, 0.05), ch + Vector3(cos(a) * 0.15, 0.06, sin(a) * 0.15), M.black, Vector3(0, -rad_to_deg(a), 0))
	_cy(0.025, 0.03, 0.33, ch + Vector3(0, 0.24, 0), M.steel, 8)
	_cy(0.24, 0.24, 0.06, ch + Vector3(0, 0.43, 0), M.seat, 16)
	_bx(Vector3(0.03, 0.3, 0.03), ch + Vector3(0, 0.55, 0.23), M.black)
	_bx(Vector3(0.42, 0.42, 0.05), ch + Vector3(0, 0.84, 0.26), M.seat)
	_bx(Vector3(0.46, 0.1, 0.12), ch + Vector3(0, 1.07, 0.26), T.knit)
	_bx(Vector3(0.44, 0.38, 0.03), ch + Vector3(0, 0.88, 0.3), T.knit, Vector3(4, 0, 0))
	_bx(Vector3(0.1, 0.42, 0.04), ch + Vector3(-0.2, 0.83, 0.31), T.knit, Vector3(5, 0, 4))
	_bx(Vector3(0.1, 0.42, 0.04), ch + Vector3(0.2, 0.83, 0.31), T.knit, Vector3(5, 0, -4))
	# the heater, cream, by her feet, its dial at the end
	var hp := Vector3(u0 + 4.25, y, wz + 0.3)
	for k in 9:
		_bx(Vector3(0.05, 0.56, 0.26), hp + Vector3(-0.26 + k * 0.065, 0.36, 0), T.radiator)
	_bx(Vector3(0.6, 0.04, 0.12), hp + Vector3(0, 0.08, 0), T.radiator)
	for fx in [-0.22, 0.22]:
		_bx(Vector3(0.05, 0.04, 0.36), hp + Vector3(fx, 0.03, 0), M.dark)
	_bx(Vector3(0.05, 0.12, 0.1), hp + Vector3(0.33, 0.56, 0), M.dark)
	# the calendar on the wall over her desk
	_bx(Vector3(0.012, 0.012, 0.012), Vector3(u0 + 2.45, y + 1.83, wz + 0.006), M.black)
	_plate("calendar", 0.34, 0.48, Vector3(u0 + 2.45, y + 1.55, wz + 0.004), facing(Vector3.BACK), T.pic_clean)
	anchors["office_calendar"] = Vector3(u0 + 2.45, y + 1.55, wz + 0.01)


# The rest of the room: the filing cabinet and the old safe along the wall on Gary's left, the
# coat stand by the window, the box of black shirts in the corner by the door, the dehumidifier.
func _corners(u0: float, zc: float, y: float) -> void:
	var lw := zc + OFFICE_W / 2.0
	var rw := zc - OFFICE_W / 2.0
	# the filing cabinet, four drawers
	var fc := Vector3(u0 + 4.6, y, lw - 0.32)
	_bx(Vector3(0.47, 1.32, 0.62), fc + Vector3(0, 0.66, 0), T.cabinet)
	for k in 4:
		var ky := 1.15 - k * 0.31
		_bx(Vector3(0.43, 0.28, 0.012), fc + Vector3(0, ky, -0.316), T.cabinet)
		_bx(Vector3(0.12, 0.025, 0.03), fc + Vector3(0, ky + 0.02, -0.33), M.steel)
		_bx(Vector3(0.07, 0.035, 0.005), fc + Vector3(0, ky + 0.08, -0.324), M.paper)
	# the safe: heavy, black, its dial and handle
	var sf := Vector3(u0 + 3.85, y, lw - 0.3)
	_bx(Vector3(0.6, 0.6, 0.55), sf + Vector3(0, 0.34, 0), T.safe)
	_bx(Vector3(0.48, 0.48, 0.015), sf + Vector3(0, 0.34, -0.28), T.safe)
	_cy(0.05, 0.05, 0.03, sf + Vector3(-0.08, 0.42, -0.295), T.brass, 16, Vector3(90, 0, 0))
	_bx(Vector3(0.025, 0.12, 0.03), sf + Vector3(0.12, 0.34, -0.3), T.brass)
	for cx in [-0.24, 0.24]:
		for cz in [-0.2, 0.2]:
			_cy(0.03, 0.03, 0.04, sf + Vector3(cx, 0.02, cz), M.black, 8)
	anchors["office_safe"] = sf + Vector3(0, 0.45, -0.28)
	# the coat stand in the corner by the window, his coat and his hat on it
	var cs := Vector3(u0 + 0.38, y, lw - 0.35)
	_cy(0.2, 0.22, 0.04, cs + Vector3(0, 0.02, 0), M.frame, 14)
	_cy(0.018, 0.022, 1.75, cs + Vector3(0, 0.9, 0), T.oak_side, 8)
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		_bx(Vector3(0.02, 0.02, 0.14), cs + Vector3(cos(a) * 0.06, 1.68, sin(a) * 0.06), T.oak_side, Vector3(-30, -rad_to_deg(a) + 90, 0))
	_bx(Vector3(0.42, 0.95, 0.18), cs + Vector3(0.06, 1.15, -0.06), T.coat, Vector3(4, 25, 0))
	_cy(0.13, 0.15, 0.08, cs + Vector3(0.05, 1.6, -0.05), T.coat, 10)
	_cy(0.16, 0.16, 0.012, cs + Vector3(0, 1.79, 0), T.coat, 16)
	_cy(0.085, 0.1, 0.11, cs + Vector3(0, 1.85, 0), T.coat, 12)
	# the carton of black T-shirts by the door, open, the top one's front up
	var bx := Vector3(u0 + 0.36, y, rw + 0.3)
	_bx(Vector3(0.52, 0.01, 0.42), bx + Vector3(0, 0.005, 0), T.cardboard)
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.52, 0.34, 0.01), bx + Vector3(0, 0.17, s * 0.205), T.cardboard)
		_bx(Vector3(0.01, 0.34, 0.42), bx + Vector3(s * 0.255, 0.17, 0), T.cardboard)
		_bx(Vector3(0.52, 0.2, 0.008), bx + Vector3(0, 0.38, s * 0.25), T.cardboard, Vector3(s * 55.0, 0, 0))
		_bx(Vector3(0.008, 0.2, 0.42), bx + Vector3(s * 0.3, 0.38, 0), T.cardboard, Vector3(0, 0, -s * 50.0))
	for k in 6:
		_bx(Vector3(0.44, 0.045, 0.34), bx + Vector3(0, 0.035 + k * 0.047, 0), T.shirt)
	var flat := Basis(Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0))
	_plate("shirt", 0.3, 0.095, bx + Vector3(0.0, 0.3045, 0.0), flat, T.pic)
	anchors["office_shirts"] = bx + Vector3(0, 0.32, 0)
	# the dehumidifier in the back corner, humming
	var dh := Vector3(u0 + 4.85, y, rw + 0.28)
	_bx(Vector3(0.36, 0.6, 0.27), dh + Vector3(0, 0.3, 0), T.plastic)
	_bx(Vector3(0.3, 0.012, 0.2), dh + Vector3(0, 0.605, 0), M.dark)
	_bx(Vector3(0.012, 0.2, 0.22), dh + Vector3(-0.18, 0.15, 0), T.beige)


# The room's light: his lamp (it lights the room, and the porch through the glass), the grey
# through the window, and a little of it off the walls.
func _office_light(u0: float, zc: float, y: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(u0 + 3.12, y + 1.08, zc + 0.52)
	lamp.light_color = Color("ffc387")
	lamp.light_energy = 1.35
	lamp.omni_range = 3.0
	lamp.omni_attenuation = 1.2
	lamp.light_cull_mask = OFFICE | 1
	far.add_child(lamp)
	var day := SpotLight3D.new()
	day.light_color = Color("cbd4de")
	day.light_energy = 1.5
	day.spot_range = 11.0
	day.spot_angle = 34.0
	day.spot_angle_attenuation = 1.4
	day.light_cull_mask = OFFICE
	far.add_child(day)
	var from := Vector3(u0 - 3.2, y + 2.9, zc + 1.2)
	day.position = from
	day.basis = Basis.looking_at(Vector3(u0 + 2.3, y + 0.3, zc + 0.5) - from, Vector3.UP)
	_day_spot = day
	var fill := OmniLight3D.new()
	fill.position = Vector3(u0 + 2.4, y + 2.2, zc + 0.4)
	fill.light_color = Color("d4dbe2")
	fill.light_energy = 0.22
	fill.omni_range = 5.5
	fill.light_cull_mask = OFFICE
	far.add_child(fill)


# ---------------------------------------------------------------- the Esso

# The gas station south of the Sov, on the inland side of the highway: the canopy over two islands
# of pumps, lit white from beneath; behind it the store, its window lit and its glass door, the ice
# freezer by the door (the kid sits on it), the propane cage, the garbage can, the squeegee bucket;
# the price sign on its pole by the road, the numbers and nothing else.
func _esso() -> void:
	# the concrete, in squares
	for sx in [-168.0, -156.0, -144.0]:
		for sz in [2.0, 14.0]:
			var zl := minf(12.0, 27.6 - sz)
			_bx(Vector3(12.0, 0.4, zl), Vector3(sx + 6.0, APRON - 0.2, sz + zl / 2.0), T.apron)
	_bx(Vector3(36.0, 0.4, 1.6), Vector3(-150.0, APRON - 0.2, 26.8), T.apron)
	# the islands, the pumps, the canopy's posts
	for iz in [19.0, 23.0]:
		_bx(Vector3(10.0, 0.15, 1.2), Vector3(-150.0, APRON + 0.075, iz), T.walk)
		for bx in [-155.2, -144.8]:
			_cy(0.1, 0.1, 0.9, Vector3(bx, APRON + 0.6, iz), T.yellow, 8)
		for px in [-152.5, -147.5]:
			_pump(Vector3(px, APRON + 0.15, iz))
		for cx in [-154.2, -145.8]:
			_bx(Vector3(0.36, 4.75, 0.36), Vector3(cx, APRON + 0.15 + 2.375, iz), T.canopy)
	# the canopy: white, a band round it, the lights under it
	_bx(Vector3(16.0, 1.0, 10.5), Vector3(-150.0, 5.4, 20.75), T.canopy)
	for s in [-1.0, 1.0]:
		_bx(Vector3(16.06, 0.32, 0.04), Vector3(-150.0, 5.45, 20.75 + s * 5.27), T.band)
		_bx(Vector3(0.04, 0.32, 10.56), Vector3(-150.0 + s * 8.02, 5.45, 20.75), T.band)
	for lx in [-155.0, -150.0, -145.0]:
		for lz in [17.4, 20.9, 24.4]:
			_bx(Vector3(2.0, 0.04, 0.9), Vector3(lx, 4.88, lz), T.canopy_lit)
	# its lit underside, over the pumps (from his post at its edge, its edge is straight up)
	anchors["esso_canopy"] = Vector3(-150.0, 4.84, 20.0)
	for iz in [19.0, 23.0]:
		var l := OmniLight3D.new()
		l.position = Vector3(-150.0, 4.45, iz)
		l.light_color = Color("bcf2da")
		l.light_energy = 2.4
		l.omni_range = 11.0
		l.omni_attenuation = 1.1
		l.light_cull_mask = OUTDOORS
		far.add_child(l)
	_esso_store()
	# the garbage can at the end of the far island, the squeegee bucket on the near one
	var gc := Vector3(-155.9, APRON, 23.0)
	_cy(0.28, 0.26, 0.9, gc + Vector3(0, 0.45, 0), T.can, 14)
	_cy(0.31, 0.31, 0.06, gc + Vector3(0, 0.93, 0), T.can, 14)
	_bx(Vector3(0.24, 0.12, 0.02), gc + Vector3(0, 0.8, 0.285), M.black)
	var bk := Vector3(-150.0, APRON + 0.15, 19.0)
	for lx in [-0.14, 0.14]:
		_bx(Vector3(0.03, 0.5, 0.03), bk + Vector3(lx, 0.25, 0), M.steel)
	_cy(0.15, 0.12, 0.32, bk + Vector3(0, 0.66, 0), T.bucket, 12)
	_cy(0.012, 0.012, 0.7, bk + Vector3(0.06, 0.95, 0.03), T.wood_pole, 6, Vector3(0, 0, -12))
	_bx(Vector3(0.24, 0.06, 0.03), bk + Vector3(0.13, 1.3, 0.03), M.black, Vector3(0, 0, -12))
	# the price sign by the road
	var ps := Vector3(-134.5, APRON, 26.4)
	_bx(Vector3(0.26, 5.0, 0.26), ps + Vector3(0, 2.5, 0), M.steel)
	_bx(Vector3(0.36, 2.3, 2.3), ps + Vector3(0, 6.1, 0), T.canopy)
	_bx(Vector3(0.38, 0.4, 2.32), ps + Vector3(0, 7.05, 0), T.band)
	var prices := ["179.9", "193.9", "188.9"]
	for k in 3:
		var py := 6.55 - k * 0.6
		_bx(Vector3(0.4, 0.46, 1.8), ps + Vector3(0, py, 0), M.black)
		for s in [-1.0, 1.0]:
			var l := Label3D.new()
			l.text = prices[k]
			l.font = _font("ui_b")
			l.font_size = 64
			l.pixel_size = 0.0062
			l.outline_size = 0
			l.modulate = Color(1.0, 0.86, 0.58)
			l.shaded = false
			l.double_sided = false
			l.position = ps + Vector3(s * 0.21, py, 0)
			l.rotation.y = s * PI / 2.0
			far.add_child(l)
	anchors["esso_prices"] = ps + Vector3(0, 6.0, 0)
	# behind the store, a few firs; the hedge along the lot's south edge
	for p in [Vector3(-162, 0, -2), Vector3(-154, 0, -5), Vector3(-146, 0, -3), Vector3(-138, 0, -6), Vector3(-171, 0, 8)]:
		_pine(Vector3(p.x, ground_y(p.x, p.z), p.z), rng.randf_range(9.0, 14.0))


func _pump(at: Vector3) -> void:
	_bx(Vector3(0.56, 1.7, 0.42), at + Vector3(0, 0.85, 0), T.pump)
	_bx(Vector3(0.6, 0.22, 0.46), at + Vector3(0, 1.75, 0), T.band)
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.36, 0.26, 0.02), at + Vector3(0, 1.3, s * 0.215), M.black)
		_bx(Vector3(0.26, 0.14, 0.02), at + Vector3(0, 0.95, s * 0.215), T.glass_dk)
		_bx(Vector3(0.07, 0.16, 0.08), at + Vector3(s * 0.32, 1.05, 0), M.black)
		_cy(0.016, 0.016, 0.9, at + Vector3(s * 0.33, 0.55, 0.05), M.black, 6, Vector3(0, 0, s * 8.0))


# The store: its window lit, the shelves through it; the glass door; an awning over the door and
# the freezer; the propane cage at the end.
func _esso_store() -> void:
	var x0 := -158.0
	var x1 := -143.0
	var z0 := 3.0
	var zf := 12.0
	var h := 4.2
	var y := APRON
	_bx(Vector3(x1 - x0, h, 0.25), Vector3((x0 + x1) / 2.0, y + h / 2.0, z0 + 0.125), T.canopy)
	for ex in [x0 + 0.125, x1 - 0.125]:
		_bx(Vector3(0.25, h, zf - z0), Vector3(ex, y + h / 2.0, (z0 + zf) / 2.0), T.canopy)
	_bx(Vector3(x1 - x0, 0.3, zf - z0), Vector3((x0 + x1) / 2.0, y + h + 0.15, (z0 + zf) / 2.0), T.canopy)
	# the front, round the window and the door
	_wallh(Vector2(x0, zf - 0.1), Vector2(x1, zf - 0.1), y, h, T.canopy, [[1.0, 7.5, 0.5, 2.6], [8.8, 9.8, 0.0, 2.25], [12.2, 14.2, 0.9, 2.3]], 0.2)
	_bx(Vector3(x1 - x0 + 0.04, 0.5, 0.06), Vector3((x0 + x1) / 2.0, y + 3.7, zf + 0.03), T.band)
	_bx(Vector3(6.5, 2.1, 0.02), Vector3(x0 + 4.25, y + 1.55, zf - 0.1), M.glass)
	_bx(Vector3(2.0, 1.4, 0.02), Vector3(x0 + 13.2, y + 1.6, zf - 0.1), M.glass)
	_bx(Vector3(0.98, 2.2, 0.02), Vector3(x0 + 9.3, y + 1.1, zf - 0.1), M.glass)
	for fx in [x0 + 8.82, x0 + 9.78]:
		_bx(Vector3(0.05, 2.25, 0.08), Vector3(fx, y + 1.125, zf - 0.1), M.steel)
	_bx(Vector3(0.03, 0.03, 0.5), Vector3(x0 + 9.7, y + 1.1, zf - 0.02), M.steel)
	anchors["esso_window"] = Vector3(x0 + 4.25, y + 1.55, zf)
	# inside: lit, the shelves, the counter by the door, the coolers along the end
	_bx(Vector3(x1 - x0 - 0.6, 0.02, zf - z0 - 0.6), Vector3((x0 + x1) / 2.0, y + 0.01, (z0 + zf) / 2.0), T.walk)
	_bx(Vector3(x1 - x0 - 0.6, h - 0.4, 0.04), Vector3((x0 + x1) / 2.0, y + (h - 0.4) / 2.0, z0 + 0.3), T.store_in)
	_bx(Vector3(0.04, h - 0.4, zf - z0 - 0.6), Vector3(x0 + 0.3, y + (h - 0.4) / 2.0, (z0 + zf) / 2.0), T.store_in)
	_bx(Vector3(x1 - x0 - 0.6, 0.04, zf - z0 - 0.6), Vector3((x0 + x1) / 2.0, y + h - 0.4, (z0 + zf) / 2.0), T.store_in)
	for row in 3:
		var rz := 5.0 + row * 2.0
		_bx(Vector3(5.0, 1.35, 0.7), Vector3(x0 + 4.0, y + 0.675, rz), M.dark)
		for k in 6:
			_bx(Vector3(0.75, 0.22, 0.72), Vector3(x0 + 1.9 + k * 0.82, y + 0.45 + (k % 3) * 0.32, rz), T.goods[(k + row) % T.goods.size()])
	_bx(Vector3(2.4, 1.0, 0.7), Vector3(x0 + 10.6, y + 0.5, zf - 1.6), M.dark)
	_bx(Vector3(0.4, 0.3, 0.35), Vector3(x0 + 10.0, y + 1.15, zf - 1.6), M.black)
	_bx(Vector3(0.05, 2.2, zf - z0 - 1.6), Vector3(x1 - 0.32, y + 1.2, (z0 + zf) / 2.0), T.canopy_lit)
	# the awning over the door, its lights
	_bx(Vector3(9.0, 0.16, 1.4), Vector3(x0 + 9.0, y + 3.05, zf + 0.7), T.canopy)
	_bx(Vector3(9.04, 0.18, 0.04), Vector3(x0 + 9.0, y + 3.05, zf + 1.4), T.band)
	for lx in [x0 + 6.0, x0 + 9.3, x0 + 12.4]:
		_bx(Vector3(0.6, 0.02, 0.3), Vector3(lx, y + 2.96, zf + 0.7), T.canopy_lit)
	var spill := OmniLight3D.new()
	spill.position = Vector3(x0 + 10.5, y + 2.6, zf + 1.6)
	spill.light_color = Color("c0f0dc")
	spill.light_energy = 1.0
	spill.omni_range = 7.0
	spill.light_cull_mask = OUTDOORS
	far.add_child(spill)
	T.store_spill = spill
	# the ice freezer by the door: white, ICE on its front
	var fz := Vector3(-147.3, y, 12.4)
	_bx(Vector3(1.2, 0.8, 0.7), fz + Vector3(0, 0.4, 0), T.ice)
	_bx(Vector3(1.22, 0.06, 0.72), fz + Vector3(0, 0.83, 0), T.ice)
	_bx(Vector3(1.2, 0.012, 0.012), fz + Vector3(0, 0.8, 0.36), M.dark)
	_bx(Vector3(0.012, 0.18, 0.36), fz + Vector3(-0.606, 0.2, 0.05), M.dark)
	_plate("ice", 0.64, 0.28, fz + Vector3(0, 0.45, 0.352), Basis.IDENTITY, T.pic)
	anchors["esso_ice"] = fz + Vector3(0, 0.6, 0.35)
	# the propane cage at the end of the front
	var pc := Vector3(x0 + 1.0, y, zf + 0.5)
	for cx in [-0.7, 0.7]:
		for cz in [-0.35, 0.35]:
			_bx(Vector3(0.05, 1.7, 0.05), pc + Vector3(cx, 0.85, cz), M.steel)
	for yy in [0.05, 0.85, 1.68]:
		_bx(Vector3(1.45, 0.04, 0.75), pc + Vector3(0, yy, 0), M.steel)
	var bx := -0.65
	while bx < 0.66:
		_bx(Vector3(0.012, 1.65, 0.012), pc + Vector3(bx, 0.85, 0.36), M.steel)
		bx += 0.1
	for k in 4:
		var tp := pc + Vector3(-0.45 + (k % 2) * 0.9 * 0.5 + (k / 2) * 0.45, 0.07 + (k / 2) * 0.8, 0.0)
		_cy(0.15, 0.15, 0.48, tp + Vector3(0, 0.26, 0), T.tank, 12)
		_cy(0.06, 0.07, 0.1, tp + Vector3(0, 0.55, 0), T.tank, 10)


# ---------------------------------------------------------------- the harbour

# The government wharf, out on its pilings from the foot of the main street: a ramp up over the
# seawall, the deck, the rails, the light at the end; a float alongside with the fish boats.
func _harbour() -> void:
	var w := 5.0
	var x0 := WHARF_X - w / 2.0
	var x1 := WHARF_X + w / 2.0
	# the ramp up from the highway's edge, over the seawall
	var rl := WHARF_Z0 - 35.6
	var ra := atan2(WHARF_Y - 0.01, rl)
	_bx(Vector3(w, 0.3, rl / cos(ra) + 0.1), Vector3(WHARF_X, (WHARF_Y + 0.01) / 2.0 - 0.15, (35.6 + WHARF_Z0) / 2.0), T.apron, Vector3(-rad_to_deg(ra), 0, 0))
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.25, 0.5, rl), Vector3(WHARF_X + s * (w / 2.0 - 0.12), (WHARF_Y + 0.01) / 2.0 + 0.2, (35.6 + WHARF_Z0) / 2.0), M.concrete, Vector3(-rad_to_deg(ra), 0, 0))
	# the deck, in pieces, on its bents of pilings
	var z := WHARF_Z0
	while z < WHARF_Z1 - 0.01:
		var z1 := minf(z + 18.0, WHARF_Z1)
		_bx(Vector3(w, 0.3, z1 - z), Vector3(WHARF_X, WHARF_Y - 0.15, (z + z1) / 2.0), T.planks)
		z = z1
	var bz := WHARF_Z0 + 1.0
	while bz < WHARF_Z1:
		_bx(Vector3(w + 0.4, 0.3, 0.3), Vector3(WHARF_X, WHARF_Y - 0.45, bz), T.piling)
		for px in [x0 + 0.2, x1 - 0.2]:
			_cy(0.17, 0.19, 3.3, Vector3(px, WHARF_Y - 0.6 - 1.65, bz), T.piling, 8)
		bz += 4.5
	# the curbs and the rails, open on the south side for the gangway down to the float
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.2, 0.2, WHARF_Z1 - WHARF_Z0), Vector3(WHARF_X + s * (w / 2.0 - 0.1), WHARF_Y + 0.1, (WHARF_Z0 + WHARF_Z1) / 2.0), T.piling)
		var rx: float = WHARF_X + s * (w / 2.0 - 0.12)
		var segs := [[WHARF_Z0, WHARF_Z1]] if s > 0.0 else [[WHARF_Z0, 69.4], [72.6, WHARF_Z1]]
		for sg in segs:
			var a: float = sg[0]
			var b: float = sg[1]
			_bx(Vector3(0.08, 0.09, b - a), Vector3(rx, WHARF_Y + 1.0, (a + b) / 2.0), T.planks)
			_bx(Vector3(0.06, 0.07, b - a), Vector3(rx, WHARF_Y + 0.55, (a + b) / 2.0), T.planks)
			var pz := a
			while pz <= b + 0.01:
				_bx(Vector3(0.1, 1.05, 0.1), Vector3(rx, WHARF_Y + 0.52, pz), T.piling)
				pz += 2.25
	_bx(Vector3(w, 0.09, 0.08), Vector3(WHARF_X, WHARF_Y + 1.0, WHARF_Z1 - 0.05), T.planks)
	# bollards, the traps stacked at the head
	for bzz in [50.0, 66.0, 82.0]:
		_cy(0.12, 0.13, 0.4, Vector3(x1 - 0.45, WHARF_Y + 0.2, bzz), M.dark, 10)
	for k in 5:
		_bx(Vector3(0.8, 0.3, 0.8), Vector3(x0 + 0.7 + (k % 2) * 0.1, WHARF_Y + 0.15 + (k / 2) * 0.3, 46.0 + (k % 2) * 0.9), M.steel)
	_bx(Vector3(1.0, 0.5, 0.7), Vector3(x0 + 0.8, WHARF_Y + 0.25, 49.5), T.bucket)
	# the light at the end, and the green one on its corner
	var lp := Vector3(x1 - 0.6, WHARF_Y, WHARF_Z1 - 0.7)
	_cy(0.07, 0.09, 4.2, lp + Vector3(0, 2.1, 0), T.pole, 8)
	_bx(Vector3(0.6, 0.06, 0.06), lp + Vector3(-0.3, 4.15, 0), T.pole)
	_bx(Vector3(0.28, 0.36, 0.28), lp + Vector3(-0.55, 3.9, 0), _lamps[5][0])
	_cy(0.0, 0.22, 0.14, lp + Vector3(-0.55, 4.15, 0), T.pole, 8)
	_pool(Vector3(WHARF_X, WHARF_Y + 0.02, WHARF_Z1 - 3.0), 8.0, 5)
	_sp(0.08, Vector3(x0 + 0.1, WHARF_Y + 1.3, WHARF_Z1), glow(Color("6fd39a"), 2.0), 8)
	anchors["street_wharf"] = Vector3(WHARF_X, WHARF_Y + 1.5, 70.0)
	# the float alongside, the gangway down to it, the tires along its edge
	var fx := x0 - 1.8
	_bx(Vector3(3.0, 0.45, 18.0), Vector3(fx, -0.39 + 0.12, 73.0), T.planks)
	var gl := Vector3(x0 + 0.1, WHARF_Y, 71.0)
	var gr := Vector3(fx + 0.4, -0.04, 71.0)
	var gd := gl - gr
	_bb(Vector3(gd.length(), 0.06, 1.0), (gl + gr) / 2.0 + Vector3(0, 0.03, 0), T.planks, Basis(Vector3.BACK, atan2(gd.y, gd.x)))
	for tz in [65.0, 69.0, 73.0, 77.0, 81.0]:
		_cy(0.3, 0.3, 0.2, Vector3(fx - 1.55, -0.2, tz), T.tire, 10, Vector3(0, 0, 90))
	# the boats: a troller on the float, a gillnetter at the wharf's north side
	_boat(Vector3(fx - 3.6, -0.39, 73.5), 0.0, 12.0, 3.8, T.hull_w, T.hull_n, true)
	_boat(Vector3(x1 + 2.4, -0.39, 62.0), PI, 11.0, 3.6, T.hull_n, T.hull_w, false)
	_boat(Vector3(fx - 3.4, -0.39, 87.0), 0.15, 9.0, 3.0, T.hull_g, T.hull_w, false)


# A fish boat, her bow on -z in her own frame: the hull, a stripe along it, the wheelhouse, the
# mast; a troller's poles up either side.
func _boat(at: Vector3, yaw: float, length: float, beam: float, hull_m: Material, stripe_m: Material, troller: bool) -> void:
	var keep := _xf
	_xf = Transform3D(Basis(Vector3.UP, yaw), at)
	var b := beam / 2.0
	var outline := [Vector2(-b * 0.82, length / 2.0), Vector2(-b, length * 0.08), Vector2(-b * 0.72, -length * 0.3),
		Vector2(0.0, -length / 2.0), Vector2(b * 0.72, -length * 0.3), Vector2(b, length * 0.08), Vector2(b * 0.82, length / 2.0)]
	_put(_extrude_p(outline, -0.7, 1.0), Transform3D.IDENTITY, hull_m)
	var wide: Array = []
	for q in outline:
		wide.append(q * 1.012)
	_put(_extrude_p(wide, 0.78, 0.98), Transform3D.IDENTITY, stripe_m)
	var wz := -length * 0.12 if troller else -length * 0.22
	_bx(Vector3(beam * 0.58, 1.9, 2.6), Vector3(0, 1.95, wz), T.hull_w)
	_bx(Vector3(beam * 0.64, 0.12, 2.9), Vector3(0, 2.96, wz), T.hull_w)
	_bx(Vector3(beam * 0.5, 0.6, 0.05), Vector3(0, 2.3, wz - 1.31), T.glass_dk)
	for s in [-1.0, 1.0]:
		_bx(Vector3(0.05, 0.55, 1.6), Vector3(s * beam * 0.291, 2.3, wz), T.glass_dk)
	_cy(0.06, 0.08, 6.0, Vector3(0, 4.0, wz - 2.2), M.frame, 8)
	_bx(Vector3(0.05, 0.05, 3.5), Vector3(0, 2.6, wz + 1.4), M.frame, Vector3(-18, 0, 0))
	if troller:
		for s in [-1.0, 1.0]:
			_cy(0.035, 0.06, 10.0, Vector3(s * 1.6, 5.6, wz + 0.4), M.frame, 6, Vector3(0, 0, -s * 18.0))
	else:
		_cy(0.6, 0.6, beam * 0.6, Vector3(0, 1.75, length * 0.32), M.dark, 14, Vector3(0, 0, 90))
	_xf = keep


# ---------------------------------------------------------------- the rest of the town

# Behind the main street's buildings, the firs on the slope; trees round the corner where the street
# meets the highway.
func _back_lots() -> void:
	var n := 0
	var guard := 0
	while n < 34 and guard < 300:
		guard += 1
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var p := Vector2(MAIN_X + side * rng.randf_range(31.0, 60.0), rng.randf_range(-140.0, 20.0))
		_pine(Vector3(p.x, ground_y(p.x, p.y), p.y), rng.randf_range(10.0, 18.0))
		n += 1
	for p in [Vector2(-178.0, 24.0), Vector2(-226.0, 22.0), Vector2(-232.0, 4.0), Vector2(-120.0, -10.0), Vector2(-100.0, 6.0)]:
		_pine(Vector3(p.x, ground_y(p.x, p.y), p.y), rng.randf_range(11.0, 16.0))


# ---------------------------------------------------------------- light, weather

# the Sov's sign as it reads from far off down the highway
func _halo_on() -> void:
	var sh := Shader.new()
	sh.code = GLOW_HALO
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tint", Color("cc001a"))
	m.set_shader_parameter("energy", 0.75)
	var q := QuadMesh.new()
	q.size = Vector2(15.0, 7.0)
	_halo = MeshInstance3D.new()
	_halo.mesh = q
	_halo.material_override = m
	_halo.position = Vector3(8.0, 11.1, ZF + 0.9)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.extra_cull_margin = 8.0
	far.add_child(_halo)


func _town_rain() -> void:
	var rain := CPUParticles3D.new()
	rain.amount = 1800
	rain.lifetime = 1.1
	rain.preprocess = 2.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(8.0, 0.3, 8.0)
	rain.direction = Vector3(0.06, -1.0, 0.0)
	rain.spread = 1.5
	rain.gravity = Vector3(0, -6.0, 0)
	rain.initial_velocity_min = 7.0
	rain.initial_velocity_max = 8.5
	rain.emitting = false
	var q := QuadMesh.new()
	q.size = Vector2(0.007, 0.34)
	var rm := ShaderMaterial.new()
	rm.shader = preload("res://look/rain.gdshader")
	q.material = rm
	rain.mesh = q
	far.add_child(rain)
	_rainfall = rain


# The light out of the cloud in the afternoon, soft, from the south-west over the hill: out of doors
# only (game/view.gd turns it with the clock).
func _key_light() -> void:
	key = DirectionalLight3D.new()
	key.light_color = Color("dfe4ea")
	key.light_energy = 0.0
	key.light_specular = 0.2
	key.light_cull_mask = OUTDOORS
	key.shadow_enabled = false
	key.basis = Basis.looking_at(Vector3(0.35, -0.6, 0.72), Vector3.UP)
	key.visible = false
	far.add_child(key)


# ---------------------------------------------------------------- the pictures

# The pictures and the lettering, drawn once into one texture: the photo of the Sov in 1958, the
# letter on the desk, the calendar, the signs. Kept as a texture with its mipmaps once it's drawn.
func _plates_start() -> void:
	_atlas = SubViewport.new()
	_atlas.size = Vector2i(int(ATLAS), int(ATLAS))
	_atlas.transparent_bg = true
	_atlas.disable_3d = true
	_atlas.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_atlas)
	# under the gold leaf, clear but white: the texture's smaller copies (its mipmaps) mix the
	# letters with what's round them, and clear black would have them go dark across the room
	var under := ColorRect.new()
	under.position = PLATES.door.position
	under.size = PLATES.door.size
	var clear := ShaderMaterial.new()
	clear.shader = Shader.new()
	clear.shader.code = "shader_type canvas_item;\nrender_mode blend_disabled;\nvoid fragment() {\n\tCOLOR = vec4(1.0, 1.0, 1.0, 0.0);\n}\n"
	under.material = clear
	_atlas.add_child(under)
	var c := Control.new()
	c.size = Vector2(ATLAS, ATLAS)
	_atlas.add_child(c)
	c.draw.connect(func(): _draw_plates(c))
	var t := _atlas.get_texture()
	T.pic = mat(Color(1, 1, 1), 0.85, 0.0, 3, Vector3.UP, 7.0, 0.6)
	T.pic.set_shader_parameter("albedo_tex", t)
	T.pic_clean = mat(Color(1, 1, 1), 0.8, 0.0, 5, Vector3.UP, 7.0, 0.6)
	T.pic_clean.set_shader_parameter("albedo_tex", t)
	# words cut in stone, in the stone's own strokes, finer (the panel they're on is dressed smoother)
	T.carved = mat(Color(1, 1, 1), 0.9, 0.0, 0, Vector3.UP, 3.5, 0.8)
	T.carved.set_shader_parameter("albedo_tex", t)
	# the gold leaf: not shiny (with nothing round it to reflect it'd go dark across the room), and
	# a little light of its own for the shine it has
	T.gilt = glass(Color(0.9, 0.72, 0.36), 1.0)
	T.gilt.set_shader_parameter("albedo_tex", t)
	T.gilt.set_shader_parameter("metallic", 0.0)
	T.gilt.set_shader_parameter("roughness", 0.8)
	T.gilt.set_shader_parameter("emission", Color(0.9, 0.72, 0.36))
	T.gilt.set_shader_parameter("emission_energy", 0.6)
	_pics = [T.pic, T.pic_clean, T.carved, T.gilt]
	# the old photograph's grain, and its corners gone dark
	var n := FastNoiseLite.new()
	n.seed = 1958
	n.noise_type = FastNoiseLite.TYPE_VALUE
	n.frequency = 0.45
	_keep.append(ImageTexture.create_from_image(n.get_image(570, 363)))
	var v := Image.create_empty(96, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 96:
			var d := Vector2((x - 47.5) / 48.0, (y - 31.5) / 32.0).length()
			v.set_pixel(x, y, Color(0.06, 0.04, 0.02, 0.6 * smoothstep(0.55, 1.45, d)))
	_keep.append(ImageTexture.create_from_image(v))


func _keep_pictures() -> void:
	if DisplayServer.get_name() == "headless" or _atlas == null:
		return
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _atlas.get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	for m in _pics:
		(m as ShaderMaterial).set_shader_parameter("albedo_tex", t)
	_atlas.queue_free()
	_atlas = null
	_keep.clear()


# Everything that's drawn rather than built, each into its place in the one texture (PLATES).
func _draw_plates(c: Control) -> void:
	_photo58(c, PLATES.photo58)
	_letter(c, PLATES.letter)
	_desk_photo(c, PLATES.desk_photo)
	_ice(c, PLATES.ice)
	_chalk(c, PLATES.chalk)
	_door_gold(c, PLATES.door)
	_calendar(c, PLATES.calendar)
	_licence(c, PLATES.licence)
	_church_board(c, PLATES.church)
	_lease(c, PLATES.lease)
	_sign(c, PLATES.shirt, "SECURITY", "anton", Color("1c1c1f"), Color("ecebe6"), 0.0, false)
	_sign(c, PLATES.legion, "LEGION    BRANCH 38", "ui_b", Color("2c3b5c"), Color("e9e4d6"), 6.0)
	_carved(c, PLATES.library, "PUBLIC LIBRARY", 10.0)
	_carved(c, PLATES.bank, "BANK", 34.0)
	_sign(c, PLATES.thrift, "THRIFT STORE", "zilla_b", Color("2f4a3a"), Color("e7dfc6"), 4.0)
	_video_sign(c, PLATES.video)


# words on a plate, in font f at size s: their middle at `at` (their foot on its y), or starting
# there if `left`; `track` pixels more between the letters. Gives back how wide they came out.
func _say(c: Control, f: String, t: String, at: Vector2, s: int, col: Color, left := false, track := 0.0) -> float:
	var font := _font(f)
	var w := _width(font, t, s, track)
	var x := at.x if left else at.x - w / 2.0
	if track == 0.0:
		c.draw_string(font, Vector2(x, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, s, col)
		return w
	for ch in t:
		c.draw_string(font, Vector2(x, at.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, s, col)
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + track
	return w


func _width(font: Font, t: String, s: int, track := 0.0) -> float:
	if track == 0.0:
		return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var w := 0.0
	for ch in t:
		w += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + track
	return w - track


# the biggest size up to s at which t fits in w
func _fit(f: String, t: String, s: int, w: float, track := 0.0) -> int:
	var font := _font(f)
	while s > 8 and _width(font, t, s, track) > w:
		s -= 2
	return s



# The fonts as game/look.gd loads them, but the town's own: the glyphs it draws go into these
# fonts' caches, not the ones the Sov's lettering is in, which would sit a little differently in
# theirs (and print a pixel or two differently at night).
func _font(k: String) -> Font:
	if not _fonts.has(k):
		var f := FontFile.new()
		f.load_dynamic_font("res://fonts/" + str(Look.FONT_FILES.get(k, Look.FONT_FILES["read"])))
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_fonts[k] = f
	return _fonts[k]


# how high a font's capitals stand, for its size
func _cap(f: String, s: int) -> float:
	return s * {"anton": 0.72, "ui_b": 0.7, "zilla_b": 0.66, "archivo": 0.7}.get(f, 0.68)


func _oval(c: Control, at: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(at + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	c.draw_colored_polygon(pts, col)


# a ring drawn round something by hand, in pen: an ellipse that doesn't quite close
func _ring(c: Control, at: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 41:
		var a := -0.5 + (TAU + 0.75) * i / 40.0
		var k := 1.0 + 0.05 * float(i) / 40.0
		pts.append(at + Vector2(cos(a) * rx * k, sin(a) * ry * k).rotated(-0.05))
	c.draw_polyline(pts, col, w, true)


# the old photograph's greys, a little warm
func _g(v: float, a := 1.0) -> Color:
	return Color(v, v * 0.985, v * 0.95, a)


# while a picture's drawn in metres: a point, a rectangle, an outline, a line
func _m(x: float, y: float) -> Vector2:
	return _po + Vector2(x, -y) * _ps


func _mr(c: Control, x0: float, y0: float, x1: float, y1: float, col: Color) -> void:
	c.draw_rect(Rect2(_m(x0, y1), Vector2(x1 - x0, y1 - y0) * _ps), col)


func _mp(c: Control, pts: Array, col: Color) -> void:
	var p := PackedVector2Array()
	for q in pts:
		p.append(_m(q.x, q.y))
	c.draw_colored_polygon(p, col)


func _ml(c: Control, x0: float, y0: float, x1: float, y1: float, col: Color, w := 1.5) -> void:
	c.draw_line(_m(x0, y0), _m(x1, y1), col, w, true)


# The Sov in the summer of 1958, Gary's father's picture: the hotel fresh painted, all of the sign
# on the roof, BEVERAGE ROOM painted over the door where the neon is now, a car out front and him
# by the door in his hat. Black and white gone a little brown; the date on the border in his hand.
func _photo58(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("e6e0cf"))
	var im := Rect2(r.position + Vector2(30, 30), Vector2(r.size.x - 60.0, r.size.y - 114.0))
	var L := im.position.x
	var T := im.position.y
	var W := im.size.x
	var H := im.size.y
	var base := T + 600.0            # the foot of the building
	var hz := base - 74.0            # the horizon, at the camera's height
	_po = Vector2(L + 197.6, base)
	_ps = 46.0
	# the sky, paler down to the hills; a cloud
	c.draw_polygon(PackedVector2Array([Vector2(L, T), Vector2(L + W, T), Vector2(L + W, hz), Vector2(L, hz)]),
		PackedColorArray([_g(0.7), _g(0.7), _g(0.88), _g(0.88)]))
	_oval(c, Vector2(L + 120, T + 70), 150, 26, _g(0.8, 0.6))
	_oval(c, Vector2(L + 1030, T + 120), 120, 20, _g(0.81, 0.5))
	# the hills across the water, and the trees on the shore under them
	var hills := PackedVector2Array([Vector2(L, hz)])
	for i in 13:
		hills.append(Vector2(L + W * i / 12.0, hz - 70.0 - 24.0 * sin(i * 1.7) - 12.0 * sin(i * 3.1 + 1.0)))
	hills.append(Vector2(L + W, hz))
	c.draw_colored_polygon(hills, _g(0.63))
	var trees := PackedVector2Array([Vector2(L, base)])
	for i in 58:
		trees.append(Vector2(L + W * i / 57.0, hz - 6.0 - (16.0 if i % 2 == 0 else 2.0) - 8.0 * sin(i * 0.9)))
	trees.append(Vector2(L + W, base))
	c.draw_colored_polygon(trees, _g(0.36))
	# the lot, gravel, a puddle or two with the sky in them
	c.draw_polygon(PackedVector2Array([Vector2(L, base - 4.0), Vector2(L + W, base - 4.0), Vector2(L + W, T + H), Vector2(L, T + H)]),
		PackedColorArray([_g(0.58), _g(0.58), _g(0.46), _g(0.46)]))
	_oval(c, Vector2(L + 300, base + 92), 70, 9, _g(0.72, 0.8))
	_oval(c, Vector2(L + 860, base + 108), 46, 7, _g(0.7, 0.8))
	# the power pole at the edge of the lot, its wires off out of the picture
	c.draw_rect(Rect2(L + 60, T + 40, 9, base + 30.0 - T - 40.0), _g(0.22))
	c.draw_rect(Rect2(L + 26, T + 60, 78, 7), _g(0.22))
	for wx in [L + 30.0, L + 64.0, L + 100.0]:
		c.draw_line(Vector2(wx, T + 58), Vector2(L - 2, T + 90), _g(0.2), 1.5, true)
		c.draw_line(Vector2(wx, T + 58), Vector2(L + 260, T - 2), _g(0.2), 1.5, true)
	# the side of it, going away
	var s0 := _m(16.6, 0)
	var s1 := _m(16.6, 9.9)
	c.draw_colored_polygon(PackedVector2Array([s0, s1, s1 + Vector2(44, 12), s0 + Vector2(44, -5)]), _g(0.34))
	# the front: the boards, the trim at the corners and between the floors
	_mr(c, -0.6, 0.0, 16.6, 9.9, _g(0.47))
	var y := 0.25
	while y < 9.8:
		_mr(c, -0.6, y, 16.6, y + 0.035, _g(0.39))
		y += 0.22
	for x in [-0.6, 16.3]:
		_mr(c, x, 0.0, x + 0.3, 9.9, _g(0.8))
	for by in [3.3, 6.6]:
		_mr(c, -0.6, by, 16.6, by + 0.16, _g(0.78))
	_mr(c, -0.9, 9.72, 16.9, 10.25, _g(0.26))
	_mr(c, -0.9, 9.72, 16.9, 9.82, _g(0.72))
	# the rooms' windows, the blinds at their heights
	var rr := RandomNumberGenerator.new()
	rr.seed = 58
	for row in [4.5, 7.8]:
		for x in [1.4, 3.6, 5.8, 8.0, 10.2, 12.4, 14.6]:
			_mr(c, x - 0.62, row - 0.74, x + 0.62, row + 0.74, _g(0.84))
			c.draw_polygon(PackedVector2Array([_m(x - 0.5, row + 0.65), _m(x + 0.5, row + 0.65), _m(x + 0.5, row - 0.65), _m(x - 0.5, row - 0.65)]),
				PackedColorArray([_g(0.42), _g(0.36), _g(0.14), _g(0.16)]))
			var blind := rr.randf_range(0.0, 1.0)
			if blind > 0.3:
				_mr(c, x - 0.5, row + 0.65 - blind * 0.9, x + 0.5, row + 0.65, _g(0.76))
			_mr(c, x - 0.5, row - 0.03, x + 0.5, row + 0.03, _g(0.84))
			_mr(c, x - 0.68, row - 0.82, x + 0.68, row - 0.74, _g(0.9))
	# the door, its two leaves and their glass; the beverage room's window
	_mr(c, 2.18, 0.0, 4.22, 2.44, _g(0.84))
	_mr(c, 2.3, 0.0, 4.1, 2.3, _g(0.17))
	for lx in [2.45, 3.3]:
		_mr(c, lx, 1.25, lx + 0.65, 2.12, _g(0.3))
	_mr(c, 3.19, 0.0, 3.21, 2.3, _g(0.08))
	_mr(c, 6.18, 0.8, 12.82, 2.52, _g(0.84))
	c.draw_polygon(PackedVector2Array([_m(6.3, 2.4), _m(12.7, 2.4), _m(12.7, 0.9), _m(6.3, 0.9)]),
		PackedColorArray([_g(0.4), _g(0.34), _g(0.16), _g(0.2)]))
	for mx in [8.43, 10.57]:
		_mr(c, mx - 0.05, 0.9, mx + 0.05, 2.4, _g(0.84))
	_mp(c, [Vector2(7.0, 2.4), Vector2(7.7, 2.4), Vector2(6.9, 0.9), Vector2(6.3, 0.9), Vector2(6.3, 1.2)], _g(0.5, 0.35))
	# the sign over the door, painted
	_mr(c, 1.95, 3.42, 6.65, 4.3, _g(0.2))
	_mr(c, 2.02, 3.49, 6.58, 4.23, _g(0.9))
	var fs := _fit("zilla_b", "BEVERAGE ROOM", 40, 4.2 * _ps)
	_say(c, "zilla_b", "BEVERAGE ROOM", _m(4.3, 3.86) + Vector2(0, _cap("zilla_b", fs) / 2.0), fs, _g(0.14))
	# the fire escape at the east end
	for fy in [3.1, 6.4]:
		_mr(c, 14.7, fy - 0.06, 16.9, fy + 0.04, _g(0.12))
		_ml(c, 14.7, fy + 0.9, 16.9, fy + 0.9, _g(0.12), 2.0)
		var px := 14.7
		while px <= 16.95:
			_ml(c, px, fy, px, fy + 0.9, _g(0.15), 1.2)
			px += 0.22
	_ml(c, 16.6, 3.1, 15.2, 6.4, _g(0.14), 2.0)
	_ml(c, 16.4, 3.1, 15.0, 6.4, _g(0.14), 2.0)
	# the sign on the roof, its rack, every letter of it there
	_mr(c, 2.9, 10.82, 13.1, 10.9, _g(0.18))
	for x in [3.3, 8.31, 12.7]:
		_mr(c, x - 0.05, 10.0, x + 0.05, 11.95, _g(0.18))
	var big := int(1.0 * _ps / 0.7)
	var word := "SOVEREIGN"
	for i in word.length():
		var at := _m(8.0 + (i - 4) * 1.02, 10.85)
		_say(c, "ui_b", word[i], at + Vector2(1.5, -1.5), big, _g(0.72))
		_say(c, "ui_b", word[i], at, big, _g(0.13))
	var small := int(0.58 * _ps / 0.7)
	var h2 := "HOTEL"
	for i in h2.length():
		var at := _m(8.0 + (i - 2) * 0.62, 10.21)
		_say(c, "ui_b", h2[i], at + Vector2(1.0, -1.0), small, _g(0.72))
		_say(c, "ui_b", h2[i], at, small, _g(0.13))
	# his car out front, then him by the door
	var keep_o := _po
	_po = Vector2(_m(8.4, 0.0).x, base + 30.0)
	_ps = 54.0
	_car58(c)
	_po = Vector2(keep_o.x + 5.05 * 46.0, base + 60.0)
	_ps = 61.0
	_father(c)
	_po = keep_o
	_ps = 46.0
	# the grain, the corners gone dark, the brown it's gone, a little faded
	if _keep.size() >= 2:
		c.draw_texture_rect(_keep[0], im, false, Color(1, 1, 1, 0.1))
		c.draw_texture_rect(_keep[1], im, false)
	c.draw_rect(im, Color(0.45, 0.33, 0.18, 0.1))
	c.draw_rect(im, Color(0.96, 0.94, 0.9, 0.06))
	_say(c, "hand", "Aug. 1958", Vector2(r.end.x - 150.0, r.end.y - 26.0), 42, Color("2b3242"))


# a big car of the time, side on, its nose to the left: whitewalls, chrome, the fins
func _car58(c: Control) -> void:
	_oval(c, _m(2.65, 0.0), 2.9 * _ps, 0.16 * _ps, _g(0.22, 0.7))
	for wx in [1.0, 4.15]:
		c.draw_circle(_m(wx, 0.36), 0.36 * _ps, _g(0.08))
		c.draw_circle(_m(wx, 0.36), 0.25 * _ps, _g(0.86))
		c.draw_circle(_m(wx, 0.36), 0.17 * _ps, _g(0.62))
	_mp(c, [Vector2(0.0, 0.42), Vector2(0.0, 0.78), Vector2(0.18, 0.88), Vector2(1.55, 0.97), Vector2(1.95, 1.02),
		Vector2(2.4, 1.46), Vector2(3.75, 1.48), Vector2(4.3, 1.04), Vector2(5.0, 0.98), Vector2(5.32, 1.06),
		Vector2(5.32, 0.46), Vector2(5.15, 0.34), Vector2(4.6, 0.34), Vector2(4.55, 0.62), Vector2(3.75, 0.62),
		Vector2(3.7, 0.34), Vector2(1.5, 0.34), Vector2(1.45, 0.62), Vector2(0.55, 0.62), Vector2(0.5, 0.34),
		Vector2(0.2, 0.34)], _g(0.3))
	# the skirt over the back wheel
	_mp(c, [Vector2(3.72, 0.36), Vector2(3.78, 0.64), Vector2(4.52, 0.64), Vector2(4.58, 0.36)], _g(0.3))
	_mp(c, [Vector2(2.08, 1.04), Vector2(2.45, 1.41), Vector2(3.68, 1.43), Vector2(4.12, 1.05)], _g(0.16))
	_mr(c, 2.95, 1.04, 3.02, 1.42, _g(0.3))
	_mp(c, [Vector2(2.5, 1.38), Vector2(3.0, 1.4), Vector2(2.7, 1.1), Vector2(2.3, 1.1)], _g(0.45, 0.5))
	_ml(c, 0.25, 0.7, 5.15, 0.74, _g(0.88), 2.5)
	_mr(c, -0.06, 0.32, 0.4, 0.52, _g(0.86))
	_mr(c, 4.95, 0.34, 5.38, 0.52, _g(0.86))
	c.draw_circle(_m(0.06, 0.72), 0.08 * _ps, _g(0.92))
	_ml(c, 0.2, 0.9, 1.6, 0.98, _g(0.62), 2.0)


# Gary's father, by the door in his hat and his good coat, his hands at his sides
func _father(c: Control) -> void:
	_oval(c, _m(0.06, 0.0), 0.42 * _ps, 0.07 * _ps, _g(0.24, 0.6))
	_mr(c, -0.17, 0.0, -0.02, 0.07, _g(0.07))
	_mr(c, 0.03, 0.0, 0.18, 0.07, _g(0.07))
	_mr(c, -0.15, 0.07, -0.02, 0.86, _g(0.22))
	_mr(c, 0.02, 0.07, 0.15, 0.86, _g(0.2))
	_mp(c, [Vector2(-0.27, 0.62), Vector2(0.27, 0.62), Vector2(0.25, 1.42), Vector2(0.19, 1.5), Vector2(-0.19, 1.5), Vector2(-0.25, 1.42)], _g(0.19))
	_mp(c, [Vector2(-0.06, 1.49), Vector2(0.06, 1.49), Vector2(0.0, 1.27)], _g(0.86))
	_mp(c, [Vector2(-0.015, 1.45), Vector2(0.015, 1.45), Vector2(0.02, 1.27), Vector2(0.0, 1.24), Vector2(-0.02, 1.27)], _g(0.12))
	_mr(c, -0.34, 0.86, -0.24, 1.44, _g(0.16))
	_mr(c, 0.24, 0.86, 0.34, 1.44, _g(0.15))
	c.draw_circle(_m(-0.29, 0.83), 0.05 * _ps, _g(0.64))
	c.draw_circle(_m(0.29, 0.83), 0.05 * _ps, _g(0.6))
	_mr(c, -0.045, 1.49, 0.045, 1.55, _g(0.6))
	_oval(c, _m(0.0, 1.63), 0.095 * _ps, 0.115 * _ps, _g(0.66))
	_oval(c, _m(0.03, 1.62), 0.06 * _ps, 0.09 * _ps, _g(0.74))
	# the hat: brim, crown, band
	_oval(c, _m(0.0, 1.715), 0.2 * _ps, 0.035 * _ps, _g(0.11))
	_mp(c, [Vector2(-0.12, 1.71), Vector2(0.12, 1.71), Vector2(0.11, 1.84), Vector2(0.0, 1.81), Vector2(-0.11, 1.84)], _g(0.14))
	_mr(c, -0.12, 1.72, 0.12, 1.755, _g(0.05))


# The health inspector's notice on his desk, as the doorman reads it upside down (content/ink/office.ink,
# "Read Gary's desk upside down"): a routine inspection on the 14th, the one the note on the Sov's till
# means (prologue.ink), and PEST circled twice in his pen.
func _letter(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("f3f0e7"))
	var ink := Color("2a2a2e")
	var mid := r.position.x + r.size.x / 2.0
	var x := r.position.x + 52.0
	var y := r.position.y + 70.0
	_say(c, "receipt_b", "ENVIRONMENTAL HEALTH", Vector2(mid, y), 23, ink)
	y += 40.0
	_say(c, "receipt_b", "NOTICE OF ROUTINE INSPECTION", Vector2(mid, y), 25, ink)
	c.draw_line(Vector2(x, y + 16.0), Vector2(r.end.x - 52.0, y + 16.0), ink, 2.0)
	y += 58.0
	var lines := ["October 28, 2026", "", "To:  Van Dusen Holdings Ltd.", "Re:  Sovereign Hotel, Shore Road",
		"     (beverage room and kitchen)", "", "An inspector will attend the",
		"premises on Saturday, November 14,", "while they are open, for a routine",
		"inspection of the food premises.", "",
		"PEST CONTROL: records of service are", "to be available on request. Any", "evidence of pests is to be reported.", "",
		"Failure to comply may result in an", "order to close the premises."]
	var font := _font("receipt")
	for i in lines.size():
		_say(c, "receipt", lines[i], Vector2(x, y), 19, ink, true)
		if lines[i].begins_with("PEST"):
			# circled twice, the second time not quite on the first
			var w := font.get_string_size("PEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
			_ring(c, Vector2(x + w / 2.0, y - 6.0), w / 2.0 + 9.0, 15.0, Color("2b4c9e"), 2.4)
			_ring(c, Vector2(x + w / 2.0 + 2.0, y - 5.0), w / 2.0 + 12.0, 17.0, Color("2b4c9e"), 2.0)
		y += 25.0
	# the signature, and who it is
	y += 22.0
	var sig := PackedVector2Array()
	for i in 40:
		var t := float(i) / 39.0
		sig.append(Vector2(x + 10.0 + t * 150.0, y - 8.0 - 12.0 * sin(t * 19.0) * (1.0 - t * 0.6) + t * 6.0))
	c.draw_polyline(sig, Color("1d2440"), 2.0, true)
	_say(c, "receipt", "Inspector", Vector2(x, y + 26.0), 19, ink, true)


# The snapshot on his desk: a woman and a girl on a beach, a cold day, both in their coats.
func _desk_photo(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("efece3"))
	var im := Rect2(r.position + Vector2(10, 10), r.size - Vector2(20, 20))
	var L := im.position.x
	var T := im.position.y
	var W := im.size.x
	var H := im.size.y
	var sea := T + H * 0.42
	var sand := T + H * 0.6
	c.draw_polygon(PackedVector2Array([Vector2(L, T), Vector2(L + W, T), Vector2(L + W, sea), Vector2(L, sea)]),
		PackedColorArray([Color("a9b8c2"), Color("a9b8c2"), Color("cdd5d6"), Color("cdd5d6")]))
	c.draw_colored_polygon(PackedVector2Array([Vector2(L, sea), Vector2(L + 30, sea - 18), Vector2(L + 90, sea - 10), Vector2(L + 120, sea)]), Color("7c8a82"))
	c.draw_rect(Rect2(L, sea, W, sand - sea), Color("6f8593"))
	c.draw_rect(Rect2(L, sea + 10, W, 3), Color(0.85, 0.88, 0.9, 0.5))
	c.draw_polygon(PackedVector2Array([Vector2(L, sand), Vector2(L + W, sand), Vector2(L + W, T + H), Vector2(L, T + H)]),
		PackedColorArray([Color("c9bc9f"), Color("c9bc9f"), Color("b3a586"), Color("b3a586")]))
	_po = Vector2(L + 86, T + H - 22)
	_ps = 92.0
	# her: dark hair, a teal coat
	_mr(c, -0.14, 0.0, -0.03, 0.8, Color("3d4048"))
	_mr(c, 0.03, 0.0, 0.14, 0.8, Color("3d4048"))
	_mp(c, [Vector2(-0.26, 0.7), Vector2(0.26, 0.7), Vector2(0.22, 1.42), Vector2(-0.22, 1.42)], Color("4f7480"))
	_oval(c, _m(0.0, 1.58), 0.11 * _ps, 0.13 * _ps, Color("d9b99c"))
	_mp(c, [Vector2(-0.14, 1.66), Vector2(0.14, 1.66), Vector2(0.16, 1.4), Vector2(0.1, 1.5), Vector2(-0.1, 1.5), Vector2(-0.16, 1.4)], Color("4a3a2e"))
	_oval(c, _m(0.0, 1.69), 0.13 * _ps, 0.07 * _ps, Color("4a3a2e"))
	# the girl in front of her, a yellow raincoat
	_po = Vector2(L + 156, T + H - 14)
	_ps = 92.0
	_mr(c, -0.09, 0.0, -0.02, 0.45, Color("40434a"))
	_mr(c, 0.02, 0.0, 0.09, 0.45, Color("40434a"))
	_mp(c, [Vector2(-0.17, 0.4), Vector2(0.17, 0.4), Vector2(0.14, 0.88), Vector2(-0.14, 0.88)], Color("d2ad46"))
	_oval(c, _m(0.0, 0.99), 0.085 * _ps, 0.1 * _ps, Color("e0c0a2"))
	_oval(c, _m(0.0, 1.06), 0.1 * _ps, 0.06 * _ps, Color("8a6a4a"))
	c.draw_rect(im, Color(1.0, 0.97, 0.9, 0.12))


func _ice(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("f0f2f3"))
	var blue := Color("2a5d9c")
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 12)), blue)
	c.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 12), Vector2(r.size.x, 12)), blue)
	var s := _fit("archivo", "ICE", 76, r.size.x - 40.0, 8.0)
	_say(c, "archivo", "ICE", Vector2(r.position.x + r.size.x / 2.0, r.position.y + r.size.y / 2.0 + _cap("archivo", s) / 2.0), s, blue, false, 8.0)


# the cafe's board on the sidewalk, in chalk
func _chalk(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("2b2f2d"))
	_oval(c, r.position + Vector2(80, 120), 70, 30, Color(0.9, 0.9, 0.88, 0.05), 0.3)
	_oval(c, r.position + Vector2(170, 250), 60, 24, Color(0.9, 0.9, 0.88, 0.05), -0.2)
	var chalk := Color(0.93, 0.92, 0.88, 0.92)
	var mid := r.position.x + r.size.x / 2.0
	var y := r.position.y + 62.0
	_say(c, "hand", "OPEN", Vector2(mid, y), 46, chalk)
	c.draw_line(Vector2(mid - 50, y + 12), Vector2(mid + 52, y + 9), chalk, 2.0, true)
	y += 54.0
	for l in [["Soup today", 26], ["Clam chowder", 28], ["", 10], ["Pie  $4.50", 30], ["Coffee  $2.25", 30]]:
		if l[0] != "":
			_say(c, "hand", l[0], Vector2(mid, y), l[1], chalk)
		y += 40.0 if l[0] != "" else 14.0


# the name on his door, gold leaf with a black edge, to be read from the street
func _door_gold(c: Control, r: Rect2) -> void:
	var mid := r.position.x + r.size.x / 2.0
	var s1 := _fit("zilla_b", "VAN DUSEN", 150, r.size.x - 60.0, 6.0)
	var s2 := _fit("zilla_b", "HOLDINGS", 84, r.size.x * 0.62, 18.0)
	var y1 := r.position.y + 30.0 + _cap("zilla_b", s1)
	var y2 := y1 + 34.0 + _cap("zilla_b", s2)
	for pass_k in 2:
		var col := Color(0.04, 0.03, 0.02, 1.0) if pass_k == 0 else Color(1, 1, 1, 1)
		var offs: Array = [Vector2.ZERO]
		if pass_k == 0:
			offs = []
			for k in 12:
				offs.append(Vector2(cos(TAU * k / 12.0), sin(TAU * k / 12.0)) * 4.5)
		for o in offs:
			_say(c, "zilla_b", "VAN DUSEN", Vector2(mid, y1) + o, s1, col, false, 6.0)
			_say(c, "zilla_b", "HOLDINGS", Vector2(mid, y2) + o, s2, col, false, 18.0)


# The calendar over the bookkeeper's desk: a fish boat at a float for the picture, November.
func _calendar(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("f1efe9"))
	var p := Rect2(r.position + Vector2(18, 18), Vector2(r.size.x - 36.0, 196))
	var L := p.position.x
	var T := p.position.y
	var W := p.size.x
	var hz := T + 110.0
	c.draw_polygon(PackedVector2Array([Vector2(L, T), Vector2(L + W, T), Vector2(L + W, hz), Vector2(L, hz)]),
		PackedColorArray([Color("9fb4c4"), Color("9fb4c4"), Color("d3dbdc"), Color("d3dbdc")]))
	c.draw_colored_polygon(PackedVector2Array([Vector2(L, hz), Vector2(L, hz - 34), Vector2(L + 70, hz - 52), Vector2(L + 150, hz - 30),
		Vector2(L + 220, hz - 44), Vector2(L + W, hz - 22), Vector2(L + W, hz)]), Color("5d6f69"))
	c.draw_rect(Rect2(L, hz, W, p.size.y - 110.0), Color("5f7c8c"))
	for k in 6:
		c.draw_line(Vector2(L + 10 + k * 47, hz + 22 + k % 3 * 18), Vector2(L + 40 + k * 47, hz + 22 + k % 3 * 18), Color(0.85, 0.9, 0.93, 0.5), 2.0)
	# the boat: her hull, the stripe, the wheelhouse, the mast and the poles
	var b := Vector2(L + 70, hz + 30)
	c.draw_colored_polygon(PackedVector2Array([b, b + Vector2(170, 0), b + Vector2(186, -30), b + Vector2(-6, -30)]), Color("e4e4df"))
	c.draw_rect(Rect2(b + Vector2(-4, -30), Vector2(190, 6)), Color("2c3b5c"))
	c.draw_rect(Rect2(b + Vector2(30, -66), Vector2(56, 36)), Color("e9e9e4"))
	c.draw_rect(Rect2(b + Vector2(38, -60), Vector2(40, 12)), Color("39434c"))
	c.draw_line(b + Vector2(100, -30), b + Vector2(100, -120), Color("3a3a3a"), 3.0)
	c.draw_line(b + Vector2(110, -30), b + Vector2(40, -140), Color("3a3a3a"), 2.0)
	c.draw_line(b + Vector2(120, -30), b + Vector2(196, -136), Color("3a3a3a"), 2.0)
	c.draw_rect(Rect2(b + Vector2(-10, 0), Vector2(200, 8)), Color(0.2, 0.25, 0.3, 0.5))
	# the month
	var mid := r.position.x + r.size.x / 2.0
	var ink := Color("2a2a2e")
	_say(c, "ui_b", "NOVEMBER  2026", Vector2(mid, T + p.size.y + 44.0), 34, ink, false, 2.0)
	var gx := r.position.x + 18.0
	var gy := T + p.size.y + 60.0
	var cw := (r.size.x - 36.0) / 7.0
	var ch := 36.0
	var days := ["S", "M", "T", "W", "T", "F", "S"]
	for i in 7:
		_say(c, "ui_b", days[i], Vector2(gx + cw * (i + 0.5), gy + 16.0), 16, Color("5a5a5e"))
	gy += 24.0
	for d in 30:
		var col := d % 7
		var row := d / 7
		var cell := Rect2(gx + cw * col, gy + ch * row, cw, ch)
		c.draw_rect(cell, Color(0.55, 0.55, 0.56, 0.5), false, 1.0)
		_say(c, "ui", str(d + 1), cell.position + Vector2(5, 19), 18, ink, true)


# The licence in its frame by the door, from the year his father opened: beer by the glass.
func _licence(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("e8dfc6"))
	var brown := Color("5a4630")
	c.draw_rect(Rect2(r.position + Vector2(14, 14), r.size - Vector2(28, 28)), brown, false, 3.0)
	c.draw_rect(Rect2(r.position + Vector2(22, 22), r.size - Vector2(44, 44)), brown, false, 1.2)
	for k in 4:
		var corner := r.position + Vector2(22 if k % 2 == 0 else r.size.x - 22.0, 22 if k < 2 else r.size.y - 22.0)
		c.draw_circle(corner, 7.0, brown)
		c.draw_circle(corner, 4.0, Color("e8dfc6"))
	var mid := r.position.x + r.size.x / 2.0
	var y := r.position.y + 86.0
	_say(c, "zilla_b", "LICENCE", Vector2(mid, y), 44, brown, false, 8.0)
	y += 42.0
	_say(c, "cormorant", "to sell beer by the glass", Vector2(mid, y), 25, brown)
	y += 30.0
	_say(c, "cormorant", "in the beverage room of", Vector2(mid, y), 22, brown)
	y += 46.0
	var s := _fit("zilla_b", "THE SOVEREIGN HOTEL", 30, r.size.x - 70.0, 1.0)
	_say(c, "zilla_b", "THE SOVEREIGN HOTEL", Vector2(mid, y), s, Color("2e241a"), false, 1.0)
	y += 30.0
	_say(c, "cormorant", "Shore Road", Vector2(mid, y), 22, brown)
	y += 44.0
	_say(c, "cormorant", "for the year", Vector2(mid, y), 20, brown)
	y += 40.0
	_say(c, "zilla_b", "1958", Vector2(mid, y), 36, Color("2e241a"), false, 4.0)
	# the seal, the ribbons under it; the signatures
	var sp := Vector2(r.position.x + 92.0, r.end.y - 84.0)
	c.draw_colored_polygon(PackedVector2Array([sp + Vector2(-14, 10), sp + Vector2(-4, 10), sp + Vector2(-20, 62), sp + Vector2(-30, 52)]), Color("2c3b5c"))
	c.draw_colored_polygon(PackedVector2Array([sp + Vector2(4, 10), sp + Vector2(14, 10), sp + Vector2(30, 52), sp + Vector2(20, 62)]), Color("2c3b5c"))
	var teeth := PackedVector2Array()
	for k in 48:
		var a := TAU * k / 48.0
		teeth.append(sp + Vector2(cos(a), sin(a)) * (36.0 if k % 2 == 0 else 32.0))
	c.draw_colored_polygon(teeth, Color("c2a052"))
	c.draw_arc(sp, 26.0, 0.0, TAU, 40, Color("8e7234"), 2.0, true)
	c.draw_arc(sp, 18.0, 0.0, TAU, 40, Color("8e7234"), 1.2, true)
	for k in 2:
		var lx := r.position.x + 178.0
		var ly := r.end.y - 104.0 + k * 46.0
		c.draw_line(Vector2(lx, ly), Vector2(lx + 150, ly), brown, 1.2)
		var sig := PackedVector2Array()
		for i in 24:
			var t := float(i) / 23.0
			sig.append(Vector2(lx + 12 + t * 120.0, ly - 6.0 - 9.0 * sin(t * (14.0 + k * 5.0))))
		c.draw_polyline(sig, Color("2a2a3a"), 1.6, true)


# the white church's board on its lawn, white letters pressed into its grooves
func _church_board(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("232c28"))
	var yy := r.position.y + 6.0
	while yy < r.end.y:
		c.draw_line(Vector2(r.position.x, yy), Vector2(r.end.x, yy), Color(0, 0, 0, 0.35), 1.0)
		yy += 11.0
	var cream := Color("ecebe4")
	var mid := r.position.x + r.size.x / 2.0
	var y := r.position.y + 46.0
	for l in [["ST. ANDREW'S", 34], ["SUNDAY SERVICE", 22], ["10:30 AM", 30], ["ALL WELCOME", 20]]:
		var s := _fit("ui_b", l[0], l[1], r.size.x - 30.0, 2.0)
		_say(c, "ui_b", l[0], Vector2(mid, y), s, cream, false, 2.0)
		y += 44.0 if l[1] >= 30 else 38.0


# a card in the papered window of the video store
func _lease(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("f2efe6"))
	var ink := Color("2a2a2e")
	var mid := r.position.x + r.size.x / 2.0
	var s := _fit("archivo", "FOR LEASE", 40, r.size.x - 30.0)
	_say(c, "archivo", "FOR LEASE", Vector2(mid, r.position.y + 72.0), s, ink)
	_say(c, "ui_b", "250 555 0143", Vector2(mid, r.position.y + 132.0), 36, ink, false, 1.0)
	for k in 2:
		var tp := r.position + Vector2(-8.0 + k * (r.size.x - 40.0), 8.0)
		c.draw_rect(Rect2(tp, Vector2(56, 18)), Color(0.95, 0.94, 0.86, 0.6))


# a painted sign: its words as big as they'll go, a line round them in their colour
func _sign(c: Control, r: Rect2, t: String, f: String, bg: Color, ink: Color, track := 0.0, edge := true) -> void:
	c.draw_rect(r, bg)
	if edge:
		c.draw_rect(Rect2(r.position + Vector2(9, 9), r.size - Vector2(18, 18)), ink, false, 3.0)
	var s := _fit(f, t, int(r.size.y * 0.9), r.size.x - 70.0, track)
	while _cap(f, s) > r.size.y * 0.56 and s > 8:
		s -= 2
	var mid := r.position + r.size / 2.0
	_say(c, f, t, Vector2(mid.x, mid.y + _cap(f, s) / 2.0), s, ink, false, track)


# Letters cut into sandstone: deep in shadow in the cut, the light catching its lower lip, on a
# panel dressed a little smoother than the rest. In the stone's own strokes (T.carved) the cuts go
# solid and the panel's strokes thin, so the word reads the way the stone does.
func _carved(c: Control, r: Rect2, t: String, track: float) -> void:
	c.draw_rect(r, Color("cdbb96"))
	var rr := RandomNumberGenerator.new()
	rr.seed = int(r.position.y)
	for k in 14:
		_oval(c, r.position + Vector2(rr.randf() * r.size.x, rr.randf() * r.size.y), rr.randf_range(20, 70), rr.randf_range(8, 20), Color(0.55, 0.47, 0.33, 0.08))
	var s := _fit("zilla_b", t, int(r.size.y * 0.8), r.size.x - 60.0, track)
	while _cap("zilla_b", s) > r.size.y * 0.62 and s > 8:
		s -= 2
	var at := r.position + r.size / 2.0 + Vector2(0, _cap("zilla_b", s) / 2.0)
	_say(c, "zilla_b", t, at + Vector2(0, 4), s, Color("eadfc2"), false, track)
	for o in [Vector2(-1.5, 0), Vector2(1.5, 0), Vector2.ZERO]:
		_say(c, "zilla_b", t, at + o, s, Color("1f1a12"), false, track)


# the video store's sign, years in the sun: the blue letters gone pale and coming away
func _video_sign(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("dcd8cc"))
	var s := _fit("archivo", "VIDEO", int(r.size.y * 0.9), r.size.x - 120.0, 14.0)
	while _cap("archivo", s) > r.size.y * 0.6 and s > 8:
		s -= 2
	var mid := r.position + r.size / 2.0
	_say(c, "archivo", "VIDEO", Vector2(mid.x, mid.y + _cap("archivo", s) / 2.0), s, Color("8d9db0"), false, 14.0)
	var rr := RandomNumberGenerator.new()
	rr.seed = 1999
	for k in 26:
		_oval(c, r.position + Vector2(rr.randf_range(60.0, r.size.x - 60.0), rr.randf_range(20.0, r.size.y - 20.0)), rr.randf_range(6, 26), rr.randf_range(3, 9), Color(0.86, 0.85, 0.8, 0.75), rr.randf_range(-0.5, 0.5))
