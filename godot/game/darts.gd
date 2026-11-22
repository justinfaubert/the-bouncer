# Darts, at the board on the east wall (game/dart_sim.gd is the physics). No bar to stop on a mark,
# no meter: the same hands make the same throw every time, and what gets between the player and
# the treble is his body and the three house darts.
#
# The throw, in four parts, each the player's:
#   aim     his eyes. The mouse moves them (finely: he's looking down a dart, not round a room).
#           Where they rest on the board is where a throw drawn back the usual way lands.
#   draw    hold the button and pull the mouse back: the dart comes back toward his face, and how
#           far it comes is how hard it goes. Halfway back is the usual throw; more lands higher
#           and flatter, less lower. Let go and the arm goes through. Any sideways drift in the
#           pull is the wrist turned: it goes off line by as much.
#   loft    the wheel: the elbow up or down. A low elbow throws flat and hard, a high one lobs it
#           in from above (over a dart that's blocking the bed, and tail-up into the board, where
#           it holds worse). Either lands where he's looking, drawn the usual way.
#   grip    Q and E: his fingers up the barrel toward the point, or back toward the shaft. Up front
#           the nose leaves a little down; at the back, up, and it swims more in the air.
#   And A and D shuffle him along the line.
#
# What pushes back (all of it his body, nothing on the screen but what that does):
#   - his hand's tremor, in the dart's point while he holds it, and in the throw when he lets go:
#     the drink, the hour, a hand that's been hurt, hands cold from the door, the nerves after
#     trouble (fast and fine), and an arm held up too long;
#   - his breathing, in his eyes: they rise and fall on it. Hold the right button to hold his
#     breath and they settle; hold it too long and the shake comes up, and then he has to breathe.
#   - the three house darts: one with a bent shaft, one with a torn flight, one heavier than the
#     others. He learns them or he doesn't.
#   - the board: the 20 chewed soft (darts hang in it, and drop), the wire, darts already in it.
#
# The score goes up in chalk on the board beside it, not on the screen. The column keeps to what
# he'd notice. Esc puts the darts down.
class_name Darts
extends Node

const OCHE := 2.37                       # the line, from the board's face
const FACE := 0.0575                     # the board's face, out from the cabinet's back (models/dartboard.glb)
const EYE_UP := Posts.STAND - 1.73       # his eyes over the bull
const HAND := Vector3(0.045, -0.035, -0.4)   # where the dart leaves his fingers, from his eyes, as he lets go
const NOMINAL := 0.5                     # the draw of the usual throw
const LOFT_MIN := 6.0
const LOFT_MAX := 28.0
const AIM_K := 0.0011                    # radians of his eyes a pixel of the mouse
const FOCUS := 46.0                      # his eyes on the board: narrower than looking round the room
const FOCUS_HARD := 26.0                 # Shift: narrowed right down on the bed he wants

signal left

var main
var pub: Pub
var view: View
var sim: DartSim
var bodies: Array = []                  # the three house darts in the sim
var nodes: Array = []                   # and drawn
var held: Node3D                        # the one in his hand, riding on his eyes
var to_world := Transform3D()           # the board's frame (DartSim's) to the world
var to_board := Transform3D()
var chalk: Label3D
var active := false
var mode := "practice"                  # practice, clock (round the clock), 501
var rehearsal := false                  # come from the menu, not the night
var body := {}                          # what's in his hands tonight, from the night or the rehearsal

# the throw
var aim_yaw := 0.0
var aim_pitch := 0.0
var shuffle := 0.0                      # along the line, metres, + to his right
var loft := 14.0
var grip := 0.0                         # -1 back at the shaft, +1 up at the point
var drawing := false
var draw := 0.0
var wrist := 0.0                        # sideways in the pull, radians
var drawn_t := 0.0                      # how long he's held it back
var up_t := 0.0                         # how long his arm's been up, aiming, this turn
# his breath
var breath := 0.0                       # its phase
var holding := false
var held_t := 0.0                       # how long it's held
var debt := 0.0                         # air owed: the shake after holding it too long
var gasp := 0.0
var t := 0.0
var shake_off := false               # tests: no tremor, no breath
var cold := 0.0                         # from the door, wearing off
var rng := RandomNumberGenerator.new()
var _ph := [0.0, 0.0, 0.0, 0.0]

