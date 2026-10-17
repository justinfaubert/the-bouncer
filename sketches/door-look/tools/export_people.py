"""Meshes the people (tools/people.py) and exports each as a .glb in models/people/, with Blender.

  python3 tools/export_people.py              every one
  python3 tools/export_people.py hoodie_door  just one
  python3 tools/export_people.py --preview    also render a grey preview of each to models/people/previews/

Godot swaps the materials for its print shader by name, keeping their colour.
"""
import os
import sys
import time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import people as PP  # noqa: E402

OUT = os.path.join(HERE, '..', 'models', 'people')

# base colours, by material name (sRGB hex)
COLOURS = {
    'skin': '#c7a38a', 'hair': '#3a2e26', 'eye': '#d2c6b2', 'iris': '#1d1a19', 'stubble': '#a2826f', 'earbud': '#efefea',
    'hoodie': '#3d3c3b', 'cord': '#d6d2c8', 'jeans': '#3a4557', 'shoe': '#d8d3c8', 'sole': '#ece6da',
    'flannel': '#7a3b30', 'jacket': '#2d3a5a', 'jacket_trim': '#c4ad76', 'coat': '#5a5445', 'cardigan': '#7a6850',
    'whites': '#e6e2d8', 'suit': '#34373e', 'tshirt': '#6b6d72', 'sweatshirt': '#45474b', 'hivis': '#d4e43c',
    'reflective': '#d0d3d5', 'apron': '#29292a', 'shirt_dark': '#2c2c30', 'cap': '#27324a', 'glasses': '#1b1b1b',
    'button': '#c8c0b0', 'tweed': '#5d4b37', 'slipper': '#b48a8e', 'boot': '#3d2e24', 'boot_sole': '#1f1a17',
    'slacks': '#4a4540', 'khaki': '#7a6f58', 'phone': '#121214', 'screen': '#e6eefc', 'phone_screen': '#e6eefc', 'cue': '#b58f5c', 'trousers': '#3b3a38',
    # clothes added with the new figures
    'raincoat': '#b5ab90', 'sweater': '#5d6b5a', 'denim': '#56708f', 'fleece': '#4b5866', 'workjacket': '#6e5d3e',
    'shirt': '#cfd3d6', 'shirt_white': '#e8e6e0', 'tie': '#5e2b2e', 'belt': '#2a221c', 'buckle': '#b9b1a1', 'zip': '#8d8d8d',
    'dress_shoe': '#211915', 'cardigan_b': '#6c7b8e', 'cardigan_c': '#8e5f5a', 'slipper_b': '#5e6f8c', 'skirt': '#3e3a48',
    'hair_grey': '#9c9892', 'hair_white': '#d2cec6', 'hair_blonde': '#a88d5e', 'hair_red': '#7a4128', 'hair_dark': '#1f1a17',
    'jeans_black': '#26272b', 'jeans_light': '#6f86a3',
    # things they hold
    'glass': '#d9e3e1', 'beer': '#b2761e', 'foam': '#efe6cf', 'wine': '#5c1626', 'cola': '#2b160d',
    'card': '#e9e5db', 'card_back': '#d6d1c4', 'chrome': '#c9ccd0', 'black': '#18181a', 'vape': '#3b3e45',
    'cardboard': '#9b784b', 'clicker_window': '#e4e0d4', 'doorman_jacket': '#25272b',
    # the constable's duty jacket, its collar, cuffs and band a shade darker
    'uniform': '#1d2330', 'uniform_trim': '#121620',
    # the night clerk's lanyard and key card, and his shirt: a blue flannel, not the big man's red
    'lanyard': '#2b3446', 'badge': '#e2ddd0', 'flannel_b': '#4a5768',
}
ROUGH = {'phone': 0.3, 'screen': 0.2, 'eye': 0.25, 'iris': 0.25, 'earbud': 0.3, 'glasses': 0.3, 'reflective': 0.4, 'cue': 0.4,
         'glass': 0.05, 'beer': 0.2, 'wine': 0.2, 'cola': 0.2, 'chrome': 0.25, 'vape': 0.35, 'card': 0.4, 'clicker_window': 0.3}
METAL = {'chrome': 1.0, 'buckle': 0.8, 'zip': 0.7, 'vape': 0.6}

KID = dict(age='young', build='slight', hat='hood', top='hoodie', face=['earbuds'], hair='messy',
           shoulders=0.86, chest=0.84, drape=True)
