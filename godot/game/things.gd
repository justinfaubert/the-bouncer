# The things he handles that aren't a licence, the kid's phone or the binder (content/data/props.yaml,
# kind: thing): what each is made of in his view, and what's printed or pencilled on it, made in the
# props' darkroom (game/props.gd). Most lie in his open hand (models/people/his_right_palm.glb); the
# flat ones he holds up the way he holds a licence (his_right_card); the pint he holds round its
# middle (his_right_pint, which brings its own glass); the last doorman's jacket is too big for one
# hand and lies folded on the bar in front of him. Turning one over turns it in his fingers, not his
# hand.
class_name Things
extends RefCounted

# how each shape is held: the hand, and the anchor on it that the thing lines up with
const HELD := {
	"flashlight": ["his_right_palm", "palm"], "key": ["his_right_palm", "palm"], "keys": ["his_right_palm", "palm"],
	"straw": ["his_right_palm", "palm"], "book": ["his_right_palm", "palm"], "bag": ["his_right_palm", "palm"],
	"shirt": ["his_right_palm", "palm"], "mat": ["his_right_card", "card"], "tickets": ["his_right_card", "card"],
	"bill": ["his_right_card", "card"], "glass": ["his_right_pint", "pint"],
}
# where it sits in front of his eyes (the camera's space: -z ahead, y up), at rest and brought
# closer (E): a position, and a turn in degrees. The open hand is palm up with his fingers straight
# ahead, so they go away from him and only their cupped ends come up (tipped toward him, they stand
# up like a hand held up to stop somebody); brought closer, it comes up under his eyes and tips a
# little toward him. The big things in it sit further off, and hide the hand, so they tip more. The
# pint is turned on its own axis so his forearm comes in from the right, not at his eyes
const POSES := {
	"palm:rest": [Vector3(0.05, -0.18, -0.36), Vector3(-88, -8, 6)],
	"palm:look": [Vector3(0.02, -0.125, -0.3), Vector3(-80, -4, 3)],
	"shirt:rest": [Vector3(0.03, -0.21, -0.46), Vector3(-72, -6, 4)],
	"shirt:look": [Vector3(0.0, -0.14, -0.37), Vector3(-58, -2, 2)],
	"bag:rest": [Vector3(0.03, -0.2, -0.44), Vector3(-72, -6, 4)],
	"bag:look": [Vector3(0.0, -0.13, -0.35), Vector3(-58, -2, 2)],
	"book:rest": [Vector3(0.04, -0.19, -0.4), Vector3(-74, -6, 4)],
	"book:look": [Vector3(0.0, -0.12, -0.31), Vector3(-60, -2, 2)],
	# the last doorman's jacket, folded on the bar in front of him, and lifted to look at
	"jacket:rest": [Vector3(0.0, -0.3, -0.72), Vector3(-70, 0, 0)],
	"jacket:look": [Vector3(0.0, -0.22, -0.58), Vector3(-52, 0, 0)],
	"card:rest": [Vector3(0.062, -0.07, -0.25), Vector3(12, -8, 4)],
	"card:look": [Vector3(0.0, -0.02, -0.2), Vector3(2, 0, 0)],
	"pint:rest": [Vector3(0.07, -0.16, -0.34), Vector3(6, 40, 0)],
	"pint:look": [Vector3(0.03, -0.12, -0.27), Vector3(4, 32, 0)],
	"none:rest": [Vector3(0.0, -0.29, -0.44), Vector3(-58, 0, 0)],
	"none:look": [Vector3(0.0, -0.2, -0.38), Vector3(-42, 0, 0)],
}
const PENCIL := Color("4a4a50")
const PAPER := Color("ece6d5")

var pp                 # the props (game/props.gd): its darkroom and its pictures


func _init(props) -> void:
	pp = props


static func held_by(shape: String) -> Array:
	return HELD.get(shape, [])


static func pose(shape: String, p: String) -> Array:
	if POSES.has(shape + ":" + p):
		return POSES[shape + ":" + p]
	var hand: Array = HELD.get(shape, [])
	var k: String = (str(hand[1]) if not hand.is_empty() else "none") + ":" + p
	return POSES.get(k, POSES["none:rest"])


# ---------------------------------------------------------------- the darkroom

# The pictures each thing needs, queued with the rest before the night starts.
func jobs(P: Dictionary) -> void:
	for id in P:
		var pr = P[id]
		if not (pr is Dictionary) or str(pr.get("kind", "")) != "thing":
			continue
		match str(pr.get("shape", "")):
			"key":
				pp._job("thing_%s_front" % id, _fob.bind(pr, true))
				pp._job("thing_%s_back" % id, _fob.bind(pr, false))
			"shirt":
				pp._job("thing_%s_front" % id, _shirt.bind(pr, true))
				pp._job("thing_%s_back" % id, _shirt.bind(pr, false))
			"bill":
				pp._job("thing_%s_front" % id, _bill.bind(pr, true))
				pp._job("thing_%s_back" % id, _bill.bind(pr, false))
			"mat":
				pp._job("thing_%s_front" % id, _mat.bind(pr, true))
				pp._job("thing_%s_back" % id, _mat.bind(pr, false))
			"tickets":
				pp._job("thing_%s_front" % id, _ticket.bind(pr, true))
				pp._job("thing_%s_back" % id, _ticket.bind(pr, false))
			"bag":
				pp._job("thing_%s_front" % id, _bag.bind(pr, true))
				pp._job("thing_%s_back" % id, _bag.bind(pr, false))
			"book":
				pp._job("thing_%s_front" % id, _book.bind(pr, true))
				pp._job("thing_%s_back" % id, _book.bind(pr, false))
				pp._job("thing_%s_flyer" % id, _flyer.bind(pr))
			"jacket":
				pp._job("thing_%s_front" % id, _jacket.bind(pr))


