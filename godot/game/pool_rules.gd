# The rules of a game of pool, and the judging of every shot (game/pool.gd asks; game/pool_sim.gd says
# what happened). Three games:
#   8bar     the Sov's: what's chalked on the board by the table. Call the eight and nothing else.
#            Scratch, and it's in hand behind the line. The eight on the break wins; scratch on the
#            eight loses. Slop counts. No jumping on the house cues.
#   8league  the league's eight-ball (the Legion's, the tournament's): the same, but ball in hand
#            anywhere, a cushion after contact or it's a foul, and the eight on the break is spotted.
#   9ball    the lowest ball first, anything that drops after counts, the nine wins whenever it drops
#            on a good hit. Ball in hand anywhere. A push-out after the break. Three fouls in a row
#            and you've lost.
#   practice no rules: put balls where you like, shoot, put them back.
class_name PoolRules
extends RefCounted

const CUE := 0
const SOLIDS := [1, 2, 3, 4, 5, 6, 7]
const STRIPES := [9, 10, 11, 12, 13, 14, 15]

var game := "8bar"
var names := ["He", "Them"]
var turn := 0                       # whose shot: 0 the player, 1 the other
var groups := ["", ""]              # "solids" / "stripes"
var broke := false
var in_hand := "kitchen"            # "", "kitchen" (behind the line), "anywhere"
var fouls := [0, 0]                 # in a row (nine-ball)
var winner := -1
var called := -1                    # the pocket called for the eight
var push_ok := false                # nine-ball: the shot after the break may be a push-out
var pushing := false                # this shot is one
var after_push := false             # the other player decides: take it or give it back
var shots := [0, 0]
var made := [0, 0]
var runs := [0, 0]                  # the longest run of balls each
var _run := 0
var history: Array = []             # each shot: {who, potted, foul, why}
var in_hand_placed := ""            # the cue ball was put down from in hand this shot (behind the line, or anywhere)


func _init(g := "8bar") -> void:
	game = g


# The rack: the balls where they go, on the foot spot. rng for the order the rules leave open, and
# how tight it's racked (loose: the gaps the buddy leaves, and the break goes dead).
func rack(sim: PoolSim, rng: RandomNumberGenerator, loose := 0.0) -> void:
	var spot := sim.table.foot_spot()
	var r := sim.table.ball_r
	var order: Array = []
	if game == "9ball":
		var mid := [2, 3, 4, 5, 6, 7, 8]
		_shuffle(mid, rng)
		# the diamond: 1 at the apex, 9 in the middle
		var rows := [1, 2, 3, 2, 1]
		var k := 0
		var ids := [1, mid[0], mid[1], mid[2], 9, mid[3], mid[4], mid[5], mid[6]]
		for row in rows.size():
			for i in rows[row]:
				var p := spot + Vector3(row * r * sqrt(3.0), 0, (i - (rows[row] - 1) * 0.5) * 2.0 * r)
				sim.add_ball(ids[k], _gap(p, rng, loose))
				k += 1
		return
	# eight-ball: the eight in the middle of the third row, a solid and a stripe in the back corners
	var sol := SOLIDS.duplicate()
	var stp := STRIPES.duplicate()
	_shuffle(sol, rng)
	_shuffle(stp, rng)
	var rest: Array = []
	var a: int = sol.pop_back()
	var b: int = stp.pop_back()
	rest.append_array(sol)
	rest.append_array(stp)
	_shuffle(rest, rng)
	order.resize(15)
	order[4] = 8
	order[10] = a if rng.randf() < 0.5 else b
	order[14] = b if order[10] == a else a
	var ri := 0
	for i in 15:
		if order[i] == null:
			order[i] = rest[ri]
			ri += 1
	var k := 0
	for row in 5:
		for i in row + 1:
			var p := spot + Vector3(row * r * sqrt(3.0), 0, (i - row * 0.5) * 2.0 * r)
			sim.add_ball(order[k], _gap(p, rng, loose))
			k += 1


func _gap(p: Vector3, rng: RandomNumberGenerator, loose: float) -> Vector3:
	# a rack's never perfectly tight: a hair between most of them, more when it's racked careless
	var g := 0.00012 + loose * 0.0012
	return p + Vector3(rng.randf() * g, 0, rng.randf_range(-0.5, 0.5) * g * 0.6) * Vector3(1, 0, 1)


func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func on_table(sim: PoolSim) -> Array:
	var out := []
	for b in sim.balls:
		if b.id != CUE and b.state != PoolSim.DOWN and b.state != PoolSim.OFF:
			out.append(b.id)
	return out


