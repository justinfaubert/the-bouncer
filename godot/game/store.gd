# Saves and settings, on the player's own machine (user://).
#
# A night is saved after every choice, and a moment after the last touch of anything in his hands.
# There are three nights, each in its own slot; each is played through once, the way the browser
# build's one save is: there's no going back to try it again.
class_name Store
extends RefCounted

const SLOTS := 3
const DIR := "user://saves"
const SETTINGS := "user://settings.json"

const DEFAULTS := {
	"text": "m",          # the column's type: s, m, l
	"reveal": "lines",    # new lines one after another (lines) or all at once (all)
	"odds": "words",      # the chance on a check in words or numbers
	"dice": "full",       # by hand (full), rolled out (auto), quick, at once (still)
	"prompts": true,      # show the writing prompts where the draft needs Hutch's material
	"notice": true,       # the voices lean in on what the player's eyes and hand are on
	"skin": true,         # drink, hurt and nerves show in the print
	"sway": true,         # drunk, the view sways (off for anyone it makes queasy)
	"grain": 1.0,         # how coarse the print's grain is
	"sound": true,
	"master": 0.8, "amb": 0.6, "sfx": 0.8, "music": 0.6,
	"look_speed": 1.0,    # turning his head with the mouse
	"invert": false,
	"fov": 58.0,
	"fullscreen": false,
	"render": 1.0,        # the share of the screen's pixels the world is drawn at
	"slot": 1,            # the night last played
}

var settings := {}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	settings = DEFAULTS.duplicate(true)
	var got = _read(SETTINGS)
	if got is Dictionary:
		for k in got:
			if DEFAULTS.has(k) and typeof(got[k]) == typeof(DEFAULTS[k]):
				settings[k] = got[k]
			elif DEFAULTS.has(k) and (DEFAULTS[k] is float) and (got[k] is int or got[k] is float):
				settings[k] = float(got[k])
			elif DEFAULTS.has(k) and (DEFAULTS[k] is int) and (got[k] is float):
				settings[k] = int(got[k])


func save_settings() -> void:
	_write(SETTINGS, settings)


func path_of(slot: int) -> String:
	return DIR + "/night%d.json" % slot


func save(slot: int, data: Dictionary) -> bool:
	var d := data.duplicate()
	d["game"] = "the-bouncer"
	d["savedAt"] = int(Time.get_unix_time_from_system())
	return _write(path_of(slot), d)


func load_slot(slot: int):
	var d = _read(path_of(slot))
	if d is Dictionary and d.get("game") == "the-bouncer":
		return d
	return null


func clear(slot: int) -> void:
	if FileAccess.file_exists(path_of(slot)):
		DirAccess.remove_absolute(path_of(slot))


# the night played most recently, or 0
func latest() -> int:
	var best := 0
	var at := -1
	for s in range(1, SLOTS + 1):
		var d = load_slot(s)
		if d != null and int(d.get("savedAt", 0)) > at:
			at = int(d.get("savedAt", 0))
			best = s
	return best


# "9:05 pm, 23 choices in", the way the title says where a night got to
static func meta(save) -> String:
	if save == null:
		return ""
	if save.get("ended", false):
		return "The shift is over."
	var clock := 0
	var re := RegEx.new()
	re.compile("\"clock\"\\s*:\\s*(\\d+)")
	var m := re.search(str(save.get("ink", "")))
	if m != null:
		clock = int(m.get_string(1))
	var path = save.get("path", [])
	var n: int = path.size() if path is Array else int(save.get("turn", 0))
	return (BUtil.fmt_clock(clock) + ", " if clock > 0 else "") + str(n) + (" choice" if n == 1 else " choices") + " in"


func _write(path: String, data) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK


func _read(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var txt := f.get_as_text()
	f.close()
	return JSON.parse_string(txt)
