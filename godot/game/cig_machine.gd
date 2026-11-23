# The cigarette machine against the east wall of the bar, under the TV on the news, between the
# dartboard and the deck door, where everyone going out for a smoke passes it. Pulled from service
# when the ban came in, the plug coiled on top and taped. It plays anyway. Nobody explains it.
# (game/cig_synth.gd is its voice.)
#
# Everything on it is what was always on it, and each thing does what it does to the sound:
#   the knobs     twelve, one under each brand, an octave of them left to right. Grab one and pull
#                 it out toward you: past the detent it speaks, and the further out the brighter and
#                 harder (the filter opens, it leans on it). Let go and the spring takes it home.
#                 The keys play them too: A W S E D F T G Y H U J, the way a piano's laid out.
#                 Z and X take the whole row down or up an octave.
#   the slot      25 CENTS. A quarter in holds whatever's pulled when the knob goes back in; pull
#                 one that's held and it lets it go. More quarters, more octaves for the motor.
#   coin return   the lever bends the pitch down as it goes; all the way down and the coins come
#                 back into the cup, the hold with them. Click the cup to take them.
#   the steel     knock on it: a knuckle (left button) is bright, a palm (right button) is a thump,
#                 and where it's hit changes how the box rings. Two knocks a beat apart set the
#                 speed of the motor and the echo.
#   the tray      the flap on the delivery tray, slapped: a tin snare.
#   the wheel     shoves it: it rocks on its feet, and the pitch rocks with it; the tube flickers.
#   the door      the lock's been drilled; the front swings open on its hinge. Inside, on the
#                 service board:
#                   PRICE         two thumbwheels. The dollars pick the voice (ten of them,
#                                 cig_synth.gd PATCHES). The dimes are its age: at 0 it's as new;
#                                 at 9 every voice drifts, the tape wows, the knobs crackle.
#                   LAMP          off, on, start: the tube behind the brands. On is a chorus; start
#                                 is the starter flickering, a deeper one; both bring the ballast's hum.
#                   MOTOR TEST    walks through what the quarters are holding, a note at a time.
#                   RELAY DELAY   the vend relay's timer: an echo, the further round the more.
#                 And in column seven, behind THISTLE, one pack still in the rack. At the right
#                 price, with the quarters in, a hard pull all the way out drops it.
#
# The column keeps to what he'd notice. Esc steps back from it; a quarter's hold keeps playing in
# the room while he's gone, until the coin mech gives up and drops it into the box.
class_name CigMachine
extends Node

const AT := Vector3(15.64, 0.0, 5.3)                 # the middle of its front, on the floor: against the east wall under the news, between the darts and the deck door
const TURN := -PI / 2.0                              # facing into the room (its front, +z, to the west)
var FRAME := Transform3D(Basis(Vector3.UP, TURN), AT)
const W := 1.0
const H := 1.74
const D := 0.46
const KNOB_X0 := 0.07                                 # door-local: the first knob, from the hinge side
const KNOB_DX := 0.0665
const KNOB_Y := 0.80
const TRAVEL := 0.085                                 # how far a knob comes out
const DETENT := 0.1                                   # past this much of its travel it speaks
const KEYS := [KEY_A, KEY_W, KEY_S, KEY_E, KEY_D, KEY_F, KEY_T, KEY_G, KEY_Y, KEY_H, KEY_U, KEY_J]
const BASE_NOTE := 60
# the brands nobody's made since: invented, each its own pack, printed in the inks there are
const BRANDS := [["MATADOR", "b9a47a"], ["NORTHERN", "6d8a8e"], ["CABOT", "c8c2b0"], ["REGAL", "8a6a44"],
	["VANGUARD", "3d4a5c"], ["LAKESHORE", "a9bcc0"], ["THISTLE", "7a7a5a"], ["MONARCH", "d8c48a"],
	["SABLE", "2b2a27"], ["HARBOUR", "8c9c94"], ["PIONEER", "b08a5a"], ["CAPE", "e0dccc"]]
const PACK_COLUMN := 6                                # THISTLE: the last pack in the machine

signal left

var main
var pub: Pub
var view: View
var synth: CigSynth
var root: Node3D                 # the machine, rocking on its feet
var door: Node3D                 # its front, on the hinge
var knobs: Array = []            # the plungers, moved out as they're pulled
var windows: Array = []          # each brand's window, lit by its note
var lever: Node3D
var lamp_light: OmniLight3D
var cup_coins: Node3D
var pack_node: Node3D
var drums: Array = []            # the two price thumbwheels' digits (Label3D)
var lamp_sw: Node3D
var motor_sw: Node3D
var relay: Node3D
var hover_label: Label

var active := false
var rehearsal := false
var body := {}
var t := 0.0
var pull := []                   # each knob, 0..1 of its travel
var shown := []                  # and as the sound last had it
var by_key := {}                 # knobs the keys are holding
var grabbed := -1                # the knob the mouse has
var grab_y := 0.0
var bend_held := false
var lever_v := 0.0               # 0 up, 1 at the bottom
var door_open := false
var door_a := 0.0                # degrees open
var dollars := 1
var dimes := 3
var lamp := 0
var motor := false
var relay_v := 0.0
var pocket := 6                  # quarters on him
var in_cup := 0                  # quarters in the return cup
var pack_left := true
var pack_in_tray := false
var hovered := ""
var seen := {}
var away_t := 0.0                # a hold left playing while he's gone
var _saved := {}
var _ph := [0.0, 0.0]


