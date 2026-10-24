"""The people in the room, sculpted in code.

Each person is built from a `look`, the same one the browser build draws its faces from
(content/data/characters.yaml: build, hair, hat, face, top, sex, age), and a pose. The figure is a
signed distance field (tools/sdf.py): a skeleton, the body fleshed out round it in soft shapes,
their clothes as parts with their own materials, and a head with its own face. It's meshed with
marching cubes, cleaned up and exported as a .glb by Blender (tools/export_people.py).

Coordinates are Blender's: z up, the person facing +y (which becomes Godot's -z, its forward), so
their right hand is on the +x side. The origin is on the floor between their feet, or under the
seat for someone sitting.
"""
import numpy as np
import sdf as S
import head as HD
from sdf import Part

V = lambda *a: np.array(a, dtype=np.float32)


def norm(v):
    return v / (np.linalg.norm(v) + 1e-9)


def ik(root, target, l1, l2, pole):
    """Where the middle joint (elbow, knee) goes for a two-bone limb reaching from root to
    target, bending toward the pole."""
    d = target - root
    dist = np.linalg.norm(d)
    dist = np.clip(dist, abs(l1 - l2) + 1e-3, (l1 + l2) * 0.999)
    u = d / (np.linalg.norm(d) + 1e-9)
    a = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist)
    h = np.sqrt(max(l1 * l1 - a * a, 0.0))
    pv = pole - root
    pv = norm(pv - u * np.dot(pv, u))
    return root + u * a + pv * h


def reach(root, target, length):
    """The target, pulled in if it's further than the limb reaches."""
    d = target - root
    n = np.linalg.norm(d)
    return target if n <= length * 0.999 else root + d / n * length * 0.999


# ---------------------------------------------------------------------------------------- build

class Build:
    """Proportions. `size` scales the whole body (1 = 1.78 m), `bulk` its girth, `belly` the gut."""
    def __init__(self, look):
        b = look.get('build', 'medium')
        self.f = look.get('sex') == 'f'
        self.old = look.get('age') == 'old'
        self.young = look.get('age') == 'young'
        self.size = {'slight': 0.95, 'medium': 1.0, 'big': 1.08}[b] * (0.93 if self.f else 1.0)
        self.bulk = {'slight': 0.88, 'medium': 1.0, 'big': 1.3}[b] * (0.9 if self.f else 1.0)
        self.belly = {'slight': 0.0, 'medium': 0.015, 'big': 0.06}[b] + (0.035 if self.old else 0.0) - (0.01 if self.young else 0.0)
        self.shoulder = 0.185 * (0.9 if self.f else 1.0) * (1.12 if b == 'big' else 1.0) * look.get('shoulders', 1.0)
        self.chest = look.get('chest', 1.0)          # the chest's girth: under 1 for a thin one
        self.hands = look.get('hands', 1.0)
        if 'size' in look:
            self.size *= look['size']
        if 'bulk' in look:
            self.bulk *= look['bulk']
        if 'belly' in look:
            self.belly = look['belly']
        s = self.size
        self.upper_arm, self.forearm = 0.30 * s, 0.265 * s
        self.thigh, self.shin = 0.445 * s, 0.415 * s


# ---------------------------------------------------------------------------------------- poses

class Pose:
    """Joint positions. Built by a pose function from a Build."""
    pass


def _base(B, pelvis, lean=0.0, twist=0.0, head_turn=0.0, head_tilt=0.0, head_roll=0.0, slump=0.0, hunch=0.0, tilt=0.0):
    """The trunk: pelvis at `pelvis`, the chest leaning forward by `lean` radians, turned by
    `twist` about the spine; the head turned (yaw), tilted (down is positive) and rolled. `hunch`
    (0..1) draws the shoulders up and forward and pokes the head out, against the cold."""
    s = B.size
    p = Pose()
    p.pelvis = V(*pelvis)
    R = S.rot(twist, lean, tilt)
    up = R @ V(0, 0, 1)
    p.waist = p.pelvis + R @ V(0, 0.005, 0.13 * s) - V(0, slump * 0.3, 0)
    p.chest = p.pelvis + R @ V(0, -0.012 * hunch, 0.33 * s) - V(0, slump, slump * 0.4)
    p.neck = p.pelvis + R @ V(0, -0.02 + 0.022 * hunch, 0.50 * s - 0.006 * hunch) - V(0, slump * 0.8, slump * 0.8)
    p.R = R
    p.hunch = hunch
    Rh = S.rot(twist + head_turn, lean * 0.4 - head_tilt, head_roll)
    p.Rh = Rh
    p.head = p.neck + Rh @ V(0, 0.03 * s, 0.185 * s) + R @ V(0, 0.02 * hunch, -0.004 * hunch)
    sh = B.shoulder * B.bulk ** 0.3            # weight rounds a man more than it widens his frame
    lift = R @ V(0, 0.022 * hunch, 0.016 * hunch)
    p.sh = [p.neck + R @ V(-sh, -0.0, -0.05 * s) + lift, p.neck + R @ V(sh, -0.0, -0.05 * s) + lift]    # left, right: the shoulders fall away from the neck
    p.grip = [None, None]           # how each hand sits (see set_hands)
    p.hip = [p.pelvis + R @ V(-0.09 * s * B.bulk ** 0.3, 0, -0.04 * s), p.pelvis + R @ V(0.09 * s * B.bulk ** 0.3, 0, -0.04 * s)]
    return p


def _arms(B, p, hands, poles, palms):
    """hands: where each wrist goes; poles: where each elbow points; palms: which way each palm faces."""
    p.elbow, p.wrist, p.palm = [], [], []
    for i in range(2):
        w = reach(p.sh[i], V(*hands[i]), B.upper_arm + B.forearm)
        e = ik(p.sh[i], w, B.upper_arm, B.forearm, V(*poles[i]))
        p.elbow.append(e)
        p.wrist.append(w)
        p.palm.append(norm(V(*palms[i])))


def _legs(B, p, ankles, knee_poles, toes):
    p.knee, p.ankle, p.toe = [], [], []
    for i in range(2):
        a = reach(p.hip[i], V(*ankles[i]), B.thigh + B.shin)
        k = ik(p.hip[i], a, B.thigh, B.shin, V(*knee_poles[i]))
        p.knee.append(k)
        p.ankle.append(a)
        p.toe.append(norm(V(*toes[i])))


def _easy(B, p, i):
    """Where the wrist of an arm hanging easy goes, its elbow's pole and its palm: the elbow a little
    bent and out, the hand by the thigh."""
    s = B.size
    sx = -1.0 if i == 0 else 1.0
    return (p.sh[i] + V(sx * 0.047, 0.075 if i == 0 else 0.058, -0.525 * s),
            p.sh[i] + V(sx * 0.25, -0.5, -0.3), (-sx, -0.35, 0))


def _set_arms(B, p, arms):
    """arms: for each arm, a (wrist, pole, palm), 'easy', or a Hand made round a thing, which the
    arm then reaches for (pole taken from the tuple after it: (Hand, pole))."""
    hands, poles, palms, held = [], [], [], [None, None]
    for i, a in enumerate(arms):
        if isinstance(a, str) and a == 'easy':
            a = _easy(B, p, i)
        if isinstance(a[0], Hand):
            held[i] = a[0]
            a = (a[0].o, a[1], a[0].M[:, 2])
        hands.append(a[0])
        poles.append(a[1])
        palms.append(a[2])
    _arms(B, p, hands, poles, palms)
    for i in range(2):
        if held[i] is not None:
            _attach(p, i, held[i])
        elif arms[i] == 'easy':
            p.grip[i] = 'relaxed'


def pose_stand(B, arms='hang', weight=0.0, **kw):
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), **kw)
    _legs(B, p, [(-0.1 * s - weight * 0.03, -0.03, 0.075), (0.1 * s - weight * 0.03, -0.03, 0.075)],
          [(-0.1, 1, 0.5), (0.1, 1, 0.5)], [(-0.15, 1, 0), (0.15, 1, 0)])
    if arms == 'hang':
        _set_arms(B, p, ['easy', 'easy'])
    return p


def pose_walk_pouch(B, **kw):
    """Coming across the lot, hands in the front pouch, hood up, not hurrying."""
    s = B.size
    p = _base(B, (0, 0.02, 0.955 * s), lean=0.08, head_tilt=0.12, **kw)
    _legs(B, p, [(-0.1 * s, 0.24, 0.1), (0.1 * s, -0.26, 0.13)],
          [(-0.1, 1, 0.6), (0.1, 1, 0.3)], [(-0.1, 1, -0.05), (0.12, 1, -0.35)])
    pouch = p.waist + p.R @ V(0, 0.16 * B.bulk, -0.03)
    _arms(B, p, [pouch + V(-0.06, -0.01, 0), pouch + V(0.06, -0.01, 0)],
          [p.sh[0] + V(-0.6, -0.4, -0.3), p.sh[1] + V(0.6, -0.4, -0.3)], [(1, 0.3, 0), (-1, 0.3, 0)])
    p.hands_in = [True, True]
    return p


def pose_pouch(B, **kw):
    """Standing still, hands in the front pouch: at the jukebox, looking at the screen."""
    s = B.size
    p = _base(B, (0, 0.0, 0.962 * s), **kw)
    _legs(B, p, [(-0.1 * s, 0.02, 0.075), (0.09 * s, -0.07, 0.075)],
          [(-0.15, 1, 0.5), (0.15, 1, 0.5)], [(-0.2, 1, 0), (0.2, 1, 0)])
    pouch = p.waist + p.R @ V(0, 0.16 * B.bulk, -0.03)
    _arms(B, p, [pouch + V(-0.06, -0.01, 0), pouch + V(0.06, -0.01, 0)],
          [p.sh[0] + V(-0.6, -0.4, -0.3), p.sh[1] + V(0.6, -0.4, -0.3)], [(1, 0.3, 0), (-1, 0.3, 0)])
    p.hands_in = [True, True]
    return p


def pose_phone_out(B, **kw):
    """In front of the stool, holding his phone up to the doorman, its screen to him, the fingers
    round its outer edge and the thumb up the inner one; the other hand in the pouch."""
    s = B.size
    p = _base(B, (0, 0.0, 0.965 * s), lean=0.03, **kw)
    _legs(B, p, [(-0.11 * s, 0.03, 0.075), (0.1 * s, -0.08, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.2, 1, 0), (0.25, 1, 0)])
    pouch = p.waist + p.R @ V(0, 0.16 * B.bulk, -0.03)
    # the phone out at chest height to his right, tipped up to the stool, clear of his face
    face = norm(V(-0.2, 0.9, 0.4))
    h = hold_phone(B, p.sh[1] + V(-0.035, 0.43 * s, -0.1 * s), face, right=True)
    _set_arms(B, p, [(pouch + V(-0.06, -0.01, 0), p.sh[0] + V(-0.6, -0.4, -0.3), (1, 0.3, 0)),
                     (h, p.sh[1] + V(0.5, -0.1, -0.8))])
    p.hands_in = [True, False]
    return p


def pose_sit(B, seat=0.64, table=0.78, lean=0.25, hands=None, feet='ring', floor=0.0, reach=0.32,
             palms=None, phone=None, hold=None, grips=None, **kw):
    """On a stool, facing a table (or the bar) in front: forearms on it, the hands resting on it,
    unless hands are given. Or in a seat with a floor of its own (a truck's), feet out in front on
    it. `phone`: which hand holds one, its screen the way that palm faces. `hold`: (kind, hand) a
    glass on the table in that hand."""
    s = B.size
    p = _base(B, (0, -0.02, seat + 0.1 * s), lean=lean, **kw)
    if feet == 'ring':
        ank = [(-0.12, 0.12, 0.3 if seat > 0.7 else 0.18), (0.12, 0.1, 0.3 if seat > 0.7 else 0.18)]
    else:
        ank = [(-0.13, reach, floor + 0.075), (0.14, reach - 0.07, floor + 0.075)]
    _legs(B, p, ank, [(-0.15, 1, 0.8), (0.15, 1, 0.8)], [(-0.1, 1, -0.3), (0.1, 1, -0.3)])
    on_table = hands is None
    if on_table:
        hands = [(-0.14, 0.42, table + 0.05), (0.12, 0.44, table + 0.05)]
    poles = [p.sh[0] + V(-0.5, -0.1, -0.4), p.sh[1] + V(0.5, -0.1, -0.4)]
    _arms(B, p, hands, poles, palms or [(0.3, 0, -1), (-0.3, 0, -1)])
    if on_table:
        p.grip = [dict(grip='open', on=below(table)), dict(grip='open', on=below(table))]
    if phone is not None:
        i = phone
        wr, el = p.wrist[i], p.elbow[i]
        face = norm(p.palm[i])
        up = norm(V(0, 0, 1) - face * face[2])
        h = hold_phone(B, wr + norm(wr - el) * 0.05 + face * 0.02 + up * 0.05, face, right=(i == 1))
        _set_arms(B, p, [(p.wrist[0], poles[0], p.palm[0]) if i == 1 else (h, poles[0]),
                         (h, poles[1]) if i == 1 else (p.wrist[1], poles[1], p.palm[1])])
        if on_table:
            p.grip[1 - i] = dict(grip='open', on=below(table))
    if hold is not None:
        kind, i = hold
        sx = -1.0 if i == 0 else 1.0
        base = V(sx * 0.06, 0.5, table)
        h = hold_glass(B, base, (sx * 1.0, -0.45, 0), right=(i == 1), kind=kind, height=0.06 if kind != 'wine' else 0.04)
        arms = [(p.wrist[0], poles[0], p.palm[0]), (p.wrist[1], poles[1], p.palm[1])]
        arms[i] = (h, poles[i])
        _set_arms(B, p, arms)
    if grips is not None:
        for i, g in enumerate(grips):
            if g is not None:
                p.grip[i] = g
    return p


def pose_chin(B, seat=0.76, desk=0.98, lean=-0.45, fist=1, **kw):
    """On a stool behind a desk with nothing to do: slumped forward, one elbow on the desk out in
    front and his chin on that fist, the other forearm along the desk; the feet on the stool's ring.
    `lean` is negative: forward."""
    s = B.size
    p = _base(B, (0, -0.02, seat + 0.1 * s), lean=lean, **kw)
    _legs(B, p, [(-0.12, 0.12, 0.3), (0.12, 0.1, 0.3)], [(-0.15, 1, 0.8), (0.15, 1, 0.8)], [(-0.1, 1, -0.3), (0.1, 1, -0.3)])
    i = fist
    sx = -1.0 if i == 0 else 1.0
    chin = p.head + p.Rh @ V(0, 0.108 * s, -0.118 * s)
    # the elbow on the desk an upper arm's length from the shoulder, out in front toward the chin;
    # the forearm from it up toward the chin
    sh = p.sh[i]
    elbow_z = desk + 0.045
    flat = np.sqrt(max(B.upper_arm ** 2 - (elbow_z - sh[2]) ** 2, 0.0))
    toward = norm(V((chin[0] - sh[0]) * 0.5, 1.0, 0.0))
    elbow = V(sh[0] + toward[0] * flat, sh[1] + toward[1] * flat, elbow_z)
    up = norm(chin - elbow)
    wrist = elbow + up * B.forearm * 0.995
    # the head comes down onto the top of the fist
    knuckles = wrist + up * 0.088 * B.hands * s
    shift = knuckles + V(0, 0, 0.012) - chin
    if np.linalg.norm(shift) < 0.08:
        p.head = p.head + shift
    hands = [None, None]
    hands[i] = tuple(wrist)
    hands[1 - i] = (-sx * 0.1, 0.4, desk + 0.04)
    poles = [None, None]
    poles[i] = elbow + (elbow - (sh + wrist) / 2) * 2.0
    poles[1 - i] = p.sh[1 - i] + V(-sx * 0.5, -0.1, -0.4)
    palms = [None, None]
    palms[i] = (-sx * 0.45, -0.9, 0.0)                     # the fist turned in, toward his face
    palms[1 - i] = (sx * 0.3, 0, -1)
    _arms(B, p, hands, poles, palms)
    p.grip = [None, None]
    p.grip[i] = 'fist'
    p.grip[1 - i] = dict(grip='open', on=below(desk))
    p.desk = V(0, 0.42, desk)
    return p


def pose_cue(B, left_handed=True, **kw):
    """Standing by the table between shots, the cue upright in one hand, its butt on the floor."""
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), **kw)
    _legs(B, p, [(-0.13 * s, 0.0, 0.075), (0.11 * s, -0.05, 0.075)],
          [(-0.3, 1, 0.5), (0.2, 1, 0.5)], [(-0.3, 1, 0), (0.2, 1, 0)])
    i = 0 if left_handed else 1
    side = -1 if left_handed else 1
    at = p.sh[i] + V(side * 0.12, 0.2, -0.28 * s)
    p.cue = (V(at[0] - side * 0.03, at[1] + 0.05, 0.0), V(at[0] - side * 0.03, at[1] + 0.07, 1.47))
    a, b2 = p.cue
    t = (at[2] - a[2]) / (b2[2] - a[2])
    h = hold_upright(B, a + (b2 - a) * t, 0.0125, (side * 1.0, -0.3, 0), right=not left_handed,
                     obj=S.cone(a, b2, 0.015, 0.0065))
    arms = [None, None]
    arms[i] = (h, p.sh[i] + V(side * 0.5, -0.4, -0.2))
    arms[1 - i] = 'easy'
    _set_arms(B, p, arms)
    return p


def pose_bar(B, top=1.08, **kw):
    """Behind the bar, both hands on it."""
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), lean=0.12, **kw)
    _legs(B, p, [(-0.12 * s, -0.02, 0.075), (0.12 * s, -0.05, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.2, 1, 0), (0.2, 1, 0)])
    _arms(B, p, [(-0.24, 0.42, top + 0.03), (0.22, 0.4, top + 0.03)],
          [p.sh[0] + V(-0.6, -0.2, -0.3), p.sh[1] + V(0.6, -0.2, -0.3)], [(0.2, 0, -1), (-0.2, 0, -1)])
    p.grip = [dict(grip='open', on=below(top)), dict(grip='open', on=below(top))]
    return p


def pose_reach(B, **kw):
    """Standing at the jukebox, one hand up on its screen."""
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), **kw)
    _legs(B, p, [(-0.1 * s, 0.0, 0.075), (0.1 * s, -0.1, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.1, 1, 0), (0.2, 1, 0)])
    _arms(B, p, [p.sh[0] + V(-0.04, 0.03, -0.56 * s), (0.12, 0.5, 1.45 * s)],
          [p.sh[0] + V(-0.3, -0.5, -0.2), p.sh[1] + V(0.5, -0.3, -0.5)], [(1, 0, 0), (0, 1, 0)])
    screen = p.wrist[1][1] + 0.026
    p.grip = ['relaxed', dict(grip='open', on=lambda P: screen - P[:, 1])]
    return p


def pose_counter(B, top=0.92, **kw):
    """Standing at the pass, tired: his right hand flat on the counter beside him, fingers over it,
    his weight on it; the other arm hanging."""
    s = B.size
    p = _base(B, (0.02, 0, 0.955 * s), lean=0.07, twist=0.12, **kw)
    _legs(B, p, [(-0.12 * s, 0.03, 0.075), (0.07 * s, -0.07, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.25, 1, 0), (0.15, 1, 0)])
    edge = 0.31 * s                                      # the counter's edge, running front to back
    wr = V(edge + 0.005, 0.14, top + 0.034)
    _arms(B, p, [_easy(B, p, 0)[0], wr], [_easy(B, p, 0)[1], p.sh[1] + V(0.6, -0.4, 0.1)], [_easy(B, p, 0)[2], (0, 0, -1)])
    counter = S.box(V(edge + 0.3, 0.1, top - 0.45), V(0.3, 0.6, 0.45), 0.004)
    p.grip = ['relaxed', dict(grip='open', along=V(0.62, 0.78, -0.08), palm=V(0, 0, -1), on=counter)]
    p.counter = V(edge + 0.05, 0.19, top)
    return p


