# The darts, worked out a thousand steps a second (game/darts.gd throws them and plays them back).
# Not the physics engine: a dart is a rigid body made of its parts, and everything it meets is
# written out here, so the same throw comes down the same way every time and nothing about it is
# rounded off into a number the player can't see.
#
# A dart, from the point back: a steel point, a brass barrel that carries nearly all its weight, a
# nylon shaft, and two flights crossed on the end of it. Its weight sits well forward and the air
# pushes on it well back, at the flights, so in the air it turns to fly point first, overshoots,
# and swings back, a little less each time (the air on the flights is worked out where each flight
# is, with the dart's turning in it, so the damping is there without being put there). It spins
# slowly about its own length from the fingers. A bent shaft holds the flights a few degrees off
# the dart's line, and a torn flight pushes harder on one side than the other: both turn with the
# spin, so a bad dart corkscrews rather than simply pulling one way.
#
# What it meets, in the board's own frame (the bull's middle on the face of the board, +Z out of
# the board toward the oche, +Y up, +X to the thrower's right):
# - the spider: round steel wire laid on the sisal, the six rings and the twenty spokes. The point
#   is a small steel ball on the end of the dart against a steel cylinder: where it lands across
#   the wire, how steep it's coming in and how much the dart weighs and how fast it's going decide
#   between sliding off into the bed beside it and coming straight back out (the bounce-out).
# - the sisal: the point goes in if it's coming in along its own length, against the fibres'
#   grip (a push to part them, and more the deeper it goes). Once in, the point is held across
#   and the dart swings on it, sags a little, and stays; or, where the board's worn soft or it only
#   went in a few millimetres, the dart's own weight levers it out and it drops.
# - the number ring, a heavier wire round the outside, which nothing sticks in.
# - the cabinet's wood round the board, its doors open flat against the wall, and the wall's
#   plaster past that.
# - the other darts already in the board: the barrels and shafts (brass and nylon), and their
#   flights, which a point goes through and tears. Straight down the back of a shaft, it sticks in
#   it.
# - the carpet under the board, where a dart that's fallen bounces, slides and lies.
#
# Everything here is about the darts. Who threw it, how his hand shook, how much he'd had: that
# all comes in as the state the dart leaves his fingers in (game/darts.gd).
class_name DartSim
extends RefCounted

const HZ := 1000.0
const DT := 1.0 / HZ
const KEEP := 5                         # a frame kept every this many steps (200 a second)
const FPS := HZ / KEEP
const GRAV := Vector3(0.0, -9.81, 0.0)
const RHO := 1.2                        # the room's air (warm, damp, a little smoke in it)
const MAX_T := 6.0

