# What he overhears (content/rules/talk.yaml): the room talking among itself, a few lines at a time,
# written over the heads of the ones saying it as they say it, word by word with the jaw
# (world/life.gd's say), the others in it looking at whoever's talking. Near him it's clear;
# further off, or over a full room, it's fainter, and past earshot it isn't heard. One conversation
# at a time, each once a night; never with the ones at the table he's at, or the bartender while
# he's at the bar (that's the story's); never starting over the story's own lines, and broken off
# if the story wants one of them. When he's heard one through, a voice in his head can answer it
# (finished: main asks the engine, barks.yaml's ears:<id>).
#
# A line is written on a slip of the paper the night's printed on, over whoever says it, in the
# reading italic; one off the edge of his eyes is kept at the edge, on their side, pointing their
# way (behind him, on the side the conversation's on).
class_name Talk
extends Control

signal finished(id: String)

const EARSHOT := 7.5              # metres, in an empty room; a full one takes a third off it
const TOGETHER := 3.8             # as far apart as the ones in one conversation can be
const GAP := Vector2(9.0, 22.0)   # seconds from one conversation to the next
const BEAT := Vector2(0.25, 0.7)  # from one line to the next
const HOLD := 2.4                 # a line stays up this long after it's said
const FADE := 0.6
const WIDTH := 14.0               # how wide a slip runs before it wraps, in ems
# the room's people with no name in the story, who can be "a" and "b"
const STRANGERS := ["crew_a", "crew_b", "patron_a", "patron_b", "patron_c", "patron_d", "patron_e", "patron_f"]

var view: View
var stage: Stage
var vars := Callable()            # the Ink's value of a VAR, by name
var psyche_of := Callable()       # the voices in his head, for a criterion that asks about them
var can := Callable()             # whether the night's in a state for it at all
var rules: Array = []
var heard := {}                   # id -> true: heard tonight
var on := {}                      # the conversation going: {rule, cast {role: [ids]}, k, at}
var slips: Array = []             # what's written up: {who, text, t0, end, gone, fs, layout}
var next_at := 0.0
var done_at := -1.0               # when to say the last one's been heard through
var done_id := ""


func setup(v: View, s: Stage, src, get_var: Callable, psy: Callable, ok: Callable) -> void:
	view = v
	stage = s
	vars = get_var
	psyche_of = psy
	can = ok
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for r in (src if src is Array else []):
		if not (r is Dictionary) or not r.has("id"):
			continue
		var when: Array = []
		for c in (r.get("when", []) if r.get("when") is Array else []):
			when.append(Barks.parse_criterion(c))
		var lines: Array = []
		for ln in r.get("lines", []):
			if ln is Dictionary and ln.size() == 1:
				var who := str(ln.keys()[0])
				lines.append([who, str(ln[who])])
		if lines.is_empty():
			continue
		var roles: Array = []
		for ln in lines:
			if not ln[0] in roles:
				roles.append(ln[0])
		rules.append({"id": str(r.id), "when": when, "lines": lines, "roles": roles, "then": str(r.get("then", "")),
			"specificity": when.size()})
	reset()


func _now() -> float:
	return stage.life.t if stage != null else 0.0


# A new night, or one picked up: nothing heard yet, and a while before anything is.
func reset() -> void:
	heard.clear()
	slips.clear()
	on = {}
	done_at = -1.0
	next_at = _now() + randf_range(6.0, 12.0)
	queue_redraw()


# The story has one of the room speak: if they're in the conversation going, it breaks off there.
func interrupt(speaker: String) -> void:
	if on.is_empty():
		return
	var id: String = Stage.SPEAKS_FOR.get(speaker, speaker)
	for role in on.cast:
		if id in on.cast[role]:
			_stop()
			return


func _stop() -> void:
	var now := _now()
	for s in slips:
		s.gone = minf(float(s.gone), now)
	for role in on.cast:
		for id in on.cast[role]:
			stage.life.hush(id)
	on = {}
	next_at = now + randf_range(GAP.x, GAP.y)


func _process(_dt: float) -> void:
	if stage == null or view == null:
		return
	var now := _now()
	if done_at >= 0.0 and now >= done_at:
		done_at = -1.0
		finished.emit(done_id)
	_run(now)
	var keep: Array = []
	for s in slips:
		if now < float(s.gone) + FADE:
			keep.append(s)
	var had := not slips.is_empty()
	slips = keep
	if had:
		queue_redraw()


