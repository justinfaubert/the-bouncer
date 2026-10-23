# His notes (Tab): a page of his notebook held up over the room. Q and E, or the tabs at the head
# of it, turn to the other page.
#
# In his head: who has a seat, how they get on (a line between two seats, solid where they get on
# and broken where they're at odds), and how loud it is in there. His seven stats, once Gary's
# office has set them, with every old number struck through. What he's been asked to do tonight,
# ticked off. The night so far, a line for each choice with the time on it. Click a voice for where
# it comes from and what's for and against its dice tonight.
#
# On him: what's in his pockets, pocket by pocket (content/ink/hand.ink), and what he's put down
# for later, in the lost-and-found drawer and up in twelve; under each thing, what he made of it, if
# he kept what one of the voices made of it. Click a thing for whose it is, what it costs him to
# carry, what it does and what it's worth (content/data/props.yaml).
class_name Notes
extends Control

const INK := Color("1b2130")
const INK_2 := Color("3d4250")
const PENCIL := Color("5a5a5e")
const RED := Color("a8231b")
const SEAT_ANGLES := [-90.0, -18.0, 54.0, 126.0, 198.0]

var main
var page: Control
var info_voice := ""
var info_thing := ""
var page_no := 0          # 0 in his head, 1 on him
var leaned := {}          # voice -> when it last leaned in (it rings on the page)
var t := 0.0
var _hits: Array = []     # [Rect2, what]: the tabs, and on him, the things, as last drawn
const POCKETS := [["right", "RIGHT POCKET"], ["left", "LEFT POCKET"], ["inside", "INSIDE POCKET"], ["jeans", "JEANS"]]


func setup(m) -> void:
	main = m
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.035, 0.05, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	page = Control.new()
	page.anchor_left = 0.06
	page.anchor_right = 0.94
	page.anchor_top = 0.07
	page.anchor_bottom = 0.93
	page.mouse_filter = Control.MOUSE_FILTER_PASS
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://look/paper.gdshader")
	sm.set_shader_parameter("paper_tex", Pub.tex_static("res://press/paper.png", false))
	sm.set_shader_parameter("paper", Look.STOCK)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.material = sm
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# under what's drawn on the page: a child draws over its parent unless it's told to go behind
	bg.show_behind_parent = true
	page.add_child(bg)
	add_child(page)
	page.draw.connect(_draw_page)
	page.gui_input.connect(_on_page_input)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	info_voice = ""
	info_thing = ""
	main.audio.sfx("page")
	refresh()


# the other page
func turn_page() -> void:
	page_no = 1 - page_no
	info_thing = ""
	main.audio.sfx("page")
	refresh()


func close() -> void:
	if visible:
		visible = false
		main.audio.sfx("page")


func refresh() -> void:
	if visible:
		page.queue_redraw()


func lean(voice: String) -> void:
	leaned[voice] = t


func _process(dt: float) -> void:
	t += dt
	if visible:
		page.queue_redraw()


func _seat_points() -> Array:
	var sz := page.size
	var c := Vector2(sz.x * 0.25, sz.y * 0.36)
	var r := minf(sz.x * 0.13, sz.y * 0.18)
	var out: Array = []
	for a in SEAT_ANGLES:
		var rad := deg_to_rad(a)
		out.append({"p": c + Vector2(cos(rad), sin(rad)) * r, "a": rad, "c": c, "r": r})
	return out


func _on_page_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for h in _hits:
			if (h[0] as Rect2).has_point(e.position):
				var what := str(h[1])
				if what.begins_with("tab:"):
					if int(what.substr(4)) != page_no:
						turn_page()
				else:
					info_thing = "" if info_thing == what else what
					main.audio.sfx("pen")
					page.queue_redraw()
				return
		if page_no != 0:
			return
		var seated: Array = main.game.psyche.seated
		var pts := _seat_points()
		for i in mini(5, seated.size()):
			if (pts[i].p as Vector2).distance_to(e.position) < 34.0:
				info_voice = "" if info_voice == seated[i] else str(seated[i])
				main.audio.sfx("pen")
				page.queue_redraw()
				return


