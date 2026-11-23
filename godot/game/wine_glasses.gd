# The wine glasses on the bar: eight of them, a mismatched set, kept for the one woman a year who
# orders wine, standing upside down on a bar towel in the gap until he turns them over. The
# water jug's behind them. A wet finger round a rim makes a glass sing; water in it brings it
# down; a stir stick on it rings it. That's an instrument, and people have played it in bars as
# long as there have been bars and glasses (Gluck did it for money, in London, in 1746).
#
# His hand, on the mouse (captured, like the darts and the mats): it moves over the bar top. The
# button held puts the fingertip down: on a rim it rubs, and the rub is the physics in
# game/glass_synth.gd, the speed round the rim and how hard he leans (Shift) against how wet his
# finger is; in a glass with water in it, it wets the finger; anywhere else it's the bar. The other
# button held pours from the jug into the glass under his hand, and the note of the air in the
# glass climbs as it fills. The wheel is the fine tuning: a splash in, or a sip tipped out into the
# drip tray. A S D F G H J K tap the glasses with a stir stick, Shift harder.
#
# Jim's clip-on tuner (he's a drummer; drummers tune) is on the jug's handle, and it reads
# whichever glass his hand's over. The rest is ears.
class_name WineGlasses
extends Node

const AT := Vector3(1.88, 1.12, 5.0)        # the middle of them: the bar top in the gap across from the taps, where staff stand
const STEP := 0.0857                        # two staggered rows, low on his left to high on his right, the way a keyboard goes
const N := 8
const RIM := 0.036                          # a rim's radius
const BOWL_R0 := 0.021                      # the bowl's bottom
const BOWL_H := 0.09
const BOWL_Y := 0.08                        # where the bowl starts, up the stem
const JUG := Vector3(1.66, 1.12, 5.0)
const KEYS := [KEY_A, KEY_S, KEY_D, KEY_F, KEY_G, KEY_H, KEY_J, KEY_K]
const K_HAND := 0.00042                     # metres of hand a pixel of the mouse
const POUR_ML := 45.0                       # what the jug gives, a second, held over
const NOTES := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
# each glass empty: what it rang at when it was made, more or less; none of them match
const EMPTY := [791.0, 826.0, 884.0, 929.0, 995.0, 1041.0, 1116.0, 1170.0]

signal left

var main
var pub: Pub
var view: View
var synth: GlassSynth
var active := false
var rehearsal := false
var body := {}
var t := 0.0
var seen := {}
var _saved := {}
var _ph := [0.0, 0.0]

var fill := []                              # each glass: 0..1 of the bowl's height
var finger := Vector2.ZERO                  # his fingertip over the bar top (x, z)
var finger_v := Vector2.ZERO
var _fv: Array = []
var _moved := 0.0                           # since the last mouse movement
var down := false                           # the button: the fingertip down
var lean := false                           # Shift: leaning on it
var pouring := false
var wet := 0.0
var on := -1                                # the glass he's rubbing
var over := -1                              # the glass his hand's over
var jug_ml := 1400.0

var glasses: Array = []                     # each glass's node
var liquid: Array = []                      # each glass's water (MeshInstance3D, CylinderMesh)
var surface: Array = []                     # each water's top, shimmering when it sings
var jug: Node3D
var jug_water: MeshInstance3D
var stream: MeshInstance3D
var hand_node: Node3D
var hover_label: Label
var hand_roll := 180.0            # palm down, the fingers out over the glasses


