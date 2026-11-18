extends "res://tests/shots_people_m1.gd"
# The borrowed motion (models/quaternius/: Quaternius' base body and his Universal Animation
# Library, both CC0), printed, and played on twos: a new pose every twelfth of a second, held. A
# run of frames of each clip for a strip or a GIF. Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_motion.gd -- --out /tmp/motion [--only talk,sit,walk]

const Q := "res://models/quaternius/"
const STEP := 1.0 / 12.0
const CLIPS := {
	"talk": ["Idle_Talking_Loop", Vector3(0.0, 0.0, 0.0), 0.0],
	"sit": ["Sitting_Talking_Loop", Vector3(0.0, 0.0, 0.0), 0.0],
	"walk": ["Walk_Formal_Loop", Vector3(0.0, 0.0, 0.0), 0.6],
}
const FRAMES := 24


func _lib() -> AnimationLibrary:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_file(Q + "ual1.glb", st)
	var sc := doc.generate_scene(st)
	var ap: AnimationPlayer = sc.find_children("*", "AnimationPlayer", true, false)[0]
	var lib: AnimationLibrary = ap.get_animation_library(&"")
	sc.free()
	return lib


func _body(model: String, pos: Vector3, yaw: float) -> AnimationPlayer:
	var n: Node3D = main.pub.model(Q + model + ".glb", pos, set_node)
	n.rotation.y = yaw
	var skin: Material = main.pub.mat(Color("c7a38a"), 0.9, 0.0, 4, Vector3.UP, 4.5, 0.7)
	var hair: Material = main.pub.mat(Color("3a2e26"), 0.9, 0.0, 4, Vector3.UP, 3.5, 0.5)
	var eye: Material = main.pub.mat(Color("2a2420"), 0.9, 0.0, 3, Vector3.UP, 5.0, 0.0)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var which: Material = skin
		if "Eyebrow" in m.name:
			which = hair
		elif "Eye" in m.name:
			which = eye
		for i in m.mesh.get_surface_count():
			m.set_surface_override_material(i, which)
	var ap := AnimationPlayer.new()
	n.add_child(ap)
	ap.root_node = NodePath("..")
	ap.add_animation_library(&"", _lib())
	# on twos: the clip is stepped by hand, a twelfth of a second at a time
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	return ap


func _run() -> void:
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false
	main.pub.shadows_near(AT)
	for clip in CLIPS:
		if not _want(clip):
			continue
		_new_set()
		_room(3.0)
		var c: Array = CLIPS[clip]
		if clip == "sit":
			_box(Vector3(0.45, 0.45, 0.45), Vector3(0, 0.225, 0.05), main.pub.M.top)
		var ap := _body("base_male", c[1], PI)
		ap.play(StringName(c[0]))
		ap.advance(0.0)
		_light(Vector3(-0.9, 2.4, -1.2), Color("f3ead8"), 1.3, 7.0)
		_light(Vector3(1.4, 1.2, -0.6), Look.LAMP, 0.6, 5.0)
		await _look(Vector3(0.6, 1.55, -2.6), Vector3(0, 1.0 if clip != "sit" else 0.8, 0), 40.0)
		for f in FRAMES:
			await _grab("%s_%02d" % [clip, f])
			ap.advance(STEP)
			await _frames(2)
	quit()
