# The truck's radio: the '78's push-button AM, tuned by hand (game/truck.gd keeps one). Like the
# engine, it's made as it plays, no samples, at a radio's own bandwidth: one AudioStreamGenerator at
# 11 025 Hz, which is about what an AM set ever gave anybody.
#
#   between the stations   the static: a rush, crackle, the plugs ticking in it at the engine's
#                          speed and the alternator's whine under the dash. A station near the
#                          pointer pulls the static down; just off it, it's muffled and whistles.
#   the voices             nobody's recorded: a buzz at a speaking pitch through moving formants, so
#                          what comes out of the speaker is the shape of talk. The words are read off
#                          the screen, and only as much of them as the signal lets through.
#   the music              written as it plays: a country waltz, a hymn on an organ, a ballad from
#                          a long way off, a slow anthem.
#
# The stations (the five buttons were set by somebody, before):
#    690  the Dominion Service   the overnight news, the marine forecast, the emergency signal's test
#    870  WBQX, Battle Creek     two thousand miles off, in and out on the skywave: the Swap Shop
#   1060  the Prayer Tower       Brother Cal, across the water, and the organ
#   1240  CKTD                   the island's own: Reg on the night desk, the records, the town's news,
#                                which is partly about him, and callers who saw his truck tonight
#   1470  -                      a carrier and nothing on it. Mostly.
class_name TruckRadio
extends Node

const RATE := 11025.0
const LO := 540.0
const HI := 1600.0
const WIDTH := 5.0                    # kHz off a station where it's still there through the set
const PRESETS := [690.0, 870.0, 1060.0, 1240.0, 1470.0]
const PLACES := [[420.0, "the motel"], [1520.0, "the fish plant"], [2140.0, "the mill road"], [2380.0, "the washout"],
	[-520.0, "the church"], [-900.0, "the fruit stand"], [-1620.0, "the ferry sign"], [-1860.0, "the bridge"], [0.0, "the Sovereign"]]
# who talks, and how: a speaking pitch, the formants' scale (the size of the head), syllables a second
const SPK := {
	"reg": {"f0": 98.0, "fs": 0.95, "rate": 4.2, "name": "Reg"},
	"ann": {"f0": 188.0, "fs": 1.14, "rate": 4.0, "name": "Ann Talbot"},
	"cal": {"f0": 112.0, "fs": 1.0, "rate": 3.5, "name": "Brother Cal", "swell": 1.0},
	"host": {"f0": 126.0, "fs": 1.02, "rate": 4.8, "name": "the host"},
	"caller": {"f0": 102.0, "fs": 0.9, "rate": 3.1, "name": "a caller"},
	"caller2": {"f0": 172.0, "fs": 1.1, "rate": 4.4, "name": "a caller"},
	"it": {"f0": 68.0, "fs": 0.84, "rate": 2.2, "name": ""},
}
# the vowels' first two formants (Hz)
const VOWELS := [[730.0, 1090.0], [530.0, 1840.0], [270.0, 2290.0], [570.0, 840.0], [300.0, 870.0], [500.0, 1500.0], [660.0, 1720.0]]

var player: AudioStreamPlayer
var gen: AudioStreamGeneratorPlayback
var on := false
var dial := 1238.0                    # kHz: where the pointer is (somebody left it just off the island's station)
var volume := 1.0                     # game/truck.gd: quieter heard from out of the cab
var muffle := 0.0                     # 0 in the cab, 1 through the door from outside
var rpm := 0.0                        # the engine, for the plugs and the alternator in the static
var interfere := 0.0                  # something on the road pulls every station under (game/truck_odd.gd)
var bleed := ""                       # and says this through all of them while it does
var drive := {}                       # what the truck knows of tonight's drive: odo, where, out
var caption := ""                     # what can be made out now, for the screen
var caption_from := ""
var stations: Array = []
var news: Array = []                  # the town's news, some of it about him (from the night's story)
var his_words: Array = []             # things he said tonight (the night's path), for whoever's listening
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _want := -1.0                     # a button pushed: where the pointer's going
var _clunk := 0.0
var _power := 0.0                     # comes up, goes down: no tubes in a '78, but a moment
var _pending: Array = []              # callers about his truck: [when, lines]
var _said := {}                       # which of those have gone out this drive
var _n := [0.0, 0.0, 0.0]
var _crack := 0.0
var _spark := 0.0
var _whine := 0.0
var _whistle := 0.0
var _hp := [0.0, 0.0]
var _lp := [0.0, 0.0]
var _spk := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _bleed_v := {}
var _bleed_t := 0.0


func _ready() -> void:
	_rng.randomize()
	player = AudioStreamPlayer.new()
	var st := AudioStreamGenerator.new()
	st.mix_rate = RATE
	st.buffer_length = 0.15
	player.stream = st
	player.bus = "Master"
	add_child(player)
	_bleed_v = _voice_state("it")
	_coef(_spk, 1500.0, 1.2)
	_make_stations()


func start() -> void:
	player.play()
	gen = player.get_stream_playback()


func stop() -> void:
	player.stop()
	gen = null


func _process(dt: float) -> void:
	if _want >= 0.0:
		dial = move_toward(dial, _want, dt * 1400.0)
		if is_equal_approx(dial, _want):
			_want = -1.0
			_clunk = 1.0
	if gen == null:
		return
	var n := gen.get_frames_available()
	if n > 0:
		gen.push_buffer(fill(n))


