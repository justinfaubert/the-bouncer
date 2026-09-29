# The people in the Sov, where the night has put them.
#
# Who is where comes from the Ink's state (who's been let in, who's been put out, who's come down
# from upstairs, the clock), worked out fresh after every batch in `_cast`. The room keeps to it the
# way a room does: people move while he isn't looking. A change waits until the place it's in is
# out of his sight (behind him, through a wall, off the edge of his eyes); if it can't wait (he's
# staring at the kid while the kid walks up to the door) his eyes close for a blink and it's done.
# And the room lives between glances on its own: the bartender works along the bar, the buddy goes
# round the table, Slippers drifts between the jukebox and the bar.
#
# The people are sculpted and posed in tools/people.py (sketches/door-look), one model per pose;
# where their heads and hands and phones are is written beside each model in a .json.
class_name Stage
extends Node3D

const PEOPLE := "res://models/people/"
const BLINK_AFTER := 1.1           # seconds a change waits in his sight before he blinks

# where a figure can be: the spot, the way it faces, the part of the building it's in (what he can
# see from each post is SEEN), and anything that's put in the truck's frame instead of the world's
var SPOTS := {}
const SEEN := {
	"door": ["vest", "room", "lot", "truck"],
	"floor": ["vest", "room", "lot"], "bar": ["vest", "room"], "t28": ["vest", "room", "lot", "truck"], "pool": ["room", "vest"],
	"hall": ["hall", "room"], "kitchen": ["kitchen"], "keg": ["keg"], "deck": ["deck", "lot"],
	"lot": ["lot", "truck", "vest", "room"], "upstairs": ["upstairs", "lot", "truck"],
}
# the ones who drift on their own between glances, and where to
const WANDER := {
	"bartender": ["bar_back_mid", "bar_back_till", "bar_back_far", "bar_back_mid"],
	"buddy": ["pool_buddy", "pool_buddy_b", "pool_buddy_c"],
	"slippers": ["juke", "juke", "bar_s6_stand"],
	"bigman": ["pool_cue", "pool_cue_b"],
}
# who speaks for a speaker the Ink names that isn't one figure
const SPEAKS_FOR := {"table28": "team_jacket", "kid": "hoodie", "sister": "driver", "wife": "raincoat", "rats": "endbar"}

var pub: Pub
var content: Dictionary
var view: View
var figures := {}                  # id -> {"node": Node3D, "spot": String, "model": String, "anchors": Dictionary}
var want := {}                     # id -> [spot, model], or [] for gone
var waiting := {}                  # id -> seconds the change has waited in his sight
var things := {}                   # changes to the room that aren't people: key -> [pos, zone, Callable, value]
var wander_at := {}                # id -> when it next drifts
var t := 0.0
var _check := 0.0
var _blinking := false
var _turned := {}                  # id -> the tween turning them toward him
var _anchors := {}


func setup(p: Pub, c: Dictionary) -> void:
	pub = p
	content = c
	_spots()


