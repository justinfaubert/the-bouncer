# Frozen seconds (bible/11_SKELETON.md, "The seconds"; 15_FIGHTS_AND_STATS.md, section 3). The press
# stops and the frame holds; the choices are drawn on it where they'd go, in the ink of the voice
# that taught them: the circle an arc round his wrist, the blow a line to where it lands, the choke a
# loop round the neck, off the line footprints, a word a ring at his mouth. Each has its dice, as
# checks do. Some choices go live: the print starts again and the fight carries on under the
# player's hands from exactly where the frame was.
#
#   var pick = await seconds.ask(choices, "The deck")
#   choice: {"id", "text", "glyph": "arc"|"line"|"loop"|"feet"|"ring"|"none", "at": Vector3 (world),
#            "voice": "fighter", "check": {"stat": "dex", "target": 12} (or none)}
#   returns {"id", "ok": bool, "d1", "d2", "total", "target"}
class_name FightSeconds
extends Control

signal picked(result: Dictionary)

var main
var view: View
var choices: Array = []
var title := ""
var hover := -1
var rolling := {}               # the dice in the air: {"t", "d1", "d2", "res"}
var t := 0.0
var stats := {}                 # his seven now
var tension := 0
var mods := {}                  # stat -> extra (drink, hurt, hunger) as the night has them


func setup(m) -> void:
	main = m
	view = m.view
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(false)


func ask(list: Array, head: String, his_stats: Dictionary, nerves := 0, extra := {}) -> Dictionary:
	choices = list
	title = head
	stats = his_stats
	tension = nerves
	mods = extra
	hover = -1
	rolling = {}
	position = Vector2.ZERO
	size = get_viewport_rect().size
	visible = true
	set_process(true)
	main.audio.sfx("stamp", 0.5, 0.6)
	view.flash = 0.35
	var r: Dictionary = await picked
	visible = false
	set_process(false)
	return r


func _mod(c: Dictionary) -> int:
	var ck = c.get("check")
	if not (ck is Dictionary):
		return 0
	var st := str(ck.get("stat", "str"))
	return int(stats.get(st, 4)) + int(ck.get("mod", 0)) + int(mods.get(st, 0))


func _odds(c: Dictionary) -> String:
	var ck = c.get("check")
	if not (ck is Dictionary):
		return ""
	if ck.get("sure", false):
		return "certain"
	return Checks.odds_word(Checks.odds(int(ck.get("target", 12)), _mod(c), tension))


func _process(dt: float) -> void:
	t += dt
	if not rolling.is_empty():
		rolling.t = float(rolling.t) + dt
		if float(rolling.t) >= 1.25:
			var r: Dictionary = rolling.res
			rolling = {}
			picked.emit(r)
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if not rolling.is_empty():
		return
	if e is InputEventMouseMotion:
		hover = _at((e as InputEventMouseMotion).position)
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var i := _at((e as InputEventMouseButton).position)
		if i >= 0:
			_choose(i)
		accept_event()


func _unhandled_key_input(e: InputEvent) -> void:
	if not visible or not rolling.is_empty():
		return
	var k := (e as InputEventKey)
	if k.pressed and not k.echo and k.physical_keycode >= KEY_1 and k.physical_keycode <= KEY_9:
		var i := int(k.physical_keycode - KEY_1)
		if i < choices.size():
			_choose(i)
			get_viewport().set_input_as_handled()


func _choose(i: int) -> void:
	var c: Dictionary = choices[i]
	var ck = c.get("check")
	main.audio.sfx("choose", 0.7)
	if not (ck is Dictionary):
		picked.emit({"id": c.id, "ok": true})
		return
	if ck.get("sure", false):
		picked.emit({"id": c.id, "ok": true, "sure": true})
		return
	var d1 := randi_range(1, 6)
	var d2 := randi_range(1, 6)
	var res := Checks.resolve(d1, d2, int(ck.get("target", 12)), _mod(c), tension)
	res["id"] = c.id
	res["ok"] = bool(res.success)
	rolling = {"t": 0.0, "d1": d1, "d2": d2, "res": res, "i": i}
	main.audio.sfx("rattle", 0.8, 1.0)


# the label boxes, laid out: [Rect2] per choice
func _rects() -> Array:
	var out: Array = []
	var w := size.x
	var col_x := w * 0.06
	var y := size.y * 0.2
	for i in choices.size():
		out.append(Rect2(col_x, y + i * 64.0, w * 0.34, 54.0))
	return out


func _at(p: Vector2) -> int:
	var rs := _rects()
	for i in rs.size():
		if (rs[i] as Rect2).grow(4).has_point(p):
			return i
	# or the glyph itself on the frame
	for i in choices.size():
		var sp := _glyph_pt(choices[i])
		if sp.z > 0.0 and Vector2(sp.x, sp.y).distance_to(p) < 44.0:
			return i
	return -1


func _glyph_pt(c: Dictionary) -> Vector3:
	if not c.has("at"):
		return Vector3(-1, -1, 0)
	return view.on_screen(c.at)


