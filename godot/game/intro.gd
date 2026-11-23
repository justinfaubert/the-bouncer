# The cold open: what plays before the title, the first time the game starts and whenever it's asked
# for again (the title's "The cold open"). Hutch's brief: a proper intro, stylish and provocative,
# that guides the player into the dream, where before the game opened on the kid at the door.
#
# It's Serling's frame and the X-Files' cold open (bible/13_STYLE.md): one image, the teller in a
# few plain lines, then out. Everything in it is the game's own world printed by the game's own
# press, so it's the same print the night is, and nothing is a picture made for the occasion.
#
#   1. black, and a bell for last call; the teller, years later, to someone who doesn't drink
#   2. the dream: the seawall at night, the strait, and the Listener coming up out of the water
#      (world/listener_rig.gd). It hears the jukebox across the highway, the tiles pack in, and we
#      go into it until the room at its heart is all there is
#   3. through it into the Sov's room, the jukebox loud
#   4. the country ending, a plate at a time: the news at table 28, the wall by the payphone, the
#      card machine, the mill's argument on the hall wall, the sign losing letters, the rats
#   5. black, the teller's last line; the Sov from the seawall; LAST CALL stamped, and the title
#
# Every cut is a print coming in (View.print_in): the colours first and the key block last. Hold any
# key or the mouse to skip; Esc skips at once.
class_name Intro
extends Control

signal finished

const SKIP_HOLD := 0.7
const LETTERBOX := 0.105         # each bar, as a share of the screen's height
const NIGHT_CLOCK := 1180        # twenty to eight: the Sov lit, the lot's lamp on

# The teller's words. Plain, said once, to someone at a bar who doesn't drink (bible/05_LOG.md:
# the listener turns out to be a machine; the teller's "he" may turn to "I"). Each line ends on the
# last concrete thing (bible/13_STYLE.md, What reads like a machine).
const OPEN := [
	"You're not drinking. I'll talk, then.",
	"He worked the door at the Sovereign for a month.",
	"On the last night he wasn't even there, and it's the only one anybody asks me about.",
]
const DREAM := "I still have the dream. It comes up out of the strait, about as high as a house, and it listens."
const LAST := "Last call's at half past one. There's time."

# the writing on the walls (content/ink/hall.ink, the men's): each line its own hand
const WALL_PM := ["PUSH BUTTON FOR A MESSAGE", "FROM THE PRIME MINISTER"]
const WALL_MILL := [["THE MILL ISN'T CLOSING.", "hand", Color("101114")], ["READ THE NOTICE.", "hand_l", Color("1d2a52")],
	["CAN'T READ. WORK AT THE MILL.", "hand", Color("c0141c")]]

# the plates: where his eyes are, what they're on, how wide, the clock, the place they're printed
# from (for its light and its sounds), and what's said or written
const PLATES := [
	{"at": Vector3(12.6, 1.6, 5.9), "look": Vector3(15.9, 2.3, 4.0), "zoom": 0.5, "place": "floor",
		"say": "Table 28 watched the country come apart on the TV over the bar, and had money on it."},
	{"at": Vector3(13.5, 1.55, -1.35), "look": Vector3(13.6, 1.5, -2.55), "zoom": 0.74, "place": "hall", "wall": "pm",
		"spot": Vector3(13.47, 1.8, -2.55)},
	{"at": Vector3(2.75, 1.42, 7.45), "look": Vector3(2.08, 1.16, 7.05), "zoom": 0.36, "place": "bar", "machine": true,
		"say": "The card machines went down two nights a week. The bank said it was the weather."},
	{"at": Vector3(14.2, 1.8, -1.7), "look": Vector3(14.25, 1.85, -2.55), "zoom": 0.62, "place": "hall", "wall": "mill", "secs": 4.6,
		"spot": Vector3(14.42, 2.0, -2.55)},
	{"at": Vector3(8.6, 1.5, 21.5), "look": Vector3(8.0, 10.6, 10.6), "zoom": 0.55, "place": "lot",
		"say": "Every big night that month, the sign on the roof lost a letter."},
	{"at": Vector3(2.2, -1.25, 0.9), "look": Vector3(2.9, -2.2, -2.4), "zoom": 0.8, "place": "keg", "torch": true,
		"say": "The rats heard it before any of us did."},
]
const PLATE_SECS := 3.4

