# The island highway, north and south of the Sov, far enough to drive (game/truck.gd). The old road
# along the water, the same every game: out of town north past the motel and up over the bluff,
# down again along the shore past the fish plant to the mill road, and the washout where the road's
# closed; south past the church and the shut fruit stand, up through the cut in the hill, down to
# the flats and the sign for the ferry, and the bridge that's out. About eight kilometres of road
# all told at the island's scale (a twelfth of the real thing, as the design has it: four minutes
# to the ferry), with the Sov's own stretch of it (world/pub.gd, world/town.gd) in the middle.
#
# What's built is the line of it and what's beside it, worked out from shapes the same way the
# grounds are: the road with its crown, the gravel shoulders, the ditch on the hill side and the
# bank going up into the trees, the shore falling to the water on the other, the guardrail where
# it falls hard, power poles, mailboxes, houses back off the road with a light on or not, the
# kilometre posts and the signs. And the ground under the truck's tires anywhere: ground() is the
# height, the slope and what it's made of (game/truck_sim.gd asks it four times a step).
#
# Units are the Sov's: metres, +x north along the shore, +z east out to the water.
class_name IslandRoad
extends Node3D

const STEP := 4.0                       # metres between the samples down the road's line
const HALF_ROAD := 4.0                  # the paved half (two lanes of 3.6 and the lines)
const SHOULDER := 5.6                   # the gravel's outer edge
const CHUNK := 64.0                     # metres of road a mesh
const CELL := 32.0                      # the lookup grid
const SOV_X := Vector2(-340.0, 320.0)   # the Sov's stretch of the highway (built already, flat, straight)
const SOV_Z := 31.6
# the line of it, south end to north end: x, z, the road's height
const LINE := [
	[-2260.0, 30.0, 5.0], [-2050.0, 52.0, 2.4], [-1820.0, 74.0, 1.6], [-1600.0, 58.0, 2.4],
	[-1420.0, 22.0, 6.0], [-1260.0, -26.0, 12.0], [-1100.0, -52.0, 16.5], [-950.0, -36.0, 13.0],
	[-820.0, 4.0, 6.0], [-690.0, 30.0, 2.0], [-560.0, 40.0, 0.6], [-450.0, 33.5, 0.1],
	[-390.0, 31.6, 0.0], [-340.0, 31.6, 0.0], [-260.0, 31.6, 0.0], [-180.0, 31.6, 0.0], [-100.0, 31.6, 0.0],
	[-20.0, 31.6, 0.0], [60.0, 31.6, 0.0], [140.0, 31.6, 0.0], [220.0, 31.6, 0.0], [320.0, 31.6, 0.0], [370.0, 31.6, 0.0], [430.0, 34.0, 0.2], [540.0, 26.0, 1.0],
	[660.0, -6.0, 5.0], [790.0, -44.0, 12.0], [940.0, -58.0, 17.0], [1090.0, -30.0, 13.0],
	[1230.0, 22.0, 5.0], [1380.0, 52.0, 1.6], [1560.0, 60.0, 1.2], [1760.0, 40.0, 2.6],
	[1950.0, 56.0, 3.2], [2140.0, 104.0, 1.8], [2350.0, 120.0, 2.2], [2560.0, 96.0, 5.0],
]
# places along it: distance from the Sov's door (+ north, - south) in metres of road
const MOTEL := 420.0
const FISH_PLANT := 1520.0
const MILL_ROAD := 2140.0
const WASHOUT := 2380.0
const CHURCH := -520.0
const FRUIT := -900.0
const FERRY_SIGN := -1620.0
const BRIDGE_OUT := -1860.0

var pts := PackedVector3Array()         # the line, every STEP metres
var dirs := PackedVector3Array()        # its way north there, flat
var dist := PackedFloat32Array()        # metres from the south end
var zero := 0.0                         # the distance along it at the Sov's door
var _grid := {}                         # cell -> sample indices
var walls: Array = []                   # what a truck can hit out here: [middle (x, z), half, turned, top]
var _wall_grid := {}
var lamps: Array = []                   # the motel's sign and the mill's shack: lights that flicker
var M: Dictionary
var T: Dictionary
var pub: Pub
var rain_on := true
var _rng := RandomNumberGenerator.new()
var _mats := {}


# ---------------------------------------------------------------- the line

func _init() -> void:
	_rng.seed = 1978
	_lay_line()


func _lay_line() -> void:
	var ctrl: Array = []
	for p in LINE:
		ctrl.append(Vector3(p[0], p[2], p[1]))
	# Catmull-Rom through the control points, then evened out to every STEP metres
	var dense: Array = []
	for i in ctrl.size() - 1:
		var p0: Vector3 = ctrl[maxi(i - 1, 0)]
		var p1: Vector3 = ctrl[i]
		var p2: Vector3 = ctrl[i + 1]
		var p3: Vector3 = ctrl[mini(i + 2, ctrl.size() - 1)]
		var n := maxi(4, int(p1.distance_to(p2) / 2.0))
		for k in n:
			var t := float(k) / float(n)
			var t2 := t * t
			var t3 := t2 * t
			dense.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	dense.append(ctrl[ctrl.size() - 1])
	var acc := 0.0
	var want := 0.0
	pts.append(dense[0])
	dist.append(0.0)
	for i in range(1, dense.size()):
		var a: Vector3 = dense[i - 1]
		var b: Vector3 = dense[i]
		var seg := Vector2(b.x - a.x, b.z - a.z).length()
		while acc + seg >= want + STEP:
			want += STEP
			var k := (want - acc) / seg
			pts.append(a.lerp(b, k))
			dist.append(want)
		acc += seg
	for i in pts.size():
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, pts.size() - 1)]
		dirs.append(Vector3(b.x - a.x, 0.0, b.z - a.z).normalized())
		var c := Vector2i(floori(pts[i].x / CELL), floori(pts[i].z / CELL))
		if not _grid.has(c):
			_grid[c] = []
		(_grid[c] as Array).append(i)
	# the Sov's door is at x 3.2 on the highway's line
	zero = along(Vector3(3.2, 0.0, SOV_Z))[0]


