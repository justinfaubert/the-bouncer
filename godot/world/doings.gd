# The room going on by itself while he's in it (world/stage.gd keeps one): table 28 laughing at
# something, looking up at the hockey together and going up for a goal or groaning at a near one,
# the pool game shot by shot, the bartender at her work, a cough, a lighter on the deck, a glass
# going over now and then, someone going for a slash and coming back. Each is heard from where it
# happens (Stage's sound, played by game/sound.gd's at), lower and duller from another part of the
# building. What can be seen happens where he can see it, the way it looks (a laugh, the bar wiped
# down); the pool game only while the table's out of his sight, since nobody's shown taking a shot.
# None of it moves the night on: the clock's the Ink's, and goes by what he does. And none of it at
# the table he's at: what happens there is the Ink's.
class_name Doings
extends RefCounted

const TV := Vector3(9.4, 2.45, 0.1)                  # table 28's hockey, up on the back wall
const FELT := Rect2(8.5, 3.45, 1.8, 0.9)             # the pool table's cloth (x, z), and how high it is
const FELT_Y := 0.82
const TABLE_Y := 0.78                                # the tops of the room's tables
# the ones who go for a slash when the night leaves them be: they can be seen walking there
const WC := ["glasses", "buddy", "goodshoes", "hivis"]
# where the bartender works from each place behind the bar: what, and where her right hand goes
# (the bar top in front of her, a tap's handle, the till's keys)
const WORK := {
	"bar_back_mid": [["wipe", Vector3(1.62, 1.135, 5.0)], ["wipe", Vector3(1.62, 1.135, 4.65)]],
	"bar_back_far": [["pour", Vector3(1.66, 1.5, 2.83)], ["pour", Vector3(1.66, 1.5, 2.64)], ["wipe", Vector3(1.62, 1.135, 3.3)]],
	"bar_back_till": [["till", Vector3(1.6, 1.39, 7.18)], ["wipe", Vector3(1.62, 1.135, 6.45)]],
}

var stage: Stage
var t := 0.0
var next := {}              # what -> when it's next due
var later: Array = []       # [when, sound, point, how loud, how near for full]: the rest of something begun
var shots := 0              # balls struck since the last break
var rack := 9               # and how many till the next
var _tick := 0.0


func update(dt: float) -> void:
	t += dt
	var i := 0
	while i < later.size():
		var l: Array = later[i]
		if t >= float(l[0]):
			stage.sound.emit(l[1], l[2], l[3], l[4])
			later.remove_at(i)
		else:
			i += 1
	_tick -= dt
	if _tick > 0.0 or stage.view == null:
		return
	_tick = 0.25
	var place := stage.view.place
	# away from the Sov (the office, the town) there's none of it to hear
	if Posts.away(place):
		return
	if place != "t28" and _due("laugh", _laugh_gap()):
		_t28_laugh()
	if place != "t28" and _due("tv", randf_range(150.0, 320.0)):
		_t28_tv()
	_pool()
	if _due("work", randf_range(5.0, 14.0)):
		_bartender()
	if _due("cough", randf_range(50.0, 150.0)):
		_cough()
	if _due("lighter", randf_range(40.0, 100.0)):
		_lighter()
	if _due("spill", randf_range(360.0, 720.0)):
		_spill()
	if _due("wc", randf_range(200.0, 420.0)):
		_wc()


# Whether it's time for something (and when it's next due after that, `gap` seconds on). Not the
# first time it's asked: everything starts a while into the night.
func _due(what: String, gap: float) -> bool:
	if not next.has(what):
		next[what] = t + gap * randf_range(0.3, 1.0)
		return false
	if t < float(next[what]):
		return false
	next[what] = t + gap
	return true


# A sound of the room's from where it happens, now or in a moment.
func hear(id: String, pos: Vector3, gain: float, reach: float, after := 0.0) -> void:
	if after <= 0.0:
		stage.sound.emit(id, pos, gain, reach)
	else:
		later.append([t + after, id, pos, gain, reach])


func _night(name: String) -> int:
	return int(BUtil.js_int(stage._v.get(name, 0)))


# who's where, sitting or standing, not on their way somewhere
func _at(prefix: String) -> Array:
	var out: Array = []
	for id in stage.figures:
		if stage.walkers.has(id):
			continue
		if str(stage.figures[id].spot).begins_with(prefix):
			out.append(id)
	return out


