extends "res://tests/going.gd"
# Choices where he is (Hutch, 23 November: "it needs to be more location and context aware"). Out on
# the floor and free to walk, a choice about someone across the room is out of his reach: it's
# dimmed in the column, and making it walks him over first and then makes it. Ways somewhere are
# always his. Headless:
#   godot --headless --path godot -s res://tests/reach_choice.gd


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	main.settings["keys_walk"] = true
	v = main.view
	if not await _a_night():
		print("never got out onto the floor: " + _here())
		await _done()
		return
	print("on the floor: " + _here())
	_ok("free to walk here", main.feet.free_here())
	var list: Array = main.game.visible_choices()
	var far_i := -1
	var near_n := 0
	var ways := 0
	for i in list.size():
		var why: String = main.out_of_reach(list[i])
		if Going.is_way(list[i]):
			ways += 1
			_ok("a way somewhere is never out of reach: " + str(list[i].text), why == "")
		if why != "" and far_i < 0:
			far_i = i
		if why == "":
			near_n += 1
		print("  %s %s" % ["FAR " if why != "" else "    ", list[i].text])
	if far_i < 0:
		print("  (nothing out of reach from here, %d choices)" % list.size())
		await _done()
		return
	var r = main.column.row_for_index(far_i)
	await _frames(20)
	_ok("the far one is dimmed in the column", r != null and r.modulate.a < 0.6)
	var text := str(list[far_i].text)
	var turn0: int = main.game.turn
	var p0: Vector3 = main.view.eye_pos
	main.choose(far_i)
	await _frames(2)
	_ok("making it doesn't make it from across the room", main.game.turn == turn0)
	_ok("he sets off over there", main.view.walking or not main._walk_then.is_empty())
	await _settle(20.0)
	await _frames(30)
	print("  walked %.1f m" % _off(p0))
	_ok("and then it's made, over there", main.game.turn > turn0 or main.game.visible_choices().all(func(c): return str(c.text) != text))
	await _done()
