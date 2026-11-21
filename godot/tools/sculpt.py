"""Sculpted heads (round five, PROPOSED, after Hutch on 20 November 2026: "far from a final form ...
the game will benefit from more detail and the right amount of realism all around").

A head here is sculpted in code. It's one signed distance field: skull, brow, sockets, cheekbones,
nose, lips, jaw and ears, each a soft solid laid into or carved out of the rest with a smooth
blend, the way clay is pressed on and cut away. The field is turned into a mesh (marching cubes),
and the face moves by shapes made from that mesh: lids closing over real eyeballs, brows lifting
and knitting, the cheeks rising into a smile, the jaw dropping. The eyes are their own balls, so
the game can turn them to look at someone.

Everything is in metres, the head's middle at the origin, x to the person's left, f forward, z up
(Blender's -y is forward, so a point (x, f, z) is Vector((x, -f, z)) there).

  python3 tools/sculpt.py amanda --preview /abs/dir     a quick raymarched look at the field

The heads are built by tools/masks.py (a person whose spec has sculpt=...).
"""
import math
import os
import sys

import numpy as np

# ---------------------------------------------------------------- the clay


def length(v):
    return np.sqrt(np.sum(v * v, axis=-1))


def ellipsoid(p, c, r):
    q = (p - np.asarray(c)) / np.asarray(r)
    k0 = length(q)
    k1 = length(q / np.asarray(r))
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def ellipsoid_rot(p, c, r, rot):
    """An ellipsoid turned: rot is a 3x3 matrix whose rows are its own axes in the head's frame."""
    q = (p - np.asarray(c)) @ np.asarray(rot).T
    return ellipsoid(q, (0, 0, 0), r)


def cone(p, a, b, ra, rb):
    """A capsule whose radius runs from ra at a to rb at b (a round cone, near enough)."""
    a, b = np.asarray(a, float), np.asarray(b, float)
    ba = b - a
    t = np.clip(((p - a) @ ba) / (ba @ ba), 0.0, 1.0)
    return length(p - a - t[:, None] * ba) - (ra + (rb - ra) * t)


def chain(p, pts, radii):
    d = None
    for i in range(len(pts) - 1):
        e = cone(p, pts[i], pts[i + 1], radii[i], radii[i + 1])
        d = e if d is None else np.minimum(d, e)
    return d


def smin(a, b, k):
    if np.isscalar(k) and k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def carve(a, b, k):
    return smax(a, -b, k)


def rot_x(deg):
    t = math.radians(deg)
    return np.array([[1, 0, 0], [0, math.cos(t), -math.sin(t)], [0, math.sin(t), math.cos(t)]])


def rot_y(deg):
    t = math.radians(deg)
    return np.array([[math.cos(t), 0, math.sin(t)], [0, 1, 0], [-math.sin(t), 0, math.cos(t)]])


def rot_z(deg):
    t = math.radians(deg)
    return np.array([[math.cos(t), -math.sin(t), 0], [math.sin(t), math.cos(t), 0], [0, 0, 1]])


def mirror(p):
    """Both sides at once: the same feature for the left and the right."""
    q = p.copy()
    q[:, 0] = np.sqrt(q[:, 0] * q[:, 0] + 0.004 ** 2)      # a soft fold, or the middle of the face creases
    return q


# ---------------------------------------------------------------- who

# Each head: the measures that make the person (metres), read by head_field(). Real measures where
# they're a real person's; the masks' caricature where they aren't.
HEADS = {
    # Amanda: a long face, high broad cheekbones, a strong level brow, long dark eyes lifted at the
    # outer corners, a straight fine nose, a full mouth with a fuller lower lip, a defined chin
    # (Hutch: "a bit like pocahontas", "strikingly beautiful even if its in a cartoonish way"). The
    # caricature is small and the right way round for her: eyes a little bigger than life, the
    # cheekbones and the mouth a little more than life, the nose a little less
    'amanda': dict(
        skull=(0.071, 0.092, 0.088),         # half-sizes of the cranium
        crown=0.112, chin_z=-0.118,          # the top of the head, the bottom of the chin
        eye=dict(x=0.0318, f=0.070, z=0.004, r=0.0128, lid=0.0014, open=0.56, tilt=0.26, inner=1.0, outer=1.16,
                 heavy=0.0),
        brow=dict(f=0.088, z=0.026, w=0.046, r=0.0052, arch=0.003),
        cheek=dict(x=0.050, f=0.056, z=-0.012, r=(0.024, 0.020, 0.016)),
        jaw=dict(x=0.043, f=-0.002, z=-0.066, chin=(0.0, 0.076, -0.102), chin_r=(0.016, 0.015, 0.015)),
        nose=dict(root=(0.078, 0.012), tip=(0.0995, -0.026), r=(0.0046, 0.0056), tip_r=(0.0056, 0.0064, 0.0060),
                  ala=(0.0086, 0.092, -0.030), ala_r=(0.0052, 0.0064, 0.0052)),
        mouth=dict(z=-0.062, f=0.0885, w=0.0268, upper=0.0058, lower=0.0070, bow=0.0019, curve=0.012),
        ear=dict(x=0.069, f=-0.006, z=-0.004, r=(0.0075, 0.016, 0.029)),
        # what's on her skin: olive, warm at the cheeks; a mouth in dark red, plum shadow and a long
        # wing of liner, brows strong and level with a low arch, a beauty mark at her mouth's left
        # corner (round four's face, now on a face)
        paint=dict(skin='#a97f58', warm='#b5704f', flush=0.55, contour=1.0, lips='#701020', shadow='#543034', shadow_k=0.75,
                   liner='#140c0a', wing=0.008, brow='#1a1310', arch=0.001, mark=(0.031, -0.054), iris='#3a2010', iris_r=0.6),
        # her hair: black, parted in the middle and drawn back flat over the head into the braid
        hair=dict(lift=0.0055, locks=46, groove=0.0011, line=0.66),
    ),
}

# ---------------------------------------------------------------- the field


def eye_frame(H, p, side):
    """Points in one eye's own terms: u across (outward positive), v up (radians), and the
    distance from the eye's middle."""
    e = H['eye']
    c = np.array([side * e['x'], e['f'], e['z']])
    q = p - c
    out = side * q[:, 0]
    u = np.arctan2(out, q[:, 1])
    v = np.arctan2(q[:, 2], np.sqrt(out * out + q[:, 1] * q[:, 1]))
    return u, v, length(q)


