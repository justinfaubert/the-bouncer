extends SceneTree
# The arm's instinct (game/darts.gd release_state): with no shake and the usual draw, a throw lands
# where his eyes are for a sound standard dart, and each house dart misses its own way (the bent
# one, the torn one, the heavy one). Prints where each crossed the board's face.
#   xvfb-run -a godot --rendering-driver opengl3 --path godot -s res://tests/darts_aim.gd
var main
func _init():
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()
func _run():
	for k in 5: await process_frame
	main.start_darts("practice", "rehearse", {})
	for k in 5: await process_frame
	var d = main.darts
	d.shake_off = true
	for tgt in [Vector3(0, 0, 0), Vector3(0, 0.103, 0), Vector3(-0.1, -0.05, 0)]:
		var a := Posts.aim(main.view.eye_pos, d.to_world * tgt)
		d.aim_yaw = a.x; d.aim_pitch = a.y
		main.view.yaw = a.x; main.view.pitch = a.y
		for i in 3:
			d.draw = 0.5
			var st: Dictionary = d.release_state(i, 0.0)
			d._collect(true)
			d.sim.throw(d.bodies[i], st.at, st.v, st.rot, st.spin)
			d.sim.run()
			var c = d.bodies[i].crossed
			print("target ", tgt, " got target ", st.target, " dart ", d.bodies[i].d.name, " crossed ", c, " v ", st.v.length())
	quit()
