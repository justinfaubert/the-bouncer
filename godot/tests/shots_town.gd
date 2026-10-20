extends SceneTree
# Pictures of the town before the night (world/town.gd), each place and each way it's seen, at its
# hour: Gary's office at four, from his chair, and the doorway and the bookkeeper from it; the old
# main street at twenty to five, and the old man at the wharf's rail; the Esso at five to five, and
# the kid on its freezer; the seawall at ten past five and at ten past seven; his room at
# twenty-five to six; his head turned from those posts to what's round them (the bank, the white
# church, the Esso's store, his father's photo and the notice on Gary's desk);
# the street's buildings from across it, for looking the town over (nowhere he's put); and the lot
# at twenty to eight, come to across the highway from the seawall, and down from his room and round
# the front, and once more from the door after (his head's his own again). Then the cost of a frame
# at the street against the door. Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_town.gd -- --out /tmp/town [--only office,esso_kid]

var main
var out := "/tmp/town"
var only: Array = []
# the name, the place, the way it's seen, the clock
const SHOTS := [
	["office", "office", "", 960],
	["office_door", "office", "door", 960],
	["office_bk", "office", "bk", 960],
	["street", "street", "", 1000],
	["street_wharf", "street", "wharf", 1000],
	["esso", "esso", "", 1015],
	["esso_kid", "esso", "kid", 1015],
	["seawall", "seawall", "", 1030],
	["seawall_late", "seawall", "", 1150],
	["upstairs", "upstairs", "", 1035],
]
# and his head turned from a post to what's round it (Pub.anchors): the name, the place, the clock,
# the anchor
const TURNS := [
	["turn_bank", "street", 1000, "street_bank"],
	["turn_church", "street", 1000, "street_church"],
	["turn_store", "esso", 1015, "esso_window"],
	["turn_photo", "office", 960, "office_photo"],
	["turn_notice", "office", 960, "office_notice"],
]


# For looking the street over, not anywhere he's put: across from each of its buildings, standing on
# the far sidewalk at twenty to five. The name, where from, what at.
func _near() -> Array:
	var on := func(x: float, z: float) -> Vector3: return Vector3(x, Town.street_y(z) + Town.KERB + Posts.STAND, z)
	var a: Dictionary = main.pub.anchors
	return [
		["near_legion", on.call(-207.3, 24.0), a.street_gun],
		["near_library", on.call(-207.3, -20.5), a.street_library],
		["near_white_church", on.call(-207.3, -50.0), a.street_church],
		["near_gary", on.call(-207.3, -86.0), Vector3(Town.OFFICE_X, Town.OFFICE_Y + 1.2, Town.OFFICE_Z - 0.4)],
		["near_shops", on.call(-192.7, 2.0), Vector3(-208.5, Town.street_y(8.0) + 3.0, 8.0)],
		["near_stone_church", on.call(-192.7, -96.0), Vector3(-212.0, Town.street_y(-106.0) + 8.0, -106.0)],
		["near_esso", Vector3(-150.0, Posts.STAND, 33.5), Vector3(-150.0, 2.5, 12.0)],
	]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--only": only = Array(args[i + 1].split(",")); i += 1
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


# the night's clock (what the stage casts by) and his eyes' (what the light goes by)
func _clock(c: int) -> void:
	main.game.set_var("clock", c)
	main.view.clock = c


func _at(place: String, frame: String, c: int) -> void:
	_clock(c)
	main.view.frame = frame
	main.view.jump_to(place)
	main.stage.sync(main.game, true)


# a walk there, walked out at once (the page going blank where it does)
func _walk(place: String, frame: String) -> void:
	var v: View = main.view
	v.frame = frame
	v.turned_t = -INF
	v.walk_to(place)
	var time := 0.0
	while v.walking and time < 120.0:
		if v._cut != null:
			v._cut.custom_step(5.0)
			continue
		v._process(1.0 / 60.0)
		time += 1.0 / 60.0
	main.stage.sync(main.game, true)


func _want(name: String) -> bool:
	return only.is_empty() or name in only


func _run() -> void:
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	await _frames(5)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(20)
	main.spots.process_mode = Node.PROCESS_MODE_DISABLED
	main.spots.clear()
	for s in SHOTS:
		if not _want(s[0]):
			continue
		_at(s[1], s[2], s[3])
		await _frames(30)
		await _grab("%s_%d" % [s[0], s[3]])
	for s in TURNS:
		if not _want(s[0]):
			continue
		_at(s[1], "", s[2])
		var v: View = main.view
		var a := Posts.aim(v.eye_pos, main.pub.anchors[s[3]])
		v.yaw = a.x
		v.pitch = a.y
		v.want_yaw = a.x
		v.want_pitch = a.y
		await _frames(30)
		await _grab("%s_%d" % [s[0], s[2]])
	if _want("near"):
		_at("street", "", 1000)
		for s in _near():
			var v: View = main.view
			v.eye_pos = s[1]
			var a := Posts.aim(v.eye_pos, s[2])
			v.yaw = a.x
			v.pitch = a.y
			v.want_yaw = a.x
			v.want_pitch = a.y
			await _frames(20)
			await _grab("%s_1000" % s[0])
	# the lot at twenty to eight, from the town: across the highway from the seawall; down from his
	# room and round the front; and then from the door, when the Sov's been seen
	if _want("lot"):
		_at("seawall", "", 1180)
		await _frames(10)
		_walk("lot", "arrive")
		await _frames(30)
		await _grab("lot_from_seawall_1180")
		print("  from the seawall: looking at %s" % _looking())
		_at("seawall", "", 1180)
		_at("upstairs", "", 1180)
		await _frames(5)
		_walk("lot", "arrive")
		await _frames(30)
		await _grab("lot_from_upstairs_1180")
		print("  from his room: looking at %s" % _looking())
		_at("door", "", 1185)
		_walk("lot", "arrive")
		await _frames(30)
		await _grab("lot_from_door_after_1185")
		print("  from the door, after: looking at %s" % _looking())
	# what a frame costs: the street against the door, the town out against all of it put away
	if _want("cost"):
		for p in [["door", 1190], ["street", 1000], ["esso", 1015], ["office", 960], ["seawall", 1030], ["lot", 1190]]:
			_at(p[0], "", p[1])
			await _frames(30)
			var calls := 0
			var prims := 0
			var objs := 0
			var t0 := Time.get_ticks_usec()
			for k in 30:
				await process_frame
				calls += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
				prims += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
				objs += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
			var ms := (Time.get_ticks_usec() - t0) / 1000.0 / 30.0
			print("cost %-8s at %d: %5d draw calls, %7d primitives, %4d objects a frame, %.1f ms a frame (software GL)" % [p[0], p[1], calls / 30, prims / 30, objs / 30, ms])
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()


# what's in the middle of his view, roughly: the Sov's front, or which way
func _looking() -> String:
	var v: View = main.view
	var fwd := -v.cam.global_transform.basis.z
	var to_sov := (Posts.FIRST_SIGHT.look - v.eye_pos).normalized()
	return "the Sov's front (%.0f degrees off)" % rad_to_deg(fwd.angle_to(to_sov)) if fwd.angle_to(to_sov) < 0.35 \
		else "away from it (%.0f degrees off the Sov's front)" % rad_to_deg(fwd.angle_to(to_sov))
