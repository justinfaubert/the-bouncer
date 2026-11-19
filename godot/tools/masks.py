"""The people as masks (PROPOSED, Hutch's pick of 18 November 2026: "the masks are the better
approach, use that as a template and then each character gets its own unique spin").

Each person is the borrowed base body (models/quaternius/, CC0) on its borrowed skeleton, so the
animation library plays on all of them, made our own:

- the body smoothed (no superhero muscles) and pushed out where the person is (a belly, a bust,
  shoulders), their clothes painted on it by which bone each part of it follows;
- its head taken off and a mask head put on the head bone: an egg shaped by the person (the jaw,
  the chin, the crown, the cheeks), a nose of its own, ears, and hair as shells and lumps;
- the face drawn, not sculpted (tools/faces.py): a picture on the mask's front, swapped for its
  expressions and mouths as they talk.

The proportions (the big head, the squat body, the big hands) are put on the skeleton in the game
(game/masks.gd), so one model serves every clip.

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

# the base bodies face -y (Blender), z up; the head bone starts at about 1.60 m
FRONT = Vector((0.0, -1.0, 0.0))
HEAD_AT = Vector((0.0, 0.0, 1.69))      # where the mask head's middle goes, on the base body

COLOURS = {
    'skin': '#c7a38a', 'skin_pale': '#d9c0ae', 'skin_ruddy': '#c4927a', 'hair': '#3a2e26', 'hair_grey': '#6e7276',
    'hair_white': '#d2cec6', 'hair_dark': '#1f1a17', 'hair_red': '#8a4a2a', 'hair_rust': '#6e2c1c',
    'apron': '#29292a', 'shirt_dark': '#2c2c30', 'trousers': '#3b3a38', 'shoe': '#2a221c', 'sneaker': '#d8d3c8',
    'jacket': '#2d3a5a', 'jacket_trim': '#c4ad76', 'slacks': '#4a4540', 'flannel': '#7a3328', 'jeans': '#3a4557',
    'boot': '#3d2e24', 'blouse': '#e6e2d8', 'skirt': '#3e3a48', 'tights': '#2a2628', 'whites': '#e6e2d8',
}

# Who they are. body: the base and what's pushed out (bone, offset from it in metres: x to their
# left, f forward, z up; radius; how far); clothes: top (material, sleeves), bottom, shoes, apron;
# head: the egg (w, d, h half-sizes in metres), jaw (<1 narrower below), chin (forward), crown,
# cheeks; nose (kind, size); ears; hair (kind, material); beard.
PEOPLE = {
    # the lifer: slight and wiry, fifties, hair scraped back in a bun, a long face, a hard mouth
    'bartender': dict(
        base='female',
        body=[('spine_02', (0, 0.06, 0.02), 0.14, -0.012)],
        clothes=dict(top=('shirt_dark', 'rolled'), bottom='trousers', shoes='sneaker', apron='apron'),
        head=dict(w=0.088, d=0.105, h=0.135, jaw=0.78, chin=0.012, crown=0.95, cheeks=0.25),
        nose=('long', 1.0), ears=0.9, hair=('bun', 'hair_grey'), beard=None, skin='skin'),
    # table 28's loudest: old, a round belly under the same team jacket every day, a few hairs combed
    # over, a big soft drinker's face
    'team_jacket': dict(
        base='male',
        body=[('spine_01', (0, 0.13, -0.02), 0.2, 0.085), ('pelvis', (0, 0.1, 0.05), 0.16, 0.03),
              ('spine_03', (0, 0.05, 0), 0.16, -0.02)],
        clothes=dict(top=('jacket', 'long'), bottom='slacks', shoes='shoe'),
        head=dict(w=0.1, d=0.105, h=0.12, jaw=1.15, chin=-0.004, crown=0.85, cheeks=0.8),
        nose=('bulb', 1.25), ears=1.15, hair=('thin', 'hair_white'), beard=None, skin='skin_ruddy'),
    # at the pool table since before the shift: huge through the shoulders, a buzz cut, a beard, a
    # small head on a thick neck
    'bigman': dict(
        base='male',
        body=[('spine_03', (0, 0.02, 0.02), 0.2, 0.03), ('spine_01', (0, 0.1, 0), 0.18, 0.04)],
        clothes=dict(top=('flannel', 'rolled'), bottom='jeans', shoes='boot'),
        head=dict(w=0.092, d=0.1, h=0.11, jaw=1.2, chin=0.004, crown=0.8, cheeks=0.3),
        nose=('wedge', 1.1), ears=0.85, hair=('buzz', 'hair_dark'), beard=('full', 'hair_dark'), skin='skin'),
    # the new server: German, a fox's face (broad cheekbones narrowing to a small chin), rust hair
    # loose to her shoulders, quick
    'amanda': dict(
        base='female',
        body=[],
        clothes=dict(top=('blouse', 'short'), bottom='skirt', shoes='shoe', apron='apron', legs='tights'),
        head=dict(w=0.098, d=0.1, h=0.118, jaw=0.62, chin=0.016, crown=1.0, cheeks=0.55),
        nose=('button', 0.85), ears=0.8, hair=('long', 'hair_rust'), beard=None, skin='skin_pale'),
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


# ---------------------------------------------------------------- the body

def dominant(me, groups):
    """Each vertex's bone: the one that moves it most."""
    out = []
    for v in me.vertices:
        if not v.groups:
            out.append('')
            continue
        g = max(v.groups, key=lambda x: x.weight)
        out.append(groups[g.group])
    return out


