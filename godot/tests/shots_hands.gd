extends SceneTree
# Pictures of the things in his hands: plays a night with a seeded random player until he's handed
# something, then takes a picture as it comes up, another with E (held up by the face, or looked at
# closer), and goes on to the next thing, up to --count of them. Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_hands.gd -- --out /tmp/hands --seed 5 --count 3

var main
var out := "/tmp/hands"
var rs := 5
var count := 3


func rnd() -> int:
	rs = (rs * 48271) % 2147483647
	return rs


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--seed": rs = int(args[i + 1]); i += 1
			"--count": count = int(args[i + 1]); i += 1
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
	main.start_new(2)
	await _frames(10)
	var seen := {}
	var guard := 0
	while seen.size() < count and guard < 3000 and not main.game.ended:
		guard += 1
		await _frames(1)
		if main.props.holding():
			var id := str(main.props.held.get("id", "thing"))
			if not seen.has(id):
				seen[id] = true
				await _frames(40)
				await _grab("%02d_%s" % [seen.size(), id])
				main.props.key(KEY_E)
				await _frames(40)
				await _grab("%02d_%s_e" % [seen.size(), id])
			main.props.put_down()
			await _frames(5)
			continue
		if main.rolling != null:
			if main.rolling.has_method("finish"):
				main.rolling.finish()
			await _frames(2)
			continue
		if main.pending != null:
			main._go_on()
			await _frames(1)
			continue
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			await _frames(5)
			continue
		main.choose(rnd() % list.size())
		await _frames(3)
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
