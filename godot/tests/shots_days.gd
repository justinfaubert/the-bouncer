extends SceneTree
# Pictures of the days after Wednesday (content/ink/days.ink, friday.ink): Thursday by daylight, and
# Friday's line in the rain. Needs a display:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#     --path godot -s res://tests/shots_days.gd -- --out /tmp/days

var main
var out := "/tmp/days"
var shots := 0
# knot, day, clock, extra vars
const SCENES := [
	["thursday", 2, 705, {}],
	["strip", 2, 760, {}],
	["wharf_day", 2, 780, {"wharf_how": 1}],
	["t28_day", 2, 900, {}],
	["esso_day", 2, 975, {}],
	["the_sign", 2, 1008, {}],
	["jim", 3, 1010, {}],
	["the_line", 3, 1300, {"in_line": 8}],
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--out":
			out = args[i + 1]; i += 1
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
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(10)
	for sc in SCENES:
		main.reset_story()
		main.game.set_var("day", sc[1])
		for k in sc[3]:
			main.game.set_var(k, sc[3][k])
		var res: Dictionary = main.game.jump(sc[0])
		main.game.set_var("clock", sc[2])
		var here: String = main.game.here()
		main.view.frame = main._frame_for(here)
		main.view.jump_to(here)
		main.stage.sync(main.game, true)
		main.show(res, true)
		await _frames(40)
		var guard := 0
		while main.pending != null and guard < 40:
			main._go_on()
			await _frames(3)
			guard += 1
		await _frames(40)
		await _grab(sc[0])
	quit()
