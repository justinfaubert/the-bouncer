extends "res://tests/shots_styles.gd"
# The people as masks (PROPOSED, Hutch's pick of 18 November 2026; tools/masks.py builds them,
# tools/faces.py draws their faces, game/face.gd lays a face together): the bartender, the team
# jacket, the big man and Amanda, each on the masks proportions with their own spin, printed, on
# twos, feeling things.
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_masks.gd -- --out /tmp/masks [--only <what>,<who>]
# what: faces (each one close, every expression), far (the four across the room, every
# expression at once: does it read from where he stands?), talk (the four talking, their feelings
# changing), close (each one close, talking), walk (the four walking), turn (each one standing,
# turned round: the whole figure from five sides), swing (each one walking, seen from behind and to
# the side: the hair and clothes moving), heights (prints how tall each one stands), quick (a look
# at a change: the four at mid shot, then her face and the bartender's close), room (in the pub
# itself, on a new night: the bartender and Amanda at the bar, the big man at the pool table with
# Amanda crossing in front of it, the team jacket at table 28 with Amanda come to the table; each
# a still, then talking, then he turns his head to her. Add still to skip the talking, or bar,
# floor or t28 for one of them). who: one or more of them. A talk is 24 pictures to the second:
# the room holds each pose for two of them, Amanda moves on every one (ONES).

const MASKS := "res://models/masks/"
const WHO := ["bartender", "team_jacket", "bigman", "amanda"]

