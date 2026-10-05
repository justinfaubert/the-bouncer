# The dice, in the room. A check is two dice, and the night takes its time with them: they wait in
# his fist until the player picks them up (hold the mouse on the room, or space, to shake them; let
# go to throw), they go down on whatever's in front of him (the ledge by the door, the bar, table 28,
# the felt, the kitchen's steel, the floor at his feet) and knock about on it the way dice do: off
# the wall behind the ledge, the cushions, the glasses on table 28, each other (game/dice_sim.gd
# works each throw out before it's shown). The first stops and the column says what the second
# needs; the second rolls on, and when it matters, the last time it stands up on an edge the night
# slows down to watch it come down. Then the stamp. His eyes narrow on them while they're down, and
# his heart is up. A tap, space or enter while they're rolling skips to the stamp. How long they're
# shaken changes nothing: the dice were decided when the choice was made
# (prototype/web/src/ui/roll.js).
class_name Dice
extends Node

const SIZE := DiceSim.S
const RATTLE := 0.45
const SPEAK := 1.3
# the shake before they leave his hand, how much faster than life they run, and the column's beats
# after each one lies still
const FULL := {"shake": 0.5, "speed": 1.0, "needs": 0.14, "ring": 0.16, "stamp": 0.4, "after": 0.42}
const QUICK := {"shake": 0.15, "speed": 1.8, "needs": 0.04, "ring": 0.06, "stamp": 0.15, "after": 0.16}
# which way each face points on the die (opposite faces make seven)
const NORMAL := {1: Vector3.UP, 6: Vector3.DOWN, 2: Vector3.RIGHT, 5: Vector3.LEFT, 3: Vector3.BACK, 4: Vector3.FORWARD}
# Where they go down, from each post: the top of something in front of him (where they should end
# up), what it's made of, the stretch of it they can run on (a box, x0 x1 z0 z1, or a round top, its
# middle and radius), the walls round it [a point, the way it faces, how high it stands (0 all the
# way), bounce], the pockets they'd drop down, what's lying on it (the balls; the arms of whoever's
# on the stools either side of him), what hangs over it (so the throw goes in low, under it), and
# how far off the middle they can end up. Anywhere else, the floor at his feet.
const SPOTS := {
	"door": {"at": Vector3(1.47, 1.05, 9.76), "of": "wood", "box": [1.24, 1.74, 9.5, 10.0],
		"walls": [[Vector3(0, 0, 10.0), Vector3(0, 0, -1), 0.0, 0.35]]},
	"bar": {"at": Vector3(2.02, 1.12, 5.42), "of": "wood", "box": [1.6, 2.33, 4.9, 5.95],
		"lying": [[Vector2(2.2, 5.0), 0.2], [Vector2(2.2, 5.85), 0.2]]},
	"t28": {"at": Vector3(9.27, 0.78, 7.62), "of": "wood", "round": [Vector2(9.4, 8.1), 0.83],
		"lying": [[Vector2(8.77, 7.94), 0.2], [Vector2(9.85, 7.63), 0.2]]},
	"pool": {"at": Vector3(8.82, 0.8, 4.22), "of": "felt", "box": [8.4475, 10.3525, 3.4225, 4.3775],
		"walls": [[Vector3(8.4475, 0, 0), Vector3(1, 0, 0), 0.042, 0.6], [Vector3(10.3525, 0, 0), Vector3(-1, 0, 0), 0.042, 0.6],
			[Vector3(0, 0, 3.4225), Vector3(0, 0, 1), 0.042, 0.6], [Vector3(0, 0, 4.3775), Vector3(0, 0, -1), 0.042, 0.6]],
		"holes": [[Vector2(8.422, 3.397), 0.075], [Vector2(10.378, 3.397), 0.075], [Vector2(8.422, 4.403), 0.075],
			[Vector2(10.378, 4.403), 0.075], [Vector2(9.4, 3.383), 0.07], [Vector2(9.4, 4.417), 0.07]],
		"lying": [[Vector2(8.78, 3.62), 0.0286], [Vector2(8.95, 3.96), 0.0286], [Vector2(9.98, 3.52), 0.0286],
			[Vector2(9.61, 4.2), 0.0286], [Vector2(8.52, 4.06), 0.0286], [Vector2(10.17, 4.14), 0.0286], [Vector2(9.45, 3.78), 0.0286]]},
	"kitchen": {"at": Vector3(2.55, 0.94, -2.16), "of": "steel", "box": [1.83, 2.85, -2.52, -1.93],
		"over": [[Vector3(1.98, 1.36, -2.17), Vector3(2.92, 1.44, -1.91)]], "low": true, "reach": 0.4},
}
# what a surface is made of: bounce, grip, how fast it takes the spin out of a die; and how a die
# sounds on it (loudness, pitch)
const STUFF := {"wood": [0.42, 0.38, 2.5, 1.0, 1.0], "felt": [0.2, 0.65, 6.0, 0.45, 0.78],
	"steel": [0.45, 0.3, 1.8, 1.0, 1.32], "carpet": [0.12, 0.85, 8.0, 0.35, 0.72]}
