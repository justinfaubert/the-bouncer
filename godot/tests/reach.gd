extends SceneTree
# Whether the room answers to the choices: plays seeded nights at random, headless, and at every
# choice on offer asks what in the room it's pinned to (game/hotspots.gd) and whether he could put
# his eyes on that from where he is: there, in a part of the building he can see from here, not too
# far up or down, and nothing drawn in the way. Lists, once each, the choices whose thing isn't
# there at all, and the ones pinned to something he couldn't see; and with --all, what each is
# pinned to, the ones about something out of sight (they stay in the column), and the ones
# nothing in the room answers to, to read through. And the same for the things he can look at
# (content/data/things.yaml) from each post: any he'd be shown that something's in the way of, and
# with --all, which he can look at from where. Gives the room a solid copy of its mesh to ask (not
# the glass: he sees through the window, the panes in the door and the screen by it).
#   godot --headless --path godot -s res://tests/reach.gd -- --seeds 1-20 --steps 400 [--all]

var main
var rs := 7
var seeds := [1, 2, 3, 4, 5, 6, 7, 8]
var steps := 400
var all := false
var found := {}          # problem line -> count
var free := {}           # place | text -> count (nothing in the room answers to it)
var pinned := {}         # place | key | text -> count
var away := {}           # place | key | text -> count (about something out of sight from here)
var looks := {}          # post -> {thing: true}: the things he could look at from there


func rnd() -> int:
	rs = (rs * 48271) % 2147483647
	return rs


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--seeds":
				var r := str(args[i + 1]).split("-")
				seeds = []
				for s in range(int(r[0]), int(r[r.size() - 1]) + 1):
					seeds.append(s)
				i += 1
			"--steps": steps = int(args[i + 1]); i += 1
			"--all": all = true
		i += 1
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _count(d: Dictionary, k: String) -> void:
	d[k] = int(d.get(k, 0)) + 1


# a solid copy of the room as it's drawn now (not the people, and not the glass: he sees through
# the window, the door's panes and the screen by the door), for the lines of sight
func _solidify(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and not (c.mesh is QuadMesh) \
				and (c as MeshInstance3D).is_visible_in_tree():
			_solid(c as MeshInstance3D)
		if not c is StaticBody3D:
			_solidify(c)


func _solid(mi: MeshInstance3D) -> void:
	var faces := PackedVector3Array()
	for si in mi.mesh.get_surface_count():
		var m := mi.get_active_material(si)
		if m is ShaderMaterial and (m as ShaderMaterial).shader == main.pub.GLASS:
			continue
		var arr := mi.mesh.surface_get_arrays(si)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx = arr[Mesh.ARRAY_INDEX]
		if idx == null or (idx as PackedInt32Array).is_empty():
			faces.append_array(verts)
		else:
			for k in idx:
				faces.append(verts[k])
	if faces.is_empty():
		return
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	mi.add_child(body)


# what a line of sight ran into: its name, if it has one, and where it is and how big
func _named(mi: Node) -> String:
	var nm := str(mi.name)
	var up := mi.get_parent()
	if up != null and up != main.pub and not str(up.name).begins_with("@"):
		nm = str(up.name) + "/" + nm
	if mi is MeshInstance3D:
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		var c := bb.get_center()
		nm += " at (%.2f, %.2f, %.2f) %.2fx%.2fx%.2f" % [c.x, c.y, c.z, bb.size.x, bb.size.y, bb.size.z]
	return nm


# whatever's in the way of a line of sight to a thing at p, of size r: "" for nothing
func _blocked(space: PhysicsDirectSpaceState3D, eye: Vector3, p: Vector3, r: float, key: String) -> String:
	var a: Vector2 = Posts.aim(eye, p)
	if a.y < View.PITCH_MIN or a.y > View.PITCH_MAX:
		return "too far up or down (%s)" % key
	# nothing drawn in the way, short of the thing itself; a big thing (a truck, table 28) is seen
	# if any of it is, so its middle, a point either side of it, or one over it (a bar of the
	# window can hide the middle of a truck and none of the rest)
	var side := (p - eye).cross(Vector3.UP).normalized() * r * 0.5
	var tries: Array = [p] if r < 0.9 else [p, p + side, p - side, p + Vector3(0, r * 0.3, 0)]
	var why := ""
	for q in tries:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, q))
		if hit.is_empty() or eye.distance_to(hit.position) >= eye.distance_to(q) - r - 0.3:
			return ""
		if why == "":
			why = "behind %s (%s)" % [_named((hit.collider as Node).get_parent()), key]
	return why


