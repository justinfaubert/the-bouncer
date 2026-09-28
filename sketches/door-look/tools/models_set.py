"""The props for the door look test, modelled from nothing in Blender (bpy) and exported as .glb.

  python3 tools/models_set.py                   every asset, in priority order
  python3 tools/models_set.py truck pendant     only those (a group name or a file name, see GROUPS)
  python3 tools/models_set.py --no-preview tv   skip the Cycles preview renders

Conventions the Godot scene depends on: metres; Blender is Z-up and the glTF export is +Y up, so
Blender +Y, each model's front, becomes Godot -Z (forward). Origins are listed in models/README.md.
Materials are named by role (MATS) with the object's real colour; Godot swaps in its print shader by
name. Hard edges get a small bevel with hardened normals (so flats stay flat), curves get enough
segments that neighbouring faces meet at under ~20 degrees, and edges are marked sharp by angle.

Writes models/<name>.glb, models/previews/<name>.png and models/README.md.
Set MODELS_CHECK_DIR to also render extra review views of each asset into that folder.
"""
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), 'models')
PREVIEWS = os.path.join(OUT, 'previews')
CHECK = os.environ.get('MODELS_CHECK_DIR')
TAU = math.tau
D = math.radians
V = Vector


# ------------------------------------------------------------------ materials

MATS = {  # role: (colour, roughness, metallic)
    'wood': ('#8a6a48', 0.4, 0.0),
    'wood_dark': ('#4a3526', 0.4, 0.0),
    'laminate': ('#b7a88f', 0.5, 0.0),
    'chrome': ('#c9cbcf', 0.25, 1.0),
    'brass': ('#b08d57', 0.35, 1.0),
    'bronze': ('#4b4038', 0.45, 0.6),
    'black': ('#1c1c1e', 0.6, 0.0),
    'dark': ('#3a3a3d', 0.5, 0.0),
    'rubber': ('#202022', 0.9, 0.0),
    'vinyl': ('#5a1f1d', 0.45, 0.0),
    'paint': ('#5b2622', 0.35, 0.0),
    'tire': ('#1e1e1f', 0.95, 0.0),
    'plastic_light': ('#b9b6ae', 0.5, 0.0),
    'felt': ('#2f5b3e', 0.9, 0.0),
    'paper': ('#e6dfcf', 0.85, 0.0),
    'cloth': ('#3a3836', 0.9, 0.0),
    'glass': ('#a9bccb', 0.05, 0.0),          # alpha 0.15
    'ceramic': ('#e8e4da', 0.2, 0.0),         # added: the glazed white mug
    'headlight': ('#f4f6ff', 0.2, 0.0),       # the light-giving ones also emit (EMIT)
    'taillight': ('#ff2a1a', 0.3, 0.0),
    'bulb': ('#ffd9a0', 0.2, 0.0),
    'screen': ('#e6eefc', 0.15, 0.0),
    'juke_light': ('#e0708e', 0.3, 0.0),
    'dome': ('#ffe2b8', 0.4, 0.0),
    'amber_marker': ('#ffae3b', 0.3, 0.0),
}
EMIT = {'headlight': 4.0, 'taillight': 3.0, 'bulb': 6.0, 'screen': 1.5, 'juke_light': 3.0,
        'dome': 3.0, 'amber_marker': 3.0}


def linear(hexcol):
    c = [int(hexcol[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


def mat(name):
    """The material for a role, made on first use: a Principled BSDF with the role's real colour."""
    m = bpy.data.materials.get(name)
    if m:
        return m
    hexcol, rough, metal = MATS[name]
    col = linear(hexcol)
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except AttributeError:
        pass
    b = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    b.inputs['Base Color'].default_value = (*col, 1.0)
    b.inputs['Roughness'].default_value = rough
    b.inputs['Metallic'].default_value = metal
    if name in EMIT:
        b.inputs['Emission Color'].default_value = (*col, 1.0)
        b.inputs['Emission Strength'].default_value = EMIT[name]
    if name == 'glass':
        b.inputs['Alpha'].default_value = 0.15
        m.surface_render_method = 'BLENDED'
    m.diffuse_color = (*col, 0.15 if name == 'glass' else 1.0)
    m.metallic, m.roughness = metal, rough
    return m


# ------------------------------------------------------------------ 2D outlines

def arc(cx, cy, r, a0, a1, n):
    """n + 1 points on a circle, from angle a0 to a1 (degrees), both ends included."""
    return [(cx + r * math.cos(D(a0 + (a1 - a0) * k / n)), cy + r * math.sin(D(a0 + (a1 - a0) * k / n)))
            for k in range(n + 1)]


def circle(r, n, cx=0.0, cy=0.0):
    return [(cx + r * math.cos(TAU * k / n), cy + r * math.sin(TAU * k / n)) for k in range(n)]


def rrect(x0, x1, y0, y1, r, n=6):
    """A rectangle with rounded corners, counterclockwise; r is one radius or four (from the (x1, y0) corner round)."""
    rs = r if isinstance(r, (list, tuple)) else [r] * 4
    rs = [min(q, (x1 - x0) / 2, (y1 - y0) / 2) for q in rs]
    pts = []
    for (cx, cy, a0), q in zip(((x1, y0, -90), (x1, y1, 0), (x0, y1, 90), (x0, y0, 180)), rs):
        sx = -1 if cx == x1 else 1
        sy = -1 if cy == y1 else 1
        if q < 1e-6:
            pts.append((cx, cy))
        else:
            pts += arc(cx + sx * q, cy + sy * q, q, a0, a0 + 90, n)
    return pts


def area2(poly):
    return sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1]
               for i in range(len(poly))) / 2


def inset(poly, d):
    """Move each edge of a counterclockwise outline inward by d (one number, or one per edge i -> i+1)."""
    n = len(poly)
    ds = d if isinstance(d, (list, tuple)) else [d] * n
    lines = []
    for i in range(n):
        p, q = V((*poly[i], 0)), V((*poly[(i + 1) % n], 0))
        t = (q - p).normalized()
        lines.append((p + V((-t.y, t.x, 0)) * ds[i], t))
    out = []
    for i in range(n):
        (p1, t1), (p2, t2) = lines[i - 1], lines[i]
        den = t1.x * t2.y - t1.y * t2.x
        if abs(den) < 1e-9:
            out.append((p2.x, p2.y))
            continue
        w = p2 - p1
        a = (w.x * t2.y - w.y * t2.x) / den
        out.append(((p1 + t1 * a).x, (p1 + t1 * a).y))
    return out


def clean(poly, eps=1e-7):
    out = []
    for p in poly:
        if not out or abs(p[0] - out[-1][0]) > eps or abs(p[1] - out[-1][1]) > eps:
            out.append((p[0], p[1]))
    if len(out) > 2 and abs(out[0][0] - out[-1][0]) <= eps and abs(out[0][1] - out[-1][1]) <= eps:
        out.pop()
    return out


# ------------------------------------------------------------------ solids (bmesh)

def _pt(plane, a, b, d):
    return (a, b, d) if plane == 'xy' else (a, d, b) if plane == 'xz' else (d, a, b)


def _normals(bm):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm


def prism(poly, d0, d1, plane='xy'):
    """A solid from a 2D outline, extruded along the plane's third axis from d0 to d1.
    plane 'xy': outline (x, y), extruded in z; 'xz': (x, z) in y; 'yz': (y, z) in x."""
    poly = clean(poly)
    bm = bmesh.new()
    lo = [bm.verts.new(_pt(plane, a, b, d0)) for a, b in poly]
    hi = [bm.verts.new(_pt(plane, a, b, d1)) for a, b in poly]
    bm.faces.new(lo)
    bm.faces.new(hi)
    for i in range(len(poly)):
        j = (i + 1) % len(poly)
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return _normals(bm)


def box(x0, x1, y0, y1, z0, z1):
    return prism([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], z0, z1)


def ring(outer, inner, d0, d1, plane='xy'):
    """A flat frame between two outlines with matching points, extruded like prism()."""
    bm = bmesh.new()
    oa = [bm.verts.new(_pt(plane, *p, d0)) for p in outer]
    ob = [bm.verts.new(_pt(plane, *p, d1)) for p in outer]
    ia = [bm.verts.new(_pt(plane, *p, d0)) for p in inner]
    ib = [bm.verts.new(_pt(plane, *p, d1)) for p in inner]
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((oa[i], oa[j], ia[j], ia[i]))
        bm.faces.new((ob[i], ib[i], ib[j], ob[j]))
        bm.faces.new((oa[i], ob[i], ob[j], oa[j]))
        bm.faces.new((ia[i], ia[j], ib[j], ib[i]))
    return _normals(bm)


def lathe(profile, segs=48, closed=False, cap=True):
    """Revolve a profile of (r, z) points around Z. Points at r = 0 become poles; open ends get flat caps."""
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        if r < 1e-9:
            rings.append([bm.verts.new((0.0, 0.0, z))])
        else:
            rings.append([bm.verts.new((r * math.cos(TAU * k / segs), r * math.sin(TAU * k / segs), z))
                          for k in range(segs)])
    pairs = list(zip(rings, rings[1:])) + ([(rings[-1], rings[0])] if closed else [])
    for a, b in pairs:
        if len(a) == 1 and len(b) == 1:
            continue
        for k in range(segs):
            j = (k + 1) % segs
            if len(a) == 1:
                bm.faces.new((a[0], b[k], b[j]))
            elif len(b) == 1:
                bm.faces.new((a[k], a[j], b[0]))
            else:
                bm.faces.new((a[k], a[j], b[j], b[k]))
    if cap and not closed:
        for rg in (rings[0], rings[-1]):
            if len(rg) > 1:
                bm.faces.new(rg)
    return _normals(bm)


def fillet(path, r, n=6, closed=False):
    """Round the corners of a polyline (3D, or 2D as z = 0) with arcs of radius r, n segments each;
    r and n may also be lists, one per point (r = 0 keeps a corner)."""
    pts = [V(p) if len(p) == 3 else V((p[0], p[1], 0.0)) for p in path]
    m = len(pts)
    rs = list(r) if isinstance(r, (list, tuple)) else [r] * m
    ns = list(n) if isinstance(n, (list, tuple)) else [n] * m
    out = []
    for i in range(m):
        p = pts[i]
        if (not closed and i in (0, m - 1)) or rs[i] <= 0:
            out.append(p)
            continue
        u, w = pts[i - 1] - p, pts[(i + 1) % m] - p
        lu, lw = u.length, w.length
        u.normalize()
        w.normalize()
        ang = u.angle(w)
        if ang < 1e-4 or ang > math.pi - 1e-4:
            out.append(p)
            continue
        t = min(rs[i] / math.tan(ang / 2), lu * 0.5, lw * 0.5)
        rr = t * math.tan(ang / 2)
        c = p + (u + w).normalized() * (rr / math.sin(ang / 2))
        vs, ve = p + u * t - c, p + w * t - c
        out += [c + vs.slerp(ve, k / ns[i]) * rr for k in range(ns[i] + 1)]     # slerp returns a unit vector
    return out


def tube(path, radius, segs=12, closed=False, cap=True):
    """A round tube along a 3D polyline (run fillet() first for smooth bends)."""
    pts = [V(p) for p in path]
    n = len(pts)
    tans = []
    for i in range(n):
        a = pts[i - 1] if (closed or i > 0) else pts[i]
        b = pts[(i + 1) % n] if (closed or i < n - 1) else pts[i]
        tans.append((b - a).normalized())
    ref = V((0, 0, 1)) if abs(tans[0].z) < 0.9 else V((1, 0, 0))
    nrm = (ref - tans[0] * ref.dot(tans[0])).normalized()
    frames = []
    for t in tans:
        nrm = (nrm - t * nrm.dot(t)).normalized()
        frames.append(nrm.copy())
    if closed:   # spread the twist left at the seam evenly along the loop
        t0 = tans[0]
        back = (frames[-1] - t0 * frames[-1].dot(t0)).normalized()
        twist = math.atan2(t0.dot(back.cross(frames[0])), back.dot(frames[0]))
        frames = [Matrix.Rotation(twist * i / n, 3, tans[i]) @ frames[i] for i in range(n)]
    bm = bmesh.new()
    rings = []
    for p, t, nr in zip(pts, tans, frames):
        bn = t.cross(nr)
        rings.append([bm.verts.new(p + radius * (math.cos(TAU * k / segs) * nr + math.sin(TAU * k / segs) * bn))
                      for k in range(segs)])
    for i in range(n if closed else n - 1):
        a, b = rings[i], rings[(i + 1) % n]
        for k in range(segs):
            j = (k + 1) % segs
            bm.faces.new((a[k], a[j], b[j], b[k]))
    if cap and not closed:
        bm.faces.new(rings[0])
        bm.faces.new(rings[-1])
    return _normals(bm)


def band(path, width, thick, side=(1, 0, 0)):
    """A flat strip along a 3D polyline, `width` along `side` (kept square to the path), `thick` across."""
    pts = [V(p) for p in path]
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        sd = V(side) - t * V(side).dot(t)
        sd.normalize()
        nr = t.cross(sd)
        rings.append([bm.verts.new(p + sd * a + nr * b) for a, b in
                      ((-width / 2, -thick / 2), (width / 2, -thick / 2), (width / 2, thick / 2), (-width / 2, thick / 2))])
    for a, b in zip(rings, rings[1:]):
        for k in range(4):
            j = (k + 1) % 4
            bm.faces.new((a[k], a[j], b[j], b[k]))
    bm.faces.new(rings[0])
    bm.faces.new(rings[-1])
    return _normals(bm)


def torus(R, r, segs=48, rsegs=16):
    return lathe([(R + r * math.cos(TAU * k / rsegs), r * math.sin(TAU * k / rsegs)) for k in range(rsegs)],
                 segs, closed=True)


def beam(p0, p1, w, h, up=(0, 0, 1)):
    """A box from p0 to p1 with cross-section w (across) by h (along `up`, made square to the beam)."""
    p0, p1 = V(p0), V(p1)
    ax = (p1 - p0).normalized()
    u = V(up) - ax * V(up).dot(ax)
    u.normalize()
    s = ax.cross(u)
    bm = bmesh.new()
    vs = [bm.verts.new(p + s * a + u * b) for p in (p0, p1)
          for a, b in ((-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2))]
    bm.faces.new(vs[0:4])
    bm.faces.new(vs[4:8])
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((vs[i], vs[j], vs[4 + j], vs[4 + i]))
    return _normals(bm)


def _along(bm, p0, p1):
    """Stand a solid built along +Z from the origin between p0 and p1."""
    d = V(p1) - V(p0)
    return xform(bm, Matrix.Translation(p0) @ V((0, 0, 1)).rotation_difference(d.normalized()).to_matrix().to_4x4())


def rod(p0, p1, r, segs=24, dome=True):
    """A round bar from p0 to p1 with domed (or flat) ends."""
    n = (V(p1) - V(p0)).length
    if dome:
        prof = ([(r * math.sin(D(a)), r * (1 - math.cos(D(a)))) for a in range(0, 91, 15)] +
                [(r * math.sin(D(a)), n - r * (1 - math.cos(D(a)))) for a in range(90, -1, -15)])
    else:
        prof = [(0.0, 0.0), (r, 0.0), (r, n), (0.0, n)]
    return _along(lathe(prof, segs), p0, p1)


def cyl(p0, p1, r, segs=32):
    return rod(p0, p1, r, segs, dome=False)


def xform(bm, m):
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts[:])
    return bm