const TRIES := 14
# how many milliseconds a frame go on working the throw out: while it's in his fist, while he
# shakes it, and once it's let go and the throw still isn't worked out
const WORK_MS := {"hand": 3.0, "shake": 5.0, "wind": 6.0, "let_go": 14.0}
# the 24 ways to turn a cube onto itself
static var TURNS: Array = []

var main
var dice: Array = []            # the two die nodes; each holds its faces in a child turned TURNS-wise
var state := ""                 # "", "hand", "shake", "wind", "let_go", "roll", "done"
var item := {}
var card: CheckCard
var cb: Callable
var need := {}
var T: Dictionary = FULL
var t := 0.0                    # real time since the throw
var ts := 0.0                   # the throw's own time, which slows when the night holds its breath
var sim: DiceSim
var planner: Planner
var quick := false
var order: Array = [0, 1]       # which die lies still first, which second
var apex := {}                  # the second die's last stand on an edge: {t, deg}
var beats: Array = []           # [throw time, Callable], in order
var spot := {}
var rest_mid := Vector3.ZERO
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
	var inner := Node3D.new()
	inner.name = "faces"
	d.add_child(inner)
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
		inner.add_child(mi)
	# the body inside, so an edge never shows daylight
	var core := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3.ONE * SIZE * 0.985
	core.mesh = b
	core.material_override = main.pub.mat(Color("e6dfcf"), 0.4, 0.0, 5)
	inner.add_child(core)
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
	quick = mode == "quick"
	T = QUICK if quick else FULL
	main.view.heart = 1.25 + 0.12 * mini(int(it.roll.get("tension", 0)), 4)
	# start working the throw out now, while they're still in his hand
	var cam: Camera3D = main.view.cam
	spot = spot_for(main.view.place, main.view.eye_pos, -cam.global_transform.basis.z)
	if main.view.place == "t28":
		spot.glasses = _t28_glasses(spot.at.y)
	var plan_rng := RandomNumberGenerator.new()
	plan_rng.seed = _rng.randi()
	planner = Planner.new(spot, main.view.eye_pos, plan_rng, need.n > 0 and need.n < 6 and not quick)
	if mode == "full":
		state = "hand"
		card.waiting_in_hand(true)
		main.audio.sfx("rattle", 0.35)
	else:
		# thrown for him: a shake first, then they go
		state = "wind"
		shake_t = 0.0
		main.audio.sfx("rattle", 1.0)


func wants_click() -> bool:
	return state in ["hand", "shake", "wind", "let_go", "roll"]


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
	if state in ["wind", "let_go", "roll"] and pressed:
		finish()
		return true
	return state != ""


func _on_sheet_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if state in ["wind", "let_go", "roll"] and e.pressed:
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


# let go: they're out of his hand as soon as the throw's worked out, which it nearly always is
func _let_go() -> void:
	card.waiting_in_hand(false)
	if shake_t <= 0.25:
		main.audio.sfx("rattle", 1.0)
	state = "let_go"
	planner.hurry = true
	_try_throw()


func _try_throw() -> void:
	if not planner.done:
		return
	_throw(planner.result())