# the turn and the game
var next := 0                           # which dart's in his hand: 0, 1, 2; 3 when they're all thrown
var flying := false
var _play_t := 0.0
var _heard_i := 0
var turn_scores: Array = []
var left_501 := 501
var clock_on := 1                       # round the clock: the number he's on
var darts_thrown := 0
var turns := 0
var seen := {}                          # what he's noticed already, so he notices it once
var per_dart := [[], [], []]            # where each house dart's gone, off where he was looking (m)


func setup(m) -> void:
	main = m
	pub = m.pub
	view = m.view
	rng.seed = 1234
	for i in 4:
		_ph[i] = rng.randf() * TAU
	var board: Node3D = (pub.dyn.board_darts as Node).get_parent() as Node3D
	to_world = board.global_transform * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -FACE))
	to_board = to_world.affine_inverse()
	sim = DartSim.new()
	# the house darts: one with its shaft bent, one with a torn flight, one with a heavier barrel
	var a := DartSim.Dart.new()
	a.name = "bent"
	a.bend = Vector3(0.07, 0.025, 0.0)
	var b := DartSim.Dart.new()
	b.name = "torn"
	b.tear = 0.7
	b.tear_dir = Vector3(-1, 0.2, 0).normalized()
	var c := DartSim.Dart.new(21.5, 0.046, 0.0039)
	c.name = "heavy"
	for d in [a, b, c]:
		var bo = sim.add(d)
		bodies.append(bo)
		var n := Node3D.new()
		n.visible = false
		pub.add_child(n)
		_draw_dart(d, n)
		nodes.append(n)
	held = Node3D.new()
	held.visible = false
	view.hands.add_child(held)
	_chalkboard()
	set_process(false)
	set_process_input(false)


# One dart drawn as the sim has it: its balance at the node, its point toward +Z. Each house dart
# has its own flights, worn its own way.
func _draw_dart(d: DartSim.Dart, n: Node3D) -> void:
	var v := Node3D.new()
	v.position = Vector3(0, 0, d.cg)
	v.basis = Basis(Vector3(1, 0, 0), -PI / 2.0)     # the drawing's +Y (point to tail) is the dart's -Z
	n.add_child(v)
	var M: Dictionary = pub.M
	var p: Array = d.parts
	pub._stick(Vector3.ZERO, Vector3(0, p[0][1], 0), 0.0011, M.steel, v, 5)
	pub._stick(Vector3(0, p[1][0], 0), Vector3(0, p[1][1], 0), p[1][2], M.brass, v, 10)
	# grip rings knurled into the barrel: dark bands
	for k in 4:
		var y: float = float(p[1][0]) + 0.009 + k * 0.007
		pub._stick(Vector3(0, y, 0), Vector3(0, y + 0.002, 0), p[1][2] + 0.0002, M.frame, v, 10)
	var tail := Node3D.new()
	tail.position = Vector3(0, p[2][0], 0)
	# a bent shaft leans the shaft and the flights off the line
	tail.rotation = Vector3(d.bend.y, 0, -d.bend.x)
	v.add_child(tail)
	pub._stick(Vector3.ZERO, Vector3(0, p[2][1] - p[2][0], 0), 0.0018, M.black, tail, 6)
	var fl: Material = {"bent": pub.mat(Color("5b2a26"), 0.7), "torn": pub.mat(Color("23374f"), 0.7), "heavy": pub.mat(Color("2b2a27"), 0.7)}.get(d.name, M.dark)
	var fy: float = d.flight_s - float(p[2][0])
	for a in [0.0, 90.0]:
		var w := 0.028
		if d.name == "torn" and a == 0.0:
			# one half of it torn away down to the shaft at the back, the rest curled
			pub.box(Vector3(w * 0.5, d.flight_len, 0.0007), Vector3(w * 0.25, fy, 0), fl, a, tail)
			var curl := pub.box(Vector3(w * 0.35, d.flight_len * 0.55, 0.0007), Vector3(-w * 0.2, fy - d.flight_len * 0.2, 0.002), fl, a, tail)
			curl.rotation.y = deg_to_rad(a + 24.0)
		else:
			pub.box(Vector3(w, d.flight_len, 0.0007), Vector3(0, fy, 0), fl, a, tail)


