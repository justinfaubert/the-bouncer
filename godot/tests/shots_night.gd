extends SceneTree
# Pictures from a night played by a seeded random player: whoever comes to the door, the first
# time each of them is there; the things he's handed, in his hands and held up (E); the clicker in
# his hand at the door; and the room from the floor as it fills. Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_night.gd -- --out /tmp/night --seed 5 --max 12

var main
var out := "/tmp/night"
var rs := 5
var most := 12
var shots := 0


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
			"--max": most = int(args[i + 1]); i += 1
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
	var st: Dictionary = main.game.status()
	var file := "%02d_%s_%s" % [shots, str(st.clockText).replace(":", "").replace(" ", ""), name]
	root.get_viewport().get_texture().get_image().save_png(out.path_join(file + ".png"))
	print("shot ", file)


func _at_door() -> String:
	for id in main.stage.figures:
		var f = main.stage.figures[id]
		if f != null and str(f.spot) == "door_front" and (f.node as Node3D).visible:
			return str(id)
	return ""


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(10)
	var seen := {}
	var guard := 0
	while shots < most and guard < 4000 and not main.game.ended:
		guard += 1
		await _frames(1)
		if main.view.walking:
			continue
		var who := _at_door()
		if who != "" and main.view.place == "door" and not seen.has("door_" + who):
			seen["door_" + who] = true
			main.stage._settle(0.0)
			await _frames(45)
			await _grab("door_" + who)
		if main.props.holding():
			var id := str(main.props.held.get("id", "thing"))
			if not seen.has("hand_" + id):
				seen["hand_" + id] = true
				await _frames(40)
				await _grab("hand_" + id)
				main.props.key(KEY_E)
				await _frames(40)
				await _grab("hand_" + id + "_e")
			main.props.put_down()
			await _frames(5)
			continue
		if main.props.left != null and main.props.left.visible and not seen.has("clicker"):
			seen["clicker"] = true
			await _frames(30)
			await _grab("clicker")
		var clock := int(main.game.status().clock)
		for mark in [1320, 1440]:
			if clock >= mark and not seen.has("floor_%d" % mark):
				seen["floor_%d" % mark] = true
				var was: String = main.view.place
				main.view.jump_to("floor")
				main.stage._settle(0.0)
				await _frames(40)
				await _grab("floor")
				main.view.jump_to(was)
				await _frames(10)
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
