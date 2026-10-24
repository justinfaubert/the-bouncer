class_name Game
extends RefCounted
# The game runtime (prototype/web/src/core/game.js, ported line for line). It drives the Ink story
# and turns its output into items the game draws: lines (narration, the teller, dialogue, voices),
# check results, sound and picture cues, tasks, places, the word on him. No drawing here; the same
# class runs the game and the playthrough bots (tests/engine_run.gd).
#
# The Ink's conventions (the full list is in content/ink/README.md):
#   FATHER: text          a line spoken by the voice or character with that id
#   NARRATOR: text        the teller, years later
#   #check: father:wis 12 {n}  on a choice: a check lent by that voice, rolled on his Wisdom (or the
#                         voice's first stat), target 12, situational modifier n
#   #stats                on a line: his seven stats, shown under it (once the interview's set them)
#   #loc: pool            on a choice: where it happens
#   #room: -fighter +kid  on a choice: who it puts out of his head and lets in
#   #hand: drink          on a choice: what it tempts him with, for the voices to lean in on
#   #sfx / #music / #amb / #portrait / #screen / #task / #done / #bark / #pause / #prompt / #always
#   #plate: lot           a picture of a place he isn't in, as it is now
#   #mark: pool.bigman A  on a voice's line: it marks that spot in the room (marks.yaml)
#   #prop: sister_card    on a line: a thing he's handed or picks up (props.yaml)
#   #toy: sister_card look   on a choice: handling that thing that way makes this choice
#   #unlisted             on a choice: not in the list; only handling a thing makes it
#   #read: father truck_keys  on a choice: that voice's read of the thing in his hand; keeping it
#                         puts it in his notes beside the thing, and the voice speaks more often
#
# Reads: what he makes of a thing in his hand (content/ink/hand.ink). Each seated voice reads it, as
# a choice tagged #read: <voice> <thing>, and he keeps one, or none. The kept read is his notes'
# (reads, by thing), the voice is heeded from then on (Psyche.heed: it speaks more often), and the
# Ink can ask kept_read(thing) and heeded(voice). What he carries is the Ink's (his pockets, status).
#
# Items and choices are Dictionaries with the same keys as the browser build's, so a save, a
# transcript or a bot report reads the same from either.

const LOG_CAP := 1500
const SAVE_VERSION := 1
const ROOM := {"door": true, "floor": true, "bar": true, "t28": true, "pool": true}   # one room: seen from anywhere in it
const GROUPS := ["t28", "kids", "staff", "owner", "cook"]                           # rep_<group> in main.ink
const AT_END := 1 << 60                                                              # an event after everything

static var _speaker_re: RegEx

var content: Dictionary
var voice_defs: Dictionary
var char_defs: Dictionary
var props: Dictionary
var speakers: Dictionary = {}
var barks: Barks
var word: Word
var psyche: Psyche
var rng: BRng
var story = null          # Ink.Story
var errors: Array = []

var night_log: Array = []
var path: Array = []       # every choice made tonight: {t: turn, c: clock, x: text, k: check}
var tasks: Dictionary = {}
var check_history: Array = []
var stat_log: Array = []   # his stats moving, once the interview's set them: {stat, from, to, clock, turn}
var barks_used: Array = []
var word_used: Array = []
var said: Dictionary = {}  # group -> {up, down: {id, text}, last}: their word on him
var taught: Array = []     # what THE MANUAL has explained
var hand_used: Array = []  # hand: lines the voices have said to the player
var _hand: Dictionary = {} # what each choice on offer whispers, worked out once per set of choices
var reads: Dictionary = {} # thing -> the read of it he kept: {voice, text, clock}
var turn := 0
var screen = null
var ended := false
var choices: Array = []
var suppressed := 0
var _pending: Array = []
var night_seed := 0
var sketch: Dictionary = {}
var _gv: Callable


# ---------------------------------------------------------------- helpers

static func raw_line(it: Dictionary) -> String:
	if it.get("role") == "teller":
		return "NARRATOR: " + BUtil.js_str(it.get("text"))
	if BUtil.js_truthy(it.get("speaker")):
		return BUtil.js_str(it["speaker"]).to_upper() + ": " + BUtil.js_str(it.get("text"))
	return BUtil.js_str(it.get("text"))


# who said what about him, from a night's log (for saves from before it was kept)
static func said_from(lg: Array) -> Dictionary:
	var out := {}
	for it in lg:
		if it.get("kind") != "word" or not BUtil.js_truthy(it.get("text")):
			continue
		if not out.has(it.group):
			out[it.group] = {}
		var s: Dictionary = out[it.group]
		s[it.way] = {"id": it.get("id"), "text": it.get("text")}
		s["last"] = it.way
	return out


static func pack_log(lg: Array) -> Array:
	var out: Array = []
	for it in lg:
		if it.get("kind") == "diff":
			continue
		if it.get("kind") != "line":
			out.append(it)
			continue
		var o := {}
		for k in it:
			var v = it[k]
			if k == "at" or k == "label" or v == null or (v is bool and v == false):
				continue
			o[k] = v
		if o.get("raw") == raw_line(it):
			o.erase("raw")
		out.append(o)
	return out


# What a choice changed: scalars as {name, from, to}; lists as {name, add, del}.
static func diff_vars(a: Dictionary, b: Dictionary) -> Array:
	var out: Array = []
	var names: Array = b.keys()
	for n in a:
		if not b.has(n):
			names.append(n)
	for n in names:
		var x = a.get(n)
		var y = b.get(n)
		if x is Array or y is Array:
			var xa: Array = x if x is Array else []
			var ya: Array = y if y is Array else []
			var add: Array = []
			var del: Array = []
			for v in ya:
				if not xa.has(v):
					add.append(v)
			for v in xa:
				if not ya.has(v):
					del.append(v)
			if not add.is_empty() or not del.is_empty():
				out.append({"name": n, "add": add, "del": del})
		elif BUtil.js_strict_ne(x, y):
			out.append({"name": n, "from": x, "to": y})
	return out


# an Ink value as the game reads it: a list as its item names, lowest first
static func ink_value(v):
	if v is Ink.InkList:
		var out: Array = []
		for kv in v.ordered_items():
			out.append(kv[0].item_name)
		return out
	return v


