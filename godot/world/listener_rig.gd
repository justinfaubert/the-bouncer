# The Listener in the world: the sphere that rises out of the strait (look/listener.gdshader), with
# what it needs round it to look right. The six views from its centre for its glass and its mirror,
# the Sov's own room for the world at its heart, and the rings it makes in the water. The look tests
# (tests/shots_listener.gd) built the same thing by hand; this is it as a piece the game can use.
# The cold open (game/intro.gd) uses it first: the dream, the sphere coming up off the seawall.
#
# It costs seven extra views of the world while it's on, so it's only built when something shows it
# and freed after (done()).
class_name ListenerRig
extends Node3D

const SPHERE_LAYER := 18
const MASK_LAYER := 20
const CUBE_PX := 320
const WATER_Y := -0.39
const FACES := [
	["cube_px", Vector3(1, 0, 0), Vector3(0, 1, 0)], ["cube_nx", Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	["cube_py", Vector3(0, 1, 0), Vector3(0, 0, -1)], ["cube_ny", Vector3(0, -1, 0), Vector3(0, 0, 1)],
	["cube_pz", Vector3(0, 0, 1), Vector3(0, 1, 0)], ["cube_nz", Vector3(0, 0, -1), Vector3(0, 1, 0)],
]
# the Sov's room from its front corner: what it holds at its heart
const INSIDE_AT := [Vector3(15.3, 2.7, 9.5), Vector3(3.0, 0.9, 2.6)]

# the rings it makes in the water where it breaks the surface; the eye's only, like a lamp's pool
const RIPPLES := """shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, fog_disabled;
uniform float t = 0.0;
uniform float r0 = 1.0;
uniform float strength = 0.0;
uniform float extent = 30.0;
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
	float ph = d * 0.9 - t * 2.4;
	float ring = 1.0 - smoothstep(px * 0.4, px * 1.2 + 0.008, abs(fract(ph) - 0.5) * 2.0 / 0.9 * 0.5);
	float k = exp(-max(d, 0.0) / 4.5) * strength * 0.7;
	float lip = 1.0 - smoothstep(px * 0.8, px * 2.5 + 0.03, abs(d));
	ALBEDO = vec3(0.85, 1.0, 0.93) * (ring * k + lip * strength * 1.5);
}
"""

var sphere: MeshInstance3D
var mat: ShaderMaterial
var cubes: Array = []
var inside: SubViewport
var inside_cam: Camera3D
var ripples: MeshInstance3D
var ripple_mat: ShaderMaterial
var centre := Vector3.ZERO
var radius := 4.2
var t := 0.0          # its clock
var phase := 12.0     # how far its tiles have flipped
var pack := 0.37      # how far its packing has gone
var hear := 0.0       # what it's hearing now, 0..1


func build(world: World3D, env: Environment, eye_cam: Camera3D, mask_cam: Camera3D) -> void:
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
	add_child(sphere)
	for fc in FACES:
		var vp := SubViewport.new()
		vp.size = Vector2i(CUBE_PX, CUBE_PX)
		vp.world_3d = world
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.positional_shadow_atlas_size = 1024
		add_child(vp)
		var c := Camera3D.new()
		c.fov = 90.0
		c.near = 0.05
		c.far = 900.0
		c.environment = env
		c.cull_mask = 0xFFFFF
		c.set_cull_mask_value(SPHERE_LAYER, false)
		c.set_cull_mask_value(MASK_LAYER, false)
		vp.add_child(c)
		cubes.append([vp, c, fc])
		mat.set_shader_parameter(fc[0], vp.get_texture())
	inside = SubViewport.new()
	inside.size = Vector2i(640, 640)
	inside.world_3d = world
	inside.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	inside.positional_shadow_atlas_size = 2048
	add_child(inside)
	inside_cam = Camera3D.new()
	inside_cam.fov = 92.0
	inside_cam.near = 0.05
	inside_cam.far = 60.0
	inside_cam.environment = env
	inside_cam.cull_mask = 0xFFFFF
	inside_cam.set_cull_mask_value(SPHERE_LAYER, false)
	inside_cam.set_cull_mask_value(MASK_LAYER, false)
	inside.add_child(inside_cam)
	mat.set_shader_parameter("inside_tex", inside.get_texture())
	mat.set_shader_parameter("inside_fov", 96.0)
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
	add_child(ripples)
	# the look the second pass settled on: obsidian, no line round it, the room small at its heart
	mat.set_shader_parameter("look", 7)
	mat.set_shader_parameter("cut", 4)
	mat.set_shader_parameter("twice", true)
	mat.set_shader_parameter("lines", 0.0)
	mat.set_shader_parameter("grown", 0.14)
	mat.set_shader_parameter("polish", 0.0)
	mat.set_shader_parameter("has_cube", true)
	_eye = eye_cam
	_mask = mask_cam


var _eye: Camera3D
var _mask: Camera3D


# Where it is and how big. y is its centre: below WATER_Y - r it's under the water, out of sight.
func put(c: Vector3, r: float) -> void:
	centre = c
	radius = r
	sphere.position = c
	sphere.scale = Vector3.ONE * r * 1.06
	mat.set_shader_parameter("radius", r)
	for cb in cubes:
		var fc: Array = cb[2]
		(cb[1] as Camera3D).global_transform = Transform3D(Basis.looking_at(fc[1], fc[2]), c)
	if _eye != null:
		mat.set_shader_parameter("deep_dir", ((c - _eye.global_position).normalized() + Vector3(0.12, -0.3, 0.0)).normalized())
	mat.set_shader_parameter("deep", 5.0)
	var below := WATER_Y - c.y
	ripples.position = Vector3(c.x, WATER_Y + 0.01, c.z)
	ripple_mat.set_shader_parameter("r0", sqrt(maxf(r * r - below * below, 0.0)))
	inside_cam.look_at_from_position(INSIDE_AT[0], INSIDE_AT[1], Vector3.UP)


# The room at its heart: 0 a point of light, 1 the whole ball.
func grow(g: float) -> void:
	mat.set_shader_parameter("grown", g)


# Its clock on by dt: the tiles flip faster and the packing runs in quicker while it hears.
func step(dt: float) -> void:
	t += dt
	phase += dt * (1.0 + 4.0 * hear)
	pack += dt * (0.05 + 0.4 * hear)
	mat.set_shader_parameter("t", 12.0 + t)
	mat.set_shader_parameter("hear", hear)
	mat.set_shader_parameter("phase", phase)
	mat.set_shader_parameter("pack", pack)


# The rings in the water, s seconds after it broke the surface, as strong as k.
func rings(s: float, k: float) -> void:
	ripples.visible = k > 0.001
	ripple_mat.set_shader_parameter("t", s)
	ripple_mat.set_shader_parameter("strength", k)


func done() -> void:
	queue_free()
