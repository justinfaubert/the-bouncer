extends SceneTree
# Shots by the hundred, at random, hunting for what a player would see as broken: two balls inside
# each other, a ball through a cushion or a jaw, a pocketed ball that comes back. Every ball's path
# is sampled every millisecond and checked against the others.
#   godot --headless --path godot -s res://tests/pool_stress.gd -- [--shots 300]

var bad := 0
var kinds := {}


func _init() -> void:
	var n := 300
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--shots" and i + 1 < args.size():
			n = int(args[i + 1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var t0 := Time.get_ticks_msec()
	var sim := _fresh(rng)
	for k in n:
		if sim.balls.filter(func(b): return b.state != PoolSim.DOWN and b.state != PoolSim.OFF and b.id != 0).size() < 2 or k % 25 == 0:
			sim = _fresh(rng)
		var cb := sim.ball(0)
		if cb.state == PoolSim.DOWN or cb.state == PoolSim.OFF:
			cb.state = PoolSim.STILL
			cb.pocket = -1
			cb.p = Vector3(sim.table.head_spot().x, cb.r, rng.randf_range(-0.2, 0.2))
			cb.segs = []
		# at a ball, often one near a pocket, hard or soft
		var live := sim.balls.filter(func(b): return b.id != 0 and b.state != PoolSim.DOWN and b.state != PoolSim.OFF)
		var tg: PoolSim.Ball = live[rng.randi() % live.size()]
		var to := tg.p - cb.p
		var dir := Vector3(to.x, 0, to.z).normalized().rotated(Vector3.UP, rng.randf_range(-0.05, 0.05))
		var speed := rng.randf_range(0.6, 7.5) if k % 25 != 0 else 8.0
		var s2 := sim.copy()
		s2.strike(s2.ball(0), dir, s2.min_elev(dir), rng.randf_range(-0.3, 0.3), rng.randf_range(-0.4, 0.4), speed, PoolAI.HOUSE_CUE)
		s2.run()
		_check(s2, k)
		sim = s2.copy()
	print(kinds)
	print("pool_stress: %s, %d shots (%d s)" % ["ok" if bad == 0 else "%d bad" % bad, n, (Time.get_ticks_msec() - t0) / 1000])
	quit(1 if bad else 0)


func _fresh(rng: RandomNumberGenerator) -> PoolSim:
	var sim := PoolSim.new(PoolSim.sov_table())
	sim.add_ball(0, sim.table.head_spot(), true)
	var rules := PoolRules.new("8bar")
	rules.rack(sim, rng)
	return sim


func _flag(kind: String, what: String) -> void:
	kinds[kind] = kinds.get(kind, 0) + 1
	if kinds[kind] <= 4:
		print("  BAD: " + what)
	bad += 1


func _check(s: PoolSim, k: int) -> void:
	var hl := s.table.L * 0.5
	var hw := s.table.W * 0.5
	var end := s.t + 0.3
	var tt := 0.0
	var reported := {}
	while tt <= end:
		var at := {}
		for b in s.balls:
			var sm: Array = s.sample(b, tt)
			at[b.id] = sm
		for a in s.balls:
			var sa: Array = at[a.id]
			if not sa[2]:
				continue
			var pa: Vector3 = sa[0]
			if a.state == PoolSim.OFF:
				continue
			# on the cloth: inside the cushions, but for a pocket's mouth
			if pa.y > -0.001 and pa.y < a.r + 0.01:
				if absf(pa.x) > hl - a.rc + 0.003 or absf(pa.z) > hw - a.rc + 0.003:
					var near := false
					for pk in s.table.pockets:
						if Vector2(pa.x - pk[0].x, pa.z - pk[0].z).length() < float(pk[1]) + a.r + 0.01:
							near = true
					if not near and not reported.has("rail%d" % a.id):
						reported["rail%d" % a.id] = true
						_flag("through_cushion", "shot %d: ball %d through the cushion at %s, t %.3f" % [k, a.id, str(pa), tt])
			for b in s.balls:
				if b.id <= a.id:
					continue
				var sb: Array = at[b.id]
				if not sb[2]:
					continue
				var pb: Vector3 = sb[0]
				var dd := pa.distance_to(pb)
				if dd < a.r + b.r - 0.002 and not reported.has("%d-%d" % [a.id, b.id]):
					reported["%d-%d" % [a.id, b.id]] = true
					var down: bool = a.state == PoolSim.DOWN or b.state == PoolSim.DOWN
					_flag("inside_falling" if (pa.y < a.r - 0.002 or pb.y < b.r - 0.002) else "inside", "shot %d: balls %d and %d inside each other by %.1f mm at t %.3f, %s %s%s" % [k, a.id, b.id, (a.r + b.r - dd) * 1000.0, tt, str(pa), str(pb), " (one pocketed)" if down else ""])
		tt += 0.001
	# a pocketed ball stays pocketed
	for b in s.balls:
		var was_down := false
		for sg in b.segs:
			if sg[7] == PoolSim.DOWN:
				was_down = true
			elif was_down:
				_flag("came_back", "shot %d: ball %d came back out of the pocket" % [k, b.id])
				break
