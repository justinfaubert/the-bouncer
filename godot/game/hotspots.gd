# Looking as choosing. The choices on offer are in the room as well as in the column: each one that's
# about something he can see (the kid's phone, the truck, the big man, the propped door, the way to
# the bar) is pinned to that thing. When his eyes rest on it (the pointer on it, or the middle of
# his view when he turns his head with the keys) the thing is ringed, the choice lights in the
# column, a voice may lean in on it there in the room (game/hand.gd), and the choice's words come up
# beside it. A click on it, or E, makes that choice. Everything else he can see that nothing on offer
# is about (the dartboard, the tape by the door, the sign on the roof: content/data/things.yaml) is
# there to look at: its name comes up, fainter, and a click hands it to the Ink (content/ink/
# things.ink), which says what he sees. The clock doesn't move for a look.
#
# What a choice is about is found from its words: the lexicon below names things by the words the
# Ink uses for them, and a move names its place. When the thing's somewhere he can't see from here
# (the kitchen from the bar, everything from the keg room), a choice that takes him there is pinned
# to the way he'd go: the door, the opening, the ladder; and so is one that takes him somewhere
# else about a thing that's here (the kitchen, about the rats). A choice nothing in sight answers
# to stays in the column only.
#
# What he can see from where he is: the part of the building he's in, and another part only
# through the openings between them (the room from the back hall is what's through its doorway;
# the front desk is through the hotel door when it's propped; from the deck, the lot is what's
# past the corner of the building). Inside one part, a few things are
# hidden by what's in the way (the trapdoor behind the bar), and pinned to where he'd look for
# them instead (the air over it); tests/reach.gd checks every pin against a solid copy of the room.
class_name Hotspots
extends Node

# words in a choice, to the thing in the room they're about (first match wins, so the specific go
# before the general); "a|b": a, or if that's not there or not in sight, b
const LEXICON := [
	["payphone|numbers on the wall|receiver", "a:payphone|a:hall_end"],
	# before the night, in Gary's office and on the walk (world/town.gd)
	["photo behind|1958", "a:office_photo"],
	["gary's desk|upside down", "a:office_notice"],
	["bookkeeper", "fig:bookkeeper"],
	["wharf", "a:street_wharf"],
	["the esso|something to eat", "a:esso_window"],
	["\\bphone\\b|photo|screen|swipe", "fig:hoodie:phone"],
	["good shoes", "fig:goodshoes"],
	["licen[cs]e|\\bid\\b|\\bcard\\b|birthday", "at_door|door_post"],
	["sister|kayla|at the wheel|the driver", "fig:driver|at_door"],
	["boyfriend|vape", "fig:vape"],
	["\\bkid\\b|hood|tyler", "fig:hoodie|fig:essokid"],
	["truck|pickup|headlight", "a:truck"],
	["raincoat|wife", "fig:raincoat"],
	["glasses|dennis", "fig:glasses|a:t28"],
	["\\bscratch\\b|lotto|ticket", "fig:scratch"],
	["cardigan|the rail", "fig:cardigan|a:deck_rail"],
	["hearing aid", "fig:hearing_aid"],
	["team jacket", "fig:team_jacket"],
	["here, at the table", "a:pool_table|fig:bigman"],
	["table 28|the table|twenty-eight|sit down with them|the last one", "a:t28"],
	["buddy", "fig:buddy"],
	["pool table|watch them play", "a:pool_table|fig:bigman"],
	["big man|pool|\\bcue\\b|the game|next game|his keys|your daughter", "fig:bigman|a:pool_table"],
	["constable|police|officer", "fig:constable"],
	["hi-vis|work crew|the crew", "fig:hivis"],
	["end of the bar|flat ?cap|walter|rat king|the old man", "fig:endbar|p:2.15,1.15,1.6"],
	["heat lamp", "a:pass"],
	["\\bcook\\b|fryer", "fig:cook|a:fryer"],
	["kitchen door|back door|propped|brick|dumpster|\\bbins?\\b|garbage|alley", "a:kitchen_back"],
	["terry|night clerk", "fig:terry"],
	["hotel door|hotel stairs|wedge", "a:hotel_door"],
	["slippers|from upstairs", "fig:slippers"],
	["\\brats?\\b|the hole|behind the wall|poison|\\btraps?\\b|scratching|crawlspace", "rat_hole"],
	["deck door|coaster|latch", "a:deck_door"],
	["jukebox|\\bsong\\b|music", "a:jukebox"],
	["washroom|stall|the single|occupied|right in there|back to the door|with a coin", "a:wc_single"],
	["the men's", "a:wc_men"],
	["the women's", "a:wc_women"],
	["trapdoor|trap door|ladder", "a:keg_ladder|a:trap_over"],
	["\\bkegs?\\b|lager|lines|office|mirror|\\bbait\\b", "a:kegs"],
	["walk-in", "a:walk_in"],
	["\\btape\\b|the date|nineteen", "a:tape"],
	["scanner|\\bscan", "a:scanner"],
	["\\btill\\b|binder|86|eighty-six|page three|the faces", "a:till"],
	["bartender|pour me|another\\.|a drink|a rye|tab\\b", "fig:bartender"],
	["incident|the book|write it|the log|leave it out", "a:ledge"],
	["\\btv\\b|hockey", "a:tv"],
	["dart", "a:dartboard"],
	["window", "p:10.2,1.65,10.1"],
	["\\bstool\\b|sit back down|your post|the door\\b|front door|at the door|lock", "door_post"],
	["\\bbed\\b|sleep|lie down", "a:his_bed"],
]
# where each place is, for the ways out of the one he's in
const WAYS := {
	"door": "door_post", "floor": "p:7.6,1.0,5.6", "bar": "a:bar_top", "t28": "a:t28", "pool": "a:pool_table",
	"hall": "a:hall_way", "kitchen": "a:swing_door", "keg": "a:trap_over", "deck": "a:deck_door",
	"lot": "a:truck|a:main_door", "upstairs": "a:hotel_door",
}
# the part of the building each place is in (and before the night, away from it: Gary's front
# room, and the town round it, world/town.gd)
const PART := {"door": "vest", "floor": "room", "bar": "room", "t28": "room", "pool": "room", "hall": "hall",
	"kitchen": "kitchen", "keg": "keg", "deck": "deck", "lot": "lot", "upstairs": "upstairs",
	"office": "office", "street": "town", "esso": "town", "seawall": "town"}