# ---------------------------------------------------------------- his hands on it

func toggle() -> void:
	on = not on
	_clunk = 0.6


func tune(khz: float) -> void:
	_want = -1.0
	dial = clampf(dial + khz, LO, HI)


func preset(i: int) -> void:
	if i < 0 or i >= PRESETS.size():
		return
	if not on:
		on = true
	_want = PRESETS[i]
	_clunk = 0.8


# the station nearest the pointer, and how well it's in (0..1)
func nearest() -> Array:
	var best = null
	var bs := 0.0
	for st in stations:
		var s := _strength(st)
		if s > bs:
			bs = s
			best = st
	return [best, bs]


# where he is on the road, said the way the island says it
static func place_name(d: float) -> String:
	var best := ""
	var bd := INF
	var bp := 0.0
	for p in PLACES:
		var dd := absf(d - float(p[0]))
		if dd < bd:
			bd = dd
			best = p[1]
			bp = p[0]
	if bd < 60.0:
		return "At " + best
	return ("North of " if d > bp else "South of ") + best


# The night so far, from the story's variables: what made it onto the island's radio. Public things
# only, the kind a bartender tells a DJ; nothing he did with nobody watching.
static func news_from(v: Dictionary) -> Array:
	var out: Array = []
	var g := func(k: String, none := 0) -> int:
		var x = v.get(k, none)
		if x is bool:
			return 1 if x else 0
		if x is int or x is float:
			return int(x)
		return 0
	if g.call("ogre_done") == 2:
		out.append("Word from the Sovereign: the new man on the door put a fella off the deck the other night, and the fella's jaw with him. He's on soup. The deck's fine.")
	elif g.call("ogre_done") == 1:
		out.append("Word from the Sovereign: the new man on the door put a fella off the deck the other night. The fella's fine. His pride's listed in serious condition.")
	if g.call("ring_name") > 0:
		out.append("Somebody's been fighting behind the fish plant again, money changing hands. We don't report on that, so I won't tell you the new fella's won %d." % g.call("ring_name"))
	if g.call("esso_answered") == 1:
		out.append("The payphone at the gas station rang the other night and somebody picked it up. Phone company says that line's been dead since nineteen eighty-six. So. Who was it?")
	elif g.call("esso_answered") == -1:
		out.append("The payphone at the gas station's been ringing at night. Nobody picks up. Can't say I blame them.")
	if g.call("fire_how") == 2:
		out.append("Somebody kicked sand over the fire on the beach. The people sitting round it would like a word.")
	if g.call("smokes") > 1:
		out.append("The night window at the gas station says they're out of the reds. Mostly to one big fella, they say.")
	if g.call("count_in") >= 20:
		out.append("Busy one at the Sov: %d through the front door, they're saying, and a few through the back the new man never saw." % g.call("count_in"))
	if g.call("walter", 1) == 0:
		out.append("Table twenty-eight at the Sovereign is in mourning tonight. We'll leave it at that.")
	elif g.call("poison") > 0:
		out.append("Health inspector's due at the Sovereign. They've got rats. Everybody's got rats. The Sov's got rats with names.")
	if g.call("police_called") > 0:
		out.append("The Mounties were out to the Sov after a scuffle. Forty minutes, as usual. It was over in four.")
	if g.call("slip") > 0:
		out.append("Somebody went down on the wet tiles inside the door at the Sov. Put a sign out, Gary.")
	if g.call("lost_line") > 2:
		out.append("The Legion says thank you to the line outside the Sovereign. They did very well out of it.")
	if g.call("suit_how") == -1:
		out.append("A man in a wedding suit was turned away from the Sovereign the other night. If it was your wedding, congratulations anyway.")
	if g.call("caps_how") == 3:
		out.append("Somebody kicked apart the bottle caps out back of the Sov, the spiral. Kids made that, they say. Or something did.")
	if g.call("hurt") >= 2:
		out.append("And the new doorman at the Sov was seen at the gas station with a bag of ice on his face. Get well, big fella.")
	if g.call("jaw") > 0:
		out.append("Somebody's walking round town with a jaw that clicks. You know who you are. Chew on the other side.")
	return out


# something he did in the truck tonight that somebody saw, and phoned in (game/truck.gd)
func saw(what: String) -> void:
	if _said.has(what):
		return
	var lines: Array = []
	match what:
		"hit":
			lines = [["reg", "Got a call. Green pickup put something in the ditch out on the highway, and kept going. Caller says that's how it goes out here."], ["reg", "Caller's not wrong."]]
		"bail":
			lines = [["reg", "Caller says there's a truck rolling down the highway with its door open and nobody in it."], ["reg", "Probably nothing. Probably somebody's."]]
		"fast":
			lines = [["reg", "Somebody's doing a hundred and forty past the motel in an old Ford. The night girl at the motel says it rattled her ashtray off the desk."], ["reg", "Slow down. There's deer."]]
		"horn":
			lines = [["reg", "We've had three calls about a horn out on the highway. If that's you, we hear you."], ["reg", "Everybody hears you."]]
		"dark":
			lines = [["reg", "There's a truck out there driving with no lights on. Don't be that truck."]]
		"out":
			lines = [["reg", "Fella just phoned from the motel. Says there's a man standing out on the highway next to a green Ford, in the rain, looking at nothing."], ["reg", "Go home, friend."]]
		_:
			return
	_said[what] = true
	_pending.append([_t + _rng.randf_range(35.0, 70.0), lines])


