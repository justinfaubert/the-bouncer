extends SceneTree
# Getting out of the truck and back in (game/truck.gd, game/truck_foot.gd). Still, he steps out,
# it goes into P, the door shuts behind him, and he gets back in at the door. At 50 he bails: it
# hurts, he ends up on the road beside it, not in it, and the truck goes on with the door open and
# rolls to a stop on its own. A walking-pace bail is only a stumble.
#   godot --headless --path godot -s res://tests/truck_door.gd
var main
var bad := 0


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  BAD  ") + what)
	if not ok:
		bad += 1


func _run() -> void:
	await _frames(10)
	main.start_truck("rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(20)
	var tr: Truck = main.truck
	# still, in D: out, and it goes in P
	tr.sim.running = true
	tr._sel = 3
	tr.sim.selector = "D"
	tr._door()
	check(tr.foot.out, "Q gets him out when it's still")
	check(tr.sim.selector == "P", "and it goes into P first (%s)" % tr.sim.selector)
	check(main.view.hurt == 0, "stepping out doesn't hurt")
	await create_timer(2.5).timeout
	check(tr.door_open < 0.05, "the door shuts behind him (%.2f)" % tr.door_open)
	var d0 := tr.foot.pos.distance_to(tr.sim.pos)
	check(d0 > 0.9 and d0 < 3.0, "he's standing by the driver's side (%.1f m from its middle)" % d0)
	tr._door()
	check(not tr.foot.out, "Q at the door gets him back in")
	# at 50: a bail
	var a: Array = tr.road.at_dist(600.0)
	var fd: Vector3 = a[1]
	tr.sim.place((a[0] as Vector3) + Vector3(-fd.z, 0, fd.x) * 1.9, atan2(-fd.x, -fd.z))
	tr.sim.vel = fd * 14.0
	for i in 4:
		tr.sim.omega[i] = 14.0 / TruckSim.RADIUS
	tr._sel = 3
	tr.sim.selector = "D"
	tr.sim.gear = "2"
	tr.sim.rpm = 1500.0
	await _frames(3)
	var hurt0: int = main.view.hurt
	tr._door()
	check(tr.foot.out and tr.foot.down > 1.0, "at 50 he bails and goes down (%.1f s on the road)" % tr.foot.down)
	check(main.view.hurt >= hurt0 + 2, "and it hurts (hurt %d to %d)" % [hurt0, main.view.hurt])
	check(tr.sim.selector == "D", "the truck stays in D")
	var t0 := 0.0
	while absf(tr.sim.speed) > 0.05 and t0 < 30.0:
		await create_timer(0.5).timeout
		t0 += 0.5
	check(absf(tr.sim.speed) <= 0.05, "it rolls to a stop on its own (%.1f s)" % t0)
	check(tr.door_open > 0.9, "with the door open (%.2f)" % tr.door_open)
	var gap := tr.foot.pos.distance_to(tr.sim.pos)
	check(gap > 1.0, "he's on the road, not inside it (%.1f m off its middle)" % gap)
	check(tr.foot.down <= 0.0, "and he's got up again")
	# walk to the door and get in
	tr.foot.pos = tr.foot.door_point()
	tr._door()
	check(not tr.foot.out, "back in at the door")
	# a walking-pace bail
	tr.sim.vel = tr.sim.forward() * 2.0
	tr._door()
	check(tr.foot.out and main.view.hurt == hurt0 + 2, "a bail at walking pace is a stumble, no more hurt")
	tr.end()
	print("truck_door: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)
