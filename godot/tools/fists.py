# His two fists and forearms, for the fight (game/fight.gd): first person, at the bottom of the
# view, up in his guard. Made with bpy (pip install bpy), written to models/people/his_fist_r.glb
# and his_fist_l.glb. Knuckles forward (-Z in Godot), the back of the hand up, the wrist at the
# origin, the forearm going back in the doorman's jacket sleeve. Big hands: he's six foot four.
#   python3 godot/tools/fists.py
import math
import os
import bpy

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "models", "people")
SKIN = (0.5711, 0.3663, 0.2542, 1.0)      # his_right_palm.glb's skin
SLEEVE = (0.0185, 0.0203, 0.0242, 1.0)    # and its jacket


def mat(name, c):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = 0.85
    return m


def rounded_box(name, size, at, bevel=0.35, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=at, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    m = o.modifiers.new("b", "BEVEL")
    m.width = min(size) * bevel
    m.segments = 3
    return o


def capsule(name, r, length, at, rot):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=length, vertices=14, location=at, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    m = o.modifiers.new("b", "BEVEL")
    m.width = r * 0.9
    m.segments = 3
    return o


def fist(side):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = 1.0 if side == "r" else -1.0
    skin = mat("skin", SKIN)
    sleeve = mat("doorman_jacket", SLEEVE)
    parts = []
    # the back of the hand and palm: a block, a little wider at the knuckles
    parts.append(rounded_box("palm", (0.092, 0.085, 0.05), (0, 0.045, 0.0), 0.4))
    # the knuckles: four, the middle two proud, along the front top edge
    for i, (x, z, r) in enumerate([(-0.033, 0.006, 0.0125), (-0.011, 0.009, 0.0135), (0.011, 0.009, 0.0135), (0.033, 0.005, 0.012)]):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=(x * s, 0.088, z), segments=14, ring_count=8)
        parts.append(bpy.context.active_object)
        # the fingers rolled under: a fat roll from the knuckle down and back under the palm
        parts.append(capsule("f%d" % i, 0.0115, 0.05, (x * s, 0.093, -0.018), (0, 0, 0)))
        parts.append(capsule("g%d" % i, 0.0105, 0.04, (x * s, 0.075, -0.034), (math.radians(80), 0, 0)))
    # the thumb, across the front of the first two fingers
    parts.append(capsule("thumb", 0.0125, 0.055, (-0.008 * s, 0.098, -0.03), (0, math.radians(90), math.radians(-12 * s))))
    parts.append(capsule("thumb_root", 0.016, 0.045, (-0.04 * s, 0.06, -0.025), (math.radians(70), 0, math.radians(-30 * s))))
    # the wrist and the forearm, back into the sleeve
    bpy.ops.mesh.primitive_cylinder_add(radius=0.034, depth=0.2, vertices=18, location=(0, -0.07, -0.004), rotation=(math.radians(90), 0, 0))
    wr = bpy.context.active_object
    wr.scale = (1.25, 0.85, 1.0)
    parts.append(wr)
    for p in parts:
        p.data.materials.clear()
        p.data.materials.append(skin)
    bpy.ops.mesh.primitive_cone_add(radius1=0.06, radius2=0.047, depth=0.6, vertices=28, location=(0, -0.45, -0.012), rotation=(math.radians(-90), 0, 0))
    sl = bpy.context.active_object
    sl.scale = (1.15, 0.95, 1.0)
    sl.data.materials.append(sleeve)
    parts += [sl]
    for p in parts:
        p.select_set(True)
        bpy.context.view_layer.objects.active = p
        for m in p.modifiers:
            bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = "his_fist_" + side
    sub = o.modifiers.new("s", "SUBSURF")
    sub.levels = 1
    bpy.ops.object.modifier_apply(modifier="s")
    bpy.ops.object.shade_smooth()
    path = os.path.join(OUT, "his_fist_%s.glb" % side)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=False)
    print("wrote", path)


for side in ("r", "l"):
    fist(side)