def aperture(H, u, v, opening=1.0):
    """How far a direction from the eye's middle is outside its opening, in radians (negative
    inside): an almond, the outer corner lifted, the upper lid's arc fuller than the lower's."""
    e = H['eye']
    if H.get('lids'):
        top, bot = lid_line(H, u, 1), lid_line(H, u, -1)
        return np.maximum(np.maximum(v - top, bot - v), np.maximum(-e['inner'] - u, u - e['outer']))
    u0, u1 = -e['inner'], e['outer']
    t = np.clip((u - u0) / (u1 - u0), 0.0, 1.0)         # 0 the inner corner, 1 the outer
    mid = e['tilt'] * (t - 0.35)                          # the line between the corners, lifted outward
    sh = np.sin(np.pi * t)
    up = e['open'] * opening * (sh ** 0.75) * (1.0 - 0.25 * t)       # the upper lid's arc, its peak inside the middle
    lo = e['open'] * 0.62 * (sh ** 0.9) * (0.8 + 0.2 * t)            # the lower lid's, flatter
    above = v - (mid + up)
    below = (mid - lo) - v
    inside_u = np.maximum(u0 - u, u - u1)
    return np.maximum(np.maximum(above, below), inside_u)


def head_field(H, p):
    """The head's signed distance at points p (N, 3), as (x, f, z)."""
    P = mirror(p)
    sk = H['skull']
    # the cranium, and the face hung off the front of it
    d = ellipsoid(p, (0, -0.012, 0.026), sk)
    d = smin(d, ellipsoid(p, (0, 0.042, 0.048), (0.060, 0.050, 0.050)), 0.02)            # the forehead
    d = smin(d, ellipsoid(p, (0, 0.030, -0.032), (0.050, 0.052, 0.072)), 0.024)          # the midface
    d = smin(d, ellipsoid(p, (0, 0.028, -0.076), (0.040, 0.05, 0.038)), 0.026)           # the lower face
    d = smin(d, ellipsoid(p, (0, 0.072, 0.002), (0.011, 0.011, 0.018)), 0.012)              # between the eyes
    # the temples a little hollow, behind the brow's corners
    d = carve(d, ellipsoid(P, (0.075, 0.040, 0.020), (0.006, 0.016, 0.016)), 0.014)
    # the jaw: a bar from under each ear to the chin, and the chin itself
    j = H['jaw']
    cx, cf, cz = j['chin']
    d = smin(d, cone(P, (j['x'], j['f'], j['z']), (0.016, cf - 0.006, cz + 0.004), 0.010, 0.010), 0.036)
    d = smin(d, ellipsoid(p, j['chin'], j['chin_r']), 0.014)
    # the cheekbones and the arch back from each to the ear
    c = H['cheek']
    d = smin(d, ellipsoid(P, (c['x'], c['f'], c['z']), c['r']), 0.02)
    d = smin(d, cone(P, (c['x'] + 0.006, c['f'] - 0.012, c['z'] + 0.002), (0.064, 0.0, 0.0), 0.007, 0.005), 0.018)
    d = smin(d, ellipsoid(P, (0.040, 0.052, -0.040), (0.020, 0.022, 0.022)), 0.02)          # the cheeks' flesh
    d = smin(d, ellipsoid(P, (0.033, 0.070, -0.028), (0.017, 0.013, 0.014)), 0.016)         # the apples of the cheeks
    # under the cheekbone, the face falls in a little toward the mouth
    d = smin(d, ellipsoid(P, (0.040, 0.024, -0.042), (0.019, 0.044, 0.042)), 0.024)            # the side of the face
    # the muzzle the mouth sits on
    m = H['mouth']
    d = smin(d, ellipsoid(p, (0, 0.060, m['z'] + 0.002), (0.028, 0.024, 0.018)), 0.014)
    # the brow: a ridge over each eye, and the sockets under it
    b = H['brow']
    d = smin(d, cone(P, (-0.006, b['f'], b['z'] - 0.002), (b['w'], b['f'] - 0.016, b['z'] + b['arch']), b['r'], b['r'] * 0.8), 0.016)
    e = H['eye']
    d = carve(d, ellipsoid(P, (e['x'] + 0.001, e['f'] + 0.014, e['z'] + 0.004), (0.016, 0.006, 0.010)), 0.01)
    # the lids: a skin over the eyeball, slit open
    ec = np.array([e['x'], e['f'], e['z']])
    rl = e['r'] + e['lid']
    d = smin(d, length(P - ec) - rl, 0.005)
    # heavy upper lids: the skin above the lid's fold sits out over it
    d = smin(d, ellipsoid(P, (e['x'] + 0.002, e['f'] + 0.008, e['z'] + 0.0105), (0.0135, 0.0055, 0.0045)), 0.004 * (1 + e['heavy']))
    for side in (-1, 1):
        u, v, r = eye_frame(H, p, side)
        a = aperture(H, u, v) * rl
        cut = np.maximum(a, r - (rl + 0.0035))
        mask = (side * p[:, 0]) > 0
        d = np.where(mask, carve(d, cut, 0.0012), d)
    # the nose: a bridge down from between the eyes, a tip, the wings, the nostrils under them
    n = H['nose']
    nose = cone(p, (0, n['root'][0], n['root'][1]), (0, n['tip'][0] - 0.004, n['tip'][1] + 0.004), n['r'][0], n['r'][1])
    nose = smin(nose, ellipsoid(p, (0, n['tip'][0], n['tip'][1]), n['tip_r']), 0.005)
    ax, af, az = n['ala']
    nose = smin(nose, ellipsoid(P, (ax, af, az), n['ala_r']), 0.007)
    d = smin(d, nose, 0.012)
    d = carve(d, ellipsoid(P, (ax * 0.55, af + 0.006, az - 0.005), (0.0032, 0.0048, 0.0024)), 0.0015)
    # the lips: the upper along a cupid's bow, the lower fuller, the line between them cut in,
    # and a mouth behind them (so the jaw can open)
    xs = np.linspace(-m['w'], m['w'], 13)
    def lip(z0, f0, rr, bow):
        pts, radii = [], []
        for x in xs:
            t = x / m['w']
            pts.append((x, f0 - m.get('curve', 0.016) * t * t - 0.004 * t ** 4, z0 + bow * (math.exp(-((abs(t) - 0.22) / 0.16) ** 2) - 0.5 * math.exp(-(t / 0.08) ** 2))
                        + 0.001 * t * t))
            radii.append(rr * (1.0 - t * t) ** 0.6 + 0.0005)
        return chain(p, pts, radii)
    n0 = H['nose']
    for sx in (-1, 1):
        d = smin(d, cone(p, (sx * 0.0035, n0['ala'][1] - 0.004, n0['ala'][2] - 0.008), (sx * 0.0052, m['f'] - 0.0035, m['z'] + 0.0085),
                         0.0011, 0.0013), 0.006)
    up = lip(m['z'] + 0.0042, m['f'] - 0.0035, m['upper'], m['bow'])
    lo = lip(m['z'] - 0.0058, m['f'] - 0.0055, m['lower'], 0.0)
    # the corners of the mouth melt into the cheeks; the middle of the lips stands proud
    xc = np.clip(np.abs(p[:, 0]) / m['w'], 0.0, 1.0)
    d = smin(d, smin(up, lo, 0.0025), 0.0075 + 0.007 * xc ** 3)
    xw = np.clip(np.abs(p[:, 0]) / m['w'], 0.0, 1.0)
    slit = np.maximum(np.abs(p[:, 2] - (m['z'] - 0.0004 * xw ** 2)) - 0.0006 * (1.0 - xw ** 3) + 0.0002 * xw ** 3,
                      np.maximum(np.abs(p[:, 0]) - m['w'] * 0.98, m['f'] - 0.022 - p[:, 1]))
    d = carve(d, slit, 0.0008)
    d = carve(d, ellipsoid(p, (0, m['f'] - 0.022, m['z']), (m['w'] * 0.85, 0.01, 0.006)), 0.002)
    # the ears, tilted back, a bowl cut into each
    er = H['ear']
    ear = ellipsoid_rot(P, (er['x'], er['f'], er['z']), er['r'], rot_x(-14) @ rot_z(-12))
    ear = carve(ear, ellipsoid_rot(P, (er['x'] + 0.0065, er['f'] + 0.003, er['z'] - 0.003), (0.0045, 0.0085, 0.013), rot_x(-14)), 0.003)
    d = smin(d, ear, 0.005)
    # the neck, down into the body's
    d = smin(d, cone(p, (0, -0.008, -0.04), (0, -0.040, -0.165), 0.046, 0.051), 0.02)
    return d


