extends SceneTree
# The set dressing (world/dressing.gd, world/glasswasher.gd), headless:
#  - every picture it puts up is there and loads;
#  - every thing in content/data/things.yaml it answers for has its anchor;
#  - nothing of it is in anything else: each paper, sign, glass and the glasswasher's box against
#    every other mesh in the building (but the wall it's on and the floor it's on): their boxes
#    mustn't cross;
#  - the glasswasher: running, a rack of empties goes in, comes out clean and sits at the end; nobody
#    looking, it's taken off and the next rack goes on; switched off, the belt stops where it is;
#    left off long enough with nobody looking, the bartender switches it back on; looked at, never.
#   godot --headless --path godot -s res://tests/dressing.gd

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var pub := Pub.new()
	root.add_child(pub)
	pub.build()
	var d := pub.dressing
	check(d != null and d.washer != null, "the dressing and the glasswasher are built")
	# the pictures
	var dir := DirAccess.open("res://textures")
	var n := 0
	for f in dir.get_files():
		if f.begins_with("dress_") and f.ends_with(".png"):
			var t := pub.tex("res://textures/" + f)
			check(t != null and t.get_width() > 4, "picture " + f)
			n += 1
	check(n >= 25, "%d pictures" % n)
	# the things' anchors
	var yaml := FileAccess.get_file_as_string("res://../content/data/things.yaml")
	var sect := yaml.get_slice("the set dressing", 1).get_slice("# ------", 0)
	for line in sect.split("\n"):
		var m := line.find("at: a:")
		if m < 0:
			continue
		var anchor := line.substr(m + 6).get_slice(",", 0).get_slice("}", 0).strip_edges()
		check(pub.anchors.has(anchor), "anchor " + anchor)
	# nothing in anything
	var mine: Array = []
	for mi in d.find_children("*", "MeshInstance3D", true, false):
		if (mi as Node).get_parent().name == "belt" or "trash" in str((mi as Node).get_path()) or "esso" in str((mi as Node).get_path()):
			continue
		mine.append(mi)
	var others: Array = []
	for mi in pub.find_children("*", "MeshInstance3D", true, false):
		if d.is_ancestor_of(mi) or (pub.town != null and pub.town.is_ancestor_of(mi)):
			continue
		var bb := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		# the walls, floors and ceilings: big and flat; the papers sit off them by design
		if bb.size.x > 1.5 or bb.size.z > 1.5 or bb.size.y > 2.6:
			continue
		others.append([mi, bb])
	var clashes := 0
	for a in mine:
		var ba := (a as MeshInstance3D).global_transform * (a as MeshInstance3D).get_aabb()
		# a hair in from each side, where it's thick enough to have one (they're built touching)
		var sh := Vector3(minf(0.002, ba.size.x * 0.25), minf(0.002, ba.size.y * 0.25), minf(0.002, ba.size.z * 0.25))
		ba = AABB(ba.position + sh, ba.size - sh * 2.0)
		for o in others:
			if ba.intersects(o[1]):
				# the back bar under the glasswasher and the glasses on it are meant to touch it
				var on: String = str((o[0] as Node).get_path())
				print("      ", (a as Node).get_path(), " in ", on, " ", (o[0] as MeshInstance3D).mesh.get_class(), " ", o[1].size, " at ", ba.get_center())
				clashes += 1
	check(clashes == 0, "nothing of the dressing in anything else (%d)" % clashes)
	# the glasswasher
	var w := d.washer
	w.set_process(false)
	d.set_process(false)
	check(w.on, "it's running when the night starts")
	var load: Dictionary = w.racks[0]
	var done: Dictionary = w.racks[1]
	check(not load.clean and done.clean, "empties waiting at the start, a clean rack at the end")
	# watched: nothing's taken off, so the empties stop behind the clean rack, in the spray
	for i in 600:
		w.tick(0.05, true)
	check(not done.hidden, "watched, nobody takes the clean rack off")
	check(absf(float(load.z) - (Glasswasher.OUT_Z - Glasswasher.RACK - 0.01)) < 0.02, "the empties wait behind it (z %.2f)" % float(load.z))
	# not watched: the clean one's taken, the empties go through and come out clean
	for i in 800:
		w.tick(0.05, false)
	check(load.clean, "the empties came out clean")
	check(w.loads >= 2 and w.washed >= 2, "the clean racks taken off, and more empties put on and washed (%d on, %d washed)" % [w.loads, w.washed])
	# off: the belt stops
	var zs := []
	for rk in w.racks:
		zs.append(float(rk.z))
	w.flip()
	check(not w.on and w.flips == 1, "switched off")
	for i in 200:
		w.tick(0.05, true)
	var still := true
	for k in w.racks.size():
		still = still and absf(float(w.racks[k].z) - float(zs[k])) < 0.001
	check(still, "off, nothing on the belt moves")
	# watched, the bartender leaves it off; not watched, puts it back on
	var by := [false]
	w.flipped.connect(func(on, jim): by[0] = jim and on)
	for i in int(Glasswasher.JIM_AFTER / 0.5) + 10:
		w.tick(0.5, true)
	check(not w.on, "watched, nobody switches it back on")
	for i in 4:
		w.tick(0.5, false)
	check(w.on and by[0], "not watched, the bartender switches it back on")
	print("\n%s: %d failed" % ["dressing", fails])
	quit(1 if fails > 0 else 0)