# The board beside it, painted black, the score in chalk; a stub of chalk on the ledge under it.
func _chalkboard() -> void:
	var at := to_world * Vector3(0.9, -0.1, -0.025)
	var face := to_world.basis * Vector3(0, 0, 1)
	var n := Node3D.new()
	pub.add_child(n)
	n.global_transform = Transform3D(Basis.looking_at(-face, Vector3.UP), at)
	# not quite square on the wall: hung on one nail
	n.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(-1.6))
	pub.box(Vector3(0.46, 0.62, 0.018), Vector3.ZERO, pub.M.frame, 0.0, n)
	pub.box(Vector3(0.42, 0.58, 0.004), Vector3(0, 0, 0.0095), pub.mat(Color("1d1f1c"), 0.95), 0.0, n)
	pub.box(Vector3(0.44, 0.012, 0.03), Vector3(0, -0.31, 0.02), pub.M.frame, 0.0, n)
	pub.box(Vector3(0.03, 0.009, 0.009), Vector3(0.12, -0.3, 0.025), pub.mat(Color("d8d4c6"), 0.95), 8.0, n)
	chalk = Label3D.new()
	chalk.font = Look.font("zilla")
	chalk.font_size = 48
	chalk.pixel_size = 0.0011
	chalk.autowrap_mode = TextServer.AUTOWRAP_WORD
	chalk.width = 340
	chalk.modulate = Color("d9d6cb", 0.9)
	chalk.outline_size = 0
	chalk.position = Vector3(-0.19, 0.27, 0.0125)
	chalk.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	chalk.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	chalk.text = "LEAGUE\nTUES 8PM\n\n(folded)"
	chalk.shaded = false
	n.add_child(chalk)


# ---------------------------------------------------------------- in and out

# Step up to the line. game: practice, clock, 501. from: {"drinks", "hurt", "tension", "clock",
# "cold"} for a rehearsal; in the night, his body as the night has it.
func begin(game_mode := "practice", rehearse := false, from := {}) -> void:
	active = true
	rehearsal = rehearse
	mode = game_mode
	body = from.duplicate()
	if not rehearse:
		body = {"drinks": view.drinks, "hurt": view.hurt, "tension": view.tension, "clock": view.clock, "cold": 0.0}
	cold = float(body.get("cold", 0.0))
	if pub.dyn.get("board_darts") != null:
		(pub.dyn.board_darts as Node3D).visible = false
	if pub.dyn.get("till_darts") != null:
		(pub.dyn.till_darts as Node3D).visible = false
	left_501 = 501
	_rows = []
	clock_on = 1
	darts_thrown = 0
	turns = 0
	turn_scores = []
	shuffle = 0.0
	_collect(true)
	_place_eyes()
	var a := Posts.aim(view.eye_pos, to_world * Vector3(0, 0, 0))
	aim_yaw = a.x
	aim_pitch = a.y
	view.focus_fov = FOCUS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_process(true)
	set_process_input(true)
	_chalk()
	_column_begin()


func end() -> void:
	if not active:
		return
	active = false
	drawing = false
	flying = false
	holding = false
	held.visible = false
	for n in nodes:
		n.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	view.hand_drag = false
	view.focus_fov = 0.0
	set_process(false)
	set_process_input(false)
	# the darts back in the board the way they were, unless the night has them behind the till
	if pub.dyn.get("board_darts") != null and not rehearsal:
		main.pub.set_darts(bool(main.game.get_var("darts_pulled")) if main.game != null and main.game.story != null else false)
	elif pub.dyn.get("board_darts") != null:
		(pub.dyn.board_darts as Node3D).visible = true
	left.emit()


func _place_eyes() -> void:
	view.walking = false
	view.eye_pos = to_world * Vector3(shuffle, EYE_UP, OCHE + 0.03)


