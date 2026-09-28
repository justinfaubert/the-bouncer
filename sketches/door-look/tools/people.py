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
        self.shoulder = 0.185 * (0.9 if self.f else 1.0) * (1.12 if b == 'big' else 1.0)
        if 'size' in look:
            self.size *= look['size']
        if 'bulk' in look:
            self.bulk *= look['bulk']
        s = self.size
        self.upper_arm, self.forearm = 0.30 * s, 0.265 * s
        self.thigh, self.shin = 0.445 * s, 0.415 * s


# ---------------------------------------------------------------------------------------- poses

class Pose:
    """Joint positions. Built by a pose function from a Build."""
    pass


def _base(B, pelvis, lean=0.0, twist=0.0, head_turn=0.0, head_tilt=0.0, head_roll=0.0, slump=0.0):
    """The trunk: pelvis at `pelvis`, the chest leaning forward by `lean` radians, turned by
    `twist` about the spine; the head turned (yaw), tilted (down is positive) and rolled."""
    s = B.size
    p = Pose()
    p.pelvis = V(*pelvis)
    R = S.rot(twist, lean, 0.0)
    up = R @ V(0, 0, 1)
    p.waist = p.pelvis + R @ V(0, 0.005, 0.13 * s) - V(0, slump * 0.3, 0)
    p.chest = p.pelvis + R @ V(0, 0.0, 0.33 * s) - V(0, slump, slump * 0.4)
    p.neck = p.pelvis + R @ V(0, -0.02, 0.50 * s) - V(0, slump * 0.8, slump * 0.8)
    p.R = R
    Rh = S.rot(twist + head_turn, lean * 0.4 - head_tilt, head_roll)
    p.Rh = Rh
    p.head = p.neck + Rh @ V(0, 0.03 * s, 0.185 * s)
    sh = B.shoulder * B.bulk ** 0.5
    p.sh = [p.neck + R @ V(-sh, -0.0, -0.035 * s), p.neck + R @ V(sh, -0.0, -0.035 * s)]    # left, right
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


def pose_stand(B, arms='hang', weight=0.0, **kw):
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), **kw)
    _legs(B, p, [(-0.1 * s - weight * 0.03, -0.03, 0.075), (0.1 * s - weight * 0.03, -0.03, 0.075)],
          [(-0.1, 1, 0.5), (0.1, 1, 0.5)], [(-0.15, 1, 0), (0.15, 1, 0)])
    if arms == 'hang':
        _arms(B, p, [p.sh[0] + V(-0.06, 0.02, -0.55 * s), p.sh[1] + V(0.06, 0.02, -0.55 * s)],
              [p.sh[0] + V(-0.1, -0.5, -0.3), p.sh[1] + V(0.1, -0.5, -0.3)], [(1, 0, 0), (-1, 0, 0)])
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


def pose_phone_out(B, **kw):
    """In front of the stool, holding his phone up to the doorman at arm's length; the other hand
    in the pouch."""
    s = B.size
    p = _base(B, (0, 0.0, 0.965 * s), lean=0.03, **kw)
    _legs(B, p, [(-0.11 * s, 0.03, 0.075), (0.1 * s, -0.08, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.2, 1, 0), (0.25, 1, 0)])
    pouch = p.waist + p.R @ V(0, 0.16 * B.bulk, -0.03)
    # the phone out at chest height to his right, tipped up to the stool, clear of his face
    _arms(B, p, [pouch + V(-0.06, -0.01, 0), p.sh[1] + V(0.0, 0.4 * s, -0.17)],
          [p.sh[0] + V(-0.6, -0.4, -0.3), p.sh[1] + V(0.5, -0.1, -0.8)], [(1, 0.3, 0), (-0.2, 0.9, 0.4)])
    p.hands_in = [True, False]
    p.phone = 1
    return p


