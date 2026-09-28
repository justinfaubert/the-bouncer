"""Sculpt one head and render it from three sides, for working on faces:
  python3 tools/head_test.py '{"hair": "short"}' out.png"""
import os, sys, json
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import people as PP
import sdf as S
import export_people as E

look = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, '..', 'models', 'people', 'previews', 'head.png')
B = PP.Build(look)
p = PP.pose_stand(B)
if 'body' in sys.argv: parts_body = PP.body_parts(B, p, look)
parts = PP.head_parts(B, p, look)
parts.append(S.Part('skin', S.cone(p.neck, p.head + p.Rh @ PP.V(0, -0.025, -0.07), 0.056, 0.05)))
lo = p.head - 0.19; hi = p.head + 0.19
step = float(os.environ.get("STEP", "0.0035"))
verts, faces, mat, names = S.mesh_islands(parts, lo, hi, step)
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
me = bpy.data.meshes.new('head'); me.from_pydata(verts.tolist(), [], faces.tolist()); me.update()
ob = bpy.data.objects.new('head', me); bpy.context.scene.collection.objects.link(ob)
for n in names:
    m = bpy.data.materials.new(n)
    h = E.COLOURS.get(n, '#808080').lstrip('#'); c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    m.use_nodes = True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (*[x ** 2.2 for x in c], 1)
    me.materials.append(m)
me.polygons.foreach_set('material_index', mat.tolist()); me.polygons.foreach_set('use_smooth', [True] * len(me.polygons)); me.update()
E.render_preview([ob], out, views=((0.0, 'front'), (0.65, 'three'), (1.5708, 'side')), focus=(tuple(p.head + np.array([0, 0.02, -0.02])), float(os.environ.get('SPAN', '0.3'))))
print(len(faces), 'faces', names)
