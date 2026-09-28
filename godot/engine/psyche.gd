class_name Psyche
extends RefCounted
# The room in his head (prototype/web/src/core/psyche.js; bible/02_SYSTEMS.md, PROPOSED).
# Up to five voices sit in the room. Every pair is allied (+1) or at odds (-1). No voice has a
# level. Tension is the frustration index of the seated voices: the fewest conflicts left after
# any set of voices reverses all its loyalties, 0 to 4 for five voices. With exactly five seated,
# the room is one of the 34 states in content/data/psyche_states.json.

const MAX_SEATS := 5

static var _perms5: Array = []

var defs: Dictionary = {}
var seated: Array = []
var rel: Dictionary = {}          # explicit relationships, set in play; defaults come from the voice data
var learned: Array = []           # voices he has, in the room or not
var history: Array = []           # tension over the night
var state_index: Dictionary = {}
var classes: Dictionary = {}


static func pair_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


static func _permutations(n: int) -> Array:
	var out: Array = []
	var a: Array = []
	for i in range(n):
		a.append(i)
	_perm_rec(a, 0, n, out)
	return out


static func _perm_rec(a: Array, k: int, n: int, out: Array) -> void:
	if k == n:
		out.append(a.duplicate())
		return
	for i in range(k, n):
		var t = a[k]; a[k] = a[i]; a[i] = t
		_perm_rec(a, k + 1, n, out)
		t = a[k]; a[k] = a[i]; a[i] = t


# Canonical string for a set of conflict pairs on 5 labelled points, up to relabelling.
static func canon_conflicts(pairs: Array) -> String:
	if _perms5.is_empty():
		_perms5 = _permutations(5)
	var best = null
	for p in _perms5:
		var mapped: Array = []
		for e in pairs:
			var x: int = p[int(e[0])]
			var y: int = p[int(e[1])]
			mapped.append(x * 5 + y if x < y else y * 5 + x)
		mapped.sort()
		var parts := PackedStringArray()
		for m in mapped:
			parts.append(str(m))
		var s := ",".join(parts)
		if best == null or s < best:
			best = s
	return "" if best == null else best


func _init(voice_defs: Dictionary = {}, states_data = null) -> void:
	defs = voice_defs
	if states_data is Dictionary and states_data.has("states"):
		for s in states_data["states"]:
			state_index[canon_conflicts(s.get("conflicts", []))] = s
		for c in states_data.get("classes", []):
			classes[c.get("class")] = c


func reset(initial_seated: Array) -> void:
	seated = []
	rel = {}
	learned = []
	history = []
	for id in initial_seated:
		learn(id)
		seat(id)


func known(id: String) -> bool:
	return defs.has(id)


func learn(id: String) -> bool:
	if not known(id):
		return false
	if not learned.has(id):
		learned.append(id)
	return true


func is_seated(id: String) -> bool:
	return seated.has(id)


func is_full() -> bool:
	return seated.size() >= MAX_SEATS


func seat(id: String) -> bool:
	if not known(id) or is_seated(id) or is_full():
		return false
	learn(id)
	seated.append(id)
	return true


func unseat(id: String) -> bool:
	var i := seated.find(id)
	if i == -1:
		return false
	seated.remove_at(i)
	return true


func get_rel(a: String, b: String) -> int:
	if a == b:
		return 1
	var k := pair_key(a, b)
	if rel.has(k):
		return int(rel[k])
	var da = defs.get(a)
	var db = defs.get(b)
	if da is Dictionary and da.get("relations") is Dictionary and da["relations"].has(b) and da["relations"][b] != null:
		return -1 if float(da["relations"][b]) < 0 else 1
	if db is Dictionary and db.get("relations") is Dictionary and db["relations"].has(a) and db["relations"][a] != null:
		return -1 if float(db["relations"][a]) < 0 else 1
	return 1


func set_rel(a: String, b: String, sign) -> bool:
	if not known(a) or not known(b) or a == b:
		return false
	rel[pair_key(a, b)] = -1 if float(sign) < 0 else 1
	return true


# Frustration index over the seated voices (or over the given ones, for a preview).
func tension(seated_override = null) -> int:
	var s: Array = seated_override if seated_override != null else seated
	var n := s.size()
	if n < 3:
		return 0
	var sign: Array = []
	for i in range(n):
		var row: Array = []
		for j in range(n):
			row.append(1 if i == j else get_rel(s[i], s[j]))
		sign.append(row)
	var best := 1 << 30
	# switching every voice is the same as switching none, so voice 0 stays put
	for mask in range(1 << (n - 1)):
		var bits := mask << 1
		var neg := 0
		for i in range(n):
			for j in range(i + 1, n):
				var flip := ((bits >> i) & 1) != ((bits >> j) & 1)
				var v: int = -sign[i][j] if flip else sign[i][j]
				if v < 0:
					neg += 1
		if neg < best:
			best = neg
	return best


func conflicts() -> Array:
	var out: Array = []
	for i in range(seated.size()):
		for j in range(i + 1, seated.size()):
			if get_rel(seated[i], seated[j]) < 0:
				out.append([seated[i], seated[j]])
	return out


# With five seated: which of the 34 states the room is in.
func state() -> Dictionary:
	var t := tension()
	if seated.size() != MAX_SEATS or state_index.is_empty():
		return {"tension": t, "id": null, "cls": null, "seats": seated.size()}
	var idx := {}
	for i in range(seated.size()):
		idx[seated[i]] = i
	var pairs: Array = []
	for c in conflicts():
		pairs.append([idx[c[0]], idx[c[1]]])
	var st = state_index.get(canon_conflicts(pairs))
	return {"tension": t, "id": st.get("id") if st != null else null, "cls": st.get("class") if st != null else null,
		"note": (st.get("note", "") if st.get("note") != null else "") if st != null else "", "seats": 5}


func record(clock: int) -> void:
	var t := tension()
	var last = history.back() if not history.is_empty() else null
	if last == null or last.t != t or last.seats != seated.size():
		history.append({"clock": clock, "t": t, "seats": seated.size()})
	if history.size() > 200:
		history.pop_front()


func to_json() -> Dictionary:
	return {"seated": seated.duplicate(), "rel": rel.duplicate(), "learned": learned.duplicate(), "history": history.slice(-100)}


func from_json(o) -> void:
	if not (o is Dictionary):
		return
	seated = []
	for v in o.get("seated", []):
		if known(str(v)) and seated.size() < MAX_SEATS:
			seated.append(str(v))
	rel = {}
	var r = o.get("rel", {})
	if r is Dictionary:
		for k in r:
			rel[k] = int(r[k])
	learned = []
	for v in o.get("learned", []):
		if known(str(v)):
			learned.append(str(v))
	history = []
	for h in o.get("history", []):
		history.append({"clock": int(h.get("clock", 0)), "t": int(h.get("t", 0)), "seats": int(h.get("seats", 0))})
