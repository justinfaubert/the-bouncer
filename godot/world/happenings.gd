# What the writing says happens, happening (Hutch, 25 November 2026: "a woman that you apparently
# run into and light her cigarette, I'd like to see her. The events in general that happen in the
# game should be more visually a part of it").
#
# The stage (world/stage.gd) puts people where the night has them. This is the few seconds after a
# choice where something is done in front of him: the flame going to Lorraine's cigarette and the
# smoke going up over her head as she goes back along the hall; her going up the hotel stairs ahead
# of him on Friday; seven's door swinging in on the key from the crab trap. While a beat plays it
# holds his eyes where it is (main._frame_for asks `holds`), and when it's done it lets them go.
# Each beat reads the Ink's own variables, so a beat plays once, as the line that says it comes up.
class_name Happenings
extends Node3D

var stage: Stage
var pub: Pub
var view: View
var on_done: Callable                 # main: look again for where his eyes should be
var _last := {}                       # the night's variables as of the last batch
var _hold := {}                       # place -> frame held while a beat plays
var _owned := {}                      # id -> node taken off the stage for a beat
var _cigs := {}                       # figure id -> the cigarette node in their fingers
var t := 0.0
var _things := {}                     # the days' own things in the world, made once, shown as the day has them


func setup(s: Stage, p: Pub, v: View) -> void:
	stage = s
	pub = p
	view = v


# the frame a beat is holding at this place, or ""
func holds(where: String) -> String:
	return str(_hold.get(where, ""))


# After every batch the night plays: anything newly true starts its beat.
func after(game: Game) -> void:
	if game == null or game.story == null:
		return
	var v := game.vars()
	var day := int(BUtil.js_int(v.get("day", 1)))
	var was := func(n: String) -> int: return int(BUtil.js_int(_last.get(n, 0)))
	var now := func(n: String) -> int: return int(BUtil.js_int(v.get(n, 0)))
	if not _last.is_empty() and int(BUtil.js_int(_last.get("day", 1))) == day:
		var lh: int = now.call("lorraine_how")
		if lh != was.call("lorraine_how"):
			if day == 2 and lh in [1, 2, -1]:
				_lorraine_thursday(lh)
			elif day == 3 and lh in [3, 4]:
				_lorraine_stairs(lh)
		if now.call("seven_how") == 1 and was.call("seven_how") != 1:
			_seven_opens()
	_last = v.duplicate(true)
	# the cigarettes in the fingers of whoever's holding one
	_dress_smokers()
	_day_things(v, day)


func _process(dt: float) -> void:
	t += dt
	# the tug out on the strait, towing north so slowly it doesn't seem to be moving (days.ink)
	var tug = _things.get("tug")
	if tug != null and (tug as Node3D).visible:
		(tug as Node3D).position.x -= 0.35 * dt
	for id in _cigs.keys():
		var c = _cigs[id]
		if not is_instance_valid(c):
			_cigs.erase(id)
			continue
		var ember := (c as Node3D).get_node_or_null("ember") as MeshInstance3D
		var glow := (c as Node3D).get_node_or_null("glow") as OmniLight3D
		if ember != null and ember.visible and glow != null:
			# a drag now and then: the ember comes up bright, then sinks back
			var k := pow(maxf(0.0, sin(t * 0.9 + float(id.hash() % 7))), 12.0)
			glow.light_energy = 0.08 + 0.5 * k
			(ember.material_override as StandardMaterial3D).emission_energy_multiplier = 1.5 + 5.0 * k


# ---------------------------------------------------------------- the cigarette

func _dress_smokers() -> void:
	for id in ["lorraine"]:
		var f = stage.figures.get(id)
		if f == null or _cigs.has(id):
			continue
		var lit: bool = str(f.model) != "lorraine_door"
		_cigs[id] = _cigarette(f.node, f.anchors, lit)


