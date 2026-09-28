class_name Word
extends RefCounted
# The word on him (prototype/web/src/core/barks.js, Word): what a group says about him when
# something he's done lands with them, by its own code. Authored in content/rules/word.yaml.
# The most specific rule that holds wins, a rule already said is passed over, and when every line
# for a group has been said, the ones marked once: false come round again.

var names: Dictionary = {}
var rules: Array = []


func _init(spec = {}) -> void:
	if not (spec is Dictionary):
		spec = {}
	names = spec.get("groups", {}) if spec.get("groups") is Dictionary else {}
	var i := 0
	for r in (spec.get("lines", []) if spec.get("lines") is Array else []):
		var when: Array = []
		for c in (r.get("when", []) if r.get("when") is Array else []):
			when.append(Barks.parse_criterion(c))
		rules.append({"id": str(r["id"]) if BUtil.js_truthy(r.get("id")) else "word_%d" % i,
			"group": str(r.get("group", "")) if r.get("group") != null else "",
			"way": str(r.get("way", "")) if r.get("way") != null else "",
			"text": r.get("text"), "when": when,
			"once": not (r.get("once") is bool and r.get("once") == false), "specificity": when.size()})
		i += 1


func groups() -> Array:
	var out: Array = names.keys()
	for r in rules:
		if not out.has(r.group):
			out.append(r.group)
	return out


func name_of(group: String) -> String:
	return str(names[group]) if BUtil.js_truthy(names.get(group)) else group


func by_id(id: String):
	for r in rules:
		if r.id == id:
			return r
	return null


func pick(group: String, way: String, by: int, now: int, get_var: Callable, psyche: Psyche, used: Array, rng: BRng):
	var vars := func(n: String):
		if n == "by":
			return by
		if n == "now":
			return now
		return get_var.call(n)
	var cands: Array = []
	for r in rules:
		if r.group != group or r.way != way:
			continue
		if r.once and used.has(r.id):
			continue
		var ok := true
		for c in r.when:
			if not Barks.test(c, vars, psyche, ""):
				ok = false
				break
		if ok:
			cands.append(r)
	if cands.is_empty():
		return null
	# lines not yet said tonight first, the most specific of them, and a one-off before a line that
	# can come round again; a repeatable line that's been said waits until nothing else is left
	var fresh: Array = []
	for r in cands:
		if not used.has(r.id):
			fresh.append(r)
	var pool: Array = fresh if not fresh.is_empty() else cands
	var top := -1
	for r in pool:
		top = maxi(top, r.specificity * 2 + (1 if r.once else 0))
	var best: Array = []
	for r in pool:
		if r.specificity * 2 + (1 if r.once else 0) == top:
			best.append(r)
	return rng.pick(best)
