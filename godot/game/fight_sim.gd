# Two bodies in a fight, simulated (bible/15_FIGHTS_AND_STATS.md, section 2). No health bars and no
# timing marks: everything the player needs is in the bodies, and everything the bodies do comes
# from here, at 120 steps a second, the same seed giving the same fight.
#
# Each body has:
#   - where it stands and which way it faces, and its feet's wish to move (W A S D, or its brain);
#   - its balance: where its weight is over its feet, a spring the feet keep putting back. Blows,
#     pulls and its own big swings push it; past STUMBLE it stumbles (can't act, steps after it),
#     past FALL it's down;
#   - breath (1 full, 0 gone): every blow and hold costs some, standing still gives it back; out of
#     breath the hands come down and the blows lose their snap;
#   - shock (0 clear): what the head's taken, fading slowly; at 1 he's down, at 1.5 he's out;
#   - hurt by part: head, body, legs, arms;
#   - nerve (1 game, 0 done): down with what he takes, up with what he lands;
#   - a guard: where each hand is, in his own frame (x across him, his right +; y up from the
#     floor, metres), unless it's out throwing;
#   - grips: what each hand has hold of on the other man;
#   - the action he's in: a blow in its tell (the shoulder going back: what the other man reads),
#     its travel, and its way back; or a reach for a hold.
#
# A blow is aimed at a point on the other man, in his frame. It lands, is blocked by a hand in the
# way, is slipped by a head that's moved, or falls short. The other man is run by a brain (BRAINS)
# deciding ten times a second from what it can see, by the same rules the player plays by.
class_name FightSim
extends RefCounted

const DT := 1.0 / 120.0
const STUMBLE := 0.17           # metres of weight off the feet before he stumbles
const FALL := 0.3               # and before he goes down
const APART := 0.6             # the nearest two bodies come, chest to chest

# Each kind of blow: its share of the arm's reach, its weight, its tell and its travel (seconds, at
# full power the tell grows by TELL_POWER of itself), and how long the arm takes to come back.
const BLOWS := {
	"straight": {"reach": 1.0, "weight": 1.0, "tell": 0.16, "travel": 0.11, "back": 0.24},
	"hook": {"reach": 0.8, "weight": 1.18, "tell": 0.22, "travel": 0.14, "back": 0.3},
	"upper": {"reach": 0.72, "weight": 1.12, "tell": 0.2, "travel": 0.12, "back": 0.3},
	"kick": {"reach": 1.15, "weight": 0.9, "tell": 0.28, "travel": 0.16, "back": 0.4},    # the purrer's, at the shins
	"elbow": {"reach": 0.45, "weight": 1.3, "tell": 0.12, "travel": 0.08, "back": 0.25},
}
const TELL_POWER := 0.7

# How the other men fight. aggression: how readily they throw; tell: how long their shoulder gives
# it away (1 ordinary); defend: how often they do something about a blow they've read; react:
# seconds to read one; power: how much they put in; mix: which blows, by weight; reach_for: how
# often they take hold instead of hitting; surge: the berserker's lunges.
const BRAINS := {
	"brawler": {"aggression": 0.8, "tell": 1.5, "defend": 0.35, "react": 0.32, "power": [0.6, 1.0],
		"mix": {"hook": 5, "straight": 3, "upper": 1}, "target": {"head": 0.75, "body": 0.25}, "reach_for": 0.05, "feet": 0.3},
	"boxer": {"aggression": 0.6, "tell": 0.85, "defend": 0.7, "react": 0.22, "power": [0.35, 0.85],
		"mix": {"straight": 6, "hook": 3, "upper": 1}, "target": {"head": 0.65, "body": 0.35}, "reach_for": 0.0, "feet": 0.8},
	"purrer": {"aggression": 0.7, "tell": 1.2, "defend": 0.4, "react": 0.3, "power": [0.5, 0.9],
		"mix": {"kick": 6, "straight": 2}, "target": {"legs": 0.8, "head": 0.2}, "reach_for": 0.45, "feet": 0.4},
	"berserker": {"aggression": 1.0, "tell": 1.7, "defend": 0.1, "react": 0.4, "power": [0.8, 1.0],
		"mix": {"hook": 5, "elbow": 2, "straight": 2}, "target": {"head": 0.8, "body": 0.2}, "reach_for": 0.0, "feet": 0.2, "surge": 0.9},
	"sparring": {"aggression": 0.45, "tell": 1.25, "defend": 0.55, "react": 0.28, "power": [0.25, 0.6],
		"mix": {"straight": 5, "hook": 3, "upper": 1}, "target": {"head": 0.6, "body": 0.4}, "reach_for": 0.0, "feet": 0.6},
}


