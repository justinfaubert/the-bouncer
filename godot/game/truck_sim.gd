# The truck, worked out step by step (game/truck.gd drives it and draws it). A jade green 1978
# F-250 Camper Special: two tonnes on four wheels, a big carbureted V8, a three-speed automatic
# through a torque converter, Twin I-Beam at the front and heavy leaf springs at the back, power
# steering with four turns lock to lock and play on centre, discs at the front and drums at the back.
#
# Our own solver, the same school as the darts and the pool table (game/dart_sim.gd): no physics
# engine, plain rigid body steps at 240 a second, the wheels' spin four times as often. Nothing on
# the screen helps the player hold it: what pushes back is the truck and the road.
#
#   the body    a rigid body with a box's inertia, its middle of mass 58% of the way to the front
#   the springs each corner a spring and a damper along the body's own down, softer going in than
#               coming back, bump stops at the ends, a sway bar at the front
#   the tires   grip from slip (a magic-formula curve), more grip with more load but less for each
#               kilo, the friction circle shared between going and turning, the surface under each
#               tire on its own (dry, wet, gravel, grass, a puddle)
#   the engine  a torque curve for the 460, a choke-less idle that hunts a little, friction
#   the gearbox a torque converter (slips, multiplies at stall, couples at speed) into three gears
#               that shift by speed and throttle, a kickdown, P R N D 2 1 on the column
#   the brakes  front discs, rear drums that heat and fade, a pull to the left when wet
#   the air     drag on a brick
#
# Units: metres, kilograms, seconds, radians. Body axes as Godot's: -z ahead, +x right, +y up.
class_name TruckSim
extends RefCounted

const HZ := 240.0
const DT := 1.0 / HZ
const SUB := 4                               # the wheels' spin, steps per body step
const G := 9.81

# the body
const MASS := 2150.0
const DIM := Vector3(2.0, 1.4, 5.6)          # what the inertia's worked out from (a box this size)
const WHEELBASE := 3.38                      # 133 inches
const TRACK_F := 1.68
const TRACK_R := 1.65
const AXLE_F := -1.42                        # the axles from the middle of mass, along the body
const AXLE_R := 1.96
const MOUNT_Y := -0.15                       # the springs' tops, under the middle of mass
const RADIUS := 0.39                         # an 8.00-16.5 tire
const TRAVEL := 0.42                         # spring length, hanging free
const K_F := 60000.0                         # N/m a corner
const K_R := 62000.0
const C_BUMP := 3200.0                       # damping, going in (N s/m)
const C_REBOUND := 5400.0                    # and coming back
const SWAY_F := 14000.0                      # the front sway bar, N/m of difference
const STOP_K := 400000.0                     # the bump stop
const I_FRONT := 2.4                         # a front wheel's spin inertia
const I_REAR := 3.6                          # a rear wheel's, with its share of the axle

# the engine: the 460's torque, N m, at rpm (net, as fitted in 1978: about 220 hp)
const TORQUE := [[0.0, 0.0], [500.0, 260.0], [800.0, 340.0], [1200.0, 400.0], [1800.0, 452.0],
	[2400.0, 478.0], [2800.0, 481.0], [3400.0, 455.0], [4000.0, 400.0], [4500.0, 320.0], [5000.0, 180.0], [5400.0, 0.0]]
const I_ENGINE := 0.38
const IDLE := 640.0
# the C6 and the axle
const GEARS := {"1": 2.46, "2": 1.46, "3": 1.0, "R": -2.18}
const FINAL := 4.10
const DRIVELINE := 0.88                      # what gets through
const TC_K := 0.0121                         # the converter: N m per (rad/s)^2 at stall
const SHIFT_T := 0.38
# the brakes, N m a wheel at the full pedal
const BRAKE_F := 3300.0
const BRAKE_R := 1650.0
const PARK := 6000.0
# the steering
const LOCK := 680.0                          # the wheel's turn either way, degrees (3.8 turns all told)
const RATIO := 20.0                          # wheel degrees to road wheel degrees
const PLAY := 5.0                            # the wheel's dead degrees either side of centre
# the air
const DRAG := 0.5 * 1.2 * 0.62 * 3.4