GOODSHOES = dict(hair='parted', top='suit', mood='smile', shoe_mat='dress_shoe', shoes='dress')
DRIVER = dict(sex='f', age='young', hair='ponytail', top='jacket')
VAPE = dict(age='young', hair='messy', top='hoodie')
HIVIS = dict(hat='cap', top='hivis', face=['stubble'])

# who, in what pose, how finely (metres per voxel for the body)
PEOPLE = {
    # the kid: slight, hunched against the rain, the hoodie hanging off him
    'hoodie_door': (KID, 'phone_out', dict(hunch=1.0), 0.008),
    'hoodie_lot': (KID, 'walk_pouch', dict(hunch=1.0), 0.011),
    'team_jacket': (dict(age='old', hair='thin', top='jacket'), 'sit', dict(lean=0.3), 0.012),
    'hearing_aid': (dict(age='old', hair='bald', top='flannel', face=['hearingaid'], bulk=1.1, bottoms='khaki'), 'sit', dict(lean=0.15, head_turn=0.4), 0.012),
    'scratch': (dict(age='old', hat='cap', top='coat', face=['stubble']), 'sit', dict(lean=0.35, head_tilt=0.3), 0.012),
    'cardigan': (dict(age='old', hair='parted', top='cardigan', build='slight', bottoms='slacks'), 'sit', dict(lean=0.05, slump=0.03), 0.012),
    'glasses': (dict(age='old', hair='short', top='tshirt', face=['glasses', 'moustache'], bulk=1.15),
                'sit', dict(lean=0.2, head_turn=-0.5, hands=[(-0.14, 0.42, 0.83), (0.2, 0.3, 1.22)]), 0.012),
    'bigman': (dict(build='big', hair='buzz', face=['beard'], top='flannel', sleeves='rolled'), 'cue', dict(left_handed=True), 0.012),
    'buddy': (dict(build='slight', hair='short', top='tshirt', hat='cap', size=0.94), 'stand', dict(head_turn=0.3), 0.012),
    'bartender': (dict(build='slight', sex='f', hair='bun', face=['lined'], top='apron', age='old', bottoms='trousers', shoes='sneakers'), 'bar', dict(top=1.1), 0.012),
    'hivis': (dict(HIVIS), 'sit', dict(seat=0.76, table=1.08, lean=0.3), 0.012),
    'endbar': (dict(age='old', hat='flatcap', face=['lined'], top='tweed', build='slight', bottoms='slacks'),
               'sit', dict(seat=0.76, table=1.08, lean=0.12, head_turn=0.5), 0.012),
    'crew_a': (dict(top='hivis', hat='beanie', face=['beard'], bulk=1.05), 'sit', dict(lean=0.3, head_turn=0.3), 0.012),
    'crew_b': (dict(build='big', top='flannel', hat='cap', face=['stubble']), 'sit', dict(lean=0.2, head_turn=-0.4), 0.012),
    # in the truck, placed in its frame by main.gd: the sister at the wheel, looking at her phone;
    # her boyfriend slumped in the back
    'driver': (DRIVER, 'sit', dict(seat=0.98, feet='floor', floor=0.62, reach=0.5, lean=0.08, head_tilt=0.4,
                                   hands=[(-0.17, 0.5, 1.4), (0.05, 0.3, 1.3)], palms=[(0.3, 0, -1), (-0.1, -0.6, 0.8)], phone=1), 0.012),
    'vape': (VAPE, 'sit', dict(seat=0.98, feet='floor', floor=0.62, reach=0.55, lean=-0.3, head_roll=0.35, head_tilt=-0.1,
                               hands=[(-0.2, 0.18, 1.05), (0.2, 0.22, 1.08)]), 0.012),
    'slippers': (dict(sex='f', age='old', hair='bun', top='cardigan', bottoms='trousers', shoes='slippers', bulk=1.1),
                 'reach', dict(), 0.012),
    # --- new
    # the cook at the pass, tired, his weight on his hand
    'cook': (dict(hair='short', face=['stubble'], top='tshirt', bulk=1.08, bottoms='jeans_black', gaunt=0.55), 'counter', dict(head_tilt=0.12), 0.012),
    # GOOD SHOES: at the stool holding his licence out at chest height; then at the bar with a soda
    'goodshoes_card': (GOODSHOES, 'card', dict(height=1.26, face=(-0.1, 0.9, 0.42)), 0.008),
    'goodshoes_bar': (GOODSHOES, 'sit_drink', dict(kind='tumbler', lean=0.1, head_turn=0.3), 0.012),
    # Glasses' wife, wet, looking for him: her coat held closed at the throat, the car keys in that fist
    'raincoat': (dict(sex='f', age='old', hair='bob', hair_mat='hair_grey', top='raincoat', face=['lined'], bottoms='slacks',
                      shoes='boots', build='slight'), 'close', dict(keys=1, head_turn=0.25), 0.01),
    # regulars
    'patron_a': (dict(hair='short', face=['beard'], top='flannel', bulk=1.05, hair_mat='hair_red', beard_mat='hair_red'),
                 'sit', dict(hold=('pint', 1), lean=0.18, head_turn=-0.3), 0.012),
    'patron_b': (dict(sex='f', hair='long', hair_mat='hair_blonde', top='sweater', bottoms='jeans'), 'sit', dict(lean=0.25, head_turn=0.4), 0.012),
    'patron_c': (dict(age='old', build='big', hair='bald', top='workjacket', face=['moustache'], bottoms='khaki', shoes='boots'),
                 'pint', dict(side=1, head_turn=0.2), 0.012),
    'patron_d': (dict(sex='f', age='young', build='slight', hair='ponytail', hair_mat='hair_dark', top='denim', bottoms='jeans_black'),
                 'pint', dict(side=-1, head_turn=-0.3), 0.012),
    'patron_e': (dict(age='old', build='slight', hat='beanie', top='fleece', face=['stubble'], bottoms='jeans_light'),
                 'sit_drink', dict(kind='pint', lean=0.15, head_tilt=0.1), 0.012),
    'patron_f': (dict(sex='f', age='old', build='big', hair='short', hair_mat='hair_white', top='sweater', top_mat='cardigan_c', bottoms='slacks'),
                 'sit', dict(hold=('pint', 0), lean=0.2, head_turn=0.3), 0.012),
    # the sister: at the stool with her licence up at eye level and the keys in her fist; then at the rail
    'driver_door': (DRIVER, 'card', dict(height=1.5, face=(-0.05, 1.0, 0.12), keys_other=True), 0.008),
    'driver_rail': (DRIVER, 'close', dict(keys=1, fist_z=-0.24, head_turn=-0.3), 0.012),
    # her boyfriend: holding the door open with his shoulder, the vape up; then leaning on the bar
    'vape_door': (VAPE, 'door', dict(), 0.01),
    'vape_bar': (VAPE, 'bar_lean', dict(head_turn=0.45), 0.012),
    # the kid at the jukebox, hood up, hands in the pouch, looking at the screen
    'hoodie_juke': (KID, 'pouch', dict(hunch=0.6, head_tilt=0.18), 0.011),
    # HI-VIS at the stool with a two-four under his arm
    'hivis_door': (dict(HIVIS), 'carry', dict(head_tilt=0.05), 0.008),
    # the two women from upstairs on bar stools, in cardigans and slippers
    'slippers_a': (dict(sex='f', age='old', hair='bun', hair_mat='hair_grey', top='cardigan', bottoms='trousers', shoes='slippers',
                        bulk=1.12), 'sit_drink', dict(kind='wine', i=1, lean=0.12, head_turn=0.35), 0.012),
    'slippers_b': (dict(sex='f', age='old', build='slight', hair='bob', hair_mat='hair_white', top='cardigan', top_mat='cardigan_b',
                        bottoms='skirt', shoes='slippers', shoe_mat='slipper_b', glasses=True, face=['glasses']),
                   'sit', dict(seat=0.76, table=1.08, lean=0.15, head_turn=-0.4), 0.012),
    # the constable from the detachment in town, forty minutes after the call: her cap on in the
    # rain, the duty jacket with its band, standing just inside the door looking at the room
    'constable': (dict(sex='f', hair='bun', hat='cap', top='jacket', top_mat='uniform', trim_mat='uniform_trim',
                       bottoms='trousers', shoes='boots'), 'stand', dict(head_turn=0.2), 0.008),
    # Terry, the night clerk, on his stool behind the front desk with his chin on his fist, watching
    # the bar's TV down the back hall through the gap he props the door open for
    'terry': (dict(build='slight', hair='thin', face=['glasses'], top='flannel', top_mat='flannel_b', trim_mat='flannel_b',
                   extra=['lanyard'], bottoms='slacks'), 'chin', dict(head_tilt=0.08), 0.008),
}
# figures seen close (at the stool): finer meshes and more faces
NEAR = {'hoodie_door', 'goodshoes_card', 'driver_door', 'hivis_door', 'raincoat', 'vape_door', 'constable', 'terry'}


