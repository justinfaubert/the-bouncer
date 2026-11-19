"""The masks' faces, drawn (PROPOSED; see tools/masks.py), in layers, so they can feel things.

Each person's face is a picture on the front of their mask, in the bold flat way of a carnival
mask or a 90s cartoon, so it never claims to be a real face. It comes in two pieces:

- the base, <name>_face.png: their skin and what never moves (the lines of their age, a mole, the
  shading under a cheekbone);
- a sheet of parts to lay over it, <name>_parts.png: each brow, each eye's white and its lids, the
  iris, the mouth (shut, and open three ways for talking), and the marks a feeling leaves on a
  face (furrows, laugh lines, a flush, sweat, tears).

<name>_face.json says where each part is on the sheet and where it goes on the face, and holds
their expressions: which parts make "angry" on this face, where the eyes look, how big the pupils
are, how the head squashes or stretches with it. The game lays the parts together whenever the
face changes (game/face.gd) and puts each iris where they're looking, clipped to the eye's white,
so the eyes can follow someone, slide away from them, or drift apart when they're drunk.

Every face has the same expressions, so the game can ask anyone to look afraid, and each draws
them in their own way: the bartender's anger is cold and her smile rare and crooked, the team
jacket's laugh takes over his whole head and his sorrow cries, the big man does everything with
one brow, and Amanda's resting face already knows something you don't.

The picture is the mask's front seen straight on (tools/masks.py's face_uvs): its middle is the
middle of the head, the top of the head 1/2.2 of the way up from it and the chin as far down; x
across the face (to the right of the picture: the person's left) and z up the face run from -1
to 1. "l" and "r" are as you look at them. Everything outside the face is bare skin.

  python3 tools/faces.py              every one
  python3 tools/faces.py amanda       just one
  python3 tools/faces.py --sheet      and a sheet of every expression in the scratch folder given
                                      by --out (default /tmp), for looking at

Writes models/masks/<name>_face.png, <name>_parts.png and <name>_face.json.
"""
import copy
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), 'models', 'masks')
N = 1024                 # the face picture's size
SS = 3                   # drawn this many times bigger, then shrunk: smooth edges
PAD = 4                  # clear pixels round each part on the sheet, so filtering never bleeds
SHEET_W = 2048

INK = (26, 22, 20)
WHITE = (240, 233, 218)
WHITE_SHADE = (206, 196, 182)
MOUTH_IN = (66, 30, 30)
TEETH = (242, 236, 222)
TONGUE = (170, 96, 86)
TEAR = (150, 198, 206)
SWEAT = (196, 222, 226)

EXPRESSIONS = ['neutral', 'smile', 'laugh', 'sad', 'angry', 'shout', 'surprised', 'afraid',
               'suspicious', 'disgust', 'sly', 'tired']


# ---------------------------------------------------------------- drawing

def P(x, z):
    """Face units to the drawn picture's pixels."""
    return ((0.5 + x / 2.2) * N * SS, (0.5 - z / 2.2) * N * SS)


def W(w):
    return w * N * SS / 2.2


def bez(pts, n=40):
    """A Bezier curve on its control points, as points along it."""
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


def spline(pts, n=12):
    """A smooth curve through the points (Catmull-Rom)."""
    out = []
    p = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        for j in range(n):
            t = j / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * (2 * p1[a] + (-p0[a] + p2[a]) * t + (2 * p0[a] - 5 * p1[a] + 4 * p2[a] - p3[a]) * t2
                                    + (-p0[a] + 3 * p1[a] - 3 * p2[a] + p3[a]) * t3) for a in (0, 1)))
    out.append(pts[-1])
    return out


def lp(p, q, t):
    return (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t)


def shift(pts, dx=0.0, dz=0.0):
    return [(x + dx, z + dz) for x, z in pts]


def darker(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3])


