# The trailer's camera (trailer/trailer.gd): it runs after everything else in a frame, his eyes
# included (game/view.gd), and puts the camera where the shot wants it. The press is pinned to it the
# way the eyes pin it, so the grain and the paper stay put on the world as it moves.
#
# A shot's camera is a Callable taking the shot's own seconds and giving back
#   {"at": Vector3, "look": Vector3, "fov": degrees, "roll": radians (optional)}
# or an empty Callable, and the game's own camera stands (the darts, the pool, his walk).
extends Node

var view: View
var cam := Callable()
var s := 0.0
var last := {}
var clean := false      # a camera shot: no hover labels or hints over the picture


func _ready() -> void:
	process_priority = 100000
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_dt: float) -> void:
	var m = get_tree().root.get_node_or_null("Main")
	if clean and m != null:
		view.pointer = Vector2(-1, -1)
		for n in ["spots", "props", "feet"]:
			var o = m.get(n)
			if o == null:
				continue
			for k in ["overlay", "hint", "caption"]:
				var ci = o.get(k)
				if ci is CanvasItem:
					(ci as CanvasItem).visible = false
	elif m != null and m.get("spots") != null and m.spots.overlay is CanvasItem:
		m.spots.overlay.visible = true
	if not cam.is_valid() or view == null:
		return
	var c: Dictionary = cam.call(s)
	if c.is_empty():
		return
	last = c
	var at: Vector3 = c.at
	var look: Vector3 = c.look
	var up := Vector3.UP
	var fwd := (look - at).normalized()
	if absf(fwd.dot(up)) > 0.995:
		up = Vector3(0, 0, -1)
	var b := Basis.looking_at(fwd, up)
	var roll := float(c.get("roll", 0.0))
	if roll != 0.0:
		b = b.rotated(fwd, roll)
	view.eye_pos = at
	view.cam.global_transform = Transform3D(b, at)
	view.cam.fov = float(c.get("fov", 60.0))
	view.mcam.global_transform = view.cam.global_transform
	view.mcam.fov = view.cam.fov
	view._pin_press()
