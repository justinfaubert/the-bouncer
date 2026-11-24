# Last Call: Wednesday, the test shift, through his eyes, printed.
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
var going: Going
var feet: Feet
var dice: Dice
var props: Props
var door_hand: DoorHand
var darts: Darts
var cig: CigMachine
var mats: BeerMats
var pool: Pool
var keys: KeysCard
var truck: Truck
var fight: Fight
var cards: FightCards
var plant: FishPlant
var menu_practice: Practice     # practice outside a night: the Games and Rehearse (settings)
var glasses: WineGlasses
var marks: Marks
var talk: Talk
var audio: Sound
var intro: Intro
var full_frame := false        # the picture takes the whole screen: the cold open and the title (game/intro.gd)

var in_game := false
var slot := 1
var pending = null             # the rest of a batch, waiting behind a pause, the dice or the tape
var rolling = null             # the dice or the tape while they play
var printing = null            # the tape
var shown_knots := {}
var prompts := {}
var read_chars := 0
var _save_soon := -1.0
# The clock in the column's head: it runs up to the night's a minute at a time, as he walks there and
# as the lines come in, rather than jumping (the skeleton's "the clock moves when he moves"). His
# notes and the menus stop it.
var clock_shown := -1
var _clock_to := -1
var _tick := 0.0
var _quit_asked := false
var answering := false         # a verdict made by hand: the room answers before the column (choose_by_hand)


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
	pub.dressing.washer.flipped.connect(_washer_flipped)
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
	audio.view = view
	audio.setup(settings)

	# what he overhears, under the voices' marks (game/talk.gd)
	talk = Talk.new()
	talk.set_anchors_preset(Control.PRESET_FULL_RECT)
	talk.anchor_right = WORLD_W
	root.add_child(talk)
	talk.setup(view, stage, content.get("talk", []), func(n): return game.get_var(n), func(): return game.psyche,
		func(): return in_game and pending == null and rolling == null and not game.ended)
	talk.finished.connect(overheard)
	talk.said.connect(func(role, id, text): audio.line({"role": "dialogue", "speaker": role, "text": text}, stage.head_of(id)))

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
		column.voice_styles[id] = str(content.voices[id].get("style", id))
	column.chose.connect(choose)
	column.hand_on.connect(func(i, on):
		hand.on_row(i, on)
		door_hand.row_on(i, on))
	column.pointed.connect(func(i, on): spots.point_out(i, on))
	column.end_action.connect(_end_action)

	spots = Hotspots.new()
	add_child(spots)
	spots.setup(self)
	going = Going.new(self)
	feet = Feet.new(self)
	hand = Hand.new()
	add_child(hand)
	hand.setup(self)
	dice = Dice.new()
	add_child(dice)
	dice.setup(self)
	props = Props.new()
	add_child(props)
	props.setup(self)
	door_hand = DoorHand.new()
	add_child(door_hand)
	door_hand.setup(self)
	darts = Darts.new()
	add_child(darts)
	darts.setup(self)
	darts.left.connect(_darts_left)
	plant = FishPlant.new()
	pub.add_child(plant)
	plant.build_for(pub)
	fight = Fight.new()
	add_child(fight)
	fight.setup(self)
	cards = FightCards.new()
	add_child(cards)
	cards.setup(self, fight, plant)
	menu_practice = Practice.from_dict(settings.get("menu_practice", {}))
	cig = CigMachine.new()
	add_child(cig)
	cig.setup(self)
	cig.left.connect(_cig_left)
	mats = BeerMats.new()
	add_child(mats)
	mats.setup(self)
	mats.left.connect(_cig_left)
	glasses = WineGlasses.new()
	add_child(glasses)
	glasses.setup(self)
	glasses.left.connect(_cig_left)
	pool = Pool.new()
	add_child(pool)
	pool.setup(self)
	pool.left.connect(_pool_left)
	# the keys for whatever's in his hands (game/keys_card.gd): added after the toys so F1 reaches it first
	keys = KeysCard.new()
	add_child(keys)
	truck = Truck.new()
	add_child(truck)
	truck.setup(self)
	truck.left.connect(_truck_left)

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
	view.arrived.connect(func(where): stage.arrived(where); spots.refresh(); props.arrived(); going.arrived(where))
	view.ran.connect(func(): going.ran())
	view.settled.connect(func(): audio.sfx("thump", 0.3, 0.7))
	view.first_sight.connect(func(): letterbox(6.0))
	stage.walked.connect(func(_id): props.arrived())
	stage.sound.connect(audio.at)
	view.people_at = stage.standing
	stage.sync(game, true)
	# the cold open, before the title: the first time the game starts, and whenever it's asked for
	# (the title's "The cold open", or --intro); after that the title comes in on its own shot
	intro = Intro.new()
	root.add_child(intro)
	intro.setup(self)
	intro.finished.connect(_after_intro)
	audio.ambience("rain_door")
	# a picture of the title, then quit: for checking a build on a machine nobody's sitting at
	#   TheBouncer --grab /tmp/title.png
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	var at := args.find("--grab")
	if at >= 0 and at + 1 < args.size():
		intro.title_only()
		_grab(args[at + 1])
	elif args.has("--no-intro"):
		menus.title()
	elif args.has("--intro") or not bool(settings.get("intro_seen", false)):
		intro.play()
	else:
		intro.title_only()


