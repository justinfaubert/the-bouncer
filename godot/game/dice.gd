# The dice, in the room. A check is two dice, and the night takes its time with them: they wait in
# his fist until the player picks them up (hold the mouse on the room, or space, to shake them; let
# go to throw), they go down on whatever's in front of him (the ledge by the door, the bar, table 28,
# the felt, the kitchen's steel, the floor at his feet), the first stops and the column says what
# the second needs, the second rolls on, and when it matters it rides up onto an edge and hangs
# there before it falls. Then the stamp. His eyes narrow on them while they're down, and his heart
# is up. A tap, space or enter while they're rolling skips to the stamp. How long they're shaken
# changes nothing: the dice were decided when the choice was made (prototype/web/src/ui/roll.js).
class_name Dice
extends Node

const SIZE := 0.019
const RATTLE := 0.45
const SPEAK := 1.3
const FULL := {"shake": 0.5, "d1": 0.72, "n1": 4, "d2": 1.38, "n2": 6, "per_t": 0.12, "needs": 0.14, "ring": 0.16, "stamp": 0.4, "after": 0.42}
const QUICK := {"shake": 0.15, "d1": 0.38, "n1": 3, "d2": 0.56, "n2": 3, "per_t": 0.0, "needs": 0.04, "ring": 0.06, "stamp": 0.15, "after": 0.16}
# which way each face points on the die (opposite faces make seven)
const NORMAL := {1: Vector3.UP, 6: Vector3.DOWN, 2: Vector3.RIGHT, 5: Vector3.LEFT, 3: Vector3.BACK, 4: Vector3.FORWARD}
# where they go down, from each post: the top of something in front of him. Anywhere else, the
# floor at his feet.
const TABLE := {
	"door": Vector3(1.38, 1.05, 9.7), "bar": Vector3(2.12, 1.12, 5.15), "t28": Vector3(9.25, 0.785, 7.55),
	"pool": Vector3(8.75, 0.805, 4.35), "kitchen": Vector3(2.35, 0.94, -2.0),
}

var main
var dice: Array = []            # the two die nodes
var state := ""                 # "", "hand", "shake", "roll", "done"
var item := {}
var card: CheckCard
var cb: Callable
var need := {}
var t := 0.0                    # time since the throw
var plans: Array = []           # per die: frames [{t, pos, basis}]
var beats: Array = []           # [time, Callable], in order
var shake_t := 0.0
var rattle_t := 0.0
var said := false
var _look_back := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func setup(m) -> void:
	main = m
	for k in 2:
		dice.append(_die())
	main.view.sheet.gui_input.connect(_on_sheet_input)


# a die: six faces, printed clean, ivory with the pips cut out of it
func _die() -> Node3D:
	var d := Node3D.new()
	d.visible = false
	main.pub.add_child(d)
	for v in NORMAL:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(SIZE, SIZE)
		mi.mesh = q
		var m: ShaderMaterial = main.pub.mat(Color(1, 1, 1), 0.35, 0.0, 5)
		var tx := _face_tex(v)
		m.set_shader_parameter("albedo_tex", tx)
		m.set_shader_parameter("emission_tex", tx)
		m.set_shader_parameter("emission", Color(1, 1, 1))
		m.set_shader_parameter("emission_energy", 0.22)
		mi.material_override = m
		var n: Vector3 = NORMAL[v]
		mi.position = n * SIZE / 2.0
		# the quad faces +z; turn it to face along n
		if n == Vector3.BACK:
			pass
		elif n == Vector3.FORWARD:
			mi.rotation.y = PI
		elif n == Vector3.RIGHT:
			mi.rotation.y = PI / 2.0
		elif n == Vector3.LEFT:
			mi.rotation.y = -PI / 2.0
		elif n == Vector3.UP:
			mi.rotation.x = -PI / 2.0
		else:
			mi.rotation.x = PI / 2.0
		d.add_child(mi)
	# the body inside, so an edge never shows daylight
	var core := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3.ONE * SIZE * 0.985
	core.mesh = b
	core.material_override = main.pub.mat(Color("e6dfcf"), 0.4, 0.0, 5)
	d.add_child(core)
	return d


static var _faces := {}