func _text(font: String, size: int, s: String, at: Vector2, c: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := Look.font(font)
	# draw_string only aligns inside a width; with none, `at` is where the line ends (or its middle)
	if width < 0.0 and align != HORIZONTAL_ALIGNMENT_LEFT:
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		at.x -= w if align == HORIZONTAL_ALIGNMENT_RIGHT else w / 2.0
		align = HORIZONTAL_ALIGNMENT_LEFT
	page.draw_string(f, at, s, align, width, size, c)


func _para(font: String, size: int, s: String, at: Vector2, width: float, c: Color, line_h := 1.3) -> float:
	var f := Look.font(font)
	var words := s.split(" ")
	var line := ""
	var y := at.y
	for w in words:
		var tryl := (line + " " + w) if line != "" else w
		if f.get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and line != "":
			page.draw_string(f, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
			y += size * line_h
			line = w
		else:
			line = tryl
	if line != "":
		page.draw_string(f, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
		y += size * line_h
	return y


func _draw_page() -> void:
	if main == null or main.game.story == null:
		return
	var g: Game = main.game
	var sz := page.size
	var st := g.status()
	# ruled lines, faint, and the margin
	var y := 90.0
	while y < sz.y - 20:
		page.draw_line(Vector2(0, y), Vector2(sz.x, y), Color("b8c4c8", 0.35), 1.0)
		y += 34.0
	page.draw_line(Vector2(sz.x * 0.5, 30), Vector2(sz.x * 0.5, sz.y - 30), Color(PENCIL, 0.35), 1.0)
	# the head of the page: the clock, where he is, what's on him
	_text("ui_b", 16, "HIS NOTES", Vector2(40, 48), RED)
	var head := "%s   %s   $%d in his pocket   %s" % [str(st.clockText), str(Look.PLACE.get(str(st.here), "")), int(st.cash),
		("%d drink%s in him" % [int(st.drinks), "" if int(st.drinks) == 1 else "s"]) if int(st.drinks) > 0 else "sober"]
	if int(st.hurt) > 0:
		head += "   " + str(Look.HURT_WORDS[clampi(int(st.hurt), 0, 3)]).to_lower()
	_text("hand", 24, head, Vector2(160, 50), INK_2)
	_text("ui_b", 13, "TAB OR ESC TO PUT IT AWAY", Vector2(sz.x - 40, 48), PENCIL, HORIZONTAL_ALIGNMENT_RIGHT, -1)
	# the two pages, as tabs under the head on the right, clear of however long the head runs: the
	# one he's on in red
	_hits.clear()
	var fu := Look.font("ui_b")
	var names := ["IN HIS HEAD", "ON HIM"]
	var tabs_w := fu.get_string_size("Q  E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	for nm in names:
		tabs_w += fu.get_string_size(str(nm), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 26.0
	var tx := sz.x - 40.0 - tabs_w
	for k in 2:
		var name: String = names[k]
		var w := fu.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		_text("ui_b", 15, name, Vector2(tx, 80), RED if k == page_no else PENCIL)
		if k == page_no:
			page.draw_line(Vector2(tx, 86), Vector2(tx + w, 86), RED, 2.0)
		_hits.append([Rect2(tx - 6, 62, w + 12, 32), "tab:%d" % k])
		tx += w + 26.0
	_text("ui_b", 11, "Q  E", Vector2(tx, 79), PENCIL)
	if page_no == 1:
		_draw_on_him(st, sz)
		return

	# the room in his head
	_text("ui_b", 16, "IN HIS HEAD", Vector2(40, 110), RED)
	var pts := _seat_points()
	var seated: Array = g.psyche.seated
	for i in seated.size():
		for j in range(i + 1, seated.size()):
			if i >= 5 or j >= 5:
				continue
			var a: Vector2 = pts[i].p
			var b: Vector2 = pts[j].p
			if g.psyche.get_rel(seated[i], seated[j]) < 0:
				_dashed(a, b, Color(RED, 0.8), 2.0)
			else:
				page.draw_line(a, b, Color(INK_2, 0.55), 1.5, true)
	for i in 5:
		var p: Vector2 = pts[i].p
		if i >= seated.size():
			page.draw_arc(p, 16, 0, TAU, 32, Color(PENCIL, 0.5), 1.5, true)
			continue
		var id := str(seated[i])
		var style := str(main.content.voices.get(id, {}).get("style", id))
		var vc := Look.voice_color(style).darkened(0.35)
		page.draw_circle(p, 17, vc)
		if leaned.has(id) and t - float(leaned[id]) < 2.6:
			var k := (t - float(leaned[id])) / 2.6
			page.draw_arc(p, 20 + k * 16, 0, TAU, 40, Color(vc, 1.0 - k), 2.0, true)
		if info_voice == id:
			page.draw_arc(p, 23, 0, TAU, 40, INK, 2.0, true)
		var rad: float = pts[i].a
		var lab := str(main.content.voices.get(id, {}).get("label", id)).replace("THE ", "")
		var lp := (pts[i].c as Vector2) + Vector2(cos(rad), sin(rad)) * (float(pts[i].r) + 44.0)
		var f := Look.font("ui_b")
		var w := f.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var ax := lp.x - w / 2.0
		if cos(rad) > 0.3:
			ax = lp.x - 18
		elif cos(rad) < -0.3:
			ax = lp.x - w + 18
		_text("ui_b", 18, lab, Vector2(ax, lp.y + 6), vc)
	var tw := int(st.tension)
	var ty := float(pts[2].p.y) + 90.0
	_text("display", 40, str(Look.TENSION_WORDS[clampi(tw, 0, 4)]), Vector2(40, ty), INK)
	for i in 4:
		var r := Rect2(Vector2(240 + i * 22, ty - 24), Vector2(14, 22))
		if i < tw:
			page.draw_rect(r, RED)
		else:
			page.draw_rect(r, Color(PENCIL, 0.6), false, 1.5)
	var tnote := "The voices agree. Checks go the way the odds say." if tw == 0 else "The louder the room in his head, the wider his checks swing, both ways."
	var yy := _para("read", 19, tnote, Vector2(40, ty + 34), sz.x * 0.42, INK_2)
	if info_voice != "":
		yy = _voice_info(info_voice, Vector2(40, yy + 16), sz.x * 0.42)
	else:
		_para("read_i", 17, "Click a voice for where it comes from and what's for and against it tonight.", Vector2(40, yy + 10), sz.x * 0.42, PENCIL)

	# him: his seven stats once the interview's set them, in his hand, each old number struck
	# through (bible/11_SKELETON.md, Him: seven stats)
	var x2 := sz.x * 0.5 + 40.0
	var y_noted := 110.0
	if bool(st.get("statsSet", false)):
		_text("ui_b", 16, "HIM", Vector2(x2, 110), RED)
		var hist := {}
		for ch in g.stat_log:
			var k0 := str(ch.stat)
			if not hist.has(k0):
				hist[k0] = [int(ch.from)]
			hist[k0].append(int(ch.to))
		var hf := Look.font("hand")
		for i in Checks.STAT_ORDER.size():
			var k: String = Checks.STAT_ORDER[i]
			var at := Vector2(x2 + (0.0 if i < 4 else sz.x * 0.21), 146.0 + float(i % 4) * 30.0)
			_text("hand", 22, str(Checks.STATS[k].label), at, INK_2)
			var h: Array = hist.get(k, [int(st.stats.get(k, 0))])
			var nx := at.x + sz.x * 0.13
			for j in h.size():
				var ns := str(h[j])
				var w := hf.get_string_size(ns, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
				var last: bool = j == h.size() - 1
				_text("hand", 22, ns, Vector2(nx, at.y), INK if last else PENCIL)
				if not last:
					page.draw_line(Vector2(nx - 3, at.y - 6), Vector2(nx + w + 3, at.y - 9), INK_2, 1.6, true)
				nx += w + 12.0
		y_noted = 146.0 + 3.0 * 30.0 + 50.0

	# what he's been asked to do
	_text("ui_b", 16, "NOTED", Vector2(x2, y_noted), RED)
	var tasks: Array = []
	for id in g.tasks:
		var tk: Dictionary = g.tasks[id].duplicate()
		tk["id"] = id
		tasks.append(tk)
	tasks.sort_custom(func(a, b):
		if bool(a.get("done", false)) != bool(b.get("done", false)):
			return not bool(a.get("done", false))
		return int(a.get("turn", 0)) < int(b.get("turn", 0)))
	var y2 := y_noted + 40.0
	if tasks.is_empty():
		_text("hand", 24, "Nothing yet.", Vector2(x2, y2), PENCIL)
		y2 += 34
	for tk in tasks:
		var done := bool(tk.get("done", false))
		var y_end := _para("hand", 24, str(tk.get("text", "")), Vector2(x2 + 26, y2), sz.x * 0.4, Color(INK_2, 0.6) if done else INK, 1.4)
		page.draw_rect(Rect2(Vector2(x2, y2 - 16), Vector2(14, 14)), INK_2, false, 1.5)
		if done:
			page.draw_line(Vector2(x2 + 2, y2 - 9), Vector2(x2 + 6, y2 - 3), RED, 2.5)
			page.draw_line(Vector2(x2 + 6, y2 - 3), Vector2(x2 + 16, y2 - 20), RED, 2.5)
		y2 = y_end + 6
	# the night so far
	y2 += 20
	_text("ui_b", 16, "TONIGHT", Vector2(x2, y2), RED)
	y2 += 34
	var path: Array = g.path
	var from := maxi(0, path.size() - int((sz.y - y2 - 30) / 30.0))
	for i in range(from, path.size()):
		var pth: Dictionary = path[i]
		_text("hand_l", 17, BUtil.fmt_clock(int(pth.get("c", 0))).replace(" pm", "").replace(" am", ""), Vector2(x2, y2), PENCIL)
		var line := str(pth.get("x", ""))
		var f2 := Look.font("hand")
		while f2.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x > sz.x * 0.4 - 70 and line.length() > 8:
			line = line.substr(0, line.length() - 5) + "…"
		_text("hand", 20, line, Vector2(x2 + 64, y2), INK_2)
		y2 += 30
	if path.is_empty():
		_text("hand", 22, "The shift's just started.", Vector2(x2, y2), PENCIL)


# The second page: what he has on him, and where he's left what he's put down.
func _draw_on_him(st: Dictionary, sz: Vector2) -> void:
	var g: Game = main.game
	var P: Dictionary = main.content.get("props", {})
	var pk: Dictionary = st.get("pockets", {})
	var x := 40.0
	var w := sz.x * 0.42
	_text("ui_b", 16, "ON HIM", Vector2(x, 110), RED)
	var y := 150.0
	var any := false
	for pair in POCKETS:
		var items: Array = pk.get(pair[0], [])
		if items.is_empty():
			continue
		any = true
		_text("ui_b", 13, str(pair[1]), Vector2(x, y), PENCIL)
		y += 30.0
		for it in items:
			y = _thing_row(str(it), P, Vector2(x + 14, y), w - 14)
		y += 8.0
	if not any:
		_text("hand", 24, "Nothing but his wallet.", Vector2(x, y), PENCIL)
		y += 40.0
	# where he's left things, for later
	var later: Array = []
	if bool(pk.get("drawerSeen", false)):
		var dr: Array = (pk.get("drawer", []) as Array).duplicate()
		if not BUtil.js_truthy(g.get_var("book_seen")):
			dr.erase("aikido_book")
		if not dr.is_empty():
			later.append(["IN THE LOST-AND-FOUND DRAWER", dr])
	if not (pk.get("twelve", []) as Array).is_empty():
		later.append(["UP IN TWELVE", pk.twelve])
	if BUtil.js_truthy(g.get_var("jacket_done")) and not (pk.get("jacket", []) as Array).is_empty():
		later.append(["STILL IN THE LAST DOORMAN'S JACKET", pk.jacket])
	if not later.is_empty():
		y += 14.0
		_text("ui_b", 16, "LEFT FOR LATER", Vector2(x, y), RED)
		y += 40.0
		for l in later:
			_text("ui_b", 13, str(l[0]), Vector2(x, y), PENCIL)
			y += 30.0
			for it in l[1]:
				y = _thing_row(str(it), P, Vector2(x + 14, y), w - 14)
			y += 8.0
	# the other half: the thing he's clicked, or what he's made of things tonight
	var x2 := sz.x * 0.5 + 40.0
	var w2 := sz.x * 0.42
	if info_thing != "" and P.has(info_thing):
		var pr: Dictionary = P[info_thing]
		_text("hand", 32, str(pr.get("name", info_thing)), Vector2(x2, 116), INK)
		var y2 := 160.0
		for f in [["whose", "WHOSE"], ["heat", "HEAT"], ["does", "DOES"], ["worth", "WORTH"]]:
			if str(pr.get(f[0], "")) == "":
				continue
			_text("ui_b", 13, str(f[1]), Vector2(x2, y2), RED)
			y2 = _para("read", 19, str(pr.get(f[0])), Vector2(x2 + 80, y2), w2 - 80, INK_2) + 10.0
		var rd = g.reads.get(info_thing)
		if rd is Dictionary:
			y2 += 10.0
			_text("ui_b", 13, "WHAT HE MADE OF IT", Vector2(x2, y2), RED)
			y2 = _read_line(rd, Vector2(x2, y2 + 30), w2)
		return
	_text("ui_b", 16, "WHAT HE MADE OF THINGS", Vector2(x2, 110), RED)
	var y3 := 150.0
	var kept: Array = []
	for th in g.reads:
		var r2: Dictionary = g.reads[th].duplicate()
		r2["thing"] = th
		kept.append(r2)
	kept.sort_custom(func(a, b): return int(a.get("clock", 0)) < int(b.get("clock", 0)))
	if kept.is_empty():
		y3 = _para("read_i", 18, "Nothing yet. When a thing's in his hand, each voice makes something of it, and he can keep what one of them makes of it, or none.", Vector2(x2, y3), w2, PENCIL)
	for r3 in kept:
		_text("hand_l", 17, BUtil.fmt_clock(int(r3.get("clock", 0))).replace(" pm", "").replace(" am", ""), Vector2(x2, y3), PENCIL)
		_text("hand", 22, str(P.get(str(r3.thing), {}).get("name", r3.thing)), Vector2(x2 + 64, y3), INK)
		y3 = _read_line(r3, Vector2(x2 + 64, y3 + 28), w2 - 64) + 6.0
		if y3 > sz.y - 60.0:
			break
	_para("read_i", 17, "Click a thing for whose it is, what it costs him to carry, what it does and what it's worth.", Vector2(x2, maxf(y3 + 10.0, sz.y - 70.0)), w2, PENCIL)


# a thing on the page, clickable, and under it what he made of it
func _thing_row(id: String, P: Dictionary, at: Vector2, width: float) -> float:
	var pr: Dictionary = P.get(id, {})
	var name := str(pr.get("name", id))
	var f := Look.font("hand")
	var w := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var on := info_thing == id
	_text("hand", 24, name, at, INK if not on else RED)
	if on:
		page.draw_line(at + Vector2(0, 6), at + Vector2(w, 6), RED, 1.5)
	_hits.append([Rect2(at + Vector2(-6, -24), Vector2(w + 12, 32)), id])
	var y := at.y + 30.0
	var rd = main.game.reads.get(id)
	if rd is Dictionary:
		y = _read_line(rd, Vector2(at.x + 10, y), width - 10) + 4.0
	return y


# what a voice made of a thing, in its colour, its name first
func _read_line(rd: Dictionary, at: Vector2, width: float) -> float:
	var id := str(rd.get("voice", ""))
	var def: Dictionary = main.content.voices.get(id, {})
	var style := str(def.get("style", id))
	var vc := Look.voice_color(style).darkened(0.45)
	var lab := str(def.get("label", id.to_upper()))
	return _para("read_i", 17, lab + ": " + Look.voice_text(Look.voice(style), str(rd.get("text", ""))), at, width, vc, 1.25)


func _voice_info(id: String, at: Vector2, width: float) -> float:
	var def: Dictionary = main.content.voices.get(id, {})
	var style := str(def.get("style", id))
	var vc := Look.voice_color(style).darkened(0.4)
	var st: Dictionary = main.game.status()
	_text("ui_b", 20, str(def.get("label", id)), at, vc)
	var y := _para("read", 18, str(def.get("from", "")), at + Vector2(0, 30), width, INK_2)
	var mods := Checks.modifiers(def, main.game._ctx(int(st.drinks)), 0)
	var parts: Array = []
	for m in mods.get("parts", []):
		parts.append(("+" if int(m.value) > 0 else "−") + str(absi(int(m.value))) + " " + str(m.label))
	y = _para("read_i", 18, "Its dice tonight: " + (", ".join(parts) if not parts.is_empty() else "nothing either way") + ".", Vector2(at.x, y + 6), width, INK_2)
	var allies: Array = []
	var odds: Array = []
	for v in main.game.psyche.seated:
		if v == id:
			continue
		var lab := str(main.content.voices.get(v, {}).get("label", v))
		var r: int = main.game.psyche.get_rel(id, v)
		if r > 0:
			allies.append(lab)
		elif r < 0:
			odds.append(lab)
	if not allies.is_empty():
		y = _para("read_i", 18, "Gets on with " + ", ".join(allies) + ".", Vector2(at.x, y), width, INK_2)
	if not odds.is_empty():
		y = _para("read_i", 18, "At odds with " + ", ".join(odds) + ".", Vector2(at.x, y), width, INK_2)
	return y


func _dashed(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	var d := b - a
	var n := d.length()
	var u := d / maxf(n, 0.001)
	var s := 0.0
	while s < n:
		page.draw_line(a + u * s, a + u * minf(s + 9.0, n), c, w, true)
		s += 15.0