func _after_intro() -> void:
	if not bool(settings.get("intro_seen", false)):
		settings["intro_seen"] = true
		store.save_settings()
	menus.title(true)


func _grab(path: String) -> void:
	for i in 150:
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
		if _choices_from("wharf_day") or _choices_from("haul"):
			return "wharf"
		if _choices_from("strip"):
			return "highway"
		return "wharf" if _choices_from("dusk.wharf") else ""
	if where == "esso":
		var kn: Array = game.vars().get("knows", [])
		if _choices_from("esso_day") and int(BUtil.js_int(game.vars().get("clock", 0))) >= 960:
			return "kid"
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
	if _choices_from("at_front"):
		return "step"
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

# The days a night can start on (Hutch, 23 November: "the other 2 nights aren't playable from the
# start, it just starts the 1st day over"). The Nights were three saves of Wednesday; Thursday and
# Friday only came after a whole Wednesday. Now a night can start on any of them: a new game, then
# straight to that day's first knot, as if Wednesday had gone by quietly (no incidents, nobody met
# who wasn't met on the door by default). dawn is where Thursday starts (it sets the new day).
const DAYS := [["wednesday", "Wednesday", "The test shift: Gary's office at four, then the door."],
	["dawn", "Thursday", "His own day on the island, the morning after the test shift."],
	["friday", "Friday", "The first real shift, and Friday's line in the rain."]]


func start_day(in_slot: int, knot: String) -> void:
	start_new(in_slot, knot)


func start_new(in_slot: int, from_knot := "") -> void:
	slot = in_slot
	settings["slot"] = slot
	store.save_settings()
	reset_story()
	in_game = true
	menus.hide_all()
	_leave_full_frame()
	var res := game.new_game()
	if from_knot != "" and from_knot != "wednesday":
		res = game.jump(from_knot)
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
	view.print_in(1.4)
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
	_leave_full_frame()
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
	view.print_in(1.1)
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


# A moment held like a film: bars come in over the picture, top and bottom, for secs, and go. The
# moments are few and the night's own: the Sov's front the first time, from the town; the bell for
# last call; the night's end, where they stay (secs 0). The page is untouched, so nothing is taken
# from the player's hands.
var _bars: Array = []
var _bars_tw: Tween
const BARS := 0.09

func letterbox(secs: float) -> void:
	if not bool(settings.get("skin", true)):
		return
	if _bars.is_empty():
		for i in 2:
			var b := ColorRect.new()
			b.color = Color("07080b")
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.anchor_top = 0.0 if i == 0 else 1.0
			b.anchor_bottom = 0.0 if i == 0 else 1.0
			root.add_child(b)
			root.move_child(b, view.sheet.get_index() + 1)
			_bars.append(b)
	if _bars_tw != null and _bars_tw.is_valid():
		_bars_tw.kill()
	_bars_tw = create_tween()
	_bars_tw.tween_method(_bars_at, _bars_h(), BARS, 1.1).set_trans(Tween.TRANS_SINE)
	if secs > 0.0:
		_bars_tw.tween_interval(secs)
		_bars_tw.tween_method(_bars_at, BARS, 0.0, 1.4).set_trans(Tween.TRANS_SINE)


func _bars_h() -> float:
	return (_bars[0] as ColorRect).anchor_bottom if not _bars.is_empty() else 0.0


func _bars_at(h: float) -> void:
	for i in _bars.size():
		var b: ColorRect = _bars[i]
		b.anchor_right = view.world_w
		if i == 0:
			b.anchor_bottom = h
		else:
			b.anchor_top = 1.0 - h


