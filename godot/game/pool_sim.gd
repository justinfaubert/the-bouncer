# Pool, worked out exactly (game/pool.gd plays it and plays it back). Not the physics engine and not
# steps: a ball on cloth moves on a curve that can be written down (sliding, rolling, spinning on
# the spot, or in the air), so the sim jumps from one thing happening to the next, works out when
# each ball next meets another ball, a cushion, a jaw, a pocket's edge or a burn in the cloth, and
# takes them in order. The same shot comes out the same every time, to the millimetre, and nothing
# about it is rounded into a number the player can't see.
#
# What it does, the way a ball does it (after Leckie and Greenspan's event-based pool, Han's
# cushion, Alciatore's ball-to-ball friction and squirt):
# - Struck, the cue ball slides: the cloth drags its bottom against the way it's slipping, which
#   both slows it and turns its spin toward rolling. Struck low it slides backspun and comes back
#   (draw), struck high it runs on after the ball it hits (follow); struck dead centre at the
#   right pace it arrives sliding and stops dead (stun). Struck off to the side it squirts off its
#   line the other way, by how heavy the cue's end is; and if the butt's up, the slip and the
#   travel aren't the same way, so it curves (swerve, and at the steepest, masse).
# - Rolling, it slows on the cloth's own drag; its side spin wears off on its own, slower.
# - Ball on ball: a near-elastic knock along the line of their middles, and friction between them
#   at the touch, so a cut ball is thrown off the line a degree or three (more slow, less fast),
#   and side spin on the cue ball throws it the other way.
# - The cushion: struck above the ball's middle (the nose is at 63% of its height), so the ball's
#   running english lengthens the angle off it and reverse shortens it, and a ball driven in hard
#   comes off shorter than it went in. The Sov's rails are old and come off dead.
# - The pockets: jaws faced in at an angle, rounded points, and the slate cut away behind. A ball
#   can rattle between the facings and come back out.
# - The air: a ball struck down into the slate bounces up off it (the jump shot), and can land on
#   another ball, the rail, or the floor.
#
# The Sov's table on top of all that: it leans (the regulars play it; it shows on a slow roll), its
# cloth is worn slow, it's burned in two places where a ball drags and turns a hair, and it's a
# coin-op, so its cue ball is the big heavy bar ball, which draws worse and follows better.
#
# Frame: the cloth's middle, y up, x along the table toward the foot (where the rack goes), z
# across. Metres, kilograms, seconds.
class_name PoolSim
extends RefCounted

const G := 9.81
const K_SPIN := 9.0                # side spin (about the vertical) wears off this fast, rad/s/s
const E_BALL := 0.94
const E_SLATE := 0.5               # a ball coming down on the slate comes back up with this much
const RAIL_TOP := 0.046            # the rail's top over the cloth: a ball in the air higher than this goes over
const MAX_EVENTS := 6000
const MAX_T := 40.0
const FLOOR_Y := -0.80             # the floor, under the cloth

enum {STILL, SPIN, SLIDE, ROLL, AIR, DOWN, OFF}
enum {EV_END, EV_BALL, EV_RAIL, EV_POINT, EV_POCKET, EV_BURN_IN, EV_BURN_OUT}


# ---------------------------------------------------------------- the table