# the masks template (shots_styles.gd's "masks") and what each one changes in it
const SPIN := {
	# slight and wiry, fifties: a long face on a longer neck, narrow, thin arms, hands that work
	"bartender": {"neck_01": {"len": 1.15}, "Head": {"len": 0.62, "s": 1.7}, "spine_03": {"len": 0.9, "s": 0.95},
		"upperarm_l": {"s": 0.85}, "upperarm_r": {"s": 0.85}, "lowerarm_l": {"len": 1.0}, "lowerarm_r": {"len": 1.0},
		"hand_l": {"len": 1.0, "s": 1.3}, "hand_r": {"len": 1.0, "s": 1.3}, "calf_l": {"len": 0.8}, "calf_r": {"len": 0.8}},
	# the loudest at table 28: the biggest head of them, no neck, short legs under the belly
	"team_jacket": {"neck_01": {"len": 0.6}, "Head": {"len": 0.42, "s": 2.05}, "spine_01": {"len": 0.8},
		"spine_02": {"len": 0.8}, "hand_l": {"len": 0.85, "s": 1.35}, "hand_r": {"len": 0.85, "s": 1.35},
		"calf_l": {"len": 0.72}, "calf_r": {"len": 0.72}, "foot_l": {"len": 0.66, "s": 1.5}, "foot_r": {"len": 0.66, "s": 1.5}},
	# all shoulders, and the tallest in the room: a small head for the masks, sunk in a thick neck, a
	# chest like a door, huge hands, legs of a real length under it
	"bigman": {"neck_01": {"len": 0.8, "s": 1.2}, "Head": {"len": 0.6, "s": 1.25}, "spine_01": {"len": 0.95}, "spine_02": {"len": 0.95, "s": 1.12},
		"spine_03": {"len": 0.95, "s": 1.25}, "clavicle_l": {"len": 1.12}, "clavicle_r": {"len": 1.12},
		"upperarm_l": {"len": 1.0, "s": 1.05}, "upperarm_r": {"len": 1.0, "s": 1.05}, "lowerarm_l": {"len": 1.0},
		"lowerarm_r": {"len": 1.0}, "hand_l": {"len": 1.0, "s": 1.55}, "hand_r": {"len": 1.0, "s": 1.55},
		"thigh_l": {"s": 1.3}, "thigh_r": {"s": 1.3}, "calf_l": {"len": 0.77, "s": 1.25}, "calf_r": {"len": 0.77, "s": 1.25},
		"foot_l": {"len": 0.76, "s": 1.3}, "foot_r": {"len": 0.76, "s": 1.3}},
	# the one from somewhere else: a woman's proportions among caricatures, the way Jessica Rabbit is
	# drawn among the toons. Her head nearly a real one's size on a long neck (theirs are half
	# again as big, or twice), a narrow waist, long legs set close (her walk puts one foot in
	# front of the other), small hands and feet, low heels (the pitch: tools/masks.py builds the
	# heels for 14 degrees); the braid hangs to the backs of her thighs
	"amanda": {"neck_01": {"len": 1.05}, "Head": {"len": 1.32, "s": 1.1}, "spine_01": {"len": 1.0, "s": 0.9},
		"spine_02": {"len": 0.95}, "spine_03": {"len": 1.0, "s": 1.0}, "pelvis": {"s": 1.03},
		"upperarm_l": {"s": 0.9}, "upperarm_r": {"s": 0.9}, "lowerarm_l": {"len": 1.0}, "lowerarm_r": {"len": 1.0},
		"hand_l": {"len": 1.0, "s": 0.88}, "hand_r": {"len": 1.0, "s": 0.88},
		"thigh_l": {"len": 0.72}, "thigh_r": {"len": 0.72}, "calf_l": {"len": 1.0}, "calf_r": {"len": 1.0},
		"foot_l": {"len": 1.03, "s": 0.85, "pitch": 14.0}, "foot_r": {"len": 1.03, "s": 0.85, "pitch": 14.0},
		"ball_l": {"pitch": -14.0}, "ball_r": {"pitch": -14.0}},
}
# how big each one is all over: the big man is the biggest thing in the room
const SIZE := {"bigman": 1.1}
# how each one carries themselves, over whatever the clip is doing: turns in the model's own frame
# (degrees about its left, its up and its front: x pitches forward, z rolls toward its right), the
# body before what hangs from it. The bartender leans in with her shoulders up, wound tight; the
# team jacket leans back behind his belly, chin up; the big man rounds his shoulders and pushes his
# head forward, level, like something that charges; Amanda stands straight and easy, shoulders
# back, her feet close and her arms in, her head a little to one side
const CARRY := {
	"bartender": {"spine_02": Vector3(4, 0, 0), "clavicle_l": Vector3(0, 0, 5), "clavicle_r": Vector3(0, 0, -5),
		"neck_01": Vector3(6, 0, 0), "Head": Vector3(-4, 0, 0)},
	"team_jacket": {"spine_01": Vector3(-5, 0, 0), "spine_03": Vector3(2, 0, 0), "Head": Vector3(-6, 0, 0)},
	"bigman": {"spine_03": Vector3(7, 0, 0), "clavicle_l": Vector3(0, -8, 0), "clavicle_r": Vector3(0, 8, 0),
		"upperarm_l": Vector3(0, 0, 4), "upperarm_r": Vector3(0, 0, -4), "neck_01": Vector3(10, 0, 0), "Head": Vector3(-12, 0, 0)},
	"amanda": {"thigh_l": Vector3(0, 0, -4), "thigh_r": Vector3(0, 0, 4), "spine_03": Vector3(-3, 0, 0),
		"upperarm_l": Vector3(0, 0, -8), "upperarm_r": Vector3(0, 0, 8), "Head": Vector3(2, 0, 3)},
}
# who moves on ones, every frame of the 24, while the room holds each pose for two: her
const ONES := ["amanda"]
# how open each one's hands hang, whatever the clip has them doing: 0 as the clip has them, 1 flat
# as the rig was made. The idle makes fists; hers hang open and a little curled
const OPEN := {"amanda": 0.55}
const FINGERS := ["index", "middle", "ring", "pinky", "thumb"]
# what each one goes through while they talk, a quarter of the clip each
const SCRIPT := {
	"bartender": ["neutral", "suspicious", "angry", "eyeroll"],
	"team_jacket": ["neutral", "laugh", "sad", "drunk"],
	"bigman": ["neutral", "menace", "surprised", "laugh"],
	"amanda": ["knowing", "tease", "laugh", "far"],
}
# the mouths in turn as they talk, a held pose each: 0 shut, 1 a little open, 2 wide, 3 round
const TALK := [1, 2, 1, 0, 3, 2, 1, 0, 2, 1, 3, 0]
const HAIR := ["hair_grey", "hair_white", "hair_dark", "hair_rust", "hair_black", "hair", "hair_red", "beard_grey"]
# She has a light of her own (a layer only she's on): a soft spot from just over his eyes, turned
# where he looks. Whoever he looks at, the light from his eyes is on them a little (the game's own,
# view.gd); when he looks at her, she warms and the strokes go off her skin. The anima is a
# projection: she's lit by his looking. So it's as strong at any distance (it isn't a lamp he
# carries), and she's at its edge when he looks at someone else. All of her skin is in it (her face
# alone read as a pale mask on a tan body), warm enough that she stays olive; her clothes stay out
# of it, or the red goes orange. The studio's lights are far brighter than the pub's: there it's a
# third as strong, to sit in the same proportion. HER_LIGHT in the environment tries another
const HER_LAYER := 5
const HER_LIGHT := 2.2
const HER_GLOW := Color("f4dcc0")
const HER_PARTS := ["_mask", "_nose", "_ears", "_hair", "_wisps", "_combed", "_pearl", "_body"]
# and she's engraved where they're cut: finer strokes, cleaner lines
const HER_PRINT := [3.2, 0.85]