def move(bm, x=0.0, y=0.0, z=0.0):
    return xform(bm, Matrix.Translation((x, y, z)))


def rot(bm, deg, axis='Z', about=(0, 0, 0)):
    c = V(about)
    return xform(bm, Matrix.Translation(c) @ Matrix.Rotation(D(deg), 4, axis) @ Matrix.Translation(-c))


def scale(bm, sx, sy, sz):
    return xform(bm, Matrix.Diagonal((sx, sy, sz, 1.0)))


def mirror_x(bm):
    scale(bm, -1, 1, 1)
    return _normals(bm)


def merge(dst, *srcs):
    """Copy the geometry of other bmeshes into dst (keeping face material indices)."""
    for src in srcs:
        vm = {v: dst.verts.new(v.co) for v in src.verts}
        for f in src.faces:
            nf = dst.faces.new([vm[v] for v in f.verts])
            nf.material_index = f.material_index
        src.free()
    return dst


def sym(bm):
    """bm and its mirror image across x = 0, in one mesh."""
    return merge(bm, mirror_x(bm.copy()))


def paint(bm, index):
    for f in bm.faces:
        f.material_index = index
    return bm


# ------------------------------------------------------------------ objects

def obj(name, bm, material, sharp=30.0):
    """An object from a bmesh: its material(s), smooth shading, sharp edges by angle."""
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    for m in (material if isinstance(material, (list, tuple)) else [material]):
        me.materials.append(mat(m))
    me.shade_smooth()
    me.set_sharp_from_angle(angle=D(sharp))
    return ob


def bevel(ob, width, segs=2, angle=30.0):
    """Round every edge sharper than `angle`; hardened normals keep the flats flat."""
    b = ob.modifiers.new('bevel', 'BEVEL')
    b.width = width
    b.segments = segs
    b.limit_method = 'ANGLE'
    b.angle_limit = D(angle)
    b.harden_normals = True
    b.use_clamp_overlap = True
    return ob


def add(name, bm, material, bev=0.0, segs=2, sharp=30.0, parts=None):
    ob = obj(name, bm, material, sharp)
    if bev > 0:
        bevel(ob, bev, segs)
    if parts is not None:
        parts.append(ob)
    return ob


def _bake(ob):
    """Replace an object's mesh by its evaluated mesh (modifiers applied)."""
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
    old = ob.data
    ob.modifiers.clear()
    ob.data = me
    bpy.data.meshes.remove(old)


def union(name, obs, material, sharp=30.0):
    """Merge touching or overlapping solids into one before bevelling, so shared corners have no seam."""
    base = obs[0]
    for o in obs[1:]:
        m = base.modifiers.new('u', 'BOOLEAN')
        m.operation = 'UNION'
        m.solver = 'EXACT'
        m.object = o
        _bake(base)
        bpy.data.objects.remove(o)
    base.name = name
    me = base.data
    me.materials.clear()
    me.materials.append(mat(material))
    for p in me.polygons:
        p.material_index = 0
    me.shade_smooth()
    me.set_sharp_from_angle(angle=D(sharp))
    return base


def difference(ob, cutters, material=None):
    """Cut solids (bmeshes) out of an object, before its bevel; the cut faces take `material`."""
    bevels = [(b.width, b.segments) for b in ob.modifiers if b.type == 'BEVEL']
    for b in [b for b in ob.modifiers if b.type == 'BEVEL']:
        ob.modifiers.remove(b)
    for bm in cutters:
        c = obj('_cut', bm, material or ob.data.materials[0].name)
        m = ob.modifiers.new('d', 'BOOLEAN')
        m.operation = 'DIFFERENCE'
        m.solver = 'EXACT'
        m.material_mode = 'TRANSFER'
        m.object = c
        _bake(ob)
        bpy.data.objects.remove(c)
    ob.data.shade_smooth()
    ob.data.set_sharp_from_angle(angle=D(30))
    for w, sg in bevels:
        bevel(ob, w, sg)
    return ob


def finish(name, parts, origin=None):
    """Apply modifiers and join parts into one object called name; origin (world) defaults to 0, 0, 0."""
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    baked = []
    for ob in parts:
        if ob.modifiers:
            baked.append((ob, bpy.data.meshes.new_from_object(ob.evaluated_get(dg), preserve_all_data_layers=True,
                                                              depsgraph=dg)))
    for ob, me in baked:
        old = ob.data
        ob.modifiers.clear()
        ob.data = me
        bpy.data.meshes.remove(old)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in parts:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    if len(parts) > 1:
        bpy.ops.object.join()
    ob = parts[0]
    ob.name = name
    ob.data.name = name
    if origin is not None:
        ob.data.transform(Matrix.Translation(-V(origin)))
        ob.location = origin
    return ob


# ------------------------------------------------------------------ export, preview, check

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def export(obs, stem):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    path = os.path.join(OUT, stem + '.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True,
                              export_yup=True, export_cameras=False, export_lights=False,
                              export_animations=False, export_materials='EXPORT', export_normals=True)
    print(f'  exported {path}')


def _world_bbox(obs):
    pts = [o.matrix_world @ V(c) for o in obs for c in o.bound_box]
    return (V((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))),
            V((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts))))


def _setup_render():
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = 28
    sc.cycles.use_denoising = True
    sc.cycles.denoiser = 'OPENIMAGEDENOISE'
    sc.cycles.max_bounces = 6
    sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 900, 600, 100
    w = bpy.data.worlds.new('preview_world')
    try:
        w.use_nodes = True
    except AttributeError:
        pass
    bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (0.09, 0.095, 0.105, 1.0)
    sc.world = w


def _helper(name, bm, color):
    ob = bpy.data.objects.new(name, bpy.data.meshes.new(name))
    bm.to_mesh(ob.data)
    bm.free()
    m = bpy.data.materials.new('_' + name)
    m.diffuse_color = (*color, 1)
    try:
        m.use_nodes = True
    except AttributeError:
        pass
    b = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    b.inputs['Base Color'].default_value = (*color, 1)
    b.inputs['Roughness'].default_value = 0.8
    ob.data.materials.append(m)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def render_view(obs, path, view=(0.7, 1.0, 0.45), ground='floor', target=None, dist=None, lens=50, margin=1.08):
    """Render obs with a three-point light from a camera looking along -view, framing their bounds."""
    sc = bpy.context.scene
    if sc.render.engine != 'CYCLES':
        _setup_render()
    lo, hi = _world_bbox(obs)
    tgt = V(target) if target else (lo + hi) / 2
    d = V(view).normalized()
    fwd = -d
    right = fwd.cross(V((0, 0, 1)))
    if right.length < 1e-6:
        right = V((1, 0, 0))
    right.normalize()
    up = right.cross(fwd)
    th, tv = 18.0 / lens, 12.0 / lens
    if dist is None:
        dist = 0.0
        for c in [V((x, y, z)) for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]:
            q = c - tgt
            dist = max(dist, abs(q.dot(right)) / th + q.dot(d), abs(q.dot(up)) / tv + q.dot(d))
        dist *= margin
    cam = bpy.data.objects.new('_cam', bpy.data.cameras.new('_cam'))
    cam.data.lens, cam.data.sensor_width, cam.data.sensor_fit = lens, 36, 'HORIZONTAL'
    cam.data.clip_start, cam.data.clip_end = 0.005, 500
    cam.location = tgt + d * dist
    cam.rotation_euler = fwd.to_track_quat('-Z', 'Y').to_euler()
    sc.collection.objects.link(cam)
    sc.camera = cam
    helpers = [cam]
    for name, vec, energy in (('_key', (-0.9, 0.9, 1.3), 3.2), ('_fill', (1.2, 0.7, 0.35), 1.1),
                              ('_rim', (0.4, -1.3, 1.0), 2.4)):
        lt = bpy.data.objects.new(name, bpy.data.lights.new(name, 'SUN'))
        lt.data.energy = energy
        lt.data.angle = D(8)
        rel = V(vec)
        # keep the key light on the camera's side whichever way the camera looks
        rel = V((rel.x * (1 if d.y >= 0 else -1), rel.y * (1 if d.y >= 0 else -1), rel.z))
        lt.rotation_euler = rel.normalized().to_track_quat('Z', 'Y').to_euler()
        sc.collection.objects.link(lt)
        helpers.append(lt)
    size = max((hi - lo).length * 6, 8.0)
    if ground == 'floor':
        helpers.append(_helper('_floor', box(-size, size, -size, size, -0.02, 0.0), (0.42, 0.42, 0.43)))
    elif ground == 'wall':
        helpers.append(_helper('_wall', box(-size, size, -0.02, 0.0, -size, size), (0.42, 0.42, 0.43)))
    elif ground == 'ceiling':   # hanging lights: a ceiling over them and a wall behind, casting no shadows
        dh = V((d.x, d.y, 0)).normalized()
        side = dh.cross(V((0, 0, 1)))
        c = tgt - dh * ((hi - lo).length + 0.8)
        wall = [c + side * a + V((0, 0, b)) for a, b in ((size, -size), (size, size), (-size, size), (-size, -size))]
        for h in (_helper('_ceiling', box(-size, size, -size, size, hi.z + 0.45, hi.z + 0.47), (0.42, 0.42, 0.43)),
                  _helper('_backdrop', slab(wall, dh, -0.02, 0.0), (0.42, 0.42, 0.43))):
            h.visible_shadow = False
            helpers.append(h)
    shown = set(o.name for o in obs) | set(h.name for h in helpers)
    hidden = [o for o in sc.objects if o.name not in shown and not o.hide_render]
    for o in hidden:
        o.hide_render = True
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hidden:
        o.hide_render = False
    for h in helpers:
        bpy.data.objects.remove(h)
    print(f'  rendered {path}')


def verify(stem):
    """Import the .glb into an empty scene and report its objects, sizes and materials."""
    reset()
    bpy.ops.import_scene.gltf(filepath=os.path.join(OUT, stem + '.glb'))
    obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    lo, hi = _world_bbox(obs)
    info = {'objects': [], 'size': tuple(hi - lo), 'lo': tuple(lo), 'hi': tuple(hi), 'materials': set()}
    for o in obs:
        ms = [s.material.name for s in o.material_slots if s.material]
        info['materials'] |= set(ms)
        info['objects'].append((o.name, tuple(round(x, 3) for x in o.dimensions), tuple(round(x, 3) for x in o.location),
                                sorted(ms), len(o.data.polygons)))
    print(f'  check {stem}.glb: size {tuple(round(x, 3) for x in info["size"])}')
    for row in info['objects']:
        print('    ', row)
    return info


# ------------------------------------------------------------------ 1. the pickup truck

X0 = 1.0   # nominal half width of the truck body: side panels are built with their skin at x = X0, then warped
SIDE = [(0.30, 0.968), (0.47, 0.975), (0.62, 0.995), (1.02, 1.000), (1.33, 0.957), (1.87, 0.822), (2.00, 0.790)]
BREAKS = [0.47, 0.62, 1.02, 1.33, 1.87]


def side_x(z):
    """Half width of the truck's skin at height z: rocker tuck, shoulder line, tumblehome of the glass."""
    if z <= SIDE[0][0]:
        return SIDE[0][1]
    for (z0, x0), (z1, x1) in zip(SIDE, SIDE[1:]):
        if z <= z1:
            return x0 + (x1 - x0) * (z - z0) / (z1 - z0)
    return SIDE[-1][1]


def warp(bm):
    """Give a panel built with its skin at x = +-X0 the body's cross-section, cutting it at the creases."""
    for z in BREAKS:
        zs = [v.co.z for v in bm.verts]
        if min(zs) < z - 1e-5 and max(zs) > z + 1e-5:
            bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-6,
                                   plane_co=(0, 0, z), plane_no=(0, 0, 1))
    for v in bm.verts:
        if abs(v.co.x) > 1e-9:
            v.co.x += (side_x(v.co.z) - X0) * (1.0 if v.co.x > 0 else -1.0)
    return bm


def skin(poly, inner, outer=0.0):
    """A panel on the truck's +X side: outline (y, z), from `inner` to `outer` metres in from the skin."""
    return warp(prism(poly, X0 - inner, X0 - outer, 'yz'))


