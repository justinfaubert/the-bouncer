# The fight's tally (Hutch, 25 Nov: "hard to know if a guy is going to go down ... perhaps a
# lifebar but designed in a way that fits the world"). Two slips of newsprint pasted at the head of
# the frame, the way a broadside printed a prize fight: each man's name, a stroke for every time
# he's been down (London rules count them), and under it his legs as an inked rule.
#
#   the ink    what's keeping him up now (FightSim.Fighter.stand)
#   the pencil what it can come back to, if he gets a breather (stand_top, less the damage he carries)
#   the red    what the last one took, fading: you see the size of a blow
#   the thin   his wind
#
# Under a third the rule trembles and the slip says so: his legs are going. Bars run out from the
# middle, yours on the left, his on the right, so the eye reads them as one line between two men.
class_name FightTally
extends Control

const PAPER := Color(0.90, 0.86, 0.76)
const INK := Color(0.10, 0.10, 0.12)
const PENCIL := Color(0.35, 0.34, 0.33)
const RED := Color(0.62, 0.12, 0.08)
const W := 300.0                 # a full rule, at 900 px of screen height

var fight
var names := ["YOU", "HIM"]
var shown := {}                  # side -> the stand drawn (it eases down, so a blow reads as a cut)
var lost := {}                   # side -> [{"from", "to", "t"}] the red pieces fading
var t := 0.0
var hint_t := 0.0                # the keys under the slips, fading once he's used his hands
var strokes_made := 0


func setup(f) -> void:
	fight = f
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func begin(me_name: String, him_name: String) -> void:
	names = [me_name, him_name]
	shown = {0: 1.0, 1: 1.0}
	lost = {0: [], 1: []}
	hint_t = 0.0
	strokes_made = 0
	visible = true


func took(side: int, from: float, to: float) -> void:
	(lost[side] as Array).append({"from": from, "to": to, "t": t})


func _process(dt: float) -> void:
	if not visible or fight == null or fight.sim == null:
		return
	t += dt
	hint_t += dt
	for side in 2:
		var f = fight.sim.a if side == 0 else fight.sim.b
		var want := clampf(f.stand, 0.0, 1.0)
		shown[side] = want if want > float(shown[side]) else lerpf(float(shown[side]), want, 1.0 - exp(-dt * 14.0))
		var keep: Array = []
		for l in lost[side]:
			if t - float(l.t) < 0.9:
				keep.append(l)
		lost[side] = keep
	queue_redraw()


func _draw() -> void:
	if fight == null or fight.sim == null:
		return
	var sc := size.y / 900.0
	var mid := size.x * 0.5
	for side in 2:
		var f = fight.sim.a if side == 0 else fight.sim.b
		_slip(side, f, mid, sc)
	_hint(mid, sc)