# A cigarette in the fingers of the right hand (by the wrist the model's anchors give), its filter
# in the fingers and the end out past them; unlit, or lit with an ember and its smoke.
func _cigarette(holder: Node3D, an: Dictionary, lit: bool) -> Node3D:
	var w: Array = an.get("hand_right", [0.15, 1.35, 0.2])
	var wrist := Vector3(w[0], w[1], w[2])
	var c := Node3D.new()
	c.name = "cig"
	holder.add_child(c)
	# out from the fingers, a little up and toward her mouth, so it reads against the robe
	# (the people face -z: up and out in front of her, a little across toward her mouth)
	var along := Vector3(-0.12, 0.55, -0.8).normalized()
	c.position = wrist + along * 0.16 + Vector3(0, 0.012, 0.0)
	c.look_at(holder.global_transform * (c.position + along), Vector3.UP)
	var paper := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0042
	cm.bottom_radius = 0.0042
	cm.height = 0.082
	cm.radial_segments = 10
	paper.mesh = cm
	paper.rotation.x = PI / 2.0
	paper.position = Vector3(0, 0, -0.041)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("ece6da")
	pm.roughness = 0.8
	paper.material_override = pm
	c.add_child(paper)
	var filt := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.0044
	fm.bottom_radius = 0.0044
	fm.height = 0.022
	filt.mesh = fm
	filt.rotation.x = PI / 2.0
	filt.position = Vector3(0, 0, -0.011)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color("c48a4e")
	filt.material_override = fmat
	c.add_child(filt)
	var ember := MeshInstance3D.new()
	ember.name = "ember"
	var em := SphereMesh.new()
	em.radius = 0.0048
	em.height = 0.007
	ember.mesh = em
	ember.position = Vector3(0, 0, -0.083)
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color("3a1a10")
	emat.emission_enabled = true
	emat.emission = Color("ff6a1e")
	emat.emission_energy_multiplier = 2.0
	ember.material_override = emat
	c.add_child(ember)
	var glow := OmniLight3D.new()
	glow.name = "glow"
	glow.light_color = Color("ff7a30")
	glow.omni_range = 0.45
	glow.light_energy = 0.1
	glow.position = ember.position
	c.add_child(glow)
	var smoke := _smoke()
	smoke.position = ember.position
	c.add_child(smoke)
	_light(c, lit)
	return c


func _light(c: Node3D, lit: bool) -> void:
	for n in ["ember", "glow"]:
		(c.get_node(n) as Node3D).visible = lit
	(c.get_node("smoke") as CPUParticles3D).emitting = lit