def make(name, look, pose, kw, step, near):
    """A person meshed into Blender (an empty scene each time): the parts' objects (body, head,
    hands), the things they hold, the build and the pose, and how many faces each part came to."""
    import bpy
    meshes = PP.mesh_person(look, pose, step=step, head_step=0.0028 if near else 0.005,
                            hand_step=0.0022 if near else 0.0045, **kw)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # how many faces each part keeps: the people at the stool are seen at arm's length
    targets = {'body': 36000 if near else 12000, 'head': 32000 if near else 7000, 'hands': 16000 if near else 2400}
    obs, report = [], []
    for part, verts, faces, mat, names in meshes:
        me = bpy.data.meshes.new(f'{name}_{part}')
        me.from_pydata(verts.tolist(), [], faces.tolist())
        me.update()
        ob = bpy.data.objects.new(f'{name}_{part}', me)
        bpy.context.scene.collection.objects.link(ob)
        for n in names:
            me.materials.append(material(n))
        me.polygons.foreach_set('material_index', mat.tolist())
        me.validate(verbose=False)
        me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
        me.update()
        n0 = len(me.polygons)
        for o in bpy.context.selected_objects:
            o.select_set(False)
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        if n0 > targets[part]:
            dec = ob.modifiers.new('decimate', 'DECIMATE')
            dec.ratio = targets[part] / n0
            bpy.ops.object.modifier_apply(modifier='decimate')
        report.append(f'{part} {n0} -> {len(ob.data.polygons)}')
        obs.append(ob)
    B, p, _ = PP.person(look, pose, **kw)
    extras = []
    for pr in p.props:
        extras += PROPS[pr['kind']](pr)
    return obs, extras, B, p, report