# the dream, off the seawall: where it comes up, how big, and his eyes on the water
const SPHERE_AT := Vector3(8.0, 3.5, 53.0)
const SPHERE_R := 4.2
const SEAWALL_EYE := Vector3(8.0, 1.37, 35.75)
# the title: the Sov from the seawall, its sign, the lot's lamp, framed to the right of the menu
const TITLE_LOOK := Vector3(1.2, 4.6, 10.3)

var main
var view: View
var playing := false
var t := 0.0
var manual := false              # the tests step it themselves (tests/shots_intro.gd)
var _cues: Array = []            # [time, Callable], in order
var _next := 0
var _shot := Callable()          # what the camera does this shot: f(shot seconds)
var _shot_t0 := 0.0
var _rig: ListenerRig
var _held := 0.0
var _skipping := false

var black: ColorRect
var bars: Array = []
var cards: VBoxContainer
var lower: Label
var skip_ring: Label
var _far: AudioStreamPlayer      # the jukebox, from across the highway
var _far_bus := -1
var _labels: Array = []          # Label3Ds put in the world for a plate, freed after it
var _machine: Node3D


func setup(m) -> void:
	main = m
	view = m.view
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_priority = -10       # before the eyes (View) take the camera where it's put
	visible = false
	# the letterbox, only over the picture's shots
	for i in 2:
		var b := ColorRect.new()
		b.color = Color("07080b")
		b.anchor_right = 1.0
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i == 0:
			b.anchor_bottom = 0.0
		else:
			b.anchor_top = 1.0
			b.anchor_bottom = 1.0
		add_child(b)
		bars.append(b)
	black = ColorRect.new()
	black.color = Color("07080b")
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	cards = VBoxContainer.new()
	cards.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 26)
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards)
	lower = UiBits.label("", "read", 30, Look.INK, 0)
	lower.anchor_left = 0.14
	lower.anchor_right = 0.86
	lower.anchor_top = 1.0 - LETTERBOX - 0.16
	lower.anchor_bottom = 1.0 - LETTERBOX - 0.03
	lower.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lower.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lower.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lower.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.85))
	lower.add_theme_constant_override("shadow_offset_x", 0)
	lower.add_theme_constant_override("shadow_offset_y", 2)
	lower.add_theme_constant_override("shadow_outline_size", 14)
	lower.modulate.a = 0.0
	add_child(lower)
	skip_ring = UiBits.label("HOLD TO SKIP", "ui_b", 14, Look.MUTED, 3)
	skip_ring.anchor_left = 1.0
	skip_ring.anchor_right = 1.0
	skip_ring.anchor_top = 1.0
	skip_ring.anchor_bottom = 1.0
	skip_ring.offset_left = -220
	skip_ring.offset_right = -36
	skip_ring.offset_top = -44
	skip_ring.offset_bottom = -20
	skip_ring.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_ring.modulate.a = 0.0
	add_child(skip_ring)
	_bars(0.0)


# ---------------------------------------------------------------- the reel

func _begin() -> void:
	playing = true
	visible = true
	t = 0.0
	_next = 0
	_held = 0.0
	_skipping = false
	main.full_frame = true
	main.menus.hide_all()
	view.world_w = 1.0
	main.lay_out(1.0)
	view.daylight(NIGHT_CLOCK, true)
	black.modulate.a = 1.0
	_clear_cards()
	lower.modulate.a = 0.0
	_bars(0.0)
	_cues = []


# Just the title's own shot: the Sov from the seawall printed in, and the stamp.
func title_only() -> void:
	_begin()
	_skipping = true
	_at(0.0, _title_shot)
	_at(2.1, _end)


# Put away without finishing: a night's been started from under it.
func stop() -> void:
	playing = false
	_shot = Callable()
	_free_rig()
	_free_labels()
	if _far != null:
		_far.stop()
	visible = false