# the way out of somewhere closed in, whichever way he's going (from the front desk, the hotel door)
const WAY_OUT := {"keg": "a:keg_ladder", "kitchen": "a:swing_door", "deck": "a:deck_door", "lot": "a:main_door",
	"hall": "a:hall_way", "hall:clerk": "a:hotel_door"}
# and from the room, the way toward the places it can't see into
const TOWARD := {"hall": "a:hall_way", "upstairs": "a:hall_way", "lobby": "a:hall_way", "kitchen": "a:swing_door",
	"keg": "a:trap_over", "deck": "a:deck_door", "lot": "a:main_door"}
# the doors and openings between two parts of the building, seen from either side
const BETWEEN := {"a:swing_door": ["room", "kitchen"], "a:hall_way": ["room", "hall"], "a:deck_door": ["room", "deck"],
	"a:main_door": ["vest", "lot"], "a:hotel_door": ["hall", "lobby"]}
# the parts of the building with nothing between them: the room and the vestibule; the town and
# the lot, across the highway
const OPEN := ["room|vest", "town|lot"]
# and the openings he sees one part from another through, any other two being walled off from each
# other: [part, part, corner, corner, the door in it if it's only open when that is], each a
# rectangle down the middle of a wall 0.2 thick. The back hall's doorway; the main door (glass) and
# the front window; the hotel door, propped or not; the deck's open end, past the corner of the
# building (the lot round the front is behind it); his window over the lot.
const OPENINGS := [
	["room", "hall", Vector3(5.9, 0.0, -0.1), Vector3(7.1, 2.3, -0.1), ""],
	["room", "lot", Vector3(2.3, 0.0, 10.1), Vector3(4.1, 2.3, 10.1), ""],
	["vest", "lot", Vector3(2.3, 0.0, 10.1), Vector3(4.1, 2.3, 10.1), ""],
	["room", "lot", Vector3(6.2, 0.9, 10.1), Vector3(12.6, 2.4, 10.1), ""],
	["hall", "lobby", Vector3(16.1, 0.0, -1.04), Vector3(16.1, 2.05, -0.16), "hotel_door"],
	["deck", "lot", Vector3(16.35, 0.0, 10.05), Vector3(40.0, 2.75, 10.05), ""],
	["upstairs", "lot", Vector3(14.1, 3.85, 10.17), Vector3(15.1, 5.15, 10.17), ""],
	# Gary's front window and the glass in his front door, on the street
	["office", "town", Vector3(Town.OFFICE_X - 0.1, Town.OFFICE_Y + 0.8, Town.OFFICE_Z + 0.35), Vector3(Town.OFFICE_X - 0.1, Town.OFFICE_Y + 2.25, Town.OFFICE_Z + 1.75), ""],
	["office", "town", Vector3(Town.OFFICE_X - 0.1, Town.OFFICE_Y + 1.07, Town.OFFICE_Z - 1.41), Vector3(Town.OFFICE_X - 0.1, Town.OFFICE_Y + 1.99, Town.OFFICE_Z - 0.79), ""],
]
# what's round a corner or behind something from where he stands (place, or place:frame), in a part
# of the building he otherwise sees from there: the payphone at the end of the back hall, the tape
# on the door frame from table 28 (the screen's in the way), the hockey on the back wall from the end
# of table 28 standing (the pool table's light is in the way), the hotel door from the payphone, and
# from the door out to the lot, his window along the front (the next one's frame is in the way) and
# the sign on the roof (straight up)
const HIDDEN := {"a:payphone": ["hall", "hall:clerk"], "a:tape": ["t28"], "a:tv": ["t28:stand"], "a:hotel_door": ["hall:phone"],
	"a:his_window": ["lot:truck"], "a:roof_sign": ["lot:truck"]}