# The nearest point of the road's line to (x, z): [distance along it, how far to the side (+ to the
# east of a man driving north: the water's side), the road's height there, the sample's index]
func along(p: Vector3) -> Array:
	var c := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
	var best := INF
	var bi := -1
	for r in [1, 3, 6]:
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var l = _grid.get(c + Vector2i(dx, dz))
				if l == null:
					continue
				for i in l:
					var q := pts[i]
					var d := (q.x - p.x) * (q.x - p.x) + (q.z - p.z) * (q.z - p.z)
					if d < best:
						best = d
						bi = i
		if bi >= 0:
			break
	if bi < 0:
		return [0.0, 999.0, 0.0, 0]
	# onto the segment either side of it
	var q := pts[bi]
	var dir := dirs[bi]
	var rel := Vector3(p.x - q.x, 0.0, p.z - q.z)
	var s := clampf(rel.dot(dir), -STEP, STEP)
	var side := Vector3(-dir.z, 0.0, dir.x)       # to the right going north: east
	var j := clampi(bi + (1 if s > 0.0 else -1), 0, pts.size() - 1)
	var y := lerpf(q.y, pts[j].y, absf(s) / STEP)
	return [dist[bi] + s, rel.dot(side), y, bi]


# metres from the Sov's door, along the road, to a point on it
func at_dist(d: float) -> Array:
	var s := clampf(d + zero, 0.0, dist[dist.size() - 1])
	var i := clampi(int(s / STEP), 0, pts.size() - 2)
	var k := (s - dist[i]) / STEP
	var p := pts[i].lerp(pts[i + 1], k)
	var dir := dirs[i].lerp(dirs[i + 1], k).normalized()
	return [p, dir]


func length_n() -> float:
	return dist[dist.size() - 1] - zero


func length_s() -> float:
	return zero


static func in_sov(x: float) -> bool:
	return x > SOV_X.x and x < SOV_X.y


# ---------------------------------------------------------------- the ground

# The ground at (x, z) across the road: its height for a distance to the side, u, of the line at
# height yc. On the paved part a 2% crown; the gravel a step down; on the hill side (west, u < 0)
# the ditch and the bank up into the trees; on the water's side the shore going down, steeply under
# the guardrail where the road's up on the bluff.
static func profile(u: float, yc: float, crown := true) -> float:
	var a := absf(u)
	if a <= HALF_ROAD:
		return yc - (0.016 * a if crown else 0.0)
	if a <= SHOULDER:
		return yc - (0.064 if crown else 0.0) - 0.05 - 0.03 * (a - HALF_ROAD)
	var edge := yc - (0.064 if crown else 0.0) - 0.1
	if u < 0.0:
		# the ditch, its bottom at 7.4 out, then the bank
		if a < 7.4:
			return edge - 0.55 * smoothstep(SHOULDER, 7.4, a)
		var bank := edge - 0.55 + (a - 7.4) * 0.32 - maxf(0.0, a - 40.0) * 0.18
		return bank
	# the water's side
	if yc > 2.5:
		return maxf(edge - (a - SHOULDER) * 0.75, -3.0)
	return maxf(edge - (a - SHOULDER) * 0.07, -1.2)


# [height, normal, surface] under (x, z): what the truck's tires ask
func ground(x: float, z: float) -> Array:
	var h := height(x, z)
	var e := 0.25
	var hx := height(x + e, z) - height(x - e, z)
	var hz := height(x, z + e) - height(x, z - e)
	var n := Vector3(-hx / (2.0 * e), 1.0, -hz / (2.0 * e)).normalized()
	return [h, n, surface(x, z)]


func height(x: float, z: float) -> float:
	if in_sov(x):
		if z >= 27.6 and z <= 35.6:
			return 0.0
		return Grounds.ground_y(x, z)
	var a := along(Vector3(x, 0.0, z))
	return profile(a[1], a[2])


func surface(x: float, z: float) -> int:
	var wet := TruckSim.Surf.WET if rain_on else TruckSim.Surf.DRY
	if in_sov(x):
		if z >= 27.6 and z <= 35.6:
			return wet
		if z > Grounds.WALL_Z.y:
			return TruckSim.Surf.SAND
		if Grounds.LOT.has_point(Vector2(x, z)) or (z > 24.0 and z < 27.6):
			# the lot's gravel, and its puddles
			for pd in PUDDLES:
				if Vector2(x, z).distance_to(pd[0]) < float(pd[1]):
					return TruckSim.Surf.PUDDLE
			return TruckSim.Surf.GRAVEL
		return TruckSim.Surf.GRASS
	var a := along(Vector3(x, 0.0, z))
	var u: float = absf(a[1])
	if u <= HALF_ROAD:
		# water lying in the ruts on the low stretches
		if rain_on and float(a[2]) < 2.0 and fmod(absf(float(a[0])), 173.0) < 9.0 and absf(float(a[1]) - 2.0) < 1.1:
			return TruckSim.Surf.PUDDLE
		return wet
	if u <= SHOULDER:
		return TruckSim.Surf.GRAVEL
	return TruckSim.Surf.GRASS