func _spots() -> void:
	var T28 := Pub.T28
	var POOL := Pub.POOL
	var eye := Posts.POSTS["door"].at
	var s := {}
	# table 28's six stools, round from the window side
	for k in 6:
		var a := TAU * k / 6.0 + 0.25
		s["t28_%d" % k] = {"pos": T28 + Vector3(cos(a) * 1.18, 0, sin(a) * 1.18), "face": T28, "zone": "room"}
	s["t28_stand"] = {"pos": T28 + Vector3(-1.35, 0, -1.25), "face": T28, "zone": "room"}
	# the bar: behind it, and its stools from the far end to the door end
	s["bar_back_mid"] = {"pos": Vector3(1.15, 0, 4.8), "face": Vector3(6.0, 0, 4.8), "zone": "room"}
	s["bar_back_till"] = {"pos": Vector3(1.15, 0, 6.7), "face": Vector3(6.0, 0, 7.4), "zone": "room"}
	s["bar_back_far"] = {"pos": Vector3(1.15, 0, 2.6), "face": Vector3(6.0, 0, 2.2), "zone": "room"}
	for i in 7:
		var z := 1.6 + i * 0.85
		s["bar_s%d" % i] = {"pos": Vector3(2.65, 0, z), "face": Vector3(0.0, 0, z), "zone": "room"}
	s["bar_s6_stand"] = {"pos": Vector3(3.05, 0, 6.3), "face": Vector3(0.0, 0, 6.0), "zone": "room"}
	# the pool table
	s["pool_cue"] = {"pos": POOL + Vector3(1.8, 0, 1.0), "face": POOL, "zone": "room"}
	s["pool_cue_b"] = {"pos": POOL + Vector3(-1.75, 0, -0.9), "face": POOL, "zone": "room"}
	s["pool_buddy"] = {"pos": POOL + Vector3(-1.0, 0, -1.35), "face": POOL, "zone": "room"}
	s["pool_buddy_b"] = {"pos": POOL + Vector3(0.4, 0, 1.55), "face": POOL, "zone": "room"}
	s["pool_buddy_c"] = {"pos": POOL + Vector3(2.0, 0, -0.6), "face": POOL, "zone": "room"}
	s["pool_watch"] = {"pos": POOL + Vector3(-0.8, 0, 2.2), "face": POOL, "zone": "room"}
	# the other tables' stools: a, b, c, d as in Pub.TABLES
	var names := ["a", "b", "c", "d"]
	for ti in Pub.TABLES.size():
		var tb: Vector3 = Pub.TABLES[ti]
		var offs := [Vector3(0.62, 0, 0), Vector3(-0.62, 0, 0), Vector3(0, 0, 0.62)]
		for j in offs.size():
			s["table_%s_%d" % [names[ti], j]] = {"pos": tb + offs[j], "face": tb, "zone": "room"}
	s["juke"] = {"pos": Vector3(13.2, 0, 1.2), "face": Vector3(13.2, 0, 0.0), "zone": "room"}
	s["juke_kid"] = {"pos": Vector3(12.7, 0, 1.15), "face": Vector3(13.2, 0, 0.0), "zone": "room"}
	s["pool_rail"] = {"pos": POOL + Vector3(-1.2, 0, 1.45), "face": POOL, "zone": "room"}
	s["bar_stand_v"] = {"pos": Vector3(2.95, 0, 4.55), "face": Vector3(0.0, 0, 4.4), "zone": "room"}
	s["vest_wait"] = {"pos": Vector3(3.85, 0, 9.35), "face": Vector3(2.0, 0, 9.0), "zone": "vest"}
	s["vest_behind"] = {"pos": Vector3(3.55, 0, 10.0), "face": eye, "zone": "vest"}
	s["vest_stand"] = {"pos": Vector3(3.3, 0, 9.7), "face": Vector3(6.0, 0, 7.0), "zone": "vest"}
	s["keg_parley"] = {"pos": Vector3(2.3, Pub.KEG_Y, -0.55), "face": Vector3(1.45, Pub.KEG_Y, 1.25), "zone": "keg", "y": -0.16}
	s["deck_chair_rail"] = {"pos": Vector3(17.8, 0, 6.6), "face": Vector3(18.4, 0, 6.6), "zone": "deck", "y": -0.29}
	# the door: in front of his stool, and out on the gravel
	# far enough back that the door's still behind them: about where anyone stops to be carded
	s["door_front"] = {"pos": Vector3(3.0, 0, 9.76), "face": eye, "zone": "vest"}
	s["door_step"] = {"pos": Vector3(3.3, 0, 11.0), "face": eye, "zone": "lot"}
	s["lot_walk"] = {"pos": Vector3(5.3, 0, 13.4), "face": Vector3(3.2, 0, 10.1), "zone": "lot"}
	s["lot_truck"] = {"pos": Vector3(7.7, 0, 14.4), "face": Vector3(3.2, 0, 10.1), "zone": "lot"}
	# the big man at the back of his own truck by the beer store, on his way round to the door
	s["work_truck"] = {"pos": Vector3(-3.0, 0, 16.75), "face": Vector3(-4.6, 0, 16.2), "zone": "lot"}
	# in the pickup: the sister at the wheel, the boyfriend across the back seat
	s["truck_wheel"] = {"pos": Vector3(-0.45, 0, -0.2), "face": Vector3.ZERO, "zone": "truck", "in": "truck"}
	s["truck_back"] = {"pos": Vector3(0.4, 0, 0.75), "face": Vector3.ZERO, "zone": "truck", "in": "truck"}
	# the back: the kitchen, the hall, the deck
	s["kitchen_fryer"] = {"pos": Vector3(1.25, 0, -1.55), "face": Vector3(0.45, 0, -2.2), "zone": "kitchen"}
	s["hall_phone"] = {"pos": Vector3(13.6, 0, -1.7), "face": Vector3(13.86, 0, -2.6), "zone": "hall"}
	s["hall_wc"] = {"pos": Vector3(11.9, 0, -0.55), "face": Vector3(11.9, 0, -1.2), "zone": "hall"}
	s["deck_rail"] = {"pos": Vector3(17.8, 0, 6.0), "face": Vector3(18.4, 0, 6.6), "zone": "deck"}
	s["deck_chair"] = {"pos": Vector3(17.3, 0, 8.2), "face": Vector3(18.4, 0, 8.2), "zone": "deck"}
	SPOTS = s


