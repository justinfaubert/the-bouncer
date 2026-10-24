# The people in the Sov, where the night has put them.
#
# Who is where comes from the Ink's state (who's been let in, who's been put out, who's come down
# from upstairs, the clock), worked out fresh after every batch in `_cast`. The room keeps to it the
# way a room does: people move while he isn't looking. A change waits until the place it's in is
# out of his sight (behind him, through a wall, off the edge of his eyes). If he's looking, the ones
# who can walk (STROLL) walk there, round the tables and whoever's in the way: the kid in past him
# to the jukebox, or back across the lot to the pickup; whoever's going, out of the door and off
# into the dark; whoever's coming, in from the lot. For anyone else, his eyes close for a blink and
# it's done.
# And the room lives between glances on its own: the bartender works along the bar, the buddy goes
# round the table, Slippers drifts between the jukebox and the bar. It goes on while he watches too
# (world/doings.gd): laughs, the pool game, the bartender at her work, someone off to the washroom
# and back; and it's heard, a stool scraped back behind him as someone sits or gets up.
#
# The people are sculpted and posed in tools/people.py (sketches/door-look), one model per pose;
# where their heads and hands and phones are is written beside each model in a .json.
class_name Stage
extends Node3D

signal walked(id: String)          # someone's got where they were walking to
signal sound(id: String, pos: Vector3, gain: float, reach: float)   # one of the room's own, from where it happens

const PEOPLE := "res://models/people/"
const BLINK_AFTER := 1.1           # seconds a change waits in his sight before he blinks

# where a figure can be: the spot, the way it faces, the part of the building it's in (what he can
# see from each post is SEEN), and anything that's put in the truck's frame instead of the world's
var SPOTS := {}
const SEEN := {
	"door": ["vest", "room", "lot", "truck"],
	"floor": ["vest", "room", "lot"], "bar": ["vest", "room"], "t28": ["vest", "room", "lot", "truck"], "pool": ["room", "vest"],
	"hall": ["hall", "room", "lobby"], "kitchen": ["kitchen"], "keg": ["keg"], "deck": ["deck", "lot"],
	"lot": ["lot", "truck", "vest", "room"], "upstairs": ["upstairs", "lot", "truck"],
	# before the night, away from it: Gary's front room and the street out of its window; the town;
	# from the seawall, the town and the Sov's lot across the highway
	"office": ["office", "town"], "street": ["town"], "esso": ["town"], "seawall": ["town", "lot", "truck"],
}
# where the man across Gary's desk is, by what Gary's looking at (Posts.FRAMES): in the doorway as
# he comes in, while Gary's looking there, and in the chair across the desk otherwise
const HIM_AT := {"office:door": ["office_door", "him_stand"], "office": ["office_chair", "him_desk"]}
# the ones who drift on their own between glances, and where to
const WANDER := {
	"bartender": ["bar_back_mid", "bar_back_till", "bar_back_far", "bar_back_mid"],
	"buddy": ["pool_buddy", "pool_buddy_b", "pool_buddy_c"],
	"slippers": ["juke", "juke", "bar_s6_stand"],
	"bigman": ["pool_cue", "pool_cue_b"],
}
# who speaks for a speaker the Ink names that isn't one figure
const SPEAKS_FOR := {"table28": "team_jacket", "kid": "hoodie", "sister": "driver", "wife": "raincoat", "rats": "endbar"}
# The ones who can be seen walking (tools/export_walkers.py made each a walk, <id>_walk.glb), and how
# fast each goes, metres a second: the kid not hurrying, Dennis's wife in no state to.
const STROLL := {"hoodie": 1.0, "driver": 1.2, "vape": 1.25, "goodshoes": 1.3, "hivis": 1.25, "raincoat": 1.1,
	"constable": 1.3, "bigman": 1.25, "glasses": 1.05, "buddy": 1.25}
const WALKABLE := ["room", "vest", "lot", "hall", "deck"]       # the parts of the ground floor they walk in
const OFF_INTO := Vector3(6.2, 0, 17.5)                         # out of the door and off across the lot, into the dark
# where someone coming to the door comes from, out in the lot, nearest first: the first he can't see
const COMES_FROM := [Vector3(4.6, 0, 13.4), Vector3(6.4, 0, 15.6), Vector3(2.6, 0, 16.4), Vector3(7.5, 0, 18.5)]
# which post sees what a part of the building does, for what he can see on the way somewhere
const ZONE_POST := {"room": "floor", "vest": "door", "hall": "hall", "kitchen": "kitchen", "deck": "deck", "lot": "lot",
	"lobby": "hall", "keg": "keg", "upstairs": "upstairs", "office": "office", "town": "street"}
# the men's on the back hall, for whoever goes: in front of its door, and inside it, past the door
const WC_DOOR := "wc_men"
const WC_FRONT := Vector3(7.47, 0, -0.8)
const WC_IN := Vector3(7.47, 0, -1.8)

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
var walkers := {}                  # id -> the walk they're on (see _walk_off)
var _nav: Nav
var _v := {}                       # the night as of the last sync: where people go when they go
var life := Life.new()             # the ones with bones, alive while he watches (world/life.gd)
var doings := Doings.new()         # and the room going on by itself (world/doings.gd)
var away := {}                     # id -> the washroom: {"back": when, "flushed": bool, "want": [spot, model] to come back to}
var _quiet := false                # putting everyone where they are at once: no stools heard


