# The room round the board while he throws (game/darts.gd is the throw and the score). Nobody here
# cares about darts until somebody does. A good dart gets a word from whoever's nearest; two in the
# treble and the bar goes quiet behind him without being asked to; the third one decides whether
# it comes back as a shout or a groan. Jim, who drums in cover bands, can't help himself on a ton.
#
# None of it is on the screen as a number or a banner. It's the room: who looks over, who says it,
# what the lamp does, how quiet it gets. Everyone calls it the way it's called in every pub in the
# Commonwealth; the narration and the voices say what that's like. Each narration line is said once
# a night (variants rotate), the calls every time, the way a caller calls every 180.
class_name DartsRoom
extends Node

const NEAR := 10.0                 # metres from the board: far enough to have watched it
const BAR_AT := Vector3(3.0, 1.5, 4.5)    # where the bar's noise comes from with nobody there to make it

var darts                          # game/darts.gd
var main
var later: Array = []              # [when, Callable]
var t := 0.0
var hush := 0.0                    # how quiet the room's gone behind him, 0..1, and where it's going
var hush_to := 0.0
var lamp: Light3D
var lamp_e := 0.0
var flicker_t := -1.0
var said := {}                     # narration keys said tonight -> how many times
var walls := 0                     # darts in the plaster this visit
var carpets := 0                   # on the carpet this turn
var on_180 := false                # two in the treble, the third in his hand


func setup(d) -> void:
	darts = d
	main = d.main
	# the lamp on its arm over the board (world/pub.gd, "the light for the darts")
	var best := 0.6
	for l in d.pub.find_children("*", "SpotLight3D", true, false):
		var dd := (l as Node3D).global_position.distance_to(Vector3(15.27, 2.17, 1.95))
		if dd < best:
			best = dd
			lamp = l
	set_process(false)


func begin() -> void:
	later.clear()
	hush = 0.0
	hush_to = 0.0
	walls = 0
	carpets = 0
	on_180 = false
	set_process(true)


func end() -> void:
	later.clear()
	hush_to = 0.0
	on_180 = false
	if lamp != null and flicker_t >= 0.0:
		lamp.light_energy = lamp_e
	flicker_t = -1.0
	if main.audio != null:
		main.audio.weigh = 0.0
	set_process(false)


func _process(dt: float) -> void:
	t += dt
	var keep: Array = []
	for e in later:
		if t >= float(e[0]):
			(e[1] as Callable).call()
		else:
			keep.append(e)
	later = keep
	hush = move_toward(hush, hush_to, dt * (0.5 if hush_to > hush else 1.6))
	if main.audio != null:
		main.audio.weigh = hush * 0.85
	if flicker_t >= 0.0 and lamp != null:
		flicker_t += dt
		var on := 1.0
		for gap in [[0.06, 0.11], [0.14, 0.2]]:
			if flicker_t > gap[0] and flicker_t < gap[1]:
				on = 0.12
		lamp.light_energy = lamp_e * on
		if flicker_t > 0.35:
			lamp.light_energy = lamp_e
			flicker_t = -1.0


func _after(secs: float, f: Callable) -> void:
	later.append([t + secs, f])


# ---------------------------------------------------------------- who's there

# The ones near the board who could have watched it, nearest first: standing or sat, not walking,
# not in the washroom.
func watchers() -> Array:
	var st = main.stage
	if st == null:
		return []
	var b: Vector3 = darts.to_world * Vector3.ZERO
	var out: Array = []
	for id in st.figures:
		if st.walkers.has(id) or st.away.has(id):
			continue
		var h: Vector3 = st.head_of(id)
		if h == Vector3.INF:
			continue
		var d := h.distance_to(b)
		if d < NEAR:
			out.append([d, id])
	out.sort_custom(func(a, c): return a[0] < c[0])
	return out.map(func(x): return x[1])


func _bar() -> Vector3:
	var h: Vector3 = main.stage.head_of("bartender") if main.stage != null else Vector3.INF
	return h if h != Vector3.INF else BAR_AT


# someone near calls it; with nobody there, it's heard from the bar and goes in the column instead
func _call(text: String, who := "", delay := 0.0) -> void:
	_after(delay, func():
		var ws := watchers()
		var id: String = who if who != "" and main.stage != null and main.stage.figures.has(who) else (ws[0] if not ws.is_empty() else "")
		if id != "" and main.talk != null and main.talk.call_out(id, text) >= 0.0:
			return
		darts._line("Somebody at the bar: \"%s\"" % text))


