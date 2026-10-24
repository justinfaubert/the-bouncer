extends "res://tests/shots_people_m1.gd"
# Colours for what people wear, tried out: a board of them, each on a cylinder the size of a
# torso, cut the way a jacket is, under the bar's table lamp, the pool table's, the back hall's
# tubes and the deck's LED, printed. For picking pub.gd's WEARS. Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_swatches.gd -- --out /tmp/swatches [--colours 6a2e1c,b08a2c,...]
# (up to 32 colours, eight to a row; the default board is below)

var colours: Array = [
	"6a2e1c", "7a3a22", "8c4a22", "5a3424", "74361e", "6e4a2e", "5c3a2a", "804c30",
	"b08a2c", "9a7a2a", "c0a66a", "8a6c3c", "6e5a2c", "8c7c46", "a08040", "c09030",
	"2f6a66", "23493a", "3b4d38", "3a5a48", "2a6a5a", "1f5a4a", "4a7a5a", "3c6e78",
	"b6f03c", "9ccc30", "c8e040", "1f2a44", "2d3a5a", "4c6470", "4c4a5a", "dcd8ce"]
const LIGHTS := {"lamp": ["ffb865", 0.9], "pool": ["fff0d6", 1.0], "tube": [Pub.TUBE_LIGHT, 0.8], "led": ["c4e2ee", 0.8]}


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for k in args.size():
		if args[k] == "--colours":
			colours = Array(args[k + 1].split(","))
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false
	main.pub.shadows_near(AT)
	for which in LIGHTS:
		_new_set()
		_room(2.0)
		for i in colours.size():
			var m: ShaderMaterial = main.pub.mat(Color(str(colours[i])), 0.9, 0.0, 4, Vector3.UP, 5.5, 0.8)
			var x := (3.5 - (i % 8)) * 0.42
			var y := 1.75 - (i / 8) * 0.42
			var c: MeshInstance3D = main.pub.cyl(0.15, 0.15, 0.34, Vector3(x, y, 0), m, set_node)
			c.set_layer_mask_value(Pub.PEOPLE_LAYER, true)
		var l: Array = LIGHTS[which]
		for x in [-1.2, 0.0, 1.2]:
			_light(Vector3(x, 2.6, -0.4), Color(str(l[0])), float(l[1]), 3.6)
		_light(Vector3(0, 2.6, -3.0), Color("e8b87a") if which == "lamp" else Color(str(l[0])), 0.35, 7.0, false)
		await _look(Vector3(0, 1.1, -3.0), Vector3(0, 1.1, 0), 50.0)
		await _grab("swatches_" + which)
	quit()
