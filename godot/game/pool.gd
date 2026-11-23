# Pool, at the coin-op by the back wall (game/pool_sim.gd is the physics, game/pool_rules.gd the
# rules, game/pool_ai.gd the man across the table, game/pool_table.gd the table, game/pool_ui.gd
# what's on the glass). No meter and no bar to stop on a mark: the same hands make the same stroke
# every time, and what gets between the player and the pocket is his eye, his body, and four house
# cues.
#
# The stroke, each part the player's:
#   aim     the mouse, side to side, turns the cue round the cue ball (Shift for the fine work). Up
#           and down, his head: down low on the line, where it's easiest to see, or up to look at the
#           table.
#   english hold the right button and move the mouse: the tip moves on the cue ball's face. High
#           follows, low draws, the sides spin it, and too far off the middle, on a dry tip, it slips.
#   butt    the wheel lifts the butt: a little to get over a ball or the rail, a lot to curve it
#           (swerve, masse) or to drive it down into the slate and jump it.
#   stroke  hold the left button and pull back: the cue comes back off the bridge, and how far is how
#           hard. Let go and it goes through. Drift sideways in the pull and the cue goes through off
#           its line by as much.
#   chalk   C. The tip goes dry over a few shots, and a dry tip miscues.
#   cue     Q and E: the four house cues in the rack, each its own.
#   look    Tab stands him up over the table; in hand, the mouse puts the cue ball down. F calls the
#           pocket for the eight (the one the ball's lined up on). Esc puts the cue down.
#
# What pushes back is all physical: his hand's shake in the tip as he holds it (the drink, the hour,
# a hurt hand, the nerves); the cues (one warped, one with its tip mushroomed, one heavy, one sound);
# the chalk; the Sov's table (its lean, its burns, its dead rails, the big bar cue ball); the man
# across the table.
class_name Pool
extends Node

const AIM_K := 0.0011
const FINE := 0.18
const TIP_K := 0.0035
const DRAW_PX := 340.0
const ELEV_MIN := 2.0
const ELEV_MAX := 82.0
const SPEED_LO := 0.3
const SPEED_HI := 8.2

# the house cues, in the rack on the wall
const CUES := [
	{"id": "sound", "name": "The sound one", "note": "Nineteen ounces, a straight shaft, the tip shaped and new. Somebody looks after this one.", "M": 0.54, "end": 0.0072, "e": 0.75, "limit": 0.56, "warp": 0.0, "colour": "6b3b22"},
	{"id": "warped", "name": "The warped one", "note": "Rolled on the cloth, it wobbles like a bad wheel. It goes through off line, a little, never the same way twice.", "M": 0.53, "end": 0.0078, "e": 0.74, "limit": 0.55, "warp": 0.0035, "colour": "4a2e1e"},
	{"id": "mushroom", "name": "The one with the mushroomed tip", "note": "The leather's spread over the ferrule like a mushroom cap. It holds the ball badly off the middle.", "M": 0.55, "end": 0.0074, "e": 0.68, "limit": 0.43, "warp": 0.0, "colour": "2e2a26"},
	{"id": "heavy", "name": "The heavy one", "note": "Twenty-one ounces, a weight screwed into the butt. Goes through the ball like a door, and doesn't want to stop.", "M": 0.6, "end": 0.0076, "e": 0.75, "limit": 0.55, "warp": 0.0, "colour": "5a1f1a"},
]

signal left(result: Dictionary)

var main
var pub
var view
var tbl: PoolTable
var sim: PoolSim
var rules: PoolRules
var ai: PoolAI
var ui
var rng := RandomNumberGenerator.new()
var to_world := Transform3D()
var active := false
var rehearsal := false
var body := {}
var mode := "8bar"                      # 8bar, 8league, 9ball, practice
var who := "buddy"                      # the man across the table, or "" for nobody
var names := ["You", "Them"]
var stakes := 0                         # dollars on the rail
var story := ""                         # "", "bigman_win", "bigman_lose" (what the night put him at the table to do)
var phase := "aim"                      # aim, place, rolling, theirs, over
var cue_i := 0
var chalk := 1.0
var aim_yaw := 0.0                      # the cue's way, about the vertical (0 along +x)
var stance := 0.15                      # 0 down on the line, 1 stood up
var tip := Vector2.ZERO                 # on the ball's face: x across, y up, parts of its radius
var elev := 4.0                         # degrees
var drawing := false
var draw := 0.0
var wrist := 0.0
var tipping := false
var overview := false
var t := 0.0
var shake_off := false
var _ph := [0.0, 0.0, 0.0, 0.0]
var _play_t := 0.0
var _speed_k := 1.0
var _heard := 0
var _start := {}                        # what the rules need from before the shot
var _before: PoolSim                    # the table before the last shot, to take it again in practice
var _trough: Array = []
var _thread: Thread
var _plan := {}
var _their_t := 0.0
var _their_stage := 0
var _their_shot := {}
var _esc_t := -10.0
var seen := {}
var result := {}
var my_line := []                       # the player's own lines on the table for the end of the game (shots made, longest run)
var cue_node: Node3D
var their_cue: Node3D
var place_at := Vector3.ZERO
var show_line := false                  # practice: the line in his head (L)
var line_node: MeshInstance3D
var trick := {}                         # the trick shot set up, or empty
var attempts := 3
var sunday := ""