# a choice that names one of the voices in his head is about him, not anything in the room
static var _voice_name := RegEx.create_from_string("\\bTHE (FATHER|MANUAL|WRONG MAN|FIGHTER|TABLE|KID|CIRCLE)\\b")

var main
var spots: Array = []            # [{i, key, text, loc}]
var things := {}                 # id -> {name, at, from}: what he can look at (content/data/things.yaml)
var under = null                 # the spot his eyes are on: {key, at: Vector2, list: [i...], look: id or ""}
var overlay: Control
var caption: PanelContainer
var cap_box: VBoxContainer
var _t := 0.0
var _on_caption := false
var _res := {}


func setup(m) -> void:
	main = m
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.anchor_right = View.WORLD_W
	overlay.anchor_bottom = 1.0
	main.root.add_child(overlay)
	overlay.draw.connect(_draw)
	caption = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Look.NIGHT, 0.9)
	sb.border_color = Color(Look.STOCK, 0.35)
	sb.border_width_left = 2
	sb.set_content_margin_all(10)
	sb.content_margin_left = 14
	caption.add_theme_stylebox_override("panel", sb)
	caption.visible = false
	caption.mouse_filter = Control.MOUSE_FILTER_STOP
	caption.mouse_entered.connect(func(): _on_caption = true)
	caption.mouse_exited.connect(func(): _on_caption = false)
	cap_box = VBoxContainer.new()
	cap_box.add_theme_constant_override("separation", 4)
	caption.add_child(cap_box)
	main.root.add_child(caption)
	for pair in LEXICON:
		_res[pair[0]] = RegEx.create_from_string("(?i)" + pair[0])
	things = main.content.get("things", {})


# the choices on offer have changed: pin each to what it's about
func refresh() -> void:
	clear()
	if not main.in_game or main.game.ended or main.game.story == null:
		return
	var list: Array = main.game.visible_choices()
	for i in list.size():
		var c: Dictionary = list[i]
		var key := _about(c)
		if key != "":
			spots.append({"i": i, "key": key, "text": str(c.get("text", "")), "loc": loc_of(c)})


func clear() -> void:
	spots.clear()
	_set_under(null)


# where a choice happens (its #loc), or "" (the engine has null for none)
static func loc_of(c: Dictionary) -> String:
	var l = c.get("loc")
	return "" if l == null else str(l)


