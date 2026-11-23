"""The darts' own sounds, rendered to audio/ as .wav (placeholders until Hutch records the real board,
like everything tools/sounds.py makes; a recording of the same name in audio/ replaces one).

Each is built the way the thing sounds: a sharp transient for the moment of contact, then the
modes of whatever rings (a steel point in sisal is mostly the board's body and the cabinet; the
wire is a thin steel ring; a dart on a dart is two brass barrels), as damped sines, a little
detuned from take to take so the same sound twice isn't the same.

  python3 tools/dart_sounds.py      (numpy and scipy)
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'audio')
SR = 44100
rng = np.random.default_rng(180)


def buf(s):
    return np.zeros(int(SR * s) + 1)


def band(x, lo, hi, order=2):
    nyq = SR / 2
    b, a = signal.butter(order, [max(lo, 20) / nyq, min(hi, nyq * 0.95) / nyq], 'band')
    return signal.lfilter(b, a, x)


def hp(x, f):
    b, a = signal.butter(2, f / (SR / 2), 'high')
    return signal.lfilter(b, a, x)


def lp(x, f):
    b, a = signal.butter(2, f / (SR / 2), 'low')
    return signal.lfilter(b, a, x)


def modes(out, t, parts, vol, jitter=0.03):
    """parts: [(freq, decay seconds, level)], rung at t."""
    i0 = int(t * SR)
    n = len(out) - i0
    tt = np.arange(n) / SR
    for f, d, lv in parts:
        f *= 1.0 + rng.uniform(-jitter, jitter)
        ph = rng.uniform(0, np.pi * 2)
        out[i0:] += np.sin(2 * np.pi * f * tt + ph) * np.exp(-tt / d) * lv * vol


def click(out, t, lo, hi, dur, vol):
    i0 = int(t * SR)
    n = int(dur * SR * 6)
    x = band(rng.standard_normal(n), lo, hi)
    tt = np.arange(n) / SR
    x *= np.exp(-tt / dur)
    x /= np.max(np.abs(x)) + 1e-9
    n = min(n, len(out) - i0)
    out[i0:i0 + n] += x[:n] * vol


def friction(out, t, dur, lo, hi, vol, rate=90.0):
    """A rough drag: noise in a band, chopped by the surface's grain."""
    i0 = int(t * SR)
    n = int(dur * SR)
    x = band(rng.standard_normal(n), lo, hi)
    tt = np.arange(n) / SR
    grain = 0.55 + 0.45 * np.sign(np.sin(2 * np.pi * rate * tt * (1 + 0.3 * rng.standard_normal(n).cumsum() / n)))
    env = np.sin(np.pi * np.minimum(tt / dur, 1.0)) ** 0.7
    x *= grain * env
    x /= np.max(np.abs(x)) + 1e-9
    n = min(n, len(out) - i0)
    out[i0:i0 + n] += x[:n] * vol


def write(name, x):
    x = x - np.mean(x)
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.89
    # a short fade at the end so nothing clicks off
    f = min(len(x), int(0.01 * SR))
    x[-f:] *= np.linspace(1, 0, f)
    wavfile.write(os.path.join(OUT, name + '.wav'), SR, (x * 32767).astype(np.int16))
    imp = os.path.join(OUT, name + '.wav.import')
    if not os.path.exists(imp):
        open(imp, 'w').write('[remap]\n\nimporter="keep"\n')


def takes(name, n, make):
    for k in range(n):
        write(name if k == 0 else '%s_%d' % (name, k + 1), make(k))


# a steel point into sisal: the crack of the fibres parting, the board's body (a cork-backed slab
# on a bracket) and the cabinet round it, short; the flights flick a little after
def sisal(k):
    o = buf(0.45)
    click(o, 0, 2500, 9000, 0.0016, 0.9)
    click(o, 0.0008, 600, 2200, 0.005, 0.55)
    modes(o, 0.0005, [(162, 0.05, 0.55), (310, 0.03, 0.35), (523, 0.018, 0.2), (1180, 0.008, 0.15)], 1.0, 0.06)
    friction(o, 0.01, 0.05, 3000, 8000, 0.05, 220)
    return o


# the bull: dead centre, where the board's thickest: the same, deeper and longer, the cabinet doors
# answering
def bull(k):
    o = buf(0.7)
    click(o, 0, 1800, 7000, 0.002, 0.8)
    modes(o, 0.0005, [(118, 0.09, 0.8), (236, 0.05, 0.4), (395, 0.03, 0.25), (880, 0.012, 0.12)], 1.0, 0.04)
    modes(o, 0.012, [(74, 0.12, 0.25), (148, 0.07, 0.18)], 1.0, 0.04)   # the cabinet
    return o