# A table: its size, its pockets, its cloth and its rails, and what's wrong with it.
class Table:
	var name := "sov"
	var L := 2.235                  # nose to nose, along (an eight-foot bar box: 88 by 44 inches)
	var W := 1.118
	var mouth_corner := 0.124       # across the jaws' points
	var mouth_side := 0.133
	var facing_corner := 38.0       # how far each facing turns in off the cushion's line, degrees
	var facing_side := 76.0
	var facing_len_corner := 0.05
	var facing_len_side := 0.035
	var nose_h := 0.0365            # the cushion's nose over the cloth
	var mu_s := 0.20                # the cloth's grip on a sliding ball
	var mu_r := 0.0105              # its drag on a rolling one (worn, this is a slow cloth)
	var rail_e := 0.92              # the rubber's life: 1 new
	var rail_f := 1.0
	var lean := Vector3.ZERO        # the slope's pull along the cloth, m/s/s (g sin of the angle, downhill)
	var burns: Array = []           # [centre (Vector3 on the cloth), radius]
	var cue_r := 0.0294             # the cue ball (a coin-op's bar ball: 2 5/16", near seven ounces)
	var cue_m := 0.19
	var ball_r := 0.028575          # the others (2 1/4", 6 oz)
	var ball_m := 0.17
	# worked out from the above
	var rails: Array = []           # [a (Vector3), b, inward normal]
	var points: Array = []          # jaw points and the facings' far ends: Vector3
	var pockets: Array = []         # [centre, radius of the drop, mouth middle]
	var corners := []               # the pocket mouths' middles, for aiming and calling

	func build() -> void:
		rails = []
		points = []
		pockets = []
		corners = []
		var hl := L * 0.5
		var hw := W * 0.5
		var q := mouth_corner / sqrt(2.0)
		var ms := mouth_side * 0.5
		# the long cushions, each side of the side pocket, and the short ones at the ends
		for sz: float in [-1.0, 1.0]:
			var z := sz * hw
			var n := Vector3(0, 0, -sz)
			_rail(Vector3(-hl + q, 0, z), Vector3(-ms, 0, z), n)
			_rail(Vector3(ms, 0, z), Vector3(hl - q, 0, z), n)
		for sx: float in [-1.0, 1.0]:
			var x := sx * hl
			_rail(Vector3(x, 0, -hw + q), Vector3(x, 0, hw - q), Vector3(-sx, 0, 0))
		# the corner pockets: two jaws faced in toward each other, the slate gone behind
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var c := Vector3(sx * hl, 0, sz * hw)
				var ja := Vector3(sx * (hl - q), 0, sz * hw)     # on the long cushion
				var jb := Vector3(sx * hl, 0, sz * (hw - q))     # on the short one
				var fa := deg_to_rad(facing_corner)
				var da := Vector3(sx * cos(fa), 0, sz * sin(fa))   # from the long cushion's point, on toward the corner and out
				var db := Vector3(sx * sin(fa), 0, sz * cos(fa))
				var ea := ja + da * facing_len_corner
				var eb := jb + db * facing_len_corner
				var ax := Vector3(sx, 0, sz).normalized()
				_facing(ja, ea, c, ax)
				_facing(jb, eb, c, ax)
				points.append_array([ja, jb, ea, eb])
				var mid := (ea + eb) * 0.5
				pockets.append([mid, ea.distance_to(eb) * 0.5 + 0.004, (ja + jb) * 0.5])
				corners.append((ja + jb) * 0.5)
		# the side pockets: the jaws nearly square to the rail, a little in
		for sz: float in [-1.0, 1.0]:
			var z := sz * hw
			var fs := deg_to_rad(facing_side)
			var ja := Vector3(-ms, 0, z)
			var jb := Vector3(ms, 0, z)
			var ea := ja + Vector3(cos(fs), 0, sz * sin(fs)) * facing_len_side
			var eb := jb + Vector3(-cos(fs), 0, sz * sin(fs)) * facing_len_side
			_facing(ja, ea, Vector3(0, 0, z), Vector3(0, 0, sz))
			_facing(jb, eb, Vector3(0, 0, z), Vector3(0, 0, sz))
			points.append_array([ja, jb, ea, eb])
			pockets.append([(ea + eb) * 0.5, ea.distance_to(eb) * 0.5 + 0.002, (ja + jb) * 0.5])
			corners.append((ja + jb) * 0.5)

	func _rail(a: Vector3, b: Vector3, n: Vector3) -> void:
		rails.append([a, b, n.normalized()])

	# a jaw's facing, from its point back into the throat: its working side faces the pocket's axis
	# (the line in through the middle of the pocket), toward the other jaw
	func _facing(a: Vector3, b: Vector3, axis_at: Vector3, axis: Vector3) -> void:
		var along := (b - a).normalized()
		var n := Vector3(-along.z, 0, along.x)
		var rel := a - axis_at
		var off := rel - axis * rel.dot(axis)
		if n.dot(-off) < 0.0:
			n = -n
		rails.append([a, b, n])

	func head_string() -> float:
		return -L * 0.25            # the kitchen's line: behind it, toward -x

	func foot_spot() -> Vector3:
		return Vector3(L * 0.25, 0, 0)

	func head_spot() -> Vector3:
		return Vector3(-L * 0.25, 0, 0)

	# the frame round the cloth, for the cue to clear: the cushion's depth past the nose, the wooden
	# rail past that, and how high the wood stands over the cloth
	const CUSH_W := 0.05
	const RAIL_W := 0.105
	const WOOD_TOP := 0.064


static func sov_table() -> Table:
	var t := Table.new()
	t.name = "sov"
	# the lean: a twentieth of a degree, down toward the window side and a little toward the foot
	var ang := deg_to_rad(0.05)
	t.lean = Vector3(0.35, 0, 1.0).normalized() * G * sin(ang)
	t.burns = [[Vector3(0.42, 0, -0.21), 0.022], [Vector3(-0.55, 0, 0.30), 0.016]]
	t.build()
	return t


# A good table somewhere else: new cloth, live rails, level, a regulation cue ball.
static func good_table(nine_foot := false) -> Table:
	var t := Table.new()
	t.name = "legion" if nine_foot else "good"
	if nine_foot:
		t.L = 2.54
		t.W = 1.27
	t.mouth_corner = 0.117
	t.mouth_side = 0.13
	t.mu_r = 0.0085
	t.mu_s = 0.2
	t.rail_e = 1.0
	t.cue_r = 0.028575
	t.cue_m = 0.17
	t.build()
	return t


# ---------------------------------------------------------------- a ball

class Ball:
	var id := 0
	var r := 0.028575
	var m := 0.17
	var inertia := 0.0
	var rc := 0.0                   # how far its middle is from a cushion's nose when it touches it
	var p := Vector3.ZERO           # where it is at t0
	var v := Vector3.ZERO
	var w := Vector3.ZERO
	var t0 := 0.0
	var state := 0
	var acc := Vector3.ZERO
	var alpha := Vector3.ZERO       # the spin's change, a second (about the horizontal axes)
	var spin_dec := 0.0             # and about the vertical
	var t_end := INF                # when this stretch of its motion ends by itself
	var ver := 0
	var segs: Array = []            # [t0, p, v, acc, w, alpha, spin_dec, state]
	var burn := -1                  # the burn it's in, or -1
	var pocket := -1
	var down_t := INF

	func _init(radius := 0.028575, mass := 0.17) -> void:
		r = radius
		m = mass
		inertia = 0.4 * m * r * r

	func at(t: float) -> Vector3:
		var d := t - t0
		return p + v * d + acc * (0.5 * d * d)

	func vel(t: float) -> Vector3:
		return v + acc * (t - t0)

	func spin(t: float) -> Vector3:
		var d := t - t0
		var o := w + alpha * d
		if spin_dec != 0.0:
			var wy := w.y + spin_dec * d
			if signf(wy) != signf(w.y):
				wy = 0.0
			o.y = wy
		return o

	func moving() -> bool:
		return state == SLIDE or state == ROLL or state == AIR or state == SPIN