# a line of the yaml's front: or back: list, and whether it's in pencil ("~ ...") or printed
static func _lines(pr: Dictionary, side: String) -> Array:
	var out: Array = []
	for l in pr.get(side, []):
		var s := str(l)
		out.append([s.trim_prefix("~").strip_edges(), s.begins_with("~")])
	return out


func _poly(parent: Control, pts: PackedVector2Array, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.antialiased = true
	parent.add_child(p)
	return p


func _stroke(parent: Control, pts: PackedVector2Array, col: Color, w: float, closed := false) -> Line2D:
	var ln := Line2D.new()
	ln.points = pts
	ln.width = w
	ln.default_color = col
	ln.joint_mode = Line2D.LINE_JOINT_ROUND
	ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ln.end_cap_mode = Line2D.LINE_CAP_ROUND
	ln.closed = closed
	ln.antialiased = true
	parent.add_child(ln)
	return ln


func _ring(parent: Control, c: Vector2, r: Vector2, col: Color, w: float, wobble := 0.0, rng: RandomNumberGenerator = null) -> Line2D:
	var pts := PackedVector2Array()
	for i in 49:
		var a := TAU * i / 48.0
		var k := 1.0 + (rng.randf_range(-wobble, wobble) if rng != null else 0.0)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * k)
	return _stroke(parent, pts, col, w)


func _centred(parent: Control, text: String, y: float, width: float, font: String, size: int, col: Color, spacing := 0) -> Label:
	var l := UiBits.label(text, font, size, col, spacing)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(width, size * 1.4)
	parent.add_child(l)
	return l


# The key to twelve on its fob: a long diamond of green plastic, the number in gold, and on the back
# what every hotel fob used to say.
func _fob(pr: Dictionary, front: bool) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(440, 240), true)
	sv.transparent_bg = true
	var c: Control = pp._page(sv)
	var green := Color("2f4a3c")
	var gold := Color("c9a44c")
	var shape := PackedVector2Array([Vector2(8, 120), Vector2(220, 8), Vector2(432, 120), Vector2(220, 232)])
	_poly(c, shape, green)
	_stroke(c, PackedVector2Array([Vector2(26, 120), Vector2(220, 20), Vector2(414, 120), Vector2(220, 220)]), Color(gold, 0.55), 2.5, true)
	# the hole the ring goes through, at the narrow end
	var hole := PackedVector2Array()
	for i in 24:
		hole.append(Vector2(52, 120) + Vector2(cos(TAU * i / 24.0), sin(TAU * i / 24.0)) * 11.0)
	_poly(c, hole, Color("101512"))
	if front:
		# the hotel's name over the number and under it, where the diamond's wide enough to hold them
		var big := str(_lines(pr, "front")[0][0]) if not _lines(pr, "front").is_empty() else ""
		_centred(c, "THE SOVEREIGN", 50, 440, "ui_b", 14, Color(gold, 0.85), 2)
		_centred(c, big, 58, 440, "anton", 84, gold)
		_centred(c, "HOTEL", 166, 440, "ui_b", 14, Color(gold, 0.85), 4)
	else:
		_centred(c, "DROP IN ANY MAILBOX", 82, 440, "ui_b", 21, gold, 2)
		_centred(c, "POSTAGE GUARANTEED", 112, 440, "ui_b", 21, gold, 2)
		_centred(c, "THE SOVEREIGN HOTEL", 146, 440, "mono", 15, Color(gold, 0.8))
	return sv


# Gary's shirt, folded out of its box: black, and turned over, what it says across his back.
func _shirt(pr: Dictionary, front: bool) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(600, 650), true)
	var c: Control = pp._page(sv)
	var black := Color("222327")
	pp._rect(c, Rect2(Vector2.ZERO, c.size), black)
	var r: RandomNumberGenerator = pp._rng("shirt" + str(front))
	# the folds: the sleeves turned in, and where the box pressed it
	for x in [96.0, 504.0]:
		pp._rect(c, Rect2(x - 3, 0, 6, 650), Color("2d2f34"))
	pp._rect(c, Rect2(0, 410, 600, 5), Color("2d2f34"))
	for i in 40:
		pp._rect(c, Rect2(r.randf_range(0, 600), r.randf_range(0, 650), r.randf_range(30, 120), 1.5), Color(1, 1, 1, 0.025))
	if front:
		# the collar's rib, round the top of the fold
		var arc := PackedVector2Array()
		for i in 25:
			var a := PI * i / 24.0
			arc.append(Vector2(300, 14) + Vector2(-cos(a) * 92.0, sin(a) * 58.0))
		_stroke(c, arc, Color("18191c"), 22.0)
		_stroke(c, arc, Color("34363b"), 2.0)
	else:
		var lines := _lines(pr, "back")
		var word := str(lines[0][0]) if not lines.is_empty() else "SECURITY"
		_centred(c, word, 150, 600, "ui_b", 74, Color("e8e6df"), 8)
	return sv


