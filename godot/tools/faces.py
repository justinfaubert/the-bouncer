"""The masks' faces, drawn (PROPOSED; see tools/masks.py). Each person's face is a picture put on
the front of their mask: big drawn eyes, brows, a mouth, the lines of their age and their mood, in
the bold flat way of a carnival mask or a 90s cartoon, so it never claims to be a real face. Each
has a set of pictures to swap between: as they are, two mouths for talking, and their eyes shut
for a blink, plus their own extra (a laugh, a wink).

The picture is the mask's front seen straight on (tools/masks.py's face_uvs): its middle is the
middle of the head, the top of the head 1/2.2 of the way up from it and the chin as far down; x
across the face and z up the face run from -1 to 1. Everything outside the face is bare skin.

  python3 tools/faces.py              every one
  python3 tools/faces.py amanda       just one

Writes models/masks/<name>_<expression>.png.
"""
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), 'models', 'masks')
N = 1024                 # the picture's size
SS = 3                   # drawn this many times bigger, then shrunk: smooth edges

INK = (26, 22, 20)
WHITE = (238, 230, 214)
SKIN = {'skin': (199, 163, 138), 'skin_pale': (217, 192, 174), 'skin_ruddy': (196, 146, 122)}


def P(x, z):
    """Face units to the picture's pixels (drawn size)."""
    return ((0.5 + x / 2.2) * N * SS, (0.5 - z / 2.2) * N * SS)


def W(w):
    return w * N * SS / 2.2


def bez(pts, n=40):
    """A Bezier curve through control points, as points along it."""
    out = []
    k = len(pts) - 1
    for i in range(n + 1):
        t = i / n
        x = z = 0.0
        for j, (px, pz) in enumerate(pts):
            b = math.comb(k, j) * t ** j * (1 - t) ** (k - j)
            x += b * px
            z += b * pz
        out.append((x, z))
    return out


class Face:
    def __init__(self, skin):
        self.skin = SKIN[skin]
        self.im = Image.new('RGB', (N * SS, N * SS), self.skin)
        self.d = ImageDraw.Draw(self.im)

    def line(self, pts, w, col=INK, taper=True):
        """A stroke of the brush: thick in the middle, thin at the ends, like a cut line."""
        n = len(pts)
        for i in range(n - 1):
            t = i / max(n - 2, 1)
            k = math.sin(math.pi * t) ** 0.6 if taper else 1.0
            ww = max(W(w) * (0.25 + 0.75 * k), 1.0)
            a, b = P(*pts[i]), P(*pts[i + 1])
            self.d.line([a, b], fill=col, width=int(ww))
            r = ww / 2
            self.d.ellipse([b[0] - r, b[1] - r, b[0] + r, b[1] + r], fill=col)

    def shape(self, pts, fill, outline=None, w=0.0):
        self.d.polygon([P(*p) for p in pts], fill=fill)
        if outline is not None:
            self.line(pts + [pts[0]], w, outline, taper=False)

    def dot(self, x, z, r, col=INK):
        cx, cz = P(x, z)
        rr = W(r)
        self.d.ellipse([cx - rr, cz - rr, cx + rr, cz + rr], fill=col)

    def tint(self, x, z, rx, rz, col):
        cx, cz = P(x, z)
        self.d.ellipse([cx - W(rx), cz - W(rz), cx + W(rx), cz + W(rz)], fill=col)

    def save(self, path):
        self.im.resize((N, N), Image.LANCZOS).save(path)


def darker(c, k):
    return tuple(int(v * k) for v in c)


# ---------------------------------------------------------------- the parts

