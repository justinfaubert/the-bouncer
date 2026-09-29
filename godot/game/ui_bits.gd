# Small pieces of the page: text in the column's type, a choice the hand can rest on, a way out,
# a die drawn small, a button in the menus.
class_name UiBits
extends RefCounted


# A paragraph: parts are [font key, size, colour, text], run together.
static func para(parts: Array, width_fill := true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = false
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.selection_enabled = false
	if width_fill:
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_constant_override("line_separation", 5)
	for p in parts:
		r.push_font(Look.font(p[0]), int(p[1]))
		r.push_color(p[2])
		r.add_text(str(p[3]))
		r.pop()
		r.pop()
	return r


static func label(text: String, font_key: String, size: int, color: Color, spacing := 0) -> Label:
	var l := Label.new()
	l.text = text
	var f: Font = Look.font(font_key)
	if spacing != 0:
		var fv := FontVariation.new()
		fv.base_font = f
		fv.spacing_glyph = spacing
		f = fv
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func spaced(font_key: String, spacing: int) -> Font:
	var fv := FontVariation.new()
	fv.base_font = Look.font(font_key)
	fv.spacing_glyph = spacing
	return fv


# A button in the menus: words knocked out of the night ink, a rule under the one the hand is on.
static func button(text: String, primary := false, size := 26) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", spaced("ui_b", 2))
	b.add_theme_font_size_override("font_size", size)
	var c := Look.INK if primary else Look.INK_2
	b.add_theme_color_override("font_color", c)
	b.add_theme_color_override("font_hover_color", Look.STOCK)
	b.add_theme_color_override("font_focus_color", Look.STOCK)
	b.add_theme_color_override("font_pressed_color", Look.RED)
	b.add_theme_color_override("font_disabled_color", Look.FAINT)
	var none := StyleBoxEmpty.new()
	var under := StyleBoxLine.new()
	under.color = Look.RED if primary else Look.MUTED
	under.thickness = 2
	under.grow_begin = 0
	under.grow_end = 0
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0, 0, 0, 0)
	hover.border_color = Look.RED
	hover.border_width_bottom = 2
	hover.content_margin_bottom = 2
	for st in ["normal", "disabled"]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0)
		s.border_color = Color(Look.RED, 0.9) if primary else Color(0, 0, 0, 0)
		s.border_width_bottom = 2 if primary else 0
		s.content_margin_bottom = 2
		b.add_theme_stylebox_override(st, s)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("hover_pressed", hover)
	return b


# A panel of the night ink with a hairline round it, for the menus and his notes.
static func sheet_style(alpha := 0.97) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(Look.NIGHT, alpha)
	s.border_color = Color(Look.MUTED, 0.35)
	s.set_border_width_all(1)
	s.content_margin_left = 48
	s.content_margin_right = 48
	s.content_margin_top = 40
	s.content_margin_bottom = 40
	return s
