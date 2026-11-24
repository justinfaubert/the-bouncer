extends SceneTree
# What's out on the road (game/truck_odd.gd), driven headless: the figure stands on the shoulder
# ahead, on his side, on the road and not up the bank; near it the radio goes under and the voice
# comes through; once he's past it, it's only in the mirror; then it's gone. The lights come up
# behind him, only in the mirror, close in, and go out. Getting out ends either.
#   godot --headless --path godot -s res://tests/truck_odd.gd
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


func _put(tr: Truck, d: float) -> void:
	var a: Array = tr.road.at_dist(d)
	var p: Vector3 = a[0]
	var fd: Vector3 = a[1]
	var side := Vector3(-fd.z, 0.0, fd.x)
	tr.sim.place(p + side * 1.9, atan2(-fd.x, -fd.z))
	tr.sim.vel = fd * 16.0
	for i in 4:
		tr.sim.omega[i] = 16.0 / TruckSim.RADIUS
	tr.sim.rpm = 1500.0
	tr.sim.gear = "3"
	tr.sim.running = true
	tr._sel = 3
	tr.sim.selector = "D"


func _run() -> void:
	await _frames(10)
	main.start_truck("rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(20)
	var tr: Truck = main.truck
	var odd: TruckOdd = tr.odd
	odd._next = 1e9
	tr.lights = 1
	tr._lights()
	tr.radio.on = true
	_put(tr, 600.0)
	await _frames(2)
	check(odd.start("figure"), "the figure starts on the road")
	var local := tr.sim.rot.inverse() * (odd.figure.global_position - tr.sim.pos)
	print("    it's at ", local, " in the truck's terms")
	check(local.z < -80.0, "it's ahead of him")
	check(local.x > 0.5 and local.x < 14.0, "on his side of the road")
	var a: Array = tr.road.along(odd.figure.global_position)
	check(absf(odd.figure.global_position.y - float(a[2])) < 0.6, "standing on the road's level, not up the bank (%.2f)" % (odd.figure.global_position.y - float(a[2])))
	check(odd.eye_sees_figure(), "the eye can see it ahead")
	var most := 0.0
	var bled := false
	var passed_mirror_only := false
	for f in 2400:
		tr.sim.throttle = 0.25
		await process_frame
		most = maxf(most, tr.radio.interfere)
		bled = bled or tr.radio.bleed != ""
		if odd._passed and odd.state == "figure":
			passed_mirror_only = not odd.eye_sees_figure()
		if odd.state == "":
			break
		if f % 600 == 0:
			print("    t %d speed %.1f dist %.1f passed %s state %s" % [f, tr.sim.speed, (odd.figure.global_position - tr.sim.pos).length(), odd._passed, odd.state])
	check(most > 0.6, "near it the radio goes under (%.2f)" % most)
	check(bled, "and a voice comes through every station")
	check(passed_mirror_only, "past it, it's only in the mirror")
	check(odd.state == "" and not odd.figure.visible, "then it's gone")
	check(tr.radio.interfere == 0.0 and tr.radio.bleed == "", "and the radio's itself again")
	# the lights
	_put(tr, 900.0)
	await _frames(2)
	check(odd.start("lights"), "the lights start")
	await _frames(30)
	var ll := tr.sim.rot.inverse() * (odd.lamps.global_position - tr.sim.pos)
	check(ll.z > 50.0, "they're behind him (%.0f m)" % ll.z)
	var core: MeshInstance3D = odd.lamps.get_child(0)
	check(core.layers == 1 << (TruckOdd.MIRROR_LAYER - 1), "only the mirror draws them")
	check(not main.view.cam.get_cull_mask_value(TruckOdd.MIRROR_LAYER), "the eye's camera doesn't")
	check(tr.mirror_cam.get_cull_mask_value(TruckOdd.MIRROR_LAYER), "the mirror's does")
	# he gets out: nothing
	tr.sim.vel = Vector3.ZERO
	for i in 4:
		tr.sim.omega[i] = 0.0
	await _frames(5)
	tr._door()
	await _frames(3)
	check(odd.state == "" and not odd.lamps.visible, "out on his feet, there's nothing behind him")
	print("truck_odd: " + ("ok" if bad == 0 else "%d BAD" % bad))
	quit(1 if bad > 0 else 0)
