extends SceneTree
# Pictures of the door by hand (game/door_hand.gd): the kid at ten to eight, his hand at rest, then
# dragged each way the verdicts go, and the room answering before the column does. Needs a display:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#     --path godot -s res://tests/shots_door.gd -- --out /tmp/door [--start door_hoodie] [--commit in]

var main
var out := "/tmp/door"
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
	await _grab("at_rest")
	var dh = main.get("door_hand")
	# DOOR_TRY="rest|x,y,z|rx,ry,rz;..." tries other poses for one verdict, a picture each
	var tries := OS.get_environment("DOOR_TRY")
	if dh != null and tries != "":
		var k := 0
		for t in tries.split(";"):
			var f := t.split("|")
			var p := f[1].split(","); var r := f[2].split(",")
			dh.poses[f[0]] = [Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(r[0]), float(r[1]), float(r[2]))]
			dh.preview(f[0] if f[0] != "rest" else "", 1.0)
			await _frames(25)
			k += 1
			await _grab("try_%d_%s" % [k, t.replace("|", "_").replace(",", " ")])
		quit()
		return
	if dh != null:
		# a hand on a verdict's row: the column scrolled to the choices, the hand starting it
		main.column.scroll_to_end()
		for g in ["out"]:
			if dh.offers(g):
				var r = main.column.row_for_index(dh.offered[g])
				if r != null:
					r.set_lit(true)
				dh.row_on(dh.offered[g], true)
				await _frames(40)
				await _grab("row_" + g)
				dh.row_on(dh.offered[g], false)
				if r != null:
					r.set_lit(false)
		for g in ["in", "out", "fetch", "terms"]:
			if dh.offers(g):
				dh.preview(g, 1.0)
				await _frames(20)
				await _grab("drag_" + g)
		dh.preview("", 0.0)
		await _frames(10)
		if commit != "" and dh.offers(commit):
			dh.commit(commit)
			for k in 6:
				await _frames(10)
				await _grab("answer_%s_%d" % [commit, k])
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
