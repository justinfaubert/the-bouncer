# A choice in the column: its number in red, the check a voice lends it, its words, and under
# them how loud the room in his head would get. The hand rests on it (the pointer, a key, his
# eyes on the thing it's about in the room) and a voice may lean in.
class_name ChoiceRow
extends MarginContainer

signal picked(index: int)
signal hand_on(index: int, on: bool)

var index := -1          # among the visible choices
var key := 0             # 1..9, or 0 past nine
var lit := false         # the hand is on it (pointer, key, or his eyes in the room)
var looked := false      # his eyes are on the thing it's about in the room
var body: RichTextLabel
var num: Label
var tip_text := ""       # where a check's number comes from
var _tip: Control


func setup(c: Dictionary, i: int, k: int, size: int, odds_numbers: bool, tension_words: Array) -> void:
	index = i
	key = k
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	add_theme_constant_override("margin_left", 6)
	add_theme_constant_override("margin_right", 8)
	add_theme_constant_override("margin_top", 5)
	add_theme_constant_override("margin_bottom", 6)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	num = UiBits.label((str(k) + ".") if k > 0 else "·", "read", size, Look.RED)
	num.custom_minimum_size = Vector2(size * 1.25, 0)
	num.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	row.add_child(num)
	body = RichTextLabel.new()
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("line_separation", 4)
	row.add_child(body)
	var ck = c.get("check")
	if ck != null:
		var style := str(ck.voice)
		var vc := Look.voice_color(style)
		var odds := ("%d%%" % roundi(float(ck.odds) * 100.0)) if odds_numbers else str(ck.oddsWord)
		body.push_font(UiBits.spaced("ui_b", 1), int(size * 0.74))
		body.push_color(vc)
		body.add_text("[" + str(ck.label) + " · " + str(ck.word) + " " + str(ck.target) + "]")
		body.pop()
		body.push_color(Color(vc, 0.72))
		body.add_text("  " + odds + "   ")
		body.pop()
		body.pop()
		var bits: Array = []
		for m in ck.get("mods", []):
			bits.append(("+" if int(m.value) > 0 else "−") + str(absi(int(m.value))) + " " + str(m.label))
		tip_text = ", ".join(bits) if not bits.is_empty() else "Nothing for or against it tonight."
	body.push_font(Look.font("read"), size)
	body.push_color(Look.INK)
	body.add_text(str(c.text))
	body.pop()
	body.pop()
	var room = c.get("room")
	if room != null:
		body.push_font(UiBits.spaced("ui", 1), int(size * 0.7))
		var t := ""
		var col := Look.MUTED
		if room.full:
			t = "His head is full. Someone has to go first."
			col = Look.BAD
		elif int(room.tension) == int(room.now):
			t = "In his head: still " + str(tension_words[int(room.now)]).to_lower()
		else:
			t = "In his head: " + str(tension_words[int(room.now)]).to_lower() + " to " + str(tension_words[int(room.tension)]).to_lower()
			col = Look.BAD if int(room.tension) > int(room.now) else Look.GOOD
		body.push_color(col)
		body.add_text("\n" + t)
		body.pop()
		body.pop()
	mouse_entered.connect(func(): _hand(true))
	mouse_exited.connect(func(): _hand(false))


func _hand(on: bool) -> void:
	set_lit(on)
	hand_on.emit(index, on)
	if tip_text != "" and on:
		_show_tip()
	elif _tip != null:
		_tip.queue_free()
		_tip = null


# the hand on it from elsewhere than the pointer (a pad's d-pad)
func hand(on: bool) -> void:
	_hand(on)


func set_lit(on: bool) -> void:
	if lit == on:
		return
	lit = on
	num.add_theme_color_override("font_color", Look.STOCK if on else Look.RED)
	queue_redraw()


func set_looked(on: bool) -> void:
	if looked == on:
		return
	looked = on
	queue_redraw()


func _draw() -> void:
	if lit or looked:
		# a rule of red ink down the left, and the band a shade lighter
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.045 if lit else 0.03))
		draw_rect(Rect2(Vector2(-10, 4), Vector2(3, size.y - 8)), Look.RED if lit else Color(Look.RED, 0.6))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		picked.emit(index)


# the check's sum, by the choice
func _show_tip() -> void:
	if _tip != null:
		return
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color("12151d")
	s.border_color = Color(Look.MUTED, 0.5)
	s.set_border_width_all(1)
	s.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiBits.label("Besides the dice: " + tip_text + ".", "ui", 17, Look.INK_2)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(minf(size.x - 40, 380), 0)
	p.add_child(l)
	p.top_level = true
	add_child(p)
	p.global_position = global_position + Vector2(40, -p.get_combined_minimum_size().y - 34)
	_tip = p