func _about(c: Dictionary) -> String:
	var loc := loc_of(c)
	var away: bool = loc != "" and loc != main.view.place
	var text := str(c.get("text", ""))
	if str(c.get("cls", "")) == "move" and away:
		# a spot in a place, not the place (the jukebox, by the pool table)
		return "a:jukebox" if text.containsn("jukebox") else WAYS.get(loc, "")
	if _voice_name.search(text) != null:
		return ""
	for pair in LEXICON:
		if (_res[pair[0]] as RegEx).search(text) != null:
			return pair[1]
	# somewhere to go, said some other way ("The bar.", "Out on the smoking deck.")
	return WAYS.get(loc, "") if away else ""


# What a choice on offer is pinned to now, from where he is: [position, radius, key], or [] for
# nothing he can see from here (it stays in the column). The thing it's about, if he can see it
# (and if the choice takes him somewhere, it's there); failing that, if it takes him somewhere, the
# place, or the way he'd go to get there; or if it's about something in a part of the building he
# can't see into, and isn't something said, the way into there.
func resolve(s: Dictionary) -> Array:
	var loc := str(s.get("loc", ""))
	var going: bool = loc != "" and loc != main.view.place
	var w := _first_seen(str(s.key))
	if not w.is_empty() and (not going or _in_part(str(w[2]), w[0], str(PART.get(loc, "")))):
		return w
	if going:
		w = _first_seen(str(WAYS.get(loc, "")))
		if not w.is_empty():
			return w
		return _first_seen(_way_to(loc))
	if str(s.get("text", "")).begins_with("\""):
		return []
	for k in str(s.key).split("|"):
		var at := _where(k)
		if not at.is_empty():
			var z: String = _zones(k, at[0])[0]
			return [] if z == zone_of(main.view.eye_pos) else _toward(z)
	return []


# whether a thing's in a part of the building (the room and the vestibule are one, for this)
func _in_part(key: String, p: Vector3, part: String) -> bool:
	for z in _zones(key, p):
		if z == part or (z in ["room", "vest"] and part in ["room", "vest"]):
			return true
	return false


# the part of the building a thing's in, or the two a door's between
func _zones(key: String, p: Vector3) -> Array:
	return BETWEEN.get(key, [zone_of(p)])


# the way toward a part of the building he can't see into from here: a door or opening into it
# that he can see, or from the room, the way he'd go
func _toward(zone: String) -> Array:
	for k in BETWEEN:
		if zone in BETWEEN[k]:
			var w := _first_seen(k)
			if not w.is_empty():
				return w
	return _first_seen(str(TOWARD.get(zone, "")))


func _way_to(loc: String) -> String:
	var here: String = main.view.place
	if here == "hall" and loc == "upstairs":
		return "a:hotel_door"
	var framed := here + ":" + str(main.view.frame)
	if WAY_OUT.has(framed):
		return WAY_OUT[framed]
	if WAY_OUT.has(here):
		return WAY_OUT[here]
	return TOWARD.get(loc, "")


# the first of "a|b" that's there and that he could see from here
func _first_seen(key: String) -> Array:
	if key == "":
		return []
	var post: String = main.view.place + (":" + str(main.view.frame) if str(main.view.frame) != "" else "")
	for k in key.split("|"):
		if post in HIDDEN.get(k, []):
			continue
		var w := _where(k)
		if not w.is_empty() and seen_from_here(k, w[0]):
			return [w[0], w[1], k]
	return []


# Where a thing he can look at is, if he can look at it from here: [where, size, key], or []. Its
# entry can say where it's to be looked at from (things.yaml's from: the room's things are for
# looking at in the room, not through the window from the lot); "room" is any post in it, the
# door's too.
func look_spot(id: String) -> Array:
	var t: Dictionary = things.get(id, {})
	var from: Array = t.get("from", [])
	var place: String = main.view.place
	if not from.is_empty() and not (place in from or ("room" in from and str(PART.get(place, "")) in ["room", "vest"])):
		return []
	return _first_seen(str(t.get("at", "")))


