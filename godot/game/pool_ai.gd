# The other player at the table: how he thinks a shot, on the same physics the player's shots go
# through (game/pool_sim.gd), and how his hands let him down. game/pool.gd runs plan() on a thread
# while he walks round the table and chalks.
#
# He thinks the way a fair bar player does: every ball he can hit and every pocket it could go in,
# the ones that are on (the line to it clear, the cut not too thin), then he tries each one in his
# head at a few paces and with the cue ball stunned, followed or drawn, putting his aim right for
# the throw the way a player's arm learns to, and asks of each: does it go, and where's the cue ball
# then, for the next one. He weighs how sure he is of it against what it leaves; if nothing's on
# well enough, he plays safe: a good hit that leaves the other man nothing. Then his hands: every
# player has his own spread on the aim, the pace and the tip, and his own ways.
class_name PoolAI
extends RefCounted

const HOUSE_CUE := {"M": 0.54, "end": 0.0075, "e": 0.75, "limit": 0.55}

# Who's playing: their hands and their ways.
#   aim     the spread of his aim, degrees
#   pace    of his pace, as a part of it
#   tip     of where his tip lands, parts of the radius
#   firm    how hard he likes to hit it (1 normal)
#   think   how many shots he weighs (more: better choices)
#   safe    how readily he plays safe instead of going for a hard one (0 never, 1 always)
#   english whether he uses side
#   throws  he misses the ones that matter on purpose (the big man, tonight)
const PEOPLE := {
	"bigman": {"name": "The big man", "aim": 0.32, "pace": 0.08, "tip": 0.05, "firm": 1.0, "think": 7, "safe": 0.3, "english": false, "throws": true, "lefty": true},
	"bigman_straight": {"name": "The big man", "aim": 0.26, "pace": 0.07, "tip": 0.04, "firm": 1.0, "think": 8, "safe": 0.45, "english": true, "throws": false, "lefty": true},
	"buddy": {"name": "The buddy", "aim": 0.55, "pace": 0.12, "tip": 0.07, "firm": 1.35, "think": 5, "safe": 0.1, "english": false, "throws": false},
	"scratch": {"name": "Scratch", "aim": 0.9, "pace": 0.15, "tip": 0.08, "firm": 0.75, "think": 4, "safe": 0.0, "english": false, "throws": false},
	"hivis": {"name": "Hi-vis", "aim": 0.7, "pace": 0.2, "tip": 0.1, "firm": 1.8, "think": 4, "safe": 0.0, "english": false, "throws": false},
	"cook": {"name": "The cook", "aim": 0.42, "pace": 0.09, "tip": 0.05, "firm": 1.1, "think": 7, "safe": 0.25, "english": true, "throws": false},
	"goodshoes": {"name": "Good Shoes", "aim": 0.85, "pace": 0.16, "tip": 0.09, "firm": 0.9, "think": 4, "safe": 0.05, "english": true, "throws": false},
	"nanaimo": {"name": "The man from Nanaimo", "aim": 0.2, "pace": 0.05, "tip": 0.03, "firm": 1.0, "think": 9, "safe": 0.55, "english": true, "throws": false},
	"nanaimo_dumb": {"name": "The man from Nanaimo", "aim": 0.75, "pace": 0.12, "tip": 0.06, "firm": 1.1, "think": 5, "safe": 0.0, "english": false, "throws": false},
	"jim": {"name": "Jim", "aim": 0.38, "pace": 0.06, "tip": 0.03, "firm": 0.85, "think": 8, "safe": 0.6, "english": false, "throws": false},
}

var me: Dictionary = PEOPLE.buddy
var rng := RandomNumberGenerator.new()
var thrown := 0                         # how many he's missed on purpose this game
var sims_run := 0


func _init(who := "buddy", seed_v := 7) -> void:
	me = PEOPLE.get(who, PEOPLE.buddy)
	rng.seed = seed_v


# ---------------------------------------------------------------- the plan

