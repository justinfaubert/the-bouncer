# His own feet (Hutch, 2026-11-21: "Movement in the world is limited which feels a bit
# claustrophobic"). W A S D walk him, the mouse and the arrow keys turn his head, Shift hurries him,
# and Alt with A or D leans him round a doorway or a shoulder, the way Thief (1998) let a player
# look round a corner without stepping out from it.
#
# Where he can walk is wherever the night has him free to (game/going.gd, _free(): the walk across
# the room is on offer): the bar's floor and the vestibule, and out on the deck and in the lot when
# he's out there. Walking through a doorway into another part of the building is going there, the
# same as clicking it: the night's choice to go out on the deck, down the back hall, into the
# kitchen, or out the front. From a place in the room (the stool, the bar, table 28, the pool
# table), holding a key to walk gets him up and out onto the floor that way. The places in the room
# are walked up to: standing in one, its name comes up at the foot of the picture, and E settles him
# there.
#
# Click-to-go stays, for anyone who'd rather point. The keys only walk while he's free to walk;
# otherwise they turn his head, as they always did. Settings > "The keys walk him" turns it off.
#
# A walk is a walk: across the room is a minute on the clock (the hub's unlisted walk, taken when he
# stops), the room sees him hurry, and his steps are heard.
class_name Feet
extends RefCounted

const ACCEL := 5.0            # metres a second, a second: a big man gets going
const BRAKE := 7.0            # and stops where he means to
const LEAVE_HOLD := 0.3       # seconds a key's held at a place in the room before he gets up from it
const STEP_SOUND := 1.5       # metres between his steps being heard
const CHARGE_AT := 10.0       # walking on and on, the minute's taken on the way
const STOPPED := 0.45         # seconds still before a walk's done
const PERSON_ROOM := 0.52
const TIGHT := 0.21           # the room his body needs outside, shoulder turned     # how close he comes to someone standing
const LEAN := 0.3             # how far his head goes out, leaning
const LEAN_ROLL := 0.09
# the part of the building each zone is (Hotspots.zone_of), as a place the night knows
const ZONE_PLACE := {"room": "floor", "vest": "floor", "hall": "hall", "kitchen": "kitchen", "deck": "deck", "lot": "lot"}
# where in each place he walks about freely, once he's there
const WALKS := {"floor": ["room", "vest"], "deck": ["deck"], "lot": ["lot"]}

var main
var held := {}                # W A S D, by key
var shift := false
var alt := false
var vel := Vector3.ZERO
var lean := 0.0               # -1 left, 1 right
var _walked := 0.0            # since the last minute taken
var _since_step := 0.0
var _still := 0.0
var _hurried := 0.0
var _held_t := 0.0            # how long a key's been held at a place he'd get up from
var _opened := {}             # doors he's opened walking, by name
var _crossing := false        # a way through a doorway taken; waiting for the night to move him
var hint: Label
var hint_way := -1            # the place he's standing in, to settle at with E


