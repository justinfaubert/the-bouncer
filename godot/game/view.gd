# His eyes: the room as he sees it, printed, on the left of the screen.
#
#   the eye     a camera on the room, lit as usual, into a SubViewport
#   the mask    a second camera on the same room from the same place that sees visual layer 20:
#               every surface draws how the key block is cut on it (look/surface.gdshader), and a
#               quad over its view finds the edges and creases in the depth (look/lines.gdshader)
#   the press   a shader over the eye's picture that separates it into the three inks, cuts the key
#               block with the mask and prints it on the paper (look/press.gdshader)
#
# His head turns with a drag across the room, or the arrow keys; the wheel narrows his eyes on
# something far off. Where the pointer rests is where his attention is (game/main.gd asks what's
# there). He walks between places the way world/nav.gd finds round the tables and the stools and
# whoever's standing about, at a man's pace (the space bar hurries him), the doors opening as he
# comes to them, his eyes on the way ahead (unless the player looks somewhere else on the way), and
# when he gets there he's still looking the way he was. Nothing turns his head for him but what would turn a man's: someone
# coming into it (the Ink's #portrait), the dice going down (and back after, unless the player's
# looked away), and sitting down, which turns him to what the seat faces. Never while the player's
# turning it.
#
# Anywhere away from the Sov (Gary's office, the old main street, the Esso, the seawall: world/
# town.gd) he doesn't walk to or from: the page goes blank, as it does on the ladder, and he's
# there. The light is the clock's: grey daylight in the rain at four in the afternoon, dusk, and
# from six on the night exactly as it's always been (daylight()). And once the Sov itself turns
# his head: the first time he comes to it from the town, he's facing its front in the lot
# (Posts.FIRST_SIGHT).
#
# His body is in the print (the review's "the print is his body"): drink slips the plates and
# sways the view, nerves coarsen the cut and bring the red up in the dark, hurt thickens red at the
# edges, his heart pulses the ink, and late in the night the ink starves.
class_name View
extends Node

signal arrived(place: String)

const WORLD_W := 0.655
const MASK_LAYER := 20
const LOOK_EASE := 14.0
const PITCH_MIN := -1.25
const PITCH_MAX := 1.05
# his walk
const PACE := 1.45                # metres a second: a big man going about his work
const PACE_FAR := 1.8             # across the building, he means it
const HURRIED := 2.7              # the space bar
const SETTING_OFF := 1.4          # how quickly he gets up to his pace (metres a second, a second)
const STOPPING := 1.0             # and comes down from it where he's going
const STEP := 0.74                # a big man's step
const AHEAD := 1.7                # how far along the way his eyes are, walking
const DOOR_NEAR := 1.3            # a door opens when he's this far from it on the way
const DOOR_PAST := 1.1            # and swings to when he's this far past it
const TURN := 3.2                 # how fast his head comes round on its own, walking (radians a second)
const STOP := 0.7                 # a stop on the way, where the page has him somewhere and then on (seconds)
const SIGHTED := 3.5              # how far from the end of the way the Sov's front turns his head, the first time

var pub: Pub
var settings: Dictionary
var env: Environment
var eye: SubViewport
var mask: SubViewport
var cam: Camera3D
var mcam: Camera3D
var sheet: TextureRect
var press: ShaderMaterial
var hands: Node3D                 # what's in his hands, carried with his head

var place := "door"
var frame := ""                   # which way a place is seen, where it has more than one (Posts.FRAMES)
var _framed := ""
var eye_pos := Post_default()
var yaw := 0.0
var pitch := 0.0
var want_yaw := 0.0
var want_pitch := 0.0
var zoom := 1.0                   # the wheel: 1 as he is, down to 0.5 narrowing his eyes on something
var want_zoom := 1.0
var focus_fov := 0.0              # a look at something close (the dice): the fov it wants, 0 for none
var walking := false
var on_floor := ""                # "" on the ground floor; "keg" or "upstairs", off it; or the place away from the Sov he's at
var people_at := Callable()       # where the people are, to walk round (game/main.gd: the stage's)
var _nav: Nav
var _legs: Array = []             # the rest of the walk: {"path", "y1"} on foot, {"cut", ...} the ladder or the stairs, {"wait", "look"} a stop
var _path := PackedVector3Array() # the stretch he's on, on the floor
var _len := 0.0
var _s := 0.0                     # how far along it he is
var _v := 0.0                     # how fast he's going
var _y0 := Posts.STAND            # his eyes where the stretch starts (off a stool, they rise)
var _y1 := Posts.STAND            # and where it ends (onto one, they sink)
var _doors: Array = []            # on this stretch: [which, how far along, 0 shut 1 opened 2 swung to]
var _stride := 0.0                # how far he's walked, for his steps
var _off := false                 # he's set off on this stretch (he turns to it first)
var _held := 0.0                  # how long he's been turning to it
var _hurry := false
var _wait := 0.0                  # stopped on the way, for this much longer
var _cut: Tween
var _to := {}                     # the post the walk ends at
var _to_where := ""
var _drag := false
var _drag_from := Vector2.ZERO
var _dragged := 0.0
var pointer := Vector2(-1, -1)    # the pointer over the world's picture, in its pixels; -1 off it
var t := 0.0
var keys_turn := Vector2.ZERO
var turned_t := -INF              # when the player last turned his head themselves
var _walk_t0 := 0.0               # when he set off
var _look_after = null            # a look asked for on the way (someone there), taken when he's there: a point, or who (a Callable giving where their head is by then)

