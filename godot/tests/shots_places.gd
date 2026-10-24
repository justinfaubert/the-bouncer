extends "res://tests/shots.gd"
# Every place at an hour of the night, one picture each, with the room as the night has it then: for
# the colour and the light (each place's own, and how the night's changes them). Needs a display:
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_places.gd -- --out /tmp/places [--clock 1290]
#     [--posts door,floor,bar] [--var name=value] [--raw] [--frames 25]
# (--clock in minutes since midnight: 1200 is eight, 1440 midnight, 1530 last call; --raw also keeps
# what his eyes see before the press prints it, and the mask, for tuning the press offline with
# sketches/door-look/tools/press.py)

var clock := 1290
var sets: Array = []
var raw := false
var frames := 25


func _run() -> void:
	posts = ["door", "floor", "bar", "t28", "pool", "hall", "kitchen", "keg", "deck", "lot", "upstairs",
		"office", "street", "esso", "seawall"]
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		match args[k]:
			"--clock": clock = int(args[k + 1])
			"--posts": posts = Array(args[k + 1].split(","))
			"--var": sets.append(args[k + 1])
			"--raw": raw = true
			"--frames": frames = int(args[k + 1])
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(20)
	main.game.set_var("clock", clock)
	for sv in sets:
		var kv: PackedStringArray = sv.split("=")
		main.game.set_var(kv[0], int(kv[1]) if kv[1].is_valid_int() else kv[1])
	for p in posts:
		main.view.frame = ""
		main.view.jump_to(p)
		main.stage.sync(main.game, true)
		main.stage._settle(0.0)
		main.view.daylight(clock, true)
		main.pub.set_clock(clock)
		await _frames(frames)
		await _grab("%s_%d" % [p, clock])
		if raw:
			main.view.eye.get_texture().get_image().save_png(out.path_join("%s_%d_raw.png" % [p, clock]))
			main.view.mask.get_texture().get_image().save_png(out.path_join("%s_%d_mask.png" % [p, clock]))
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