# ---------------------------------------------------------------- who's where

func _has(v: Dictionary, list: String, item: String) -> bool:
	var l = v.get(list)
	return l is Array and item in l


# Who is where, from the night so far: id -> [spot, model]. Left out: not here. This follows the
# staging spec worked out from the Ink (docs/STAGING.md); the section numbers below are its.
func _cast(game: Game, here_as := "") -> Dictionary:
	var v := game.vars()
	var clock := int(BUtil.js_int(v.get("clock", 1180)))
	var here := here_as if here_as != "" else game.here()
	var out := {}
	var fam := func(item: String) -> bool: return _has(v, "fam", item)
	var arr := func(item: String) -> bool: return _has(v, "arrivals", item)
	var cleared := func(item: String) -> bool: return _has(v, "cleared", item)
	# 1. the bartender, behind the bar all night; 10. the cook, till he goes home at eleven
	out.bartender = ["bar_back_mid", "bartender"]
	if clock < 1380:
		out.cook = ["kitchen_fryer", "cook"]
	# 2. table 28, all five, from two in the afternoon till they're cleared; Dennis goes with his wife
	if not cleared.call("cl_t28"):
		out.team_jacket = ["t28_0", "team_jacket"]
		out.hearing_aid = ["t28_1", "hearing_aid"]
		out.scratch = ["t28_2", "scratch"]
		out.cardigan = ["t28_3", "cardigan"]
		if not (arr.call("wife_told") or arr.call("wife_in") or arr.call("wife_inside")):
			out.glasses = ["t28_5", "glasses"]
		# Cardigan at the deck rail, smoking alone, while he's out there before half ten
		if here == "deck" and clock < 1350 and _visits(game, "at_deck.cardigan") == 0 and not arr.call("wife_in"):
			out.cardigan = ["deck_chair_rail", "cardigan"]
	# 3. the big man and his buddy at the pool table while the big man's still there
	var pool_still: bool = not (fam.call("dad_went") or fam.call("dad_ejected") or fam.call("lot_scene") or fam.call("dad_drove"))
	if pool_still and not cleared.call("cl_pool"):
		out.bigman = ["pool_cue", "bigman"]
		out.buddy = ["pool_buddy", "buddy"]
	# at the end, out in the lot: the big man at his truck, till he's driven off
	if here == "lot" and fam.call("lot_scene") and not fam.call("dad_drove"):
		out.bigman = ["work_truck", "bigman"]
	# 8. the end of the bar, till last call; the keg room after two, if he goes down to him
	if clock < 1530:
		out.endbar = ["bar_s0", "endbar"]
	elif here == "keg" and _visits(game, "keg_parley") > 0:
		out.endbar = ["keg_parley", "endbar"]
	# 9. the two women from upstairs at the near end of the bar with their white wine
	if not cleared.call("cl_res"):
		var up := bool(BUtil.js_truthy(v.get("slippers_upstairs", false)))
		if _exists("slippers_a"):
			out.slippers = ["bar_s6", "slippers_a"]
			if not up and _exists("slippers_b"):
				out.slippers_b = ["bar_s5", "slippers_b"]
		elif not up:
			out.slippers = ["bar_s6_stand", "slippers"]
	# 5. HI-VIS: at the store, then at the door, then at the bar (or upstairs)
	if here == "door" and clock >= 1260 and not arr.call("hivis_done"):
		out.hivis = ["door_front", "hivis_door"]
	elif (arr.call("hivis_in") or arr.call("hivis_hotel")) and not cleared.call("cl_hivis"):
		out.hivis = ["bar_s3", "hivis"]
	# 6. GOOD SHOES: at the door from half ten, at the bar if he got in
	if here == "door" and clock >= 1350 and not arr.call("banned_done"):
		out.goodshoes = ["door_front", "goodshoes_card"]
	elif (arr.call("banned_in") or (arr.call("banned_inside") and not arr.call("banned_out"))) and not cleared.call("cl_banned"):
		out.goodshoes = ["bar_s2", "goodshoes_bar"]
	# 7. RAINCOAT, in the vestibule, no further in
	if here == "door" and clock >= 1480 and not arr.call("wife_done"):
		out.raincoat = ["vest_stand", "raincoat"]
	# 4. the kids. kids_in is only a head count: which of them are inside is worked out from it
	var kids_in := int(BUtil.js_int(v.get("kids_in", 0)))
	var fam_done := bool(BUtil.js_truthy(v.get("fam_done", false)))
	var pickup: bool = clock >= 1190 and not fam.call("dad_went") and not fam.call("lot_scene") and not (fam_done and kids_in == 0 and not fam.call("kids_waiting"))
	var S := 1 if kids_in > 0 and (fam.call("sister_admitted") or fam.call("via_deck")) else 0
	var r := kids_in - S
	var vape_came: bool = _visits(game, "ev_sister.sister_all") > 0 or fam.call("via_deck")
	var V := 1 if r == 2 or (r == 1 and vape_came and not fam.call("vape_ejected")) else 0
	var K := r - V
	var sister_at_door: bool = fam.call("sister_met") and not fam.call("via_deck") and not fam.call("sister_admitted") \
		and not fam.call("sister_refused") and _visits(game, "ev_sister.sister_fetch") == 0 and not fam_done
	var sister_waiting: bool = _visits(game, "ev_sister.sister_fetch") > 0 and not fam.call("sister_admitted") \
		and not fam.call("kids_waiting") and not fam_done
	# the kid: in front of the stool with his phone up until he's let in or not; by the jukebox
	# inside (or locked in the single, out of sight); otherwise in the pickup, out of sight
	if pickup and not (fam.call("hoodie_admitted") or fam.call("hoodie_refused")):
		out.hoodie = ["door_front", "hoodie_door"]
	elif K >= 1 and not _kid_locked_in(v, clock):
		out.hoodie = ["juke_kid", "hoodie_juke" if _exists("hoodie_juke") else "hoodie_door"]
	# the sister: at the wheel, at the door with her card up, waiting in the vestibule, or inside
	# at the rail by the pool table
	if sister_at_door:
		out.driver = ["door_front", "driver_door"]
		out.vape = ["vest_behind", "vape_door"]
	elif sister_waiting:
		out.driver = ["vest_wait", "driver_door"]
	elif S == 1:
		out.driver = ["pool_rail", "driver_rail"] if _exists("driver_rail") else ["bar_s4", "driver"]
	elif pickup:
		out.driver = ["truck_wheel", "driver"]
	# her boyfriend: across the back seat, or at the bar trying to get served
	if not out.has("vape"):
		if V == 1:
			out.vape = ["bar_stand_v", "vape_bar"] if _exists("vape_bar") else ["bar_s4" if not out.has("driver") or out.driver[0] != "bar_s4" else "bar_s3", "vape"]
		elif pickup and not fam.call("vape_ejected"):
			out.vape = ["truck_back", "vape"]
	# 13, 14. whoever else is in: the room's count, less the ones with faces, at the free tables
	var named := 0
	for id in out:
		if id in ["bartender", "cook", "raincoat"]:
			continue
		if SPOTS[out[id][0]].zone in ["room", "hall", "deck"]:
			named += 1
	if not out.has("glasses") and not cleared.call("cl_t28"):
		named += 1          # the count never went down for Dennis
	var extra := clampi(int(BUtil.js_int(v.get("room_count", 13))) - named, 0, 8)
	# the count's stale after last call; at two the rest of them go with the crowd
	if clock >= 1560 or bool(BUtil.js_truthy(v.get("lock_up", false))):
		extra = 0
	elif clock >= 1530:
		extra = mini(extra, 3)
	var fillers := ["crew_b", "patron_a", "patron_b", "patron_c", "patron_d", "patron_e", "patron_f", "crew_a"]
	var free := ["table_d_0", "table_c_1", "table_d_1", "table_c_0", "table_a_2", "table_d_2", "table_c_2", "bar_s4"]
	var used := {}
	for id in out:
		used[out[id][0]] = true
	var k := 0
	var fi := 0
	for spot in free:
		if k >= extra:
			break
		if used.has(spot):
			continue
		while fi < fillers.size() and not _exists(fillers[fi]):
			fi += 1
		if fi >= fillers.size():
			break
		out[fillers[fi]] = [spot, fillers[fi]]
		fi += 1
		k += 1
	# anything whose model hasn't been made yet stays out
	for id in out.keys():
		if not _exists(out[id][1]):
			out.erase(id)
	# the pickup itself: from ten to eight, till it goes
	pickup_here = pickup
	return out


