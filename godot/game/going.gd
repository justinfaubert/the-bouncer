# Going where he looks (bible/11_SKELETON.md, "Looking and going"). A click on the floor he can see
# is somewhere to go, and he walks there at a man's pace, round the tables and whoever's standing
# about (game/view.gd).
#
# Where that floor is part of a place the night knows (world/posts.gd, AREAS: the stool by the door
# and the vestibule, the bar and its stools, table 28, the pool table and the jukebox by it, the
# trapdoor; and the back hall, the kitchen, the deck and the lot whole), going there is the night's
# own choice to go there, the same as clicking the thing itself: he settles there, on the stool, on
# his forearms at the bar, at the table, and the room comes to him. Anywhere else on the bar's floor
# is just the floor. From a place, that's the night's way back onto it, and he walks out to where
# the player pointed. On it, he just walks there; a walk across the room costs a minute (the hub's
# unlisted choice, content/ink/floor.ink), taken when he gets there, so whatever's due happens as he
# does. In the middle of something (a talk, a check, someone at the door), nothing on offer goes
# anywhere, and he only looks over there.
#
# The ways round aren't in the column, only what he does where he is (game/column.gd): each one is
# pinned to its place in the room (game/hotspots.gd), and the sketch (M) takes him anywhere lit on
# it. With nothing under his eyes, E (Y on a pad) walks him to the floor he's looking at.
#
# While the pointer's on floor a click would take him to, a ring on it says where he'd end up, pale
# on the dark of the carpet like chalk: the spot itself, or the place's own (the stool, the gap in
# the bar's stools). Once he's going, a ring stays where he's going till he's there.
class_name Going
extends RefCounted

const FAR := 16.0             # past this, the floor's too far off to point at
const STROLL := 2.5           # a walk on the floor at least this long costs the minute
const RAN_AGAIN := 20.0       # seconds before the room makes anything of him running again
# a place that isn't on offer, and what's around it that may be (the trapdoor's behind the bar)
const OR_ELSE := {"keg": "bar", "pool:juke": "pool"}
# the places in the room, whose floor round them is theirs (world/posts.gd, AREAS)
const IN_ROOM := ["door", "bar", "t28", "pool", "pool:juke", "keg"]
const RING := 0.21            # the ring's size, across its middle (a man's two feet)

var main
var _from = null              # where on the floor he set off from, walking about it
var _ran_t := -INF
var _ring: MeshInstance3D     # where a click on the floor would take him
var _goal: MeshInstance3D     # where he's going, till he's there
var _goal_at = null
var _goal_to := ""            # the place he's going to, with it


func _init(m) -> void:
	main = m
	_ring = _make_ring()
	_goal = _make_ring()


# whether a choice on offer is only a way somewhere: a way out of a place (#class: move), or one of
# the floor's places (content/ink/floor.ink, the hub); not counting the room, which is on the floor
static func is_way(c: Dictionary) -> bool:
	if str(c.get("cls", "")) == "move":
		return true
	var loc = c.get("loc")
	return str(c.get("knot", "")) == "hub" and loc != null and str(loc) != "floor"


# The ways on offer the column can leave out (game/column.gd): the ones he can go by in the room. A
# way to somewhere he can see, or toward it (a door, the ladder), is pinned there; the way back onto
# the floor, while he's in the bar, is the floor itself. Any other stays in the column.
func hidden(list: Array) -> Array:
	var out: Array = []
	var view: View = main.view
	if Posts.away(view.place) or main.game.ended:
		return out
	# where he's going to be, not where he is on the way there
	var mine: String = Hotspots.PART.get(view.place, Hotspots.zone_of(view.eye_pos))
	for i in list.size():
		var c: Dictionary = list[i]
		if not is_way(c):
			continue
		var loc := Hotspots.loc_of(c)
		if loc == "floor" and view.on_floor == "" and mine in ["room", "vest"]:
			out.append(i)
			continue
		var key: String = main.spots.about(c)
		if key != "" and not main.spots.resolve({"i": i, "key": key, "text": str(c.get("text", "")), "loc": loc}).is_empty():
			out.append(i)
	return out