func group_of(id: int) -> String:
	if id in SOLIDS:
		return "solids"
	if id in STRIPES:
		return "stripes"
	return ""


func group_left(sim: PoolSim, who: int) -> Array:
	var g: String = groups[who]
	if g == "":
		return []
	var ids: Array = SOLIDS if g == "solids" else STRIPES
	return on_table(sim).filter(func(i): return i in ids)


# What he may hit first now: the ids, for aiming and for the opponents' thinking.
func targets(sim: PoolSim, who := -1) -> Array:
	if who < 0:
		who = turn
	var left := on_table(sim)
	match game:
		"9ball":
			if left.is_empty():
				return []
			return [left.min()]
		"practice":
			return left
		_:
			if not broke:
				return left
			if groups[who] == "":
				return left.filter(func(i): return i != 8)
			var mine := group_left(sim, who)
			return mine if not mine.is_empty() else ([8] if 8 in left else [])


# on the eight now: the shot needs a pocket called
func needs_call(sim: PoolSim) -> bool:
	if game != "8bar" and game != "8league":
		return false
	return broke and targets(sim) == [8]


# Judge the shot just played. Returns {"potted", "foul", "why", "keep" (shoots again), "win" (the
# player who's won, or -1), "in_hand", "spot" (balls to put back on the foot spot)}.
func judge(sim: PoolSim, start: Dictionary) -> Dictionary:
	var who := turn
	var potted: Array = sim.pocketed()
	var off: Array = sim.went_off()
	var first := sim.first_hit(CUE)
	var scratch: bool = CUE in potted or CUE in off
	var objs := potted.filter(func(i): return i != CUE)
	var res := {"potted": objs, "foul": false, "why": "", "keep": false, "win": -1, "in_hand": "", "spot": [], "who": who, "first": first, "scratch": scratch}
	shots[who] += 1
	if game == "practice":
		res.keep = true
		if scratch:
			res.in_hand = "anywhere"
		_log(res)
		return res
	var tg: Array = start.get("targets", [])
	var jumped: bool = start.get("jumped", false)
	var league := game != "8bar"
	var why := ""
	if scratch:
		why = "scratch" if CUE in potted else "off the table"
	elif first == -1:
		why = "nothing hit"
	elif not (first in tg) and not pushing:
		why = "wrong ball first"
	elif jumped and game == "8bar":
		why = "jumped on a house cue"
	elif start.get("kitchen", false) and start.get("first_in_kitchen", false):
		why = "hit a ball behind the line"
	elif league and broke and not pushing and objs.is_empty() and not sim.rail_after_contact(CUE):
		why = "no rail after contact"
	elif off.size() > 0:
		why = "a ball off the table"
	res.foul = why != ""
	res.why = why
	# balls that left the table are spotted (the coin-op keeps the pocketed ones)
	for i in off:
		if i != CUE:
			res.spot.append(i)
	match game:
		"9ball":
			_judge9(sim, res, objs)
		_:
			_judge8(sim, res, objs, start)
	if res.foul and res.win < 0:
		res.in_hand = "kitchen" if game == "8bar" else "anywhere"
	if not res.foul and objs.size() > 0:
		made[who] += objs.size()
	if res.keep:
		_run += objs.size()
		runs[who] = maxi(runs[who], _run)
	else:
		_run = 0
	_log(res)
	return res


func _judge8(sim: PoolSim, res: Dictionary, objs: Array, start: Dictionary) -> void:
	var who: int = res.who
	var eight := 8 in objs
	if not broke:
		broke = true
		if eight:
			if game == "8bar":
				if res.scratch:
					res.win = 1 - who
					res.why = "scratched on the break with the eight"
				else:
					res.win = who
					res.why = "the eight on the break"
				return
			# league: the eight comes back up
			res.spot.append(8)
			objs.erase(8)
		res.keep = not res.foul and objs.size() > 0
		# the table stays open after the break
		return
	# the eight
	if eight:
		var was_on: bool = start.get("targets", []) == [8]
		if not was_on:
			res.win = 1 - who
			res.why = "the eight went early"
		elif res.foul:
			res.win = 1 - who
			res.why = "the eight with a foul (%s)" % res.why
		elif called >= 0 and sim.ball(8).pocket != called:
			res.win = 1 - who
			res.why = "the eight in the wrong pocket"
		else:
			res.win = who
			res.why = "the eight, called"
		return
	if res.foul:
		return
	# the groups, off the first ball down after the break on a good shot
	if groups[who] == "" and objs.size() > 0:
		var g := group_of(objs[0])
		if g != "":
			groups[who] = g
			groups[1 - who] = "stripes" if g == "solids" else "solids"
			res["groups"] = g
	if groups[who] == "":
		res.keep = objs.size() > 0
	else:
		var mine := objs.filter(func(i): return group_of(i) == groups[who])
		# slop counts in the Sov: any of his down keeps him at the table
		res.keep = mine.size() > 0


