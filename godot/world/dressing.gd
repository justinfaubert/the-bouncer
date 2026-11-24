# The set dressing: what's on the walls and the floor that nobody put there on purpose, or did, a
# long time ago. The beer posters gone pale toward the window (BOORS LIGHT, MILDCAT with SHITTY KITTY
# in marker across her shins, LOCHNESS, the Unlucky Lager calendar stopped on March 1998), the tin
# sign, the house's signs and Gary's additions to them, the corkboard by the hall with its flyers,
# the beer clock behind the bar, the blue neon in the window with its H going, the clean glasses
# upside down on the back bar and the racks on the cooler, the glasswasher (world/glasswasher.gd);
# outside, the signs by the door and what's on the gravel; at the Esso, the window full of ads and
# what's round the pumps.
#
# Nothing hangs square: every paper's turned a degree or three, waved, a corner lifting. The
# pictures are tools/dressing.py's. Its own dice, so nothing else in the building moves. Built by
# Pub.build after the room's things. Claude's, all of it.
class_name Dressing
extends Node3D

var pub: Pub
var rng := RandomNumberGenerator.new()
var washer: Glasswasher
var _mats := {}
var _trash_tex := {}
var _neon_h: Label3D
var _neon_light: OmniLight3D
var _neon_t := 0.0
var _clock_hands: Array = []      # [hour, minute]
var _marks_node: Node3D
var _back_hands: Array = []       # the hall clock's [hour, minute, second], going the other way


func build(p: Pub) -> void:
	pub = p
	name = "dressing"
	rng.seed = 1996
	_posters()
	_signs()
	_corkboard()
	_clock()
	_neon()
	_glasses()
	washer = Glasswasher.new()
	add_child(washer)
	washer.build(pub)
	_hall()
	_lived_in()
	_outside_signs()
	_lot_trash()
	if pub.town != null:
		_esso()


# ---------------------------------------------------------------- paper

# The material for one of tools/dressing.py's pictures, printed on paper (no strokes cut in it), its
# torn edges cut out.
const PAPER_GLOW := 0.07
# the things on the walls that are there to be read, and half the size of each: a look narrows his
# eyes on it till it fills his sight (game/main.gd, _read_closer)
const READ := {"poster_boors": 0.45, "poster_mildcat": 0.45, "calendar": 0.32, "poster_lochness": 0.38,
	"labutt": 0.24, "corkboard": 0.42, "sign_reserve": 0.2, "sign_forget": 0.18, "beer_clock": 0.2,
	"door_signs": 0.3, "esso_ads": 0.6, "poster_teeth": 0.36, "poster_cokanee": 0.34, "poster_hockey": 0.3,
	"poster_zero": 0.22, "founder": 0.36, "painting_1952": 0.42, "velvet": 0.36, "scrawl": 0.5,
	"hall_clock": 0.18, "table_tents": 0.1}


func paper_mat(t: String) -> ShaderMaterial:
	if _mats.has(t):
		return _mats[t]
	var m := pub.mat(Color(1, 1, 1), 0.85, 0.0, 3, Vector3.UP, 7.0, 0.5)
	m.set_shader_parameter("albedo_tex", pub.tex("res://textures/dress_" + t + ".png"))
	m.set_shader_parameter("alpha_scissor", 0.4)
	# a breath of its own picture, so where the room goes dark the print still holds its shapes
	# (the walls round it go to black; the paper keeps the last of the light, the way paper does)
	m.set_shader_parameter("emission", Color(1, 1, 1))
	m.set_shader_parameter("emission_tex", pub.tex("res://textures/dress_" + t + ".png"))
	m.set_shader_parameter("emission_energy", PAPER_GLOW)
	_mats[t] = m
	return m


# A sheet of paper w x h on a wall at `at`, facing `face`, turned `tilt` degrees: not flat (it waves
# a little across, and `curl` lifts the corner it names, 0 none, 1..4 clockwise from top left),
# a few millimetres off the wall. `m` its material. Lying on the ground with face up, `crumple`
# wrinkles it.
func paper(m: Material, w: float, h: float, at: Vector3, face: Vector3, tilt := 0.0, curl := 0, crumple := 0.0, parent: Node = null) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 8
	var ny := 10
	var corners := [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1)]
	var seed := rng.randf() * 10.0
	var pts := []
	for j in ny + 1:
		var row := []
		for i in nx + 1:
			var u := float(i) / nx
			var v := float(j) / ny
			var x := (u - 0.5) * w
			var y := (0.5 - v) * h
			# the wave across it, and the fold lines from the tube
			var z := 0.0025 * sin(u * 5.0 + seed) * sin(v * 3.0 + seed * 0.7) + 0.0015 * absf(u - 0.5) * 2.0
			if curl > 0:
				var c: Vector2 = corners[curl - 1]
				var d := Vector2((u - 0.5) * 2.0, (0.5 - v) * 2.0).distance_to(c)
				z += pow(maxf(0.0, 1.0 - d / 0.7), 2.0) * minf(w, h) * 0.22
			if crumple > 0.0:
				z += crumple * (sin(u * 13.0 + seed) * cos(v * 11.0 - seed) + 0.6 * sin(u * 29.0 + v * 17.0)) * 0.5
			row.append([Vector3(x, y, z), Vector2(u, v)])
		pts.append(row)
	for j in ny:
		for i in nx:
			var a: Array = pts[j][i]
			var b: Array = pts[j][i + 1]
			var c2: Array = pts[j + 1][i]
			var d2: Array = pts[j + 1][i + 1]
			for tri in [[a, b, c2], [b, d2, c2]]:
				for q in tri:
					st.set_uv(q[1])
					st.add_vertex(q[0])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var b := Basis.looking_at(-face.normalized(), Vector3.UP if absf(face.normalized().y) < 0.9 else Vector3(0, 0, -1))
	b = b * Basis(Vector3(0, 0, 1), deg_to_rad(tilt))
	mi.transform = Transform3D(b, at + face.normalized() * 0.004)
	(parent if parent else self).add_child(mi)
	return mi


func _pin(at: Vector3, face: Vector3, c: Color, parent: Node = null) -> void:
	var p := pub.ball(0.0055, at + face * 0.008, pub.mat(c, 0.35, 0.1, 3), parent if parent else self)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _tilt() -> float:
	return rng.randf_range(-2.6, 2.6)


# ---------------------------------------------------------------- the room's walls

