extends "res://tests/shots_styles.gd"
# The people as masks (PROPOSED, Hutch's pick of 18 November 2026; tools/masks.py builds them,
# tools/faces.py draws their faces): the bartender, the team jacket, the big man and Amanda side by
# side, each on the masks proportions with their own spin, talking and then walking, printed, on
# twos, their drawn faces swapped as they talk and blink. Then each one close, talking.
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_masks.gd -- --out /tmp/masks [--only row,close | --only amanda,bigman]

const MASKS := "res://models/masks/"
const WHO := ["bartender", "team_jacket", "bigman", "amanda"]

# the masks template (shots_styles.gd's "masks") and what each one changes in it
const SPIN := {
	# slight and wiry, fifties: a long face on a longer neck, narrow, thin arms, hands that work
	"bartender": {"neck_01": {"len": 1.15}, "Head": {"len": 0.62, "s": 1.7}, "spine_03": {"len": 0.9, "s": 0.95},
		"upperarm_l": {"s": 0.85}, "upperarm_r": {"s": 0.85}, "lowerarm_l": {"len": 1.0}, "lowerarm_r": {"len": 1.0},
		"hand_l": {"len": 1.0, "s": 1.5}, "hand_r": {"len": 1.0, "s": 1.5}, "calf_l": {"len": 0.8}, "calf_r": {"len": 0.8}},
	# the loudest at table 28: the biggest head of them, no neck, short legs under the belly
	"team_jacket": {"neck_01": {"len": 0.6}, "Head": {"len": 0.42, "s": 2.05}, "spine_01": {"len": 0.8},
		"spine_02": {"len": 0.8}, "calf_l": {"len": 0.6}, "calf_r": {"len": 0.6}, "foot_l": {"len": 0.6, "s": 1.5},
		"foot_r": {"len": 0.6, "s": 1.5}},
	# all shoulders: a small head for the masks, sunk in a thick neck, a chest like a door, huge hands
	"bigman": {"neck_01": {"len": 0.8, "s": 1.2}, "Head": {"len": 0.6, "s": 1.25}, "spine_02": {"len": 0.9, "s": 1.12},
		"spine_03": {"len": 0.95, "s": 1.25}, "clavicle_l": {"len": 1.12}, "clavicle_r": {"len": 1.12},
		"upperarm_l": {"len": 1.0, "s": 1.05}, "upperarm_r": {"len": 1.0, "s": 1.05}, "lowerarm_l": {"len": 1.0},
		"lowerarm_r": {"len": 1.0}, "hand_l": {"len": 1.0, "s": 1.75}, "hand_r": {"len": 1.0, "s": 1.75}},
	# quick: a big fox's head on a slender neck, the longest legs of them, small feet
	"amanda": {"neck_01": {"len": 1.05}, "Head": {"len": 0.55, "s": 1.85}, "spine_03": {"len": 0.9, "s": 0.95},
		"hand_l": {"len": 0.9, "s": 1.35}, "hand_r": {"len": 0.9, "s": 1.35}, "calf_l": {"len": 0.88},
		"calf_r": {"len": 0.88}, "foot_l": {"len": 0.8, "s": 1.05}, "foot_r": {"len": 0.8, "s": 1.05}},
}
# how each one talks: the pictures in turn, a held pose each a twelfth of a second; a blink now and
# then; their own extra in the middle of it
const TALK := ["talk_a", "talk_b", "talk_a", "neutral", "talk_b", "talk_a", "neutral", "neutral"]
const EXTRA := {"team_jacket": "laugh", "amanda": "wink"}
const HAIR := ["hair_grey", "hair_white", "hair_dark", "hair_rust", "hair", "hair_red"]


func _spin(who: String) -> Dictionary:
	var s: Dictionary = STYLES["masks"].duplicate(true)
	var mine: Dictionary = SPIN[who]
	for b in mine:
		var d: Dictionary = s.get(b, {}).duplicate()
		d.merge(mine[b], true)
		s[b] = d
	return s


