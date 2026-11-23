# The cigarette machine's voice (game/cig_machine.gd is the machine and the player's hands on it).
# Unplugged since the smoking ban and it plays anyway. Nobody explains it.
#
# All of it made here, sample by sample, with no recordings: a small polyphonic synth of the kind
# that was in every rehearsal space in 1983, built the way those were.
#
#   voices    six. Each one two sawtooths a few cents apart, a pulse off the first one's phase, a
#             square an octave down, a triangle, and noise; or two sine operators, one bending the
#             other's phase (the bells). The sawtooths and the pulse are band-limited (PolyBLEP) so
#             the top of the keyboard doesn't fold back into whistles.
#   filter    a state-variable low-pass (Zavalishin's topology-preserving form, so it stays true
#             when it's swept fast and when it rings), twelve or twenty-four dB an octave, its
#             resonance up to the edge of singing. A little drive into it, so a hard pull growls.
#   envelopes two, attack-decay-sustain-release, one for the loudness and one for the filter.
#   expression how far a knob is out: further opens the filter and leans on the loudness.
#   wear      the machine's age, set by the price's pennies (cig_machine.gd): each voice drifts off
#             pitch on its own and comes back, the whole thing wows and flutters like a tape, the
#             knobs crackle when they move, and there's hiss.
#   the hold  a quarter in the slot holds whatever's pulled when the knob goes back in; the motor
#             test switch walks through what's held, one note at a time (an arpeggio), up across as
#             many octaves as there are quarters in, at the speed of the last two knocks on the side.
#   the box   the cabinet itself rings: knocks on the steel are struck modes of a steel box (where
#             it's hit changes which ring), the delivery tray's flap is a thinner plate, a quarter
#             falling through the coin mech is a struck coin bouncing down the chute, the knobs
#             click at their detent and clunk at the stop. And the box hums along a little with
#             what it plays, the way a cabinet does.
#
# The chorus, the echo and the room are Godot's own effects, on a bus of the machine's own that
# goes out through the room's echo (game/sound.gd).
class_name CigSynth
extends Node

const RATE := 32000.0
const CTRL := 16                        # samples to a control step: envelopes, the filter's sums, the arpeggio
const NV := 6
const TAB := 4096
const MASK := 4095
const BUS := &"Machine"

