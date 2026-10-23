# The Bouncer: Wednesday, the test shift, through his eyes, printed.
#
# The game: boots the night, reads it into the column as it happens, and keeps the room in step
# with it. Everything the night says comes from the engine (engine/game.gd, the browser build's
# engine ported line for line) running the Ink (ink/ink.gd); this file decides only how and when
# it's shown.
#
#   the reader     renders a batch of items into the column. Three things hold the rest of a batch
#                  back: a #pause in the Ink ("Go on"), the dice, and the till tape at close.
#   the room       his eyes (game/view.gd) walk to where he is, the people are staged by the clock
#                  and the story (world/stage.gd), and what's in the room answers to his eyes and
#                  hands (game/hotspots.gd)
#   saves          every choice is saved as it's made, into one of three nights (game/store.gd)
extends Node

const WORLD_W := View.WORLD_W

var store: Store
var settings: Dictionary
var content: Dictionary
var game: Game
var pub: Pub
var stage: Stage
var view: View
var ui: CanvasLayer
var root: Control
var column: Column
var menus: Menus
var notes: Notes
var sketch: Sketch
var hand: Hand
var spots: Hotspots
var dice: Dice
var props: Props
var marks: Marks
var audio: Sound

var in_game := false
var slot := 1
var pending = null             # the rest of a batch, waiting behind a pause, the dice or the tape
var rolling = null             # the dice or the tape while they play
var printing = null            # the tape
var shown_knots := {}
var prompts := {}
var read_chars := 0
var _save_soon := -1.0
var _quit_asked := false


func _ready() -> void:
	randomize()
	get_tree().auto_accept_quit = false
	Look.load_fonts()
	store = Store.new()
	settings = store.settings
	slot = clampi(int(settings.get("slot", 1)), 1, Store.SLOTS)
	_apply_window()
	content = _load_content()
	game = Game.new(content)
	for p in content.get("meta", {}).get("prompts", []):
		if not prompts.has(p.knot):
			prompts[p.knot] = []
		prompts[p.knot].append(p)

	pub = Pub.new()
	add_child(pub)
	pub.build()
	stage = Stage.new()
	add_child(stage)
	stage.setup(pub, content)

	ui = CanvasLayer.new()
	add_child(ui)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.add_child(root)
	view = View.new()
	add_child(view)
	view.setup(pub, settings, root)
	stage.view = view

	audio = Sound.new()
	add_child(audio)
	audio.setup(settings)

	marks = Marks.new()
	marks.set_anchors_preset(Control.PRESET_FULL_RECT)
	marks.anchor_right = WORLD_W
	root.add_child(marks)
	marks.setup(view, stage, pub, content)

	column = Column.new()
	column.anchor_left = WORLD_W
	column.anchor_right = 1.0
	column.anchor_bottom = 1.0
	root.add_child(column)
	column.setup(settings)
	for id in content.voices:
		column.voice_labels[id] = str(content.voices[id].get("label", id.to_upper()))
	column.chose.connect(choose)
	column.hand_on.connect(func(i, on): hand.on_row(i, on))
	column.end_action.connect(_end_action)

	spots = Hotspots.new()
	add_child(spots)
	spots.setup(self)
	hand = Hand.new()
	add_child(hand)
	hand.setup(self)
	dice = Dice.new()
	add_child(dice)
	dice.setup(self)
	props = Props.new()
	add_child(props)
	props.setup(self)

	notes = Notes.new()
	notes.anchor_right = WORLD_W
	notes.anchor_bottom = 1.0
	root.add_child(notes)
	notes.setup(self)
	sketch = Sketch.new()
	sketch.anchor_right = WORLD_W
	sketch.anchor_bottom = 1.0
	root.add_child(sketch)
	sketch.setup(self)

	menus = Menus.new()
	menus.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(menus)
	menus.setup(self)

	view.sheet.gui_input.connect(_on_world_input)
	view.arrived.connect(func(where): stage.arrived(where); spots.refresh(); props.arrived())
	stage.walked.connect(func(_id): props.arrived())
	view.people_at = stage.standing
	stage.sync(game, true)
	menus.title()
	audio.ambience("rain_door")
	# a picture of the title, then quit: for checking a build on a machine nobody's sitting at
	#   TheBouncer --grab /tmp/title.png
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	var at := args.find("--grab")
	if at >= 0 and at + 1 < args.size():
		_grab(args[at + 1])