func setup(p: Pub, c: Dictionary) -> void:
	pub = p
	content = c
	life.cups = pub.dyn.get("t28_glasses")
	life.heard = func(id, pos, gain, reach): sound.emit(id, pos, gain, reach)
	doings.stage = self
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
	var a5 := TAU * 5 / 6.0 + 0.25
	s["t28_behind5"] = {"pos": T28 + Vector3(cos(a5) * 1.75, 0, sin(a5) * 1.75), "face": T28, "zone": "room"}
	# the bar: behind it, and its stools from the far end to the door end
	s["bar_back_mid"] = {"pos": Vector3(1.15, 0, 4.8), "face": Vector3(6.0, 0, 4.8), "zone": "room"}
	s["bar_back_till"] = {"pos": Vector3(1.15, 0, 6.7), "face": Vector3(6.0, 0, 7.4), "zone": "room"}
	s["bar_back_far"] = {"pos": Vector3(1.15, 0, 2.6), "face": Vector3(6.0, 0, 2.2), "zone": "room"}
	for i in 7:
		var z := 1.6 + i * 0.85
		if absf(z - Pub.SERVICE_Z) > 0.1:
			s["bar_s%d" % i] = {"pos": Vector3(2.65, 0, z), "face": Vector3(0.0, 0, z), "zone": "room"}
	s["bar_s6_stand"] = {"pos": Vector3(3.05, 0, 6.3), "face": Vector3(0.0, 0, 6.0), "zone": "room"}
	# the pool table
	s["pool_cue"] = {"pos": POOL + Vector3(1.8, 0, 1.0), "face": POOL, "zone": "room"}
	s["pool_cue_b"] = {"pos": POOL + Vector3(-1.75, 0, -0.9), "face": POOL, "zone": "room"}
	s["pool_buddy"] = {"pos": POOL + Vector3(-1.0, 0, -1.35), "face": POOL, "zone": "room"}
	s["pool_buddy_b"] = {"pos": POOL + Vector3(0.4, 0, 1.55), "face": POOL, "zone": "room"}
	s["pool_buddy_c"] = {"pos": POOL + Vector3(2.0, 0, -0.6), "face": POOL, "zone": "room"}
	s["pool_watch"] = {"pos": POOL + Vector3(-1.05, 0, 2.5), "face": POOL, "zone": "room"}
	# the other tables' stools: a, b, c, d as in Pub.TABLES
	var names := ["a", "b", "c", "d"]
	for ti in Pub.TABLES.size():
		var tb: Vector3 = Pub.TABLES[ti]
		var offs := [Vector3(0.62, 0, 0), Vector3(-0.62, 0, 0), Vector3(0, 0, 0.62)]
		for j in offs.size():
			s["table_%s_%d" % [names[ti], j]] = {"pos": tb + offs[j], "face": tb, "zone": "room"}
	s["juke"] = {"pos": Vector3(13.2, 0, 1.2), "face": Vector3(13.2, 0, 0.0), "zone": "room"}
	s["juke_kid"] = {"pos": Vector3(12.7, 0, 1.15), "face": Vector3(13.2, 0, 0.0), "zone": "room"}
	s["pool_rail"] = {"pos": POOL + Vector3(-0.3, 0, 1.5), "face": POOL, "zone": "room"}
	# at the door end of the bar, by the till, where you pay: out of the gap, which is staff's
	s["bar_stand_v"] = {"pos": Vector3(2.75, 0, 7.45), "face": Vector3(0.0, 0, 7.45), "zone": "room"}
	# on their feet with a pint: behind the stools at the bar, and by the front window
	s["stand_bar"] = {"pos": Vector3(3.15, 0, 2.9), "face": Vector3(0.0, 0, 3.1), "zone": "room"}
	s["stand_window"] = {"pos": Vector3(11.7, 0, 9.35), "face": Vector3(9.4, 0, 8.1), "zone": "room"}
	s["vest_wait"] = {"pos": Vector3(3.85, 0, 9.35), "face": Vector3(2.0, 0, 9.0), "zone": "vest"}
	s["vest_behind"] = {"pos": Vector3(3.55, 0, 10.0), "face": eye, "zone": "vest"}
	s["vest_stand"] = {"pos": Vector3(3.3, 0, 9.7), "face": Vector3(6.0, 0, 7.0), "zone": "vest"}
	# on the upturned keg in the aisle between the rows, facing the way down
	s["keg_parley"] = {"pos": Vector3(3.42, Pub.KEG_Y, 1.25), "face": Vector3(3.42, Pub.KEG_Y, 4.35), "zone": "keg", "y": -0.16}
	s["deck_chair_rail"] = {"pos": Vector3(17.8, 0, 6.6), "face": Vector3(18.4, 0, 6.6), "zone": "deck", "y": -0.29}
	# the door: in front of his stool, and out on the gravel
	# far enough back that the door's still behind them: about where anyone stops to be carded
	s["door_front"] = {"pos": Vector3(3.0, 0, 9.76), "face": eye, "zone": "vest"}
	s["door_step"] = {"pos": Vector3(4.2, 0, 11.4), "face": eye, "zone": "lot"}
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
	# through the hotel door: the night clerk's stool behind the front desk, square to the doorway
	s["desk_stool"] = {"pos": Vector3(18.35, 0, -0.62), "face": Vector3(16.1, 0, -0.62), "zone": "lobby"}
	s["deck_chair"] = {"pos": Vector3(17.3, 0, 8.2), "face": Vector3(18.4, 0, 8.2), "zone": "deck", "y": -0.29}
	s["deck_chair_far"] = {"pos": Vector3(17.3, 0, 5.0), "face": Vector3(18.4, 0, 6.2), "zone": "deck", "y": -0.29}
	s["deck_chair_back"] = {"pos": Vector3(16.75, 0, 5.35), "face": Vector3(17.6, 0, 6.4), "zone": "deck", "y": -0.29}
	# at the top of the deck steps: one looking across at the door, one looking down the deck at the lot
	s["deck_steps"] = {"pos": Vector3(17.95, 0, 5.3), "face": Vector3(16.3, 0, 7.0), "zone": "deck"}
	s["deck_steps_lot"] = {"pos": Vector3(18.05, 0, 5.85), "face": Vector3(19.0, 0, 16.0), "zone": "deck"}
	# Away from the Sov (world/town.gd), put in the town so they're put away with it. In Gary's
	# office: the armchair across his desk, just inside the front door, the bookkeeper's chair at her
	# desk; the ice freezer by the Esso's door; the wharf's rail at the end, under its light. Where
	# someone sits, the height of the seat (_seat_on); "still", the ones in a chair with arms or at a
	# desk, who don't turn to him in it.
	var ox := Town.OFFICE_X
	var oy := Town.OFFICE_Y
	var oz := Town.OFFICE_Z
	s["office_chair"] = {"pos": Vector3(ox + 1.9, oy, oz), "face": Vector3(Town.GARY.x, oy, oz), "zone": "office", "in": "town", "seat": 0.46, "still": true}
	s["office_door"] = {"pos": Vector3(ox + 0.45, oy, oz - 1.1), "face": Vector3(Town.GARY.x, oy, oz), "zone": "office", "in": "town"}
	s["office_bk"] = {"pos": Vector3(ox + 3.15, oy, oz - 1.15), "face": Vector3(ox + 3.15, oy, oz - 2.3), "zone": "office", "in": "town", "seat": 0.46, "still": true}
	s["esso_freezer"] = {"pos": Vector3(-147.3, Town.APRON, 12.4), "face": Vector3(-147.3, Town.APRON, 20.0), "zone": "town", "in": "town", "seat": 0.86}
	s["wharf_rail"] = {"pos": Vector3(-198.15, Town.WHARF_Y, 93.6), "face": Vector3(-190.0, Town.WHARF_Y, 96.6), "zone": "town", "in": "town"}
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
	# away from the Sov he's wherever his eyes are, whatever the night's bookkeeping says yet
	if here_as == "" and view != null and Posts.away(view.place):
		here = view.place
	var out := {}
	var fam := func(item: String) -> bool: return _has(v, "fam", item)
	var arr := func(item: String) -> bool: return _has(v, "arrivals", item)
	var cleared := func(item: String) -> bool: return _has(v, "cleared", item)
	# 1. the bartender, behind the bar all night, but for the two minutes she's down the trapdoor
	# changing the lager (bar.ink, lager_out); 10. the cook, till he goes home at eleven; Terry on
	# the front desk through the hotel door, all night
	if not bool(BUtil.js_truthy(v.get("lager_down", false))):
		out.bartender = ["bar_back_mid", "bartender"]
	out.terry = ["desk_stool", "terry"]
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
	var pool_still: bool = not (fam.call("dad_went") or fam.call("dad_ejected") or fam.call("lot_scene") or fam.call("dad_drove") or fam.call("dad_walked"))
	if pool_still and not cleared.call("cl_pool"):
		out.bigman = ["pool_cue", "bigman"]
		out.buddy = ["pool_buddy", "buddy"]
	# at the end, out in the lot: the big man at his truck, till he's driven off
	if here == "lot" and fam.call("lot_scene") and not fam.call("dad_drove"):
		out.bigman = ["work_truck", "bigman"]
	# at two in the morning, back from the Esso for his keys: outside the front door's glass, under
	# the light over it (closing.ink, keys_at_two), till he's had his answer
	if _visits(game, "after_hours.keys_at_two") > 0 and int(BUtil.js_int(v.get("keys_back", 0))) == 0:
		out.bigman = ["door_step", "bigman"]
	# 8. the end of the bar, till last call (before the night, at the wharf's rail, looking at the
	# water); the keg room after two, if he goes down to him
	if clock < Town.NIGHT:
		out.endbar = ["wharf_rail", "endbar_wharf"]
	elif clock < 1530:
		out.endbar = ["bar_s0", "endbar"]
	elif here == "keg" and _visits(game, "keg_parley") > 0:
		out.endbar = ["keg_parley", "endbar"]
	# Before the night, away from the Sov (world/town.gd). Gary's office: the man across the desk
	# (HIM_AT) and the bookkeeper at hers; never Gary, whose eyes these are. The kid on the ice
	# freezer at the Esso, till the night.
	if here == "office":
		var framed := "office:" + view.frame if view != null and view.frame != "" else "office"
		out.him = HIM_AT.get(framed, HIM_AT.office)
		out.bookkeeper = ["office_bk", "bookkeeper_desk"]
	if here == "esso" and clock < Town.NIGHT:
		out.essokid = ["esso_freezer", "essokid_freezer"]
	# 9. the two women from upstairs at the near end of the bar with their white wine
	if not cleared.call("cl_res"):
		var up := bool(BUtil.js_truthy(v.get("slippers_upstairs", false)))
		if _exists("slippers_a"):
			out.slippers = ["bar_s6", "slippers_a"]
			if not up and _exists("slippers_b"):
				out.slippers_b = ["bar_s5", "slippers_b"]
		elif not up:
			out.slippers = ["bar_s6_stand", "slippers"]
	# The three who come to the door later each have a scene there. The Ink marks the arrival done
	# as the scene starts, and marks how it went at its end, so a scene is on between the two.
	# 5. HI-VIS: at the store, then at the door, then at the bar (or upstairs)
	if arr.call("hivis_done") and not (arr.call("hivis_in") or arr.call("hivis_out") or arr.call("hivis_hotel")):
		if here == "door":
			out.hivis = ["door_front", "hivis_door"]
	elif (arr.call("hivis_in") or arr.call("hivis_hotel")) and not cleared.call("cl_hivis"):
		out.hivis = ["bar_s3", "hivis"]
	# 6. GOOD SHOES: at the door from half ten (in the vestibule while he checks the binder or asks),
	# at the bar if he got in
	if arr.call("banned_done") and not (arr.call("banned_inside") or arr.call("banned_in") or arr.call("banned_out")):
		out.goodshoes = ["door_front", "goodshoes_card"] if here == "door" else ["vest_wait", "goodshoes_card"]
	elif (arr.call("banned_in") or (arr.call("banned_inside") and not arr.call("banned_out"))) and not cleared.call("cl_banned"):
		out.goodshoes = ["bar_s2", "goodshoes_bar"]
	# 7. RAINCOAT, in the vestibule, no further in; or, when nobody was on the door, standing behind
	# Dennis at table 28 while that plays out, and then gone with him
	if arr.call("wife_done") and not (arr.call("wife_lied") or arr.call("wife_told") or arr.call("wife_in") or arr.call("wife_inside")):
		if here == "door":
			out.raincoat = ["vest_stand", "raincoat"]
	elif not cleared.call("cl_t28") and _scene(game) == "ev_wife_inside":
		out.raincoat = ["t28_behind5", "raincoat"]
		out.glasses = ["t28_5", "glasses"]
	# the constable, forty minutes after a fight's called in: just inside the door while she asks
	# about it (before close, or knocking on the glass after he's locked up and let in)
	if _scene(game) == "ev_police":
		out.constable = ["door_front", "constable"]
	# 4. the kids: where each of the three is, as the Ink keeps it (kid_at, sister_at, vape_at, one
	# spot each, moved by move() in sim.ink), and the pickup till it goes (truck_gone)
	var kid := _spot_of(v, "kid_at")
	var sister := _spot_of(v, "sister_at")
	var vape := _spot_of(v, "vape_at")
	var pickup: bool = clock >= 1190 and not bool(BUtil.js_truthy(v.get("truck_gone", false)))
	# the kid: in front of the stool with his phone up (or walking up to it, before anything's been
	# decided); by the jukebox; at the rail with his father; loose in the lot. Locked in the single
	# washroom, or in the pickup, he's out of sight.
	match kid:
		"s_door":
			out.hoodie = ["door_front", "hoodie_door"]
		"s_jukebox":
			out.hoodie = ["juke_kid", "hoodie_juke" if _exists("hoodie_juke") else "hoodie_door"]
		"s_rail":
			out.hoodie = ["pool_watch", "hoodie_door"]
		"s_lot":
			out.hoodie = ["lot_walk", "hoodie_lot" if _exists("hoodie_lot") else "hoodie_door"]
		"s_truck":
			if pickup and not (fam.call("hoodie_admitted") or fam.call("hoodie_refused")):
				out.hoodie = ["door_front", "hoodie_door"]
	# the sister: at the door with her card up, waiting in the vestibule, at the rail by the pool
	# table, or at the wheel of the pickup
	match sister:
		"s_door":
			out.driver = ["door_front", "driver_door"]
		"s_vestibule":
			out.driver = ["vest_wait", "driver_door"]
		"s_rail":
			out.driver = ["pool_rail", "driver_rail"] if _exists("driver_rail") else ["bar_s1", "driver"]
		"s_bar":
			out.driver = ["bar_s1", "driver"]
		"s_lot":
			out.driver = ["lot_truck", "driver_door"]
		"s_truck":
			if pickup:
				out.driver = ["truck_wheel", "driver"]
	# her boyfriend: behind her at the door, at the bar trying to get served, rattling round the lot,
	# or across the pickup's back seat
	match vape:
		"s_door", "s_vestibule":
			out.vape = ["vest_behind", "vape_door"]
		"s_bar", "s_jukebox", "s_rail":
			out.vape = ["bar_stand_v", "vape_bar"] if _exists("vape_bar") else ["bar_s1" if not out.has("driver") or out.driver[0] != "bar_s1" else "bar_s3", "vape"]
		"s_lot":
			out.vape = ["lot_walk" if not out.has("hoodie") or out.hoodie[0] != "lot_walk" else "door_step", "vape_door"]
		"s_truck":
			if pickup:
				out.vape = ["truck_back", "vape"]
	# 13, 14. whoever else is in: the room's count, less the ones with faces, at the free tables
	var named := 0
	for id in out:
		if id in ["bartender", "cook", "raincoat", "terry"]:
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
	# in the order the room fills, each to a place their pose fits: a table's stool, the bar's, or
	# on their feet with a pint
	var fillers := [["crew_b", "table"], ["patron_a", "table"], ["patron_e", "bar"], ["patron_c", "stand"],
		["patron_b", "table"], ["patron_f", "table"], ["patron_d", "stand"], ["crew_a", "table"]]
	var free := {"table": ["table_d_0", "table_d_1", "table_c_1", "table_c_0", "table_a_2", "table_d_2", "table_c_2"],
		"bar": ["bar_s1", "bar_s5"], "stand": ["pool_watch", "stand_bar", "stand_window"]}
	var used := {}
	for id in out:
		used[out[id][0]] = true
	var k := 0
	for f in fillers:
		if k >= extra:
			break
		if not _exists(f[0]):
			continue
		for spot in free[f[1]]:
			if not used.has(spot):
				used[spot] = true
				out[f[0]] = [spot, f[0]]
				k += 1
				break
	# out on the deck before last call: a woman smoking at the top of the steps (she watches him pull
	# the coaster, in deck.ink), and whoever else is out there to talk in front of him as if a doorman
	# were a post (_deck_smokers)
	if here == "deck" and clock < 1530:
		out.patron_d = ["deck_steps", "patron_d"]
		var smokers := _deck_smokers(v, clock)
		if smokers == 1:
			var rail_free: bool = not (out.has("cardigan") and out.cardigan[0] == "deck_chair_rail")
			out.patron_f = ["deck_chair_rail" if rail_free else "deck_chair_far", "patron_f"]
		elif smokers == 2:
			out.patron_c = ["deck_steps_lot", "patron_c"]
		elif smokers == 3:
			out.crew_a = ["deck_chair_far", "crew_a"]
			out.crew_b = ["deck_chair_back", "crew_b"]
	# anything whose model hasn't been made yet stays out
	for id in out.keys():
		if not _exists(out[id][1]):
			out.erase(id)
	# the pickup itself: from ten to eight, till it goes
	pickup_here = pickup
	return out