def eyeballs(H):
    e = H['eye']
    return [((s * e['x'], e['f'], e['z']), e['r']) for s in (1, -1)]


# ---------------------------------------------------------------- the mesh


def sample(field, lo, hi, step, band=0.004, coarse=4):
    """The field on a grid, exactly near the surface and roughly far from it: a coarse grid first,
    then only the fine points within `band` of the surface worked out exactly."""
    from scipy.ndimage import zoom
    lo, hi = np.asarray(lo, float), np.asarray(hi, float)
    n = np.ceil((hi - lo) / step).astype(int) + 1
    cs = step * coarse
    nc = np.ceil((hi - lo) / cs).astype(int) + 2
    g = np.stack(np.meshgrid(*[lo[i] + np.arange(nc[i]) * cs for i in range(3)], indexing='ij'), -1).reshape(-1, 3)
    dc = np.concatenate([field(g[i:i + 400000]) for i in range(0, len(g), 400000)]).reshape(nc)
    d = zoom(dc, coarse, order=1)[:n[0], :n[1], :n[2]].astype(np.float32)
    near = np.argwhere(np.abs(d) < band + cs)
    pts = lo + near * step
    exact = np.concatenate([field(pts[i:i + 400000]) for i in range(0, len(pts), 400000)])
    d[near[:, 0], near[:, 1], near[:, 2]] = exact
    return d


def mesh(field, lo, hi, step):
    """The surface where the field is 0, as vertices (x, f, z) and triangles, outward facing."""
    from skimage.measure import marching_cubes
    d = sample(field, lo, hi, step)
    v, f, _, _ = marching_cubes(d, 0.0, spacing=(step, step, step))
    v += np.asarray(lo)
    return v, f[:, ::-1]


def head_mesh(H, step=0.0007):
    lo = (-0.09, -0.125, H['chin_z'] - 0.06)
    hi = (0.09, 0.13, H['crown'] + 0.006)
    return mesh(lambda q: head_field(H, q), lo, hi, step)


# ---------------------------------------------------------------- the face moving

# The shapes the face makes, each a field of movement over the sculpt's vertices: the game mixes
# them (game/face.gd), and an expression is a mix. Per side where a face is seldom even.


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def gauss(p, c, r):
    q = (p - np.asarray(c)) / np.asarray(r)
    return np.exp(-np.sum(q * q, axis=-1))


def from_eye(H, side, u, v, r):
    e = H['eye']
    c = np.array([side * e['x'], e['f'], e['z']])
    horiz = r * np.cos(v)
    return np.stack([c[0] + side * horiz * np.sin(u), c[1] + horiz * np.cos(u), c[2] + r * np.sin(v)], 1)


def lid_line(H, u, which):
    """The upper (which=1) or lower (-1) lid's margin, as a height (radians) at u."""
    e = H['eye']
    if H.get('lids'):
        # measured off a modelled head (tools/human.py): the margins as tables over u
        ug, top, bot = H['lids']
        return np.interp(u, ug, top if which > 0 else bot)
    u0, u1 = -e['inner'], e['outer']
    t = np.clip((u - u0) / (u1 - u0), 0.0, 1.0)
    mid = e['tilt'] * (t - 0.35)
    sh = np.sin(np.pi * t)
    if which > 0:
        return mid + e['open'] * (sh ** 0.75) * (1.0 - 0.25 * t)
    return mid - e['open'] * 0.62 * (sh ** 0.9) * (0.8 + 0.2 * t)


