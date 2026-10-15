extends SceneTree
# Whether his head stays where the player leaves it (game/view.gd, game/dice.gd): he gets somewhere
# still looking the way he was walking, or the way the player turned him on the way; someone there
# turns it when he gets there, and so does sitting down; the dice draw his eyes and give them back
# after, but not once the player's looked away from them; a tap on the room skips the dice, a drag
# only looks round, and the tap goes no further. Headless:
#   godot --headless --path godot -s res://tests/head.gd

var main
var v
var bad := 0
const CHECK := {"kind": "check", "label": "Composure", "word": "steady", "target": 8, "voice": "composure",
	"success": true, "roll": {"d1": 4, "d2": 5, "natural": 9, "total": 9, "target": 8, "mod": 0, "tension": 1}}


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _ok(what: String, ok: bool, more := "") -> void:
	print(("  ok     " if ok else "  WRONG  ") + what + ("" if ok or more == "" else "  (" + more + ")"))
	if not ok:
		bad += 1


func _off(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


func _aim_off(p: Vector3) -> float:
	return _off(v.want_yaw, Posts.aim(v.eye_pos, p).x)


# walk somewhere, noting where he was looking the last moment before he got there; the player
# turning his head a moment on the way, or something there asking for his eyes
func _walk(to: String, turn_at := -1.0, glance := Vector3.INF) -> Vector2:
	v.walk_to(to)
	if glance != Vector3.INF:
		await _frames(3)
		v.look_at_point(glance)
	var last := Vector2(v.want_yaw, v.want_pitch)
	var t0 := Time.get_ticks_msec()
	var turned := false
	while v.walking and Time.get_ticks_msec() - t0 < 20000:
		if turn_at >= 0.0 and not turned and (Time.get_ticks_msec() - t0) / 1000.0 >= turn_at:
			turned = true
			v.keys_turn = Vector2(1, 0)
			await _wait(0.3)
			v.keys_turn = Vector2.ZERO
		last = Vector2(v.want_yaw, v.want_pitch)
		await process_frame
	await _frames(2)
	return last


func _press(at: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = at
	v.sheet.gui_input.emit(e)


func _move(at: Vector2, by: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at + by
	e.relative = by
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	v.sheet.gui_input.emit(e)


# a check, thrown from here: in his hand, shaken a moment, let go; back when it's rolling
func _throw() -> void:
	main.render_items([CHECK.duplicate(true)], true)
	await _frames(3)
	main.dice.key(true)
	await _wait(0.3)
	main.dice.key(false)
	var t0 := Time.get_ticks_msec()
	while main.dice.state != "roll" and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	await _frames(2)


func _over() -> void:
	var t0 := Time.get_ticks_msec()
	while main.rolling != null and Time.get_ticks_msec() - t0 < 20000:
		await process_frame


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "full"
	main.start_new(2)
	await _frames(10)
	v = main.view
	v.frame = ""

	print("== walking")
	v.jump_to("door")
	await _frames(2)
	var last := await _walk("floor")
	_ok("gets to the floor still looking the way he was walking", _off(v.want_yaw, last.x) < 0.001,
		"%.3f off" % _off(v.want_yaw, last.x))
	_ok("  and not turned to the floor's own look", _aim_off(Posts.post("floor").look) > 0.2)
	v.jump_to("bar")
	await _frames(2)
	last = await _walk("hall", 0.4)
	_ok("turned on the way to the hall, still looking there when he gets there", _off(v.want_yaw, last.x) < 0.001)
	var way_on := Posts.aim(Vector3(6.5, Posts.STAND, 0.9), Vector3(7.3, Posts.STAND - 0.15, -0.6)).x
	_ok("  the last stretch didn't turn him back to the way he was going", _off(v.want_yaw, way_on) > 0.2)
	v.jump_to("bar")
	await _frames(2)
	var who := Vector3(9.5, 1.5, 3.2)
	await _walk("pool", -1.0, who)
	_ok("someone there, on the way to the pool: he looks at them when he gets there", _aim_off(who) < 0.01,
		"%.3f off" % _aim_off(who))
	v.jump_to("floor")
	await _frames(2)
	await _walk("door")
	_ok("sits on his stool by the door and faces what it faces", _aim_off(Posts.post("door").look) < 0.01)

	print("== the dice")
	v.jump_to("floor")
	await _frames(2)
	await _throw()
	_ok("his eyes go to where they'll lie, and narrow", _aim_off(main.dice.rest_mid) < 0.35 and v.focus_fov > 0.0,
		"%.3f off, fov %.1f" % [_aim_off(main.dice.rest_mid), v.focus_fov])
	var back: Vector2 = main.dice._look_back
	await _over()
	await _wait(1.2)
	_ok("and back where the player had them after", _off(v.want_yaw, back.x) < 0.001 and absf(v.want_pitch - back.y) < 0.001)

	v.jump_to("floor")
	await _frames(2)
	await _throw()
	v.keys_turn = Vector2(-1, 0)
	await _wait(0.25)
	v.keys_turn = Vector2.ZERO
	await _frames(2)
	var put: float = v.want_yaw
	_ok("the player looks away mid-roll: his eyes widen again", v.focus_fov == 0.0)
	await _wait(0.3)
	_ok("  and the dice don't pull them back", _off(v.want_yaw, put) < 0.001)
	await _over()
	await _wait(1.2)
	_ok("  nor does it being over", _off(v.want_yaw, put) < 0.001)

	v.jump_to("floor")
	await _frames(2)
	await _throw()
	var mid: Vector2 = (v.sheet as Control).size / 2.0
	_press(mid, true)
	for k in 6:
		_move(mid + Vector2(k * 8, 0), Vector2(8, 0))
		await process_frame
	_press(mid + Vector2(48, 0), false)
	await _frames(2)
	_ok("a drag while they're rolling looks round and doesn't skip them", main.dice.state == "roll" and v.focus_fov == 0.0,
		"state %s" % main.dice.state)
	var turn: int = main.game.turn
	_press(mid, true)
	await process_frame
	_press(mid, false)
	_ok("a tap skips them", main.dice.state in ["done", ""], "state %s" % main.dice.state)
	_ok("  and isn't a click on the room too", main.dice.wants_click() and main.game.turn == turn)
	await _over()
	await _wait(0.5)

	print("== %s" % ("all right" if bad == 0 else "%d wrong" % bad))
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit(1 if bad > 0 else 0)