# A fifty folded small: a quarter of the note on each side, in the press's inks and not the note's
# own, which is red, and red is the sign's and blood's.
func _bill(pr: Dictionary, front: bool) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(760, 340), true)
	var c: Control = pp._page(sv)
	var paper := Color("d9d3bd")
	var ink := Color("4e5a4a")
	var ink2 := Color("7a6a52")
	pp._rect(c, Rect2(Vector2.ZERO, c.size), paper)
	for i in 22:
		var pts := PackedVector2Array()
		for x in range(0, 770, 14):
			pts.append(Vector2(x, 20.0 + i * 15.0 + sin(x * 0.024 + i * 0.8) * 7.0 + sin(x * 0.009 + i) * 4.0))
		_stroke(c, pts, Color(ink2, 0.28), 1.3)
	var lines := _lines(pr, "front" if front else "back")
	var num := str(lines[0][0]) if not lines.is_empty() else "50"
	if front:
		# an oval of fine lines where a face would be, and the number, big
		for k in 9:
			_ring(c, Vector2(200, 170), Vector2(96 - k * 7, 122 - k * 8), Color(ink, 0.5 - k * 0.04), 1.6)
		var l: Label = pp._text(c, num, Vector2(470, 40), "display", 210, ink)
		l.modulate.a = 0.92
		pp._text(c, "FIFTY", Vector2(486, 268), "ui_b", 26, ink2, 6)
	else:
		for i in 12:
			pp._rect(c, Rect2(330 + i * 26, 120 - (i % 3) * 14, 12, 140 + (i % 3) * 14), Color(ink, 0.35))
		pp._text(c, num, Vector2(40, 40), "display", 170, ink)
		pp._text(c, "CINQUANTE", Vector2(40, 270), "ui_b", 24, ink2, 5)
	# the folds: it's been in a pocket
	pp._rect(c, Rect2(0, 168, 760, 3), Color(0.2, 0.2, 0.15, 0.25))
	pp._rect(c, Rect2(378, 0, 3, 340), Color(0.2, 0.2, 0.15, 0.2))
	return sv


