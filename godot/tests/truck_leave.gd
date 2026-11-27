extends SceneTree
# Into the truck from Rehearse and out again with Esc, twice, then the title: nothing may error.
#   godot --headless --path godot -s res://tests/truck_leave.gd
var main
var errors := Errors.new()


class Errors extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			count += 1

func _init() -> void:
	OS.add_logger(errors)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()

func _frames(n: int) -> void:
	for k in n:
		await process_frame

func _esc() -> void:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_ESCAPE
	e.keycode = KEY_ESCAPE
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await _frames(5)

func _run() -> void:
	await _frames(10)
	for n in 2:
		main.menus.rehearse("title")
		await _frames(5)
		main.start_truck("rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": 1290, "cold": 0.0})
		await _frames(60)
		await _esc()
		await _frames(30)
		print("out of the truck, menu open: ", main.menus.is_open(), "  truck active: ", main.truck.active)
	main.menus.back()
	await _frames(30)
	print("truck_leave: %s" % ("ok" if errors.count == 0 else "%d errors" % errors.count))
	quit(1 if errors.count else 0)