# JSON numbers come back as floats in Godot; JavaScript has one kind of number
static func normalize_numbers(v):
	if v is float and v == floor(v) and absf(v) < 9.0e15:
		return int(v)
	if v is Array:
		var out: Array = []
		for x in v:
			out.append(normalize_numbers(x))
		return out
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = normalize_numbers(v[k])
		return out
	return v


static func _vis(list: Array) -> Array:
	var out: Array = []
	for c in list:
		if not c.hidden:
			out.append(c)
	return out


# ---------------------------------------------------------------- setup

func _init(c: Dictionary) -> void:
	if _speaker_re == null:
		_speaker_re = RegEx.create_from_string("^([A-Z][A-Z0-9_]*):\\s+([\\s\\S]*)$")
	content = c
	voice_defs = c.get("voices", {})
	char_defs = c.get("characters", {})
	props = c.get("props", {}) if c.get("props") is Dictionary else {}
	for id in voice_defs:
		speakers[str(id).to_upper()] = {"id": id, "kind": "voice", "def": voice_defs[id]}
	for id in char_defs:
		speakers[str(id).to_upper()] = {"id": id, "kind": "character", "def": char_defs[id]}
	barks = Barks.new(c.get("barks", []))
	word = Word.new(c.get("word", {}))
	# the room in his head holds his own voices; Gary's (whose: gary) speak only in Gary's office
	var his := {}
	for id in voice_defs:
		if not BUtil.js_truthy(voice_defs[id].get("whose")):
			his[id] = voice_defs[id]
	psyche = Psyche.new(his, c.get("psyche"))
	rng = BRng.new(1)
	_gv = get_var
	_reset()


func _reset() -> void:
	night_log = []
	path = []
	tasks = {}
	check_history = []
	stat_log = []
	barks_used = []
	word_used = []
	said = {}
	taught = []
	hand_used = []
	_hand = {}
	reads = {}
	turn = 0
	screen = null
	ended = false
	choices = []
	suppressed = 0
	_pending = []
	night_seed = 0
	sketch = {}


func _make_story():
	var s = Ink.Story.new(content["story"])
	s.allow_external_function_fallbacks = true
	s.on_error = func(message, type): errors.append({"message": str(message), "type": type, "turn": turn})
	s.bind_external_function("seated", func(v): return psyche.is_seated(BUtil.js_str(v)), true)
	s.bind_external_function("tension", func(): return psyche.tension(), true)
	s.bind_external_function("seats_free", func(): return Psyche.MAX_SEATS - psyche.seated.size(), true)
	s.bind_external_function("seat", func(v):
		var ok := psyche.seat(BUtil.js_str(v))
		if ok:
			_pending.append({"kind": "psyche", "op": "seat", "voice": BUtil.js_str(v)})
		return ok)
	s.bind_external_function("unseat", func(v):
		var ok := psyche.unseat(BUtil.js_str(v))
		if ok:
			_pending.append({"kind": "psyche", "op": "unseat", "voice": BUtil.js_str(v)})
		return ok)
	s.bind_external_function("learn", func(v): return psyche.learn(BUtil.js_str(v)))
	# what he made of a thing he's held: the voice whose read he kept ("" if he kept none)
	s.bind_external_function("kept_read", func(th): return str(reads[BUtil.js_str(th)].voice) if reads.has(BUtil.js_str(th)) else "", true)
	s.bind_external_function("heeded", func(v): return psyche.heeded(BUtil.js_str(v)), true)
	s.bind_external_function("last_word", func(g): return _last_word(BUtil.js_str(g)), true)
	# nothing, but not safe to look ahead past: the Ink's move after a scene's last line waits for it
	s.bind_external_function("beat", func(): return true)
	s.bind_external_function("bond", func(a, b, sign):
		var sa := BUtil.js_str(a)
		var sb := BUtil.js_str(b)
		var before := psyche.get_rel(sa, sb)
		var ok := psyche.set_rel(sa, sb, sign)
		if ok and before != (-1 if BUtil.js_num(sign) < 0 else 1):
			_pending.append({"kind": "psyche", "op": "rift" if BUtil.js_num(sign) < 0 else "bond", "a": sa, "b": sb})
		return ok)
	return s


# ---------------------------------------------------------------- lifecycle

func new_game(seed_in: int = 0) -> Dictionary:
	_reset()
	errors = []
	night_seed = seed_in & BUtil.U32
	if night_seed == 0:
		night_seed = BRng.fresh_seed()
	rng = BRng.new(night_seed)
	story = _make_story()
	story.state().story_seed = night_seed % 2147483647
	var start: Array = []
	for id in voice_defs:
		if BUtil.js_truthy(voice_defs[id].get("start")):
			start.append(id)
	psyche.reset(start)
	return next()


func serialize() -> Dictionary:
	var meta = content.get("meta", {})
	return {
		"v": SAVE_VERSION,
		"game": "the-bouncer",
		"build": str(meta.get("build", "")) if meta is Dictionary and BUtil.js_truthy(meta.get("build")) else "",
		"savedAt": Time.get_datetime_string_from_system(true) + "Z",
		"turn": turn,
		"seed": night_seed,
		"ink": story.state().to_json(),
		"psyche": psyche.to_json(),
		"rng": rng.get_state(),
		"barksUsed": barks_used.duplicate(),
		"wordUsed": word_used.duplicate(),
		"said": said.duplicate(true),
		"taught": taught.duplicate(),
		"handUsed": hand_used.duplicate(),
		"reads": reads.duplicate(true),
		"tasks": tasks.duplicate(true),
		"checks": check_history.slice(-40),
		"statLog": stat_log.duplicate(true),
		"screen": screen,
		"ended": ended,
		"log": pack_log(night_log),
		"path": path.duplicate(true),
		"sketch": sketch.duplicate(true),
	}


