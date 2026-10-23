extends "res://tests/reach.gd"
# Where on the floor, near a point, he could stand and see everything the floor offers: every thing
# he can look at from it, and every place's pin, against the same solid copy of the room
# tests/reach.gd asks, with the room as it is at twenty to eight. For picking the spots he comes
# back onto the floor at (world/posts.gd, FLOOR_FROM) when the room changes. Prints the clear spots
# nearest each point, and what's hidden from the rest round it.
#   godot --headless --path godot -s res://tests/floor_sight.gd -- --near "4.0,2.0;3.6,8.0"


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var centers: Array = []
	for i in args.size():
		if args[i] == "--near":
			for c in str(args[i + 1]).split(";"):
				var b := c.split(",")
				centers.append(Vector3(float(b[0]), 0, float(b[1])))
	await _frames(5)
	main.settings["dice"] = "quick"
	main.start_new(3)
	await _frames(3)
	for b in main.pub.find_children("*", "StaticBody3D", true, false):
		b.queue_free()
	await _frames(1)
	_solidify(main.pub)
	await physics_frame
	await physics_frame
	main.game.set_var("clock", 1180)
	main.view.clock = 1180
	main.stage.sync(main.game, true)
	await _frames(5)
	var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
	var hs: Hotspots = main.spots
	var people: Array = main.stage.standing()
	for c in centers:
		print("== near (%.2f, %.2f)" % [c.x, c.z])
		var good: Array = []
		var worst := {}
		for dx in range(-8, 9):
			for dz in range(-8, 9):
				var q: Vector3 = c + Vector3(dx * 0.15, 0, dz * 0.15)
				if Nav.clearance(q) < Nav.BODY + 0.12 or Hotspots.zone_of(q + Vector3(0, 1, 0)) != "room":
					continue
				var crowded := false
				for pp in people:
					if Vector2((pp as Vector3).x - q.x, (pp as Vector3).z - q.z).length() < Nav.PERSON + Nav.BODY + 0.1:
						crowded = true
				if crowded:
					continue
				main.view.floor_spot = q
				main.view.jump_to("floor")
				var eye: Vector3 = main.view.eye_pos
				var bad: Array = []
				for id in hs.things:
					var tw: Array = hs.look_spot(str(id))
					if tw.is_empty():
						continue
					if _blocked(space, eye, tw[0], float(tw[1]), str(tw[2])) != "":
						bad.append(str(id))
				for loc in ["door", "bar", "t28", "pool", "hall", "kitchen", "deck", "lot"]:
					var key: String = Hotspots.WAYS[loc]
					for k in key.split("|"):
						var w: Array = hs._first_seen(k)
						if not w.is_empty() and _blocked(space, eye, w[0], float(w[1]), str(w[2])) != "":
							bad.append("way " + loc)
				if bad.is_empty():
					good.append([q.distance_to(c), q])
				else:
					for b in bad:
						worst[b] = int(worst.get(b, 0)) + 1
		good.sort_custom(func(a, b): return a[0] < b[0])
		for g in good.slice(0, 10):
			print("  clear  (%.2f, %.2f)  %.2f off" % [g[1].x, g[1].z, g[0]])
		print("  hidden somewhere near: ", worst)
	quit()
