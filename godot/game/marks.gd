# The voices' marks: when a voice talks about something he can see, it marks it on the world, in its
# own hand and colour: a ring round the big man, a box round the propped door, a cross on the empty
# stool, a word written by it. (In the browser build the voice pulled that part of the place's
# picture out beside its line; here the place is all round him, so the mark goes on the room.)
#
# A mark is pinned to the thing in the room and moves with it as he turns his head. When the thing
# is off the edge of his eyes but in the room he's in, a pen tick at the edge points the way. The
# marks fade on their own, and when he chooses.
class_name Marks
extends Control

const LIFE := 38.0
const DRAW := 0.5

# Where each of the voices' spots is in the room (content/data/marks.yaml names them by place and
# spot): a shape round a point, a box round a block, a line between two points, or a figure.
#   ring  [centre, radius in metres, how tall against wide]
#   cross [centre, radius]
#   box   [centre, half size]
#   line  [from, to]
#   tally [centre, how many]
#   fig   [who, what part]      (the part: "" for the whole of them, or an anchor, hand_left...)
const SPOTS := {
	"door.stool": ["ring", Vector3(1.7, 0.78, 8.85), 0.26, 0.45, "door"],
	"door.empty": ["cross", Vector3(1.7, 0.78, 8.85), 0.2, 0.0, "door"],
	"door.mat": ["box", Vector3(3.2, 0.02, 9.45), Vector3(0.9, 0.02, 0.5), 0.0, "door"],
	"door.door": ["box", Vector3(3.2, 1.15, 10.1), Vector3(0.9, 1.15, 0.05), 0.0, "door"],
	"door.minors": ["ring", Vector3(2.157, 1.4, 9.99), 0.11, 0.5, "door"],
	"pool.lefthand": ["fig", "bigman", "hand_left", 0.09, "room"],
	"pool.bigman": ["fig", "bigman", "", 0.0, "room"],
	"pool.buddy": ["fig", "buddy", "", 0.0, "room"],
	"pool.table": ["box", Vector3(9.4, 0.8, 3.9), Vector3(1.3, 0.08, 0.72), 0.0, "room"],
	"pool.three": ["ring", Vector3(8.95, 0.83, 3.96), 0.06, 0.8, "room"],
	"t28.table": ["ring", Vector3(9.4, 0.8, 8.1), 1.25, 0.32, "room"],
	"t28.glasses": ["line", Vector3(8.8, 0.78, 7.7), Vector3(10.0, 0.78, 7.7), 0.0, "room"],
	"t28.under": ["ring", Vector3(9.7, 0.1, 8.95), 0.4, 0.3, "room"],
	"bar.three": ["tally", Vector3(2.15, 1.14, 3.3), 3, 0.0, "room"],
	"bar.bartender": ["fig", "bartender", "", 0.0, "room"],
	"bar.till": ["box", Vector3(1.75, 1.25, 7.3), Vector3(0.2, 0.15, 0.18), 0.0, "room"],
	"kitchen.backdoor": ["box", Vector3(-0.1, 1.02, -1.55), Vector3(0.05, 1.02, 0.45), 0.0, "kitchen"],
	"kitchen.cook": ["fig", "cook", "", 0.0, "kitchen"],
	"keg.dark": ["ring", Vector3(2.4, -2.2, -1.7), 0.7, 0.35, "keg"],
	"keg.hole": ["ring", Vector3(2.9, -2.35, -2.45), 0.2, 0.7, "keg"],
	"deck.door": ["box", Vector3(16.06, 1.14, 7.1), Vector3(0.05, 1.15, 0.6), 0.0, "deck"],
	"deck.latch": ["ring", Vector3(16.02, 1.02, 7.66), 0.07, 1.0, "deck"],
	"lot.truck": ["ring", Vector3(9.2, 1.0, 15.8), 2.3, 0.42, "lot"],
	"lot.window": ["ring", Vector3(14.6, 4.5, 10.25), 0.6, 1.0, "lot"],
	"hall.single": ["box", Vector3(11.94, 1.02, -1.21), Vector3(0.37, 1.02, 0.05), 0.0, "hall"],
	"hall.signs": ["box", Vector3(8.64, 1.6, -1.19), Vector3(0.14, 0.19, 0.02), 0.0, "hall"],
	"hall.wall": ["ring", Vector3(13.86, 1.5, -2.6), 0.62, 0.85, "hall"],
	"floor.pool": ["ring", Vector3(9.4, 0.8, 3.9), 1.55, 0.32, "room"],
	"floor.t28": ["ring", Vector3(9.4, 0.8, 8.1), 1.3, 0.32, "room"],
}
# the places he can be, and the parts of the building a mark can be in that he can turn and see
const REACH := {
	"door": ["door", "room", "lot"], "floor": ["room", "door"], "bar": ["room", "door"], "t28": ["room", "door", "lot"],
	"pool": ["room", "door"], "hall": ["hall"], "kitchen": ["kitchen"], "keg": ["keg"], "deck": ["deck", "lot"],
	"lot": ["lot", "door"], "upstairs": ["lot"],
}

