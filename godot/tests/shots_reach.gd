extends SceneTree
# Pictures of what this round changed, to look at: his eyes on things with nothing on offer about
# them (the jukebox from the floor, the window from the lot, the can on the deck), a look said in
# the column, the scenes seen from somewhere of their own (the jukebox, the payphone), and the dice
# thrown at each post, on the tray where they'd have gone on the floor. Needs a display (xvfb-run)
# and the Compatibility renderer:
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_reach.gd -- --out /tmp/shots [--dice floor,lot] [--dice-only]

var main
var out := "/tmp/shots"
var dice := ["floor", "door", "bar", "pool", "hall", "keg", "deck", "lot", "lot:pickup", "upstairs"]
var dice_only := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--dice": dice = Array(args[i + 1].split(",")); i += 1
			"--dice-only": dice_only = true
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
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _go(post: String) -> void:
	# past any pause, so his eyes can rest on things
	while main.pending != null and main.rolling == null:
		main._go_on()
		await _frames(5)
	main.view.frame = post.get_slice(":", 1) if ":" in post else ""
	main.view.jump_to(post.get_slice(":", 0))
	(main.pub.dyn.truck as Node3D).visible = post == "lot:pickup"
	main.stage._settle(0.0)
	await _frames(20)


# his eyes on a thing, by the middle of his view
func _eyes_on(id: String) -> void:
	main.view.pointer = Vector2(-1, -1)
	var w: Array = main.spots.look_spot(id)
	if w.is_empty():
		print("  can't look at %s from %s" % [id, main.view.place])
		return
	main.view.look_at_point(w[0])
	await _frames(40)


func _run() -> void:
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.settings["dice"] = "quick"
	main.start_new(2)
	await _frames(30)
	if not dice_only:
		await _looks()
	await _dice()
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()


func _looks() -> void:
	# the things
	await _go("floor")
	await _eyes_on("jukebox")
	await _grab("20_floor_jukebox")
	main.spots.click()
	await _frames(30)
	await _grab("21_floor_jukebox_looked")
	await _go("lot")
	await _eyes_on("window")
	await _grab("22_lot_window")
	await _go("deck")
	await _eyes_on("butt_can")
	await _grab("23_deck_can")
	await _go("kitchen")
	await _eyes_on("radio")
	await _grab("24_kitchen_radio")
	# the scenes seen from somewhere of their own
	await _go("pool:juke")
	await _grab("25_pool_juke")
	await _go("hall:phone")
	await _grab("26_hall_phone")


# the dice, looking a little down and ahead from each post, the way he'd be looking
func _dice() -> void:
	var n := 0
	for p in dice:
		await _go(p)
		main.view.want_pitch = -0.45
		await _frames(20)
		var roll: Dictionary = Checks.resolve(4, 5, 8, 0, 1)
		var it := {"kind": "check", "voice": "fighter", "label": "Picture", "word": "Hard", "target": 8,
			"success": roll.success, "roll": roll, "mods": []}
		# the night slowed right down while they're thrown: a frame here can take most of a second,
		# and at full speed one frame steps past them lying still, the stamp and all, to after
		Engine.time_scale = 0.06
		main.render_items([it], true)
		var guard := 0
		while guard < 1500 and not (main.dice.state == "roll" and main.dice.sim != null
				and main.dice.ts > maxf(float(main.dice.sim.rest_t[0]), float(main.dice.sim.rest_t[1])) + 0.1):
			guard += 1
			await _frames(1)
		if guard >= 1500:
			print("  the dice never lay still at %s (state %s)" % [p, main.dice.state])
		await _grab("3%d_dice_%s" % [n, p.replace(":", "_")])
		Engine.time_scale = 1.0
		n += 1
		guard = 0
		while main.rolling != null and guard < 600:
			guard += 1
			await _frames(1)
		main.pending = null
		await _frames(10)