const PUDDLES := [[Vector2(4.2, 11.7), 0.8], [Vector2(6.8, 12.5), 0.9], [Vector2(5.6, 14.8), 0.8],
	[Vector2(10.6, 13.3), 0.9], [Vector2(12.5, 17.9), 0.9], [Vector2(3.0, 16.4), 0.8]]


# ---------------------------------------------------------------- what's to hit

func add_wall(c: Vector2, half: Vector2, turned: float, top: float) -> void:
	var w := [c, half, turned, top]
	walls.append(w)
	var reach := half.length()
	var x0 := floori((c.x - reach) / CELL)
	var x1 := floori((c.x + reach) / CELL)
	var z0 := floori((c.y - reach) / CELL)
	var z1 := floori((c.y + reach) / CELL)
	for gx in range(x0, x1 + 1):
		for gz in range(z0, z1 + 1):
			var k := Vector2i(gx, gz)
			if not _wall_grid.has(k):
				_wall_grid[k] = []
			(_wall_grid[k] as Array).append(w)


func walls_near(p: Vector3, r := 24.0) -> Array:
	var out: Array = []
	var seen := {}
	var x0 := floori((p.x - r) / CELL)
	var x1 := floori((p.x + r) / CELL)
	var z0 := floori((p.z - r) / CELL)
	var z1 := floori((p.z + r) / CELL)
	for gx in range(x0, x1 + 1):
		for gz in range(z0, z1 + 1):
			for w in _wall_grid.get(Vector2i(gx, gz), []):
				var id: int = (w as Array).hash()
				if seen.has(id):
					continue
				seen[id] = true
				out.append(w)
	return out


# the Sov's grounds and its stretch of the highway: the building, what's lying about out back, the
# cars in the lot, the lamp post, the seawall either side of the steps, the highway's lamps
func _sov_walls() -> void:
	for k in Grounds.BOXES:
		var b: Array = Grounds.BOXES[k]
		if k == "wall_n" or k == "wall_s":
			continue
		var top := 0.9 if k in ["log_a", "log_b", "log_c", "crate", "bins", "drums", "pallets"] else 4.0
		add_wall(b[0], b[1], -deg_to_rad(float(b[2])), top)
	for c in [[Vector2(13.0, 12.4), 0.0], [Vector2(-1.5, 13.4), 8.0]]:
		add_wall(c[0], Vector2(0.9, 2.15), -deg_to_rad(c[1]), 1.4)
	add_wall(Vector2(15.8, 21.5), Vector2(0.12, 0.12), 0.0, 6.0)
	# the seawall all along the Sov's stretch, but for the steps and the wharf
	var x := SOV_X.x
	while x < SOV_X.y:
		var x1 := minf(x + 16.0, SOV_X.y)
		var mid := (x + x1) / 2.0
		var open := (mid > Grounds.STEP_X.x - 1.0 and mid < Grounds.STEP_X.y + 1.0)
		if not open:
			add_wall(Vector2(mid, 35.9), Vector2((x1 - x) / 2.0, 0.25), 0.0, 0.65)
		x = x1
	for lx in [-118.0, -84.0, -50.0, -230.0, -262.0]:
		add_wall(Vector2(lx, 26.2), Vector2(0.12, 0.12), 0.0, 8.0)
	# the barricades where the slice of road ends, and past them, solid: nobody drives off the end
	# of the world by mistake
	for d in [WASHOUT, BRIDGE_OUT]:
		var a := at_dist(d)
		var p: Vector3 = a[0]
		var dir: Vector3 = a[1]
		add_wall(Vector2(p.x, p.z), Vector2(6.5, 0.4), atan2(dir.x, -dir.z), p.y + 1.4)
		var past := at_dist(d + (20.0 if d > 0.0 else -20.0))
		var pp: Vector3 = past[0]
		add_wall(Vector2(pp.x, pp.z), Vector2(60.0, 3.0), atan2(dir.x, -dir.z), pp.y + 10.0)


# ---------------------------------------------------------------- built

func build_for(p: Pub) -> void:
	pub = p
	M = p.M
	T = p.town.T if p.town != null else {}
	_materials()
	_sov_walls()
	var s0 := 0.0
	while s0 < dist[dist.size() - 1] - 0.01:
		var s1 := minf(s0 + CHUNK, dist[dist.size() - 1])
		var mid: Vector3 = pts[int((s0 + s1) / 2.0 / STEP)]
		if not in_sov(mid.x):
			_chunk(s0, s1)
		s0 = s1
	_places()
	_water()


func _materials() -> void:
	_mats.road = pub.mat(Color("3a3a3b"), 0.55, 0.0, 1, Vector3(1, 0, 0), 7.0, 0.3)
	_mats.gravel = M.get("gravel", pub.mat(Color("5a5650")))
	_mats.line = M.get("wall", pub.mat(Color("d8d4c8")))
	_mats.yellow = pub.mat(Color("b8963a"), 0.8)
	_mats.grass = T.get("grass", pub.mat(Color("4d5243"), 0.95, 0.0, 1))
	_mats.bank = pub.mat(Color("3d4234"), 0.95, 0.0, 1, Vector3(1, 0, 0.3), 7.0, 0.3)
	_mats.shore = pub.mat(Color("4a463e"), 0.95, 0.0, 1, Vector3(1, 0, 0.3), 7.0, 0.25)
	_mats.conifer = T.get("conifer", pub.mat(Color("1f2b22")))
	_mats.bark = T.get("bark", pub.mat(Color("3a2e24")))
	_mats.pole = T.get("pole", pub.mat(Color("4a3c30")))
	_mats.rail = pub.mat(Color("8a8c88"), 0.5, 0.4, 2, Vector3(0, 1, 0))
	_mats.post = pub.mat(Color("6b5a44"))
	_mats.sign_g = pub.mat(Color("1f4a30"), 0.7)
	_mats.sign_y = pub.mat(Color("c8a43a"), 0.7)
	_mats.white = pub.mat(Color("d6d2c6"), 0.8)
	_mats.dark = M.get("dark", pub.mat(Color("1a1a1c")))
	_mats.window = pub.glow(Color("ffcf8a"), 1.4)
	_mats.window_tv = pub.glow(Color("a9c8dc"), 1.0)
	_mats.neon_r = pub.glow(Color("ff3a3a"), 2.6)
	_mats.neon_dead = pub.mat(Color("3a1414"))
	_mats.amber = pub.glow(Color("ffaa30"), 3.0)
	_mats.sodium = M.get("sodium", pub.glow(Color("ffb860"), 2.0))
	_mats.water = M.get("water", pub.mat(Color("101418"), 0.2))
	_mats.clap = T.get("clap", [pub.mat(Color("8a8070"))])
	_mats.roof = T.get("roof", pub.mat(Color("2e2a28")))