class Fighter:
	var name := ""
	var stats := {"str": 5, "con": 5, "dex": 4, "int": 4, "wis": 4, "cha": 4, "gut": 4}
	var knacks := {}               # practice.gd's knacks that touch a fight: short_one, heavy_hands, hard_head, ...
	var drinks := 0                # the drinks that show
	var brain := ""                # "" for the player
	var mass := 95.0
	var height := 1.88
	var reach := 0.74              # shoulder to fist
	var depth := 0.15              # chest, front to the middle of him (set from his build in body())
	var pos := Vector2.ZERO        # on the floor (x, z), metres
	var facing := 0.0              # radians; forward is (sin, cos)
	var vel := Vector2.ZERO
	var move := Vector2.ZERO       # the feet's wish, in his frame: x his right, y forward, each -1..1
	var bal := Vector2.ZERO        # his weight off his feet, on the floor (world)
	var bal_v := Vector2.ZERO
	var breath := 1.0
	var shock := 0.0
	var hurt := {"head": 0.0, "body": 0.0, "legs": 0.0, "arms": 0.0}
	var nerve := 1.0
	var cover := false             # forearms up by the face
	var slip := 0.0                # his head off the line: -1 his left .. 1 his right
	var slip_to := 0.0
	var guard := {"L": Vector2(-0.11, 0.0), "R": Vector2(0.12, 0.0)}   # y set from height in reset
	var act := {}                  # the action he's in (see strike / grab)
	var grips := {}                # hand -> {"part": String, "hold": 0..1}
	var pull := Vector2.ZERO       # the force his hands put through his grips, on the floor (world), newtons-ish
	var brace := Vector2.ZERO      # his own feet pushing against what's moving him (the brain's)
	var down := false
	var down_t := 0.0
	var up_at := 0.0               # when he gets up, if he's let to
	var out := false               # out cold
	var stumbling := 0.0
	var hit_first := false         # hard head: the first clean one's been taken
	var second_wind := false
	var tired := 0.0               # what the night's already taken out of him, 0..1 (sets breath's ceiling)
	# the brain's own
	var next_think := 0.0
	var next_move := 0.0
	var wait_till := 0.0
	var surge_t := 0.0
	var seen := {}                 # the other man's blow it's read: its start time
	var helpers: Array = []        # others holding him: {"hold": strength 0..1, "to": Vector2 where they pull him toward, "side": "L"/"R"}

	func fwd() -> Vector2:
		return Vector2(sin(facing), cos(facing))

	func right() -> Vector2:
		# his right, on the floor: forward turned a quarter clockwise seen from above
		return Vector2(-cos(facing), sin(facing))

	func stat(k: String) -> int:
		return int(stats.get(k, 4))

	func busy() -> bool:
		return down or stumbling > 0.0 or not act.is_empty()

	func head_y() -> float:
		return height - 0.12

	func reset_guard() -> void:
		guard = {"L": Vector2(-0.12, height - 0.2), "R": Vector2(0.13, height - 0.26)}


var a := Fighter.new()          # the player (or the first of two brains)
var b := Fighter.new()
var t := 0.0
var rng := RandomNumberGenerator.new()
var events: Array = []          # what happened since the caller last took them: {"t", "kind", ...}
var log := {}                   # the player's habits, for the champion: counts by key
var bounds := Rect2(-3.0, -3.0, 6.0, 6.0)   # the floor he can stand on
var posts: Array = []                        # people and things standing on the floor: {"pos", "r"}
var ring_r := 0.0                            # a ring of people instead of walls: past it they shove him back in
var _crowd_t := -9.0
var keep_down := false          # ring rules: a man down stays down until the round's called
var hold_breath := false


func _init(seed_v := 1) -> void:
	rng.seed = seed_v


func setup(pa: Fighter, pb: Fighter, gap := 1.4) -> void:
	a = pa
	b = pb
	a.pos = Vector2(0, -gap * 0.5)
	b.pos = Vector2(0, gap * 0.5)
	a.facing = 0.0
	b.facing = PI
	a.reset_guard()
	b.reset_guard()


func other(f: Fighter) -> Fighter:
	return b if f == a else a


func dist() -> float:
	return a.pos.distance_to(b.pos)


# A point on f's body (his frame: x across, his right +; y up) in the world, on the floor plane plus height.
static func on_body(f: Fighter, p: Vector2) -> Vector3:
	var w := f.pos + f.right() * p.x + f.fwd() * 0.12
	return Vector3(w.x, p.y, w.y)


# Which part of him a point is: jaw, head, body, legs.
static func zone(f: Fighter, p: Vector2) -> String:
	var hy := f.head_y()
	if p.y > hy + 0.14:
		return "over"
	if p.y > hy - 0.1:
		return "jaw" if absf(p.x - f.slip * 0.16) < 0.075 and p.y < hy - 0.02 else "head"
	if p.y > f.height * 0.52:
		return "body"
	return "legs"


