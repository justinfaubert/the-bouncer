"""Signed distance fields in numpy, for sculpting people and soft things in code.

A shape is a function of points P (N x 3, metres) that returns the signed distance to its surface:
negative inside, positive outside. Build shapes from the primitives here, join them with union,
blend (a smooth union), carve (a smooth subtraction), then mesh the result with `mesh()`, which runs
marching cubes over a grid and returns vertices, faces and, for each face, which material it is.

Coordinates are Blender's: z up, the figure's front toward +y.
"""
import numpy as np
from skimage import measure


def _v(x):
    return np.asarray(x, dtype=np.float32)


def rot(yaw=0.0, pitch=0.0, roll=0.0):
    """A rotation matrix: yaw about z, then pitch about x, then roll about y (radians)."""
    cz, sz = np.cos(yaw), np.sin(yaw)
    cx, sx = np.cos(pitch), np.sin(pitch)
    cy, sy = np.cos(roll), np.sin(roll)
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    return (Rz @ Rx @ Ry).astype(np.float32)


def frame(x_axis, y_axis):
    """A rotation whose local x and y point along the given directions (z completes it)."""
    x = _v(x_axis) / np.linalg.norm(x_axis)
    y = _v(y_axis) - x * np.dot(x, y_axis)
    y /= np.linalg.norm(y)
    z = np.cross(x, y)
    return np.stack([x, y, z], axis=1).astype(np.float32)


# ------------------------------------------------------------------ primitives

def sphere(c, r):
    c = _v(c)
    return lambda P: np.linalg.norm(P - c, axis=1) - r


def ellipsoid(c, radii, R=None):
    """An ellipsoid (a close, cheap approximation of its distance)."""
    c, radii = _v(c), _v(radii)
    def f(P):
        q = P - c
        if R is not None:
            q = q @ R
        k0 = np.linalg.norm(q / radii, axis=1)
        k1 = np.linalg.norm(q / (radii * radii), axis=1)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)
    return f


def cone(a, b, ra, rb):
    """A capsule from a to b whose radius runs from ra to rb (a round cone): limbs, fingers."""
    a, b = _v(a), _v(b)
    ba = b - a
    l2 = float(np.dot(ba, ba))
    rr = ra - rb
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    def f(P):
        pa = P - a
        y = pa @ ba
        z = y - l2
        x2v = pa * l2 - y[:, None] * ba[None, :]
        x2 = (x2v * x2v).sum(axis=1)
        y2 = y * y * l2
        z2 = z * z * l2
        k = np.sign(rr) * rr * rr * x2
        out = (np.sqrt(np.maximum(x2 * a2 * il2, 0.0)) + y * rr) * il2 - ra
        m2 = np.sign(y) * a2 * y2 < k
        out = np.where(m2, np.sqrt(x2 + y2) * il2 - ra, out)
        m1 = np.sign(z) * a2 * z2 > k
        out = np.where(m1, np.sqrt(x2 + z2) * il2 - rb, out)
        return out
    return f


def capsule(a, b, r):
    return cone(a, b, r, r)


def box(c, half, radius=0.0, R=None):
    """A box with rounded edges, half-extents `half`, edge radius `radius`."""
    c, half = _v(c), _v(half)
    def f(P):
        q = P - c
        if R is not None:
            q = q @ R
        d = np.abs(q) - (half - radius)
        return np.linalg.norm(np.maximum(d, 0.0), axis=1) + np.minimum(np.max(d, axis=1), 0.0) - radius
    return f


def torus(c, R_major, r_minor, R=None):
    """A ring round local z."""
    c = _v(c)
    def f(P):
        q = P - c
        if R is not None:
            q = q @ R
        xy = np.sqrt(q[:, 0] ** 2 + q[:, 1] ** 2) - R_major
        return np.sqrt(xy * xy + q[:, 2] ** 2) - r_minor
    return f


def cylinder(a, b, r, radius=0.0):
    """A flat-ended cylinder from a to b, its rims rounded by `radius`."""
    a, b = _v(a), _v(b)
    ba = b - a
    h = np.linalg.norm(ba)
    ax = ba / h
    mid = (a + b) / 2
    def f(P):
        q = P - mid
        y = q @ ax
        x = np.linalg.norm(q - y[:, None] * ax[None, :], axis=1)
        d = np.stack([x - (r - radius), np.abs(y) - (h / 2 - radius)], axis=1)
        return np.linalg.norm(np.maximum(d, 0.0), axis=1) + np.minimum(np.max(d, axis=1), 0.0) - radius
    return f


# ------------------------------------------------------------------ combining

def union(*fs):
    def f(P):
        out = fs[0](P)
        for g in fs[1:]:
            out = np.minimum(out, g(P))
        return out
    return f


def _smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


def blend(k, *fs):
    """A smooth union: the shapes melt together over about k metres."""
    def f(P):
        out = fs[0](P)
        for g in fs[1:]:
            out = _smin(out, g(P), k)
        return out
    return f


def carve(a, b, k=0.0):
    """a with b cut out of it, the cut's edge softened over k."""
    def f(P):
        da, db = a(P), b(P)
        if k <= 0.0:
            return np.maximum(da, -db)
        return -_smin(-da, db, k)
    return f


def intersect(a, b, k=0.0):
    def f(P):
        da, db = a(P), b(P)
        if k <= 0.0:
            return np.maximum(da, db)
        return -_smin(-da, -db, k)
    return f


def shell(f, t):
    """A skin of thickness t on f's surface."""
    return lambda P: np.abs(f(P)) - t / 2.0