# his body, set by main.gd from the night: drinks (the ones that show), nerves (0..4), hurt (0..3), the clock
var drinks := 0
var tension := 0
var hurt := 0
var clock := 0
var heart := 0.0                  # beats per second, 0 at rest; main.gd raises it for the dice
var _beat := 0.0
var flash := 0.0
# the light by the clock
var _day := -1.0                  # the clock the light's at (it eases to the clock); -1 before there's been one
var _snap := true                 # the next light goes on at once: he's just got somewhere
var _lit := ""                    # the light last put on: its clock and where it was for
var _night := {}                  # the night as _environment() makes it, to go back to exactly
var _first_sight := false         # he's come from the town and not been anywhere at the Sov yet (Posts.FIRST_SIGHT)


static func Post_default() -> Vector3:
	return Posts.POSTS["door"].at


func setup(p: Pub, s: Dictionary, parent: CanvasItem) -> void:
	pub = p
	settings = s
	_environment()
	eye = SubViewport.new()
	eye.msaa_3d = Viewport.MSAA_4X
	eye.positional_shadow_atlas_size = 4096
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	eye.audio_listener_enable_3d = true
	add_child(eye)
	cam = Camera3D.new()
	cam.fov = 58.0
	cam.near = 0.03
	cam.far = 900.0
	cam.environment = env
	cam.set_cull_mask_value(MASK_LAYER, false)
	eye.add_child(cam)
	hands = Node3D.new()
	cam.add_child(hands)
	# the mask: the same room from the same place, drawn as the key block's cut, with the lines
	# found over it (the Compatibility renderer can't read the depth of a multisampled view, so the
	# mask gets its own)
	mask = SubViewport.new()
	mask.world_3d = eye.find_world_3d()
	mask.positional_shadow_atlas_size = 256
	mask.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(mask)
	var menv := Environment.new()
	menv.background_mode = Environment.BG_COLOR
	menv.background_color = Color(0.45, 0.0, 0.0)
	menv.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	menv.ambient_light_color = Color.BLACK
	menv.ambient_light_energy = 0.0
	menv.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	mcam = Camera3D.new()
	mcam.near = cam.near
	mcam.far = cam.far
	mcam.environment = menv
	mcam.cull_mask = 0xFFFFF
	mask.add_child(mcam)
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	quad.mesh = qm
	var lm := ShaderMaterial.new()
	lm.shader = preload("res://look/lines.gdshader")
	quad.material_override = lm
	quad.layers = 0
	quad.set_layer_mask_value(MASK_LAYER, true)
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mcam.add_child(quad)
	quad.position = Vector3(0, 0, -1)

	# the press, over the world's part of the screen
	sheet = TextureRect.new()
	sheet.texture = eye.get_texture()
	sheet.anchor_right = WORLD_W
	sheet.anchor_bottom = 1.0
	sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.stretch_mode = TextureRect.STRETCH_SCALE
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	press = ShaderMaterial.new()
	press.shader = preload("res://look/press.gdshader")
	press.set_shader_parameter("scene", eye.get_texture())
	press.set_shader_parameter("cut_mask", mask.get_texture())
	press.set_shader_parameter("separation", Pub.tex_static("res://press/separation.png", false))
	press.set_shader_parameter("grain", Pub.tex_static("res://press/grain.png", false))
	press.set_shader_parameter("paper_tex", Pub.tex_static("res://press/paper.png", false))
	press.set_shader_parameter("paper", Look.STOCK)
	press.set_shader_parameter("ink_night", Look.NIGHT)
	press.set_shader_parameter("ink_lamp", Look.LAMP)
	press.set_shader_parameter("ink_neon", Look.NEON)
	sheet.material = press
	parent.add_child(sheet)
	sheet.gui_input.connect(_on_sheet_input)
	sheet.mouse_exited.connect(func(): pointer = Vector2(-1, -1))
	get_viewport().size_changed.connect(resize)
	resize()
	RenderingServer.global_shader_parameter_set("cut_scale", 1.0)
	jump_to("door")


