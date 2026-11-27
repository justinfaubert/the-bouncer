extends SceneTree
# Pictures of the days' events happening on screen (world/happenings.gd): Lorraine at twelve's door
# and the cigarette lit, Lorraine on the hotel stairs, seven's door, the Preacher, the line's faces,
# the bookkeeper. Needs a display:
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 \
#     --path godot -s res://tests/shots_happen.gd -- --out /tmp/happen [--only lorraine,seven]

var main
var out := "/tmp/happen"
var only := []
var shots := 0
# name, knot, day, clock, vars, [choice to take, seconds after it to grab at...]
const SCENES := [
	["lorraine", "twelve_day", 2, 900, {}, [0, [1.2, 2.2, 3.0, 3.5, 4.0, 6.0]]],
	["lorraine_maybe", "twelve_day", 2, 900, {}, [1, [1.0, 3.0]]],
	["cheque", "cheque", 3, 960, {}, []],
	["preacher", "preacher", 3, 1130, {}, [0, [1.0]]],
	["girl", "the_line.girl", 3, 1300, {"in_line": 6}, []],
	["suit", "the_line.suit", 3, 1300, {"in_line": 6}, []],
	["legion", "the_line.legion", 3, 1300, {"in_line": 6}, []],
	["couple", "the_line.couple", 3, 1300, {"in_line": 6}, []],
	["lorraine_stair", "close_friday.lorraine_friday", 3, 1560, {"lorraine_how": 2}, [1, [0.8, 2.0, 3.5]]],
	["seven", "close_friday.seven", 3, 1565, {}, [0, [0.8, 2.5, 5.0]]],
	["wharf", "wharf_day", 2, 780, {"wharf_how": 1}, []],
	["haul", "haul", 2, 1000, {"trap_in": 800}, []],
	["esso_day", "esso_day", 2, 900, {}, []],
	["t28_day", "t28_day", 2, 900, {}, []],
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--out":
			out = args[i + 1]; i += 1
		elif args[i] == "--only":
			only = args[i + 1].split(","); i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _wait(secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	shots += 1
	var file := "%02d_%s" % [shots, name]
	root.get_viewport().get_texture().get_image().save_png(out.path_join(file + ".png"))
	print("shot ", file)


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(10)
	for sc in SCENES:
		if not only.is_empty() and not sc[0] in only:
			continue
		main.reset_story()
		main.happenings._last = {}
		main.game.set_var("day", sc[2])
		for k in sc[4]:
			main.game.set_var(k, sc[4][k])
		var res: Dictionary = main.game.jump(sc[1])
		main.game.set_var("clock", sc[3])
		var here: String = main.game.here()
		main.view.frame = main._frame_for(here)
		main.view.jump_to(here)
		main.stage.sync(main.game, true)
		main.show(res, true)
		await _frames(30)
		var guard := 0
		while main.pending != null and guard < 40:
			main._go_on()
			await _frames(3)
			guard += 1
		await _wait(2.0)
		await _grab(sc[0])
		print(sc[0], ": here ", main.game.here(), " frame ", main.view.frame, " people ", main.stage.figures.keys())
		if sc[5].size() > 0:
			var w0 := Time.get_ticks_msec()
			while main.view.walking and Time.get_ticks_msec() - w0 < 30000:
				await process_frame
			main.happenings.after(main.game)
			main.choose(sc[5][0])
			var t0 := Time.get_ticks_msec()
			for at in sc[5][1]:
				while Time.get_ticks_msec() - t0 < at * 1000.0:
					await process_frame
				await _grab("%s_%.1f" % [sc[0], at])
				print("  ", at, " place ", main.view.place, " frame ", main.view.frame, " floor ", main.view.on_floor, " eye ", main.view.eye_pos, " walking ", main.view.walking)
	quit()