func _bars_off() -> void:
	if _bars_tw != null and _bars_tw.is_valid():
		_bars_tw.kill()
	if not _bars.is_empty():
		_bars_at(0.0)


# Out of the title's whole-screen picture and back to the picture and the page, at once: the night
# comes in as a print, so there's nothing to see sliding.
func _leave_full_frame() -> void:
	if intro.playing:
		intro.stop()
	full_frame = false
	view.world_w = WORLD_W
	lay_out(WORLD_W)
	_bars_off()


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
	talk.reset()
	column.reset()
	clock_shown = -1
	going.moved()
	view.floor_spot = null
	view.floor_next = null


func persist() -> void:
	if game.story == null:
		return
	_save_soon = -1.0
	if not store.save(slot, game.serialize()):
		menus.toast("The night couldn't be saved on this machine.")


func persist_soon() -> void:
	_save_soon = 0.9


# Darts, at the board (game/darts.gd): from the night, or from the menu (the games he's met, and the
# rehearsal, which needs no night at all: body is {drinks, hurt, tension, clock, cold}).
var _darts_from := ""
var _truck_from := ""
var _looked_at := {}


# a game he's come across in the night: in the Games on the title from now on
func _met(what: String) -> void:
	var met: Array = settings.get("met", [])
	if not (what in met):
		met.append(what)
		settings["met"] = met
		store.save_settings()

func start_darts(game_mode: String, from_menu: String, body := {}) -> void:
	_darts_from = from_menu
	menus.hide_all()
	if from_menu != "":
		_leave_full_frame()
		view.drinks = int(body.get("drinks", 0))
		view.hurt = int(body.get("hurt", 0))
		view.tension = int(body.get("tension", 0))
		view.jump_to("pool")
		stage.sync(game, true)
		audio.unlock()
		audio.ambience("room_quiet")
	darts.begin(game_mode, from_menu != "", body)


# the truck (game/truck.gd): from Rehearse for now; in the month it's in the lot once he has the keys
func start_truck(from_menu: String, body := {}) -> void:
	_truck_from = from_menu
	menus.hide_all()
	_leave_full_frame()
	audio.unlock()
	stage.sync(game, true)
	truck.begin(from_menu != "", body)


func _truck_left() -> void:
	var m := _truck_from
	_truck_from = ""
	view.drinks = 0
	view.hurt = 0
	view.tension = 0
	column.reset()
	audio.out_mix = {}
	audio.ambience("rain_door")
	if m == "rehearse":
		menus.rehearse("title")
	elif m != "":
		menus.title()


# A fight (game/fight_cards.gd): from the menu (the Games, or Rehearse) or the night.
var _fight_from := ""

func start_fight(id: String, from_menu: String, body := {}) -> void:
	_fight_from = from_menu
	menus.hide_all()
	audio.unlock()
	if from_menu != "":
		_leave_full_frame()
		column.reset()
		_met("fights")
	await cards.run(id, from_menu, body)
	if from_menu != "":
		persist_settings_practice()
		await get_tree().create_timer(4.0).timeout
		view.drinks = 0
		view.hurt = 0
		view.tension = 0
		column.reset()
		if from_menu == "rehearse":
			menus.rehearse("title")
		else:
			menus.games("title")
	else:
		persist()


# What he's practised into knacks, now: the night's, or the menu's.
func knacks_now(from_menu := "") -> Dictionary:
	if from_menu == "" and in_game and game != null:
		return game.practice.fight_knacks()
	return menu_practice.fight_knacks() if menu_practice != null else {}


# Practice outside a night (the Games, Rehearse): kept in the settings, with its own seven.
func practice_play(kind: String, amount: float, how: String) -> Array:
	var st: Dictionary = settings.get("menu_stats", {"str": 6, "con": 5, "dex": 5, "int": 4, "wis": 5, "cha": 4, "gut": 4})
	menu_practice.new_night(int(Time.get_unix_time_from_system() / 21600.0))
	var out := menu_practice.earn(kind, amount, how, st)
	settings["menu_stats"] = st
	return out


# from anywhere: the night's practice when in one, else the menu's
func practise_any(kind: String, amount: float, how: String, from_menu := "") -> Array:
	var out: Array
	if from_menu == "" and in_game and game != null:
		out = game.practise(kind, amount, how)
	else:
		out = practice_play(kind, amount, how)
	_say_practice(out)
	return out