func _grab(path: String) -> void:
	for i in 90:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


# The lot is three places in one: the building from across the gravel when he arrives, the
# pickup's window, and the step at the end with the big man at his truck. And the back hall has the
# front desk through the hotel door, for as long as he's talking to the night clerk.
func _frame_for(where: String) -> String:
	if game.story == null:
		return ""
	if where == "hall":
		if _choices_from("at_hall.night_clerk"):
			return "clerk"
		return "phone" if _choices_from("at_hall.payphone") else ""
	if where == "pool":
		return "juke" if _choices_from("at_jukebox") or _choices_from("at_pool.kid_jukebox") else ""
	# Gary's office, through Gary's eyes (content/ink/office.ink): the man in the doorway until he
	# sits; turned to the bookkeeper while she does the papers
	if where == "office":
		if _choices_from("interview.arrive"):
			return "door"
		return "bk" if _choices_from("interview.paperwork") else ""
	# the walk (content/ink/walk.ink): the old man at the wharf's rail; the highway, walking along it
	# to the Esso; the kid on the freezer, once he's talking to him
	if where == "street":
		if _choices_from("dusk.highway"):
			return "highway"
		return "wharf" if _choices_from("dusk.wharf") else ""
	if where == "esso":
		var kn: Array = game.vars().get("knows", [])
		if _choices_from("dusk.kid_rater") or (_choices_from("dusk.esso_lot") and ("esso_sky" in kn or "esso_rater" in kn)):
			return "kid"
		return ""
	if where == "t28":
		# on a stool with them once he's sat down; on his feet at the end of the table otherwise
		for k in ["at_t28.sit", "at_t28.stories", "at_t28.another", "at_t28.tip_offer", "at_t28.walter_intro"]:
			if _choices_from(k):
				return ""
		return "stand"
	if where != "lot":
		return ""
	var v: Dictionary = game.vars()
	if int(BUtil.js_int(v.get("clock", 0))) < 1190:
		return "arrive"
	if "lot_scene" in v.get("fam", []):
		return "truck"
	return "pickup"


# whether the choices on offer come out of this stitch of the Ink
func _choices_from(path: String) -> bool:
	for c in game.story.current_choices():
		if str(c.source_path).begins_with(path + "."):
			return true
	return false


func _load_content() -> Dictionary:
	var txt := FileAccess.get_file_as_string("res://data/content.json")
	var d = JSON.parse_string(txt)
	if not (d is Dictionary):
		push_error("content.json didn't read")
		return {}
	return d


func _apply_window() -> void:
	if OS.has_feature("editor") or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.get("fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)


func apply_settings() -> void:
	store.save_settings()
	_apply_window()
	column.apply_settings()
	view.resize()
	audio.apply(settings)


# ---------------------------------------------------------------- the night

func start_new(in_slot: int) -> void:
	slot = in_slot
	settings["slot"] = slot
	store.save_settings()
	reset_story()
	in_game = true
	menus.hide_all()
	var res := game.new_game()
	persist()
	# the night opens wherever its first place line is (the lot), not where the story's
	# bookkeeping says he'll be later: start there, don't walk there
	var opening := game.here() if game.here() != "" else "door"
	for it in res.get("items", []):
		if it.get("kind") == "place":
			opening = str(it.here)
			break
	view.frame = _frame_for(opening)
	view.jump_to(opening)
	stage.sync(game, true)
	show(res, true)
	audio.unlock()


# A night saved by an earlier build was played under a story that has changed since. It loads and
# plays on, but whatever the new story added starts partway through the night, so it says so. A
# build is the day it was made and its story's hash (tools/build.mjs): only the hash says the story
# changed, so the same story built again another day isn't older.
func older_story(save) -> bool:
	if save == null or save.get("ended", false):
		return false
	var meta = game.content.get("meta", {})
	var now := _story_of(str(meta.get("build", "")) if meta is Dictionary else "")
	var then := _story_of(str(save.get("build", "")))
	return now != "" and then != "" and then != now


static func _story_of(build: String) -> String:
	return RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}-").sub(build, "")


