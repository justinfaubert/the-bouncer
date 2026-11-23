extends SceneTree
# Pictures of the wine glasses (game/wine_glasses.gd), from Rehearse with no night: stood at them,
# his hand over one, water poured into three, a fingertip going round a rim (driven here, a frame
# at a time), and a tap along the row. Prints each glass's fill, pitch and how loud it's singing.
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 \
#     --path godot -s res://tests/shots_glasses.gd -- --out /tmp/glasses

var main
var out := "/tmp/glasses"
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
	var g = main.glasses
	var st := []
	for i in WineGlasses.N:
		st.append("%d:%.2f/%.0fHz/%.2f" % [i, g.fill[i], g.synth.freq(i), g.synth.glasses[i].amp])
	print("shot ", file, " over ", g.over, " on ", g.on, " wet %.2f " % g.wet, " ".join(st), " tuner '", g.hover_label.text, "'")


func _run() -> void:
	await _frames(5)
	main.start_glasses("rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(60)
	await _grab("stood_at_them")
	var g = main.glasses
	# his hand over the fourth, then the jug over it, pouring
	g.finger = g.centre(3) + Vector2(0.01, 0.0)
	await _frames(10)
	await _grab("hand_over_one")
	g.pouring = true
	await _frames(70)
	await _grab("pouring")
	g.pouring = false
	g._set_fill(5, 0.55)
	g._set_fill(6, 0.8)
	await _frames(30)
	# the fingertip wetted, then round the rim at about a turn a second
	g.finger = g.centre(3)
	g.down = true
	g._touch()
	g.down = false
	var a := 0.0
	g.down = true
	for k in 90:
		a += 0.1
		var c: Vector2 = g.centre(3)
		g.finger = c + Vector2(cos(a), sin(a)) * WineGlasses.RIM
		g.finger_v = Vector2(-sin(a), cos(a)) * 0.3
		g._moved = -1.0
		await process_frame
	await _grab("singing")
	g.down = false
	for i in WineGlasses.N:
		g.synth.tap(i, 0.6, 1.0)
		await _frames(4)
	await _grab("tapped_along")
	g.end()
	await _frames(20)
	await _grab("back_to_rehearse")
	quit()