# a mesh from triangles
func _mesh(v: PackedVector3Array, n: PackedVector3Array, m: Material, parent: Node3D = null) -> MeshInstance3D:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	var u := PackedVector2Array()
	u.resize(v.size())
	arr[Mesh.ARRAY_TEX_UV] = u
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 900.0
	(parent if parent != null else self).add_child(mi)
	return mi


func _quad(v: PackedVector3Array, n: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	# a b along one edge, d c along the other (a-b-c-d round), facing up
	var nn := (b - a).cross(d - a).normalized()
	if nn.y < 0.0:
		nn = -nn
		v.append_array(PackedVector3Array([a, c, b, a, d, c]))
	else:
		v.append_array(PackedVector3Array([a, b, c, a, c, d]))
	n.append_array(PackedVector3Array([nn, nn, nn, nn, nn, nn]))


# A stretch of road, s0 to s1 metres from the south end, and everything beside it.
func _chunk(s0: float, s1: float) -> void:
	var node := Node3D.new()
	node.name = "road_%d" % int(s0)
	add_child(node)
	var i0 := int(s0 / STEP)
	var i1 := mini(int(s1 / STEP), pts.size() - 1)
	# across the road and out either side: the lateral stations and what each strip's made of
	var cols := [-160.0, -80.0, -42.0, -22.0, -12.0, -7.4, -SHOULDER, -HALF_ROAD, 0.0, HALF_ROAD, SHOULDER, 9.0, 16.0, 30.0, 60.0, 120.0]
	var strips := {}
	for key in ["road", "gravel", "bank", "shore"]:
		strips[key] = [PackedVector3Array(), PackedVector3Array()]
	for i in range(i0, i1):
		var j := i + 1
		var pi := pts[i]
		var pj := pts[j]
		var si := Vector3(-dirs[i].z, 0.0, dirs[i].x)
		var sj := Vector3(-dirs[j].z, 0.0, dirs[j].x)
		for c in cols.size() - 1:
			var ua: float = cols[c]
			var ub: float = cols[c + 1]
			var a := pi + si * ua
			a.y = profile(ua, pi.y)
			var b := pj + sj * ua
			b.y = profile(ua, pj.y)
			var cc := pj + sj * ub
			cc.y = profile(ub, pj.y)
			var d := pi + si * ub
			d.y = profile(ub, pi.y)
			var key := "road"
			if ua >= -HALF_ROAD and ub <= HALF_ROAD:
				key = "road"
			elif ua >= -SHOULDER and ub <= SHOULDER:
				key = "gravel"
			elif ub <= -SHOULDER:
				key = "bank"
			else:
				key = "shore"
			_quad(strips[key][0], strips[key][1], a, b, cc, d)
	_mesh(strips.road[0], strips.road[1], _mats.road, node)
	_mesh(strips.gravel[0], strips.gravel[1], _mats.gravel, node)
	_mesh(strips.bank[0], strips.bank[1], _mats.bank, node)
	_mesh(strips.shore[0], strips.shore[1], _mats.shore, node)
	# the lines: the yellow down the middle (dashed where he can pass, solid on the curves and the
	# hills), the white at the edges
	var lv := PackedVector3Array()
	var ln := PackedVector3Array()
	var yv := PackedVector3Array()
	var yn := PackedVector3Array()
	for i in range(i0, i1):
		var j := i + 1
		var pi := pts[i] + Vector3(0, 0.012, 0)
		var pj := pts[j] + Vector3(0, 0.012, 0)
		var si := Vector3(-dirs[i].z, 0.0, dirs[i].x)
		var sj := Vector3(-dirs[j].z, 0.0, dirs[j].x)
		for e: float in [-3.8, 3.8]:
			var w := 0.1
			var a := pi + si * (e - w)
			var b := pj + sj * (e - w)
			var c := pj + sj * (e + w)
			var d := pi + si * (e + w)
			a.y = pi.y - 0.016 * absf(e)
			b.y = pj.y - 0.016 * absf(e)
			c.y = pj.y - 0.016 * absf(e)
			d.y = pi.y - 0.016 * absf(e)
			_quad(lv, ln, a, b, c, d)
		var curve := dirs[i].angle_to(dirs[mini(i + 6, pts.size() - 1)])
		var solid := curve > 0.12 or absf(pts[mini(i + 6, pts.size() - 1)].y - pts[i].y) > 0.9
		if solid or (int(dist[i] / STEP) % 3 == 0):
			for off in ([-0.12, 0.12] if solid else [0.0]):
				var w2 := 0.06
				_quad(yv, yn, pi + si * (off - w2), pj + sj * (off - w2), pj + sj * (off + w2), pi + si * (off + w2))
	_mesh(lv, ln, _mats.line, node)
	_mesh(yv, yn, _mats.yellow, node)
	_beside(node, i0, i1)


# What's beside the road on a chunk: trees up the bank, power poles, the guardrail, kilometre posts,
# the odd house with its mailbox.
func _beside(node: Node3D, i0: int, i1: int) -> void:
	var trees := MultiMesh.new()
	trees.transform_format = MultiMesh.TRANSFORM_3D
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 7
	cone.rings = 1
	trees.mesh = cone
	var xfs: Array = []
	var trunks: Array = []
	for i in range(i0, i1):
		var p := pts[i]
		var side := Vector3(-dirs[i].z, 0.0, dirs[i].x)
		var d := dist[i] - zero
		# trees: thick up the bank, a few on the shore side where it's low
		for k in 2:
			var u := -_rng.randf_range(11.0, 70.0)
			if _rng.randf() < 0.2:
				u = _rng.randf_range(14.0, 40.0)
				if p.y > 2.5:
					continue
			var at := p + side * u + dirs[i] * _rng.randf_range(-2.0, 2.0)
			at.y = profile(u, p.y)
			var h := _rng.randf_range(9.0, 22.0)
			# three tiers of a fir
			for tier in 3:
				var hh := h * (0.5 - 0.08 * tier)
				var r := h * 0.2 * (1.0 - 0.25 * tier)
				var y0 := h * (0.2 + 0.24 * tier)
				xfs.append(Transform3D(Basis.from_scale(Vector3(r, hh, r)), at + Vector3(0, y0 + hh / 2.0, 0)))
			trunks.append([at, h])
		var di := int(round(dist[i]))
		# power poles on the hill side, every 52 m
		if di % 52 < int(STEP):
			var at := p + side * -8.6
			at.y = profile(-8.6, p.y)
			_cyl(0.12, 0.15, 10.0, at + Vector3(0, 5.0, 0), _mats.pole, node)
			var arm := _box(Vector3(2.2, 0.12, 0.12), at + Vector3(0, 9.4, 0), _mats.pole, node)
			arm.look_at_from_position(arm.position, arm.position + side, Vector3.UP)
			arm.rotate_object_local(Vector3.UP, PI / 2.0)
			add_wall(Vector2(at.x, at.z), Vector2(0.16, 0.16), 0.0, 10.0)
		# the guardrail where the road's up over the water
		if p.y > 2.5 and i + 1 < pts.size():
			var a := p + side * 6.1
			a.y = profile(6.1, p.y) + 0.55
			var b := pts[i + 1] + Vector3(-dirs[i + 1].z, 0.0, dirs[i + 1].x) * 6.1
			b.y = profile(6.1, pts[i + 1].y) + 0.55
			var mid := (a + b) / 2.0
			var rail := _box(Vector3(0.06, 0.3, a.distance_to(b) + 0.05), mid, _mats.rail, node)
			rail.look_at_from_position(mid, b, Vector3.UP)
			_box(Vector3(0.16, 0.8, 0.16), a + Vector3(0, -0.25, 0), _mats.post, node)
			add_wall(Vector2(mid.x, mid.z), Vector2(0.15, STEP / 2.0 + 0.1), atan2(-(b.x - a.x), (b.z - a.z)), p.y + 0.9)
		# a kilometre post every 250 m (a kilometre, at the island's scale), on the shore side
		if di % 250 < int(STEP):
			var at := p + side * 6.6
			at.y = profile(6.6, p.y)
			_box(Vector3(0.1, 1.2, 0.1), at + Vector3(0, 0.6, 0), _mats.post, node)
			var plate := _box(Vector3(0.36, 0.5, 0.04), at + Vector3(0, 1.35, 0), _mats.sign_g, node)
			plate.look_at_from_position(plate.position, plate.position - dirs[i], Vector3.UP)
			var km := int(round(absf(d) / 250.0))
			var lab := _label(str(km), plate.position, 0.0026, Color("e8e8e0"), node)
			lab.look_at_from_position(plate.position - dirs[i] * 0.03, plate.position - dirs[i] * 2.0, Vector3.UP)
			lab.rotate_object_local(Vector3.UP, PI)
		# a house back off the hill side now and then, with its mailbox at the road
		if di % 190 < int(STEP) and absf(d) > 150.0 and p.y < 9.0:
			_house(node, p, side, dirs[i], -_rng.randf_range(24.0, 34.0))
	trees.instance_count = xfs.size()
	for k in xfs.size():
		trees.set_instance_transform(k, xfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = trees
	mmi.material_override = _mats.conifer
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 700.0
	node.add_child(mmi)
	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.14
	cyl.bottom_radius = 0.2
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	trunk_mm.mesh = cyl
	trunk_mm.instance_count = trunks.size()
	for k in trunks.size():
		var at: Vector3 = trunks[k][0]
		var h: float = trunks[k][1]
		trunk_mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(1, h * 0.3, 1)), at + Vector3(0, h * 0.15, 0)))
		if absf(along(at)[1]) < 30.0:
			add_wall(Vector2(at.x, at.z), Vector2(0.25, 0.25), 0.0, h)
	var tmi := MultiMeshInstance3D.new()
	tmi.multimesh = trunk_mm
	tmi.material_override = _mats.bark
	tmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tmi.visibility_range_end = 500.0
	node.add_child(tmi)


