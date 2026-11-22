"""Fit a person's MakeHuman recipe (tools/human.py) to measurements of beautiful faces.

Amanda is the game's measure of beauty (Hutch: "very objectively beautiful"; "find the real
mathematical measurements of their heads and faces"). Her head is measured the way the
anthropometry papers measure, in millimetres, and the recipe's weights are moved (damped least
squares, each step kept only if it helps) until the measures sit on the targets:

  the 3D anthropometry of 66 Miss Italia 2010 contestants (Galantucci et al., "Three-dimensional
  anthropometric database of attractive caucasian women", J Craniofac Surg 2016), and Pallett,
  Link and Lee, "New 'golden' ratios for facial beauty" (Vision Research 2010)

  python3 tools/fit_face.py            prints the measures and the fitted weights, writes
                                       /tmp/fit_face.json (paste what's wanted into RECIPES)
  python3 tools/fit_face.py --measure  only the measures

The eye's opening is measured where the eyeball itself shows, so its corners can't reach the
papers' canthi (they lie past the eyeball's edge): the fit aims it near its widest instead.
"""
import json
import os
import sys

import bpy  # noqa: F401 (first: masks needs it)
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import human  # noqa: E402
import masks  # noqa: E402
import sculpt  # noqa: E402

# Galantucci et al. 2016 (Miss Italia 2010, 3D anthropometry), means and SDs, mm
MEAN = dict(exex=84.01, enen=30.51, fissure=27.66, pupil=59.12, mouth=45.70, verm=17.97,
            n_sn=50.29, sn_me=61.25, sn_pg=48.14, nose=31.61, jaw_ratio=0.71, eye_h=10.2)
SD0 = dict(exex=2.98, enen=2.03, fissure=1.4, pupil=2.43, mouth=2.77, verm=2.29,
          n_sn=2.43, sn_me=2.88, sn_pg=2.65, nose=1.88, jaw_ratio=0.03, eye_h=0.8)


def measure():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    H, ob = masks.human_head(masks.PEOPLE['amanda'], 'amanda', ['a', 'b', 'c'])
    V = masks.xfz(ob)
    s = H['surface']
    e, m, L = H['eye'], H['mouth'], H['lip_line']
    out = {}
    out['pupil'] = 2 * e['x']
    ug, top, bot = H['lids']
    vi, vo = (top[0] + bot[0]) / 2, (top[-1] + bot[-1]) / 2
    # the eye's corners as a photograph sees them: looking straight at the face, where the first
    # thing met is the eyeball (inside its sphere), furthest in and out
    c = np.array([e['x'], e['f'], e['z']])
    pts = []
    for x in np.arange(c[0] - 0.022, c[0] + 0.024, 0.0004):
        for z in np.arange(c[2] - 0.012, c[2] + 0.012, 0.0004):
            hit = s.on_face(x, z)
            if np.linalg.norm(hit - c) < e['r'] + 0.0002 or hit[1] < c[1] - e['r']:
                pts.append(np.array([x, c[1], z]))
    pts = np.array(pts)
    en, ex = pts[np.argmin(pts[:, 0])], pts[np.argmax(pts[:, 0])]
    out['eye_h'] = pts[:, 2].max() - pts[:, 2].min()
    out['enen'], out['exex'] = 2 * en[0], 2 * ex[0]
    out['fissure'] = float(np.linalg.norm(ex - en))
    out['mouth'] = 2 * L[-1, 0]
    out['verm'] = L[0, 2] - L[0, 3]
    zs = np.arange(-0.13, 0.04, 0.0005)
    p = np.array([s.on_face(0.0, z)[1] for z in zs])
    # nasion: the deepest point between the brows and the nose
    i = np.where((zs > e['z'] + 0.004) & (zs < e['z'] + 0.035))[0]
    ridge = zs[i[np.argmax(p[i])]]
    i = np.where((zs > e['z'] - 0.012) & (zs < ridge))[0]
    n_z = zs[i[np.argmin(p[i])]]
    # subnasale: the deepest point between the nose's tip and the upper lip
    tip = zs[np.argmax(np.where((zs > -0.05) & (zs < e['z']), p, -1))]
    i = np.where((zs > L[0, 2]) & (zs < tip))[0]
    sn_z = zs[i[np.argmin(p[i])]]
    # pogonion, the chin's most forward point; menton, its lowest (where the profile turns under)
    i = np.where((zs < L[0, 3] - 0.006) & (zs > L[0, 3] - 0.04))[0]
    pg = i[np.argmax(p[i])]
    j = pg
    while j > 0 and p[j - 1] > p[pg] - 0.010:
        j -= 1
    me_z = zs[j]
    out['n_sn'], out['sn_me'], out['sn_pg'] = n_z - sn_z, sn_z - me_z, sn_z - zs[pg]
    # the nose's width: across just above the subnasale, out to where its wing meets the cheek
    xs = np.arange(0.0, 0.03, 0.0003)
    q = np.array([s.on_face(x, sn_z + 0.004)[1] for x in xs])
    d2 = np.gradient(np.gradient(q))
    k = np.argmax(np.where((xs > 0.008) & (xs < 0.025), d2, -1))
    out['nose'] = 2 * xs[k]
    # the jaw: its width at the angle, about a third of the way up from the chin to the ear
    zj = me_z + 0.4 * (H['ear']['z'] - 0.02 - me_z)
    sel = (np.abs(V[:, 2] - zj) < 0.0012) & (V[:, 1] > H['ear']['f'] + 0.008)
    out['jaw'] = 2 * np.abs(V[sel, 0]).max()
    # the cheekbones' width, in front of the ears, a little under the eyes
    sel = (V[:, 2] > e['z'] - 0.03) & (V[:, 2] < e['z']) & (V[:, 1] > H['ear']['f'] + 0.03)
    out['zygo'] = 2 * np.abs(V[sel, 0]).max()
    out['jaw_ratio'] = out['jaw'] / out['zygo'] / 1000
    return {k: float(v) * 1000 for k, v in out.items()}



