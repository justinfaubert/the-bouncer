# The dice, worked out before anyone sees them (game/dice.gd plays them back): two cubes out of his
# hand onto a surface, off it, off whatever walls it has (the front wall behind the ledge, the
# cushions on the pool table), off the glasses standing on it and off each other, until both lie
# still. Plain rigid bodies, not the physics engine: a cube's corners against the surface and the
# walls; its corners, the middles of its edges and the middles of its faces against the other die
# and the glasses; impulses for the bounce and the friction. So the same throw comes down the same
# way every time, here and in the browser.
#
# Which number is on which face is settled afterwards (dice.gd): a cube turned any of its 24 ways
# is the same cube, so the faces are dealt to it so that the one it came to rest on shows the number
# the night already chose.
class_name DiceSim
extends RefCounted

const S := 0.019                      # a die's edge (game/dice.gd's SIZE)
const H := S * 0.5
const HZ := 240.0
const DT := 1.0 / HZ
const KEEP := 2                       # a frame kept every this many steps
const FPS := HZ / KEEP                # frames kept a second
const GRAV := Vector3(0.0, -9.81, 0.0)
const INV_I := 6.0 / (S * S)          # a solid cube of unit mass, about any axis through its middle
const SLOP := 0.0003
const MAX_T := 4.0
const ITER := 4
const NEAR := S * 0.87                # no corner of a die is further than this from its middle

# the surface they're thrown onto, and what it's made of
var floor_y := 0.0
var e_floor := 0.4                    # how much bounce it gives back
var mu_floor := 0.4                   # its grip
var drag := 2.0                       # how fast it takes the spin out of a die lying on it
# walls: [a point on it, the way it faces (into the play), how high it stands off the surface (0 all
# the way up), bounce]
var walls: Array = []
# glasses standing on it: [Vector2 where (x, z), radius, height of the rim]
var glasses: Array = []

# the two dice
var pos: Array = [Vector3.ZERO, Vector3.ZERO]
var vel: Array = [Vector3.ZERO, Vector3.ZERO]
var rot: Array = [Basis.IDENTITY, Basis.IDENTITY]
var spin: Array = [Vector3.ZERO, Vector3.ZERO]
var asleep: Array = [false, false]
var held: Array = [0.0, 0.0]          # how much longer each stays in his hand
var release: Array = [0.0, 0.0]       # when each left it
var _still: Array = [0.0, 0.0]
var _last_hit: Array = [-1.0, -1.0]
var _n := 0

# what came of it
var frames: Array = [[], []]          # per die, FPS a second: [position, Quaternion]
var hits: Array = []                  # [time, die, "floor" "wall" "die" "glass", speed]
var rest_t: Array = [-1.0, -1.0]      # when each one lay still
var t := 0.0
var done := false
var ok := false

# the contacts of one step, side by side
var _ca := PackedInt32Array()         # the die pushed along the normal
var _cb := PackedInt32Array()         # the die pushed against it, or -1 for the world
var _cn := PackedVector3Array()       # the normal
var _cra := PackedVector3Array()      # from each one's middle to the point
var _crb := PackedVector3Array()
var _ce := PackedFloat32Array()       # bounce
var _cmu := PackedFloat32Array()      # grip
var _cw := PackedStringArray()        # what it hit
var _cjn := PackedFloat32Array()      # the push so far
var _cjt := PackedVector3Array()      # the friction so far
var _cbias := PackedFloat32Array()    # the speed it should leave at

static var CORNERS: Array = []
static var POINTS: Array = []         # the corners, the middles of the edges, the middles of the faces


static func _make_points() -> void:
	if not POINTS.is_empty():
		return
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				CORNERS.append(Vector3(x, y, z) * H)
	POINTS.append_array(CORNERS)
	for a in 3:
		for s1 in [-1.0, 1.0]:
			for s2 in [-1.0, 1.0]:
				var v := Vector3.ZERO
				v[(a + 1) % 3] = s1 * H
				v[(a + 2) % 3] = s2 * H
				POINTS.append(v)
	for a in 3:
		for s in [-1.0, 1.0]:
			var v2 := Vector3.ZERO
			v2[a] = s * H
			POINTS.append(v2)


func _init() -> void:
	_make_points()