var pickup_here := false


func _kid_locked_in(v: Dictionary, clock: int) -> bool:
	return int(BUtil.js_int(v.get("kids_in", 0))) > 0 and _has(v, "fam", "hoodie_admitted") and not _has(v, "fam", "kid_opened") \
		and not bool(BUtil.js_truthy(v.get("fam_done", false))) and not bool(BUtil.js_truthy(v.get("kid_out", false))) \
		and (_has(v, "fam", "kid_found") or clock >= 1300)


func _visits(game: Game, path: String) -> int:
	if game.story == null:
		return 0
	return int(game.story.state().visit_count_at_path_string(path))


func _exists(model: String) -> bool:
	return FileAccess.file_exists(PEOPLE + model + ".glb")


# ---------------------------------------------------------------- keeping the room to it

# After every batch: work out who should be where, and move them when he isn't looking. Instant
# (a new night, a loaded one): just put them there.
func sync(game: Game, instant: bool) -> void:
	if game.story == null:
		want = _cast_default()
	else:
		want = _cast(game)
		var v := game.vars()
		var rounds := int(BUtil.js_int(v.get("t28_rounds", 0)))
		_thing("t28_glasses", Pub.T28 + Vector3(0, 0.8, 0), "room", func(): pub.set_t28_glasses(rounds, _has(v, "cleared", "cl_t28")), rounds)
		var here_now := pickup_here
		_thing("truck", pub.anchors.get("truck", Vector3.ZERO), "lot", func(): (pub.dyn.truck as Node3D).visible = here_now, here_now)
		# the big man's work truck, till he's driven it away
		var parked := not _has(v, "fam", "dad_drove")
		_thing("work_truck", pub.anchors.get("work_truck", Vector3.ZERO), "lot", func(): (pub.dyn.work_truck as Node3D).visible = parked, parked)
		for d in [["deck_door", "deck_door", "room"], ["kitchen_door", "kitchen_back", "kitchen"], ["hotel_door", "hotel_door", "hall"]]:
			var open := bool(BUtil.js_truthy(v.get(d[0], false)))
			var which: String = d[0]
			_thing(which, pub.anchors.get(d[1], Vector3.ZERO), d[2], func(): pub.prop_door(which, open), open)
	for id in figures.keys():
		if not want.has(id):
			want[id] = []
	# the ones who drift stay where they've drifted to
	for id in WANDER:
		var w: Array = want.get(id, [])
		var f = figures.get(id)
		if f != null and not w.is_empty() and w[0] in WANDER[id] and f.spot in WANDER[id] and f.model == w[1]:
			want[id] = [f.spot, w[1]]
	if instant:
		for id in want:
			_place(id)
		for key in things:
			_do_thing(key)
		waiting.clear()
	else:
		_settle(0.0)