def pose_card(B, height=1.3, face=(-0.15, 1.0, 0.33), other='easy', keys_other=False, **kw):
    """Standing in front of the stool, holding a card (a licence) out to the doorman at `height`,
    its face to him; the other arm easy, or its fist round car keys."""
    s = B.size
    p = _base(B, (0, 0.0, 0.965 * s), lean=0.03, **kw)
    _legs(B, p, [(-0.1 * s, 0.02, 0.075), (0.1 * s, -0.06, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.2, 1, 0), (0.2, 1, 0)])
    face = norm(V(*face))
    c = V(p.sh[1][0] - 0.07, p.sh[1][1] + 0.4 * s, height)
    h = hold_card(B, c, face, right=True)
    if keys_other:
        # the other hand a fist round the keys, down in front of the hip
        arms = [(p.sh[0] + V(-0.02, 0.16, -0.5 * s), p.sh[0] + V(-0.3, -0.4, -0.3), (0.6, -0.6, 0.2)),
                (h, p.sh[1] + V(0.45, -0.15, -0.8))]
        _set_arms(B, p, arms)
        p.grip[0] = dict(grip='fist', keys=True)
    else:
        _set_arms(B, p, [other, (h, p.sh[1] + V(0.45, -0.15, -0.8))])
    return p


def pose_close(B, fist_z=-0.1, keys=1, across=True, **kw):
    """Standing, holding her coat closed at the throat with one fist (right), the other forearm
    across her waist; car keys in the hand `keys` (None: none). Arms close to her."""
    s = B.size
    p = _base(B, (0, 0.0, 0.958 * s), lean=0.05, **kw)
    _legs(B, p, [(-0.075 * s, 0.01, 0.075), (0.085 * s, -0.04, 0.075)],
          [(-0.1, 1, 0.5), (0.2, 1, 0.5)], [(-0.12, 1, 0), (0.2, 1, 0)])
    R = p.R
    b = B.bulk
    fist = p.neck + R @ V(0.015, 0.125 * b + 0.03, fist_z)
    wrap = p.waist + R @ V(0.1, 0.15 * b + 0.03, 0.03)
    left = (wrap, p.sh[0] + V(-0.35, -0.1, -0.45), (0.2, -1, 0.1)) if across else _easy(B, p, 0)
    _set_arms(B, p, [left, (fist, p.sh[1] + V(0.25, -0.1, -0.6), (-0.4, -1, 0.1))])
    p.grip = [dict(grip='fist', along=V(1, 0.1, -0.15), keys=(keys == 0)) if across else 'relaxed',
              dict(grip='fist', along=V(-0.3, 0.2, 1.0), keys=(keys == 1))]
    return p


def pose_pint(B, side=1, height=1.05, **kw):
    """Standing with a pint in one hand at the waist, the other arm easy."""
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), **kw)
    _legs(B, p, [(-0.1 * s, 0.0, 0.075), (0.1 * s, -0.05, 0.075)],
          [(-0.15, 1, 0.5), (0.15, 1, 0.5)], [(-0.18, 1, 0), (0.18, 1, 0)])
    i = 1 if side > 0 else 0
    sx = 1.0 if i == 1 else -1.0
    h = hold_glass(B, V(sx * 0.11 * s, 0.27, height * s - 0.07), (sx * 1.0, -0.3, 0), right=(i == 1))
    arms = ['easy', 'easy']
    arms[i] = (h, p.sh[i] + V(sx * 0.3, -0.35, -0.5))
    _set_arms(B, p, arms)
    return p


def pose_door(B, **kw):
    """Standing in the doorway holding the door open with his left shoulder, leaning on it, the
    vape up by his chin in the right hand."""
    s = B.size
    p = _base(B, (0.0, 0.0, 0.955 * s), lean=0.02, tilt=-0.1, head_roll=0.12, **kw)
    _legs(B, p, [(-0.06 * s, 0.03, 0.075), (0.16 * s, 0.02, 0.075)],
          [(-0.1, 1, 0.5), (0.25, 1, 0.5)], [(-0.15, 1, 0), (0.3, 1, 0)])
    # the vape: a slim stick upright in a loose fist under his chin
    wr = p.neck + p.R @ V(0.07, 0.2, -0.16)
    _set_arms(B, p, [(p.sh[0] + V(-0.06, 0.03, -0.54 * s), p.sh[0] + V(-0.3, -0.5, -0.2), (1, -0.2, 0)),
                     (wr, p.sh[1] + V(0.3, -0.2, -0.6), (-0.8, -0.3, 0.3))])
    p.grip = ['relaxed', dict(grip='fist', along=p.R @ V(-0.9, 0.2, 0.35), palm=p.R @ V(0.1, -1.0, 0.15), vape=True)]
    p.door = p.sh[0] + p.R @ V(-0.07, 0.0, 0.0)
    return p


def pose_bar_lean(B, top=1.08, **kw):
    """Standing at the bar leaning on it, forearms on the top, looking along it for the bartender,
    one hand up off the bar to be seen."""
    s = B.size
    p = _base(B, (0, 0.0, 0.955 * s), lean=0.3, **kw)
    _legs(B, p, [(-0.11 * s, -0.12, 0.075), (0.1 * s, -0.04, 0.075)],
          [(-0.15, 1, 0.5), (0.15, 1, 0.5)], [(-0.15, 1, 0), (0.2, 1, 0)])
    _arms(B, p, [(-0.2, 0.5, top + 0.045), (0.2, 0.46, top + 0.2)],
          [p.sh[0] + V(-0.4, -0.1, -0.5), p.sh[1] + V(0.4, -0.1, -0.5)], [(0.3, 0, -1), (-0.6, 0.8, 0.0)])
    p.grip = [dict(grip='open', on=below(top)), dict(grip='relaxed', along=V(-0.1, 0.25, 1.0))]
    p.bar = V(0, 0.4, top)
    return p


def pose_carry(B, **kw):
    """Standing in front of the stool with a case of beer (a two-four) under his left arm, on his
    forearm against his ribs, his hand round its front; the other arm easy."""
    s = B.size
    p = _base(B, (0, 0.0, 0.965 * s), **kw)
    _legs(B, p, [(-0.11 * s, 0.0, 0.075), (0.1 * s, -0.04, 0.075)],
          [(-0.15, 1, 0.5), (0.15, 1, 0.5)], [(-0.15, 1, 0), (0.18, 1, 0)])
    R = p.R
    half = V(0.132, 0.2, 0.122)                       # a two-four: 26.5 x 40 x 24.5 cm
    c = p.chest + R @ V(-(0.165 * B.bulk + 0.012) - half[0] - 0.005, 0.12, -0.17 * s)
    Rc = R.copy()
    wr = c + R @ V(0.005, half[1] - 0.035, -half[2] - 0.035)
    box = S.box(c, half, 0.012, Rc)
    _set_arms(B, p, [(wr, p.sh[0] + V(-0.3, -0.5, -0.4), (0, 0.1, 1)), 'easy'])
    p.grip[0] = dict(grip='open', along=R @ V(0.35, 0.85, 0.35), palm=R @ V(0.1, 0.2, 1), on=box)
    p.props = [dict(kind='case', at=c, R=Rc, half=half)]
    return p


def pose_sit_drink(B, seat=0.76, table=1.08, kind='pint', i=1, **kw):
    """On a stool at a table or the bar, a glass on it in one hand, the other forearm on it."""
    return pose_sit(B, seat=seat, table=table, hold=(kind, i), **kw)


def _armrest(x, y0, y1, top):
    """A wooden chair's arm along y at x, its top at `top`: for a forearm to lie on and a hand to
    hang over the end of."""
    return S.box(V(x, (y0 + y1) / 2, top - 0.02), V(0.028, (y1 - y0) / 2, 0.02), 0.012)


def pose_armchair(B, seat=0.46, arm=0.66, arm_x=0.3, lean=0.2, knees=0.19, feet=0.5, desk=0.55, desk_top=0.76, **kw):
    """In a wooden armchair across a desk, leaning back a little: the feet flat on the floor out in
    front, the knees apart, each forearm along an arm of the chair (its top `arm` high, `arm_x` out
    from the middle) and the hands loose over their ends. The desk's near edge is `desk` in front of
    his knees, its top `desk_top` high."""
    s = B.size
    p = _base(B, (0, -0.02, seat + 0.1 * s), lean=lean, **kw)
    _legs(B, p, [(-knees - 0.01, feet, 0.075), (knees, feet - 0.03, 0.075)],
          [(-0.4, 1, 0.6), (0.4, 1, 0.6)], [(-0.18, 1, -0.05), (0.18, 1, -0.05)])
    hands, poles, palms, rests = [], [], [], []
    for i in range(2):
        sx = -1.0 if i == 0 else 1.0
        sh = p.sh[i]
        # the elbow on the arm where the upper arm hangs to it, the forearm on along it and in a little
        ez = arm + 0.036 * B.bulk ** 0.75
        dx, dz = sx * arm_x - sh[0], sh[2] - ez
        dy = np.sqrt(max(B.upper_arm ** 2 * 0.998 - dx * dx - dz * dz, 0.0))
        elbow = V(sx * arm_x, sh[1] + dy, ez)
        along = norm(V(-sx * 0.1, 1.0, -0.03))
        wrist = elbow + along * B.forearm
        hands.append(tuple(wrist))
        poles.append(elbow + (elbow - (sh + wrist) / 2) * 2.0)
        palms.append((sx * 0.15, 0.0, -1.0))
        rests.append(_armrest(sx * arm_x, elbow[1] - 0.2, wrist[1] + 0.035, arm))
    _arms(B, p, hands, poles, palms)
    p.grip = [dict(grip='relaxed', on=rests[i]) for i in range(2)]
    p.seat = V(0, 0.0, seat)
    p.armrest_left, p.armrest_right = V(-arm_x, p.wrist[0][1], arm), V(arm_x, p.wrist[1][1], arm)
    p.desk_edge = V(0, max(p.knee[0][1], p.knee[1][1]) + 0.06 + desk, desk_top)     # from the fronts of his knees
    return p


LEDGER = dict(w=0.25, d=0.34, t=0.011)   # an account book open: each page 25 x 34 cm, its pages 11 mm deep


def pose_ledger(B, seat=0.46, desk=0.74, edge=0.3, turn=0.42, lean=-0.3, head_tilt=0.45, **kw):
    """At a desk, in an office chair turned out from it a little toward the room on her right, writing
    in a ledger open on the desk in front of her: the pen in her right hand on its right-hand page,
    her left hand flat on the other, her head bent to it. The desk's near edge is `edge` in front of
    the middle of the chair, square to the world's y, its top `desk` high; the chair and her knees
    are turned `turn` to her right, her shoulders less. p.ledger: the book (see LEDGER)."""
    s = B.size
    p = _base(B, (0, -0.02, seat + 0.1 * s), lean=lean, twist=-turn * 0.35, head_tilt=head_tilt, **kw)
    Rt = S.rot(-turn, 0, 0)
    _legs(B, p, [Rt @ V(-0.11, 0.42, 0.075), Rt @ V(0.13, 0.38, 0.075)],
          [Rt @ V(-0.15, 1, 0.6), Rt @ V(0.15, 1, 0.6)], [Rt @ V(-0.15, 1, -0.05), Rt @ V(0.2, 1, -0.05)])
    # the book square to the desk, a little to her right, its spine running away from her
    top = desk + LEDGER['t']
    book = V(0.03, edge + 0.04 + LEDGER['d'] / 2, desk)
    p.ledger = dict(kind='ledger', at=book, R=S.rot(-0.08, 0, 0))
    # the pen on the right-hand page, leaning back over her hand toward her shoulder
    h = hold_pen(B, book + p.ledger['R'] @ V(0.1, -0.02, LEDGER['t'] + 0.0006), (0.42, -0.45, 0.79), (-0.6, -0.05, -0.8))
    left = (V(-0.13, edge + 0.08, top + 0.021), p.sh[0] + V(-0.45, -0.25, -0.45), (0.2, 0.05, -1.0))
    _set_arms(B, p, [left, (h, p.sh[1] + V(0.5, -0.35, -0.4))])
    p.grip[0] = dict(grip='open', on=below(top))
    p.props = [p.ledger]
    p.seat = V(0, 0, seat)
    p.seat_front = V(0, 0, seat) + Rt @ V(0, 0.25, 0)
    p.desk_edge = V(0, edge, desk)
    return p


def pose_perch(B, top=0.86, front=0.0, lean=0.05, hunch=0.25, head_tilt=-0.72, head_turn=0.12, **kw):
    """Sat up on the lid of a chest freezer, its top `top` high and its front edge `front` along y:
    the thighs along the lid, the legs hanging down its front with the heels back against it, the
    hands in the front pouch, the head tipped right back, looking up at the sky. p.seat: the lid
    under him; p.seat_front: the middle of its front edge."""
    s = B.size
    p = _base(B, (0, front + 0.045 - B.thigh * 0.99, top + 0.1 * s), lean=lean, hunch=hunch, head_tilt=head_tilt,
              head_turn=head_turn, **kw)
    # the backs of the heels against the front, the shoes hanging level (see shoe)
    ank = []
    for i, sx in enumerate((-1, 1)):
        knee_z = top + 0.055 * s
        ay = front + 0.078 * s + 0.004
        ank.append(V(p.hip[i][0] + sx * 0.012, ay, knee_z - np.sqrt(max(B.shin ** 2 - (ay - front - 0.045) ** 2, 0.0))))
    _legs(B, p, ank, [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.12, 1, 0), (0.15, 1, 0)])
    pouch = p.waist + p.R @ V(0, 0.16 * B.bulk, -0.03)
    _arms(B, p, [pouch + V(-0.06, -0.01, 0), pouch + V(0.06, -0.01, 0)],
          [p.sh[0] + V(-0.6, -0.4, -0.3), p.sh[1] + V(0.6, -0.4, -0.3)], [(1, 0.3, 0), (-1, 0.3, 0)])
    p.hands_in = [True, True]
    p.seat = V(0, p.pelvis[1], top)
    p.seat_front = V(0, front, top)
    return p


RAIL = dict(d=0.09, t=0.038)      # a wharf's rail: a timber laid flat along the posts, 9 cm across and 3.8 deep


def pose_rail(B, top=1.0, near=0.3, apart=0.2, lean=-0.1, hunch=0.25, head_tilt=0.06, **kw):
    """Standing at the rail along a wharf's edge, looking out over the water, both hands on it: the
    rail (see RAIL) runs along x, its top `top` high and its near edge `near` in front of him; his
    hands `apart` from the middle, the heels of them on its near edge and the fingers over its far
    one, his weight a little on them, his head a little down to the water. p.rail: the middle of
    its top."""
    s = B.size
    p = _base(B, (0, 0.0, 0.962 * s), lean=lean, hunch=hunch, head_tilt=head_tilt, **kw)
    _legs(B, p, [(-0.1 * s, 0.02, 0.075), (0.1 * s, -0.06, 0.075)],
          [(-0.15, 1, 0.5), (0.15, 1, 0.5)], [(-0.2, 1, 0), (0.18, 1, 0)])
    d, t = RAIL['d'], RAIL['t']
    rail = S.box(V(0, near + d / 2, top - t / 2), V(1.0, d / 2, t / 2), 0.005)
    hands, poles, palms, grips = [], [], [], []
    for i, sx in enumerate((-1.0, 1.0)):
        hands.append(V(sx * apart, near - 0.01, top + 0.021))
        poles.append(p.sh[i] + V(sx * 0.6, -0.3, -0.2))
        # palm down, rolled a little onto its outer edge; the fingers forward, a little in
        palms.append((sx * 0.12, 0.0, -1.0))
        # (the thumb along the top beside the first finger, not down into the rail)
        grips.append(dict(grip='open', along=V(-sx * 0.12, 1.0, -0.04), palm=V(sx * 0.12, 0.0, -1.0), on=rail,
                          thumb=(0.55, -0.14, 0.1, 0.0, 0.0)))
    _arms(B, p, hands, poles, palms)
    p.grip = grips
    p.rail = V(0, near + d / 2, top)
    return p


# ---------------------------------------------------------------------------------------- hands in poses

def set_hands(B, p):
    """Make each hand (p.hands) from its arm and p.grip[i]: None or a grip's name; a Hand already
    made round something (the hold_* functions); or a dict of grip, along, palm, thumb, and `on`: a
    surface or thing (a distance function) the fingers close on. The things held go in p.props."""
    p.hands = [None, None]
    p.props = list(getattr(p, 'props', []))
    for i in range(2):
        if getattr(p, 'hands_in', [False, False])[i]:
            continue
        g = p.grip[i] if hasattr(p, 'grip') else None
        if isinstance(g, Hand):
            h = g
        else:
            g = {'grip': g} if (g is None or isinstance(g, str)) else dict(g)
            along = g.get('along', p.wrist[i] - p.elbow[i])
            h = Hand(B, p.wrist[i], along, g.get('palm', p.palm[i]), right=(i == 1), grip=g.get('grip') or 'relaxed',
                     size=B.hands)
            if 'thumb' in g:
                h.th = list(g['thumb'])
            if 'curls' in g:
                h.curls = [list(c) for c in g['curls']]
            if g.get('vape'):
                # a pen of a vape across the palm, standing out of the fist on the thumb's side
                h.curls = [list(c) for c in GRIPS['open'][0]]
                h.th = [0.35, 0.75, 1.0, 0.1, 0.1]
                c = h.w((0.018, 0.083, 0.025))
                ax = h.dirw((1.0, 0.0, 0.0))
                a, b2 = c - ax * 0.045, c + ax * 0.062
                h.close(S.capsule(a, b2, 0.0078), gap=0.0004)
                h.prop = dict(kind='vape', at=(a + b2) / 2, R=S.frame(h.dirw((0.0, 1.0, 0.0)), ax))
            if g.get('keys'):
                # car keys: the ring in the fist, the fob and a key hanging out below the little finger
                ring = h.w((-0.036, 0.074, 0.024))
                hang = h.dirw((-1.0, 0.0, 0.0))
                hang = norm(hang + V(0, 0, -1.2))
                side = norm(np.cross(hang, h.dirw((0.0, 0.0, 1.0))))
                h.prop = dict(kind='keys', at=ring, R=S.frame(side, -hang))
            if g.get('on') is not None:
                h.close(g['on'], fingers=g.get('fingers', (0, 1, 2, 3)), thumb=g.get('close_thumb', True),
                        to=g.get('to', 'fist'))
        h.fore = norm(p.elbow[i] - p.wrist[i])
        p.hands[i] = h
        if getattr(h, 'prop', None) is not None:
            p.props.append(dict(h.prop, hand=i))
    for pr in p.props:
        if pr['kind'] == 'phone':
            p.phone_at = (pr['at'], pr['R'])
            p.phone = pr['hand']
        if pr['kind'] == 'card':
            p.card_at = (pr['at'], pr['R'])


