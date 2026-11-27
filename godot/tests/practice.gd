extends SceneTree
# Practice (engine/practice.gd): earned by doing well and not by doing it over; capped a night; the
# same way again earns less; marks put a point on a stat (in turn, where it feeds two), never past 9,
# and give knacks; a stopped practice earns nothing; it saves and loads; and through the Game the
# stat and the knack land in the Ink.
#   godot --headless --path godot -s res://tests/practice.gd

var bad := 0


func _init() -> void:
	var p := Practice.new()
	p.new_night(1)
	var st := {"str": 6, "dex": 4}
	var evs: Array = []
	for i in 30:
		evs.append_array(p.earn("hands", 1.0, "jab", st))
	print("one jab over and over, a night: %.1f points" % p.points.hands)
	check(p.points.hands < 4.0, "the same blow over and over earns little")
	p.new_night(2)
	var kinds := ["jab", "cross", "hook", "upper", "body", "counter", "short"]
	for i in 40:
		evs.append_array(p.earn("hands", 1.2, kinds[i % kinds.size()], st))
	print("a varied night: %.1f points (cap %.0f)" % [p.points.hands, Practice.NIGHT_CAP])
	check(float(p.tonight.hands) <= Practice.NIGHT_CAP + 0.001, "a night is capped")
	for n in range(3, 12):
		p.new_night(n)
		for i in 40:
			evs.append_array(p.earn("hands", 1.2, kinds[i % kinds.size()], st))
	var stat_evs := evs.filter(func(e): return e.kind == "stat")
	var knack_evs := evs.filter(func(e): return e.kind == "knack")
	print("after eleven nights: %.0f points, marks %d, stats %s, knacks %s" % [p.points.hands, p.marks.hands, str(stat_evs.map(func(e): return "%s %d>%d" % [e.stat, e.from, e.to])), str(knack_evs.map(func(e): return e.id))])
	check(stat_evs.size() == 2 and stat_evs[0].stat == "str" and stat_evs[1].stat == "dex", "two marks put points on Strength then Dexterity")
	check(p.has("short_one") and p.has("heavy_hands"), "the second and fourth marks give the knacks")
	var q := Practice.new()
	var hi := {"con": 9}
	q.new_night(1)
	for n in 6:
		q.new_night(n + 1)
		for i in 20:
			q.earn("chin", 2.0, "t%d" % i, hi)
	check(int(hi.con) == 9, "never past 9 by practice")
	q.stop("chin", "broken jaw")
	var before := float(q.points.chin)
	q.new_night(20)
	q.earn("chin", 3.0, "x", hi)
	check(float(q.points.chin) == before, "a stopped practice earns nothing")
	var r := Practice.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check(r.has("short_one") and absf(float(r.points.hands) - float(p.points.hands)) < 0.001, "it saves and loads")
	var says := Practice.says({"practice": "hands", "words": "getting quick"})
	print("says: %s: %s" % says)
	_game()
	print("practice: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)


func _game() -> void:
	var txt := FileAccess.get_file_as_string("res://data/content.json")
	var content: Dictionary = JSON.parse_string(txt)
	var g := Game.new(content)
	g.new_game(5)
	var s0 := int(g.get_var("stat_str"))
	var got: Array = []
	for n in 3:
		g.set_var("day", n + 1)
		for i in 12:
			got.append_array(g.practise("hands", 1.5, "b%d" % i))
	print("through the game: strength %d > %d, knack_short_one %s" % [s0, int(g.get_var("stat_str")), str(g.get_var("knack_short_one"))])
	check(int(g.get_var("stat_str")) == s0 + 1, "the mark's point lands in the Ink")
	check(bool(g.get_var("knack_short_one")), "and so does the knack")
	check(g.serialize().has("practice"), "the night's save keeps it")


func check(ok: bool, what: String) -> void:
	if not ok:
		bad += 1
		print("  BAD: " + what)
