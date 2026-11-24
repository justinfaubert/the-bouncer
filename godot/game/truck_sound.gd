# The truck's sound, made as it plays (no samples): the one sound the player hears for minutes at a
# time, so it has to be worth listening to.
#
#   the engine   eight firing pulses every two turns of the crank, in the 460's firing order
#                (1-5-4-2-6-3-7-8), so each bank's exhaust gets its pulses unevenly and the cross-plane
#                V8's lope comes out of the arithmetic, not a loop. Each pulse rings its bank's pipe (a
#                resonance that moves with the pipe's heat and the load) and the muffler's box; a
#                little of each cylinder's own difference, more at idle; the intake's breath under
#                the throttle; the valves ticking on the cam.
#   the cab      what of all that gets through the firewall and the floor: low, boomy, the cab
#                panel's own drone at about 45 Hz
#   the road     tire hiss on the wet, rising with speed; the gravel's crunch; the wind round the
#                mirrors and the drip rails
#   the rest     the horn (two notes, a slow attack), a deep thud when it hits something, the starter
#
# One AudioStreamGenerator at 22 050 Hz, filled each frame.
class_name TruckSound
extends Node

const RATE := 22050.0
# crank degrees at which each bank fires (of 720): right bank cylinders 1-4, left 5-8
const RIGHT := [0.0, 180.0, 270.0, 450.0]
const LEFT := [90.0, 360.0, 540.0, 630.0]

var player: AudioStreamPlayer
var gen: AudioStreamGeneratorPlayback
# fed from game/truck.gd each frame
var rpm := 0.0
var load := 0.0                 # 0..1, the throttle as the engine sees it
var speed := 0.0                # m/s
var surface := 0                # TruckSim.Surf under the rear tires
var wet := true
var running := true
var cranking := 0.0             # seconds of starter left
var horn := false
var volume := 0.8
var outside := false            # heard from out of the cab (the outside view): brighter, no cab boom

var _crank := 0.0               # crank angle, degrees 0..720
var _rng := RandomNumberGenerator.new()
var _bank := [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]     # per bank: pulse left, its amplitude, its phase
var _pipe := [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]]               # each bank's pipe resonator state
var _box := [0.0, 0.0, 0.0, 0.0]                              # the muffler
var _cab := [0.0, 0.0, 0.0, 0.0]
var _dc := [0.0, 0.0]                              # the cab's boom
var _lp := 0.0
var _lp2 := 0.0
var _hiss := [0.0, 0.0]
var _wind := 0.0
var _intake := 0.0
var _tick_ph := 0.0
var _horn_ph := [0.0, 0.0]
var _horn_env := 0.0
var _knock := 0.0
var _knock_ph := 0.0
var _knock_body := 0.0          # the thud's phase
var _knock_lp := [0.0, 0.0]
var _cyl_jit: Array = []
var _rpm_s := 0.0


func _ready() -> void:
	_rng.seed = 460
	for i in 8:
		_cyl_jit.append(_rng.randf_range(0.88, 1.12))
	player = AudioStreamPlayer.new()
	var st := AudioStreamGenerator.new()
	st.mix_rate = RATE
	st.buffer_length = 0.12
	player.stream = st
	player.bus = "Master"
	add_child(player)


func start() -> void:
	player.play()
	gen = player.get_stream_playback()


func stop() -> void:
	player.stop()
	gen = null


# a hit: a deep thud through the frame, the body's low ring under it (0..1)
func knock(strength: float) -> void:
	var st := clampf(strength, 0.0, 1.0)
	if _knock > 0.001 and st < _knock * 0.6:
		return
	_knock = maxf(st, _knock * 0.5)
	_knock_ph = 0.0
	_knock_body = 0.0