func begin(story_vars: Dictionary, path: Array) -> void:
	news = news_from(story_vars)
	his_words.clear()
	for p in path:
		var x := str((p as Dictionary).get("x", "")) if p is Dictionary else str(p)
		x = _clean(x)
		if x.length() > 3 and x.length() < 90:
			his_words.append(x)
	_said.clear()
	_pending.clear()
	for st in stations:
		(st.queue as Array).clear()


static func _clean(x: String) -> String:
	var re := RegEx.new()
	re.compile("\\[[^\\]]*\\]|<[^>]*>|\\*")
	return re.sub(x, "", true).strip_edges()


# ---------------------------------------------------------------- the stations

func _make_stations() -> void:
	stations = [
		_station(690.0, "690", "the Dominion Service", 0.85, "dominion"),
		_station(870.0, "870 WBQX", "Battle Creek", 0.6, "swap"),
		_station(1060.0, "1060", "the Prayer Tower", 0.7, "tower"),
		_station(1240.0, "1240 CKTD", "the night desk", 1.0, "local"),
		_station(1470.0, "1470", "", 0.75, "it"),
	]
	for st in stations:
		# the program's been going all night: start each somewhere in it
		st.t = _rng.randf_range(0.0, 40.0)
		_next(st)
		st.seg_t = _rng.randf_range(0.0, float(st.seg.dur) * 0.6)


func _station(f: float, call: String, name: String, power: float, kind: String) -> Dictionary:
	return {"f": f, "call": call, "name": name, "power": power, "kind": kind, "t": 0.0, "seg": {}, "seg_t": 0.0,
		"queue": [], "i": _rng.randi_range(0, 30), "lp": 0.0, "voice": _voice_state("reg"), "music": {}, "who": "",
		"line": -1, "beat": 0.0}


func _strength(st: Dictionary) -> float:
	var d := absf(dial - float(st.f))
	if d > WIDTH * 2.2:
		return 0.0
	var s := exp(-pow(d / WIDTH, 2.0) * 1.6)
	return s * _power_now(st)


func _power_now(st: Dictionary) -> float:
	var p: float = st.power
	if st.kind == "swap":
		# the skywave: two thousand miles of night, in and out
		p *= 0.25 + 0.75 * clampf(0.5 + 0.5 * sin(_t * 0.11 + 0.6) * sin(_t * 0.043 + 2.0) + 0.25 * sin(_t * 0.37), 0.0, 1.0)
	return p


func _talk(lines: Array) -> Dictionary:
	var out: Array = []
	var t := 0.6
	for l in lines:
		var text: String = l[1]
		var d := 0.9 + text.length() * 0.058 / (float(SPK[l[0]].rate) / 4.2)
		out.append([l[0], text, t, d])
		t += d + 0.55
	return {"kind": "talk", "lines": out, "dur": t + 0.4}


func _song(style: String, dur: float) -> Dictionary:
	return {"kind": "song", "style": style, "seed": _rng.randi(), "dur": dur}


func _pick(a: Array, st: Dictionary):
	st.i = int(st.i) + 1
	return a[int(st.i) % a.size()]


# the next thing on a station: what's queued, or what the program does next
func _next(st: Dictionary) -> void:
	if not (st.queue as Array).is_empty():
		st.seg = (st.queue as Array).pop_front()
	else:
		match st.kind:
			"local":
				_local(st)
			"dominion":
				_dominion(st)
			"tower":
				_tower(st)
			"swap":
				_swap(st)
			"it":
				_it(st)
	st.seg_t = 0.0
	st.line = -1
	if st.seg.kind == "song":
		st.music = _music_state(st.seg)


const RECORDS := [["Wanda Pruitt", "Kitchen Light"], ["the Hollis Brothers", "Long Haul to Nowhere You'd Know"],
	["Billie Rae Dunn", "Second Wife"], ["Dutch Carver", "The Mill Whistle Don't Blow No More"], ["Lorna Vale", "I Kept Your Coat"],
	["Tommy Gage and the Low Tide", "Ferry's Late Again"], ["Cora Sweet", "Drinking With the Lights Off"], ["Earl Ambrose", "Jade"]]
const REG := ["They're all about a woman who left, or a dog, or a truck. Sometimes all three, and that's a hit.",
	"Request line's open. Nobody's called since one. So I'm playing what I want.",
	"If you're up, you're up. I'm up. We're in it together, more or less.",
	"My ex-wife used to sing that one in the car. Badly. I miss it badly.",
	"Coffee's gone cold. That's the whole update from in here.",
	"Somebody left a box of records on the station step, with a note: for the night man. This is out of the box. I'll keep going till one of them's good.",
	"The manager wants me to say we're the voice of the island. We're the voice of about forty people who can't sleep.",
	"Dollar closed at sixty-one cents American. My dad used to say a country's a currency with a flag on it. He drank, my dad. He wasn't wrong.",
	"Tide's coming in at the government wharf. Tide doesn't care what the dollar did.",
	"Lost dog: blue heeler, answers to Moss, last seen by the fish plant. His owner says he doesn't answer to anything. Look for a dog that looks like he's thinking.",
	"Doris called again about the light on in the old church. Nobody's had a key to that church since the diocese sold it. Thanks, Doris. Lock your door.",
	"Mill's down to one shift. If you're on the other one, I'm sorry. If you're on this one, enjoy it while it's yours.",
	"The washout past the mill road's still out. Highways says spring. Highways said spring last spring.",
	"The Island Queen's tied up at the slip till the five-forty. If you're thinking of leaving, think slower.",
	"Weather: rain. Then more of it. Small craft warning for the strait, which out here is every craft there is.",
	"If you're driving at this hour, you shouldn't be. If you're driving anyway, the shoulder past the fruit stand's soft. Keep it between the lines.",
	"Fella phoned to ask could we play something with a bit of hope in it. We're looking. Here's this in the meantime.",
	"Legion says crokinole Thursday, and the man who took the good board knows who he is.",
	"Bottle depot's paying a nickel less on cans as of Monday. I don't make the news. I read it to you.",
	"Somebody keeps leaving bread on the bench outside the post office. For the crows, I guess. The crows have started following the postman home."]