# surfaces: grip, rolling resistance, bumps (m), name
enum Surf { DRY, WET, GRAVEL, GRASS, PUDDLE, SAND }
const GRIP := {Surf.DRY: 0.95, Surf.WET: 0.72, Surf.GRAVEL: 0.62, Surf.GRASS: 0.42, Surf.PUDDLE: 0.34, Surf.SAND: 0.5}
const ROLL := {Surf.DRY: 0.012, Surf.WET: 0.013, Surf.GRAVEL: 0.03, Surf.GRASS: 0.05, Surf.PUDDLE: 0.03, Surf.SAND: 0.09}

# the ground: a Callable (x, z) -> [height, normal, surface]. Flat dry ground if none.
var ground: Callable
# things to hit: [middle Vector2 (x, z), half size Vector2, turned (radians), top height]
var walls: Array = []

# the body's state
var pos := Vector3(0, RADIUS + 0.47, 0)
var rot := Basis.IDENTITY
var vel := Vector3.ZERO
var spin := Vector3.ZERO                     # angular velocity, world
var _inv_i_body := Vector3.ZERO
var _i_body := Vector3.ZERO

# the wheels: fl, fr, rl, rr
var mount: Array = []                        # where each spring's top is, body local
var length: Array = [TRAVEL, TRAVEL, TRAVEL, TRAVEL]   # each spring, now
var omega: Array = [0.0, 0.0, 0.0, 0.0]     # each wheel's spin, rad/s (+ rolling ahead)
var turn: Array = [0.0, 0.0, 0.0, 0.0]      # angle on the road wheels, radians (+ to the left)
var load: Array = [0.0, 0.0, 0.0, 0.0]      # N on each tire
var slip: Array = [0.0, 0.0, 0.0, 0.0]      # how far past its grip each tire is, 0..1+ (for the sound of it)
var surf: Array = [Surf.DRY, Surf.DRY, Surf.DRY, Surf.DRY]
var touching: Array = [true, true, true, true]
var roll_angle: Array = [0.0, 0.0, 0.0, 0.0]   # each wheel's turn about its axle, for drawing it

# the driver's hands and feet, set from outside each frame
var throttle := 0.0                          # 0..1
var brake := 0.0                             # 0..1
var steer_in := 0.0                          # -1 full left .. 1 full right: where his hands want the wheel
var steer_direct := false                    # a stick or a wheel: the steering wheel goes where it's put
var selector := "P"                          # P R N D 2 1
var running := true
var wet := true                              # it's raining (the island)
var drunk := 0.0                             # 0..1: his hands lag behind what he means, and over-correct

# what the truck is doing, read from outside
var wheel_deg := 0.0                         # the steering wheel, degrees (+ to the left)
var rpm := IDLE
var gear := "1"                              # the gear it's in, in D
var shifting := 0.0
var speed := 0.0                             # along its own nose, m/s
var drum_temp := 40.0                        # the rear drums, deg C
var hit := 0.0                               # the hardest knock this step (m/s into whatever it was)
var hits: Array = []                         # [time, speed, where (world)]
var t := 0.0
var _lag_steer := 0.0
var _wander := 0.0
var _wander_v := 0.0
var _rng := RandomNumberGenerator.new()
var _converter_t := 0.0                      # turbine torque, last step (for reading)
var odometer := 0.0                          # metres since it was put down


func _init() -> void:
	_rng.seed = 1978
	var m := MASS / 12.0
	_i_body = Vector3(m * (DIM.y * DIM.y + DIM.z * DIM.z), m * (DIM.x * DIM.x + DIM.z * DIM.z) * 1.05, m * (DIM.x * DIM.x + DIM.y * DIM.y))
	_inv_i_body = Vector3(1.0 / _i_body.x, 1.0 / _i_body.y, 1.0 / _i_body.z)
	mount = [Vector3(-TRACK_F / 2.0, MOUNT_Y, AXLE_F), Vector3(TRACK_F / 2.0, MOUNT_Y, AXLE_F),
		Vector3(-TRACK_R / 2.0, MOUNT_Y, AXLE_R), Vector3(TRACK_R / 2.0, MOUNT_Y, AXLE_R)]