# a band-pass (RBJ, 0 dB at its peak, nothing at DC): returns the new output; state [x1, x2, y1, y2]
static func _res(x: float, st: Array, f: float, q: float) -> float:
	var w := TAU * f / RATE
	var alpha := sin(w) / (2.0 * q)
	var a0 := 1.0 + alpha
	var y: float = (alpha * x - alpha * float(st[1]) + 2.0 * cos(w) * float(st[2]) - (1.0 - alpha) * float(st[3])) / a0
	st[1] = st[0]
	st[0] = x
	st[3] = st[2]
	st[2] = y
	return y


func _process(_dt: float) -> void:
	if gen == null:
		return
	var n := gen.get_frames_available()
	if n <= 0:
		return
	gen.push_buffer(fill(n))


# n samples of it as it is now (tests/truck_sound.gd renders it to a file this way)
func fill(n: int) -> PackedVector2Array:
	var on := running or cranking > 0.0
	var spd := absf(speed)
	var gravel := surface == TruckSim.Surf.GRAVEL or surface == TruckSim.Surf.SAND
	var puddle := surface == TruckSim.Surf.PUDDLE
	var hiss_amt := clampf(spd / 30.0, 0.0, 1.0) * (0.5 if wet else 0.18) * (1.6 if puddle else 1.0)
	var crunch := clampf(spd / 10.0, 0.0, 1.0) * (0.55 if gravel else 0.0)
	var wind_amt := clampf(spd * spd / 1600.0, 0.0, 1.0) * 0.35
	var vol := volume
	var buf := PackedVector2Array()
	buf.resize(n)
	for k in n:
		# the crank goes round at the rpm (eased so a shift's a slur, not a step)
		var target := rpm if running else (180.0 + 40.0 * sin(_crank * 0.02) if cranking > 0.0 else 0.0)
		_rpm_s += (target - _rpm_s) * 0.0025
		var deg := _rpm_s * 6.0 / RATE           # degrees of crank a sample
		var before := _crank
		_crank = fmod(_crank + deg, 720.0)
		var ex := [0.0, 0.0]
		if on and deg > 0.0:
			# a cylinder fires as the crank passes its angle
			for b in 2:
				var angs: Array = RIGHT if b == 0 else LEFT
				for ci in angs.size():
					var a: float = angs[ci]
					var passed := (before < a and _crank >= a) or (before > _crank and (a > before or a <= _crank))
					if passed and running:
						var cyl := ci + b * 4
						var idle_j := clampf(1.0 - _rpm_s / 2500.0, 0.0, 1.0)
						var amp: float = (0.35 + 0.65 * load) * lerpf(1.0, float(_cyl_jit[cyl]) * _rng.randf_range(0.85, 1.15), idle_j)
						_bank[b][0] = 1.0
						_bank[b][1] = amp
					elif passed and cranking > 0.0:
						_bank[b][0] = 0.4
						_bank[b][1] = 0.15
				# the pulse: a short burst, a couple of milliseconds
				if float(_bank[b][0]) > 0.0:
					var pulse: float = _bank[b][1] * (float(_bank[b][0]) * 2.0 - 1.0 if float(_bank[b][0]) > 0.5 else float(_bank[b][0]) * 2.0)
					ex[b] = pulse + _rng.randf_range(-0.15, 0.15) * float(_bank[b][1]) * float(_bank[b][0])
					_bank[b][0] = maxf(0.0, float(_bank[b][0]) - 1.0 / (RATE * 0.0028))
		# each bank's pipe and the muffler: the resonances move a little with load
		var pf := 92.0 + 18.0 * load + _rpm_s * 0.004
		var l := _res(ex[0], _pipe[0], pf, 3.2)
		var r := _res(ex[1], _pipe[1], pf * 1.06, 3.2)
		var mono := (l + r) * 0.5
		var muff := _res(mono, _box, 310.0, 1.6)
		var eng: float = mono * 1.4 + muff * 0.8 + (float(ex[0]) + float(ex[1])) * 0.08
		# the intake: breath under the throttle, filtered noise
		_intake += (_rng.randf_range(-1.0, 1.0) - _intake) * (0.05 + 0.25 * load)
		eng += _intake * load * clampf(_rpm_s / 3500.0, 0.0, 1.0) * 0.18
		# the valves on the cam: a tick at the cam's speed times eight, faint
		_tick_ph = fmod(_tick_ph + _rpm_s / 60.0 / 2.0 * 8.0 / RATE, 1.0)
		if on and _tick_ph < 0.004:
			eng += 0.05 * _rng.randf_range(0.5, 1.0)
		# through the cab: low pass and the panel's boom
		var cut := 0.08 if not outside else 0.25
		_lp += (eng - _lp) * cut
		_lp2 += (_lp - _lp2) * cut
		var cab := _lp2 * 1.6
		if not outside:
			cab += _res(_lp2, _cab, 45.0 + _rpm_s * 0.002, 4.0) * 1.2
		else:
			cab = eng * 0.6 + _lp2
		# the road: hiss, crunch, wind
		var w := _rng.randf_range(-1.0, 1.0)
		_hiss[0] += (w - _hiss[0]) * 0.55
		_hiss[1] += (_hiss[0] - _hiss[1]) * 0.3
		var road: float = (float(_hiss[0]) - float(_hiss[1])) * hiss_amt
		if crunch > 0.0 and _rng.randf() < 0.004 * crunch * 10.0:
			_knock_ph = 0.0
			road += _rng.randf_range(0.2, 0.5) * crunch
		_wind += (_rng.randf_range(-1.0, 1.0) - _wind) * 0.02
		road += _wind * wind_amt * 2.0
		# the horn: two notes, a slow attack
		_horn_env += ((1.0 if horn else 0.0) - _horn_env) * (0.004 if horn else 0.01)
		var hv := 0.0
		if _horn_env > 0.002:
			_horn_ph[0] = fmod(_horn_ph[0] + 392.0 / RATE, 1.0)
			_horn_ph[1] = fmod(_horn_ph[1] + 494.0 / RATE, 1.0)
			hv = ((1.0 if _horn_ph[0] < 0.5 else -1.0) + (1.0 if _horn_ph[1] < 0.42 else -1.0)) * 0.12 * _horn_env
		# a knock: a deep thud that falls in pitch (70 Hz down to 36), a little dull noise for the
		# crumple, the cab's low ring under it; quiet enough to stay clear of the soft knee
		var kv := 0.0
		if _knock > 0.001:
			_knock_ph += 1.0 / RATE
			var kt := _knock_ph
			_knock_body = fmod(_knock_body + (36.0 + 34.0 * exp(-kt * 16.0)) / RATE, 1.0)
			var env := (1.0 - exp(-kt * 300.0)) * exp(-kt * 6.5)
			_knock_lp[0] += (_rng.randf_range(-1.0, 1.0) - float(_knock_lp[0])) * 0.05
			_knock_lp[1] += (float(_knock_lp[0]) - float(_knock_lp[1])) * 0.05
			var ring := sin(TAU * 96.0 * kt) * exp(-kt * 11.0) * 0.18
			kv = _knock * 0.16 * (env * (sin(TAU * _knock_body) + float(_knock_lp[1]) * 1.6) + ring)
			if kt > 0.9:
				_knock = 0.0
		var s: float = (cab * 0.55 + road * 0.5 + hv + kv) * vol
		# a DC blocker, then a soft knee rather than a hard clip
		var hp: float = s - float(_dc[0]) + 0.995 * float(_dc[1])
		_dc[0] = s
		_dc[1] = hp
		var sl := tanh((hp + l * 0.05 * vol) * 5.5) * 0.8
		var sr := tanh((hp + r * 0.05 * vol) * 5.5) * 0.8
		buf[k] = Vector2(sl, sr)
	if cranking > 0.0:
		cranking = maxf(0.0, cranking - float(n) / RATE)
	return buf