def _attach(p, i, h):
    """Put a hand made round a thing on arm i, moving it and the thing to where the wrist got to."""
    d = p.wrist[i] - h.o
    h.o = p.wrist[i].copy()
    if getattr(h, 'prop', None) is not None:
        h.prop = dict(h.prop, at=h.prop['at'] + d)
    p.grip[i] = h


def below(z):
    """Everything under the level z: a table top, the bar, a counter, for fingers to rest on."""
    return lambda P: P[:, 2] - z


def _frame_at(h, c, q):
    """Move hand h so that the point q of its own frame lands on c."""
    h.o = h.o + (V(*c) - h.w(q))


def hold_phone(B, c, face, right=True, phi=0.96, at=(0.0123, 0.070), thumb=(1.1, 0.12, 0.2, 0.05, 0.05)):
    """A hand round a phone whose screen faces `face`, upright, centred at c: the palm on its back,
    the hand turned out by phi from upright so the fingers wrap its outer edge (their tips beside
    the glass, not on it) and the thumb runs up its inner edge."""
    face = norm(V(*face))
    up = norm(V(0, 0, 1) - face * face[2])
    out = norm(np.cross(face, up)) * (1.0 if right else -1.0)
    h = Hand(B, V(0, 0, 0), up * np.cos(phi) + out * np.sin(phi), face, right, grip='open', size=B.hands)
    h.th = list(thumb)
    _frame_at(h, c, (at[0], at[1], 0.0205))
    Rp = S.frame(np.cross(up, face), up)
    body = S.box(c, V(0.036, 0.076, 0.00425), 0.004, Rp)
    glass = S.box(V(*c) + Rp @ V(0, 0, 0.016), V(0.031, 0.07, 0.012), 0.0, Rp)
    h.close(S.union(body, glass), gap=0.0004)
    h.prop = dict(kind='phone', at=V(*c), R=Rp)
    return h


CARD = (0.086, 0.054, 0.0008)        # a licence: ID-1 size


def card_sdf(c, R):
    return S.box(c, V(CARD[0] / 2, CARD[1] / 2, CARD[2] / 2), 0.0003, R)


def hold_card(B, c, face, right=True, at=(-0.008, 0.118), thumb=(0.4, 0.3, -0.4, 0.0, 0.0)):
    """A hand showing a card (a licence) centred at c, its face toward `face`, level: the card
    stands above the hand, the fingers behind it (their tips over its top edge) and the thumb up its
    face to the lower inner corner. `at`: the card's middle across the hand and its bottom edge along
    it, in the hand's frame."""
    face = norm(V(*face))
    up = norm(V(0, 0, 1) - face * face[2])
    h = Hand(B, V(0, 0, 0), up, face, right, grip='flat', size=B.hands)
    h.curls = [[-0.05, 0.0, 0.0] for _ in range(4)]
    h.th = list(thumb)
    _frame_at(h, c, (at[0], at[1] + CARD[1] / 2, 0.0205))
    Rc = S.frame(np.cross(up, face), up)          # x along the card, y up it, z out of its face
    h.close(card_sdf(V(*c), Rc), gap=0.0003, to=([(1.2, 1.2, 0.6)] * 4, (0, 0, 0, 1.2, 1.1)))
    h.prop = dict(kind='card', at=V(*c), R=Rc)
    return h


PEN = dict(r=0.0042, L=0.142)          # a ballpoint pen: 8.4 mm across, 14 cm long


PEN_GRIP = dict(rest=(0.0445, 0.079, -0.0095), d=(-0.235, 0.59, 0.772), reach=0.106, index=(0.4, 0.3, 0.05), thumb=(0.22, 0.38, 0.0, 0.0, 0.0))


def hold_pen(B, tip, up, palm, right=True):
    """A hand writing: the pen's point on the page at `tip`, the pen leaning back from it along `up`
    (toward the hand). It lies in the web over the root of the first finger and runs down under that
    finger's pad, the thumb's pad against its side, to rest on the side of the second finger's end;
    the other two fingers are curled under. `palm`: which way the palm about faces (down onto the
    page, toward the other hand)."""
    g = PEN_GRIP
    rest, d = V(*g['rest']), norm(V(*g['d']))        # in the hand's own frame: d from the web toward the point
    at = rest + d * g['reach']
    # turn the hand so that the pen leans back along `up` and the palm faces about `palm`
    up = norm(V(*up))
    e2 = norm(V(0, 0, 1) - d * float(np.dot(V(0, 0, 1), d)))
    f2 = norm(V(*palm) - up * float(np.dot(V(*palm), up)))
    M = np.stack([up, f2, np.cross(up, f2)], axis=1) @ np.stack([-d, e2, np.cross(-d, e2)], axis=1).T
    h = Hand(B, V(0, 0, 0), M @ V(0, 1, 0), M @ V(0, 0, 1), right, grip='open', size=B.hands)
    h.curls[0] = list(g['index'])
    h.curls[2], h.curls[3] = [1.2, 1.3, 0.8], [1.35, 1.35, 0.8]
    h.th = list(g['thumb'])
    _frame_at(h, tip, at)
    pen = S.capsule(V(*tip) + up * PEN['r'], V(*tip) + up * PEN['L'], PEN['r'])
    h.close(pen, fingers=(0, 1), to=([(1.3, 1.5, 0.9), (1.0, 1.15, 0.6), (1.5, 1.7, 0.9), (1.5, 1.7, 0.9)], (0, 0, 0, 1.0, 0.9)),
            gap=0.0004)
    h.prop = dict(kind='pen', at=V(*tip) + up * (PEN['L'] / 2), R=S.frame(norm(np.cross(up, M @ V(0, 0, 1))), up))
    return h


GLASSES = {  # an upright glass: radius at the foot, at the lip, height (a wine glass: see glass_r)
    'pint': (0.030, 0.043, 0.155),
    'tumbler': (0.031, 0.034, 0.13),
    'wine': (0.036, 0.033, 0.19),
}
WINE = dict(foot=0.036, stem_r=0.0042, stem=0.078, bowl_c=0.128, bowl=(0.041, 0.056), lip=0.186)


def glass_r(kind, z):
    """The glass's radius z above its foot."""
    if kind == 'wine':
        w = WINE
        if z < w['stem']:
            return w['stem_r']
        rx, rz = w['bowl']
        t = np.clip((z - w['bowl_c']) / rz, -1.0, 1.0)
        return rx * float(np.sqrt(1.0 - t * t))
    r0, r1, h = GLASSES[kind]
    return r0 + (r1 - r0) * z / h


def glass_sdf(kind, base):
    base = V(*base)
    if kind == 'wine':
        w = WINE
        foot = S.cylinder(base, base + V(0, 0, 0.004), w['foot'], 0.0015)
        stem = S.capsule(base + V(0, 0, 0.004), base + V(0, 0, w['stem'] + 0.01), w['stem_r'])
        bowl = S.intersect(S.ellipsoid(base + V(0, 0, w['bowl_c']), V(w['bowl'][0], w['bowl'][0], w['bowl'][1])),
                           S.halfspace(base + V(0, 0, w['lip']), V(0, 0, 1)))
        return S.union(foot, S.blend(0.012, stem, bowl))
    r0, r1, h = GLASSES[kind]
    return S.cone(base + V(0, 0, r0 * 0.5), base + V(0, 0, h - r1 * 0.3), r0, r1)


def hold_glass(B, base, toward, right=True, kind='pint', height=0.065, fill=0.9, thumb=(1.0, 0.55, 0.6, 0.1, 0.1)):
    """A hand round an upright glass whose foot is at `base`: the palm on its side toward `toward`
    (from the glass to the hand, level), the thumb up and the fingers round it. A wine glass is held
    by its bowl."""
    if kind == 'wine':
        height = max(height, 0.1)
    h = hold_upright(B, V(*base) + V(0, 0, height), glass_r(kind, height), toward, right, glass_sdf(kind, base), thumb)
    h.prop = dict(kind=kind, at=V(*base), R=np.eye(3, dtype=np.float32), fill=fill)
    return h


def hold_upright(B, c, r, toward, right=True, obj=None, thumb=(1.0, 0.55, 0.6, 0.1, 0.1)):
    """A hand round an upright thing of radius r whose axis passes c (a glass, a cue): the palm on
    its side toward `toward` (from the thing to the hand, level), the thumb up and the fingers
    round it, closing until they touch obj (the thing's shape)."""
    n = V(*toward)
    n[2] = 0.0
    n = -norm(n)                                # the palm faces the thing
    tv = V(0, 0, 1)
    u = np.cross(n, tv) if right else np.cross(tv, n)
    h = Hand(B, V(0, 0, 0), u, n, right, grip='open', size=B.hands)
    h.th = list(thumb)
    # the axis passes the middle of the palm, the thing's radius off it
    _frame_at(h, V(*c), (0.0, 0.052, 0.0165 + r / h.k))
    if obj is None:
        obj = S.capsule(V(*c) - V(0, 0, 0.3), V(*c) + V(0, 0, 0.3), r)
    h.close(obj, gap=0.0005)
    return h


def head_scale(B):
    """How big the head is drawn, 1 being an average man's: heads differ less than bodies do, and a
    woman's is 0.955 of a man's."""
    return (0.955 if B.f else 1.0) * (1.0 + 0.3 * (B.size / (0.93 if B.f else 1.0) - 1.0))


def face_of(B, look):
    """The numbers of a person's face (tools/head.py) from their look: man or woman, their age and
    build, the expression, and the small differences everyone has, drawn from their name
    (look['seed'], the same for every model of one person). look['face_numbers'] sets any of them
    outright."""
    F = look.get('face', [])
    age = look.get('age_n', 0.78 if B.old else (0.06 if B.young else 0.36))
    fat = float(np.clip((B.bulk / (0.9 if B.f else 1.0) - 1.0) / 0.45 + 4.0 * (B.belly - 0.015), -1.0, 1.0))
    smile = 0.7 if ('smile' in F or look.get('mood') == 'smile') else 0.0
    over = dict(look.get('face_numbers', {}))
    if 'gaunt' in look:
        over.setdefault('gaunt', look['gaunt'])
    if 'lined' in F:
        over.setdefault('lines', 1.6)
    return HD.face('f' if B.f else 'm', age=age, fat=fat, seed=look.get('seed'), smile=smile, **over)


_heads = {}


def head_of(B, look):
    """The person's head (a built head.Head), made once for each face."""
    fp = face_of(B, look)
    key = repr(sorted(fp.items()))
    if key not in _heads:
        _heads[key] = HD.Head(**fp).build()
    return _heads[key]


def head_world(B, p, f):
    """A shape of the head's (in its own frame, metres for an average man's head) where the head is."""
    H, R, s = p.head, p.Rh, head_scale(B)
    return lambda P: f(((P - H) @ R) / s) * s


def readers_ends(B, p):
    """The ends of the arms of reading glasses worn down the nose, behind the ears: where their
    chain is fixed."""
    s = head_scale(B)
    return [p.head + p.Rh @ (V(sx * 0.07, -0.032, -0.012) * s) for sx in (-1, 1)]


def eyes_at(B, p):
    """The midpoint between the eyes (their fronts)."""
    s = head_scale(B)
    return p.head + p.Rh @ (V(0, 0.076, 0.005) * s)


# ---------------------------------------------------------------------------------------- body

def _loc(fn, o, R):
    """A shape given in a local frame about o: fn(q) with q = (P - o) @ R."""
    return lambda P: fn((P - o) @ R)


def _panel(f, region, rise):
    """Cloth laid on the surface f, standing `rise` proud of it, inside `region`: a band, a pocket,
    a lapel, a placket."""
    return S.intersect(S.offset(f, rise), region)


def rings(f, a, d, amp, period, t0, t1):
    """Folds round a sleeve or a leg: f rippled along d, between t0 and t1 metres from a."""
    a, d = V(*a), norm(V(*d))
    w = 2 * np.pi / period
    def g(P):
        t = (P - a) @ d
        m = np.clip((t - t0) / 0.015, 0, 1) * np.clip((t1 - t) / 0.015, 0, 1)
        return f(P) + amp * m * np.sin(t * w)
    return g


def folds(f, o, R, amp, period, z0, z1):
    """Soft folds hanging down cloth: f rippled across its frame's x, strongest at the height z0 (the
    hem) and gone by z1, both in the frame about o."""
    w = 2 * np.pi / period
    def g(P):
        q = (P - o) @ R
        m = np.clip((z1 - q[:, 2]) / (z1 - z0), 0, 1)
        return f(P) + amp * m * np.sin(q[:, 0] * w + 0.8 * np.sin(q[:, 1] * 11.0))
    return g


# how loose each top hangs, and where it ends below the pelvis (None: a long coat's own skirt; a
# positive number: tucked in at the waist)
LOOSE = {'hoodie': 0.022, 'coat': 0.03, 'raincoat': 0.03, 'jacket': 0.022, 'denim': 0.018, 'hivis': 0.012,
         'cardigan': 0.012, 'whites': 0.012, 'suit': 0.012, 'tweed': 0.014, 'flannel': 0.01, 'apron': 0.006,
         'tshirt': 0.004, 'sweater': 0.012, 'fleece': 0.016, 'shirt': 0.007, 'workjacket': 0.02}
HEM = {'tshirt': -0.06, 'sweater': -0.07, 'fleece': -0.08, 'hoodie': -0.09, 'jacket': -0.07, 'denim': -0.06,
       'flannel': -0.075, 'hivis': -0.075, 'cardigan': -0.1, 'tweed': -0.12, 'suit': -0.13, 'whites': -0.085,
       'apron': 0.07, 'shirt': 0.07, 'workjacket': -0.08, 'coat': None, 'raincoat': None}


def gut(f, p, belly, b, s, hangs=True):
    """A belly let out of the front of the trunk f: pushed out from under the ribs in a long slope,
    most a hand below the navel, and tucked back under to the belt in a short curve, filling out a
    little round the sides; sitting, it settles a little. A smooth push on the surface rather than a
    shape of its own, so it's one with the body: no seam, no ball."""
    R = p.R
    o = p.waist + R @ V(0, 0, -0.035 * s) - V(0, 0, belly * 0.25)
    def g(P):
        q = (P - o) @ R
        z = q[:, 2]
        fz = np.exp(-(z / np.where(z > 0, 0.2 * s, (0.125 if hangs else 0.085) * s)) ** 2)
        fx = np.exp(-(q[:, 0] / (0.15 * b)) ** 2)
        front = np.clip((q[:, 1] + 0.03) / 0.11, 0.0, 1.0)
        front = front * front * (3.0 - 2.0 * front)
        return f(P) - belly * fz * (fx * front + 0.12 * (1.0 - fx))
    return g


