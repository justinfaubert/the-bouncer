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
# there). He walks between places along the ways in world/posts.gd, through the doors.
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
var _walk: Tween
var _drag := false
var _drag_from := Vector2.ZERO
var _dragged := 0.0
var pointer := Vector2(-1, -1)    # the pointer over the world's picture, in its pixels; -1 off it
var t := 0.0
var keys_turn := Vector2.ZERO

# his body, set by main.gd from the night: drinks, nerves (0..4), hurt (0..3), the clock
var drinks := 0
var tension := 0
var hurt := 0
var clock := 0
var heart := 0.0                  # beats per second, 0 at rest; main.gd raises it for the dice
var _beat := 0.0
var flash := 0.0


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
	if _walk != null and _walk.is_valid():
		_walk.kill()
	walking = false
	place = where
	_framed = frame
	var p := Posts.post(where, frame)
	eye_pos = p.at
	var a := Posts.aim(eye_pos, p.look)
	yaw = a.x
	pitch = a.y
	want_yaw = yaw
	want_pitch = pitch
	pub.shadows_near(eye_pos)
	_apply()


# Walk to a place along the ways, through the doors; up a ladder or a flight of stairs, the page
# goes blank for a moment. Instant: just be there.
func walk_to(where: String, instant := false) -> void:
	if where == place and frame == _framed and not walking:
		look_at_point(Posts.post(where, frame).look, 0.6)
		return
	if instant or where == "":
		jump_to(where)
		arrived.emit(where)
		return
	var from := place
	var from_frame := _framed
	var steps := Posts.way(from, where)
	# seen from somewhere of its own (the front desk), he goes back to the place's post first
	var from_node: String = Posts.post(from, from_frame).node
	if from_node != Posts.post(from).node and not steps.is_empty():
		steps.push_front([Posts.post(from).node, "walk"])
	place = where
	_framed = frame
	if _walk != null and _walk.is_valid():
		_walk.kill()
	walking = true
	_walk = create_tween()
	var p := Posts.post(where, frame)
	if steps.is_empty():
		# the same place seen another way: walk across it
		steps = [[p.node, "walk"]]
	var at := eye_pos
	var last_node: String = from_node
	var speed := 2.3
	for s in steps:
		var node: String = s[0]
		var how: String = s[1]
		var n: Vector3 = Posts.NODES[node]
		var target := Vector3(n.x, n.y + Posts.STAND, n.z)
		if node == p.node:
			target = p.at
		if how == "cut":
			_walk.tween_property(self, "flash", 1.0, 0.25)
			_walk.tween_callback(func():
				eye_pos = target
				var a0 := Posts.aim(target, p.look)
				yaw = a0.x
				pitch = a0.y
				want_yaw = yaw
				want_pitch = pitch
				pub.shadows_near(target))
			_walk.tween_interval(0.15)
			_walk.tween_property(self, "flash", 0.0, 0.45)
		else:
			var dur := clampf(at.distance_to(target) / speed, 0.25, 3.0)
			var door: String = Posts.DOORS_ON.get(last_node + "|" + node, "")
			if door != "":
				_walk.tween_callback(func(): pub.swing_door(door, true))
			var a1 := Posts.aim(at, Vector3(target.x, at.y - 0.15, target.z))
			var tgt := target
			_walk.tween_callback(func():
				want_yaw = _near_angle(yaw, a1.x)
				want_pitch = a1.y)
			_walk.tween_method(func(v: Vector3): eye_pos = v, at, tgt, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			if door != "":
				_walk.tween_callback(func(): pub.swing_door(door, false))
		at = target
		last_node = node
	_walk.tween_callback(func():
		walking = false
		var a2 := Posts.aim(eye_pos, p.look)
		want_yaw = _near_angle(yaw, a2.x)
		want_pitch = a2.y
		pub.shadows_near(eye_pos)
		arrived.emit(where))


func _near_angle(from: float, to: float) -> float:
	return from + wrapf(to - from, -PI, PI)


# turn his head to look at something (it eases there)
func look_at_point(p: Vector3, _how_fast := 1.0) -> void:
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
		want_yaw -= keys_turn.x * dt * 1.6 * float(settings.get("look_speed", 1.0)) * zoom
		want_pitch = clampf(want_pitch + keys_turn.y * dt * 1.2 * zoom, PITCH_MIN, PITCH_MAX)
	var k := 1.0 - exp(-dt * LOOK_EASE)
	yaw = lerpf(yaw, want_yaw, k)
	pitch = lerpf(pitch, want_pitch, k)
	zoom = lerpf(zoom, want_zoom, 1.0 - exp(-dt * 8.0))
	_skin(dt)
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
	if walking:
		dy = sin(t * 11.0) * 0.012
	var basis := Basis.from_euler(Vector3(pitch + dp, yaw + sway, roll))
	cam.global_transform = Transform3D(basis, eye_pos + Vector3(0, dy, 0))
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
