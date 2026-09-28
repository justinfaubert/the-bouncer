class_name Checks
extends RefCounted
# Checks (prototype/web/src/core/checks.js). A voice lends him its way of seeing, and he rolls two
# dice. No skill levels. What moves the odds: the voice's base, drink, hurt for physical voices, a
# modifier written into the choice's tag, and tension, which stretches the dice's distance from 7
# (volatility, not the average). Double one always fails, double six always succeeds.

const WORDS := [[5, "Trivial"], [7, "Easy"], [9, "Medium"], [11, "Hard"], [13, "Very hard"], [99, "Near impossible"]]


static func difficulty_word(target: int) -> String:
	for w in WORDS:
		if target <= w[0]:
			return w[1]
	return "Near impossible"


static func volatility(tension: int) -> float:
	return 1.0 + 0.35 * maxi(0, tension)


static func scaled(d1: int, d2: int, tension: int) -> int:
	return 7 + BUtil.js_round((d1 + d2 - 7) * volatility(tension))


static func resolve(d1: int, d2: int, target: int, mod: int, tension: int) -> Dictionary:
	var natural := d1 + d2
	var total := scaled(d1, d2, tension) + mod
	var success := total >= target
	var crit = null
	if natural == 2:
		success = false
		crit = "fail"
	if natural == 12:
		success = true
		crit = "success"
	return {"d1": d1, "d2": d2, "natural": natural, "total": total, "target": target, "mod": mod, "tension": tension, "success": success, "crit": crit}


static func odds(target: int, mod: int, tension: int) -> float:
	var wins := 0
	for a in range(1, 7):
		for b in range(1, 7):
			if resolve(a, b, target, mod, tension).success:
				wins += 1
	return wins / 36.0


static func odds_word(p: float) -> String:
	if p >= 0.97: return "certain"
	if p >= 0.8: return "near certain"
	if p >= 0.62: return "likely"
	if p >= 0.42: return "even"
	if p >= 0.25: return "unlikely"
	if p >= 0.1: return "long shot"
	return "hopeless"


# Everything that feeds a check besides the dice.
static func modifiers(voice_def, drinks_v, hurt_v, tag_mod) -> Dictionary:
	var parts: Array = []
	var base := 0
	if voice_def is Dictionary and not voice_def.is_empty():
		base = BUtil.js_int(voice_def.get("base", 0))
	if base != 0:
		parts.append({"label": "source", "value": base})
	var drinks := maxi(0, BUtil.js_int(drinks_v))
	if voice_def is Dictionary and voice_def.get("drink") is Array and voice_def["drink"].size() > 0:
		var dl: Array = voice_def["drink"]
		var d := BUtil.js_int(dl[mini(drinks, dl.size() - 1)])
		if d != 0:
			parts.append({"label": "1 drink" if drinks == 1 else "%d drinks" % drinks, "value": d})
	if voice_def is Dictionary and BUtil.js_truthy(voice_def.get("physical")) and BUtil.js_truthy(hurt_v):
		parts.append({"label": "hurt", "value": -BUtil.js_int(hurt_v)})
	if BUtil.js_truthy(tag_mod):
		parts.append({"label": "situation", "value": BUtil.js_int(tag_mod)})
	var total := 0
	for p in parts:
		total += p.value
	return {"total": total, "parts": parts}


# "#check: father 8 2" -> {voice: father, target: 8, mod: 2}
static func parse_spec(value):
	var bits := BUtil.split_ws(BUtil.js_trim(BUtil.js_str(value)))
	if bits[0] == "":
		return null
	var target = BUtil.js_parse_int(bits[1]) if bits.size() > 1 else null
	var mod = BUtil.js_parse_int(bits[2]) if bits.size() > 2 else 0
	return {"voice": bits[0].to_lower(), "target": 8 if target == null else target, "mod": 0 if mod == null else mod}


static func roll(rng: BRng, target: int, mod: int, tension: int) -> Dictionary:
	var d1 := rng.d6()
	var d2 := rng.d6()
	return resolve(d1, d2, target, mod, tension)