func resume(in_slot: int) -> void:
	var save = store.load_slot(in_slot)
	if save == null:
		start_new(in_slot)
		return
	slot = in_slot
	settings["slot"] = slot
	store.save_settings()
	var older := older_story(save)
	var res := game.load_save(save)
	if res.is_empty():
		menus.toast("That night couldn't be read. Starting it fresh.")
		start_new(in_slot)
		return
	reset_story()
	in_game = true
	menus.hide_all()
	column.begin_batch()
	render_items(game.night_log, false)
	if not game.night_log.is_empty() and not game.ended:
		if older:
			column.add_aside([["Picked up where you left off.", true], [" This night was saved under an older version of the story, so it goes on from the floor, and some of it may not line up. Start Wednesday over for the night as it is now.", false]])
		else:
			column.add_aside([["Picked up where you left off.", true]])
	column.reveal(false)
	view.frame = _frame_for(game.here())
	view.jump_to(game.here() if game.here() != "" else "door")
	stage.sync(game, true)
	if older and not game.ended:
		# the scene it was saved in may not be in this story any more, or not where it was: a
		# night picked up mid-scene can lose its place and run out early, so it goes on from the floor
		var floor_res := game.jump("hub")
		persist()
		show(floor_res, true)
	else:
		after({"choices": game.choices, "ended": game.ended}, false)
	column.scroll_to_end()
	audio.unlock()


func reset_story() -> void:
	if rolling != null and rolling.has_method("cancel"):
		rolling.cancel()
	rolling = null
	printing = null
	pending = null
	shown_knots.clear()
	hand.stop()
	props.drop_all()
	marks.clear()
	column.reset()


func persist() -> void:
	if game.story == null:
		return
	_save_soon = -1.0
	if not store.save(slot, game.serialize()):
		menus.toast("The night couldn't be saved on this machine.")


func persist_soon() -> void:
	_save_soon = 0.9


func back_to_title() -> void:
	if in_game and not game.ended:
		persist()
	if rolling != null and rolling.has_method("cancel"):
		rolling.cancel()
	rolling = null
	pending = null
	in_game = false
	hand.stop()
	menus.title()


# the player's choice, by its place among the visible choices
func choose(i: int) -> void:
	if not in_game or pending != null or rolling != null or game.ended or menus.is_open():
		return
	var list := game.visible_choices()
	if i < 0 or i >= list.size():
		return
	var considered := hand.leave(i)
	var res := game.choose(i, {"considered": considered})
	if res.is_empty():
		return
	persist()
	audio.sfx("choose")
	marks.fade_all()
	show(res, true)


# Handling a thing between choices (Game.toy). If a choice was waiting for it, the night moves on
# from that choice as from any other; if not, what it changed goes quietly into the head, and
# anything said about it goes in above the choices. Returns "chose", "said" or "".
func toy(id: String, what: String) -> String:
	if not in_game or pending != null or rolling != null or game.ended:
		return ""
	var res := game.toy(id, what)
	if res.is_empty():
		return ""
	if res.get("chose", false):
		hand.leave(-1)
		persist()
		show(res, true)
		return "chose"
	if not res.items.is_empty():
		column.begin_batch()
		var first := render_items(res.items, true)
		column.reveal(true)
		if first != null:
			column.keep_in_view(first)
	refresh_status()
	persist_soon()
	return "said"


