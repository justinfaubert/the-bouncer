# The fight's blows, made rather than recorded: deep and short, more felt than heard, so a run of
# them doesn't grate (Hutch, 23 Nov: "loud and bad, make them deep"). Each is a low body (a sine
# falling in pitch, the flesh) under a soft, low-passed knock (the bone), a touch of saturation.
#   python3 godot/tools/fight_sounds.py      writes godot/audio/punch*.wav, block*.wav, body_fall*.wav
import os
import wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")


def lowpass(x, cut):
    # one-pole, run twice
    a = np.exp(-2.0 * np.pi * cut / SR)
    for _ in range(2):
        y = np.zeros_like(x)
        acc = 0.0
        for i in range(len(x)):
            acc = (1 - a) * x[i] + a * acc
            y[i] = acc
        x = y
    return x


def blow(f0, f1, dur, body_decay, knock, knock_cut, noise_len, seed, peak=0.5):
    rng = np.random.default_rng(seed)
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t / 0.035)
    ph = 2 * np.pi * np.cumsum(f) / SR
    env = (1 - np.exp(-t / 0.002)) * np.exp(-t / body_decay)
    body = np.sin(ph) * env
    nz = rng.standard_normal(n) * np.exp(-t / noise_len)
    nz = lowpass(nz, knock_cut)
    nz /= max(1e-6, np.abs(nz).max())
    x = body + nz * knock
    x = np.tanh(x * 1.6) / np.tanh(1.6)
    fade = np.ones(n)
    k = int(SR * 0.02)
    fade[-k:] = np.linspace(1, 0, k)
    x *= fade
    return x / np.abs(x).max() * peak


def write(name, x):
    p = os.path.join(OUT, name + ".wav")
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    imp = p + ".import"
    if not os.path.exists(imp):
        open(imp, "w").write('[remap]\n\nimporter="keep"\n')
    print("wrote", p)


for i, (f0, f1, s) in enumerate([(150, 78, 1), (138, 70, 2), (160, 84, 3)]):
    write("punch" if i == 0 else "punch_%d" % (i + 1), blow(f0, f1, 0.32, 0.075, 0.55, 900, 0.012, s))
for i, (f0, f1, s) in enumerate([(110, 52, 4), (100, 48, 5)]):
    write("punch_body" if i == 0 else "punch_body_%d" % (i + 1), blow(f0, f1, 0.42, 0.11, 0.4, 500, 0.03, s))
for i, (f0, f1, s) in enumerate([(190, 120, 6), (175, 110, 7)]):
    write("block" if i == 0 else "block_%d" % (i + 1), blow(f0, f1, 0.22, 0.045, 0.35, 1200, 0.008, s, 0.38))
write("body_fall", blow(85, 38, 0.9, 0.22, 0.5, 350, 0.09, 8, 0.6))