# ---------------------------------------------------------------- table 28

# the longer they've been at it, the readier they are to laugh
func _laugh_gap() -> float:
	return lerpf(75.0, 30.0, clampf(_night("t28_rounds") / 6.0, 0.0, 1.0)) * randf_range(0.6, 1.4)


func _t28_laugh() -> void:
	var at: Array = _at("t28_").filter(func(id): return stage.life.idle(id))
	if at.size() < 2:
		return
	at.shuffle()
	var n := mini(at.size(), 2 + randi() % 3)
	stage.life.laugh(at[0], randf_range(0.8, 1.0))
	for k in range(1, n):
		stage.life.laugh(at[k], randf_range(0.4, 0.85), randf_range(0.1, 0.5))
	hear("laugh", Pub.T28 + Vector3(0, 1.15, 0), 0.55 + 0.12 * n, 2.5)
	if randf() < 0.3:
		hear("slap", Pub.T28 + Vector3(randf_range(-0.3, 0.3), TABLE_Y + 0.02, randf_range(-0.3, 0.3)), 0.8, 1.2, 0.25)


# The hockey: all of them up at it at once, and then a goal (up they go), a near thing (a groan), or
# nothing much and back to their glasses.
func _t28_tv() -> void:
	var at: Array = _at("t28_").filter(func(id): return stage.life.idle(id))
	if at.is_empty():
		return
	for id in at:
		stage.life.look_over(id, TV, randf_range(2.5, 4.5))
	var r := randf()
	if r < 0.3:
		hear("cheer", Pub.T28 + Vector3(0, 1.2, 0), 0.9, 2.5, 1.6)
		for id in at:
			if randf() < 0.7:
				stage.life.laugh(id, randf_range(0.5, 0.8), randf_range(1.6, 2.0))
	elif r < 0.6:
		hear("groan", Pub.T28 + Vector3(0, 1.2, 0), 0.8, 2.5, 1.4)


# ---------------------------------------------------------------- the pool game

# The big man and his buddy at the table: a shot every so often, the harder the game's got the
# quicker, heard only while the table's out of his sight (the cue on the ball, the balls into each
# other, now and then one dropping), and every so many a new rack broken.
func _pool() -> void:
	var on := false
	for id in ["bigman", "buddy"]:
		var f = stage.figures.get(id)
		if f != null and str(f.spot).begins_with("pool") and not stage.walkers.has(id):
			on = true
	if not on:
		return
	var heat := float(_night("pool_heat"))
	if not _due("pool", lerpf(24.0, 11.0, clampf(heat / 6.0, 0.0, 1.0)) * randf_range(0.6, 1.4)):
		return
	if stage.in_sight(Pub.POOL + Vector3(0, 0.9, 0), "room"):
		next["pool"] = t + 2.0
		return
	shots += 1
	if shots > rack:
		shots = 0
		rack = randi_range(7, 12)
		hear("break", Vector3(FELT.position.x + 0.45, FELT_Y, FELT.get_center().y), 1.0, 2.0)
		return
	var ball := Vector3(randf_range(FELT.position.x + 0.2, FELT.end.x - 0.2), FELT_Y, randf_range(FELT.position.y + 0.15, FELT.end.y - 0.15))
	var hard := randf_range(0.5, 1.0)
	hear("cue", ball, hard, 1.5)
	var hit := ball + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.25, 0.25))
	hear("clack", hit, 0.8 * hard, 1.5, randf_range(0.1, 0.4) / hard)
	if randf() < 0.35:
		var px: float = FELT.position.x + FELT.size.x * [0.0, 0.5, 1.0][randi() % 3]
		var pz: float = FELT.position.y + FELT.size.y * float(randi() % 2)
		hear("pocket", Vector3(px, FELT_Y - 0.1, pz), 0.9, 1.5, randf_range(0.7, 1.4))


# ---------------------------------------------------------------- the bartender

