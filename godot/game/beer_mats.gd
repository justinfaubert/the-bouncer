# Beer mats off the edge of the bar: the oldest game in a pub that isn't on the wall. A mat, or a
# stack of them, set hanging over the edge; flicked up from underneath with the fingers so it turns
# over in the air; caught, snatched out of the air in the same hand, before it lands. One, then two,
# then however many he can. Nobody keeps score but him. (The record's in his head: settings.)
#
# The physics, in the plane across the bar's edge (u out from the edge into the room, y up off
# the bar top), at 600 steps a second:
#   - the flick: his fingertips come up under the overhang and hit it. The mats hinge on their back
#     edge where it rests on the bar, so what the hit does is worked out about that hinge: the
#     fingers' mass against the stack's (its moment about the hinge over the arm squared), how fast
#     his hand was going, a little bounce. The further out he hits it the more it turns and the less
#     it climbs; nearer the edge, it climbs and barely turns.
#   - the air: a beer mat is a plate. Pushed through the air flat it's held back hard, edge-on
#     hardly at all, so a single one floats and wobbles and a stack of ten goes up like a brick.
#     Turning, the air slows its turn.
#   - a stack holds together by friction while it turns slowly. Flick it too hard and the mats fan
#     out off each other, and a fan can't be caught.
#   - the catch: the hand closes where it is. It holds if the mats are there, lying near enough flat
#     (face down: it turned over once; face up again: twice) and not going much faster than the
#     hand. Anything else is a slap, and they go down: on the bar, or over his hand onto the floor.
#
# The player has the hand: the mouse moves it (it's captured, the way the darts' aim is), the
# button held curls the fingers to flick, and a click while they're up in the air is the snatch.
# The wheel slides the stack out over the edge or back. No marks, no bar: the same hand does the
# same thing every time, and what pushes back is the drink in him, the nerves, and the mats.
class_name BeerMats
extends Node

const EDGE := Vector3(2.35, 1.12, 5.0)       # the bar top's edge, room side, at the gap across from the taps
const L := 0.105                             # a mat: 105 mm square, a millimetre and a half thick, four grams
const THICK := 0.0016
const MASS := 0.004
const FINGERS := 0.035                       # the fingers' mass, what's behind a flick of them (kg)
const BOUNCE := 0.25
const RHO := 1.2
const CD := 1.15                             # a flat plate across the flow
const HZ := 600.0
const K_HAND := 0.0011                       # metres of hand a pixel of the mouse
const CATCH_R := 0.055                       # how near the mats the hand has to close

signal left

var main
var pub: Pub
var view: View
var active := false
var rehearsal := false
var body := {}
var t := 0.0
var n := 1                                   # mats in the stack
var best := 0
var overhang := 0.042                        # how far the stack hangs out over the edge (m)
var hand := Vector2(0.06, -0.06)             # where his fingertips are, in the plane (u, y)
var hand_v := Vector2.ZERO
var _hv: Array = []                          # the hand's last few speeds
var curled := false                          # the button's held: fingers ready to flick
var closed := false                          # the snatch
var phase := "set"                           # set, air, down, caught
# the stack in the air: its middle, its turn, and how they go
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var th := 0.0
var om := 0.0
var splay := 0.0                             # how far the stack's fanned out
var _spl: Array = []                         # each mat's share of the fan
var _down_t := 0.0
var _acc := 0.0
var rng := RandomNumberGenerator.new()
var flicks := 0
var seen := {}

var mats: Array = []                         # the mats drawn
var pile: Node3D                             # the rest of them, stacked by the till
var hand_node: Node3D
var _ph := [0.0, 0.0]