func _spin(who: String) -> Dictionary:
	var s: Dictionary = STYLES["masks"].duplicate(true)
	var mine: Dictionary = SPIN[who]
	for b in mine:
		var d: Dictionary = s.get(b, {}).duplicate()
		d.merge(mine[b], true)
		s[b] = d
	return s


# A mask person: their clothes and skin in the print's strokes, their face drawn and alive.
# [AnimationPlayer, Skeleton3D, DrawnFace, who, their node, HairChain or null]
func _mask(who: String, pos: Vector3, yaw: float) -> Array:
	var n: Node3D = main.pub.model(MASKS + who + ".glb", pos, set_node)
	n.rotation.y = yaw
	n.scale = Vector3.ONE * float(SIZE.get(who, 1.0))
	var face := DrawnFace.open(MASKS, who)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(i)
			var key := src.resource_name if src else ""
			var c := (src as BaseMaterial3D).albedo_color if src is BaseMaterial3D else Color(0.7, 0.7, 0.7)
			var mat: ShaderMaterial
			if key.begins_with("face_"):
				mat = main.pub.mat(Color(1, 1, 1), 0.9, 0.0, 4, Vector3.UP, 4.5, 0.7)
				mat.set_shader_parameter("albedo_tex", face.tex)
				mat.set_shader_parameter("specular", 0.25)
			elif key in HAIR:
				# hardly any shine: dark hair caught by the lamp prints pale, a helmet, not hair
				mat = main.pub.mat(c, 0.95, 0.0, 4, Vector3.UP, 3.5, 0.5)
				mat.set_shader_parameter("specular", 0.0)
			elif key.begins_with("flannel"):
				# the big man's shirt: a plaid, printed in the strokes like the rest
				mat = main.pub.mat(c, 0.9, 0.0, 4, Vector3.UP, 4.5, 0.7)
				mat.set_shader_parameter("albedo_tex", _plaid())
			elif key == "gold":
				mat = main.pub.mat(c, 0.4, 0.8, 3, Vector3.UP, 5.0, 0.4)
			elif key == "pearl":
				# a pearl: no strokes, a soft shine, a pale drop at her jaw
				mat = main.pub.mat(c, 0.3, 0.0, 3, Vector3.UP, 5.0, 0.6)
				mat.set_shader_parameter("specular", 0.8)
			else:
				mat = main.pub.mat(c, 0.9, 0.0, 4, Vector3.UP, 4.5, 0.7)
			if who == "amanda" and int(mat.get_shader_parameter("cut")) == 4:
				mat.set_shader_parameter("cut_px", HER_PRINT[0] * (0.78 if key in HAIR else 1.0))
				mat.set_shader_parameter("lines", HER_PRINT[1] * (0.7 if key in HAIR else 1.0))
			m.set_surface_override_material(i, mat)
		# the light from his eyes, as in the game (pub.gd puts the people on its layer)
		m.set_layer_mask_value(Pub.PEOPLE_LAYER, true)
		if who == "amanda" and HER_PARTS.any(func(k): return k in String(m.name)):
			m.set_layer_mask_value(HER_LAYER, true)
	var ap := AnimationPlayer.new()
	n.add_child(ap)
	ap.root_node = NodePath("..")
	ap.add_animation_library(&"", _lib())
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var hair: HairChain = HairChain.new(sk) if sk.find_bone("braid_00") >= 0 else null
	if hair != null and who == "amanda":
		# a breeze nobody else is in, from her left: the braid stirs when she's standing still
		hair.wind = Vector3(-1.1, 0.0, -0.35)
		hair.thick = 1.08
	return [ap, sk, face, who, n, hair]


