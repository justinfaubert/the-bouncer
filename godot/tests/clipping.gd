extends SceneTree
# Nobody through anything: a night played the way tests/smoke.gd plays it, seeded, waiting out every
# walk, and on every frame each person in the room, standing or walking, is a body (a column a
# hand off the floor to the top of the head, as wide as a body) held up against everything drawn in
# the building: the walls, the bar, the tables, the pool table, the trucks, and the doors as they are
# that frame (open, shut or swinging). Seated people sit on their stools and their knees go under
# tables, so only the doors count for them. Two people standing in one another counts too. Prints
# each thing walked into once, with who, where and when; fails if there's any.
#   godot --headless --path godot -s res://tests/clipping.gd -- --seed 2 --steps 200

var main
var rs := 7
var steps := 300
var errors := Errors.new()
const BODY_R := 0.16        # a body's half-width round the middle, for the probe (shoulders swing past it)
const FOOT := 0.25          # what's lower than this is a step, a mat, a foot rail: stepped over
const HEAD := 1.7
const APART := 0.36         # two people's middles closer than this are in each other
var probe := CylinderShape3D.new()
var q := PhysicsShapeQueryParameters3D.new()
var seen := {}              # what's been reported, so each thing's said once
var bad := 0
var frames := 0
var stuck := 0.0
const DOORS := ["leaf_l", "leaf_r", "swing", "deck_door", "hotel_door", "kitchen_door"]


class Errors extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			count += 1


func rnd() -> int:
	rs = (rs * 48271) % 2147483647
	return rs


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--seed": rs = int(args[i + 1]); i += 1
			"--steps": steps = int(args[i + 1]); i += 1
		i += 1
	OS.add_logger(errors)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame
		_check()


# a solid copy of everything drawn in the building (not the people, who are the stage's)
func _solidify(n: Node, door: String) -> void:
	for c in n.get_children():
		var d := door
		for k in main.pub.dyn:
			if main.pub.dyn[k] is Node and main.pub.dyn[k] == c:
				d = str(k)
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and not (c.mesh is QuadMesh):
			(c as MeshInstance3D).create_trimesh_collision()
			for b in c.get_children():
				if b is StaticBody3D:
					b.set_meta("what", d if d != "" else str(c.get_parent().name) + "/" + str(c.name))
					if d in DOORS or d.begins_with("wc_"):
						b.set_meta("door", d)
		if not c is StaticBody3D:
			_solidify(c, d)


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	main.start_new(3)
	await _frames(10)
	_solidify(main.pub, "")
	await physics_frame
	await physics_frame
	probe.radius = BODY_R
	probe.height = HEAD - FOOT
	q.shape = probe
	var made := 0
	var guard := 0
	while made < steps and guard < steps * 2000:
		guard += 1
		await _frames(1)
		if main.game.ended:
			print("ENDED after %d choices" % made)
			break
		if not main.stage.walkers.is_empty():
			# a minute of walking with the night held for it is a walker who isn't getting there
			stuck += main.get_process_delta_time()
			if stuck < 60.0:
				continue
			for id in main.stage.walkers:
				var wk: Dictionary = main.stage.walkers[id]
				var at: Vector3 = Nav.at(wk.path, wk.s)[0]
				bad += 1
				print("  WRONG  %s stuck walking at (%.2f, %.2f), %.1f of %.1f m, %s, to %s" % [id, at.x, at.z, wk.s, wk.len, main.game.status().clockText, str(wk.to)])
		stuck = 0.0
		if main.rolling != null:
			if main.rolling.has_method("finish"):
				main.rolling.finish()
			await _frames(2)
			continue
		if main.pending != null:
			main._go_on()
			await _frames(1)
			continue
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			await _frames(5)
			continue
		if made % 20 == 0:
			print("  %s %s, %d choices" % [main.game.status().clockText, main.game.here(), made])
		main.choose(rnd() % list.size())
		made += 1
		# a few frames for the room to answer, and the doors to finish swinging
		await _frames(150)
	var st: Dictionary = main.game.status()
	print("choices %d, clock %s, %d frames looked at, %d things walked into, %d script errors" % [made, st.clockText, frames, bad, errors.count])
	main.store.clear(3)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	print("== all right" if bad == 0 else "== WRONG")
	quit(1 if bad > 0 or errors.count > 0 else 0)


func _check() -> void:
	if main == null or main.stage == null or q.shape == null or probe.radius == 0.0:
		return
	frames += 1
	var stage: Stage = main.stage
	var space: PhysicsDirectSpaceState3D = main.pub.get_world_3d().direct_space_state
	var clock := str(main.game.status().clockText)
	var bodies: Array = []
	for id in stage.figures:
		var f: Dictionary = stage.figures[id]
		var node := f.node as Node3D
		if node == null or not is_instance_valid(node) or node.get_parent() != stage or not node.is_visible_in_tree():
			continue
		var spot := str(f.spot)
		if spot != "" and stage.SPOTS.has(spot) and (stage.SPOTS[spot].get("in", "") != "" or not str(stage.SPOTS[spot].zone) in Stage.WALKABLE):
			continue
		var walking: bool = stage.walkers.has(id)
		var seated: bool = not walking and spot != "" and stage._seated(spot)
		var p := node.global_position
		q.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, p.y + FOOT + probe.height / 2.0, p.z))
		for hit in space.intersect_shape(q, 8):
			var col = hit.collider
			if col == null or not col.has_meta("what"):
				continue
			if seated and not col.has_meta("door"):
				continue
			# a walker's first step up off a stool and last one onto it: the stool's under them
			if walking and str(col.get_meta("what")).contains("stool"):
				var wk: Dictionary = stage.walkers[id]
				if float(wk.s) < 0.45 or float(wk.len) - float(wk.s) < 0.45:
					continue
			var what := str(col.get_meta("what"))
			var key := "%s|%s|%s" % [id, what, "walk" if walking else spot]
			if seen.has(key):
				continue
			seen[key] = true
			bad += 1
			print("  WRONG  %s %s at (%.2f, %.2f) %s: through %s" % [id, ("walking to " + str(stage.walkers[id].to)) if walking else ("at " + spot), p.x, p.z, clock, what])
		if not seated:
			bodies.append([id, p, walking, ("walking, waited %.1f s" % float(stage.walkers[id].get("waited", 0.0))) if walking else spot])
	for i in bodies.size():
		for j in range(i + 1, bodies.size()):
			var a: Array = bodies[i]
			var b: Array = bodies[j]
			if Vector2(a[1].x - b[1].x, a[1].z - b[1].z).length() < APART:
				var key := "%s+%s" % [a[0], b[0]] if str(a[0]) < str(b[0]) else "%s+%s" % [b[0], a[0]]
				if seen.has(key):
					continue
				seen[key] = true
				bad += 1
				print("  WRONG  %s (%s) and %s (%s) in each other at (%.2f, %.2f) and (%.2f, %.2f) %s" % [a[0], a[3], b[0], b[3], a[1].x, a[1].z, b[1].x, b[1].z, clock])
