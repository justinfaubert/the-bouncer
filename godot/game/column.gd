# The column: the night in words, beside the room.
#
# A solid of the night ink with the words knocked out of it (look/column.gdshader), on the right of
# the screen. At the top, the day, the clock and where he is. Under it the page, read from the top
# down: what happens, the voices in their own type and colour, the checks, the word on him, and the
# choices at the foot. Older paragraphs dim as new ones come. The whole night stays on the page to
# scroll back through. The incident log is a page of the hardback book; the ledger is a till tape.
#
# The column only draws. What to draw, and when, is the reader's (game/main.gd).
class_name Column
extends Control

signal chose(index: int)
signal hand_on(index: int, on: bool)
signal pointed(index: int, on: bool)
signal end_action(what: String)

const TEXT_SIZES := {"s": 22, "m": 24, "l": 27}
# the places the ways he goes by in the room go to, by name (content/ink/floor.ink, the hub)
const PLACE_WORDS := {"door": "the door", "floor": "the floor", "t28": "table 28", "pool": "the pool table",
	"bar": "the bar", "hall": "the back hall", "kitchen": "the kitchen", "keg": "the keg room",
	"deck": "the deck", "lot": "the pickup", "upstairs": "upstairs"}
# the night's words for a way that's pressing (floor.ink, door_label and pool_label): its name stands out
static var _pressing := RegEx.create_from_string("^(Get back|Back on)|getting loud|been an hour")
const PAD_L := 44.0
const PAD_R := 40.0

var settings: Dictionary
var size_px := 24

var bg: ColorRect
var head_day: Label
var head_clock: RichTextLabel
var head_row: RichTextLabel
var scroll: ScrollContainer
var page: VBoxContainer
var story: VBoxContainer
var choices_box: VBoxContainer
var foot: Label
var more: Label

var block: Control              # the block new lines go into
var block_box: VBoxContainer    # where its lines go
var block_screen = null         # null (the page), "log" or "ledger"
var batch: Array = []           # this batch's nodes, to fade in
var older: Array = []           # the last batch's, to dim when the next comes
var rows: Array = []            # ChoiceRows and way chips, in key order
var _reveal: Tween
var _scroll_tw: Tween
var _follow := true             # keep the newest lines in view


func setup(s: Dictionary) -> void:
	settings = s
	size_px = TEXT_SIZES.get(s.get("text", "m"), 24)
	mouse_filter = Control.MOUSE_FILTER_PASS
	bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://look/column.gdshader")
	cm.set_shader_parameter("paper_tex", Pub.tex_static("res://press/paper.png", false))
	cm.set_shader_parameter("paper", Look.STOCK)
	cm.set_shader_parameter("ink_night", Look.NIGHT)
	bg.material = cm
	add_child(bg)

	# the head: the day, the clock, where he is; what's in his pocket and in him
	var head := VBoxContainer.new()
	head.position = Vector2(PAD_L, 26)
	head.add_theme_constant_override("separation", 0)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	head_day = UiBits.label("WEDNESDAY, THE TEST SHIFT", "ui_b", 16, Look.MUTED, 3)
	head.add_child(head_day)
	head_clock = RichTextLabel.new()
	head_clock.fit_content = true
	head_clock.scroll_active = false
	head_clock.autowrap_mode = TextServer.AUTOWRAP_OFF
	head_clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_clock.custom_minimum_size = Vector2(560, 0)
	head.add_child(head_clock)
	head_row = RichTextLabel.new()
	head_row.fit_content = true
	head_row.scroll_active = false
	head_row.autowrap_mode = TextServer.AUTOWRAP_OFF
	head_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.custom_minimum_size = Vector2(560, 0)
	head.add_child(head_row)

	scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = PAD_L - 14
	scroll.offset_right = -PAD_R + 14
	scroll.offset_top = 150
	scroll.offset_bottom = -42
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus = false
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 0)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(margin)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	page.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(page)
	story = VBoxContainer.new()
	story.add_theme_constant_override("separation", 22)
	story.mouse_filter = Control.MOUSE_FILTER_PASS
	page.add_child(story)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 26)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(gap)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 6)
	choices_box.mouse_filter = Control.MOUSE_FILTER_PASS
	page.add_child(choices_box)
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 90)
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(tail)
	scroll.get_v_scroll_bar().value_changed.connect(_on_scrolled)

	foot = UiBits.label("TAB  HIS NOTES      M  THE SKETCH      ESC  MENU", "ui_b", 13, Look.FAINT, 2)
	foot.anchor_top = 1.0
	foot.anchor_bottom = 1.0
	foot.offset_top = -34
	foot.offset_left = PAD_L
	add_child(foot)
	more = UiBits.label("MORE BELOW", "ui_b", 13, Look.RED, 2)
	more.anchor_left = 1.0
	more.anchor_right = 1.0
	more.anchor_top = 1.0
	more.anchor_bottom = 1.0
	more.offset_left = -160
	more.offset_top = -34
	more.visible = false
	add_child(more)
	reset()