const ADS := ["Clam-a-Lot, on the wharf. If it came out of the water today, it's in the fryer tonight. If it came out yesterday, it's two dollars off.",
	"Ritchie's Towing, all night. You're going to need us. Might as well know the name.",
	"The Sovereign Hotel. Rooms by the week, the beer's cold, and there's a new man on the door, so mind yourselves.",
	"Gold Exchange, on Third. We buy gold. Rings, chains, coins, teeth. No questions. Well. One question.",
	"Island Credit Union. We're still here. Come in and see for yourself.",
	"Marv's Guns and Tackle. For the man who wants to be left alone, and the fish who wanted the same."]


func _local(st: Dictionary) -> void:
	# record, Reg, record, the news, record, Reg and an ad...
	var k := int(st.get("k", 0))
	st.k = k + 1
	if k % 2 == 0:
		st.seg = _song("waltz", _rng.randf_range(55.0, 85.0))
		st.rec = _pick(RECORDS, st)
		return
	var rec: Array = st.get("rec", RECORDS[0])
	var lines: Array = [["reg", "That was %s, \"%s\"." % [rec[0], rec[1]]]]
	match (k / 2) % 3:
		0:
			lines.append(["reg", _pick(REG, st)])
			lines.append(["reg", "Twelve-forty, CKTD, the night desk. I'm Reg."])
		1:
			lines.append(["reg", "The news, such as it is."])
			var items: Array = news.duplicate()
			items.shuffle()
			for it in items.slice(0, 2):
				lines.append(["reg", it])
			lines.append(["reg", _pick(REG, st)])
			lines.append(["reg", "That's the news. Back to the box of records."])
		2:
			lines.append(["reg", _pick(REG, st)])
			lines.append(["reg", _pick(ADS, st)])
	st.seg = _talk(lines)


const NEWS := ["The Bank of the Dominion held its rate tonight and asked Canadians to be patient. It asked last month as well.",
	"In the capital, the Senate sat through the night on the emergency measures. Senators are sleeping in shifts in the reading room.",
	"The ferry corporation says the island routes will run a reduced schedule until further notice. No further notice was given.",
	"Overseas, the war in the east goes into its eleventh winter. Our correspondent says the front has not moved. The people have.",
	"Grain shipments out of the port are down by a third. The port authority blamed the weather, then the strike, then the weather.",
	"A survey finds one Canadian in four expects to leave the country within ten years. The other three were asked where they would go. Most said they didn't know.",
	"The prime minister will address the nation on the first of the month, for thirty minutes. Some networks will carry it.",
	"The price of bread rose again in the Maritimes, where a bakery in Moncton has begun taking IOUs.",
	"Hydro says the rolling outages on the island will go on through the winter, and asks customers to keep a flashlight by the bed.",
	"The national museum has closed two wings to save on heat. The dinosaurs, a spokesman said, have been through worse."]


func _dominion(st: Dictionary) -> void:
	var k := int(st.get("k", 0))
	st.k = k + 1
	match k % 4:
		0:
			var lines: Array = [["ann", "This is the Dominion Service. The overnight news, read by Ann Talbot."]]
			for j in 3:
				lines.append(["ann", _pick(NEWS, st)])
			lines.append(["ann", "The marine forecast. The strait: winds southeast twenty-five knots, rising to gale force near midnight. Rain. Visibility one mile in rain. Seas three metres. Outlook: no change."])
			lines.append(["ann", "That is the news. The Dominion Service continues through the night with music."])
			st.seg = _talk(lines)
		1:
			st.seg = _song("anthem", _rng.randf_range(60.0, 90.0))
		2:
			if (k / 4) % 2 == 0:
				var seg := _talk([["ann", "The Dominion Service will now leave the air for a test of the emergency alert signal. This is only a test."]])
				st.queue.append({"kind": "tone", "hz": 853.0, "hz2": 960.0, "dur": 9.0})
				st.queue.append(_talk([["ann", "That was a test. Had it been an emergency, you would have been told where to go."]]))
				st.seg = seg
			else:
				st.seg = _talk([["ann", _pick(NEWS, st)], ["ann", _pick(NEWS, st)]])
		3:
			st.seg = _song("anthem", _rng.randf_range(50.0, 80.0))