def shapes(H, V):
    """{name: displaced vertices} for the sculpt's vertices V (x, f, z)."""
    e, m, b = H['eye'], H['mouth'], H['brow']
    out = {}
    rl = e['r'] + e['lid']
    for side, tag in ((1, 'l'), (-1, 'r')):
        u, v, r = eye_frame(H, V, side)
        mine = (side * V[:, 0]) > 0.004
        near = mine & (r < rl + 0.012) & (u > -e['inner'] - 0.35) & (u < e['outer'] + 0.35)
        top, bot = lid_line(H, u, 1), lid_line(H, u, -1)
        # the upper lid down over the eye to meet the lower, the skin above following less and less
        meet = bot + 0.25 * (top - bot)
        above = v - top
        w = np.where(near & (v > meet - 0.02), np.exp(-np.maximum(above, 0.0) / 0.22), 0.0)
        w *= smoothstep(rl + 0.012, rl + 0.004, r) * (1.0 - smoothstep(e['outer'] + 0.1, e['outer'] + 0.35, u)) \
            * (1.0 - smoothstep(e['inner'] + 0.1, e['inner'] + 0.35, -u))
        nv = v - w * (top - meet)
        nr = r + w * 0.0011 * np.sin(np.clip((v - meet) / max(e['open'], 1e-3), 0, 1) * np.pi)
        X = V.copy()
        X[near] = from_eye(H, side, u[near], nv[near], nr[near])
        out[f'blink_{tag}'] = X
        # the lower lid up (a squint, the cheeks pushing it in a real smile)
        wl = np.where(near & (v < meet + 0.02), np.exp(-np.maximum(bot - v, 0.0) / 0.18), 0.0)
        wl *= smoothstep(rl + 0.012, rl + 0.004, r)
        nv = v + wl * 0.45 * (meet - bot)
        X = V.copy()
        X[near] = from_eye(H, side, u[near], nv[near], r[near])
        out[f'squint_{tag}'] = X
        # the brow: up (all of it), its inner end up (grief, worry), down and in (anger, focus)
        bc = np.array([side * b['w'] * 0.55, b['f'] - 0.004, b['z'] + 0.004])
        wb = gauss(V, bc, (0.03, 0.03, 0.022)) * mine * smoothstep(e['z'] - 0.002, e['z'] + 0.014, V[:, 2])
        X = V.copy()
        X[:, 2] += 0.0075 * wb
        out[f'brow_up_{tag}'] = X
        wi = gauss(V, (side * 0.012, b['f'], b['z'] + 0.002), (0.016, 0.03, 0.02)) * mine * smoothstep(e['z'] - 0.002, e['z'] + 0.012, V[:, 2])
        X = V.copy()
        X[:, 2] += 0.005 * wi
        out[f'brow_in_{tag}'] = X
        wd = gauss(V, (side * 0.016, b['f'], b['z']), (0.022, 0.03, 0.018)) * mine * smoothstep(e['z'] - 0.002, e['z'] + 0.012, V[:, 2])
        X = V.copy()
        X[:, 2] -= 0.0045 * wd
        X[:, 0] -= side * 0.003 * wd
        X[:, 1] += 0.0015 * wd
        out[f'brow_down_{tag}'] = X
        # a smile: the corner of the mouth up and back, the cheek rising round it
        corner = np.array([side * m['w'], m['f'] - 0.012, m['z']])
        wc = gauss(V, corner, (0.016, 0.02, 0.012)) * mine
        wk = gauss(V, (side * 0.034, 0.07, -0.03), (0.02, 0.03, 0.018)) * mine
        X = V.copy()
        X[:, 2] += 0.0065 * wc + 0.0032 * wk
        X[:, 0] += side * 0.0045 * wc
        X[:, 1] -= 0.0025 * wc
        X[:, 1] += 0.0018 * wk
        out[f'smile_{tag}'] = X
        X = V.copy()
        X[:, 2] -= 0.0045 * wc
        X[:, 1] -= 0.001 * wc
        out[f'frown_{tag}'] = X
        # the upper lip lifted on one side (a sneer)
        ws = gauss(V, (side * 0.012, m['f'], m['z'] + 0.006), (0.01, 0.02, 0.006)) * mine
        X = V.copy()
        X[:, 2] += 0.003 * ws
        X[:, 1] += 0.0008 * ws
        out[f'sneer_{tag}'] = X
    # the jaw: everything under the line of the lips turned down about a hinge in front of the ears
    hinge = np.array([0.0, -0.004, -0.018])
    below = smoothstep(m['z'] + 0.0005, m['z'] - 0.0035, V[:, 2] + 0.0006 * (V[:, 0] / m['w']) ** 2)
    if H.get('lip_line') is not None:
        # a modelled head's lips meet along a line, sealed by the mouth's inside behind them:
        # torn open there, everything under the line going with the jaw and nothing above it
        L = H['lip_line']
        zs = np.interp(np.abs(V[:, 0]), L[:, 0], L[:, 1])
        sharp = smoothstep(zs + 0.0002, zs - 0.0004, V[:, 2])
        lips = 1.0 - smoothstep(L[-1, 0] - 0.002, L[-1, 0] + 0.006, np.abs(V[:, 0]))
        below = lips * sharp + (1.0 - lips) * below
    front = smoothstep(-0.01, 0.03, V[:, 1])
    wj = below * front * (1.0 - smoothstep(H['chin_z'] + 0.006, H['chin_z'] - 0.018, V[:, 2]))
    wj *= 1.0 - smoothstep(0.045, 0.07, np.abs(V[:, 0]))
    a = math.radians(14.0)
    q = V - hinge
    X = V.copy()
    ca, sa = np.cos(a * wj), np.sin(a * wj)
    X[:, 1] = hinge[1] + q[:, 1] * ca + q[:, 2] * sa
    X[:, 2] = hinge[2] - q[:, 1] * sa + q[:, 2] * ca
    out['jaw'] = X
    # the lips pushed forward and gathered into an O
    wp = gauss(V, (0, m['f'], m['z']), (m['w'] * 1.2, 0.02, 0.014))
    X = V.copy()
    X[:, 0] *= 1.0 - 0.32 * wp
    X[:, 1] += 0.004 * wp
    out['pucker'] = X
    # the lips pressed thin
    wt = gauss(V, (0, m['f'], m['z']), (m['w'] * 1.1, 0.02, 0.01))
    X = V.copy()
    X[:, 2] = m['z'] + (V[:, 2] - m['z']) * (1.0 - 0.45 * wt)
    X[:, 1] -= 0.0015 * wt
    out['press'] = X
    return out


# ---------------------------------------------------------------- the picture on the skin

# The skin's picture wraps round the head: across, by the angle round the head's upright axis
# (squeezed toward the back, so the face gets the most of it); up, by height.


def uv_of(H, V):
    th = np.arctan2(V[:, 0], V[:, 1])
    u = 0.5 + 0.5 * np.sin(th / 2.0)
    z0, z1 = H['chin_z'] - 0.06, H['crown'] + 0.006
    return np.stack([u, (V[:, 2] - z0) / (z1 - z0)], 1)


def texel_points(H, size):
    """Where on the head each texel of the skin's picture lies: rays in from outside toward the
    upright axis, each stopped where it first meets the head."""
    if H.get('surface'):
        return H['surface'].texels(H, size)
    n = size
    u = (np.arange(n) + 0.5) / n
    v = 1.0 - (np.arange(n) + 0.5) / n
    U, Vv = np.meshgrid(u, v)
    th = 2.0 * np.arcsin(np.clip(2.0 * U - 1.0, -1, 1))
    z0, z1 = H['chin_z'] - 0.06, H['crown'] + 0.006
    z = z0 + Vv * (z1 - z0)
    d = np.stack([np.sin(th), np.cos(th), np.zeros_like(th)], -1).reshape(-1, 3)
    o = d * 0.15
    o[:, 2] = z.ravel()
    t = np.zeros(len(o))
    alive = np.ones(len(o), bool)
    for _ in range(80):
        idx = np.where(alive)[0]
        if len(idx) == 0:
            break
        q = o[idx] - d[idx] * t[idx, None]
        dd = head_field(H, q)
        t[idx] += np.maximum(dd * 0.9, 0.00008)
        stop = (dd < 0.00015) | (t[idx] > 0.15)
        alive[idx[stop]] = False
    return (o - d * t[:, None]).reshape(n, n, 3)


def noise(P, scale, seed=0):
    """A soft value noise in space, -1..1."""
    rng = np.random.default_rng(seed)
    g = rng.uniform(-1, 1, (64, 64, 64))
    q = P / scale
    i = np.floor(q).astype(int)
    f = q - i
    f = f * f * (3 - 2 * f)
    def at(a, b, c):
        return g[(i[..., 0] + a) % 64, (i[..., 1] + b) % 64, (i[..., 2] + c) % 64]
    x00 = at(0, 0, 0) * (1 - f[..., 0]) + at(1, 0, 0) * f[..., 0]
    x10 = at(0, 1, 0) * (1 - f[..., 0]) + at(1, 1, 0) * f[..., 0]
    x01 = at(0, 0, 1) * (1 - f[..., 0]) + at(1, 0, 1) * f[..., 0]
    x11 = at(0, 1, 1) * (1 - f[..., 0]) + at(1, 1, 1) * f[..., 0]
    y0 = x00 * (1 - f[..., 1]) + x10 * f[..., 1]
    y1 = x01 * (1 - f[..., 1]) + x11 * f[..., 1]
    return y0 * (1 - f[..., 2]) + y1 * f[..., 2]


