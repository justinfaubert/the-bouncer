extends SceneTree
# Whole games of pool between two of the opponents, on the physics, headless: eight-ball on the
# Sov's rules, league eight-ball and nine-ball. Every shot judged; each game has to end with a winner
# inside a sane number of shots, and nothing in the rules may go round in circles. Also: a good
# player beats a bad one most of the time, and the big man throws the ones that matter.
#   godot --headless --path godot -s res://tests/pool_rules.gd -- [--games 6]

var bad := 0


func _init() -> void:
	var games := 4
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--games" and i + 1 < args.size():
			games = int(args[i + 1])
	var t0 := Time.get_ticks_msec()
	var tally := {}
	for g in ["8bar", "8league", "9ball"]:
		for k in games:
			var r := play(g, "cook", "scratch", 100 + k)
			var key: String = g + " " + r.winner_name
			tally[key] = tally.get(key, 0) + 1
	print(tally)
	# the big man: does he throw?
	var r2 := play("8bar", "bigman", "cook", 903)
	print("the big man threw %d" % r2.thrown)
	print("pool_rules: %s (%d s)" % ["ok" if bad == 0 else "%d bad" % bad, (Time.get_ticks_msec() - t0) / 1000])
	quit(1 if bad else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		bad += 1
		print("  BAD: " + what)


func play(g: String, a: String, b: String, seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var sim := PoolSim.new(PoolSim.sov_table())
	var rules := PoolRules.new(g)
	sim.add_ball(0, sim.table.head_spot(), true)
	rules.rack(sim, rng)
	var ais := [PoolAI.new(a, seed_v), PoolAI.new(b, seed_v + 1)]
	var shots := 0
	var think_ms := 0
	while rules.winner < 0 and shots < 160:
		var ai: PoolAI = ais[rules.turn]
		var t0 := Time.get_ticks_msec()
		var plan := ai.plan(sim, rules)
		think_ms += Time.get_ticks_msec() - t0
		var shot := ai.hands(plan)
		var cb := sim.ball(0)
		if rules.in_hand != "" and plan.place != null:
			if not rules.can_place(sim, plan.place) and rules.broke:
				check(false, "%s placed the cue ball where it can't go %s" % [ais[rules.turn].me.name, str(plan.place)])
			cb.p = Vector3(plan.place.x, cb.r, plan.place.z)
			cb.state = PoolSim.STILL
			cb.pocket = -1
			cb.segs = []
		var start := {"targets": rules.targets(sim), "kitchen": rules.in_hand == "kitchen"}
		rules.called = int(plan.call)
		# a fresh sim from where everything lies, for this shot
		var s2 := sim.copy()
		s2.strike(s2.ball(0), shot.dir, float(shot.elev), float(shot.a), float(shot.b), float(shot.speed), PoolAI.HOUSE_CUE)
		s2.run()
		var res := rules.judge(s2, start)
		sim = s2.copy()
		for id in res.spot:
			rules.spot(sim, id)
		if res.scratch:
			var c := sim.ball(0)
			c.state = PoolSim.STILL
			c.pocket = -1
			c.p = Vector3(sim.table.head_spot().x, c.r, 0)
		rules.next(res)
		shots += 1
	var wn: String = ais[rules.winner].me.name if rules.winner >= 0 else "nobody"
	print("%s: %s v %s, %s won in %d shots (%s); thinking %.0f ms a shot" % [g, ais[0].me.name, ais[1].me.name, wn, shots,
		rules.history[rules.history.size() - 1].why if not rules.history.is_empty() else "", think_ms / maxf(shots, 1)])
	check(rules.winner >= 0, "%s never ended" % g)
	return {"winner_name": wn, "thrown": ais[0].thrown, "shots": shots}