const CAL := ["You know what you did. I don't, and the Lord does, and that leaves you in the middle of it, doesn't it.",
	"Somebody out there is driving right now. In the dark, with the radio on, turning the dial for a voice that'll talk to them. Well. Here I am. Keep your eyes on the road.",
	"The Book says the end comes like a thief in the night. Friend, look outside. It's night. Check your pockets.",
	"They tell you an empire falls like a tree. It doesn't. It goes like a house with the termites in. You can live in it for years. You'll hear it at night, though.",
	"Ezekiel saw a wheel in the middle of the air, and the rims of it were full of eyes, round about. Full of eyes. And what does a wheel full of eyes want with a man by a river? It wants to see him. That's all. It wants to see him.",
	"I won't tell you to stop drinking. I'll tell you to look at who's waiting at the bottom of the glass. He's been waiting a while.",
	"Every one of you has been forgiven already. That's the hard part. Now you have to live like it.",
	"The Lord hears every word you say. Every one. Did you think it went nowhere? Nothing goes nowhere."]


func _tower(st: Dictionary) -> void:
	var k := int(st.get("k", 0))
	st.k = k + 1
	match k % 3:
		0:
			var lines: Array = []
			if (k / 3) % 2 == 0:
				lines.append(["cal", "This is the Prayer Tower, forty thousand watts out of Port Hollis, Washington, and I'm Brother Cal. If you can hear me in Canada, God bless you. I'm sorry about your dollar."])
			for j in 3:
				lines.append(["cal", _pick(CAL, st)])
			st.seg = _talk(lines)
			st.seg.organ = true
		1:
			st.seg = _song("organ", _rng.randf_range(40.0, 60.0))
		2:
			var seg := _talk([["cal", _pick(CAL, st)], ["cal", "Send what you can to Box Nine, Port Hollis. A dollar. A Canadian dollar, we'll take it. God knows we'll take anything."]])
			seg.organ = true
			st.seg = seg


const SWAPS := [[["host", "WBQX, Battle Creek, it's the Swap Shop. You're on the air."], ["caller2", "Hi, yeah. I got a chest freezer. Works. Smells a little. Fifty dollars."], ["host", "Chest freezer, works, smells, fifty. Next caller."]],
	[["host", "Swap Shop, go ahead."], ["caller2", "Encyclopedias, A through R. My husband had the rest. He's got them still, wherever he is."], ["host", "A through R. Hey. That's most of it."]],
	[["host", "It's a quarter past. If you're just tuning in, we're buying, selling and swapping. No guns, no animals, no husbands."], ["host", "This hour's brought to you by Kellner's Feed and Seed, on the Beckley Road. Here's one from back when."]]]
const THE_TRUCK := [["host", "Swap Shop, you're on."], ["caller", "Yeah. I got a seventy-eight Ford. F-two-fifty, Camper Special. Green. Kind of a jade."],
	["host", "She run?"], ["caller", "She did. Fella from Canada was driving her. State police took her off him on the ninety-four and nobody ever came for her."],
	["host", "What are you asking?"], ["caller", "Parts. The four-sixty's good. Box is good. Cab's still got some of his stuff in it."],
	["host", "What kind of stuff?"], ["caller", "Little pine tree on the mirror. Tapes. A letter he never mailed. I didn't read it."], ["host", "You read it."], ["caller", "I'll call back."]]


func _swap(st: Dictionary) -> void:
	var k := int(st.get("k", 0))
	st.k = k + 1
	if k % 2 == 1:
		st.seg = _song("ballad", _rng.randf_range(45.0, 70.0))
	elif (k / 2) % 3 == 1:
		st.seg = _talk(THE_TRUCK)
	else:
		st.seg = _talk(_pick(SWAPS, st))


# 1470: the carrier, a slow beat under it, and now and then somebody reading
func _it(st: Dictionary) -> void:
	var k := int(st.get("k", 0))
	st.k = k + 1
	if k % 2 == 0:
		st.seg = {"kind": "air", "dur": _rng.randf_range(22.0, 45.0)}
		return
	var lines: Array = []
	var odo := str(int(drive.get("odo", 86402))).pad_zeros(5)
	match (k / 2) % 4:
		0:
			var digits: PackedStringArray = []
			for c in odo:
				digits.append(["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"][int(c)])
			lines.append(["it", ". ".join(digits) + "."])
		1:
			lines.append(["it", str(drive.get("where", "Here")) + "."])
		2:
			if not his_words.is_empty():
				lines.append(["it", "\"" + str(his_words[_rng.randi() % his_words.size()]) + "\""])
			else:
				lines.append(["it", "Jade."])
		3:
			lines.append(["it", "Fifty." if not bool(drive.get("out", false)) else "Door."])
	st.seg = _talk(lines)


# ---------------------------------------------------------------- the sound

func _voice_state(who: String) -> Dictionary:
	return {"who": who, "ph": 0.0, "st": 1.0, "sd": 0.2, "f1": 500.0, "f2": 1500.0, "t1": 500.0, "t2": 1500.0, "cons": false,
		"gap": false, "r1": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], "r2": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		"r3": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], "nz": 0.0, "k": 0, "prog": 0.0, "amp": 0.0}


# a band-pass's coefficients, kept in its state: [x1, x2, y1, y2, b0, a1, a2]
static func _coef(r: Array, f: float, q: float) -> void:
	var w := TAU * clampf(f, 60.0, RATE * 0.45) / RATE
	var alpha := sin(w) / (2.0 * q)
	var a0 := 1.0 + alpha
	r[4] = alpha / a0
	r[5] = 2.0 * cos(w) / a0
	r[6] = (1.0 - alpha) / a0


