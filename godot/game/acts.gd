# What a choice looks like when he makes it: his head with what he says (a nod, a shake, leaning
# in, looking down), and what the one he's saying it to does back (world/life.gd's gestures).
#
# A choice can say so itself, "#act: shake back" (his, then theirs; "-" for nothing of his).
# Otherwise it's read from the words, the way the hotspots read what a choice is about: the first
# rule that matches wins. Most choices are nothing to look at, and get nothing.
class_name Acts
extends RefCounted

# [words (regex, case blind), his, theirs]
const RULES := [
	["\\b(get out|out you go|you're done|leave now|not tonight|go home|you're cut off|cut him off|no chance|turn (him|her|them) (away|back))", "shake", "back"],
	["\\b(grab|shove|push|hands on|by the collar|step outside|square up|get in (his|her) face|lean in)", "in", "back"],
	["\\b(in you go|go on in|go ahead|you can go in|come in|wave (him|her|them) in|let (him|her|them) in)", "nod", "nod"],
	["\\b(sorry|my fault|apologi[sz]e)", "down", "nod"],
	["\\b(joke|laugh|kid (him|her)|tease|wink)", "nod", "laugh"],
	["^(no|nope)\\b|\\b(say no|refuse|tell (him|her|them) no|won't|not happening)", "shake", "away"],
	["^(yes|yeah|sure|okay|ok|fine|all right|alright)\\b|\\b(agree|nod)", "nod", "nod"],
	["\\b(stare|hold (his|her|their) eye|look at (him|her|them)|say nothing|wait (him|her|them) out|let the silence)", "", "away"],
	["\\b(ask|what's|who's|why|where|how)\\b.*\\?$|\\?$", "", "tilt"],
	["\\b(look away|look down|let it go|drop it|back off)", "down", ""],
]

static var _res := []


static func read(c: Dictionary) -> Array:
	var tag := str(c.get("act", "")) if c.get("act") != null else ""
	if tag != "":
		var w := tag.split(" ", false)
		return [("" if w[0] == "-" else w[0]), (w[1] if w.size() > 1 else "")]
	if c.get("cls") == "move" or c.get("read") != null:
		return ["", ""]
	if _res.is_empty():
		for r in RULES:
			_res.append(RegEx.create_from_string("(?i)" + r[0]))
	var text := str(c.get("text", "")).strip_edges()
	# what he says, in quotes, counts more than the telling round it
	for i in RULES.size():
		if _res[i].search(text) != null:
			return [RULES[i][1], RULES[i][2]]
	return ["", ""]


# Play it: his head now, theirs a moment after (they hear it first). who: the one he's facing,
# found by the stage if not given.
static func play(main, c: Dictionary, s := 1.0) -> Array:
	var a := read(c)
	if a[0] != "":
		main.view.beat(a[0], s)
	if a[1] != "":
		var who := facing(main)
		if who != "":
			if a[1] == "laugh":
				main.stage.life.laugh(who, 0.6, 0.4)
			else:
				main.stage.life.gesture(who, a[1], s, 0.35)
	return a


# The one he's looking at, near enough to be talking to: the nearest head within a cone ahead.
static func facing(main) -> String:
	var cam: Camera3D = main.view.cam
	var fwd := -cam.global_transform.basis.z
	var best := ""
	var best_d := 3.2
	for id in main.stage.figures:
		if not main.stage.life.has(str(id)):
			continue
		var h: Vector3 = main.stage.head_of(str(id))
		var to := h - cam.global_position
		var d := to.length()
		if d < best_d and d > 0.2 and fwd.angle_to(to) < 0.7:
			best_d = d
			best = str(id)
	return best


# What someone does with their own line as they say it: a no shakes, a yes nods, a question tips
# the head, sorry looks down.
const THEIRS := [
	["^\\W*(no|nah|nope|not)\\b|\\bno way\\b", "shake"],
	["^\\W*(yes|yeah|yep|sure|okay|ok|right)\\b", "nod"],
	["\\b(sorry|my bad)\\b", "down"],
	["\\?\\W*$", "tilt"],
]
static var _their := []


static func their_line(text: String) -> String:
	if _their.is_empty():
		for r in THEIRS:
			_their.append(RegEx.create_from_string("(?i)" + r[0]))
	for i in THEIRS.size():
		if _their[i].search(text.strip_edges()) != null:
			return THEIRS[i][1]
	return ""
