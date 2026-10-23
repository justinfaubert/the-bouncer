# Where he stands (or sits) in each place the Ink knows, what he's looking at when he gets there,
# the doors he walks through and the ladder and the stairs off the ground floor.
#
# The Ink's places (content/ink/main.ink, LIST where): floor, door, bar, t28, pool, hall, kitchen,
# keg, deck, lot, upstairs, and before the night, away from the Sov: office, street, esso, seawall.
# He walks between the ones on the ground floor the way world/nav.gd finds round things, through the
# doors; the keg room (down the ladder under the trapdoor) and his room upstairs are a cut, from the
# top of the ladder or the foot of the stairs. Going to or from anywhere away from the Sov is a cut
# too, from wherever he is: there's no walking across town on the page.
class_name Posts
extends RefCounted

const STAND := 1.76        # his eyes, standing: a big man, not a giant
const SIT_DOOR := 1.62     # on the stool by the door
const SIT_T28 := 1.28      # on a low stool at table 28
const LEAN_BAR := 1.62     # leaning on the bar on his forearms

# at: his eyes; look: what he's looking at when he gets there
const POSTS := {
	"door": {"at": Vector3(1.7, SIT_DOOR, 8.85), "look": Vector3(3.45, 1.25, 10.1), "seat": true},
	"floor": {"at": Vector3(7.0, STAND, 6.7), "look": Vector3(9.8, 1.0, 3.6)},
	# the bar: in the gap in its stools (Pub.SERVICE_Z), across from the bartender, leaning on it on
	# his forearms (the Ink: "He leaned on the bar in the gap in the stools where staff stood")
	"bar": {"at": Vector3(2.68, LEAN_BAR, 5.0), "look": Vector3(1.15, 1.45, 4.8), "lean": true},
	"t28": {"at": Vector3(9.08, SIT_T28, 6.97), "look": Vector3(9.55, 0.95, 8.4), "seat": true},
	"pool": {"at": Vector3(7.85, STAND, 5.5), "look": Vector3(10.2, 0.9, 3.9)},
	"hall": {"at": Vector3(7.3, STAND, -0.6), "look": Vector3(15.2, 1.3, -0.62)},
	"kitchen": {"at": Vector3(3.7, STAND, -1.35), "look": Vector3(0.45, 1.05, -2.25)},
	"keg": {"at": Vector3(3.42, -2.5 + STAND, 4.35), "look": Vector3(3.42, -1.7, -1.5)},
	"deck": {"at": Vector3(17.5, STAND, 8.7), "look": Vector3(21.0, 0.6, 30.0)},
	"lot": {"at": Vector3(8.0, STAND, 23.0), "look": Vector3(5.0, 5.2, 10.1)},
	"upstairs": {"at": Vector3(14.1, 3.4 + 1.62, 7.1), "look": Vector3(14.6, 3.4 + 1.1, 9.95), "seat": true},
	# Away from the Sov (world/town.gd). Gary's office: Gary's eyes, in his chair behind the desk,
	# on whoever's in the chair across it
	"office": {"at": Town.GARY, "look": Town.VISITOR, "seat": true},
	# on the sidewalk at the foot of Gary's porch, down the old main street to the highway and the
	# harbour
	"street": {"at": Town.STREET_EYE, "look": Vector3(-200.0, 1.2, 40.0)},
	# under the Esso's canopy at its edge by the road, across the pumps to the store and the kid on
	# the ice freezer by its door (the Sov's sign is down the highway, a turn of his head away)
	"esso": {"at": Vector3(-150.0, Town.APRON + STAND, 25.0), "look": Vector3(-147.8, Town.APRON + 1.5, 12.5)},
	# sitting on the seawall across the highway from the Sov, its front and the sign on its roof
	"seawall": {"at": Vector3(8.0, 1.37, 35.75), "look": Vector3(7.0, 5.6, 10.3), "seat": true},
}

# the places away from the Sov: going to or from any of them, the page goes blank and he's there
const AWAY := ["office", "street", "esso", "seawall"]

