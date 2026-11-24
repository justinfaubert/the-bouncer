extends SceneTree
# The truck on the island road (game/truck_sim.gd on world/island_road.gd), driven by a plain lane
# keeper the way a careful driver would: out of the Sov's lot, onto the highway, north in the right
# lane over the bluff and down past the fish plant to the barricade at the washout; round, and all
# the way south past the Sov, up through the cut and down to the bridge that's out. The wheels must
# stay on the ground the whole way (no falling through it, no flying off a seam), nothing goes
# NaN, the barricades stop it, and the road's line, heights and the ground beside it agree.
# Headless:
#   godot --headless --path godot -s res://tests/truck_road.gd

var bad := 0
var road: IslandRoad
var s: TruckSim


func _init() -> void:
	road = IslandRoad.new()
	road._sov_walls()
	_line()
	s = TruckSim.new()
	s.ground = road.ground
	s.walls = []
	s.place(Truck.PARK_AT, PI)
	s.selector = "D"
	s.running = true
	s.keys_cap = false     # the lane keeper works the wheel itself, to the degree
	print("  the road: %.0f m north of the Sov's door, %.0f m south" % [road.length_n(), road.length_s()])
	_out_of_the_lot()
	_drive(1.0, IslandRoad.WASHOUT, "north to the washout")
	# from the barricade, put it down facing south in the south lane and go
	var here: Array = road.at_dist(IslandRoad.WASHOUT - 30.0)
	var hd: Vector3 = here[1]
	s.place((here[0] as Vector3) + Vector3(hd.z, 0.0, -hd.x) * 1.9, atan2(hd.x, hd.z))
	s.selector = "D"
	_drive(-1.0, IslandRoad.BRIDGE_OUT, "south to the bridge")
	print("truck_road: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)


func check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  BAD  ") + what)
	if not ok:
		bad += 1


func _line() -> void:
	var worst := 0.0
	for i in range(1, road.pts.size()):
		var a := road.pts[i - 1]
		var b := road.pts[i]
		worst = maxf(worst, absf(b.y - a.y) / IslandRoad.STEP)
	check(worst < 0.1, "no grade on the road steeper than 10%% (steepest %.1f%%)" % (worst * 100.0))
	var d := road.along(Vector3(3.2, 0, IslandRoad.SOV_Z))
	check(absf(float(d[1])) < 0.2, "the line runs down the middle of the Sov's stretch (%.2f m off)" % float(d[1]))
	# the ground's the same either side of where the Sov's stretch ends
	for x in [IslandRoad.SOV_X.x, IslandRoad.SOV_X.y]:
		var h0 := road.height(x - 0.5, IslandRoad.SOV_Z + 2.0)
		var h1 := road.height(x + 0.5, IslandRoad.SOV_Z + 2.0)
		check(absf(h0 - h1) < 0.1, "no step in the road where the Sov's stretch ends at x %.0f (%.3f m)" % [x, absf(h0 - h1)])


func _lap(secs: float, fn: Callable) -> void:
	for n in int(secs * TruckSim.HZ):
		fn.call()
		s.walls = road.walls_near(s.pos, 22.0)
		s.step()


# out of the lot: ease forward and turn left onto the highway (north, the east lane)
func _out_of_the_lot() -> void:
	_lap(8.0, func():
		_steer_to(Vector3(30.0, 0.0, 33.5), 5.0))
	var a := road.along(s.pos)
	check(s.pos.z > 26.0, "out of the lot and onto the highway (z %.1f, %.1f m from the line)" % [s.pos.z, float(a[1])])


func _steer_to(target: Vector3, kmh: float) -> void:
	var local := s.rot.inverse() * (target - s.pos)
	var alpha := atan2(local.x, -local.z)
	var ld := maxf(Vector2(local.x, local.z).length(), 4.0)
	var delta := atan(2.0 * TruckSim.WHEELBASE * sin(alpha) / ld)
	var wheel := rad_to_deg(delta) * TruckSim.RATIO
	wheel += signf(wheel) * TruckSim.PLAY
	s.steer_direct = true
	s.steer_in = clampf(wheel / TruckSim.LOCK, -1.0, 1.0)
	var err := kmh - s.kmh()
	s.throttle = clampf(err * 0.08, 0.0, 0.8)
	s.brake = clampf(-err * 0.05, 0.0, 0.6)


func _drive(dir: float, to: float, what: String) -> void:
	var lowest := INF
	var highest := -INF
	var off_road := 0
	var worst_air := 0.0
	var air := 0.0
	var t0 := s.t
	var reached := false
	var max_u := 0.0
	var start := float(road.along(s.pos)[0]) - road.zero
	var where_worst := 0.0
	while s.t < t0 + 600.0:
		var a := road.along(s.pos)
		var me := float(a[0]) - road.zero
		var u := float(a[1])
		# the lane: right of the line going his way
		var ahead := road.at_dist(me + dir * maxf(10.0, absf(s.speed) * 1.1))
		var p: Vector3 = ahead[0]
		var dv: Vector3 = ahead[1]
		var side := Vector3(-dv.z, 0.0, dv.x) * dir
		var target := p + side * 1.9
		# slow for the curves, as a man does
		var c0: Vector3 = road.at_dist(me)[1]
		var c1: Vector3 = road.at_dist(me + dir * 60.0)[1]
		var bend := c0.angle_to(c1)
		var want := clampf(80.0 - bend * 180.0, 40.0, 80.0)
		_steer_to(target, want)
		s.walls = road.walls_near(s.pos, 22.0)
		s.step()
		var gh := road.height(s.pos.x, s.pos.z)
		var up := s.pos.y - gh
		lowest = minf(lowest, up)
		highest = maxf(highest, up)
		if OS.has_environment("TRACE") and absf(me - 380.0) < 60.0 and int(s.t * 240.0) % 60 == 0:
			print("    me %.0f u %.2f kmh %.0f hit %.2f pos %s" % [me, u, s.kmh(), s.hit, s.pos])
		if (me - to) * dir < -80.0 and absf(me - start) > 120.0:
			if absf(u - 1.9 * dir) > max_u:
				max_u = absf(u - 1.9 * dir)
				where_worst = me
		var any := false
		for i in 4:
			if s.touching[i]:
				any = true
		air = 0.0 if any else air + TruckSim.DT
		worst_air = maxf(worst_air, air)
		if (me - to) * dir > -22.0 and absf(s.speed) < 0.5:
			reached = true
			break
		if not is_finite(s.pos.x):
			break
	var me2 := float(road.along(s.pos)[0]) - road.zero
	check(is_finite(s.pos.x) and is_finite(s.vel.length()), what + ": stays finite")
	check(lowest > 0.45 and highest < 1.4, what + ": the body rides at a truck's height over the ground the whole way (%.2f to %.2f m)" % [lowest, highest])
	check(worst_air < 0.25, what + ": no wheel off the ground for long (all four up %.2f s at most)" % worst_air)
	check(max_u < 2.6, what + ": stays in its lane (%.2f m from the lane's middle at worst, %.0f m from the door)" % [max_u, where_worst])
	check(reached, what + ": gets there and stops at the barricade (%.0f m from the Sov's door, %.0f s)" % [me2, s.t - t0])


func _turn_round() -> void:
	# back up, a three-point turn across both lanes
	s.steer_direct = true
	_lap(4.0, func():
		s.selector = "D"
		s.steer_in = -1.0
		s.throttle = 0.25 if s.kmh() < 6.0 else 0.0
		s.brake = 0.0)
	_lap(2.0, func():
		s.throttle = 0.0
		s.brake = 1.0)
	s.selector = "R"
	_lap(4.0, func():
		s.steer_in = 1.0
		s.brake = 0.0
		s.throttle = 0.25 if absf(s.kmh()) < 6.0 else 0.0)
	_lap(2.0, func():
		s.throttle = 0.0
		s.brake = 1.0)
	s.selector = "D"
	_lap(5.0, func():
		s.steer_in = -1.0
		s.brake = 0.0
		s.throttle = 0.25 if s.kmh() < 6.0 else 0.0)
	var f := s.forward()
	var dir: Vector3 = road.at_dist(float(road.along(s.pos)[0]) - road.zero)[1]
	print("    a three-point turn at the barricade: facing %.2f along the road after it" % f.dot(dir))