# The voices, by the price's dollars (cig_machine.gd: the left thumbwheel inside the door). Claude's,
# each after a sound people remember without remembering where from.
#   saw saw2 sq sub tri noise: how much of each oscillator; pw the pulse's width, pwm how much the
#   slow wobble moves it; det the second saw's detune in cents; fm, ratio: the bells; sync: the
#   second saw hard-synced to the first at its ratio, swept by the filter envelope (the 1983 lead).
#   cut res poles: the filter; env: the filter envelope, in octaves; track: how much it follows the
#   key; expr: octaves a full pull opens it. a d s r: loudness; fa fd fs fr: the filter's.
#   mono: one voice, last note wins, gliding between (glide seconds). oct: octaves up or down.
#   vib: cents of the slow wobble on the pitch; lfo its rate. drive: into the filter. lvl: loudness.
const PATCHES := [
	# $0: the hum. The machine as it's been for twenty years: one note, mostly fundamental, wavering.
	{"name": "hum", "tri": 0.8, "saw": 0.15, "cut": 900.0, "res": 0.1, "env": 0.5, "a": 0.08, "d": 0.6, "s": 0.8, "r": 0.9,
		"fa": 0.05, "fd": 0.8, "fs": 0.4, "fr": 0.8, "vib": 18.0, "lfo": 4.6, "wear": 0.6, "lvl": 1.2},
	# $1: the pad. Two saws apart and a square under them, slow in, a twenty-four dB filter: through the chorus, 1984.
	{"name": "pad", "saw": 0.7, "saw2": 0.7, "sub": 0.45, "det": 9.0, "cut": 700.0, "res": 0.22, "poles": 4, "env": 1.6,
		"track": 0.5, "a": 0.35, "d": 1.2, "s": 0.75, "r": 1.6, "fa": 0.6, "fd": 1.8, "fs": 0.5, "fr": 1.6, "vib": 3.0, "lfo": 0.7, "lvl": 0.9},
	# $2: brass. The filter snaps open and settles: horn stabs off a polysynth.
	{"name": "brass", "saw": 0.85, "saw2": 0.6, "det": 6.0, "cut": 420.0, "res": 0.18, "poles": 4, "env": 3.2, "track": 0.6,
		"a": 0.05, "d": 0.5, "s": 0.85, "r": 0.35, "fa": 0.07, "fd": 0.45, "fs": 0.45, "fr": 0.4, "drive": 1.4, "lvl": 0.95},
	# $3: the organ. Squares at the note and an octave under, no envelope on the filter: a combo organ in a church hall.
	{"name": "organ", "sq": 0.8, "sub": 0.6, "tri": 0.3, "pw": 0.5, "cut": 3200.0, "res": 0.05, "env": 0.0, "track": 0.4,
		"a": 0.006, "d": 0.1, "s": 1.0, "r": 0.06, "vib": 7.0, "lfo": 6.2, "lvl": 0.7},
	# $4: the chip. A thin pulse, no filter to speak of, instant: the arcade in the back of the Esso.
	{"name": "chip", "sq": 0.9, "pw": 0.125, "cut": 9000.0, "res": 0.0, "env": 0.0, "a": 0.002, "d": 0.18, "s": 0.7, "r": 0.03,
		"vib": 0.0, "lvl": 1.7, "wear": -0.3},
	# $5: strings. Saws, the pulse wobbling under them, slow in and slow out.
	{"name": "strings", "saw": 0.6, "saw2": 0.6, "sq": 0.35, "pw": 0.35, "pwm": 0.12, "det": 14.0, "cut": 2600.0, "res": 0.08,
		"env": 0.4, "track": 0.3, "a": 0.7, "d": 1.5, "s": 0.9, "r": 1.4, "fa": 1.0, "fd": 1.0, "fs": 0.8, "fr": 1.2, "lfo": 0.45, "lvl": 0.85},
	# $6: the bass. One voice, gliding, the filter plucked and ringing: down the bottom of a dance floor.
	{"name": "bass", "saw": 0.8, "sub": 0.6, "cut": 180.0, "res": 0.62, "poles": 4, "env": 3.6, "track": 0.3, "a": 0.003,
		"d": 0.4, "s": 0.6, "r": 0.12, "fa": 0.002, "fd": 0.22, "fs": 0.1, "fr": 0.12, "mono": true, "glide": 0.06,
		"oct": -1, "drive": 2.2, "lvl": 1.0},
	# $7: the bell. Two operators, the modulator at three and a half: glassy, dying away.
	{"name": "bell", "fm": 3.2, "ratio": 3.5, "cut": 7000.0, "res": 0.0, "env": 0.0, "a": 0.002, "d": 2.6, "s": 0.0, "r": 1.8,
		"fa": 0.002, "fd": 1.2, "fs": 0.0, "fr": 1.0, "oct": 1, "lvl": 0.85},
	# $8: the lead. The second saw synced to the first and swept up by the envelope; it tears.
	{"name": "lead", "saw": 0.3, "sync": 2.6, "saw2": 0.8, "cut": 2400.0, "res": 0.3, "env": 1.2, "track": 0.5, "a": 0.004,
		"d": 0.6, "s": 0.7, "r": 0.25, "fa": 0.004, "fd": 0.5, "fs": 0.3, "fr": 0.3, "vib": 12.0, "lfo": 5.4, "mono": true,
		"glide": 0.035, "drive": 1.6, "lvl": 1.5},
	# $9: last call. A triangle an octave up, plucked short: a music box left on a bar after closing.
	{"name": "music box", "tri": 1.0, "sq": 0.12, "pw": 0.5, "cut": 5000.0, "res": 0.0, "env": 0.0, "a": 0.001, "d": 0.7,
		"s": 0.0, "r": 0.5, "oct": 1, "lvl": 1.0},
]
const DEFAULTS := {"saw": 0.0, "saw2": 0.0, "sq": 0.0, "sub": 0.0, "tri": 0.0, "noise": 0.0, "pw": 0.5, "pwm": 0.0, "det": 0.0,
	"fm": 0.0, "ratio": 1.0, "sync": 0.0, "cut": 2000.0, "res": 0.0, "poles": 2, "env": 0.0, "track": 0.0, "expr": 2.2,
	"a": 0.01, "d": 0.3, "s": 0.8, "r": 0.3, "fa": 0.01, "fd": 0.3, "fs": 0.5, "fr": 0.3, "mono": false, "glide": 0.0, "oct": 0,
	"vib": 0.0, "lfo": 5.0, "drive": 1.0, "lvl": 1.0, "wear": 0.0}


class Voice:
	var note := -1
	var gate := false
	var busy := false
	var order := 0
	var pitch := 60.0
	var target := 60.0
	var expr := 0.0                     # the knob's pull, as the hand has it
	var ex := 0.0                       # and as the filter's had it (eased)
	var pa := 0.0
	var pb := 0.0
	var ps := 0.0
	var pm := 0.0
	var amp := 0.0
	var amp_st := 0                     # 0 quiet, 1 attack, 2 decay and sustain, 3 release
	var fe := 0.0
	var fe_st := 0
	var s1 := 0.0
	var s2 := 0.0
	var s3 := 0.0
	var s4 := 0.0
	var drift := 0.0                    # off pitch on its own, semitones
	var drift_to := 0.0
	var gl := 0.7
	var gr := 0.7