def build(name, preview=False):
    import bpy
    import json
    look, pose, kw, step = PEOPLE[name]
    t0 = time.time()
    obs, extras, B, p, report = make(name, look, pose, kw, step, name in NEAR)
    t1 = time.time()
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + '.glb')
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in obs + extras:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True,
                              export_yup=True)
    nf = sum(len(o.data.polygons) for o in obs + extras)
    print(f'{name}: {", ".join(report)} faces ({nf} in all, {os.path.getsize(path) / 1e6:.2f} MB), '
          f'made in {t1 - t0:.1f}s, total {time.time() - t0:.1f}s')
    with open(os.path.join(OUT, name + '.json'), 'w') as fh:
        json.dump(anchors(B, p), fh, indent=1)
    if preview:
        render_preview(obs + extras, os.path.join(OUT, 'previews', name + '.png'))
    if '--face' in sys.argv:
        render_preview(obs + extras, os.path.join(OUT, 'previews', name + '-face.png'), views=((0.0, 'front'), (0.7, 'three-quarter'), (0.35, 'near')),
                       focus=(tuple(p.head + np.array([0, 0.02, -0.02])), 0.34))
    if '--hands' in sys.argv:
        for i, h in enumerate(p.hands):
            if h is not None:
                c = h.w((0.0, 0.07, 0.01))
                render_preview(obs + extras, os.path.join(OUT, 'previews', f'{name}-hand{"LR"[i]}.png'),
                               views=((0.0, 'front', 0.3), (1.2, 'side', 0.3)), focus=(tuple(c), 0.2))


def anchors(B, p):
    """Where things are on them, for Godot (its axes: x, z, -y): the head, the eyes, the chest, the
    hands (their wrists), and what they hold: the phone and the card (their middles and which way
    their faces look), the glass, the keys; and what they lean on."""
    g = lambda v: [round(float(v[0]), 4), round(float(v[2]), 4), round(float(-v[1]), 4)]
    a = {'head': g(p.head), 'eyes': g(PP.eyes_at(B, p)), 'chest': g(p.chest + p.R @ PP.V(0, 0.1 * B.bulk, 0.0)),
         'hand_left': g(p.wrist[0]), 'hand_right': g(p.wrist[1])}
    for pr in p.props:
        k = pr['kind']
        if k in ('phone', 'card'):
            a[k] = g(pr['at'])
            a[k + '_facing'] = g(pr['R'][:, 2])
            a[k + '_up'] = g(pr['R'][:, 1])
        elif k in PP.GLASSES:
            a['glass'] = g(pr['at'])
        else:
            a[k] = g(pr['at'])
    for k in ('door', 'bar', 'counter'):
        if hasattr(p, k):
            a[k] = g(getattr(p, k))
    return a