# What he'll do: {"dir", "elev", "a", "b", "speed", "place" (Vector3 or null), "call" (pocket or -1),
# "target", "kind" (pot, safe, break, throw), "sure" (how sure he is it goes)}. The shot he means,
# before his hands; hands() puts his spread on it.
func plan(sim0: PoolSim, rules: PoolRules) -> Dictionary:
	sims_run = 0
	var place = null
	if rules.in_hand != "":
		if not rules.broke:
			place = Vector3(sim0.table.head_spot().x - 0.02, 0, rng.randf_range(-0.18, 0.18))
		else:
			place = _choose_place(sim0, rules)
	var sim := _with_cue_at(sim0, place)
	if not rules.broke:
		return _break(sim, rules, place)
	var cands := _candidates(sim, rules)
	var best := {}
	var best_v := -INF
	var safeties: Array = []
	var n := mini(cands.size(), int(me.think))
	for ci in n:
		var c: Dictionary = cands[ci]
		for pace in _paces(sim, c):
			var aim := _corrected_aim(sim, rules, c, pace)
			for tip in _tips():
				var shot := {"dir": aim, "elev": deg_to_rad(4.0), "a": 0.0, "b": tip, "speed": pace, "target": c.target, "pocket": c.pocket}
				var out := _try(sim, rules, shot)
				var v := _value(sim, rules, out, c)
				if out.legal and not out.potted_target:
					safeties.append([out.opp_ease, shot])
				if v > best_v:
					best_v = v
					best = shot
					best["out"] = out
	# how sure: the best few again with his own spread on them
	var sure := 0.0
	if not best.is_empty() and best.out.potted_target:
		var made := 0
		for k in 4:
			var jittered := hands(best, 1.0)
			var o := _try(sim, rules, jittered)
			if o.potted_target and o.legal:
				made += 1
		sure = made / 4.0
	var go_safe: bool = best.is_empty() or not best.out.potted_target or (sure < 0.5 and rng.randf() < float(me.safe))
	var plan := {}
	if go_safe and not safeties.is_empty():
		safeties.sort_custom(func(a, b): return a[0] < b[0])
		plan = safeties[0][1].duplicate()
		plan["kind"] = "safe"
	elif not best.is_empty():
		plan = best.duplicate()
		plan["kind"] = "pot"
	else:
		# nothing at all: hit the nearest ball he may hit, firmly, and hope
		var tg := rules.targets(sim)
		var cb := sim.ball(PoolRules.CUE)
		var near := -1
		var nd := INF
		for id in tg:
			var d := cb.p.distance_to(sim.ball(id).p)
			if d < nd:
				nd = d
				near = id
		var to := (sim.ball(near).p - cb.p) if near >= 0 else Vector3(1, 0, 0)
		plan = {"dir": Vector3(to.x, 0, to.z).normalized(), "elev": deg_to_rad(4.0), "a": 0.0, "b": 0.0, "speed": 3.0, "target": near, "pocket": -1, "kind": "hope"}
	plan.erase("out")
	plan["place"] = place
	plan["sure"] = sure
	plan["call"] = plan.get("pocket", -1) if rules.needs_call(sim) else -1
	# the big man, tonight: the ones that matter, he misses. The eight above all.
	if bool(me.get("throws", false)) and plan.kind == "pot" and _matters(sim, rules):
		plan.dir = plan.dir.rotated(Vector3.UP, deg_to_rad(rng.randf_range(1.6, 2.6)) * (1.0 if rng.randf() < 0.5 else -1.0))
		plan.kind = "throw"
		thrown += 1
	return plan


# His hands on the shot he means: the aim, the pace and the tip each a little off, by how good he
# is. k scales it (the drink, the nerves).
func hands(shot: Dictionary, k := 1.0) -> Dictionary:
	var s := shot.duplicate()
	var ang := deg_to_rad(float(me.aim)) * _gauss() * k
	s.dir = (s.dir as Vector3).rotated(Vector3.UP, ang)
	s.speed = float(s.speed) * (1.0 + float(me.pace) * _gauss() * k)
	s.a = float(s.a) + float(me.tip) * _gauss() * k
	s.b = float(s.b) + float(me.tip) * _gauss() * k
	return s