def body_parts(B, p, look):
    """The body in its clothes, as parts with materials. The hands, and the cuffs round them, are
    in the group 'hand', meshed finer."""
    top = look.get('top', 'tshirt')
    legs_mat = look.get('bottoms', 'jeans')
    s, b = B.size, B.bulk
    ab = b ** 0.75                    # the arms: weight thickens them less than the trunk
    parts = []
    add = lambda name, f, order=0, group=None: parts.append(Part(name, f, order=order, group=group))
    loose = look.get('loose', LOOSE.get(top, 0.01))
    shirt = look.get('top_mat', {'hivis': 'sweatshirt', 'apron': 'shirt_dark', 'suit': 'suit'}.get(top, top))
    R = p.R
    hands = getattr(p, 'hands', [None, None])
    # the trunk
    ch = B.chest
    chest_r = V(0.165 * b * ch + loose, 0.105 * b * ch + loose + (0.012 if B.f else 0.0), 0.15 * s)
    belly = B.belly * b * 0.85
    thin = min(belly, 0.0)            # the young and slight: a little in at the waist
    # the slope of the shoulders from the neck out, rather than a bar across
    yoke = [S.cone(p.neck + R @ V(0, -0.014, -0.014), p.sh[i] + R @ V(0.02 * (1 if i == 0 else -1), -0.008, 0.004),
                   0.056 * b ** 0.7 + loose * 0.5, 0.05 * b ** 0.7 + loose * 0.85) for i in range(2)]
    body = S.blend(0.07,
        S.ellipsoid(p.pelvis + R @ V(0, -0.005, 0.02), V(0.16 * b + loose, 0.108 * b + loose, 0.12 * s), R),
        S.ellipsoid(p.waist + R @ V(0, thin * 0.6, 0), V(0.148 * b + loose + thin * 0.4 + max(belly, 0.0) * 0.3,
                                                          0.1 * b + loose + thin, (0.12 + max(belly, 0.0) * 0.4) * s), R),
        S.ellipsoid(p.chest, chest_r, R), *yoke)
    if belly > 0.0:
        body = gut(body, p, belly, b, s, hangs=not (HEM.get(top, -0.07) or -0.07) > 0 or look.get('tucked') is False)
    if look.get('drape'):
        # a top too big for him: from the chest it falls straight to the hem instead of taking him in
        body = S.blend(0.05, body, S.ellipsoid(p.waist + R @ V(0, 0.004, 0.015 * s), V(chest_r[0] * 0.97, chest_r[1] * 1.02, 0.25 * s), R))
    if B.f:
        # the bust, melted into the chest under the cloth
        body = S.blend(0.035, body, *[S.ellipsoid(p.chest + R @ V(sx * 0.068, 0.1 * b * ch + loose - 0.014, -0.035),
                                                  V(0.055, 0.038, 0.048), R) for sx in (-1, 1)])
    hem = HEM.get(top, -0.07)
    tucked = hem is not None and hem > 0
    if look.get('tucked') is False and tucked:
        hem, tucked = -0.07, False
    trunk = body
    if hem is not None:
        # the top ends in a hem round the hips (or goes into the trousers at the waist)
        cut = S.halfspace(p.pelvis + R @ V(0, 0, hem * s), -(R @ V(0, 0, 1)))
        trunk = S.intersect(body, cut, 0.006)
        if not tucked:
            trunk = S.union(trunk, _panel(body, S.intersect(cut, S.halfspace(p.pelvis + R @ V(0, 0, hem * s + 0.012), R @ V(0, 0, 1))), 0.003))
    if top in ('hoodie', 'sweater', 'fleece', 'workjacket') or look.get('drape'):
        trunk = folds(trunk, p.pelvis, R, 0.0022 if look.get('drape') else 0.0014, 0.075, (hem or -0.1) * s, 0.2 * s)
    vneck = None
    if top in ('suit', 'cardigan', 'tweed'):
        # a V opening down the front, to the top button
        vt = 0.2 if top != 'cardigan' else 0.24
        vneck = _loc(lambda q: np.maximum(np.abs(q[:, 0]) * 0.94 - (q[:, 2] + vt) * 0.34, -q[:, 1]), p.neck, R)
        trunk = S.carve(trunk, vneck, 0.003)
    add(shirt, trunk)
    # the trousers: the hips under the top's hem, the waistband and a belt where a shirt is tucked in
    lb = 1.0 + (b - 1.0) * 0.6
    hips = S.ellipsoid(p.pelvis + R @ V(0, -0.012, -0.035), V(0.148 * b + 0.008, 0.1 * b + 0.008, 0.105 * s), R)
    add(legs_mat, hips)
    if tucked:
        wb = S.intersect(S.offset(body, 0.004), S.intersect(S.halfspace(p.pelvis + R @ V(0, 0, hem * s + 0.001), R @ V(0, 0, 1)),
                                                             S.halfspace(p.pelvis + R @ V(0, 0, hem * s - 0.038), -(R @ V(0, 0, 1)))))
        add('belt' if top != 'apron' else legs_mat, wb, order=1)
        c0 = p.pelvis + R @ V(0, 0, hem * s - 0.018)
        add('buckle', S.box(c0 + _surf(body, c0, R @ V(0, 1, 0)) + R @ V(0, 0.008, 0), V(0.022, 0.006, 0.016), 0.003, R), order=2)
    # the neck
    # (up into the head's own neck, inside it)
    add('skin', S.cone(p.neck + R @ V(0, 0.0, -0.03), p.head + p.Rh @ V(0, -0.016, -0.11), 0.056 * b ** 0.5, 0.042))
    neck_r = 0.056 * b ** 0.5
    Rn = R @ S.rot(0, -0.35, 0)
    # arms: sleeves to the wrist, or to above the elbow for a t-shirt
    for i in range(2):
        sh, el, wr = p.sh[i], p.elbow[i], p.wrist[i]
        d = norm(wr - el)
        hd = hands[i]
        grp = ('hand_l' if i == 0 else 'hand_r') if hd is not None else None
        up_mat = shirt
        bare = top in ('tshirt',) or look.get('sleeves') in ('rolled', 'short')
        fore_mat = 'skin' if bare else shirt
        if top == 'hivis':
            up_mat = fore_mat = 'sweatshirt'
        if look.get('sleeves') == 'short':
            up_mat = 'skin'
        ul = loose if up_mat != 'skin' else 0.0
        sx = -1.0 if i == 0 else 1.0
        upper = S.blend(0.03, S.sphere(sh + R @ V(sx * 0.006, 0, -0.016), 0.047 * ab + ul * 0.6),
                        S.cone(sh, el, 0.049 * ab + ul * 0.8, 0.041 * ab + ul))
        if up_mat != 'skin' and not bare:
            upper = rings(upper, el, -(el - sh), 0.0016, 0.022, 0.0, 0.07)       # creases in the crook of the arm
        add(up_mat, upper)
        if top == 'tshirt' or look.get('sleeves') == 'short':
            # the sleeve from under the shoulder's round to halfway down, standing a little off the arm
            # and opening toward its end
            mid = sh + (el - sh) * 0.45
            sleeve = S.cone(sh + (el - sh) * 0.14, mid, 0.0479 * ab + ul * 0.8 + 0.004, 0.0454 * ab + ul * 0.9 + 0.009)
            if look.get('creased'):
                sleeve = crease(sleeve, sh, el, R @ V(sx, 0, 0.6))
            # (a t-shirt of a colour of its own, top_mat, has its sleeves in it too)
            add(shirt if top != 'tshirt' else look.get('top_mat', 'tshirt'), sleeve, order=2)
        if fore_mat == 'skin':
            # a bare forearm, flattening to the wrist the hand comes out of
            if hd is not None:
                k = hd.k
                add('skin', S.econe(el, wr - d * 0.012, (0.041 * ab, 0.039 * ab), (0.0262 * k, 0.0172 * k), hd.M[:, 0]))
            else:
                add('skin', S.cone(el, wr, 0.041 * ab, 0.03 * ab))
        else:
            sl = S.cone(el, wr - d * 0.04, 0.041 * ab + loose, 0.031 * ab + loose * 0.75)
            if top in ('hoodie', 'sweater', 'fleece') or look.get('drape'):
                sl = rings(sl, el, d, 0.0022, 0.024, 0.1, 0.24)             # bunched above the cuff
            add(fore_mat, sl)
            # the cuff: a band round the wrist, its mouth open so the wrist comes out of it
            r0, r1 = 0.032 * b + loose * 0.7, 0.03 * b + loose * 0.6
            cuff = S.cone(wr - d * 0.055, wr - d * 0.004, r0, r1)
            rin = r1 - 0.0035
            cuff = S.carve(cuff, S.capsule(wr - d * (0.014 - rin), wr + d * 0.05, rin), 0.0015)
            add(shirt if top != 'jacket' else look.get('trim_mat', 'jacket_trim'), cuff, order=1, group=grp)
        if look.get('sleeves') == 'rolled':
            add(shirt, S.torus(el + d * 0.02, 0.045 * b, 0.016, S.frame(np.cross(d, V(0, 0, 1)) if abs(d[2]) < 0.9 else V(1, 0, 0), np.cross(d, np.cross(d, V(0, 0, 1))) if abs(d[2]) < 0.9 else V(0, 1, 0))), order=2)
        if hd is not None:
            add('skin', hd.sdf(nails=look.get('nails', False)), order=1, group=grp)
            if look.get('knuckles') == 'scarred':
                add('scar', knuckle_scars(hd), order=2, group=grp)
    # legs
    for i in range(2):
        hp, kn, an = p.hip[i], p.knee[i], p.ankle[i]
        leg = S.blend(0.04, S.cone(hp, kn, 0.088 * lb + 0.008, 0.056 * lb + 0.008),
                      S.cone(kn, an + V(0, 0, 0.04), 0.056 * lb + 0.008, 0.045 * lb + 0.006))
        add(legs_mat, leg)
        add(legs_mat, S.ellipsoid(kn + (an - kn) * 0.3 - V(0, 0.025, 0), V(0.05 * lb, 0.045 * lb, 0.09), None))
        # the hem breaking over the shoe
        add(legs_mat, S.cone(an + V(0, 0, 0.085), an + V(0, 0, 0.035), 0.047 * lb + 0.007, 0.051 * lb + 0.008), order=1)
        if look.get('shoes') == 'slippers':
            add(look.get('shoe_mat', 'slipper'), shoe(an, p.toe[i], s * 0.97, look), order=1)
        elif look.get('shoes', 'boots' if (B.old or top == 'hivis') else 'sneakers') == 'boots':
            add('boot', shoe(an, p.toe[i], s, look), order=1)
            add('boot_sole', sole(an, p.toe[i], s, look), order=2)
        else:
            add(look.get('shoe_mat', 'shoe'), shoe(an, p.toe[i], s, look), order=1)
            add('sole' if look.get('shoes') != 'dress' else 'boot_sole', sole(an, p.toe[i], s, look), order=2)
    # --- the top's own shapes: necklines and collars, bands, openings, pockets
    chest_front = p.chest + R @ V(0, chest_r[1], 0)
    front = lambda x0, x1, z0, z1, o=p.chest: _loc(lambda q: np.maximum.reduce([np.abs(q[:, 0] - (x0 + x1) / 2) - (x1 - x0) / 2,
                                                                             np.abs(q[:, 2] - (z0 + z1) / 2) - (z1 - z0) / 2,
                                                                             -q[:, 1]]), o, R)
    if top in ('tshirt', 'sweater'):
        # a ribbed crew neck
        add(shirt, S.torus(p.neck + R @ V(0, 0.014, -0.002), neck_r + 0.004, 0.0055 if top == 'tshirt' else 0.008, Rn), order=2)
        if top == 'sweater':
            hemz = p.pelvis + R @ V(0, 0, (hem or -0.07) * s)
            add(shirt, _panel(body, S.intersect(S.halfspace(hemz, -(R @ V(0, 0, 1))), S.halfspace(hemz + R @ V(0, 0, 0.05), R @ V(0, 0, 1))), 0.004), order=1)
    if top == 'shirt' or top == 'denim':
        # a collar standing round the neck, its points turned down over the chest; a placket of buttons
        col = S.carve(S.cone(p.neck + R @ V(0, 0.004, -0.018), p.neck + R @ V(0, 0.0, 0.028), neck_r + 0.012, neck_r + 0.008),
                      S.cone(p.neck + R @ V(0, 0.004, -0.03), p.neck + R @ V(0, 0.0, 0.04), neck_r - 0.004, neck_r - 0.006))
        col = S.carve(col, front(-0.012, 0.012, 0.1, 0.3, p.neck), 0.002)
        add(shirt, col, order=2)
        for sx in (-1, 1):
            # the collar's points, turned down on the chest: a triangle each side of the throat
            pt = _loc(lambda q, sx=sx: np.maximum.reduce([-(sx * q[:, 0]) + 0.008, q[:, 2] - 0.002 + (sx * q[:, 0] - 0.008) * 0.1,
                                                          (sx * q[:, 0]) - 0.058 + (-q[:, 2]) * 0.55, -q[:, 2] - 0.07 + (sx * q[:, 0]) * 0.4,
                                                          -q[:, 1]]), p.neck, R)
            add(shirt, _panel(body, pt, 0.004), order=2)
        add(shirt, _panel(body, front(-0.013, 0.013, -0.5, 0.0, p.neck), 0.0025), order=1)
        for k in range(5 if top == 'shirt' else 4):
            c0 = p.neck + R @ V(0, 0, -0.07 - k * 0.075)
            add('button', S.sphere(c0 + _surf(body, c0, R @ V(0, 1, 0)), 0.0055), order=3)
        if top == 'denim':
            for sx in (-1, 1):
                add(shirt, _panel(body, front(sx * 0.075 - 0.045, sx * 0.075 + 0.045, 0.0, 0.1, p.chest), 0.004), order=1)
                add(shirt, _panel(body, front(sx * 0.075 - 0.047, sx * 0.075 + 0.047, 0.07, 0.1, p.chest), 0.008), order=2)
            hemz = p.pelvis + R @ V(0, 0, (hem or -0.06) * s)
            add(shirt, _panel(body, S.intersect(S.halfspace(hemz, -(R @ V(0, 0, 1))), S.halfspace(hemz + R @ V(0, 0, 0.045), R @ V(0, 0, 1))), 0.004), order=1)
    if top == 'fleece' or top == 'workjacket':
        # a stand-up collar and the zip down the front
        col = S.carve(S.cone(p.neck + R @ V(0, 0.006, -0.02), p.neck + R @ V(0, 0.0, 0.045), neck_r + 0.02, neck_r + 0.014),
                      S.cone(p.neck + R @ V(0, 0.006, -0.03), p.neck + R @ V(0, 0.0, 0.06), neck_r - 0.002, neck_r - 0.005))
        add(shirt, col, order=2)
        add('zip', _panel(body, front(-0.004, 0.004, -0.6, 0.05, p.neck), 0.004), order=3)
        hemz = p.pelvis + R @ V(0, 0, (hem or -0.08) * s)
        add(shirt, _panel(body, S.intersect(S.halfspace(hemz, -(R @ V(0, 0, 1))), S.halfspace(hemz + R @ V(0, 0, 0.035), R @ V(0, 0, 1))), 0.004), order=1)
        if top == 'workjacket':
            for sx in (-1, 1):
                add(shirt, _panel(body, front(sx * 0.08 - 0.05, sx * 0.08 + 0.05, -0.22, -0.1, p.chest), 0.005), order=1)
    if top == 'hoodie':
        hemz = p.pelvis + R @ V(0, 0, hem * s)
        add('hoodie', _panel(body, S.intersect(S.halfspace(hemz, -(R @ V(0, 0, 1))), S.halfspace(hemz + R @ V(0, 0, 0.05), R @ V(0, 0, 1))), 0.005), order=1)
        c0 = p.waist + R @ V(0, 0, -0.035)
        pouch_c = c0 + _surf(body, c0, R @ V(0, 1, 0)) + R @ V(0, 0.006, 0)
        add('hoodie', S.box(pouch_c, V(0.1, 0.018, 0.075), 0.016, R), order=2)
        if look.get('hat') != 'hood':
            add('hoodie', S.ellipsoid(p.neck + R @ V(0, -0.075, -0.02), V(0.11, 0.05, 0.07), R), order=1)
        if look.get('hat') == 'hood':
            for sx in (-1, 1):
                a = p.head + p.Rh @ V(sx * 0.04, 0.03, -0.19)
                add('cord', S.capsule(a, p.chest + R @ V(sx * 0.045, 0.12 * b + loose + 0.01, 0.02), 0.0055), order=3)
    elif top in ('jacket', 'coat', 'suit', 'tweed', 'cardigan', 'whites', 'flannel', 'raincoat'):
        col = look.get('trim_mat', {'jacket': 'jacket_trim', 'coat': 'coat', 'suit': 'suit', 'tweed': 'tweed', 'cardigan': shirt,
               'whites': 'whites', 'flannel': 'flannel', 'raincoat': 'raincoat'}[top])
        if top == 'raincoat':
            # the collar turned up round her neck
            add(col, S.carve(S.cone(p.neck + R @ V(0, 0.004, -0.03), p.neck + R @ V(0, -0.004, 0.06), neck_r + 0.034, neck_r + 0.026),
                             S.cone(p.neck + R @ V(0, 0.004, -0.04), p.neck + R @ V(0, -0.004, 0.08), neck_r + 0.016, neck_r + 0.01)), order=2)
        else:
            band = S.torus(p.neck + R @ V(0, 0.012, -0.012), 0.062 * b ** 0.5 + 0.012, 0.02, R @ S.rot(0, -0.35, 0))
            if look.get('collar') and vneck is not None:
                # round the back of the neck only, going on down the edges of the V (below)
                band = S.carve(band, S.offset(vneck, 0.003), 0.004)
            add(col, band, order=1)
        if vneck is not None:
            # in the V: the shirt (and for a suit, a tie), and the lapels beside it
            under = look.get('under', 'shirt_white' if top == 'suit' else 'tshirt')
            # (a blouse with its collar out is set further in, so the V's edge stands clear of it)
            add(under, S.intersect(S.offset(body, -0.009 if look.get('collar') else -0.004), S.offset(vneck, 0.004)), order=1)
            if look.get('collar'):
                # the cardigan's band down each edge of the V from round the neck, and on down the
                # front under the buttons to the hem
                vb = _loc(lambda q: np.maximum.reduce([np.abs(np.abs(q[:, 0]) * 0.94 - (q[:, 2] + vt) * 0.34 - 0.008) - 0.008,
                                                       -q[:, 1], q[:, 2] + 0.02]), p.neck, R)
                strip = _loc(lambda q: np.maximum.reduce([np.abs(q[:, 0]) - 0.014, q[:, 2] + vt - 0.02, -q[:, 1]]), p.neck, R)
                above = S.halfspace(p.pelvis + R @ V(0, 0, (hem or -0.1) * s), -(R @ V(0, 0, 1)))
                add(col, _panel(body, S.intersect(S.union(vb, strip), above), 0.004), order=2)
                # the blouse's collar out over the V: a point lying on each side of it, on the band.
                # Too fine for the body's grain: head_parts puts it in with the head (p.collar).
                # (e: how far out from the V's edge, across)
                p.collar = []
                for sx in (-1, 1):
                    def pt(q, sx=sx):
                        e = np.abs(q[:, 0]) * 0.94 - (q[:, 2] + vt) * 0.34
                        return np.maximum.reduce([-0.002 - e, e - 0.045, q[:, 2], -0.09 + 1.33 * e - q[:, 2], -sx * q[:, 0], -q[:, 1]])
                    p.collar.append((under, _panel(body, _loc(pt, p.neck, R), 0.006)))
            if top == 'suit':
                add('tie', S.intersect(S.offset(body, -0.0015), _loc(lambda q: np.maximum(np.abs(q[:, 0]) - 0.009 - np.clip(-q[:, 2] - 0.05, 0, 1) * 0.05, -q[:, 1]), p.neck, R)), order=2)
                for sx in (-1, 1):
                    lap = _loc(lambda q, sx=sx: np.maximum.reduce([
                        -(np.abs(q[:, 0]) * 0.94 - (q[:, 2] + vt) * 0.34), (np.abs(q[:, 0]) * 0.94 - (q[:, 2] + vt) * 0.34) - 0.04,
                        -sx * q[:, 0], -q[:, 1], q[:, 2] + 0.005]), p.neck, R)
                    add('suit', _panel(body, lap, 0.004), order=2)
        if top == 'jacket':
            # the ribbed band at the hem, and the snaps down the front
            hemz = p.pelvis + R @ V(0, 0, hem * s)
            add(look.get('trim_mat', 'jacket_trim'), _panel(body, S.intersect(S.halfspace(hemz, -(R @ V(0, 0, 1))), S.halfspace(hemz + R @ V(0, 0, 0.05), R @ V(0, 0, 1))), 0.006), order=2)
            add('jacket', _panel(body, front(-0.014, 0.014, -0.62, -0.02, p.neck), 0.003), order=1)
            for k in range(4):
                c0 = p.neck + R @ V(0, 0, -0.08 - k * 0.1)
                add('button', S.sphere(c0 + _surf(body, c0, R @ V(0, 1, 0)), 0.0065), order=3)
        if top == 'coat':
            add('coat', S.blend(0.05, S.ellipsoid(p.pelvis + R @ V(0, 0.0, -0.12), V(0.19 * b, 0.13 * b, 0.2), R)), order=0)
        if top == 'raincoat':
            # the skirt of it to below the knee, the opening down its front, a belt tied at the waist
            kn = (p.knee[0] + p.knee[1]) / 2
            skirt_lo = kn + V(0, 0.0, -0.17)
            sk = S.blend(0.06, S.ellipsoid(p.pelvis + R @ V(0, 0.0, -0.05), V(0.2 * b, 0.14 * b, 0.16), R),
                         S.cone(p.pelvis + V(0, 0, -0.05), V(skirt_lo[0], skirt_lo[1] + 0.01, skirt_lo[2]), 0.19 * b, 0.24 * b))
            sk = S.intersect(sk, S.halfspace(V(0, 0, skirt_lo[2] - 0.01), V(0, 0, -1)), 0.01)
            sk = folds(sk, p.pelvis, R, 0.004, 0.09, -0.6, -0.05)
            add('raincoat', sk)
            # the front of the coat lapped over from her right, its edge running down to the hem;
            # the hem turned up
            flap = _loc(lambda q: np.maximum.reduce([0.03 - q[:, 0], -q[:, 1], q[:, 2] + 0.02]), p.pelvis, R)
            add('raincoat', _panel(sk, flap, 0.005), order=1)
            add('raincoat', _panel(sk, S.halfspace(V(0, 0, skirt_lo[2] + 0.035), V(0, 0, -1)), 0.004), order=1)
            add('raincoat', _panel(body, _loc(lambda q: np.maximum(np.abs(q[:, 2]) - 0.022, -q[:, 1] - 0.05), p.waist, R), 0.006), order=2)
            c0 = p.waist + R @ V(0.03, 0, 0.0)
            add('raincoat', S.box(c0 + _surf(body, c0, R @ V(0, 1, 0)) + R @ V(0, 0.012, 0), V(0.022, 0.008, 0.02), 0.005, R), order=3)
            for sx in (-1, 1):
                for k in range(3):
                    add('button', S.sphere(p.chest + R @ V(sx * 0.05, 0, 0.06 - k * 0.09) + _surf(body, p.chest + R @ V(sx * 0.05, 0, 0.06 - k * 0.09), R @ V(0, 1, 0)), 0.008), order=3)
        if top in ('cardigan', 'suit', 'tweed', 'jacket', 'coat'):
            for k in range(4 if top == 'cardigan' else 2):
                z = -0.02 - k * 0.07 if top in ('cardigan', 'suit', 'tweed') else 0.05 - k * 0.07
                c0 = p.chest + R @ V(0.0, 0, z)
                add('button', S.sphere(c0 + _surf(body, c0, R @ V(0, 1, 0)), 0.007), order=3)
            if top in ('suit', 'tweed', 'jacket', 'coat'):
                for sx in (-1, 1):
                    # the pocket flaps at the hips
                    add(shirt if top != 'jacket' else 'jacket', _panel(body, front(sx * 0.1 - 0.055, sx * 0.1 + 0.055, -0.03, 0.0, p.pelvis), 0.004), order=2)
        if top == 'cardigan':
            hemz = p.pelvis + R @ V(0, 0, (hem or -0.1) * s)
            add(shirt, _panel(body, S.intersect(S.halfspace(hemz, -(R @ V(0, 0, 1))), S.halfspace(hemz + R @ V(0, 0, 0.04), R @ V(0, 0, 1))), 0.004), order=1)
        if top == 'flannel':
            add(shirt, _panel(body, front(-0.013, 0.013, -0.5, 0.0, p.neck), 0.0025), order=1)
            for sx in (-1, 1):
                add(shirt, _panel(body, front(sx * 0.075 - 0.045, sx * 0.075 + 0.045, 0.02, 0.1, p.chest), 0.004), order=1)
    elif top == 'hivis':
        vest = S.intersect(S.offset(trunk, 0.006), S.box(p.chest + R @ V(0, 0, -0.12), V(0.3, 0.3, 0.3), 0.0, R))
        add('hivis', vest, order=1)
        for zz in (-0.08, -0.2):
            add('reflective', S.intersect(S.offset(trunk, 0.009), S.box(p.chest + R @ V(0, 0, zz), V(0.3, 0.3, 0.013), 0.0, R)), order=2)
        add('sweatshirt', S.torus(p.neck + R @ V(0, 0.014, -0.002), neck_r + 0.006, 0.008, Rn), order=2)
    elif top == 'apron':
        add('apron', S.intersect(S.offset(trunk, 0.008), S.box(p.pelvis + R @ V(0, 0.2, 0.02), V(0.15, 0.2, 0.2), 0.0, R)), order=1)
        for i in range(2):
            add('apron', S.cone(p.hip[i] + R @ V(0, 0.04, 0.02), p.knee[i] + R @ V(0, 0.06, 0.0), 0.095, 0.075), order=1)
        add('apron', S.torus(p.waist + R @ V(0, 0, 0.0), 0.15 * b + 0.01, 0.008, R), order=2)
        add(shirt, S.torus(p.neck + R @ V(0, 0.012, -0.004), neck_r + 0.005, 0.006, Rn), order=2)
    if 'lanyard' in look.get('extra', ()):
        # a lanyard round the neck with the key card on it, hanging straight down off the chest
        # whichever way he leans. Too thin to sculpt at this grain: export_people.py makes it.
        fwd = R @ V(0, 1, 0)
        out = norm(V(fwd[0], fwd[1], 0.0))
        tip = p.neck + R @ V(0, 0.07 * b + loose + 0.01, -0.06) + V(0, 0, -0.12)
        for _ in range(40):
            if body(tip[None, :])[0] > 0.014:
                break
            tip = tip + out * 0.005
        side = norm(np.cross(V(0, 0, 1), out))
        straps = [(p.neck + R @ V(sx * (neck_r + 0.006), 0.006, -0.018), tip + V(sx * 0.005, 0, 0.01)) for sx in (-1, 1)]
        p.props = list(getattr(p, 'props', [])) + [dict(kind='lanyard', at=tip, straps=straps, R=S.frame(side, V(0, 0, 1)))]
    if 'chain' in look.get('extra', ()):
        # the chain of her reading glasses: fixed behind each ear, hanging down by her neck and round
        # the back of it on her collar, let fall there and left to settle
        on = S.union(body, head_world(B, p, head_of(B, look).skin),
                     S.cone(p.neck + R @ V(0, 0.0, -0.03), p.head + p.Rh @ V(0, -0.016, -0.11), neck_r, 0.042))
        if top in ('cardigan', 'jacket', 'coat', 'suit', 'tweed', 'whites', 'flannel'):
            on = S.union(on, S.torus(p.neck + R @ V(0, 0.012, -0.012), 0.062 * b ** 0.5 + 0.012, 0.02, R @ S.rot(0, -0.35, 0)))
        ends = readers_ends(B, p)
        r, gap, length = 0.0011, 0.0032, 0.62
        n = int(round(length / gap)) + 1
        way = [ends[0], ends[0] + V(0, 0, -0.07)] + [p.neck + R @ V(rb * np.sin(a), -rb * np.cos(a), -0.03 - 0.03 * np.cos(a))
                                                      for a, rb in zip(np.linspace(-np.pi / 2, np.pi / 2, 9), [0.1] * 9)]
        way += [ends[1] + V(0, 0, -0.07), ends[1]]
        way = np.array(way, dtype=np.float32)
        sw = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(way, axis=0), axis=1))])
        u = np.linspace(0, sw[-1], n)
        X0 = np.stack([np.interp(u, sw, way[:, j]) for j in range(3)], axis=1).astype(np.float32)
        X = drape(on, X0, [gap] * n, r + 0.001, [1.0] * n, closed=False, pinned=(0, n - 1), iters=500, settle=150)
        p.props = list(getattr(p, 'props', [])) + [dict(kind='chain', at=X[n // 2], links=list(X), r=r, R=np.eye(3, dtype=np.float32))]
    if 'mala' in look.get('extra', ()):
        # under the jacket, if there's one: on the shirt and its neck, round his neck
        on = S.union(body, S.torus(p.neck + R @ V(0, 0.014, -0.002), neck_r + 0.004, 0.0055, Rn),
                     S.cone(p.neck + R @ V(0, 0.0, -0.03), p.head + p.Rh @ V(0, -0.025, -0.07), neck_r, 0.05))
        p.props = list(getattr(p, 'props', [])) + [mala(p, on, neck_r)]
    if look.get('over') == 'jacket':
        # what long hair lies on (head_parts)
        p.outer = over_jacket(B, p, look, body, add)
    elif look.get('over') == 'vest':
        p.outer = over_vest(B, p, look, body, add)
    return parts


def _surf(f, o, d, far=0.3):
    """From o (inside f) along d to f's surface: to set a button on the cloth."""
    d = norm(V(*d))
    o = V(*o)
    lo, hi = 0.0, far
    for _ in range(24):
        m = (lo + hi) / 2
        if float(f((o + d * m)[None, :])[0]) < 0:
            lo = m
        else:
            hi = m
    return d * lo


def crease(f, a, b, out):
    """A sleeve ironed flat: its section drawn to an edge along the side `out` (from the arm's axis
    a..b), the crease pressed down it."""
    a, b = V(*a), V(*b)
    ax = norm(b - a)
    o = norm(V(*out) - ax * float(np.dot(V(*out), ax)))
    def g(P):
        q = P - a
        r = q - (q @ ax)[:, None] * ax[None, :]
        c = (r @ o) / np.maximum(np.linalg.norm(r, axis=1), 1e-6)
        return f(P) - 0.004 * np.clip(c, 0.0, 1.0) ** 12
    return g


def knuckle_scars(h):
    """Old scars over the knuckles of a hand that's hit things: pale marks across the backs of the
    first two and a nick on the third, laid on the skin."""
    k = h.k
    on = h.sdf()
    marks = []
    for i, (dx, l, w) in enumerate(((0.0, 0.009, 0.0026), (0.002, 0.007, 0.0022), (-0.001, 0.004, 0.002))):
        kn = FINGERS[i][0]
        c = h.w(V(kn[0] + dx, kn[1] - 0.002, kn[2] - 0.009))
        R = S.frame(h.dirw((1.0, 0.25, 0.0)), h.dirw((-0.25, 1.0, 0.0)))
        marks.append(S.ellipsoid(c, V(l, w, 0.01) * k, R))
    return _panel(on, S.union(*marks), 0.0007)


def _grad(f, X, h=0.0005):
    """Which way f rises at each point (not normalised)."""
    e = np.eye(3, dtype=np.float32) * h
    return np.stack([(f(X + e[i]) - f(X - e[i])) / (2 * h) for i in range(3)], axis=1)


def drape(f, X, rest, clear, weight, closed=True, pinned=(), iters=700, grip=0.4, passes=8, settle=0):
    """Beads on a string let fall onto f and left to settle: X (N x 3) where they start, rest[i] the
    string from bead i to the next, clear how far each bead's middle keeps off f, weight how hard
    gravity pulls each. They keep their spacing and stay out of f, and where they touch it they
    slide only reluctantly (grip: how much of their speed they keep); the pinned ones stay put, and
    no bead gets further from one than the string between them. Then `settle` more rounds without
    gravity draw the string back to its length where it's still stretched."""
    X = np.asarray(X, dtype=np.float32).copy()
    Xp = X.copy()
    N = len(X)
    free = np.ones(N, dtype=np.float32)
    free[list(pinned)] = 0.0
    fall = V(0, 0, -0.00025) * np.asarray(weight, dtype=np.float32)[:, None] * free[:, None]
    rest = np.asarray(rest, dtype=np.float32)
    # the nearest pinned bead each way along the string from each bead, and the string between
    tied = []
    for step in ((1, -1) if closed else (1, -1)):
        to, far = np.zeros(N, dtype=int), np.full(N, np.inf, dtype=np.float32)
        for i in range(N):
            d, j = 0.0, i
            for _ in range(N):
                if free[j] == 0.0:
                    to[i], far[i] = j, d
                    break
                if not closed and (j + step < 0 or j + step >= N):
                    break
                d += float(rest[j] if step > 0 else rest[(j - 1) % N])
                j = (j + step) % N
        if np.isfinite(far).any():
            tied.append((to, np.where(np.isfinite(far), far, 1e9).astype(np.float32)))
    for it in range(iters + settle):
        if it < iters:
            keep = np.where(f(X) < clear + 0.0015, grip, 0.88).astype(np.float32)
            Xn = X + (X - Xp) * (keep * free)[:, None] + fall
            Xp, X = X, Xn
        for _ in range(passes):
            nxt = np.roll(X, -1, axis=0)
            d = nxt - X
            L = np.linalg.norm(d, axis=1)
            c = ((L - rest) / np.maximum(L, 1e-9))[:, None] * d
            if not closed:
                c[-1] = 0.0
            # each end of a link moves half of its stretch, or all of it when the other is pinned
            wa = free / np.maximum(free + np.roll(free, -1), 1e-9)
            wb = free / np.maximum(free + np.roll(free, 1), 1e-9)
            X = X + 0.9 * (c * wa[:, None] - np.roll(c, 1, axis=0) * wb[:, None])
            for to, far in tied:
                d = X - X[to]
                L = np.linalg.norm(d, axis=1)
                X = X - (d * (np.maximum(L - far, 0.0) / np.maximum(L, 1e-9))[:, None]) * free[:, None]
            dist = f(X)
            near = (dist < clear) & (free > 0)
            if near.any():
                n = _grad(f, X[near])
                n = n / np.maximum(np.linalg.norm(n, axis=1), 1e-9)[:, None]
                X[near] = X[near] + n * (clear - dist[near])[:, None]
        if it >= iters:
            Xp = X.copy()
    return X


def _drop(f, c, up, clear, far=0.12):
    """From above c, down along -up onto f, to where a bead's middle stops clear of it."""
    x = c + up * far
    for _ in range(int(far * 2 / 0.002)):
        if float(f(x[None, :])[0]) < clear:
            break
        x = x - up * 0.002
    lo, hi = 0.0, 0.002
    for _ in range(16):
        m = (lo + hi) / 2
        if float(f((x + up * m)[None, :])[0]) < clear:
            lo = m
        else:
            hi = m
    return x + up * hi


def mala(p, on, neck_r, n=108, r=0.0045):
    """A mala round the neck, on the shirt (on: the shirt and its neck): n wooden beads r across and
    the guru bead. Round the back of the neck it lies where the neck meets the shoulders, and stays
    there (the collar and the hair hold it); from either side of the neck the two strands are let
    fall onto the chest and left to settle, meeting at the guru bead at the breastbone; under it the
    tassel. Too small to sculpt at the body's grain: export_people.py makes the beads, from their
    centres here."""
    R = p.R
    up = R @ V(0, 0, 1)
    rg = r * 1.4
    gap = 2 * r * 1.02
    clear = r + 0.0012
    tie = rg + r + 0.0004
    # round the back: each point let down onto the shoulders close in to the neck, the beads spaced
    # out along it from the middle
    rb = neck_r + clear + 0.002
    arc = np.array([_drop(on, p.neck + R @ V(rb * np.sin(a), -rb * np.cos(a), 0.0), up, clear)
                    for a in np.linspace(-np.pi / 2, np.pi / 2, 91)], dtype=np.float32)
    sa = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(arc, axis=0), axis=1))])
    pos = sa[-1] / 2 + (np.arange(1, n + 1) - (n + 1) / 2) * gap
    back = np.flatnonzero((pos >= 0) & (pos <= sa[-1]))
    X = np.zeros((n + 1, 3), dtype=np.float32)
    X[back + 1] = np.stack([np.interp(pos[back], sa, arc[:, j]) for j in range(3)], axis=1)
    # the strands: from the ends of the back down to the guru bead on the breastbone, laid straight
    # and out of the shirt to start with
    k0, k1 = back[0] + 1, back[-1] + 1
    length = (k0 - 1) * gap + tie
    A = [X[k0], X[k1]]
    mid = (A[0] + A[1]) / 2
    G = None
    for z in np.linspace(-0.1, -0.4, 61):
        g = p.neck + R @ V(0, 0, z)
        g = g + R @ V(0, 1, 0) * float(np.linalg.norm(_surf(on, g, R @ V(0, 1, 0)))) + R @ V(0, clear, 0)
        if np.linalg.norm(g - A[0]) > length * 0.95:
            break
        G = g
    X[0] = G
    for j in range(1, k0):
        X[j] = G + (A[0] - G) * (j * gap + tie - gap) / length
    for j in range(k1 + 1, n + 1):
        X[j] = G + (A[1] - G) * ((n + 1 - j) * gap + tie - gap) / length
    for j in list(range(0, k0)) + list(range(k1 + 1, n + 1)):
        d = float(on(X[j][None, :])[0])
        if d < clear:
            X[j] = X[j] + R @ V(0, 1, 0) * (clear - d + 0.002)
    rest = [tie] + [gap] * (n - 1) + [tie]
    X = drape(on, X, rest, clear, [4.0] + [1.0] * n, pinned=back + 1, settle=200)
    guru, beads = X[0], list(X[1:])
    # the tassel: a short chain of its own hanging from the guru bead
    T0 = np.array([guru + V(0, 0, -(rg + 0.004 + 0.016 * j)) for j in range(5)], dtype=np.float32)
    T = drape(on, T0, [0.016] * 5, 0.0062, [1.0] * 5, closed=False, pinned=(0,), iters=300)
    top, bot = T[0], T[-1]
    return dict(kind='mala', at=guru, beads=beads, r=r, guru_r=rg, tassel=(top, bot),
                R=S.frame(R @ V(1, 0, 0), norm(top - bot)))