# Before the night starts (the title over the door): the room as it is at nine.
# (the moment the game's named for: ten to eight, the pickup in the lot, the kid at the stool)
func _cast_default() -> Dictionary:
	var g := Game.new(content)
	g.new_game(1)
	g.set_var("clock", 1190)
	var out := _cast(g, "door")
	(pub.dyn.truck as Node3D).visible = true
	return out


func _thing(key: String, pos: Vector3, zone: String, fn: Callable, value) -> void:
	if things.has(key) and things[key][3] == value:
		return
	things[key] = [pos, zone, fn, value, false, 0.0]


func _do_thing(key: String) -> void:
	var th: Array = things[key]
	if th[4]:
		return
	th[2].call()
	th[4] = true


func _moved(id: String) -> bool:
	var w: Array = want.get(id, [])
	var f = figures.get(id)
	if f == null:
		return not w.is_empty()
	if w.is_empty():
		return true
	return f.spot != w[0] or f.model != w[1]


# Whether a point in the building is in his sight right now: in a part of the building he can see
# from where he is, and inside his eyes' reach.
func in_sight(pos: Vector3, zone: String) -> bool:
	if view == null:
		return false
	var post := view.place
	if view.walking:
		return zone in ["room", "vest"] or zone in SEEN.get(post, [])
	if not zone in SEEN.get(post, []):
		return false
	var cam := view.cam
	var half_v := deg_to_rad(cam.fov) / 2.0
	var aspect := float(view.eye.size.x) / maxf(1.0, float(view.eye.size.y))
	var half_h := atan(tan(half_v) * aspect)
	var local := cam.global_transform.affine_inverse() * pos
	if local.z > 0.3:
		return false
	var ang_h := absf(atan2(local.x, -local.z))
	var ang_v := absf(atan2(local.y, -local.z))
	return ang_h < half_h + 0.15 and ang_v < half_v + 0.25


