class_name DrawnFace
extends RefCounted
# A drawn face on a mask (tools/faces.py; PROPOSED): the picture a mask wears, laid together from
# the person's base picture and their sheet of parts whenever the face changes: what they feel,
# which mouth they're on as they talk, a blink, where they're looking. Each iris goes where they
# look, clipped to the white of its eye, so the eyes can follow someone, slide away from them, or
# come unstuck from each other when they're drunk.
#
#   var face := DrawnFace.open("res://models/masks/", "amanda")
#   material.set_shader_parameter("albedo_tex", face.tex)
#   face.wear("sly", 0, false, Vector2.ZERO)     # each held pose: on twos

var who := ""
var data: Dictionary
var tex: ImageTexture
var expression := "neutral"
var mouth := 0                    # 0 the expression's own mouth; 1 to 3 the mouths for talking
var blink := false
var look := Vector2.ZERO          # added to the expression's own gaze: -1..1 across (their left) and up
var _base: Image
var _sheet: Image
var _img: Image
var _key := ""


static func open(dir: String, name: String) -> DrawnFace:
	var f := DrawnFace.new()
	f.who = name
	f.data = JSON.parse_string(FileAccess.get_file_as_string(dir + name + "_face.json"))
	f._base = _png(dir + name + "_face.png")
	f._sheet = _png(dir + name + "_parts.png")
	f._img = Image.create_empty(f._base.get_width(), f._base.get_height(), false, Image.FORMAT_RGBA8)
	f._compose()
	return f


static func _png(path: String) -> Image:
	# read as bytes, like pub.gd's pictures: the same in the editor and the game
	var img := Image.new()
	img.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	img.convert(Image.FORMAT_RGBA8)
	return img


func has(expr: String) -> bool:
	return data.expressions.has(expr)


# The face for this held pose. Lays it together again only if something shows differently.
func wear(expr: String, talk_mouth := 0, shut := false, gaze := Vector2.ZERO) -> void:
	expression = expr if has(expr) else "neutral"
	mouth = clampi(talk_mouth, 0, 3)
	blink = shut
	look = gaze
	var key := "%s|%d|%s|%.2f|%.2f" % [expression, mouth, blink, snappedf(look.x, 0.05), snappedf(look.y, 0.05)]
	if key != _key:
		_key = key
		_compose()


# How the head squashes or stretches with this expression: (wide, tall).
func head() -> Vector2:
	var h: Array = data.expressions[expression].head
	return Vector2(h[0], h[1])


func _put(name) -> void:
	if name == null:
		return
	var c: Array = data.parts[name]
	_img.blend_rect(_sheet, Rect2i(c[0], c[1], c[2], c[3]), Vector2i(c[4], c[5]))


func _compose() -> void:
	_img.copy_from(_base)
	var rec: Dictionary = data.expressions[expression]
	for mk in rec.marks:
		_put(mk)
	if not blink:
		for i in 2:
			var wn = rec.white[i]
			if wn == null:
				continue
			var c: Array = data.parts[wn]
			var white := _sheet.get_region(Rect2i(c[0], c[1], c[2], c[3]))
			var g: Array = rec.gaze[i]
			var eye: Dictionary = data.eyes["l" if i == 0 else "r"]
			var ir: Array = data.parts[data.irises[rec.pupil]]
			var gx := clampf(g[0] + look.x, -1.25, 1.25)
			var gy := clampf(g[1] + look.y, -1.25, 1.25)
			var cx: float = eye.c[0] + gx * eye.range[0]
			var cy: float = eye.c[1] - gy * eye.range[1]
			var at := Vector2i(roundi(cx - (data.iris_centre[0] - ir[4]) - c[4]), roundi(cy - (data.iris_centre[1] - ir[5]) - c[5]))
			var iris := Image.create_empty(c[2], c[3], false, Image.FORMAT_RGBA8)
			iris.blend_rect(_sheet, Rect2i(ir[0], ir[1], ir[2], ir[3]), at)
			white.blend_rect_mask(iris, white.duplicate(), Rect2i(0, 0, c[2], c[3]), Vector2i.ZERO)
			_img.blend_rect(white, Rect2i(0, 0, c[2], c[3]), Vector2i(c[4], c[5]))
	for ln in (data.blink if blink else rec.lid):
		_put(ln)
	for bn in rec.brow:
		_put(bn)
	_put(rec.mouth[mouth])
	_img.generate_mipmaps()
	if tex == null:
		tex = ImageTexture.create_from_image(_img)
	else:
		tex.update(_img)
