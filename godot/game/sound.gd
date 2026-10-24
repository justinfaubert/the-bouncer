# The sound: the room's noise in layers, the room's own sounds from where they happen, and the small
# sounds of the job.
#
# Everything here is a placeholder made in code (tools/sounds.py), there to hold the places where
# Hutch's own recordings go. To swap one, put a file with the same name (.wav, .ogg or .mp3) in a
# folder called "audio" beside the game, or in the game's user folder; it's used instead from the
# next start. The names are the files in audio/: the small sounds (click, beep_ok, thump...), the
# room's own (glass_down, laugh, cue...) and the room's layers (amb_rain_glass, amb_talk_a...).
# godot/docs/SOUNDS.md lists every one, what it's for and where it plays.
#
# The room is mixed from its layers by where he is and what the night's doing: how many are in, the
# heat at the pool table, table 28's rounds, the rats. The Ink's #amb and #music tags lean on the
# mix (a quiet room, an empty bar, the jukebox late), they don't replace it.
#
# In the Sov each layer comes from where it is (FROM): the jukebox from the jukebox, table 28 from
# table 28, the room's talk from both halves of the room, the rain from the front glass, the fryer
# and the cook's radio from the kitchen, the hum of the tubes from the back hall, the cellar's from
# the keg room. It's louder near it and comes from its side as he turns his head, and from another
# part of the building it's lower and dulled by what's between (_through): the bar from the hall
# or the kitchen, through the deck's door (clearer while the coaster's in it), or through the
# floor, from the keg room. The rain on the roof and outside, the sea, and the room's own hum are
# all round him. The room's own sounds come from where they happen the same way (at): a glass set
# down at table 28, their laugh, a ball struck on the pool table (world/doings.gd).
class_name Sound
extends Node

# the Ink's names for things, to the files that stand in for them
const INK := {"scanner_ok": "beep_ok", "scanner_bad": "beep_bad", "door": "thump", "phone": "ring",
	"hit": "thud", "balls": "clack", "dice_shake": "rattle", "die_tick": "tick", "die_land": "tock",
	"glass": "glass", "scratch": "scratch", "till": "till", "bell": "bell"}
const LAYERS := ["rain_glass", "rain_out", "rain_roof", "room_tone", "talk_a", "talk_b", "shout", "juke",
	"fryer", "fan", "tube", "cellar", "rats", "sea", "keys", "canopy", "traffic", "radio"]
# how loud each small sound sits under the rest
const LEVEL := {"click": 0.8, "choose": 0.35, "click_ui": 0.35, "steps": 0.45, "whisper": 0.5, "page": 0.5, "pen": 0.55,
	"printer": 0.5, "heart": 0.8, "tick": 0.55, "tock": 0.8, "rattle": 0.7, "gust": 0.6, "swipe": 0.45, "card": 0.6, "lift": 0.5,
	"glass_down": 0.6, "clink": 0.5, "laugh": 0.85, "laugh_one": 0.7, "cough": 0.5, "stool": 0.55, "pour": 0.75, "wipe": 0.6,
	"flush": 0.7, "door_wc": 0.55, "slap": 0.65, "cue": 0.8, "pocket": 0.7, "break": 0.85, "lighter": 0.6, "cheer": 0.8, "groan": 0.7,
	"spill": 0.75}