func _spot_pos(spot: String) -> Vector3:
	var s: Dictionary = SPOTS.get(spot, {})
	if s.is_empty():
		return Vector3.ZERO
	if s.get("in", "") == "truck":
		return (pub.dyn.truck as Node3D).to_global(s.pos) + Vector3(0, 1.2, 0)
	return s.pos + Vector3(0, 1.2, 0)


func _seen_now(id: String) -> bool:
	var f = figures.get(id)
	if f != null and f.spot != "" and in_sight(_spot_pos(f.spot), SPOTS[f.spot].zone):
		return true
	var w: Array = want.get(id, [])
	if not w.is_empty() and in_sight(_spot_pos(w[0]), SPOTS[w[0]].zone):
		return true
	return false


func _settle(dt: float) -> void:
	var blink_for: Array = []
	for id in want.keys():
		if not _moved(id):
			waiting.erase(id)
			continue
		if not _seen_now(id):
			_place(id)
			waiting.erase(id)
			continue
		waiting[id] = waiting.get(id, 0.0) + dt
		if waiting[id] >= BLINK_AFTER:
			blink_for.append(id)
	for key in things:
		var th: Array = things[key]
		if th[4]:
			continue
		if not in_sight(th[0], th[1]):
			_do_thing(key)
		else:
			th[5] = th[5] + dt
			if th[5] >= BLINK_AFTER:
				blink_for.append("#" + key)
	if not blink_for.is_empty() and not _blinking:
		_blink(blink_for)


