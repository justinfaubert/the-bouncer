extends SceneTree
# Pictures of the truck (game/truck.gd) from Rehearse > The truck: sat in it in the lot with the
# engine off, the key turned and the lights on, from behind it in the lot, and then out on the road
# at each place along it (the truck put down there in its lane, the lights on, a few seconds driven
# so it's moving): the motel, the bluff, the fish plant, the mill road, the washout; the church, the
# fruit stand, the cut, the ferry sign, the bridge that's out. Needs a display:
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver vulkan --resolution 1600x900 \
#     --path godot -s res://tests/shots_truck.gd -- --out /tmp/truck [--only motel|model] [--drinks 0]

var main
var out := "/tmp/truck"
var only := ""
var drinks := 0
var shots := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--only": only = args[i + 1]; i += 1
			"--drinks": drinks = int(args[i + 1]); i += 1
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
	main.start_truck("rehearse", {"drinks": drinks, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(20)
	var tr: Truck = main.truck
	main.keys.hide_card()
	if only == "model":
		# round the truck in the lot, lights on, close enough to see what it is
		tr._key()
		await create_timer(1.6).timeout
		tr.lights = 1
		tr._lights()
		for v in [["front_quarter", Vector3(3.6, 1.3, -5.2)], ["side", Vector3(5.6, 1.1, 0.4)],
				["rear_quarter", Vector3(-3.8, 1.8, 6.0)], ["front", Vector3(0.0, 1.0, -6.8)], ["above", Vector3(2.5, 4.5, 3.5)]]:
			tr.chase_at = v[1]
			_chase(tr, true)
			await _frames(40)
			await _grab("model_" + str(v[0]))
		quit()
		return
	if only == "":
		await _grab("cab_parked_dark")
		tr._key()
		await create_timer(1.6).timeout
		tr.lights = 1
		tr._lights()
		await _frames(10)
		await _grab("cab_lights_on")
		main.view.want_yaw = 0.9
		await _frames(30)
		await _grab("cab_look_left")
		main.view.want_yaw = 0.0
		main.view.want_pitch = -0.35
		await _frames(30)
		await _grab("cab_the_dash")
		main.view.want_pitch = -0.08
		_chase(tr, true)
		await _frames(30)
		await _grab("behind_in_the_lot")
		_chase(tr, false)
	else:
		tr.sim.running = true
		tr.sound.running = true
		tr.lights = 1
		tr._lights()
	var places := [["sov", 40.0, 1.0], ["motel", IslandRoad.MOTEL - 70.0, 1.0], ["bluff", 900.0, 1.0],
		["fish_plant", IslandRoad.FISH_PLANT - 60.0, 1.0], ["mill_road", IslandRoad.MILL_ROAD - 120.0, 1.0],
		["washout", IslandRoad.WASHOUT - 70.0, 1.0], ["church", IslandRoad.CHURCH + 90.0, -1.0],
		["fruit", IslandRoad.FRUIT + 90.0, -1.0], ["the_cut", -1250.0, -1.0],
		["ferry_sign", IslandRoad.FERRY_SIGN + 90.0, -1.0], ["bridge_out", IslandRoad.BRIDGE_OUT + 60.0, -1.0]]
	for p in places:
		if only != "" and p[0] != only:
			continue
		_put(tr, float(p[1]), float(p[2]))
		tr.sim.selector = "D"
		tr._sel = 3
		await _frames(30)
		await _grab(str(p[0]) + "_cab")
		if p[0] in ["motel", "bluff", "mill_road", "church"]:
			_chase(tr, true)
			await _frames(30)
			await _grab(str(p[0]) + "_behind")
			_chase(tr, false)
	print("speed at the end: %.0f km/h, rpm %d, gear %s" % [tr.sim.kmh(), tr.sim.rpm, tr.sim.gear])
	quit()


func _chase(tr: Truck, on: bool) -> void:
	tr.chase = on
	main.view.ride = null if on else tr.body
	tr._chase_pos = tr.sim.pos + tr.sim.rot * Vector3(tr.chase_at.x, 0.0, tr.chase_at.z) + Vector3(0, tr.chase_at.y, 0)
	main.view.want_yaw = 0.0
	main.view.want_pitch = -0.08
	main.view.yaw = 0.0
	main.view.pitch = -0.08
	tr.sound.outside = on


# down in its lane at d metres from the Sov's door, going dir (1 north, -1 south), at about 60
func _put(tr: Truck, d: float, dir: float) -> void:
	var a: Array = tr.road.at_dist(d)
	var p: Vector3 = a[0]
	var fd: Vector3 = (a[1] as Vector3) * dir
	var side := Vector3(-fd.z, 0.0, fd.x)
	tr.sim.place(p + side * 1.9, atan2(-fd.x, -fd.z))
	tr.sim.vel = fd * 16.0
	for i in 4:
		tr.sim.omega[i] = 16.0 / TruckSim.RADIUS
	tr.sim.rpm = 1500.0
	tr.sim.gear = "3"
	tr.sim.running = true
	tr.sound.running = true
	tr.sim.throttle = 0.2
