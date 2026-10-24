"""The placeholder sound, rendered to audio/ as .wav: small synthesized stand-ins for every cue the
Ink fires and every sound the game makes, and the layers of the room's noise, until Hutch's own
recordings replace them (a file of the same name in audio/ is all it takes; see game/sound.gd).

The recipes are the browser build's (prototype/web/src/ui/audio.js), rendered offline so the game
starts at once: filtered noise bursts and plain tones, a few takes of each so a sound played over
and over isn't the same every time.

  python3 tools/sounds.py            (numpy and scipy)
  python3 tools/sounds.py amb_keys   (only those files)
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'audio')
SR = 22050
rng = np.random.default_rng(28)


def buf(seconds):
    return np.zeros(int(SR * seconds) + 1, dtype=np.float64)


def _filter(x, kind, freq, q):
    nyq = SR / 2
    freq = min(max(freq, 30.0), nyq * 0.95)
    if kind == 'lowpass':
        b, a = signal.butter(2, freq / nyq, 'low')
    elif kind == 'highpass':
        b, a = signal.butter(2, freq / nyq, 'high')
    else:
        bw = freq / max(q, 0.3)
        lo = max(30.0, freq - bw / 2) / nyq
        hi = min(nyq * 0.95, freq + bw / 2) / nyq
        if hi <= lo:
            hi = min(0.99, lo * 1.2)
        b, a = signal.butter(2, [lo, hi], 'band')
    return signal.lfilter(b, a, x)


def burst(out, t, dur, freq, q, vol, kind='bandpass'):
    """Noise, filtered, with a quick attack and a decay over `dur`."""
    n = int(SR * (dur * 1.6 + 0.02))
    i0 = int(SR * t)
    if i0 >= len(out):
        return
    x = rng.standard_normal(n)
    x = _filter(x, kind, freq, q)
    tt = np.arange(n) / SR
    env = np.minimum(tt / 0.002, 1.0) * np.exp(-tt / max(dur * 0.45, 1e-3))
    x = x * env
    x = x / (np.max(np.abs(x)) + 1e-9) * vol
    n = min(n, len(out) - i0)
    out[i0:i0 + n] += x[:n]


def tone(out, t, freq, dur, vol, wave='sine', glide=None):
    n = int(SR * (dur * 1.3 + 0.01))
    i0 = int(SR * t)
    if i0 >= len(out):
        return
    tt = np.arange(n) / SR
    if glide:
        f = freq * (glide / freq) ** np.minimum(tt / dur, 1.0)
    else:
        f = np.full(n, float(freq))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if wave == 'square':
        x = np.sign(np.sin(ph)) * 0.6
    elif wave == 'triangle':
        x = 2 / np.pi * np.arcsin(np.sin(ph))
    elif wave == 'sawtooth':
        x = 2 * ((ph / (2 * np.pi)) % 1.0) - 1
    else:
        x = np.sin(ph)
    env = np.minimum(tt / 0.003, 1.0) * np.exp(-tt / max(dur * 0.4, 1e-3))
    n = min(n, len(out) - i0)
    out[i0:i0 + n] += (x * env * vol)[:n]


def r():
    return rng.random()


# ---------------------------------------------------------------------------------- things

SFX = {
    'click': lambda o, v: (burst(o, 0, 0.012, 3000, 2, 0.3 * v), tone(o, 0, 1800, 0.02, 0.08 * v, 'square'),
                           burst(o, 0.07, 0.01, 2600, 2, 0.18 * v)),
    'beep_ok': lambda o, v: tone(o, 0, 1450, 0.11, 0.12 * v),
    'beep_bad': lambda o, v: (tone(o, 0, 330, 0.18, 0.1 * v, 'square'), tone(o, 0.24, 330, 0.18, 0.1 * v, 'square')),
    'bell': lambda o, v: [(tone(o, s, 1320, 1.8, 0.14 * v), tone(o, s, 2650, 1.1, 0.05 * v)) for s in (0, 0.5)],
    'thump': lambda o, v: (tone(o, 0, 90, 0.25, 0.4 * v, glide=40), burst(o, 0, 0.08, 300, 0.8, 0.2 * v, 'lowpass')),
    'thud': lambda o, v: (tone(o, 0, 70, 0.35, 0.5 * v, glide=32), burst(o, 0, 0.12, 220, 0.7, 0.3 * v, 'lowpass')),
    'glass': lambda o, v: (tone(o, 0, 3300, 0.3, 0.09 * v), tone(o, 0, 4400, 0.18, 0.05 * v), burst(o, 0, 0.02, 5000, 3, 0.05 * v)),
    'scratch': lambda o, v: [burst(o, i * (0.04 + r() * 0.05), 0.03, 2800 + r() * 1500, 2, 0.08 * v) for i in range(7)],
    'ring': lambda o, v: [(tone(o, s, 880, 0.9, 0.08 * v, 'square'), tone(o, s + 0.02, 1100, 0.9, 0.05 * v, 'square')) for s in (0, 0.05, 0.1, 0.15)],
    'clack': lambda o, v: _clack(o, v),
    'till': lambda o, v: (tone(o, 0, 2100, 0.5, 0.08 * v), burst(o, 0.12, 0.1, 400, 0.8, 0.15 * v, 'lowpass')),
    'rattle': lambda o, v: _rattle(o, v),
    'tick': lambda o, v: (burst(o, 0, 0.016, 1300 + r() * 900, 2.5, 0.2 * v), tone(o, 0, 300 + r() * 90, 0.05, 0.07 * v, 'triangle', 190)),
    'tock': lambda o, v: (burst(o, 0, 0.03, 950, 1.4, 0.24 * v), tone(o, 0, 240, 0.09, 0.13 * v, 'triangle', 140)),
    'stamp': lambda o, v: (tone(o, 0, 125, 0.17, 0.36 * v, glide=52), burst(o, 0, 0.07, 520, 0.8, 0.3 * v, 'lowpass'), burst(o, 0.004, 0.035, 3000, 0.9, 0.07 * v)),
    'printer': lambda o, v: _printer(o, v),
    'pen': lambda o, v: _pen(o, v),
    'whisper': lambda o, v: _whisper(o, v),
    'tear': lambda o, v: [burst(o, i * 0.017 + r() * 0.007, 0.03, 1100 + i * 240 + r() * 300, 1.3, (0.08 + i * 0.01) * v) for i in range(11)],
    'ratchet': lambda o, v: (burst(o, 0, 0.006, 4200 + r() * 900, 6, 0.09 * v), tone(o, 0, 2600, 0.01, 0.018 * v, 'square')),
    'zero': lambda o, v: _zero(o, v),
    'card': lambda o, v: (burst(o, 0, 0.03, 2200, 1.2, 0.06 * v), burst(o, 0.05 + r() * 0.02, 0.018, 3800, 2, 0.045 * v)),
    'page': lambda o, v: ([burst(o, i * 0.03 + r() * 0.02, 0.05, 1500 + r() * 2500, 0.9, 0.03 * v) for i in range(5)], burst(o, 0.17, 0.05, 700, 0.8, 0.06 * v, 'lowpass')),
    'swipe': lambda o, v: (burst(o, 0, 0.09, 5200, 0.6, 0.018 * v), burst(o, 0.02, 0.05, 2600, 0.9, 0.012 * v)),
    'rings': lambda o, v: _rings(o, v),
    'heart': lambda o, v: _heart(o, v),
    # the game's own
    'choose': lambda o, v: (burst(o, 0, 0.02, 1800, 1.2, 0.05 * v), tone(o, 0, 520, 0.04, 0.03 * v, 'triangle', 380)),
    'click_ui': lambda o, v: (burst(o, 0, 0.01, 2400, 1.5, 0.04 * v), tone(o, 0, 900, 0.02, 0.02 * v, 'triangle')),
    'steps': lambda o, v: [(tone(o, s, 85, 0.1, 0.12 * v, glide=50), burst(o, s, 0.05, 380, 0.8, 0.07 * v, 'lowpass')) for s in (0, 0.48, 0.97, 1.43)],
    'gust': lambda o, v: _gust(o, v),
    'lift': lambda o, v: (burst(o, 0, 0.06, 1800, 0.8, 0.03 * v), burst(o, 0.05, 0.08, 900, 0.8, 0.03 * v, 'lowpass')),
}


def _clack(o, v):
    s = 0
    for i in range(6):
        burst(o, s, 0.015, 2400 + r() * 1200, 3, 0.18 * v)
        s += 0.03 + r() * 0.09


def _rattle(o, v):
    for k in range(3):
        s = k * 0.15 + r() * 0.02
        burst(o, s, 0.05, 240, 0.7, 0.06 * v, 'lowpass')
        for i in range(4):
            burst(o, s + 0.008 + r() * 0.07, 0.009, 2600 + r() * 2600, 7, (0.05 + r() * 0.08) * v)


def _printer(o, v):
    for i in range(9):
        burst(o, i * 0.017, 0.014, 3400 + r() * 1400, 4, 0.11 * v)
    tone(o, 0, 610, 0.15, 0.02 * v, 'square')
    tone(o, 0.155, 190, 0.05, 0.055 * v, 'sawtooth', 140)
    burst(o, 0.155, 0.04, 900, 1.2, 0.07 * v)


def _pen(o, v):
    n = 10
    for i in range(n):
        burst(o, i * 0.045 + r() * 0.015, 0.05 + r() * 0.03, 2600 + r() * 2200, 2.2, (0.014 + r() * 0.012) * v * 2)
    burst(o, 0, 0.045 * n, 1200, 0.8, 0.008 * v * 2, 'lowpass')


def _whisper(o, v):
    n = int(SR * 0.85)
    x = rng.standard_normal(n)
    # a band that rises through the breath
    half = n // 2
    a = _filter(x[:half], 'bandpass', 1500, 1.3)
    b = _filter(x[half:], 'bandpass', 3000, 1.3)
    y = np.concatenate([a, b])
    tt = np.arange(n) / SR
    env = np.where(tt < 0.2, tt / 0.2, np.exp(-(tt - 0.2) / 0.18))
    y = y * env
    y = y / (np.max(np.abs(y)) + 1e-9) * 0.05 * v
    o[:n] += y[:len(o)]


def _zero(o, v):
    for i in range(4):
        s = i * 0.034 + r() * 0.006
        burst(o, s, 0.01, 3700 - i * 280, 4, 0.14 * v)
        tone(o, s, 1500 - i * 130, 0.02, 0.045 * v, 'square')
    burst(o, 0.15, 0.03, 900, 1, 0.16 * v, 'lowpass')


def _rings(o, v):
    for i in range(3):
        s = i * 0.018 + r() * 0.006
        burst(o, s, 0.008, 5400 - i * 400, 7, 0.1 * v)
        tone(o, s, 3200 - i * 260, 0.05, 0.022 * v, 'triangle')
    burst(o, 0.09, 0.05, 600, 0.8, 0.09 * v, 'lowpass')


def _heart(o, v):
    tone(o, 0, 58, 0.12, 0.3 * v, glide=38)
    tone(o, 0, 116, 0.07, 0.1 * v, glide=72)
    burst(o, 0, 0.05, 190, 0.9, 0.09 * v, 'lowpass')
    tone(o, 0.19, 52, 0.15, 0.22 * v, glide=34)
    tone(o, 0.19, 104, 0.08, 0.07 * v, glide=66)
    burst(o, 0.19, 0.045, 170, 0.9, 0.06 * v, 'lowpass')


def _gust(o, v):
    # the door open on the rain: the hiss swells in and is cut off as it swings to
    n = int(SR * 1.4)
    x = _filter(rng.standard_normal(n), 'bandpass', 2600, 0.5)
    x += 0.6 * _filter(rng.standard_normal(n), 'lowpass', 400, 0.7)
    tt = np.arange(n) / SR
    env = np.clip(tt / 0.25, 0, 1) * np.where(tt < 1.05, 1.0, np.exp(-(tt - 1.05) / 0.04))
    x = x * env
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.12 * v
    o[:n] += x[:len(o)]
    tone(o, 1.08, 90, 0.25, 0.3 * v, glide=40)


SECONDS = {'bell': 2.6, 'ring': 1.3, 'steps': 1.8, 'gust': 1.6, 'whisper': 0.9, 'pen': 0.7, 'tear': 0.4, 'printer': 0.3}
TAKES = {'scratch': 3, 'clack': 3, 'rattle': 4, 'tick': 4, 'printer': 3, 'pen': 3, 'tear': 2, 'ratchet': 3, 'zero': 2,
         'card': 3, 'page': 3, 'rings': 2, 'click': 3, 'tock': 2, 'glass': 2, 'thud': 2, 'whisper': 3, 'steps': 2}


def write(name, x, loop=False):
    peak = np.max(np.abs(x)) + 1e-9
    if peak > 0.98:
        x = x / peak * 0.98
    if loop:
        pass
    wavfile.write(os.path.join(OUT, name + '.wav'), SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))


# ---------------------------------------------------------------------------------- the room

def loop(seconds, fill):
    """A layer that loops: rendered a second long at each end and crossfaded into itself."""
    fade = 1.0
    x = buf(seconds + fade)
    fill(x, seconds + fade)
    n = int(SR * seconds)
    f = int(SR * fade)
    head = x[:f].copy()
    tail = x[n:n + f].copy()
    w = np.linspace(0, 1, f)
    y = x[:n].copy()
    y[:f] = head * w + tail * (1 - w)
    return y


def noise_bed(x, kind, freq, q, level):
    y = _filter(rng.standard_normal(len(x)), kind, freq, q)
    y = y / (np.std(y) + 1e-9) * level
    x += y


def am(n, rate, depth, smooth=0.05):
    """A slow wobble: random levels at `rate` a second, smoothed."""
    k = max(2, int(n / SR * rate) + 2)
    pts = rng.random(k)
    env = np.interp(np.linspace(0, k - 1, n), np.arange(k), pts)
    if smooth > 0:
        win = max(1, int(SR * smooth))
        env = np.convolve(env, np.ones(win) / win, mode='same')
    return 1 - depth + depth * env


def talk(x, secs, bright=1.0):
    n = len(x)
    # a room of people talking: several voices' worth of band-limited noise, each rising and
    # falling on its own syllables and breaths
    for k in range(7):
        f = 350 + r() * 900 * bright
        v = _filter(rng.standard_normal(n), 'bandpass', f, 1.6)
        v = v / (np.std(v) + 1e-9)
        v *= am(n, 3.5 + r() * 3, 0.85, 0.03) * am(n, 0.4 + r() * 0.4, 0.7, 0.3)
        x += v * 0.06
    # glasses now and then
    t = 0.3
    while t < secs - 0.5:
        tone(x, t, 3000 + r() * 1500, 0.2, 0.02 + r() * 0.02)
        t += 1.2 + r() * 3.5


def rain(x, secs, hard):
    noise_bed(x, 'bandpass', 3200, 0.6, 0.03 * hard)
    noise_bed(x, 'lowpass', 500, 0.7, 0.02 * hard)
    t = 0.0
    while t < secs:
        burst(x, t, 0.02, 2600 + r() * 3000, 4, (0.03 + r() * 0.05) * hard)
        t += 0.01 + r() * 0.05 / hard


def juke(x, secs):
    beat = 0.625
    t = 0.0
    i = 0
    while t < secs:
        tone(x, t, 70, 0.2, 0.2, glide=42)
        root = [55, 55, 49, 41.2][(i // 4) % 4]
        if i % 2 == 0:
            tone(x, t, root, 0.55, 0.12, 'triangle')
        if i % 4 == 2:
            burst(x, t, 0.05, 3500, 1.2, 0.02)
        t += beat
        i += 1
    y = _filter(x, 'lowpass', 500, 0.7)
    x[:] = y


def pool(x, secs):
    t = 1.0
    while t < secs - 1:
        if r() < 0.25:
            d = 0
            for i in range(6):
                burst(x, t + d, 0.016, 2300 + r() * 1400, 3, 0.2 * (1 - i * 0.1))
                d += 0.02 + r() * 0.07
        else:
            burst(x, t, 0.018, 2600, 3, 0.2)
            burst(x, t + 0.25 + r() * 0.5, 0.014, 2400, 3, 0.12)
        t += 3 + r() * 4


def shout(x, secs):
    n = len(x)
    for k in range(3):
        v = _filter(rng.standard_normal(n), 'bandpass', 900 + r() * 700, 2.0)
        v = v / (np.std(v) + 1e-9)
        v *= am(n, 5, 0.95, 0.02) * (am(n, 0.35, 1.0, 0.2) ** 3)
        x += v * 0.08


def hum(x, f, level):
    t = np.arange(len(x)) / SR
    x += level * (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * 2 * f * t) + 0.15 * np.sin(2 * np.pi * 3 * f * t))


def fryer(x, secs):
    noise_bed(x, 'highpass', 3500, 0.7, 0.012)
    t = 0.0
    while t < secs:
        burst(x, t, 0.012, 3500 + r() * 3000, 1.5, 0.04 + 0.06 * r())
        t += 0.05 + r() * 0.3


def drips(x, secs):
    t = 0.5
    while t < secs:
        tone(x, t, 900 + r() * 700, 0.08, 0.05, glide=1600)
        t += 1.5 + r() * 3


def rats(x, secs):
    t = 0.5
    while t < secs - 1:
        m = 3 + int(r() * 5)
        for i in range(m):
            burst(x, t + i * (0.04 + r() * 0.05), 0.03, 2600 + r() * 1800, 2, 0.12)
        t += 2 + r() * 5


def keys(x, secs):
    """The bookkeeper entering invoices with one finger: a key at a time, then a stop to read."""
    t = 0.6
    while t < secs - 1.5:
        for i in range(2 + int(r() * 6)):
            burst(x, t, 0.012, 3400 + r() * 600, 4, 0.16)
            burst(x, t + 0.004, 0.02, 900 + r() * 200, 2, 0.05)
            t += 0.28 + r() * 0.45
        t += 1.5 + r() * 4


def canopy(x, secs):
    """A gas station's canopy lights, buzzing, and a pump's screen beeping now and then."""
    hum(x, 120, 0.012)
    noise_bed(x, 'bandpass', 7000, 2, 0.002)
    t = 2.0
    while t < secs - 1:
        tone(x, t, 1850, 0.09, 0.03, 'square')
        t += 5 + r() * 7


def traffic(x, secs):
    """The highway in the wet: tires hissing past, and a log truck's roar now and then."""
    n = len(x)
    noise_bed(x, 'lowpass', 240, 0.7, 0.012)
    t = 0.4
    while t < secs - 1:
        big = r() < 0.3
        dur = 2.6 + r() * 1.6 if big else 1.4 + r() * 1.0
        m = int(SR * dur)
        i0 = int(SR * t)
        k = min(m, n - i0)
        if k > 0:
            v = _filter(rng.standard_normal(m), 'bandpass', 700 + r() * 500 if not big else 380, 0.7)
            v = v / (np.std(v) + 1e-9)
            env = np.sin(np.linspace(0, np.pi, m)) ** 2
            x[i0:i0 + k] += (v * env * (0.11 if big else 0.06))[:k]
        t += dur * 0.6 + 1.5 + r() * 5