func _house(node: Node3D, p: Vector3, side: Vector3, dir: Vector3, u: float) -> void:
	var at := p + side * u
	at.y = profile(u, p.y)
	var h := Node3D.new()
	h.position = at
	node.add_child(h)
	h.look_at(at - side * 10.0, Vector3.UP)
	var w := _rng.randf_range(7.0, 10.0)
	var dpt := _rng.randf_range(7.0, 9.0)
	var wall_m: Material = (_mats.clap as Array)[_rng.randi() % (_mats.clap as Array).size()] if _mats.clap is Array else _mats.clap
	_box(Vector3(w, 3.0, dpt), Vector3(0, 1.4, 0), wall_m, h)
	var roof := _box(Vector3(w + 0.6, 0.25, dpt * 0.62), Vector3(0, 3.5, -dpt * 0.24), _mats.roof, h)
	roof.rotation.x = deg_to_rad(28.0)
	var roof2 := _box(Vector3(w + 0.6, 0.25, dpt * 0.62), Vector3(0, 3.5, dpt * 0.24), _mats.roof, h)
	roof2.rotation.x = deg_to_rad(-28.0)
	# a window lit, or the blue of a television, or nothing: most people are asleep
	var r := _rng.randf()
	if r < 0.55:
		_box(Vector3(1.1, 0.9, 0.05), Vector3(_rng.randf_range(-w / 3.0, w / 3.0), 1.6, -dpt / 2.0 - 0.02), _mats.window if r < 0.4 else _mats.window_tv, h)
	add_wall(Vector2(at.x, at.z), Vector2(w / 2.0, dpt / 2.0), -h.rotation.y, 4.0)
	# the mailbox at the road
	var mb := p + side * -6.3
	mb.y = profile(-6.3, p.y)
	_box(Vector3(0.08, 1.05, 0.08), mb + Vector3(0, 0.52, 0), _mats.post, node)
	var box := _box(Vector3(0.22, 0.22, 0.46), mb + Vector3(0, 1.15, 0), _mats.dark, node)
	box.look_at_from_position(box.position, box.position + dir, Vector3.UP)
	add_wall(Vector2(mb.x, mb.z), Vector2(0.12, 0.12), 0.0, 1.3)