func _say_practice(out: Array) -> void:
	if out.is_empty() or column == null:
		return
	column.begin_batch()
	for ev in out:
		if ev.kind == "mark":
			var s := Practice.says(ev)
			column.add_line({"role": "voice", "speaker": s[0], "label": _voice_label(s[0]), "text": s[1]})
		elif ev.kind == "stat":
			column.add_note("%s %d → %d (practice: %s)" % [Checks.STATS[ev.stat].label, int(ev.from), int(ev.to), Practice.KINDS[ev.practice].label])
		elif ev.kind == "knack":
			column.add_note("A knack: %s. %s" % [ev.name, ev.what])
	column.scroll_to_end()


func _voice_label(id: String) -> String:
	var v = content.get("voices", {}).get(id, {})
	return str(v.get("label", id.to_upper())) if v is Dictionary else id.to_upper()


func persist_settings_practice() -> void:
	settings["menu_practice"] = menu_practice.to_dict()
	store.save_settings()


func _darts_left() -> void:
	if _darts_from == "":
		return
	var m := _darts_from
	_darts_from = ""
	view.drinks = 0
	view.hurt = 0
	view.tension = 0
	column.reset()
	if m == "rehearse":
		menus.rehearse("title")
	else:
		menus.games("title")


# The cigarette machine on the east wall under the news (game/cig_machine.gd): from the night, the
# games, or the rehearsal, the same way as the darts.
var _cig_from := ""

func start_cig(from_menu: String, body := {}) -> void:
	_cig_from = from_menu
	menus.hide_all()
	if from_menu != "":
		_leave_full_frame()
		view.drinks = int(body.get("drinks", 0))
		view.hurt = int(body.get("hurt", 0))
		view.tension = int(body.get("tension", 0))
		view.jump_to("pool")
		stage.sync(game, true)
		audio.unlock()
		audio.ambience("room_quiet")
	cig.begin(from_menu != "", body)


# The beer mats off the edge of the bar (game/beer_mats.gd), the same way.
func start_mats(from_menu: String, body := {}) -> void:
	_cig_from = from_menu
	menus.hide_all()
	if from_menu != "":
		_leave_full_frame()
		view.drinks = int(body.get("drinks", 0))
		view.hurt = int(body.get("hurt", 0))
		view.tension = int(body.get("tension", 0))
		view.jump_to("bar")
		stage.sync(game, true)
		audio.unlock()
		audio.ambience("room_quiet")
	mats.begin(from_menu != "", body)


# The wine glasses on the bar (game/wine_glasses.gd), the same way.
func start_glasses(from_menu: String, body := {}) -> void:
	_cig_from = from_menu
	menus.hide_all()
	if from_menu != "":
		if has_method("_leave_full_frame"):
			call("_leave_full_frame")
		view.drinks = int(body.get("drinks", 0))
		view.hurt = int(body.get("hurt", 0))
		view.tension = int(body.get("tension", 0))
		view.jump_to("bar")
		stage.sync(game, true)
		audio.unlock()
		audio.ambience("room_quiet")
	glasses.begin(from_menu != "", body)


func _cig_left() -> void:
	if _cig_from == "":
		return
	var m := _cig_from
	_cig_from = ""
	view.drinks = 0
	view.hurt = 0
	view.tension = 0
	column.reset()
	if m == "rehearse":
		menus.rehearse("title")
	else:
		menus.games("title")


func back_to_title() -> void:
	if in_game and not game.ended:
		persist()
	if rolling != null and rolling.has_method("cancel"):
		rolling.cancel()
	rolling = null
	pending = null
	in_game = false
	hand.stop()
	menus.hide_all()
	_bars_off()
	intro.title_only()


# the player's choice, by its place among the visible choices
func choose(i: int) -> void:
	if not in_game or pending != null or rolling != null or game.ended or menus.is_open() or answering:
		return
	var list := game.visible_choices()
	if i < 0 or i >= list.size():
		return
	# where he is: a choice about someone or something across the room, or back where he walked away
	# from, isn't his to make from here (Hutch, 23 November: "it needs to be more location and
	# context aware")
	# on his way somewhere a choice took him: the next one waits till he's there (Hutch, 23
	# November: you "can just keep clicking through decisions even if they're not in the physical
	# location"). The column holds them dimmed while he walks.
	if view.walking and not bool(settings.get("click_ahead", false)):
		return
	_far_at = Vector3.INF
	var far := out_of_reach(list[i])
	if far != "":
		# on the floor, he walks over and then does it; anywhere else it's for the player to walk
		if _walk_over_then(list[i]):
			return
		menus.toast(far)
		audio.sfx("click_ui", 0.25, 0.7)
		return
	# played out on the table first: the night waits, and what came of it goes into the Ink
	if list[i].get("game") != null and str(list[i].game.what) == "pool":
		_play_choice(i, list[i].game)
		return
	var considered := hand.leave(i)
	var was_read: bool = list[i].get("read") != null
	Acts.play(self, list[i])
	var res := game.choose(i, {"considered": considered})
	if res.is_empty():
		return
	# what he made of the thing in his hand: it's still in his hand, to do something with
	if was_read:
		props.keep()
	persist()
	audio.sfx("choose")
	marks.fade_all()
	show(res, true)