# all three back in his hand: he walks up, pulls them, walks back to the line
func _collect(at_once := false) -> void:
	for i in bodies.size():
		var b = bodies[i]
		b.mode = "hand"
		b.depth = 0.0
		b.pos = Vector3(0, 0, 50)
		nodes[i].visible = false
	next = 0
	up_t = 0.0
	turn_scores = []
	held.visible = true
	_hold_drawing()
	if not at_once:
		main.audio.sfx("pocket", 0.5, 1.0)


func _hold_drawing() -> void:
	for c in held.get_children():
		c.queue_free()
	if next < 3:
		var n := Node3D.new()
		held.add_child(n)
		_draw_dart(bodies[next].d, n)
		_no_shadows(n)


func _no_shadows(n: Node) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_no_shadows(c)


# ---------------------------------------------------------------- his body

# How much his hand shakes now, radians at the point: the drink, the hour, a hurt hand, cold, the
# nerves, his arm up too long, his breath held too long.
func shake() -> float:
	if shake_off:
		return 0.0
	var drinks := float(body.get("drinks", 0))
	var hurt := float(body.get("hurt", 0))
	var nerves := float(body.get("tension", 0))
	var hour := float(body.get("clock", 1260))
	var late := clampf((hour - 1380.0) / 180.0, 0.0, 1.2) if hour > 600 else 1.2
	var s := 0.0009
	s += drinks * 0.00045 + maxf(0.0, drinks - 5.0) * 0.0006
	s += hurt * 0.0009
	s += cold * 0.0016
	s += nerves * 0.00035
	s += late * 0.0005
	s += clampf(up_t - 6.0, 0.0, 10.0) * 0.00012       # his arm's been up a while
	s += clampf(drawn_t - 1.6, 0.0, 4.0) * 0.0005      # held back too long
	s += debt * 0.0022
	return s


# its frequency: steady hands shake slow and wide, the nerves fast and fine
func _tremor(at: float) -> Vector2:
	var nerves := float(body.get("tension", 0))
	var f := 8.5 + nerves * 0.9
	var y := sin(at * TAU * f + _ph[0]) * 0.6 + sin(at * TAU * f * 1.37 + _ph[1]) * 0.4
	var x := sin(at * TAU * f * 0.91 + _ph[2]) * 0.6 + sin(at * TAU * f * 1.53 + _ph[3]) * 0.4
	return Vector2(x, y) * shake()


# his breath in his eyes: up and down on it, a little across; held, it settles
func _breath_sway() -> Vector2:
	var drinks := float(body.get("drinks", 0))
	var amp := 0.0035 * (1.0 + drinks * 0.12) + gasp * 0.006
	var calm := 1.0
	if holding:
		calm = lerpf(1.0, 0.08, clampf(held_t / 0.7, 0.0, 1.0))
	var p := sin(breath) * amp * calm
	var y := sin(breath * 0.5 + 1.3) * amp * 0.35 * calm
	return Vector2(y, p)


func _process(dt: float) -> void:
	if not active:
		return
	t += dt
	cold = maxf(0.0, cold - dt / 120.0)
	# breathing: about fourteen a minute, faster with the nerves; held, it waits
	if holding:
		held_t += dt
		if held_t > 4.0:
			debt = minf(1.5, debt + dt * 0.35)
		if held_t > 7.5:
			_breathe_out(true)
	else:
		breath += dt * TAU * (0.23 + float(body.get("tension", 0)) * 0.03 + debt * 0.2)
		debt = maxf(0.0, debt - dt * 0.25)
	gasp = maxf(0.0, gasp - dt * 0.5)
	if next < 3 and not flying:
		up_t += dt
	if drawing:
		drawn_t += dt
	# his eyes: where the player has them, and his breath on them
	var sw := _breath_sway()
	view.yaw = aim_yaw + sw.x
	view.pitch = aim_pitch + sw.y
	view.want_yaw = view.yaw
	view.want_pitch = view.pitch
	_place_eyes()
	# the dart in his hand: up by his eye, the point on the board, shaking; drawn back toward his
	# face as the player pulls
	if held.visible:
		var tr := _tremor(t) * 3.0
		# at rest under his eye, the point on the board; drawn back, the hand comes back by his cheek
		# and the point lifts a little, the way the forearm cocks
		var hp := Vector3(0.04 - draw * 0.01, -0.055 + draw * 0.025, -0.38 + draw * 0.13)
		var aim_lift := deg_to_rad(loft) * 0.3 + draw * 0.12
		held.transform = Transform3D(Basis.from_euler(Vector3(aim_lift + tr.y, tr.x + wrist * 3.0, 0.0)) \
			* Basis(Vector3.UP, PI), hp + Vector3(0, 0, -grip * 0.012))
	view.focus_fov = FOCUS_HARD if Input.is_key_pressed(KEY_SHIFT) else FOCUS
	if flying:
		_play(dt)