func setup(m) -> void:
	main = m
	pub = m.pub
	view = m.view
	tbl = pub.pool_table
	to_world = tbl.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, PoolTable.BED, 0))
	rng.seed = 4242
	for i in 4:
		_ph[i] = rng.randf() * TAU
	cue_node = _make_cue(CUES[0])
	cue_node.visible = false
	pub.add_child(cue_node)
	their_cue = _make_cue(CUES[1])
	their_cue.visible = false
	pub.add_child(their_cue)
	var im := ImmediateMesh.new()
	line_node = MeshInstance3D.new()
	line_node.mesh = im
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.92, 0.88, 0.78, 0.5)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_node.material_override = lm
	line_node.visible = false
	pub.add_child(line_node)
	ui = PoolUI.new()
	ui.pool = self
	ui.visible = false
	var layer := CanvasLayer.new()
	layer.layer = 8
	m.add_child(layer)
	layer.add_child(ui)
	set_process(false)
	set_process_input(false)


# A cue: a tapered shaft and butt, the ferrule and the tip, the wrap; along -Z from its tip at the
# node, so its basis points it.
func _make_cue(c: Dictionary) -> Node3D:
	var n := Node3D.new()
	var shaft: Material = pub.mat(Color("cdb48a"), 0.5, 0.0, 2, Vector3.FORWARD, 5.0, 0.4)
	var butt: Material = pub.mat(Color(c.colour), 0.4, 0.0, 2, Vector3.FORWARD, 5.0, 0.5)
	var L := 1.45
	var parts := [[0.0, 0.012, 0.0062, 0.0065, pub.mat(Color("2a4f7a") if c.id != "mushroom" else Color("3b3026"), 0.8)],
		[0.012, 0.032, 0.0065, 0.0066, pub.mat(Color("e6e0d0"), 0.4)],
		[0.032, 0.74, 0.0066, 0.0098, shaft],
		[0.74, 1.0, 0.0098, 0.0118, butt],
		[1.0, 1.25, 0.0118, 0.0135, pub.mat(Color("1d1b1a"), 0.85)],
		[1.25, L, 0.0135, 0.0145, butt]]
	for p in parts:
		var a: float = p[0]
		var b: float = p[1]
		var cy: MeshInstance3D = pub.cyl(p[3], p[2], b - a, Vector3(0, 0, (a + b) * 0.5), p[4], n, 10)
		cy.rotation.x = PI * 0.5
		cy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if c.id == "mushroom":
		pub.cyl(0.0075, 0.0068, 0.004, Vector3(0, 0, 0.002), pub.mat(Color("3b3026"), 0.8), n, 10).rotation.x = PI * 0.5
	return n


# ---------------------------------------------------------------- in and out

# Up to the table. game: 8bar, 8league, 9ball, practice. opponent: one of PoolAI.PEOPLE or "".
# opts: {"rehearse", "body", "stakes", "story", "names", "loose"}.
func begin(game_mode := "8bar", opponent := "buddy", opts := {}) -> void:
	active = true
	mode = game_mode
	who = opponent if game_mode != "practice" else ""
	rehearsal = bool(opts.get("rehearse", false))
	stakes = int(opts.get("stakes", 0))
	sunday = str(opts.get("sunday", ""))
	story = str(opts.get("story", ""))
	body = (opts.get("body", {}) as Dictionary).duplicate()
	if body.is_empty():
		body = {"drinks": view.drinks, "hurt": view.hurt, "tension": view.tension, "clock": view.clock, "cold": 0.0}
	rng.seed = int(opts.get("seed", Time.get_ticks_usec() % 100000))
	trick = {}
	attempts = 3
	if mode == "trick":
		for tr in PoolCareer.TRICKS:
			if tr.id == str(opts.get("trick", "")):
				trick = tr
		who = ""
	rules = PoolRules.new(mode if mode != "trick" else "practice")
	if who != "":
		ai = PoolAI.new(who, rng.randi())
		names = ["You", str(ai.me.name)]
	else:
		ai = null
		names = ["You", ""]
	rules.names = names
	seen = {}
	result = {}
	_new_rack(float(opts.get("loose", 0.0)))
	# who breaks: the challenger's quarters on the rail, his break
	rules.turn = 0 if not bool(opts.get("they_break", false)) else 1
	chalk = 1.0
	tip = Vector2.ZERO
	elev = 4.0
	stance = 0.15
	overview = false
	_show_cue()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	view.walking = false
	ui.visible = true
	ui.say_clear()
	set_process(true)
	set_process_input(true)
	_opening_lines()
	_turn_start()


func end() -> void:
	if not active:
		return
	active = false
	drawing = false
	_join()
	cue_node.visible = false
	their_cue.visible = false
	line_node.visible = false
	tbl.call_pocket(-1)
	ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	view.focus_fov = 0.0
	set_process(false)
	set_process_input(false)
	if result.is_empty():
		result = {"won": false, "left": true, "stakes": stakes}
	left.emit(result)


func _new_rack(loose := 0.0) -> void:
	sim = PoolSim.new(PoolSim.sov_table())
	if mode == "practice" or mode == "trick":
		rules.game = "practice"
	if not trick.is_empty():
		for b in trick.balls:
			sim.add_ball(b[0], Vector3(b[1].x, 0, b[1].y), b[0] == 0)
		rules.broke = true
		rules.in_hand = ""
		rules.winner = -1
		_trough = []
		tbl.hide_balls()
		tbl.set_trough([])
		_put_all(0.0)
		return
	sim.add_ball(0, Vector3(sim.table.head_spot().x, 0, 0), true)
	rules.rack(sim, rng, loose)
	rules.broke = false
	rules.in_hand = "kitchen"
	rules.winner = -1
	rules.groups = ["", ""]
	rules.fouls = [0, 0]
	_trough = []
	tbl.hide_balls()
	tbl.set_trough([])
	_put_all(0.0)


func cues() -> Array:
	return PoolCareer.cues(main.settings) if main != null else CUES


func _show_cue() -> void:
	cue_node.queue_free()
	cue_i = cue_i % cues().size()
	cue_node = _make_cue(cues()[cue_i])
	pub.add_child(cue_node)


# ---------------------------------------------------------------- turns

