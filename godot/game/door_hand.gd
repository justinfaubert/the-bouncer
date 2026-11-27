# The door by hand: the verdict at the door made with his hand, not picked from a list of words.
#
# When the choices on offer at the door carry a verdict (`#door: in`, `out`, `fetch` or `terms` in
# content/ink/door.ink), his left hand rests on his knee at the bottom of his view, and the player
# can take it and use it the way a doorman does:
#
#   in      a sweep of the open hand toward the room: go on in
#   out     the palm up, square to them: no
#   fetch   the hand thrown back out past them, at the lot: go and get it, then come back
#   terms   the hand flat, palm down, patting the air: hold on, here's how it goes
#
# Which way is "toward the room" is worked out from where the room is on the screen, so it holds
# however he's turned his head; the lot is the other way. Up is always the palm, down the terms.
# Only the verdicts on offer can be made: a way with nothing on offer the hand won't go far.
#
# While he's dragging, the choice's words come up by his hand and its row lights in the column,
# a voice may lean in on it there (game/hand.gd), and the room goes quiet under him, more the
# further he commits (Sound.weigh). Let go short of the mark and the hand goes back to his knee.
# Let go past it and it's done: the room answers first (the person goes in or turns back, the
# door swings, he hears it), and only then the column (main.choose_by_hand).
#
# The words are still in the column, and choosing them there does the same thing. This is a
# second way in, for the hand, not the only one.
class_name DoorHand
extends Node

const PEOPLE := "res://models/people/"
const GRAB_R := 120.0            # how near the hand the pointer has to be to take it (screen px at 1080)
const FULL := 150.0              # how far it's dragged to commit (screen px at 1080)
const DEAD := 22.0               # under this, no way is chosen yet
# where the hand sits for each verdict, in his eye's space (-z ahead, y up): position, then turn in
# degrees (the model is his right hand lying open, palm up, fingers ahead, mirrored to his left)
const POSE := {
	"rest": [Vector3(-0.15, -0.30, -0.45), Vector3(40, 20, 180)],
	# down out of the way, the fingertips at the foot of his view: where it waits till it's wanted
	"low": [Vector3(-0.17, -0.42, -0.42), Vector3(55, 20, 180)],
	"in": [Vector3(-0.2, -0.15, -0.5), Vector3(10, 75, -15)],
	"out": [Vector3(-0.04, -0.10, -0.48), Vector3(90, 0, 180)],
	"fetch": [Vector3(0.05, -0.14, -0.5), Vector3(10, -60, 15)],
	"terms": [Vector3(-0.06, -0.19, -0.46), Vector3(70, 10, 190)],
}
const WORDS := {"in": "in", "out": "no", "fetch": "go get it", "terms": "on terms"}

var main
var poses := POSE.duplicate(true)  # the poses in use (a test can try others)
var node: Node3D                 # the hand, riding on his head (view.hands)
var label: Label                 # the choice's words, by the hand
var hint: Label
var shown := false
var offered := {}                # verdict -> visible index of the choice that makes it
var dragging := false
var drag_from := Vector2.ZERO
var way := ""                    # the way it's being dragged now
var amount := 0.0                # how far, 0 to 1
var room_left := true            # the room's on the left of his view
var _armed := false
var _lit := -1
var _cur := Transform3D()
var _t := 0.0
var _ready_k := 0.0              # 0 down out of the way, 1 up and ready
var row_way := ""                # the verdict whose row the player's hand is resting on
var _who := ""                   # the one at the door
var _taught := false             # he's done it once: no more words by the hand


