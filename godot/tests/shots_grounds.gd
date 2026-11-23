extends "res://tests/shots.gd"
# The grounds round the Sov at night (world/grounds.gd), from where a man walking about out there
# would stand: one picture each, the picture the whole screen as it is while he walks. For the
# light, the dark, and holes and things standing in each other. Needs a display:
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 \
#     --path godot -s res://tests/shots_grounds.gd -- --out /tmp/grounds [--clock 1290] [--only a,b]

var clock := 1205
var only: Array = []

# name: [his eyes on the ground (x, z), what he's looking at]
const VIEWS := {
	"lot_back_at_sov": [Vector2(9.0, 24.0), Vector3(8.0, 4.0, 10.1)],
	"lot_to_esso": [Vector2(4.0, 22.0), Vector3(-150.0, 2.0, 22.0)],
	"rat_run": [Vector2(9.6, 11.6), Vector3(9.4, 0.1, 10.25)],
	"pole": [Vector2(14.2, 20.4), Vector3(15.8, 1.6, 21.5)],
	"east_side": [Vector2(21.5, 12.0), Vector3(20.0, 1.0, -2.0)],
	"hotel_door": [Vector2(19.4, 2.4), Vector3(18.9, 1.4, 0.9)],
	"behind": [Vector2(24.0, -6.0), Vector3(4.0, 1.5, -4.0)],
	"alley": [Vector2(-3.0, 6.5), Vector3(-1.0, 1.2, -3.0)],
	"kitchen_door": [Vector2(-2.6, -1.5), Vector3(-0.1, 1.2, -1.5)],
	"up_the_hill": [Vector2(6.0, -6.0), Vector3(6.0, 6.0, -30.0)],
	"crossing": [Vector2(10.0, 28.5), Vector3(-30.0, 1.0, 30.0)],
	"cross": [Vector2(-36.0, 26.0), Vector3(-38.0, 0.6, 27.6)],
	"seawall_merle": [Vector2(8.0, 34.6), Vector3(2.0, 1.2, 36.5)],
	"seawall_back": [Vector2(4.0, 34.8), Vector3(8.0, 5.0, 10.0)],
	"steps_down": [Vector2(14.0, 34.0), Vector3(14.0, -0.5, 40.0)],
	"beach": [Vector2(16.0, 39.0), Vector3(4.0, -0.3, 41.0)],
	"beach_back": [Vector2(6.0, 43.0), Vector3(8.0, 4.0, 10.0)],
	"fire": [Vector2(22.0, 39.0), Vector3(24.5, -0.2, 40.5)],
	"kelp": [Vector2(-2.0, 42.0), Vector3(-4.5, -0.35, 44.0)],
	"shoulder": [Vector2(-80.0, 26.4), Vector3(-150.0, 2.0, 22.0)],
	"esso_near": [Vector2(-138.0, 25.0), Vector3(-150.0, 1.5, 12.0)],
	"esso_window": [Vector2(-152.0, 14.2), Vector3(-153.75, 1.5, 12.0)],
}


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		match args[k]:
			"--clock": clock = int(args[k + 1])
			"--only": only = Array(args[k + 1].split(","))
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(20)
	main.game.set_var("clock", clock)
	main.show(main.game.jump("at_front"), false)
	await _frames(5)
	main.view.frame = ""
	main.view.jump_to("lot")
	main.stage.sync(main.game, true)
	main.stage._settle(0.0)
	main.view.daylight(clock, true)
	main.pub.set_clock(clock)
	await _frames(10)
	var v: View = main.view
	for name in VIEWS:
		if not only.is_empty() and not name in only:
			continue
		var g: Vector2 = VIEWS[name][0]
		var gy := Grounds.ground_y(g.x, g.y)
		v.eye_pos = Vector3(g.x, gy + Posts.STAND, g.y)
		v.floor_spot = Vector3(g.x, gy, g.y)
		var a := Posts.aim(v.eye_pos, VIEWS[name][1])
		v.yaw = a.x
		v.want_yaw = a.x
		v.pitch = a.y
		v.want_pitch = a.y
		for k in 30:
			main.set("_still_t", 0.0)
			await process_frame
		await _grab(name)
		print("  ", name, " clearance ", snappedf(Grounds.clearance(v.eye_pos), 0.01), " zone ", Hotspots.zone_of(v.eye_pos), " area ", Grounds.area_of(v.eye_pos))
	quit()
