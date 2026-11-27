extends SceneTree
# The teaser: every shot of it rendered in the game itself, frame by frame, at 24 a second, each into
# its own folder of pictures, to be cut to the music by tools/trailer/cut.py. What's on screen is
# the game: its rooms, its people, its press and its night-stock film, the darts and the pool and
# the machine and the truck played by their own code; only the camera's been taken off his head
# and put on rails (trailer/director.gd).
#
# The cut (which shots, how many frames each) comes from tools/trailer/cut.py, which reads the
# track's beats (tools/trailer/analyze.py). Run under a display, with the clock fixed, so the
# game's time is the film's time however slowly the frames come:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver vulkan --resolution 1920x1080 \
#     --fixed-fps 24 --path godot -s res://trailer/trailer.gd -- --cut /tmp/trailer/cut.json \
#     --out /tmp/trailer/frames [--only darts_aim,pool_break] [--stills]
# --stills renders each shot at a quarter of the frames and keeps three pictures (first, middle,
# last), to frame things up quickly.

const FPS := 24.0
const Director := preload("res://trailer/director.gd")
const NIGHT := 1290          # half past nine
const LATE := 1395           # a quarter past eleven, the room full

var main
var dir
var out := "/tmp/trailer/frames"
var cut: Array = []
var only: Array = []
var stills := false
var _events: Array = []       # sounds to lay under the shot in the cut: [seconds into it, the game's sound, gain]
var _shot_name := ""
var _pre := 10               # frames run before a shot's first, for the light and the print to settle


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	var cut_path := ""
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--cut": cut_path = args[i + 1]; i += 1
			"--only": only = Array(args[i + 1].split(",", false)); i += 1
			"--stills": stills = true
		i += 1
	cut = JSON.parse_string(FileAccess.get_file_as_string(cut_path)).shots
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _run() -> void:
	await _frames(3)
	if main.intro.playing:
		main.intro.stop()
	main.settings["intro_seen"] = true
	main.settings["dice"] = "still"
	main.settings["look"] = "7"
	main.apply_settings()
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	dir = Director.new()
	dir.view = main.view
	root.add_child(dir)
	await _frames(5)
	# the order they render in: grouped by what's set up, not the order they're cut in
	var order := ["sov_far", "seawall_end", "listener_rise", "listener_push", "x_mirror",
		"bar_empty", "talk", "room_full", "room_frozen", "washer", "x_line_rain", "line_door",
		"hall_walk", "payphone_wall", "x_stall", "x_declined", "walk_lot", "door_in", "door_hand",
		"sign_dying", "darts_aim", "darts_fly", "x_dart_treble", "pool_break", "x_pool_pot",
		"pool_table", "cig_synth", "x_cig_pull", "fight_frozen", "x_fight_hit", "fight_live",
		"truck_road"]
	var frames := {}
	for c in cut:
		frames[str(c.name)] = int(c.frames)
	for name in order:
		if not frames.has(name):
			continue
		if not only.is_empty() and not name in only:
			continue
		if not has_method("_shot_" + name):
			print("trailer: no shot ", name)
			continue
		print("trailer: ", name, " ", frames[name], " frames")
		var t0 := Time.get_ticks_msec()
		await call("_shot_" + name, frames[name])
		print("trailer: ", name, " took ", (Time.get_ticks_msec() - t0) / 1000.0, " s")
	for name in frames:
		if not name in order and (only.is_empty() or name in only):
			print("trailer: not in the order: ", name)
	quit()


# ---------------------------------------------------------------- taking a shot

# The shot itself: the camera put on its rails, every frame stepped and kept. every(s) runs before
# each frame, for what happens in the shot (a dart thrown, a ball struck).
func _take(name: String, n: int, cam: Callable, every := Callable(), clean := true) -> void:
	var path := out.path_join(name)
	DirAccess.make_dir_recursive_absolute(path)
	dir.cam = cam
	dir.s = 0.0
	dir.clean = clean
	_events = []
	_shot_name = name
	for k in _pre:
		await process_frame
	var step := 4 if stills else 1
	if stills:
		Engine.time_scale = float(step)
	var keep := [0, n / 2, n - 1]
	var f := 0
	while f < n:
		var s := f / FPS
		dir.s = s
		if every.is_valid():
			every.call(s)
		await process_frame
		await RenderingServer.frame_post_draw
		var save := not stills
		if stills:
			for kk in keep:
				if kk >= f and kk < f + step:
					save = true
		if save:
			var img: Image = root.get_viewport().get_texture().get_image()
			img.save_jpg(path.path_join("%04d.jpg" % f), 0.94)
		f += step
	Engine.time_scale = 1.0
	dir.cam = Callable()
	dir.clean = false
	var fe := FileAccess.open(path.path_join("events.json"), FileAccess.WRITE)
	fe.store_string(JSON.stringify(_events))
	fe.close()


