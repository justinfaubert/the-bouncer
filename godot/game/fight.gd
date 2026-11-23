# The live fight, in first person (bible/15_FIGHTS_AND_STATS.md, section 2). game/fight_sim.gd is
# the bodies; this is his eyes, his two fists at the bottom of the view, the other man's body posed
# from the sim, the player's hands on the mouse, and the feel: the held frame on a clean one, the
# head snapping the way the blow came, the room going under water when his bell's rung.
#
# The player's hands:
#   left button, a stroke    his right hand (the heavy one): press, draw toward where it should land
#                            on the man, let go. Straight is a straight; bowed to a side, a hook;
#                            drawn upward, an uppercut. Faster and longer is harder, and costs more.
#   right button, a stroke   his left (the lead: quicker, lighter)
#   press and hold still     that hand takes hold of what's under the pointer: wrist, arm, collar,
#                            the back of the neck, the belt. Drag while holding to move his weight;
#                            drag round in a circle and the turn builds until his feet can't follow.
#                            Both hands on the neck from behind is the choke. Let go to let go.
#   W A S D                  his feet: in, out, round
#   Q E                      slip his head left or right
#   Space                    cover up: forearms by the face
# No bars and no numbers: his breath is in the sound and the edges of the print, his bell in the
# blur, and the other man's state is on the other man.
class_name Fight
extends Node

const PEOPLE := "res://models/people/"
const HIT_STOP := [0.05, 0.11]          # the frame held on a clean one, light to heavy (seconds)
const STILL_GRAB := 0.22                # held still this long on him, a hand takes hold
const STILL_PX := 10.0
const EYE_DOWN := 0.1                   # his eyes under the top of his head

signal finished(result: Dictionary)
signal event(e: Dictionary)             # the card listens: every sim event, as it happens

var main
var pub: Pub
var view: View
var sim: FightSim
var active := false
var paused := false                     # frozen seconds: the sim stops, the print holds
var frame_to := Transform3D()           # the sim's floor (x, y) to the world: origin and turn
var figures: Array = []                 # the bodies drawn: [Figure], the first the other man
var extras: Array = []                  # people standing round, posed once: [Node3D]
var fist_r: Node3D
var fist_l: Node3D
var layer: CanvasLayer
var caption: Label
var marks_ui: Control                   # his strokes drawn on the screen as he makes them, and the shoulder
var hold := 0.0                         # hit stop left
var shake := Vector2.ZERO               # his head knocked: yaw, pitch (radians), springing back
var shake_v := Vector2.ZERO
var look_at_pt := Vector3.ZERO
var t := 0.0
var card: Dictionary = {}
var rehearsal := false
var practice_out: Array = []            # what crossed a mark this fight, said at the end
var body := {}                          # drinks, hurt, tension, stats from the night or the menu
var ring_rules := false
var saw_hint := false
# the strokes
var strokes := {}                       # button -> {"hand", "pts": [[pos, t]], "t0", "still_t", "grab": bool}
var stats_used := {}
var said := {}
var feet := Vector2.ZERO
var last_pull := Vector2.ZERO
var mouse_v := Vector2.ZERO
var _prev_mouse := Vector2.ZERO
var _hid: Array = []
var opp_level := 4.0                    # how good the other man is, for what beating him teaches


class Figure:
	var f: FightSim.Fighter
	var node: Node3D                    # at his feet, turned his way
	var tilt: Node3D                    # for a fall: turned about his feet
	var model: Node3D
	var sk: Skeleton3D
	var b := {}
	var L := {}
	var G := {}
	var Gi := {}
	var O := {}
	var scale := 1.0
	var head := Vector3.ZERO            # springs: head yaw, pitch, roll offsets and their speed
	var head_v := Vector3.ZERO
	var chest := Vector3.ZERO
	var chest_v := Vector3.ZERO
	var fall := 0.0                     # 0 standing .. 1 flat
	var fall_v := 0.0
	var fall_dir := Vector2(0, 1)
	var stride := 0.0
	var hand_w := {"L": Vector3.ZERO, "R": Vector3.ZERO}   # where each hand is now, in the world (smoothed)
	var posed_t := 0.0
	var up := Vector3.UP                # the model's up, forward and right, in the skeleton's frame
	var fwd := Vector3.FORWARD
	var right := Vector3.RIGHT
	var helper := false                 # a man holding someone, posed by hand not by the sim
	var hold_pt := {}                   # side -> a world point his hands go to


func setup(m) -> void:
	main = m
	pub = m.pub
	view = m.view
	layer = CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	marks_ui = Control.new()
	marks_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	marks_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks_ui.draw.connect(_draw_marks)
	layer.add_child(marks_ui)
	caption = Label.new()
	caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caption.anchor_left = 0.12
	caption.anchor_right = 0.88
	caption.anchor_top = 0.84
	caption.anchor_bottom = 0.97
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	caption.add_theme_font_override("font", Look.font("read_i"))
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	caption.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.06))
	caption.add_theme_constant_override("outline_size", 8)
	layer.add_child(caption)
	layer.visible = false
	fist_r = _fist("r")
	fist_l = _fist("l")
	set_process(false)
	set_process_input(false)