func _environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0a0b0f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("3b4250")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color("16181e")
	env.fog_density = 0.01
	_night = {"sky": env.background_color, "ambient": env.ambient_light_color, "ambient_e": env.ambient_light_energy,
		"fog": env.fog_light_color, "fog_d": env.fog_density, "exposure": env.tonemap_exposure}


func resize() -> void:
	var win := Vector2(DisplayServer.window_get_size())
	if win.x < 8 or win.y < 8:
		win = Vector2(1920, 1080)
	var k := clampf(float(settings.get("render", 1.0)), 0.4, 1.0)
	var size := Vector2i(maxi(64, roundi(win.x * WORLD_W * k)), maxi(64, roundi(win.y * k)))
	eye.size = size
	mask.size = size
	press.set_shader_parameter("view_px", Vector2(size))


# ---------------------------------------------------------------- where he is

func jump_to(where: String) -> void:
	if _cut != null and _cut.is_valid():
		_cut.kill()
	_cut = null
	# a door he had open on the way, shut behind him at once
	for d in _doors:
		if d[2] == 1:
			pub.swing_door(d[0], false, true)
	_doors = []
	flash = 0.0
	walking = false
	_legs.clear()
	_path = PackedVector3Array()
	_v = 0.0
	_wait = 0.0
	_look_after = null
	place = where
	_framed = frame
	on_floor = where if Posts.FLIGHTS.has(where) or Posts.away(where) else ""
	pub.lift_trap(on_floor == "keg", true)
	var p := Posts.post(where, frame)
	eye_pos = p.at
	var first = _first_look(where)
	var a := Posts.aim(eye_pos, first if first != null else p.look)
	yaw = a.x
	pitch = a.y
	want_yaw = yaw
	want_pitch = pitch
	_got_to(where)
	pub.shadows_near(eye_pos)
	_apply()


# Somewhere new, in a jump or the blank of a cut: the town there or put away (world/town.gd), his
# eyes' nearest focus (out in the open, the far things want the depth: nothing comes that close),
# and the light for here, at once.
func _got_to(where: String) -> void:
	pub.away(where, clock, _framed)
	var near := 0.03 if not Posts.away(where) or where == "office" else 0.1
	cam.near = near
	mcam.near = near
	_snap = true
	_light_step(0.0, true)


# Walk to a place: round things, through the doors; down the ladder or up the stairs, the page goes
# blank for a moment. Instant: just be there. Then: on from where he's already going, after a moment
# there, when the page moves him twice at once (over to the bar, then the man walked to the door).
func walk_to(where: String, instant := false, then := false) -> void:
	if where == place and frame == _framed and not walking:
		return
	if instant or where == "":
		jump_to(where)
		arrived.emit(where)
		return
	if then and walking:
		if where == place and frame == _framed:
			return
		_then(where)
		return
	if where != place or frame != _framed:
		_look_after = null
	# a walk asked for in the middle of a cut: the cut's done first, at once, and the rest of the walk
	# it was on goes with it (its end would go on to that)
	if _cut != null and _cut.is_valid():
		var cut := _cut
		_legs.clear()
		cut.custom_step(10.0)
		if cut.is_valid():
			cut.kill()
	_cut = null
	flash = 0.0
	place = where
	_framed = frame
	_to = Posts.post(where, frame)
	_to_where = where
	# a door he'd opened on the way he was going swings to behind him
	for d in _doors:
		if d[2] == 1:
			pub.swing_door(d[0], false)
	_doors = []
	_legs = _plan(where, _to, eye_pos, on_floor)
	walking = true
	_walk_t0 = t
	_hurry = false
	_path = PackedVector3Array()
	_next_leg()


# the next place after the one he's on his way to: he stops there, on his feet (not onto its stool),
# looks the way it looks for a moment, and goes on
func _then(where: String) -> void:
	var last_path := -1
	for i in _legs.size():
		if _legs[i].has("path"):
			last_path = i
	if last_path >= 0:
		_legs[last_path]["y1"] = Posts.STAND
	elif not _path.is_empty():
		_y1 = Posts.STAND
	var stop_at: Vector3 = _to.at
	var off_floor: bool = Posts.FLIGHTS.has(_to_where) or Posts.away(_to_where)
	if not off_floor:
		stop_at.y = Posts.STAND
	_legs.append({"wait": STOP, "look": _to.look})
	place = where
	_framed = frame
	var p := Posts.post(where, frame)
	_legs.append_array(_plan(where, p, stop_at, _to_where if off_floor else ""))
	_to = p
	_to_where = where