func _run(now: float) -> void:
	if on.is_empty():
		if now < next_at:
			return
		next_at = now + 1.0
		if not can.call() or Posts.away(view.place) or stage.life.talk_free > now:
			return
		var pick := _choose()
		if pick.is_empty():
			return
		on = pick
		on.k = 0
		on.at = now
		heard[str(pick.rule.id)] = true
	if now < float(on.at):
		return
	if not _still():
		_stop()
		return
	var lines: Array = on.rule.lines
	var k: int = on.k
	if k >= lines.size():
		_then(now)
		return
	var role: String = lines[k][0]
	var text: String = lines[k][1]
	# said to whoever answers it, or else to whoever it answers
	var to := ""
	for j in [k + 1, k - 1]:
		if j >= 0 and j < lines.size() and lines[j][0] != role and lines[j][0] != "table28":
			to = (on.cast[lines[j][0]] as Array)[0]
			break
	var end := now
	for id in on.cast[role]:
		end = maxf(end, stage.life.say(id, text, "" if role == "table28" else to))
	# everyone else in it looks at whoever's talking
	var first: String = (on.cast[role] as Array)[0]
	if role != "table28":
		for r in on.cast:
			if r == role:
				continue
			for id in on.cast[r]:
				stage.life.listen(id, first, end)
	_slip(role, first, text, now + 0.06, end, _middle())
	on.k = k + 1
	on.at = end + randf_range(BEAT.x, BEAT.y)


# After the last line: they laugh at it, or the glasses go together; and in a moment, it's been heard.
func _then(now: float) -> void:
	var ids := _everyone()
	var c := _middle()
	match str(on.rule.then):
		"laugh":
			for id in ids:
				stage.life.laugh(id, randf_range(0.4, 0.9), randf_range(0.0, 0.35))
			stage.doings.hear("laugh" if ids.size() >= 3 else "laugh_one", c, 0.75, 1.5)
		"clink":
			for d in [0.0, 0.12, 0.3]:
				stage.doings.hear("clink", Vector3(c.x + randf_range(-0.3, 0.3), 1.0, c.z + randf_range(-0.3, 0.3)), 0.8, 1.2, d)
	done_id = str(on.rule.id)
	done_at = now + 0.8
	on = {}
	next_at = now + randf_range(GAP.x, GAP.y)


func _everyone() -> Array:
	var ids: Array = []
	for role in on.cast:
		for id in on.cast[role]:
			if not id in ids:
				ids.append(id)
	return ids


# where the conversation is: the middle of the ones in it
func _middle() -> Vector3:
	var ids := _everyone()
	var c := Vector3.ZERO
	for id in ids:
		c += stage.head_of(id)
	return c / maxf(1.0, float(ids.size()))


func _still() -> bool:
	for role in on.cast:
		for id in on.cast[role]:
			if not stage.figures.has(id) or stage.walkers.has(id) or stage.away.has(id):
				return false
	return true


# ---------------------------------------------------------------- what's said, by whom

# The most specific conversation that can happen now, then the nearest.
func _choose() -> Dictionary:
	var eye := view.eye_pos
	var mine := Sound._space(Hotspots.zone_of(eye))
	var reach := _reach()
	var psyche = psyche_of.call()
	var best := {}
	var top := -1
	var near := INF
	for r in rules:
		if heard.has(r.id) or int(r.specificity) < top:
			continue
		var ok := true
		for c in r.when:
			if not Barks.test(c, vars, psyche, ""):
				ok = false
				break
		if not ok:
			continue
		var cast := _cast(r, eye, reach, mine)
		if cast.is_empty():
			continue
		var d: float = cast.d
		if int(r.specificity) > top or d < near:
			top = int(r.specificity)
			near = d
			best = {"rule": r, "cast": cast.ids}
	return best


func _reach() -> float:
	var crowd := clampf(BUtil.js_num(vars.call("room_count")) / 24.0, 0.0, 1.0)
	return EARSHOT * (1.0 - crowd / 3.0)


