# A voice's mask: each voice in his head has a face, cut like the people's (the masks, Ensor and
# Redon), printed in the voice's own ink. It sits in the page's gutter beside what the voice says,
# in the head of the page with the others who have a seat, and in the room by the thing it's on
# about when the page is folded away.
#
#   father    his dead dad: long face, flat cap, heavy lids, the moustache he kept when he quit
#   fighter   the man he trained with: flat nose, a swollen eye, tape on the brow, an ear gone to gristle
#   manual    the course binder: a plate with ring holes, the eyes punched reinforcements, a ruled mouth
#   wrongman  the story retold: drawn twice and never in the same place, and redrawn each time it talks
#   table     table 28: four heads in one, all talking at once, over the table tent
#   kid       the kid: the hood, the eyes on the floor, the wires of the earbuds
#   till      Gary's: the adding machine, two keys for eyes, the tape coming out the top
#   senior    Gary's father: an oval photograph, spectacles, a parting
#
# The lines are drawn by hand, a little different on every draw, and redrawn on twos while it
# talks (the boil of a drawn film), slower when it's quiet. It blinks. Its mouth works while its
# words come in. It leans in when it speaks, goes back when it's done, and goes faint when it's
# been put out of the room.
class_name VoiceMask
extends Control

var style := "father"
var ink := Color("dcab5e")
var talk := 0.0           # 0..1: how hard it's talking now; eases back on its own
var lean := 0.0           # 0..1: leaning in
var faint := false        # put out of the room
var shake := 0.0          # a jolt (the fighter coming in)
var still := false        # a picture: no boil, no blink (tests)

var _seed := 0
var _boil := 0.0
var _blink_in := 2.0
var _lid := 0.0           # 0 open, 1 shut
var _retell := 0          # the wrong man: which telling


func _init(st := "father", px := 64.0) -> void:
	style = st
	ink = Look.voice_color(st)
	custom_minimum_size = Vector2(px, px * 1.15)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed = randi()
	_blink_in = randf_range(1.0, 5.0)


# it speaks: mouth and lean for a while; the wrong man is told again, a little differently
func say(seconds := 1.2) -> void:
	talk = clampf(seconds, 0.4, 4.0)
	if style == "wrongman":
		_retell += 1
	if style == "fighter":
		shake = 1.0
	queue_redraw()


func _process(dt: float) -> void:
	if still:
		return
	var t_was := talk
	talk = maxf(0.0, talk - dt)
	lean = move_toward(lean, 1.0 if talk > 0.0 else 0.0, dt * (5.0 if talk > 0.0 else 1.6))
	shake = maxf(0.0, shake - dt * 4.0)
	_boil += dt
	var step := 1.0 / 12.0 if talk > 0.0 else 0.55
	var redraw := t_was != talk or shake > 0.0
	if _boil >= step:
		_boil = 0.0
		_seed += 1
		redraw = true
	_blink_in -= dt
	if _blink_in <= 0.0:
		_lid = 1.0
		_blink_in = randf_range(2.2, 6.5) if style != "fighter" else randf_range(1.5, 3.0)
		redraw = true
	elif _lid > 0.0:
		_lid = maxf(0.0, _lid - dt * 7.0)
		redraw = true
	if redraw:
		queue_redraw()


# ------------------------------------------------------------------ drawing

var _rng := RandomNumberGenerator.new()
var _w := 2.0
var _box := Rect2()


func _draw() -> void:
	_rng.seed = hash(_seed if not still else 7) ^ hash(style)
	var s := minf(size.x, size.y / 1.15)
	var grow := 1.0 + 0.1 * lean
	var side := Vector2(s, s * 1.15) * grow
	var off := (size - side) * 0.5 + Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * 3.0 * shake
	_box = Rect2(off, side)
	_w = maxf(1.2, s / 34.0)
	var a := 0.38 if faint else 1.0
	var c := Color(ink, a)
	_k = Color(Look.NIGHT, 1.0)
	match style:
		"father": _father(c)
		"fighter": _fighter(c)
		"manual": _manual(c)
		"wrongman": _wrongman(c)
		"table": _table(c)
		"kid": _kid(c)
		"till": _till(c)
		"senior": _senior(c)
		_: _father(c)


# a point in the mask's own square (0..1 across, 0..1.15 down)
func P(x: float, y: float) -> Vector2:
	return _box.position + Vector2(x, y) * _box.size.x


func _j(v: Vector2, amt := 0.006) -> Vector2:
	return v + Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * amt * _box.size.x