# Put it down somewhere, still, nose toward `yaw` (radians about +y; 0 = facing -z), its wheels on
# the ground.
func place(at: Vector3, yaw: float) -> void:
	rot = Basis(Vector3.UP, yaw)
	var h: float = _ground(at.x, at.z)[0]
	pos = Vector3(at.x, h + RADIUS + 0.47 - MOUNT_Y - 0.15, at.z)
	vel = Vector3.ZERO
	spin = Vector3.ZERO
	for i in 4:
		omega[i] = 0.0
		length[i] = TRAVEL - 0.1
	# let it settle on its springs
	var keep := [throttle, brake, selector]
	selector = "P"
	throttle = 0.0
	brake = 1.0
	for n in 240:
		step()
	throttle = keep[0]
	brake = keep[1]
	selector = keep[2]
	t = 0.0
	hits.clear()
	odometer = 0.0


func _ground(x: float, z: float) -> Array:
	if ground.is_valid():
		return ground.call(x, z)
	return [0.0, Vector3.UP, Surf.WET if wet else Surf.DRY]


func yaw() -> float:
	var f := -rot.z
	return atan2(-f.x, -f.z)


func forward() -> Vector3:
	return -rot.z


func kmh() -> float:
	return speed * 3.6


# ---------------------------------------------------------------- one step

func step() -> void:
	t += DT
	hit = 0.0
	_steering()
	var f_total := Vector3(0, -G * MASS, 0)
	var tq_total := Vector3.ZERO
	var down := -rot.y
	var fwd_body := -rot.z
	speed = vel.dot(fwd_body)
	# the springs
	var comp: Array = [0.0, 0.0, 0.0, 0.0]
	var contact: Array = []
	var normal: Array = []
	for i in 4:
		var p: Vector3 = pos + rot * (mount[i] as Vector3)
		var gq := _ground(p.x, p.z)
		var gh: float = gq[0]
		var n: Vector3 = gq[1]
		surf[i] = gq[2]
		var nd := n.dot(down)
		var s := TRAVEL + RADIUS
		if nd < -0.2:
			s = n.dot(Vector3(p.x, gh, p.z) - p) / nd
		var l := s - RADIUS
		touching[i] = l < TRAVEL
		length[i] = clampf(l, 0.0, TRAVEL)
		comp[i] = TRAVEL - length[i]
		contact.append(p + down * (length[i] + RADIUS))
		normal.append(n)
	for i in 4:
		load[i] = 0.0
		if not touching[i]:
			continue
		var p: Vector3 = pos + rot * (mount[i] as Vector3)
		var r: Vector3 = p - pos
		var pv := vel + spin.cross(r)
		var rate := pv.dot(down)                # + going in
		var k: float = K_F if i < 2 else K_R
		var fz: float = k * comp[i] + (C_BUMP if rate > 0.0 else C_REBOUND) * rate
		if comp[i] > TRAVEL - 0.05:
			fz += STOP_K * (comp[i] - (TRAVEL - 0.05))
		if i < 2:
			fz += SWAY_F * (comp[i] - comp[1 - i])
		fz = maxf(fz, 0.0)
		load[i] = fz
		var fs: Vector3 = -down * fz
		f_total += fs
		tq_total += r.cross(fs)
	# the engine and the gearbox, and the tires, a few times over for the wheels' spin
	var tire_f: Array = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var frames: Array = []
	for i in 4:
		if not touching[i]:
			frames.append(null)
			continue
		var n: Vector3 = normal[i]
		var a: float = turn[i]
		var fw: Vector3 = (rot * Vector3(-sin(a), 0.0, -cos(a)))
		fw = (fw - n * fw.dot(n)).normalized()
		var right := fw.cross(n).normalized()
		var c: Vector3 = contact[i]
		var cv := vel + spin.cross(c - pos)
		frames.append([fw, right, cv.dot(fw), cv.dot(right)])
	var sub_dt := DT / float(SUB)
	for s in SUB:
		var drive := _drivetrain(sub_dt)
		for i in 4:
			var fr = frames[i]
			var tb: float = _brake_torque(i)
			var inertia: float = I_FRONT if i < 2 else I_REAR + _reflected()
			if fr == null:
				# in the air: the drive spins it, the brake stops it
				omega[i] += (drive if i >= 2 else 0.0) / inertia * sub_dt
				omega[i] = _apply_brake(omega[i], tb, inertia, sub_dt)
				continue
			var vx: float = fr[2]
			var vy: float = fr[3]
			var mu: float = GRIP[surf[i]] * (1.0 - 0.08 * (load[i] / 5300.0 - 1.0))
			var fmax: float = mu * load[i]
			var denom: float = maxf(absf(vx), 3.0)
			var kappa: float = (omega[i] * RADIUS - vx) / denom
			var alpha: float = atan2(vy, maxf(absf(vx), 0.8))
			var fx: float = fmax * _curve(kappa, 10.0, 1.65, 0.2)
			var fy: float = -fmax * _curve(alpha, 7.5, 1.35, 0.05)
			# the friction circle
			var mag: float = sqrt(fx * fx + fy * fy)
			slip[i] = mag / maxf(fmax, 1.0)
			if mag > fmax and mag > 0.0:
				fx *= fmax / mag
				fy *= fmax / mag
			# slow, it can't push a corner sideways past standing still in one step
			var corner: float = MASS * (0.29 if i < 2 else 0.21)
			fy = clampf(fy, -absf(vy) * corner / DT, absf(vy) * corner / DT)
			# rolling resistance
			fx -= ROLL[surf[i]] * load[i] * tanh(vx * 2.0)
			var wheel_t: float = (drive if i >= 2 else 0.0) - fx * RADIUS
			omega[i] += wheel_t / inertia * sub_dt
			omega[i] = _apply_brake(omega[i], tb, inertia, sub_dt)
			tire_f[i] += ((fr[0] as Vector3) * fx + (fr[1] as Vector3) * fy) / float(SUB)
	for i in 4:
		if frames[i] == null:
			continue
		var c: Vector3 = contact[i]
		f_total += tire_f[i]
		tq_total += (c - pos).cross(tire_f[i])
		roll_angle[i] = fmod(roll_angle[i] + omega[i] * DT, TAU)
	# the air
	f_total -= vel * vel.length() * DRAG
	# integrate
	vel += f_total / MASS * DT
	var inv_w := rot * Basis.from_scale(_inv_i_body) * rot.transposed()
	var i_w := rot * Basis.from_scale(_i_body) * rot.transposed()
	spin += inv_w * (tq_total - spin.cross(i_w * spin)) * DT
	pos += vel * DT
	odometer += absf(speed) * DT
	var w := spin.length()
	if w > 1e-7:
		rot = Basis(spin / w, w * DT) * rot
	rot = rot.orthonormalized()
	_collide()
	_brakes_heat()