func _play_choice(i: int, g: Dictionary) -> void:
	answering = true
	column.clear_choices()
	var who: String = g.who if g.who != "" else "bigman"
	start_pool("8bar", who, "", {"stakes": 20, "story": "bigman_" + str(g.meant), "they_break": true}, func(res: Dictionary):
		answering = false
		var r := 3 if res.get("left", false) and not res.has("why") else (1 if res.get("won", false) else 2)
		game.set_var("pool_result", r)
		game.set_var("pool_threw", int(res.get("thrown", 0)))
		game.set_var("pool_dumped", int(res.get("dumped", 0)))
		view.jump_to("pool")
		_choose_now.call_deferred(i))


func _choose_now(i: int) -> void:
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


# A verdict at the door made with his hand (game/door_hand.gd). The choice is made at once and saved,
# but the room answers first: the people are put where the choice puts them (the kid walks in past
# him, or turns back across the gravel) and the room's quiet holds, and only after ANSWER seconds
# does the column say what happened. After a choice that matters, a face changes, someone moves,
# then the words.
const ANSWER := 1.2

func choose_by_hand(i: int, _verdict: String) -> void:
	if not in_game or pending != null or rolling != null or game.ended or menus.is_open() or answering:
		return
	var list := game.visible_choices()
	if i < 0 or i >= list.size():
		return
	var considered := hand.leave(i)
	var res := game.choose(i, {"considered": considered})
	if res.is_empty():
		return
	persist()
	marks.fade_all()
	column.clear_choices()
	spots.clear()
	answering = true
	stage.sync(game, false)
	audio.weigh = 0.6
	await get_tree().create_timer(ANSWER).timeout
	answering = false
	audio.weigh = 0.0
	if not in_game:
		return
	audio.sfx("choose", 0.6)
	show(res, true)


# Pool, at the coin-op (game/pool.gd): from the night (a #game choice, the big man's twenty), from
# Games (the regulars, the money, the Sunday draw), or the rehearsal. opts go to Pool.begin.
var _pool_from := ""
var _pool_choice := -1
var _pool_after := Callable()

func start_pool(game_mode: String, opponent: String, from_menu: String, opts := {}, after := Callable()) -> void:
	_pool_from = from_menu
	_pool_after = after
	menus.hide_all()
	if from_menu != "":
		_leave_full_frame()
		var body: Dictionary = opts.get("body", {})
		view.drinks = int(body.get("drinks", 0))
		view.hurt = int(body.get("hurt", 0))
		view.tension = int(body.get("tension", 0))
		view.jump_to("pool")
		stage.sync(game, true)
		audio.unlock()
		audio.ambience("room_quiet")
		opts["rehearse"] = true
	else:
		_met("pool")
	pool.begin(game_mode, opponent, opts)


func _pool_left(res: Dictionary) -> void:
	var m := _pool_from
	_pool_from = ""
	if _pool_after.is_valid():
		var cb := _pool_after
		_pool_after = Callable()
		cb.call(res)
	if m == "":
		return
	view.drinks = 0
	view.hurt = 0
	view.tension = 0
	column.reset()
	if m == "rehearse":
		menus.rehearse("title")
	elif m == "games":
		menus.pool_menu("title")
	else:
		menus.games("title")
	audio.sfx("choose", 0.6)