# Returns {items, choices, ended}, or {} if it isn't a save from this game.
func load_save(save_in) -> Dictionary:
	if not (save_in is Dictionary) or save_in.get("game") != "the-bouncer" or not BUtil.js_truthy(save_in.get("ink")):
		push_error("Not a save from this game")
		return {}
	var save: Dictionary = normalize_numbers(save_in)
	_reset()
	errors = []
	story = _make_story()
	story.state().load_json(str(save["ink"]))
	night_seed = BUtil.js_int(save.get("seed")) & BUtil.U32
	rng = BRng.new(night_seed)
	rng.set_state(save.get("rng"))
	psyche.from_json(save.get("psyche"))
	barks_used = (save.get("barksUsed") if save.get("barksUsed") is Array else []).duplicate()
	word_used = (save.get("wordUsed") if save.get("wordUsed") is Array else []).duplicate()
	taught = (save.get("taught") if save.get("taught") is Array else ["check", "tension", "word", "room"]).duplicate()
	hand_used = (save.get("handUsed") if save.get("handUsed") is Array else []).duplicate()
	reads = save.get("reads") if save.get("reads") is Dictionary else {}
	tasks = save.get("tasks") if save.get("tasks") is Dictionary else {}
	check_history = (save.get("checks") if save.get("checks") is Array else []).duplicate()
	stat_log = (save.get("statLog") if save.get("statLog") is Array else []).duplicate()
	turn = BUtil.js_int(save.get("turn"))
	screen = save.get("screen") if BUtil.js_truthy(save.get("screen")) else null
	ended = BUtil.js_truthy(save.get("ended"))
	night_log = []
	for it in (save.get("log") if save.get("log") is Array else []):
		if it.get("kind") != "line":
			night_log.append(it)
			continue
		var o: Dictionary = it.duplicate()
		if o.get("raw") == null:
			o["raw"] = raw_line(o)
		if BUtil.js_truthy(o.get("speaker")) and not BUtil.js_truthy(o.get("label")):
			o["label"] = _label(o["speaker"])
		if not o.has("screen"):
			o["screen"] = null
		night_log.append(o)
	said = save.get("said") if save.get("said") is Dictionary else said_from(night_log)
	path = (save.get("path") if save.get("path") is Array else []).duplicate()
	sketch = save.get("sketch") if save.get("sketch") is Dictionary else {}
	choices = _read_choices()
	return {"items": [], "choices": choices, "ended": ended}


# ---------------------------------------------------------------- reading state

func get_var(n: String):
	if story == null:
		return null
	return story.get_var(n)


func set_var(n: String, value) -> bool:
	if story == null:
		return false
	return story.set_var(n, value)


func vars() -> Dictionary:
	var out := {}
	if story == null:
		return out
	for n in story.state().variables_state.global_names():
		out[n] = ink_value(story.get_var(n))
	return out


func status() -> Dictionary:
	var h = ink_value(get_var("here"))
	var clock := BUtil.js_int(get_var("clock"))
	return {
		"clock": clock,
		"clockText": BUtil.fmt_clock(clock),
		"day": BUtil.js_int(get_var("day")),
		"cash": BUtil.js_int(get_var("cash")),
		"drinks": BUtil.js_int(get_var("drinks")),
		"hurt": BUtil.js_int(get_var("hurt")),
		"here": (str(h[0]) if not h.is_empty() and BUtil.js_truthy(h[0]) else "") if h is Array else (BUtil.js_str(h) if BUtil.js_truthy(h) else ""),
		"tension": psyche.tension(),
		"seated": psyche.seated.duplicate(),
		"stats": Checks.read_stats(_gv),
		"statsSet": BUtil.js_truthy(get_var("stats_set")),
		# the drinks that show (Checks.felt): what the print and his hands go by
		"felt": Checks.felt(get_var("drinks"), Checks.read_stats(_gv), get_var("ate")),
		# what's on him, pocket by pocket, and what he's left where (content/ink/hand.ink)
		"pockets": pockets(),
	}


# His pockets (content/ink/hand.ink): right and left outside, inside, his jeans; what he's put down
# for later, in the lost-and-found drawer behind the bar (once he's had it open) and in room twelve;
# and what's still in the last doorman's jacket (content/ink/drawer.ink).
func pockets() -> Dictionary:
	var out := {}
	for k in [["right", "in_right"], ["left", "in_left"], ["inside", "in_inside"], ["jeans", "in_jeans"], ["drawer", "in_drawer"],
			["twelve", "in_twelve"], ["jacket", "in_jacket"]]:
		var v = ink_value(get_var(k[1]))
		out[k[0]] = v.duplicate() if v is Array else []
	out["drawerSeen"] = BUtil.js_truthy(get_var("drawer_seen"))
	return out


# what goes into a check besides the dice and the voice: drink, hurt, his stats, whether he ate
func _ctx(drinks) -> Dictionary:
	return {"drinks": BUtil.js_int(drinks), "hurt": BUtil.js_int(get_var("hurt")), "stats": Checks.read_stats(_gv), "ate": BUtil.js_int(get_var("ate"))}


# In Gary's office the camera's Gary's: the voices in the doorman's head keep quiet there
func _in_office() -> bool:
	return here() == "office"


func speaker(label: String):
	return speakers.get(label)


func here() -> String:
	var h = ink_value(get_var("here"))
	if h is Array:
		return str(h[0]) if not h.is_empty() and BUtil.js_truthy(h[0]) else ""
	return BUtil.js_str(h) if BUtil.js_truthy(h) else ""


func visible_choices() -> Array:
	return _vis(choices)


# ---------------------------------------------------------------- flow

func next() -> Dictionary:
	var items: Array = []
	var events: Array = []
	var before := _watch()
	_continue(items, events)
	_after_batch(before, items, events)
	return _finish(items)


# opts.considered: the other choices the player had a hand on first (visible indexes)
func choose(visible_index: int, opts: Dictionary = {}) -> Dictionary:
	var shown := _vis(choices)
	if visible_index < 0 or visible_index >= shown.size():
		push_error("No such choice: %d" % visible_index)
		return {}
	var looked: Array = []
	for i in opts.get("considered", []):
		var k := int(i)
		if k >= 0 and k < shown.size():
			looked.append(shown[k])
	return choose_choice(shown[visible_index], looked)