var table: Table
var balls: Array = []
var t := 0.0
var log: Array = []                 # what happened: [t, kind, a, b, speed]
var heap: Array = []
var events := 0
var done := false


func _init(tb: Table = null) -> void:
	table = tb if tb != null else PoolSim.sov_table()


func add_ball(id: int, at: Vector3, cue := false) -> Ball:
	var b := Ball.new(table.cue_r if cue else table.ball_r, table.cue_m if cue else table.ball_m)
	b.id = id
	b.p = Vector3(at.x, b.r, at.z)
	_set_rc(b)
	balls.append(b)
	return b


func _set_rc(b: Ball) -> void:
	var dh := table.nose_h - b.r
	b.rc = sqrt(maxf(b.r * b.r - dh * dh, 0.0))


# The lowest the butt can go, in radians, for a cue laid along dir (on the cloth's plane) from the
# cue ball: the cue's own thickness kept over the cushion, the wooden rail and any ball behind,
# and a hand's thickness more where he has to bridge on the rail. The player and the man across the
# table both go by it, so neither cue goes through the table.
func min_elev(dir: Vector3, lo := deg_to_rad(2.0)) -> float:
	var cb := ball(0)
	var back := Vector3(-dir.x, 0, -dir.z).normalized()
	var need := lo
	var hl := table.L * 0.5
	var hw := table.W * 0.5
	# where the line back crosses the nose, the cushion's back and the wood's outer edge
	for k in 3:
		var out := [0.0, Table.CUSH_W, Table.CUSH_W + Table.RAIL_W][k] as float
		var top := [RAIL_TOP, Table.WOOD_TOP, Table.WOOD_TOP][k] as float
		var dist := INF
		if absf(back.x) > 1e-4:
			dist = minf(dist, ((hl + out if back.x > 0 else -hl - out) - cb.p.x) / back.x)
		if absf(back.z) > 1e-4:
			dist = minf(dist, ((hw + out if back.z > 0 else -hw - out) - cb.p.z) / back.z)
		if dist <= 0.0 or dist > 1.6:
			continue
		# the cue's thickness there (a tip of 6.5 mm out to a butt of 15 over its 1.47 m), and the
		# bridge hand when the rail's that close
		var thick := 0.0065 + 0.0085 * clampf(dist / 1.47, 0.0, 1.0)
		var hand := 0.022 if dist < 0.32 else 0.004
		need = maxf(need, atan2(top + thick + hand - cb.r, dist))
	for o in balls:
		if o.id == 0 or o.state == DOWN or o.state == OFF:
			continue
		var rel := Vector3(o.p.x - cb.p.x, 0, o.p.z - cb.p.z)
		var s := rel.dot(back)
		if s <= 0.0 or s > 0.7:
			continue
		if (rel - back * s).length() < o.r + 0.014:
			need = maxf(need, atan2(o.r * 2.0 + 0.009 - cb.r, s))
	return need


func ball(id: int) -> Ball:
	for b in balls:
		if b.id == id:
			return b
	return null


# A copy to try things in (the opponents think this way): the same table, the balls where they are now.
func copy() -> PoolSim:
	var s := PoolSim.new(table)
	for b in balls:
		var c := Ball.new(b.r, b.m)
		c.id = b.id
		c.rc = b.rc
		if b.state == DOWN:
			# gone: under the table, not left lying on the pocket's lip where the next shot's
			# playback would show it and the others roll through it
			var pc: Vector3 = table.pockets[b.pocket][0] if b.pocket >= 0 else b.p
			c.p = Vector3(pc.x, -0.5, pc.z)
		elif b.state == OFF:
			c.p = sample(b, t + 30.0)[0] if not b.segs.is_empty() else b.p
		else:
			c.p = b.at(t)
			c.p.y = c.r
		c.state = b.state if b.state == DOWN or b.state == OFF else STILL
		c.pocket = b.pocket
		s.balls.append(c)
	return s


# ---------------------------------------------------------------- the stroke

