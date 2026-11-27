# The girls on the beer posters: Quaternius's CC0 base woman (Universal Base Characters, kept out
# of the repo: Hutch's copy is in the project files), posed, dressed in the brand's colours, lit like
# a 1990s studio shoot, and rendered against nothing, for godot/tools/dressing.py to print the poster
# round. Her skin with the bikini recoloured comes from dressing.py too (girl_skin_<pose>.png).
#
#   xvfb-run -a -s "-screen 0 1280x1024x24" env VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json \
#     godot --path tools/poster_girls -s render.gd -- <kit folder> <work folder> <game folder> [pose ...]
#
# Claude's, all of it.
extends SceneTree

const W := 900
const H := 1350
const X := Vector3(1, 0, 0)
const Y := Vector3(0, 1, 0)
const Z := Vector3(0, 0, 1)

var kit := ""
var work := ""
var game := ""

# Each pose: the moves (see _pose), the camera [from, at] and its fov, the hair and its colour, her
# eyes' colour, and props: [model or "can"/"bottle", where, turn in degrees, scale].
var POSES := {
	"cx": {"cam": [Vector3(-0.66, 1.42, 0.8), Vector3(-0.66, 1.42, 0)], "fov": 30.0, "moves": [["curl", "r", 60.0, X], ["curl", "l", 60.0, X]], "props": [["can", "hand_r", Vector3(0, 0.08, 0), Vector3(0, 0, 0), 1.0]]},
	"cz": {"cam": [Vector3(-0.66, 1.42, 0.8), Vector3(-0.66, 1.42, 0)], "fov": 30.0, "moves": [["curl", "r", 60.0, Z]], "props": [["can", "hand_r", Vector3(0.08, 0, 0), Vector3(0, 0, 0), 1.0]]},
	"cy": {"cam": [Vector3(-0.66, 1.42, 0.8), Vector3(-0.66, 1.42, 0)], "fov": 30.0, "moves": [["curl", "r", 60.0, Y]], "props": [["can", "hand_r", Vector3(0, 0, 0.08), Vector3(0, 0, 0), 1.0]]},
	# BOORS LIGHT: on her feet, her weight on her left leg, the hip out, one hand behind her head
	# and the can up by her shoulder in the other, chin down, looking at you
	"boors": {"hair": "Hair_Long", "hair_c": Color("e2c27a"), "cam": [Vector3(0.25, 1.05, 3.5), Vector3(0.0, 0.98, 0)], "fov": 33.0,
		"moves": [
			["turn", "pelvis", Y, 28], ["turn", "pelvis", Z, 8],
			["turn", "spine_01", Z, -6], ["turn", "spine_02", Z, -7], ["turn", "spine_02", Y, -8], ["turn", "spine_03", Y, -8], ["turn", "spine_03", X, -6],
			["turn", "neck_01", Z, -4], ["turn", "Head", Z, 9], ["turn", "Head", Y, -16], ["turn", "Head", X, 6],
			["aim", "upperarm_l", "lowerarm_l", Vector3(0.42, 0.88, -0.2)], ["aim", "lowerarm_l", "hand_l", Vector3(-0.8, 0.35, -0.4)],
			["aim", "upperarm_r", "lowerarm_r", Vector3(-0.28, -0.88, 0.3)], ["aim", "lowerarm_r", "hand_r", Vector3(0.18, 0.78, 0.6)],
			["aim", "thigh_l", "calf_l", Vector3(-0.07, -1, 0.0)], ["aim", "calf_l", "foot_l", Vector3(0.0, -1, -0.02)],
			["aim", "thigh_r", "calf_r", Vector3(0.14, -1, 0.26)], ["aim", "calf_r", "foot_r", Vector3(0.0, -1, -0.16)],
			["curl", "r", 68.0], ["curl", "l", 30.0],
		],
		"props": [["can", "grip_r", Vector3(0, 0.01, 0), Vector3(0, 0, 0), 1.0]]},
	# MILDCAT: on a bar stool, her legs crossed toward you, the can up by her face, her other hand
	# on her knee, head on one side
	"mildcat": {"hair": "Hair_Long", "hair_c": Color("4a2c1c"), "drop": 0.21, "cam": [Vector3(0.55, 1.0, 3.3), Vector3(0.05, 0.8, 0)], "fov": 33.0,
		"moves": [
			["turn", "pelvis", Y, -28],
			["aim", "thigh_l", "calf_l", Vector3(0.06, -0.12, 1)], ["aim", "calf_l", "foot_l", Vector3(0.0, -1, 0.12)],
			["aim", "thigh_r", "calf_r", Vector3(0.24, 0.12, 1)], ["aim", "calf_r", "foot_r", Vector3(0.18, -1, 0.3)],
			["turn", "foot_r", X, 30], ["turn", "foot_l", X, 20],
			["turn", "spine_01", X, -6], ["turn", "spine_02", Y, 14], ["turn", "spine_03", Y, 12], ["turn", "spine_03", Z, 5],
			["turn", "Head", Z, -12], ["turn", "Head", Y, 8], ["turn", "Head", X, 8],
			["aim", "upperarm_r", "lowerarm_r", Vector3(0.05, -0.85, 0.5)], ["aim", "lowerarm_r", "hand_r", Vector3(0.35, -0.35, 0.85)],
			["aim", "upperarm_l", "lowerarm_l", Vector3(0.35, -0.85, 0.25)], ["aim", "lowerarm_l", "hand_l", Vector3(-0.2, 0.85, 0.45)],
			["curl", "l", 68.0], ["curl", "r", 20.0],
		],
		"props": [["can", "grip_l", Vector3(0, 0.01, 0), Vector3(0, 0, 0), 1.0], ["models/stool_bar.glb", "", Vector3(0.0, 0.0, 0.07), Vector3(0, 30, 0), 1.0]]},
	# UNLUCKY LAGER, the calendar's Miss March: leaned back on the fender of a pickup, her ankles
	# crossed, an arm along the hood, a bottle at her hip
	"unlucky": {"hair": "Hair_Long", "hair_c": Color("8a4a26"), "paint": Color("3f7a62"), "cam": [Vector3(0.9, 1.2, 4.6), Vector3(0.0, 0.95, -0.4)], "fov": 38.0,
		"moves": [
			["turn", "pelvis", Y, -32], ["turn", "pelvis", Z, -6],
			["turn", "spine_01", X, -6], ["turn", "spine_02", X, -6], ["turn", "spine_02", Z, 5], ["turn", "spine_03", Y, 12],
			["turn", "Head", Z, 10], ["turn", "Head", Y, 18], ["turn", "Head", X, 4],
			["aim", "thigh_l", "calf_l", Vector3(-0.1, -1, 0.18)], ["aim", "calf_l", "foot_l", Vector3(-0.2, -1, 0.0)],
			["aim", "thigh_r", "calf_r", Vector3(0.05, -1, 0.04)], ["aim", "calf_r", "foot_r", Vector3(0.1, -1, -0.02)],
			["aim", "upperarm_l", "lowerarm_l", Vector3(0.45, -0.8, -0.3)], ["aim", "lowerarm_l", "hand_l", Vector3(-0.55, -0.45, 0.35)],
			["aim", "upperarm_r", "lowerarm_r", Vector3(-0.25, -1, 0.05)], ["aim", "lowerarm_r", "hand_r", Vector3(0.25, -0.55, 0.7)],
			["curl", "r", 66.0], ["curl", "l", 35.0],
		],
		"props": [["bottle", "grip_r", Vector3(0, -0.02, 0), Vector3(0, 0, 0), 1.0], ["models/truck.glb", "", Vector3(-0.6, 0.0, -1.7), Vector3(0, 75, 0), 1.0]]},
	# THE VELVET (not a brand): on the stool from behind, her back to you and her face turned
	# over her shoulder, one hand up in her hair; painted on black velvet after (dressing2.py)
	"velvet": {"hair": "Hair_Long", "hair_c": Color("2a1810"), "drop": 0.21, "cam": [Vector3(-0.9, 1.05, -3.1), Vector3(0.0, 0.92, 0)], "fov": 30.0,
		"moves": [
			["turn", "pelvis", Y, 20],
			["aim", "thigh_l", "calf_l", Vector3(0.1, -0.1, 1)], ["aim", "calf_l", "foot_l", Vector3(0.0, -1, 0.15)],
			["aim", "thigh_r", "calf_r", Vector3(0.3, 0.1, 1)], ["aim", "calf_r", "foot_r", Vector3(0.2, -1, 0.3)],
			["turn", "spine_01", X, 8], ["turn", "spine_02", X, 6], ["turn", "spine_02", Y, 22], ["turn", "spine_03", Y, 20],
			["turn", "neck_01", Y, 25], ["turn", "Head", Y, 45], ["turn", "Head", Z, -8], ["turn", "Head", X, 8],
			["aim", "upperarm_l", "lowerarm_l", Vector3(0.7, 0.6, 0.15)], ["aim", "lowerarm_l", "hand_l", Vector3(-0.55, 0.55, -0.45)],
			["aim", "upperarm_r", "lowerarm_r", Vector3(-0.25, -0.9, -0.2)], ["aim", "lowerarm_r", "hand_r", Vector3(-0.1, -0.6, 0.6)],
			["curl", "l", 25.0], ["curl", "r", 30.0],
		],
		"props": [["models/stool_bar.glb", "", Vector3(0.0, 0.0, 0.07), Vector3(0, 30, 0), 1.0]]},
	# THE SLUSH GIRL, for the cardboard standee at the gas station's door: on her feet, offering you
	# the cup at arm's length, her other hand on her hip, head on one side
	"slush": {"hair": "Hair_Long", "hair_c": Color("b86a3a"), "cam": [Vector3(0.1, 1.0, 3.6), Vector3(0.0, 0.95, 0)], "fov": 33.0,
		"moves": [
			["turn", "pelvis", Y, -14], ["turn", "pelvis", Z, -7],
			["turn", "spine_01", Z, 5], ["turn", "spine_02", Z, 6], ["turn", "spine_03", Y, 10],
			["turn", "Head", Z, -11], ["turn", "Head", Y, 6], ["turn", "Head", X, 5],
			["aim", "upperarm_r", "lowerarm_r", Vector3(-0.35, -0.45, 0.82)], ["aim", "lowerarm_r", "hand_r", Vector3(-0.15, 0.2, 1.0)],
			["aim", "upperarm_l", "lowerarm_l", Vector3(0.62, -0.72, -0.1)], ["aim", "lowerarm_l", "hand_l", Vector3(-0.75, 0.15, 0.3)],
			["aim", "thigh_r", "calf_r", Vector3(0.02, -1, 0.0)], ["aim", "calf_r", "foot_r", Vector3(0.0, -1, -0.02)],
			["aim", "thigh_l", "calf_l", Vector3(-0.12, -1, 0.22)], ["aim", "calf_l", "foot_l", Vector3(0.0, -1, -0.14)],
			["curl", "r", 62.0], ["curl", "l", 15.0],
		],
		"props": [["slush", "grip_r", Vector3(0, 0.03, 0), Vector3(0, 0, 0), 1.0]]},
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	kit = args[0]
	work = args[1]
	game = args[2]
	var which: Array = args.slice(3) if args.size() > 3 else POSES.keys()
	await process_frame
	for p in which:
		await _render(p, POSES[p])
	quit()


func _load(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		push_error("can't load " + path)
		return Node3D.new()
	return doc.generate_scene(st) as Node3D


# The pose, a move at a time, each on the pose as the moves before left it: ["aim", bone, child,
# direction in the world] points a bone at a direction (her front is +z, her left +x); ["turn",
# bone, axis in the world, degrees] turns a bone and everything on it; ["bend", bone, axis of the
# bone's own, degrees]; ["curl", "l"|"r", degrees] closes that hand's fingers.
func _pose(sk: Skeleton3D, moves: Array) -> void:
	for mv in moves:
		if mv[0] == "curl":
			for f in ["index", "middle", "ring", "pinky"]:
				for k in [1, 2, 3]:
					_move(sk, ["bend", "%s_0%d_%s" % [f, k, mv[1]], mv[3] if mv.size() > 3 else X, float(mv[2])])
			_move(sk, ["bend", "thumb_02_" + mv[1], mv[3] if mv.size() > 3 else X, float(mv[2]) * 0.4])
			continue
		_move(sk, mv)


func _move(sk: Skeleton3D, mv: Array) -> void:
	var i := sk.find_bone(mv[1])
	if i < 0:
		push_warning("no bone " + str(mv[1]))
		return
	var gp := sk.get_bone_global_pose(i)
	var nb: Basis
	if mv[0] == "aim":
		var c := sk.find_bone(mv[2])
		var cur := (sk.get_bone_global_pose(c).origin - gp.origin).normalized()
		var to: Vector3 = (mv[3] as Vector3).normalized()
		nb = Basis(Quaternion(cur, to)) * gp.basis
	elif mv[0] == "bend":
		nb = gp.basis * Basis((mv[2] as Vector3).normalized(), deg_to_rad(float(mv[3])))
	else:
		nb = Basis((mv[2] as Vector3).normalized(), deg_to_rad(float(mv[3]))) * gp.basis
	var par := sk.get_bone_parent(i)
	var pg := sk.get_bone_global_pose(par).basis if par >= 0 else Basis.IDENTITY
	sk.set_bone_pose_rotation(i, (pg.inverse() * nb).get_rotation_quaternion())


func _tex(path: String) -> ImageTexture:
	var img := Image.load_from_file(path)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _render(name: String, p: Dictionary) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.7)
	e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var body := _load(kit + "/Base Characters/Godot - UE/Superhero_Female_FullBody.gltf")
	world.add_child(body)
	var sk: Skeleton3D = body.find_children("*", "Skeleton3D", true, false)[0]
	body.position.y = -float(p.get("drop", 0.0))
	# her skin, with the bikini in the brand's colours (dressing.py)
	var skin_png := work + "/girl_skin_" + name + ".png"
	if FileAccess.file_exists(skin_png):
		for mi in body.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			for s in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(s) as StandardMaterial3D
				if mat and mat.resource_name.begins_with("MI_Superhero"):
					var m2 := mat.duplicate() as StandardMaterial3D
					m2.albedo_texture = _tex(skin_png)
					m.set_surface_override_material(s, m2)
	if p.has("hair"):
		var hair := _load(kit + "/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/" + p.hair + ".gltf")
		for mi in hair.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			m.get_parent().remove_child(m)
			m.owner = null
			sk.add_child(m)
			m.skeleton = NodePath("..")
			for s in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(s) as StandardMaterial3D
				if mat:
					var m2 := mat.duplicate() as StandardMaterial3D
					m2.albedo_color = p.get("hair_c", Color.WHITE)
					m.set_surface_override_material(s, m2)
		hair.free()
	# the eyebrows take the hair's colour, darker
	for mi in body.find_children("Eyebrows*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var mat := m.mesh.surface_get_material(0) as StandardMaterial3D
		if mat:
			var m2 := mat.duplicate() as StandardMaterial3D
			m2.albedo_color = (p.get("hair_c", Color.WHITE) as Color).darkened(0.45)
			m.set_surface_override_material(0, m2)
	await process_frame
	_pose(sk, p.get("moves", []))
	# the props, in a hand (by its bone) or in the world
	_paint = p.get("paint", Color.BLACK)
	for pr in p.get("props", []):
		var n := _prop(str(pr[0]))
		world.add_child(n)
		var at: Transform3D
		var bi := sk.find_bone(str(pr[1]))
		var local := Transform3D(Basis.from_euler((pr[3] as Vector3) * (PI / 180.0)), pr[2])
		if str(pr[1]).begins_with("grip_"):
			# in the fist: the can's axis along the knuckles, its middle in the loop of the fingers
			var sd := str(pr[1]).substr(5)
			var g := func(b: String) -> Vector3: return (sk.global_transform * sk.get_bone_global_pose(sk.find_bone(b + "_" + sd))).origin
			var ax: Vector3 = (g.call("pinky_01") - g.call("index_01")).normalized()
			var mid: Vector3 = (g.call("middle_01") + g.call("middle_04_leaf")) * 0.5
			var up := ax if ax.y >= 0.0 else -ax
			var side := up.cross(Vector3(0, 0, 1)).normalized()
			n.global_transform = Transform3D(Basis(side, up, side.cross(up)), mid) * local
		elif bi >= 0:
			# in the hand's own frame, from the bone's head
			at = sk.global_transform * sk.get_bone_global_pose(bi)
			at.basis = at.basis.orthonormalized()
			n.global_transform = at * local
		else:
			n.global_transform = local
		n.scale = Vector3.ONE * float(pr[4])
	var cam := Camera3D.new()
	cam.fov = p.get("fov", 34.0)
	world.add_child(cam)
	cam.look_at_from_position(p.cam[0], p.cam[1], Vector3.UP)
	# a studio's: the key high on her right, a fill low on her left, a hard rim behind
	var key := DirectionalLight3D.new()
	key.light_energy = 1.7
	key.light_color = Color(1.0, 0.94, 0.86)
	key.shadow_enabled = true
	world.add_child(key)
	key.look_at_from_position(Vector3(2, 3, 3), Vector3.ZERO, Vector3.UP)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.5
	fill.light_color = Color(0.8, 0.88, 1.0)
	world.add_child(fill)
	fill.look_at_from_position(Vector3(-3, 0.5, 2), Vector3.ZERO, Vector3.UP)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 1.4
	world.add_child(rim)
	rim.look_at_from_position(Vector3(-1.5, 2, -3), Vector3.ZERO, Vector3.UP)
	for k in 8:
		await process_frame
	var img := vp.get_texture().get_image()
	img.save_png(work + "/girl_" + name + ".png")
	print("rendered ", name)
	vp.queue_free()
	await process_frame


func _prop(what: String) -> Node3D:
	var n := Node3D.new()
	if what == "can":
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.031
		c.bottom_radius = 0.033
		c.height = 0.122
		mi.mesh = c
		var m := StandardMaterial3D.new()
		m.metallic = 0.85
		m.roughness = 0.3
		var label := work + "/can_label.png"
		if FileAccess.file_exists(label):
			m.albedo_texture = _tex(label)
		else:
			m.albedo_color = Color("b8c4cc")
		mi.material_override = m
		n.add_child(mi)
	elif what == "slush":
		# a slush cup: red ice in a clear cup going up wide, a dome lid, a straw
		var red := StandardMaterial3D.new()
		red.albedo_color = Color("d0203a")
		red.roughness = 0.35
		var cup := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.048
		c.bottom_radius = 0.034
		c.height = 0.16
		cup.mesh = c
		cup.material_override = red
		n.add_child(cup)
		var dome := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.05
		sp.height = 0.05
		sp.is_hemisphere = true
		dome.mesh = sp
		dome.position.y = 0.08
		var clear := StandardMaterial3D.new()
		clear.albedo_color = Color(0.95, 0.95, 1.0, 0.55)
		clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		clear.roughness = 0.05
		dome.material_override = clear
		n.add_child(dome)
		var straw := MeshInstance3D.new()
		var st := CylinderMesh.new()
		st.top_radius = 0.005
		st.bottom_radius = 0.005
		st.height = 0.2
		straw.mesh = st
		straw.position = Vector3(0.01, 0.15, 0)
		straw.rotation.z = 0.15
		var yel := StandardMaterial3D.new()
		yel.albedo_color = Color("f0d020")
		straw.material_override = yel
		n.add_child(straw)
	elif what == "bottle":
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("3a2410")
		m.roughness = 0.15
		m.metallic = 0.1
		var b := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.03
		c.bottom_radius = 0.031
		c.height = 0.15
		b.mesh = c
		b.material_override = m
		n.add_child(b)
		var nk := MeshInstance3D.new()
		var c2 := CylinderMesh.new()
		c2.top_radius = 0.012
		c2.bottom_radius = 0.03
		c2.height = 0.09
		nk.mesh = c2
		nk.position.y = 0.12
		nk.material_override = m
		n.add_child(nk)
	else:
		var m := _load(game + "/" + what)
		n.add_child(m)
		if _paint != Color.BLACK:
			for mi in m.find_children("*", "MeshInstance3D", true, false):
				var me := mi as MeshInstance3D
				for s in me.mesh.get_surface_count():
					var mat := me.mesh.surface_get_material(s) as StandardMaterial3D
					if mat and mat.resource_name == "paint":
						var m2 := mat.duplicate() as StandardMaterial3D
						m2.albedo_color = _paint
						me.set_surface_override_material(s, m2)
	return n


var _paint := Color.BLACK