# His eyes close for a moment and the room's moved on when they open.
func _blink(ids: Array) -> void:
	_blinking = true
	var tw := create_tween()
	tw.tween_property(view, "flash", 0.92, 0.07)
	tw.tween_callback(func():
		for id in ids:
			if str(id).begins_with("#"):
				_do_thing(str(id).substr(1))
			else:
				_place(id)
				waiting.erase(id))
	tw.tween_interval(0.05)
	tw.tween_property(view, "flash", 0.0, 0.22)
	tw.tween_callback(func(): _blinking = false)


# Put a figure where it's wanted, now.
func _place(id: String) -> void:
	var w: Array = want.get(id, [])
	var f = figures.get(id)
	if w.is_empty():
		if f != null:
			(f.node as Node3D).queue_free()
			figures.erase(id)
		return
	var spot: String = w[0]
	var model: String = w[1]
	var s: Dictionary = SPOTS[spot]
	if f != null and f.model != model:
		(f.node as Node3D).queue_free()
		figures.erase(id)
		f = null
	if f == null:
		var holder := Node3D.new()
		holder.name = id
		add_child(holder)
		var body := pub.model(PEOPLE + model + ".glb", Vector3.ZERO, holder)
		body.name = "body"
		var an := anchors_of(model)
		if an.has("phone"):
			var ph := OmniLight3D.new()
			var at_phone: Array = an.phone
			var facing: Array = an.get("phone_facing", [0, 0, 1])
			ph.position = Vector3(at_phone[0], at_phone[1], at_phone[2]) + Vector3(facing[0], facing[1], facing[2]) * 0.05
			ph.light_color = Color("dfe8ff")
			ph.light_energy = 0.35
			ph.omni_range = 0.7
			holder.add_child(ph)
		f = {"node": holder, "spot": "", "model": model, "anchors": an, "phase": randf() * TAU, "rate": randf_range(0.18, 0.3)}
		figures[id] = f
	var node: Node3D = f.node
	if s.get("in", "") == "truck":
		if node.get_parent() != pub.dyn.truck:
			node.reparent(pub.dyn.truck, false)
		node.transform = Transform3D(Basis.IDENTITY, s.pos + Vector3(0, float(s.get("y", 0.0)), 0))
	else:
		if node.get_parent() != self:
			node.reparent(self, false)
		var pos: Vector3 = s.pos + Vector3(0, float(s.get("y", 0.0)) + _sit_offset(model, spot), 0)
		node.transform = Transform3D.IDENTITY
		node.position = pos
		var face: Vector3 = s.face
		if Vector2(face.x - pos.x, face.z - pos.z).length() > 0.01:
			node.look_at(Vector3(face.x, pos.y, face.z), Vector3.UP)
	f.spot = spot
	f.base_yaw = node.rotation.y
	wander_at[id] = t + randf_range(20.0, 45.0)
	if model == "bigman":
		_dress(node, spot.begins_with("pool"))


# The big man's cue stays at the pool table when he goes out to his truck.
func _dress(node: Node3D, cue: bool) -> void:
	for n in node.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			if src != null and src.resource_name == "cue":
				mi.set_surface_override_material(i, pub._from_model(src) if cue else _gone())


var _gone_mat: ShaderMaterial


func _gone() -> ShaderMaterial:
	if _gone_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled;\nvoid fragment() { discard; }\n"
		_gone_mat = ShaderMaterial.new()
		_gone_mat.shader = sh
	return _gone_mat