func _turn_start() -> void:
	tbl.call_pocket(-1)
	rules.called = -1
	if rules.winner >= 0:
		_game_over()
		return
	if rules.turn == 1 and ai != null:
		_theirs_begin()
		return
	tip = Vector2(0, 0)
	if rules.in_hand != "":
		phase = "place"
		overview = true
		var cb := sim.ball(0)
		place_at = cb.p if cb.state != PoolSim.DOWN and cb.state != PoolSim.OFF else Vector3(sim.table.head_spot().x, 0, 0)
		_hint()
	else:
		phase = "aim"
		overview = false
		_aim_at_something()
		_hint()


# start the cue pointing at the nearest ball he may hit, the way he'd walk up to it
func _aim_at_something() -> void:
	var cb := sim.ball(0)
	var best := -1
	var bd := INF
	for id in rules.targets(sim):
		var b := sim.ball(id)
		var d := cb.p.distance_to(b.p)
		if d < bd:
			bd = d
			best = id
	if best >= 0:
		var to := sim.ball(best).p - cb.p
		aim_yaw = atan2(-to.z, to.x)


func aim_dir() -> Vector3:
	return Vector3(cos(aim_yaw), 0, -sin(aim_yaw))


func cue() -> Dictionary:
	var c: Dictionary = cues()[cue_i % cues().size()].duplicate()
	# a dry tip holds the ball worse off its middle
	c.limit = float(c.limit) - (1.0 - chalk) * 0.16
	return c


# ---------------------------------------------------------------- his body

func shake() -> float:
	if shake_off:
		return 0.0
	var drinks := float(body.get("drinks", 0))
	var hurt := float(body.get("hurt", 0))
	var nerves := float(body.get("tension", 0))
	var hour := float(body.get("clock", 1260))
	var late := clampf((hour - 1380.0) / 180.0, 0.0, 1.2) if hour > 600 else 1.2
	var s := 0.0006
	s += drinks * 0.0004 + maxf(0.0, drinks - 5.0) * 0.0006
	s += hurt * 0.0008
	s += float(body.get("cold", 0.0)) * 0.0012
	s += nerves * 0.0003
	s += late * 0.0004
	# money on it, and the room watching: a little more
	if stakes >= 20:
		s += 0.0002
	return s


func _tremor(at: float) -> Vector2:
	var nerves := float(body.get("tension", 0))
	var f := 7.5 + nerves * 0.9
	var y := sin(at * TAU * f + _ph[0]) * 0.6 + sin(at * TAU * f * 1.37 + _ph[1]) * 0.4
	var x := sin(at * TAU * f * 0.91 + _ph[2]) * 0.6 + sin(at * TAU * f * 1.53 + _ph[3]) * 0.4
	return Vector2(x, y) * shake()


# the lowest the butt can be here: over the rail behind the cue ball, and over any ball in the way of
# the cue's line back
func min_elev() -> float:
	var cb := sim.ball(0)
	var back := -aim_dir()
	var need := ELEV_MIN
	# the rail: where the line back crosses the cushion's line
	var hl := sim.table.L * 0.5
	var hw := sim.table.W * 0.5
	var dist := INF
	if absf(back.x) > 1e-4:
		dist = minf(dist, ((hl if back.x > 0 else -hl) - cb.p.x) / back.x)
	if absf(back.z) > 1e-4:
		dist = minf(dist, ((hw if back.z > 0 else -hw) - cb.p.z) / back.z)
	# the rail's top is RAIL_TOP over the cloth, and a hand's thickness more to bridge on it
	var over := PoolSim.RAIL_TOP + 0.02 - cb.r
	if dist < 0.5:
		need = maxf(need, rad_to_deg(atan2(over, maxf(dist + 0.08, 0.02))))
	for o in sim.balls:
		if o.id == 0 or o.state == PoolSim.DOWN or o.state == PoolSim.OFF:
			continue
		var rel := Vector3(o.p.x - cb.p.x, 0, o.p.z - cb.p.z)
		var s := rel.dot(back)
		if s <= 0.0 or s > 0.6:
			continue
		if (rel - back * s).length() < o.r + 0.012:
			need = maxf(need, rad_to_deg(atan2(o.r * 2.0 + 0.01 - cb.r, s)))
	return clampf(need, ELEV_MIN, ELEV_MAX)


# ---------------------------------------------------------------- every frame

func _process(dt: float) -> void:
	if not active:
		return
	t += dt
	match phase:
		"aim":
			elev = maxf(elev, min_elev())
			_camera_aim(dt)
			_place_cue()
			_draw_line()
		"place":
			_camera_over(dt)
			_place_ghost()
		"rolling":
			_play(dt)
			_camera_watch(dt)
		"theirs":
			_theirs(dt)
			_camera_watch(dt)
		"over":
			_camera_over(dt)
	ui.queue_redraw()


func world(p: Vector3) -> Vector3:
	return to_world * p


func _camera_aim(dt: float) -> void:
	var cb := sim.ball(0)
	var d := aim_dir()
	if overview:
		_camera_over(dt)
		return
	var s := stance
	var dist := lerpf(0.36, 1.05, s) + elev / 90.0 * 0.15
	var hgt := lerpf(0.1, 0.78, s * s) + sin(deg_to_rad(elev)) * 0.32
	var eye := cb.p - d * dist + Vector3(0, hgt, 0)
	var look := cb.p + d * lerpf(0.5, 0.25, s) + Vector3(0, -0.02, 0)
	_look(world(eye), world(look), dt, 18.0)
	view.focus_fov = lerpf(46.0, 58.0, s) * (0.6 if Input.is_key_pressed(KEY_SHIFT) and not drawing else 1.0)