func _gauss() -> float:
	return clampf(rng.randfn(0.0, 1.0), -2.5, 2.5)


# ---------------------------------------------------------------- what's on

# Every ball he may hit, into every pocket, that's on: [{target, pocket, ghost, cut, ease}], best first.
func _candidates(sim: PoolSim, rules: PoolRules) -> Array:
	var cb := sim.ball(PoolRules.CUE)
	var out := []
	for id in rules.targets(sim):
		var b := sim.ball(id)
		for k in sim.table.pockets.size():
			var e := _ease(sim, cb.p, b, k)
			if e.ease > 0.0:
				e["target"] = id
				e["pocket"] = k
				out.append(e)
	out.sort_custom(func(a, b): return a.ease > b.ease)
	return out


# How makeable a ball is into a pocket from where the cue ball is: 0 if it isn't on at all.
func _ease(sim: PoolSim, from: Vector3, b: PoolSim.Ball, k: int) -> Dictionary:
	var cb := sim.ball(PoolRules.CUE)
	var pk: Array = sim.table.pockets[k]
	var aim_at: Vector3 = (pk[0] + pk[2]) * 0.5
	var u := Vector3(aim_at.x - b.p.x, 0, aim_at.z - b.p.z)
	var d2 := u.length()
	u = u / maxf(d2, 1e-6)
	# the pocket has to be open from the ball's side: not coming at a corner along its rail
	var mouth_dir: Vector3 = Vector3(pk[0].x - pk[2].x, 0, pk[0].z - pk[2].z).normalized()
	if u.dot(mouth_dir) < 0.35:
		return {"ease": 0.0}
	var ghost := b.p - u * (b.r + cb.r)
	var to_g := Vector3(ghost.x - from.x, 0, ghost.z - from.z)
	var d1 := to_g.length()
	if d1 < 0.005:
		return {"ease": 0.0}
	var cut := acos(clampf(to_g.normalized().dot(u), -1.0, 1.0))
	if cut > deg_to_rad(76.0):
		return {"ease": 0.0}
	# the lines clear
	if not _clear(sim, from, ghost, cb.r, [PoolRules.CUE, b.id]):
		return {"ease": 0.0}
	if not _clear(sim, b.p, aim_at, b.r, [PoolRules.CUE, b.id]):
		return {"ease": 0.0}
	var ease := pow(cos(cut), 1.6) / (1.0 + 1.3 * d1 + 1.8 * d2)
	return {"ease": ease, "ghost": ghost, "cut": cut, "u": u, "d1": d1, "d2": d2}


func _clear(sim: PoolSim, a: Vector3, b: Vector3, r: float, skip: Array) -> bool:
	var ab := Vector3(b.x - a.x, 0, b.z - a.z)
	var L := ab.length()
	if L < 1e-6:
		return true
	var n := ab / L
	for o in sim.balls:
		if o.id in skip or o.state == PoolSim.DOWN or o.state == PoolSim.OFF:
			continue
		var rel := Vector3(o.p.x - a.x, 0, o.p.z - a.z)
		var s := rel.dot(n)
		if s < 0.0 or s > L:
			continue
		if (rel - n * s).length() < r + o.r - 0.002:
			return false
	return true


func _paces(sim: PoolSim, c: Dictionary) -> Array:
	# the cue speed that just gets the ball to the pocket, then firmer
	var mu := sim.table.mu_r * PoolSim.G
	var v_obj := sqrt(2.0 * mu * (float(c.d2) + 0.15)) * 1.25
	var v_hit := v_obj / maxf(cos(float(c.cut)), 0.25) / 0.95
	var v_cb := sqrt(v_hit * v_hit + 2.0 * mu * 1.8 * float(c.d1))
	var cb := sim.ball(PoolRules.CUE)
	var V := v_cb * cb.m * (1.0 / 0.54 + 1.0 / cb.m) / 1.75
	var f := float(me.firm)
	var out := []
	for k in [1.15, 1.7, 2.6]:
		out.append(clampf(V * k * f, 0.4, 7.5))
	return out