def pose_sit(B, seat=0.64, table=0.78, lean=0.25, hands=None, feet='ring', floor=0.0, reach=0.32,
             palms=None, phone=None, **kw):
    """On a stool, facing a table (or the bar) in front: forearms on it unless hands are given.
    Or in a seat with a floor of its own (a truck's), feet out in front on it. `phone`: which hand
    holds one, its screen the way that palm faces."""
    s = B.size
    p = _base(B, (0, -0.02, seat + 0.1 * s), lean=lean, **kw)
    if feet == 'ring':
        ank = [(-0.12, 0.12, 0.3 if seat > 0.7 else 0.18), (0.12, 0.1, 0.3 if seat > 0.7 else 0.18)]
    else:
        ank = [(-0.13, reach, floor + 0.075), (0.14, reach - 0.07, floor + 0.075)]
    _legs(B, p, ank, [(-0.15, 1, 0.8), (0.15, 1, 0.8)], [(-0.1, 1, -0.3), (0.1, 1, -0.3)])
    if hands is None:
        hands = [(-0.14, 0.42, table + 0.05), (0.12, 0.44, table + 0.05)]
    _arms(B, p, hands, [p.sh[0] + V(-0.5, -0.1, -0.4), p.sh[1] + V(0.5, -0.1, -0.4)], palms or [(0.3, 0, -1), (-0.3, 0, -1)])
    if phone is not None:
        p.phone = phone
    return p


def pose_cue(B, left_handed=True, **kw):
    """Standing by the table between shots, the cue upright in one hand, its butt on the floor."""
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), **kw)
    _legs(B, p, [(-0.13 * s, 0.0, 0.075), (0.11 * s, -0.05, 0.075)],
          [(-0.3, 1, 0.5), (0.2, 1, 0.5)], [(-0.3, 1, 0), (0.2, 1, 0)])
    i = 0 if left_handed else 1
    side = -1 if left_handed else 1
    hands = [None, None]
    hands[i] = p.sh[i] + V(side * 0.12, 0.2, -0.28 * s)
    hands[1 - i] = p.sh[1 - i] + V(-side * 0.05, 0.03, -0.56 * s)
    _arms(B, p, hands, [p.sh[0] + V(-0.5, -0.4, -0.2), p.sh[1] + V(0.5, -0.4, -0.2)], [(1, 0, 0), (-1, 0, 0)])
    p.cue = (V(hands[i][0], hands[i][1] + 0.02, 0.0), V(hands[i][0], hands[i][1] + 0.04, 1.47))
    return p


def pose_bar(B, top=1.08, **kw):
    """Behind the bar, both hands on it."""
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), lean=0.12, **kw)
    _legs(B, p, [(-0.12 * s, -0.02, 0.075), (0.12 * s, -0.05, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.2, 1, 0), (0.2, 1, 0)])
    _arms(B, p, [(-0.24, 0.42, top + 0.03), (0.22, 0.4, top + 0.03)],
          [p.sh[0] + V(-0.6, -0.2, -0.3), p.sh[1] + V(0.6, -0.2, -0.3)], [(0.2, 0, -1), (-0.2, 0, -1)])
    return p


def pose_reach(B, **kw):
    """Standing at the jukebox, one hand up on its screen."""
    s = B.size
    p = _base(B, (0, 0, 0.965 * s), **kw)
    _legs(B, p, [(-0.1 * s, 0.0, 0.075), (0.1 * s, -0.1, 0.075)],
          [(-0.2, 1, 0.5), (0.2, 1, 0.5)], [(-0.1, 1, 0), (0.2, 1, 0)])
    _arms(B, p, [p.sh[0] + V(-0.04, 0.03, -0.56 * s), (0.12, 0.5, 1.45 * s)],
          [p.sh[0] + V(-0.3, -0.5, -0.2), p.sh[1] + V(0.5, -0.3, -0.5)], [(1, 0, 0), (0, 1, 0)])
    return p


# ---------------------------------------------------------------------------------------- body