func _throw(plan: Dictionary) -> void:
	sim = plan.sim
	order = plan.order
	apex = plan.apex if planner.drama else {}
	# deal the faces: the first die to lie still shows the first number, the other the second; and
	# when the second matters, the face it stood up toward on its last edge is one that would have
	# turned the night the other way
	var want_other := not bool(item.get("success", false))
	_deal(order[0], int(item.roll.d1), Vector3.ZERO, -1)
	var near := Vector3.ZERO
	if not apex.is_empty():
		near = apex.near
	_deal(order[1], int(item.roll.d2), near, 1 if want_other else 0)
	# the beats, on the throw's own clock: the knocks, then the column
	beats = []
	var stuff: Array = STUFF.get(str(spot.get("of", "wood")), STUFF.wood)
	var last_knock := [-1, -1]
	for i in sim.hits.size():
		var h: Array = sim.hits[i]
		if float(h[0]) <= float(sim.rest_t[h[1]]):
			last_knock[h[1]] = i
	for i in sim.hits.size():
		var h2: Array = sim.hits[i]
		var loud := clampf(float(h2[3]) / 1.3, 0.1, 1.0)
		var what: String = h2[2]
		var name := "die_land" if i == last_knock[h2[1]] else "die_tick"
		var gain: float = loud * float(stuff[3])
		var pitch: float = float(stuff[4])
		if what == "die":
			name = "die_tick"
			gain = loud * 0.8
			pitch = 1.55
		elif what == "glass":
			name = "glass"
			gain = loud * 0.45
			pitch = 1.35
		elif what == "wall":
			pitch *= 0.9
		beats.append([float(h2[0]), func(): main.audio.sfx(name, gain, pitch)])
	var still1: float = sim.rest_t[order[0]]
	var still2: float = sim.rest_t[order[1]]
	beats.append([still1 + T.needs, card.first_down])
	beats.append([still2 + T.ring, card.second_down])
	beats.append([still2 + T.stamp, _stamp])
	beats.append([still2 + T.stamp + T.after, _done])
	beats.sort_custom(func(a, b): return a[0] < b[0])
	for d in dice:
		(d as Node3D).visible = false
	# his eyes go to where they'll lie, and narrow on it
	var p0: Vector3 = sim.pos[0]
	var p1: Vector3 = sim.pos[1]
	rest_mid = (p0 + p1) / 2.0
	_look_back = Vector2(main.view.want_yaw, main.view.want_pitch)
	main.view.look_at_point(rest_mid + Vector3(0, 0.01, 0))
	var dist: float = main.view.eye_pos.distance_to(rest_mid)
	var half := maxf(0.12, p0.distance_to(p1) / 2.0 + 0.075)
	main.view.focus_fov = clampf(rad_to_deg(2.0 * atan(half / maxf(dist, 0.3))), 12.0, 45.0)
	t = 0.0
	ts = 0.0
	state = "roll"


# The faces on a die: turn its six so the one on top at the end shows v; with a near face (the
# one it stood up toward on its last edge), so that face's number is one that passes (1) or fails
# (0) the check.
func _deal(k: int, v: int, near: Vector3, near_passes: int) -> void:
	_turns()
	var up := DiceSim.up_face(sim.rot[k])
	var fits: Array = []
	for r in TURNS:
		if ((r as Basis) * NORMAL[v]).is_equal_approx(up):
			fits.append(r)
	var pick: Basis = fits[_rng.randi() % fits.size()]
	if near != Vector3.ZERO and near_passes >= 0:
		var good: Array = []
		for r2 in fits:
			for f in range(1, 7):
				if ((r2 as Basis) * NORMAL[f]).is_equal_approx(near) and bool(need.pass[f - 1]) == (near_passes == 1):
					good.append(r2)
		if not good.is_empty():
			pick = good[_rng.randi() % good.size()]
	((dice[k] as Node3D).get_node("faces") as Node3D).basis = pick


static func _turns() -> void:
	if not TURNS.is_empty():
		return
	var axes := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	for x in axes:
		for y in axes:
			if absf((x as Vector3).dot(y)) > 0.5:
				continue
			TURNS.append(Basis(x, y, (x as Vector3).cross(y)))


# where they go down from here (SPOTS), or the floor at his feet
static func spot_for(place: String, eye: Vector3, fwd: Vector3) -> Dictionary:
	if SPOTS.has(place):
		return (SPOTS[place] as Dictionary).duplicate(true)
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var feet := eye + fwd * 0.8
	feet.y = eye.y - Posts.STAND
	return {"at": feet, "of": "carpet", "round": [Vector2(feet.x, feet.z), 0.6]}