def eye(f, x, z, s, kind, look=(0.0, 0.0), shut=False, side=1, iris=(60, 44, 34), lid=0.0, tilt=0.0, lash=0.0):
    """One eye at (x, z), s wide (half-width). kind: round, heavy (the lid down over it), happy (an
    arch, shut with laughing), beady (small and deep), fox (long, the outer corner up)."""
    if shut or kind == 'happy':
        up = kind == 'happy' and not shut
        arc = [(x - s, z), (x - s * 0.3, z + (0.55 if up else -0.25) * s), (x + s * 0.3, z + (0.55 if up else -0.25) * s), (x + s, z)]
        f.line(bez(arc), s * 0.22)
        if kind == 'fox' and shut:
            f.line(bez([(x + side * s, z), (x + side * s * 1.25, z + s * 0.22)], 6), s * 0.18)
        return
    t = tilt * side
    if kind == 'fox':
        top = [(x - s, z - s * 0.05 - t * s), (x - s * 0.4, z + s * 0.5), (x + s * 0.4, z + s * 0.48), (x + s, z + s * 0.2 + t * s)]
        bot = [(x + s, z + s * 0.2 + t * s), (x + s * 0.3, z - s * 0.34), (x - s * 0.4, z - s * 0.36), (x - s, z - s * 0.05 - t * s)]
    elif kind == 'beady':
        s *= 0.55
        top = [(x - s, z), (x - s * 0.5, z + s * 0.8), (x + s * 0.5, z + s * 0.8), (x + s, z)]
        bot = [(x + s, z), (x + s * 0.5, z - s * 0.7), (x - s * 0.5, z - s * 0.7), (x - s, z)]
    else:
        top = [(x - s, z), (x - s * 0.55, z + s * 0.95), (x + s * 0.55, z + s * 0.95), (x + s, z)]
        bot = [(x + s, z), (x + s * 0.55, z - s * 0.85), (x - s * 0.55, z - s * 0.85), (x - s, z)]
    outline = bez(top, 24) + bez(bot, 24)
    box = [int(v) for v in (P(x - s * 1.1, z + s * 1.2) + P(x + s * 1.1, z - s * 1.2))]
    before = f.im.crop(box)
    f.shape(outline, WHITE)
    # the iris and the pupil, where they're looking, clipped to the white by drawing the lid over
    ir = s * (0.5 if kind != 'beady' else 0.75)
    ix, iz = x + look[0] * s * 0.35, z + look[1] * s * 0.25 - (0.05 * s if kind == 'fox' else 0)
    f.dot(ix, iz, ir, iris)
    f.dot(ix, iz, ir * 0.48, INK)
    f.dot(ix - ir * 0.3, iz + ir * 0.35, ir * 0.16, WHITE)
    # what's outside the white goes back to what was there (the iris must not spill)
    mask = Image.new('L', f.im.size, 0)
    ImageDraw.Draw(mask).polygon([P(*p) for p in outline], fill=255)
    region = f.im.crop(box)
    f.im.paste(Image.composite(region, before, mask.crop(box)), box)
    f.d = ImageDraw.Draw(f.im)
    # a heavy lid, down over the top of the eye
    if kind == 'heavy' or lid > 0:
        k = lid if lid > 0 else 0.45
        lz = z + s * 0.95 - k * s * 1.4
        f.shape([(x - s * 1.05, z + s * 1.1), (x + s * 1.05, z + s * 1.1), (x + s * 1.02, lz + s * 0.1), (x, lz), (x - s * 1.02, lz + s * 0.1)],
                darker(f.skin, 0.9))
        f.line(bez([(x - s * 1.02, lz + s * 0.06), (x, lz - s * 0.04), (x + s * 1.02, lz + s * 0.06)], 20), s * 0.2)
    # the line round it: heavy on top, light under
    f.line(bez(top, 24), s * (0.24 + lash), taper=True)
    f.line(bez(bot, 24), s * 0.1)
    if kind == 'fox':
        # the wing at the outer corner, up and out
        cx, cz = top[-1] if side > 0 else top[0]
        f.line(bez([(cx, cz), (cx + side * s * 0.35, cz + s * 0.3)], 8), s * 0.2)


def brow(f, x, z, s, angle=0.0, arch=0.3, w=0.12, side=1):
    """A brow over an eye at x, s wide; angle > 0 lifts the inner end (worried), < 0 drops it (cross)."""
    a = angle * side
    pts = [(x - s, z - a * s * 0.5 * side), (x - s * 0.3, z + arch * s), (x + s * 0.4, z + arch * s * 0.8), (x + s, z + a * s * 0.5 * side - s * 0.1)]
    if side < 0:
        pts = [(2 * x - px, pz) for px, pz in pts]
    f.line(bez(pts, 24), w)