# Where the Sov's layers come from: the points (more than one for the room's talk, spread over the
# room), the part of the building, and how near it has to be to be heard at full (metres; it's
# half as loud at twice that, a quarter at four times).
const FROM := {
	"juke": [[Vector3(13.2, 1.5, 0.25)], "room", 4.0],
	"talk_a": [[Vector3(4.6, 1.3, 4.6), Vector3(12.2, 1.3, 5.6)], "room", 4.0],
	"talk_b": [[Vector3(9.4, 1.15, 8.1)], "room", 2.5],
	"shout": [[Vector3(9.4, 1.5, 3.9)], "room", 3.5],
	"rain_glass": [[Vector3(3.2, 1.5, 10.05), Vector3(9.4, 1.6, 10.05)], "room", 2.0],
	"fryer": [[Vector3(0.45, 1.0, -2.19)], "kitchen", 2.0],
	"fan": [[Vector3(1.4, 2.4, -1.7)], "kitchen", 2.5],
	"radio": [[Vector3(2.55, 2.06, -2.49)], "kitchen", 1.5],
	"tube": [[Vector3(10.5, 2.4, -1.9)], "hall", 2.0],
	"cellar": [[Vector3(2.4, -1.4, -0.8)], "keg", 3.0],
	"rats": [[Vector3(2.9, -2.2, -2.4)], "keg", 1.5],
}
# the layers all round him that are still the room's, and so dulled like it from the next room
const ROOM_FLAT := ["room_tone"]
# In a room a sound fills the room as well as coming from where it is: the share of each of the
# Sov's layers that's heard all round him in the part of the building it carries to, at its level
# where it is, without its side or its distance
const DIFFUSE := 0.35
# what's between two parts of the building dulls a sound to below about this (Hz): the buses made
# for it, from a doorway to a floor
const DULL := [["Doorway", 2200.0], ["Wall", 800.0], ["Floor", 280.0]]

var settings: Dictionary
var view: View                  # where he is, so the room comes from round him
var files := {}                 # name -> [paths of its takes]
var cache := {}
var players: Array = []         # a few for the small sounds, round robin
var next_player := 0
var spots: Array = []           # and for the room's own, from where they happen
var next_spot := 0
var loops := {}                 # layer -> AudioStreamPlayer, all round him
var level := {}                 # layer -> where it is now, 0..1
var target := {}                # layer -> where it's going
var sources := {}               # layer -> [AudioStreamPlayer3D, one at each of its points]
var level_at := {}
var target_at := {}             # layer -> how loud it is where it is
var ink_amb := ""               # the last #amb
var music := "jukebox_early"    # the last #music
var room_state := {"n": 13, "heat": 0, "rounds": 0, "rats": 0, "clock": 1260, "here": "door"}
var where := "door"
var doors := {"deck": true, "kitchen": true, "hotel": true}
var unlocked := false
var _last := {}                 # name -> when it last played, so the same take isn't used twice running


func setup(s: Dictionary) -> void:
	settings = s
	_find_files()
	_buses()
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	for i in 14:
		var p := AudioStreamPlayer3D.new()
		p.max_db = 0.0
		p.max_distance = 45.0
		p.attenuation_filter_cutoff_hz = 9000.0
		add_child(p)
		spots.append(p)
	for layer in LAYERS:
		var st = _looping(_stream("amb_" + layer, 0))
		var p := AudioStreamPlayer.new()
		p.stream = st
		p.volume_db = -80.0
		add_child(p)
		loops[layer] = p
		level[layer] = 0.0
		target[layer] = 0.0
		if FROM.has(layer):
			var list: Array = []
			for at in FROM[layer][0]:
				var q := AudioStreamPlayer3D.new()
				q.stream = st
				q.position = at
				q.unit_size = float(FROM[layer][2])
				q.max_db = 0.0
				q.max_distance = 45.0
				q.attenuation_filter_cutoff_hz = 9000.0
				q.volume_db = -80.0
				add_child(q)
				list.append(q)
			sources[layer] = list
			level_at[layer] = 0.0
			target_at[layer] = 0.0
	place("door", 1260)


func _looping(st):
	if st is AudioStreamWAV:
		var w := st as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(round(w.get_length() * w.mix_rate))
	elif st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	elif st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = true
	return st


# The buses a sound from the next room goes through, each cut above its frequency.
func _buses() -> void:
	for d in DULL:
		if AudioServer.get_bus_index(d[0]) >= 0:
			continue
		var i := AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, d[0])
		AudioServer.set_bus_send(i, "Master")
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = d[1]
		lp.resonance = 0.4
		AudioServer.add_bus_effect(i, lp)


