extends SceneTree
# Pictures of the opening, from a new night: the first choice each time (or one matching --prefer),
# a picture after the choices listed in --at, the notes (Tab) and the sketch (M) after --pad.
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_opening.gd -- --out /tmp/m1 --at 0,2,12,16 --pad 16 --steps 24

var main
var out := "/tmp/m1"
var at := {}
var pad := -1
var steps := 24
var prefer: Array = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--at":
				for s in args[i + 1].split(","):
					at[int(s)] = true
				i += 1
			"--pad": pad = int(args[i + 1]); i += 1
			"--steps": steps = int(args[i + 1]); i += 1
			"--prefer":
				prefer = Array(args[i + 1].split("|"))
				i += 1
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


func _settle() -> void:
	var guard := 0
	while guard < 600:
		guard += 1
		await _frames(1)
		if main.rolling != null:
			if main.rolling.has_method("finish"):
				main.rolling.finish()
			await _frames(2)
			continue
		if main.pending != null:
			main._go_on()
			await _frames(2)
			continue
		if main.view.walking:
			continue
		if not main.game.visible_choices().is_empty():
			break
	await _frames(40)


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "still"
	main.start_new(4)
	await _frames(10)
	for n in steps + 1:
		await _settle()
		if at.has(n):
			await _grab("step%02d" % n)
		if n == pad:
			main._pad_key(KEY_TAB)
			await _frames(30)
			await _grab("notes%02d" % n)
			main._pad_key(KEY_TAB)
			await _frames(10)
			main._pad_key(KEY_M)
			await _frames(30)
			await _grab("sketch%02d" % n)
			main._pad_key(KEY_M)
			await _frames(10)
		if n == steps:
			break
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			print("no choices at ", n)
			break
		var pick := 0
		for re_s in prefer:
			var re := RegEx.create_from_string(str(re_s))
			var found := -1
			for j in list.size():
				if re.search(str(list[j].text)) != null:
					found = j
					break
			if found >= 0:
				pick = found
				break
		var st: Dictionary = main.game.status()
		print("%2d %s %s > %s" % [n, st.clockText, st.here, str(list[pick].text).substr(0, 80)])
		main.choose(pick)
	main.store.clear(4)
	quit(0)