func choose_choice(choice: Dictionary, looked: Array = []) -> Dictionary:
	var items: Array = []
	var events: Array = []
	var before := _watch()
	var vars_before := vars()
	var passed = _resisted(choice, looked)
	turn += 1
	# a read he keeps is his before the story goes on, so the Ink sees it (kept_read)
	if choice.get("read") != null:
		reads[str(choice.read.thing)] = {"voice": choice.read.voice, "text": choice.text, "clock": before.clock}
		psyche.heed(str(choice.read.voice))
	var chosen := {"kind": "chosen", "text": choice.text, "knot": choice.get("knot", ""), "check": {"voice": choice.check.voice} if choice.get("check") != null else null}
	if choice.get("toy") != null:
		chosen["toy"] = choice.toy.id
	if choice.get("read") != null:
		chosen["read"] = choice.read.voice
	items.append(chosen)
	if passed != null:
		items.append(passed)
	var step := {"t": turn, "c": before.clock, "x": choice.text}
	if choice.get("read") != null:
		step["r"] = choice.read.voice
	path.append(step)
	if choice.get("check") != null:
		var c: Dictionary = choice.check
		var def = voice_defs.get(c.voice, {})
		var mods := Checks.modifiers(def, _ctx(before.drinks), c.mod, str(c.get("stat", "")))
		var r := Checks.roll(rng, c.target, mods.total, psyche.tension())
		var rec := {"kind": "check", "voice": c.voice, "label": _label(c.voice), "stat": c.get("stat", ""), "statLabel": c.get("statLabel", ""), "target": c.target, "word": Checks.difficulty_word(c.target),
			"mods": mods.parts, "roll": r, "success": r.success, "turn": turn, "clock": before.clock}
		check_history.append(rec)
		if check_history.size() > 200:
			check_history.pop_front()
		step["k"] = {"v": c.voice, "n": r.total, "of": c.target, "ok": r.success}
		set_var("passed", r.success)
		set_var("crit", (1 if r.crit == "success" else -1) if r.crit != null else 0)
		items.append(rec)
		# after the first line of the outcome, so the voice answers what happened
		events.append({"at": items.size() + 1, "name": ("check_pass:" if r.success else "check_fail:") + c.voice})
	# once he's there: after the place has been described
	if BUtil.js_truthy(choice.get("loc")):
		events.append({"at": AT_END, "name": "visit:" + str(choice.loc)})
	story.choose_choice_index(choice.inkIndex)
	_continue(items, events)
	_after_batch(before, items, events)
	var changes := diff_vars(vars_before, vars())
	if not changes.is_empty():
		items.append({"kind": "diff", "turn": turn, "changes": changes})
	return _finish(items)


func jump(p: String) -> Dictionary:
	var items: Array = []
	var events: Array = []
	var before := _watch()
	story.choose_path_string(p)
	_continue(items, events)
	_after_batch(before, items, events)
	return _finish(items)


# ---------------------------------------------------------------- the hand
#
# While the player's hand is on a choice, a voice can lean in on it before it's made: whisper(i)
# says who and what, or null. murmur(what) is the voices noticing the player: hand:wait, hand:reread,
# hand:back, hand:rush. None of it touches the night's dice: it has its own random numbers.

func whisper(visible_index: int):
	var shown := _vis(choices)
	if visible_index < 0 or visible_index >= shown.size():
		return null
	var c: Dictionary = shown[visible_index]
	if c.get("hand") == null or c.hand.is_empty() or _in_office():
		return null
	var key := "c%d:%s" % [c.inkIndex, c.text]
	if _hand.has(key):
		return _hand[key]
	var r := _hand_rng(key)
	var out = null
	for kind in c.hand:
		var rule = barks.best("hand:" + kind, _gv, psyche, hand_used, r)
		if rule != null:
			out = _hand_line(rule, kind)
			break
	_hand[key] = out
	return out


func murmur(what: String):
	if _in_office():
		return null
	var rule = barks.best("hand:" + what, _gv, psyche, hand_used, _hand_rng("m:" + what))
	return _hand_line(rule, what) if rule != null else null


# whether a voice in the room has something to say about this choice (without saying it)
func leans(c: Dictionary) -> bool:
	for k in c.get("hand", []):
		if not barks.candidates("hand:" + k, _gv, psyche, hand_used).is_empty():
			return true
	return false


func _hand_rng(key: String) -> BRng:
	var h := BUtil.hash32("%d:%d:%d:%s" % [night_seed, turn, hand_used.size(), key])
	return BRng.new(h if h != 0 else 1)


func _hand_line(rule: Dictionary, kind: String) -> Dictionary:
	if rule.once:
		hand_used.append(rule.id)
	return {"id": rule.id, "kind": kind, "speaker": rule.speaker, "label": _label(rule.speaker), "text": rule.text}


# The player had a hand on something he's tempted by and chose something else: a voice may say so.
func _resisted(choice: Dictionary, looked: Array):
	var mine: Array = choice.get("tempt", [])
	var kinds: Array = []
	for c in looked:
		if is_same(c, choice):
			continue
		for k in c.get("tempt", []):
			if not mine.has(k) and not kinds.has(k):
				kinds.append(k)
	var r := _hand_rng("resisted")
	for k in kinds:
		var rule = barks.best("hand:resisted:" + k, _gv, psyche, hand_used, r)
		if rule == null:
			continue
		if rule.once:
			hand_used.append(rule.id)
		var item := _bark_item(rule)
		item["hand"] = k
		return item
	return null


# ---------------------------------------------------------------- toys
#
# Things the player can handle between choices (content/ink/toys.ink): a card at the door, the
# kid's phone, the binder under the till. If a choice on offer is tagged for it, that choice
# is made; if not, the Ink's toy_<id>(what) runs, if there is one. Either way a voice may answer.
# Returns {items, choices, ended, chose}, or {} when nothing can happen.