def material(name):
    import bpy
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    h = COLOURS.get(name, '#808080').lstrip('#')
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    lin = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*lin, 1.0)
    bsdf.inputs['Roughness'].default_value = ROUGH.get(name, 0.85)
    bsdf.inputs['Metallic'].default_value = METAL.get(name, 0.0)
    if name in ('screen', 'phone_screen'):
        bsdf.inputs['Emission Color'].default_value = (*lin, 1.0)
        bsdf.inputs['Emission Strength'].default_value = 1.0
    if name == 'glass':
        bsdf.inputs['Alpha'].default_value = 0.25
        try:
            m.surface_render_method = 'BLENDED'
        except AttributeError:
            m.blend_method = 'BLEND'
    return m


def _place(obs, c, R):
    """Move objects made about the origin to c, turned by R (its columns: the local axes)."""
    import mathutils
    M = mathutils.Matrix(np.asarray(R, dtype=float).tolist()).to_4x4()
    M.translation = mathutils.Vector([float(x) for x in c])
    for o in obs:
        o.matrix_world = M @ o.matrix_world
    return obs


def _box(name, mat, half, at=(0, 0, 0), bevel=0.0, segments=2):
    import bpy
    bpy.ops.mesh.primitive_cube_add(size=2.0)
    o = bpy.context.active_object
    o.name = o.data.name = name
    o.scale = tuple(float(x) for x in half)
    bpy.ops.object.transform_apply(scale=True)
    o.location = tuple(float(x) for x in at)
    bpy.ops.object.transform_apply(location=True)
    if bevel > 0:
        bev = o.modifiers.new('bevel', 'BEVEL')
        bev.width = bevel
        bev.segments = segments
    o.data.materials.append(material(mat))
    return o


def _plane(name, mat, half, z):
    """A face of its own with UVs over it (0..1 left to right, bottom to top, seen from +z)."""
    import bpy
    bpy.ops.mesh.primitive_plane_add(size=2.0)
    o = bpy.context.active_object
    o.name = o.data.name = name
    o.scale = (float(half[0]), float(half[1]), 1.0)
    bpy.ops.object.transform_apply(scale=True)
    o.location = (0, 0, float(z))
    bpy.ops.object.transform_apply(location=True)
    o.data.materials.append(material(mat))
    return o


def _lathe(name, mat, profile, segs=28):
    """A solid of revolution about z from a list of (radius, height), bottom to top, capped."""
    import bpy
    verts, faces = [], []
    for r, z in profile:
        for k in range(segs):
            a = 2 * np.pi * k / segs
            verts.append((r * np.cos(a), r * np.sin(a), z))
    n = len(profile)
    for j in range(n - 1):
        for k in range(segs):
            a0, a1 = j * segs + k, j * segs + (k + 1) % segs
            faces.append((a0, a1, a1 + segs, a0 + segs))
    verts.append((0, 0, profile[0][1]))
    verts.append((0, 0, profile[-1][1]))
    cb, ct = len(verts) - 2, len(verts) - 1
    for k in range(segs):
        faces.append((cb, (k + 1) % segs, k))
        faces.append((ct, (n - 1) * segs + k, (n - 1) * segs + (k + 1) % segs))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    me.materials.append(material(mat))
    me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
    return o


def phone(pr):
    """The phone in a hand: a bevelled slab, and its screen as a face of its own with UVs, so
    Godot can show the licence photo on it."""
    body = _box('phone', 'phone', (0.036, 0.076, 0.00425), bevel=0.004, segments=3)
    scr = _plane('phone_screen', 'phone_screen', (0.032, 0.07), 0.0044)
    return _place([body, scr], pr['at'], pr['R'])


