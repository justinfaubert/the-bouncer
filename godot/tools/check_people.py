"""Checks the people before anyone sees them, and writes what it found where a person can read it.

  python3 tools/check_people.py --out DIR [patron_c bigman ...] [--dir PATH] [--masks]

With no names, every rigged person in models/people/. --dir reads the models from somewhere else
(a fresh export, say sketches/door-look/models/people/). --masks also checks models/masks/.

Two checks:
  open skin   in each model's meshes, edges with a face on one side only, gathered into loops; a
              loop longer than a few centimetres in a body, its clothes, its head or its hands is a
              hole in it (the eyes' lids, the mouth and the lips are meant to be open, and the
              things they hold are made of flat pieces, so those are left out)
  see-through tests/check_people.gd films each person alone at the top of a sip (world/life.gd
              moves them as the room does), from five sides, and films each view again with the
              inside of every surface red: red seen within a figure is a way into it. A sliver
              shows at a cuff or a hem, so only patches bigger than that are marked, boxed on the
              pictures for a person to look at.

Writes DIR/review.md, a sheet of each one's five pictures with anything found boxed in red
(DIR/<name>_sheet.png), and DIR/all.png. Needs Blender's Python module (bpy), scipy and Godot.
"""
import json
import os
import subprocess
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.dirname(HERE)
VIEWS = ('front', 'three', 'left', 'back', 'right')
OPEN_OK = ('lid', 'mouth', 'lip', 'lash', 'eye', 'teeth', 'brow', 'wisp', 'pearl', 'strand')


def rigged(d):
    out = []
    for f in sorted(os.listdir(d)):
        if f.endswith('.json'):
            try:
                if 'rig' in json.load(open(os.path.join(d, f))):
                    out.append(f[:-5])
            except (ValueError, OSError):
                pass
    return out


MESH_SCRIPT = r'''
import bpy, bmesh, json, sys
ok = tuple(sys.argv[2].split(','))
res = {}
for path in sys.argv[3:]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    loops = []
    for ob in bpy.data.objects:
        if ob.type != 'MESH':
            continue
        bm = bmesh.new(); bm.from_mesh(ob.data); bm.transform(ob.matrix_world)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)   # glTF splits the skin at its UV seams
        bm.edges.index_update()
        seen = set()
        for e in bm.edges:
            if not e.is_boundary or e.index in seen:
                continue
            stack, loop = [e], []
            while stack:
                x = stack.pop()
                if x.index in seen:
                    continue
                seen.add(x.index); loop.append(x)
                for v in x.verts:
                    stack += [y for y in v.link_edges if y.is_boundary and y.index not in seen]
            mats = set()
            for x in loop:
                for f in x.link_faces:
                    if ob.material_slots and f.material_index < len(ob.material_slots):
                        m = ob.material_slots[f.material_index].material
                        mats.add(m.name if m else '')
            name = ob.name.lower()
            if any(k in name for k in ok) or (mats and all(any(k in m.lower() for k in ok) for m in mats)):
                continue
            per = sum(x.calc_length() for x in loop)
            if per < float(sys.argv[1]):
                continue
            c = [sum((v.co[i] for x in loop for v in x.verts)) / (2 * len(loop)) for i in range(3)]
            loops.append({'mesh': ob.name, 'around_cm': round(per * 100, 1), 'at': [round(a, 2) for a in c],
                          'materials': sorted(mats)})
        bm.free()
    res[path] = sorted(loops, key=lambda l: -l['around_cm'])
print('MESHCHECK ' + json.dumps(res))
'''


def open_skin(paths, min_len=0.03):
    """Holes in the meshes: {path: [loops]}."""
    script = os.path.join(os.environ.get('TMPDIR', '/tmp'), 'check_people_mesh.py')
    with open(script, 'w') as fh:
        fh.write(MESH_SCRIPT)
    r = subprocess.run([sys.executable, script, str(min_len), ','.join(OPEN_OK)] + paths,
                       capture_output=True, text=True)
    for line in r.stdout.splitlines():
        if line.startswith('MESHCHECK '):
            return json.loads(line[10:])
    raise RuntimeError('mesh check failed:\n' + r.stderr[-2000:])


def film(names, src, out):
    cmd = ['xvfb-run', '-a', '-s', '-screen 0 1920x1080x24', 'godot', '--rendering-driver', 'opengl3',
           '--resolution', '700x1000', '--path', GODOT, '-s', 'res://tests/check_people.gd', '--',
           '--out', out, '--who', ','.join(names), '--dir', src]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
    return {l.split()[1]: l for l in r.stdout.splitlines() if l.startswith('check ')}


def see_through(path, min_px=120):
    """Inside surfaces seen within the figure (red in the picture's _inside twin): [(x0, y0, x1, y1, pixels)].
    A little shows at any open hem or cuff; a hole shows a lot."""
    from PIL import Image
    from scipy import ndimage
    p = path[:-4] + '_inside.png'
    if not os.path.exists(p):
        return []
    im = np.asarray(Image.open(p).convert('RGB')).astype(int)
    red = (im[..., 0] > 200) & (im[..., 1] < 70) & (im[..., 2] < 70)
    lab, n = ndimage.label(ndimage.binary_opening(red, iterations=1))
    found = []
    for k, sl in enumerate(ndimage.find_objects(lab), start=1):
        px = int((lab[sl] == k).sum())
        if px >= min_px:
            found.append((sl[1].start, sl[0].start, sl[1].stop, sl[0].stop, px))
    return found


