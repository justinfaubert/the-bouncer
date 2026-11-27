extends SceneTree
# The darts' physics against what real darts do (game/dart_sim.gd): a clean throw's time in the air,
# how it goes in, the wobble dying out, the wire (slid off or bounced out, by where it lands across
# it and how hard), the worn 20 letting go of darts the fresh beds hold, a dart into a dart, and a
# hand that shakes. Prints numbers; fails (exit 1) where they leave what's real.
#   godot --headless --path godot -s res://tests/darts_sim.gd

var bad := 0
const REL := Vector3(0.0, 0.03, 2.37 - 0.42)   # where it leaves his fingers: a forearm out past the oche, about eye height


func _init() -> void:
	_clean()
	_wobble()
	_wire()
	_worn()
	_dart_on_dart()
	_shake()
	print("darts_sim: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		bad += 1
		print("  BAD: " + what)


# A dart pointing along its flight, leaving at `at`, speed v, aimed up by `up` radians and across
# by `yaw`, its nose pitched off the line by `pitch_off`.
func shot(s: DartSim, b, at: Vector3, v: float, up: float, yaw := 0.0, pitch_off := 0.0, roll := 12.0) -> void:
	var dirv := Vector3(sin(yaw) * cos(up), sin(up), -cos(yaw) * cos(up)).normalized()
	var nose := dirv.rotated(Vector3(1, 0, 0), pitch_off).normalized()
	var r := Basis.looking_at(-nose, Vector3.UP)   # looking_at points -Z at the target: our +Z is the point
	s.throw(b, at, dirv * v, r, nose * roll)
	s.run()


# The angle up that puts a throw at height y on the board.
func aim(v: float, y: float, d := DartSim.Dart.new()) -> float:
	var lo := -0.2
	var hi := 0.9
	for i in 30:
		var mid := (lo + hi) * 0.5
		var s := DartSim.new()
		var b = s.add(d)
		shot(s, b, REL, v, mid)
		var h: float = b.crossed.y if b.crossed != null else (9.0 if b.vel.y > 0 else -9.0)
		if h > y:
			hi = mid
		else:
			lo = mid
	return (lo + hi) * 0.5


# height at which the dart's flight crossed the board's face
func _cross(b) -> float:
	for i in range(1, b.frames.size()):
		var t0: Transform3D = Transform3D(Basis(b.frames[i - 1][1]), b.frames[i - 1][0])
		var t1: Transform3D = Transform3D(Basis(b.frames[i][1]), b.frames[i][0])
		var p0: Vector3 = t0 * b.d.at(0.0)
		var p1: Vector3 = t1 * b.d.at(0.0)
		if p1.z <= 0.001:
			var f := (p0.z - 0.001) / maxf(p0.z - p1.z, 0.00001)
			return lerpf(p0.y, p1.y, f)
	return -9.0


func _clean() -> void:
	print("A clean throw at the bull")
	var d := DartSim.Dart.new()
	print("  the house dart: %.1f g, balance %.0f mm from the point, %.0f mm long" % [d.mass * 1000, d.cg * 1000, d.length * 1000])
	for v in [4.5, 5.5, 6.5, 7.5]:
		var up := aim(v, 0.0, d)
		var s := DartSim.new()
		var b = s.add(d)
		shot(s, b, REL, v, up)
		var res := s.result(b)
		var t_in := -1.0
		var in_speed := 0.0
		var tail_up := 0.0
		for h in s.hits:
			if h[2] == "sisal" or h[2] == "wire":
				t_in = h[0]
				in_speed = h[3]
				break
		var ax: Vector3 = Basis(b.frames[b.frames.size() - 1][1]).z
		tail_up = rad_to_deg(asin(-ax.y))
		print("  %.1f m/s: up %.1f deg, %.2f s in the air, in at %.1f m/s, %s %s%s, %.1f mm deep, tail %+.0f deg" % [v, rad_to_deg(up), t_in, in_speed,
			res.where, res.get("n", 0), "x%d" % res.get("x", 0), res.get("depth", 0.0) * 1000, -tail_up])
		check(t_in > 0.25 and t_in < 0.6, "%.1f m/s took %.2f s (real darts: about 0.3 to 0.5)" % [v, t_in])
		check(res.where == "board", "%.1f m/s at the bull isn't in the board" % v)
		check(res.get("depth", 0.0) > 0.003 and res.get("depth", 0.0) < 0.02, "%.1f m/s went %.1f mm in" % [v, res.get("depth", 0.0) * 1000])


func _wobble() -> void:
	print("Released 10 degrees nose-up off its line: the wobble")
	var d := DartSim.Dart.new()
	var s := DartSim.new()
	var b = s.add(d)
	var up := aim(6.0, 0.0, d)
	shot(s, b, REL, 6.0, up, 0.0, deg_to_rad(10.0))
	var line := []
	var peaks := []
	var last := 0.0
	var rising := true
	for i in range(1, b.frames.size()):
		var p0: Vector3 = b.frames[i - 1][0]
		var p1: Vector3 = b.frames[i][0]
		if p1.z < 0.05:
			break
		var vel := (p1 - p0).normalized()
		var ax: Vector3 = Basis(b.frames[i][1]).z
		var off := rad_to_deg(asin(clampf(ax.cross(vel).x, -1, 1)))
		if i % 8 == 0:
			line.append("%+.1f" % off)
		if rising and off < last and i > 1:
			peaks.append(absf(last))
			rising = false
		elif not rising and off > last:
			peaks.append(absf(last))
			rising = true
		last = off
	print("  off its line, deg, every 40 ms: " + " ".join(line))
	print("  swings: " + ", ".join(peaks.map(func(x): return "%.1f" % x)))
	check(peaks.size() >= 2, "it didn't swing back")
	if peaks.size() >= 3:
		check(peaks[2] < peaks[0], "the swing isn't dying out")


func _wire() -> void:
	print("Onto the spoke between the 20 and the 1, by where across it the point lands")
	var d := DartSim.Dart.new()
	# the spoke at 9 degrees right of up, at the height of the big 20 bed
	var rr := 0.13
	var sa := deg_to_rad(9.0)
	var on := Vector2(sin(sa), cos(sa)) * rr
	var nrm := Vector2(cos(sa), -sin(sa))
	for v in [4.0, 6.0, 8.0]:
		var row := []
		var outs := 0
		for k in range(-12, 13):
			var off := k * 0.0001
			var tgt := on + nrm * off
			var up := aim(v, tgt.y, d)
			var yaw := atan2(tgt.x, REL.z)
			var s := DartSim.new()
			var b = s.add(d)
			shot(s, b, REL, v, up, yaw)
			var res := s.result(b)
			var ch := "."
			if res.where == "carpet":
				ch = "X"
				outs += 1
			elif res.n == 20:
				ch = "2"
			elif res.n == 1:
				ch = "1"
			row.append(ch)
		print("  %.0f m/s, -1.2 mm to +1.2 mm across: %s  (%d bounced out)" % [v, "".join(row), outs])
		if v > 5.0:
			check(outs > 0, "nothing bounced out at %.0f m/s" % v)
			check(outs <= 8, "too many bounced out at %.0f m/s (real: a third of wire hits at most)" % v)


func _worn() -> void:
	print("The worn treble 20 against the fresh treble 3")
	var d := DartSim.Dart.new()
	var kept := []
	for tgt in [Vector2(0.0, 0.103), Vector2(0.0, -0.103)]:
		var held := 0
		var n := 0
		for v in [4.6, 5.0, 5.5, 6.0, 6.5]:
			for k in 4:
				var q: Vector2 = tgt + Vector2((k - 1.5) * 0.002, 0.0)
				var up := aim(v, q.y, d)
				var s := DartSim.new()
				var b = s.add(d)
				shot(s, b, REL, v, up, atan2(q.x, REL.z))
				n += 1
				var rs := s.result(b)
				if rs.where == "board":
					held += 1
				elif k == 0:
					print("    %.1f m/s: %s, heard %s" % [v, rs.where, ", ".join(s.hits.map(func(h): return h[2]))])
		print("  %s: %d of %d stayed in" % ["treble 20" if tgt.y > 0 else "treble 3", held, n])
		kept.append(held)
	check(kept[0] < kept[1] and kept[0] > 0, "the worn treble 20 should let go of some darts the treble 3 holds, not all")


func _dart_on_dart() -> void:
	print("Three at the bull, the same throw each time")
	var s := DartSim.new()
	var ds := [s.add(DartSim.Dart.new()), s.add(DartSim.Dart.new()), s.add(DartSim.Dart.new())]
	var up := aim(6.0, 0.0)
	for b in ds:
		shot(s, b, REL, 6.0, up)
		var hs := s.hits.map(func(h): return "%d:%s" % [h[1], h[2]])
		print("  thrown dart %d, heard: %s" % [ds.find(b), ", ".join(hs)])
		for o in ds:
			var r := s.result(o)
			print("    dart %d: %s %s" % [ds.find(o), r.where, "%sx%s" % [r.n, r.x]])


func _shake() -> void:
	print("A hand that shakes: twenty at the bull, the spread")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for shake in [0.0015, 0.004, 0.009]:
		var spread := 0.0
		var inb := 0
		var up0 := aim(6.0, 0.0)
		for k in 20:
			var s := DartSim.new()
			var b = s.add(DartSim.Dart.new())
			var up := up0 + rng.randfn(0.0, shake)
			shot(s, b, REL, 6.0 + rng.randfn(0.0, shake * 20.0), up, rng.randfn(0.0, shake), rng.randfn(0.0, shake * 3.0))
			var res := s.result(b)
			if res.where == "board":
				spread += Vector2(res.at.x, res.at.y).length()
				inb += 1
		print("  shake %.4f rad: mean %.0f mm off the bull, %d of 20 in the board" % [shake, spread / maxf(inb, 1) * 1000.0, inb])
		if shake < 0.002:
			check(inb >= 17, "a steady hand bounced %d of 20 out round the bull" % (20 - inb))
