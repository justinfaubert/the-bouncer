"""The heads of the people in the room, built on real measurements.

A head here is a signed distance field (tools/sdf.py) in the head's own frame: x to their right, y
forward, z up, in metres, its origin a little in front of the ear holes at the height of the eyes'
centres (people.py puts it at p.head, turned by p.Rh, scaled by the head's size). Everything is in
proportion to an average man's head (196 mm from brow to the back of the skull, 152 across, 232 from
crown to chin; the cheekbones 140 across, the angles of the jaw 112, eyes 64 apart), after the
measurements of faces in the anthropometric literature (Farkas and others), and a person's own
`Face` moves it from there: a woman's, a young or an old face, a heavy or a lean one, and the small
differences everyone has, drawn from their name.

The skull and the face are big soft shapes melted together, then the features are made on them:
eyes in their sockets with lids over them, a nose, a mouth on the curve of the teeth, ears, a neck
with the cords of its muscles. Hair and hats are people.py's: they're laid on `skull` and `brain`.
"""
import zlib
import numpy as np
import sdf as S

V = lambda *a: np.array(a, dtype=np.float32)
MM = 0.001


def mm(*a):
    return np.array(a, dtype=np.float32) * MM


def norm(v):
    return v / (np.linalg.norm(v) + 1e-9)


# ------------------------------------------------------------------------------------ shapes

def blob(c, rx, ry, rz, n=2.0, m=2.0, R=None):
    """A soft solid like an egg: an ellipsoid whose front and back (ry = (front, back)) and top
    and bottom (rz = (top, bottom)) can differ, its outline squarer across with n > 2 and up and
    down with m > 2. Radii in metres. Its distance is the field over its gradient (close to the
    surface, where it counts)."""
    c = np.asarray(c, dtype=np.float32)
    ry = ry if isinstance(ry, (tuple, list)) else (ry, ry)
    rz = rz if isinstance(rz, (tuple, list)) else (rz, rz)
    rx = rx if isinstance(rx, (tuple, list)) else (rx, rx)

    def f(P):
        q = P - c
        if R is not None:
            q = q @ R
        ax = np.where(q[:, 0] > 0, rx[0], rx[1])
        ay = np.where(q[:, 1] > 0, ry[0], ry[1])
        az = np.where(q[:, 2] > 0, rz[0], rz[1])
        X, Y, Z = np.abs(q[:, 0]) / ax, np.abs(q[:, 1]) / ay, np.abs(q[:, 2]) / az
        h = (X ** n + Y ** n) ** (1.0 / n) + 1e-9
        k = (h ** m + Z ** m) ** (1.0 / m) + 1e-9
        a = k ** (1 - m) * h ** (m - n)
        gx = a * X ** (n - 1) / ax
        gy = a * Y ** (n - 1) / ay
        gz = k ** (1 - m) * Z ** (m - 1) / az
        g = np.sqrt(gx * gx + gy * gy + gz * gz) + 1e-9
        return (k - 1.0) / g
    return f


def tube(pts, radii, k=0.0):
    """A tube through pts, its radius running through radii: a chain of round cones."""
    pts = [np.asarray(p, dtype=np.float32) for p in pts]
    parts = [S.cone(pts[i], pts[i + 1], radii[i], radii[i + 1]) for i in range(len(pts) - 1)]
    return S.blend(k, *parts) if k > 0 else S.union(*parts)