func _camera_over(dt: float) -> void:
	# stood up at the side of the table, looking down over it
	var cb := sim.ball(0)
	var side := -1.0 if cb.p.z <= 0.0 else 1.0
	var eye := Vector3(clampf(cb.p.x * 0.4, -0.5, 0.5), 1.15, side * 1.15)
	_look(world(eye), world(Vector3(0, 0, side * 0.05)), dt, 6.0)
	view.focus_fov = 62.0


func _camera_watch(dt: float) -> void:
	# up off the shot, watching it go
	if phase == "rolling" and _who_shot == 0 and not overview:
		stance = move_toward(stance, 0.9, dt * 0.9)
		var cb := sim.ball(0)
		var d := aim_dir()
		var eye := _shot_from - d * lerpf(0.4, 1.0, stance) + Vector3(0, lerpf(0.12, 0.85, stance), 0)
		var cpos: Vector3 = sim.sample(cb, _play_t)[0]
		var look := _shot_from.lerp(cpos, 0.5) + d * 0.3
		_look(world(eye), world(look), dt, 3.0)
		view.focus_fov = 60.0
		return
	# watching the other man shoot: stood against the wall by the rail, his own place
	var eye := Vector3(-0.2, 1.05, -1.25)
	_look(world(eye), world(Vector3(0.1, 0, 0)), dt, 3.5)
	view.focus_fov = 62.0


func _look(eye: Vector3, at: Vector3, dt: float, ease: float) -> void:
	var k := 1.0 - exp(-dt * ease)
	view.eye_pos = view.eye_pos.lerp(eye, k) if view.eye_pos.distance_to(eye) < 4.0 else eye
	var a := Posts.aim(view.eye_pos, at)
	var dy := wrapf(a.x - view.yaw, -PI, PI)
	view.yaw += dy * minf(1.0, k * 1.6)
	view.pitch = lerpf(view.pitch, a.y, minf(1.0, k * 1.6))
	view.want_yaw = view.yaw
	view.want_pitch = view.pitch


# The cue in his hands: its tip off the ball by the draw, on the spot he's chosen, the butt up, the
# shake in it.
func _place_cue() -> void:
	var cb := sim.ball(0)
	var d := aim_dir()
	var e := deg_to_rad(elev)
	var fwd := (d * cos(e) - Vector3.UP * sin(e)).normalized()
	var side := d.cross(Vector3.UP).normalized()
	var up := side.cross(fwd).normalized()
	var tr := _tremor(t)
	var a := tip.x + tr.x * 30.0
	var b := tip.y + tr.y * 30.0
	var R := cb.r
	var c := sqrt(maxf(1.0 - a * a - b * b, 0.0)) * R
	var contact := cb.p + side * a * R + up * b * R - fwd * c
	var gap := 0.012 + draw * 0.28
	var tip_at := contact - fwd * gap
	cue_node.visible = not overview or phase == "aim"
	var bas := Basis.looking_at(fwd, Vector3.UP)
	cue_node.global_transform = to_world * Transform3D(bas.rotated(fwd, wrist * 2.0), tip_at)


func _place_ghost() -> void:
	# in hand: where the pointer is on the cloth
	var r: Array = view.ray(true)
	var o: Vector3 = to_world.affine_inverse() * (r[0] as Vector3)
	var dv: Vector3 = to_world.basis.inverse() * (r[1] as Vector3)
	var cb := sim.ball(0)
	if absf(dv.y) > 1e-4:
		var k := (cb.r - o.y) / dv.y
		if k > 0.0:
			var p := o + dv * k
			var lim := Vector2(sim.table.L * 0.5 - cb.rc - 0.002, sim.table.W * 0.5 - cb.rc - 0.002)
			if rules.in_hand == "kitchen":
				p.x = minf(p.x, sim.table.head_string() - 0.001)
			place_at = Vector3(clampf(p.x, -lim.x, lim.x), 0, clampf(p.z, -lim.y, lim.y))
	var ok := rules.can_place(sim, place_at)
	tbl.put_ball(0, cb.r, Vector3(place_at.x, cb.r, place_at.z), true)
	ui.place_ok = ok
	cue_node.visible = false


# ---------------------------------------------------------------- the player's hands

func _input(e: InputEvent) -> void:
	if not active:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if phase == "over" or stakes == 0 or rules.winner >= 0 or t - _esc_t < 2.5:
			end()
		else:
			_esc_t = t
			ui.toast("Esc again to walk away from the table. The money on the rail stays there.")
		return
	if main.menus.is_open():
		return
	if e is InputEventKey:
		get_viewport().set_input_as_handled()
		if e.pressed and not e.echo:
			_key(e.physical_keycode)
		return
	if e is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		var rel: Vector2 = e.relative
		var ls := float(main.settings.get("look_speed", 1.0))
		match phase:
			"aim":
				if drawing:
					draw = clampf(draw + rel.y / DRAW_PX, 0.0, 1.0)
					wrist += rel.x * 0.00022
				elif tipping:
					tip += Vector2(rel.x, -rel.y) * TIP_K
					if tip.length() > 0.7:
						tip = tip.normalized() * 0.7
				elif overview:
					pass
				else:
					var k := AIM_K * ls * (FINE if Input.is_key_pressed(KEY_SHIFT) else 1.0)
					aim_yaw -= rel.x * k
					stance = clampf(stance + rel.y * 0.0025, 0.0, 1.0)
			"place":
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if e is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		match phase:
			"aim":
				_mouse_aim(e)
			"place":
				if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
					if rules.can_place(sim, place_at):
						var cb := sim.ball(0)
						cb.p = Vector3(place_at.x, cb.r, place_at.z)
						cb.state = PoolSim.STILL
						cb.pocket = -1
						cb.segs = []
						rules.in_hand_placed = rules.in_hand
						rules.in_hand = ""
						phase = "aim"
						overview = false
						Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
						_aim_at_something()
						main.audio.sfx("clack", 0.3, 1.4)
						_hint()
					else:
						ui.toast("Not there." if rules.in_hand != "kitchen" else "Behind the line, and clear of the balls.")
			"rolling":
				if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
					_speed_k = 3.0
			"over":
				pass


