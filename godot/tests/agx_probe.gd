extends SceneTree
# What the eye's tonemapper does to a few reds: unshaded quads in a row, read back.

const CANDS := [Color(1.0, 0.24, 0.16), Color(0.85, 0.12, 0.08), Color(0.7, 0.05, 0.05), Color(0.8, 0.0, 0.1),
	Color(0.6, 0.0, 0.08), Color(1.0, 0.0, 0.15), Color(0.5, 0.02, 0.04), Color(0.9, 0.05, 0.25)]


func _init() -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0
	cam.position = Vector3(0, 0, 5)
	root.add_child(cam)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.5
	we.environment = env
	root.add_child(we)
	for i in CANDS.size():
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.4, 1.5)
		mi.mesh = q
		mi.position = Vector3(-1.75 + i * 0.5, 0, 0)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = CANDS[i]
		mi.material_override = m
		root.add_child(mi)
	_go.call_deferred()


func _go() -> void:
	for k in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var w := img.get_width()
	var h := img.get_height()
	for i in CANDS.size():
		var x := int((0.5 + (-1.75 + i * 0.5) / 4.0 * (float(h) / float(w)) * 2.0 * 0.5 * 2.0) * w) if false else int(w / 2.0 + (-1.75 + i * 0.5) * (h / 2.0))
		var c := img.get_pixel(clampi(x, 0, w - 1), h / 2)
		print("in ", CANDS[i].to_html(false), " out ", c.to_html(false), " (%.2f %.2f %.2f)" % [c.r, c.g, c.b])
	quit()