# Handling a thing between choices (Game.toy). If a choice was waiting for it, the night moves on
# from that choice as from any other; if not, what it changed goes quietly into the head, and
# anything said about it goes in above the choices. Returns "chose", "said" or "".
func toy(id: String, what: String) -> String:
	if not in_game or pending != null or rolling != null or game.ended or answering:
		return ""
	# the dartboard: the first look says what it is; looked at again with the darts still in it, he
	# goes over and takes them out of the board and throws a few (game/darts.gd). Either way it's met,
	# and from then on it's in the Games on the title.
	if id == "dartboard" and what == "look":
		_met("darts")
		if _looked_at.has(id) and not bool(game.get_var("darts_pulled")) and view.eye_pos.distance_to(darts.to_world.origin) < 8.5:
			start_darts("practice", "")
			return "said"
		_looked_at[id] = true
	# the cigarette machine: the first look says what it is; the next, he goes and stands at it
	if id == "cigmachine" and what == "look":
		_met("cigs")
		if _looked_at.has(id) and view.eye_pos.distance_to(CigMachine.AT) < 10.0:
			start_cig("")
			return "said"
		_looked_at[id] = true
	# the beer mats on the bar: the same, from the bar
	if id == "coasters" and what == "look":
		_met("mats")
		if _looked_at.has(id) and view.eye_pos.distance_to(BeerMats.EDGE) < 3.0:
			start_mats("")
			return "said"
		_looked_at[id] = true
	# the glasswasher's switch on the back bar (world/glasswasher.gd): he leans over and flips it, and
	# then the words for it, which know which way it went
	if id == "washer_switch" and what == "look" and pub.dressing != null:
		var w := pub.dressing.washer
		w.flip()
		game.set_var("washer_on", w.on)
		game.set_var("washer_flips", w.flips)
	# the wine glasses on the bar: the same, from the bar
	if id == "wineglasses" and what == "look":
		_met("glasses")
		if _looked_at.has(id) and view.eye_pos.distance_to(WineGlasses.AT) < 3.5:
			start_glasses("")
			return "said"
		_looked_at[id] = true
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


# The glasswasher switched by somebody else: the bartender, back on, while he wasn't looking.
func _washer_flipped(on: bool, by_jim: bool) -> void:
	if not by_jim or not in_game or game == null or game.ended:
		return
	game.set_var("washer_on", on)
	game.set_var("washer_back", true)


# The room said something he heard through (game/talk.gd): a voice in his head can answer it.
func overheard(id: String) -> void:
	heard("ears:" + id)


# Somewhere his feet have taken him, or anything else a voice can answer that isn't the Ink's
# (out:<area>, world/grounds.gd).
func heard(event: String) -> void:
	if not in_game or pending != null or rolling != null or game.ended:
		return
	var res := game.heard(event)
	if res.is_empty():
		return
	column.begin_batch()
	var first := render_items(res.items, true)
	column.reveal(true)
	if first != null:
		column.keep_in_view(first)
	persist_soon()


func show(res: Dictionary, live: bool) -> void:
	_still_t = WIDE_HOLD
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
		if live:
			letterbox(0.0)
	else:
		var list := game.visible_choices()
		column.show_choices(list, Look.TENSION_WORDS, going.hidden(list))
		_far_shown = {}
		_dim_far(true)
	# a spot on the floor he was to go to, if the page had put him on it (game/going.gd), is
	# forgotten once it hasn't
	view.floor_next = null
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


# Whether a choice is out of his reach from where his own feet have taken him: "" if he can make it,
# else what to tell the player. Only while he's walking about freely (game/feet.gd): a scene that
# put him somewhere put him in reach. A way somewhere is always his (it walks him there). Something
# said to a person, done to a thing, or looked at in the room needs him near it: within REACH of
# whoever or whatever the choice is about (game/hotspots.gd), and outdoors, back in the lot where
# the scene is, not off round the grounds.
const REACH := 4.2
const OUTDOOR_AWAY := ["yard", "town"]
var _reach_t := 0.0
var _far_shown := {}
var _far_at := Vector3.INF          # where the last thing out of reach is (out_of_reach)
var _walk_then := {}                # a choice he's walking over to make: {text, t}

func out_of_reach(c: Dictionary) -> String:
	if not in_game or game == null or game.ended or feet == null or not feet.free_here():
		return ""
	if Going.is_way(c) or c.get("read") != null or c.get("toy") != null:
		return ""
	var zone := Hotspots.zone_of(view.eye_pos)
	if view.place == "lot" and zone in OUTDOOR_AWAY:
		return "He's off round the back of the lot. Walk back out front to do that."
	var key := spots.about(c)
	if key == "":
		return ""
	for k in key.split("|"):
		var at: Array = spots._where(k)
		if at.is_empty():
			continue
		var p: Vector3 = at[0]
		var d := Vector2(p.x - view.eye_pos.x, p.z - view.eye_pos.z).length()
		if d <= REACH:
			return ""
		_far_at = p
		var who := ""
		if k.begins_with("fig:"):
			var ch = game.content.get("characters", {}).get(k.split(":")[1], {})
			if ch is Dictionary and ch.has("label"):
				who = str(ch.label).to_lower()
		return "He's too far off for that. Walk over first." if who == "" else "He's across the room from %s. Walk over first." % who
	return ""


