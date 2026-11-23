extends SceneTree
# A sheet of the voices' masks (game/voice_mask.gd): each at rest and talking, on the night ink.
#   xvfb-run -a -s "-screen 0 1600x700x24" godot --rendering-driver opengl3 --resolution 1600x700 \
#     --path godot -s res://tests/shots_voice_masks.gd -- --out /tmp/masks.png

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := "/tmp/masks.png"
	if args.size() >= 2 and args[0] == "--out":
		out = args[1]
	Look.load_fonts()
	var bg := ColorRect.new()
	bg.color = Look.NIGHT
	bg.size = Vector2(1600, 700)
	root.add_child(bg)
	var styles := ["father", "fighter", "manual", "wrongman", "table", "kid", "till", "senior"]
	for i in styles.size():
		for row in 2:
			var m := VoiceMask.new(styles[i], 150)
			m.position = Vector2(30 + i * 195, 40 + row * 320)
			m.size = Vector2(160, 184)
			if row == 1:
				m.talk = 1.0
				m.lean = 1.0
				m._retell = 1
			m.still = true
			root.add_child(m)
		var l := UiBits.label(Look.voice(styles[i]).font + "  " + styles[i].to_upper(), "ui_b", 16, Look.voice_color(styles[i]), 2)
		l.position = Vector2(40 + i * 195, 250)
		root.add_child(l)
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