def body_parts(B, p, look):
    """The body in its clothes, as parts with materials."""
    top = look.get('top', 'tshirt')
    legs_mat = look.get('bottoms', 'jeans')
    s, b = B.size, B.bulk
    parts = []
    add = lambda name, f, order=0: parts.append(Part(name, f, order=order))

    loose = {'hoodie': 0.022, 'coat': 0.03, 'jacket': 0.022, 'hivis': 0.012, 'cardigan': 0.012, 'whites': 0.012,
             'suit': 0.012, 'tweed': 0.014, 'flannel': 0.01, 'apron': 0.006, 'tshirt': 0.004}.get(top, 0.01)
    shirt = {'hivis': 'sweatshirt', 'apron': 'shirt_dark', 'suit': 'suit'}.get(top, top)
    R = p.R
    # the trunk
    chest_r = V(0.165 * b + loose, 0.105 * b + loose + (0.012 if B.f else 0.0), 0.15 * s)
    belly = B.belly * b
    trunk = S.blend(0.07,
        S.ellipsoid(p.pelvis + R @ V(0, -0.005, 0.02), V(0.16 * b + loose, 0.108 * b + loose, 0.12 * s), R),
        S.ellipsoid(p.waist + R @ V(0, belly * 0.6, 0), V(0.148 * b + loose + belly * 0.4, 0.1 * b + loose + belly, 0.12 * s), R),
        S.ellipsoid(p.chest, chest_r, R),
        S.capsule(p.sh[0] + R @ V(0.02, -0.01, 0.0), p.sh[1] + R @ V(-0.02, -0.01, 0.0), 0.062 * b ** 0.7 + loose),
    )
    add(shirt, trunk)
    if B.f:
        for sx in (-1, 1):
            add(shirt, S.ellipsoid(p.chest + R @ V(sx * 0.075, 0.1 * b + loose - 0.01, -0.03), V(0.06, 0.045, 0.055), R))
    # the neck
    add('skin', S.cone(p.neck + R @ V(0, 0.0, -0.03), p.head + p.Rh @ V(0, -0.025, -0.07), 0.056 * b ** 0.5, 0.05))
    # arms: sleeves to the wrist, or to above the elbow for a t-shirt
    for i in range(2):
        sh, el, wr = p.sh[i], p.elbow[i], p.wrist[i]
        up_mat = shirt
        fore_mat = 'skin' if top in ('tshirt',) or look.get('sleeves') == 'rolled' else shirt
        if top == 'hivis':
            up_mat = fore_mat = 'sweatshirt'
        add(up_mat, S.blend(0.03, S.sphere(sh, 0.058 * b + loose), S.cone(sh, el, 0.052 * b + loose, 0.041 * b + loose)))
        if top == 'tshirt':
            mid = sh + (el - sh) * 0.45
            add('tshirt', S.cone(sh, mid, 0.06 * b + 0.008, 0.052 * b + 0.01), order=2)
        add(fore_mat, S.cone(el, wr, 0.041 * b + (loose if fore_mat != 'skin' else 0.0), 0.03 * b + (loose * 0.6 if fore_mat != 'skin' else 0.0)))
        if fore_mat != 'skin':
            # the cuff, and a fold or two at the elbow
            d = norm(wr - el)
            add(shirt, S.cone(wr - d * 0.045, wr - d * 0.005, 0.033 * b + loose * 0.7, 0.031 * b + loose * 0.6), order=1)
        elif look.get('sleeves') == 'rolled':
            d = norm(wr - el)
            add(shirt, S.torus(el + d * 0.02, 0.045 * b, 0.016, S.frame(np.cross(d, V(0, 0, 1)) if abs(d[2]) < 0.9 else V(1, 0, 0), np.cross(d, np.cross(d, V(0, 0, 1))) if abs(d[2]) < 0.9 else V(0, 1, 0))), order=2)
        # the hand, unless it's in the pouch or round the phone (that one's made with the phone)
        if not getattr(p, 'hands_in', [False, False])[i] and getattr(p, 'phone', -1) != i:
            add('skin', hand(B, wr, norm(wr - el), p.palm[i]), order=1)
    # the seat of the trousers, under the top's hem
    add(legs_mat, S.ellipsoid(p.pelvis + R @ V(0, -0.01, -0.05), V(0.15 * b + 0.008, 0.1 * b + 0.008, 0.085 * s), R))
    # legs
    for i in range(2):
        hp, kn, an = p.hip[i], p.knee[i], p.ankle[i]
        lb = 1.0 + (b - 1.0) * 0.6
        add(legs_mat, S.blend(0.04, S.cone(hp, kn, 0.088 * lb + 0.008, 0.056 * lb + 0.008),
                              S.cone(kn, an + V(0, 0, 0.04), 0.056 * lb + 0.008, 0.045 * lb + 0.006)))
        add(legs_mat, S.ellipsoid(kn + (an - kn) * 0.3 + norm(an - kn) * 0.0 - V(0, 0.025, 0), V(0.05 * lb, 0.045 * lb, 0.09), None))
        if look.get('shoes') == 'slippers':
            add('slipper', shoe(an, p.toe[i], s * 0.97, look), order=1)
        elif look.get('shoes', 'boots' if (B.old or top == 'hivis') else 'sneakers') == 'boots':
            add('boot', shoe(an, p.toe[i], s, look), order=1)
            add('boot_sole', sole(an, p.toe[i], s, look), order=2)
        else:
            add('shoe', shoe(an, p.toe[i], s, look), order=1)
            add('sole', sole(an, p.toe[i], s, look), order=2)
    # the top's own features
    if top == 'hoodie':
        hem = p.pelvis + R @ V(0, 0.0, 0.0)
        add('hoodie', S.ellipsoid(hem, V(0.165 * b + loose + 0.012, 0.113 * b + loose + 0.01, 0.035), R), order=1)
        pouch_c = p.waist + R @ V(0, 0.1 * b + loose + belly + 0.006, -0.035)
        add('hoodie', S.box(pouch_c, V(0.1, 0.018, 0.075), 0.016, R), order=2)
        if look.get('hat') != 'hood':
            add('hoodie', S.ellipsoid(p.neck + R @ V(0, -0.075, -0.02), V(0.11, 0.05, 0.07), R), order=1)
        if look.get('hat') == 'hood':
            for sx in (-1, 1):
                a = p.head + p.Rh @ V(sx * 0.04, 0.03, -0.19)
                add('cord', S.capsule(a, p.chest + R @ V(sx * 0.045, 0.12 * b + loose + 0.01, 0.02), 0.0055), order=3)
    elif top in ('jacket', 'coat', 'suit', 'tweed', 'cardigan', 'whites', 'flannel'):
        # a collar round the neck, and for a coat, the skirt of it over the hips
        col = {'jacket': 'jacket_trim', 'coat': 'coat', 'suit': 'suit', 'tweed': 'tweed', 'cardigan': 'cardigan', 'whites': 'whites', 'flannel': 'flannel'}[top]
        add(col, S.torus(p.neck + R @ V(0, 0.012, -0.012), 0.062 * b ** 0.5 + 0.012, 0.02, R @ S.rot(0, -0.35, 0)), order=1)
        if top == 'jacket':
            # a team jacket: ribbed band at the waist and the cuffs in the trim colour
            add('jacket_trim', S.ellipsoid(p.pelvis + R @ V(0, 0, 0.05), V(0.165 * b + loose + 0.02, 0.112 * b + loose + 0.02 + belly * 0.5, 0.032), R), order=2)
            for i in range(2):
                d = norm(p.wrist[i] - p.elbow[i])
                add('jacket_trim', S.cone(p.wrist[i] - d * 0.05, p.wrist[i] - d * 0.004, 0.036 * b + loose, 0.034 * b + loose), order=3)
        if top == 'coat':
            add('coat', S.blend(0.05, S.ellipsoid(p.pelvis + R @ V(0, 0.0, -0.12), V(0.19 * b, 0.13 * b, 0.2), R)), order=0)
        if top in ('cardigan', 'suit', 'tweed', 'jacket', 'coat'):
            # the opening down the front
            for k in range(4 if top == 'cardigan' else 2):
                add('button', S.sphere(p.chest + R @ V(0.0, chest_r[1] - 0.004, 0.05 - k * 0.07), 0.007), order=3)
    elif top == 'hivis':
        vest = S.intersect(S.offset(trunk, 0.006), S.box(p.chest + R @ V(0, 0, -0.12), V(0.3, 0.3, 0.3), 0.0, R))
        add('hivis', vest, order=1)
        for zz in (-0.08, -0.2):
            add('reflective', S.intersect(S.offset(trunk, 0.009), S.box(p.chest + R @ V(0, 0, zz), V(0.3, 0.3, 0.013), 0.0, R)), order=2)
    elif top == 'apron':
        add('apron', S.intersect(S.offset(trunk, 0.008), S.box(p.pelvis + R @ V(0, 0.2, 0.02), V(0.15, 0.2, 0.2), 0.0, R)), order=1)
        for i in range(2):
            add('apron', S.cone(p.hip[i] + R @ V(0, 0.04, 0.02), p.knee[i] + R @ V(0, 0.06, 0.0), 0.095, 0.075), order=1)
        add('apron', S.torus(p.waist + R @ V(0, 0, 0.0), 0.15 * b + 0.01, 0.008, R), order=2)
    return parts


