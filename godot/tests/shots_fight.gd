extends SceneTree
# Pictures of the fights (game/fight.gd, fight_cards.gd), from Rehearse with no night: the fish plant
# with Ox at the line, a frozen second, his fists up, a straight thrown (the tell, the travel, the
# hit held), a hook, Ox's own swing coming (his shoulder back), holding him, Ox down; the deck with
# the man and Dale on his arm, the frozen frame there, the walk. Each picture is checked by eye for
# holes and clipping before anyone sees it. Needs a display:
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 \
#     --path godot -s res://tests/shots_fight.gd -- --out /tmp/fight [--only ox|ogre]

var main
var out := "/tmp/fight"
var only := ""
var shots := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--only": only = args[i + 1]; i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _secs(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await process_frame


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	shots += 1
	var file := "%02d_%s" % [shots, name]
	root.get_viewport().get_texture().get_image().save_png(out.path_join(file + ".png"))
	print("shot ", file)


# run the sim forward by s seconds with the picture held still between (lavapipe is slow: the
# sim is stepped by hand so what's pictured is what the sim says)
func _sim(s: float) -> void:
	var f = main.fight
	for k in int(s / FightSim.DT):
		f.sim.step()
		for e in f.sim.take_events():
			f._on_event(e)
	f.hold = 0.0
	for k in int(clampf(s, 0.1, 0.5) / 0.016):
		for fg in f.figures:
			f._pose(fg, 0.016)
		f._place_eyes(0.016)
		f._fists(0.016)
	print("  me %s down=%s  him %s down=%s  eye %s yaw %.2f pitch %.2f flash %.2f hurt %d breath %.2f" % [f.sim.a.pos, f.sim.a.down, f.sim.b.pos, f.sim.b.down, main.view.eye_pos, main.view.yaw, main.view.pitch, main.view.flash, main.view.hurt, f.sim.a.breath])


func _run() -> void:
	await _frames(5)
	main.menus.rehearse("title")
	await _frames(5)
	if only == "" or only == "ox":
		await _ox()
	if only == "" or only == "ogre":
		await _ogre()
	quit()


func _pick(id: String) -> void:
	var s = main.cards.seconds
	var t0 := Time.get_ticks_msec()
	while not s.visible and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	await _frames(3)
	for i in s.choices.size():
		if s.choices[i].id == id:
			s._choose(i)
			return


func _ox() -> void:
	main.start_fight("ox", "rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290})
	var t0 := Time.get_ticks_msec()
	while not main.cards.seconds.visible and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	await _frames(4)
	await _grab("ox_frozen_at_scratch")
	await _pick("toe")
	await _secs(1.0)
	var f = main.fight
	var sim: FightSim = f.sim
	f.freeze(true)
	_sim(0.3)
	await _frames(3)
	await _grab("ox_guard_up")
	# a straight to the jaw: the tell, then the hit held
	sim.a.pos = sim.b.pos + (sim.a.pos - sim.b.pos).normalized() * 1.0
	sim.strike(sim.a, "R", "straight", Vector2(0.0, sim.b.head_y() - 0.06), 1.0)
	_sim(0.12)
	await _frames(3)
	await _grab("ox_straight_tell")
	_sim(0.1)
	await _frames(3)
	await _grab("ox_straight_hit")
	_sim(0.15)
	await _frames(3)
	await _grab("ox_head_snapped")
	_sim(0.8)
	# Ox's own big hook coming: his shoulder back
	sim.strike(sim.b, "R", "hook", Vector2(0.1, sim.a.head_y()), 1.0)
	_sim(0.35)
	await _frames(3)
	await _grab("ox_hook_tell")
	_sim(0.25)
	await _frames(3)
	await _grab("ox_hook_landed")
	_sim(1.0)
	# take hold of him and turn him
	sim.a.grips["L"] = {"part": "collar", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO, "circle": 0.0}
	sim.a.grips["R"] = {"part": "arm_L", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO, "circle": 0.0}
	for k in 30:
		var ang := k * 0.1 * 6.0
		sim.a.pull = Vector2(cos(ang), sin(ang)) * 5.0
		_sim(0.1)
	await _frames(3)
	await _grab("ox_held_turning")
	sim.a.pull = Vector2.ZERO
	sim.a.grips.clear()
	sim._fall(sim.b, (sim.b.pos - sim.a.pos).normalized(), "test")
	for k in 8:
		_sim(0.1)
	await _frames(3)
	await _grab("ox_down")
	main.cards._quit = true
	await _secs(12.0)


func _ogre() -> void:
	main.start_fight("ogre", "rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1300})
	var t0 := Time.get_ticks_msec()
	while not main.cards.seconds.visible and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	await _frames(4)
	await _grab("ogre_frozen_deck")
	await _pick("arm")
	await _secs(1.0)
	var f = main.fight
	f.freeze(true)
	_sim(0.6)
	await _frames(3)
	await _grab("ogre_holding_arm")
	for k in 10:
		_sim(0.3)
	await _frames(3)
	await _grab("ogre_surging")
	main.cards._quit = true
	await _secs(12.0)