# A thing that rings when it's struck: modes, each a two-pole resonator. Where it's struck is in the
# gains the strike brings; how hard the thing hitting it is, in how bright the strike is.
class Body:
	var f: PackedFloat32Array
	var b1: PackedFloat32Array
	var b2: PackedFloat32Array
	var y1: PackedFloat32Array
	var y2: PackedFloat32Array
	var g: PackedFloat32Array           # this strike's gains, mode by mode
	var norm: PackedFloat32Array        # each mode's input scaled so a struck one rings about as loud as it's hit
	var fnorm: PackedFloat32Array       # and so a steady feed doesn't pile up in the long ones
	var exc_left := 0                   # samples of the strike still going in
	var exc_amp := 0.0
	var exc_lp := 0.0                   # its brightness: a one-pole low-pass on the noise
	var exc_st := 0.0
	var energy := 0.0                   # still ringing
	var pan := 0.5
	var level := 1.0

	func _init(freqs: Array, decays: Array, lvl := 1.0) -> void:
		var n := freqs.size()
		f = PackedFloat32Array(freqs)
		b1.resize(n)
		b2.resize(n)
		y1.resize(n)
		y2.resize(n)
		g.resize(n)
		norm.resize(n)
		fnorm.resize(n)
		level = lvl
		for m in n:
			var r := exp(-1.0 / (float(decays[m]) * RATE))
			b1[m] = 2.0 * r * cos(TAU * float(freqs[m]) / RATE)
			b2[m] = r * r
			g[m] = 1.0
			norm[m] = sin(TAU * float(freqs[m]) / RATE)
			fnorm[m] = norm[m] * sqrt(1.0 - r * r)


var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var voices: Array = []
var _order := 0
var _tab := PackedFloat32Array()
var _seed := 22695477
var rng := RandomNumberGenerator.new()

# the patch as numbers, for the inner loop
var patch := 1
var P := {}
var wear := 0.3                         # 0 like new, 1 twenty years in a hallway (the price's pennies)
var lamp := 0                           # 0 off, 1 on, 2 flickering: the chorus, and the ballast's hum
var echo := 0.0                         # the relay delay knob, 0 to 1
var bend := 0.0                         # semitones, from the coin return
var rock := 0.0                         # the cabinet rocking on its feet: shaken pitch, the tube flickering
var rock_v := 0.0
var octave := 0
var volume := 0.8
var _lfo := 0.0
var _wow := 0.0
var _flut := 0.0
var _hum := 0.0
var crackle := 0.0                      # a knob moving: the old contacts scratch (cig_machine.gd sets it)

# the hold and the arpeggio
var held := {}                          # note: pull (0..1), the knobs out now
var latched: Array = []                 # what a quarter's holding
var credit := 0                         # quarters in
var arp_on := false                     # the motor test switch
var bpm := 104.0
var _arp_t := 0.0
var _arp_i := 0
var _arp_note := -1
var _knocks: Array = []                 # when the last knocks were, for the speed

# the box and what's in it
var cabinet: Body
var tray: Body
var coin: Body
var knob: Body
var _events: Array = []                 # [at sample, callable]
var _now := 0                           # samples since it started
var _feed := 0.0                        # what it's playing, fed back into the cabinet a little
var running := false


func setup(parent_for_player: Node = null) -> void:
	rng.seed = 1983
	_tab.resize(TAB)
	for i in TAB:
		_tab[i] = sin(TAU * float(i) / TAB)
	for i in NV:
		voices.append(Voice.new())
	# the cabinet: a steel box about a metre by a metre seventy by forty-five, the low modes of its
	# big panels, its corners and its door, and the ring of the sheet; long-ish, it's a box
	cabinet = Body.new([71.0, 104.0, 133.0, 187.0, 242.0, 311.0, 467.0, 693.0, 1130.0, 1720.0],
		[0.32, 0.26, 0.22, 0.2, 0.17, 0.14, 0.11, 0.08, 0.05, 0.03], 0.22)
	# the delivery tray's flap: thin, bright, short
	tray = Body.new([412.0, 1033.0, 1690.0, 2610.0, 3380.0], [0.09, 0.07, 0.05, 0.035, 0.02], 0.1)
	# a quarter: its modes (a thin disc, nickel on copper), ringing a long time for something so small
	coin = Body.new([3150.0, 5480.0, 7360.0, 9890.0], [0.12, 0.09, 0.06, 0.04], 0.1)
	# the knob on its plunger: chrome on a steel rod, a spring behind it
	knob = Body.new([1840.0, 2950.0, 4410.0, 6020.0], [0.025, 0.02, 0.015, 0.01], 0.12)
	set_patch(1)
	_bus()
	player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.1
	player.stream = gen
	player.bus = BUS if AudioServer.get_bus_index(BUS) >= 0 else &"Master"
	(parent_for_player if parent_for_player != null else self).add_child(player)
	set_process(false)