var pickup_here := false


# where one of the three is: the one item of their spot list ("s_jukebox"), or "" if none
func _spot_of(v: Dictionary, name: String) -> String:
	var l = v.get(name)
	if l is Array:
		return str(l[0]) if not l.is_empty() else ""
	return str(l) if l != null else ""


# Who's smoking on the deck besides the woman at the steps (deck.ink, the air stitch): the ones who
# just talked in front of him, till their smoke's done, or else the next ones who will, by the same
# tests the Ink uses. 1 the two women with the news about GOOD SHOES, 2 the man watching the pickup,
# 3 two of the mill crew at the back, 0 nobody else.
func _deck_smokers(v: Dictionary, clock: int) -> int:
	var said := int(BUtil.js_int(v.get("deck_smokers", 0)))
	if said != 0 and clock < int(BUtil.js_int(v.get("smokers_at", 0))) + 20:
		return said
	if not _has(v, "arrivals", "banned_done") and not _has(v, "knows", "ardagh") and clock >= 1230:
		return 1
	if not _has(v, "knows", "truck") and not BUtil.js_truthy(v.get("truck_gone", false)):
		return 2
	if not _has(v, "knows", "mill_closing"):
		return 3
	return 0


func _visits(game: Game, path: String) -> int:
	if game.story == null:
		return 0
	return int(game.story.state().visit_count_at_path_string(path))


