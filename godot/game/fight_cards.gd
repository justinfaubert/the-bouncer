# The fights as they're played (bible/15_FIGHTS_AND_STATS.md): each card a run of frozen seconds
# (game/fight_seconds.gd) and live play (game/fight.gd), with what it costs and teaches at the end.
#
#   ogre     the man on the deck, from Hutch's own door (12_FROM_THE_DOOR.md, 23 November): frozen
#            at the bar and on the deck, live holding him, frozen for the sister at the patio door,
#            live walking him through it, the fall like a tree, frozen for the throw and the elbow.
#   ox       the first Sunday at the fish plant: Ox Pettigrew in braces and a borrowed collar, under
#            the London Prize Ring's rules, a round ending when a man goes down, up to scratch or not.
#   spar     the plant on a weeknight, a sparring partner who pulls his punches, for as long as you like.
class_name FightCards
extends Node

signal done(result: Dictionary)

var main
var fight: Fight
var seconds: FightSeconds
var plant: FishPlant
var running := ""
var from_menu := ""
var body := {}
var result := {}
var _quit := false

const DECK := Vector3(17.3, 0.0, 7.1)


func setup(m, f: Fight, p: FishPlant) -> void:
	main = m
	fight = f
	plant = p
	seconds = FightSeconds.new()
	f.layer.add_child(seconds)
	seconds.setup(m)
	fight.finished.connect(func(r): _quit = r.get("result", "") == "quit")


# his seven, and what a fight needs of him, from the night or the menu
func _him(b: Dictionary) -> FightSim.Fighter:
	var st: Dictionary
	if main.in_game and main.game != null and from_menu == "":
		st = Checks.read_stats(main.game._gv)
	else:
		st = b.get("stats", {"str": 6, "con": 5, "dex": 5, "int": 4, "wis": 5, "cha": 4, "gut": 4})
	var me := FightSim.body("him", st, 1.93, 0.72)
	me.drinks = int(b.get("drinks", 0))
	me.hurt.head = float(b.get("hurt", 0)) * 0.15
	me.tired = clampf((float(b.get("clock", 1290)) - 1200.0) / 400.0, 0.0, 0.6)
	me.knacks = main.knacks_now(from_menu)
	return me


func _stats_of(me: FightSim.Fighter) -> Dictionary:
	return me.stats


func run(id: String, menu: String, b: Dictionary) -> void:
	running = id
	from_menu = menu
	body = b.duplicate()
	result = {}
	_quit = false
	match id:
		"ogre":
			await _ogre()
		"ox":
			await _ox()
		_:
			await _spar()
	if plant.visible:
		plant.show_now(false)
	main._say_practice(fight.practice_out)
	running = ""
	done.emit(result)


func _column(lines: Array, note := "") -> void:
	if main.column == null:
		return
	main.column.begin_batch()
	for l in lines:
		if l is Array:
			main.column.add_line({"role": "voice", "speaker": l[0], "label": str(l[0]).to_upper().replace("FIGHTER", "THE FIGHTER"), "text": l[1]})
		else:
			main.column.add_line({"role": "narration", "text": str(l)})
	if note != "":
		main.column.add_note(note)
	main.column.scroll_to_end()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


const HOW := "Left button, a stroke: the right hand. Right button: the left. Draw from the fist toward where it should land; bow it for a hook, draw it up for an uppercut, faster and longer is harder. Press and hold still on him to take hold; drag to move his weight, round in a circle to turn him off his feet. W A S D his feet, Q and E slip, Space covers up."


# ---------------------------------------------------------------- the man on the deck

