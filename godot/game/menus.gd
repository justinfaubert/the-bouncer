# The menus: the title, the pause, the nights, the settings, how it plays, a question, a note.
#
# They print where the column is, on the same night ink, so the room stays in view on the left:
# on the title it's the door, the rain on its glass, the pickup's lights beyond.
class_name Menus
extends Control

var main
var sheet: Control
var box: VBoxContainer
var scroll: ScrollContainer
var screen := ""          # title, pause, nights, settings, help, confirm
var came_from := ""
var _toast: Label
var _toast_tw: Tween


func setup(m) -> void:
	main = m
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet = Control.new()
	sheet.anchor_left = View.WORLD_W
	sheet.anchor_right = 1.0
	sheet.anchor_bottom = 1.0
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(sheet)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://look/column.gdshader")
	cm.set_shader_parameter("paper_tex", Pub.tex_static("res://press/paper.png", false))
	cm.set_shader_parameter("paper", Look.STOCK)
	cm.set_shader_parameter("ink_night", Look.NIGHT)
	bg.material = cm
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(bg)
	scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 58
	scroll.offset_right = -46
	scroll.offset_top = 70
	scroll.offset_bottom = -40
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sheet.add_child(scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)
	_toast = UiBits.label("", "ui_b", 20, Look.INK, 1)
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.anchor_right = View.WORLD_W
	_toast.offset_top = -70
	_toast.offset_left = 40
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_toast.modulate.a = 0.0
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(Look.NIGHT, 0.92)
	ts.set_content_margin_all(12)
	_toast.add_theme_stylebox_override("normal", ts)
	add_child(_toast)
	sheet.visible = false


func is_open() -> bool:
	return sheet.visible


func hide_all() -> void:
	sheet.visible = false
	screen = ""


func _clear() -> void:
	for c in box.get_children():
		c.queue_free()
	scroll.scroll_vertical = 0


func _open(name: String) -> void:
	_clear()
	screen = name
	sheet.visible = true


func _gap(h: int) -> void:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	box.add_child(g)


func _head(text: String, small := "") -> void:
	if small != "":
		box.add_child(UiBits.label(small.to_upper(), "ui_b", 16, Look.MUTED, 3))
	var l := UiBits.label(text, "display", 64, Look.INK, 1)
	box.add_child(l)


func _para(text: String, size := 22, color := Look.INK_2) -> RichTextLabel:
	var r := UiBits.para([["read", size, color, text]])
	box.add_child(r)
	return r


func _button(text: String, primary: bool, fn: Callable, size := 26) -> Button:
	var b := UiBits.button(text, primary, size)
	b.pressed.connect(func():
		main.audio.sfx("click_ui")
		fn.call())
	box.add_child(b)
	return b


func _focus_first() -> void:
	await get_tree().process_frame
	for c in box.get_children():
		if c is Button:
			c.grab_focus()
			return


# ---------------------------------------------------------------- the title

func title() -> void:
	_open("title")
	main.view.jump_to("door")
	main.view.look_at_point(Vector3(3.45, 1.35, 10.1))
	_gap(40)
	box.add_child(UiBits.label("WEDNESDAY, THE TEST SHIFT", "ui_b", 18, Look.MUTED, 4))
	var t := UiBits.label("THE BOUNCER", "display", 108, Look.INK, 2)
	box.add_child(t)
	_para("The Sovereign Hotel, on the island's east coast. A pub on the ground floor, rooms upstairs, a gravel lot and the strait beyond it. It's raining, and you're on the door.", 23)
	_gap(24)
	var last: int = main.store.latest()
	var cur: int = main.slot
	var save = main.store.load_slot(cur)
	if save == null and last > 0:
		cur = last
		save = main.store.load_slot(cur)
	if save != null:
		var ended: bool = save.get("ended", false)
		_button("See how it ended" if ended else "Continue the shift", true, func(): main.resume(cur), 30)
		box.add_child(UiBits.label(("NIGHT %d   " % cur) + Store.meta(save).to_upper(), "ui_b", 15, Look.MUTED, 2))
		_gap(6)
		_button("Start Wednesday over", false, func():
			confirm("Start Wednesday over?", "Night %d, as it stands, goes. A new one starts in its place. (Your other nights are kept.)" % cur, "Start over", func():
				main.store.clear(cur)
				main.start_new(cur)))
	else:
		_button("Start the shift", true, func(): main.start_new(cur), 30)
	_button("Nights", false, func(): nights("title"))
	_button("How it plays", false, func(): help("title"))
	_button("Settings", false, func(): settings("title"))
	_button("Quit", false, func(): main._notification(NOTIFICATION_WM_CLOSE_REQUEST))
	_gap(30)
	box.add_child(UiBits.label("PLACEHOLDER SOUND.   DRAFT WRITING IS MARKED FOR HUTCH.", "ui_b", 13, Look.FAINT, 2))
	_focus_first()


