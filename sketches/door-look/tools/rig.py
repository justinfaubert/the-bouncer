"""The rig every person in the room is made with, so the room can move them while he watches
(godot/world/life.gd): breathing, shifting on a stool, turning a head, the eyes going to him and
away, blinking, the jaw going while they talk, a glass lifted.

The bones are in the pose the model is made in (its rest pose is the pose: a model with nothing
moved is the model as it's sculpted). They're the walk's (tools/export_walkers.py): the hips, the
spine, the chest; each thigh, shin and foot; each upper arm, forearm and hand. And the head's own:
the neck, from between the shoulders up to the joint under the skull where a head nods and turns;
the head; the jaw, hinged in front of the ears; each eye, turning about its middle; and each lid.
The lids the faces are sculpted with are too thin a skin to move, so each eye has a lid of its own
for blinking: a cap of skin on a sphere just over the ball (over the iris, under the skin of the
lids), its lower edge drawn dark like the lashes, lying folded up under the upper lid at rest; its
bone turns it down about the eye's middle to close the eye. And the mouth is opened along the line
where the lips meet, with the dark of the mouth behind it, so that when the jaw drops, the lips part.

The skin goes with its bones by where it is: the body's by how near each bone is (its three
nearest, as for the walk), the head's by the head's own measurements (tools/head.py): below the jaw
it's the neck's, the lower lip and the chin and the jaw down from the corners of the mouth the
jaw's, the balls of the eyes their own.
The neck is weighted the same way in both meshes it's in (the body's, inside the collar, and the
head's), so the two never part.
"""
import numpy as np
import people as PP

V = PP.V
SIDES = ('L', 'R')          # L is the person's left: x < 0 in the body's frame
MM = 0.001

# The head's own points, in its frame (head.py: x to their right, y forward, z up, mm for an average
# man's head, scaled with the head): the joint under the skull where the head nods and turns, the
# jaw's hinge in front of the ears.
NOD = (0.0, -16.0, -34.0)
HINGE = (0.0, 8.0, -14.0)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


class HeadFrame:
    """Between the world and a person's head frame (mm, as head.py's numbers)."""

    def __init__(self, B, p, hd):
        self.H, self.R, self.s = p.head, p.Rh, PP.head_scale(B)
        self.fp = hd.fp
        self.hd = hd

    def local(self, P):
        return ((P - self.H) @ self.R) / (self.s * MM)

    def world(self, q):
        return self.H + self.R @ (V(*q) * self.s * MM)


def bones(B, p, hd):
    """name -> (head, tail, parent): where each bone is, in the model's pose."""
    hf = HeadFrame(B, p, hd)
    fp = hd.fp
    s = B.size
    up_h = p.Rh[:, 2]
    fw_h = p.Rh[:, 1]
    nod = hf.world(NOD)
    hinge = hf.world(HINGE)
    out = {
        'hips': (p.pelvis, p.waist, None),
        'spine': (p.waist, p.chest, 'hips'),
        'chest': (p.chest, p.neck, 'spine'),
        'neck': (p.neck, nod, 'chest'),
        'head': (nod, nod + up_h * 0.12 * hf.s, 'neck'),
        'jaw': (hinge, hf.world((0.0, fp['pg_y'], fp['pg_z'])), 'head'),
    }
    for i, sd in enumerate(SIDES):
        sx = -1.0 if i == 0 else 1.0
        c = hf.world((sx * fp['eye_x'], fp['eye_y'], fp['eye_z']))
        out['eye.' + sd] = (c, c + fw_h * 0.02, 'head')
        out['lid.' + sd] = (c, c + fw_h * 0.018 + up_h * 0.004, 'head')
    for i, sd in enumerate(SIDES):
        toe = p.toe[i] * 0.15 * s + V(0, 0, -0.06)
        out['thigh.' + sd] = (p.hip[i], p.knee[i], 'hips')
        out['shin.' + sd] = (p.knee[i], p.ankle[i], 'thigh.' + sd)
        out['foot.' + sd] = (p.ankle[i], p.ankle[i] + toe, 'shin.' + sd)
        out['upper_arm.' + sd] = (p.sh[i], p.elbow[i], 'chest')
        out['forearm.' + sd] = (p.elbow[i], p.wrist[i], 'upper_arm.' + sd)
        out['hand.' + sd] = (p.wrist[i], p.wrist[i] + PP.norm(p.wrist[i] - p.elbow[i]) * 0.08, 'forearm.' + sd)
    return out


