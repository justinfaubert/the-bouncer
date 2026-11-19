"""The people as masks (PROPOSED, Hutch's pick of 18 November 2026: "the masks are the better
approach, use that as a template and then each character gets its own unique spin").

Each person is the borrowed base body (models/quaternius/, CC0) on its borrowed skeleton, so the
animation library plays on all of them, made our own:

- the body smoothed (no superhero muscles) and pushed out where the person is (a belly, a chest,
  hips), the skin and the tight clothes painted on it by which bone each part of it follows;
- the clothes that stand off the body made as real shapes on the same bones, so they have edges
  the print can draw: a team jacket with its knit collar, cuffs and band, its snaps and its crest;
  a shirt with its collar open and its sleeves rolled; a long canvas apron and a bar towel over
  the shoulder; a full skirt, a narrow belt and a server's pouch; a belt and its buckle;
- its head taken off and a mask head put on the head bone: an egg shaped by the person (the jaw,
  the chin, the crown, the cheekbones), a nose of their own, ears, hair as solid shells (a beard
  too, where there is one), what they wear on it or in it (a ball cap with its brim, seams and
  patch, a pencil behind an ear, pearl drops);
- the face drawn, not sculpted (tools/faces.py), and laid together in the game (game/face.gd);
- Amanda's braid on bones of its own, hung from her head, that the game swings (game/hair.gd).

The proportions (the big head, the squat body, the big hands) are put on the skeleton in the game
(tests/shots_masks.gd for now), so one model serves every clip.

  python3 tools/masks.py              every one
  python3 tools/masks.py amanda       just one

Writes models/masks/<name>.glb. Needs Blender's Python module (pip install bpy) and numpy.
"""
import math
import os
import sys

import bpy  # noqa: I001 (first: it brings bmesh and mathutils)
import bmesh
import numpy as np  # noqa: F401
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.dirname(HERE)
BASE = os.path.join(GODOT, 'models', 'quaternius')
OUT = os.path.join(GODOT, 'models', 'masks')

# the base bodies face -y (Blender), z up: a point's "forward" is -y, its left +x
FINGERS = ('hand', 'thumb', 'index', 'middle', 'ring', 'pinky')

COLOURS = {
    'skin': '#c7a38a', 'skin_pale': '#d9c0ae', 'skin_ruddy': '#c4927a', 'skin_olive': '#a97f58',
    'hair': '#3a2e26', 'hair_grey': '#6e7276', 'hair_white': '#d2cec6', 'hair_dark': '#16120f', 'hair_black': '#140f0c',
    'shirt_dark': '#2c2c30', 'trousers': '#3b3a38', 'shoe': '#2a221c', 'sneaker': '#d8d3c8', 'shoe_black': '#1c1a1a',
    'jacket': '#183a2e', 'jacket_trim': '#d0ac5c', 'snap': '#b8b2a2', 'slacks': '#5a5248',
    'flannel': '#6a3a2a', 'flannel_dark': '#4a281e', 'jeans': '#3a4557', 'boot': '#4a3626', 'belt': '#2e221a', 'buckle': '#c9a85a',
    'top_red': '#a3222a', 'tie_red': '#a3222a', 'skirt_black': '#1e1c20', 'tights': '#2a2628', 'apron_white': '#ece6d8',
    'apron_canvas': '#4f4436', 'towel': '#e4ddcc', 'pencil': '#d8a428', 'pencil_wood': '#d9b88a', 'graphite': '#2a2a2a',
    'gold': '#d4ac52', 'sole': '#2a2420',
    'dress_red': '#861c26', 'apron_black': '#1a191c', 'belt_black': '#141315', 'pearl': '#ece6da',
    'beard_grey': '#5e5650', 'towel_white': '#e8e2d2',
    'cap_navy': '#252b3b', 'cap_patch': '#ddd5c2',
}

# Who they are.
#   base: the borrowed body; smooth: how much of its muscle is smoothed away
#   body: what's pushed out: (bone, offset from it in metres: x to their left, f forward, z up;
#         radius; how far, out or in)
#   paint: the skin and the tight clothes: top (material, sleeves: long, elbow, rolled, short), bottom,
#          legs below a skirt (and how far above the knee they start), shoes; shaft (boots: how
#          far up the leg); heels (degrees the foot is pitched in the game, the heel built to
#          meet the floor there); neckline (a scoop to this height at the middle; with boat, a
#          boat neck: nearly level from shoulder to shoulder, just under the collarbones)
#   wear: the clothes and things that stand off the body (see dress())
#   head: the egg (w, d, h half-sizes in metres), jaw (<1 narrower below), chin (forward), crown,
#         cheeks, flat (how flat the face is, a mask's plane: 1 not at all); nose (kind, size); ears (size, and 'boxer' for a cauliflower ear); hair (kind,
#         material); beard; things: what's in the hair or the ears
PEOPLE = {
    # Jim, the bartender (Hutch, 19 November 2026: the model read as a man, so he is one, in a ball
    # cap "for now", and he takes Paige's place in the story): the lifer, slight and wiry, fifties,
    # a long face and a hard mouth; grey hair cropped short under a dark cap with a pale patch on
    # its front, a pencil behind his ear; his black shirt's sleeves rolled, a long canvas apron, a
    # bar towel thrown over his shoulder, black work shoes. Printed in the night's ink, like the
    # bar itself
    'jim': dict(
        base='male', smooth=12,
        body=[('spine_02', (0, 0.06, 0.02), 0.14, -0.012)],
        paint=dict(top=('shirt_dark', 'rolled'), bottom='trousers', shoes='shoe_black'),
        wear=['shell:shirt_dark:0.004', 'collar:shirt_dark', 'rolls:shirt_dark', 'apron_long:apron_canvas', 'towel_shoulder:towel_white'],
        head=dict(w=0.088, d=0.105, h=0.135, jaw=0.86, chin=0.014, crown=0.95, cheeks=0.25),
        nose=('long', 1.05), ears=0.95, hair=('short', 'hair_grey'), beard=None, skin='skin', things=['cap', 'pencil_ear']),
    # table 28's loudest: old, a round belly under the same team jacket every day (bottle green,
    # gold trim: it prints in the cold ink, the television's), a few hairs combed over, a big soft
    # drinker's face
    'team_jacket': dict(
        base='male', smooth=14,
        body=[('spine_01', (0, 0.13, -0.02), 0.2, 0.085), ('pelvis', (0, 0.1, 0.05), 0.16, 0.03),
              ('spine_03', (0, 0.05, 0), 0.16, -0.02)],
        paint=dict(top=('jacket', 'long'), bottom='slacks', shoes='shoe'),
        wear=['shell:jacket:0.012', 'knit:jacket_trim', 'snaps', 'crest', 'belt'],
        head=dict(w=0.1, d=0.105, h=0.12, jaw=1.15, chin=-0.004, crown=0.85, cheeks=0.8),
        nose=('bulb', 1.25), ears=1.15, hair=('thin', 'hair_grey'), beard=None, skin='skin_ruddy', things=[]),
    # at the pool table since before the shift: huge through the shoulders, his head shaved and his
    # jaw grey with stubble (a pale dome reads from across the room, where dark hair and a dark beard
    # didn't; a grey beard of its own, a shell round his jaw, read as a muzzle; faces.py draws the
    # stubble), a small head on a thick neck, a broken nose and a boxer's ear; a brick flannel
    # shirt (the earth's ink), open at the neck, sleeves rolled, a belt with a big buckle
    'bigman': dict(
        base='male', smooth=14,
        body=[('spine_03', (0, 0.02, 0.02), 0.2, 0.03), ('spine_01', (0, 0.1, 0), 0.18, 0.04)],
        paint=dict(top=('flannel', 'rolled'), bottom='jeans', shoes='boot', shaft=0.11),
        wear=['shell:flannel:0.007', 'flaps:flannel_dark', 'rolls:flannel', 'pockets:flannel_dark', 'belt', 'buckle'],
        head=dict(w=0.092, d=0.1, h=0.11, jaw=1.2, chin=0.004, crown=0.8, cheeks=0.3),
        nose=('broken', 1.1), ears=(0.85, 'boxer'), hair=None, beard=None, skin='skin', things=[]),
    # the new server, from Germany. Her features a little like Disney's Pocahontas (she isn't Native):
    # a long face, high broad cheekbones, a strong level brow, long dark eyes lifted at the outer
    # corners, a full mouth, a defined chin; olive skin; black hair parted in the middle and drawn
    # back into a braid that hangs to the backs of her thighs, a strand loose at each temple; pearl
    # drops. A crimson dress out of an old European film: a boat neck, sleeves to the elbow, a narrow
    # black belt, a full skirt to below the knee; a server's black pouch at her hip, dark stockings,
    # low black heels. The one person in the room printed in the sign's red, and drawn closer to the
    # human than the rest (her proportions, her light and her motion: tests/shots_masks.gd)
    'amanda': dict(
        base='female', smooth=6,
        body=[('spine_03', (0.07, 0.09, 0.03), 0.08, 0.006), ('spine_03', (-0.07, 0.09, 0.03), 0.08, 0.006),
              ('spine_01', (0.125, 0.0, 0.08), 0.075, -0.012), ('spine_01', (-0.125, 0.0, 0.08), 0.075, -0.012),
              ('pelvis', (0.165, 0.0, 0.0), 0.1, 0.008), ('pelvis', (-0.165, 0.0, 0.0), 0.1, 0.008)],
        paint=dict(top=('dress_red', 'elbow'), bottom='tights', shoes='shoe_black', heels=14, neckline=1.425, boat=True),
        wear=['shell:dress_red:0.003', 'swing:dress_red:-0.07:0.14', 'sash:belt_black', 'pouch:apron_black'],
        head=dict(w=0.09, d=0.1, h=0.13, jaw=0.75, chin=0.014, crown=1.0, cheeks=1.05, flat=0.85),
        nose=('fine', 1.0), ears=0.75, hair=('centre', 'hair_black'), beard=None, skin='skin_olive',
        things=['pearls', 'wisps', 'parted'], braid=dict(length=1.05, bones=8)),
}


def colour(hexs):
    h = hexs.lstrip('#')
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c] + [1.0]


def material(name):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get('Principled BSDF')
        base = name if name in COLOURS else 'skin'
        bsdf.inputs['Base Color'].default_value = colour(COLOURS.get(base, '#c7a38a'))
        bsdf.inputs['Roughness'].default_value = 0.9
    return m


def link(ob):
    bpy.context.scene.collection.objects.link(ob)
    return ob


def smoothstep(a, b, x):
    t = min(max((x - a) / (b - a), 0.0), 1.0)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- the body

