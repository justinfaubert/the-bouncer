"""The glasswasher's sounds (world/glasswasher.gd), rendered to audio/ as .wav:

  washer_run    the motor, the pump, the spray on the inside of the hood and on the glasses, the
                belt's chain ticking over: a loop
  washer_clack  the switch, a heavy toggle in a steel box

  python3 tools/washer_sounds.py     (numpy, scipy)

Placeholders like the rest of audio/ until Hutch records a real one (a file of the same name is all
it takes). Claude's.
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'audio')
SR = 22050
rng = np.random.default_rng(71)


def band(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], 'band')
    return signal.lfilter(b, a, x)


def low(x, f):
    b, a = signal.butter(2, f / (SR / 2), 'low')
    return signal.lfilter(b, a, x)


def write(name, x):
    x = x / (np.abs(x).max() + 1e-9) * 0.8
    wavfile.write(os.path.join(OUT, name + '.wav'), SR, (x * 32767).astype(np.int16))
    print('audio/' + name + '.wav', round(len(x) / SR, 2), 's')


def run(secs=6.0):
    n = int(SR * secs)
    t = np.arange(n) / SR
    # the motor: 50 Hz-ish, its harmonics, a slow wobble in its load
    f0 = 49.0
    motor = sum((0.6 / k) * np.sin(2 * np.pi * f0 * k * t + k) for k in (1, 2, 3, 4, 6))
    motor *= 1 + 0.08 * np.sin(2 * np.pi * 0.5 * t)
    # the spray: hiss through the hood, louder in bursts as the arms come round
    hiss = band(rng.standard_normal(n), 900, 6500) * (0.7 + 0.3 * np.sin(2 * np.pi * (1 / 1.5) * t) ** 2)
    # water on glass: little bright splashes
    splash = np.zeros(n)
    for _ in range(int(secs * 30)):
        i = rng.integers(0, n - 400)
        L = rng.integers(80, 380)
        splash[i:i + L] += rng.standard_normal(L) * np.exp(-np.arange(L) / (L / 4)) * rng.uniform(0.2, 0.6)
    splash = band(splash, 2000, 8000)
    # the chain: a tick per link, every 0.9 s (a slat going over the sprocket)
    chain = np.zeros(n)
    for k in np.arange(0, secs, 0.9):
        i = int(k * SR)
        L = 300
        chain[i:i + L] += np.sin(2 * np.pi * 1800 * np.arange(L) / SR) * np.exp(-np.arange(L) / 40)
    x = 0.55 * low(motor, 400) + 0.35 * hiss + 0.2 * splash + 0.12 * chain
    # loop it: cross-fade the end into the start
    fade = int(SR * 0.4)
    w = np.linspace(0, 1, fade)
    x[:fade] = x[:fade] * w + x[-fade:] * (1 - w)
    return x[:-fade]


def clack():
    n = int(SR * 0.35)
    t = np.arange(n) / SR
    x = np.zeros(n)
    # the toggle snaps over, the steel box rings a little
    for at, f, g in ((0.0, 2600, 1.0), (0.012, 900, 0.6)):
        i = int(at * SR)
        L = n - i
        tt = np.arange(L) / SR
        x[i:] += g * np.sin(2 * np.pi * f * tt) * np.exp(-tt * 60)
    x += band(rng.standard_normal(n), 1500, 7000) * np.exp(-t * 120) * 0.8
    x += np.sin(2 * np.pi * 420 * t) * np.exp(-t * 18) * 0.25
    return x


if __name__ == '__main__':
    write('washer_run', run())
    write('washer_clack', clack())