func setup(m) -> void:
	main = m
	pub = m.pub
	view = m.view
	var r := RandomNumberGenerator.new()
	r.seed = 1746
	_ph = [r.randf() * TAU, r.randf() * TAU]
	var glass_m := pub.glass(Color("c9d4d8"), 0.34)
	var rim_m := pub.glass(Color("eef4f5"), 0.75)
	var water_m := pub.glass(Color("9fb4bc"), 0.4)
	# the bar towel they stand on, folded, gone grey
	var towel := pub.box(Vector3(0.34, 0.004, 0.74), AT + Vector3(0.0, 0.002, 0.0), pub.mat(Color("b9b4a6"), 1.0, 0.0, 3), 1.5)
	towel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in N:
		fill.append(0.0)
		var g := Node3D.new()
		pub.add_child(g)
		g.position = pos_of(i) + Vector3(r.randf_range(-0.006, 0.006), 0.0, 0.0)
		g.rotation.y = r.randf_range(-PI, PI)
		pub.cyl(0.033, 0.034, 0.004, Vector3(0, 0.006, 0), glass_m, g, 18)                       # the foot
		pub.cyl(0.0035, 0.0045, BOWL_Y - 0.004, Vector3(0, 0.004 + (BOWL_Y - 0.004) / 2.0 + 0.004, 0), glass_m, g, 8)
		var bowl := pub.cyl(RIM, BOWL_R0, BOWL_H, Vector3(0, BOWL_Y + BOWL_H / 2.0, 0), glass_m, g, 22)
		bowl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = RIM - 0.0012
		tm.outer_radius = RIM + 0.0006
		tm.rings = 28
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = rim_m
		ring.position = Vector3(0, BOWL_Y + BOWL_H, 0)
		g.add_child(ring)
		var w := pub.cyl(BOWL_R0, BOWL_R0, 0.001, Vector3(0, BOWL_Y, 0), water_m, g, 20)
		w.visible = false
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		liquid.append(w)
		var sm := pub.glow(Color("dfe8ea"), 0.0)
		var top := pub.cyl(BOWL_R0, BOWL_R0, 0.0006, Vector3(0, BOWL_Y, 0), sm, g, 20)
		top.visible = false
		surface.append(top)
		glasses.append(g)
	# the jug, behind them, with the tuner clipped to its handle
	jug = Node3D.new()
	pub.add_child(jug)
	jug.position = JUG
	var jb := pub.cyl(0.058, 0.064, 0.2, Vector3(0, 0.1, 0), glass_m, jug, 20)
	jb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pub.box(Vector3(0.016, 0.13, 0.02), Vector3(0.0, 0.11, -0.075), glass_m, 0.0, jug)        # the handle
	pub.box(Vector3(0.03, 0.02, 0.025), Vector3(0.0, 0.205, 0.06), glass_m, 0.0, jug)          # the lip
	jug_water = pub.cyl(0.055, 0.06, 0.15, Vector3(0, 0.08, 0), water_m, jug, 20)
	jug_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tuner := pub.box(Vector3(0.028, 0.034, 0.012), Vector3(0.0, 0.17, -0.09), pub.M.black, 0.0, jug)
	tuner.rotation.x = -0.3
	var scr := pub.glow(Color("b8c9a8"), 0.35)
	pub.box(Vector3(0.02, 0.014, 0.002), Vector3(0.0, 0.175, -0.0965), scr, 0.0, jug).rotation.x = -0.3
	stream = pub.cyl(0.0022, 0.0028, 1.0, Vector3.ZERO, water_m, pub, 6)
	stream.visible = false
	pub.anchors["wine_glasses"] = AT + Vector3(0.04, 0.17, 0.0)
	synth = GlassSynth.new()
	add_child(synth)
	synth.setup()
	for i in N:
		synth.set_glass(i, EMPTY[i], 0.0004 + 0.0003 * r.randf(), (float(i) / (N - 1) - 0.5) * 1.2)
	hover_label = UiBits.label("", "ui", 18, Look.INK_2)
	hover_label.visible = false
	hover_label.z_index = 20
	main.root.add_child(hover_label)
	set_process(false)
	set_process_input(false)


func pos_of(i: int) -> Vector3:
	return Vector3(1.96 if i % 2 == 0 else 1.80, AT.y, AT.z + 0.3 - i * STEP)


func centre(i: int) -> Vector2:
	var p := (glasses[i] as Node3D).position
	return Vector2(p.x, p.z)