# The truck's two sit higher than a stool: brought down to one when they're inside.
func _sit_offset(model: String, spot: String) -> float:
	if model == "driver" and not spot.begins_with("truck"):
		return -0.22 if spot.begins_with("bar_s") else -0.34
	if model == "vape" and not spot.begins_with("truck"):
		return -0.22 if spot.begins_with("bar_s") else -0.34
	return 0.0


func anchors_of(model: String) -> Dictionary:
	if _anchors.has(model):
		return _anchors[model]
	var out := {}
	var path := PEOPLE + model + ".json"
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			out = d
	_anchors[model] = out
	return out


# Where someone's head is, in the world (for his eyes to go to, and for the voices' marks).
func head_of(id: String) -> Vector3:
	var f = figures.get(SPEAKS_FOR.get(id, id))
	if f == null:
		return Vector3.INF
	var h: Array = f.anchors.get("head", [0, 1.5, 0])
	return (f.node as Node3D).to_global(Vector3(h[0], h[1], h[2]))


func figure_zone(id: String) -> String:
	var f = figures.get(SPEAKS_FOR.get(id, id))
	if f == null:
		return ""
	return SPOTS[f.spot].zone


func present(id: String) -> bool:
	return figures.has(SPEAKS_FOR.get(id, id))


# ---------------------------------------------------------------- answering the night

func arrived(_where: String) -> void:
	_settle(0.0)


# Someone speaks: if he can see them, they turn a little toward him.
func speaking(speaker: String) -> void:
	var id: String = SPEAKS_FOR.get(speaker, speaker)
	var f = figures.get(id)
	if f == null or view == null:
		return
	var node: Node3D = f.node
	if node.get_parent() != self:
		return
	if not in_sight(head_of(id), SPOTS[f.spot].zone):
		return
	var to := view.eye_pos - node.global_position
	var yaw_to := atan2(-to.x, -to.z)
	var d := wrapf(yaw_to - float(f.base_yaw), -PI, PI)
	var turn := clampf(d, -0.45, 0.45)
	if _turned.has(id) and (_turned[id] as Tween).is_valid():
		(_turned[id] as Tween).kill()
	var tw := node.create_tween()
	tw.tween_property(node, "rotation:y", float(f.base_yaw) + turn, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(5.0)
	tw.tween_property(node, "rotation:y", float(f.base_yaw), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turned[id] = tw


# The Ink's #portrait: someone comes into the story. His eyes go to them, if they're where he can
# see them.
func glance(id: String) -> void:
	if view == null or not present(id):
		return
	var h := head_of(id)
	if h == Vector3.INF:
		return
	if figure_zone(id) in SEEN.get(view.place, []):
		view.look_at_point(h)


func _process(dt: float) -> void:
	t += dt
	_check -= dt
	if _check <= 0.0 and view != null:
		_check = 0.25
		_settle(0.25)
		_wander()
	# breathing, and the small shifts of people sitting a long time
	for id in figures:
		var f: Dictionary = figures[id]
		var body: Node3D = (f.node as Node3D).get_node_or_null("body")
		if body == null:
			continue
		var ph: float = f.phase
		body.position.y = 0.004 * sin(t * TAU * float(f.rate) + ph)
		body.rotation.y = 0.018 * sin(t * 0.13 + ph * 2.0)


# The ones who drift, drift, when he isn't looking.
func _wander() -> void:
	for id in WANDER:
		if not figures.has(id) or not want.has(id) or want[id].is_empty():
			continue
		if t < float(wander_at.get(id, 0.0)):
			continue
		var f: Dictionary = figures[id]
		var list: Array = WANDER[id]
		if not f.spot in list:
			continue
		var next: String = list[(list.find(f.spot) + 1 + randi() % maxi(1, list.size() - 1)) % list.size()]
		if next == f.spot:
			wander_at[id] = t + 10.0
			continue
		if in_sight(_spot_pos(f.spot), "room") or in_sight(_spot_pos(next), "room"):
			wander_at[id] = t + 3.0
			continue
		want[id] = [next, f.model]
		_place(id)
		wander_at[id] = t + randf_range(25.0, 60.0)
