class_name KeysCard
extends CanvasLayer
# The keys for whatever's in his hands, on a card at the foot of the picture: the same card, laid
# out the same way, for the darts, the table, the cigarette machine and the beer mats, so a player
# who's learned one knows where to look for the next. It comes up when he steps up to a thing, and
# once the player's used it a few times (or after a while) it folds down to one faint line,
# "F1  the keys", and stays out of the way. F1 brings it back up, or folds it again.
#
#   main.keys.show_for("darts", [["Mouse", "aim with his eyes"], ["Hold LMB, pull back", "draw, let go to throw"]])
#   main.keys.used()      # the player did something with it: a few of these fold the card
#   main.keys.hide_card() # he's stepped away

const FOLD_AFTER_USES := 3
const FOLD_AFTER_SECS := 14.0
const PAD := 14.0

var box: PanelContainer
var grid: GridContainer
var title: Label
var folded: Label
var what := ""
var corner := "bl"            # where it sits: "bl" foot of the picture, "tr" top right (the table talks at the foot)
var _rows: Array = []
var _uses := 0
var _t := 0.0
var _open := false            # the whole card's up (not folded)
var _seen := {}               # things whose card has folded once: next time it starts folded


func _init() -> void:
	layer = 40


func _ready() -> void:
	box = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Look.NIGHT, 0.78)
	sb.border_color = Color(Look.STOCK, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = PAD
	sb.content_margin_right = PAD
	sb.content_margin_top = PAD * 0.7
	sb.content_margin_bottom = PAD * 0.8
	box.add_theme_stylebox_override("panel", sb)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	title = _label(15, Color(Look.MUTED, 0.95), "ui_b")
	v.add_child(title)
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 3)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grid)
	var foot := _label(13, Color(Look.FAINT, 1.0), "ui_r")
	foot.text = "F1 folds this away.  Esc steps back."
	v.add_child(foot)
	add_child(box)
	folded = _label(15, Color(Look.MUTED, 0.75), "ui_b")
	folded.text = "F1   the keys"
	add_child(folded)
	box.visible = false
	folded.visible = false
	get_viewport().size_changed.connect(_place)


func _label(size: int, col: Color, font: String) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", UiBits.spaced(font, 2))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(Look.NIGHT, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# The card for a thing: rows of [the key or the hand, what it does].
func show_for(thing: String, rows: Array, heading := "", where := "bl") -> void:
	what = thing
	corner = where
	_uses = 0
	_t = 0.0
	set_rows(rows, heading)
	_open = not _seen.has(thing)
	_show()


# The rows change with what he's doing (the table: ball in hand, or the cue down on the line).
func set_rows(rows: Array, heading := "") -> void:
	if rows == _rows and (heading == "" or heading == title.text):
		return
	_rows = rows.duplicate(true)
	if heading != "":
		title.text = heading.to_upper()
	# freed at once, not queued: the card measures itself from what's in it this frame
	for c in grid.get_children():
		grid.remove_child(c)
		c.free()
	for r in rows:
		var k := _label(15, Color(Look.STOCK, 0.96), "ui_b")
		k.text = str(r[0])
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(k)
		var d := _label(15, Color(Look.INK_2, 0.9), "ui_r")
		d.text = str(r[1])
		grid.add_child(d)
	_place.call_deferred()


func hide_card() -> void:
	what = ""
	box.visible = false
	folded.visible = false


func used() -> void:
	if what == "" or not _open:
		return
	_uses += 1
	if _uses >= FOLD_AFTER_USES:
		_fold()


func toggle() -> void:
	if what == "":
		return
	_open = not _open
	_t = 0.0
	_uses = 0
	_show()


func _fold() -> void:
	_open = false
	_seen[what] = true
	_show()


func _show() -> void:
	box.visible = _open and what != ""
	folded.visible = (not _open) and what != ""
	_place()


func _place() -> void:
	var vp := get_viewport().get_visible_rect().size
	box.size = Vector2.ZERO
	box.reset_size()
	var s := box.get_combined_minimum_size()
	box.size = s
	folded.reset_size()
	var fs := folded.get_combined_minimum_size()
	if corner == "tr":
		box.position = Vector2(vp.x - s.x - 24, 24)
		folded.position = Vector2(vp.x - fs.x - 26, 20)
	else:
		box.position = Vector2(24, vp.y - s.y - 24)
		folded.position = Vector2(26, vp.y - fs.y - 20)


func _process(dt: float) -> void:
	if what == "" or not _open:
		return
	_t += dt
	if _t > FOLD_AFTER_SECS and _uses > 0:
		_fold()


func _input(e: InputEvent) -> void:
	if what == "":
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_F1:
		toggle()
		get_viewport().set_input_as_handled()