func _mouse_aim(e: InputEventMouseButton) -> void:
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			if e.pressed:
				if overview:
					overview = false
					return
				drawing = true
				draw = 0.0
				wrist = 0.0
				view.hand_drag = true
			elif drawing:
				drawing = false
				view.hand_drag = false
				if draw < 0.035:
					draw = 0.0
					wrist = 0.0
				else:
					_stroke()
		MOUSE_BUTTON_RIGHT:
			tipping = e.pressed
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
				elev = clampf(elev + (0.5 if Input.is_key_pressed(KEY_SHIFT) else 2.0), min_elev(), ELEV_MAX)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				elev = clampf(elev - (0.5 if Input.is_key_pressed(KEY_SHIFT) else 2.0), min_elev(), ELEV_MAX)


func _key(k: int) -> void:
	match k:
		KEY_TAB:
			if phase == "aim":
				overview = not overview
		KEY_C:
			if phase == "aim" or phase == "place":
				chalk = 1.0
				main.audio.sfx("scratch", 0.35, 1.6)
				_once("chalk", "He chalked it. The cube's worn into a dish on one face, the way everybody holds it.")
				ui.say("Chalked.")
		KEY_Q, KEY_E:
			if phase == "aim" or phase == "place":
				var cs := cues()
				cue_i = (cue_i + (1 if k == KEY_E else cs.size() - 1)) % cs.size()
				_show_cue()
				ui.say("%s. %s" % [cs[cue_i].name, cs[cue_i].note])
				main.audio.sfx("lift", 0.3, 1.2)
		KEY_F:
			if phase == "aim" and rules.needs_call(sim):
				var k2 := _aimed_pocket()
				rules.called = k2
				tbl.call_pocket(k2)
				ui.say("Called: %s." % pocket_name(k2) if k2 >= 0 else "He can't see where it'd go.")
		KEY_R:
			if phase == "over":
				_rematch()
			elif phase == "aim" and mode == "practice" and trick.is_empty():
				_new_rack()
				rules.in_hand = "kitchen"
				_turn_start()
		KEY_BACKSPACE:
			if mode == "practice" and _before != null and (phase == "aim" or phase == "place"):
				sim = _before.copy()
				_put_all(0.0)
				ui.say("Put back the way they were.")
				_turn_start()
		KEY_L:
			if mode == "practice":
				show_line = not show_line
		KEY_SPACE:
			if phase == "rolling":
				_speed_k = 3.0
		KEY_P:
			if phase == "aim" and rules.game == "9ball" and rules.push_ok and rules.turn == 0:
				rules.pushing = not rules.pushing
				ui.say("Push out: anything goes on this one, and then he chooses." if rules.pushing else "No push.")


static func pocket_name(k: int) -> String:
	return ["the head corner on the near side", "the head corner on the far side", "the foot corner on the near side",
		"the foot corner on the far side", "the side pocket, near", "the side pocket, far"][k] if k >= 0 and k < 6 else "?"


# the pocket the object ball's lined up on, from where the cue's pointing
func _aimed_pocket() -> int:
	var hit := _first_contact()
	if hit.is_empty():
		return -1
	var b: PoolSim.Ball = hit.ball
	var dir: Vector3 = (b.p - hit.ghost).normalized()
	var best := -1
	var bd := deg_to_rad(18.0)
	for k in sim.table.pockets.size():
		var pk: Array = sim.table.pockets[k]
		var to: Vector3 = (pk[0] - b.p)
		to.y = 0
		var ang := acos(clampf(to.normalized().dot(Vector3(dir.x, 0, dir.z).normalized()), -1.0, 1.0))
		if ang < bd:
			bd = ang
			best = k
	return best


# where the cue ball would first meet a ball going straight down the line: {ball, ghost}
func _first_contact() -> Dictionary:
	var cb := sim.ball(0)
	var d := aim_dir()
	var best := {}
	var bs := INF
	for o in sim.balls:
		if o.id == 0 or o.state == PoolSim.DOWN or o.state == PoolSim.OFF:
			continue
		var rel := Vector3(o.p.x - cb.p.x, 0, o.p.z - cb.p.z)
		var s := rel.dot(d)
		if s <= 0.0:
			continue
		var off := (rel - d * s).length()
		var R: float = o.r + cb.r
		if off >= R:
			continue
		var back := sqrt(R * R - off * off)
		var ss := s - back
		if ss < bs:
			bs = ss
			best = {"ball": o, "ghost": cb.p + d * ss, "s": ss}
	return best


func _draw_line() -> void:
	if not show_line or mode != "practice" or overview:
		line_node.visible = false
		return
	var im := line_node.mesh as ImmediateMesh
	im.clear_surfaces()
	var hit := _first_contact()
	var cb := sim.ball(0)
	var y := 0.0015
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var end_p: Vector3 = hit.ghost if not hit.is_empty() else cb.p + aim_dir() * 2.0
	im.surface_add_vertex(world(Vector3(cb.p.x, y, cb.p.z)))
	im.surface_add_vertex(world(Vector3(end_p.x, y, end_p.z)))
	if not hit.is_empty():
		var b: PoolSim.Ball = hit.ball
		var dir: Vector3 = (b.p - hit.ghost)
		dir.y = 0
		dir = dir.normalized()
		im.surface_add_vertex(world(Vector3(b.p.x, y, b.p.z)))
		im.surface_add_vertex(world(Vector3(b.p.x, y, b.p.z) + dir * 0.35))
		# the ghost ball's outline
		for i in 24:
			var a0 := TAU * i / 24.0
			var a1 := TAU * (i + 1) / 24.0
			im.surface_add_vertex(world(Vector3(end_p.x + cos(a0) * cb.r, y, end_p.z + sin(a0) * cb.r)))
			im.surface_add_vertex(world(Vector3(end_p.x + cos(a1) * cb.r, y, end_p.z + sin(a1) * cb.r)))
	im.surface_end()
	line_node.visible = true