func setup(m) -> void:
	main = m
	pub = m.pub
	view = m.view
	for i in 12:
		pull.append(0.0)
		shown.append(0.0)
	_build()
	synth = CigSynth.new()
	add_child(synth)
	synth.setup()
	_apply_price()
	hover_label = UiBits.label("", "ui", 18, Look.INK_2)
	hover_label.visible = false
	hover_label.z_index = 20
	main.root.add_child(hover_label)
	var r := RandomNumberGenerator.new()
	r.seed = 1997
	_ph = [r.randf() * TAU, r.randf() * TAU]
	set_process(true)
	set_process_input(false)


# ---------------------------------------------------------------- the machine, built

func _build() -> void:
	var M: Dictionary = pub.M
	root = Node3D.new()
	root.name = "cig_machine"
	root.position = AT
	root.rotation.y = TURN
	pub.add_child(root)
	var enamel := pub.mat(Color("a89c80"), 0.45, 0.25, 2, Vector3.UP, 5.0, 0.9)     # the cabinet: brown enamel gone dull
	var chrome := pub.mat(Color("b4b8ba"), 0.18, 0.9, 2, Vector3.UP, 4.0, 1.0)
	var inside := pub.mat(Color("3a3834"), 0.8, 0.2)
	# the cabinet: back, sides, top, bottom, on four short feet
	pub.box(Vector3(W, H - 0.04, 0.02), Vector3(0, 0.04 + (H - 0.04) / 2.0, -D + 0.01), enamel, 0.0, root)
	for sx in [-1.0, 1.0]:
		pub.box(Vector3(0.02, H - 0.04, D), Vector3(sx * (W / 2.0 - 0.01), 0.04 + (H - 0.04) / 2.0, -D / 2.0), enamel, 0.0, root)
	pub.box(Vector3(W, 0.03, D), Vector3(0, H - 0.015, -D / 2.0), enamel, 0.0, root)
	pub.box(Vector3(W, 0.08, D), Vector3(0, 0.08, -D / 2.0), M.black, 0.0, root)
	for fx in [-0.44, 0.44]:
		for fz in [-0.4, -0.06]:
			pub.cyl(0.025, 0.03, 0.04, Vector3(fx, 0.02, fz), M.black, root, 8)
	# the plug, coiled on top and taped, and twenty years of dust
	for k in 3:
		var coil := pub.cyl(0.07 - k * 0.006, 0.07 - k * 0.006, 0.012, Vector3(-0.28, H + 0.006 + k * 0.012, -0.22), M.black, root, 14)
		coil.rotation.y = k * 0.7
	pub.box(Vector3(0.05, 0.03, 0.03), Vector3(-0.2, H + 0.05, -0.18), M.dark, 0.0, root)
	pub.box(Vector3(0.03, 0.04, 0.16), Vector3(-0.28, H + 0.03, -0.22), pub.mat(Color("cfc8b0"), 0.9), 0.0, root)   # the tape
	# inside: the twelve columns, steel channels; the coin mech; the service board
	pub.box(Vector3(W - 0.04, H - 0.2, 0.01), Vector3(0, 0.95, -D + 0.03), inside, 0.0, root)
	for i in 12:
		var cx := -W / 2.0 + KNOB_X0 + i * KNOB_DX
		pub.box(Vector3(0.004, 0.62, 0.2), Vector3(cx + KNOB_DX / 2.0, 1.12, -0.32), M.steel, 0.0, root)
	pub.box(Vector3(0.12, 0.32, 0.2), Vector3(0.4, 0.62, -0.25), M.steel, 0.0, root)             # the coin mech
	pub.box(Vector3(0.12, 0.12, 0.2), Vector3(0.4, 0.3, -0.25), M.dark, 0.0, root)               # the cash box
	# the pack: THISTLE, the last one, lying at the foot of its column
	pack_node = Node3D.new()
	root.add_child(pack_node)
	var pcx := -W / 2.0 + KNOB_X0 + PACK_COLUMN * KNOB_DX
	pack_node.position = Vector3(pcx, 0.84, -0.32)
	pub.box(Vector3(0.055, 0.085, 0.022), Vector3.ZERO, pub.mat(Color("7a7a5a"), 0.6), 0.0, pack_node)
	pub.box(Vector3(0.056, 0.02, 0.023), Vector3(0, 0.03, 0), pub.mat(Color("d8d4c6"), 0.7), 0.0, pack_node)
	_service_board()
	_door()
	# the tube behind the brands, for the lamp
	lamp_light = OmniLight3D.new()
	lamp_light.light_color = Color("d8f5e4")
	lamp_light.light_energy = 0.0
	lamp_light.omni_range = 1.6
	lamp_light.position = Vector3(-0.1, 1.08, 0.2)
	lamp_light.shadow_enabled = false
	root.add_child(lamp_light)
	# the bare bulb over the corner, on the ceiling by the kitchen door: just enough to read it by
	var bulb := OmniLight3D.new()
	bulb.light_color = Color("ffd9a0")
	bulb.light_energy = 0.45
	bulb.omni_range = 2.4
	bulb.omni_attenuation = 1.6
	bulb.position = Vector3(0.1, 2.5, 0.7)
	root.add_child(bulb)
	pub.anchors["cigmachine"] = FRAME * Vector3(0, 1.1, 0.02)


