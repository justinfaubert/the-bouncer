extends SceneTree
# The Listener's looks (look/listener.gdshader) out on the strait off the seawall, printed by the
# real press: a still of each look far off, face to face, and narrowed on (the wheel), and runs of
# frames of the ones that move, for loops (LOOPS: what it hears and how high it's risen, frame by
# frame). Only the world's part of the screen is kept. Needs a display (xvfb-run) and the
# Compatibility renderer:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#     --path godot -s res://tests/shots_listener.gd -- --out /tmp/listener [--only tiles_near,rising_far] \
#     [--clock 1030] [--dry]
#
# The six views round its centre are what its glass and its mirror give back; the man leaning on
# the seawall where he's sitting is on a layer only they see (GHOST_LAYER), so he's only in the
# reflection. The world inside is the Sov's own room from its front corner (INSIDE_AT).

var main
var out := "/tmp/listener"
var only: Array = []
var dry := false            # rain off: the looks only
var clock := 1150           # ten past seven, after dark; 1030 for ten past five, the grey daylight

var sphere: MeshInstance3D
var mat: ShaderMaterial
var cubes: Array = []        # [SubViewport, Camera3D, face] for each of the six faces
var inside: SubViewport
var inside_cam: Camera3D
var ghost: Node3D
var ripples: MeshInstance3D
var ripple_mat: ShaderMaterial