func _all_look(secs: float) -> void:
	var b: Vector3 = darts.to_world * Vector3.ZERO
	for id in watchers():
		main.stage.life.look_over(id, b, secs)


func _laugh(n := 1) -> void:
	var ws := watchers()
	for k in mini(n, ws.size()):
		main.stage.life.laugh(ws[k], randf_range(0.5, 0.9), randf_range(0.0, 0.3))
	var at: Vector3 = main.stage.head_of(ws[0]) if not ws.is_empty() else _bar()
	main.audio.at("laugh_one" if n <= 1 else "laugh", at, 0.7, 2.0)


# narration, once each a night; variants go round in order
func _once(key: String, variants: Array, delay := 0.0) -> void:
	var k := int(said.get(key, 0))
	if k >= variants.size():
		return
	said[key] = k + 1
	var v = variants[k]
	_after(delay, func():
		if v is Dictionary:
			_voice(v.who, v.text)
		else:
			darts._line(str(v)))


func _voice(who: String, text: String) -> void:
	if main.column == null:
		return
	main.column.begin_batch()
	main.column.add_line({"role": "voice", "speaker": who, "text": text,
		"label": str(main.column.voice_labels.get(who, who.to_upper()))})
	main.column.scroll_to_end()
	main.audio.line({"role": "voice", "speaker": who, "text": text})


func _flicker() -> void:
	if lamp == null:
		return
	lamp_e = lamp.light_energy if flicker_t < 0.0 else lamp_e
	flicker_t = 0.0
	main.audio.at("filament", lamp.global_position, 0.6, 1.2)


# ---------------------------------------------------------------- the darts

# One dart in: what the room makes of it, before the turn's done.
func landed(i: int, r: Dictionary, heard: Array, turn: Array) -> void:
	var bull: bool = r.where == "board" and int(r.n) == 25 and int(r.x) == 2
	if r.where == "carpet":
		carpets += 1
	if r.where == "plaster":
		walls += 1
		if walls == 2:
			_call("That wall's not a double.", "bartender", 0.6)
		elif walls == 4:
			_once("walls", ["Behind the bar Jim had stopped polishing the glass he was polishing and was counting the holes in the plaster with his lips."], 0.8)
	if "robin" in heard:
		# darts.gd says nobody saw it. Somebody saw it.
		var ws := watchers()
		if not ws.is_empty():
			_call("I saw it.", ws[0], 2.2)
		else:
			_after(2.2, func(): _voice("kid", "i saw it"))
		return
	if bull:
		darts.push(0.9, 0.18)
		_call("Bull." if randf() < 0.6 else "Bullseye.", "", 0.35)
		_once("bull", ["Dead centre. The board took it with a sound like a knuckle on a door, and the cabinet doors answered it."], 0.9)
	if "out" in heard and r.where == "carpet" and turn.size() <= 2:
		_laugh(1)
	# two in the treble twenty, the third in his hand: the room goes quiet behind him
	if i == 1 and turn.size() == 2 and _t20(turn[0]) and _t20(turn[1]):
		on_180 = true
		hush_to = 1.0
		_all_look(9.0)
		main.audio.sfx("heart", 0.35, 0.9)
		_once("on180", [
			"Two in the treble. The talk at the bar thinned out behind him, nobody asking it to. Somebody put a glass down very carefully.",
			"Two in the treble again. The bar went quiet for him again. It was getting to be a thing.",
			{"who": "fighter", "text": "Same feet. Same elbow. Seven foot nine and a quarter to the board, and it hasn't moved."},
		], 0.5)


func _t20(r: Dictionary) -> bool:
	return r.where == "board" and int(r.n) == 20 and int(r.x) == 3


