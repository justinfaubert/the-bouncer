extends SceneTree
# Pictures of the things he handles (content/data/props.yaml, kind: thing, and the boy's licence):
# the darkroom's pictures of them as files, and each one in his hand at the bar, as it comes up,
# brought closer (E), and turned over. Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_things.gd -- --out /tmp/things [--only beer_mat,straw] [--at bar]

var main
var out := "/tmp/things"
var only: Array = []
var at := "bar"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--only": only = Array(args[i + 1].split(",", false)); i += 1
			"--at": at = args[i + 1]; i += 1
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
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "still"
	main.settings["notice"] = true
	main.start_new(2)
	await _frames(10)
	# the darkroom's done when its queue is
	var guard := 0
	while (main.props.developing or not main.props.jobs.is_empty()) and guard < 2000:
		guard += 1
		await _frames(1)
	for k in main.props.tex:
		var name := str(k)
		if name.begins_with("thing_") or name == "face_ballcap" or name.begins_with("card_minor_card") or name == "sleeve_8":
			var img: Image = (main.props.tex[k] as Texture2D).get_image()
			img.save_png(out.path_join("tex_" + name + ".png"))
	main.view.walk_to(at, true)
	main.stage.sync(main.game, true)
	await _frames(30)
	var ids: Array = []
	for id in main.props.P:
		var pr = main.props.P[id]
		if pr is Dictionary and (str(pr.get("kind", "")) == "thing" or str(id) == "minor_card"):
			if only.is_empty() or str(id) in only:
				ids.append(str(id))
	for id in ids:
		main.props.offer({"prop": id}, true, true)
		await _frames(45)
		await _grab(id + "_1rest")
		main.props.key(KEY_E)
		await _frames(45)
		await _grab(id + "_2closer")
		main.props._flip(false)
		await _frames(45)
		await _grab(id + "_3turned")
		main.props.drop_all()
		await _frames(5)
	print("done ", ids.size())
	quit()