# ---------------------------------------------------------------- the pause

func pause() -> void:
	_open("pause")
	_gap(40)
	_head("The shift", "Paused")
	var st: Dictionary = main.game.status()
	_para(str(st.clockText) + ", " + str(Look.PLACE.get(str(st.here), "")).to_lower() + ". The night is saved as it stands after every choice.", 21, Look.MUTED)
	_gap(10)
	_button("Back to the shift", true, func(): hide_all(), 30)
	_button("Settings", false, func(): settings("pause"))
	_button("How it plays", false, func(): help("pause"))
	_button("Back to the title", false, func(): main.back_to_title())
	_button("Quit", false, func(): main._notification(NOTIFICATION_WM_CLOSE_REQUEST))
	_focus_first()


func back() -> void:
	match screen:
		"pause":
			hide_all()
		"settings", "help", "nights":
			if came_from == "pause":
				pause()
			else:
				title()
		"confirm":
			if came_from == "pause":
				pause()
			elif main.in_game:
				hide_all()
			else:
				title()


# ---------------------------------------------------------------- the nights

func nights(from: String) -> void:
	came_from = from
	_open("nights")
	_gap(40)
	_head("Nights", "Three of them")
	_para("Each night is its own Wednesday, saved as it goes. There's no going back inside a night: to try it another way, play another.", 21, Look.MUTED)
	_gap(10)
	for s in range(1, Store.SLOTS + 1):
		var save = main.store.load_slot(s)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.add_child(UiBits.label("NIGHT %d" % s + ("   (LAST PLAYED)" if s == main.slot and save != null else ""), "ui_b", 17, Look.MUTED, 3))
		row.add_child(UiBits.label(Store.meta(save) if save != null else "Not started.", "read", 22, Look.INK_2))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 22)
		var slot_n := s
		if save != null:
			var b1 := UiBits.button("Continue" if not save.get("ended", false) else "See how it ended", true, 21)
			b1.pressed.connect(func(): main.resume(slot_n))
			h.add_child(b1)
			var b2 := UiBits.button("Start over", false, 21)
			b2.pressed.connect(func():
				confirm("Start night %d over?" % slot_n, "That night, as it stands, goes.", "Start over", func():
					main.store.clear(slot_n)
					main.start_new(slot_n)))
			h.add_child(b2)
		else:
			var b3 := UiBits.button("Start it", true, 21)
			b3.pressed.connect(func(): main.start_new(slot_n))
			h.add_child(b3)
		row.add_child(h)
		box.add_child(row)
		_gap(8)
	_button("Back", false, func(): back())
	_focus_first()


# ---------------------------------------------------------------- how it plays

const HELP := [
	["Reading", "The night comes down the column on the right, a paragraph at a time. The voices in his head speak in their own type and colour. Scroll back up whenever you like: the whole night stays on the page."],
	["Choosing", "Click a choice, or press its number. The ways out of a place sit in a row under the rest. Where the Ink stops to let a moment land, Go on (or Space) carries on."],
	["Looking", "Drag across the room to turn his head, or use the arrow keys. The wheel narrows his eyes on something far off. Rest the pointer on someone or something a choice is about and that choice lights up; a voice may lean in on it. Click it to do it."],
	["Checks", "Some choices have a voice's dice behind them: its name, how hard it is, and the odds. Hover the tag to see what's for and against it tonight. When the dice come, hold Space or the mouse button to shake them and let go to throw. The first die down tells you what the second one needs."],
	["Things in his hands", "When he's handed something, it comes up into his hand. Drag to turn it, E to look closer, Q to turn it over, Esc to put it down. Some things can only be done with the hands: hold a licence up by the face of whoever gave it to you."],
	["The clicker", "Once the bartender has handed it over, C clicks it and Z turns the knob back to nothing. It's the room's count, as far as he knows it."],
	["His notes and the sketch", "Tab opens his notes: what he's been asked to do, who has a seat in his head and how they're getting on, and the night so far. M opens the floor sketch from his pocket; a lit place is somewhere he can go now."],
	["His body", "Drink, nerves and hurt show in the print, not on a meter. The Settings can turn the sway off, or all of it."],
	["Saving", "Every choice is saved as it's made. There are three nights; each plays through once."],
	["On a pad", "Either stick looks round. Up and down on the d-pad go through the choices and A makes the lit one; with none lit, A goes on, and holding it shakes the dice. B pauses or puts things down, Y is E, X clicks the clicker, Back opens his notes and the left shoulder the sketch."],
]