func _door() -> void:
	var M: Dictionary = pub.M
	door = Node3D.new()
	door.position = Vector3(-W / 2.0, 0, 0)
	root.add_child(door)
	var enamel := pub.mat(Color("a89c80"), 0.45, 0.25, 2, Vector3.UP, 5.0, 0.9)
	var chrome := pub.mat(Color("b4b8ba"), 0.18, 0.9, 2, Vector3.UP, 4.0, 1.0)
	var cx := W / 2.0
	# the door's face in parts, so the windows and the tray are holes in it
	pub.box(Vector3(W, 0.12, 0.03), Vector3(cx, 0.18, -0.015), enamel, 0.0, door)                 # under the tray
	pub.box(Vector3(W, 0.3, 0.03), Vector3(cx, 0.6, -0.015), enamel, 0.0, door)                   # between the tray and the knobs
	pub.box(Vector3(0.12, 0.16, 0.03), Vector3(0.06, 0.34, -0.015), enamel, 0.0, door)            # either side of the tray
	pub.box(Vector3(0.36, 0.16, 0.03), Vector3(0.82, 0.34, -0.015), enamel, 0.0, door)
	pub.box(Vector3(W, 0.14, 0.03), Vector3(cx, 0.82, -0.015), enamel, 0.0, door)                 # the knobs' strip
	pub.box(Vector3(W, 0.05, 0.03), Vector3(cx, 1.255, -0.015), enamel, 0.0, door)                # over the windows
	pub.box(Vector3(W, 0.04, 0.03), Vector3(cx, 0.905, -0.015), enamel, 0.0, door)                # under them
	pub.box(Vector3(0.2, 0.32, 0.03), Vector3(0.9, 1.08, -0.015), enamel, 0.0, door)              # the coin side
	# the delivery tray: a chrome trough behind a flap
	pub.box(Vector3(0.5, 0.02, 0.1), Vector3(0.4, 0.27, -0.05), chrome, 0.0, door)
	pub.box(Vector3(0.5, 0.15, 0.01), Vector3(0.4, 0.34, -0.1), M.black, 0.0, door)
	var flap := pub.box(Vector3(0.5, 0.11, 0.006), Vector3(0.4, 0.36, 0.004), chrome, 0.0, door)
	flap.rotation.x = deg_to_rad(-8.0)
	var tray_lbl := _label(door, "PULL KNOB ALL THE WAY OUT", Vector3(0.4, 0.45, 0.002), 18, Color("2b2a27"))
	tray_lbl.pixel_size = 0.0006
	# the knobs: a chrome cup on the face, the plunger, the handle across
	for i in 12:
		var x := KNOB_X0 + i * KNOB_DX
		pub.cyl(0.02, 0.02, 0.006, Vector3(x, KNOB_Y, 0.003), chrome, door, 14).rotation.x = PI / 2.0
		var k := Node3D.new()
		k.position = Vector3(x, KNOB_Y, 0.0)
		door.add_child(k)
		var rod := pub.cyl(0.008, 0.008, 0.04, Vector3(0, 0, 0.02), chrome, k, 10)
		rod.rotation.x = PI / 2.0
		pub.box(Vector3(0.046, 0.017, 0.016), Vector3(0, 0, 0.045), chrome, 0.0, k)
		knobs.append(k)
		# the price over it, on a paper strip
		pub.box(Vector3(0.05, 0.016, 0.002), Vector3(x, 0.868, 0.001), pub.mat(Color("d9d4c8"), 0.9, 0.0, 3), 0.0, door)
		# the brand's window: a pack face behind glass, lit from behind
		var b: Array = BRANDS[i]
		var c := Color(b[1])
		var wm := pub.glow(c, 0.05)
		wm.set_shader_parameter("albedo", c)
		var win := pub.box(Vector3(0.054, 0.3, 0.004), Vector3(x, 1.075, -0.02), wm, 0.0, door)
		win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		windows.append(win)
		var name_l := _label(door, b[0], Vector3(x, 1.08, -0.016), 26, Color("1f1e22") if c.v > 0.5 else Color("e6dcc0"))
		name_l.rotation.z = PI / 2.0
		name_l.pixel_size = 0.00055
		# the mullions between
		pub.box(Vector3(0.0125, 0.32, 0.03), Vector3(x + KNOB_DX / 2.0, 1.075, -0.015), enamel, 0.0, door)
	pub.box(Vector3(0.04, 0.32, 0.03), Vector3(0.02, 1.075, -0.015), enamel, 0.0, door)
	_prices()
	# the mirror strip, grey at the corners, and the sticker someone tried to get off with a key
	pub.box(Vector3(W, 0.24, 0.012), Vector3(cx, 1.4, -0.006), M.mirror, 0.0, door)
	pub.box(Vector3(0.3, 0.06, 0.002), Vector3(0.62, 1.34, 0.002), pub.mat(Color("d8c48a"), 0.9, 0.0, 3), 0.0, door)
	var law := _label(door, "IT'S THE LAW — 19 TO BUY", Vector3(0.62, 1.34, 0.0035), 22, Color("2b2a27"))
	law.pixel_size = 0.0006
	pub.box(Vector3(0.09, 0.045, 0.003), Vector3(0.75, 1.335, 0.0035), M.mirror, 0.0, door).rotation.z = 0.2
	# the marquee: CIGARETTES, and the maker
	pub.box(Vector3(W, 0.2, 0.03), Vector3(cx, 1.62, -0.015), enamel, 0.0, door)
	var mq := pub.glow(Color("e6dcc0"), 0.06)
	pub.box(Vector3(W - 0.08, 0.13, 0.004), Vector3(cx, 1.63, 0.001), mq, 0.0, door)
	var title := _label(door, "Cigarettes", Vector3(cx, 1.635, 0.004), 120, Color("3d3a36"), "zilla")
	title.pixel_size = 0.0007
	var maker := _label(door, "DOMINION VENDING CO.  BRANTFORD, ONT.", Vector3(cx, 1.535, 0.002), 18, Color("d9d4c8"))
	maker.pixel_size = 0.0006
	# the coin side: the slot's plate, 25 CENTS, the return lever, the cup; the lock up by the mirror
	pub.box(Vector3(0.09, 0.13, 0.008), Vector3(0.91, 1.04, 0.004), chrome, 0.0, door)
	pub.box(Vector3(0.006, 0.03, 0.01), Vector3(0.91, 1.07, 0.006), M.black, 0.0, door)
	var cents := _label(door, "25¢", Vector3(0.91, 1.0, 0.0085), 40, Color("2b2a27"))
	cents.pixel_size = 0.0006
	lever = Node3D.new()
	lever.position = Vector3(0.91, 0.885, 0.01)
	door.add_child(lever)
	pub.box(Vector3(0.05, 0.02, 0.02), Vector3(0, 0, 0.01), chrome, 0.0, lever)
	var rl := _label(door, "COIN RETURN", Vector3(0.91, 0.915, 0.002), 16, Color("d9d4c8"))
	rl.pixel_size = 0.0006
	pub.box(Vector3(0.08, 0.07, 0.04), Vector3(0.91, 0.57, -0.01), M.black, 0.0, door)          # the cup
	pub.box(Vector3(0.085, 0.01, 0.045), Vector3(0.91, 0.535, 0.0), chrome, 0.0, door)
	cup_coins = Node3D.new()
	cup_coins.position = Vector3(0.91, 0.545, 0.0)
	door.add_child(cup_coins)
	pub.cyl(0.012, 0.012, 0.012, Vector3(0.93, 1.42, 0.006), chrome, door, 12).rotation.x = PI / 2.0
	pub.box(Vector3(0.008, 0.014, 0.004), Vector3(0.93, 1.42, 0.013), M.black, 0.0, door)       # drilled out