# the space bar, on the way: he hurries
func hurry() -> void:
	if walking:
		_hurry = true
		_wait = minf(_wait, 0.1)


# The walk, in stretches: off the floor he's on (up the ladder, down the stairs), across the ground
# floor, and onto the one he's going to. To or from anywhere away from the Sov, one cut, straight
# there; another way of seeing the same place from the same chair is only a turn of his head.
func _plan(where: String, p: Dictionary, from: Vector3, off: String) -> Array:
	if Posts.away(where) or Posts.away(off):
		if where == off and from.distance_to(p.at) < 0.05:
			return []
		var to_floor := where if Posts.away(where) or Posts.FLIGHTS.has(where) else ""
		return [{"cut": p.at, "floor": to_floor, "after": p.look, "away": where}]
	var legs: Array = []
	if off != "":
		var up: Dictionary = Posts.FLIGHTS[off]
		var top := Vector3(up.from.x, Posts.STAND, up.from.z)
		legs.append({"cut": top, "floor": "", "lid": off == "keg"})
		from = top
	var to: Vector3 = p.at
	var flight := ""
	if Posts.FLIGHTS.has(where):
		flight = where
		to = Posts.FLIGHTS[where].from + Vector3(0, Posts.STAND, 0)
	var path := _route(from, to)
	if path.size() >= 2 and Nav.length_of(path) > 0.02:
		legs.append({"path": path, "y1": to.y})
	if flight != "":
		legs.append({"cut": p.at, "floor": flight, "before": Posts.FLIGHTS[flight].look, "after": p.look, "lid": flight == "keg"})
	return legs


# the way across the ground floor, round whoever's in it (if there's no way round them, through)
func _route(a: Vector3, b: Vector3) -> PackedVector3Array:
	if _nav == null:
		_nav = Nav.new()
	var people: Array = people_at.call() if people_at.is_valid() else []
	var path := _nav.way(a, b, people)
	if path.is_empty() and not people.is_empty():
		path = _nav.way(a, b)
	if path.is_empty():
		path = PackedVector3Array([Vector3(a.x, 0, a.z), Vector3(b.x, 0, b.z)])
	return path


func _next_leg() -> void:
	if _legs.is_empty():
		_arrive()
		return
	var leg: Dictionary = _legs.pop_front()
	if leg.has("cut"):
		_cut_to(leg)
		return
	if leg.has("wait"):
		_path = PackedVector3Array()
		_v = 0.0
		_wait = 0.1 if _hurry else float(leg.wait)
		if turned_t <= _walk_t0:
			var a := Posts.aim(eye_pos, leg.look)
			want_yaw = _near_angle(yaw, a.x)
			want_pitch = clampf(a.y, PITCH_MIN, PITCH_MAX)
		return
	_path = leg.path
	_len = Nav.length_of(_path)
	_s = 0.0
	_y0 = eye_pos.y
	_y1 = float(leg.y1)
	_doors = Posts.doors_on(_path)
	_off = false
	_held = 0.0


