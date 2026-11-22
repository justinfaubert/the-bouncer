extends SceneTree
# Prints a still offline: an eye's picture and its mask, as tests/shots_places.gd --raw keeps them,
# through look/press.gdshader, in a second, for tuning the press without running a night:
#   xvfb-run -a godot --rendering-driver opengl3 --path godot -s res://tests/press_still.gd -- \
#     --in /tmp/places/floor_1290 --out /tmp/press [--set band=0.1,0.95] [--set lift=0.8]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var src := ""
	var out := "/tmp/press"
	var sets: Array = []
	for k in args.size():
		match args[k]:
			"--in": src = args[k + 1]
			"--out": out = args[k + 1]
			"--set": sets.append(args[k + 1])
	DirAccess.make_dir_recursive_absolute(out)
	var raw := ImageTexture.create_from_image(Image.load_from_file(src + "_raw.png"))
	var msk := ImageTexture.create_from_image(Image.load_from_file(src + "_mask.png"))
	var size := raw.get_size()
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var rect := TextureRect.new()
	rect.texture = raw
	rect.size = size
	var m := ShaderMaterial.new()
	m.shader = load("res://look/press.gdshader")
	m.set_shader_parameter("scene", raw)
	m.set_shader_parameter("cut_mask", msk)
	for n in ["separation", "separation_b", "grain", "paper_tex"]:
		var f: String = "paper" if n == "paper_tex" else n
		m.set_shader_parameter(n, ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://press/%s.png" % f))))
	m.set_shader_parameter("paper", Look.STOCK)
	m.set_shader_parameter("ink_night", Look.NIGHT)
	m.set_shader_parameter("ink_lamp", Look.LAMP)
	m.set_shader_parameter("ink_neon", Look.NEON)
	m.set_shader_parameter("ink_cold", Look.COLD)
	m.set_shader_parameter("ink_earth", Look.EARTH)
	m.set_shader_parameter("view_px", Vector2(size))
	for sv in sets:
		var kv: PackedStringArray = sv.split("=")
		var v: PackedStringArray = kv[1].split(",")
		m.set_shader_parameter(kv[0], float(v[0]) if v.size() == 1 else Vector2(float(v[0]), float(v[1])))
	rect.material = m
	vp.add_child(rect)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var name := src.get_file() + ("_" + "_".join(sets).replace("=", "").replace(",", "-") if sets.size() > 0 else "")
	vp.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("press ", name)
	quit()