# signed parameters: name -> (target if negative, target if positive); l/r both set
P = {
    'eye-scale': ('eyes/%s-eye-scale-decr', 'eyes/%s-eye-scale-incr'),
    'eye-trans': ('eyes/%s-eye-trans-in', 'eyes/%s-eye-trans-out'),
    'eye-push1': ('eyes/%s-eye-push1-in', 'eyes/%s-eye-push1-out'),
    'eye-push2': ('eyes/%s-eye-push2-in', 'eyes/%s-eye-push2-out'),
    'eye-epicanthus': ('eyes/%s-eye-epicanthus-in', 'eyes/%s-eye-epicanthus-out'),
    'head-shape': ('head/head-square', 'head/head-invertedtriangular'),
    'cheek-bones': ('cheek/%s-cheek-bones-decr', 'cheek/%s-cheek-bones-incr'),
    'chin-height': ('chin/chin-height-decr', 'chin/chin-height-incr'),
    'chin-width': ('chin/chin-width-decr', 'chin/chin-width-incr'),
    'chin-bones': ('chin/chin-bones-decr', 'chin/chin-bones-incr'),
    'chin-prominent': ('chin/chin-prominent-decr', 'chin/chin-prominent-incr'),
    'mouth-scale-horiz': ('mouth/mouth-scale-horiz-decr', 'mouth/mouth-scale-horiz-incr'),
    'mouth-trans-v': ('mouth/mouth-trans-down', 'mouth/mouth-trans-up'),
    'lowerlip': ('mouth/mouth-lowerlip-volume-decr', 'mouth/mouth-lowerlip-volume-incr'),
    'upperlip': ('mouth/mouth-upperlip-volume-decr', 'mouth/mouth-upperlip-volume-incr'),
    'nose-scale-horiz': ('nose/nose-scale-horiz-decr', 'nose/nose-scale-horiz-incr'),
    'nose-scale-vert': ('nose/nose-scale-vert-decr', 'nose/nose-scale-vert-incr'),
    'nose-trans-v': ('nose/nose-trans-down', 'nose/nose-trans-up'),
}
# what to aim for: the Miss Italia means, a little past them where beauty is known to lean
# (eyes a little longer, lips a little fuller, the jaw a little lighter)
# (the eye's opening is measured where the eyeball itself shows, which can't pass its diameter,
# so its corners aren't the papers' canthi: aim for the opening near its widest instead)
TARGET = dict(MEAN, fissure=23.0, verm=19.5, jaw_ratio=0.68, eye_h=10.2)
SD = dict(SD0, eye_h=0.8, fissure=1.0)
for k in ('enen', 'exex'):
    TARGET.pop(k)
KEYS = list(TARGET)
FACE = human.RECIPES['amanda']['face']


def names(p):
    lo, hi = P[p]
    out = []
    for t in (lo, hi):
        out.append([t % s for s in ('l', 'r')] if '%s' in t else [t])
    return out


def get(p):
    lo, hi = names(p)
    if FACE.get(hi[0]):
        return FACE[hi[0]]
    return -FACE.get(lo[0], 0.0)


def put(p, w):
    lo, hi = names(p)
    for n in lo + hi:
        FACE.pop(n, None)
    for n in (hi if w > 0 else lo):
        if abs(w) > 1e-4:
            FACE[n] = round(abs(float(w)), 3)


def resid(r):
    return np.array([(r[k] - TARGET[k]) / SD[k] for k in KEYS])


def fit():
    params = list(P)
    w = np.array([get(p) for p in params])
    w0 = w.copy()
    lam = 1.0

    def cost_at(w):
        for p, x in zip(params, w):
            put(p, x)
        r = measure()
        f = resid(r)
        return float(f @ f) + 0.3 * float((w - w0) @ (w - w0)), f, r

    c0, f0, r0 = cost_at(w)
    for it in range(3):
        print('iter', it, 'cost', round(c0, 2), {k: round(r0[k], 1) for k in KEYS}, flush=True)
        J = np.zeros((len(KEYS), len(params)))
        for j, p in enumerate(params):
            h = 0.2 if w[j] < 0.8 else -0.2
            wj = w.copy()
            wj[j] += h
            J[:, j] = (cost_at(wj)[1] - f0) / h
        A = J.T @ J + lam * np.eye(len(params))
        step = np.linalg.solve(A, -J.T @ f0 - 0.3 * (w - w0))
        for k in range(4):
            wn = np.clip(w + step, -1.0, 1.0)
            cn, fn, rn = cost_at(wn)
            if cn < c0:
                w, c0, f0, r0 = wn, cn, fn, rn
                break
            step *= 0.5
    for p, x in zip(params, w):
        put(p, x)
    r = measure()
    f = resid(r)
    print('final cost', round(float(f @ f), 2))
    for k in KEYS:
        print('%-10s %6.1f target %6.1f z %+.1f' % (k, r[k], TARGET[k], (r[k] - TARGET[k]) / SD[k]))
    print(json.dumps({p: round(float(x), 3) for p, x in zip(params, w)}))
    json.dump(FACE, open('/tmp/fit_face.json', 'w'), indent=1)


if __name__ == '__main__':
    if '--measure' in sys.argv:
        r = measure()
        for k in KEYS:
            print('%-10s %6.1f  target %6.1f' % (k, r[k], TARGET[k]))
    else:
        fit()
