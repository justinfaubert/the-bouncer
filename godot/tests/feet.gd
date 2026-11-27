extends "res://tests/going.gd"
# His own feet (game/feet.gd), the way a player does it, with real key presses: plays the night on
# to the floor the way tests/going.gd does, then walks him with W A S D. He must move where he's
# looking and never through a table, a wall or a person; a walk across the room must take its
# minute; standing in a place's floor must name it at the foot of the picture, and E settle him
# there; holding a key there must get him up and out onto the floor; walking through the deck door
# must take him out on the deck, where he walks about, and back in through it onto the floor; and
# out the front he walks the lot. Alt with D leans him. With --out it takes pictures as it goes.
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/feet.gd -- --out DIR

var out := ""


func _grab(name: String, settle := 20) -> void:
	if out == "":
		return
	await _frames(settle)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot %s  %s" % [name, _here()])


func _key(k: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = down
	Input.parse_input_event(e)
	await process_frame


# hold a key this long (seconds), the night going on meanwhile
func _hold(k: Key, secs: float, with_shift := false) -> void:
	if with_shift:
		await _key(KEY_SHIFT, true)
	await _key(k, true)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
	await _key(k, false)
	if with_shift:
		await _key(KEY_SHIFT, false)


# turn him to face p (on the floor), his eyes level
func _face(p: Vector3) -> void:
	var a := Posts.aim(v.eye_pos, Vector3(p.x, v.eye_pos.y - 0.15, p.z))
	v.yaw = a.x
	v.want_yaw = a.x
	v.pitch = a.y
	v.want_pitch = a.y
	await _frames(2)


# walk toward p with W till he's within near of it, or it's been secs; whether he got there
func _walk_to(p: Vector3, near := 0.5, secs := 12.0) -> bool:
	await _key(KEY_W, true)
	var t0 := Time.get_ticks_msec()
	var ok := false
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		if v.walking or main.pending != null:
			break
		var a := Posts.aim(v.eye_pos, Vector3(p.x, v.eye_pos.y - 0.15, p.z))
		v.yaw = a.x
		v.want_yaw = a.x
		if _off(p) < near:
			ok = true
			break
	await _key(KEY_W, false)
	return ok


# never inside anything: the walk map's room for his body where he's standing
func _clear_here() -> bool:
	return Nav.clearance(Vector3(v.eye_pos.x, 0, v.eye_pos.z)) >= Nav.BODY - 0.005


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
	print("on the floor: " + _here())
	_ok("the view's wider than it was", float(main.settings.get("fov", 0)) >= 70.0, str(main.settings.get("fov")))
	_ok("free to walk here", main.feet.free_here())
	await _grab("1_floor", 30)

	# W walks him the way he's looking, and the clock takes its minute when he stops
	var c0 := _clock()
	var p0 := v.eye_pos
	await _face(Vector3(10.5, 0, 3.0))
	await _hold(KEY_W, 3.0)
	await _frames(40)
	_ok("W walks him forward", _off(p0) > 2.6, "%.2f m" % _off(p0))
	var fwd := Vector2(-sin(v.yaw), -cos(v.yaw))
	var moved := Vector2(v.eye_pos.x - p0.x, v.eye_pos.z - p0.z)
	_ok("the way he's looking", moved.normalized().dot(fwd) > 0.7, "%.2f" % moved.normalized().dot(fwd))
	_ok("never inside anything", _clear_here())
	var tw := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tw < 1200:
		await process_frame
	await _settle()
	_ok("a walk across the room is a minute", _clock() > c0, "%d -> %d" % [c0, _clock()])

	# walking at the pool table: stops at its rail, doesn't go through
	await _free_on_floor()
	await _face(Vector3(9.4, 0, 3.9))
	var blocked := true
	await _key(KEY_W, true)
	for n in 240:
		await process_frame
		if v.walking:
			break
		if not _clear_here():
			blocked = false
	await _key(KEY_W, false)
	_ok("into the pool table: stopped at it, never through", blocked, _here())
	await _grab("2_at_the_table")

	# the bar: walked up to, named, E settles him
	await _settle()
	await _free_on_floor()
	# up to the stools, facing the bar
	var bar_spot := Vector3(4.9, 0.0, 5.45)
	var got := await _walk_to(bar_spot, 0.3)
	await _face(Vector3(1.0, 0, 5.0))
	await _frames(6)
	var named: bool = main.feet.hint.visible and main.feet.hint.text.contains("E")
	if not named:
		var fw := Vector3(-sin(v.yaw), 0, -cos(v.yaw))
		for ah in [0.0, 1.0, 2.0]:
			var q: Vector3 = Vector3(v.eye_pos.x, 0, v.eye_pos.z) + fw * ah
			print("  at ", q, " zone ", Hotspots.zone_of(q + Vector3(0, 1, 0)), " area ", Posts.area_of(q, Hotspots.zone_of(q + Vector3(0, 1, 0))))
		print("  mode ", main.feet.mode(), " way to bar ", main.going._way_to("bar"))
	_ok("walked up to the bar", got, _here())
	_ok("its name at the foot of the picture", named, main.feet.hint.text)
	await _grab("3_bar_named", 6)
	if named:
		await _key(KEY_E, true)
		await _key(KEY_E, false)
		await _settle()
		_ok("E settles him at the bar", v.place == "bar", _here())
		# holding a key there gets him up, out onto the floor
		if await _till_the_floor_way("bar"):
			await _hold(KEY_S, 0.6)
			await _settle()
			_ok("holding S gets him up from the bar", v.place == "floor", _here())

	# the deck: through its door is going out on it
	await _free_on_floor()
	var deck_door: Vector3 = Posts.DOORWAYS["deck"]
	await _walk_to(Vector3(15.3, 0, 7.1), 0.5, 15.0)
	await _face(Vector3(17.5, 0, 7.1))
	await _key(KEY_W, true)
	for n in 300:
		await process_frame
		if v.walking or v.place == "deck":
			break
	await _key(KEY_W, false)
	await _settle()
	_ok("through the deck door, out on the deck", v.place == "deck", _here())
	if v.place == "deck":
		await _grab("4_deck", 30)
		var d0 := v.eye_pos
		_ok("free to walk on the deck", main.feet.free_here())
		await _face(Vector3(19.5, 0, 9.5))
		await _hold(KEY_W, 1.2)
		await _frames(30)
		_ok("walks about the deck", _off(d0) > 0.6, "%.2f m" % _off(d0))
		_ok("still on the deck, inside it", Hotspots.zone_of(v.eye_pos) == "deck" and Nav.clearance(Vector3(v.eye_pos.x, 0, v.eye_pos.z)) >= Feet.TIGHT - 0.005, _here())
		await _grab("5_deck_walked")
		# lean round: Alt and D
		await _key(KEY_ALT, true)
		await _key(KEY_D, true)
		await _frames(30)
		_ok("Alt and D lean him", v.lean_off > 0.1, "%.2f" % v.lean_off)
		await _grab("6_lean", 2)
		await _key(KEY_D, false)
		await _key(KEY_ALT, false)
		await _frames(30)
		_ok("and back upright", absf(v.lean_off) < 0.02)
		# back in through the door, onto the floor
		await _settle()
		if main.feet.free_here():
			# round the table on the deck, by the wall, to the door
			await _walk_to(Vector3(16.6, 0, 9.0), 0.3, 10.0)
			# somebody on the deck may be standing in the way: round them, as a player would
			for x in [16.6, 16.2, 17.0]:
				if await _walk_to(Vector3(x, 0, 7.2), 0.3, 6.0):
					break
			await _face(deck_door + Vector3(-2.0, 0, 0))
			await _key(KEY_W, true)
			for n in 300:
				await process_frame
				if v.walking or v.place != "deck":
					break
			await _key(KEY_W, false)
			await _settle()
			_ok("back in through the door, on the floor", v.place == "floor", _here())

	# out front: the lot
	await _free_on_floor()
	var front := -1
	var list: Array = main.game.visible_choices()
	for i in list.size():
		if str(list[i].get("text", "")).contains("Step out front"):
			front = i
	_ok("stepping out front is on offer", front >= 0)
	if front >= 0:
		main.choose(front)
		await _settle()
		_ok("out front, in the lot", v.place == "lot", _here())
		await _grab("7_front", 40)
		if main.feet.free_here():
			var l0 := v.eye_pos
			await _face(Vector3(8.0, 0, 18.0))
			await _key(KEY_W, true)
			await _frames(45)
			_ok("walking, the picture has the whole screen", v.world_w > 0.95, "%.2f" % v.world_w)
			await _grab("8a_walking_whole_screen", 1)
			await _hold(KEY_W, 0.8)
			await _frames(30)
			_ok("walks about the lot", _off(l0) > 1.0, "%.2f m" % _off(l0))
			_ok("never inside anything out there", _clear_here(), _here())
			await _grab("8_lot_walked")
			await _face(Vector3(5.0, 5.2, 10.1))
			await _grab("9_lot_back_at_the_sov")
	var tp := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tp < 2500:
		await process_frame
	_ok("stopped, the page is back", v.world_w < 0.7, "%.2f" % v.world_w)
	_ok("no script errors", errors.count == 0, str(errors.count))
	await _done()
