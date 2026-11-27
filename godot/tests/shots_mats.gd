extends SceneTree
# Beer mats (game/beer_mats.gd) from Rehearse: set out over the edge, a flick by script, the mat in
# the air, the snatch at the top, then a stack of five. Prints each flight: how high, how far over
# it had turned when it was caught or landed. Needs a display (see shots_cig.gd).
var main
var out := "/tmp/mats"
var shots := 0

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--out":
		out = args[1]
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
	var m = main.mats
	print("shot %s phase %s n %d pos %s th %.2f om %.1f" % [file, m.phase, m.n, m.pos, m.th, m.om])

func _run() -> void:
	await _frames(5)
	# the sums first: how far over a single mat has turned at the top of its climb, for hand speeds
	var m = main.mats
	for k in [1, 5, 12]:
		for v in [1.0, 1.5, 2.0, 2.5, 3.5, 5.0]:
			m.n = k
			m._reset()
			m._flick(Vector2(0, v), m.overhang * 0.8)
			var top := 0.0
			var th_top := 0.0
			var tt := 0.0
			while m.phase == "air" and tt < 2.0:
				m._step(1.0 / m.HZ)
				tt += 1.0 / m.HZ
				if m.pos.y > top:
					top = m.pos.y
					th_top = m.th
			print("stack %2d hand %.1f m/s: up %.0f mm, turned %.0f deg at the top, splay %.2f, %s after %.2fs" % [k, v, top * 1000.0, rad_to_deg(th_top), m.splay, m.phase, tt])
	m.n = 1
	main.start_mats("rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
	await _frames(60)
	await _grab("set_out")
	m.curled = true
	m.hand = Vector2(m.overhang * 0.7, -0.02)
	await _frames(5)
	await _grab("fingers_under")
	m.set_process(false)
	m._flick(Vector2(0.1, 2.1), m.overhang * 0.75)
	# follow it with the hand and snatch it as it comes flat (the physics stepped here, not by frames)
	m.set_process(false)
	var caught := false
	for f in 1200:
		m._step(1.0 / m.HZ)
		m.hand = m.hand.lerp(m.pos, 0.05)
		m.hand_v = m.vel
		if f == 40:
			m._draw()
			await _grab("in_the_air")
		if absf(fposmod(m.th, TAU) - PI) < 0.25 and m.phase == "air":
			print("snatch at d %.3f rel %.2f th %.2f" % [m.hand.distance_to(m.pos), (m.vel - m.hand_v).length(), m.th])
			m.curled = false
			m._snatch()
			caught = m.phase == "caught"
			break
		if m.phase != "air":
			break
	m._draw()
	m.set_process(true)
	await _frames(2)
	await _grab("snatched" if caught else "missed")
	await _frames(70)
	m.n = 5
	m._reset()
	await _frames(10)
	await _grab("five")
	quit()