func _service_board() -> void:
	var M: Dictionary = pub.M
	var board := Node3D.new()
	board.position = Vector3(0.34, 0.0, -0.08)
	root.add_child(board)
	pub.box(Vector3(0.27, 0.55, 0.01), Vector3(0, 1.2, -0.005), pub.mat(Color("4a4843"), 0.7, 0.1), 0.0, board)
	var paper := pub.mat(Color("d9d4c8"), 0.9, 0.0, 3)
	var ink := Color("1f1e22")
	var cream := Color("d9d4c8")
	_label(board, "PRICE", Vector3(-0.07, 1.44, 0.002), 22, cream).pixel_size = 0.0006
	for k in 2:
		var dx := -0.1 + k * 0.055
		pub.box(Vector3(0.045, 0.06, 0.03), Vector3(dx, 1.38, 0.015), M.black, 0.0, board)
		var dg := _label(board, "0", Vector3(dx, 1.38, 0.031), 44, cream, "zilla")
		dg.pixel_size = 0.0007
		drums.append(dg)
	_label(board, "$       .   0", Vector3(-0.07, 1.335, 0.002), 18, cream).pixel_size = 0.0006
	_label(board, "LAMP", Vector3(0.08, 1.44, 0.002), 22, cream).pixel_size = 0.0006
	_label(board, "OFF  ON  START", Vector3(0.08, 1.33, 0.002), 14, cream).pixel_size = 0.0006
	lamp_sw = _toggle(board, Vector3(0.08, 1.38, 0.0))
	_label(board, "MOTOR TEST", Vector3(0.08, 1.24, 0.002), 18, cream).pixel_size = 0.0006
	motor_sw = _toggle(board, Vector3(0.08, 1.19, 0.0))
	_label(board, "RELAY DELAY", Vector3(-0.07, 1.24, 0.002), 18, cream).pixel_size = 0.0006
	relay = Node3D.new()
	relay.position = Vector3(-0.07, 1.17, 0.0)
	board.add_child(relay)
	var rk := pub.cyl(0.022, 0.025, 0.025, Vector3(0, 0, 0.0125), M.black, relay, 16)
	rk.rotation.x = PI / 2.0
	pub.box(Vector3(0.004, 0.02, 0.004), Vector3(0, 0.012, 0.027), paper, 0.0, relay)
	for k in 11:
		var a := deg_to_rad(-135.0 + k * 27.0)
		pub.box(Vector3(0.002, 0.006, 0.001), Vector3(sin(a) * 0.035, cos(a) * 0.035, 0.001), paper, -0.0, relay).rotation.z = -a
	# the service card, taped up: who came, when, and then nobody
	pub.box(Vector3(0.12, 0.09, 0.001), Vector3(0.0, 1.04, 0.001), paper, 0.0, board)
	var card := _label(board, "SERVICE\nM.L. 03/97\nM.L. 11/99\nM.L. 06/03\nD.", Vector3(0.0, 1.04, 0.002), 15, ink)
	card.pixel_size = 0.0006
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _toggle(parent: Node3D, at: Vector3) -> Node3D:
	var M: Dictionary = pub.M
	pub.box(Vector3(0.03, 0.03, 0.006), at + Vector3(0, 0, 0.003), pub.M.steel, 0.0, parent)
	var bat := Node3D.new()
	bat.position = at + Vector3(0, 0, 0.006)
	parent.add_child(bat)
	var st := pub.cyl(0.004, 0.006, 0.03, Vector3(0, 0, 0.015), M.steel, bat, 8)
	st.rotation.x = PI / 2.0
	return bat


func _label(parent: Node3D, text: String, at: Vector3, size: int, c: Color, font := "ui_b") -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = Look.font(font)
	l.font_size = size
	l.pixel_size = 0.0008
	l.modulate = c
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.position = at
	parent.add_child(l)
	return l


var _price_labels: Array = []