def hexc(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def lay(col, c, a):
    a = np.clip(a, 0, 1)[..., None]
    return col * (1 - a) + np.asarray(c) * a


def curve_dist(P, pts):
    """Distance from each point to a polyline, and how far along it (0..1) the nearest point is."""
    pts = np.asarray(pts, float)
    best = np.full(P.shape[:-1], 1e9)
    along = np.zeros(P.shape[:-1])
    seg = np.linalg.norm(np.diff(pts, axis=0), axis=1)
    acc = np.concatenate([[0], np.cumsum(seg)])
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        ab = b - a
        t = np.clip(((P - a) @ ab) / (ab @ ab), 0, 1)
        dd = np.linalg.norm(P - a - t[..., None] * ab, axis=-1)
        closer = dd < best
        best = np.where(closer, dd, best)
        along = np.where(closer, (acc[i] + t * seg[i]) / acc[-1], along)
    return best, along


def on_face(H, x, z, f0=0.12):
    """The point on the face straight in front of (x, z)."""
    if H.get('surface'):
        return H['surface'].on_face(x, z)
    o = np.array([[x, f0, z]])
    t = 0.0
    for _ in range(80):
        dd = head_field(H, o - np.array([[0, t, 0]]))[0]
        if dd < 0.0001:
            break
        t += max(dd * 0.9, 0.00005)
    return np.array([x, f0 - t, z])


def paint(H, size=2048):
    """The skin's picture: the skin's own colour and its warmth, then what's put on it."""
    P = texel_points(H, size // 2)
    P = P.repeat(2, axis=0).repeat(2, axis=1)
    pk = H['paint']
    skin = hexc(pk['skin'])
    col = np.broadcast_to(skin, P.shape).copy()
    # the skin's mottle, and its warmth where the blood's near the surface: the cheeks, the nose,
    # the ears, the chin; cooler and a little darker under the jaw and round the eyes
    col *= (1.0 + 0.035 * noise(P, 0.012, 1) + 0.02 * noise(P, 0.004, 2))[..., None]
    # pores and the skin's fine grain, more over the nose and the cheeks
    pores = np.clip(noise(P, 0.0006, 11) * 1.6, -1, 0) * (0.5 + 0.5 * gauss(np.abs(P) * [1, 1, 1], (0.02, 0.09, -0.03), (0.03, 0.03, 0.03)))
    col *= (1.0 + 0.05 * pores + 0.012 * noise(P, 0.0015, 12))[..., None]
    warm = hexc(pk['warm'])
    e, m, b = H['eye'], H['mouth'], H['brow']
    mp = P.copy()
    mp[..., 0] = np.abs(mp[..., 0])
    flush = 0.5 * gauss(mp, (0.04, 0.07, -0.026), (0.022, 0.03, 0.018)) + 0.35 * gauss(mp, (0.0, 0.1, -0.03), (0.012, 0.02, 0.012)) \
        + 0.3 * gauss(mp, (0.07, 0.0, -0.01), (0.012, 0.03, 0.03)) + 0.2 * gauss(mp, (0, 0.08, -0.1), (0.015, 0.02, 0.012))
    col = lay(col, warm, flush * pk.get('flush', 1.0))
    shade = 0.10 * gauss(mp, (0.03, 0.075, -0.012), (0.016, 0.02, 0.006)) + 0.08 * smoothstep(-0.11, -0.13, P[..., 2]) \
        + 0.10 * gauss(mp, (0.05, 0.05, -0.05), (0.012, 0.03, 0.016)) * pk.get('contour', 1.0)
    # the folds a face lives in: from the nose's wings down past the mouth, under the eyes, the
    # little hollow under the lower lip
    n_ = H['nose']
    fold, fa = curve_dist(mp, [(n_['ala'][0] + 0.006, n_['ala'][1] - 0.004, n_['ala'][2] + 0.002), (0.024, 0.080, -0.052),
                               (H['mouth']['w'] + 0.004, 0.078, -0.07)])
    shade = shade + 0.09 * smoothstep(0.004, 0.0, fold) * (1 - fa * 0.5) * pk.get('folds', 1.0)
    shade = shade + 0.07 * gauss(mp, (0.03, 0.078, -0.012), (0.012, 0.012, 0.004))
    shade = shade + 0.08 * gauss(mp, (0.0, 0.085, H['mouth']['z'] - 0.016), (0.012, 0.012, 0.004))
    col *= (1.0 - shade)[..., None]
    # the lips, the line between them darkest, a light on the lower
    up = [(x, m['f'] - 0.0035 - m.get('curve', 0.016) * (x / m['w']) ** 2, m['z'] + 0.0042 + m['bow'] * (math.exp(-((abs(x / m['w']) - 0.22) / 0.16) ** 2)
           - 0.5 * math.exp(-(x / m['w'] / 0.08) ** 2))) for x in np.linspace(-m['w'], m['w'], 25)]
    lo = [(x, m['f'] - 0.0055 - m.get('curve', 0.016) * (x / m['w']) ** 2, m['z'] - 0.0058) for x in np.linspace(-m['w'], m['w'], 25)]
    Pl = P
    if H.get('surface'):
        # on a modelled head the lips are where they are: their outline is drawn across the face,
        # not round a tube of our own
        Pl = P.copy()
        Pl[..., 1] = m['f'] - 0.0035 - m.get('curve', 0.016) * (np.clip(P[..., 0] / m['w'], -1.2, 1.2)) ** 2
    du, au = curve_dist(Pl, up)
    dl, al = curve_dist(Pl, lo)
    ru = m['upper'] * (1 - (2 * au - 1) ** 2) ** 0.6 + 0.0014
    rlw = m['lower'] * (1 - (2 * al - 1) ** 2) ** 0.6 + 0.0014
    front = smoothstep(0.06, 0.075, P[..., 1])
    lips = np.maximum(smoothstep(ru + 0.0009, ru + 0.0001, du), smoothstep(rlw + 0.0009, rlw + 0.0001, dl)) * front
    if H.get('lip_line') is not None:
        # measured off a modelled head: between the borders, across to the corners
        L = H['lip_line']
        ax = np.abs(P[..., 0])
        zt, zb = np.interp(ax, L[:, 0], L[:, 2]), np.interp(ax, L[:, 0], L[:, 3])
        lips = smoothstep(zt + 0.0004, zt - 0.0002, P[..., 2]) * smoothstep(zb - 0.0004, zb + 0.0002, P[..., 2]) \
            * smoothstep(L[-1, 0] + 0.0005, L[-1, 0] - 0.001, ax) * front
    lipc = hexc(pk['lips'])
    col = lay(col, lipc, lips * 0.92)
    col = lay(col, lipc * 0.45, lips * smoothstep(0.0022, 0.0, np.abs(P[..., 2] - m['z'])) * 0.8)
    col = lay(col, np.minimum(lipc * 1.5, 1), lips * gauss(P, (0.004, m['f'], m['z'] - 0.006), (0.008, 0.02, 0.0018)) * 0.5)
    # inside the nostrils
    n = H['nose']
    if not H.get('surface'):
        col = lay(col, skin * 0.25, gauss(mp, (n['ala'][0] * 0.55, n['ala'][1] + 0.004, n['ala'][2] - 0.006), (0.0028, 0.006, 0.0018)))
    for side in (1, -1):
        mine = (side * P[..., 0]) > 0.003
        u, v, r = eye_frame(H, P.reshape(-1, 3), side)
        u, v, r = u.reshape(P.shape[:-1]), v.reshape(P.shape[:-1]), r.reshape(P.shape[:-1])
        near = mine & (r < e['r'] + e['lid'] + 0.02) & (r > e['r'] + 0.0004)
        top, bot = lid_line(H, u, 1), lid_line(H, u, -1)
        t = (u + e['inner']) / (e['inner'] + e['outer'])
        # shadow on the lid up to the fold, deepest at the outer corner, plum
        shadow = near * smoothstep(0.62, 0.05, v - top) * (v > top - 0.02) * smoothstep(-0.2, 0.4, t) \
            * (1 - smoothstep(1.0, 1.35, t)) * (0.55 + 0.45 * smoothstep(0.3, 1.0, t))
        col = lay(col, hexc(pk['shadow']), shadow * pk.get('shadow_k', 0.8))
        # the line along the upper lashes, thickening outward into a wing past the corner
        thick = 0.09 + 0.13 * smoothstep(0.2, 1.0, t)
        opening = aperture(H, u, v) < 0.005
        liner = near * (v > top - 0.03) * smoothstep(thick + 0.03, thick - 0.01, v - top) * (t > 0.04) * (t < 1.0) * ~opening
        # the wing: a tapering stroke out and up from the outer corner
        cx = np.array([side * e['x'], e['f'], e['z']])
        corner = from_eye(H, side, np.array([e['outer']]), np.array([lid_line(H, np.array([e['outer']]), 1)[0]]), np.array([e['r'] + e['lid']]))[0]
        tip = corner + np.array([side * pk.get('wing', 0.007), -0.004, 0.0045])
        dw, aw = curve_dist(P, [corner - np.array([side * 0.002, -0.0008, 0.0003]), tip])
        wing = smoothstep(0.0016 * (1 - aw) + 0.0003, 0.0001, dw) * mine
        col = lay(col, hexc(pk['liner']), np.maximum(liner, wing))
        # the lower lashes, smudged, in the outer half
        low = near * smoothstep(0.08, 0.0, np.abs(v - bot + 0.02)) * smoothstep(0.35, 0.9, t) * (t < 1.02) * ~opening
        col = lay(col, hexc(pk['liner']), low * 0.6)
        # the wet rim of the lower lid
        rim = near * smoothstep(0.025, 0.0, np.abs(v - bot - 0.012)) * ~opening * (t > 0.08) * (t < 0.95)
        col = lay(col, hexc('#c48a7c'), rim * 0.7)
        # inside the lids, where the eyeball doesn't reach (the corners): wet pink skin, not ink
        inner = mine & (r < e['r'] + e['lid'] + 0.004) & opening
        col = np.where(inner[..., None], hexc('#b07468') * 0.9, col)
        # the brow: hairs laid at a slant along a curve over the eye, thick at the inner end
        bx = [0.013, 0.024, 0.036, 0.046, 0.052]
        bz = [b['z'] - 0.004, b['z'] + 0.0005, b['z'] + 0.003 + pk.get('arch', 0.0), b['z'] + 0.001, b['z'] - 0.004]
        bp = [on_face(H, side * x, zz) + np.array([0, 0.001, 0]) for x, zz in zip(bx, bz)]
        db, ab = curve_dist(P, bp)
        bw = 0.0036 * (1 - 0.72 * ab) + 0.0007
        hairs = 0.75 + 0.25 * np.sin((P[..., 0] * side * 3800 + P[..., 2] * 5200) + 4 * noise(P, 0.0012, 7))
        edge = smoothstep(bw * 1.1, bw * 0.35, db + 0.0004 * noise(P, 0.0008, 8))
        brow = edge * mine * np.clip(hairs + 0.5 * smoothstep(bw * 0.8, 0.0, db), 0, 1)
        col = lay(col, hexc(pk['brow']), brow * 0.95)
    # the hairline isn't a hard edge: fine short hairs and the dark of the roots under the skin,
    # thinning out over a few millimetres below where the hair starts
    if H.get('surface') and H.get('hair'):
        hp = H['hair']
        c = P - np.array([0.0, -0.01, 0.0])
        n = c / np.maximum(np.linalg.norm(c, axis=-1, keepdims=True), 1e-9)
        x, f, z = n[..., 0], n[..., 1], n[..., 2]
        line = hp['line'] + 0.05 * np.exp(-(x / 0.1) ** 2) - 0.4 * x * x
        below = line - z
        fine = 0.6 + 0.4 * np.sin(x * 900 + 3 * noise(P, 0.001, 21))
        band = smoothstep(0.045, 0.0, below) * (below > -0.01) * (f > 0.1) * fine
        col = lay(col, hexc(pk['brow']) * 1.4, np.clip(band, 0, 1) * 0.55)
    # a beauty mark
    if pk.get('mark'):
        mx, mz = pk['mark']
        q = on_face(H, mx, mz)
        col = lay(col, hexc(pk['liner']) * 1.3, smoothstep(0.0011, 0.0006, np.linalg.norm(P - q, axis=-1)))
    from PIL import Image
    return Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))