# Across the room from whoever a choice is about: he walks over, to within arm's length or so, and
# the choice is made when he's there (main._process). The player sees him go; nothing's said from
# across the room.
func _walk_over_then(c: Dictionary) -> bool:
	if _far_at == Vector3.INF or view.place != "floor" or view.on_floor != "":
		return false
	var me := Vector3(view.eye_pos.x, 0.0, view.eye_pos.z)
	var them := Vector3(_far_at.x, 0.0, _far_at.z)
	var toward := (me - them).normalized() if me.distance_to(them) > 0.01 else Vector3.BACK
	var stand: Vector3 = going._stand_near(them + toward * 1.3)
	if stand == Vector3.INF:
		return false
	view.go_to_spot(stand)
	audio.sfx("steps")
	_walk_then = {"text": str(c.get("text", "")), "t": 0.0}
	return true


func _walk_then_tick(dt: float) -> void:
	if _walk_then.is_empty():
		return
	_walk_then.t = float(_walk_then.t) + dt
	if view.walking and float(_walk_then.t) < 12.0:
		return
	var text := str(_walk_then.text)
	_walk_then = {}
	if not in_game or game == null or game.ended or pending != null:
		return
	var list := game.visible_choices()
	for i in list.size():
		if str(list[i].get("text", "")) == text:
			if out_of_reach(list[i]) == "":
				choose(i)
			return


# The choices he can't make from where he's walked to, dimmed in the column, and lit again as he
# comes back within reach. Checked a few times a second while he walks.
func _dim_far(force := false) -> void:
	if not in_game or game == null or game.ended or pending != null:
		return
	var list := game.visible_choices()
	var now := {}
	var walking: bool = view.walking and not bool(settings.get("click_ahead", false))
	for i in list.size():
		var far := "On his way there." if walking else out_of_reach(list[i])
		if far != "":
			now[i] = far
	if not force and now.is_empty() and _far_shown.is_empty():
		return
	_far_shown = now
	for i in list.size():
		var r := column.row_for_index(i)
		if r == null:
			continue
		r.modulate.a = 0.4 if now.has(i) else 1.0
		r.tooltip_text = str(now.get(i, ""))