func apply_settings() -> void:
	size_px = TEXT_SIZES.get(settings.get("text", "m"), 24)


# a fresh night
func reset() -> void:
	for c in story.get_children():
		c.queue_free()
	clear_choices()
	block = null
	block_box = null
	block_screen = null
	batch.clear()
	older.clear()
	scroll.scroll_vertical = 0


# ---------------------------------------------------------------- the head

var _head_place := ""


# the head: the day, the clock (shown_clock: the clock the head is showing, which runs up to the
# night's as he walks and as the lines come in: game/main.gd), where he is, and what's on him
func set_status(st: Dictionary, shown_clock := -1) -> void:
	var day: String = Look.DAY_NAMES.get(int(st.get("day", 1)), "Day %d" % int(st.get("day", 1)))
	var part := "the interview" if str(st.get("here", "")) == "office" else ("before the shift" if int(st.clock) < 1180 else "the test shift")
	head_day.text = (day + ", " + part).to_upper()
	_head_place = str(Look.PLACE.get(str(st.here), "")).to_upper()
	show_clock(int(st.clock) if shown_clock < 0 else shown_clock)
	_status_row(st)


func show_clock(c: int) -> void:
	var cp := BUtil.clock_parts(c)
	head_clock.clear()
	head_clock.push_font(Look.font("display"), 46)
	head_clock.push_color(Look.INK)
	head_clock.add_text(str(cp.text))
	head_clock.pop()
	head_clock.pop()
	head_clock.push_font(UiBits.spaced("ui_b", 2), 18)
	head_clock.push_color(Look.MUTED)
	head_clock.add_text(" " + str(cp.ampm).to_upper() + "     ")
	head_clock.pop()
	head_clock.push_color(Look.INK_2)
	head_clock.add_text(_head_place)
	head_clock.pop()
	head_clock.pop()


func _status_row(st: Dictionary) -> void:
	head_row.clear()
	# what his size is holding off (engine/checks.gd, felt): only the ones that show count
	var felt := int(st.get("felt", st.drinks))
	var held_off := ("feels like " + (str(felt) if felt > 0 else "none")) if felt < int(st.drinks) else ""
	var bits := [["POCKET", "$" + str(int(st.cash)), ""], ["DRINKS", Look.tally(int(st.drinks)), held_off]]
	if int(st.hurt) > 0:
		bits.append(["HURT", Look.HURT_WORDS[clampi(int(st.hurt), 0, 3)], ""])
	for i in bits.size():
		head_row.push_font(UiBits.spaced("ui_b", 2), 14)
		head_row.push_color(Look.MUTED)
		head_row.add_text(bits[i][0] + "  ")
		head_row.pop()
		head_row.pop()
		head_row.push_font(UiBits.spaced("ui_b", 1), 19)
		head_row.push_color(Look.BAD if bits[i][0] == "HURT" else Look.INK_2)
		head_row.add_text(bits[i][1])
		head_row.pop()
		head_row.pop()
		if bits[i][2] != "":
			head_row.push_font(UiBits.spaced("ui", 1), 14)
			head_row.push_color(Look.MUTED)
			head_row.add_text("  " + bits[i][2])
			head_row.pop()
			head_row.pop()
		if i < bits.size() - 1:
			head_row.push_font(UiBits.spaced("ui_b", 1), 19)
			head_row.add_text("        ")
			head_row.pop()


# ---------------------------------------------------------------- blocks

func use_screen(name) -> void:
	if block != null and block_screen == name:
		return
	block_screen = name
	if name == "ledger":
		var tape := TapeBlock.new()
		tape.kind = "ledger"
		block = tape
		block_box = tape.box
		story.add_child(tape)
	elif name == "log":
		var bk := TapeBlock.new()
		bk.kind = "log"
		block = bk
		block_box = bk.box
		story.add_child(bk)
	else:
		var b := VBoxContainer.new()
		b.add_theme_constant_override("separation", 16)
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		block = b
		block_box = b
		story.add_child(b)


func _add(node: Control, screen = "keep") -> Control:
	if screen is String and screen == "keep":
		if block == null:
			use_screen(null)
	else:
		use_screen(screen)
	block_box.add_child(node)
	batch.append(node)
	return node