def hand(B, wrist, along, palm, fist=False):
    """A hand as a mitten: palm, the fingers together (curled round something if `fist`), a thumb."""
    s = B.size * (0.95 if B.f else 1.0)
    side = norm(np.cross(palm, along))
    back = -palm
    c = wrist + along * 0.045 * s
    palmf = S.box(c, V(0.038 * s, 0.047 * s, 0.014 * s), 0.012, S.frame(side, along))
    if fist:
        f1 = S.capsule(c + along * 0.035 * s + back * 0.0, c + along * 0.05 * s + palm * 0.03 * s, 0.017 * s)
        fingers = S.blend(0.01, f1, S.capsule(c + along * 0.05 * s + palm * 0.03 * s + side * 0.02,
                                                c + along * 0.05 * s + palm * 0.03 * s - side * 0.02, 0.016 * s))
    else:
        fingers = S.box(c + along * 0.07 * s + palm * 0.006, V(0.036 * s, 0.04 * s, 0.011 * s), 0.01, S.frame(side, along))
    thumb = S.cone(c - side * 0.03 * s + palm * 0.006, c - side * 0.042 * s + along * 0.05 * s + palm * 0.025 * s, 0.012 * s, 0.009 * s)
    return S.blend(0.012, palmf, fingers, thumb)


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
    """The head at p.head turned by p.Rh: skull, face, features, hair, hat."""
    H, R = p.head, p.Rh
    s = B.size * (0.96 if B.f else 1.0)
    at = lambda x, y, z: H + R @ (V(x, y, z) * s)
    F = look.get('face', [])
    old, young, fem = B.old, B.young, B.f
    parts = []
    add = lambda name, f, order=0: parts.append(Part(name, f, order=order))
    jaw_w = 0.056 if fem else (0.061 if not young else 0.057)
    if 'beard' in F or B.bulk > 1.2:
        jaw_w += 0.004
    cheek = 0.0 if not young else 0.004
    sag = 0.008 if old else 0.0
    skull = S.ellipsoid(at(0, -0.014, 0.024), V(0.073, 0.093, 0.092) * s, R)
    face = S.ellipsoid(at(0, 0.028, -0.024), V(0.058, 0.066, 0.066) * s, R)
    # the jaw: from under each ear to the chin
    jaw = S.blend(0.022,
        S.cone(at(-jaw_w, -0.006, -0.05 - sag), at(-0.016, 0.062, -0.087 - sag * 0.5), 0.017 * s, 0.015 * s),
        S.cone(at(jaw_w, -0.006, -0.05 - sag), at(0.016, 0.062, -0.087 - sag * 0.5), 0.017 * s, 0.015 * s),
        S.ellipsoid(at(0, 0.064, -0.086 - sag * 0.5), V(0.024, 0.015, 0.016) * s, R))
    cheeks = S.union(S.ellipsoid(at(-0.045, 0.05, -0.004), V(0.021 + cheek, 0.018, 0.015) * s, R),
                     S.ellipsoid(at(0.045, 0.05, -0.004), V(0.021 + cheek, 0.018, 0.015) * s, R))
    bw = 0.0105 if fem or young else 0.0125
    brow = S.union(S.capsule(at(-0.05, 0.07, 0.024), at(-0.012, 0.083, 0.03), bw * s),
                   S.capsule(at(0.05, 0.07, 0.024), at(0.012, 0.083, 0.03), bw * s))
    nose = S.blend(0.01,
        S.cone(at(0, 0.088, 0.018), at(0, 0.109, -0.026), 0.0085 * s, 0.0115 * s),
        S.sphere(at(-0.0125, 0.096, -0.031), 0.0095 * s), S.sphere(at(0.0125, 0.096, -0.031), 0.0095 * s))
    lips = S.union(S.ellipsoid(at(0, 0.088, -0.05), V(0.021, 0.009, 0.0058) * s, R),
                   S.ellipsoid(at(0, 0.083, -0.0605), V(0.018, 0.0095, 0.0066) * s, R))
    ears = S.union(S.ellipsoid(at(-0.075, -0.006, -0.006), V(0.01, 0.02, 0.029) * s, R @ S.rot(0.25, 0, 0)),
                   S.ellipsoid(at(0.075, -0.006, -0.006), V(0.01, 0.02, 0.029) * s, R @ S.rot(-0.25, 0, 0)))
    head = S.blend(0.02 * s, skull, face, jaw, cheeks)
    head = S.blend(0.014 * s, head, brow)
    head = S.blend(0.008 * s, head, nose, lips, ears)
    # eye sockets under the brow, and the mouth's line
    for sx in (-1, 1):
        head = S.carve(head, S.ellipsoid(at(sx * 0.03, 0.084, 0.006), V(0.017, 0.013, 0.012) * s, R), 0.008 * s)
    head = S.carve(head, S.capsule(at(-0.02, 0.094, -0.0553), at(0.02, 0.094, -0.0553), 0.0017 * s), 0.002)
    if 'lined' in F or old:
        # the lines the years put in: across the brow, beside the mouth
        for zz in (0.05, 0.062):
            head = S.carve(head, S.capsule(at(-0.03, 0.082, zz), at(0.03, 0.082, zz), 0.0016 * s), 0.002)
        for sx in (-1, 1):
            head = S.carve(head, S.capsule(at(sx * 0.019, 0.096, -0.03), at(sx * 0.029, 0.086, -0.062), 0.002 * s), 0.003)
    add('skin', head)
    for sx in (-1, 1):
        eye_c = at(sx * 0.03, 0.07, 0.005)
        add('eye', S.sphere(eye_c, 0.0118 * s), order=1)
        # the lids: skins over the top of the eye and, thinner, the bottom, that leave an almond
        # open between them, 24 mm across and 9.5 high: the two arcs of two long cylinders run
        # front to back, one below whose top is the upper lid's edge, one above for the lower
        zc, w, h = 0.004, 0.024, 0.0095
        r = ((w / 2) ** 2 + h * h / 4) / h
        up_arc = S.capsule(at(sx * 0.03, 0.02, zc - (r - h / 2)), at(sx * 0.03, 0.14, zc - (r - h / 2)), r * s)
        low_arc = S.capsule(at(sx * 0.03, 0.02, zc + (r - h / 2)), at(sx * 0.03, 0.14, zc + (r - h / 2)), r * s)
        above = S.box(at(sx * 0.03, 0.07, zc + 0.02), V(0.03, 0.03, 0.02) * s, 0.0, R)
        below = S.box(at(sx * 0.03, 0.07, zc - 0.02), V(0.03, 0.03, 0.02) * s, 0.0, R)
        add('skin', S.carve(S.intersect(S.sphere(eye_c, 0.0132 * s), above), up_arc), order=2)
        add('skin', S.carve(S.intersect(S.sphere(eye_c, 0.0126 * s), below), low_arc), order=2)
        # the iris: a dark cap standing a little proud of the white, straight ahead, the lids over
        # its top and bottom edges, so he looks at whoever he's facing. It's cut to the almond, so
        # it never shows through the lids.
        iris = S.sphere(at(sx * 0.03, 0.0782, 0.004), 0.0062 * s)
        add('iris', S.intersect(S.intersect(iris, up_arc), low_arc), order=3)
    if 'earbuds' in F:
        for sx in (-1, 1):
            add('earbud', S.ellipsoid(at(sx * 0.074, 0.008, -0.012), V(0.008, 0.009, 0.011) * s, R), order=3)
    if 'hearingaid' in F:
        add('earbud', S.ellipsoid(at(-0.084, -0.02, 0.0), V(0.006, 0.01, 0.016) * s, R), order=3)
    if 'glasses' in F:
        for sx in (-1, 1):
            add('glasses', S.torus(at(sx * 0.032, 0.098, 0.006), 0.019 * s, 0.0022 * s, R @ S.rot(0, np.pi / 2, 0)), order=3)
            add('glasses', S.capsule(at(sx * 0.05, 0.096, 0.008), at(sx * 0.074, 0.01, 0.01), 0.0018 * s), order=3)
        add('glasses', S.capsule(at(-0.013, 0.1, 0.01), at(0.013, 0.1, 0.01), 0.002 * s), order=3)
    if 'moustache' in F or 'beard' in F:
        add('hair', S.ellipsoid(at(0, 0.098, -0.05), V(0.028, 0.012, 0.008) * s, R), order=2)
    if 'beard' in F:
        beard = S.carve(S.blend(0.02, S.offset(jaw, 0.008 * s), S.ellipsoid(at(0, 0.06, -0.085), V(0.055, 0.045, 0.04) * s, R)),
                        S.ellipsoid(at(0, 0.1, -0.063), V(0.02, 0.02, 0.012) * s, R), 0.004)
        add('hair', beard, order=1)
    elif 'stubble' in F:
        add('stubble', S.offset(jaw, 0.0015), order=1)
    # hair
    hair = look.get('hair', 'short')
    hat = look.get('hat')
    top_skull = S.intersect(S.offset(skull, 0.008 * s), S.box(at(0, -0.01, 0.07), V(0.1, 0.12, 0.08) * s, 0.0, R))
    if hat is None:
        if hair in ('short', 'parted', 'messy'):
            h = S.intersect(S.offset(skull, 0.009 * s), S.carve(S.box(at(0, -0.01, 0.04), V(0.1, 0.12, 0.08) * s, 0.0, R),
                                                              S.ellipsoid(at(0, 0.1, 0.0), V(0.08, 0.06, 0.06) * s, R), 0.01))
            if hair == 'parted':
                h = S.carve(h, S.capsule(at(-0.03, 0.08, 0.09), at(-0.03, -0.1, 0.08), 0.003 * s), 0.002)
            if hair == 'messy':
                h = S.ripple(h, 0.003, 180.0, (0.3, 0.7, 0.2))
            add('hair', h, order=1)
        elif hair == 'buzz':
            add('hair', S.intersect(S.offset(skull, 0.003 * s), S.carve(S.box(at(0, -0.01, 0.04), V(0.1, 0.12, 0.08) * s, 0.0, R),
                                                                       S.ellipsoid(at(0, 0.1, 0.0), V(0.08, 0.06, 0.07) * s, R), 0.01)), order=1)
        elif hair == 'thin':
            add('hair', S.intersect(S.offset(skull, 0.005 * s), S.carve(S.box(at(0, -0.04, 0.0), V(0.1, 0.07, 0.05) * s, 0.0, R),
                                                                       S.ellipsoid(at(0, 0.1, 0.0), V(0.08, 0.06, 0.07) * s, R), 0.01)), order=1)
        elif hair in ('long', 'bun', 'ponytail'):
            add('hair', S.intersect(S.offset(skull, 0.01 * s), S.carve(S.box(at(0, -0.01, 0.03), V(0.1, 0.12, 0.09) * s, 0.0, R),
                                                                      S.ellipsoid(at(0, 0.1, -0.005), V(0.07, 0.06, 0.06) * s, R), 0.01)), order=1)
            if hair == 'long':
                add('hair', S.ellipsoid(at(0, -0.045, -0.1), V(0.085, 0.055, 0.14) * s, R), order=1)
            if hair == 'bun':
                add('hair', S.sphere(at(0, -0.1, 0.07), 0.035 * s), order=1)
            if hair == 'ponytail':
                add('hair', S.cone(at(0, -0.1, 0.02), at(0, -0.14, -0.16), 0.022 * s, 0.012 * s), order=1)
    elif hat == 'cap':
        crown = S.intersect(S.offset(skull, 0.012 * s), S.box(at(0, -0.01, 0.07), V(0.1, 0.12, 0.075) * s, 0.0, R))
        add('cap', crown, order=1)
        add('cap', S.box(at(0, 0.1, 0.05), V(0.058, 0.05, 0.0035) * s, 0.003, R @ S.rot(0, -0.12, 0)), order=2)
        add('hair', S.intersect(S.offset(skull, 0.006 * s), S.box(at(0, -0.06, -0.02), V(0.09, 0.05, 0.03) * s, 0.0, R)), order=1)
    elif hat == 'flatcap':
        add('cap', S.ellipsoid(at(0, 0.004, 0.075), V(0.085, 0.1, 0.035) * s, R @ S.rot(0, -0.12, 0)), order=1)
        add('cap', S.box(at(0, 0.09, 0.052), V(0.06, 0.03, 0.004) * s, 0.003, R @ S.rot(0, -0.25, 0)), order=2)
    elif hat == 'beanie':
        add('cap', S.intersect(S.offset(skull, 0.012 * s), S.box(at(0, -0.01, 0.08), V(0.1, 0.12, 0.085) * s, 0.0, R)), order=1)
        add('cap', S.torus(at(0, -0.01, 0.01), 0.08 * s, 0.01 * s, R), order=2)
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
        # his fringe, swept across under the peak
        add('hair', S.blend(0.01, S.cone(at(-0.042, 0.06, 0.068), at(0.008, 0.088, 0.05), 0.011 * s, 0.007 * s),
                            S.cone(at(0.008, 0.088, 0.05), at(0.04, 0.08, 0.036), 0.007 * s, 0.003 * s)), order=1)
    if hat is None and hair == 'bald':
        pass
    return parts


