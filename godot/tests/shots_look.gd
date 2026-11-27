extends "res://tests/shots.gd"
# The look menu over a night, with whatever look the settings start with (night stock by default),
# and the same place with the menu closed:
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver vulkan --resolution 1920x1080 \
#     --path godot -s res://tests/shots_look.gd -- --out /tmp/look [--posts t28]


func _run() -> void:
	for k in range(1, Store.SLOTS + 1):
		main.store.clear(k)
	main.settings["dice"] = "still"
	main.start_new(2)
	await _frames(20)
	main.game.set_var("clock", 1290)
	var p: String = posts[0] if posts.size() < 5 else "t28"
	main.view.frame = ""
	main.view.jump_to(p)
	main.stage.sync(main.game, true)
	main.stage._settle(0.0)
	main.view.daylight(1290, true)
	main.pub.set_clock(1290)
	await _frames(25)
	print("look setting: ", main.settings.get("look"))
	await _grab("look_" + p)
	main.menus.look_menu("pause")
	await _frames(10)
	await _grab("look_menu_" + p)
	main.store.clear(2)
	quit()