# Throw them: where each leaves his hand, how fast and which way, how it's turned and spinning,
# and how long after the first the second goes.
func throw(from: Array, v0: Array, r0: Array, w0: Array, after := 0.0) -> void:
	held = [0.0, after]
	release = [0.0, after]
	for k in 2:
		pos[k] = from[k]
		vel[k] = v0[k]
		rot[k] = r0[k]
		spin[k] = w0[k]
		# one still in his hand is out of it all, like one lying still, until it goes
		asleep[k] = held[k] > 0.0
		_still[k] = 0.0
		_last_hit[k] = -1.0
		rest_t[k] = -1.0
		frames[k] = [[pos[k], Quaternion(rot[k])]]
	hits = []
	t = 0.0
	_n = 0
	done = false
	ok = false


# Run it for so many steps, or until both lie still (done; ok if they did), or it's taken too long
# (done, not ok).
func run(steps: int = 1 << 30) -> void:
	while steps > 0 and not done:
		step()
		steps -= 1
		if asleep[0] and asleep[1] and held[1] <= 0.0:
			done = true
			ok = true
		elif t >= MAX_T:
			done = true


func step() -> void:
	for k in 2:
		if held[k] > 0.0 and t >= held[k]:
			held[k] = 0.0
			asleep[k] = false
		if not asleep[k]:
			vel[k] += GRAV * DT
			vel[k] *= 1.0 - 0.15 * DT
	_contacts()
	var m := _ca.size()
	for i in m:
		var vn := _rel(i).dot(_cn[i])
		_cbias[i] = -_ce[i] * vn if vn < -0.35 else 0.0
		if vn < -0.12:
			_heard(i, -vn)
		# knocked hard enough, a die lying still moves again
		if _cw[i] == "die" and vn < -0.05:
			for k in [_ca[i], _cb[i]]:
				if asleep[k]:
					asleep[k] = false
					_still[k] = 0.0
					rest_t[k] = -1.0
	for it in ITER:
		for i in m:
			_solve(i)
	for k in 2:
		if asleep[k]:
			continue
		pos[k] += vel[k] * DT
		var w: Vector3 = spin[k]
		var wl := w.length()
		if wl > 0.000001:
			rot[k] = (Basis(w / wl, wl * DT) * rot[k]).orthonormalized()
	_push_out()
	t += DT
	_n += 1
	_settle()
	if _n % KEEP == 0:
		for k in 2:
			frames[k].append([pos[k], Quaternion(rot[k])])


# ---------------------------------------------------------------- touching

func _add(a: int, b: int, p: Vector3, n: Vector3, e: float, mu: float, what: String) -> void:
	_ca.append(a)
	_cb.append(b)
	_cn.append(n)
	_cra.append(p - pos[a])
	_crb.append(p - pos[b] if b >= 0 else Vector3.ZERO)
	_ce.append(e)
	_cmu.append(mu)
	_cw.append(what)
	_cjn.append(0.0)
	_cjt.append(Vector3.ZERO)
	_cbias.append(0.0)


func _contacts() -> void:
	_ca.clear()
	_cb.clear()
	_cn.clear()
	_cra.clear()
	_crb.clear()
	_ce.clear()
	_cmu.clear()
	_cw.clear()
	_cjn.clear()
	_cjt.clear()
	_cbias.clear()
	for k in 2:
		if asleep[k]:
			continue
		var p0: Vector3 = pos[k]
		var r: Basis = rot[k]
		if p0.y < floor_y + NEAR:
			for c in CORNERS:
				var p: Vector3 = p0 + r * c
				if p.y < floor_y + SLOP:
					_add(k, -1, p, Vector3.UP, e_floor, mu_floor, "floor")
		for w in walls:
			var wp: Vector3 = w[0]
			var wn: Vector3 = w[1]
			var tall: float = w[2]
			if (p0 - wp).dot(wn) > NEAR:
				continue
			for c in CORNERS:
				var p2: Vector3 = p0 + r * c
				if tall > 0.0 and p2.y > floor_y + tall:
					continue
				if (p2 - wp).dot(wn) < SLOP:
					_add(k, -1, p2, wn, w[3], 0.3, "wall")
		for g in glasses:
			var gc: Vector2 = g[0]
			var gr: float = g[1]
			if Vector2(p0.x, p0.z).distance_to(gc) > gr + NEAR or p0.y - NEAR > float(g[2]):
				continue
			for c2 in POINTS:
				var p3: Vector3 = p0 + r * c2
				if p3.y > float(g[2]):
					continue
				var q := Vector2(p3.x, p3.z) - gc
				var d := q.length()
				if d < gr + SLOP and d > 0.0001:
					_add(k, -1, p3, Vector3(q.x / d, 0.0, q.y / d), 0.5, 0.2, "glass")
	if not (asleep[0] and asleep[1]) and held[1] <= 0.0 and (pos[0] as Vector3).distance_to(pos[1]) < NEAR * 2.0:
		for a in 2:
			var b := 1 - a
			var inv: Basis = (rot[b] as Basis).transposed()
			var pa: Vector3 = pos[a]
			var ra: Basis = rot[a]
			var pb: Vector3 = pos[b]
			for c3 in POINTS:
				var p4: Vector3 = pa + ra * c3
				var q3: Vector3 = inv * (p4 - pb)
				var pen := _inside(q3)
				if pen.x < 0.0:
					continue
				var nl := Vector3.ZERO
				nl[int(pen.y)] = signf(q3[int(pen.y)])
				_add(a, b, p4, rot[b] * nl, 0.45, 0.3, "die")