# table 28's glasses, as they stand tonight
func _t28_glasses(top: float) -> Array:
	var out: Array = []
	var g = main.pub.dyn.get("t28_glasses")
	if g == null:
		return out
	for c in (g as Node).get_children():
		if c is Node3D:
			var p: Vector3 = (c as Node3D).global_position
			out.append([Vector2(p.x, p.z), 0.037, top + 0.15])
	return out


# Works the throw out, a few milliseconds a frame, while the dice are still in his hand: a run of
# throws from his hand at the spot, each played through to the end, and the best kept. Both dice
# have to stay on what they were thrown at, not go down a pocket or into the balls or under the
# pass, and lie still a moment apart; and when the second die matters (drama), the throw wanted is
# one where the second stands up high on an edge near the end before it comes down. Each throw
# that misses tells the next where to aim. The same throws in the same order whatever the frame
# rate, so the same choice comes down the same way.
class Planner:
	var sp: Dictionary
	var drama := false
	var hurry := false          # let go: take the best there is as soon as there's one
	var done := false
	var tries := 0
	var _rng: RandomNumberGenerator
	var _at: Vector3
	var _hand: Vector3
	var _toward: Vector3
	var _side: Vector3
	var _stuff: Array
	var _aim := Vector3.ZERO
	var _cur: DiceSim
	var _best := {}
	var _best_score := -INF
	var _fallback: DiceSim

	func _init(spot: Dictionary, eye: Vector3, rng: RandomNumberGenerator, want_drama: bool) -> void:
		sp = spot
		sp["eye"] = eye
		_rng = rng
		drama = want_drama
		_at = sp.at
		_toward = Vector3(_at.x - eye.x, 0.0, _at.z - eye.z)
		var flat := _toward.length()
		_toward = _toward / flat if flat > 0.01 else Vector3.FORWARD
		_side = _toward.cross(Vector3.UP).normalized()
		# his hand goes out over what he's throwing at, short of where they're meant to end up, a
		# hand's height off it (in low, under anything hanging over it)
		var low: bool = sp.get("low", false)
		_hand = _at - _toward * minf(flat - 0.25, 0.3 if low else 0.42) + _side * 0.04
		_hand.y = _at.y + (0.13 if low else clampf(eye.y - _at.y - 0.45, 0.2, 0.5))
		_stuff = Dice.STUFF.get(str(sp.get("of", "wood")), Dice.STUFF.wood)

	func work(ms: float) -> void:
		var until := Time.get_ticks_usec() + int(ms * 1000.0)
		while not done and Time.get_ticks_usec() < until:
			if hurry and not _best.is_empty():
				done = true
				return
			if _cur == null:
				if tries >= Dice.TRIES:
					done = true
					return
				_cur = _next()
				tries += 1
			_cur.run(16)
			if _cur.done:
				_judge(_cur)
				_cur = null

	func result() -> Dictionary:
		if not _best.is_empty():
			return _best
		# nothing landed where it should: the last that finished at all will have to do, and
		# failing that, the dice simply lying there
		var s: DiceSim = _fallback if _fallback != null else Dice._lying(sp, _rng)
		return {"sim": s, "order": [0, 1] if float(s.rest_t[0]) <= float(s.rest_t[1]) else [1, 0], "apex": {}}

	func _next() -> DiceSim:
		var s := DiceSim.new()
		s.floor_y = _at.y
		s.e_floor = _stuff[0]
		s.mu_floor = _stuff[1]
		s.drag = _stuff[2]
		s.walls = sp.get("walls", [])
		s.glasses = sp.get("glasses", [])
		var land := _at + _aim - _toward * _rng.randf_range(0.06, 0.13) + _side * _rng.randf_range(-0.035, 0.035)
		var from: Array = []
		var v0: Array = []
		var r0: Array = []
		var w0: Array = []
		var fly := clampf(0.25 + 0.3 * _hand.distance_to(land), 0.3, 0.62) * _rng.randf_range(0.92, 1.08)
		if sp.get("low", false):
			# in low and flat, under what's over it
			fly = _rng.randf_range(0.24, 0.32)
		# the second comes off his fingers a moment after the first; when it's the one that
		# matters, a longer moment
		var after := _rng.randf_range(0.3, 0.48) if drama else _rng.randf_range(0.08, 0.2)
		for k in 2:
			var f := _hand + _side * (0.02 if k == 0 else -0.02) + Vector3(0, 0.012 * k, 0)
			var l := land + _side * _rng.randf_range(-0.02, 0.02) + _toward * _rng.randf_range(-0.025, 0.025)
			var tk := fly * _rng.randf_range(0.96, 1.04)
			from.append(f)
			v0.append((l + Vector3(0, DiceSim.H, 0) - f) / tk - DiceSim.GRAV * (0.5 * tk))
			var axis := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1))
			r0.append(Basis(axis.normalized() if axis.length() > 0.01 else Vector3.UP, _rng.randf_range(0.0, TAU)))
			var spin := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1))
			w0.append((spin.normalized() if spin.length() > 0.01 else Vector3.RIGHT) * _rng.randf_range(9.0, 24.0))
		s.throw(from, v0, r0, w0, after)
		return s

	func _judge(s: DiceSim) -> void:
		if not s.ok:
			return
		if _fallback == null:
			_fallback = s
		# where it ended against where it was meant to: the next throw aims off by that much
		var mid: Vector3 = ((s.pos[0] as Vector3) + (s.pos[1] as Vector3)) / 2.0
		var miss := Vector3(_at.x - mid.x, 0.0, _at.z - mid.z)
		_aim = (_aim + miss * 0.5).limit_length(0.35)
		if not Dice._fits(s, sp):
			return
		var o := [0, 1] if float(s.rest_t[0]) <= float(s.rest_t[1]) else [1, 0]
		var gap: float = float(s.rest_t[o[1]]) - float(s.rest_t[o[0]])
		var score := 1.0 - maxf(0.0, 0.3 - gap) * 3.0 + minf(gap, 0.6) * 0.5 - maxf(0.0, float(s.rest_t[o[1]]) - 2.4) * 1.5
		var ap := {}
		if drama:
			# its last stand counts only once the first is down and the column's said what it needs
			ap = Dice._teeter(s, o[1], float(s.rest_t[o[0]]) + 0.2)
			if not ap.is_empty():
				score += 2.0 * smoothstep(14.0, 40.0, float(ap.deg))
		if score > _best_score:
			_best_score = score
			_best = {"sim": s, "order": o, "apex": ap}
		if (not drama and gap >= 0.3) or (drama and score >= 2.75):
			done = true