func setup(m) -> void:
	main = m
	node = Node3D.new()
	node.visible = false
	main.view.hands.add_child(node)
	if FileAccess.file_exists(PEOPLE + "his_right_palm.glb"):
		var h: Node3D = main.pub.model(PEOPLE + "his_right_palm.glb", Vector3.ZERO, node)
		# his left: the right hand, mirrored
		h.scale = Vector3(-1, 1, 1)
		_no_shadows(h)
	label = Label.new()
	label.add_theme_font_override("font", UiBits.spaced("ui_b", 2))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(Look.STOCK, 0.96))
	label.add_theme_color_override("font_outline_color", Color(Look.NIGHT, 0.92))
	label.add_theme_constant_override("outline_size", 7)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	main.root.add_child(label)
	hint = Label.new()
	hint.add_theme_font_override("font", UiBits.spaced("ui_b", 2))
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(Look.STOCK, 0.8))
	hint.add_theme_color_override("font_outline_color", Color(Look.NIGHT, 0.9))
	hint.add_theme_constant_override("outline_size", 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 28
	hint.offset_top = -104
	hint.offset_bottom = -70
	hint.visible = false
	main.root.add_child(hint)
	main.view.sheet.gui_input.connect(_on_sheet_input)


# ---------------------------------------------------------------- what's on offer

# The verdicts on offer now, if he's on the door with nothing in the way of his hand.
func _read_offer() -> Dictionary:
	var out := {}
	if not main.in_game or main.game.ended or main.pending != null or main.rolling != null or main.answering:
		return out
	if main.menus.is_open() or main.notes.visible or main.sketch.visible:
		return out
	if main.view.place != "door" or main.view.walking:
		return out
	var list: Array = main.game.visible_choices()
	for i in list.size():
		var d := str(list[i].get("door", ""))
		if d in POSE and d != "rest" and d != "low" and not out.has(d):
			out[d] = i
	return out


func offers(g: String) -> bool:
	return offered.has(g)


# ---------------------------------------------------------------- the hand

func _process(dt: float) -> void:
	_t += dt
	offered = _read_offer()
	var want := not offered.is_empty()
	if want != shown:
		shown = want
		if not shown:
			_cancel()
		node.visible = shown
		if shown:
			_cur = _pose_tr("low").translated_local(Vector3(0, -0.12, 0.04))
			_room_side()
			_who = Acts.facing(main)
		elif _who != "":
			main.stage.life.hold(_who, 0.0)
			_who = ""
	# the hand comes up when it's wanted: the pointer down near it, or resting on a verdict's row
	var near := false
	var ptr: Vector2 = main.view.pointer
	if ptr.x >= 0.0:
		var hs := _hand_screen()
		var at: Vector2 = ptr / Vector2(main.view.eye.size) * main.view.sheet.size + main.view.sheet.global_position
		near = hs.x >= 0.0 and at.distance_to(hs) < GRAB_R * _scale() * 2.4
	_ready_k = move_toward(_ready_k, 1.0 if (near or dragging or row_way != "") else 0.0, dt * 3.0)
	hint.visible = shown and not dragging and _ready_k > 0.6 and not _taught
	if hint.visible:
		_hint_text()
	if not shown:
		label.visible = false
		main.audio.weigh = 0.0
		return
	# where it wants to be: on his knee, or that far along the way it's being taken
	var target := _pose_tr("low").interpolate_with(_pose_tr("rest"), _ready_k)
	if way != "":
		target = target.interpolate_with(_pose_tr(way), amount)
	elif row_way != "" and offered.has(row_way):
		# a hand on the verdict's row: his hand starts to make it
		target = target.interpolate_with(_pose_tr(row_way), 0.32)
	# the one at the door feels it coming: leaning in to the sweep, back from the palm
	var lean_v := 0.0
	var w := way if way != "" else row_way
	var a := amount if way != "" else (0.3 if row_way != "" else 0.0)
	match w:
		"in": lean_v = 0.7 * a
		"out": lean_v = -1.0 * a
		"fetch": lean_v = -0.6 * a
		"terms": lean_v = -0.25 * a
	if _who != "":
		main.stage.life.hold(_who, lean_v)
	elif dragging:
		# taken, but no way yet: it follows a little, loosely
		target = target.translated(Vector3(0, 0.01, 0))
	# a breath in it at rest, so it reads as his and alive
	if not dragging:
		target = target.translated(Vector3(0, sin(_t * 1.3) * 0.0015, 0))
	_cur = _cur.interpolate_with(target, 1.0 - exp(-dt * 14.0))
	node.transform = _cur
	main.audio.weigh = amount if way != "" else 0.0
	_place_label()


# the gestures held further off than they were: a wrist's worth of hand at the foot of the view,
# not an arm across it (the hand looks smaller and leaves their face in sight)
const REACH_K := 1.35
const DROP := {"out": Vector3(-0.08, -0.05, 0.0), "terms": Vector3(0.0, -0.03, 0.0), "in": Vector3(0.0, -0.04, 0.0), "fetch": Vector3(0.04, -0.03, 0.0)}

func _pose_tr(p: String) -> Transform3D:
	var pr: Array = poses[p]
	var pos: Vector3 = pr[0]
	if p != "rest" and p != "low" and poses[p] == POSE[p]:
		pos = pos * REACH_K + DROP.get(p, Vector3.ZERO)
	var rot: Vector3 = pr[1]
	# toward the room: the sweep's turn and place mirror when the room's on his right
	if p == "in" and not room_left:
		pos.x = -pos.x * 0.4
		rot.y = -rot.y
	if p == "fetch" and not room_left:
		pos.x = -0.2
		rot.y = -rot.y
		rot.z = -rot.z
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	return Transform3D(b, pos)


# Which side of his view the room's on, from where he's sitting now.
func _room_side() -> void:
	var cam: Camera3D = main.view.cam
	var room_pt := Vector3(7.0, 1.2, 7.4)
	var local := cam.global_transform.affine_inverse() * room_pt
	room_left = local.x < 0.0


func _hand_screen() -> Vector2:
	var s: Vector3 = main.view.on_screen(node.global_position)
	return Vector2(s.x, s.y) if s.z > 0.0 else Vector2(-1, -1)


func _scale() -> float:
	return main.view.sheet.size.y / 1080.0


func _hint_text() -> void:
	var parts: Array = []
	var arrows := {"in": "←" if room_left else "→", "out": "↑", "fetch": "→" if room_left else "←", "terms": "↓"}
	for g in ["in", "out", "fetch", "terms"]:
		if offered.has(g):
			parts.append("%s %s" % [arrows[g], WORDS[g]])
	hint.text = "DRAG HIS HAND   " + "   ".join(parts)


func row_on(i: int, on: bool) -> void:
	var g := ""
	if on:
		for k in offered:
			if offered[k] == i:
				g = k
	if on or row_way == "" or offered.get(row_way, -1) == i:
		row_way = g


func _place_label() -> void:
	if not dragging or way == "" or not offered.has(way):
		label.visible = false
		return
	var list: Array = main.game.visible_choices()
	var i: int = offered[way]
	if i >= list.size():
		label.visible = false
		return
	label.text = str(list[i].get("text", ""))
	label.reset_size()
	var at := _hand_screen()
	if at.x < 0.0:
		label.visible = false
		return
	label.visible = true
	label.modulate.a = clampf(amount * 1.6, 0.0, 1.0)
	var w: float = label.size.x
	var x := clampf(at.x - w * 0.5, 16.0, main.view.sheet.size.x - w - 16.0)
	label.position = Vector2(x, at.y - 120.0 * _scale())


# ---------------------------------------------------------------- the player's hand on his

func _on_sheet_input(e: InputEvent) -> void:
	if not shown:
		return
	var at: Vector2 = Vector2.ZERO
	if e is InputEventMouse:
		at = (e as InputEventMouse).position + main.view.sheet.global_position
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			var h := _hand_screen()
			if h.x >= 0.0 and at.distance_to(h) < GRAB_R * _scale() * 1.4:
				dragging = true
				drag_from = at
				main.view.hand_drag = true
				_room_side()
				main.audio.sfx("pocket", 0.35, 1.1)
				main.view.sheet.accept_event()
		elif dragging:
			var g := way
			var full := amount >= 1.0
			_cancel()
			if full and offered.has(g):
				commit(g)
			main.view.sheet.accept_event()
	elif e is InputEventMouseMotion and dragging:
		_drag_to(at)
		main.view.sheet.accept_event()


func _drag_to(at: Vector2) -> void:
	var d := (at - drag_from) / _scale()
	var g := ""
	if d.length() > DEAD:
		if absf(d.x) > absf(d.y):
			var toward_room := (d.x < 0.0) == room_left
			g = "in" if toward_room else "fetch"
		else:
			g = "out" if d.y < 0.0 else "terms"
	var along := d.length()
	if g != "" and not offered.has(g):
		# nothing on offer that way: it won't go
		preview(g, minf(along / FULL, 1.0) * 0.18, false)
		return
	preview(g, minf(along / FULL, 1.0))


# Show the hand that far along a way (the drag, or a test's pictures).
func preview(g: String, a: float, live := true) -> void:
	if g != way:
		_unlight()
		_armed = false
	way = g
	amount = a if g != "" else 0.0
	if g == "" or not live or not offered.has(g):
		if g == "" and not dragging:
			label.visible = false
		return
	if not dragging:
		dragging = a > 0.0
	var i: int = offered[g]
	if _lit != i:
		_unlight()
		_lit = i
		var row = main.column.row_for_index(i)
		if row != null and row.has_method("set_looked"):
			row.set_looked(true)
		main.hand.eyes_on(i, true, _hand_screen())
	if amount >= 1.0 and not _armed:
		_armed = true
		main.audio.sfx("heart", 0.4)
	elif amount < 0.9:
		_armed = false


func _unlight() -> void:
	if _lit < 0:
		return
	var row = main.column.row_for_index(_lit)
	if row != null and row.has_method("set_looked"):
		row.set_looked(false)
	main.hand.eyes_on(_lit, false, Vector2.ZERO)
	_lit = -1


func _cancel() -> void:
	_unlight()
	dragging = false
	way = ""
	amount = 0.0
	_armed = false
	label.visible = false
	main.view.hand_drag = false


# Make the verdict: what the hand does, the door's own sound, and the choice.
func commit(g: String) -> void:
	if not offered.has(g):
		return
	var i: int = offered[g]
	_cancel()
	_taught = true
	if _who != "":
		main.stage.life.hold(_who, 0.0)
		main.stage.life.gesture(_who, {"in": "nod", "out": "back", "fetch": "away", "terms": "tilt"}[g], 1.0, 0.1)
	main.view.beat({"in": "nod", "out": "back", "fetch": "shake", "terms": "nod"}[g], 0.6)
	match g:
		"out", "fetch":
			# he leans and pushes the door open for them, and it falls to behind them
			main.pub.swing_door("main", true)
			main.get_tree().create_timer(1.1).timeout.connect(func(): main.pub.swing_door("main", false))
			main.audio.sfx("door_wc", 0.5, 0.8)
		"in":
			main.audio.sfx("steps", 0.45)
		"terms":
			main.audio.sfx("slap", 0.25, 0.7)
	main.choose_by_hand(i, g)


func _no_shadows(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadows(c)


# The press that took his hand, and the release that let it go, are the hand's and not a click on
# the room (main._on_world_input asks).
var _took := false

func took(pressed: bool) -> bool:
	if pressed:
		_took = dragging
		return _took
	var was := _took
	_took = false
	return was