def build_truck():
    body, door = [], []
    PANEL = 5.5                                  # body panels are flats: mark even gentle creases sharp
    WF, WR, AR, AZ = 1.95, -1.75, 0.48, 0.42     # axles, wheel arch radius and centre height
    ZB, ZBELT, ZD0 = 0.47, 1.33, 0.53            # body sides' lower edge, beltline, door bottoms
    YC = 1.235                                   # back of the front clip (fenders, hood, grille)
    YDF0, YDF1, YDR0, YDR1 = 1.229, 0.081, 0.075, -0.843    # front and rear doors, front and rear edges
    YCAB = -0.97                                 # back of the cab
    YB0, YB1 = -1.00, -2.775                     # bed, front and back

    def A(name, bm, m, bev=0.0, segs=2, sharp=30.0, to=None):
        return add(name, bm, m, bev, segs, sharp, body if to is None else to)

    def both(name, bm, m, bev=0.0, segs=2, sharp=30.0):
        """A part on the +X side and its mirror image."""
        A(name, mirror_x(bm.copy()), m, bev, segs, sharp)
        return A(name, bm, m, bev, segs, sharp)

    def arch(yc, n=36, reverse=False):
        a0 = math.degrees(math.asin((ZB - AZ) / AR))
        pts = arc(yc, AZ, AR, a0, 180 - a0, n)
        return pts[::-1] if reverse else pts

    def hood(y):
        return 1.285 - 0.0505 * (y - YC)

    # --- front clip: fenders, hood and the grille face in one solid; the arch tunnel is filled by the engine
    fc = [(YC, ZB), (YC, hood(YC)), (2.62, hood(2.62)), (2.71, 1.200), (2.765, 1.185), (2.790, 1.165),
          (2.805, 1.125), (2.815, 0.78), (2.80, 0.60), (2.79, ZB)] + arch(WF)
    A('front_clip', skin(fc, 2 * X0), 'paint', 0.025, 5, PANEL)
    dome = prism([(-0.40, 1.45), (0.40, 1.45), (0.34, 2.55), (-0.34, 2.55)], -0.012, 0.014)
    for v in dome.verts:
        v.co.z += hood(v.co.y)
    A('hood_dome', dome, 'paint', 0.012, 3, PANEL)
    go = rrect(-0.56, 0.56, 0.78, 1.16, 0.05)
    A('grille_surround', ring(go, inset(go, 0.055), 2.78, 2.848, 'xz'), 'chrome', 0.008, 2)
    A('grille_mesh', box(-0.51, 0.51, 2.78, 2.826, 0.83, 1.11), 'black', 0.004, 1)
    for zc in (0.925, 1.015):
        A('grille_bar', box(-0.51, 0.51, 2.79, 2.838, zc - 0.02, zc + 0.02), 'chrome', 0.008, 2)
    both('headlight', box(0.60, 0.968, 2.74, 2.828, 1.00, 1.14), 'headlight', 0.01, 2)
    both('turn_signal', box(0.60, 0.968, 2.74, 2.826, 0.935, 0.995), 'amber_marker', 0.008, 2)
    both('side_marker', skin([(2.56, 0.955), (2.66, 0.955), (2.66, 1.005), (2.56, 1.005)], 0.01, -0.004),
         'amber_marker', 0.004, 1)
    A('bumper_f', prism(rrect(-0.99, 0.99, 2.60, 2.905, [0, 0.16, 0.16, 0], 8), 0.44, 0.76), 'chrome', 0.015, 3)
    A('bumper_f_strip', prism(rrect(-0.62, 0.62, 2.80, 2.909, [0, 0.02, 0.02, 0], 3), 0.575, 0.60), 'black',
      0.004, 1)
    A('valance_f', prism(rrect(-0.92, 0.92, 2.62, 2.87, [0, 0.12, 0.12, 0], 6), 0.33, 0.445), 'black', 0.01, 2)
    A('plate_f', box(-0.152, 0.152, 2.905, 2.912, 0.595, 0.747), 'paper', 0.003, 1)

    # --- the cab shell: roof, pillars, back wall and rockers merged, so its corners have no seams
    WS0, WS1 = (1.29, 1.30), (0.63, 1.862)       # the windshield's side edge in side view, (y, z)

    def ws_y(z):
        return WS0[0] + (z - WS0[1]) * (WS1[0] - WS0[0]) / (WS1[1] - WS0[1])

    pl = [V((s * (side_x(z) - 0.05), ws_y(z), z)) for s, z in ((1, 1.30), (1, 1.848), (-1, 1.848), (-1, 1.30))]
    wsn = (pl[1] - pl[0]).cross(pl[3] - pl[0]).normalized()
    if wsn.y < 0:
        wsn = -wsn
    shell = []
    rp = [(side_x(1.845) - 0.005, 1.845), (side_x(1.90) - 0.005, 1.90), (0.0, 1.90)]
    rp = [(p.x, p.y) for p in fillet([V((x, z, 0)) for x, z in rp], 0.032, 6)]
    roof = prism([(-x, z) for x, z in reversed(rp)] + rp[:-1], YCAB, ws_y(1.845), 'xz')
    for v in roof.verts:
        if v.co.y > 0:
            v.co.y = ws_y(v.co.z) + 0.012
    shell.append(obj('roof', roof, 'paint'))
    for s in (1, -1):
        a0 = V((s * (side_x(1.26) - 0.05), ws_y(1.26), 1.26)) - wsn * 0.017
        a1 = V((s * (side_x(1.88) - 0.05), ws_y(1.88), 1.88)) - wsn * 0.017
        shell.append(obj('a_pillar', beam(a0, a1, 0.09, 0.05, wsn), 'paint'))
        cp = skin([(-0.849, ZD0), (-0.849, ZBELT), (-0.769, 1.845), (YCAB, 1.845), (YCAB, ZD0)], 0.06)
        rk = skin([(1.232, ZB), (1.232, 0.527), (YCAB, 0.527), (YCAB, ZB)], 0.20)
        if s < 0:
            cp, rk = mirror_x(cp), mirror_x(rk)
        shell += [obj('c_pillar', cp, 'paint'), obj('rocker', rk, 'paint')]
    bw_side = [(side_x(z), z) for z in (ZB, 0.62, 1.02, ZBELT, 1.845)]
    hole = rrect(-0.62, 0.62, 1.42, 1.79, 0.06, 6)
    shell.append(obj('back_wall', ring_poly([(-x, z) for x, z in reversed(bw_side)] + bw_side, hole,
                                            YCAB, YCAB + 0.04), 'paint'))
    cab = union('cab', shell, 'paint', PANEL)
    bevel(cab, 0.008, 2)
    body.append(cab)
    A('windshield', slab(pl, wsn, -0.012, -0.006), 'glass')
    A('cowl', box(-0.86, 0.86, 1.235, 1.33, 1.272, 1.297), 'black', 0.006, 1)
    for xc in (-0.42, 0.30):
        A('wiper', beam((xc - 0.33, ws_y(1.33), 1.33), (xc + 0.33, ws_y(1.33), 1.33), 0.02, 0.012, wsn),
          'black', 0.003, 1)
    A('rear_glass', box(-0.63, 0.63, YCAB + 0.012, YCAB + 0.018, 1.41, 1.80), 'glass')
    A('rear_frame', ring(hole, inset(hole, 0.025), YCAB - 0.004, YCAB + 0.012, 'xz'), 'black', 0.003, 1)
    for xc in (-0.21, 0.21):
        A('rear_divider', box(xc - 0.015, xc + 0.015, YCAB - 0.003, YCAB + 0.02, 1.42, 1.79), 'black', 0.003, 1)
    A('brake_light', box(-0.13, 0.13, YCAB - 0.008, YCAB + 0.004, 1.806, 1.83), 'taillight', 0.003, 1)

    # --- doors: panels, black window frames (a U with no member on the belt), glass, belt strips, handles, trim
    front_frame = [(ws_y(ZBELT) - 0.08, ZBELT), (ws_y(1.842) - 0.08, 1.842), (YDF1 + 0.003, 1.842),
                   (YDF1 + 0.003, ZBELT)]
    fi = inset(front_frame, [0.035, 0.035, 0.045, 0.0])
    t = (1.47 - fi[0][1]) / (fi[1][1] - fi[0][1])        # a black sail at the front of the window for the mirror
    front_inner = [(fi[0][0] - 0.10, ZBELT), (fi[0][0] + (fi[1][0] - fi[0][0]) * t, 1.47)] + fi[1:]
    rear_frame = [(YDR0 - 0.003, ZBELT), (YDR0 - 0.003, 1.842), (-0.762, 1.842), (YDR1 + 0.004, ZBELT)]
    rear_inner = inset(rear_frame, [0.045, 0.035, 0.035, 0.0])
    for s in (1, -1):
        for which, (y0, y1), frame, inner, hy in (('front', (YDF0, YDF1), front_frame, front_inner, 0.23),
                                                  ('rear', (YDR0, YDR1), rear_frame, rear_inner, -0.70)):
            to = door if (s > 0 and which == 'front') else body
            low = rrect(y1, y0, ZD0, ZBELT, [0.03, 0, 0, 0.03], 4)
            glass = [(p[0], ZBELT - 0.04) if p[1] <= ZBELT + 1e-6 else p for p in inner]
            pieces = [
                ('door_panel', skin(low, 0.10), 'paint', 0.006, 2, PANEL),
                ('window_frame', skin(frame + inner[::-1], 0.045, 0.006), 'black', 0.005, 2, PANEL),
                ('door_glass', skin(glass, 0.030, 0.024), 'glass', 0, 2, 30),
                ('belt_strip', skin([(y0 - 0.004, ZBELT - 0.008), (y1 + 0.004, ZBELT - 0.008),
                                     (y1 + 0.004, ZBELT + 0.012), (y0 - 0.004, ZBELT + 0.012)], 0.036, 0.004),
                 'black', 0.004, 1, 30),
                ('door_handle', skin([(hy - 0.08, 1.112), (hy + 0.08, 1.112), (hy + 0.08, 1.146),
                                      (hy - 0.08, 1.146)], 0.002, -0.017), 'black', 0.006, 2, 30),
                ('door_trim', skin(rrect(y1 + 0.045, y0 - 0.045, 0.62, ZBELT - 0.03, 0.02, 3), 0.135, 0.10),
                 'dark', 0.01, 2, 30),
                ('armrest', skin([(y0 - 0.12, 1.00), (y1 + 0.10, 1.00), (y1 + 0.10, 1.065), (y0 - 0.12, 1.065)],
                                 0.20, 0.13), 'dark', 0.012, 2, 30),
            ]
            for name, bmp, m, bv, sg, sh in pieces:
                A(name, bmp if s > 0 else mirror_x(bmp), m, bv, sg, sh, to)
        for name, bmp, m, bv, sg in (('mirror', box(0.995, 1.215, 1.075, 1.17, 1.345, 1.60), 'black', 0.022, 4),
                                     ('mirror_glass', box(1.008, 1.202, 1.068, 1.076, 1.358, 1.587), 'chrome',
                                      0.004, 1),
                                     ('mirror_arm', box(0.925, 1.0, 1.095, 1.15, 1.37, 1.43), 'black', 0.01, 2)):
            A(name, bmp if s > 0 else mirror_x(bmp), m, bv, sg, 30, door if s > 0 else body)
    both('b_pillar', skin([(0.12, 0.527), (0.12, 1.845), (0.035, 1.845), (0.035, 0.527)], 0.19, 0.105), 'paint',
         0.008, 2, PANEL)
    both('sill_plate', skin([(1.232, 0.527), (1.232, 0.60), (YCAB + 0.002, 0.60), (YCAB + 0.002, 0.527)], 0.20,
                            0.105), 'black', 0.006, 2)

    # --- the bed: sides and bulkhead as one box, floor with its humps, liner, tailgate, lamps, bumper
    bed_side = [(YB0, ZB), (YB0, ZBELT), (YB1, ZBELT), (YB1, ZB)] + arch(WR, reverse=True)
    parts = [obj('bed_side', skin(bed_side, 0.13), 'paint'), obj('bed_side', mirror_x(skin(bed_side, 0.13)), 'paint')]
    bh_side = [(side_x(z) - 0.02, z) for z in (0.55, 0.62, 1.02, ZBELT)]
    parts.append(obj('bulkhead', prism([(-x, z) for x, z in reversed(bh_side)] + bh_side, YB0 - 0.05, YB0, 'xz'),
                     'paint'))
    bed = union('bed', parts, 'paint', PANEL)
    bevel(bed, 0.012, 3)
    body.append(bed)
    both('rail_cap', skin([(YB0 - 0.004, ZBELT), (YB1 + 0.004, ZBELT), (YB1 + 0.004, ZBELT + 0.018),
                           (YB0 - 0.004, ZBELT + 0.018)], 0.142, 0.004), 'black', 0.005, 2)
    both('bed_liner', skin([(YB0 - 0.05, 0.80), (YB1 + 0.06, 0.80), (YB1 + 0.06, 1.315), (YB0 - 0.05, 1.315)],
                           0.145, 0.128), 'black', 0.004, 1)
    hump = prism([(WR - 0.50 * math.cos(math.pi * k / 16), 0.76 + 0.29 * math.sin(math.pi * k / 16))
                  for k in range(17)], X0 - 0.38, X0 - 0.125, 'yz')
    both('wheel_hump', warp(hump), 'black', 0.012, 2)
    both('tail_light', skin([(YB1 - 0.016, 0.86), (YB1 + 0.055, 0.86), (YB1 + 0.055, 1.29), (YB1 - 0.016, 1.29)],
                            0.125, -0.003), 'taillight', 0.008, 2)
    both('reverse_light', skin([(YB1 - 0.018, 0.935), (YB1 + 0.056, 0.935), (YB1 + 0.056, 0.995),
                                (YB1 - 0.018, 0.995)], 0.12, -0.004), 'plastic_light', 0.004, 1)
    fl = [(-0.868, YB1 + 0.06), (0.868, YB1 + 0.06), (0.868, WR - 0.50), (0.62, WR - 0.50), (0.62, WR + 0.50),
          (0.868, WR + 0.50), (0.868, YB0 - 0.05), (-0.868, YB0 - 0.05), (-0.868, WR + 0.50), (-0.62, WR + 0.50),
          (-0.62, WR - 0.50), (-0.868, WR - 0.50)]
    A('bed_floor', prism(fl, 0.76, 0.80), 'black', 0.004, 1)
    for xc in (-0.46, -0.23, 0.0, 0.23, 0.46):
        A('bed_rib', box(xc - 0.014, xc + 0.014, YB1 + 0.10, YB0 - 0.09, 0.80, 0.812), 'black', 0.004, 1)
    tg_side = [(side_x(z) - 0.136, z) for z in (0.58, 0.62, 1.02, 1.322)]
    A('tailgate', prism([(-x, z) for x, z in reversed(tg_side)] + tg_side, YB1, YB1 + 0.06, 'xz'), 'paint', 0.008,
      2, PANEL)
    tgc = [(side_x(z) - 0.140, z) for z in (1.322, 1.342)]
    A('tailgate_cap', prism([(-x, z) for x, z in reversed(tgc)] + tgc, YB1 - 0.004, YB1 + 0.064, 'xz'), 'black',
      0.005, 2)
    A('tailgate_handle', box(-0.13, 0.13, YB1 - 0.008, YB1 + 0.002, 1.19, 1.25), 'black', 0.006, 2)
    A('bumper_r', prism(rrect(-0.95, 0.95, -2.905, -2.74, [0.07, 0, 0, 0.07], 6), 0.45, 0.69), 'chrome', 0.012, 3)
    A('bumper_r_step', box(-0.34, 0.34, -2.895, -2.775, 0.69, 0.697), 'black', 0.003, 1)
    A('plate_r_recess', box(-0.18, 0.18, -2.908, -2.90, 0.478, 0.66), 'black', 0.004, 1)
    A('plate_r', rot(box(-0.152, 0.152, -2.913, -2.906, 0.493, 0.645), 2.5, 'Y', (0, -2.91, 0.57)), 'paper',
      0.003, 1)                                    # a bit crooked
    both('running_board', prism(rrect(0.87, 1.05, -0.80, 1.12, 0.05, 4), 0.39, 0.43), 'black', 0.008, 2)
    for yb in (-0.55, 0.20, 0.90):
        both('board_bracket', box(0.50, 0.90, yb - 0.03, yb + 0.03, 0.405, 0.47), 'black', 0.005, 1)
    A('hitch', box(-0.036, 0.036, -2.97, -2.70, 0.37, 0.442), 'black', 0.006, 1)

    # --- underneath: frame, engine, driveline, axle, exhaust, wheel arch liners
    both('frame_rail', box(0.40, 0.50, -2.72, 2.62, 0.30, 0.47), 'black', 0.006, 1)
    A('engine', box(-0.56, 0.56, 1.36, 2.56, 0.34, 1.00), 'black', 0.02, 2)
    A('driveshaft', tube([(0, 1.36, 0.42), (0, WR + 0.12, 0.40)], 0.045, 12), 'black')
    A('axle', tube([(-0.72, WR, 0.40), (0.72, WR, 0.40)], 0.05, 12), 'black')
    A('diff', move(lathe([(0, -0.13), (0.09, -0.12), (0.13, -0.04), (0.13, 0.04), (0.09, 0.12), (0, 0.13)], 24),
                   0.05, WR, 0.40), 'black')
    A('exhaust', tube(fillet([(0.30, -0.4, 0.30), (0.62, -1.3, 0.30), (0.62, -2.80, 0.30)], 0.3), 0.035, 12),
      'black')
    liner = arch(0.0, 36) + [(y * 0.95, AZ + (z - AZ) * 0.95) for y, z in reversed(arch(0.0, 36))]
    for yc in (WF, WR):
        both('arch_liner', prism([(y + yc, z) for y, z in liner], 0.60, 0.975, 'yz'), 'black')

    # --- wheels: tire with a rounded tread and two grooves, a dished chrome rim with dark windows
    tire_p = [(0.216, -0.108), (0.232, -0.121), (0.262, -0.130), (0.300, -0.1335), (0.340, -0.1325),
              (0.368, -0.128), (0.386, -0.120), (0.396, -0.108), (0.400, -0.092), (0.400, -0.046),
              (0.392, -0.042), (0.392, -0.030), (0.400, -0.026), (0.400, 0.026), (0.392, 0.030), (0.392, 0.042),
              (0.400, 0.046), (0.400, 0.092), (0.396, 0.108), (0.386, 0.120), (0.368, 0.128), (0.340, 0.1325),
              (0.300, 0.1335), (0.262, 0.130), (0.232, 0.121), (0.216, 0.108)]
    rim_p = [(0.0, 0.074), (0.052, 0.074), (0.060, 0.066), (0.078, 0.057), (0.150, 0.057), (0.186, 0.062),
             (0.201, 0.078), (0.208, 0.097), (0.222, 0.101), (0.228, 0.095), (0.221, 0.080), (0.216, -0.10),
             (0.0, -0.10)]
    steel_p = [(0.0, 0.052), (0.042, 0.052), (0.05, 0.046), (0.062, 0.030), (0.182, 0.030), (0.196, 0.050),
               (0.205, 0.080), (0.210, 0.097), (0.222, 0.100), (0.227, 0.094), (0.220, 0.080), (0.216, -0.10),
               (0.0, -0.10)]

    def wheel(m, steel=False):
        """Tire, rim and the dark windows in it, axis along +Z (outer face up), placed by the matrix m."""
        wins = bmesh.new()
        for k in range(6 if not steel else 8):
            a = 60 * k
            merge(wins, prism(arc(0, 0, 0.145, a + 12, a + 48, 6) + arc(0, 0, 0.088, a + 44, a + 16, 4),
                              0.0575, 0.0595) if not steel else
                  prism(circle(0.02, 16, 0.152 * math.cos(D(45 * k + 22.5)), 0.152 * math.sin(D(45 * k + 22.5))),
                        0.0295, 0.0315))
        rim = ('rim', lathe(rim_p, 64), 'chrome', 0.004) if not steel else \
            ('steel_rim', lathe(steel_p, 64), 'plastic_light', 0.004)
        return [(name, _normals(xform(b, m)), mm, bv) for name, b, mm, bv in
                (('tire', lathe(tire_p, 64, closed=True), 'tire', 0), rim, ('rim_window', wins, 'black', 0.003))]

    for yc in (WF, WR):
        for s in (1, -1):
            m = Matrix.Translation((s * 0.85, yc, 0.40)) @ Matrix.Diagonal((s, 1, 1, 1)) @ Matrix.Rotation(D(90), 4, 'Y')
            # a bit tired: the spare is on the rear right, a silver steel wheel among the chrome ones
            for name, b, mm, bv in wheel(m, steel=(yc == WR and s > 0)):
                A(name, b, mm, bv, 1)

    # --- inside the cab
    A('cab_floor', box(-0.80, 0.80, YCAB + 0.04, 1.215, 0.56, 0.60), 'black', 0.005, 1)
    A('firewall', box(-0.82, 0.82, 1.205, 1.232, 0.60, 1.05), 'black', 0.004, 1)
    dash = [(1.232, 0.90), (1.232, 1.278), (1.10, 1.300), (0.93, 1.292), (0.84, 1.255), (0.785, 1.18),
            (0.78, 1.06), (0.83, 0.96), (0.95, 0.885), (1.10, 0.865)]
    A('dashboard', prism(dash, -0.84, 0.84, 'yz'), 'dark', 0.015, 3)
    A('cluster_hood', prism([(1.02, 1.27), (0.93, 1.345), (0.845, 1.34), (0.82, 1.26)], -0.63, -0.21, 'yz'), 'dark',
      0.012, 2)
    A('cluster', box(-0.60, -0.24, 0.86, 0.90, 1.19, 1.31), 'black', 0.004, 1)
    A('radio', box(-0.13, 0.13, 0.775, 0.80, 0.99, 1.20), 'black', 0.005, 1)
    col = V((0, -0.92, 0.39)).normalized()
    wc = V((-0.40, 0.66, 1.205))
    A('column', tube([wc - col * 0.33, wc - col * 0.04], 0.034, 16), 'black', 0.006, 1)
    swm = Matrix.Translation(wc) @ V((0, 0, 1)).rotation_difference(col).to_matrix().to_4x4()
    A('steering_wheel', xform(torus(0.19, 0.017, 48, 12), swm), 'black')
    A('wheel_hub', xform(lathe([(0, -0.03), (0.07, -0.03), (0.075, 0.0), (0.06, 0.022), (0, 0.025)], 32), swm),
      'black')
    for a in (0, 180, 270):
        A('spoke', xform(beam((0, 0, 0), (0.18 * math.cos(D(a)), 0.18 * math.sin(D(a)), 0), 0.04, 0.012), swm),
          'black', 0.004, 1)
    for xc in (-0.40, 0.40):     # front bucket seats
        A('seat_base', box(xc - 0.19, xc + 0.19, 0.16, 0.50, 0.60, 0.87), 'black', 0.01, 1)
        A('seat', prism([(0.585, 0.86), (0.585, 0.962), (0.535, 0.985), (0.15, 0.955), (0.10, 0.935), (0.10, 0.86)],
                        xc - 0.25, xc + 0.25, 'yz'), 'cloth', 0.022, 4)
        A('seat_back', prism([(0.13, 0.94), (0.035, 1.53), (-0.075, 1.515), (0.02, 0.925)], xc - 0.25, xc + 0.25,
                             'yz'), 'cloth', 0.024, 4)
        A('headrest', prism([(0.03, 1.585), (0.005, 1.74), (-0.075, 1.73), (-0.05, 1.575)], xc - 0.13, xc + 0.13,
                            'yz'), 'cloth', 0.02, 4)
        for px in (xc - 0.07, xc + 0.07):
            A('headrest_post', box(px - 0.005, px + 0.005, -0.03, -0.02, 1.52, 1.59), 'chrome')
    A('console', box(-0.13, 0.13, 0.14, 0.74, 0.60, 0.95), 'dark', 0.015, 2)
    A('bench_base', box(-0.78, 0.78, -0.80, -0.36, 0.60, 0.87), 'black', 0.01, 1)
    A('bench', prism([(-0.30, 0.86), (-0.30, 0.972), (-0.35, 0.995), (-0.78, 0.965), (-0.82, 0.94), (-0.82, 0.86)],
                     -0.80, 0.80, 'yz'), 'cloth', 0.022, 4)
    A('bench_back', prism([(-0.80, 0.965), (-0.855, 1.55), (-0.925, 1.545), (-0.925, 0.955)], -0.80, 0.80, 'yz'),
      'cloth', 0.024, 4)
    for xc in (-0.52, 0.0, 0.52):
        A('headrest', prism([(-0.85, 1.575), (-0.87, 1.68), (-0.925, 1.675), (-0.925, 1.57)], xc - 0.13, xc + 0.13,
                            'yz'), 'cloth', 0.018, 4)
    A('headliner', box(-0.775, 0.775, YCAB + 0.04, 0.62, 1.815, 1.845), 'plastic_light', 0.008, 2)
    A('dome_light', box(-0.09, 0.09, 0.20, 0.30, 1.804, 1.816), 'dome', 0.004, 1)
    both('sun_visor', box(0.08, 0.70, 0.50, 0.60, 1.795, 1.814), 'plastic_light', 0.006, 2)
    A('mirror_stem', box(-0.012, 0.012, 0.60, 0.68, 1.79, 1.815), 'black', 0.003, 1)
    A('rear_view', box(-0.12, 0.12, 0.60, 0.635, 1.715, 1.79), 'black', 0.008, 2)
    A('rear_view_glass', box(-0.11, 0.11, 0.596, 0.60, 1.723, 1.782), 'chrome', 0.002, 1)

    truck = finish('truck', body)
    pdoor = finish('passenger_door', door, origin=(X0, YDF0, ZD0))
    pdoor.rotation_euler = (0, 0, D(52))
    return [result('truck', [truck, pdoor], dict(view=(0.78, 1.0, 0.36)),
                   [dict(view=(-0.8, -1.0, 0.45)), dict(view=(1.0, 0.02, 0.12)), dict(view=(0.35, -0.5, 1.2)),
                    dict(view=(1.0, -0.35, 0.25), target=(0.3, 0.5, 1.1), dist=3.2),
                    dict(view=(0.2, 1.0, 0.15), target=(0, 1.9, 0.9), dist=5.5)])]