# ---------------------------------------------------------------- what they do

# A blow: hand "L" or "R", kind from BLOWS, at a point on the other man (his frame), power 0..1.
# Returns false if he can't throw now.
func strike(f: Fighter, hand: String, kind: String, target: Vector2, power: float) -> bool:
	if f.busy() or f.out or not BLOWS.has(kind):
		return false
	if f.grips.has(hand):
		release(f, hand)
	var bl: Dictionary = BLOWS[kind]
	power = clampf(power, 0.05, 1.0)
	var tell := float(bl.tell) * (1.0 + TELL_POWER * power)
	if f.brain != "":
		tell *= float(BRAINS[f.brain].tell)
		# the man reading it: Wisdom stretches what he gets to see, and "seen it before" more
		var o := other(f)
		tell *= 1.0 + 0.05 * (o.stat("wis") - 4) + (0.25 if o.knacks.has("seen_it") else 0.0)
	else:
		# the short one: a short draw still carries his weight, and shows less
		if f.knacks.has("short_one"):
			tell *= 0.8
	tell *= 1.0 + f.shock * 0.6 + f.drinks * 0.04
	var speed: float = (0.8 + f.stat("dex") * 0.045) * lerpf(0.6, 1.0, f.breath)
	var travel := float(bl.travel) / speed
	f.act = {"kind": "strike", "hand": hand, "blow": kind, "target": target, "power": power, "t0": t,
		"tell": tell, "travel": travel, "back": float(bl.back) * (0.7 + power * 0.6), "phase": "tell", "done": false}
	f.breath = maxf(0.0, f.breath - 0.035 - 0.05 * power)
	if f == a:
		_note("blow:%s:%s" % [hand, kind])
	return true


# A reach for a hold: hand at a point on the other man. The part is what's there.
func grab(f: Fighter, hand: String, target: Vector2) -> bool:
	if f.busy() or f.out:
		return false
	var o := other(f)
	var part := _part_at(o, target, f)
	f.act = {"kind": "grab", "hand": hand, "target": target, "part": part, "t0": t, "tell": 0.05, "travel": 0.16, "back": 0.1, "phase": "tell", "done": false}
	if f == a:
		_note("grab:" + part)
	return true


func release(f: Fighter, hand: String) -> void:
	if f.grips.has(hand):
		f.grips.erase(hand)
		events.append({"t": t, "kind": "let_go", "by": f.name, "hand": hand})


func _part_at(o: Fighter, p: Vector2, by: Fighter) -> String:
	var z := zone(o, p)
	var behind := _behind(by, o)
	if z == "jaw" or z == "head" or z == "over":
		return "neck" if behind else "collar"
	if z == "body":
		if absf(p.x) > 0.19:
			return "arm_R" if p.x > 0 else "arm_L"
		return "belt" if behind else "shirt"
	return "belt"


# Whether by stands behind o (more than ~115 degrees off his front).
static func _behind(by: Fighter, o: Fighter) -> bool:
	var to := (by.pos - o.pos).normalized()
	return to.dot(o.fwd()) < -0.42


# ---------------------------------------------------------------- the step

func step(n := 1) -> void:
	for i in n:
		_step()


func _step() -> void:
	t += DT
	for f: Fighter in [a, b]:
		if f.brain != "":
			_think(f)
	for f: Fighter in [a, b]:
		_body(f)
	for f: Fighter in [a, b]:
		_act(f)
	_grips()
	_apart()