def offset(f, d):
    """Grow (d > 0) or shrink the shape."""
    return lambda P: f(P) - d


def ripple(f, amp, freq, axis=(0, 0, 1), phase=0.0):
    """Waves along an axis: bunched cloth, ribbing."""
    ax = _v(axis) / np.linalg.norm(axis)
    return lambda P: f(P) + amp * np.sin((P @ ax) * freq + phase)


def warp(f, fn):
    """Evaluate f at points moved by fn (P -> P')."""
    return lambda P: f(fn(P))


# ------------------------------------------------------------------ meshing

class Part:
    """A shape with a material name. The figure is the union of its parts; each face of the mesh
    takes the material of the nearest part."""
    def __init__(self, name, f, blend_k=0.0, order=0):
        self.name, self.f, self.k, self.order = name, f, blend_k, order


def solid(parts, k=0.0):
    fs = [p.f for p in parts]
    return blend(k, *fs) if k > 0 else union(*fs)


def mesh(parts, lo, hi, step, k=0.0, smooth_iters=2):
    """Marching cubes over the box lo..hi at `step` metres. Returns verts (V x 3), faces (F x 3)
    and a material index per face (into the list of distinct part names, also returned)."""
    lo, hi = _v(lo), _v(hi)
    n = np.ceil((hi - lo) / step).astype(int) + 1
    xs = [lo[i] + np.arange(n[i], dtype=np.float32) * step for i in range(3)]
    X, Y, Z = np.meshgrid(*xs, indexing='ij')
    P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    f = solid(parts, k)
    D = np.empty(len(P), dtype=np.float32)
    for s in range(0, len(P), 2_000_000):
        D[s:s + 2_000_000] = f(P[s:s + 2_000_000])
    D = D.reshape(n)
    verts, faces, normals, _ = measure.marching_cubes(D, 0.0, spacing=(step, step, step))
    verts = verts.astype(np.float32) + lo
    if smooth_iters:
        verts = taubin(verts, faces, smooth_iters)
    names = []
    for p in parts:
        if p.name not in names:
            names.append(p.name)
    # which part is each face nearest to
    cent = verts[faces].mean(axis=1)
    best = np.full(len(cent), np.inf, dtype=np.float32)
    mat = np.zeros(len(cent), dtype=np.int32)
    for p in sorted(parts, key=lambda p: p.order):
        d = p.f(cent) - 0.0015 * p.order                     # higher order wins a near tie
        better = d < best
        best = np.where(better, d, best)
        mat = np.where(better, names.index(p.name), mat)
    return verts, faces.astype(np.int32), mat, names


def taubin(verts, faces, iters=2, lam=0.5, mu=-0.53):
    """Smooths away the marching cubes' faint terracing without shrinking the shape."""
    n = len(verts)
    e = np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]])
    e = np.concatenate([e, e[:, ::-1]])
    deg = np.bincount(e[:, 0], minlength=n).astype(np.float32)
    v = verts.copy()
    for _ in range(iters):
        for w in (lam, mu):
            s = np.zeros_like(v)
            np.add.at(s, e[:, 0], v[e[:, 1]])
            avg = s / np.maximum(deg, 1)[:, None]
            v = v + w * (avg - v)
    return v


def mesh_islands(parts, lo, hi, step, smooth_iters=2):
    """Like mesh(), but each material is meshed as a surface of its own: the union of that
    material's parts. Where two materials meet, their surfaces simply pass through each other, so
    the seam is drawn by the depth test, clean, instead of following the triangles' edges (a
    sawtooth). Each material's surface is only meshed inside the box where it is, found first on
    a grid four times coarser. Returns verts, faces, material per face and material names."""
    lo, hi = _v(lo), _v(hi)
    names = []
    for p in parts:
        if p.name not in names:
            names.append(p.name)
    V_all, F_all, M_all, base = [], [], [], 0
    for mi, name in enumerate(names):
        f = union(*[p.f for p in parts if p.name == name])
        # where is it? a coarse look first
        cs = step * 4
        n = np.ceil((hi - lo) / cs).astype(int) + 1
        xs = [lo[i] + np.arange(n[i], dtype=np.float32) * cs for i in range(3)]
        X, Y, Z = np.meshgrid(*xs, indexing='ij')
        P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
        d = f(P).reshape(n)
        near = np.argwhere(d < cs * 1.8)
        if len(near) == 0:
            continue
        blo = np.maximum(lo, lo + (near.min(axis=0) - 1) * cs)
        bhi = np.minimum(hi, lo + (near.max(axis=0) + 1) * cs)
        n = np.ceil((bhi - blo) / step).astype(int) + 1
        if (n < 2).any():
            continue
        xs = [blo[i] + np.arange(n[i], dtype=np.float32) * step for i in range(3)]
        X, Y, Z = np.meshgrid(*xs, indexing='ij')
        P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
        D = np.empty(len(P), dtype=np.float32)
        for s in range(0, len(P), 2_000_000):
            D[s:s + 2_000_000] = f(P[s:s + 2_000_000])
        D = D.reshape(n)
        if D.min() >= 0 or D.max() <= 0:
            continue
        verts, faces, _, _ = measure.marching_cubes(D, 0.0, spacing=(step, step, step))
        verts = verts.astype(np.float32) + blo
        if smooth_iters:
            verts = taubin(verts, faces, smooth_iters)
        V_all.append(verts)
        F_all.append(faces.astype(np.int32) + base)
        M_all.append(np.full(len(faces), mi, dtype=np.int32))
        base += len(verts)
    return np.concatenate(V_all), np.concatenate(F_all), np.concatenate(M_all), names