def result(stem, obs, view, extra=(), export=True):
    """What a builder hands back: a file's objects, its preview camera, extra review views."""
    return dict(stem=stem, obs=obs, view=view, extra=list(extra), export=export)


# ------------------------------------------------------------------ 2. the pub's main doors

def build_doors():
    W, H, T, SW, TR, BR = 0.86, 2.25, 0.05, 0.07, 0.10, 0.14    # leaf: width, height, thickness, stile, rails
    h = T / 2
    leaf = []

    def L(name, bm, m, bev=0.0, segs=2):
        return add(name, bm, m, bev, segs, 30.0, leaf)

    # stiles and rails butt together like the real extrusions, so the corner joints show as hairlines
    L('hinge_stile', box(0, SW, -h, h, 0, H), 'bronze', 0.004)
    L('lock_stile', box(W - SW, W, -h, h, 0, H), 'bronze', 0.004)
    L('top_rail', box(SW, W - SW, -h, h, H - TR, H), 'bronze', 0.004)
    L('bottom_rail', box(SW, W - SW, -h, h, 0, BR), 'bronze', 0.004)
    opening = [(SW, BR), (W - SW, BR), (W - SW, H - TR), (SW, H - TR)]
    for y0, y1 in ((0.003, h - 0.006), (-(h - 0.006), -0.003)):     # glazing stops round the glass, both faces
        L('glazing_stop', ring(opening, inset(opening, 0.016), y0, y1, 'xz'), 'bronze', 0.002, 1)
    L('glass', box(SW - 0.006, W - SW + 0.006, -0.003, 0.003, BR - 0.006, H - TR + 0.006), 'glass')
    L('kick_plate', box(0.02, W - 0.02, h, h + 0.0025, 0.012, BR - 0.008), 'brass', 0.001, 1)
    # push bar on the room side (+Y) at 1.02 m, on standoffs from the stiles
    zb, yb = 1.02, h + 0.068
    L('push_bar', rod((0.012, yb, zb), (W - 0.012, yb, zb), 0.016), 'chrome')
    for xs in (SW / 2, W - SW / 2):
        L('standoff', cyl((xs, h, zb), (xs, yb, zb), 0.0115, 24), 'chrome', 0.0015, 1)
        L('escutcheon', cyl((xs, h, zb), (xs, h + 0.005, zb), 0.021, 32), 'chrome', 0.0015, 1)
    # street side (-Y): a pull handle and the key cylinder on the lock stile
    xp, yp = W - SW / 2, -h - 0.058
    L('pull', rod((xp, yp, 0.86), (xp, yp, 1.24), 0.0145), 'chrome')
    for zs in (0.90, 1.20):
        L('pull_standoff', cyl((xp, -h, zs), (xp, yp, zs), 0.011, 24), 'chrome', 0.0015, 1)
    L('key_cylinder', cyl((xp, -h, 1.34), (xp, -h - 0.007, 1.34), 0.016, 32), 'brass', 0.0015, 1)
    L('thumb_turn', cyl((xp, h, 1.34), (xp, h + 0.006, 1.34), 0.018, 32), 'bronze', 0.0015, 1)
    L('thumb_turn_grip', box(xp - 0.004, xp + 0.004, h + 0.006, h + 0.02, 1.34 - 0.014, 1.34 + 0.014), 'bronze',
      0.002, 1)
    # surface closer on the top rail, its arm folded along the door to a shoe on the top edge
    L('closer', box(0.078, 0.372, h, h + 0.058, 2.163, 2.237), 'bronze', 0.008, 2)
    L('closer_pinion', cyl((0.11, h + 0.03, 2.237), (0.11, h + 0.03, 2.250), 0.013, 24), 'bronze', 0.002, 1)
    L('closer_arm', beam((0.11, h + 0.03, 2.256), (0.47, h + 0.035, 2.262), 0.026, 0.012, (0, 1, 0)), 'bronze',
      0.003, 1)
    L('closer_shoe', box(0.45, 0.50, h + 0.012, h + 0.058, 2.25, 2.272), 'bronze', 0.004, 1)
    left = finish('door_leaf_left', leaf)
    right = left.copy()
    right.data = left.data.copy()
    right.data.transform(Matrix.Diagonal((-1, 1, 1, 1)))
    right.data.flip_normals()
    right.name = right.data.name = 'door_leaf_right'
    bpy.context.scene.collection.objects.link(right)

    fr = []

    def F(name, bm, m, bev=0.0, segs=2):
        return add(name, bm, m, bev, segs, 30.0, fr)

    OW, OH, P, DP = 1.80, 2.34, 0.09, 0.16          # opening, frame profile face width and depth
    F('jamb', box(-OW / 2 - P, -OW / 2, -DP / 2, DP / 2, 0, OH), 'bronze', 0.004)
    F('jamb', box(OW / 2, OW / 2 + P, -DP / 2, DP / 2, 0, OH), 'bronze', 0.004)
    F('head', box(-OW / 2 - P, OW / 2 + P, -DP / 2, DP / 2, OH, OH + P), 'bronze', 0.004)
    for s in (-1, 1):   # door stops on the room side of the leaves
        F('stop', box(min(s * OW / 2, s * (OW / 2 - 0.015)), max(s * OW / 2, s * (OW / 2 - 0.015)), 0.028, 0.062, 0,
                      OH), 'bronze', 0.002, 1)
    F('stop', box(-OW / 2, OW / 2, 0.028, 0.062, OH - 0.012, OH), 'bronze', 0.002, 1)
    # threshold: a fluted saddle with bevelled edges, 13 mm high
    th = [(-0.115, 0.0), (-0.072, 0.013)]
    for yc in (-0.048, -0.024, 0.0, 0.024, 0.048):
        th += [(yc - 0.004, 0.013), (yc - 0.0025, 0.0105), (yc + 0.0025, 0.0105), (yc + 0.004, 0.013)]
    th += [(0.072, 0.013), (0.115, 0.0)]
    F('threshold', prism(th, -OW / 2, OW / 2, 'yz'), 'chrome', 0.0015, 1)
    frame = finish('door_frame', fr)

    # review only: the pair hung in the frame, the right leaf swung a little open
    hung_l = left.copy()
    hung_r = right.copy()
    for o in (hung_l, hung_r):
        bpy.context.scene.collection.objects.link(o)
    hung_l.location = (-0.875, 0, 0.012)
    hung_r.location = (0.875, 0, 0.012)
    hung_r.rotation_euler = (0, 0, D(35))
    view = dict(view=(0.45, 1.0, 0.25))
    return [result('door_leaf_left', [left], view, [dict(view=(-0.5, -1.0, 0.3))]),
            result('door_leaf_right', [right], dict(view=(-0.45, 1.0, 0.25))),
            result('door_frame', [frame], view, [dict(view=(0.3, 1.0, 0.8), target=(0, 0, 0.02), dist=1.6)]),
            result('doors_hung', [frame, hung_l, hung_r], dict(view=(0.55, 1.0, 0.3)),
                   [dict(view=(0.2, 1.0, 0.05), target=(0.5, 0, 1.05), dist=1.4),
                    dict(view=(0.3, 1.0, 0.1), target=(-0.6, 0, 2.2), dist=1.4)], export=False)]


# ------------------------------------------------------------------ 3. the props on his ledge

ALONG_X = Matrix(((0, 0, 1, 0), (1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 0, 1)))   # built along +Z, +Y up -> along +X, +Z up