# ---------------------------------------------------------------- the stroke

var _who_shot := 0
var _shot_from := Vector3.ZERO


# What the stroke is, from what the player did and his shake at the moment he let go.
func release_state(at_t: float) -> Dictionary:
	var tr := _tremor(at_t)
	var c := cue()
	var glove := 0.6 if PoolCareer.has(main.settings, "glove") else 1.0
	var dir := aim_dir().rotated(Vector3.UP, wrist * 0.6 * glove + tr.x)
	# the warped cue: off line a little, a different way each time it's picked up and rolled in the hand
	if float(c.warp) > 0.0:
		dir = dir.rotated(Vector3.UP, float(c.warp) * sin(rng.randf() * TAU))
	var a := tip.x + tr.x * 25.0 + wrist * 0.4
	var b := tip.y + tr.y * 25.0
	var speed := SPEED_LO + (SPEED_HI - SPEED_LO) * pow(draw, 1.5)
	return {"dir": dir, "elev": deg_to_rad(elev), "a": a, "b": b, "speed": speed, "cue": c}


func _stroke() -> void:
	var st := release_state(t)
	_before = sim.copy()
	_start = {"targets": rules.targets(sim), "kitchen": rules.in_hand_placed == "kitchen", "jumped": false}
	_start["first_in_kitchen"] = false
	_shoot(st, 0)
	chalk = maxf(0.0, chalk - (0.11 if PoolCareer.has(main.settings, "chalk") else 0.22))
	draw = 0.0
	wrist = 0.0


func _shoot(st: Dictionary, shooter: int) -> void:
	_who_shot = shooter
	var cb := sim.ball(0)
	_shot_from = cb.p
	sim = sim.copy()
	cb = sim.ball(0)
	var r := sim.strike(cb, st.dir, float(st.elev), float(st.a), float(st.b), float(st.speed), st.cue)
	sim.run()
	# did it leave the cloth on the way (a jump)
	for sg in sim.ball(0).segs:
		if sg[7] == PoolSim.AIR and float(sg[2].y) > 0.75:
			_start.jumped = true
	# a ball behind the line hit first, from in hand behind it
	var fh := sim.first_hit(0)
	if fh >= 0 and _start.kitchen:
		var fb = _before.ball(fh) if _before != null else null
		if fb != null and fb.p.x < sim.table.head_string():
			_start.first_in_kitchen = true
	_play_t = 0.0
	_heard = 0
	_speed_k = 1.0
	phase = "rolling"
	cue_node.visible = shooter == 0
	their_cue.visible = shooter == 1
	if r.miscue:
		main.audio.at("clack", world(_shot_from), 0.7, 1.5, 1.7)
		ui.say("Miscue." if chalk > 0.4 else "Miscue. The tip was dry.")
		_once("miscue_%d" % shooter, "The tip slid off the ball with that sound everybody in the room knows." if shooter == 0 else "The tip slid off. He looked at the end of the cue like it had done it.")
	else:
		var hard := clampf(float(st.speed) / 6.0, 0.15, 1.0)
		main.audio.at("break" if not rules.broke and mode != "practice" and float(st.speed) > 4.0 else "cue", world(_shot_from), 0.5 + hard * 0.5, 1.5, 0.9 + rng.randf() * 0.2)
	tbl.call_pocket(rules.called)


# ---------------------------------------------------------------- playing it back

func _put_all(tt: float) -> void:
	for b in sim.balls:
		var s: Array = sim.sample(b, tt)
		tbl.put_ball(b.id, b.r, s[0], s[2])


func _play(dt: float) -> void:
	var prev := _play_t
	_play_t += dt * _speed_k
	var step := _play_t - prev
	for b in sim.balls:
		var s: Array = sim.sample(b, _play_t)
		var n: Node3D = tbl.ball_node(b.id, b.r)
		n.position = Vector3(s[0].x, PoolTable.BED + s[0].y, s[0].z)
		n.visible = s[2]
		var w: Vector3 = s[1]
		if w.length() > 1e-4:
			n.basis = Basis(w.normalized(), w.length() * step) * n.basis
			n.basis = n.basis.orthonormalized()
	# the cue goes through and stays a moment
	if _who_shot == 0 and _play_t < 0.4:
		draw = -minf(_play_t * 4.0, 0.25)
		_place_cue()
	elif _who_shot == 0:
		cue_node.visible = false
	while _heard < sim.log.size() and float(sim.log[_heard][0]) <= _play_t:
		_sound(sim.log[_heard])
		_heard += 1
	if _play_t >= sim.t + 0.35:
		_settled()


func _sound(e: Array) -> void:
	var b := sim.ball(e[2])
	if b == null:
		return
	var at: Vector3 = world(sim.sample(b, float(e[0]))[0])
	var sp := float(e[4])
	match str(e[1]):
		"ball":
			main.audio.at("clack", at, clampf(sp / 3.0, 0.08, 1.0), 1.6, 1.0 + rng.randf_range(-0.08, 0.08) + (0.15 if sp < 0.6 else 0.0))
		"rail":
			main.audio.at("thump", at, clampf(sp / 3.5, 0.05, 0.6), 1.4, 1.6)
		"jaw":
			main.audio.at("tock", at, clampf(sp / 3.0, 0.08, 0.7), 1.4, 1.5)
		"pocket":
			main.audio.at("pocket", at + Vector3(0, -0.1, 0), clampf(0.4 + sp / 4.0, 0.3, 1.0), 1.6, rng.randf_range(0.85, 1.1))
			# and down the gully under the table to the window at the foot
			get_tree().create_timer(0.6).timeout.connect(func(): main.audio.at("rattle", world(Vector3(0.9, -0.4, 0.1)), 0.35, 1.4, 0.8))
		"off":
			get_tree().create_timer(0.4).timeout.connect(func(): main.audio.at("thump", at + Vector3(0, -0.8, 0), 0.6, 1.8, 0.9))
		"bounce":
			main.audio.at("tock", at, clampf(sp, 0.1, 0.6), 1.4, 1.1)