# ---------------------------------------------------------------- in and out

func begin(rehearse := false, from := {}) -> void:
	active = true
	rehearsal = rehearse
	body = from.duplicate()
	if not rehearse:
		body = {"drinks": view.drinks, "hurt": view.hurt, "tension": view.tension, "clock": view.clock, "cold": 0.0}
	_saved = {"eye": view.eye_pos, "yaw": view.yaw, "pitch": view.pitch}
	view.walking = false
	view.focus_fov = 50.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	finger = centre(3) + Vector2(0.06, 0.0)
	down = false
	pouring = false
	_hand_build()
	synth.start()
	set_process(true)
	set_process_input(true)
	_column_begin()
	if "keys" in main and main.keys != null:
		main.keys.show_for("glasses", [
			["Mouse", "his hand over the bar top"],
			["Hold the button on a rim, go round", "rub it: it sings; faster is louder, too fast skates"],
			["Shift", "lean on it"],
			["Button down in water", "wet the finger (a dry one squeaks)"],
			["Hold the right button", "pour from the jug into the glass under his hand"],
			["Wheel", "a splash in, a sip out: more water, lower note"],
			["A S D F G H J K", "tap them with a stir stick  (Shift: harder)"],
		], "The wine glasses")


func end() -> void:
	if not active:
		return
	active = false
	down = false
	pouring = false
	synth.pour = 0.0
	if on >= 0:
		synth.set_finger(on, 0.0, 0.0, wet)
	on = -1
	stream.visible = false
	jug.position = JUG
	jug.rotation = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	view.focus_fov = 0.0
	hover_label.visible = false
	if "keys" in main and main.keys != null:
		main.keys.hide_card()
	if hand_node != null:
		hand_node.visible = false
	set_process_input(false)
	if not rehearsal:
		view.eye_pos = _saved.get("eye", view.eye_pos)
		view.yaw = _saved.get("yaw", view.yaw)
		view.pitch = _saved.get("pitch", view.pitch)
		view.want_yaw = view.yaw
		view.want_pitch = view.pitch
	# the glasses ring on after he's gone, and then it stops
	get_tree().create_timer(6.0).timeout.connect(func():
		if not active:
			synth.stop()
			set_process(false))
	left.emit()


func _hand_build() -> void:
	if hand_node != null:
		hand_node.visible = true
		return
	hand_node = Node3D.new()
	pub.add_child(hand_node)
	var h: Node3D = pub.model("res://models/people/his_right_palm.glb", Vector3.ZERO, hand_node)
	h.name = "palm"


# ---------------------------------------------------------------- every frame