# the lines of the last batch go back a shade when new ones come
func begin_batch() -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	for n in batch:
		if is_instance_valid(n):
			n.modulate.a = 1.0
			n.set_meta("shown", true)
	for n in older:
		if is_instance_valid(n) and n.modulate.a > 0.6:
			n.modulate.a = 0.62
	older = batch.duplicate()
	batch.clear()


func _screen_of(it: Dictionary):
	return it.get("screen", null)


# ---------------------------------------------------------------- lines

func add_line(it: Dictionary) -> Control:
	var s := size_px
	var scr = _screen_of(it)
	var role := str(it.get("role", "narration"))
	var text := str(it.get("text", ""))
	if scr == "ledger":
		return _add(_tape_line(it), scr)
	if scr == "log":
		return _add(_log_line(it), scr)
	var r: RichTextLabel
	match role:
		"voice":
			var st := str(it.get("speaker", "father"))
			var v := Look.voice(st)
			r = UiBits.para([["ui_b", int(s * 0.74), v.color, str(it.get("label", "")) + "   "],
				[v.font, int(s * float(v.size)), v.color, Look.voice_text(v, text)]])
		"dialogue":
			r = UiBits.para([["ui_b", int(s * 0.74), Look.INK_2, str(it.get("label", "")) + "   "], ["read", s, Look.INK, text]])
		"teller":
			r = UiBits.para([["read_i", s, Look.INK_2, text]])
			var m := MarginContainer.new()
			m.add_theme_constant_override("margin_left", 18)
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			m.add_child(r)
			m.draw.connect(func(): m.draw_rect(Rect2(0, 3, 2, m.size.y - 6), Color("c9a15b")))
			return _add(m, scr)
		_:
			r = UiBits.para([["read", s, Look.INK, text]])
	return _add(r, scr)


