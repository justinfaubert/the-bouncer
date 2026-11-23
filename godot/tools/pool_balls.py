#!/usr/bin/env python3
"""The Sov's pool balls, as pictures wrapped round Godot's SphereMesh (game/pool_table.gd).

Old bar balls: the whites gone the colour of a smoker's teeth, the colours a little faded, a chip or
two, the numbers in their circles on both sides. The cue ball is the coin-op's bar ball, with the
red dot some of them have, worn. Each picture is laid out the way SphereMesh lays its UVs: u round
the equator, v from the top pole down.

    python3 godot/tools/pool_balls.py        writes godot/textures/pool/ball_<n>.png
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), '..', 'textures', 'pool')
W, H = 512, 256
COLOURS = {1: (214, 168, 38), 2: (34, 58, 140), 3: (184, 42, 34), 4: (82, 40, 112), 5: (212, 102, 30),
           6: (30, 104, 58), 7: (112, 34, 40), 8: (18, 18, 18)}
IVORY = np.array([226, 214, 186], float)
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def glyph(n):
    im = Image.new('L', (200, 200), 0)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 118 if n < 10 else 92)
    s = str(n)
    bb = d.textbbox((0, 0), s, font=f)
    d.text((100 - (bb[0] + bb[2]) / 2, 100 - (bb[1] + bb[3]) / 2), s, fill=255, font=f)
    if n in (6, 9):
        d.rectangle((70, 168, 130, 176), fill=255)   # the line under a six or a nine
    return np.asarray(im, float) / 255.0


def make(n):
    rnd = random.Random(n * 31 + 7)
    u = (np.arange(W) + 0.5) / W
    v = (np.arange(H) + 0.5) / H
    U, V = np.meshgrid(u, v)
    x = np.sin(U * 2 * math.pi) * np.sin(V * math.pi)
    y = np.cos(V * math.pi)
    z = np.cos(U * 2 * math.pi) * np.sin(V * math.pi)
    img = np.zeros((H, W, 3), float)
    img[:] = IVORY
    if n == 0:
        img[:] = IVORY + 10
        # the bar ball's dots, six of them, worn pale
        for ax in [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]:
            c = x * ax[0] + y * ax[1] + z * ax[2]
            m = c > 0.985
            img[m] = img[m] * 0.4 + np.array([170, 60, 50]) * 0.6
    else:
        col = np.array(COLOURS[n if n <= 8 else n - 8], float)
        if n <= 8:
            img[:] = col
        else:
            band = np.abs(y) < 0.68
            img[band] = col
        g = glyph(n)
        for sign in (1, -1):
            c = x * sign
            disc = c > 0.88
            img[disc] = IVORY
            # the number, on the plane touching the disc
            pu = (-z * sign) / np.maximum(c, 1e-3)
            pv = -y / np.maximum(c, 1e-3)
            gi = np.clip(((pu / 0.42) * 0.5 + 0.5) * 199, 0, 199).astype(int)
            gj = np.clip(((pv / 0.42) * 0.5 + 0.5) * 199, 0, 199).astype(int)
            a = g[gj, gi] * (c > 0.9)
            img = img * (1 - a[..., None]) + np.array([24, 20, 18]) * a[..., None]
    # years of chalk, smoke and hands: a little grime in it, uneven, and a few chips to the white
    noise = np.random.default_rng(n).normal(0, 3.5, (H, W, 1))
    img = img * 0.97 + noise
    for _ in range(rnd.randint(1, 4)):
        cu, cv, r = rnd.random(), rnd.uniform(0.2, 0.8), rnd.uniform(0.006, 0.014)
        d = np.sqrt(((U - cu) * 2) ** 2 + (V - cv) ** 2)
        img[d < r] = IVORY * 0.92
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(os.path.join(OUT, 'ball_%d.png' % n))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for n in range(16):
        make(n)
    print('wrote', OUT)
