class_name Checks
extends RefCounted
# Checks (prototype/web/src/core/checks.js). A voice lends him its way of seeing, he brings one of
# his stats to it, and he rolls two dice. What moves the odds: the stat the check is rolled on,
# added to the dice (his seven, 1 to 10, set in Gary's office; the one the check names, or the
# voice's first), the voice's base, drink (the drinks that show: Constitution and a meal hold some),
# hurt for physical voices, nothing to eat before the shift (the body's checks down, Gut Brain's
# up), a modifier written into the choice's tag, and tension, which stretches the dice's distance
# from 7 (volatility, not the average). Double one always fails, double six always succeeds. An
# ordinary man's stat is 4, so a target of 12 is what 8 was before the stats.

const WORDS := [[9, "Trivial"], [11, "Easy"], [13, "Medium"], [15, "Hard"], [17, "Very hard"], [99, "Near impossible"]]

# His seven stats: the Ink's VAR for each (content/ink/main.ink), and its name on a check.
const STATS := {
	"str": {"v": "stat_str", "label": "Strength"},
	"con": {"v": "stat_con", "label": "Constitution"},
	"dex": {"v": "stat_dex", "label": "Dexterity"},
	"int": {"v": "stat_int", "label": "Intelligence"},
	"wis": {"v": "stat_wis", "label": "Wisdom"},
	"cha": {"v": "stat_cha", "label": "Charisma"},
	"gut": {"v": "stat_gut", "label": "Gut Brain"},
}
const STAT_ORDER := ["str", "con", "dex", "int", "wis", "cha", "gut"]


# all seven, read from the story: get.call(name) -> its value
static func read_stats(get: Callable) -> Dictionary:
	var out := {}
	for k in STAT_ORDER:
		out[k] = BUtil.js_int(get.call(STATS[k].v))
	return out


# the stat a check is rolled on: the one it names, or the voice's first
static func stat_of(voice_def, stat := "") -> String:
	if stat != "" and STATS.has(stat):
		return stat
	var list: Array = voice_def.get("stats") if voice_def is Dictionary and voice_def.get("stats") is Array else []
	return str(list[0]) if not list.is_empty() and STATS.has(str(list[0])) else ""


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


# The drinks that show. Constitution holds some of them, none at 3 or 4, one at 5 or 6, two at 7
# or 8, three at 9 or 10, and at 1 or 2 he feels one more than he's had; a meal before the shift
# holds one more (ate: 1 he ate, -1 he didn't, 0 nobody asked).
static func felt(drinks_v, stats, ate_v) -> int:
	var drinks := maxi(0, BUtil.js_int(drinks_v))
	if drinks == 0:
		return 0
	var con := BUtil.js_int(stats.get("con")) if stats is Dictionary else 0
	if con == 0:
		con = 4
	var holds := floori((con - 3) / 2.0) + (1 if BUtil.js_int(ate_v) > 0 else 0)
	return maxi(0, drinks - holds)


static func drinks_label(drinks: int, f: int) -> String:
	if drinks == 0:
		return "sober"
	var n := "1 drink" if drinks == 1 else "%d drinks" % drinks
	return n if f == drinks else n + " (feels like " + (str(f) if f != 0 else "none") + ")"


# Everything that feeds a check besides the dice. ctx: {drinks, hurt, stats: read_stats(), ate}
static func modifiers(voice_def, ctx: Dictionary, tag_mod, stat := "") -> Dictionary:
	var parts: Array = []
	var st := stat_of(voice_def, stat)
	if st != "":
		var sv: Dictionary = ctx.get("stats") if ctx.get("stats") is Dictionary else {}
		parts.append({"label": STATS[st].label, "value": BUtil.js_int(sv.get(st)), "stat": st})
	var drinks_v = ctx.get("drinks")
	var hurt_v = ctx.get("hurt")
	var base := 0
	if voice_def is Dictionary and not voice_def.is_empty():
		base = BUtil.js_int(voice_def.get("base", 0))
	if base != 0:
		parts.append({"label": "source", "value": base})
	var drinks := maxi(0, BUtil.js_int(drinks_v))
	if voice_def is Dictionary and voice_def.get("drink") is Array and voice_def["drink"].size() > 0:
		var dl: Array = voice_def["drink"]
		var f := felt(drinks, ctx.get("stats"), ctx.get("ate"))
		var d := BUtil.js_int(dl[mini(f, dl.size() - 1)])
		if d != 0:
			parts.append({"label": drinks_label(drinks, f), "value": d})
	if voice_def is Dictionary and BUtil.js_truthy(voice_def.get("physical")) and BUtil.js_truthy(hurt_v):
		parts.append({"label": "hurt", "value": -BUtil.js_int(hurt_v)})
	# hunger sharpens his gut and costs his body (bible/11_SKELETON.md, Him: seven stats)
	if BUtil.js_int(ctx.get("ate")) < 0 and st != "":
		if st == "gut":
			parts.append({"label": "nothing to eat", "value": 1})
		elif st == "str" or st == "con" or st == "dex":
			parts.append({"label": "nothing to eat", "value": -1})
	if BUtil.js_truthy(tag_mod):
		parts.append({"label": "situation", "value": BUtil.js_int(tag_mod)})
	var total := 0
	for p in parts:
		total += p.value
	return {"total": total, "parts": parts}


# "#check: father:wis 12 2" -> {voice: father, stat: wis, target: 12, mod: 2}; the stat can be left out
static func parse_spec(value):
	var bits := BUtil.split_ws(BUtil.js_trim(BUtil.js_str(value)))
	if bits[0] == "":
		return null
	var vs := bits[0].to_lower().split(":")
	var target = BUtil.js_parse_int(bits[1]) if bits.size() > 1 else null
	var mod = BUtil.js_parse_int(bits[2]) if bits.size() > 2 else 0
	return {"voice": vs[0], "stat": vs[1] if vs.size() > 1 and STATS.has(vs[1]) else "", "target": 12 if target == null else target, "mod": 0 if mod == null else mod}


static func roll(rng: BRng, target: int, mod: int, tension: int) -> Dictionary:
	var d1 := rng.d6()
	var d2 := rng.d6()
	return resolve(d1, d2, target, mod, tension)
