extends SceneTree
# The room round the board (game/darts_room.gd): with no shake, three thrown at the treble 20 from
# the Rehearse menu, then a turn told it was 180, a ton, bed and breakfast, a bust and a game shot,
# so every call and line runs once. Prints who was near enough to call it, the chalk, and the column's
# last lines; saves pictures of the hush and the 180 if --out is given. Needs a display:
#   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" godot \
#     --rendering-driver vulkan --resolution 1280x720 --path godot -s res://tests/darts_fanfare.gd -- [--out /tmp/fanfare]
var main
var out := ""
var fails := 0

func _init():
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		if args[k] == "--out":
			out = args[k + 1]
			DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()

func _frames(n):
	for k in n:
		await process_frame

func _grab(name):
	if out == "":
		return
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)

func _check(ok: bool, what: String):
	if not ok:
		fails += 1
		print("FAIL ", what)

func _r(n, x):
	return {"where": "board", "n": n, "x": x, "at": Vector3.ZERO}

func _run():
	await _frames(5)
	main.start_darts("501", "rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(20)
	var d = main.darts
	d.shake_off = true
	print("watchers: ", d.room.watchers(), " lamp: ", d.room.lamp != null)
	_check(d.room.lamp != null, "the board's lamp found")
	var tgt: Vector3 = d.to_world * Vector3(0.0, 0.103, 0.0)
	for k in 3:
		var a := Posts.aim(main.view.eye_pos, tgt)
		d.aim_yaw = a.x
		d.aim_pitch = a.y
		await _frames(2)
		d.draw = 0.5
		d._throw()
		while d.flying:
			await _frames(2)
		var r: Dictionary = d.sim.result(d.bodies[k])
		print("dart %d: %s %s x%s" % [k, r.where, r.get("n", 0), r.get("x", 0)])
		if k == 1:
			print("hush going to ", d.room.hush_to, " on_180 ", d.room.on_180)
			await _frames(40)
			await _grab("01_two_in_the_treble")
	await _frames(20)
	await _grab("02_after_three")
	await create_timer(4.0).timeout
	print("chalk:\n", d.chalk.text)
	_check(d.chalk.text == d._chalk_want, "the chalk written out")
	# two in the treble, told straight: the room hushes, then lets go on a miss
	d.room.landed(1, _r(20, 3), ["sisal"], [_r(20, 3), _r(20, 3)])
	_check(d.room.hush_to == 1.0 and d.room.on_180, "two in the treble hushes the room")
	await create_timer(2.5).timeout
	_check(main.audio.weigh > 0.3, "the room quiet under the hush (weigh %.2f)" % main.audio.weigh)
	d.room.turn_over([_r(20, 3), _r(20, 3), _r(5, 1)])
	_check(d.room.said.has("missed180"), "the missed 180 line")
	# each call once, told straight to the room
	var turns := {"180": [_r(20, 3), _r(20, 3), _r(20, 3)], "ton": [_r(20, 3), _r(20, 1), _r(20, 1)],
		"bnb": [_r(20, 1), _r(5, 1), _r(1, 1)], "bed": [_r(19, 1), _r(19, 1), _r(19, 1)]}
	for name in turns:
		d.room.turn_over(turns[name])
		await _frames(60)
		if name == "180":
			await _grab("03_one_eighty")
	d.room.turn_over([_r(20, 1)], true)
	await _frames(40)
	d.room.turn_over([_r(16, 2)], false, true, 0)
	await _frames(60)
	d.room.landed(0, {"where": "board", "n": 25, "x": 2, "at": Vector3.ZERO}, ["sisal"], [_r(25, 2)])
	await _frames(50)
	_check(d.room.hush_to == 0.0, "the hush let go after the turn")
	_check(main.audio.weigh < 0.2, "the room back up after the hush")
	print("narration said: ", d.room.said)
	for k in ["180", "ton", "bnb", "bed", "shot", "bull"]:
		_check(d.room.said.has(k), "the %s line said" % k)
	d.end()
	await _frames(5)
	print("darts_fanfare: ", "ok" if fails == 0 else "%d failed" % fails)
	quit()
