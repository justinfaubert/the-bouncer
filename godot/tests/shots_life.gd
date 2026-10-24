extends "res://tests/shots.gd"
# The people with bones (world/life.gd) over a few seconds, at a post: a picture every half second
# of the room's own time, with the room's clock stepped by hand (a thirtieth of a second at a
# time, so a slow machine sees what a quick one does). Partway, someone says a line.
#   ... -s res://tests/shots_life.gd -- --out DIR [--post bar] [--who bartender] [--zoom 0.6] [--steps 20]
#   [--say "Door. You don't run on my floor."] [--at 4] [--sip] (everyone with a drink sips straight away)
#   [--box x,y,w,h] (pictures cut to that part of the screen) [--clock 1290] (the room's light at that
#   time, minutes from midnight: half past nine)

var post := "bar"
var who := "bartender"
var zoom := 1.0
var steps := 20
var say := "Door. You don't run on my floor. Half the room just looked round for the fight."
var say_at := 4
var sip := false
var box := Rect2i()
var clock := -1


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		match args[k]:
			"--post": post = args[k + 1]
			"--who": who = args[k + 1]
			"--zoom": zoom = float(args[k + 1])
			"--steps": steps = int(args[k + 1])
			"--say": say = args[k + 1]
			"--at": say_at = int(args[k + 1])
			"--sip": sip = true
			"--clock": clock = int(args[k + 1])
			"--box":
				var b := args[k + 1].split(",")
				box = Rect2i(int(b[0]), int(b[1]), int(b[2]), int(b[3]))
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(20)
	main.view.frame = post.get_slice(":", 1) if ":" in post else ""
	main.view.jump_to(post.get_slice(":", 0))
	# who's where for that place and frame (the man across Gary's desk is in the doorway at first)
	main.stage.sync(main.game, true)
	main.stage._settle(0.0)
	if clock >= 0:
		main.view.daylight(clock, true)
		main.pub.set_clock(clock)
	main.view.want_zoom = zoom
	main.view.zoom = zoom
	await _frames(20)
	var stage: Stage = main.stage
	stage.set_process(false)
	print("with bones: ", stage.life.people.keys())
	if sip:
		for id in stage.life.people:
			var sp: Dictionary = stage.life.people[id].sip
			if not sp.is_empty():
				print("sips: ", id, " ", sp.side)
				sp.next = 0.0
	for s in steps:
		if s == say_at and say != "":
			stage.speaking(who, say)
		for k in 15:
			var heads := {}
			for id in stage.figures:
				heads[id] = stage.head_of(id)
			stage.life.update(1.0 / 30.0, main.view.cam.global_position, -main.view.cam.global_transform.basis.z, heads)
		await _frames(2)
		if box.size.x > 0:
			await RenderingServer.frame_post_draw
			var img := root.get_viewport().get_texture().get_image().get_region(box)
			img.save_png(out.path_join("life_%s_%02d.png" % [post.replace(":", "_"), s]))
		else:
			await _grab("life_%s_%02d" % [post.replace(":", "_"), s])
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