# the scene the night is waiting in: the knot its choices come from
func _scene(game: Game) -> String:
	var vis := game.visible_choices()
	return str(vis[0].get("knot", "")) if not vis.is_empty() else ""


func _exists(model: String) -> bool:
	return FileAccess.file_exists(PEOPLE + model + ".glb")


# ---------------------------------------------------------------- keeping the room to it

# After every batch: work out who should be where, and move them when he isn't looking. Instant
# (a new night, a loaded one): just put them there.
func sync(game: Game, instant: bool) -> void:
	if game.story == null:
		want = _cast_default()
		_v = {}
	else:
		want = _cast(game)
		var v := game.vars()
		_v = v
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
	# whoever's in the washroom stays there till they're done, unless the night wants them now (a
	# scene's on, or he's come to where they were)
	var scene_on: bool = game.story != null and _scene(game).begins_with("ev_")
	for id in away.keys():
		away[id].want = want.get(id, [])
		if scene_on or instant or _post_of(away[id].want) == (view.place if view != null else ""):
			_back(id)
		else:
			want[id] = []
	# the ones who drift stay where they've drifted to; but with him at the bar, the bartender comes
	# back across from him
	var at_bar: bool = game.story != null and game.here() == "bar"
	for id in WANDER:
		var w: Array = want.get(id, [])
		var f = figures.get(id)
		if id == "bartender" and at_bar:
			continue
		if f != null and not w.is_empty() and w[0] in WANDER[id] and f.spot in WANDER[id] and f.model == w[1]:
			want[id] = [f.spot, w[1]]
	if instant:
		_stop_walks()
		_quiet = true
		for id in want:
			_place(id)
		_quiet = false
		_from_wc.clear()
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
		# on the way: what the part of the building he's in can see, and where he's going can
		var mine := Hotspots.zone_of(view.eye_pos)
		if not (zone == mine or zone in SEEN.get(post, []) or zone in SEEN.get(ZONE_POST.get(mine, ""), [])):
			return false
	elif not zone in SEEN.get(post, []):
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
		if walkers.has(id) or not _moved(id):
			waiting.erase(id)
			continue
		if not _seen_now(id):
			_place(id)
			waiting.erase(id)
			continue
		if _walk_off(id):
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