# Whether a thing's somewhere he could see from here, if he turned his head: in the part of the
# building he's in, or one open to it, or through an opening into the part it's in. On the way
# somewhere, anything in the room.
func seen_from_here(key: String, p: Vector3) -> bool:
	var view: View = main.view
	var seen: Array = Stage.SEEN.get(view.place, [])
	var mine := zone_of(view.eye_pos)
	for z in _zones(key, p):
		if view.walking:
			if z in seen or z in ["room", "vest"]:
				return true
			continue
		if z == mine:
			return true
		if not z in seen:
			continue
		if (mine + "|" + z) in OPEN or (z + "|" + mine) in OPEN:
			return true
		for o in OPENINGS:
			if not ((o[0] == mine and o[1] == z) or (o[1] == mine and o[0] == z)):
				continue
			var door: Node3D = main.pub.dyn.get(o[4]) if o[4] != "" else null
			if door != null and absf(door.rotation.y) < 0.5:
				continue
			if _through(view.eye_pos, p, o[2], o[3]):
				return true
	return false


# whether the line from a to b goes through a rectangle down the middle of a wall (through both
# its faces, 0.2 apart), or ends in it
static func _through(a: Vector3, b: Vector3, c0: Vector3, c1: Vector3) -> bool:
	var ax := 2 if absf(c0.z - c1.z) < 0.001 else 0
	var d: float = b[ax] - a[ax]
	if absf(d) < 0.0001:
		return false
	for face in [-0.1, 0.1]:
		var t: float = (c0[ax] + face - a[ax]) / d
		if t > 1.0:
			continue
		if t < 0.0:
			return false
		var h := a.lerp(b, t)
		for k in [0, 1, 2]:
			if k != ax and (h[k] < minf(c0[k], c1[k]) or h[k] > maxf(c0[k], c1[k])):
				return false
	return true


# and whether it's in front of him now
func _in_view(key: String, p: Vector3) -> bool:
	for z in _zones(key, p):
		if main.stage.in_sight(p, z):
			return true
	return false


# where a spot's thing is now, in the world, and how big: [position, radius in metres], or []
func _where(key: String) -> Array:
	var stage: Stage = main.stage
	var pub: Pub = main.pub
	if key.begins_with("fig:"):
		var bits := key.split(":")
		var id := bits[1]
		if not stage.present(id):
			return []
		var f = stage.figures.get(id)
		if bits.size() > 2:
			var an: Dictionary = f.anchors
			if not an.has(bits[2]):
				return []
			var a: Array = an[bits[2]]
			return [(f.node as Node3D).to_global(Vector3(a[0], a[1], a[2])), 0.1]
		var head := stage.head_of(id)
		var base := (f.node as Node3D).global_position
		# the chest, not the middle: the bartender's behind the bar, and from the floor the
		# counter's edge is higher than her waist
		return [base.lerp(head, 0.8), 0.42]
	if key.begins_with("a:"):
		var n := key.substr(2)
		if not pub.anchors.has(n):
			return []
		# a thing that comes and goes (the pickup, the work truck): not there when it's gone
		var node = pub.dyn.get(n)
		if node is Node3D and not (node as Node3D).visible:
			return []
		var r := 0.35
		match n:
			"truck":
				r = 1.6
			"work_truck":
				r = 1.2
			"t28", "pool_table", "store", "roof_sign":
				r = 1.0
			"his_window", "up_window":
				r = 0.6
			"tape", "scanner", "till":
				r = 0.14
			"trap_over":
				r = 0.4
			"trapdoor", "deck_door", "kitchen_back", "wc_single", "wc_men", "wc_women", "main_door", "hotel_door", "swing_door", "hall_way":
				r = 0.5
			# away from the Sov (world/town.gd): Gary's front room, then the town
			"bk_mug", "office_lamp", "office_notice":
				r = 0.12
			"office_calendar", "office_licence", "office_shirts":
				r = 0.24
			"office_safe", "office_photo":
				r = 0.4
			"office_window":
				r = 0.7
			"esso_ice", "street_gun":
				r = 0.8
			"esso_prices", "street_pickup":
				r = 1.4
			"esso_window", "street_library", "street_legion", "street_bank":
				r = 2.2
			"esso_canopy", "street_church", "street_wharf", "seawall_water":
				r = 3.5
		return [pub.anchors[n], r]
	if key.begins_with("p:"):
		var v := key.substr(2).split(",")
		return [Vector3(float(v[0]), float(v[1]), float(v[2])), 0.5]
	match key:
		"at_door":
			for id in ["hoodie", "driver", "goodshoes", "raincoat"]:
				var f2 = stage.figures.get(id)
				if f2 != null and f2.spot == "door_front":
					var an2: Dictionary = f2.anchors
					var hand: Array = an2.get("hand_right", an2.get("hand_left", [0, 1.1, -0.3]))
					return [(f2.node as Node3D).to_global(Vector3(hand[0], hand[1], hand[2])), 0.14]
			return []
		"rat_hole":
			if main.view.place == "keg":
				return [pub.anchors.get("keg_hole", Vector3.ZERO), 0.25]
			return [pub.anchors.get("t28_wall", Vector3.ZERO), 0.3]
		"door_post":
			return [Vector3(1.7, 1.05, 9.2), 0.45]
	return []