def pen(kind):
    """A pen along +Z from its writing end at z = 0, clip on +Y: a list of (name, bmesh, material, bevel)."""
    if kind == 'bic':            # hexagonal barrel, black cap with a clip over the tip, end plug
        clip = merge(band([(0, 0.0052, 0.005), (0, 0.0052, 0.030)], 0.0026, 0.0011),
                     box(-0.0013, 0.0013, 0.0038, 0.0058, 0.0285, 0.0335))
        return [('barrel', lathe([(0, 0.016), (0.0038, 0.016), (0.0038, 0.1335), (0, 0.1335)], 6), 'plastic_light',
                 0.0004),
                ('tip', lathe([(0, 0.0025), (0.0009, 0.003), (0.0033, 0.0165), (0, 0.0165)], 24), 'plastic_light', 0),
                ('plug', lathe([(0, 0.133), (0.0026, 0.133), (0.0026, 0.1375), (0.0019, 0.139), (0, 0.139)], 16),
                 'black', 0),
                ('cap', lathe([(0, -0.003), (0.0028, -0.0028), (0.0041, -0.0016), (0.0045, 0.002), (0.0045, 0.035),
                               (0, 0.035)], 24), 'black', 0.0003),
                ('clip', clip, 'black', 0.0003)]
    if kind == 'click':          # round dark barrel, chrome clip and tip cone, plunger
        clip = merge(band([(0, 0.0056, 0.098), (0, 0.0056, 0.132)], 0.003, 0.0011),
                     box(-0.0015, 0.0015, 0.0044, 0.0062, 0.128, 0.134))
        return [('barrel', lathe([(0, 0.014), (0.0046, 0.016), (0.0048, 0.13), (0.0044, 0.136), (0, 0.136)], 24),
                 'dark', 0),
                ('tip', lathe([(0, 0.0), (0.0006, 0.0006), (0.0022, 0.006), (0.0040, 0.015), (0, 0.015)], 24),
                 'chrome', 0),
                ('plunger', lathe([(0, 0.135), (0.0028, 0.135), (0.0028, 0.143), (0.002, 0.1445), (0, 0.1445)], 16),
                 'black', 0),
                ('clip', clip, 'chrome', 0.0003)]
    if kind == 'marker':         # black cap with a clip at the tip end, dark barrel
        clip = merge(band([(0, 0.0082, 0.010), (0, 0.0082, 0.046)], 0.0038, 0.0014),
                     box(-0.0019, 0.0019, 0.0065, 0.0089, 0.044, 0.050))
        return [('barrel', lathe([(0, 0.045), (0.0066, 0.045), (0.0066, 0.125), (0.0058, 0.132), (0, 0.133)], 24),
                 'dark', 0),
                ('cap', lathe([(0, -0.001), (0.0052, 0.0), (0.0071, 0.004), (0.0071, 0.052), (0, 0.052)], 24),
                 'black', 0.0004),
                ('clip', clip, 'black', 0.0004)]
    # a plain wooden pencil, sharpened, with a brass ferrule and a red eraser
    return [('pencil', lathe([(0, 0.021), (0.0042, 0.021), (0.0042, 0.172), (0, 0.172)], 6), 'wood', 0.0003),
            ('pencil_cone', lathe([(0, 0.004), (0.0013, 0.004), (0.0037, 0.021), (0, 0.021)], 24), 'wood', 0),
            ('lead', lathe([(0, 0.0), (0.0004, 0.0006), (0.0013, 0.0042), (0, 0.0042)], 16), 'black', 0),
            ('ferrule', lathe([(0, 0.171), (0.0043, 0.171), (0.0044, 0.182), (0, 0.182)], 24), 'brass', 0.0003),
            ('eraser', lathe([(0, 0.181), (0.0039, 0.181), (0.0039, 0.188), (0.003, 0.1895), (0, 0.1895)], 24),
             'vinyl', 0)]


def build_ledge():
    props = []

    def prop(name, x, fill):
        parts = []

        def A(n, bm, m, bev=0.0, segs=2):
            return add(n, bm, m, bev, segs, 30.0, parts)
        fill(A, parts)
        ob = finish(name, parts)
        ob.location.x = x
        props.append(ob)

    def scanner(A, parts):
        # a squat dark plastic body; the top slopes down towards the operator (-Y) and carries the screen
        prof = [(0.065, 0.004), (0.065, 0.064), (0.059, 0.0705), (0.028, 0.0705), (-0.042, 0.016), (-0.065, 0.016),
                (-0.065, 0.004)]
        body = obj('scanner_body', prism(prof, -0.10, 0.10, 'yz'), 'dark')
        difference(body, [box(-0.046, 0.046, -0.08, -0.045, 0.0085, 0.0118)], 'black')      # the licence slot
        parts.append(bevel(body, 0.004, 3))
        ds = V((0, -0.070, -0.0545)).normalized()
        slope = Matrix(((1, 0, 0, 0), (0, ds.y, ds.z, 0.028), (0, ds.z, -ds.y, 0.0705), (0, 0, 0, 1)))

        def on_slope(bm):
            return _normals(xform(bm, slope))
        outer, inner = rrect(-0.086, 0.086, 0.005, 0.071, 0.004), rrect(-0.049, 0.049, 0.010, 0.066, 0.002)
        A('bezel', on_slope(ring(outer, inner, 0.0, 0.0016)), 'black', 0.0006, 1)
        A('screen', on_slope(box(-0.0495, 0.0495, 0.0095, 0.0665, 0.0, 0.0008)), 'screen')
        for xb in (-0.021, 0.0):
            A('button', on_slope(cyl((xb, 0.079, 0), (xb, 0.079, 0.0024), 0.0038)), 'black', 0.0006, 1)
        A('led', on_slope(cyl((0.066, 0.079, 0), (0.066, 0.079, 0.0012), 0.0016, 16)), 'screen')
        # the tray in front of the slot, with side guides
        A('tray', box(-0.047, 0.047, -0.081, -0.064, 0.004, 0.0068), 'dark', 0.001, 1)
        for s in (-1, 1):
            A('tray_guide', box(min(s * 0.043, s * 0.047), max(s * 0.043, s * 0.047), -0.081, -0.064, 0.0068,
                                0.0092), 'dark', 0.0008, 1)
            for t in (-1, 1):
                A('foot', cyl((s * 0.080, t * 0.050, 0), (s * 0.080, t * 0.050, 0.0045), 0.006, 24), 'rubber',
                  0.001, 1)
        # the cable out of the back, down to the counter and away
        A('strain_relief', cyl((-0.062, 0.060, 0.026), (-0.062, 0.082, 0.026), 0.0048, 24), 'black', 0.001, 1)
        A('cable', tube(fillet([(-0.062, 0.075, 0.026), (-0.062, 0.094, 0.026), (-0.064, 0.114, 0.0027),
                                (-0.072, 0.165, 0.0027), (-0.084, 0.215, 0.0027), (-0.088, 0.262, 0.0027)], 0.012, 6),
                         0.0027, 12), 'black')

    def clicker(A, parts):
        # a chrome hand tally counter lying on its back, plunger towards +Y, finger ring towards -Y
        prof = [(0, 0.0), (0.010, 0.0003), (0.018, 0.0014), (0.0226, 0.0036), (0.0241, 0.0064), (0.0243, 0.0100),
                (0.0237, 0.0128), (0.0223, 0.0150), (0.0206, 0.0155), (0.0196, 0.0147), (0.0188, 0.0140), (0, 0.0140)]
        body = obj('counter_body', lathe(prof, 64), 'chrome')
        difference(body, [box(-0.0135, 0.0135, -0.0010, 0.0090, 0.0124, 0.02)], 'black')   # the digit window
        parts.append(bevel(body, 0.0003, 1))
        for k in range(4):
            x0 = -0.0128 + k * 0.0065
            A('digit_wheel', cyl((x0, 0.004, 0.0093), (x0 + 0.0056, 0.004, 0.0093), 0.0045, 24), 'dark', 0.0003, 1)
        A('plunger_stem', cyl((0, 0.022, 0.0078), (0, 0.031, 0.0078), 0.0028, 24), 'chrome')
        A('plunger', _along(lathe([(0, 0), (0.0062, 0), (0.0066, 0.0008), (0.0066, 0.0038), (0.0052, 0.0054),
                                   (0, 0.0058)], 32), (0, 0.030, 0.0078), (0, 0.040, 0.0078)), 'chrome')
        A('ring_lug', box(-0.003, 0.003, -0.0268, -0.020, 0.0012, 0.0050), 'chrome', 0.0006, 1)
        A('finger_ring', move(torus(0.0105, 0.0022, 48, 12), 0, -0.0336, 0.0023), 'chrome')
        A('reset_knob', cyl((0.0236, 0.0085, 0.0078), (0.0294, 0.0085, 0.0078), 0.0036, 24), 'chrome', 0.0005, 1)

    def book(A, parts):
        # the incident log: a black cloth ledger, closed, spine to the left (-X) as he sees it, head to +Y
        W2, H2, TH, XS = 0.115, 0.150, 0.032, -0.100
        cover = rrect(XS, W2, -H2, H2, [0.009, 0.013, 0.0, 0.0], 5)        # the open corners worn round
        A('back_board', prism(cover, 0.0, 0.003), 'black', 0.0008, 1)
        A('front_board', prism(cover, TH - 0.003, TH), 'black', 0.0008, 1)
        spine = arc(XS, TH / 2, TH / 2, 90, 270, 12) + arc(XS, TH / 2, TH / 2 - 0.0022, 270, 90, 12)
        A('spine', prism(spine, -H2, H2, 'xz'), 'black', 0.0005, 1)
        fore = [(XS, 0.003), (0.112, 0.003), (0.1126, 0.007), (0.1103, 0.012), (0.1093, 0.016), (0.1103, 0.020),
                (0.1126, 0.025), (0.112, 0.029), (XS, 0.029)]
        A('pages', prism(fore, -(H2 - 0.003), H2 - 0.003, 'xz'), 'paper', 0.0004, 1)
        # the board showing through at the worn tips of the front cover's open corners
        for (cx, cy, a0, r) in ((W2 - 0.009, -H2 + 0.009, -90, 0.009), (W2 - 0.013, H2 - 0.013, 0, 0.013)):
            tipp = arc(cx, cy, r, a0, a0 + 90, 5)
            e0 = (tipp[0][0] - 0.010 if a0 == -90 else tipp[0][0], tipp[0][1] if a0 == -90 else tipp[0][1] - 0.010)
            e1 = (tipp[-1][0], tipp[-1][1] + 0.010) if a0 == -90 else (tipp[-1][0] - 0.010, tipp[-1][1])
            A('worn_corner', prism([e0] + tipp + [e1], TH - 0.0004, TH + 0.0003), 'dark')
        A('label', prism(rrect(-0.045, 0.065, 0.080, 0.126, 0.004, 3), TH - 0.0003, TH + 0.0004), 'paper', 0.0002,
          1)
        A('ribbon', band(fillet([(0.03, -0.140, 0.016), (0.03, -0.152, 0.016), (0.031, -0.158, 0.010),
                                 (0.033, -0.163, 0.0035), (0.036, -0.176, 0.0006), (0.041, -0.20, 0.0006)], 0.004, 4),
                         0.007, 0.0005), 'vinyl')
        # the pen lying across the cover, clip up
        place = Matrix.Translation((-0.062, -0.040, TH + 0.0045)) @ Matrix.Rotation(D(22), 4, 'Z') @ ALONG_X
        for n, bm, m, bv in pen('bic'):
            A('pen_' + n, _normals(xform(bm, place)), m, bv, 1)

    def lighter(A, parts):
        # a disposable lighter, built standing, then laid on its broad side with its top towards +X
        def stadium(w, d, n=8):
            r = d / 2
            return arc(w / 2 - r, 0, r, -90, 90, n) + arc(-w / 2 + r, 0, r, 90, 270, n)
        bits = [('lighter_body', prism(stadium(0.024, 0.012), 0.0, 0.064), 'vinyl', 0.0025, 3),
                ('hood', ring(stadium(0.0206, 0.0104), stadium(0.0196, 0.0094), 0.0605, 0.079), 'chrome', 0.0003, 1),
                ('burner', cyl((0.003, 0, 0.064), (0.003, 0, 0.0745), 0.0016, 16), 'chrome', 0, 1),
                ('flint_wheel', cyl((-0.0048, -0.0040, 0.0768), (-0.0048, 0.0040, 0.0768), 0.0046, 24), 'dark',
                 0.0004, 1),
                ('gas_lever', box(0.0012, 0.0088, -0.0034, 0.0034, 0.064, 0.0760), 'black', 0.0006, 1)]
        lay = Matrix.Translation((-0.041, 0, 0.006)) @ ALONG_X
        for n, bm, m, bv, sg in bits:
            A(n, _normals(xform(bm, lay)), m, bv, sg)

    def mug(A, parts):
        # a heavy white diner mug, chipped at the rim, handle to +X, a few pens in it
        prof = [(0, 0.0032), (0.030, 0.0032), (0.0322, 0.0006), (0.0345, 0.0), (0.0372, 0.0), (0.0395, 0.0018),
                (0.0408, 0.006), (0.0412, 0.020), (0.0412, 0.088), (0.0409, 0.0930), (0.0400, 0.0953),
                (0.0385, 0.0962), (0.0370, 0.0957), (0.0359, 0.0940), (0.0355, 0.0920), (0.0355, 0.014),
                (0.0345, 0.0105), (0.0320, 0.0090), (0, 0.0088)]
        body = obj('mug', lathe(prof, 96), 'ceramic')
        a = D(-118)
        chip = xform(lathe([(0, -1), (0.5, -0.87), (0.87, -0.5), (1, 0), (0.87, 0.5), (0.5, 0.87), (0, 1)], 24),
                     Matrix.Translation((0.0445 * math.cos(a), 0.0445 * math.sin(a), 0.0985)) @
                     Matrix.Rotation(a, 4, 'Z') @ Matrix.Rotation(D(-25), 4, 'Y') @
                     Matrix.Diagonal((0.0080, 0.0085, 0.0066, 1)))
        difference(body, [chip])
        parts.append(body)
        hp = fillet([(0.0385, 0, 0.081), (0.0605, 0, 0.083), (0.0665, 0, 0.060), (0.0615, 0, 0.027),
                     (0.0385, 0, 0.022)], 0.012, 6)
        A('handle', scale(tube(hp, 0.0047, 16), 1, 1.25, 1), 'ceramic')
        for kind, bottom, lean, turn in (('bic', (0.012, 0.011), 9, 45), ('marker', (-0.013, 0.009), 7, 150),
                                         ('pencil', (-0.004, -0.015), 10, 250), ('click', (0.013, -0.011), 7, 320)):
            p0 = V((bottom[0], bottom[1], 0.0092))
            d = V((math.sin(D(lean)) * math.cos(D(turn)), math.sin(D(lean)) * math.sin(D(turn)), math.cos(D(lean))))
            up = kind == 'pencil'                   # the pencil stands tip up, the pens tip down
            for n, bm, m, bv in pen(kind):
                if up:
                    xform(bm, Matrix.Translation((0, 0, 0.1895)) @ Matrix.Diagonal((1, 1, -1, 1)))
                    _normals(bm)
                A(kind + '_' + n, _along(bm, p0, p0 + d), m, bv, 1)

    prop('scanner', 0.0, scanner)
    prop('clicker', 0.19, clicker)
    prop('book', 0.40, book)
    prop('lighter', 0.60, lighter)
    prop('mug', 0.74, mug)
    close = [dict(view=(0.15, -1.0, 0.9), target=(x, 0.0, z), dist=d) for x, z, d in
             ((0.0, 0.035, 0.42), (0.19, 0.01, 0.16), (0.40, 0.02, 0.55), (0.60, 0.006, 0.16), (0.74, 0.07, 0.40))]
    return [result('ledge_props', props, dict(view=(0.22, -1.0, 0.95)),
                   close + [dict(view=(0.6, 1.0, 0.5)), dict(view=(-0.8, -0.5, 0.35), target=(0.0, 0.0, 0.035),
                                                              dist=0.45)])]


# ------------------------------------------------------------------ 4. stools