func toy(id: String, what: String = "") -> Dictionary:
	if story == null or ended:
		return {}
	var via = toy_choice(id, what)
	if via != null:
		var res := choose_choice(via, [])
		res["chose"] = true
		return res
	var items: Array = []
	var fn := "toy_" + id
	var ran := false
	if story.has_function(fn):
		ran = true
		var out = story.evaluate_function(fn, [what], true)
		var text: String = out.get("output", "") if out is Dictionary and out.get("output") is String else ""
		for line in text.split("\n"):
			if BUtil.js_trim(line) != "":
				_line(line, [], items, [], fn, "")
	# a voice on this thing, or on any thing of its kind (toy:card:tilt)
	var kind = props[id].get("kind") if props.get(id) is Dictionary else null
	var rule = barks.best("toy:%s:%s" % [id, what], _gv, psyche, barks_used, _toy_rng(id + ":" + what))
	if rule == null and BUtil.js_truthy(kind):
		rule = barks.best("toy:%s:%s" % [kind, what], _gv, psyche, barks_used, _toy_rng(str(kind) + ":" + what))
	if rule != null:
		if rule.once:
			barks_used.append(rule.id)
		items.append(_bark_item(rule))
	if not ran and items.is_empty():
		return {}
	for it in items:
		night_log.append(it)
	if night_log.size() > LOG_CAP:
		night_log = night_log.slice(night_log.size() - LOG_CAP)
	return {"items": items, "choices": choices, "ended": ended, "chose": false}


# Something he's just overheard the room say (the Godot build's talk, content/rules/talk.yaml): a
# voice in his head can answer it, once (barks.yaml, ears:<id>). Nothing moves the night on.
func overheard(id: String) -> Dictionary:
	if story == null or ended:
		return {}
	var rule = barks.best("ears:" + id, _gv, psyche, barks_used, _toy_rng("ears:" + id))
	if rule == null:
		return {}
	if rule.once:
		barks_used.append(rule.id)
	var it := _bark_item(rule)
	night_log.append(it)
	if night_log.size() > LOG_CAP:
		night_log = night_log.slice(night_log.size() - LOG_CAP)
	return {"items": [it]}


# the choice on offer that handling this thing this way would make, if there is one
func toy_choice(id: String, what: String):
	for c in choices:
		if c.get("toy") == null or c.toy.id != id or c.toy.what != what:
			continue
		if c.get("check") != null and not psyche.is_seated(c.check.voice):
			continue
		return c
	return null


# what can be done with a thing right now that would move the night on: ["look", "swipe"]
func toy_moves(id: String) -> Array:
	var out: Array = []
	for c in choices:
		if c.get("toy") != null and c.toy.id == id and is_same(toy_choice(id, c.toy.what), c):
			out.append(c.toy.what)
	return out


func _toy_rng(key: String) -> BRng:
	var h := BUtil.hash32("%d:%d:%d:toy:%s" % [night_seed, turn, barks_used.size(), key])
	return BRng.new(h if h != 0 else 1)


# ---------------------------------------------------------------- internals

func _label(id) -> String:
	var s = speakers.get(str(id).to_upper())
	if s == null:
		return str(id).to_upper()
	var d: Dictionary = s.def
	if BUtil.js_truthy(d.get("label")):
		return str(d.label)
	if BUtil.js_truthy(d.get("name")):
		return str(d.name)
	return str(id)


func _watch() -> Dictionary:
	return {"drinks": BUtil.js_int(get_var("drinks")), "clock": BUtil.js_int(get_var("clock")), "tension": psyche.tension(),
		"statsSet": BUtil.js_truthy(get_var("stats_set")), "stats": Checks.read_stats(_gv), "here": here()}


func _continue(items: Array, events: Array) -> void:
	var guard := 0
	while story.can_continue() and guard < 5000:
		guard += 1
		var from = story.state().current_path_string()
		if from == null:
			from = ""
		var was_here := here()
		var stood := _standing()
		var text: String = story.continue_story()
		var tags: Array = story.current_tags().duplicate()
		# Where the line came from. The path before Continue can sit on a divert into another knot,
		# and the last pointer after it can have run on past the line, so keep both.
		var last := ""
		var pp = story.state().previous_pointer()
		if pp != null and not pp.is_null():
			var ppath = pp.path()
			last = ppath.text() if ppath != null else ""
		var at := items.size()
		# effects raised by external functions during this Continue
		while not _pending.is_empty():
			items.append(_pending.pop_front())
		var now_here := here()
		if now_here != was_here:
			items.append({"kind": "place", "here": now_here, "from": was_here, "clock": BUtil.js_int(get_var("clock")), "state": _plate_state()})
		_line(text, tags, items, events, from, last)
		# What people will say about what he's just done goes under the line that shows it, unless
		# the line came from somewhere else and there's more to come: then it belongs to the scene
		# before, and goes in above (the browser build explains this at length).
		var said_items := _word(stood)
		if not said_items.is_empty():
			var line = null
			for k in range(at, items.size()):
				if items[k].get("kind") == "line":
					line = items[k]
					break
			var origin := ""
			if line != null:
				origin = str(line.get("knot2")) if BUtil.js_truthy(line.get("knot2")) else (str(line.get("knot")) if BUtil.js_truthy(line.get("knot")) else "")
			var kf := BUtil.knot_of(from)
			var above: bool = story.can_continue() and line != null and origin != "" and kf != "" and origin != kf
			var i := at if above else items.size()
			for j in range(said_items.size()):
				items.insert(i + j, said_items[j])
			for ev in events:
				if ev.at > i and ev.at != AT_END:
					ev.at += said_items.size()


func _bark_item(rule: Dictionary, answer = null) -> Dictionary:
	var it := {"kind": "line", "role": "voice", "speaker": rule.speaker, "label": _label(rule.speaker), "text": rule.text,
		"raw": rule.speaker.to_upper() + ": " + BUtil.js_str(rule.text), "knot": "", "bark": rule.id, "screen": screen}
	if BUtil.js_truthy(answer):
		it["answer"] = answer
	if rule.mark != null:
		var m = _mark_of(rule.mark)
		if m != null:
			it["mark"] = m
	return it


# "pool.bigman A; pool.buddy B": the spots in a place a voice marks, each with the word it writes by
# it, and the place as it is now
func _mark_of(spec):
	var spots: Array = []
	for s in BUtil.js_str(spec).split(";"):
		s = BUtil.js_trim(s)
		var sp := s.find(" ")
		var spot := {"at": s} if sp == -1 else {"at": s.substr(0, sp), "note": BUtil.js_trim(s.substr(sp + 1))}
		if spot.at != "":
			spots.append(spot)
	if spots.is_empty():
		return null
	return {"spots": spots, "state": _plate_state(), "clock": BUtil.js_int(get_var("clock"))}