# its own bus: a chorus (the lamp), an echo (the relay delay knob), and out through the room
func _bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, &"Space" if AudioServer.get_bus_index(&"Space") >= 0 else &"Master")
	var ch := AudioEffectChorus.new()
	ch.voice_count = 2
	ch.dry = 1.0
	ch.wet = 0.0
	AudioServer.add_bus_effect(i, ch)
	var dl := AudioEffectDelay.new()
	dl.dry = 1.0
	dl.tap1_active = false
	dl.tap2_active = false
	dl.feedback_active = true
	dl.feedback_level_db = -80.0
	dl.feedback_lowpass = 3200.0
	AudioServer.add_bus_effect(i, dl)
	# the cabinet: a steel box takes the very top off, and the speaker it hasn't got
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 9500.0
	AudioServer.add_bus_effect(i, lp)


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


func set_patch(i: int) -> void:
	patch = clampi(i, 0, PATCHES.size() - 1)
	P = DEFAULTS.duplicate()
	P.merge(PATCHES[patch], true)
	# a mono voice from a poly one: let the rest go
	if bool(P.mono):
		for k in range(1, NV):
			_release(voices[k])


func set_lamp(l: int) -> void:
	lamp = l
	var bi := AudioServer.get_bus_index(BUS)
	if bi < 0:
		return
	var ch := AudioServer.get_bus_effect(bi, 0) as AudioEffectChorus
	# chorus I and II: two delayed copies, either side, swung slowly; II is quicker and deeper
	ch.wet = [0.0, 0.55, 0.65][l]
	ch.set_voice_rate_hz(0, [0.5, 0.5, 0.83][l])
	ch.set_voice_rate_hz(1, [0.5, 0.5, 0.83][l] * 1.07)
	ch.set_voice_depth_ms(0, [2.0, 2.2, 3.4][l])
	ch.set_voice_depth_ms(1, [2.0, 2.2, 3.4][l])
	ch.set_voice_delay_ms(0, 12.0)
	ch.set_voice_delay_ms(1, 15.0)
	ch.set_voice_pan(0, -0.8)
	ch.set_voice_pan(1, 0.8)
	ch.set_voice_cutoff_hz(0, 8000.0)
	ch.set_voice_cutoff_hz(1, 8000.0)


func set_echo(e: float) -> void:
	echo = clampf(e, 0.0, 1.0)
	_echo_time()


func _echo_time() -> void:
	var bi := AudioServer.get_bus_index(BUS)
	if bi < 0:
		return
	var dl := AudioServer.get_bus_effect(bi, 1) as AudioEffectDelay
	# a dotted eighth at the knocks' speed: the echo falls between the notes
	dl.feedback_delay_ms = clampf(60000.0 / bpm * 0.75, 90.0, 1400.0)
	dl.feedback_level_db = -80.0 if echo < 0.02 else lerpf(-16.0, -2.5, echo)
	dl.feedback_lowpass = lerpf(4200.0, 1800.0, echo)


# ---------------------------------------------------------------- notes

func pull(n: int, how: float) -> void:
	var was := held.has(n)
	held[n] = clampf(how, 0.0, 1.0)
	if not was:
		# a quarter in: a knob pulled again lets go of the note it's holding, or adds it to the hold
		if credit > 0:
			if n in latched:
				latched.erase(n)
			else:
				latched.append(n)
		_regate()
	else:
		for v in voices:
			if v.note == n + octave * 12:
				v.expr = held[n]


func push_in(n: int) -> void:
	if not held.has(n):
		return
	held.erase(n)
	_regate()


func drop_hold() -> void:
	latched.clear()
	_regate()


# what should be sounding: what's pulled and what's held, or the arpeggio walking through them
func _regate() -> void:
	if arp_on and credit > 0:
		return            # the arpeggio's clock does it
	var want := {}
	for n in latched:
		want[n] = held.get(n, 0.55)
	for n in held:
		want[n] = held[n]
	for v in voices:
		if v.gate and not want.has(v.note - octave * 12):
			_release(v)
	if bool(P.mono):
		if want.is_empty():
			return
		var last: int = want.keys()[want.size() - 1]
		var v: Voice = voices[0]
		_on(v, last + octave * 12, float(want[last]), v.gate)
		return
	for n in want:
		var have := false
		for v in voices:
			if v.gate and v.note == n + octave * 12:
				have = true
				v.expr = float(want[n])
		if not have:
			_on(_free_voice(), n + octave * 12, float(want[n]))


func _free_voice() -> Voice:
	var best: Voice = null
	for v in voices:
		if not v.busy:
			return v
	# all going: the quietest of the ones let go, or else the oldest
	for v in voices:
		if not v.gate and (best == null or v.amp < best.amp):
			best = v
	if best != null:
		return best
	best = voices[0]
	for v in voices:
		if v.order < best.order:
			best = v
	return best