LAYERS = {
    'rain_glass': (10, lambda x, s: rain(x, s, 1.0)),
    'rain_out': (10, lambda x, s: rain(x, s, 1.8)),
    'rain_roof': (10, lambda x, s: (rain(x, s, 0.7), x.__setitem__(slice(None), _filter(x, 'lowpass', 900, 0.7)))),
    'room_tone': (8, lambda x, s: (noise_bed(x, 'lowpass', 160, 0.7, 0.05), hum(x, 60, 0.01))),
    'talk_a': (12, lambda x, s: talk(x, s, 1.0)),
    'talk_b': (11, lambda x, s: talk(x, s, 1.3)),
    'shout': (9, lambda x, s: shout(x, s)),
    'juke': (10, lambda x, s: juke(x, s)),
    'pool': (14, lambda x, s: pool(x, s)),
    'fryer': (8, lambda x, s: fryer(x, s)),
    'fan': (8, lambda x, s: (noise_bed(x, 'bandpass', 420, 1.0, 0.05), hum(x, 50, 0.012))),
    'tube': (6, lambda x, s: (hum(x, 120, 0.008), noise_bed(x, 'bandpass', 6000, 2, 0.002))),
    'cellar': (10, lambda x, s: (hum(x, 60, 0.018), noise_bed(x, 'lowpass', 120, 0.7, 0.03), drips(x, s))),
    'rats': (12, lambda x, s: rats(x, s)),
    'sea': (12, lambda x, s: (noise_bed(x, 'lowpass', 300, 0.7, 0.04), x.__imul__(am(len(x), 0.12, 0.8, 1.0)))),
    # before the shift (content/ink/office.ink, walk.ink)
    'keys': (14, lambda x, s: keys(x, s)),
    'canopy': (9, lambda x, s: canopy(x, s)),
    'traffic': (16, lambda x, s: traffic(x, s)),
}


