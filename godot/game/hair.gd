class_name HairChain
extends RefCounted
# Hair that hangs and swings on a chain of bones (PROPOSED): Amanda's braid, so far. Each held pose
# the chain falls under its own weight, keeps its length, leans a little back toward the shape it
# was made in, and lies on the body instead of passing through it. It's stepped once per held
# pose, so it swings on twos like everything else.
#
#   var braid := HairChain.new(skeleton, "braid_")
#   braid.step(1.0 / 12.0)    # after each pose is set (clip, proportions), before it's drawn
#   braid.settle()            # or hanging still, as if she'd been standing there a while
#
# The shape it leans back toward is carried by the body: the top by the head; below the nape by the
# chest, since a braid lies on the back and doesn't swing round when she turns her head; and below
# the waist by the hips, so when she leans it still lies on her skirt instead of standing off
# behind her.
#
# A wind can be given (skeleton space, m/s/s): it comes and goes in slow gusts, so the braid stirs
# even when she's standing still. Amanda's: a breeze nobody else in the room is in.

var sk: Skeleton3D
var bones: PackedInt32Array = []
var stiff := 0.04             # how hard it leans back toward its made shape, per substep, at the top
var keep := 0.965             # how much of its swing is left after each substep
var thick := 1.15             # drawn a little thicker than it was made: the head is bigger too
var wind := Vector3.ZERO      # a breeze on it, at its strongest; it gusts, a third of that to all of it
var _t := 0.0
var _pts: PackedVector3Array = []    # where each bone starts, then the tip: skeleton space
var _old: PackedVector3Array = []
var _len: PackedFloat32Array = []
var _by: PackedInt32Array = []          # what carries the made shape: the head, the chest, the hips
var _rest: Array[Transform3D] = []      # each of them at rest, unscaled
var _on: Array = []                     # the made shape as each of them carries it
var _w: Array = []                      # how much each point goes with each of them
var _axis: PackedVector3Array = []      # each bone's way to the next, in its own rest
var _basis: Array[Basis] = []           # each bone's rest, unscaled
var _caps: Array = []                   # the body, as capsules: [bone, a point, bone, a point, radius at each]
var _was: Array[Transform3D] = []
var _going := false


func _init(skeleton: Skeleton3D, prefix := "braid_") -> void:
	sk = skeleton
	var named := []
	for b in sk.get_bone_count():
		if sk.get_bone_name(b).begins_with(prefix):
			named.append(sk.get_bone_name(b))
	named.sort()
	for nm in named:
		bones.append(sk.find_bone(nm))
	if bones.size() < 2:
		return
	var at := PackedVector3Array()
	for b in bones:
		var r := sk.get_bone_global_rest(b)
		at.append(r.origin)
		_basis.append(r.basis.orthonormalized())
	var n := at.size()
	at.append(at[n - 1] + (at[n - 1] - at[n - 2]))
	for i in n:
		_len.append(at[i].distance_to(at[i + 1]))
		_axis.append(_basis[i].inverse() * (at[i + 1] - at[i]).normalized())
	# what carries it: the head at the top, the chest from the nape, the hips from the waist down
	var chest := sk.find_bone("spine_03")
	var hips := sk.find_bone("pelvis")
	chest = chest if chest >= 0 else bones[0]
	_by = PackedInt32Array([bones[0], chest, hips if hips >= 0 else chest])
	for c in _by:
		_rest.append(_flat(sk.get_bone_global_rest(c)))
	for c in _by.size():
		var on := PackedVector3Array()
		for i in at.size():
			on.append(_rest[c].affine_inverse() * at[i])
		_on.append(on)
	var chest_y := _rest[1].origin.y
	var hips_y := _rest[2].origin.y
	for i in at.size():
		var top := 1.0 - smoothstep(0.0, 2.5, float(i))
		var low := 0.0
		if chest_y > hips_y + 0.01:
			var t := clampf((chest_y - at[i].y) / (chest_y - hips_y), 0.0, 1.0)
			low = t * t * (3.0 - 2.0 * t)
		_w.append(Vector3(top, (1.0 - top) * (1.0 - low), (1.0 - top) * low))
	# the body it lies on: each capsule as wide as it can be without touching the made shape
	for c in [["pelvis", "spine_01", 1.0], ["spine_01", "spine_02", 1.0], ["spine_02", "spine_03", 1.0],
			["spine_03", "neck_01", 1.0], ["thigh_l", "thigh_r", 1.0], ["thigh_l", "calf_l", 0.085],
			["thigh_r", "calf_r", 0.085]]:
		var a := sk.find_bone(c[0])
		var b := sk.find_bone(c[1])
		if a < 0 or b < 0:
			continue
		var pa := sk.get_bone_global_rest(a).origin
		var pb := sk.get_bone_global_rest(b).origin
		var r := 1.0
		for i in range(1, at.size()):
			r = minf(r, _near(at[i], pa, pb).distance_to(at[i]))
		r = minf(r - 0.006, c[2])
		_caps.append([a, pa, b, pb, r, r])
	_below(at)


