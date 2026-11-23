# The Sov's pool table, built to the physics' own measures (game/pool_sim.gd), so a ball the sim
# says is touching a cushion is touching it on the screen, a ball that drops goes down through a hole
# that's there, and nothing passes through anything. A coin-op bar box: the slate in a cabinet, the
# cushions with their noses at the height the sim strikes them, the jaws faced in at the angle it
# turns them, the wooden rails with their pearl sights, the pockets' leather, the coin slide and the
# window at the foot end where the pocketed balls come down and wait for the next quarter.
#
# Its frame is the sim's: the cloth's middle at the table's origin plus BED up, x toward the foot.
class_name PoolTable
extends Node3D

const BED := 0.80                       # the cloth's height off the floor
const RAIL_W := 0.105                   # the wooden rail's width, past the cushion
const CUSH_W := 0.05                    # the cushion's depth, nose to back

var pub
var table: PoolSim.Table
var cloth_mat: Material
var ball_nodes := {}                    # id -> Node3D (the ball, its spin carried in its basis)
var trough: Node3D                      # the return's window
var trough_balls := []
var marker: Node3D                      # the chalk cube put by the called pocket
var chalk_cube: Node3D


func build(p, t: PoolSim.Table) -> void:
	pub = p
	table = t
	var M: Dictionary = pub.M
	var hl := table.L * 0.5
	var hw := table.W * 0.5
	var outer_l := table.L + 2.0 * (CUSH_W + RAIL_W)
	var outer_w := table.W + 2.0 * (CUSH_W + RAIL_W)
	# the cloth: a bar box's green gone the colour of old money where the break lands and along the
	# lines everyone plays, two burns, the slate under it
	cloth_mat = pub.mat(Color("2e5a43"), 0.95, 0.0, 1, Vector3(1, 0, 0), 6.0, 0.15)
	pub.box(Vector3(table.L + 2.0 * CUSH_W, 0.03, table.W + 2.0 * CUSH_W), Vector3(0, BED - 0.015, 0), cloth_mat, 0.0, self)
	# the worn bed where the break lands, paler
	var worn = pub.mat(Color("3d6650"), 0.95, 0.0, 1, Vector3(1, 0, 0), 6.0, 0.1)
	# (the wear's in the cloth's own strokes; a disc of it reads as a sticker)
	var _w = worn
	# the burns: a cigarette put down on the cloth, twice, years apart
	for bn in table.burns:
		var c: Vector3 = bn[0]
		_disc(Vector3(c.x, BED + 0.0005, c.z), float(bn[1]), pub.mat(Color("1d1a16"), 1.0, 0.0, 3), 10)
		_disc(Vector3(c.x + 0.003, BED + 0.0006, c.z - 0.002), float(bn[1]) * 0.55, pub.mat(Color("4b3b2a"), 1.0, 0.0, 3), 10)
	# the head string's spot and the foot spot: little paper spots stuck on
	for sp in [table.foot_spot(), table.head_spot()]:
		_disc(Vector3(sp.x, BED + 0.0007, sp.z), 0.006, pub.mat(Color("cfc7b0"), 0.9, 0.0, 3), 8)
	# the pockets: the slate cut away, black under the drop
	for pk in table.pockets:
		var c: Vector3 = pk[0]
		_disc(Vector3(c.x, BED + 0.0008, c.z), float(pk[1]) + 0.003, pub.mat(Color("070606"), 1.0, 0.0, 3), 16)
		# the leather cup under it
		var cup = pub.cyl(float(pk[1]) + 0.012, float(pk[1]) - 0.004, 0.09, Vector3(c.x, BED - 0.05, c.z), pub.mat(Color("17110d"), 0.6), self, 14)
		cup.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the cushions and the jaws' facings: the K-66 profile run along each, its nose where the sim has it
	var rubber = pub.mat(Color("2b553f"), 0.9, 0.0, 1, Vector3(1, 0, 0), 6.0, 0.4)
	for rl in table.rails:
		_cushion(rl[0], rl[1], rl[2], rubber)
	# the wooden rails, cut at the pockets
	var wood: Material = M.wood
	var q := table.mouth_corner / sqrt(2.0)
	var ms := table.mouth_side * 0.5
	var y_r := BED + table.nose_h + 0.0095
	var rw := RAIL_W + 0.015
	for sz: float in [-1.0, 1.0]:
		var zc := sz * (hw + CUSH_W + RAIL_W * 0.5)
		_rail_box(Vector3(-hl + q, y_r, zc), Vector3(-ms - 0.02, y_r, zc), rw, wood)
		_rail_box(Vector3(ms + 0.02, y_r, zc), Vector3(hl - q, y_r, zc), rw, wood)
	for sx: float in [-1.0, 1.0]:
		var xc := sx * (hl + CUSH_W + RAIL_W * 0.5)
		_rail_box(Vector3(xc, y_r, -hw + q), Vector3(xc, y_r, hw - q), rw, wood, true)
	# the corners round the pockets: the rail wrapped round each in a block, with the leather showing
	var leather = pub.mat(Color("1b1511"), 0.55, 0.0, 2, Vector3.UP, 5.0, 0.6)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := Vector3(sx * (hl + 0.1), y_r, sz * (hw + 0.1))
			var blk = pub.box(Vector3(0.17, 0.034, 0.17), c, wood, 0.0, self)
			blk.rotation.y = 0.0
	for sz: float in [-1.0, 1.0]:
		pub.box(Vector3(table.mouth_side + 0.04, 0.034, 0.1), Vector3(0, y_r, sz * (hw + CUSH_W + RAIL_W * 0.62)), wood, 0.0, self)
	# the sights: mother-of-pearl, three a side between pockets, the odd one gone
	var pearl = pub.mat(Color("ddd6c6"), 0.3, 0.0, 3)
	for i in 8:
		if i == 0 or i == 4:
			continue
		var x := -hl + table.L * i / 8.0
		for sz: float in [-1.0, 1.0]:
			if i == 6 and sz > 0.0:
				continue                # prised out, years ago: a hole
			_disc(Vector3(x, y_r + 0.0175, sz * (hw + CUSH_W + RAIL_W * 0.45)), 0.006, pearl, 8)
	for i in [1, 2, 3]:
		var z: float = -hw + table.W * i / 4.0
		for sx: float in [-1.0, 1.0]:
			_disc(Vector3(sx * (hl + CUSH_W + RAIL_W * 0.45), y_r + 0.0175, z), 0.006, pearl, 8)
	# the cabinet: a bar box's, laminate gone at the corners where the cues knock it
	var cab = pub.mat(Color("3a2a1f"), 0.6, 0.0, 2, Vector3.UP, 7.0, 0.8)
	pub.box(Vector3(outer_l - 0.06, BED - 0.16, outer_w - 0.08), Vector3(0, (BED - 0.16) * 0.5 + 0.11, 0), cab, 0.0, self)
	pub.box(Vector3(outer_l - 0.02, 0.06, outer_w - 0.04), Vector3(0, BED - 0.07, 0), wood, 0.0, self)
	# the plinth
	pub.box(Vector3(outer_l - 0.2, 0.11, outer_w - 0.22), Vector3(0, 0.055, 0), M.black, 0.0, self)
	# the coin slide at the foot, chrome gone dull, and the window over the return
	var chrome: Material = M.steel
	var foot := hl + CUSH_W + RAIL_W - 0.02
	pub.box(Vector3(0.012, 0.11, 0.26), Vector3(foot + 0.012, BED - 0.24, -0.25), chrome, 0.0, self)
	for k in 2:
		pub.box(Vector3(0.03, 0.012, 0.035), Vector3(foot + 0.03, BED - 0.24, -0.32 + k * 0.08), chrome, 0.0, self)
	pub.box(Vector3(0.05, 0.03, 0.2), Vector3(foot + 0.035, BED - 0.19, -0.25), chrome, 0.0, self)   # the slide's handle
	var lbl := Label3D.new()
	lbl.text = "2 x $1"
	lbl.font = Look.font("zilla")
	lbl.font_size = 36
	lbl.pixel_size = 0.0008
	lbl.modulate = Color("c9c3b4")
	lbl.outline_size = 0
	lbl.shaded = true
	lbl.position = Vector3(foot + 0.0195, BED - 0.29, -0.25)
	lbl.rotation.y = PI * 0.5
	add_child(lbl)
	# the return's window: a slot of scratched perspex with the pocketed balls in a row behind it
	trough = Node3D.new()
	trough.position = Vector3(foot + 0.0, BED - 0.42, 0.12)
	add_child(trough)
	pub.box(Vector3(0.02, 0.09, 0.5), Vector3(0.0, 0.0, 0.0), M.black, 0.0, trough)
	var glass = pub.glass(Color(0.8, 0.8, 0.75), 0.18)
	pub.box(Vector3(0.004, 0.07, 0.46), Vector3(0.03, 0.0, 0.0), glass, 0.0, trough)
	# the chalk: a cube, blue, worn into a dish on one face, kept on the rail
	chalk_cube = Node3D.new()
	add_child(chalk_cube)
	pub.box(Vector3(0.022, 0.022, 0.022), Vector3(0, 0.011, 0), pub.mat(Color("3b5d8a"), 0.9), 0.0, chalk_cube)
	chalk_cube.position = Vector3(hl + CUSH_W + RAIL_W * 0.5, y_r + 0.017, hw - 0.25)
	chalk_cube.rotation.y = 0.4
	marker = Node3D.new()
	marker.visible = false
	add_child(marker)
	pub.box(Vector3(0.022, 0.022, 0.022), Vector3(0, 0.011, 0), pub.mat(Color("3b5d8a"), 0.9), 0.0, marker)