# On the way: at his pace, getting up to it and coming down from it, his eyes on the way ahead.
func _walking(dt: float) -> void:
	if _wait > 0.0:
		_wait -= dt
		if _wait <= 0.0:
			_wait = 0.0
			_next_leg()
		return
	if _path.is_empty():
		return
	# facing away from the way, he turns to it before he sets off (off a stool, he swivels on it)
	var mine := turned_t <= _walk_t0
	if not _off:
		var first: Vector3 = Nav.at(_path, minf(AHEAD, _len))[0]
		var dd := Vector2(first.x - eye_pos.x, first.z - eye_pos.z)
		if mine and _held < 0.8 and dd.length() > 0.25 and absf(wrapf(atan2(-dd.x, -dd.y) - yaw, -PI, PI)) > 0.9:
			want_yaw = _near_angle(yaw, atan2(-dd.x, -dd.y))
			want_pitch = -0.1
			_held += dt
			return
		_off = true
	var cruise := HURRIED if _hurry else (PACE_FAR if _len > 9.0 else PACE)
	var left := _len - _s
	_v = minf(_v + SETTING_OFF * dt, cruise)
	_v = minf(_v, sqrt(2.0 * STOPPING * maxf(left, 0.0)) + 0.12)
	var ds := minf(maxf(_v, 0.12) * dt, left)
	_s += ds
	_stride += ds
	left = _len - _s
	var here: Vector3 = Nav.at(_path, _s)[0]
	# off a stool his eyes rise in the first steps; onto one, they sink in the last
	var up := minf(0.55, _len * 0.45)
	var down := minf(0.5, _len * 0.45)
	var y := Posts.STAND + (_y0 - Posts.STAND) * (1.0 - smoothstep(0.0, up, _s)) + (_y1 - Posts.STAND) * smoothstep(_len - down, _len, _s)
	eye_pos = Vector3(here.x, y, here.z)
	for d in _doors:
		if d[2] == 0 and _s >= float(d[1]) - DOOR_NEAR:
			pub.swing_door(d[0], true)
			d[2] = 1
		elif d[2] == 1 and _s >= float(d[1]) + DOOR_PAST:
			pub.swing_door(d[0], false)
			d[2] = 2
	var sight = _sight_ahead()
	if mine and _legs.is_empty() and sight != null and left < SIGHTED:
		# round the front of the Sov the first time: it turns his head as he comes to it
		var a0 := Posts.aim(Vector3(here.x, _y1, here.z), sight)
		want_yaw = _near_angle(yaw, a0.x)
		want_pitch = clampf(a0.y, PITCH_MIN, PITCH_MAX)
	elif mine and _legs.is_empty() and _to.get("seat", false) and left < 0.9:
		# sitting down: he turns to what the seat faces as he comes to it
		var a := Posts.aim(Vector3(here.x, _y1, here.z), _to.look)
		want_yaw = _near_angle(yaw, a.x)
		want_pitch = clampf(a.y, PITCH_MIN, PITCH_MAX)
	elif mine and left > 0.4:
		var ahead: Vector3 = Nav.at(_path, minf(_s + AHEAD, _len))[0]
		var d2 := Vector2(ahead.x - here.x, ahead.z - here.z)
		if d2.length() > 0.25:
			want_yaw = _near_angle(yaw, atan2(-d2.x, -d2.y))
		want_pitch = -0.1
	if left <= 0.0001:
		for d in _doors:
			if d[2] == 1:
				pub.swing_door(d[0], false)
				d[2] = 2
		_path = PackedVector3Array()
		_next_leg()


# Down the ladder, up the stairs: he looks at the way down or up, the page goes blank, and he comes
# out of it on the other floor looking at the room (or, back on the ground floor, the way he's going).
# To or from somewhere away from the Sov, the page goes blank where he is, a little longer, and he
# comes out of it there.
func _cut_to(leg: Dictionary) -> void:
	_v = 0.0
	var to: Vector3 = leg.cut
	var away = leg.get("away")
	_cut = create_tween()
	var before = leg.get("before")
	if before != null and turned_t <= _walk_t0:
		var a := Posts.aim(eye_pos, before)
		want_yaw = _near_angle(yaw, a.x)
		want_pitch = clampf(a.y, PITCH_MIN, PITCH_MAX)
		_cut.tween_interval(0.35)
	if leg.get("lid", false) and on_floor == "":
		_cut.tween_callback(func(): pub.lift_trap(true))
		_cut.tween_interval(0.3)
	_cut.tween_property(self, "flash", 1.0, 0.3)
	_cut.tween_callback(func():
		eye_pos = to
		on_floor = str(leg.floor)
		if on_floor == "" and leg.get("lid", false):
			pub.lift_trap(false, true)
		if away != null:
			pub.lift_trap(on_floor == "keg", true)
			_got_to(str(away))
		pub.shadows_near(to)
		# the page is blank: his head's where it'd be coming off the ladder or the stairs (or, back
		# from the town to the Sov's front the first time, on the Sov)
		var look_at = leg.get("after")
		if away != null and _legs.is_empty():
			var first = _first_look(str(away))
			if first != null:
				look_at = first
		if look_at == null and not _legs.is_empty() and _legs[0].has("path"):
			look_at = Nav.at(_legs[0].path, AHEAD)[0] + Vector3(0, to.y - 0.3, 0)
		if look_at != null:
			var a2 := Posts.aim(to, look_at)
			yaw = _near_angle(yaw, a2.x)
			pitch = clampf(a2.y, PITCH_MIN, PITCH_MAX)
			want_yaw = yaw
			want_pitch = pitch)
	_cut.tween_interval(0.15 if away == null else 0.35)
	_cut.tween_property(self, "flash", 0.0, 0.45)
	_cut.tween_callback(func():
		_cut = null
		_next_leg())


# there: still looking the way he was, unless someone there's turned his head on the way, or he's
# sat down, which turns him to what the seat faces, or it's the Sov's front, the first time
func _arrive() -> void:
	walking = false
	_path = PackedVector3Array()
	_v = 0.0
	var to = _look_after
	_look_after = null
	if to is Callable:
		to = (to as Callable).call()
		if to == Vector3.INF:
			to = null
	var first = _first_look(_to_where)
	if to == null and first != null:
		to = first
	if to == null and _to.get("seat", false):
		to = _to.look
	if to != null:
		look_at_point(to)
	pub.shadows_near(eye_pos)
	arrived.emit(_to_where)


