# What's on the glass while he's at the pool table (game/pool.gd): its own, not the column's, kept to
# the corners so the table's the picture.
#   top left     the game: who's on what, the balls each has left as they are on the table, whose
#                shot, the fouls in a row (nine-ball), the money on the rail
#   bottom right the cue ball as he sees it down the cue: where the tip is on its face, and how far
#                off the middle the tip holds on this cue with this chalk (past that ring it slips);
#                beside it the cue from the side, the butt's lift, and as he draws back, how far
#   bottom left  what happened, a line or two, the way he'd say it; and once in a while what he
#                notices, in the teller's voice
#   the middle   the end of the game
# The type and the inks are the column's (game/look.gd), set on a dark card with a ragged edge, like
# the house rules chalked on the board.
class_name PoolUI
extends Control

var pool
var lines: Array = []                   # [text, t, note]
var hint := ""
var place_ok := true
var _toast := ""
var _toast_t := -10.0
var _over := false
var _over_won := false
var _over_why := ""
var t := 0.0

const BALL_COL := {0: Color("e2d6ba"), 1: Color("d6a826"), 2: Color("223a8c"), 3: Color("b82a22"), 4: Color("522870"), 5: Color("d4661e"),
	6: Color("1e683a"), 7: Color("702228"), 8: Color("121212")}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50


func _process(dt: float) -> void:
	t += dt
	if visible:
		queue_redraw()


func say(text: String) -> void:
	lines.append([text, t, false])
	if lines.size() > 4:
		lines.pop_front()


func note(text: String) -> void:
	lines.append([text, t, true])
	if lines.size() > 4:
		lines.pop_front()


func say_clear() -> void:
	lines = []


func toast(text: String) -> void:
	_toast = text
	_toast_t = t


func over(won: bool, why: String) -> void:
	_over = true
	_over_won = won
	_over_why = why


func over_hide() -> void:
	_over = false


func _card(r: Rect2, a := 0.82) -> void:
	# a dark card, its edge a little ragged
	var pts := PackedVector2Array()
	var n := 28
	var rr := RandomNumberGenerator.new()
	rr.seed = int(r.position.x * 13 + r.position.y * 7)
	for i in n:
		var k := float(i) / n
		var p: Vector2
		if k < 0.25:
			p = r.position + Vector2(r.size.x * k * 4.0, 0)
		elif k < 0.5:
			p = r.position + Vector2(r.size.x, r.size.y * (k - 0.25) * 4.0)
		elif k < 0.75:
			p = r.position + Vector2(r.size.x * (1.0 - (k - 0.5) * 4.0), r.size.y)
		else:
			p = r.position + Vector2(0, r.size.y * (1.0 - (k - 0.75) * 4.0))
		pts.append(p + Vector2(rr.randf_range(-1.5, 1.5), rr.randf_range(-1.5, 1.5)))
	draw_colored_polygon(pts, Color(0.07, 0.075, 0.08, a))
	pts.append(pts[0])
	draw_polyline(pts, Color(Look.RULE, 0.9), 1.0)