func _prices() -> void:
	for i in 12:
		var l := _label(door, "", Vector3(KNOB_X0 + i * KNOB_DX, 0.868, 0.0025), 20, Color("1f1e22"))
		l.pixel_size = 0.0005
		_price_labels.append(l)


func _apply_price() -> void:
	synth.set_patch(dollars)
	synth.wear = dimes / 9.0
	if drums.size() == 2:
		drums[0].text = str(dollars)
		drums[1].text = str(dimes)
	for l in _price_labels:
		l.text = "$%d.%d0" % [dollars, dimes]


func price_quarters() -> int:
	return maxi(1, int(ceil((dollars * 100 + dimes * 10) / 25.0)))


# ---------------------------------------------------------------- in and out

func begin(rehearse := false, from := {}) -> void:
	active = true
	rehearsal = rehearse
	body = from.duplicate()
	if not rehearse:
		body = {"drinks": view.drinks, "hurt": view.hurt, "tension": view.tension, "clock": view.clock, "cold": 0.0}
		pocket = maxi(pocket, 0)
	else:
		pocket = 12
		in_cup = 0
		pack_left = true
		pack_in_tray = false
		pack_node.visible = true
		pack_node.position = Vector3(-W / 2.0 + KNOB_X0 + PACK_COLUMN * KNOB_DX, 0.84, -0.32)
		pack_node.rotation = Vector3.ZERO
	_saved = {"eye": view.eye_pos, "yaw": view.yaw, "pitch": view.pitch, "walking": view.walking}
	view.walking = false
	view.focus_fov = 56.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	away_t = 0.0
	synth.start()
	set_process_input(true)
	_column_begin()


func end() -> void:
	if not active:
		return
	active = false
	grabbed = -1
	bend_held = false
	for i in 12:
		synth.push_in(BASE_NOTE + i)
		pull[i] = 0.0
	by_key.clear()
	hover_label.visible = false
	view.focus_fov = 0.0
	view.hand_drag = false
	set_process_input(false)
	if not rehearsal:
		view.eye_pos = _saved.get("eye", view.eye_pos)
		view.yaw = _saved.get("yaw", view.yaw)
		view.pitch = _saved.get("pitch", view.pitch)
		view.want_yaw = view.yaw
		view.want_pitch = view.pitch
	# a hold left on keeps going in the room while he's gone; a rehearsal's ends with it
	if rehearsal:
		pocket += synth.coins_back() + in_cup
		in_cup = 0
		_cup_draw()
		synth.all_off()
	elif synth.credit == 0 or (synth.latched.is_empty() and not synth.arp_on):
		synth.all_off()
	left.emit()


# ---------------------------------------------------------------- every frame

func _process(dt: float) -> void:
	t += dt
	# the knobs: the mouse's, the keys', or springing home
	for i in 12:
		var want := 0.0
		if by_key.has(i):
			want = float(by_key[i])
		elif i == grabbed:
			want = pull[i]
		if i != grabbed:
			pull[i] = move_toward(pull[i], want, dt * (9.0 if want > pull[i] else 14.0))
		_knob_moved(i, shown[i], pull[i])
		shown[i] = pull[i]
		(knobs[i] as Node3D).position.z = pull[i] * TRAVEL
	# the coin return lever: springs up
	if not bend_held:
		lever_v = move_toward(lever_v, 0.0, dt * 6.0)
	synth.bend = -lever_v * 2.0 if lever_v < 0.92 else -2.0
	lever.position.y = 0.885 - lever_v * 0.03
	lever.rotation.x = -lever_v * 0.35
	# the door, on its hinge
	door_a = move_toward(door_a, 105.0 if door_open else 0.0, dt * 240.0)
	door.rotation.y = deg_to_rad(-door_a)
	# the box rocking on its feet
	root.rotation.x = synth.rock * 0.03
	# the lamp, the windows: each lit by its note as it sounds, lamp or no lamp
	var base: float = [0.04, 0.55, 0.5][lamp]
	if lamp == 2:
		base *= 0.4 + (1.0 if fmod(t * 7.3, 1.0) > 0.3 else 0.0) * 0.7 * (0.6 + 0.4 * sin(t * 61.0))
	if absf(synth.rock) > 0.05:
		base *= 0.6 + 0.4 * randf()
	lamp_light.light_energy = base * 0.8
	var lit := []
	for i in 12:
		lit.append(0.0)
	for v in synth.voices:
		if v.busy:
			var n := posmod(int(v.note) - synth.octave * 12, 12)
			lit[n] = maxf(lit[n], float(v.amp))
	for i in 12:
		var m: ShaderMaterial = (windows[i] as MeshInstance3D).material_override
		m.set_shader_parameter("emission_energy", base + lit[i] * 1.4)
	# heard from where he is: in the room it carries; from the back, through the walls
	var d := view.eye_pos.distance_to(FRAME * Vector3(0, 1.0, 0))
	var db := -20.0 * log(maxf(1.0, d / 1.2)) / log(10.0)
	if not active and Hotspots.PART.get(view.place, "room") != "room":
		db -= 10.0
	synth.player.volume_db = db + linear_to_db(float(main.settings.get("vol_room", 1.0)) if main.settings.has("vol_room") else 1.0)
	# a hold left playing, while he's away: the coin mech gives up after a while
	if not active and synth.running:
		away_t += dt
		if synth.credit > 0 and away_t > 150.0:
			synth.credit = 0
			synth.strike(synth.cabinet, 0.3, 0.6, 0.4, 3)
			synth.all_off()
		if synth.credit == 0 and away_t > 4.0:
			var any := false
			for v in synth.voices:
				any = any or v.busy
			if not any:
				synth.stop()
	if active:
		_eyes(dt)
		_body_tremor()