# The last doorman's beer mat: the Sov's, printed on the front; on the back, in his pencil, his count
# of them, doubling, the knot as he drew it, and where.
func _mat(pr: Dictionary, front: bool) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(512, 512), true)
	sv.transparent_bg = true
	var c: Control = pp._page(sv)
	var r: RandomNumberGenerator = pp._rng("mat" + str(front))
	pp._rect(c, Rect2(4, 4, 504, 504), Color("e6dfca") if front else Color("ddd5bf"), 46)
	# carried in a pocket: soft at the edges, a ring where a glass sat on it once
	_ring(c, Vector2(300, 290), Vector2(150, 150), Color(0.45, 0.32, 0.18, 0.09), 14.0, 0.02, r)
	if front:
		var navy := Color("2a3550")
		_ring(c, Vector2(256, 256), Vector2(222, 222), navy, 6.0)
		_ring(c, Vector2(256, 256), Vector2(208, 208), navy, 2.0)
		var ls := _lines(pr, "front")
		var y := 150.0
		var sizes := [42, 86, 30]
		var fonts := ["ui_b", "display", "ui_b"]
		for i in ls.size():
			var sz: int = sizes[mini(i, 2)]
			_centred(c, str(ls[i][0]), y, 512, fonts[mini(i, 2)], sz, navy, 4 if i != 1 else 2)
			y += sz * 1.25 + 8.0
		for sx in [-1.0, 1.0]:
			var st := Vector2(256 + sx * 150, 120)
			_poly(c, PackedVector2Array([st + Vector2(0, -12), st + Vector2(4, -3), st + Vector2(13, -3), st + Vector2(6, 3), st + Vector2(9, 12),
				st + Vector2(0, 6), st + Vector2(-9, 12), st + Vector2(-6, 3), st + Vector2(-13, -3), st + Vector2(-4, -3)]), navy)
	else:
		var ls2 := _lines(pr, "back")
		var y2 := 28.0
		var hand: Font = Look.font("hand")
		for l in ls2:
			var s := str(l[0])
			if s.begins_with("("):
				_knot(c, Vector2(256, y2 + 106), 60.0, r)
				y2 += 214.0
				continue
			var big := s.begins_with("BEHIND")
			var sz := 50 if big else 38
			var lab: Label = pp._text(c, s, Vector2(70, y2), "hand", sz, PENCIL)
			lab.rotation = deg_to_rad(r.randf_range(-1.6, 1.0))
			if s.ends_with("35"):
				# the last count, gone round, where it is on the line as he wrote it
				var whole := hand.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
				var last := hand.get_string_size("35", HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
				var mid := Vector2(70, y2) + Vector2(whole - last / 2.0, sz * 0.72).rotated(lab.rotation)
				_ring(c, mid, Vector2(last / 2.0 + 13.0, sz * 0.62), Color(PENCIL, 0.9), 2.4, 0.06, r)
			if big:
				var wide := hand.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
				_stroke(c, PackedVector2Array([Vector2(66, y2 + 64), Vector2(74 + wide, y2 + 60)]), PENCIL, 2.6)
				_stroke(c, PackedVector2Array([Vector2(80, y2 + 71), Vector2(70 + wide, y2 + 68)]), Color(PENCIL, 0.7), 1.8)
			y2 += 44.0
	return sv


# The knot as he drew it: a ring of rats, heads out, each one shaded in, the tails run in to the
# middle and tied there, the knot gone over and over till the pencil shone.
func _knot(c: Control, at: Vector2, rad: float, r: RandomNumberGenerator) -> void:
	var n := 9
	var lead := Color(PENCIL, 0.92)
	for i in n:
		# half a step round, so none points straight up into the count over it
		var a := TAU * (i + 0.5) / n - PI / 2.0 + r.randf_range(-0.06, 0.06)
		var d := Vector2(cos(a), sin(a))
		var side := Vector2(-d.y, d.x)
		var rump := at + d * rad
		# the body, fat at the rump, and the head drawn out to the nose
		var body := _oval(rump + d * 13.0, d, 17.0, 10.5)
		var head := _oval(rump + d * 33.0, d, 11.0, 6.5)
		_poly(c, body, Color(PENCIL, 0.42))
		_poly(c, head, Color(PENCIL, 0.42))
		_stroke(c, body, lead, 2.0, true)
		_stroke(c, PackedVector2Array([head[3], rump + d * 45.0, head[17]]), lead, 2.0)
		# the ears, and the feet, quick
		for e in [-1.0, 1.0]:
			_ring(c, rump + d * 27.0 + side * e * 8.5, Vector2(4.2, 4.2), lead, 1.6)
			_stroke(c, PackedVector2Array([rump + d * 20.0 + side * e * 9.0, rump + d * 24.0 + side * e * 15.0]), Color(PENCIL, 0.75), 1.6)
			_stroke(c, PackedVector2Array([rump + d * 4.0 + side * e * 9.0, rump + d * 1.0 + side * e * 15.0]), Color(PENCIL, 0.75), 1.6)
		# the tail, in to the middle, with a turn in it
		var tail := PackedVector2Array()
		for k in 11:
			var t := k / 10.0
			tail.append(rump - d * (4.0 + t * (rad - 16.0)) + side * sin(t * PI * 1.4) * 8.0)
		_stroke(c, tail, Color(PENCIL, 0.85), 1.8)
	# the knot: loops over loops, and the middle of it dark
	_poly(c, _oval(at, Vector2.RIGHT, 12.0, 10.0), Color(PENCIL, 0.55))
	for k in 12:
		_ring(c, at + Vector2(r.randf_range(-6, 6), r.randf_range(-6, 6)), Vector2(r.randf_range(8, 17), r.randf_range(6, 14)),
			Color(PENCIL, 0.8), 1.8, 0.18, r)


# an oval's outline, long along d
func _oval(c: Vector2, d: Vector2, along: float, across: float) -> PackedVector2Array:
	var side := Vector2(-d.y, d.x)
	var pts := PackedVector2Array()
	for k in 20:
		var t := TAU * k / 20.0
		pts.append(c + d * cos(t) * along + side * sin(t) * across)
	return pts


# where a point of the paperback's cover drawing lands: drawn standing on y 604, set down a little
# lower and smaller
static func _cv(v: Vector2) -> Vector2:
	return Vector2(220, 640) + (v - Vector2(220, 604)) * 0.9


static func _cvs(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in pts:
		out.append(_cv(v))
	return out


# a limb on the cover, the way the pictures on a sports page draw them: one round-ended stroke
func _limb(c: Control, pts: Array, w: float, col: Color) -> void:
	_stroke(c, _cvs(pts), col, w * 0.9)


# A ferry ticket from the machine at the terminal: foot passenger, one way, the sailing.
func _ticket(pr: Dictionary, front: bool) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(860, 540), true)
	var c: Control = pp._page(sv)
	var ink := Color("1d2430")
	pp._rect(c, Rect2(Vector2.ZERO, c.size), Color("ece8dc"))
	var r: RandomNumberGenerator = pp._rng("ticket" + str(front))
	if front:
		pp._rect(c, Rect2(0, 0, 860, 96), Color("2d3a48"))
		var ls := _lines(pr, "front")
		if not ls.is_empty():
			pp._text(c, str(ls[0][0]), Vector2(36, 18), "ui_b", 46, Color("ece8dc"), 4)
		for i in range(1, ls.size()):
			pp._text(c, str(ls[i][0]), Vector2(40, 120 + (i - 1) * 66), "mono", 46 if i < 3 else 52, ink)
		var bx := 40.0
		var on := true
		while bx < 600.0:
			var w := float(r.randi_range(3, 9))
			if on:
				pp._rect(c, Rect2(bx, 440, w, 70), ink)
			bx += w
			on = not on
		pp._text(c, "NOT VALID WITHOUT", Vector2(640, 444), "mono", 18, Color(ink, 0.6))
		pp._text(c, "A SAILING TIME", Vector2(640, 470), "mono", 18, Color(ink, 0.6))
	else:
		pp._rect(c, Rect2(0, 70, 860, 90), Color("3a2e24"))
		var small := ["VALID ONLY FOR THE SAILING SHOWN.", "NOT TRANSFERABLE. NO REFUNDS AFTER DEPARTURE.", "KEEP THIS TICKET UNTIL YOU DISEMBARK."]
		for i in small.size():
			pp._text(c, small[i], Vector2(40, 220 + i * 40), "mono", 24, Color(ink, 0.7))
	return sv


# The door float, out of the jacket's right pocket: the money in its clear bag, with the till tape
# round it. Printed side out on the front; turned over, his pencil on the back of the tape.
func _bag(pr: Dictionary, front: bool) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(900, 480), true)
	var c: Control = pp._page(sv)
	var r: RandomNumberGenerator = pp._rng("bag" + str(front))
	pp._rect(c, Rect2(Vector2.ZERO, c.size), Color("2a2c31"))
	# the stack of twenties, a little fanned
	var note := Rect2(170, 110, 560, 260)
	for k in 5:
		var off := Vector2(r.randf_range(-10, 10), r.randf_range(-8, 8))
		pp._rect(c, Rect2(note.position + off, note.size), Color("bfc2a8").darkened(0.05 * (4 - k)), 6)
	var ink := Color("4f5b4c")
	pp._rect(c, Rect2(note.position + Vector2(14, 14), note.size - Vector2(28, 28)), Color(ink, 0.12), 4)
	pp._text(c, "20", Vector2(note.position.x + 28, note.position.y + 18), "display", 78, ink)
	pp._text(c, "20", Vector2(note.end.x - 110, note.end.y - 104), "display", 78, ink)
	for k in 7:
		_ring(c, Vector2(note.position.x + 380, note.position.y + 130), Vector2(70 - k * 6, 90 - k * 7), Color(ink, 0.3), 1.4)
	# the till tape, round the middle of the stack
	var tape := Rect2(392, 70, 116, 340)
	pp._rect(c, tape, Color("f1eee4"))
	var ls := _lines(pr, "back")
	if front:
		var rows := ["THE SOV", "DOOR", "FLOAT", "--------", "400.00"]
		for i in rows.size():
			pp._text(c, rows[i], Vector2(tape.position.x + 10, tape.position.y + 30 + i * 42), "receipt", 22, Color(0.15, 0.15, 0.15, 0.75))
	else:
		for i in ls.size():
			pp._text(c, str(ls[i][0]).replace("    ", " ").replace("  ", " "), Vector2(tape.position.x + 6, tape.position.y + 26 + i * 64), "hand", 21, PENCIL)
		pp._rect(c, Rect2(tape.position.x + 8, tape.position.y + 26 + 3 * 64 - 8, 100, 2), PENCIL)
	# the zip, along the top of the bag, and the write-on panel
	pp._rect(c, Rect2(0, 0, 900, 46), Color("1b2130"))
	for x in range(10, 900, 16):
		pp._rect(c, Rect2(x, 18, 8, 10), Color("6c7380"))
	if front:
		var fl := _lines(pr, "front")
		pp._rect(c, Rect2(40, 390, 250, 66), Color("e4e1d6"), 3)
		pp._text(c, "AMOUNT", Vector2(52, 400), "ui_b", 16, Color("3d4250"), 2)
		if not fl.is_empty():
			pp._text(c, str(fl[0][0]), Vector2(150, 392), "hand", 40, PENCIL)
	return sv