func show(res: Dictionary, live: bool) -> void:
	column.clear_choices()
	spots.clear()
	read_chars = 0
	if live:
		for it in res.get("items", []):
			if it.get("kind") == "line":
				read_chars += str(it.get("text", "")).length()
	column.begin_batch()
	var first := render_items(res.get("items", []), live)
	column.reveal(live)
	if pending == null:
		after(res, live)
	else:
		refresh_status()
	if live and first != null:
		column.scroll_to(first)


func after(res: Dictionary, live: bool) -> void:
	if res.get("ended", false):
		var stamped := false
		for it in game.night_log:
			if str(it.get("cls", "")) == "end":
				stamped = true
		column.show_end(stamped)
	else:
		column.show_choices(game.visible_choices(), Look.TENSION_WORDS)
	refresh_status()
	# a scene seen from somewhere of its own (the front desk, the payphone, the jukebox, a stool at
	# table 28, the doorway of Gary's office, the wharf's rail, the highway, the kid on the freezer):
	# over to it, and back
	if view.place in ["hall", "pool", "t28", "office", "street", "esso"] and not res.get("ended", false):
		var f := _frame_for(view.place)
		if f != view.frame:
			view.frame = f
			view.walk_to(view.place, not live)
	stage.sync(game, false)
	spots.refresh()
	hand.attach(read_chars)
	if live:
		_sync_sound()


func refresh_status() -> void:
	var st := game.status()
	# the place as the player sees it: in the prologue he's out in the lot while the story's
	# bookkeeping already has him on the floor
	var shown := st.duplicate()
	if Look.PLACE.has(view.place):
		shown.here = view.place
	column.set_status(shown)
	view.drinks = int(st.get("felt", st.drinks))
	view.tension = int(st.tension)
	view.hurt = int(st.hurt)
	view.clock = int(st.clock)
	pub.set_clock(int(st.clock))
	props.status(st)
	notes.refresh()


# ---------------------------------------------------------------- the reader

func _is_tape(it) -> bool:
	if it == null:
		return false
	if it.get("kind") == "screen" and it.get("name") == "ledger":
		return true
	return it.get("screen") == "ledger" and (it.get("kind") == "line" or it.get("kind") == "word")


func _tape_on() -> bool:
	return settings.get("reveal", "lines") == "lines"


# Draw items into the column (and the room). Returns the first node drawn.
func render_items(items: Array, live: bool) -> Control:
	var first: Control = null
	var i := 0
	var walked := false     # a second place in the same stretch is a stop after the first, not instead of it
	while i < items.size():
		var it: Dictionary = items[i]
		if live and printing == null and _is_tape(it) and _tape_on():
			pending = items.slice(i)
			_print_tape()
			return first
		var node: Control = null
		match str(it.get("kind", "")):
			"line":
				node = column.add_line(it)
				_prompts(it)
				var mk = it.get("mark")
				if mk != null and it.get("role") == "voice":
					marks.add(mk, str(content.voices.get(str(it.get("speaker")), {}).get("style", it.get("speaker"))), live)
				if it.get("prop") != null:
					props.offer(it, live)
				if live and it.get("role") == "dialogue":
					stage.speaking(str(it.get("speaker", "")))
			"chosen":
				node = column.add_chosen(it)
			"place":
				node = column.add_place(it)
				view.frame = _frame_for(str(it.here))
				view.walk_to(str(it.here), not live, walked)
				walked = true
				if live:
					audio.sfx("steps")
			"word":
				node = column.add_word(it)
			"check":
				var r: Dictionary = it.roll
				var p := Checks.odds(int(it.target), int(r.get("mod", 0)), int(r.get("tension", 0)))
				var odds := ("%d%%" % roundi(p * 100.0)) if settings.get("odds", "words") == "numbers" else Checks.odds_word(p)
				var card := column.add_check(it, odds)
				node = card
				if not live or settings.get("dice", "full") == "still":
					card.still()
				else:
					pending = items.slice(i + 1)
					rolling = dice
					dice.play(it, card, p, _after_dice)
					if first == null:
						first = node
					return first
			"task":
				node = column.add_aside([["Noted. " if it.get("op") == "add" else "Done. ", true], [str(it.get("text", "")), false]])
				if live:
					audio.sfx("pen")
			"stats":
				node = column.add_stats(it)
			"stat":
				# one of his stats moving, where it moved: the old number struck through
				node = column.add_aside([[str(it.get("label", "")) + " ", true], [str(int(it.get("from", 0))), false, true], [" " + str(int(it.get("to", 0))), true]])
				if live:
					audio.sfx("pen")
			"psyche":
				var parts := _psyche_parts(it)
				if not parts.is_empty():
					node = column.add_aside(parts)
			"screen":
				column.use_screen(it.get("name"))
			"fx":
				var ty := str(it.get("type", ""))
				if ty == "portrait":
					if live:
						stage.glance(str(it.get("id", "")))
				elif live:
					_fx(it)
			"pause":
				if live:
					pending = items.slice(i + 1)
					node = column.add_pause(_go_on)
					if first == null:
						first = node
					return first
		if node != null and first == null:
			first = node
		i += 1
	return first


