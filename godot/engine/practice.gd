# Practice: what he does becomes who he is (bible/15_FIGHTS_AND_STATS.md, section 4).
#
# Under his seven stats, tallies for what he actually does, named in the world's words: Hands for
# clean blows, Holds for grips kept and men turned, Read for tells read, Arm for darts, and the rest.
# Points come only from doing a thing well, and never from doing it again and again:
#   - a night's cap on each (a good night reaches it);
#   - the same thing done the same way earns less each time that night ("how", the key);
#   - the caller doesn't pay for beating someone worse (that's its business: see fight.gd).
# Four marks on each. The first and third put a point on a stat it feeds (in turn, where it feeds
# two), never past 9 by practice alone; the second and fourth give a knack, a named way of doing a
# thing that changes play and that the story can see (Ink: knack_<id>). Loss: a practice can be
# stopped (a broken hand stops Hands) until the body heals.
class_name Practice
extends RefCounted

const MARKS := [10.0, 25.0, 45.0, 70.0]
const NIGHT_CAP := 11.0
const STAT_CEIL := 9
const AGAIN := 0.35           # each time the same way tonight: the next earns 1 / (1 + AGAIN * times)

# Each practice: its name, the stats it feeds, the voice that says it when a mark comes, and words
# for how far along he is (none, then by marks reached).
const KINDS := {
	"hands": {"label": "Hands", "feeds": ["str", "dex"], "voice": "fighter",
		"words": ["green", "getting quick", "quick and heavy", "a puncher", "hands people talk about"]},
	"holds": {"label": "Holds", "feeds": ["str", "dex"], "voice": "fighter",
		"words": ["green", "a grip", "a good grip", "he turns men", "nobody gets out of it"]},
	"feet": {"label": "Feet", "feeds": ["dex"], "voice": "fighter",
		"words": ["flat-footed", "moving", "light for his size", "never where they throw", "a dancer, they say"]},
	"chin": {"label": "Chin", "feeds": ["con"], "voice": "fighter",
		"words": ["untested", "he can take one", "he can take a few", "a hard head", "you'd need a brick"]},
	"wind": {"label": "Wind", "feeds": ["con"], "voice": "table",
		"words": ["short of it", "getting his wind", "goes a few rounds", "goes all night", "never blows"]},
	"read": {"label": "Read", "feeds": ["wis"], "voice": "father",
		"words": ["late on everything", "sees some coming", "sees them coming", "sees it before they do", "reads a man like a menu"]},
	"sense": {"label": "Sense", "feeds": ["gut"], "voice": "wrongman",
		"words": ["deaf to it", "a prickle", "the hair on his neck", "knows before he turns", "something tells him"]},
	"nerve": {"label": "Nerve", "feeds": ["cha"], "voice": "father",
		"words": ["untried", "holds his ground", "steady", "the room goes quiet for him", "nobody tries him twice"]},
	"arm": {"label": "Arm", "feeds": ["dex"], "voice": "table",
		"words": ["a pub thrower", "finding the line", "a steady arm", "league standard", "a ringer"]},
	"eye": {"label": "Eye", "feeds": ["dex", "int"], "voice": "manual",
		"words": ["a hacker", "sees the angle", "plays position", "runs a rack", "a hustler's eye"]},
	"faces": {"label": "Faces", "feeds": ["int", "wis"], "voice": "manual",
		"words": ["takes them at their word", "checks the dates", "hears the lie", "knows a fake by the feel", "nobody gets by him"]},
}

# The knacks: which practice and which mark (2 or 4) gives each, and what it does, as he'd put it.
const KNACKS := {
	"short_one": {"from": "hands", "mark": 2, "name": "The short one", "what": "A six-inch punch carries his whole weight. A short stroke hits as hard as a long one, and shows less."},
	"heavy_hands": {"from": "hands", "mark": 4, "name": "Heavy hands", "what": "What lands rings the bell harder."},
	"circle_closes": {"from": "holds", "mark": 2, "name": "The circle closes", "what": "The turn builds quicker: less circling before a man's feet can't keep up."},
	"the_angle": {"from": "feet", "mark": 2, "name": "The angle", "what": "His sidestep is quicker, and takes him off the line."},
	"hard_head": {"from": "chin", "mark": 2, "name": "Hard head", "what": "The first clean one of a fight doesn't ring the bell."},
	"second_wind": {"from": "wind", "mark": 2, "name": "Second wind", "what": "Once a fight, when it's gone, the breath comes back."},
	"the_shoulder": {"from": "read", "mark": 2, "name": "The shoulder", "what": "He sees the shoulder go back before a blow: it's drawn on the man in THE FIGHTER's ink."},
	"seen_it": {"from": "read", "mark": 4, "name": "Seen it before", "what": "Their tells last longer for him."},
	"steady_hand": {"from": "arm", "mark": 2, "name": "Steady hand", "what": "The dart shakes half as much in his fingers."},
}