# The first time a part of the game comes up, THE MANUAL explains it, once. Only from the room.
func _teach(what: String, items: Array, at: int) -> bool:
	if taught.has(what) or _in_office():
		return false
	var rule = barks.pick("teach:" + what, _gv, psyche, barks_used, rng)
	if rule == null:
		return false
	taught.append(what)
	if rule.once:
		barks_used.append(rule.id)
	items.insert(mini(at, items.size()), _bark_item(rule))
	return true


# How the person in a portrait looks at him: warm once he stands well with their group, cold once
# he's in their bad books (characters.yaml, standing).
func _lean(portrait: String) -> String:
	for id in char_defs:
		var d: Dictionary = char_defs[id]
		if d.get("portrait") != portrait or not BUtil.js_truthy(d.get("standing")):
			continue
		var v := BUtil.js_int(get_var("rep_" + str(d.standing)))
		return "warm" if v >= 2 else ("cold" if v <= -2 else "")
	return ""


# where he stands with each group that judges him, -5 .. 5
func _standing() -> Dictionary:
	var out := {}
	for g in GROUPS:
		out[g] = BUtil.js_int(get_var("rep_" + g))
	return out


# What he's just done has landed with someone: what they'll say about him.
func _word(before: Dictionary) -> Array:
	var now := _standing()
	var out: Array = []
	for g in GROUPS:
		var d: int = now[g] - before[g]
		if d == 0:
			continue
		var way := "up" if d > 0 else "down"
		var rule = word.pick(g, way, absi(d), now[g], _gv, psyche, word_used, rng)
		out.append({"kind": "word", "group": g, "who": word.name_of(g), "way": way, "by": absi(d),
			"text": rule.text if rule != null else "", "id": rule.id if rule != null else "", "turn": turn, "screen": screen})
		if rule != null:
			word_used.append(rule.id)
			if not said.has(g):
				said[g] = {}
			said[g][way] = {"id": rule.id, "text": rule.text}
			said[g]["last"] = way
	return out


# What a group is saying about him now (the ledger asks, through last_word in the Ink).
func _last_word(g: String) -> String:
	var s = said.get(g)
	if not BUtil.js_truthy(s):
		return ""
	var rep := BUtil.js_int(get_var("rep_" + g))
	var key
	if rep > 0 and BUtil.js_truthy(s.get("up")):
		key = "up"
	elif rep < 0 and BUtil.js_truthy(s.get("down")):
		key = "down"
	else:
		key = s.get("last")
	var w = s.get(key) if key != null else null
	if not BUtil.js_truthy(w):
		return ""
	var rule = word.by_id(str(w.get("id")))
	if rule != null and BUtil.js_truthy(rule.text):
		return str(rule.text)
	return str(w.get("text")) if BUtil.js_truthy(w.get("text")) else ""


func _line(raw_text, tags: Array, items: Array, events: Array, from: String, last: String) -> void:
	var parsed: Array = []
	for t in tags:
		parsed.append(BUtil.parse_tag(t))
	var tagv := {}
	for t in parsed:
		tagv[t.key] = t.value
	for t in parsed:
		match t.key:
			"sfx", "music", "amb", "bg", "look":
				items.append({"kind": "fx", "type": t.key, "id": BUtil.js_str(t.value)})
			"portrait":
				items.append({"kind": "fx", "type": t.key, "id": BUtil.js_str(t.value), "lean": _lean(BUtil.js_str(t.value))})
			"plate":
				items.append({"kind": "place", "here": BUtil.js_str(t.value), "from": here(), "clock": BUtil.js_int(get_var("clock")), "state": _plate_state(), "view": true})
			"screen":
				screen = null if (t.value is bool and t.value) or (t.value is String and t.value == "none") else BUtil.js_str(t.value)
				items.append({"kind": "screen", "name": screen})
			"task":
				# #task: id :: what the task says
				var s := BUtil.js_str(t.value)
				var sep := s.find("::")
				var id := BUtil.js_trim(s if sep == -1 else s.substr(0, sep))
				var text := id if sep == -1 else BUtil.js_trim(s.substr(sep + 2))
				tasks[id] = {"text": text, "done": false, "turn": turn}
				items.append({"kind": "task", "op": "add", "id": id, "text": text})
			"done":
				var id := BUtil.js_trim(BUtil.js_str(t.value))
				if BUtil.js_truthy(tasks.get(id)):
					tasks[id]["done"] = true
				else:
					tasks[id] = {"text": id, "done": true, "turn": turn}
				items.append({"kind": "task", "op": "done", "id": id, "text": tasks[id].text})

	var text := BUtil.js_trim_end(BUtil.js_str(raw_text) if BUtil.js_truthy(raw_text) else "")
	if BUtil.js_trim(text) != "":
		var t := BUtil.js_trim(text)
		var item := {"kind": "line", "role": "narration", "text": t, "raw": t, "screen": screen}
		var m := _speaker_re.search(t)
		if m != null:
			var label := m.get_string(1)
			if label == "NARRATOR":
				item["role"] = "teller"
				item["text"] = m.get_string(2)
			else:
				var sp = speakers.get(label)
				if sp != null:
					item["speaker"] = sp.id
					var d: Dictionary = sp.def
					item["label"] = str(d.label) if BUtil.js_truthy(d.get("label")) else (str(d.name) if BUtil.js_truthy(d.get("name")) else str(sp.id))
					item["role"] = "voice" if sp.kind == "voice" else "dialogue"
					item["text"] = m.get_string(2)
					if BUtil.js_truthy(d.get("whose")):
						item["whose"] = str(d.whose)
					if sp.kind == "voice" and not BUtil.js_truthy(d.get("whose")) and not psyche.is_seated(sp.id) and not BUtil.js_truthy(tagv.get("always")):
						suppressed += 1
						item["suppressed"] = true
		var kf := BUtil.knot_of(from)
		item["knot"] = kf if kf != "" else BUtil.knot_of(last)
		var k2 := BUtil.knot_of(last)
		if k2 != "" and k2 != item.knot:
			item["knot2"] = k2
		if from != "":
			item["at"] = from
		if BUtil.js_truthy(tagv.get("prompt")):
			item["prompt"] = BUtil.js_str(tagv.prompt)
		if BUtil.js_truthy(tagv.get("mark")):
			var mk = _mark_of(tagv.mark)
			if mk != null:
				item["mark"] = mk
		if BUtil.js_truthy(tagv.get("prop")):
			# #prop: hoodie_phone, or #prop: hoodie_phone held (how it's shown this time)
			var pw := BUtil.split_ws(BUtil.js_trim(BUtil.js_str(tagv.prop)))
			item["prop"] = pw[0]
			if pw.size() > 1 and pw[1] != "":
				item["propHow"] = pw[1]
			item["propAt"] = {"turn": turn, "clock": BUtil.js_int(get_var("clock"))}
		if BUtil.js_truthy(tagv.get("class")):
			item["cls"] = BUtil.js_str(tagv["class"])
		if not item.get("suppressed", false):
			items.append(item)

	if BUtil.js_truthy(tagv.get("bark")):
		events.append({"at": items.size(), "name": BUtil.js_str(tagv.bark)})
	if BUtil.js_truthy(tagv.get("stats")):
		items.append({"kind": "stats", "stats": Checks.read_stats(_gv), "turn": turn})
	if BUtil.js_truthy(tagv.get("pause")):
		items.append({"kind": "pause"})