# how far a point (in a die's own space) is inside it, and through which face: (depth, axis), or
# depth -1 when it's outside
static func _inside(q: Vector3) -> Vector2:
	var best := -1.0
	var axis := 0
	for i in 3:
		var d := H + SLOP - absf(q[i])
		if d <= 0.0:
			return Vector2(-1.0, 0.0)
		if best < 0.0 or d < best:
			best = d
			axis = i
	return Vector2(best, axis)


func _rel(i: int) -> Vector3:
	var a := _ca[i]
	var b := _cb[i]
	var v: Vector3 = vel[a] + (spin[a] as Vector3).cross(_cra[i])
	if b >= 0:
		v -= vel[b] + (spin[b] as Vector3).cross(_crb[i])
	return v


# a die lying still is part of the table until something knocks it
func _mass(i: int, n: Vector3) -> float:
	var k := 0.0
	var a := _ca[i]
	var b := _cb[i]
	if not asleep[a]:
		k += 1.0 + INV_I * _cra[i].cross(n).length_squared()
	if b >= 0 and not asleep[b]:
		k += 1.0 + INV_I * _crb[i].cross(n).length_squared()
	return maxf(k, 0.000001)


func _push(i: int, j: Vector3) -> void:
	var a := _ca[i]
	if not asleep[a]:
		vel[a] += j
		spin[a] += INV_I * _cra[i].cross(j)
	var b := _cb[i]
	if b >= 0 and not asleep[b]:
		vel[b] -= j
		spin[b] -= INV_I * _crb[i].cross(j)


func _solve(i: int) -> void:
	var n: Vector3 = _cn[i]
	var v := _rel(i)
	var vn := v.dot(n)
	var j0: float = _cjn[i]
	var jn := maxf(j0 + (_cbias[i] - vn) / _mass(i, n), 0.0)
	_cjn[i] = jn
	_push(i, n * (jn - j0))
	# friction, no more than the grip times how hard it's pressed
	v = _rel(i)
	var vt := v - n * v.dot(n)
	var vtl := vt.length()
	if vtl < 0.00001:
		return
	var td := vt / vtl
	var jt0: Vector3 = _cjt[i]
	var jt := jt0 - td * (vtl / _mass(i, td))
	var most := _cmu[i] * jn
	var jl := jt.length()
	if jl > most:
		jt = jt * (most / jl) if jl > 0.0 else Vector3.ZERO
	_cjt[i] = jt
	_push(i, jt - jt0)


# a knock loud enough to hear: one per die per moment, the hardest of the corners that made it
func _heard(i: int, speed: float) -> void:
	var a := _ca[i]
	if t - float(_last_hit[a]) < 0.035 and not hits.is_empty():
		for h in range(hits.size() - 1, -1, -1):
			if int(hits[h][1]) == a:
				hits[h][3] = maxf(float(hits[h][3]), speed)
				break
		return
	_last_hit[a] = t
	hits.append([t, a, _cw[i], speed])