# A line on the till tape: what, a run of dots, how much; the head of the tape, a small line under
# a row, the bartender's word, the stamp at the bottom.
func _tape_line(it: Dictionary) -> Control:
	var s := int(size_px * 0.8)
	var cls := str(it.get("cls", "")) if it.get("cls") != null else ""
	var text := str(it.get("text", ""))
	if str(it.get("role", "")) == "voice" or str(it.get("role", "")) == "dialogue":
		text = str(it.get("label", "")) + ": " + text
	var ink := Look.RECEIPT_INK
	match cls:
		"row":
			var cut := text.find(": ")
			var row := TapeRow.new()
			row.key = (text.substr(0, cut) if cut > 0 else text).to_upper()
			row.value = text.substr(cut + 2) if cut > 0 else ""
			row.font = Look.font("receipt")
			row.fsize = s
			row.ink = ink
			return row
		"sub":
			var m := MarginContainer.new()
			m.add_theme_constant_override("margin_left", 24)
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var l := UiBits.label(text, "receipt", int(s * 0.9), ink)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			m.add_child(l)
			return m
		"head":
			# spaced out, unless it's too long to stay on one line that way
			var l := UiBits.label(text, "receipt_b", s + (2 if text.begins_with("THE ") else 0), ink, 2 if text.length() <= 24 else 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			return l
		"total":
			var box := VBoxContainer.new()
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var rule := ColorRect.new()
			rule.color = ink
			rule.custom_minimum_size = Vector2(0, 3)
			box.add_child(rule)
			var l := UiBits.label(text, "receipt_b", s + 1, ink)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(l)
			return box
		"end":
			var st := StampLabel.new()
			st.text = text
			return st
	var caps := text.length() > 3 and text == text.to_upper() and text.to_lower() != text
	var l := UiBits.label(text, "receipt_b" if caps else "receipt", s, ink, 1 if caps else 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if caps or str(it.get("role", "")) == "teller":
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


# A line in the incident log: the book's page, and what he writes in it in his own hand.
func _log_line(it: Dictionary) -> Control:
	var s := size_px
	var cls := str(it.get("cls", "")) if it.get("cls") != null else ""
	var role := str(it.get("role", "narration"))
	var text := str(it.get("text", ""))
	if cls == "entry":
		return UiBits.para([["hand_l", int(s * 1.08), Color("2b3e5c"), text]])
	if role == "voice":
		var st := str(it.get("speaker", "father"))
		var v := Look.voice(st)
		var dark := Look.voice_color(st).darkened(0.55)
		return UiBits.para([["ui_b", int(s * 0.72), dark, str(it.get("label", "")) + "   "], [v.font, int(s * float(v.size) * 0.95), dark, Look.voice_text(v, text)]])
	if role == "dialogue":
		return UiBits.para([["ui_b", int(s * 0.72), Color("4a4640"), str(it.get("label", "")) + "   "], ["read", int(s * 0.95), Look.RECEIPT_INK, text]])
	return UiBits.para([["read", int(s * 0.95), Look.RECEIPT_INK, text]])


func add_chosen(it: Dictionary) -> Control:
	var s := size_px
	var parts: Array = [["ui_b", int(s * 0.9), Look.RED, "▪  "]]
	var ck = it.get("check")
	var scr = block_screen
	var dark: bool = scr == "log" or scr == "ledger"
	# a read he kept: what that voice made of the thing in his hand, in its own hand (content/ink/hand.ink)
	if it.get("read") != null:
		var style := voice_style(str(it.read))
		var v := Look.voice(style)
		parts.append(["ui_b", int(s * 0.74), v.color, _voice_label(str(it.read)) + "   "])
		parts.append([v.font, int(s * float(v.size)), v.color, Look.voice_text(v, str(it.text))])
		var rm := MarginContainer.new()
		rm.add_theme_constant_override("margin_top", 10)
		rm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rm.add_child(UiBits.para(parts))
		return _add(rm)
	if ck != null:
		var style := str(ck.voice)
		parts.append(["ui_b", int(s * 0.8), Look.voice_color(style).darkened(0.5 if dark else 0.0), "[" + _voice_label(style) + "]  "])
	parts.append(["ui", int(s * 0.94), Color("4a4640") if dark else Look.MUTED, str(it.text)])
	var r := UiBits.para(parts)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 10)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(r)
	return _add(m)


var voice_labels := {}
var voice_styles := {}


func _voice_label(id: String) -> String:
	return str(voice_labels.get(id, id.to_upper()))


func voice_style(id: String) -> String:
	return str(voice_styles.get(id, id))


func add_check(it: Dictionary, odds_text: String) -> CheckCard:
	var card := CheckCard.new()
	card.setup(it, odds_text, size_px)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_top", 2)
	m.add_theme_constant_override("margin_bottom", 6)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(card)
	_add(m, null)
	return card


# The word on him: what a group will say about what he's just done, stamped under the line where
# it landed. Red when it went against him.
func add_word(it: Dictionary) -> Control:
	if not BUtil.js_truthy(it.get("text")):
		return null
	var s := size_px
	var down := str(it.get("way", "up")) == "down"
	# the stamp, then what they're saying, set to the right of the page; a long one wraps in the
	# room the stamp leaves it, never down to a letter a line
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var who := StampLabel.new()
	who.text = str(it.get("who", it.get("group", ""))).to_upper()
	who.small = true
	who.ink = Look.RED if down else Look.INK_2
	who.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var q := UiBits.label("“" + str(it.text) + "”", "read_i", int(s * 0.94), Look.INK_2)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(q)
	h.add_child(who)
	return _add(h, _screen_of(it))


# a small note in the margin: a task noted or done, a voice let in or put out, a stat moving.
# parts: [text, bold] or [text, bold, struck through]
func add_aside(parts: Array) -> Control:
	var s := size_px
	var bb: Array = []
	for p in parts:
		bb.append(["ui_b" if p[1] else "ui", int(s * 0.8), Look.INK_2 if p[1] else Look.MUTED, p[0], p.size() > 2 and bool(p[2])])
	return _add(UiBits.para(bb))


# His seven stats, printed once where the camera becomes his (#stats, content/ink/walk.ink), out
# of ten, with the scale under them (prototype/web/src/ui/app.js, statsNode)
func add_stats(it: Dictionary) -> Control:
	var s := size_px
	var stats: Dictionary = it.get("stats", {}) if it.get("stats") is Dictionary else {}
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(Look.INK_2, 0.8)
	sb.set_border_width_all(2)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	v.add_child(UiBits.label("HIM", "display", int(s * 1.3), Look.INK, 5))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grid)
	for k in Checks.STAT_ORDER:
		var n := BUtil.js_int(stats.get(k, 0))
		grid.add_child(UiBits.label(str(Checks.STATS[k].label), "ui", int(s * 0.86), Look.INK_2, 1))
		var pips := Control.new()
		pips.custom_minimum_size = Vector2(10 * 13, int(s * 0.86))
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.size_flags_vertical = Control.SIZE_FILL
		pips.draw.connect(func():
			for i in 10:
				var c := Vector2(6 + i * 13, pips.size.y * 0.55)
				if i < n:
					pips.draw_circle(c, 4.5, Look.INK_2)
				else:
					pips.draw_arc(c, 4.0, 0, TAU, 20, Color(Look.MUTED, 0.8), 1.25, true))
		grid.add_child(pips)
		var num := UiBits.label(str(n), "ui_b", int(s * 0.9), Look.INK, 1)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(num)
	v.add_child(UiBits.label("Out of 10. An ordinary man is a 4.", "ui", int(s * 0.72), Look.MUTED, 1))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 10)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(p)
	return _add(m)