# a mask person: its clothes and skin in the print's strokes, its face a picture we can swap
func _mask(who: String, pos: Vector3, yaw: float) -> Array:
	var n: Node3D = main.pub.model(MASKS + who + ".glb", pos, set_node)
	n.rotation.y = yaw
	var face: ShaderMaterial = null
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(i)
			var key := src.resource_name if src else ""
			var c := (src as BaseMaterial3D).albedo_color if src is BaseMaterial3D else Color(0.7, 0.7, 0.7)
			var mat: ShaderMaterial
			if key.begins_with("face_"):
				mat = main.pub.mat(Color(1, 1, 1), 0.9, 0.0, 4, Vector3.UP, 4.5, 0.7)
				face = mat
			elif key in HAIR:
				mat = main.pub.mat(c, 0.9, 0.0, 4, Vector3.UP, 3.5, 0.5)
			else:
				mat = main.pub.mat(c, 0.9, 0.0, 4, Vector3.UP, 4.5, 0.7)
			m.set_surface_override_material(i, mat)
	var ap := AnimationPlayer.new()
	n.add_child(ap)
	ap.root_node = NodePath("..")
	ap.add_animation_library(&"", _lib())
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	return [ap, sk, face]


func _face(who: String, face: ShaderMaterial, f: int, talking: bool) -> void:
	if face == null:
		return
	var e := "neutral"
	if talking:
		e = TALK[f % TALK.size()]
	if (f + WHO.find(who) * 5) % 17 == 16:
		e = "blink"
	if EXTRA.has(who) and f >= 12 and f < 16:
		e = EXTRA[who]
	face.set_shader_parameter("albedo_tex", main.pub.tex(MASKS + who + "_" + e + ".png"))


func _play(people: Array, clip: String, tag: String, talking: bool) -> void:
	for p in people:
		(p[0] as AnimationPlayer).play(StringName(clip))
		(p[0] as AnimationPlayer).advance(0.0)
	for f in FRAMES:
		for i in people.size():
			var p: Array = people[i]
			_shape(p[1], _spin(p[3]))
			_face(p[3], p[2], f, talking)
		await _frames(2)
		await _grab("%s_%02d" % [tag, f])
		for p in people:
			(p[1] as Skeleton3D).reset_bone_poses()
			(p[0] as AnimationPlayer).advance(STEP)


func _run() -> void:
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false
	main.pub.shadows_near(AT)
	if _want("row"):
		for clip in ["Idle_Talking_Loop", "Walk_Formal_Loop"]:
			_new_set()
			_room(2.5)
			var people := []
			for i in WHO.size():
				var p := _mask(WHO[i], Vector3(1.95 - i * 1.3, 0, 0), PI)
				p.append(WHO[i])
				people.append(p)
			_light(Vector3(-1.5, 2.8, -1.6), Color("f3ead8"), 1.4, 9.0)
			_light(Vector3(2.0, 1.4, -1.0), Look.LAMP, 0.7, 6.0)
			await _look(Vector3(0.0, 1.3, -4.6), Vector3(0, 1.0, 0), 48.0)
			await _play(people, clip, "row_talk" if clip.begins_with("Idle") else "row_walk", clip.begins_with("Idle"))
	for who in WHO:
		if _want("close") or _want(who):
			_new_set()
			_room(2.5)
			var p := _mask(who, Vector3.ZERO, PI + 0.35)
			p.append(who)
			_light(Vector3(-0.9, 2.4, -1.2), Color("f3ead8"), 1.3, 7.0)
			_light(Vector3(1.4, 1.2, -0.6), Look.LAMP, 0.6, 5.0)
			await _look(Vector3(0.25, 1.5, -2.2), Vector3(0, 1.15, 0), 40.0)
			await _play([p], "Idle_Talking_Loop", "close_" + who, true)
	quit()