# The one arrival where the place turns his head (game/view.gd): the first time he comes to the Sov
# from the town, across the highway from the seawall or down from his room and round the front, he's
# facing its front in the lot, the door and the windows and the sign; he's never seen it close up.
# His room on the way doesn't count; anywhere else at the Sov first, and it's been seen. After that
# he's still looking the way he was, wherever he gets to.
const FIRST_SIGHT := {"place": "lot", "look": Vector3(5.0, 5.2, 10.1), "through": ["upstairs"]}

# The doorways he walks through: the middle of each on the floor, and the door in it that opens as
# he comes to it (Pub.swing_door) and swings to behind him. A door the night's propped open (the
# deck door on its coaster, the hotel door on its wedge) goes back to how it was propped.
const DOORWAYS := {
	"main": Vector3(3.2, 0, 10.1),
	"swing": Vector3(3.25, 0, -0.1),
	"deck": Vector3(16.1, 0, 7.1),
	"hotel": Vector3(16.1, 0, -0.6),
}

# Off the ground floor: where he stands to go down the ladder through the trapdoor behind the bar,
# or up the hotel stairs from beside the front desk, on the floor, and what he looks at there.
const FLIGHTS := {
	"keg": {"from": Vector3(1.05, 0, 1.12), "look": Vector3(1.05, 0.0, 1.9)},
	"upstairs": {"from": Vector3(16.75, 0, -1.35), "look": Vector3(17.6, 1.0, -2.2)},
}


# Where each place in the bar is on its floor, for going there by pointing at it (game/going.gd): a
# spot inside one of these is that place, and anywhere else on the floor of the room is just the
# floor. Round ones are [x, z, radius]; the rest [x0, z0, x1, z1]; the first one a spot's in is
# the one. Behind the bar, the trapdoor; the stool by the door (and the vestibule, past it); the
# bar, its stools and the gap in them, and behind it; table 28 and its six stools; the pool table
# and the room round it a cue needs; the jukebox, by the pool table. The parts of the building off
# the room are their places whole (game/hotspots.gd's zones): the back hall, the kitchen, the
# deck, the lot.
const AREAS := {
	"keg": [1.05, 1.9, 0.6],
	"door": [1.7, 8.85, 1.05],
	"bar": [0.3, 0.9, 3.05, 7.75],
	"t28": [9.4, 8.1, 1.6],
	"pool": [7.55, 2.65, 11.25, 5.15],
	"pool:juke": [13.2, 0.75, 0.85],
}
const ZONE_AREAS := {"vest": "door", "hall": "hall", "kitchen": "kitchen", "deck": "deck", "lot": "lot"}

# Back onto the floor from somewhere off the room: just inside it, through the way he came (from
# anywhere in the room he steps back off where he was instead: game/view.gd). From the back hall
# and from upstairs, through the hall's doorway; the deck's door; the main door from the lot; from
# the kitchen, a step or two out past its swing door, and up the ladder behind the bar, round its
# end and out from it. Each is somewhere he can see everything the floor offers from (the clutter
# on the bar's end mustn't hide the ledge by the door, nor the vestibule's corner the sign on its
# wall): tests/floor_sight.gd finds such spots, and tests/reach.gd checks them.
const FLOOR_FROM := {
	"hall": Vector3(6.5, 0.0, 1.35), "upstairs": Vector3(6.5, 0.0, 1.35), "kitchen": Vector3(4.0, 0.0, 2.0),
	"deck": Vector3(14.7, 0.0, 7.0), "lot": Vector3(3.6, 0.0, 8.0), "keg": Vector3(3.6, 0.0, 2.0),
}