def body(obj, arm, spec):
    """Smoothed, let out, painted. Gives back each vertex's place and its bone, for fitting the
    clothes to."""
    me = obj.data
    groups = {g.index: g.name for g in obj.vertex_groups}
    bones = arm.data.bones
    head_z = bones['Head'].head_local.z

    bm = bmesh.new()
    bm.from_mesh(me)
    deform = bm.verts.layers.deform.active
    # one skin: the import splits the mesh along its texture seams, and smoothing pulls the two sides
    # of a seam apart (cracks at the shoulders, the hips, the neck)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.verts.ensure_lookup_table()

    def doms():
        return [groups[max(v[deform].items(), key=lambda x: x[1])[0]] if v[deform] else '' for v in bm.verts]
    dom = doms()

    # the head goes: the mask sits on the neck
    gone = [bm.verts[i] for i, d in enumerate(dom) if d == 'Head' or (d == 'neck_01' and bm.verts[i].co.z > head_z - 0.015)]
    bmesh.ops.delete(bm, geom=gone, context='VERTS')
    bm.verts.ensure_lookup_table()
    dom = doms()

    # no superhero: the torso and limbs smoothed till the muscles go
    soft = [v for v, d in zip(bm.verts, dom) if d and not d.startswith(FINGERS + ('foot', 'ball', 'neck'))]
    for _ in range(spec.get('smooth', 14)):
        bmesh.ops.smooth_vert(bm, verts=soft, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bm.normal_update()
    for v in soft:
        v.co += v.normal * 0.004 * spec.get('smooth', 14) / 14
    # in shoes: the toes smoothed into one toe cap, the sole kept flat on the floor
    feet = [v for v, d in zip(bm.verts, dom) if d.startswith(('foot', 'ball'))]
    sole = {v: v.co.z for v in feet if v.co.z < 0.012}
    for _ in range(18):
        bmesh.ops.smooth_vert(bm, verts=feet, factor=0.5, use_axis_x=True, use_axis_y=False, use_axis_z=True)
    for v, z in sole.items():
        v.co.z = z
    bm.normal_update()
    for v in feet:
        v.co += v.normal * 0.005

    # pushed out (or in) where the person is
    for bone, off, r, amt in spec['body']:
        c = bones[bone].head_local + Vector((off[0], -off[1], off[2]))
        for v in bm.verts:
            d = (v.co - c).length
            if d < r:
                k = 0.5 + 0.5 * math.cos(math.pi * d / r)
                v.co += v.normal * amt * k
    bm.normal_update()

    # the skin and the tight clothes, painted on by which bone each face follows and where it is
    cl = spec['paint']
    skin = spec['skin']
    names = [skin, cl['top'][0], cl['bottom'], cl['shoes']] + ([cl['legs']] if cl.get('legs') else [])
    slot = {n: i for i, n in enumerate(dict.fromkeys(names))}
    me.materials.clear()
    for n in slot:
        me.materials.append(material(n))
    sleeves = cl['top'][1]
    pelvis_z = bones['pelvis'].head_local.z
    knee_z = bones['calf_l'].head_local.z
    ankle_z = bones['foot_l'].head_local.z
    legs_z = knee_z + cl.get('legs_from', 0.12)
    sleeve_x = abs(bones['upperarm_l'].head_local.x) + 0.07
    roll_x = abs(bones['lowerarm_l'].head_local.x) + 0.06
    elbow_x = abs(bones['lowerarm_l'].head_local.x) + 0.035
    boat = cl.get('boat', False)

    def neck_front(x):
        if boat:
            return cl['neckline'] + 0.014 * (abs(x) / 0.11) ** 2
        return cl['neckline'] + 0.075 * (abs(x) / 0.11) ** 2

    def neck_at(x, fwd):
        w = smoothstep(-0.07, 0.03, fwd)
        return w * neck_front(x) + (1.0 - w) * (cl['neckline'] + (0.03 if boat else 0.07))
    for f in bm.faces:
        ds = [dom[v.index] for v in f.verts]
        d = max(set(ds), key=ds.count)
        c = f.calc_center_median()
        fwd = -c.y
        if d.startswith(FINGERS) or d == 'neck_01':
            m = skin
        elif d.startswith(('foot', 'ball')):
            m = cl['shoes']
        elif d.startswith('calf') and cl.get('shaft') and c.z < ankle_z + cl['shaft']:
            m = cl['shoes']
        elif d.startswith('lowerarm'):
            if sleeves == 'long':
                m = cl['top'][0]
            elif sleeves == 'rolled':
                # rolled to the elbow: the forearm bare past a hand's breadth from it
                m = cl['top'][0] if abs(c.x) < roll_x else skin
            elif sleeves == 'elbow':
                m = cl['top'][0] if abs(c.x) < elbow_x else skin
            else:
                m = skin
        elif d.startswith('upperarm'):
            m = cl['top'][0] if sleeves != 'short' or abs(c.x) < sleeve_x else skin
        elif d.startswith(('thigh', 'calf')):
            m = cl['bottom']
            if cl.get('legs') and c.z < legs_z:
                m = cl['legs']
        elif d == 'pelvis':
            m = cl['bottom'] if c.z < pelvis_z + 0.05 else cl['top'][0]
        else:
            m = cl['top'][0]
            # a scoop neck: the skin of the chest above a curve, and of the back above the shoulder blades
            if cl.get('neckline') and d in ('spine_03', 'clavicle_l', 'clavicle_r'):
                if c.z > neck_at(c.x, fwd):
                    m = skin
        f.material_index = slot[m]
        f.smooth = True
    # each edge between two paints laid along its line, not stepping from face to face: a neckline
    # that's a curve, a sleeve that ends straight round the arm. Each edge is where some measure
    # of a point is zero; a vertex on it is slid along the skin till it is
    name_of = {i: n for n, i in slot.items()}
    top = cl['top'][0]

    def edge_of(here, d):
        if {skin, top} <= here and cl.get('neckline') and d in ('spine_03', 'clavicle_l', 'clavicle_r'):
            return lambda p: p.z - neck_at(p.x, -p.y)
        if {skin, top} <= here and d.startswith('upperarm') and sleeves == 'short':
            return lambda p: abs(p.x) - sleeve_x
        if {skin, top} <= here and d.startswith('lowerarm') and sleeves == 'rolled':
            return lambda p: abs(p.x) - roll_x
        if {skin, top} <= here and d.startswith('lowerarm') and sleeves == 'elbow':
            return lambda p: abs(p.x) - elbow_x
        if cl.get('legs') and {cl['bottom'], cl['legs']} <= here and d.startswith(('thigh', 'calf')):
            return lambda p: p.z - legs_z
        if {cl['bottom'], top} <= here and d == 'pelvis':
            return lambda p: p.z - (pelvis_z + 0.05)
        if cl.get('shaft') and {cl['shoes'], cl['bottom']} <= here and d.startswith('calf'):
            return lambda p: p.z - (ankle_z + cl['shaft'])
        return None
    bm.normal_update()
    moves = {}
    for v in bm.verts:
        here = {name_of[f.material_index] for f in v.link_faces}
        if len(here) < 2:
            continue
        fn = edge_of(here, dom[v.index])
        if fn is None:
            continue
        p = v.co.copy()
        n = v.normal.copy()
        for _ in range(4):
            e = 1e-4
            f0 = fn(p)
            g = Vector(((fn(p + Vector((e, 0, 0))) - f0) / e, (fn(p + Vector((0, e, 0))) - f0) / e, (fn(p + Vector((0, 0, e))) - f0) / e))
            g -= n * g.dot(n)
            if g.length_squared < 1e-8:
                break
            p -= g * (f0 / g.length_squared)
        if (p - v.co).length < 0.025:
            moves[v] = p
    for v, p in moves.items():
        v.co = p
    bm.normal_update()
    bm.to_mesh(me)
    pts = [(obj.matrix_world @ v.co, d) for v, d in zip(bm.verts, dom)]
    bm.free()
    me.update()
    return pts


# ---------------------------------------------------------------- clothes and things on the bones

def to_object(bm, name, mats, thick=0.0):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(material(m) if isinstance(m, str) else m)
    for p in me.polygons:
        p.use_smooth = True
    ob = link(bpy.data.objects.new(name, me))
    if thick:
        solid(ob, thick)
    return ob


def solid(ob, thick):
    # a shell given a thickness, so it's solid seen from inside too (the print draws only the side
    # of a face that looks at us) and has an edge to draw
    mod = ob.modifiers.new('solid', 'SOLIDIFY')
    mod.thickness = thick
    mod.offset = -1.0
    mod.use_rim = True
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
    ob.modifiers.clear()
    ob.data = me


def skin_to(ob, arm, weights):
    """Bound to the skeleton: weights(co) gives each vertex's bones and how much each moves it."""
    per = [weights(v.co) for v in ob.data.vertices]
    names = sorted({n for w in per for n in w})
    groups = {n: ob.vertex_groups.new(name=n) for n in names}
    for v, w in zip(ob.data.vertices, per):
        tot = sum(w.values()) or 1.0
        for n, x in w.items():
            if x > 0:
                groups[n].add([v.index], x / tot, 'REPLACE')
    ob.parent = arm
    mod = ob.modifiers.new('skeleton', 'ARMATURE')
    mod.object = arm
    return ob


def on_bone(ob, arm, bone):
    """Fixed to one bone, the way a mask is to the head."""
    bpy.context.view_layer.update()
    mw = ob.matrix_world.copy()
    ob.parent = arm
    ob.parent_type = 'BONE'
    ob.parent_bone = bone
    bpy.context.view_layer.update()
    ob.matrix_world = mw
    return ob


def shell_from(bodyob, arm, mats, name, out, thick):
    """The body's faces in these materials, stood off it and given a thickness: clothes with
    edges, moving with the same bones."""
    me = bodyob.data.copy()
    ob = link(bpy.data.objects.new(name, me))
    for g in bodyob.vertex_groups:
        ob.vertex_groups.new(name=g.name)
    keep = {i for i, m in enumerate(me.materials) if m and m.name in mats}
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index not in keep], context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * out
    bm.to_mesh(me)
    bm.free()
    if thick:
        solid(ob, thick)
    ob.parent = arm
    mod = ob.modifiers.new('skeleton', 'ARMATURE')
    mod.object = arm
    return ob


def frame(a):
    a = a.normalized()
    ref = Vector((0, 0, 1)) if abs(a.z) < 0.9 else Vector((0, -1, 0))
    u = a.cross(ref).normalized()
    return a, u, a.cross(u).normalized()


def fit(pts, c, a, bones, slab=0.012, maxr=0.3):
    """How far the body reaches round an axis at a point: half-sizes across (u) and through (v)."""
    a, u, v = frame(a)
    rx = ry = 0.0
    for p, d in pts:
        if bones and not d.startswith(bones):
            continue
        q = p - c
        if abs(q.dot(a)) > slab:
            continue
        x, y = q.dot(u), q.dot(v)
        if x * x + y * y > maxr * maxr:
            continue
        rx, ry = max(rx, abs(x)), max(ry, abs(y))
    return rx, ry