# where he's walked into, and the time: a strip across the page
func add_place(it: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap := UiBits.label(str(Look.CAPTION.get(str(it.here), str(it.here))).to_upper(), "ui_b", 15, Look.MUTED, 3)
	h.add_child(cap)
	var rule := Control.new()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.custom_minimum_size = Vector2(20, 16)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.draw.connect(func(): rule.draw_line(Vector2(0, rule.size.y * 0.55), Vector2(rule.size.x, rule.size.y * 0.55), Look.RULE, 1.0))
	h.add_child(rule)
	h.add_child(UiBits.label(Look.clock_text(int(it.get("clock", 0))).to_upper(), "ui_b", 15, Look.MUTED, 2))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	return _add(m, null)


# a writing prompt: where the draft needs Hutch's material
func add_prompt(text: String) -> Control:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = Color("c9a15b", 0.7)
	s.set_border_width_all(1)
	s.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := UiBits.para([["ui_b", int(size_px * 0.66), Color("c9a15b"), "FOR HUTCH   "], ["ui", int(size_px * 0.82), Look.INK_2, text]])
	p.add_child(r)
	return _add(p)


func add_note(text: String) -> Control:
	return _add(UiBits.para([["ui_b", int(size_px * 0.8), Look.INK_2, text]]))


# "Go on": the rest of the batch waits behind a #pause in the Ink
func add_pause(on_go: Callable) -> Control:
	var b := UiBits.button("Go on", true, int(size_px * 0.9))
	b.pressed.connect(func():
		b.queue_free()
		on_go.call())
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(b)
	h.add_child(UiBits.label("   SPACE", "ui_b", 13, Look.FAINT, 2))
	return _add(h, null)


# ---------------------------------------------------------------- choices

func clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()
	rows.clear()


# list: the visible choices; the ways out of a place (#class: move) go in a row under the rest. hide:
# the ways he goes by in the room instead (game/going.gd), which aren't numbered here; where there
# are any, a line under the rest says so and names where they go.
func show_choices(list: Array, tension_words: Array, hide: Array = []) -> void:
	clear_choices()
	var main_idx: Array = []
	var ways: Array = []
	var reads: Array = []
	for i in list.size():
		if i in hide:
			continue
		if str(list[i].get("cls", "")) == "move":
			ways.append(i)
		elif list[i].get("read") != null:
			reads.append(i)
		else:
			main_idx.append(i)
	var k := 0
	# what the voices make of the thing in his hand: he keeps one of them, or none, and then does
	# something with it (content/ink/hand.ink)
	if not reads.is_empty():
		var head := UiBits.label("WHAT HE MAKES OF IT", "ui_b", 15, Look.MUTED, 3)
		head.custom_minimum_size = Vector2(0, 30)
		head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choices_box.add_child(head)
	for i in reads:
		k += 1
		var row := ChoiceRow.new()
		var c: Dictionary = list[i]
		row.read_label = _voice_label(str(c.read.voice))
		row.read_style = voice_style(str(c.read.voice))
		row.setup(c, i, k if k <= 9 else 0, size_px, settings.get("odds", "words") == "numbers", tension_words)
		row.picked.connect(func(ix): chose.emit(ix))
		row.hand_on.connect(func(ix, on): hand_on.emit(ix, on))
		choices_box.add_child(row)
		rows.append(row)
	if not reads.is_empty() and not main_idx.is_empty():
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 12)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choices_box.add_child(gap)
	for i in main_idx:
		k += 1
		var row := ChoiceRow.new()
		row.setup(list[i], i, k if k <= 9 else 0, size_px, settings.get("odds", "words") == "numbers", tension_words)
		row.picked.connect(func(ix): chose.emit(ix))
		row.hand_on.connect(func(ix, on): hand_on.emit(ix, on))
		choices_box.add_child(row)
		rows.append(row)
	if not ways.is_empty():
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 8)
		flow.mouse_filter = Control.MOUSE_FILTER_PASS
		var lab := UiBits.label("OR GO" if not main_idx.is_empty() else "GO", "ui_b", 15, Look.MUTED, 3)
		lab.custom_minimum_size = Vector2(0, 34)
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		flow.add_child(lab)
		for i in ways:
			k += 1
			var c: Dictionary = list[i]
			var chip := WayChip.new()
			chip.setup(c, i, k if k <= 9 else 0, str(c.text).begins_with("Back on the door"))
			chip.picked.connect(func(ix): chose.emit(ix))
			chip.hand_on.connect(func(ix, on): hand_on.emit(ix, on))
			flow.add_child(chip)
			rows.append(chip)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_top", 10 if not main_idx.is_empty() else 0)
		m.mouse_filter = Control.MOUSE_FILTER_PASS
		m.add_child(flow)
		choices_box.add_child(m)
	# the ways he goes by in the room, named after it, without numbers: a click on one is the same as
	# a click on the place, and a hand on one rings the place in the room, where he can see it
	if not hide.is_empty():
		var gflow := HFlowContainer.new()
		gflow.add_theme_constant_override("h_separation", 10)
		gflow.add_theme_constant_override("v_separation", 8)
		gflow.mouse_filter = Control.MOUSE_FILTER_PASS
		var go := UiBits.label(("OR GO" if not main_idx.is_empty() or not ways.is_empty() else "GO") + " WHERE HE LOOKS", "ui_b", 15, Look.MUTED, 3)
		go.custom_minimum_size = Vector2(0, 34)
		go.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		go.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gflow.add_child(go)
		for i in hide:
			var c: Dictionary = list[i]
			var chip := WayChip.new()
			chip.setup({"text": place_word(c)}, i, 0, _pressing.search(str(c.get("text", ""))) != null)
			chip.picked.connect(func(ix): chose.emit(ix))
			chip.hand_on.connect(func(ix, on):
				hand_on.emit(ix, on)
				pointed.emit(ix, on))
			gflow.add_child(chip)
			rows.append(chip)
		var gm := MarginContainer.new()
		gm.add_theme_constant_override("margin_top", 10 if not main_idx.is_empty() or not ways.is_empty() else 0)
		gm.mouse_filter = Control.MOUSE_FILTER_PASS
		gm.add_child(gflow)
		choices_box.add_child(gm)
	_fade_in_choices()