func _body(f: Fighter) -> void:
	var o := other(f)
	# breath: back when he's not working, less with what the night's taken; held (darts' button) it waits
	var ceiling: float = 1.0 - f.tired * 0.4 - f.hurt.body * 0.3
	var working := not f.act.is_empty() or not f.grips.is_empty() or f.move.length() > 0.2
	f.breath = minf(ceiling, f.breath + DT * (0.035 if working else 0.11) * (0.7 + f.stat("con") * 0.06))
	if f.breath < 0.08 and f.knacks.has("second_wind") and not f.second_wind:
		f.second_wind = true
		f.breath = 0.55
		events.append({"t": t, "kind": "second_wind", "by": f.name})
	f.shock = maxf(0.0, f.shock - DT * (0.03 + f.stat("con") * 0.004))
	f.slip = move_toward(f.slip, f.slip_to, DT * (5.0 + f.stat("dex") * 0.4))
	if f.down:
		f.down_t += DT
		f.vel *= 0.8
		if not f.out and not keep_down and t >= f.up_at:
			f.down = false
			f.bal = Vector2.ZERO
			f.bal_v = Vector2.ZERO
			events.append({"t": t, "kind": "up", "by": f.name})
		return
	# facing: round to the other man, as quick as his feet let him, unless he's stumbling or held
	var to := o.pos - f.pos
	if to.length() > 0.01 and f.stumbling <= 0.0:
		var want := atan2(to.x, to.y)
		var turn := (4.0 + f.stat("dex") * 0.3) * (0.4 if not f.grips.is_empty() or _held(f) else 1.0)
		f.facing = rotate_toward(f.facing, want, turn * DT)
	# the feet
	var speed: float = (1.0 + f.stat("dex") * 0.06) * lerpf(0.5, 1.0, f.breath) * (1.0 - f.hurt.legs * 0.5) * (95.0 / f.mass) ** 0.3
	if f.knacks.has("the_angle") and absf(f.move.x) > 0.3:
		speed *= 1.25
	var wish := f.right() * f.move.x + f.fwd() * f.move.y
	if wish.length() > 1.0:
		wish = wish.normalized()
	if f.stumbling > 0.0:
		f.stumbling -= DT
		wish = f.bal.normalized() * 0.9 if f.bal.length() > 0.01 else Vector2.ZERO
		speed *= 1.1
	f.vel = f.vel.lerp(wish * speed, minf(1.0, DT * 9.0))
	# balance: a spring back over the feet, stiffer with good legs and breath, and the feet catching
	# it when they step the way it's going
	var k: float = (55.0 + f.stat("con") * 2.0 + f.stat("dex") * 2.0) * (1.0 - f.hurt.legs * 0.4) * lerpf(0.55, 1.0, f.breath) * (1.0 - minf(0.6, f.shock * 0.5))
	if f.drinks > 0:
		k *= maxf(0.55, 1.0 - f.drinks * 0.05)
	# held, his feet aren't his own: softer, and slower to settle
	var damp := 0.55
	if not other(f).grips.is_empty():
		k *= 0.75
		damp = 0.24
	var catch := maxf(0.0, wish.normalized().dot(f.bal.normalized())) * 0.5 if f.bal.length() > 0.02 and wish.length() > 0.1 else 0.0
	if not other(f).grips.is_empty():
		catch *= 0.3
	var acc: Vector2 = -f.bal * k * (1.0 + catch) - f.bal_v * 2.0 * sqrt(k) * damp
	# the helpers holding him: they drag his weight toward where they want him, and damp it
	for h in f.helpers:
		var hold := float(h.get("hold", 0.5))
		var hto: Vector2 = h.get("to", f.pos)
		var pull_h := (hto - f.pos)
		if pull_h.length() > 1.0:
			pull_h = pull_h.normalized()
		acc += pull_h * hold * 6.0 - f.bal_v * hold * 3.0
		f.vel *= 1.0 - minf(0.5, hold * DT * 6.0)
	acc += f.brace * (80.0 / f.mass)
	f.bal_v += acc * DT
	f.bal += f.bal_v * DT
	# the weight moves the body too: a man pushed steps where he's pushed
	f.pos += (f.vel + f.bal_v * 0.55) * DT
	_keep_in(f)
	var off := f.bal.length()
	if off > FALL:
		_fall(f, f.bal.normalized(), "balance")
	elif off > STUMBLE and f.stumbling <= 0.0:
		f.stumbling = 0.25 + off
		if not f.act.is_empty() and str(f.act.phase) == "tell":
			f.act = {}
		events.append({"t": t, "kind": "stumble", "by": f.name})


func _held(f: Fighter) -> bool:
	return not other(f).grips.is_empty() or not f.helpers.is_empty()


func _fall(f: Fighter, dir: Vector2, why: String) -> void:
	if f.down:
		return
	f.down = true
	f.down_t = 0.0
	f.act = {}
	f.grips.clear()
	f.stumbling = 0.0
	f.up_at = t + 1.6 + f.shock * 3.0 + rng.randf() * 0.8
	f.bal = dir * FALL
	f.bal_v = Vector2.ZERO
	var o := other(f)
	for hnd in o.grips.keys():
		if str(o.grips[hnd].part) != "neck":
			o.grips.erase(hnd)
	if f.shock >= 1.5:
		f.out = true
	f.nerve = maxf(0.0, f.nerve - 0.25)
	events.append({"t": t, "kind": "down", "by": f.name, "why": why, "dir": dir, "out": f.out})


func _act(f: Fighter) -> void:
	if f.act.is_empty():
		return
	var ac := f.act
	var age := t - float(ac.t0)
	match str(ac.phase):
		"tell":
			if age >= float(ac.tell):
				ac.phase = "go"
				events.append({"t": t, "kind": "throw", "by": f.name, "blow": ac.get("blow", "grab"), "hand": ac.hand})
		"go":
			if age >= float(ac.tell) + float(ac.travel):
				ac.phase = "back"
				if ac.kind == "strike":
					_land(f, ac)
				else:
					_take_hold(f, ac)
		"back":
			if age >= float(ac.tell) + float(ac.travel) + float(ac.back):
				f.act = {}