func _on(v: Voice, n: int, how: float, legato := false) -> void:
	v.note = n
	v.target = float(n)
	if not legato or float(P.glide) <= 0.0:
		v.pitch = float(n)
	v.expr = how
	if not legato:
		v.ex = how
	v.gate = true
	v.busy = true
	_order += 1
	v.order = _order
	if not legato:
		v.amp_st = 1
		v.fe_st = 1
		v.fe = 0.0 if v.amp < 0.01 else v.fe
		# the pulse restarts where it was, as on the hardware: no click
		if v.amp < 0.01:
			v.s1 = 0.0
			v.s2 = 0.0
			v.s3 = 0.0
			v.s4 = 0.0
			v.pa = rng.randf()
			v.pb = rng.randf()
	# each note to its own side, a little, low left to high right, like a keyboard in front of you
	var pan := clampf(0.5 + (float(n) - 60.0) / 48.0, 0.15, 0.85)
	v.gl = cos(pan * PI * 0.5)
	v.gr = sin(pan * PI * 0.5)


func _release(v: Voice) -> void:
	v.gate = false
	if v.busy:
		v.amp_st = 3
		v.fe_st = 3


func all_off() -> void:
	held.clear()
	latched.clear()
	_arp_note = -1
	for v in voices:
		_release(v)


# ---------------------------------------------------------------- the hold, the motor, the knocks

func coin_in() -> void:
	credit += 1
	# down the chute: in at the slot with a scrape, the first drop onto the rail, three bounces
	# shorter each time, a roll, and into the escrow cup with a heavier tick
	var t0 := _now
	_at(t0, func(): strike(coin, 0.5, 0.35, 0.6, 3))
	var t := t0 + int(RATE * 0.11)
	var gap := 0.055
	var a := 0.8
	for k in 4:
		var ta := t
		var aa := a
		_at(ta, func(): strike(coin, aa, 0.9, randf(), 1))
		t += int(RATE * gap)
		gap *= 0.62
		a *= 0.6
	for k in 6:
		var tk := t + int(RATE * 0.012 * k)
		_at(tk, func(): strike(coin, 0.08, 0.7, randf(), 1))
	_at(t + int(RATE * 0.09), func():
		strike(coin, 0.5, 0.6, 0.3, 1)
		strike(cabinet, 0.12, 0.8, 0.8, 2))


func coins_back() -> int:
	var n := credit
	credit = 0
	latched.clear()
	_arp_note = -1
	# the coins come down into the return cup one after another, onto the ones already there
	for k in n:
		var tk := _now + int(RATE * (0.12 + k * 0.07 + rng.randf() * 0.02))
		_at(tk, func():
			strike(coin, 0.7, 0.9, randf(), 1)
			strike(tray, 0.25, 0.9, randf(), 1))
		_at(tk + int(RATE * 0.03), func(): strike(coin, 0.25, 0.8, randf(), 1))
	_regate()
	return n


# a knock on the side: where (0..1 across, 0..1 up), how hard, and what with (0 a palm, 1 a knuckle)
func knock(x: float, y: float, hard: float, knuckle: float) -> void:
	# a plate's modes: each rings by how far the place it's hit is from its still lines
	for m in cabinet.f.size():
		var nx := 1 + (m % 3)
		var ny := 1 + int(m / 3)
		cabinet.g[m] = absf(sin(nx * PI * clampf(x, 0.05, 0.95)) * sin(ny * PI * clampf(y, 0.05, 0.95))) + 0.15
	strike(cabinet, hard, lerpf(0.2, 0.95, knuckle), -1.0, int(lerpf(5.0, 1.0, knuckle)))
	# the speed: from the last two knocks, if they're near enough a beat apart to be one
	var ts := Time.get_ticks_msec() / 1000.0
	_knocks.append(ts)
	if _knocks.size() > 4:
		_knocks.pop_front()
	if _knocks.size() >= 2:
		var gap: float = _knocks[_knocks.size() - 1] - _knocks[_knocks.size() - 2]
		if gap > 0.24 and gap < 1.6:
			bpm = clampf(60.0 / gap, 40.0, 240.0)
			_echo_time()


func flap(hard: float) -> void:
	strike(tray, hard, 0.85, rng.randf(), 2)
	_at(_now + int(RATE * 0.07), func(): strike(tray, hard * 0.35, 0.8, randf(), 1))


func knob_click(full: bool) -> void:
	strike(knob, 0.55 if not full else 0.9, 0.95, rng.randf(), 1)
	if full:
		strike(cabinet, 0.25, 0.7, 0.5, 2)


func knob_home() -> void:
	# the spring takes it back in: the plunger hits home and rattles once
	strike(knob, 0.35, 0.9, rng.randf(), 1)
	_at(_now + int(RATE * 0.045), func(): strike(knob, 0.12, 0.85, randf(), 1))


func shake(push: float) -> void:
	rock_v += push


func strike(b: Body, amp: float, bright: float, where := -1.0, ms := 2) -> void:
	if where >= 0.0:
		for m in b.f.size():
			b.g[m] = absf(sin((m + 1) * PI * clampf(where, 0.03, 0.97))) * 0.85 + 0.15
	b.exc_left = int(RATE * ms / 1000.0) + 1
	b.exc_amp = amp / maxf(1.0, float(ms))   # a longer, softer blow puts the same work in over longer
	b.exc_lp = clampf(bright, 0.02, 1.0)
	b.energy = 1.0