func setup(m) -> void:
	main = m
	pub = m.pub
	view = m.view
	rng.seed = 1971
	_ph = [rng.randf() * TAU, rng.randf() * TAU]
	# the pile on the bar top, in the gap: the mats the brewery sends, a hundred at a time
	pile = Node3D.new()
	pub.add_child(pile)
	pile.position = EDGE + Vector3(-0.28, 0.0, 0.22)
	for k in 18:
		var mt := _mat()
		pile.add_child(mt)
		mt.position = Vector3(rng.randf_range(-0.004, 0.004), THICK * (k + 0.5), rng.randf_range(-0.004, 0.004))
		mt.rotation.y = rng.randf_range(-0.06, 0.06)
	pub.anchors["coasters"] = pile.position + Vector3(0, 0.03, 0)
	best = int(main.settings.get("mats_best", 0))
	set_process(false)
	set_process_input(false)


func _mat() -> Node3D:
	var M: Dictionary = pub.M
	var nd := Node3D.new()
	var card := pub.mat(Color("cfc6ae"), 0.95, 0.0, 3)
	pub.box(Vector3(L, THICK, L), Vector3.ZERO, card, 0.0, nd)
	# the face: the brewery's, a ring and a name, worn; the back plain card
	var face := pub.mat(Color("7a6a4a"), 0.9, 0.0, 3)
	pub.cyl(0.042, 0.042, 0.0002, Vector3(0, THICK / 2.0 + 0.0001, 0), face, nd, 20)
	pub.cyl(0.033, 0.033, 0.0002, Vector3(0, THICK / 2.0 + 0.0002, 0), card, nd, 20)
	var l := Label3D.new()
	l.text = "SEAWALL\nLAGER"
	l.font = Look.font("ui_b")
	l.font_size = 30
	l.pixel_size = 0.0005
	l.modulate = Color("5a4a32")
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.rotation.x = -PI / 2.0
	l.position = Vector3(0, THICK / 2.0 + 0.0004, 0)
	nd.add_child(l)
	return nd


# ---------------------------------------------------------------- in and out

func begin(rehearse := false, from := {}) -> void:
	active = true
	rehearsal = rehearse
	body = from.duplicate()
	if not rehearse:
		body = {"drinks": view.drinks, "hurt": view.hurt, "tension": view.tension, "clock": view.clock, "cold": 0.0}
	n = 1
	_saved = {"eye": view.eye_pos, "yaw": view.yaw, "pitch": view.pitch}
	view.walking = false
	view.focus_fov = 50.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hand_build()
	_reset()
	set_process(true)
	set_process_input(true)
	_column_begin()


var _saved := {}

func end() -> void:
	if not active:
		return
	active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	view.focus_fov = 0.0
	set_process(false)
	set_process_input(false)
	for mt in mats:
		mt.queue_free()
	mats.clear()
	if hand_node != null:
		hand_node.visible = false
	if not rehearsal:
		view.eye_pos = _saved.get("eye", view.eye_pos)
		view.yaw = _saved.get("yaw", view.yaw)
		view.pitch = _saved.get("pitch", view.pitch)
		view.want_yaw = view.yaw
		view.want_pitch = view.pitch
	left.emit()


func _hand_build() -> void:
	if hand_node != null:
		hand_node.visible = true
		return
	hand_node = Node3D.new()
	pub.add_child(hand_node)
	var h: Node3D = pub.model("res://models/people/his_right_palm.glb", Vector3.ZERO, hand_node)
	h.name = "palm"


# a fresh stack of n set out over the edge, his hand down under it
func _reset() -> void:
	for mt in mats:
		mt.queue_free()
	mats.clear()
	_spl.clear()
	for k in n:
		var mt := _mat()
		pub.add_child(mt)
		mats.append(mt)
		_spl.append(rng.randf_range(-1.0, 1.0))
	pos = Vector2(overhang - L / 2.0, n * THICK / 2.0)
	vel = Vector2.ZERO
	th = 0.0
	om = 0.0
	splay = 0.0
	phase = "set"
	closed = false
	curled = false
	hand = Vector2(overhang * 0.6, -0.07)
	hand_v = Vector2.ZERO
	_hv.clear()
	_draw()


# ---------------------------------------------------------------- the physics

