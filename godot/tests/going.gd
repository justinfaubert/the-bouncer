extends SceneTree
# Going where he looks (game/going.gd), the way a player does it: plays the night on from Gary's
# office (choices at random, seeded) until he's out on the bar's floor with nothing going on, then
# points at the floor and at the places on it (a click on the world's picture where that bit of
# floor is) and watches him go. He must get where he was pointed, or as near as a man can stand,
# and the night must go on from it the way it says: a minute for a walk across the room, nothing
# for a step or two, a place's own choice for the floor round a place, and from a place, the way
# back onto the floor. The ways he can go by aren't numbered in the column, only named, under GO
# WHERE HE LOOKS. Hurrying across the room, the
# room sees him run, and the bar has something to say about it. Off the floor's post, the dice tray
# goes down by his feet. The clock on the page runs up to the night's, not all at once.
#   godot --headless --path godot -s res://tests/going.gd -- --seed 3

var main
var v: View
var rs := 3
var bad := 0
var settled := 0
var errors := Errors.new()


# every script error on the way, counted: one's enough to fail the run
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


func _ok(what: String, cond: bool, extra := "") -> void:
	if cond:
		print("  ok     " + what)
	else:
		print("  WRONG  " + what + ("" if extra == "" else "  (" + extra + ")"))
		bad += 1


func _clock() -> int:
	return int(main.game.get_var("clock"))


# how far he is from p, on the floor
func _off(p: Vector3) -> float:
	return Vector2(v.eye_pos.x - p.x, v.eye_pos.z - p.z).length()


func _here() -> String:
	return "%s (%s), at (%.2f, %.2f), %s" % [v.place, main.game.here(), v.eye_pos.x, v.eye_pos.z, main.game.status().clockText]


# what's been said tonight, any of it this
func _said(bits: Array) -> bool:
	for it in main.game.night_log:
		for b in bits:
			if str(it.get("text", "")).contains(str(b)):
				return true
	return false


# how many times tonight a group has had something to say about him, this way
func _words(group: String, way: String) -> int:
	var n := 0
	for it in main.game.night_log:
		if str(it.get("kind", "")) == "word" and str(it.get("group", "")) == group and str(it.get("way", "")) == way:
			n += 1
	return n


func _has_label(n: Node, text: String) -> bool:
	if (n is Label or n is RichTextLabel) and str(n.get("text")).contains(text):
		return true
	for c in n.get_children():
		if _has_label(c, text):
			return true
	return false


# the night going on by itself till there's a choice to make: the pauses gone on from, the dice let
# fall, and him where he was going
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


# out on the floor with nothing going on, past twenty to eight: back onto it by its own way where
# there's one, anything at random otherwise
func _free_on_floor(limit := 400) -> bool:
	for n in limit:
		await _settle()
		if main.game.ended:
			return false
		if v.place == "floor" and main.going._free() and _clock() >= 1180:
			return true
		var list: Array = main.game.visible_choices()
		if list.is_empty():
			continue
		var pick := -1
		for i in list.size():
			if Hotspots.loc_of(list[i]) == "floor" and str(list[i].get("cls", "")) == "move":
				pick = i
		main.choose(pick if pick >= 0 else rnd() % list.size())
	return false


# a night started, and played on till he's out on the floor with nothing going on (a night that ends
# in Gary's office first, the doorman not hired, is started again)
func _a_night() -> bool:
	for attempt in 4:
		main.start_new(3)
		await _frames(3)
		if await _free_on_floor():
			return true
		print("  (the night ended before he got out onto the floor: again)")
	return false


# in a place, on with what there is to do there (never a way somewhere else) till the way back onto
# the floor is on offer; false if the night's taken him somewhere else first
func _till_the_floor_way(where: String, limit := 40) -> bool:
	for n in limit:
		await _settle()
		if main.game.ended or v.place != where:
			return false
		if main.going._way_to("floor") >= 0:
			return true
		var list: Array = main.game.visible_choices()
		var picks: Array = []
		for i in list.size():
			if not Going.is_way(list[i]):
				picks.append(i)
		if picks.is_empty():
			return false
		main.choose(picks[rnd() % picks.size()])
	return false


# bare floor in the bar between lo and hi off him: room to stand, nobody on it, none of the places'
# floor, his eyes able to come down on it from here, and nothing lit there under them
func _bare(lo: float, hi: float) -> Vector3:
	var people: Array = main.stage.standing()
	var me := Vector3(v.eye_pos.x, 0.0, v.eye_pos.z)
	for r in [lo, (lo + hi) / 2.0, hi]:
		for k in 24:
			var a := TAU * (k + 0.5) / 24.0
			var q: Vector3 = me + Vector3(cos(a), 0.0, sin(a)) * float(r)
			if Nav.clearance(q) < Nav.BODY + 0.1 or Hotspots.zone_of(q + Vector3(0, 0.05, 0)) != "room":
				continue
			if Posts.area_of(q, "room") != "floor":
				continue
			var crowded := false
			for pp in people:
				if Vector2((pp as Vector3).x - q.x, (pp as Vector3).z - q.z).length() < 0.9:
					crowded = true
			if crowded:
				continue
			await _point(q)
			await _frames(4)
			var got: Vector3 = main.going.floor_at()
			if got == Vector3.INF or got.distance_to(q) > 0.05 or main.spots.under != null:
				continue
			return q
	return Vector3.INF