# his eyes on it: square on to the front, or round into the open door; leaning a little toward
# where the pointer is, the way you lean in to what your hand's on
func _eyes(dt: float) -> void:
	var eye_l := Vector3(0.0, 1.42, 1.32)
	var look_l := Vector3(0.03, 0.98, 0.0)
	if door_open:
		eye_l = Vector3(0.5, 1.42, 0.7)
		look_l = Vector3(0.34, 1.18, -0.08)
	var pp := view.pointer
	if pp.x >= 0.0 and view.eye != null:
		var off := (pp / Vector2(view.eye.size) - Vector2(0.5, 0.5))
		look_l += Vector3(off.x * 0.12, -off.y * 0.1, 0)
		eye_l += Vector3(off.x * 0.05, 0, 0)
	var want_eye := FRAME * eye_l
	var k := 1.0 - exp(-dt * 5.0)
	view.eye_pos = view.eye_pos.lerp(want_eye, k) if view.eye_pos.distance_to(want_eye) < 3.0 else want_eye
	var a := Posts.aim(view.eye_pos, FRAME * look_l)
	view.yaw = lerp_angle(view.yaw, a.x, k)
	view.pitch = lerpf(view.pitch, a.y, k)
	view.want_yaw = view.yaw
	view.want_pitch = view.pitch


# his hand on a knob shakes as it does on a dart: the drink, the nerves, the cold
func _body_tremor() -> void:
	var drinks := float(body.get("drinks", 0))
	var nerves := float(body.get("tension", 0))
	var hurt := float(body.get("hurt", 0))
	var s := drinks * 0.006 + nerves * 0.008 + hurt * 0.01 + float(body.get("cold", 0.0)) * 0.02
	if s <= 0.0:
		return
	var f := 7.5 + nerves
	var w := sin(t * TAU * f + _ph[0]) * 0.6 + sin(t * TAU * f * 1.41 + _ph[1]) * 0.4
	for i in 12:
		if pull[i] > DETENT and synth.held.has(BASE_NOTE + i):
			synth.pull(BASE_NOTE + i, clampf(_expr(pull[i]) + w * s, 0.0, 1.0))


func _knob_moved(i: int, was: float, now: float) -> void:
	if was == now:
		return
	synth.crackle = minf(1.0, synth.crackle + absf(now - was) * 6.0)
	if was < DETENT and now >= DETENT:
		synth.knob_click(false)
		synth.pull(BASE_NOTE + i, _expr(now))
		_noticed_note()
	elif now >= DETENT:
		synth.pull(BASE_NOTE + i, _expr(now))
	if was < 0.97 and now >= 0.97:
		synth.knob_click(true)
		_full_pull(i)
	if was >= DETENT and now < DETENT:
		synth.push_in(BASE_NOTE + i)
		synth.knob_home()


func _expr(p: float) -> float:
	return clampf((p - DETENT) / (1.0 - DETENT), 0.0, 1.0)


# ---------------------------------------------------------------- the player's hands

func _input(e: InputEvent) -> void:
	if not active:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		end()
		return
	if main.menus.is_open():
		return
	if e is InputEventMouse:
		var sh: Control = view.sheet
		var local: Vector2 = (e as InputEventMouse).position - sh.global_position
		if local.x >= 0.0 and local.y >= 0.0 and local.x <= sh.size.x and local.y <= sh.size.y:
			view.pointer = local / sh.size * Vector2(view.eye.size)
		else:
			view.pointer = Vector2(-1, -1)
		hovered = _under()
		_hover(e.position)
	if e is InputEventMouseMotion:
		var rel: Vector2 = e.relative
		if grabbed >= 0:
			# pulled toward him is down the screen
			pull[grabbed] = clampf(pull[grabbed] + rel.y / 180.0, 0.0, 1.0)
		elif bend_held:
			lever_v = clampf(lever_v + rel.y / 90.0, 0.0, 1.0)
			if lever_v >= 0.98:
				_coin_return()
		elif grabbed == -2:
			_relay(-rel.y / 150.0)
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_press(hovered, mb.button_index == MOUSE_BUTTON_RIGHT)
			else:
				_release()
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var up := mb.button_index == MOUSE_BUTTON_WHEEL_UP
			if hovered.begins_with("drum"):
				_drum(int(hovered.substr(4)), 1 if up else -1)
			elif hovered == "relay":
				_relay(0.05 if up else -0.05)
			else:
				synth.shake(0.9 if up else -0.9)
				_once("rock", "He leaned on it and it rocked on its feet, and the note went with it.")
	elif e is InputEventKey:
		var ke := e as InputEventKey
		var k: int = ke.physical_keycode
		var i := KEYS.find(k)
		if i >= 0 and not ke.echo:
			if ke.pressed:
				by_key[i] = 1.0 if ke.shift_pressed else 0.62
			else:
				by_key.erase(i)
		elif ke.pressed and not ke.echo:
			match k:
				KEY_Z:
					_octave(-1)
				KEY_X:
					_octave(1)
				KEY_C:
					_coin()
				KEY_R:
					lever_v = 1.0
					_coin_return()
				KEY_SPACE:
					_knock(0.5, 0.45, false)
				KEY_O:
					_door_toggle()
		get_viewport().set_input_as_handled()