func _init(m) -> void:
	main = m
	hint = Label.new()
	hint.add_theme_font_override("font", UiBits.spaced("ui_b", 2))
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(Look.STOCK, 0.88))
	hint.add_theme_color_override("font_outline_color", Color(Look.NIGHT, 0.9))
	hint.add_theme_constant_override("outline_size", 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.anchor_left = 0.0
	hint.anchor_right = View.WORLD_W
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_top = -64
	hint.offset_bottom = -36
	hint.visible = false
	main.root.add_child(hint)


func on() -> bool:
	return bool(main.settings.get("keys_walk", true))


# W A S D, Shift and Alt, pressed or let go. Whether the key's his feet's (otherwise it's his head's).
func key(k: int, pressed: bool) -> bool:
	if k == KEY_SHIFT:
		shift = pressed
		return false
	if k == KEY_ALT:
		alt = pressed
		return false
	if not k in [KEY_W, KEY_A, KEY_S, KEY_D]:
		return false
	if pressed:
		held[k] = true
	else:
		held.erase(k)
	return on()


func clear() -> void:
	held.clear()
	shift = false
	alt = false


# the keys as a direction: x right, y forward
func wish() -> Vector2:
	var v := Vector2.ZERO
	if held.has(KEY_W):
		v.y += 1
	if held.has(KEY_S):
		v.y -= 1
	if held.has(KEY_A):
		v.x -= 1
	if held.has(KEY_D):
		v.x += 1
	return v


func _can() -> bool:
	return main.in_game and not main.game.ended and main.pending == null and main.rolling == null \
		and not main.menus.is_open() and not main.props.holding() and not main.notes.visible \
		and not main.sketch.visible and not main.answering


# Where he is walks about freely: on the floor, the deck or the lot, with the night letting him.
func free_here() -> bool:
	var view: View = main.view
	if not on() or not _can() or view.walking or view.on_floor != "" or Posts.away(view.place):
		return false
	if not WALKS.has(view.place):
		return false
	return main.game.toy_choice("legs", "walk") != null


# What the keys do this frame: "walk", "leave" (get up from a place), "lean", or "look".
func mode() -> String:
	if not on():
		return "look"
	if alt:
		return "lean"
	if free_here():
		return "walk"
	var view: View = main.view
	if _can() and not view.walking and view.place in Going.IN_ROOM and main.going._way_to("floor") >= 0:
		return "leave"
	return "look"


func process(dt: float) -> void:
	var view: View = main.view
	var w := wish()
	var m := mode()
	# the keys turn his head when they can't walk him (and Alt's A and D lean him instead)
	var look := Vector2.ZERO
	if m == "look":
		look = Vector2(w.x, w.y)
	view.keys_feet = look
	_lean(dt, w.x if m == "lean" else 0.0)
	if not view.walking:
		_crossing = false
	if m == "walk":
		_walk(dt, w)
	else:
		vel = Vector3.ZERO
		view.stroll = false
		if m == "leave" and w != Vector2.ZERO:
			_held_t += dt
			if _held_t >= LEAVE_HOLD:
				_held_t = 0.0
				_leave(w)
		else:
			_held_t = 0.0
	_doors()
	_hint(m)


# ---------------------------------------------------------------- walking

func _walk(dt: float, w: Vector2) -> void:
	var view: View = main.view
	var yaw := view.yaw
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var cruise := View.HURRIED if shift else View.PACE
	var want := Vector3.ZERO
	if w != Vector2.ZERO:
		want = (fwd * w.y + right * w.x).normalized() * cruise
		# backing up and stepping sideways, a man goes slower
		if w.y < 0:
			want *= 0.6
		elif w.y == 0:
			want *= 0.8
	vel = vel.move_toward(want, (ACCEL if want.length() > vel.length() else BRAKE) * dt)
	var at := Vector3(view.eye_pos.x, 0.0, view.eye_pos.z)
	var step := vel * dt
	if step.length() > 0.00001:
		var to = _try(at, step)
		if to == null:
			to = _try(at, Vector3(step.x, 0, 0))
		if to == null:
			to = _try(at, Vector3(0, 0, step.z))
		if to == null:
			vel = Vector3.ZERO
		elif to is Dictionary:
			return
		else:
			var moved: float = (to as Vector3).distance_to(at)
			view.eye_pos = Vector3(to.x, Posts.STAND, to.z)
			view.floor_spot = Vector3(to.x, 0.0, to.z)
			_walked += moved
			_since_step += moved
			if _since_step >= STEP_SOUND:
				_since_step = 0.0
				main.audio.sfx("steps", 0.5 if not shift else 0.7)
			if shift and Hotspots.zone_of(view.eye_pos) in ["room", "vest"]:
				_hurried += moved
				if _hurried >= View.RAN:
					_hurried = 0.0
					main.going.ran()
	view.stroll = vel.length() > 0.05
	view.stroll_v = vel.length()
	if view.stroll:
		view.turned_t = view.t
		view.add_stride(vel.length() * dt)
		_still = 0.0
	else:
		_still += dt
		_hurried = 0.0
	# the minute a walk costs, when he stops (or as he goes, if he keeps on)
	if (_still >= STOPPED and _walked >= Going.STROLL) or _walked >= CHARGE_AT:
		_walked = 0.0
		main.view.pub.shadows_near(view.eye_pos)
		main.toy("legs", "walk")
		main.spots.refresh()


# Where a step from at would put him: the spot, or null where he can't go (a wall, a table, someone
# standing there), or {} where the step's taken him through a doorway and the night's moving him.
func _try(at: Vector3, step: Vector3) -> Variant:
	var view: View = main.view
	var to := at + step
	# room for his body: outside, between the deck's chairs and the cars, he turns a shoulder (a
	# little less); and from a spot the night put him in tight, any step toward more room is fine
	var need := Nav.BODY if Hotspots.zone_of(at + Vector3(0, 1.0, 0)) in ["room", "vest"] else TIGHT
	var room := Nav.clearance(to)
	if room < need and not (room > Nav.clearance(at) + 0.005 and room > 0.03):
		return null
	var people: Array = view.people_at.call() if view.people_at.is_valid() else []
	for p in people:
		var pp := Vector3(p.x, 0.0, p.z)
		var d := pp.distance_to(to)
		# never walks into someone; walking away from them is fine
		if d < PERSON_ROOM and d < pp.distance_to(at):
			return null
	var zone := Hotspots.zone_of(to + Vector3(0, 1.0, 0))
	var allowed: Array = WALKS.get(view.place, [])
	if zone in allowed:
		return to
	if _crossing:
		return null
	# through a doorway: going there, if the night has a way there on offer
	var place: String = ZONE_PLACE.get(zone, "")
	if place == "":
		return null
	var i: int = main.going._way_to(place)
	if i < 0:
		return null
	_crossing = true
	vel = Vector3.ZERO
	view.stroll = false
	if place == "floor":
		view.floor_next = to + step.normalized() * 0.6
	main.going._going(Vector3.INF, place)
	main.choose(i)
	return {}


# Up from a place in the room, the way the key says: out onto the floor a step or so that way.
func _leave(w: Vector2) -> void:
	var view: View = main.view
	var i: int = main.going._way_to("floor")
	if i < 0:
		return
	var yaw := view.yaw
	var dir := (Vector3(-sin(yaw), 0.0, -cos(yaw)) * w.y + Vector3(cos(yaw), 0.0, -sin(yaw)) * w.x).normalized()
	var at := Vector3(view.eye_pos.x, 0.0, view.eye_pos.z)
	var spot: Vector3 = main.going._stand_near(at + dir * 1.1)
	if spot == Vector3.INF or Hotspots.zone_of(spot + Vector3(0, 1.0, 0)) not in ["room", "vest"]:
		spot = main.going._stand_near(at + dir * 0.7)
	if spot != Vector3.INF:
		view.floor_next = spot
	main.choose(i)


# ---------------------------------------------------------------- leaning

func _lean(dt: float, want: float) -> void:
	var view: View = main.view
	# never through a wall: only as far out as there's room for his head
	if want != 0.0:
		var right := Vector3(cos(view.yaw), 0.0, -sin(view.yaw))
		var tip := Vector3(view.eye_pos.x, 0.0, view.eye_pos.z) + right * LEAN * want
		if Nav.clearance(tip) < 0.06:
			want *= 0.35
	lean = move_toward(lean, want, dt * 4.0)
	view.lean_off = lean * LEAN
	view.lean_roll = -lean * LEAN_ROLL


# ---------------------------------------------------------------- doors and places

# A door he's walking to opens as he comes to it, and swings to once he's by.
func _doors() -> void:
	var view: View = main.view
	if view.walking:
		_opened.clear()
		return
	var at := Vector2(view.eye_pos.x, view.eye_pos.z)
	for k in Posts.DOORWAYS:
		var d: Vector3 = Posts.DOORWAYS[k]
		var dist := at.distance_to(Vector2(d.x, d.z))
		if dist < View.DOOR_NEAR and view.stroll and not _opened.has(k):
			_opened[k] = true
			view.pub.swing_door(k, true)
		elif _opened.has(k) and dist > View.DOOR_NEAR + 0.4:
			_opened.erase(k)
			view.pub.swing_door(k, false)


# Standing in a place in the room he's free to settle at: its name at the foot of the picture.
func _hint(m: String) -> void:
	hint_way = -1
	var view: View = main.view
	if m == "walk" and view.place == "floor":
		# the place he's standing in, or right in front of (the bar's over the stools from him)
		var at := Vector3(view.eye_pos.x, 0.0, view.eye_pos.z)
		var fwd := Vector3(-sin(view.yaw), 0.0, -cos(view.yaw))
		var area := ""
		for ahead in [0.0, 0.5, 1.0, 1.5, 2.0, 2.3]:
			var q: Vector3 = at + fwd * ahead
			var a := Posts.area_of(q, Hotspots.zone_of(q + Vector3(0, 1.0, 0)))
			if a != "" and a != "floor" and a in Going.IN_ROOM:
				area = a
				break
		if area != "":
			var to := area
			var i: int = main.going._way_to(to)
			if i < 0 and Going.OR_ELSE.has(area):
				i = main.going._way_to(Going.OR_ELSE[area])
			if i >= 0:
				hint_way = i
				var c: Dictionary = main.game.visible_choices()[i]
				hint.text = "E    " + str(c.get("text", "")).to_upper()
	hint.visible = hint_way >= 0


# E, standing in a place: settle there (a thing under his eyes there is still a click). Whether it
# did.
func use() -> bool:
	if hint_way < 0:
		return false
	var i := hint_way
	hint_way = -1
	hint.visible = false
	main.choose(i)
	return true