func _prompts(it: Dictionary) -> void:
	if not settings.get("prompts", true):
		return
	var knot := str(it.get("knot", ""))
	if knot != "" and prompts.has(knot) and not shown_knots.has(knot):
		shown_knots[knot] = true
		for p in prompts[knot]:
			column.add_prompt(str(p.text))
	if it.get("prompt") != null and str(it.prompt) != "":
		column.add_prompt(str(it.prompt))


func _psyche_parts(it: Dictionary) -> Array:
	var lab := func(id): return str(content.voices.get(str(id), {}).get("label", str(id).to_upper()))
	match str(it.get("op", "")):
		"seat":
			return [[lab.call(it.voice), true], [" has a seat in his head now.", false]]
		"unseat":
			return [[lab.call(it.voice), true], [" is out of his head.", false]]
		"bond":
			return [[lab.call(it.a), true], [" and ", false], [lab.call(it.b), true], [" come round to each other.", false]]
		"rift":
			return [[lab.call(it.a), true], [" and ", false], [lab.call(it.b), true], [" fall out.", false]]
	return []


# "Go on", after a #pause
func _go_on() -> void:
	var rest = pending
	pending = null
	if rest == null:
		return
	column.begin_batch()
	var f := render_items(rest, true)
	column.reveal(true)
	if pending == null:
		after({"choices": game.choices, "ended": game.ended}, true)
	if f != null:
		column.scroll_to(f)


func _after_dice() -> void:
	rolling = null
	var rest = pending if pending != null else []
	pending = null
	var f := render_items(rest, true)
	column.reveal(true)
	if pending == null:
		after({"choices": game.choices, "ended": game.ended}, true)
	if f != null:
		column.keep_in_view(f)


func _fx(it: Dictionary) -> void:
	match str(it.get("type", "")):
		"sfx":
			audio.sfx(str(it.get("id", "")))
		"music":
			audio.track(str(it.get("id", "")))
		"amb":
			audio.ink_ambience(str(it.get("id", "")), game.here())
		"look":
			_look(str(it.get("id", "")))


# The Ink's #look: what turns his head (a sound across the room, someone pointing it out to him):
# someone in the room, if he can see them, or a place in it. Not if the player's turning it, and not
# somewhere he's standing.
func _look(id: String) -> void:
	if stage.present(id):
		stage.glance(id)
		return
	if not Posts.POSTS.has(id):
		return
	var p: Vector3 = Posts.POSTS[id].at
	if Vector2(p.x - view.eye_pos.x, p.z - view.eye_pos.z).length() < 1.0:
		return
	view.look_at_point(Vector3(p.x, 1.0, p.z))