func _press(what: String, right: bool) -> void:
	if what.begins_with("knob"):
		grabbed = int(what.substr(4))
		return
	match what:
		"lever":
			bend_held = true
		"slot":
			_coin()
		"cup":
			_take_cup()
		"tray":
			if pack_in_tray:
				_take_pack()
			else:
				synth.flap(0.9 if right else 0.6)
		"lock", "door":
			_door_toggle()
		"lamp":
			lamp = (lamp + 1) % 3
			synth.set_lamp(lamp)
			synth.strike(synth.knob, 0.4, 0.9, 0.3, 1)
			lamp_sw.rotation.x = [-0.5, 0.0, 0.5][lamp]
			if lamp > 0:
				_once("lamp", "The tube behind the brands came on, from nowhere, the plug still taped on top. It hummed, and everything the machine did after that had a shimmer round it.")
		"motor":
			motor = not motor
			synth.set_arp(motor)
			synth.strike(synth.knob, 0.4, 0.9, 0.6, 1)
			motor_sw.rotation.x = 0.5 if motor else -0.5
			if motor and synth.credit > 0:
				_once("motor", "Somewhere in it a motor started turning, and it walked through what the quarter was holding, one at a time.")
		"relay":
			grabbed = -2
		_:
			if what.begins_with("drum"):
				var di := int(what.substr(4, 1))
				_drum(di, -1 if what.ends_with("dn") else 1)
			elif what.begins_with("steel") or what == "mirror":
				var p := _hit_local()
				_knock(clampf(p.x / W, 0.0, 1.0), clampf(p.y / H, 0.0, 1.0), right)


func _release() -> void:
	if grabbed >= 0:
		grabbed = -1
	elif grabbed == -2:
		grabbed = -1
	bend_held = false


# what's under the pointer on it, by where the ray from his eyes meets the door's face (or the
# service board, with the door open)
func _under() -> String:
	if view.pointer.x < 0.0:
		return ""
	var r := view.ray()
	if door_a > 60.0:
		var bp = _plane_hit(root.global_transform * Transform3D(Basis(), Vector3(0.34, 0, -0.08)), r)
		if bp != null:
			var p: Vector2 = bp
			if absf(p.x) < 0.14 and p.y > 0.92 and p.y < 1.48:
				for k in 2:
					var dx := -0.1 + k * 0.055
					if absf(p.x - dx) < 0.025 and absf(p.y - 1.38) < 0.035:
						return "drum%d%s" % [k, "up" if p.y > 1.38 else "dn"]
				if absf(p.x - 0.08) < 0.03 and absf(p.y - 1.38) < 0.03:
					return "lamp"
				if absf(p.x - 0.08) < 0.03 and absf(p.y - 1.19) < 0.03:
					return "motor"
				if absf(p.x + 0.07) < 0.04 and absf(p.y - 1.17) < 0.04:
					return "relay"
				return "board"
		var dp = _plane_hit(door.global_transform, r)
		if dp != null:
			var q: Vector2 = dp
			if q.x > 0.0 and q.x < W and q.y > 0.1 and q.y < H:
				return "door"
		return ""
	var hit = _plane_hit(door.global_transform, r)
	if hit == null:
		return ""
	var p: Vector2 = hit
	if p.x < 0.0 or p.x > W or p.y < 0.1 or p.y > H:
		return ""
	if absf(p.y - KNOB_Y) < 0.035:
		var i := int(round((p.x - KNOB_X0) / KNOB_DX))
		if i >= 0 and i < 12 and absf(p.x - (KNOB_X0 + i * KNOB_DX)) < 0.03:
			return "knob%d" % i
	if absf(p.x - 0.91) < 0.05:
		if absf(p.y - 1.04) < 0.07:
			return "slot"
		if absf(p.y - 0.885) < 0.03:
			return "lever"
		if absf(p.y - 0.57) < 0.05:
			return "cup"
	if absf(p.x - 0.93) < 0.03 and absf(p.y - 1.42) < 0.03:
		return "lock"
	if p.x > 0.15 and p.x < 0.65 and p.y > 0.26 and p.y < 0.43:
		return "tray"
	if p.y > 0.93 and p.y < 1.23 and p.x < 0.82:
		var wi := int(round((p.x - KNOB_X0) / KNOB_DX))
		return "window%d" % clampi(wi, 0, 11)
	if p.y > 1.28 and p.y < 1.52:
		return "mirror"
	return "steel"


var _last_hit := Vector2.ZERO

func _plane_hit(xf: Transform3D, r: Array):
	var inv := xf.affine_inverse()
	var o: Vector3 = inv * (r[0] as Vector3)
	var d: Vector3 = inv.basis * (r[1] as Vector3)
	if absf(d.z) < 0.0001:
		return null
	var s := -o.z / d.z
	if s < 0.0:
		return null
	var p := o + d * s
	_last_hit = Vector2(p.x, p.y)
	return Vector2(p.x, p.y)


func _hit_local() -> Vector2:
	_under()
	return _last_hit


const NAMES := {"slot": "the coin slot", "lever": "coin return", "cup": "the return cup", "tray": "the tray",
	"lock": "the lock", "door": "the door", "lamp": "LAMP", "motor": "MOTOR TEST", "relay": "RELAY DELAY", "mirror": "",
	"steel": "", "board": ""}


func _hover(at: Vector2) -> void:
	var s := ""
	if hovered.begins_with("knob"):
		s = BRANDS[int(hovered.substr(4))][0].capitalize()
	elif hovered.begins_with("window"):
		s = BRANDS[int(hovered.substr(6))][0].capitalize()
	elif hovered.begins_with("drum"):
		s = "PRICE"
	elif hovered == "cup" and in_cup == 0:
		s = ""
	elif hovered == "tray" and pack_in_tray:
		s = "a pack of Thistle"
	else:
		s = NAMES.get(hovered, "")
	hover_label.text = s
	hover_label.visible = s != ""
	hover_label.position = at + Vector2(18, 10)


# ---------------------------------------------------------------- what each thing does