# ---------------------------------------------------------------- walking

# Someone the night has moved while he's looking, who can walk: off they go, from where they are
# (out of the pickup, from beside its door; or, coming, from out in the lot where he can't see them)
# to where they're wanted (or, going, to the pickup or out into the dark). False if they can't (no walk made for them, off the ground
# floor, sitting, no way there), and his eyes close on it instead.
func _walk_off(id: String) -> bool:
	if id == "bartender":
		return _behind_bar(id)
	if not STROLL.has(id) or not _exists(id + "_walk") or view == null:
		return false
	var w: Array = want.get(id, [])
	var f = figures.get(id)
	var from := Vector3.INF
	var out_of_truck := false
	if f != null:
		var node: Node3D = f.node
		if f.spot != "" and SPOTS[f.spot].get("in", "") == "truck":
			# out of the pickup: from beside its door
			if w.is_empty() or not pickup_here:
				return false
			from = _truck_door(f.spot)
			out_of_truck = true
		elif node.get_parent() != self or f.spot == "" or not str(SPOTS[f.spot].zone) in WALKABLE:
			return false
		else:
			from = node.global_position
	elif w.is_empty():
		return false
	# back out of the washroom: from in front of its door (and through it, below)
	var from_wc: bool = f == null and _from_wc.has(id)
	if from_wc:
		from = WC_FRONT
	var to := Vector3.INF
	if w.is_empty():
		to = _goes_to(id)
	else:
		var s: Dictionary = SPOTS[w[0]]
		if s.get("in", "") == "truck":
			if f == null:
				return false
			to = _truck_door(w[0])
		elif str(s.zone) in WALKABLE:
			to = s.pos
			if _seated(w[0]):
				# up to the seat from behind it: the sitting down's in the blink of taking the pose
				var away := Vector3(s.pos.x - s.face.x, 0.0, s.pos.z - s.face.z)
				if away.length() > 0.01:
					to = s.pos + away.normalized() * 0.32
		else:
			return false
	if from == Vector3.INF:
		from = _comes_from()
	if _nav == null:
		_nav = Nav.new(Nav.SLIGHT)
	var others: Array = [view.eye_pos]
	for o in figures:
		if o != id and (figures[o].node as Node3D).get_parent() == self:
			others.append((figures[o].node as Node3D).global_position)
	var path := _nav.way(from, to, others)
	if path.is_empty():
		path = _nav.way(from, to)
	if path.size() < 2:
		return false
	# to the washroom and in through its door, or out through it and back
	var wc_door := -1.0
	var into_wc: bool = w.is_empty() and away.has(id)
	if into_wc:
		path.append(WC_IN)
		wc_door = Nav.length_of(path) - WC_IN.distance_to(Vector3(WC_IN.x, 0, Pub.HALL_Z))
	elif from_wc:
		path.insert(0, WC_IN)
		wc_door = WC_IN.distance_to(Vector3(WC_IN.x, 0, Pub.HALL_Z))
		_from_wc.erase(id)
	if f != null and str(f.spot) != "" and _seated(f.spot):
		_scrape(f.spot)
	# the walking body in place of the standing one (or a new one, coming in)
	if f == null:
		var holder := Node3D.new()
		holder.name = id
		add_child(holder)
		holder.position = Vector3(from.x, 0.0, from.z)
		f = {"node": holder, "spot": w[0], "model": "", "anchors": {}, "phase": randf() * TAU, "rate": randf_range(0.18, 0.3), "base_yaw": 0.0}
		figures[id] = f
	var node2: Node3D = f.node
	if out_of_truck:
		node2.reparent(self, false)
		node2.transform = Transform3D.IDENTITY
		node2.position = Vector3(from.x, 0.0, from.z)
	if _turned.has(id) and (_turned[id] as Tween).is_valid():
		(_turned[id] as Tween).kill()
	for c in node2.get_children():
		c.queue_free()
	var a0: Vector3 = Nav.at(path, minf(0.4, Nav.length_of(path)))[0] - path[0]
	if Vector2(a0.x, a0.z).length() > 0.01:
		node2.rotation = Vector3(0.0, atan2(-a0.x, -a0.z), 0.0)
	var body := pub.model(PEOPLE + id + "_walk.glb", Vector3.ZERO, node2)
	body.name = "walking"
	f.anchors = anchors_of(id + "_walk")
	f.model = id + "_walk"
	var anim := body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null and anim.has_animation("walk"):
		anim.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
		anim.play("walk")
		anim.seek(randf(), true)
		anim.speed_scale = 0.0
	var doors := Posts.doors_on(path)
	if wc_door >= 0.0:
		doors.append([WC_DOOR, wc_door, 0])
	walkers[id] = {"path": path, "len": Nav.length_of(path), "s": 0.0, "v": 0.0, "to": w.duplicate(),
		"pace": float(STROLL[id]), "stride": maxf(0.3, float(f.anchors.get("stride", 1.0))), "anim": anim,
		"doors": doors}
	return true