def _front(R, o, x0, x1, z0, z1):
    """The front of the trunk (frame R about o) between x0..x1 across and z0..z1 up: a pocket, a flap."""
    return _loc(lambda q: np.maximum.reduce([np.abs(q[:, 0] - (x0 + x1) / 2) - (x1 - x0) / 2,
                                             np.abs(q[:, 2] - (z0 + z1) / 2) - (z1 - z0) / 2, -q[:, 1]]), o, R)


def over_jacket(B, p, look, body, add):
    """A work jacket of canvas worn open over the shirt (body: the shirt's shape): standing off it,
    hanging open down the front from the collar to the hem, so the shirt shows down the middle; a
    collar turned down round the neck, sleeves to the wrist, a patch pocket on each side of the
    chest, and the buttons down its right front. Returns its outside, for long hair to lie on."""
    mat = look.get('over_mat', 'doorman_jacket')
    s, b = B.size, B.bulk
    ab = b ** 0.75
    R = p.R
    up = R @ V(0, 0, 1)
    hands = getattr(p, 'hands', [None, None])
    jb = S.offset(body, 0.017)
    # open down the front: a little at the collar, falling wider toward the hem round his belly
    w = lambda z: 0.06 + 0.1 * np.clip((-z - 0.08) / 0.42, 0.0, 1.0)
    opening = _loc(lambda q: np.maximum(np.abs(q[:, 0]) - w(q[:, 2]), 0.03 - q[:, 1]), p.neck, R)
    hem = S.halfspace(p.pelvis + R @ V(0, 0, -0.17 * s), -up)
    jacket = S.carve(S.intersect(jb, hem, 0.006), opening, 0.003)
    add(mat, jacket)
    # the collar, turned down, open where the front is
    neck_r = 0.056 * b ** 0.5
    col = S.torus(p.neck + R @ V(0, 0.004, -0.018), neck_r + 0.03, 0.019, R @ S.rot(0, -0.32, 0))
    add(mat, S.carve(col, opening, 0.003), order=1)
    # the sleeves, the creases in the crook of the arm and bunched above the cuff
    for i in range(2):
        sh, el, wr = p.sh[i], p.elbow[i], p.wrist[i]
        d = norm(wr - el)
        sx = -1.0 if i == 0 else 1.0
        grp = ('hand_l' if i == 0 else 'hand_r') if hands[i] is not None else None
        jl = 0.019
        upper = S.blend(0.03, S.sphere(sh + R @ V(sx * 0.008, 0, -0.012), 0.047 * ab + jl + 0.006),
                        S.cone(sh, el, 0.049 * ab + jl, 0.041 * ab + jl + 0.002))
        upper = rings(upper, el, -(el - sh), 0.0018, 0.024, 0.0, 0.08)
        fore = rings(S.cone(el, wr - d * 0.03, 0.041 * ab + jl + 0.002, 0.031 * ab + jl * 0.8), el, d, 0.0022, 0.026, 0.12, 0.25)
        add(mat, S.blend(0.02, upper, fore))
        r0, r1 = 0.032 * b + jl * 0.75, 0.03 * b + jl * 0.65
        cuff = S.cone(wr - d * 0.06, wr - d * 0.006, r0, r1)
        rin = r1 - 0.004
        add(mat, S.carve(cuff, S.capsule(wr - d * (0.016 - rin), wr + d * 0.05, rin), 0.0015), order=1, group=grp)
    # a patch pocket on each side of the chest, and its flap
    for sx in (-1, 1):
        x = sx * 0.145 * b ** 0.5
        add(mat, _panel(jacket, _front(R, p.chest, x - 0.048, x + 0.048, -0.075, 0.05), 0.004), order=1)
        add(mat, _panel(jacket, _front(R, p.chest, x - 0.051, x + 0.051, 0.022, 0.058), 0.007), order=2)
    # the buttons down his right front, a little in from its edge, all undone
    for k in range(5):
        z = -0.1 - k * 0.1
        c0 = p.neck + R @ V(float(w(np.array([z]))[0]) + 0.016, 0.0, z)
        add('button', S.sphere(c0 + _surf(jacket, c0, R @ V(0, 1, 0)), 0.0065), order=3)
    return S.union(jacket, col)


