"""The people who walk where he can see them (in to the door, out of it, to the jukebox), meshed
standing and rigged to walk, with Blender: models/people/<who>_walk.glb, its walk a loop of two
steps called "walk", and a .json beside it with the head and chest as for the others, and the
stride, how far one loop of the walk carries them along the floor.

  python3 tools/export_walkers.py             every one
  python3 tools/export_walkers.py hoodie      just the kid

The rig is a bone for each part of a body that moves on its own in a walk, at the joints the pose
put them (tools/people.py): the hips, the spine, the chest, the head; each thigh, shin and foot;
each upper arm, forearm and hand. Each point of the skin goes with the bones nearest it (the
nearest by how far it is from each bone's surface, not its middle, so the trunk's thickness counts),
the left ones never on the right. The walk is worked out the way a body walks: the thighs swing,
the knee folds through the swing and a little in the stance, the foot rolls; the hips drop as far
as the legs' angles take them (the lower foot stays on the floor), turn a little with the leading
leg, and the chest turns back against them; the arms swing against the legs, where they're free.
"""
import os
import sys
import json
import time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import people as PP  # noqa: E402
import export_people as EP  # noqa: E402

V = PP.V
OUT = EP.OUT
N = 24          # frames in the loop, at 24 a second: a loop is a second long

# who, in what pose they walk, its settings, how finely, which arms swing (left, right), and how
# they walk: the swing of the thighs (degrees), of the arms, and how far the hips turn
WALKERS = {
    # the kid, hood up, hands in the front pouch, not hurrying
    'hoodie': (EP.KID, 'pouch', dict(hunch=0.8), 0.011, (False, False), dict(hip=21.0, arm=0.0, turn=3.0)),
    # the sister, her jacket held shut at the throat with the keys in that fist, the other arm free
    'driver': (EP.DRIVER, 'close', dict(keys=1, across=False, fist_z=-0.2), 0.011, (True, False), dict(hip=21.0, arm=12.0, turn=4.0)),
    # her boyfriend
    'vape': (EP.VAPE, 'stand', dict(), 0.011, (True, True), dict(hip=23.0, arm=13.0, turn=4.0)),
    # GOOD SHOES
    'goodshoes': (EP.GOODSHOES, 'stand', dict(), 0.011, (True, True), dict(hip=23.0, arm=11.0, turn=4.0)),
    # HI-VIS with his two-four under his arm
    'hivis': (EP.HIVIS, 'carry', dict(), 0.011, (False, True), dict(hip=23.0, arm=13.0, turn=4.0)),
    # Dennis's wife in her raincoat, held shut, the keys in her fist
    'raincoat': (EP.PEOPLE['raincoat'][0], 'close', dict(keys=1), 0.011, (False, False), dict(hip=20.0, arm=0.0, turn=3.0)),
    # the constable
    'constable': (EP.PEOPLE['constable'][0], 'stand', dict(), 0.011, (True, True), dict(hip=23.0, arm=12.0, turn=4.0)),
    # the big man, out to his truck
    'bigman': (EP.PEOPLE['bigman'][0], 'stand', dict(), 0.012, (True, True), dict(hip=22.0, arm=14.0, turn=5.0)),
    # Dennis, out with his wife
    'glasses': (EP.PEOPLE['glasses'][0], 'stand', dict(), 0.012, (True, True), dict(hip=21.0, arm=10.0, turn=4.0)),
    # the big man's buddy
    'buddy': (EP.PEOPLE['buddy'][0], 'stand', dict(), 0.012, (True, True), dict(hip=23.0, arm=13.0, turn=4.0)),
}

SIDES = ('L', 'R')


def bones(B, p):
    """name -> (head, tail, parent): where each bone is, standing."""
    s = B.size
    out = {
        'hips': (p.pelvis, p.waist, None),
        'spine': (p.waist, p.chest, 'hips'),
        'chest': (p.chest, p.neck, 'spine'),
        'head': (p.neck, p.head, 'chest'),
    }
    for i, sd in enumerate(SIDES):
        toe = p.toe[i] * 0.15 * s + V(0, 0, -0.06)
        out['thigh.' + sd] = (p.hip[i], p.knee[i], 'hips')
        out['shin.' + sd] = (p.knee[i], p.ankle[i], 'thigh.' + sd)
        out['foot.' + sd] = (p.ankle[i], p.ankle[i] + toe, 'shin.' + sd)
        out['upper_arm.' + sd] = (p.sh[i], p.elbow[i], 'chest')
        out['forearm.' + sd] = (p.elbow[i], p.wrist[i], 'upper_arm.' + sd)
        out['hand.' + sd] = (p.wrist[i], p.wrist[i] + PP.norm(p.wrist[i] - p.elbow[i]) * 0.08, 'forearm.' + sd)
    return out


