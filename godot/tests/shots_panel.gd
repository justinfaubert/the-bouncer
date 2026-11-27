extends SceneTree
# Pictures of the page: at the door with the voices' masks, folded to its spine while he walks with a
# voice speaking, and back. Needs a display:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#     --path godot -s res://tests/shots_panel.gd -- --out /tmp/panel [--start door_hoodie] [--commit in]

var main
var out := "/tmp/panel"
var start := "door_hoodie"
var commit := ""
var shots := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--start": start = args[i + 1]; i += 1
			"--commit": commit = args[i + 1]; i += 1
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
	main.reset_story()
	var res: Dictionary = main.game.jump(start)
	main.game.set_var("clock", 1190)
	main.view.frame = main._frame_for(main.game.here())
	main.view.jump_to("door")
	main.stage.sync(main.game, true)
	main.show(res, true)
	await _frames(40)
	while main.pending != null:
		main._go_on()
		await _frames(3)
	await _frames(30)
	await _grab("page")
	# walking: the page folds to its spine; a voice has a word while it's folded
	for k in 80:
		main._still_t = 0.0
		await process_frame
	var said := false
	for what in ["wait", "back", "reread"]:
		if main.hand.murmur(what, "float"):
			said = true
			break
	for k in 30:
		main._still_t = 0.0
		await process_frame
	await _grab("spine" + ("_said" if said else ""))
	pass
	await _frames(90)
	await _grab("page_back")
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