var _plaid_tex: ImageTexture


func _plaid() -> ImageTexture:
	if _plaid_tex == null:
		var img := Image.new()
		img.load_png_from_buffer(FileAccess.get_file_as_bytes(MASKS + "plaid.png"))
		img.generate_mipmaps()
		_plaid_tex = ImageTexture.create_from_image(img)
	return _plaid_tex


# the proportions, the feet pitched onto heels, then back down on the floor (longer or shorter legs
# would sink or float), the head squashed or stretched with what the face is doing, then the hair
# swinging after it (dt 0: hanging still)
func _pose(p: Array, dt := STEP) -> void:
	var sk: Skeleton3D = p[1]
	var spin := _spin(p[3])
	var balls := [sk.find_bone("ball_l"), sk.find_bone("ball_r")]
	var was := [sk.get_bone_global_pose(balls[0]).origin.y, sk.get_bone_global_pose(balls[1]).origin.y]
	_shape(sk, spin)
	_pitch(sk, spin)
	_carry(sk, p[3])
	# the foot that's lower in the clip, the one standing, put back where the clip had it
	var low := 0 if was[0] <= was[1] else 1
	var lift: float = was[low] - sk.get_bone_global_pose(balls[low]).origin.y
	var pv := sk.find_bone("pelvis")
	var rise := Vector3(0.0, lift, 0.0)
	if sk.get_bone_parent(pv) >= 0:
		rise = sk.get_bone_global_pose(sk.get_bone_parent(pv)).basis.inverse() * rise
	sk.set_bone_pose_position(pv, sk.get_bone_pose_position(pv) + rise)
	var hb := sk.find_bone("Head")
	var hv: Vector2 = (p[2] as DrawnFace).head()
	var up := 0
	var rest := sk.get_bone_global_rest(hb).basis
	for k in 3:
		if absf(rest[k].normalized().dot(Vector3.UP)) > absf(rest[up].normalized().dot(Vector3.UP)):
			up = k
	var sc := Vector3(hv.x, hv.x, hv.x)
	sc[up] = hv.y
	sk.set_bone_pose_scale(hb, sk.get_bone_pose_scale(hb) * sc)
	if p[5] != null:
		var hair: HairChain = p[5]
		if dt > 0.0:
			hair.step(dt)
		else:
			hair.settle()


# a bone turned about the body's own left-right axis, its end down by this many degrees: a foot
# onto a heel, the toes back flat
func _pitch(sk: Skeleton3D, spin: Dictionary) -> void:
	for bn in spin:
		var deg: float = spin[bn].get("pitch", 0.0)
		if deg == 0.0:
			continue
		var b := sk.find_bone(bn)
		var rest := sk.get_bone_global_rest(b).basis.orthonormalized()
		var axis := (rest.inverse() * Vector3.RIGHT).normalized()
		var q := Quaternion(axis, deg_to_rad(deg))
		if (rest * (q * Vector3.UP)).y > (rest * Vector3.UP).y:
			q = q.inverse()
		sk.set_bone_pose_rotation(b, sk.get_bone_pose_rotation(b) * q)