def thickness(B, name):
    """How far a bone's surface is from its middle, near enough."""
    b = B.bulk
    base = name.split('.')[0]
    return {'hips': 0.11 * b, 'spine': 0.11 * b, 'chest': 0.11 * b, 'head': 0.07, 'thigh': 0.075 * b ** 0.5,
            'shin': 0.052, 'foot': 0.035, 'upper_arm': 0.048 * b ** 0.75, 'forearm': 0.042 * b ** 0.75, 'hand': 0.03}[base]


def seg_dist(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(float(ab @ ab), 1e-9), 0.0, 1.0)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def skin_weights(B, p, bs, P):
    """For each point, its three nearest bones and how much each has it."""
    names = list(bs)
    mid = p.pelvis[0]
    D = np.full((len(P), len(names)), np.inf)
    for k, n in enumerate(names):
        a, b, _ = bs[n]
        d = np.maximum(seg_dist(P, a, b) - thickness(B, n), 0.0) + 0.006
        if n.endswith('.L'):
            d[P[:, 0] > mid + (0.015 if n.split('.')[0] in ('thigh', 'shin', 'foot') else -0.04)] = np.inf
        elif n.endswith('.R'):
            d[P[:, 0] < mid - (0.015 if n.split('.')[0] in ('thigh', 'shin', 'foot') else -0.04)] = np.inf
        if n.split('.')[0] in ('thigh', 'shin', 'foot'):
            d[P[:, 2] > p.hip[0][2] + 0.1] = np.inf
        D[:, k] = d
    W = 1.0 / D ** 3
    top = np.argsort(-W, axis=1)[:, :3]
    out = []
    for i in range(len(P)):
        w = W[i, top[i]]
        w = w / w.sum()
        out.append([(names[top[i][j]], float(w[j])) for j in range(3) if w[j] > 0.01])
    return out


def bump(x, c, w):
    d = (x - c + np.pi) % (2 * np.pi) - np.pi
    return np.exp(-(d / w) ** 2)


def gait(phi, how):
    """The angles of one leg and the arm on its side at phase phi (0: its heel strikes, its thigh
    forward), in degrees: thigh forward, knee folded, foot up, arm forward, elbow folded."""
    hip = how['hip'] * np.cos(phi)
    knee = 14.0 * bump(phi, 0.3 * np.pi, 0.22 * np.pi) + 58.0 * bump(phi, 1.42 * np.pi, 0.3 * np.pi) + 3.0
    foot = (-4.0 * bump(phi, 0.12 * np.pi, 0.12 * np.pi) + 9.0 * bump(phi, 0.85 * np.pi, 0.25 * np.pi)
            - 16.0 * bump(phi, 1.22 * np.pi, 0.14 * np.pi) + 6.0 * bump(phi, 1.65 * np.pi, 0.2 * np.pi))
    arm = -how['arm'] * np.cos(phi)
    elbow = 6.0 + 9.0 * max(0.0, -np.cos(phi)) if how['arm'] > 0 else 0.0
    return hip, knee, foot, arm, elbow


def leg_drop(B, p, phi_l, how):
    """How far the hips come down at this point of the walk so the lower foot stays on the floor,
    and where each ankle is then along the floor (forward from the hip), for the stride."""
    zs, ys = [], []
    for i, ph in enumerate((phi_l, phi_l + np.pi)):
        hip, knee, _, _, _ = gait(ph, how)
        h, k = np.radians(hip), np.radians(knee)
        y = B.thigh * np.sin(h) + B.shin * np.sin(h - k)
        z = -B.thigh * np.cos(h) - B.shin * np.cos(h - k)
        zs.append(z)
        ys.append(y)
    rest = -(B.thigh + B.shin)
    lowest = min(zs)
    return lowest - rest, ys, int(np.argmin(zs))


def walk_loop(B, p, how):
    """Per frame: the hips' drop and sway, and each bone's turn as (axis, degrees) about the
    world's axes; and the stride, from how far the foot on the floor goes back under them."""
    frames = []
    stride = 0.0
    for f in range(N + 1):
        phi = 2 * np.pi * f / N
        drop, ys, low = leg_drop(B, p, phi, how)
        d2, ys2, _ = leg_drop(B, p, 2 * np.pi * (f + 1) / N, how)
        if f < N:
            stride += max(0.0, ys[low] - ys2[low])
        turns = {}
        for i, sd in enumerate(SIDES):
            ph = phi + (0.0 if i == 0 else np.pi)
            hip, knee, foot, arm, elbow = gait(ph, how)
            turns['thigh.' + sd] = ('X', hip)
            turns['shin.' + sd] = ('X', -knee)
            turns['foot.' + sd] = ('X', foot)
            if how['swing'][i]:
                turns['upper_arm.' + sd] = ('X', arm)
                turns['forearm.' + sd] = ('X', elbow)
        yaw = -how['turn'] * np.cos(phi)
        turns['hips'] = ('Z', yaw)
        turns['spine'] = ('Z', -1.6 * yaw)
        turns['head'] = ('Z', 0.5 * yaw)
        sway = -0.016 * np.sin(phi)
        frames.append(dict(drop=drop, sway=sway, turns=turns))
    return frames, stride


