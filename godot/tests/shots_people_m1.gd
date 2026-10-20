extends SceneTree
# Pictures of the people for the RPG's first month (models/people/), in the print, each in a bare
# stand-in for where they'll be, lit, and seen from where the player sees them: him across the desk
# in the wooden armchair, and standing in the office doorway; the short-haired him of his licence,
# and the photo game/props.gd makes of that head; the bookkeeper writing at her desk; the kid on the
# freezer outside the gas station; the old man at the rail over the water. Then Gary's own right
# hand up in his view across the desk, the way props.gd holds a licence and a phone, the licence with
# a stand-in face whose name is a block of ink, to see that his thumb covers it; and the hand again
# with the strokes its new materials would get from a line in pub.gd's CUTS. A model that isn't
# there yet is passed over. Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_people_m1.gd -- --out /tmp/people [--only desk,door,card,books,kid,wharf,hands]

var main
var out := "/tmp/people"
var only: Array = []
var set_node: Node3D
const AT := Vector3(240, 0, 240)          # well away from the building, where nothing else is
const PEOPLE := "res://models/people/"
# where the licence's name is printed, as fractions of its face from the top left corner: what his
# thumb has to cover
const NAME := Rect2(0.45, 0.28, 0.5, 0.34)
# how props.gd holds a licence and a phone in his view (its _pose), at rest and held up to look at;
# a licence held up goes beside the face of whoever handed it over (its _beside_face)
const POSES := {"card:rest": [Vector3(0.062, -0.07, -0.25), Vector3(12, -8, 4)],
	"phone:rest": [Vector3(0.05, -0.085, -0.27), Vector3(14, -6, 2)], "phone:look": [Vector3(0.0, -0.02, -0.2), Vector3(4, 0, 0)]}
# the materials of Gary's hand that pub.gd doesn't cut yet, and the cut each would want
const NEW_CUTS := {"skin_pale": [4, Vector3.UP, 4.5, 0.7], "hand_hair": [4, Vector3.UP, 3.5, 0.5], "age_spot": [4, Vector3.UP, 4.5, 0.7],
	"oxford": [4, Vector3.UP, 5.5, 0.8], "gold": [3, Vector3.UP, 5.0, 0.0]}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]; i += 1
			"--only": only = Array(args[i + 1].split(",")); i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


# the world's part of the screen, without the page beside it
func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img = img.get_region(Rect2i(0, 0, roundi(img.get_width() * View.WORLD_W), img.get_height()))
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _want(what: String) -> bool:
	return only.is_empty() or what in only


func _has(model: String) -> bool:
	if FileAccess.file_exists(PEOPLE + model + ".glb"):
		return true
	print("  no ", model, " yet")
	return false


# ---------------------------------------------------------------- the stand-in places

func _new_set() -> void:
	if set_node != null:
		set_node.free()
	set_node = Node3D.new()
	main.pub.add_child(set_node)
	set_node.position = AT


func _box(size: Vector3, pos: Vector3, m: Material, rot_y := 0.0) -> MeshInstance3D:
	return main.pub.box(size, pos, m, rot_y, set_node)


