# The wine glasses' voice (game/wine_glasses.gd is the glasses on the bar and his hands on them).
#
# Made here, sample by sample, with no recordings. Each glass is its bowl's modes: the lowest, the
# one a wet finger sings (the rim going oval, four still points round it), and three above it at
# the ratios a wine glass has, nowhere near harmonic, which is why a tapped glass sounds like a
# glass and not a flute. No bowl is quite round, so the lowest mode is two, a fraction of a hertz
# apart, and they beat: the slow wah in a sung glass. Water in it lowers every mode, the low ones
# most (A. P. French's formula, for a bowl of glass two and a half times as dense as water), and
# damps them.
#
# Each mode is a phasor turned by its frequency every sample, losing a little: exact in pitch at
# any frequency, and cheap. A tap kicks them all, harder up top for a stir stick, softer for a
# fingertip. A rub is a friction bow on the lowest pair: the finger's speed round the rim against
# the rim's own speed under it, through a friction curve that grips when they're near and lets go
# as they part, so the glass pulls the finger along and lets it slip, hundreds of times a second,
# and sings. Too slow and it chatters, too fast and the finger skates and it barely speaks, too
# hard and it grinds, a dry finger squeaks. Nobody sets any of that: it falls out of the curve.
class_name GlassSynth
extends Node

const RATE := 32000.0
const CTRL := 16
const NG := 8
const RATIOS := [1.0, 1.0, 2.38, 4.31, 6.82]      # the lowest twice: the pair that beats
const GAINS := [0.5, 0.5, 0.32, 0.16, 0.08]
const LOWER := [1.0, 1.0, 0.82, 0.66, 0.55]       # how much water pulls each mode down, of the lowest's
const BUS := &"Glasses"

class Glass:
	var f0 := 800.0               # empty
	var split := 0.0006           # the pair, apart by this fraction
	var fill := 0.0               # 0..1 of the bowl's height
	var c := PackedFloat32Array() # each mode's turn: cos and sin times what's left after a sample
	var s := PackedFloat32Array()
	var x := PackedFloat32Array() # each mode's phasor
	var y := PackedFloat32Array()
	var g := PackedFloat32Array() # what each mode gives the air
	var energy := 0.0
	# the finger on the rim
	var vb := 0.0                 # how fast it goes round, m/s
	var press := 0.0              # 0 off the rim, ~1 a light touch, 2 leaning on it
	var wet := 1.0
	var pan := 0.0
	var squeal := 0.0             # what the grinding's at, for the hands to feel
	var amp := 0.0                # how loud it's singing (for the eyes)
	var catch_n := 0              # a dry finger catching on the rim: samples left of the judder

	func _init() -> void:
		for a in [c, s, x, y, g]:
			a.resize(RATIOS.size())

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var glasses: Array = []
var running := false
var rng := RandomNumberGenerator.new()
var _seed := 1759
var volume := 0.8
var pour := 0.0                    # water coming out of the jug, 0..1
var pour_into := -1                # which glass it's going into (-1 the drip tray)
var _pour_lp := 0.0
var _pour_bp := [0.0, 0.0]
var _bow_n := 0.0


func setup(parent_for_player: Node = null) -> void:
	rng.seed = 1761                # the year Franklin made the armonica
	for i in NG:
		var gl := Glass.new()
		glasses.append(gl)
	_bus()
	player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.1
	player.stream = gen
	player.bus = BUS if AudioServer.get_bus_index(BUS) >= 0 else &"Master"
	(parent_for_player if parent_for_player != null else self).add_child(player)
	set_process(false)


func _bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, &"Space" if AudioServer.get_bus_index(&"Space") >= 0 else &"Master")


func start() -> void:
	if running:
		return
	running = true
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(true)


func stop() -> void:
	running = false
	player.stop()
	playback = null
	set_process(false)


# a glass, empty pitch and where it stands (-1 left .. 1 right)
func set_glass(i: int, f0: float, split: float, pan: float) -> void:
	var gl: Glass = glasses[i]
	gl.f0 = f0
	gl.split = split
	gl.pan = pan
	tune(i)


# the frequency of mode m of glass i with the water it has in it (French: f = f0 / sqrt(1 + a (h/H)^4))
func freq(i: int, m := 0) -> float:
	var gl: Glass = glasses[i]
	var f: float = gl.f0 * RATIOS[m] / sqrt(1.0 + 3.3 * float(LOWER[m]) * pow(gl.fill, 4.0))
	if m == 1:
		f *= 1.0 + gl.split
	return f


func tune(i: int) -> void:
	var gl: Glass = glasses[i]
	# water damps it: an empty glass rings five seconds, a full one under two; the tops go sooner
	var t60 := lerpf(5.5, 1.6, gl.fill)
	for m in RATIOS.size():
		var f := freq(i, m)
		var t := t60 / (1.0 + 0.6 * m)
		var r := pow(10.0, -3.0 / (t * RATE))
		var th := TAU * f / RATE
		gl.c[m] = cos(th) * r
		gl.s[m] = sin(th) * r
		gl.g[m] = GAINS[m] if f < RATE * 0.45 else 0.0


func set_fill(i: int, fill: float) -> void:
	var gl: Glass = glasses[i]
	gl.fill = clampf(fill, 0.0, 1.0)
	tune(i)