# and what it lay on below the waist as it was made, a skirt standing off her: a cone down from the
# hips to the knees that moves with the hips, as wide at each height as the made shape lets it be.
# Without it the braid hangs straight down from her back, inside the skirt, and seems to end at
# her waist
func _below(at: PackedVector3Array) -> void:
	var pv := sk.find_bone("pelvis")
	var knee := sk.find_bone("calf_l")
	if pv < 0 or knee < 0:
		return
	var top := sk.get_bone_global_rest(pv).origin
	var bottom := Vector3(top.x, sk.get_bone_global_rest(knee).origin.y, top.z)
	var span := top.y - bottom.y
	var room := []       # (how far down the cone, how wide it may be there), for each made point
	var under := false
	for i in range(1, at.size()):
		var t := (top.y - at[i].y) / span
		if t > 0.0 and t < 1.0:
			under = true
			room.append(Vector2(t, Vector2(at[i].x - top.x, at[i].z - top.z).length() - 0.006))
		else:
			room.append(Vector2(clampf(t, 0.0, 1.0), at[i].distance_to(top if t <= 0.0 else bottom) - 0.006))
	if not under:
		return
	# the widest straight cone under every point: through two of them, or as wide as the narrowest
	var r0 := INF
	for q in room:
		r0 = minf(r0, q.y)
	var slope := 0.0
	for i in room.size():
		for j in range(i + 1, room.size()):
			var a2: Vector2 = room[i]
			var b2: Vector2 = room[j]
			if absf(b2.x - a2.x) < 1e-4:
				continue
			var s := (b2.y - a2.y) / (b2.x - a2.x)
			var c0 := a2.y - s * a2.x
			var fits := true
			for q in room:
				fits = fits and c0 + s * q.x <= q.y + 1e-6
			if fits and c0 + s * 0.5 > r0 + slope * 0.5:
				r0 = c0
				slope = s
	if r0 > 0.0:
		_caps.append([pv, top, pv, bottom, r0, maxf(r0 + slope, 0.0)])


static func _flat(t: Transform3D) -> Transform3D:
	return Transform3D(t.basis.orthonormalized(), t.origin)


static func _near(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var ab := b - a
	return a + ab * clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)


# the head, the chest and the hips as they are now
func _now() -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for c in _by:
		out.append(_flat(sk.get_bone_global_pose(c)))
	return out


# where a point would be if the braid were stiff, carried by the head, the chest and the hips
func _made(i: int, by: Array[Transform3D]) -> Vector3:
	var w: Vector3 = _w[i]
	var at := Vector3.ZERO
	for c in by.size():
		at += (by[c] * (_on[c] as PackedVector3Array)[i]) * w[c]
	return at


func _start(by: Array[Transform3D]) -> void:
	_pts.resize(_w.size())
	for i in _pts.size():
		_pts[i] = _made(i, by)
	_old = _pts.duplicate()
	_was = by.duplicate()
	_going = true