# The blow arrives. Short, slipped, blocked or clean.
func _land(f: Fighter, ac: Dictionary) -> void:
	var o := other(f)
	var bl: Dictionary = BLOWS[ac.blow]
	var power := float(ac.power)
	var dir := (o.pos - f.pos).normalized()
	var d := f.pos.distance_to(o.pos)
	var reach := f.reach * float(bl.reach) + 0.2
	var ev := {"t": t, "kind": "blow", "by": f.name, "on": o.name, "blow": ac.blow, "hand": ac.hand, "power": power}
	if o.down:
		ev.result = "short"
		events.append(ev)
		return
	if d > reach + 0.05:
		# short: the arm goes out into nothing and takes his weight after it
		f.bal_v += dir * (0.25 + power * 0.6)
		ev.result = "short"
		events.append(ev)
		return
	# where it really goes: his eye and hand, the drink, his bell rung, his breath
	var sigma := 0.012 + 0.028 * (1.0 - f.stat("dex") / 10.0) + 0.06 * f.shock + 0.012 * f.drinks + 0.03 * (1.0 - f.breath)
	var aim: Vector2 = ac.target + Vector2(rng.randfn(0.0, sigma), rng.randfn(0.0, sigma))
	var z := zone(o, aim)
	ev.zone = z
	if z == "over":
		ev.result = "miss"
		f.bal_v += dir * power * 0.3
		events.append(ev)
		return
	# slipped: the head isn't where it was
	if (z == "head" or z == "jaw") and absf(aim.x - o.slip * 0.16) > 0.13:
		ev.result = "slipped"
		f.bal_v += dir * power * 0.35
		events.append(ev)
		if o == a:
			_note("slip:" + ("L" if o.slip < 0 else "R"))
		return
	# blocked: a hand in the way (not one that's out throwing); covered up, the forearms take the head
	var blocked := false
	for hnd in ["L", "R"]:
		if o.grips.has(hnd):
			continue
		if not o.act.is_empty() and str(o.act.get("hand", "")) == hnd and str(o.act.phase) != "tell":
			continue
		var g: Vector2 = o.guard[hnd]
		var r := 0.085
		if o.cover:
			r = 0.15
		if ac.blow == "hook":
			# a hook comes round the side: the hand on that side has to be up by the head
			if signf(aim.x) == signf(g.x) and absf(g.y - aim.y) < r + 0.05 and absf(g.x) > 0.04:
				blocked = true
		elif g.distance_to(aim) < r:
			blocked = true
	if o.cover and (z == "head" or z == "jaw") and ac.blow != "upper":
		blocked = true
	var force: float = power * (0.55 + f.stat("str") * 0.07) * float(bl.weight) * lerpf(0.55, 1.0, f.breath) * sqrt(f.mass / 90.0)
	if ac.hand == "L" and ac.blow == "straight":
		force *= 0.7
	if f.knacks.has("short_one"):
		force = maxf(force, 0.55 * (0.55 + f.stat("str") * 0.07) * float(bl.weight))
	# caught coming in: walking onto it doubles what it does
	if not o.act.is_empty() and o.act.kind == "strike" and str(o.act.phase) != "back":
		force *= 1.35
		ev.counter = true
	if f.drinks > 2:
		force *= 0.92
	ev.force = force
	var push := dir * force * 0.55 * (90.0 / o.mass)
	if blocked:
		o.hurt.arms = minf(1.0, o.hurt.arms + force * 0.03)
		o.shock += force * 0.03
		o.bal_v += push * 0.35
		o.breath = maxf(0.0, o.breath - 0.015)
		ev.result = "blocked"
		events.append(ev)
		if o == a:
			_note("covered")
		return
	var chin := 0.15 + o.stat("con") * 0.035
	var shock := 0.0
	match z:
		"jaw":
			shock = force * 0.62 * (1.0 - chin)
			o.hurt.head = minf(1.0, o.hurt.head + force * 0.06)
		"head":
			shock = force * 0.36 * (1.0 - chin)
			o.hurt.head = minf(1.0, o.hurt.head + force * 0.05)
		"body":
			shock = force * 0.04
			o.breath = maxf(0.0, o.breath - force * 0.28)
			o.hurt.body = minf(1.0, o.hurt.body + force * 0.08)
		"legs":
			shock = 0.0
			o.hurt.legs = minf(1.0, o.hurt.legs + force * 0.09)
			o.bal_v += dir.orthogonal() * force * 0.2 * (1.0 if rng.randf() < 0.5 else -1.0)
	if f.knacks.has("heavy_hands"):
		shock *= 1.2
	if o.knacks.has("hard_head") and not o.hit_first and shock > 0.0:
		o.hit_first = true
		shock *= 0.25
		ev.hard_head = true
	o.shock += shock
	o.bal_v += push * (1.4 if z == "jaw" else 1.0)
	o.nerve = maxf(0.0, o.nerve - force * 0.06 - shock * 0.2)
	f.nerve = minf(1.0, f.nerve + force * 0.03)
	# a man hit as he throws loses the blow
	if not o.act.is_empty() and str(o.act.phase) == "tell" and force > 0.35:
		o.act = {}
	ev.result = "clean"
	ev.shock = shock
	events.append(ev)
	if o.shock >= 1.0:
		_fall(o, dir, "shock")