var view: View
var stage: Stage
var pub: Pub
var content: Dictionary
var marks: Array = []            # {spot, note, color, font, born, seed, fade}
var t := 0.0


func setup(v: View, s: Stage, p: Pub, c: Dictionary) -> void:
	view = v
	stage = s
	pub = p
	content = c
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func add(mk, style: String, live: bool) -> void:
	if not live or not (mk is Dictionary):
		return
	var v := Look.voice(style)
	for s in mk.get("spots", []):
		var at := str(s.get("at", ""))
		if not SPOTS.has(at):
			continue
		for m in marks:
			if m.spot == at:
				m.fade = t
		marks.append({"spot": at, "note": str(s.get("note", "")), "color": Look.voice_color(style), "font": str(v.get("font", "hand")),
			"born": t + 0.15 * marks.size(), "seed": randi(), "fade": -1.0})


func clear() -> void:
	marks.clear()
	queue_redraw()


# he's chosen: the marks go, over a moment
func fade_all() -> void:
	for m in marks:
		if m.fade < 0.0:
			m.fade = t


func _process(dt: float) -> void:
	t += dt
	var keep: Array = []
	for m in marks:
		var gone: float = m.fade if m.fade >= 0.0 else m.born + LIFE
		if t < gone + 0.8:
			keep.append(m)
	marks = keep
	if not marks.is_empty() or t < 0.5:
		queue_redraw()


# ---------------------------------------------------------------- drawing in his head's hand

func _screen(p: Vector3) -> Vector3:
	var s := view.on_screen(p)
	if s.z <= 0.0:
		return s
	return Vector3(s.x - global_position.x, s.y - global_position.y, 1.0)


# how many pixels a length in metres is, at a point in the world
func _px(p: Vector3, r: float) -> float:
	var right := view.cam.global_transform.basis.x
	var a := _screen(p)
	var b := _screen(p + right * r)
	if a.z <= 0.0 or b.z <= 0.0:
		return 0.0
	return Vector2(b.x - a.x, b.y - a.y).length()


func _draw() -> void:
	if view == null:
		return
	for m in marks:
		var age: float = t - m.born
		if age < 0.0:
			continue
		var grow := clampf(age / DRAW, 0.0, 1.0)
		var alpha := 1.0
		var end: float = m.fade if m.fade >= 0.0 else m.born + LIFE
		if t > end:
			alpha = clampf(1.0 - (t - end) / 0.8, 0.0, 1.0)
		var c: Color = m.color
		c.a = 0.92 * alpha
		_mark(m, grow, c)