static func _bp(x: float, r: Array) -> float:
	var y: float = float(r[4]) * (x - float(r[1])) + float(r[5]) * float(r[2]) - float(r[6]) * float(r[3])
	r[1] = r[0]
	r[0] = x
	r[3] = r[2]
	r[2] = y
	return y


# one sample of a voice talking (speaking: 0 between the words of a line, 1 in them)
func _voice(v: Dictionary, speaking: bool) -> float:
	var sp: Dictionary = SPK[v.who]
	var rate: float = sp.rate
	v.st = float(v.st) + 1.0 / RATE
	if float(v.st) >= float(v.sd):
		v.st = 0.0
		v.sd = _rng.randf_range(0.6, 1.45) / rate
		var vw: Array = VOWELS[_rng.randi() % VOWELS.size()]
		v.t1 = float(vw[0]) * float(sp.fs)
		v.t2 = float(vw[1]) * float(sp.fs)
		v.cons = _rng.randf() < 0.72
		v.gap = _rng.randf() < 0.2
	if not speaking:
		v.amp = float(v.amp) * 0.995
	var x := float(v.st) / float(v.sd)
	# a word's gap: the last part of some syllables is nothing
	var env := 0.0
	if speaking and not (v.gap and x > 0.6):
		env = pow(sin(clampf(x, 0.0, 1.0) * PI), 0.6)
		if v.who == "it":
			env = clampf(x * 1.4, 0.0, 1.0) * (1.0 if x < 0.85 else 0.0)
	v.amp = float(v.amp) + (env - float(v.amp)) * 0.02
	# the pitch: a phrase's fall, a little lilt, a little roughness
	var f0: float = sp.f0
	if v.who != "it":
		f0 *= 1.0 + 0.1 * sin(float(v.prog) * 5.0 + float(v.k) * 0.3) - 0.12 * float(v.prog) + _rng.randf_range(-0.01, 0.01)
		if sp.has("swell"):
			f0 *= 1.0 + 0.18 * maxf(0.0, sin(_t * 0.7))
	v.ph = float(v.ph) + f0 / RATE
	if float(v.ph) >= 1.0:
		v.ph = float(v.ph) - 1.0
	var src := 1.0 - 2.0 * float(v.ph)
	# the formants glide; their filters are worked out every 32 samples
	v.f1 = float(v.f1) + (float(v.t1) - float(v.f1)) * 0.004
	v.f2 = float(v.f2) + (float(v.t2) - float(v.f2)) * 0.004
	v.k = int(v.k) + 1
	if int(v.k) % 32 == 0:
		_coef(v.r1, v.f1, 6.0)
		_coef(v.r2, v.f2, 9.0)
		_coef(v.r3, 2600.0 * float(sp.fs), 7.0)
	var out := _bp(src, v.r1) * 1.0 + _bp(src, v.r2) * 0.7 + _bp(src, v.r3) * 0.25
	# a consonant at the front of the syllable: a hiss or a stop
	if v.cons and x < 0.22 and speaking:
		v.nz = float(v.nz) + (_rng.randf_range(-1.0, 1.0) - float(v.nz)) * 0.7
		out = out * x / 0.22 + float(v.nz) * 0.35 * (1.0 - x / 0.22)
	return out * float(v.amp) * 0.9


