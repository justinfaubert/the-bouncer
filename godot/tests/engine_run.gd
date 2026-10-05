extends SceneTree
# Plays whole nights through the Godot engine (engine/game.gd) with a seeded player who also
# handles things, puts a hand on choices and saves and reloads mid-night,
# and writes a canonical transcript for tools/engine_diff.mjs to compare with the browser build's.
#   godot --headless --path godot -s res://tests/engine_run.gd -- --from 1 --to 20 --out /tmp/eng

var rs := 1

func rnd() -> int:
	rs = (rs * 48271) % 2147483647
	return rs

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var from := 1
	var to := 5
	var out_dir := "/tmp/eng"
	var i := 0
	while i < args.size():
		match args[i]:
			"--from": from = int(args[i + 1]); i += 1
			"--to": to = int(args[i + 1]); i += 1
			"--out": out_dir = args[i + 1]; i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out_dir)
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json"))
	var t0 := Time.get_ticks_msec()
	var total := 0
	for night in range(from, to + 1):
		var lines := PackedStringArray()
		var g := Game.new(content)
		var res := g.new_game(night)
		lines.append("N " + Canon.of(res))
		rs = night
		var steps := 0
		var save_at := 15 + night % 50
		while not res.ended and steps < 3000:
			if steps == save_at:
				var s := g.serialize()
				s.erase("savedAt")
				var text := JSON.stringify(s)
				g = Game.new(content)
				res = g.load_save(JSON.parse_string(text))
				lines.append("S " + Canon.of(res))
			var vis := g.visible_choices()
			if vis.is_empty():
				lines.append("STUCK")
				break
			var handled: Array = []
			for c in res.choices:
				if c.get("toy") != null and c.get("unlisted", false) and is_same(g.toy_choice(c.toy.id, c.toy.what), c):
					handled.append(c)
			if not handled.is_empty() and rnd() % 3 == 0:
				var hc: Dictionary = handled[rnd() % handled.size()]
				res = g.toy(hc.toy.id, hc.toy.what)
				lines.append("H " + Canon.of(res))
				steps += 1
				continue
			lines.append("W " + Canon.of(g.whisper(rnd() % vis.size())))
			if steps % 7 == 3:
				lines.append("M " + Canon.of(g.murmur("wait")))
			var pick := rnd() % vis.size()
			var considered := [rnd() % vis.size()]
			res = g.choose(pick, {"considered": considered})
			lines.append("C " + Canon.of(res))
			lines.append("T " + Canon.of(g.status()))
			steps += 1
		total += steps
		lines.append("END " + Canon.of({"steps": steps, "ended": res.ended, "errors": g.errors, "sketch": g.sketch, "tasks": g.tasks, "said": g.said}))
		FileAccess.open("%s/g_%d.txt" % [out_dir, night], FileAccess.WRITE).store_string("\n".join(lines) + "\n")
	print("%d nights, %d choices, %.1f s" % [to - from + 1, total, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()
