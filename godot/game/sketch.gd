# The floor sketch (M): the paper in his pocket (prototype/web/src/ui/views.js, mapSVG).
#
# The Sov from above in pencil: the bar down the side wall, the pool table, table 28 in the front
# window, the washrooms off the back hall, the deck on the water side, the lot and the pickup. His
# own notes on it, faded by how long ago they were true: the last count, the pool table ringed when
# it's heating up, table 28's rounds in a tally, the doors propped or shut. A lit place is
# somewhere he can go now: click it, and he goes.
class_name Sketch
extends Control

const INK := Color("1b2130")
const PENCIL := Color("4e5058")
const RED := Color("a8231b")
const PAPER := Color("eae2cf")

# where each place is on the sketch, and where its label goes (the same as the browser's)
const SPOTS := {
	"door": {"x": 40, "y": 222, "lx": 40, "ly": 207, "anchor": "middle", "label": "Door"},
	"floor": {"x": 112, "y": 168, "lx": 112, "ly": 186, "anchor": "middle", "label": "Count"},
	"t28": {"x": 186, "y": 206, "r": 22, "label": ""},
	"pool": {"x": 186, "y": 123, "lx": 186, "ly": 158, "anchor": "middle", "label": "Pool"},
	"bar": {"x": 29, "y": 170, "lx": 59, "ly": 174, "anchor": "start", "label": "Bar"},
	"keg": {"x": 29, "y": 88, "lx": 46, "ly": 92, "anchor": "start", "label": "Keg room"},
	"kitchen": {"x": 55, "y": 30, "lx": 55, "ly": 50, "anchor": "middle", "label": "Kitchen"},
	"hall": {"x": 160, "y": 47, "lx": 176, "ly": 51, "anchor": "start", "label": "Washrooms"},
	"deck": {"x": 330, "y": 186, "lx": 330, "ly": 226, "anchor": "middle", "label": "Deck"},
	"lot": {"x": 262, "y": 264, "lx": 262, "ly": 284, "anchor": "middle", "label": "Lot"},
}

var main
var page: Control
var open := {}           # place -> visible choice index
var hot := ""            # the spot under the pointer
var k := 2.0             # sketch units to pixels
var origin := Vector2.ZERO


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
	page.anchor_left = 0.08
	page.anchor_right = 0.92
	page.anchor_top = 0.06
	page.anchor_bottom = 0.94
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://look/paper.gdshader")
	sm.set_shader_parameter("paper_tex", Pub.tex_static("res://press/paper.png", false))
	sm.set_shader_parameter("paper", PAPER)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.material = sm
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(bg)
	add_child(page)
	page.draw.connect(_draw_page)
	page.gui_input.connect(_on_input)


func toggle() -> void:
	if visible:
		close()
	else:
		open_it()


func open_it() -> void:
	visible = true
	main.audio.sfx("page")
	_update_open()
	page.queue_redraw()


func close() -> void:
	if visible:
		visible = false
		main.audio.sfx("page")


func _update_open() -> void:
	open.clear()
	if main.game.story == null or main.pending != null or main.rolling != null:
		return
	var list: Array = main.game.visible_choices()
	for i in list.size():
		var loc = list[i].get("loc")
		if loc != null and str(loc) != "" and not open.has(str(loc)):
			open[str(loc)] = i


func _to_px(x: float, y: float) -> Vector2:
	return origin + Vector2(x, y) * k


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h := _spot_at(e.position)
		if h != hot:
			hot = h
			page.queue_redraw()
			page.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if open.has(hot) else Control.CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var s := _spot_at(e.position)
		if open.has(s):
			var i: int = open[s]
			close()
			main.choose(i)


func _spot_at(p: Vector2) -> String:
	for id in SPOTS:
		var s: Dictionary = SPOTS[id]
		var r: float = s.get("r", 10) + 6
		if _to_px(s.x, s.y).distance_to(p) < r * k:
			return id
	return ""