# no longer played: the pool game's heard shot by shot now (ROOM: cue, clack, pocket, break). Still
# made, so the files after it come out the same, but not written.
RETIRED = {'pool'}


# ---------------------------------------------------------------------------------- the room's own
#
# The sounds the room makes from where they happen (game/sound.gd, Sound.at; world/doings.gd): a
# glass set down after a sip, table 28 laughing, the pool game shot by shot, the bartender pouring
# and wiping down, someone in the washroom. Made after everything above, so adding them changed
# none of the files before them.

def _voice(o, t0, f0, n, rate, vol, vowel=(750, 1250, 2500), fall=0.85, breath=0.25):
    """One person's 'ha ha ha': n syllables at `rate` a second, a buzz at f0 (falling a little
    through the laugh) through the vowel's three formants, each syllable softer than the last."""
    for i in range(n):
        s = t0 + i / rate * (0.9 + 0.2 * r())
        d = 0.055 + 0.05 * r()
        m = int(SR * (d + 0.08))
        i0 = int(SR * s)
        if i0 >= len(o):
            return
        tt = np.arange(m) / SR
        f = f0 * (fall ** (i / max(n - 1, 1))) * (1.0 + 0.03 * np.sin(2 * np.pi * 6 * tt)) * (1 + 0.02 * (r() - 0.5))
        ph = 2 * np.pi * np.cumsum(f) / SR
        src = 2 * ((ph / (2 * np.pi)) % 1.0) - 1
        src += breath * rng.standard_normal(m)
        y = np.zeros(m)
        for fq, g in zip(vowel, (1.0, 0.55, 0.22)):
            y += g * _filter(src, 'bandpass', fq * (0.95 + 0.1 * r()), 5.0)
        env = np.minimum(tt / 0.012, 1.0) * np.exp(-np.maximum(tt - d * 0.5, 0) / (d * 0.45))
        y = y * env
        y = y / (np.max(np.abs(y)) + 1e-9) * vol * (1 - 0.6 * i / max(n, 1))
        k = min(m, len(o) - i0)
        o[i0:i0 + k] += y[:k]