# ---------------------------------------------------------------- his hands on the wheel

func _steering() -> void:
	var v := absf(speed)
	# drink: the hands are late, and when they catch up they go too far
	var target := steer_in
	if drunk > 0.0:
		var lag := lerpf(30.0, 3.0, drunk)
		_lag_steer += (steer_in - _lag_steer) * minf(1.0, lag * DT)
		target = _lag_steer + (_lag_steer - steer_in) * -0.6 * drunk
	var want := -target * LOCK
	if steer_direct:
		wheel_deg = move_toward(wheel_deg, want, 1400.0 * DT)
	elif absf(target) > 0.01:
		# the keys: the wheel goes round as fast as hands go round a wheel, slower at speed
		var rate := 520.0 / (1.0 + v / 14.0)
		wheel_deg = move_toward(wheel_deg, want, rate * DT * (1.0 + absf(target)))
	else:
		# hands loose, the castor brings it back, faster at speed
		wheel_deg = move_toward(wheel_deg, 0.0, (40.0 + v * 22.0) * DT)
	wheel_deg = clampf(wheel_deg, -LOCK, LOCK)
	# the play on centre, and the wander: the front end's worn
	var eff := 0.0
	if absf(wheel_deg) > PLAY:
		eff = wheel_deg - signf(wheel_deg) * PLAY
	_wander_v += (_rng.randf_range(-1.0, 1.0) * 6.0 - _wander * 0.8 - _wander_v * 1.2) * DT
	_wander += _wander_v * DT
	var road := deg_to_rad(eff / RATIO) + deg_to_rad(_wander * 0.22) * clampf(v / 20.0, 0.0, 1.0)
	# Ackermann: the inside wheel turns more
	if absf(road) < 0.0005:
		turn[0] = road
		turn[1] = road
	else:
		var r := WHEELBASE / tan(absf(road))
		var inner := atan(WHEELBASE / maxf(r - TRACK_F / 2.0, 0.3))
		var outer := atan(WHEELBASE / (r + TRACK_F / 2.0))
		if road > 0.0:         # to the left: the left wheel's inside
			turn[0] = inner
			turn[1] = outer
		else:
			turn[0] = -outer
			turn[1] = -inner