# A sound of the game's at this moment of the shot, for the cut to lay in (tools/trailer/cut.py).
func sfx(s: float, sound: String, gain := 1.0) -> void:
	_events.append([s, sound, gain])


# A night at the Sov at a clock, with whoever the day has there, and the picture the whole screen.
var _last_night := ""

func _night(clock: int, day := 1, knot := "", vars := {}) -> void:
	var key := "%d %d %s %s" % [clock, day, knot, str(vars)]
	if key == _last_night and main.game != null:
		_whole()
		return
	_last_night = key
	main.start_new(2)
	await _frames(12)
	if knot != "" or day != 1:
		main.reset_story()
		main.game.set_var("day", day)
		for k in vars:
			main.game.set_var(k, vars[k])
		if knot != "":
			main.game.jump(knot)
	main.game.set_var("clock", clock)
	_whole()
	main.stage.sync(main.game, true)
	main.stage._settle(0.0)
	main.view.daylight(clock, true)
	main.pub.set_clock(clock)
	await _frames(4)


func _whole() -> void:
	main.full_frame = true
	main.view.world_w = 1.0
	main.lay_out(1.0)
	main.menus.hide_all()
	if main.keys != null:
		main.keys.hide_card()
	main._bars_off()


func _at(place: String, clock: int) -> void:
	main.view.frame = ""
	main.view.jump_to(place)
	main.view.daylight(clock, true)
	main.pub.set_clock(clock)
	main.audio.place(place, clock)
	main.stage.sync(main.game, true)
	main.stage._settle(0.0)
	main._bars_off()


# ---------------------------------------------------------------- the camera's rails