def _breath_in(o, t, vol):
    burst(o, t, 0.25, 1400, 0.9, vol)


def _laugh(o, v):
    # table 28 going off together: four or five of them, high and low, in on it at different
    # moments, one wheezing at the end
    voices = 4 + int(r() * 2)
    for k in range(voices):
        f0 = [105, 125, 150, 190, 230][k % 5] * (0.92 + 0.16 * r())
        vowel = [(700, 1200, 2450), (650, 1080, 2400), (780, 1300, 2600), (600, 1000, 2300)][int(r() * 4)]
        _voice(o, 0.05 + r() * 0.45, f0, 4 + int(r() * 5), 4.2 + r() * 1.8, (0.11 + r() * 0.07) * v, vowel)
    _breath_in(o, 1.75 + r() * 0.3, 0.04 * v)


def _laugh_one(o, v):
    f0 = 110 + r() * 50
    _voice(o, 0.02, f0, 5 + int(r() * 3), 4.8 + r(), 0.2 * v, (720, 1180, 2450))
    _breath_in(o, 1.1 + r() * 0.2, 0.05 * v)


def _cough(o, v):
    s = 0.0
    for i in range(2 + int(r() * 2)):
        burst(o, s, 0.07, 450 + r() * 250, 1.2, (0.3 - i * 0.06) * v)
        burst(o, s + 0.01, 0.05, 1500 + r() * 400, 1.5, (0.1 - i * 0.02) * v)
        tone(o, s, 120 + r() * 40, 0.06, 0.05 * v, 'sawtooth', 95)
        s += 0.2 + r() * 0.12