# ---------------------------------------------------------------------------------------- things they hold

def held_parts(B, p, look):
    parts = []
    if getattr(p, 'phone', -1) >= 0:
        i = p.phone
        wr, el = p.wrist[i], p.elbow[i]
        along = norm(wr - el)
        palm = p.palm[i]
        side = norm(np.cross(palm, along))
        c = wr + along * 0.07 + palm * 0.022
        # the phone stands up out of the fist, its screen toward the doorman (palm side)
        up = norm(V(0, 0, 1) - palm * np.dot(V(0, 0, 1), palm))
        Rp = S.frame(np.cross(up, palm), up)
        ph = c + up * 0.04
        # the phone itself is made as a clean box in export_people.py; here just where it is
        p.phone_at = (ph, Rp)
        # the hand round its lower half: the palm flat on its back, the fingers over its outer edge,
        # the thumb up the inner one, their tips on the glass's border
        k = B.size * (0.95 if B.f else 1.0)
        L = lambda x, y, z: ph + Rp @ (V(x, y, z) * k)
        grip = [S.box(L(0.0, -0.045, -0.017), V(0.037, 0.043, 0.011) * k, 0.01, Rp),
                S.capsule(wr, L(0.0, -0.075, -0.018), 0.026 * k)]
        for j, y in enumerate((-0.068, -0.05, -0.032, -0.014)):
            r = (0.0085 - 0.0008 * j) * k
            grip.append(S.capsule(L(-0.032, y, -0.02), L(-0.045, y, -0.006), r))
            grip.append(S.capsule(L(-0.045, y, -0.006), L(-0.037, y + 0.002, 0.0075), r * 0.95))
        grip.append(S.capsule(L(0.026, -0.078, -0.016), L(0.043, -0.05, -0.002), 0.0105 * k))
        grip.append(S.capsule(L(0.043, -0.05, -0.002), L(0.037, -0.022, 0.008), 0.0095 * k))
        parts.append(Part('skin', S.blend(0.008, *grip), order=1))
    if hasattr(p, 'cue'):
        a, b2 = p.cue
        parts.append(Part('cue', S.cone(a + V(0, 0, 0.01), b2, 0.015, 0.0065), order=4))
    return parts