func refresh_status() -> void:
	var st := game.status()
	# the place as the player sees it: in the prologue he's out in the lot while the story's
	# bookkeeping already has him on the floor
	var shown := st.duplicate()
	if Look.PLACE.has(view.place):
		shown.here = view.place
	_clock_to = int(st.clock)
	# a new night, a night picked up, or a long way at once: there at once
	if clock_shown < 0 or clock_shown > _clock_to or _clock_to - clock_shown > 90:
		clock_shown = _clock_to
	column.set_status(shown, clock_shown)
	column.set_seats(game.psyche.seated if game.psyche != null else [], str(Look.TENSION_WORDS[clampi(int(st.tension), 0, Look.TENSION_WORDS.size() - 1)]))
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
					talk.interrupt(str(it.get("speaker", "")))
					stage.speaking(str(it.get("speaker", "")), str(it.get("text", "")))
				if live:
					# its recording, a bark or a whisper (game/sound.gd), from the speaker's head if they're here
					var who := str(it.get("speaker", ""))
					audio.line(it, stage.head_of(who) if it.get("role") == "dialogue" and stage.present(who) else Vector3.INF)
			"chosen":
				# his legs (a walk across the room, game/going.gd) aren't a choice anyone reads
				if str(it.get("toy", "")) != "legs":
					node = column.add_chosen(it)
					# a line of his out loud: his mouth goes with it where he can be seen (Gary's office)
					if live and str(it.get("text", "")).begins_with("\""):
						stage.speaking("him", str(it.text))
			"place":
				going.moved()
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
			# the bell for last call: the night's turn, held like a film for a moment
			if str(it.get("id", "")) == "bell":
				letterbox(5.5)
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
	var b := func(n): return bool(BUtil.js_truthy(game.get_var(n)))
	audio.room({"n": g.call("room_count"), "heat": g.call("pool_heat"), "rounds": g.call("t28_rounds"),
		"rats": g.call("rat_count"), "clock": int(st.clock), "here": str(st.here),
		"t28": stage.present("team_jacket"), "pool_on": stage.present("bigman") or stage.present("buddy"),
		"doors": {"deck": b.call("deck_door"), "kitchen": b.call("kitchen_door"), "hotel": b.call("hotel_door")}})
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
	var out: Array = ["LAST CALL. Wednesday, the test shift.", ""]
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
				# his legs, a walk across the room, aren't a choice anyone reads (render_items)
				if it.get("read") != null:
					out.append("")
					out.append("> " + str(column.voice_labels.get(str(it.read), str(it.read).to_upper())) + ": " + str(it.get("text", "")))
				elif str(it.get("toy", "")) != "legs":
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
	if e is InputEventMouseButton and door_hand.took(e.pressed):
		return
	if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and view.was_click():
		if dice.wants_click():
			return
		# what's under his eyes, or with nothing there, the floor: he goes there (game/going.gd)
		if spots.under != null:
			spots.click()
		else:
			going.click()


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
	# his feet: W A S D walk him where he's free to walk, and turn his head where he isn't; Shift
	# hurries him and Alt leans (game/feet.gd)
	if not e.echo and (k in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_ALT]) and not menus.is_open():
		if feet.key(k, e.pressed) or k in [KEY_SHIFT, KEY_ALT]:
			get_viewport().set_input_as_handled()
			return
	elif e.echo and k in [KEY_W, KEY_A, KEY_S, KEY_D] and feet.on():
		get_viewport().set_input_as_handled()
		return
	# looking round: the arrow keys and the keys by the left hand (when his feet aren't using them)
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
	if notes.visible and (k == KEY_Q or k == KEY_E):
		get_viewport().set_input_as_handled()
		notes.turn_page(k == KEY_Q)
		return
	if k == KEY_E or k == KEY_F:
		get_viewport().set_input_as_handled()
		if props.holding():
			props.key(k)
		elif not feet.use():
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
	_walk_then_tick(dt)
	_reach_t += dt
	if _reach_t > 0.25:
		_reach_t = 0.0
		_dim_far()
	if _save_soon > 0.0:
		_save_soon -= dt
		if _save_soon <= 0.0:
			persist()
	if clock_shown < _clock_to and not notes.visible and not menus.is_open():
		_tick += dt
		# quicker the more there is to go, and the last few minutes a third of a second each: ten
		# minutes take two seconds and a half, an hour five
		if _tick >= clampf(1.5 / float(_clock_to - clock_shown), 0.04, 0.35):
			_tick = 0.0
			clock_shown += 1
			column.show_clock(clock_shown)
	going.process(dt)
	feet.process(dt)
	_widen(dt)


# While he walks on his own feet the picture takes the whole screen and the page slides off to the
# right; it slides back a moment after he stops, or at once when the night has something to say
# (show()). Settings > "The whole screen while he walks".
const WIDE_HOLD := 1.0        # seconds stopped before the page comes back
const WIDE_SPEED := 1.4       # of the screen's width a second
var _still_t := WIDE_HOLD

func _widen(dt: float) -> void:
	if view.stroll:
		_still_t = 0.0
	else:
		_still_t += dt
	var wide: bool = (bool(settings.get("wide_walk", true)) and in_game and _still_t < WIDE_HOLD \
		and not notes.visible and not sketch.visible and not menus.is_open() and not props.holding())
	var spine := Column.SPINE_W / maxf(1.0, root.size.x)
	var to := 1.0 if full_frame or (pool != null and pool.active) or (fight != null and fight.active) else ((1.0 - spine) if wide else WORLD_W)
	if is_equal_approx(view.world_w, to):
		return
	var w := move_toward(view.world_w, to, dt * WIDE_SPEED)
	view.world_w = w
	lay_out(w)


func lay_out(w: float) -> void:
	view.sheet.anchor_right = w
	talk.anchor_right = w
	marks.anchor_right = w
	column.anchor_left = w
	column.anchor_right = 1.0 + (w - WORLD_W)
	var spine := Column.SPINE_W / maxf(1.0, root.size.x)
	column.set_fold(inverse_lerp(WORLD_W, 1.0 - spine, w))
	feet.hint.anchor_right = w
	spots.overlay.anchor_right = w
	props.hint.anchor_right = w
	for b in _bars:
		(b as ColorRect).anchor_right = w
	view.resize()


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
		if feet != null:
			feet.clear()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		hand.away(false)