def eye_picture(H, size=512):
    """An eyeball's picture, seen from the front: the white, a little warm at its edges, the iris
    in fibres round a dark ring, the pupil."""
    pk = H['paint']
    ys, xs = np.mgrid[0:size, 0:size]
    x = (xs + 0.5) / size * 2 - 1
    y = 1 - (ys + 0.5) / size * 2
    r = np.sqrt(x * x + y * y)
    a = np.arctan2(y, x)
    col = np.broadcast_to(hexc('#e9e2d6'), (size, size, 3)).copy()
    col = lay(col, hexc('#c98c80'), smoothstep(0.55, 1.0, r) * 0.5)
    ir = pk.get('iris_r', 0.48)
    iris = hexc(pk['iris'])
    fib = 0.75 + 0.25 * np.sin(a * 70 + 4 * np.sin(a * 13)) * (0.6 + 0.4 * np.sin(r * 40))
    ic = iris[None, None, :] * (0.65 + 0.6 * smoothstep(ir, 0.1, r))[..., None] * fib[..., None]
    col = np.where((r < ir)[..., None], ic, col)
    col = lay(col, iris * 0.25, smoothstep(ir - 0.08, ir, r) * (r < ir + 0.01))
    col = lay(col, hexc('#0b0807'), smoothstep(ir * 0.42, ir * 0.36, r))
    # the light caught on the wet of the eye, up and to one side of the pupil
    col = lay(col, hexc('#fbf6ee'), smoothstep(0.075, 0.045, np.hypot(x + 0.16, y - 0.18)))
    col = lay(col, hexc('#fbf6ee'), smoothstep(0.03, 0.015, np.hypot(x - 0.12, y + 0.14)) * 0.6)
    from PIL import Image
    return Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))


