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
var _bg: ColorRect
var _fade: TextureRect         # the title over the whole picture: the night ink fading off to the right


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
	_bg = bg
	_fade = TextureRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(Color("07080b"), 0.94))
	gr.set_color(1, Color(Color("07080b"), 0.0))
	gr.add_point(0.55, Color(Color("07080b"), 0.78))
	gt.gradient = gr
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 256
	gt.height = 4
	_fade.texture = gt
	_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fade.stretch_mode = TextureRect.STRETCH_SCALE
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.visible = false
	sheet.add_child(_fade)
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
	# the title over the whole picture (game/intro.gd): the menu on the left on the night's ink,
	# fading off into the print; everything else where the column is
	var over: bool = name == "title" and main.full_frame
	sheet.anchor_left = 0.0 if over else View.WORLD_W
	sheet.anchor_right = 0.42 if over else 1.0
	_bg.visible = not over
	_fade.visible = over
	scroll.offset_left = 84 if over else 58
	scroll.offset_right = -120 if over else -46
	scroll.offset_top = 96 if over else 70


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

func title(stamp := false) -> void:
	# back from somewhere that had the picture and the page (a game of darts from the Games): the
	# title's own shot again, printed in
	if not main.full_frame and not main.in_game and main.intro != null:
		main.intro.title_only()
		return
	_open("title")
	if not main.full_frame:
		main.view.jump_to("door")
		main.view.look_at_point(Vector3(3.45, 1.35, 10.1))
	_gap(40)
	box.add_child(UiBits.label("WEDNESDAY, THE TEST SHIFT", "ui_b", 18, Look.MUTED, 4))
	var t := UiBits.label("LAST CALL", "display", 132 if main.full_frame else 108, Look.INK, 2)
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
		if main.older_story(save):
			box.add_child(UiBits.label("SAVED UNDER AN OLDER VERSION OF THE STORY", "ui_b", 13, Look.FAINT, 2))
		_gap(6)
		_button("Start Wednesday over", false, func():
			confirm("Start Wednesday over?", "Night %d, as it stands, goes. A new one starts in its place. (Your other nights are kept.)" % cur, "Start over", func():
				main.store.clear(cur)
				main.start_new(cur)))
	else:
		_button("Start Wednesday", true, func(): main.start_new(cur), 30)
	_button("Nights: Wednesday, Thursday, Friday", false, func(): nights("title"))
	_button("The cold open", false, func(): hide_all(); main.intro.play())
	_button("Games", false, func(): games("title"))
	_button("Rehearse", false, func(): rehearse("title"))
	_button("How it plays", false, func(): help("title"))
	_button("Settings", false, func(): settings("title"))
	_button("Quit", false, func(): main._notification(NOTIFICATION_WM_CLOSE_REQUEST))
	_gap(30)
	box.add_child(UiBits.label("PLACEHOLDER SOUND.   DRAFT WRITING IS MARKED FOR HUTCH.", "ui_b", 13, Look.FAINT, 2))
	_focus_first()
	if stamp:
		_stamp(t)