func help(from: String) -> void:
	came_from = from
	_open("help")
	_gap(40)
	_head("How it plays")
	_gap(4)
	for h in HELP:
		box.add_child(UiBits.label(h[0].to_upper(), "ui_b", 17, Look.RED, 3))
		_para(h[1], 21)
		_gap(2)
	_gap(6)
	_button("Back", true, func(): back())
	_focus_first()


# ---------------------------------------------------------------- settings

func settings(from: String) -> void:
	came_from = from
	_open("settings")
	var s: Dictionary = main.settings
	_gap(40)
	_head("Settings")
	_section("The page")
	_seg("Type size", [["s", "Small"], ["m", "Medium"], ["l", "Large"]], "text")
	_seg("New lines", [["lines", "One after another"], ["all", "All at once"]], "reveal")
	_seg("Odds", [["words", "In words"], ["numbers", "In numbers"]], "odds")
	_seg("Dice", [["full", "By hand"], ["auto", "Thrown for you"], ["quick", "Quick"], ["still", "At once"]], "dice")
	_toggle("The voices notice you", "notice", "A voice may lean in on what your hand or eyes are on.")
	_toggle("Writing prompts", "prompts", "Show where the draft is waiting on Hutch's own material.")
	_section("His body")
	_toggle("Drink, nerves and hurt in the print", "skin", "")
	_toggle("Sway when he's drunk", "sway", "Off for anyone the movement makes queasy.")
	_slider("Grain", "grain", 0.6, 1.6, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_section("Looking")
	_slider("Look speed", "look_speed", 0.4, 2.0, 0.05, func(v): return "%.2f" % v)
	_toggle("Invert up and down", "invert", "")
	_slider("Field of view", "fov", 45.0, 75.0, 1.0, func(v): return "%d°" % roundi(v))
	_section("The screen")
	_toggle("Fullscreen", "fullscreen", "")
	_slider("Detail", "render", 0.5, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_section("Sound")
	_toggle("Sound", "sound", "Placeholder sound, until Hutch's own.")
	_slider("Everything", "master", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_slider("The room and the weather", "amb", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_slider("Things", "sfx", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_gap(16)
	_button("Back", true, func(): back())
	_focus_first()


func _section(t: String) -> void:
	_gap(10)
	box.add_child(UiBits.label(t.to_upper(), "ui_b", 16, Look.RED, 3))


func _row(label: String, hint: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(UiBits.label(label, "ui_b", 21, Look.INK, 1))
	if hint != "":
		var h := UiBits.label(hint, "ui", 17, Look.MUTED)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(h)
	box.add_child(v)
	return v


func _seg(label: String, options: Array, key: String) -> void:
	var v := _row(label, "")
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 18)
	v.add_child(h)
	var buttons: Array = []
	for o in options:
		var b := UiBits.button(o[1], main.settings.get(key) == o[0], 19)
		var val = o[0]
		b.pressed.connect(func():
			main.settings[key] = val
			main.apply_settings()
			settings(came_from))
		h.add_child(b)
		buttons.append(b)


func _toggle(label: String, key: String, hint: String) -> void:
	var v := _row(label, hint)
	var on: bool = main.settings.get(key, false)
	var b := UiBits.button("On" if on else "Off", on, 19)
	b.pressed.connect(func():
		main.settings[key] = not main.settings.get(key, false)
		main.apply_settings()
		settings(came_from))
	v.add_child(b)


func _slider(label: String, key: String, lo: float, hi: float, step: float, fmt: Callable) -> void:
	var v := _row(label, "")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = float(main.settings.get(key, lo))
	sl.custom_minimum_size = Vector2(320, 28)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grab := StyleBoxFlat.new()
	grab.bg_color = Look.RULE
	grab.content_margin_top = 3
	grab.content_margin_bottom = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = Look.RED
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	sl.add_theme_stylebox_override("slider", grab)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	h.add_child(sl)
	var val := UiBits.label(fmt.call(sl.value), "ui_b", 19, Look.INK_2, 1)
	val.custom_minimum_size = Vector2(70, 0)
	h.add_child(val)
	sl.value_changed.connect(func(x):
		main.settings[key] = x
		val.text = fmt.call(x)
		main.apply_settings())
	v.add_child(h)


# ---------------------------------------------------------------- a question

func confirm(q: String, text: String, yes: String, fn: Callable) -> void:
	var from := screen
	if from == "":
		from = "pause" if main.in_game else "title"
	came_from = from if from in ["pause", "title"] else came_from
	_open("confirm")
	_gap(60)
	_head(q)
	_para(text, 22)
	_gap(10)
	_button(yes, true, fn, 28)
	_button("Keep it", false, func(): back())
	_focus_first()


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tw != null and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast.modulate.a = 1.0
	_toast_tw = create_tween()
	_toast_tw.tween_interval(3.2)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.6)