# off the wire: a thin steel ring, bright and short, and the dart's own barrel ringing back
def wire(k):
    o = buf(0.5)
    click(o, 0, 4000, 12000, 0.0009, 0.8)
    modes(o, 0.0002, [(3240, 0.07, 0.5), (5110, 0.045, 0.35), (7930, 0.03, 0.25), (1460, 0.05, 0.2)], 1.0, 0.05)
    modes(o, 0.001, [(2210, 0.11, 0.18), (6020, 0.06, 0.1)], 1.0, 0.05)
    return o


# a dart on a dart: brass on brass, a clack with a pitch in it
def clack(k):
    o = buf(0.5)
    click(o, 0, 2000, 9000, 0.0012, 0.9)
    modes(o, 0.0003, [(1870, 0.06, 0.5), (2950, 0.04, 0.35), (4420, 0.03, 0.3), (6880, 0.02, 0.2)], 1.0, 0.05)
    return o


# out onto the carpet: a soft drop and the barrel's tick as it rolls over
def drop(k):
    o = buf(0.5)
    click(o, 0, 120, 900, 0.012, 0.6)
    modes(o, 0.0, [(95, 0.05, 0.3)], 1.0)
    click(o, 0.09 + 0.03 * k, 2500, 7000, 0.002, 0.25)
    modes(o, 0.09 + 0.03 * k, [(2950, 0.03, 0.12)], 1.0)
    return o


# pulling one out of the board: the fibres grip the point, a squeak and a drag, and it comes free
def pull(k):
    o = buf(0.4)
    friction(o, 0.0, 0.09 + 0.02 * k, 1400, 4200, 0.45, 70 + 15 * k)
    click(o, 0.09 + 0.02 * k, 1500, 6000, 0.003, 0.5)
    modes(o, 0.09 + 0.02 * k, [(162, 0.03, 0.2), (1870, 0.02, 0.08)], 1.0)
    return o


# the throw: the hand coming through, air past the flights
def throw(k):
    o = buf(0.3)
    n = int(0.16 * SR)
    x = rng.standard_normal(n)
    tt = np.arange(n) / SR
    f = np.linspace(700 + 100 * k, 2400, n)
    y = np.zeros(n)
    # a swept band, worked in blocks
    blk = 256
    for i in range(0, n, blk):
        y[i:i + blk] = band(x[i:i + blk + 64], f[i] * 0.7, f[i] * 1.5)[:len(y[i:i + blk])]
    env = np.sin(np.pi * np.minimum(tt / 0.16, 1)) ** 1.5
    o[:n] += y * env * 0.5
    return o


# chalk on a blackboard: a few strokes, each a gritty drag with the chalk's skip in it
def chalk(k):
    o = buf(0.6)
    t = 0.0
    for s in range(3 + k % 2):
        d = rng.uniform(0.05, 0.11)
        friction(o, t, d, 1800, 7500, rng.uniform(0.5, 0.9), rng.uniform(140, 260))
        click(o, t, 3000, 9000, 0.0015, 0.3)
        t += d + rng.uniform(0.02, 0.06)
    return o


# Jim behind the bar with two stir sticks: the rail, the rail, and the glass. Ba-dum, ting.
def bar_fill(k):
    o = buf(1.6)
    for t, f in [(0.0, 930), (0.13, 760), (0.2, 700)][:2 + (k % 2)]:
        click(o, t, 900, 5000, 0.004, 0.6)
        modes(o, t, [(f, 0.035, 0.5), (f * 2.3, 0.015, 0.2)], 1.0)
    t = 0.34 if k % 2 else 0.3
    click(o, t, 4000, 12000, 0.001, 0.5)
    modes(o, t, [(2093, 0.8, 0.35), (5270, 0.45, 0.2), (8650, 0.25, 0.12), (3920, 0.6, 0.1)], 1.0, 0.01)
    return o


# the board's lamp filament, near the end of its life, catching and coming back
def filament(k):
    o = buf(0.5)
    tt = np.arange(len(o)) / SR
    hum = np.sin(2 * np.pi * 120 * tt) * 0.2 + np.sin(2 * np.pi * 240 * tt) * 0.08
    env = np.zeros(len(o))
    for a, b in [(0.0, 0.06), (0.11, 0.14), (0.2, 0.32)]:
        env[int(a * SR):int(b * SR)] = 1.0
    env = lp(env, 60)
    o += hum * env
    click(o, 0.0, 2000, 8000, 0.002, 0.3)
    click(o, 0.2, 2000, 8000, 0.002, 0.2)
    return o


if __name__ == '__main__':
    takes('dart_sisal', 4, sisal)
    takes('dart_bull', 2, bull)
    takes('dart_wire', 3, wire)
    takes('dart_clack', 3, clack)
    takes('dart_drop', 2, drop)
    takes('dart_pull', 3, pull)
    takes('dart_throw', 3, throw)
    takes('chalk', 3, chalk)
    takes('bar_fill', 2, bar_fill)
    takes('filament', 1, filament)
    print('darts sounds written to', os.path.normpath(OUT))