# a stroke through points, each one nudged, thick in the middle and thin at the ends like a cut
func _stroke(pts: Array, c: Color, w := 1.0) -> void:
	if pts.size() < 2:
		return
	var out := PackedVector2Array()
	for p in pts:
		out.append(_j(p))
	draw_polyline(out, c, _w * w, true)


func _ellipse(cx: float, cy: float, rx: float, ry: float, n := 28, a0 := 0.0, a1 := TAU) -> Array:
	var pts := []
	for i in n + 1:
		var t := lerpf(a0, a1, float(i) / n)
		pts.append(P(cx + cos(t) * rx * _rng.randf_range(0.97, 1.03), cy + sin(t) * ry * _rng.randf_range(0.97, 1.03)))
	return pts


func _fill(pts: Array, c: Color) -> void:
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(p)
	if poly.size() >= 3 and Geometry2D.triangulate_polygon(poly).size() > 0:
		draw_colored_polygon(poly, c)


# the cut lines of a shadow: slanting strokes inside an ellipse, on one side of it
func _hatch_ellipse(cx: float, cy: float, rx: float, ry: float, from_x: float, c: Color, gap := 0.045, slant := 0.5) -> void:
	var y := cy - ry
	while y < cy + ry:
		var dy := (y - cy) / ry
		var half := rx * sqrt(maxf(0.0, 1.0 - dy * dy))
		var x0 := maxf(cx + from_x * rx, cx - half)
		var x1 := cx + half
		if x1 - x0 > 0.02:
			var a := P(x0, y)
			var b := P(x1, y - (x1 - x0) * slant * 0.4)
			_stroke([a, b], Color(c, c.a * 0.55), 0.55)
		y += gap


var _k := Color()          # the cut: the night showing through the ink


func _eye(cx: float, cy: float, rx: float, ry: float, c: Color, look := Vector2.ZERO, lid_rest := 0.0) -> void:
	var lid := clampf(maxf(_lid, lid_rest), 0.0, 1.0)
	# the socket cut deep, the mask's way
	_fill(_ellipse(cx, cy, rx * 1.35, ry * 2.1, 14), _k)
	var open := ry * (1.0 - lid)
	if open < ry * 0.15:
		_stroke([P(cx - rx, cy), P(cx, cy + ry * 0.35), P(cx + rx, cy)], c, 1.0)
		return
	# the eye drawn big, and a hard bead of light in it
	var pr := minf(rx * 0.5, open * 0.9)
	var pc := P(cx + look.x * rx * 0.45, cy + look.y * open * 0.45)
	draw_circle(pc, pr * _box.size.x, c)
	draw_circle(pc + Vector2(look.x * 0.2, look.y * 0.2) * pr * _box.size.x, pr * _box.size.x * 0.5, _k)
	# the lid's edge across it
	if lid > 0.05:
		_fill([P(cx - rx * 1.3, cy - ry * 2.1), P(cx + rx * 1.3, cy - ry * 2.1), P(cx + rx * 1.3, cy - ry * 2.0 + ry * 3.0 * lid), P(cx - rx * 1.3, cy - ry * 2.0 + ry * 3.0 * lid)], c)
		_stroke([P(cx - rx * 1.2, cy - ry * 2.0 + ry * 3.0 * lid), P(cx + rx * 1.2, cy - ry * 2.0 + ry * 3.0 * lid)], _k, 0.9)


func _mouth(cx: float, cy: float, w: float, c: Color, open_max := 0.05) -> void:
	var o := open_max * clampf(talk * 1.4, 0.0, 1.0) * (0.55 + 0.45 * sin(float(_seed) * 1.7))
	_stroke([P(cx - w, cy), P(cx - w * 0.3, cy - 0.006), P(cx + w * 0.3, cy - 0.004), P(cx + w, cy + 0.004)], _k, 1.4)
	if o > 0.008:
		var lip := [P(cx - w * 0.85, cy + 0.002)]
		for i in 7:
			var t := float(i) / 6.0
			lip.append(P(cx - w * 0.85 + 1.7 * w * t, cy + o * sin(t * PI)))
		_fill(lip, _k)


# the shadow side cut away in lines: the night showing between them, more of it toward the edge
func _cuts(cx: float, cy: float, rx: float, ry: float, from_x := 0.2, gap := 0.05) -> void:
	var y := cy - ry
	while y < cy + ry:
		var dy := (y - cy) / ry
		var half := rx * sqrt(maxf(0.0, 1.0 - dy * dy))
		var x0 := maxf(cx + from_x * rx, cx - half)
		var x1 := cx + half
		if x1 - x0 > 0.02:
			_stroke([P(x0, y), P(x1, y - (x1 - x0) * 0.25)], _k, 0.75)
		y += gap