# He's got somewhere: a jump, the end of a walk, the blank of a cut. The first time he's at the
# Sov's front after the town, what it turns his head to (Posts.FIRST_SIGHT), and null any other
# time. Being away from the Sov sets it up; being anywhere at the Sov but his room on the way uses
# it up.
func _first_look(where: String) -> Variant:
	if Posts.away(where):
		_first_sight = true
		return null
	if not _first_sight or where in Posts.FIRST_SIGHT.through:
		return null
	_first_sight = false
	return Posts.FIRST_SIGHT.look if where == Posts.FIRST_SIGHT.place else null


# on his way to the Sov's front the first time after the town: what it'll turn his head to, or null
func _sight_ahead() -> Variant:
	if _first_sight and _to_where == Posts.FIRST_SIGHT.place:
		return Posts.FIRST_SIGHT.look
	return null


func _near_angle(from: float, to: float) -> float:
	return from + wrapf(to - from, -PI, PI)


# turn his head to look at something (it eases there): not while the player's turning it, and on
# the way somewhere, once he's there
# Someone who may have moved by the time he's there (the bartender coming along the bar to him):
# head gives where their head is, Vector3.INF if they've gone.
func look_at_who(head: Callable) -> void:
	if walking:
		_look_after = head
		return
	var p: Vector3 = head.call()
	if p != Vector3.INF:
		look_at_point(p)


func look_at_point(p: Vector3, _how_fast := 1.0) -> void:
	if walking:
		_look_after = p
		return
	if turning():
		return
	var a := Posts.aim(eye_pos, p)
	want_yaw = _near_angle(yaw, a.x)
	want_pitch = clampf(a.y, PITCH_MIN, PITCH_MAX)


func looking_toward(p: Vector3) -> float:
	# how nearly he's looking at a point: the angle off the middle of his view, radians
	var fwd := -cam.global_transform.basis.z
	return fwd.angle_to((p - cam.global_position).normalized())


# ---------------------------------------------------------------- the pointer and the head

func _on_sheet_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		pointer = e.position / sheet.size * Vector2(eye.size)
		if _drag:
			var k := 0.0042 * float(settings.get("look_speed", 1.0)) * zoom
			_dragged += e.relative.length()
			if _dragged > 6.0:
				turned_t = t
				want_yaw -= e.relative.x * k
				want_pitch = clampf(want_pitch - e.relative.y * k * (-1.0 if settings.get("invert", false) else 1.0), PITCH_MIN, PITCH_MAX)
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			want_zoom = clampf(want_zoom - 0.08, 0.45, 1.0)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			want_zoom = clampf(want_zoom + 0.08, 0.45, 1.0)
		elif e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if e.pressed:
				_drag = true
				_drag_from = e.position
				_dragged = 0.0
			else:
				_drag = false


# a click on the room that wasn't a drag
func was_click() -> bool:
	return _dragged <= 6.0


func dragging() -> bool:
	return _drag and _dragged > 6.0


# the player's turning his head right now: a drag, or the keys or a stick held
func turning() -> bool:
	return dragging() or keys_turn != Vector2.ZERO


# the ray from his eyes through the pointer (or the middle of his view), in the world
func ray(from_pointer := true) -> Array:
	var p := pointer if from_pointer and pointer.x >= 0.0 else Vector2(eye.size) / 2.0
	return [cam.project_ray_origin(p), cam.project_ray_normal(p)]


# where a point in the world is on the screen (the canvas the UI is laid out in), and whether
# it's in front of him
func on_screen(p: Vector3) -> Vector3:
	if cam.is_position_behind(p):
		return Vector3(-1, -1, 0)
	var v := cam.unproject_position(p)
	var s := v / Vector2(eye.size) * sheet.size + sheet.global_position
	return Vector3(s.x, s.y, 1.0)


func _process(dt: float) -> void:
	t += dt
	# the arrow keys, and the keys by them
	if keys_turn != Vector2.ZERO:
		turned_t = t
		want_yaw -= keys_turn.x * dt * 1.6 * float(settings.get("look_speed", 1.0)) * zoom
		want_pitch = clampf(want_pitch + keys_turn.y * dt * 1.2 * zoom, PITCH_MIN, PITCH_MAX)
	if walking:
		_walking(dt)
	var k := 1.0 - exp(-dt * LOOK_EASE)
	var dyaw := (want_yaw - yaw) * k
	var dpitch := (want_pitch - pitch) * k
	if walking and turned_t <= _walk_t0:
		# walking, his head comes round as a head does, not as the pointer can
		dyaw = clampf(dyaw, -TURN * dt, TURN * dt)
		dpitch = clampf(dpitch, -TURN * 0.6 * dt, TURN * 0.6 * dt)
	yaw += dyaw
	pitch += dpitch
	zoom = lerpf(zoom, want_zoom, 1.0 - exp(-dt * 8.0))
	_skin(dt)
	_light_step(dt)
	_apply()