# The cue on the cue ball. dir: the way the cue points, along the cloth. elev: how far the butt's
# raised, radians. a, b: where the tip lands on the ball's face, across and up, as parts of its
# radius. speed: the cue's, m/s. cue: {"M" its weight, "end" the weight of its last few inches
# (what squirt comes from), "e" the tip's bounce, "limit" how far off the middle the tip holds
# before it slips off (the chalk and the tip's shape)}.
# Returns what happened at the tip: {"miscue": bool, "v": speed off the tip, "squirt": radians}.
func strike(cue_ball: Ball, dir: Vector3, elev: float, a: float, b: float, speed: float, cue: Dictionary) -> Dictionary:
	var R := cue_ball.r
	var m := cue_ball.m
	var h := Vector3(dir.x, 0, dir.z).normalized()
	var d := (h * cos(elev) - Vector3.UP * sin(elev)).normalized()
	var s := h.cross(Vector3.UP).normalized()
	var u := s.cross(d).normalized()
	var off := sqrt(a * a + b * b)
	var limit := float(cue.get("limit", 0.55))
	var miscue := off > limit
	if miscue:
		# the tip slides off the ball: a glancing push, most of the cue's going past it
		var k := clampf(1.0 - (off - limit) * 3.0, 0.15, 0.45)
		a *= 0.6
		b *= 0.6
		speed *= k
	var aa := clampf(a, -0.7, 0.7) * R
	var bb := clampf(b, -0.7, 0.7) * R
	var c := sqrt(maxf(R * R - aa * aa - bb * bb, 0.0))
	var rc := s * aa + u * bb - d * c
	var M := float(cue.get("M", 0.54))
	var e := float(cue.get("e", 0.75))
	var arm := rc.cross(d)
	var inv_eff := 1.0 / m + arm.length_squared() / cue_ball.inertia
	var J := (1.0 + e) * speed / (1.0 / M + inv_eff)
	var v := d * (J / m)
	var w := rc.cross(d * J) / cue_ball.inertia
	# squirt: the tip's end mass pushed aside by the ball, so the ball goes off the other way
	var me := float(cue.get("end", 0.007))
	var fa := clampf(a, -0.7, 0.7)
	var sq := atan((2.5 * fa * sqrt(1.0 - fa * fa)) / (1.0 + m / me + 2.5 * (1.0 - fa * fa)))
	var vh := Vector3(v.x, 0, v.z)
	var vy := v.y
	var sp := vh.length()
	vh = (h * cos(sq) - s * sin(sq)) * sp
	v = Vector3(vh.x, vy, vh.z)
	cue_ball.p = cue_ball.at(t)
	cue_ball.v = v
	cue_ball.w = w
	cue_ball.t0 = t
	# driven down into the slate, it comes back up off it
	if cue_ball.v.y < 0.0:
		cue_ball.v.y = -cue_ball.v.y * E_SLATE
		# the slate's grip in that moment takes a little off its speed and its spin
		cue_ball.v.x *= 0.96
		cue_ball.v.z *= 0.96
		if cue_ball.v.y < 0.12:
			cue_ball.v.y = 0.0
	log.append([t, "cue", cue_ball.id, -1, sp, off])
	_classify(cue_ball)
	return {"miscue": miscue, "v": sp, "squirt": sq, "J": J}


# ---------------------------------------------------------------- running it

func run(max_t := MAX_T) -> void:
	heap = []
	done = false
	for b in balls:
		_classify(b)
	for b in balls:
		_plan(b, true)
	while not heap.is_empty() and events < MAX_EVENTS:
		var e: Array = _pop()
		var et: float = e[0]
		if et > max_t:
			break
		var a: Ball = balls[e[2]]
		if a.ver != e[4]:
			continue
		var bi: int = e[3]
		if e[1] == EV_BALL and (balls[bi] as Ball).ver != e[5]:
			continue
		events += 1
		t = et
		_handle(e)
	# everything stops where it is
	for b in balls:
		if b.state != DOWN and b.state != OFF:
			_advance(b, t)
	done = true


func still() -> bool:
	for b in balls:
		if b.moving():
			return false
	return true


func _handle(e: Array) -> void:
	var a: Ball = balls[e[2]]
	match e[1]:
		EV_END:
			_advance(a, t)
			match a.state:
				SLIDE:
					# the slip's gone: rolling, its spin matched to its travel (or only a stretch of
					# sliding done, on a table that leans, and it goes on sliding)
					if slip(a).length() < 0.01:
						_roll_now(a)
				ROLL:
					if Vector2(a.v.x, a.v.z).length() < 0.002:
						a.v = Vector3.ZERO
						a.w.x = 0.0
						a.w.z = 0.0
					else:
						_roll_now(a)
				SPIN:
					a.w.y = 0.0
				AIR:
					# down on the slate
					a.p.y = a.r
					if a.v.y < 0.0:
						a.v.y = -a.v.y * E_SLATE
					if a.v.y < 0.15:
						a.v.y = 0.0
					log.append([t, "bounce", a.id, -1, absf(a.v.y)])
			if absf(a.w.y) < 0.02 or (a.spin_dec != 0.0 and absf(a.w.y) < absf(a.spin_dec) * 0.002):
				a.w.y = 0.0
			_classify(a)
			_plan(a)
		EV_BALL:
			var b: Ball = balls[e[3]]
			_advance(a, t)
			_advance(b, t)
			_collide(a, b)
			_classify(a)
			_classify(b)
			_plan(a)
			_plan(b)
		EV_RAIL, EV_POINT:
			_advance(a, t)
			var n: Vector3
			if e[1] == EV_RAIL:
				n = table.rails[e[3]][2]
			else:
				var c: Vector3 = table.points[e[3]]
				n = Vector3(a.p.x - c.x, 0, a.p.z - c.z).normalized()
			# in the air over the rail: it goes over, onto the floor
			if a.p.y - a.r > RAIL_TOP:
				a.state = OFF
				log.append([t, "off", a.id, -1, a.v.length()])
				_off_floor(a)
				return
			var vin := -Vector3(a.v.x, 0, a.v.z).dot(n)
			_cushion(a, n)
			log.append([t, "rail" if e[1] == EV_RAIL else "jaw", a.id, e[3], vin])
			_classify(a)
			_plan(a)
		EV_POCKET:
			_advance(a, t)
			a.pocket = e[3]
			a.down_t = t
			log.append([t, "pocket", a.id, e[3], a.v.length()])
			a.segs.append([t, a.p, a.v, Vector3(0, -G, 0), a.w, Vector3.ZERO, 0.0, DOWN])
			a.state = DOWN
			a.ver += 1
		EV_BURN_IN, EV_BURN_OUT:
			_advance(a, t)
			if e[1] == EV_BURN_IN:
				a.burn = e[3]
				# the crust of the burn: it turns a hair, the way it's crossing it
				var bc: Vector3 = table.burns[e[3]][0]
				var vh := Vector3(a.v.x, 0, a.v.z)
				var side := signf((a.p - bc).cross(vh).y)
				a.v = a.v.rotated(Vector3.UP, side * 0.006)
				log.append([t, "burn", a.id, e[3], vh.length()])
			else:
				a.burn = -1
			_classify(a)
			_plan(a)