# where on the floor the ray through this point of his view comes down, if it's floor he can see
# and could stand near; Vector3.INF if not
func floor_at(from_pointer := true) -> Vector3:
	var view: View = main.view
	if view.on_floor != "" or Posts.away(view.place):
		return Vector3.INF
	var r: Array = view.ray(from_pointer)
	var o: Vector3 = r[0]
	var d: Vector3 = r[1]
	if d.y > -0.03:
		return Vector3.INF
	var t := -o.y / d.y
	if t <= 0.0 or t > FAR:
		return Vector3.INF
	var p := o + d * t
	p.y = 0.0
	var c := Nav.cell(p)
	if c.x < 0 or c.y < 0 or c.x >= Nav.SIZE.x or c.y >= Nav.SIZE.y:
		return Vector3.INF
	if not main.spots.seen_from_here("", p + Vector3(0, 0.05, 0)):
		return Vector3.INF
	return p


# a click on the room where nothing's under his eyes: go there, if it's floor. Whether it did.
func click(from_pointer := true) -> bool:
	if not _can():
		return false
	var tg := _target(from_pointer)
	var view: View = main.view
	if tg.has("way"):
		_going(tg.at, tg.to)
		main.hand.key_on(tg.way)
		main.choose(tg.way)
		return true
	if tg.has("walk"):
		if _from == null:
			_from = Vector3(view.eye_pos.x, 0.0, view.eye_pos.z)
		view.go_to_spot(tg.at)
		_going(tg.at, "floor")
		main.audio.sfx("steps")
		return true
	if tg.has("back"):
		view.floor_next = tg.at
		_going(tg.at, "floor")
		main.hand.key_on(tg.back)
		main.choose(tg.back)
		return true
	if tg.has("look"):
		_look_over(tg.look)
	return false


# What a click on the floor at that point of his view would do, the way click() does it:
#   {"way": i, "to": place, "at": where he'd stand}  the night's choice to go to a place
#   {"walk": true, "at": spot}                         across the floor he's on, to there
#   {"back": i, "at": spot}                            from a place, the way back onto the floor, out to there
#   {"look": p}                                        nothing to go to: he only looks over there
#   {}                                                 not the floor, or nothing to do with it
# Where the floor's part of a place but that place isn't on offer, and he's free to walk about, it's
# just the floor by it; somewhere else in the building with nothing on offer is only a look.
func _target(from_pointer: bool) -> Dictionary:
	var p := floor_at(from_pointer)
	if p == Vector3.INF:
		return {}
	var view: View = main.view
	var area := Posts.area_of(p, Hotspots.zone_of(p + Vector3(0, 0.05, 0)))
	if area == "":
		return {}
	if area != "floor":
		var to := area
		var i := _way_to(to)
		if i < 0 and OR_ELSE.has(area):
			to = OR_ELSE[area]
			i = _way_to(to)
		if i >= 0:
			return {"way": i, "to": to.split(":")[0], "at": _stand_at(to) if to in IN_ROOM else Vector3.INF}
		# there already: nothing to go to
		if area.split(":")[0] == view.place:
			return {}
		if not area in IN_ROOM:
			return {"look": p}
	var spot := _stand_near(p)
	if spot == Vector3.INF:
		return {"look": p}
	if view.place == "floor" and view.on_floor == "":
		return {"walk": true, "at": spot} if _free() else {"look": p}
	var back := _way_to("floor")
	if back < 0:
		return {"look": p}
	return {"back": back, "at": spot}


func _can() -> bool:
	return main.in_game and not main.game.ended and main.pending == null and main.rolling == null and not main.menus.is_open()


# where in a place in the room he'd stand (or sit), down on the floor
static func _stand_at(area: String) -> Vector3:
	var bits := area.split(":")
	var at: Vector3 = Posts.post(bits[0], bits[1] if bits.size() > 1 else "").at
	return Vector3(at.x, 0.0, at.z)


# E with nothing under his eyes: the floor he's looking at
func ahead() -> bool:
	return click(main.view.pointer.x >= 0.0)


# He's got somewhere. Walking about the floor, once he's stopped: a walk across the room is the
# minute it costs, and the night goes on from it.
func arrived(where: String) -> void:
	if where != "floor" or _from == null:
		return
	var view: View = main.view
	var walked: float = Vector2(view.eye_pos.x - _from.x, view.eye_pos.z - _from.z).length()
	_from = null
	if walked >= STROLL and _free():
		main.toy("legs", "walk")


# the page has moved him somewhere itself: whatever walk about the floor he was on is over
func moved() -> void:
	_from = null


# He ran across the bar's floor, in front of everyone (game/view.gd): heads come round, and the
# night hears of it (content/ink/toys.ink, toy_legs), once in a while, not every stride.
func ran() -> void:
	if main.view.t - _ran_t < RAN_AGAIN:
		return
	_ran_t = main.view.t
	main.stage.heads_to(main.view.eye_pos)
	main.toy("legs", "ran")