const FRONT := Vector3(0, 0, -1)     # the front wall's inside face, z 10.0
const BACKW := Vector3(0, 0, 1)      # the back wall's, z 0.0
const EAST := Vector3(-1, 0, 0)      # x 16.0
const WEST := Vector3(1, 0, 0)       # x 0.0, behind the bar

func _posters() -> void:
	# MILDCAT on the front wall between the screen and the window, where the door's draught gets it
	paper(paper_mat("mildcat"), 0.6, 0.9, Vector3(4.97, 1.7, 10.0), FRONT, -1.8, 2)
	pub.anchors["poster_mildcat"] = Vector3(4.97, 1.7, 9.99)
	# BOORS LIGHT on the east wall past the deck door, under the sconce, sun-gone at the top
	paper(paper_mat("boors"), 0.6, 0.9, Vector3(16.0, 1.43, 9.3), EAST, 1.4, 0)
	pub.anchors["poster_boors"] = Vector3(15.99, 1.43, 9.3)
	# the Unlucky Lager calendar on the front wall at the east end, under the sconce, on its nail,
	# March 1998
	paper(paper_mat("unlucky"), 0.42, 0.63, Vector3(14.3, 1.5, 10.0), FRONT, 0.9, 0)
	pub.box(Vector3(0.006, 0.006, 0.03), Vector3(14.3, 1.81, 9.985), pub.M.steel, 0.0, self)
	pub.anchors["calendar"] = Vector3(14.3, 1.5, 9.99)
	# LOCHNESS on the back wall in the dart corner, past the jukebox
	paper(paper_mat("lochness"), 0.5, 0.75, Vector3(14.95, 1.78, 0.0), BACKW, -2.2, 1)
	pub.anchors["poster_lochness"] = Vector3(14.95, 1.78, 0.01)
	# the tin sign, on two screws, over the calendar's end of the front wall, a corner out
	var tin := paper(paper_mat("labutt"), 0.48, 0.3, Vector3(15.2, 2.3, 10.0), FRONT, 2.4, 3)
	tin.position += FRONT * 0.004
	pub.anchors["labutt"] = Vector3(15.2, 2.3, 9.99)
	# the ones away from a lamp get a pool of their own, tight to the paper, from somewhere over
	# your shoulder; the wall a foot past the edge stays as dark as it was
	_pool_on(Vector3(4.97, 1.7, 10.0), FRONT, 0.5, 0.75)
	_pool_on(Vector3(14.95, 1.78, 0.0), BACKW, 0.45, 1.3)
	_pool_on(Vector3(15.2, 2.3, 10.0), FRONT, 0.28, 0.7)


# A tight warm pool on a picture on the wall at `at` facing `face`, `r` its half-size: a spot from
# 0.9 out and a little up, no shadow, gone a step past the paper.
func _pool_on(at: Vector3, face: Vector3, r: float, energy: float) -> SpotLight3D:
	var sp := SpotLight3D.new()
	var pos := at + face * 0.9 + Vector3(0, 0.35, 0)
	sp.transform = Transform3D(Basis.looking_at(at - pos, Vector3.UP), pos)
	sp.light_color = Color("ffc98a")
	sp.light_energy = energy
	sp.light_specular = 0.05
	sp.spot_range = 1.6
	sp.spot_angle = rad_to_deg(atan((r + 0.06) / pos.distance_to(at)))
	sp.spot_angle_attenuation = 0.35
	sp.spot_attenuation = 0.6
	add_child(sp)
	pub.lamps.append(sp)        # dims and warms with the room's lamps by the clock
	return sp


func _signs() -> void:
	# over the back bar, above the glasswasher: Gary's terms
	paper(paper_mat("reserve"), 0.42, 0.3, Vector3(0.0, 2.08, 7.18), WEST, -1.2, 0)
	pub.anchors["sign_reserve"] = Vector3(0.01, 2.08, 7.18)
	# over the kitchen door, where the bartender reads it every time he goes through
	paper(paper_mat("forget"), 0.36, 0.3, Vector3(3.25, 2.42, 0.0), BACKW, 1.6, 0)
	pub.anchors["sign_forget"] = Vector3(3.25, 2.42, 0.01)
	_pool_on(Vector3(3.25, 2.42, 0.0), BACKW, 0.2, 0.7)
	# CASH ONLY on the till's front, toward the room, on tape
	paper(paper_mat("cash"), 0.15, 0.1, Vector3(1.93, 1.25, 7.36), Vector3(1, 0, 0), -3.5, 0)


func _corkboard() -> void:
	# on the back wall between the kitchen door and the way to the hall, where everyone passes
	var c := Vector3(4.82, 1.5, 0.0)
	var w := 1.18
	var h := 0.8
	var cork := pub.mat(Color(1, 1, 1), 0.95, 0.0, 3)
	cork.set_shader_parameter("albedo_tex", pub.tex("res://textures/dress_cork.png"))
	cork.set_shader_parameter("mapping", 1)
	cork.set_shader_parameter("tex_size", 0.5)
	var board := Node3D.new()
	board.position = c
	board.rotation.z = deg_to_rad(-0.7)
	add_child(board)
	pub.box(Vector3(w, h, 0.015), Vector3(0, 0, 0.0075), cork, 0.0, board)
	for s in [-1.0, 1.0]:
		pub.box(Vector3(w + 0.05, 0.025, 0.025), Vector3(0, s * (h / 2.0 + 0.0125), 0.0125), pub.M.wood, 0.0, board)
		pub.box(Vector3(0.025, h, 0.025), Vector3(s * (w / 2.0 + 0.0125), 0, 0.0125), pub.M.wood, 0.0, board)
	# the flyers, overlapping, each on a pin (or two, or a staple), the newest on top
	var fly := [["meat", 0.2, 0.245, Vector2(-0.4, 0.17)], ["karaoke", 0.2, 0.236, Vector2(0.36, 0.2)],
		["band", 0.22, 0.3, Vector2(-0.1, 0.1)], ["smoker", 0.21, 0.31, Vector2(0.14, -0.08)],
		["cat", 0.18, 0.295, Vector2(-0.42, -0.12)], ["room", 0.16, 0.208, Vector2(0.42, -0.15)],
		["darlene", 0.21, 0.22, Vector2(-0.19, -0.2)], ["drywall", 0.09, 0.058, Vector2(0.3, 0.02)]]
	var pins := [Color("c8b030"), Color("2a5a8a"), Color("e8e4d8"), Color("3a7a4a"), Color("8a4a8a")]
	var layer := 0.0
	for f in fly:
		layer += 0.0015
		var at := board.to_global(Vector3(f[3].x, f[3].y, 0.016 + layer))
		var m := paper(paper_mat("fly_" + str(f[0])), f[1], f[2], at, BACKW, _tilt() * 1.5, rng.randi_range(0, 4) if rng.randf() < 0.4 else 0)
		m.position.z = 0.016 + layer
		_pin(at + Vector3(0, f[2] / 2.0 - 0.012, 0.0), BACKW, pins[rng.randi() % pins.size()])
	# the sconce is right over it and the light grazes the board: its shadow down the wall below was a
	# striped column of acne, and a board flat on the wall throws next to nothing anyway
	for mi in board.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pub.anchors["corkboard"] = c + Vector3(0, 0, 0.02)