func _draw() -> void:
	# the frame held: the print darkened toward the edges, the ink still
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.03, 0.28))
	var f := Look.font("ui_b")
	var fr := Look.font("read")
	var fi := Look.font("read_i")
	draw_string(f, Vector2(size.x * 0.06, size.y * 0.13), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.92, 0.88, 0.8))
	draw_string(fi, Vector2(size.x * 0.06, size.y * 0.13 + 30), "The second holds. Choose.", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.8, 0.78, 0.72))
	var rs := _rects()
	for i in choices.size():
		var c: Dictionary = choices[i]
		var col := Look.voice_color(str(c.get("voice", "father"))) if c.has("voice") else Color(0.9, 0.88, 0.82)
		var lit := i == hover or (not rolling.is_empty() and int(rolling.i) == i)
		var r: Rect2 = rs[i]
		draw_rect(r, Color(0.04, 0.04, 0.05, 0.78 if lit else 0.6))
		draw_rect(Rect2(r.position, Vector2(4, r.size.y)), col)
		draw_string(f, r.position + Vector2(16, 24), "%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
		draw_string(fr, r.position + Vector2(40, 24), str(c.text), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 50, 20, Color(0.95, 0.93, 0.88) if lit else Color(0.85, 0.83, 0.78))
		var ck = c.get("check")
		var sub := ""
		if ck is Dictionary:
			var st := str(ck.get("stat", ""))
			sub = "%s  %s" % [(Checks.STATS[st].label if Checks.STATS.has(st) else st).to_upper(), _odds(c)]
		if c.get("live", false):
			sub += ("  ·  " if sub != "" else "") + "goes live"
		if sub != "":
			draw_string(f, r.position + Vector2(40, 46), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		# the glyph on the frame, where it goes
		var sp := _glyph_pt(c)
		if sp.z > 0.0:
			_glyph(str(c.get("glyph", "none")), Vector2(sp.x, sp.y), col, lit)
			if lit:
				draw_line(r.position + Vector2(r.size.x, r.size.y * 0.5), Vector2(sp.x, sp.y), Color(col, 0.35), 1.5, true)
	if not rolling.is_empty():
		_dice()


func _glyph(kind: String, p: Vector2, c: Color, lit: bool) -> void:
	var w := 4.0 if lit else 2.5
	var a := 1.0 if lit else 0.7
	var cc := Color(c, a)
	match kind:
		"arc":
			draw_arc(p, 46.0, -PI * 0.15, PI * 1.25, 28, cc, w, true)
			var tip := p + Vector2(cos(PI * 1.25), sin(PI * 1.25)) * 46.0
			draw_line(tip, tip + Vector2(14, -2), cc, w, true)
			draw_line(tip, tip + Vector2(4, 13), cc, w, true)
		"line":
			var from := p + Vector2(160, 150)
			draw_line(from, p, cc, w, true)
			draw_circle(p, 6.0 if lit else 4.0, cc)
		"loop":
			draw_arc(p, 30.0, 0, TAU, 32, cc, w, true)
			draw_arc(p + Vector2(0, 4), 36.0, 0.2, PI - 0.2, 20, Color(cc, a * 0.6), w * 0.7, true)
		"feet":
			for k in 3:
				var q := p + Vector2(-40 + k * 34, (k % 2) * 14.0)
				draw_rect(Rect2(q - Vector2(7, 12), Vector2(14, 24)), Color(cc, a * 0.8), false, w * 0.7)
		"ring":
			draw_arc(p, 22.0, 0, TAU, 24, cc, w, true)
			draw_arc(p, 34.0, -0.6, 0.6, 10, Color(cc, a * 0.6), w * 0.7, true)
			draw_arc(p, 34.0, PI - 0.6, PI + 0.6, 10, Color(cc, a * 0.6), w * 0.7, true)


func _dice() -> void:
	var rt := float(rolling.t)
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var settle := clampf(rt / 0.7, 0.0, 1.0)
	for k in 2:
		var d := int(rolling.d1 if k == 0 else rolling.d2)
		var face := d if settle >= 1.0 else randi_range(1, 6)
		var c := Vector2(cx - 50 + k * 100, cy + (1.0 - settle) * -60.0 * absf(sin(rt * 14.0 + k)))
		var rot := (1.0 - settle) * (rt * 9.0 + k)
		_die(c, face, rot)
	if settle >= 1.0:
		var res: Dictionary = rolling.res
		var ok := bool(res.ok)
		var txt := "%d against %d: %s" % [int(res.total), int(res.target), "it goes" if ok else "it doesn't"]
		draw_string(Look.font("ui_b"), Vector2(cx - 200, cy + 90), txt, HORIZONTAL_ALIGNMENT_CENTER, 400, 22, Color(0.95, 0.93, 0.85) if ok else Color(0.85, 0.45, 0.4))


func _die(c: Vector2, face: int, rot: float) -> void:
	var s := 64.0
	draw_set_transform(c, rot, Vector2.ONE)
	draw_rect(Rect2(Vector2(-s / 2, -s / 2), Vector2(s, s)), Color(0.93, 0.9, 0.82))
	draw_rect(Rect2(Vector2(-s / 2, -s / 2), Vector2(s, s)), Color(0.1, 0.1, 0.12), false, 2.0)
	var pips := {1: [Vector2.ZERO], 2: [Vector2(-1, -1), Vector2(1, 1)], 3: [Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)],
		4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
		5: [Vector2(-1, -1), Vector2(1, -1), Vector2.ZERO, Vector2(-1, 1), Vector2(1, 1)],
		6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]}
	for p in pips[face]:
		draw_circle(p * s * 0.27, 6.0, Color(0.1, 0.1, 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
