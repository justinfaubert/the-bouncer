class_name Barks
extends RefCounted
# Rule-matched lines (prototype/web/src/core/barks.js), after Valve's dialogue system: many short
# lines, each tied to facts about the world, where the most specific match wins. Authored in
# content/rules/barks.yaml; see that file and the browser build for the rule format.
#
# Criteria:  <var> <op> <number|true|false|word>   (op: >= <= > < == != has hasnt)
#            seated <voice> / unseated <voice> / ally <voice> / odds <voice> / tension <op> <n>

# Chance that a voice speaks up at all, by tension. At 0 the room is quiet.
const CHANCE := [0.0, 0.45, 0.65, 0.85, 1.0]
# and a heeded voice's, for every read of his he's kept (never at 0): see barks.js, Heeded voices
const HEED := 0.08

static var _crit: RegEx
static var _seat: RegEx
static var _numeric: RegEx

var rules: Array = []


static func _regexes() -> void:
	if _crit == null:
		_crit = RegEx.create_from_string("(?i)^\\s*([a-z_][a-z0-9_]*)\\s*(>=|<=|==|!=|>|<|has|hasnt)\\s*([a-z0-9_.\\-]+)\\s*$")
		_seat = RegEx.create_from_string("(?i)^\\s*(seated|unseated|ally|odds)\\s+([a-z_][a-z0-9_]*)\\s*$")
		_numeric = RegEx.create_from_string("^-?\\d+(\\.\\d+)?$")


static func parse_criterion(s) -> Dictionary:
	_regexes()
	var src := str(s)
	var m := _seat.search(src)
	if m != null:
		return {"kind": m.get_string(1).to_lower(), "voice": m.get_string(2).to_lower(), "src": src}
	m = _crit.search(src)
	if m == null:
		return {"kind": "bad", "src": src}
	var val = m.get_string(3)
	if _numeric.search(val) != null:
		val = val.to_float()
	elif val == "true":
		val = true
	elif val == "false":
		val = false
	return {"kind": "cmp", "name": m.get_string(1), "op": m.get_string(2).to_lower(), "value": val, "src": src}


static func compile(src_rules) -> Array:
	var out: Array = []
	var i := 0
	for r in (src_rules if src_rules is Array else []):
		var when: Array = []
		for c in (r.get("when", []) if r.get("when") is Array else []):
			when.append(parse_criterion(c))
		out.append({
			"id": str(r["id"]) if BUtil.js_truthy(r.get("id")) else "bark_%d" % i,
			"on": r.get("on"),
			"speaker": (str(r["speaker"]) if BUtil.js_truthy(r.get("speaker")) else "").to_lower(),
			"text": r.get("text"),
			"when": when,
			"once": not (r.get("once") is bool and r.get("once") == false),
			"always": BUtil.js_truthy(r.get("always")),
			"mark": str(r["mark"]) if BUtil.js_truthy(r.get("mark")) else null,
			"specificity": when.size(),
		})
		i += 1
	return out


static func list_has(v, item) -> bool:
	if v == null:
		return false
	if v is Object and v.has_method("contains_item_named"):
		if item is bool:
			return false
		return v.contains_item_named(BUtil.js_str(item))
	if v is Array:
		return v.has(item)
	return BUtil.js_str(v) == BUtil.js_str(item) if item is String else false


# get_var: Callable(name) -> value
static func test(c: Dictionary, get_var: Callable, psyche: Psyche, speaker: String) -> bool:
	var k: String = c.kind
	if k == "seated":
		return psyche.is_seated(c.voice)
	if k == "unseated":
		return not psyche.is_seated(c.voice)
	if k == "ally" or k == "odds":
		if not psyche.is_seated(c.voice) or c.voice == speaker:
			return false
		var r := psyche.get_rel(speaker, c.voice)
		return r > 0 if k == "ally" else r < 0
	if k != "cmp":
		return false
	var v = psyche.tension() if c.name == "tension" else get_var.call(c.name)
	match c.op:
		"has": return list_has(v, c.value)
		"hasnt": return not list_has(v, c.value)
		"==": return BUtil.js_loose_eq(v, c.value) or BUtil.js_str(v) == BUtil.js_str(c.value)
		"!=": return not (BUtil.js_loose_eq(v, c.value) or BUtil.js_str(v) == BUtil.js_str(c.value))
		">=": return BUtil.js_num(v) >= BUtil.js_num(c.value)
		"<=": return BUtil.js_num(v) <= BUtil.js_num(c.value)
		">": return BUtil.js_num(v) > BUtil.js_num(c.value)
		"<": return BUtil.js_num(v) < BUtil.js_num(c.value)
	return false


func _init(src_rules = []) -> void:
	rules = compile(src_rules)


# not_voice: a voice that may not speak (the one being answered)
func candidates(event: String, get_var: Callable, psyche: Psyche, used: Array, not_voice = null) -> Array:
	var out: Array = []
	for r in rules:
		if r.on != event:
			continue
		if r.once and used.has(r.id):
			continue
		if not psyche.is_seated(r.speaker) or r.speaker == not_voice:
			continue
		var ok := true
		for c in r.when:
			if not test(c, get_var, psyche, r.speaker):
				ok = false
				break
		if ok:
			out.append(r)
	return out


# The most specific rule that holds, whatever the noise in his head.
func best(event: String, get_var: Callable, psyche: Psyche, used: Array, rng: BRng, not_voice = null):
	var cands := candidates(event, get_var, psyche, used, not_voice)
	if cands.is_empty():
		return null
	var top := -1
	for r in cands:
		if r.specificity > top:
			top = r.specificity
	# a heeded voice's rule goes in once more for each read of his he's kept
	var pool: Array = []
	for r in cands:
		if r.specificity != top:
			continue
		for k in 1 + psyche.heeded(r.speaker):
			pool.append(r)
	return rng.pick(pool)


func pick(event: String, get_var: Callable, psyche: Psyche, used: Array, rng: BRng, not_voice = null):
	var rule = best(event, get_var, psyche, used, rng, not_voice)
	if rule == null:
		return null
	if not rule.always:
		var t := mini(4, psyche.tension())
		var chance: float = minf(1.0, CHANCE[t] + HEED * psyche.heeded(str(rule.speaker))) if t > 0 else 0.0
		if rng.next() >= chance:
			return null
	return rule