def _stool(o, v):
    # a stool pushed back on the carpet: a judder of the feet, and the joint creaking under him
    n = int(SR * (0.28 + r() * 0.15))
    x = _filter(rng.standard_normal(n), 'bandpass', 380 + r() * 200, 1.1)
    tt = np.arange(n) / SR
    x *= (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * (28 + r() * 14) * tt))) * np.sin(np.pi * tt / tt[-1]) ** 0.6
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.12 * v
    o[:n] += x[:len(o)]
    tone(o, 0.05 + r() * 0.1, 170 + r() * 60, 0.18, 0.03 * v, 'sawtooth', 230 + r() * 40)


def _pour(o, v):
    # a pint pulled from the tap: the rush into the glass, its note rising as the glass fills, and
    # the last of it as the tap goes off
    secs = 3.0 + r() * 0.6
    n = int(SR * secs)
    tt = np.arange(n) / SR
    x = np.zeros(n)
    seg = int(SR * 0.05)
    noise = rng.standard_normal(n + seg)
    for i0 in range(0, n, seg):
        f = 850 + 900 * (i0 / n) ** 0.8
        y = _filter(noise[i0:i0 + seg * 2], 'bandpass', f, 3.5)[:seg]
        x[i0:i0 + len(y)] += y[:n - i0]
    x += 0.5 * _filter(rng.standard_normal(n), 'bandpass', 2600, 0.8)
    x *= am(n, 9, 0.35, 0.02)
    env = np.minimum(tt / 0.12, 1.0) * np.where(tt < secs - 0.25, 1.0, np.exp(-(tt - (secs - 0.25)) / 0.06))
    x = x * env
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.07 * v
    o[:n] += x[:len(o)]
    tone(o, secs - 0.22, 2400, 0.05, 0.01 * v)