static func zone_of(p: Vector3) -> String:
	if Town.in_office(p):
		return "office"
	if Town.in_town(p):
		return "town"
	if p.y < -0.2:
		return "keg"
	if p.y > 3.3:
		return "upstairs" if p.z < 10.1 else "lot"
	if p.z > 10.15:
		return "lot"
	if p.x > 16.15:
		return "lobby" if p.z < 1.0 else "deck"
	if p.z < -0.05:
		return "kitchen" if p.x < 4.8 else "hall"
	if p.x < 4.6 and p.z > 8.9:
		return "vest"
	return "room"


func _process(dt: float) -> void:
	_t += dt
	if (spots.is_empty() and things.is_empty()) or not main.in_game or main.game.ended or main.menus.is_open() or main.pending != null \
			or main.rolling != null or main.props.holding():
		if under != null and not _on_caption:
			_set_under(null)
		return
	if _on_caption:
		_place_caption()
		return
	var view: View = main.view
	var sheet: TextureRect = view.sheet
	var probe: Vector2
	var by_pointer := view.pointer.x >= 0.0
	if by_pointer:
		probe = view.pointer / Vector2(view.eye.size) * sheet.size + sheet.global_position
	else:
		probe = sheet.global_position + sheet.size / 2.0
	var best = null
	var pinned := {}
	for s in spots:
		var w := resolve(s)
		if w.is_empty():
			continue
		pinned[s.i] = w[2]
		var c = _candidate(w, probe, by_pointer)
		if c != null and (best == null or c.d < best.d):
			best = c
	# the things he can look at, where nothing on offer is
	var taken: Array = pinned.values()
	for id in things:
		if str((things[id] as Dictionary).get("at", "")) in taken:
			continue
		var w := look_spot(id)
		if w.is_empty():
			continue
		var c = _candidate(w, probe, by_pointer)
		if c != null and (best == null or c.d < best.d):
			best = c
			best.look = id
	if best == null:
		_set_under(null)
		return
	# everything pinned to the same thing, or the same way out
	var list: Array = []
	if best.look == "":
		for s in spots:
			if pinned.get(s.i, "") == best.key:
				list.append(s.i)
	best["list"] = list
	_set_under(best)


# the ring a thing would have, if the probe's on it: {key, at, r, p, d, look}, or null
func _candidate(w: Array, probe: Vector2, by_pointer: bool):
	var p: Vector3 = w[0]
	if not _in_view(w[2], p):
		return null
	var sc: Vector3 = main.view.on_screen(p)
	if sc.z <= 0.0:
		return null
	var at := Vector2(sc.x, sc.y)
	var rpx := clampf(_px(p, w[1]), 26.0, 170.0) * (1.0 if by_pointer else 0.8)
	var d := at.distance_to(probe)
	if d >= rpx:
		return null
	return {"key": w[2], "at": at, "r": rpx, "p": p, "d": d, "look": ""}


func _px(p: Vector3, r: float) -> float:
	var view: View = main.view
	var right := view.cam.global_transform.basis.x
	var a: Vector3 = view.on_screen(p)
	var b: Vector3 = view.on_screen(p + right * r)
	if a.z <= 0.0 or b.z <= 0.0:
		return 0.0
	return Vector2(b.x - a.x, b.y - a.y).length()