func _plate(pts: Array, c: Color) -> void:
	_fill(pts, c)
	_stroke(pts, c, 1.2)


func _father(c: Color) -> void:
	var plate := _ellipse(0.5, 0.64, 0.29, 0.43, 30)
	_plate(plate, c)
	_cuts(0.5, 0.64, 0.29, 0.43, 0.35)
	# the cap pulled down, its brim a cut
	_fill([P(0.16, 0.38), P(0.2, 0.2), P(0.46, 0.11), P(0.74, 0.15), P(0.86, 0.3), P(0.88, 0.39)], c)
	_stroke([P(0.1, 0.41), P(0.5, 0.37), P(0.94, 0.4)], _k, 1.3)
	_stroke([P(0.12, 0.44), P(0.5, 0.4), P(0.92, 0.43)], c, 1.8)
	# brows like a ledge over sockets gone dark, the lids most of the way down
	_eye(0.37, 0.54, 0.07, 0.035, c, Vector2(0.15, 0.4), 0.5)
	_eye(0.64, 0.54, 0.07, 0.035, c, Vector2(0.15, 0.4), 0.5)
	_stroke([P(0.27, 0.62), P(0.37, 0.65), P(0.45, 0.62)], _k, 0.7)
	_stroke([P(0.56, 0.62), P(0.64, 0.65), P(0.72, 0.62)], _k, 0.7)
	# the nose long, a drinker's
	_stroke([P(0.5, 0.52), P(0.47, 0.7), P(0.5, 0.75), P(0.57, 0.73)], _k, 1.3)
	# the moustache he kept, the mouth shut under it
	_fill([P(0.32, 0.82), P(0.42, 0.77), P(0.5, 0.79), P(0.58, 0.77), P(0.68, 0.82), P(0.6, 0.85), P(0.5, 0.83), P(0.4, 0.85)], _k)
	_mouth(0.5, 0.9, 0.09, c, 0.035)
	_stroke([P(0.3, 0.74), P(0.33, 0.9)], _k, 0.6)
	_stroke([P(0.7, 0.74), P(0.67, 0.9)], _k, 0.6)


func _fighter(c: Color) -> void:
	var plate := [P(0.2, 0.32), P(0.5, 0.17), P(0.8, 0.32), P(0.85, 0.66), P(0.75, 0.93), P(0.5, 1.01), P(0.25, 0.93), P(0.15, 0.66), P(0.2, 0.32)]
	_plate(plate, c)
	_fill(_ellipse(0.12, 0.6, 0.07, 0.1, 10), c)
	_stroke(_ellipse(0.12, 0.6, 0.03, 0.05, 8), _k, 0.8)
	_fill(_ellipse(0.88, 0.6, 0.05, 0.09, 10), c)
	_cuts(0.5, 0.65, 0.35, 0.36, 0.3, 0.045)
	# the brow a shelf; the tape across the cut
	_fill([P(0.22, 0.42), P(0.5, 0.37), P(0.8, 0.42), P(0.8, 0.45), P(0.22, 0.46)], _k)
	_fill([P(0.58, 0.31), P(0.76, 0.38), P(0.74, 0.42), P(0.56, 0.35)], Look.INK)
	_fill([P(0.58, 0.39), P(0.74, 0.31), P(0.77, 0.35), P(0.6, 0.43)], Look.INK)
	# the left eye swollen shut, the right small and hard
	_fill(_ellipse(0.35, 0.53, 0.11, 0.06, 12), Color(c.lightened(0.25), c.a))
	_stroke([P(0.27, 0.53), P(0.35, 0.55), P(0.43, 0.53)], _k, 1.3)
	_eye(0.65, 0.52, 0.06, 0.03, c, Vector2(-0.5, 0.0), 0.15)
	# the nose flattened, pushed over
	_stroke([P(0.5, 0.47), P(0.46, 0.6), P(0.54, 0.64), P(0.43, 0.68), P(0.57, 0.69)], _k, 1.5)
	_mouth(0.5, 0.82, 0.14, c, 0.06)
	_stroke([P(0.25, 0.94), P(0.17, 1.13)], c, 2.4)
	_stroke([P(0.75, 0.94), P(0.83, 1.13)], c, 2.4)