def body(obj, arm, spec):
    me = obj.data
    groups = {g.index: g.name for g in obj.vertex_groups}
    dom = dominant(me, groups)
    bones = arm.data.bones

    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    deform = bm.verts.layers.deform.active
    # one skin: the import splits the mesh along its texture seams, and smoothing pulls the two sides
    # of a seam apart (cracks at the shoulders, the hips, the neck)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.verts.ensure_lookup_table()
    dom = [groups[max(v[deform].items(), key=lambda x: x[1])[0]] if v[deform] else '' for v in bm.verts]

    # the head goes: the mask sits on the neck
    gone = [bm.verts[i] for i, d in enumerate(dom) if d == 'Head' or (d == 'neck_01' and bm.verts[i].co.z > 1.585)]
    bmesh.ops.delete(bm, geom=gone, context='VERTS')
    bm.verts.ensure_lookup_table()
    dom = [groups[max(v[deform].items(), key=lambda x: x[1])[0]] if v[deform] else '' for v in bm.verts]

    # no superhero: the torso and limbs smoothed till the muscles go
    soft = [v for v, d in zip(bm.verts, dom) if d and not d.startswith(('hand', 'thumb', 'index', 'middle', 'ring', 'pinky', 'foot', 'ball', 'neck'))]
    for _ in range(14):
        bmesh.ops.smooth_vert(bm, verts=soft, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bm.normal_update()
    for v in soft:
        v.co += v.normal * 0.004

    # pushed out where the person is
    for bone, off, r, amt in spec['body']:
        c = bones[bone].head_local + Vector((off[0], -off[1], off[2]))
        for v in bm.verts:
            d = (v.co - c).length
            if d < r:
                k = 0.5 + 0.5 * math.cos(math.pi * d / r)
                v.co += v.normal * amt * k
    bm.normal_update()

    # the clothes, painted on by which bone each face follows and where it is
    cl = spec['clothes']
    names = ['skin', cl['top'][0], cl['bottom'], cl['shoes']]
    if cl.get('apron'):
        names.append(cl['apron'])
    if cl.get('legs'):
        names.append(cl['legs'])
    slot = {n: i for i, n in enumerate(dict.fromkeys(names))}
    me.materials.clear()
    for n in slot:
        me.materials.append(material(n))
    sleeves = cl['top'][1]
    elbow_z = bones['lowerarm_l'].head_local.z
    pelvis_z = bones['pelvis'].head_local.z
    for f in bm.faces:
        ds = [dom[v.index] for v in f.verts]
        d = max(set(ds), key=ds.count)
        c = f.calc_center_median()
        fwd = -c.y
        if d.startswith(('hand', 'thumb', 'index', 'middle', 'ring', 'pinky')):
            m = 'skin'
        elif d in ('neck_01',):
            m = 'skin'
        elif d.startswith(('foot', 'ball')):
            m = cl['shoes']
        elif d.startswith('lowerarm'):
            if sleeves == 'long':
                m = cl['top'][0]
            elif sleeves == 'rolled':
                # rolled to the elbow: the forearm bare past a hand's breadth from it
                m = cl['top'][0] if abs(c.x) < abs(bones['lowerarm_l'].head_local.x) + 0.07 else 'skin'
            else:
                m = 'skin'
        elif d.startswith('upperarm'):
            m = cl['top'][0] if sleeves != 'short' or abs(c.x) < abs(bones['upperarm_l'].head_local.x) + 0.08 else 'skin'
        elif d.startswith(('thigh', 'calf')):
            m = cl['bottom']
            if cl['bottom'] == 'skirt' and c.z < pelvis_z - 0.32:
                m = cl.get('legs', 'skin')
        elif d == 'pelvis':
            m = cl['bottom'] if c.z < pelvis_z + 0.04 else cl['top'][0]
        else:
            m = cl['top'][0]
        # an apron: the front from the chest to the knees
        if cl.get('apron') and fwd > 0.02 and pelvis_z - 0.45 < c.z < pelvis_z + 0.32 and abs(c.x) < 0.17 and not d.startswith(('hand', 'lowerarm', 'upperarm', 'thumb', 'index', 'middle', 'ring', 'pinky')):
            m = cl['apron']
        f.material_index = slot[m]
        f.smooth = True
    bm.to_mesh(me)
    bm.free()
    me.update()


# ---------------------------------------------------------------- the mask head

def egg(spec, segs=48, rings=32):
    """The head's shape as a function on the unit sphere: x to their left, f forward, z up."""
    h = spec['head']
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    for v in bm.verts:
        x, y, z = v.co
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
            f = 0.55 + (f - 0.55) * 0.6
        v.co = Vector((x * h['w'], -f * h['d'], z * h['h']))
    return bm


def blob(bm, at, size, rot=None, segs=16, rings=10):
    m = Matrix.Translation(at) @ (rot or Matrix.Identity(4)) @ Matrix.Diagonal((*size, 1.0))
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0, matrix=m)