# The bartender, along behind the bar from one end of it to the other: the bar's between her feet
# and anyone who'd see them, so it's her as she stands, carried along at a walk.
func _behind_bar(id: String) -> bool:
	var w: Array = want.get(id, [])
	var f = figures.get(id)
	if f == null or w.is_empty() or f.model != w[1] or not (str(f.spot).begins_with("bar_back") and str(w[0]).begins_with("bar_back")):
		return false
	var node: Node3D = f.node
	var to: Vector3 = SPOTS[w[0]].pos
	var path := PackedVector3Array([Vector3(node.position.x, 0.0, node.position.z), Vector3(to.x, 0.0, to.z)])
	if Nav.length_of(path) < 0.05:
		return false
	if _turned.has(id) and (_turned[id] as Tween).is_valid():
		(_turned[id] as Tween).kill()
	walkers[id] = {"path": path, "len": Nav.length_of(path), "s": 0.0, "v": 0.0, "to": w.duplicate(),
		"pace": 1.1, "stride": 1.0, "anim": null, "doors": []}
	return true


# Along their way: a man's pace, slowing to stop; the doors on it opening as they come to them;
# turning to face the way. There: standing where they were wanted as they're wanted (or, going, gone).
func _walk_on(dt: float) -> void:
	for id in walkers.keys():
		var wk: Dictionary = walkers[id]
		var f = figures.get(id)
		if f == null:
			walkers.erase(id)
			continue
		var node: Node3D = f.node
		var left: float = wk.len - wk.s
		var v := minf(float(wk.v) + 1.6 * dt, float(wk.pace))
		v = minf(v, sqrt(2.0 * 1.2 * maxf(left, 0.0)) + 0.1)
		wk.v = v
		wk.s = minf(float(wk.s) + v * dt, float(wk.len))
		var here: Vector3 = Nav.at(wk.path, wk.s)[0]
		node.position = Vector3(here.x, 0.0, here.z)
		var ahead: Vector3 = Nav.at(wk.path, minf(float(wk.s) + 0.6, float(wk.len)))[0] - here
		if Vector2(ahead.x, ahead.z).length() > 0.05:
			node.rotation.y = lerp_angle(node.rotation.y, atan2(-ahead.x, -ahead.z), 1.0 - exp(-dt * 7.0))
		if wk.anim != null:
			(wk.anim as AnimationPlayer).speed_scale = v / float(wk.stride)
		for d in wk.doors:
			if d[2] == 0 and wk.s >= float(d[1]) - 1.0:
				pub.swing_door(d[0], true)
				d[2] = 1
			elif d[2] == 1 and wk.s >= float(d[1]) + 1.0:
				pub.swing_door(d[0], false)
				d[2] = 2
		if wk.s >= float(wk.len) - 0.001:
			_walked(id)