def tube_band(name, mat, c, a, rx, ry, width, thick, arm, weights, segs=28, flare=0.0, open_front=0.0):
    """A band round a limb, the neck or the body (a cuff, a collar, a knit hem)."""
    a, u, v = frame(a)
    bm = bmesh.new()
    rings = []
    angs = [2 * math.pi * i / segs for i in range(segs)]
    for t in (-0.5, 0.5):
        k = 1.0 + flare * (t + 0.5)
        rings.append([bm.verts.new(c + a * (t * width) + u * (math.cos(g) * rx * k) + v * (math.sin(g) * ry * k)) for g in angs])
    for i in range(segs):
        j = (i + 1) % segs
        mid = c + u * math.cos(angs[i]) * rx + v * math.sin(angs[i]) * ry
        if open_front and (mid - c).normalized().dot(Vector((0, -1, 0))) > 1 - open_front:
            continue
        f = bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
    bm.normal_update()
    for f in bm.faces:
        q = f.calc_center_median() - c
        if f.normal.dot(q - a * q.dot(a)) < 0:
            f.normal_flip()
    bmesh.ops.delete(bm, geom=[vv for vv in bm.verts if not vv.link_faces], context='VERTS')
    ob = to_object(bm, name, [mat], thick)
    return skin_to(ob, arm, weights)


def slice_ring(pts, z, bones, angs, gap, cy=None):
    """The body cut level at this height, its outline as far as it reaches in each direction (so a
    skirt goes round both legs, not between them)."""
    sl = [p for p, d in pts if abs(p.z - z) < 0.02 and d.startswith(bones)]
    if not sl:
        return None, []
    if cy is None:
        cy = sum(p.y for p in sl) / len(sl)
    out = []
    for g in angs:
        dx, dy = math.cos(g), math.sin(g)
        h = max(p.x * dx + (p.y - cy) * dy for p in sl) + gap
        out.append(Vector((dx * h, cy + dy * h, z)))
    return cy, out


def sheet(name, mat, rings, closed, thick, arm, weights, centre=None):
    bm = bmesh.new()
    vs = [[bm.verts.new(p) for p in r] for r in rings]
    n = len(rings[0])
    for a, b in zip(vs, vs[1:]):
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.normal_update()
    ob = to_object(bm, name, [mat])
    # facing out from the body's middle (an open sheet, an apron, is told where that is: its own
    # middle is in front of the body)
    me = ob.data
    cx = sum(v.co.x for v in me.vertices) / len(me.vertices)
    cy = sum(v.co.y for v in me.vertices) / len(me.vertices)
    if centre is not None:
        cx, cy = centre
    flip = sum(1 for p in me.polygons if p.normal.x * (p.center.x - cx) + p.normal.y * (p.center.y - cy) < 0) > len(me.polygons) / 2
    if flip:
        bm = bmesh.new()
        bm.from_mesh(me)
        for f in bm.faces:
            f.normal_flip()
        bm.to_mesh(me)
        bm.free()
    if thick:
        solid(ob, thick)
    return skin_to(ob, arm, weights)


def legs_weights(top_z, crotch_z, hem_z):
    """A skirt's bones: the pelvis at the waist, more and more the legs towards the hem."""
    def w(co):
        k = 0.9 * smoothstep(crotch_z + 0.05, hem_z, co.z)
        side = co.x / (abs(co.x) + 0.05)
        out = {'pelvis': 1.0 - k}
        if k > 0:
            out['thigh_l'] = k * (0.5 + 0.5 * side)
            out['thigh_r'] = k * (0.5 - 0.5 * side)
        return out
    return w


def front_y(pts, x, z, r=0.03):
    near = [p.y for p, _ in pts if abs(p.x - x) < r and abs(p.z - z) < r]
    return min(near) if near else 0.0


def back_y(pts, z, r=0.03):
    near = [p.y for p, d in pts if abs(p.x) < 0.07 and abs(p.z - z) < r and not d.startswith(('upperarm', 'lowerarm') + FINGERS)]
    return max(near) if near else 0.1


def blob(bm, at, size, rot=None, segs=16, rings=10):
    m = Matrix.Translation(at) @ (rot or Matrix.Identity(4)) @ Matrix.Diagonal((*size, 1.0))
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0, matrix=m)


def tube(bm, pts, radii, sides=8):
    """A tube along a line of points, its radius at each: a strand of hair, a pencil."""
    rings = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        _, u, v = frame(t)
        rings.append([bm.verts.new(p + (u * math.cos(2 * math.pi * k / sides) + v * math.sin(2 * math.pi * k / sides)) * radii[i]) for k in range(sides)])
    for a, b in zip(rings, rings[1:]):
        for k in range(sides):
            j = (k + 1) % sides
            bm.faces.new((a[k], a[j], b[j], b[k]))
    for r, end in ((rings[0], pts[0]), (rings[-1], pts[-1])):
        c = bm.verts.new(end)
        for k in range(sides):
            bm.faces.new((r[k], r[(k + 1) % sides], c) if r is rings[-1] else (r[(k + 1) % sides], r[k], c))


def torus(bm, c, axis, big, small, segs=20, sides=6):
    a, u, v = frame(axis)
    rings = []
    for i in range(segs):
        g = 2 * math.pi * i / segs
        d = u * math.cos(g) + v * math.sin(g)
        rings.append([bm.verts.new(c + d * (big + small * math.cos(2 * math.pi * k / sides)) + a * small * math.sin(2 * math.pi * k / sides)) for k in range(sides)])
    for i in range(segs):
        r0, r1 = rings[i], rings[(i + 1) % segs]
        for k in range(sides):
            j = (k + 1) % sides
            bm.faces.new((r0[k], r0[j], r1[j], r1[k]))


