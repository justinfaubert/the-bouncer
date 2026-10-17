# The sound: the room's noise in layers, and the small sounds of the job.
#
# Everything here is a placeholder made in code (tools/sounds.py), there to hold the places where
# Hutch's own recordings go. To swap one, put a file with the same name (.wav, .ogg or .mp3) in a
# folder called "audio" beside the game, or in the game's user folder; it's used instead from the
# next start. The names are the files in audio/: the small sounds (click, beep_ok, thump...) and the
# room's layers (amb_rain_glass, amb_talk_a...).
#
# The room is mixed from its layers by where he is and what the night's doing: how many are in, the
# heat at the pool table, table 28's rounds, the rats. The Ink's #amb and #music tags lean on the
# mix (a quiet room, an empty bar, the jukebox late), they don't replace it.
class_name Sound
extends Node

# the Ink's names for things, to the files that stand in for them
const INK := {"scanner_ok": "beep_ok", "scanner_bad": "beep_bad", "door": "thump", "phone": "ring",
	"hit": "thud", "balls": "clack", "dice_shake": "rattle", "die_tick": "tick", "die_land": "tock",
	"glass": "glass", "scratch": "scratch", "till": "till", "bell": "bell"}
const LAYERS := ["rain_glass", "rain_out", "rain_roof", "room_tone", "talk_a", "talk_b", "shout", "juke", "pool",
	"fryer", "fan", "tube", "cellar", "rats", "sea", "keys", "canopy", "traffic"]
# how loud each small sound sits under the rest
const LEVEL := {"click": 0.8, "choose": 0.35, "click_ui": 0.35, "steps": 0.45, "whisper": 0.5, "page": 0.5, "pen": 0.55,
	"printer": 0.5, "heart": 0.8, "tick": 0.55, "tock": 0.8, "rattle": 0.7, "gust": 0.6, "swipe": 0.45, "card": 0.6, "lift": 0.5}

var settings: Dictionary
var files := {}                 # name -> [paths of its takes]
var cache := {}
var players: Array = []         # a few for the small sounds, round robin
var next_player := 0
var loops := {}                 # layer -> AudioStreamPlayer
var level := {}                 # layer -> where it is now, 0..1
var target := {}                # layer -> where it's going
var ink_amb := ""               # the last #amb
var music := "jukebox_early"    # the last #music
var room_state := {"n": 13, "heat": 0, "rounds": 0, "rats": 0, "clock": 1260, "here": "door"}
var where := "door"
var unlocked := false
var _last := {}                 # name -> when it last played, so the same take isn't used twice running


func setup(s: Dictionary) -> void:
	settings = s
	_find_files()
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	for layer in LAYERS:
		var p := AudioStreamPlayer.new()
		var st = _stream("amb_" + layer, 0)
		if st is AudioStreamWAV:
			var w := st as AudioStreamWAV
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(round(w.get_length() * w.mix_rate))
		elif st is AudioStreamOggVorbis:
			(st as AudioStreamOggVorbis).loop = true
		elif st is AudioStreamMP3:
			(st as AudioStreamMP3).loop = true
		p.stream = st
		p.volume_db = -80.0
		add_child(p)
		loops[layer] = p
		level[layer] = 0.0
		target[layer] = 0.0
	place("door", 1260)


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


# One of the small sounds, by its own name or the Ink's.
func sfx(id: String, gain := 1.0, pitch := 1.0) -> void:
	var name: String = INK.get(id, id)
	var list: Array = files.get(name, [])
	if list.is_empty():
		return
	var v := _vol("sfx") * gain * float(LEVEL.get(name, 0.75))
	if v <= 0.001:
		return
	var take := randi() % list.size()
	if list.size() > 1 and _last.get(name, -1) == take:
		take = (take + 1) % list.size()
	_last[name] = take
	var st = _stream(name, take)
	if st == null:
		return
	var p: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = st
	p.volume_db = linear_to_db(v)
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
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
	_mix()


func place(here: String, clock: int) -> void:
	where = here
	room_state["clock"] = clock
	_mix()


func _mix() -> void:
	var t := {}
	for layer in LAYERS:
		t[layer] = 0.0
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
	# the room as it is heard in the room, and how much of it gets through to where he is
	var room_part := 0.0
	match where:
		"door":
			t.rain_glass = 0.75
			t.rain_out = 0.18
			room_part = 0.7
		"floor", "bar", "t28", "pool":
			t.rain_roof = 0.18
			t.rain_glass = 0.22 if where == "t28" else 0.1
			room_part = 1.0
			if where == "pool":
				t.pool = 0.55 + heat * 0.08
			if where == "t28":
				t.talk_b = 0.35 + rounds * 0.05
		"hall":
			t.tube = 0.55
			room_part = 0.45
		"kitchen":
			t.fryer = 0.8
			t.fan = 0.75
			room_part = 0.3
		"keg":
			t.cellar = 0.85
			t.rats = clampf(0.2 + rats * 0.06, 0.0, 0.95)
			room_part = 0.14
		"deck":
			t.rain_roof = 0.85
			t.rain_out = 0.55
			t.sea = 0.5
			room_part = 0.18
		"lot":
			t.rain_out = 0.95
			t.sea = 0.35
			room_part = 0.1
		"upstairs":
			t.rain_glass = 0.45
			t.rain_roof = 0.3
			room_part = 0.1
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
			room_part = 0.06
	if ink_amb == "rain_lot":
		t.rain_out = maxf(t.rain_out, 0.8)
	if ink_amb == "deck":
		t.rain_roof = maxf(t.rain_roof, 0.7)
	if ink_amb == "keg_room":
		t.cellar = maxf(t.cellar, 0.7)
	t.room_tone = (0.35 + 0.35 * minf(crowd, 1.0)) * room_part if ink_amb != "none" else 0.0
	t.talk_a = minf(crowd, 1.0) * 0.75 * talk * room_part
	t.talk_b = maxf(t.talk_b, clampf(crowd - 0.4, 0.0, 1.0) * 0.6 * talk * room_part)
	t.shout = clampf((heat - 2.0) * 0.18, 0.0, 0.6) * room_part * (1.0 if talk > 0.0 else 0.0)
	t.juke = juke * room_part * (0.7 if where in ["door", "hall"] else 1.0)
	if where != "pool":
		t.pool = (0.22 + heat * 0.04) * room_part * (1.0 if talk > 0.0 else 0.0)
	target = t


func _process(dt: float) -> void:
	var amb := _vol("amb")
	var k := 1.0 - exp(-dt * (0.9 if unlocked else 0.4))
	for layer in LAYERS:
		var want: float = target.get(layer, 0.0) * amb
		level[layer] = lerpf(level[layer], want, k)
		var p: AudioStreamPlayer = loops[layer]
		if p.stream == null:
			continue
		if level[layer] > 0.004:
			p.volume_db = linear_to_db(level[layer])
			if not p.playing:
				p.play(randf() * maxf(p.stream.get_length() - 1.0, 0.0))
		elif p.playing:
			p.stop()
