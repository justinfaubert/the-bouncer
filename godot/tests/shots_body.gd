extends SceneTree
# His notes' third page, HIS BODY (game/notes.gd, engine/practice.gd): empty at the start of a
# night, then after some practice (a few marks, two knacks, a hand stopped). Needs a display:
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 \
#     --path godot -s res://tests/shots_body.gd -- --out /tmp/body

var main
var out := "/tmp/body"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--out":
		out = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _run() -> void:
	await _frames(5)
	main.start_new(2)
	await _frames(20)
	main.notes.open()
	main.notes.page_no = 2
	main.notes.refresh()
	await _frames(5)
	await _grab("body_empty")
	var g: Game = main.game
	for n in 6:
		g.practice.new_night(n + 1)
		for k in 8:
			g.practise("hands", 3.0, "jab%d" % k)
			g.practise("holds", 2.0, "turn%d" % k)
			g.practise("read", 2.5, "shoulder%d" % k)
			g.practise("arm", 1.5, "dart%d" % k)
	g.practise("chin", 4.0, "took one")
	g.practice.stop("arm", "a broken hand, till it knits")
	main.notes.refresh()
	await _frames(5)
	await _grab("body_practised")
	quit()