# Every sound by name, with its takes (click, click_2, click_3...): the placeholders in res://audio,
# and anything Hutch has put beside the game with the same name, which wins.
func _find_files() -> void:
	var dirs: Array = ["res://audio"]
	var beside := OS.get_executable_path().get_base_dir().path_join("audio")
	if not OS.has_feature("editor") and DirAccess.dir_exists_absolute(beside):
		dirs.append(beside)
	if DirAccess.dir_exists_absolute("user://audio"):
		dirs.append("user://audio")
	for d in dirs:
		var own := {}
		for f in DirAccess.get_files_at(d):
			var ext := f.get_extension().to_lower()
			if not ext in ["wav", "ogg", "mp3"]:
				continue
			var base := f.get_basename()
			var name := base
			var m := RegEx.create_from_string("^(.*)_(\\d+)$").search(base)
			if m != null and not base.begins_with("amb_"):
				name = m.get_string(1)
			if not own.has(name):
				own[name] = []
			own[name].append(d.path_join(f))
		for name in own:
			own[name].sort()
			files[name] = own[name]


func _stream(name: String, take: int):
	var list: Array = files.get(name, [])
	if list.is_empty():
		return null
	var path: String = list[take % list.size()]
	if cache.has(path):
		return cache[path]
	var st: AudioStream = null
	match path.get_extension().to_lower():
		"wav":
			st = AudioStreamWAV.load_from_file(path)
		"ogg":
			st = AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			st = AudioStreamMP3.load_from_file(path)
	cache[path] = st
	return st


func apply(s: Dictionary) -> void:
	settings = s


# the browser build waited for a first touch before it could make a sound; here it's just a mark
# that the night has started, so the room comes up from nothing
func unlock() -> void:
	unlocked = true


func _vol(kind: String) -> float:
	if not settings.get("sound", true):
		return 0.0
	return clampf(float(settings.get("master", 0.8)), 0.0, 1.0) * clampf(float(settings.get(kind, 0.8)), 0.0, 1.0)


# a take of a sound, not the one played last time if it has more than one
func _take(name: String):
	var list: Array = files.get(name, [])
	if list.is_empty():
		return null
	var take := randi() % list.size()
	if list.size() > 1 and _last.get(name, -1) == take:
		take = (take + 1) % list.size()
	_last[name] = take
	return _stream(name, take)


# One of the small sounds, by its own name or the Ink's.
func sfx(id: String, gain := 1.0, pitch := 1.0) -> void:
	var name: String = INK.get(id, id)
	if not files.has(name):
		return
	var v := _vol("sfx") * gain * float(LEVEL.get(name, 0.75))
	if v <= 0.001:
		return
	var st = _take(name)
	if st == null:
		return
	var p: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = st
	p.volume_db = linear_to_db(v)
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()


# One of the room's own sounds, from where it happens (a glass set down at table 28, a laugh, a ball
# struck): as loud as gain within reach metres of it, half as loud at twice that, and lower and duller
# from another part of the building.
func at(id: String, pos: Vector3, gain := 1.0, reach := 1.5, pitch := 1.0) -> void:
	var name: String = INK.get(id, id)
	if not files.has(name):
		return
	var th := _through(Hotspots.zone_of(pos), _mine())
	var v := _vol("amb") * gain * float(LEVEL.get(name, 0.75)) * th.x
	if v <= 0.002 or (view != null and pos.distance_to(view.eye_pos) > 40.0):
		return
	var st = _take(name)
	if st == null:
		return
	var p: AudioStreamPlayer3D = spots[next_spot]
	next_spot = (next_spot + 1) % spots.size()
	p.stream = st
	p.position = pos
	p.unit_size = reach
	p.volume_db = linear_to_db(v)
	p.bus = _bus(th.y)
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.play()


# ---------------------------------------------------------------- the room

# The #music tag: the jukebox (someone's card in it early, the late songs, off after hours).
func track(id: String) -> void:
	music = id
	_mix()


# The #amb tag, where it was said.
func ink_ambience(id: String, here: String) -> void:
	ink_amb = id
	if here != "":
		where = here
	_mix()


# Before the night: the rain on the door's glass and the room behind him, low.
func ambience(id: String) -> void:
	ink_amb = id
	_mix()


