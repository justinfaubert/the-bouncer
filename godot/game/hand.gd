# The hand: the voices in his head reach for the player (prototype/web/src/ui/hand.js).
#
# While the player's hand is on a choice (the pointer resting on it, its key, or his eyes on the
# thing it's about in the room) a voice may lean in on it before it's made: its words come up
# beside the choice, or by the thing in the room, in its own type and colour, with a breath of
# sound. And they notice the player: sitting on the choices a long while (hand:wait), reading back
# up the night (hand:reread), coming back to the game after a while away (hand:back), choosing
# faster than anyone could read (hand:rush).
#
# What they say comes from the engine (Game.whisper and Game.murmur; the hand: rules in
# content/rules/barks.yaml). When a choice is made the engine is told which others the player had a
# hand on first, so a voice can say so when he passed over something he was tempted by.
class_name Hand
extends Node

const HOVER := 0.32
const KEY := 0.45
const LOOK := 0.7
const EYES := 0.55          # his eyes resting on a thing in the room before a voice leans in
const REREAD := 3.5
const AWAY := 240.0
const GAP := {"wait": 5, "reread": 10, "rush": 8, "back": 0}

var main
var shown_at := 0.0
var chars := 0
var considered := {}
var on_i := -1               # the choice the hand is on
var on_since := 0.0
var on_delay := HOVER
var on_where := "row"        # row, room
var on_at := Vector2.ZERO    # for the room: where on the screen the thing is
var leaned := false
var wait_at := -1.0
var reread_at := -1.0
var rush_run := 0
var rush_due := false
var last := {"wait": -99, "reread": -99, "rush": -99, "back": -99}
var away_at := 0.0
var tip: PanelContainer
var tip_tw: Tween
var tip_until := -1.0
var now := 0.0


func setup(m) -> void:
	main = m


func _on() -> bool:
	return main.settings.get("notice", true) and main.in_game and main.game.story != null and not main.game.ended


func _busy() -> bool:
	return main.pending != null or main.rolling != null or main.menus.is_open()


func _turn() -> int:
	return main.game.turn


# new choices are up; n is how many characters of story came before them
func attach(n: int) -> void:
	stop()
	shown_at = now
	chars = n
	considered.clear()
	if not _on():
		return
	if rush_due and _turn() - last.rush >= GAP.rush:
		rush_due = false
		var at := shown_at
		get_tree().create_timer(0.9).timeout.connect(func():
			if shown_at == at and on_i < 0 and murmur("rush", "lead"):
				last.rush = _turn())
	wait_at = now + clampf(14.0 + chars * 0.045, 22.0, 80.0)


# a choice has been made: which others the player had a hand on first
func leave(i: int) -> Array:
	var t := now - shown_at
	rush_run = rush_run + 1 if chars > 160 and t < chars * 0.012 else 0
	if rush_run >= 4:
		rush_run = 0
		rush_due = true
	var out: Array = []
	for k in considered:
		if k != i:
			out.append(k)
	stop()
	return out


func stop() -> void:
	on_i = -1
	leaned = false
	wait_at = -1.0
	reread_at = -1.0
	hide_tip(true)


# the pointer on a row in the column
func on_row(i: int, on: bool) -> void:
	if on:
		_enter(i, HOVER, "row", Vector2.ZERO)
	elif on_i == i:
		_out()


func key_on(i: int) -> void:
	_enter(i, KEY, "row", Vector2.ZERO)


# his eyes on the thing a choice is about, in the room (game/hotspots.gd)
func eyes_on(i: int, on: bool, at: Vector2) -> void:
	if on:
		if on_i == i and on_where == "room":
			on_at = at
			return
		_enter(i, EYES, "room", at)
	elif on_i == i and on_where == "room":
		_out()


func _enter(i: int, delay: float, where: String, at: Vector2) -> void:
	if not _on() or _busy():
		return
	if on_i == i and on_where == where:
		return
	on_i = i
	on_since = now
	on_delay = delay
	on_where = where
	on_at = at
	leaned = false


func _out() -> void:
	on_i = -1
	leaned = false
	if tip != null and tip.get_meta("mode", "") in ["row", "room"]:
		hide_tip(false)


func _lean() -> void:
	var w = main.game.whisper(on_i)
	considered[on_i] = true
	if w == null:
		return
	_show(w, on_where)


func murmur(what: String, mode: String) -> bool:
	if main.game.story == null:
		return false
	var w = main.game.murmur(what)
	if w == null:
		return false
	_show(w, mode)
	return true


# ---------------------------------------------------------------- on the page