# The turn's three darts done: the call for it, if it's one that gets called.
# turn: the three results. bust, shot: 501's. left: 501's left after it.
func turn_over(turn: Array, bust := false, shot := false, left := 501) -> void:
	var total := 0
	var beds := {}
	var ns := []
	for r in turn:
		if r.where == "board":
			total += int(r.n) * int(r.x)
			beds["%d_%d" % [int(r.n), int(r.x)]] = true
			ns.append(int(r.n))
	var was_on := on_180
	on_180 = false
	hush_to = 0.0
	var three_in := turn.size() == 3 and turn.all(func(r): return r.where == "board")
	if shot:
		_game_shot(turn)
	elif total == 180:
		_one_eighty()
	elif was_on:
		# two in the treble and the third somewhere else: the breath goes out of the room
		main.audio.at("groan", _bar(), 0.7, 2.5)
		_once("missed180", [
			"The room let its breath go, all of it at once, and went back to the hockey, too loudly.",
			"Ohhh, from the bar. The long one, the one that's mostly pleasure.",
			{"who": "wrongman", "text": "Two out of three. They put that on the headstone of every man you've ever met."},
		], 0.4)
	elif bust:
		_call("Bust.", "", 0.3)
		_once("bust", [{"who": "manual", "text": "Five-oh-one is finished on a double. Scores that would leave one, or less than nothing, do not count. This is in the binder."}], 0.9)
	elif total >= 140:
		_call("Ton-forty.", "", 0.4)
		_jim_fill(0.9)
	elif total >= 100:
		_call("Ton.", "", 0.4)
		_jim_fill(0.9)
		_once("ton", ["Behind the bar, Jim played a fill on the rail with two stir sticks, very quietly, for himself. He'd have said he didn't know he was doing it."], 1.6)
	elif three_in and total == 26 and ns.has(20) and ns.has(5) and ns.has(1):
		_call("Bed and breakfast.", "", 0.4)
		_after(1.0, func(): _laugh(2))
		_once("bnb", ["Twenty, five and one. Twenty-six. In every pub in the Commonwealth there's a man who says it, and in this one he'd been waiting all night."], 1.6)
	elif three_in and beds.size() == 1:
		_call("Three in a bed.", "", 0.4)
		_once("bed", ["All three in one bed, touching. Not the bed he wanted. Somebody at the bar clapped anyway, slowly, and got told to shut up."], 1.2)
	elif carpets >= 3:
		_call("Want me to bring the board closer?", "", 0.5)
		_after(1.4, func(): _laugh(2))
	carpets = 0


func _one_eighty() -> void:
	# the hush breaks: the call held all the way up, the bell, the glasses, the lamp catching
	_all_look(4.0)
	darts.push(1.6, 0.42)
	_call("One hundred and eightyyy!", "", 0.25)
	main.audio.at("cheer", _bar(), 0.85, 3.0, 1.0)
	_after(0.6, func(): main.audio.at("bell", _bar(), 0.55, 3.0))
	_after(0.95, func(): main.audio.at("bell", _bar(), 0.45, 3.0))
	_after(1.3, func():
		var c := _bar()
		for d in [0.0, 0.1, 0.24]:
			main.audio.at("clink", c + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)), 0.7, 1.5))
	_after(0.15, _flicker)
	_once("180", [
		"Somebody at the bar said it the way they say it on television, all the way up and holding the end, and then looked embarrassed. Jim rang the bell. You only ring the bell for last call. He rang it twice and then wiped it with his sleeve.",
		{"who": "father", "text": "Steady hands. Mine were like that the year I quit. Don't get used to it."},
		"The lamp over the board blinked, once, the old filament catching. Nobody else seemed to notice. Or they thought it was for him.",
		{"who": "fighter", "text": "AGAIN."},
	], 1.8)


func _game_shot(turn: Array) -> void:
	var last: Dictionary = turn.filter(func(r): return r.where == "board").back()
	var madhouse := int(last.n) == 1 and int(last.x) == 2
	darts.push(1.4, 0.35)
	_call("Madhouse." if madhouse else "Game shot.", "", 0.3)
	main.audio.at("cheer", _bar(), 0.6, 3.0, 1.1)
	_after(0.7, func(): main.audio.at("bell", _bar(), 0.5, 3.0))
	if madhouse:
		_once("madhouse", ["Double one. They call it the madhouse because that's where you end up waiting for it."], 1.5)
	else:
		_once("shot", [
			"Game shot. Nobody was playing him. That didn't seem to matter to anybody.",
			{"who": "table", "text": "THAT'S OUR BOY. Somebody get him one. Not us. Somebody."},
		], 1.5)


func _jim_fill(delay: float) -> void:
	_after(delay, func(): main.audio.at("bar_fill", _bar(), 0.6, 2.0))