# ---------------------------------------------------------------- the places along it

func _post_sign(d: float, u: float, lines: Array, m: Material, size := Vector2(2.4, 1.2), face_south := false) -> Node3D:
	var a := at_dist(d)
	var p: Vector3 = a[0]
	var dir: Vector3 = a[1]
	var side := Vector3(-dir.z, 0.0, dir.x)
	var at := p + side * u
	at.y = profile(u, p.y)
	var n := Node3D.new()
	n.position = at
	add_child(n)
	var face := dir if face_south else -dir
	n.look_at(at - face, Vector3.UP)     # its front toward who's coming
	for sx in [-size.x * 0.35, size.x * 0.35]:
		_box(Vector3(0.1, 2.2, 0.1), Vector3(sx, 1.1, 0), _mats.post, n)
	_box(Vector3(size.x, size.y, 0.06), Vector3(0, 2.2 + size.y / 2.0, 0), m, n)
	var y := 2.2 + size.y - 0.3
	for l in lines:
		var lab := _label(str(l), Vector3(0, y, 0.05), 0.0045, Color("eceae0"), n)
		lab.rotation.y = PI
		y -= 0.34
	add_wall(Vector2(at.x, at.z), Vector2(size.x / 2.0, 0.15), -n.rotation.y, 3.0)
	return n


func _places() -> void:
	# going north
	_post_sign(140.0, 6.8, ["UP ISLAND", "Mill Road  2", "Campbell Narrows  61"], _mats.sign_g, Vector2(2.6, 1.3))
	_motel(MOTEL)
	_post_sign(FISH_PLANT - 60.0, -7.4, ["COASTAL PRODUCTS", "NO TRESPASSING"], _mats.white, Vector2(2.4, 0.9))
	_plant(FISH_PLANT)
	_post_sign(MILL_ROAD - 90.0, 6.8, ["MILL ROAD", "TRUCKS ENTERING"], _mats.sign_y, Vector2(2.2, 1.0))
	_mill(MILL_ROAD)
	_barricade(WASHOUT, ["ROAD CLOSED", "WASHOUT"])
	# going south
	_post_sign(-140.0, -6.8, ["FERRY TERMINAL  22", "Port Albion  38"], _mats.sign_g, Vector2(2.6, 1.0), true)
	_church(CHURCH)
	_fruit(FRUIT)
	_post_sign(FERRY_SIGN, -6.8, ["FERRY", "NEXT SAILING", "SEE BOARD"], _mats.sign_g, Vector2(2.2, 1.2), true)
	_barricade(BRIDGE_OUT, ["BRIDGE OUT", "DETOUR"], true)


