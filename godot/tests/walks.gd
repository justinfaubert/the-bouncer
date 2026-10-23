extends SceneTree
# Every walk he can take, from every place (and every way a place is seen) to every other, with the
# room as it is at the start of the night: the way world/nav.gd finds, walked out a sixtieth of a
# second at a time the way game/view.gd walks it. Each must get there; never through anything
# (every step of it somewhere a man can walk, but the step off a stool and the step onto one); never
# faster than he walks; the doors on it opened before he's at them; his head coming round no
# faster than a head does. Prints the longest walks, and the people he had to brush past.
#   godot --headless --path godot -s res://tests/walks.gd

var main
var bad := 0


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _wrong(what: String) -> void:
	print("  WRONG  " + what)
	bad += 1


func _run() -> void:
	await _frames(5)
	main.start_new(2)
	await _frames(10)
	# the room as it is when he gets there, at twenty to eight, not while he's in Gary's office at four
	main.game.set_var("clock", 1180)
	main.view.clock = 1180
	main.stage.sync(main.game, true)
	await _frames(10)
	var v: View = main.view
	var nav := Nav.new()
	var people: Array = main.stage.standing()
	print("%d people in the room" % people.size())
	var all: Array = []
	for p in Posts.POSTS:
		all.append(p)
	for f in Posts.FRAMES:
		all.append(f)
	var dt := 1.0 / 60.0
	var walks: Array = []
	var brushes := 0
	var plan_ms := 0.0
	var n := 0
	for a in all:
		for b in all:
			if a == b:
				continue
			var ap: String = str(a).get_slice(":", 0)
			var bp: String = str(b).get_slice(":", 0)
			v.frame = str(a).get_slice(":", 1) if ":" in str(a) else ""
			v.jump_to(ap)
			v.yaw = 0.0
			v.want_yaw = 0.0
			v.turned_t = -INF
			v.frame = str(b).get_slice(":", 1) if ":" in str(b) else ""
			var t0 := Time.get_ticks_usec()
			v.walk_to(bp)
			plan_ms += (Time.get_ticks_usec() - t0) / 1000.0
			n += 1
			var name := "%s -> %s" % [a, b]
			var time := 0.0
			var dist := 0.0
			var fastest := 0.0
			var turn_fastest := 0.0
			var last: Vector3 = v.eye_pos
			var last_yaw: float = v.yaw
			var through := ""
			var door_late := ""
			var opened := {}
			var path := PackedVector3Array()
			while v.walking and time < 90.0:
				if v._cut != null:
					v._cut.custom_step(5.0)
					last = v.eye_pos
					last_yaw = v.yaw
					continue
				if path != v._path:
					path = v._path
				v._process(dt)
				time += dt
				var step := Vector2(v.eye_pos.x - last.x, v.eye_pos.z - last.z).length()
				dist += step
				fastest = maxf(fastest, step / dt)
				turn_fastest = maxf(turn_fastest, absf(v.yaw - last_yaw) / dt)
				last = v.eye_pos
				last_yaw = v.yaw
				for d in v._doors:
					if int(d[2]) >= 1 and not opened.has(d[0]):
						opened[d[0]] = v._s
				# somewhere to walk, but near the ends of the stretch (a stool, a seat)
				if through == "" and not path.is_empty():
					var e := v.eye_pos
					var near_end: bool = Vector2(e.x - path[0].x, e.z - path[0].z).length() < 0.75 \
						or Vector2(e.x - path[path.size() - 1].x, e.z - path[path.size() - 1].z).length() < 0.75
					if not near_end and not nav.open(Nav.cell(e)):
						through = "(%.2f, %.2f) clearance %.2f" % [e.x, e.z, Nav.clearance(e)]
					if not near_end:
						for q in people:
							var pq: Vector3 = q
							if Vector2(e.x - pq.x, e.z - pq.z).length() < Nav.PERSON + Nav.BODY - 0.12 \
									and Vector2(pq.x - path[0].x, pq.z - path[0].z).length() > 0.9 \
									and Vector2(pq.x - path[path.size() - 1].x, pq.z - path[path.size() - 1].z).length() > 0.9:
								brushes += 1
								print("  brushes past someone at (%.2f, %.2f): %s" % [pq.x, pq.z, name])
								people.erase(q)
								break
				for d in v._doors:
					if int(d[2]) == 0 and v._s >= float(d[1]) - 0.2 and door_late == "":
						door_late = str(d[0])
			if v.walking:
				_wrong("%s: not there after %.0f s" % [name, time])
				v.jump_to(bp)
				continue
			var want: Vector3 = Posts.post(bp, v.frame).at
			if v.eye_pos.distance_to(want) > 0.02:
				_wrong("%s: ends at %s, not %s" % [name, v.eye_pos, want])
			if through != "":
				_wrong("%s: through something at %s" % [name, through])
			if fastest > View.PACE_FAR + 0.02:
				_wrong("%s: %.2f m/s at his fastest" % [name, fastest])
			if turn_fastest > View.TURN + 0.05:
				_wrong("%s: his head came round at %.2f rad/s" % [name, turn_fastest])
			if door_late != "":
				_wrong("%s: the %s door wasn't open when he got to it" % [name, door_late])
			walks.append([time, dist, name])
			people = main.stage.standing()
	walks.sort_custom(func(x, y): return x[0] > y[0])
	print("%d walks, %.1f ms each to find the way; the longest:" % [n, plan_ms / n])
	for w in walks.slice(0, 8):
		print("  %5.1f s  %5.1f m  %s" % [w[0], w[1], w[2]])
	print("from his stool:")
	for w in walks:
		if str(w[2]).begins_with("door -> "):
			print("  %5.1f s  %5.1f m  %s" % [w[0], w[1], w[2]])
	var tot := 0.0
	for w in walks:
		tot += float(w[0])
	print("average %.1f s; %d brushes past someone" % [tot / maxi(1, walks.size()), brushes])
	# two places in one stretch of the page: a stop at the first, standing, then on to the second
	for trip in [["door", "bar", "door"], ["floor", "door", "deck"], ["bar", "keg", "floor"], ["t28", "pool", "door"], ["lot", "kitchen", "floor"]]:
		v.frame = ""
		v.jump_to(trip[0])
		v.turned_t = -INF
		v.walk_to(trip[1])
		v.walk_to(trip[2], false, true)
		var time := 0.0
		var stopped := false
		var lowest := INF
		var first: Vector3 = Posts.post(trip[1]).at
		while v.walking and time < 120.0:
			if v._cut != null:
				v._cut.custom_step(5.0)
				continue
			v._process(dt)
			time += dt
			if v._wait > 0.0 and Vector2(v.eye_pos.x - first.x, v.eye_pos.z - first.z).length() < 0.05:
				stopped = true
				lowest = minf(lowest, v.eye_pos.y - first.y if not Posts.FLIGHTS.has(trip[1]) else 0.0)
		var name := " -> ".join(trip)
		if v.walking:
			_wrong("%s: not there after %.0f s" % [name, time])
			continue
		if v.eye_pos.distance_to(Posts.post(trip[2]).at) > 0.02:
			_wrong("%s: ends at %s" % [name, v.eye_pos])
		if not stopped:
			_wrong("%s: didn't stop at the %s on the way" % [name, trip[1]])
		elif lowest < -0.01 and Posts.post(trip[1]).get("seat", false):
			_wrong("%s: sat down at the %s on the way" % [name, trip[1]])
		print("  %5.1f s  %s" % [time, name])
	# where he stands, at every place and every way it's seen: nobody's spot under him (his own
	# stool at table 28 aside, and the two spots nobody's put at yet)
	var spots: Dictionary = main.stage.SPOTS
	var stood := {}
	for p in Posts.POSTS:
		stood[p] = Posts.POSTS[p].at
	for f in Posts.FRAMES:
		stood[f] = Posts.FRAMES[f].at
	for name in stood:
		var at: Vector3 = stood[name]
		var floor_y := Pub.KEG_Y if at.y < 0.0 else (Pub.UP_Y if at.y > Pub.UP_Y else 0.0)
		for id in spots:
			var sp: Dictionary = spots[id]
			if sp.has("in") or id in ["hall_phone", "deck_chair"] or (str(name).begins_with("t28") and id == "t28_4"):
				continue
			var q: Vector3 = sp.pos
			if absf(q.y - floor_y) > 0.5:
				continue
			var d := Vector2(q.x - at.x, q.z - at.z).length()
			if d < Nav.PERSON + Nav.BODY + 0.1:
				_wrong("at %s he'd be %.2f from whoever's at %s" % [name, d, id])
	print("== %s" % ("all right" if bad == 0 else "%d wrong" % bad))
	main.back_to_title()
	await _frames(2)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit(1 if bad > 0 else 0)