# The beer clock on the west wall over the end of the bar, lit from inside, the face yellowed and the
# flies in the bottom of it. It keeps the bar's time: seven minutes fast, so last call comes early.
func _clock() -> void:
	var at := Vector3(0.0, 2.32, 8.55)
	var n := Node3D.new()
	n.position = at
	n.rotation.y = PI / 2.0
	add_child(n)
	var rim := pub.cyl(0.2, 0.2, 0.07, Vector3(0, 0, 0.035), pub.M.frame, n, 28)
	rim.rotation.x = PI / 2.0
	var face := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.36, 0.36)
	face.mesh = q
	face.position = Vector3(0, 0, 0.0715)
	var fm := pub.glow(Color(1, 1, 1), 0.55)
	fm.set_shader_parameter("albedo", Color(0.9, 0.86, 0.74))
	fm.set_shader_parameter("emission", Color("ffd8a0"))
	fm.set_shader_parameter("emission_tex", pub.tex("res://textures/dress_mildew.png"))
	fm.set_shader_parameter("albedo_tex", pub.tex("res://textures/dress_mildew.png"))
	fm.set_shader_parameter("alpha_scissor", 0.5)
	face.material_override = fm
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(face)
	for k in 2:
		var hand := Node3D.new()
		hand.position = Vector3(0, 0, 0.074 + k * 0.002)
		n.add_child(hand)
		var ln := 0.1 if k == 0 else 0.15
		pub.box(Vector3(0.008 if k == 0 else 0.005, ln, 0.002), Vector3(0, ln / 2.0 - 0.015, 0), pub.M.black, 0.0, hand)
		_clock_hands.append(hand)
	var l := OmniLight3D.new()
	l.position = at + Vector3(0.22, 0, 0)
	l.light_color = Color("ffcf8a")
	l.light_energy = 0.12
	l.omni_range = 0.9
	add_child(l)
	pub.anchors["beer_clock"] = at + Vector3(0.06, 0, 0)
	set_clock(1260)


# The bar's time on the clock: the minutes since midnight of the night's day (game time), seven
# fast.
func set_clock(minutes: int) -> void:
	if _clock_hands.is_empty():
		return
	var m := float((minutes + 7) % 1440)
	(_clock_hands[0] as Node3D).rotation.z = -TAU * fmod(m / 60.0, 12.0) / 12.0
	(_clock_hands[1] as Node3D).rotation.z = -TAU * fmod(m, 60.0) / 60.0
	if _back_hands.size() == 3:
		var b := float(minutes % 1440)
		(_back_hands[0] as Node3D).rotation.z = TAU * fmod(b / 60.0, 12.0) / 12.0
		(_back_hands[1] as Node3D).rotation.z = TAU * fmod(b, 60.0) / 60.0


# The neon in the front window, BOORS LIGHT in blue, to the lot; the H in LIGHT going.
func _neon() -> void:
	var col := Color("58a8ff")
	var x0 := 11.25                 # clear of the window's mullions at 11.0 and 12.6
	var x := x0
	var y := 1.98
	var z := 9.93
	var parts := []
	for s in ["BOORS LIG", "H", "T"]:
		var l := _neon_word(s, Vector3(x, y, z), col)
		parts.append(l)
		x += l.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, l.font_size).x * l.pixel_size
	_neon_h = parts[1]
	# the rail the tubes are wired to (open, so they read from the lot and backwards from in here),
	# the transformer at its end, and its chains from the window's head
	pub.box(Vector3(x - (x0 - 0.1), 0.022, 0.018), Vector3((x + (x0 - 0.1)) / 2.0, y - 0.085, 9.945), pub.M.black, 0.0, self)
	pub.box(Vector3(0.09, 0.06, 0.05), Vector3(x - 0.05, y - 0.13, 9.94), pub.M.black, 0.0, self)
	for cx in [x0 + 0.08, x - 0.18]:
		pub.box(Vector3(0.004, 0.62, 0.004), Vector3(cx, 2.39, 9.955), pub.M.frame, 0.0, self)
	_neon_light = OmniLight3D.new()
	_neon_light.position = Vector3((x + (x0 - 0.1)) / 2.0, y, 9.6)
	_neon_light.light_color = col
	_neon_light.light_energy = 0.25
	_neon_light.omni_range = 2.2
	_neon_light.light_specular = 0.0
	add_child(_neon_light)
	pub.anchors["window_neon"] = Vector3((x + (x0 - 0.1)) / 2.0, y, 9.94)