def curve(pts, n=12):
    """A smooth line through the points."""
    out = []
    p = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        for j in range(n):
            t = j / n
            out.append(0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    out.append(pts[-1])
    return out


def dress(spec, name, bodyob, arm, pts):
    """The clothes that stand off the body, and what's on them."""
    bones = arm.data.bones
    B = {b: bones[b].head_local.copy() for b in ('pelvis', 'spine_01', 'spine_02', 'spine_03', 'neck_01', 'Head', 'thigh_l', 'calf_l')}
    pelvis_z, knee_z = B['pelvis'].z, B['calf_l'].z
    crotch_z = B['thigh_l'].z - 0.07
    one = lambda b: (lambda co: {b: 1.0})  # noqa: E731
    out = []
    under = {}           # what a thing laid over another needs of it: a skirt's rings for its apron
    for item in spec['wear']:
        kind, *args = item.split(':')
        if kind == 'shell':
            out.append(shell_from(bodyob, arm, [args[0]], f'{name}_{args[0]}', float(args[1]), 0.005))
        elif kind == 'collar':
            # a shirt's collar stood up round the neck and open at the front
            c = B['neck_01'] + Vector((0, 0.0, 0.015))
            a = (B['Head'] - B['neck_01'])
            rx, ry = fit(pts, c, a, ('neck', 'spine_03'), 0.02)
            out.append(tube_band(f'{name}_collar', args[0], c, a, rx + 0.012, ry + 0.012, 0.04, 0.004, arm,
                                 lambda co: {'neck_01': 0.4, 'spine_03': 0.6}, flare=0.25, open_front=0.25))
        elif kind == 'knit':
            # a team jacket's knit collar, cuffs and band, striped
            c = B['neck_01'] + Vector((0, 0.0, 0.0))
            a = (B['Head'] - B['neck_01'])
            rx, ry = fit(pts, c, a, ('neck', 'spine_03'), 0.02)
            out.append(tube_band(f'{name}_knit_collar', args[0], c, a, rx + 0.016, ry + 0.016, 0.045, 0.006, arm,
                                 lambda co: {'neck_01': 0.5, 'spine_03': 0.5}, flare=0.12))
            for s, b in ((1, 'l'), (-1, 'r')):
                lo, hd = bones[f'lowerarm_{b}'].head_local, bones[f'hand_{b}'].head_local
                a = hd - lo
                c = hd - a.normalized() * 0.035
                rx, ry = fit(pts, c, a, ('lowerarm',), 0.02)
                out.append(tube_band(f'{name}_knit_cuff_{b}', args[0], c, a, rx + 0.016, ry + 0.016, 0.055, 0.006, arm, one(f'lowerarm_{b}')))
            z = pelvis_z + 0.02
            angs = [2 * math.pi * i / 36 for i in range(36)]
            cy, r0 = slice_ring(pts, z - 0.025, ('pelvis', 'spine_01', 'thigh'), angs, 0.024)
            _, r1 = slice_ring(pts, z + 0.025, ('pelvis', 'spine_01', 'thigh'), angs, 0.024, cy)
            out.append(sheet(f'{name}_knit_band', args[0], [r0, r1], True, 0.006, arm, lambda co: {'pelvis': 0.6, 'spine_01': 0.4}))
        elif kind == 'rolls':
            # sleeves rolled to the elbow: a fat roll of cloth there
            for b in ('l', 'r'):
                lo, hd = bones[f'lowerarm_{b}'].head_local, bones[f'hand_{b}'].head_local
                a = hd - lo
                c = lo + a.normalized() * 0.06
                rx, ry = fit(pts, c, a, ('lowerarm',), 0.02)
                out.append(tube_band(f'{name}_roll_{b}', args[0], c, a, rx + 0.014, ry + 0.014, 0.045, 0.012, arm, one(f'lowerarm_{b}')))
        elif kind == 'flaps':
            # an open collar: two points of it lying on the chest either side of the neck
            bm = bmesh.new()
            for s in (1, -1):
                top = B['neck_01'] + Vector((s * 0.06, -0.045, 0.0))
                pts3 = [top, top + Vector((s * 0.05, -0.012, -0.03)), B['neck_01'] + Vector((s * 0.025, -0.075, -0.075))]
                pts3 = [p + Vector((0, -0.006, 0)) for p in pts3]
                v = [bm.verts.new(p) for p in pts3]
                bm.faces.new(v if s > 0 else v[::-1])
            bm.normal_update()
            ob = to_object(bm, f'{name}_flaps', [args[0]], 0.006)
            out.append(skin_to(ob, arm, lambda co: {'spine_03': 1.0}))
        elif kind == 'pockets':
            # two chest pockets with buttoned flaps, lying on the curve of the chest
            bm = bmesh.new()
            for s in (1, -1):
                x, z = s * 0.1, B['spine_03'].z + 0.06
                for (w, h, dz, off) in ((0.05, 0.055, -0.03, 0.008), (0.054, 0.02, 0.025, 0.014)):
                    grid = []
                    for i in range(5):
                        row = []
                        for j in range(5):
                            px, pz = x - w + 2 * w * j / 4, z + dz - h + 2 * h * i / 4
                            row.append(bm.verts.new(Vector((px, front_y(pts, px, pz, 0.02) - off, pz))))
                        grid.append(row)
                    for i in range(4):
                        for j in range(4):
                            bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
                blob(bm, Vector((x, front_y(pts, x, z + 0.012, 0.02) - 0.02, z + 0.012)), (0.008, 0.005, 0.008), segs=8, rings=6)
            bm.normal_update()
            for f in bm.faces:
                if f.normal.y > 0:
                    f.normal_flip()
            ob = to_object(bm, f'{name}_pockets', [args[0]], 0.004)
            out.append(skin_to(ob, arm, lambda co: {'spine_03': 1.0}))
        elif kind == 'belt':
            z = pelvis_z + 0.035
            angs = [2 * math.pi * i / 40 for i in range(40)]
            cy, r0 = slice_ring(pts, z - 0.02, ('pelvis', 'spine_01'), angs, 0.012 if 'jacket' not in spec['paint']['top'][0] else 0.03)
            _, r1 = slice_ring(pts, z + 0.02, ('pelvis', 'spine_01'), angs, 0.012 if 'jacket' not in spec['paint']['top'][0] else 0.03, cy)
            if 'jacket' in spec['paint']['top'][0]:
                # under the jacket: only the buckle shows below its band
                continue
            out.append(sheet(f'{name}_belt', 'belt', [r0, r1], True, 0.006, arm, lambda co: {'pelvis': 1.0}))
        elif kind == 'buckle':
            z = pelvis_z + 0.035
            y = front_y(pts, 0.0, z, 0.04) - 0.02
            bm = bmesh.new()
            bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation((0, y, z)) @ Matrix.Diagonal((0.085, 0.012, 0.06, 1.0)))
            ob = to_object(bm, f'{name}_buckle', ['buckle'])
            out.append(skin_to(ob, arm, lambda co: {'pelvis': 1.0}))
        elif kind == 'snaps':
            bm = bmesh.new()
            for i in range(5):
                z = B['spine_03'].z + 0.14 - i * 0.085
                y = front_y(pts, 0.0, z, 0.03) - 0.02
                blob(bm, Vector((0.0, y, z)), (0.009, 0.004, 0.009), segs=10, rings=6)
            ob = to_object(bm, f'{name}_snaps', ['snap'])
            out.append(skin_to(ob, arm, lambda co: {'spine_03': 1.0} if co.z > B['spine_02'].z else {'spine_02': 0.5, 'spine_01': 0.5}))
        elif kind == 'crest':
            # the team's crest on his heart: a shield with a band across it
            x, z = 0.1, B['spine_03'].z + 0.07
            y = front_y(pts, x, z, 0.03) - 0.016
            bm = bmesh.new()
            sh = [(-0.04, 0.035), (0.04, 0.035), (0.04, -0.005), (0.0, -0.05), (-0.04, -0.005)]
            bm.faces.new([bm.verts.new(Vector((x + a, y, z + b))) for a, b in sh][::-1])
            bm.normal_update()
            ob = to_object(bm, f'{name}_crest', ['jacket_trim'], 0.004)
            out.append(skin_to(ob, arm, lambda co: {'spine_03': 1.0}))
            bm = bmesh.new()
            q = [(-0.042, 0.008), (0.042, 0.008), (0.042, -0.006), (-0.042, -0.006)]
            bm.faces.new([bm.verts.new(Vector((x + a, y - 0.0045, z + b))) for a, b in q][::-1])
            ob = to_object(bm, f'{name}_crest_band', ['jacket'], 0.002)
            out.append(skin_to(ob, arm, lambda co: {'spine_03': 1.0}))
        elif kind == 'skirt':
            # a pencil skirt: round the hips and both legs together, to the knee (the game lengthens the
            # thigh below where the skirt is bound to it, so it ends a little above the knee there)
            top, hem = pelvis_z + 0.1, knee_z - 0.015
            angs = [2 * math.pi * i / 48 for i in range(48)]
            rings, cy = [], None
            for k in range(12):
                z = top + (hem - top) * k / 11
                c0, r = slice_ring(pts, z, ('pelvis', 'spine_01', 'thigh'), angs, 0.01 + 0.002 * k / 11, cy)
                cy = cy if cy is not None else c0
                rings.append(r)
            sk = sheet(f'{name}_skirt', args[0], rings, True, 0.006, arm, legs_weights(top, crotch_z, hem))
            # the slit: the back of the hem parted a hand's length up
            me = sk.data
            for v in me.vertices:
                g = math.atan2(v.co.y - cy, v.co.x)
                if v.co.z < hem + 0.11 and abs(math.remainder(g - math.pi / 2, 2 * math.pi)) < 0.06:
                    v.co.z = max(v.co.z, hem + 0.11 * (1 - abs(math.remainder(g - math.pi / 2, 2 * math.pi)) / 0.06))
            out.append(sk)
            c0, r0 = slice_ring(pts, top - 0.03, ('pelvis', 'spine_01'), angs, 0.016, cy)
            _, r1 = slice_ring(pts, top + 0.002, ('pelvis', 'spine_01'), angs, 0.016, cy)
            out.append(sheet(f'{name}_skirt_band', args[0], [r0, r1], True, 0.005, arm, lambda co: {'pelvis': 0.7, 'spine_01': 0.3}))
        elif kind == 'swing':
            # a swing skirt: fitted at the waist, flaring from the hips to the knee in soft folds. It
            # follows her hips and sways a little with her legs, and as it's never tight on them it
            # never tears between them when she walks (a pencil skirt bound to two legs does). Its
            # hem (from the knee) and its waist (from the pelvis) can be given
            top = pelvis_z + (float(args[2]) if len(args) > 2 else 0.1)
            hem = knee_z + (float(args[1]) if len(args) > 1 else 0.03)
            hip_z = pelvis_z - 0.05
            angs = [2 * math.pi * i / 64 for i in range(64)]
            cy, _ = slice_ring(pts, top, ('pelvis', 'spine_01'), angs, 0.012)
            _, r_hip = slice_ring(pts, hip_z, ('pelvis', 'spine_01', 'thigh'), angs, 0.016, cy)
            rings = []
            n_r = 16
            for k in range(n_r):
                z = top + (hem - top) * k / (n_r - 1)
                if z >= hip_z:
                    gap = 0.012 + 0.004 * (top - z) / (top - hip_z)
                    _, r = slice_ring(pts, z, ('pelvis', 'spine_01', 'thigh'), angs, gap, cy)
                else:
                    u = (hip_z - z) / (hip_z - hem)
                    r = []
                    for g, p in zip(angs, r_hip):
                        d = Vector((p.x, p.y - cy, 0.0))
                        # wider to the sides than to the front and back, and folding as it falls
                        grow = 1.0 + (0.62 - 0.14 * abs(math.sin(g))) * u ** 1.25
                        fold = 1.0 + 0.05 * u * math.sin(9 * g + 0.4)
                        q = d * grow * fold
                        r.append(Vector((q.x, cy + q.y, z)))
                rings.append(r)

            # how much of the hem goes with the legs: a long skirt with too much of it parts between
            # them as she steps, like a slit
            legs = 0.35 if hem > knee_z else 0.2

            def swing_w(co, top=top, hem=hem, hip_z=hip_z, legs=legs):
                k = legs * smoothstep(hip_z, hem, co.z)
                side = co.x / (abs(co.x) + 0.12)
                w = {'pelvis': 1.0 - k}
                if k > 0:
                    w['thigh_l'] = k * (0.5 + 0.5 * side)
                    w['thigh_r'] = k * (0.5 - 0.5 * side)
                if co.z > top - 0.05:
                    w = {'pelvis': 0.7, 'spine_01': 0.3}
                return w
            spec['_skirt_back'] = [(r[0].z, max(p.y for p in r)) for r in rings]
            out.append(sheet(f'{name}_skirt', args[0], rings, True, 0.006, arm, swing_w))
            c0, r0 = slice_ring(pts, top - 0.03, ('pelvis', 'spine_01'), angs, 0.016, cy)
            _, r1 = slice_ring(pts, top + 0.002, ('pelvis', 'spine_01'), angs, 0.016, cy)
            out.append(sheet(f'{name}_skirt_band', args[0], [r0, r1], True, 0.005, arm, lambda co: {'pelvis': 0.7, 'spine_01': 0.3}))
            under['skirt'] = (rings, cy, angs, swing_w)
            under['waist'] = (top, cy)
        elif kind == 'sash' and 'waist' in under:
            # a narrow belt where the bodice meets the skirt
            top, cy = under['waist']
            angs = [2 * math.pi * i / 48 for i in range(48)]
            _, r0 = slice_ring(pts, top - 0.013, ('pelvis', 'spine_01'), angs, 0.02, cy)
            _, r1 = slice_ring(pts, top + 0.013, ('pelvis', 'spine_01'), angs, 0.02, cy)
            out.append(sheet(f'{name}_sash', args[0], [r0, r1], True, 0.005, arm, lambda co: {'pelvis': 0.5, 'spine_01': 0.5}))
        elif kind == 'pouch' and 'skirt' in under:
            # a server's pouch for the order pad and the change, hung from the belt at her right hip,
            # where her hand goes for it: the job at her side, not an apron on her lap (a black one
            # was a dark square there that drew the eye, as the white one had; a palm's width, or
            # it's a black card on the red from across the room)
            rings, cy, angs, w = under['skirt']
            top = under['waist'][0]
            side = [i for i, g in enumerate(angs) if abs(math.remainder(g + 2.8, 2 * math.pi)) < 0.16]
            side.sort(key=lambda i: math.remainder(angs[i] + 2.8, 2 * math.pi))
            pr = []
            for r in [r for r in rings if top - 0.035 > r[0].z > top - 0.145][:4]:
                row = []
                for i in side:
                    d = Vector((r[i].x, r[i].y - cy, 0.0))
                    q = d * ((d.length + 0.016) / d.length)
                    row.append(Vector((q.x, cy + q.y, r[i].z)))
                pr.append(row)
            if len(pr) >= 2:
                out.append(sheet(f'{name}_pouch', args[0], pr, False, 0.012, arm, w, (0.0, cy)))
        elif kind == 'apron_half' and 'skirt' in under:
            # a white half apron lying over the front of the skirt, a pocket on it for the order pad; its
            # band round her waist, tied in a bow at the back. Small, so the skirt's black shows round
            # it: it's the brightest white on her, and a big one pulled the eye to her lap, not her face
            rings, cy, angs, w = under['skirt']
            front = [i for i, g in enumerate(angs) if abs(math.remainder(g + math.pi / 2, 2 * math.pi)) < 0.8]
            front.sort(key=lambda i: math.remainder(angs[i] + math.pi / 2, 2 * math.pi))
            ar = []
            drop = float(args[1]) if len(args) > 1 else 0.3
            for r in [r for r in rings[1:] if r[0].z > rings[0][0].z - drop][:8]:
                row = []
                for i in front:
                    d = Vector((r[i].x, r[i].y - cy, 0.0))
                    q = d * ((d.length + 0.009) / d.length)
                    row.append(Vector((q.x, cy + q.y, r[i].z)))
                ar.append(row)
            out.append(sheet(f'{name}_apron', args[0], ar, False, 0.004, arm, w, (0.0, cy)))
            top = rings[1][0].z
            c0, r0 = slice_ring(pts, top - 0.012, ('pelvis', 'spine_01'), [2 * math.pi * i / 40 for i in range(40)], 0.024, cy)
            _, r1 = slice_ring(pts, top + 0.016, ('pelvis', 'spine_01'), [2 * math.pi * i / 40 for i in range(40)], 0.024, cy)
            out.append(sheet(f'{name}_apron_band', args[0], [r0, r1], True, 0.004, arm, lambda co: {'pelvis': 0.7, 'spine_01': 0.3}))
            # the pocket, on her right, where her right hand goes for the pad
            mid = ar[4]
            j = int(len(mid) * 0.32)
            pc = mid[j]
            d = Vector((pc.x, pc.y - cy, 0.0)).normalized()
            side = Vector((-d.y, d.x, 0.0))
            pc = pc + d * 0.004
            bm = bmesh.new()
            q = [pc + side * sx * 0.055 + Vector((0, 0, sz * 0.045)) for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
            f = bm.faces.new([bm.verts.new(p) for p in q])
            bm.normal_update()
            if f.normal.dot(d) < 0:
                f.normal_flip()
            # the bow at the back
            by = back_y(pts, top) + 0.03
            for s in (1, -1):
                blob(bm, Vector((s * 0.03, by, top + 0.005)), (0.03, 0.008, 0.016), Matrix.Rotation(s * 0.3, 4, 'Y'), segs=10, rings=6)
                blob(bm, Vector((s * 0.022, by + 0.004, top - 0.07)), (0.012, 0.004, 0.06), Matrix.Rotation(s * 0.25, 4, 'Y'), segs=8, rings=6)
            ob = to_object(bm, f'{name}_apron_bits', [args[0]], 0.003)
            out.append(skin_to(ob, arm, lambda co: {'pelvis': 1.0}))
        elif kind == 'apron_half':
            # a white half apron over the front of the skirt, a pocket on it for the order pad, its
            # band round her waist and tied in a bow at the back
            top, hem = pelvis_z + 0.08, pelvis_z - 0.22
            # bound the way the skirt under it is, so the two move as one and the skirt never shows
            # through
            under = legs_weights(pelvis_z + 0.1, crotch_z, knee_z - 0.015) if 'skirt:' in ' '.join(spec['wear']) else legs_weights(top, crotch_z, hem)
            angs = [-math.pi / 2 + 1.15 * (i / 16 - 0.5) * 2 for i in range(17)]
            rings, cy = [], None
            for k in range(8):
                z = top + (hem - top) * k / 7
                c0, r = slice_ring(pts, z, ('pelvis', 'spine_01', 'thigh'), angs, 0.022, cy)
                cy = cy if cy is not None else c0
                rings.append(r)
            out.append(sheet(f'{name}_apron', args[0], rings, False, 0.004, arm, under, (0.0, cy)))
            angs = [2 * math.pi * i / 40 for i in range(40)]
            c0, r0 = slice_ring(pts, top - 0.012, ('pelvis', 'spine_01'), angs, 0.026)
            _, r1 = slice_ring(pts, top + 0.016, ('pelvis', 'spine_01'), angs, 0.026, c0)
            out.append(sheet(f'{name}_apron_band', args[0], [r0, r1], True, 0.004, arm, lambda co: {'pelvis': 0.7, 'spine_01': 0.3}))
            px, pz = -0.07, top - 0.1
            py = min(p.y for p in rings[3]) - 0.006
            bm = bmesh.new()
            q = [Vector((px - 0.055, py, pz - 0.045)), Vector((px + 0.055, py, pz - 0.045)), Vector((px + 0.055, py, pz + 0.045)), Vector((px - 0.055, py, pz + 0.045))]
            bm.faces.new([bm.verts.new(p) for p in q][::-1])
            # the bow at the back
            by = back_y(pts, top) + 0.03
            for s in (1, -1):
                blob(bm, Vector((s * 0.03, by, top + 0.005)), (0.03, 0.008, 0.016), Matrix.Rotation(s * 0.3, 4, 'Y'), segs=10, rings=6)
                blob(bm, Vector((s * 0.022, by + 0.004, top - 0.07)), (0.012, 0.004, 0.06), Matrix.Rotation(s * 0.25, 4, 'Y'), segs=8, rings=6)
            ob = to_object(bm, f'{name}_apron_bits', [args[0]], 0.003)
            out.append(skin_to(ob, arm, lambda co: {'pelvis': 1.0}))
        elif kind == 'apron_long':
            # a long canvas apron, waist to shin, wrapped round the front and sides
            top, hem = pelvis_z + 0.06, knee_z - 0.18
            angs = [-math.pi / 2 + 1.75 * (i / 20 - 0.5) * 2 for i in range(21)]
            rings, cy = [], None
            for k in range(12):
                z = top + (hem - top) * k / 11
                c0, r = slice_ring(pts, z, ('pelvis', 'spine_01', 'thigh', 'calf'), angs, 0.02 + 0.02 * k / 11, cy)
                cy = cy if cy is not None else c0
                rings.append(r)
            out.append(sheet(f'{name}_apron', args[0], rings, False, 0.004, arm, legs_weights(top, crotch_z, hem), (0.0, cy)))
            angs = [2 * math.pi * i / 40 for i in range(40)]
            c0, r0 = slice_ring(pts, top - 0.01, ('pelvis', 'spine_01'), angs, 0.024)
            _, r1 = slice_ring(pts, top + 0.012, ('pelvis', 'spine_01'), angs, 0.024, c0)
            out.append(sheet(f'{name}_apron_band', args[0], [r0, r1], True, 0.004, arm, lambda co: {'pelvis': 0.7, 'spine_01': 0.3}))
        elif kind == 'towel_shoulder':
            # a bar towel thrown over her left shoulder, a hand's length down her front and her back
            x0, cz = 0.1, B["spine_03"].z + 0.04
            near = [p for p, d in pts if abs(p.x - x0) < 0.05 and d.startswith(('spine_03', 'clavicle', 'neck', 'spine_02'))]
            rows = []
            for i in range(19):
                phi = math.radians(-58 + 290 * i / 18)
                ray = Vector((0.0, -math.cos(phi), math.sin(phi)))
                row = []
                for j in range(5):
                    x = x0 - 0.04 + 0.08 * j / 4
                    c = Vector((x, 0.01, cz))
                    best = 0.04
                    for p in near:
                        q = p - c
                        if abs(q.x) > 0.018:
                            continue
                        along = q.y * ray.y + q.z * ray.z
                        side = math.hypot(q.y - ray.y * along, q.z - ray.z * along)
                        if side < 0.02 and along > best:
                            best = along
                    wob = 0.004 * math.sin(i * 1.7 + j)
                    row.append(c + ray * (best + 0.011 + wob))
                rows.append(row)
            ob = sheet(f'{name}_towel', args[0] if args else 'towel', [list(r) for r in zip(*rows)], False, 0.006, arm,
                       lambda co: {'spine_03': 0.6, 'clavicle_l': 0.4}, (x0, 0.01))
            out.append(ob)
        elif kind == 'towel':
            # a bar towel tucked in the apron's band at her right hip, folded over it
            x, z = -0.12, pelvis_z + 0.07
            y = front_y(pts, x, z - 0.05, 0.04) - 0.03
            bm = bmesh.new()
            for (dy, z0, z1, w) in ((0.0, z + 0.03, z - 0.27, 0.07), (-0.008, z + 0.03, z - 0.06, 0.072)):
                q = [Vector((x - w, y + dy, z1)), Vector((x + w, y + dy, z1)), Vector((x + w, y + dy, z0)), Vector((x - w, y + dy, z0))]
                bm.faces.new([bm.verts.new(p) for p in q][::-1])
            bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=3, use_grid_fill=True)
            for v in bm.verts:
                v.co.y += 0.01 * math.sin((v.co.x - x) * 60) + 0.12 * (v.co.x - x) ** 2 / 0.07
            ob = to_object(bm, f'{name}_towel', ['towel'], 0.006)
            out.append(skin_to(ob, arm, lambda co: {'pelvis': 0.6, 'thigh_r': 0.4} if co.z < z - 0.1 else {'pelvis': 1.0}))
    return out


