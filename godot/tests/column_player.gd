extends SceneTree
# A player who only goes by the column: every choice is one of the rows there (a numbered choice, a
# way's chip, or a place's name under GO WHERE HE LOOKS), at random, seeded, never the room itself.
# The night has to get to its end that way. It fails on a moment with nothing in the column to click,
# on going round in a circle with no way out of it (the column back the same at the same minute with
# nothing in the night changed, and only the one thing in it to do, the way "Count the room." once
# came straight back after "That's enough counting."; or back the same ten times), and on script
# errors. Going back and forth by choice (a thing into the drawer and out again) is only noted.
#   godot --headless --path godot -s res://tests/column_player.gd -- --seed 3

var main
var v: View
var rs := 3
var errors := Errors.new()


class Errors extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			count += 1


func rnd() -> int:
	rs = (rs * 48271) % 2147483647
	return rs


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--seed": rs = int(args[i + 1]); i += 1
		i += 1
	OS.add_logger(errors)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


# the night going on by itself till there's a choice to make
func _settle(secs := 60.0) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		if main.game.ended:
			return
		if main.rolling != null:
			if main.rolling.has_method("finish"):
				main.rolling.finish()
			continue
		if main.pending != null:
			main._go_on()
			continue
		if not v.walking and not main.game.visible_choices().is_empty():
			return


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	v = main.view
	var seed0 := rs
	main.start_new(3)
	await _frames(3)
	var t0 := Time.get_ticks_msec()
	var empty := 0
	var circles := 0
	var seen := {}
	var minute := -1
	var steps := 0
	# what it takes to not get the job (content/ink/office.ink): a player has to set out to
	var walks_out := RegEx.create_from_string("^(\"Want to find out\\?\"|Get up and go\\.|\"Must be nice\\.)")
	while steps < 900:
		await _settle()
		if main.game.ended:
			break
		var list: Array = main.game.visible_choices()
		var rows: Array = main.column.rows.filter(func(r): return is_instance_valid(r) and r.index < list.size())
		if rows.is_empty():
			empty += 1
			var names := []
			for c in list:
				names.append(str(c.text))
			print("  WRONG  nothing in the column to click, at %s (%s): %s" % [main.game.status().clockText, v.place, " | ".join(names)])
			if empty > 3:
				break
			main.choose(rnd() % list.size())
			steps += 1
			continue
		var clock := int(main.game.get_var("clock"))
		if clock != minute:
			minute = clock
			seen.clear()
		var shown: Array = rows.map(func(r): return str(list[r.index].text))
		var sig := ",".join(shown) + "|" + JSON.stringify(main.game.vars())
		var again: int = seen.get(sig, 0)
		seen[sig] = again + 1
		if again > 0 and (rows.size() == 1 or again >= 10):
			circles += 1
			print("  WRONG  round in a circle at %s, with no way out of it: %s" % [main.game.status().clockText, " | ".join(shown)])
			if circles > 3:
				break
		elif again == 1:
			print("  (back the same at %s, by going back and forth: %s)" % [main.game.status().clockText, " | ".join(shown)])
		var pick: int = rows[rnd() % rows.size()].index
		if main.game.here() == "office" and walks_out.search(str(list[pick].text)) != null and rnd() % 10 != 0:
			pick = rows[0].index
		main.choose(pick)
		steps += 1
	var ended: bool = main.game.ended
	print("seed %d: %d choices, %s, %d times nothing in the column, %d circles, %d script errors, %.0f s" % [seed0, steps,
		("ended at " + main.game.status().clockText) if ended else "NOT ENDED at " + main.game.status().clockText,
		empty, circles, errors.count, (Time.get_ticks_msec() - t0) / 1000.0])
	print("== all right" if ended and empty == 0 and circles == 0 and errors.count == 0 else "== WRONG")
	quit()