# Who'd say it: the ones it names, if they're about and free, then strangers beside them (or, with
# nobody named, any two together); all of them near each other, near enough to him to be heard, in
# the part of the building he's in, and one of them where he can see them, or else all of them
# close by (behind him, say). {} if it can't be. d: how far off they are, the ones he can't see
# counted further, so what's in front of him comes first.
func _cast(r: Dictionary, eye: Vector3, reach: float, mine: String) -> Dictionary:
	var ids := {}
	var used: Array = []
	var pts: Array = []
	for role in r.roles:
		if role == "a" or role == "b":
			continue
		var list: Array = []
		if role == "table28":
			if view.place == "t28":
				return {}
			for id in stage.figures:
				if str(stage.figures[id].spot).begins_with("t28_") and _free(id):
					list.append(id)
			if list.size() < 3:
				return {}
		else:
			if not _free(role) or _his(role):
				return {}
			list = [role]
		ids[role] = list
		for id in list:
			if not id in used:
				used.append(id)
				pts.append(stage.head_of(id))
	for role in r.roles:
		if role != "a" and role != "b":
			continue
		var pick := ""
		var pd := INF
		for id in STRANGERS:
			if id in used or not _free(id):
				continue
			var h := stage.head_of(id)
			var d := INF
			if pts.is_empty():
				for o in STRANGERS:
					if o != id and _free(o) and stage.head_of(o).distance_to(h) < TOGETHER:
						d = h.distance_to(eye)
						break
			else:
				for q in pts:
					d = minf(d, (q as Vector3).distance_to(h))
				if d > TOGETHER:
					d = INF
			if d < pd:
				pd = d
				pick = id
		if pick == "":
			return {}
		ids[role] = [pick]
		used.append(pick)
		pts.append(stage.head_of(pick))
	var seen := false
	var sum := 0.0
	var far := 0.0
	for i in pts.size():
		var h: Vector3 = pts[i]
		if h == Vector3.INF or h.distance_to(eye) > reach:
			return {}
		if Sound._space(Hotspots.zone_of(h)) != mine:
			return {}
		for j in range(i + 1, pts.size()):
			if h.distance_to(pts[j]) > TOGETHER:
				return {}
		sum += h.distance_to(eye)
		far = maxf(far, h.distance_to(eye))
		if not seen and stage.in_sight(h, Hotspots.zone_of(h)):
			seen = true
	if not seen and far > reach * 0.7:
		return {}
	return {"ids": ids, "d": sum / maxf(1.0, float(pts.size())) + (0.0 if seen else 3.0)}


# about, and not on their way anywhere or saying something already
func _free(id: String) -> bool:
	if not stage.figures.has(id) or stage.walkers.has(id) or stage.away.has(id):
		return false
	var p = stage.life.people.get(id)
	return p == null or (p.talk as Array).is_empty()


# at the place he's at, where the story has them
func _his(id: String) -> bool:
	var spot := str(stage.figures[id].spot)
	match view.place:
		"t28":
			return spot.begins_with("t28")
		"pool":
			return spot.begins_with("pool")
		"bar":
			return id == "bartender" or id == "endbar"
	return false


# ---------------------------------------------------------------- the slips

func _slip(role: String, id: String, text: String, t0: float, end: float, middle: Vector3) -> void:
	var who := "table28" if role == "table28" else id
	for s in slips:
		if s.who == who:
			s.gone = minf(float(s.gone), t0)
	slips.append({"who": who, "text": text, "t0": t0, "end": end, "gone": end + HOLD, "fs": -1, "layout": {},
		"middle": middle})


# over whoever's saying it (table 28 all at once: over the table)
func _anchor(s: Dictionary) -> Vector3:
	if s.who == "table28":
		return Pub.T28 + Vector3(0, 1.75, 0)
	var h := stage.head_of(str(s.who))
	return h + Vector3(0, 0.3, 0) if h != Vector3.INF else h


func _screen(p: Vector3) -> Vector3:
	var s := view.on_screen(p)
	if s.z <= 0.0:
		return s
	return Vector3(s.x - global_position.x, s.y - global_position.y, 1.0)


# The words laid out on the slip once for a size: each word's place, the lines centred.
func _layout(text: String, f: Font, fs: int) -> Dictionary:
	var max_w := WIDTH * fs
	var space := f.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var words: Array = []
	var line_w: Array = [0.0]
	var x := 0.0
	var line := 0
	var c := 0
	for w in text.split(" ", false):
		var ww := f.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		if x > 0.0 and x + ww > max_w:
			line += 1
			x = 0.0
			line_w.append(0.0)
		words.append([w, x, line, c])
		line_w[line] = x + ww
		x += ww + space
		c += w.length() + 1
	var widest := 0.0
	for lw in line_w:
		widest = maxf(widest, float(lw))
	return {"words": words, "w": widest, "lines": line + 1, "line_w": line_w, "chars": maxi(1, text.length())}