# A way he goes by in the room, by the name of where it goes (the night's words for it come up
# beside the place itself, game/hotspots.gd).
static func place_word(c: Dictionary) -> String:
	var text := str(c.get("text", ""))
	var loc = c.get("loc")
	var l := "" if loc == null else str(loc)
	if l == "pool" and text.containsn("jukebox"):
		return "the jukebox"
	if PLACE_WORDS.has(l):
		return PLACE_WORDS[l]
	return text.trim_suffix(".")


func show_end(stamped: bool) -> void:
	clear_choices()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	if not stamped:
		v.add_child(UiBits.label("END OF THE TEST SHIFT", "ui_b", 30, Look.INK, 3))
	var p := UiBits.para([["read", size_px, Look.INK_2, "Friday comes next, and it is not written yet. This night stays saved the way it ended until you start Wednesday over."]])
	v.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 26)
	for pair in [["Copy the night", "copy", true], ["Start Wednesday over", "restart", false], ["Back to the title", "title", false]]:
		var b := UiBits.button(pair[0], pair[2], 20)
		var what: String = pair[1]
		b.pressed.connect(func(): end_action.emit(what))
		h.add_child(b)
	v.add_child(h)
	choices_box.add_child(v)
	_fade_in_choices()


func _fade_in_choices() -> void:
	choices_box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.05 if settings.get("reveal", "lines") == "all" else minf(0.25 + batch.size() * 0.07, 1.5))
	tw.tween_property(choices_box, "modulate:a", 1.0, 0.25)


func row_for_key(k: int) -> Control:
	for r in rows:
		if r.key == k:
			return r
	return null


func row_for_index(i: int) -> Control:
	for r in rows:
		if r.index == i:
			return r
	return null


# ---------------------------------------------------------------- reveal and scroll

# the batch's new lines, one after another
func reveal(live: bool) -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
		for node in batch:
			if is_instance_valid(node) and node.get_meta("shown", false):
				node.modulate.a = 1.0
	if not live or settings.get("reveal", "lines") == "all":
		for node in batch:
			if is_instance_valid(node):
				node.modulate.a = 1.0
				node.set_meta("shown", true)
		return
	var fresh: Array = []
	for node in batch:
		if is_instance_valid(node) and not node.get_meta("shown", false):
			fresh.append(node)
	if fresh.is_empty():
		return
	_reveal = create_tween()
	_reveal.set_parallel(true)
	for k in fresh.size():
		var node: Control = fresh[k]
		node.modulate.a = 0.0
		node.set_meta("shown", true)
		_reveal.tween_property(node, "modulate:a", 1.0, 0.32).set_delay(minf(k * 0.07, 1.4))