func _ogre() -> void:
	main.view.jump_to("deck")
	var me := _him(body)
	var ogre := FightSim.body("ogre", {"str": 10, "con": 10, "dex": 3, "wis": 2, "cha": 2}, 2.13, 1.3, "berserker")
	ogre.drinks = 2
	var opts := {"where": Transform3D(Basis.IDENTITY, DECK), "bounds": Rect2(-0.9, -2.6, 1.85, 5.2), "me": me, "him": ogre,
		"model": "bigman", "size": 1.16, "gap": 1.0, "me_at": Vector2(0.35, -0.9), "him_at": Vector2(0.15, 0.4), "seed": 23,
		"helpers": [{"model": "patron_c", "side": "R", "off": Vector2(0.55, 0.15)}], "can_quit": from_menu != "", "level": 9.0,
		"extras": [{"model": "goodshoes_card", "at": Vector3(17.6, 0, 9.55), "face": Vector3(17.3, 0, 7.0)},
			{"model": "cook", "at": Vector3(18.05, 0, 9.4), "face": Vector3(17.3, 0, 7.0)},
			{"model": "vape", "at": Vector3(16.7, 0, 9.5), "face": Vector3(17.3, 0, 7.0)}]}
	fight.begin(opts, from_menu != "", body)
	fight.freeze(true)
	_column(["He came in about nine. Seven foot if he was an inch, and built like two of you stood side by side. Not much English. He didn't seem out of it. You served him a beer and he said thank you like it was a word he'd been practising, and drank it, and the night went on.",
		"Then one of the girls comes running for you. Someone's going crazy on the deck."], HOW)
	main.audio.ambience("room_quiet")
	await _wait(0.6)
	_thunder()
	var p: Dictionary = await seconds.ask([
		{"id": "talk", "text": "\"Hey. Hey, big man. Easy.\"", "glyph": "ring", "at": fight.point_of("my_mouth"), "voice": "father"},
		{"id": "shoulder", "text": "Your hand on his shoulder.", "glyph": "ring", "at": fight.point_of("his_neck"), "voice": "father",
			"check": {"stat": "cha", "target": 16}},
		{"id": "arm", "text": "Take the free arm.", "glyph": "arc", "at": fight.point_of("his_arm"), "voice": "fighter", "live": true},
		{"id": "jaw", "text": "Hit him on the jaw. Now, while he's on the boards.", "glyph": "line", "at": fight.point_of("his_jaw"), "voice": "fighter",
			"check": {"stat": "str", "target": 18}},
	], "The deck, 11:40", me.stats, int(body.get("tension", 0)))
	match str(p.id):
		"talk":
			fight.say("He looks at you. Nothing in his face you know. He says something long and low in a language with too many consonants and goes back to the boards.", 5.0)
			_thunder()
			await _wait(2.2)
		"shoulder":
			if p.ok:
				fight.say("He stops. For one breath he looks down at your hand on his arm. Then he rolls his shoulder and your hand isn't there any more.", 5.0)
			else:
				fight.say("He doesn't feel it. You might as well be pushing on the deck.", 4.0)
			await _wait(2.4)
		"jaw":
			if p.ok:
				fight.say("It lands. Your whole arm rings to the shoulder. He turns his head back, slowly, and looks round for who did it.", 5.0)
				me.hurt.arms = 0.4
				result["hand"] = "sore"
			else:
				fight.say("Your knuckles find the hinge of his jaw and something in your hand gives. He doesn't. THE FIGHTER: wrong man for that.", 5.0)
				me.hurt.arms = 0.7
				result["hand"] = "hurt"
			await _wait(2.6)
	# live: you've got his free arm, Dale's on the other
	fight.say("You get his left arm in both hands. Dale's got the right. Keep him off the people at the rail.", 4.5)
	me.grips["L"] = {"part": "arm_L", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO, "circle": 0.0}
	me.grips["R"] = {"part": "arm_L", "hold": 1.0, "ang": 0.0, "last": Vector2.ZERO, "circle": 0.0}
	ogre.helpers = [{"hold": 0.42, "to": Vector2(0.15, 0.2), "side": "R"}]
	fight.freeze(false)
	var hits := 0
	var t0 := fight.sim.t
	var free_t := 0.0
	var last_hit := -10.0
	while fight.active and fight.sim.t - t0 < 20.0 and not _quit:
		await get_tree().process_frame
		# he reaches the people at the rail
		if ogre.pos.y > 1.9 and fight.sim.t - last_hit > 3.0:
			hits += 1
			last_hit = fight.sim.t
			main.audio.at("punch", fight._w3(ogre.pos, 1.5), 0.7, 3.0, 0.8)
			fight.say(["He gets a fist into a man at the rail. The man sits down hard among the chairs.", "Another one at the rail. Somebody's glass goes over the side.", "He catches a woman's shoulder. She screams like it's a joke and then it isn't."][mini(hits - 1, 2)], 3.5)
		# both hands off him: he hits the deck, and anyone near
		if me.grips.is_empty():
			free_t += get_process_delta_time()
			if free_t > 1.4:
				free_t = 0.0
				_thunder()
		else:
			free_t = 0.0
		if ogre.breath < 0.25:
			break
	if _quit:
		_end_menu()
		return
	fight.freeze(true)
	_thunder()
	result["rail"] = hits
	p = await seconds.ask([
		{"id": "yes", "text": "\"Yeah. Get them.\"", "glyph": "ring", "at": fight.point_of("my_mouth"), "voice": "table"},
		{"id": "no", "text": "\"We've got him.\"", "glyph": "ring", "at": fight.point_of("my_mouth"), "voice": "father"},
		{"id": "cops", "text": "\"Call the cops.\"", "glyph": "ring", "at": fight.point_of("my_mouth"), "voice": "manual"},
	], "A woman at the patio door, in a leather vest: \"You want my brothers?\"", me.stats, int(body.get("tension", 0)))
	var door := Vector2(-1.05, 0.0)
	var helper_hold := 0.5
	match str(p.id):
		"yes":
			result["club"] = true
			helper_hold = 1.25
			fight.say("Five of them, out through the door at once, like they'd been waiting for the word. Big quiet men with their hands already open.", 5.0)
			for i in 3:
				var hf := fight._figure(["vape", "vape_door", "goodshoes_card"][i], null, 1.0)
				hf.helper = true
				hf.hold_pt = {"side": "L" if i % 2 == 0 else "R", "off": Vector2(0.65 + i * 0.15, -0.35 - i * 0.2)}
				fight.figures.append(hf)
		"no":
			fight.say("She shrugs and goes back in. Dale looks at you. \"Seriously, man?\"", 4.5)
		"cops":
			result["cops"] = true
			fight.say("She goes in to call it. THE MANUAL: forty minutes, on a Friday. Nobody's coming.", 4.5)
	ogre.helpers = [{"hold": helper_hold, "to": door, "side": "R"}]
	fight.freeze(false)
	fight.say("Walk him to the patio door. Pull him the way you want him to go.", 4.0)
	t0 = fight.sim.t
	while fight.active and not _quit:
		await get_tree().process_frame
		if ogre.pos.x < -0.72 and absf(ogre.pos.y - door.y) < 0.7:
			break
		if fight.sim.t - t0 > 55.0:
			fight.say("It takes everything you've got and most of Dale's, and the door frame takes a strip off your forearm, but he's through.", 4.0)
			me.hurt.arms += 0.2
			result["slow"] = true
			break
		if ogre.pos.y > 1.9:
			ogre.pos.y = 1.9
	if _quit:
		_end_menu()
		return
	# the fall: inside, on his face, like a tree
	ogre.helpers = []
	me.grips.clear()
	ogre.pos = door + Vector2(-0.3, 0)
	fight.sim.keep_down = true
	fight.sim._fall(ogre, Vector2(-1, 0), "trip")
	main.audio.at("groan", fight._w3(ogre.pos, 1.8), 1.0, 3.0, 0.5)
	await _wait(2.2)
	fight.say("Boom. The floor of the bar comes up through your feet. He lies there a second, two. Then he puts his hands flat and pushes himself up, and wipes them on his jeans.", 5.0)
	await _wait(1.5)
	ogre.down = false
	ogre.bal = Vector2.ZERO
	fight.sim.keep_down = false
	await _wait(1.2)
	fight.freeze(true)
	var elbow_sure := me.knacks.has("the_shoulder")
	p = await seconds.ask([
		{"id": "out", "text": "Every one of you gets a piece of him, and out he goes.", "glyph": "feet", "at": fight.point_of("my_feet"), "voice": "table"},
		{"id": "watch", "text": "Out he goes, and watch his elbows.", "glyph": "line", "at": fight.point_of("his_chest"), "voice": "fighter",
			"check": {"stat": "wis", "target": 14, "sure": elbow_sure}},
	], "Out", me.stats, int(body.get("tension", 0)))
	var jaw := not (str(p.id) == "watch" and bool(p.ok))
	fight.freeze(false)
	if jaw:
		fight.view.flash = 1.0
		fight.shake_v += Vector2(3.0, -1.0)
		main.audio.sfx("punch", 0.8, 0.8)
		main.audio.sfx("heart", 0.8, 0.8)
		fight.say("On the way out his elbow comes back and finds your jaw. A white flash, and a taste in your mouth like you've been sucking a penny.", 5.0)
		result["jaw"] = true
	else:
		fight.say("You see the elbow start before he does, and your chin's already somewhere else. It goes past your ear like a train.", 5.0)
	await _wait(3.0)
	fight.end()
	_ogre_after(hits)