func _disc(at: Vector3, r: float, m: Material, seg := 18) -> MeshInstance3D:
	var d: MeshInstance3D = pub.cyl(r, r, 0.0006, at, m, self, seg)
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return d


func _rail_box(a: Vector3, b: Vector3, w: float, m: Material, along_z := false) -> void:
	var c := (a + b) * 0.5
	var L := a.distance_to(b)
	var size := Vector3(w, 0.034, L) if along_z else Vector3(L, 0.034, w)
	pub.box(size, c, m, 0.0, self)


# A cushion along one segment: its profile, nose to the back, run from a to b. n is the sim's inward
# normal (toward the cloth): the rubber is on the other side of the nose.
func _cushion(a: Vector3, b: Vector3, n: Vector3, m: Material) -> void:
	var out := -n
	var nh := table.nose_h
	var top := nh + 0.0095
	# the profile: (out from the nose line, up from the cloth)
	var prof := [Vector2(0.0, nh), Vector2(0.011, top), Vector2(CUSH_W, top), Vector2(CUSH_W, 0.0), Vector2(0.022, 0.0), Vector2(0.004, nh - 0.012)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pa := []
	var pb := []
	for pv in prof:
		pa.append(a + out * pv.x + Vector3(0, BED + pv.y, 0))
		pb.append(b + out * pv.x + Vector3(0, BED + pv.y, 0))
	var k := prof.size()
	for i in k:
		var j := (i + 1) % k
		_quad(st, pa[i], pa[j], pb[j], pb[i])
	# the ends
	for i in range(1, k - 1):
		_tri(st, pa[0], pa[i + 1], pa[i])
		_tri(st, pb[0], pb[i], pb[i + 1])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	add_child(mi)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# both faces: the order a profile is walked in isn't to be trusted at both ends
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


# ---------------------------------------------------------------- the balls

func ball_node(id: int, r: float) -> Node3D:
	if ball_nodes.has(id):
		return ball_nodes[id]
	var n := Node3D.new()
	add_child(n)
	var m: ShaderMaterial = pub.mat(Color(1, 1, 1), 0.18, 0.0, 3, Vector3.UP, 5.0, 0.25)
	m.set_shader_parameter("albedo_tex", pub.tex("res://textures/pool/ball_%d.png" % id))
	m.set_shader_parameter("mapping", 0)
	m.set_shader_parameter("specular", 0.7)
	var mi: MeshInstance3D = pub.ball(r, Vector3.ZERO, m, n)
	(mi.mesh as SphereMesh).radial_segments = 28
	(mi.mesh as SphereMesh).rings = 16
	# a little turn of its own, so the numbers aren't all facing the same way in the rack
	n.basis = Basis.from_euler(Vector3(0.0, id * 1.37, 0.0))
	ball_nodes[id] = n
	return n


func put_ball(id: int, r: float, p: Vector3, vis := true) -> void:
	var n := ball_node(id, r)
	n.position = Vector3(p.x, BED + p.y, p.z)
	n.visible = vis


func hide_balls() -> void:
	for n in ball_nodes.values():
		(n as Node3D).visible = false


# the pocketed balls in the return's window, in the order they came down
func set_trough(ids: Array) -> void:
	for b in trough_balls:
		(b as Node3D).queue_free()
	trough_balls = []
	for i in ids.size():
		var src: Node3D = ball_nodes.get(ids[i])
		if src == null:
			continue
		var c := (src.get_child(0) as MeshInstance3D).duplicate() as MeshInstance3D
		var holder := Node3D.new()
		holder.position = Vector3(-0.005, -0.006, -0.2 + i * 0.058)
		holder.basis = Basis.from_euler(Vector3(0.3 * i, 1.0 + i, 0.0))
		trough.add_child(holder)
		holder.add_child(c)
		trough_balls.append(holder)


# the chalk cube put down on the rail by the pocket he's called; -1 takes it back
func call_pocket(k: int) -> void:
	if k < 0:
		marker.visible = false
		return
	var pk: Array = table.pockets[k]
	var mouth: Vector3 = pk[2]
	var outw := Vector3(mouth.x, 0, mouth.z)
	var dir := Vector3(signf(outw.x) if absf(outw.x) > 0.1 else 0.0, 0, signf(outw.z)).normalized()
	var at := mouth + dir * (CUSH_W + RAIL_W * 0.55) + Vector3(-signf(mouth.x) * 0.07 if absf(mouth.x) > 0.1 else 0.09, 0, 0)
	marker.position = Vector3(at.x, BED + table.nose_h + 0.027, at.z)
	marker.visible = true