func _sync_sound() -> void:
	var st := game.status()
	var g := func(n): return int(BUtil.js_int(game.get_var(n)))
	audio.room({"n": g.call("room_count"), "heat": g.call("pool_heat"), "rounds": g.call("t28_rounds"),
		"rats": g.call("rat_count"), "clock": int(st.clock), "here": str(st.here)})
	audio.place(str(st.here), int(st.clock))


# ---------------------------------------------------------------- the till tape at close

# The ledger prints the way the till prints its tape at close: a line at a time, the printer
# chattering, a stop before the bartender's word, the stamp at the bottom, and the tape torn off.
# Space, enter or a click prints the rest at once.
func _print_tape() -> void:
	printing = {"fast": false, "over": false}
	rolling = self
	get_tree().create_timer(0.9).timeout.connect(_tape_step)


func _tape_rows(it: Dictionary) -> int:
	if it.get("kind") == "line" or it.get("kind") == "word":
		return maxi(1, ceili(str(it.get("text", "")).length() / 38.0))
	return 0


func _tape_step() -> void:
	if printing == null or printing.over:
		return
	var rest: Array = pending if pending != null else []
	if not printing.fast and not rest.is_empty() and _is_tape(rest[0]):
		var it: Dictionary = rest.pop_front()
		pending = rest
		var node := render_items([it], true)
		column.reveal(true)
		var n := 0 if str(it.get("cls", "")) == "end" else _tape_rows(it)
		for r in n:
			get_tree().create_timer(r * 0.17).timeout.connect(func(): if printing != null and not printing.fast: audio.sfx("printer"))
		if str(it.get("cls", "")) == "end":
			audio.sfx("stamp")
		if node != null:
			column.keep_in_view(node)
		var nxt = rest[0] if not rest.is_empty() else null
		var wait := 0.38 if it.get("kind") == "screen" else 0.17 + maxi(1, n) * 0.17 + (0.12 if str(it.get("cls", "")) == "head" else 0.0)
		if nxt != null and str(nxt.get("cls", "")) == "total":
			wait += 1.5
		elif nxt != null and str(nxt.get("cls", "")) == "end":
			wait += 0.7
		get_tree().create_timer(wait).timeout.connect(_tape_step)
		return
	while not rest.is_empty() and _is_tape(rest[0]):
		var it2: Dictionary = rest.pop_front()
		render_items([it2], false)
		if str(it2.get("cls", "")) == "end":
			audio.sfx("stamp")
	pending = rest
	column.reveal(false)
	var tear := func():
		if printing == null:
			return
		audio.sfx("tear")
		var left: Array = pending if pending != null else []
		printing = null
		rolling = null
		pending = null
		var f := render_items(left, true)
		column.reveal(true)
		if pending == null:
			after({"choices": game.choices, "ended": game.ended}, true)
		if f != null:
			column.keep_in_view(f)
	if printing.fast:
		tear.call()
	else:
		get_tree().create_timer(0.65).timeout.connect(tear)


# (the tape takes the dice's place for skipping)
func finish() -> void:
	if printing != null and not printing.fast:
		printing.fast = true
		_tape_step()


func cancel() -> void:
	if printing != null:
		printing.over = true
	printing = null


# ---------------------------------------------------------------- the end

func _end_action(what: String) -> void:
	match what:
		"copy":
			DisplayServer.clipboard_set(_transcript())
			menus.toast("The night is on the clipboard.")
		"restart":
			menus.confirm("Start Wednesday over?", "This night, as it ended, goes. A new one starts in its place.", "Start over", func(): store.clear(slot); start_new(slot))
		"title":
			back_to_title()


