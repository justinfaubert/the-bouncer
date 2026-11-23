extends SceneTree
# Back to the title from a night, from a game and from the truck, and into a night again, several
# times over: none of it may crash or raise a script error (Hutch, 23 November: "the game crashes
# when you try to go back to the main menu").
#   godot --headless --path godot -s res://tests/back_to_title.gd

var main


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _run() -> void:
	await _secs(1.0)
	main.settings["dice"] = "still"
	for round in 3:
		print("round %d: into a night" % round)
		main.start_new(3)
		await _secs(2.0)
		for k in 6:
			if main.pending != null:
				main._go_on()
			else:
				main.choose(0)
			await _secs(0.4)
		print("round %d: back to the title" % round)
		main.back_to_title()
		await _secs(3.0)
		print("round %d: resume" % round)
		main.resume(3)
		await _secs(2.0)
		main.back_to_title()
		await _secs(3.0)
		print("round %d: darts from the title, then back" % round)
		main.start_darts("practice", "rehearse", {})
		await _secs(1.0)
		main.darts.end()
		await _secs(2.0)
	print("done, no crash")
	quit(0)
