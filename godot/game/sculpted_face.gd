class_name SculptedFace
extends DrawnFace
# A sculpted face (round five, PROPOSED; tools/sculpt.py): a real head whose face moves. Where a
# drawn face swaps pictures, this one mixes the shapes the sculpt was made with: the lids down over
# the eyeballs, the brows up, in or down, the cheeks lifting the corners of the mouth, the jaw
# dropping. The eyes are balls on bones of their own, turned to where they look. The skin's
# picture (makeup, brows, a beauty mark) doesn't change; the face under it does.
#
#   var face := SculptedFace.open("res://models/masks/", "amanda")
#   face.fit(mesh_instance, skeleton)
#   face.wear("knowing", 0, false, Vector2.ZERO)     # the same as DrawnFace

# Each expression as a mix of shapes, 0..1. A name without _l or _r is both sides. gaze: where the
# eyes rest (-1..1, across to their left, and up), added to where they're told to look.
const LOOKS := {
	"neutral": {"blink": 0.1},
	"smile": {"smile": 0.7, "squint": 0.35, "blink": 0.1},
	"laugh": {"smile": 1.0, "jaw": 0.45, "squint": 0.65, "brow_up": 0.3, "blink": 0.2},
	"sad": {"brow_in": 0.9, "frown": 0.5, "blink": 0.3, "gaze": Vector2(0.0, -0.4)},
	"angry": {"brow_down": 1.0, "squint": 0.45, "press": 0.6, "frown": 0.3},
	"shout": {"brow_down": 0.8, "jaw": 0.85, "sneer": 0.4, "squint": 0.3},
	"surprised": {"brow_up": 1.0, "jaw": 0.4},
	"afraid": {"brow_in": 0.8, "brow_up": 0.5, "jaw": 0.2, "frown": 0.35},
	"suspicious": {"squint": 0.7, "brow_down_l": 0.6, "brow_up_r": 0.3, "press": 0.3, "gaze": Vector2(0.5, 0.0)},
	"disgust": {"sneer_l": 0.9, "brow_down": 0.5, "squint": 0.4, "frown": 0.3},
	"sly": {"smile_l": 0.6, "blink": 0.35, "brow_up_l": 0.3, "gaze": Vector2(0.5, 0.0)},
	"tired": {"blink": 0.55, "brow_in": 0.2, "frown": 0.1},
	"knowing": {"blink": 0.24, "smile_l": 0.35, "brow_down_r": 0.2, "brow_up_l": 0.25, "gaze": Vector2(0.35, -0.05)},
	"far": {"blink": 0.25, "jaw": 0.05, "gaze": Vector2(0.25, 0.2)},
	"wink": {"blink_r": 1.0, "smile_r": 0.4, "smile_l": 0.3, "squint_r": 0.5},
	"tease": {"smile_l": 0.5, "smile_r": 0.2, "pucker": 0.25, "brow_up_l": 0.5, "blink": 0.2, "gaze": Vector2(-0.2, 0.0)},
	"eyeroll": {"blink": 0.2, "brow_up": 0.3, "press": 0.3, "gaze": Vector2(0.2, 1.0)},
}
# the mouths for talking, over the expression's own: a little open, wide, round
const TALKING := [{}, {"jaw": 0.22}, {"jaw": 0.5}, {"jaw": 0.3, "pucker": 0.8}]
const SIDED := ["blink", "squint", "brow_up", "brow_in", "brow_down", "smile", "frown", "sneer"]
const TURN := Vector2(26.0, 18.0)          # how far the eyes turn at a gaze of 1, degrees across and up

var mesh: MeshInstance3D
var skeleton: Skeleton3D
var _eyes := []                            # [bone, its rest rotation, its rest basis in the skeleton]


static func open(dir: String, name: String) -> DrawnFace:
	var f := SculptedFace.new()
	f.who = name
	f.data = {"expressions": LOOKS}
	var img := _png(dir + name + "_skin.png")
	img.generate_mipmaps()
	f.tex = ImageTexture.create_from_image(img)
	return f


static func is_sculpted(dir: String, name: String) -> bool:
	return FileAccess.file_exists(dir + name + "_skin.png")


func fit(mi: MeshInstance3D, sk: Skeleton3D) -> void:
	mesh = mi
	skeleton = sk
	_eyes.clear()
	for bn in ["eye_l", "eye_r"]:
		var b := sk.find_bone(bn)
		if b >= 0:
			_eyes.append([b, sk.get_bone_rest(b).basis.get_rotation_quaternion(), sk.get_bone_global_rest(b).basis.orthonormalized()])
	_apply()


func has(expr: String) -> bool:
	return LOOKS.has(expr)


func wear(expr: String, talk_mouth := 0, shut := false, gaze := Vector2.ZERO) -> void:
	expression = expr if has(expr) else "neutral"
	mouth = clampi(talk_mouth, 0, 3)
	blink = shut
	look = gaze
	_apply()


func head() -> Vector2:
	return Vector2.ONE


func _apply() -> void:
	if mesh == null:
		return
	var w := {}
	var rec: Dictionary = LOOKS[expression]
	for src in [rec, TALKING[mouth]]:
		for k in src:
			if k == "gaze":
				continue
			var names: Array = [k + "_l", k + "_r"] if k in SIDED else [k]
			for n in names:
				w[n] = maxf(float(w.get(n, 0.0)), float(src[k]))
	if blink:
		w["blink_l"] = 1.0
		w["blink_r"] = 1.0
	for i in mesh.get_blend_shape_count():
		var n := String(mesh.mesh.get("blend_shape/names")[i]) if false else _shape_name(i)
		mesh.set_blend_shape_value(i, clampf(float(w.get(n, 0.0)), 0.0, 1.0))
	# the eyes: where the expression rests them, and where they're told to look
	var g: Vector2 = rec.get("gaze", Vector2.ZERO) + look
	g = g.clamp(Vector2(-1.25, -1.25), Vector2(1.25, 1.25))
	var r := Basis(Vector3.UP, deg_to_rad(g.x * TURN.x)) * Basis(Vector3.RIGHT, deg_to_rad(-g.y * TURN.y))
	for e in _eyes:
		var rb: Basis = e[2]
		var q := Quaternion((rb.inverse() * r * rb).orthonormalized())
		skeleton.set_bone_pose_rotation(e[0], (e[1] as Quaternion) * q)


var _names := []


func _shape_name(i: int) -> String:
	if _names.is_empty():
		var am := mesh.mesh as ArrayMesh
		for k in mesh.get_blend_shape_count():
			_names.append(String(am.get_blend_shape_name(k)) if am else "")
	return _names[i]
