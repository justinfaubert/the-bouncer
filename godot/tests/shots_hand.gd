extends SceneTree
# Pictures of his hand's second choice, in a night played by a seeded random player: the voices'
# reads of a thing he's holding, over what he does with it; the read he keeps, in the column; and
# his notes' second page, ON HIM, as it stands then and with that thing looked at. Needs a display
# (xvfb-run):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_hand.gd -- --out /tmp/hand --seed 5 --max 3
# A night played at random is slow to reach a thing in his hand on a software renderer, so
# --start knot.stitch begins it there instead (the way a saved night goes on from the floor), and
# --prefer words makes any choice with those words in it first: --start the_drawer --prefer jacket

var main
var out := "/tmp/hand"
var rs := 5
var most := 3
var shots := 0
var start := ""
var prefer := ""


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
			"--start": start = args[i + 1]; i += 1
			"--prefer": prefer = args[i + 1]; i += 1
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


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "still"
	main.settings["notice"] = true
	main.start_new(2)
	await _frames(10)
	if start != "":
		main.reset_story()
		var res: Dictionary = main.game.jump(start)
		main.view.frame = main._frame_for(main.game.here())
		main.view.jump_to(main.game.here() if main.game.here() != "" else "door")
		main.stage.sync(main.game, true)
		main.show(res, true)
		await _frames(20)
	var kept := 0
	var guard := 0
	while kept < most and guard < 6000 and not main.game.ended:
		guard += 1
		await _frames(1)
		if main.view.walking:
			continue
		if main.props.holding() and main.game.visible_choices().is_empty():
			main.props.put_down()
			await _frames(3)
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
		var reads: Array = []
		for i in list.size():
			if list[i].get("read") != null:
				reads.append(i)
		if reads.is_empty():
			var pick := -1
			if prefer != "":
				for i in list.size():
					if str(list[i].get("text", "")).to_lower().contains(prefer.to_lower()):
						pick = i
						break
			main.choose(pick if pick >= 0 else rnd() % list.size())
			await _frames(3)
			continue
		# the reads, over what he does with it
		var thing := str(list[reads[0]].read.get("thing", "thing"))
		await _frames(30)
		await _grab("reads_" + thing)
		main.choose(reads[rnd() % reads.size()])
		await _frames(40)
		await _grab("kept_" + thing)
		# his notes, on him, and the thing looked at
		main.notes.open()
		if main.notes.page_no != 1:
			main.notes.turn_page()
		await _frames(20)
		await _grab("on_him")
		main.notes.info_thing = thing
		main.notes.refresh()
		await _frames(10)
		await _grab("on_him_" + thing)
		main.notes.close()
		await _frames(5)
		kept += 1
	print("done ", kept)
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