# show everything now
func hurry() -> bool:
	var busy := _reveal != null and _reveal.is_valid() and _reveal.is_running()
	if busy:
		_reveal.kill()
		for n in batch:
			if is_instance_valid(n):
				n.modulate.a = 1.0
		choices_box.modulate.a = 1.0
	return busy


# bring a node to the top of the page, a little below the rule
func scroll_to(node: Control) -> void:
	_follow = true
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(node):
		return
	var y := node.global_position.y - page.global_position.y - 18.0
	var bar := scroll.get_v_scroll_bar()
	var target := clampf(y, 0.0, maxf(0.0, bar.max_value - bar.page))
	if _scroll_tw != null and _scroll_tw.is_valid():
		_scroll_tw.kill()
	_scroll_tw = create_tween()
	_scroll_tw.tween_property(scroll, "scroll_vertical", int(target), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func scroll_to_end() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var bar := scroll.get_v_scroll_bar()
	scroll.scroll_vertical = int(maxf(0.0, bar.max_value - bar.page))


# keep a node in view (a line gone in above the choices)
func keep_in_view(node: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(node):
		return
	var top := node.global_position.y - scroll.global_position.y
	var bottom := top + node.size.y
	if top >= 8 and bottom <= scroll.size.y - 8:
		return
	scroll.scroll_vertical += int(top - maxf(40.0, scroll.size.y * 0.3))


func scroll_by(px: float) -> void:
	scroll.scroll_vertical += int(px)


func is_reading_back() -> bool:
	var bar := scroll.get_v_scroll_bar()
	return bar.max_value - bar.page - scroll.scroll_vertical > scroll.size.y * 1.6


func _on_scrolled(_v: float) -> void:
	_update_more()


func _process(_d: float) -> void:
	_update_more()


func _update_more() -> void:
	if choices_box.get_child_count() == 0:
		more.visible = false
		return
	var bar := scroll.get_v_scroll_bar()
	var below := bar.max_value - bar.page - scroll.scroll_vertical
	var choices_top := choices_box.global_position.y - scroll.global_position.y
	more.visible = below > 40 and choices_top > scroll.size.y - 30


# ---------------------------------------------------------------- pieces

# A way out of a place: a chip in the row under the choices.
class WayChip extends MarginContainer:
	signal picked(index: int)
	signal hand_on(index: int, on: bool)
	var index := -1
	var key := 0
	var lit := false
	var looked := false
	var hot := false
	var _l: Label

	func setup(c: Dictionary, i: int, k: int, is_hot: bool) -> void:
		index = i
		key = k
		hot = is_hot
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_theme_constant_override("margin_left", 10)
		add_theme_constant_override("margin_right", 12)
		add_theme_constant_override("margin_top", 4)
		add_theme_constant_override("margin_bottom", 5)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 7)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h)
		if k > 0:
			h.add_child(UiBits.label(str(k), "ui_b", 17, Look.RED))
		_l = UiBits.label(str(c.text), "ui_b", 19, Look.INK if hot else Look.INK_2, 1)
		h.add_child(_l)
		mouse_entered.connect(func():
			set_lit(true)
			hand_on.emit(index, true))
		mouse_exited.connect(func():
			set_lit(false)
			hand_on.emit(index, false))

	func set_lit(on: bool) -> void:
		lit = on
		queue_redraw()

	# the hand on it from elsewhere than the pointer (a pad's d-pad)
	func hand(on: bool) -> void:
		set_lit(on)
		hand_on.emit(index, on)

	func set_looked(on: bool) -> void:
		looked = on
		queue_redraw()

	func _draw() -> void:
		var c := Look.RED if (lit or looked) else (Color(Look.RED, 0.75) if hot else Look.RULE)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.05) if lit else Color(0, 0, 0, 0), true)
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), c, false, 1.0)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			picked.emit(index)