func _manual(c: Color) -> void:
	var plate := [P(0.16, 0.16), P(0.86, 0.15), P(0.87, 1.02), P(0.15, 1.03), P(0.16, 0.16)]
	_plate(plate, c)
	var y := 0.3
	while y < 0.98:
		_stroke([P(0.33, y), P(0.83, y)], Color(_k, _k.a * 0.45), 0.45)
		y += 0.075
	_stroke([P(0.31, 0.18), P(0.31, 1.0)], _k, 0.6)
	for hy in [0.3, 0.59, 0.88]:
		draw_circle(P(0.22, hy), 0.03 * _box.size.x, _k)
	# the eyes: punched holes, the reinforcement rings round them
	for ex in [0.47, 0.71]:
		_stroke(_ellipse(ex, 0.5, 0.075, 0.075, 16), _k, 1.2)
		if _lid > 0.5:
			_stroke([P(ex - 0.05, 0.5), P(ex + 0.05, 0.5)], _k, 1.6)
		else:
			draw_circle(P(ex, 0.5), 0.042 * _box.size.x, _k)
	var f := Look.font("mono")
	draw_string(f, P(0.5, 0.35), "§2", HORIZONTAL_ALIGNMENT_LEFT, -1, int(_box.size.x * 0.15), _k)
	var o := 0.03 * clampf(talk * 1.4, 0.0, 1.0)
	_stroke([P(0.4, 0.79 - o), P(0.8, 0.79 - o)], _k, 1.5)
	if o > 0.006:
		_stroke([P(0.4, 0.79 + o), P(0.8, 0.79 + o)], _k, 1.5)


func _wrongman(c: Color) -> void:
	# told again: the features where they were last time, give or take
	var r := RandomNumberGenerator.new()
	r.seed = hash(_retell) ^ 991
	var dx := r.randf_range(-0.05, 0.05)
	var dy := r.randf_range(-0.04, 0.04)
	# the last telling, faint behind this one
	_stroke(_ellipse(0.5 - dx * 1.6, 0.6 - dy, 0.3, 0.42, 26), Color(c, c.a * 0.4), 0.8)
	var plate := _ellipse(0.5 + dx, 0.6 + dy * 0.5, 0.29, 0.41, 26)
	_plate(plate, Color(c, c.a * 0.85))
	_cuts(0.5 + dx, 0.6, 0.29, 0.41, -0.2, 0.06)
	var e1 := Vector2(0.37 + dx, 0.53 + dy)
	var e2 := Vector2(0.63 + dx * 0.3, 0.52 - dy)
	_fill(_ellipse(e1.x, e1.y, 0.08, 0.06, 14), _k)
	_fill(_ellipse(e2.x, e2.y, 0.08 + r.randf_range(-0.02, 0.02), 0.06, 14), _k)
	if _lid < 0.5:
		draw_circle(P(e1.x, e1.y + 0.01), 0.018 * _box.size.x, c)
	# one of the eyes struck out: he wasn't sure about that one
	if _retell % 3 == 1:
		_stroke([P(e2.x - 0.1, e2.y - 0.06), P(e2.x + 0.1, e2.y + 0.06)], c, 1.3)
	elif _lid < 0.5:
		draw_circle(P(e2.x, e2.y + 0.01), 0.018 * _box.size.x, c)
	_stroke([P(0.5 + dx, 0.55), P(0.46 + dx, 0.71), P(0.53 + dx, 0.73)], _k, 1.0)
	_mouth(0.5 + dx * 0.5, 0.84, 0.11, c, 0.045)
	_stroke([P(0.4 - dx, 0.88 + dy), P(0.6 - dx, 0.87 + dy)], Color(_k, 0.5), 0.8)
	_stroke([P(0.42, 0.31), P(0.47, 0.26), P(0.55, 0.27), P(0.56, 0.33), P(0.5, 0.37), P(0.5, 0.41)], _k, 1.0)


func _table(c: Color) -> void:
	_stroke([P(0.3, 1.1), P(0.5, 0.86), P(0.7, 1.1)], c, 1.4)
	var f := Look.font("archivo")
	draw_string(f, P(0.41, 1.07), "28", HORIZONTAL_ALIGNMENT_LEFT, -1, int(_box.size.x * 0.14), c)
	var heads := [[0.3, 0.42, 0.17], [0.7, 0.4, 0.16], [0.42, 0.66, 0.18], [0.66, 0.68, 0.16]]
	for i in heads.size():
		var h: Array = heads[i]
		var e := _ellipse(h[0], h[1], h[2], h[2] * 1.1, 18)
		_fill(e, c)
		_stroke(e, _k, 1.0)
		var shut := _lid > 0.5 and i % 2 == 0
		for sx in [-1.0, 1.0]:
			var ep := P(h[0] + sx * h[2] * 0.38, h[1] - h[2] * 0.15)
			if shut:
				_stroke([ep - Vector2(3, 0), ep + Vector2(3, 0)], _k, 1.2)
			else:
				draw_circle(ep, h[2] * 0.2 * _box.size.x, _k)
		var mo := 0.3 + 0.7 * absf(sin(float(_seed + i * 3) * 1.3)) * clampf(talk + 0.25, 0.0, 1.0)
		_fill(_ellipse(h[0], h[1] + h[2] * 0.48, h[2] * 0.34, h[2] * 0.26 * mo, 10), _k)


