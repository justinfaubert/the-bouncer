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
# The top of the chain moves with the head. Below the nape it moves with the chest, since a braid
# lies on the back and doesn't swing round when she turns her head.

var sk: Skeleton3D
var bones: PackedInt32Array = []
var stiff := 0.04             # how hard it leans back toward its made shape, per substep, at the top
var keep := 0.965             # how much of its swing is left after each substep
var thick := 1.15             # drawn a little thicker than it was made: the head is bigger too
var _pts: PackedVector3Array = []    # where each bone starts, then the tip: skeleton space
var _old: PackedVector3Array = []
var _len: PackedFloat32Array = []
var _on_head: PackedVector3Array = []   # the made shape, as the head carries it
var _on_chest: PackedVector3Array = []  # and as the chest carries it
var _axis: PackedVector3Array = []      # each bone's way to the next, in its own rest
var _basis: Array[Basis] = []           # each bone's rest, unscaled
var _head_rest: Transform3D
var _chest_rest: Transform3D
var _chest := -1
var _caps: Array = []                   # [bone, to bone, radius at rest]: the body, as capsules
var _was_head := Transform3D()
var _was_chest := Transform3D()
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
	_chest = sk.find_bone("spine_03")
	_head_rest = _flat(sk.get_bone_global_rest(bones[0]))
	_chest_rest = _flat(sk.get_bone_global_rest(_chest))
	var at := PackedVector3Array()
	for b in bones:
		var r := sk.get_bone_global_rest(b)
		at.append(r.origin)
		_basis.append(r.basis.orthonormalized())
	var n := at.size()
	at.append(at[n - 1] + (at[n - 1] - at[n - 2]))
	for i in at.size():
		_on_head.append(_head_rest.affine_inverse() * at[i])
		_on_chest.append(_chest_rest.affine_inverse() * at[i])
	for i in n:
		_len.append(at[i].distance_to(at[i + 1]))
		_axis.append(_basis[i].inverse() * (at[i + 1] - at[i]).normalized())
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
		_caps.append([a, b, minf(r - 0.006, c[2])])


static func _flat(t: Transform3D) -> Transform3D:
	return Transform3D(t.basis.orthonormalized(), t.origin)


static func _near(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var ab := b - a
	return a + ab * clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)


func _head_now() -> Transform3D:
	return _flat(sk.get_bone_global_pose(bones[0]))


func _chest_now() -> Transform3D:
	return _flat(sk.get_bone_global_pose(_chest))


# where each point would be if the braid were stiff: the head's shape at the top, the chest's below
func _made(i: int, head: Transform3D, chest: Transform3D) -> Vector3:
	var w := smoothstep(0.0, 2.5, float(i))
	return (head * _on_head[i]).lerp(chest * _on_chest[i], w)


func _start(head: Transform3D, chest: Transform3D) -> void:
	_pts.resize(_on_head.size())
	for i in _pts.size():
		_pts[i] = _made(i, head, chest)
	_old = _pts.duplicate()
	_was_head = head
	_was_chest = chest
	_going = true


# hanging still: as if she'd been standing like this a while
func settle() -> void:
	if bones.size() < 2:
		return
	var head := _head_now()
	var chest := _chest_now()
	_start(head, chest)
	var caps := _bodies()
	for k in 60:
		_sub(head, chest, caps, 1.0 / 48.0, 0.8)
	_old = _pts.duplicate()
	_lay(head, chest)


# one held pose later: it swings toward where the body has gone, in a few small steps
func step(dt := 1.0 / 12.0, subs := 4) -> void:
	if bones.size() < 2:
		return
	if not _going:
		settle()
		return
	var head := _head_now()
	var chest := _chest_now()
	var caps := _bodies()
	for s in subs:
		var t := float(s + 1) / subs
		_sub(_was_head.interpolate_with(head, t), _was_chest.interpolate_with(chest, t), caps, dt / subs, keep)
	_was_head = head
	_was_chest = chest
	_lay(head, chest)


func _bodies() -> Array:
	var out := []
	for c in _caps:
		var ta := sk.get_bone_global_pose(c[0])
		var tb := sk.get_bone_global_pose(c[1])
		out.append([ta.origin, tb.origin, float(c[2]) * ta.basis.get_scale().x])
	return out


func _sub(head: Transform3D, chest: Transform3D, caps: Array, h: float, k: float) -> void:
	var g := sk.global_transform.basis.inverse() * Vector3(0.0, -9.8 * h * h, 0.0)
	var n := _pts.size()
	_pts[0] = head.origin
	_old[0] = head.origin
	for i in range(1, n):
		var p := _pts[i]
		var v := (p - _old[i]) * k
		_old[i] = p
		p += v + g
		p += (_made(i, head, chest) - p) * stiff * lerpf(1.0, 0.2, float(i) / (n - 1))
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
				var q := _near(p, c[0], c[1])
				var d := p - q
				var l := d.length()
				if l < c[2]:
					p = q + (d / l if l > 1e-6 else Vector3.BACK) * float(c[2])
			_pts[i] = p


# each bone turned to point where its stretch of the chain now runs
func _lay(head: Transform3D, chest: Transform3D) -> void:
	var by_head := head.basis * _head_rest.basis.inverse()
	var by_chest := chest.basis * _chest_rest.basis.inverse()
	for i in bones.size():
		var made: Basis = (by_head if i < 2 else by_chest) * _basis[i]
		var a := (made * _axis[i]).normalized()
		var d := (_pts[i + 1] - _pts[i]).normalized()
		var b := made
		if a.dot(d) > -0.999:
			b = Basis(Quaternion(a, d)) * made
		sk.set_bone_global_pose(bones[i], Transform3D(b.scaled(Vector3.ONE * thick), _pts[i]))
