extends SceneTree
# Where the tray can go down round each place with nothing in front of him to throw onto
# (game/dice.gd's TRAYS): every so many degrees round him, the nearest stretch of floor a step
# away that's flat under the whole tray, with nothing over it a throw could hit, no way through
# anything from his hand to it, and nobody's spot there (world/stage.gd), with the doors shut and
# propped open and the pickup in the lot. Gives everything drawn a solid copy of its mesh to ask.
# Prints the table to paste into dice.gd; run it again when the room changes.
#   godot --headless --path godot -s res://tests/tray_spots.gd -- [--every 30]

var main
var every := 30
const PLACES := ["floor", "hall", "keg", "deck", "lot", "upstairs", "hall:clerk", "lot:pickup", "lot:truck", "pool:juke"]
const OUT := Dice.TRAY_R + 0.04         # the tray's outside, and a hand's width of room round it
const UP := 0.6                         # how high over it a throw goes, and looks for the floor from
const AWAY := [0.8, 0.75, 0.85, 0.7, 0.9, 0.65, 0.95]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--every":
			every = int(args[i + 1])
			i += 1
		i += 1
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _solid(n: Node, on: bool) -> void:
	for c in n.get_children():
		if c is StaticBody3D:
			if not on:
				c.queue_free()
			continue
		if on and c is MeshInstance3D and (c as MeshInstance3D).mesh != null and not (c.mesh is QuadMesh) \
				and not str(c.get_path()).contains("faces") and (c as MeshInstance3D).is_visible_in_tree():
			(c as MeshInstance3D).create_trimesh_collision()
		_solid(c, on)


func _hits(space: PhysicsDirectSpaceState3D, shape: Shape3D, at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY, at)
	return not space.intersect_shape(q, 1).is_empty()


func _floor(space: PhysicsDirectSpaceState3D, p: Vector3, from_y: float) -> float:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, from_y, p.z), Vector3(p.x, from_y - 3.0, p.z)))
	return float(hit.position.y) if not hit.is_empty() else NAN


# could the tray go down at c (on the floor at fy), thrown into from his eye?
func _clear(space: PhysicsDirectSpaceState3D, eye: Vector3, c: Vector3, fy: float, zones: Array) -> bool:
	# flat under all of it
	for k in 9:
		var p := c if k == 8 else c + Vector3(cos(TAU * k / 8.0), 0, sin(TAU * k / 8.0)) * OUT
		var f := _floor(space, p, fy + UP)
		if is_nan(f) or absf(f - fy) > 0.006:
			return false
	# nothing over it, up to near his eyes (no counter or rail hanging over its edge)
	var cyl := CylinderShape3D.new()
	cyl.radius = OUT
	cyl.height = eye.y - fy - 0.3
	if _hits(space, cyl, c + Vector3(0, 0.015 + cyl.height / 2.0, 0)):
		return false
	# nothing between his hand and it, nor between his eyes and it (a mesh is only its skin, so
	# lines, which can't slip through a wall between two looks)
	var dir := Vector3(c.x - eye.x, 0, c.z - eye.z).normalized()
	var side := dir.cross(Vector3.UP)
	var hand := c - dir * 0.42 + Vector3(0, 0.5, 0)
	for off in [Vector3.ZERO, side * 0.05, side * -0.05]:
		for line in [[hand + off, c + off + Vector3(0, 0.03, 0)], [eye, c + off * 2.0 + Vector3(0, 0.02, 0)]]:
			if not space.intersect_ray(PhysicsRayQueryParameters3D.create(line[0], line[1])).is_empty():
				return false
	# nobody stands there
	for id in main.stage.SPOTS:
		var sp: Dictionary = main.stage.SPOTS[id]
		if sp.has("in") or not str(sp.zone) in zones:
			continue
		var at: Vector3 = sp.pos
		if absf(at.y - fy) < 0.6 and Vector2(at.x - c.x, at.z - c.z).length() < OUT + 0.34:
			return false
	return true


# 0.5 as 0.5, 3.4 as 3.4, -0.0 as 0.0
static func _num(v: float, places: int) -> String:
	var s := String.num(snappedf(v, pow(10.0, -places)), places)
	if s == "-0" or s == "-0.0":
		s = "0"
	return s if "." in s else s + ".0"


func _set_doors(open: bool) -> void:
	for d in ["deck_door", "kitchen_door", "hotel_door"]:
		main.pub.prop_door(d, open)
	(main.pub.dyn.truck as Node3D).visible = open


func _run() -> void:
	await _frames(5)
	main.start_new(2)
	await _frames(10)
	for id in main.stage.figures:
		(main.stage.figures[id].node as Node3D).visible = false
	# what's clear with the doors shut, then propped open (the pickup in the lot with them)
	var ok := {}
	for open in [false, true]:
		_set_doors(open)
		_solid(main.pub, false)
		await _frames(1)
		_solid(main.pub, true)
		await physics_frame
		await physics_frame
		var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
		for p in PLACES:
			var place: String = p.get_slice(":", 0)
			var post := Posts.post(place, p.get_slice(":", 1) if ":" in p else "")
			var eye: Vector3 = post.at
			var fy := _floor(space, eye, eye.y - 0.25)
			var zones: Array = Stage.SEEN.get(place, []).duplicate()
			if not place in zones:
				zones.append(place)
			for a in range(0, 360, every):
				var yaw := deg_to_rad(float(a))
				var dir := Vector3(-sin(yaw), 0, -cos(yaw))
				for d in AWAY:
					var c: Vector3 = Vector3(eye.x, fy, eye.z) + dir * float(d)
					var key := "%s|%d|%.2f" % [p, a, d]
					var was = ok.get(key, true)
					ok[key] = was and _clear(space, eye, c, fy, zones)
	_set_doors(false)
	# the nearest clear one each way round, written out as dice.gd keeps them
	var out := "const TRAYS := {\n"
	var total := 0
	for p in PLACES:
		var place: String = p.get_slice(":", 0)
		var post := Posts.post(place, p.get_slice(":", 1) if ":" in p else "")
		var eye: Vector3 = post.at
		var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
		var fy := _floor(space, eye, eye.y - 0.25)
		var list: Array = []
		for a in range(0, 360, every):
			var yaw := deg_to_rad(float(a))
			var dir := Vector3(-sin(yaw), 0, -cos(yaw))
			for d in AWAY:
				if ok.get("%s|%d|%.2f" % [p, a, d], false):
					var c: Vector3 = Vector3(eye.x, fy, eye.z) + dir * float(d)
					list.append("Vector3(%s, %s, %s)" % [_num(c.x, 2), _num(fy, 3), _num(c.z, 2)])
					break
		total += list.size()
		var line := "\t\"%s\": [" % p
		for i in list.size():
			var piece: String = list[i] + (", " if i < list.size() - 1 else "],")
			if line.length() + 3 + piece.length() > 112:
				out += line.strip_edges(false, true) + "\n"
				line = "\t\t"
			line += piece
		out += line + "\n"
		print("# %s: %d of %d ways round" % [p, list.size(), 360 / every])
	out += "}"
	print(out)
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