func room(state: Dictionary) -> void:
	room_state = state
	var d = state.get("doors")
	if d is Dictionary:
		for k in d:
			doors[k] = bool(d[k])
	_mix()


func place(here: String, clock: int) -> void:
	where = here
	room_state["clock"] = clock
	_mix()


# The part of the building he's in, as far as sound goes: the vestibule is the room's, the pickup's
# out in the lot, and anywhere in town is a long way from all of it.
func _mine() -> String:
	if view != null:
		return _space(Hotspots.zone_of(view.eye_pos))
	match where:
		"door", "floor", "bar", "t28", "pool":
			return "room"
		"office", "street", "esso", "seawall":
			return "town"
	return where


static func _space(zone: String) -> String:
	match zone:
		"vest":
			return "room"
		"truck":
			return "lot"
		"office":
			return "town"
	return zone


# How much of a sound in one part of the building gets to another, and how dull it is there: x the
# share of it, y about where it's cut off (Hz; past 20000, it isn't).
func _through(src: String, mine: String) -> Vector2:
	var a := _space(src)
	var b := _space(mine)
	if a == b:
		return Vector2(1.0, 20500.0)
	if a == "town" or b == "town":
		return Vector2.ZERO
	var pair := [a, b]
	pair.sort()
	match "%s:%s" % pair:
		"hall:room":
			return Vector2(0.55, 2200.0)            # the way through to the hall is open
		"kitchen:room":
			return Vector2(0.3, 800.0)              # the swing door
		"deck:room":
			return Vector2(0.45, 2200.0) if doors.get("deck", true) else Vector2(0.18, 800.0)
		"lot:room":
			return Vector2(0.15, 800.0)             # through the front glass
		"keg:room", "keg:kitchen":
			return Vector2(0.12, 280.0)             # through the floor
		"room:upstairs":
			return Vector2(0.1, 280.0)
		"hall:kitchen":
			return Vector2(0.2, 800.0)
		"hall:lobby":
			return Vector2(0.55, 2200.0) if doors.get("hotel", true) else Vector2(0.15, 800.0)
		"lobby:room":
			return Vector2(0.3, 800.0) if doors.get("hotel", true) else Vector2(0.08, 280.0)
		"deck:lot":
			return Vector2(0.85, 20500.0)            # the deck's open to the lot
		"kitchen:lot":
			return Vector2(0.4, 2200.0) if doors.get("kitchen", true) else Vector2(0.12, 800.0)
	return Vector2(0.06, 280.0)


# the bus for a sound cut off at hz: straight out, or through a doorway, a wall, the floor
func _bus(hz: float) -> StringName:
	if hz >= 20000.0:
		return &"Master"
	for d in DULL:
		if hz >= float(d[1]) - 1.0:
			return StringName(d[0])
	return StringName(DULL[DULL.size() - 1][0])


