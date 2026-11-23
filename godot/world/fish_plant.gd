# The shut fish plant on the wharf, Sunday night (bible/15_FIGHTS_AND_STATS.md, section 1): the
# gutting floor, concrete with its drains, the stainless tables shoved back to the walls, the hooks
# on their rail, and five old bulbs on flex over the middle and nothing else: the dark comes right up
# to the edge of the light. The scratch line chalked across the middle of the floor. The Timekeeper
# on his herring barrel with his watch and the ledger, the widows' box at his feet; the Legion's old
# guard and the rest standing round in a ring that is the ring. Built once, out past the town where
# nothing else is, and only shown on a Sunday.
class_name FishPlant
extends Node3D

const AT := Vector3(120.0, 0.0, -160.0)
const W := 18.0
const D := 12.0
const RING := 2.1                    # half the floor the crowd leaves them
const PEOPLE := "res://models/people/"

var pub: Pub
var lights: Array = []
var built := false


func build_for(p: Pub) -> void:
	pub = p
	position = AT
	visible = false


func ensure() -> void:
	if built:
		return
	built = true
	var M: Dictionary = pub.M
	var rng := RandomNumberGenerator.new()
	rng.seed = 1854
	# the floor, and the drains running down the middle of each half toward the sea end
	pub.tiled(Vector3(W, 0.1, D), Vector3(0, -0.05, 0), M.concrete, 2.5, self)
	for z in [-3.5, 3.5]:
		pub.box(Vector3(W - 1.0, 0.012, 0.22), Vector3(0, 0.004, z), M.black, 0.0, self)
		for x in range(-8, 9, 2):
			pub.box(Vector3(0.18, 0.014, 0.2), Vector3(x, 0.006, z), M.steel, 0.0, self)
	# old stains, fish scale and blood a long time gone
	for i in 14:
		pub.box(Vector3(rng.randf_range(0.4, 1.6), 0.006, rng.randf_range(0.3, 1.0)), Vector3(rng.randf_range(-8, 8), 0.003, rng.randf_range(-5.5, 5.5)), M.puddle, rng.randf_range(-40.0, 40.0), self)
	# the walls, the roof and its trusses, all lost in the dark past the bulbs
	for side in [-1.0, 1.0]:
		pub.box(Vector3(W, 6.0, 0.2), Vector3(0, 3.0, side * D * 0.5), M.siding, 0.0, self)
		pub.box(Vector3(0.2, 6.0, D), Vector3(side * W * 0.5, 3.0, 0), M.siding, 0.0, self)
	pub.box(Vector3(W, 0.2, D), Vector3(0, 6.1, 0), M.dark, 0.0, self)
	for x in range(-8, 9, 4):
		pub.box(Vector3(0.18, 0.4, D), Vector3(x, 5.6, 0), M.wood, 0.0, self)
		for side in [-1.0, 1.0]:
			pub.box(Vector3(0.22, 5.6, 0.22), Vector3(x, 2.8, side * (D * 0.5 - 0.6)), M.steel, 0.0, self)
	# the gutting tables pushed back to the long walls, and the hook rail over them
	for side in [-1.0, 1.0]:
		for x in [-6.5, -3.0, 3.5, 6.8]:
			var tx: float = x + rng.randf_range(-0.3, 0.3)
			var z: float = side * (D * 0.5 - 1.4)
			pub.box(Vector3(2.4, 0.06, 0.9), Vector3(tx, 0.9, z), M.steel, rng.randf_range(-4.0, 4.0), self)
			for lx in [-1.1, 1.1]:
				for lz in [-0.4, 0.4]:
					pub.box(Vector3(0.05, 0.9, 0.05), Vector3(tx + lx, 0.45, z + lz), M.steel, 0.0, self)
		pub.box(Vector3(W - 2.0, 0.06, 0.06), Vector3(0, 3.2, side * (D * 0.5 - 1.4)), M.steel, 0.0, self)
		for i in 9:
			var hx := -7.5 + i * 1.9 + rng.randf_range(-0.2, 0.2)
			pub.box(Vector3(0.015, 0.5, 0.015), Vector3(hx, 2.95, side * (D * 0.5 - 1.4)), M.steel, 0.0, self)
	# the bulbs: five on their flex over the middle, old filament ones, low and warm, and nothing else
	for p in [Vector3(0, 3.1, 0), Vector3(-1.6, 3.3, -1.2), Vector3(1.7, 3.2, 1.0), Vector3(-1.4, 3.4, 1.5), Vector3(1.5, 3.35, -1.6)]:
		pub.box(Vector3(0.01, 6.0 - p.y, 0.01), Vector3(p.x, (6.0 + p.y) * 0.5, p.z), M.black, 0.0, self)
		pub.ball(0.045, p, M.bulb, self)
		var l: OmniLight3D = pub.omni(to_global(p), Color(1.0, 0.72, 0.42), 1.1 if p.x == 0 else 0.55, 6.5, p.x == 0)
		l.reparent(self)
		lights.append(l)
	# the scratch line, chalked across the floor, scuffed
	for i in 7:
		pub.box(Vector3(0.24 + rng.randf_range(-0.05, 0.05), 0.004, 0.035), Vector3(-0.75 + i * 0.25, 0.008, rng.randf_range(-0.01, 0.01)), M.paper, rng.randf_range(-6.0, 6.0), self)
	# the Timekeeper's barrel, the ledger on a fish box beside it, the widows' box at his feet
	var tk := Vector3(-RING - 0.9, 0, -RING - 0.4)
	pub.cyl(0.3, 0.27, 0.72, tk + Vector3(0, 0.36, 0), M.wood, self, 16)
	pub.box(Vector3(0.6, 0.4, 0.42), tk + Vector3(0.75, 0.2, 0.1), M.wood, 12.0, self)
	pub.box(Vector3(0.3, 0.035, 0.22), tk + Vector3(0.75, 0.42, 0.1), M.leather, 12.0, self)
	pub.box(Vector3(0.22, 0.16, 0.16), tk + Vector3(-0.1, 0.08, 0.42), M.brass, -10.0, self)
	var keeper: Node3D = pub.model(PEOPLE + "endbar.glb", tk + Vector3(0, 0.08, 0), self)
	keeper.look_at(to_global(Vector3(0, keeper.position.y, 0)), Vector3.UP, true)
	# the ring they stand round: the old guard nearest the line, the club's book further back
	var who := ["vape_door", "goodshoes_card", "essokid_freezer", "cook", "vape", "goodshoes_card", "vape_door", "cook", "essokid_freezer", "vape"]
	for i in who.size():
		var a := TAU * float(i) / who.size() + rng.randf_range(-0.12, 0.12)
		var r := RING + 0.55 + rng.randf_range(0.0, 0.5)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if p.distance_to(tk) < 1.3:
			continue
		if not FileAccess.file_exists(PEOPLE + who[i] + ".glb"):
			continue
		var n: Node3D = pub.model(PEOPLE + who[i] + ".glb", p, self)
		n.look_at(to_global(Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))), Vector3.UP, true)
	# a sign nobody took down
	var sign := Label3D.new()
	sign.text = "THE FRIENDLY\nWIDOWS' BOX\nEST. 1854"
	sign.font = Look.font("display")
	sign.font_size = 64
	sign.pixel_size = 0.004
	sign.modulate = Color(0.85, 0.8, 0.7)
	sign.position = Vector3(-W * 0.5 + 0.12, 2.0, -2.0)
	sign.rotation.y = PI * 0.5
	add_child(sign)


func show_now(on: bool) -> void:
	if on:
		ensure()
	visible = on
	for l in lights:
		(l as Light3D).visible = on


# the sim's floor to the world: the middle of the gutting floor, the line across it
func frame() -> Transform3D:
	return Transform3D(Basis.IDENTITY, AT)