def prism(bm, bottom, top):
    """A solid between two outlines of the same number of points, the bottom one under the top."""
    b = [bm.verts.new(p) for p in bottom]
    t = [bm.verts.new(p) for p in top]
    n = len(b)
    bm.faces.new(b[::-1])
    bm.faces.new(t)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((b[i], b[j], t[j], t[i]))


def soles(spec, name, arm, pts):
    """A sole under each shoe, its edge standing proud of the upper; and for heels, the heel, built
    where it meets the floor once the game has pitched the foot and lifted her onto it."""
    bones = arm.data.bones
    deg = spec['paint'].get('heels', 0)
    out = []
    for b in ('l', 'r'):
        fp = [p for p, d in pts if d.startswith((f'foot_{b}', f'ball_{b}')) and p.z < 0.025]
        cx = sum(p.x for p in fp) / len(fp)
        cy = sum(p.y for p in fp) / len(fp)
        angs = [2 * math.pi * i / 32 for i in range(32)]
        ring = []
        for g in angs:
            dx, dy = math.cos(g), math.sin(g)
            h = max((p.x - cx) * dx + (p.y - cy) * dy for p in fp) + 0.005
            ring.append((cx + dx * h, cy + dy * h))
        bm = bmesh.new()
        prism(bm, [Vector((x, y, -0.004)) for x, y in ring], [Vector((x, y, 0.012)) for x, y in ring])
        ball_y = bones[f'ball_{b}'].head_local.y
        ob = to_object(bm, f'{name}_sole_{b}', ['sole'])
        out.append(skin_to(ob, arm, lambda co, b=b, ball_y=ball_y: {f'ball_{b}': 1.0} if co.y < ball_y - 0.01 else
                           ({f'foot_{b}': 1.0} if co.y > ball_y + 0.02 else {f'ball_{b}': 0.5, f'foot_{b}': 0.5})))
        if not deg:
            continue
        # the foot pitched toes down about the ankle by deg, the body lifted till the ball of the foot
        # is back where it was: where the heel's tip has to reach, worked back to the foot at rest
        a = bones[f'foot_{b}'].head_local
        ball = bones[f'ball_{b}'].head_local
        th = math.radians(deg)

        def rot(f, z, k=1):
            return f * math.cos(th) + k * z * math.sin(th), -k * f * math.sin(th) + z * math.cos(th)
        af, az = -a.y, a.z
        bf, bz = rot(-ball.y - af, ball.z - az)
        lift = ball.z - (az + bz)

        def to_game(p):
            f, z = rot(-p.y - af, p.z - az)
            return Vector((p.x, -(af + f), az + z + lift))

        def to_rest(q):
            f, z = rot(-q.y - af, q.z - lift - az, -1)
            return Vector((q.x, -(af + f), az + z))
        heel_y = max(p.y for p in fp)
        # both outlines counter-clockwise seen from above, so the faces look outward
        top = [Vector((cx + sx * 0.02, heel_y + 0.004 - dy, -0.004)) for sx, dy in ((-1, 0.045), (1, 0.045), (1, 0.0), (-1, 0.0))]
        back = to_game(top[3]).y
        foot = [Vector((cx + sx * 0.012, back - dy, 0.0)) for sx, dy in ((-1, 0.028), (1, 0.028), (1, 0.008), (-1, 0.008))]
        bm = bmesh.new()
        prism(bm, [to_rest(q) for q in foot], top)
        ob = to_object(bm, f'{name}_heel_{b}', ['sole'])
        out.append(skin_to(ob, arm, lambda co, b=b: {f'foot_{b}': 1.0}))
    return out


