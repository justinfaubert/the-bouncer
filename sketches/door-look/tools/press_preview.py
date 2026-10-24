"""The press, offline: prints what his eyes saw the way look/press.gdshader does, from a raw picture
and its mask (godot/tests/shots_places.gd --raw), so the separation can be tuned without the game.

  python3 tools/press_preview.py OUT_DIR RAW.png [RAW.png ...] [--lut DIR] [--lift 0.72] [--white 0.92]

Each RAW is a <name>_raw.png with its <name>_mask.png beside it; the print goes to OUT_DIR/<name>.png.
--lut reads separation.png and separation_b.png from DIR instead of the press folder. Close to the
shader, not exact: the plates' misregistration and the grain's pinning to his head are left out.
"""
import os
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PRESS = os.path.join(HERE, '..', 'press')
PAPER = '#eae2cf'
INKS = {'night': '#1b2130', 'lamp': '#f0a23c', 'neon': '#d9382c', 'cold': '#8fc7b8', 'earth': '#9a5a3c'}


def hex_rgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def lin(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def srgb(c):
    c = np.maximum(c, 0.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1.0 / 2.4) - 0.055)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def load(path):
    return np.asarray(Image.open(path).convert('RGB'), dtype=np.float64) / 255.0


def table(lut_dir):
    """The two separation pictures as one [r, g, b, ink] table of five inks."""
    a = load(os.path.join(lut_dir, 'separation.png'))
    bpath = os.path.join(lut_dir, 'separation_b.png')
    b = load(bpath) if os.path.exists(bpath) else np.zeros_like(a)
    n = a.shape[0]
    t = np.zeros((n, n, n, 5))
    for bi in range(n):
        t[:, :, bi, 0:3] = a[:, bi * n:(bi + 1) * n, :].transpose(1, 0, 2)
        t[:, :, bi, 3:5] = b[:, bi * n:(bi + 1) * n, 0:2].transpose(1, 0, 2)
    return t


def separate(c, lut, lo, hi, lift):
    n = lut.shape[0]
    c = np.clip((c - lo) / (hi - lo), 0.0, 1.0) ** lift * (n - 1)
    i0 = np.floor(c).astype(int)
    i1 = np.minimum(i0 + 1, n - 1)
    f = c - i0
    out = 0.0
    for dr in (0, 1):
        for dg in (0, 1):
            for db in (0, 1):
                ir = i1[..., 0] if dr else i0[..., 0]
                ig = i1[..., 1] if dg else i0[..., 1]
                ib = i1[..., 2] if db else i0[..., 2]
                w = (f[..., 0] if dr else 1 - f[..., 0]) * (f[..., 1] if dg else 1 - f[..., 1]) * (f[..., 2] if db else 1 - f[..., 2])
                out = out + lut[ir, ig, ib] * w[..., None]
    return out


def tile(tex, h, w, px):
    ys = (np.arange(h) / px).astype(int) % tex.shape[0]
    xs = (np.arange(w) / px).astype(int) % tex.shape[1]
    return tex[ys][:, xs]


def shift(img, dx, dy):
    return np.roll(np.roll(img, -dy, axis=0), -dx, axis=1)


def press(raw, mask, lut, lo=0.0, hi=0.92, lift=0.72, tints=4.0):
    h, w, _ = raw.shape
    g = tile(load(os.path.join(PRESS, 'grain.png')), h, w, 1.5)
    pp = tile(load(os.path.join(PRESS, 'paper.png')), h, w, 1.5)
    s = separate(raw, lut, lo, hi, lift)
    cn, cl, cr, cc, ce = (s[..., i] for i in range(5))
    m = mask
    clean = m[..., 0] >= 0.97
    aa = 0.1
    T = np.clip(m[..., 0] / 0.9 + (g[..., 0] - 0.5) * 0.18, 0.0, 1.0)
    T = aa + T * (1.0 - 2.0 * aa)
    key = smoothstep(T - aa, T + aa, cn)
    around = (shift(raw, 3, 2) + shift(raw, -3, -2) + shift(raw, -2, 3) + shift(raw, 2, -3)) * 0.25
    dark = separate(around, lut, lo, hi, lift)[..., 0]
    line = m[..., 2] * smoothstep(0.08, 0.3, m[..., 2] * (0.75 + 0.5 * g[..., 2]))
    key = np.maximum(key, line * (1.0 - smoothstep(0.45, 0.7, dark)))
    key *= 1.0 - line * smoothstep(0.55, 0.8, dark)
    # the colour plates: grain channels as the shader uses them (g, b; the new two on a second sample)
    g2 = shift(g, 37, 61)
    pp2 = shift(pp, 211, 97)
    plates = []
    for c, gr, mot in ((cl, g[..., 1], pp[..., 1]), (cr, g[..., 2], pp[..., 2]),
                       (cc, g2[..., 1], pp2[..., 1]), (ce, g2[..., 2], pp2[..., 2])):
        k = np.clip(np.floor(c * tints + 0.5 + (gr - 0.5) * 0.9) / tints, 0.0, 1.0)
        plates.append(k * (0.88 + 0.24 * mot))
    key *= 0.94 + 0.12 * pp[..., 1]
    key *= 1.0 - smoothstep(0.78, 0.92, pp[..., 0]) * 0.6
    paper = lin(hex_rgb(PAPER))
    col = paper[None, None, :] * (0.95 + 0.08 * pp[..., 0:1])
    for k, ink in zip(plates, ('lamp', 'neon', 'cold', 'earth')):
        col = col * (1.0 - k[..., None] * (1.0 - lin(hex_rgb(INKS[ink]))))
    col = col * (1.0 - key[..., None] * (1.0 - lin(hex_rgb(INKS['night']))))
    if clean.any():
        sc = lin(np.clip(raw * 1.08, 0.0, 1.0))
        cc2 = paper * (0.96 + 0.05 * pp[..., 0:1]) * (1.0 + 0.97 * (sc / np.maximum(paper, 0.2) - 1.0))
        cc2 *= 1.0 - (line * 0.85)[..., None] * (1.0 - lin(hex_rgb(INKS['night'])))
        col[clean] = cc2[clean]
    return np.clip(srgb(col), 0.0, 1.0)


if __name__ == '__main__':
    args = sys.argv[1:]
    opts = {'--lut': PRESS, '--lift': '0.72', '--white': '0.92'}
    files = []
    i = 1
    while i < len(args):
        if args[i] in opts:
            opts[args[i]] = args[i + 1]
            i += 2
        else:
            files.append(args[i])
            i += 1
    out = args[0]
    os.makedirs(out, exist_ok=True)
    lut = table(opts['--lut'])
    for f in files:
        name = os.path.basename(f).replace('_raw.png', '')
        mask = load(f.replace('_raw.png', '_mask.png'))
        img = press(load(f), mask, lut, hi=float(opts['--white']), lift=float(opts['--lift']))
        Image.fromarray((img * 255 + 0.5).astype(np.uint8)).save(os.path.join(out, name + '.png'))
        print('printed', name)
