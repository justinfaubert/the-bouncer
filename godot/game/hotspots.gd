# Looking as choosing. The choices on offer are in the room as well as in the column: each one that's
# about something he can see (the kid's phone, the truck, the big man, the propped door, the way to
# the bar) is pinned to that thing. When his eyes rest on it (the pointer on it, or the middle of
# his view when he turns his head with the keys) the thing is ringed, the choice lights in the
# column, a voice may lean in on it there in the room (game/hand.gd), and the choice's words come up
# beside it. A click on it, or E, makes that choice.
#
# What a choice is about is found from its words: the lexicon below names things by the words the
# Ink uses for them, and a move names its place. A choice nothing in the room answers to stays in
# the column only.
class_name Hotspots
extends Node

# words in a choice, to the thing in the room they're about (first match wins, so the specific go
# before the general)
const LEXICON := [
	["phone|photo|screen|swipe", "fig:hoodie:phone"],
	["good shoes", "fig:goodshoes"],
	["licen[cs]e|\\bid\\b|\\bcard\\b|birthday", "at_door"],
	["sister|kayla|at the wheel|the driver", "fig:driver"],
	["boyfriend|vape", "fig:vape"],
	["\\bkid\\b|hood|tyler", "fig:hoodie"],
	["truck|pickup|headlight", "a:truck"],
	["raincoat|wife", "fig:raincoat"],
	["glasses|dennis", "fig:glasses"],
	["scratch|lotto|ticket", "fig:scratch"],
	["cardigan", "fig:cardigan"],
	["hearing aid", "fig:hearing_aid"],
	["team jacket", "fig:team_jacket"],
	["table 28|the table|twenty-eight|sit down with them|the last one", "a:t28"],
	["buddy", "fig:buddy"],
	["big man|pool|\\bcue\\b|the game|his keys", "fig:bigman"],
	["constable|police|officer", "fig:constable"],
	["hi-vis|work crew|the crew", "fig:hivis"],
	["end of the bar|flat ?cap|walter|rat king|the old man", "fig:endbar"],
	["\\bcook\\b|fryer", "fig:cook"],
	["kitchen door|back door|propped|brick|dumpster|\\bbins?\\b|garbage|alley", "a:kitchen_back"],
	["terry|night clerk", "fig:terry"],
	["hotel door|wedge", "a:hotel_door"],
	["slippers", "fig:slippers"],
	["\\brats?\\b|the hole|behind the wall|poison|trap", "rat_hole"],
	["deck door|coaster|latch", "a:deck_door"],
	["jukebox|\\bsong\\b|music", "a:jukebox"],
	["washroom|stall|the single|occupied", "a:wc_single"],
	["payphone|numbers on the wall", "a:payphone"],
	["trapdoor|trap door|ladder", "a:trapdoor"],
	["\\bkegs?\\b|lines|office|mirror|bucket|\\bbait\\b", "a:kegs"],
	["\\btape\\b|the date|nineteen", "a:tape"],
	["scanner|\\bscan", "a:scanner"],
	["clicker|click|the count|count (him|her|them)", "clicker"],
	["\\btill\\b|binder|86|eighty-six|page three|the faces", "a:till"],
	["bartender|pour me|another\\.|a drink|tab\\b", "fig:bartender"],
	["incident|the book|write it|the log|leave it out", "a:ledge"],
	["\\btv\\b|hockey", "a:tv"],
	["dart", "a:dartboard"],
	["window", "p:9.4,1.65,10.1"],
	["\\bstool\\b|sit back down|your post|the door\\b|at the door|lock", "door_post"],
	["\\bbed\\b|sleep|lie down", "a:his_bed"],
]
# where each place is, for the ways out of the one he's in
const WAYS := {
	"door": "door_post", "floor": "p:7.6,1.0,5.6", "bar": "a:bar_top", "t28": "a:t28", "pool": "a:pool_table",
	"hall": "a:hall_way", "kitchen": "a:swing_door", "keg": "a:trapdoor", "deck": "a:deck_door", "lot": "a:main_door",
	"upstairs": "a:hotel_door",
}

var main
var spots: Array = []            # [{i, key, text}]
var under = null                 # the spot his eyes are on: {key, at: Vector2, list: [i...]}
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
			spots.append({"i": i, "key": key, "text": str(c.get("text", ""))})