static func _face_tex(v: int) -> ImageTexture:
	if _faces.has(v):
		return _faces[v]
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color("ece5d4"))
	var pips := {1: [[10, 10]], 2: [[5.5, 5.5], [14.5, 14.5]], 3: [[5.5, 5.5], [10, 10], [14.5, 14.5]],
		4: [[5.5, 5.5], [14.5, 5.5], [5.5, 14.5], [14.5, 14.5]], 5: [[5.5, 5.5], [14.5, 5.5], [10, 10], [5.5, 14.5], [14.5, 14.5]],
		6: [[5.5, 5], [14.5, 5], [5.5, 10], [14.5, 10], [5.5, 15], [14.5, 15]]}
	var r := 1.9 * n / 20.0
	var ink := Color("1b2130") if v != 1 else Color("b3261e")
	for p in pips[v]:
		var c := Vector2(p[0], p[1]) * n / 20.0
		for y in range(int(c.y - r - 2), int(c.y + r + 2)):
			for x in range(int(c.x - r - 2), int(c.x + r + 2)):
				var dd := Vector2(x + 0.5, y + 0.5).distance_to(c)
				if dd <= r + 0.5 and x >= 0 and y >= 0 and x < n and y < n:
					var a := clampf(r + 0.5 - dd, 0.0, 1.0)
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(ink, a))
	# a thin dark edge round the face
	for i in n:
		for e in [0, 1, n - 2, n - 1]:
			img.set_pixel(i, e, Color("8d8676"))
			img.set_pixel(e, i, Color("8d8676"))
	img.generate_mipmaps()
	var tx := ImageTexture.create_from_image(img)
	_faces[v] = tx
	return tx


# ---------------------------------------------------------------- the throw

func play(it: Dictionary, c: CheckCard, _p: float, done: Callable) -> void:
	cancel()
	item = it
	card = c
	cb = done
	need = CheckCard.needs(it.roll)
	_rng.seed = hash(str(it.get("label", "")) + str(it.roll.d1) + str(it.roll.d2) + str(main.game.turn))
	said = false
	var mode := str(main.settings.get("dice", "full"))
	main.view.heart = 1.25 + 0.12 * mini(int(it.roll.get("tension", 0)), 4)
	if mode == "full":
		state = "hand"
		card.waiting_in_hand(true)
		main.audio.sfx("rattle", 0.35)
	else:
		_throw(mode == "quick", 0.0)


func wants_click() -> bool:
	return state in ["hand", "shake", "roll"]


func mouse(pressed: bool) -> void:
	if pressed and state == "hand":
		_grip()
	elif not pressed and state == "shake":
		_let_go()


func key(pressed: bool) -> bool:
	if state == "hand" and pressed:
		_grip()
		return true
	if state == "shake" and not pressed:
		_let_go()
		return true
	if state == "roll" and pressed:
		finish()
		return true
	return state != ""


func _on_sheet_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if state == "roll" and e.pressed:
			finish()
			main.view.sheet.accept_event()
			return
		mouse(e.pressed)


func _grip() -> void:
	state = "shake"
	shake_t = 0.0
	rattle_t = 0.0
	main.audio.sfx("rattle", 0.55)
	main.view.heart = 1.6 + 0.15 * mini(int(item.roll.get("tension", 0)), 4)


func _let_go() -> void:
	card.waiting_in_hand(false)
	_throw(false, shake_t)


