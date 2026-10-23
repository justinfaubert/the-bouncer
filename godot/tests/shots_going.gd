extends "res://tests/going.gd"
# Pictures of going where he looks, to look at by eye: the night played on to the floor the way
# tests/going.gd plays it, then the page there (the ways gone from the column, and what it says
# instead), the ring on the floor under the pointer, the one where he's going, him out in the room
# where he was pointed, the ring over the bar's floor, leaning on the bar, and the heads come round
# when he runs.
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_going.gd -- --out DIR

var out := "/tmp/going"


func _grab(name: String, settle := 24) -> void:
	await _frames(settle)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot %s  %s" % [name, _here()])


# his eyes a little above p, and the pointer on it
func _over(p: Vector3, up := 0.22) -> void:
	await _point(p)
	v.pitch = clampf(v.pitch + up, View.PITCH_MIN, View.PITCH_MAX)
	v.want_pitch = v.pitch
	await _frames(3)
	v.pointer = v.cam.unproject_position(p)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	await _frames(5)
	main.settings["dice"] = "quick"
	v = main.view
	if not await _a_night():
		print("never got out onto the floor: " + _here())
		await _done()
		return
	# the page out on the floor, looking down the room
	await _point(Vector3(9.4, 1.0, 4.0))
	v.pointer = Vector2(-1, -1)
	await _grab("1_floor_page")
	# the ring under the pointer, on bare floor across the room
	var far: Vector3 = await _bare(3.2, 4.6)
	if far != Vector3.INF:
		await _over(far)
		await _grab("2_ring")
		var from := v.eye_pos
		main.going.click()
		v.pointer = Vector2(-1, -1)
		while v.walking and _off(from) < 1.0:
			await process_frame
		await _grab("3_going", 1)
		await _settle()
		await _grab("4_there")
	# the ring over the floor by the bar: the gap in its stools, where he'd stand
	await _free_on_floor()
	await _over(Vector3(2.95, 0.0, 4.3), 0.3)
	await _grab("5_ring_bar")
	main.going.click()
	await _settle()
	v.pointer = Vector2(-1, -1)
	await _grab("6_bar_lean", 60)
	# running back across the room: the heads come round
	await _free_on_floor()
	var run_to: Vector3 = await _bare(4.0, 6.0)
	if run_to != Vector3.INF:
		main.going.click()
		await _frames(3)
		v.hurry()
		var t0 := Time.get_ticks_msec()
		while v.walking and int(main.game.get_var("ran_room")) == 0 and Time.get_ticks_msec() - t0 < 20000:
			await process_frame
		v.pointer = Vector2(-1, -1)
		await _grab("7_ran", 30)
		await _settle()
	await _done()
