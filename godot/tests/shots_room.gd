extends "res://tests/shots.gd"
# The room's things (content/ink/room.ink; world/pub.gd, _room_things), each from where he'd see it
# and as the night can have it: the empties on the rail, the padlock and the darts, the coat on its
# hook, the wallet under the stool, the wet inside the door and the yellow sign, the dimmer and the
# house lights, the big TV, the extinguisher, the butts on the deck, the stools pushed out late, the
# stool over after GOOD SHOES went out the hard way. One picture each. Needs a display:
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_room.gd -- --out /tmp/room [--only rail_late,coat]

# name, where he is (place or place:frame), what he's looking at (or null, the post's own look), the
# clock, and the night's VARs for it
const VIEWS := [
	["rail_early", "pool", Vector3(9.8, 1.15, 0.1), 1200, {}],
	["rail_late", "pool", Vector3(9.8, 1.15, 0.1), 1290, {"rack_locked": true}],
	["rack_open", "pool:juke", Vector3(11.7, 1.2, 0.05), 1290, {}],
	["rack_locked", "pool:juke", Vector3(11.7, 1.2, 0.05), 1290, {"rack_locked": true}],
	["coat", "pool:juke", Vector3(15.9, 1.3, 1.15), 1290, {}],
	["board_pulled", "pool:juke", Vector3(15.9, 1.73, 2.3), 1290, {"darts_pulled": true}],
	["darts_till", "bar", Vector3(1.74, 1.2, 7.62), 1290, {"darts_pulled": true}],
	["wallet", "bar", Vector3(3.2, 0.03, 3.5), 1360, {"wallet_dropped": 1340}],
	["scuffle", "bar", Vector3(2.9, 0.3, 3.3), 1340, {"bar_scuffle": true}],
	["door_dry", "door", Vector3(3.6, 0.3, 9.5), 1190, {}],
	["door_wet2", "door", Vector3(3.6, 0.3, 9.5), 1300, {"count_in": 2}],
	["door_wet3_sign", "door", Vector3(3.6, 0.3, 9.5), 1460, {"count_in": 4, "wet_sign": true}],
	["dimmer", "door", Vector3(1.86, 1.34, 9.98), 1290, {}],
	["tv_hockey", "floor", Vector3(9.4, 2.3, 0.0), 1300, {}],
	["tv_light", "floor", Vector3(9.4, 2.3, 0.0), 1420, {"tv_on": 1}],
	["tv_replay", "floor", Vector3(9.4, 2.3, 0.0), 1420, {"tv_on": 2}],
	["tv_off", "floor", Vector3(9.4, 2.3, 0.0), 1420, {"tv_on": 3}],
	["tv_curling", "floor", Vector3(9.4, 2.3, 0.0), 1420, {"tv_on": 4}],
	["last_call", "floor", null, 1535, {}],
	["lights_up", "floor", null, 1535, {"lights": 1}],
	["lights_low", "floor", null, 1535, {"lights": -1}],
	["extinguisher", "hall", Vector3(14.4, 1.0, -0.3), 1290, {}],
	["butts", "deck", Vector3(18.1, 0.1, 9.6), 1500, {}],
	["stools_late", "floor", Vector3(5.0, 0.4, 7.0), 1500, {}],
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
		for name in v[4]:
			main.game.set_var(name, v[4][name])
		var at: String = v[1]
		main.view.frame = at.get_slice(":", 1) if ":" in at else ""
		main.view.jump_to(at.get_slice(":", 0))
		main.stage.sync(main.game, true)
		main.stage._settle(0.0)
		main.view.daylight(v[3], true)
		main.pub.set_clock(v[3])
		if v[2] != null:
			var a := Posts.aim(main.view.eye_pos, v[2])
			main.view.yaw = a.x
			main.view.want_yaw = a.x
			main.view.pitch = clampf(a.y, View.PITCH_MIN, View.PITCH_MAX)
			main.view.want_pitch = main.view.pitch
		await _frames(25)
		await _grab(v[0])
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