func clear() -> void:
	spots.clear()
	_set_under(null)


func _about(c: Dictionary) -> String:
	if str(c.get("cls", "")) == "move":
		var loc := str(c.get("loc", ""))
		if loc != "" and loc != main.view.place:
			return WAYS.get(loc, "")
	var text := str(c.get("text", ""))
	for pair in LEXICON:
		if (_res[pair[0]] as RegEx).search(text) != null:
			return pair[1]
	return ""


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
		return [base.lerp(head, 0.62), 0.42]
	if key.begins_with("a:"):
		var n := key.substr(2)
		if not pub.anchors.has(n):
			return []
		var r := 0.35
		match n:
			"truck":
				r = 1.6
			"t28", "pool_table":
				r = 1.0
			"tape", "scanner", "till":
				r = 0.14
			"trapdoor", "deck_door", "kitchen_back", "wc_single", "main_door", "hotel_door", "swing_door", "hall_way":
				r = 0.5
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
		"clicker":
			return [pub.anchors.get("ledge", Vector3(1.3, 1.06, 9.72)) + Vector3(0.25, 0.0, 0.04), 0.12]
		"door_post":
			return [Vector3(1.7, 1.05, 9.2), 0.45]
	return []


static func zone_of(p: Vector3) -> String:
	if p.y < -1.0:
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
	if spots.is_empty() or not main.in_game or main.menus.is_open() or main.pending != null or main.rolling != null or main.props.holding():
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
	var best_d := INF
	for s in spots:
		var w := _where(s.key)
		if w.is_empty():
			continue
		var p: Vector3 = w[0]
		if not main.stage.in_sight(p, zone_of(p)):
			continue
		var sc: Vector3 = view.on_screen(p)
		if sc.z <= 0.0:
			continue
		var at := Vector2(sc.x, sc.y)
		var rpx := clampf(_px(p, w[1]), 26.0, 170.0) * (1.0 if by_pointer else 0.8)
		var d := at.distance_to(probe)
		if d < rpx and d < best_d:
			best_d = d
			best = {"key": s.key, "at": at, "r": rpx, "p": p}
	if best == null:
		_set_under(null)
		return
	var list: Array = []
	for s in spots:
		if s.key == best.key:
			list.append(s.i)
	best["list"] = list
	_set_under(best)


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
	var same: bool = was != null and u != null and was.key == u.key
	if same:
		under.at = u.at
		under.r = u.r
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
	main.hand.eyes_on(int(u.list[0]), true, u.at)
	_build_caption()
	overlay.queue_redraw()


func _build_caption() -> void:
	for c in cap_box.get_children():
		c.queue_free()
	var list: Array = main.game.visible_choices()
	for i in under.list:
		if int(i) >= list.size():
			continue
		var c: Dictionary = list[int(i)]
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = _short(str(c.get("text", "")))
		b.add_theme_font_override("font", Look.font("read"))
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", Look.INK)
		b.add_theme_color_override("font_hover_color", Look.LAMP)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(300, 0)
		var ix := int(i)
		b.pressed.connect(func(): _pick(ix))
		cap_box.add_child(b)
	var hint := UiBits.label("click, or E", "ui", 14, Look.MUTED, 2)
	cap_box.add_child(hint)
	caption.visible = true
	caption.reset_size()
	_place_caption()


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
	if under == null or under.list.is_empty():
		return
	_pick(int(under.list[0]))


# E: the choice his eyes are on; or, if there's nothing there, pick back up what he put down
func use() -> void:
	if under != null and not under.list.is_empty():
		_pick(int(under.list[0]))
		return
	main.props.raise()


func _draw() -> void:
	if under == null:
		return
	var at: Vector2 = under.at - overlay.global_position
	var r: float = under.r
	var c := Color(Look.STOCK, 0.75 + 0.2 * sin(_t * 4.0))
	# a ring drawn in dashes, turning slowly
	var n := 28
	for k in n:
		if k % 2 == 1:
			continue
		var a0 := TAU * k / n + _t * 0.4
		var a1 := TAU * (k + 1) / n + _t * 0.4
		overlay.draw_arc(at, r, a0, a1, 4, Color(Look.NIGHT, 0.6), 4.5, true)
		overlay.draw_arc(at, r, a0, a1, 4, c, 2.0, true)