func _mix() -> void:
	var t := {}
	var ta := {}
	for layer in LAYERS:
		t[layer] = 0.0
	for layer in FROM:
		ta[layer] = 0.0
	var n := float(room_state.get("n", 13))
	var heat := float(room_state.get("heat", 0))
	var rounds := float(room_state.get("rounds", 0))
	var rats := float(room_state.get("rats", 0))
	var clock := int(room_state.get("clock", 1260))
	# how full the room sounds, from how many are in it
	var crowd := clampf(n / 24.0, 0.0, 1.2)
	var juke := 0.55
	match music:
		"jukebox_late":
			juke = 0.7
		"keg_room":
			juke = 0.35
		"after_hours", "none":
			juke = 0.0
	if clock >= 1560:           # past last call the card runs out
		juke *= 0.4
	var talk := 1.0
	match ink_amb:
		"room_quiet":
			talk = 0.55
		"room_busy":
			talk = 1.35
		"empty_bar", "none":
			talk = 0.0
			crowd = 0.0
	# the Sov's own, as loud as each is where it is (and how much of it gets to him, from where he
	# is, is worked out as he goes: _process)
	ta.juke = juke
	ta.talk_a = minf(crowd, 1.0) * 0.75 * talk
	ta.talk_b = (0.3 + rounds * 0.04) * talk if room_state.get("t28", true) else 0.0
	if room_state.get("pool_on", true) and talk > 0.0:
		ta.shout = clampf((heat - 2.0) * 0.18, 0.0, 0.6)
	ta.rain_glass = 0.75
	var cook := clock < 1380            # the cook goes at eleven, and his radio with him
	ta.fryer = 0.8 if cook else 0.2
	ta.fan = 0.75
	ta.radio = 0.75 if cook else 0.0
	ta.tube = 0.55
	ta.cellar = 0.85
	ta.rats = clampf(0.2 + rats * 0.06, 0.0, 0.95)
	# all round him, by where he is
	match where:
		"door":
			t.rain_out = 0.18
		"floor", "bar", "t28", "pool":
			t.rain_roof = 0.18
		"deck":
			t.rain_roof = 0.85
			t.rain_out = 0.55
			t.sea = 0.5
		"lot":
			t.rain_out = 0.95
			t.sea = 0.35
		"upstairs":
			t.rain_glass = 0.45
			t.rain_roof = 0.3
		# before the shift: Gary's office, the rain at its window and the bookkeeper's one finger;
		# the old main street and the highway in the wet; the Esso's canopy; the seawall, with the
		# Sov across the highway
		"office":
			t.rain_glass = 0.5
			t.keys = 0.75
		"street":
			t.rain_out = 0.6
			t.traffic = 0.45
			t.sea = 0.2
		"esso":
			t.canopy = 0.8
			t.traffic = 0.7
			t.rain_out = 0.3
		"seawall":
			t.rain_out = 0.75
			t.sea = 0.6
			t.traffic = 0.5
	if ink_amb == "rain_lot":
		t.rain_out = maxf(t.rain_out, 0.8)
	if ink_amb == "deck":
		t.rain_roof = maxf(t.rain_roof, 0.7)
	if ink_amb == "keg_room":
		ta.cellar = maxf(ta.cellar, 0.7)
	t.room_tone = (0.35 + 0.35 * minf(crowd, 1.0)) if ink_amb != "none" else 0.0
	target = t
	target_at = ta


func _process(dt: float) -> void:
	var amb := _vol("amb")
	var k := 1.0 - exp(-dt * (0.9 if unlocked else 0.4))
	var mine := _mine()
	var room_th := _through("room", mine)
	for layer in LAYERS:
		var want: float = target.get(layer, 0.0)
		var bus := &"Master"
		if layer in ROOM_FLAT:
			want *= room_th.x
			bus = _bus(room_th.y)
		elif FROM.has(layer):
			# what fills the room of a layer that comes from somewhere in it
			var th := _through(str(FROM[layer][1]), mine)
			var fill: float = target_at.get(layer, 0.0) * th.x * DIFFUSE
			if fill > want:
				want = fill
				bus = _bus(th.y)
		want *= amb
		level[layer] = lerpf(level[layer], want, k)
		var p: AudioStreamPlayer = loops[layer]
		if p.stream == null:
			continue
		if level[layer] > 0.004:
			p.volume_db = linear_to_db(level[layer])
			if p.bus != bus:
				p.bus = bus
			if not p.playing:
				p.play(randf() * maxf(p.stream.get_length() - 1.0, 0.0))
		elif p.playing:
			p.stop()
	for layer in sources:
		var th := _through(str(FROM[layer][1]), mine)
		var want: float = target_at.get(layer, 0.0) * th.x * (1.0 - DIFFUSE) * amb
		level_at[layer] = lerpf(level_at[layer], want, k)
		var bus := _bus(th.y)
		for q in sources[layer]:
			var p3: AudioStreamPlayer3D = q
			if p3.stream == null:
				continue
			if level_at[layer] > 0.004:
				p3.volume_db = linear_to_db(level_at[layer])
				if p3.bus != bus:
					p3.bus = bus
				if not p3.playing:
					p3.play(randf() * maxf(p3.stream.get_length() - 1.0, 0.0))
			elif p3.playing:
				p3.stop()