def smooth_curve(pts, n=24):
    """A Catmull-Rom curve through pts, n points between each pair."""
    pts = np.asarray(pts, dtype=np.float32)
    P = np.concatenate([pts[:1] * 2 - pts[1:2], pts, pts[-1:] * 2 - pts[-2:-1]])
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for t in np.linspace(0, 1, n, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(pts[-1])
    return np.array(out, dtype=np.float32)


def curve_dist(curve):
    """The distance to a polyline, and where along it (0..1) the nearest point is."""
    A = curve[:-1]
    Bv = curve[1:] - curve[:-1]
    L = np.linalg.norm(Bv, axis=1)
    cum = np.concatenate([[0.0], np.cumsum(L)])
    total = cum[-1]
    BB = (Bv * Bv).sum(axis=1) + 1e-12

    def f(P):
        best = np.full(len(P), np.inf, dtype=np.float32)
        where = np.zeros(len(P), dtype=np.float32)
        for i in range(len(A)):
            pa = P - A[i]
            t = np.clip(pa @ Bv[i] / BB[i], 0.0, 1.0)
            d = np.linalg.norm(pa - t[:, None] * Bv[i], axis=1)
            better = d < best
            best = np.where(better, d, best)
            where = np.where(better, (cum[i] + t * L[i]) / total, where)
        return best, where
    return f


def ribbon(curve, radius, k=0.0):
    """A tube along a smooth curve whose radius is a function of where along it (0..1)."""
    cn = curve_near(curve)

    def f(P):
        q, w = cn(P)
        return np.linalg.norm(q, axis=1) - radius(w)
    return f


def curve_near(curve):
    """For points: the offset from the nearest point of a polyline to each, and where along it
    (0..1) that nearest point is."""
    A = curve[:-1].astype(np.float32)
    Bv = (curve[1:] - curve[:-1]).astype(np.float32)
    L = np.linalg.norm(Bv, axis=1)
    cum = np.concatenate([[0.0], np.cumsum(L)]).astype(np.float32)
    total = float(cum[-1])
    BB = (Bv * Bv).sum(axis=1) + 1e-12

    def f(P):
        off = np.empty_like(P)
        where = np.empty(len(P), dtype=np.float32)
        step = max(1, 400000 // max(len(A), 1))
        for s in range(0, len(P), step):
            Q = P[s:s + step]
            pa = Q[:, None, :] - A[None, :, :]
            t = np.clip((pa * Bv[None]).sum(axis=2) / BB[None], 0.0, 1.0)
            q = pa - t[:, :, None] * Bv[None]
            d2 = (q * q).sum(axis=2)
            i = np.argmin(d2, axis=1)
            r = np.arange(len(Q))
            off[s:s + step] = q[r, i]
            where[s:s + step] = (cum[i] + t[r, i] * L[i]) / total
        return off, where
    return f


def ribbon2(curve, rh, rv, up=(0.0, 0.0, 1.0)):
    """A tube along a curve whose section is an ellipse, rv high (along `up`) and rh across, each a
    function of where along the curve (0..1): a lip, an eyebrow."""
    cn = curve_near(curve)
    up = np.asarray(up, dtype=np.float32)

    def f(P):
        q, w = cn(P)
        a, b = np.maximum(rh(w), 1e-4), np.maximum(rv(w), 1e-4)
        qz = q @ up
        qh = np.linalg.norm(q - qz[:, None] * up, axis=1)
        k0 = np.sqrt((qh / a) ** 2 + (qz / b) ** 2)
        k1 = np.sqrt((qh / (a * a)) ** 2 + (qz / (b * b)) ** 2)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)
    return f


def hump(t, p=1.0):
    """0 at each end of 0..1, 1 in the middle, its shoulders fuller for p < 1."""
    return np.maximum(np.sin(np.pi * np.clip(t, 0.0, 1.0)), 0.0) ** p


def wend(t):
    t = np.clip(t, 0.0, 1.0)
    return (1 - t) ** 4 * (4 * t + 1)


def swell(c, r, amp, R=None):
    """A smooth rise of amp metres at c, gone by r (r a radius, or radii along R's axes): added to
    a shape's surface with lift()."""
    c = np.asarray(c, dtype=np.float32)
    r = np.asarray(r, dtype=np.float32)

    def g(P):
        q = P - c
        if R is not None:
            q = q @ R
        return amp * wend(np.linalg.norm(q / r, axis=1))
    return g


def swell2(c, r, amp, R=None):
    """Like swell, but broad, its top flatter: for the soft parts of a face."""
    c = np.asarray(c, dtype=np.float32)
    r = np.asarray(r, dtype=np.float32)

    def g(P):
        q = P - c
        if R is not None:
            q = q @ R
        t2 = np.minimum((q / r) ** 2 @ np.ones(3, np.float32), 1.0)
        return amp * (1.0 - t2) ** 2
    return g


def lift(f, *gs):
    """The shape f with the rises gs added to its surface (a negative rise sinks it)."""
    def h(P):
        out = f(P)
        for g in gs:
            out = out - g(P)
        return out
    return h


def groove(curve, width, depth):
    """A rise (for lift()) that is a soft groove along a curve lying on a surface: `depth(t)`
    metres deep at each place along it (0..1), gone `width` metres to either side."""
    cn = curve_near(curve)
    lo = curve.min(axis=0) - width
    hi = curve.max(axis=0) + width

    def g(P):
        out = np.zeros(len(P), dtype=np.float32)
        near = np.all((P > lo) & (P < hi), axis=1)
        if near.any():
            q, t = cn(P[near])
            out[near] = -depth(t) * wend(np.linalg.norm(q, axis=1) / width)
        return out
    return g


def within(region, f, band=0.003):
    """The shape f, only where it's inside region (a cheap shape): f is worked out only near the
    region, the region's own distance standing in for it elsewhere."""
    def g(P):
        out = region(P)
        near = out < band
        if near.any():
            out[near] = np.maximum(out[near], f(P[near]))
        return out
    return g


def mirror(fn):
    """Both sides: fn(sx) for sx = -1 and 1, unioned."""
    return S.union(fn(-1.0), fn(1.0))


def bounded(f, c, r):
    """f, worked out only within r of c (a small shape among many): further off, the distance to
    that sphere stands in for it, which is never nearer than the shape itself."""
    c = np.asarray(c, dtype=np.float32)

    def g(P):
        d = np.linalg.norm(P - c, axis=1) - r
        near = d < 0.004
        if near.any():
            d[near] = f(P[near])
        return d
    return g


def blend_near(k, a, b, c, r):
    """A smooth union of a with b, where b is small and lies within r of c: a alone further off.
    k (metres) can be a function of the points, to melt them together more in some places."""
    c = np.asarray(c, dtype=np.float32)
    kmax = k if not callable(k) else 0.02

    def g(P):
        out = a(P)
        near = np.linalg.norm(P - c, axis=1) < r + kmax + 0.004
        if near.any():
            out = out.copy()
            Q = P[near]
            out[near] = S._smin(out[near], b(Q), k(Q) if callable(k) else k)
        return out
    return g


def carve_near(k, a, b, c, r):
    """a with b (small, within r of c) cut out of it, softened over k."""
    c = np.asarray(c, dtype=np.float32)

    def g(P):
        out = a(P)
        near = np.linalg.norm(P - c, axis=1) < r + k + 0.004
        if near.any():
            out = out.copy()
            da, db = out[near], b(P[near])
            out[near] = np.maximum(da, -db) if k <= 0 else -S._smin(-da, db, k)
        return out
    return g


def loft(rows, cap=(0.0, 0.0), smooth=True):
    """A solid stacked from horizontal slices: rows of (z, half-width, y of the widest point, y of
    the front, y of the back, squareness of the front, of the back), in metres. Each slice is a
    superellipse round its widest point, pointed at the front for a squareness under 2, square for
    over 2; the rows run into each other up and down along a smooth spline (or, with smooth False,
    one that never overshoots them). Its ends are flat, their edges rounded by cap = (bottom, top)
    metres. Its distance is its field over the field's gradient."""
    from scipy.interpolate import CubicSpline, PchipInterpolator
    rows = np.asarray(rows, dtype=np.float64)
    rows = rows[np.argsort(rows[:, 0])]
    z = rows[:, 0]
    if smooth:
        fits = [CubicSpline(z, rows[:, j], bc_type='natural', extrapolate=True) for j in range(1, 7)]
    else:
        fits = [PchipInterpolator(z, rows[:, j], extrapolate=True) for j in range(1, 7)]
    z0, z1 = float(z[0]), float(z[-1])
    rb, rt = cap

    def at(z):
        zz = np.clip(z.astype(np.float64), z0, z1)
        return [np.asarray(f(zz), dtype=np.float32) for f in fits]

    def field(P, sv):
        w, yc, yf, yb, nf, nb = sv
        dy = P[:, 1] - yc
        front = dy > 0
        d = np.where(front, yf - yc, yc - yb)
        n = np.where(front, nf, nb)
        w = np.maximum(w, 0.002)
        d = np.maximum(d, 0.002)
        X = np.abs(P[:, 0]) / w + 1e-9
        Y = np.abs(dy) / d + 1e-9
        k = (X ** n + Y ** n) ** (1.0 / n)
        # in metres: the field over its gradient across the slice (which doesn't jump where the
        # front's depth meets the back's)
        g = k ** (1.0 - n) * np.sqrt((X ** (n - 1) / w) ** 2 + (Y ** (n - 1) / d) ** 2)
        o = (k - 1.0) / np.maximum(g, 1e-6)
        # the ends: in the plane of (out from the outline, up past the end), a rectangle's corner
        # rounded by the cap
        out = o
        for r, t in ((rt, P[:, 2] - (z1 - rt)), (rb, (z0 + rb) - P[:, 2])):
            a, b = o + r, t
            corner = np.sqrt(np.maximum(a, 0.0) ** 2 + np.maximum(b, 0.0) ** 2) + np.minimum(np.maximum(a, b), 0.0) - r
            out = np.maximum(out, corner)
        return out

    def f(P):
        e = 0.0004
        sv = at(P[:, 2])
        d0 = field(P, sv)
        g = np.zeros(len(P), dtype=np.float32)
        for ax in range(2):
            dp = np.zeros(3, dtype=np.float32)
            dp[ax] = e
            g = g + ((field(P + dp, sv) - field(P - dp, sv)) / (2 * e)) ** 2
        dp = np.array([0, 0, e], dtype=np.float32)
        g = g + ((field(P + dp, at(P[:, 2] + e)) - field(P - dp, at(P[:, 2] - e))) / (2 * e)) ** 2
        return d0 / np.maximum(np.sqrt(g), 0.2)
    return f


def front_y(f, x, z, y0=0.02, y1=0.17, it=22):
    """Where the front of the shape f is (its y, metres) at each x, z (metres, scalars or arrays),
    between y0 (inside it) and y1 (in front of it): for laying small things on a surface."""
    x, z = np.broadcast_arrays(np.atleast_1d(np.asarray(x, np.float32)), np.atleast_1d(np.asarray(z, np.float32)))
    lo = np.full(x.shape, y0, np.float32)
    hi = np.full(x.shape, y1, np.float32)
    for _ in range(it):
        mid = (lo + hi) / 2
        inside = f(np.stack([x, mid, z], axis=1)) < 0
        lo = np.where(inside, mid, lo)
        hi = np.where(inside, hi, mid)
    return (lo + hi) / 2


def prism_y(f2, y0=None, y1=None):
    """A 2D shape in x-z (f2(x, z) its distance) run straight through front to back, optionally
    only between y0 and y1."""
    def f(P):
        d = f2(P[:, 0], P[:, 2])
        if y0 is not None:
            d = np.maximum(d, y0 - P[:, 1])
        if y1 is not None:
            d = np.maximum(d, P[:, 1] - y1)
        return d
    return f


def lens2(a, b, up, low, shear=0.0):
    """An almond in a plane, as a 2D distance: between corners a and b, its upper edge an arc rising
    `up` above the line from a to b, its lower edge an arc `low` below it; `shear` leans it (the top
    toward a for a shear > 0)."""
    a, b = np.asarray(a, dtype=np.float64), np.asarray(b, dtype=np.float64)
    mid = (a + b) / 2
    ch = b - a
    L = np.linalg.norm(ch)
    t = ch / L
    nrm = np.array([-t[1], t[0]])
    if nrm[1] < 0:
        nrm = -nrm
    R1 = (L * L / 4 + up * up) / (2 * up)
    R2 = (L * L / 4 + low * low) / (2 * low)
    c1 = mid - nrm * (R1 - up)
    c2 = mid + nrm * (R2 - low)

    def f(u, v):
        u = u + shear * (v - mid[1])
        d1 = np.sqrt((u - c1[0]) ** 2 + (v - c1[1]) ** 2) - R1
        d2 = np.sqrt((u - c2[0]) ** 2 + (v - c2[1]) ** 2) - R2
        return np.maximum(d1, d2)
    return f, (c1, R1, c2, R2)


# ------------------------------------------------------------------------------------ the face

# An average man's face, in mm (see the module's note for the frame): what a person's Face moves.
AVERAGE = dict(
    # the vault of the skull: its half-width, how far it reaches forward and back of its middle, up
    # and down
    skull_w=75.0, skull_front=100.0, skull_back=94.0, skull_top=88.0, skull_low=80.0,
    # the brow: how far forward the bone between the brows stands, and the root of the nose
    brow_y=94.0, nasion_y=88.0, nasion_z=12.0,
    # the cheekbones' half-width; the angles of the jaw (half-width, height, how far forward)
    zy=69.0, go_w=56.0, go_z=-67.0, go_y=4.0,
    # the chin: its half-width, its front, the bottom of the jaw under it
    chin_w=20.0, pg_y=89.0, pg_z=-99.0, gn_z=-110.0, me_y=72.0, me_z=-114.0,
    # the eyes: half the distance between the pupils, where their centres are, the ball's radius
    eye_x=31.5, eye_y=64.0, eye_z=5.0, eye_r=12.0, iris_r=5.9,
    # the opening of the lids: inner and outer corners (out from the pupil, up from it), how far
    # the upper lid's edge rises and the lower falls from the line between the corners, the lids'
    # thickness, the fold of skin over the upper lid (0 none, 1 hooded), bags under the eyes
    fis_in=(-14.2, -0.5), fis_out=(12.8, 1.5), fis_up=3.7, fis_low=5.2, lid_t=2.5, hood=0.0, bags=0.0,
    # the nose: the tip (pronasale) and where it meets the lip (subnasale), the wings' half-width,
    # the tip's half-width, the bridge's line (a hump > 0, a dip < 0), off the straight (mm)
    prn_y=114.0, prn_z=-33.0, sn_y=93.0, sn_z=-43.0, al_w=17.5, tip_w=10.5, dorsum=0.0, crooked=0.0,
    # the mouth: its corners' half-width, the line where the lips meet, the red of the upper and
    # lower lip (heights), how far forward each lip stands
    ch_w=27.0, sto_z=-65.0, ls_h=8.0, li_h=9.5, ls_y=97.0, li_y=94.0,
    # the ears: length and width, how far the back of each stands off the head (radians)
    ear_len=63.0, ear_w=35.0, ear_flare=0.55,
    # the soft parts: the edge of the jaw (sharp, small; soft, big), the fill under it, the hollow
    # under the cheekbones, the neck's half-width and the Adam's apple
    jaw_k=10.0, under_k=24.0, gaunt=0.45, neck_w=52.0, larynx=1.0,
    # the expression at rest: a smile (0..1), the brows drawn down (0..1)
    smile=0.0, frown=0.0,
    # what the years and the fat do (0..1, and -1..1 for lean to heavy), the fat of the cheeks
    age=0.3, fat=0.0, cheeks=0.3, lines=1.0,
    # the eyebrows: how high over the eyes, how much they arch, how thick (mm)
    brow_lift=0.0, brow_arch=1.5, brow_w=8.5, brow_ridge=1.0,
)


def _basis(x, y, z):
    """The rotation whose columns are x, y, z (for an ellipsoid's axes)."""
    return np.stack([x, y, z], axis=1).astype(np.float32)


class Head:
    """A head built from a face's numbers (mm, as AVERAGE). After build(): `skin` (the skin's
    shape, in the head's frame, metres), `parts` (material, shape, order) for everything on it,
    and the shapes people.py lays hair and hats on: `skull`, `brain` (the skull with the
    forehead), `jaw` (where a beard grows) and `face_hole`."""

    def __init__(self, **fp):
        self.fp = dict(AVERAGE)
        self.fp.update(fp)

    def __getattr__(self, k):
        fp = self.__dict__.get('fp')
        if fp is not None and k in fp:
            return fp[k]
        raise AttributeError(k)

    # -------------------------------------------------------------------------- the big shapes
    def vault_rows(self):
        w, f, b = self.skull_w, self.skull_front, self.skull_back
        # z, half-width, y at the widest, y front, y back, squareness (an average man's skull: the
        # crown above and a little behind the ears, the forehead standing up from the brow and
        # leaning back, the back of the head round and full over the nape)
        rows = [(125, 2, -12, -8, -16, 2.0), (120, 0.43 * w, -12, 0.34 * f - 12, -0.36 * b - 12, 2.2),
                (110, 0.67 * w, -13, 0.59 * f - 13, -0.58 * b - 13, 2.3), (95, 0.84 * w, -15, 0.82 * f - 15, -0.77 * b - 15, 2.4),
                (75, 0.96 * w, -18, 0.98 * f - 18, -0.86 * b - 18, 2.5), (55, w, -20, 1.06 * f - 20, -0.89 * b - 20, 2.5),
                (40, 1.005 * w, -20, 1.07 * f - 20, -0.89 * b - 20, 2.5), (25, w, -18, 1.02 * f - 18, -0.89 * b - 18, 2.4),
                (10, 0.97 * w, -16, 0.88 * f - 16, -0.87 * b - 16, 2.3), (-5, 0.945 * w, -14, 0.7 * f - 14, -0.83 * b - 14, 2.3),
                (-20, 0.88 * w, -14, 0.5 * f - 14, -0.74 * b - 14, 2.3), (-35, 0.75 * w, -18, 0.28 * f - 18, -0.6 * b - 18, 2.3),
                (-48, 0.5 * w, -34, -14, -0.45 * b - 22, 2.3), (-62, 0.32 * w, -36, -22, -0.36 * b - 22, 2.3),
                (-76, 0.16 * w, -38, -30, -0.28 * b - 22, 2.3)]
        return [[r[0] * MM, r[1] * MM, r[2] * MM, r[3] * MM, r[4] * MM, r[5], r[5]] for r in rows]

    def vault(self):
        w, f, b = self.skull_w, self.skull_front, self.skull_back
        # up to the crown the rows; over it a dome, as wide as the rows up to 75 mm and a little
        # fuller above (the rows' thin top slices make a field that jumps over the crown, and hair
        # and hats laid on the skull at an offset came out flat-topped)
        lo = S.intersect(loft(self.vault_rows(), smooth=False), S.halfspace(mm(0, 0, 85), V(0, 0, 1)))
        dome = blob(mm(0, -14, 45), 1.01 * w * MM, (0.977 * f * MM, 0.94 * b * MM), (80 * MM, 40 * MM), n=2.4, m=2.4)
        # (the two all but meet from 60 to 85 mm up: a smooth join there would swell into a ridge)
        v = S.union(lo, dome)
        self.skull = v
        return v

    def face_rows(self):
        go_w, zy, ch = self.go_w, self.zy, self.chin_w
        gn_y = self.me_y + 10.0
        # z, half-width, y at the widest, y front, y back, squareness: few rows, so the face runs
        # smooth from one to the next (its smaller hollows and rises are made on it after)
        rows = [
            (self.gn_z - 25, ch + 4, 44, gn_y - 16, -30, 2.2),
            (self.gn_z, ch + 10, 42, gn_y, -30, 2.2),
            ((self.gn_z + self.go_z) / 2 - 3, (go_w + ch) / 2 + 10, 26, self.pg_y - 2, -30, 2.05),
            (self.go_z, go_w + 1, 14, self.ls_y - 8, -30, 2.0),
            (-40, (go_w + zy) / 2 + 1.5, 22, self.sn_y - 4, -30, 1.9),
            (-15, zy - 0.5, 28, 87, -30, 1.75),
            (8, zy - 4, 27, 88, -30, 1.5),
            (22, zy - 17, 32, self.brow_y - 8, -30, 2.0),
            (34, zy - 35, 36, self.brow_y - 18, -30, 2.0),
            # (on up inside the skull, so where the face ends is well out of sight)
            (46, zy - 47, min(38, self.brow_y - 32 - 16), self.brow_y - 32, -30, 2.0),
            (58, zy - 57, min(40, self.brow_y - 46 - 16), self.brow_y - 46, -30, 2.0),
        ]
        return [[r[0] * MM, r[1] * MM, r[2] * MM, r[3] * MM, r[4] * MM, r[5], r[5]] for r in rows]

    def neck(self):
        w = self.neck_w
        rows = [(-235, w + 10, -18, 44, -80), (-185, w + 5, -16, 42, -74), (-150, w + 2, -14, 40, -68),
                (-120, w, -12, 38, -64), (-90, w, -14, 30, -62), (-60, w + 2, -18, 18, -64),
                (-30, w, -22, 6, -62), (-10, w - 6, -26, -6, -58), (6, w - 16, -28, -12, -52), (22, w - 28, -30, -18, -44)]
        nk = loft([[r[0] * MM, r[1] * MM, r[2] * MM, r[3] * MM, r[4] * MM, 2.2, 2.2] for r in rows], cap=(0.0, 0.02), smooth=False)
        # the cords from behind each ear down to the top of the breastbone
        scm = mirror(lambda sx: tube([mm(sx * 56, -26, -32), mm(sx * 40, 4, -110), mm(sx * 14, 36, -196)],
                                     [9 * MM, 11 * MM, 8 * MM]))
        nk = S.blend(9 * MM, nk, scm)
        if self.larynx > 0:
            nk = blend_near(10 * MM, nk, S.ellipsoid(mm(0, 38, -132), mm(9, 6.5, 13) * self.larynx), mm(0, 38, -132), 0.016)
        return nk

    def base(self):
        face = loft(self.face_rows(), cap=(0.0, 0.014))
        me = mm(0, self.me_y, self.me_z)
        go = mm(0, self.go_y, self.go_z)
        nrm = norm(np.cross(go - me, V(1, 0, 0)))
        if nrm[2] > 0:
            nrm = -nrm
        face = S.intersect(face, S.halfspace(me, nrm), self.jaw_k * MM)
        self.jaw = face
        head = S.blend(22 * MM, self.vault(), face)
        head = S.blend(self.under_k * MM, head, self.neck())
        # the ridge of the brow: the bone over each eye and between them, standing out of the
        # forehead's lean
        by = self.brow_y
        curve = smooth_curve(np.array([mm(-50, by - 36, 15), mm(-36, by - 16, 19), mm(-18, by - 7, 19.5), mm(0, by - 6, 19),
                                       mm(18, by - 7, 19.5), mm(36, by - 16, 19), mm(50, by - 36, 15)]), 8)
        brow = ribbon(curve, lambda t: (3.0 + 2.0 * hump(t, 0.5)) * self.brow_ridge * MM)
        head = blend_near(14 * MM, head, brow, mm(0, by - 20, 18), 0.06)
        # the skin of the upper lip, leaning forward from under the nose to the red, round the
        # curve of the teeth (the lips are laid on after)
        top = self.sto_z + self.ls_h + 2.0
        mc = mm(0, self.ls_y - 2.0 - 28.0, top)
        muzzle = blob(mc, (self.ch_w + 3) * MM, 28 * MM, ((self.sn_z - top) * 2.4 * MM, 12 * MM))
        head = blend_near(10 * MM, head, muzzle, mc, 0.045)
        # the point of the chin
        cc = mm(0, self.pg_y - 11, self.pg_z + 1)
        head = blend_near(10 * MM, head, S.ellipsoid(cc, mm(self.chin_w - 2, 11, 12)), cc, 0.025)
        return head

    # -------------------------------------------------------------------------- the eyes
    def eye_centre(self, sx):
        return mm(sx * self.eye_x, self.eye_y, self.eye_z)

    def lens(self):
        return lens2(self.fis_in, self.fis_out, self.fis_up, self.fis_low, shear=0.3)

    def margin(self, upper=True, n=24, rise=0.0, widen=1.0):
        """Points along the edge of the upper (or lower) lid in the eye's front view (u, v), mm."""
        f2, (c1, R1, c2, R2) = self.lens()
        a, b = np.asarray(self.fis_in, float), np.asarray(self.fis_out, float)
        mid_v = (a[1] + b[1]) / 2
        c, R = (c1, R1) if upper else (c2, R2)
        sgn = 1.0 if upper else -1.0
        out = []
        for t in np.linspace(0.0, 1.0, n):
            u0 = a[0] + (b[0] - a[0]) * t
            # on the circle, sheared back
            v = c[1] + sgn * np.sqrt(max(R * R - (u0 - c[0]) ** 2, 0.0))
            u = u0 - 0.3 * (v - mid_v)
            out.append((u * widen, v + rise))
        return out

    def on_ball(self, sx, uv, radius):
        c = self.eye_centre(sx) / MM
        pts = []
        for u, v in uv:
            dy = np.sqrt(max(radius * radius - u * u - v * v, 1.0))
            pts.append(mm(c[0] + sx * u, c[1] + dy, c[2] + v))
        return pts

    def eyes(self, head):
        r, t = self.eye_r * MM, self.lid_t * MM
        out_parts = []
        f2, _ = self.lens()
        for sx in (-1.0, 1.0):
            c = self.eye_centre(sx)
            # the socket: room under the brow for the ball and its lids, hollowed only in front of
            # the ball's middle (so nothing beside it is hollowed out)
            oc = c + mm(sx * 0.0, 6.0, 6.0)
            sock = S.ellipsoid(oc, mm(16.0, 10.0, 11.0))
            head = carve_near(6.0 * MM, head, sock, oc, 0.025)
            cx, cz = float(c[0]), float(c[2])

            def g(x, z, cx=cx, cz=cz, sx=sx):
                return f2((sx * (x - cx)) / MM, (z - cz) / MM) * MM
            opening = prism_y(g, y0=float(c[1]) - 0.008)
            # the lids: a skin over the ball, thinner below than above
            def lid(P, c=c):
                q = P - c
                d = np.linalg.norm(q, axis=1)
                tt = t * (0.6 + 0.4 * np.clip((q[:, 2] + 0.003) / 0.006, 0.0, 1.0))
                return np.maximum(d - (r + tt), (r + 0.25 * MM) - d)
            lid = S.intersect(lid, S.halfspace(c + mm(0, -6, 0), V(0, -1, 0)))
            lid = S.carve(lid, opening, 0.9 * MM)
            # the crease over the upper lid
            crease = tube(self.on_ball(sx, self.margin(True, 12, rise=6.5 + 2.0 * self.hood, widen=1.08),
                                       self.eye_r + self.lid_t + 0.6), [0.8 * MM] * 12)
            lid = S.carve(lid, crease, 1.0 * MM)
            head = blend_near(2.5 * MM, head, lid, c, 0.02)
            # and the opening between the lids, clear through to the ball (only over the ball, so
            # nothing is hollowed out past its sides)
            over = S.intersect(S.intersect(opening, S.sphere(c, r + 2.2 * MM)), S.halfspace(c + mm(0, -5.0, 0), V(0, -1, 0)))
            head = carve_near(0.5 * MM, head, over, c, 0.02)
            out_parts.append(('eye', S.sphere(c, r), 1))
            # the iris (and the cornea over it) a millimetre proud of the white, so it stands clear
            # of it to its edge however coarsely it's meshed
            iris = S.intersect(S.sphere(c, r + 1.0 * MM), S.cylinder(c, c + mm(0, 20, 0), self.iris_r * MM))
            out_parts.append(('iris', iris, 2))
            # the lashes: the edge of the upper lid drawn dark (a band of the lid's skin, deep
            # enough to mesh at any step)
            mg = self.on_ball(sx, self.margin(True, 14, rise=-0.2), self.eye_r + self.lid_t * 0.6)
            band = bounded(ribbon(smooth_curve(np.array(mg), 4), lambda t: (0.9 + 0.9 * hump(t, 0.55)) * MM), c, 0.022)
            self.lash_bands.append(band)
        return head, out_parts

    # -------------------------------------------------------------------------- the nose
    def nose_rows(self):
        """The nose as slices up its length (mm, as loft rows): the bridge between the eyes, the
        line of it down to the tip, the wings either side of the tip, wide at the back."""
        ny, nz = self.nasion_y + 1.0, self.nasion_z
        ty, tz = self.prn_y, self.prn_z
        sup_y, sup_z = ty - 3.0, tz + 7.0

        def line(z):
            # the bridge's line from the root to above the tip, a hump (or a dip) on it
            t = (nz - z) / (nz - sup_z)
            return ny + (sup_y - ny) * t + self.dorsum * hump(np.clip(t * 1.25, 0, 1), 1.0)
        aw = self.al_w
        rows = [(nz + 9, 9.5, ny - 11, ny - 4, 64, 1.9),
                (nz, 8.5, ny - 6, ny, 66, 1.8),
                (2, 8.0, line(2) - 8, line(2), 68, 1.65),
                (-10, 8.0, line(-10) - 9, line(-10), 70, 1.6),
                (sup_z + 6, 8.6, line(sup_z + 6) - 14.5, line(sup_z + 6), 72, 1.65),
                (sup_z, 10.0, self.sn_y - 1, sup_y, 72, 1.75),
                (tz + 3, self.tip_w + 2.0, self.sn_y - 1, ty - 0.5, 72, 1.7),
                (tz - 1, self.tip_w + 2.5, self.sn_y - 1, ty, 72, 1.65),
                (tz - 6, self.tip_w + 2.0, self.sn_y - 2, ty - 3, 72, 1.6),
                (self.sn_z - 3, self.tip_w + 1.0, self.sn_y - 2, ty - 9, 72, 1.6)]
        return [[r[0] * MM, r[1] * MM, r[2] * MM, r[3] * MM, r[4] * MM, r[5], 2.0] for r in rows]

    def nose(self, head):
        rows = self.nose_rows()
        body = loft(rows, cap=(0.003, 0.0), smooth=True)
        nz, tz = self.nasion_z * MM, self.prn_z * MM
        if self.crooked:
            def bent(P, f=body):
                q = P.copy()
                q[:, 0] -= self.crooked * MM * np.clip((nz - P[:, 2]) / (nz - tz), 0.0, 1.2)
                return f(q)
            body = bent
        # the wings of the nostrils, either side of the tip, long from the cheek toward the tip,
        # widest where they meet the cheek
        aw = self.al_w
        ar = (4.5, 8.0, 5.6)
        alae = []
        for sx in (-1.0, 1.0):
            Ra = S.rot(sx * 0.55, 0.12, 0.0)
            ac = mm(sx * (aw - 4.5), self.sn_y - 3.0, self.sn_z + 7.5)
            alae.append((sx, ac, Ra))
        body = S.blend(3.5 * MM, body, *[S.ellipsoid(ac, mm(*ar), Ra) for _, ac, Ra in alae])
        # underneath: from where it meets the lip, rising a little to the tip
        P0 = mm(0, self.sn_y, self.sn_z - 0.5)
        body = S.intersect(body, S.halfspace(P0, norm(V(0, 0.22, -1.0))), 3.5 * MM)
        ctr = mm(0, (self.nasion_y + self.prn_y) / 2, (self.nasion_z + self.sn_z) / 2)
        # melted into the face softly up the bridge, sharper round the wings
        zk0, zk1 = (self.prn_z + 4.0) * MM, (self.prn_z + 22.0) * MM
        kf = lambda P: (3.0 + 5.0 * np.clip((P[:, 2] - zk0) / (zk1 - zk0), 0.0, 1.0)) * MM
        before = head
        head = blend_near(kf, head, body, ctr, 0.045)
        for sx, ac, Ra in alae:
            ex, ey, ez = Ra[:, 0] * sx, Ra[:, 1], Ra[:, 2]

            def on_ala(th, ph):
                # a point on the wing's surface: th along it from the back end (0) to the front
                # (pi), ph round it from underneath (-pi/2) by the outer side (0) to the top
                return ac + (ex * ar[0] * np.cos(ph) * np.sin(th) - ey * ar[1] * np.cos(th) + ez * ar[2] * np.sin(ph) * np.sin(th)) * MM
            # the crease where it comes out of the cheek: for each way round, the first point
            # along it that's out of the face
            pts = []
            ths = np.linspace(0.05, np.pi * 0.6, 60)
            for ph in np.radians([-55, -25, 5, 35, 60, 80]):
                Q = np.array([on_ala(t, ph) for t in ths], dtype=np.float32)
                out = np.where(before(Q) > 0)[0]
                if len(out):
                    pts.append(on_ala(ths[out[0]] + 0.04, ph))
            # and on over the top toward the tip, fading
            pts += [on_ala(np.pi * 0.55, np.radians(78)), on_ala(np.pi * 0.7, np.radians(70))]
            crease = ribbon(smooth_curve(np.array(pts), 6), lambda t: (0.25 + 0.55 * hump(np.clip(t * 1.3, 0, 1), 0.6)) * MM)
            head = carve_near(1.3 * MM, head, crease, ac, 0.016)
            # the nostril: a hole up into the underside, long toward the tip
            nc = mm(sx * 6.0, self.sn_y + 6.0, self.sn_z + 0.4)
            nostril = S.ellipsoid(nc, mm(2.6, 5.4, 3.2), S.rot(sx * 0.32, 0.2, 0.0))
            head = carve_near(1.2 * MM, head, nostril, nc, 0.008)
        return head

    # -------------------------------------------------------------------------- the mouth
    def arch(self, y_front, y_corner, x):
        return y_front - (y_front - y_corner) * (x / (self.ch_w * MM)) ** 2

    def lip_curve(self, z_mid, y_front, back=15.0, corner=0.0, n=17):
        w = self.ch_w
        pts = []
        for x in np.linspace(-w, w, n):
            y = self.arch(y_front * MM, (y_front - back) * MM, x * MM) / MM
            pts.append((x, y, z_mid + corner * (x / w) ** 2))
        return smooth_curve(np.array(pts) * MM, 6)

    def mouth(self, head):
        w, sto, smile = self.ch_w, self.sto_z, self.smile
        up_z = sto + self.ls_h * 0.45
        lo_z = sto - self.li_h * 0.48
        # the red of each lip: a band along the curve of the teeth, flatter than it is high, fullest
        # in the middle, thinning to the corners (which a smile lifts)
        upper = ribbon2(self.lip_curve(up_z, self.ls_y - 3.0, back=16.0, corner=-3.0 + 3.5 * smile),
                        lambda t: (0.5 + 2.6 * hump(t, 0.6)) * MM, lambda t: (0.8 + self.ls_h * 0.42 * hump(t, 0.5)) * MM)
        lower = ribbon2(self.lip_curve(lo_z, self.li_y - 3.6, back=16.0, corner=3.5 + 2.5 * smile),
                        lambda t: (0.6 + 3.2 * hump(t, 0.8)) * MM, lambda t: (0.9 + self.li_h * 0.44 * hump(t, 0.6)) * MM)
        ctr = mm(0, self.ls_y - 8, sto)
        lips = S.union(upper, lower)
        head = blend_near(2.0 * MM, head, lips, ctr, 0.036)
        self.lips = lips
        # the skin between the nose and the lip, found where it is: the groove down the middle, the
        # pillars either side of it (from under the nose out to the peaks of the bow), the dip in
        # the middle of the bow
        z_top, z_bow = self.sn_z - 3.5, sto + self.ls_h + 0.5
        zs = np.linspace(z_top, z_bow, 5)
        ymid = front_y(head, 0.0, zs * MM) / MM
        gc = mm(0, ymid[2], zs[2])
        head = lift(head, swell(gc, mm(3.2, 3.0, (z_top - z_bow) / 2 + 2.0), -0.5 * MM))
        for sx in (-1.0, 1.0):
            xs = sx * np.linspace(2.8, 5.2, 5)
            yp = front_y(head, xs * MM, zs * MM) / MM
            a, b = mm(xs[1], yp[1] - 1.7, zs[1]), mm(xs[-1], yp[-1] - 1.3, zs[-1])
            head = blend_near(3.0 * MM, head, S.capsule(a, b, 1.6 * MM), (a + b) / 2, 0.012)
        bc = mm(0, front_y(head, 0.0, z_bow * MM)[0] / MM, z_bow)
        head = lift(head, swell(bc, mm(2.4, 3.0, 1.8), -0.6 * MM))

        # the line where they meet, the corners
        def slit(P):
            y_arch = self.arch((self.ls_y - 2.0) * MM, (self.ls_y - 17.0) * MM, P[:, 0])
            zc = sto * MM + (1.5 * smile) * MM * (P[:, 0] / (w * MM)) ** 2
            d = np.abs(P[:, 2] - zc) - 0.5 * MM
            d = np.maximum(d, np.abs(P[:, 0]) - w * MM)
            return np.maximum(d, (y_arch - 7.0 * MM) - P[:, 1])
        head = carve_near(0.7 * MM, head, slit, ctr, 0.036)
        for sx in (-1.0, 1.0):
            cc = mm(sx * (w + 0.5), self.ls_y - 17.0, sto + 1.0 * smile)
            head = carve_near(2.0 * MM, head, S.sphere(cc, 2.0 * MM), cc, 0.004)
        # the hollow between the lower lip and the chin
        fz = sto - self.li_h - 8.0
        fc = mm(0, front_y(head, 0.0, fz * MM)[0] / MM, fz)
        head = lift(head, swell(fc, mm(self.ch_w * 0.8, 10.0, 8.0), -2.6 * MM))
        return head

    # -------------------------------------------------------------------------- the ears
    def ear_frame(self, sx):
        """The ear's own frame: from the opening of the ear (in front of the tragus), `up` along
        the ear leaning back, `fw` forward in the ear's plane (which turns out from the head
        behind, by ear_flare), `nrm` out of it."""
        tilt = np.radians(15)
        T = mm(sx * 71.0, -5.0, -4.0)
        up = V(0, -np.sin(tilt), np.cos(tilt))
        fw = V(0, np.cos(tilt), np.sin(tilt))
        fl = self.ear_flare
        fw2 = norm(fw * np.cos(fl) - V(sx, 0, 0) * np.sin(fl))
        nrm = norm(np.cross(up, fw2))
        if nrm[0] * sx < 0:
            nrm = -nrm
        return T, up, fw2, nrm

    def ear(self, sx):
        """An ear (mm in its own frame: a up it, b forward, c out of it): the rim rolled round the
        top and back, the ridge inside it that forks at the top, the bowl in front of the ridge
        that leads into the head, the flap over the opening, the lobe."""
        T, up, fw2, nrm = self.ear_frame(sx)
        Be = _basis(up, fw2, nrm)
        k = self.ear_len / 63.0
        kw = self.ear_w / 35.0

        def at(a, b, c=0.0):
            return T + up * (a * k * MM) + fw2 * (b * kw * MM) + nrm * (c * MM)

        def curve(pts, n=8):
            return smooth_curve(np.array([at(*p) for p in pts]), n)
        # the body of it, a little cupped
        plate = S.ellipsoid(at(0.0, -14.0, -1.0), mm(29.0 * k, 16.0 * kw, 3.6), Be)
        # the rim: from inside the bowl, up and forward over the opening, over the top, down the
        # back, into the lobe
        helix_pts = [(6, -8, 1.0), (12, -1, 0.5), (20, 0.5, 0.0), (27, -4, 0.0), (29.5, -12, 0.5), (26, -22, 1.0),
                     (17, -28.5, 1.2), (4, -31, 1.2), (-8, -29, 1.0), (-17, -24, 0.6), (-23, -17, 0.2)]
        helix = ribbon(curve(helix_pts), lambda t: (1.4 + 2.5 * np.clip(t * 4, 0, 1) - 0.6 * np.clip((t - 0.75) * 4, 0, 1)) * MM)
        lobe = S.ellipsoid(at(-25.0, -11.0, 0.0), mm(7.5 * k, 9.0 * kw, 3.8), Be)
        ear = S.blend(2.2 * MM, plate, helix, lobe)
        # the hollow just inside the rim
        scapha = ribbon(curve([(22, -8, 4.2), (24, -15, 4.4), (17, -23.5, 4.6), (5, -26, 4.6), (-7, -24.5, 4.4), (-15, -19.5, 4.0)]),
                        lambda t: 2.4 * MM)
        ear = S.carve(ear, scapha, 1.4 * MM)
        # the ridge inside it, forking at the top round a small hollow
        anti = ribbon(curve([(-13, -10, 1.5), (-5, -17, 2.0), (5, -20, 2.2), (13, -18.5, 2.0), (19, -14, 1.6), (23, -9, 1.2), (25, -5, 0.6)]),
                      lambda t: (2.6 - 1.2 * t) * MM)
        crus = ribbon(curve([(18, -14, 1.8), (16, -7, 1.6), (13, -2, 1.0)]), lambda t: (2.0 - 0.8 * t) * MM)
        ear = S.blend(1.4 * MM, ear, anti, crus)
        ear = S.carve(ear, S.ellipsoid(at(20.0, -8.0, 3.6), mm(4.0 * k, 3.5 * kw, 1.6), Be), 1.2 * MM)
        # the bowl, down into the head, and the flaps either side of the opening
        concha = S.ellipsoid(at(-2.0, -5.5, 2.5), mm(11.0 * k, 8.0 * kw, 6.5), Be)
        ear = S.carve(ear, concha, 1.6 * MM)
        tragus = S.ellipsoid(at(-3.0, 1.5, 1.2), mm(5.5 * k, 2.6 * kw, 2.4), Be, )
        antitragus = S.ellipsoid(at(-13.5, -9.0, 1.6), mm(3.6 * k, 4.6 * kw, 2.0), Be)
        ear = S.blend(2.4 * MM, ear, tragus, antitragus)
        # behind it, where it joins the head
        root = S.ellipsoid(at(-2.0, -6.0, -7.0), mm(16.0 * k, 9.0 * kw, 6.0), Be)
        return S.blend(3.0 * MM, ear, root), at(0.0, -12.0, 0.0)

    # -------------------------------------------------------------------------- all of it
    # -------------------------------------------------------------------------- flesh and years
    def on_face(self, head, pts):
        """Points (x, z in mm) laid on the front of the face, as an array of 3D points (metres)."""
        pts = np.asarray(pts, dtype=np.float32)
        y = front_y(head, pts[:, 0] * MM, pts[:, 1] * MM)
        return np.stack([pts[:, 0] * MM, y, pts[:, 1] * MM], axis=1).astype(np.float32)

    def flesh(self, head):
        """What the fat and the years do: the cheeks, the hollows under the cheekbones, jowls and
        a second chin, the folds from the nose past the mouth, the lines across the brow and
        out from the eyes, the bags under them."""
        sm, age, fat = self.smile, self.age, self.fat
        # how lined the face is: the years, more for some (a hard life, the sun)
        wear = min(age * self.lines, 1.2)
        rises = []
        for sx in (-1.0, 1.0):
            # the hollow under the cheekbone
            rises.append(swell2(mm(sx * 54, 52, -48), mm(16, 18, 20), -(self.gaunt * 2.6 - max(fat, 0.0) * 1.6) * MM))
        head = lift(head, *rises)
        for sx in (-1.0, 1.0):
            # the fat over each cheekbone, lifted in a smile
            amt = 0.8 * self.cheeks + 1.0 * sm + 1.0 * max(fat, 0.0)
            if amt > 0.05:
                cc = mm(sx * 40, 62 + 5.0 * amt, -30 + 5 * sm)
                head = blend_near(12 * MM, head, S.ellipsoid(cc, mm(17, 10, 15), S.rot(-sx * 0.5, 0, 0)), cc, 0.04)
            # the jowl, by the chin on the line of the jaw, sagging with the years
            j = 0.6 * age + 1.2 * max(fat, 0.0)
            if j > 0.05:
                jc = self.on_face(head, [(sx * (self.chin_w + 16), self.gn_z + 12 - 3 * age)])[0]
                head = lift(head, swell2(jc + mm(0, -4, -2), mm(13, 12, 12), j * 1.8 * MM))
        if fat > 0.05:
            # under the chin
            dc = mm(0, 40, -112 - 4 * age)
            head = blend_near((16 + 10 * fat) * MM, head, S.ellipsoid(dc, mm(36 + 6 * fat, 30, 9 + 5 * fat)), dc, 0.07)
        # the folds from the wings of the nose down past the corners of the mouth
        nl = 0.25 + 1.2 * wear + 0.8 * sm + 0.3 * max(fat, 0.0)
        for sx in (-1.0, 1.0):
            pts = self.on_face(head, [(sx * (self.al_w + 1.5), self.sn_z + 6), (sx * (self.al_w + 5.5), self.sn_z - 6),
                                      (sx * (self.ch_w + 4.5), self.sto_z + 2), (sx * (self.ch_w + 6.5), self.sto_z - 9)])
            head = lift(head, groove(smooth_curve(pts, 6), 4.5 * MM, lambda t: nl * hump(t, 0.5) * MM))
            if wear > 0.4:
                # the lines down from the corners of the mouth
                pts = self.on_face(head, [(sx * (self.ch_w + 1.5), self.sto_z - 3), (sx * (self.ch_w + 3), self.sto_z - 16)])
                head = lift(head, groove(smooth_curve(pts, 6), 4.0 * MM, lambda t: (wear - 0.4) * 1.0 * hump(t, 0.6) * MM))
        if wear > 0.25:
            # across the brow
            for zz, wide in ((44, 32), (54, 36), (64, 30)):
                pts = self.on_face(head, [(-wide, zz + 1.5), (-wide / 2, zz - 0.5), (0, zz), (wide / 2, zz - 0.5), (wide, zz + 1.5)])
                head = lift(head, groove(smooth_curve(pts, 6), 2.2 * MM, lambda t: (wear - 0.25) * 0.7 * hump(t, 0.6) * MM))
            # out from the eyes
            for sx in (-1.0, 1.0):
                ox = sx * (self.eye_x + 14.5)
                for dz, dx in ((4.0, 6.0), (0.0, 7.5), (-4.0, 6.0)):
                    pts = self.on_face(head, [(ox, self.eye_z + dz * 0.3), (ox + sx * dx, self.eye_z + dz)])
                    head = lift(head, groove(smooth_curve(pts, 4), 1.4 * MM, lambda t: (wear - 0.25) * 0.45 * hump(t, 0.5) * MM))
        if self.bags > 0.05:
            for sx in (-1.0, 1.0):
                bc = self.on_face(head, [(sx * (self.eye_x + 1.0), self.eye_z - 10.5)])[0]
                head = lift(head, swell(bc, mm(10, 6, 4), self.bags * 1.2 * MM))
                pts = self.on_face(head, [(sx * (self.eye_x - 9), self.eye_z - 12), (sx * self.eye_x, self.eye_z - 14.5),
                                          (sx * (self.eye_x + 10), self.eye_z - 12)])
                head = lift(head, groove(smooth_curve(pts, 6), 1.6 * MM, lambda t: self.bags * 0.8 * hump(t, 0.6) * MM))
        if self.frown > 0.05:
            for sx in (-1.0, 1.0):
                pts = self.on_face(head, [(sx * 5.0, 20.0), (sx * 6.5, 32.0)])
                head = lift(head, groove(smooth_curve(pts, 4), 1.4 * MM, lambda t: self.frown * 0.9 * hump(t, 0.6) * MM))
        return head

    def brows(self, skin):
        """The eyebrows: a skin of hair a little over the skin, in the shape of each brow seen
        from the front (from over the inner corner of the eye, rising to over the outside of the
        iris, then tailing off)."""
        ex, ez = self.eye_x, self.eye_z
        lift_ = self.brow_lift - 3.0 * self.frown
        out = []
        for sx in (-1.0, 1.0):
            pts = [(sx * (ex - 16.5), ez + 16.5 + lift_ - 2.0 * self.frown), (sx * (ex - 6), ez + 18.5 + lift_),
                   (sx * (ex + 8), ez + 20.0 + lift_ + self.brow_arch), (sx * (ex + 16), ez + 18.0 + lift_ + 0.5 * self.brow_arch),
                   (sx * (ex + 22), ez + 14.5 + lift_)]
            c2 = smooth_curve(np.array([(x * MM, 0.0, z * MM) for x, z in pts]), 8)
            cn = curve_near(c2)
            th = self.brow_w

            def region(P, cn=cn, th=th):
                Q = P.copy()
                Q[:, 1] = 0.0
                q, t = cn(Q)
                r = (th * (1.0 - 0.62 * t ** 1.5) * (0.82 + 0.18 * np.clip(t / 0.25, 0.0, 1.0))) * 0.5 * MM
                return np.maximum(np.linalg.norm(q, axis=1) - r, 0.040 - P[:, 1])
            out.append(bounded(region, mm(sx * (ex + 3), 80, ez + 17), 0.032))
        reg = S.union(*out)
        shell = S.carve(S.offset(skin, 0.9 * MM), S.offset(skin, -4.0 * MM))
        return within(reg, shell)

    def beard_ground(self):
        """Where a beard grows (a region, not a surface): under a line each side from the bottom
        of the sideburn across the cheek to over the corner of the mouth and the middle of the
        upper lip, in front of the ears, down the throat to the collar; never on the lips."""
        planes = []
        for sx in (-1.0, 1.0):
            A = mm(sx * 64, 0, -8)
            B = mm(sx * (self.ch_w + 8), self.ls_y - 24, self.sn_z - 6)
            C = mm(0, self.sn_y + 2, self.sn_z - 3.5)
            n = norm(np.cross(B - A, C - A))
            if n[2] < 0:
                n = -n
            planes.append(S.halfspace(A, n))
        zone = S.intersect(S.intersect(planes[0], planes[1]), S.halfspace(mm(0, -6, 0), norm(V(0, -1, 0.16))))
        zone = S.intersect(zone, S.halfspace(mm(0, 0, -165), V(0, 0, -1)))
        lc = mm(0, self.ls_y - 8, self.sto_z)
        return S.carve(zone, bounded(S.offset(self.lips, 1.2 * MM), lc, 0.045))

    def beards(self, skin):
        """A full beard and a moustache, as shapes on the skin. The beard is the hair's depth off
        the skin where a beard grows: short up the cheeks and at the sideburns, deeper down the
        jaw, deepest at the chin and under it, and the mouth clear of it, the moustache over the
        upper lip to its red. The moustache alone: from under the nose down over the top of the
        upper lip, fullest in the middle, its ends drooping past the corners of the mouth."""
        # ending under the jaw on a line from behind its angle down to above the Adam's apple
        neckline = S.halfspace(mm(0, 40, -138), norm(V(0, -0.86, -1)))
        zone = S.intersect(self.beard_zone, neckline, 4.0 * MM)

        def deep(P):
            z = P[:, 2] / MM
            d = (2.5 + 1.0 * np.clip((-10.0 - z) / 30.0, 0.0, 1.0) + 5.5 * np.clip((-45.0 - z) / 60.0, 0.0, 1.0)) * MM
            # thinning to nothing at its edges
            return d * np.clip(-zone(P) / (7.0 * MM), 0.0, 1.0) ** 0.6
        beard = S.intersect(lambda P: skin(P) - deep(P), zone, 1.0 * MM)
        mz = self.sto_z + (self.ls_h - self.li_h) / 2.0 - 0.5
        mouth = S.ellipsoid(mm(0, self.ls_y, mz), mm(self.ch_w + 1.0, 22.0, (self.ls_h + self.li_h) / 2.0 + 0.5))
        beard = S.carve(beard, bounded(mouth, mm(0, self.ls_y, mz), 0.04), 2.0 * MM)
        # the moustache
        half = self.ch_w + 1.5

        def band(P):
            x, z = P[:, 0] / MM, P[:, 2] / MM
            u = np.clip(np.abs(x) / half, 0.0, 1.0)
            # (narrowing to its ends, which droop)
            top = self.sn_z - 1.5 - 8.0 * u ** 2 - 2.0 * np.exp(-(x / 4.0) ** 2)
            low = self.sto_z + 0.75 * self.ls_h - 3.5 * u ** 2
            d = np.maximum(np.maximum(z - top, low - z), np.abs(x) - half)
            return np.maximum(d * MM, (self.ls_y - 25.0) * MM - P[:, 1])

        def thick(P):
            u = np.clip(np.abs(P[:, 0]) / (half * MM), 0.0, 1.0)
            # rounded across: full in its middle, thinning to its edges
            return (3.6 - 2.0 * u ** 2) * MM * np.clip(-band(P) / (3.5 * MM), 0.0, 1.0) ** 0.5
        tache = S.intersect(lambda P: skin(P) - thick(P), bounded(band, mm(0, self.ls_y, self.sn_z - 10), 0.05), 0.6 * MM)
        return beard, tache

    def build(self):
        self.lash_bands = []
        head = self.base()
        head = self.nose(head)
        head = self.mouth(head)
        head, eye_parts = self.eyes(head)
        for sx in (-1.0, 1.0):
            ear, E = self.ear(sx)
            head = blend_near(2.5 * MM, head, ear, E, 0.045)
        head = self.flesh(head)
        self.skin = head
        # the red of the lips, a skin over them
        lc = mm(0, self.ls_y - 8, self.sto_z)
        # (the skins laid on the skin reach well down into it, so that however coarse the mesh
        # they come out whole: only their outer face, a fraction of a millimetre proud, shows)
        self.lip_skin = within(bounded(S.offset(self.lips, 0.5 * MM), lc, 0.04),
                               S.carve(S.offset(head, 0.45 * MM), S.offset(head, -4.0 * MM)))
        self.brow_skin = self.brows(head)
        self.lash_skin = within(S.union(*self.lash_bands), S.carve(S.offset(head, 0.5 * MM), S.offset(head, -4.0 * MM)))
        eye_parts.append(('lash', self.lash_skin, 3))
        self.beard_zone = self.beard_ground()
        self.full_beard, self.moustache = self.beards(head)
        self.parts = [('skin', head, 0), ('lip', self.lip_skin, 1), ('brow', self.brow_skin, 2)] + eye_parts
        return self


# ------------------------------------------------------------------------------------ a person's face

def face(sex='m', age=0.35, fat=0.0, seed=None, smile=0.0, frown=0.0, **over):
    """A face's numbers (as AVERAGE) for a man or a woman (sex 'f') of an age (0 at twenty, 1 at
    eighty), lean to heavy (fat -1 to 1), with the small differences everyone has drawn from
    seed (any hashable: their name), and an expression; `over` sets any number outright. A
    woman's head is drawn 0.955 the size of a man's (people.py): what's here is on top of that."""
    fp = dict(AVERAGE)
    if sex == 'f':
        fp.update(brow_y=91.0, nasion_y=86.5, nasion_z=12.5, prn_y=110.0, prn_z=-32.0, sn_y=92.0, al_w=16.2, tip_w=9.5,
                  go_w=50.5, jaw_k=17.0, chin_w=17.0, pg_y=87.5, gn_z=-107.0, me_z=-110.5, zy=68.0,
                  eye_r=12.5, eye_x=32.0, ls_h=9.0, li_h=10.4, ch_w=25.5, larynx=0.15, neck_w=44.0,
                  cheeks=0.65, gaunt=0.25, ear_len=60.0, ear_w=33.5, brow_lift=2.5, brow_arch=3.2, brow_w=7.5, fis_up=4.0,
                  skull_front=101.0, brow_ridge=0.45)
    rng = np.random.default_rng(zlib.crc32(str(seed).encode()) if seed is not None else 0)
    n = lambda sd: float(sd * np.clip(rng.normal(), -2.0, 2.0))
    if seed is not None:
        # the small differences, some of them moving together (a long lower face moves the lips,
        # the chin and the angles of the jaw down together; a longer nose its tip and its base)
        face_h, nose_l, nose_p, chin_p, lip_p = n(4.0), n(3.0), n(2.8), n(2.4), n(1.2)
        fp['sto_z'] -= 0.55 * face_h
        for k_ in ('pg_z', 'gn_z', 'me_z'):
            fp[k_] -= face_h
        fp['go_z'] -= 0.6 * face_h
        fp['sn_z'] -= 0.25 * face_h + 0.3 * nose_l
        fp['prn_z'] -= 0.15 * face_h + 0.8 * nose_l
        fp['prn_y'] += nose_p + 0.3 * nose_l
        fp['pg_y'] += chin_p
        fp['me_y'] += 0.8 * chin_p
        fp['ls_y'] += lip_p
        fp['li_y'] += lip_p
        SD = dict(skull_w=3.0, skull_front=3.0, skull_back=4.0, skull_top=4.0, brow_y=1.6, nasion_y=1.6, nasion_z=1.8, zy=2.8,
                  go_w=3.5, chin_w=2.2, eye_x=1.2, eye_z=1.2, eye_y=1.0, fis_up=0.5, fis_low=0.5, sn_y=1.4, al_w=1.6,
                  tip_w=0.9, dorsum=1.1, ch_w=2.2, ls_h=1.0, li_h=1.0, ear_len=3.2, ear_w=2.0, ear_flare=0.09,
                  neck_w=2.5, brow_lift=1.4, brow_arch=1.0, brow_w=1.0, cheeks=0.12, gaunt=0.1)
        for k_, sd in SD.items():
            fp[k_] += n(sd)
        tilt = n(1.1)
        fp['fis_out'] = (fp['fis_out'][0], fp['fis_out'][1] + tilt)
        if rng.random() < 0.15:
            fp['crooked'] = n(1.6)
    # the years
    a = float(np.clip(age, 0.0, 1.0))
    fp['age'] = a
    fp['ear_len'] += 6.0 * a
    fp['ear_w'] += 2.0 * a
    fp['prn_z'] -= 2.5 * a
    fp['prn_y'] += 1.5 * a
    fp['tip_w'] += 1.0 * a
    fp['ls_h'] -= 2.2 * a
    fp['li_h'] -= 2.0 * a
    fp['ls_y'] -= 1.2 * a
    fp['hood'] = max(fp['hood'], 0.9 * a - 0.2)
    fp['bags'] = max(fp['bags'], 0.9 * a - 0.15)
    fp['brow_lift'] -= 2.0 * a
    fp['cheeks'] *= 1.0 - 0.6 * a
    fp['gaunt'] += 0.3 * a
    fp['under_k'] += 8.0 * a
    fp['jaw_k'] += 4.0 * a
    fp['larynx'] *= 1.0 + 0.3 * a
    # fat or lean
    fp['fat'] = float(fat)
    if fat > 0:
        fp['go_w'] += 4.0 * fat
        fp['zy'] += 2.0 * fat
        fp['neck_w'] += 7.0 * fat
        fp['jaw_k'] += 8.0 * fat
        fp['under_k'] += 10.0 * fat
        fp['cheeks'] += 0.5 * fat
        fp['larynx'] *= 1.0 - 0.6 * fat
    else:
        fp['gaunt'] -= 0.5 * fat
        fp['jaw_k'] += 3.0 * fat
        fp['cheeks'] += 0.4 * fat
    fp['gaunt'] = max(fp['gaunt'], 0.0)
    fp['cheeks'] = max(fp['cheeks'], 0.0)
    fp['smile'], fp['frown'] = smile, frown
    if smile:
        fp['fis_low'] -= 1.2 * smile
    fp.update(over)
    return fp