# both dice still on the stretch they were thrown at, nowhere they couldn't be on the way
static func _fits(s: DiceSim, sp: Dictionary) -> bool:
	var y0: float = s.floor_y
	var at: Vector3 = sp.at
	var p0: Vector3 = s.pos[0]
	var p1: Vector3 = s.pos[1]
	if p0.distance_to(p1) > float(sp.get("reach", 0.28)) + 0.06:
		return false
	for k in 2:
		var p: Vector3 = s.pos[k]
		if Vector2(p.x - at.x, p.z - at.z).length() > float(sp.get("reach", 0.28)):
			return false
		var fr: Array = s.frames[k]
		for i in range(0, fr.size(), 2):
			var q: Vector3 = fr[i][0]
			for o in sp.get("over", []):
				var lo: Vector3 = (o[0] as Vector3) - Vector3.ONE * DiceSim.H
				var hi: Vector3 = (o[1] as Vector3) + Vector3.ONE * DiceSim.H
				if q.x > lo.x and q.x < hi.x and q.y > lo.y and q.y < hi.y and q.z > lo.z and q.z < hi.z:
					return false
			# what's lying there stands up off it, a ball or an arm: nothing goes through it, low or
			# in the air
			for l in sp.get("lying", []):
				var lr := float(l[1])
				if q.y < y0 + minf(2.0 * lr, 0.12) + DiceSim.H and Vector2(q.x, q.z).distance_to(l[0]) < lr + DiceSim.H * 1.8:
					return false
			if q.y > y0 + DiceSim.S * 1.2:
				continue
			# down on it: on it, and not over a pocket
			if sp.has("box"):
				var b: Array = sp.box
				var m := DiceSim.H * 0.8
				if q.x < float(b[0]) + m or q.x > float(b[1]) - m or q.z < float(b[2]) + m or q.z > float(b[3]) - m:
					return false
			if sp.has("round"):
				if Vector2(q.x, q.z).distance_to(sp.round[0]) > float(sp.round[1]) - DiceSim.H * 1.3:
					return false
			for h in sp.get("holes", []):
				if Vector2(q.x, q.z).distance_to(h[0]) < float(h[1]):
					return false
	# and he has to be able to read them where they lie: not tucked in under the near cushion, with
	# the rail between his eye and the face that's up
	if sp.has("eye"):
		var eye: Vector3 = sp.eye
		for k in 2:
			var top: Vector3 = (s.pos[k] as Vector3) + Vector3(0, DiceSim.H, 0)
			for w in sp.get("walls", []):
				var n: Vector3 = w[1]
				var a: float = (eye - (w[0] as Vector3)).dot(n)
				var b: float = (top - (w[0] as Vector3)).dot(n)
				if a < 0.0 and b > 0.0:
					var y: float = eye.y + (top.y - eye.y) * (a / (a - b))
					if float(w[2]) <= 0.0 or y < y0 + float(w[2]) + 0.004:
						return false
	return true