static func _midi(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


func _music_state(seg: Dictionary) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = int(seg.seed)
	var style: String = seg.style
	var m := {"style": style, "root": float(r.randi_range(50, 57)), "bt": 0.0, "bi": 0, "notes": [], "r": r, "mel": 0.0}
	match style:
		"waltz":
			m.bpm = r.randf_range(96.0, 116.0)
			m.per = 3
			m.prog = [[0, 0], [0, 0], [5, 0], [5, 0], [7, 0], [7, 0], [0, 0], [0, 0]]
		"ballad":
			m.bpm = r.randf_range(72.0, 86.0)
			m.per = 4
			m.prog = [[0, 0], [9, 1], [5, 0], [7, 0]]
		"organ":
			m.bpm = r.randf_range(56.0, 66.0)
			m.per = 4
			m.prog = [[0, 0], [5, 0], [0, 0], [7, 0], [9, 1], [5, 0], [7, 0], [0, 0]]
		_:
			m.bpm = r.randf_range(64.0, 74.0)
			m.per = 4
			m.prog = [[0, 0], [7, 0], [9, 1], [4, 1], [5, 0], [0, 0], [2, 1], [7, 0]]
	# the tune: a phrase of chord tones, repeated, so it's a tune
	var tune: Array = []
	for i in 8:
		tune.append([0, 4, 7, 12, 7, 4, 2, 9][r.randi() % 8])
	m.tune = tune
	return m


# a note: [freq, amp, decay a sample, phase, kind (0 pluck, 1 steel, 2 organ, 3 bass), age, vibrato]
func _note(m: Dictionary, midi: float, amp: float, kind: int, secs: float) -> void:
	var notes: Array = m.notes
	if notes.size() > 12:
		notes.pop_front()
	notes.append([_midi(midi), amp, pow(0.001, 1.0 / (secs * RATE)), 0.0, kind, 0.0])


func _music(m: Dictionary) -> float:
	var beat_len := 60.0 / float(m.bpm)
	m.bt = float(m.bt) + 1.0 / RATE
	if float(m.bt) >= beat_len:
		m.bt = float(m.bt) - beat_len
		m.bi = int(m.bi) + 1
		var per: int = m.per
		var bar := int(m.bi) / per
		var beat := int(m.bi) % per
		var prog: Array = m.prog
		var ch: Array = prog[bar % prog.size()]
		var root: float = float(m.root) + float(ch[0])
		var third := 3.0 if int(ch[1]) == 1 else 4.0
		var tune: Array = m.tune
		var mel: float = float(m.root) + 12.0 + float(tune[(bar * 2 + (1 if beat > 0 else 0)) % tune.size()])
		match str(m.style):
			"waltz":
				if beat == 0:
					_note(m, root - 12.0, 0.5, 3, 0.7)
					_note(m, mel, 0.22, 1, beat_len * 2.8)
				else:
					for iv in [0.0, third, 7.0]:
						_note(m, root + iv, 0.12, 0, 0.35)
			"ballad":
				_note(m, root - 12.0 if beat % 2 == 0 else root - 5.0, 0.4, 3, 0.6)
				for iv in [0.0, third, 7.0]:
					_note(m, root + iv, 0.08, 0, 0.9)
				if beat % 2 == 0:
					_note(m, mel, 0.18, 1, beat_len * 1.8)
			_:
				if beat == 0:
					for iv in [-12.0, 0.0, third, 7.0]:
						_note(m, root + iv, 0.11, 2, beat_len * float(m.per) * 1.1)
				if beat % 2 == 0:
					_note(m, mel, 0.12, 2, beat_len * 1.9)
	var s := 0.0
	var notes: Array = m.notes
	var i := notes.size() - 1
	while i >= 0:
		var nt: Array = notes[i]
		nt[5] = float(nt[5]) + 1.0 / RATE
		var age: float = nt[5]
		var f: float = nt[0]
		var kind: int = nt[4]
		if kind == 1:
			f *= 1.0 + 0.006 * sin(age * 34.0) * clampf(age * 2.0, 0.0, 1.0)
		nt[3] = fmod(float(nt[3]) + f / RATE, 1.0)
		var ph: float = TAU * float(nt[3])
		var v := 0.0
		match kind:
			0:
				v = sin(ph) + 0.35 * sin(ph * 2.0) + 0.15 * sin(ph * 3.0)
			1:
				v = sin(ph) * clampf(age * 6.0, 0.0, 1.0)
			2:
				v = (sin(ph) + 0.5 * sin(ph * 2.0) + 0.3 * sin(ph * 4.0)) * clampf(age * 8.0, 0.0, 1.0)
			3:
				v = sin(ph) + 0.25 * sin(ph * 2.0)
		s += v * float(nt[1])
		nt[1] = float(nt[1]) * float(nt[2])
		if float(nt[1]) < 0.0008:
			notes.remove_at(i)
		i -= 1
	return s


# advance a station's program by dt and say what's on it now: [voice speaking, music on, tone hz]
func _advance(st: Dictionary, dt: float) -> void:
	st.t = float(st.t) + dt
	st.seg_t = float(st.seg_t) + dt
	# a caller about his truck: Reg cuts the record short for it
	if st.kind == "local" and not _pending.is_empty() and float(_pending[0][0]) <= _t:
		var p: Array = _pending.pop_front()
		var lines: Array = [["reg", "Cutting in on that one. Sorry, folks."]] if st.seg.kind == "song" else []
		lines.append_array(p[1])
		st.queue.push_front(_talk(lines))
		if st.seg.kind == "song":
			st.seg.dur = minf(float(st.seg.dur), float(st.seg_t) + 2.5)
	if float(st.seg_t) >= float(st.seg.dur):
		_next(st)
	st.line = -1
	if st.seg.kind == "talk":
		var lines: Array = st.seg.lines
		for li in lines.size():
			var l: Array = lines[li]
			if float(st.seg_t) >= float(l[2]) and float(st.seg_t) < float(l[2]) + float(l[3]):
				st.line = li
				var v: Dictionary = st.voice
				if v.who != l[0]:
					var nv := _voice_state(l[0])
					st.voice = nv
				(st.voice as Dictionary).prog = (float(st.seg_t) - float(l[2])) / float(l[3])
				break


# n samples of the set as it is now (tests/truck_radio.gd renders it to a file this way)
func fill(n: int) -> PackedVector2Array:
	var dt := float(n) / RATE
	_t += dt
	for st in stations:
		_advance(st, dt)
	if bleed != "":
		_bleed_t += dt
	else:
		_bleed_t = 0.0
	_power = move_toward(_power, 1.0 if on else 0.0, dt * (5.0 if on else 12.0))
	# who's in, and how well
	var heard: Array = []
	var total := 0.0
	var best_s := 0.0
	var best = null
	for st in stations:
		var s := _strength(st) * (1.0 - interfere * 0.85)
		if s > 0.004:
			heard.append([st, s])
			total += s
			if s > best_s:
				best_s = s
				best = st
	_caption(best, best_s)
	var buf := PackedVector2Array()
	buf.resize(n)
	if _power <= 0.0 and _clunk <= 0.0:
		return buf
	var stat_amt := clampf(0.08 + 0.7 * (1.0 - clampf(total, 0.0, 1.0)) + interfere * 0.6, 0.0, 1.0)
	var spark_hz := rpm / 60.0 * 4.0
	var whine_hz := rpm / 60.0 * 2.6 * 6.0
	var muf := 0.75 - 0.6 * muffle
	var vol := volume * (1.0 - 0.6 * muffle)
	for k in n:
		var x := 0.0
		for h in heard:
			var st: Dictionary = h[0]
			var s: float = h[1]
			var seg: Dictionary = st.seg
			var p := 0.0
			var kind: String = seg.kind
			if kind == "talk":
				p += _voice(st.voice, st.line >= 0)
				if seg.get("organ", false):
					if (st.music as Dictionary).is_empty() or str(st.music.get("style", "")) != "organ":
						st.music = _music_state({"seed": 7, "style": "organ"})
					p += _music(st.music) * 0.18
			elif kind == "song":
				var fade := clampf(float(st.seg_t) / 1.5, 0.0, 1.0) * clampf((float(seg.dur) - float(st.seg_t)) / 2.0, 0.0, 1.0)
				p += _music(st.music) * fade
			elif kind == "tone":
				st.beat = fmod(float(st.beat) + float(seg.hz) / RATE, 1.0)
				p += (sin(TAU * float(st.beat)) + sin(TAU * float(st.beat) * float(seg.hz2) / float(seg.hz))) * 0.22
			elif kind == "air" and st.kind == "it":
				# a slow beat under the carrier: fifty a minute, lub-dub
				var bt := fmod(_t + float(k) / RATE, 1.2)
				var lub := exp(-bt * 30.0) * sin(TAU * 150.0 * bt) + exp(-maxf(bt - 0.22, 0.0) * 34.0) * sin(TAU * 130.0 * bt) * (1.0 if bt > 0.22 else 0.0) * 0.7
				p += lub * 0.35
			# off the station: the top of it goes, so it's muffled
			var d := absf(dial - float(st.f))
			var c := lerpf(0.9, 0.1, clampf(d / (WIDTH * 0.8), 0.0, 1.0))
			st.lp = float(st.lp) + (p - float(st.lp)) * c
			x += float(st.lp) * s
			# and just off it, the whistle of it beating against the set
			if d > 0.6 and d < WIDTH * 1.4:
				_whistle = fmod(_whistle + (180.0 + d * 260.0) / RATE, 1.0)
				x += sin(TAU * _whistle) * 0.05 * s * smoothstep(0.6, 1.6, d)
		# the voice that comes through all of them
		if bleed != "":
			x = x * 0.25 + _voice(_bleed_v, fmod(_bleed_t, 3.0) < 2.4) * 0.9
		# the static: a rush, crackle, the plugs, the alternator
		var w := _rng.randf_range(-1.0, 1.0)
		_n[0] += (w - _n[0]) * 0.6
		_n[1] += (_n[0] - _n[1]) * 0.45
		var nz: float = (w - float(_n[1])) * 0.15 + float(_n[1]) * 0.8
		if _rng.randf() < 0.0012 * stat_amt:
			_crack = _rng.randf_range(0.4, 1.0) * (1.0 if _rng.randf() < 0.5 else -1.0)
		_crack *= 0.93
		var sv := nz * 0.32 + _crack * 0.5
		if spark_hz > 1.0:
			_spark += spark_hz / RATE
			if _spark >= 1.0:
				_spark -= 1.0
				sv += 0.12 * (1.0 if _rng.randf() < 0.5 else -1.0)
			_whine = fmod(_whine + whine_hz / RATE, 1.0)
			sv += sin(TAU * _whine) * 0.05
		var y := x + sv * stat_amt * 0.45
		# the set's own band: no lows, no highs, a small speaker under the dash
		_hp[0] += (y - float(_hp[0])) * 0.133
		var hp: float = y - float(_hp[0])
		_hp[1] += (hp - float(_hp[1])) * 0.133
		hp -= float(_hp[1])
		_lp[0] += (hp - float(_lp[0])) * muf
		_lp[1] += (float(_lp[0]) - float(_lp[1])) * muf
		var cone := _bp(float(_lp[1]), _spk)
		var o: float = (float(_lp[1]) + cone * 0.8) * _power * 2.2
		# the knob and the buttons: a clunk in the dash, power or not
		if _clunk > 0.0:
			o += sin(TAU * 95.0 * (1.0 - _clunk) * 0.25) * _clunk * _clunk * 0.25 + _rng.randf_range(-0.05, 0.05) * _clunk
			_clunk = maxf(0.0, _clunk - 1.0 / (RATE * 0.06))
		o = tanh(o * 1.6 * vol) * 0.6
		buf[k] = Vector2(o, o)
	return buf


# what can be read of the strongest station now: its line, with what didn't come through dropped
func _caption(st, s: float) -> void:
	caption = ""
	caption_from = ""
	if not on or _power < 0.5:
		return
	if bleed != "" and fmod(_bleed_t, 3.0) < 2.4:
		caption = bleed
		caption_from = ""
		return
	if st == null or int(st.line) < 0:
		return
	var clarity := clampf((s - 0.15) / 0.5, 0.0, 1.0)
	if clarity <= 0.05:
		return
	var l: Array = st.seg.lines[st.line]
	var words: PackedStringArray = str(l[1]).split(" ")
	var out: PackedStringArray = []
	var dropped := false
	for i in words.size():
		var h := float(hash(str(l[1]).length() * 131 + i * 7919) % 1000) / 1000.0
		if h < clarity:
			out.append(words[i])
			dropped = false
		elif not dropped:
			out.append("...")
			dropped = true
	var who: String = SPK[l[0]].name
	caption = (who + ": " if who != "" else "") + " ".join(out)
	caption_from = st.call