func _throw(quick: bool, shook: float) -> void:
	var T: Dictionary = QUICK if quick else FULL
	var tension := mini(int(item.roll.get("tension", 0)), 4)
	var split: bool = need.n > 0 and need.n < 6
	var hang := split and not quick
	var shake: float = T.shake if shook <= 0.0 else (0.0 if shook > 0.25 else 0.12)
	if shook <= 0.0 or shake > 0.0:
		main.audio.sfx("rattle", 1.0)
	# where they go down, and where from: his right hand, low in his eyes
	var cam: Camera3D = main.view.cam
	var surface: Vector3 = TABLE.get(main.view.place, Vector3.INF)
	if surface == Vector3.INF:
		var fwd := -cam.global_transform.basis.z
		fwd.y = 0.0
		fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
		var feet: Vector3 = main.view.eye_pos + fwd * 0.75
		feet.y = main.view.eye_pos.y - Posts.STAND
		surface = feet
	var from := cam.global_transform * Vector3(0.14, -0.2, -0.32)
	var across: Vector3 = surface - main.view.eye_pos
	across.y = 0.0
	across = across.normalized() if across.length() > 0.01 else Vector3.FORWARD
	var side: Vector3 = across.cross(Vector3.UP).normalized()
	var rests := [surface + side * SIZE * 1.4 + Vector3(0, SIZE / 2.0, 0), surface - side * SIZE * 1.3 + across * SIZE * 0.8 + Vector3(0, SIZE / 2.0, 0)]
	var finals := [_final(int(item.roll.d1)), _final(int(item.roll.d2))]
	var d1: float = T.d1
	var d2: float = T.d2 + T.per_t * tension - (0.0 if hang or quick else 0.26)
	plans = []
	beats = []
	var end2: Basis = finals[1]
	var tail: Array = []
	if hang:
		# a face of the other outcome, beside the real one: it rides up onto the edge between them
		var want := not bool(item.success)
		var near: Array = []
		for f in range(1, 7):
			var nw: Vector3 = finals[1] * NORMAL[f]
			if absf(nw.y) < 0.5 and need.pass[f - 1] == want:
				near.append(f)
		if near.is_empty():
			for f in range(1, 7):
				if absf((finals[1] * NORMAL[f]).y) < 0.5:
					near.append(f)
					break
		var other: int = near[_rng.randi() % near.size()]
		var nw2: Vector3 = finals[1] * NORMAL[other]
		var axis := nw2.cross(Vector3.UP).normalized()
		var hold := 0.48 + 0.09 * tension
		var lift := SIZE * 0.21
		var r2: Vector3 = rests[1]
		var f1: Basis = finals[1]
		if _rng.randf() < 0.5:
			# it comes over the other face, rides up onto the edge, and hangs there
			end2 = Basis(axis, PI / 2.0) * f1
			tail = [[0.3, Basis(axis, PI / 4.0) * f1, lift], [hold * 0.35, Basis(axis, PI / 4.0 * 1.16) * f1, lift],
				[hold * 0.35, Basis(axis, PI / 4.0 * 0.9) * f1, lift], [hold * 0.3, Basis(axis, PI / 4.0 * 1.02) * f1, lift]]
		else:
			# it lands on the real face, rolls on up onto the edge, and hangs there
			tail = [[0.34, Basis(axis, PI / 4.0) * f1, lift], [hold * 0.35, Basis(axis, PI / 4.0 * 1.14) * f1, lift],
				[hold * 0.35, Basis(axis, PI / 4.0 * 0.9) * f1, lift], [hold * 0.3, Basis(axis, PI / 4.0 * 1.02) * f1, lift]]
		tail.append([0.2, finals[1], 0.0, "land"])
		tail.append([0.07, Basis(axis, -PI / 4.0 * 0.09) * finals[1], SIZE * 0.02])
		tail.append([0.09, finals[1], 0.0])
	plans.append(_path(from + side * 0.02, rests[0], finals[0], d1, int(T.n1), 0.16))
	plans.append(_path(from - side * 0.02, rests[1], end2, d2, int(T.n2) + (mini(tension, 3) if hang else 0), 0.2))
	var t2: float = plans[1][-1].t
	for f in tail:
		t2 += f[0]
		plans[1].append({"t": t2, "pos": rests[1] + Vector3(0, f[2], 0), "basis": f[1], "hit": f[3] if f.size() > 3 else "", "ease": true})
	# the beats: sounds at each contact, then the column
	for k in 2:
		var fr: Array = plans[k]
		var vol := 1.0
		for i in fr.size():
			var h: String = fr[i].get("hit", "")
			if h == "":
				continue
			var last: bool = i == fr.size() - 1 or h == "land"
			var v := vol
			beats.append([shake + fr[i].t, func(): main.audio.sfx("die_land" if last else "die_tick", 0.9 if last else v)])
			vol *= 0.8
	var land1: float = shake + plans[0][-1].t
	var land2: float = shake + plans[1][-1].t
	beats.append([land1 + T.needs, card.first_down])
	beats.append([land2 + T.ring, card.second_down])
	beats.append([land2 + T.stamp, _stamp])
	beats.append([land2 + T.stamp + T.after, _done])
	beats.sort_custom(func(a, b): return a[0] < b[0])
	for k in 2:
		for f in plans[k]:
			f.t += shake
		(dice[k] as Node3D).visible = false
	# his eyes go to where they're going down, and narrow on it
	_look_back = Vector2(main.view.want_yaw, main.view.want_pitch)
	main.view.look_at_point(surface + Vector3(0, 0.02, 0))
	var dist: float = main.view.eye_pos.distance_to(surface)
	main.view.focus_fov = clampf(rad_to_deg(2.0 * atan(0.17 / maxf(dist, 0.3))), 12.0, 45.0)
	t = 0.0
	state = "roll"


# the die's last turn: the face it shows on top, and a turn about the up for how it lies
func _final(v: int) -> Basis:
	var n: Vector3 = NORMAL[v]
	var align: Basis
	if n == Vector3.UP:
		align = Basis.IDENTITY
	elif n == Vector3.DOWN:
		align = Basis(Vector3.RIGHT, PI)
	else:
		align = Basis(Quaternion(n, Vector3.UP))
	return Basis(Vector3.UP, _rng.randf_range(0.0, TAU)) * align