def stool(stem, SH, ring_r, ring_z, tape=False):
    """A cheap pub stool: weighted base plate on a rubber rim, chrome post, foot ring on four struts,
    a swivel, and a round vinyl cushion with a welt round its top edge. SH is the seat height."""
    P = []

    def A(n, bm, m, bev=0.0, segs=2):
        return add(n, bm, m, bev, segs, 30.0, P)
    A('base_plate', lathe([(0, 0.036), (0.06, 0.0342), (0.13, 0.0262), (0.182, 0.0182), (0.195, 0.0148),
                           (0.1995, 0.0118), (0.199, 0.0092), (0.194, 0.0082), (0, 0.0082)], 96), 'chrome', 0.0015, 1)
    A('foot_rim', lathe([(0.168, 0.0), (0.197, 0.0), (0.2, 0.0035), (0.1995, 0.0088), (0.166, 0.0088),
                         (0.166, 0.002)], 96, closed=True), 'rubber', 0.0015, 1)
    A('post_boss', lathe([(0, 0.034), (0.046, 0.034), (0.046, 0.041), (0.040, 0.048), (0.032, 0.056),
                          (0.029, 0.066), (0, 0.066)], 48), 'chrome', 0.0015, 1)
    A('post', cyl((0, 0, 0.05), (0, 0, SH - 0.088), 0.0254, 48), 'chrome')
    A('foot_ring', move(torus(ring_r, 0.0105, 96, 16), 0, 0, ring_z), 'chrome')
    A('ring_collar', lathe([(0, ring_z - 0.018), (0.034, ring_z - 0.018), (0.036, ring_z - 0.014),
                            (0.036, ring_z + 0.014), (0.034, ring_z + 0.018), (0, ring_z + 0.018)], 48), 'chrome')
    for k in range(4):
        a = D(45 + 90 * k)
        A('strut', cyl((0.03 * math.cos(a), 0.03 * math.sin(a), ring_z),
                       ((ring_r - 0.004) * math.cos(a), (ring_r - 0.004) * math.sin(a), ring_z), 0.0075, 16), 'chrome')
    A('swivel', lathe([(0, SH - 0.094), (0.075, SH - 0.094), (0.082, SH - 0.088), (0.10, SH - 0.078),
                       (0.10, SH - 0.072), (0, SH - 0.072)], 48), 'black', 0.002, 1)
    A('seat_pan', lathe([(0, SH - 0.072), (0.160, SH - 0.072), (0.166, SH - 0.068), (0.166, SH - 0.060),
                         (0, SH - 0.060)], 96), 'black', 0.002, 1)
    z0 = SH - 0.060           # the cushion: 6 cm of vinyl, a band round the side, a domed top a little sat-in
    top = [(0.170, 0.0515), (0.160, 0.0550), (0.140, 0.0574), (0.110, 0.0590), (0.075, 0.0598), (0.040, 0.0592),
           (0.0, 0.0588)]
    prof = [(0, 0.0), (0.160, 0.0), (0.170, 0.0022), (0.1765, 0.0085), (0.1788, 0.020), (0.1790, 0.034),
            (0.1776, 0.045), (0.1745, 0.0505)] + top
    A('cushion', lathe([(r, z0 + z) for r, z in prof], 96), 'vinyl')
    A('welt', move(torus(0.1742, 0.0048, 96, 12), 0, 0, z0 + 0.0505), 'vinyl')
    if tape:     # a split in the vinyl patched with a strip of black tape
        def top_z(r):
            pts = [(0.1745, 0.0505)] + top
            for (r0, z0_), (r1, z1_) in zip(pts, pts[1:]):
                if r1 <= r <= r0:
                    return z0_ + (z1_ - z0_) * (r - r0) / (r1 - r0)
            return top[-1][1]
        a = D(28)
        path = [V((t * math.cos(a) + 0.02, t * math.sin(a) - 0.01, 0)) for t in [-0.11 + 0.22 * k / 16 for k in range(17)]]
        path = [V((p.x, p.y, z0 + top_z(p.length) + 0.0004)) for p in path]
        A('tape', band(path, 0.048, 0.0006, side=(-math.sin(a), math.cos(a), 0)), 'black')
    return finish(stem, P)


def build_stools():
    bar = stool('stool_bar', 0.76, 0.20, 0.30, tape=True)
    low = stool('stool_low', 0.64, 0.17, 0.24)
    low.location.x = 0.0
    view = dict(view=(0.55, 1.0, 0.5))
    return [result('stool_bar', [bar], view, [dict(view=(0.3, 0.6, 1.0), target=(0, 0, 0.72), dist=0.9),
                                              dict(view=(0.6, 1.0, 0.1), target=(0, 0, 0.1), dist=1.0)]),
            result('stool_low', [low], view)]


# ------------------------------------------------------------------ 5. tables

def build_tables():
    P = []

    def A(n, bm, m, bev=0.0, segs=2):
        return add(n, bm, m, bev, segs, 30.0, P)
    # the square one: a solid wood top on a cast-iron column and a four-armed foot, arms on the diagonals
    A('top', prism(rrect(-0.40, 0.40, -0.40, 0.40, 0.03, 6), 0.74, 0.78), 'wood', 0.009, 5)
    for a in (45, 135):
        A('spider', rot(box(-0.26, 0.26, -0.022, 0.022, 0.726, 0.74), a), 'black', 0.003, 1)
    A('column', lathe([(0, 0.07), (0.066, 0.07), (0.066, 0.082), (0.056, 0.092), (0.047, 0.108), (0.041, 0.13),
                       (0.038, 0.16), (0.038, 0.60), (0.041, 0.625), (0.047, 0.64), (0.050, 0.652), (0.046, 0.664),
                       (0.056, 0.676), (0.056, 0.712), (0.075, 0.716), (0.075, 0.726), (0, 0.726)], 48), 'black',
      0.002, 1)
    A('hub', lathe([(0, 0.014), (0.080, 0.014), (0.088, 0.022), (0.086, 0.045), (0.074, 0.064), (0.060, 0.074),
                    (0, 0.074)], 48), 'black', 0.003, 2)
    arm = [(0.04, 0.018), (0.10, 0.022), (0.16, 0.028), (0.22, 0.026), (0.268, 0.016), (0.284, 0.012),
           (0.306, 0.012), (0.312, 0.020), (0.308, 0.032), (0.28, 0.040), (0.20, 0.052), (0.12, 0.064),
           (0.06, 0.072), (0.04, 0.072)]
    for k in range(4):
        bm = prism(arm, -0.022, 0.022, 'xz')
        for v in bm.verts:                      # taper the arm towards its tip
            v.co.y *= 1.0 - 0.35 * max(0.0, v.co.x - 0.04) / 0.27
        A('arm', rot(bm, 45 + 90 * k), 'black', 0.003, 2)
        a = D(45 + 90 * k)
        A('glide', cyl((0.293 * math.cos(a), 0.293 * math.sin(a), 0.0), (0.293 * math.cos(a), 0.293 * math.sin(a),
                                                                          0.0125), 0.017, 24), 'rubber', 0.002, 1)
    square = finish('table_square', P)

    P = []
    # table 28: a big round top, a heavy turned column on a domed cast-iron disc foot
    edge = arc(0.838, 0.768, 0.012, 90, 0, 5)
    A('top', lathe([(0, 0.78)] + edge + [(0.85, 0.742), (0.838, 0.730), (0, 0.730)], 160), 'wood', 0.002, 1)
    for a in (0, 90):
        A('spider', rot(box(-0.46, 0.46, -0.028, 0.028, 0.712, 0.730), a), 'black', 0.003, 1)
    A('spider_plate', lathe([(0, 0.704), (0.14, 0.704), (0.14, 0.712), (0, 0.712)], 48), 'black', 0.002, 1)
    A('column', lathe([(0, 0.09), (0.12, 0.09), (0.12, 0.104), (0.10, 0.118), (0.088, 0.14), (0.080, 0.18),
                       (0.076, 0.24), (0.076, 0.58), (0.080, 0.61), (0.090, 0.628), (0.098, 0.644), (0.098, 0.658),
                       (0.088, 0.668), (0.104, 0.68), (0.104, 0.704), (0, 0.704)], 64), 'black', 0.002, 1)
    A('foot', lathe([(0, 0.100), (0.12, 0.100), (0.16, 0.086), (0.25, 0.062), (0.34, 0.044), (0.40, 0.034),
                     (0.418, 0.028), (0.422, 0.018), (0.42, 0.006), (0.412, 0.0), (0, 0.0)], 128), 'black', 0.003, 2)
    rnd = finish('table_round', P)
    view = dict(view=(0.55, 1.0, 0.55))
    return [result('table_square', [square], view, [dict(view=(0.7, 0.8, 0.12), target=(0, 0, 0.2), dist=1.6)]),
            result('table_round', [rnd], view, [dict(view=(0.6, 1.0, 0.15), target=(0, 0, 0.3), dist=2.4)])]


def ring_poly(outer, hole, y0, y1):
    """A wall in the XZ plane (outline `outer`, a hole `hole`), extruded from y0 to y1: rays from the hole's
    centre pair up points on both outlines so the face between them is quads."""
    cx = sum(p[0] for p in hole) / len(hole)
    cz = sum(p[1] for p in hole) / len(hole)
    n = 96

    def hit(poly, ang):
        d = (math.cos(ang), math.sin(ang))
        best = None
        for i in range(len(poly)):
            (x1, z1), (x2, z2) = poly[i], poly[(i + 1) % len(poly)]
            ex, ez = x2 - x1, z2 - z1
            den = d[0] * ez - d[1] * ex
            if abs(den) < 1e-12:
                continue
            t = ((x1 - cx) * ez - (z1 - cz) * ex) / den
            u = ((x1 - cx) * d[1] - (z1 - cz) * d[0]) / den
            if t > 0 and -1e-9 <= u <= 1 + 1e-9 and (best is None or t < best):
                best = t
        return (cx + d[0] * best, cz + d[1] * best)
    # sample both outlines at the same angles, plus every corner of the outer one
    angs = sorted(set([round(TAU * k / n, 9) for k in range(n)] +
                      [round(math.atan2(z - cz, x - cx) % TAU, 9) for x, z in outer + hole]))
    o = [hit(outer, a) for a in angs]
    h = [hit(hole, a) for a in angs]
    return ring(o, h, y0, y1, 'xz')


def slab(corners, nrm, d0, d1):
    """A flat plate through 3D corners (a convex outline), offset along nrm from d0 to d1."""
    bm = bmesh.new()
    lo = [bm.verts.new(V(c) + nrm * d0) for c in corners]
    hi = [bm.verts.new(V(c) + nrm * d1) for c in corners]
    bm.faces.new(lo)
    bm.faces.new(hi)
    n = len(corners)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return _normals(bm)


# ------------------------------------------------------------------ shells (lights)

def loft(rings, cap0=True, cap1=True):
    """Join closed rings of 3D points (all the same length) with quads, and cap the two ends flat."""
    bm = bmesh.new()
    vs = [[bm.verts.new(V(p)) for p in rg] for rg in rings]
    n = len(vs[0])
    for a, b in zip(vs, vs[1:]):
        for k in range(n):
            j = (k + 1) % n
            bm.faces.new((a[k], a[j], b[j], b[k]))
    if cap0:
        bm.faces.new(vs[0])
    if cap1:
        bm.faces.new(vs[-1])
    return _normals(bm)


def offset_line(pts, d):
    """An open 2D polyline moved to its right by d (mitred corners)."""
    P = [V((p[0], p[1], 0.0)) for p in pts]
    out = []
    for i in range(len(P)):
        tans = []
        if i > 0:
            tans.append((P[i] - P[i - 1]).normalized())
        if i < len(P) - 1:
            tans.append((P[i + 1] - P[i]).normalized())
        nr = V((0, 0, 0))
        for t in tans:
            nr += V((t.y, -t.x, 0))
        nr.normalize()
        k = nr.dot(V((tans[0].y, -tans[0].x, 0)))
        q = P[i] + nr * (d / max(k, 0.3))
        out.append((q.x, q.y))
    return out


def two_tone(bm, outward):
    """Material 0 on the faces that look outward (away from outward(centre)'s axis) or up, 1 on the rest:
    the enamel outside and the white inside of a lamp shade."""
    for f in bm.faces:
        o = outward(f.calc_center_median())
        f.material_index = 0 if f.normal.dot(o) + f.normal.z > 0 else 1
    return bm


def socket_and_bulb(A, x=0.0, y=0.0, top=0.0):
    """A black lamp holder hanging from height `top`, with a round 6 cm bulb in it."""
    A('socket', move(lathe([(0, 0), (0.028, 0), (0.028, -0.005), (0.0215, -0.007), (0.0215, -0.053),
                            (0.0195, -0.057), (0.0135, -0.0585), (0, -0.0585)], 48), x, y, top), 'black', 0.0012, 1)
    zc, r = -0.1045, 0.030
    prof = [(0, -0.057), (0.0122, -0.057), (0.0122, -0.0655), (0.0131, -0.0705), (0.0158, -0.0748)]
    prof += [(r * math.sin(D(a)), zc + r * math.cos(D(a))) for a in range(36, 181, 8)]
    A('bulb', move(lathe(prof, 48), x, y, top), 'bulb')


# ------------------------------------------------------------------ 6. the pendant light

def build_pendant():
    P = []

    def A(n, bm, m, bev=0.0, segs=2):
        return add(n, bm, m, bev, segs, 30.0, P)
    t, rb = 0.0015, 0.0045                    # sheet steel thickness; radius of the rolled rim
    Rt, Rb, H = 0.07, 0.24, 0.20               # the cone: radius at the top and at the rim, height
    rim = (Rb - rb, -(H - rb))                 # centre of the rolled rim: its outside is 48 cm across, 20 cm down
    outer = [(p.x, p.y) for p in fillet([(0, 0), (Rt, 0), rim], 0.014, 8)]
    inner = offset_line(outer, t)
    A('shade', two_tone(lathe(outer + inner[::-1], 96), lambda c: V((c.x, c.y, 0)).normalized()),
      ['dark', 'plastic_light'])
    A('rim', move(torus(rim[0], rb, 96, 12), 0, 0, rim[1]), 'dark')
    socket_and_bulb(A, top=-t)
    pendant = finish('pendant', P)
    return [result('pendant', [pendant], dict(view=(0.4, 1.0, -0.7), ground='ceiling'),
                   [dict(view=(0.6, 1.0, 0.45), ground=None), dict(view=(0.05, 0.08, -1.0), ground='ceiling')])]


# ------------------------------------------------------------------ 7. the pool table and its light