func _process(dt: float) -> void:
	if not active:
		return
	t += dt
	_acc += dt
	var steps := 0
	while _acc >= 1.0 / HZ and steps < 40:
		_acc -= 1.0 / HZ
		_step(1.0 / HZ)
		steps += 1
	if phase == "down":
		_down_t += dt
		if _down_t > 1.2:
			_reset()
	_eyes(dt)
	_draw()


func _step(h: float) -> void:
	if phase != "air":
		return
	var m := MASS * n
	# the air on the plate: across it, hard; along it, little
	var nrm := Vector2(-sin(th), cos(th))
	var vn := vel.dot(nrm)
	var vt := vel - nrm * vn
	var area := L * L * (1.0 + splay * 0.6)
	var f := -nrm * 0.5 * RHO * CD * area * vn * absf(vn) - vt * 0.5 * RHO * 0.02 * area * vt.length()
	vel += (f / m + Vector2(0, -9.81)) * h
	pos += vel * h
	# the turn, slowed by the air on its two ends going round
	var inertia := m * (L * L + (n * THICK) * (n * THICK)) / 12.0
	var tq := -0.5 * RHO * CD * L * pow(L / 2.0, 4) / 4.0 * om * absf(om)
	om += tq / inertia * h
	th += om * h
	# down onto the bar, or past the edge and down to the floor
	var lowest := pos.y - absf(sin(th)) * L / 2.0 - n * THICK / 2.0
	if pos.x < 0.0 and lowest <= 0.0 and vel.y < 0.0:
		_land("bar")
	elif pos.y < -1.05:
		_land("floor")


func _flick(v_hand: Vector2, at_u: float) -> void:
	# the hinge: the back edge of the stack where it rests on the bar
	var hinge := overhang - L
	var a := clampf(at_u - hinge, L * 0.55, L)
	var m := MASS * n
	var i_hinge := m * (L * L + (n * THICK) * (n * THICK)) / 12.0 + m * (L / 2.0) * (L / 2.0)
	var m_eff := i_hinge / (a * a)
	var vup := maxf(0.0, v_hand.y)
	var j := (1.0 + BOUNCE) * vup / (1.0 / FINGERS + 1.0 / m_eff)
	var w := j * a / i_hinge
	# it leaves the hinge turning about it: the middle going up at the turn times half the length,
	# and along with the hand a little
	om = w
	th = 0.0
	vel = Vector2(v_hand.x * 0.25, w * L / 2.0)
	pos = Vector2(hinge + L / 2.0, n * THICK / 2.0 + 0.001)
	# a stack holds by friction while it turns slowly; harder, it fans
	var hold := 34.0 + n * 1.5
	splay = clampf((absf(w) - hold) / 40.0, 0.0, 1.0) if n > 1 else 0.0
	phase = "air"
	flicks += 1
	main.audio.sfx("card", 0.4 + minf(0.4, j * 4.0), 1.15)
	if splay > 0.3:
		_once("fanned", "Too hard. They came off the top of each other in a fan.")
	_once("flick", "He set it over the edge and flicked it up from underneath with his fingers.")


func _snatch() -> void:
	closed = true
	if phase != "air":
		return
	var d := hand.distance_to(pos)
	var turned := fposmod(th, TAU)
	var flat := minf(absf(turned), minf(absf(turned - PI), absf(turned - TAU)))
	var rel := (vel - hand_v).length()
	if d < CATCH_R and flat < deg_to_rad(28.0) and rel < 2.6 and splay < 0.3:
		var flips := int(round(absf(th) / PI))
		if flips < 1:
			_caught(false, 0)
		else:
			_caught(true, flips)
	else:
		# a slap: knocked away, down they go
		if d < CATCH_R * 1.6:
			vel += Vector2(rng.randf_range(-1.0, 1.0), -1.0) * 1.5
			om += rng.randf_range(-20.0, 20.0)
			splay = maxf(splay, 0.5) if n > 1 else splay
			main.audio.sfx("slap", 0.35, 1.4)
			if flat >= deg_to_rad(28.0) and d < CATCH_R:
				_once("edge", "He got to it edge-on and knocked it away.")