# his eyes on p, and the pointer on it in the world's picture
func _point(p: Vector3) -> void:
	var a := Posts.aim(v.eye_pos, p)
	v.yaw = a.x
	v.want_yaw = a.x
	v.pitch = clampf(a.y, View.PITCH_MIN, View.PITCH_MAX)
	v.want_pitch = v.pitch
	await _frames(3)
	v.pointer = v.cam.unproject_position(p)


# a click there, the way the world's picture takes one with nothing lit under his eyes
func _click(p: Vector3) -> bool:
	await _point(p)
	await _frames(2)
	return main.going.click()


# from a place, a click on bare floor out in the room: the way back onto the floor, and he walks out
# to where it was. Tries a few times, the night being what it is.
func _out_from(where: String, by: Vector3, floor_pt: Vector3) -> void:
	for attempt in 3:
		if not await _free_on_floor():
			break
		var clicked: bool = await _click(by)
		await _settle()
		if not clicked or v.place != where:
			print("  (%s: the click by it took him to %s)" % [where, _here()])
			continue
		_ok("the floor round the %s is the night's way to it" % where, true)
		if where == "door":
			_ok("  and he sits on the stool", absf(v.eye_pos.y - Posts.POSTS["door"].at.y) < 0.02 and v.eye_pos.distance_to(Posts.POSTS["door"].at) < 0.02)
		if not await _till_the_floor_way(where):
			print("  (the night took him on from the %s before the floor was on offer: %s)" % [where, _here()])
			continue
		var spot: Vector3 = main.going._stand_near(floor_pt)
		var c0 := _clock()
		clicked = await _click(floor_pt)
		_ok("  from there, a click on the floor is the way back onto it", clicked, _here())
		if not clicked:
			return
		await _settle()
		if v.place != "floor":
			print("  (the night took him on from the floor to %s)" % _here())
			continue
		_ok("  and he walks out to where it was", _off(spot) < 0.15, "%.2f off, %s" % [_off(spot), _here()])
		print("  (%d minutes on the clock, that way back)" % (_clock() - c0))
		return
	_ok("got to the %s and back out by clicking the floor" % where, false, _here())