def card(pr):
    """A licence (86 x 54 mm): its face a face of its own with UVs, 'card', over a thin body."""
    w, h, t = PP.CARD
    body = _box('card_body', 'card_back', (w / 2, h / 2, t / 2), bevel=0.0003, segments=1)
    face = _plane('card', 'card', (w / 2 - 0.0002, h / 2 - 0.0002), t / 2 + 0.00015)
    return _place([body, face], pr['at'], pr['R'])


def lanyard(pr):
    """A lanyard: a flat strap from each side of the neck down to the clip, and the key card
    hanging off it, its face forward."""
    obs = []
    for k, (a, b) in enumerate(pr['straps']):
        a, b = np.asarray(a, dtype=float), np.asarray(b, dtype=float)
        z = (b - a) / np.linalg.norm(b - a)
        x = np.cross(z, np.array([0.0, 1.0, 0.0]))
        x = x / (np.linalg.norm(x) + 1e-9)
        y = np.cross(z, x)
        R = np.stack([x, y, z], axis=1)
        st = _box(f'lanyard_strap_{k}', 'lanyard', (0.0055, 0.0009, np.linalg.norm(b - a) / 2 + 0.003))
        obs += _place([st], (a + b) / 2, R)
    clip = _box('lanyard_clip', 'chrome', (0.005, 0.004, 0.008), bevel=0.0015)
    badge = _box('badge', 'badge', (0.027, 0.043, 0.0009), at=(0, -0.05, 0), bevel=0.0012)
    band = _box('badge_band', 'lanyard', (0.0272, 0.009, 0.001), at=(0, -0.017, 0))
    obs += _place([clip, badge, band], pr['at'], pr['R'])
    return obs


def glass(pr):
    """A glass on its foot at `at`, and what's in it. A pint and a tumbler taper out to the lip; a
    wine glass is a bowl on a stem."""
    kind = pr['kind']
    fill = pr.get('fill', 0.9)
    if kind == 'wine':
        w = PP.WINE
        rx, rz = w['bowl']
        prof = [(w['foot'], 0.0), (w['foot'], 0.003), (w['stem_r'] * 1.6, 0.006), (w['stem_r'], 0.012), (w['stem_r'], w['stem']),
                (w['stem_r'] * 2.2, w['stem'] + 0.006)]
        for t in np.linspace(-0.82, 1.0, 12)[1:]:
            z = w['bowl_c'] + t * rz
            if z > w['lip']:
                break
            prof.append((rx * float(np.sqrt(max(1 - t * t, 0.0))), z))
        prof.append((PP.glass_r('wine', w['lip']), w['lip']))
        gl = _lathe(kind, 'glass', prof)
        top = w['bowl_c'] + 0.2 * rz
        liq = [(0.001, w['stem'] + 0.012)]
        for t in np.linspace(-0.7, 0.2, 7):
            liq.append((rx * float(np.sqrt(1 - t * t)) - 0.002, w['bowl_c'] + t * rz))
        obs = [gl, _lathe(kind + '_wine', 'wine', liq)]
    else:
        r0, r1, hg = PP.GLASSES[kind]
        prof = [(r0 - 0.002, 0.0), (r0, 0.003), (r1, hg)]
        gl = _lathe(kind, 'glass', prof)
        lz = hg * fill * (0.88 if kind == 'pint' else 0.6)
        base = 0.012
        liquid = 'beer' if kind == 'pint' else 'cola'
        rl = lambda z: r0 + (r1 - r0) * z / hg - 0.0022
        obs = [gl, _lathe(kind + '_' + liquid, liquid, [(rl(base), base), (rl(lz), lz)])]
        if kind == 'pint':
            obs.append(_lathe(kind + '_foam', 'foam', [(rl(lz), lz - 0.001), (rl(lz + 0.012), lz + 0.012)]))
    return _place(obs, pr['at'], pr['R'])


def keys(pr):
    """Car keys hanging out of a fist: the ring, a fob and a key."""
    import bpy
    bpy.ops.mesh.primitive_torus_add(major_radius=0.012, minor_radius=0.0014, major_segments=20, minor_segments=6)
    ring = bpy.context.active_object
    ring.name = 'keys'
    ring.rotation_euler = (0, np.pi / 2, 0)
    bpy.ops.object.transform_apply(rotation=True)
    ring.data.materials.append(material('chrome'))
    fob = _box('keys_fob', 'black', (0.0075, 0.03, 0.016), at=(0.0, -0.045, 0.004), bevel=0.006, segments=3)
    blade = _box('keys_key', 'chrome', (0.0012, 0.028, 0.0075), at=(0.0, -0.05, -0.012), bevel=0.001, segments=1)
    head = _box('keys_head', 'black', (0.0035, 0.012, 0.012), at=(0.0, -0.022, -0.012), bevel=0.003, segments=2)
    return _place([ring, fob, blade, head], pr['at'], pr['R'])