# The paperback under the glove, its cover half off: two men in white, one thrown over his own
# wrist, head first, by the other; a price sticker from a yard sale.
func _book(pr: Dictionary, front: bool) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(440, 712), true)
	var c: Control = pp._page(sv)
	var blue := Color("23303f")
	var yellow := Color("e0b52e")
	var white := Color("ece8dc")
	pp._rect(c, Rect2(Vector2.ZERO, c.size), blue)
	if front:
		# the title as big as fits left of where the cover's torn
		var ls := _lines(pr, "front")
		var title := str(ls[0][0]) if not ls.is_empty() else ""
		var tf: Font = UiBits.spaced("anton", 6)
		var ts := 100
		while ts > 40 and tf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x > 278.0:
			ts -= 4
		pp._text(c, title, Vector2(40, 30), "anton", ts, yellow, 6)
		pp._text(c, "A BEGINNER'S GUIDE", Vector2(44, 40 + ts * 1.32), "ui_b", 18, Color(white, 0.8), 4)
		# the mat's edge, and on it the man in his hakama, his hands out; the other man over them in
		# the air, going down head first, his wrist in the first man's hand
		_stroke(c, _cvs([Vector2(40, 604), Vector2(400, 604)]), Color("3a485a"), 3.0)
		var hip := Vector2(160, 470)
		var sh := Vector2(172, 384)
		_poly(c, _cvs([hip + Vector2(-24, -8), hip + Vector2(24, -8), hip + Vector2(60, 130), hip + Vector2(-56, 130)]), white)
		_poly(c, _cvs([hip + Vector2(-2, 50), hip + Vector2(4, 50), hip + Vector2(6, 130), hip + Vector2(-4, 130)]), blue)
		_limb(c, [hip, sh], 44.0, white)
		_poly(c, _cvs([hip + Vector2(-26, -12), hip + Vector2(26, -12), hip + Vector2(26, -2), hip + Vector2(-26, -2)]), Color("101418"))
		_poly(c, _oval(_cv(sh + Vector2(9, -50)), Vector2.RIGHT, 23.0 * 0.9, 23.0 * 0.9), white)
		_limb(c, [sh + Vector2(12, 2), Vector2(226, 352), Vector2(270, 318)], 17.0, white)
		_limb(c, [sh + Vector2(4, 14), Vector2(206, 428), Vector2(252, 418)], 17.0, white)
		var uh := Vector2(322, 250)
		var us := Vector2(346, 352)
		_limb(c, [uh, us], 40.0, white)
		_poly(c, _oval(_cv(us + (us - uh).normalized() * 46.0), Vector2.RIGHT, 21.0 * 0.9, 21.0 * 0.9), white)
		_limb(c, [us + Vector2(-10, -6), Vector2(300, 328), Vector2(272, 318)], 15.0, white)
		_limb(c, [us + Vector2(12, 6), Vector2(388, 404), Vector2(402, 446)], 15.0, white)
		_limb(c, [uh, Vector2(284, 196), Vector2(300, 146)], 20.0, white)
		_limb(c, [uh, Vector2(350, 202), Vector2(392, 186)], 20.0, white)
		# the cover half off: the corner gone, and the first page under it
		_poly(c, PackedVector2Array([Vector2(300, 0), Vector2(440, 0), Vector2(440, 250), Vector2(420, 200), Vector2(400, 214), Vector2(392, 150),
			Vector2(366, 136), Vector2(360, 90), Vector2(328, 64), Vector2(322, 30)]), Color("efe9da"))
		# a yard sale's sticker
		_poly(c, _oval(Vector2(380, 676), Vector2.RIGHT, 30.0, 30.0), Color("e08a2e"))
		var price := _centred(c, "$1", 656, 140, "ui_b", 28, Color("2a1d10"))
		price.position.x = 310
	else:
		for i in 9:
			pp._rect(c, Rect2(50, 120 + i * 34, 340 - (i % 3) * 40, 12), Color(white, 0.35), 4)
		pp._rect(c, Rect2(250, 560, 150, 100), Color("ece8dc"))
		var r: RandomNumberGenerator = pp._rng("isbn")
		var x := 262.0
		while x < 388.0:
			var w := float(r.randi_range(2, 5))
			pp._rect(c, Rect2(x, 572, w, 64), Color("101418"))
			x += w + float(r.randi_range(2, 4))
	return sv