func _transcript() -> String:
	var out: Array = ["THE BOUNCER. Wednesday, the test shift.", ""]
	var st := game.status()
	if bool(st.get("statsSet", false)):
		var bits: Array = []
		for k in Checks.STAT_ORDER:
			bits.append(str(Checks.STATS[k].label) + " " + str(int(st.stats.get(k, 0))))
		out.insert(1, "Him: " + ", ".join(bits) + ".")
	for it in game.night_log:
		match str(it.get("kind", "")):
			"line":
				var lab := str(it.get("label", ""))
				out.append((lab + ": " if lab != "" and it.get("role") != "narration" else "") + str(it.get("text", "")))
			"chosen":
				out.append("")
				out.append("> " + str(it.get("text", "")))
			"check":
				out.append("[%s %s %d: %s]" % [str(it.get("label", "")), str(it.get("word", "")), int(it.get("target", 0)), "success" if it.get("success") else "failure"])
			"place":
				out.append("")
				out.append("-- " + str(Look.CAPTION.get(str(it.here), it.here)) + ", " + Look.clock_text(int(it.get("clock", 0))))
	return "\n".join(out)


# ---------------------------------------------------------------- input

func _on_world_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and view.was_click():
		if dice.wants_click():
			return
		spots.click()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey:
		_key(e)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		dice.mouse(e.pressed)
	elif e is InputEventJoypadButton:
		_pad(e)
	elif e is InputEventJoypadMotion:
		_stick(e)


func _key(e: InputEventKey) -> void:
	var k := e.physical_keycode
	# looking round: the arrow keys and the keys by the left hand
	var turn := {KEY_LEFT: Vector2(-1, 0), KEY_A: Vector2(-1, 0), KEY_RIGHT: Vector2(1, 0), KEY_D: Vector2(1, 0),
		KEY_UP: Vector2(0, 1), KEY_W: Vector2(0, 1), KEY_DOWN: Vector2(0, -1), KEY_S: Vector2(0, -1)}
	if turn.has(k) and not menus.is_open():
		var v: Vector2 = turn[k]
		if e.pressed:
			view.keys_turn = Vector2(v.x if v.x != 0 else view.keys_turn.x, v.y if v.y != 0 else view.keys_turn.y)
		else:
			view.keys_turn = Vector2(0 if v.x != 0 else view.keys_turn.x, 0 if v.y != 0 else view.keys_turn.y)
		get_viewport().set_input_as_handled()
		return
	if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
		if menus.is_open():
			return
		if dice.key(e.pressed):
			get_viewport().set_input_as_handled()
			return
		if not e.pressed or e.echo:
			return
		get_viewport().set_input_as_handled()
		if pending != null and rolling == null:
			_go_on()
		elif rolling != null and rolling.has_method("finish"):
			rolling.finish()
		else:
			column.hurry()
			view.hurry()
		return
	if not e.pressed or e.echo:
		return
	if k == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if props.holding():
			props.put_down()
		elif notes.visible:
			notes.close()
		elif sketch.visible:
			sketch.close()
		elif menus.is_open():
			menus.back()
		elif in_game:
			menus.pause()
		return
	if menus.is_open():
		return
	if not in_game:
		return
	if k == KEY_TAB:
		get_viewport().set_input_as_handled()
		sketch.close()
		notes.toggle()
		return
	if k == KEY_M:
		get_viewport().set_input_as_handled()
		notes.close()
		sketch.toggle()
		return
	if k == KEY_E or k == KEY_F:
		get_viewport().set_input_as_handled()
		if props.holding():
			props.key(k)
		else:
			spots.use()
		return
	if k == KEY_Q or k == KEY_R:
		if props.holding():
			get_viewport().set_input_as_handled()
			props.key(k)
		return
	if k == KEY_PAGEUP or k == KEY_PAGEDOWN:
		column.scroll_by(-500 if k == KEY_PAGEUP else 500)
		return
	var n := -1
	if k >= KEY_1 and k <= KEY_9:
		n = k - KEY_1 + 1
	elif k >= KEY_KP_1 and k <= KEY_KP_9:
		n = k - KEY_KP_1 + 1
	if n > 0:
		get_viewport().set_input_as_handled()
		var row := column.row_for_key(n)
		if row != null:
			hand.key_on(row.index)
			choose(row.index)


