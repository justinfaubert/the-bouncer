extends SceneTree
# The truck's physics against what a 1978 F-250 with a 460 and a C6 does (game/truck_sim.gd): it
# sits level on its springs, idles where it should, pulls away in D, gets to 100 in about thirteen
# seconds and tops out somewhere past 150, shifts 1-2-3 and kicks down, stops from 100 in the wet in
# about fifty metres, turns a circle the size it should, slides when it's pushed past its grip and
# doesn't fly off or spin up, backs up in R, holds in P on a hill, fades its drums on a long hill, and
# stops at a wall. Prints numbers; fails (exit 1) where they leave what's real.
#   godot --headless --path godot -s res://tests/truck_sim.gd

var bad := 0


func _init() -> void:
	_rest()
	_pull()
	_brake()
	_circle()
	_slide()
	_keys()
	_reverse()
	_hill()
	_wall()
	print("truck_sim: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)


func check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  BAD  ") + what)
	if not ok:
		bad += 1


func run(s: TruckSim, secs: float) -> void:
	for n in int(secs * TruckSim.HZ):
		s.step()


func finite(s: TruckSim) -> bool:
	return is_finite(s.pos.x) and is_finite(s.pos.y) and is_finite(s.vel.length()) and is_finite(s.rpm)


func _rest() -> void:
	var s := TruckSim.new()
	s.place(Vector3.ZERO, 0.0)
	run(s, 3.0)
	var tilt := rad_to_deg(acos(clampf(s.rot.y.dot(Vector3.UP), -1.0, 1.0)))
	check(tilt < 1.5, "sits level at rest (%.2f deg)" % tilt)
	check(s.vel.length() < 0.02, "still at rest (%.3f m/s)" % s.vel.length())
	check(absf(s.rpm - TruckSim.IDLE) < 120.0, "idles at about %d rpm (%d)" % [TruckSim.IDLE, s.rpm])
	var fl: float = s.load[0] + s.load[1]
	var share: float = fl / (fl + float(s.load[2]) + float(s.load[3]))
	check(share > 0.53 and share < 0.62, "front carries %.0f%% of it" % (share * 100.0))
	print("    ride height: middle of mass %.2f m up" % s.pos.y)


func _pull() -> void:
	var s := TruckSim.new()
	s.wet = false
	s.place(Vector3.ZERO, 0.0)
	s.selector = "D"
	s.brake = 0.0
	s.throttle = 1.0
	var t100 := -1.0
	var t60 := -1.0
	var gears := ""
	var off := -1.0
	for n in int(40.0 * TruckSim.HZ):
		s.step()
		if off < 0.0 and s.pos.z < -250.0:
			off = absf(s.pos.x)
		if not gears.ends_with(s.gear):
			gears += s.gear
		if t60 < 0.0 and s.kmh() >= 60.0:
			t60 = s.t
		if t100 < 0.0 and s.kmh() >= 100.0:
			t100 = s.t
	check(finite(s), "stays finite flat out")
	check(t60 > 4.0 and t60 < 8.5, "0-60 km/h in %.1f s" % t60)
	check(t100 > 9.5 and t100 < 17.0, "0-100 km/h in %.1f s" % t100)
	check(s.kmh() > 140.0 and s.kmh() < 175.0, "after 40 s flat out: %.0f km/h at %d rpm" % [s.kmh(), s.rpm])
	check(gears == "123", "shifts through the gears in order (%s)" % gears)
	check(off < 2.5, "wanders but runs near straight with hands off (%.2f m off line after 250 m)" % off)
	# kickdown: cruising in third at 70, floor it
	s.throttle = 0.25
	s.brake = 0.4
	for n in int(30.0 * TruckSim.HZ):
		s.step()
		s.brake = 0.4 if s.kmh() > 70.0 else 0.0
		s.throttle = 0.0 if s.kmh() > 70.0 else 0.3
	var before := s.gear
	s.brake = 0.0
	s.throttle = 1.0
	run(s, 0.3)
	check(before == "3" and s.gear == "2", "kicks down from third to second at 70 floored (%s to %s)" % [before, s.gear])


func _brake() -> void:
	for wet in [false, true]:
		var best := INF
		var locked := 0.0
		for pedal in [0.45, 0.55, 0.65, 0.75, 0.85, 1.0]:
			var r := _stop(wet, pedal)
			best = minf(best, r[0])
			if pedal == 1.0:
				locked = r[0]
				if not wet:
					check(r[1] < 1.5, "stops straight dry on the full pedal (%.2f m)" % r[1])
				else:
					print("    the wet pull to the left: %.2f m off line" % r[2])
		if wet:
			check(best > 45.0 and best < 72.0, "stops from 100 in the wet in %.0f m at best (%.0f m locked up)" % [best, locked])
		else:
			check(best > 38.0 and best < 58.0, "stops from 100 dry in %.0f m at best (%.0f m locked up)" % [best, locked])
		check(locked > best + 3.0, "no ABS: standing on it locks them and takes longer (%s)" % ("wet" if wet else "dry"))


func _stop(wet: bool, pedal: float) -> Array:
	if true:
		var s := TruckSim.new()
		s.wet = wet
		s.place(Vector3.ZERO, 0.0)
		s.selector = "D"
		s.brake = 0.0
		s.throttle = 1.0
		while s.kmh() < 100.0 and s.t < 30.0:
			s.step()
		s.throttle = 0.0
		s.brake = pedal
		var z0: float = s.pos.z
		var t0 := s.t
		while s.kmh() > 0.5 and s.t < t0 + 15.0:
			s.step()
		return [absf(s.pos.z - z0), absf(s.pos.x), s.pos.x]
	return []


func _circle() -> void:
	var s := TruckSim.new()
	s.wet = false
	s.place(Vector3.ZERO, 0.0)
	s.selector = "D"
	s.brake = 0.0
	s.steer_direct = true
	s.steer_in = -1.0
	s.throttle = 0.12
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for n in int(30.0 * TruckSim.HZ):
		s.step()
		s.throttle = 0.12 if s.kmh() < 8.0 else 0.0
		if s.t > 6.0:
			lo = lo.min(Vector2(s.pos.x, s.pos.z))
			hi = hi.max(Vector2(s.pos.x, s.pos.z))
	var dia := ((hi - lo).x + (hi - lo).y) / 2.0
	# a long-bed F-250's turning circle is about 14 m kerb to kerb; its middle of mass a little less
	check(dia > 10.0 and dia < 17.0, "full lock at walking pace turns a %.1f m circle" % dia)


func _slide() -> void:
	var s := TruckSim.new()
	s.wet = true
	s.place(Vector3.ZERO, 0.0)
	s.selector = "D"
	s.brake = 0.0
	s.throttle = 1.0
	while s.kmh() < 90.0 and s.t < 30.0:
		s.step()
	s.throttle = 0.0
	s.steer_direct = true
	s.steer_in = 0.5
	var max_spin := 0.0
	var max_lat := 0.0
	for n in int(4.0 * TruckSim.HZ):
		s.step()
		max_spin = maxf(max_spin, absf(s.spin.y))
		var lat := absf(s.vel.dot(s.rot.x))
		max_lat = maxf(max_lat, lat)
	check(finite(s), "stays finite through a wet swerve at 90")
	check(s.pos.y < 3.0 and s.pos.y > 0.3, "stays on the ground (%.2f m)" % s.pos.y)
	check(max_spin < 3.0, "yaw rate stays a truck's (%.2f rad/s)" % max_spin)
	check(max_lat > 1.0, "the back steps out when he yanks it at 90 in the wet (%.1f m/s sideways)" % max_lat)
	var up: float = s.rot.y.dot(Vector3.UP)
	check(up > 0.5, "doesn't roll over on a flat road (up %.2f)" % up)


# the keys at speed: a tap is a lane change, held it's a hard turn but not a spin, and at a crawl
# they still find full lock
func _keys() -> void:
	for case in ["tap", "hold"]:
		var s := TruckSim.new()
		s.wet = false
		s.place(Vector3.ZERO, 0.0)
		s.selector = "D"
		s.throttle = 1.0
		while s.kmh() < 90.0 and s.t < 30.0:
			s.step()
		s.throttle = 0.3
		var y0 := s.yaw()
		var max_spin := 0.0
		var max_slip := 0.0
		var max_g := 0.0
		var v0 := s.vel
		for n in int(3.0 * TruckSim.HZ):
			s.steer_direct = false
			s.steer_in = -1.0 if (case == "hold" or n < int(0.3 * TruckSim.HZ)) else 0.0
			s.step()
			max_spin = maxf(max_spin, absf(s.spin.y))
			max_slip = maxf(max_slip, absf(s.vel.dot(s.rot.x)))
			max_g = maxf(max_g, ((s.vel - v0) * TruckSim.HZ).length())
			v0 = s.vel
		var turned := absf(rad_to_deg(wrapf(s.yaw() - y0, -PI, PI)))
		if case == "tap":
			check(turned > 1.0 and turned < 20.0, "a tap of the key at 90 turns it %.1f degrees: a lane change, not a swerve" % turned)
		else:
			check(max_spin < 0.75 and max_slip < 3.0, "holding a key at 90 turns it hard but doesn't spin it (yaw %.2f rad/s, %.1f m/s sideways)" % [max_spin, max_slip])
	var c := TruckSim.new()
	c.place(Vector3.ZERO, 0.0)
	c.selector = "D"
	c.throttle = 0.1
	for n in int(4.0 * TruckSim.HZ):
		c.throttle = 0.1 if c.kmh() < 5.0 else 0.0
		c.steer_direct = false
		c.steer_in = 1.0
		c.step()
	check(absf(c.wheel_deg) > TruckSim.LOCK * 0.95, "at a crawl the keys still find full lock (%.0f of %.0f degrees)" % [absf(c.wheel_deg), TruckSim.LOCK])


func _reverse() -> void:
	var s := TruckSim.new()
	s.place(Vector3.ZERO, 0.0)
	s.selector = "R"
	s.brake = 0.0
	s.throttle = 0.3
	run(s, 4.0)
	check(s.pos.z > 2.0, "backs up in R (%.1f m)" % s.pos.z)


func _hill() -> void:
	var s := TruckSim.new()
	s.ground = func(x: float, z: float) -> Array:
		return [-z * 0.12, Vector3(0, 1, 0.12).normalized(), TruckSim.Surf.WET]
	s.place(Vector3.ZERO, 0.0)
	s.selector = "P"
	s.brake = 0.0
	s.throttle = 0.0
	var z0: float = s.pos.z
	run(s, 5.0)
	check(absf(s.pos.z - z0) < 0.5, "holds in P on a 12%% hill (%.2f m)" % absf(s.pos.z - z0))
	# down a long hill on the brakes: the drums heat and fade
	var d := TruckSim.new()
	d.ground = func(x: float, z: float) -> Array:
		return [z * 0.08, Vector3(0, 1, -0.08).normalized(), TruckSim.Surf.DRY]
	d.place(Vector3.ZERO, 0.0)
	d.selector = "D"
	d.brake = 0.0
	for n in int(120.0 * TruckSim.HZ):
		d.step()
		d.brake = 0.45 if d.kmh() > 60.0 else 0.0
	check(d.drum_temp > 200.0, "the drums heat holding 60 down an 8%% hill for two minutes (%.0f C)" % d.drum_temp)


func _wall() -> void:
	var s := TruckSim.new()
	s.walls = [[Vector2(0, -30), Vector2(6, 0.3), 0.0, 1.0]]
	s.place(Vector3.ZERO, 0.0)
	s.selector = "D"
	s.brake = 0.0
	s.throttle = 0.5
	run(s, 8.0)
	check(s.pos.z > -30.0 + 0.3 + 2.8 - 0.3, "stops at a wall, not through it (nose at %.2f)" % (s.pos.z - 2.8))
	check(not s.hits.is_empty(), "the knock is heard (%d)" % s.hits.size())
	check(finite(s), "stays finite against a wall")