# the board, in metres, from the middle out (the regulation board: wire to wire)
const R_BULL := 0.00635
const R_OUTER_BULL := 0.0159
const R_TREBLE_IN := 0.099
const R_TREBLE_OUT := 0.107
const R_DOUBLE_IN := 0.162
const R_DOUBLE_OUT := 0.170
const R_NUMBERS := 0.190                # the number ring's wire
const R_BOARD := 0.2255                 # the edge of the sisal
const RINGS := [R_BULL, R_OUTER_BULL, R_TREBLE_IN, R_TREBLE_OUT, R_DOUBLE_IN, R_DOUBLE_OUT]
const ORDER := [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
const WIRE_R := 0.0006                  # round wire, 1.2 mm
const WIRE_Z := 0.0004                  # its middle off the sisal (pressed in a little)
const NUM_R := 0.0011                   # the number ring's heavier wire
const BOARD_T := 0.038                  # the board's thickness: the cabinet's back is behind it
const CAB := Vector2(0.32, 0.32)        # half the cabinet's back, across and up
const DOORS := 0.64                     # the open doors flat to the wall either side, out to here
const WALL_Z := -0.058                  # the wall's plaster, behind the cabinet
const FLOOR_Y := -1.73                  # the carpet, under the bull

# what things are made of: [the push to part it (N), how much more each metre deeper (N/m), how
# much it holds the dart against being levered out per metre it's in (N m / m), its spring against
# the dart swinging per metre in (N m / rad / m), steepest it'll take a point (cos of the angle off
# straight in), bounce, grip]
const STUFF := {
	"sisal": [14.0, 9000.0, 4.2, 22.0, 0.26, 0.15, 0.6],
	"wood": [70.0, 52000.0, 2.6, 30.0, 0.55, 0.32, 0.35],
	"shaft": [16.0, 9000.0, 1.6, 10.0, 0.95, 0.3, 0.3],
	"plaster": [400.0, 400000.0, 1.0, 20.0, 1.1, 0.25, 0.4],
}

# ---------------------------------------------------------------- one dart

# The house darts and anything else he might throw: the parts from the point back [from, to (m from
# the point), radius, mass (kg)], where the flights sit, how big they are, and what's wrong with it.
class Dart:
	var name := "house"
	var parts: Array = []               # [s0, s1, r, m]
	var flight_s := 0.122               # the flights' middle, from the point
	var flight_len := 0.036
	var flight_area := 0.00070          # one flight's face, each side of the shaft together
	var bend := Vector3.ZERO            # the shaft's bend: the flights' axis off the dart's line, in its own frame (small)
	var tear := 0.0                     # how torn its flights are, 0 to 1
	var tear_dir := Vector3(1, 0, 0)    # which side's torn, in its own frame
	var tip_r := 0.0003                 # the point's end: worn blunt is wider
	var mass := 0.0
	var cg := 0.0                       # the balance point, from the point
	var i_t := 0.0                      # turning end over end about its balance
	var i_a := 0.0                      # spinning about its length
	var length := 0.0

	func _init(barrel_g := 18.0, barrel_len := 0.046, barrel_r := 0.0036) -> void:
		var p0 := 0.032
		parts = [
			[0.0, p0, 0.00115, 0.0010],                                  # the point
			[p0, p0 + barrel_len, barrel_r, barrel_g / 1000.0],          # the barrel
			[p0 + barrel_len, p0 + barrel_len + 0.040, 0.0018, 0.0008],  # the shaft
			[flight_s - flight_len * 0.5, flight_s + flight_len * 0.5, 0.0005, 0.0004],  # the flights
		]
		flight_s = p0 + barrel_len + 0.044
		parts[3] = [flight_s - flight_len * 0.5, flight_s + flight_len * 0.5, 0.0005, 0.0004]
		weigh()

	func weigh() -> void:
		mass = 0.0
		var sm := 0.0
		length = 0.0
		for p in parts:
			mass += p[3]
			sm += p[3] * (p[0] + p[1]) * 0.5
			length = max(length, p[1])
		cg = sm / mass
		i_t = 0.0
		i_a = 0.0
		for p in parts:
			var l: float = p[1] - p[0]
			var d: float = (p[0] + p[1]) * 0.5 - cg
			i_t += p[3] * (l * l / 12.0 + p[2] * p[2] / 4.0 + d * d)
			i_a += p[3] * p[2] * p[2] / 2.0
		# the flights stand out from the shaft: they spin with some reach
		i_a += parts[3][3] * 0.013 * 0.013 * 0.5

	# a point on its line, s from the point, in its own frame (+Z is toward the point; the middle is its balance)
	func at(s: float) -> Vector3:
		return Vector3(0, 0, cg - s)


# The state of one dart in the sim.
class Body:
	var d: Dart
	var pos := Vector3.ZERO             # its balance point
	var vel := Vector3.ZERO
	var rot := Basis.IDENTITY           # +Z toward the point
	var spin := Vector3.ZERO            # in the room, rad/s
	var mode := "fly"                   # fly, in (stuck in something), lie (still on the carpet), hand
	# stuck: what in, where the point went in, which way, how deep, how fast it's still going in, and
	# how it lay when it went in
	var in_what := ""
	var in_at := Vector3.ZERO
	var in_dir := Vector3.ZERO
	var depth := 0.0
	var dv := 0.0
	var in_rot := Basis.IDENTITY
	var still := 0.0
	var frames: Array = []
	var tore := 0.0                     # torn flight it took from other darts tonight
	var crossed = null                  # where its point first came through the board's face (Vector3), whatever happened after

	func tip() -> Vector3:
		return pos + rot * d.at(0.0)

	func tail() -> Vector3:
		return pos + rot * d.at(d.length)

	func axis() -> Vector3:
		return rot.z

	func r_of(s: float) -> Vector3:
		return rot * d.at(s)


var bodies: Array = []                  # Body
var t := 0.0
var hits: Array = []                    # [time, dart, what, speed, where (board frame)]
var tilt := 0.0                         # how crooked the board hangs, radians, clockwise as he sees it
var wear_seed := 7
var wear_spots: Array = []              # [Vector2 where, radius, how soft] soft patches in the sisal
var done := false
var _n := 0


func _init() -> void:
	# the board's been thrown at for twenty years, and mostly at the top: the 20's bed chewed out and
	# the treble 20 near gone, the 19 and the 1 either side of it worn, and here and there a patch the
	# fibres have come loose in
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.seed = wear_seed
	wear_spots = [
		[Vector2(0.0, 0.103), 0.018, 0.42],          # treble 20
		[Vector2(0.0, 0.135), 0.03, 0.22],           # the big 20 bed
		[Vector2(0.0, 0.166), 0.012, 0.3],           # double 20
		[Vector2(-0.032, 0.098), 0.012, 0.3],        # treble 5
		[Vector2(0.032, 0.098), 0.012, 0.3],         # treble 1
		[Vector2(-0.032, -0.098), 0.014, 0.35],      # treble 19
		[Vector2(0.0, 0.0), 0.012, 0.2],             # the bull
	]
	for k in 9:
		var a := seed_rng.randf() * TAU
		var r := seed_rng.randf_range(0.02, 0.2)
		wear_spots.append([Vector2(cos(a), sin(a)) * r, seed_rng.randf_range(0.004, 0.009), seed_rng.randf_range(0.2, 0.5)])


# How sound the sisal is here, 1 new to near nothing.
func soundness(p: Vector2) -> float:
	var s := 1.0
	for w in wear_spots:
		var dd := p.distance_to(w[0])
		var rr: float = w[1]
		if dd < rr * 2.0:
			s *= 1.0 - float(w[2]) * exp(-(dd * dd) / (rr * rr))
	return clampf(s, 0.12, 1.0)


func add(d: Dart) -> Body:
	var b := Body.new()
	b.d = d
	b.mode = "hand"
	bodies.append(b)
	return b


# Throw one: where its balance point leaves his fingers, how fast, how it's turned, and how it's
# turning. The others stay as they are (in the board, on the carpet, in his hand).
func throw(b: Body, at: Vector3, v: Vector3, r: Basis, w: Vector3) -> void:
	b.pos = at
	b.vel = v
	b.rot = r.orthonormalized()
	b.spin = w
	b.mode = "fly"
	b.still = 0.0
	b.crossed = null
	for o in bodies:
		o.frames = [[o.pos, Quaternion(o.rot)]]
	hits = []
	t = 0.0
	_n = 0
	done = false


func run(steps: int = 1 << 30) -> void:
	while steps > 0 and not done:
		step()
		steps -= 1


func step() -> void:
	for b in bodies:
		match b.mode:
			"fly": _fly(b)
			"in": _in(b)
	t += DT
	_n += 1
	var moving := false
	for b2 in bodies:
		if b2.mode == "fly" or (b2.mode == "in" and b2.still < 0.25):
			moving = true
	if not moving or t >= MAX_T:
		done = true
	if _n % KEEP == 0 or done:
		for b3 in bodies:
			b3.frames.append([b3.pos, Quaternion(b3.rot)])


# ---------------------------------------------------------------- in the air

# the air on it: the crossflow on the barrel, the flights' lift and drag across, and the drag
# along it
func _air(b: Body) -> Array:
	var d: Dart = b.d
	var f := Vector3.ZERO
	var tq := Vector3.ZERO
	var a := b.axis()
	# the flights: two plates crossed on the shaft's end, their axis bent off the dart's if the
	# shaft is
	var fa: Vector3 = (b.rot * (Vector3(0, 0, 1) + d.bend)).normalized()
	var rf := b.r_of(d.flight_s)
	var vf: Vector3 = b.vel + b.spin.cross(rf)
	var spd := vf.length()
	if spd > 0.01:
		var area := d.flight_area * (1.0 - 0.35 * d.tear)
		for n0 in [b.rot.x, b.rot.y]:
			var n: Vector3 = (n0 - fa * fa.dot(n0)).normalized()
			var vn := vf.dot(n)
			# lift across the plate, linear while it's small (a low, stubby wing), and the plate's
			# drag once it's well across the air
			var fn := -0.5 * RHO * area * (1.15 * spd * vn + 1.2 * absf(vn) * vn)
			f += n * fn
			tq += rf.cross(n * fn)
		# the torn side pushes harder (and turns with the dart)
		if d.tear > 0.0:
			var td: Vector3 = b.rot * d.tear_dir
			var ft := td * (0.5 * RHO * spd * spd * d.flight_area * 0.04 * d.tear)
			f += ft
			tq += rf.cross(ft)
		# drag along: the flights' faces edge on, and their spin
		var drag_a := -vf.normalized() * (0.5 * RHO * spd * spd * (0.000034 + 0.00004 * d.tear))
		f += drag_a
		tq += rf.cross(drag_a)
		# the flights resist the spin
		tq += -a * a.dot(b.spin) * 0.0000006 * spd
	# the barrel and the point, side on, a little forward of the balance
	var rb := b.r_of(d.cg - 0.008)
	var vb: Vector3 = b.vel + b.spin.cross(rb)
	var vba := vb - a * a.dot(vb)
	var side := -vba * vba.length() * (0.5 * RHO * 1.2 * 0.00034)
	f += side
	tq += rb.cross(side)
	# the barrel's front
	var vax := a.dot(b.vel)
	f += -a * vax * absf(vax) * (0.5 * RHO * 0.8 * PI * 0.0036 * 0.0036)
	return [f, tq]


func _fly(b: Body) -> void:
	# near anything it can hit, in steps short enough that the point can't jump a wire (6 m/s is 6 mm
	# a step; the wire's 1.2 mm across): a third of a millimetre at a time
	var tp := b.tip()
	var near := (tp.z < 0.04 and tp.z > WALL_Z - 0.03) or tp.y < FLOOR_Y + 0.16
	if not near:
		for o in bodies:
			if o != b and o.mode != "hand" and o.pos.distance_to(b.pos) < b.d.length + o.d.length + 0.02:
				near = true
	var n := 1
	if near:
		n = clampi(int(ceil((b.vel.length() + b.spin.length() * 0.09) * DT / 0.0003)), 1, 40)
	var h := DT / n
	for i in n:
		_fly_h(b, h)
		if b.mode != "fly":
			return


func _fly_h(b: Body, h: float) -> void:
	var d: Dart = b.d
	var ft := _air(b)
	var f: Vector3 = ft[0] + GRAV * d.mass
	var tq: Vector3 = ft[1]
	b.vel += f / d.mass * h
	# turning: in its own frame, with the spin's own push on itself (a slow spinning dart's a weak gyro)
	var wb: Vector3 = b.rot.transposed() * b.spin
	var tb: Vector3 = b.rot.transposed() * tq
	var iv := Vector3(d.i_t, d.i_t, d.i_a)
	var lb := wb * iv
	var dw := (tb - wb.cross(lb)) / iv
	wb += dw * h
	b.spin = b.rot * wb
	var z0 := b.tip().z
	b.pos += b.vel * h
	var wl := b.spin.length()
	if wl > 0.000001:
		b.rot = (Basis(b.spin / wl, wl * h) * b.rot).orthonormalized()
	if b.crossed == null:
		var tp := b.tip()
		if tp.z <= 0.0015 and z0 > 0.0015:
			b.crossed = tp
	_touch(b, h)


# ---------------------------------------------------------------- what it meets

func _touch(b: Body, h := DT) -> void:
	var tp := b.tip()
	var tl := b.tail()
	# the board's face and the spider on it
	if tp.z < WIRE_Z + WIRE_R + b.d.tip_r + 0.0005 and tp.z > -BOARD_T:
		var q := Vector2(tp.x, tp.y)
		var r := q.length()
		if r < R_BOARD:
			if _wire(b, tp):
				return
			if r > R_NUMBERS - 0.004 and r < R_NUMBERS + 0.004 and _ring(b, tp, R_NUMBERS, NUM_R, NUM_R):
				return
			if tp.z < 0.0:
				_go_in(b, "sisal", tp)
				if b.mode == "fly" and b.tip().z < 0.0:
					b.pos.z -= b.tip().z
				return
	# the other darts
	for o in bodies:
		if o == b or o.mode == "hand":
			continue
		if o.mode == "fly" and bodies.find(o) < bodies.find(b):
			continue
		if _darts(b, o):
			return
	# the cabinet's back round the board, the doors flat to the wall, and the wall
	var back := -BOARD_T
	var wood := absf(tp.x) < CAB.x and absf(tp.y) < CAB.y
	var doors := absf(tp.x) < DOORS and absf(tp.y) < CAB.y
	var tz := back if wood else (-0.02 if doors else WALL_Z)
	if Vector2(tp.x, tp.y).length() > R_BOARD or tp.z < -BOARD_T:
		if tp.z < tz:
			var what := "wood" if (wood or doors) else "plaster"
			_go_in(b, what, tp, Vector3(0, 0, 1), tz)
			if b.mode == "fly":
				b.pos.z += tz - b.tip().z if b.tip().z < tz else 0.0
			return
		if tl.z < tz:
			b.pos.z += tz - tl.z
			_bump(b, tl, Vector3(0, 0, 1), 0.3, 0.4, "wood" if (wood or doors) else "plaster")
	# the carpet
	if tp.y < FLOOR_Y or tl.y < FLOOR_Y:
		_carpet(b, tp, tl, h)


# The spider: the nearest wire under the point, the rings and the spokes.
func _wire(b: Body, tp: Vector3) -> bool:
	var q := Vector2(tp.x, tp.y)
	var r := q.length()
	var reach := WIRE_R + b.d.tip_r + 0.0006
	for rr in RINGS:
		if absf(r - rr) < reach:
			if _ring(b, tp, rr, WIRE_R, WIRE_Z):
				return true
	if r > R_OUTER_BULL - reach and r < R_DOUBLE_OUT + reach:
		# the spokes are where the beds meet: 9 degrees either side of each number's middle
		var ang := atan2(q.x, q.y) - tilt        # from straight up, clockwise
		var k := roundf((ang - deg_to_rad(9.0)) / deg_to_rad(18.0))
		var sa := deg_to_rad(9.0) + k * deg_to_rad(18.0) + tilt
		var dirv := Vector2(sin(sa), cos(sa))
		var nrm := Vector2(dirv.y, -dirv.x)
		var off := q.dot(nrm)
		var along := q.dot(dirv)
		if absf(off) < reach and along > R_OUTER_BULL and along < R_DOUBLE_OUT:
			var c := Vector3(dirv.x * along, dirv.y * along, WIRE_Z)
			return _steel(b, tp, c, Vector3(dirv.x, dirv.y, 0.0), WIRE_R)
	return false


func _ring(b: Body, tp: Vector3, rr: float, wr: float, wz: float) -> bool:
	var q := Vector2(tp.x, tp.y)
	var r := q.length()
	if r < 0.00001:
		return false
	var u := q / r
	var c := Vector3(u.x * rr, u.y * rr, wz)
	return _steel(b, tp, c, Vector3(-u.y, u.x, 0.0), wr)


# The point against a round steel wire (its nearest point c, running along dirv). The point isn't a
# ball: it's a cone, sharp at the end and widening back at about ten degrees, so where it lands on
# the wire's shoulder its flank meets the wire and the push is mostly sideways, off into the bed
# beside it. Only landing near the crest does the push come straight back up the dart. Steel on
# steel: a little bounce, not much grip.
const CONE := 0.18                      # tan of the point's half-angle
const CONE_LEN := 0.010                 # how much of the point's taper can touch a wire

func _steel(b: Body, tp: Vector3, c: Vector3, dirv: Vector3, wr: float) -> bool:
	var a := b.axis()
	var deepest := 0.0
	var at_s := -1.0
	var n := Vector3.ZERO
	for i in 9:
		var sd := CONE_LEN * float(i * i) / 64.0
		var p := tp - a * sd
		var rel := p - c
		rel -= dirv * dirv.dot(rel)
		var dist := rel.length()
		var into := wr + b.d.tip_r + sd * CONE - dist
		if into > deepest and dist > 0.000001:
			deepest = into
			at_s = sd
			# the cone's flank, not its axis, is what's touching: tip the normal back toward the
			# dart's line by the taper
			var radial := rel / dist
			n = (radial - a * radial.dot(a) * 0.0).normalized()
	if at_s < 0.0:
		return false
	# the cone's surface normal at the touch: the radial direction, leaned back along the dart by the
	# taper (a flank at ten degrees off the axis faces mostly sideways)
	var side := n - a * n.dot(a)
	if side.length() > 0.0001:
		side = side.normalized()
		var flank := (side - a * CONE).normalized()
		# the normal is whichever of the wire's radial and the cone's flank is nearer the crest: both
		# bodies are round, so it's the line between their surfaces; take the blend
		n = (n + flank * (at_s / CONE_LEN)).normalized()
	b.pos += n * deepest
	var r := b.r_of(at_s)
	var vp: Vector3 = b.vel + b.spin.cross(r)
	var vn := vp.dot(n)
	if vn < 0.0:
		# hardly any bounce: the wire's stapled into the sisal and gives, and the point's sharp enough
		# to bite it; what the dart keeps is the slide along it, off into the bed beside
		_impulse(b, r, n, vn, vp, 0.12, 0.12)
		_heard(b, "wire", -vn, tp)
	return true


# A push at r (from its balance) along n, to take the speed vn off it with this much bounce, and
# friction against the slide.
func _impulse(b: Body, r: Vector3, n: Vector3, vn: float, vp: Vector3, e: float, mu: float) -> void:
	var d: Dart = b.d
	var k := _k(b, r, n)
	var jn := -(1.0 + e) * vn / k
	var vt := vp - n * vn
	var jt := Vector3.ZERO
	var vtl := vt.length()
	if vtl > 0.00001:
		var tdir := vt / vtl
		var kt := _k(b, r, tdir)
		jt = -tdir * minf(vtl / kt, mu * jn)
	var j := n * jn + jt
	b.vel += j / d.mass
	b.spin += _inv_i(b, r.cross(j))


func _inv_i(b: Body, tq: Vector3) -> Vector3:
	var tb: Vector3 = b.rot.transposed() * tq
	return b.rot * (tb / Vector3(b.d.i_t, b.d.i_t, b.d.i_a))


# how hard it is to move the point at r along n (one over the mass it feels like there)
func _k(b: Body, r: Vector3, n: Vector3) -> float:
	return 1.0 / b.d.mass + n.dot(_inv_i(b, r.cross(n)).cross(r))


func _bump(b: Body, p: Vector3, n: Vector3, e: float, mu: float, what: String) -> void:
	var r := p - b.pos
	var vp: Vector3 = b.vel + b.spin.cross(r)
	var vn := vp.dot(n)
	if vn < 0.0:
		_impulse(b, r, n, vn, vp, e, mu)
		_heard(b, what, -vn, p)


# The point into something soft enough to take it, if it's coming in along its own length; if not,
# it skates or slaps and comes off.
func _go_in(b: Body, what: String, tp: Vector3, face := Vector3(0, 0, 1), face_z := 0.0) -> void:
	var st: Array = STUFF[what]
	var a := b.axis()
	var r := b.r_of(0.0)
	var vp: Vector3 = b.vel + b.spin.cross(r)
	var spd := vp.length()
	var along := a.dot(vp)
	var c_face := -a.dot(face)             # how square the dart is to the face
	var c_way := along / maxf(spd, 0.0001) # how much the point's going where it points
	if c_face > float(st[4]) and c_way > 0.25 and along > 0.45:
		var sound := soundness(Vector2(tp.x, tp.y)) if what == "sisal" else 1.0
		# the fibres take the point across: the dart swings on it
		var lat := vp - a * along
		if lat.length() > 0.00001:
			var n := -lat.normalized()
			var k := _k(b, r, n)
			var j := n * lat.length() / k
			b.vel += j / b.d.mass
			b.spin += _inv_i(b, r.cross(j))
		b.mode = "in"
		b.in_what = what
		b.in_dir = a
		# where the point broke the surface, back along its line, and how far it's in already
		b.in_at = tp - a * ((tp.z - face_z) / minf(a.z, -0.2))
		b.depth = maxf(0.0, (tp - b.in_at).dot(a))
		b.dv = a.dot(b.vel + b.spin.cross(r))
		b.in_rot = b.rot
		b.still = 0.0
		b.set_meta("sound", sound)
		_heard(b, what, along, tp)
	else:
		if OS.has_environment("DART_WHY"):
			print("  no go in %s: face %.2f way %.2f along %.2f" % [what, c_face, c_way, along])
		_bump(b, tp, face, float(st[5]), float(st[6]), what)


# Stuck in something: the point held across, going in along its line against the grip until it
# stops, and the dart swinging on it, sprung by the fibres and pulled down by its own weight. If
# what's holding it can't, it comes out.
func _in(b: Body) -> void:
	var d: Dart = b.d
	var st: Array = STUFF[b.in_what]
	var sound: float = b.get_meta("sound", 1.0)
	# going in
	if b.dv > 0.0:
		# loose fibres part easier, and hold far worse than they part
		var push := (float(st[0]) + float(st[1]) * b.depth) * sqrt(sound)
		push -= GRAV.dot(b.in_dir) * d.mass
		b.dv -= push / d.mass * DT
		if b.dv < 0.0:
			b.dv = 0.0
		b.depth += b.dv * DT
	var tip := b.in_at + b.in_dir * b.depth
	# swinging on the point
	var r := b.r_of(0.0)                   # balance to point
	var rc := -r                           # point to balance
	var ip := _i_about(b, rc)
	var tq := rc.cross(GRAV * d.mass)
	# the fibres' spring, and their drag on it
	var turned := (b.in_rot.z.cross(b.rot.z))
	var k_turn := float(st[3]) * b.depth * sound
	tq += -turned * k_turn
	var hold := float(st[2]) * b.depth * pow(sound, 1.6)
	var pull := rc.cross(GRAV * d.mass).length()
	# the fibres' drag, worked implicitly (the dart spins about its own length with almost no weight
	# to it, so drag added the plain way would overshoot and run away)
	var c := 0.3 * b.depth * sound + 0.0000004
	var lhs := Basis(ip.x + Vector3(c * DT, 0, 0), ip.y + Vector3(0, c * DT, 0), ip.z + Vector3(0, 0, c * DT))
	b.spin = lhs.inverse() * (ip * b.spin + tq * DT)
	var wl := b.spin.length()
	if wl > 0.000001:
		b.rot = (Basis(b.spin / wl, wl * DT) * b.rot).orthonormalized()
	b.pos = tip - b.rot * d.at(0.0)
	b.vel = b.in_dir * b.dv + b.spin.cross(b.pos - tip)
	if b.dv <= 0.0 and wl < 0.05:
		b.still += DT
	else:
		b.still = 0.0
	# levered out by its own weight (or knocked), or never really in
	var spring_load := turned.length() * k_turn
	if (b.dv <= 0.0 and (pull > hold or spring_load > hold * 1.6)) or (b.dv <= 0.0 and b.depth < 0.0012):
		if OS.has_environment("DART_WHY"):
			print("  out of %s: depth %.1f mm, sound %.2f, pull %.4f hold %.4f spring %.4f" % [b.in_what, b.depth * 1000, sound, pull, hold, spring_load])
		b.mode = "fly"
		b.pos += -b.in_dir * (b.depth + 0.001)
		b.vel = -b.in_dir * 0.05
		b.spin *= 0.5
		_heard(b, "out", 0.1, tip)


# its weight about the point: its own turning plus its mass out at the balance
func _i_about(b: Body, rc: Vector3) -> Basis:
	var d: Dart = b.d
	var ib := Basis(b.rot.x * d.i_t, b.rot.y * d.i_t, b.rot.z * d.i_a) * b.rot.transposed()
	var rr := rc.dot(rc)
	var par := Basis(Vector3(rr - rc.x * rc.x, -rc.y * rc.x, -rc.z * rc.x),
		Vector3(-rc.x * rc.y, rr - rc.y * rc.y, -rc.z * rc.y),
		Vector3(-rc.x * rc.z, -rc.y * rc.z, rr - rc.z * rc.z)) * d.mass
	return Basis(ib.x + par.x, ib.y + par.y, ib.z + par.z)


# One dart against another: this one's point and barrel against the other's barrel, shaft and
# flights.
func _darts(b: Body, o: Body) -> bool:
	if b.pos.distance_to(o.pos) > b.d.length + o.d.length:
		return false
	var tp := b.tip()
	var oa := o.axis()
	var ot := o.tip()
	# Robin Hood: straight down the back of its shaft
	var back := o.pos + o.rot * o.d.at(o.d.parts[2][1])
	if o.mode == "in" and tp.distance_to(back) < 0.0016 and b.axis().dot(oa) > 0.94:
		b.mode = "in"
		b.in_what = "shaft"
		b.in_dir = b.axis()
		b.in_at = tp
		b.depth = 0.0
		b.dv = b.axis().dot(b.vel)
		b.in_rot = b.rot
		b.set_meta("sound", 1.0)
		_heard(b, "robin", b.dv, tp)
		return true
	# its flights: the point goes through them, and tears them
	var fs := o.d.flight_s
	var fc := o.pos + o.r_of(fs)
	var rel := tp - fc
	if absf(rel.dot(oa)) < o.d.flight_len * 0.5 and (rel - oa * rel.dot(oa)).length() < 0.013 \
			and (absf(rel.dot(o.rot.x)) < 0.0012 or absf(rel.dot(o.rot.y)) < 0.0012):
		if not b.has_meta("through_%d" % bodies.find(o)):
			b.set_meta("through_%d" % bodies.find(o), true)
			o.d.tear = minf(1.0, o.d.tear + 0.25)
			o.tore += 0.25
			b.vel *= 0.985
			_heard(b, "flight", b.vel.length(), tp)
	# the barrels and shafts: segment against segment
	var segs_o := [[0.032, o.d.parts[1][1], o.d.parts[1][2], "barrel"], [o.d.parts[2][0], o.d.parts[2][1], o.d.parts[2][2], "shaft"]]
	var segs_b := [[0.0, 0.032, b.d.tip_r, "point"], [0.032, b.d.parts[1][1], b.d.parts[1][2], "barrel"]]
	for sb in segs_b:
		var a0 := b.pos + b.r_of(sb[0])
		var a1 := b.pos + b.r_of(sb[1])
		for so in segs_o:
			var c0 := o.pos + o.r_of(so[0])
			var c1 := o.pos + o.r_of(so[1])
			var cp := _closest(a0, a1, c0, c1)
			var pa: Vector3 = cp[0]
			var pb: Vector3 = cp[1]
			var dd := pa.distance_to(pb)
			var lim: float = float(sb[2]) + float(so[2])
			if dd < lim and dd > 0.000001:
				var n := (pa - pb) / dd
				b.pos += n * (lim - dd)
				var r := pa - b.pos
				var vp: Vector3 = b.vel + b.spin.cross(r)
				var ro := pb - o.pos
				var vo: Vector3 = o.vel + o.spin.cross(ro)
				var vn := (vp - vo).dot(n)
				if vn < 0.0:
					# both move: the one hit swings on its point if it's in the board
					var k := _k(b, r, n) + _k_hit(o, pb, n)
					var j := -(1.0 + 0.35) * vn / k
					b.vel += n * j / b.d.mass
					b.spin += _inv_i(b, r.cross(n * j))
					_shove(o, pb, -n * j)
					_heard(b, "dart", -vn, pa)
				return true
	return false


func _k_hit(o: Body, p: Vector3, n: Vector3) -> float:
	if o.mode == "in":
		var tip := o.in_at + o.in_dir * o.depth
		var rc := p - tip
		var ip := _i_about(o, o.pos - tip)
		return n.dot((ip.inverse() * rc.cross(n)).cross(rc))
	if o.mode == "lie":
		return 0.0
	return _k(o, p - o.pos, n)


func _shove(o: Body, p: Vector3, j: Vector3) -> void:
	if o.mode == "in":
		var tip := o.in_at + o.in_dir * o.depth
		var ip := _i_about(o, o.pos - tip)
		o.spin += ip.inverse() * (p - tip).cross(j)
		o.still = 0.0
	elif o.mode == "fly":
		o.vel += j / o.d.mass
		o.spin += _inv_i(o, (p - o.pos).cross(j))


static func _closest(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> Array:
	var d1 := q1 - p1
	var d2 := q2 - p2
	var r := p1 - p2
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var tt := 0.0
	var c := d1.dot(r)
	var bb := d1.dot(d2)
	var den := a * e - bb * bb
	if den > 0.0000000001:
		s = clampf((bb * f - c * e) / den, 0.0, 1.0)
	tt = (bb * s + f) / e if e > 0.0 else 0.0
	if tt < 0.0:
		tt = 0.0
		s = clampf(-c / a, 0.0, 1.0)
	elif tt > 1.0:
		tt = 1.0
		s = clampf((bb - c) / a, 0.0, 1.0)
	return [p1 + d1 * s, p2 + d2 * tt]


# The carpet: both ends of it, a dead bounce and a lot of grip, and when it's lying still it stays.
func _carpet(b: Body, tp: Vector3, tl: Vector3, h := DT) -> void:
	for p in [tp, tl]:
		if p.y < FLOOR_Y:
			b.pos.y += FLOOR_Y - p.y
			_bump(b, p, Vector3.UP, 0.18, 0.7, "carpet")
	# both ends down on the pile: it's lying, and the carpet's pile takes the slide out of it fast
	var tp2 := b.tip()
	var tl2 := b.tail()
	if tp2.y < FLOOR_Y + 0.004 and tl2.y < FLOOR_Y + 0.016:
		b.vel.y = maxf(b.vel.y, 0.0) * 0.5
		var hz := Vector3(b.vel.x, 0.0, b.vel.z)
		var slow := minf(hz.length(), 9.81 * 0.7 * h)
		if hz.length() > 0.00001:
			b.vel -= hz.normalized() * slow
		b.spin *= maxf(0.0, 1.0 - 30.0 * h)
		if b.vel.length() < 0.05:
			b.still += h
		if b.still > 0.1:
			b.mode = "lie"
			b.vel = Vector3.ZERO
			b.spin = Vector3.ZERO
	else:
		b.still = 0.0


func _heard(b: Body, what: String, speed: float, where: Vector3) -> void:
	if speed < 0.08 and what != "out":
		return
	var k := bodies.find(b)
	# one sound per thing per touch, not one per step it's touching
	for i in range(hits.size() - 1, -1, -1):
		var h: Array = hits[i]
		if float(h[0]) < t - 0.06:
			break
		if int(h[1]) == k and h[2] == what:
			return
	hits.append([t, k, what, speed, where])


# ---------------------------------------------------------------- the score

# What a point at p (on the board's face, board frame) scores: [number, times], [0, 0] off the
# doubles, [25, 1] the outer bull, [25, 2] the bull.
func score_at(p: Vector3) -> Array:
	var q := Vector2(p.x, p.y)
	var r := q.length()
	if r <= R_BULL:
		return [25, 2]
	if r <= R_OUTER_BULL:
		return [25, 1]
	if r > R_DOUBLE_OUT:
		return [0, 0]
	var ang := fposmod(atan2(q.x, q.y) - tilt + deg_to_rad(9.0), TAU)
	var n: int = ORDER[int(floor(ang / deg_to_rad(18.0))) % 20]
	if r >= R_TREBLE_IN and r <= R_TREBLE_OUT:
		return [n, 3]
	if r >= R_DOUBLE_IN:
		return [n, 2]
	return [n, 1]


# Where one ended up and what it's worth: in the board (and scoring), in the board but nowhere
# (past the doubles, the cabinet), on the carpet, still in his hand.
func result(b: Body) -> Dictionary:
	match b.mode:
		"in":
			var tip := b.in_at + b.in_dir * b.depth
			if b.in_what == "sisal":
				var s := score_at(tip)
				return {"where": "board", "n": s[0], "x": s[1], "at": tip, "depth": b.depth}
			return {"where": b.in_what, "n": 0, "x": 0, "at": tip, "depth": b.depth}
		"lie", "fly":
			return {"where": "carpet", "n": 0, "x": 0, "at": b.tip()}
	return {"where": "hand", "n": 0, "x": 0}