def normal_at(H, q):
    q = np.atleast_2d(np.asarray(q, float))
    if H.get('surface'):
        return np.array([H['surface'].normal(p) for p in q])
    e = 0.0003
    g = np.stack([head_field(H, q + [e, 0, 0]) - head_field(H, q - [e, 0, 0]),
                  head_field(H, q + [0, e, 0]) - head_field(H, q - [0, e, 0]),
                  head_field(H, q + [0, 0, e]) - head_field(H, q - [0, 0, e])], 1)
    return g / np.maximum(length(g)[:, None], 1e-9)


def brow_curve(H, side):
    b, pk = H['brow'], H['paint']
    bx = [0.013, 0.024, 0.036, 0.046, 0.052]
    bz = [b['z'] - 0.004, b['z'] + 0.0005, b['z'] + 0.003 + pk.get('arch', 0.0), b['z'] + 0.001, b['z'] - 0.004]
    return bx, bz


def hairs(H, seed=3):
    """The brows and the upper lashes as hairs: (points, radii) for each, a short tapering tube.
    The brows lie along the skin, the inner hairs rising, the rest combed outward; the lashes
    spring from the lid's edge, out and up, longest at the outer corner."""
    rng = np.random.default_rng(seed)
    e, pk = H['eye'], H['paint']
    out = []
    for side in (1, -1):
        bx, bz = brow_curve(H, side)
        for i in range(pk.get('brow_hairs', 90)):
            t = rng.uniform(0, 1) ** 1.3
            x = np.interp(t, np.linspace(0, 1, len(bx)), bx)
            zc = np.interp(t, np.linspace(0, 1, len(bz)), bz)
            w = 0.0036 * (1 - 0.72 * t) + 0.0007
            z = zc + rng.uniform(-0.5, 0.5) * w
            ang = np.radians(np.interp(t, [0, 0.18, 0.5, 1.0], [80, 40, 12, -18]) + rng.normal(0, 8))
            ln = rng.uniform(0.0035, 0.006) * (1.0 if t > 0.15 else 0.75)
            pts = []
            for k in range(3):
                s = ln * k / 2
                xx = side * (x + s * np.cos(ang))
                zz = z + s * np.sin(ang)
                p = on_face(H, xx, zz)
                pts.append(p + normal_at(H, p)[0] * (0.0003 + 0.0002 * k))
            out.append((pts, [0.00042, 0.0003, 0.0001]))
        rl = e['r'] + e['lid']
        for i in range(pk.get('lashes', 46)):
            t = 0.08 + 0.92 * (i + rng.uniform(0, 0.8)) / pk.get('lashes', 46)
            u = -e['inner'] * 0.85 + t * (e['outer'] * 0.98 + e['inner'] * 0.85)
            v = lid_line(H, np.array([u]), 1)[0]
            base = from_eye(H, side, np.array([u]), np.array([v + 0.02]), np.array([rl + 0.0003]))[0]
            c = np.array([side * e['x'], e['f'], e['z']])
            rad = (base - c) / np.linalg.norm(base - c)
            ln = pk.get('lash', 0.0055) * (0.45 + 0.75 * smoothstep(0.0, 0.85, t)) * rng.uniform(0.85, 1.1)
            up = np.array([0.0, 0.0, 1.0])
            outw = np.array([side, 0.0, 0.0])
            d0 = rad * 0.8 + np.array([0, 0.35, 0]) + outw * 0.25 * t
            d0 /= np.linalg.norm(d0)
            p1 = base + d0 * ln * 0.5
            p2 = p1 + (d0 * 0.5 + up * 0.7 + outw * 0.25 * t) / np.linalg.norm(d0 * 0.5 + up * 0.7) * ln * 0.55
            out.append(([base, p1, p2], [0.00045, 0.0003, 0.00008]))
    return out


def teeth(H):
    """The teeth, upper and lower, as two bands curved round behind the lips: (upper rows,
    lower rows), each a list of rows of points (x, f, z) from one end to the other."""
    m = H['mouth']
    rows = []
    for top, bot, back in ((m['z'] + 0.006, m['z'] - 0.0028, 0.0105), (m['z'] - 0.0012, m['z'] - 0.0075, 0.0118)):
        band = []
        for x in np.linspace(-m['w'] * 0.68, m['w'] * 0.68, 15):
            t = x / (m['w'] * 0.68)
            f = m['f'] - back - 0.011 * t * t - (0.0022 if H.get('surface') else 0.0)   # a modelled head's lips are thicker
            band.append(((x, f, top), (x, f, bot)))
        rows.append(band)
    return rows


# ---------------------------------------------------------------- the hair


def hair_field(H, p):
    """Hair as a thick skin over the skull, cut to its line, combed into locks: grooves that run
    from the hairline back to where it's gathered at the nape."""
    hp = H['hair']
    if H.get('surface'):
        base = H['surface'].sdf(p)
        er = H['ear']
        base = smin(base, ellipsoid(mirror(p), (er['x'] - 0.004, er['f'], er['z'] + 0.006), (0.008, 0.022, 0.026)), 0.012)
    else:
        sk = H['skull']
        base = ellipsoid(p, (0, -0.012, 0.026), sk)
        base = smin(base, ellipsoid(p, (0, 0.042, 0.048), (0.060, 0.050, 0.050)), 0.02)
        base = smin(base, ellipsoid(mirror(p), (0.064, -0.004, -0.004), (0.008, 0.024, 0.032)), 0.02)   # over the ears' tops
    out = base - hp['lift'] * (0.6 + 0.4 * smoothstep(-0.02, 0.08, p[:, 2]))
    if H.get('surface'):
        # drawn back, but hair, not paint: it stands a little off the head at the crown and sweeps
        # out over the temples and the tops of the ears, and parts down the middle
        mp = mirror(p)
        out = out - 0.006 * gauss(mp, (0.065, -0.005, 0.03), (0.03, 0.06, 0.035)) \
            - 0.004 * gauss(p, (0.0, -0.03, H['crown'] - 0.01), (0.06, 0.06, 0.04))
        part = np.exp(-(p[:, 0] / 0.0025) ** 2) * smoothstep(-0.03, 0.02, p[:, 1]) * smoothstep(0.03, 0.06, p[:, 2])
        out = out + 0.004 * part
    # combed: the angle round an axis from the front of the part to the nape
    a = np.array([0.0, 0.07, 0.10]) if not H.get('surface') else np.array([0.0, 0.08, H['crown'] - 0.025])
    g = np.array([0.0, -0.095, -0.03])
    ax = (a - g) / np.linalg.norm(a - g)
    q = p - g
    q = q - (q @ ax)[:, None] * ax
    ref = np.array([0.0, 0.0, 1.0]) - (np.array([0.0, 0.0, 1.0]) @ ax) * ax
    ref /= np.linalg.norm(ref)
    side = np.cross(ax, ref)
    th = np.arctan2(q @ side, q @ ref)
    locks = np.abs(np.sin(th * hp['locks'] * 0.5 + 0.6 * noise(p, 0.02, 5)))
    out = out + hp['groove'] * (1.0 - locks) ** 2
    d = np.maximum(out, -(base + 0.0005))
    # its line: over the forehead, round the temples and above the ears, open below them
    c = p - np.array([0.0, -0.01, 0.0])
    n = c / np.maximum(length(c)[:, None], 1e-9)
    x, f, z = n[:, 0], n[:, 1], n[:, 2]
    line = hp['line'] + 0.05 * np.exp(-(x / 0.1) ** 2) - 0.4 * x * x
    face = (f > 0.15) & (z < line)
    ears = (np.abs(x) > 0.55) & (z < -0.05) & (f > -0.45)
    nape = z < -0.62
    cut = np.where(face | ears | nape, 0.004, -0.004)
    return np.maximum(d, cut)