def build_pool():
    P = []

    def A(n, bm, m, bev=0.0, segs=2):
        return add(n, bm, m, bev, segs, 30.0, P)
    XO, YO = 1.10, 0.65                 # outside of the rails: 2.2 x 1.3
    XB, YB = 1.00, 0.525                # back of the cushions = inside edge of the wooden rails
    XN, YN = 0.95, 0.475                # cushion noses: a 1.90 x 0.95 playfield
    ZB, ZR, ZR0, ZC = 0.80, 0.848, 0.785, 0.44    # bed (playing surface), rail top, rail underside, cabinet bottom
    XE, YE = 1.05, 0.60                 # outside of the cabinet under the rails
    pockets = ([(sx * 0.978, sy * 0.503, 0.068) for sx in (-1, 1) for sy in (-1, 1)] +
               [(0.0, sy * 0.517, 0.066) for sy in (-1, 1)])

    def holes(z0, z1):
        return [cyl((x, y, z0), (x, y, z1), r, 64) for x, y, r in pockets]

    # the wooden rails, the pockets cut out of them
    rail = obj('rail', ring(rrect(-XO, XO, -YO, YO, 0.035, 8), rrect(-XB, XB, -YB, YB, 0.002, 8), ZR0, ZR),
               'wood_dark')
    difference(rail, holes(ZR0 - 0.05, ZR + 0.05))
    P.append(bevel(rail, 0.008, 4))
    # the bed: slate under felt, holed at the pockets
    bed = obj('bed', box(-XB, XB, -YB, YB, ZB - 0.025, ZB), 'felt')
    difference(bed, holes(ZB - 0.1, ZB + 0.1))
    P.append(bevel(bed, 0.003, 1))
    # six felt cushions; their ends (the jaws) angled into the pockets
    prof = [(0.0, ZB), (0.021, ZB), (0.0465, ZB + 0.028), (0.0492, ZB + 0.0325), (0.0500, ZB + 0.0362),
            (0.0487, ZB + 0.0398), (0.0440, ZB + 0.0428), (0.030, ZB + 0.0445), (0.0, ZB + 0.046)]
    kc, ks, m = 1.0, 0.25, 0.085        # jaw slope at corner and side pockets; corner jaws' distance from the corner

    def cushion(o, t, n, s0, s1):
        bm = bmesh.new()
        o, t, n = V(o), V(t), V(n)
        a = [bm.verts.new(o + t * s0(u) + n * u + V((0, 0, z))) for u, z in prof]
        b = [bm.verts.new(o + t * s1(u) + n * u + V((0, 0, z))) for u, z in prof]
        bm.faces.new(a)
        bm.faces.new(b)
        for i in range(len(prof)):
            j = (i + 1) % len(prof)
            bm.faces.new((a[i], a[j], b[j], b[i]))
        return _normals(bm)
    for sy in (-1, 1):
        for sx in (-1, 1):          # long rails: from the side pocket out to the corner
            A('cushion', cushion((0, sy * YB, 0), (sx, 0, 0), (0, -sy, 0), lambda u: 0.0625 + ks * u,
                                 lambda u: XN - m + kc * (0.05 - u)), 'felt', 0.002, 1)
    for sx in (-1, 1):              # end rails
        A('cushion', cushion((sx * XB, 0, 0), (0, 1, 0), (-sx, 0, 0), lambda u: -(YN - m + kc * (0.05 - u)),
                             lambda u: YN - m + kc * (0.05 - u)), 'felt', 0.002, 1)
    # black pocket liners: a lip on the rail and a cup below the bed
    for x, y, r in pockets:
        lp = [(r - 0.0045, ZB - 0.068), (r - 0.0005, ZB - 0.068), (r - 0.0005, ZR), (r + 0.011, ZR),
              (r + 0.0135, ZR + 0.0022), (r + 0.011, ZR + 0.0045), (r - 0.0015, ZR + 0.0045), (r - 0.0045, ZR + 0.0015)]
        liner = obj('pocket', move(lathe(lp, 64, closed=True), x, y, 0), 'black')
        difference(liner, [box(-XB, XB, -YB, YB, ZB + 0.0005, ZR + 0.05)])
        P.append(bevel(liner, 0.0012, 1))
        A('pocket_floor', move(lathe([(0, ZB - 0.074), (r - 0.001, ZB - 0.074), (r - 0.001, ZB - 0.066),
                                      (0, ZB - 0.066)], 64), x, y, 0), 'black')
    # sights on the rails
    for x in (-0.7125, -0.475, -0.2375, 0.2375, 0.475, 0.7125):
        for sy in (-1, 1):
            A('sight', cyl((x, sy * (YB + YO) / 2, ZR - 0.001), (x, sy * (YB + YO) / 2, ZR + 0.0006), 0.0055, 20),
              'plastic_light')
    for y in (-0.2375, 0.0, 0.2375):
        for sx in (-1, 1):
            A('sight', cyl((sx * (XB + XO) / 2, y, ZR - 0.001), (sx * (XB + XO) / 2, y, ZR + 0.0006), 0.0055, 20),
              'plastic_light')
    # the cabinet (apron) under the rails: open-topped walls on a bottom board, the ball return cut in the +X end
    cab = obj('cabinet', ring(rrect(-XE, XE, -YE, YE, 0.012, 4), rrect(-XE + 0.02, XE - 0.02, -YE + 0.02, YE - 0.02,
                                                                     0.004, 4), ZC, ZR0), 'wood_dark')
    difference(cab, [box(XE - 0.05, XE + 0.01, -0.44, -0.08, 0.50, 0.585)], 'black')
    P.append(bevel(cab, 0.006, 2))
    A('cabinet_bottom', box(-XE + 0.02, XE - 0.02, -YE + 0.02, YE - 0.02, ZC, ZC + 0.018), 'wood_dark')
    tray = merge(box(0.93, 1.032, -0.45, -0.07, 0.49, 0.50), box(0.93, 1.032, -0.45, -0.07, 0.585, 0.595),
                 box(0.92, 0.93, -0.45, -0.07, 0.49, 0.595), box(0.93, 1.032, -0.45, -0.44, 0.50, 0.585),
                 box(0.93, 1.032, -0.08, -0.07, 0.50, 0.585))
    A('ball_return', tray, 'black')
    A('ball_return_trim', ring(rrect(-0.452, -0.068, 0.488, 0.597, 0.008, 3), rrect(-0.44, -0.08, 0.50, 0.585, 0.002, 3),
                               XE, XE + 0.004, 'yz'), 'chrome', 0.0012, 1)
    # the coin mechanism: chrome face plate, the slide with three coin slots, a reject button, the cash box lock
    A('coin_plate', box(XE, XE + 0.004, 0.06, 0.32, 0.56, 0.72), 'chrome', 0.0015, 1)
    A('coin_slide', box(XE + 0.004, XE + 0.058, 0.13, 0.25, 0.625, 0.655), 'chrome', 0.003, 2)
    A('slide_grip', rod((XE + 0.058, 0.118, 0.64), (XE + 0.058, 0.262, 0.64), 0.009), 'chrome')
    for k in range(3):
        y = 0.155 + 0.035 * k
        A('coin_slot', cyl((XE + 0.03, y, 0.6545), (XE + 0.03, y, 0.6556), 0.0125, 24), 'black')
    A('coin_reject', cyl((XE + 0.004, 0.19, 0.59), (XE + 0.012, 0.19, 0.59), 0.011, 24), 'chrome', 0.0015, 1)
    A('cash_lock', cyl((XE, 0.19, 0.52), (XE + 0.007, 0.19, 0.52), 0.012, 24), 'brass', 0.0015, 1)
    # four heavy square legs, a little tapered, on rubber levellers
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = sx * (XE - 0.075), sy * (YE - 0.075)
            leg = box(cx - 0.075, cx + 0.075, cy - 0.075, cy + 0.075, 0.014, ZC)
            for v in leg.verts:
                if v.co.z < 0.1:
                    v.co.x = cx + (v.co.x - cx) * 0.85
                    v.co.y = cy + (v.co.y - cy) * 0.85
            A('leg', leg, 'wood_dark', 0.006, 2)
            A('leveller', cyl((cx, cy, 0.0), (cx, cy, 0.0145), 0.042, 32), 'rubber', 0.002, 1)
    # somebody's chalk left on the rail
    A('chalk', move(rot(box(-0.011, 0.011, -0.011, 0.011, ZR, ZR + 0.022), 20, 'Z'), 0.60, 0.598, 0.0), 'felt',
      0.002, 1)
    table = finish('pool_table', P)

    # the light over it: a long hood with sloping sides, enamelled dark outside and white inside, three bulbs
    P = []
    L, W, H, t, rb = 1.60, 0.40, 0.16, 0.0015, 0.004

    def outline(d, z):
        return [(x, y, z) for x, y in rrect(-L / 2 + d, L / 2 - d, -W / 2 + d, W / 2 - d,
                                            max(0.035 - 0.3 * d, 0.012), 6)]
    hprof = [(p.x, p.y) for p in fillet([(rb, -H + rb), (0.064, 0.0), (0.2, 0.0)], 0.02, 6)][:-1]
    hin = offset_line(hprof, t)
    hood = loft([outline(d, z) for d, z in hin[::-1]] + [outline(d, z) for d, z in hprof])

    def out(c):
        q = V((c.x - max(-0.6, min(0.6, c.x)), c.y, 0))
        return q.normalized() if q.length > 1e-9 else q
    A('hood', two_tone(hood, out), ['dark', 'plastic_light'])
    A('rim', tube(outline(rb, -H + rb), rb, 10, closed=True), 'dark')
    for x in (-0.5, 0.0, 0.5):
        socket_and_bulb(A, x, 0.0, -t)
    light = finish('pool_light', P)
    return [result('pool_table', [table], dict(view=(0.9, 1.0, 0.75)),
                   [dict(view=(1.0, 0.35, 0.3), target=(1.08, 0.05, 0.6), dist=1.3),
                    dict(view=(0.25, 0.5, 1.0), target=(0.95, 0.47, 0.82), dist=0.75),
                    dict(view=(0.1, 1.0, 0.35), target=(0.0, 0.5, 0.8), dist=0.8),
                    dict(view=(0.6, 1.0, 0.2))]),
            result('pool_light', [light], dict(view=(0.55, 1.0, -0.3), ground='ceiling'),
                   [dict(view=(0.6, 1.0, 0.45), ground=None)])]


# ------------------------------------------------------------------ 8. the television

def build_tv():
    P, C = [], []

    def A(n, bm, m, bev=0.0, segs=2, parts=None):
        return add(n, bm, m, bev, segs, 30.0, P if parts is None else parts)
    W, Ht, T, yb = 1.24, 0.72, 0.06, 0.045         # the set; the bracket holds its back 45 mm off the wall
    yf = yb + T                                     # the glass
    panel = obj('panel', box(-W / 2, W / 2, yf - 0.022, yf, -Ht / 2, Ht / 2), 'black')
    difference(panel, [box(-0.609, 0.609, yf - 0.0012, yf + 0.01, -0.347, 0.352)])
    P.append(bevel(panel, 0.003, 2))
    A('screen', box(-0.609, 0.609, yf - 0.0022, yf - 0.0004, -0.347, 0.352), 'screen')
    # the electronics bulge on the back, sloped all round
    A('back', loft([[(x, y, z) for x, z in rrect(-hw, hw, z0, z1, 0.04, 6)]
                    for hw, z0, z1, y in ((0.46, -0.33, 0.24, yf - 0.022), (0.40, -0.29, 0.18, yb))]),
      'black', 0.004, 2)
    # the wall bracket: two rails on the wall, two arms on the set
    for z0, z1 in ((0.08, 0.12), (-0.20, -0.16)):
        A('wall_rail', box(-0.30, 0.30, 0.0, 0.012, z0, z1), 'black', 0.002, 1)
    for x in (-0.20, 0.20):
        A('bracket_arm', box(x - 0.018, x + 0.018, 0.012, yb, -0.23, 0.15), 'black', 0.002, 1)
    tv = finish('tv', P)
    # its lead, down to a cable outlet on the wall just under the right-hand side
    A('outlet', box(0.262, 0.338, 0.0, 0.008, -0.475, -0.40), 'plastic_light', 0.0015, 1, C)
    A('grommet', cyl((0.30, 0.008, -0.418), (0.30, 0.013, -0.418), 0.0075, 24), 'black', 0.001, 1, C)
    path = fillet([(0.27, 0.064, -0.30), (0.27, 0.064, -0.365), (0.30, 0.058, -0.418), (0.30, 0.009, -0.418)],
                  0.03, 8)
    A('lead', tube(path, 0.0035, 12), 'black', 0, 2, C)
    cable = finish('cable', C)
    return [result('tv', [tv, cable], dict(view=(0.45, 1.0, 0.1), ground='wall'),
                   [dict(view=(1.0, 0.3, -0.1), ground='wall'), dict(view=(0.35, 1.0, -0.5), ground='wall',
                                                                    target=(0.25, 0.05, -0.36), dist=1.0)])]


# ------------------------------------------------------------------ 9. the jukebox

def build_jukebox():
    P = []

    def A(n, bm, m, bev=0.0, segs=2):
        return add(n, bm, m, bev, segs, 30.0, P)
    XW, XC, REC = 0.31, 0.278, 0.018    # half width; inside face of the side cheeks; how far the body sits back
    # side profile (y, z): the lower front leans out, the screen face leans back, a big round into the top
    corners = [(0.0, 0.0), (0.205, 0.0), (0.292, 0.50), (0.250, 1.05), (0.0, 1.05)]
    cheek = [(p.x, p.y) for p in fillet(corners, [0, 0.015, 0.06, 0.12, 0], [1, 3, 3, 12, 1], closed=True)]
    body_c = inset(corners, [0.0, REC, REC, REC, 0.0])
    body = [(p.x, p.y) for p in fillet(body_c, [0, 0.006, 0.042, 0.102, 0], [1, 2, 3, 12, 1], closed=True)]
    for sx in (-1, 1):
        A('cheek', prism(cheek, sx * XC, sx * XW, 'yz'), 'black', 0.006, 2)
    A('body', prism(body, -XC, XC, 'yz'), 'dark', 0.004, 2)

    def frame(a, b):
        """Axes on the body's front from corner a to corner b: x across, y out of the face, z up the face."""
        a, b = V((0.0, a[0], a[1])), V((0.0, b[0], b[1]))
        up = (b - a).normalized()
        out = V((0.0, up.z, -up.y))
        return Matrix(((1, 0, 0, 0), (0, out.y, up.y, a.y), (0, out.z, up.z, a.z), (0, 0, 0, 1)))
    ML, MS = frame(body_c[1], body_c[2]), frame(body_c[2], body_c[3])
    # the touchscreen in a black glass bezel, on the face that leans back
    A('bezel', xform(prism(rrect(-0.245, 0.245, 0.04, 0.40, 0.02, 4), 0.0, 0.008, 'xz'), MS), 'black', 0.003, 2)
    A('screen', xform(prism(rrect(-0.215, 0.215, 0.065, 0.375, 0.004, 2), 0.006, 0.0088, 'xz'), MS), 'screen',
      0.0008, 1)
    # two speaker grilles low down: a black frame, a black back, dark slats
    for s in (-1, 1):
        u0, u1 = sorted((s * 0.03, s * 0.245))
        v0, v1 = 0.05, 0.30
        A('grille_frame', xform(ring(rrect(u0, u1, v0, v1, 0.014, 4), rrect(u0 + 0.012, u1 - 0.012, v0 + 0.012,
                                                                              v1 - 0.012, 0.004, 4), 0.0, 0.006,
                                     'xz'), ML), 'black', 0.0015, 1)
        A('grille_back', xform(prism(rrect(u0 + 0.011, u1 - 0.011, v0 + 0.011, v1 - 0.011, 0.004, 2), -0.001, 0.0015,
                                     'xz'), ML), 'black')
        for k in range(11):
            vz = v0 + 0.02 + 0.0192 * k
            A('grille_slat', xform(box(u0 + 0.012, u1 - 0.012, 0.0015, 0.0045, vz, vz + 0.0095), ML), 'dark',
              0.001, 1)
    # the money (seen from the front, -X is on the right): a bill acceptor on the right, a coin entry on the
    # left, a price label between
    acc = obj('bill_acceptor', xform(prism(rrect(-0.235, -0.14, 0.325, 0.475, 0.012, 4), 0.0, 0.028, 'xz'), ML),
              'black')
    difference(acc, [xform(box(-0.215, -0.16, 0.018, 0.05, 0.41, 0.416), ML)], 'rubber')
    P.append(bevel(acc, 0.003, 2))
    A('bill_slot_trim', xform(ring(rrect(-0.223, -0.152, 0.402, 0.424, 0.004, 3),
                                   rrect(-0.215, -0.16, 0.41, 0.416, 0.001, 3), 0.028, 0.0295, 'xz'), ML), 'chrome',
      0.0005, 1)
    A('coin_plate', xform(box(0.165, 0.235, 0.0, 0.004, 0.35, 0.45), ML), 'chrome', 0.0015, 1)
    A('coin_slot', xform(box(0.197, 0.203, 0.0035, 0.0046, 0.385, 0.425), ML), 'black')
    A('coin_reject', xform(cyl((0.2, 0.004, 0.365), (0.2, 0.011, 0.365), 0.008, 24), ML), 'chrome', 0.001, 1)
    A('price_label', xform(rot(box(-0.045, 0.045, 0.0, 0.0006, 0.375, 0.435), 3, 'Y', (0, 0, 0.405)), ML), 'paper')
    # light trim: strips up the front edges of both cheeks and over their tops, a bar across the top
    path = [p for p in cheek if p[1] > 0.012 and p[0] > 0.02] + [(0.03, 1.05)]
    path = offset_line(path, 0.002)
    for sx in (-1, 1):
        A('light_strip', band([(sx * (XW - 0.016), y, z) for y, z in path], 0.014, 0.005), 'juke_light')
    ym, zm = max(body, key=lambda p: p[0] + p[1])
    A('light_bar', rod((-0.27, ym + 0.0025, zm + 0.0025), (0.27, ym + 0.0025, zm + 0.0025), 0.009), 'juke_light')
    juke = finish('jukebox', P)
    return [result('jukebox', [juke], dict(view=(0.5, 1.0, 0.12), ground='wall'),
                   [dict(view=(1.0, 0.3, 0.05), ground='wall'),
                    dict(view=(0.35, 1.0, 0.2), ground='wall', target=(0.0, 0.28, 0.45), dist=1.0)])]