def _thickness(B, name):
    """How far a bone's surface is from its middle, near enough (the body's bones only)."""
    b = B.bulk
    base = name.split('.')[0]
    return {'hips': 0.11 * b, 'spine': 0.11 * b, 'chest': 0.11 * b, 'thigh': 0.075 * b ** 0.5,
            'shin': 0.052, 'foot': 0.035, 'upper_arm': 0.048 * b ** 0.75, 'forearm': 0.042 * b ** 0.75, 'hand': 0.03}[base]


def _seg_dist(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(float(ab @ ab), 1e-9), 0.0, 1.0)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


BODY = ('hips', 'spine', 'chest', 'thigh.L', 'shin.L', 'foot.L', 'thigh.R', 'shin.R', 'foot.R',
        'upper_arm.L', 'forearm.L', 'hand.L', 'upper_arm.R', 'forearm.R', 'hand.R')


def body_weights(B, p, bs, P):
    """For each point of the body, its three nearest bones and how much each has it (n x len(BODY))."""
    mid = p.pelvis[0]
    D = np.full((len(P), len(BODY)), np.inf)
    for k, n in enumerate(BODY):
        a, b, _ = bs[n]
        d = np.maximum(_seg_dist(P, a, b) - _thickness(B, n), 0.0) + 0.006
        limb = n.split('.')[0] in ('thigh', 'shin', 'foot')
        if n.endswith('.L'):
            d[P[:, 0] > mid + (0.015 if limb else -0.04)] = np.inf
        elif n.endswith('.R'):
            d[P[:, 0] < mid - (0.015 if limb else -0.04)] = np.inf
        if limb:
            d[P[:, 2] > p.hip[0][2] + 0.1] = np.inf
        D[:, k] = d
    W = 1.0 / D ** 3
    top = np.argsort(-W, axis=1)[:, :3]
    out = np.zeros_like(W)
    rows = np.arange(len(P))[:, None]
    out[rows, top] = W[rows, top]
    return out / np.maximum(out.sum(axis=1, keepdims=True), 1e-12)


def neck_share(B, p, hf, P):
    """For points about the neck and head: how much the chest, the neck and the head have each (n x 3).
    The head has what's above the line of the jaw and the base of the skull; below it, the neck
    takes over from the chest up the neck's length."""
    q = hf.local(P)
    fp = hf.fp
    y, z = q[:, 1], q[:, 2]
    # the line between the head and the neck, side on: under the chin, along the jaw to its angle,
    # up behind the ear and round under the back of the skull
    ys = [-120.0, -30.0, fp['go_y'], fp['me_y'], fp['me_y'] + 30.0]
    zs = [-66.0, -50.0, fp['go_z'] - 6.0, fp['me_z'] - 4.0, fp['me_z'] - 8.0]
    zb = np.interp(y, ys, zs)
    head = smooth(-11.0, 11.0, z - zb)
    nod = hf.world(NOD)
    ax = nod - p.neck
    t = ((P - p.neck) @ ax) / float(ax @ ax)
    neck = smooth(0.0, 0.35, t)
    return np.stack([(1.0 - head) * (1.0 - neck), (1.0 - head) * neck, head], axis=1)