def over_vest(B, p, look, body, add):
    """A plain work vest of padded canvas over the hoodie, unzipped: standing off it, open down the
    front (wider below, so the pouch shows), its edges rounded over the padding, the armholes cut
    deep for the hoodie's sleeves, its back under the fallen hood, its hem at the hips above the
    hoodie's; a pocket low on each side. Returns its outside."""
    mat = look.get('over_mat', 'workjacket')
    s = B.size
    R = p.R
    up = R @ V(0, 0, 1)
    vb = S.offset(body, 0.014)
    w = lambda z: 0.04 + 0.075 * np.clip((-z - 0.12) / 0.3, 0.0, 1.0)
    opening = _loc(lambda q: np.maximum(np.abs(q[:, 0]) - w(q[:, 2]), 0.03 - q[:, 1]), p.neck, R)
    hem = S.halfspace(p.pelvis + R @ V(0, 0, -0.05 * s), -up)
    vest = S.carve(S.intersect(vb, hem, 0.008), opening, 0.008)
    # the neckline, and the hood lying over the back of it
    vest = S.carve(vest, S.ellipsoid(p.neck + R @ V(0, 0.0, 0.025), V(0.075, 0.075, 0.06), R), 0.008)
    vest = S.carve(vest, S.ellipsoid(p.neck + R @ V(0, -0.075, -0.02), V(0.116, 0.056, 0.076), R), 0.006)
    for i, sx in enumerate((-1, 1)):
        # the armhole: from the top of the shoulder well down the side
        vest = S.carve(vest, S.ellipsoid(p.sh[i] + R @ V(sx * 0.03, 0.0, -0.085), V(0.07, 0.082, 0.11), R), 0.008)
    add(mat, vest, order=1)
    # a pocket low on each front
    for sx in (-1, 1):
        x = sx * 0.125 * B.bulk
        add(mat, _panel(vest, _front(R, p.pelvis, x - 0.05, x + 0.05, 0.0, 0.11), 0.005), order=2)
    return vest


# ---------------------------------------------------------------------------------------- hands

def turn(v, axis, ang):
    """v turned about the unit axis by ang radians."""
    c, s_ = np.cos(ang), np.sin(ang)
    return v * c + np.cross(axis, v) * s_ + axis * float(np.dot(axis, v)) * (1.0 - c)


# A man's right hand in its own frame, in metres: x toward the thumb, y along the hand from the
# middle of the wrist, z out of the palm (a left hand is its mirror). Each finger: its knuckle, how
# far it fans toward the thumb (radians), its three bones, and its radius at the knuckle, the two
# joints and the tip.
FINGERS = (
    ((0.0245, 0.087, 0.0005), 0.07, (0.040, 0.024, 0.0185), (0.0097, 0.0089, 0.0078, 0.0068)),    # index
    ((0.0062, 0.092, -0.001), 0.0, (0.045, 0.028, 0.0195), (0.0099, 0.0091, 0.0080, 0.0070)),     # middle
    ((-0.0118, 0.088, 0.0), -0.07, (0.042, 0.026, 0.019), (0.0093, 0.0086, 0.0075, 0.0066)),      # ring
    ((-0.0275, 0.078, 0.003), -0.16, (0.033, 0.019, 0.017), (0.0083, 0.0076, 0.0067, 0.0059)),    # little
)
# the thumb: where its long bone starts (low on the heel of the hand), its three bones, its radii
THUMB = ((0.0195, 0.027, 0.011), (0.046, 0.033, 0.026), (0.0122, 0.0112, 0.0101, 0.0088))
# how a hand sits: the curl of each finger at its knuckle, middle and end joints (index to little),
# and the thumb: its spread from the fingers, its lift out of the palm, its roll to face them, and
# the bend at its two joints
GRIPS = {
    'relaxed': ([(0.3, 0.45, 0.22), (0.36, 0.52, 0.25), (0.42, 0.6, 0.28), (0.5, 0.66, 0.3)], (0.55, 0.42, 0.3, 0.2, 0.25)),
    'open': ([(0.1, 0.16, 0.08), (0.13, 0.18, 0.09), (0.16, 0.22, 0.1), (0.2, 0.26, 0.12)], (0.75, 0.3, 0.15, 0.1, 0.12)),
    'flat': ([(0.02, 0.04, 0.02)] * 4, (0.65, 0.12, 0.0, 0.05, 0.05)),
    'fist': ([(1.45, 1.7, 0.9), (1.5, 1.75, 0.9), (1.55, 1.75, 0.9), (1.55, 1.75, 0.9)], (0.3, 0.85, 1.1, 0.55, 0.45)),
}


class Hand:
    """A hand with fingers. Its frame is at the middle of the wrist: `along` runs toward the
    fingers, `palm` out of the palm. The fingers sit as a grip has them, or close round a thing (a
    distance function) until each bone touches it."""
    def __init__(self, B, wrist, along, palm, right, grip='relaxed', size=1.0):
        self.k = B.size * (0.92 if B.f else 1.0) * size
        u = norm(V(*along))
        n = V(*palm)
        n = norm(n - u * float(np.dot(n, u)))
        t = np.cross(u, n) if right else np.cross(n, u)
        self.o, self.right = V(*wrist), right
        self.M = np.stack([t, u, n], axis=1).astype(np.float32)
        c, th = GRIPS[grip]
        self.curls = [list(x) for x in c]
        self.th = list(th)

    def w(self, q):
        """Point(s) in the hand's frame (unscaled metres) to the world."""
        return (self.o + (np.asarray(q, dtype=np.float32) * self.k) @ self.M.T).astype(np.float32)

    def dirw(self, d):
        return (self.M @ np.asarray(d, dtype=np.float32)).astype(np.float32)

    def finger(self, i, curl=None):
        """The knuckle, the two joints and the tip of finger i (0 index .. 3 little), in the frame."""
        base, splay, L, _ = FINGERS[i]
        c = self.curls[i] if curl is None else curl
        u0 = V(np.sin(splay), np.cos(splay), 0.0)
        ax = norm(np.cross(u0, V(0, 0, 1)))
        pts, a = [V(*base)], 0.0
        for j in range(3):
            a += c[j]
            pts.append(pts[-1] + turn(u0, ax, a) * L[j])
        return pts

    def thumb(self, th=None):
        """The thumb's root, its two joints and its tip, and which way its bone and its pad face."""
        spread, lift, roll, b1, b2 = self.th if th is None else th
        base, L, _ = THUMB
        d0 = V(np.sin(spread) * np.cos(lift), np.cos(spread) * np.cos(lift), np.sin(lift))
        pad = V(-1, 0, 0)
        pad = norm(pad - d0 * float(np.dot(pad, d0)))
        pad = turn(pad, d0, roll)
        ax = norm(np.cross(d0, pad))
        p0 = V(*base)
        p1 = p0 + d0 * L[0]
        p2 = p1 + turn(d0, ax, b1) * L[1]
        p3 = p2 + turn(d0, ax, b1 + b2) * L[2]
        return [p0, p1, p2, p3], d0, pad

    def tip(self, i):
        """Where the pad of finger i (4: the thumb) is, in the world."""
        if i == 4:
            pts, _, _ = self.thumb()
            return self.w(pts[3])
        return self.w(self.finger(i)[3])

    def _touch(self, pts, radii, obj, gap):
        """The first bone of a chain that goes into obj, or None."""
        for j in range(len(pts) - 1):
            ts = np.linspace(0.2 if j == 0 else 0.0, 1.0, 7)[:, None]
            q = pts[j][None, :] * (1 - ts) + pts[j + 1][None, :] * ts
            r = (radii[j] * (1 - ts) + radii[j + 1] * ts)[:, 0] * self.k
            if (obj(self.w(q)) - r < -gap).any():
                return j
        return None

    def _close(self, chain, radii, a0, a1, obj, gap, steps):
        a0, a1 = np.array(a0, float), np.array(a1, float)
        cur, free = a0.copy(), np.ones(len(a0), bool)
        if self._touch(chain(cur), radii, obj, gap) is not None:
            return cur
        for s in range(1, steps + 1):
            trial = np.where(free, a0 + (a1 - a0) * (s / steps), cur)
            j = self._touch(chain(trial), radii, obj, gap)
            if j is None:
                cur = trial
                continue
            free[:j + 1] = False          # the bone that touched and the joints behind it stay
            if not free.any():
                break
        return cur

    def close(self, obj, fingers=(0, 1, 2, 3), thumb=True, to='fist', gap=0.0006, steps=60):
        """Curl the fingers (and the thumb's two joints) toward the grip `to`, each bone stopping
        where it touches obj."""
        tc, tt = GRIPS[to] if isinstance(to, str) else to
        for i in fingers:
            self.curls[i] = list(self._close(lambda a: self.finger(i, a), FINGERS[i][3], self.curls[i], tc[i],
                                             obj, gap, steps))
        if thumb:
            def chain(a):
                return self.thumb(self.th[:3] + list(a))[0][1:]
            self.th[3:] = list(self._close(chain, THUMB[2][1:], self.th[3:], tt[3:], obj, gap, steps))

    def sdf(self, nails=False):
        """The hand as one shape: the palm, and each finger and the thumb melted into it but not into
        each other, so they part with a clean crease."""
        k, W, M = self.k, self.w, self.M
        E = lambda c, r: S.ellipsoid(W(c), V(*r) * k, M)
        tpts, d0, pad = self.thumb()
        fore = getattr(self, 'fore', None)
        if fore is None:
            fore = -self.dirw((0.0, 1.0, 0.0))
        nn = self.dirw((0.0, 0.0, 1.0))
        nn = norm(nn - fore * float(np.dot(nn, fore)))
        Rw = S.frame(norm(np.cross(fore, nn)), fore)
        palm = [S.ellipsoid(self.o + fore * 0.008 * k, V(0.0265, 0.028, 0.017) * k, Rw),           # the wrist, on the forearm
                E((0, 0.004, 0.0), (0.027, 0.018, 0.0165)),                       # and where the hand leaves it
                E((0.001, 0.021, 0.003), (0.03, 0.025, 0.0165)),                  # the heel of the hand
                E((-0.003, 0.056, 0.004), (0.034, 0.038, 0.0115)),                # the flesh of the palm
                E((-0.024, 0.042, 0.005), (0.0115, 0.03, 0.0115)),                # the pad below the little finger
                S.capsule(W((0.021, 0.081, 0.006)), W((-0.025, 0.073, 0.008)), 0.0088 * k)]   # the pads at the fingers' roots
        for x0, f, r in zip((0.014, 0.005, -0.006, -0.016), FINGERS, (0.0103, 0.0106, 0.01, 0.0093)):
            palm.append(S.capsule(W((x0, 0.024, -0.003)), W(f[0]), r * k))    # the long bones out to the knuckles
        # the ball of the thumb, along its long bone
        palm.append(S.ellipsoid(W(tpts[0] + d0 * 0.02 + V(-0.004, 0.0, 0.004)), V(0.0155, 0.025, 0.0125) * k,
                                S.frame(self.dirw(pad), self.dirw(d0))))
        palmf = S.blend(0.011 * k, *palm)
        fingers = []
        for i in range(4):
            pts = self.finger(i)
            r = FINGERS[i][3]
            P = [W(q) for q in pts]
            segs = [S.cone(P[j], P[j + 1], r[j] * k, r[j + 1] * k) for j in range(3)]
            segs += [S.sphere(P[1], r[1] * 1.035 * k), S.sphere(P[2], r[2] * 1.035 * k),
                     S.sphere(W(pts[0] + V(0, 0, -0.0028)), r[0] * 1.06 * k)]    # the knuckles
            if nails:
                segs.append(self._nail(pts, i))
            fingers.append(S.blend(0.0022 * k, *segs))
        T = [W(q) for q in tpts]
        tr = THUMB[2]
        tsegs = [S.cone(T[j], T[j + 1], tr[j] * k, tr[j + 1] * k) for j in range(3)]
        tsegs += [S.sphere(T[1], tr[1] * 1.03 * k), S.sphere(T[2], tr[2] * 1.03 * k)]
        thumbf = S.blend(0.003 * k, *tsegs)
        kf, kt = 0.0055 * k, 0.009 * k
        def f(P):
            dp = palmf(P)
            out = S._smin(dp, thumbf(P), kt)
            for g in fingers:
                out = np.minimum(out, S._smin(dp, g(P), kf))
            return out
        return f

    def _nail(self, pts, i):
        """A fingernail: a thin plate on the back of the last bone."""
        r = FINGERS[i][3]
        d = norm(pts[3] - pts[2])
        side = norm(np.cross(d, V(0, 0, 1)) if abs(d[2]) < 0.95 else V(1, 0, 0))
        back = norm(np.cross(side, d))            # the back of the finger (away from the palm)
        if back[2] > 0:
            back = -back
        c = pts[2] + d * (FINGERS[i][2][2] * 0.62) + back * (r[2] * 0.72)
        R = S.frame(self.dirw(side), self.dirw(d))
        return S.ellipsoid(self.w(c), V(r[3] * 0.72, FINGERS[i][2][2] * 0.5, 0.0024) * self.k, R)


def shoe(ankle, toe_dir, s, look):
    fwd = norm(V(toe_dir[0], toe_dir[1], 0.0) + 1e-6)
    side = norm(np.cross(fwd, V(0, 0, 1)))
    base = V(ankle[0], ankle[1], ankle[2] - 0.075)
    c = base + fwd * 0.055 * s
    up = V(0, 0, 1)
    R = S.frame(side, fwd)
    return S.blend(0.03, S.box(c + up * 0.045, V(0.048 * s, 0.13 * s, 0.035), 0.03, R),
                   S.ellipsoid(ankle - fwd * 0.01, V(0.045, 0.05, 0.05)))


def sole(ankle, toe_dir, s, look):
    fwd = norm(V(toe_dir[0], toe_dir[1], 0.0) + 1e-6)
    side = norm(np.cross(fwd, V(0, 0, 1)))
    base = V(ankle[0], ankle[1], ankle[2] - 0.075)
    return S.box(base + fwd * 0.055 * s + V(0, 0, 0.013), V(0.051 * s, 0.133 * s, 0.013), 0.012, S.frame(side, fwd))


# ---------------------------------------------------------------------------------------- head