func _process(dt: float) -> void:
	t += dt
	if not active:
		return
	_moved += dt
	if _moved > maxf(0.05, dt * 2.5):
		finger_v = finger_v.move_toward(Vector2.ZERO, dt * 6.0)
	var tr := _tremor()
	var f := finger + tr
	over = _over(f)
	# the fingertip down: on a rim it rubs; in water it wets; the rim pulls a finger round it a
	# little, the way a rim does, so a circle that's nearly round stays on
	var was := on
	on = -1
	if down and over >= 0:
		var c := centre(over)
		var d := f.distance_to(c)
		if absf(d - RIM) < 0.009:
			on = over
			var dir := (f - c) / maxf(d, 0.0001)
			finger = finger.lerp(c + dir * RIM - tr, 1.0 - exp(-dt * 10.0))
			var tang := Vector2(-dir.y, dir.x)
			var vt := absf(finger_v.dot(tang))
			synth.set_finger(on, vt, 1.8 if lean else 1.0, wet)
			wet = maxf(0.0, wet - vt * dt / 8.0)
			if was != on:
				synth.tap(on, 0.06, 0.05)
				_once("rub", "He put his fingertip on the rim and drew it round, and the glass took hold of it.")
			if wet < 0.25:
				_once("dry", "It squeaked. His finger had gone dry.")
	if was >= 0 and was != on:
		synth.set_finger(was, 0.0, 0.0, wet)
	# the jug: over the glass, tipped, a thread of water into it
	var into := over if pouring and over >= 0 and jug_ml > 0.0 else -1
	if into >= 0:
		var c3 := pos_of(into)
		jug.position = jug.position.lerp(Vector3(c3.x - 0.1, 1.12 + 0.2, c3.z), 1.0 - exp(-dt * 8.0))
		jug.rotation.z = lerp_angle(jug.rotation.z, -1.05, 1.0 - exp(-dt * 6.0))
		jug.rotation.y = lerp_angle(jug.rotation.y, PI / 2.0, 1.0 - exp(-dt * 8.0))
		var tipped := absf(jug.rotation.z) > 0.9
		if tipped:
			var ml := POUR_ML * minf(dt, 0.05)
			jug_ml = maxf(0.0, jug_ml - ml)
			_add_ml(into, ml)
		synth.pour = 0.7 if tipped else 0.0
		synth.pour_into = into
		var lip: Vector3 = jug.global_transform * Vector3(0.0, 0.205, 0.07)
		var surf := c3 + Vector3(0, BOWL_Y + fill[into] * BOWL_H, 0)
		stream.visible = tipped
		if tipped:
			var mid := (lip + surf) / 2.0
			var ln := maxf(0.01, lip.distance_to(surf))
			(stream.mesh as CylinderMesh).height = ln
			stream.global_transform = Transform3D(Basis.looking_at(surf - lip, Vector3.FORWARD) * Basis(Vector3.RIGHT, PI / 2.0), mid)
	else:
		synth.pour = 0.0
		stream.visible = false
		jug.position = jug.position.lerp(JUG, 1.0 - exp(-dt * 6.0))
		jug.rotation = jug.rotation.lerp(Vector3.ZERO, 1.0 - exp(-dt * 6.0))
	jug_water.scale.y = maxf(0.02, jug_ml / 1400.0)
	jug_water.position.y = 0.005 + 0.075 * jug_water.scale.y
	# the water's top shivers with the glass when it sings
	for i in N:
		var a: float = (synth.glasses[i] as GlassSynth.Glass).amp
		var sm: ShaderMaterial = (surface[i] as MeshInstance3D).material_override
		sm.set_shader_parameter("emission_energy", minf(1.2, a * 3.0))
		(surface[i] as MeshInstance3D).position.y = BOWL_Y + fill[i] * BOWL_H + 0.0004 + sin(t * 97.0 + i) * a * 0.0006
	_eyes(dt)
	_draw_hand(f)
	_tuner()


func _over(f: Vector2) -> int:
	var best := -1
	var bd := RIM + 0.012
	for i in N:
		var d := f.distance_to(centre(i))
		if d < bd:
			bd = d
			best = i
	return best


# the bowl's a cone: water in it climbs slower as it widens
func _r_at(h: float) -> float:
	return BOWL_R0 + (RIM - BOWL_R0) * clampf(h / BOWL_H, 0.0, 1.0)


func _add_ml(i: int, ml: float) -> void:
	var h: float = fill[i] * BOWL_H
	var r := _r_at(h)
	h += ml * 1e-6 / (PI * r * r)
	_set_fill(i, h / BOWL_H)
	if fill[i] >= 0.999 and ml > 0.0:
		_once("over", "It ran over the rim and down the stem onto the towel.")


func _set_fill(i: int, f: float) -> void:
	fill[i] = clampf(f, 0.0, 1.0)
	synth.set_fill(i, fill[i])
	var w: MeshInstance3D = liquid[i]
	var h: float = fill[i] * BOWL_H
	w.visible = h > 0.0008
	(surface[i] as MeshInstance3D).visible = w.visible
	if w.visible:
		var cm := w.mesh as CylinderMesh
		cm.top_radius = _r_at(h) - 0.0012
		cm.bottom_radius = BOWL_R0 - 0.001
		cm.height = h
		w.position.y = BOWL_Y + h / 2.0
		var top: MeshInstance3D = surface[i]
		(top.mesh as CylinderMesh).top_radius = _r_at(h) - 0.0012
		(top.mesh as CylinderMesh).bottom_radius = _r_at(h) - 0.0012