func _tips() -> Array:
	return [0.0, 0.35, -0.35]


# His aim, put right for the throw and the squirt by trying it and seeing where the ball goes: the
# way a player's arm knows a slow thin cut wants a hair more cut.
func _corrected_aim(sim: PoolSim, rules: PoolRules, c: Dictionary, pace: float) -> Vector3:
	var cb := sim.ball(PoolRules.CUE)
	var g: Vector3 = c.ghost
	var aim := Vector3(g.x - cb.p.x, 0, g.z - cb.p.z).normalized()
	var want: Vector3 = c.u
	var e0 := _obj_err(sim, aim, pace, c.target, want)
	if is_nan(e0):
		return aim
	var dl := deg_to_rad(0.15)
	var e1 := _obj_err(sim, aim.rotated(Vector3.UP, dl), pace, c.target, want)
	if is_nan(e1) or absf(e1 - e0) < 1e-6:
		return aim
	var slope := (e1 - e0) / dl
	var fix := clampf(-e0 / slope, -deg_to_rad(4.0), deg_to_rad(4.0))
	return aim.rotated(Vector3.UP, fix)


# the angle between where the object ball goes off and where it ought to (NAN if it isn't hit)
func _obj_err(sim: PoolSim, aim: Vector3, pace: float, target: int, want: Vector3) -> float:
	var s := sim.copy()
	sims_run += 1
	s.strike(s.ball(PoolRules.CUE), aim, deg_to_rad(4.0), 0.0, 0.0, pace, HOUSE_CUE)
	s.run(1.6)
	var b := s.ball(target)
	var th := -1.0
	for e in s.log:
		if e[1] == "ball" and (e[2] == target or e[3] == target):
			th = e[0]
			break
	if th < 0.0:
		return NAN
	var v := Vector3.ZERO
	for sg in b.segs:
		if float(sg[0]) >= th - 1e-9:
			v = sg[2]
			break
	if Vector2(v.x, v.z).length() < 1e-4:
		return NAN
	var dv := Vector3(v.x, 0, v.z).normalized()
	return atan2(want.cross(dv).y, want.dot(dv))


# Run a shot in a copy of the table and say how it came out.
func _try(sim: PoolSim, rules: PoolRules, shot: Dictionary) -> Dictionary:
	var s := sim.copy()
	sims_run += 1
	var cb := s.ball(PoolRules.CUE)
	s.strike(cb, shot.dir, float(shot.elev), float(shot.a), float(shot.b), float(shot.speed), HOUSE_CUE)
	s.run()
	var potted := s.pocketed()
	var first := s.first_hit(PoolRules.CUE)
	var tg := rules.targets(sim)
	var scratch: bool = PoolRules.CUE in potted or PoolRules.CUE in s.went_off()
	var legal: bool = first in tg and not scratch and s.went_off().is_empty()
	if rules.game != "8bar" and legal and potted.is_empty() and not s.rail_after_contact(PoolRules.CUE):
		legal = false
	var pt: bool = int(shot.get("target", -1)) in potted
	var right_pocket := true
	if pt and int(shot.get("pocket", -1)) >= 0:
		right_pocket = s.ball(int(shot.target)).pocket == int(shot.pocket)
	# the eight early, in the wrong pocket, or with the cue ball: all lose
	var lose: bool = 8 in potted and rules.game != "9ball" and (not (tg == [8]) or scratch or not right_pocket)
	var next_ease := 0.0
	var opp_ease := 0.0
	if not scratch:
		next_ease = _best_next(s, rules, rules.turn, potted)
		opp_ease = _best_next(s, rules, 1 - rules.turn, potted)
	return {"legal": legal, "potted_target": pt and legal and right_pocket, "potted": potted, "scratch": scratch, "lose": lose,
		"next_ease": next_ease, "opp_ease": opp_ease, "sim": s}