def _wipe(o, v):
    for k in range(2):
        s = k * (0.26 + r() * 0.06)
        n = int(SR * 0.24)
        x = _filter(rng.standard_normal(n), 'lowpass', 1100 + r() * 400, 0.7)
        x *= np.sin(np.linspace(0, np.pi, n)) ** 2
        x = x / (np.max(np.abs(x)) + 1e-9) * 0.05 * v
        i0 = int(SR * s)
        o[i0:i0 + n] += x[:len(o) - i0]


def _flush(o, v):
    n = int(SR * 3.2)
    tt = np.arange(n) / SR
    x = np.zeros(n)
    seg = int(SR * 0.1)
    noise = rng.standard_normal(n + seg * 2)
    for i0 in range(0, n, seg):
        f = 2200 * np.exp(-tt[i0] / 1.4) + 300
        y = _filter(noise[i0:i0 + seg * 2], 'lowpass', f, 0.7)[:seg]
        x[i0:i0 + len(y)] += y[:n - i0]
    x *= am(n, 6, 0.4, 0.03)
    env = np.minimum(tt / 0.15, 1.0) * np.exp(-np.maximum(tt - 0.6, 0) / 1.1)
    x = x * env
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.16 * v
    o[:n] += x[:len(o)]
    noise_tail = int(SR * 1.4)
    i0 = int(SR * 2.4)
    y = _filter(rng.standard_normal(noise_tail), 'bandpass', 3000, 1.5) * np.linspace(1, 0, noise_tail)
    y = y / (np.max(np.abs(y)) + 1e-9) * 0.02 * v
    k = min(noise_tail, len(o) - i0)
    o[i0:i0 + k] += y[:k]