# The flyer folded into it for a bookmark: the class at the community hall.
func _flyer(pr: Dictionary) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(320, 420), true)
	var c: Control = pp._page(sv)
	pp._rect(c, Rect2(Vector2.ZERO, c.size), Color("f3efe2"))
	var ink := Color("2a3550")
	var ls := _lines(pr, "back")
	var y := 26.0
	for i in ls.size():
		var s := str(ls[i][0])
		var big := i == 1
		for part in s.split("  ", false):
			_centred(c, part.strip_edges(), y, 320, "ui_b" if big else "mono", 34 if big else 20, ink, 2 if big else 0)
			y += (34 if big else 20) * 1.5
		y += 10.0
	return sv


# The last doorman's jacket, folded at the bottom of the drawer: brown canvas, a corduroy collar,
# the flaps of its two outside pockets, the stitching gone pale.
func _jacket(_pr: Dictionary) -> SubViewport:
	var sv: SubViewport = pp._viewport(Vector2i(840, 680), true)
	var c: Control = pp._page(sv)
	var canvas := Color("6e5d3e")
	var thread := Color("a08c62")
	pp._rect(c, Rect2(Vector2.ZERO, c.size), canvas)
	var r: RandomNumberGenerator = pp._rng("jacket")
	for i in 220:
		pp._rect(c, Rect2(r.randf_range(0, 840), r.randf_range(0, 680), r.randf_range(20, 90), 1.2), Color(0, 0, 0, 0.06))
	# the sleeves folded in along the sides, the elbows gone pale
	for x in [0.0, 690.0]:
		pp._rect(c, Rect2(x, 0, 150, 680), canvas.darkened(0.08))
		pp._rect(c, Rect2(x + 30, 300, 90, 120), Color(canvas.lightened(0.25), 0.7), 30)
	# the collar
	var col := PackedVector2Array()
	for i in 25:
		var a := PI * i / 24.0
		col.append(Vector2(420, 0) + Vector2(-cos(a) * 200.0, sin(a) * 110.0))
	_stroke(c, col, Color("4a3b28"), 48.0)
	# the placket and its snaps, and the two flaps
	pp._rect(c, Rect2(416, 110, 8, 570), Color(0, 0, 0, 0.25))
	for y in [180, 300, 420, 540]:
		var sn := PackedVector2Array()
		for i in 16:
			sn.append(Vector2(446, y) + Vector2(cos(TAU * i / 16.0), sin(TAU * i / 16.0)) * 9.0)
		_poly(c, sn, Color("8d8d8d"))
	for x2: float in [200.0, 480.0]:
		pp._rect(c, Rect2(x2, 420, 170, 70), canvas.darkened(0.12), 4)
		var dash: float = x2 + 8.0
		while dash < x2 + 160.0:
			pp._rect(c, Rect2(dash, 478, 9, 2), thread)
			dash += 15.0
	return sv


# ---------------------------------------------------------------- in his hand