# The smoke off the end: a thin thread that rises, slows, widens and goes, leaning with the air.
func _smoke() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "smoke"
	p.amount = 46
	p.lifetime = 3.2
	p.local_coords = false
	p.emitting = false
	p.direction = Vector3(0, 1, 0)
	p.spread = 6.0
	p.gravity = Vector3(0.02, 0.09, 0.0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.09
	p.damping_min = 0.02
	p.damping_max = 0.05
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.15))
	curve.add_point(Vector2(0.4, 0.6))
	curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.82, 0.82, 0.8, 0.0))
	grad.add_point(0.12, Color(0.82, 0.82, 0.8, 0.32))
	grad.set_color(grad.get_point_count() - 1, Color(0.7, 0.7, 0.7, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = _puff_tex()
	m.disable_receive_shadows = true
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


static var _puff: ImageTexture


static func _puff_tex() -> ImageTexture:
	if _puff != null:
		return _puff
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x - n / 2.0 + 0.5, y - n / 2.0 + 0.5).length() / (n / 2.0)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	_puff = ImageTexture.create_from_image(img)
	return _puff


# ---------------------------------------------------------------- Lorraine, Thursday

# Take a figure off the stage for a beat: the stage forgets it (and won't blink it away), the beat
# moves it, and frees it at the end.
func _take(id: String) -> Node3D:
	var f = stage.figures.get(id)
	if f == null:
		return null
	stage.figures.erase(id)
	stage.want.erase(id)
	var node: Node3D = f.node
	_owned[id] = node
	return node


func _release(id: String) -> void:
	var node = _owned.get(id)
	_owned.erase(id)
	_cigs.erase(id)
	if node != null and is_instance_valid(node):
		(node as Node3D).queue_free()


# 1: he lights it. The lighter comes up out of the bottom of his eyes in his fist, a thumb on the
# wheel, the flame goes to the end, the end takes, she holds his wrist a second longer than the
# lighter needed; then she goes back along the hall with the smoke over her head, and six's door.
# 2: maybe Friday: she laughs, takes it out of her mouth, goes the other way to ask eleven.
# -1: he shuts the door on her (twelve's is only a hole in the wall here; she's gone from it).
func _lorraine_thursday(how: int) -> void:
	var node := _take("lorraine")
	if node == null:
		return
	_hold["upstairs"] = "door"
	var cig = _cigs.get("lorraine")
	var tw := create_tween()
	if how == 1 and cig != null:
		# a step to her, to the doorway, for the light
		_hold["upstairs"] = "door_close"
		if on_done.is_valid():
			on_done.call()
		tw.tween_interval(1.4)
		var tip: Vector3 = (cig as Node3D).global_transform * Vector3(0, 0, -0.085)
		var lighter := _lighter()
		add_child(lighter)
		lighter.visible = false
		var p_close: Dictionary = Posts.FRAMES["upstairs:door_close"]
		var eye: Vector3 = p_close.at
		var toward := (eye - tip).normalized()
		var side := toward.cross(Vector3.UP).normalized()
		var start := tip + toward * 0.45 - side * 0.12 + Vector3(0, -0.55, 0)
		var at := tip + toward * 0.05 + Vector3(0, -0.06, 0)
		lighter.global_position = start
		lighter.look_at(lighter.global_position - toward, Vector3.UP)
		tw.tween_callback(func(): lighter.visible = true)
		tw.tween_property(lighter, "global_position", at, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			stage.sound.emit("lighter", at, 1.0, 3.0)
			(lighter.get_node("flame") as Node3D).visible = true)
		tw.tween_interval(0.5)
		tw.tween_callback(func(): _light(cig, true))
		# the second longer than the lighter needed
		tw.tween_interval(1.1)
		tw.tween_callback(func(): (lighter.get_node("flame") as Node3D).visible = false)
		tw.tween_property(lighter, "global_position", start + Vector3(0, -0.2, 0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(lighter.queue_free)
		tw.tween_callback(func():
			_hold["upstairs"] = "door"
			if on_done.is_valid():
				on_done.call())
	else:
		tw.tween_interval(1.4 if how == 2 else 0.4)
	# and off along the hall: toward six for a light got, toward eleven for maybe
	var to := Vector3(15.0, Pub.UP_Y, 5.6) if how == 1 else Vector3(12.6, Pub.UP_Y, 5.75)
	_walk(tw, node, to, 0.75)
	if how == 1:
		tw.tween_callback(func(): stage.sound.emit("door_wc", pub.anchors.get("six_door", to), 0.8, 4.0))
	tw.tween_interval(0.6)
	tw.tween_callback(func():
		_release("lorraine")
		_hold.erase("upstairs")
		if on_done.is_valid():
			on_done.call())


# Friday: up the hotel stairs, one hand on the rail; ahead of him (3), or alone (4).
func _lorraine_stairs(how: int) -> void:
	var node := _take("lorraine")
	if node == null:
		return
	_hold["hall"] = "stair"
	var tw := create_tween()
	tw.tween_interval(0.5)
	# along the stairs and up them: thirteen steps of 0.25 by 0.2
	node.look_at(Vector3(19.5, node.global_position.y, -2.2), Vector3.UP)
	var steps := 9
	for k in steps:
		var p := Vector3(16.42 + 0.25 * (k + 1), 0.2 + 0.2 * (k + 1), -2.2)
		tw.tween_property(node, "global_position", p + Vector3(0, 0.03, 0), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "global_position", p, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if k % 2 == 0:
			tw.tween_callback(func(): stage.sound.emit("steps", node.global_position, 0.35, 3.0))
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		_release("lorraine")
		_hold.erase("hall")
		if on_done.is_valid():
			on_done.call())


# Walking a figure that has no walk of its own (the made-for-a-pose ones) a few steps: turned to
# where they're going, a bob on each step and a little sway, at an unhurried pace.
func _walk(tw: Tween, node: Node3D, to: Vector3, speed: float) -> void:
	tw.tween_callback(func():
		var from := node.global_position
		if Vector2(to.x - from.x, to.z - from.z).length() > 0.05:
			node.look_at(Vector3(to.x, from.y, to.z), Vector3.UP))
	var from := node.global_position
	var dist := Vector2(to.x - from.x, to.z - from.z).length()
	var n := maxi(2, int(dist / 0.55))
	for k in n:
		var p := from.lerp(to, float(k + 1) / n)
		var mid := from.lerp(to, (k + 0.5) / n) + Vector3(0, 0.025, 0)
		tw.tween_property(node, "global_position", mid, 0.55 / speed / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "global_position", p, 0.55 / speed / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# His lighter in his fist: a steel lighter, the flame a bead of light with its glow.
func _lighter() -> Node3D:
	var l := Node3D.new()
	var fist_path := "res://models/people/his_fist_r.glb"
	if FileAccess.file_exists(fist_path):
		var fist := pub.model(fist_path, Vector3.ZERO, l)
		fist.position = Vector3(0.0, -0.035, 0.06)
	# his sleeve back from the wrist, the canvas work jacket
	var arm := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.042
	am.bottom_radius = 0.05
	am.height = 0.32
	arm.mesh = am
	# (the lighter faces away from his eyes, so +z runs back to him: the arm comes up from the
	# bottom right of what he sees)
	am.height = 0.62
	arm.position = Vector3(0.1, -0.2, 0.3)
	arm.rotation = Vector3(deg_to_rad(-58.0), deg_to_rad(18.0), 0.0)
	var jm := StandardMaterial3D.new()
	jm.albedo_color = Color("25272b")
	jm.roughness = 0.9
	arm.material_override = jm
	l.add_child(arm)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.024, 0.05, 0.012)
	body.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color("9a9c9e")
	sm.metallic = 0.8
	sm.roughness = 0.35
	body.material_override = sm
	l.add_child(body)
	var flame := Node3D.new()
	flame.name = "flame"
	flame.visible = false
	flame.position = Vector3(0, 0.045, 0)
	var fm := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.006
	sp.height = 0.026
	fm.mesh = sp
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = Color("ffd27a")
	fmat.emission_enabled = true
	fmat.emission = Color("ffb347")
	fmat.emission_energy_multiplier = 6.0
	fm.material_override = fmat
	flame.add_child(fm)
	var fl := OmniLight3D.new()
	fl.light_color = Color("ffb05a")
	fl.light_energy = 1.4
	fl.omni_range = 1.6
	fl.shadow_enabled = true
	flame.add_child(fl)
	l.add_child(flame)
	return l


# ---------------------------------------------------------------- room seven

# The key turns; the door goes in, slow, on hinges nobody's oiled since March; the radiator knocks.
func _seven_opens() -> void:
	var hinge = pub.dyn.get("seven_door")
	if hinge == null:
		return
	var at: Vector3 = pub.anchors.get("seven_door", Vector3(11.4, Pub.UP_Y + 1.0, 5.0))
	stage.sound.emit("click", at, 0.8, 3.0)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(hinge, "rotation:y", deg_to_rad(96.0), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# when he's shut it again, from the hall: three knocks, and a needle set down on nothing
	tw.tween_interval(4.0)
	for k in 3:
		tw.tween_callback(func(): stage.sound.emit("clack", at + Vector3(0.5, -0.8, -2.6), 0.6, 4.0))
		tw.tween_interval(0.45)
	tw.tween_interval(0.8)
	tw.tween_callback(func(): stage.sound.emit("scratch", pub.anchors.get("seven_record", at), 0.5, 5.0))


# ---------------------------------------------------------------- the days' things

# What Thursday's writing puts in the world: the crab trap on the wharf's planks by the old man,
# its rope tied off down into the water once it's over, and up again at dusk with three crabs in it
# and the key to seven caught in the wire; table 28's afternoon, the Shoreline spread across both
# tables and the vacuum standing by the pool table with its cord wound round it; the tug and its
# boom of logs out on the strait in the grey light.
func _day_things(v: Dictionary, day: int) -> void:
	if _things.is_empty():
		_make_things()
	var clock := int(BUtil.js_int(v.get("clock", 0)))
	var trap_in := int(BUtil.js_int(v.get("trap_in", 0)))
	var d2: Array = v.get("d2_done", []) if v.get("d2_done") is Array else []
	var hauled := "d2_hauled" in d2
	var thursday := day == 2
	var kept := v.get("knows") is Array and "key_seven" in (v.get("knows") as Array)
	(_things.trap as Node3D).visible = thursday and (trap_in <= 0 or hauled)
	(_things.trap as Node3D).position = (Vector3(-198.55, Town.WHARF_Y, 93.0) if not hauled else Vector3(-197.95, Town.WHARF_Y, 94.1))
	(_things.crabs as Node3D).visible = thursday and hauled
	(_things.key7 as Node3D).visible = thursday and hauled and not kept
	(_things.rope as Node3D).visible = thursday and trap_in > 0 and not hauled
	var afternoon := thursday and clock >= 840 and clock < 1008
	(_things.papers as Node3D).visible = afternoon
	(_things.vacuum as Node3D).visible = afternoon
	# Friday at four: the bookkeeper's shoebox of envelopes on the bar in front of her
	(_things.shoebox as Node3D).visible = day == 3 and clock < 990
	(_things.tug as Node3D).visible = thursday and clock < 1040
	if not (_things.tug as Node3D).visible:
		(_things.tug as Node3D).position.x = 160.0


func _make_things() -> void:
	var town_far: Node3D = pub.town.far if pub.town != null else pub
	# the trap: a cage of wire and rope, the fish head inside on its string
	var trap := Node3D.new()
	town_far.add_child(trap)
	var wire := pub.mat(Color("6e6a62"), 0.5, 0.6, 2, Vector3.UP, 5.0, 1.0)
	var rope_m := pub.mat(Color("b5a27c"), 0.95, 0.0, 2, Vector3.UP, 6.0, 0.8)
	for k in 9:
		var a := TAU * k / 9.0
		pub.cyl(0.006, 0.006, 0.3, Vector3(cos(a) * 0.36, 0.15, sin(a) * 0.36), wire, trap, 4)
	for hy in [0.01, 0.3]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.35
		tm.outer_radius = 0.37
		ring.mesh = tm
		ring.material_override = wire
		ring.position = Vector3(0, hy, 0)
		trap.add_child(ring)
	var net := pub.mat(Color("5f5a50"), 0.8, 0.2, 1, Vector3(1, 0, 0), 3.0, 1.2)
	pub.cyl(0.36, 0.36, 0.008, Vector3(0, 0.3, 0), net, trap, 18)
	pub.ball(0.06, Vector3(0.05, 0.08, 0.02), pub.mat(Color("8a8f84"), 0.4), trap)
	pub.cyl(0.004, 0.004, 0.9, Vector3(0.0, 0.55, 0.0), rope_m, trap, 4)
	_things.trap = trap
	var crabs := Node3D.new()
	trap.add_child(crabs)
	var shell := pub.mat(Color("7a3e2a"), 0.7, 0.0, 4, Vector3.UP, 6.0, 0.8)
	for c in [[Vector3(0.08, 0.04, 0.02), 0.075], [Vector3(-0.12, 0.035, 0.1), 0.055], [Vector3(0.0, 0.035, -0.15), 0.05]]:
		var b := pub.ball(c[1], c[0], shell, crabs)
		b.scale = Vector3(1.3, 0.45, 1.0)
	_things.crabs = crabs
	# the key on its brass fob shaped like a shield, caught in the wire
	var key7 := Node3D.new()
	trap.add_child(key7)
	key7.position = Vector3(0.36, 0.2, 0.0)
	var brass := pub.mat(Color("a88a4a"), 0.35, 0.7, 2, Vector3.UP, 5.0, 1.0)
	pub.box(Vector3(0.008, 0.07, 0.04), Vector3(0.0, -0.04, 0.0), brass, 0.0, key7)
	pub.box(Vector3(0.004, 0.055, 0.012), Vector3(0.0, 0.03, 0.0), brass, 0.0, key7)
	_things.key7 = key7
	# the rope tied off on the rail, going down into the brown water
	var rope := Node3D.new()
	town_far.add_child(rope)
	var top := Vector3(-197.55, Town.WHARF_Y + 0.98, 93.95)
	var bot := Vector3(-197.0, -0.4, 94.05)
	var r := pub.cyl(0.006, 0.006, top.distance_to(bot), (top + bot) / 2.0, rope_m, rope, 5)
	r.look_at_from_position((top + bot) / 2.0, bot, Vector3.FORWARD)
	r.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	_things.rope = rope
	# table 28 at three in the afternoon: the Shoreline across both tables, a page or two on the floor
	var papers := Node3D.new()
	pub.add_child(papers)
	var newsprint := pub.mat(Color("d8d2c2"), 0.95, 0.0, 1, Vector3(1, 0, 0), 2.5, 1.4)
	var rr := RandomNumberGenerator.new()
	rr.seed = 1105
	for k in 7:
		var at := Pub.T28 + Vector3(rr.randf_range(-0.55, 0.55), 0.785 + k * 0.002, rr.randf_range(-0.35, 0.35))
		pub.box(Vector3(0.58, 0.002, 0.38), at, newsprint, rr.randf_range(-40.0, 40.0), papers)
	pub.box(Vector3(0.58, 0.002, 0.38), Pub.T28 + Vector3(-1.2, 0.001, 0.6), newsprint, 25.0, papers)
	_things.papers = papers
	# the vacuum standing by the pool table, its cord wound round its handle
	var vac := Node3D.new()
	pub.add_child(vac)
	vac.position = Pub.POOL + Vector3(-1.6, 0, 1.2)
	var red := pub.mat(Color("8c2f2a"), 0.6, 0.0, 2, Vector3.UP, 6.0, 0.8)
	pub.box(Vector3(0.3, 0.12, 0.26), Vector3(0, 0.06, 0), red, 0.0, vac)
	pub.cyl(0.07, 0.09, 0.55, Vector3(0, 0.4, -0.06), red, vac, 14)
	pub.cyl(0.012, 0.012, 0.5, Vector3(0, 0.92, -0.08), pub.M.frame, vac, 6)
	for k in 6:
		var coil := MeshInstance3D.new()
		var tm2 := TorusMesh.new()
		tm2.inner_radius = 0.035
		tm2.outer_radius = 0.045
		coil.mesh = tm2
		coil.material_override = pub.M.dark
		coil.position = Vector3(0, 0.62 + k * 0.025, -0.06)
		vac.add_child(coil)
	_things.vacuum = vac
	var sb := Node3D.new()
	pub.add_child(sb)
	sb.position = Vector3(2.22, 1.12, 6.55)
	sb.rotation.y = 0.2
	var card := pub.mat(Color("8e7b5e"), 0.9, 0.0, 2, Vector3.UP, 6.0, 0.8)
	pub.box(Vector3(0.18, 0.11, 0.32), Vector3(0, 0.055, 0), card, 0.0, sb)
	var env := pub.mat(Color("ddd6c4"), 0.9, 0.0, 1, Vector3(1, 0, 0), 3.0, 1.0)
	for k in 14:
		pub.box(Vector3(0.165, 0.1, 0.004), Vector3(0, 0.07, -0.14 + k * 0.02), env, 0.0, sb)
	_things.shoebox = sb
	# the tug and its boom, far out
	var tug := Node3D.new()
	pub.add_child(tug)
	tug.position = Vector3(160.0, -0.39, 330.0)
	var hull := pub.mat(Color("2f3236"), 0.7, 0.1, 2, Vector3.UP, 6.0, 0.8)
	var cab := pub.mat(Color("c9c2b0"), 0.8, 0.0, 2, Vector3.UP, 6.0, 0.8)
	pub.box(Vector3(14.0, 2.6, 5.0), Vector3(0, 0.9, 0), hull, 0.0, tug)
	pub.box(Vector3(5.0, 3.2, 3.6), Vector3(-2.0, 3.6, 0), cab, 0.0, tug)
	pub.box(Vector3(2.4, 1.6, 2.6), Vector3(-2.4, 5.9, 0), cab, 0.0, tug)
	pub.cyl(0.5, 0.5, 3.0, Vector3(1.0, 6.0, 0), hull, tug, 10)
	var logs := pub.mat(Color("5a4734"), 0.95, 0.0, 2, Vector3.RIGHT, 6.0, 0.8)
	var rl := RandomNumberGenerator.new()
	rl.seed = 77
	for k in 70:
		var lg := pub.cyl(0.45, 0.45, rl.randf_range(10.0, 15.0), Vector3(30.0 + (k % 7) * 13.0 + rl.randf_range(-1, 1), 0.1, (floorf(k / 7.0) - 4.5) * 1.6), logs, tug, 8)
		lg.rotation.z = PI / 2.0
		lg.rotation.y = rl.randf_range(-0.05, 0.05)
	_things.tug = tug
