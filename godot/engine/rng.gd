class_name BRng
extends RefCounted
# Seeded random numbers for checks (prototype/web/src/core/rng.js, mulberry32). The state is saved
# with the game, so quitting and reloading can't re-roll a check.

var seed := 1
var state := 1
var calls := 0


func _init(s: int = 1) -> void:
	seed = s & BUtil.U32
	if seed == 0:
		seed = 1
	state = seed


func next() -> float:
	calls += 1
	state = (state + 0x6D2B79F5) & BUtil.U32
	var t := state
	t = BUtil.imul(t ^ (t >> 15), t | 1)
	t = t ^ ((t + BUtil.imul(t ^ (t >> 7), t | 61)) & BUtil.U32)
	return float((t ^ (t >> 14)) & BUtil.U32) / 4294967296.0


func int_between(lo: int, hi: int) -> int:
	return lo + int(floor(next() * (hi - lo + 1)))


func d6() -> int:
	return int_between(1, 6)


func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[int_between(0, arr.size() - 1)]


func get_state() -> Dictionary:
	return {"seed": seed, "state": state, "calls": calls}


func set_state(s) -> void:
	if s == null or not (s is Dictionary):
		return
	seed = int(s.get("seed", 0)) & BUtil.U32
	state = int(s.get("state", 0)) & BUtil.U32
	calls = int(s.get("calls", 0))


static func fresh_seed() -> int:
	return (int(Time.get_unix_time_from_system() * 1000.0) ^ randi()) & BUtil.U32
