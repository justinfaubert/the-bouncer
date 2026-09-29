extends SceneTree
# Plays the game as a player would, headless: boots the main scene, starts a night, and makes
# choices (at random, seeded) through pauses, dice and the till tape, handling things now and
# then, saving and loading mid-night. Prints what went by and fails on script errors.
#   godot --headless --path godot -s res://tests/smoke.gd -- --seed 3 --steps 400

var main
var rs := 7
var steps := 400
var log_lines: Array = []


func rnd() -> int:
	rs = (rs * 48271) % 2147483647
	return rs


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--seed": rs = int(args[i + 1]); i += 1
			"--steps": steps = int(args[i + 1]); i += 1
		i += 1
	var scene: PackedScene = load("res://main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	main.start_new(3)
	await _frames(3)
	var made := 0
	var loads := 0
	var guard := 0
	while made < steps and guard < steps * 40:
		guard += 1
		await _frames(1)
		if main.game.ended:
			print("ENDED after %d choices" % made)
			break
		if main.rolling != null:
			if main.rolling.has_method("finish"):
				main.rolling.finish()
			await _frames(2)
			continue
		if main.pending != null:
			main._go_on()
			await _frames(1)
			continue
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			await _frames(5)
			continue
		# now and then, handle what's in his hands, or click the clicker
		if rnd() % 7 == 0 and main.props.holding():
			main.props.key(KEY_E)
			await _frames(2)
		if rnd() % 11 == 0 and main.game.clicker_in_hand():
			main.props.clicker_key(false)
		var pick := rnd() % list.size()
		var st: Dictionary = main.game.status()
		log_lines.append("%s %s  %s" % [st.clockText, st.here, str(list[pick].text).substr(0, 70)])
		main.choose(pick)
		made += 1
		# save and load back, now and then
		if made % 37 == 0:
			main.back_to_title()
			await _frames(2)
			main.resume(3)
			loads += 1
			await _frames(3)
	var st2: Dictionary = main.game.status()
	print("choices %d, loads %d, clock %s, here %s, figures %d, column nodes %d" % [made, loads, st2.clockText, st2.here, main.stage.figures.size(), main.column.story.get_child_count()])
	for l in log_lines.slice(maxi(0, log_lines.size() - 12)):
		print("  ", l)
	var who: Array = main.stage.figures.keys()
	who.sort()
	print("in the room: ", ", ".join(who))
	# leave no night behind: the title would offer to show how the test ended
	main.store.clear(3)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