# how they carry themselves (CARRY): each bone turned in the model's frame, about where it hangs
# from, whatever the clip has it doing
func _carry(sk: Skeleton3D, who: String) -> void:
	var c: Dictionary = CARRY.get(who, {})
	for bn in c:
		var b := sk.find_bone(bn)
		if b < 0:
			continue
		var q := Quaternion.from_euler((c[bn] as Vector3) * (PI / 180.0))
		var par := sk.get_bone_parent(b)
		var pr := Quaternion(sk.get_bone_global_pose(par).basis.orthonormalized()) if par >= 0 else Quaternion.IDENTITY
		sk.set_bone_pose_rotation(b, (pr.inverse() * q * pr) * sk.get_bone_pose_rotation(b))
	var k: float = OPEN.get(who, 0.0)
	if k <= 0.0:
		return
	for b in sk.get_bone_count():
		if FINGERS.any(func(f): return sk.get_bone_name(b).begins_with(f)):
			var flat := sk.get_bone_rest(b).basis.get_rotation_quaternion()
			sk.set_bone_pose_rotation(b, sk.get_bone_pose_rotation(b).slerp(flat, k))


# where the eyes must look to meet a point: the gaze, from the head's place and facing
func _gaze_at(p: Array, target: Vector3) -> Vector2:
	var sk: Skeleton3D = p[1]
	var n: Node3D = p[4]
	var head := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
	var d := n.global_transform.basis.inverse() * (target - head)
	return Vector2(clampf(atan2(d.x, d.z) / deg_to_rad(35.0), -1.0, 1.0), clampf(atan2(d.y, Vector2(d.x, d.z).length()) / deg_to_rad(25.0), -1.0, 1.0))