func _show(w: Dictionary, mode: String) -> void:
	hide_tip(true)
	var st := str(main.content.voices.get(str(w.speaker), {}).get("style", w.speaker))
	var v := Look.voice(st)
	var c := Look.voice_color(st)
	var size: int = main.column.size_px
	var col: Column = main.column
	var width := minf(col.size.x - 90.0, 520.0)
	tip = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Look.NIGHT.lightened(0.05), 0.97)
	sb.border_color = Color(c, 0.7)
	sb.set_content_margin_all(12)
	# the voice's rule on the side nearest what it's talking about: by a choice, that's the column
	if mode == "row":
		sb.border_width_right = 3
		sb.content_margin_right = 16
	else:
		sb.border_width_left = 3
		sb.content_margin_left = 16
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(3, 5)
	tip.add_theme_stylebox_override("panel", sb)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.set_meta("mode", mode)
	# the width first: a paragraph that fits its height to its words works the height out at the
	# width it has when it goes in, and at no width at all that's a letter a line, a box two
	# thousand pixels tall that never gives the height back
	var r := RichTextLabel.new()
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size = Vector2(width, 0)
	r.push_font(UiBits.spaced("ui_b", 2), int(size * 0.66))
	r.push_color(c)
	r.add_text(str(w.label) + "   ")
	r.pop()
	r.pop()
	r.push_font(Look.font(v.font), int(size * 0.92 * float(v.size)))
	r.push_color(c)
	var text := str(w.text)
	r.add_text(text.to_lower() if v.get("lower", false) else text)
	r.pop()
	r.pop()
	tip.add_child(r)
	tip.top_level = true
	tip.modulate.a = 0.0
	main.root.add_child(tip)
	tip.reset_size()
	_place_tip(tip, mode, width)
	tip_tw = tip.create_tween()
	tip_tw.tween_property(tip, "modulate:a", 1.0, 0.25)
	tip_until = now + (14.0 if mode == "lead" else (7.0 if mode == "float" else 30.0))
	main.audio.sfx("whisper")
	main.notes.lean(str(w.speaker))
	# the words are laid out a frame late: fit the box to them then, and place it again
	var t := tip
	await get_tree().process_frame
	if is_instance_valid(t) and t == tip:
		t.reset_size()
		_place_tip(t, mode, width)


# Where the words go: beside the choice the hand is on, out over the room, so the other choices
# stay in sight; by the thing in the room; or over the choices.
func _place_tip(t: PanelContainer, mode: String, width: float) -> void:
	var col: Column = main.column
	var screen_h: float = main.root.size.y
	var h := t.size.y
	match mode:
		"row":
			var row: Control = col.row_for_index(on_i)
			if row != null:
				var y := row.global_position.y + row.size.y * 0.5 - h * 0.5
				t.global_position = Vector2(col.global_position.x - t.size.x - 22.0, clampf(y, 16.0, maxf(16.0, screen_h - h - 16.0)))
		"room":
			var p := on_at + Vector2(24, 18)
			var sheet_w: float = main.view.sheet.size.x
			p.x = clampf(p.x, 20.0, sheet_w - width - 50.0)
			p.y = clampf(p.y, 16.0, maxf(16.0, screen_h - h - 16.0))
			t.global_position = p
		"lead":
			t.global_position = Vector2(col.global_position.x + 30.0, clampf(col.choices_box.global_position.y - h - 14.0, 16.0, maxf(16.0, screen_h - h - 16.0)))
		_:
			t.global_position = Vector2(col.global_position.x + 30.0, maxf(16.0, screen_h - h - 60.0))


func hide_tip(quick: bool) -> void:
	tip_until = -1.0
	if tip == null:
		return
	var t := tip
	tip = null
	if quick:
		t.queue_free()
		return
	var tw := t.create_tween()
	tw.tween_property(t, "modulate:a", 0.0, 0.25)
	tw.tween_callback(t.queue_free)


func away(gone: bool) -> void:
	if gone:
		away_at = now
		return
	var dt := now - away_at
	away_at = 0.0
	if dt >= AWAY and _on():
		get_tree().create_timer(0.7).timeout.connect(func():
			if not _busy() and murmur("back", "float"):
				last.back = _turn())


func _process(dt: float) -> void:
	now += dt
	if tip != null and tip_until > 0.0 and now > tip_until:
		hide_tip(false)
	if not _on():
		return
	if on_i >= 0:
		if not considered.has(on_i) and now - on_since >= LOOK:
			considered[on_i] = true
		if not leaned and now - on_since >= on_delay and not _busy():
			leaned = true
			_lean()
	if wait_at > 0.0 and now >= wait_at:
		if _busy() or on_i >= 0:
			wait_at = now + 8.0
		else:
			wait_at = -1.0
			if _turn() - last.wait >= GAP.wait and murmur("wait", "lead"):
				last.wait = _turn()
	# reading back up the night
	if main.column.is_reading_back():
		if reread_at < 0.0 and _turn() - last.reread >= GAP.reread:
			reread_at = now + REREAD
		elif reread_at > 0.0 and now >= reread_at:
			reread_at = -1.0
			if not _busy() and murmur("reread", "float"):
				last.reread = _turn()
	else:
		reread_at = -1.0