# Everything's stopped: the rules have their say, the balls that went down go into the window, and
# it's somebody's shot.
func _settled() -> void:
	var shooter := rules.turn
	cue_node.visible = false
	their_cue.visible = false
	for id in sim.pocketed():
		if id != 0 and not (id in _trough):
			_trough.append(id)
	tbl.set_trough(_trough)
	if not trick.is_empty():
		_trick_settled()
		return
	var res := rules.judge(sim, _start)
	# fresh balls from where everything lies
	sim = sim.copy()
	for id in res.spot:
		rules.spot(sim, id)
		_trough.erase(id)
	tbl.set_trough(_trough)
	var cb := sim.ball(0)
	if res.scratch:
		cb.state = PoolSim.STILL
		cb.pocket = -1
		cb.p = Vector3(sim.table.head_spot().x, cb.r, 0)
	_put_all(0.0)
	if res.scratch:
		tbl.put_ball(0, cb.r, cb.p, false)
	_tell(res, shooter)
	rules.next(res)
	rules.in_hand_placed = ""
	_turn_start()


func _trick_settled() -> void:
	var potted := sim.pocketed()
	var touched := {}
	for e in sim.log:
		if e[1] == "ball":
			touched[e[2]] = true
			touched[e[3]] = true
	var ok := not (0 in potted) and not (0 in sim.went_off())
	for id in trick.need:
		ok = ok and (id in potted)
	for id in trick.avoid:
		ok = ok and not touched.has(id)
	attempts -= 1
	if ok:
		main.audio.sfx("cheer", 0.35, 1.2)
		ui.say("Made it. Table 28 pays up, slowly, with a lot to say about it." if not rehearsal else "Made it.")
		result = {"made": true, "won": true, "why": "made it", "stakes": int(trick.pays)}
		phase = "over"
		overview = true
		ui.over(true, "made it, %d %s" % [3 - attempts, "try" if 3 - attempts == 1 else "tries"])
		return
	if attempts <= 0:
		result = {"made": false, "won": false, "why": "three tries and no", "stakes": 0}
		phase = "over"
		overview = true
		main.audio.sfx("groan", 0.3, 1.1)
		ui.over(false, "three tries and no")
		return
	ui.say(["Not quite. Two more.", "No. One more."][2 - attempts] if attempts <= 2 else "Again.")
	_new_rack()
	_turn_start()


# ---------------------------------------------------------------- the other man's shot

func _theirs_begin() -> void:
	phase = "theirs"
	_their_t = 0.0
	_their_stage = 0
	_plan = {}
	cue_node.visible = false
	var copy_sim := sim.copy()
	var copy_rules := _rules_copy()
	_thread = Thread.new()
	_thread.start(func(): return ai.plan(copy_sim, copy_rules))
	ui.say("%s walks round the table." % names[1] if rng.randf() < 0.5 else "%s chalks up." % names[1])


func _rules_copy() -> PoolRules:
	var r := PoolRules.new(rules.game)
	for k in ["turn", "broke", "in_hand", "winner", "called", "push_ok", "pushing", "after_push"]:
		r.set(k, rules.get(k))
	r.groups = rules.groups.duplicate()
	r.fouls = rules.fouls.duplicate()
	return r


func _join() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null


func _theirs(dt: float) -> void:
	_their_t += dt
	match _their_stage:
		0:
			# thinking: he takes his time over it, as long as the sums take and a bit
			if _thread != null and not _thread.is_alive() and _their_t > 1.2:
				_plan = _thread.wait_to_finish()
				_thread = null
				_their_stage = 1
				_their_t = 0.0
				var cb := sim.ball(0)
				if _plan.get("place") != null:
					var p: Vector3 = _plan.place
					cb.p = Vector3(p.x, cb.r, p.z)
					cb.state = PoolSim.STILL
					cb.pocket = -1
					cb.segs = []
					tbl.put_ball(0, cb.r, cb.p, true)
					rules.in_hand_placed = rules.in_hand
					rules.in_hand = ""
					main.audio.sfx("clack", 0.25, 1.4)
				rules.called = int(_plan.get("call", -1))
				tbl.call_pocket(rules.called)
				_their_shot = ai.hands(_plan, 1.0 + float(body.get("tension", 0)) * 0.0)
				_their_shot["cue"] = CUES[1] if who == "bigman" else CUES[0]
		1:
			# down on it: his cue along the line, a couple of practice strokes, then through
			var cb := sim.ball(0)
			var d: Vector3 = _their_shot.dir
			var e := float(_their_shot.elev)
			var fwd := (d * cos(e) - Vector3.UP * sin(e)).normalized()
			var strokes := 0.12 + 0.1 * (0.5 - 0.5 * cos(_their_t * 5.5)) if _their_t < 1.7 else 0.12 + (_their_t - 1.7) * 1.4
			var tip_at := cb.p - fwd * (cb.r + strokes)
			their_cue.visible = true
			their_cue.global_transform = to_world * Transform3D(Basis.looking_at(fwd, Vector3.UP), tip_at)
			if _their_t > 2.0:
				their_cue.visible = false
				_before = sim.copy()
				_start = {"targets": rules.targets(sim), "kitchen": rules.in_hand_placed == "kitchen", "jumped": false, "first_in_kitchen": false}
				_shoot(_their_shot, 1)