# The second die's last stand: over its last second before it lay still (and not before a given
# time), the moment it stood up highest on an edge, down on the surface, and the face it stood up
# toward (or the face it came over from): {t, deg, near}, or nothing if it never rose much.
static func _teeter(s: DiceSim, k: int, not_before := 0.0) -> Dictionary:
	var fr: Array = s.frames[k]
	var end := mini(int(float(s.rest_t[k]) * DiceSim.FPS), fr.size() - 1)
	var from := maxi(maxi(1, end - int(1.1 * DiceSim.FPS)), int(not_before * DiceSim.FPS))
	var final_up := DiceSim.up_face(Basis(fr[end][1] as Quaternion))
	var best := {}
	var prev := -1.0
	var rising := false
	for i in range(from, end + 1):
		var b := Basis(fr[i][1] as Quaternion)
		var deg := rad_to_deg(acos(clampf(float(_two_up(b)[0][1]), -1.0, 1.0)))
		var down := DiceSim.lowest(fr[i][0], b) < s.floor_y + 0.0015
		if prev >= 0.0 and deg < prev and rising:
			# a peak, one frame back, if it was standing on the surface then
			var bp := Basis(fr[i - 1][1] as Quaternion)
			if DiceSim.lowest(fr[i - 1][0], bp) < s.floor_y + 0.0015 and prev >= 12.0 and prev <= 46.0:
				var tp := _two_up(bp)
				var a: Vector3 = tp[0][0]
				var c: Vector3 = tp[1][0]
				var near := Vector3.ZERO
				if a.is_equal_approx(final_up):
					near = c
				elif c.is_equal_approx(final_up):
					near = a
				if near != Vector3.ZERO and (best.is_empty() or prev >= float(best.deg) - 4.0):
					best = {"t": (i - 1) / DiceSim.FPS, "deg": prev, "near": near}
		rising = prev >= 0.0 and deg > prev and down
		prev = deg
	return best


# the two faces nearest pointing up, and how nearly: [[face, cos], [face, cos]]
static func _two_up(b: Basis) -> Array:
	var all: Array = []
	for f in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
		all.append([f, (b * f).dot(Vector3.UP)])
	all.sort_custom(func(x, y): return float(x[1]) > float(y[1]))
	return [all[0], all[1]]


# no throw would come right: the two dice lying at the spot, as if they'd been there all along
static func _lying(sp: Dictionary, rng: RandomNumberGenerator) -> DiceSim:
	var s := DiceSim.new()
	var at: Vector3 = sp.at
	s.floor_y = at.y
	for k in 2:
		var p := at + Vector3(0.022 * (1 if k == 0 else -1), DiceSim.H, 0.01 * k)
		s.pos[k] = p
		s.rot[k] = Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		s.frames[k] = [[p, Quaternion(s.rot[k])]]
		s.asleep[k] = true
		s.rest_t[k] = 0.05 + 0.3 * k
	s.done = true
	s.ok = true
	return s