func _slip(side: int, f, mid: float, sc: float) -> void:
	var dir := -1.0 if side == 0 else 1.0
	var w := W * sc
	var x0 := mid + dir * 14.0 * sc               # where the rule starts, by the middle
	var top := 18.0 * sc
	var h := 64.0 * sc
	# the slip of paper, a little off true, torn at the outer end
	var tilt := (-0.012 if side == 0 else 0.009)
	draw_set_transform(Vector2(mid, top), tilt, Vector2.ONE)
	var px0 := 4.0 * sc if side == 1 else -(w + 40.0 * sc)
	var poly := PackedVector2Array()
	poly.append(Vector2(px0, 0))
	poly.append(Vector2(px0 + w + 36.0 * sc, 0))
	var outer_x := px0 + w + 36.0 * sc if side == 1 else px0
	var inner_x := px0 if side == 1 else px0 + w + 36.0 * sc
	# torn outer edge: a ragged line down
	poly.clear()
	poly.append(Vector2(inner_x, 0))
	var steps := 9
	for i in steps + 1:
		var yy := h * float(i) / steps
		var jag := (sin(i * 12.9898 + side * 3.0) * 0.5 + 0.5) * 7.0 * sc
		poly.append(Vector2(outer_x + dir * jag, yy))
	poly.append(Vector2(inner_x, h))
	draw_colored_polygon(poly, Color(0, 0, 0, 0.35), PackedVector2Array(), null)
	for i in poly.size():
		poly[i] = poly[i] + Vector2(-2.0 * sc, -3.0 * sc)
	draw_colored_polygon(poly, PAPER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the name, small caps, from the middle out; the downs as strokes after it
	var fnt := Look.font("ui_b")
	var nm: String = names[side]
	var fs := int(16.0 * sc)
	var nw := fnt.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ny := top + 22.0 * sc
	var nx := x0 if side == 1 else x0 - nw
	draw_string(fnt, Vector2(nx, ny), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var tx := (nx + nw + 12.0 * sc) if side == 1 else (nx - 12.0 * sc)
	for k in int(f.downs):
		var sx := tx + dir * k * 7.0 * sc
		draw_line(Vector2(sx, ny - 13.0 * sc), Vector2(sx - 2.0 * sc, ny + 1.0 * sc), RED, 2.2 * sc, true)
	# the rule: pencil to what it can come back to, ink to what's left, red for what just went
	var ry := top + 38.0 * sc
	var top_v: float = clampf(f.stand_top - f.hurt.head * 0.25 - f.hurt.body * 0.15 - f.hurt.legs * 0.15, 0.0, 1.0)
	var now := float(shown[side])
	var rocked: bool = f.stand < 0.3 and not f.down
	var shake := Vector2(sin(t * 31.0) , cos(t * 27.0)) * (2.2 * sc if rocked else 0.0)
	# the end of the full rule, a tick
	draw_line(Vector2(x0 + dir * w, ry - 6.0 * sc), Vector2(x0 + dir * w, ry + 6.0 * sc), Color(PENCIL, 0.5), 1.0 * sc)
	_dashes(Vector2(x0, ry), dir, w * top_v, Color(PENCIL, 0.7), sc)
	for l in lost[side]:
		var a := 1.0 - (t - float(l.t)) / 0.9
		var fr := clampf(float(l.from), 0.0, 1.0)
		var to := clampf(float(l.to), 0.0, 1.0)
		_brush(Vector2(x0 + dir * w * to, ry), dir, w * (fr - to), Color(RED, a), 7.0 * sc, 7, Vector2.ZERO)
	_brush(Vector2(x0, ry) + shake, dir, w * now, RED.darkened(0.2) if rocked else INK, 8.0 * sc, 3 + side, shake)
	# his wind, thin under it
	var br := clampf(f.breath, 0.0, 1.0)
	draw_line(Vector2(x0, ry + 11.0 * sc), Vector2(x0 + dir * w * br, ry + 11.0 * sc), Color(INK, 0.55), 1.6 * sc, true)
	# what the slip says, when it says anything
	var word := ""
	if f.down:
		word = "down" if not f.out else "out"
	elif rocked:
		word = "your legs are going" if side == 0 else "his legs are going"
	elif f.breath < 0.25:
		word = "blown"
	if word != "":
		var fi := Look.font("read_i")
		var ws := int(15.0 * sc)
		var ww := fi.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, ws).x
		var wx := (x0 + w - ww) if side == 1 else (x0 - w)
		draw_string(fi, Vector2(wx, top + 59.0 * sc), word, HORIZONTAL_ALIGNMENT_LEFT, -1, ws, RED)


# an inked rule: a brush line, a little uneven, its end frayed
func _brush(from: Vector2, dir: float, length: float, c: Color, thick: float, seed: int, _jit: Vector2) -> void:
	if length <= 0.5:
		return
	var n := maxi(2, int(length / 9.0))
	var pts := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n
		var wob := sin(u * 9.0 + seed) * 0.6 + sin(u * 23.0 + seed * 2.0) * 0.4
		pts.append(from + Vector2(dir * length * u, wob))
	draw_polyline(pts, c, thick, true)
	# the frayed end: three short hairs
	var end := from + Vector2(dir * length, 0)
	for k in 3:
		var off := (k - 1) * thick * 0.35
		draw_line(end + Vector2(0, off), end + Vector2(dir * thick * (0.6 + 0.4 * sin(seed + k * 1.7)), off * 1.4), c, maxf(1.0, thick * 0.25), true)


func _dashes(from: Vector2, dir: float, length: float, c: Color, sc: float) -> void:
	var x := 0.0
	while x < length:
		var seg := minf(6.0 * sc, length - x)
		draw_line(from + Vector2(dir * x, 0), from + Vector2(dir * (x + seg), 0), c, 1.4 * sc, true)
		x += 10.0 * sc


# the keys, small under the slips, until he's thrown a few
func _hint(mid: float, sc: float) -> void:
	var a := 1.0
	if strokes_made >= 4:
		a = 0.0
	elif hint_t > 14.0:
		a = clampf(1.0 - (hint_t - 14.0) / 2.0, 0.0, 1.0)
	if a <= 0.0:
		return
	var lines := ["CLICK HIM  a jab     DRAG  harder, the longer and quicker     CURVE IT  a hook     DRAG UP  an uppercut",
		"LEFT BUTTON  your right hand     RIGHT BUTTON  your left     HOLD STILL ON HIM  take hold, then circle the mouse to turn him",
		"W A S D  your feet     Q  E  slip     SPACE  cover up"]
	var fnt := Look.font("ui_b")
	var fs := int(12.0 * sc)
	for i in lines.size():
		var s: String = lines[i]
		var sw := fnt.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := Vector2(mid - sw * 0.5, 104.0 * sc + i * 18.0 * sc)
		draw_string(fnt, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7 * a))
		draw_string(fnt, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.93, 0.9, 0.82, 0.9 * a))
