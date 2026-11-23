extends "res://tests/shots.gd"
# The shadows, place by place: which lamps throw one from where he stands (and what kind, how far,
# its biases), and his eyes' own picture before the press, for checking contact shadows (feet,
# hands on the bar, glasses on the tables), acne, and light through walls. Needs a display:
#   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" godot \
#     --rendering-driver vulkan --resolution 1280x720 --path godot -s res://tests/shadows.gd -- \
#     --out /tmp/shadows [--posts floor,bar] [--clock 1290] [--list]

var clock := 1290
var list := false


func _run() -> void:
	posts = ["door", "floor", "bar", "t28", "pool", "hall", "kitchen", "deck", "lot", "upstairs"]
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		match args[k]:
			"--clock": clock = int(args[k + 1])
			"--posts": posts = Array(args[k + 1].split(","))
			"--list": list = true
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(20)
	main.game.set_var("clock", clock)
	print("atlas ", main.view.eye.positional_shadow_atlas_size, " quadrants ",
		[main.view.eye.positional_shadow_atlas_quad_0, main.view.eye.positional_shadow_atlas_quad_1,
		main.view.eye.positional_shadow_atlas_quad_2, main.view.eye.positional_shadow_atlas_quad_3])
	for p in posts:
		main.view.frame = ""
		main.view.jump_to(p)
		main.stage.sync(main.game, true)
		main.stage._settle(0.0)
		main.view.daylight(clock, true)
		main.pub.set_clock(clock)
		await _frames(25)
		var on := 0
		var lines := []
		for l in main.pub.find_children("*", "Light3D", true, false):
			var li := l as Light3D
			if not li.visible or li.light_energy <= 0.0:
				continue
			var r := (li as OmniLight3D).omni_range if li is OmniLight3D else ((li as SpotLight3D).spot_range if li is SpotLight3D else 0.0)
			if li.shadow_enabled:
				on += 1
			lines.append("  %s %-5s %5.1fm away, range %4.1f, e %.2f, shadow %s bias %.3f nb %.2f" % [
				li.name.left(14), "omni" if li is OmniLight3D else ("spot" if li is SpotLight3D else "dir"),
				li.global_position.distance_to(main.view.eye_pos), r, li.light_energy, li.shadow_enabled,
				li.shadow_bias, li.shadow_normal_bias])
		print("%s: %d lamps lit, %d with shadows" % [p, lines.size(), on])
		if list:
			for s in lines:
				print(s)
		main.view.eye.get_texture().get_image().save_png(out.path_join("%s_raw.png" % p))
		await _grab(p)
	main.store.clear(2)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit()