func _tremor() -> Vector2:
	var drinks := float(body.get("drinks", 0))
	var nerves := float(body.get("tension", 0))
	var s := 0.0002 + drinks * 0.0006 + nerves * 0.0004 + float(body.get("hurt", 0)) * 0.0005
	var f := 7.0 + nerves
	return Vector2(sin(t * TAU * f + _ph[0]), sin(t * TAU * f * 1.37 + _ph[1])) * s


func _eyes(dt: float) -> void:
	var mid := AT
	var at := mid + Vector3(0.6, 0.64, 0.05)
	var look := mid + Vector3(-0.02, 0.02, 0.0)
	# leaning a little toward the hand
	var lean_z := clampf(finger.y - mid.z, -0.5, 0.5)
	at.z += lean_z * 0.25
	look.z += lean_z * 0.55
	var drinks := float(body.get("drinks", 0))
	look += Vector3(0, sin(t * 0.9) * 0.003 * drinks, cos(t * 0.7) * 0.003 * drinks)
	var k := 1.0 - exp(-dt * 4.0)
	view.eye_pos = view.eye_pos.lerp(at, k) if view.eye_pos.distance_to(at) < 3.0 else at
	var a := Posts.aim(view.eye_pos, look)
	view.yaw = lerp_angle(view.yaw, a.x, k)
	view.pitch = lerpf(view.pitch, a.y, k)
	view.want_yaw = view.yaw
	view.want_pitch = view.pitch


# his hand, palm down over the bar, the forefinger's tip where the mouse has it; down on a rim it
# sits at the rim's height, up it hovers a couple of centimetres over everything
func _draw_hand(f: Vector2) -> void:
	if hand_node == null:
		return
	var y := 1.12 + BOWL_Y + BOWL_H + 0.03
	if down:
		if on >= 0:
			y = 1.12 + BOWL_Y + BOWL_H + 0.002
		elif over >= 0 and f.distance_to(centre(over)) < RIM - 0.006:
			y = 1.12 + BOWL_Y + maxf(0.004, fill[over] * BOWL_H - 0.006)
		elif over < 0:
			y = 1.125
	# the arm comes in from his right shoulder, over the bar's edge, not straight at his eyes
	var yaw := deg_to_rad(68.0)
	var b := Basis(Vector3.UP, PI / 2.0 + yaw) * Basis(Vector3(0, 0, 1), deg_to_rad(hand_roll))
	var tip := Vector3(f.x, y, f.y)
	var cur := hand_node.global_transform.origin
	var want := tip + Basis(Vector3.UP, yaw) * Vector3(0.13, 0.012, 0.0)
	hand_node.global_transform = Transform3D(b, cur.lerp(want, 0.6) if cur.distance_to(want) < 0.5 else want)


# Jim's tuner, reading the glass under his hand
func _tuner() -> void:
	if over < 0:
		hover_label.visible = false
		return
	var f := synth.freq(over)
	var midi := 69.0 + 12.0 * log(f / 440.0) / log(2.0)
	var n := int(round(midi))
	var cents := int(round((midi - n) * 100.0))
	var name: String = NOTES[posmod(n, 12)] + str(n / 12 - 1)
	var how := "in tune" if absf(cents) <= 3 else ("%d cents %s" % [absi(cents), "sharp" if cents > 0 else "flat"])
	hover_label.text = "%s, %s" % [name, how]
	var w := pos_of(over) + Vector3(0, BOWL_Y + BOWL_H + 0.05, 0)
	var p: Vector2 = view.cam.unproject_position(w)
	var sh: Control = view.sheet
	hover_label.position = sh.global_position + p / Vector2(view.eye.size) * sh.size + Vector2(-30, -40)
	hover_label.visible = true


