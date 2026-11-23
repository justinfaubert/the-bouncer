extends SceneTree
# Pictures of darts (game/darts.gd), from the Rehearse menu with no night: at the line aiming, a
# dart drawn back, three thrown (each picture after it lands), the board close, and the chalk.
# Needs a display:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#     --path godot -s res://tests/shots_darts.gd -- --out /tmp/darts [--mode 501] [--drinks 0]

var main
var out := "/tmp/darts"
var mode := "501"
var drinks := 0
var shots := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--mode": mode = args[i + 1]; i += 1
			"--drinks": drinks = int(args[i + 1]); i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	shots += 1
	var file := "%02d_%s" % [shots, name]
	root.get_viewport().get_texture().get_image().save_png(out.path_join(file + ".png"))
	print("shot ", file)


func _run() -> void:
	await _frames(5)
	main.menus.rehearse("title")
	await _frames(10)
	await _grab("rehearse_menu")
	main.start_darts(mode, "rehearse", {"drinks": drinks, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(60)
	await _grab("at_the_line")
	var d = main.darts
	# aim at the treble 20, a little above the bull
	var tgt: Vector3 = d.to_world * Vector3(0.0, 0.103, 0.0)
	var a := Posts.aim(main.view.eye_pos, tgt)
	d.aim_yaw = a.x
	d.aim_pitch = a.y
	d.drawing = true
	d.draw = 0.5
	await _frames(20)
	await _grab("drawn_back")
	d.drawing = false
	for k in 3:
		d.draw = 0.5 + (k - 1) * 0.04
		d._throw()
		await _frames(6)
		await _grab("dart_%d_in_flight" % k)
		while d.flying:
			await _frames(2)
		await _frames(10)
		var r: Dictionary = d.sim.result(d.bodies[k])
		print("dart %d: %s %s x%s, heard %s" % [k, r.where, r.get("n", 0), r.get("x", 0), str(d.sim.hits.filter(func(h): return int(h[1]) == k).map(func(h): return h[2]))])
		await _grab("dart_%d_landed" % k)
	d.fov_hold = 14.0
	d.aim_pitch = a.y - 0.03
	await _frames(30)
	await _grab("board_close")
	var ca: Vector2 = Posts.aim(main.view.eye_pos, d.chalk.global_position)
	d.aim_yaw = ca.x
	d.aim_pitch = ca.y
	d.fov_hold = 22.0
	await _frames(30)
	await _grab("chalk")
	d.fov_hold = 0.0
	quit()