func _light(pos: Vector3, c: Color, e: float, r: float, shadow := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = r
	l.shadow_enabled = shadow
	set_node.add_child(l)
	l.position = pos
	return l


func _figure(model: String, pos := Vector3.ZERO, yaw := 0.0) -> Node3D:
	var n: Node3D = main.pub.model(PEOPLE + model + ".glb", pos, set_node)
	n.rotation.y = yaw
	return n


func _anchor(model: String, k: String, fallback := Vector3.ZERO) -> Vector3:
	var a: Dictionary = main.stage.anchors_of(model)
	return Props._v3(a[k]) if a.has(k) else fallback


# his eyes at `from`, on `at` (both in the set)
func _look(from: Vector3, at: Vector3, fov := 58.0) -> void:
	var v = main.view
	v.eye_pos = AT + from
	var a: Vector2 = Posts.aim(v.eye_pos, AT + at)
	v.yaw = a.x
	v.pitch = a.y
	v.want_yaw = a.x
	v.want_pitch = a.y
	v.focus_fov = fov
	await _frames(30)


func _room(depth := 4.0) -> void:
	var M: Dictionary = main.pub.M
	main.pub.tiled(Vector3(8, 0.1, 8), Vector3(0, -0.05, 0), M.boards, 2.0, set_node)
	main.pub.tiled(Vector3(8, 3.0, 0.15), Vector3(0, 1.5, depth), M.wall, 2.0, set_node)


# the office: the desk, his wooden armchair, a lamp on the desk and the light overhead
func _office(model: String) -> Vector3:
	var M: Dictionary = main.pub.M
	_room(1.4)
	var seat := _anchor(model, "seat", Vector3(0, 0.46, 0))
	var arm_l := _anchor(model, "armrest_left", Vector3(-0.3, 0.66, -0.3))
	var arm_r := _anchor(model, "armrest_right", Vector3(0.3, 0.66, -0.3))
	var edge := _anchor(model, "desk_edge", Vector3(0, 0.76, -1.2))
	# the chair: the seat, the back leaning back with him, its arms out to under his hands, the legs
	_box(Vector3(0.56, 0.05, 0.5), Vector3(0, seat.y - 0.025, -0.02), M.wood)
	var back := _box(Vector3(0.56, 0.62, 0.04), Vector3(0, seat.y + 0.33, 0.27), M.wood)
	back.rotation.x = deg_to_rad(-10)
	for a in [arm_l, arm_r]:
		var front: float = a.z - 0.035
		_box(Vector3(0.056, 0.04, 0.27 - front), Vector3(a.x, a.y - 0.02, (front + 0.27) / 2.0), M.wood)
		_box(Vector3(0.04, a.y - seat.y, 0.04), Vector3(a.x, (a.y + seat.y) / 2.0, front + 0.04), M.wood)
	for x in [-0.25, 0.25]:
		for z in [-0.24, 0.22]:
			_box(Vector3(0.04, seat.y - 0.05, 0.04), Vector3(x, (seat.y - 0.05) / 2.0, z), M.wood)
	# the desk, its near edge where the model says
	var depth := 0.8
	_box(Vector3(1.5, 0.035, depth), Vector3(0, edge.y - 0.0175, edge.z - depth / 2.0), M.top)
	for x in [-0.72, 0.72]:
		_box(Vector3(0.035, edge.y - 0.035, depth - 0.04), Vector3(x, (edge.y - 0.035) / 2.0, edge.z - depth / 2.0), M.wood)
	_box(Vector3(1.4, 0.5, 0.02), Vector3(0, edge.y - 0.3, edge.z - 0.06), M.wood)
	_light(Vector3(0.55, edge.y + 0.42, edge.z - 0.3), Look.LAMP, 1.1, 2.6)
	_light(Vector3(-0.4, 2.7, -0.6), Color("f3ead8"), 0.9, 6.0)
	_box(Vector3(0.14, 0.02, 0.14), Vector3(0.55, edge.y + 0.01, edge.z - 0.3), M.black)
	return edge


# ---------------------------------------------------------------- the people

func _run() -> void:
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false            # no heartbeat or drink in the pictures
	main.pub.shadows_near(AT)                # the building's lamps cast none out here
	if _want("desk") and _has("him_desk"):
		_new_set()
		var edge := _office("him_desk")
		_figure("him_desk")
		var head := _anchor("him_desk", "head", Vector3(0, 1.3, 0))
		# Gary, in his chair across the desk
		await _look(Vector3(0.06, 1.17, edge.z - 1.15), head + Vector3(0, -0.2, 0))
		await _grab("desk_across")
		await _look(Vector3(-1.5, 1.45, edge.z - 0.2), head + Vector3(0, -0.3, 0), 40.0)
		await _grab("desk_side")
		await _look(Vector3(0.05, 1.25, edge.z - 0.6), head + Vector3(0, -0.12, 0), 30.0)
		await _grab("desk_close")
	if _want("door") and _has("him_stand"):
		_new_set()
		var M: Dictionary = main.pub.M
		_room(3.0)
		# the office wall he's standing in the doorway of, the hall behind him lit from along it
		main.pub.tiled(Vector3(2.0, 2.9, 0.15), Vector3(-1.5, 1.45, 0.12), M.wall, 2.0, set_node)
		main.pub.tiled(Vector3(2.0, 2.9, 0.15), Vector3(1.5, 1.45, 0.12), M.wall, 2.0, set_node)
		_box(Vector3(1.0, 0.75, 0.15), Vector3(0, 2.525, 0.12), M.wall)
		for x in [-0.5, 0.5]:
			_box(Vector3(0.07, 2.16, 0.19), Vector3(x, 1.08, 0.12), M.wood)
		_box(Vector3(1.07, 0.07, 0.19), Vector3(0, 2.16, 0.12), M.wood)
		_figure("him_stand")
		var head := _anchor("him_stand", "head", Vector3(0, 1.8, 0))
		_light(Vector3(0.3, 2.6, -1.6), Color("f3ead8"), 1.0, 6.0)
		_light(Vector3(1.2, 1.1, -2.6), Look.LAMP, 0.6, 3.0)
		_light(Vector3(-0.8, 2.5, 1.6), Color("f3ead8"), 0.8, 4.0)
		await _look(Vector3(0.2, 1.17, -3.3), head + Vector3(0, -0.45, 0))
		await _grab("door_from_desk")
		await _look(Vector3(-0.45, 1.5, -1.6), head + Vector3(0, -0.15, 0), 34.0)
		await _grab("door_close")
	if _want("card") and _has("him_card"):
		_new_set()
		_room(2.0)
		_figure("him_card")
		var head := _anchor("him_card", "head", Vector3(0, 1.8, 0))
		_light(Vector3(0.6, 2.6, -1.4), Color("f3ead8"), 1.1, 6.0)
		await _look(Vector3(0.0, 1.5, -2.6), head + Vector3(0, -0.6, 0))
		await _grab("card_figure")
		await _look(Vector3(0.5, 1.75, -1.1), head, 30.0)
		await _grab("card_head")
		# the licence photo, as props.gd takes it
		var sv: SubViewport = main.props._portrait("him_card")
		if sv != null:
			sv.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			sv.get_texture().get_image().save_png(out.path_join("card_photo.png"))
			print("shot card_photo")
			sv.queue_free()
	if _want("books") and _has("bookkeeper_desk"):
		_new_set()
		var M: Dictionary = main.pub.M
		_room(1.6)
		var seat := _anchor("bookkeeper_desk", "seat", Vector3(0, 0.46, 0))
		var front := _anchor("bookkeeper_desk", "seat_front", seat + Vector3(0, 0, -0.25))
		var edge := _anchor("bookkeeper_desk", "desk_edge", Vector3(0, 0.74, -0.3))
		# her desk square to the wall, her chair turned out from it a little toward the room
		_box(Vector3(1.3, 0.035, 0.7), Vector3(0, edge.y - 0.0175, edge.z - 0.35), M.top)
		for x in [-0.62, 0.62]:
			_box(Vector3(0.035, edge.y - 0.035, 0.66), Vector3(x, (edge.y - 0.035) / 2.0, edge.z - 0.35), M.wood)
		var chair := Node3D.new()
		set_node.add_child(chair)
		chair.position = Vector3(seat.x, 0, seat.z)
		chair.rotation.y = atan2(seat.x - front.x, seat.z - front.z)
		main.pub.box(Vector3(0.48, 0.06, 0.46), Vector3(0, seat.y - 0.03, 0.02), M.dark, 0.0, chair)
		main.pub.box(Vector3(0.46, 0.5, 0.05), Vector3(0, seat.y + 0.32, 0.27), M.dark, 0.0, chair)
		main.pub.box(Vector3(0.06, seat.y - 0.06, 0.06), Vector3(0, (seat.y - 0.06) / 2.0, 0), M.steel, 0.0, chair)
		_figure("bookkeeper_desk")
		var head := _anchor("bookkeeper_desk", "head", Vector3(0, 1.2, 0))
		_light(Vector3(-0.45, edge.y + 0.45, edge.z - 0.25), Look.LAMP, 1.0, 2.4)
		_light(Vector3(0.9, 2.5, 0.2), Color("f3ead8"), 1.8, 6.0)
		# from the room on her right, where she's turned to (not so wide that the town comes into
		# view, its lamps crowding hers out); then at her side, over the ledger
		await _look(Vector3(2.0, 1.62, 0.9), head + Vector3(0, -0.25, 0), 34.0)
		await _grab("books_room")
		await _look(Vector3(0.95, 1.45, -0.6), head + Vector3(0, -0.2, -0.08), 34.0)
		await _grab("books_close")
	if _want("kid") and _has("essokid_freezer"):
		_new_set()
		var M: Dictionary = main.pub.M
		main.pub.tiled(Vector3(10, 0.1, 10), Vector3(0, -0.05, 0), M.gravel, 2.0, set_node)
		main.pub.tiled(Vector3(10, 3.6, 0.2), Vector3(0, 1.8, 0.85), M.plain, 2.0, set_node)
		var lid := _anchor("essokid_freezer", "seat", Vector3(0, 0.86, 0.4))
		var front := _anchor("essokid_freezer", "seat_front", Vector3(lid.x, lid.y, 0.0))
		# the chest freezer against the wall, him on its lid with his heels against its front
		_box(Vector3(1.3, lid.y, 0.72), Vector3(lid.x, lid.y / 2.0, front.z + 0.36), M.steel)
		_figure("essokid_freezer")
		var head := _anchor("essokid_freezer", "head", Vector3(0, 1.6, 0))
		# the canopy's lights out front, bright and high over him, and the shop window's
		_light(Vector3(0.6, 3.6, -1.8), Color("e4ecf4"), 2.0, 8.0)
		_light(Vector3(-1.8, 1.4, -0.4), Color("e9f0f4"), 0.5, 3.0, false)
		# from across the lot, then standing over him, his face turned up past us
		await _look(Vector3(1.2, 1.8, -3.8), head + Vector3(0, -0.45, 0))
		await _grab("kid_lot")
		await _look(Vector3(0.5, 1.8, -1.3), head + Vector3(0, -0.12, 0), 34.0)
		await _grab("kid_close")
	if _want("wharf") and _has("endbar_wharf"):
		_new_set()
		var M: Dictionary = main.pub.M
		main.pub.tiled(Vector3(8, 0.1, 4), Vector3(0, -0.05, 1.4), M.boards, 2.0, set_node)
		var rail := _anchor("endbar_wharf", "rail", Vector3(0, 1.0, -0.4))
		# the rail along the wharf's edge, the water dark below and away
		_box(Vector3(6, 0.06, 0.08), Vector3(0, rail.y - 0.03, rail.z - 0.02), M.wood)
		for x in [-2.4, -1.2, 0.0, 1.2, 2.4]:
			_box(Vector3(0.09, rail.y, 0.09), Vector3(x + 0.6, rail.y / 2.0, rail.z - 0.02), M.wood)
		_box(Vector3(40, 0.05, 40), Vector3(0, -1.4, rail.z - 20.1), M.black)
		_figure("endbar_wharf")
		var head := _anchor("endbar_wharf", "head", Vector3(0, 1.6, 0))
		_light(Vector3(1.6, 4.0, 1.2), Look.LAMP, 1.6, 9.0)
		await _look(Vector3(1.9, 1.6, 2.6), head + Vector3(0, -0.4, 0))
		await _grab("wharf_behind")
		await _look(Vector3(2.2, 1.45, -0.9), head + Vector3(0, -0.25, 0), 40.0)
		await _grab("wharf_side")
	if _want("hands"):
		await _hands()
	quit()


# ---------------------------------------------------------------- Gary's hands

# a stand-in for the licence's face: the card's ground, its band, the photo's place, and the name a
# block of ink where it's printed, to see whether any of it shows past his thumb
func _face_tex() -> ImageTexture:
	var img := Image.create(856, 540, false, Image.FORMAT_RGBA8)
	img.fill(Color("d9e0e3"))
	img.fill_rect(Rect2i(0, 0, 856, 74), Color("2d4868"))
	img.fill_rect(Rect2i(32, 98, 238, 300), Color("bfc6cb"))
	for k in 4:
		img.fill_rect(Rect2i(300, 380 + k * 32, 300 - k * 40, 12), Color("8a929a"))
	img.fill_rect(Rect2i(roundi(NAME.position.x * 856), roundi(NAME.position.y * 540), roundi(NAME.size.x * 856), roundi(NAME.size.y * 540)),
		Color("101418"))
	return ImageTexture.create_from_image(img)


func _screen_tex() -> ImageTexture:
	var img := Image.create(330, 710, false, Image.FORMAT_RGBA8)
	img.fill(Color("dfe6ee"))
	img.fill_rect(Rect2i(20, 120, 290, 200), Color("7d8894"))
	img.fill_rect(Rect2i(20, 360, 200, 24), Color("38404a"))
	return ImageTexture.create_from_image(img)


func _held(kind: String, pose: String, model: String) -> Node3D:
	var node := Node3D.new()
	main.view.hands.add_child(node)
	var body := Node3D.new()
	node.add_child(body)
	if kind == "card":
		var f: MeshInstance3D = main.props._quad(Props.CARD, main.props._surface(_face_tex()), body)
		f.position.z = 0.0004
		var b: MeshInstance3D = main.props._quad(Props.CARD, main.props._surface(null), body)
		b.rotation.y = PI
		b.position.z = -0.0004
	else:
		main.props._box(Vector3(0.074, 0.152, 0.008), Vector3(0, 0, -0.0045), main.pub.mat(Color("141417"), 0.35, 0.2, 5), body)
		main.props._quad(Vector2(0.066, 0.142), main.props._surface(_screen_tex()), body)
	main.props._right_hand(body, model, kind)
	var pos := Vector3.ZERO
	var rot := Vector3.ZERO
	if kind + ":" + pose in POSES:
		pos = POSES[kind + ":" + pose][0]
		rot = POSES[kind + ":" + pose][1]
	else:
		pos = _beside_face()
	node.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))), pos)
	return node