func _fist(side: String) -> Node3D:
	var n := Node3D.new()
	n.visible = false
	view.hands.add_child(n)
	var path := PEOPLE + "his_fist_%s.glb" % side
	if FileAccess.file_exists(path):
		var m: Node3D = pub.model(path, Vector3.ZERO, n)
		for mi in m.find_children("*", "GeometryInstance3D", true, false):
			(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


# ---------------------------------------------------------------- starting and ending

# A live fight. opts:
#   where: Transform3D, the sim's floor to the world (origin at the middle of the floor, its +y the
#          sim's +y as world +z turned by the basis)
#   bounds: Rect2 of the floor
#   me: Fighter (the player), him: Fighter (the other man), model: his model's file name, size
#   helpers: [{"model", "side"}] men holding him (posed on him)
#   extras: [{"model", "at": Vector3, "face": Vector3}] people standing round
#   ring: London rules
func begin(opts: Dictionary, rehearse := false, from := {}) -> void:
	active = true
	paused = false
	rehearsal = rehearse
	body = from.duplicate()
	card = opts
	ring_rules = bool(opts.get("ring", false))
	practice_out = []
	said = {}
	saw_hint = false
	frame_to = opts.get("where", Transform3D.IDENTITY)
	sim = FightSim.new(int(opts.get("seed", 1)))
	sim.bounds = opts.get("bounds", Rect2(-2.5, -2.5, 5.0, 5.0))
	sim.keep_down = ring_rules
	var me: FightSim.Fighter = opts.me
	var him: FightSim.Fighter = opts.him
	sim.setup(me, him, float(opts.get("gap", 1.5)))
	if opts.has("me_at"):
		me.pos = opts.me_at
	if opts.has("him_at"):
		him.pos = opts.him_at
	opp_level = float(opts.get("level", 4.0))
	_clear_figures()
	figures.append(_figure(str(opts.get("model", "crew_a")), him, float(opts.get("size", 1.0))))
	for h in opts.get("helpers", []):
		var hf := _figure(str(h.model), null, float(h.get("size", 1.0)))
		hf.helper = true
		hf.hold_pt = {"side": str(h.get("side", "L")), "off": h.get("off", Vector2(0.55, 0.2))}
		figures.append(hf)
	for x in opts.get("extras", []):
		var n: Node3D = pub.model(PEOPLE + str(x.model) + ".glb", x.at)
		var to: Vector3 = x.get("face", x.at + Vector3(0, 0, 1))
		n.look_at(Vector3(to.x, n.global_position.y, to.z), Vector3.UP, true)
		extras.append(n)
	view.walking = false
	view.focus_fov = 62.0
	view.drinks = int(body.get("drinks", 0))
	view.tension = int(body.get("tension", 0))
	view.hurt = int(body.get("hurt", 0))
	# whatever else is in his hands goes out of sight while they're fists
	_hid = []
	for c in view.hands.get_children():
		if c != fist_r and c != fist_l and c is Node3D and (c as Node3D).visible:
			(c as Node3D).visible = false
			_hid.append(c)
	fist_r.visible = true
	fist_l.visible = true
	layer.visible = true
	caption.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	look_at_pt = _w3(him.pos, him.height * 0.8)
	_place_eyes(0.0)
	set_process(true)
	set_process_input(true)
	main.lay_out(1.0)


# where the live part ends; the card decides what comes after
func end() -> void:
	if not active:
		return
	active = false
	paused = false
	fist_r.visible = false
	fist_l.visible = false
	for c in _hid:
		if is_instance_valid(c):
			(c as Node3D).visible = true
	_hid = []
	layer.visible = false
	strokes.clear()
	view.focus_fov = 0.0
	view.flash = 0.0
	view.heart = 0.0
	set_process(false)
	set_process_input(false)
	_clear_figures()
	main.lay_out(View.WORLD_W)


func _clear_figures() -> void:
	for fg in figures:
		if is_instance_valid(fg.node):
			fg.node.queue_free()
	figures = []
	for n in extras:
		if is_instance_valid(n):
			n.queue_free()
	extras = []


# the sim's floor point at a height, in the world
func _w3(p: Vector2, y := 0.0) -> Vector3:
	return frame_to * Vector3(p.x, y, p.y)


# a world point onto the sim's floor
func _f2(w: Vector3) -> Vector2:
	var l := frame_to.affine_inverse() * w
	return Vector2(l.x, l.z)


func _yaw_of(facing: float) -> float:
	# the sim's facing (forward (sin, cos) on its floor) to a world yaw for a model that faces -z
	var fw := frame_to.basis * Vector3(sin(facing), 0, cos(facing))
	return atan2(fw.x, fw.z) + PI


# ---------------------------------------------------------------- the bodies

func _figure(model: String, f: FightSim.Fighter, size: float) -> Figure:
	var fg := Figure.new()
	fg.f = f
	fg.scale = size
	fg.node = Node3D.new()
	pub.add_child(fg.node)
	fg.tilt = Node3D.new()
	fg.node.add_child(fg.tilt)
	fg.model = pub.model(PEOPLE + model + ".glb", Vector3.ZERO, fg.tilt)
	fg.model.scale = Vector3.ONE * size
	# only the body: what they were modelled holding (a case, a card, a pint) stays out of a fight
	var base := model.get_basename()
	for mi in fg.model.find_children("*", "MeshInstance3D", true, false):
		var nm := str(mi.name)
		if not (nm.begins_with(base + "_") or nm.ends_with("_body") or nm.ends_with("_hands") or nm.ends_with("_head")):
			(mi as MeshInstance3D).visible = false
		else:
			_strip_props(mi as MeshInstance3D)
	var sks := fg.model.find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		fg.sk = sks[0]
		for i in fg.sk.get_bone_count():
			var nm := fg.sk.get_bone_name(i)
			fg.b[nm] = i
			fg.L[nm] = fg.sk.get_bone_rest(i).basis.orthonormalized()
			var g := fg.sk.get_bone_global_rest(i)
			fg.G[nm] = g.basis.orthonormalized()
			fg.Gi[nm] = g.basis.orthonormalized().transposed()
			fg.O[nm] = g.origin
		var rel: Transform3D = fg.sk.global_transform.affine_inverse() * fg.model.global_transform
		fg.up = (rel.basis * Vector3.UP).normalized()
		fg.fwd = (rel.basis * Vector3(0, 0, -1)).normalized()
		fg.right = fg.fwd.cross(fg.up).normalized()
	# his height from the model, so the sim and the drawing agree
	if f != null:
		var js := PEOPLE + model + ".json"
		if FileAccess.file_exists(js):
			var d = JSON.parse_string(FileAccess.get_file_as_string(js))
			if d is Dictionary and d.get("head") is Array:
				f.height = (float(d.head[1]) + 0.12) * size
				f.reach = f.height * 0.4
				f.reset_guard()
	return fg


# Turn a bone by d (a turn in the skeleton's frame at rest) about its own joint (life.gd's way).
func _turn(fg: Figure, bone: String, d: Basis) -> void:
	if not fg.b.has(bone):
		return
	var local: Basis = (fg.L[bone] as Basis) * ((fg.Gi[bone] as Basis) * d * (fg.G[bone] as Basis))
	fg.sk.set_bone_pose_rotation(int(fg.b[bone]), local.get_rotation_quaternion())


# springs stepped in small pieces (semi-implicit), so a long frame can't blow them up
static func _spring3(x: Vector3, v: Vector3, w: float, dt: float) -> Array:
	var n := maxi(1, ceili(minf(dt, 0.25) / 0.008))
	var h := minf(dt, 0.25) / n
	for i in n:
		v += (-x * w * w - v * 2.0 * w * 0.45) * h
		x += v * h
	return [x, v]


# The body as the sim has it: where it stands and faces, the weight leaning, the fall, the head
# knocked about, the hands in their guard or out throwing or holding, the legs stepping.
func _pose(fg: Figure, dt: float) -> void:
	if fg.sk == null:
		return
	var f := fg.f
	if fg.helper:
		_pose_helper(fg, dt)
		return
	var me := sim.other(f)
	fg.node.global_position = _w3(f.pos)
	fg.node.rotation = Vector3(0, _yaw_of(f.facing), 0)
	# the springs
	var hs := _spring3(fg.head, fg.head_v, 11.0, dt)
	fg.head = (hs[0] as Vector3).clamp(Vector3(-0.3, -0.45, -0.3), Vector3(0.32, 0.45, 0.3))
	fg.head_v = hs[1]
	var cs := _spring3(fg.chest, fg.chest_v, 8.0, dt)
	fg.chest = (cs[0] as Vector3).clamp(Vector3(-0.35, -0.4, -0.25), Vector3(0.2, 0.4, 0.25))
	fg.chest_v = cs[1]
	# a fall: over about his feet, the way he went, gravity taking him; up again when he gets up
	if f.down:
		if fg.fall == 0.0:
			fg.fall_dir = f.bal.normalized() if f.bal.length() > 0.01 else -f.fwd()
		fg.fall_v += dt * 9.0 * (0.3 + fg.fall)
		fg.fall = minf(1.0, fg.fall + fg.fall_v * dt)
		if fg.fall >= 1.0 and fg.fall_v > 0.5:
			_landed_flat(fg)
			fg.fall_v = 0.0
	else:
		fg.fall_v = 0.0
		fg.fall = move_toward(fg.fall, 0.0, dt * 1.6)
	var lean_floor := f.bal * 1.3
	var tilt_axis := Vector3.ZERO
	var tilt_amt := 0.0
	if fg.fall > 0.0:
		var fd := frame_to.basis * Vector3(fg.fall_dir.x, 0, fg.fall_dir.y)
		tilt_axis = Vector3.UP.cross(fd).normalized()
		tilt_amt = fg.fall * PI * 0.48
	fg.tilt.global_transform = Transform3D(Basis.IDENTITY, fg.node.global_position)
	if tilt_amt > 0.0 and tilt_axis.length() > 0.5:
		fg.tilt.global_transform = Transform3D(Basis(tilt_axis, tilt_amt), fg.node.global_position)
	fg.model.global_transform = Transform3D(fg.tilt.global_transform.basis * Basis(Vector3.UP, _yaw_of(f.facing)) * Basis.from_scale(Vector3.ONE * fg.scale), fg.tilt.global_transform.origin)
	# in the skeleton's frame: his right and forward as modelled (faces -z, right +x... in rig space)
	var to_sk: Transform3D = fg.sk.global_transform.affine_inverse()
	var lean_w := frame_to.basis * Vector3(lean_floor.x, 0, lean_floor.y)
	var lean_sk := to_sk.basis * lean_w
	var fwd_sk := fg.fwd
	var right_sk := fg.right
	var up_sk := fg.up
	var lean_flat := lean_sk - up_sk * lean_sk.dot(up_sk)
	var lean_ax := up_sk.cross(lean_flat)
	var lean_a := clampf(lean_ax.length() * 1.2, 0.0, 0.5)
	var spine_d := Basis.IDENTITY
	if lean_ax.length() > 0.001:
		spine_d = Basis(lean_ax.normalized(), lean_a * 0.5)
	# the strike: the shoulder back in the tell, through in the throw
	var twist := 0.0
	var crouch := 0.12 + f.shock * 0.1
	if not f.act.is_empty() and f.act.kind == "strike":
		var ac := f.act
		var age := sim.t - float(ac.t0)
		var side := 1.0 if ac.hand == "R" else -1.0
		var pw := float(ac.power)
		if ac.phase == "tell":
			twist = -side * 0.35 * pw * clampf(age / maxf(0.01, float(ac.tell)), 0.0, 1.0)
		elif ac.phase == "go":
			twist = side * 0.3 * pw
		else:
			twist = side * 0.3 * pw * (1.0 - clampf((age - float(ac.tell) - float(ac.travel)) / maxf(0.01, float(ac.back)), 0.0, 1.0))
	var slip_roll := f.slip * 0.22
	var chest_d := Basis(up_sk, twist + fg.chest.y) * Basis(right_sk, -crouch * 0.6 + fg.chest.x) * Basis(fwd_sk, slip_roll + fg.chest.z)
	_turn(fg, "spine", spine_d)
	_turn(fg, "chest", chest_d)
	var head_d := Basis(up_sk, fg.head.y) * Basis(right_sk, fg.head.x - crouch * 0.4 + f.shock * 0.1 * sin(t * 3.1)) * Basis(fwd_sk, fg.head.z + slip_roll * 0.5)
	_turn(fg, "head", head_d)
	# the arms: to where each hand is (guard, blow, hold), in the world, then into the bones
	for side in ["L", "R"]:
		var want := _hand_target(fg, side, me)
		var cur: Vector3 = fg.hand_w[side]
		var quick := 30.0 if (not f.act.is_empty() and str(f.act.get("hand", "")) == side and str(f.act.phase) == "go") else 14.0
		cur = want if cur == Vector3.ZERO else cur.lerp(want, 1.0 - exp(-dt * quick))
		fg.hand_w[side] = cur
		_arm(fg, side, to_sk * cur, [spine_d, chest_d])
	# the legs: a step when he moves
	var spd := f.vel.length()
	fg.stride += spd * dt * 7.0
	var sw := sin(fg.stride) * clampf(spd * 0.6, 0.0, 0.45)
	_turn(fg, "thigh.L", Basis(right_sk, sw + crouch))
	_turn(fg, "thigh.R", Basis(right_sk, -sw + crouch))
	_turn(fg, "shin.L", Basis(right_sk, -(crouch * 2.0 + maxf(0.0, -sw) * 0.8)))
	_turn(fg, "shin.R", Basis(right_sk, -(crouch * 2.0 + maxf(0.0, sw) * 0.8)))


# a prop modelled into the body itself (the big man's cue): its surfaces dropped from the mesh
const PROPS := ["cue", "cardboard", "glass", "beer", "foam", "card", "phone", "vape"]


static func _strip_props(mi: MeshInstance3D) -> void:
	var m := mi.mesh as ArrayMesh
	if m == null:
		return
	var keep: Array = []
	for i in m.get_surface_count():
		var mat := m.surface_get_material(i)
		if mat == null or not PROPS.has(mat.resource_name):
			keep.append(i)
	if keep.size() == m.get_surface_count():
		return
	var out := ArrayMesh.new()
	out.blend_shape_mode = m.blend_shape_mode
	for k in m.get_blend_shape_count():
		out.add_blend_shape(m.get_blend_shape_name(k))
	for i in keep:
		out.add_surface_from_arrays(m.surface_get_primitive_type(i), m.surface_get_arrays(i), m.surface_get_blend_shape_arrays(i))
		out.surface_set_material(out.get_surface_count() - 1, m.surface_get_material(i))
	mi.mesh = out


func _landed_flat(fg: Figure) -> void:
	var at := fg.node.global_position
	main.audio.at("thud", at, 1.0, 3.0, 0.55 if fg.scale > 1.05 else 0.8)
	main.audio.at("thump", at, 0.9, 3.0, 0.5)
	if fg.scale > 1.05:
		shake_v += Vector2(0.0, 1.6)
		view.flash = maxf(view.flash, 0.25)
	event.emit({"t": sim.t, "kind": "landed", "by": fg.f.name})


# Where a hand goes now, in the world.
func _hand_target(fg: Figure, side: String, me: FightSim.Fighter) -> Vector3:
	var f := fg.f
	var g: Vector2 = f.guard[side]
	var guard_w := _w3(f.pos + f.right() * g.x * 1.25 * fg.scale + f.fwd() * 0.38 * fg.scale, g.y - 0.17 * fg.scale)
	if f.cover:
		guard_w = _w3(f.pos + f.right() * (0.07 if side == "R" else -0.07) * fg.scale + f.fwd() * 0.2 * fg.scale, f.head_y() - 0.02)
	if f.breath < 0.35:
		guard_w.y -= (0.35 - f.breath) * 0.8
	if f.down:
		return guard_w
	# the arm someone has hold of: pinned out and down where they hold it
	var pinned := false
	for g2 in me.grips.values():
		pinned = pinned or str(g2.part) == "arm_" + side
	for h in f.helpers:
		pinned = pinned or str(h.get("side", "")) == side
	if pinned:
		if true:
			return _w3(f.pos + f.right() * (0.3 if side == "R" else -0.3) * fg.scale + f.fwd() * 0.3 * fg.scale, f.height * 0.62)
	if f.grips.has(side):
		var gp: Dictionary = f.grips[side]
		var y := me.height * 0.72
		var x := 0.18 if side == "R" else -0.18
		match str(gp.part):
			"collar":
				y = me.height - 0.32
				x *= 0.4
			"neck":
				y = me.height - 0.22
				x *= 0.3
			"arm_L", "arm_R":
				y = me.height * 0.66
			"belt":
				y = me.height * 0.53
		return _w3(me.pos + me.right() * x - (me.pos - f.pos).normalized() * 0.12, y)
	if not f.act.is_empty() and str(f.act.get("hand", "")) == side:
		var ac := f.act
		var tgt: Vector2 = ac.target
		var hit := _w3(me.pos + me.right() * tgt.x - (me.pos - f.pos).normalized() * 0.08, tgt.y)
		var age := sim.t - float(ac.t0)
		var back_w := guard_w + (_w3(f.pos) - _w3(f.pos + f.fwd() * 0.25)) * float(ac.get("power", 0.5))
		if ac.blow == "hook":
			back_w += (_w3(f.pos + f.right() * (0.25 if side == "R" else -0.25)) - _w3(f.pos))
		match str(ac.phase):
			"tell":
				return guard_w.lerp(back_w, clampf(age / maxf(0.01, float(ac.tell)), 0.0, 1.0))
			"go":
				var k := clampf((age - float(ac.tell)) / maxf(0.01, float(ac.travel)), 0.0, 1.0)
				var mid := back_w.lerp(hit, k)
				if ac.blow == "hook":
					mid += (_w3(f.pos + f.right() * (0.2 if side == "R" else -0.2)) - _w3(f.pos)) * sin(k * PI)
				return mid
			_:
				var k2 := clampf((age - float(ac.tell) - float(ac.travel)) / maxf(0.01, float(ac.back)), 0.0, 1.0)
				return hit.lerp(guard_w, k2)
	return guard_w


# Two bones to a wrist point (in the skeleton's frame), allowing for what the spine and chest turns
# have done to the shoulder.
func _arm(fg: Figure, side: String, target: Vector3, parents: Array) -> void:
	var ua := "upper_arm." + side
	var fa := "forearm." + side
	var hd := "hand." + side
	if not (fg.b.has(ua) and fg.b.has(fa) and fg.b.has(hd)):
		return
	# undo the spine's and chest's turns about their joints: the target in the arm's rest frame
	var tr := Transform3D.IDENTITY
	var names := ["spine", "chest"]
	for i in parents.size():
		var o: Vector3 = fg.O.get(names[i], Vector3.ZERO)
		tr = tr * Transform3D(Basis.IDENTITY, o) * Transform3D(parents[i], Vector3.ZERO) * Transform3D(Basis.IDENTITY, -o)
	var tgt := tr.affine_inverse() * target
	var s0: Vector3 = fg.O[ua]
	var e0: Vector3 = fg.O[fa]
	var w0: Vector3 = fg.O[hd]
	var a := (e0 - s0).length()
	var bl := (w0 - e0).length()
	var to := tgt - s0
	var d := clampf(to.length(), absf(a - bl) + 0.01, a + bl - 0.003)
	var u := to.normalized()
	var out := fg.right * (1.0 if side == "R" else -1.0)
	var pole := out * 0.5 - fg.up
	pole = pole - u * pole.dot(u)
	if pole.length() < 1e-4:
		pole = -fg.fwd - u * (-fg.fwd).dot(u)
	pole = pole.normalized()
	var ca := clampf((a * a + d * d - bl * bl) / (2.0 * a * d), -1.0, 1.0)
	var e1 := s0 + (u * ca + pole * sqrt(1.0 - ca * ca)) * a
	var w1 := s0 + u * d
	var x_ua := Basis(Quaternion((e0 - s0).normalized(), (e1 - s0).normalized()))
	var x_fa := Basis(Quaternion(x_ua * (w0 - e0).normalized(), (w1 - e1).normalized())) * x_ua
	_turn(fg, ua, x_ua)
	_turn(fg, fa, x_ua.inverse() * x_fa)


# A man holding the other man's arm (the ogre's helpers): beside him, both hands on the arm.
func _pose_helper(fg: Figure, dt: float) -> void:
	var o := sim.b
	var side := str(fg.hold_pt.side)
	var off: Vector2 = fg.hold_pt.off
	var s := 1.0 if side == "R" else -1.0
	var at := o.pos + o.right() * off.x * s - o.fwd() * off.y
	var cur := _f2(fg.node.global_position) if fg.posed_t > 0.0 else at
	fg.posed_t += dt
	cur = cur.lerp(at, 1.0 - exp(-dt * 6.0))
	fg.node.global_position = _w3(cur)
	var face := (o.pos - cur).normalized()
	fg.node.rotation = Vector3(0, _yaw_of(atan2(face.x, face.y)), 0)
	fg.model.global_transform = Transform3D(fg.node.global_transform.basis * Basis.from_scale(Vector3.ONE * fg.scale), fg.node.global_position)
	var to_sk: Transform3D = fg.sk.global_transform.affine_inverse()
	var arm_pt := _w3(o.pos + o.right() * 0.3 * s * fg_b_scale() + o.fwd() * 0.25 * fg_b_scale(), o.height * 0.62)
	var lean := Basis(fg.right, -0.35)
	_turn(fg, "spine", lean)
	for sd in ["L", "R"]:
		var p := arm_pt + Vector3(0, 0.06 if sd == "L" else -0.08, 0)
		_arm(fg, sd, to_sk * p, [lean, Basis.IDENTITY])
	_turn(fg, "thigh.L", Basis(fg.right, 0.35))
	_turn(fg, "thigh.R", Basis(fg.right, -0.2))
	_turn(fg, "shin.L", Basis(fg.right, -0.5))


# ---------------------------------------------------------------- each frame

func _process(dt: float) -> void:
	if not active:
		return
	t += dt
	var mp := get_viewport().get_mouse_position()
	mouse_v = mouse_v.lerp((mp - _prev_mouse) / maxf(dt, 0.001), 1.0 - exp(-dt * 20.0))
	_prev_mouse = mp
	if not paused:
		if hold > 0.0:
			hold -= dt
		else:
			_feed_player(dt)
			var n := int(round(dt / FightSim.DT))
			n = clampi(n, 1, 6)
			for i in n:
				sim.step()
				for e in sim.take_events():
					_on_event(e)
	for fg in figures:
		_pose(fg, dt)
	_place_eyes(dt)
	_fists(dt)
	_body_in_print(dt)
	marks_ui.queue_redraw()


# his feet, his head, his hands' pulls, from the keys and the mouse
func _feed_player(dt: float) -> void:
	var a := sim.a
	a.move = feet
	a.slip_to = (-1.0 if Input.is_physical_key_pressed(KEY_Q) else 0.0) + (1.0 if Input.is_physical_key_pressed(KEY_E) else 0.0)
	a.cover = Input.is_physical_key_pressed(KEY_SPACE)
	# a still press on him becomes a hold
	for btn in strokes:
		var s: Dictionary = strokes[btn]
		if s.grab or a.grips.has(s.hand):
			continue
		var pts: Array = s.pts
		var first: Vector2 = pts[0][0]
		var now := get_viewport().get_mouse_position()
		if now.distance_to(first) < STILL_PX:
			s.still_t = float(s.still_t) + dt
			if float(s.still_t) >= STILL_GRAB and not a.busy():
				var tg = _on_him(now)
				if tg != null and sim.grab(a, s.hand, tg):
					s.grab = true
		else:
			s.still_t = 0.0
	# the pull through his grips: the mouse's motion, in the room's directions (right is right,
	# up the screen is away from him)
	if not a.grips.is_empty():
		var cam_basis := view.cam.global_transform.basis
		var r := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		var fw := Vector3(-cam_basis.z.x, 0, -cam_basis.z.z).normalized()
		var mv := mouse_v / 160.0
		var w := r * mv.x - fw * mv.y
		var p := _f2(_w3(Vector2.ZERO) + w) - _f2(_w3(Vector2.ZERO))
		if p.length() > 6.0:
			p = p.normalized() * 6.0
		last_pull = last_pull.lerp(p, 1.0 - exp(-dt * 14.0))
		a.pull = last_pull
	else:
		a.pull = Vector2.ZERO
		last_pull = Vector2.ZERO


# where the pointer is on the other man's body, in his frame (x across, his right +; y up), or null
func _on_him(screen: Vector2):
	if figures.is_empty():
		return null
	var him := sim.b
	var sh := view.sheet
	var pe := (screen - sh.global_position) / sh.size * Vector2(view.eye.size)
	var ro := view.cam.project_ray_origin(pe)
	var rd := view.cam.project_ray_normal(pe)
	var c := _w3(him.pos, him.height * 0.7)
	var n := (ro - c)
	n.y = 0.0
	n = n.normalized()
	var den := rd.dot(n)
	if absf(den) < 1e-4:
		return null
	var hit := ro + rd * ((c - ro).dot(n) / den)
	var local := _f2(hit) - him.pos
	var x := local.dot(him.right())
	if absf(x) > 0.5 or hit.y < 0.1 or hit.y > him.height + 0.25:
		return null
	return Vector2(x, hit.y)


func _place_eyes(dt: float) -> void:
	var a := sim.a
	var b := sim.b
	var up := a.height - EYE_DOWN
	if a.down:
		up = 0.5
	var eye := _w3(a.pos + a.right() * a.slip * 0.16 + a.bal * 0.6, up - (0.08 if a.cover else 0.0) - a.shock * 0.05)
	# his eyes on the other man: between the chest and the head, and on the floor when he's down
	var want := _w3(b.pos, (b.height * 0.78) if not b.down else 0.4)
	look_at_pt = want if dt == 0.0 else look_at_pt.lerp(want, 1.0 - exp(-dt * 7.0))
	var sp := _spring2(shake, shake_v, 14.0, dt)
	shake = sp[0]
	shake_v = sp[1]
	view.eye_pos = eye
	var aim := Posts.aim(eye, look_at_pt)
	view.yaw = aim.x + shake.x
	view.pitch = aim.y + shake.y
	view.want_yaw = view.yaw
	view.want_pitch = view.pitch


static func _spring2(x: Vector2, v: Vector2, w: float, dt: float) -> Array:
	var n := maxi(1, ceili(minf(dt, 0.25) / 0.008))
	var h := minf(dt, 0.25) / n
	for i in n:
		v += (-x * w * w - v * 2.0 * w * 0.4) * h
		x += v * h
	return [x.clamp(Vector2(-0.35, -0.3), Vector2(0.35, 0.3)), v]


# His fists: up in the guard, back in his tell, out to where the blow's going, on the man when he
# has hold of him, up by his face covering.
func _fists(dt: float) -> void:
	var a := sim.a
	for side in ["L", "R"]:
		var n: Node3D = fist_r if side == "R" else fist_l
		var s := 1.0 if side == "R" else -1.0
		var guard := Vector3(0.13 * s, -0.13, -0.3) if side == "R" else Vector3(-0.14, -0.1, -0.36)
		var rot := Basis.from_euler(Vector3(0.85, 0.15 * s, 0.35 * s))
		if a.cover:
			guard = Vector3(0.075 * s, -0.04, -0.17)
			rot = Basis.from_euler(Vector3(1.3, 0.35 * s, 0.9 * s))
		if a.breath < 0.35:
			guard.y -= (0.35 - a.breath) * 0.25
		var want := guard
		var want_rot := rot
		if a.grips.has(side) or (not a.act.is_empty() and str(a.act.get("hand", "")) == side):
			var tgt_w := _hand_target_me(side)
			want = view.cam.global_transform.affine_inverse() * tgt_w
			# never closer than a forearm, and the arm coming from his own shoulder, so the
			# sleeve runs away from the eye and never fills it
			if want.z > -0.34:
				want.z = -0.34
			var shoulder := Vector3(0.2 * s, -0.42, 0.05)
			var along := (want - shoulder).normalized()
			if a.grips.has(side):
				want_rot = Basis.looking_at(along, Vector3.UP) * Basis(Vector3(0, 0, 1), -1.1 * s)
			else:
				want_rot = Basis.looking_at(along, Vector3.UP) * Basis(Vector3(0, 0, 1), 0.3 * s)
		var cur := n.transform
		var k := 1.0 - exp(-dt * (40.0 if not a.act.is_empty() and str(a.act.get("phase", "")) == "go" else 16.0))
		var p := cur.origin.lerp(want, k)
		var b := cur.basis.orthonormalized().slerp(want_rot, k)
		n.transform = Transform3D(b, p)


func _hand_target_me(side: String) -> Vector3:
	var a := sim.a
	var o := sim.b
	var eye := view.cam.global_position
	if a.grips.has(side):
		var y := o.height * 0.7
		match str(a.grips[side].part):
			"collar":
				y = o.height - 0.3
			"neck":
				y = o.height - 0.2
			"belt":
				y = o.height * 0.53
			"arm_L", "arm_R":
				y = o.height * 0.64
		var x := 0.14 if side == "R" else -0.14
		if str(a.grips[side].part) in ["arm_L", "arm_R"]:
			# both hands on the one arm, out at his side: his left is on your right
			var at := 0.26 if str(a.grips[side].part) == "arm_L" else -0.26
			x = at + (0.05 if side == "R" else -0.05)
		return _w3(o.pos - o.right() * x + (a.pos - o.pos).normalized() * 0.15, y)
	var ac := a.act
	var tgt: Vector2 = ac.target
	var hit := _w3(o.pos + o.right() * tgt.x + (a.pos - o.pos).normalized() * 0.1, tgt.y)
	var age := sim.t - float(ac.t0)
	var guard := view.cam.global_transform * (Vector3(0.13, -0.13, -0.3) if side == "R" else Vector3(-0.14, -0.1, -0.36))
	var back := guard + (eye - hit).normalized() * 0.08
	match str(ac.phase):
		"tell":
			return guard.lerp(back, clampf(age / maxf(0.01, float(ac.tell)), 0.0, 1.0))
		"go":
			var k := clampf((age - float(ac.tell)) / maxf(0.01, float(ac.travel)), 0.0, 1.0)
			var reach_pt := eye + (hit - eye).limit_length(a.reach + 0.25)
			return back.lerp(reach_pt, k)
		_:
			var k2 := clampf((age - float(ac.tell) - float(ac.travel)) / maxf(0.01, float(ac.back)), 0.0, 1.0)
			var reach2 := eye + (hit - eye).limit_length(a.reach + 0.25)
			return reach2.lerp(guard, k2)


# his body in the print: out of breath the edges close, his bell rung the room goes soft and the
# heart comes up
func _body_in_print(dt: float) -> void:
	var a := sim.a
	view.heart = lerpf(view.heart, 1.2 + (1.0 - a.breath) * 1.4 + a.shock, 1.0 - exp(-dt * 2.0))
	view.flash = maxf(0.0, view.flash - dt * 2.2)
	var h := int(clampf(a.shock * 2.5 + (1.0 - a.breath) * 1.2 + float(body.get("hurt", 0)), 0.0, 3.0))
	view.hurt = h
	# breathing he can hear: ragged when it's short
	if a.breath < 0.45 and fmod(t, lerpf(0.5, 1.4, a.breath)) < dt:
		main.audio.sfx("whisper", 0.18 + (0.45 - a.breath) * 0.6, 0.6)


# ---------------------------------------------------------------- what happens

func _on_event(e: Dictionary) -> void:
	var me := sim.a.name
	match str(e.kind):
		"throw":
			main.audio.at("swipe", _w3(sim.a.pos if e.by == me else sim.b.pos, 1.4), 0.35, 2.0, 1.25 if e.hand == "L" else 0.95)
		"blow":
			_blow(e)
		"down":
			if e.by != me:
				_say_once("down_" + str(sim.t), "He goes down." if not e.get("out", false) else "He goes down and doesn't move.")
			else:
				shake_v += Vector2(0.0, -2.5)
				view.flash = 1.0
				_say_once("me_down" + str(sim.t), "The floor comes up.")
		"stumble":
			if e.by == me:
				shake_v += Vector2(randf_range(-1, 1), 0.6)
		"grab":
			if e.by == me and e.result == "held":
				main.audio.sfx("rattle", 0.4, 0.8)
			elif e.by != me and e.result == "held":
				_say_once("held_" + str(int(sim.t)), "He's got hold of you.")
		"broke_grip":
			if e.by != me:
				_say_once("tore", "He tears free.")
		"gone":
			_say_once("gone", "His hands stop pulling at your arm.")
		"surge":
			main.audio.at("groan", _w3(sim.b.pos, 1.8), 0.7, 3.0, 0.55)
		"second_wind":
			if e.by == me:
				_say_once("wind", "From somewhere, the breath comes back.")
	_practice_from(e)
	event.emit(e)


func _blow(e: Dictionary) -> void:
	var me := sim.a.name
	var on_me: bool = e.on == me
	var res := str(e.result)
	var f := float(e.get("force", 0.5))
	var at := _w3(sim.a.pos if on_me else sim.b.pos, 1.5)
	match res:
		"clean":
			hold = lerpf(HIT_STOP[0], HIT_STOP[1], clampf(f, 0.0, 1.0))
			main.audio.at("slap" if randf() < 0.5 else "slap_2", at, 0.8 + f * 0.4, 2.0, lerpf(1.1, 0.7, clampf(f, 0.0, 1.0)))
			if str(e.get("zone", "")) == "body":
				main.audio.at("thump", at, 0.7, 2.0, 0.7)
			if on_me:
				var dirx := 1.0 if str(e.hand) == "L" else -1.0
				shake_v += Vector2(dirx * f * (3.5 if e.blow == "hook" else 1.2), (1.8 if e.blow == "upper" else -0.8) * f)
				view.flash = maxf(view.flash, clampf(float(e.get("shock", 0.0)) * 2.2, 0.15, 1.0))
				if float(e.get("shock", 0.0)) > 0.25:
					main.audio.sfx("heart", 0.6, 0.8)
			else:
				_knock(figures[0], e, f)
				if f > 0.8 and str(e.zone) == "jaw":
					main.audio.sfx("groan_2", 0.6, 0.8)
		"blocked":
			hold = 0.03
			main.audio.at("thud_2", at, 0.6, 2.0, 1.2)
			if on_me:
				shake_v += Vector2(0.0, -0.4 * f)
			else:
				_knock(figures[0], e, f * 0.25)
		"slipped", "short", "miss":
			if not on_me and not saw_hint and res == "short":
				saw_hint = true
				_say_once("short", "Short. He's further than your arm.")


# a body knocked about by a blow, the way it came
func _knock(fg: Figure, e: Dictionary, f: float) -> void:
	var side := 1.0 if str(e.hand) == "R" else -1.0
	match str(e.get("zone", "head")):
		"jaw", "head":
			if e.blow == "hook":
				fg.head_v += Vector3(0.0, side * 6.0 * f, side * 3.0 * f)
			elif e.blow == "upper":
				fg.head_v += Vector3(5.5 * f, 0.0, 0.0)
			else:
				fg.head_v += Vector3(4.5 * f, side * 1.5 * f, 0.0)
			fg.chest_v += Vector3(2.0 * f, side * 1.5 * f, 0.0)
		"body":
			fg.chest_v += Vector3(-5.0 * f, side * 1.2 * f, 0.0)
			fg.head_v += Vector3(-2.5 * f, 0.0, 0.0)
		"legs":
			fg.chest_v += Vector3(0.0, 0.0, side * 3.0 * f)


func _say_once(key: String, text: String) -> void:
	if said.has(key):
		return
	said[key] = true
	say(text)


func say(text: String, secs := 3.5) -> void:
	caption.text = text
	var mine := text
	get_tree().create_timer(secs).timeout.connect(func():
		if caption.text == mine:
			caption.text = "")


# What the fight teaches (engine/practice.gd): only what's done well, and less against a man worse
# than him.
func _practice_from(e: Dictionary) -> void:
	var me := sim.a.name
	var lvl := clampf((opp_level - float(sim.a.stat("str") + sim.a.stat("dex")) * 0.5 + 3.0) / 3.0, 0.2, 1.2)
	match str(e.kind):
		"blow":
			if e.by == me and e.result == "clean":
				_learn("hands", float(e.get("force", 0.5)) * 1.2 * lvl, "%s:%s:%s" % [e.hand, e.blow, e.get("zone", "")])
			elif e.on == me and (e.result == "blocked" or e.result == "slipped"):
				_learn("read", 0.8 * lvl, "read:" + str(e.result) + ":" + str(e.blow))
			elif e.on == me and e.result == "short" and sim.a.move.length() > 0.3:
				_learn("feet", 0.8 * lvl, "feet:" + str(e.blow))
			elif e.on == me and e.result == "clean" and float(e.get("shock", 0.0)) > 0.15 and not sim.a.down:
				_learn("chin", 0.6 * lvl, "chin:" + str(int(sim.t / 10.0)))
		"down":
			if e.by != me:
				var how := "down:" + str(e.why)
				_learn("holds" if str(e.why) == "balance" else "hands", 3.0 * lvl, how)
		"gone":
			_learn("holds", 3.0 * lvl, "choke")


func _learn(kind: String, amount: float, how: String) -> void:
	var out: Array = []
	if not rehearsal and main.in_game and main.game != null:
		out = main.game.practise(kind, amount, how)
	else:
		out = main.practice_play(kind, amount, how)
	for ev in out:
		practice_out.append(ev)
		if ev.kind == "knack":
			_apply_knack(str(ev.id))


func _apply_knack(id: String) -> void:
	sim.a.knacks[id] = true


# ---------------------------------------------------------------- the player's hands

func _input(e: InputEvent) -> void:
	if not active:
		return
	if e is InputEventKey:
		var k := (e as InputEventKey).physical_keycode
		var down := (e as InputEventKey).pressed
		if k in [KEY_W, KEY_A, KEY_S, KEY_D]:
			var v := {KEY_W: Vector2(0, 1), KEY_S: Vector2(0, -1), KEY_A: Vector2(-1, 0), KEY_D: Vector2(1, 0)}[k] as Vector2
			if down and not (e as InputEventKey).echo:
				feet = Vector2(v.x if v.x != 0 else feet.x, v.y if v.y != 0 else feet.y)
			elif not down:
				feet = Vector2(0 if v.x != 0 else feet.x, 0 if v.y != 0 else feet.y)
			get_viewport().set_input_as_handled()
		elif k in [KEY_Q, KEY_E, KEY_SPACE]:
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE and down and not (e as InputEventKey).echo:
			get_viewport().set_input_as_handled()
			if bool(card.get("can_quit", true)):
				finished.emit({"result": "quit"})
		return
	if paused:
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
			return
		get_viewport().set_input_as_handled()
		var hand := "R" if mb.button_index == MOUSE_BUTTON_LEFT else "L"
		if mb.pressed:
			strokes[mb.button_index] = {"hand": hand, "pts": [[mb.position, t]], "t0": t, "still_t": 0.0, "grab": false}
		elif strokes.has(mb.button_index):
			var s: Dictionary = strokes[mb.button_index]
			strokes.erase(mb.button_index)
			if sim.a.grips.has(hand):
				sim.release(sim.a, hand)
				return
			if s.grab:
				return
			(s.pts as Array).append([mb.position, t])
			_stroke(s)
	elif e is InputEventMouseMotion:
		for btn in strokes:
			var pts: Array = strokes[btn].pts
			pts.append([(e as InputEventMouseMotion).position, t])
			if pts.size() > 120:
				pts.remove_at(1)


# A stroke made: what kind of blow, where to, how hard.
func _stroke(s: Dictionary) -> void:
	var pts: Array = s.pts
	var p0: Vector2 = pts[0][0]
	var p1: Vector2 = pts[-1][0]
	var chord := p1 - p0
	var L := chord.length()
	var vh := get_viewport().get_visible_rect().size.y
	if L < vh * 0.03:
		return
	# how far it bows off the straight line, and which way
	var bow := 0.0
	var n := chord.orthogonal().normalized()
	for pt in pts:
		var d := ((pt[0] as Vector2) - p0).dot(n)
		if absf(d) > absf(bow):
			bow = d
	var kind := "straight"
	if absf(bow) / L > 0.2:
		kind = "hook"
	elif chord.y < -0.75 * L and (p0.y - p1.y) > vh * 0.08:
		kind = "upper"
	# speed over the last tenth of a second, and the length, in screen heights
	var tend: float = pts[-1][1]
	var j := pts.size() - 1
	while j > 0 and tend - float(pts[j][1]) < 0.1:
		j -= 1
	var dt := maxf(0.016, tend - float(pts[j][1]))
	var spd := ((pts[-1][0] as Vector2) - (pts[j][0] as Vector2)).length() / dt / vh
	var power := clampf(0.2 + spd * 0.22 + L / vh * 0.5, 0.15, 1.0)
	var tgt = _on_him(p1)
	if tgt == null:
		# drawn past him: aimed where the line points, at his height
		var lean := (p1.x - p0.x) / maxf(1.0, L)
		tgt = Vector2(clampf(lean * 0.3, -0.3, 0.3), sim.b.head_y() - 0.05 if p1.y < p0.y else sim.b.height * 0.66)
	if kind == "hook":
		tgt = Vector2(clampf(tgt.x, -0.2, 0.2), tgt.y)
	sim.strike(sim.a, s.hand, kind, tgt, power)
	stats_used[kind] = int(stats_used.get(kind, 0)) + 1


# his strokes as he draws them, a pencil line; and the shoulder (the knack) on the other man
func _draw_marks() -> void:
	for btn in strokes:
		var pts: Array = strokes[btn].pts
		if pts.size() < 2:
			continue
		var line := PackedVector2Array()
		for p in pts:
			line.append(p[0])
		var c := Color(0.92, 0.88, 0.8, 0.55) if strokes[btn].hand == "R" else Color(0.8, 0.85, 0.92, 0.55)
		marks_ui.draw_polyline(line, c, 3.0, true)
	if sim == null or figures.is_empty():
		return
	var b := sim.b
	if sim.a.knacks.has("the_shoulder") and not b.act.is_empty() and b.act.kind == "strike" and b.act.phase == "tell":
		var sh := _w3(b.pos + b.right() * (0.2 if b.act.hand == "R" else -0.2), b.height - 0.3)
		var sp := view.on_screen(sh)
		if sp.z > 0.0:
			var c2 := Look.voice_color("fighter")
			marks_ui.draw_arc(Vector2(sp.x, sp.y), 26.0, -PI * 0.9, -PI * 0.1, 12, c2, 4.0, true)
	# a hold: a small ring where each of his hands has him
	for side in sim.a.grips:
		var w := _hand_target_me(side)
		var s3 := view.on_screen(w)
		if s3.z > 0.0:
			marks_ui.draw_arc(Vector2(s3.x, s3.y), 14.0, 0, TAU, 16, Color(0.95, 0.9, 0.8, 0.5), 2.0, true)


# ---------------------------------------------------------------- for the cards

func freeze(on: bool) -> void:
	paused = on
	strokes.clear()
	if on:
		feet = Vector2.ZERO


# the world point of something in the fight, for drawing choices on the frozen frame
func point_of(what: String) -> Vector3:
	match what:
		"his_head":
			return _w3(sim.b.pos, sim.b.head_y())
		"his_jaw":
			return _w3(sim.b.pos + sim.b.fwd() * 0.12, sim.b.head_y() - 0.08)
		"his_arm":
			return _w3(sim.b.pos + sim.b.right() * -0.25, sim.b.height * 0.66)
		"his_neck":
			return _w3(sim.b.pos, sim.b.height - 0.2)
		"his_chest":
			return _w3(sim.b.pos, sim.b.height * 0.7)
		"my_feet":
			return _w3(sim.a.pos + sim.a.fwd() * 0.6, 0.0)
		"my_mouth":
			return view.cam.global_position + view.cam.global_transform.basis * Vector3(0, -0.15, -0.6)
	return _w3(sim.b.pos, 1.2)


func fg_b_scale() -> float:
	return (figures[0] as Figure).scale if not figures.is_empty() else 1.0
