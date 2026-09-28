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
}
ROUGH = {'phone': 0.3, 'screen': 0.2, 'eye': 0.25, 'iris': 0.25, 'earbud': 0.3, 'glasses': 0.3, 'reflective': 0.4, 'cue': 0.4}

# who, in what pose, how finely (metres per voxel for the body; the kid is seen at arm's length)
PEOPLE = {
    'hoodie_door': (dict(age='young', build='slight', hat='hood', top='hoodie', face=['earbuds'], hair='messy'),
                    'phone_out', dict(), 0.008),
    'hoodie_lot': (dict(age='young', build='slight', hat='hood', top='hoodie', face=['earbuds'], hair='messy'),
                   'walk_pouch', dict(), 0.011),
    'team_jacket': (dict(age='old', hair='thin', top='jacket'), 'sit', dict(lean=0.3), 0.012),
    'hearing_aid': (dict(age='old', hair='bald', top='flannel', face=['hearingaid'], bulk=1.1, bottoms='khaki'), 'sit', dict(lean=0.15, head_turn=0.4), 0.012),
    'scratch': (dict(age='old', hat='cap', top='coat', face=['stubble']), 'sit', dict(lean=0.35, head_tilt=0.3), 0.012),
    'cardigan': (dict(age='old', hair='parted', top='cardigan', build='slight', bottoms='slacks'), 'sit', dict(lean=0.05, slump=0.03), 0.012),
    'glasses': (dict(age='old', hair='short', top='tshirt', face=['glasses', 'moustache'], bulk=1.15),
                'sit', dict(lean=0.2, head_turn=-0.5, hands=[(-0.14, 0.42, 0.83), (0.2, 0.3, 1.22)]), 0.012),
    'bigman': (dict(build='big', hair='buzz', face=['beard'], top='flannel', sleeves='rolled'), 'cue', dict(left_handed=True), 0.012),
    'buddy': (dict(build='slight', hair='short', top='tshirt', hat='cap', size=0.94), 'stand', dict(head_turn=0.3), 0.012),
    'bartender': (dict(build='slight', sex='f', hair='bun', face=['lined'], top='apron', age='old', bottoms='trousers', shoes='sneakers'), 'bar', dict(top=1.1), 0.012),
    'hivis': (dict(hat='cap', top='hivis', face=['stubble']), 'sit', dict(seat=0.76, table=1.08, lean=0.3), 0.012),
    'endbar': (dict(age='old', hat='flatcap', face=['lined'], top='tweed', build='slight', bottoms='slacks'),
               'sit', dict(seat=0.76, table=1.08, lean=0.12, head_turn=0.5), 0.012),
    'crew_a': (dict(top='hivis', hat='beanie', face=['beard'], bulk=1.05), 'sit', dict(lean=0.3, head_turn=0.3), 0.012),
    'crew_b': (dict(build='big', top='flannel', hat='cap', face=['stubble']), 'sit', dict(lean=0.2, head_turn=-0.4), 0.012),
    # in the truck, placed in its frame by main.gd: the sister at the wheel, looking at her phone;
    # her boyfriend slumped in the back
    'driver': (dict(sex='f', age='young', hair='ponytail', top='jacket'), 'sit',
               dict(seat=0.98, feet='floor', floor=0.62, reach=0.5, lean=0.08, head_tilt=0.4,
                    hands=[(-0.17, 0.5, 1.4), (0.05, 0.3, 1.3)], palms=[(0.3, 0, -1), (-0.1, -0.6, 0.8)], phone=1), 0.012),
    'vape': (dict(age='young', hair='messy', top='hoodie'), 'sit',
             dict(seat=0.98, feet='floor', floor=0.62, reach=0.55, lean=-0.3, head_roll=0.35, head_tilt=-0.1,
                  hands=[(-0.2, 0.18, 1.05), (0.2, 0.22, 1.08)]), 0.012),
    'slippers': (dict(sex='f', age='old', hair='bun', top='cardigan', bottoms='trousers', shoes='slippers', bulk=1.1),
                 'reach', dict(), 0.012),
}


def build(name, preview=False):
    import bpy
    look, pose, kw, step = PEOPLE[name]
    near = name == 'hoodie_door'
    t0 = time.time()
    meshes = PP.mesh_person(look, pose, step=step, head_step=0.0028 if near else 0.005, **kw)
    t1 = time.time()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # how many faces each part keeps: the kid at the door is seen at arm's length
    targets = {'body': 36000 if near else 12000, 'head': 32000 if near else 7000}
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
    extras = phone(p.phone_at) if hasattr(p, 'phone_at') else []
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + '.glb')
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in obs + extras:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True,
                              export_yup=True)
    print(f'{name}: {", ".join(report)} faces, sdf {t1 - t0:.1f}s, total {time.time() - t0:.1f}s')
    # where things are on them, for Godot (its axes: x, z, -y): the phone, the head, the hands
    import json
    g = lambda v: [round(float(v[0]), 4), round(float(v[2]), 4), round(float(-v[1]), 4)]
    anchors = {'head': g(p.head), 'hand_left': g(p.wrist[0]), 'hand_right': g(p.wrist[1])}
    if hasattr(p, 'phone_at'):
        anchors['phone'] = g(p.phone_at[0])
        anchors['phone_facing'] = g(p.phone_at[1][:, 2])
    with open(os.path.join(OUT, name + '.json'), 'w') as fh:
        json.dump(anchors, fh, indent=1)
    if preview:
        render_preview(obs, os.path.join(OUT, 'previews', name + '.png'))
    if '--face' in sys.argv:
        render_preview(obs, os.path.join(OUT, 'previews', name + '-face.png'), views=((0.0, 'front'), (0.7, 'three-quarter'), (0.35, 'near')),
                       focus=(tuple(p.head + np.array([0, 0.02, -0.02])), 0.34))


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
    if name in ('screen', 'phone_screen'):
        bsdf.inputs['Emission Color'].default_value = (*lin, 1.0)
        bsdf.inputs['Emission Strength'].default_value = 1.0
    return m


def phone(at):
    """The phone in his hand: a bevelled slab, and its screen as a face of its own with UVs, so
    Godot can show the licence photo on it."""
    import bpy
    import mathutils
    c, Rp = at
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    body = bpy.context.active_object
    body.name = 'phone'
    body.scale = (0.072, 0.152, 0.0085)
    bpy.ops.object.transform_apply(scale=True)
    bev = body.modifiers.new('bevel', 'BEVEL')
    bev.width = 0.004
    bev.segments = 3
    body.data.materials.append(material('phone'))
    bpy.ops.mesh.primitive_plane_add(size=1.0)
    scr = bpy.context.active_object
    scr.name = 'phone_screen'
    scr.scale = (0.064, 0.14, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    scr.location = (0, 0, 0.0044)
    bpy.ops.object.transform_apply(location=True)
    scr.data.materials.append(material('phone_screen'))
    M = mathutils.Matrix(np.asarray(Rp, dtype=float).tolist()).to_4x4()
    M.translation = mathutils.Vector([float(x) for x in c])
    for o in (body, scr):
        o.matrix_world = M
        o.data.update()
    return [body, scr]


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
    for yaw, label in views:
        d = mathutils.Vector((np.sin(yaw), np.cos(yaw), 0.08))
        cob.location = ctr + d * size * 2.6
        cob.rotation_euler = (ctr - cob.location).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = path.replace('.png', f'-{label}.png')
        bpy.ops.render.render(write_still=True)


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    prev = '--preview' in sys.argv
    for n in (args or list(PEOPLE)):
        build(n, prev)