# the best shot left for a player from where the cue ball's ended up
func _best_next(s: PoolSim, rules: PoolRules, who: int, potted: Array) -> float:
	var cb := s.ball(PoolRules.CUE)
	var best := 0.0
	var tg: Array = rules.targets(s, who)
	# once his group's gone the eight is next
	if tg.is_empty() and rules.game != "9ball" and 8 in rules.on_table(s):
		tg = [8]
	for id in tg:
		if id in potted:
			continue
		var b := s.ball(id)
		for k in s.table.pockets.size():
			best = maxf(best, float(_ease(s, cb.p, b, k).ease))
	return best


func _value(_sim: PoolSim, rules: PoolRules, out: Dictionary, _c: Dictionary) -> float:
	if out.lose:
		return -10.0
	if not out.legal:
		return -3.0
	if out.potted_target:
		var v := 1.0 + 3.0 * float(out.next_ease)
		# the nine, or the eight, down: the game
		if rules.game == "9ball" and 9 in out.potted:
			v += 5.0
		if rules.game != "9ball" and 8 in out.potted:
			v += 5.0
		return v
	return -1.0 - 2.0 * float(out.opp_ease)


func _matters(sim: PoolSim, rules: PoolRules) -> bool:
	var tg := rules.targets(sim)
	if tg == [8]:
		return true
	if rules.game == "9ball":
		return 9 in tg
	# ahead of the man he's playing: he doesn't want to be
	var mine := rules.group_left(sim, rules.turn).size()
	var theirs := rules.group_left(sim, 1 - rules.turn).size()
	return rules.groups[rules.turn] != "" and mine < theirs and rng.randf() < 0.7


func _with_cue_at(sim0: PoolSim, place) -> PoolSim:
	var s := sim0.copy()
	if place != null:
		var cb := s.ball(PoolRules.CUE)
		cb.p = Vector3(place.x, cb.r, place.z)
		cb.state = PoolSim.STILL
		cb.pocket = -1
	return s


func _break(sim: PoolSim, rules: PoolRules, place) -> Dictionary:
	var apex := sim.table.foot_spot()
	var cb := sim.ball(PoolRules.CUE)
	var from: Vector3 = place if place != null else cb.p
	var dir := Vector3(apex.x - from.x, 0, apex.z - from.z).normalized()
	var spd := clampf(6.4 * float(me.firm), 4.5, 8.5)
	return {"dir": dir, "elev": deg_to_rad(3.0), "a": 0.0, "b": -0.08, "speed": spd, "place": place, "call": -1, "target": -1, "kind": "break", "sure": 0.0}


# In hand: where he puts the cue ball. A straight-ish shot on the easiest ball, a little angle on it
# for the next one, where it's allowed.
func _choose_place(sim: PoolSim, rules: PoolRules) -> Vector3:
	var best := Vector3(sim.table.head_spot().x, 0, 0)
	var best_e := -1.0
	var cb := sim.ball(PoolRules.CUE)
	for id in rules.targets(sim):
		var b := sim.ball(id)
		for k in sim.table.pockets.size():
			var pk: Array = sim.table.pockets[k]
			var aim_at: Vector3 = (pk[0] + pk[2]) * 0.5
			var u := Vector3(aim_at.x - b.p.x, 0, aim_at.z - b.p.z).normalized()
			for dist in [0.22, 0.4, 0.65]:
				for ang in [-18.0, 0.0, 18.0]:
					var back := (-u).rotated(Vector3.UP, deg_to_rad(ang))
					var p := b.p - u * (b.r + cb.r) + back * dist
					p.y = 0.0
					if not rules.can_place(sim, p):
						continue
					var e := _ease(sim, p, b, k)
					var ev := float(e.get("ease", 0.0)) * (0.92 if ang == 0.0 else 1.0)
					if ev > best_e:
						best_e = ev
						best = p
	if best_e < 0.0:
		# anywhere it's allowed
		for k in 60:
			var p := Vector3(rng.randf_range(-0.9, 0.9), 0, rng.randf_range(-0.42, 0.42))
			if rules.in_hand == "kitchen":
				p.x = rng.randf_range(-0.9, sim.table.head_string() - 0.02)
			if rules.can_place(sim, p):
				return p
	return best