# where it is, its speed and its spin, brought up to time tt
func _advance(b: Ball, tt: float) -> void:
	b.p = b.at(tt)
	var v := b.vel(tt)
	var w := b.spin(tt)
	b.v = v
	b.w = w
	b.t0 = tt


func _roll_now(b: Ball) -> void:
	b.v.y = 0.0
	b.p.y = b.r
	var vh := Vector3(b.v.x, 0, b.v.z)
	var wh := Vector3.UP.cross(vh) / b.r
	b.w.x = wh.x
	b.w.z = wh.z


func _mu_r(b: Ball) -> float:
	return table.mu_r * (2.6 if b.burn >= 0 else 1.0)


func _mu_s(b: Ball) -> float:
	return table.mu_s * (1.25 if b.burn >= 0 else 1.0)


# the slip at the bottom of the ball, where it touches the cloth
func slip(b: Ball) -> Vector3:
	var u := b.v - b.r * b.w.cross(Vector3.UP)
	u.y = 0.0
	return u


# What it's doing now, and so how it'll move until something changes it.
func _classify(b: Ball) -> void:
	if b.state == DOWN or b.state == OFF:
		return
	b.ver += 1
	b.acc = Vector3.ZERO
	b.alpha = Vector3.ZERO
	b.spin_dec = 0.0
	b.t_end = INF
	var lean := table.lean
	if b.p.y > b.r + 1e-5 or b.v.y > 1e-4:
		b.state = AIR
		b.acc = Vector3(0, -G, 0)
		var dy := b.p.y - b.r
		b.t_end = t + (b.v.y + sqrt(b.v.y * b.v.y + 2.0 * G * maxf(dy, 0.0))) / G
		_seg(b)
		return
	b.p.y = b.r
	b.v.y = 0.0
	var u := slip(b)
	var vh := Vector3(b.v.x, 0, b.v.z)
	var cap := INF if lean == Vector3.ZERO else 0.12
	if u.length() > 0.004:
		b.state = SLIDE
		var uh := u.normalized()
		var ms := _mu_s(b)
		b.acc = -uh * ms * G + lean
		b.alpha = Vector3.UP.cross(uh) * (5.0 * ms * G / (2.0 * b.r))
		b.t_end = t + minf(2.0 * u.length() / (7.0 * ms * G), cap * 0.5)
	elif vh.length() > 0.002:
		b.state = ROLL
		_roll_now(b)
		var vn := vh.normalized()
		b.acc = -vn * _mu_r(b) * G + lean * (5.0 / 7.0)
		var dec := -b.acc.dot(vn)
		b.alpha = Vector3.UP.cross(b.acc) / b.r
		b.t_end = t + minf(vh.length() / maxf(dec, 1e-5), cap)
	elif absf(b.w.y) > 0.02:
		b.state = SPIN
		b.v = Vector3.ZERO
		b.w.x = 0.0
		b.w.z = 0.0
	else:
		b.state = STILL
		b.v = Vector3.ZERO
		b.w = Vector3.ZERO
		_seg(b)
		return
	if absf(b.w.y) > 0.02:
		b.spin_dec = -signf(b.w.y) * K_SPIN
		b.t_end = minf(b.t_end, t + absf(b.w.y) / K_SPIN)
	else:
		b.w.y = 0.0
	_seg(b)


func _seg(b: Ball) -> void:
	b.t0 = t
	b.segs.append([t, b.p, b.v, b.acc, b.w, b.alpha, b.spin_dec, b.state])


func _off_floor(b: Ball) -> void:
	b.ver += 1
	b.acc = Vector3(0, -G, 0)
	b.alpha = Vector3.ZERO
	b.spin_dec = 0.0
	b.t0 = t
	b.down_t = t
	b.segs.append([t, b.p, b.v, b.acc, b.w, Vector3.ZERO, 0.0, OFF])


# ---------------------------------------------------------------- what's next for a ball

func _plan(b: Ball, first := false) -> void:
	if b.state == DOWN or b.state == OFF:
		return
	var moving := _travelling(b)
	var bi := balls.find(b)
	if b.t_end < INF:
		_push([b.t_end, EV_END, bi, -1, b.ver, 0])
	var hor := b.t_end
	# other balls: any pair where one of them is going somewhere
	for j in balls.size():
		var o: Ball = balls[j]
		if o == b or o.state == DOWN or o.state == OFF:
			continue
		if not moving and not _travelling(o):
			continue
		if first and j < bi:
			continue                      # found already from its side
		var h := minf(hor, o.t_end)
		var tc := _ball_time(b, o, h)
		if tc < INF:
			_push([tc, EV_BALL, bi, j, b.ver, o.ver])
	if not moving:
		return
	var h_end := minf(hor, t + MAX_T)
	# the cushions and the facings
	var A := b.at(t)
	var B := b.vel(t)
	var C := b.acc * 0.5
	for k in table.rails.size():
		var rl: Array = table.rails[k]
		var n: Vector3 = rl[2]
		var a0: Vector3 = rl[0]
		var a1: Vector3 = rl[1]
		var d0 := n.dot(Vector3(A.x - a0.x, 0, A.z - a0.z)) - b.rc
		var d1 := n.dot(Vector3(B.x, 0, B.z))
		var d2 := n.dot(Vector3(C.x, 0, C.z))
		if d0 < -b.rc * 2.0:
			continue                      # behind it: the rail on the other side of a pocket's throat
		var tc := _first_cross([d0, d1, d2], 0.0, h_end - t, -1)
		if tc < INF:
			var hit := b.at(t + tc)
			var along := a1 - a0
			var s := Vector3(hit.x - a0.x, 0, hit.z - a0.z).dot(along) / along.length_squared()
			if s >= 0.0 and s <= 1.0:
				_push([t + tc, EV_RAIL, bi, k, b.ver, 0])
	for k in table.points.size():
		var c: Vector3 = table.points[k]
		var tc := _circle_time(A, B, C, c, b.rc, h_end - t, -1)
		if tc < INF:
			_push([t + tc, EV_POINT, bi, k, b.ver, 0])
	for k in table.pockets.size():
		var pk: Array = table.pockets[k]
		var tc := _circle_time(A, B, C, pk[0], pk[1], h_end - t, -1)
		if tc < INF:
			_push([t + tc, EV_POCKET, bi, k, b.ver, 0])
	for k in table.burns.size():
		var bn: Array = table.burns[k]
		if b.state == AIR:
			continue
		var tc := _circle_time(A, B, C, bn[0], bn[1], h_end - t, -1 if b.burn != k else 1)
		if tc < INF:
			_push([t + tc, EV_BURN_IN if b.burn != k else EV_BURN_OUT, bi, k, b.ver, 0])