# A place seen more than one way. The lot: the whole building from across the gravel when he
# arrives; the pickup's driver's window, the glass fogged; the step under the light over the door
# at the end, the big man at his truck by the beer store. The back hall: through the hotel door to
# the front desk, while he talks to the night clerk; round the corner at the end of it, the dead
# payphone and the wall of numbers round it. The pool table: the jukebox past it, on the back wall,
# round behind whoever's standing at it. Table 28: standing at the end of it, behind the stool,
# until he sits down with them. Away from the Sov: from Gary's chair, the doorway and the bookkeeper
# (he only turns his head: the same chair); down at the harbour, the old man at the wharf's rail;
# along the highway, the Esso coming and the Sov's sign down the road; at the Esso, the kid on the
# ice freezer.
const FRAMES := {
	"t28:stand": {"at": Vector3(9.05, STAND, 6.38), "look": Vector3(9.5, 1.0, 8.3)},
	"hall:clerk": {"at": Vector3(16.85, STAND, -0.5), "look": Vector3(18.3, 1.42, -0.62)},
	"hall:phone": {"at": Vector3(13.9, STAND, -1.65), "look": Vector3(13.86, 1.45, -2.64)},
	"pool:juke": {"at": Vector3(14.1, STAND, 1.6), "look": Vector3(13.2, 1.5, 0.27)},
	"lot:arrive": {"at": Vector3(8.0, STAND, 23.0), "look": Vector3(5.0, 5.2, 10.1)},
	"lot:pickup": {"at": Vector3(8.17, STAND, 17.17), "look": Vector3(8.75, 1.3, 15.99)},
	"lot:truck": {"at": Vector3(3.3, STAND, 11.0), "look": Vector3(-3.0, 1.2, 13.4)},
	# Gary's office, from his chair: the doorway, where the man stands as he comes in, and round to
	# the bookkeeper at her desk against the wall
	"office:door": {"at": Town.GARY, "look": Town.DOORWAY, "seat": true},
	"office:bk": {"at": Town.GARY, "look": Town.BOOKKEEPER, "seat": true},
	# out at the end of the government wharf, a few steps behind the old man at its rail under the light
	"street:wharf": {"at": Vector3(-199.9, Town.WHARF_Y + STAND, 90.9), "look": Vector3(-198.1, Town.WHARF_Y + 1.45, 93.6)},
	# on the highway's shoulder past the foot of the street, the seawall on his right, looking north
	# along it: the Esso first, on the left, and the Sov's sign a long way down
	"street:highway": {"at": Vector3(-186.0, STAND, 34.3), "look": Vector3(-140.0, 2.5, 20.0)},
	# out from under the canopy, the kid on the ice freezer by the store's door
	"esso:kid": {"at": Vector3(-149.6, Town.APRON + STAND, 15.3), "look": Vector3(-147.3, Town.APRON + 1.6, 12.45)},
}


static func post(place: String, frame := "") -> Dictionary:
	if frame != "" and FRAMES.has(place + ":" + frame):
		return FRAMES[place + ":" + frame]
	return POSTS.get(place, POSTS["door"])


static func away(place: String) -> bool:
	return place in AWAY


# the place in the bar a spot on its floor is part of (AREAS, then the part of the building it's
# in), or "floor" for the open floor of the room, or "" for nowhere he goes by pointing
static func area_of(p: Vector3, zone: String) -> String:
	if zone in ["room", "vest"]:
		for k in AREAS:
			var a: Array = AREAS[k]
			if a.size() == 3:
				if Vector2(p.x - a[0], p.z - a[1]).length() <= a[2]:
					return k
			elif p.x >= a[0] and p.x <= a[2] and p.z >= a[1] and p.z <= a[3]:
				return k
	if ZONE_AREAS.has(zone):
		return ZONE_AREAS[zone]
	return "floor" if zone == "room" else ""


# The doorways on a way across the floor, and how far along it each is: [door, metres, 0] (the 0
# for whoever's walking it to mark the door opened, then swung to).
static func doors_on(path: PackedVector3Array) -> Array:
	var out: Array = []
	for which in DOORWAYS:
		var c: Vector3 = DOORWAYS[which]
		var best := INF
		var best_s := 0.0
		var s := 0.0
		for i in range(1, path.size()):
			var a := path[i - 1]
			var b := path[i]
			var seg := a.distance_to(b)
			var k := 0.0
			if seg > 0.0001:
				k = clampf((c - a).dot(b - a) / (seg * seg), 0.0, 1.0)
			var q := a.lerp(b, k)
			var d := Vector2(q.x - c.x, q.z - c.z).length()
			if d < best:
				best = d
				best_s = s + seg * k
			s += seg
		if best < 0.6:
			out.append([which, best_s, 0])
	return out


# yaw and pitch that look from `at` toward `target` (yaw round +y from -z, as the camera takes it)
static func aim(at: Vector3, target: Vector3) -> Vector2:
	var d := (target - at).normalized()
	return Vector2(atan2(-d.x, -d.z), asin(clampf(d.y, -1.0, 1.0)))