func play() -> void:
	_begin()
	var c := 0.0
	# 1. black; the bell; the teller
	_at(1.0, func(): main.audio.sfx("bell", 0.9))
	_at(2.6, func(): _card(OPEN[0]))
	_at(6.4, func(): _card(OPEN[1]))
	_at(10.0, func(): _card(OPEN[2]))
	_at(14.6, func(): _cards_out(0.9))
	# 2. the dream
	_at(15.6, _dream)
	_at(28.0, func(): _say(DREAM, 6.2))
	_at(29.5, _hears)
	_at(31.5, _push)
	# 3. into it, and out into the Sov's room
	_at(40.4, func(): view.blank_out(0.3))
	_at(40.75, _room)
	# 4. the plates
	c = 45.4
	for p in PLATES:
		var plate: Dictionary = p
		_at(c - 0.22, func(): view.blank_out(0.2))
		_at(c, func(): _plate(plate))
		c += float(plate.get("secs", PLATE_SECS))
	# 5. black, the last line, the title
	_at(c - 0.3, func(): view.blank_out(0.3); _bars_to(0.0, 0.5))
	_at(c, func(): _go_black(0.35); _card(LAST))
	_at(c + 3.9, func(): _cards_out(0.6))
	_at(c + 4.6, _title_shot)
	_at(c + 7.4, _end)


func _at(when: float, fn: Callable) -> void:
	_cues.append([when, fn])


func skip() -> void:
	if not playing or _skipping:
		return
	_skipping = true
	_clear_cards()
	lower.modulate.a = 0.0
	# straight to the Sov from the seawall and the stamp
	_cues = []
	_next = 0
	t = 0.0
	_at(0.0, func(): view.blank_out(0.15))
	_at(0.2, _title_shot)
	_at(2.3, _end)


func _process(dt: float) -> void:
	if not playing or manual:
		return
	advance(dt)


func advance(dt: float) -> void:
	t += dt
	while _next < _cues.size() and t >= float(_cues[_next][0]):
		var fn: Callable = _cues[_next][1]
		_next += 1
		fn.call()
	if _shot.is_valid():
		_shot.call(t - _shot_t0)
	if _rig != null:
		_rig.step(dt)
	# hold to skip
	var down := Input.is_anything_pressed()
	_held = _held + dt if down else 0.0
	skip_ring.modulate.a = move_toward(skip_ring.modulate.a, 0.85 if down and not _skipping else 0.0, dt * 3.0)
	if _held >= SKIP_HOLD:
		skip()


func _gui_input(e: InputEvent) -> void:
	accept_event()


func _input(e: InputEvent) -> void:
	if not playing:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
		skip()
	if e is InputEventKey or e is InputEventMouseButton or e is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


func _end() -> void:
	playing = false
	_shot = Callable()
	_free_rig()
	_free_labels()
	visible = false
	finished.emit()


# ---------------------------------------------------------------- the shots

# his eyes put exactly where the shot wants them, and held there (View eases only toward want_*)
func _eyes(at: Vector3, look: Vector3, zoom := 1.0) -> void:
	view.eye_pos = at
	var a := Posts.aim(at, look)
	view.yaw = a.x
	view.want_yaw = a.x
	view.pitch = a.y
	view.want_pitch = a.y
	view.zoom = zoom
	view.want_zoom = zoom
	view.cam.fov = float(main.settings.get("fov", 70.0)) * zoom


func _go(place: String) -> void:
	view.frame = ""
	view.jump_to(place)
	main.audio.place(place, NIGHT_CLOCK)


