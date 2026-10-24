# The people in the room, alive while he watches.
#
# A person modelled with bones (tools/rig.py: their model's .json has "rig") breathes, shifts their
# weight standing or settles on their stool, and looks about: at whoever they're with, at whoever's
# talking, at their phone or their glass, round the room, and at the eye the room is seen through
# (his; Gary's, in the office) when it comes close, when it's been on them a while, and while they
# talk to it. The eyes go first and the head comes after, the way eyes do; they blink, and nearly
# always when their eyes go a long way; the upper lids follow the eyes down; and the jaw goes with
# what they say. They talk among themselves too (game/talk.gd: what he overhears), each looking at
# whoever they're talking to; they laugh, the head back and the shoulders going; and the bartender
# works while he watches, wiping down, pulling a pint, at the till (world/doings.gd). A glass from the
# table put back down is heard where it lands. Stage keeps its old ways (the whole figure turned, a
# bob) for anyone without bones.
#
# Each bone is turned about its own joint by a turn given in the model's frame as it's posed (a
# bone's turn carries the bones on it, so the head's goes on top of the neck's): see _turn.
class_name Life
extends RefCounted

# how readily each meets the eye: 0 never holds it, 1 stares it out; anyone else 0.5
const BOLD := {"hoodie": 0.12, "vape": 0.3, "driver": 0.35, "essokid": 0.2, "constable": 0.95, "bartender": 0.65,
	"bigman": 0.8, "endbar": 0.4, "team_jacket": 0.7, "scratch": 0.45, "glasses": 0.55, "him": 0.75, "terry": 0.6,
	"bookkeeper": 0.3, "slippers": 0.4, "raincoat": 0.3, "goodshoes": 0.7, "hivis": 0.6}
# what of their own each looks at (the point in their model's .json), and how much beside the rest
const OWN := {"phone": 5.0, "ledger": 6.0, "glass": 1.0, "card": 0.5, "keys": 0.6}
const HEAD_LIMIT := 1.35          # how far round from their body the head goes, either way (radians), standing
const HEAD_LIMIT_SEATED := 1.2
const CHEST_MAX := 0.3            # how much of a turn the chest takes, standing
const CHEST_MAX_SEATED := 0.17
const EYES_YAW := 0.42            # how far the eyes go in the head, side to side (radians)
const EYES_UP := 0.14
const EYES_DOWN := 0.33
const JAW_OPEN := 14.0            # the jaw at its widest in talk, degrees
const BONES := ["hips", "spine", "chest", "neck", "head", "jaw", "eye.L", "eye.R", "lid.L", "lid.R",
	"upper_arm.L", "upper_arm.R", "forearm.L", "forearm.R", "hand.L", "hand.R"]
const SIP_TILT := 0.8             # how far a glass tips at the mouth (radians)
const REACH := 0.44               # as far from the shoulder as a hand goes easily, at work (metres)

var people := {}                  # id -> a person's bones and state (see add)
var t := 0.0
var talk_free := 0.0              # when the last line given out has been said: lines are said one after another
var cups: Node3D = null           # the glasses on table 28 (world/pub.gd), for whoever sits at it to drink from
var heard := Callable()           # a sound of theirs from where it happens: (name, point, how loud, how near for full)


static func _v(a) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


# Someone placed in the room (stage.gd's _place): their bones, if their model has them. False if
# it hasn't, and stage moves them its old way.
func add(id: String, node: Node3D, body: Node3D, anchors: Dictionary, seated: bool) -> bool:
	remove(id)
	if not anchors.has("rig"):
		return false
	var sks := body.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return false
	var sk: Skeleton3D = sks[0]
	var rig: Dictionary = anchors.rig
	var p := {"id": id, "node": node, "body": body, "sk": sk, "b": {}, "L": {}, "G": {}, "Gi": {}, "O": {}, "seated": seated}
	for name in BONES:
		var i := sk.find_bone(name)
		if i < 0:
			continue
		p.b[name] = i
		p.L[name] = sk.get_bone_rest(i).basis.orthonormalized()
		var g := sk.get_bone_global_rest(i)
		p.G[name] = g.basis.orthonormalized()
		p.Gi[name] = g.basis.orthonormalized().transposed()
		p.O[name] = g.origin
	if not (p.b.has("head") and p.b.has("neck") and p.b.has("chest")):
		return false
	# from the model's frame (its .json) to the skeleton's
	var to_sk := sk.global_transform.affine_inverse() * body.global_transform
	p.to_sk = to_sk
	var ax: Array = rig.get("head_axes", [[1, 0, 0], [0, 0, -1], [0, 1, 0]])
	p.right = (to_sk.basis * _v(ax[0])).normalized()
	p.fwd = (to_sk.basis * _v(ax[1])).normalized()
	p.up = (to_sk.basis * _v(ax[2])).normalized()
	var e: Array = rig.eyes
	p.eyes = to_sk * ((_v(e[0]) + _v(e[1])) * 0.5)
	p.eyes_model = (_v(e[0]) + _v(e[1])) * 0.5
	p.blink_deg = float(rig.get("blink", 40.0))
	# the body's own front and right (the model faces -z), and where the head is turned on it as it's sculpted
	var tf := (to_sk.basis * Vector3(0, 0, -1)).normalized()
	p.tf = tf
	p.tr = tf.cross(Vector3.UP).normalized()
	var f0 := Vector3(p.fwd.x, 0.0, p.fwd.z).normalized()
	p.f0 = f0
	p.l0 = Vector3.UP.cross(f0).normalized()
	p.yaw0 = atan2(f0.dot(-p.tr), f0.dot(tf))
	p.pitch0 = asin(clampf(p.fwd.y, -1.0, 1.0))
	p.own = {}
	for k in OWN:
		if anchors.has(k):
			p.own[k] = _v(anchors[k])
	# a drink: in their hand (the hand round it, and where the middle of it is), or, sitting without
	# one, whatever's on the table in front of them (cups); and where their mouth is, for a sip now and then
	p.sip = {}
	if rig.has("mouth"):
		var sp := {"mouth": to_sk * _v(rig.mouth), "next": t + randf_range(5.0, 30.0), "t0": -100.0, "hold": 1.2,
			"r": 0.0, "end": 0.0, "table": false, "side": ""}
		if anchors.has("glass"):
			var gl := _v(anchors.glass)
			var side := "L" if gl.distance_to(_v(anchors.get("hand_left", [0, 0, 0]))) < gl.distance_to(_v(anchors.get("hand_right", [0, 0, 0]))) else "R"
			if _arm(p, side):
				sp.side = side
				sp.glass = to_sk * (gl + Vector3(0, 0.07, 0))
				p.sip = sp
		elif seated and (_arm(p, "L") or _arm(p, "R")):
			sp.table = true
			p.sip = sp
	p.bold = float(BOLD.get(id, 0.5))
	p.quick = randf_range(7.0, 11.0) * lerpf(0.85, 1.15, p.bold)
	p.notice = randf_range(1.0, 2.6) * lerpf(1.4, 0.7, p.bold)
	p.rate = randf_range(0.2, 0.3)
	p.breath = randf() * TAU
	# where they're looking now: what at ("" for straight ahead), the point or who, till when
	p.kind = ""
	p.at = null
	p.until = t + randf_range(0.5, 3.0)
	p.idle = Vector2.ZERO
	p.hy = 0.0
	p.hp = 0.0
	p.hyv = 0.0
	p.hpv = 0.0
	p.drift = Vector2.ZERO
	p.drift_at = 0.0
	p.blink0 = -10.0
	p.next_blink = t + randf_range(0.5, 4.0)
	p.watched = 0.0
	p.noticed = false
	p.shift = Vector3.ZERO          # the weight shifted: lean forward, roll, turn (radians)
	p.shift_to = Vector3.ZERO
	p.next_shift = t + randf_range(3.0, 12.0)
	p.talk = []
	p.jaw = 0.0
	p.jawv = 0.0
	p.force = {}
	p.laugh0 = -100.0
	p.laugh_len = 0.0
	p.cough0 = -100.0
	p.job = {}
	people[id] = p
	return true


