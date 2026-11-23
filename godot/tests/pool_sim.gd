extends SceneTree
# The pool physics against what real balls do (game/pool_sim.gd): how far a rolling ball goes, stun,
# draw and follow, the 30-degree rule, cut-induced throw, the cushion, squirt, swerve and masse, the
# jump, a straight shot into a pocket and one onto the point of the jaw, the break, and the same shot
# twice. Prints numbers; fails (exit 1) where they leave what's real.
#   godot --headless --path godot -s res://tests/pool_sim.gd

var bad := 0
const HOUSE := {"M": 0.54, "end": 0.0075, "e": 0.75, "limit": 0.55}


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	_roll()
	_stun_draw_follow()
	_thirty()
	_throw()
	_cushion()
	_squirt()
	_masse()
	_jump()
	_pockets()
	_break()
	_lean()
	print("pool_sim: %s (%d ms)" % ["ok" if bad == 0 else "%d bad" % bad, Time.get_ticks_msec() - t0])
	quit(1 if bad else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		bad += 1
		print("  BAD: " + what)


func level() -> PoolSim.Table:
	return PoolSim.good_table(false)


# a ball set going with a speed and a spin, no cue: rolling from the start
func rolling(s: PoolSim, b, v: Vector3) -> void:
	b.v = v
	b.w = Vector3.UP.cross(v) / b.r


func _roll() -> void:
	print("A ball rolling at 1 m/s on a level table")
	var s := PoolSim.new(level())
	var b := s.add_ball(0, Vector3(-0.9, 0, 0), true)
	rolling(s, b, Vector3(0.5, 0, 0))
	s.run()
	var went: float = b.p.x + 0.9
	var want := 0.25 / (2.0 * s.table.mu_r * PoolSim.G)
	print("  0.5 m/s went %.3f m (v^2/2ug says %.3f), stopped at %.2f s" % [went, want, s.t])
	check(absf(went - want) < 0.01, "rolling distance off")


func _stun_draw_follow() -> void:
	print("Straight at a ball 0.8 m off: centre, low, high (the bar ball on the Sov table, and a regulation one)")
	for tb in [level(), PoolSim.sov_table()]:
		for b_off in [0.0, -0.45, 0.45]:
			for sp in [1.6, 3.2]:
				var s := PoolSim.new(tb)
				var cb := s.add_ball(0, Vector3(-0.5, 0, 0), true)
				var ob := s.add_ball(1, Vector3(0.3, 0, 0))
				s.strike(cb, Vector3(1, 0, 0), 0.0, 0.0, b_off, sp, HOUSE)
				s.run()
				# how the cue ball's going once the slip's gone after the hit: back (draw), on (follow), or stopped
				var th := 0.0
				for e in s.log:
					if e[1] == "ball":
						th = e[0]
						break
				var cx := 0.0
				for sg in cb.segs:
					if float(sg[0]) > th and (sg[7] == PoolSim.ROLL or sg[7] == PoolSim.STILL):
						cx = float(sg[2].x)
						break
				print("  %s tip %+.2f cue %.1f m/s: cue ball rolling at %+.2f m/s after the hit" % [tb.name, b_off, sp, cx])
				if tb.name == "good" and b_off == 0.0 and sp == 3.2:
					check(cx >= -0.05 and cx < 0.5, "centre ball firm: little follow (%.2f)" % cx)
				if b_off < 0.0 and sp == 3.2:
					check(cx < -0.1, "draw should bring it back (%.2f)" % cx)
				if b_off > 0.0:
					check(cx > 0.1, "follow should run on (%.2f)" % cx)


func _thirty() -> void:
	print("The 30-degree rule: a rolling cue ball, half-ball and quarter/three-quarter hits")
	for frac in [0.25, 0.5, 0.75]:
		var s := PoolSim.new(level())
		var cb := s.add_ball(0, Vector3(-0.6, 0, 0), false)
		var ob := s.add_ball(1, Vector3(0.0, 0, (1.0 - frac) * 2.0 * 0.028575))
		rolling(s, cb, Vector3(1.0, 0, 0))
		s.run(0.9)
		# the cue ball's line well after the hit, once it's rolling again
		var pts: Array = []
		for k in 2:
			var smp: Array = s.sample(cb, 0.85 + k * 0.05)
			pts.append(smp[0])
		var d: Vector3 = pts[1] - pts[0]
		var ang := rad_to_deg(atan2(-d.z, d.x))
		print("  %.2f ball hit: cue ball comes off %.1f degrees" % [frac, absf(ang)])
		if frac == 0.5:
			check(absf(ang) > 26.0 and absf(ang) < 36.0, "half-ball deflection should be near 30 (%.1f)" % ang)


func _throw() -> void:
	print("Throw: a stun half-ball cut, slow and fast")
	for sp in [0.5, 1.5, 4.0]:
		var s := PoolSim.new(level())
		var cb := s.add_ball(0, Vector3(-0.3, 0, 0), false)
		var ob := s.add_ball(1, Vector3(0.0, 0, 0.028575))
		cb.v = Vector3(sp, 0, 0)
		cb.w = Vector3.ZERO
		s.run(1.5)
		var th := 0.0
		for e in s.log:
			if e[1] == "ball":
				th = e[0]
				break
		# the object ball's line against the line of centres at contact (cut 30 degrees)
		var smp0: Array = s.sample(ob, th + 0.01)
		var smp1: Array = s.sample(ob, th + 0.02)
		var d: Vector3 = smp1[0] - smp0[0]
		var hit_line := Vector3(0.0, 0, 0.028575) - Vector3(-2.0 * 0.028575 * cos(deg_to_rad(30.0)), 0, 0)
		var ang := rad_to_deg(atan2(-d.z, d.x)) - rad_to_deg(atan2(-hit_line.z, hit_line.x))
		print("  %.1f m/s: thrown %.2f degrees off the line of centres" % [sp, absf(ang)])
		if sp == 0.5:
			check(absf(ang) > 1.5 and absf(ang) < 6.0, "slow stun half-ball throw should be 2-5 degrees (%.2f)" % ang)


func _cushion() -> void:
	print("Into the long cushion at 45 degrees, rolling, at 1.5 m/s: no english, running, reverse")
	for side in [0.0, 1.0, -1.0]:
		var s := PoolSim.new(level())
		var b := s.add_ball(0, Vector3(-0.3, 0, 0.2), false)
		var v := Vector3(1.0, 0, -1.0).normalized() * 1.5
		rolling(s, b, v)
		# running english on a ball going +x into the far (-z) cushion: spin that turns it on along +x off the rail
		b.w.y = side * 40.0
		s.run(1.2)
		var a: Array = s.sample(b, 0.8)
		var c: Array = s.sample(b, 0.85)
		var d: Vector3 = c[0] - a[0]
		var ang := rad_to_deg(atan2(d.z, d.x))
		print("  side spin %+.0f: comes off at %.1f degrees from the rail (went in at 45), %.2f m/s" % [side, ang, d.length() / 0.05])
		if side == 0.0:
			check(ang > 30.0 and ang < 55.0, "no-english rebound should be near the angle in (%.1f)" % ang)


func _squirt() -> void:
	print("Squirt: half a tip of right english with the house cue and a low-deflection one")
	for cue in [HOUSE, {"M": 0.55, "end": 0.0045, "e": 0.75, "limit": 0.55}]:
		var s := PoolSim.new(level())
		var cb := s.add_ball(0, Vector3(-0.8, 0, 0), false)
		var r := s.strike(cb, Vector3(1, 0, 0), 0.0, 0.4, 0.0, 3.0, cue)
		print("  end mass %.1f g: squirts %.2f degrees" % [float(cue.end) * 1000.0, rad_to_deg(r.squirt)])
		check(rad_to_deg(r.squirt) > 0.6 and rad_to_deg(r.squirt) < 4.0, "squirt out of range")


func _masse() -> void:
	print("Swerve and masse: the butt up, the tip off to the right")
	for elev in [8.0, 30.0, 70.0]:
		var s := PoolSim.new(level())
		var cb := s.add_ball(0, Vector3(-0.8, 0, 0), false)
		s.strike(cb, Vector3(1, 0, 0), deg_to_rad(elev), 0.45, 0.0, 2.0, HOUSE)
		s.run(1.5)
		var bend: float = 0.0
		for k in 20:
			var smp: Array = s.sample(cb, k * 0.07)
			bend = maxf(bend, absf(float(smp[0].z)))
		print("  butt up %.0f degrees: off its line by %.3f m" % [elev, bend])
		if elev == 70.0:
			check(bend > 0.08, "a masse should curve well off its line (%.3f)" % bend)


func _jump() -> void:
	print("The jump: struck down into the slate")
	for elev in [10.0, 45.0]:
		var s := PoolSim.new(level())
		var cb := s.add_ball(0, Vector3(-0.8, 0, 0), false)
		s.strike(cb, Vector3(1, 0, 0), deg_to_rad(elev), 0.0, 0.2, 5.0, HOUSE)
		s.run(1.0)
		var top := 0.0
		for k in 60:
			var smp: Array = s.sample(cb, k * 0.01)
			top = maxf(top, float(smp[0].y) - cb.r)
		print("  butt up %.0f: off the cloth %.3f m at its highest" % [elev, top])
		if elev == 45.0:
			check(top > 0.03, "a jump shot should leave the cloth (%.3f)" % top)


func _pockets() -> void:
	print("Pockets: straight into the corner, then onto the jaw's point")
	var tb := level()
	var corner: Vector3 = tb.corners[3]
	for off in [0.0, 0.02, 0.04, 0.055, 0.08]:
		var s := PoolSim.new(tb)
		var start := Vector3(0.2, 0, 0.0)
		var dir := (corner - start).normalized()
		var perp := dir.cross(Vector3.UP)
		var b := s.add_ball(1, start + perp * off)
		rolling(s, b, dir * 1.4)
		s.run()
		var heard := s.log.filter(func(e): return e[1] == "jaw" or e[1] == "rail").size()
		print("  %.3f m off the pocket's line: %s (%d jaw/rail touches)" % [off, "in" if b.state == PoolSim.DOWN else "stays out", heard])
		if off <= 0.02:
			check(b.state == PoolSim.DOWN, "a ball near the pocket's line should drop")
		if off == 0.08:
			check(b.state != PoolSim.DOWN, "a ball well wide should stay out")


func rack8(s: PoolSim) -> void:
	var spot := s.table.foot_spot()
	var r := s.table.ball_r + 0.00008
	var order := [1, 9, 2, 10, 8, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15]
	var k := 0
	for row in 5:
		for i in row + 1:
			var p := spot + Vector3(row * r * sqrt(3.0), 0, (i - row * 0.5) * 2.0 * r)
			s.add_ball(order[k], p)
			k += 1


func _break() -> void:
	print("The break, from the head spot at 8 m/s: how long the sums take, and the same break twice")
	var ends := []
	for rep in 2:
		var s := PoolSim.new(PoolSim.sov_table())
		var cb := s.add_ball(0, s.table.head_spot(), true)
		rack8(s)
		var t0 := Time.get_ticks_usec()
		s.strike(cb, Vector3(1, 0, 0.003).normalized(), deg_to_rad(4.0), 0.0, 0.05, 8.0, HOUSE)
		s.run()
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		var downs := s.pocketed()
		var still := 0
		for b in s.balls:
			if b.state == PoolSim.STILL or b.state == PoolSim.DOWN or b.state == PoolSim.OFF:
				still += 1
		print("  %d events, %.1f s of play worked out in %.0f ms; %d down %s, %d off; all still: %s" % [s.events, s.t, ms, downs.size(), str(downs), s.went_off().size(), still == s.balls.size()])
		check(still == s.balls.size(), "everything should come to rest")
		check(s.t > 3.0 and s.t < 30.0, "a break runs a few seconds to twenty")
		var pos := []
		for b in s.balls:
			pos.append(b.p)
		ends.append(pos)
		# nothing in anything: every ball apart from every other, and on the table or gone
		for i in s.balls.size():
			var a = s.balls[i]
			if a.state == PoolSim.DOWN or a.state == PoolSim.OFF:
				continue
			check(absf(a.p.x) < s.table.L * 0.5 + 0.02 and absf(a.p.z) < s.table.W * 0.5 + 0.02, "ball %d off the cloth but not down (%s)" % [a.id, str(a.p)])
			for j in range(i + 1, s.balls.size()):
				var b = s.balls[j]
				if b.state == PoolSim.DOWN or b.state == PoolSim.OFF:
					continue
				check(a.p.distance_to(b.p) > a.r + b.r - 0.0005, "balls %d and %d inside each other" % [a.id, b.id])
	var same := true
	for i in ends[0].size():
		if (ends[0][i] as Vector3).distance_to(ends[1][i]) > 1e-9:
			same = false
	print("  the same break twice comes out the same: %s" % same)
	check(same, "not deterministic")


func _lean() -> void:
	print("The Sov's lean: a slow ball down the table, against the level table")
	for tb in [level(), PoolSim.sov_table()]:
		var s := PoolSim.new(tb)
		var b := s.add_ball(1, Vector3(-0.85, 0, -0.15))
		rolling(s, b, Vector3(0.62, 0, 0))
		s.run()
		print("  %s: drifted %.1f mm across over %.2f m" % [tb.name, (b.p.z + 0.15) * 1000.0, b.p.x + 0.85])
		if tb.name == "sov":
			check(absf(b.p.z + 0.15) > 0.008, "the lean should show on a slow roll")
