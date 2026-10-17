# Where a man can walk on the ground floor, and the way he'd go from one place to another: round the
# tables and the stools and whoever's standing about, not through them; straight across where it's
# clear; the corners taken in a curve, the way a man takes them, not on a point.
#
# The map is textures/walk_grid.png, made from the room by tests/walk_grid.gd: every ten
# centimetres, how far it is to the nearest thing a body would walk into, in centimetres. A cell is
# somewhere to walk for a body as wide as the distance there; the doorman needs more room than
# anyone else (BODY). Where there's room to spare a way keeps off things a little (it costs more to
# brush past them), the way people keep off a table's corner.
class_name Nav
extends RefCounted

const ORIGIN := Vector2(-6.0, -4.0)        # x, z of the corner of the first cell
const CELL := 0.1
const SIZE := Vector2i(300, 300)
const BODY := 0.26                         # how far the doorman's body comes out from where he stands
const SLIGHT := 0.2                        # anyone else's
const PERSON := 0.24                       # how much room a person standing takes up, about where they stand
const ROOMY := 0.5                         # past this from anything, a way doesn't care how close it goes
const EASE := 0.1                          # what a straight stretch keeps off things besides, where it can

static var _clear := PackedByteArray()     # centimetres to the nearest thing, by cell
var astar := AStarGrid2D.new()
var body := BODY
var _people: Array = []                    # cells made solid for the people in the way, to undo


static func load_map() -> void:
	if not _clear.is_empty():
		return
	var path := "res://textures/walk_grid.png"
	if not FileAccess.file_exists(path):
		push_warning("no walk map: " + path)
		_clear.resize(SIZE.x * SIZE.y)
		_clear.fill(100)
		return
	var img := Image.new()
	img.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	img.convert(Image.FORMAT_L8)
	_clear = img.get_data()


func _init(radius := BODY) -> void:
	load_map()
	body = radius
	astar.region = Rect2i(Vector2i.ZERO, SIZE)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	var need := roundi(body * 100.0)
	for j in SIZE.y:
		for i in SIZE.x:
			var c := int(_clear[j * SIZE.x + i])
			if c < need:
				astar.set_point_solid(Vector2i(i, j), true)
			elif c < ROOMY * 100.0:
				astar.set_point_weight_scale(Vector2i(i, j), 1.0 + (ROOMY * 100.0 - c) / 100.0 * 2.5)


# the middle of a cell, on the floor
static func world(c: Vector2i) -> Vector3:
	return Vector3(ORIGIN.x + (c.x + 0.5) * CELL, 0.0, ORIGIN.y + (c.y + 0.5) * CELL)


static func cell(p: Vector3) -> Vector2i:
	return Vector2i(floori((p.x - ORIGIN.x) / CELL), floori((p.z - ORIGIN.y) / CELL))


static func clearance(p: Vector3) -> float:
	load_map()
	var c := cell(p)
	if c.x < 0 or c.y < 0 or c.x >= SIZE.x or c.y >= SIZE.y:
		return 0.0
	return int(_clear[c.y * SIZE.x + c.x]) / 100.0


func open(c: Vector2i) -> bool:
	return astar.is_in_boundsv(c) and not astar.is_point_solid(c)


# The way from a to b on the floor (their heights are ignored): a list of points, a to b, each
# corner rounded. People standing in the way (their positions) are walked round. Where a or b
# isn't somewhere to walk (a seat, a stool), the way starts and ends at the nearest place that is,
# and goes the last step straight. Empty if there's no way at all.
func way(a: Vector3, b: Vector3, people: Array = []) -> PackedVector3Array:
	_block_people(people, [a, b])
	var ca := _nearest_open(cell(a))
	var cb := _nearest_open(cell(b))
	var out := PackedVector3Array()
	if ca.x >= 0 and cb.x >= 0:
		var ids := astar.get_id_path(ca, cb)
		if not ids.is_empty():
			var pts: Array = []
			pts.append(Vector3(a.x, 0.0, a.z))
			for c in ids:
				pts.append(world(c))
			pts.append(Vector3(b.x, 0.0, b.z))
			out = _round(_pull(pts))
	_unblock_people()
	return out


# the people in the way as solid, but not the ones at either end of it (he's going to them, or
# coming from beside them)
func _block_people(people: Array, ends: Array) -> void:
	_people.clear()
	var r := body + PERSON
	var n := ceili(r / CELL)
	for p in people:
		var pp: Vector3 = p
		var near_end := false
		for e in ends:
			if Vector2(pp.x - e.x, pp.z - e.z).length() < r + 0.15:
				near_end = true
		if near_end:
			continue
		var c := cell(pp)
		for dj in range(-n, n + 1):
			for di in range(-n, n + 1):
				var k := c + Vector2i(di, dj)
				if not open(k):
					continue
				if Vector2(world(k).x - pp.x, world(k).z - pp.z).length() <= r:
					astar.set_point_solid(k, true)
					_people.append(k)