func _apply() -> void:
	if cam == null:
		return
	var sway := 0.0
	var roll := 0.0
	var dy := 0.0
	var dp := 0.0
	if bool(settings.get("sway", true)) and bool(settings.get("skin", true)):
		var d := clampf(drinks / 8.0, 0.0, 1.0)
		sway = d * 0.035 * sin(t * 0.43) + d * 0.02 * sin(t * 1.13 + 1.0)
		dp = d * 0.02 * sin(t * 0.61 + 2.0)
		roll = d * 0.045 * sin(t * 0.37 + 0.5)
	# his steps: down at each footfall, up over the foot, and a little from side to side, as much as
	# he's going
	var side := 0.0
	if walking and not _path.is_empty():
		var k := clampf(_v / PACE, 0.0, 1.3)
		var ph := _stride / STEP * PI
		dy = (absf(sin(ph)) - 0.64) * 0.018 * k
		side = sin(ph) * 0.012 * k
		roll += sin(ph) * 0.004 * k
	var basis := Basis.from_euler(Vector3(pitch + dp, yaw + sway, roll))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	cam.global_transform = Transform3D(basis, eye_pos + Vector3(0, dy, 0) + right * side)
	var base := float(settings.get("fov", 58.0))
	var f := base * zoom
	if focus_fov > 0.0:
		f = focus_fov
	cam.fov = lerpf(cam.fov, f, 0.25) if absf(cam.fov - f) > 0.05 else f
	mcam.global_transform = cam.global_transform
	mcam.fov = cam.fov
	_pin_press()


# Tell the press where he's looking, so the grain and the paper stay put as he turns his head.
# The grain repeats a whole number of times round the circle, so there's no seam behind him.
func _pin_press() -> void:
	var half := deg_to_rad(cam.fov) / 2.0
	var ppr := (eye.size.y / 2.0) / tan(half)
	var grain_px := 1.5 * float(settings.get("grain", 1.0)) * (eye.size.y / 1080.0)
	grain_px = maxf(grain_px, 0.75)
	var tile := 512.0 * grain_px
	ppr = roundf(TAU * ppr / tile) * tile / TAU
	press.set_shader_parameter("cam_basis", cam.global_transform.basis)
	press.set_shader_parameter("tan_half_fov", tan(half))
	press.set_shader_parameter("px_per_rad", ppr)
	press.set_shader_parameter("grain_px", grain_px)
	press.set_shader_parameter("paper_px", grain_px)
	press.set_shader_parameter("time", t)
	press.set_shader_parameter("flash", flash)


# ---------------------------------------------------------------- the light by the clock

# The light outside by the clock, on the 4th of November under cloud, sunset at ten to five: grey
# daylight in the rain at four; dusk at twenty to five, the lamps coming on; the canopy's light over
# everything at five to five; a slate sky by ten past, the Sov lit. Past the last row it goes on into
# the night, and from NIGHT_FROM (and before the night has a clock at all) it's the night exactly as
# _environment() makes it and the press as it's always been. Each row: the clock, the sky, the
# ambient light and how much of it, the fog and how thick, the exposure, the cloud's own light (a
# soft key from the west, out of doors only), and the press's lift and white point. A daylit scene is
# mostly light, and the press prints light as paper: the exposure keeps the surfaces in the middle
# tones, where the key block cuts strokes, and a lift nearer 1 keeps those from opening up to paper.
const DAY := [
	[960, Color("d6d9da"), Color("9aa1a8"), 2.6, Color("c4c9cc"), 0.005, 1.35, 1.4, 0.85, 0.95],
	[1000, Color("b9bec2"), Color("858c95"), 1.5, Color("9da3aa"), 0.0055, 1.05, 0.7, 0.88, 0.96],
	[1015, Color("76808c"), Color("5f6774"), 0.9, Color("646c78"), 0.0065, 1.2, 0.3, 0.84, 0.94],
	[1030, Color("4f5967"), Color("4a5260"), 0.7, Color("424955"), 0.0075, 1.35, 0.08, 0.78, 0.93],
	[1055, Color("14161c"), Color("3c4351"), 0.58, Color("1a1c23"), 0.009, 1.46, 0.0, 0.73, 0.92],
]
const NIGHT_FROM := 1100
const PRESS_NIGHT := [0.72, 0.92]  # the press's own lift and white point (look/press.gdshader), where the dusk ends
const INDOORS := 0.8            # the ambient light in Gary's front room, against outside: the one window