func _ogre_after(hits: int) -> void:
	var lines: Array = []
	lines.append("You literally throw him out. He lands on the gravel on his hands and knees and stays there, breathing, then gets up and walks off across the lot toward the highway without looking back.")
	if result.get("club", false):
		lines.append("The brothers go back to their table. One of them lifts his glass to you as he sits. You'll be buying that table drinks till Christmas.")
	if result.get("cops", false):
		lines.append("At ten past one a single car pulls into the lot. The constable asks which way he went. Nobody knows. She writes it down.")
	else:
		lines.append("Nobody calls it in. Nobody comes.")
	if hits > 0:
		lines.append("%s at the rail took one of his fists. Somebody's going to have a face in the morning, and it's going to be the Sov's." % ("A man" if hits == 1 else "%d people" % hits))
	if result.get("jaw", false):
		lines.append("Your jaw clicks when you open it. Soup, for a week. Maybe soup.")
	lines.append("He'll wake up somewhere tomorrow and not remember any of it. The deck has a dent in it you could sit in. The bruises are yours, the paperwork's yours, and when the man at the rail gets a lawyer, the lawyer will want the name of whoever was on the door. The RCMP come on Tuesday, with a clipboard.")
	_column(lines)
	result["kind"] = "ogre"
	var g = main.game if main.in_game and from_menu == "" else null
	if g != null:
		g.set_var("ogre_done", 2 if result.get("jaw", false) else 1)
		g.set_var("ogre_club", bool(result.get("club", false)))
		if result.get("jaw", false):
			g.set_var("jaw", 7)
			g.set_var("hurt", mini(3, int(g.get_var("hurt")) + 1))
	_learn_end("holds", 3.0, "ogre_walk")
	_learn_end("nerve", 3.0, "ogre")