func _judge9(sim: PoolSim, res: Dictionary, objs: Array) -> void:
	var who: int = res.who
	var was_break := not broke
	broke = true
	if pushing:
		pushing = false
		push_ok = false
		after_push = true
		if 9 in objs:
			res.spot.append(9)
		res.foul = res.why == "scratch" or res.why == "off the table"
		if res.foul:
			fouls[who] += 1
		return
	if res.foul:
		fouls[who] += 1
		if 9 in objs:
			res.spot.append(9)
		if fouls[who] >= 3:
			res.win = 1 - who
			res.why = "three fouls in a row"
		push_ok = was_break
		return
	fouls[who] = 0
	if 9 in objs:
		res.win = who
		res.why = "the nine on the break" if was_break else "the nine"
		return
	res.keep = objs.size() > 0
	push_ok = was_break


# The next shot's: who, and whether it's in hand. Called after judge() unless someone's won.
func next(res: Dictionary) -> void:
	if res.win >= 0:
		winner = res.win
		return
	called = -1
	if not res.keep:
		turn = 1 - turn
	in_hand = res.in_hand
	if game == "9ball" and res.in_hand != "":
		in_hand = "anywhere"


func _log(res: Dictionary) -> void:
	history.append({"who": res.who, "potted": res.potted.duplicate(), "foul": res.foul, "why": res.why})


# Put a ball back on the foot spot, or behind it along the line if that's taken.
func spot(sim: PoolSim, id: int) -> void:
	var b := sim.ball(id)
	if b == null:
		return
	var p := sim.table.foot_spot()
	for k in 40:
		var free := true
		for o in sim.balls:
			if o == b or o.state == PoolSim.DOWN or o.state == PoolSim.OFF:
				continue
			if Vector2(o.p.x - p.x, o.p.z - p.z).length() < o.r + b.r + 0.001:
				free = false
				break
		if free:
			break
		p.x += 0.01
		if p.x > sim.table.L * 0.5 - b.r:
			p = sim.table.foot_spot() - Vector3(0.06 * (k - 20), 0, 0)
	b.p = Vector3(p.x, b.r, p.z)
	b.v = Vector3.ZERO
	b.w = Vector3.ZERO
	b.state = PoolSim.STILL
	b.pocket = -1
	b.segs = []
	b.ver += 1


# where the cue ball may go in hand: on the cloth, clear of the other balls, and behind the line
# when that's the rule
func can_place(sim: PoolSim, p: Vector3) -> bool:
	var cb := sim.ball(CUE)
	var hl := sim.table.L * 0.5 - cb.rc - 0.001
	var hw := sim.table.W * 0.5 - cb.rc - 0.001
	if absf(p.x) > hl or absf(p.z) > hw:
		return false
	if in_hand == "kitchen" and p.x > sim.table.head_string():
		return false
	for o in sim.balls:
		if o == cb or o.state == PoolSim.DOWN or o.state == PoolSim.OFF:
			continue
		if Vector2(o.p.x - p.x, o.p.z - p.z).length() < o.r + cb.r + 0.0005:
			return false
	# not in a pocket's mouth
	for pk in sim.table.pockets:
		if Vector2(p.x - pk[0].x, p.z - pk[0].z).length() < float(pk[1]) + 0.03:
			return false
	return true


# The chalk on the board by the table, for the game: what the house rules say.
func house_rules() -> String:
	match game:
		"8bar":
			return "SOV RULES\nLOSER RACKS\nCALL THE 8\nSCRATCH: BEHIND THE LINE\n8 ON BREAK WINS\nSCRATCH ON 8 LOSES\nSLOP COUNTS\nNO JUMPING ON\nHOUSE CUES\n— MGMT"
		"8league":
			return "LEAGUE 8-BALL\nCALL THE 8\nBALL IN HAND\nRAIL AFTER CONTACT\n8 ON BREAK SPOTS"
		"9ball":
			return "9-BALL\nLOWEST BALL FIRST\nBALL IN HAND\nPUSH OUT AFTER BREAK\n3 FOULS LOSES"
	return "PRACTICE"


func describe(g := "") -> String:
	match g if g != "" else game:
		"8bar":
			return "Eight-ball on the Sov's rules"
		"8league":
			return "League eight-ball"
		"9ball":
			return "Nine-ball"
	return "Practice"