func _after_batch(before: Dictionary, items: Array, events: Array) -> void:
	var after := _watch()
	if after.drinks > before.drinks:
		events.append({"at": items.size(), "name": "drink"})
	if floori(after.clock / 60.0) > floori(before.clock / 60.0):
		events.append({"at": items.size(), "name": "hour"})
	if after.tension != before.tension:
		events.append({"at": items.size(), "name": "tension_up" if after.tension > before.tension else "tension_down"})
	# the first time the room in his head changes, and the first time someone's word on him comes up,
	# THE MANUAL explains (it goes in ahead of the other voices)
	# A batch can run on out of Gary's office into the street (office.ink into walk.ink): what came
	# before the place changed was still Gary's telling, with none of the doorman's voices in it.
	var office_to := -1
	if before.here == "office":
		office_to = items.size()
		for i in items.size():
			if items[i].get("kind") == "place" and str(items[i].get("here")) != "office":
				office_to = i
				break
	if after.tension != before.tension:
		_teach("tension", items, items.size())
	if not taught.has("word"):
		for i in range(items.size() - 1, -1, -1):
			if items[i].get("kind") != "word" or not BUtil.js_truthy(items[i].get("text")):
				continue
			if i >= office_to and _teach("word", items, i + 1):
				for ev in events:
					if ev.at > i + 1 and ev.at != AT_END:
						ev.at += 1
			break

	# His stats moving, once the interview's set them: each change is kept, and shown where it happened.
	if before.statsSet and after.statsSet:
		for k in Checks.STAT_ORDER:
			if after.stats[k] == before.stats[k]:
				continue
			var ch := {"stat": k, "from": before.stats[k], "to": after.stats[k], "clock": after.clock, "turn": turn}
			stat_log.append(ch)
			var it := {"kind": "stat", "label": Checks.STATS[k].label}
			it.merge(ch)
			items.append(it)

	# Barks: at most one per event, inserted where the event happened (last first, so indexes hold).
	# After each, another voice in the room may answer it. None in Gary's office.
	var picked: Array = []
	var used_this_batch := {}
	if _in_office():
		events.clear()
	for k in range(events.size() - 1, -1, -1):
		if int(events[k].at) <= office_to:
			events.remove_at(k)
	for ev in events:
		var rule = barks.pick(ev.name, _gv, psyche, barks_used, rng)
		if rule == null or used_this_batch.has(rule.speaker):
			continue
		used_this_batch[rule.speaker] = true
		if rule.once:
			barks_used.append(rule.id)
		var said_items: Array = [_bark_item(rule)]
		var reply = barks.pick("answer:" + rule.speaker, _gv, psyche, barks_used, rng, rule.speaker)
		if reply != null and not used_this_batch.has(reply.speaker):
			used_this_batch[reply.speaker] = true
			if reply.once:
				barks_used.append(reply.id)
			said_items.append(_bark_item(reply, rule.speaker))
		picked.append({"at": mini(ev.at, items.size()), "said": said_items})
	BUtil.stable_sort(picked, func(a, b): return a.at > b.at)
	for p in picked:
		for j in range(p.said.size()):
			items.insert(p.at + j, p.said[j])
	psyche.record(after.clock)


