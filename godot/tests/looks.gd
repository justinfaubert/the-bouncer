extends SceneTree
# What the things he can look at say (content/data/things.yaml, content/ink/things.ink): looks at
# each one twice, from each place it can be looked at from (the room's things from the floor), and
# prints what comes back, voices and all, for reading through. Counts a look that says nothing, and
# one with a dash, an ellipsis or a curly quote in it, which the game's text doesn't use.
#   godot --headless --path godot -s res://tests/looks.gd

var main
var bad := 0
var said := 0
const WHERE := ["floor", "door", "bar", "t28", "pool", "hall", "kitchen", "keg", "deck", "lot", "upstairs"]
# a part of the building, to a place he can be in it
const IN := {"room": "floor", "vest": "door", "hall": "hall", "lobby": "hall", "kitchen": "kitchen", "keg": "keg",
	"deck": "deck", "lot": "lot", "upstairs": "upstairs"}


func _init() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for k in n:
		await process_frame


# where the Ink thinks he is
func _put(place: String) -> void:
	var l := Ink.InkList.from_origin("where", main.game.story)
	l.add(Ink.InkListItem.new("where", place), WHERE.find(place) + 1)
	main.game.set_var("here", l)


func _places(id: String) -> Array:
	var t: Dictionary = main.spots.things[id]
	var out: Array = []
	for f in t.get("from", []):
		var p := "floor" if f == "room" else str(f)
		if not p in out:
			out.append(p)
	if out.is_empty():
		var at := str(t.get("at", ""))
		var w: Array = main.spots._where(at)
		out.append(IN.get(Hotspots.zone_of(w[0]), "floor") if not w.is_empty() else "floor")
	return out


func _run() -> void:
	await _frames(5)
	main.start_new(3)
	await _frames(5)
	var odd := RegEx.create_from_string("[–—…‘’“”]|\\.\\.\\.")
	for id in main.spots.things:
		for place in _places(str(id)):
			_put(place)
			for k in 2:
				var res: Dictionary = main.game.toy(str(id), "look")
				var lines: Array = []
				for it in res.get("items", []):
					var who := str(it.get("speaker", "")) if it.get("role", "") == "voice" else ""
					lines.append((who.to_upper() + ": " if who != "" else "") + str(it.get("text", "")))
				var text := " / ".join(lines)
				said += 1
				print("  %-11s %-8s %d  %s" % [id, place, k + 1, text])
				if text.strip_edges() == "":
					bad += 1
					print("    ^ says nothing")
				elif odd.search(text) != null:
					bad += 1
					print("    ^ a dash, an ellipsis or a curly quote")
	print("== %d looks, %d wrong" % [said, bad])
	main.back_to_title()
	await _frames(2)
	main.store.clear(3)
	main.store.settings["slot"] = 1
	main.store.save_settings()
	quit(1 if bad > 0 else 0)
