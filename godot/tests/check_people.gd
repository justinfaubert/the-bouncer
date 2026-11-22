extends SceneTree
# A look at people before anyone else sees them: each one alone against flat grey under plain light
# (no print, so a hole is a hole and not a stroke), the room's own movements put through them by
# world/life.gd (a sip of whatever they hold, breathing, the head going), and pictures at the top of
# the sip from the front, three-quarter, both sides and behind; and each picture again with the
# insides of every surface drawn red (any red within the figure is a way into it: a hole). tools/check_people.py runs this
# with the mesh checks and writes the review.
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 700x1000 \
#     --path godot -s res://tests/check_people.gd -- --out DIR --who patron_c,bigman [--dir res://models/people/]

var out := "/tmp/check_people"
var who: Array = ["patron_c"]
var dir := "res://models/people/"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		match args[k]:
			"--out": out = args[k + 1]
			"--who": who = Array(args[k + 1].split(","))
			"--dir": dir = args[k + 1]
	DirAccess.make_dir_recursive_absolute(out)
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode cull_disabled, unshaded;\nvoid fragment() {\n\tALBEDO = FRONT_FACING ? vec3(0.55) : vec3(1.0, 0.0, 0.0);\n}\n"
	_inside.shader = sh
	_run.call_deferred()


var _inside := ShaderMaterial.new()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("8c8f94")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b9bcc2")
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	for d in [[Vector3(-50, 30, 0), 1.0], [Vector3(-20, 200, 0), 0.5]]:
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = d[0]
		sun.light_energy = d[1]
		world.add_child(sun)
	# no floor: anything of the background seen inside a figure is a hole through it
	var cam := Camera3D.new()
	cam.fov = 40.0
	world.add_child(cam)
	cam.make_current()
	for model in who:
		var holder := Node3D.new()
		world.add_child(holder)
		# read straight from the file, so a model just exported is seen without an import
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(dir + model + ".glb"), st) != OK:
			print("check ", model, " could not be read")
			continue
		var body: Node3D = doc.generate_scene(st)
		holder.add_child(body)
		var an := {}
		var jp: String = dir + model + ".json"
		if FileAccess.file_exists(jp):
			var d = JSON.parse_string(FileAccess.get_file_as_string(jp))
			if d is Dictionary:
				an = d
		var life := Life.new()
		var rigged := life.add(model, holder, body, an, false)
		var sips := false
		if rigged and life.people.has(model):
			var sp: Dictionary = life.people[model].sip
			if not sp.is_empty():
				sp.next = 0.0
				sips = true
		print("check ", model, " rigged=", rigged, " sips=", sips)
		var h: float = 1.75
		if an.has("head"):
			h = float(an.head[1])
		var c := Vector3(0, h * 0.6, 0)
		cam.global_position = c + Vector3(0, 0.1, -3.4)
		cam.look_at(c, Vector3.UP)
		# to the top of the sip: the glass at the mouth after a second and a bit
		for k in 40:
			if rigged:
				life.update(1.0 / 30.0, cam.global_position, -cam.global_transform.basis.z, {})
			await _frames(1)
		# the model faces -z: its front is seen from -z
		for v in [["front", 0.0], ["three", 35.0], ["left", 90.0], ["back", 180.0], ["right", -90.0]]:
			var dv := Vector3(0, 0, -1).rotated(Vector3.UP, deg_to_rad(v[1]))
			cam.global_position = c + dv * 3.4 + Vector3(0, 0.1, 0)
			cam.look_at(c, Vector3.UP)
			await _frames(3)
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s.png" % [model, v[0]]))
			# again with every surface's inside drawn red: red within the figure is a way into it
			var meshes := body.find_children("*", "MeshInstance3D", true, false)
			for mi in meshes:
				(mi as MeshInstance3D).material_override = _inside
			await _frames(2)
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s_inside.png" % [model, v[0]]))
			for mi in meshes:
				(mi as MeshInstance3D).material_override = null
		life.remove(model)
		holder.queue_free()
		await _frames(2)
	quit()