# ---------------------------------------------------------------- the mask head

def egg_point(spec, d):
    """Where the egg's surface is in a direction from its middle (a point on the unit sphere)."""
    h = spec['head']
    x, y, z = d
    f = -y
    # the crown narrower or fuller, the jaw narrower or heavier
    if z > 0:
        k = 1.0 + (h['crown'] - 1.0) * z
        x, f = x * k, f * (0.6 + 0.4 * k)
    else:
        k = 1.0 + (h['jaw'] - 1.0) * (-z) ** 1.2
        x = x * k
    # cheeks: the face wider at the cheekbones
    cb = math.exp(-((z + 0.05) / 0.28) ** 2) * max(f, 0.0)
    x *= 1.0 + 0.18 * h['cheeks'] * cb
    # the chin forward
    if z < -0.6 and f > 0:
        f += h['chin'] / h['d'] * ((-z - 0.6) / 0.4) * f
    # the face flatter than the back of the skull, a mask's plane
    if f > 0.55:
        f = 0.55 + (f - 0.55) * h.get('flat', 0.6)
    return Vector((x * h['w'], -f * h['d'], z * h['h']))


def egg(spec, segs=48, rings=32, dirs=None):
    """The head's shape as a function on the unit sphere: x to their left, f forward, z up. dirs, a
    dict, is given each vertex's direction on the sphere."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    for v in bm.verts:
        if dirs is not None:
            dirs[v] = v.co.copy()
        v.co = egg_point(spec, v.co.copy())
    return bm


def hairline(x):
    """Sleek hair's hairline on the unit sphere, how high it is across the forehead: a soft peak
    in the middle, the line rounding down to the temples."""
    return 0.74 - 0.34 * x * x - 0.06 * math.exp(-(x / 0.1) ** 2)


def sleek_scale(d):
    """How far out from the egg sleek hair lies, in a direction: flat on the skin at the hairline,
    rising behind it, combed up off the forehead and back, with height at the crown."""
    x, f, z = d.x, -d.y, d.z
    if f <= 0.0:
        k = 1.045
    else:
        k = 1.006 + 0.039 * smoothstep(0.0, 0.14, z - hairline(x))
    k *= 1.0 + 0.05 * smoothstep(0.02, 0.3, z - hairline(x)) * smoothstep(0.0, 0.5, f)
    return k * (1.0 + 0.03 * max(z - 0.3, 0.0))


def hairline_c(x):
    """Hair parted in the middle and drawn back: its line across the forehead, a notch where it
    parts, falling away to either side over the corners of the forehead toward the temples."""
    return 0.72 + 0.05 * math.exp(-(x / 0.06) ** 2) - 0.36 * x * x


def centre_scale(d):
    """How far out from the egg hair parted in the middle lies: flat at the hairline, rising behind
    it, a little full in two wings over the temples and the tops of the ears, a groove at the part."""
    x, f, z = d.x, -d.y, d.z
    hl = hairline_c(x)
    if f <= 0.0:
        k = 1.045
    else:
        k = 1.006 + 0.039 * smoothstep(0.0, 0.14, z - hl)
    side = smoothstep(0.45, 0.85, abs(x)) * math.exp(-((z - 0.15) / 0.4) ** 2) * smoothstep(-0.6, 0.1, f)
    k *= 1.0 + 0.04 * side
    k *= 1.0 - 0.014 * math.exp(-(x / 0.04) ** 2) * smoothstep(0.25, 0.6, z) * smoothstep(-0.4, 0.2, f)
    return k * (1.0 + 0.025 * max(z - 0.3, 0.0))


def face_uvs(ob, spec):
    """The face's picture projected from the front onto the mask; the back of the head and the
    sides take the picture's corner, which is bare skin."""
    h = spec['head']
    me = ob.data
    uv = me.uv_layers.new(name='UVMap')
    for p in me.polygons:
        n = p.normal
        for li in p.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            if -n.y > 0.05 and -co.y > 0.0:
                u = 0.5 + co.x / (2.2 * h['w'])
                v = 0.5 + co.z / (2.2 * h['h'])
                uv.data[li].uv = (u, v)
            else:
                uv.data[li].uv = (0.01, 0.01)