func _thunder() -> void:
	var at := fight._w3(fight.sim.b.pos, 0.1) if fight.sim != null else DECK
	main.audio.at("body_fall", at, 0.9, 4.0, 0.7)
	main.audio.at("break", at, 0.5, 4.0, 0.5)
	fight.shake_v += Vector2(0.0, 0.8)


func _learn_end(kind: String, amount: float, how: String) -> void:
	fight._learn(kind, amount, how)


func _end_menu() -> void:
	fight.end()
	result["kind"] = running
	result["quit"] = true


# ---------------------------------------------------------------- the fish plant, Sunday

func _plant_fight(opts: Dictionary) -> void:
	plant.show_now(true)
	main.view.jump_to("pool")
	opts["where"] = plant.frame()
	opts["bounds"] = Rect2(-FishPlant.RING, -FishPlant.RING, FishPlant.RING * 2.0, FishPlant.RING * 2.0)
	opts["ring_r"] = FishPlant.RING - 0.2
	fight.begin(opts, from_menu != "", body)


func _ox() -> void:
	var me := _him(body)
	var ox := FightSim.body("ox", {"str": 6, "con": 6, "dex": 3, "wis": 3, "cha": 4}, 1.88, 0.85, "brawler")
	_plant_fight({"me": me, "him": ox, "model": "hivis_door", "size": 1.1, "gap": 1.3, "ring": true, "seed": 5, "level": 4.5, "can_quit": true})
	fight.freeze(true)
	_column(["The fish plant on the wharf, Sunday. The gutting floor, the drains, five bulbs on their flex and the dark right up to the edge of the light. The old men round in a ring that's the ring.",
		"The Timekeeper on his herring barrel opens the ledger, licks his pencil and writes your name under a hundred and seventy years of names. \"London rules,\" he says. \"A man down, the round's done. Thirty seconds and up to scratch on your own feet. Nothing below the belt. The box takes ten either way.\"",
		"Ox Pettigrew drives the forklift at the co-op and came straight from his shift, the hi-vis still on over the collarless shirt the Friendly makes you wear, braces under it. His wife holds his glasses. He nods at you like you're both waiting for the same bus."], HOW + " Esc stays down.")
	await _wait(0.5)
	var p: Dictionary = await seconds.ask([
		{"id": "toe", "text": "Toe the line.", "glyph": "feet", "at": fight.point_of("my_feet"), "voice": "fighter", "live": true},
	], "Up to scratch", me.stats, int(body.get("tension", 0)))
	main.audio.sfx("bell", 0.8, 0.9)
	fight.freeze(false)
	var round_n := 1
	var outcome := ""
	while fight.active and outcome == "":
		var down_by := ""
		while fight.active and down_by == "" and not _quit:
			await get_tree().process_frame
			if fight.sim.a.down:
				down_by = "him"
			elif fight.sim.b.down:
				down_by = "ox"
		if _quit:
			outcome = "quit"
			break
		await _wait(1.6)
		fight.freeze(true)
		if down_by == "ox":
			if ox.out or ox.shock > 1.35 or ox.nerve < 0.12:
				outcome = "won"
				break
			fight.say("\"Time,\" says the Timekeeper. Ox's corner gets him up and pours water on him and he walks to the line on his own feet, which is the rule.", 4.5)
			ox.shock = maxf(0.0, ox.shock - 0.45)
			ox.breath = minf(1.0, ox.breath + 0.35)
		else:
			var target := 10 + round_n + int(me.shock * 4.0)
			p = await seconds.ask([
				{"id": "up", "text": "Up. To the line, on your own feet.", "glyph": "feet", "at": fight.point_of("my_feet"), "voice": "fighter",
					"check": {"stat": "con", "target": target, "mod": 2 if me.knacks.has("hard_head") else 0}, "live": true},
				{"id": "stay", "text": "Stay down.", "glyph": "none", "voice": "father"},
			], "Down. Thirty seconds.", me.stats, int(body.get("tension", 0)))
			if str(p.id) == "stay" or not bool(p.ok):
				outcome = "lost"
				fight.say("You don't make the line. Somebody's hand on your back, kind, and the Timekeeper writing.", 4.0)
				break
			me.shock = maxf(0.0, me.shock - 0.5)
			me.breath = minf(1.0, me.breath + 0.4)
		round_n += 1
		me.down = false
		ox.down = false
		me.bal = Vector2.ZERO
		ox.bal = Vector2.ZERO
		me.pos = Vector2(0, -0.65)
		ox.pos = Vector2(0, 0.65)
		me.grips.clear()
		ox.grips.clear()
		main.audio.sfx("bell", 0.7, 0.9)
		fight.freeze(false)
	await _wait(1.0)
	fight.end()
	var lines: Array = []
	match outcome:
		"won":
			lines.append("Ox doesn't come up. He sits on the concrete with his legs out like a kid at the beach and laughs, blood on his teeth, and his wife gives him his glasses. \"Fair enough,\" he says.")
			lines.append("The Timekeeper writes it. Round %d. Forty dollars in your hand and ten of it straight into the widows' box, which is brass, and older than the plant." % round_n)
			lines.append(["fighter", "First one in the book. They'll be stranger from here."])
			result["won"] = true
			_learn_end("nerve", 2.5, "ring:ox")
			_learn_end("wind", 1.0 + round_n * 0.5, "ring:rounds")
		"lost":
			lines.append("The Timekeeper writes it. Round %d. The box takes its ten from you anyway. Ox helps you up and buys you a beer you can't taste." % round_n)
		_:
			lines.append("You walk out of the light. The old men let you through.")
	_column(lines)
	result["kind"] = "ox"
	result["outcome"] = outcome
	var g = main.game if main.in_game and from_menu == "" else null
	if g != null and outcome == "won":
		g.set_var("ring_name", int(g.get_var("ring_name")) + 1)


func _spar() -> void:
	var me := _him(body)
	var mate := FightSim.body("dale", {"str": 5, "con": 6, "dex": 5, "wis": 5}, 1.9, 0.7, "sparring")
	_plant_fight({"me": me, "him": mate, "model": "patron_c", "size": 1.0, "gap": 1.4, "seed": randi() % 1000, "level": 5.0, "can_quit": true})
	_column(["A weeknight at the plant. Dale from the deck holds the keys for the old men and says he'll move around with you if you don't take his head off. He pulls his punches. Mostly."], HOW + " Esc to stop.")
	while fight.active and not _quit:
		await get_tree().process_frame
		if mate.down and mate.down_t > 2.5:
			mate.down = false
			mate.shock = 0.2
			mate.pos = me.pos + me.fwd() * 1.3
		if me.down and me.down_t > 2.5:
			me.down = false
			me.shock = maxf(0.0, me.shock - 0.6)
	fight.end()
	result["kind"] = "spar"