func _dream() -> void:
	_go("seawall")
	if _rig == null:
		_rig = ListenerRig.new()
		main.pub.add_child(_rig)
		_rig.build(view.eye.find_world_3d(), view.env, view.cam, view.mcam)
	_rig.put(Vector3(SPHERE_AT.x, ListenerRig.WATER_Y - SPHERE_R - 0.3, SPHERE_AT.z), SPHERE_R)
	_go_black(2.2, true)
	_bars_to(LETTERBOX, 1.6)
	_shot_t0 = t
	# the water at first, with nothing on it; it comes up three seconds in, over eight, slowing,
	# the last of it hanging; the rings start where it breaks the surface and die away
	_shot = func(s: float):
		var look := Vector3(SPHERE_AT.x - 0.4, 1.6 + 0.25 * smoothstep(3.0, 11.0, s), SPHERE_AT.z)
		_eyes(SEAWALL_EYE, look, lerpf(0.86, 0.8, smoothstep(0.0, 12.0, s)))
		var k := clampf((s - 3.0) / 8.0, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		var y := lerpf(ListenerRig.WATER_Y - SPHERE_R - 0.3, SPHERE_AT.y, e)
		_rig.put(Vector3(SPHERE_AT.x, y, SPHERE_AT.z), SPHERE_R)
		var broke := maxf(s - 3.6, 0.0)
		_rig.rings(broke, clampf((y + SPHERE_R - ListenerRig.WATER_Y) * 2.0, 0.0, 1.0) * (1.0 - smoothstep(8.0, 12.0, broke) * 0.6))


# The jukebox across the highway, as it carries over the water: it hears it, and the tiles come up.
func _hears() -> void:
	_far_player()
	var tw := create_tween().set_parallel()
	tw.tween_method(func(v: float): _far.volume_db = linear_to_db(maxf(v, 0.0001)), 0.0001, _vol() * 0.5, 3.0)
	tw.tween_method(func(v: float): if _rig != null: _rig.hear = v, 0.0, 1.0, 3.5)


# Into it: his eyes narrow on it as the room at its heart grows to fill the ball, and the jukebox
# comes clearer the further in he goes.
func _push() -> void:
	var s0 := t
	var from := SEAWALL_EYE
	_shot_t0 = s0
	_shot = func(s: float):
		var k := smoothstep(0.0, 8.8, s)
		var kk := k * k * (3.0 - 2.0 * k)
		_eyes(from, SPHERE_AT + Vector3(0, -0.15 * kk, 0), lerpf(0.8, 0.2, kk))
		if _rig != null:
			_rig.grow(lerpf(0.14, 1.0, smoothstep(0.1, 0.85, k)))
			# the tiles go back to ghosts as the room comes up through them
			_rig.hear = lerpf(1.0, 0.1, smoothstep(0.2, 0.75, k))
		if _far != null:
			_far.volume_db = linear_to_db(_vol() * lerpf(0.5, 0.95, k))
			if _far_bus >= 0:
				var lp := AudioServer.get_bus_effect(_far_bus, 0) as AudioEffectLowPassFilter
				if lp != null:
					lp.cutoff_hz = lerpf(700.0, 6000.0, k * k)


# The room it was holding: the Sov from its front corner, where the sphere held it from, wide, and
# easing down and in; the jukebox in the room now.
func _room() -> void:
	_free_rig()
	_go("floor")
	main.audio.ambience("room_quiet")
	if _far != null:
		var tw := create_tween()
		tw.tween_property(_far, "volume_db", -40.0, 1.6)
	view.print_in(0.9)
	_shot_t0 = t
	var at: Vector3 = ListenerRig.INSIDE_AT[0]
	var to: Vector3 = ListenerRig.INSIDE_AT[1]
	_shot = func(s: float):
		var k := smoothstep(0.0, 4.6, s)
		_eyes(at + Vector3(-0.5, -0.5, -0.3) * k, to + Vector3(0, 0.3 * (1.0 - k), 0), lerpf(1.32, 1.12, k))


func _plate(p: Dictionary) -> void:
	_free_labels()
	_go(str(p.place))
	_lower_out(0.15)
	view.print_in(0.62)
	main.audio.sfx("stamp", 0.35, 0.8 + randf() * 0.15)
	if p.has("wall"):
		_wall(str(p.wall), p)
	if p.get("machine", false):
		_card_machine()
	if p.get("torch", false):
		_torch(p)
	if p.has("say"):
		var said: String = p.say
		get_tree().create_timer(0.55).timeout.connect(func(): if playing: _say(said, float(p.get("secs", PLATE_SECS)) - 0.9))
	_shot_t0 = t
	var at: Vector3 = p.at
	var look: Vector3 = p.look
	var z: float = p.zoom
	var secs: float = p.get("secs", PLATE_SECS)
	_shot = func(s: float):
		# a slow push, the way a camera on a dolly leans in on a still
		var k := s / secs
		_eyes(at + (look - at).normalized() * 0.18 * k, look, z * lerpf(1.0, 0.93, k))


# The writing on the wall, put up a letter at a time in each hand as the plate comes in. It's in the
# world, so the press prints it with the wall.
func _wall(which: String, p: Dictionary) -> void:
	var look: Vector3 = p.get("spot", p.look)
	var at: Vector3 = p.at
	var face := (at - (p.look as Vector3))
	face.y = 0.0
	face = face.normalized()
	var lines: Array = []
	if which == "pm":
		for i in WALL_PM.size():
			lines.append([WALL_PM[i], "hand", Color("c0141c"), Vector3(0.0, 0.03 - i * 0.05, 0.0), 0.35 + i * 0.95])
	else:
		for i in WALL_MILL.size():
			var w: Array = WALL_MILL[i]
			lines.append([w[0], w[1], w[2], Vector3(-0.03 + i * 0.025, 0.0 - i * 0.075, 0.0), 0.35 + i * 1.25])
	for ln in lines:
		var l := Label3D.new()
		l.font = Look.font(str(ln[1]))
		l.font_size = 64
		l.pixel_size = 0.00062
		l.modulate = ln[2]
		l.outline_size = 0
		l.shaded = false
		l.no_depth_test = true     # the wall's plaster isn't flat to the millimetre; marker sits on top of it
		l.double_sided = false
		l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.text = ""
		main.pub.add_child(l)
		l.global_position = Vector3(look.x, look.y, Pub.BACK) + face * 0.012 + ln[3]
		l.look_at(l.global_position - face, Vector3.UP)
		l.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(randf_range(-3.0, 2.0)))
		_labels.append(l)
		var full: String = ln[0]
		var tw := create_tween()
		tw.tween_interval(float(ln[4]))
		tw.tween_callback(func(): main.audio.sfx("pen", 0.5))
		tw.tween_method(func(n: float): if is_instance_valid(l): l.text = full.substr(0, int(n)), 0.0, float(full.length()), full.length() * 0.045)