def _slap(o, v):
    burst(o, 0, 0.04, 280, 0.8, 0.35 * v, 'lowpass')
    burst(o, 0, 0.012, 2100, 1.2, 0.2 * v)
    tone(o, 0.015, 3100 + r() * 600, 0.12, 0.025 * v)
    tone(o, 0.03, 3900 + r() * 500, 0.1, 0.02 * v)


def _cue(o, v):
    burst(o, 0, 0.007, 1800 + r() * 500, 2.2, 0.26 * v)
    burst(o, 0.002, 0.02, 700, 1.2, 0.08 * v, 'lowpass')


def _pocket(o, v):
    burst(o, 0, 0.03, 480 + r() * 120, 1.1, 0.26 * v)
    n = int(SR * 0.7)
    x = _filter(rng.standard_normal(n), 'lowpass', 260, 0.7) * am(n, 16, 0.6, 0.01)
    x *= np.exp(-np.arange(n) / SR / 0.3)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.1 * v
    i0 = int(SR * 0.05)
    o[i0:i0 + n] += x[:len(o) - i0]


def _break(o, v):
    _cue(o, v)
    s = 0.03
    for i in range(14):
        burst(o, s, 0.015, 2300 + r() * 1500, 3, (0.24 - i * 0.012) * v)
        s += 0.008 + r() * 0.035
    for i in range(5):
        s += 0.12 + r() * 0.25
        burst(o, s, 0.014, 2400 + r() * 1200, 3, 0.08 * v)


def _lighter(o, v):
    for i in range(2 + int(r() * 2)):
        burst(o, i * 0.06, 0.012, 4200 + r() * 1500, 3, 0.1 * v)
    burst(o, 0.17, 0.3, 900, 0.9, 0.05 * v)


def _long(o, t0, f0, dur, vol, vowel, glide):
    """One voice on one long vowel (a 'hey!', an 'ohh'): a buzz at f0 going to f0 * glide over it,
    through the vowel's three formants."""
    m = int(SR * (dur + 0.15))
    i0 = int(SR * t0)
    if i0 >= len(o):
        return
    tt = np.arange(m) / SR
    f = f0 * (1 + (glide - 1) * np.minimum(tt / dur, 1.0)) * (1.0 + 0.025 * np.sin(2 * np.pi * 5.5 * tt))
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = 2 * ((ph / (2 * np.pi)) % 1.0) - 1 + 0.3 * rng.standard_normal(m)
    y = np.zeros(m)
    for fq, g in zip(vowel, (1.0, 0.6, 0.25)):
        y += g * _filter(src, 'bandpass', fq * (0.95 + 0.1 * r()), 4.0)
    env = np.minimum(tt / 0.03, 1.0) * np.exp(-np.maximum(tt - dur * 0.6, 0) / (dur * 0.3))
    y = y * env
    y = y / (np.max(np.abs(y)) + 1e-9) * vol
    k = min(m, len(o) - i0)
    o[i0:i0 + k] += y[:k]


def _cheer(o, v):
    # a goal on table 28's hockey: up they go, a shout each, a hand or two on the table, and a laugh
    for k in range(3 + int(r() * 2)):
        _long(o, 0.02 + r() * 0.25, 170 + r() * 70, 0.35 + r() * 0.4, (0.1 + r() * 0.06) * v, (620, 1750, 2550), 1.1 + r() * 0.1)
    for i in range(2 + int(r() * 2)):
        _slap(o[int(SR * (0.15 + i * 0.22 + r() * 0.1)):], 0.6 * v)
    _voice(o, 0.9 + r() * 0.3, 130 + r() * 30, 4, 5.0, 0.08 * v)


def _groan(o, v):
    # a near thing: the long 'ohh' going down together
    for k in range(3 + int(r() * 2)):
        _long(o, 0.02 + r() * 0.2, 140 + r() * 60, 0.7 + r() * 0.5, (0.09 + r() * 0.05) * v, (520, 900, 2400), 0.72 + r() * 0.1)


def _spill(o, v):
    # a glass knocked over on a table: the clunk of it going down, the beer across the top, and the
    # glass rolling a little on its side
    burst(o, 0, 0.03, 260, 0.8, 0.3 * v, 'lowpass')
    burst(o, 0.002, 0.015, 1400, 1.4, 0.12 * v)
    tone(o, 0.005, 1900 + r() * 500, 0.1, 0.03 * v)
    n = int(SR * 0.6)
    x = _filter(rng.standard_normal(n), 'bandpass', 900 + r() * 300, 0.9)
    x *= np.exp(-np.arange(n) / SR / 0.18) * am(n, 22, 0.5, 0.01)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.09 * v
    i0 = int(SR * 0.03)
    o[i0:i0 + n] += x[:len(o) - i0]
    m = int(SR * 0.7)
    y = _filter(rng.standard_normal(m), 'lowpass', 400, 0.7) * am(m, 7, 0.7, 0.02)
    y *= np.sin(np.linspace(0, np.pi, m))
    y = y / (np.max(np.abs(y)) + 1e-9) * 0.04 * v
    i1 = int(SR * 0.35)
    o[i1:i1 + m] += y[:len(o) - i1]