# The thing itself, built under `turn` (a node at the middle of it, which turning it over spins round
# its own up), for whatever holds it at `turn`'s parent: in his palm, its back on the palm (the
# anchor's z out of the palm, y up the fingers); held up like a licence, facing him; round a pint,
# nothing (the hand's model brings its glass); on the bar, flat. Returns the faces it has.
func build(id: String, pr: Dictionary, turn: Node3D) -> Dictionary:
	var out := {}
	var pub = pp.main.pub
	match str(pr.get("shape", "")):
		"flashlight":
			# two D cells in steel, across his palm: the body, the knurled grip, the head and its lens
			var steel: ShaderMaterial = pub.mat(Color("1d1e22"), 0.4, 0.55, 2, Vector3(1, 0, 0), 4.0, 0.8)
			turn.position.z = 0.021
			_cyl(0.019, 0.019, 0.17, steel, turn, Vector3(0.02, 0, 0), Vector3(0, 0, 90))
			_cyl(0.0205, 0.0205, 0.07, pub.mat(Color("16171a"), 0.6, 0.4, 2, Vector3(0, 1, 0), 3.0, 1.0), turn, Vector3(0.05, 0, 0), Vector3(0, 0, 90))
			_cyl(0.029, 0.021, 0.06, steel, turn, Vector3(-0.09, 0, 0), Vector3(0, 0, 90))
			_cyl(0.026, 0.026, 0.004, pub.glow(Color("e9e4cf"), 0.5), turn, Vector3(-0.1215, 0, 0), Vector3(0, 0, 90))
			_box(Vector3(0.016, 0.008, 0.006), pub.mat(Color("3a3b40"), 0.5, 0.0, 3), turn, Vector3(-0.045, 0, 0.019))
		"key":
			# the key to twelve on its fob, the fob across his fingers
			var brass: ShaderMaterial = pub.mat(Color("b39550"), 0.35, 0.8, 3)
			turn.position.z = 0.004
			var fob := _quad(Vector2(0.074, 0.04), _print("thing_%s_front" % id, true), turn, Vector3(-0.005, 0.03, 0.002), Vector3(0, 0, 20))
			var fob_b := _quad(Vector2(0.074, 0.04), _print("thing_%s_back" % id, true), turn, Vector3(-0.005, 0.03, -0.002), Vector3(0, 180, -20))
			out.faces = [fob, fob_b]
			_torus(0.008, 0.0105, brass, turn, Vector3(-0.036, 0.018, 0.0), Vector3(90, 0, 0))
			_box(Vector3(0.008, 0.05, 0.0022), brass, turn, Vector3(-0.044, -0.022, 0.0))
			_box(Vector3(0.014, 0.016, 0.0024), brass, turn, Vector3(-0.044, 0.008, 0.0))
			for k in 3:
				_box(Vector3(0.004, 0.005, 0.0022), brass, turn, Vector3(-0.038, -0.03 - k * 0.012 + (k % 2) * 0.004, 0.0))
		"keys":
			# the big man's keys: the ring, his truck's key, his house key, and a rabbit's foot gone grey
			var chrome: ShaderMaterial = pub.mat(Color("c9ccd0"), 0.25, 1.0, 3)
			turn.position.z = 0.006
			_torus(0.011, 0.0135, chrome, turn, Vector3(0, 0.0, 0.0), Vector3(90, 0, 0))
			var blk: ShaderMaterial = pub.mat(Color("18181a"), 0.55, 0.0, 3)
			_box(Vector3(0.024, 0.034, 0.009), blk, turn, Vector3(0.026, -0.03, 0.0), Vector3(0, 0, 28))
			_box(Vector3(0.008, 0.038, 0.0022), chrome, turn, Vector3(0.045, -0.062, -0.001), Vector3(0, 0, 28))
			var brass2: ShaderMaterial = pub.mat(Color("b39550"), 0.35, 0.8, 3)
			_cyl(0.012, 0.012, 0.0024, brass2, turn, Vector3(-0.02, -0.022, 0.0), Vector3(90, 0, 0))
			_box(Vector3(0.007, 0.036, 0.0022), brass2, turn, Vector3(-0.03, -0.05, 0.0), Vector3(0, 0, -18))
			var fur: ShaderMaterial = pub.mat(Color("8f8b84"), 1.0, 0.0, 4, Vector3(0, 1, 0), 3.0, 0.6)
			var foot := _capsule(0.012, 0.062, fur, turn, Vector3(0.0, 0.05, 0.004), Vector3(0, 0, 8))
			foot.scale = Vector3(1.0, 1.0, 0.8)
			_cyl(0.006, 0.006, 0.008, chrome, turn, Vector3(0.0, 0.017, 0.004))
		"straw":
			# two inches of straw, cut square at both ends
			turn.position.z = 0.0035
			_cyl(0.0032, 0.0032, 0.051, pub.mat(Color("ebe8e0"), 0.3, 0.0, 3), turn, Vector3(0, 0.01, 0), Vector3(0, 0, 62))
		"shirt":
			# folded, on his fingers as they curl
			turn.position.z = 0.05
			_box(Vector3(0.23, 0.25, 0.024), pub.mat(Color("222327"), 0.95, 0.0, 4, Vector3(0, 1, 0), 5.5, 0.8), turn, Vector3(0, 0.04, 0))
			out.faces = [_quad(Vector2(0.23, 0.25), _print("thing_%s_front" % id), turn, Vector3(0, 0.04, 0.0125)),
				_quad(Vector2(0.23, 0.25), _print("thing_%s_back" % id), turn, Vector3(0, 0.04, -0.0125), Vector3(0, 180, 0))]
		"bill":
			# folded small, held up the way he holds a licence, its top edge where a card's would be
			out.faces = [_quad(Vector2(0.076, 0.034), _print("thing_%s_front" % id), turn, Vector3(0, 0.01, 0.0006)),
				_quad(Vector2(0.076, 0.034), _print("thing_%s_back" % id), turn, Vector3(0, 0.01, -0.0006), Vector3(0, 180, 0))]
			_box(Vector3(0.076, 0.034, 0.0011), pub.mat(Color("cfc8b1"), 0.9, 0.0, 3), turn, Vector3(0, 0.01, 0))
		"mat":
			out.faces = [_quad(Vector2(0.1, 0.1), _print("thing_%s_front" % id, true), turn, Vector3(0, 0.02, 0.0013)),
				_quad(Vector2(0.1, 0.1), _print("thing_%s_back" % id, true), turn, Vector3(0, 0.02, -0.0013), Vector3(0, 180, 0))]
		"tickets":
			# two, one behind the other, neither torn
			var faces: Array = []
			for k in 2:
				var at := Vector3(0.012 * k, 0.008 * k, -0.0016 * k)
				faces.append(_quad(Vector2(0.086, 0.054), _print("thing_%s_front" % id), turn, at + Vector3(0, 0, 0.0003), Vector3(0, 0, -5.0 * k)))
				faces.append(_quad(Vector2(0.086, 0.054), _print("thing_%s_back" % id), turn, at + Vector3(0, 0, -0.0003), Vector3(0, 180, 5.0 * k)))
			out.faces = faces
		"bag":
			turn.position.z = 0.048
			out.faces = [_quad(Vector2(0.27, 0.144), _print("thing_%s_front" % id), turn, Vector3(0, 0.03, 0.0095)),
				_quad(Vector2(0.27, 0.144), _print("thing_%s_back" % id), turn, Vector3(0, 0.03, -0.0095), Vector3(0, 180, 0))]
			_box(Vector3(0.276, 0.15, 0.02), pub.glass(Color("dfe6e8"), 0.18), turn, Vector3(0, 0.03, 0))
		"book":
			turn.position.z = 0.045
			_box(Vector3(0.108, 0.176, 0.02), pub.mat(Color("efe9da"), 0.9, 0.0, 2, Vector3(1, 0, 0), 3.0, 0.8), turn, Vector3(0, 0.03, 0))
			out.faces = [_quad(Vector2(0.11, 0.178), _print("thing_%s_front" % id), turn, Vector3(0, 0.03, 0.0102)),
				_quad(Vector2(0.11, 0.178), _print("thing_%s_back" % id), turn, Vector3(0, 0.03, -0.0102), Vector3(0, 180, 0))]
			# the spine, and the flyer sticking out of the top of the pages
			_box(Vector3(0.004, 0.178, 0.021), pub.mat(Color("23303f"), 0.8, 0.0, 3), turn, Vector3(-0.055, 0.03, 0))
			_quad(Vector2(0.06, 0.06), _print("thing_%s_flyer" % id), turn, Vector3(0.018, 0.13, 0.001), Vector3(0, 0, -6))
		"jacket":
			turn.position.z = 0.035
			_box(Vector3(0.42, 0.34, 0.07), pub.mat(Color("6e5d3e"), 0.95, 0.0, 4, Vector3(0, 1, 0), 5.5, 0.8), turn, Vector3.ZERO)
			out.faces = [_quad(Vector2(0.42, 0.34), _print("thing_%s_front" % id), turn, Vector3(0, 0, 0.0355))]
	return out


