# Pool for money, outside the nights: what Games > Pool keeps (in the settings, so it lasts). His
# purse (he starts with the forty he came with), the regulars on the chalk ladder by the table and
# which he's beaten, the cues he's bought, the Sunday draw, and the trick shots table 28 bets on.
#
# The ladder, bottom up, each on their own game and for their own money:
#   Scratch         $5 a rack, the Sov's eight-ball. Old, slow, lucky on the banks.
#   Hi-vis          $10. Hits everything as hard as a mill shift.
#   The buddy       $20. Quick, nervous, worse with money on it.
#   The cook        $20 nine-ball, on his smoke break. Good position, no patience.
#   Jim             $10 league eight-ball, after close. Plays the way he drums: in time, the same way
#                   every time, and he plays safe.
#   The big man     $50, the Sov's rules. Playing straight, he's the best in the room.
#   The man from Nanaimo  a stranger with a cue in a tube. He loses the first one for ten dollars,
#                   badly, and then wants a hundred on the next. He doesn't lose that one badly.
# And Good Shoes, off the ladder: he'll bet whatever you let him, and he's bad. Beat him by a lot and
# he's done for the week; keep it close and he doubles it.
class_name PoolCareer
extends RefCounted

const LADDER := [
	{"id": "scratch", "who": "scratch", "game": "8bar", "stakes": 5, "line": "Scratch, from table 28, plays left-handed off the rail when he can't reach, and talks to the balls."},
	{"id": "hivis", "who": "hivis", "game": "8bar", "stakes": 10, "line": "Hi-vis from the crew upstairs. He breaks like the table owes him money."},
	{"id": "buddy", "who": "buddy", "game": "8bar", "stakes": 20, "line": "The buddy. Quick, and quicker when there's money on it, which is worse."},
	{"id": "cook", "who": "cook", "game": "9ball", "stakes": 20, "line": "The cook, on his smoke break, nine-ball. He wants to be back on the line before the fryer notices."},
	{"id": "jim", "who": "jim", "game": "8league", "stakes": 10, "line": "Jim, after close, league rules. He chalks every shot the same way, four turns, and plays safe like it's a duty."},
	{"id": "bigman", "who": "bigman_straight", "game": "8bar", "stakes": 50, "line": "The big man, playing straight for once. Left-handed, slow, and he doesn't miss the ones that matter."},
	{"id": "nanaimo", "who": "nanaimo_dumb", "game": "8league", "stakes": 10, "line": "A man from Nanaimo with his own cue in a tube. He says he hasn't played in years."},
]

# What can be bought for the table: real differences, worked through the physics.
const SHOP := [
	{"id": "dufferin", "kind": "cue", "price": 60, "name": "A two-piece from the pawn window", "note": "A Dufferin, the joint a little loose. Straight, a good tip, better than anything in the rack.", "M": 0.55, "end": 0.0068, "e": 0.76, "limit": 0.6, "warp": 0.0, "colour": "3a1c14"},
	{"id": "ld_shaft", "kind": "cue", "price": 140, "name": "A low-deflection shaft", "note": "The cook's cousin's, in a sock. Its end is light, so the ball squirts half as much off its line with side on it.", "M": 0.55, "end": 0.0042, "e": 0.76, "limit": 0.6, "warp": 0.0, "colour": "1d2430"},
	{"id": "breaker", "kind": "cue", "price": 90, "name": "A break cue", "note": "A hard phenolic tip: it hits like a hammer and holds no spin.", "M": 0.57, "end": 0.0075, "e": 0.88, "limit": 0.4, "warp": 0.0, "colour": "1a1a1a"},
	{"id": "glove", "kind": "kit", "price": 15, "name": "A bridge glove", "note": "Three fingers, black. The cue slides true through the bridge: less drift in the stroke."},
	{"id": "chalk", "kind": "kit", "price": 4, "name": "Your own chalk", "note": "Blue, in a holder on a string. It lasts twice as long on the tip."},
]

# The trick shots: where the balls go, what has to drop, and what table 28 puts on it.
const TRICKS := [
	{"id": "railroad", "name": "Down the rail", "pays": 5, "balls": [[0, Vector2(-0.55, 0.32)], [3, Vector2(0.35, 0.465)]], "need": [3], "avoid": [],
		"line": "A ball frozen on the far rail, the length of the table to the corner. Hit the rail and the ball together, a hair of outside english."},
	{"id": "two_side", "name": "Two in the side", "pays": 8, "balls": [[0, Vector2(-0.6, 0.0)], [1, Vector2(0.0, 0.24)], [9, Vector2(0.0, 0.3)]], "need": [1, 9], "avoid": [],
		"line": "Two balls frozen together pointing at the side pocket. Hit the back one anywhere and they both go: it looks like magic and it's only geometry."},
	{"id": "round_eight", "name": "Round the eight", "pays": 12, "balls": [[0, Vector2(-0.3, 0.0)], [8, Vector2(-0.1, 0.0)], [5, Vector2(0.55, 0.12)]], "need": [5], "avoid": [8],
		"line": "The eight square in the way. Butt up high, the tip off to the side, and curve round it."},
	{"id": "over", "name": "Over the top", "pays": 15, "balls": [[0, Vector2(-0.45, -0.1)], [11, Vector2(-0.32, -0.1)], [2, Vector2(0.4, -0.38)]], "need": [2], "avoid": [11],
		"line": "A ball a hand in front of the cue ball. Drive down into the slate and jump it."},
]


static func data(settings: Dictionary) -> Dictionary:
	var d: Dictionary = settings.get("pool", {})
	if d.is_empty():
		d = {"purse": 40, "beaten": [], "owned": [], "tricks": [], "shoes_week": 0, "shoes_stakes": 50, "nanaimo_hustled": false, "sundays": 0, "trophies": []}
		settings["pool"] = d
	return d


static func cues(settings: Dictionary) -> Array:
	var out: Array = Pool.CUES.duplicate()
	var d := data(settings)
	for s in SHOP:
		if s.kind == "cue" and s.id in d.owned:
			out.append(s)
	return out


static func has(settings: Dictionary, id: String) -> bool:
	return id in data(settings).owned


static func unlocked(settings: Dictionary, i: int) -> bool:
	if i == 0:
		return true
	return LADDER[i - 1].id in data(settings).beaten