def mouth(f, z, s, kind, open_=0.0, crook=0.0, teeth=False, lip=None):
    """kind: flat, down (turned down), grin, smile, sly (one corner up). open_: 0 shut, 1 wide."""
    if kind == 'down':
        mid, ends = 0.06, -0.1
    elif kind == 'grin':
        mid, ends = -0.18, 0.18
    elif kind == 'smile':
        mid, ends = -0.08, 0.08
    elif kind == 'sly':
        mid, ends = -0.03, 0.02
    else:
        mid, ends = 0.0, -0.01
    l = (-s, z + ends * s * 2 - crook * s * 0.25)
    r = (s, z + ends * s * 2 + crook * s * 0.6)
    top = [l, (-s * 0.35, z + mid * s * 2 + 0.02), (s * 0.35, z + mid * s * 2 + 0.02 + crook * s * 0.2), r]
    if open_ > 0:
        dz = open_ * s * (0.9 if kind == 'grin' else 0.6)
        # the lower lip follows the upper one, crook and all, dropped: no wedge
        bot = [r, (top[2][0], top[2][1] - dz), (top[1][0], top[1][1] - dz), l]
        f.shape(bez(top, 20) + bez(bot, 20), (52, 30, 28))
        if teeth or kind == 'grin':
            f.shape(bez(top, 20) + [(s * 0.6, z + mid * s * 2 - dz * 0.25), (-s * 0.6, z + mid * s * 2 - dz * 0.25)], WHITE)
        f.line(bez(bot, 20), s * 0.07)
    elif kind == 'grin':
        dz = s * 0.42
        bot = [r, (s * 0.35, z + mid * s * 2 - dz), (-s * 0.35, z + mid * s * 2 - dz), l]
        f.shape(bez(top, 20) + bez(bot, 20), WHITE)
        f.line(bez(bot, 20), s * 0.07)
    f.line(bez(top, 24), s * 0.12)
    if lip:
        f.line(bez([(-s * 0.3, z + mid * s * 2 - s * 0.16 - open_ * s * 0.6), (s * 0.3, z + mid * s * 2 - s * 0.16 - open_ * s * 0.6)], 8), s * 0.07, lip)
    # the corners dug in
    for c, sx in ((l, -1), (r, 1)):
        f.line(bez([(c[0] - sx * s * 0.02, c[1] + s * 0.12), c, (c[0] - sx * s * 0.04, c[1] - s * 0.1)], 8), s * 0.06)


# ---------------------------------------------------------------- the people

def bartender(f, ex):
    # the lifer: hard, knowing, flat. Heavy lids, straight brows, a long upper lip, the mouth turned
    # down at one end, crow's feet and the two lines down from the nose
    shut = ex == 'blink'
    for sx in (-1, 1):
        eye(f, sx * 0.4, 0.05, 0.2, 'heavy', look=(-0.3, -0.1), shut=shut, side=sx, iris=(70, 74, 70), lid=0.5)
        brow(f, sx * 0.4, 0.33, 0.24, angle=-0.25, arch=0.1, w=0.075, side=sx)
        for k in range(3):
            f.line(bez([(sx * 0.66, 0.1 - k * 0.07), (sx * 0.74, 0.08 - k * 0.075)], 4), 0.018)
        f.line(bez([(sx * 0.17, -0.3), (sx * 0.3, -0.48), (sx * 0.34, -0.66)], 12), 0.03)
        f.line(bez([(sx * 0.25, -0.12), (sx * 0.4, -0.16)], 6), 0.018)
    op = {'talk_a': 0.25, 'talk_b': 0.5}.get(ex, 0.0)
    mouth(f, -0.62, 0.26, 'down', open_=op, crook=-0.25, lip=darker(f.skin, 0.78))
    f.line(bez([(-0.12, -0.88), (0.0, -0.92), (0.12, -0.88)], 8), 0.02)