func remove(id: String) -> void:
	if people.has(id):
		_stop_sip(people[id])
	people.erase(id)


func has(id: String) -> bool:
	return people.has(id)


# A line of theirs: the jaw goes with it, after whatever's been said before it, and while they say
# it they look at the eye if they can.
func speak(id: String, text: String) -> void:
	var p = people.get(id)
	if p == null or text.strip_edges() == "":
		return
	var t0 := maxf(t, talk_free)
	var keys := _syllables(text, t0)
	(p.talk as Array).append_array(keys)
	talk_free = float(keys[keys.size() - 1][0]) + 0.25
	p.force = {"kind": "eye", "at": t0, "until": talk_free + randf_range(0.8, 2.0)}


# Something they turn to (he ran across the room): after a moment, for a few seconds.
func startle(id: String, point: Vector3) -> void:
	var p = people.get(id)
	if p == null:
		return
	var d0 := t + randf_range(0.0, 0.45)
	p.force = {"kind": "point", "point": point, "at": d0, "until": d0 + randf_range(2.8, 4.2)}


# A line of theirs to someone else in the room (game/talk.gd, what he overhears): the jaw goes with
# it, once they're done with whatever they were saying, and they look at whoever it's to. Returns
# when it's said, in the room's time (t); for someone without bones, when it would be.
func say(id: String, text: String, to := "") -> float:
	var p = people.get(id)
	if p == null or text.strip_edges() == "":
		return t + float(_syllables(text, 0.0).back()[0])
	var tk: Array = p.talk
	var t0 := t
	if not tk.is_empty():
		t0 = maxf(t0, float(tk[tk.size() - 1][0]) + 0.1)
	var keys := _syllables(text, t0)
	tk.append_array(keys)
	var end := float(keys[keys.size() - 1][0])
	if to != "":
		p.force = {"kind": "them", "point": to, "at": t0, "until": end + randf_range(0.4, 1.2)}
	return end


# What they were saying, broken off (the story wants them now): the jaw shut, the look let go.
func hush(id: String) -> void:
	var p = people.get(id)
	if p != null:
		(p.talk as Array).clear()
		p.force = {}


# Someone listening: they look at whoever's talking, after a moment, till then.
func listen(id: String, to: String, until: float) -> void:
	var p = people.get(id)
	if p == null or id == to:
		return
	var d0 := t + randf_range(0.1, 0.6)
	p.force = {"kind": "them", "point": to, "at": d0, "until": maxf(until, d0 + 0.8)}


# Their eyes on something for a while (the TV, a ball on the felt), after a moment.
func look_over(id: String, point: Vector3, secs: float) -> void:
	var p = people.get(id)
	if p == null:
		return
	var d0 := t + randf_range(0.0, 0.5)
	p.force = {"kind": "point", "point": point, "at": d0, "until": d0 + secs}


# A laugh, s how hard (0 to 1), starting a moment from now: the head goes back, the shoulders with
# each "ha", the jaw open on them, and the eyes screwed up.
func laugh(id: String, s := 1.0, after := 0.0) -> void:
	var p = people.get(id)
	if p == null:
		return
	p.laugh0 = t + after
	p.laugh_len = lerpf(1.2, 2.4, s) * randf_range(0.85, 1.15)
	p.laugh_s = s
	p.laugh_hz = randf_range(4.0, 5.4)


# A cough: twice forward from the chest, the jaw open on it and the eyes shut.
func cough(id: String) -> void:
	var p = people.get(id)
	if p != null:
		p.cough0 = t


# Whether they're free for something of their own (world/doings.gd): not talking or about to, not
# laughing, drinking, at work or told where to look.
func idle(id: String) -> bool:
	var p = people.get(id)
	if p == null:
		return false
	if not (p.talk as Array).is_empty() or not (p.job as Dictionary).is_empty() or not (p.force as Dictionary).is_empty():
		return false
	return t >= float(p.laugh0) + float(p.laugh_len) and not (p.sip as Dictionary).get("on", false)