# Out of whatever they've sunk into: up off the surface, off the walls, out of the glasses, apart.
func _push_out() -> void:
	for k in 2:
		if asleep[k]:
			continue
		var p0: Vector3 = pos[k]
		var r: Basis = rot[k]
		if p0.y < floor_y + NEAR:
			var low := INF
			for c in CORNERS:
				low = minf(low, (p0 + r * c).y)
			if low < floor_y:
				p0.y += floor_y - low
		for w in walls:
			var wp: Vector3 = w[0]
			var wn: Vector3 = w[1]
			var tall: float = w[2]
			if (p0 - wp).dot(wn) > NEAR:
				continue
			var most := 0.0
			for c in CORNERS:
				var p: Vector3 = p0 + r * c
				if tall > 0.0 and p.y > floor_y + tall:
					continue
				most = minf(most, (p - wp).dot(wn))
			if most < 0.0:
				p0 += wn * -most
		for g in glasses:
			var gc: Vector2 = g[0]
			var gr: float = g[1]
			if Vector2(p0.x, p0.z).distance_to(gc) > gr + NEAR:
				continue
			var most2 := 0.0
			var out := Vector3.ZERO
			for c2 in POINTS:
				var p2: Vector3 = p0 + r * c2
				if p2.y > float(g[2]):
					continue
				var q := Vector2(p2.x, p2.z) - gc
				var d := q.length()
				if d < gr and gr - d > most2 and d > 0.0001:
					most2 = gr - d
					out = Vector3(q.x / d, 0.0, q.y / d)
			p0 += out * most2
		pos[k] = p0
	if held[1] <= 0.0 and (pos[0] as Vector3).distance_to(pos[1]) < NEAR * 2.0:
		var deepest := 0.0
		var n := Vector3.ZERO
		for a in 2:
			var b := 1 - a
			var inv: Basis = (rot[b] as Basis).transposed()
			for c3 in POINTS:
				var q3: Vector3 = inv * (pos[a] + rot[a] * c3 - pos[b])
				var pen := _inside(q3)
				if pen.x - SLOP > deepest:
					deepest = pen.x - SLOP
					var nl := Vector3.ZERO
					nl[int(pen.y)] = signf(q3[int(pen.y)])
					n = rot[b] * nl * (1.0 if a == 0 else -1.0)
		if deepest > 0.0:
			# n pushes die 0 away from die 1
			if asleep[1]:
				pos[0] += n * deepest
			elif asleep[0]:
				pos[1] -= n * deepest
			else:
				pos[0] += n * deepest * 0.5
				pos[1] -= n * deepest * 0.5


# ---------------------------------------------------------------- lying still

func _settle() -> void:
	for k in 2:
		if asleep[k] or held[k] > 0.0:
			continue
		var p0: Vector3 = pos[k]
		var r: Basis = rot[k]
		var on := false
		if p0.y < floor_y + NEAR:
			for c in CORNERS:
				if (p0 + r * c).y < floor_y + SLOP * 2.0:
					on = true
					break
		if on:
			# the surface takes the spin out of it
			spin[k] *= exp(-drag * DT)
		if on and (vel[k] as Vector3).length() < 0.03 and (spin[k] as Vector3).length() < 0.9:
			_still[k] += DT
		else:
			_still[k] = 0.0
		if _still[k] < 0.1:
			continue
		var up := up_face(r)
		var lean: float = (r * up).dot(Vector3.UP)
		if lean > 0.9994 and absf(p0.y - (floor_y + H)) < 0.001:
			# square on a face: still
			rot[k] = (Basis(Quaternion(r * up, Vector3.UP)) * r).orthonormalized()
			pos[k].y = floor_y + H
			vel[k] = Vector3.ZERO
			spin[k] = Vector3.ZERO
			asleep[k] = true
			rest_t[k] = t
		elif _still[k] > 0.3:
			# balanced on an edge, which a real die doesn't stay: down it goes, onto the face it
			# leans toward
			var tip := ((r * up) as Vector3).cross(Vector3.UP)
			spin[k] += (tip.normalized() if tip.length() > 0.0001 else Vector3.RIGHT) * 2.5
			_still[k] = 0.0


# which of a die's faces (its own +x, -x, +y...) points most nearly up
static func up_face(r: Basis) -> Vector3:
	var best := -2.0
	var face := Vector3.UP
	for f in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
		var d: float = (r * f).dot(Vector3.UP)
		if d > best:
			best = d
			face = f
	return face


# the lowest of a die's corners, turned so and standing there
static func lowest(p: Vector3, r: Basis) -> float:
	var low := INF
	for c in CORNERS:
		low = minf(low, (p + r * c).y)
	return low