# What each voice says when a mark comes, by practice: %s is the words for where he's got to.
const SAYS := {
	"hands": "Your hands are %s. Feel that? That's the weight going through, not the arm.",
	"holds": "%s. You stopped pulling and started turning. They follow the turn.",
	"feet": "%s. The punch you weren't there for is the one that never hurt.",
	"chin": "%s. Tuck it and take it on the forehead. You're still here.",
	"wind": "%s. You'd have been sat on a stool gasping a week ago.",
	"read": "%s. You watched his shoulder, not his fist. That's all it ever is.",
	"sense": "%s. You turned before you knew why. Don't ask why.",
	"nerve": "%s. You didn't step back. They saw you not step back.",
	"arm": "%s. Same elbow, same release, same place. Again.",
	"eye": "%s. You saw the shot before you were down on it.",
	"faces": "%s. The date's wrong, and so's the way she said it.",
}

var points := {}       # kind -> float
var tonight := {}      # kind -> float earned this night
var ways := {}         # how -> times this night
var marks := {}        # kind -> marks reached
var bumps := {}        # kind -> stat points it's given
var knacks := {}       # id -> the night it came
var stopped := {}      # kind -> why (a broken hand)
var night := 0


# A new night: the caps and the "same way again" start over.
func new_night(n: int) -> void:
	if n == night:
		return
	night = n
	tonight = {}
	ways = {}


# He did something well. kind: a KINDS key; amount: how well (a clean jab is ~1, a man turned to the
# floor ~3); how: what exactly, so the same thing again earns less tonight. stats: his seven now
# (to know what a point on one would do). Returns what came of it: [{"kind": "mark", ...},
# {"kind": "stat", "stat", "from", "to"}, {"kind": "knack", "id", ...}]
func earn(kind: String, amount: float, how := "", stats := {}) -> Array:
	var out: Array = []
	if not KINDS.has(kind) or amount <= 0.0 or stopped.has(kind):
		return out
	var key := how if how != "" else kind
	var times := int(ways.get(key, 0))
	ways[key] = times + 1
	var got := amount / pow(1.0 + AGAIN * times, 2.0)
	var room := NIGHT_CAP - float(tonight.get(kind, 0.0))
	got = clampf(got, 0.0, maxf(0.0, room))
	if got <= 0.0:
		return out
	tonight[kind] = float(tonight.get(kind, 0.0)) + got
	var before := float(points.get(kind, 0.0))
	var after := before + got
	points[kind] = after
	for i in MARKS.size():
		if before < MARKS[i] and after >= MARKS[i] and int(marks.get(kind, 0)) <= i:
			marks[kind] = i + 1
			var ev := {"kind": "mark", "practice": kind, "mark": i + 1, "label": KINDS[kind].label, "words": word(kind)}
			out.append(ev)
			if i == 0 or i == 2:
				var feeds: Array = KINDS[kind].feeds
				var n := int(bumps.get(kind, 0))
				var st := str(feeds[n % feeds.size()])
				var cur := int(stats.get(st, 4))
				if cur < STAT_CEIL:
					bumps[kind] = n + 1
					stats[st] = cur + 1
					out.append({"kind": "stat", "stat": st, "from": cur, "to": cur + 1, "practice": kind})
			else:
				for id in KNACKS:
					var k: Dictionary = KNACKS[id]
					if k.from == kind and int(k.mark) == i + 1 and not knacks.has(id):
						knacks[id] = night
						out.append({"kind": "knack", "id": id, "name": k.name, "what": k.what, "practice": kind})
	return out


func has(knack: String) -> bool:
	return knacks.has(knack)


# The knacks a fight cares about, as FightSim.Fighter.knacks wants them.
func fight_knacks() -> Dictionary:
	var d := {}
	for id in knacks:
		d[id] = true
	return d


func word(kind: String) -> String:
	var w: Array = KINDS[kind].words
	return str(w[mini(int(marks.get(kind, 0)), w.size() - 1)])


# How far to the next mark, 0..1 (for the pencil ticks on his notes).
func toward(kind: String) -> float:
	var m := int(marks.get(kind, 0))
	if m >= MARKS.size():
		return 1.0
	var lo: float = 0.0 if m == 0 else MARKS[m - 1]
	return clampf((float(points.get(kind, 0.0)) - lo) / (MARKS[m] - lo), 0.0, 1.0)


# The line for a mark, in its voice: [voice id, text]
static func says(ev: Dictionary) -> Array:
	var kind := str(ev.get("practice", ""))
	if not KINDS.has(kind):
		return ["", ""]
	var w := str(ev.get("words", ""))
	var tpl := str(SAYS.get(kind, "%s."))
	if tpl.begins_with("%s"):
		w = w.substr(0, 1).to_upper() + w.substr(1)
	return [str(KINDS[kind].voice), tpl % w]


func stop(kind: String, why: String) -> void:
	stopped[kind] = why


func heal(kind: String) -> void:
	stopped.erase(kind)


func to_dict() -> Dictionary:
	return {"points": points.duplicate(), "tonight": tonight.duplicate(), "ways": ways.duplicate(), "marks": marks.duplicate(),
		"bumps": bumps.duplicate(), "knacks": knacks.duplicate(), "stopped": stopped.duplicate(), "night": night}


static func from_dict(d) -> Practice:
	var p := Practice.new()
	if d is Dictionary:
		for k in ["points", "tonight", "ways", "marks", "bumps", "knacks", "stopped"]:
			if d.get(k) is Dictionary:
				p.set(k, (d[k] as Dictionary).duplicate())
		p.night = int(d.get("night", 0))
	return p