def head_weights(B, p, hf, P, mats):
    """Each point of the head mesh's share for each of the head's bones: chest, neck, head, jaw, eye.L,
    eye.R (n x 6). mats: each point's material name."""
    fp = hf.fp
    q = hf.local(P)
    x, y, z = q[:, 0], q[:, 1], q[:, 2]
    W = np.zeros((len(P), len(HEAD_BONES)))
    W[:, :3] = neck_share(B, p, hf, P)
    head = W[:, 2].copy()
    hairy = np.char.startswith(mats.astype(str), 'hair') | np.isin(mats, ['beard'])
    skinlike = np.isin(mats, ['skin', 'lip', 'stubble', 'mouth']) | hairy
    # the jaw: below the line from each corner of the mouth back to the hinge, in front of it; at the
    # lips, sharply at the line where they meet
    sto, w = fp['sto_z'], fp['ch_w']
    corner_y = fp['ls_y'] - 17.0
    zc = sto + 1.5 * fp['smile'] * np.clip(np.abs(x) / w, 0.0, 1.0) ** 2
    zl = np.where(y > corner_y, zc, np.interp(y, [HINGE[1], corner_y], [HINGE[2] - 4.0, sto]))
    at_lips = (np.abs(x) < w + 3.0) & (y > corner_y - 4.0)
    band = np.where(at_lips, 0.7, 7.0)
    jaw = smooth(-band, band, zl - z) * smooth(HINGE[1] - 6.0, HINGE[1] + 10.0, y)
    # the lower lip held at its corners, so the lips part wider in the middle than at the ends
    lower_lip = at_lips & (z > sto - fp['li_h'] - 3.0)
    jaw = np.where(lower_lip, jaw * (1.0 - 0.75 * smooth(w - 11.0, w + 1.0, np.abs(x))), jaw)
    # (the moustache, over the lip, stays with the head; a beard goes with the jaw, but not the hair
    # that hangs beside the face)
    jaw = np.where(hairy, jaw * (1.0 - smooth(w + 22.0, w + 34.0, np.abs(x))) * smooth(8.0, 18.0, y), jaw)
    jaw = np.where(skinlike, jaw, 0.0)
    W[:, 3] = head * jaw
    W[:, 2] = head * (1.0 - jaw)
    # the balls of the eyes, and the irises on them
    for i, sd in enumerate(SIDES):
        sx = -1.0 if i == 0 else 1.0
        ball = np.isin(mats, ['eye', 'iris']) & (x * sx > 0)
        W[ball] = 0.0
        W[ball, 4 + i] = 1.0
    return W / np.maximum(W.sum(axis=1, keepdims=True), 1e-12)


def lid_caps(B, p, hd, rows=9, cols=13):
    """Each eye's blinking lid, as it lies at rest (folded up under the upper lid): verts (world),
    quads, and for each quad whether it's the dark edge. Returns [(side, verts, quads, dark)] and the
    angle it turns down through to close."""
    hf = HeadFrame(B, p, hd)
    fp = hd.fp
    rc = fp['eye_r'] + 1.3
    up = np.array(hd.margin(True, 25))
    low = np.array(hd.margin(False, 25))
    u0, u1 = float(up[0, 0]) - 1.5, float(up[-1, 0]) + 1.5
    mid_up = float(np.interp(0.0, up[:, 0], up[:, 1]))
    mid_low = float(np.interp(0.0, low[:, 0], low[:, 1]))
    # how far it turns: its lower edge from the lower lid's edge up past the upper's, about the ball
    shut = np.arcsin(np.clip((mid_up + 0.6) / rc, -1, 1)) - np.arcsin(np.clip((mid_low - 0.9) / rc, -1, 1))
    out = []
    for i, sd in enumerate(SIDES):
        sx = -1.0 if i == 0 else 1.0
        c = np.array([sx * fp['eye_x'], fp['eye_y'], fp['eye_z']])
        verts = []
        for r in range(rows):
            for k in range(cols):
                u = u0 + (u1 - u0) * k / (cols - 1)
                vl = float(np.interp(u, low[:, 0], low[:, 1])) - 0.9
                vu = float(np.interp(u, up[:, 0], up[:, 1])) + 2.2
                v = vl + (vu - vl) * r / (rows - 1)
                # on the sphere (out at the corners too, where u runs past it)
                th = np.arcsin(np.clip(v / rc, -0.95, 0.95))
                rho = rc * np.cos(th)
                ph = np.arcsin(np.clip(u / rho, -0.97, 0.97))
                uu, yv, zv = rho * np.sin(ph), rho * np.cos(ph), rc * np.sin(th)
                # closed, then folded up through `shut` about the eye's middle
                ca, sa = np.cos(shut), np.sin(shut)
                yv, zv = yv * ca - zv * sa, yv * sa + zv * ca
                verts.append(hf.world((c[0] + sx * uu, c[1] + yv, c[2] + zv)))
        quads, dark = [], []
        for r in range(rows - 1):
            for k in range(cols - 1):
                a, b = r * cols + k, r * cols + k + 1
                cq, d = (r + 1) * cols + k + 1, (r + 1) * cols + k
                # wound to face out of the eye whichever side it's on
                quads.append((a, d, cq, b) if sx > 0 else (a, b, cq, d))
                dark.append(r == 0)
        out.append((sd, np.array(verts), quads, dark))
    return out, float(np.degrees(shut))


