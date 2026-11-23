extends SceneTree
# Stills of the cold open (game/intro.gd) at the seconds asked for, the whole screen. Run it with a
# fixed frame rate, so the reel's clock and its tweens keep the same time however slowly it renders:
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --path godot --resolution 1600x900 --fixed-fps 10 \
#     -s res://tests/shots_intro.gd -- --out /tmp/intro --at 3,12,18,24,30,36,42,47,50
# --title also takes the title after the reel ends. For a film of it, Godot's movie maker:
#   ... godot --path godot --resolution 1280x720 --fixed-fps 24 --write-movie /tmp/intro/reel.avi -- --intro

var main
var out := "/tmp/intro"
var at: Array = []
var title := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--at":
				for s in args[i + 1].split(","):
					at.append(float(s))
				i += 1
			"--title": title = true
		i += 1
	at.sort()
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _grab(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


func _run() -> void:
	await process_frame
	if not main.intro.playing:
		main.intro.play()
	var k := 0
	while k < at.size() and main.intro.playing:
		await process_frame
		if main.intro.t >= at[k]:
			await _grab(out.path_join("t%05.1f.png" % at[k]))
			k += 1
	if title:
		while main.intro.playing:
			await process_frame
		for f in 25:
			await process_frame
		await _grab(out.path_join("title.png"))
	quit()