func _motel(d: float) -> void:
	var a := at_dist(d)
	var p: Vector3 = a[0]
	var dir: Vector3 = a[1]
	var side := Vector3(-dir.z, 0.0, dir.x)
	var at := p + side * -22.0
	at.y = profile(-9.0, p.y) + 0.2
	var n := Node3D.new()
	n.position = at
	add_child(n)
	n.look_at(at - side, Vector3.UP)
	# a long low block of rooms, its doors to the road, two lit
	_box(Vector3(30.0, 3.0, 8.0), Vector3(0, 1.5, 0), (_mats.clap as Array)[1] if _mats.clap is Array else _mats.clap, n)
	_box(Vector3(31.0, 0.3, 9.0), Vector3(0, 3.1, 0), _mats.roof, n)
	for k in 8:
		var x := -12.6 + k * 3.6
		_box(Vector3(0.9, 2.0, 0.05), Vector3(x, 1.0, 4.03), _mats.dark, n)
		_box(Vector3(1.2, 0.8, 0.05), Vector3(x + 1.4, 1.6, 4.03), _mats.window if k in [2, 6] else _mats.dark, n)
	add_wall(Vector2(at.x, at.z), Vector2(15.0, 4.0), -n.rotation.y, 3.0)
	# the sign on its pole at the road: SEA BREEZE MOTEL, VACANCY with the A out
	var s := _post_sign(d - 30.0, -7.0, [], _mats.dark, Vector2(3.0, 1.6))
	var lab := _label("SEA BREEZE", Vector3(0, 3.55, 0.06), 0.006, Color("ff6a5a"), s)
	lab.rotation.y = PI
	lab = _label("MOTEL", Vector3(0, 3.1, 0.06), 0.006, Color("ff6a5a"), s)
	lab.rotation.y = PI
	lab = _label("V CANCY", Vector3(0, 2.55, 0.06), 0.005, Color("ff2a2a"), s)
	lab.rotation.y = PI
	var l := OmniLight3D.new()
	l.position = Vector3(0, 3.0, 1.2)
	l.light_color = Color("ff5040")
	l.light_energy = 1.6
	l.omni_range = 9.0
	s.add_child(l)
	lamps.append([l, 1.6])


func _plant(d: float) -> void:
	var a := at_dist(d)
	var p: Vector3 = a[0]
	var dir: Vector3 = a[1]
	var side := Vector3(-dir.z, 0.0, dir.x)
	var at := p + side * 26.0
	at.y = 0.2
	var n := Node3D.new()
	n.position = at
	add_child(n)
	n.look_at(at + side, Vector3.UP)
	# the plant on the water: a long shed of corrugated tin, its loading doors shut, one sodium lamp
	_box(Vector3(40.0, 8.0, 16.0), Vector3(0, 4.0, 0), _mats.rail, n)
	_box(Vector3(41.0, 0.4, 17.0), Vector3(0, 8.2, 0), _mats.roof, n)
	for k in 4:
		_box(Vector3(4.0, 4.5, 0.08), Vector3(-15.0 + k * 10.0, 2.25, -8.03), _mats.dark, n)
	var lab := _label("COASTAL PRODUCTS LTD.", Vector3(0, 6.6, -8.1), 0.012, Color("d8d4c8"), n)
	lab.rotation.y = 0.0
	_cyl(0.1, 0.12, 7.0, Vector3(22.0, 3.5, -10.0), _mats.pole, n)
	_box(Vector3(0.6, 0.12, 0.3), Vector3(22.0, 7.0, -10.4), _mats.sodium, n)
	var l := OmniLight3D.new()
	l.position = Vector3(22.0, 6.6, -11.0)
	l.light_color = Color("ffb05a")
	l.light_energy = 2.2
	l.omni_range = 22.0
	n.add_child(l)
	add_wall(Vector2(at.x, at.z), Vector2(20.0, 8.0), -n.rotation.y, 8.0)


func _mill(d: float) -> void:
	var a := at_dist(d)
	var p: Vector3 = a[0]
	var dir: Vector3 = a[1]
	var side := Vector3(-dir.z, 0.0, dir.x)
	var at := p + side * -18.0
	at.y = profile(-9.0, p.y)
	var n := Node3D.new()
	n.position = at
	add_child(n)
	n.look_at(at - side, Vector3.UP)
	# the gate on the mill road, the guard's shack lit, the stacks far back with their red lights
	_box(Vector3(2.4, 2.6, 2.4), Vector3(5.0, 1.3, 0), (_mats.clap as Array)[0] if _mats.clap is Array else _mats.clap, n)
	_box(Vector3(1.2, 0.8, 0.05), Vector3(5.0, 1.6, 1.23), _mats.window, n)
	_box(Vector3(9.0, 0.12, 0.12), Vector3(-1.0, 1.0, 1.5), _mats.sign_y, n)
	var lab := _label("HAMMOND CEDAR  -  ALL VISITORS REPORT", Vector3(5.0, 2.95, 1.25), 0.004, Color("e0dccc"), n)
	lab.rotation.y = 0.0
	for k in 2:
		_cyl(1.2, 1.6, 40.0, Vector3(-20.0 + k * 14.0, 20.0, -90.0), _mats.dark, n)
		_box(Vector3(0.6, 0.6, 0.6), Vector3(-20.0 + k * 14.0, 40.4, -90.0), _mats.neon_r, n)
	var l := OmniLight3D.new()
	l.position = Vector3(5.0, 2.0, 3.0)
	l.light_color = Color("ffd8a0")
	l.light_energy = 1.2
	l.omni_range = 10.0
	n.add_child(l)
	lamps.append([l, 1.2])
	add_wall(Vector2(at.x, at.z) + Vector2(side.x, side.z) * -5.0, Vector2(1.3, 1.3), -n.rotation.y, 3.0)