func _caught(ok: bool, flips: int) -> void:
	phase = "caught"
	main.audio.sfx("slap", 0.25, 1.8)
	if not ok:
		_line("Caught, but it hadn't gone over. That doesn't count.")
		_after(func(): _reset())
		return
	if n > best:
		best = n
		if not rehearsal:
			main.settings["mats_best"] = best
			main.store.save_settings()
	var what := ""
	if flips >= 2:
		what = "Over twice, and caught. "
	if n == 1:
		_line(what + "It went over once and he had it.")
	elif n == best and n >= 3:
		_line(what + "%s, over and caught. His best." % _count(n))
	else:
		_line(what + "%s, over and caught." % _count(n))
	n += 1
	_after(func(): _reset())


func _land(where: String) -> void:
	phase = "down"
	_down_t = 0.0
	vel = Vector2.ZERO
	om = 0.0
	if where == "bar":
		pos.y = n * THICK / 2.0
		th = PI if fposmod(th, TAU) > PI / 2.0 and fposmod(th, TAU) < 3.0 * PI / 2.0 else 0.0
		main.audio.sfx("card", 0.4, 0.8)
		_once("bar", "It came down on the bar.")
	else:
		pos.y = -1.12 + n * THICK / 2.0
		pos.x = maxf(pos.x, 0.12)
		th = 0.0
		main.audio.sfx("card", 0.25, 0.7)
		_once("floor", "Onto the carpet. He picked it up.")
	if n > 1:
		n = maxi(1, n - 1)


func _after(f: Callable) -> void:
	get_tree().create_timer(0.8).timeout.connect(f)


