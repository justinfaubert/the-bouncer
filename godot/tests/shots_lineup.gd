extends "res://tests/shots_people_m1.gd"
# Everyone in a row, six at a time, under a lamp like the ones over the bar's tables and the room's
# own dim light: to see that each wears a colour of their own and how the press prints it
# (pub.gd's WEARS). Needs a display (xvfb-run):
#   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1280x720 \
#     --path godot -s res://tests/shots_lineup.gd -- --out /tmp/lineup [--only hoodie_door,driver]

const ROWS := [
	["hoodie_door", "driver_door", "vape_door", "ballcap_cap", "essokid_freezer", "constable"],
	["team_jacket", "hearing_aid", "scratch", "cardigan", "glasses", "endbar"],
	["bigman", "buddy", "crew_a", "crew_b", "hivis", "goodshoes_bar"],
	["raincoat", "slippers_a", "slippers_b", "terry", "cook", "bartender"],
	["patron_a", "patron_b", "patron_c", "patron_d", "patron_e", "patron_f"],
]


func _run() -> void:
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false
	main.pub.shadows_near(AT)
	for r in ROWS.size():
		var row: Array = ROWS[r].filter(func(m): return (only.is_empty() or only.has(m)) and _has(m))
		if row.is_empty():
			continue
		_new_set()
		_room(2.5)
		for i in row.size():
			var x := (i - (row.size() - 1) / 2.0) * 0.95
			_figure(row[i], Vector3(x, 0, 0))
		# a table lamp's warm pool over the row, the way the bar's pendants light whoever's under one,
		# and the room's own low light
		for x in [-1.9, 0.0, 1.9]:
			_light(Vector3(x, 2.2, -0.2), Color("ffb865"), 1.6, 3.6)
		_light(Vector3(0, 2.6, -3.0), Color("e8b87a"), 0.35, 7.0, false)
		await _look(Vector3(0, 1.45, -4.2), Vector3(0, 1.05, 0), 58.0)
		await _grab("lineup_%d" % r)
		await _look(Vector3(0, 1.55, -2.2), Vector3(0, 1.45, 0), 58.0)
		await _grab("lineup_%d_close" % r)
	quit()