def mouth_bag(B, p, hd, rows=6, cols=11):
    """The dark of the mouth behind the lips: a curved sheet along the teeth, facing out. Returns verts
    (world), quads and each vert's height above the line of the lips (mm)."""
    hf = HeadFrame(B, p, hd)
    fp = hd.fp
    w, sto = fp['ch_w'], fp['sto_z']
    verts, hz = [], []
    for r in range(rows):
        z = sto - 8.0 + 13.0 * r / (rows - 1)
        for k in range(cols):
            x = -(w - 1.5) + 2.0 * (w - 1.5) * k / (cols - 1)
            y = hd.arch((fp['ls_y'] - 13.0) * MM, (fp['ls_y'] - 26.0) * MM, x * MM) / MM
            verts.append(hf.world((x, y, z)))
            hz.append(z - sto)
    quads = []
    for r in range(rows - 1):
        for k in range(cols - 1):
            a, b = r * cols + k, r * cols + k + 1
            # (facing out of the mouth)
            quads.append((a, (r + 1) * cols + k, (r + 1) * cols + k + 1, b))
    return np.array(verts), quads, np.array(hz)


def open_mouth(ob, hf):
    """Cut the head's mesh along the line where the lips meet (the faces across it, between the
    corners, the stubble's too where it comes down to the lips), so the lips can part."""
    import bmesh
    fp = hf.fp
    me = ob.data
    names = [m.name.split('.')[0] for m in me.materials]
    bm = bmesh.new()
    bm.from_mesh(me)
    w, sto = fp['ch_w'], fp['sto_z']
    cut = []
    for f in bm.faces:
        if names[f.material_index] not in ('skin', 'lip', 'stubble', 'beard'):
            continue
        q = hf.local(np.array([ob.matrix_world @ v.co for v in f.verts], dtype=np.float64))
        cx, cy = q[:, 0].mean(), q[:, 1].mean()
        if abs(cx) > w - 1.5 or cy < fp['ls_y'] - 15.0:
            continue
        zc = sto + 1.5 * fp['smile'] * min(abs(cx) / w, 1.0) ** 2
        if q[:, 2].min() < zc + 0.3 and q[:, 2].max() > zc - 0.3:
            cut.append(f)
    bmesh.ops.delete(bm, geom=cut, context='FACES')
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context='VERTS')
    bm.to_mesh(me)
    bm.free()
    me.update()
    return len(cut)


HEAD_BONES = ('chest', 'neck', 'head', 'jaw', 'eye.L', 'eye.R')


def vertex_materials(me):
    """Each vertex's material name (a vertex is in one material's island only)."""
    out = np.array([''] * len(me.vertices), dtype=object)
    names = [m.name.split('.')[0] for m in me.materials]
    for poly in me.polygons:
        n = names[poly.material_index]
        for vi in poly.vertices:
            out[vi] = n
    return out.astype(str)


def _mesh_object(name, verts, quads, mats, mat_names):
    """A Blender object of quads, a material for each."""
    import bpy
    import export_people as EP
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(float(c) for c in v) for v in verts], [], [tuple(q) for q in quads])
    for n in mat_names:
        me.materials.append(EP.material(n))
    me.polygons.foreach_set('material_index', list(mats))
    me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def rest_strokes(o):
    """Where each point of a mesh is in the model's pose, for the print (godot/look/surface.gdshader):
    its height and how much its surface faces up (Godot's y, Blender's z), as a second set of UVs.
    The press cuts a person's strokes by those, so the strokes stay where they're cut on the skin
    when the bones move it (a turned head takes its strokes round with it, and a breath doesn't make
    them crawl). A mesh with no UVs of its own has them as its only UVs (glTF's first set, Godot's
    UV); one with a picture on it, as its second (UV2)."""
    me = o.data
    uv = me.uv_layers.new(name='rest')
    M = o.matrix_world
    N = M.to_3x3().inverted().transposed()
    h = np.array([(M @ v.co).z for v in me.vertices])
    up = np.array([(N @ v.normal).normalized().z for v in me.vertices])
    vi = np.zeros(len(me.loops), dtype=np.int64)
    me.loops.foreach_get('vertex_index', vi)
    # (glTF turns a UV's v upside down: 1 - v)
    co = np.stack([h[vi], 1.0 - up[vi]], axis=1).astype(np.float32)
    uv.data.foreach_set('uv', co.ravel())


