extends "res://tests/feet.gd"
# The grounds round the Sov at night (world/grounds.gd), on his own feet, the way a player does it:
# plays the night on to the floor, steps out front, and walks W across the lot and the highway to
# the seawall, where the man fishing is. He must be on the ground the whole way (never inside
# anything, never under or over it), each area named once as he gets to it, and the man fishing
# only there to look at once he's walked up to him; handling him takes the choice that goes to
# him (content/ink/grounds.ink), and leaving him brings the night back out front. Then he's put
# down at each of the other things out there that are more than a look, and each one's choice is
# taken and left the same way; and at every thing in things.yaml that's out of doors, a look says
# something. With --out it takes pictures as it goes.
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/grounds.gd -- --out DIR

# the things out there that are more than a look: [where he stands (x, z), the knot it takes]
const HANDLED := {
	"buzzers": [Vector2(19.6, 2.6), "out_buzzers"],
	"caps": [Vector2(3.4, -4.6), "out_caps"],
	"kelp": [Vector2(-3.0, 43.4), "out_kelp"],
	"beach_fire": [Vector2(22.0, 39.0), "out_fire"],
	"cross": [Vector2(-36.0, 26.0), "out_cross"],
	"esso_clerk": [Vector2(-144.6, 13.6), "out_clerk"],
}


# on the ground where he is: his eyes the height he stands above it, and room for him there
func _grounded() -> bool:
	var gy := Grounds.ground_y(v.eye_pos.x, v.eye_pos.z)
	return absf(v.eye_pos.y - gy - Posts.STAND) < 0.05 and Grounds.clearance(v.eye_pos) >= Nav.BODY - 0.02


func _put(g: Vector2, look: Vector3) -> void:
	var gy := Grounds.ground_y(g.x, g.y)
	v.eye_pos = Vector3(g.x, gy + Posts.STAND, g.y)
	v.floor_spot = Vector3(g.x, gy, g.y)
	var a := Posts.aim(v.eye_pos, look)
	v.yaw = a.x
	v.want_yaw = a.x
	v.pitch = a.y
	v.want_pitch = a.y
	await _frames(4)


# how many times the story's been in a knot
func _visits(knot: String) -> int:
	return int(main.game.story.state().visit_count_at_path_string(knot))


# leave whatever he's handling, by its last choice, till he's back out front
func _leave() -> bool:
	for n in 8:
		await _settle(2.0)
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			continue
		if list.any(func(c): return str(c.get("text", "")).contains("Stand in the air")):
			return true
		main.choose(list.size() - 1)
	return false


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			out = args[i + 1]
	if out != "":
		DirAccess.make_dir_recursive_absolute(out)
	await _frames(5)
	main.settings["dice"] = "quick"
	main.settings["keys_walk"] = true
	v = main.view
	if not await _a_night():
		print("never got out onto the floor: " + _here())
		await _done()
		return
	await _free_on_floor()
	var front := -1
	var list: Array = main.game.visible_choices()
	for i in list.size():
		if str(list[i].get("text", "")).contains("Step out front"):
			front = i
	_ok("stepping out front is on offer", front >= 0)
	if front < 0:
		await _done()
		return
	main.choose(front)
	await _settle()
	_ok("out front, in the lot", v.place == "lot", _here())
	_ok("the grounds are there", main.pub.grounds != null)

	# across the lot and the highway to the seawall, on his feet
	var merle_far: bool = main.spots.look_spot("merle").is_empty()
	_ok("the man fishing isn't to be found from the door", merle_far)
	var grounded := true
	var named := {}
	for p in [Vector3(8.0, 0, 26.0), Vector3(6.0, 0, 34.6), Vector3(3.4, 0, 35.0)]:
		await _key(KEY_W, true)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 16000:
			await process_frame
			if main.pending != null:
				break
			var a := Posts.aim(v.eye_pos, Vector3(p.x, v.eye_pos.y - 0.15, p.z))
			v.yaw = a.x
			v.want_yaw = a.x
			grounded = grounded and _grounded()
			named[Grounds.area_of(v.eye_pos)] = true
			if _off(p) < 0.45:
				break
		await _key(KEY_W, false)
		await _frames(10)
	_ok("walked out to the seawall", _off(Vector3(3.4, 0, 35.0)) < 1.0, _here())
	_ok("on the ground the whole way, never inside anything", grounded, _here())
	_ok("crossed the highway", named.has("road"), str(named.keys()))
	_ok("still out front as far as the night goes", v.place == "lot", _here())
	await _face(Vector3(2.0, 0, 36.0))
	await _grab("1_seawall_merle")
	_ok("the man fishing, found by walking up to him", not main.spots.look_spot("merle").is_empty())
	var said: String = main.toy("merle", "look")
	await _settle(3.0)
	_ok("handling him takes the choice to him", said == "chose" and _visits("out_merle") == 1, "%s %d" % [said, _visits("out_merle")])
	_ok("and leaving him brings the night back out front", await _leave(), _here())

	# the other things out there that are more than a look
	for id in HANDLED:
		var g: Vector2 = HANDLED[id][0]
		var at = main.pub.anchors.get(id)
		await _put(g, at if at is Vector3 else Vector3(g.x, 0, g.y + 1.0))
		_ok("%s: clear standing there" % id, Grounds.clearance(v.eye_pos) >= Nav.BODY - 0.02, "%.2f" % Grounds.clearance(v.eye_pos))
		_ok("%s: there to look at, close up" % id, not main.spots.look_spot(id).is_empty())
		await _grab("2_" + id)
		var was := _visits(HANDLED[id][1])
		said = main.toy(id, "look")
		await _settle(3.0)
		_ok("%s: takes its choice" % id, said == "chose" and _visits(HANDLED[id][1]) == was + 1, "%s %d" % [said, _visits(HANDLED[id][1])])
		_ok("%s: and comes back out front" % id, await _leave(), _here())

	# every thing out of doors says something when it's looked at
	var mute: Array = []
	for id in main.content.get("things", {}):
		var t: Dictionary = main.content.things[id]
		if t.get("near") == null:
			continue
		if not main.game.story.has_function("toy_" + id):
			mute.append(id)
			continue
		var out_said = main.game.story.evaluate_function("toy_" + id, ["look"], true)
		if not (out_said is Dictionary and str(out_said.get("output", "")).strip_edges() != ""):
			mute.append(id)
	_ok("every thing out there says something", mute.is_empty(), str(mute))
	_ok("no script errors", errors.count == 0, str(errors.count))
	await _done()