func _church(d: float) -> void:
	var a := at_dist(d)
	var p: Vector3 = a[0]
	var dir: Vector3 = a[1]
	var side := Vector3(-dir.z, 0.0, dir.x)
	var at := p + side * -26.0
	at.y = profile(-9.0, p.y)
	var n := Node3D.new()
	n.position = at
	add_child(n)
	n.look_at(at - side, Vector3.UP)
	_box(Vector3(9.0, 6.0, 16.0), Vector3(0, 3.0, 0), _mats.white, n)
	var r1 := _box(Vector3(10.0, 0.3, 6.0), Vector3(-2.4, 7.2, 0), _mats.roof, n)
	r1.rotation.z = deg_to_rad(-40.0)
	var r2 := _box(Vector3(10.0, 0.3, 6.0), Vector3(2.4, 7.2, 0), _mats.roof, n)
	r2.rotation.z = deg_to_rad(40.0)
	_box(Vector3(2.4, 9.0, 2.4), Vector3(0, 4.5, 8.6), _mats.white, n)
	_cyl(0.0, 1.5, 5.0, Vector3(0, 11.5, 8.6), _mats.roof, n, 4)
	add_wall(Vector2(at.x, at.z), Vector2(5.0, 9.0), -n.rotation.y, 6.0)
	# the reader board at the road
	var s := _post_sign(d + 24.0, -7.2, [], _mats.white, Vector2(2.6, 1.1), true)
	for k in 3:
		var txt: String = ["ST. ANDREW'S BY THE SEA", "WHAT IS MISSING", "FROM CH  CH?  U R"][k]
		var lab := _label(txt, Vector3(0, 3.05 - k * 0.32, 0.06), 0.0038, Color("1a1a1a"), s)
		lab.rotation.y = PI


func _fruit(d: float) -> void:
	var a := at_dist(d)
	var p: Vector3 = a[0]
	var dir: Vector3 = a[1]
	var side := Vector3(-dir.z, 0.0, dir.x)
	var at := p + side * 9.5
	at.y = profile(9.5, p.y)
	var n := Node3D.new()
	n.position = at
	add_child(n)
	n.look_at(at + side, Vector3.UP)
	_box(Vector3(5.0, 2.4, 2.4), Vector3(0, 1.2, 0), _mats.post, n)
	_box(Vector3(5.6, 0.15, 3.2), Vector3(0, 2.5, -0.3), _mats.roof, n)
	var lab := _label("FRESH FRUIT  CLOSED FOR SEASON", Vector3(0, 1.8, -1.25), 0.0045, Color("d8d0b8"), n)
	lab.rotation.y = PI
	add_wall(Vector2(at.x, at.z), Vector2(2.6, 1.3), -n.rotation.y, 2.5)


# where the slice of the road ends, honestly: a barricade across both lanes with its lamps going
func _barricade(d: float, words: Array, face_south := false) -> void:
	var a := at_dist(d)
	var p: Vector3 = a[0]
	var dir: Vector3 = a[1]
	var n := Node3D.new()
	n.position = p
	add_child(n)
	n.look_at(p + (dir if face_south else -dir), Vector3.UP)
	for k in 3:
		var x := -4.0 + k * 4.0
		_box(Vector3(3.2, 0.3, 0.06), Vector3(x, 1.0, 0), _mats.sign_y, n)
		_box(Vector3(3.2, 0.3, 0.06), Vector3(x, 0.5, 0), _mats.white, n)
		for sx in [-1.4, 1.4]:
			_box(Vector3(0.08, 1.2, 0.5), Vector3(x + sx, 0.6, 0), _mats.dark, n)
		var lamp := _box(Vector3(0.18, 0.18, 0.1), Vector3(x, 1.3, 0), _mats.amber, n)
		lamps.append([lamp, -1.0])
	var y := 2.6
	for w in words:
		var lab := _label(str(w), Vector3(0, y, -0.1), 0.007, Color("f0c040"), n)
		lab.rotation.y = PI
		y -= 0.42
	_box(Vector3(2.4, 1.0, 0.06), Vector3(0, 2.4, 0), _mats.dark, n)
	_box(Vector3(0.1, 2.0, 0.1), Vector3(0, 1.0, 0.1), _mats.post, n)


# the water along the island's shore, north and south past the Sov's
func _water() -> void:
	for seg in [[-2600.0, -400.0], [400.0, 2900.0]]:
		var w := float(seg[1]) - float(seg[0])
		var mi := _box(Vector3(w, 0.02, 1400.0), Vector3((float(seg[0]) + float(seg[1])) / 2.0, -0.42, 760.0), _mats.water, self)
		mi.visibility_range_end = 0.0
	# far hills to the west behind the trees, so the bank's never the edge of the world
	var r := RandomNumberGenerator.new()
	r.seed = 61
	var x := -2600.0
	while x < 2900.0:
		var w := r.randf_range(200.0, 420.0)
		var hh := r.randf_range(40.0, 110.0)
		var a := along(Vector3(x, 0, 0))
		var z := -260.0 - r.randf_range(0.0, 120.0)
		if not in_sov(x):
			var b := _box(Vector3(w, hh, 80.0), Vector3(x, -2.0 + hh / 2.0, z), _mats.bank, self)
			b.rotation.y = deg_to_rad(r.randf_range(-8.0, 8.0))
			b.visibility_range_end = 0.0
		x += w * 0.75


# ---------------------------------------------------------------- shapes

func _box(size: Vector3, pos: Vector3, m: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.visibility_range_end = 600.0
	parent.add_child(mi)
	return mi


func _cyl(rt: float, rb: float, h: float, pos: Vector3, m: Material, parent: Node3D, seg := 8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rt
	cm.bottom_radius = rb
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.visibility_range_end = 600.0
	parent.add_child(mi)
	return mi


func _label(text: String, pos: Vector3, px: float, col: Color, parent: Node3D) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = px
	l.font_size = 64
	l.modulate = col
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.position = pos
	l.visibility_range_end = 220.0
	parent.add_child(l)
	return l


# the lamps that flicker (the motel's neon), the barricades' that blink
func tick(t: float) -> void:
	for l in lamps:
		if float(l[1]) < 0.0:
			(l[0] as Node3D).visible = fmod(t, 1.1) < 0.55
		else:
			var e: float = l[1]
			(l[0] as OmniLight3D).light_energy = e * (0.85 + 0.1 * sin(t * 9.0) - (0.6 if fmod(t, 6.3) < 0.07 else 0.0))
