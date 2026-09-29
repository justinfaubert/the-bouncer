extends SceneTree
# Screenshots of the game as it runs: the title over the door, then a night started and the posts
# walked to, one picture each. Needs a display (xvfb-run) and the Compatibility renderer:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#     --path godot -s res://tests/shots.gd -- --out /tmp/shots [--posts door,floor] [--choices 3]

var main
var out := "/tmp/shots"
var posts := ["door", "floor", "bar", "t28", "pool", "hall", "kitchen", "keg", "deck", "lot", "upstairs"]
var choices := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--posts": posts = Array(args[i + 1].split(",")); i += 1
			"--choices": choices = int(args[i + 1]); i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	var scene: PackedScene = load("res://main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _run() -> void:
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.menus.title()
	await _frames(40)
	await _grab("00_title")
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(30)
	await _grab("01_start")
	for c in choices:
		if main.pending != null:
			main._go_on()
			await _frames(10)
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			break
		main.choose(0)
		await _frames(40)
		await _grab("02_choice_%d" % c)
	for p in posts:
		# a place seen another way: lot:pickup
		main.view.frame = p.get_slice(":", 1) if ":" in p else ""
		main.view.jump_to(p.get_slice(":", 0))
		if p == "lot:pickup":
			(main.pub.dyn.truck as Node3D).visible = true
		main.stage._settle(0.0)
		await _frames(25)
		await _grab("10_" + p.replace(":", "_"))
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
