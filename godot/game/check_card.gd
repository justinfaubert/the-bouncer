# A check, in the column: which voice lent it and what it's against; once the first die is down,
# what the second one needs, the six faces with the ones that would do it lit; then the stamp, and
# the sum. The dice themselves are in the room (game/dice.gd).
class_name CheckCard
extends VBoxContainer

const WORD := ["", "one", "two", "three", "four", "five", "six"]

var item := {}
var need := {}
var faces: HBoxContainer
var needs_row: HBoxContainer
var hint: Label
var stamp_box: HBoxContainer
var sum: Label
var voice_line: RichTextLabel
var vc := Look.MUTED
var hit := 0


# What the second die has to show once the first is down. The dice's stretch and the modifiers
# are in it already, so it's the honest answer (prototype/web/src/ui/roll.js, needs).
static func needs(r: Dictionary) -> Dictionary:
	var pass_list: Array = []
	for b in range(1, 7):
		pass_list.append(Checks.resolve(int(r.d1), b, int(r.target), int(r.mod), int(r.tension)).success)
	var n := pass_list.count(true)
	var low := pass_list.find(true) + 1
	var text: String
	if n == 6:
		text = "Any second die will do."
	elif n == 0:
		text = "No second die can save it."
	elif low == 6:
		text = "Needs a six on the second die."
	elif low == 2:
		text = "Anything but a one on the second die."
	else:
		text = "Needs " + WORD[low] + " or better on the second die."
	return {"pass": pass_list, "n": n, "text": text}


static func sum_text(it: Dictionary) -> String:
	var r: Dictionary = it.roll
	var s := "%d + %d = %d" % [int(r.d1), int(r.d2), int(r.natural)]
	var swung := 7 + BUtil.js_round((int(r.natural) - 7) * Checks.volatility(int(r.tension)))
	if swung != int(r.natural):
		s += ", his head swings it to %d" % swung
	var bits := [s]
	for m in it.get("mods", []):
		bits.append(("+" if int(m.value) > 0 else "−") + str(absi(int(m.value))) + " " + str(m.label))
	bits.append("%d against %d" % [int(r.total), int(r.target)])
	return "  ·  ".join(bits)


func setup(it: Dictionary, odds_text: String, size: int) -> void:
	item = it
	need = needs(it.roll)
	vc = Look.voice_color(str(it.voice))
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	add_child(head)
	head.add_child(UiBits.label(str(it.label), "ui_b", int(size * 0.8), vc, 2))
	head.add_child(UiBits.label(str(it.word) + " " + str(it.target), "ui_b", int(size * 0.8), Look.INK_2, 1))
	if odds_text != "":
		head.add_child(UiBits.label(odds_text, "ui", int(size * 0.8), Color(vc, 0.8), 1))
	hint = UiBits.label("Hold to shake them. Let go to throw.", "ui", int(size * 0.74), Look.MUTED, 1)
	hint.visible = false
	add_child(hint)
	voice_line = RichTextLabel.new()
	voice_line.fit_content = true
	voice_line.scroll_active = false
	voice_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	voice_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voice_line.visible = false
	add_child(voice_line)
	needs_row = HBoxContainer.new()
	needs_row.add_theme_constant_override("separation", 5)
	needs_row.modulate.a = 0.0
	add_child(needs_row)
	faces = HBoxContainer.new()
	faces.add_theme_constant_override("separation", 4)
	needs_row.add_child(faces)
	for b in range(1, 7):
		var d := MiniDie.new()
		d.value = b
		d.yes = need.pass[b - 1]
		d.custom_minimum_size = Vector2(size * 0.9, size * 0.9)
		faces.add_child(d)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(8, 0)
	needs_row.add_child(gap)
	var nt := UiBits.label(str(need.text), "read", int(size * 0.84), Look.INK_2)
	nt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	needs_row.add_child(nt)
	stamp_box = HBoxContainer.new()
	stamp_box.add_theme_constant_override("separation", 12)
	stamp_box.modulate.a = 0.0
	add_child(stamp_box)
	var ok: bool = it.success
	var st := UiBits.label("SUCCESS" if ok else "FAILURE", "ui_b", int(size * 1.35), Look.GOOD if ok else Look.RED, 4)
	stamp_box.add_child(st)
	var crit = it.roll.get("crit")
	if crit != null:
		var cl := UiBits.label("DOUBLE SIX" if crit == "success" else "DOUBLE ONE", "ui_b", int(size * 0.7), Look.GOOD if ok else Look.RED, 3)
		cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stamp_box.add_child(cl)
	sum = UiBits.label(sum_text(it), "ui", int(size * 0.72), Look.MUTED, 1)
	sum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum.modulate.a = 0.0
	add_child(sum)