# ------------------------------------------------------------------ 10. the dartboard

def build_dartboard():
    P, DP = [], []

    def A(n, bm, m, bev=0.0, segs=2, parts=None):
        return add(n, bm, m, bev, segs, 30.0, P if parts is None else parts)
    CW, CH, CD, FT = 0.58, 0.68, 0.10, 0.018       # cabinet outside width, height, depth; its board thickness
    A('cabinet', ring(rrect(-CW / 2, CW / 2, -CH / 2, CH / 2, 0.003, 1),
                      rrect(-CW / 2 + FT, CW / 2 - FT, -CH / 2 + FT, CH / 2 - FT, 0.001, 1), 0.0, CD, 'xz'),
      'wood_dark', 0.003, 2)
    A('cabinet_back', box(-CW / 2 + FT, CW / 2 - FT, 0.0, 0.012, -CH / 2 + FT, CH / 2 - FT), 'wood_dark')
    for sx in (-1, 1):
        for z in (-0.24, 0.24):
            A('hinge', cyl((sx * CW / 2, CD + 0.018, z - 0.025), (sx * CW / 2, CD + 0.018, z + 0.025), 0.0045, 16),
              'brass')

    # the board, built round +Z (its face at z = BT) and then turned to face +Y, its back 20 mm off the cabinet
    YB0, BT, N = 0.020, 0.038, 120

    def face_y(bm):
        return move(rot(bm, -90, 'X'), 0, YB0, 0)
    board = lathe([(0, 0), (0.2215, 0), (0.2255, 0.004), (0.2255, 0.034), (0.2215, BT)], N, cap=False)
    radii = [0.016, 0.099, 0.107, 0.162, 0.170, 0.2215]
    pole = board.verts.new((0, 0, BT))
    rings = [[board.verts.new((r * math.cos(TAU * k / N), r * math.sin(TAU * k / N), BT)) for k in range(N)]
             for r in radii]

    def sector(k):         # the 20 segments, 0 = the 20 at the top; even ones black, odd ones cream
        th = -(k + 0.5) * 360.0 / N           # this lathe angle ends up at world angle -angle in the XZ plane
        return int(((th - 81.0) % 360.0) // 18.0)
    for k in range(N):
        j = (k + 1) % N
        board.faces.new((pole, rings[0][k], rings[0][j]))
        for i in range(len(radii) - 1):
            f = board.faces.new((rings[i][k], rings[i][j], rings[i + 1][j], rings[i + 1][k]))
            f.material_index = 1 if i in (0, 2) and sector(k) % 2 else 0
    bmesh.ops.remove_doubles(board, verts=board.verts[:], dist=1e-6)
    A('board', face_y(_normals(board)), ['black', 'paper'])
    # the doubles and trebles as raised bands, red on the black segments and green on the cream ones
    for r0, r1 in ((0.099, 0.107), (0.162, 0.170)):
        for s in range(20):
            k0, k1 = -33 - 6 * s, -27 - 6 * s
            arc_o = [(r1 * math.cos(TAU * k / N), r1 * math.sin(TAU * k / N)) for k in range(k0, k1 + 1)]
            arc_i = [(r0 * math.cos(TAU * k / N), r0 * math.sin(TAU * k / N)) for k in range(k1, k0 - 1, -1)]
            A('ring', face_y(prism(arc_o + arc_i, BT - 0.0005, BT + 0.0015)), 'vinyl' if s % 2 == 0 else 'felt')
    A('outer_bull', face_y(lathe([(0.0064, BT - 0.0005), (0.016, BT - 0.0005), (0.016, BT + 0.0015),
                                  (0.0064, BT + 0.0015)], 48, closed=True)), 'felt')
    A('bull', face_y(lathe([(0, BT + 0.002), (0.0064, BT + 0.002), (0.0064, BT - 0.0005), (0, BT - 0.0005)], 32)),
      'vinyl')

    # the doors, standing open about 165 degrees on their hinges, chalk scores on the boards inside them
    def door(sx, chalk):
        parts = []
        add('door', box(0.0015, CW / 2, CD, CD + 0.018, -CH / 2, CH / 2), 'wood_dark', 0.003, 2, 30.0, parts)
        add('chalkboard', box(0.028, CW / 2 - 0.028, CD - 0.003, CD, -CH / 2 + 0.045, CH / 2 - 0.045), 'black',
            0.001, 1, 30.0, parts)
        for x0, z0, x1, z1 in chalk:
            add('chalk', beam((x0, CD - 0.0033, z0), (x1, CD - 0.0033, z1), 0.0024, 0.0006, (0, 1, 0)), 'paper',
                0.0, 1, 30.0, parts)
        add('knob', rod((0.035, CD + 0.018, 0.0), (0.035, CD + 0.038, 0.0), 0.008), 'brass', 0.0, 1, 30.0, parts)
        ob = finish('door', parts)
        hinge = V((CW / 2, CD + 0.018, 0.0))
        ob.data.transform(Matrix.Translation(hinge) @ Matrix.Rotation(D(-165), 4, 'Z') @ Matrix.Translation(-hinge))
        if sx < 0:
            ob.data.transform(Matrix.Diagonal((-1, 1, 1, 1)))
            ob.data.flip_normals()
        P.append(ob)

    def tally(x, z, n):
        marks = [(x + 0.008 * i, z - 0.02, x + 0.008 * i + 0.002, z + 0.02) for i in range(min(n, 4))]
        if n >= 5:
            marks.append((x - 0.006, z - 0.012, x + 0.031, z + 0.013))
        return marks
    grid = [(0.045, 0.236, 0.245, 0.231), (0.146, 0.27, 0.148, -0.26)]
    door(1, grid + tally(0.06, 0.19, 5) + tally(0.06, 0.13, 5) + tally(0.06, 0.07, 2) + tally(0.165, 0.19, 5) +
         tally(0.165, 0.13, 3))
    door(-1, grid + tally(0.06, 0.19, 5) + tally(0.06, 0.13, 1) + tally(0.165, 0.19, 4))
    cabinet = finish('dartboard', P)

    # three darts in the board
    def dart(face, d, spin):
        d = V(d).normalized()
        tip = V((face[0], YB0 + BT, face[1])) - d * 0.022
        bits = [('point', lathe([(0, 0), (0.0006, 0.002), (0.00115, 0.012), (0.00115, 0.031), (0, 0.031)], 16),
                 'chrome'),
                ('barrel', lathe([(0, 0.030), (0.0028, 0.031), (0.0036, 0.037), (0.0036, 0.062), (0.0030, 0.070),
                                  (0.0023, 0.074), (0, 0.074)], 24), 'chrome'),
                ('shaft', lathe([(0, 0.073), (0.0024, 0.073), (0.0024, 0.108), (0.0017, 0.110), (0, 0.110)], 16),
                 'black')]
        for k in range(4):
            bits.append(('flight', rot(prism([(0.0012, 0.094), (0.0165, 0.107), (0.0165, 0.134), (0.0012, 0.138)],
                                             -0.0003, 0.0003, 'xz'), spin + 90 * k), 'vinyl'))
        for n, bm, mt in bits:
            add(n, _along(bm, tip, tip + d), mt, 0.0, 1, 30.0, DP)
    dart((0.003, 0.103), (0.02, 1.0, 0.20), 20)
    dart((0.05, 0.14), (-0.03, 1.0, 0.16), 55)
    dart((-0.075, -0.02), (0.05, 1.0, 0.24), 5)
    darts = finish('darts', DP)
    return [result('dartboard', [cabinet, darts], dict(view=(0.35, 1.0, 0.15), ground='wall'),
                   [dict(view=(0.15, 1.0, 0.1), ground='wall', target=(0.0, 0.06, 0.0), dist=0.9),
                    dict(view=(1.0, 0.6, 0.2), ground='wall')])]


# ------------------------------------------------------------------ the list

GROUPS = [('truck', build_truck, ['truck']),
          ('doors', build_doors, ['door_leaf_left', 'door_leaf_right', 'door_frame']),
          ('ledge_props', build_ledge, ['ledge_props']),
          ('stools', build_stools, ['stool_bar', 'stool_low']),
          ('tables', build_tables, ['table_square', 'table_round']),
          ('pendant', build_pendant, ['pendant']),
          ('pool', build_pool, ['pool_table', 'pool_light']),
          ('tv', build_tv, ['tv']),
          ('jukebox', build_jukebox, ['jukebox']),
          ('dartboard', build_dartboard, ['dartboard'])]

INFO = {  # stem: (origin, facing)
    'truck': ('floor, centred under the truck; `passenger_door` origin on its hinge axis (x 1.0, y 1.229, z 0.53 '
              'in Blender, i.e. Godot x 1.0, y 0.53, z -1.229), rotated 52 deg open about the vertical axis',
              'front +Y (Godot -Z); driver on -X'),
    'door_leaf_left': ('hinge axis at the bottom corner (leaf centred on its thickness, y 0); leaf runs to +X',
                       'room side (push bar, kick plate, closer) +Y'),
    'door_leaf_right': ('hinge axis at the bottom corner (leaf centred on its thickness, y 0); leaf runs to -X',
                        'room side (push bar, kick plate, closer) +Y'),
    'door_frame': ('bottom centre of the 1.80 x 2.34 opening, frame depth centred on y 0',
                   'room side +Y (door stops on the +Y side of the leaves)'),
    'ledge_props': ('each object at its own base centre, laid out along X: `scanner` x 0, `clicker` 0.19, `book` 0.40, '
                    '`lighter` 0.60, `mug` 0.74',
                    'the operator (him) is at -Y: scanner screen and slot face -Y, cable out of +Y; counter lies face '
                    'up, plunger +Y; ledger spine -X, head +Y; lighter lies on its side, top +X; mug handle +X'),
    'stool_bar': ('floor, centred under the post', 'round, no front (seat top 0.76; foot ring 0.40 across at 0.30)'),
    'stool_low': ('floor, centred under the post', 'round, no front (seat top 0.64; foot ring 0.34 across at 0.24)'),
    'table_square': ('floor, centred under the column', 'square top edges along X and Y, foot arms on the diagonals'),
    'table_round': ('floor, centred under the column', 'round (table 28)'),
    'pendant': ('top centre of the shade, where the cord goes in; everything hangs below it',
                'round, opens downward'),
    'pool_table': ('floor, centred under the table; the bed (playing surface) is at 0.80, the rail tops at 0.848',
                   'long axis X; coin slide and ball return on the +X end'),
    'pool_light': ('top centre of the hood; everything hangs below it', 'long axis X, opens downward'),
    'tv': ('on the wall, behind the middle of the screen (the bracket holds the set 45 mm off the wall); '
           '`cable` is its lead, down to a cable outlet on the wall under the right-hand side',
           'screen +Y'),
    'jukebox': ('on the wall, at the bottom centre of its back', 'front +Y'),
    'dartboard': ('on the wall, behind the bull (the centre of the cabinet back); `darts` is three darts in the board',
                  'board +Y, doors standing open about 165 deg'),
}


def write_readme():
    lines = ['# Props for the door look test', '',
             'Built by `tools/models_set.py` (Blender 5.0, bpy); rerun it to rebuild. Metres. Blender Z-up, exported '
             'glTF +Y up, so Blender +Y (each model\'s front) is Godot -Z (forward). Sizes below are '
             'width (X) x depth (Blender Y, Godot Z) x height, measured from the exported files. Materials are named '
             'by role with the real colour; `ceramic` (#e8e4da, roughness 0.2, the white mug) is an added name.', '',
             '| file | origin | faces | size (m) | materials |', '|---|---|---|---|---|']
    for _, _, stems in GROUPS:
        for stem in stems:
            if not os.path.exists(os.path.join(OUT, stem + '.glb')):
                continue
            info = verify(stem)
            sx, sy, sz = info['size']
            org, face = INFO.get(stem, ('', ''))
            objs = ', '.join(f'`{o[0]}`' for o in info['objects']) if len(info['objects']) > 1 else ''
            lines.append(f'| `{stem}.glb`{(" (" + objs + ")") if objs else ""} | {org} | {face} | '
                         f'{sx:.2f} x {sy:.2f} x {sz:.2f} | {", ".join(sorted(info["materials"]))} |')
    with open(os.path.join(OUT, 'README.md'), 'w') as fh:
        fh.write('\n'.join(lines) + '\n')
    print('  wrote models/README.md')


def main(args):
    os.makedirs(PREVIEWS, exist_ok=True)
    with open(os.path.join(PREVIEWS, '.gdignore'), 'w'):
        pass
    if CHECK:
        os.makedirs(CHECK, exist_ok=True)
    previews = '--no-preview' not in args
    want = [a for a in args if not a.startswith('--')]
    for key, build, stems in GROUPS:
        if want and key not in want and not set(stems) & set(want):
            continue
        print(f'building {key}')
        reset()
        groups = build()
        for g in groups:
            if g['export']:
                export(g['obs'], g['stem'])
        if previews:
            _setup_render()
            for g in groups:
                if g['export']:
                    render_view(g['obs'], os.path.join(PREVIEWS, g['stem'] + '.png'), **g['view'])
                if CHECK:
                    views = ([] if g['export'] else [g['view']]) + g['extra']
                    for i, v in enumerate(views):
                        render_view(g['obs'], os.path.join(CHECK, f"{g['stem']}-{i + 1}.png"), **v)
        for g in groups:
            if g['export']:
                verify(g['stem'])
    write_readme()


if __name__ == '__main__':
    main(sys.argv[1:])
