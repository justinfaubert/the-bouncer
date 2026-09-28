extends SceneTree
# Times the Ink port over a few nights and prints where the time goes.
func _init() -> void:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json")).story
	var t0 := Time.get_ticks_usec()
	var choices := 0
	for seed in range(1, 4):
		var story := Ink.Story.new(json)
		story.allow_external_function_fallbacks = true
		story.state().story_seed = seed
		var rng := seed
		while true:
			while story.can_continue():
				story.continue_story()
			var ch := story.current_choices()
			if ch.is_empty(): break
			rng = (rng * 48271) % 2147483647
			story.choose_choice_index(rng % ch.size())
			choices += 1
	var total := Time.get_ticks_usec() - t0
	print("total %.2f s, %d choices, %.2f ms/choice" % [total / 1e6, choices, total / 1000.0 / choices])
	var names := Ink._prof.keys()
	names.sort_custom(func(a, b): return Ink._prof[a] > Ink._prof[b])
	for n in names:
		print("%-16s %8.1f ms  %9d calls  %6.2f us/call" % [n, Ink._prof[n] / 1000.0, Ink._cnt[n], float(Ink._prof[n]) / Ink._cnt[n]])
	quit()