def vape(pr):
    """A pen of a vape: a metal tube with a dark mouthpiece."""
    import bpy
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.0078, depth=0.1)
    o = bpy.context.active_object
    o.name = 'vape'
    o.rotation_euler = (-np.pi / 2, 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    o.data.materials.append(material('vape'))
    bev = o.modifiers.new('bevel', 'BEVEL')
    bev.width = 0.002
    bev.segments = 2
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.0062, depth=0.018)
    tip = bpy.context.active_object
    tip.name = 'vape_tip'
    tip.rotation_euler = (-np.pi / 2, 0, 0)
    tip.location = (0, 0.057, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True)
    tip.data.materials.append(material('black'))
    return _place([o, tip], pr['at'], pr['R'])


def case(pr):
    """A two-four: a cardboard case of beer, bevelled a little."""
    o = _box('case', 'cardboard', pr['half'], bevel=0.004, segments=2)
    return _place([o], pr['at'], pr['R'])


def clicker(pr):
    """The tally counter: a chrome disc with the button on top, a small knob on its side, and the
    count window on its face as an object of its own with UVs, 'clicker_window'."""
    import bpy
    r, t = PP.CLICKER['r'], PP.CLICKER['t']
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r, depth=t)
    body = bpy.context.active_object
    body.name = body.data.name = 'clicker'
    bev = body.modifiers.new('bevel', 'BEVEL')
    bev.width = 0.004
    bev.segments = 3
    body.data.materials.append(material('chrome'))
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.0055, depth=0.012, location=(0, r + 0.004, 0), rotation=(np.pi / 2, 0, 0))
    btn = bpy.context.active_object
    btn.name = btn.data.name = 'clicker_button'
    btn.data.materials.append(material('chrome'))
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.004, depth=0.008, location=(r + 0.003, 0.004, 0), rotation=(0, np.pi / 2, 0))
    knob = bpy.context.active_object
    knob.name = knob.data.name = 'clicker_knob'
    knob.data.materials.append(material('chrome'))
    bpy.ops.object.select_all(action='DESELECT')
    win = _plane('clicker_window', 'clicker_window', (0.011, 0.0045), t / 2 + 0.0003)
    win.location = (0, 0.006, 0)
    bpy.ops.object.transform_apply(location=True)
    return _place([body, btn, knob, win], pr['at'], pr['R'])


PROPS = {'clicker': clicker, 'phone': phone, 'card': card, 'lanyard': lanyard, 'pint': glass, 'tumbler': glass, 'wine': glass, 'keys': keys, 'vape': vape,
         'case': case}


def render_preview(obs, path, views=((0.0, 'front'), (0.6, 'three-quarter')), focus=None):
    import bpy
    import mathutils
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 24
    sc.cycles.device = 'CPU'
    sc.render.resolution_x, sc.render.resolution_y = 700, 900
    sc.render.film_transparent = False
    world = bpy.data.worlds.new('w')
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.05, 0.05, 0.06, 1)
    sc.world = world
    # clay: override every material with plain grey, keeping the tone of the colour
    bb = [o.matrix_world @ mathutils.Vector(c) for o in obs for c in o.bound_box]
    lo = mathutils.Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
    hi = mathutils.Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
    ctr = (lo + hi) / 2
    size = max(hi - lo)
    if focus is not None:
        ctr = mathutils.Vector(focus[0])
        size = focus[1]
    key = bpy.data.lights.new('key', 'AREA')
    key.energy = 400 * size * size
    key.size = size
    kob = bpy.data.objects.new('key', key)
    kob.location = ctr + mathutils.Vector((size * 0.9, size * 1.2, size * 0.9))
    kob.rotation_euler = (ctr - kob.location).to_track_quat('-Z', 'Y').to_euler()
    sc.collection.objects.link(kob)
    fill = bpy.data.lights.new('fill', 'AREA')
    fill.energy = 120 * size * size
    fill.size = size * 2
    fob = bpy.data.objects.new('fill', fill)
    fob.location = ctr + mathutils.Vector((-size * 1.2, size * 0.8, size * 0.2))
    fob.rotation_euler = (ctr - fob.location).to_track_quat('-Z', 'Y').to_euler()
    sc.collection.objects.link(fob)
    cam = bpy.data.cameras.new('cam')
    cam.lens = 70
    cob = bpy.data.objects.new('cam', cam)
    sc.collection.objects.link(cob)
    sc.camera = cob
    os.makedirs(os.path.dirname(path), exist_ok=True)
    for view in views:
        yaw, label = view[:2]
        up = view[2] if len(view) > 2 else 0.08          # how far above the level the camera looks from
        d = mathutils.Vector((np.sin(yaw), np.cos(yaw), up))
        cob.location = ctr + d * size * 2.6
        cob.rotation_euler = (ctr - cob.location).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = path.replace('.png', f'-{label}.png')
        bpy.ops.render.render(write_still=True)