# ---------------------------------------------------------------- playing it back

func _process(dt: float) -> void:
	if planner != null and not planner.done and state in ["hand", "shake", "wind", "let_go"]:
		planner.work(WORK_MS.get(state, 4.0))
	if state == "hand":
		return
	if state == "shake" or state == "wind":
		shake_t += dt
		rattle_t += dt
		if rattle_t >= RATTLE:
			rattle_t = 0.0
			main.audio.sfx("rattle", 0.45 + _rng.randf() * 0.35)
		if state == "shake" and not said and shake_t >= SPEAK:
			said = true
			var w = main.game.murmur("shake")
			if w != null:
				card.said(w, main.column.size_px)
		if state == "wind" and shake_t >= T.shake:
			state = "let_go"
			planner.hurry = true
		else:
			return
	if state == "let_go":
		_try_throw()
		return
	if state != "roll":
		return
	t += dt
	ts += dt * float(T.speed) * _pace(ts)
	while not beats.is_empty() and beats[0][0] <= ts:
		var b: Array = beats.pop_front()
		b[1].call()
		if state != "roll":
			return
	for k in 2:
		_pose_die(k)
	# his eyes follow them a little, on the way to where they'll lie
	var now := Vector3.ZERO
	var out := 0
	for d in dice:
		if (d as Node3D).visible:
			now += (d as Node3D).global_position
			out += 1
	main.view.look_at_point((rest_mid.lerp(now / out, 0.25) if out > 0 else rest_mid) + Vector3(0, 0.01, 0))


# The throw's clock against the night's: the same, except round the second die's last stand on an
# edge, when it runs slow, slower the higher it stood and the more rides on it.
func _pace(at: float) -> float:
	if apex.is_empty():
		return 1.0
	var tension := mini(int(item.roll.get("tension", 0)), 4)
	var hold := (1.4 + 0.45 * tension) * smoothstep(14.0, 40.0, float(apex.deg))
	var x := (at - float(apex.t)) / 0.13
	return 1.0 / (1.0 + hold * exp(-x * x))


func _pose_die(k: int) -> void:
	var fr: Array = sim.frames[k]
	var d: Node3D = dice[k]
	# still in his hand
	d.visible = ts >= float(sim.release[k])
	if not d.visible:
		return
	var f := ts * DiceSim.FPS
	if f >= fr.size() - 1:
		d.global_transform = Transform3D(Basis(fr[-1][1] as Quaternion), fr[-1][0])
		return
	var i := int(f)
	var u := f - i
	var a: Array = fr[i]
	var b: Array = fr[i + 1]
	var q: Quaternion = (a[1] as Quaternion).slerp(b[1], u)
	d.global_transform = Transform3D(Basis(q), (a[0] as Vector3).lerp(b[0], u))


func _stamp() -> void:
	card.stamp()
	main.audio.sfx("stamp")
	main.view.heart = 0.0


# the stamp's down: back to the night
func _done() -> void:
	state = "done"
	planner = null
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


# space, enter or a tap: straight to the stamp, the dice lying where they'd have ended (or, if the
# throw isn't worked out yet, just lying there)
func finish() -> void:
	if state in ["hand", "shake", "wind", "let_go"]:
		card.waiting_in_hand(false)
		quick = true
		T = QUICK
		planner.drama = false
		if planner.done or planner.tries > 0:
			planner.hurry = true
			planner.work(4.0)
		_throw(planner.result() if planner.done else {"sim": _lying(spot, _rng), "order": [0, 1], "apex": {}})
	if state != "roll":
		return
	ts = INF
	for k in 2:
		var fr: Array = sim.frames[k]
		(dice[k] as Node3D).visible = true
		(dice[k] as Node3D).global_transform = Transform3D(Basis(fr[-1][1] as Quaternion), fr[-1][0])
	beats.clear()
	card.first_down()
	card.stamp()
	main.audio.sfx("stamp")
	_done()


func cancel() -> void:
	if state == "":
		return
	state = ""
	planner = null
	beats.clear()
	for d in dice:
		(d as Node3D).visible = false
	main.view.heart = 0.0
	main.view.focus_fov = 0.0