def hair_mesh(H, step=0.0008):
    lo = (-0.1, -0.13, H['chin_z'] + 0.02)
    hi = (0.1, 0.12, H['crown'] + 0.02)
    return mesh(lambda q: hair_field(H, q), lo, hi, step)


def lid_tables(H, ug, vg, open_):
    """The lids' margins off a modelled head: open_[i, j] says whether the eyeball shows in the
    direction (ug[i] across, vg[j] up) from the eye's middle. For each angle across, the highest
    and lowest it shows. Sets H['lids'] and the eye's corners and opening."""
    e = H['eye']
    cols = np.where(open_.sum(1) >= 2)[0]
    i0, i1 = cols.min(), cols.max()
    top = np.full(len(ug), np.nan)
    bot = np.full(len(ug), np.nan)
    for i in cols:
        js = np.where(open_[i])[0]
        top[i], bot[i] = vg[js.max()], vg[js.min()]
    u = ug[i0:i1 + 1]
    t_, b_ = top[i0:i1 + 1], bot[i0:i1 + 1]
    ok = ~np.isnan(t_)
    t_, b_ = np.interp(u, u[ok], t_[ok]), np.interp(u, u[ok], b_[ok])
    # the corners, where the lids meet, half a step past the last that shows
    du = ug[1] - ug[0]
    uu = np.concatenate([[u[0] - du / 2], u, [u[-1] + du / 2]])
    m0, m1 = (t_[0] + b_[0]) / 2, (t_[-1] + b_[-1]) / 2
    H['lids'] = (uu, np.concatenate([[m0], t_, [m1]]), np.concatenate([[m0], b_, [m1]]))
    e['inner'], e['outer'] = float(-uu[0]), float(uu[-1])
    e['open'] = float(np.max(t_ - b_) * 0.6)
    return H['lids']


# ---------------------------------------------------------------- a quick look


def preview(H, path, size=360, view='front', span=0.29, at=(0.0, -0.012)):
    """The field raymarched with a lamp and a rim, no mesh: to judge the forms quickly."""
    from PIL import Image
    w = size
    hh = int(size * 1.15)
    ys, xs = np.mgrid[0:hh, 0:w]
    sx = (xs / w - 0.5) * span + at[0]
    sz = (0.5 - ys / hh) * span * hh / w + at[1]
    n = sx.size
    if view == 'front':
        o = np.stack([sx.ravel(), np.full(n, 0.4), sz.ravel()], 1)
        dvec = np.array([0, -1.0, 0])
    elif view == 'three':
        a = math.radians(35)
        o = np.stack([sx.ravel() * math.cos(a) + 0.4 * math.sin(a), -sx.ravel() * math.sin(a) + 0.4 * math.cos(a), sz.ravel()], 1)
        dvec = np.array([-math.sin(a), -math.cos(a), 0])
    else:
        o = np.stack([np.full(n, 0.4), -sx.ravel(), sz.ravel()], 1)
        dvec = np.array([-1.0, 0, 0])
    D = np.broadcast_to(dvec, o.shape)
    t = np.zeros(n)
    hit = np.zeros(n, bool)
    alive = np.ones(n, bool)
    balls = eyeballs(H)
    def field(q):
        d = head_field(H, q)
        for c, r in balls:
            d = np.minimum(d, length(q - np.array(c)) - r)
        return d
    for _ in range(140):
        idx = np.where(alive)[0]
        if len(idx) == 0:
            break
        q = o[idx] + D[idx] * t[idx, None]
        d = field(q)
        t[idx] += d * 0.8
        h = d < 0.00015
        hit[idx[h]] = True
        alive[idx[h | (t[idx] > 0.8)]] = False
    img = np.zeros((n, 3))
    idx = np.where(hit)[0]
    q = o[idx] + D[idx] * t[idx, None]
    eps = 0.0004
    nrm = np.stack([field(q + [eps, 0, 0]) - field(q - [eps, 0, 0]), field(q + [0, eps, 0]) - field(q - [0, eps, 0]),
                    field(q + [0, 0, eps]) - field(q - [0, 0, eps])], 1)
    nrm /= np.maximum(length(nrm)[:, None], 1e-9)
    key = np.array([0.5, 0.6, 0.62])
    key /= np.linalg.norm(key)
    lam = np.clip(nrm @ key, 0, 1)
    rim = np.clip(nrm @ np.array([-0.7, -0.2, 0.3]), 0, 1) ** 2
    is_eye = np.zeros(len(idx), bool)
    for c, r in balls:
        is_eye |= np.abs(length(q - np.array(c)) - r) < 0.0004
    base = np.where(is_eye[:, None], np.array([0.9, 0.88, 0.85]), np.array([0.78, 0.6, 0.45]))
    col = base * (0.18 + 0.82 * lam[:, None]) + rim[:, None] * 0.25
    img[idx] = col
    img = (np.clip(img, 0, 1) ** (1 / 2.2) * 255).astype(np.uint8).reshape(hh, w, 3)
    Image.fromarray(img).save(path)


if __name__ == '__main__':
    who = sys.argv[1]
    out = sys.argv[sys.argv.index('--preview') + 1]
    os.makedirs(out, exist_ok=True)
    for v in ('front', 'three', 'side'):
        preview(HEADS[who], os.path.join(out, f'{who}_{v}.png'), view=v)
    preview(HEADS[who], os.path.join(out, f'{who}_close.png'), view='three', span=0.11, at=(0.0, -0.02))