func _at(sample: int, f: Callable) -> void:
	_events.append([sample, f])


func set_arp(on: bool) -> void:
	arp_on = on
	_arp_note = -1
	for v in voices:
		_release(v)
	_regate()


# ---------------------------------------------------------------- the sound

func _process(_dt: float) -> void:
	if playback == null:
		return
	var n := playback.get_frames_available()
	n -= n % CTRL
	if n <= 0:
		return
	playback.push_buffer(render(n))


func render(n: int) -> PackedVector2Array:
	var L := PackedFloat32Array()
	L.resize(n)
	var R := PackedFloat32Array()
	R.resize(n)
	var ex := PackedFloat32Array()
	ex.resize(CTRL)
	var blocks := n / CTRL
	for b in blocks:
		var o := b * CTRL
		_control()
		for v in voices:
			if v.busy:
				_voice(v, L, R, o)
		# what it played this step, a little into the cabinet: the box sings along
		var fed := 0.0
		for i in CTRL:
			fed += absf(L[o + i]) + absf(R[o + i])
		_feed = fed / (2.0 * CTRL)
		_body(cabinet, L, R, o, ex, _feed * 0.025)
		_body(tray, L, R, o, ex, 0.0)
		_body(coin, L, R, o, ex, 0.0)
		_body(knob, L, R, o, ex, 0.0)
		_air(L, R, o)
		_now += CTRL
	var out := PackedVector2Array()
	out.resize(n)
	var vol := volume
	for i in n:
		var l := L[i] * vol
		var r := R[i] * vol
		# a soft ceiling: nothing clips, a chord leaned on just thickens
		l = l / (1.0 + 0.3 * absf(l))
		r = r / (1.0 + 0.3 * absf(r))
		out[i] = Vector2(l, r)
	return out


# once a control step: the slow wobble, the tape's wow, the rocking cabinet, what's due
func _control() -> void:
	var dt := CTRL / RATE
	_lfo = fmod(_lfo + dt * float(P.lfo), 1.0)
	_wow = fmod(_wow + dt * 0.55, 1.0)
	_flut = fmod(_flut + dt * 6.3, 1.0)
	# the cabinet on its feet: a heavy thing on a spring, rocked by the hand, settling
	var acc := -rock * 38.0 - rock_v * 2.6
	rock_v += acc * dt
	rock += rock_v * dt
	if absf(rock_v) > 0.4 and rng.randf() < 0.004:
		strike(cabinet, minf(0.25, absf(rock_v) * 0.1), 0.15, rng.randf(), 6)
	var k := 0
	while k < _events.size():
		if int(_events[k][0]) <= _now:
			(_events[k][1] as Callable).call()
			_events.remove_at(k)
		else:
			k += 1
	if arp_on and credit > 0:
		_arp(dt)


func _arp(dt: float) -> void:
	var notes: Array = []
	for n in latched:
		notes.append(n)
	for n in held:
		if not (n in notes):
			notes.append(n)
	notes.sort()
	if notes.is_empty():
		if _arp_note >= 0:
			for v in voices:
				_release(v)
			_arp_note = -1
		return
	var span := clampi(credit, 1, 3)
	_arp_t -= dt
	if _arp_t > 0.0:
		return
	_arp_t += 60.0 / bpm / 2.0           # eighths
	if _arp_t < 0.0:
		_arp_t = 60.0 / bpm / 2.0
	var seq: Array = []
	for o in span:
		for n in notes:
			seq.append(n + o * 12)
	_arp_i = (_arp_i + 1) % seq.size()
	var n: int = seq[_arp_i]
	for v in voices:
		if v.gate:
			_release(v)
	var how: float = held.get(n % 128, 0.55) if held.has(n) else 0.55
	if bool(P.mono):
		_on(voices[0], n + octave * 12, how, voices[0].busy and voices[0].amp > 0.05)
	else:
		_on(_free_voice(), n + octave * 12, how)
	_arp_note = n


