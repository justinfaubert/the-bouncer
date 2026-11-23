extends SceneTree
# Pictures of pool (game/pool.gd), from the Rehearse menu with no night: the table from the side,
# ball in hand behind the line, down on the break, the break in motion and settled, a cut shot lined
# up with the tip low and the butt up, the other man at the table, and the end card. Checks the balls
# against the cloth and the cushions as it goes: none inside another, none through a cushion, none
# under the cloth or floating over it.
# Needs a display:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#     --path godot -s res://tests/shots_pool.gd -- --out /tmp/pool

var main
var out := "/tmp/pool"
var shots := 0
var bad := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	shots += 1
	var file := "%02d_%s" % [shots, name]
	root.get_viewport().get_texture().get_image().save_png(out.path_join(file + ".png"))
	print("shot ", file)


# nothing through anything: every ball on the cloth, inside the cushions, apart from the others
func _check(p) -> void:
	var s: PoolSim = p.sim
	for a in s.balls:
		if a.state == PoolSim.DOWN or a.state == PoolSim.OFF:
			continue
		if absf(a.p.y - a.r) > 0.001:
			bad += 1
			print("  BAD: ball %d at height %.4f" % [a.id, a.p.y])
		if absf(a.p.x) > s.table.L * 0.5 - a.rc + 0.002 or absf(a.p.z) > s.table.W * 0.5 - a.rc + 0.002:
			# allowed only in a pocket's mouth
			var near_pocket := false
			for pk in s.table.pockets:
				if Vector2(a.p.x - pk[2].x, a.p.z - pk[2].z).length() < 0.09:
					near_pocket = true
			if not near_pocket:
				bad += 1
				print("  BAD: ball %d through the cushion at %s" % [a.id, str(a.p)])
		for b in s.balls:
			if b.id <= a.id or b.state == PoolSim.DOWN or b.state == PoolSim.OFF:
				continue
			if a.p.distance_to(b.p) < a.r + b.r - 0.0005:
				bad += 1
				print("  BAD: balls %d and %d inside each other" % [a.id, b.id])


func _wait_settled(p) -> void:
	for k in 4000:
		if p.phase != "rolling":
			return
		# the software renderer's slow: play it back fast once it's been seen
		if k > 3:
			p._speed_k = 40.0
		await process_frame


func _run() -> void:
	await _frames(5)
	main.menus.rehearse("title")
	await _frames(5)
	main.start_pool("8bar", "buddy", "rehearse", {"body": {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0}, "seed": 11})
	var p = main.pool
	p.shake_off = true
	await _frames(60)
	await _grab("in_hand_behind_the_line")
	# put it down a little off the head spot
	var cb: PoolSim.Ball = p.sim.ball(0)
	cb.p = Vector3(p.sim.table.head_spot().x, cb.r, 0.08)
	cb.state = PoolSim.STILL
	p.tbl.put_ball(0, cb.r, cb.p, true)
	p.rules.in_hand_placed = "kitchen"
	p.rules.in_hand = ""
	p.phase = "aim"
	p.overview = false
	var to: Vector3 = p.sim.table.foot_spot() - cb.p
	p.aim_yaw = atan2(-to.z, to.x)
	p.stance = 0.05
	await _frames(50)
	await _grab("down_on_the_break")
	p.drawing = true
	p.draw = 0.8
	await _frames(20)
	await _grab("drawn_back")
	p.drawing = false
	p._stroke()
	await _frames(14)
	await _grab("the_break")
	await _wait_settled(p)
	await _frames(20)
	_check(p)
	print("after the break: down %s, turn %d, in hand '%s'" % [str(p._trough), p.rules.turn, p.rules.in_hand])
	p.overview = true
	await _frames(40)
	await _grab("after_the_break")
	# let it play: the buddy's shots and ours, a few, the AI aiming ours too
	var helper := PoolAI.new("cook", 3)
	for n in 5:
		if p.phase == "over":
			break
		if p.phase == "theirs":
			for k in 3000:
				if p.phase != "theirs":
					break
				p._their_t += 0.25
				if k == 4:
					await _grab("their_shot_%d" % n)
				await process_frame
			await _wait_settled(p)
			_check(p)
			continue
		if p.phase == "place":
			var pl: Vector3 = helper._choose_place(p.sim, p.rules)
			var c: PoolSim.Ball = p.sim.ball(0)
			c.p = Vector3(pl.x, c.r, pl.z)
			c.state = PoolSim.STILL
			c.pocket = -1
			c.segs = []
			p.tbl.put_ball(0, c.r, c.p, true)
			p.rules.in_hand_placed = p.rules.in_hand
			p.rules.in_hand = ""
			p.phase = "aim"
			p.overview = false
		var plan: Dictionary = helper.plan(p.sim, p.rules)
		p.aim_yaw = atan2(-plan.dir.z, plan.dir.x)
		p.tip = Vector2(plan.a, plan.b)
		p.elev = rad_to_deg(plan.elev)
		if plan.call >= 0:
			p.rules.called = plan.call
			p.tbl.call_pocket(plan.call)
		p.stance = 0.1
		await _frames(40)
		if n < 3:
			await _grab("lined_up_%d" % n)
		# the stroke for the planned speed
		p.draw = pow(clampf((float(plan.speed) - Pool.SPEED_LO) / (Pool.SPEED_HI - Pool.SPEED_LO), 0.0, 1.0), 1.0 / 1.5)
		p._stroke()
		await _wait_settled(p)
		_check(p)
	p.overview = true
	await _frames(30)
	await _grab("later")
	# a trick shot, the butt up
	p.end()
	await _frames(10)
	main.start_pool("trick", "", "rehearse", {"trick": "round_eight", "body": {"drinks": 0}})
	p = main.pool
	await _frames(30)
	var c2: PoolSim.Ball = p.sim.ball(0)
	var t5: Vector3 = p.sim.ball(5).p - c2.p
	p.aim_yaw = atan2(-t5.z, t5.x) + 0.25
	p.elev = 60.0
	p.tip = Vector2(-0.45, 0.0)
	p.stance = 0.3
	await _frames(40)
	await _grab("masse_lined_up")
	p.end()
	await _frames(10)
	print("shots_pool: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)