func _travelling(b: Ball) -> bool:
	return b.state == SLIDE or b.state == ROLL or b.state == AIR


# when two balls touch, from now, before h; INF if they don't
func _ball_time(a: Ball, b: Ball, h: float) -> float:
	var A := b.at(t) - a.at(t)
	var B := b.vel(t) - a.vel(t)
	var C := (b.acc - a.acc) * 0.5
	var D := a.r + b.r
	var span := h - t
	if span <= 0.0:
		return INF
	span = minf(span, MAX_T)
	# can't reach each other in the time: skip the sums
	var reach := B.length() * span + C.length() * span * span
	if A.length() - D > reach + 1e-6:
		return INF
	var c4 := C.dot(C)
	var c3 := 2.0 * B.dot(C)
	var c2 := B.dot(B) + 2.0 * A.dot(C)
	var c1 := 2.0 * A.dot(B)
	var c0 := A.dot(A) - D * D
	var tc := _first_cross([c0, c1, c2, c3, c4], 0.0, span, -1)
	return t + tc if tc < INF else INF


# when a point moving A + B t + C t^2 comes to within r of c (dir -1), or out past it (dir 1), on the cloth
func _circle_time(A: Vector3, B: Vector3, C: Vector3, c: Vector3, r: float, span: float, dir: int) -> float:
	if span <= 0.0:
		return INF
	var a := Vector3(A.x - c.x, 0, A.z - c.z)
	var b := Vector3(B.x, 0, B.z)
	var cc := Vector3(C.x, 0, C.z)
	if dir < 0:
		var reach := b.length() * span + cc.length() * span * span
		if a.length() - r > reach + 1e-6:
			return INF
	var c4 := cc.dot(cc)
	var c3 := 2.0 * b.dot(cc)
	var c2 := b.dot(b) + 2.0 * a.dot(cc)
	var c1 := 2.0 * a.dot(b)
	var c0 := a.dot(a) - r * r
	return _first_cross([c0, c1, c2, c3, c4], 0.0, span, dir)


# ---------------------------------------------------------------- what happens when they meet

func _collide(a: Ball, b: Ball) -> void:
	var n := (b.p - a.p).normalized()
	var vrel := a.v - b.v
	var vn := vrel.dot(n)
	if vn <= 0.0:
		return
	var red := 1.0 / (1.0 / a.m + 1.0 / b.m)
	var Jn := (1.0 + E_BALL) * vn * red
	# the touch: how the two surfaces slide on each other there (travel and spin)
	var ua := a.v + a.w.cross(n * a.r)
	var ub := b.v + b.w.cross(-n * b.r)
	var du := ua - ub
	var dut := du - n * du.dot(n)
	var Jt := 0.0
	var th := Vector3.ZERO
	if dut.length() > 1e-6:
		th = dut.normalized()
		var mu := 0.00995 + 0.108 * exp(-1.088 * dut.length())
		var kt := 1.0 / a.m + 1.0 / b.m + a.r * a.r / a.inertia + b.r * b.r / b.inertia
		Jt = minf(mu * Jn, dut.length() / kt)
	var Pa := -n * Jn - th * Jt
	var Pb := -Pa
	a.v += Pa / a.m
	b.v += Pb / b.m
	a.w += (n * a.r).cross(Pa) / a.inertia
	b.w += (-n * b.r).cross(Pb) / b.inertia
	for x in [a, b]:
		var bx: Ball = x
		if bx.p.y <= bx.r + 1e-5:
			if bx.v.y < 0.0:
				bx.v.y = 0.0
			elif bx.v.y < 0.05:
				bx.v.y = 0.0
	log.append([t, "ball", a.id, b.id, vn, Jt / maxf(Jn, 1e-9)])