const SPHERE_LAYER := 18
const GHOST_LAYER := 19
const MASK_LAYER := 20
const CUBE_PX := 384
const WATER_Y := -0.39
# the six faces: the way each looks, and its up (the shader takes them the same way)
const FACES := [
	["cube_px", Vector3(1, 0, 0), Vector3(0, 1, 0)], ["cube_nx", Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	["cube_py", Vector3(0, 1, 0), Vector3(0, 0, -1)], ["cube_ny", Vector3(0, -1, 0), Vector3(0, 0, 1)],
	["cube_pz", Vector3(0, 0, 1), Vector3(0, 1, 0)], ["cube_nz", Vector3(0, 0, -1), Vector3(0, 1, 0)],
]
const INSIDE_AT := [Vector3(15.3, 2.7, 9.5), Vector3(3.0, 0.9, 2.6)]

# the looks: its look, how the press cuts it, and what it's hearing
const LOOKS := {
	"black": {"look": 0, "cut": 3},
	"point": {"look": 1, "cut": 3},
	"inside": {"look": 2, "cut": 3},
	"tiles": {"look": 3, "cut": 3},
	"tiles_strokes": {"look": 3, "cut": 4},
	"mirror": {"look": 4, "cut": 4},
	"waves": {"look": 5, "cut": 3},
	"inside_clean": {"look": 2, "cut": 5},
	"black_twice": {"look": 0, "cut": 3, "twice": true},
	"listener": {"look": 6, "cut": 3, "twice": true},
	"listener_hears": {"look": 6, "cut": 3, "hear": 1.0, "twice": true},
	"listener_strokes": {"look": 6, "cut": 4, "hear": 1.0, "twice": true},
	"listener_once": {"look": 6, "cut": 3},
	"listener_clean": {"look": 6, "cut": 5, "hear": 1.0},
}
# where it is and how big, and how he's looking at it (his eyes on the seawall, turned to the water)
const PLACES := {
	"far": {"c": Vector3(-14.0, 5.0, 150.0), "r": 6.0, "zoom": 1.0, "aim": Vector3(-10.0, 2.0, 150.0)},
	"near": {"c": Vector3(8.0, 3.5, 53.0), "r": 4.2, "zoom": 1.0, "aim": Vector3(8.0, 3.0, 53.0)},
	"close": {"c": Vector3(8.0, 3.5, 53.0), "r": 4.2, "zoom": 0.5, "aim": Vector3(8.0, 3.6, 53.0)},
}
# the runs of frames: the look, the place, how many frames, seconds a frame, and what happens
const LOOPS := {
	# it hears something (the jukebox from across the highway): the tiles come up and go down
	"hearing_near": {"look": "listener", "place": "near", "n": 96, "dt": 1.0 / 12.0, "hear": "swell"},
	"hearing_close": {"look": "listener", "place": "close", "n": 96, "dt": 1.0 / 12.0, "hear": "swell"},
	# it comes up out of the water
	"rising_far": {"look": "listener", "place": "far", "n": 108, "dt": 1.0 / 12.0, "rise": true},
	"rising_near": {"look": "listener", "place": "near", "n": 108, "dt": 1.0 / 12.0, "rise": true},
	# the other looks, moving
	"tiles_turning": {"look": "tiles", "place": "near", "n": 72, "dt": 1.0 / 6.0},
	"point_turning": {"look": "point", "place": "near", "n": 48, "dt": 1.0 / 12.0},
	"waves_turning": {"look": "waves", "place": "near", "n": 48, "dt": 1.0 / 12.0},
}
const ORDER := ["black", "black_twice", "point", "inside", "tiles", "tiles_strokes", "mirror", "waves", "inside_clean",
	"listener", "listener_hears", "listener_strokes", "listener_once", "listener_clean"]

# the rings it makes in the water where it breaks the surface; the eye's only, like a lamp's pool
const RIPPLES := """shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled;
uniform float t = 0.0;
uniform float r0 = 1.0;        // where it meets the water, from its middle, in metres
uniform float strength = 0.0;
uniform float extent = 30.0;   // the quad's half width, in metres
void fragment() {
	if ((CAMERA_VISIBLE_LAYERS & 524288u) != 0u) {
		discard;
	}
	vec2 p = (UV - 0.5) * 2.0 * extent;
	float d = length(p) - r0;
	if (d < -0.05) {
		discard;
	}
	float px = max(fwidth(d), 1e-4);
	// rings going out, each fainter as it goes and as it spreads
	float ph = d * 0.9 - t * 2.4;
	float ring = 1.0 - smoothstep(px * 0.6, px * 1.8 + 0.02, abs(fract(ph) - 0.5) * 2.0 / 0.9 * 0.5);
	float k = exp(-max(d, 0.0) / 9.0) * strength;
	// and a bright line right at the sphere, where the water's pulled up round it
	float lip = 1.0 - smoothstep(px * 0.8, px * 2.5 + 0.03, abs(d));
	ALBEDO = vec3(0.85, 1.0, 0.93) * (ring * k + lip * strength * 1.5);
}
"""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--only": only = Array(args[i + 1].split(",")); i += 1
			"--dry": dry = true
			"--clock": clock = int(args[i + 1]); i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _grab(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var w := roundi(img.get_width() * View.WORLD_W)
	img.get_region(Rect2i(0, 0, w, img.get_height())).save_png(path)
	print("shot ", path)


func _want(name: String) -> bool:
	return only.is_empty() or name in only


func _build() -> void:
	var v: View = main.view
	var world := v.eye.find_world_3d()
	sphere = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 48
	sm.rings = 24
	sphere.mesh = sm
	mat = ShaderMaterial.new()
	mat.shader = load("res://look/listener.gdshader")
	sphere.material_override = mat
	sphere.layers = 1 << (SPHERE_LAYER - 1)
	sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere.extra_cull_margin = 4.0
	main.pub.add_child(sphere)
	# the world round it, from its centre
	for fc in FACES:
		var vp := SubViewport.new()
		vp.size = Vector2i(CUBE_PX, CUBE_PX)
		vp.world_3d = world
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.positional_shadow_atlas_size = 1024
		root.add_child(vp)
		var c := Camera3D.new()
		c.fov = 90.0
		c.near = 0.05
		c.far = 900.0
		c.environment = v.env
		c.cull_mask = 0xFFFFF
		c.set_cull_mask_value(SPHERE_LAYER, false)
		c.set_cull_mask_value(MASK_LAYER, false)
		vp.add_child(c)
		cubes.append([vp, c, fc])
		mat.set_shader_parameter(fc[0], vp.get_texture())
	# the other place: the Sov's room from its front corner
	inside = SubViewport.new()
	inside.size = Vector2i(720, 720)
	inside.world_3d = world
	inside.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	inside.positional_shadow_atlas_size = 2048
	inside.msaa_3d = Viewport.MSAA_4X
	root.add_child(inside)
	inside_cam = Camera3D.new()
	inside_cam.fov = 92.0
	inside_cam.near = 0.05
	inside_cam.far = 60.0
	inside_cam.environment = v.env
	inside_cam.cull_mask = 0xFFFFF
	inside_cam.set_cull_mask_value(SPHERE_LAYER, false)
	inside_cam.set_cull_mask_value(GHOST_LAYER, false)
	inside_cam.set_cull_mask_value(MASK_LAYER, false)
	inside.add_child(inside_cam)
	inside_cam.look_at_from_position(INSIDE_AT[0], INSIDE_AT[1], Vector3.UP)
	mat.set_shader_parameter("inside_tex", inside.get_texture())
	mat.set_shader_parameter("inside_fov", 96.0)
	# the man on the seawall where he's sitting: only the reflection sees him
	ghost = main.pub.model("res://models/people/endbar_wharf.glb", Vector3.ZERO, main.pub)
	for mi in ghost.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = 1 << (GHOST_LAYER - 1)
	ghost.position = Vector3(8.0, -0.35, 35.65 - 0.345)
	ghost.rotation.y = PI
	v.cam.set_cull_mask_value(GHOST_LAYER, false)
	v.mcam.set_cull_mask_value(GHOST_LAYER, false)
	# the rings in the water
	ripples = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(60, 60)
	q.orientation = PlaneMesh.FACE_Y
	ripples.mesh = q
	ripple_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = RIPPLES
	ripple_mat.shader = sh
	ripples.material_override = ripple_mat
	ripples.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ripples.visible = false
	main.pub.add_child(ripples)


func _put(place: String, y := INF) -> void:
	var p: Dictionary = PLACES[place]
	var c: Vector3 = p.c
	if y != INF:
		c.y = y
	var r: float = p.r
	sphere.position = c
	sphere.scale = Vector3.ONE * r * 1.06
	mat.set_shader_parameter("radius", r)
	for cb in cubes:
		var cam: Camera3D = cb[1]
		var fc: Array = cb[2]
		cam.global_transform = Transform3D(Basis.looking_at(fc[1], fc[2]), c)
	var v: View = main.view
	var a := Posts.aim(v.eye_pos, p.aim)
	v.yaw = a.x
	v.want_yaw = a.x
	v.pitch = a.y
	v.want_pitch = a.y
	v.zoom = p.zoom
	v.want_zoom = p.zoom
	v.cam.fov = 58.0 * p.zoom
	# the well inside goes down and a little aside from where he's looking at it, so he sees down it
	# at a slant
	mat.set_shader_parameter("deep_dir", ((c - v.eye_pos).normalized() + Vector3(0.12, -0.3, 0.0)).normalized())
	mat.set_shader_parameter("deep", 5.0)
	# where it meets the water
	var below := WATER_Y - c.y
	ripples.position = Vector3(c.x, WATER_Y + 0.01, c.z)
	ripple_mat.set_shader_parameter("r0", sqrt(maxf(r * r - below * below, 0.0)))


func _look(name: String) -> void:
	var l: Dictionary = LOOKS[name]
	mat.set_shader_parameter("look", l.look)
	mat.set_shader_parameter("cut", l.cut)
	mat.set_shader_parameter("hear", l.get("hear", 0.0))
	mat.set_shader_parameter("twice", l.get("twice", false))
	var reflects: bool = l.look != 0
	mat.set_shader_parameter("has_cube", reflects)
	for cb in cubes:
		(cb[0] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS if reflects else SubViewport.UPDATE_DISABLED
	var room: bool = l.look == 2 or l.look == 6
	inside.render_target_update_mode = SubViewport.UPDATE_ALWAYS if room else SubViewport.UPDATE_DISABLED


# what it hears, s seconds in: nothing, then the jukebox coming up, held, and gone
func _swell(s: float) -> float:
	return smoothstep(1.0, 3.5, s) * (1.0 - smoothstep(5.5, 7.8, s))


func _run() -> void:
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	await _frames(5)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(20)
	main.spots.process_mode = Node.PROCESS_MODE_DISABLED
	main.spots.clear()
	main.game.set_var("clock", clock)
	main.view.clock = clock
	main.view.frame = ""
	main.view.jump_to("seawall")
	main.stage.sync(main.game, true)
	await _frames(10)
	if dry and main.pub.town != null and main.pub.town._rainfall != null:
		main.pub.town._rainfall.emitting = false
		main.pub.town._rainfall.visible = false
	_build()
	await _frames(5)
	if _want("room"):
		inside.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await _frames(6)
		await RenderingServer.frame_post_draw
		inside.get_texture().get_image().save_png(out.path_join("room.png"))
	for look in ORDER:
		for place in PLACES:
			var name := "%s_%s" % [look, place]
			if not _want(name):
				continue
			_look(look)
			_put(place)
			ripples.visible = false
			mat.set_shader_parameter("t", 12.0)
			mat.set_shader_parameter("phase", 12.0)
			await _frames(8)
			await _grab(out.path_join(name + ".png"))
	for name in LOOPS:
		if not _want(name):
			continue
		var lp: Dictionary = LOOPS[name]
		_look(lp.look)
		_put(lp.place)
		var dir := out.path_join(name)
		DirAccess.make_dir_recursive_absolute(dir)
		var phase := 12.0
		var p: Dictionary = PLACES[lp.place]
		var r: float = p.r
		var top: float = (p.c as Vector3).y
		for f in int(lp.n):
			var s: float = f * float(lp.dt)
			var hear := 0.0
			if lp.get("hear", "") == "swell":
				hear = _swell(s)
			phase += float(lp.dt) * (1.0 + 4.0 * hear)
			mat.set_shader_parameter("t", 12.0 + s)
			mat.set_shader_parameter("hear", hear)
			mat.set_shader_parameter("phase", phase)
			if lp.get("rise", false):
				# up out of the water, slowing as it comes, the last of it hanging; the rings
				# start as it breaks the surface and die away
				var k := clampf(s / 7.5, 0.0, 1.0)
				var e := 1.0 - pow(1.0 - k, 3.0)
				var y := lerpf(WATER_Y - r - 0.2, top, e)
				_put(lp.place, y)
				ripples.visible = true
				ripple_mat.set_shader_parameter("t", s)
				ripple_mat.set_shader_parameter("strength", clampf((y + r - WATER_Y) * 2.0, 0.0, 1.0) * (1.0 - smoothstep(6.0, 9.0, s) * 0.6))
			await _frames(2)
			await _grab(dir.path_join("f_%03d.png" % f))
	quit()