func waiting_in_hand(on: bool) -> void:
	hint.visible = on


# the first die is down: what the second needs
func first_down() -> void:
	hint.visible = false
	create_tween().tween_property(needs_row, "modulate:a", 1.0, 0.25)


# the second die is down: ring its face among the six
func second_down() -> void:
	var d: MiniDie = faces.get_child(int(item.roll.d2) - 1)
	d.hit = true
	d.queue_redraw()


func stamp() -> void:
	hint.visible = false
	needs_row.modulate.a = 1.0
	second_down()
	var tw := create_tween()
	stamp_box.scale = Vector2(1.25, 1.25)
	stamp_box.pivot_offset = Vector2(0, 20)
	tw.tween_property(stamp_box, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(stamp_box, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_IN)
	tw.tween_property(sum, "modulate:a", 1.0, 0.3)


# at rest from the start: drawn again, or dice set to "at once"
func still() -> void:
	hint.visible = false
	needs_row.modulate.a = 1.0
	stamp_box.modulate.a = 1.0
	sum.modulate.a = 1.0
	second_down()


# a voice, while they're shaken
func said(w: Dictionary, size: int) -> void:
	voice_line.clear()
	var st := str(w.speaker)
	var c := Look.voice_color(st)
	voice_line.push_font(UiBits.spaced("ui_b", 2), int(size * 0.66))
	voice_line.push_color(c)
	voice_line.add_text(str(w.label) + "   ")
	voice_line.pop()
	voice_line.pop()
	var v := Look.voice(st)
	voice_line.push_font(Look.font(v.font), int(size * 0.9 * v.size))
	voice_line.push_color(c)
	voice_line.add_text(str(w.text).to_lower() if v.get("lower", false) else str(w.text))
	voice_line.pop()
	voice_line.pop()
	voice_line.visible = true


func _draw() -> void:
	# a hairline down the left in the voice's colour
	draw_rect(Rect2(Vector2(-14, 2), Vector2(2, size.y - 4)), Color(vc, 0.8))


class MiniDie extends Control:
	const PIPS := {
		1: [[10, 10]], 2: [[5.5, 5.5], [14.5, 14.5]], 3: [[5.5, 5.5], [10, 10], [14.5, 14.5]],
		4: [[5.5, 5.5], [14.5, 5.5], [5.5, 14.5], [14.5, 14.5]],
		5: [[5.5, 5.5], [14.5, 5.5], [10, 10], [5.5, 14.5], [14.5, 14.5]],
		6: [[5.5, 5], [14.5, 5], [5.5, 10], [14.5, 10], [5.5, 15], [14.5, 15]],
	}
	var value := 1
	var yes := false
	var hit := false

	func _draw() -> void:
		var k := size.x / 20.0
		var body := Look.STOCK if yes else Color(Look.STOCK, 0.18)
		var pip := Look.NIGHT if yes else Color(Look.STOCK, 0.5)
		draw_rect(Rect2(Vector2(1, 1) * k, Vector2(18, 18) * k), body, true)
		if not yes:
			draw_rect(Rect2(Vector2(1, 1) * k, Vector2(18, 18) * k), Color(Look.STOCK, 0.4), false, 1.0)
		for p in PIPS[value]:
			draw_circle(Vector2(p[0], p[1]) * k, 1.8 * k, pip)
		if hit:
			draw_arc(size / 2.0, size.x * 0.72, 0, TAU, 28, Look.RED, 2.0, true)