func _count(k: int) -> String:
	var words := ["None", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"]
	return words[k] if k < words.size() else str(k)


# ---------------------------------------------------------------- what's seen

func _eyes(_dt: float) -> void:
	var at := EDGE + Vector3(0.62, 0.36, 0.42)
	var look := EDGE + Vector3(-0.02, 0.1, 0.0)
	# drink in him: the eyes don't hold still
	var drinks := float(body.get("drinks", 0))
	look += Vector3(0, sin(t * 0.9) * 0.004 * drinks, cos(t * 0.7) * 0.004 * drinks)
	view.eye_pos = at
	var a := Posts.aim(at, look)
	view.yaw = a.x
	view.pitch = a.y
	view.want_yaw = a.x
	view.want_pitch = a.y


func _w(p: Vector2) -> Vector3:
	return EDGE + Vector3(p.x, p.y, 0.0)


func _draw() -> void:
	var cur := pos
	var cth := th
	if phase == "set" or phase == "caught" and false:
		pass
	for k in mats.size():
		var mt: Node3D = mats[k]
		var off := (k - (mats.size() - 1) / 2.0) * THICK
		# each mat off the middle of the stack, along its normal, fanned out by its share
		var a := cth + float(_spl[k]) * splay * 0.9
		var nrm := Vector2(-sin(a), cos(a))
		var p := cur + nrm * off + Vector2(cos(a), sin(a)) * float(_spl[k]) * splay * 0.04
		if phase == "caught":
			p = hand + Vector2(0, 0.012) + nrm * off
		mt.global_transform = Transform3D(Basis(Vector3(0, 0, 1), a), _w(p))
	# the hand: palm up under the edge to flick, turned over and closing to snatch
	if hand_node != null:
		var tr := _tremor()
		var hp := hand + tr
		var palm_down := phase == "air" and not curled or closed
		var b := Basis(Vector3.UP, PI / 2.0)
		if palm_down:
			b = b * Basis(Vector3(0, 0, 1), PI)
		if curled and phase == "set":
			b = b * Basis(Vector3(1, 0, 0), deg_to_rad(-20.0))
		hand_node.global_transform = Transform3D(b, _w(hp) + Vector3(0.13, -0.015 if not palm_down else 0.015, 0.0))


func _tremor() -> Vector2:
	var drinks := float(body.get("drinks", 0))
	var nerves := float(body.get("tension", 0))
	var s := 0.0006 + drinks * 0.0012 + nerves * 0.0009 + float(body.get("hurt", 0)) * 0.001
	var f := 8.0 + nerves
	return Vector2(sin(t * TAU * f + _ph[0]), sin(t * TAU * f * 1.31 + _ph[1])) * s


# ---------------------------------------------------------------- the player's hand

func _input(e: InputEvent) -> void:
	if not active:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		end()
		return
	if main.menus.is_open():
		return
	if e is InputEventMouseMotion:
		var rel: Vector2 = e.relative
		var k := K_HAND * float(main.settings.get("look_speed", 1.0))
		var was := hand
		hand += Vector2(-rel.x, -rel.y) * k * Vector2(0.6, 1.0)
		hand.x = clampf(hand.x, -0.25, 0.3)
		hand.y = clampf(hand.y, -0.2, 0.45)
		# the bar's in the way: the hand doesn't go through it
		if hand.x < -0.005 and hand.y < 0.02 and was.y >= 0.02:
			hand.y = 0.02
		elif hand.x < -0.005 and hand.y < 0.02 and was.x >= -0.005:
			hand.x = -0.005
		var dt := maxf(get_process_delta_time(), 1.0 / 240.0)
		var v := (hand - was) / dt
		_hv.append(v)
		if _hv.size() > 3:
			_hv.pop_front()
		hand_v = Vector2.ZERO
		for vv in _hv:
			hand_v += vv
		hand_v /= float(_hv.size())
		hand_v = hand_v.limit_length(5.0)
		# fingers come up through the underside of the overhang: the flick
		if phase == "set" and was.y < 0.0 and hand.y >= 0.0 and hand.x > 0.0 and hand.x < overhang + 0.01:
			if curled:
				_flick(hand_v, hand.x)
			else:
				# lifted with a flat hand: it tips up and falls back
				_once("lift", "He lifted it with his fingers and it tipped and fell back. It wants a flick, not a push. (Hold the button to curl the fingers.)")
				hand.y = -0.001
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		var mb := e as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					if phase == "air":
						_snatch()
					else:
						curled = true
				else:
					curled = false
					closed = false
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed and phase == "set":
					overhang = clampf(overhang + 0.004, 0.02, 0.07)
					pos.x = overhang - L / 2.0
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed and phase == "set":
					overhang = clampf(overhang - 0.004, 0.02, 0.07)
					pos.x = overhang - L / 2.0
	elif e is InputEventKey:
		var ke := e as InputEventKey
		if ke.pressed and not ke.echo:
			match ke.physical_keycode:
				KEY_Q:
					if phase == "set" and n > 1:
						n -= 1
						_reset()
				KEY_E:
					if phase == "set":
						n += 1
						_reset()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- what he notices

func _column_begin() -> void:
	if main.column == null:
		return
	main.column.begin_batch()
	if rehearsal:
		main.column.reset()
		main.column.add_line({"role": "narration", "text": "The bar, at the gap across from the taps, and the pile of beer mats the brewery sends a hundred at a time."})
	else:
		main.column.add_line({"role": "narration", "text": "He took a beer mat off the pile and set it hanging over the edge of the bar."})
	main.column.add_note("The mouse moves his hand. Hold the button to curl his fingers and bring them up fast under the part that's hanging over; let go, and click again while it's in the air to snatch it. It has to have turned over and be lying flat. The wheel slides it out over the edge or back. Q and E take a mat off or put one on. Esc puts them down.%s" % ("" if best == 0 else "\nHis best: %d." % best))
	main.column.scroll_to_end()


func _line(text: String) -> void:
	if text == "" or main.column == null:
		return
	main.column.begin_batch()
	main.column.add_line({"role": "narration", "text": text})
	main.column.scroll_to_end()


func _once(key: String, text: String) -> void:
	if seen.has(key):
		return
	seen[key] = true
	_line(text)