func _breathe_out(gasped := false) -> void:
	if not holding:
		return
	holding = false
	if gasped or held_t > 5.0:
		gasp = 1.0
		main.audio.sfx("whisper", 0.25, 0.7)
	held_t = 0.0


# ---------------------------------------------------------------- the player's hands

func _input(e: InputEvent) -> void:
	if not active:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		end()
		return
	if main.menus.is_open():
		return
	if e is InputEventMouseMotion:
		var rel: Vector2 = e.relative
		if drawing:
			draw = clampf(draw + rel.y / 320.0, 0.0, 1.0)
			wrist += rel.x * 0.00028
		else:
			var k := AIM_K * float(main.settings.get("look_speed", 1.0)) * (0.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
			aim_yaw -= rel.x * k
			aim_pitch = clampf(aim_pitch - rel.y * k, -0.5, 0.5)
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		match e.button_index:
			MOUSE_BUTTON_LEFT:
				if e.pressed:
					if next >= 3 and not flying:
						_collect()
					elif not flying and next < 3:
						drawing = true
						draw = 0.0
						wrist = 0.0
						drawn_t = 0.0
						view.hand_drag = true
				elif drawing:
					drawing = false
					view.hand_drag = false
					if draw < 0.06:
						draw = 0.0        # brought it back down: no throw
					else:
						_throw()
			MOUSE_BUTTON_RIGHT:
				if e.pressed:
					if not holding and debt < 0.6:
						holding = true
						held_t = 0.0
				else:
					_breathe_out()
			MOUSE_BUTTON_WHEEL_UP:
				if e.pressed:
					loft = clampf(loft + 1.0, LOFT_MIN, LOFT_MAX)
			MOUSE_BUTTON_WHEEL_DOWN:
				if e.pressed:
					loft = clampf(loft - 1.0, LOFT_MIN, LOFT_MAX)
	elif e is InputEventKey and e.pressed:
		var k: int = e.physical_keycode
		match k:
			KEY_A:
				shuffle = clampf(shuffle - 0.03, -0.45, 0.45)
			KEY_D:
				shuffle = clampf(shuffle + 0.03, -0.45, 0.45)
			KEY_Q:
				grip = clampf(grip - 0.25, -1.0, 1.0)
			KEY_E:
				if next >= 3 and not flying:
					_collect()
				else:
					grip = clampf(grip + 0.25, -1.0, 1.0)
			KEY_SPACE:
				if next >= 3 and not flying:
					_collect()
	# nothing else the keys do in the night happens while he's at the line (a number would pick a
	# choice in the column behind him)
	if e is InputEventKey:
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- the throw

# What the throw is, from what the player did: worked out from his eyes, the draw, the loft, the
# grip and the wrist, and then his tremor at the moment he let go. In the board's frame.
func release_state(dart_i: int, at_t: float) -> Dictionary:
	var d: DartSim.Dart = bodies[dart_i].d
	var cam_b := Basis.from_euler(Vector3(view.pitch, view.yaw, 0.0))
	var eye := view.eye_pos
	var hand_w := eye + cam_b * HAND
	var look := -cam_b.z
	# where his eyes are on the board: the point the usual throw goes to
	var e_b := to_board * eye
	var l_b := (to_board.basis * look).normalized()
	var target := e_b + l_b * (-e_b.z / minf(l_b.z, -0.05))
	var h_b := to_board * hand_w
	# the arm's instinct: the speed that would carry it from his hand to there at this loft (the
	# brain's sum is a plain arc; the air and the dart's own ways are for the player to learn)
	var dv := target - h_b
	var horiz := Vector2(dv.x, dv.z).length()
	var elev := atan2(dv.y, horiz)
	var theta := elev + deg_to_rad(loft)
	var den := 2.0 * pow(cos(theta), 2) * (horiz * tan(theta) - dv.y)
	var v_need := sqrt(9.81 * horiz * horiz / maxf(den, 0.0001))
	var az0 := atan2(dv.x, -dv.z)
	# then the arm's years of it: a plain arc is a little out (the air, the dart turning in it), so
	# it's put right against a sound standard dart thrown clean, the way a man's arm knows a dart.
	# The house darts' own faults aren't in it: those are for the player to find.
	for it in 3:
		var hit = _clean_cross(h_b, v_need, az0, theta)
		if hit == null:
			break
		var err: Vector3 = hit - target
		if Vector2(err.x, err.y).length() < 0.0003:
			break
		# higher than meant: a touch slower; right of it: turn left
		# the height it falls is what the speed buys back: half the fall's change for each part of speed
		var tt := horiz / maxf(v_need * cos(theta), 0.5)
		var fall := 0.5 * 9.81 * tt * tt
		v_need *= 1.0 + err.y / maxf(2.0 * fall, 0.05) * -1.0
		az0 -= err.x / maxf(horiz, 0.5)
	# the draw: halfway back is the usual; more is harder. The heavy one leaves slower for the same arm.
	var v := v_need * (0.82 + 0.36 * draw)
	v *= pow(0.0202 / d.mass, 0.12)
	# the line he throws on: toward the target, turned by the wrist, lifted by the loft; and the shake
	var tr := _tremor(at_t)
	var az := az0 + wrist + tr.x
	var up := theta + tr.y
	var dirv := Vector3(sin(az) * cos(up), sin(up), -cos(az) * cos(up)).normalized()
	# the dart's nose: the grip tips it, and the shake in the fingers turns it a little more
	var nose_off := -grip * deg_to_rad(3.0) + tr.y * 2.5 + deg_to_rad(1.0)
	var right := dirv.cross(Vector3.UP).normalized()
	var nose := dirv.rotated(right, nose_off).rotated(Vector3.UP, tr.x * 2.0)
	var rot := Basis.looking_at(-nose, Vector3.UP)
	var spin := nose * (9.0 + grip * 3.0) + right * (-draw * 1.5)
	# the balance point, not the point, is where the hand lets go
	var at: Vector3 = h_b - nose * (d.length * 0.5 - d.cg)
	return {"at": at, "v": dirv * v, "rot": rot, "spin": spin, "target": target}


# where a clean throw with a sound standard dart crosses the board's face, or null
var _std := DartSim.Dart.new()

func _clean_cross(from: Vector3, v: float, az: float, up: float):
	var s := DartSim.new()
	var b = s.add(_std)
	var dirv := Vector3(sin(az) * cos(up), sin(up), -cos(az) * cos(up)).normalized()
	var rot := Basis.looking_at(-dirv, Vector3.UP)
	s.throw(b, from - dirv * (_std.length * 0.5 - _std.cg), dirv * v, rot, dirv * 9.0)
	for k in 1500:
		s.step()
		if b.crossed != null:
			return b.crossed
		if s.done:
			break
	return null


func _throw() -> void:
	var i := next
	var st := release_state(i, t)
	var b = bodies[i]
	for k in 3:
		if b.has_meta("through_%d" % k):
			b.remove_meta("through_%d" % k)
	sim.throw(b, st.at, st.v, st.rot, st.spin)
	sim.run()
	per_dart[i].append(st.target)
	nodes[i].visible = true
	held.visible = false
	flying = true
	_play_t = 0.0
	_heard_i = 0
	draw = 0.0
	wrist = 0.0
	drawn_t = 0.0
	darts_thrown += 1
	main.audio.sfx("swipe", 0.25, 1.4)


# play the throw back as the sim worked it out, every dart that moved
func _play(dt: float) -> void:
	_play_t += dt
	var fi := int(_play_t * DartSim.FPS)
	var last := true
	for i in bodies.size():
		var b = bodies[i]
		if b.mode == "hand":
			continue
		var fr: Array = b.frames
		if fr.is_empty():
			continue
		var k := mini(fi, fr.size() - 1)
		if fi < fr.size() - 1:
			last = false
		var a: Array = fr[k]
		var bn := Basis(a[1] as Quaternion)
		nodes[i].global_transform = to_world * Transform3D(bn, a[0])
	while _heard_i < sim.hits.size() and float(sim.hits[_heard_i][0]) <= _play_t:
		_sound(sim.hits[_heard_i])
		_heard_i += 1
	if last:
		flying = false
		_landed(next)
		next += 1
		up_t = 0.0
		if next < 3:
			held.visible = true
			_hold_drawing()
		else:
			_turn_over()


func _sound(h: Array) -> void:
	var where: Vector3 = to_world * (h[4] as Vector3)
	var s := clampf(float(h[3]) / 6.0, 0.15, 1.0)
	match str(h[2]):
		"sisal": main.audio.at("thud", where, 0.55 * s, 1.5, 1.6)
		"wire": main.audio.at("clink", where, 0.7 * s, 1.5, 1.9)
		"wood": main.audio.at("tock", where, 0.6 * s, 1.5, 1.1)
		"plaster": main.audio.at("tock", where, 0.45 * s, 1.5, 0.8)
		"carpet": main.audio.at("thump", where, 0.3 * s, 1.5, 1.5)
		"dart": main.audio.at("clack", where, 0.5 * s, 1.5, 1.8)
		"flight": main.audio.at("tear", where, 0.35, 1.5, 1.6)
		"robin": main.audio.at("clack", where, 0.8, 1.5, 0.9)
		"out": main.audio.at("thump", where, 0.15, 1.5, 2.0)


# ---------------------------------------------------------------- the game

func _landed(i: int) -> void:
	var b = bodies[i]
	var r: Dictionary = sim.result(b)
	var heard: Array = sim.hits.filter(func(h): return int(h[1]) == i).map(func(h): return str(h[2]))
	var knocked := []
	for k in bodies.size():
		if k != i and "out" in sim.hits.filter(func(h): return int(h[1]) == k).map(func(h): return str(h[2])):
			knocked.append(k)
	# what it scored
	var sc := 0
	if r.where == "board":
		sc = int(r.n) * int(r.x)
	turn_scores.append(r)
	match mode:
		"clock":
			if r.where == "board" and ((clock_on <= 20 and int(r.n) == clock_on) or (clock_on == 21 and int(r.n) == 25)):
				clock_on += 1
		"501":
			pass
	_notice(i, r, heard, knocked)
	_chalk()


# the 501 column as it's chalked: each score left, the old ones struck through (shown as a dash)
var _rows: Array = []

func _501_rows() -> Array:
	var r := _rows.slice(maxi(0, _rows.size() - 6))
	var outr := []
	for k in r.size():
		outr.append(("—" if k < r.size() - 1 else "") + str(r[k]))
	return outr


func _turn_over() -> void:
	turns += 1
	if mode == "501":
		var total := 0
		var last_double := false
		var bust := false
		var left := left_501
		for r in turn_scores:
			if r.where != "board":
				continue
			var s := int(r.n) * int(r.x)
			left -= s
			last_double = int(r.x) == 2
			if left < 0 or left == 1 or (left == 0 and not last_double):
				bust = true
				break
			if left == 0:
				break
		if not bust:
			left_501 = left
		_rows.append(left_501)
		_line("Bust." if bust else ("Game shot." if left_501 == 0 else ""))
	_chalk()


# The chalk: whatever game it is, in his hand, the way a man keeps score on a blackboard.
func _chalk() -> void:
	if chalk == null:
		return
	var marks := []
	for r in turn_scores:
		if r.where == "board":
			var n := "BULL" if int(r.n) == 25 and int(r.x) == 2 else ("25" if int(r.n) == 25 else ("%s%d" % [["", "", "D", "T"][int(r.x)], int(r.n)]))
			marks.append(n)
		else:
			marks.append("-")
	match mode:
		"501":
			chalk.text = "501\n%s\n\n%s" % ["\n".join(_501_rows()), "  ".join(marks)]
		"clock":
			chalk.text = "ROUND THE\nCLOCK\n\non %s\n%d darts" % ["BULL" if clock_on == 21 else ("DONE" if clock_on > 21 else str(clock_on)), darts_thrown]
		_:
			chalk.text = "%s\n\n%s" % ["PRACTICE" if rehearsal else "", "  ".join(marks)]


# ---------------------------------------------------------------- what he notices

func _column_begin() -> void:
	if main.column == null:
		return
	main.column.begin_batch()
	if rehearsal:
		main.column.reset()
		main.column.add_line({"role": "narration", "text": "The board on the east wall in its cabinet, the doors open, the lamp on its arm over it, left on since the league folded. The line on the carpet, taped, the tape lifting at one end."})
	else:
		main.column.add_line({"role": "narration", "text": "He took the three darts out of the board and went back to the line."})
	var how := {"practice": "Throwing for nothing.", "clock": "Round the clock: one to twenty, then the bull.", "501": "Five-oh-one, on his own, finishing on a double."}
	main.column.add_note(str(how.get(mode, "")) + "\nLook with the mouse. Hold the button and pull back to draw; let go to throw. The wheel lifts the elbow, Q and E move the grip, A and D move along the line, the right button holds his breath. Esc puts them down.")
	main.column.scroll_to_end()


func _line(text: String) -> void:
	if text == "" or main.column == null:
		return
	main.column.begin_batch()
	main.column.add_line({"role": "narration", "text": text})
	main.column.scroll_to_end()


func _once(key: String, text: String) -> void:
	if seen.has(key):
		return
	seen[key] = true
	_line(text)


func _notice(i: int, r: Dictionary, heard: Array, knocked: Array) -> void:
	var d: DartSim.Dart = bodies[i].d
	if "robin" in heard:
		_once("robin", "Straight into the back of the other one, down the shaft. Nobody saw it.")
		return
	if knocked.size() > 0:
		if r.where == "carpet":
			_line("It hit the one already there and knocked it out. Both on the carpet.")
		else:
			_line("It knocked the other one out of the board.")
		return
	if "flight" in heard:
		_once("flight", "Through the flight of the one already in.")
	if r.where == "carpet":
		if "out" in heard:
			var from := Vector3.ZERO
			for h in sim.hits:
				if int(h[1]) == i and str(h[2]) == "out":
					from = h[4]
			var in20: bool = from.y > 0.08 and absf(from.x) < 0.03
			if in20:
				_once("fell_20", "It hung a second in the twenty and let go. That bed was chewed to nothing, years of everyone aiming at it.")
			else:
				_once("fell", "It hung there a second and dropped.")
		elif "wire" in heard and not ("sisal" in heard):
			_once("bounce", "Off the wire, and back at him across the carpet.")
		elif "plaster" in heard:
			_once("wall", "Into the plaster beside the cabinet. There were other holes there.")
		return
	# learning the darts: after a few, where each one tends to go
	var at: Vector3 = r.get("at", Vector3.ZERO)
	var tgt: Vector3 = per_dart[i][per_dart[i].size() - 1]
	bodies[i].set_meta("miss_%d" % per_dart[i].size(), Vector2(at.x - tgt.x, at.y - tgt.y))
	if per_dart[i].size() >= 3:
		var sum := Vector2.ZERO
		for k in range(per_dart[i].size() - 2, per_dart[i].size() + 1):
			sum += bodies[i].get_meta("miss_%d" % k, Vector2.ZERO)
		sum /= 3.0
		if sum.length() > 0.025:
			var way := "low" if absf(sum.y) > absf(sum.x) and sum.y < 0 else ("high" if absf(sum.y) > absf(sum.x) else ("left" if sum.x < 0 else "right"))
			var which: String = {"bent": "the one with the red flights", "torn": "the one with the torn flight", "heavy": "the heavy one"}.get(d.name, "that one")
			_once("learn_%s" % d.name, "%s goes %s. Every time." % [which.capitalize(), way])