func _walked(id: String) -> void:
	var wk: Dictionary = walkers[id]
	walkers.erase(id)
	for d in wk.doors:
		if d[2] == 1:
			pub.swing_door(d[0], false)
	var f = figures.get(id)
	if f != null:
		(f.node as Node3D).queue_free()
		figures.erase(id)
	# standing where the walk was for (if the night's moved them on since, that's the next walk)
	if not (wk.to as Array).is_empty():
		var now: Array = want.get(id, [])
		want[id] = wk.to
		_place(id)
		want[id] = now
	walked.emit(id)


func _stop_walks() -> void:
	for id in walkers.keys():
		for d in walkers[id].doors:
			if d[2] == 1:
				pub.swing_door(d[0], false, true)
		var f = figures.get(id)
		if f != null:
			(f.node as Node3D).queue_free()
			figures.erase(id)
	walkers.clear()


func _seated(spot: String) -> bool:
	return (spot.begins_with("t28_") and spot != "t28_stand" and spot != "t28_behind5") or (spot.begins_with("bar_s") and spot != "bar_s6_stand") \
		or spot.begins_with("table_") or spot.begins_with("deck_chair")


# where someone going goes: the three from the pickup back to it while it's there, everyone else out
# of the door and off across the lot
func _goes_to(id: String) -> Vector3:
	if away.has(id):
		return WC_FRONT
	var var_of := {"hoodie": "kid_at", "driver": "sister_at", "vape": "vape_at"}
	if var_of.has(id) and pickup_here and _spot_of(_v, var_of[id]) == "s_truck":
		return _truck_door("truck_wheel" if id == "driver" else "truck_back")
	return OFF_INTO


# beside the pickup's door for a seat in it: the driver's on the left, the back on the right
func _truck_door(spot: String) -> Vector3:
	var t: Node3D = pub.dyn.truck
	var local := Vector3(-1.25, 0, -0.2) if spot == "truck_wheel" else Vector3(1.25, 0, 0.75)
	var p := t.to_global(local)
	return Vector3(p.x, 0.0, p.z)


# where someone coming to the door comes from: out in the lot, the nearest place he can't see
func _comes_from() -> Vector3:
	for p in COMES_FROM:
		if not in_sight(p + Vector3(0, 1.2, 0), "lot"):
			return p
	return COMES_FROM[COMES_FROM.size() - 1]


# Put a figure where it's wanted, now.
func _place(id: String) -> void:
	var w: Array = want.get(id, [])
	var f = figures.get(id)
	if w.is_empty():
		if f != null:
			if str(f.spot) != "" and _seated(f.spot):
				_scrape(f.spot)
			(f.node as Node3D).queue_free()
			figures.erase(id)
		return
	var spot: String = w[0]
	var model: String = w[1]
	var s: Dictionary = SPOTS[spot]
	_from_wc.erase(id)
	# a stool scraped as someone gets up off it, or sits down on one
	var was := str(f.spot) if f != null else ""
	if was != spot:
		if was != "" and _seated(was):
			_scrape(was)
		if _seated(spot):
			_scrape(spot)
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
		f.rigged = life.add(id, holder, body, an, _seated(spot))
		figures[id] = f
	var node: Node3D = f.node
	if s.get("in", "") == "truck":
		if node.get_parent() != pub.dyn.truck:
			node.reparent(pub.dyn.truck, false)
		node.transform = Transform3D(Basis.IDENTITY, s.pos + Vector3(0, float(s.get("y", 0.0)), 0))
	else:
		# in the town, they're put away with it while he's at the Sov
		var holder: Node3D = pub.town.far if s.get("in", "") == "town" and pub.town != null else self
		if node.get_parent() != holder:
			node.reparent(holder, false)
		var pos: Vector3 = s.pos + Vector3(0, float(s.get("y", 0.0)) + _sit_offset(model, spot), 0)
		node.transform = Transform3D.IDENTITY
		node.position = pos
		var face: Vector3 = s.face
		if Vector2(face.x - pos.x, face.z - pos.z).length() > 0.01:
			node.look_at(Vector3(face.x, pos.y, face.z), Vector3.UP)
		_seat_on(node, s, f.anchors)
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


# Sitting on something of the town's (a chair, the freezer): the point of them that sits on things
# (their model's "seat") on the seat, its height over the spot. Without one, where they stand.
func _seat_on(node: Node3D, s: Dictionary, an: Dictionary) -> void:
	if not s.has("seat") or not an.has("seat"):
		return
	var a: Array = an.seat
	node.position = s.pos + Vector3(0, float(s.seat), 0) - node.basis * Vector3(a[0], a[1], a[2])


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


# Where the front of someone's chest is, in the world (for a thing handed back to them).
func chest_of(id: String) -> Vector3:
	var f = figures.get(SPEAKS_FOR.get(id, id))
	if f == null:
		return Vector3.INF
	var c: Array = f.anchors.get("chest", [0, 1.25, -0.1])
	return (f.node as Node3D).to_global(Vector3(c[0], c[1], c[2]))


# Where the people are on the floor (not the two in the pickup), for him to walk round.
func standing() -> Array:
	var out: Array = []
	for id in figures:
		var n: Node3D = figures[id].node
		if n.get_parent() == self:
			out.append(n.global_position)
	return out


func figure_zone(id: String) -> String:
	var key: String = SPEAKS_FOR.get(id, id)
	var f = figures.get(key)
	if f == null:
		return ""
	if walkers.has(key) or f.spot == "":
		return Hotspots.zone_of((f.node as Node3D).global_position + Vector3(0, 1.2, 0))
	return SPOTS[f.spot].zone


