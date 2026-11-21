"""Heads from MakeHuman's human (round five, second start, PROPOSED). Hutch on the hand-sculpted
head (21 November 2026): "the proportions are still off and kind of uncanny ... the face is too
flat, she should be gorgeous ... if you need to start from scratch or do some research that's
okay". So the head starts from a professionally modelled human instead: MakeHuman's base mesh and
its morph targets (released CC0, the licence in their repository: "the base mesh and proxies,
targets and modifiers"). A person here is a recipe of targets: the mix of who her forebears were,
then her own face, feature by feature (her cheekbones up, her eyes lifted at the outer corners, her
lips fuller). What's sculpted on top of it (lids that close, a jaw that drops, brows and lashes hair
by hair, the skin's picture) is tools/sculpt.py's, given the head's own measures from here.

The assets are fetched once into a cache (~/.cache/lastcall-makehuman) from MakeHuman's GitHub.

Numpy only; masks.py does the Blender side (the surface queries need its BVH tree).
"""
import os
import urllib.request

import numpy as np

SRC = 'https://raw.githubusercontent.com/makehumancommunity/makehuman/master/makehuman/data/'
CACHE = os.path.expanduser('~/.cache/lastcall-makehuman')

# Who they are, as MakeHuman targets. race: the mix of the three race targets (they carry the
# gender and age, and sum to 1); body: the mix of build (muscle and weight; the plain average if
# left out); face: target name -> weight
RECIPES = {
    # Amanda: German, and the game's measure of a beautiful face (Hutch: "very objectively
    # beautiful and more european looking"; the first mix of forebears read South Asian). A long
    # face, the skull not tall or round over it (Hutch: "too conical", "like a grey alien head"),
    # narrow at the temples, high prominent cheekbones, a jaw with a line to it rather than a
    # point; almond eyes, "beautiful and beguiling", lifted at the outer corners, larger than life; a
    # straight fine nose with a neat tip, full lips with a clear bow, a long slim neck (Hutch, on
    # the first of her: "eyes a little bigger, lips a little fuller")
    'amanda': dict(
        race={'caucasian': 1.0, 'asian': 0.0, 'african': 0.0},
        body={'averagemuscle-minweight': 0.7, 'averagemuscle-averageweight': 0.3},
        face={'head/head-oval': 0.6, 'head/head-scale-vert-incr': 0.4,
              'head/head-back-scale-depth-decr': 0.4, 'head/head-age-incr': 0.15,
              'forehead/forehead-scale-vert-decr': 0.5, 'forehead/forehead-temple-decr': 0.6,
              'cheek/l-cheek-bones-incr': 0.9, 'cheek/r-cheek-bones-incr': 0.9,
              'cheek/l-cheek-volume-decr': 0.3, 'cheek/r-cheek-volume-decr': 0.3,
              'cheek/l-cheek-trans-up': 0.7, 'cheek/r-cheek-trans-up': 0.7,
              'eyes/l-eye-scale-incr': 1.0, 'eyes/r-eye-scale-incr': 1.0,
              'eyes/l-eye-height2-incr': 0.35, 'eyes/r-eye-height2-incr': 0.35,
              'eyes/l-eye-corner2-up': 0.65, 'eyes/r-eye-corner2-up': 0.65,
              'eyes/l-eye-trans-out': 0.3, 'eyes/r-eye-trans-out': 0.3,
              'eyes/l-eye-eyefold-angle-up': 0.5, 'eyes/r-eye-eyefold-angle-up': 0.5,
              'eyes/l-eye-corner1-down': 0.4, 'eyes/r-eye-corner1-down': 0.4,
              'eyes/l-eye-height3-decr': 0.4, 'eyes/r-eye-height3-decr': 0.4,
              'eyes/l-eye-push1-in': 0.3, 'eyes/r-eye-push1-in': 0.3,
              'nose/nose-scale-horiz-decr': 0.45, 'nose/nose-scale-vert-decr': 0.4,
              'nose/nose-trans-forward': 0.3, 'nose/nose-point-width-decr': 0.6,
              'nose/nose-nostrils-width-decr': 0.5, 'nose/nose-point-up': 0.4,
              'nose/nose-hump-decr': 0.5, 'nose/nose-volume-decr': 0.3,
              'mouth/mouth-trans-up': 0.4, 'mouth/mouth-scale-horiz-incr': 0.3,
              'mouth/mouth-lowerlip-volume-incr': 1.0, 'mouth/mouth-upperlip-volume-incr': 1.0,
              'mouth/mouth-cupidsbow-incr': 0.6, 'mouth/mouth-angles-up': 0.3,
              'chin/chin-prominent-incr': 0.35, 'chin/chin-height-decr': 0.2,
              'neck/neck-scale-horiz-decr': 0.4}),
}


def fetch(rel):
    path = os.path.join(CACHE, rel)
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        urllib.request.urlretrieve(SRC + rel, path)
    return path


def load_base():
    """The base mesh: vertices (MakeHuman's units and axes), faces with their groups."""
    V, F, G = [], [], []
    g = None
    for line in open(fetch('3dobjs/base.obj')):
        if line.startswith('v '):
            V.append([float(x) for x in line.split()[1:4]])
        elif line.startswith('g '):
            g = line.split()[1]
        elif line.startswith('f '):
            F.append([int(p.split('/')[0]) - 1 for p in line.split()[1:]])
            G.append(g)
    return np.array(V), F, G


def target(rel):
    idx, off = [], []
    for line in open(fetch('targets/' + rel + '.target')):
        if line.startswith('#') or not line.strip():
            continue
        a = line.split()
        idx.append(int(a[0]))
        off.append([float(x) for x in a[1:4]])
    return np.array(idx, int), np.array(off)


def build(name):
    """The person's whole MakeHuman body, morphed, in metres and in the sculptor's axes (x to
    their left, f forward, z up), with its faces and groups."""
    r = RECIPES[name]
    V, F, G = load_base()
    tw = {f'macrodetails/{k}-female-young': w for k, w in r['race'].items()}
    tw['macrodetails/proportions/female-young-averagemuscle-averageweight-idealproportions'] = 1.0
    for k, w in r.get('body', {'averagemuscle-averageweight': 1.0}).items():
        tw[f'macrodetails/universal-female-young-{k}'] = w
    tw.update(r['face'])
    for rel, w in tw.items():
        i, o = target(rel)
        if len(i):                                     # some are empty: the reference shape itself
            V[i] += w * o
    V = V * 0.1
    X = np.stack([V[:, 0], V[:, 2], V[:, 1]], 1)       # MakeHuman: y up, z forward
    return X, F, G


def group_verts(F, G, name):
    return sorted({v for f, g in zip(F, G) if g == name for v in f})


def head_part(X, F, G, neck=0.15):
    """The head and the neck down to `neck` below the eyes, from the body: vertices re-indexed,
    quads and triangles, and the eyes' middles and radii."""
    eyes = []
    for g in ('helper-l-eye', 'helper-r-eye'):
        P = X[group_verts(F, G, g)]
        eyes.append(P.mean(0))
    ez = (eyes[0][2] + eyes[1][2]) / 2
    keep = [f for f, g in zip(F, G) if g == 'body' and min(X[v][2] for v in f) > ez - neck]
    used = sorted({v for f in keep for v in f})
    remap = {v: i for i, v in enumerate(used)}
    return X[used], [[remap[v] for v in f] for f in keep], eyes
