# Things in his hands: what he's handed at the door, or picks up (content/data/props.yaml; a line
# in the Ink hands one over with #prop:). They come up into his view, printed clean, and the player
# handles them with their own hands:
#
#   a licence   click it and it turns over; the pointer over it tips it to the light, and the
#               hologram under the laminate runs through its colours as it does (a real one's foil
#               moves; a printed one sits there); E holds it up beside the face of whoever handed it
#               over, in the room, for the player to compare the two.
#   the phone   the kid holds it up with a photo of his licence on it. E, or a click on it, takes it;
#               then R (or a drag across it) swipes to the next photo, and E brings it closer.
#   the binder  the 86 binder from under the till: Q and R leaf through the sleeves. Staying on a
#               page is looking at it; getting to the back is having been through them all.
#
# Every handling goes to the game (main.toy, Game.toy): if a choice on offer is waiting for it,
# that choice is made; otherwise a voice may say something. A thing stays in his hands while the
# choices it came with are on offer, or while a choice on offer waits for it; after that he hands it
# back. Esc puts it down for a moment; E picks it up again.
#
# The pictures on them (the licence's face and fields, the phone's photos, the binder's sleeves) are
# made once, in a darkroom of small viewports, before the night starts.
#
# His own hand is in view with them (models/people/his_*.glb): the right one holds the licence or
# the phone, and turns and tips with it.
class_name Props
extends Node

const PEOPLE := "res://models/people/"
const CARD := Vector2(0.0856, 0.054)
const TILT := 16.0
const TILT_SEEN := 40.0
const SWEET := Vector2(-8.0, -6.0)          # the tip of a card (degrees, as held.tilt) that meets the lamp
const DWELL := 3.0
const MONTHS := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
# the licence's photo: whose face, as a model
const FACES := {"hoodie": "hoodie_door", "driver": "driver", "goodshoes": "goodshoes_card", "him": "him_card"}

var main
var P := {}                      # content.props
var tex := {}                    # the darkroom's pictures, by name
var jobs: Array = []
var developing := false
var held = null                  # what's in his hands: a Dictionary, or null
var _waiting := {}               # held out before it can be in his hand: he's on his way, or they are
const WAIT_MAX := 12.0           # seconds it waits for whoever's bringing it, if they never come into sight
# his own hand: which holds what
const HAND_FOR := {"card": ["his_right_card", "card"], "phone": ["his_right_phone", "phone"]}
# in Gary's office the eyes are Gary's, and so are the hands (content/ink/office.ink)
const GARY_HAND_FOR := {"card": ["gary_right_card", "card"], "phone": ["gary_right_phone", "phone"]}
# a card or a phone that's in his hands isn't in theirs: which figure holds each, and its parts
const ON_FIGURE := {"driver_card": ["driver", ["card", "card_body"]], "goodshoes_card": ["goodshoes", ["card", "card_body"]],
	"hoodie_phone": ["hoodie", ["phone", "phone_screen"]]}
var _figs_in := 0.0
var _holo_face_shader: Shader
var hint: Label
var t := 0.0