func _mark(m: Dictionary, grow: float, c: Color) -> void:
	var sp: Array = SPOTS[m.spot]
	var kind: String = sp[0]
	var zone: String = sp[4]
	if not zone in REACH.get(view.place, []):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = m.seed
	var w := 2.6
	var centre := Vector3.ZERO
	var note_at := Vector2.ZERO
	match kind:
		"ring", "cross", "tally":
			centre = sp[1]
		"box":
			centre = sp[1]
		"line":
			centre = (sp[1] + sp[2]) / 2.0
		"fig":
			if not stage.present(sp[1]):
				return
			if sp[2] == "":
				var f = stage.figures.get(sp[1])
				centre = (f.node as Node3D).global_position + Vector3(0, 0.95, 0)
			else:
				var f2 = stage.figures.get(sp[1])
				var a: Array = f2.anchors.get(sp[2], [0, 1.0, 0])
				centre = (f2.node as Node3D).to_global(Vector3(a[0], a[1], a[2]))
	var s := _screen(centre)
	var r := Rect2(Vector2.ZERO, size)
	if s.z <= 0.0 or not r.grow(-8).has_point(Vector2(s.x, s.y)):
		_edge(centre, m, c)
		return
	var p := Vector2(s.x, s.y)
	match kind:
		"ring":
			var rx := maxf(_px(centre, sp[2]), 7.0)
			var ry := rx * float(sp[3])
			var fit := _fit(p, rx + 6.0, ry + 5.0)
			_ring(Vector2(fit.x, fit.y), fit.z, fit.w, grow, c, w, rng)
			note_at = Vector2(fit.x, fit.y) + Vector2(fit.z + 4.0, -fit.w - 1.0)
		"fig":
			if sp[2] == "":
				var rx2 := maxf(_px(centre, 0.42), 10.0)
				var fit2 := _fit(p, rx2, rx2 * 1.9)
				_ring(Vector2(fit2.x, fit2.y), fit2.z, fit2.w, grow, c, w, rng)
				note_at = Vector2(fit2.x, fit2.y) + Vector2(fit2.z + 8.0, -fit2.w)
			else:
				var rx3 := maxf(_px(centre, float(sp[3])), 7.0)
				_ring(p, rx3 + 5.0, rx3 * 0.8 + 5.0, grow, c, w, rng)
				note_at = p + Vector2(rx3 + 10.0, -rx3 - 4.0)
		"cross":
			var rr := maxf(_px(centre, sp[2]), 9.0)
			_line(p + Vector2(-rr, -rr), p + Vector2(rr, rr), clampf(grow * 2.0, 0.0, 1.0), c, w + 0.6, rng)
			_line(p + Vector2(rr, -rr), p + Vector2(-rr, rr), clampf(grow * 2.0 - 1.0, 0.0, 1.0), c, w + 0.6, rng)
			note_at = p + Vector2(rr + 8.0, -rr)
		"box":
			var box := _box_rect(centre, sp[2])
			if box.size == Vector2.ZERO:
				return
			# a thing bigger than his eyes (the door, from the stool) gets its box drawn inside the
			# view, so it reads as a box and not a stray line down one side
			box = box.grow(5.0).intersection(Rect2(Vector2(18, 18), size - Vector2(36, 36)))
			if box.size.x < 12.0 or box.size.y < 12.0:
				return
			var pts := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y), box.position + Vector2(6, -2)]
			var n := pts.size() - 1
			for i in n:
				var g := clampf(grow * n - i, 0.0, 1.0)
				if g > 0.0:
					_line(pts[i] + _j(rng, 2.0), pts[i + 1] + _j(rng, 2.0), g, c, w, rng)
			note_at = Vector2(box.end.x + 8.0, box.position.y - 2.0)
		"line":
			var a := _screen(sp[1])
			var b := _screen(sp[2])
			if a.z <= 0.0 or b.z <= 0.0:
				return
			var pa := Vector2(a.x, a.y) + Vector2(0, 6)
			var pb := Vector2(b.x, b.y) + Vector2(0, 6)
			_line(pa, pb, grow, c, w, rng)
			_line(pa + Vector2(4, 5), pb + Vector2(-2, 4), clampf(grow * 1.4 - 0.4, 0.0, 1.0), c, w * 0.8, rng)
			note_at = pb + Vector2(8, -6)
		"tally":
			var n2 := int(sp[2])
			var h := 22.0
			for i in n2:
				var g2 := clampf(grow * n2 - i, 0.0, 1.0)
				var x := p.x + i * 9.0 - n2 * 4.5
				if g2 > 0.0:
					_line(Vector2(x, p.y - h / 2.0) + _j(rng, 1.5), Vector2(x + 2.0, p.y + h / 2.0) + _j(rng, 1.5), g2, c, w, rng)
			note_at = p + Vector2(n2 * 5.0 + 10.0, -h / 2.0)
	if m.note != "" and grow >= 1.0:
		var nw := Look.font("hand").get_string_size(m.note, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		note_at.x = clampf(note_at.x, 10.0, maxf(10.0, size.x - nw - 12.0))
		note_at.y = clampf(note_at.y, 30.0, size.y - 12.0)
		_note(note_at, m, c)


# A ring round something close enough to fill his eyes (the table he's sitting at) is kept inside
# the view, so the pen goes round what he sees of it instead of off the edges: (x, y, rx, ry).
func _fit(p: Vector2, rx: float, ry: float) -> Vector4:
	rx = minf(rx, size.x * 0.44)
	ry = minf(ry, size.y * 0.44)
	var x := clampf(p.x, minf(rx + 16.0, size.x / 2.0), maxf(size.x - rx - 16.0, size.x / 2.0))
	var y := clampf(p.y, minf(ry + 16.0, size.y / 2.0), maxf(size.y - ry - 16.0, size.y / 2.0))
	return Vector4(x, y, rx, ry)


func _j(rng: RandomNumberGenerator, a: float) -> Vector2:
	return Vector2(rng.randf_range(-a, a), rng.randf_range(-a, a))


# a ring drawn the way a pen draws one fast: a little past where it started, not quite round
func _ring(p: Vector2, rx: float, ry: float, grow: float, c: Color, w: float, rng: RandomNumberGenerator) -> void:
	var start := rng.randf_range(0.0, TAU)
	var turns := rng.randf_range(1.06, 1.16)
	var wob := rng.randf_range(0.04, 0.08)
	var tilt := rng.randf_range(-0.12, 0.12)
	var n := 56
	var pts := PackedVector2Array()
	var upto := int(n * grow)
	for i in upto + 1:
		var f := float(i) / n
		var a := start + TAU * turns * f
		var k := 1.0 + wob * sin(a * 2.0 + start) + 0.035 * f
		var q := Vector2(cos(a) * rx * k, sin(a) * ry * k).rotated(tilt)
		pts.append(p + q)
	if pts.size() >= 2:
		draw_polyline(pts, c, w, true)


func _line(a: Vector2, b: Vector2, grow: float, c: Color, w: float, rng: RandomNumberGenerator) -> void:
	if grow <= 0.0:
		return
	var n := 10
	var pts := PackedVector2Array()
	var bow := rng.randf_range(-0.03, 0.03) * a.distance_to(b)
	var nrm := (b - a).orthogonal().normalized()
	for i in n + 1:
		var f := float(i) / n * grow
		pts.append(a.lerp(b, f) + nrm * bow * sin(f * PI))
	draw_polyline(pts, c, w, true)


func _note(at: Vector2, m: Dictionary, c: Color) -> void:
	var f: Font = Look.font("hand")
	var fs := 26
	draw_set_transform(at, -0.06, Vector2.ONE)
	draw_string(f, Vector2(1, 1), m.note, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Look.NIGHT, c.a * 0.6))
	draw_string(f, Vector2.ZERO, m.note, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# the screen's rectangle round a block in the world
func _box_rect(centre: Vector3, half: Vector3) -> Rect2:
	var r := Rect2()
	var first := true
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				var s := _screen(centre + Vector3(half.x * sx, half.y * sy, half.z * sz))
				if s.z <= 0.0:
					return Rect2()
				var q := Vector2(s.x, s.y)
				if first:
					r = Rect2(q, Vector2.ZERO)
					first = false
				else:
					r = r.expand(q)
	return r


# The thing's off the edge of his eyes: a pen tick at the edge the way it is, and its word.
func _edge(p: Vector3, m: Dictionary, c: Color) -> void:
	var local := view.cam.global_transform.affine_inverse() * p
	var dir := Vector2(local.x, -local.y)
	if local.z > 0.0 and absf(local.x) < 0.2:
		dir = Vector2(1.0 if local.x >= 0.0 else -1.0, 0.0)
	if dir.length() < 0.001:
		return
	dir = dir.normalized()
	var mid := size / 2.0
	var k := minf((mid.x - 34.0) / maxf(absf(dir.x), 0.001), (mid.y - 34.0) / maxf(absf(dir.y), 0.001))
	var at := mid + dir * k
	var pulse := 0.75 + 0.25 * sin(t * 3.0)
	var cc := Color(c, c.a * pulse)
	var back := -dir * 22.0
	var side := dir.orthogonal() * 9.0
	draw_polyline(PackedVector2Array([at + back + side, at, at + back - side]), cc, 3.0, true)
	if m.note != "":
		var f: Font = Look.font("hand")
		var ts := f.get_string_size(m.note, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		var np := at + back * 1.6 - Vector2(ts.x / 2.0, -8.0)
		np.x = clampf(np.x, 8.0, size.x - ts.x - 8.0)
		np.y = clampf(np.y, 24.0, size.y - 8.0)
		draw_string(f, np, m.note, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, cc)