# The bartender at her work while he watches (world/doings.gd), for secs: "wipe", the bar top round
# and round under her right hand; "pour", up to a tap's handle, drawn down while the glass fills and
# let go; "till", her fingers on its keys. point: where, in the room.
func work(id: String, kind: String, point: Vector3, secs: float) -> bool:
	var p = people.get(id)
	if p == null or not _arm(p, "R") or not (p.job as Dictionary).is_empty() or (p.sip as Dictionary).get("on", false):
		return false
	# a step in toward it, if it's further off than an easy reach (behind the bar her feet don't show):
	# along the floor toward it, as far as brings the shoulder within reach, and no further than a step
	var sk: Skeleton3D = p.sk
	var sh: Vector3 = sk.global_transform * (p.O["upper_arm.R"] as Vector3)
	var flat := Vector3(point.x - sh.x, 0.0, point.z - sh.z)
	var dy := point.y - sh.y
	var step := clampf(flat.length() - sqrt(maxf(REACH * REACH - dy * dy, 0.01)), 0.0, 0.25)
	var node: Node3D = p.node
	var local := node.global_transform.basis.orthonormalized().inverse() * (flat.normalized() * step) if flat.length() > 0.01 else Vector3.ZERO
	p.job = {"kind": kind, "point": point, "t0": t, "secs": secs, "step": Vector3(local.x, 0.0, local.z)}
	p.force = {"kind": "point", "point": point, "at": t, "until": t + minf(secs, 2.5)}
	return true


func working(id: String) -> bool:
	var p = people.get(id)
	return p != null and not (p.job as Dictionary).is_empty()


func talking(p: Dictionary) -> bool:
	var tk: Array = p.talk
	return not tk.is_empty() and t >= float(tk[0][0]) - 0.05 and t <= float(tk[tk.size() - 1][0])


