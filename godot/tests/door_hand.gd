extends SceneTree
# The door by hand, headless (game/door_hand.gd): the kid at ten to eight, each verdict on offer is
# found, and a real drag (press on his hand, up, let go) says no to the kid, with the room's beat
# before the column. Then the same with the sister: the sweep toward the room lets them in.
#   godot --headless --path godot -s res://tests/door_hand.gd

var main
var fails := 0


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _ok(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		fails += 1


func _at(knot: String) -> void:
	main.reset_story()
	var res: Dictionary = main.game.jump(knot)
	main.view.jump_to("door")
	main.stage.sync(main.game, true)
	main.show(res, true)
	await _frames(10)
	while main.pending != null:
		main._go_on()
		await _frames(2)
	await _frames(10)


func _drag(by: Vector2) -> void:
	var dh: DoorHand = main.door_hand
	var sheet: Control = main.view.sheet
	var from: Vector2 = dh._hand_screen() - sheet.global_position
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = from
	sheet.gui_input.emit(e)
	for k in 8:
		var m := InputEventMouseMotion.new()
		m.position = from + by * float(k + 1) / 8.0
		m.relative = by / 8.0
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		sheet.gui_input.emit(m)
		await _frames(2)
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.pressed = false
	u.position = from + by
	sheet.gui_input.emit(u)


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(10)
	var dh: DoorHand = main.door_hand
	var scale: float = main.view.sheet.size.y / 1080.0

	await _at("door_hoodie")
	_ok(dh.shown, "the hand is out at the door with verdicts on offer")
	_ok(dh.offers("in") and dh.offers("out"), "in and no are on offer from the start")
	_ok(not dh.offers("terms"), "terms wait for a longer read (door_reads > 2)")
	# a short drag up and let go: nothing happens
	var before: int = main.game.visible_choices().size()
	await _drag(Vector2(0, -60) * scale)
	await _frames(5)
	_ok(main.game.visible_choices().size() == before and not main.answering, "a short drag goes back to his knee")
	# the palm: up, all the way
	await _drag(Vector2(0, -220) * scale)
	await _frames(2)
	_ok(main.answering, "the room answers before the column")
	_ok(not dh.shown, "the hand's gone while it does")
	await create_timer(main.ANSWER + 0.4).timeout
	await _frames(5)
	_ok(not main.answering, "then the column")
	var inc: String = str(main.game.get_var("incident"))
	_ok(inc.contains("inc_kid_refused"), "the palm said no to the kid (incident: %s)" % inc)

	await _at("ev_sister")
	_ok(dh.offers("in") and dh.offers("out") and dh.offers("terms"), "the sister: in, no and terms on offer")
	var toward: Vector2 = Vector2(-240, 0) if dh.room_left else Vector2(240, 0)
	await _drag(toward * scale)
	await create_timer(main.ANSWER + 0.4).timeout
	await _frames(5)
	var fam: String = str(main.game.get_var("fam"))
	_ok(not fam.contains("sister_refused"), "the sweep toward the room let them in (fam: %s)" % fam)

	print("%d failed" % fails)
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit(1 if fails > 0 else 0)