# the things to look at, as they stand from here
func _things(post: String, eye: Vector3, space: PhysicsDirectSpaceState3D) -> void:
	var hs: Hotspots = main.spots
	for id in hs.things:
		var tw: Array = hs.look_spot(str(id))
		if tw.is_empty():
			continue
		if not looks.has(post):
			looks[post] = {}
		looks[post][id] = true
		var tb := _blocked(space, eye, tw[0], float(tw[1]), str(tw[2]))
		if tb != "":
			_count(found, "%s | look: %s | %s" % [post, id, tb])


# every post and every way a place is seen, before the night's begun: the things from each
func _every_post() -> void:
	var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
	var all_posts: Array = Posts.POSTS.keys()
	for f in Posts.FRAMES:
		all_posts.append(f)
	for p in all_posts:
		var place: String = str(p).get_slice(":", 0)
		main.view.frame = str(p).get_slice(":", 1) if ":" in str(p) else ""
		main.view.jump_to(place)
		await _frames(2)
		_things(str(p), main.view.eye_pos, space)
	main.view.frame = ""


# everything on offer now, against the room as it stands
func _look() -> void:
	var hs: Hotspots = main.spots
	var post: String = main.view.place
	if main.view.frame != "":
		post += ":" + str(main.view.frame)
	var eye: Vector3 = main.view.eye_pos
	var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
	_things(post, eye, space)
	var list: Array = main.game.visible_choices()
	for i in list.size():
		var c: Dictionary = list[i]
		var text := str(c.get("text", ""))
		var key: String = hs._about(c)
		if key == "":
			_count(free, "%s | %s" % [post, text])
			continue
		var s := {"i": i, "key": key, "text": text, "loc": Hotspots.loc_of(c)}
		var w: Array = hs.resolve(s)
		var why := ""
		if w.is_empty():
			# nothing he can see: is the thing anywhere at all?
			var anywhere := false
			for k in key.split("|"):
				if not hs._where(k).is_empty():
					anywhere = true
			if anywhere:
				_count(away, "%s | %s | %s" % [post, key, text])
				continue
			why = "not there"
		else:
			_count(pinned, "%s | %s | %s" % [post, w[2], text])
			why = _blocked(space, eye, w[0], float(w[1]), str(w[2]))
		if why != "":
			_count(found, "%s | %s | %s | %s" % [post, key, why, text])


func _night(seed: int) -> void:
	rs = seed
	main.start_new(3)
	await _frames(3)
	for b in main.pub.find_children("*", "StaticBody3D", true, false):
		b.queue_free()
	await _frames(1)
	_solidify(main.pub)
	await physics_frame
	await physics_frame
	if seed == seeds[0]:
		await _every_post()
		main.view.jump_to(str(main.game.here()))
		await _frames(2)
	var made := 0
	var guard := 0
	while made < steps and guard < steps * 40:
		guard += 1
		await _frames(1)
		if main.game.ended:
			break
		if main.rolling != null:
			if main.rolling.has_method("finish"):
				main.rolling.finish()
			await _frames(2)
			continue
		if main.pending != null:
			main._go_on()
			await _frames(1)
			continue
		if main.view.walking:
			# no need to see him walk there: be there
			main.view.jump_to(main.view.place)
			await _frames(1)
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			await _frames(5)
			continue
		if main.props.holding():
			main.props.put_down()
			await _frames(1)
		# the room as it'll be once he's blinked (world/stage.gd moves people he can see only then)
		main.stage.sync(main.game, true)
		_look()
		main.choose(rnd() % list.size())
		made += 1
	main.back_to_title()
	await _frames(2)
	main.store.clear(3)


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	for s in seeds:
		await _night(s)
		print("  night %d done: %d problems so far" % [s, found.size()])
	print("== choices about something he can't put his eyes on (%d)" % found.size())
	var keys: Array = found.keys()
	keys.sort()
	for k in keys:
		print("  %4d  %s" % [found[k], k])
	if all:
		print("== choices pinned to something (%d)" % pinned.size())
		var pk: Array = pinned.keys()
		pk.sort()
		for k in pk:
			print("  %4d  %s" % [pinned[k], k])
		print("== choices about something out of sight from here, left in the column (%d)" % away.size())
		var ak: Array = away.keys()
		ak.sort()
		for k in ak:
			print("  %4d  %s" % [away[k], k])
		print("== things he can look at, from each post")
		var lk: Array = looks.keys()
		lk.sort()
		for k in lk:
			var ids: Array = looks[k].keys()
			ids.sort()
			print("  %-12s %s" % [k, ", ".join(ids)])
		print("== choices nothing in the room answers to (%d)" % free.size())
		var fk: Array = free.keys()
		fk.sort()
		for k in fk:
			print("  %4d  %s" % [free[k], k])
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
