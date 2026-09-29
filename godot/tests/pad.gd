extends SceneTree
# A night's first choices made on a pad, headless: the d-pad goes through the choices, A makes the
# lit one, A goes on through pauses and throws the dice, B pauses and B again goes back, a stick
# turns his head. Fails on script errors or if a choice doesn't land.
#   godot --headless --path godot -s res://tests/pad.gd

var main


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _btn(b: JoyButton, pressed := true) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = pressed
	main._unhandled_input(e)


func _tap(b: JoyButton) -> void:
	_btn(b, true)
	await _frames(2)
	_btn(b, false)
	await _frames(2)


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	main.start_new(3)
	await _frames(3)
	var made := 0
	var guard := 0
	while made < 12 and guard < 4000:
		guard += 1
		await _frames(1)
		if main.game.ended:
			break
		if main.rolling != null or main.pending != null:
			await _tap(JOY_BUTTON_A)
			continue
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			await _frames(5)
			continue
		var before: int = main.game.night_log.size()
		# down three times and up once: the second row of three or more, else the first
		await _tap(JOY_BUTTON_DPAD_DOWN)
		await _tap(JOY_BUTTON_DPAD_DOWN)
		await _tap(JOY_BUTTON_DPAD_DOWN)
		await _tap(JOY_BUTTON_DPAD_UP)
		if main.pad_row == null:
			push_error("pad: nothing lit with %d choices" % list.size())
			quit(1)
			return
		var shown: Array = main.column.rows.filter(func(r): return is_instance_valid(r) and r.is_visible_in_tree())
		var expect: int = shown[maxi(0, mini(2, shown.size() - 1) - 1)].index
		if main.pad_row.index != expect:
			push_error("pad: lit row %d, expected %d" % [main.pad_row.index, expect])
			quit(1)
			return
		var want: String = str(main.pad_row.index)
		await _tap(JOY_BUTTON_A)
		await _frames(3)
		if main.game.night_log.size() == before:
			push_error("pad: A made no choice (row %s)" % want)
			quit(1)
			return
		made += 1
		print("pad: chose row ", want, " at ", main.game.status().clockText)
	# the stick, and the pause and back
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_RIGHT_X
	m.axis_value = 0.8
	main._unhandled_input(m)
	await _frames(2)
	print("pad: stick turns ", main.view.keys_turn)
	m.axis_value = 0.0
	main._unhandled_input(m)
	await _tap(JOY_BUTTON_B)
	print("pad: B pauses: ", main.menus.is_open())
	await _tap(JOY_BUTTON_B)
	print("pad: B again: ", main.menus.is_open())
	print("pad: %d choices made on the pad" % made)
	main.back_to_title()
	await _frames(2)
	main.store.clear(3)
	main.settings["slot"] = 1
	main.store.save_settings()
	quit(0 if made >= 12 or main.game.ended else 1)