# ---------------------------------------------------------------- the engine, the converter, the gears

func engine_torque(r: float) -> float:
	r = clampf(r, 0.0, 5400.0)
	for i in range(1, TORQUE.size()):
		if r <= TORQUE[i][0]:
			var a: Array = TORQUE[i - 1]
			var b: Array = TORQUE[i]
			return lerpf(a[1], b[1], (r - a[0]) / (b[0] - a[0]))
	return 0.0


func ratio() -> float:
	match selector:
		"R":
			return GEARS["R"]
		"D", "2", "1":
			return GEARS[gear]
	return 0.0


func _reflected() -> float:
	var g := ratio() * FINAL
	return 0.06 * g * g / 2.0


func _auto_shift() -> void:
	if shifting > 0.0:
		return
	var v := kmh()
	var th := throttle
	var want := gear
	match selector:
		"1":
			want = "1"
		"2":
			want = "2" if gear != "1" or v > 50.0 else "1"
			if gear == "1" and v > 22.0 + 40.0 * th:
				want = "2"
		"D":
			match gear:
				"1":
					if v > 22.0 + 42.0 * th:
						want = "2"
				"2":
					if v > 44.0 + 56.0 * th:
						want = "3"
					elif v < 10.0 + 14.0 * th or (th > 0.92 and v < 38.0):
						want = "1"
				"3":
					if v < 28.0 + 26.0 * th or (th > 0.9 and v < 82.0):
						want = "2"
		_:
			want = "1"
	if want != gear:
		gear = want
		shifting = SHIFT_T


# a sub step of the drivetrain: the engine's spin, the converter, the torque out to each rear wheel
func _drivetrain(dt: float) -> float:
	_auto_shift()
	if shifting > 0.0:
		shifting = maxf(0.0, shifting - dt)
	var we := rpm * TAU / 60.0
	var g := ratio() * FINAL
	var wt: float = (omega[2] + omega[3]) / 2.0 * g
	var tp: float = 0.0
	var tt: float = 0.0
	if g != 0.0:
		var sr: float = wt / maxf(we, 1.0)
		var k: float = TC_K * (1.0 + 6.0 * pow(clampf(sr, 0.0, 1.0), 4.0))
		tp = k * maxf(absf(we), absf(wt)) * (we - wt)
		var tr: float = lerpf(2.1, 1.0, clampf(sr / 0.85, 0.0, 1.0)) if tp > 0.0 else 1.0
		tt = tp * tr
	else:
		tp = 0.02 * we     # the pump turning in its own oil
	# the engine: what the throttle gives, what friction takes, the idle's own air
	var th := throttle if running else 0.0
	var idle_th := clampf((IDLE - rpm) / 300.0, 0.0, 0.35) + 0.035
	idle_th += sin(t * 2.3) * 0.004            # it hunts a little: an old carburetor
	var open := clampf(maxf(th, idle_th if running else 0.0), 0.0, 1.0)
	var te := engine_torque(rpm) * open - (18.0 + 0.011 * rpm + 0.0000035 * rpm * rpm) * (1.0 - open * 0.6)
	if not running:
		te = -(30.0 + 0.02 * rpm)
	we += (te - tp) / I_ENGINE * dt
	if not running:
		we = maxf(we, 0.0)
	we = clampf(we, 0.0, 5600.0 * TAU / 60.0)
	rpm = we * 60.0 / TAU
	_converter_t = tt
	var cut := 0.55 if shifting > 0.0 else 1.0
	return tt * g * DRIVELINE * cut / 2.0