def to_object(bm, name, mats, thick=0.0):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(material(m) if isinstance(m, str) else m)
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if thick:
        # a shell given a thickness, so it's solid seen from inside too (the print draws only the
        # side of a face that looks at us)
        mod = ob.modifiers.new('solid', 'SOLIDIFY')
        mod.thickness = thick
        mod.offset = -1.0
        mod.use_rim = True
        dg = bpy.context.evaluated_depsgraph_get()
        solid = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        ob.modifiers.clear()
        ob.data = solid
    return ob


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
    h = spec['head']
    skin = spec['skin']
    # the mask itself, its face drawn (material "face_<name>", the picture put on in the game)
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
        blob(bm, Vector((0, -front - 0.008 * s, fz + 0.012)), (0.011 * s, 0.016 * s, 0.034 * s),
             Matrix.Rotation(-0.35, 4, 'X'))
    elif kind == 'wedge':
        blob(bm, Vector((0, -front - 0.01 * s, fz + 0.01)), (0.016 * s, 0.018 * s, 0.03 * s),
             Matrix.Rotation(-0.25, 4, 'X'))
    else:  # button
        blob(bm, Vector((0, -front - 0.006 * s, fz)), (0.012 * s, 0.011 * s, 0.011 * s))
        blob(bm, Vector((0, -front + 0.002, fz + 0.016)), (0.006 * s, 0.008 * s, 0.018 * s))
    parts.append(to_object(bm, f'{name}_nose', [skin]))

    # the ears
    e = spec['ears']
    if e:
        bm = bmesh.new()
        for sx in (-1, 1):
            blob(bm, Vector((sx * h['w'] * 0.98, 0.004, -0.01)), (0.008 * e, 0.016 * e, 0.026 * e))
        parts.append(to_object(bm, f'{name}_ears', [skin]))

    # the hair: a shell of the egg a little out from it, cut to the hairline, and lumps
    kind, hm = spec['hair']
    shell = egg(spec)
    for v in shell.verts:
        v.co = v.co * 1.06
    keep = []
    for v in shell.verts:
        x, f, z = v.co.x / h['w'], -v.co.y / h['d'], v.co.z / h['h']
        if kind in ('bun', 'long'):
            ok = z > 0.42 - 0.25 * (1 - max(f, 0)) or (f < -0.1 and z > -0.55) or (abs(x) > 0.85 and z > -0.1 and f < 0.3)
            if kind == 'long':
                # swept from a side parting: the fringe low over her right eye, high over her left
                ok = (z > 0.36 - 0.25 * (1 - max(f, 0)) + 0.2 * x) or (f < -0.1 and z > -0.55) or (abs(x) > 0.85 and z > -0.1 and f < 0.3)
                ok = ok or (f < 0.3 and z > -0.5)
        elif kind == 'buzz':
            ok = (z > 0.5 - 0.6 * (1 - max(f, 0))) and not (f > 0.6 and z < 0.55)
        elif kind == 'thin':
            # a band round the back and over the ears, the top bald, a few hairs combed over
            ok = (-0.25 < z < 0.4 and f < 0.25) or (z > 0.86 and abs(x) < 0.5 and f < 0.4)
        else:
            ok = False
        if not ok:
            keep.append(v)
    bmesh.ops.delete(shell, geom=keep, context='VERTS')
    if kind == 'bun':
        blob(shell, Vector((0, h['d'] * 0.95, h['h'] * 0.55)), (0.045, 0.04, 0.042))
    parts.append(to_object(shell, f'{name}_hair', [hm], 0.006))
    if kind == 'long':
        # loose to the shoulders: a hood of hair behind the face, falling straight and a little out
        # below the ears, so from the front it frames her face down to her collarbones
        # (from the plain egg: her narrow jaw would pull the hair in behind her neck)
        back = egg(dict(spec, head=dict(h, jaw=1.0, cheeks=0.0, chin=0.0)))
        drop = []
        for v in back.verts:
            v.co = v.co * 1.1
            x, f, z = v.co.x / h['w'], -v.co.y / h['d'], v.co.z / h['h']
            if f > 0.35 - 0.1 * max(z, 0) or z < -0.92 or z > 0.7:
                drop.append(v)
        bmesh.ops.delete(back, geom=drop, context='VERTS')
        for v in back.verts:
            z = v.co.z / h['h']
            if z < 0.0:
                v.co.z = z * 2.0 * h['h']
                v.co.x *= 1.0 + 0.25 * -z
        parts.append(to_object(back, f'{name}_hair_back', [hm], 0.008))

    # a beard: a shell of the lower face with the mouth left showing
    if spec.get('beard'):
        _, bmat = spec['beard']
        sh = egg(spec)
        for v in sh.verts:
            v.co = v.co * 1.07
        drop = []
        for v in sh.verts:
            x, f, z = v.co.x / h['w'], -v.co.y / h['d'], v.co.z / h['h']
            mouth = abs(x) < 0.3 and -0.7 < z < -0.42 and f > 0.4
            if not (z < -0.3 + 0.12 * (1 - max(f, 0)) and f > -0.3) or mouth:
                drop.append(v)
        bmesh.ops.delete(sh, geom=drop, context='VERTS')
        parts.append(to_object(sh, f'{name}_beard', [bmat], 0.006))
    return parts


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
    body(bodyob, arm, spec)
    hb = arm.data.bones['Head']
    for p in head(spec, name):
        p.location = HEAD_AT
        bpy.context.view_layer.update()
        mw = p.matrix_world.copy()
        p.parent = arm
        p.parent_type = 'BONE'
        p.parent_bone = 'Head'
        bpy.context.view_layer.update()
        p.matrix_world = mw
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f'{name}.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_animations=False, export_skins=True,
                              export_yup=True)
    print(f'{name}: {os.path.getsize(path) / 1e6:.2f} MB')


if __name__ == '__main__':
    who = [a for a in sys.argv[1:] if not a.startswith('-')] or list(PEOPLE)
    for n in who:
        build(n)
