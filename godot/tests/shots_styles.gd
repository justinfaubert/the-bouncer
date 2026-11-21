extends "res://tests/shots_motion.gd"
# Four ways the people could be drawn, sketched on the borrowed base body by pulling its skeleton
# about after each step of the clip (PROPOSED, for Hutch to choose from): the four side by side,
# talking and then walking, printed and on twos.
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_styles.gd -- --out /tmp/styles
#
# Per bone: "len" stretches the bone it hangs from (its offset from its parent), "s" scales it
# (and what hangs from it) all round. A bone scaled down with "len" on its child at the inverse
# keeps its length and loses its girth: a thin limb.

const STYLES := {
	# 1. Long people: Varo, Carrington, de Chirico; Aeon Flux. Tall, narrow, long necks, small heads,
	# thin long limbs, tiny feet.
	"long": {
		"spine_01": {"len": 1.25}, "spine_02": {"len": 1.3}, "spine_03": {"len": 1.3, "s": 0.85}, "neck_01": {"len": 1.1},
		"Head": {"len": 2.8, "s": 0.78},
		"upperarm_l": {"len": 0.8, "s": 0.78}, "upperarm_r": {"len": 0.8, "s": 0.78},
		"lowerarm_l": {"len": 1.6}, "lowerarm_r": {"len": 1.6}, "hand_l": {"len": 1.55, "s": 1.25}, "hand_r": {"len": 1.55, "s": 1.25},
		"thigh_l": {"s": 0.78}, "thigh_r": {"s": 0.78}, "calf_l": {"len": 1.6}, "calf_r": {"len": 1.6},
		"foot_l": {"len": 1.65, "s": 0.6}, "foot_r": {"len": 1.65, "s": 0.6},
	},
	# 2. Masks and big eyes: Ensor, Redon; Ren & Stimpy, Courage. Big heads, squat, big hands and
	# feet, short legs.
	"masks": {
		"spine_01": {"len": 0.85}, "spine_02": {"len": 0.85}, "spine_03": {"len": 0.85, "s": 1.12},
		"neck_01": {"len": 0.9}, "Head": {"len": 0.5, "s": 1.9},
		"lowerarm_l": {"len": 0.85}, "lowerarm_r": {"len": 0.85}, "hand_l": {"len": 0.85, "s": 1.6}, "hand_r": {"len": 0.85, "s": 1.6},
		"calf_l": {"len": 0.7}, "calf_r": {"len": 0.7}, "foot_l": {"len": 0.7, "s": 1.4}, "foot_r": {"len": 0.7, "s": 1.4},
	},
	# 3. Dark deco: Klimt, Khnopff; Batman: The Animated Series, Gargoyles. A big square chest and
	# shoulders, a short thick neck, long arms and big hands, thin legs tapering to small feet.
	"deco": {
		"spine_02": {"s": 1.15}, "spine_03": {"len": 1.05, "s": 1.45}, "neck_01": {"s": 0.8}, "Head": {"len": 0.7, "s": 0.92},
		"upperarm_l": {"len": 1.35}, "upperarm_r": {"len": 1.35},
		"lowerarm_l": {"len": 1.12}, "lowerarm_r": {"len": 1.12}, "hand_l": {"len": 1.12, "s": 1.4}, "hand_r": {"len": 1.12, "s": 1.4},
		"pelvis": {"s": 0.78}, "thigh_l": {"s": 0.6}, "thigh_r": {"s": 0.6},
		"calf_l": {"len": 1.7}, "calf_r": {"len": 1.7}, "foot_l": {"len": 1.7, "s": 0.6}, "foot_r": {"len": 1.7, "s": 0.6},
	},
	# 4. Paper dolls: Daisies, Ernst, Svankmajer; Rugrats, Real Monsters. Lopsided: a big head on a
	# long neck, one shoulder up, a pear of a body on skinny legs, big shoes.
	"dolls": {
		"spine_03": {"s": 0.9}, "neck_01": {"len": 1.1}, "Head": {"len": 1.9, "s": 1.45},
		"upperarm_l": {"len": 1.25, "s": 0.72}, "upperarm_r": {"len": 0.8, "s": 0.72},
		"lowerarm_l": {"len": 1.39}, "lowerarm_r": {"len": 1.39}, "hand_l": {"len": 1.0, "s": 1.3}, "hand_r": {"len": 1.0, "s": 1.3},
		"pelvis": {"s": 1.25}, "thigh_l": {"s": 0.6}, "thigh_r": {"s": 0.6},
		"calf_l": {"len": 1.5}, "calf_r": {"len": 1.5}, "foot_l": {"len": 1.5, "s": 1.7}, "foot_r": {"len": 1.5, "s": 1.7},
	},
}
const ORDER := ["long", "masks", "deco", "dolls"]


func _shape(sk: Skeleton3D, style: Dictionary) -> void:
	# what each bone's scale is in the end, all round; its children are scaled back so a bone's
	# scale is its own
	for b in sk.get_bone_count():
		var bn := sk.get_bone_name(b)
		var want: Dictionary = style.get(bn, {})
		var p := sk.get_bone_parent(b)
		var ps := 1.0
		if p >= 0:
			ps = float(style.get(sk.get_bone_name(p), {}).get("s", 1.0))
		var s := float(want.get("s", 1.0))
		var pos := sk.get_bone_pose_position(b) * float(want.get("len", 1.0))
		sk.set_bone_pose_position(b, pos)
		sk.set_bone_pose_scale(b, sk.get_bone_pose_scale(b) * (s / ps))


func _run() -> void:
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false
	main.pub.shadows_near(AT)
	for clip in ["Idle_Talking_Loop", "Walk_Formal_Loop"]:
		_new_set()
		_room(2.5)
		var aps := []
		var sks := []
		for i in ORDER.size():
			var ap := _body("base_male", Vector3(1.95 - i * 1.3, 0, 0), PI)
			ap.play(StringName(clip))
			ap.advance(0.0)
			aps.append(ap)
			sks.append((ap.get_parent() as Node).find_children("*", "Skeleton3D", true, false)[0])
		_light(Vector3(-1.5, 2.8, -1.6), Color("f3ead8"), 1.4, 9.0)
		_light(Vector3(2.0, 1.4, -1.0), Look.LAMP, 0.7, 6.0)
		await _look(Vector3(0.0, 1.3, -4.6), Vector3(0, 1.0, 0), 48.0)
		var tag := "talk" if clip.begins_with("Idle") else "walk"
		for f in FRAMES:
			for i in ORDER.size():
				_shape(sks[i], STYLES[ORDER[i]])
			await _frames(2)
			await _grab("%s_%02d" % [tag, f])
			for i in ORDER.size():
				# back to the rest pose first: the clip only sets what it keys, and the shaping
				# would pile up on what it doesn't
				(sks[i] as Skeleton3D).reset_bone_poses()
				(aps[i] as AnimationPlayer).advance(STEP)
	quit()
