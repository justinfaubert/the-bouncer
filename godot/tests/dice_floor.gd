extends SceneTree
# Where the dice go down at each post, against everything drawn there: plays the throw that would be
# made looking each way round from each post (game/dice.gd's Planner), and lists the throws where a
# die goes into something drawn (a wall, a leg, a shoe, the tray's own rim), the tray or the dice
# go down off the floor that's really there, or no throw came right. Gives everything in the room
# a solid copy of its mesh to ask.
#   godot --headless --path godot -s res://tests/dice_floor.gd -- [--places floor,hall:clerk] [--step 20]

var main
var places := ["floor", "hall", "keg", "deck", "lot", "upstairs", "hall:clerk", "lot:pickup", "lot:truck", "pool:juke", "door", "bar",
	"t28", "pool", "kitchen"]
var step := 20
var bad := 0
var all := 0
var fallbacks := 0           # throws shown that went somewhere clean but not where they were meant to


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--places": places = Array(args[i + 1].split(",")); i += 1
			"--step": step = int(args[i + 1]); i += 1
		i += 1
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


# a solid copy of everything drawn, but the dice
func _solidify(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and not (c.mesh is QuadMesh) \
				and not str(c.get_path()).contains("faces") and (c as MeshInstance3D).is_visible_in_tree():
			(c as MeshInstance3D).create_trimesh_collision()
		_solidify(c)


func _what(space: PhysicsDirectSpaceState3D, at: Transform3D, size: float) -> String:
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * size
	q.shape = box
	q.transform = at
	var hits := space.intersect_shape(q, 4)
	if hits.is_empty():
		return ""
	var names: Array = []
	for h in hits:
		var body: Node = h.collider
		var mi := body.get_parent()
		var nm := str(mi.name)
		var up := mi.get_parent()
		for k in 3:
			if up == null or up == main.pub:
				break
			nm = str(up.name) + "/" + nm
			up = up.get_parent()
		names.append(nm)
	return ", ".join(names)


func _floor_at(space: PhysicsDirectSpaceState3D, p: Vector3, from_y: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, from_y, p.z), Vector3(p.x, from_y - 4.0, p.z))
	var hit := space.intersect_ray(q)
	return float(hit.position.y) if not hit.is_empty() else NAN


# why each throw a planner tries doesn't come right, counted
func _misses(sp: Dictionary, eye: Vector3, seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pl := Dice.Planner.new(sp.duplicate(true), eye, rng, false)
	var count := {}
	for t in Dice.TRIES:
		var s: DiceSim = pl._next()
		s.run()
		var w := "fell short" if not s.ok else _why(s, pl.sp)
		count[w] = int(count.get(w, 0)) + 1
		pl._judge(s)
	var out: Array = []
	for k in count:
		out.append("%s x%d" % [k, count[k]])
	return ", ".join(out)


# game/dice.gd's _fits, saying which part a throw fails
func _why(s: DiceSim, sp: Dictionary) -> String:
	var y0: float = s.floor_y
	var at: Vector3 = sp.at
	var p0: Vector3 = s.pos[0]
	var p1: Vector3 = s.pos[1]
	if p0.distance_to(p1) > float(sp.get("reach", 0.28)) + 0.06:
		return "apart"
	for k in 2:
		var p: Vector3 = s.pos[k]
		if Vector2(p.x - at.x, p.z - at.z).length() > float(sp.get("reach", 0.28)):
			return "out (%.3f)" % Vector2(p.x - at.x, p.z - at.z).length()
		var fr: Array = s.frames[k]
		for i in range(0, fr.size(), 2):
			var q: Vector3 = fr[i][0]
			for rim in sp.get("rims", []):
				var dr := Vector2(q.x, q.z).distance_to(rim[0])
				if dr > float(rim[1]) and dr < float(rim[1]) + 0.016 + DiceSim.NEAR \
						and DiceSim.lowest(q, Basis(fr[i][1] as Quaternion)) < y0 + float(rim[2]) + 0.004:
					return "through the rim"
	if not Dice._clean(s, sp):
		return "unread"
	return "fits"


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	main.start_new(2)
	await _frames(10)
	var tray: Node3D = main.dice.tray
	for p in places:
		var place: String = p.get_slice(":", 0)
		main.view.frame = p.get_slice(":", 1) if ":" in p else ""
		main.view.jump_to(place)
		if p == "lot:pickup":
			(main.pub.dyn.truck as Node3D).visible = true
		main.stage._settle(0.0)
		await _frames(4)
		for b in main.pub.find_children("*", "StaticBody3D", true, false):
			b.queue_free()
		await _frames(1)
		tray.visible = false
		_solidify(main.pub)
		# the tray too, wherever it goes
		tray.visible = true
		for mi in tray.get_children():
			(mi as MeshInstance3D).create_trimesh_collision()
		tray.visible = false
		await physics_frame
		await physics_frame
		var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
		var eye: Vector3 = main.view.eye_pos
		var lines: Array = []
		for deg in range(0, 360, step):
			var yaw := deg_to_rad(float(deg))
			var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
			var sp: Dictionary = Dice.spot_for(place, eye, fwd, main.view.frame)
			if place == "t28":
				sp.glasses = main.dice._t28_glasses()
			# the tray where it's gone down, and nowhere else
			tray.position = sp.get("tray", Vector3(0, -50, 0))
			await physics_frame
			var rng := RandomNumberGenerator.new()
			rng.seed = deg * 7919 + 13
			var pl := Dice.Planner.new(sp, eye, rng, false)
			while not pl.done:
				pl.work(100.0)
			var plan: Dictionary = pl.result()
			var s: DiceSim = plan.sim
			var at: Vector3 = sp.at
			# what they land on: the tray's cork, or the floor round it
			var real := _floor_at(space, at, eye.y - 0.3)
			var why: Array = []
			if not is_nan(real) and absf(real - at.y) > 0.004:
				why.append("floor really at %.3f, thrown at %.3f" % [real, at.y])
			if is_nan(real):
				why.append("no floor under it")
			if sp.has("tray"):
				var c: Vector3 = sp.tray
				for k in 8:
					var rp := c + Vector3(cos(TAU * k / 8.0), 0, sin(TAU * k / 8.0)) * (Dice.TRAY_R + 0.016)
					var under := _floor_at(space, rp, eye.y - 0.3)
					if not is_nan(under) and absf(under - c.y) > 0.012:
						why.append("tray's foot off the floor (%.3f there)" % under)
						break
			if not Dice._clean(s, sp):
				why.append("no clean throw (%s)" % _misses(sp, eye, deg * 7919 + 13))
			elif not Dice._near(s, sp):
				fallbacks += 1
			for k in 2:
				var fr: Array = s.frames[k]
				for fi in range(0, fr.size(), 3):
					var tr := Transform3D(Basis(fr[fi][1] as Quaternion), fr[fi][0])
					var w := _what(space, tr, DiceSim.S * 0.9)
					if w != "":
						why.append("die %d into %s at %.2fs (%.2f, %.2f, %.2f)" % [k, w, fi / DiceSim.FPS, tr.origin.x, tr.origin.y, tr.origin.z])
						break
			all += 1
			if not why.is_empty():
				bad += 1
				lines.append("  %3d°  %s" % [deg, " | ".join(why)])
		print("== %s (eye %.2f %.2f %.2f): %d of %d ways round" % [p, eye.x, eye.y, eye.z, lines.size(), 360 / step])
		for l in lines:
			print(l)
	print("== %d of %d throws wrong; %d more came down clean but off where they were meant to" % [bad, all, fallbacks])
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