# His torch in the dark, the beam going where he looks (the X-Files' flashlight crossing a room,
# bible/13_STYLE.md): the keg room has no light of its own till someone brings one.
func _torch(p: Dictionary) -> void:
	var l := SpotLight3D.new()
	l.light_color = Color("fff1d6")
	l.light_energy = 6.0
	l.spot_range = 9.0
	l.spot_angle = 17.0
	l.spot_attenuation = 0.8
	l.shadow_enabled = true
	main.pub.add_child(l)
	l.global_position = (p.at as Vector3) + Vector3(0.18, -0.25, 0.0)
	l.look_at(p.look, Vector3.UP)
	_labels.append(l)


# A card machine on the bar by the till, its screen saying what it said two nights a week.
func _card_machine() -> void:
	_machine = Node3D.new()
	main.pub.add_child(_machine)
	_machine.global_position = Vector3(2.08, 1.13, 7.05)
	# its screen turned to whoever's paying: him, in the plate
	_machine.look_at(Vector3(2.75, 1.13, 7.45), Vector3.UP)
	_machine.rotate_y(PI)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.085, 0.035, 0.17)
	body.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color("1d1e22")
	mm.roughness = 0.5
	body.material_override = mm
	body.position = Vector3(0, 0.018, 0)
	body.rotation.x = deg_to_rad(-14.0)
	_machine.add_child(body)
	var scr := Label3D.new()
	scr.text = "DECLINED"
	scr.font = Look.font("mono")
	scr.font_size = 64
	scr.pixel_size = 0.00028
	scr.modulate = Color(0.75, 1.0, 0.86)
	scr.shaded = false
	scr.position = Vector3(0, 0.04, -0.035)
	scr.rotation.x = deg_to_rad(-76.0)
	_machine.add_child(scr)
	var lit := OmniLight3D.new()
	lit.light_color = Color(0.7, 1.0, 0.85)
	lit.light_energy = 0.25
	lit.omni_range = 0.4
	lit.position = Vector3(0, 0.08, -0.03)
	_machine.add_child(lit)
	_labels.append(_machine)


