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
# the side: the hair and clothes moving). who: one or more of them.

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
		"calf_l": {"len": 0.6}, "calf_r": {"len": 0.6}, "foot_l": {"len": 0.6, "s": 1.5}, "foot_r": {"len": 0.6, "s": 1.5}},
	# all shoulders: a small head for the masks, sunk in a thick neck, a chest like a door, huge hands
	"bigman": {"neck_01": {"len": 0.8, "s": 1.2}, "Head": {"len": 0.6, "s": 1.25}, "spine_02": {"len": 0.9, "s": 1.12},
		"spine_03": {"len": 0.95, "s": 1.25}, "clavicle_l": {"len": 1.12}, "clavicle_r": {"len": 1.12},
		"upperarm_l": {"len": 1.0, "s": 1.05}, "upperarm_r": {"len": 1.0, "s": 1.05}, "lowerarm_l": {"len": 1.0},
		"lowerarm_r": {"len": 1.0}, "hand_l": {"len": 1.0, "s": 1.55}, "hand_r": {"len": 1.0, "s": 1.55}},
	# the one who stands out: closest of them to a real woman, drawn the way a pin-up is. A smaller
	# head than theirs on a long neck, a narrow waist, long legs set close (her walk puts one foot in
	# front of the other), up on heels (the pitch: tools/masks.py builds the heels for 24 degrees);
	# the braid hangs past her hips
	"amanda": {"neck_01": {"len": 1.0}, "Head": {"len": 1.2, "s": 1.3}, "spine_01": {"len": 1.0, "s": 0.9},
		"spine_02": {"len": 1.0}, "spine_03": {"len": 1.0, "s": 1.0}, "pelvis": {"s": 1.04},
		"upperarm_l": {"s": 0.9}, "upperarm_r": {"s": 0.9}, "lowerarm_l": {"len": 1.0}, "lowerarm_r": {"len": 1.0},
		"hand_l": {"len": 1.0, "s": 1.05}, "hand_r": {"len": 1.0, "s": 1.05},
		"thigh_l": {"len": 0.72}, "thigh_r": {"len": 0.72}, "calf_l": {"len": 1.1}, "calf_r": {"len": 1.1},
		"foot_l": {"len": 1.12, "s": 0.9, "pitch": 24.0}, "foot_r": {"len": 1.12, "s": 0.9, "pitch": 24.0},
		"ball_l": {"pitch": -24.0}, "ball_r": {"pitch": -24.0}},
}
# what each one goes through while they talk, a quarter of the clip each
const SCRIPT := {
	"bartender": ["neutral", "suspicious", "angry", "eyeroll"],
	"team_jacket": ["neutral", "laugh", "sad", "drunk"],
	"bigman": ["neutral", "menace", "surprised", "laugh"],
	"amanda": ["sly", "wink", "laugh", "tease"],
}
# the mouths in turn as they talk, a held pose each: 0 shut, 1 a little open, 2 wide, 3 round
const TALK := [1, 2, 1, 0, 3, 2, 1, 0, 2, 1, 3, 0]
const HAIR := ["hair_grey", "hair_white", "hair_dark", "hair_rust", "hair_black", "hair", "hair_red"]


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
			else:
				mat = main.pub.mat(c, 0.9, 0.0, 4, Vector3.UP, 4.5, 0.7)
			m.set_surface_override_material(i, mat)
	var ap := AnimationPlayer.new()
	n.add_child(ap)
	ap.root_node = NodePath("..")
	ap.add_animation_library(&"", _lib())
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var hair: HairChain = HairChain.new(sk) if sk.find_bone("braid_00") >= 0 else null
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


func _step(people: Array) -> void:
	for p in people:
		(p[1] as Skeleton3D).reset_bone_poses()
		(p[0] as AnimationPlayer).advance(STEP)


func _talk(people: Array, tag: String, frames: int, eye := Vector3.INF) -> void:
	for f in frames:
		for i in people.size():
			var p: Array = people[i]
			var who: String = p[3]
			var script: Array = SCRIPT[who]
			var ex: String = script[mini(f * script.size() / frames, script.size() - 1)]
			var shut := (f + i * 5) % 19 == 18
			var g := Vector2.ZERO
			if eye != Vector3.INF:
				g = _gaze_at(p, AT + eye)
			(p[2] as DrawnFace).wear(ex, TALK[(f + i * 3) % TALK.size()], shut, g)
			_pose(p)
		await _frames(2)
		await _grab("%s_%02d" % [tag, f])
		_step(people)


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
	var whom := WHO.filter(func(w): return _want(w))
	if whom.is_empty():
		whom = WHO
	var only_who := whom.size() < WHO.size() and not (_want("faces") or _want("far") or _want("talk") or _want("close") or _want("walk") or _want("turn") or _want("swing"))
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
			await _look(Vector3(0.0, 1.0, -3.3), Vector3(0, 0.92, 0), 40.0)
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
	quit()