func _line(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	page.draw_line(_to_px(a.x, a.y), _to_px(b.x, b.y), c, w * k * 0.5, true)


func _rect(x: float, y: float, w: float, h: float, c: Color, lw: float, fill := Color(0, 0, 0, 0)) -> void:
	var r := Rect2(_to_px(x, y), Vector2(w, h) * k)
	if fill.a > 0.0:
		page.draw_rect(r, fill)
	page.draw_rect(r, c, false, lw * k * 0.5)


func _dash(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	var d := b - a
	var n := d.length()
	var u := d / maxf(n, 0.001)
	var s := 0.0
	while s < n:
		_line(a + u * s, a + u * minf(s + 4.0, n), c, w)
		s += 7.0


func _text(x: float, y: float, s: String, size: float, c: Color, anchor := "start", font := "hand") -> void:
	var f := Look.font(font)
	var px := int(size * k)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var p := _to_px(x, y)
	if anchor == "middle":
		p.x -= w / 2.0
	elif anchor == "end":
		p.x -= w
	page.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)


func _fade(age: float) -> float:
	return clampf(1.0 - age / 120.0, 0.38, 1.0)


func _fmt(m: int) -> String:
	return BUtil.fmt_clock(m).replace(" am", "").replace(" pm", "")


func _pen_ring(cx: float, cy: float, rx: float, ry: float, seed_n: int, c: Color) -> void:
	var a := seed_n
	var rnd := func():
		a = (a * 1103515245 + 12345) & 0x7fffffff
		return float(a) / 0x7fffffff
	var n := 26
	var start: float = rnd.call() * TAU
	var pts := PackedVector2Array()
	for i in n + 4:
		var tt := start + i * TAU / n
		var kk: float = 1.0 + (rnd.call() - 0.5) * 0.08 + i * 0.004
		pts.append(_to_px(cx + cos(tt) * rx * kk, cy + sin(tt) * ry * kk))
	page.draw_polyline(pts, c, 1.4 * k * 0.5, true)


func _draw_page() -> void:
	var sz := page.size
	k = minf((sz.x - 60.0) / 360.0, (sz.y - 80.0) / 312.0)
	origin = Vector2((sz.x - 360.0 * k) / 2.0, 50.0 + (sz.y - 80.0 - 312.0 * k) / 2.0)
	page.draw_string(Look.font("ui_b"), Vector2(30, 36), "THE FLOOR SKETCH, FROM HIS POCKET", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, RED)
	page.draw_string(Look.font("ui_b"), Vector2(sz.x - 30, 36), "M OR ESC TO PUT IT AWAY", HORIZONTAL_ALIGNMENT_RIGHT, -1, 13, PENCIL)
	var thin := Color(PENCIL, 0.75)
	# outside: the lot, the highway, the water
	_rect(292, 254, 40, 18, INK, 1.4, Color(PENCIL, 0.12))
	_text(312, 250, "pickup", 8.5, PENCIL, "middle")
	_dash(Vector2(0, 296), Vector2(360, 296), thin, 1.0)
	_text(6, 309, "Highway", 9, PENCIL)
	_text(354, 309, "the strait", 9, PENCIL, "end")
	# the deck
	var dk := [Vector2(314, 140), Vector2(348, 140), Vector2(348, 236), Vector2(314, 236), Vector2(314, 140)]
	for i in 4:
		_dash(dk[i], dk[i + 1], thin, 1.0)
	# walls
	_rect(10, 10, 300, 230, INK, 3.0)
	for l in [[10, 58, 310, 58], [100, 10, 100, 58], [130, 10, 130, 36], [172, 10, 172, 36], [214, 10, 214, 36], [256, 10, 256, 36], [130, 36, 256, 36]]:
		_line(Vector2(l[0], l[1]), Vector2(l[2], l[3]), thin, 1.2)
	# doorways, painted over the walls
	for l in [[28, 240, 52, 240], [310, 176, 310, 198], [310, 39, 310, 55], [62, 58, 80, 58], [10, 22, 10, 38], [120, 58, 142, 58], [144, 36, 158, 36], [186, 36, 200, 36], [228, 36, 242, 36]]:
		_line(Vector2(l[0], l[1]), Vector2(l[2], l[3]), PAPER, 4.0)
	_text(151, 27, "Men", 8.5, PENCIL, "middle")
	_text(193, 27, "Women", 8.5, PENCIL, "middle")
	_text(235, 27, "Single", 8.5, PENCIL, "middle")
	_rect(266, 12, 8, 10, INK, 1.2, Color(PENCIL, 0.2))
	_text(316, 34, "Hotel", 8.5, PENCIL)
	_line(Vector2(120, 235), Vector2(252, 235), thin, 1.2)
	# the bar, its stools, the trapdoor
	_rect(18, 76, 22, 122, INK, 1.4, Color(PENCIL, 0.12))
	_rect(24, 82, 10, 10, thin, 1.0)
	_line(Vector2(24, 82), Vector2(34, 92), thin, 1.0)
	_line(Vector2(34, 82), Vector2(24, 92), thin, 1.0)
	for yy in range(104, 185, 20):
		page.draw_arc(_to_px(50, yy), 3.2 * k, 0, TAU, 16, thin, 1.0 * k * 0.5, true)
	page.draw_circle(_to_px(40, 226), 4.5 * k, Color(PENCIL, 0.35))
	# the pool table and the jukebox, the tables, table 28
	_rect(150, 104, 72, 38, INK, 1.4, Color(PENCIL, 0.12))
	_rect(250, 72, 16, 16, INK, 1.4, Color(PENCIL, 0.12))
	_text(258, 100, "Jukebox", 8.5, PENCIL, "middle")
	for tt in [[84, 132], [248, 140], [104, 206], [252, 204]]:
		_rect(tt[0], tt[1], 14, 14, thin, 1.0)
	page.draw_arc(_to_px(186, 206), 15 * k, 0, TAU, 40, INK, 1.4 * k * 0.5, true)
	_text(186, 211.5, "28", 13, INK, "middle", "zilla_b")
	# his notes
	_notes()
	# the places he can go
	for id in SPOTS:
		var s: Dictionary = SPOTS[id]
		var r: float = s.get("r", 10)
		var is_open := open.has(id)
		var c := RED if is_open else Color(PENCIL, 0.45)
		if is_open and hot == id:
			page.draw_circle(_to_px(s.x, s.y), r * k, Color(RED, 0.18))
		page.draw_arc(_to_px(s.x, s.y), r * k, 0, TAU, 32, c, (1.6 if is_open else 1.0) * k * 0.5, true)
		if id != "t28":
			page.draw_circle(_to_px(s.x, s.y), 2.6 * k, c)
		if str(s.get("label", "")) != "":
			_text(s.lx, s.ly, str(s.label), 10.5, RED if is_open else PENCIL, str(s.get("anchor", "middle")), "ui_b")
	# where he is
	var here: String = main.game.here()
	if SPOTS.has(here) or here != "upstairs":
		var at: Dictionary = SPOTS.get(here, SPOTS["floor"])
		var dx := 20.0 if here == "t28" else 12.0
		page.draw_circle(_to_px(at.x + dx, at.y - 10), 5.5 * k, INK)
	if open.is_empty():
		page.draw_string(Look.font("read_i"), Vector2(30, sz.y - 22), "Nowhere to go from here just now.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, PENCIL)
	else:
		page.draw_string(Look.font("read_i"), Vector2(30, sz.y - 22), "A place in red is somewhere he can go now. Click it and he goes.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, PENCIL)


func _notes() -> void:
	var g: Game = main.game
	var S: Dictionary = g.sketch
	var now := int(g.status().clock)
	var pen := Color("27407a")
	var warn := RED
	if S.has("count"):
		var c: Dictionary = S["count"]
		_text(112, 199, "%d at %s" % [int(c.n), _fmt(int(c.at))], 9.5, Color(pen, _fade(now - int(c.at))), "middle")
	if S.has("pool") and int(S["pool"].heat) >= 4:
		var p: Dictionary = S["pool"]
		var hot_p := int(p.heat) >= 7
		var col := Color(warn if hot_p else pen, _fade(now - int(p.at)))
		_pen_ring(186, 123, 48, 28, int(p.at) * 7 + 1, col)
		if hot_p:
			_pen_ring(186, 123, 53, 32, int(p.at) * 7 + 2, col)
		_text(137, 100, _fmt(int(p.at)), 9.5, col, "end")
	if S.has("t28") and int(S["t28"].rounds) > 0:
		var t: Dictionary = S["t28"]
		var col2 := Color(pen, _fade(now - int(t.at)))
		var n := mini(15, int(t.rounds))
		for i in n:
			var gi := i / 5
			var j := i % 5
			var gx := 166.0 + gi * 22.0
			if j < 4:
				_line(Vector2(gx + j * 4, 222), Vector2(gx + j * 4 + 0.6, 231), col2, 1.2)
			else:
				_line(Vector2(gx - 2, 229), Vector2(gx + 15, 224), col2, 1.2)
		_text(206, 199, _fmt(int(t.at)), 9.5, col2, "start")
	var away := int(BUtil.js_int(g.get_var("door_away")))
	if away >= 15:
		_text(40, 256, "door %d min" % away, 9.5, warn, "middle")
	_door_mark(310, 187, 22, S.get("deck"), now, 304, 172, "end")
	_door_mark(310, 47, 16, S.get("hotel"), now, 305, 69, "end")
	_door_mark(10, 30, 16, S.get("kitchen"), now, 15, 70, "start")


func _door_mark(x: float, y: float, h: float, seen, now: int, tx: float, ty: float, anchor: String) -> void:
	if seen == null or not (seen is Dictionary):
		return
	var age := now - int(seen.at)
	var is_open := bool(seen.get("open", false))
	var col := Color(RED if is_open else Color("27407a"), _fade(age))
	var top := y - h / 2.0
	if is_open:
		_line(Vector2(x, top), Vector2(x + h, top), col, 1.4)
		# the swing of the door: a quarter circle from its open edge back to the frame
		var arc := PackedVector2Array()
		for i in 13:
			var a2 := (PI / 2.0) * i / 12.0
			arc.append(_to_px(x + h * cos(a2), top + h * sin(a2)))
		page.draw_polyline(arc, col, 1.2 * k * 0.5, true)
	else:
		_line(Vector2(x, top), Vector2(x, y + h / 2.0), col, 1.6)
	_text(tx, ty, ("propped " if is_open else "shut ") + _fmt(int(seen.at)), 9.5, col, anchor)
