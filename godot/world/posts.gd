# Where he stands (or sits) in each place the Ink knows, what he's looking at when he gets there,
# and the ways between them on foot.
#
# The Ink's places (content/ink/main.ink, LIST where): floor, door, bar, t28, pool, hall, kitchen,
# keg, deck, lot, upstairs. He walks between the ones on the ground floor, through the doors as
# they are; the keg room (down the ladder under the trapdoor) and his room upstairs are a cut.
class_name Posts
extends RefCounted

const STAND := 1.76        # his eyes, standing: a big man, not a giant
const SIT_DOOR := 1.62     # on the stool by the door
const SIT_T28 := 1.28      # on a low stool at table 28

# at: his eyes; look: what he's looking at when he gets there; node: where he stands on the ways
const POSTS := {
	"door": {"at": Vector3(1.7, SIT_DOOR, 8.85), "look": Vector3(3.45, 1.25, 10.1), "node": "door", "seat": true},
	"floor": {"at": Vector3(7.0, STAND, 6.7), "look": Vector3(9.8, 1.0, 3.6), "node": "floor"},
	"bar": {"at": Vector3(2.95, STAND, 5.3), "look": Vector3(1.15, 1.45, 4.8), "node": "bar"},
	"t28": {"at": Vector3(9.08, SIT_T28, 6.97), "look": Vector3(9.55, 0.95, 8.4), "node": "t28", "seat": true},
	"pool": {"at": Vector3(7.85, STAND, 5.5), "look": Vector3(10.2, 0.9, 3.9), "node": "pool"},
	"hall": {"at": Vector3(7.3, STAND, -0.6), "look": Vector3(15.2, 1.3, -0.62), "node": "hall"},
	"kitchen": {"at": Vector3(3.7, STAND, -1.35), "look": Vector3(0.45, 1.05, -2.25), "node": "kitchen"},
	"keg": {"at": Vector3(1.45, -2.5 + STAND, 1.25), "look": Vector3(2.9, -2.2, -2.45), "node": "keg"},
	"deck": {"at": Vector3(16.95, 1.69, 6.2), "look": Vector3(23.0, 0.9, 9.0), "node": "deck"},
	"lot": {"at": Vector3(8.0, STAND, 23.0), "look": Vector3(5.0, 5.2, 10.1), "node": "lot"},
	"upstairs": {"at": Vector3(14.1, 3.4 + 1.62, 7.1), "look": Vector3(14.6, 3.4 + 1.3, 9.95), "node": "upstairs", "seat": true},
}

# the ways on foot: points on the floor (x, z, floor height)
const NODES := {
	"door": Vector3(1.7, 0, 8.85),
	"vest": Vector3(3.2, 0, 9.15),
	"out": Vector3(3.2, 0, 10.95),
	"lot": Vector3(3.9, 0, 12.4),
	"room": Vector3(5.6, 0, 7.5),
	"floor": Vector3(7.0, 0, 6.7),
	"bar": Vector3(2.95, 0, 5.3),
	"t28": Vector3(9.08, 0, 6.97),
	"pool": Vector3(7.85, 0, 5.5),
	"backway": Vector3(6.5, 0, 0.9),
	"hall": Vector3(7.3, 0, -0.6),
	"swing": Vector3(3.25, 0, 0.55),
	"kitchen": Vector3(3.7, 0, -1.35),
	"barend": Vector3(1.95, 0, 0.45),
	"trap": Vector3(1.05, 0, 1.75),
	"keg": Vector3(1.45, -2.5, 1.25),
	"deck_in": Vector3(15.3, 0, 7.1),
	"deck_out": Vector3(16.75, -0.07, 7.1),
	"deck": Vector3(16.95, -0.07, 6.2),
	"hotel": Vector3(15.5, 0, -0.62),
	"upstairs": Vector3(14.1, 3.4, 7.1),
}

# [a, b, how]: "walk", or "cut" (a ladder, a flight of stairs: the page goes blank between)
const WAYS := [
	["door", "vest", "walk"], ["vest", "out", "walk"], ["out", "lot", "walk"], ["vest", "room", "walk"],
	["room", "floor", "walk"], ["room", "bar", "walk"], ["room", "t28", "walk"], ["floor", "t28", "walk"],
	["floor", "pool", "walk"], ["floor", "bar", "walk"], ["pool", "backway", "walk"], ["floor", "backway", "walk"],
	["backway", "hall", "walk"], ["hall", "hotel", "walk"], ["bar", "swing", "walk"], ["pool", "swing", "walk"],
	["swing", "kitchen", "walk"], ["swing", "barend", "walk"], ["barend", "trap", "walk"], ["trap", "keg", "cut"],
	["floor", "deck_in", "walk"], ["t28", "deck_in", "walk"], ["deck_in", "deck_out", "walk"], ["deck_out", "deck", "walk"],
	["hotel", "upstairs", "cut"], ["bar", "door", "walk"],
]

# the doors he goes through on a way, and which way they swing
const DOORS_ON := {
	"vest|out": "main", "out|vest": "main",
	"swing|kitchen": "swing", "kitchen|swing": "swing",
	"deck_in|deck_out": "deck", "deck_out|deck_in": "deck",
	"hall|hotel": "", "hotel|hall": "",
}


# A place seen more than one way. The lot: the whole building from across the gravel when he
# arrives; the pickup's driver's window, the glass fogged; the step under the light over the door
# at the end, the big man at his truck by the beer store.
const FRAMES := {
	"lot:arrive": {"at": Vector3(8.0, STAND, 23.0), "look": Vector3(5.0, 5.2, 10.1), "node": "lot"},
	"lot:pickup": {"at": Vector3(8.17, STAND, 17.17), "look": Vector3(8.75, 1.3, 15.99), "node": "lot"},
	"lot:truck": {"at": Vector3(3.3, STAND, 11.0), "look": Vector3(-3.0, 1.2, 13.4), "node": "lot"},
}


static func post(place: String, frame := "") -> Dictionary:
	if frame != "" and FRAMES.has(place + ":" + frame):
		return FRAMES[place + ":" + frame]
	return POSTS.get(place, POSTS["door"])


# The way from one place to another: a list of [node, how] from the first node after `from`'s
# to `to`'s, by the fewest steps.
static func way(from: String, to: String) -> Array:
	var a: String = post(from).node
	var b: String = post(to).node
	if a == b:
		return []
	var prev := {a: ""}
	var how := {}
	var q: Array = [a]
	while not q.is_empty():
		var n: String = q.pop_front()
		if n == b:
			break
		for w in WAYS:
			var other := ""
			if w[0] == n:
				other = w[1]
			elif w[1] == n:
				other = w[0]
			if other != "" and not prev.has(other):
				prev[other] = n
				how[other] = w[2]
				q.append(other)
	if not prev.has(b):
		return [[b, "cut"]]
	var out: Array = []
	var n2 := b
	while n2 != a:
		out.push_front([n2, how[n2]])
		n2 = prev[n2]
	return out


# yaw and pitch that look from `at` toward `target` (yaw round +y from -z, as the camera takes it)
static func aim(at: Vector3, target: Vector3) -> Vector2:
	var d := (target - at).normalized()
	return Vector2(atan2(-d.x, -d.z), asin(clampf(d.y, -1.0, 1.0)))