# free to walk about the floor: the night has him on it with nothing else going on (the hub's walk
# across the room is on offer)
func _free() -> bool:
	return main.game.toy_choice("legs", "walk") != null


# the choice on offer that's a way to a place (the jukebox's own, by the pool table), or -1
func _way_to(area: String) -> int:
	var bits := area.split(":")
	var loc := bits[0]
	var list: Array = main.game.visible_choices()
	var found := -1
	for i in list.size():
		var c: Dictionary = list[i]
		if not is_way(c) or Hotspots.loc_of(c) != loc:
			continue
		if loc == "floor" and str(c.get("cls", "")) != "move":
			continue
		var juke := str(c.get("text", "")).containsn("jukebox")
		if bits.size() > 1 and bits[1] == "juke":
			if juke:
				return i
		elif juke:
			continue
		if found < 0:
			found = i
	return found


# somewhere he can stand by p, a metre and a half off it at most, or Vector3.INF
func _stand_near(p: Vector3) -> Vector3:
	if Nav.clearance(p) >= Nav.BODY + 0.04:
		return p
	var best := Vector3.INF
	var bd := INF
	for r in [0.2, 0.35, 0.5, 0.7, 0.95, 1.2, 1.5]:
		for k in 16:
			var a := TAU * k / 16.0
			var q: Vector3 = p + Vector3(cos(a), 0.0, sin(a)) * r
			if Nav.clearance(q) < Nav.BODY + 0.04 or Hotspots.zone_of(q + Vector3(0, 0.05, 0)) != Hotspots.zone_of(p + Vector3(0, 0.05, 0)):
				continue
			var d: float = q.distance_to(main.view.eye_pos * Vector3(1, 0, 1))
			if d < bd:
				bd = d
				best = q
		if best != Vector3.INF:
			return best
	return Vector3.INF


# not going anywhere: his eyes go over there, and that's all
func _look_over(p: Vector3) -> bool:
	main.view.look_at_point(p + Vector3(0, 0.9, 0))
	return false


# ---------------------------------------------------------------- the rings

# Every frame (game/main.gd): the ring under the pointer, where a click would take him, while the
# pointer's resting on floor with nothing lit on it; and the one where he's going, till he's there
# (or the night's taken him somewhere else).
func process(dt: float) -> void:
	var view: View = main.view
	var at := Vector3.INF
	if _can() and view.pointer.x >= 0.0 and main.spots.under == null and not view.dragging() \
			and not main.props.holding() and not main.notes.visible:
		var tg := _target(true)
		if tg.has("at") and tg.at != Vector3.INF and Vector2(tg.at.x - view.eye_pos.x, tg.at.z - view.eye_pos.z).length() > 0.4:
			at = tg.at
	if _goal_at != null and not (view.walking and view.place == _goal_to):
		_goal_at = null
	var goal := Vector3.INF
	if _goal_at != null and (at == Vector3.INF or at.distance_to(_goal_at) > RING):
		goal = _goal_at
	_fade(_ring, at, 0.65, dt)
	_fade(_goal, goal, 0.9, dt)


func _going(at: Vector3, to: String) -> void:
	_goal_at = at if at != Vector3.INF else null
	_goal_to = to


# a ring at p (or none, at Vector3.INF), coming and going over a moment
func _fade(r: MeshInstance3D, p: Vector3, a: float, dt: float) -> void:
	var m := r.material_override as StandardMaterial3D
	var want := 0.0
	if p != Vector3.INF:
		want = a
		if not r.visible or m.albedo_color.a < 0.05:
			r.position = p + Vector3(0, 0.012, 0)
		else:
			r.position = r.position.lerp(p + Vector3(0, 0.012, 0), 1.0 - exp(-dt * 30.0))
		r.visible = true
	var c := m.albedo_color
	c.a = lerpf(c.a, want, 1.0 - exp(-dt * 14.0))
	m.albedo_color = c
	if want == 0.0 and c.a < 0.02:
		r.visible = false


# a thin flat ring, drawn pale, lying on the floor
func _make_ring() -> MeshInstance3D:
	var r := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = RING - 0.022
	t.outer_radius = RING + 0.022
	t.rings = 40
	t.ring_segments = 6
	r.mesh = t
	r.scale = Vector3(1.0, 0.12, 1.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(Look.INK.r, Look.INK.g, Look.INK.b, 0.0)
	r.material_override = m
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.visible = false
	main.pub.add_child(r)
	return r