def team_jacket(f, ex):
    # table 28's loudest, drunk and happy: eyes laughing shut, brows up, red-brown cheeks, a huge
    # grin, jowls
    for sx in (-1, 1):
        f.tint(sx * 0.48, -0.25, 0.2, 0.14, darker(f.skin, 0.88))
        kind = 'happy' if ex != 'blink' else 'round'
        eye(f, sx * 0.38, 0.05, 0.19, kind, shut=ex == 'blink', side=sx)
        brow(f, sx * 0.4, 0.4, 0.22, angle=0.35, arch=0.45, w=0.06, side=sx)
        f.line(bez([(sx * 0.62, -0.42), (sx * 0.7, -0.62), (sx * 0.6, -0.84)], 12), 0.03)
        f.line(bez([(sx * 0.2, -0.05), (sx * 0.34, -0.12)], 6), 0.018)
    op = {'talk_a': 0.35, 'talk_b': 0.7, 'laugh': 1.0}.get(ex, 0.0)
    mouth(f, -0.56, 0.42, 'grin', open_=op, teeth=True)
    f.line(bez([(-0.18, -0.95), (0.0, -0.99), (0.18, -0.95)], 8), 0.025)


def bigman(f, ex):
    # the big man, flat: small eyes deep under one heavy brow, a broken nose's line, the mouth a slot
    # in the beard
    for sx in (-1, 1):
        f.tint(sx * 0.33, 0.06, 0.2, 0.13, darker(f.skin, 0.8))
        eye(f, sx * 0.33, 0.04, 0.18, 'beady', look=(0.2 * sx * 0, 0), shut=ex == 'blink', side=sx, iris=(48, 40, 34))
    f.line(bez([(-0.62, 0.28), (-0.3, 0.33), (0.0, 0.24), (0.3, 0.33), (0.62, 0.28)], 30), 0.13, taper=True)
    f.line(bez([(-0.04, 0.18), (0.02, 0.0), (-0.03, -0.16)], 10), 0.025)
    op = {'talk_a': 0.35, 'talk_b': 0.65}.get(ex, 0.0)
    mouth(f, -0.54, 0.22, 'flat', open_=op)


def amanda(f, ex):
    # the fox: long eyes tilted up at the outer corners with a flick, looking sideways and amused,
    # thin arched brows, freckles across the nose, a crooked smile, a mole by the mouth
    shut = ex == 'blink'
    for sx in (-1, 1):
        wink = ex == 'wink' and sx > 0
        eye(f, sx * 0.4, 0.04, 0.23, 'fox', look=(0.55, 0.05), shut=shut or wink, side=sx, iris=(92, 60, 30), tilt=0.28, lash=0.06)
        brow(f, sx * 0.42, 0.34, 0.25, angle=0.05 if ex != 'wink' else (0.25 if sx < 0 else -0.1), arch=0.55, w=0.05, side=sx)
        f.line(bez([(sx * 0.5, -0.2), (sx * 0.64, -0.3)], 6), 0.016)
    for (x, z) in [(-0.22, -0.12), (-0.15, -0.18), (-0.08, -0.13), (0.08, -0.14), (0.15, -0.19), (0.23, -0.12),
                   (-0.3, -0.18), (0.31, -0.17), (0.0, -0.08), (-0.18, -0.24), (0.19, -0.25)]:
        f.dot(x, z, 0.012, darker(f.skin, 0.68))
    op = {'talk_a': 0.25, 'talk_b': 0.5, 'wink': 0.0}.get(ex, 0.0)
    mouth(f, -0.55, 0.27, 'sly', open_=op, crook=0.45, teeth=op > 0.3, lip=(150, 92, 84))
    f.dot(0.36, -0.5, 0.016, INK)


PEOPLE = {
    'bartender': (bartender, 'skin', ['neutral', 'talk_a', 'talk_b', 'blink']),
    'team_jacket': (team_jacket, 'skin_ruddy', ['neutral', 'talk_a', 'talk_b', 'blink', 'laugh']),
    'bigman': (bigman, 'skin', ['neutral', 'talk_a', 'talk_b', 'blink']),
    'amanda': (amanda, 'skin_pale', ['neutral', 'talk_a', 'talk_b', 'blink', 'wink']),
}


def build(name):
    fn, skin, exprs = PEOPLE[name]
    os.makedirs(OUT, exist_ok=True)
    for ex in exprs:
        f = Face(skin)
        fn(f, ex)
        f.save(os.path.join(OUT, f'{name}_{ex}.png'))
    print(name, ', '.join(exprs))


if __name__ == '__main__':
    for n in [a for a in sys.argv[1:] if not a.startswith('-')] or list(PEOPLE):
        build(n)