# props.gd's _beside_face, for him across the desk
func _beside_face() -> Vector3:
	var cam: Camera3D = main.view.cam
	var head := set_node.to_global(_anchor("him_desk", "head", Vector3(0, 1.3, 0)))
	var local := cam.global_transform.affine_inverse() * head
	return local.normalized() * 0.26 + Vector3(-0.07 if local.x > 0.0 else 0.07, 0.0, 0.0)


func _hands() -> void:
	_new_set()
	var edge := _office("him_desk")
	if FileAccess.file_exists(PEOPLE + "him_desk.glb"):
		_figure("him_desk")
	var head := _anchor("him_desk", "head", Vector3(0, 1.3, 0))
	await _look(Vector3(0.06, 1.17, edge.z - 1.15), head + Vector3(0, -0.2, 0))
	for shot in [["card", "rest", "gary_right_card"], ["card", "look", "gary_right_card"], ["phone", "rest", "gary_right_phone"],
			["phone", "look", "gary_right_phone"]]:
		if not _has(shot[2]):
			continue
		var n := _held(shot[0], shot[1], shot[2])
		await _frames(20)
		await _grab("hands_%s_%s" % [shot[0], shot[1]])
		if shot[0] == "card" and shot[1] == "rest":
			# the same, closer: the thumb over the name
			main.view.focus_fov = 24.0
			var a: Vector2 = Posts.aim(main.view.eye_pos, n.global_position)
			main.view.yaw = a.x
			main.view.pitch = a.y
			main.view.want_yaw = a.x
			main.view.want_pitch = a.y
			await _frames(30)
			await _grab("hands_card_thumb")
			# and as it would print with its new materials given a cut in pub.gd's CUTS
			var was := {}
			for k in NEW_CUTS:
				var m = main.pub.from_model_cache.get(k)
				if m is ShaderMaterial:
					was[k] = [m.get_shader_parameter("cut"), m.get_shader_parameter("cut_dir"), m.get_shader_parameter("cut_px"),
						m.get_shader_parameter("lines")]
					var c: Array = NEW_CUTS[k]
					m.set_shader_parameter("cut", c[0])
					m.set_shader_parameter("cut_dir", c[1])
					m.set_shader_parameter("cut_px", c[2])
					m.set_shader_parameter("lines", c[3])
			await _frames(10)
			await _grab("hands_card_thumb_cuts")
			for k in was:
				var m: ShaderMaterial = main.pub.from_model_cache[k]
				m.set_shader_parameter("cut", was[k][0])
				m.set_shader_parameter("cut_dir", was[k][1])
				m.set_shader_parameter("cut_px", was[k][2])
				m.set_shader_parameter("lines", was[k][3])
			await _look(Vector3(0.06, 1.17, edge.z - 1.15), head + Vector3(0, -0.2, 0))
		n.free()
		await _frames(2)