# ---------------------------------------------------------------- what's said

func _opening_lines() -> void:
	if not trick.is_empty():
		ui.say("%s. %s" % [trick.name, trick.line])
		return
	if sunday != "":
		ui.say("The Sunday draw, %s, against %s. League rules." % [sunday.to_lower(), names[1].to_lower()])
	match mode:
		"practice":
			ui.say("The table to himself. R racks them again, Backspace puts the last shot back, L shows the line in his head.")
		_:
			var how := rules.describe()
			ui.say("%s%s. %s." % [how, (", against %s" % names[1].to_lower() if names[1] != "" else ""), ("$%d on the rail" % stakes) if stakes > 0 else "For nothing"])
	if not seen.has("lean"):
		ui.note("The table has a lean to it the regulars play, and the bar cue ball is big and heavy: it follows well and it doesn't want to draw.")
		seen["lean"] = true


func _hint() -> void:
	match phase:
		"place":
			ui.hint = "Ball in hand%s: move it with the mouse, click to put it down." % (" behind the line" if rules.in_hand == "kitchen" else "")
		"aim":
			var extra := ""
			if rules.needs_call(sim):
				extra = "   F calls the pocket."
			if rules.game == "9ball" and rules.push_ok and rules.turn == 0:
				extra += "   P: push out."
			ui.hint = "Mouse aims (Shift fine), up and down moves his head.  Right button: the tip.  Wheel: the butt.  Hold and pull back to stroke.  C chalk, Q E cues, Tab stands up." + extra
		_:
			ui.hint = ""


func _tell(res: Dictionary, shooter: int) -> void:
	var who_s: String = "He" if shooter == 0 else names[1]
	var potted: Array = res.potted
	var line := ""
	if res.win >= 0:
		return
	if res.foul:
		match str(res.why):
			"scratch":
				line = "Scratch."
				if shooter == 0:
					_once("scratch", "The cue ball went down after it. The coin-op sent it back by its own chute, the way it does.")
			"off the table":
				line = "Off the table. It went across the carpet and under a stool."
			"nothing hit":
				line = "Didn't touch a thing."
			"wrong ball first":
				line = "Wrong ball first."
			"no rail after contact":
				line = "Nothing reached a rail."
			"jumped on a house cue":
				line = "Jumped it. Not on the house cues."
				_once("jumped", "Somebody at the bar said hey, and meant the cloth.")
			_:
				line = str(res.why).capitalize() + "."
		line += " Ball in hand%s." % (" behind the line" if res.in_hand == "kitchen" else "")
	elif potted.size() > 0:
		var names_b := potted.map(func(i): return str(i))
		line = "%s: %s down." % [who_s, ", ".join(names_b)]
		if res.has("groups"):
			line += " %s on %s." % [who_s, res.groups]
	elif res.keep:
		line = ""
	else:
		line = "%s missed." % who_s if shooter == 0 or rng.randf() < 0.5 else ""
	# what he saw: the jaws, the throw, the lean
	var jaws := sim.log.filter(func(e): return e[1] == "jaw").size()
	if jaws >= 2 and potted.is_empty():
		_once("rattle", "It rattled in the jaws and came back out. The pockets on this one are tighter than they look.")
	for e in sim.log:
		if e[1] == "burn" and float(e[4]) < 0.5:
			_once("burn", "The ball crossed the burn in the cloth and turned a hair, the way they all do there.")
			break
	if shooter == 1 and ai != null and str(_plan.get("kind", "")) == "throw":
		_once("threw_%d" % ai.thrown, ["He missed it by a hand. His left hand went flat on the rail and stayed there.", "He missed the one that mattered and made a show of not minding.", "He was down on it a long time and missed it anyway, by the width of a cigarette."][mini(ai.thrown - 1, 2)])
	if line != "":
		ui.say(line)


func _once(key: String, text: String) -> void:
	if seen.has(key):
		return
	seen[key] = true
	ui.note(text)


# ---------------------------------------------------------------- the end of the game

func _game_over() -> void:
	phase = "over"
	overview = true
	var won := rules.winner == 0
	var why: String = rules.history[rules.history.size() - 1].why if not rules.history.is_empty() else ""
	result = {"won": won, "why": why, "stakes": stakes, "made": rules.made[0], "shots": rules.shots[0], "run": rules.runs[0],
		"thrown": ai.thrown if ai != null else 0, "fouls": rules.history.filter(func(h): return h.who == 0 and h.foul).size(),
		"dumped": _dumped(), "opponent": who, "game": mode, "margin": _margin()}
	if won:
		main.audio.sfx("cheer", 0.25, 1.1) if stakes > 0 else main.audio.sfx("clack", 0.3)
	ui.over(won, why)


# how many the other man had left when it ended
func _margin() -> int:
	if rules.game == "9ball":
		return rules.on_table(sim).size()
	return rules.group_left(sim, 1).size() if rules.groups[1] != "" else 7


# losing on purpose, and how plainly: fouls that touch nothing, or the eight knocked in early
func _dumped() -> int:
	var obvious := 0
	for h in rules.history:
		if h.who != 0:
			continue
		if h.foul and h.why in ["nothing hit", "wrong ball first", "scratch"]:
			obvious += 1
		if h.why == "the eight went early":
			obvious += 2
	return obvious


func _rematch() -> void:
	if story != "":
		end()
		return
	var they_break := rules.winner == 0     # loser breaks, at the Sov winner stays and challenger breaks: keep it simple, loser racks so winner... the other man breaks
	_new_rack()
	rules.turn = 1 if they_break and ai != null else 0
	rules.history = []
	rules.shots = [0, 0]
	rules.made = [0, 0]
	result = {}
	ui.say_clear()
	ui.over_hide()
	_turn_start()