# A word of the neon: its face to the lot (from inside, its back, backwards).
func _neon_word(s: String, at: Vector3, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font = Look.font("ui_b")
	l.font_size = 96
	l.pixel_size = 0.0016
	l.outline_size = 0
	l.modulate = col
	l.position = at
	l.double_sided = true
	l.shaded = false
	# drawn with the solid things: left in the see-through pass, the window glass in front of it hid
	# it from the lot
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.set_meta("lit", col)
	add_child(l)
	return l


func _process(dt: float) -> void:
	if _back_hands.size() == 3:
		(_back_hands[2] as Node3D).rotation.z += TAU / 60.0 * dt
	if _neon_h == null:
		return
	# the H: on, mostly; a stutter now and then, a few seconds dark once in a while
	_neon_t -= dt
	if _neon_t <= 0.0:
		var r := randf()
		var lit := r > 0.18
		_neon_h.modulate = (_neon_h.get_meta("lit") as Color) if lit else Color(0.12, 0.16, 0.22)
		_neon_t = randf_range(0.04, 0.12) if r < 0.5 else randf_range(1.5, 7.0)


# ---------------------------------------------------------------- glasses

# The clean pints upside down on the rubber mat on the back bar, three rows deep, a stack of four
# nested by the till; two racks of spares on top of the cooler at the far end.
func _glasses() -> void:
	var matm := pub.mat(Color("1d1c1e"), 0.8, 0.0, 1, Vector3(0, 0, 1), 6.0, 0.3)
	pub.box(Vector3(0.32, 0.008, 0.6), Vector3(0.27, 0.955, 6.26), matm)
	for i in 3:
		for j in 6:
			if i == 2 and j == 4:
				continue          # one's out
			var at := Vector3(0.15 + i * 0.105 + rng.randf_range(-0.008, 0.008), 0.959, 6.02 + j * 0.095 + rng.randf_range(-0.008, 0.008))
			var g := pub.cyl(0.034, 0.042, 0.15, at + Vector3(0, 0.075, 0), pub.M.pint, null, 12)
			g.rotation = Vector3(rng.randf_range(-0.02, 0.02), 0, rng.randf_range(-0.02, 0.02))
	# nested, the way they stack, each a little proud of the one under
	for k in 4:
		pub.cyl(0.042, 0.034, 0.15, Vector3(1.97, 1.12 + 0.075 + k * 0.024, 7.62), pub.M.pint, null, 12)
	# the racks on the cooler: grey grids with the glasses' shapes in them
	var grey := pub.mat(Color("4e5a64"), 0.7, 0.0, 3)
	for k in 2:
		var y := 2.1 + k * 0.105
		var rk := Node3D.new()
		rk.position = Vector3(0.31, y, 0.72 + k * 0.03)
		rk.rotation.y = deg_to_rad(rng.randf_range(-6, 6))
		add_child(rk)
		for s in [-1.0, 1.0]:
			pub.box(Vector3(0.5, 0.1, 0.01), Vector3(0, 0.05, s * 0.25), grey, 0.0, rk)
			pub.box(Vector3(0.01, 0.1, 0.5), Vector3(s * 0.25, 0.05, 0), grey, 0.0, rk)
		if k == 1:
			for i in 4:
				for j in 4:
					pub.cyl(0.034, 0.042, 0.15, Vector3(-0.18 + i * 0.12, 0.08, -0.18 + j * 0.12), pub.M.pint, rk, 10)
	pub.anchors["clean_glasses"] = Vector3(0.27, 1.05, 6.26)


# ---------------------------------------------------------------- the back hall

# A hole punched in the plaster of the hall side of the bar's back wall, at about a fist's height on
# a big man, a beer mat taped over half of it; Darrell's card is on the corkboard.
func _hall() -> void:
	var at := Vector3(9.3, 1.38, -0.2)
	var face := Vector3(0, 0, -1)
	var n := Node3D.new()
	add_child(n)
	var hole := pub.cyl(0.07, 0.05, 0.02, at + Vector3(0, 0, 0.008), pub.mat(Color("141210"), 0.95, 0.0, 3), n, 9)
	hole.rotation.x = PI / 2.0
	hole.scale = Vector3(1.0, 1.0, 0.8)
	# the paper face of the board torn back round it
	for k in 7:
		var a := TAU * k / 7.0 + rng.randf_range(-0.2, 0.2)
		var f := pub.box(Vector3(0.03, 0.018, 0.002), at + Vector3(cos(a) * 0.075, sin(a) * 0.06, -0.003), pub.M.plain, 0.0, n)
		f.rotation = Vector3(rng.randf_range(-0.6, 0.6), 0, a)
	var beer := pub.box(Vector3(0.1, 0.1, 0.003), at + Vector3(0.05, 0.01, -0.008), _cell_mat(0, 0.9, 0.0), 0.0, n)
	beer.rotation = Vector3(0, 0, deg_to_rad(12.0))
	for t in [[Vector3(0.05, 0.065, -0.01), 0.0], [Vector3(0.05, -0.045, -0.01), 0.0]]:
		var tp := pub.box(Vector3(0.07, 0.018, 0.002), at + t[0], pub.mat(Color("c8a868"), 0.8, 0.0, 3), 0.0, n)
		tp.rotation.z = deg_to_rad(rng.randf_range(-12, 12))
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = 1 << (Pub.HALL_LAYER - 1)
	pub.anchors["wall_hole"] = at + Vector3(0, 0, -0.02)


# ---------------------------------------------------------------- the second layer

# What thirty years leave on a room that nobody decided on: four more ads in the gaps (ALEXANDER
# TEETH'S, COKANEE, the hockey night with its wings gone up, a BOORS ZERO from a summer that hasn't
# come), the Clam-a-Lot cards on the tables, the rings on the tables and the stain on the ceiling
# and the brown over the big table, the heel marks by the door, stickers where people stood; and the
# things nobody can account for: the founder with no face between the washroom doors, the painting
# of this room in 1952 with a man in a door that wasn't there, Rocco's woman on velvet under a
# blacklight, the hall clock that goes the other way, what's written on the hall wall, the diving
# helmet on the jukebox with a lime in it.
func _lived_in() -> void:
	# the ads, in the gaps between everything else
	paper(paper_mat("teeth"), 0.45, 0.675, Vector3(16.0, 1.5, 8.2), EAST, -1.1, 1)
	pub.anchors["poster_teeth"] = Vector3(15.99, 1.5, 8.2)
	paper(paper_mat("cokanee"), 0.42, 0.63, Vector3(13.25, 1.62, 10.0), FRONT, 1.7, 0)
	pub.anchors["poster_cokanee"] = Vector3(13.25, 1.62, 9.99)
	paper(paper_mat("hockey"), 0.36, 0.5, Vector3(14.1, 1.72, 0.0), BACKW, 2.3, 4)
	pub.anchors["poster_hockey"] = Vector3(14.1, 1.72, 0.01)
	var z := paper(paper_mat("zero"), 0.26, 0.364, Vector3(12.42, 1.58, 0.0), BACKW, -3.4, 2)
	z.position += BACKW * 0.002
	for c in [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		# tape on its corners, gone brown
		var t := pub.box(Vector3(0.04, 0.014, 0.001), z.to_global(Vector3(c.x * 0.12, c.y * 0.17, 0.003)), pub.mat(Color("9a7a3e"), 0.8, 0.0, 3), 0.0, self)
		t.rotation = z.rotation + Vector3(0, 0, c.x * c.y * 0.7)
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pub.anchors["poster_zero"] = Vector3(12.42, 1.58, 0.01)
	_pool_on(Vector3(16.0, 1.5, 8.2), EAST, 0.36, 0.8)
	_pool_on(Vector3(13.25, 1.62, 10.0), FRONT, 0.34, 0.7)
	_pool_on(Vector3(14.1, 1.72, 0.0), BACKW, 0.3, 0.8)
	_pictures()
	_back_clock()
	_scrawl()
	_helmet()
	_tents()
	_marks()
	_stickers()


# A picture in a frame w x h at `at` on a wall facing `face`: the frame `fm`, `d` deep, the picture
# itself flat in it (board or canvas, not paper), a breath of its own light `glow`. The node's
# returned, its z toward the room.
func _framed(t: String, w: float, h: float, at: Vector3, face: Vector3, fm: Material, d: float, glow: float, tilt: float) -> Node3D:
	var n := Node3D.new()
	n.transform = Transform3D(Basis.looking_at(-face, Vector3.UP) * Basis(Vector3(0, 0, 1), deg_to_rad(tilt)), at)
	add_child(n)
	var bw := 0.045
	for s in [-1.0, 1.0]:
		pub.box(Vector3(w + bw * 2.0, bw, d), Vector3(0, s * (h + bw) / 2.0, d / 2.0), fm, 0.0, n)
		pub.box(Vector3(bw, h, d), Vector3(s * (w + bw) / 2.0, 0, d / 2.0), fm, 0.0, n)
	# the backing, so the wall doesn't show round the picture's edge
	pub.box(Vector3(w, h, 0.006), Vector3(0, 0, 0.004), pub.M.black, 0.0, n)
	var m := pub.mat(Color(1, 1, 1), 0.7, 0.0, 3, Vector3.UP, 7.0, 0.3)
	m.set_shader_parameter("albedo_tex", pub.tex("res://textures/dress_" + t + ".png"))
	m.set_shader_parameter("emission", Color(1, 1, 1))
	m.set_shader_parameter("emission_tex", pub.tex("res://textures/dress_" + t + ".png"))
	m.set_shader_parameter("emission_energy", glow)
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	q.mesh = qm
	q.position = Vector3(0, 0, 0.0085)
	q.material_override = m
	n.add_child(q)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


func _hall_layer(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = 1 << (Pub.HALL_LAYER - 1)


func _pictures() -> void:
	var gilt := pub.mat(Color("8a6a2e"), 0.4, 0.75, 2, Vector3.UP, 5.0, 0.8)
	# the founder, between the washroom doors, in the hall's tube light: the face a disc of black,
	# domed and varnished, the hall in it
	var hall_face := Vector3(0, 0, 1)
	var f := _framed("founder", 0.46, 0.6, Vector3(8.6, 1.6, -1.16), hall_face, gilt, 0.05, 0.05, 0.8)
	var disc := pub.ball(0.085, Vector3(0, 0.088, 0.024), pub.mat(Color("030304"), 0.12, 0.55, 3, Vector3.UP, 7.0, 0.0), f)
	disc.scale = Vector3(1, 1, 0.22)
	# the plate on the frame's foot
	var plate := pub.box(Vector3(0.16, 0.035, 0.004), Vector3(0, -0.3 - 0.0225, 0.052), pub.mat(Color("b8923e"), 0.3, 0.85, 3), 0.0, f)
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pl := Label3D.new()
	pl.text = "R. H. SOVEREIGN\nPROPRIETOR · 1911 –"
	pl.font_size = 22
	pl.pixel_size = 0.0004
	pl.modulate = Color("2a1e0e")
	pl.outline_size = 0
	pl.position = Vector3(0, -0.3225, 0.0545)
	pl.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	pl.layers = 1 << (Pub.HALL_LAYER - 1)
	f.add_child(pl)
	_hall_layer(f)
	pub.anchors["founder"] = Vector3(8.6, 1.6, -1.14)
	# the painting of this room, over the drink rail on the back wall, dark wood, its own little
	# brass lamp on an arm over it
	var p := _framed("room1952", 0.72, 0.48, Vector3(7.95, 1.8, 0.0), BACKW, pub.M.frame, 0.04, 0.16, -0.6)
	var arm := pub.box(Vector3(0.012, 0.012, 0.14), Vector3(0, 0.3, 0.07), gilt, 0.0, p)
	arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var hood := pub.cyl(0.02, 0.02, 0.26, Vector3(0, 0.29, 0.15), gilt, p, 10)
	hood.rotation.z = PI / 2.0
	hood.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pls := SpotLight3D.new()
	pls.position = Vector3(7.95, 2.07, 0.17)
	pls.rotation = Vector3(deg_to_rad(-62), 0, 0)
	pls.light_color = Color("ffc070")
	pls.light_energy = 0.22
	pls.light_specular = 0.05
	pls.spot_range = 0.8
	pls.spot_angle = 52.0
	pls.spot_attenuation = 1.4
	add_child(pls)
	pub.lamps.append(pls)
	pub.anchors["painting_1952"] = Vector3(7.95, 1.8, 0.03)
	# Rocco's woman on velvet, on the east wall under the news screen, a frame sprayed gold; the
	# blacklight tube Gary put over her
	var gold := pub.mat(Color("c8a040"), 0.35, 0.9, 2, Vector3.UP, 5.0, 0.6)
	_framed("velvet", 0.42, 0.62, Vector3(16.0, 1.43, 4.0), EAST, gold, 0.035, 0.32, 1.3)
	var tube := pub.box(Vector3(0.03, 0.03, 0.46), Vector3(15.95, 1.8, 4.0), pub.glow(Color("8a50ff"), 2.2))
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bl := OmniLight3D.new()
	bl.position = Vector3(15.8, 1.6, 4.0)
	bl.light_color = Color("7a48ff")
	bl.light_energy = 0.35
	bl.omni_range = 0.9
	bl.omni_attenuation = 1.6
	add_child(bl)
	pub.anchors["velvet"] = Vector3(15.99, 1.43, 4.0)


# The school clock over the hall: SOVEREIGN, TIME, GENTLEMEN, and its hands going the other way.
func _back_clock() -> void:
	var at := Vector3(11.5, 2.0, -0.2)
	var n := Node3D.new()
	n.transform = Transform3D(Basis.looking_at(Vector3(0, 0, 1), Vector3.UP), at)
	add_child(n)
	var rim := pub.cyl(0.165, 0.165, 0.05, Vector3(0, 0, 0.025), pub.M.black, n, 28)
	rim.rotation.x = PI / 2.0
	var face := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.3)
	face.mesh = q
	face.position = Vector3(0, 0, 0.0515)
	var fm := pub.mat(Color(1, 1, 1), 0.6, 0.0, 3, Vector3.UP, 7.0, 0.3)
	fm.set_shader_parameter("albedo_tex", pub.tex("res://textures/dress_clock_back.png"))
	fm.set_shader_parameter("alpha_scissor", 0.5)
	fm.set_shader_parameter("emission", Color(1, 1, 1))
	fm.set_shader_parameter("emission_tex", pub.tex("res://textures/dress_clock_back.png"))
	fm.set_shader_parameter("emission_energy", 0.08)
	face.material_override = fm
	n.add_child(face)
	for k in 3:
		var hand := Node3D.new()
		hand.position = Vector3(0, 0, 0.054 + k * 0.002)
		n.add_child(hand)
		var ln: float = [0.075, 0.115, 0.12][k]
		pub.box(Vector3([0.007, 0.005, 0.002][k], ln, 0.0015), Vector3(0, ln / 2.0 - 0.015, 0), pub.M.black if k < 2 else pub.mat(Color("a8281e"), 0.6), 0.0, hand)
		_back_hands.append(hand)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hall_layer(n)
	pub.anchors["hall_clock"] = at + Vector3(0, 0, -0.06)
	set_clock(1260)


# On the hall wall by the phone, in pen and marker and key: what people write while they wait.
func _scrawl() -> void:
	var m := paper_mat("scrawl")
	m.set_shader_parameter("lines", 0.0)
	var s := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.4, 0.5)
	s.mesh = q
	s.transform = Transform3D(Basis.looking_at(Vector3(0, 0, 1), Vector3.UP), Vector3(12.9, 1.35, -0.203))
	s.material_override = m
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.layers = 1 << (Pub.HALL_LAYER - 1)
	add_child(s)
	# the phone's own bulb, over the wall where they stand and write
	_pool_on(Vector3(12.9, 1.35, -0.2), Vector3(0, 0, -1), 0.7, 0.9)
	pub.anchors["scrawl"] = Vector3(12.9, 1.35, -0.22)


# On top of the jukebox: a brass diving helmet, the old kind, green at its seams; in its front
# window, half a lime.
func _helmet() -> void:
	var n := Node3D.new()
	n.position = Vector3(13.22, 2.008, 0.2)
	n.rotation.y = deg_to_rad(18)
	add_child(n)
	var brass := pub.mat(Color("a8823a"), 0.5, 0.8, 2, Vector3.UP, 5.0, 0.8)
	var green := pub.mat(Color("4e7a5c"), 0.85, 0.1, 3)
	pub.cyl(0.15, 0.17, 0.05, Vector3(0, 0.025, 0), brass, n, 18)         # the breastplate's collar
	pub.cyl(0.152, 0.152, 0.012, Vector3(0, 0.05, 0), green, n, 18)
	var dome := pub.ball(0.15, Vector3(0, 0.2, 0), brass, n)
	dome.scale = Vector3(1, 1.05, 1)
	for k in 10:
		var a := TAU * k / 10.0
		pub.ball(0.009, Vector3(cos(a) * 0.168, 0.035, sin(a) * 0.168), brass, n)
	# the windows: front and the two sides, each a ring with its glass gone dark; the front's has
	# the lime
	for w in [[Vector3(0, 0.2, 1), 0.06], [Vector3(1, 0.21, 0.15), 0.045], [Vector3(-1, 0.21, 0.15), 0.045]]:
		var dir: Vector3 = Vector3(w[0].x, 0, w[0].z).normalized()
		var c: Vector3 = Vector3(0, w[0].y, 0) + dir * 0.135
		var r: float = w[1]
		var ring := pub.cyl(r + 0.012, r + 0.012, 0.03, c, brass, n, 16)
		ring.transform.basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3(1, 0, 0), PI / 2.0)
		var glass := pub.cyl(r, r, 0.032, c + dir * 0.002, pub.mat(Color("0c0e0d"), 0.08, 0.3, 3, Vector3.UP, 7.0, 0.0), n, 16)
		glass.transform.basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3(1, 0, 0), PI / 2.0)
		if r > 0.05:
			var lime := pub.ball(0.034, c + dir * 0.004, pub.mat(Color("3f7a22"), 0.6, 0.0, 3), n)
			lime.scale = Vector3(1, 1, 0.45)
			lime.transform.basis = Basis.looking_at(dir, Vector3.UP) * Basis.from_scale(Vector3(1, 1, 0.45))
			var flesh := pub.cyl(0.03, 0.03, 0.003, c + dir * 0.019, pub.mat(Color("8fae4a"), 0.6, 0.0, 3), n, 14)
			flesh.transform.basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3(1, 0, 0), PI / 2.0)
			# its bars
			for b in [-1.0, 1.0]:
				var bar := pub.box(Vector3(0.006, r * 2.0, 0.006), c + dir * 0.02 + Vector3(0, 0, 0) + Basis.looking_at(dir, Vector3.UP) * Vector3(b * 0.02, 0, 0), brass, 0.0, n)
				bar.transform.basis = Basis.looking_at(dir, Vector3.UP)
	# the air fitting at the back, and the green coming out of every seam
	var nip := pub.cyl(0.02, 0.025, 0.06, Vector3(0, 0.25, -0.15), brass, n, 10)
	nip.rotation.x = -PI / 3.0
	for k in 6:
		var a := TAU * k / 6.0 + 0.3
		pub.box(Vector3(0.025, 0.006, 0.006), Vector3(cos(a) * 0.15, 0.055, sin(a) * 0.15), green, -a, n)
	pub.anchors["helmet"] = n.position + Vector3(0, 0.2, 0.15)


