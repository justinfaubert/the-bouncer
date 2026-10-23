extends SceneTree
# Plays the raw Ink (no engine, the story's own fallbacks) with a seeded chooser and writes a
# transcript, for tools/ink_diff.mjs to compare line for line with inkjs.
#   godot --headless --path godot -s res://tests/ink_run.gd -- --from 1 --to 50 --out /tmp/ink
# --start knot.stitch plays each night from there instead, to reach a scene the seeded chooser rarely does.

func esc(s: String) -> String:
	return s.replace("\\", "\\\\").replace("\n", "\\n").replace("|", "\\p")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var from := 1
	var to := 10
	var out_dir := "/tmp/ink"
	var start := ""
	var i := 0
	while i < args.size():
		match args[i]:
			"--from": from = int(args[i + 1]); i += 1
			"--to": to = int(args[i + 1]); i += 1
			"--out": out_dir = args[i + 1]; i += 1
			"--start": start = args[i + 1]; i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out_dir)
	var t0 := Time.get_ticks_usec()
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json")).story
	var t1 := Time.get_ticks_usec()
	var total_steps := 0
	var total_continue_us := 0
	var worst_us := 0
	for seed in range(from, to + 1):
		var lines: PackedStringArray = []
		var story := Ink.Story.new(json)
		story.allow_external_function_fallbacks = true
		story.on_error = func(msg, type): lines.append("E|%d|%s" % [type, esc(str(msg))])
		story.state().story_seed = seed % 2147483647
		if start != "":
			story.choose_path_string(start)
		var rng := seed
		var steps := 0
		var save_at := 20 + seed % 60
		while true:
			var c0 := Time.get_ticks_usec()
			while story.can_continue():
				var text := story.continue_story()
				lines.append("T|%s|%s" % [esc(text), esc("#".join(story.current_tags()))])
			var dt := Time.get_ticks_usec() - c0
			total_continue_us += dt
			worst_us = maxi(worst_us, dt)
			var ch := story.current_choices()
			if ch.is_empty():
				break
			for c in ch:
				lines.append("C|%d|%s|%s" % [c.index, esc(c.text_value), esc("#".join(c.tags if c.tags != null else []))])
			if steps == save_at:
				var saved := story.state().to_json()
				FileAccess.open("%s/g_%d.state.json" % [out_dir, seed], FileAccess.WRITE).store_string(saved)
				var fresh := Ink.Story.new(json)
				fresh.allow_external_function_fallbacks = true
				fresh.on_error = story.on_error
				fresh.state().load_json(saved)
				story = fresh
				lines.append("S|%d" % steps)
			rng = (rng * 48271) % 2147483647
			var pick := rng % ch.size()
			lines.append("P|%d" % pick)
			story.choose_choice_index(pick)
			steps += 1
			if steps > 3000:
				lines.append("CAP")
				break
		total_steps += steps
		lines.append("END|%d|%s" % [steps, str(story.state().visit_count_at_path_string("ledger"))])
		FileAccess.open("%s/g_%d.txt" % [out_dir, seed], FileAccess.WRITE).store_string("\n".join(lines) + "\n")
	var t2 := Time.get_ticks_usec()
	print("parsed json in %d ms; %d nights, %d choices, %.1f s; continue avg %.2f ms per choice, worst %.1f ms" % [
		(t1 - t0) / 1000, to - from + 1, total_steps, (t2 - t1) / 1e6,
		total_continue_us / 1000.0 / maxi(1, total_steps), worst_us / 1000.0])
	quit()