func setup(m) -> void:
	main = m
	P = main.content.get("props", {})
	hint = Label.new()
	hint.add_theme_font_override("font", UiBits.spaced("ui_b", 2))
	hint.add_theme_font_size_override("font_size", 19)
	hint.add_theme_color_override("font_color", Color(Look.STOCK, 0.92))
	hint.add_theme_color_override("font_outline_color", Color(Look.NIGHT, 0.9))
	hint.add_theme_constant_override("outline_size", 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.anchor_left = 0.0
	hint.anchor_right = View.WORLD_W
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_top = -64
	hint.offset_bottom = -30
	hint.visible = false
	main.root.add_child(hint)
	main.view.sheet.gui_input.connect(_on_sheet_input)
	# the pictures: faces first, then what they're printed on
	for face in FACES:
		_job("face_" + face, _portrait.bind(FACES[face]))
	for id in P:
		var pr = P[id]
		if pr is Dictionary and pr.get("kind") == "card":
			_job("card_%s_front" % id, _card_face.bind(pr, true))
			_job("card_%s_back" % id, _card_face.bind(pr, false))
			_job("card_%s_holo" % id, _card_holo.bind(pr))
	_job("photo_table", _photo_table)
	_job("photo_pool", _photo_pool)
	if P.has("binder"):
		var sleeves: Dictionary = P.binder.get("sleeves", {})
		for k in sleeves:
			_job("sleeve_" + str(k), _sleeve.bind(str(k), sleeves[k]))
		_job("sleeve_empty", _sleeve.bind("", {}))
	_develop.call_deferred()


# ---------------------------------------------------------------- the darkroom

func _job(name: String, build: Callable) -> void:
	jobs.append([name, build])


func _develop() -> void:
	if developing or DisplayServer.get_name() == "headless":
		return
	developing = true
	while not jobs.is_empty():
		var job: Array = jobs.pop_front()
		var sv: SubViewport = job[1].call()
		if sv == null:
			continue
		sv.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := sv.get_texture().get_image()
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			img.generate_mipmaps()
			tex[job[0]] = ImageTexture.create_from_image(img)
		sv.queue_free()
	developing = false


func _viewport(size: Vector2i, own_world: bool) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = size
	sv.own_world_3d = own_world
	sv.transparent_bg = false
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(sv)
	return sv


# A face for a licence: the head of their model, straight on against the pale backdrop, lit flat
# the way the licensing office lights everybody.
func _portrait(model: String) -> SubViewport:
	if not FileAccess.file_exists(PEOPLE + model + ".glb"):
		return null
	var sv := _viewport(Vector2i(300, 380), true)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("c6ccd0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d8dde2")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var body: Node3D = main.pub.model(PEOPLE + model + ".glb", Vector3.ZERO, sv)
	body.rotation.y = 0.0
	var an: Dictionary = main.stage.anchors_of(model)
	var h: Array = an.get("head", [0, 1.5, 0])
	var hp := Vector3(h[0], h[1], h[2])
	var cam := Camera3D.new()
	cam.fov = 21.0
	cam.environment = env
	cam.set_cull_mask_value(View.MASK_LAYER, false)
	sv.add_child(cam)
	cam.position = hp + Vector3(0, 0.035, -1.2)
	cam.look_at(hp + Vector3(0, -0.02, 0), Vector3.UP)
	var back := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(3, 3)
	back.mesh = q
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color("bfc6cb")
	back.material_override = bm
	sv.add_child(back)
	back.position = hp + Vector3(0, 0, 0.7)
	var key := DirectionalLight3D.new()
	sv.add_child(key)
	key.light_energy = 1.1
	key.look_at_from_position(hp + Vector3(0.3, 0.8, -1.5), hp, Vector3.UP)
	var fill := OmniLight3D.new()
	fill.position = hp + Vector3(-0.6, 0.1, -0.9)
	fill.light_energy = 0.6
	fill.omni_range = 3.0
	sv.add_child(fill)
	return sv


func _page(sv: SubViewport) -> Control:
	var c := Control.new()
	c.size = Vector2(sv.size)
	sv.add_child(c)
	return c


func _text(parent: Control, text: String, at: Vector2, font: String, size: int, col: Color, spacing := 0) -> Label:
	var l := UiBits.label(text, font, size, col, spacing)
	l.position = at
	parent.add_child(l)
	return l


func _rect(parent: Control, r: Rect2, col: Color, radius := 0) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _pic(parent: Control, name: String, r: Rect2, alpha := 1.0) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex.get(name)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.position = r.position
	tr.size = r.size
	tr.modulate.a = alpha
	parent.add_child(tr)
	return tr


func _rng(seed_text: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(seed_text)
	return r


# "2026-10-17" as she writes it in marker: OCT 17/26
static func hand_date(iso: String) -> String:
	var p := iso.split("-")
	if p.size() < 3:
		return ""
	return "%s %d/%s" % [MONTHS[clampi(int(p[1]) - 1, 0, 11)], int(p[2]), p[0].substr(2)]


# What a card prints for a field. A number in the yaml comes through the build's JSON as a float,
# and a licence says CLASS 5 and 183 cm, not CLASS 5.0 and 183.0 cm.
static func _field(v) -> String:
	if v is float and is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return str(v)


# A driver's licence, front or back, a hundred pixels to the centimetre.
func _card_face(pr: Dictionary, front: bool) -> SubViewport:
	if str(pr.get("type", "")) == "security":
		return _security_face(pr, front)
	var sv := _viewport(Vector2i(856, 540), true)
	var c := _page(sv)
	var ink := Color("1d2430")
	_rect(c, Rect2(Vector2.ZERO, c.size), Color("d9e0e3"), 0)
	var r := _rng(str(pr.get("number", "")) + ("f" if front else "b"))
	# the guilloche: fine waves across the whole card, the pattern nobody reads
	for i in 44:
		var ln := Line2D.new()
		ln.width = 1.2
		ln.default_color = Color("b7c7cf")
		var y0 := 20.0 + i * 12.5
		for x in range(0, 860, 12):
			ln.add_point(Vector2(x, y0 + sin(x * 0.021 + i * 0.7) * 6.0 + sin(x * 0.007 + i) * 4.0))
		c.add_child(ln)
	if front:
		_rect(c, Rect2(0, 0, 856, 74), Color("2d4868"))
		_text(c, "DRIVER'S LICENCE", Vector2(34, 12), "ui_b", 40, Color("eef2f4"), 3)
		_text(c, "CLASS " + _field(pr.get("class", "")), Vector2(640, 16), "ui_b", 34, Color("eef2f4"), 2)
		var face := "face_" + str(pr.get("face", ""))
		_rect(c, Rect2(32, 98, 238, 300), Color("bfc6cb"))
		if tex.has(face):
			_pic(c, face, Rect2(32, 98, 238, 300))
		var x := 300.0
		_text(c, str(pr.get("surname", "")), Vector2(x, 92), "ui_b", 50, ink, 1)
		_text(c, str(pr.get("given", "")), Vector2(x, 146), "ui", 36, ink, 1)
		# the address, worn past reading, like every address on every licence
		_rect(c, Rect2(x, 198, 330, 12), Color(ink, 0.35), 5)
		_rect(c, Rect2(x, 220, 250, 12), Color(ink, 0.3), 5)
		var cells := [["DOB", str(pr.get("born", ""))], ["EXP", str(pr.get("expires", ""))], ["ISS", str(pr.get("issued", ""))],
			["SEX", str(pr.get("sex", ""))], ["HGT", "%s cm" % _field(pr.get("height", ""))], ["WGT", "%s kg" % _field(pr.get("weight", ""))],
			["EYES", str(pr.get("eyes", ""))], ["HAIR", str(pr.get("hair", ""))]]
		for i in cells.size():
			var cx := x + (i % 2) * 262.0
			var cy := 248.0 + (i / 2) * 50.0
			_text(c, cells[i][0], Vector2(cx, cy + 8), "mono", 17, Color(ink, 0.7))
			var v := _text(c, cells[i][1], Vector2(cx + 58, cy), "ui_b", 30 if i == 0 else 27, Color("a3261f") if i == 0 else ink, 1)
			v.name = cells[i][0]
		_text(c, "DL " + str(pr.get("number", "")), Vector2(x, 452), "mono", 24, ink)
		# the signature: loops along a line, and the tail back under it
		var sig := Line2D.new()
		sig.width = 2.4
		sig.default_color = Color("1f2a44")
		sig.joint_mode = Line2D.LINE_JOINT_ROUND
		var sx := 560.0
		var n := 5 + r.randi() % 4
		for i in n:
			var w := r.randf_range(14, 26)
			var up := r.randf_range(10, 26)
			for k in 9:
				var f := k / 8.0
				sig.add_point(Vector2(sx + w * f, 470.0 - up * sin(f * PI) + r.randf_range(-1, 1)))
			sx += w
		sig.add_point(Vector2(sx - 30, 486))
		sig.add_point(Vector2(560, 480))
		c.add_child(sig)
		# the ghost: the face again, small and faint
		if tex.has(face):
			_pic(c, face, Rect2(700, 330, 112, 140), 0.22)
		if str(pr.get("wear", "")) == "wet":
			for i in 7:
				var s := r.randf_range(40, 130)
				_rect(c, Rect2(r.randf_range(0, 800), r.randf_range(80, 500), s, s * r.randf_range(0.5, 0.9)), Color(0.2, 0.25, 0.3, 0.1), int(s / 2))
	else:
		# the stacked barcode, and the small print
		var bx := 60.0
		var by := 70.0
		for y in 13:
			var xx := bx
			var on := true
			while xx < 796.0:
				var w2 := float(r.randi_range(2, 8))
				if on:
					_rect(c, Rect2(xx, by + y * 16.0, w2, 16.0), ink)
				xx += w2
				on = not on
		var cls := _field(pr.get("class", ""))
		var line1 := ("CLASS %s  ·  NEW DRIVER  ·  DISPLAY N" % cls.trim_suffix("N")) if cls.ends_with("N") else "CLASS " + cls
		_text(c, line1, Vector2(60, 310), "mono", 26, ink)
		_text(c, "RESTRICTIONS: NONE  ·  ENDORSEMENTS: NONE", Vector2(60, 352), "mono", 22, Color(ink, 0.7))
		var num := str(pr.get("number", ""))
		var rev := ""
		for i in range(num.length() - 1, -1, -1):
			rev += num[i]
		_text(c, rev + "   " + str(pr.get("issued", "")).replace("-", ""), Vector2(60, 470), "mono", 20, Color(ink, 0.55))
	return sv


# His security worker licence (content/data/props.yaml), the one Gary holds up in the office: the
# role across the top, the seal in the corner, the photo from before his hair grew, a number, the
# dates. His name is printed where Gary's thumb is (the hand's card anchor covers it), and drawn
# as worn bars, because his name is Hutch's to give.
func _security_face(pr: Dictionary, front: bool) -> SubViewport:
	var sv := _viewport(Vector2i(856, 540), true)
	var c := _page(sv)
	var ink := Color("1d2430")
	_rect(c, Rect2(Vector2.ZERO, c.size), Color("dfe2dc"), 0)
	var r := _rng(str(pr.get("number", "")) + ("f" if front else "b"))
	# the guilloche: rings out from the seal, the pattern nobody reads
	for i in 30:
		var ln := Line2D.new()
		ln.width = 1.2
		ln.default_color = Color("c3cbc4")
		var rr := 40.0 + i * 24.0
		for k in 121:
			var a := TAU * k / 120.0
			ln.add_point(Vector2(760, 470) + Vector2(cos(a), sin(a)) * (rr + sin(a * 9.0 + i) * 5.0))
		c.add_child(ln)
	if front:
		_rect(c, Rect2(0, 0, 856, 80), Color("2f3a33"))
		_text(c, str(pr.get("role", "SECURITY WORKER")), Vector2(34, 14), "ui_b", 44, Color("eef0ea"), 4)
		var face := "face_" + str(pr.get("face", ""))
		_rect(c, Rect2(32, 104, 238, 300), Color("bfc6cb"))
		if tex.has(face):
			_pic(c, face, Rect2(32, 104, 238, 300))
		# the name, under his thumb: surname, given names
		_rect(c, Rect2(400, 158, 350, 30), Color(ink, 0.82), 6)
		_rect(c, Rect2(400, 204, 260, 22), Color(ink, 0.62), 6)
		var cells := [["LIC", str(pr.get("number", ""))], ["ISS", str(pr.get("issued", ""))], ["EXP", str(pr.get("expires", ""))]]
		for i in cells.size():
			var cy := 360.0 + i * 46.0
			_text(c, cells[i][0], Vector2(300, cy + 8), "mono", 17, Color(ink, 0.7))
			_text(c, cells[i][1], Vector2(360, cy), "ui_b", 30, ink, 1)
		# the seal in the corner: rings, and a crown that's only a row of points
		var seal := Vector2(760, 456)
		for k in 3:
			var ring := Line2D.new()
			ring.width = 3.0 if k == 0 else 1.6
			ring.default_color = Color(ink, 0.55)
			var rr := 52.0 - k * 9.0
			for i in 73:
				var a := TAU * i / 72.0
				ring.add_point(seal + Vector2(cos(a), sin(a)) * rr)
			c.add_child(ring)
		var crown := Line2D.new()
		crown.width = 2.4
		crown.default_color = Color(ink, 0.6)
		for i in 9:
			crown.add_point(seal + Vector2(-20 + i * 5.0, -2.0 - (10.0 if i % 2 == 0 else 0.0)))
		c.add_child(crown)
		_rect(c, Rect2(seal.x - 20, seal.y + 2, 40, 5), Color(ink, 0.6), 2)
	else:
		# the barcode, and what the card says about itself
		var bx := 60.0
		var xx := bx
		var on := true
		while xx < 520.0:
			var w2 := float(r.randi_range(2, 7))
			if on:
				_rect(c, Rect2(xx, 70, w2, 110), ink)
			xx += w2
			on = not on
		_text(c, "CARRY THIS LICENCE WHILE WORKING", Vector2(60, 240), "mono", 24, ink)
		_text(c, "AND SHOW IT ON REQUEST.", Vector2(60, 274), "mono", 24, ink)
		_text(c, "NOT TRANSFERABLE.", Vector2(60, 330), "mono", 22, Color(ink, 0.7))
		_text(c, str(pr.get("number", "")).replace(" ", "") + "   " + str(pr.get("issued", "")).replace("-", ""), Vector2(60, 470), "mono", 20, Color(ink, 0.55))
	return sv


# A licence's hologram, as a picture the shader reads (look/licence.gdshader): red is how much
# foil, green which way its grating runs (a turn: the tip it answers to), blue where in that tip it
# catches. A field of waves over the whole card, each row catching a little after the one above;
# the seal over the corner of the photo, so the photo can't be swapped without breaking it, its
# rings and the sun's rays ruled out from its middle, so a light runs round them as the card turns
# and the rings come up one after another; the face again, in the foil, by the printed ghost; and
# the birthday along a wave at the foot, in print too small to read. Drawn bold: a card in his hand
# is a few hundred pixels across, and a hairline in the foil is no line at all.
func _card_holo(pr: Dictionary) -> SubViewport:
	var sv := _viewport(Vector2i(856, 540), true)
	sv.transparent_bg = true
	var c := _page(sv)
	var foil := func(amount: float, grating: float, start: float, a := 1.0) -> Color:
		return Color(amount, grating, start, a)
	# ruled out from a middle: a line round it whose grating turns with it, g0 where the line
	# starts to g1 where it ends (a turn the other way round from the picture's angles: its y runs
	# down, the card's up)
	var radial := func(ln: Line2D, amount: float, g0: float, g1: float, start: float) -> void:
		var g := Gradient.new()
		g.set_color(0, foil.call(amount, g0, start))
		g.set_color(1, foil.call(amount, g1, start))
		ln.gradient = g
	# the waves
	for row in 12:
		var ln := Line2D.new()
		ln.width = 6.0
		ln.default_color = foil.call(0.55, 0.25 + 0.04 * (row % 2), fposmod(row * 0.083, 1.0))
		var y0 := 22.0 + row * 45.0
		for x in range(-12, 872, 8):
			ln.add_point(Vector2(x, y0 + sin(x * 0.038 + row * 1.1) * 9.0))
		c.add_child(ln)
	# the seal: rings, and inside them the sun coming up out of three waves
	var seal := Vector2(262, 372)
	for k in 4:
		var ring := Line2D.new()
		ring.width = 8.0 if k == 0 else 5.5
		var rr := 94.0 - k * 13.0
		for i in 97:
			var a := TAU * i / 96.0
			ring.add_point(seal + Vector2(cos(a), sin(a)) * rr)
		radial.call(ring, 1.0 if k == 0 else 0.9, 1.0, 0.0, 0.25 * k)
		c.add_child(ring)
	var sun := Line2D.new()
	sun.width = 6.0
	for i in 33:
		var a := PI + PI * i / 32.0
		sun.add_point(seal + Vector2(0, 8) + Vector2(cos(a), sin(a)) * 28.0)
	radial.call(sun, 1.0, 0.5, 0.0, 0.55)
	c.add_child(sun)
	for i in 9:
		var ray := Line2D.new()
		ray.width = 5.0
		var a := PI + PI * (i + 0.5) / 9.0
		ray.default_color = foil.call(0.95, fposmod(-a / TAU, 1.0), 0.6 + 0.04 * i)
		ray.add_point(seal + Vector2(0, 8) + Vector2(cos(a), sin(a)) * 36.0)
		ray.add_point(seal + Vector2(0, 8) + Vector2(cos(a), sin(a)) * 56.0)
		c.add_child(ray)
	for w in 3:
		var wave := Line2D.new()
		wave.width = 5.5
		wave.default_color = foil.call(1.0, 0.0, 0.1 + 0.25 * w)
		for i in 25:
			var x := -50.0 + i * 100.0 / 24.0
			wave.add_point(seal + Vector2(x, 22.0 + w * 14.0 + sin(i * 0.9 + w) * 5.0))
		c.add_child(wave)
	# the face, in the foil, over the printed ghost
	var face := "face_" + str(pr.get("face", ""))
	if tex.has(face):
		var tr := _pic(c, face, Rect2(700, 330, 112, 140))
		tr.material = _holo_face_material()
	# the birthday, small, along a wave at the foot (a licence with no birthday on it: its number)
	var born := str(pr.get("born", ""))
	var p := born.split("-")
	var day := ("%d %s %s" % [int(p[2]), MONTHS[clampi(int(p[1]) - 1, 0, 11)], p[0]]) if p.size() >= 3 else str(pr.get("number", born))
	var x := 30.0
	var i := 0
	while x < 830.0:
		var l := _text(c, day, Vector2(x, 506.0 + sin(x * 0.012) * 5.0), "mono", 15, foil.call(0.85, 0.2, 0.33 + 0.04 * i), 1)
		l.rotation = cos(x * 0.012) * 0.06
		x += 138.0
		i += 1
	return sv


# The face in the foil: its shadows (the eyes, the hair, the line of the jaw) are where the foil
# is, at a grating of their own; the pale backdrop of the licensing office drops out.
func _holo_face_material() -> ShaderMaterial:
	if _holo_face_shader == null:
		_holo_face_shader = Shader.new()
		_holo_face_shader.code = "shader_type canvas_item;\n" \
			+ "void fragment() {\n" \
			+ "	vec4 c = texture(TEXTURE, UV);\n" \
			+ "	float d = 1.0 - dot(c.rgb, vec3(0.3, 0.59, 0.11));\n" \
			+ "	COLOR = vec4(smoothstep(0.3, 0.8, d) * 0.95, 0.62, 0.45, c.a * smoothstep(0.22, 0.4, d));\n" \
			+ "}\n"
	var m := ShaderMaterial.new()
	m.shader = _holo_face_shader
	return m


# The kid's first photo: the licence on the kitchen table at home, under the light over it,
# taken from where he stood.
func _photo_table() -> SubViewport:
	if not tex.has("card_hoodie_card_front"):
		return null
	var sv := _viewport(Vector2i(540, 720), true)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1a1714")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("6e6456")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var cam := Camera3D.new()
	cam.environment = env
	cam.fov = 52.0
	sv.add_child(cam)
	cam.look_at_from_position(Vector3(0.03, 0.34, 0.19), Vector3(0, 0, -0.01), Vector3.UP)
	cam.rotation.z += deg_to_rad(-6)
	var top := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 0.04, 1.0)
	top.mesh = bm
	var tm := StandardMaterial3D.new()
	tm.albedo_texture = Pub.tex_static("res://textures/wood.png")
	tm.uv1_scale = Vector3(1.6, 1.6, 1.6)
	tm.albedo_color = Color("c9b79c")
	tm.roughness = 0.55
	top.material_override = tm
	top.position = Vector3(0, -0.02, 0)
	sv.add_child(top)
	var card := MeshInstance3D.new()
	var cq := QuadMesh.new()
	cq.size = CARD
	card.mesh = cq
	var cm := StandardMaterial3D.new()
	cm.albedo_texture = tex["card_hoodie_card_front"]
	cm.roughness = 0.35
	card.material_override = cm
	card.rotation = Vector3(deg_to_rad(-90), deg_to_rad(8), 0)
	card.position = Vector3(0.0, 0.001, 0.0)
	sv.add_child(card)
	# a mug at the edge, and the salt
	var mug := MeshInstance3D.new()
	var mc := CylinderMesh.new()
	mc.top_radius = 0.042
	mc.bottom_radius = 0.04
	mc.height = 0.1
	mug.mesh = mc
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color("7a3a2e")
	mug.material_override = mm
	mug.position = Vector3(0.14, 0.05, -0.12)
	sv.add_child(mug)
	var l := OmniLight3D.new()
	l.position = Vector3(-0.1, 0.9, -0.2)
	l.light_color = Color("ffd8a0")
	l.light_energy = 1.6
	l.omni_range = 3.0
	l.shadow_enabled = true
	sv.add_child(l)
	return sv


# The kid's second photo: the pool table through the front window, from the lot, in the rain,
# earlier tonight. He was looking for someone.
func _photo_pool() -> SubViewport:
	var sv := _viewport(Vector2i(540, 720), false)
	sv.world_3d = main.view.eye.find_world_3d()
	var cam := Camera3D.new()
	cam.environment = main.view.env
	cam.fov = 44.0
	cam.set_cull_mask_value(View.MASK_LAYER, false)
	sv.add_child(cam)
	cam.look_at_from_position(Vector3(8.4, 1.5, 12.9), Pub.POOL + Vector3(0.6, 0.9, 0), Vector3.UP)
	cam.rotation.z += deg_to_rad(3)
	return sv


# A sleeve in the binder: the sheet in it (a printout, a photocopy, a photograph), the date in
# marker, and how long.
func _sleeve(k: String, s: Dictionary) -> SubViewport:
	var sv := _viewport(Vector2i(600, 780), true)
	var c := _page(sv)
	var r := _rng("sleeve" + k)
	_rect(c, Rect2(Vector2.ZERO, c.size), Color("2a2b2e"))
	_rect(c, Rect2(18, 14, 564, 752), Color("e9e5da"), 4)
	for hole in [120, 390, 660]:
		_rect(c, Rect2(34, hole, 22, 22), Color("2a2b2e"), 11)
	if s.is_empty():
		_text(c, "", Vector2(80, 80), "hand", 40, Color("222"))
	else:
		var kind := str(s.get("photo", "printout"))
		var ph := Rect2(110, 70, 400, 480)
		var ground := Color("d7d3c8") if kind != "photocopy" else Color("bdb8ad")
		_rect(c, ph, ground)
		if s.has("card") and tex.has("face_" + str(P.get(str(s.card), {}).get("face", ""))):
			_pic(c, "face_" + str(P[str(s.card)].face), ph)
		else:
			_silhouette(c, ph, s.get("who", {}), kind, r)
		if kind == "photocopy":
			for i in 160:
				_rect(c, Rect2(r.randf_range(ph.position.x, ph.end.x), r.randf_range(ph.position.y, ph.end.y), 2, 2), Color(0.1, 0.1, 0.1, 0.5))
			_rect(c, Rect2(ph.position.x + r.randf_range(40, 360), ph.position.y, 2, ph.size.y), Color(0.15, 0.15, 0.15, 0.35))
		var red := Color("b3261e")
		if s.has("words"):
			var w := _text(c, str(s.words), Vector2(120, 580), "hand", 64, Color("1c1c1c"))
			w.rotation = deg_to_rad(-3)
		else:
			var d := _text(c, hand_date(str(s.get("date", ""))), Vector2(120, 575), "hand", 52, Color("1c1c1c"))
			d.rotation = deg_to_rad(r.randf_range(-3, 2))
			var ln := _text(c, str(s.get("length", "")), Vector2(130, 650), "hand", 46, red)
			ln.rotation = deg_to_rad(r.randf_range(-2, 3))
	# the sleeve's plastic: a sheen across it
	var sheen := _rect(c, Rect2(-100, 200, 900, 90), Color(1, 1, 1, 0.08))
	sheen.rotation = deg_to_rad(-24)
	return sv


# Someone nobody's modelled, as the copier left them: a head and shoulders, dark on pale.
func _silhouette(c: Control, ph: Rect2, who: Dictionary, kind: String, r: RandomNumberGenerator) -> void:
	var dark := Color("2b2622") if kind == "photocopy" else Color("4a4038")
	var big: bool = who.get("build", "") == "big"
	var cx := ph.position.x + ph.size.x / 2.0 + r.randf_range(-20, 20)
	var sw := 330.0 if big else 280.0
	_rect(c, Rect2(cx - sw / 2.0, ph.end.y - 160, sw, 170), Color(dark, 0.9), 80)
	var hw := 150.0 if big else 130.0
	var hh := 190.0
	_rect(c, Rect2(cx - hw / 2.0, ph.position.y + 90, hw, hh), Color(dark.lightened(0.25), 0.95), int(hw / 2))
	if who.get("hair", "") == "long":
		_rect(c, Rect2(cx - hw / 2.0 - 18, ph.position.y + 80, hw + 36, hh + 90), Color(dark, 0.8), int(hw / 2))
		_rect(c, Rect2(cx - hw / 2.0 + 10, ph.position.y + 100, hw - 20, hh - 20), Color(dark.lightened(0.3), 0.95), int(hw / 2))
	if who.get("hat", "") == "cap":
		_rect(c, Rect2(cx - hw / 2.0 - 6, ph.position.y + 78, hw + 12, 62), Color(dark.darkened(0.3), 1.0), 30)
	if "beard" in who.get("face", []):
		_rect(c, Rect2(cx - hw / 2.0 + 14, ph.position.y + 90 + hh * 0.6, hw - 28, hh * 0.45), Color(dark.darkened(0.2), 0.95), 40)


# ---------------------------------------------------------------- in his hands

func _surface(front: Texture2D) -> ShaderMaterial:
	var m: ShaderMaterial = main.pub.mat(Color(1, 1, 1), 0.3, 0.0, 5)
	if front != null:
		m.set_shader_parameter("albedo_tex", front)
		m.set_shader_parameter("emission_tex", front)
	m.set_shader_parameter("emission", Color(1, 1, 1))
	m.set_shader_parameter("emission_energy", 0.32)
	return m


# The face of a licence: the card, the laminate and its hologram (look/licence.gdshader). A real
# one's hologram is foil, and moves; holo: printed in props.yaml is ink, and sits there; none, none.
func _licence_face(id: String, pr: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://look/licence.gdshader")
	m.set_shader_parameter("face_tex", tex.get("card_%s_front" % id))
	m.set_shader_parameter("holo_tex", tex.get("card_%s_holo" % id))
	var kind := str(pr.get("holo", "foil"))
	m.set_shader_parameter("foil", 0.0 if kind == "none" else 1.0)
	m.set_shader_parameter("printed", kind == "printed")
	return m


func _quad(size: Vector2, m: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _box(size: Vector3, pos: Vector3, m: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# A line hands something over. Live, it comes into his hands (or, the kid's phone, stays in the
# kid's hand where he's holding it up); read back from a save, it's just in the story.
func offer(it: Dictionary, live: bool, now := false) -> void:
	var spec := str(it.get("prop", "")).strip_edges().split(" ", false)
	if spec.is_empty():
		return
	var id: String = spec[0]
	var state: String = spec[1] if spec.size() > 1 else ""
	var pr = P.get(id)
	if not (pr is Dictionary) or not live:
		return
	if state == "back":
		# #prop: hoodie_card back: he gives it back, now, to whoever handed it over
		_waiting = {}
		if held != null and str(held.id) == id:
			_let_go(false)
		return
	# held out from across the room: it's in his hand when he gets to it, not on the way; and held
	# out by someone still coming (out of the pickup, across the lot), when they're in front of him
	if not now and (main.view.walking or not _brought(id)):
		_waiting = {"it": it, "turn": main.game.turn, "since": t}
		return
	var kind := str(pr.get("kind", ""))
	if kind == "phone" and state != "held":
		# held up at arm's length: it's the kid's still; E or a click on it takes it
		_let_go(true)
		held = {"id": id, "kind": kind, "turn": main.game.turn, "node": null, "away": true, "pr": pr, "photo": 0}
		_hint()
		return
	_let_go(true)
	var node := Node3D.new()
	main.view.hands.add_child(node)
	held = {"id": id, "kind": kind, "turn": main.game.turn, "node": node, "away": false, "pr": pr, "flipped": false,
		"tilt": Vector2.ZERO, "tipped": 0.0, "tilt_said": false, "pose": "rest", "photo": 0, "page": 0, "stay": 0.0,
		"all": false, "seen": {}, "look_at": Vector3.INF}
	match kind:
		"card":
			var body := Node3D.new()
			node.add_child(body)
			var f := _quad(CARD, _licence_face(id, pr), body)
			f.position.z = 0.0004
			held.face = f
			var b := _quad(CARD, _surface(tex.get("card_%s_back" % id)), body)
			b.rotation.y = PI
			b.position.z = -0.0004
			held.body = body
			main.audio.sfx("card")
		"phone":
			var body2 := Node3D.new()
			node.add_child(body2)
			_box(Vector3(0.074, 0.152, 0.008), Vector3(0, 0, -0.0045), main.pub.mat(Color("141417"), 0.35, 0.2, 5), body2)
			held.screen = _quad(Vector2(0.066, 0.142), _surface(null), body2)
			held.body = body2
			_phone_photo()
			main.audio.sfx("swipe", 0.6)
		"binder":
			var body3 := Node3D.new()
			node.add_child(body3)
			_box(Vector3(0.25, 0.32, 0.012), Vector3(0, 0, -0.008), main.pub.mat(Color("1d1f24"), 0.6, 0.0, 5), body3)
			held.screen = _quad(Vector2(0.22, 0.286), _surface(null), body3)
			held.screen.position.z = 0.0005
			held.body = body3
			_binder_page()
			main.audio.sfx("page")
	var hands: Dictionary = GARY_HAND_FOR if main.game.here() == "office" else HAND_FOR
	if hands.has(kind) and held.has("body"):
		_right_hand(held.body, hands[kind][0], hands[kind][1])
	_pose(held.pose, true)
	_hint()


# His right hand on what he's holding: the model's own card or phone lines up with the one in his
# view (its anchor: the middle of it, which way it faces, which way is up), and the model's copy of
# it is hidden.
func _right_hand(body: Node3D, model: String, what: String) -> void:
	if not FileAccess.file_exists(PEOPLE + model + ".glb"):
		return
	var a: Dictionary = _anchors(model)
	if not (a.has(what) and a.has(what + "_facing") and a.has(what + "_up")):
		return
	var hand: Node3D = main.pub.model(PEOPLE + model + ".glb", Vector3.ZERO, body)
	for n in ["card", "card_body", "phone", "phone_screen"]:
		var c := hand.find_child(n, true, false)
		if c is Node3D:
			(c as Node3D).visible = false
	var z := _v3(a[what + "_facing"]).normalized()
	var x := _v3(a[what + "_up"]).cross(z).normalized()
	var y := z.cross(x)
	hand.transform = Transform3D(Basis(x, y, z), _v3(a[what])).affine_inverse()
	_no_shadows(hand)


func _anchors(model: String) -> Dictionary:
	var path := PEOPLE + model + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


static func _v3(a) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2])) if a is Array and a.size() >= 3 else Vector3.ZERO


func _no_shadows(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadows(c)


func _figure_props() -> void:
	if main.stage == null:
		return
	for id in ON_FIGURE:
		var f = main.stage.figures.get(ON_FIGURE[id][0])
		if f == null or not is_instance_valid(f.node):
			continue
		var mine: bool = holding() and str(held.id) == id
		for n in ON_FIGURE[id][1]:
			var c := (f.node as Node).find_child(n, true, false)
			if c is Node3D:
				(c as Node3D).visible = not mine


func _phone_photo() -> void:
	if held == null or not held.has("screen"):
		return
	var names := ["photo_table", "photo_pool"]
	var name: String = names[clampi(int(held.photo), 0, names.size() - 1)]
	var m: ShaderMaterial = (held.screen as MeshInstance3D).material_override
	var tx = tex.get(name)
	m.set_shader_parameter("albedo_tex", tx)
	m.set_shader_parameter("emission_tex", tx)
	m.set_shader_parameter("albedo", Color(0.2, 0.2, 0.2))
	m.set_shader_parameter("emission_energy", 1.0)


func _binder_page() -> void:
	if held == null or not held.has("screen"):
		return
	var sleeves: Dictionary = held.pr.get("sleeves", {})
	var keys := sleeves.keys()
	keys.sort_custom(func(a, b): return int(a) < int(b))
	var k := int(held.page)
	var name := ("sleeve_" + str(keys[k])) if k < keys.size() else "sleeve_empty"
	var m: ShaderMaterial = (held.screen as MeshInstance3D).material_override
	m.set_shader_parameter("albedo_tex", tex.get(name))
	m.set_shader_parameter("emission_tex", tex.get(name))


# where a thing sits in his hands, in front of his eyes (the camera's space: -z ahead, y up)
func _pose(p: String, instant := false) -> void:
	if held == null or held.node == null:
		return
	held.pose = p
	var node: Node3D = held.node
	var pos := Vector3.ZERO
	var rot := Vector3.ZERO
	match str(held.kind) + ":" + p:
		"card:rest":
			pos = Vector3(0.062, -0.07, -0.25)
			rot = Vector3(12, -8, 4)
		"card:look":
			var at := _beside_face()
			pos = at
			rot = Vector3(0, 0, 0)
		"phone:rest":
			pos = Vector3(0.05, -0.085, -0.27)
			rot = Vector3(14, -6, 2)
		"phone:look":
			pos = Vector3(0.0, -0.02, -0.2)
			rot = Vector3(4, 0, 0)
		"binder:rest":
			pos = Vector3(0.0, -0.15, -0.36)
			rot = Vector3(-38, 0, 0)
		"binder:look":
			pos = Vector3(0.0, -0.045, -0.33)
			rot = Vector3(-8, 0, 0)
		_:
			pos = Vector3(0.0, -0.4, -0.3)
			rot = Vector3(-40, 0, 0)
	var basis := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	var tr := Transform3D(basis, pos)
	if instant:
		node.transform = Transform3D(basis, pos + Vector3(0, -0.25, 0.05))
	var tw := node.create_tween()
	tw.tween_property(node, "transform", tr, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Up by the face of whoever handed it over, to one side, so the player sees the two together.
func _beside_face() -> Vector3:
	var who := str(held.pr.get("face", ""))
	var cam: Camera3D = main.view.cam
	var head: Vector3 = main.stage.head_of(who)
	if head == Vector3.INF or not main.stage.in_sight(head, main.stage.figure_zone(who)):
		return Vector3(0.0, -0.005, -0.2)
	var local := cam.global_transform.affine_inverse() * head
	var d := local.normalized()
	var p := d * 0.26
	# to the side of the face that's nearer the middle of his view
	var side := Vector3(-0.07 if local.x > 0.0 else 0.07, 0.0, 0.0)
	return p + side


func holding() -> bool:
	return held != null and held.node != null and not held.away


func _let_go(quick: bool) -> void:
	if held == null:
		return
	var node = held.node
	var id_was := str(held.id)
	held = null
	hint.visible = false
	if node == null:
		return
	if quick:
		(node as Node3D).queue_free()
		return
	# handed back: out of his eyes toward whoever it's theirs, if they're there to take it, or down
	var to := (node as Node3D).position + Vector3(0.05, -0.3, 0.1)
	var who: String = _whose(id_was)
	if who != "" and main.stage != null and main.stage.present(who):
		var chest: Vector3 = main.stage.chest_of(who)
		var cam: Camera3D = main.view.cam
		var local := cam.global_transform.affine_inverse() * chest
		if local.z < -0.2:
			to = local.normalized() * 0.55 + Vector3(0, -0.08, 0)
	var tw := (node as Node3D).create_tween()
	tw.tween_property(node, "position", to, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback((node as Node3D).queue_free)


# whose a thing is: the figure that handed it over
func _whose(id: String) -> String:
	if ON_FIGURE.has(id):
		return ON_FIGURE[id][0]
	var pr = P.get(id)
	return str(pr.get("face", "")) if pr is Dictionary else ""


func drop_all() -> void:
	_waiting = {}
	_let_go(true)


# Whether whoever holds it out is there to: in front of him, not walking up or still in the pickup.
# The stage puts people where the night has them after the lines are out, so a line that hands
# something over comes before they've set off.
func _brought(id: String) -> bool:
	var who := _whose(id)
	if who == "" or main.stage == null:
		return true
	# in Gary's office everything comes across the desk, from a man already sitting at it
	if main.game.here() == "office":
		return true
	if main.stage.walkers.has(who):
		return false
	var f = main.stage.figures.get(who)
	if f == null or str(f.spot) == "":
		return false
	return str(main.stage.SPOTS[f.spot].get("in", "")) != "truck"


# He's got where he was going, or they have (or it's waited long enough for someone who never came
# into sight): what was held out to him, if it's still his to take. Every frame while something waits.
func arrived() -> void:
	if _waiting.is_empty() or main.view.walking:
		return
	var w := _waiting
	var id := str(w.it.get("prop", "")).strip_edges().split(" ", false)[0]
	if not _brought(id) and t - float(w.get("since", t)) < WAIT_MAX:
		return
	_waiting = {}
	if int(w.turn) == main.game.turn or not main.game.toy_moves(id).is_empty():
		offer(w.it, true, true)


# Esc: down for a moment, out of his eyes. E brings it back up while it's still his to handle.
func put_down() -> void:
	if not holding():
		return
	held.away = true
	var node: Node3D = held.node
	var tw := node.create_tween()
	tw.tween_property(node, "position", Vector3(0.1, -0.42, -0.22), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_hint()


func raise() -> bool:
	if held == null or not held.away:
		return false
	if held.node == null:
		# the kid's phone, held up to him: take it
		return _play("look") != ""
	held.away = false
	_pose("rest")
	_hint()
	return true


func _live() -> bool:
	if held == null or not main.in_game or main.game.ended:
		return false
	return int(held.turn) == main.game.turn or not main.game.toy_moves(str(held.id)).is_empty()


func _waits(what: String) -> bool:
	return held != null and what in main.game.toy_moves(str(held.id))


func _play(what: String) -> String:
	if held == null or not _live():
		return ""
	return main.toy(str(held.id), what)


# after every batch: while it's live it stays; when it isn't, he hands it back
func status(_st: Dictionary) -> void:
	if held == null:
		return
	if not _live():
		_let_go(false)
		return
	_hint()


func _hint() -> void:
	if held == null:
		hint.visible = false
		return
	var whose := "her" if str(held.pr.get("sex", "")) == "F" else "his"
	var s := ""
	match str(held.kind):
		"card":
			s = "Move over it to tip it to the light   ·   Click  turn it over   ·   E  up by %s face   ·   Esc  down" % whose
		"phone":
			s = "E  take the phone" if held.node == null else "R  or drag across it: the next photo   ·   E  closer   ·   Esc  down"
		"binder":
			s = "Q  R  the sleeves   ·   E  closer   ·   Esc  down"
	if held.away and held.node != null:
		s = "E  pick it up again"
	hint.text = s
	hint.visible = main.settings.get("notice", true) or held.away


# the keys while he's holding something
func key(k: int) -> void:
	if held == null:
		return
	match k:
		KEY_E, KEY_F:
			_verb_look()
		KEY_R:
			_next(1)
		KEY_Q:
			_next(-1)


func _verb_look() -> void:
	if held.away:
		raise()
		return
	match str(held.kind):
		"card":
			if held.pose == "look":
				_pose("rest")
				return
			if held.flipped:
				_flip(false)
			_pose("look")
			main.audio.sfx("card", 0.7)
			_play("look")
		"phone", "binder":
			_pose("rest" if held.pose == "look" else "look")
			if held.kind == "phone":
				main.audio.sfx("swipe", 0.6)
				_play("look")


func _flip(say := true) -> void:
	if held == null or held.kind != "card":
		return
	held.flipped = not held.flipped
	var body: Node3D = held.body
	var tw := body.create_tween()
	tw.tween_property(body, "rotation:y", PI if held.flipped else 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	main.audio.sfx("card")
	if say:
		_play("flip")


func _next(d: int) -> void:
	match str(held.kind):
		"phone":
			if d > 0 and held.photo == 0:
				# a swipe only goes through when the story's waiting for one; otherwise the hand holding it holds on
				if _waits("swipe"):
					main.audio.sfx("swipe")
					held.photo = 1
					_phone_photo()
					_play("swipe")
				else:
					var body: Node3D = held.body
					var tw := body.create_tween()
					tw.tween_property(body, "position:x", -0.012, 0.12)
					tw.tween_property(body, "position:x", 0.0, 0.2)
			elif d < 0 and held.photo > 0:
				held.photo = 0
				_phone_photo()
				main.audio.sfx("swipe", 0.6)
		"binder":
			var n: int = held.pr.get("sleeves", {}).size()
			var p := clampi(int(held.page) + d, 0, n)
			if p == held.page:
				return
			held.page = p
			held.stay = 0.0
			_binder_page()
			main.audio.sfx("page")


# ---------------------------------------------------------------- the pointer on what he's holding

func _on_sheet_input(e: InputEvent) -> void:
	if not holding():
		return
	if e is InputEventMouseMotion and held.kind == "card":
		var c := _screen_of_held()
		if c.x < 0.0:
			return
		var off: Vector2 = (e.position + main.view.sheet.global_position - c) / 180.0
		var was: Vector2 = held.tilt
		held.tilt = Vector2(clampf(off.y * TILT, -TILT, TILT), clampf(off.x * TILT, -TILT, TILT))
		held.tipped += absf(held.tilt.x - was.x) + absf(held.tilt.y - was.y)
		if not held.tilt_said and held.tipped > TILT_SEEN:
			held.tilt_said = true
			_play("tilt")
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		if main.view.was_click() and _near_held(e.position + main.view.sheet.global_position):
			if held.kind == "card":
				_flip()
			elif held.kind == "phone":
				_verb_look()
			elif held.kind == "binder":
				var c2 := _screen_of_held()
				_next(1 if e.position.x + main.view.sheet.global_position.x > c2.x else -1)
			main.view.sheet.accept_event()
	elif e is InputEventMouseMotion and held.kind == "phone" and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) and e.relative.x < -14.0:
		if _near_held(e.position + main.view.sheet.global_position):
			_next(1)


# The lamp a licence's foil catches (look/licence.gdshader), kept where the card meets it at the
# same small tip of the wrist however he's holding it: SWEET, up and in toward the middle of his
# view. At rest the foil is half awake; the pointer over the card wakes it.
func _aim_lamp() -> void:
	if not held.has("face"):
		return
	# what he's holding sits on view.hands, which rides on the camera: its transform is already in
	# his eye's space, the space the shader's lamp is in
	var tr: Transform3D = (held.node as Node3D).transform
	var n := (tr.basis * Basis.from_euler(Vector3(deg_to_rad(SWEET.x), deg_to_rad(SWEET.y), 0.0))).z.normalized()
	var v := (-tr.origin).normalized()
	var m: ShaderMaterial = (held.face as MeshInstance3D).material_override
	m.set_shader_parameter("lamp", (n * (2.0 * n.dot(v)) - v).normalized())


func _screen_of_held() -> Vector2:
	if held == null or held.node == null:
		return Vector2(-1, -1)
	var s: Vector3 = main.view.on_screen((held.node as Node3D).global_position)
	return Vector2(s.x, s.y) if s.z > 0.0 else Vector2(-1, -1)


func _near_held(p: Vector2) -> bool:
	var c := _screen_of_held()
	if c.x < 0.0:
		return false
	var reach := 200.0 if held.kind == "binder" else 130.0
	return p.distance_to(c) < reach * (1.6 if held.pose == "look" else 1.0)


func _process(dt: float) -> void:
	t += dt
	if not _waiting.is_empty():
		arrived()
	_figs_in -= dt
	if _figs_in <= 0.0:
		_figs_in = 0.1
		_figure_props()
	if held == null or held.node == null:
		return
	# the card tipped to the light
	if held.kind == "card" and held.has("body"):
		var body: Node3D = held.body
		var base_y := PI if held.flipped else 0.0
		var want := Vector3(deg_to_rad(held.tilt.x), base_y + deg_to_rad(held.tilt.y), 0.0)
		# a hand isn't a clamp: it breathes, and with drink in him it wanders, and the foil with it
		var calm := deg_to_rad(0.35)
		if bool(main.settings.get("skin", true)):
			calm += deg_to_rad(1.2) * clampf(float(main.view.drinks) / 8.0, 0.0, 1.0)
		want += Vector3(sin(t * 1.3) * calm, sin(t * 0.9 + 1.7) * calm, 0.0)
		body.rotation.x = lerpf(body.rotation.x, want.x, 1.0 - exp(-dt * 10.0))
		if absf(wrapf(body.rotation.y - base_y, -PI, PI)) < 0.5:
			body.rotation.y = lerpf(body.rotation.y, want.y, 1.0 - exp(-dt * 10.0))
		held.tilt = held.tilt.lerp(Vector2.ZERO, 1.0 - exp(-dt * 0.8))
		_aim_lamp()
	# the binder: staying on a page is looking at it; the back of it is having been through them all
	if held.kind == "binder" and not held.away:
		held.stay += dt
		var n: int = held.pr.get("sleeves", {}).size()
		var k := int(held.page) + 1
		if held.stay >= DWELL and not held.seen.has(k) and k <= n:
			held.seen[k] = true
			_play("page" + str(k))
		if int(held.page) >= n - 1 and held.stay >= 0.7 and not held.all:
			held.all = true
			_play("all")
	# the card up by a face: keep it there as his head moves
	if held.kind == "card" and held.pose == "look":
		var want_p := _beside_face()
		var node: Node3D = held.node
		node.position = node.position.lerp(want_p, 1.0 - exp(-dt * 6.0))