func present(id: String) -> bool:
	return figures.has(SPEAKS_FOR.get(id, id))


# ---------------------------------------------------------------- answering the night

func arrived(_where: String) -> void:
	_settle(0.0)


# Someone speaks: their jaw goes with the line, and they look at him if they can (world/life.gd).
# Anyone without bones turns a little toward him, if he can see them.
func speaking(speaker: String, text := "") -> void:
	var id: String = SPEAKS_FOR.get(speaker, speaker)
	if away.has(id):
		_back(id)
	var f = figures.get(id)
	if f == null or view == null or walkers.has(id):
		return
	if f.get("rigged", false):
		life.speak(id, text)
		return
	var node: Node3D = f.node
	var s: Dictionary = SPOTS.get(f.spot, {})
	if node.get_parent() != self and (s.get("in", "") != "town" or s.get("still", false)):
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


# He ran across the room (game/going.gd): everyone in it turns to look, one after another the way a
# room does, and then goes back to what they were doing. Standing, they turn round to it; sitting,
# as far as a stool lets them.
func heads_to(p: Vector3) -> void:
	for id in figures:
		var f: Dictionary = figures[id]
		if walkers.has(id) or str(f.spot) == "" or not SPOTS.has(f.spot):
			continue
		if not str(SPOTS[f.spot].zone) in ["room", "vest"]:
			continue
		var node: Node3D = f.node
		if not node.is_visible_in_tree():
			continue
		if f.get("rigged", false):
			life.startle(id, p)
			continue
		var to := p - node.global_position
		var d := wrapf(atan2(-to.x, -to.z) - float(f.base_yaw), -PI, PI)
		var lim := 0.35 if _seated(f.spot) else 1.0
		if _turned.has(id) and (_turned[id] as Tween).is_valid():
			(_turned[id] as Tween).kill()
		var tw := node.create_tween()
		tw.tween_interval(randf_range(0.0, 0.45))
		tw.tween_property(node, "rotation:y", float(f.base_yaw) + clampf(d, -lim, lim), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(randf_range(2.8, 4.2))
		tw.tween_property(node, "rotation:y", float(f.base_yaw), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
		view.look_at_who(func(): return head_of(id) if present(id) else Vector3.INF)


func _process(dt: float) -> void:
	t += dt
	if not walkers.is_empty():
		_walk_on(dt)
	if not away.is_empty():
		_errands()
	doings.update(dt)
	_check -= dt
	if _check <= 0.0 and view != null:
		_check = 0.25
		_settle(0.25)
		_wander()
	# breathing, and the small shifts of people sitting a long time: the ones with bones their own
	# way, looking about as they do (world/life.gd), and anyone else bobbing
	if view != null and view.cam != null:
		var heads := {}
		for id in figures:
			if not walkers.has(id):
				heads[id] = head_of(id)
		life.update(dt, view.cam.global_position, -view.cam.global_transform.basis.z, heads)
	for id in figures:
		var f: Dictionary = figures[id]
		if f.get("rigged", false):
			continue
		var body: Node3D = (f.node as Node3D).get_node_or_null("body")
		if body == null:
			continue
		var ph: float = f.phase
		body.position.y = 0.004 * sin(t * TAU * float(f.rate) + ph)
		body.rotation.y = 0.018 * sin(t * 0.13 + ph * 2.0)


# The ones who drift, drift, when he isn't looking.
func _wander() -> void:
	for id in WANDER:
		if not figures.has(id) or not want.has(id) or want[id].is_empty() or walkers.has(id):
			continue
		if id == "bartender" and view.place == "bar":
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


# ---------------------------------------------------------------- the washroom

# Someone off to the washroom for secs (world/doings.gd): gone from their place the way anyone goes
# (walking there if he's looking, or while he isn't), and back to it after.
func errand(id: String, secs: float) -> void:
	if not figures.has(id) or away.has(id) or walkers.has(id):
		return
	away[id] = {"back": t + secs, "flushed": false, "want": want.get(id, [])}
	want[id] = []
	_settle(0.0)


# Done in there: the flush, the door, and out.
func _errands() -> void:
	for id in away.keys():
		var a: Dictionary = away[id]
		if t < float(a.back) or walkers.has(id) or figures.has(id):
			continue
		if not a.flushed:
			a.flushed = true
			a.back = t + randf_range(1.8, 2.6)
			sound.emit("flush", WC_IN + Vector3(0.6, 0.5, -0.5), 0.9, 1.5)
			continue
		sound.emit("door_wc", Vector3(WC_FRONT.x, 1.0, Pub.HALL_Z), 0.9, 1.2)
		_from_wc[id] = true
		_back(id)


var _from_wc := {}                 # the ones coming back out of the washroom, for their walk out of it


# Back to where the night wants them, from the washroom or on the way to it.
func _back(id: String) -> void:
	if not away.has(id):
		return
	want[id] = away[id].want
	away.erase(id)
	# gone already, or on the way: they come back out of the washroom (once they're in it)
	if not figures.has(id) or walkers.has(id):
		_from_wc[id] = true


# the post a place is seen best from (for "he's come to where they were")
func _post_of(w: Array) -> String:
	if w.is_empty():
		return ""
	var spot := str(w[0])
	if spot.begins_with("t28"):
		return "t28"
	if spot.begins_with("pool"):
		return "pool"
	if spot.begins_with("bar_"):
		return "bar"
	return ""


# A stool scraped on the carpet, or a chair on the deck: from where it is.
func _scrape(spot: String) -> void:
	if _quiet or view == null:
		return
	var s: Dictionary = SPOTS.get(spot, {})
	if s.is_empty() or s.get("in", "") != "":
		return
	sound.emit("stool", (s.pos as Vector3) + Vector3(0, 0.4, 0), randf_range(0.6, 0.9), 1.2)