# ---------------------------------------------------------------- the brakes

func _brake_torque(i: int) -> float:
	var tb: float = 0.0
	if i < 2:
		tb = BRAKE_F * brake
		if i == 0 and wet:
			tb *= 1.08                          # the left front grabs in the wet
	else:
		var fade := 1.0 - clampf((drum_temp - 220.0) / 300.0, 0.0, 0.5)
		tb = BRAKE_R * brake * fade
		if selector == "P":
			tb += PARK
	return tb


func _apply_brake(w: float, tb: float, inertia: float, dt: float) -> float:
	if tb <= 0.0:
		return w
	var dw := tb / inertia * dt
	if absf(w) <= dw:
		return 0.0
	return w - signf(w) * dw


func _brakes_heat() -> void:
	var work := BRAKE_R * brake * (absf(omega[2]) + absf(omega[3]))
	drum_temp += work * DT / 1800.0
	drum_temp -= (drum_temp - 12.0) * (0.004 + absf(speed) * 0.0003) * DT


# ---------------------------------------------------------------- the tires' curve

static func _curve(s: float, b: float, c: float, e: float) -> float:
	var bs := b * s
	return sin(c * atan(bs - e * (bs - atan(bs))))


# ---------------------------------------------------------------- what it hits

const HALF := Vector2(1.0, 2.8)               # the truck's footprint, half (x, z), bumpers and all

func _collide() -> void:
	if walls.is_empty():
		return
	var c := Vector2(pos.x, pos.z)
	var f := Vector2(-rot.z.x, -rot.z.z).normalized()
	var r := Vector2(-f.y, f.x)        # perpendicular, its right in x z
	for w in walls:
		var top: float = w[3]
		if pos.y - 0.55 > top:
			continue
		var wc: Vector2 = w[0]
		if wc.distance_squared_to(c) > 64.0 + (w[1] as Vector2).length_squared() * 2.0:
			continue
		var a: float = w[2]
		var wx := Vector2(cos(a), sin(a))
		var wz := Vector2(-sin(a), cos(a))
		var wh: Vector2 = w[1]
		# separating axes: the truck's two, the wall's two
		var best := INF
		var axis := Vector2.ZERO
		var hit_it := true
		for ax in [r, f, wx, wz]:
			var p1 := absf(r.dot(ax)) * HALF.x + absf(f.dot(ax)) * HALF.y
			var p2 := absf(wx.dot(ax)) * wh.x + absf(wz.dot(ax)) * wh.y
			var d := (wc - c).dot(ax)
			var over := p1 + p2 - absf(d)
			if over <= 0.0:
				hit_it = false
				break
			if over < best:
				best = over
				axis = ax * (-1.0 if d > 0.0 else 1.0)    # push the truck away from the wall
		if not hit_it:
			continue
		var n3 := Vector3(axis.x, 0.0, axis.y)
		pos += n3 * best
		# where it touched: the truck's corner deepest into the wall, near enough
		var corner: Vector2 = c
		var deepest := INF
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var q: Vector2 = c + r * HALF.x * float(sx) + f * HALF.y * float(sz)
				var d: float = (q - c).dot(axis)
				if d < deepest:
					deepest = d
					corner = q
		var arm := Vector3(corner.x - pos.x, 0.0, corner.y - pos.z)
		var pv := vel + spin.cross(arm)
		var into := pv.dot(n3)
		if into < 0.0:
			var rn := arm.cross(n3)
			var inv := 1.0 / MASS + rn.y * rn.y / _i_body.y
			var j := -(1.0 + 0.15) * into / inv
			vel += n3 * j / MASS
			spin.y += rn.y * j / _i_body.y
			# and the scrape along it
			var tang := pv - n3 * into
			tang.y = 0.0
			vel -= tang * minf(1.0, 0.4 * j / MASS / maxf(tang.length(), 0.01))
			hit = maxf(hit, -into)
			if -into > 0.8:
				hits.append([t, -into, Vector3(corner.x, pos.y, corner.y)])