def head_parts(B, p, look):
    """The head at p.head turned by p.Rh: the face (tools/head.py, its numbers from the look), and
    on it the hair, a hat, glasses, a beard."""
    H, R = p.head, p.Rh
    s = head_scale(B)
    at = lambda x, y, z: H + R @ (V(x, y, z) * s)
    dirn = lambda x, y, z: R @ norm(V(x, y, z))
    F = look.get('face', [])
    parts = []
    add = lambda name, f, order=0: parts.append(Part(name, f, order=order))
    hair_mat = look.get('hair_mat', 'hair')
    hd = head_of(B, look)
    world = lambda f: head_world(B, p, f)
    head = world(hd.skin)
    skull = world(hd.skull)
    brain = skull
    add('skin', head)
    add('lip', world(hd.lip_skin), order=1)
    # the brows the hair's colour, greying with no hair to go by
    brow_mat = look.get('brow_mat') or ('hair_grey' if B.old and look.get('hair') in ('bald', 'thin') and hair_mat == 'hair' else hair_mat)
    add(brow_mat, world(hd.brow_skin), order=2)
    for name, f, order in hd.parts[3:]:
        add(name, world(f), order=order)
    if 'earbuds' in F:
        for sx in (-1, 1):
            add('earbud', S.ellipsoid(at(sx * 0.074, -0.004, -0.008), V(0.008, 0.009, 0.011) * s, R), order=3)
    if 'hearingaid' in F:
        add('earbud', S.ellipsoid(at(-0.084, -0.02, 0.0), V(0.006, 0.01, 0.016) * s, R), order=3)
    if 'glasses' in F:
        for sx in (-1, 1):
            add('glasses', S.torus(at(sx * 0.032, 0.098, 0.006), 0.019 * s, 0.0022 * s, R @ S.rot(0, np.pi / 2, 0)), order=3)
            add('glasses', S.capsule(at(sx * 0.05, 0.096, 0.008), at(sx * 0.074, 0.01, 0.01), 0.0018 * s), order=3)
        add('glasses', S.capsule(at(-0.013, 0.1, 0.01), at(0.013, 0.1, 0.01), 0.002 * s), order=3)
    if 'readers' in F:
        # reading glasses down her nose: a half-moon frame under each lens, straight across its top,
        # the arms back over the ears to behind them (where the chain is fixed: readers_ends)
        rr = 0.021
        for sx in (-1, 1):
            c = at(sx * 0.03, 0.104, -0.016)
            rim = S.intersect(S.torus(c, rr * s, 0.0016 * s, R @ S.rot(0, np.pi / 2, 0)), S.halfspace(c, dirn(0, 0, 1)))
            add('glasses', S.union(rim, S.capsule(c - dirn(1, 0, 0) * rr * s, c + dirn(1, 0, 0) * rr * s, 0.0016 * s)), order=3)
            # the arm, held off the side of the head on its way back to the ear
            path = [at(sx * (0.03 + rr), 0.104, -0.016), at(sx * 0.068, 0.07, 0.0), at(sx * 0.074, 0.03, 0.01), at(sx * 0.073, 0.0, 0.016),
                    readers_ends(B, p)[(sx + 1) // 2]]
            for j in (1, 2, 3):
                for _ in range(20):
                    if float(head(path[j][None, :])[0]) > 0.0025:
                        break
                    path[j] = path[j] + dirn(sx, 0, 0) * 0.001
            add('glasses', S.union(*[S.capsule(path[j], path[j + 1], 0.0014 * s) for j in range(4)]), order=3)
        add('glasses', S.capsule(at(-0.03 + rr * 0.55, 0.106, -0.012), at(0.03 - rr * 0.55, 0.106, -0.012), 0.0016 * s), order=3)
    for name, f in getattr(p, 'collar', ()):
        add(name, f, order=3)
    beard_mat = look.get('beard_mat', hair_mat)
    zone = world(hd.beard_zone)
    if 'beard' in F:
        add(beard_mat, world(hd.full_beard), order=1)
    elif 'moustache' in F:
        add(beard_mat, world(hd.moustache), order=1)
    elif 'stubble' in F:
        # (deep into the skin, so it meshes whole at any step: only its face shows)
        add('stubble', S.intersect(S.carve(S.offset(head, 0.0008 * s), S.offset(head, -0.005 * s)), zone), order=1)
    # hair
    hair = look.get('hair', 'short')
    hat = look.get('hat')
    face_hole = S.ellipsoid(at(0, 0.1, 0.012), V(0.08, 0.06, 0.068) * s, R)
    # a hat's crown ends on a plane that rises from the nape to above the brow, so it never comes
    # down into the eyes
    over = lambda z0, rise: S.halfspace(at(0, 0.0, z0), dirn(0, rise, -1))
    # hair t deep over the skull, thinning to a third of that at its edge round the face
    def shell(t, hole, fade=0.016):
        return lambda P: skull(P) - s * np.maximum(t * (0.33 + 0.67 * np.clip(hole(P) / (fade * s), 0.0, 1.0)), min(t, 0.003))
    # and never over the face: where the face stands out of it (the cheeks), it gives way
    face_clear = S.intersect(S.intersect(S.offset(head, 0.003 * s), S.halfspace(at(0, 0.03, 0), dirn(0, -1, 0))),
                             S.halfspace(at(0, 0, -0.005), dirn(0, 0, 1)))

    def cropped_short(t, hole):
        # short hair all round, t deep, off the face and up off the nape
        h = S.intersect(shell(t, hole), S.carve(S.box(at(0, -0.01, 0.05), V(0.1, 0.12, 0.095) * s, 0.0, R), hole, 0.01))
        return S.intersect(h, S.halfspace(at(0, 0.0, -0.022), dirn(0, 0.4, -1)), 0.004)
    if hat in ('cap', 'flatcap', 'beanie'):
        # under a cap or a toque: what shows of short hair below its edge, over the ears and down the
        # nape (a bun low at the back of the head, under the cap's band)
        add(hair_mat, cropped_short(0.006, face_hole), order=1)
        if hair == 'bun':
            add(hair_mat, S.ellipsoid(at(0, -0.104, -0.004), V(0.03, 0.026, 0.024) * s, R), order=1)
    if hat is None:
        if hair in ('short', 'parted', 'messy'):
            h = S.intersect(shell(0.009, face_hole), S.carve(S.box(at(0, -0.01, 0.05), V(0.1, 0.12, 0.095) * s, 0.0, R), face_hole, 0.01))
            h = S.intersect(h, S.halfspace(at(0, 0.0, -0.022), dirn(0, 0.4, -1)), 0.004)
            if hair == 'messy':
                h = S.ripple(h, 0.003, 180.0, (0.3, 0.7, 0.2))
            add(hair_mat, h, order=1)
        elif hair == 'buzz':
            add(hair_mat, S.intersect(S.offset(skull, 0.003 * s), S.carve(S.box(at(0, -0.01, 0.05), V(0.1, 0.12, 0.095) * s, 0.0, R),
                                                                       face_hole, 0.01)), order=1)
        elif hair == 'thin':
            # gone on top: what's left a fringe round the back and over the ears, thinning up to where
            # the bald crown begins, and short sideburns in front of the ears
            bald = S.ellipsoid(at(0, 0.02, 0.085), V(0.1, 0.13, 0.075) * s, R)
            add(hair_mat, cropped_short(0.005, S.union(face_hole, bald)), order=1)
        elif hair in ('long', 'bun', 'ponytail'):
            # (pulled back into a bun or a tail, it lies close to the head)
            hole = S.ellipsoid(at(0, 0.1, 0.005), V(0.07, 0.06, 0.068) * s, R)
            h = S.carve(S.intersect(shell(0.01 if hair == 'long' else 0.0055, hole),
                                    S.carve(S.box(at(0, -0.01, 0.04), V(0.1, 0.12, 0.105) * s, 0.0, R), hole, 0.01)), face_clear, 0.004)
            if hair != 'long':
                # combed back: shallow furrows running over the head
                h = S.ripple(h, 0.0009 * s, 2 * np.pi / (0.014 * s), R @ V(1, 0, 0))
            add(hair_mat, h, order=1)
            if hair == 'long':
                add(hair_mat, S.ellipsoid(at(0, -0.045, -0.1), V(0.085, 0.055, 0.14) * s, R), order=1)
            if hair == 'bun':
                add(hair_mat, S.sphere(at(0, -0.1, 0.07), 0.035 * s), order=1)
            if hair == 'ponytail':
                add(hair_mat, S.cone(at(0, -0.1, 0.02), at(0, -0.14, -0.16), 0.022 * s, 0.012 * s), order=1)
        elif hair == 'bob':
            # cut blunt at the jaw all round, a fringe over the brow
            bob = S.blend(0.03 * s, S.offset(skull, 0.009 * s),
                          S.ellipsoid(at(0, -0.02, -0.035), V(0.086, 0.094, 0.056) * s, R))
            bob = S.intersect(bob, S.halfspace(at(0, 0, -0.064), dirn(0, 0.12, -1)), 0.004)
            bob = S.carve(bob, S.ellipsoid(at(0, 0.1, -0.03), V(0.072, 0.085, 0.083) * s, R), 0.006)
            bob = S.carve(bob, S.offset(skull, 0.001), 0.0)
            # falling in locks from the crown: shallow grooves round the head, up and down
            up, fw = R[:, 2], R[:, 1]
            sd = np.cross(fw, up)
            bob = (lambda f: lambda P: f(P) + 0.0011 * s * np.sin(56.0 * np.arctan2((P - H) @ sd, (P - H) @ fw)))(bob)
            add(hair_mat, S.carve(bob, face_clear, 0.004), order=1)
            add(hair_mat, S.intersect(S.offset(skull, 0.012 * s), S.ellipsoid(at(0, 0.075, 0.052), V(0.064, 0.036, 0.028) * s, R)), order=1)
        elif hair == 'set':
            # short and set: brushed back off the face in soft waves that follow the hairline round,
            # lifted at the crown, close over the ears and tapering to the nape
            up = R[:, 2]
            vol = S.blend(0.03 * s, brain, S.ellipsoid(at(0, -0.01, 0.068), V(0.066, 0.08, 0.046) * s, R))
            h = lambda P: vol(P) - (0.006 + 0.006 * np.clip(((P - H) @ up / s + 0.01) / 0.08, 0.0, 1.0)) * s
            h = S.intersect(h, S.halfspace(at(0, 0.0, -0.03), dirn(0, 0.55, -1)), 0.012)
            h = S.carve(h, S.ellipsoid(at(0, 0.105, -0.005), V(0.075, 0.06, 0.068) * s, R), 0.012)
            for sx in (-1, 1):
                h = S.carve(h, S.ellipsoid(at(sx * 0.08, 0.002, -0.024), V(0.022, 0.028, 0.032) * s, R), 0.008)
            # the waves: rings round a point before the face
            wc = at(0, 0.15, 0.0)
            h = (lambda f: lambda P: f(P) + 0.0013 * s * np.sin(np.linalg.norm(P - wc, axis=1) * (2 * np.pi / (0.024 * s))))(h)
            add(hair_mat, h, order=1)
        elif hair == 'cropped':
            # clipped short, close to the head (over the forehead's full corners too): shortest at
            # the sides and back, a little longer on top, the sideburns ending halfway down the ear
            up = R[:, 2]
            crop = lambda P: brain(P) - (0.0035 + 0.0045 * np.clip(((P - H) @ up / s - 0.02) / 0.07, 0.0, 1.0)) * s
            h = S.intersect(crop, S.carve(S.box(at(0, -0.01, 0.05), V(0.1, 0.12, 0.09) * s, 0.0, R), face_hole, 0.01))
            h = S.carve(h, S.box(at(0, 0.08, -0.058), V(0.1, 0.08, 0.05) * s, 0.0, R), 0.004)
            add(hair_mat, S.intersect(h, S.halfspace(at(0, 0.0, -0.032), dirn(0, 0.45, -1)), 0.004), order=1)
        elif hair == 'long_wet':
            add(hair_mat, long_wet_hair(p, s, skull, at, dirn), order=1)
    elif hat == 'cap':
        crown = S.intersect(S.offset(skull, 0.012 * s), over(0.021, 0.36), 0.002)
        add('cap', crown, order=1)
        add('cap', S.box(at(0, 0.1, 0.05), V(0.058, 0.05, 0.0035) * s, 0.003, R @ S.rot(0, -0.12, 0)), order=2)
    elif hat == 'flatcap':
        cap = S.blend(0.02 * s, S.intersect(S.offset(skull, 0.01 * s), over(0.03, 0.3), 0.003),
                      S.ellipsoid(at(0, 0.006, 0.068), V(0.086, 0.1, 0.034) * s, R @ S.rot(0, -0.12, 0)))
        add('cap', cap, order=1)
        add('cap', S.box(at(0, 0.092, 0.046), V(0.06, 0.03, 0.004) * s, 0.003, R @ S.rot(0, -0.25, 0)), order=2)
    elif hat == 'beanie':
        add('cap', S.intersect(S.offset(skull, 0.012 * s), over(0.018, 0.25), 0.002), order=1)
        add('cap', S.intersect(S.offset(skull, 0.018 * s), S.intersect(over(0.018, 0.25), lambda P: -over(0.036, 0.25)(P))), order=2)
    elif hat == 'hood':
        # the hood up: cloth a couple of centimetres off the skull, a soft ridge where its two
        # halves are sewn over the crown, hanging beside the jaw and gathered on the shoulders.
        # The opening is cut through the front of it: an egg-shaped hole, square to a plane that
        # leans back from the brow to the throat, so the edge rides over the brow like a peak,
        # runs down past the cheekbones, then closes in under the jaw to a V at the throat
        outer = S.blend(0.045 * s,
            S.offset(skull, 0.024 * s),
            S.ellipsoid(at(0, -0.03, -0.095), V(0.094, 0.098, 0.1) * s, R),
            S.ellipsoid(at(0, -0.06, -0.185), V(0.118, 0.09, 0.06) * s, R))
        outer = S.blend(0.015 * s, outer, S.capsule(at(0, 0.075, 0.105), at(0, -0.12, 0.085), 0.006 * s))
        inner = S.offset(outer, -0.011 * s)
        n = R @ norm(V(0, 1.0, -0.4))
        up = R @ norm(V(0, 0.4, 1.0))
        side = R @ V(1, 0, 0)
        P0 = at(0, 0.058, 0.03)
        C = at(0, 0.054, -0.01)
        ax, az_top, az_low = 0.082 * s, 0.3 * s, 0.19 * s
        def cut(P):
            front = -((P - P0) @ n)
            q = P - C
            a, b = q @ side, q @ up
            az = np.where(b > 0, az_top, az_low)
            k0 = np.sqrt((a / ax) ** 2 + (b / az) ** 2)
            k1 = np.sqrt((a / ax ** 2) ** 2 + (b / az ** 2) ** 2)
            egg = k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)
            return np.maximum(front, egg)
        mid = S.offset(outer, -0.0055 * s)
        hoodf = S.carve(S.carve(outer, inner), cut, 0.003)
        # the hem, rolled: a tube along the edge
        rim = lambda P: np.sqrt(cut(P) ** 2 + mid(P) ** 2) - 0.0085 * s
        hoodf = S.blend(0.006, hoodf, rim)
        add('hoodie', hoodf, order=2)
        # his fringe, swept across his forehead under the peak: lying on it, its edge slanting down from
        # his left to his right temple, thinning to the edge, untidy
        edge = S.halfspace(at(0, 0.0, 0.037), dirn(-0.2, 0, -1))
        fringe = lambda P: brain(P) - s * (0.0025 + 0.0045 * np.clip(-edge(P) / (0.014 * s), 0.0, 1.0))
        fringe = S.intersect(fringe, S.intersect(edge, S.box(at(0, 0.075, 0.06), V(0.058, 0.045, 0.045) * s, 0.0, R)), 0.003)
        add(hair_mat, S.ripple(fringe, 0.0008 * s, 2 * np.pi / (0.009 * s), R @ norm(V(1, 0, 0.35))), order=1)
    if hat is None and hair == 'bald':
        pass
    return parts


def _lock(sup, pts, w, t):
    """A lock of wet hair lying on sup through pts (each let onto sup's surface): a flat ribbon w[j]
    wide and t thick at each, its width along the surface."""
    lay, nrm = [], []
    for c in pts:
        c = V(*c)
        for _ in range(6):
            g = _grad(sup, c[None, :])[0]
            g = g / max(float(np.linalg.norm(g)), 1e-9)
            c = c - g * (float(sup(c[None, :])[0]) - t * 0.7)
        lay.append(c)
        nrm.append(g)
    segs = []
    for j in range(len(lay) - 1):
        d = norm(lay[j + 1] - lay[j])
        side = np.cross(d, nrm[j] + nrm[j + 1])
        segs.append(S.econe(lay[j], lay[j + 1], (w[j], t), (w[j + 1], t * (0.75 if j == len(lay) - 2 else 1.0)), side))
    return S.blend(0.008, *segs)


def long_wet_hair(p, s, skull, at, dirn):
    """Long hair, loose and wet from the rain: pushed back off the face and lying flat to the head
    in the lines the fingers left, tucked behind the ears, then down over the collar to past the shoulders
    (on p.outer, what he's wearing, if body_parts left it) in the clumps wet hair falls into, its
    ends uneven. Locks of it hang down behind each ear, and two have come forward over his left
    shoulder onto his chest."""
    Rt = p.R
    R = p.Rh
    nk = lambda x, y, z: p.neck + Rt @ V(x, y, z)
    # the hairline: across the top of the brow and down in front of each ear to a short sideburn
    hole = S.blend(0.02 * s, S.ellipsoid(at(0, 0.1, -0.008), V(0.068, 0.06, 0.062) * s, R),
                   *[S.ellipsoid(at(sx * 0.06, 0.05, -0.065), V(0.03, 0.06, 0.042) * s, R) for sx in (-1, 1)])
    scalp = S.intersect(S.offset(skull, 0.0065 * s), S.carve(S.box(at(0, -0.01, 0.05), V(0.1, 0.12, 0.11) * s, 0.0, R), hole, 0.01))
    for sx in (-1, 1):
        # tucked behind the ears, close round them
        ear = S.ellipsoid(at(sx * 0.077, -0.004, -0.008), V(0.016, 0.024, 0.033) * s, R @ S.rot(-sx * 0.25, 0, 0))
        scalp = S.carve(scalp, ear, 0.004)
    # combed back by his fingers: shallow furrows running back over the head, smoothing out at the
    # hairline
    ax, sc = R @ V(1, 0, 0), scalp
    scalp = lambda P: sc(P) + 0.0011 * np.sin((P @ ax) * (2 * np.pi / 0.013)) * np.clip(hole(P) / 0.015, 0.0, 1.0)
    # what it hangs over: the back of the head, bridged to the back of the neck, and the collar and
    # shoulders under it
    sup = S.blend(0.04, S.offset(skull, 0.005 * s), S.capsule(at(0, -0.05, -0.05), nk(0, -0.05, -0.04), 0.047 * s))
    outer = getattr(p, 'outer', None)
    if outer is not None:
        sup = S.blend(0.03, sup, outer)
    def region(q):
        # behind the ears, as wide as the head and then the shoulders it falls over, its ends uneven
        x, y, z = q[:, 0], q[:, 1], q[:, 2]
        wide = 0.085 + 0.05 * np.clip(-z / 0.1, 0.0, 1.0)
        ends = -0.19 - 0.025 * np.sin(x * 47.0) - 0.014 * np.sin(x * 113.0 + 1.0)
        # and over the tops of the shoulders, beside the neck, where it shows from the front
        fore = -0.012 + 0.03 * np.clip(z / 0.15, 0.0, 1.0) + 0.04 * np.clip((np.abs(x) - 0.07) / 0.03, 0.0, 1.0) * (z > -0.06)
        return np.maximum.reduce([np.abs(x) - wide, ends - z, y - fore])
    fall = S.intersect(S.offset(sup, 0.012), _loc(region, p.neck, Rt), 0.008)
    behind = S.halfspace(at(0, 0.004, 0), dirn(0, 1, 0))
    fall = S.intersect(fall, behind, 0.01)
    # wet, it goes into clumps: grooves down it
    fall = S.ripple(fall, 0.0022, 2 * np.pi / 0.021, Rt @ V(1, 0.0, 0.0))
    locks = []
    for sx in (-1, 1):
        # down behind the ear and the jaw onto the collar, and over the back of the shoulder
        locks.append(_lock(sup, [at(sx * 0.068, -0.045, 0.0), nk(sx * 0.085, -0.045, 0.1), nk(sx * 0.11, -0.04, 0.02),
                                 nk(sx * 0.13, -0.065, -0.07), nk(sx * 0.13, -0.08, -0.15 - 0.02 * sx)],
                           [0.02, 0.019, 0.019, 0.016, 0.009], 0.0055))
    # come forward over his left shoulder onto his chest, side by side, and over his right a shorter one
    for dx, dz, w in ((0.0, 0.0, 0.016), (0.026, 0.03, 0.013), (-0.024, -0.01, 0.012)):
        locks.append(_lock(sup, [at(-0.07, -0.025 - dx * 0.4, -0.01), nk(-0.09 - dx * 0.5, -0.012, 0.085), nk(-0.112 - dx, 0.035, 0.005),
                                 nk(-0.118 - dx, 0.09, -0.07 + dz), nk(-0.112 - dx, 0.11, -0.16 + dz * 1.5)],
                           [w, w, w * 0.95, w * 0.75, w * 0.35], 0.005))
    locks.append(_lock(sup, [at(0.07, -0.03, -0.01), nk(0.092, -0.014, 0.085), nk(0.118, 0.03, 0.01), nk(0.124, 0.075, -0.05)],
                       [0.015, 0.015, 0.013, 0.006], 0.005))
    return S.blend(0.01, scalp, fall, *locks)


# ---------------------------------------------------------------------------------------- things they hold

def held_parts(B, p, look):
    """Things they hold that are part of their shape (the cue). The rest (a phone, a card, a glass,
    keys) are clean meshes of their own, made in export_people.py from p.props."""
    parts = []
    if hasattr(p, 'cue'):
        a, b2 = p.cue
        parts.append(Part('cue', S.cone(a + V(0, 0, 0.01), b2, 0.015, 0.0065), order=4))
    return parts


# ---------------------------------------------------------------------------------------- his own hands

DOORMAN = dict(build='big', bulk=1.05)
CLICKER = dict(r=0.025, t=0.022)       # a tally counter: a chrome disc 50 mm across, 22 thick


def clicker_sdf(c, R):
    """The counter's body (its face, the window side, toward R's z; its button toward R's y)."""
    return S.cylinder(c - R[:, 2] * CLICKER['t'] / 2, c + R[:, 2] * CLICKER['t'] / 2, CLICKER['r'], 0.004)


def fp_hand(kind):
    """The doorman's own hands for the first-person view: his wrist at the origin, his forearm going
    back toward the camera (-y) in the sleeve of his work jacket, the hand forward (+y). kind:
    'left_clicker' (the tally counter in his fist, its face to him, his thumb on its button),
    'right_card' (a licence held up, its face to him), 'right_phone', 'right_open' (open, palm
    down), 'right_pint' (round a pint glass, held up), 'right_palm' (open, palm up, for a thing to
    lie in). Returns the Hand, its parts and the things it holds."""
    B = Build(DOORMAN)
    fore = norm(V(0.0, -1.0, -0.35))
    props = []
    eye = norm(V(0.1, -0.8, 0.6))                 # from the hand back up to his eye
    if kind == 'left_clicker':
        h = Hand(B, V(0, 0, 0), V(0.05, 1.0, 0.25), V(1.0, 0.0, 0.25), right=False, grip='open')
        Rc = S.frame(np.cross(h.dirw((1, 0, 0)), eye), h.dirw((1, 0, 0)))       # x across, y up the thumb, z its face to him
        c = h.w((0.025, 0.066, 0.042))
        # the thumb bent over its top; the button turned to where the thumb's pad comes down
        h.th = [1.2, 0.2, 0.4, 1.0, 0.9]
        tip = h.w(h.thumb()[0][3])
        ax = Rc[:, 2]
        yb = norm((tip - c) - ax * float(np.dot(tip - c, ax)))
        Rc = S.frame(np.cross(yb, ax), yb)
        body = clicker_sdf(c, Rc)
        h.close(body, thumb=False, gap=0.0005)
        props.append(dict(kind='clicker', at=c, R=Rc))
    elif kind == 'right_card':
        face = norm(V(-0.1, -0.75, 0.65))
        h = hold_card(B, V(0, 0, 0), face, right=True)
        props.append(h.prop)
    elif kind == 'right_phone':
        face = norm(V(-0.1, -0.75, 0.65))
        h = hold_phone(B, V(0, 0, 0), face, right=True)
        props.append(h.prop)
    elif kind == 'right_pint':
        # a pint held up to look at: his hand round it from the right, the thumb up its near side
        h = hold_glass(B, V(0, 0, 0), V(1.0, -0.15, 0.0), right=True, kind='pint', height=0.058, thumb=(0.8, 0.22, 0.6, 0.1, 0.1))
        props.append(h.prop)
    elif kind == 'right_palm':
        # open, palm up and cupped a little, for what he's been handed to lie in it: the prop is
        # where it lies, x across the palm, y up the fingers, z out of it
        h = Hand(B, V(0, 0, 0), V(0.0, 1.0, 0.12), V(0.0, -0.12, 1.0), right=True, grip='relaxed')
        props.append(dict(kind='palm', at=h.w((-0.003, 0.056, 0.0175)), R=S.frame(h.dirw((1, 0, 0)), h.dirw((0, 1, 0)))))
    else:
        h = Hand(B, V(0, 0, 0), V(0.0, 1.0, -0.1), V(0.0, 0.1, -1.0), right=True, grip='relaxed')
    # the wrist to the origin, and what it holds with it
    d = -h.o
    h.o = V(0, 0, 0)
    props = [dict(pr, at=pr['at'] + d) for pr in props]
    h.fore = fore
    k = h.k
    b = B.bulk
    sl0 = fore * 0.045
    parts = [Part('skin', h.sdf(), order=1),
             Part('skin', S.econe(fore * 0.004, fore * 0.06, (0.0262 * k, 0.0172 * k), (0.03 * b, 0.026 * b), h.M[:, 0])),
             Part('doorman_jacket', rings(S.cone(sl0, fore * 0.34, 0.043 * b, 0.05 * b), sl0, fore, 0.002, 0.03, 0.05, 0.3)),
             Part('doorman_jacket', S.carve(S.cone(sl0 + fore * 0.006, fore * 0.03, 0.045 * b, 0.041 * b),
                                            S.capsule(fore * 0.022, -fore * 0.02, 0.035 * b), 0.002), order=2)]
    return B, h, parts, props


# ---------------------------------------------------------------------------------------- Gary's hands

# Gary Van Dusen, late fifties, the boss: his right hand in his own view across the desk, as the
# doorman's are in his. Soft hands that used to work, paler and hairier than the doorman's, a few
# age spots, a gold signet ring on the little finger, and the cuff of a blue oxford shirt turned
# back once.
GARY = dict(build='medium')


class GaryHand(Hand):
    """Gary's hand: softer and a little fuller all over than the Hand it's made as (`soft`), his
    thumb longer and fuller still (`tl`, `tr`), the pad of it spread flat on what it presses
    (`pad` times as wide as the bone)."""
    tl, tr, pad, soft = 1.06, 1.08, 1.14, 0.0006

    def thumb(self, th=None):
        pts, d0, pad = Hand.thumb(self, th)
        q = [pts[0]]
        for j in range(3):
            q.append(q[-1] + (pts[j + 1] - pts[j]) * self.tl)
        return q, d0, pad

    def sdf(self, nails=False):
        f0 = Hand.sdf(self, nails)
        k = self.k
        (t0, t1, t2, t3), d0, pad = self.thumb()
        ax = norm(np.cross(d0, pad))
        T = [self.w(q) for q in (t1, t2, t3)]
        r = [x * k * self.tr for x in THUMB[2][1:]]
        full = S.blend(0.003 * k, S.cone(T[0], T[1], r[0], r[1]), S.cone(T[1], T[2], r[1], r[2]))
        # the pad of its last bone pressed flat: wider across, no deeper toward what it presses
        e = self.dirw(norm(t3 - t2))
        pd = self.dirw(turn(pad, ax, self.th[3] + self.th[4]))
        c = self.w(t2 + (t3 - t2) * 0.5) + pd * r[2] * 0.3
        full = S.blend(0.004 * k, full, S.ellipsoid(c, V(r[2] * self.pad, 0.0125 * k, r[2] * 0.72), S.frame(np.cross(e, pd), e)))
        soft = self.soft
        return lambda P: S._smin(f0(P), full(P), 0.004 * k) - soft


def _angle_about(a, b, axis):
    """The angle turning a to b about axis (a and b square to it)."""
    return float(np.arctan2(np.dot(np.cross(a, b), axis), np.dot(a, b)))


def hold_card_edge(B, c, face, theta=1.5, back=0.2, tilt=-0.3, az=0.0, el=0.85, x1=0.06, y1=0.0027,
                   to=((0.3, 1.5, 0.8), (0.3, 1.5, 0.8), (1.45, 1.7, 0.9), (1.55, 1.75, 0.9))):
    """Gary's right hand holding a card (a licence) up by its right short edge, centred at c, its face
    toward `face`, level: his thumb flat across its face from that edge, over where the name is
    printed, its knuckle `x1` right of the card's middle and `y1` above it; his first two fingers
    bent round behind the card onto its back (curling toward `to` till they touch), the other two
    curled under. The hand is turned so its fingers run `theta` round from up toward the left,
    leaning `back` away from the card, and its palm `tilt` from facing him; the thumb's long bone
    comes up off the card toward him by `el` and runs `az` up from level. The rest follows from
    where that puts the root of the thumb."""
    face = norm(V(*face))
    up = norm(V(0, 0, 1) - face * face[2])
    Rc = S.frame(np.cross(up, face), up)          # x along the card, y up it, z out of its face
    u = V(-np.sin(theta), np.cos(theta), 0.0)
    h = GaryHand(B, V(0, 0, 0), Rc @ (u * np.cos(back) - V(0, 0, np.sin(back))), Rc @ turn(V(0, 0, 1), u, tilt), True,
                 grip='open', size=B.hands)
    k = h.k
    # where the thumb lies, in the card's frame: its pad on the face, straight across it to the left
    r = [x * k * h.tr for x in THUMB[2]]
    L = [x * k * h.tl for x in THUMB[1]]
    p1 = V(x1, y1, CARD[2] / 2 + r[1] + 0.0008)
    p2 = p1 + norm(V(-1.0, 0.0, (r[2] - r[1]) / L[1])) * L[1]
    p3 = p2 + norm(V(-1.0, 0.0, (r[3] - r[2]) / L[2])) * L[2]
    d0 = V(-np.cos(el) * np.cos(az), np.cos(el) * np.sin(az), np.sin(el))
    p0 = p1 - d0 * L[0]
    h.o = (V(*c) + Rc @ p0 - h.M @ (V(*THUMB[0]) * k)).astype(np.float32)
    # the thumb's angles that put it there
    dh = h.M.T @ (Rc @ d0)
    e1, e2 = norm(p2 - p1), norm(p3 - p2)
    padc = norm(e1 - d0 * float(np.dot(e1, d0)))
    pad0 = norm(V(-1, 0, 0) - dh * float(np.dot(V(-1, 0, 0), dh)))
    h.th = [float(np.arctan2(dh[0], dh[1])), float(np.arcsin(np.clip(dh[2], -1.0, 1.0))),
            _angle_about(pad0, h.M.T @ (Rc @ padc), dh), float(np.arccos(np.clip(np.dot(d0, e1), -1.0, 1.0))),
            _angle_about(e1, e2, norm(np.cross(d0, padc)))]
    # the fingers: the first two bent onto the back of the card, the others curled under
    card = card_sdf(V(*c), Rc)
    h.close(card, thumb=False, gap=0.0003, to=([tuple(x) for x in to], GRIPS['fist'][1]))
    h.prop = dict(kind='card', at=V(*c), R=Rc)
    return h


def _scatter(shapes, far=0.01):
    """The union of many small shapes, each a (lo, hi, f) asked only about the points in its box
    (and `far` everywhere else), so a few hundred cost little more than one."""
    def f(P):
        out = np.full(len(P), far, dtype=np.float32)
        for lo, hi, g in shapes:
            m = np.all((P >= lo) & (P <= hi), axis=1)
            if m.any():
                out[m] = np.minimum(out[m], g(P[m]))
        return out
    return f


def _skin_at(skin, o, d):
    """From o (inside the skin) out along d: the point on it there, and which way it faces."""
    s = o + _surf(skin, o, d, far=0.06)
    n = _grad(skin, s[None, :])[0]
    return s, norm(n)


def gary_hairs(h, skin, fore, side, seed=7):
    """The hair on the back of Gary's hand, of his thumb and of the first bones of his fingers, and
    round his forearm out to the cuff (thicker on its back): short hairs lying along the skin the
    way they grow, down the arm and out across the hand toward the little finger. Returns the
    shape of them all."""
    rng = np.random.default_rng(seed)
    back = h.dirw((0.0, 0.0, -1.0))
    spots = []                        # (where it starts inside, the way out, the way the hair runs)
    for _ in range(70):
        x, y = rng.uniform(-0.03, 0.022), rng.uniform(0.014, 0.076)
        spots.append((h.w((x, y, 0.004)), back, h.dirw((-0.35, 1.0, 0.0))))
    for i in range(4):
        pts = h.finger(i)
        base, splay, _, _ = FINGERS[i]
        u0 = V(np.sin(splay), np.cos(splay), 0.0)
        ax = norm(np.cross(u0, V(0, 0, 1)))
        e = turn(u0, ax, h.curls[i][0])
        for _ in range(4):
            t = rng.uniform(0.12, 0.55)
            spots.append((h.w(pts[0] + (pts[1] - pts[0]) * t), h.dirw(-turn(e, ax, np.pi / 2)), h.dirw(e)))
    (t0, t1, t2, t3), d0, pad = h.thumb()
    tax = norm(np.cross(d0, pad))
    for _ in range(10):
        t = rng.uniform(0.35, 1.45)
        o = t0 + (t1 - t0) * min(t, 1.0) + (t2 - t1) * max(t - 1.0, 0.0)
        spots.append((h.w(o), h.dirw(-turn(pad, tax, h.th[3] if t > 1.0 else 0.0)), h.dirw(d0)))
    across = norm(np.cross(fore, side))
    dors = norm(back - fore * float(np.dot(back, fore)))
    for _ in range(230):
        s, a = rng.uniform(0.008, 0.058), rng.uniform(0.0, 2.0 * np.pi)
        out = side * np.cos(a) + across * np.sin(a)
        if rng.uniform() > 0.3 + 0.7 * max(0.0, float(np.dot(out, dors))):
            continue
        spots.append((fore * s, out, -fore + side * 0.25))
    shapes = []
    for o, d, g in spots:
        if float(skin(o[None, :])[0]) >= 0.0:
            continue
        s, n = _skin_at(skin, o, d)
        g = norm(g - n * float(np.dot(g, n)))
        g = turn(g, n, rng.uniform(-0.35, 0.35))
        L = rng.uniform(0.0036, 0.0055)
        c = s + n * 0.00015
        R = S.frame(np.cross(g, n), g)
        ext = L / 2 + 0.008
        shapes.append((c - ext, c + ext, S.ellipsoid(c, V(0.0005, L / 2, 0.0005), R)))
    return _scatter(shapes)


def gary_spots(h, skin, fore, side, rise=0.0003):
    """A few age spots: flat brown marks on the back of his hand, the back of his thumb and the
    side of his wrist, each a skin's breadth proud of it."""
    back = h.dirw((0.0, 0.0, -1.0))
    across = norm(np.cross(fore, side))
    marks = [(h.w((-0.013, 0.046, 0.004)), back, 0.0034), (h.w((0.009, 0.062, 0.004)), back, 0.0024),
             (h.w((-0.022, 0.028, 0.004)), back, 0.0028), (fore * 0.024, norm(side * 0.8 - across * 0.6), 0.003),
             (fore * 0.046, norm(side * 0.5 - across * 0.85), 0.0022)]
    (t0, t1, t2, t3), d0, pad = h.thumb()
    marks.append((h.w(t0 + (t1 - t0) * 0.7), h.dirw(-pad), 0.0022))
    shapes = []
    for o, d, r in marks:
        if float(skin(o[None, :])[0]) >= 0.0:
            continue
        s, _ = _skin_at(skin, o, d)
        g = (lambda s, r: lambda P: np.maximum(np.linalg.norm(P - s, axis=1) - r, skin(P) - rise))(s, r)
        shapes.append((s - r - 0.008, s + r + 0.008, g))
    return _scatter(shapes)


def gary_ring(h):
    """His gold signet ring, on the first bone of the little finger: a band round it and a flat oval
    face on its back."""
    pts = h.finger(3)
    base, splay, _, rr = FINGERS[3]
    u0 = V(np.sin(splay), np.cos(splay), 0.0)
    ax = norm(np.cross(u0, V(0, 0, 1)))
    e = turn(u0, ax, h.curls[3][0])
    c = h.w(pts[0] + (pts[1] - pts[0]) * 0.45)
    ew = h.dirw(e)
    dors = h.dirw(-turn(e, ax, np.pi / 2))
    rf = (rr[0] * 0.55 + rr[1] * 0.45) * h.k + getattr(h, 'soft', 0.0)
    band = S.torus(c, rf + 0.0011, 0.0011, S.frame(dors, np.cross(ew, dors)))
    top = S.ellipsoid(c + dors * (rf + 0.0016), V(0.0047, 0.0043, 0.0017), S.frame(np.cross(ew, dors), ew))
    return S.intersect(S.blend(0.0012, band, top), S.halfspace(c + dors * (rf + 0.0027), dors))


def _band(axis, t0, t1, rin, rout, rr):
    """A band round the line through the origin along `axis`, from t0 to t1 along it and rin to
    rout out from it, its edges rounded over by rr."""
    tc, ht, rc, hr = (t0 + t1) / 2, (t1 - t0) / 2, (rin + rout) / 2, (rout - rin) / 2

    def f(P):
        t = P @ axis
        q = np.stack([np.abs(np.linalg.norm(P - np.outer(t, axis), axis=1) - rc) - hr + rr, np.abs(t - tc) - ht + rr], axis=1)
        return (np.linalg.norm(np.maximum(q, 0.0), axis=1) + np.minimum(q.max(axis=1), 0.0) - rr).astype(np.float32)
    return f


def gary_hand(kind):
    """Gary's right hand for his own view, as fp_hand is the doorman's (his wrist at the origin, his
    forearm going back toward his eye): 'right_card', a licence held up by its right short edge
    (hold_card_edge), or 'right_phone', his phone with its screen to him (hold_phone). Out of the
    cuff of his shirt, turned back once, his forearm bare to it. Returns the Build, the Hand, its
    parts and the things it holds."""
    B = Build(GARY)
    face = norm(V(-0.1, -0.75, 0.65))
    if kind == 'right_card':
        h = hold_card_edge(B, V(0, 0, 0), face)
        # the forearm from the wrist out to his right, down and back toward him
        up = norm(V(0, 0, 1) - face * face[2])
        fore = norm(S.frame(np.cross(up, face), up) @ V(0.8, -0.45, 0.4))
    else:
        # the doorman's grip, closed round the phone as a plain hand, then made his: soft and full,
        # but his thumb no longer than the grip closed it
        h = hold_phone(B, V(0, 0, 0), face, right=True)
        h.__class__ = GaryHand
        h.tl = 1.0
        fore = norm(V(0.0, -1.0, -0.35))
    d = -h.o
    h.o = V(0, 0, 0)
    props = [dict(h.prop, at=h.prop['at'] + d)]
    h.fore = fore
    k = h.k
    side = h.M[:, 0]
    hand = h.sdf()
    arm = S.econe(fore * 0.004, fore * 0.12, (0.0268 * k, 0.0178 * k), (0.032, 0.028), side)
    skin = lambda P: np.minimum(hand(P), arm(P))
    # the cuff turned back once: a doubled band standing off the forearm, its edges rounded over,
    # then the sleeve on up
    cuff = _band(fore, 0.062, 0.118, 0.0352, 0.0418, 0.0024)
    sleeve = rings(S.cone(fore * 0.112, fore * 0.34, 0.0385, 0.046), fore * 0.112, fore, 0.0014, 0.034, 0.04, 0.22)
    parts = [Part('skin_pale', hand, order=1), Part('skin_pale', arm),
             Part('oxford', cuff, order=2), Part('oxford', sleeve, order=1),
             Part('gold', gary_ring(h), order=3),
             Part('age_spot', gary_spots(h, skin, fore, side), order=2),
             Part('hand_hair', gary_hairs(h, skin, fore, side), order=3)]
    return B, h, parts, props


# ---------------------------------------------------------------------------------------- a person

POSES = {
    'stand': pose_stand, 'walk_pouch': pose_walk_pouch, 'pouch': pose_pouch, 'phone_out': pose_phone_out,
    'sit': pose_sit, 'cue': pose_cue, 'bar': pose_bar, 'reach': pose_reach, 'counter': pose_counter,
    'card': pose_card, 'close': pose_close, 'pint': pose_pint, 'door': pose_door, 'bar_lean': pose_bar_lean,
    'carry': pose_carry, 'sit_drink': pose_sit_drink, 'chin': pose_chin,
    'armchair': pose_armchair, 'ledger': pose_ledger, 'perch': pose_perch, 'rail': pose_rail,
}


def person(look, pose='stand', **pose_kw):
    B = Build(look)
    p = POSES[pose](B, **pose_kw)
    set_hands(B, p)
    parts = body_parts(B, p, look) + head_parts(B, p, look) + held_parts(B, p, look)
    return B, p, parts


def _hand_box(h, pad=0.035):
    """The box a hand (and the cuff round its wrist) fills."""
    pts = [h.o, h.w((0, -0.07, 0))] + [h.w(q) for i in range(4) for q in h.finger(i)] + [h.w(q) for q in h.thumb()[0]]
    pts = np.array(pts)
    return pts.min(axis=0) - pad, pts.max(axis=0) + pad


def mesh_person(look, pose='stand', step=0.012, head_step=None, hand_step=None, **pose_kw):
    """Mesh a person, as a list of (part, verts, faces, material per face, material names). With
    `head_step`, the head is a mesh of its own at that finer step, since a face needs it; the two
    overlap at the neck, inside the collar or the hood. With `hand_step`, so are the hands (and the
    cuffs round them), each in a box of its own."""
    B = Build(look)
    p = POSES[pose](B, **pose_kw)
    set_hands(B, p)
    allp = body_parts(B, p, look) + held_parts(B, p, look)
    head = head_parts(B, p, look)
    body = [q for q in allp if not (q.group or '').startswith('hand')]
    hand_parts = [[q for q in allp if q.group == 'hand_l'], [q for q in allp if q.group == 'hand_r']]
    if hand_step is None:
        body = allp
    pts = [p.head, p.pelvis, *p.sh, *p.elbow, *p.wrist, *p.knee, *p.ankle, *p.hip]
    if hasattr(p, 'cue'):
        pts += list(p.cue)
    pts = np.array(pts)
    lo = pts.min(axis=0) - 0.2
    hi = pts.max(axis=0) + 0.2
    lo[2] = -0.005
    if head_step is None:
        return [("body", *S.mesh_islands(body + head, lo, hi, step))]
    out = [("body", *S.mesh_islands(body, lo, hi, step))]
    # (long hair hangs below the head's box: `head_drop` takes it down to the ends)
    hlo, hhi = p.head + V(-0.2, -0.2, -look.get('head_drop', 0.3)), p.head + V(0.2, 0.2, 0.2)
    clip = S.box((hlo + hhi) / 2, (hhi - hlo) / 2 - head_step * 1.5)
    head = [Part(q.name, S.intersect(q.f, clip), order=q.order) for q in head]
    out.append(("head", *S.mesh_islands(head, hlo, hhi, head_step)))
    if hand_step is not None:
        V_all, F_all, M_all, names, base = [], [], [], [], 0
        for i in range(2):
            if not hand_parts[i] or p.hands[i] is None:
                continue
            blo, bhi = _hand_box(p.hands[i])
            clip = S.box((blo + bhi) / 2, (bhi - blo) / 2 - hand_step * 1.5)
            hp = [Part(q.name, S.intersect(q.f, clip), order=q.order) for q in hand_parts[i]]
            v, f, m, nm = S.mesh_islands(hp, blo, bhi, hand_step)
            for n in nm:
                if n not in names:
                    names.append(n)
            V_all.append(v)
            F_all.append(f + base)
            M_all.append(np.array([names.index(nm[k]) for k in m], dtype=np.int32))
            base += len(v)
        if V_all:
            out.append(("hands", np.concatenate(V_all), np.concatenate(F_all), np.concatenate(M_all), names))
    return out
