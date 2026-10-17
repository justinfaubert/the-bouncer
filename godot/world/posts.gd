# Where he stands (or sits) in each place the Ink knows, what he's looking at when he gets there,
# the doors he walks through and the ladder and the stairs off the ground floor.
#
# The Ink's places (content/ink/main.ink, LIST where): floor, door, bar, t28, pool, hall, kitchen,
# keg, deck, lot, upstairs. He walks between the ones on the ground floor the way world/nav.gd finds
# round things, through the doors; the keg room (down the ladder under the trapdoor) and his room
# upstairs are a cut, from the top of the ladder or the foot of the stairs.
class_name Posts
extends RefCounted

const STAND := 1.76        # his eyes, standing: a big man, not a giant
const SIT_DOOR := 1.62     # on the stool by the door
const SIT_T28 := 1.28      # on a low stool at table 28

# at: his eyes; look: what he's looking at when he gets there
const POSTS := {
	"door": {"at": Vector3(1.7, SIT_DOOR, 8.85), "look": Vector3(3.45, 1.25, 10.1), "seat": true},
	"floor": {"at": Vector3(7.0, STAND, 6.7), "look": Vector3(9.8, 1.0, 3.6)},
	# the bar: in the gap in its stools (Pub.SERVICE_Z), across from the bartender
	"bar": {"at": Vector3(2.85, STAND, 5.0), "look": Vector3(1.15, 1.45, 4.8)},
	"t28": {"at": Vector3(9.08, SIT_T28, 6.97), "look": Vector3(9.55, 0.95, 8.4), "seat": true},
	"pool": {"at": Vector3(7.85, STAND, 5.5), "look": Vector3(10.2, 0.9, 3.9)},
	"hall": {"at": Vector3(7.3, STAND, -0.6), "look": Vector3(15.2, 1.3, -0.62)},
	"kitchen": {"at": Vector3(3.7, STAND, -1.35), "look": Vector3(0.45, 1.05, -2.25)},
	"keg": {"at": Vector3(3.42, -2.5 + STAND, 4.35), "look": Vector3(3.42, -1.7, -1.5)},
	"deck": {"at": Vector3(17.5, STAND, 8.7), "look": Vector3(21.0, 0.6, 30.0)},
	"lot": {"at": Vector3(8.0, STAND, 23.0), "look": Vector3(5.0, 5.2, 10.1)},
	"upstairs": {"at": Vector3(14.1, 3.4 + 1.62, 7.1), "look": Vector3(14.6, 3.4 + 1.1, 9.95), "seat": true},
}

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


# A place seen more than one way. The lot: the whole building from across the gravel when he
# arrives; the pickup's driver's window, the glass fogged; the step under the light over the door
# at the end, the big man at his truck by the beer store. The back hall: through the hotel door to
# the front desk, while he talks to the night clerk; round the corner at the end of it, the dead
# payphone and the wall of numbers round it. The pool table: the jukebox past it, on the back wall,
# round behind whoever's standing at it. Table 28: standing at the end of it, behind the stool,
# until he sits down with them.
const FRAMES := {
	"t28:stand": {"at": Vector3(9.05, STAND, 6.38), "look": Vector3(9.5, 1.0, 8.3)},
	"hall:clerk": {"at": Vector3(16.85, STAND, -0.5), "look": Vector3(18.3, 1.42, -0.62)},
	"hall:phone": {"at": Vector3(13.9, STAND, -1.65), "look": Vector3(13.86, 1.45, -2.64)},
	"pool:juke": {"at": Vector3(14.1, STAND, 1.6), "look": Vector3(13.2, 1.5, 0.27)},
	"lot:arrive": {"at": Vector3(8.0, STAND, 23.0), "look": Vector3(5.0, 5.2, 10.1)},
	"lot:pickup": {"at": Vector3(8.17, STAND, 17.17), "look": Vector3(8.75, 1.3, 15.99)},
	"lot:truck": {"at": Vector3(3.3, STAND, 11.0), "look": Vector3(-3.0, 1.2, 13.4)},
}


static func post(place: String, frame := "") -> Dictionary:
	if frame != "" and FRAMES.has(place + ":" + frame):
		return FRAMES[place + ":" + frame]
	return POSTS.get(place, POSTS["door"])


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