func _kid(c: Color) -> void:
	var hood := _ellipse(0.5, 0.6, 0.38, 0.5, 30, PI * 0.95, TAU + PI * 0.05)
	_fill(hood + [P(0.88, 1.12), P(0.12, 1.12)], c)
	_cuts(0.5, 0.75, 0.38, 0.4, 0.5, 0.05)
	var face := _ellipse(0.5, 0.66, 0.22, 0.3, 24)
	_fill(face, _k)
	_fill(face, Color(c, c.a * 0.55))
	_stroke(face, _k, 1.2)
	_eye(0.41, 0.63, 0.05, 0.026, c.lightened(0.4), Vector2(0.0, 1.0), 0.35)
	_eye(0.59, 0.63, 0.05, 0.026, c.lightened(0.4), Vector2(0.0, 1.0), 0.35)
	_stroke([P(0.5, 0.67), P(0.49, 0.75), P(0.52, 0.76)], _k, 0.9)
	_mouth(0.5, 0.84, 0.06, c, 0.03)
	for sx in [-1.0, 1.0]:
		var ear := P(0.5 + sx * 0.21, 0.7)
		draw_circle(ear, 0.026 * _box.size.x, Look.INK)
		_stroke([ear, P(0.5 + sx * 0.2, 0.92), P(0.5 + sx * 0.06, 1.05), P(0.5, 1.12)], Look.INK, 0.6)
	_stroke([P(0.44, 0.98), P(0.43, 1.1)], _k, 1.0)
	_stroke([P(0.56, 0.98), P(0.57, 1.1)], _k, 1.0)


func _till(c: Color) -> void:
	var body := [P(0.14, 0.4), P(0.86, 0.4), P(0.9, 1.05), P(0.1, 1.05), P(0.14, 0.4)]
	_plate(body, c)
	_stroke([P(0.4, 0.4), P(0.38, 0.22), P(0.46, 0.08), P(0.58, 0.1), P(0.56, 0.22), P(0.6, 0.4)], c, 1.2)
	for k in 3:
		_stroke([P(0.43, 0.32 - k * 0.07), P(0.55, 0.33 - k * 0.07)], Color(c, c.a * 0.5), 0.5)
	for ex in [0.33, 0.67]:
		_fill(_ellipse(ex, 0.58, 0.11, 0.09, 14), _k)
		if _lid < 0.5:
			_fill(_ellipse(ex, 0.59, 0.05, 0.045, 10), c)
	_mouth(0.5, 0.78, 0.2, c, 0.04)
	for row in 2:
		for col in 5:
			draw_circle(P(0.24 + col * 0.13, 0.9 + row * 0.07), 0.022 * _box.size.x, _k)


func _senior(c: Color) -> void:
	_stroke(_ellipse(0.5, 0.6, 0.4, 0.52, 32), c, 1.8)
	_fill(_ellipse(0.5, 0.6, 0.35, 0.47, 32), Color(c, c.a * 0.35))
	var face := _ellipse(0.5, 0.58, 0.2, 0.27, 24)
	_plate(face, c)
	_cuts(0.5, 0.58, 0.2, 0.27, 0.3, 0.04)
	_fill([P(0.3, 0.5), P(0.33, 0.36), P(0.44, 0.31), P(0.62, 0.32), P(0.7, 0.42), P(0.7, 0.5), P(0.6, 0.38), P(0.46, 0.4)], _k)
	for ex in [0.42, 0.58]:
		_stroke(_ellipse(ex, 0.56, 0.06, 0.05, 14), _k, 1.0)
		if _lid < 0.5:
			draw_circle(P(ex, 0.565), 0.02 * _box.size.x, _k)
	_stroke([P(0.48, 0.56), P(0.52, 0.56)], _k, 0.9)
	_mouth(0.5, 0.74, 0.07, c, 0.03)
	_stroke([P(0.34, 0.9), P(0.5, 0.96), P(0.66, 0.9)], c, 1.2)
	_fill([P(0.47, 0.95), P(0.53, 0.95), P(0.55, 1.08), P(0.45, 1.08)], c)