# the doorman's own hands, for the first-person view
FP = {'his_left_clicker': 'left_clicker', 'his_right_card': 'right_card', 'his_right_phone': 'right_phone',
      'his_right_open': 'right_open'}


def build_fp(name, preview=False):
    """One of his hands: the wrist at the origin, the forearm back along Godot's +z, the hand forward
    (-z). Anchors: wrist, grip (the middle of what it holds), and the thing's own (button; card and
    card_facing; phone and phone_facing)."""
    import bpy
    import json
    B, h, parts, props = PP.fp_hand(FP[name])
    pts = np.array([h.o] + [h.w(q) for i in range(4) for q in h.finger(i)] + [h.w(q) for q in h.thumb()[0]] + [h.fore * 0.34])
    lo, hi = pts.min(axis=0) - 0.06, pts.max(axis=0) + 0.06
    verts, faces, mat, names = PP.S.mesh_islands(parts, lo, hi, 0.0022)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts.tolist(), [], faces.tolist())
    for n in names:
        me.materials.append(material(n))
    me.polygons.foreach_set('material_index', mat.tolist())
    me.validate(verbose=False)
    me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    n0 = len(me.polygons)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    if n0 > 24000:
        dec = ob.modifiers.new('decimate', 'DECIMATE')
        dec.ratio = 24000 / n0
        bpy.ops.object.modifier_apply(modifier='decimate')
    extras = []
    for pr in props:
        extras += PROPS[pr['kind']](pr)
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in [ob] + extras:
        o.select_set(True)
    path = os.path.join(OUT, name + '.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
    g = lambda v: [round(float(v[0]), 4), round(float(v[2]), 4), round(float(-v[1]), 4)]
    a = {'wrist': [0.0, 0.0, 0.0], 'forearm': g(h.fore)}
    for pr in props:
        a['grip'] = g(pr['at'])
        if pr['kind'] in ('card', 'phone'):
            a[pr['kind']] = g(pr['at'])
            a[pr['kind'] + '_facing'] = g(pr['R'][:, 2])
            a[pr['kind'] + '_up'] = g(pr['R'][:, 1])
        if pr['kind'] == 'clicker':
            a['button'] = g(pr['at'] + pr['R'][:, 1] * (PP.CLICKER['r'] + 0.01))
            a['clicker_window'] = g(pr['at'] + pr['R'][:, 2] * (PP.CLICKER['t'] / 2) + pr['R'][:, 1] * 0.006)
            a['clicker_facing'] = g(pr['R'][:, 2])
    if 'grip' not in a:
        a['grip'] = g(h.w((0.0, 0.07, 0.02)))
    with open(os.path.join(OUT, name + '.json'), 'w') as fh:
        json.dump(a, fh, indent=1)
    print(f'{name}: {n0} -> {len(ob.data.polygons)} faces, {os.path.getsize(path) / 1e6:.2f} MB')
    if preview:
        c = tuple(h.w((0.0, 0.08, 0.0)))
        render_preview([ob] + extras, os.path.join(OUT, 'previews', name + '.png'),
                       views=((np.pi, 'eye', 0.7), (np.pi * 0.6, 'side', 0.3), (0.0, 'front', 0.2)), focus=(c, 0.22))


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    prev = '--preview' in sys.argv
    for n in (args or list(PEOPLE) + list(FP)):
        (build_fp if n in FP else build)(n, prev)