func _draw() -> void:
	if view == null or slips.is_empty():
		return
	var now := _now()
	var eye := view.eye_pos
	var reach := _reach()
	var f: Font = Look.font("read_i")
	var order: Array = []
	for s in slips:
		var at := _anchor(s)
		if at != Vector3.INF:
			order.append([at.distance_to(eye), s, at])
	# the furthest first, so the nearer are written over them
	order.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	var taken: Array = []
	for o in order:
		_draw_slip(o[1], o[2], float(o[0]), now, f, reach, taken)


func _draw_slip(s: Dictionary, at: Vector3, d: float, now: float, f: Font, reach: float, taken: Array) -> void:
	var a := clampf((now - float(s.t0)) / 0.15, 0.0, 1.0)
	if now > float(s.gone):
		a *= clampf(1.0 - (now - float(s.gone)) / FADE, 0.0, 1.0)
	# fainter further off (the words, not the slip they're on), and gone past earshot
	var k := clampf(1.0 - (d - reach * 0.6) / (reach * 0.5), 0.0, 1.0)
	var faint := maxf(k, 0.4) if d <= reach else k
	if d > reach:
		a *= k
	if a <= 0.01:
		return
	var base := size.y / 720.0
	var fs := int(round(clampf(lerpf(20.0, 14.0, (d - 1.5) / 6.0), 14.0, 20.0) * base))
	if int(s.fs) != fs:
		s.fs = fs
		s.layout = _layout(str(s.text), f, fs)
	var lay: Dictionary = s.layout
	var lh := f.get_height(fs)
	var pad := Vector2(0.6, 0.35) * fs
	var box := Vector2(float(lay.w), lh * int(lay.lines)) + pad * 2.0
	var sp := _screen(at)
	var edge := sp.z <= 0.0 or sp.x < 0.0 or sp.x > size.x or sp.y < 0.0 or sp.y > size.y
	var p := Vector2(sp.x, sp.y)
	var left := false
	if edge:
		# off the edge of his eyes: kept at the edge, on their side; behind him, on the side the
		# conversation's on, so one heard over his shoulder stays over the one shoulder
		var local := view.cam.global_transform.affine_inverse() * (at if sp.z > 0.0 else (s.middle as Vector3))
		left = local.x < 0.0
		p = Vector2(box.x * 0.5 + 22.0 if left else size.x - box.x * 0.5 - 22.0, clampf(sp.y if sp.z > 0.0 else size.y * 0.4, box.y + 12.0, size.y * 0.7))
		faint *= 0.85
	var r := Rect2(p - Vector2(box.x * 0.5, box.y + 7.0), box)
	r.position.x = clampf(r.position.x, 8.0, maxf(8.0, size.x - r.size.x - 8.0))
	r.position.y = clampf(r.position.y, 8.0, maxf(8.0, size.y - r.size.y - 8.0))
	for i in 6:
		var hit := false
		for q in taken:
			if (q as Rect2).intersects(r):
				r.position.y = (q as Rect2).position.y - r.size.y - 4.0
				hit = true
		if not hit:
			break
	taken.append(r)
	var paper := Color(Look.STOCK, 0.95 * a)
	var ink := Color(Look.NIGHT, a * (0.35 + 0.65 * faint))
	draw_rect(r, paper)
	draw_rect(r, Color(Look.NIGHT, 0.5 * a), false, 1.0)
	if not edge and absf(r.end.y + 7.0 - p.y) < 2.0:
		var bx := clampf(p.x, r.position.x + 10.0, r.end.x - 10.0)
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 6.0, r.end.y), Vector2(bx + 6.0, r.end.y), Vector2(bx, r.end.y + 7.0)]), paper)
	elif edge:
		# a point on its outer side, toward whoever's saying it
		var my := r.position.y + r.size.y * 0.5
		var ex := r.position.x if left else r.end.x
		var out := -1.0 if left else 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(ex, my - 7.0), Vector2(ex, my + 7.0), Vector2(ex + out * 9.0, my)]), paper)
	# the words said so far
	var said := (now - float(s.t0)) / maxf(float(s.end) - float(s.t0), 0.01) * float(lay.chars)
	for w in lay.words:
		if float(w[3]) > said:
			break
		var line: int = w[2]
		var off := (float(lay.w) - float(lay.line_w[line])) * 0.5
		var pos := r.position + pad + Vector2(off + float(w[1]), lh * line + f.get_ascent(fs))
		draw_string(f, pos, str(w[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
