extends SceneTree
# Pictures of the cigarette machine (game/cig_machine.gd), from Rehearse with no night: from the
# hall's post, stood at it, a chord pulled with a quarter in and the lamp on, the front open on
# the service board, and the pack in the tray. Prints what the synth's doing at each.
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 \
#     --path godot -s res://tests/shots_cig.gd -- --out /tmp/cig

var main
var out := "/tmp/cig"
var shots := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
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
	var c = main.cig
	var sounding := []
	for v in c.synth.voices:
		if v.busy:
			sounding.append("%d(%.2f)" % [v.note, v.amp])
	print("shot ", file, "  sounding ", sounding, " credit ", c.synth.credit, " latched ", c.synth.latched, " patch ", c.synth.P.name, " hovered ", c.hovered)


func _run() -> void:
	await _frames(5)
	main.view.jump_to("hall")
	await _frames(40)
	await _grab("from_the_hall")
	main.start_cig("rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(90)
	await _grab("stood_at_it")
	var c = main.cig
	# the pointer on the slot: what it says it is
	_point(c, Vector3(0.91 - 0.5, 1.04, 0.0))
	await _frames(10)
	await _grab("pointer_on_the_slot")
	c._coin()
	c._press("lamp", false)
	for n in [0, 4, 7]:
		c.by_key[n] = 0.7
	await _frames(40)
	await _grab("a_chord_pulled")
	c.by_key.clear()
	await _frames(40)
	await _grab("let_go_and_held")
	c._door_toggle()
	await _frames(80)
	await _grab("front_open")
	c._drum(0, 5)
	await _frames(10)
	await _grab("price_turned")
	c._door_toggle()
	c.dollars = 0
	c.dimes = 5
	c._apply_price()
	c._coin()
	c._coin()
	c.grabbed = 6
	c.pull[6] = 1.0
	await _frames(60)
	c.grabbed = -1
	await _frames(30)
	await _grab("the_pack")
	c.end()
	await _frames(30)
	await _grab("back_to_rehearse")
	quit()


func _point(c, local: Vector3) -> void:
	var w: Vector3 = c.root.global_transform * local
	var p: Vector2 = main.view.cam.unproject_position(w)
	main.view.pointer = p
	c.hovered = c._under()
