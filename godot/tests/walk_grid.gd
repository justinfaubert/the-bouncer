extends SceneTree
# Where a man can walk on the ground floor, for world/nav.gd: every ten centimetres over the bar,
# the back strip, the deck, the lobby and the lot, how far it is to the nearest thing a body would
# walk into (a stool, a table's edge, the bar, a wall, a truck), from a hand above the floor to
# over his head, with the doors that swing out of his way left out (they open as he comes to them)
# and nobody in the room (the people are worked in as he goes). Only what can be walked to from
# the floor counts: the inside of the pool table or a wall is nowhere. Writes
# textures/walk_grid.png, the distance in centimetres in each pixel (x east, z down the image);
# run it again when the room changes.
#   godot --headless --path godot -s res://tests/walk_grid.gd

var main
const PROBE := 0.06         # the probe's own radius: the cells are 0.1 apart, so they overlap
const LOW := 0.2            # what's lower than this off the floor is stepped over (a mat, a wedge, a step)
const HIGH := 1.95          # a door's head is higher than this
const REACH := 0.26         # how far a big man's body comes out from where he stands


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


# a solid copy of everything drawn, for the probes (the window glass too: a body stops at it)
func _solidify(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and not (c.mesh is QuadMesh) \
				and (c as MeshInstance3D).is_visible_in_tree():
			(c as MeshInstance3D).create_trimesh_collision()
		if not c is StaticBody3D:
			_solidify(c)


func _run() -> void:
	await _frames(5)
	main.start_new(2)
	await _frames(10)
	for id in main.stage.figures:
		(main.stage.figures[id].node as Node3D).visible = false
	var dyn: Dictionary = main.pub.dyn
	for k in dyn:
		var n = dyn[k]
		if n is Node3D and (str(k) in ["leaf_l", "leaf_r", "swing", "deck_door", "hotel_door", "kitchen_door", "rain", "coaster", "hotel_wedge"]
				or str(k).begins_with("wc_")):
			(n as Node3D).visible = false
	# the trucks where they park: walked round, whether they're there or not; and the yellow sign
	# where it stands on the tiles inside the door when it's out
	(dyn.truck as Node3D).visible = true
	(dyn.work_truck as Node3D).visible = true
	(dyn.sign_out as Node3D).visible = true
	_solidify(main.pub)
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
	var W := Nav.SIZE.x
	var H := Nav.SIZE.y
	var blocked := PackedByteArray()
	blocked.resize(W * H)
	var probe := CylinderShape3D.new()
	probe.radius = PROBE
	probe.height = HIGH - LOW
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = probe
	var t0 := Time.get_ticks_msec()
	var free_n := 0
	for j in H:
		for i in W:
			var p := Nav.world(Vector2i(i, j))
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, 1.2, p.z), Vector3(p.x, -0.6, p.z)))
			var b := 1
			if not hit.is_empty() and absf(float(hit.position.y)) < 0.3:
				var fy := float(hit.position.y)
				q.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, fy + LOW + probe.height / 2.0, p.z))
				if space.intersect_shape(q, 1).is_empty():
					b = 0
					free_n += 1
			blocked[j * W + i] = b
	print("probed %d cells in %.1fs, %d clear" % [W * H, (Time.get_ticks_msec() - t0) / 1000.0, free_n])
	# how far each cell is from the nearest blocked one, in centimetres (to 2.55 m)
	var dist := PackedFloat32Array()
	dist.resize(W * H)
	dist.fill(9.99)
	var R := 25
	var offs: Array = []
	for dj in range(-R, R + 1):
		for di in range(-R, R + 1):
			var d := Vector2(di, dj).length() * Nav.CELL
			if d <= R * Nav.CELL:
				offs.append([di, dj, d])
	offs.sort_custom(func(a, b): return a[2] < b[2])
	for j in H:
		for i in W:
			if blocked[j * W + i] == 1:
				dist[j * W + i] = 0.0
				continue
			for o in offs:
				var ii: int = i + o[0]
				var jj: int = j + o[1]
				if ii < 0 or jj < 0 or ii >= W or jj >= H or blocked[jj * W + ii] == 1:
					dist[j * W + i] = maxf(0.0, float(o[2]) - PROBE)
					break
	# only what can be walked to from the floor, by a man his size
	var seen := PackedByteArray()
	seen.resize(W * H)
	var stack: Array = []
	for post in ["floor", "lot", "deck", "kitchen", "hall"]:
		var c := Nav.cell(Posts.POSTS[post].at)
		stack.append(c)
	var reached := 0
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if c.x < 0 or c.y < 0 or c.x >= W or c.y >= H:
			continue
		var k := c.y * W + c.x
		if seen[k] == 1 or dist[k] < REACH:
			continue
		seen[k] = 1
		reached += 1
		stack.append(c + Vector2i(1, 0))
		stack.append(c + Vector2i(-1, 0))
		stack.append(c + Vector2i(0, 1))
		stack.append(c + Vector2i(0, -1))
	# the band round what he can reach, where a slighter body can still go, stays as it is; what's
	# walled off from all of it is nowhere
	var img := Image.create(W, H, false, Image.FORMAT_L8)
	var kept := 0
	for j in H:
		for i in W:
			var k := j * W + i
			var near := false
			if seen[k] == 0:
				for o in [Vector2i(0, 0), Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3), Vector2i(2, 2), Vector2i(-2, 2), Vector2i(2, -2), Vector2i(-2, -2)]:
					var ii: int = i + o.x
					var jj: int = j + o.y
					if ii >= 0 and jj >= 0 and ii < W and jj < H and seen[jj * W + ii] == 1:
						near = true
						break
			var v := 0
			if seen[k] == 1 or near:
				v = clampi(roundi(dist[k] * 100.0), 0, 255)
				kept += 1
			img.set_pixel(i, j, Color8(v, v, v))
	var path := ProjectSettings.globalize_path("res://textures/walk_grid.png")
	img.save_png(path)
	print("reached %d cells from the floor; wrote %s" % [reached, path])
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