# ---------------------------------------------------------------------------------------- a person

POSES = {'stand': pose_stand, 'walk_pouch': pose_walk_pouch, 'phone_out': pose_phone_out, 'sit': pose_sit,
         'cue': pose_cue, 'bar': pose_bar, 'reach': pose_reach}


def person(look, pose='stand', **pose_kw):
    B = Build(look)
    p = POSES[pose](B, **pose_kw)
    parts = body_parts(B, p, look) + head_parts(B, p, look) + held_parts(B, p, look)
    return B, p, parts


def mesh_person(look, pose='stand', step=0.012, head_step=None, **pose_kw):
    """Mesh a person, as a list of (part, verts, faces, material per face, material names). With
    `head_step`, the head is a mesh of its own at that finer step, since a face needs it; the two
    overlap at the neck, inside the collar or the hood."""
    B = Build(look)
    p = POSES[pose](B, **pose_kw)
    body = body_parts(B, p, look) + held_parts(B, p, look)
    head = head_parts(B, p, look)
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
    hlo, hhi = p.head + V(-0.2, -0.2, -0.3), p.head + V(0.2, 0.2, 0.2)
    clip = S.box((hlo + hhi) / 2, (hhi - hlo) / 2 - head_step * 1.5)
    head = [Part(q.name, S.intersect(q.f, clip), order=q.order) for q in head]
    out.append(("head", *S.mesh_islands(head, hlo, hhi, head_step)))
    return out