def mixc(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def ramp(t, a=0.3, b=0.3, k0=0.2, k1=0.2):
    """A stroke's width along it: from k0 at the start up to 1, and down to k1 at the end."""
    if t < a:
        u = t / a
        return k0 + (1 - k0) * (u * u * (3 - 2 * u))
    if t > 1 - b:
        u = (1 - t) / b
        return k1 + (1 - k1) * (u * u * (3 - 2 * u))
    return 1.0


class Layer:
    """A sheet the size of the face, drawn SS times bigger than it's kept."""

    def __init__(self, fill=None):
        self.im = Image.new('RGBA', (N * SS, N * SS), (fill + (255,)) if fill else (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def stroke(self, pts, w, col=INK, profile=None, ends=(0.2, 0.2)):
        """A cut line, w wide (face units) at its fullest; profile(t) for its width along it, or
        tapering to ends at either end."""
        if len(pts) < 2:
            return
        q = [P(*p) for p in pts]
        acc = [0.0]
        for i in range(1, len(q)):
            acc.append(acc[-1] + math.dist(q[i], q[i - 1]))
        tot = acc[-1] or 1.0
        prof = profile or (lambda t: ramp(t, 0.3, 0.3, ends[0], ends[1]))
        ws = [max(W(w) * prof(a / tot), 1.6) for a in acc]
        left, right = [], []
        n = len(q)
        for i in range(n):
            a, b = q[max(i - 1, 0)], q[min(i + 1, n - 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(dx, dy) or 1.0
            nx, ny = -dy / ln, dx / ln
            h = ws[i] / 2
            left.append((q[i][0] + nx * h, q[i][1] + ny * h))
            right.append((q[i][0] - nx * h, q[i][1] - ny * h))
        self.d.polygon(left + right[::-1], fill=col)
        for i in (0, n - 1):
            r = ws[i] / 2
            self.d.ellipse([q[i][0] - r, q[i][1] - r, q[i][0] + r, q[i][1] + r], fill=col)

    def shape(self, pts, col):
        self.d.polygon([P(*p) for p in pts], fill=col)

    def ellipse(self, x, z, rx, rz, col):
        cx, cz = P(x, z)
        self.d.ellipse([cx - W(rx), cz - W(rz), cx + W(rx), cz + W(rz)], fill=col)

    def soft(self, shapes, col, alpha=1.0, blur=0.02):
        """A tint laid over what's there, its edge soft. shapes: ('poly', pts), ('ell', x, z, rx, rz)
        or ('line', pts, w), in face units; drawn small, blurred, then grown."""
        m = Image.new('L', (N, N), 0)
        d = ImageDraw.Draw(m)
        s = 1.0 / SS
        for sh in shapes:
            if sh[0] == 'poly':
                d.polygon([(a * s, b * s) for a, b in (P(*p) for p in sh[1])], fill=255)
            elif sh[0] == 'ell':
                cx, cz = P(sh[1], sh[2])
                d.ellipse([(cx - W(sh[3])) * s, (cz - W(sh[4])) * s, (cx + W(sh[3])) * s, (cz + W(sh[4])) * s], fill=255)
            elif sh[0] == 'line':
                d.line([(a * s, b * s) for a, b in (P(*p) for p in sh[1])], fill=255, width=max(int(W(sh[2]) * s), 1), joint='curve')
        if blur:
            m = m.filter(ImageFilter.GaussianBlur(W(blur) / SS))
        m = m.resize(self.im.size, Image.BILINEAR)
        if alpha < 1.0:
            m = m.point(lambda v: int(v * alpha))
        tint = Image.new('RGBA', self.im.size, tuple(col[:3]) + (0,))
        tint.putalpha(m)
        self.im.alpha_composite(tint)

    def clip(self, shape_pts):
        """Keeps only what's inside the shape (face units)."""
        m = Image.new('L', self.im.size, 0)
        ImageDraw.Draw(m).polygon([P(*p) for p in shape_pts], fill=255)
        a = self.im.getchannel('A')
        self.im.putalpha(Image.composite(a, Image.new('L', a.size, 0), m))

    def over(self, other):
        self.im.alpha_composite(other.im)

    def cut(self):
        """The drawn part, shrunk to the face's size: (picture, x, y) on the face, or None."""
        bb = self.im.getchannel('A').getbbox()
        if not bb:
            return None
        x0, y0 = max(bb[0] // SS - PAD, 0), max(bb[1] // SS - PAD, 0)
        x1, y1 = min(-(-bb[2] // SS) + PAD, N), min(-(-bb[3] // SS) + PAD, N)
        im = self.im.crop((x0 * SS, y0 * SS, x1 * SS, y1 * SS)).convert('RGBa')
        return im.resize((x1 - x0, y1 - y0), Image.LANCZOS).convert('RGBA'), x0, y0


# ---------------------------------------------------------------- the parts

def eye_geo(E, side, p):
    """The eye's opening: the upper lid's curve and the lower's control points, inner corner to
    outer and back."""
    x = side * E['x']
    z = E['z'] + p.get('dz', 0.0)
    s = E['s'] * p.get('size', 1.0)
    o = p.get('open', 1.0)
    sq = p.get('squint', 0.0)
    tilt = E.get('tilt', 0.0) + p.get('tilt', 0.0)
    xi, xo = x - side * s, x + side * s
    zi, zo = z - 0.04 * s, z + tilt * s
    up = E['up'] * s * o / 0.75
    lo = E['lo'] * s * (1.0 - 0.85 * sq) / 0.75
    pk = E.get('peak', 0.0)
    a, b = 0.33 + pk, 0.67 + pk
    lin, lout = p.get('lid_in', 0.0), p.get('lid_out', 0.0)
    c1, c2 = lp((xi, zi), (xo, zo), a), lp((xi, zi), (xo, zo), b)
    upper = [(xi, zi), (c1[0], c1[1] + up * (1 - lin)), (c2[0], c2[1] + up * (1 - lout)), (xo, zo)]
    lift = p.get('cheek', 0.0) * s * 0.25
    lower = [(xo, zo), (c2[0], c2[1] - lo + lift), (c1[0], c1[1] - lo + lift), (xi, zi)]
    return upper, lower, s


def eye_closed(p):
    return p.get('shut') or p.get('happy') or p.get('open', 1.0) < 0.08


def draw_white(lay, E, side, p):
    if eye_closed(p):
        return
    upper, lower, s = eye_geo(E, side, p)
    outline = bez(upper, 28) + bez(lower, 28)
    lay.shape(outline, WHITE)
    # the lid's shadow along the top of the white
    shade = Layer()
    shade.shape(bez(upper, 28) + bez(shift(upper, 0, -0.16 * s)[::-1], 28), WHITE_SHADE)
    shade.clip(outline)
    lay.over(shade)


def draw_lids(lay, E, side, p, skin):
    """The lids and lashes, and the closed eye when it's shut."""
    upper, lower, s = eye_geo(E, side, p)
    xi, zi = upper[0]
    xo, zo = upper[-1]
    lash = E['lash'] * s
    if p.get('shut'):
        lid = [(xi, zi), lp((xi, zi), (xo, zo), 0.33), lp((xi, zi), (xo, zo), 0.67), (xo, zo)]
        lid = [lid[0], (lid[1][0], lid[1][1] - 0.22 * s), (lid[2][0], lid[2][1] - 0.22 * s), lid[3]]
        # the shut lid: from the lash line up to its crease, a crescent, no higher than the open
        # eye's lid would be
        crease = [lid[0], (lid[1][0], lid[1][1] + 0.42 * s), (lid[2][0], lid[2][1] + 0.42 * s), lid[3]]
        if E.get('shadow'):
            lay.soft([('poly', bez(crease, 20) + bez(lid, 20)[::-1])], E['shadow'], 0.55, 0.012)
        lay.stroke(bez(lid, 28), lash, profile=lambda t: ramp(t, 0.35, 0.2, 0.3, 0.55))
        if E.get('lashes'):
            pts = bez(lid, 28)
            for k in range(E['lashes']):
                t = 0.5 + 0.45 * (k + 0.5) / E['lashes']
                px, pz = pts[int(t * 28)]
                lay.stroke([(px, pz), (px + side * 0.05 * s, pz - 0.16 * s), (px + side * 0.12 * s, pz - 0.2 * s)], lash * 0.45, ends=(0.8, 0.1))
        if E.get('crease') is not None:
            lay.stroke(bez(crease, 20)[5:16], 0.045 * s, ends=(0.1, 0.1))
        return
    if p.get('happy'):
        arc = [(xi, zi - 0.05 * s), lp((xi, zi), (xo, zo), 0.3), lp((xi, zi), (xo, zo), 0.7), (xo, zo - 0.05 * s)]
        arc = [arc[0], (arc[1][0], arc[1][1] + 0.62 * s), (arc[2][0], arc[2][1] + 0.62 * s), arc[3]]
        lay.stroke(bez(arc, 28), lash * 1.15, ends=(0.25, 0.25))
        if E.get('lashes'):
            lay.stroke([(xo, zo - 0.05 * s), (xo + side * 0.14 * s, zo + 0.04 * s)], lash * 0.6, ends=(0.8, 0.1))
        lay.stroke(bez([(xi + side * 0.2 * s, zi - 0.42 * s), (xi + side * s, zi - 0.62 * s), (xo - side * 0.2 * s, zo - 0.42 * s)], 16), 0.05 * s, ends=(0.1, 0.1))
        return
    if E.get('shadow'):
        crease = shift(upper, 0, E.get('crease', 0.3) * s)
        crease = [crease[0], crease[1], crease[2], (crease[3][0] + side * 0.12 * s, crease[3][1] + 0.05 * s)]
        lay.soft([('poly', bez(crease, 20) + bez(upper, 20)[::-1])], E['shadow'], E.get('shadow_a', 0.55), 0.015)
    # the lash line: thin at the nose, heavy towards the outer corner
    lay.stroke(bez(upper, 32), lash, profile=lambda t: ramp(t, 0.55, 0.12, 0.3, 0.75))
    if E.get('fold'):
        # a heavy lid: the skin under the brow hanging down over the outer corner of the eye
        up_pts = bez(upper, 24)
        fh = E['fold'] * s * p.get('fold', 1.0)
        fold = [(x, z + fh * (0.75 - 1.25 * (i / 24)) + 0.02 * s) for i, (x, z) in enumerate(up_pts)]
        fold.append((fold[-1][0] + side * 0.1 * s, fold[-1][1] - 0.06 * s))
        lay.shape(fold + up_pts[::-1], darker(skin, 0.9))
        lay.stroke(fold, 0.075 * s, ends=(0.15, 0.3))
    if E.get('wing'):
        wl = E.get('wing_len', 1.0)
        lay.stroke([(xo - side * 0.08 * s, zo - 0.01 * s), (xo + side * 0.14 * s * wl, zo + 0.08 * s * wl), (xo + side * 0.3 * s * wl, zo + 0.2 * s * wl)],
                   lash * E.get('wing_w', 0.8), profile=lambda t: 1.0 - 0.9 * t)
    if E.get('lashes'):
        pts = bez(upper, 32)
        for k in range(E['lashes']):
            t = 0.52 + 0.42 * (k + 0.5) / E['lashes']
            px, pz = pts[int(t * 32)]
            ln = 0.15 * s * (0.8 + 0.4 * t) * E.get('lash_len', 1.0)
            lay.stroke([(px, pz), (px + side * 0.04 * s, pz + ln * 0.75), (px + side * 0.12 * s, pz + ln)], lash * E.get('lash_w', 0.42), ends=(0.9, 0.1))
    lw = bez(lower, 28)
    lay.stroke(lw[:22] if side > 0 else lw[:22], E.get('lo_w', 0.06) * s, ends=(0.6, 0.1))
    if E.get('crease') is not None and not E.get('fold'):
        cr = shift(upper, 0, E['crease'] * s * (1.0 if p.get('open', 1.0) > 0.5 else 0.6))
        lay.stroke(bez(cr, 24)[4:22], 0.045 * s, ends=(0.1, 0.1))


def draw_iris(lay, E, pupil):
    """The iris at the face's middle, for cutting out: a ring of its colour, darker at its rim,
    lighter below, the pupil, and the light caught in it."""
    r = E['iris'] * E['s']
    col = E['iris_col']
    lay.ellipse(0, 0, r, r, darker(col, 0.55))
    lay.ellipse(0, 0, r * 0.86, r * 0.86, col)
    lay.soft([('ell', 0, -r * 0.35, r * 0.6, r * 0.38)], mixc(col, (255, 255, 255), 0.3), 0.55, r * 0.25)
    k = {'small': 0.2, 'normal': 0.44, 'big': 0.62}[pupil]
    if E.get('iris_ring'):
        # a warmer ring round the pupil: light down in a dark eye
        lay.soft([('ell', 0, 0, r * (k + 0.24), r * (k + 0.24))], E['iris_ring'], 0.85, r * 0.1)
    lay.ellipse(0, 0, r * k, r * k, INK)
    lay.ellipse(-r * 0.34, r * 0.36, r * 0.24, r * 0.24, (252, 250, 244))
    if E.get('catch', 1) > 1:
        lay.ellipse(r * 0.34, -r * 0.3, r * 0.1, r * 0.1, (252, 250, 244))


def brow_pts(B, side, p):
    x = side * B['x']
    z = B['z'] + p.get('raise', 0.0)
    L = B['s'] * p.get('len', 1.0)
    a = B.get('angle', 0.0) + p.get('angle', 0.0)
    ar = B.get('arch', 0.2) + p.get('arch', 0.0)
    xi, xo = x - side * L, x + side * L
    zi, zo = z + a * L * 0.8, z - a * L * 0.35 - 0.12 * L
    c1, c2 = lp((xi, zi), (xo, zo), 0.33), lp((xi, zi), (xo, zo), 0.68)
    return [(xi, zi), (c1[0], c1[1] + ar * L * 0.7), (c2[0], c2[1] + ar * L * 0.65), (xo, zo)]


def draw_brow(lay, B, side, p):
    col = B.get('col', INK)
    if B.get('kind') == 'uni':
        # one brow across: anger pulls its middle down into a V, worry pushes it up
        L = B['s']
        z = B['z'] + p.get('raise', 0.0)
        a = B.get('angle', 0.0) + p.get('angle', 0.0)
        ar = B.get('arch', 0.15) + p.get('arch', 0.0)
        lr = p.get('tilt', 0.0)
        pts = [(-L, z - 0.05 - lr * 0.06), (-L * 0.55, z + ar * 0.1 + a * 0.02 - lr * 0.04), (-L * 0.12, z + a * 0.12),
               (L * 0.12, z + a * 0.12), (L * 0.55, z + ar * 0.1 + a * 0.02 + lr * 0.04), (L, z - 0.05 + lr * 0.06)]
        cur = spline(pts, 10)
        lay.stroke(cur, B['w'], col, profile=lambda t: 0.45 + 0.55 * math.sin(math.pi * min(max(t, 0.02), 0.98)) ** 0.35)
        for i in range(8, len(cur) - 8, 5):
            px, pz = cur[i]
            lay.stroke([(px, pz + B['w'] * 0.25), (px + 0.015, pz + B['w'] * 0.62)], 0.012, col, ends=(0.8, 0.2))
        return
    pts = bez(brow_pts(B, side, p), 24)
    if B.get('kind') == 'straight':
        prof = lambda t: ramp(t, 0.15, 0.4, 0.75, 0.35)
    else:  # thick at the nose, tapering to a point
        prof = lambda t: ramp(t, 0.12, 0.65, 0.8, 0.12)
    lay.stroke(pts, B['w'], col, profile=prof)


def mouth_geo(M, p):
    z = M['z'] + p.get('dz', 0.0)
    s = M['s'] * p.get('width', 1.0)
    c = M.get('curve', 0.0) + p.get('curve', 0.0)
    k = M.get('crook', 0.0) + p.get('crook', 0.0)
    zl = z + c * (0.32 * s + 0.025) - k * (0.08 * s + 0.01)
    zr = z + c * (0.32 * s + 0.025) + k * (0.16 * s + 0.02)
    mid = z - c * (0.1 * s + 0.01)
    L, R = (-s, zl), (s, zr)
    top = [L, (-s * 0.42, mid + (zl - z) * 0.25 + k * 0.02 * s), (s * 0.42, mid + (zr - z) * 0.25 + k * 0.05 * s), R]
    return L, R, top, mid, s, c, k


def draw_mouth(lay, M, p, skin):
    L, R, top, mid, s, c, k = mouth_geo(M, p)
    o = p.get('open', 0.0)
    shape = p.get('shape', 'normal')
    lips = M.get('lips')
    lw = M.get('line_w', 0.05)
    if shape == 'o':
        # an O: round, the lips pushed out round it
        d = 0.06 + o * s * 0.55
        cz = mid - d * 0.55
        rx, rz = s * 0.62, d * 0.9
        if lips:
            lay.ellipse(0, cz, rx + lips['lower'] * 0.5, rz + lips['lower'] * 0.6, lips['col'])
            lay.soft([('ell', s * 0.15, cz - rz - lips['lower'] * 0.35, s * 0.18, lips['lower'] * 0.22)], (255, 236, 230), 0.45, 0.01)
        lay.ellipse(0, cz, rx, rz, MOUTH_IN)
        if o > 0.4:
            t = Layer()
            t.ellipse(0, cz - rz * 0.85, rx * 0.6, rz * 0.45, TONGUE)
            t.clip([(rx * math.cos(a), cz + rz * math.sin(a)) for a in [i * math.pi / 24 for i in range(48)]])
            lay.over(t)
        ring = [(rx * math.cos(a), cz + rz * math.sin(a)) for a in [i * math.pi / 24 for i in range(49)]]
        lay.stroke(ring, lw * (0.7 if lips else 1.0), INK if not lips else darker(lips['col'], 0.55), profile=lambda t: 0.7 + 0.3 * math.sin(math.pi * 2 * t) ** 2)
        return
    depth = 0.0
    bot = None
    if o > 0 or shape == 'tongue':
        d = o * s * (0.95 if shape in ('normal', 'shout') else 0.7) / 0.75
        if c >= 0 or shape == 'shout':
            bot = [R, (s * 0.48, mid - d * (1.0 + 0.2 * max(c, 0))), (-s * 0.48, mid - d * (1.0 + 0.2 * max(c, 0))), L]
        else:
            bot = [R, (s * 0.5, mid - d * 0.85), (-s * 0.5, mid - d * 0.85), L]
            # a frown opened: the top lip lifts in the middle
            top = [top[0], (top[1][0], top[1][1] + d * 0.15), (top[2][0], top[2][1] + d * 0.15), top[3]]
        if shape == 'sneer':
            # the lip lifted on one side, off the teeth
            side = 1 if k >= 0 else -1
            i = 2 if side > 0 else 1
            top = list(top)
            top[i] = (top[i][0], top[i][1] + 0.18 * s)
        depth = d
    interior = bez(top, 28) + (bez(bot, 28) if bot else bez(top, 28)[::-1])
    lipcol = lips['col'] if lips else None
    if lips:
        uh, lh = lips['upper'], lips['lower']
        mz = top[1][1] * 0.5 + top[2][1] * 0.5
        # the upper lip: the cupid's bow above the line
        rb = [(0.0, mz + uh * 0.7), (s * 0.1, mz + uh * 1.12), (s * 0.4, mz + uh * 0.95), R]
        lb = [L, (-s * 0.4, mz + uh * 0.95), (-s * 0.1, mz + uh * 1.12), (0.0, mz + uh * 0.7)]
        upper_lip = bez(top, 28) + bez(rb, 16)[::-1] + bez(lb, 16)[::-1]
        lay.shape(upper_lip, darker(lipcol, 0.88))
        under = bot if bot else [R, (s * 0.45, mid - 0.01), (-s * 0.45, mid - 0.01), L]
        low_z = min(under[1][1], under[2][1]) * 0.75 + mid * 0.25
        lower_out = [R, (s * 0.55, low_z - lh * 1.5), (-s * 0.55, low_z - lh * 1.5), L]
        lay.shape(bez(under, 28) + bez(lower_out, 28)[::-1], lipcol)
        lay.soft([('ell', s * 0.14, low_z - lh * 0.75, s * 0.2, lh * 0.22)], (255, 238, 232), 0.5, 0.008)
        lay.soft([('ell', -s * 0.2, mz + uh * 0.55, s * 0.12, uh * 0.15)], (255, 238, 232), 0.3, 0.006)
    if bot:
        lay.shape(interior, MOUTH_IN)
        inner = Layer()
        th = min(0.2 * s, depth * 0.42)
        if shape == 'grimace':
            inner.shape(interior, TEETH)
            gap = lp(top[1], bot[2], 0.5)[1]
            inner.stroke(bez([L, (-s * 0.45, gap), (s * 0.45, gap), R], 20), 0.016, darker(TEETH, 0.45), ends=(0.6, 0.6))
        elif p.get('teeth'):
            inner.shape(bez(top, 28) + bez(shift(top, 0, -th), 28)[::-1], TEETH)
            if shape in ('shout', 'sneer'):
                inner.shape(bez(bot, 28) + bez(shift(bot, 0, th * 0.85), 28)[::-1], TEETH)
        if shape == 'grimace':
            for i in range(-3, 4):
                x = i * s * 0.22
                inner.stroke([(x, mid + 0.1), (x, mid - depth * 1.4)], 0.008, darker(TEETH, 0.7), ends=(1, 1))
        if p.get('tongue') and depth > 0.05:
            inner.ellipse(0, mid - depth * 1.05, s * 0.45, depth * 0.42, TONGUE)
            inner.stroke([(0, mid - depth * 0.85), (0, mid - depth * 1.2)], 0.012, darker(TONGUE, 0.75), ends=(0.3, 0.3))
        inner.clip(interior)
        lay.over(inner)
        lay.stroke(bez(bot, 28), lw * (0.55 if lips else 0.85), INK if not lips else darker(lipcol, 0.5), ends=(0.4, 0.4))
    if shape == 'tongue':
        # the tongue out, teasing
        tz = mid - 0.01
        t = [(-s * 0.3, tz), (-s * 0.34, tz - 0.12), (0, tz - 0.2), (s * 0.34, tz - 0.12), (s * 0.3, tz)]
        lay.shape(spline(t, 8), TONGUE)
        lay.stroke(spline(t, 8), 0.016, darker(TONGUE, 0.55), ends=(0.4, 0.4))
        lay.stroke([(0.0, tz - 0.02), (0.01, tz - 0.12)], 0.012, darker(TONGUE, 0.6), ends=(0.3, 0.3))
    # the line of the mouth, and its corners dug in
    lcol = INK if not lips else darker(lipcol, 0.42)
    lay.stroke(bez(top, 32), lw * (0.75 if lips else 1.0), lcol, profile=lambda t: 0.45 + 0.55 * math.sin(math.pi * t) ** 0.5)
    if not lips and M.get('under', True) and not bot:
        lay.stroke([(-s * 0.28, mid - 0.075 - abs(c) * 0.02), (0, mid - 0.09 - abs(c) * 0.02), (s * 0.28, mid - 0.075 - abs(c) * 0.02)],
                   lw * 0.6, darker(skin, 0.72), ends=(0.1, 0.1))
    for corner, sx in ((L, -1), (R, 1)):
        up = c + (k if sx > 0 else -k) * 0.6
        if abs(up) > 0.2:
            dz = 0.07 * (1 if up > 0 else -1)
            lay.stroke([(corner[0] - sx * 0.01, corner[1] - dz * 0.3), corner, (corner[0] + sx * 0.03, corner[1] + dz)], lw * 0.6, lcol, ends=(0.2, 0.1))


def draw_mark(lay, st, name):
    E, B, M = st['eye'], st['brow'], st['mouth']
    skin = st['skin_col']
    lc = darker(skin, 0.55)
    if name == 'furrow':
        for sx in (-1, 1):
            lay.stroke(bez([(sx * 0.05, B['z'] - 0.1), (sx * 0.075, B['z'] - 0.02), (sx * 0.065, B['z'] + 0.07)], 10), 0.022, INK, ends=(0.2, 0.2))
    elif name == 'forehead':
        for i, dz in enumerate((0.2, 0.3, 0.4)):
            w = 0.42 - i * 0.07
            zz = B['z'] + dz
            lay.stroke(spline([(-w, zz - 0.015), (-w * 0.4, zz + 0.02), (w * 0.1, zz - 0.01), (w * 0.6, zz + 0.018), (w, zz - 0.01)], 8), 0.02, lc, ends=(0.1, 0.1))
    elif name == 'worry':
        for dz in (0.19, 0.28):
            zz = B['z'] + dz
            lay.stroke(bez([(-0.17, zz - 0.035), (0, zz + 0.03), (0.17, zz - 0.035)], 12), 0.02, lc, ends=(0.1, 0.1))
    elif name == 'smile' and st.get('soft_marks'):
        for sx in (-1, 1):
            lay.soft([('line', bez([(sx * (M['s'] + 0.02), M['z'] + 0.1), (sx * (M['s'] + 0.07), M['z'] + 0.02), (sx * (M['s'] + 0.04), M['z'] - 0.05)], 8), 0.03)],
                     darker(skin, 0.72), 0.55, 0.012)
    elif name == 'laugh' and st.get('soft_marks'):
        for sx in (-1, 1):
            lay.soft([('ell', sx * (E['x'] + 0.02), E['z'] - E['s'] * 0.85, E['s'] * 0.7, E['s'] * 0.14)], darker(skin, 0.8), 0.5, 0.015)
    elif name == 'smile':
        for sx in (-1, 1):
            x0 = sx * (M['s'] * 0.55 + 0.04)
            lay.stroke(bez([(x0, -0.28), (sx * (M['s'] + 0.1), M['z'] + 0.1), (sx * (M['s'] + 0.05), M['z'] - 0.02)], 14), 0.02, mixc(lc, skin, 0.3), ends=(0.1, 0.4))
    elif name == 'laugh':
        for sx in (-1, 1):
            ox, oz = sx * (E['x'] + E['s'] * 1.08), E['z']
            for kk in (-1, 0, 1):
                a = kk * 0.42
                lay.stroke([(ox, oz + kk * 0.015), (ox + sx * 0.1 * math.cos(a), oz + 0.1 * math.sin(a))], 0.02, lc, ends=(0.6, 0.1))
    elif name == 'bags':
        for sx in (-1, 1):
            lay.stroke(bez([(sx * (E['x'] - E['s'] * 0.65), E['z'] - E['s'] * 0.72), (sx * E['x'], E['z'] - E['s'] * 1.05),
                            (sx * (E['x'] + E['s'] * 0.8), E['z'] - E['s'] * 0.7)], 14), 0.02, lc, ends=(0.1, 0.1))
    elif name == 'sweat':
        x, z = 0.6, 0.45
        drop = [(x, z + 0.12), (x + 0.05, z + 0.0), (x + 0.045, z - 0.05), (x, z - 0.07), (x - 0.045, z - 0.05), (x - 0.05, z)]
        lay.shape(spline(drop + [drop[0]], 8), SWEAT)
        lay.stroke(spline(drop + [drop[0]], 8), 0.014, INK, ends=(1, 1))
        lay.ellipse(x - 0.015, z - 0.02, 0.012, 0.018, (255, 255, 255))
    elif name == 'tears':
        for sx in (-1, 1):
            x0, z0 = sx * (E['x'] + E['s'] * 0.45), E['z'] - E['s'] * 0.45
            path = bez([(x0, z0), (x0 + sx * 0.03, z0 - 0.15), (x0 + sx * 0.01, z0 - 0.3), (x0 + sx * 0.05, z0 - 0.42)], 16)
            lay.stroke(path, 0.04, TEAR, ends=(0.5, 0.9))
            ex, ez = path[-1]
            lay.ellipse(ex, ez - 0.02, 0.028, 0.034, TEAR)
            lay.stroke(path[:10], 0.008, (255, 255, 255), ends=(0.3, 0.3))
    elif name == 'flush':
        lay.soft([('ell', -0.46, -0.2, 0.2, 0.12), ('ell', 0.46, -0.2, 0.2, 0.12)], st.get('flush', (196, 104, 92)), 0.55, 0.035)
    elif name == 'vein':
        x, z = 0.52, 0.6
        for a in range(4):
            ang = a * math.pi / 2 + math.pi / 4
            cx, cz = x + 0.11 * math.cos(ang), z + 0.11 * math.sin(ang)
            pts = [(cx + 0.09 * math.cos(ang + math.pi * 0.75), cz + 0.09 * math.sin(ang + math.pi * 0.75)), (cx - 0.03 * math.cos(ang), cz - 0.03 * math.sin(ang)),
                   (cx + 0.09 * math.cos(ang - math.pi * 0.75), cz + 0.09 * math.sin(ang - math.pi * 0.75))]
            lay.stroke(bez(pts, 10), 0.05, (128, 44, 40), ends=(0.3, 0.3))
    elif name == 'nose':
        for i in range(3):
            zz = -0.02 + i * 0.045
            lay.stroke(bez([(-0.07, zz - 0.01), (0, zz + 0.012), (0.07, zz - 0.01)], 8), 0.014, lc, ends=(0.2, 0.2))
    elif name == 'glare':
        # a shadow over the eyes: the brow come down over them
        for sx in (-1, 1):
            lay.soft([('ell', sx * E['x'], E['z'] + E['s'] * 0.55, E['s'] * 1.15, E['s'] * 0.5)], darker(skin, 0.6), 0.5, 0.03)
    elif name == 'pale':
        lay.soft([('ell', 0, 0.35, 0.75, 0.45)], (210, 214, 208), 0.35, 0.08)


# ---------------------------------------------------------------- the expressions

# Every face's expressions, before each person's own way of doing them. eye/brow: the same both
# sides, or {'l': ..., 'r': ...} as you look at them. gaze: where the eyes look, -1..1 across
# (to the right of the picture: their left) and up. head: the head squashed or stretched with it,
# (wide, tall).
BASE = {
    'neutral': {},
    'smile': {'brow': {'raise': 0.02, 'arch': 0.05}, 'eye': {'squint': 0.3, 'cheek': 0.6}, 'mouth': {'curve': 0.75},
              'marks': ['smile']},
    'laugh': {'brow': {'raise': 0.07, 'angle': 0.12}, 'eye': {'happy': True}, 'mouth': {'curve': 0.85, 'open': 0.8, 'teeth': True, 'tongue': True, 'width': 1.08},
              'marks': ['smile', 'laugh'], 'head': (1.05, 0.95), 'gaze': (0, 0)},
    'sad': {'brow': {'angle': 0.55, 'raise': 0.02}, 'eye': {'open': 0.85, 'lid_out': 0.35}, 'mouth': {'curve': -0.65, 'width': 0.85},
            'marks': ['worry'], 'gaze': (0.0, -0.7), 'head': (1.0, 0.98)},
    'angry': {'brow': {'angle': -0.65, 'raise': -0.06}, 'eye': {'open': 0.9, 'lid_in': 0.45, 'squint': 0.25}, 'mouth': {'curve': -0.5, 'width': 0.85},
              'marks': ['furrow'], 'head': (1.02, 0.97)},
    'shout': {'brow': {'angle': -0.75, 'raise': -0.05}, 'eye': {'open': 1.05, 'lid_in': 0.5}, 'mouth': {'curve': -0.25, 'open': 1.0, 'teeth': True, 'shape': 'shout', 'width': 1.05},
              'marks': ['furrow'], 'head': (1.05, 1.04), 'pupil': 'small'},
    'surprised': {'brow': {'raise': 0.13, 'arch': 0.25}, 'eye': {'open': 1.3, 'squint': -0.15}, 'mouth': {'shape': 'o', 'open': 0.55, 'width': 0.5},
                  'marks': ['forehead'], 'pupil': 'small', 'head': (0.95, 1.07)},
    'afraid': {'brow': {'raise': 0.1, 'angle': 0.6}, 'eye': {'open': 1.25}, 'mouth': {'curve': -0.4, 'open': 0.35, 'teeth': True, 'shape': 'grimace', 'width': 0.95},
               'marks': ['worry', 'sweat'], 'pupil': 'small', 'head': (0.96, 1.03), 'gaze': (0.55, 0.05)},
    'suspicious': {'brow': {'l': {'raise': -0.05, 'angle': -0.35}, 'r': {'raise': 0.08, 'angle': -0.1, 'arch': 0.2}}, 'eye': {'open': 0.62, 'squint': 0.45},
                   'mouth': {'curve': -0.2, 'crook': -0.45, 'width': 0.8}, 'gaze': (0.65, 0.0)},
    'disgust': {'brow': {'angle': -0.3, 'raise': -0.03}, 'eye': {'open': 0.72, 'squint': 0.5}, 'mouth': {'shape': 'sneer', 'curve': -0.35, 'crook': 0.45, 'open': 0.22, 'teeth': True},
                'marks': ['nose'], 'gaze': (-0.35, -0.25), 'head': (1.0, 0.97)},
    'sly': {'brow': {'l': {'raise': -0.02}, 'r': {'raise': 0.07, 'arch': 0.2}}, 'eye': {'open': 0.6, 'lid_out': 0.1}, 'mouth': {'curve': 0.4, 'crook': 0.6},
            'gaze': (0.7, 0.0)},
    'tired': {'brow': {'angle': 0.15, 'raise': 0.0}, 'eye': {'open': 0.42, 'lid_out': 0.15}, 'mouth': {'curve': -0.15, 'open': 0.1},
              'marks': ['bags'], 'gaze': (0.0, -0.45), 'head': (1.0, 0.98)},
}


def merge(a, b):
    out = copy.deepcopy(a)
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = merge(out[k], v)
        else:
            out[k] = copy.deepcopy(v)
    return out


def sides(d):
    """A setting the same both sides, or each its own."""
    if d is None:
        return {}, {}
    if 'l' in d or 'r' in d:
        common = {k: v for k, v in d.items() if k not in ('l', 'r')}
        return merge(common, d.get('l', {})), merge(common, d.get('r', {}))
    return d, d


def talk_mouths(m):
    """The mouths for talking in this expression: a little open, wide, round."""
    o = m.get('open', 0.0)
    if m.get('shape') == 'o':
        return [merge(m, {'open': o * 0.6, 'width': m.get('width', 1) * 1.1}), merge(m, {'open': o * 1.25}), merge(m, {'open': o * 0.9, 'width': m.get('width', 1) * 0.8})]
    if o >= 0.3:
        return [merge(m, {'open': o * 0.65}), merge(m, {'open': o * 1.15}), merge(m, {'open': o * 0.85, 'width': m.get('width', 1) * 0.85})]
    base = {k: v for k, v in m.items() if k not in ('shape',)}
    if m.get('shape') == 'tongue':
        base['shape'] = 'normal'
    return [merge(base, {'open': 0.3, 'teeth': m.get('teeth', base.get('curve', 0) > 0.3)}), merge(base, {'open': 0.62, 'teeth': True, 'tongue': True}),
            merge(base, {'shape': 'o', 'open': 0.35, 'width': 0.55})]


# ---------------------------------------------------------------- the people

def p_bartender(lay, st):
    # the lifer: twenty-five years behind the bar. Her age in the lines that don't go away: crow's
    # feet, two lines down from her nose to past her mouth, the ones under her eyes, a crease in
    # her chin, the forehead she's frowned with
    skin = st['skin_col']
    lc = darker(skin, 0.62)
    lay.soft([('ell', -0.4, -0.12, 0.18, 0.1), ('ell', 0.4, -0.12, 0.18, 0.1)], darker(skin, 0.86), 0.6, 0.04)
    lay.soft([('ell', 0, -0.36, 0.1, 0.05)], darker(skin, 0.78), 0.6, 0.02)
    for sx in (-1, 1):
        for kk in range(3):
            lay.stroke([(sx * 0.65, 0.11 - kk * 0.06), (sx * 0.75, 0.09 - kk * 0.075)], 0.016, lc, ends=(0.6, 0.1))
        lay.stroke(bez([(sx * 0.17, -0.28), (sx * 0.29, -0.42), (sx * 0.33, -0.56), (sx * 0.32, -0.68)], 16), 0.019, mixc(lc, skin, 0.35), ends=(0.2, 0.5))
        lay.stroke(bez([(sx * 0.24, -0.11), (sx * 0.38, -0.16), (sx * 0.52, -0.1)], 10), 0.016, lc, ends=(0.1, 0.1))
    lay.stroke(bez([(-0.11, -0.86), (0.0, -0.9), (0.11, -0.86)], 8), 0.018, lc, ends=(0.2, 0.2))
    for dz in (0.58, 0.67):
        lay.stroke(spline([(-0.3, dz), (-0.1, dz + 0.012), (0.12, dz - 0.008), (0.3, dz + 0.006)], 8), 0.012, darker(skin, 0.75), ends=(0.1, 0.1))


def p_team_jacket(lay, st):
    # a soft, ruddy drinker's face: the cheeks and the nose always flushed, broken veins in them,
    # jowls, a second chin, the lines of a man who laughs a lot
    skin = st['skin_col']
    lc = darker(skin, 0.64)
    lay.soft([('ell', -0.48, -0.22, 0.22, 0.15), ('ell', 0.48, -0.22, 0.22, 0.15)], (190, 112, 96), 0.55, 0.04)
    for sx in (-1, 1):
        for kk in range(3):
            x, z = sx * (0.42 + kk * 0.05), -0.18 - kk * 0.03
            lay.stroke([(x, z), (x + sx * 0.03, z - 0.02), (x + sx * 0.02, z - 0.045)], 0.007, (150, 70, 66), ends=(0.4, 0.4))
        lay.stroke(bez([(sx * 0.62, -0.42), (sx * 0.71, -0.62), (sx * 0.6, -0.84)], 12), 0.026, lc, ends=(0.2, 0.3))
        lay.stroke(bez([(sx * 0.66, 0.14), (sx * 0.74, 0.1), (sx * 0.78, 0.04)], 8), 0.014, lc, ends=(0.3, 0.1))
    lay.stroke(bez([(-0.2, -0.95), (0.0, -0.99), (0.2, -0.95)], 8), 0.024, lc, ends=(0.2, 0.2))
    for dz in (0.62, 0.72):
        lay.stroke(spline([(-0.34, dz), (-0.1, dz + 0.015), (0.14, dz - 0.008), (0.34, dz + 0.01)], 8), 0.013, darker(skin, 0.74), ends=(0.1, 0.1))


def p_bigman(lay, st):
    # deep-set eyes in the shadow of his brow, a scar through it from an old fight, and the grey
    # stubble of a man who shaves his head and not his face, the cartoon's five o'clock shadow: a
    # flat darker grey with a clean edge, over the jaw, the chin and the lip, up under the
    # cheekbones, stippled along its top. (A beard of its own, a shell round his jaw with a slot
    # for the mouth, read as a muzzle; a soft one didn't survive the print.)
    skin = st['skin_col']
    grey = mixc(darker(skin, 0.58), (96, 96, 102), 0.45)
    top = spline([(-0.84, -0.06), (-0.7, -0.22), (-0.5, -0.31), (-0.3, -0.33), (-0.14, -0.29), (0.0, -0.28),
                  (0.14, -0.29), (0.3, -0.33), (0.5, -0.31), (0.7, -0.22), (0.84, -0.06)], 8)
    jaw = spline([(0.84, -0.06), (0.9, -0.5), (0.72, -0.92), (0.36, -1.12), (0.0, -1.16), (-0.36, -1.12),
                  (-0.72, -0.92), (-0.9, -0.5), (-0.84, -0.06)], 8)
    lay.soft([('poly', top + jaw)], grey, 0.4, 0.012)
    # and the stipple a cartoonist gives it, dark enough for the print to keep under the lamp: dots
    # on a jittered grid, thinning out along the top
    edge = top + jaw
    def inside(x, z):
        c = False
        for (x1, z1), (x2, z2) in zip(edge, edge[1:] + edge[:1]):
            if (z1 > z) != (z2 > z) and x < x1 + (z - z1) * (x2 - x1) / (z2 - z1):
                c = not c
        return c
    dots = []
    k = 7
    def rnd():
        nonlocal k
        k = (k * 1103515245 + 12345) % 2147483648
        return (k >> 8) % 10000 / 10000.0
    zz = -0.2
    while zz > -1.15:
        xx = -0.9 + (0.02 if int(zz * 100) % 2 else 0.0)
        while xx < 0.9:
            x, z = xx + (rnd() - 0.5) * 0.03, zz + (rnd() - 0.5) * 0.03
            if inside(x, z):
                d = min(abs(z - tz) + abs(x - tx) * 0.3 for tx, tz in top)
                if rnd() < min(1.0, 0.35 + d * 9.0):
                    dots.append(('ell', x, z, 0.0105, 0.0105))
            xx += 0.042
        zz -= 0.04
    lay.soft(dots, mixc(grey, (40, 38, 38), 0.55), 0.85, 0.003)
    for sx in (-1, 1):
        lay.soft([('ell', sx * 0.33, 0.07, 0.24, 0.16)], darker(skin, 0.7), 0.75, 0.04)
    lay.stroke([(-0.5, 0.42), (-0.4, 0.2), (-0.33, 0.06)], 0.022, mixc(skin, (236, 220, 206), 0.55), ends=(0.4, 0.4))
    for t in (0.25, 0.5, 0.75):
        x, z = lp((-0.5, 0.42), (-0.33, 0.06), t)
        lay.stroke([(x - 0.03, z - 0.01), (x + 0.03, z + 0.01)], 0.01, darker(skin, 0.6), ends=(1, 1))


def p_amanda(lay, st):
    # fewer marks than anyone: the hollow under each high cheekbone and its top in the light, a
    # little colour there, the sides of a straight nose, the groove above her lip, the shadow under
    # it, her chin lit. No lines and no beauty mark: nothing on her face has happened to it yet
    skin = st['skin_col']
    for sx in (-1, 1):
        # the plane under the cheekbone, short, from by the ear down toward the mouth: cut clean
        # along the bone, as a cartoonist draws it, and fading below (a soft one didn't survive the
        # print, and her face read round; a long one ran to her mouth like lines of age)
        bone = spline([(sx * 0.9, 0.0), (sx * 0.8, -0.12), (sx * 0.7, -0.21), (sx * 0.6, -0.27)], 8)
        under = spline([(sx * 0.63, -0.3), (sx * 0.76, -0.25), (sx * 0.87, -0.17), (sx * 0.93, -0.07)], 8)
        lay.soft([('poly', bone + under)], darker(skin, 0.68), 0.62, 0.006)
        lay.soft([('poly', bone + under)], darker(skin, 0.68), 0.3, 0.04)
        # the cheekbone's top in the light, and colour on it
        lay.soft([('line', bez([(sx * 0.36, -0.1), (sx * 0.55, -0.06), (sx * 0.74, 0.0)], 8), 0.07)], mixc(skin, (255, 244, 230), 0.4), 0.45, 0.04)
        lay.soft([('ell', sx * 0.5, -0.17, 0.15, 0.07)], (198, 116, 96), 0.2, 0.045)
        # the temples a little in shadow
        lay.soft([('ell', sx * 0.82, 0.32, 0.1, 0.2)], darker(skin, 0.88), 0.35, 0.05)
        # the sides of the nose, and its nostril
        lay.soft([('line', bez([(sx * 0.07, 0.14), (sx * 0.075, -0.04), (sx * 0.095, -0.2)], 8), 0.028)], darker(skin, 0.86), 0.4, 0.02)
        lay.soft([('ell', sx * 0.052, -0.262, 0.028, 0.014)], darker(skin, 0.62), 0.6, 0.008)
    # under the nose, the groove above her lip, the shadow under her lower lip, the chin lit
    lay.soft([('ell', 0, -0.295, 0.085, 0.022)], darker(skin, 0.8), 0.45, 0.014)
    lay.soft([('line', [(0.0, -0.355), (0.0, -0.44)], 0.036)], darker(skin, 0.88), 0.35, 0.012)
    lay.soft([('ell', 0, -0.78, 0.14, 0.035)], darker(skin, 0.82), 0.5, 0.02)
    lay.soft([('ell', 0, -0.9, 0.12, 0.05)], mixc(skin, (255, 244, 230), 0.3), 0.3, 0.03)


PEOPLE = {
    # the lifer: hard, knowing, flat. Heavy lids, grey-green eyes, straight steel brows, a long
    # upper lip and the mouth turned down. Her smile is rare and goes up one side; her anger is
    # cold, the lids come down and the mouth goes thin; she's never really surprised
    'bartender': dict(
        skin='skin', base=p_bartender,
        eye=dict(x=0.4, z=0.05, s=0.2, up=0.56, lo=0.4, peak=0.04, tilt=-0.04, lash=0.17, lo_w=0.07, fold=0.26,
                 iris=0.5, iris_col=(76, 92, 78)),
        brow=dict(x=0.4, z=0.33, s=0.23, w=0.06, arch=0.1, angle=-0.18, col=(52, 52, 56), kind='straight'),
        mouth=dict(z=-0.62, s=0.25, curve=-0.25, crook=-0.15, line_w=0.055),
        expr={
            'neutral': {'eye': {'open': 0.72}},
            'smile': {'eye': {'open': 0.7, 'squint': 0.35}, 'mouth': {'curve': 0.6, 'crook': 0.55}},
            'laugh': {'mouth': {'curve': 0.7, 'open': 0.6, 'width': 0.95}, 'head': (1.03, 0.97)},
            'angry': {'eye': {'open': 0.6, 'lid_in': 0.3}, 'mouth': {'curve': -0.25, 'width': 0.75}, 'marks': ['furrow', 'glare']},
            'surprised': {'brow': {'l': {'raise': 0.03}, 'r': {'raise': 0.13, 'arch': 0.25}}, 'eye': {'open': 1.05}, 'mouth': {'shape': 'normal', 'open': 0.25, 'curve': -0.2, 'width': 0.8},
                          'head': (0.98, 1.03), 'marks': ['forehead']},
            'sly': {'mouth': {'curve': 0.45, 'crook': 0.7}},
            'tired': {'eye': {'open': 0.35}},
            'eyeroll': {'brow': {'raise': 0.06, 'angle': 0.1}, 'eye': {'open': 0.62}, 'mouth': {'curve': -0.3, 'crook': -0.5, 'width': 0.85}, 'gaze': (0.4, 1.0)},
        }),
    # table 28's loudest, drunk and happy: eyes always half laughing, high arched brows, red-brown
    # cheeks, a huge grin, jowls. His laugh takes over his whole head; his sorrow cries; his
    # anger goes red and shouts; drunk, his eyes come unstuck from each other
    'team_jacket': dict(
        skin='skin_ruddy', base=p_team_jacket, flush=(186, 92, 80),
        eye=dict(x=0.38, z=0.06, s=0.19, up=0.92, lo=0.82, lash=0.18, lo_w=0.07, iris=0.44, iris_col=(80, 112, 140)),
        brow=dict(x=0.4, z=0.42, s=0.21, w=0.075, arch=0.5, angle=0.2, col=(80, 74, 68)),
        mouth=dict(z=-0.56, s=0.4, curve=0.45, line_w=0.062),
        expr={
            'neutral': {'eye': {'open': 0.8, 'squint': 0.45, 'cheek': 0.6}, 'marks': ['smile']},
            'smile': {'eye': {'happy': True}, 'mouth': {'curve': 0.9, 'open': 0.45, 'teeth': True}, 'marks': ['smile', 'laugh']},
            'laugh': {'mouth': {'open': 1.0, 'width': 1.12}, 'marks': ['smile', 'laugh', 'tears'], 'head': (1.08, 0.92)},
            'sad': {'brow': {'angle': 0.8}, 'eye': {'open': 0.95}, 'mouth': {'curve': -0.9, 'width': 0.75}, 'marks': ['worry', 'tears']},
            'angry': {'mouth': {'curve': -0.9, 'width': 0.7, 'open': 0.3, 'teeth': True, 'shape': 'grimace'}, 'marks': ['furrow', 'flush', 'vein']},
            'shout': {'marks': ['furrow', 'flush', 'vein'], 'head': (1.08, 1.06)},
            'sly': {'eye': {'r': {'shut': True}, 'l': {'open': 0.8, 'squint': 0.4}}, 'mouth': {'curve': 0.75, 'crook': 0.5}, 'gaze': (0.0, 0.0)},
            'drunk': {'brow': {'l': {'raise': 0.05}, 'r': {'raise': -0.02}}, 'eye': {'open': 0.5, 'lid_out': 0.2}, 'mouth': {'curve': 0.2, 'open': 0.15, 'crook': -0.3},
                      'marks': ['flush', 'bags'], 'gaze': {'l': (0.9, -0.5), 'r': (-0.8, 0.2)}, 'head': (1.02, 0.98)},
        }),
    # the big man, flat: small dark eyes deep under one heavy brow, a scar through it, the mouth a
    # slot in his stubble. He does everything with the brow: down into a V and he's dangerous, up
    # and he's a kid again
    'bigman': dict(
        skin='skin', base=p_bigman,
        eye=dict(x=0.33, z=0.04, s=0.15, up=0.8, lo=0.7, lash=0.22, lo_w=0.08, iris=0.62, iris_col=(58, 46, 38)),
        brow=dict(kind='uni', x=0.0, z=0.27, s=0.6, w=0.13, arch=0.1, col=(30, 26, 24)),
        mouth=dict(z=-0.55, s=0.2, line_w=0.06, under=False),
        expr={
            'smile': {'mouth': {'curve': 0.55}},
            'laugh': {'mouth': {'open': 0.55, 'width': 1.0}, 'head': (1.06, 0.94)},
            'surprised': {'brow': {'raise': 0.16}, 'eye': {'open': 1.5, 'size': 1.15}, 'mouth': {'width': 0.6}},
            'suspicious': {'brow': {'tilt': 1.0, 'angle': -0.4}},
            'sly': {'brow': {'tilt': 0.8}, 'mouth': {'curve': 0.35, 'crook': 0.7}},
            'menace': {'brow': {'angle': -0.9, 'raise': -0.06}, 'eye': {'open': 0.55, 'lid_in': 0.4}, 'mouth': {'curve': 0.35, 'open': 0.25, 'teeth': True, 'shape': 'grimace', 'width': 0.9},
                       'marks': ['glare'], 'gaze': (0, 0), 'head': (1.03, 0.97)},
        }),
    # the new server, from Germany, her features a little like Disney's Pocahontas (she isn't
    # Native). Long almond eyes lifted at the outer corners, dark and warm, with amber round the
    # pupil and the light caught in them twice; a strong level brow with a soft lift; a straight
    # nose; a full mouth the deep rose of her dress, a little higher at one corner. Her resting face
    # already knows something ("knowing", the Mona Lisa's, Khnopff's women's); sometimes she looks
    # past him at something behind him ("far"). She's funny too: she teases, sticks out her tongue,
    # rolls her eyes, winks
    'amanda': dict(
        skin='skin_olive', base=p_amanda, soft_marks=True,
        eye=dict(x=0.39, z=0.06, s=0.25, up=0.46, lo=0.24, peak=0.06, tilt=0.17, lash=0.23, lo_w=0.045, crease=0.42,
                 shadow=(104, 70, 58), shadow_a=0.5, lashes=4, lash_len=1.1, lash_w=0.42, wing=True, wing_len=0.75, wing_w=0.75,
                 iris=0.6, iris_col=(62, 40, 28), iris_ring=(214, 150, 62), catch=2),
        brow=dict(x=0.41, z=0.365, s=0.27, w=0.07, arch=0.3, angle=0.05, col=(14, 10, 10)),
        mouth=dict(z=-0.58, s=0.27, curve=0.1, crook=0.12, line_w=0.042,
                   lips=dict(col=(146, 44, 52), upper=0.07, lower=0.1)),
        expr={
            'neutral': {'eye': {'open': 0.7}},
            'knowing': {'brow': {'l': {'raise': -0.01}, 'r': {'raise': 0.03, 'arch': 0.06}}, 'eye': {'open': 0.6, 'lid_out': 0.06},
                        'mouth': {'curve': 0.32, 'crook': 0.42, 'width': 0.95}, 'gaze': (0.0, 0.0)},
            'far': {'brow': {'raise': 0.025, 'angle': 0.08}, 'eye': {'open': 0.8}, 'mouth': {'curve': 0.0, 'crook': 0.0, 'open': 0.06, 'width': 0.95},
                    'gaze': (-0.6, 0.3)},
            'smile': {'eye': {'open': 0.62}},
            'laugh': {'mouth': {'width': 1.0, 'open': 0.7}, 'head': (1.03, 0.97), 'gaze': (0, 0.3)},
            'surprised': {'mouth': {'width': 0.45}},
            'angry': {'mouth': {'curve': -0.3, 'width': 0.75}, 'eye': {'open': 0.8}},
            'disgust': {'mouth': {'shape': 'tongue', 'open': 0.0, 'curve': -0.2, 'crook': 0.2, 'teeth': False}},
            'sly': {'eye': {'open': 0.58}, 'mouth': {'curve': 0.45, 'crook': 0.7}},
            'wink': {'brow': {'l': {'raise': 0.05, 'arch': 0.1}, 'r': {'raise': -0.04}}, 'eye': {'r': {'shut': True}, 'l': {'open': 0.85}}, 'mouth': {'curve': 0.6, 'crook': 0.55},
                     'gaze': (0.0, 0.0), 'head': (1.0, 0.99)},
            'tease': {'brow': {'raise': 0.05, 'arch': 0.1}, 'eye': {'happy': True}, 'mouth': {'shape': 'tongue', 'curve': 0.3}, 'head': (1.02, 0.98)},
            'eyeroll': {'brow': {'raise': 0.07}, 'eye': {'open': 0.66}, 'mouth': {'curve': -0.1, 'crook': -0.6, 'width': 0.85}, 'gaze': (0.35, 1.0)},
        }),
}

SKIN = {'skin': (199, 163, 138), 'skin_pale': (217, 192, 174), 'skin_ruddy': (196, 146, 122), 'skin_olive': (169, 127, 88)}


# ---------------------------------------------------------------- one face

class Sheet:
    """The parts as they're drawn, kept once each however many expressions use them."""

    def __init__(self):
        self.parts = {}
        self.keys = {}

    def add(self, kind, name, key, draw):
        k = kind + ':' + json.dumps(key, sort_keys=True, default=str)
        if k in self.keys:
            return self.keys[k]
        lay = Layer()
        draw(lay)
        got = lay.cut()
        if got is None:
            self.keys[k] = None
            return None
        full = f'{kind}.{name}'
        while full in self.parts:
            full += '_'
        self.parts[full] = got
        self.keys[k] = full
        return full

    def pack(self):
        items = sorted(self.parts.items(), key=lambda kv: (-kv[1][0].height, kv[0]))
        x = y = shelf = 0
        at = {}
        for name, (im, _, _) in items:
            w, h = im.size
            if x + w > SHEET_W:
                x, y, shelf = 0, y + shelf, 0
            at[name] = (x, y)
            x += w
            shelf = max(shelf, h)
        hgt = (y + shelf + 3) // 4 * 4
        sheet = Image.new('RGBA', (SHEET_W, hgt), (0, 0, 0, 0))
        cells = {}
        for name, (im, dx, dy) in self.parts.items():
            sheet.paste(im, at[name])
            cells[name] = [at[name][0], at[name][1], im.width, im.height, dx, dy]
        return sheet, cells


def build(name, sheet_out=None):
    st = copy.deepcopy(PEOPLE[name])
    st['skin_col'] = SKIN[st['skin']]
    skin = st['skin_col']
    E, B, M = st['eye'], st['brow'], st['mouth']

    base = Layer(fill=skin)
    st['base'](base, st)

    sh = Sheet()
    exprs = {}
    names = list(EXPRESSIONS) + [k for k in st['expr'] if k not in EXPRESSIONS]
    for ex in names:
        e = merge(BASE.get(ex, BASE['neutral']), st['expr'].get(ex, {}))
        if ex not in BASE:
            e = merge(BASE['neutral'], st['expr'][ex])
        # each person's own neutral settles under all their expressions
        neutral = st['expr'].get('neutral', {})
        if ex != 'neutral':
            for part in ('eye', 'brow', 'mouth'):
                if part in neutral:
                    e[part] = merge({k: v for k, v in neutral[part].items() if k not in e.get(part, {})}, e.get(part, {}))
        el, er = sides(e.get('eye'))
        bl, br = sides(e.get('brow'))
        m = e.get('mouth', {})
        rec = {}
        if B.get('kind') == 'uni':
            rec['brow'] = [sh.add('brow', ex, ['u', bl], lambda lay, p=bl: draw_brow(lay, B, 0, p))]
        else:
            rec['brow'] = [sh.add('brow', 'l.' + ex, ['l', bl], lambda lay, p=bl: draw_brow(lay, B, -1, p)),
                           sh.add('brow', 'r.' + ex, ['r', br], lambda lay, p=br: draw_brow(lay, B, 1, p))]
        rec['white'] = [sh.add('white', 'l.' + ex, ['l', el], lambda lay, p=el: draw_white(lay, E, -1, p)),
                        sh.add('white', 'r.' + ex, ['r', er], lambda lay, p=er: draw_white(lay, E, 1, p))]
        rec['lid'] = [sh.add('lid', 'l.' + ex, ['l', el], lambda lay, p=el: draw_lids(lay, E, -1, p, skin)),
                      sh.add('lid', 'r.' + ex, ['r', er], lambda lay, p=er: draw_lids(lay, E, 1, p, skin))]
        mouths = [m] + talk_mouths(m)
        rec['mouth'] = [sh.add('mouth', ex + ('', '_a', '_b', '_c')[i], mm, lambda lay, p=mm: draw_mouth(lay, M, p, skin)) for i, mm in enumerate(mouths)]
        rec['marks'] = [sh.add('mark', mk, mk, lambda lay, k=mk: draw_mark(lay, st, k)) for mk in e.get('marks', [])]
        g = e.get('gaze', (0.0, 0.0))
        rec['gaze'] = [list(g.get('l', (0, 0))), list(g.get('r', (0, 0)))] if isinstance(g, dict) else [list(g), list(g)]
        rec['pupil'] = e.get('pupil', 'normal')
        rec['head'] = list(e.get('head', (1.0, 1.0)))
        exprs[ex] = rec
    # the blink: each eye shut, whatever else the face is doing
    shut = {'shut': True}
    blink = [sh.add('lid', 'l.shut', ['l', shut], lambda lay: draw_lids(lay, E, -1, shut, skin)),
             sh.add('lid', 'r.shut', ['r', shut], lambda lay: draw_lids(lay, E, 1, shut, skin))]
    irises = {}
    for pu in ('normal', 'small', 'big'):
        irises[pu] = sh.add('iris', pu, pu, lambda lay, k=pu: draw_iris(lay, E, k))
    sheet, cells = sh.pack()

    def px(x, z):
        a, b = P(x, z)
        return [a / SS, b / SS]
    eyes = {}
    for key, side in (('l', -1), ('r', 1)):
        eyes[key] = {'c': px(side * E['x'], E['z'] + E.get('iris_dz', 0.0)), 'range': [0.58 * E['s'] * N / 2.2, 0.32 * E['s'] * N / 2.2]}
    out = {
        'who': name, 'size': N, 'parts': cells, 'expressions': exprs, 'blink': blink, 'irises': irises,
        'iris_centre': [N / 2, N / 2], 'eyes': eyes,
        'order': ['marks', 'white', 'lid', 'brow', 'mouth'],
    }
    os.makedirs(OUT, exist_ok=True)
    face = base.im.convert('RGB').resize((N, N), Image.LANCZOS)
    face.save(os.path.join(OUT, f'{name}_face.png'), optimize=True)
    sheet.save(os.path.join(OUT, f'{name}_parts.png'), optimize=True)
    with open(os.path.join(OUT, f'{name}_face.json'), 'w') as f:
        json.dump(out, f, indent=None, separators=(',', ':'))
    print(f'{name}: {len(cells)} parts on a {sheet.width}x{sheet.height} sheet, {len(exprs)} expressions')
    if sheet_out:
        contact(name, face, sheet, out, sheet_out)


# ---------------------------------------------------------------- for looking at

def compose(face, sheet, data, ex, mouth=0, blink=False, gaze=None):
    """The face as the game lays it together (game/face.gd does the same)."""
    im = face.convert('RGBA')
    rec = data['expressions'][ex]
    cells = data['parts']

    def put(name, onto=None):
        if not name:
            return
        sx, sy, w, h, dx, dy = cells[name]
        (onto or im).alpha_composite(sheet.crop((sx, sy, sx + w, sy + h)), (dx, dy))
    for mk in rec['marks']:
        put(mk)
    lids = data['blink'] if blink else rec['lid']
    for i, key in enumerate(('l', 'r')):
        wn = None if blink else rec['white'][i]
        if not wn:
            continue
        sx, sy, w, h, dx, dy = cells[wn]
        white = sheet.crop((sx, sy, sx + w, sy + h))
        g = gaze[i] if gaze else rec['gaze'][i]
        ir = cells[data['irises'][rec['pupil']]]
        ex_, ey_ = data['eyes'][key]['c']
        rx, ry = data['eyes'][key]['range']
        cx, cy = ex_ + g[0] * rx, ey_ - g[1] * ry
        ix = int(round(cx - (data['iris_centre'][0] - ir[4]) - dx))
        iy = int(round(cy - (data['iris_centre'][1] - ir[5]) - dy))
        lay = Image.new('RGBA', white.size, (0, 0, 0, 0))
        lay.alpha_composite(sheet.crop((ir[0], ir[1], ir[0] + ir[2], ir[1] + ir[3])), (ix, iy)) if 0 <= ix and 0 <= iy else lay.paste(sheet.crop((ir[0], ir[1], ir[0] + ir[2], ir[1] + ir[3])), (ix, iy))
        mask = white.getchannel('A').point(lambda v: 255 if v > 0 else 0)
        lay.putalpha(Image.composite(lay.getchannel('A'), Image.new('L', lay.size, 0), mask))
        white.alpha_composite(lay)
        im.alpha_composite(white, (dx, dy))
    for ln in lids:
        put(ln)
    for bn in rec['brow']:
        put(bn)
    put(rec['mouth'][mouth])
    return im


def contact(name, face, sheet, data, out_dir):
    exs = list(data['expressions'])
    cols = 6
    cell = 300
    rows = (len(exs) + cols - 1) // cols
    img = Image.new('RGB', (cols * cell, rows * (cell + 24)), (240, 236, 228))
    d = ImageDraw.Draw(img)
    for i, ex in enumerate(exs):
        c = compose(face, sheet, data, ex).convert('RGB')
        c = c.crop((int(N * 0.1), int(N * 0.08), int(N * 0.9), int(N * 0.92))).resize((cell, int(cell * 0.84 / 0.8)), Image.LANCZOS)
        x, y = (i % cols) * cell, (i // cols) * (cell + 24)
        img.paste(c.crop((0, 0, cell, cell)), (x, y))
        d.text((x + 6, y + cell + 4), ex, fill=(20, 20, 20))
    os.makedirs(out_dir, exist_ok=True)
    img.save(os.path.join(out_dir, f'faces_{name}.png'))
    # and talking
    talk = Image.new('RGB', (5 * cell, cell), (240, 236, 228))
    for i, (mo, bl) in enumerate([(0, False), (1, False), (2, False), (3, False), (0, True)]):
        c = compose(face, sheet, data, 'neutral', mo, bl).convert('RGB')
        c = c.crop((int(N * 0.1), int(N * 0.08), int(N * 0.9), int(N * 0.92))).resize((cell, int(cell * 0.84 / 0.8)), Image.LANCZOS)
        talk.paste(c.crop((0, 0, cell, cell)), (i * cell, 0))
    talk.save(os.path.join(out_dir, f'faces_{name}_talk.png'))


if __name__ == '__main__':
    args = sys.argv[1:]
    out_dir = None
    if '--sheet' in args:
        out_dir = args[args.index('--out') + 1] if '--out' in args else '/tmp'
    who = [a for i, a in enumerate(args) if not a.startswith('-') and (i == 0 or args[i - 1] != '--out')] or list(PEOPLE)
    for n in who:
        build(n, out_dir)