# The cushion (Han, 2005): the nose takes the ball above its middle, so the impulse has a part down
# into the slate and the friction at the nose works on the ball's spin about every axis.
func _cushion(b: Ball, n_in: Vector3) -> void:
	var X := -n_in                       # into the cushion
	var Z := Vector3.UP
	var Y := Z.cross(X)
	var R := b.r
	var m := b.m
	var vx := b.v.dot(X)
	var vy := b.v.dot(Y)
	var vz := b.v.dot(Z)
	var wx := b.w.dot(X)
	var wy := b.w.dot(Y)
	var wz := b.w.dot(Z)
	if vx <= 0.0:
		return
	var th := asin(clampf(table.nose_h / R - 1.0, -0.9, 0.9))
	var e := clampf(0.5 + 0.257 * vx - 0.044 * vx * vx, 0.55, 0.9) * table.rail_e
	var phi := fmod(atan2(vy, vx) + TAU, TAU)
	var phi_in := absf(atan2(vy, vx))
	var f := clampf(0.471 - 0.241 * phi_in, 0.1, 0.471) * table.rail_f
	var sx := vx * sin(th) - vz * cos(th) + R * wy
	var sy := -vy - R * wz * cos(th) + R * wx * sin(th)
	var c := vx * cos(th)
	var II := 0.4 * m * R * R
	var Ak := 3.5 / m
	var Bk := 1.0 / m
	var PzE := (1.0 + e) * c / Bk
	var PzS := sqrt(sx * sx + sy * sy) / Ak
	var PX: float
	var PY: float
	var PZ: float
	if PzS <= PzE:
		PX = -sx / Ak * sin(th) - (1.0 + e) * c / Bk * cos(th)
		PY = sy / Ak
		PZ = sx / Ak * cos(th) - (1.0 + e) * c / Bk * sin(th)
	else:
		PX = -f * (1.0 + e) * c / Bk * cos(phi) * sin(th) - (1.0 + e) * c / Bk * cos(th)
		PY = f * (1.0 + e) * c / Bk * sin(phi)
		PZ = f * (1.0 + e) * c / Bk * cos(phi) * cos(th) - (1.0 + e) * c / Bk * sin(th)
	vx += PX / m
	vy += PY / m
	wx += -R / II * PY * sin(th)
	wy += R / II * (PX * sin(th) - PZ * cos(th))
	wz += R / II * PY * cos(th)
	b.v = X * vx + Y * vy + Z * maxf(vz, 0.0)
	b.w = X * wx + Y * wy + Z * wz
	# whatever was pushed down went into the slate; a ball low in the air stays on it
	if b.p.y <= b.r + 1e-4:
		b.v.y = 0.0


# ---------------------------------------------------------------- the sums

# The first time in [lo, hi] a polynomial (lowest power first) crosses zero going the way dir says
# (-1 down through it, 1 up through it); INF if it doesn't. Exact to a few nanoseconds.
static func _first_cross(c: Array, lo: float, hi: float, dir: int) -> float:
	var f0 := _ev(c, lo)
	var d0 := _ev(_deriv(c), lo)
	# touching or already through, and still going that way: now. (Only a hair through counted
	# once, and a touch at this very moment was skipped as a root at the start: in a rack, where
	# everything touches at once, balls went through each other.)
	if dir < 0 and f0 < 1e-9 and d0 < 0.0:
		return lo
	if dir > 0 and f0 > -1e-9 and d0 > 0.0:
		return lo
	var rs := _roots(c, lo, hi)
	for r in rs:
		if r <= lo + 1e-10:
			continue
		var dr := _ev(_deriv(c), r)
		if dir < 0 and dr < 0.0:
			return r
		if dir > 0 and dr > 0.0:
			return r
		# a touch that's a double root (a graze): go a hair either side
		if dr == 0.0:
			var before := _ev(c, r - 1e-7)
			var after := _ev(c, r + 1e-7)
			if dir < 0 and before > 0.0 and after <= 0.0:
				return r
			if dir > 0 and before < 0.0 and after >= 0.0:
				return r
	return INF


static func _ev(c: Array, x: float) -> float:
	var s := 0.0
	for i in range(c.size() - 1, -1, -1):
		s = s * x + float(c[i])
	return s


static func _deriv(c: Array) -> Array:
	var d := []
	for i in range(1, c.size()):
		d.append(float(c[i]) * i)
	return d


static func _trim(c: Array) -> Array:
	var o := c.duplicate()
	var big := 0.0
	for x in o:
		big = maxf(big, absf(float(x)))
	while o.size() > 1 and absf(float(o[o.size() - 1])) <= big * 1e-14:
		o.pop_back()
	return o


# every real root in [lo, hi], in order: between the roots of the derivative the polynomial only goes
# one way, so each stretch has at most one, and halving finds it
static func _roots(c0: Array, lo: float, hi: float) -> Array:
	var c := _trim(c0)
	var deg := c.size() - 1
	if deg <= 0:
		return []
	if deg == 1:
		var r := -float(c[0]) / float(c[1])
		return [r] if r >= lo and r <= hi else []
	if deg == 2:
		var a := float(c[2])
		var b := float(c[1])
		var cc := float(c[0])
		var disc := b * b - 4.0 * a * cc
		if disc < 0.0:
			return []
		var sq := sqrt(disc)
		var q := -0.5 * (b + (sq if b >= 0.0 else -sq))
		var out := []
		var r1 := q / a
		var r2 := cc / q if q != 0.0 else r1
		for r in [minf(r1, r2), maxf(r1, r2)]:
			if r >= lo and r <= hi and (out.is_empty() or absf(r - float(out[out.size() - 1])) > 1e-13):
				out.append(r)
		return out
	var crit := _roots(_deriv(c), lo, hi)
	var pts := [lo]
	pts.append_array(crit)
	pts.append(hi)
	var out := []
	for i in range(pts.size() - 1):
		var x0: float = pts[i]
		var x1: float = pts[i + 1]
		var f0 := _ev(c, x0)
		var f1 := _ev(c, x1)
		if f0 == 0.0:
			if out.is_empty() or absf(x0 - float(out[out.size() - 1])) > 1e-13:
				out.append(x0)
			continue
		if f0 * f1 < 0.0:
			for k in 64:
				var mid := (x0 + x1) * 0.5
				var fm := _ev(c, mid)
				if (fm < 0.0) == (f0 < 0.0):
					x0 = mid
					f0 = fm
				else:
					x1 = mid
				if x1 - x0 < 1e-12:
					break
			out.append((x0 + x1) * 0.5)
		elif f1 == 0.0 and i == pts.size() - 2:
			out.append(x1)
	return out


