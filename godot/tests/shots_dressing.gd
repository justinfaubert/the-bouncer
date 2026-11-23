extends "res://tests/shots.gd"
# The set dressing (world/dressing.gd, world/glasswasher.gd), each piece from where he'd see it: the
# posters, the calendar, the tin sign, the corkboard, the house's signs, the beer clock, the neon in
# the window, the glasses and the glasswasher running, the hole in the hall, the signs by the door
# and the trash on the gravel, the Esso's window. One picture each. Needs a display:
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --resolution 1280x720 --path godot \
#     -s res://tests/shots_dressing.gd -- --out /tmp/dress [--only washer,mildcat]

# name, where he is (place or place:frame), what he's looking at, the clock
# name, where he is (place or place:frame), what he's looking at, the clock, and (for a close look)
# where his eyes are instead of the post's
const VIEWS := [
	["room_front", "bar", Vector3(9.0, 1.6, 10.0), 1290],
	["mildcat", "floor", Vector3(4.97, 1.7, 10.0), 1290, Vector3(5.6, 1.6, 8.6)],
	["boors", "floor", Vector3(16.0, 1.43, 9.3), 1290, Vector3(14.6, 1.6, 8.6)],
	["calendar", "t28", Vector3(14.3, 1.5, 10.0), 1290, Vector3(13.9, 1.6, 8.7)],
	["lochness", "pool:juke", Vector3(14.95, 1.78, 0.0), 1290, Vector3(14.4, 1.6, 1.5)],
	["corkboard", "floor", Vector3(4.82, 1.5, 0.0), 1290, Vector3(4.9, 1.6, 1.4)],
	["back_bar", "bar", Vector3(0.3, 1.3, 6.9), 1290, Vector3(2.6, 1.65, 5.4)],
	["washer", "bar", Vector3(0.35, 1.15, 7.1), 1290, Vector3(1.25, 1.55, 6.3)],
	["clock", "door", Vector3(0.0, 2.32, 8.55), 1290],
	["neon_in", "t28", Vector3(11.4, 1.98, 9.95), 1290],
	["hole", "hall", Vector3(9.3, 1.38, -0.2), 1290, Vector3(9.0, 1.6, -0.9)],
	["neon_out", "lot", Vector3(11.2, 1.95, 10.0), 1290, Vector3(9.6, 1.7, 14.2)],
	["door_signs", "lot", Vector3(3.0, 1.4, 10.25), 1290, Vector3(3.2, 1.65, 12.4)],
	["lot_trash", "lot", Vector3(4.0, 0.0, 12.2), 1290],
	["esso", "esso", Vector3(-153.5, 1.4, 11.9), 1000],
	["esso_ground", "esso", Vector3(-150.0, 0.0, 21.0), 1000],
]

var only: Array = []


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		if args[k] == "--only":
			only = Array(args[k + 1].split(",", false))
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.settings["dice"] = "still"
	for v in VIEWS:
		if not only.is_empty() and not v[0] in only:
			continue
		main.start_new(2)
		await _frames(15)
		main.game.set_var("clock", v[3])
		var at: String = v[1]
		main.view.frame = at.get_slice(":", 1) if ":" in at else ""
		main.view.jump_to(at.get_slice(":", 0))
		if v.size() > 4:
			main.view.eye_pos = v[4]
		main.stage.sync(main.game, true)
		main.stage._settle(0.0)
		main.view.daylight(v[3], true)
		main.pub.set_clock(v[3])
		var a := Posts.aim(main.view.eye_pos, v[2])
		main.view.yaw = a.x
		main.view.want_yaw = a.x
		main.view.pitch = clampf(a.y, View.PITCH_MIN, View.PITCH_MAX)
		main.view.want_pitch = main.view.pitch
		await _frames(25)
		await _grab(v[0])
		# and the eye's own picture, before the press: to see what's in what
		var img: Image = main.view.eye.get_texture().get_image()
		img.save_png(out.path_join(v[0] + "_eye.png"))
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