func _unblock_people() -> void:
	for k in _people:
		astar.set_point_solid(k, false)
	_people.clear()


# the nearest cell to c he can stand in, within a metre and a half; (-1, -1) if none
func _nearest_open(c: Vector2i) -> Vector2i:
	if open(c):
		return c
	for r in range(1, 16):
		var best := Vector2i(-1, -1)
		var bd := INF
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				if maxi(absi(di), absi(dj)) != r:
					continue
				var k := c + Vector2i(di, dj)
				if open(k):
					var d := Vector2(di, dj).length()
					if d < bd:
						bd = d
						best = k
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)


# whether a straight line from a to b stays where he can walk (its ends needn't: a seat, a stool);
# eased, with room to spare (EASE) besides
func clear_line(a: Vector3, b: Vector3, eased := false) -> bool:
	var need := roundi((body + (EASE if eased else 0.0)) * 100.0)
	var d := Vector2(b.x - a.x, b.z - a.z)
	var n := maxi(1, ceili(d.length() / (CELL * 0.5)))
	var start_ok := open(cell(a))
	var end_ok := open(cell(b))
	for k in range(0, n + 1):
		var t := float(k) / n
		var c := cell(a.lerp(b, t))
		if _roomy(c, need):
			continue
		# a stretch at either end that isn't somewhere to walk, where the end itself isn't: the step
		# off the stool, the step onto it
		if (not start_ok and t < 0.5 and _all_shut(a, a.lerp(b, t))) or (not end_ok and t > 0.5 and _all_shut(a.lerp(b, t), b)):
			continue
		return false
	return true


func _roomy(c: Vector2i, need: int) -> bool:
	return open(c) and int(_clear[c.y * SIZE.x + c.x]) >= need


func _all_shut(a: Vector3, b: Vector3) -> bool:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var n := maxi(1, ceili(d.length() / (CELL * 0.5)))
	for k in range(0, n + 1):
		if open(cell(a.lerp(b, float(k) / n))):
			return false
	return true


# the corners that aren't needed taken out: from each point, straight on to the furthest one ahead
# it can see with room to spare, as a string pulled tight (past one it can't see, a few more are
# tried: the cells' own steps can hide one that's in plain sight)
func _pull(pts: Array) -> Array:
	if pts.size() <= 2:
		return pts
	var out: Array = [pts[0]]
	var i := 0
	while i < pts.size() - 1:
		var best := i + 1
		var miss := 0
		var j := i + 2
		while j < pts.size() and miss < 8:
			if clear_line(pts[i], pts[j], true):
				best = j
				miss = 0
			else:
				miss += 1
			j += 1
		out.append(pts[best])
		i = best
	return out


# each corner taken in a curve: cut back along both legs as far as there's room, and a curve between
func _round(pts: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	if pts.is_empty():
		return out
	out.append(pts[0])
	for i in range(1, pts.size() - 1):
		var p0: Vector3 = out[out.size() - 1]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var cut := minf(0.9, minf(p0.distance_to(p1), p1.distance_to(p2)) * 0.45)
		var done := false
		while cut >= 0.08 and not done:
			var a := p1 + (p0 - p1).normalized() * cut
			var b := p1 + (p2 - p1).normalized() * cut
			var curve: Array = []
			var ok := true
			var segs := clampi(ceili(cut / 0.12), 3, 8)
			for k in range(0, segs + 1):
				var t := float(k) / segs
				var q := a.lerp(p1, t).lerp(p1.lerp(b, t), t)
				if k > 0 and not clear_line(curve[curve.size() - 1] if not curve.is_empty() else a, q):
					ok = false
					break
				curve.append(q)
			if ok:
				out.append_array(PackedVector3Array(curve))
				done = true
			else:
				cut *= 0.5
		if not done:
			out.append(p1)
	out.append(pts[pts.size() - 1])
	return out


static func length_of(path: PackedVector3Array) -> float:
	var l := 0.0
	for i in range(1, path.size()):
		l += path[i - 1].distance_to(path[i])
	return l


# Along a path: where you are s metres in, and which way it's going there.
static func at(path: PackedVector3Array, s: float) -> Array:
	if path.size() == 1:
		return [path[0], Vector3.FORWARD]
	var left := s
	for i in range(1, path.size()):
		var seg := path[i - 1].distance_to(path[i])
		if left <= seg or i == path.size() - 1:
			var t := clampf(left / maxf(seg, 0.0001), 0.0, 1.0)
			return [path[i - 1].lerp(path[i], t), (path[i] - path[i - 1]).normalized()]
		left -= seg
	return [path[path.size() - 1], Vector3.FORWARD]