static func smooth(k: float) -> float:
	k = clampf(k, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


# a camera on a dolly from a to b, looking from la to lb, the lens from f0 to f1, over secs;
# hand: how much a hand on it breathes
func rail(a: Vector3, b: Vector3, la: Vector3, lb: Vector3, f0: float, f1: float, secs: float, hand := 0.0, roll := 0.0) -> Callable:
	return func(s: float) -> Dictionary:
		var k := smooth(s / secs) * 0.7 + clampf(s / secs, 0.0, 1.0) * 0.3
		var w := Vector3(sin(s * 1.3) * 0.6 + sin(s * 3.1 + 1.0) * 0.25, sin(s * 1.7 + 2.0) * 0.5 + sin(s * 4.3) * 0.2, sin(s * 0.9) * 0.3) * hand * 0.02
		return {"at": a.lerp(b, k) + w, "look": la.lerp(lb, k) + w * 1.6, "fov": lerpf(f0, f1, k), "roll": roll * (1.0 - k * 0.5)}


func hold(at: Vector3, look: Vector3, fov: float, hand := 0.0) -> Callable:
	return rail(at, at, look, look, fov, fov, 1.0, hand)


# ---------------------------------------------------------------- the shots

# The Sov across the highway from the seawall, at night in the rain: the sign, the lot's lamp; the
# camera creeping in over the water's edge.
func _shot_sov_far(n: int) -> void:
	await _night(LATE)
	_at("seawall", LATE)
	var secs := n / FPS
	await _take("sov_far", n, rail(Vector3(10.5, 1.0, 38.5), Vector3(9.6, 1.15, 37.0),
		Vector3(6.2, 4.2, 10.0), Vector3(6.0, 4.4, 10.0), 36.0, 31.0, secs, 0.3))


# The empty bar before the doors: along the bar top toward the back bar and Jim, the bulbs over it.
func _shot_bar_empty(n: int) -> void:
	await _night(1180)
	_at("bar", 1180)
	var secs := n / FPS
	await _take("bar_empty", n, rail(Vector3(3.35, 1.75, 7.7), Vector3(3.3, 1.7, 5.9),
		Vector3(1.2, 1.25, 1.8), Vector3(1.0, 1.35, 2.6), 52.0, 46.0, secs, 0.2))


# The front door from the stool beside it, the kid's shape in the glass.
func _shot_door_in(n: int) -> void:
	await _night(1190, 1, "door_hoodie")
	_at("door", 1190)
	var secs := n / FPS
	await _take("door_in", n, rail(Vector3(1.55, 1.5, 8.4), Vector3(1.8, 1.48, 8.95),
		Vector3(3.3, 1.35, 10.2), Vector3(3.2, 1.45, 10.2), 46.0, 36.0, secs, 0.4))


# The door played: the page beside the picture, his hand on the kid's verdict, the game as it is.
func _shot_door_hand(n: int) -> void:
	_last_night = ""
	main.start_new(2)
	await _frames(12)
	main.reset_story()
	var res: Dictionary = main.game.jump("door_hoodie")
	main.game.set_var("clock", 1190)
	main.view.frame = main._frame_for(main.game.here())
	main.view.jump_to("door")
	main.stage.sync(main.game, true)
	main.show(res, true)
	for k in 30:
		if main.pending == null:
			break
		main._go_on()
		await _frames(4)
	await _frames(20)
	var st := {"done": false}
	var every := func(s: float):
		# partway, he takes the phone and looks at the photo
		if s > 2.0 and not st.done:
			st.done = true
			if not main.game.visible_choices().is_empty():
				main.choose(0)
				sfx(s, "pocket", 0.6)
	await _take("door_hand", n, Callable(), every, false)


# The room at a quarter past eleven, full: a crane over the floor from the door end.
func _shot_room_full(n: int) -> void:
	await _night(LATE, 3)
	_at("floor", LATE)
	var secs := n / FPS
	await _take("room_full", n, rail(Vector3(4.0, 1.8, 9.3), Vector3(6.0, 1.75, 8.9),
		Vector3(10.0, 1.1, 3.0), Vector3(11.5, 1.15, 3.6), 56.0, 50.0, secs, 0.3))


# Talk, as it's played: the night's first page, Gary's office, the picture and the page beside it,
# the lines coming in as the player clicks on.
func _shot_talk(n: int) -> void:
	_last_night = ""
	main.start_new(2)
	await _frames(30)
	var st := {"next": 0.9}
	var every := func(s: float):
		if s >= st.next:
			st.next += 1.1
			if main.pending != null:
				main._go_on()
				sfx(s, "page", 0.5)
	await _take("talk", n, Callable(), every, false)


# The room stopped dead: nobody moves, the smoke hangs, and the camera goes on through them.
func _shot_room_frozen(n: int) -> void:
	await _night(LATE, 3)
	_at("floor", LATE)
	await _frames(20)
	main.stage.set_process(false)
	var secs := n / FPS
	await _take("room_frozen", n, rail(Vector3(12.8, 1.55, 8.9), Vector3(6.0, 1.5, 6.6),
		Vector3(9.0, 1.3, 5.0), Vector3(2.0, 1.4, 4.0), 48.0, 44.0, secs, 0.0, 0.03))
	main.stage.set_process(true)


# The glasswasher running behind the bar.
func _shot_washer(n: int) -> void:
	await _night(NIGHT)
	_at("bar", NIGHT)
	if main.pub.dressing != null:
		main.pub.dressing.washer.set_on(true)
	var secs := n / FPS
	await _take("washer", n, rail(Vector3(1.1, 1.3, 8.2), Vector3(0.95, 1.22, 7.95),
		Vector3(0.3, 1.0, 6.9), Vector3(0.3, 1.0, 7.0), 46.0, 40.0, secs, 0.2))


# Friday's line at the door in the rain, from the stool, fast.
func _shot_x_line_rain(n: int) -> void:
	await _night(1300, 3, "the_line", {"in_line": 8})
	_at("lot", 1300)
	var secs := n / FPS
	await _take("x_line_rain", n, rail(Vector3(6.6, 1.25, 11.4), Vector3(6.2, 1.3, 11.2),
		Vector3(3.2, 1.6, 10.7), Vector3(3.2, 1.65, 10.7), 30.0, 26.0, secs, 0.6))


# Friday's line from the lot: the Sov's front, the queue under the sign, rain in the lamp.
func _shot_line_door(n: int) -> void:
	await _night(1300, 3, "the_line", {"in_line": 8})
	_at("lot", 1300)
	var secs := n / FPS
	await _take("line_door", n, rail(Vector3(11.0, 1.6, 19.5), Vector3(8.5, 1.7, 17.0),
		Vector3(3.6, 1.6, 10.4), Vector3(3.4, 1.8, 10.4), 42.0, 36.0, secs, 0.3))


# Down the back hall, under the tubes, past the scrawl.
func _shot_hall_walk(n: int) -> void:
	await _night(NIGHT)
	_at("hall", NIGHT)
	var secs := n / FPS
	await _take("hall_walk", n, rail(Vector3(6.6, 1.62, -0.58), Vector3(11.0, 1.62, -0.6),
		Vector3(15.0, 1.45, -0.7), Vector3(16.0, 1.4, -0.75), 58.0, 54.0, secs, 1.4))


# The payphone wall: a message from the Prime Minister, in red marker.
func _shot_payphone_wall(n: int) -> void:
	await _night(NIGHT)
	_at("hall", NIGHT)
	var p: Dictionary = main.intro.PLATES[1]
	var secs := n / FPS
	await _take("payphone_wall", n, rail(p.at + Vector3(-0.3, 0.05, 0.3), p.at + Vector3(0.05, 0.0, -0.1), p.look + Vector3(-0.15, 0, 0), p.look + Vector3(0, -0.1, 0), 42.0, 32.0, secs, 0.3))


# The women's stall door: the list, and at the bottom, fresh, the question about him.
func _shot_x_stall(n: int) -> void:
	await _night(NIGHT)
	_at("hall", NIGHT)
	var p: Dictionary = main.intro.PLATES[4]
	main.intro._wall("stall", p)
	await _frames(84)
	var secs := n / FPS
	var sp: Vector3 = p.spot
	await _take("x_stall", n, rail(p.at, p.at + Vector3(0.1, -0.05, -0.25), sp + Vector3(0, -0.22, 0), sp + Vector3(0, -0.32, 0), 30.0, 21.0, secs, 0.5))
	main.intro._free_labels()


# The card machine on the bar, its screen saying what it says two nights a week.
func _shot_x_declined(n: int) -> void:
	await _night(NIGHT)
	_at("bar", NIGHT)
	var p: Dictionary = main.intro.PLATES[2]
	main.intro._card_machine()
	var secs := n / FPS
	await _take("x_declined", n, rail(p.at + Vector3(0.12, 0.06, 0.1), p.at, p.look, p.look, 30.0, 24.0, secs, 0.4))
	if main.intro._machine != null:
		main.intro._machine.queue_free()
		main.intro._machine = null


# Out the front and across the lot toward the highway and the water, on his own feet.
func _shot_walk_lot(n: int) -> void:
	await _night(LATE)
	_at("lot", LATE)
	_rig_up()
	_rig.put(main.intro.SPHERE_AT, main.intro.SPHERE_R)
	_rig.hear = 0.3
	var secs := n / FPS
	var walk := func(s: float) -> Dictionary:
		var k := clampf(s / secs, 0.0, 1.0)
		var at := Vector3(3.3, 1.66, 11.0).lerp(Vector3(6.5, 1.66, 22.0), k)
		var ph := s * 1.9 * PI
		at.y += (absf(sin(ph)) - 0.64) * 0.03
		at.x += sin(ph) * 0.02
		return {"at": at, "look": at + Vector3(0.25, -0.08, 1.0) + Vector3(sin(s * 0.7) * 0.15, 0, 0), "fov": 62.0, "roll": sin(ph) * 0.006}
	await _take("walk_lot", n, walk, func(s: float): _rig.step(1.0 / FPS))
	_rig_down()


# The sign on the roof from the lot, in the rain, its letters going.
func _shot_sign_dying(n: int) -> void:
	await _night(LATE)
	_at("lot", LATE)
	var secs := n / FPS
	await _take("sign_dying", n, rail(Vector3(9.4, 1.3, 23.0), Vector3(8.7, 1.45, 21.0),
		Vector3(7.0, 7.5, 10.4), Vector3(7.4, 9.6, 10.4), 40.0, 30.0, secs, 0.3))


# ---------------------------------------------------------------- the Listener

var _rig: ListenerRig

func _rig_up() -> void:
	if _rig == null:
		_rig = ListenerRig.new()
		main.pub.add_child(_rig)
		_rig.build(main.view.eye.find_world_3d(), main.view.env, main.view.cam, main.view.mcam)


func _rig_down() -> void:
	if _rig != null:
		_rig.done()
		_rig = null


# It comes up out of the strait: the water, nothing on it, and then it.
func _shot_listener_rise(n: int) -> void:
	await _night(LATE)
	_at("seawall", LATE)
	_rig_up()
	var c: Vector3 = main.intro.SPHERE_AT
	var r: float = main.intro.SPHERE_R
	var secs := n / FPS
	var eye: Vector3 = main.intro.SEAWALL_EYE
	var every := func(s: float):
		var k := clampf((s - 0.3) / (secs * 0.85), 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		var y := lerpf(ListenerRig.WATER_Y - r - 0.3, c.y, e)
		_rig.put(Vector3(c.x, y, c.z), r)
		_rig.rings(maxf(s - 0.5, 0.0), clampf((y + r - ListenerRig.WATER_Y) * 2.0, 0.0, 1.0))
		_rig.step(1.0 / FPS)
	await _take("listener_rise", n, rail(eye + Vector3(0, -0.3, 0), eye + Vector3(0, -0.2, 1.2),
		c + Vector3(-0.4, -1.5, 0), c + Vector3(-0.4, 0.4, 0), 50.0, 44.0, secs, 0.2), every)
	_rig_down()


# Into it: it listens, the tiles packing in, and the room at its heart grows to fill it.
func _shot_listener_push(n: int) -> void:
	await _night(LATE)
	_at("seawall", LATE)
	_rig_up()
	var c: Vector3 = main.intro.SPHERE_AT
	var r: float = main.intro.SPHERE_R
	_rig.put(c, r)
	var secs := n / FPS
	var eye: Vector3 = main.intro.SEAWALL_EYE
	var every := func(s: float):
		var k := smooth(s / secs)
		_rig.hear = lerpf(1.0, 0.15, smoothstep(0.3, 0.8, k))
		_rig.grow(lerpf(0.14, 1.0, smoothstep(0.15, 0.9, k)))
		_rig.step(1.0 / FPS)
	var cam := func(s: float) -> Dictionary:
		var k := smooth(s / secs)
		return {"at": eye + Vector3(0, -0.1, 1.2), "look": c + Vector3(0, -0.15 * k, 0), "fov": lerpf(48.0, 14.0, k * k)}
	await _take("listener_push", n, cam, every)
	_rig_down()


# The small one: the orb on the bar, the room in it, a record going round.
func _shot_x_mirror(n: int) -> void:
	await _night(LATE)
	_at("seawall", LATE)
	_rig_up()
	var c: Vector3 = main.intro.SPHERE_AT
	var r: float = main.intro.SPHERE_R
	_rig.put(c, r)
	_rig.hear = 1.0
	var every := func(s: float):
		_rig.step(1.0 / FPS)
	var secs := n / FPS
	await _take("x_mirror", n, rail(c + Vector3(-1.5, 0.3, -13.0), c + Vector3(-1.2, 0.3, -12.0),
		c, c, 30.0, 28.0, secs, 0.1), every)
	_rig_down()


# The last of it: on the seawall behind him, the Sov across the road, the thing in the water over
# his shoulder, hanging there; back and up and away.
func _shot_seawall_end(n: int) -> void:
	await _night(LATE)
	_at("seawall", LATE)
	_rig_up()
	var c: Vector3 = main.intro.SPHERE_AT
	var r: float = main.intro.SPHERE_R
	_rig.put(Vector3(1.0, 3.0, 50.0), r)
	_rig.hear = 0.4
	var every := func(s: float):
		_rig.step(1.0 / FPS)
	var secs := n / FPS
	await _take("seawall_end", n, rail(Vector3(12.0, 1.0, 60.0), Vector3(13.0, 2.6, 64.0),
		Vector3(6.0, 3.5, 10.0), Vector3(6.0, 3.8, 10.0), 44.0, 48.0, secs, 0.15), every)
	_rig_down()


# ---------------------------------------------------------------- the games

func _body() -> Dictionary:
	return {"drinks": 1, "hurt": 0, "tension": 0, "clock": NIGHT, "cold": 0.0}


# At the line: the dart drawn back, and thrown.
func _shot_darts_aim(n: int) -> void:
	_last_night = ""
	main.menus.rehearse("title")
	await _frames(4)
	main.start_darts("501", "rehearse", _body())
	await _frames(40)
	_whole()
	var d = main.darts
	d.shake_off = true
	var tgt: Vector3 = d.to_world * Vector3(0.0, 0.103, 0.0)
	var a := Posts.aim(main.view.eye_pos, tgt)
	d.aim_yaw = a.x
	d.aim_pitch = a.y
	d.fov_hold = 38.0
	var st := {"thrown": false}
	var every := func(s: float):
		d.drawing = s > 0.25 and s < 1.0
		if s > 0.25 and s < 1.0:
			d.draw = clampf((s - 0.25) / 0.6, 0.0, 0.55)
		if s >= 1.0 and not st.thrown:
			st.thrown = true
			d.draw = 0.52
			d._throw()
			sfx(s, "dart_throw", 0.8)
	await _take("darts_aim", n, Callable(), every)
	d.fov_hold = 0.0
	await _frames(30)


# By the board: the dart coming at it, in, and the shaft shaking.
func _shot_darts_fly(n: int) -> void:
	var d = main.darts
	if d == null or not d.active:
		return
	d._collect(true)
	await _frames(10)
	var tgt: Vector3 = d.to_world * Vector3(0.0, 0.103, 0.0)
	var a := Posts.aim(main.view.eye_pos, tgt)
	d.aim_yaw = a.x
	d.aim_pitch = a.y
	d.next = 1
	var face: Vector3 = d.to_world * Vector3(0, 0, 0)
	var out_dir: Vector3 = (d.to_world.basis * Vector3(0, 0, 1)).normalized()
	var side: Vector3 = out_dir.cross(Vector3.UP).normalized()
	var st := {"thrown": false, "fly": false}
	var every := func(s: float):
		if st.fly and not d.flying:
			sfx(s, "dart_sisal", 1.0)
		st.fly = d.flying
		if s >= 0.05 and not st.thrown:
			st.thrown = true
			d.draw = 0.5
			d._throw()
	var secs := n / FPS
	var cam := func(s: float) -> Dictionary:
		var at: Vector3 = face + out_dir * 0.55 + side * 0.32 + Vector3(0, 0.02, 0)
		var look: Vector3 = face + Vector3(0, 0.08, 0) + out_dir * lerpf(0.9, 0.05, smooth(s / 0.7))
		return {"at": at, "look": look, "fov": lerpf(40.0, 30.0, smooth(s / secs))}
	await _take("darts_fly", n, cam, every)
	await _frames(20)


# The board close on the dart that just went in, the next one coming in beside it.
func _shot_x_dart_treble(n: int) -> void:
	var d = main.darts
	if d == null or not d.active:
		return
	var face: Vector3 = d.to_world * Vector3(0, 0, 0)
	var stuck: Vector3 = (d.nodes[1] as Node3D).global_position if d.nodes.size() > 1 else face
	var out_dir: Vector3 = (d.to_world.basis * Vector3(0, 0, 1)).normalized()
	var side: Vector3 = out_dir.cross(Vector3.UP).normalized()
	d.next = 2
	var st := {"thrown": false, "fly": false}
	var every := func(s: float):
		if st.fly and not d.flying:
			sfx(s, "dart_sisal_2", 1.0)
		st.fly = d.flying
		if not st.thrown:
			st.thrown = true
			d.draw = 0.5
			d._throw()
	var secs := n / FPS
	var look: Vector3 = stuck.lerp(face, 0.35)
	await _take("x_dart_treble", n, rail(look + out_dir * 0.42 - side * 0.2 + Vector3(0, 0.05, 0), look + out_dir * 0.36 - side * 0.16 + Vector3(0, 0.04, 0),
		look, look, 34.0, 30.0, secs, 0.2), every)
	d.end()
	await _frames(10)


func _pool_start() -> Variant:
	_last_night = ""
	main.menus.rehearse("title")
	await _frames(4)
	main.start_pool("8bar", "buddy", "rehearse", {"body": _body(), "seed": 11})
	await _frames(40)
	_whole()
	var p = main.pool
	p.shake_off = true
	return p


# Down on the break, at the cloth: the cue goes through and the rack goes everywhere.
func _shot_pool_break(n: int) -> void:
	var p = await _pool_start()
	var cb: PoolSim.Ball = p.sim.ball(0)
	cb.p = Vector3(p.sim.table.head_spot().x, cb.r, 0.08)
	cb.state = PoolSim.STILL
	p.tbl.put_ball(0, cb.r, cb.p, true)
	p.rules.in_hand_placed = "kitchen"
	p.rules.in_hand = ""
	p.phase = "aim"
	p.overview = false
	var to: Vector3 = p.sim.table.foot_spot() - cb.p
	p.aim_yaw = atan2(-to.z, to.x)
	p.stance = 0.05
	await _frames(40)
	var st := {"hit": false}
	var every := func(s: float):
		p.drawing = s > 0.05 and s < 0.5
		if p.drawing:
			p.draw = clampf((s - 0.05) / 0.4, 0.0, 0.85)
		if s >= 0.5 and not st.hit:
			st.hit = true
			p.drawing = false
			p.draw = 0.85
			p._stroke()
			sfx(s, "pool_break", 1.0)
	await _take("pool_break", n, Callable(), every)


# A ball going down, close at the pocket.
func _shot_x_pool_pot(n: int) -> void:
	var p = main.pool
	if p == null or not p.active:
		p = await _pool_start()
	await _wait_still(p)
	var helper := PoolAI.new("cook", 3)
	if p.phase == "place" or p.phase == "theirs":
		p.phase = "aim"
	var plan: Dictionary = helper.plan(p.sim, p.rules)
	p.aim_yaw = atan2(-plan.dir.z, plan.dir.x)
	p.tip = Vector2(plan.a, plan.b)
	p.elev = rad_to_deg(plan.elev)
	p.stance = 0.1
	await _frames(30)
	var st := {"hit": false}
	var every := func(s: float):
		if not st.hit:
			st.hit = true
			p.draw = pow(clampf((float(plan.speed) - Pool.SPEED_LO) / (Pool.SPEED_HI - Pool.SPEED_LO), 0.0, 1.0), 1.0 / 1.5)
			p._stroke()
			sfx(s, "pool_cue", 0.9)
	await _take("x_pool_pot", n, Callable(), every)


# The table from above and round it, the other man stood over a shot.
func _shot_pool_table(n: int) -> void:
	var p = main.pool
	if p == null or not p.active:
		p = await _pool_start()
	await _wait_still(p)
	var c: Vector3 = Pub.POOL + Vector3(0, 0.8, 0)
	var secs := n / FPS
	var cam := func(s: float) -> Dictionary:
		var k := smooth(s / secs)
		var ang := lerpf(-0.6, 0.4, k)
		return {"at": c + Vector3(cos(ang) * 2.4, 1.9 - 0.4 * k, sin(ang) * 2.4), "look": c + Vector3(0, -0.1, 0), "fov": 42.0}
	await _take("pool_table", n, cam)
	p.end()
	await _frames(10)


func _wait_still(p) -> void:
	for k in 4000:
		if p.phase != "rolling":
			break
		if k > 3:
			p._speed_k = 40.0
		await process_frame
	p._speed_k = 1.0
	await _frames(5)


# The cigarette machine, its lamp on, a chord held and its windows lit.
func _shot_cig_synth(n: int) -> void:
	_last_night = ""
	main.start_cig("rehearse", _body())
	await _frames(60)
	_whole()
	var c = main.cig
	c._coin()
	c._press("lamp", false)
	var st := {"k": -1}
	var chords := [[0, 4, 7], [2, 5, 9], [0, 3, 7, 10]]
	var every := func(s: float):
		var k := int(s / 0.6) % chords.size()
		if k != st.k:
			st.k = k
			c.by_key.clear()
			for nn in chords[k]:
				c.by_key[nn] = 0.7
	var at: Vector3 = CigMachine.AT
	var secs := n / FPS
	await _take("cig_synth", n, rail(at + Vector3(-1.1, 1.3, 0.55), at + Vector3(-0.75, 1.25, 0.3),
		at + Vector3(0, 1.05, 0), at + Vector3(0, 1.1, 0), 46.0, 38.0, secs, 0.3), every)
	c.by_key.clear()


# A pack pulled out of the drawer.
func _shot_x_cig_pull(n: int) -> void:
	var c = main.cig
	if c == null or not c.active:
		return
	c.dollars = 0
	c.dimes = 5
	c._apply_price()
	c._coin()
	c._coin()
	var every := func(s: float):
		c.grabbed = 6 if s < 0.6 else -1
		c.pull[6] = clampf(s / 0.5, 0.0, 1.0)
	await _take("x_cig_pull", n, Callable(), every)
	c.end()
	await _frames(20)


# The fish plant, Ox at the line, the frozen second: the room stopped, the card of what he can do.
func _shot_fight_frozen(n: int) -> void:
	_last_night = ""
	main.start_fight("ox", "rehearse", {"drinks": 0, "hurt": 0, "tension": 0, "clock": NIGHT})
	var t0 := Time.get_ticks_msec()
	while not main.cards.seconds.visible and Time.get_ticks_msec() - t0 < 30000:
		await process_frame
	await _frames(6)
	await _take("fight_frozen", n, Callable())


# A straight to the jaw, held.
func _shot_x_fight_hit(n: int) -> void:
	var s = main.cards.seconds
	if s.visible:
		for i in s.choices.size():
			if s.choices[i].id == "toe":
				s._choose(i)
				break
	await _frames(30)
	var f = main.fight
	if f == null:
		return
	var sim: FightSim = f.sim
	sim.a.pos = sim.b.pos + (sim.a.pos - sim.b.pos).normalized() * 0.85
	var st := {"hit": false}
	var every := func(t: float):
		if t > 0.1 and not st.hit:
			st.hit = true
			sim.strike(sim.a, "R", "straight", Vector2(0.0, sim.b.head_y() - 0.06), 1.0)
			sfx(t + 0.2, "punch", 1.0)
	await _take("x_fight_hit", n, Callable(), every)


# The fight going on, live.
func _shot_fight_live(n: int) -> void:
	var f = main.fight
	if f == null:
		return
	var sim: FightSim = f.sim
	var st := {"n": 0}
	var every := func(t: float):
		var k := int(t / 0.8)
		if k > st.n:
			st.n = k
			if k % 2 == 1:
				sim.strike(sim.b, "R", "hook", Vector2(0.1, sim.a.head_y()), 1.0)
			else:
				sim.strike(sim.a, "L", "straight", Vector2(0.0, sim.b.head_y() - 0.06), 1.0)
	await _take("fight_live", n, Callable(), every)
	main.cards._quit = true
	await _frames(30)


# The truck on the island road at night, its lights on the wet, from behind and alongside.
func _shot_truck_road(n: int) -> void:
	_last_night = ""
	main.start_truck("rehearse", _body())
	await _frames(20)
	_whole()
	var tr: Truck = main.truck
	tr._key()
	await _frames(30)
	tr.lights = 1
	tr._lights()
	var a: Array = tr.road.at_dist(900.0)
	var p: Vector3 = a[0]
	var fd: Vector3 = a[1]
	var side := Vector3(-fd.z, 0.0, fd.x)
	tr.sim.place(p + side * 1.9, atan2(-fd.x, -fd.z))
	tr.sim.vel = fd * 18.0
	for i in 4:
		tr.sim.omega[i] = 18.0 / TruckSim.RADIUS
	tr.sim.rpm = 1700.0
	tr.sim.gear = "3"
	tr.sim.running = true
	tr.sound.running = true
	tr.sim.selector = "D"
	tr._sel = 3
	tr.sim.throttle = 0.35
	main.view.ride = null
	await _frames(10)
	var secs := n / FPS
	var cam := func(s: float) -> Dictionary:
		var k := smooth(s / secs)
		var b: Node3D = tr.body
		var bt := b.global_transform
		var off := Vector3(lerpf(4.0, 2.6, k), lerpf(1.2, 1.6, k), lerpf(-4.5, 2.5, k))
		return {"at": bt * off, "look": bt * Vector3(0, 0.9, lerpf(0.0, -3.0, k)), "fov": 46.0}
	await _take("truck_road", n, cam)
	if tr.has_method("end"):
		tr.end()
	await _frames(10)