# a printed face: clean, no key block cut on it, and where it isn't square, cut to its shape
func _print(name: String, shaped := false) -> ShaderMaterial:
	var m: ShaderMaterial = pp._surface(pp.tex.get(name))
	if pp.tex.get(name) == null:
		pp.rush(name, m)
	if shaped:
		m.set_shader_parameter("alpha_scissor", 0.5)
	return m


func _place(mi: Node3D, parent: Node3D, pos: Vector3, rot: Vector3) -> void:
	mi.position = pos
	mi.rotation_degrees = rot
	if mi is GeometryInstance3D:
		(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _quad(size: Vector2, m: Material, parent: Node3D, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = m
	_place(mi, parent, pos, rot)
	return mi


func _box(size: Vector3, m: Material, parent: Node3D, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = m
	_place(mi, parent, pos, rot)
	return mi


# a cylinder along its own y (turn it to lie along x: 0, 0, 90)
func _cyl(r_top: float, r_bottom: float, h: float, m: Material, parent: Node3D, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = r_top
	cy.bottom_radius = r_bottom
	cy.height = h
	cy.radial_segments = 24
	cy.rings = 1
	mi.mesh = cy
	mi.material_override = m
	_place(mi, parent, pos, rot)
	return mi


func _capsule(r: float, h: float, m: Material, parent: Node3D, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cp := CapsuleMesh.new()
	cp.radius = r
	cp.height = h
	mi.mesh = cp
	mi.material_override = m
	_place(mi, parent, pos, rot)
	return mi


# a ring lying in its own xz plane
func _torus(inner: float, outer: float, m: Material, parent: Node3D, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 24
	t.ring_segments = 8
	mi.mesh = t
	mi.material_override = m
	_place(mi, parent, pos, rot)
	return mi