# The light for a clock: put on at once (as at the start of a night, or after a cut), or eased to
# from the light there is, when the clock moves on while he stays where he is. main.gd sets `clock`
# from the night's status; this follows it on its own.
func daylight(at: int, now := false) -> void:
	clock = at
	if now:
		_snap = true
	_light_step(0.0, now)


func _light_step(dt: float, force := false) -> void:
	# the page going blank: the light changes in the blank
	if not force and _cut != null and _cut.is_valid():
		return
	var want := float(clock)
	# just got somewhere, or the clock's jumped (a night begun, a night loaded): no easing to it
	if _snap or _day < 0.0 or absf(want - _day) > 30.0:
		_day = want
		_snap = false
	elif absf(want - _day) > 0.05:
		_day = lerpf(_day, want, 1.0 - exp(-dt * 0.9))
	else:
		_day = want
	var key := "%.1f %s" % [_day, place]
	if key == _lit:
		return
	_lit = key
	_put_light(_day)


func _put_light(c: float) -> void:
	var key: DirectionalLight3D = pub.town.key if pub.town != null else null
	pub.dusk(c, place)
	if c >= NIGHT_FROM or c < float(DAY[0][0]) - 60.0:
		env.background_color = _night.sky
		env.ambient_light_color = _night.ambient
		env.ambient_light_energy = _night.ambient_e
		env.fog_light_color = _night.fog
		env.fog_density = _night.fog_d
		env.tonemap_exposure = _night.exposure
		press.set_shader_parameter("lift", null)
		press.set_shader_parameter("levels_in", null)
		if key != null:
			key.visible = false
		return
	var r := _day_row(c)
	env.background_color = r[0]
	env.ambient_light_color = r[1]
	env.ambient_light_energy = r[2] * (INDOORS if place == "office" else 1.0)
	env.fog_light_color = r[3]
	env.fog_density = r[4]
	env.tonemap_exposure = r[5]
	press.set_shader_parameter("lift", r[7])
	press.set_shader_parameter("levels_in", Vector2(0.0, r[8]))
	if key != null:
		key.light_energy = r[6]
		key.visible = r[6] > 0.001 and Posts.away(place)


# the light at a clock, between the rows of DAY, and past the last of them on into the night
func _day_row(c: float) -> Array:
	var night := [_night.sky, _night.ambient, _night.ambient_e, _night.fog, _night.fog_d, _night.exposure, 0.0,
		PRESS_NIGHT[0], PRESS_NIGHT[1]]
	var rows: Array = []
	for row in DAY:
		rows.append([float(row[0]), row.slice(1)])
	rows.append([float(NIGHT_FROM), night])
	if c <= rows[0][0]:
		return rows[0][1]
	for i in range(1, rows.size()):
		if c <= rows[i][0]:
			var k: float = (c - rows[i - 1][0]) / (rows[i][0] - rows[i - 1][0])
			var a: Array = rows[i - 1][1]
			var b: Array = rows[i][1]
			var out: Array = []
			for j in a.size():
				out.append(a[j].lerp(b[j], k) if a[j] is Color else lerpf(float(a[j]), float(b[j]), k))
			return out
	return night


# ---------------------------------------------------------------- his body in the print

func _skin(dt: float) -> void:
	var on := bool(settings.get("skin", true))
	# his heart: faster with nerves, and when main.gd says the dice are in his hand
	var bps := heart if heart > 0.0 else (1.1 + 0.12 * tension if tension >= 2 else 0.0)
	var p := 0.0
	if bps > 0.0 and on:
		_beat += dt * bps
		var ph := fmod(_beat, 1.0)
		# a beat and its echo: lub, dub
		p = exp(-pow((ph - 0.05) / 0.05, 2.0)) + 0.55 * exp(-pow((ph - 0.24) / 0.05, 2.0))
	var slip := 0.0
	if on:
		slip = clampf((drinks - 1) * 1.25, 0.0, 9.0)
	press.set_shader_parameter("slip", slip)
	press.set_shader_parameter("pulse", clampf(p, 0.0, 1.0) * (0.6 if hurt > 0 or tension >= 2 or heart > 0.0 else 0.0))
	press.set_shader_parameter("bleed", (clampf((tension - 1) * 0.11, 0.0, 0.33) if on else 0.0))
	press.set_shader_parameter("hurt", (clampf(hurt * 0.3, 0.0, 0.85) if on else 0.0))
	var late := clampf((clock - 1500) / 90.0, 0.0, 1.0)
	press.set_shader_parameter("starve", late * 0.35 if on else 0.0)
	RenderingServer.global_shader_parameter_set("cut_scale", (1.0 + clampf(tension - 1, 0, 3) * 0.14) if on else 1.0)