# The jaw's openings for a line, 0 shut to 1 wide, against time: open on each vowel, shut on b, m
# and p, nearly on f and v, part way on the other consonants, and shut for the stops, a short one
# for a comma and a longer one for the end of a sentence. About fourteen letters a second.
func _syllables(text: String, t0: float) -> Array:
	var keys := [[t0, 0.0]]
	var tt := t0 + 0.06
	var in_vowel := false
	for ch in text.to_lower():
		if ch in "aeiouy":
			if not in_vowel:
				var o := 1.0 if ch in "ao" else (0.75 if ch == "e" else 0.55)
				keys.append([tt + 0.035, o * randf_range(0.6, 1.0)])
				tt += 0.11
			in_vowel = true
			continue
		in_vowel = false
		if ch in "bmp":
			keys.append([tt + 0.025, 0.0])
			tt += 0.07
		elif ch in "fv":
			keys.append([tt + 0.025, 0.12])
			tt += 0.06
		elif ch == " ":
			keys.append([tt + 0.02, 0.12])
			tt += 0.035
		elif ch in ",;:":
			keys.append([tt + 0.04, 0.0])
			tt += 0.22
		elif ch in ".!?":
			keys.append([tt + 0.05, 0.0])
			tt += 0.4
		elif (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			keys.append([tt + 0.025, 0.3])
			tt += 0.055
	keys.append([tt + 0.12, 0.0])
	return keys


func _talk_open(p: Dictionary) -> float:
	var tk: Array = p.talk
	while tk.size() > 1 and float(tk[1][0]) < t:
		tk.pop_front()
	if tk.is_empty() or t < float(tk[0][0]):
		return 0.0
	if tk.size() == 1:
		tk.clear()
		return 0.0
	var a: Array = tk[0]
	var b: Array = tk[1]
	var k := clampf((t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001), 0.0, 1.0)
	return lerpf(float(a[1]), float(b[1]), k)


# Every frame: eye is where the room is seen from, look the way it's looking, heads where
# everyone's head is (id -> world point; the ones without bones too).
func update(dt: float, eye: Vector3, look: Vector3, heads: Dictionary) -> void:
	t += dt
	for id in people.keys():
		var p: Dictionary = people[id]
		if not is_instance_valid(p.sk):
			remove(id)
			continue
		var sk: Skeleton3D = p.sk
		# out of the room, or too far off to see (he's across town): a glass of the table's they had up
		# goes back down
		if not sk.is_inside_tree() or not sk.is_visible_in_tree() or _head_world(p).distance_to(eye) > 25.0:
			_stop_sip(p)
			continue
		_live(p, dt, eye, look, heads)


func _head_world(p: Dictionary) -> Vector3:
	return (p.sk as Skeleton3D).global_transform * (p.eyes as Vector3)


func _live(p: Dictionary, dt: float, eye: Vector3, look: Vector3, heads: Dictionary) -> void:
	_step(p)
	var sk: Skeleton3D = p.sk
	var to_sk := sk.global_transform.affine_inverse()
	var me := sk.global_transform * (p.eyes as Vector3)
	# the eye on them: looking their way, near enough to tell
	var from_eye := me - eye
	var dist := from_eye.length()
	var on: bool = dist < 9.0 and look.angle_to(from_eye) < maxf(0.09, atan2(0.3, dist))
	p.watched = float(p.watched) + dt if on else maxf(0.0, float(p.watched) - dt * 1.5)
	if p.watched >= p.notice and not p.noticed:
		p.noticed = true
		p.until = t
	elif p.watched <= 0.0:
		p.noticed = false
	# where to look: told to, or chosen when the last look's done
	var f: Dictionary = p.force
	if not f.is_empty() and t >= float(f.at):
		_look_at(p, str(f.kind), f.get("point", null), float(f.until) - t, eye, heads)
		p.force = {}
	elif t >= float(p.until):
		_choose(p, eye, heads, me)
	# the point they're looking at now, in the skeleton's frame
	var target = null
	match str(p.kind):
		"eye":
			target = eye
		"them":
			target = heads.get(p.at, null)
			if target == null:
				p.until = t
		"point", "own", "about", "down":
			target = p.at
	var yaw := float(p.idle.x)
	var pitch := float(p.idle.y)
	var dir := Vector3.ZERO
	var aim := Vector3.ZERO
	if target != null:
		aim = to_sk * (target as Vector3)
		dir = (aim - (p.eyes as Vector3)).normalized()
		yaw = atan2(dir.dot(p.l0), dir.dot(p.f0))
		pitch = asin(clampf(dir.y, -1.0, 1.0)) - float(p.pitch0)
		var lim := HEAD_LIMIT_SEATED if p.seated else HEAD_LIMIT
		yaw = clampf(float(p.yaw0) + yaw, -lim, lim) - float(p.yaw0)
		pitch = clampf(pitch, -0.6, 0.4)
	# the head comes round after the eyes (a spring, quick or slow by the person)
	var hy_v := _spring(float(p.hy), float(p.hyv), yaw, float(p.quick), dt)
	var hp_v := _spring(float(p.hp), float(p.hpv), pitch, float(p.quick), dt)
	p.hy = hy_v.x
	p.hyv = hy_v.y
	p.hp = hp_v.x
	p.hpv = hp_v.y
	# breathing, and the weight shifting now and then
	p.breath = fmod(float(p.breath) + dt * TAU * float(p.rate), TAU)
	var br := sin(float(p.breath))
	if t >= float(p.next_shift):
		if p.seated:
			p.shift_to = Vector3(randf_range(-0.045, 0.05), randf_range(-0.012, 0.012), randf_range(-0.03, 0.03))
		else:
			p.shift_to = Vector3(randf_range(-0.012, 0.015), randf_range(-0.022, 0.022), randf_range(-0.035, 0.035))
		p.next_shift = t + randf_range(6.0, 22.0)
	p.shift = (p.shift as Vector3).lerp(p.shift_to, 1.0 - exp(-dt * 1.6))
	var sh: Vector3 = p.shift
	# the jaw, with what they're saying, or open on each "ha" of a laugh (lg how far into the laugh
	# they are, ha the shoulders' and the jaw's beat in it)
	var open := _talk_open(p)
	var lg := 0.0
	var ha := 0.0
	var ls := t - float(p.laugh0)
	if ls >= 0.0 and ls < float(p.laugh_len):
		var ll := float(p.laugh_len)
		lg = float(p.laugh_s) * smoothstep(0.0, 0.15, ls) * (1.0 - smoothstep(ll * 0.55, ll, ls))
		ha = 0.5 + 0.5 * sin(TAU * float(p.laugh_hz) * ls)
		open = maxf(open, lg * (0.3 + 0.5 * ha))
	# a cough: two jolts, the second a little less
	var cs := t - float(p.cough0)
	var cg := 0.0
	if cs >= 0.0 and cs < 0.9:
		cg = exp(-pow(cs / 0.08, 2.0)) + 0.75 * exp(-pow((cs - 0.34) / 0.08, 2.0))
		open = maxf(open, 0.4 * cg)
	var jaw_v := _spring(float(p.jaw), float(p.jawv), open, 34.0, dt)
	p.jaw = clampf(jaw_v.x, -0.05, 1.1)
	p.jawv = jaw_v.y
	# a sip, started when it's time, and how far they lean in to reach a glass on the table (or over
	# the bar, wiping it down)
	var lean := _sip_phase(p) + _work_lean(p) + 0.06 * cg
	# the turn shared out: the chest a little past a big one, then the neck and the head (which
	# keep their look as the body leans in)
	var hy: float = p.hy
	var hp: float = p.hp + (float(p.jaw) - 0.3) * 0.022 * (1.0 if open > 0.0 else 0.0) + float(p.drink) * 0.14 + lg * 0.16 - cg * 0.1
	var bounce := lg * (ha - 0.5) * 0.05
	var cmax := CHEST_MAX_SEATED if p.seated else CHEST_MAX
	var chest_y := signf(hy) * minf(maxf(absf(hy) - 0.7, 0.0) * 0.45, cmax)
	var rest_y := hy - chest_y
	var tr: Vector3 = p.tr
	var tf: Vector3 = p.tf
	var right: Vector3 = p.right
	var up: Vector3 = p.up
	var d_spine := Basis(tf, sh.y) * Basis(tr, sh.x * 0.6 + br * 0.0035 - lean * 0.6 + bounce * 0.4)
	var d_chest := Basis(Vector3.UP, chest_y + sh.z) * Basis(tr, sh.x * 0.4 + br * 0.007 - lean * 0.4 + bounce) * Basis(tf, -sh.y * 0.5)
	var d_neck := Basis(Vector3.UP, rest_y * 0.4 - sh.z * 0.5) * Basis(right, hp * 0.4 - br * 0.009 - sh.x * 0.5 + lean * 0.4) * Basis(tf, -sh.y * 0.4)
	var d_head := Basis(Vector3.UP, rest_y * 0.6) * Basis(right, hp * 0.6 + lean * 0.6)
	_turn(p, "spine", d_spine)
	_turn(p, "chest", d_chest)
	_turn(p, "neck", d_neck)
	_turn(p, "head", d_head)
	# where the joints are now, up the back from the spine (each turn carries the ones above it)
	var x_chest := d_spine * d_chest
	var x_neck := x_chest * d_neck
	var x_head := x_neck * d_head
	var o_sp: Vector3 = p.O.get("spine", p.O.chest)
	var c1: Vector3 = o_sp + d_spine * ((p.O.chest as Vector3) - o_sp)
	var n1: Vector3 = c1 + x_chest * ((p.O.neck as Vector3) - (p.O.chest as Vector3))
	var h1: Vector3 = n1 + x_neck * ((p.O.head as Vector3) - (p.O.neck as Vector3))
	# the arms kept where they were (a glass stays on the bar while they turn), but for a sip
	var keep := x_chest.inverse()
	var sipping := _sip(p, c1, x_chest, h1, x_head, tr)
	if sipping == "":
		sipping = _work(p, c1, x_chest)
	for sd in ["L", "R"]:
		if sd != sipping:
			_turn(p, "upper_arm." + sd, keep)
	_turn(p, "jaw", Basis(right, -deg_to_rad(JAW_OPEN) * maxf(float(p.jaw), 0.0)))
	# the eyes on the point, from the head as it is now, with the small drift of eyes holding a look
	if t >= float(p.drift_at):
		p.drift = Vector2(randf_range(-0.02, 0.02), randf_range(-0.012, 0.012))
		p.drift_at = t + randf_range(0.5, 1.8)
	var ey := float(p.drift.x)
	var ep := float(p.drift.y)
	if dir != Vector3.ZERO:
		# from where the eyes are now
		var eyes1: Vector3 = h1 + x_head * ((p.eyes as Vector3) - (p.O.head as Vector3))
		var dh := x_head.inverse() * (aim - eyes1).normalized()
		var lh := up.cross(p.fwd as Vector3).normalized()
		ey += atan2(dh.dot(lh), dh.dot(p.fwd))
		ep += asin(clampf(dh.dot(up), -1.0, 1.0))
	ey = clampf(ey, -EYES_YAW, EYES_YAW)
	ep = clampf(ep, -EYES_DOWN, EYES_UP)
	var d_eye := Basis(up, ey) * Basis(right, ep)
	_turn(p, "eye.L", d_eye)
	_turn(p, "eye.R", d_eye)
	# a blink now and then (and the upper lids following the eyes down)
	if t >= float(p.next_blink):
		_blink(p)
	var s := t - float(p.blink0)
	var k := 0.0
	if s < 0.075:
		k = smoothstep(0.0, 0.075, s)
	elif s < 0.11:
		k = 1.0
	elif s < 0.24:
		k = 1.0 - smoothstep(0.11, 0.24, s)
	var lid := maxf(maxf(float(p.blink_deg) * k, rad_to_deg(maxf(-ep, 0.0)) * 0.75), float(p.blink_deg) * maxf(0.45 * lg, 0.8 * minf(cg, 1.0)))
	var d_lid := Basis(right, -deg_to_rad(minf(lid, float(p.blink_deg))))
	_turn(p, "lid.L", d_lid)
	_turn(p, "lid.R", d_lid)


# A sip, for someone with a drink, every half minute or so when they aren't talking: the glass
# lifted to the mouth upright, tipped there, and put back. A glass in the hand goes straight up; one
# on the table in front of them is reached for first, leaning in for it and the hand turned to take
# it, and put back where it was. Here, the sip's time: started when it's time (for a glass on the
# table, only if there's one they can reach), and how far it's got: the hand gone to the glass on
# the table (g), the glass at the mouth (w), tipped there (tip). Returns how far they lean in.
func _sip_phase(p: Dictionary) -> float:
	var sp: Dictionary = p.sip
	p.drink = 0.0
	if sp.is_empty():
		return 0.0
	if t >= float(sp.next) and t >= float(sp.t0) + float(sp.end) and not talking(p):
		sp.next = t + randf_range(25.0, 70.0)
		if not sp.table or _take(p, sp):
			sp.t0 = t
			sp.hold = randf_range(0.8, 1.6)
			sp.r = 0.7 if sp.table else 0.0
			sp.end = 2.0 * float(sp.r) + 1.9 + float(sp.hold)
			p.until = t + float(sp.end) + 0.1
			p.idle = Vector2(0.0, -0.06)
			# an eye on the glass while the hand goes to it
			if sp.table:
				p.kind = "point"
				p.at = (sp.spot as Transform3D).origin
			else:
				p.kind = ""
				p.at = null
	var s := t - float(sp.t0)
	var hold: float = sp.hold
	var r: float = sp.r
	var end: float = sp.end
	sp.on = s >= 0.0 and s < end
	if not sp.on:
		_put_back(sp)
		if sp.get("closed", "") != "":
			(p.sk as Skeleton3D).set_bone_pose_scale(int(p.b[sp.closed]), Vector3.ONE)
			sp.closed = ""
		return 0.0
	if sp.table and s > r * 0.8 and str(p.kind) == "point":
		p.kind = ""
		p.at = null
	var g := 1.0
	if r > 0.0:
		g = smoothstep(0.0, r, s) * (1.0 - smoothstep(end - r, end, s))
	var w := smoothstep(r, r + 0.95, s) * (1.0 - smoothstep(r + 0.95 + hold, r + 1.9 + hold, s))
	sp.g = g
	sp.w = w
	sp.tip = smoothstep(r + 0.6, r + 1.1, s) * (1.0 - smoothstep(r + 0.8 + hold, r + 1.35 + hold, s))
	var was: bool = sp.get("held", false)
	sp.held = not sp.table or (s >= r and s < r + 1.9 + hold)
	# a glass from the table, down on it again: heard where it lands
	if sp.table and was and not sp.held and heard.is_valid():
		heard.call("glass_down", (sp.spot as Transform3D).origin, randf_range(0.45, 0.8), 1.0)
	p.drink = sp.tip
	# leaning in to the table for it, and back up to drink
	return float(sp.get("lean", 0.0)) * g * (1.0 - w)


# The arm for a sip, with the body as it's posed now (the chest's joint c1 and turn, the head's
# joint h1 and turn): it reaches by its two bones (the elbow kept the way it bends at rest, a little
# out and down), and the hand keeps the glass upright till it tips. Returns the side that's drinking
# ("" for none).
func _sip(p: Dictionary, c1: Vector3, x_chest: Basis, h1: Vector3, x_head: Basis, tr: Vector3) -> String:
	var sp: Dictionary = p.sip
	if sp.is_empty() or not sp.get("on", false):
		return ""
	var g: float = sp.g
	var w: float = sp.w
	var tip: float = sp.tip
	var side: String = sp.side
	var ua := "upper_arm." + side
	var fa := "forearm." + side
	var hd := "hand." + side
	var s0: Vector3 = p.O[ua]
	var e0: Vector3 = p.O[fa]
	var w0: Vector3 = p.O[hd]
	# where the shoulder is now, and where the wrist would be at rest from there
	var sh := c1 + x_chest * (s0 - (p.O.chest as Vector3))
	var rest_w := sh + (w0 - s0)
	# the glass's middle as the hand takes it, and the wrist then: in the hand already, or on the table
	var cup: Vector3 = sp.c if sp.table else sp.glass
	var grip: Vector3 = sp.grip if sp.table else w0
	var base := rest_w.lerp(grip, g) if sp.table else rest_w
	# where the wrist goes to bring the glass's middle just in front of the mouth, tipped
	var mouth := h1 + x_head * ((sp.mouth as Vector3) - (p.O.head as Vector3))
	var goal := mouth + x_head * ((p.fwd as Vector3) * 0.055 - (p.up as Vector3) * 0.02)
	var x_tip := Basis(tr, SIP_TILT * tip)
	var reach := goal - x_tip * (cup - grip)
	var target := base.lerp(reach, w)
	# the two bones to it
	var a := (e0 - s0).length()
	var b := (w0 - e0).length()
	var to := target - sh
	var d := clampf(to.length(), absf(a - b) + 0.01, a + b - 0.003)
	var u := to.normalized()
	var out := tr * (1.0 if side == "R" else -1.0)
	var pole := (e0 - s0) + (out * 0.06 + Vector3.DOWN * 0.04) * w
	pole = pole - u * pole.dot(u)
	if pole.length() < 1e-4:
		pole = Vector3.DOWN - u * Vector3.DOWN.dot(u)
	pole = pole.normalized()
	var ca := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var e1 := sh + (u * ca + pole * sqrt(1.0 - ca * ca)) * a
	var w1 := sh + u * d
	var x_ua := Basis(Quaternion((e0 - s0).normalized(), (e1 - sh).normalized()))
	var x_fa := Basis(Quaternion(x_ua * (w0 - e0).normalized(), (w1 - e1).normalized())) * x_ua
	# the hand turned on its forearm to take a glass from the table (thumb up), then tipped with it
	var x_hand := x_tip
	if sp.table:
		x_hand = x_tip * Basis((w0 - e0).normalized(), float(sp.roll) * g)
	_turn(p, ua, x_chest.inverse() * x_ua)
	_turn(p, fa, x_ua.inverse() * x_fa)
	_turn(p, hd, x_fa.inverse() * x_hand)
	# a hand made flat on the table closes round the glass (shortened along its length, which reads as
	# fingers curled)
	if sp.table:
		(p.sk as Skeleton3D).set_bone_pose_scale(int(p.b[hd]), Vector3(1.0, 1.0 - 0.4 * g, 1.0))
		sp.closed = hd
	# a glass from the table goes with the hand, from when it's taken till it's down again
	if sp.table:
		var gn = sp.node
		if gn != null and is_instance_valid(gn):
			if sp.held:
				var sk: Skeleton3D = p.sk
				var spot: Transform3D = sk.global_transform.affine_inverse() * (sp.spot as Transform3D)
				(gn as Node3D).global_transform = sk.global_transform * Transform3D(x_tip * spot.basis, w1 + x_tip * (cup - grip))
			else:
				(gn as Node3D).global_transform = sp.spot
	return side


# The bartender's right arm at her work (work), with the body as it's posed now: up from where it
# rests to the place (the bar top, a tap's handle, the till), what she does there, and back. The hand
# keeps the way it's turned at rest: flat on the bar. Returns "R" while it's at it, "" otherwise.
func _work(p: Dictionary, c1: Vector3, x_chest: Basis) -> String:
	var jb: Dictionary = p.job
	if jb.is_empty():
		return ""
	var s := t - float(jb.t0)
	var secs := float(jb.secs)
	if s > secs + 1.2:
		p.job = {}
		(p.sk as Skeleton3D).set_bone_pose_scale(int(p.b["hand.R"]), Vector3.ONE)
		return ""
	var g := smoothstep(0.0, 0.6, s) * (1.0 - smoothstep(secs + 0.5, secs + 1.2, s))
	var s0: Vector3 = p.O["upper_arm.R"]
	var w0: Vector3 = p.O["hand.R"]
	var sh := c1 + x_chest * (s0 - (p.O.chest as Vector3))
	var rest_w := sh + (w0 - s0)
	var tf: Vector3 = p.tf
	var tr: Vector3 = p.tr
	var goal := (p.sk as Skeleton3D).global_transform.affine_inverse() * (jb.point as Vector3)
	var on := smoothstep(0.5, 0.9, s)
	match str(jb.kind):
		"wipe":
			var a := s * TAU * 0.95
			goal += (tf * cos(a) * 0.07 + tr * sin(a) * 0.1) * on
		"pour":
			var pull := smoothstep(0.8, 1.15, s) * (1.0 - smoothstep(secs - 0.25, secs + 0.1, s))
			goal += (Vector3.DOWN * 0.04 - tf * 0.07) * pull
		"till":
			goal += Vector3.DOWN * 0.012 * (0.5 + 0.5 * sin(s * TAU * 3.2)) * on
	var arms := _two_bone(p, "R", sh, rest_w.lerp(goal, g), 0.0)
	# the hand as it rests (flat, for the bar top and the till's keys), or for a tap's handle turned
	# thumb up on its forearm and closed round it
	var x_hand := Basis.IDENTITY
	if str(jb.kind) == "pour":
		var e0: Vector3 = p.O["forearm.R"]
		x_hand = Basis((w0 - e0).normalized(), 1.2 * g)
		(p.sk as Skeleton3D).set_bone_pose_scale(int(p.b["hand.R"]), Vector3(1.0, 1.0 - 0.35 * g, 1.0))
	_turn(p, "upper_arm.R", x_chest.inverse() * arms[0])
	_turn(p, "forearm.R", (arms[0] as Basis).inverse() * arms[1])
	_turn(p, "hand.R", (arms[1] as Basis).inverse() * x_hand)
	return "R"


# Stepping in to a job and back again (work): the body moved along the floor under its holder.
func _step(p: Dictionary) -> void:
	var body = p.get("body")
	if body == null or not is_instance_valid(body):
		return
	var jb: Dictionary = p.job
	var to := Vector3.ZERO
	if not jb.is_empty():
		var s := t - float(jb.t0)
		to = (jb.step as Vector3) * smoothstep(0.0, 0.55, s) * (1.0 - smoothstep(float(jb.secs) + 0.45, float(jb.secs) + 1.15, s))
	if (body as Node3D).position != to:
		(body as Node3D).position = to


# how far she leans over the bar for it: a little, wiping down
func _work_lean(p: Dictionary) -> float:
	var jb: Dictionary = p.job
	if jb.is_empty() or str(jb.kind) != "wipe":
		return 0.0
	var s := t - float(jb.t0)
	return 0.07 * smoothstep(0.0, 0.6, s) * (1.0 - smoothstep(float(jb.secs) + 0.5, float(jb.secs) + 1.2, s))


# An arm's two bones to put its wrist at target, from the shoulder where it is now (sh): the elbow
# kept the way it bends at rest, out and down by `out` (a sip's a little out and down). Returns the
# upper arm's and the forearm's turns, in the skeleton's frame as it's posed, and the elbow and wrist.
func _two_bone(p: Dictionary, side: String, sh: Vector3, target: Vector3, out: float) -> Array:
	var s0: Vector3 = p.O["upper_arm." + side]
	var e0: Vector3 = p.O["forearm." + side]
	var w0: Vector3 = p.O["hand." + side]
	var a := (e0 - s0).length()
	var b := (w0 - e0).length()
	var to := target - sh
	var d := clampf(to.length(), absf(a - b) + 0.01, a + b - 0.003)
	var u := to.normalized()
	var o: Vector3 = (p.tr as Vector3) * (1.0 if side == "R" else -1.0)
	var pole := (e0 - s0) + (o * 0.06 + Vector3.DOWN * 0.04) * out
	pole = pole - u * pole.dot(u)
	if pole.length() < 1e-4:
		pole = Vector3.DOWN - u * Vector3.DOWN.dot(u)
	pole = pole.normalized()
	var ca := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var e1 := sh + (u * ca + pole * sqrt(1.0 - ca * ca)) * a
	var w1 := sh + u * d
	var x_ua := Basis(Quaternion((e0 - s0).normalized(), (e1 - sh).normalized()))
	var x_fa := Basis(Quaternion(x_ua * (w0 - e0).normalized(), (w1 - e1).normalized())) * x_ua
	return [x_ua, x_fa, e1, w1]


# Whether they've an arm to drink with on that side.
func _arm(p: Dictionary, side: String) -> bool:
	return p.b.has("upper_arm." + side) and p.b.has("forearm." + side) and p.b.has("hand." + side)


# A glass on the table for them to drink from (cups): the nearest they can reach leaning in a little,
# in front of them, that nobody else has up, taken with the hand on its side (the right, between
# two the same). False if there's none.
func _take(p: Dictionary, sp: Dictionary) -> bool:
	if cups == null or not is_instance_valid(cups):
		return false
	var to_sk := (p.sk as Skeleton3D).global_transform.affine_inverse()
	var tf: Vector3 = p.tf
	var tr: Vector3 = p.tr
	var best := []
	var bd := INF
	for g in cups.get_children():
		var gn := g as Node3D
		if gn == null or gn.is_queued_for_deletion() or gn.has_meta("held"):
			continue
		var c := to_sk * gn.global_position
		for sd in ["L", "R"]:
			if not _arm(p, sd):
				continue
			var s0: Vector3 = p.O["upper_arm." + sd]
			var to := c - s0
			# in front, below the shoulder, not over on the other side of them, and within a lean's reach
			var over := (c - (p.O.chest as Vector3)).dot(tr) * (1.0 if sd == "R" else -1.0)
			if to.dot(tf) < 0.15 or to.y > -0.12 or over < -0.1:
				continue
			var grip := _grip(p, sd, c)
			if _lean_for(p, sd, grip) < 0.0:
				continue
			var dd := to.length() - (0.03 if sd == "R" else 0.0)
			if dd < bd:
				bd = dd
				best = [gn, sd, c, grip]
	if best.is_empty():
		return false
	var gn: Node3D = best[0]
	var sd: String = best[1]
	sp.side = sd
	sp.node = gn
	sp.spot = gn.global_transform
	sp.c = best[2]
	sp.grip = best[3]
	sp.lean = _lean_for(p, sd, best[3])
	sp.roll = 1.25 if sd == "R" else -1.25
	gn.set_meta("held", p.id)
	return true


# Where the wrist goes to take a glass whose middle is at c: just behind it and to its outside (the
# palm against it), a little below its middle.
func _grip(p: Dictionary, side: String, c: Vector3) -> Vector3:
	var s0: Vector3 = p.O["upper_arm." + side]
	var h := Vector3(c.x - s0.x, 0.0, c.z - s0.z).normalized()
	var out: Vector3 = (p.tr as Vector3) * (1.0 if side == "R" else -1.0)
	return c - h * 0.055 + out * 0.045 + Vector3.DOWN * 0.02


# How far they lean in (radians at the spine and chest together) for that hand to get to the wrist
# point w: the least that does it, or -1 if leaning as far as anyone would at a table won't.
func _lean_for(p: Dictionary, side: String, w: Vector3) -> float:
	var s0: Vector3 = p.O["upper_arm." + side]
	var e0: Vector3 = p.O["forearm." + side]
	var w0: Vector3 = p.O["hand." + side]
	var o_sp: Vector3 = p.O.get("spine", p.O.chest)
	var o_c: Vector3 = p.O.chest
	var tr: Vector3 = p.tr
	var arm := ((e0 - s0).length() + (w0 - e0).length()) * 0.99
	var lean := 0.0
	while lean <= 0.5:
		var d_sp := Basis(tr, -lean * 0.6)
		var x_c := d_sp * Basis(tr, -lean * 0.4)
		if (o_sp + d_sp * (o_c - o_sp) + x_c * (s0 - o_c)).distance_to(w) <= arm:
			return lean
		lean += 0.03
	return -1.0


# A sip cut short (they're out of sight, or gone): the glass back down and the hand open.
func _stop_sip(p: Dictionary) -> void:
	var sp: Dictionary = p.sip
	if sp.is_empty():
		return
	_put_back(sp)
	if sp.get("closed", "") != "" and is_instance_valid(p.sk):
		(p.sk as Skeleton3D).set_bone_pose_scale(int(p.b[sp.closed]), Vector3.ONE)
	sp.closed = ""
	if t < float(sp.t0) + float(sp.end):
		sp.t0 = -100.0
		sp.end = 0.0
		p.drink = 0.0


# A glass from the table back where it was, and free for anyone.
func _put_back(sp: Dictionary) -> void:
	var gn = sp.get("node")
	if gn == null:
		return
	if is_instance_valid(gn):
		(gn as Node3D).global_transform = sp.spot
		(gn as Node3D).remove_meta("held")
	sp.node = null


# A critically damped spring at x (going at v) toward to, w how quick, after dt: the new x and v. Worked
# out exactly, so a long frame doesn't throw it.
static func _spring(x: float, v: float, to: float, w: float, dt: float) -> Vector2:
	var x0 := x - to
	var k := v + w * x0
	var e := exp(-w * dt)
	return Vector2(to + (x0 + k * dt) * e, (v - w * k * dt) * e)


func _blink(p: Dictionary) -> void:
	if t - float(p.blink0) < 0.45:
		return
	p.blink0 = t
	# mostly every two to five seconds, now and then a long while
	p.next_blink = t + (randf_range(1.6, 5.0) if randf() < 0.85 else randf_range(5.0, 9.0))


# Turn a bone by d, a turn in the skeleton's frame as it's posed, about the bone's own joint: its
# pose is its rest with d brought round into the bone's own frame (G⁻¹ d G).
func _turn(p: Dictionary, bone: String, d: Basis) -> void:
	if not p.b.has(bone):
		return
	var local: Basis = (p.L[bone] as Basis) * ((p.Gi[bone] as Basis) * d * (p.G[bone] as Basis))
	(p.sk as Skeleton3D).set_bone_pose_rotation(int(p.b[bone]), local.get_rotation_quaternion())


# A new look, picked among what there is to look at by how much each draws them.
func _choose(p: Dictionary, eye: Vector3, heads: Dictionary, me: Vector3) -> void:
	var node: Node3D = p.node
	var body_fwd := node.global_transform.basis * Vector3(0, 0, -1)
	body_fwd = Vector3(body_fwd.x, 0.0, body_fwd.z).normalized()
	var lim := (HEAD_LIMIT_SEATED if p.seated else HEAD_LIMIT) + 0.2
	var c: Array = []
	var to_eye := eye - me
	var d := to_eye.length()
	if d < 10.0 and _within(body_fwd, to_eye, lim) and t >= float(p.get("avoid", 0.0)):
		var w := (0.35 + 2.6 * clampf(1.0 - (d - 0.8) / 5.0, 0.0, 1.0)) * lerpf(0.35, 1.7, float(p.bold))
		if d < 1.4:
			w *= 3.0
		if talking(p):
			w *= 8.0
		if p.noticed:
			w *= 12.0
		c.append([w, "eye", null, randf_range(1.0, 3.0) * lerpf(0.45, 1.9, float(p.bold))])
	for oid in heads:
		if oid == p.id:
			continue
		var h: Vector3 = heads[oid]
		var to := h - me
		var dd := to.length()
		if dd > 3.5 or dd < 0.25 or not _within(body_fwd, to, lim):
			continue
		var w2 := 1.3
		var o = people.get(oid)
		if o != null and talking(o):
			w2 *= 6.0
		c.append([w2, "them", oid, randf_range(1.5, 5.0)])
	for k in p.own:
		c.append([float(OWN[k]), "own", node.to_global(p.own[k]), randf_range(2.0, 7.0)])
	var em: Vector3 = p.eyes_model
	if p.seated:
		c.append([0.8, "down", node.to_global(em + Vector3(randf_range(-0.15, 0.15), -0.45, -0.45)), randf_range(1.5, 4.0)])
	c.append([2.2, "", null, randf_range(2.0, 6.0)])
	var a := randf_range(-1.1, 1.1)
	c.append([0.7, "about", node.to_global(em + Vector3(-sin(a) * 3.0, randf_range(-0.3, 0.35), -cos(a) * 3.0)), randf_range(0.8, 2.2)])
	var total := 0.0
	for e in c:
		total += float(e[0])
	var r := randf() * total
	for e in c:
		r -= float(e[0])
		if r <= 0.0:
			var dwell := float(e[3])
			# the shy meet the eye and look away, and keep away from it a while
			if e[1] == "eye" and float(p.bold) < 0.3 and not talking(p):
				dwell = randf_range(0.5, 1.1)
				p.avoid = t + dwell + randf_range(2.0, 5.0)
			_look_at(p, str(e[1]), e[2], dwell, eye, heads)
			return


func _within(fwd: Vector3, to: Vector3, lim: float) -> bool:
	var h := Vector3(to.x, 0.0, to.z)
	return h.length() < 0.01 or fwd.angle_to(h) < lim


func _look_at(p: Dictionary, kind: String, at, dwell: float, eye: Vector3, heads: Dictionary) -> void:
	var before := _aim(p, eye, heads)
	p.kind = kind
	p.at = at
	p.until = t + maxf(dwell, 0.3)
	p.idle = Vector2(randf_range(-0.09, 0.09), randf_range(-0.05, 0.03)) if kind == "" else Vector2.ZERO
	var after := _aim(p, eye, heads)
	# the eyes going a long way take a blink with them, mostly
	if before != Vector3.ZERO and after != Vector3.ZERO and before.angle_to(after) > 0.45 and randf() < 0.7:
		_blink(p)


# Which way they mean to look now, in the world (zero for straight ahead).
func _aim(p: Dictionary, eye: Vector3, heads: Dictionary) -> Vector3:
	var me := _head_world(p)
	var target = null
	match str(p.kind):
		"eye":
			target = eye
		"them":
			target = heads.get(p.at, null)
		"point", "own", "about", "down":
			target = p.at
	if target == null:
		var n: Node3D = p.node
		return n.global_transform.basis * Vector3(0, 0, -1)
	return ((target as Vector3) - me).normalized()