# ---------------------------------------------------------------- his hands

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
		var k := K_HAND * float(main.settings.get("look_speed", 1.0))
		var was := finger
		# he's facing west down the bar: the mouse right is toward the door end, up is away
		finger += Vector2(rel.y, -rel.x) * k
		finger.x = clampf(finger.x, AT.x - 0.2, AT.x + 0.3)
		finger.y = clampf(finger.y, AT.z - 0.42, AT.z + 0.42)
		var dt := maxf(get_process_delta_time(), 1.0 / 240.0)
		_fv.append((finger - was) / dt)
		if _fv.size() > 4:
			_fv.pop_front()
		var v := Vector2.ZERO
		for vv in _fv:
			v += vv
		finger_v = (v / float(_fv.size())).limit_length(3.0)
		_moved = 0.0
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		var mb := e as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				down = mb.pressed
				lean = mb.shift_pressed
				if down:
					_touch()
			MOUSE_BUTTON_RIGHT:
				pouring = mb.pressed
				if pouring and over >= 0 and jug_ml <= 0.0:
					_once("jug_empty", "The jug was empty. (Rehearse it again for a full one; on a shift, there's the tap behind the bar.)")
					if not rehearsal:
						jug_ml = 1400.0
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed and over >= 0:
					_add_ml(over, 4.0)
					synth.pour = 0.4
					synth.pour_into = over
					get_tree().create_timer(0.08).timeout.connect(func(): if not pouring: synth.pour = 0.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed and over >= 0 and fill[over] > 0.0:
					_add_ml(over, -4.0)
					_once("sip", "He tipped a little out into the drip tray.")
	elif e is InputEventKey:
		var ke := e as InputEventKey
		if ke.physical_keycode == KEY_SHIFT:
			lean = ke.pressed
		var i := KEYS.find(ke.physical_keycode)
		if i >= 0 and ke.pressed and not ke.echo:
			synth.tap(i, 0.9 if ke.shift_pressed else 0.5, 1.0)
			_once("tap", "He took a stir stick out of the caddy and tapped along the row with it.")
		get_viewport().set_input_as_handled()


# the fingertip going down: into the water, onto a rim, or on the bar
func _touch() -> void:
	if over < 0:
		return
	var d := (finger + _tremor()).distance_to(centre(over))
	if d < RIM - 0.006:
		if fill[over] > 0.12:
			wet = 1.0
			synth.tap(over, 0.03, 0.02)
			_once("wet", "He dipped his fingertip in the water in the glass.")
		else:
			synth.tap(over, 0.2, 0.15)
			_once("bottom", "He touched the bottom of the bowl. Dry, and it rang a little.")
	elif absf(d - RIM) < 0.009 and wet < 0.1:
		_once("dry_first", "His fingertip squeaked on the rim and the glass didn't want it. Dry.")


# ---------------------------------------------------------------- what he notices

func _column_begin() -> void:
	if main.column == null:
		return
	main.column.begin_batch()
	if rehearsal:
		main.column.reset()
		main.column.add_line({"role": "narration", "text": "Eight wine glasses on a bar towel in the gap, kept for the one woman a year who orders wine, none of them from the same set. The water jug behind them, with Jim's clip-on tuner on its handle."})
	else:
		main.column.add_line({"role": "narration", "text": "He turned the wine glasses over on their towel, one by one, and pulled the water jug over."})
	main.column.add_note("The mouse moves his hand over the bar. Hold the button to put his fingertip down: round a rim it rubs, faster is louder, too fast and it skates; Shift leans on it. Down in a glass with water, it wets his finger; a dry finger squeaks. Hold the other button over a glass to pour from the jug; the wheel adds a splash or tips a little out. More water, lower note. A S D F G H J K tap them with a stir stick (Shift harder). The tuner reads the glass under his hand. Esc leaves them.")
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