def sheet(name, out, gaps):
    from PIL import Image, ImageDraw
    ims = []
    for v in VIEWS:
        p = os.path.join(out, f'{name}_{v}.png')
        if not os.path.exists(p):
            return None
        im = Image.open(p).convert('RGB')
        d = ImageDraw.Draw(im)
        for x0, y0, x1, y1, _ in gaps.get(v, []):
            d.rectangle((x0 - 6, y0 - 6, x1 + 6, y1 + 6), outline=(220, 20, 30), width=4)
        ims.append(im)
    w, h = ims[0].size
    s = Image.new('RGB', (w * len(ims), h + 40), 'white')
    for i, im in enumerate(ims):
        s.paste(im, (i * w, 40))
    ImageDraw.Draw(s).text((10, 12), name, fill='black')
    s = s.resize((s.width // 2, s.height // 2))
    p = os.path.join(out, f'{name}_sheet.png')
    s.save(p)
    return p


def main():
    args = sys.argv[1:]
    out = args[args.index('--out') + 1] if '--out' in args else '/tmp/check_people'
    src = args[args.index('--dir') + 1] if '--dir' in args else os.path.join(GODOT, 'models', 'people')
    src = os.path.abspath(src) + '/'
    skip = {out, src.rstrip('/')}
    names = [a for i, a in enumerate(args) if not a.startswith('--') and args[i - 1] not in ('--out', '--dir')]
    names = names or rigged(src)
    os.makedirs(out, exist_ok=True)
    paths = [src + n + '.glb' for n in names]
    holes = open_skin(paths)
    if '--masks' in args:
        md = os.path.join(GODOT, 'models', 'masks')
        mpaths = [os.path.join(md, f) for f in sorted(os.listdir(md)) if f.endswith('.glb')]
        holes.update(open_skin(mpaths))
    filmed = film(names, src, out)
    lines = ['# People check', '', f'Models from `{src}`; pictures at the top of a sip, five sides each.', '']
    sheets, flagged = [], 0
    for n, p in zip(names, paths):
        gaps = {v: see_through(os.path.join(out, f'{n}_{v}.png')) for v in VIEWS
                if os.path.exists(os.path.join(out, f'{n}_{v}.png'))}
        # the person's own meshes (name_body, name_head, name_hands): what they hold is made of flat
        # pieces whose hard edges read as open skin, and is seen whole in the pictures anyway
        loops = [l for l in holes.get(p, []) if l['mesh'].startswith(n + '_')]
        # the mouth is opened along the line the lips meet (sketches/door-look/tools/rig.py): that one's meant
        try:
            mo = json.load(open(src + n + '.json'))['rig']['mouth']
            mb = np.array([mo[0], -mo[2], mo[1]])     # Godot's frame to Blender's
            loops = [l for l in loops if np.linalg.norm(np.array(l['at']) - mb) > 0.03]
        except (OSError, ValueError, KeyError):
            pass
        bad = loops or any(gaps.values())
        flagged += bool(bad)
        lines.append(f'## {n}: {"LOOK" if bad else "clean"}')
        lines.append(f'- filmed: {filmed.get(n, "not filmed").replace("check " + n, "").strip() or "yes"}')
        for l in loops:
            lines.append(f'- open skin: {l["around_cm"]} cm round, in {l["mesh"]} {l["materials"]} at {l["at"]}')
        for v, gs in gaps.items():
            for g in gs:
                lines.append(f'- see-through, {v} view: {g[4]} px at x {g[0]}-{g[2]}, y {g[1]}-{g[3]}')
        s = sheet(n, out, gaps)
        if s:
            sheets.append(s)
            lines.append(f'- sheet: {os.path.basename(s)}')
        lines.append('')
    if '--masks' in args:
        lines.append('## The masks (open skin only)')
        for p in mpaths:
            ls = holes.get(p, [])
            lines.append(f'- {os.path.basename(p)}: ' + ('clean' if not ls else
                         '; '.join(f'{l["around_cm"]} cm in {l["mesh"]} at {l["at"]}' for l in ls[:6])))
        lines.append('')
    lines.insert(3, f'{len(names)} checked, {flagged} to look at.')
    with open(os.path.join(out, 'review.md'), 'w') as fh:
        fh.write('\n'.join(lines) + '\n')
    if sheets:
        from PIL import Image
        ims = [Image.open(s) for s in sheets]
        w = max(i.width for i in ims)
        a = Image.new('RGB', (w, sum(i.height for i in ims)), 'white')
        y = 0
        for i in ims:
            a.paste(i, (0, y))
            y += i.height
        a.save(os.path.join(out, 'all.png'))
    print('\n'.join(lines[:4]))
    print('review:', os.path.join(out, 'review.md'))


if __name__ == '__main__':
    main()