def radio(x, secs):
    """The cook's radio up on the shelf: a song on a small speaker, all middle and no bottom."""
    beat = 0.5
    t = 0.0
    i = 0
    while t < secs:
        root = [196, 196, 147, 165][(i // 8) % 4]
        if i % 2 == 0:
            tone(x, t, root, 0.4, 0.08, 'sawtooth')
            tone(x, t, root * 1.5, 0.35, 0.05, 'sawtooth')
        if i % 4 == 2:
            burst(x, t, 0.05, 2500, 1.0, 0.05)
        burst(x, t, 0.03, 180, 0.8, 0.07, 'lowpass')
        if i % 16 == 12:
            for k in range(4):
                tone(x, t + k * 0.12, root * 2 * [1, 1.12, 1.26, 1.5][k], 0.14, 0.04, 'triangle')
        t += beat
        i += 1
    noise_bed(x, 'bandpass', 3000, 1.0, 0.004)
    y = _filter(_filter(x, 'highpass', 450, 0.7), 'lowpass', 3200, 0.7)
    x[:] = y


ROOM = {
    'glass_down': lambda o, v: (burst(o, 0, 0.03, 240, 0.8, 0.22 * v, 'lowpass'), burst(o, 0.001, 0.02, 950, 1.5, 0.1 * v),
                                tone(o, 0.004, 2300 + r() * 700, 0.12, 0.028 * v), burst(o, 0.02, 0.12, 650, 1.2, 0.025 * v)),
    'clink': lambda o, v: (tone(o, 0, 2900 + r() * 600, 0.35, 0.07 * v), tone(o, 0, 4500 + r() * 500, 0.2, 0.03 * v),
                           burst(o, 0, 0.004, 5200, 3, 0.05 * v)),
    'laugh': _laugh,
    'laugh_one': _laugh_one,
    'cough': _cough,
    'stool': _stool,
    'pour': _pour,
    'wipe': _wipe,
    'flush': _flush,
    'door_wc': lambda o, v: (burst(o, 0, 0.005, 3200, 3, 0.12 * v), tone(o, 0.04, 85, 0.2, 0.3 * v, glide=45),
                             burst(o, 0.04, 0.06, 300, 0.8, 0.15 * v, 'lowpass')),
    'slap': _slap,
    'cue': _cue,
    'pocket': _pocket,
    'break': _break,
    'lighter': _lighter,
    'cheer': _cheer,
    'groan': _groan,
    'spill': _spill,
}
ROOM_SECONDS = {'laugh': 2.4, 'laugh_one': 1.6, 'cough': 1.0, 'pour': 3.8, 'wipe': 0.7, 'flush': 4.0, 'break': 2.0,
                'pocket': 0.9, 'clink': 0.5, 'lighter': 0.6, 'cheer': 2.0, 'groan': 1.8, 'spill': 1.2}
ROOM_TAKES = {'glass_down': 4, 'clink': 2, 'laugh': 3, 'laugh_one': 3, 'cough': 3, 'stool': 3, 'pour': 2, 'wipe': 2,
              'door_wc': 2, 'slap': 2, 'cue': 3, 'pocket': 2, 'lighter': 2, 'cheer': 2, 'groan': 2}
ROOM_LAYERS = {
    'radio': (12, lambda x, s: radio(x, s)),
}


def main(only=None):
    """Everything, or only the files named (amb_keys ...): the rest are still made, in order, so
    each file comes out the same either way, but only those are written."""
    os.makedirs(OUT, exist_ok=True)
    put = (lambda name, x: write(name, x)) if not only else (lambda name, x: write(name, x) if name in only else None)
    for name, fn in SFX.items():
        takes = TAKES.get(name, 1)
        for k in range(takes):
            x = buf(SECONDS.get(name, 0.6))
            fn(x, 1.0)
            put(name if k == 0 else f'{name}_{k + 1}', x)
    for name, (secs, fn) in LAYERS.items():
        x = loop(secs, fn)
        if name not in RETIRED:
            put('amb_' + name, x)
    for name, fn in ROOM.items():
        for k in range(ROOM_TAKES.get(name, 1)):
            x = buf(ROOM_SECONDS.get(name, 0.6))
            fn(x, 1.0)
            put(name if k == 0 else f'{name}_{k + 1}', x)
    for name, (secs, fn) in ROOM_LAYERS.items():
        put('amb_' + name, loop(secs, fn))
    print('wrote', len(only) if only else len(os.listdir(OUT)), 'files to', os.path.normpath(OUT))


if __name__ == '__main__':
    import sys
    main(set(sys.argv[1:]) or None)