# ---------------------------------------------------------------- a controller

# The basics on a pad. Either stick looks round. Up and down on the d-pad go through the choices,
# and A makes the one that's lit; with none lit, A is space (go on, or hold to shake the dice and
# let go to throw). B and Start are Esc, Y is E, Back opens his notes, and the
# shoulders go through what's in his hands, or the left one opens the floor sketch. The menus take
# the d-pad and A themselves.
const PAD_DEAD := 0.25
var pad_row: Control = null
var _sticks := {}
var _stick_on := false


func _pad_key(k: Key, pressed := true) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = pressed
	_key(ev)


func _pad(e: InputEventJoypadButton) -> void:
	match e.button_index:
		JOY_BUTTON_A:
			if e.pressed and not menus.is_open() and column.rows.has(pad_row) and is_instance_valid(pad_row):
				var i: int = pad_row.index
				_pad_pick(null)
				hand.key_on(i)
				choose(i)
				return
			_pad_key(KEY_SPACE, e.pressed)
		JOY_BUTTON_B, JOY_BUTTON_START:
			if e.pressed:
				_pad_key(KEY_ESCAPE)
		JOY_BUTTON_Y:
			if e.pressed:
				_pad_key(KEY_E)
		JOY_BUTTON_BACK:
			if e.pressed:
				_pad_key(KEY_TAB)
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			if not e.pressed:
				return
			if props.holding():
				_pad_key(KEY_Q if e.button_index == JOY_BUTTON_LEFT_SHOULDER else KEY_R)
			elif e.button_index == JOY_BUTTON_LEFT_SHOULDER:
				_pad_key(KEY_M)
		JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
			if e.pressed and not menus.is_open() and in_game:
				_pad_step(-1 if e.button_index == JOY_BUTTON_DPAD_UP else 1)


func _pad_step(d: int) -> void:
	var rows: Array = column.rows.filter(func(r): return is_instance_valid(r) and r.is_visible_in_tree())
	if rows.is_empty():
		return
	var at := rows.find(pad_row)
	at = clampi(at + d, 0, rows.size() - 1) if at >= 0 else (0 if d > 0 else rows.size() - 1)
	_pad_pick(rows[at])
	column.keep_in_view(rows[at])


func _pad_pick(r: Control) -> void:
	if pad_row != null and is_instance_valid(pad_row) and pad_row != r:
		pad_row.hand(false)
	pad_row = r
	if r != null:
		r.hand(true)


func _stick(e: InputEventJoypadMotion) -> void:
	if e.axis > JOY_AXIS_RIGHT_Y:
		return
	_sticks[e.axis] = e.axis_value
	var v := Vector2(float(_sticks.get(JOY_AXIS_LEFT_X, 0.0)) + float(_sticks.get(JOY_AXIS_RIGHT_X, 0.0)),
		-(float(_sticks.get(JOY_AXIS_LEFT_Y, 0.0)) + float(_sticks.get(JOY_AXIS_RIGHT_Y, 0.0)))).limit_length(1.0)
	if v.length() < PAD_DEAD or menus.is_open():
		v = Vector2.ZERO
	if settings.get("invert", false):
		v.y = -v.y
	# a stick at rest leaves the keys alone
	if v == Vector2.ZERO and not _stick_on:
		return
	_stick_on = v != Vector2.ZERO
	view.keys_turn = v


func _process(dt: float) -> void:
	if _save_soon > 0.0:
		_save_soon -= dt
		if _save_soon <= 0.0:
			persist()


# the caches are static and outlive the scene; let go of them before the servers shut down,
# or the exported game falls over on its way out
func _exit_tree() -> void:
	Pub._glb_cache.clear()
	Pub._tex_cache.clear()
	Look.fonts.clear()
	Dice._faces.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if in_game and game.story != null and not game.ended:
			persist()
		store.save_settings()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		hand.away(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		hand.away(false)