def head(spec, name):
    """The mask head and what's on it, centred on the origin (moved onto the neck after)."""
    h = spec['head']
    skin = spec['skin']
    bm = egg(spec)
    mask = to_object(bm, f'{name}_mask', [material(f'face_{name}')])
    face_uvs(mask, spec)
    parts = [mask]

    # the nose
    kind, s = spec['nose']
    bm = bmesh.new()
    fz = -0.24 * h['h']                  # the tip of the nose a quarter of the way down the face
    front = h['d'] * 0.8
    if kind == 'bulb':
        blob(bm, Vector((0, -front - 0.012 * s, fz)), (0.02 * s, 0.018 * s, 0.018 * s))
        blob(bm, Vector((0, -front + 0.004, fz + 0.02)), (0.009 * s, 0.012 * s, 0.024 * s))
    elif kind == 'long':
        blob(bm, Vector((0, -front - 0.008 * s, fz + 0.012)), (0.011 * s, 0.016 * s, 0.034 * s), Matrix.Rotation(-0.35, 4, 'X'))
    elif kind == 'broken':
        # broken and set crooked: a bump on the bridge, the tip off to one side
        blob(bm, Vector((0.004, -front - 0.01 * s, fz + 0.01)), (0.016 * s, 0.018 * s, 0.03 * s), Matrix.Rotation(-0.25, 4, 'X') @ Matrix.Rotation(0.12, 4, 'Y'))
        blob(bm, Vector((-0.002, -front - 0.004, fz + 0.034)), (0.01 * s, 0.01 * s, 0.01 * s))
        blob(bm, Vector((0.009, -front - 0.016 * s, fz - 0.008)), (0.012 * s, 0.011 * s, 0.01 * s))
    elif kind == 'fine':
        # straight and fine: a low ridge down from between the eyes, a neat tip
        blob(bm, Vector((0, -front + 0.003, fz + 0.03)), (0.0065 * s, 0.009 * s, 0.032 * s), Matrix.Rotation(-0.22, 4, 'X'))
        blob(bm, Vector((0, -front - 0.004, fz + 0.002)), (0.0095 * s, 0.0085 * s, 0.0085 * s))
    else:  # button
        blob(bm, Vector((0, -front - 0.006 * s, fz)), (0.012 * s, 0.011 * s, 0.011 * s))
        blob(bm, Vector((0, -front + 0.002, fz + 0.016)), (0.006 * s, 0.008 * s, 0.018 * s))
    parts.append(to_object(bm, f'{name}_nose', [skin]))

    # the ears: a boxer's swollen on one side
    e = spec['ears']
    boxer = isinstance(e, tuple) and 'boxer' in e
    e = e[0] if isinstance(e, tuple) else e
    if e:
        bm = bmesh.new()
        for sx in (-1, 1):
            blob(bm, Vector((sx * h['w'] * 0.98, 0.004, -0.01)), (0.008 * e, 0.016 * e, 0.026 * e))
            blob(bm, Vector((sx * h['w'] * 1.02, 0.008, -0.03)), (0.007 * e, 0.009 * e, 0.009 * e))
            if boxer and sx > 0:
                for (dy, dz, r) in ((-0.004, 0.012, 0.012), (0.008, -0.002, 0.011), (0.0, -0.022, 0.01)):
                    blob(bm, Vector((sx * h['w'] * 1.03, dy, dz)), (r * 0.8, r, r), segs=10, rings=8)
        parts.append(to_object(bm, f'{name}_ears', [skin]))

    # the hair: a shell of the egg a little out from it, cut to the hairline, and lumps (none: bald)
    kind, hm = spec['hair'] if spec.get('hair') else (None, None)
    fine = kind in ('sleek', 'centre')
    dirs = {}
    shell = egg(spec, *((96, 64) if fine else (48, 32)), dirs=dirs)
    for v in shell.verts:
        v.co = v.co * (sleek_scale(dirs[v]) if kind == 'sleek' else centre_scale(dirs[v]) if kind == 'centre'
                       else 1.035 if kind == 'short' else 1.06)
    drop = []
    for v in shell.verts:
        x, f, z = v.co.x / h['w'], -v.co.y / h['d'], v.co.z / h['h']
        if fine:
            x, f, z = dirs[v].x, -dirs[v].y, dirs[v].z
        if kind == 'bun':
            ok = z > 0.42 - 0.25 * (1 - max(f, 0)) or (f < -0.1 and z > -0.55) or (abs(x) > 0.85 and z > -0.1 and f < 0.3)
        elif kind == 'sleek':
            # pulled back off the face: a clean hairline with a soft peak in the middle, swept down to
            # the temples and over the tops of the ears, the lobes and her hoops left bare
            ok = z > hairline(x) or (f < 0.12 and z > -0.5)
            if abs(x) > 0.75 and -0.35 < z < 0.04 and f > -0.32:
                ok = False
        elif kind == 'centre':
            # parted in the middle and drawn back over the temples and the tops of the ears into
            # the braid: the lobes and what hangs from them left bare
            ok = z > hairline_c(x) or (f < 0.12 and z > -0.5) or (abs(x) > 0.7 and z > -0.08 and f < 0.4)
            if abs(x) > 0.72 and -0.42 < z < -0.08 and f > -0.3:
                ok = False
        elif kind == 'buzz':
            ok = (z > 0.5 - 0.6 * (1 - max(f, 0))) and not (f > 0.6 and z < 0.55)
        elif kind == 'thin':
            # a band round the back and over the ears, the top bald
            ok = -0.25 < z < 0.4 and f < 0.25
        elif kind == 'short':
            # cropped close under a cap: up from the nape to the cap's band, and over the temples
            # above the ears, a short sideburn in front of each, the ears left bare; the top is
            # under the cap and needs none
            ok = (f < 0.1 and -0.62 < z < 0.55) or (abs(x) > 0.76 and 0.1 < z < 0.55 and f < 0.52) \
                or (abs(x) > 0.84 and -0.22 < z < 0.12 and 0.1 < f < 0.36)
            if abs(x) > 0.8 and -0.34 < z < 0.1 and -0.14 < f < 0.1:
                ok = False
        else:
            ok = False
        if not ok:
            drop.append(v)
    bmesh.ops.delete(shell, geom=drop, context='VERTS')
    if fine:
        # the hairline drawn as its curve, not stepping from vertex to vertex of the egg
        line, scale = (hairline, sleek_scale) if kind == 'sleek' else (hairline_c, centre_scale)
        for v in shell.verts:
            if not any(e.is_boundary for e in v.link_edges):
                continue
            d = dirs[v]
            if -d.y < 0.15 or abs(d.x) > (0.8 if kind == 'sleek' else 0.68):
                continue
            z = line(d.x)
            f = math.sqrt(max(1.0 - d.x * d.x - z * z, 0.0))
            nd = Vector((d.x, -f, z)).normalized()
            v.co = egg_point(spec, nd) * scale(nd)
    if kind == 'bun':
        # a twisted bun at the back of the crown
        c = Vector((0, h['d'] * 0.95, h['h'] * 0.55))
        blob(shell, c, (0.042, 0.036, 0.04))
        torus(shell, c + Vector((0, 0.006, 0)), Vector((0, 1, 0.3)), 0.034, 0.012, 18, 6)
    if kind:
        parts.append(to_object(shell, f'{name}_hair', [hm], 0.006))
    else:
        shell.free()
    if kind == 'thin':
        # a few long hairs combed over the bald top, from the left side to the right
        bm = bmesh.new()
        for i in range(5):
            zz = 0.45 + i * 0.1
            pts = []
            for j in range(9):
                a = -1.0 + 2.0 * j / 8
                x = math.sin(a * 1.2) * 0.95
                zt = zz + (1 - zz) * (1 - abs(a)) * 0.9
                f = -0.25 + i * 0.12
                pts.append(Vector((x * h['w'] * 1.05, -f * h['d'] * 1.05, min(zt, 0.995) * h['h'] * 1.05)))
            tube(bm, curve(pts, 4), [0.0022] * len(curve(pts, 4)), 5)
        parts.append(to_object(bm, f'{name}_combover', [hm]))

    # a beard: a shell of the lower face with the mouth left showing
    if spec.get('beard'):
        _, bmat, *rest = spec['beard']
        sh = egg(spec)
        for v in sh.verts:
            v.co = v.co * (rest[0] if rest else 1.07)
        drop = []
        for v in sh.verts:
            x, f, z = v.co.x / h['w'], -v.co.y / h['d'], v.co.z / h['h']
            mouth = abs(x) < 0.3 and -0.7 < z < -0.42 and f > 0.4
            if not (z < -0.3 + 0.12 * (1 - max(f, 0)) and f > -0.3) or mouth:
                drop.append(v)
        bmesh.ops.delete(sh, geom=drop, context='VERTS')
        parts.append(to_object(sh, f'{name}_beard', [bmat], 0.006))

    # what's in the hair or the ears
    for thing in spec.get('things', []):
        if thing == 'pencil':
            # a pencil stuck through the bun
            c = Vector((0, h['d'] * 0.95, h['h'] * 0.55))
            a = Vector((1.0, 0.25, 0.55)).normalized()
            bm = bmesh.new()
            tube(bm, [c - a * 0.075, c + a * 0.06], [0.0045, 0.0045], 6)
            parts.append(to_object(bm, f'{name}_pencil', ['pencil']))
            bm = bmesh.new()
            tube(bm, [c + a * 0.06, c + a * 0.078, c + a * 0.082], [0.0045, 0.0012, 0.0003], 6)
            parts.append(to_object(bm, f'{name}_pencil_tip', ['pencil_wood']))
        elif thing == 'pencil_ear':
            # a pencil behind his right ear (-x): resting on the top of the ear where it meets the
            # head, the point just past the front of the ear, the rest of it back above the ear
            # (further forward, it crossed his temple like a scar)
            c = Vector((-h['w'] * 1.04, 0.01, h['h'] * 0.1))
            a = Vector((-0.06, -1.0, 0.12)).normalized()
            bm = bmesh.new()
            tube(bm, [c - a * 0.05, c + a * 0.028], [0.0042, 0.0042], 6)
            parts.append(to_object(bm, f'{name}_pencil', ['pencil']))
            bm = bmesh.new()
            tube(bm, [c + a * 0.028, c + a * 0.044, c + a * 0.048], [0.0042, 0.0011, 0.0003], 6)
            parts.append(to_object(bm, f'{name}_pencil_tip', ['pencil_wood']))
        elif thing == 'cap':
            # a ball cap, worn a little down in front: six panels gathered at a button, its band just
            # over the brows in front and low at the back, the front panels stiff and standing up a
            # little, a brim curved down at its sides, and a pale patch on the front for the print
            # to find from across the room
            def band(f):
                # the band's height, from the back (f -1) to the front (1): over the brows in front,
                # high enough that they show under the brim (lower, the brim hid them, and half of
                # what his face does with them)
                return 0.36 + 0.18 * f

            def k_at(d):
                f, z = -d.y, d.z
                return 1.085 + 0.03 * max(f, 0.0) * smoothstep(0.3, 0.9, z) + 0.008 * max(z - 0.55, 0.0)

            def on_cap(d, lift=0.0):
                d = d.normalized()
                return egg_point(spec, d) * (k_at(d) + lift)

            def at_band(d):
                # the direction whose height is the band's, round the head from d
                hor = Vector((d.x, d.y, 0.0))
                hor = hor.normalized() if hor.length > 1e-6 else Vector((0.0, -1.0, 0.0))
                zb = band(-hor.y)
                r = math.sqrt(max(1.0 - zb * zb, 0.0))
                return Vector((hor.x * r, hor.y * r, zb))

            def strap_hole(d):
                # the arch at the back above the strap, where the hair shows through
                x, f, z = d.x, -d.y, d.z
                return f < -0.6 and abs(x) < 0.24 and z < band(f) + 0.2 * (1.0 - (x / 0.24) ** 2)

            cdirs = {}
            cb = egg(spec, 72, 44, dirs=cdirs)
            drop = [v for v in cb.verts if cdirs[v].z < band(-cdirs[v].y) or strap_hole(cdirs[v])]
            bmesh.ops.delete(cb, geom=drop, context='VERTS')
            for v in cb.verts:
                d = cdirs[v]
                if any(e.is_boundary for e in v.link_edges) and d.z < band(-d.y) + 0.06 and not (-d.y < -0.55 and abs(d.x) < 0.3):
                    d = at_band(d)                 # the band's edge as its curve, not stepped
                v.co = on_cap(d)
            parts.append(to_object(cb, f'{name}_cap', ['cap_navy'], 0.004))

            # the button on top and the seams down from it between the panels
            bm = bmesh.new()
            top = on_cap(Vector((0.0, 0.0, 1.0)))
            blob(bm, top + Vector((0, 0, 0.003)), (0.0085, 0.0085, 0.0045), segs=12, rings=6)
            for deg in (30, 90, 150, 210, 270, 330):
                a = math.radians(deg)
                f0 = math.cos(a)
                pts = []
                for j in range(13):
                    t = j / 12
                    z = 0.985 - t * (0.985 - band(f0) - 0.01)
                    r = math.sqrt(max(1.0 - z * z, 0.0))
                    pts.append(on_cap(Vector((math.sin(a) * r, -math.cos(a) * r, z)), 0.004))
                tube(bm, pts, [0.0016] * len(pts), 5)
            parts.append(to_object(bm, f'{name}_cap_seams', ['cap_navy']))

            # the strap across the bottom of the arch at the back, and its buckle
            bm = bmesh.new()
            pts = []
            for j in range(9):
                x = -0.26 + 0.52 * j / 8
                hz = math.sqrt(max(1.0 - x * x - band(-0.97) ** 2, 0.0))
                pts.append(on_cap(Vector((x, hz, band(-0.97) + 0.02)), 0.002))
            tube(bm, pts, [0.004] * len(pts), 4)
            parts.append(to_object(bm, f'{name}_cap_strap', ['cap_navy']))
            bm = bmesh.new()
            blob(bm, pts[5] + Vector((0, 0.003, 0)), (0.007, 0.003, 0.005), segs=8, rings=6)
            parts.append(to_object(bm, f'{name}_cap_buckle', ['snap']))

            # the brim: out from the band across the forehead, its edge a D (deepest in the middle,
            # nothing at the ends, where it meets the band), its sides curved down, the whole of it
            # pitched a little down (squarer and steeper, it read as a bucket hat)
            bm = bmesh.new()
            nu, nv, reach = 20, 6, 0.07
            grid = []
            for i in range(nu + 1):
                u = -1.0 + 2.0 * i / nu
                a = u * 1.1
                root = on_cap(at_band(Vector((math.sin(a), -math.cos(a), 0.0)))) + Vector((0, 0, -0.002))
                out = Vector((math.sin(a) * 0.55, -1.0, 0.0)).normalized()
                row = []
                for j in range(nv + 1):
                    t = j / nv
                    p = root + out * (reach * math.sqrt(max(1.0 - u * u, 0.0)) * t) + Vector((0, 0, -(0.016 * u * u + 0.006) * t - 0.004 * t * t))
                    row.append(bm.verts.new(p))
                grid.append(row)
            for i in range(nu):
                for j in range(nv):
                    bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
            parts.append(to_object(bm, f'{name}_brim', ['cap_navy'], 0.006))

            # the patch on the front panels
            bm = bmesh.new()
            pu, pz = 8, 5
            fz = band(1.0)
            grid = []
            for i in range(pu + 1):
                a = -0.34 + 0.68 * i / pu
                row = []
                for j in range(pz + 1):
                    z = fz + 0.07 + 0.2 * j / pz
                    r = math.sqrt(max(1.0 - z * z, 0.0))
                    row.append(bm.verts.new(on_cap(Vector((math.sin(a) * r, -math.cos(a) * r, z)), 0.006)))
                grid.append(row)
            for i in range(pu):
                for j in range(pz):
                    bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
            parts.append(to_object(bm, f'{name}_cap_patch', ['cap_patch'], 0.002))
        elif thing == 'hoops':
            bm = bmesh.new()
            for sx in (-1, 1):
                torus(bm, Vector((sx * h['w'] * 1.03, 0.006, -0.058)), Vector((1, 0, 0)), 0.018, 0.0026, 24, 6)
            parts.append(to_object(bm, f'{name}_hoops', ['gold']))
        elif thing == 'pearls':
            # a pearl drop at each lobe on a short gold hook
            bm, hook = bmesh.new(), bmesh.new()
            for sx in (-1, 1):
                lobe = Vector((sx * h['w'] * 1.03, 0.007, -0.034))
                tube(hook, [lobe, lobe + Vector((0, 0, -0.011))], [0.0009, 0.0009], 5)
                blob(bm, lobe + Vector((0, 0, -0.018)), (0.0052, 0.0052, 0.0064), segs=12, rings=8)
            parts.append(to_object(hook, f'{name}_pearl_hooks', ['gold']))
            parts.append(to_object(bm, f'{name}_pearls', ['pearl']))
        elif thing == 'parted':
            # the comb's lines out from the part, over the head and back to where the braid's gathered;
            # the nearest the face run down over the temples and back above the ears
            bm = bmesh.new()
            g = Vector((0.0, 1.0, -0.12)).normalized()
            for sx in (-1, 1):
                for k, a in enumerate((0.0, 0.18, 0.4, 0.65, 0.95)):
                    z0 = hairline_c(0.05) + 0.03 + a * (0.98 - hairline_c(0.05))
                    f0 = math.sqrt(max(1.0 - 0.0025 - z0 * z0, 0.0)) * (1.0 - a * 0.6)
                    d0 = Vector((sx * 0.05, -f0, z0)).normalized()
                    bow = 0.55 * (1.0 - a * 0.7)
                    cp = []
                    for j in range(17):
                        t = j / 16
                        dd = d0.slerp(g, t) if d0.dot(g) > -0.99 else d0
                        dd = (dd + Vector((sx * bow * math.sin(math.pi * min(t * 1.15, 1.0)), 0, -0.08 * bow * math.sin(math.pi * t)))).normalized()
                        q = egg_point(spec, dd) * (centre_scale(dd) + 0.012)
                        cp.append(q)
                    tube(bm, cp, [0.0014] * len(cp), 5)
            parts.append(to_object(bm, f'{name}_combed', [hm]))
        elif thing == 'wisps':
            # strands come loose at her temples: a long one on her right, falling past her
            # cheekbone in an S and curling out at the jaw, a short one on her left
            bm = bmesh.new()
            for sx, ln in ((-1, 1.0), (1, 0.5)):
                pts = [Vector((sx * h['w'] * 0.66, -h['d'] * 0.66, h['h'] * 0.62)), Vector((sx * h['w'] * 0.84, -h['d'] * 0.62, h['h'] * 0.3)),
                       Vector((sx * h['w'] * 0.8, -h['d'] * 0.62, -h['h'] * 0.05)), Vector((sx * h['w'] * 0.9, -h['d'] * 0.56, -h['h'] * 0.4)),
                       Vector((sx * h['w'] * 0.82, -h['d'] * 0.66, -h['h'] * 0.68))]
                cp = curve(pts, 8)
                cp = cp[:max(int(len(cp) * ln), 4)]
                tube(bm, cp, [0.0036 * (1 - 0.75 * i / (len(cp) - 1)) for i in range(len(cp))], 6)
            parts.append(to_object(bm, f'{name}_wisps', [hm]))
        elif thing == 'combed':
            # the comb's lines, from the hairline back over the head to where the braid's gathered
            bm = bmesh.new()
            g = Vector((0.0, 1.0, -0.12)).normalized()
            for xi in (-0.62, -0.42, -0.22, 0.0, 0.22, 0.42, 0.62):
                zz = hairline(xi) + 0.07
                ff = math.sqrt(max(1.0 - xi * xi - zz * zz, 0.0))
                d0 = Vector((xi, -ff, zz)).normalized()
                cp = []
                for k in range(15):
                    t = k / 14
                    dd = d0.slerp(g, t) if d0.dot(g) > -0.99 else d0
                    # over the top, not through it: a great circle bowed up toward the crown
                    dd = (dd + Vector((0, 0, 0.35 * math.sin(math.pi * t)))).normalized()
                    q = egg_point(spec, dd)
                    q = q * (sleek_scale(dd) + 0.012)
                    cp.append(q)
                tube(bm, cp, [0.0014] * len(cp), 5)
            parts.append(to_object(bm, f'{name}_combed', [hm]))
    return parts