def rig(name, obs, extras, B, p, hd):
    """Put a skeleton under the meshed person (Blender objects: the body, the head, the hands, and the
    things they hold) and skin each on it, with the lids that blink and the dark of the mouth added.
    Returns the armature object, and the objects added (to export with the rest)."""
    import bpy
    bs = bones(B, p, hd)
    hf = HeadFrame(B, p, hd)
    # the things they hold: their bevels made real first (the rig would leave them off)
    for o in extras:
        for o2 in bpy.context.selected_objects:
            o2.select_set(False)
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
    # the mouth opened along the line of the lips, and what's behind it; the lids
    head_ob = next((o for o in obs if o.name.endswith('_head')), None)
    added = []
    if head_ob is not None:
        open_mouth(head_ob, hf)
        bv, bq, bz = mouth_bag(B, p, hd)
        bag = _mesh_object(name + '_mouth', bv, bq, [0] * len(bq), ['mouth'])
        bag['heights'] = list(map(float, bz))
        added.append(bag)
        caps, shut = lid_caps(B, p, hd)
        for sd, cv, cq, dark in caps:
            added.append(_mesh_object(name + '_lid' + sd, cv, cq, [1 if d else 0 for d in dark], ['skin', 'lash']))
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
    for o in obs + extras + added:
        me = o.data
        P = np.array([o.matrix_world @ v.co for v in me.vertices], dtype=np.float64)
        groups = {n: o.vertex_groups.new(name=n) for n in bs}
        part = o.name.rsplit('_', 1)[-1]
        if part in ('lidL', 'lidR'):
            groups['lid.' + part[-1]].add(list(range(len(P))), 1.0, 'REPLACE')
        elif part == 'mouth':
            # the top of it stays with the head, the bottom goes down with the jaw
            hz = np.array(o['heights'])
            jw = smooth(1.5, -1.5, hz)
            for k in range(len(P)):
                if jw[k] < 0.99:
                    groups['head'].add([k], float(1.0 - jw[k]), 'REPLACE')
                if jw[k] > 0.01:
                    groups['jaw'].add([k], float(jw[k]), 'REPLACE')
        elif o in extras or part == 'hands':
            # rigid, each to the hand (or, held against the body, the bone) it's nearest
            if part == 'hands':
                for i, sd in enumerate(SIDES):
                    idx = [k for k in range(len(P)) if (P[k, 0] < p.pelvis[0]) == (i == 0)]
                    if idx:
                        groups['hand.' + sd].add(idx, 1.0, 'REPLACE')
            else:
                c = P.mean(axis=0)
                best = min(BODY, key=lambda n: _seg_dist(c[None, :], bs[n][0], bs[n][1])[0])
                groups[best].add(list(range(len(P))), 1.0, 'REPLACE')
        else:
            if part == 'head':
                W, names = head_weights(B, p, hf, P, vertex_materials(me)), HEAD_BONES
            else:
                W, names = body_weights(B, p, bs, P), BODY
                # about the neck, as the head's mesh has it
                q = hf.local(P)
                near = (np.hypot(q[:, 0], q[:, 1] + 20.0) < 95.0) & (q[:, 2] > -260.0)
                if near.any():
                    ns = neck_share(B, p, hf, P[near])
                    full = np.zeros((len(P), len(BODY) + 2))
                    full[:, :len(BODY)] = W
                    full[near, :len(BODY)] = W[near] * ns[:, :1]
                    full[near, len(BODY)] = ns[:, 1]
                    full[near, len(BODY) + 1] = ns[:, 2]
                    W, names = full, BODY + ('neck', 'head')
            for j, n in enumerate(names):
                col = W[:, j]
                idx = np.nonzero(col > 0.01)[0]
                for k in idx:
                    groups[n].add([int(k)], float(col[k]), 'REPLACE')
        rest_strokes(o)
        mod = o.modifiers.new('rig', 'ARMATURE')
        mod.object = arm
        o.parent = arm
    return arm, added


def rig_anchors(B, p, hd):
    """What the room needs to move them, in Godot's axes (x, z, -y): the bones' names, where the eyes
    and the mouth are, and how far the lids turn down to close."""
    g = lambda v: [round(float(v[0]), 4), round(float(v[2]), 4), round(float(-v[1]), 4)]
    hf = HeadFrame(B, p, hd)
    fp = hd.fp
    return {
        'bones': list(bones(B, p, hd)),
        'eyes': [g(hf.world((sx * fp['eye_x'], fp['eye_y'], fp['eye_z']))) for sx in (-1.0, 1.0)],
        'mouth': g(hf.world((0.0, fp['ls_y'], fp['sto_z']))),
        'blink': round(lid_caps(B, p, hd)[1], 1),
        # the head as it's sculpted: which way is its right, its front and its top
        'head_axes': [g(p.Rh[:, 0]), g(p.Rh[:, 1]), g(p.Rh[:, 2])],
    }