func _set_under(u) -> void:
	var was = under
	var same: bool = was != null and u != null and was.key == u.key and was.look == u.look
	if same:
		under.at = u.at
		under.r = u.r
		if not under.list.is_empty():
			main.hand.eyes_on(int(under.list[0]), true, under.at)
		_place_caption()
		overlay.queue_redraw()
		return
	if was != null:
		for i in was.list:
			main.hand.eyes_on(int(i), false, Vector2.ZERO)
			var row = main.column.row_for_index(int(i))
			if row != null and row.has_method("set_looked"):
				row.set_looked(false)
	under = u
	if u == null:
		caption.visible = false
		overlay.queue_redraw()
		return
	for i in u.list:
		var row2 = main.column.row_for_index(int(i))
		if row2 != null and row2.has_method("set_looked"):
			row2.set_looked(true)
	if not u.list.is_empty():
		main.hand.eyes_on(int(u.list[0]), true, u.at)
	_build_caption()
	overlay.queue_redraw()


func _build_caption() -> void:
	for c in cap_box.get_children():
		c.queue_free()
	var look: String = under.look
	if look != "":
		# a thing to look at: its name, quieter than a choice's words
		var b := _cap_button(str((things[look] as Dictionary).get("name", look)), func(): _look(look))
		b.add_theme_color_override("font_color", Look.STOCK)
		cap_box.add_child(b)
	else:
		var list: Array = main.game.visible_choices()
		for i in under.list:
			if int(i) >= list.size():
				continue
			var c: Dictionary = list[int(i)]
			var ix := int(i)
			cap_box.add_child(_cap_button(_short(str(c.get("text", ""))), func(): _pick(ix)))
	var hint := UiBits.label("look: click, or E" if look != "" else "click, or E", "ui", 14, Look.MUTED, 2)
	cap_box.add_child(hint)
	caption.visible = true
	caption.reset_size()
	_place_caption()


func _cap_button(text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = text
	b.add_theme_font_override("font", Look.font("read"))
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Look.INK)
	b.add_theme_color_override("font_hover_color", Look.LAMP)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(300, 0)
	b.pressed.connect(fn)
	return b


func _short(s: String) -> String:
	return s if s.length() <= 90 else s.substr(0, 88).strip_edges() + "…"


func _place_caption() -> void:
	if under == null:
		return
	var sz := caption.get_combined_minimum_size()
	var p: Vector2 = under.at + Vector2(-sz.x / 2.0, -under.r - sz.y - 14.0)
	var area := Rect2(main.view.sheet.global_position, main.view.sheet.size)
	if p.y < area.position.y + 8.0:
		p.y = under.at.y + under.r + 14.0
	p.x = clampf(p.x, area.position.x + 8.0, area.end.x - sz.x - 8.0)
	p.y = clampf(p.y, area.position.y + 8.0, area.end.y - sz.y - 8.0)
	caption.position = p
	caption.size = sz


func _pick(i: int) -> void:
	_on_caption = false
	main.hand.key_on(i)
	main.choose(i)


# a click on the room: the choice his eyes are on
func click() -> void:
	if under == null:
		return
	if under.look != "":
		_look(under.look)
	elif not under.list.is_empty():
		_pick(int(under.list[0]))


# E: the choice his eyes are on, or the thing; or, if there's nothing there, pick back up what he
# put down
func use() -> void:
	if under != null and (under.look != "" or not under.list.is_empty()):
		click()
		return
	main.props.raise()


func _look(id: String) -> void:
	_on_caption = false
	main.toy(id, "look")


func _draw() -> void:
	if under == null:
		return
	var at: Vector2 = under.at - overlay.global_position
	var r: float = under.r
	# a thing to look at is ringed fainter than a choice
	var c := Color(Look.STOCK, (0.4 if under.look != "" else 0.75) + 0.2 * sin(_t * 4.0))
	# a ring drawn in dashes, turning slowly
	var n := 28
	for k in n:
		if k % 2 == 1:
			continue
		var a0 := TAU * k / n + _t * 0.4
		var a1 := TAU * (k + 1) / n + _t * 0.4
		overlay.draw_arc(at, r, a0, a1, 4, Color(Look.NIGHT, 0.6), 4.5, true)
		overlay.draw_arc(at, r, a0, a1, 4, c, 2.0, true)