# a tap: how hard, how bright (0 a fingertip, 1 a stir stick, the rim)
func tap(i: int, hard: float, bright := 1.0) -> void:
	var gl: Glass = glasses[i]
	for m in RATIOS.size():
		var k := hard * float(GAINS[m]) * lerpf(0.25, 1.0, pow(bright, 0.5 + m * 0.4)) * (1.0 if m > 0 else 1.0)
		# the stick lands somewhere on the rim: the two halves of the pair don't get the same share
		var share := 1.0
		if m <= 1:
			share = 0.5 + rng.randf_range(-0.3, 0.3) * (1.0 if m == 0 else -1.0)
		gl.x[m] += k * share * 4.0
	gl.energy = 1.0


func set_finger(i: int, vb: float, press: float, wet: float) -> void:
	var gl: Glass = glasses[i]
	gl.vb = vb
	gl.press = press
	gl.wet = wet
	if press > 0.0:
		gl.energy = 1.0


func _process(_dt: float) -> void:
	if playback == null:
		return
	var n := playback.get_frames_available()
	n -= n % CTRL
	if n <= 0:
		return
	playback.push_buffer(render(n))


func _noise() -> float:
	_seed = (_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_seed) / 1073741824.0 - 1.0


func render(n: int) -> PackedVector2Array:
	var L := PackedFloat32Array()
	var R := PackedFloat32Array()
	L.resize(n)
	R.resize(n)
	for gl in glasses:
		_glass(gl, L, R, n)
	_water(L, R, n)
	var out := PackedVector2Array()
	out.resize(n)
	for i in n:
		var l := clampf(L[i] * volume, -3.0, 3.0)
		var r := clampf(R[i] * volume, -3.0, 3.0)
		out[i] = Vector2(l * (27.0 + l * l) / (27.0 + 9.0 * l * l), r * (27.0 + r * r) / (27.0 + 9.0 * r * r))
	return out


# the friction between a wet fingertip and the rim, by how fast they slide past each other (m/s):
# gripping, it pulls up to what it can; past that it lets go, and falls toward what it is sliding
const STICK := 0.02
func _friction(dv: float, wet: float) -> float:
	var mu_s := lerpf(1.3, 1.0, wet)
	var mu_d := lerpf(0.75, 0.35, wet)
	var a := absf(dv)
	var f: float
	if a < STICK:
		f = mu_s * a / STICK
	else:
		f = mu_d + (mu_s - mu_d) / (1.0 + (a - STICK) / 0.1)
	return f if dv >= 0.0 else -f


func _glass(gl: Glass, L: PackedFloat32Array, R: PackedFloat32Array, n: int) -> void:
	if gl.energy < 0.00002 and gl.press <= 0.0:
		gl.amp = 0.0
		return
	var nm := RATIOS.size()
	var c := gl.c
	var s := gl.s
	var x := gl.x
	var y := gl.y
	var gg := gl.g
	var lp := 0.5 - gl.pan * 0.35
	var rp := 0.5 + gl.pan * 0.35
	var bowing := gl.press > 0.0
	# the bow: the rim's speed under the finger is what the pair is doing, scaled to metres a second
	var vscale := 0.06
	var force := 0.02 * gl.press
	var rough := (1.0 - gl.wet) * 0.6 + 0.04
	var grind := maxf(0.0, gl.press - 1.3) * 0.5
	var peak := 0.0
	var sq := 0.0
	for i in n:
		if bowing:
			var vr := (y[0] + y[1]) * vscale
			var vb := gl.vb
			var fk := force
			# a dry fingertip catches and lets go: the squeak
			if gl.catch_n > 0:
				gl.catch_n -= 1
				vb *= 0.15
				fk *= 1.8
			elif rng.randf() < (1.0 - gl.wet) * (1.0 - gl.wet) * gl.vb * 0.0008:
				gl.catch_n = rng.randi_range(250, 600)
			var dv := vb - vr
			var f := _friction(dv, gl.wet) * fk
			# the skin catching: noise riding the grip, more when it's dry, more leaning on it
			f *= 1.0 + _noise() * (rough + grind)
			y[0] += f
			y[1] += f
			y[2] += f * 0.06
			sq += absf(dv)
		var o := 0.0
		for m in nm:
			var xm := x[m]
			var ym := y[m]
			x[m] = c[m] * xm - s[m] * ym
			y[m] = s[m] * xm + c[m] * ym
			o += x[m] * gg[m]
		o *= 0.18
		L[i] += o * lp
		R[i] += o * rp
		peak = maxf(peak, absf(o))
	gl.energy = peak * 4.0
	gl.amp = lerpf(gl.amp, peak * 4.0, 0.3)
	gl.squeal = sq / n if bowing else 0.0


# the jug pouring: water hitting water, and the air over it in the glass, a pipe closed at the
# water's end, getting shorter as it fills so the note of it climbs
func _water(L: PackedFloat32Array, R: PackedFloat32Array, n: int) -> void:
	if pour <= 0.001:
		return
	var f := 900.0
	var pan := 0.0
	if pour_into >= 0:
		var gl: Glass = glasses[pour_into]
		var air := maxf(0.008, 0.11 * (1.0 - gl.fill))
		f = clampf(343.0 / (4.0 * (air + 0.012)), 500.0, 9000.0)
		pan = gl.pan
	var g := 2.0 * sin(PI * f / RATE)
	var q := 0.08
	for i in n:
		var w := _noise() * pour * (0.6 + 0.4 * _noise())
		# a state-variable band-pass round the air column's note
		var hp: float = w - _pour_bp[0] - q * _pour_bp[1]
		_pour_bp[1] += g * hp
		_pour_bp[0] += g * _pour_bp[1]
		_pour_lp += (w - _pour_lp) * 0.08
		var o: float = _pour_bp[1] * 0.06 + _pour_lp * 0.18
		L[i] += o * (0.5 - pan * 0.35)
		R[i] += o * (0.5 + pan * 0.35)