func _voice(v: Voice, L: PackedFloat32Array, R: PackedFloat32Array, o: int) -> void:
	var dt := CTRL / RATE
	var w := clampf(wear + float(P.wear), 0.0, 1.2)
	# loudness envelope
	var a0 := v.amp
	match v.amp_st:
		1:
			v.amp += dt / maxf(float(P.a), 0.001)
			if v.amp >= 1.0:
				v.amp = 1.0
				v.amp_st = 2
		2:
			v.amp = float(P.s) + (v.amp - float(P.s)) * exp(-dt * 3.0 / maxf(float(P.d), 0.001))
		3:
			v.amp *= exp(-dt * 4.6 / maxf(float(P.r), 0.001))
			if v.amp < 0.0004:
				v.amp = 0.0
				v.amp_st = 0
				v.busy = false
	match v.fe_st:
		1:
			v.fe += dt / maxf(float(P.fa), 0.001)
			if v.fe >= 1.0:
				v.fe = 1.0
				v.fe_st = 2
		2:
			v.fe = float(P.fs) + (v.fe - float(P.fs)) * exp(-dt * 3.0 / maxf(float(P.fd), 0.001))
		3:
			v.fe *= exp(-dt * 4.6 / maxf(float(P.fr), 0.001))
	# pitch: the glide, the drift of an old oscillator, the bend, the wobble, the tape, the rocking
	if float(P.glide) > 0.0:
		v.pitch += (v.target - v.pitch) * (1.0 - exp(-dt / float(P.glide)))
	else:
		v.pitch = v.target
	if rng.randf() < dt * 0.7:
		v.drift_to = rng.randf_range(-1.0, 1.0) * 0.12 * w
	v.drift += (v.drift_to - v.drift) * dt * 0.8
	v.ex += (v.expr - v.ex) * (1.0 - exp(-dt / 0.03))
	var lfo := _tab[int(_lfo * TAB) & MASK]
	var tape := (_tab[int(_wow * TAB) & MASK] * 0.09 + _tab[int(_flut * TAB) & MASK] * 0.025) * w
	var pt := v.pitch + bend + lfo * float(P.vib) / 100.0 + v.drift + tape + rock * 0.9 + float(P.oct) * 12.0
	var freq := 440.0 * pow(2.0, (pt - 69.0) / 12.0)
	var inc := freq / RATE
	var incb := inc * pow(2.0, float(P.det) / 1200.0)
	var sync := float(P.sync)
	if sync > 0.0:
		incb = inc * (sync + v.fe * 2.2 + v.ex * 1.2)
	# the filter: its cutoff from the patch, the envelope, the key, the pull
	var fc := float(P.cut) * pow(2.0, float(P.env) * v.fe + float(P.track) * (v.pitch - 60.0) / 12.0 + (v.ex - 0.35) * float(P.expr))
	fc = clampf(fc, 30.0, RATE * 0.42)
	var g := tan(PI * fc / RATE)
	var kq := 2.0 - 1.94 * float(P.res)
	var a1 := 1.0 / (1.0 + g * (g + kq))
	var a2 := g * a1
	var a3 := g * a2
	var four := int(P.poles) == 4
	var c1 := 1.0 / (1.0 + g * (g + 1.4))
	var c2 := g * c1
	var c3 := g * c2
	var a1v := v.amp * (0.62 + 0.38 * v.ex) * float(P.lvl) * 0.3
	var a0v := a0 * (0.62 + 0.38 * v.ex) * float(P.lvl) * 0.3
	# the oscillators' mix
	var m_saw := float(P.saw)
	var m_saw2 := float(P.saw2)
	var m_sq := float(P.sq)
	var m_sub := float(P.sub)
	var m_tri := float(P.tri)
	var m_noise := float(P.noise) + w * 0.004
	var pw := clampf(float(P.pw) + lfo * float(P.pwm), 0.05, 0.95)
	var fm := float(P.fm) * (0.25 + 0.75 * v.fe)
	var ratio := float(P.ratio)
	var drive := float(P.drive)
	var pa := v.pa
	var pb := v.pb
	var ps := v.ps
	var pm := v.pm
	var s1 := v.s1
	var s2 := v.s2
	var s3 := v.s3
	var s4 := v.s4
	var sd := _seed
	var gl := v.gl
	var gr := v.gr
	var tab := _tab
	for i in CTRL:
		var amp := a0v + (a1v - a0v) * (float(i) / CTRL)
		pa += inc
		var wrapped := false
		if pa >= 1.0:
			pa -= 1.0
			wrapped = true
		var x := 0.0
		if fm > 0.0:
			pm += inc * ratio
			if pm >= 1.0:
				pm -= 1.0
			var ph := pa + fm * tab[int(pm * TAB) & MASK] * 0.16
			x += tab[int(ph * TAB) & MASK] * 1.4
		if m_saw > 0.0 or m_sq > 0.0:
			var sa := 2.0 * pa - 1.0
			if pa < inc:
				var tt := pa / inc
				sa -= tt + tt - tt * tt - 1.0
			elif pa > 1.0 - inc:
				var tt := (pa - 1.0) / inc
				sa -= tt * tt + tt + tt + 1.0
			x += sa * m_saw
			if m_sq > 0.0:
				var q := pa + pw
				if q >= 1.0:
					q -= 1.0
				var sq := 2.0 * q - 1.0
				if q < inc:
					var tt := q / inc
					sq -= tt + tt - tt * tt - 1.0
				elif q > 1.0 - inc:
					var tt := (q - 1.0) / inc
					sq -= tt * tt + tt + tt + 1.0
				x += (sa - sq) * 0.5 * m_sq
		if m_saw2 > 0.0:
			pb += incb
			if sync > 0.0 and wrapped:
				pb = pa * incb / inc
			elif pb >= 1.0:
				pb -= 1.0
			var sb := 2.0 * pb - 1.0
			if pb < incb:
				var tt := pb / incb
				sb -= tt + tt - tt * tt - 1.0
			elif pb > 1.0 - incb:
				var tt := (pb - 1.0) / incb
				sb -= tt * tt + tt + tt + 1.0
			x += sb * m_saw2
		if m_sub > 0.0:
			ps += inc * 0.5
			if ps >= 1.0:
				ps -= 1.0
			x += (1.0 if ps < 0.5 else -1.0) * m_sub * 0.8
		if m_tri > 0.0:
			x += (4.0 * absf(pa - 0.5) - 1.0) * m_tri
		sd = (sd * 1103515245 + 12345) & 0x7fffffff
		x += (float(sd) / 1073741824.0 - 1.0) * m_noise
		# into the filter, driven a little
		x *= drive
		x = x / (1.0 + absf(x) * 0.35)
		var v3 := x - s2
		var v1 := a1 * s1 + a2 * v3
		var v2 := s2 + a2 * s1 + a3 * v3
		s1 = 2.0 * v1 - s1
		s2 = 2.0 * v2 - s2
		var y := v2
		if four:
			var u3 := y - s4
			var u1 := c1 * s3 + c2 * u3
			var u2 := s4 + c2 * s3 + c3 * u3
			s3 = 2.0 * u1 - s3
			s4 = 2.0 * u2 - s4
			y = u2
		y *= amp
		L[o + i] += y * gl
		R[o + i] += y * gr
	v.pa = pa
	v.pb = pb
	v.ps = ps
	v.pm = pm
	v.s1 = s1
	v.s2 = s2
	v.s3 = s3
	v.s4 = s4
	_seed = sd