# The Clam-a-Lot cards, folded over on the four tables, one corner each; on the turn of the night
# somebody's always moved one.
func _tents() -> void:
	var a := paper_mat("clam_a")
	var b := paper_mat("clam_b")
	var k := 0
	for t in Pub.TABLES:
		var yaw := rng.randf_range(0, TAU)
		var c: Vector3 = t + Vector3(0.24 * (1 if k % 2 == 0 else -1), 0.78, -0.22 * (1 if k < 2 else -1))
		var out := Vector3(cos(yaw), 0, sin(yaw))
		var lean := deg_to_rad(18)
		for side in [[a, 1.0], [b, -1.0]]:
			var f: Vector3 = out * float(side[1])
			var face := Vector3(f.x * cos(lean), sin(lean), f.z * cos(lean))
			var at := c + f * 0.016 + Vector3(0, 0.048, 0)
			var mi := paper(side[0], 0.14, 0.1, at, face, 0.0, 0)
			mi.position -= face * 0.004
		k += 1
	pub.anchors["table_tents"] = Pub.TABLES[0] + Vector3(0.24, 0.84, -0.22)


# The marks: rings on the tables, a water stain on the ceiling, the brown over the big table, heel
# scuffs where the door's crowd stands. Soft-edged, laid a hair off what they're on.
func _mark_mat(t: String, a: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = pub.tex("res://textures/dress_" + t + ".png")
	m.albedo_color = Color(1, 1, 1, a)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.9
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


# the same, for a mark up where no lamp reaches: a breath of its own, so the shape holds in the dark
func _mark_glow(t: String, a: float, e: float) -> StandardMaterial3D:
	var m := _mark_mat(t, a)
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = e
	return m


func _flat(m: Material, size: Vector2, at: Vector3, up: bool, yaw: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = size
	q.flip_faces = not up
	mi.mesh = q
	mi.position = at
	mi.rotation.y = yaw
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marks_node.add_child(mi)
	return mi


func _marks() -> void:
	# their own node: laid flat over everything, they're meant to be in it (the pendant's cord goes
	# through the brown on the ceiling)
	_marks_node = Node3D.new()
	_marks_node.name = "marks"
	add_child(_marks_node)
	var rings := _mark_mat("rings", 0.75)
	for t in Pub.TABLES + [Pub.T28]:
		for i in rng.randi_range(1, 3):
			_flat(rings, Vector2(0.16, 0.16), t + Vector3(rng.randf_range(-0.3, 0.3), 0.7815 + i * 0.0004, rng.randf_range(-0.3, 0.3)), true, rng.randf_range(0, TAU))
	_flat(_mark_glow("stain", 0.9, 0.35), Vector2(1.6, 1.6), Vector3(6.6, 3.196, 5.9), false, 0.4)
	_flat(_mark_glow("nicotine", 0.85, 0.2), Vector2(2.6, 2.2), Vector3(9.4, 3.197, 8.1), false, 1.1)
	_flat(_mark_mat("scuffs", 0.7), Vector2(1.4, 0.9), Vector3(3.4, 0.008, 8.6), true, 0.2)
	pub.anchors["ceiling_stain"] = Vector3(6.6, 3.15, 5.9)


# The stickers, where people stand and wait: by the phone, on the washroom fronts, by the corkboard.
func _stickers() -> void:
	var spots := [[0, Vector3(14.0, 1.05, -0.2), Vector3(0, 0, -1), true],
		[2, Vector3(9.15, 1.15, -1.16), Vector3(0, 0, 1), true],
		[3, Vector3(10.35, 1.42, -1.16), Vector3(0, 0, 1), true],
		[1, Vector3(5.62, 1.22, 0.0), BACKW, false]]
	for s in spots:
		var mi := paper(paper_mat("stk_%d" % s[0]), 0.105, 0.082, s[1], s[2], rng.randf_range(-14, 14), 0)
		if s[3]:
			mi.layers = 1 << (Pub.HALL_LAYER - 1)


# ---------------------------------------------------------------- outside

func _outside_signs() -> void:
	var out := Vector3(0, 0, 1)
	# by the door, on the boards: the licence board's MINORS PROHIBITED, and NO SHIRT NO SHOES with
	# Gary's line under it
	paper(paper_mat("minors"), 0.3, 0.38, Vector3(4.85, 1.55, 10.25), out, 0.8, 0)
	paper(paper_mat("noshirt"), 0.38, 0.28, Vector3(1.5, 1.6, 10.25), out, -2.0, 4)
	pub.anchors["door_signs"] = Vector3(1.5, 1.6, 10.27)


# What the night leaves on the gravel: butts by the door and the deck steps where they smoke, cans
# crushed and not, the bags and cups and papers the wind's put along the front of the building and
# the store, a scratch ticket or two, one flip-flop, one wrapper by the side of the building that
# nobody's going to mention; and along the highway's shoulder, what's thrown from cars.
func _lot_trash() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4471
	var lot := Node3D.new()
	lot.name = "trash"
	add_child(lot)
	# where: [centre, half size, ground y, how many, what]
	var spots := [
		[Vector3(3.2, 0, 11.4), Vector2(1.8, 0.9), 0.12, 34, "butts"],      # on the step and round it
		[Vector3(3.2, 0, 12.6), Vector2(2.6, 0.8), 0.0, 22, "butts"],
		[Vector3(18.9, 0, 5.0), Vector2(0.6, 1.0), -0.25, 26, "butts"],     # under the deck steps
		[Vector3(8.0, 0, 10.55), Vector2(7.8, 0.3), 0.0, 9, "mixed"],       # along the front of the building
		[Vector3(-3.2, 0, 10.6), Vector2(2.8, 0.35), 0.0, 7, "mixed"],      # along the store
		[Vector3(7.0, 0, 15.5), Vector2(8.0, 4.0), 0.0, 10, "mixed"],       # the lot
		[Vector3(5.0, 0, 28.6), Vector2(26.0, 1.2), -0.01, 18, "road"],     # the shoulder
		[Vector3(17.6, 0, 3.4), Vector2(0.9, 0.5), -0.25, 1, "wrapper"],    # round the side, by the hotel door
	]
	pub.anchors["lot_trash"] = Vector3(3.2, 0.1, 11.6)
	for s in spots:
		for k in int(s[3]):
			var at: Vector3 = s[0] + Vector3(r.randf_range(-s[1].x, s[1].x), float(s[2]), r.randf_range(-s[1].y, s[1].y))
			if at.distance_to(Vector3(9.2, at.y, 15.8)) < 2.8 or at.distance_to(Vector3(13.0, at.y, 12.4)) < 2.4 or at.distance_to(Vector3(-1.5, at.y, 13.4)) < 2.4 or at.distance_to(Vector3(-3.4, at.y, 13.6)) < 3.2:
				continue        # under a car
			var what: String = s[4]
			if what == "mixed":
				what = ["can", "can", "can", "bag", "cup", "paper", "ticket", "butt", "bottle", "menu"][r.randi() % 10]
			elif what == "road":
				what = ["can", "can", "cup", "bag", "paper", "bottle", "case", "flipflop", "receipt"][r.randi() % 9]
			elif what == "butts":
				what = "butt"
			trash_piece(what, at, r, lot)


# One piece: a crushed can, a cup on its side, a bag, a paper, a butt.
func trash_piece(what: String, at: Vector3, r: RandomNumberGenerator, parent: Node) -> void:
	var yaw := r.randf_range(0.0, TAU)
	match what:
		"butt":
			var n := Node3D.new()
			n.position = at + Vector3(0, 0.0035, 0)
			n.rotation = Vector3(0, yaw, PI / 2.0 + r.randf_range(-0.1, 0.1))
			parent.add_child(n)
			pub.cyl(0.0036, 0.0036, 0.012, Vector3(0, 0.006, 0), pub.mat(Color("c89a5a"), 0.9, 0.0, 3), n, 6)
			pub.cyl(0.0034, 0.0034, r.randf_range(0.004, 0.02), Vector3(0, -0.006, 0), pub.mat(Color("d8d4c8"), 0.9, 0.0, 3), n, 6)
		"can":
			var cell := r.randi_range(0, 2)
			var n := Node3D.new()
			n.position = at + Vector3(0, 0.024, 0)
			n.rotation = Vector3(0, yaw, PI / 2.0)
			parent.add_child(n)
			var crushed := r.randf() < 0.6
			var c := pub.cyl(0.031, 0.033, 0.07 if crushed else 0.122, Vector3.ZERO, _cell_mat(cell, 0.6, 0.6), n, 14)
			if crushed:
				c.scale = Vector3(1.0, 1.0, 0.55)
				n.position.y = at.y + 0.017
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		"cup":
			var n := Node3D.new()
			n.position = at + Vector3(0, 0.036, 0)
			n.rotation = Vector3(0, yaw, PI / 2.0 - 0.1)
			parent.add_child(n)
			pub.cyl(0.042, 0.03, 0.11, Vector3.ZERO, _cell_mat(4, 0.9, 0.0), n, 14)
		"bottle":
			var n := Node3D.new()
			n.position = at + Vector3(0, 0.03, 0)
			n.rotation = Vector3(0, yaw, PI / 2.0)
			parent.add_child(n)
			var bm := pub.glass(Color("4a2a10"), 0.75)
			pub.cyl(0.03, 0.031, 0.15, Vector3.ZERO, bm, n, 12)
			pub.cyl(0.012, 0.03, 0.08, Vector3(0, 0.115, 0), bm, n, 10)
		"flipflop":
			var f := pub.box(Vector3(0.1, 0.012, 0.26), at + Vector3(0, 0.006, 0), pub.mat(Color("2a4a6a"), 0.8), rad_to_deg(yaw), parent)
			f.scale = Vector3(1, 1, 1)
		"bag", "paper", "ticket", "menu", "case", "receipt", "wrapper":
			var cells := {"bag": [3, Vector2(0.17, 0.24), 0.012], "paper": [7, Vector2(0.28, 0.36), 0.02], "ticket": [6, Vector2(0.06, 0.1), 0.002],
				"menu": [10, Vector2(0.2, 0.26), 0.012], "case": [12, Vector2(0.26, 0.2), 0.004], "receipt": [13, Vector2(0.07, 0.16), 0.003],
				"wrapper": [9, Vector2(0.05, 0.05), 0.001]}
			var cfg: Array = cells[what]
			var m := paper(_cell_mat(int(cfg[0]), 0.9, 0.0), cfg[1].x, cfg[1].y, at + Vector3(0, 0.004, 0), Vector3.UP, rad_to_deg(yaw), 0, float(cfg[2]), parent)
			m.position.y = at.y + 0.003 + float(cfg[2]) * 0.5


# A square of the trash sheet (textures/dress_trash.png, 4 x 4) as a material of its own.
func _cell_mat(i: int, rough: float, metal: float) -> Material:
	var key := "%d:%f:%f" % [i, rough, metal]
	if _trash_tex.has(key):
		return _trash_tex[key]
	var sheet := Image.new()
	sheet.load_png_from_buffer(FileAccess.get_file_as_bytes("res://textures/dress_trash.png"))
	var t := sheet.get_width() / 4
	var sub := sheet.get_region(Rect2i((i % 4) * t, (i / 4) * t, t, t))
	sub.generate_mipmaps()
	var m := pub.mat(Color(1, 1, 1), rough, metal, 3, Vector3.UP, 7.0, 0.4)
	m.set_shader_parameter("albedo_tex", ImageTexture.create_from_image(sub))
	_trash_tex[key] = m
	return m


# ---------------------------------------------------------------- the Esso

# The Esso's window full of ads taped up inside the glass, the door's, the night window's; the
# squeegee's sign on a canopy post; and round the pumps and the freezer, what's dropped there.
# Under the town's "far", out only while he's away from the Sov (world/town.gd).
func _esso() -> void:
	var far: Node3D = pub.town.far
	var es := Node3D.new()
	es.name = "esso_dressing"
	far.add_child(es)
	var out := Vector3(0, 0, 1)
	var y := Town.APRON
	var zi := 11.915                  # taped on the outside of the store's front glass (inside, the glass
	                                  # washed them out to nothing)
	for a in [["ice", 0.36, 0.48, -156.3, 1.12], ["lotto", 0.4, 0.52, -155.25, 1.32], ["smokes", 0.4, 0.3, -153.9, 1.05],
			["grill", 0.38, 0.3, -152.6, 1.8], ["wash", 0.34, 0.22, -151.4, 1.0]]:
		# big enough to read across the forecourt: these are made to be seen from the pumps
		paper(paper_mat("esso_" + a[0]), a[1] * 1.7, a[2] * 1.7, Vector3(a[3], y + a[4] + 0.15, zi), out, _tilt(), 0, 0.0, es)
	paper(paper_mat("esso_id"), 0.3, 0.2, Vector3(-148.7, y + 1.55, zi), out, -1.5, 0, 0.0, es)
	paper(paper_mat("esso_night"), 0.3, 0.4, Vector3(-144.3, y + 1.75, zi), out, 1.0, 0, 0.0, es)
	pub.anchors["esso_ads"] = Vector3(-154.0, y + 1.3, 11.95)
	var r := RandomNumberGenerator.new()
	r.seed = 8890
	for s in [[Vector3(-150.0, y, 21.0), Vector2(5.0, 3.0), 14], [Vector3(-147.3, y, 13.4), Vector2(2.0, 0.6), 16],
			[Vector3(-155.9, y, 23.6), Vector2(0.8, 0.6), 7], [Vector3(-150.0, y, 26.4), Vector2(12.0, 0.8), 8]]:
		for k in int(s[2]):
			var at: Vector3 = s[0] + Vector3(r.randf_range(-s[1].x, s[1].x), 0.0, r.randf_range(-s[1].y, s[1].y))
			if absf(at.x + 150.0) < 5.1 and (absf(at.z - 19.0) < 0.7 or absf(at.z - 23.0) < 0.7):
				at.y += 0.15          # on the island's curb
			var what: String = ["butt", "butt", "butt", "can", "receipt", "ticket", "cup", "bag", "paper"][r.randi() % 9]
			trash_piece(what, at, r, es)