# ---------------------------------------------------------------- the braid

def braid(spec, name, arm, pts, head_at):
    """A braid on bones of its own (braid_00 to braid_08, the last only marks the end), hung from
    the back of the head down along the back, a hand's breadth off it at the shoulder blades and
    lying on it lower down, tied in red at the head and near the end."""
    h = spec['head']
    L = spec['braid']['length']
    n = spec['braid']['bones']
    g = Vector((0.0, head_at.y + h['d'] * 0.92, head_at.z - 0.012))
    skirt = spec.get('_skirt_back', [])

    def clear_of_skirt(z):
        # where a skirt stands off her, the braid lies on the skirt, not through it
        for (z0, y0), (z1, y1) in zip(skirt, skirt[1:]):
            if z1 <= z <= z0:
                return y0 + (y1 - y0) * (z0 - z) / max(z0 - z1, 1e-6) + 0.018
        return -1.0
    path = [g]
    for k in range(1, n + 1):
        z = g.z - L * k / n
        path.append(Vector((0.0, max(back_y(pts, z) + 0.032, g.y * (1 - k / n) + 0.04, clear_of_skirt(z)), z)))
    # its bones, hung from the head
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones
    prev = eb['Head']
    for k in range(n + 1):
        b = eb.new(f'braid_{k:02d}')
        b.head = path[k]
        b.tail = path[k + 1] if k < n else path[n] + (path[n] - path[n - 1]).normalized() * 0.04
        b.parent = prev
        b.use_connect = k > 0
        prev = b
    bpy.ops.object.mode_set(mode='OBJECT')

    # the braid: three strands over and under, lobes leaning one way and the other, thinning down
    seg = [(path[i + 1] - path[i]).length for i in range(n)]
    total = sum(seg)

    def at(s):
        for i in range(n):
            if s <= seg[i] or i == n - 1:
                t = min(s / seg[i], 1.0)
                return path[i].lerp(path[i + 1], t), (path[i + 1] - path[i]).normalized()
            s -= seg[i]
    bm = bmesh.new()
    s = 0.035
    i = 0
    end = total - 0.07
    while s < end:
        p, t = at(s)
        k = 1.0 - 0.35 * s / total
        side = 1 if i % 2 else -1
        tilt = Matrix.Rotation(side * 0.55, 4, t.cross(Vector((1, 0, 0))).normalized() if abs(t.x) < 0.9 else Vector((0, 1, 0)))
        look = t.to_track_quat('Z', 'Y').to_matrix().to_4x4()
        blob(bm, p + Vector((side * 0.007 * k, 0, 0)), (0.023 * k, 0.018 * k, 0.031 * k), tilt @ look, segs=12, rings=8)
        s += 0.03 * k
        i += 1
    # the end: a tuft below the tie
    p, t = at(end + 0.012)
    for j in range(5):
        a = (j - 2) * 0.22
        d = (t + Vector((math.sin(a) * 0.5, 0.02 * (j % 2), 0))).normalized()
        blob(bm, p + d * 0.04, (0.009, 0.007, 0.048), d.to_track_quat('Z', 'Y').to_matrix().to_4x4(), segs=8, rings=6)
    ob = to_object(bm, f'{name}_braid', [spec['hair'][1]])
    # each point moves with the bones it's between
    def weights(co):
        best, bi, bt = 1e9, 0, 0.0
        for i in range(n):
            a, b = path[i], path[i + 1]
            ab = b - a
            t = max(0.0, min(1.0, (co - a).dot(ab) / ab.length_squared))
            d = (a + ab * t - co).length
            if d < best:
                best, bi, bt = d, i, t
        out = {f'braid_{bi:02d}': 1.0 - bt}
        if bi + 1 < n:
            out[f'braid_{bi + 1:02d}'] = bt
        else:
            out[f'braid_{bi:02d}'] = 1.0
        return out
    parts = [skin_to(ob, arm, weights)]
    # the ties: one where it's gathered at her head, one near the end
    bm = bmesh.new()
    torus(bm, g + (path[1] - g).normalized() * 0.014, path[1] - g, 0.02, 0.0065, 16, 6)
    ob = to_object(bm, f'{name}_tie', ['tie_red'])
    parts.append(skin_to(ob, arm, lambda co: {'braid_00': 1.0}))
    bm = bmesh.new()
    p, t = at(end)
    torus(bm, p, t, 0.0135 * 0.68, 0.0045, 14, 6)
    ob = to_object(bm, f'{name}_tie_end', ['tie_red'])
    parts.append(skin_to(ob, arm, lambda co: {f'braid_{n - 1:02d}': 1.0}))
    return parts


def plaid_uvs(ob, arm, per=0.8):
    """A plaid's UVs: round the body and round each arm, in metres over per (the texture's width),
    so its checks run level and its seams fall where a shirt's do: down the back and under the
    arms."""
    me = ob.data
    if not me.uv_layers:
        return
    uv = me.uv_layers.active
    groups = {g.index: g.name for g in ob.vertex_groups}
    bones = arm.data.bones
    ay = bones['upperarm_l'].head_local.y
    az = bones['upperarm_l'].head_local.z
    for p in me.polygons:
        m = me.materials[p.material_index] if p.material_index < len(me.materials) else None
        if not m or m.name != 'flannel':
            continue
        w = {}
        for vi in p.vertices:
            for g in me.vertices[vi].groups:
                n = groups.get(g.group, '')
                w[n] = w.get(n, 0.0) + g.weight
        dom = max(w, key=w.get) if w else ''
        c = p.center
        arm_face = dom.startswith(('upperarm', 'lowerarm'))
        if arm_face:
            a0 = math.atan2(c.z - az, c.y - ay)
        else:
            a0 = math.atan2(c.x, -c.y)
        for li in p.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            if arm_face:
                a = a0 + math.remainder(math.atan2(co.z - az, co.y - ay) - a0, 2 * math.pi)
                uv.data[li].uv = (a * 0.055 / per, abs(co.x) / per)
            else:
                a = a0 + math.remainder(math.atan2(co.x, -co.y) - a0, 2 * math.pi)
                uv.data[li].uv = (a * 0.16 / per, co.z / per)


# ---------------------------------------------------------------- one person

def build(name):
    spec = PEOPLE[name]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(BASE, f"base_{spec['base']}.glb"))
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and (o.name.startswith(('Icosphere', 'Eyes', 'Eyebrows'))):
            bpy.data.objects.remove(o)
    bodyob = next(o for o in bpy.data.objects if o.type == 'MESH')
    bodyob.name = f'{name}_body'
    # where the mask's middle goes: above the head bone, whichever body
    head_at = Vector((0.0, 0.0, arm.data.bones['Head'].head_local.z + 0.088))
    pts = body(bodyob, arm, spec)
    dress(spec, name, bodyob, arm, pts)
    soles(spec, name, arm, pts)
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and any(m and m.name == 'flannel' for m in o.data.materials):
            plaid_uvs(o, arm)
    for p in head(spec, name):
        p.location = head_at
        on_bone(p, arm, 'Head')
    if spec.get('braid'):
        braid(spec, name, arm, pts, head_at)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f'{name}.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_animations=False, export_skins=True,
                              export_yup=True)
    print(f'{name}: {os.path.getsize(path) / 1e6:.2f} MB')


if __name__ == '__main__':
    who = [a for a in sys.argv[1:] if not a.startswith('-')] or list(PEOPLE)
    for n in who:
        build(n)