func _take_hold(f: Fighter, ac: Dictionary) -> void:
	var o := other(f)
	var d := f.pos.distance_to(o.pos)
	var ev := {"t": t, "kind": "grab", "by": f.name, "hand": ac.hand, "part": ac.part}
	if o.down or d > f.reach + 0.28:
		ev.result = "short"
		events.append(ev)
		return
	# he can knock it off: his hands quicker than yours, and not busy
	var knock := 0.12 + (o.stat("dex") - f.stat("dex")) * 0.04
	if not o.act.is_empty() or o.stumbling > 0.0 or o.shock > 0.4:
		knock -= 0.2
	if o.helpers.size() > 0:
		knock -= 0.3
	if rng.randf() < knock:
		ev.result = "knocked off"
		events.append(ev)
		return
	f.grips[ac.hand] = {"part": ac.part, "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO, "circle": 0.0}
	ev.result = "held"
	events.append(ev)


# What hands on him do: the pull goes into his weight (the circle building on itself), the choke
# takes his breath, and he fights the grip off.
func _grips() -> void:
	for f: Fighter in [a, b]:
		var o := other(f)
		if f.grips.is_empty():
			continue
		if o.down and not _choking(f):
			for hnd in f.grips.keys():
				if str(f.grips[hnd].part) != "neck":
					f.grips.erase(hnd)
			if f.grips.is_empty():
				continue
		var holds := 0.0
		for hnd in f.grips:
			holds += float(f.grips[hnd].hold)
		# the pull: what he's putting through his hands, measured against the other man's mass. A pull
		# that turns round and round (the circle) builds: each turn the same way adds to it.
		var p: Vector2 = f.pull
		if p.length() > 0.01:
			var g0: Dictionary = f.grips.values()[0]
			var last: Vector2 = g0.last
			if last.length() > 0.01:
				var da := last.angle_to(p)
				if absf(da) > 0.004:
					g0.ang = float(g0.ang) * 0.985 + da
				else:
					g0.ang = float(g0.ang) * 0.97
			g0.last = p
			var turning := absf(float(g0.ang))
			var circle := 1.0 + minf(2.4, turning / (2.0 if f.knacks.has("circle_closes") else 2.8))
			g0.circle = circle
			var force: Vector2 = p * holds * circle * (0.7 + f.stat("str") * 0.06) * lerpf(0.6, 1.0, f.breath)
			o.bal_v += force * (1.0 / o.mass) * 60.0 * DT
			f.bal_v -= force * (1.0 / f.mass) * 15.0 * DT
			# a turn round him turns him: his facing goes round with the circle
			if turning > 0.8:
				o.facing += signf(float(g0.ang)) * minf(2.0, turning * 0.25) * DT
			f.breath = maxf(0.0, f.breath - DT * 0.04 * p.length() / 4.0)
			if f == a and turning > 3.0 and not g0.has("noted"):
				g0.noted = true
				_note("circle")
		# the choke: both hands on the neck from behind
		if _choking(f):
			o.breath = maxf(0.0, o.breath - DT * 0.32 * (0.7 + f.stat("str") * 0.05))
			o.shock += DT * (0.25 if o.breath <= 0.0 else 0.0)
			if o.breath <= 0.0 and not o.out:
				o.out = true
				_fall(o, -o.fwd(), "choke")
				o.out = true
				events.append({"t": t, "kind": "gone", "by": o.name})
			if o.out:
				o.hurt.head = minf(1.0, o.hurt.head + DT * 0.12)
				if not f.grips.values()[0].has("past"):
					f.grips.values()[0].past = 0.0
				f.grips.values()[0].past = float(f.grips.values()[0].past) + DT
		# his struggle against it
		var fight_off := (0.12 + o.stat("str") * 0.03) * lerpf(0.3, 1.0, o.breath) * (0.2 if o.out or o.down else 1.0)
		if o.helpers.size() > 0:
			fight_off *= 0.5
		for hnd in f.grips.keys():
			var g: Dictionary = f.grips[hnd]
			g.hold = float(g.hold) - DT * fight_off / (0.6 + f.stat("str") * 0.08) * 0.35
			if float(g.hold) <= 0.0:
				f.grips.erase(hnd)
				events.append({"t": t, "kind": "broke_grip", "by": o.name, "hand": hnd})


func _choking(f: Fighter) -> bool:
	if f.grips.size() < 2:
		return false
	for hnd in f.grips:
		if str(f.grips[hnd].part) != "neck":
			return false
	return true


func choke_past(f: Fighter) -> float:
	if not _choking(f):
		return 0.0
	return float(f.grips.values()[0].get("past", 0.0))


# The nearest two bodies come: their chests and the forearms between them. Close in a clinch, when
# one has hold of the other; never through each other, never through a wall or the ring of people.
func apart_now() -> float:
	var room := 0.34 if (a.grips.is_empty() and b.grips.is_empty()) else 0.24
	return maxf(APART if room > 0.3 else 0.52, a.depth + b.depth + room)


func _apart() -> void:
	var want := apart_now()
	for it in 3:
		var d := b.pos - a.pos
		var l := d.length()
		if l < want and l > 0.0001:
			var n := d / l
			var push := (want - l)
			var wa := b.mass / (a.mass + b.mass)
			# a man against the wall can't give: the other takes it all
			var a_pinned := _at_edge(a, -n)
			var b_pinned := _at_edge(b, n)
			if a_pinned and not b_pinned:
				wa = 0.0
			elif b_pinned and not a_pinned:
				wa = 1.0
			a.pos -= n * push * wa
			b.pos += n * push * (1.0 - wa)
			# what's closing the gap stops: no velocity into each other
			var va := a.vel.dot(n)
			if va > 0.0:
				a.vel -= n * va
			var vb := b.vel.dot(-n)
			if vb > 0.0:
				b.vel += n * vb
		_keep_in(a)
		_keep_in(b)


# would a step this way take him out of the floor?
func _at_edge(f: Fighter, dir: Vector2) -> bool:
	var p := f.pos + dir * 0.03
	if ring_r > 0.0:
		return p.length() > ring_r
	return not bounds.grow(-0.001).has_point(p)


func _keep_in(f: Fighter) -> void:
	for p in posts:
		var pp: Vector2 = p.pos
		var r := float(p.r) + f.depth + 0.05
		var d := f.pos - pp
		if d.length() < r:
			var n := d.normalized() if d.length() > 0.001 else Vector2.RIGHT
			f.pos = pp + n * r
			var into := f.vel.dot(-n)
			if into > 0.0:
				f.vel += n * into
			var bi := f.bal_v.dot(-n)
			if bi > 0.0:
				f.bal_v += n * bi * 1.2
	if ring_r > 0.0:
		var l := f.pos.length()
		if l > ring_r:
			var n := f.pos / l
			f.pos = n * ring_r
			var out := f.vel.dot(n)
			if out > 0.0:
				f.vel -= n * out * 1.6
			# the people round the ring put their hands on him and shove him back in
			f.bal_v -= n * 0.35
			if t - _crowd_t > 1.2:
				_crowd_t = t
				events.append({"t": t, "kind": "crowd", "by": f.name})
		return
	var c := Vector2(clampf(f.pos.x, bounds.position.x, bounds.end.x), clampf(f.pos.y, bounds.position.y, bounds.end.y))
	if c != f.pos:
		var n := (f.pos - c).normalized()
		f.pos = c
		var out := f.vel.dot(n)
		if out > 0.0:
			f.vel -= n * out
		# into the rail or the wall: it stops him, and his weight with him
		var bo := f.bal_v.dot(n)
		if bo > 0.0:
			f.bal_v -= n * bo * 1.4
			if bo > 0.5 and t - _crowd_t > 0.6:
				_crowd_t = t
				events.append({"t": t, "kind": "wall", "by": f.name, "force": bo})


# ---------------------------------------------------------------- the brains

func _think(f: Fighter) -> void:
	var br: Dictionary = BRAINS[f.brain]
	var o := other(f)
	# reading the other man's blow: once it's been in its tell long enough for him to see it
	if not o.act.is_empty() and o.act.kind == "strike":
		var key := str(o.act.t0)
		if not f.seen.has(key):
			var react := float(br.react) * (1.0 + f.shock + f.drinks * 0.05) * (1.0 - (f.stat("wis") - 4) * 0.04)
			if t - float(o.act.t0) >= react:
				f.seen[key] = true
				if rng.randf() < float(br.defend) * (1.0 - f.shock * 0.5) and not f.down and f.stumbling <= 0.0:
					_defend(f, o.act)
	if t < f.next_think or f.down or f.out:
		if f.down:
			f.move = Vector2.ZERO
		return
	f.next_think = t + 0.1
	var d := f.pos.distance_to(o.pos)
	# the guard back up when the moment's past
	if f.cover and rng.randf() < 0.25:
		f.cover = false
	if absf(f.slip_to) > 0.0 and rng.randf() < 0.35:
		f.slip_to = 0.0
	if f.act.is_empty() and rng.randf() < 0.2:
		f.reset_guard()
	# held: brace against the pull, and try to strike or tear free
	if _held(f):
		f.brace = -o.pull.normalized() * 0.6 if o.pull.length() > 0.1 else f.brace * 0.8
	else:
		f.brace = Vector2.ZERO
	# the berserker surges: lunges at whatever's in front of him
	if br.has("surge") and t >= f.surge_t:
		f.surge_t = t + rng.randf_range(0.9, 2.2)
		var ang := rng.randf_range(-1.2, 1.2)
		var sd := f.fwd().rotated(ang)
		f.bal_v += sd * float(br.surge) * 1.1 * (1.0 if f.helpers.is_empty() else 1.5)
		events.append({"t": t, "kind": "surge", "by": f.name, "dir": sd})
	# feet: in to range, out of it when hurt, round now and then
	var want := f.reach + 0.12
	if t >= f.next_move:
		f.next_move = t + rng.randf_range(0.25, 0.7)
		var mx := 0.0
		if rng.randf() < float(br.feet) * 0.6:
			mx = rng.randf_range(-1.0, 1.0)
		var my := 0.0
		if d > want + 0.15:
			my = 1.0 * float(br.aggression)
		elif d < want - 0.25:
			my = -0.6
		if f.nerve < 0.25 and rng.randf() < 0.5:
			my = -1.0
		f.move = Vector2(mx, my)
	if f.busy() or t < f.wait_till or f.breath < 0.15:
		return
	if f.nerve < 0.08 and f.brain != "berserker":
		return
	# take hold, or throw
	if d < f.reach + 0.3 and rng.randf() < float(br.reach_for) * 0.4:
		var part := Vector2(0.18 * (1.0 if rng.randf() < 0.5 else -1.0), o.height - 0.38)
		grab(f, "L" if rng.randf() < 0.5 else "R", part)
		f.wait_till = t + 0.4
		return
	if d > f.reach + 0.35:
		return
	if rng.randf() > float(br.aggression) * 0.35:
		return
	var kind := _pick(br.mix)
	var where := _pick(br.target)
	var tgt := Vector2(rng.randf_range(-0.06, 0.06), o.head_y() - 0.04)
	if where == "body":
		tgt = Vector2(rng.randf_range(-0.14, 0.14), o.height * 0.66)
	elif where == "legs" or kind == "kick":
		tgt = Vector2(rng.randf_range(-0.15, 0.15), 0.35)
		kind = "kick"
	if kind == "hook":
		tgt.x = 0.1 * (1.0 if rng.randf() < 0.5 else -1.0)
	var hand := "R" if rng.randf() < 0.55 else "L"
	var pw: Array = br.power
	strike(f, hand, kind, tgt, rng.randf_range(float(pw[0]), float(pw[1])))
	f.wait_till = t + rng.randf_range(0.15, 0.9) / float(br.aggression)


func _defend(f: Fighter, ac: Dictionary) -> void:
	var tgt: Vector2 = ac.target
	var z := zone(f, tgt)
	var r := rng.randf()
	if (z == "head" or z == "jaw") and r < 0.4:
		f.slip_to = -1.0 if tgt.x > 0 else 1.0
		if rng.randf() < 0.5:
			f.slip_to *= -1.0
	elif r < 0.75:
		# a hand to where it's going
		var hnd := "R" if tgt.x > 0 else "L"
		f.guard[hnd] = Vector2(clampf(tgt.x, -0.18, 0.18), tgt.y)
		if z == "head" or z == "jaw":
			f.cover = rng.randf() < 0.4
	else:
		f.move = Vector2(rng.randf_range(-0.5, 0.5), -1.0)


func _pick(weights: Dictionary) -> String:
	var tot := 0.0
	for k in weights:
		tot += float(weights[k])
	var r := rng.randf() * tot
	for k in weights:
		r -= float(weights[k])
		if r <= 0.0:
			return str(k)
	return str(weights.keys()[0])


func _note(key: String) -> void:
	log[key] = int(log.get(key, 0)) + 1


# what happened since last asked
func take_events() -> Array:
	var e := events
	events = []
	return e


# ---------------------------------------------------------------- making them

# A body for a stats dictionary and a size: height (m) sets reach and, with build (0 lean .. 1
# heavy), mass.
static func body(name_v: String, stats_v: Dictionary, height_v := 1.85, build := 0.5, brain_v := "") -> Fighter:
	var f := Fighter.new()
	f.name = name_v
	f.stats = stats_v.duplicate()
	f.height = height_v
	f.reach = height_v * 0.4
	f.mass = lerpf(68.0, 112.0, build) * pow(height_v / 1.8, 2.4)
	f.depth = 0.12 + 0.05 * build * (height_v / 1.85)
	f.brain = brain_v
	f.reset_guard()
	return f