func _body(b: Body, L: PackedFloat32Array, R: PackedFloat32Array, o: int, ex: PackedFloat32Array, feed: float) -> void:
	if b.energy < 0.00002 and b.exc_left <= 0 and feed < 0.0005:
		return
	# the strike for this step: noise through its brightness, or what the box is fed
	var sd := _seed
	var lp := b.exc_st
	var fe := PackedFloat32Array()
	fe.resize(CTRL)
	for i in CTRL:
		var e := 0.0
		if b.exc_left > 0:
			sd = (sd * 1103515245 + 12345) & 0x7fffffff
			var nz := float(sd) / 1073741824.0 - 1.0
			lp += (nz - lp) * b.exc_lp
			e = lp * b.exc_amp
			b.exc_left -= 1
		if feed > 0.0:
			sd = (sd * 1103515245 + 12345) & 0x7fffffff
			fe[i] = (float(sd) / 1073741824.0 - 1.0) * feed
		ex[i] = e
	b.exc_st = lp
	_seed = sd
	var peak := 0.0
	var lvl := b.level
	for m in b.f.size():
		var c1 := b.b1[m]
		var c2 := b.b2[m]
		var y1 := b.y1[m]
		var y2 := b.y2[m]
		var gm := b.g[m] * lvl * b.norm[m] * 0.7
		var gf := b.fnorm[m] * lvl * 40.0
		for i in CTRL:
			var y := c1 * y1 - c2 * y2 + ex[i] * gm + fe[i] * gf
			y2 = y1
			y1 = y
			L[o + i] += y
			R[o + i] += y
		b.y1[m] = y1
		b.y2[m] = y2
		peak = maxf(peak, absf(y1) + absf(y2))
	b.energy = peak if b.exc_left <= 0 else 1.0


# what's in the air round it: the ballast's hum with the lamp on, hiss as it wears, the old contacts
func _air(L: PackedFloat32Array, R: PackedFloat32Array, o: int) -> void:
	var w := clampf(wear + float(P.wear), 0.0, 1.2)
	var hum_amt := 0.0
	if lamp > 0:
		hum_amt = 0.0035 if lamp == 1 else 0.0055
	var hiss := w * 0.0022
	if hum_amt <= 0.0 and hiss <= 0.0 and crackle <= 0.0:
		return
	var sd := _seed
	var h := _hum
	var inc := 60.0 / RATE
	var tab := _tab
	# the tube in its starter, flickering: the hum comes and goes with it
	var flick := 1.0
	if lamp == 2 and rng.randf() < 0.08:
		flick = rng.randf_range(0.0, 1.6)
	var pops := crackle * w
	for i in CTRL:
		h += inc
		if h >= 1.0:
			h -= 1.0
		var hm := tab[int(h * TAB) & MASK] * 0.5 + tab[int(h * 2.0 * TAB) & MASK] * 0.35 + tab[int(h * 3.0 * TAB) & MASK] * 0.25 + tab[int(h * 5.0 * TAB) & MASK] * 0.12
		sd = (sd * 1103515245 + 12345) & 0x7fffffff
		var nz := float(sd) / 1073741824.0 - 1.0
		var x := hm * hum_amt * flick + nz * hiss
		if pops > 0.0 and absf(nz) > 1.0 - pops * 0.004:
			x += nz * 0.25
		L[o + i] += x
		R[o + i] += x
	_hum = h
	_seed = sd
	crackle = maxf(0.0, crackle - 0.02)