# A block that isn't the page: the till tape at close, or the incident log's page.
class TapeBlock extends MarginContainer:
	var kind := "ledger"
	var box: VBoxContainer
	var feeding := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		box = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)

	func _ready() -> void:
		if kind == "ledger":
			box.add_theme_constant_override("separation", 9)
			add_theme_constant_override("margin_left", 70)
			add_theme_constant_override("margin_right", 70)
			add_theme_constant_override("margin_top", 30)
			add_theme_constant_override("margin_bottom", 40)
		else:
			box.add_theme_constant_override("separation", 10)
			add_theme_constant_override("margin_left", 64)
			add_theme_constant_override("margin_right", 22)
			add_theme_constant_override("margin_top", 26)
			add_theme_constant_override("margin_bottom", 26)

	func _draw() -> void:
		if kind == "ledger":
			# the tape: narrower than the page, its foot torn in teeth
			var r := Rect2(Vector2(40, 0), Vector2(size.x - 80, size.y - 10))
			draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.35))
			draw_rect(r, Look.RECEIPT)
			var teeth := PackedVector2Array()
			var x := r.position.x
			var y := r.end.y
			teeth.append(Vector2(x, y))
			var w := 16.0
			while x < r.end.x - 0.1:
				teeth.append(Vector2(minf(x + w / 2.0, r.end.x), y + 9))
				x = minf(x + w, r.end.x)
				teeth.append(Vector2(x, y))
			teeth.append(Vector2(r.end.x, y))
			if not feeding:
				draw_colored_polygon(teeth, Look.RECEIPT)
		else:
			# a page of the hardback log: ruled, with the red double rule down the margin
			var r := Rect2(Vector2(0, 0), size)
			draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.35))
			draw_rect(r, Color("d8d4c6"))
			var y := 30.0
			while y < size.y - 8:
				draw_line(Vector2(0, y), Vector2(size.x, y), Color("b8c4c8"), 1.0)
				y += 32.0
			draw_line(Vector2(44, 0), Vector2(44, size.y), Color("c0463b"), 1.0)
			draw_line(Vector2(48, 0), Vector2(48, size.y), Color("c0463b"), 1.0)


# A row on the till tape: what, a run of dots, and how much, the way a till prints in its one
# typeface on a grid of characters. When the how-much won't fit on the line with its what, the dots
# run out to the edge and it prints underneath, indented, on as many lines as it takes.
class TapeRow extends Control:
	const INDENT := 3                 # characters in, for a how-much on the lines under
	var key := ""
	var value := ""
	var font: Font
	var fsize := 19
	var ink := Color.BLACK
	var _cw := 11.0                   # a character's width: the grid
	var _lh := 26.0
	var _under: TextParagraph = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_cw = font.get_char_size(ord("M"), fsize).x
		_lh = ceilf(font.get_height(fsize) + 5.0)
		custom_minimum_size = Vector2(0, _lh)
		resized.connect(_layout)
		_layout()

	func _cols() -> int:
		return int(floor(size.x / _cw))

	func _layout() -> void:
		var cols := _cols()
		if cols < 8:
			return
		# the what, two dots at least, a space, the how-much
		if value == "" or key.length() + 3 + value.length() <= cols:
			_under = null
			custom_minimum_size.y = _lh
		else:
			_under = TextParagraph.new()
			_under.add_string(value, font, fsize)
			_under.width = (cols - INDENT) * _cw
			custom_minimum_size.y = _lh + ceilf(_under.get_size().y) + 3.0
		queue_redraw()

	func _draw() -> void:
		var cols := _cols()
		var base := font.get_ascent(fsize) + 2.0
		draw_string(font, Vector2(0, base), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, ink)
		var stop := cols
		if _under == null and value != "":
			stop = cols - value.length() - 1
			draw_string(font, Vector2((cols - value.length()) * _cw, base), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, ink)
		var dot := Color(ink, 0.45)
		for i in range(key.length() + 1, stop):
			draw_string(font, Vector2(i * _cw, base), ".", HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, dot)
		if _under != null:
			_under.draw(get_canvas_item(), Vector2(INDENT * _cw, _lh - 2.0), ink)


# A stamp: letters in a box, knocked a little crooked. On the tape it's the end of the shift; small,
# it's who's saying the word on him.
class StampLabel extends Control:
	var text := ""
	var small := false
	var ink := Look.RECEIPT_RED
	var _font: Font
	var _size := 28

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_font = UiBits.spaced("ui_b", 3 if small else 4)
		_size = 14 if small else 30
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size).x
		custom_minimum_size = Vector2(w + (18 if small else 34), _size + (12 if small else 26))
		if not small:
			size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var c := ink
		draw_set_transform(size / 2.0, deg_to_rad(-1.4 if small else -4.0), Vector2.ONE)
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size).x
		var box := Rect2(Vector2(-w / 2.0 - (7 if small else 13), -_size / 2.0 - (4 if small else 8)), Vector2(w + (14 if small else 26), _size + (8 if small else 16)))
		draw_rect(box, c, false, 1.5 if small else 3.0)
		draw_string(_font, Vector2(-w / 2.0, _size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, c)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