# The title comes down on the paper like a block on a press: LAST CALL first, hard, with the thump
# of it; the picture jolts; then the rest of the menu, one line after another.
func _stamp(t: Label) -> void:
	var rest: Array = []
	for c in box.get_children():
		if c != t:
			rest.append(c)
			c.modulate.a = 0.0
	t.modulate.a = 0.0
	await get_tree().process_frame
	# the title can be gone by now (a night started, or resumed, the frame it came up): its labels
	# are freed, and a tween on a freed label crashes the engine. Every tween here is the node's own,
	# so it dies with it.
	if not is_instance_valid(t) or not t.is_inside_tree():
		return
	t.pivot_offset = Vector2(t.size.x * 0.3, t.size.y * 0.6)
	t.scale = Vector2(1.18, 1.18)
	var tw := t.create_tween()
	tw.tween_interval(0.25)
	tw.tween_callback(func():
		main.audio.sfx("stamp", 1.0, 0.62)
		main.audio.sfx("thump", 0.7, 0.5))
	tw.set_parallel()
	tw.tween_property(t, "modulate:a", 1.0, 0.06).set_delay(0.25)
	tw.tween_property(t, "scale", Vector2.ONE, 0.09).set_delay(0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# the jolt: the paper takes the block
	var jolt := sheet.create_tween()
	jolt.tween_interval(0.34)
	jolt.tween_property(sheet, "position:y", 5.0, 0.04)
	jolt.tween_property(sheet, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var i := 0
	for c in rest:
		if not is_instance_valid(c):
			continue
		var ct: Tween = (c as Node).create_tween()
		ct.tween_interval(0.75 + 0.07 * i)
		ct.tween_property(c, "modulate:a", 1.0, 0.45)
		i += 1


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
	_button("The look", false, func(): look_menu("pause"))
	_button("How it plays", false, func(): help("pause"))
	_button("Back to the title", false, func(): main.back_to_title())
	_button("Quit", false, func(): main._notification(NOTIFICATION_WM_CLOSE_REQUEST))
	_focus_first()


func back() -> void:
	match screen:
		"pause":
			hide_all()
		"look":
			if _look_from == "settings":
				settings(came_from)
			else:
				pause()
		"settings", "help", "nights", "games", "rehearse":
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


# ---------------------------------------------------------------- the games and the rehearsal

# The games he's met, to play again from here: each one opens once the night's put it in front of
# him (Store.met). Each comes up as it is in the Sov, at the board or the table.
const GAMES := [
	["darts", "Darts", "The board on the east wall, the house darts, the chalk.", [["practice", "Throw a few"], ["clock", "Round the clock"], ["501", "Five-oh-one"]]],
	["cigs", "The cigarette machine", "On the east wall under the news, unplugged, and it plays.", [["play", "Stand at it"]]],
	["mats", "Beer mats", "Off the edge of the bar, flipped and caught, one more each time.", [["play", "Flip a few"]]],
	["pool", "Pool", "The coin-op by the back wall: the regulars on the chalk ladder, money on the rail, the Sunday draw, the trick shots table 28 bets on.", [["table", "To the table"]]],
	["fights", "Fights", "The fish plant on a Sunday, and the man on the deck.", [["fight:ox", "Sunday: Ox Pettigrew"], ["fight:ogre", "The man on the deck"], ["fight:spar", "Move around with Dale"]]],
	["glasses", "The wine glasses", "Eight on a bar towel in the gap, a jug of water, a wet finger.", [["play", "Play them"]]],
]


func games(from: String) -> void:
	came_from = from
	_open("games")
	_gap(40)
	_head("Games", "What he's played")
	var met: Array = main.settings.get("met", [])
	var any := false
	for g in GAMES:
		if not (g[0] in met):
			continue
		any = true
		_section(g[1])
		_para(g[2], 20, Look.MUTED)
		for m in g[3]:
			var mode: String = m[0]
			if mode.begins_with("fight:"):
				_button(m[1], false, func(): main.start_fight(mode.substr(6), "games", _rh.duplicate()))
			elif g[0] == "cigs":
				_button(m[1], false, func(): main.start_cig("games"))
			elif g[0] == "mats":
				_button(m[1], false, func(): main.start_mats("games"))
			elif g[0] == "pool":
				_button(m[1], false, func(): pool_menu("games"))
			elif g[0] == "glasses":
				_button(m[1], false, func(): main.start_glasses("games"))
			else:
				_button(m[1], false, func(): main.start_darts(mode, "games"))
	if not any:
		_para("Nothing yet. The games open here once he's come across them on a shift.", 21, Look.MUTED)
	_gap(14)
	_button("Back", true, func(): back())
	_focus_first()


# Pool for money (game/pool_career.gd): his purse, the ladder chalked by the table, Good Shoes, the
# Sunday draw, the trick shots, and the pawn window.
func pool_menu(from: String) -> void:
	if from != "pool":
		came_from = from
	_open("pool")
	_gap(40)
	var d := PoolCareer.data(main.settings)
	_head("The table", "Pool for money")
	_para("$%d in his pocket.%s" % [int(d.purse), ("  The trophy on the shelf: " + ", ".join(d.trophies)) if not (d.trophies as Array).is_empty() else ""], 22, Look.INK)
	_button("Knock them around on his own", false, func(): main.start_pool("practice", "", "games", {}))
	_section("The ladder")
	_para("Chalked on the board by the table. Beat one and the next will play you.", 19, Look.MUTED)
	for i in PoolCareer.LADDER.size():
		var r: Dictionary = PoolCareer.LADDER[i]
		var beaten: bool = r.id in d.beaten
		if not PoolCareer.unlocked(main.settings, i):
			_para("— " + ("?" if i > 0 else ""), 19, Look.FAINT)
			break
		var label := "%s, $%d, %s%s" % [str(PoolAI.PEOPLE[r.who].name), int(r.stakes), PoolRules.new().describe(r.game).to_lower(), "  (beaten)" if beaten else ""]
		var idx := i
		var bt := _button(label, false, func(): _pool_match(idx), 22)
		bt.tooltip_text = str(r.line)
		_para(str(r.line), 17, Look.MUTED)
		if int(d.purse) < int(r.stakes):
			bt.disabled = true
	_section("Good Shoes")
	var shoes_st := int(d.get("shoes_stakes", 50))
	_para("He's at the bar with a soda water and a fifty folded long-ways. He'll play anybody for anything, and he's bad. Win by too much and he remembers somewhere else to be.", 18, Look.MUTED)
	var sb := _button("Play him for $%d" % shoes_st, false, func(): _pool_shoes(), 22)
	sb.disabled = int(d.purse) < shoes_st or int(d.get("shoes_week", 0)) > 0
	if int(d.get("shoes_week", 0)) > 0:
		_para("He's not in. Somebody said he'd gone to the casino in Nanaimo.", 17, Look.FAINT)
	_section("The Sunday draw")
	_para("Ten dollars in, eight names out of a pint glass, league rules, one rack a round. Fifty to the winner, twenty to the other one in the final.", 18, Look.MUTED)
	var tb := _button("Put ten in the glass", false, func(): _pool_sunday(), 22)
	tb.disabled = int(d.purse) < 10
	_section("Trick shots")
	_para("Table 28 puts money on whether he can. Three tries a time.", 18, Look.MUTED)
	for tr in PoolCareer.TRICKS:
		var tid: String = tr.id
		var done: bool = tid in d.tricks
		_button("%s, $%d%s" % [tr.name, int(tr.pays), "  (made)" if done else ""], false, func(): _pool_trick(tid), 21)
	_section("The pawn window")
	for it in PoolCareer.SHOP:
		var iid: String = it.id
		var own: bool = iid in d.owned
		var lb := "%s, $%d%s" % [it.name, int(it.price), "  (his)" if own else ""]
		var b := _button(lb, false, func(): _pool_buy(iid), 21)
		b.disabled = own or int(d.purse) < int(it.price)
		_para(str(it.note), 17, Look.MUTED)
	_gap(14)
	_button("Back", true, func(): back())
	_focus_first()


func _pool_pay(amount: int) -> void:
	var d := PoolCareer.data(main.settings)
	d.purse = maxi(0, int(d.purse) + amount)
	main.store.save_settings()


func _pool_match(i: int) -> void:
	var r: Dictionary = PoolCareer.LADDER[i]
	var d := PoolCareer.data(main.settings)
	var who: String = r.who
	var stakes := int(r.stakes)
	# the man from Nanaimo: once he's lost the first one, it's a hundred, and he plays
	if r.id == "nanaimo" and bool(d.get("nanaimo_hustled", false)):
		who = "nanaimo"
		stakes = 100
		if int(d.purse) < 100:
			toast("He wants a hundred on it now. You haven't got a hundred.")
			return
	main.start_pool(r.game, who, "games", {"stakes": stakes, "they_break": randf() < 0.5}, func(res):
		if res.get("left", false) and not res.has("why"):
			return
		var dd := PoolCareer.data(main.settings)
		_pool_pay(stakes if res.won else -stakes)
		if res.won and r.id == "nanaimo" and who == "nanaimo_dumb":
			dd.nanaimo_hustled = true
		elif res.won and not (r.id in dd.beaten) and not (r.id == "nanaimo" and who == "nanaimo_dumb"):
			dd.beaten.append(r.id)
		main.store.save_settings())


func _pool_shoes() -> void:
	var d := PoolCareer.data(main.settings)
	var stakes := int(d.get("shoes_stakes", 50))
	main.start_pool("8bar", "goodshoes", "games", {"stakes": stakes}, func(res):
		if res.get("left", false) and not res.has("why"):
			return
		var dd := PoolCareer.data(main.settings)
		_pool_pay(stakes if res.won else -stakes)
		# keep it close and he doubles; run away with it and he's gone for the week
		if res.won and int(res.get("margin", 0)) >= 5:
			dd.shoes_week = 1
			dd.shoes_stakes = 50
		elif res.won:
			dd.shoes_stakes = mini(stakes * 2, 400)
		main.store.save_settings())


func _pool_trick(id: String) -> void:
	var tr: Dictionary = {}
	for x in PoolCareer.TRICKS:
		if x.id == id:
			tr = x
	main.start_pool("trick", "", "games", {"trick": id}, func(res):
		if res.get("made", false) or res.get("won", false):
			var dd := PoolCareer.data(main.settings)
			_pool_pay(int(tr.pays))
			if not (id in dd.tricks):
				dd.tricks.append(id)
			main.store.save_settings())


func _pool_buy(id: String) -> void:
	var d := PoolCareer.data(main.settings)
	for it in PoolCareer.SHOP:
		if it.id == id and int(d.purse) >= int(it.price) and not (id in d.owned):
			d.purse = int(d.purse) - int(it.price)
			d.owned.append(id)
			main.store.save_settings()
			toast("His now: " + str(it.name).to_lower() + ".")
	pool_menu("pool")


# The Sunday draw: three rounds, one rack each, the other games played out by how good they are.
var _sunday_round := 0
var _sunday_field: Array = []

func _pool_sunday() -> void:
	_pool_pay(-10)
	_sunday_round = 0
	var field := ["scratch", "hivis", "buddy", "cook", "jim", "bigman_straight", "nanaimo"]
	field.shuffle()
	_sunday_field = field
	_sunday_next()


func _sunday_next() -> void:
	var who: String = _sunday_field[_sunday_round]
	var round_name: String = ["The first round", "The semi-final", "The final"][_sunday_round]
	toast("%s: %s." % [round_name, str(PoolAI.PEOPLE[who].name).to_lower()])
	main.start_pool("8league", who, "games", {"stakes": 0, "sunday": round_name}, func(res):
		if not res.get("won", false):
			if _sunday_round == 2:
				_pool_pay(20)
				toast("Out in the final. Twenty dollars for the other one in it.")
			else:
				toast("Out in %s." % round_name.to_lower())
			return
		_sunday_round += 1
		if _sunday_round >= 3:
			var dd := PoolCareer.data(main.settings)
			_pool_pay(50)
			dd.sundays = int(dd.get("sundays", 0)) + 1
			if not ("the Sunday draw" in dd.trophies):
				dd.trophies.append("the Sunday draw")
			main.store.save_settings()
			toast("He won the Sunday draw. Fifty dollars, and his name in chalk on the board till next week.")
			return
		_sunday_next.call_deferred())


# Rehearse: any interaction on its own, without the night, with his body set by hand. For trying
# things out while they're being made.
var _rh := {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0}

func rehearse(from: String) -> void:
	came_from = from
	_open("rehearse")
	_gap(40)
	_head("Rehearse", "Without the night")
	_para("Any of the hands-on parts on its own, for trying out. Set how he is first.", 21, Look.MUTED)
	_rh_slider("Drinks in him", "drinks", 0, 12, 1, func(v): return "%d" % v)
	_rh_slider("Hurt", "hurt", 0, 3, 1, func(v): return ["none", "a bit", "hurt", "badly"][int(v)])
	_rh_slider("Nerves", "tension", 0, 4, 1, func(v): return ["calm", "edgy", "keyed up", "shaking", "after a fight"][int(v)])
	_rh_slider("The hour", "clock", 1200, 1560, 15, func(v): return Look.clock_text(int(v) % 1440))
	_rh_slider("Cold hands", "cold", 0.0, 1.0, 0.25, func(v): return "no" if v == 0 else ("in from the door" if v >= 1.0 else "a little"))
	_section("Darts")
	_button("Throw a few", true, func(): main.start_darts("practice", "rehearse", _rh.duplicate()))
	_button("Round the clock", false, func(): main.start_darts("clock", "rehearse", _rh.duplicate()))
	_button("Five-oh-one", false, func(): main.start_darts("501", "rehearse", _rh.duplicate()))
	_section("The cigarette machine")
	_button("Stand at it", false, func(): main.start_cig("rehearse", _rh.duplicate()))
	_section("Beer mats")
	_button("Flip a few", false, func(): main.start_mats("rehearse", _rh.duplicate()))
	_section("Pool")
	_button("The table to himself", false, func(): main.start_pool("practice", "", "rehearse", {"body": _rh.duplicate()}))
	_button("Eight-ball against the buddy", false, func(): main.start_pool("8bar", "buddy", "rehearse", {"body": _rh.duplicate()}))
	_button("Nine-ball against the cook", false, func(): main.start_pool("9ball", "cook", "rehearse", {"body": _rh.duplicate()}))
	_button("The big man, the way he plays tonight", false, func(): main.start_pool("8bar", "bigman", "rehearse", {"body": _rh.duplicate(), "stakes": 20, "they_break": true}))
	for tr in PoolCareer.TRICKS:
		var tid: String = tr.id
		_button("Trick shot: " + str(tr.name).to_lower(), false, func(): main.start_pool("trick", "", "rehearse", {"body": _rh.duplicate(), "trick": tid}))
	_section("The truck")
	_para("The jade green '78 in the lot at night, in the rain. The highway north to the mill road and south to the ferry sign.", 19, Look.MUTED)
	_button("Drive it", false, func(): main.start_truck("rehearse", _rh.duplicate()))
	_section("Fights")
	_button("The man on the deck", false, func(): main.start_fight("ogre", "rehearse", _rh.duplicate()))
	_button("Sunday at the fish plant: Ox Pettigrew", false, func(): main.start_fight("ox", "rehearse", _rh.duplicate()))
	_button("Move around with Dale", false, func(): main.start_fight("spar", "rehearse", _rh.duplicate()))
	_section("The wine glasses")
	_button("Play them", false, func(): main.start_glasses("rehearse", _rh.duplicate()))
	_section("Still to come here")
	_para("The door by hand, the dice, the licence in his hands: each gets a way in here as it's worked on.", 19, Look.FAINT)
	_gap(14)
	_button("Back", true, func(): back())
	_focus_first()


func _rh_slider(label: String, key: String, lo: float, hi: float, step: float, fmt: Callable) -> void:
	var row := _row(label, "")
	var h := HBoxContainer.new()
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = _rh.get(key, lo)
	sl.custom_minimum_size = Vector2(320, 24)
	var val := UiBits.label(str(fmt.call(sl.value)), "ui_b", 18, Look.INK_2, 1)
	sl.value_changed.connect(func(v):
		_rh[key] = v
		val.text = str(fmt.call(v)))
	h.add_child(sl)
	h.add_child(val)
	row.add_child(h)


# ---------------------------------------------------------------- the nights

func nights(from: String) -> void:
	came_from = from
	_open("nights")
	_gap(40)
	_head("Nights", "Three of them")
	_para("Three saves, each its own run, saved as it goes. A new one can start on Wednesday, the test shift, or skip ahead to Thursday or Friday as if Wednesday went by quietly. There's no going back inside a night: to try it another way, play another.", 21, Look.MUTED)
	_gap(10)
	for s in range(1, Store.SLOTS + 1):
		var save = main.store.load_slot(s)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.add_child(UiBits.label("NIGHT %d" % s + ("   (LAST PLAYED)" if s == main.slot and save != null else ""), "ui_b", 17, Look.MUTED, 3))
		row.add_child(UiBits.label(Store.meta(save) if save != null else "Not started.", "read", 22, Look.INK_2))
		if main.older_story(save):
			row.add_child(UiBits.para([["read", 18, Look.MUTED, "Saved under an older version of the story, so some of it may not line up."]]))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 22)
		var slot_n := s
		if save != null:
			var b1 := UiBits.button("Continue" if not save.get("ended", false) else "See how it ended", true, 21)
			b1.pressed.connect(func(): main.resume(slot_n))
			h.add_child(b1)
			h.add_child(UiBits.label("START OVER ON", "ui_b", 14, Look.FAINT, 2))
			for d in main.DAYS:
				var knot: String = d[0]
				var day_name: String = d[1]
				var b2 := UiBits.button(day_name, false, 19)
				b2.tooltip_text = d[2]
				b2.pressed.connect(func():
					confirm("Start night %d over, on %s?" % [slot_n, day_name], "That night, as it stands, goes.", "Start over", func():
						main.store.clear(slot_n)
						main.start_day(slot_n, knot)))
				h.add_child(b2)
		else:
			h.add_child(UiBits.label("START ON", "ui_b", 14, Look.FAINT, 2))
			for d in main.DAYS:
				var knot: String = d[0]
				var b3 := UiBits.button(d[1], d[0] == "wednesday", 21)
				b3.tooltip_text = d[2]
				b3.pressed.connect(func(): main.start_day(slot_n, knot))
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
	["Where he is", "He can only do what he's there for. While he's on his way somewhere, the choices wait, faint, till he gets there. A choice about someone across the room is faint too: pick it and he walks over first, then does it. Out round the back of the lot, the bar's choices wait for him to come back out front. The Settings can let you choose ahead."],
	["Checks", "Some choices have a voice's dice behind them: its name, how hard it is, and the odds. Hover the tag to see what's for and against it tonight. When the dice come, hold Space or the mouse button to shake them and let go to throw. The first die down tells you what the second one needs."],
	["Things in his hands", "When he's handed something, it comes up into his hand. Drag to turn it, E to look closer, Q to turn it over, Esc to put it down. Some things can only be done with the hands: hold a licence up by the face of whoever gave it to you."],
	["His notes and the sketch", "Tab opens his notes: what he's been asked to do, who has a seat in his head and how they're getting on, and the night so far. M opens the floor sketch from his pocket; a lit place is somewhere he can go now."],
	["Darts", "Look at the dartboard twice and he goes over and takes the darts out of the board. Aim with your eyes; hold the button and pull back to draw, and let go: halfway back is his usual throw, which lands where he's looking. The wheel lifts his elbow for a flatter throw or a lob, Q and E move his grip on the barrel, A and D move him along the line, Shift narrows his eyes and the right button holds his breath. The three house darts each fly their own way. Esc puts them down. Once he's played, darts are in Games on the title; Rehearse plays them with no night at all."],
	["The cigarette machine", "On the east wall under the news, on the way to the deck. Look at it twice and he goes and stands at it. Pull a knob out with the mouse, down the screen being out toward him, or play the row with A W S E D F T G Y H U J (Shift pulls one all the way); Z and X move it an octave. A quarter in the slot (C) holds what's pulled; the coin return lever bends the note, and all the way down gives the quarters back (R); click the cup to take them. Knock on it with either button (Space), twice to set its speed. The wheel rocks it. K O L P ; go on up past the knobs, and a MIDI keyboard plugged in plays it too, with velocity, the sustain pedal, the mod wheel and pitch bend. The two lamps over the slot are a tape: Enter (or click MAKE ANOTHER SELECTION) records, then closes the loop and plays it round, then lays more over it; Backspace (or USE CORRECT CHANGE) wipes it; Q pulls what's played onto the sixteenths. Knock twice to set the speed before recording; knocks and the tray flap record as a drum part. The lock opens the front (I): what's on the board inside changes the sound; I, Esc or a click off the board shuts it. Esc steps back. What a quarter's holding keeps playing while he's gone."],
	["The wine glasses", "At the bar, look at the wine glasses twice. The mouse (or the arrow keys) moves his hand from glass to glass. Hold the button to put his fingertip on the rim and keep the mouse moving, any way you like: that takes it round, and the glass sings; faster is louder, too fast and the finger skates, too slow and it barely speaks. Shift leans on it. W wets the fingertip; a dry finger squeaks. Hold the other button over a glass to pour from the jug, and the wheel adds a splash or tips a little out: more water, lower note. A S D F G H J K tap them with a stir stick, Shift harder. Jim's tuner reads the glass under his hand. Esc leaves them."],
	["Beer mats", "At the bar, look at the pile of beer mats twice. The mouse moves his hand. Hold the button to curl his fingers and bring them up fast under the part hanging over the edge: it hinges off the bar and turns over in the air. Click again while it's up to snatch it. It has to have turned over and be lying near flat. Each one caught, he puts another on the stack. The wheel slides it out over the edge or back; Q and E take one off or put one on. Esc puts them down."],
	["Pool", "Put twenty on the big man's next game and you play the rack on the table. The mouse turns the cue round the cue ball (Shift for fine work); up and down moves his head, low on the line or stood up. Hold the right button and move the mouse to put the tip on the ball: high follows, low draws, the sides spin it, and past the ring on the little ball it slips off. The wheel lifts the butt: over a ball, a curve, a jump. Hold the left button and pull back to draw the cue, and let go: how far back is how hard. C chalks, Q and E change cues, Tab stands him up over the table, F calls the pocket on the eight. In hand, the mouse puts the cue ball down. Once he's played, Games on the title has the table: the regulars for money, Good Shoes, the Sunday draw, the trick shots and the pawn window."],
	["The keys card", "Whatever he steps up to (the darts, the table, the cigarette machine, the beer mats) puts its keys on a card at the foot of the picture. It folds down to one line once you've got the hang of it; F1 brings it back up."],
	["His body", "Drink, nerves and hurt show in the print, not on a meter. The Settings can turn the sway off, or all of it."],
	["Saving", "Every choice is saved as it's made. There are three saves, one to a page under Nights; each can start on Wednesday, Thursday or Friday, and starting over wipes only that page."],
	["On a pad", "Either stick looks round. Up and down on the d-pad go through the choices and A makes the lit one; with none lit, A goes on, and holding it shakes the dice. B pauses or puts things down, Y is E, Back opens his notes and the left shoulder the sketch."],
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
	# a toggle redraws the page: keep it where it was scrolled to, not back at the top
	var keep: int = scroll.scroll_vertical if screen == "settings" else 0
	came_from = from
	_open("settings")
	if keep > 0:
		_rescroll.call_deferred(keep)
	var s: Dictionary = main.settings
	_gap(40)
	_head("Settings")
	_section("The page")
	_seg("Type size", [["s", "Small"], ["m", "Medium"], ["l", "Large"]], "text")
	_seg("New lines", [["lines", "One after another"], ["all", "All at once"]], "reveal")
	_seg("Odds", [["words", "In words"], ["numbers", "In numbers"]], "odds")
	_seg("Dice", [["full", "By hand"], ["auto", "Thrown for you"], ["quick", "Quick"], ["still", "At once"]], "dice")
	_toggle("Choose ahead while he walks", "click_ahead", "Off: while he's on his way somewhere, the next choices wait till he gets there. On: pick ahead while he walks.")
	_toggle("The voices notice you", "notice", "A voice may lean in on what your hand or eyes are on.")
	_toggle("Writing prompts", "prompts", "Show where the draft is waiting on Hutch's own material.")
	_section("His body")
	_toggle("Drink, nerves and hurt in the print", "skin", "")
	_toggle("Sway when he's drunk", "sway", "Off for anyone the movement makes queasy.")
	_section("Looking")
	_slider("Look speed", "look_speed", 0.4, 2.0, 0.05, func(v): return "%.2f" % v)
	_toggle("Invert up and down", "invert", "")
	_toggle("The keys walk him", "keys_walk", "W A S D walk him, Shift hurries, Alt with A or D leans. Off: a click on the floor walks him. Looking is the mouse or the arrow keys either way.")
	_toggle("Fold the page when he walks", "wide_walk", "Setting off on his feet folds the page to its spine. It only opens again when you open it: C, or a click on the spine.")
	_slider("Field of view", "fov", 45.0, 90.0, 1.0, func(v): return "%d°" % roundi(v))
	_section("The screen")
	_toggle("Fullscreen", "fullscreen", "")
	_button("The look", false, func(): look_menu("settings"), 22)
	_slider("Detail", "render", 0.5, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_section("Sound")
	_toggle("Sound", "sound", "Placeholder sound, until Hutch's own.")
	_slider("Everything", "master", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_slider("The room and the weather", "amb", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_slider("Things", "sfx", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_slider("The score", "music", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_slider("Voices", "voice", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_gap(16)
	_button("Back", true, func(): back())
	_focus_first()


# ---------------------------------------------------------------- the look

# Every way the night can be shown (look/press.gdshader's style), in families, each with a line on
# what it is. Night stock is the game's own; the rest are there to play in.
const LOOK_FAMILIES := [
	["Film", [["7", "Night stock"], ["8", "Super 8"], ["11", "Anamorphic"]]],
	["Paint", [["3", "Painted"], ["5", "Oil"], ["6", "Thin paint"], ["12", "Paint on night stock"]]],
	["Print", [["0", "The press"], ["1", "Clean cut"], ["2", "Black plate"], ["4", "Pulp"]]],
	["Cameras", [["9", "Bodycam"], ["10", "The bar's camera"]]],
]
const LOOK_NOTES := {
	"0": "The old woodcut press: five inks on cream stock, strokes cut along the surfaces.",
	"1": "The press with its blacks solid and its colour smoothed.",
	"2": "Black or paper, nothing between but where a form turns. Mignola, Sin City.",
	"3": "The room's own colour, smoothed into paint and pulled toward the press's inks.",
	"4": "Halftone dots, every ink at its own angle, like a cheap four-colour press.",
	"5": "The paint with a bigger brush, a rougher board and more of the inks.",
	"6": "Mostly the render, with only a little paint.",
	"7": "Tungsten film pushed in a dark bar: cool shadows, warm bulbs, red halation, grain in the dye layers.",
	"8": "A home-movie camera at night: soft, warm, brown blacks, the gate's round corners.",
	"9": "A camera on his chest: a fisheye, the colour splitting, the sensor's noise in the dark.",
	"10": "The security camera over the till: grey-green, low, lines.",
	"11": "A widescreen lens: letterboxed, a blue streak through every light, teal and amber.",
	"12": "The paint, with night stock's halation and grain over it.",
}
var _look_from := ""


func look_menu(from: String) -> void:
	if from != "":
		_look_from = from
	var keep: int = scroll.scroll_vertical if screen == "look" else 0
	_open("look")
	if keep > 0:
		_rescroll.call_deferred(keep)
	var cur := str(main.settings.get("look", "7"))
	_gap(40)
	_head("The look", "How the night is shown")
	_para(LOOK_NOTES.get(cur, ""), 21, Look.MUTED)
	_para("F8 goes round them while you play.", 17, Look.MUTED)
	for fam in LOOK_FAMILIES:
		_seg(fam[0], fam[1], "look")
	var n := int(cur)
	if n >= 7 and n <= 12 or n == 5 or n == 6 or n == 3:
		_section("The film")
		_slider("Grain", "film_grain", 0.0, 2.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
		_slider("Halation", "film_halation", 0.0, 2.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
		_slider("Glow round the lights", "film_glow", 0.0, 2.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
		_slider("The lens's corners", "film_vignette", 0.0, 2.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	if n <= 6 or n == 12:
		_section("The print")
		_toggle("The bulbs bloom", "halo", "Old incandescent glass: a warm haze round every lamp. Shift+F8 while you play.")
		_slider("Grain", "grain", 0.6, 1.6, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
		_slider("Strokes", "print", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100.0))
	_gap(16)
	_button("Back", true, func(): back())
	_focus_first()


func _reopen() -> void:
	if screen == "look":
		look_menu("")
	else:
		settings(came_from)


func _rescroll(v: int) -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = v


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
			_reopen())
		h.add_child(b)
		buttons.append(b)


func _toggle(label: String, key: String, hint: String) -> void:
	var v := _row(label, hint)
	var on: bool = main.settings.get(key, false)
	var b := UiBits.button("On" if on else "Off", on, 19)
	b.pressed.connect(func():
		main.settings[key] = not main.settings.get(key, false)
		main.apply_settings()
		_reopen())
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