def rig(name, look, pose, kw, step, swing, how):
    import bpy
    import mathutils
    t0 = time.time()
    obs, extras, B, p, report = EP.make(name + '_walk', look, pose, kw, step, False)
    how = dict(how, swing=swing)
    bs = bones(B, p)
    # the things they hold: their bevels made real first (the rig would leave them off)
    for o in extras:
        for o2 in bpy.context.selected_objects:
            o2.select_set(False)
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
    # the skeleton
    arm_data = bpy.data.armatures.new(name + '_rig')
    arm = bpy.data.objects.new(name + '_rig', arm_data)
    bpy.context.scene.collection.objects.link(arm)
    for o2 in bpy.context.selected_objects:
        o2.select_set(False)
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for n, (a, b, par) in bs.items():
        eb = arm_data.edit_bones.new(n)
        eb.head = tuple(float(x) for x in a)
        eb.tail = tuple(float(x) for x in b)
        eb.roll = 0.0
    for n, (a, b, par) in bs.items():
        if par:
            arm_data.edit_bones[n].parent = arm_data.edit_bones[par]
            arm_data.edit_bones[n].use_connect = False
    bpy.ops.object.mode_set(mode='OBJECT')
    # the skin on it
    for o in obs + extras:
        me = o.data
        P = np.array([o.matrix_world @ v.co for v in me.vertices])
        groups = {n: o.vertex_groups.new(name=n) for n in bs}
        part = o.name.rsplit('_', 1)[-1]
        if part == 'head':
            groups['head'].add(list(range(len(P))), 1.0, 'REPLACE')
        elif part == 'hands' or o in extras:
            # rigid, each to the hand (or, held against the body, the bone) it's nearest
            c = P.mean(axis=0)
            best = min(bs, key=lambda n: seg_dist(c[None, :], bs[n][0], bs[n][1])[0])
            if part == 'hands':
                for i, sd in enumerate(SIDES):
                    idx = [k for k in range(len(P)) if (P[k, 0] < p.pelvis[0]) == (i == 0)]
                    if idx:
                        groups['hand.' + sd].add(idx, 1.0, 'REPLACE')
            else:
                groups[best].add(list(range(len(P))), 1.0, 'REPLACE')
        else:
            for k, ws in enumerate(skin_weights(B, p, bs, P)):
                for n, w in ws:
                    groups[n].add([k], w, 'REPLACE')
        mod = o.modifiers.new('rig', 'ARMATURE')
        mod.object = arm
        o.parent = arm
    # the walk
    frames, stride = walk_loop(B, p, how)
    scene = bpy.context.scene
    scene.render.fps = 24
    scene.frame_start = 0
    scene.frame_end = N
    arm.animation_data_create()
    act = bpy.data.actions.new('walk')
    arm.animation_data.action = act
    rest = {n: arm_data.bones[n].matrix_local.to_3x3() for n in bs}
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    for f, fr in enumerate(frames):
        for pb in arm.pose.bones:
            n = pb.name
            R = rest[n]
            q = mathutils.Quaternion()
            if n in fr['turns']:
                ax, deg = fr['turns'][n]
                W = mathutils.Matrix.Rotation(np.radians(deg), 3, ax)
                q = (R.inverted() @ W @ R).to_quaternion()
            pb.rotation_quaternion = q
            pb.keyframe_insert('rotation_quaternion', frame=f)
            if n == 'hips':
                pb.location = R.inverted() @ mathutils.Vector((fr['sway'], 0.0, -fr['drop']))
                pb.keyframe_insert('location', frame=f)
    for o2 in bpy.context.selected_objects:
        o2.select_set(False)
    for o in [arm] + obs + extras:
        o.select_set(True)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + '_walk.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=False,
                              export_yup=True, export_animations=True, export_skins=True, export_force_sampling=True,
                              export_frame_range=True, export_def_bones=False)
    a = EP.anchors(B, p)
    a['stride'] = round(float(stride), 4)
    a['loop'] = N / 24.0
    with open(os.path.join(OUT, name + '_walk.json'), 'w') as fh:
        json.dump(a, fh, indent=1)
    print(f'{name}_walk: {", ".join(report)}; stride {stride:.2f} m a loop, '
          f'{os.path.getsize(path) / 1e6:.2f} MB, {time.time() - t0:.1f}s')


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    for n in (args or list(WALKERS)):
        rig(n, *WALKERS[n])
