extends "res://tests/shots_people_m1.gd"
# Every model's head from the front and three-quarters, close, in the print (the walkers too).

const ALL := ["hoodie_door", "hoodie_lot", "team_jacket", "hearing_aid", "scratch", "cardigan", "glasses", "bigman", "buddy",
	"bartender", "hivis", "endbar", "crew_a", "crew_b", "driver", "vape", "slippers", "cook", "goodshoes_card", "goodshoes_bar",
	"raincoat", "patron_a", "patron_b", "patron_c", "patron_d", "patron_e", "patron_f", "driver_door", "driver_rail", "vape_door",
	"vape_bar", "hoodie_juke", "hivis_door", "slippers_a", "slippers_b", "constable", "terry", "him_desk", "him_stand", "him_card",
	"ballcap_card", "ballcap_cap", "bookkeeper_desk", "essokid_freezer", "endbar_wharf",
	"hoodie_walk", "driver_walk", "vape_walk", "goodshoes_walk", "hivis_walk", "raincoat_walk", "constable_walk", "bigman_walk",
	"glasses_walk", "buddy_walk"]

func _run() -> void:
	await _frames(5)
	main.menus.hide_all()
	main.settings["skin"] = false
	main.pub.shadows_near(AT)
	for model in ALL:
		if not only.is_empty() and not only.has(model):
			continue
		if not _has(model):
			continue
		_new_set()
		_room(3.0)
		_figure(model)
		var head := _anchor(model, "head", Vector3(0, 1.6, 0))
		_light(head + Vector3(-0.9, 0.7, -1.4), Color("f3ead8"), 1.2, 6.0)
		_light(head + Vector3(1.2, 0.2, -1.0), Look.LAMP, 0.5, 4.0)
		_light(head + Vector3(0.0, 1.5, 0.8), Color("f3ead8"), 0.6, 4.0)
		await _look(head + Vector3(0.0, 0.02, -1.25), head + Vector3(0, -0.03, 0), 22.0)
		await _grab("face_" + model + "_a")
		await _look(head + Vector3(0.85, 0.05, -0.95), head + Vector3(0, -0.03, 0), 22.0)
		await _grab("face_" + model + "_b")
	quit()