# ---------------------------------------------------------------- the heap of what's coming

func _push(e: Array) -> void:
	heap.append(e)
	var i := heap.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if float(heap[p][0]) <= float(e[0]):
			break
		heap[i] = heap[p]
		i = p
	heap[i] = e


func _pop() -> Array:
	var top: Array = heap[0]
	var last: Array = heap.pop_back()
	if heap.is_empty():
		return top
	var i := 0
	var n := heap.size()
	while true:
		var l := 2 * i + 1
		if l >= n:
			break
		var r := l + 1
		var c := l if r >= n or float(heap[l][0]) <= float(heap[r][0]) else r
		if float(heap[c][0]) >= float(last[0]):
			break
		heap[i] = heap[c]
		i = c
	heap[i] = last
	return top


# ---------------------------------------------------------------- playing it back

# Where a ball is at time tt, from the stretches it went through; and its spin there, to turn it by.
# A pocketed ball drops into the pocket and is gone; one off the table falls to the floor and lies.
func sample(b: Ball, tt: float) -> Array:
	if b.segs.is_empty():
		return [b.p, Vector3.ZERO, b.state != DOWN]
	var k := b.segs.size() - 1
	while k > 0 and float(b.segs[k][0]) > tt:
		k -= 1
	var sg: Array = b.segs[k]
	var d := maxf(tt - float(sg[0]), 0.0)
	var st: int = sg[7]
	if st == DOWN:
		var pk: Array = table.pockets[b.pocket] if b.pocket >= 0 else [sg[1], 0.05]
		var c: Vector3 = pk[0]
		var k2 := clampf(d / 0.18, 0.0, 1.0)
		var p0: Vector3 = sg[1]
		var p := p0.lerp(Vector3(c.x, p0.y, c.z), k2)
		p.y = p0.y - 0.5 * G * d * d
		# one that went down the same pocket just before is still in the cup: this one lands on it
		for o in balls:
			if o != b and o.state == DOWN and o.pocket == b.pocket and o.down_t < b.down_t and b.down_t - o.down_t < 0.4:
				var po: Vector3 = sample(o, tt)[0]
				var gap := Vector2(p.x - po.x, p.z - po.z).length()
				var need := o.r + b.r
				if gap < need:
					p.y = maxf(p.y, po.y + sqrt(need * need - gap * gap))
		var vis := p.y > -0.12
		return [p, sg[4], vis]
	if st == OFF:
		var p0: Vector3 = sg[1]
		var v0: Vector3 = sg[2]
		var p := p0 + v0 * d + Vector3(0, -G, 0) * (0.5 * d * d)
		if p.y < FLOOR_Y + b.r:
			# on the floor: find where it got to and leave it there (it rolls a little under the table)
			var tf := (v0.y + sqrt(v0.y * v0.y + 2.0 * G * (p0.y - FLOOR_Y - b.r))) / G
			p = p0 + v0 * tf + Vector3(0, -G, 0) * (0.5 * tf * tf)
			p.y = FLOOR_Y + b.r
			var vh := Vector3(v0.x, 0, v0.z) * 0.35
			var rest := minf(d - tf, 0.6)
			p += vh * rest * (1.0 - rest / 1.2)
		return [p, sg[4], true]
	var p := (sg[1] as Vector3) + (sg[2] as Vector3) * d + (sg[3] as Vector3) * (0.5 * d * d)
	var w := (sg[4] as Vector3) + (sg[5] as Vector3) * d
	if float(sg[6]) != 0.0:
		var wy := float((sg[4] as Vector3).y) + float(sg[6]) * d
		if signf(wy) != signf((sg[4] as Vector3).y):
			wy = 0.0
		w.y = wy
	# a stretch that ended (a still ball's last stretch has no end)
	if k < b.segs.size() - 1:
		var nxt: float = b.segs[k + 1][0]
		if tt > nxt:
			pass
	return [p, w, true]


# when the last ball stops moving, for playing it back
func end_time() -> float:
	return t


# ---------------------------------------------------------------- reading the log

# what the cue ball touched first: the id, or -1
func first_hit(cue_id := 0) -> int:
	for e in log:
		if e[1] == "ball" and (e[2] == cue_id or e[3] == cue_id):
			return e[3] if e[2] == cue_id else e[2]
	return -1


func pocketed() -> Array:
	var out := []
	for e in log:
		if e[1] == "pocket":
			out.append(e[2])
	return out


func went_off() -> Array:
	var out := []
	for e in log:
		if e[1] == "off":
			out.append(e[2])
	return out


# did anything touch a cushion after the cue ball's first hit (the rule in league play)
func rail_after_contact(cue_id := 0) -> bool:
	var hit := false
	for e in log:
		if e[1] == "ball" and (e[2] == cue_id or e[3] == cue_id):
			hit = true
		elif hit and (e[1] == "rail" or e[1] == "jaw" or e[1] == "pocket"):
			return true
	return false


func rails_by(id: int) -> int:
	var n := 0
	for e in log:
		if (e[1] == "rail") and e[2] == id:
			n += 1
	return n
