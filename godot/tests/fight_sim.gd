extends SceneTree
# The fight's sim (game/fight_sim.gd) against what fights do: a straight to the jaw in range lands
# and rings the bell, out of range it falls short and carries him; covered, the forearms take it;
# a slipped head isn't there; a hook needs a hand up on its side; big swings wind up longer than a
# jab; the brains finish fights, each its own way, the same seed the same way; a hold pulled round in
# a circle builds and puts a man down; a choke from behind takes his breath and then him; the ogre
# drags two men. Prints numbers; exit 1 where it's wrong.
#   godot --headless --path godot -s res://tests/fight_sim.gd

var bad := 0


func _init() -> void:
	_jaw()
	_short()
	_cover()
	_slip()
	_hook()
	_tells()
	_brains()
	_same()
	_circle()
	_choke()
	_ogre()
	print("fight_sim: %s" % ("ok" if bad == 0 else "%d bad" % bad))
	quit(1 if bad else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		bad += 1
		print("  BAD: " + what)


func pair(gap := 0.95, b_brain := "") -> FightSim:
	var s := FightSim.new(7)
	var me := FightSim.body("him", {"str": 6, "con": 5, "dex": 5, "wis": 5, "gut": 4, "cha": 4}, 1.93, 0.7)
	var him := FightSim.body("ox", {"str": 5, "con": 5, "dex": 4, "wis": 4}, 1.85, 0.6, b_brain)
	s.setup(me, him, gap)
	return s


func run_until(s: FightSim, kind: String, secs := 2.0) -> Dictionary:
	var n := int(secs / FightSim.DT)
	for i in n:
		s.step()
		for e in s.take_events():
			if e.kind == kind:
				return e
	return {}


func _jaw() -> void:
	var s := pair()
	var jaw := Vector2(0.0, s.b.head_y() - 0.06)
	s.strike(s.a, "R", "straight", jaw, 1.0)
	var e := run_until(s, "blow")
	print("jaw: %s zone %s force %.2f shock %.2f" % [e.get("result"), e.get("zone"), e.get("force", 0.0), s.b.shock])
	check(e.get("result") == "clean" and e.get("zone") == "jaw", "a full straight to the jaw in range lands on the jaw")
	check(s.b.shock > 0.3, "and rings his bell")


func _short() -> void:
	var s := pair(2.2)
	var v0 := s.a.bal_v.length()
	s.strike(s.a, "R", "straight", Vector2(0, s.b.head_y()), 1.0)
	var e := run_until(s, "blow")
	print("short: %s, his weight after it %.2f" % [e.get("result"), s.a.bal_v.length()])
	check(e.get("result") == "short", "out of range it falls short")
	check(s.a.bal_v.length() > v0 + 0.2, "and carries him after it")


func _cover() -> void:
	var s := pair()
	s.b.cover = true
	s.strike(s.a, "R", "straight", Vector2(0, s.b.head_y() - 0.06), 1.0)
	var e := run_until(s, "blow")
	print("cover: %s shock %.3f" % [e.get("result"), s.b.shock])
	check(e.get("result") == "blocked", "covered up, the head's blocked")
	check(s.b.shock < 0.1, "and it barely rings")
	var s2 := pair()
	s2.b.cover = true
	s2.strike(s2.a, "R", "straight", Vector2(0.0, s2.b.height * 0.66), 0.9)
	var e2 := run_until(s2, "blow")
	print("cover, to the body: %s breath %.2f" % [e2.get("result"), s2.b.breath])
	check(e2.get("result") == "clean", "covered up, the body's open")


func _slip() -> void:
	var s := pair()
	s.strike(s.a, "R", "straight", Vector2(0, s.b.head_y() - 0.04), 0.8)
	s.b.slip_to = 1.0
	var e := run_until(s, "blow")
	print("slip: %s" % e.get("result"))
	check(e.get("result") == "slipped", "a slipped head isn't there")


func _hook() -> void:
	var hits := 0
	var blocks := 0
	for side in [-1.0, 1.0]:
		var s := pair(0.75)
		# his guard hand up on that side
		s.b.guard["R" if side > 0 else "L"] = Vector2(0.14 * side, s.b.head_y())
		s.strike(s.a, "R", "hook", Vector2(0.1 * side, s.b.head_y() - 0.02), 0.9)
		var e := run_until(s, "blow")
		blocks += 1 if e.get("result") == "blocked" else 0
		var s2 := pair(0.75)
		s2.b.guard["R" if side > 0 else "L"] = Vector2(0.14 * side, s2.b.height * 0.6)
		s2.strike(s2.a, "R", "hook", Vector2(0.1 * side, s2.b.head_y() - 0.02), 0.9)
		var e2 := run_until(s2, "blow")
		hits += 1 if e2.get("result") == "clean" else 0
	print("hook: blocked by a hand up %d/2, landed past a hand down %d/2" % [blocks, hits])
	check(blocks == 2 and hits == 2, "a hook needs the hand on its side up by the head")


func _tells() -> void:
	var s := pair(0.95, "brawler")
	s.strike(s.b, "R", "hook", Vector2(0.1, s.a.head_y()), 1.0)
	var big := float(s.b.act.tell)
	var s2 := pair(0.95, "boxer")
	s2.strike(s2.b, "L", "straight", Vector2(0, s2.a.head_y()), 0.4)
	var jab := float(s2.b.act.tell)
	print("tells: a brawler's big hook %.2f s, a boxer's jab %.2f s" % [big, jab])
	check(big > jab * 2.0, "a big swing shows far longer than a jab")
	var s3 := pair(0.95, "brawler")
	s3.a.stats.wis = 9
	s3.strike(s3.b, "R", "hook", Vector2(0.1, s3.a.head_y()), 1.0)
	print("tells: the same hook seen by Wisdom 9 %.2f s" % float(s3.b.act.tell))
	check(float(s3.b.act.tell) > big, "Wisdom gives him longer to see it")


func _brains() -> void:
	for br in ["brawler", "boxer", "purrer", "sparring"]:
		var s := FightSim.new(11)
		var x := FightSim.body("x", {"str": 5, "con": 5, "dex": 5, "wis": 5}, 1.88, 0.6, br)
		var y := FightSim.body("y", {"str": 5, "con": 5, "dex": 5, "wis": 5}, 1.88, 0.6, "boxer")
		s.setup(x, y, 1.6)
		var clean := 0
		var blows := 0
		var downs := 0
		var holds := 0
		for i in int(90.0 / FightSim.DT):
			s.step()
			for e in s.take_events():
				if e.kind == "blow":
					blows += 1
					clean += 1 if e.result == "clean" else 0
				elif e.kind == "down":
					downs += 1
				elif e.kind == "grab" and e.result == "held":
					holds += 1
		print("brains: %s v boxer, 90 s: %d blows, %d clean, %d holds, %d down" % [br, blows, clean, holds, downs])
		check(blows > 20, br + " throws")
		check(clean > 3 and clean < blows, br + " lands some and not all")
		if br == "purrer":
			check(holds > 0, "the purrer takes hold")


func _same() -> void:
	var r := []
	for k in 2:
		var s := FightSim.new(99)
		s.setup(FightSim.body("x", {}, 1.9, 0.6, "brawler"), FightSim.body("y", {}, 1.8, 0.5, "boxer"), 1.4)
		s.step(int(20.0 / FightSim.DT))
		r.append("%.5f %.5f %.5f" % [s.a.pos.x, s.b.shock, s.a.breath])
	print("same seed: %s | %s" % r)
	check(r[0] == r[1], "the same seed fights the same fight")


func _circle() -> void:
	# a steady pull one way, against the same pull going round in a circle at the body's sway
	var res := []
	for circle in [false, true]:
		var s := pair(0.75)
		s.b.brain = ""
		s.a.grips["L"] = {"part": "arm_R", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO, "circle": 0.0}
		s.a.grips["R"] = {"part": "collar", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO, "circle": 0.0}
		var down := false
		var most := 0.0
		for i in int(4.0 / FightSim.DT):
			var ang := s.t * 6.0 if circle else 0.0
			s.a.pull = Vector2(cos(ang), sin(ang)) * 5.0
			s.step()
			most = maxf(most, s.b.bal.length())
			for e in s.take_events():
				if e.kind == "down" and e.by == "ox":
					down = true
		res.append([down, most])
	print("circle: steady pull down=%s most off %.2f m; circle down=%s most off %.2f m" % [res[0][0], res[0][1], res[1][0], res[1][1]])
	check(res[1][1] > res[0][1], "pulled round in a circle, his weight goes further than a steady pull")
	check(res[1][0], "and the circle puts him down")


func _choke() -> void:
	var s := pair(0.6)
	s.b.brain = ""
	s.b.facing = 0.0   # turned away from him: his back to him
	s.b.pos = s.a.pos + Vector2(0, 0.55)
	s.a.grips["L"] = {"part": "neck", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO}
	s.a.grips["R"] = {"part": "neck", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO}
	var gone := -1.0
	for i in int(8.0 / FightSim.DT):
		s.step()
		for e in s.take_events():
			if e.kind == "gone":
				gone = s.t
	print("choke: gone at %.1f s, held past it %.1f s" % [gone, s.choke_past(s.a)])
	check(gone > 1.5 and gone < 6.0, "a choke from behind takes him in seconds, not at once")
	check(s.choke_past(s.a) > 1.0, "and it keeps count of every second held after")


func _ogre() -> void:
	var s := FightSim.new(3)
	var me := FightSim.body("him", {"str": 6, "con": 5, "dex": 5}, 1.93, 0.75)
	var ogre := FightSim.body("ogre", {"str": 10, "con": 10, "dex": 3}, 2.13, 1.3, "berserker")
	s.setup(me, ogre, 0.7)
	print("ogre: %.0f kg against his %.0f" % [ogre.mass, me.mass])
	check(ogre.mass > me.mass * 1.4, "the ogre is a lot more man")
	me.grips["L"] = {"part": "arm_R", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO}
	ogre.helpers = [{"hold": 0.5, "to": ogre.pos, "side": "L"}]
	var start := ogre.pos
	var surges := 0
	var moved := 0.0
	for i in int(10.0 / FightSim.DT):
		s.step()
		moved = maxf(moved, ogre.pos.distance_to(start))
		for e in s.take_events():
			surges += 1 if e.kind == "surge" else 0
	print("ogre: %d surges in 10 s, dragged up to %.2f m from where they had him" % [surges, moved])
	check(surges >= 4, "he surges")
	check(moved > 0.3, "and drags them")