func _read_choices() -> Array:
	var out: Array = []
	var list: Array = story.current_choices()
	var h := here()
	_hand = {}
	for c in list:
		var tv := {}
		for tg in (c.tags if c.tags != null else []):
			var t := BUtil.parse_tag(tg)
			tv[t.key] = t.value
		var ch := {"inkIndex": c.index, "text": BUtil.js_trim(c.text_value), "knot": BUtil.knot_of(c.source_path),
			"loc": BUtil.js_str(tv.loc) if BUtil.js_truthy(tv.get("loc")) else null,
			"cls": BUtil.js_str(tv["class"]) if BUtil.js_truthy(tv.get("class")) else null,
			"check": null, "hidden": false}
		# "#toy: hoodie_phone swipe": handling that thing that way makes this choice; #unlisted keeps it
		# out of the list, so handling it is the only way
		if BUtil.js_truthy(tv.get("toy")) and not (tv.toy is bool):
			var tw := BUtil.split_ws(BUtil.js_trim(BUtil.js_str(tv.toy)))
			ch["toy"] = {"id": tw[0], "what": tw[1] if tw.size() > 1 else ""}
			if BUtil.js_truthy(tv.get("unlisted")):
				ch["unlisted"] = true
				ch["hidden"] = true
		if BUtil.js_truthy(tv.get("check")):
			var spec = Checks.parse_spec(tv.check)
			if spec != null:
				var def = voice_defs.get(spec.voice, {})
				var stat := Checks.stat_of(def, spec.stat)
				var mods := Checks.modifiers(def, _ctx(get_var("drinks")), spec.mod, stat)
				var p := Checks.odds(spec.target, mods.total, psyche.tension())
				ch["check"] = {"voice": spec.voice, "label": _label(spec.voice), "stat": stat, "statLabel": Checks.STATS[stat].label if stat != "" else "", "target": spec.target, "mod": spec.mod,
					"word": Checks.difficulty_word(spec.target), "odds": p, "oddsWord": Checks.odds_word(p), "mods": mods.parts}
				if not psyche.is_seated(spec.voice):
					ch["hidden"] = true
		# "#read: father truck_keys": a voice's read of the thing in his hand. Only the seated speak.
		if BUtil.js_truthy(tv.get("read")) and not (tv.read is bool):
			var rw := BUtil.split_ws(BUtil.js_trim(BUtil.js_str(tv.read)))
			ch["read"] = {"voice": rw[0].to_lower(), "thing": rw[1] if rw.size() > 1 else ""}
			if not psyche.is_seated(ch.read.voice):
				ch["hidden"] = true
		# "#room: -fighter +table": who this choice lets in or puts out of his head
		if BUtil.js_truthy(tv.get("room")):
			var nxt: Array = psyche.seated.duplicate()
			for op in BUtil.split_ws(BUtil.js_str(tv.room)):
				var v := op.substr(1).to_lower()
				if op.begins_with("+") and v != "" and not nxt.has(v):
					nxt.append(v)
				if op.begins_with("-"):
					var at := nxt.find(v)
					if at != -1:
						nxt.remove_at(at)
			var room := {"seated": nxt, "now": psyche.tension(), "full": nxt.size() > Psyche.MAX_SEATS}
			room["tension"] = null if room.full else psyche.tension(nxt)
			ch["room"] = room
		# what the voices can lean in on while the player's hand is on it, most particular first
		var tempt: Array = []
		if BUtil.js_truthy(tv.get("hand")):
			for w in BUtil.split_ws(BUtil.js_str(tv.hand)):
				if w != "":
					tempt.append(w)
		ch["tempt"] = tempt
		var hand: Array = tempt.duplicate()
		if ch.check != null:
			hand.append("check:" + ch.check.voice)
		if BUtil.js_truthy(tv.get("room")):
			for op in BUtil.split_ws(BUtil.js_str(tv.room)):
				if op.length() > 1 and (op.begins_with("+") or op.begins_with("-")):
					hand.append(("room_in:" if op.begins_with("+") else "room_out:") + op.substr(1).to_lower())
		if ch.loc != null and h == "door" and ch.loc != "door":
			hand.append("leave_door")
		if ch.loc != null and ch.loc != h:
			hand.append("loc:" + ch.loc)
		# a read is a voice already: nobody leans in on it
		ch["hand"] = [] if ch.has("read") else hand
		out.append(ch)
	return out


# What the place he's walked into shows: how full the room is, table 28's rounds, the pool
# table's heat, the rats, which doors are propped.
func _plate_state() -> Dictionary:
	return {
		"n": BUtil.js_int(get_var("room_count")), "rounds": BUtil.js_int(get_var("t28_rounds")),
		"heat": BUtil.js_int(get_var("pool_heat")), "rats": BUtil.js_int(get_var("rat_count")),
		"deck": BUtil.js_truthy(get_var("deck_door")), "kitchen": BUtil.js_truthy(get_var("kitchen_door")),
		"hotel": BUtil.js_truthy(get_var("hotel_door")), "walter": BUtil.js_int(get_var("walter")),
		"clock": BUtil.js_int(get_var("clock")), "keys": BUtil.js_truthy(get_var("took_keys")),
	}


# What he can see from where he is goes into the sketch, with the time he saw it. Anywhere in the
# bar he sees the whole room; the doors he sees only when he's at them.
func _see() -> void:
	var h := here()
	var c := BUtil.js_int(get_var("clock"))
	if ROOM.has(h):
		sketch["room"] = c
		sketch["pool"] = {"heat": BUtil.js_int(get_var("pool_heat")), "at": c}
		sketch["t28"] = {"rounds": BUtil.js_int(get_var("t28_rounds")), "at": c}
	if h == "door":
		sketch["door"] = c
	if h == "deck":
		sketch["deck"] = {"open": BUtil.js_truthy(get_var("deck_door")), "at": c}
	if h == "kitchen":
		sketch["kitchen"] = {"open": BUtil.js_truthy(get_var("kitchen_door")), "at": c}
	if h == "hall":
		sketch["hotel"] = {"open": BUtil.js_truthy(get_var("hotel_door")), "at": c}
	var lc := BUtil.js_int(get_var("last_count"))
	if lc != 0 and (not BUtil.js_truthy(sketch.get("count")) or sketch.count.get("at") != lc):
		sketch["count"] = {"n": BUtil.js_int(get_var("room_count")), "at": lc}


func _finish(items: Array) -> Dictionary:
	_see()
	choices = _read_choices()
	var shown := _vis(choices)
	var any_check := false
	var any_room := false
	for c in shown:
		if c.check != null:
			any_check = true
		if c.get("room") != null:
			any_room = true
	if any_check:
		_teach("check", items, items.size())
	if any_room:
		_teach("room", items, items.size())
	# how to put a hand on a choice: once the checks have been explained, the first time a voice has
	# something to say about one, and not in the same breath as another explanation
	if not taught.has("hand") and taught.has("check") and turn >= 3:
		var teaching := false
		for it in items:
			if BUtil.js_truthy(it.get("bark")) and str(it.bark).begins_with("teach_"):
				teaching = true
				break
		if not teaching:
			var any_leans := false
			for c in shown:
				if leans(c):
					any_leans = true
					break
			if any_leans:
				_teach("hand", items, items.size())
	var over: bool = not story.can_continue() and choices.is_empty()
	if over:
		ended = true
	for it in items:
		if (it.get("kind") == "fx" and it.get("type") != "portrait") or it.get("kind") == "pause":
			continue
		night_log.append(it)
	if night_log.size() > LOG_CAP:
		night_log = night_log.slice(night_log.size() - LOG_CAP)
	return {"items": items, "choices": choices, "ended": ended}