# the middle of the mask: where to look at a face from
func _head_pos(p: Array) -> Vector3:
	var n: Node3D = p[4]
	for mi in n.find_children("*_mask", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		return m.global_transform * m.get_aabb().get_center() - AT
	var sk: Skeleton3D = p[1]
	return sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin - AT


func _step(people: Array, dt := STEP) -> void:
	for p in people:
		(p[1] as Skeleton3D).reset_bone_poses()
		(p[0] as AnimationPlayer).advance(dt)


# Each held pose is two frames of the 24. The room holds each pose for both; who moves on ones
# moves again on the second, half a pose on. Their faces change on twos, with everyone's. paths:
# who walks where meanwhile, {who: [from, to]}; origin: where eye is measured from (the set, or
# the room's own 0)
func _talk(people: Array, tag: String, frames: int, eye := Vector3.INF, paths := {}, origin := AT) -> void:
	var any_ones := people.any(func(p): return p[3] in ONES)
	for f in frames:
		for half in 2:
			if half == 1 and not any_ones:
				# nobody moves on the second frame: it's the first again
				DirAccess.copy_absolute(out.path_join("%s_%03d.png" % [tag, f * 2]), out.path_join("%s_%03d.png" % [tag, f * 2 + 1]))
				for p in people:
					_step([p])
				continue
			for i in people.size():
				var p: Array = people[i]
				var who: String = p[3]
				var ones: bool = who in ONES
				if half == 1 and not ones:
					continue
				if paths.has(who):
					var k := float(f * 2 + half) / float(frames * 2)
					(p[4] as Node3D).position = (paths[who][0] as Vector3).lerp(paths[who][1], k)
				var script: Array = SCRIPT[who]
				var ex: String = script[mini(f * script.size() / frames, script.size() - 1)]
				var shut := (f + i * 5) % 19 == 18
				var g := Vector2.ZERO
				if eye != Vector3.INF:
					g = _gaze_at(p, origin + eye)
				(p[2] as DrawnFace).wear(ex, TALK[(f + i * 3) % TALK.size()], shut, g)
				_pose(p, STEP / 2.0 if ones else STEP)
			await _frames(2)
			await _grab("%s_%03d" % [tag, f * 2 + half])
			for p in people:
				if p[3] in ONES:
					_step([p], STEP / 2.0)
				elif half == 1:
					_step([p])


func _lights_row() -> void:
	_light(Vector3(-1.5, 2.8, -1.6), Color("f3ead8"), 1.4, 9.0)
	_light(Vector3(2.0, 1.4, -1.0), Look.LAMP, 0.7, 6.0)


func _row(clip: String) -> Array:
	_new_set()
	_room(2.5)
	var people := []
	for i in WHO.size():
		var p := _mask(WHO[i], Vector3(1.8 - i * 1.2, 0, 0), PI)
		(p[0] as AnimationPlayer).play(StringName(clip))
		(p[0] as AnimationPlayer).advance(0.0)
		people.append(p)
	_lights_row()
	return people


func _run() -> void:
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false
	main.pub.shadows_near(AT)
	var glow := SpotLight3D.new()
	glow.spot_range = 9.0
	glow.spot_angle = 26.0
	glow.spot_angle_attenuation = 1.8
	glow.spot_attenuation = 0.0
	glow.light_color = HER_GLOW
	glow.light_energy = float(OS.get_environment("HER_LIGHT")) if OS.has_environment("HER_LIGHT") else HER_LIGHT
	glow.light_energy *= 1.0 if _want("room") else 0.3
	glow.light_cull_mask = 1 << (HER_LAYER - 1)
	glow.light_specular = 0.15
	glow.position = Vector3(0, 0.3, 0.0)
	main.view.cam.add_child(glow)
	var whom := WHO.filter(func(w): return _want(w))
	if whom.is_empty():
		whom = WHO
	var only_who := whom.size() < WHO.size() and not (_want("heights") or _want("quick") or _want("room") or _want("faces") or _want("far") or _want("talk") or _want("close") or _want("walk") or _want("turn") or _want("swing"))
	# each one close, straight on, every expression
	if _want("faces") or only_who:
		for who in whom:
			_new_set()
			_room(2.5)
			var p := _mask(who, Vector3.ZERO, PI)
			(p[0] as AnimationPlayer).play(&"Idle_Talking_Loop")
			(p[0] as AnimationPlayer).advance(0.0)
			_light(Vector3(-0.9, 2.4, -1.2), Color("f3ead8"), 1.3, 7.0)
			_light(Vector3(1.4, 1.2, -0.6), Look.LAMP, 0.6, 5.0)
			var face: DrawnFace = p[2]
			face.wear("neutral")
			_pose(p, 0.0)
			await _frames(2)
			var hp := _head_pos(p)
			await _look(hp + Vector3(0.0, 0.04, -1.25), hp + Vector3(0, -0.02, 0), 30.0)
			for ex in face.data.expressions:
				(p[1] as Skeleton3D).reset_bone_poses()
				(p[0] as AnimationPlayer).advance(0.0)
				face.wear(ex)
				_pose(p, 0.0)
				await _frames(2)
				await _grab("faces_%s_%s" % [who, ex])
	# how tall each one stands, to the top of the head
	if _want("heights"):
		var people := _row("Idle_Loop")
		for p in people:
			(p[2] as DrawnFace).wear("neutral")
			_pose(p, 0.0)
		await _frames(2)
		for p in people:
			var top := -INF
			for mi in (p[4] as Node3D).find_children("*", "MeshInstance3D", true, false):
				var m := mi as MeshInstance3D
				if not (String(m.name).ends_with("_mask") or String(m.name).ends_with("_hair")):
					continue
				var bb := m.get_aabb()
				for k in 8:
					top = maxf(top, (m.global_transform * bb.get_endpoint(k)).y)
			print("height ", p[3], " ", snappedf(top - AT.y, 0.01))
	# a look at a change: the four in a row at mid shot, then her face and the bartender's close
	if _want("quick"):
		var people := _row("Idle_Talking_Loop")
		for p in people:
			(p[2] as DrawnFace).wear("neutral")
			_pose(p, 0.0)
		await _look(Vector3(-0.6, 1.4, -3.6), Vector3(-0.6, 1.05, 0), 46.0)
		await _grab("quick_row")
		var her: Array = people[3]
		var hp := _head_pos(her)
		await _look(hp + Vector3(0.3, 0.02, -1.3), hp + Vector3(0, -0.06, 0), 34.0)
		await _grab("quick_her")
		var bt: Array = people[0]
		hp = _head_pos(bt)
		await _look(hp + Vector3(0.3, 0.02, -1.3), hp + Vector3(0, -0.06, 0), 34.0)
		await _grab("quick_bartender")
	# the four across the room, every expression at once
	if _want("far"):
		var people := _row("Idle_Talking_Loop")
		await _look(Vector3(0.0, 1.45, -5.2), Vector3(0, 1.2, 0), 48.0)
		for ex in ["neutral", "smile", "laugh", "sad", "angry", "shout", "surprised", "afraid", "suspicious", "disgust", "sly", "tired"]:
			for p in people:
				(p[1] as Skeleton3D).reset_bone_poses()
				(p[0] as AnimationPlayer).advance(0.0)
				(p[2] as DrawnFace).wear(ex)
				_pose(p, 0.0)
			await _frames(2)
			await _grab("far_" + ex)
	# the four talking, their feelings changing, looking at him
	if _want("talk"):
		var people := _row("Idle_Talking_Loop")
		var eye := Vector3(0.0, 1.5, -5.2)
		await _look(eye, Vector3(0, 1.1, 0), 46.0)
		await _talk(people, "talk", FRAMES * 2, eye)
	# the four walking
	if _want("walk"):
		var people := _row("Walk_Formal_Loop")
		await _look(Vector3(0.0, 1.3, -4.6), Vector3(0, 1.0, 0), 48.0)
		await _talk(people, "walk", FRAMES)
	# each one close, three-quarters on, talking to him
	if _want("close"):
		for who in whom:
			_new_set()
			_room(2.5)
			var p := _mask(who, Vector3.ZERO, PI + 0.35)
			(p[0] as AnimationPlayer).play(&"Idle_Talking_Loop")
			(p[0] as AnimationPlayer).advance(0.0)
			_light(Vector3(-0.9, 2.4, -1.2), Color("f3ead8"), 1.3, 7.0)
			_light(Vector3(1.4, 1.2, -0.6), Look.LAMP, 0.6, 5.0)
			(p[2] as DrawnFace).wear("neutral")
			_pose(p, 0.0)
			await _frames(2)
			var hp := _head_pos(p)
			var eye := hp + Vector3(0.35, 0.0, -1.7)
			await _look(eye, hp + Vector3(0, -0.2, 0), 40.0)
			await _talk([p], "close_" + who, FRAMES * 2, eye)
	# each one standing, turned round
	if _want("turn"):
		for who in whom:
			_new_set()
			_room(2.5)
			var p := _mask(who, Vector3.ZERO, PI)
			(p[0] as AnimationPlayer).play(&"Idle_Loop")
			(p[0] as AnimationPlayer).advance(0.0)
			_light(Vector3(-0.9, 2.6, -1.6), Color("f3ead8"), 1.3, 8.0)
			_light(Vector3(1.4, 1.4, -0.8), Look.LAMP, 0.6, 6.0)
			_light(Vector3(0.6, 2.2, 1.6), Color("f3ead8"), 0.7, 6.0)
			await _look(Vector3(0.0, 1.05, -3.9), Vector3(0, 0.98, 0), 40.0)
			var k := 0
			for yaw in [PI, PI + 0.7, PI + PI / 2.0, 2.3, 0.0]:
				(p[4] as Node3D).rotation.y = yaw
				(p[1] as Skeleton3D).reset_bone_poses()
				(p[0] as AnimationPlayer).advance(0.0)
				(p[2] as DrawnFace).wear("neutral")
				_pose(p, 0.0)
				await _frames(2)
				await _grab("turn_%s_%d" % [who, k])
				k += 1
	# each one walking, from behind and to the side
	if _want("swing"):
		for who in whom:
			_new_set()
			_room(2.5)
			var p := _mask(who, Vector3.ZERO, 0.75)
			(p[0] as AnimationPlayer).play(&"Walk_Formal_Loop")
			(p[0] as AnimationPlayer).advance(0.0)
			_light(Vector3(-0.9, 2.6, -1.6), Color("f3ead8"), 1.3, 8.0)
			_light(Vector3(1.4, 1.4, -0.8), Look.LAMP, 0.6, 6.0)
			_light(Vector3(0.6, 2.2, 1.6), Color("f3ead8"), 0.7, 6.0)
			await _look(Vector3(0.0, 1.0, -3.3), Vector3(0, 0.92, 0), 40.0)
			await _talk([p], "swing_" + who, FRAMES)
	# in the room itself, under its own lights, from where he is: a night started, the stage's own
	# people put away and the masks where they'd be. The bar, across from the bartender with Amanda
	# come behind it for an order; the floor, the big man at the pool table and Amanda crossing in
	# front of it; table 28, the team jacket on his stool and Amanda come to the table
	if _want("room"):
		main.start_new(2)
		await _frames(40)
		main.stage.visible = false
		main.stage.process_mode = Node.PROCESS_MODE_DISABLED
		# and nothing named under his eyes: the pictures are of the people
		main.spots.process_mode = Node.PROCESS_MODE_DISABLED
		main.spots.caption.visible = false
		for scene in ["bar", "floor", "t28"]:
			if not _want(scene) and (_want("bar") or _want("floor") or _want("t28")):
				continue
			if set_node != null:
				set_node.free()
			set_node = Node3D.new()
			main.pub.add_child(set_node)
			main.view.frame = ""
			main.view.jump_to(scene)
			var cast := []
			var paths := {}
			match scene:
				"bar":
					cast.append(_mask("bartender", Vector3(1.15, 0, 4.8), PI / 2.0))
					cast.append(_mask("amanda", Vector3(1.3, 0, 4.15), atan2(2.68 - 1.3, 5.0 - 4.15)))
				"floor":
					cast.append(_mask("bigman", Pub.POOL + Vector3(1.8, 0, 1.0), atan2(-1.8, -1.0)))
					var a := Vector3(7.7, 0, 3.4)
					var b := Vector3(9.9, 0, 5.75)
					paths["amanda"] = [a, b]
					cast.append(_mask("amanda", a, atan2(b.x - a.x, b.z - a.z)))
				"t28":
					# across the table from him, and Amanda come to the table at its side
					var a1 := TAU / 6.0 + 0.25
					var k1 := Pub.T28 + Vector3(cos(a1) * 1.18, 0, sin(a1) * 1.18)
					cast.append(_mask("team_jacket", k1, atan2(Pub.T28.x - k1.x, Pub.T28.z - k1.z)))
					var st := Pub.T28 + Vector3(-0.7, 0, 1.6)
					cast.append(_mask("amanda", st, atan2(9.08 - st.x, 6.97 - st.z)))
			for p in cast:
				var clip := &"Idle_Loop"
				if p[3] == "team_jacket":
					clip = &"Sitting_Talking_Loop"
				elif p[3] == "amanda" and paths.has("amanda"):
					clip = &"Walk_Formal_Loop"
				elif p[3] != "amanda":
					clip = &"Idle_Talking_Loop"
				(p[0] as AnimationPlayer).play(clip)
				(p[0] as AnimationPlayer).advance(0.0)
				(p[2] as DrawnFace).wear("knowing" if p[3] == "amanda" else "neutral")
				_pose(p, 0.0)
			await _frames(30)
			await _grab("room_" + scene)
			if not _want("still"):
				await _talk(cast, "room_" + scene, FRAMES, main.view.eye_pos, paths, Vector3.ZERO)
			# then he turns his head to her, and the light from his eyes comes up on her; she meets
			# his look, knowing
			for p in cast:
				if p[3] == "amanda":
					main.view.look_at_point(_head_pos(p) + AT)
					await _frames(120)
					(p[2] as DrawnFace).wear("knowing", 0, false, _gaze_at(p, main.view.cam.global_position))
					await _frames(2)
					await _grab("room_" + scene + "_her")
	quit()