func _title_shot() -> void:
	_free_rig()
	_free_labels()
	_go("seawall")
	main.audio.ambience("rain_door")
	if _far != null:
		_far.stop()
	if _skipping:
		view.print_in(1.2)
		_go_black(0.3, true)
	else:
		_go_black(1.6, true)
	_bars_to(0.0, 0.4)
	_shot_t0 = t
	_shot = func(s: float):
		_eyes(SEAWALL_EYE, TITLE_LOOK + Vector3(0, -0.25 * (1.0 - smoothstep(0.0, 3.0, s)), 0), 0.92)


# ---------------------------------------------------------------- the type

func _card(text: String) -> void:
	var l := UiBits.label(text, "read", 34, Look.INK, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x * 0.62, 1100.0), 0)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.modulate.a = 0.0
	cards.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 1.1)
	main.audio.sfx("page", 0.25)


func _cards_out(secs: float) -> void:
	for c in cards.get_children():
		var tw := create_tween()
		tw.tween_property(c, "modulate:a", 0.0, secs)
		tw.tween_callback(c.queue_free)


func _clear_cards() -> void:
	for c in cards.get_children():
		c.queue_free()


func _say(text: String, secs: float) -> void:
	lower.text = text
	var tw := create_tween()
	tw.tween_property(lower, "modulate:a", 1.0, 0.6)
	tw.tween_interval(maxf(secs - 1.2, 0.5))
	tw.tween_property(lower, "modulate:a", 0.0, 0.6)


func _lower_out(secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(lower, "modulate:a", 0.0, secs)


func _go_black(secs: float, clear := false) -> void:
	var tw := create_tween()
	tw.tween_property(black, "modulate:a", 0.0 if clear else 1.0, secs)


func _bars(h: float) -> void:
	(bars[0] as ColorRect).anchor_bottom = h
	(bars[1] as ColorRect).anchor_top = 1.0 - h


func _bars_to(h: float, secs: float) -> void:
	var from: float = (bars[0] as ColorRect).anchor_bottom
	var tw := create_tween()
	tw.tween_method(_bars, from, h, secs)


# ---------------------------------------------------------------- sound

func _vol() -> float:
	var s: Dictionary = main.settings
	if not s.get("sound", true):
		return 0.0
	return clampf(float(s.get("master", 0.8)), 0.0, 1.0) * clampf(float(s.get("music", 0.8)), 0.0, 1.0)


func _far_player() -> void:
	if _far != null:
		return
	_far_bus = AudioServer.get_bus_index("IntroFar")
	if _far_bus < 0:
		_far_bus = AudioServer.bus_count
		AudioServer.add_bus(_far_bus)
		AudioServer.set_bus_name(_far_bus, "IntroFar")
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 700.0
		AudioServer.add_bus_effect(_far_bus, lp, 0)
	_far = AudioStreamPlayer.new()
	_far.bus = "IntroFar"
	var st = main.audio._stream("amb_juke", 0)
	if st is AudioStreamWAV:
		(st as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		(st as AudioStreamWAV).loop_end = (st as AudioStreamWAV).data.size() / 4
	_far.stream = st
	_far.volume_db = -60.0
	add_child(_far)
	if st != null:
		_far.play()


# ---------------------------------------------------------------- tidying

func _free_rig() -> void:
	if _rig != null:
		_rig.done()
		_rig = null


func _free_labels() -> void:
	for l in _labels:
		if is_instance_valid(l):
			l.queue_free()
	_labels.clear()
	_machine = null
