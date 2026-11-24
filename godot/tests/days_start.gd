extends SceneTree
# Each night can start on Wednesday, Thursday or Friday (main.DAYS, the Nights menu): the day must be
# the right one, the night must go on by its choices without errors, and the save must say the day.
#   godot --headless --path godot -s res://tests/days_start.gd

var main
var bad := 0


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _run() -> void:
	await _secs(1.0)
	main.settings["dice"] = "still"
	var want := {"wednesday": 1, "dawn": 2, "friday": 3}
	for d in main.DAYS:
		var knot: String = d[0]
		main.store.clear(2)
		main.start_day(2, knot)
		await _secs(1.5)
		var day := int(main.game.get_var("day"))
		print("%s: day %d, at %s, %d choices" % [d[1], day, main.game.here(), main.game.visible_choices().size()])
		var made := 0
		for k in 12:
			if main.pending != null:
				main._go_on()
			elif not main.game.visible_choices().is_empty():
				if knot == "friday":
					print("        > ", main.game.visible_choices()[0].text, "   [", main.game.here(), " ", main.game.get_var("clock"), "]")
				main.choose(0)
				made += 1
			await _secs(0.3)
		day = int(main.game.get_var("day"))
		var ok: bool = day == int(want[knot])
		if not ok:
			bad += 1
			print("BAD   day %d after its first choices" % day)
		var meta: String = Store.meta(main.store.load_slot(2))
		print("      %d choices made; the save says: %s" % [made, meta])
		if not meta.begins_with(d[1]) and not main.game.ended:
			bad += 1
			print("BAD   the save doesn't say %s" % d[1])
		if not main.game.errors.is_empty():
			bad += 1
			print("BAD   ink errors: ", main.game.errors)
		main.back_to_title()
		await _secs(2.5)
	print("%d bad" % bad)
	quit(1 if bad > 0 else 0)