# A tumble from the hand to where it stops: hops shorter each time, turning less each time, ending
# exactly on the turn it's meant to show.
func _path(from: Vector3, rest: Vector3, end: Basis, dur: float, hops: int, air: float) -> Array:
	var out: Array = []
	var axis0 := _rng.randf_range(0.0, TAU)
	var spin := _rng.randf_range(2.2, 3.4) * TAU
	var ground_from := Vector3(from.x, rest.y, from.z)
	var fracs: Array = []
	var total := 0.0
	var w := 1.0
	for i in hops + 1:
		fracs.append(w)
		total += w
		w *= 0.62
	var tt := 0.0
	var prev := from
	out.append({"t": 0.0, "pos": from, "basis": _turned(end, axis0, spin, 0.0), "hit": "", "air": 0.0})
	var along := 0.0
	for i in hops + 1:
		var seg: float = fracs[i] / total
		tt += dur * seg
		along += seg
		var k := clampf(0.55 + 0.45 * pow(along, 0.8), 0.0, 1.0) if i < hops else 1.0
		var p := ground_from.lerp(rest, k)
		var h := air * pow(0.5, i) if i > 0 else air * 0.6
		out.append({"t": tt, "pos": p, "basis": _turned(end, axis0 + i * 0.9, spin, tt / dur), "hit": "tick" if i < hops else "land", "air": h, "from": prev})
		prev = p
	out[-1].basis = end
	return out


func _turned(end: Basis, axis_a: float, spin: float, f: float) -> Basis:
	var left := spin * pow(1.0 - clampf(f, 0.0, 1.0), 1.7)
	var axis := Vector3(cos(axis_a), 0.0, sin(axis_a))
	return Basis(axis, left) * end


func _process(dt: float) -> void:
	if state == "shake":
		shake_t += dt
		rattle_t += dt
		if rattle_t >= RATTLE:
			rattle_t = 0.0
			main.audio.sfx("rattle", 0.45 + _rng.randf() * 0.35)
		if not said and shake_t >= SPEAK:
			said = true
			var w = main.game.murmur("shake")
			if w != null:
				card.said(w, main.column.size_px)
		return
	if state != "roll":
		return
	t += dt
	while not beats.is_empty() and beats[0][0] <= t:
		var b: Array = beats.pop_front()
		b[1].call()
		if state != "roll":
			return
	for k in 2:
		_pose_die(k)


func _pose_die(k: int) -> void:
	var fr: Array = plans[k]
	var d: Node3D = dice[k]
	if t < fr[0].t:
		d.visible = false
		return
	d.visible = true
	var i := 1
	while i < fr.size() and fr[i].t < t:
		i += 1
	if i >= fr.size():
		d.global_transform = Transform3D(fr[-1].basis, fr[-1].pos)
		return
	var a: Dictionary = fr[i - 1]
	var b: Dictionary = fr[i]
	var u := clampf((t - a.t) / maxf(b.t - a.t, 0.0001), 0.0, 1.0)
	var pos: Vector3
	if b.get("ease", false):
		var e := u * u * (3.0 - 2.0 * u)
		pos = a.pos.lerp(b.pos, e)
	else:
		pos = a.pos.lerp(b.pos, u) + Vector3.UP * 4.0 * float(b.get("air", 0.0)) * u * (1.0 - u)
	var q := Quaternion(a.basis.orthonormalized()).slerp(Quaternion(b.basis.orthonormalized()), u)
	d.global_transform = Transform3D(Basis(q), pos)


func _stamp() -> void:
	card.stamp()
	main.audio.sfx("stamp")
	main.view.heart = 0.0


# the stamp's down: back to the night
func _done() -> void:
	state = "done"
	_restore()
	var c := cb
	cb = Callable()
	if c.is_valid():
		c.call()


func _restore() -> void:
	main.view.heart = 0.0
	main.view.focus_fov = 0.0
	var back := _look_back
	get_tree().create_timer(0.9).timeout.connect(func():
		if state in ["", "done"] and back != Vector2.ZERO:
			main.view.want_yaw = back.x
			main.view.want_pitch = back.y)
	for d in dice:
		var node: Node3D = d
		var tw := node.create_tween()
		tw.tween_interval(2.5)
		tw.tween_callback(func(): if state in ["", "done"]: node.visible = false)


# space, enter or a tap: straight to the stamp
func finish() -> void:
	if state == "hand" or state == "shake":
		card.waiting_in_hand(false)
		_throw(true, 1.0)
	if state != "roll":
		return
	var end := 0.0
	for b in beats:
		end = maxf(end, b[0])
	t = end
	for k in 2:
		var fr: Array = plans[k]
		(dice[k] as Node3D).visible = true
		(dice[k] as Node3D).global_transform = Transform3D(fr[-1].basis, fr[-1].pos)
	beats.clear()
	card.first_down()
	card.stamp()
	main.audio.sfx("stamp")
	_done()


func cancel() -> void:
	if state == "":
		return
	state = ""
	beats.clear()
	for d in dice:
		(d as Node3D).visible = false
	main.view.heart = 0.0
	main.view.focus_fov = 0.0