# hanging still: as if she'd been standing like this a while
func settle() -> void:
	if bones.size() < 2:
		return
	var by := _now()
	_start(by)
	var caps := _bodies()
	for k in 60:
		_sub(by, caps, 1.0 / 48.0, 0.8, 0.6)
	_old = _pts.duplicate()
	_lay(by)


# one held pose later: it swings toward where the body has gone, in a few small steps
func step(dt := 1.0 / 12.0, subs := 4) -> void:
	if bones.size() < 2:
		return
	if not _going:
		settle()
		return
	var by := _now()
	var caps := _bodies()
	for s in subs:
		var t := float(s + 1) / subs
		var mid: Array[Transform3D] = []
		for c in by.size():
			mid.append(_was[c].interpolate_with(by[c], t))
		_sub(mid, caps, dt / subs, keep)
	_was = by
	_lay(by)


# the capsules where the body is now: each end carried by its bone from where it was at rest
func _bodies() -> Array:
	var out := []
	for c in _caps:
		var ra := sk.get_bone_global_rest(c[0])
		var ta := sk.get_bone_global_pose(c[0])
		var tb := sk.get_bone_global_pose(c[2]) * sk.get_bone_global_rest(c[2]).affine_inverse()
		var k := ta.basis.get_scale().x / ra.basis.get_scale().x
		out.append([(ta * ra.affine_inverse()) * (c[1] as Vector3), tb * (c[3] as Vector3), float(c[4]) * k, float(c[5]) * k])
	return out


func _sub(by: Array[Transform3D], caps: Array, h: float, k: float, gust := -1.0) -> void:
	var g := sk.global_transform.basis.inverse() * Vector3(0.0, -9.8 * h * h, 0.0)
	if wind != Vector3.ZERO:
		_t += h
		if gust < 0.0:
			gust = 0.66 + 0.34 * sin(_t * 0.83) * sin(_t * 0.31 + 1.7)
		g += wind * gust * h * h
	var n := _pts.size()
	_pts[0] = by[0].origin
	_old[0] = by[0].origin
	for i in range(1, n):
		var p := _pts[i]
		var v := (p - _old[i]) * k
		_old[i] = p
		p += v + g
		p += (_made(i, by) - p) * stiff * lerpf(1.0, 0.2, float(i) / (n - 1))
		_pts[i] = p
	for it in 4:
		# keep each length, from the top down, then off the body
		for i in n - 1:
			var d := _pts[i + 1] - _pts[i]
			var l := d.length()
			if l > 1e-6:
				_pts[i + 1] = _pts[i] + d * (_len[i] / l)
		for i in range(1, n):
			var p := _pts[i]
			for c in caps:
				var ab: Vector3 = c[1] - c[0]
				var t := clampf((p - c[0]).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
				var q: Vector3 = c[0] + ab * t
				var r := lerpf(c[2], c[3], t)
				var d := p - q
				var l := d.length()
				if l < r:
					# out the way it went in, or behind her (she faces +z)
					p = q + (d / l if l > 1e-6 else Vector3.FORWARD) * r
			_pts[i] = p


# each bone turned to point where its stretch of the chain now runs, twisted the way whatever
# carries most of it has turned
func _lay(by: Array[Transform3D]) -> void:
	var turned: Array[Basis] = []
	for c in by.size():
		turned.append(by[c].basis * _rest[c].basis.inverse())
	for i in bones.size():
		var w: Vector3 = _w[i]
		var made: Basis = turned[w.max_axis_index()] * _basis[i]
		var a := (made * _axis[i]).normalized()
		var d := (_pts[i + 1] - _pts[i]).normalized()
		var b := made
		if a.dot(d) > -0.999:
			b = Basis(Quaternion(a, d)) * made
		sk.set_bone_global_pose(bones[i], Transform3D(b.scaled(Vector3.ONE * thick), _pts[i]))