# Between serving: wiping the bar down in front of her, pulling a pint at the taps, at the till,
# by where she's standing. Not while she's talking, or on her way along the bar.
func _bartender() -> void:
	var id := "bartender"
	var f = stage.figures.get(id)
	if f == null or stage.walkers.has(id) or not stage.life.idle(id):
		return
	var spot := str(f.spot)
	var jobs: Array = WORK.get(spot, [])
	if jobs.is_empty():
		if not spot.begins_with("bar_back"):
			return
		jobs = [["wipe", (f.node as Node3D).to_global(Vector3(0.1, 1.135, -0.47))]]
	var job: Array = jobs[randi() % jobs.size()]
	var kind: String = job[0]
	var at: Vector3 = job[1]
	var secs: float = {"wipe": randf_range(3.0, 6.0), "pour": 3.6, "till": randf_range(1.4, 2.4)}[kind]
	if not stage.life.work(id, kind, at, secs):
		return
	match kind:
		"wipe":
			var s := 0.6
			while s < secs:
				hear("wipe", at, randf_range(0.6, 0.9), 1.0, s)
				s += randf_range(0.95, 1.2)
		"pour":
			hear("pour", Vector3(1.62, 1.25, at.z), 0.9, 1.2, 0.9)
			hear("glass_down", Vector3(1.8, 1.13, at.z + randf_range(-0.2, 0.2)), 0.7, 1.0, secs + 0.9)
		"till":
			hear("till", at, 0.8, 1.2, 0.6)


# ---------------------------------------------------------------- anyone

# A cough from somewhere in the room (or out on the deck, or in the hall).
func _cough() -> void:
	var ids: Array = []
	for id in stage.figures:
		if stage.walkers.has(id) or id == "bartender":
			continue
		if stage.figure_zone(id) in ["room", "vest", "deck", "hall"]:
			ids.append(id)
	if ids.is_empty():
		return
	var id: String = ids[randi() % ids.size()]
	if stage.life.idle(id):
		stage.life.cough(id)
	elif stage.life.has(id):
		return
	hear("cough", stage.head_of(id) + Vector3(0, -0.08, 0), randf_range(0.6, 1.0), 1.0)


# One of the smokers on the deck lighting up.
func _lighter() -> void:
	var ids: Array = _at("deck_")
	if ids.is_empty():
		return
	var id: String = ids[randi() % ids.size()]
	hear("lighter", stage.head_of(id) + Vector3(0, -0.12, 0), 0.8, 0.8)


# A glass knocked over at one of the tables: whoever's at it looks, one of them laughs at it, and
# the bartender looks across.
func _spill() -> void:
	var ids: Array = _at("table_")
	if ids.is_empty():
		return
	var id: String = ids[randi() % ids.size()]
	var s: Dictionary = stage.SPOTS[stage.figures[id].spot]
	var tb: Vector3 = s.face
	var at := Vector3(s.pos.x, TABLE_Y, s.pos.z).lerp(Vector3(tb.x, TABLE_Y, tb.z), 0.55)
	hear("spill", at, 1.0, 1.5)
	var near: Array = []
	for o in stage.figures:
		if stage.walkers.has(o) or not stage.life.has(o):
			continue
		if (stage.figures[o].node as Node3D).global_position.distance_to(at) < 2.2:
			near.append(o)
			stage.life.look_over(o, at, randf_range(1.5, 3.0))
	if not near.is_empty():
		var who: String = near[randi() % near.size()]
		stage.life.laugh(who, randf_range(0.3, 0.6), 0.9)
		hear("laugh_one", stage.head_of(who), 0.7, 1.2, 0.9)
	if stage.life.idle("bartender"):
		stage.life.look_over("bartender", at, randf_range(1.5, 2.5))


# Someone off to the washroom, if the night's leaving them be: up from where they are (a stool
# scraped back), down the back hall, and in; a minute or two, the flush, and back to their place.
func _wc() -> void:
	var ids: Array = []
	for id in WC:
		var f = stage.figures.get(id)
		if f == null or stage.walkers.has(id) or stage.away.has(id):
			continue
		if stage.figure_zone(id) != "room":
			continue
		# not from the table or the game he's at
		var spot := str(f.spot)
		if (spot.begins_with("t28") and stage.view.place == "t28") or (spot.begins_with("pool") and stage.view.place == "pool"):
			continue
		ids.append(id)
	if ids.is_empty():
		return
	stage.errand(ids[randi() % ids.size()], randf_range(50.0, 110.0))