func _octave(d: int) -> void:
	synth.octave = clampi(synth.octave + d, -2, 2)
	for i in 12:
		synth.push_in(BASE_NOTE + i)
	by_key.clear()


func _coin() -> void:
	if pocket <= 0:
		_once("broke", "He felt in his pocket for another quarter and there wasn't one.")
		return
	pocket -= 1
	synth.coin_in()
	_once("coin", "The quarter went down through the works and landed on something. When he let go of the knob, the note stayed.")


func _coin_return() -> void:
	bend_held = false
	if synth.credit <= 0:
		synth.strike(synth.knob, 0.3, 0.7, 0.5, 2)
		return
	var n := synth.coins_back()
	in_cup += n
	_cup_draw()
	_once("return", "The quarters came back down into the cup, and whatever it was holding went with them.")


func _take_cup() -> void:
	if in_cup <= 0:
		return
	pocket += in_cup
	in_cup = 0
	_cup_draw()
	main.audio.sfx("pocket", 0.5, 1.0)


func _cup_draw() -> void:
	for c in cup_coins.get_children():
		c.queue_free()
	for k in mini(in_cup, 8):
		var c := pub.cyl(0.012, 0.012, 0.0018, Vector3((k % 3) * 0.012 - 0.012, 0.002 + k * 0.0018, 0.004 * (k % 2)), pub.M.steel, cup_coins, 12)
		c.rotation.z = 0.08 * k


func _knock(x: float, y: float, palm: bool) -> void:
	synth.knock(x, y, 0.9 if palm else 0.7, 0.0 if palm else 1.0)
	if synth._knocks.size() >= 2:
		_once("tempo", "He knocked on the side of it twice, and after that anything it walked through, it walked through at that speed.")


func _door_toggle() -> void:
	door_open = not door_open
	synth.strike(synth.cabinet, 0.35, 0.5, 0.15, 3)
	synth.strike(synth.knob, 0.3, 0.6, 0.9, 2)
	if door_open:
		_once("door", "The lock had been drilled out years ago. The front came open on its hinge. Inside, on a board on the right, PRICE, LAMP, MOTOR TEST, RELAY DELAY, and a service card with three visits on it and a D. And in the seventh column, behind THISTLE, one pack still in the rack.")


func _drum(k: int, d: int) -> void:
	if k == 0:
		dollars = posmod(dollars + d, 10)
	else:
		dimes = posmod(dimes + d, 10)
	_apply_price()
	synth.strike(synth.knob, 0.25, 0.95, 0.2 + k * 0.3, 1)
	_once("price", "He turned the price over. Every brand's price changed on its paper strip, and so did the voice.")


func _relay(d: float) -> void:
	relay_v = clampf(relay_v + d, 0.0, 1.0)
	relay.rotation.z = -deg_to_rad(-135.0 + relay_v * 270.0)
	synth.set_echo(relay_v)
	synth.crackle = minf(1.0, synth.crackle + 0.3)


func _full_pull(i: int) -> void:
	_once("full", "All the way out it hit the stop, and something in the column behind it moved.")
	if i == PACK_COLUMN and pack_left and synth.credit >= price_quarters():
		pack_left = false
		synth.credit = 0
		synth.latched.clear()
		# the pack comes down the column and over the lip into the tray
		var tw := create_tween()
		tw.tween_property(pack_node, "position:y", 0.3, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			synth.strike(synth.tray, 0.7, 0.4, 0.3, 4)
			synth.strike(synth.cabinet, 0.3, 0.3, 0.5, 4)
			# lying in the tray behind the flap, the cellophane catching the light
			pack_node.position = Vector3(-0.1, 0.29, -0.06)
			pack_node.rotation = Vector3(-PI / 2.0, 0.0, 0.3)
			pack_in_tray = true)
		_line("It took the quarters. Something came down inside and dropped into the tray: a pack of Thistle Kings, the cellophane gone yellow.")


func _take_pack() -> void:
	pack_in_tray = false
	pack_node.visible = false
	main.audio.sfx("pocket", 0.5, 1.0)
	if not rehearsal:
		main.settings["cig_pack"] = true
		main.store.save_settings()
	_line("He put the pack in his jacket. On the side, in the place the warning went, a picture of a man's lungs, and a price in a currency that still had pennies.")


func _noticed_note() -> void:
	_once("first", "The knob came out with a click, and the machine made a sound. A note, held as long as he held the knob, and brighter the further it came.")


# ---------------------------------------------------------------- what he notices

func _column_begin() -> void:
	if main.column == null:
		return
	main.column.begin_batch()
	if rehearsal:
		main.column.reset()
		main.column.add_line({"role": "narration", "text": "The cigarette machine against the east wall, under the news, on the way to the deck. The plug coiled on top of it and taped. Twelve knobs, twelve brands nobody makes now."})
	else:
		main.column.add_line({"role": "narration", "text": "He went over and stood in front of the cigarette machine."})
	main.column.add_note("Pull a knob out with the mouse (down is out) or play the row with A W S E D F T G Y H U J; Shift pulls one all the way. Z and X move the row an octave. Click the slot for a quarter (C), the coin return lever bends the note and gives them back (R). Knock on it: left button a knuckle, right a palm (Space). The wheel rocks it. The lock opens the front (O). Esc steps back.\nQuarters on him: %d." % pocket)
	main.column.scroll_to_end()


func _line(text: String) -> void:
	if text == "" or main.column == null:
		return
	main.column.begin_batch()
	main.column.add_line({"role": "narration", "text": text})
	main.column.scroll_to_end()


func _once(key: String, text: String) -> void:
	if seen.has(key):
		return
	seen[key] = true
	_line(text)