func _text(at: Vector2, s: String, size: int, col: Color, font := "ui", width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(Look.font(font), at, s, align, width, size, col)


func _ball(at: Vector2, id: int, r: float, gone := false) -> void:
	var c: Color = BALL_COL.get(id if id <= 8 else id - 8, Color.WHITE)
	if gone:
		draw_arc(at, r, 0, TAU, 18, Color(Look.FAINT, 0.6), 1.0)
		return
	if id > 8:
		draw_circle(at, r, Color("e2d6ba"))
		draw_rect(Rect2(at - Vector2(r, r * 0.55), Vector2(r * 2, r * 1.1)), c)
		draw_arc(at, r, 0, TAU, 18, Color("e2d6ba"), 1.5)
	else:
		draw_circle(at, r, c)
	if id > 0:
		draw_circle(at, r * 0.48, Color("e2d6ba"))
		_text(at + Vector2(-r * 0.5, r * 0.32), str(id), int(r * 0.9), Color("1b1a17"), "ui_b", r, HORIZONTAL_ALIGNMENT_CENTER)


func _draw() -> void:
	if pool == null or not pool.active:
		return
	var vp := get_viewport_rect().size
	var k := vp.y / 1080.0
	_scoreboard(k)
	if pool.phase == "aim":
		_tipcard(vp, k)
	_lines(vp, k)
	if hint != "" and pool.phase in ["aim", "place"]:
		_text(Vector2(28 * k, vp.y - 18 * k), hint, int(17 * k), Color(Look.MUTED, 0.85), "ui_r")
	if pool.phase == "place" and not place_ok:
		_text(Vector2(vp.x * 0.5 - 200 * k, vp.y * 0.18), "Not there.", int(26 * k), Look.BAD, "ui_b", 400 * k, HORIZONTAL_ALIGNMENT_CENTER)
	if t - _toast_t < 3.0:
		var a := clampf(3.0 - (t - _toast_t), 0.0, 1.0)
		_text(Vector2(vp.x * 0.5 - 450 * k, vp.y * 0.13), _toast, int(24 * k), Color(Look.INK, a), "read", 900 * k, HORIZONTAL_ALIGNMENT_CENTER)
	if _over:
		_over_card(vp, k)


func _scoreboard(k: float) -> void:
	var r: PoolRules = pool.rules
	var sim: PoolSim = pool.sim
	var x := 28.0 * k
	var y := 26.0 * k
	var two: bool = pool.ai != null
	var h := (118.0 if two else 70.0) * k
	_card(Rect2(x - 12 * k, y - 12 * k, 430 * k, h))
	_text(Vector2(x, y + 14 * k), r.describe().to_upper() + ("    $%d ON THE RAIL" % pool.stakes if pool.stakes > 0 else ""), int(15 * k), Look.MUTED, "ui_b")
	var on := r.on_table(sim)
	for who in (2 if two else 1):
		var yy := y + (44.0 + who * 40.0) * k
		var turn: bool = r.turn == who and r.winner < 0
		if turn:
			_text(Vector2(x - 2 * k, yy + 6 * k), "▸", int(22 * k), Look.LAMP, "ui_b")
		_text(Vector2(x + 16 * k, yy + 6 * k), str(pool.names[who]), int(22 * k), Look.INK if turn else Look.INK_2, "ui_b")
		var bx := x + 150 * k
		var ids: Array = []
		match r.game:
			"9ball":
				if who == 0:
					ids = [1, 2, 3, 4, 5, 6, 7, 8, 9]
			"practice":
				if who == 0:
					ids = range(1, 16)
			_:
				if r.groups[who] == "solids":
					ids = PoolRules.SOLIDS.duplicate()
				elif r.groups[who] == "stripes":
					ids = PoolRules.STRIPES.duplicate()
				if not ids.is_empty():
					ids.append(8)
		if ids.is_empty() and r.game != "9ball" and r.game != "practice":
			_text(Vector2(bx, yy + 6 * k), "open table" if r.broke else "", int(17 * k), Look.MUTED, "ui_r")
		for i in ids.size():
			_ball(Vector2(bx + i * 26 * k, yy), ids[i], 10.5 * k, not (ids[i] in on))
		if r.game == "9ball" and r.fouls[who] > 0:
			_text(Vector2(x + 330 * k, yy + 6 * k), "foul" + ("s: %d" % r.fouls[who] if r.fouls[who] > 1 else ""), int(16 * k), Look.BAD, "ui_r")
	if r.game == "9ball" and two:
		_text(Vector2(x + 150 * k, y + 104 * k), "on the %d" % (r.targets(sim)[0] if not r.targets(sim).is_empty() else 9), int(15 * k), Look.MUTED, "ui_r")


func _tipcard(vp: Vector2, k: float) -> void:
	var c: Dictionary = pool.cue()
	var w := 300.0 * k
	var h := 180.0 * k
	var o := Vector2(vp.x - w - 28 * k, vp.y - h - 44 * k)
	_card(Rect2(o, Vector2(w, h)))
	# the cue ball's face
	var cen := o + Vector2(82 * k, 92 * k)
	var R := 62.0 * k
	draw_circle(cen, R, Color("d9ccae"))
	draw_arc(cen, R, 0, TAU, 40, Color("3b3a36"), 1.5)
	# where the tip holds: past this it slips off
	draw_arc(cen, R * float(c.limit), 0, TAU, 40, Color(Look.RED, 0.35), 1.0)
	draw_line(cen - Vector2(R, 0), cen + Vector2(R, 0), Color(0, 0, 0, 0.12), 1.0)
	draw_line(cen - Vector2(0, R), cen + Vector2(0, R), Color(0, 0, 0, 0.12), 1.0)
	var tr: Vector2 = pool._tremor(pool.t) * 30.0
	var tp: Vector2 = pool.tip + tr
	var slips: bool = tp.length() > float(c.limit)
	var at := cen + Vector2(tp.x, -tp.y) * R
	draw_circle(at, 7.0 * k, Color("2a4f7a") if not slips else Look.BAD)
	draw_arc(at, 7.0 * k, 0, TAU, 16, Color(0, 0, 0, 0.6), 1.0)
	# the cue from the side: the butt's lift, and the draw
	var sx := o.x + 170 * k
	var sy := o.y + 128 * k
	var e := deg_to_rad(float(pool.elev))
	draw_circle(Vector2(sx, sy), 9 * k, Color("d9ccae"))
	draw_line(Vector2(sx - 30 * k, sy + 9 * k), Vector2(sx + 110 * k, sy + 9 * k), Color(Look.MUTED, 0.6), 1.0)
	var back := 14.0 * k + float(maxf(pool.draw, 0.0)) * 60.0 * k
	var p0 := Vector2(sx + cos(e) * back, sy - sin(e) * back)
	var p1 := p0 + Vector2(cos(e), -sin(e)) * 90.0 * k
	draw_line(p0, p1, Color("cdb48a"), 3.0 * k)
	_text(Vector2(sx - 4 * k, o.y + 30 * k), "butt up %d°" % roundi(float(pool.elev)), int(15 * k), Look.INK_2, "ui_r")
	var chalk_w := "fresh chalk" if pool.chalk > 0.75 else ("chalk going" if pool.chalk > 0.3 else "dry tip")
	_text(Vector2(sx - 4 * k, o.y + 50 * k), chalk_w, int(15 * k), Look.INK_2 if pool.chalk > 0.3 else Look.BAD, "ui_r")
	_text(Vector2(o.x + 14 * k, o.y + h - 10 * k), str(c.name).to_lower(), int(14 * k), Look.MUTED, "ui_r")
	if pool.rules.called >= 0:
		_text(Vector2(sx - 4 * k, o.y + 70 * k), "called", int(15 * k), Look.LAMP, "ui_r")
	if pool.rules.pushing:
		_text(Vector2(sx - 4 * k, o.y + 70 * k), "push out", int(15 * k), Look.LAMP, "ui_r")


func _lines(vp: Vector2, k: float) -> void:
	var y := vp.y - 56.0 * k
	for i in range(lines.size() - 1, -1, -1):
		var ln: Array = lines[i]
		var age := t - float(ln[1])
		var a := clampf(1.0 - (age - 9.0) / 3.0, 0.0, 1.0) * (1.0 if i == lines.size() - 1 else 0.7)
		if a <= 0.0:
			continue
		var note: bool = ln[2]
		var font := "read_i" if note else "read"
		var col := Color(Look.INK_2 if note else Look.INK, a)
		# wrap to the width by hand, a few words a line
		var words: PackedStringArray = str(ln[0]).split(" ")
		var rows: Array = []
		var cur := ""
		var maxw := vp.x * 0.42
		var f := Look.font(font)
		var size := int(20 * k)
		for wd in words:
			var test := (cur + " " + wd).strip_edges()
			if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > maxw and cur != "":
				rows.append(cur)
				cur = wd
			else:
				cur = test
		if cur != "":
			rows.append(cur)
		for j in range(rows.size() - 1, -1, -1):
			draw_string_outline(f, Vector2(28 * k, y), rows[j], HORIZONTAL_ALIGNMENT_LEFT, -1, size, int(5 * k), Color(0, 0, 0, a * 0.7))
			draw_string(f, Vector2(28 * k, y), rows[j], HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
			y -= 26 * k
		y -= 8 * k


func _over_card(vp: Vector2, k: float) -> void:
	var w := 560.0 * k
	var h := 250.0 * k
	var o := Vector2((vp.x - w) * 0.5, vp.y * 0.3)
	_card(Rect2(o, Vector2(w, h)), 0.9)
	var res: Dictionary = pool.result
	var head := "HE WON" if _over_won else ("HE LOST" if pool.ai != null else "THE RACK'S DONE")
	_text(o + Vector2(0, 62 * k), head, int(46 * k), Look.INK if _over_won else Look.INK_2, "anton", w, HORIZONTAL_ALIGNMENT_CENTER)
	_text(o + Vector2(0, 100 * k), _over_why.capitalize() + ".", int(20 * k), Look.MUTED, "read_i", w, HORIZONTAL_ALIGNMENT_CENTER)
	var stats := "%d down from %d shots, longest run %d" % [int(res.get("made", 0)), int(res.get("shots", 0)), int(res.get("run", 0))]
	_text(o + Vector2(0, 140 * k), stats, int(18 * k), Look.INK_2, "ui_r", w, HORIZONTAL_ALIGNMENT_CENTER)
	if pool.stakes > 0:
		_text(o + Vector2(0, 176 * k), ("+$%d" if _over_won else "-$%d") % pool.stakes, int(30 * k), Look.GOOD if _over_won else Look.BAD, "ui_b", w, HORIZONTAL_ALIGNMENT_CENTER)
	_text(o + Vector2(0, h - 18 * k), ("Esc to leave" if pool.story != "" else "R for another rack    Esc to leave the table"), int(16 * k), Look.MUTED, "ui_r", w, HORIZONTAL_ALIGNMENT_CENTER)