func _run() -> void:
	await _frames(5)
	main.settings["dice"] = "quick"
	v = main.view
	v.settled.connect(func(): settled += 1)
	if not await _a_night():
		_ok("out on the floor with nothing going on", false, _here())
		await _done()
		return
	print("on the floor: " + _here())

	print("== the column")
	var list: Array = main.game.visible_choices()
	var hid: Array = main.going.hidden(list)
	var numbered: Array = []
	var named := 0
	for r in main.column.rows:
		if r.index in hid:
			if r.key != 0:
				numbered.append(str(list[r.index].text))
			else:
				named += 1
	var names: Array = []
	for i in hid:
		names.append(str(list[i].text))
	print("  out of it: " + "; ".join(names))
	_ok("the ways round the room are out of the column's numbered choices", hid.size() >= 4, "%d of %d" % [hid.size(), list.size()])
	_ok("  none of them numbered", numbered.is_empty(), "; ".join(numbered))
	_ok("  and it says where they've gone", _has_label(main.column.choices_box, "WHERE HE LOOKS"))
	_ok("  naming each of them there, to click", named == hid.size(), "%d of %d" % [named, hid.size()])
	var keyed = main.column.row_for_key(1)
	_ok("  the keys go to what's numbered", keyed == null or not (keyed.index in hid))

	print("== across the room")
	var far: Vector3 = await _bare(3.2, 4.6)
	_ok("bare floor to point at, across the room", far != Vector3.INF, _here())
	if far != Vector3.INF:
		var c0 := _clock()
		var r0 := int(main.game.get_var("ran_room"))
		var clicked: bool = main.going.click()
		_ok("a click on it walks him there", clicked and v.walking)
		await _settle()
		_ok("  he gets there", _off(far) < 0.15, "%.2f off, %s" % [_off(far), _here()])
		_ok("  and a walk across the room is a minute", _clock() >= c0 + 1, "%d -> %d" % [c0, _clock()])
		_ok("  at a walk, nobody making anything of it", int(main.game.get_var("ran_room")) == r0)
		_ok("  and the page says nothing of it", not _has_label(main.column.story, "Walk across the room") and not main._transcript().contains("Walk across the room"))
		# the dice, here: the tray a step off him, clear of everything
		var fwd := -v.cam.global_transform.basis.z
		var tray: Dictionary = Dice.spot_for("floor", v.eye_pos, fwd, "", main.stage.standing())
		var tp: Vector3 = tray.tray
		var td := Vector2(tp.x - v.eye_pos.x, tp.z - v.eye_pos.z).length()
		_ok("  the dice tray would go down a step off him, clear", absf(td - 0.8) < 0.05 and Nav.clearance(tp) >= Dice.TRAY_R + 0.1,
			"%.2f off him, clearance %.2f" % [td, Nav.clearance(tp)])

	print("== a step or two")
	if await _free_on_floor():
		var near: Vector3 = await _bare(1.4, 2.1)
		if near != Vector3.INF:
			var c0 := _clock()
			var clicked: bool = main.going.click()
			await _settle()
			_ok("a step or two over", clicked and _off(near) < 0.15, "%.2f off" % _off(near))
			_ok("  costs nothing", _clock() == c0, "%d -> %d" % [c0, _clock()])
		else:
			_ok("bare floor a step or two off", false, _here())

	print("== E, with nothing under his eyes")
	if await _free_on_floor():
		var ahead: Vector3 = await _bare(2.4, 3.4)
		if ahead != Vector3.INF:
			v.pointer = Vector2(-1, -1)
			var went: bool = main.going.ahead()
			await _settle()
			_ok("walks him to the floor he's looking at", went and _off(ahead) < 0.3, "%.2f off" % _off(ahead))

	print("== running")
	if await _free_on_floor():
		var run_to: Vector3 = await _bare(4.0, 6.0)
		if run_to == Vector3.INF:
			run_to = await _bare(3.0, 4.0)
		if run_to != Vector3.INF:
			var r0 := int(main.game.get_var("ran_room"))
			main.going.click()
			await _frames(3)
			v.hurry()
			var turned := 0
			while v.walking:
				await process_frame
				for id in main.stage._turned:
					if (main.stage._turned[id] as Tween).is_valid() and (main.stage._turned[id] as Tween).is_running():
						turned = maxi(turned, 1)
			await _settle()
			_ok("hurrying across the room, the room sees him run", int(main.game.get_var("ran_room")) == r0 + 1,
				"ran_room %d -> %d" % [r0, int(main.game.get_var("ran_room"))])
			_ok("  heads come round", turned > 0)
			var voices: bool = main.game.psyche.is_seated("father")
			if voices:
				_ok("  and his father's in his ear about it", _said(["A doorman running tells the whole room"]))
			else:
				print("  (his father's not in his head tonight to say anything)")
			# at the bar, she's seen it
			if await _free_on_floor():
				var s0 := settled
				var w0 := _words("staff", "down")
				var clicked: bool = await _click(Vector3(2.95, 0.0, 4.3))
				await _settle()
				if v.place == "bar":
					_ok("a click on the floor by the bar takes him to it", clicked)
					_ok("  he leans there, his weight on it", settled > s0 and absf(v.eye_pos.y - Posts.LEAN_BAR) < 0.02,
						"settled %d, eye %.2f" % [settled - s0, v.eye_pos.y])
					_ok("  and she saw him run", int(main.game.get_var("ran_seen")) == int(main.game.get_var("ran_room")) and _said(["run on my floor"]))
					_ok("  and the word on him says so", _words("staff", "down") == w0 + 1, "%d -> %d" % [w0, _words("staff", "down")])
					# and from the bar, the floor by the page: a step or two off it, out into the room
					var can_go: bool = await _till_the_floor_way("bar")
					var back: int = main.going._way_to("floor") if can_go else -1
					if back >= 0:
						main.choose(back)
						await _settle()
						var bp: Vector3 = Posts.POSTS["bar"].at
						var d := _off(bp)
						_ok("back onto the floor from the bar: a step or two off it, out in the room", v.place == "floor" and d > 1.0 and d < 1.6
							and Hotspots.zone_of(v.eye_pos) == "room" and Nav.clearance(v.eye_pos) >= Nav.BODY + 0.1,
							"%.2f off the bar, %s" % [d, _here()])
				else:
					print("  (the click by the bar took him to %s)" % _here())

	print("== the places")
	await _out_from("t28", Vector3(8.2, 0.0, 7.4), Vector3(6.3, 0.0, 5.6))
	await _out_from("door", Vector3(2.45, 0.0, 8.35), Vector3(5.2, 0.0, 7.0))

	print("== the clock")
	await _free_on_floor()
	var now := _clock()
	main.clock_shown = now - 12
	main.refresh_status()
	_ok("a few minutes on, the clock on the page doesn't jump", main.clock_shown == now - 12)
	var t0 := Time.get_ticks_msec()
	var saw := {}
	while main.clock_shown < now and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
		saw[main.clock_shown] = true
	_ok("  it runs up to the night's, a minute at a time", main.clock_shown == now and saw.size() >= 12,
		"%d of %d, %d minutes seen" % [main.clock_shown, now, saw.size()])
	main.clock_shown = now - 120
	main.refresh_status()
	_ok("  a long way at once, it's there at once", main.clock_shown == now)
	await _done()


func _done() -> void:
	print("%d script errors" % errors.count)
	print("== %s" % ("all right" if bad == 0 and errors.count == 0 else "%d wrong" % (bad + errors.count)))
	main.back_to_title()
	await _frames(2)
	main.store.clear(3)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit(1 if bad > 0 or errors.count > 0 else 0)
