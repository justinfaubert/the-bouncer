# Props for the door look test

Built by `tools/models_set.py` (Blender 5.0, bpy); rerun it to rebuild. Metres. Blender Z-up, exported glTF +Y up, so Blender +Y (each model's front) is Godot -Z (forward). Sizes below are width (X) x depth (Blender Y, Godot Z) x height, measured from the exported files. Materials are named by role with the real colour; `ceramic` (#e8e4da, roughness 0.2, the white mug) is an added name.

| file | origin | faces | size (m) | materials |
|---|---|---|---|---|
| `truck.glb` (`truck`, `passenger_door`) | floor, centred under the truck; `passenger_door` origin on its hinge axis (x 1.0, y 1.229, z 0.53 in Blender, i.e. Godot x 1.0, y 0.53, z -1.229), rotated 52 deg open about the vertical axis | front +Y (Godot -Z); driver on -X | 3.25 x 5.88 x 1.90 | amber_marker, black, chrome, cloth, dark, dome, glass, headlight, paint, paper, plastic_light, taillight, tire |
| `door_leaf_left.glb` | hinge axis at the bottom corner (leaf centred on its thickness, y 0); leaf runs to +X | room side (push bar, kick plate, closer) +Y | 0.86 x 0.21 x 2.27 | brass, bronze, chrome, glass |
| `door_leaf_right.glb` | hinge axis at the bottom corner (leaf centred on its thickness, y 0); leaf runs to -X | room side (push bar, kick plate, closer) +Y | 0.86 x 0.21 x 2.27 | brass, bronze, chrome, glass |
| `door_frame.glb` | bottom centre of the 1.80 x 2.34 opening, frame depth centred on y 0 | room side +Y (door stops on the +Y side of the leaves) | 1.98 x 0.23 x 2.43 | bronze, chrome |
| `ledge_props.glb` (`scanner`, `clicker`, `book`, `lighter`, `mug`) | each object at its own base centre, laid out along X: `scanner` x 0, `clicker` 0.19, `book` 0.40, `lighter` 0.60, `mug` 0.74 | the operator (him) is at -Y: scanner screen and slot face -Y, cable out of +Y; counter lies face up, plunger +Y; ledger spine -X, head +Y; lighter lies on its side, top +X; mug handle +X | 0.91 x 0.46 x 0.20 | black, brass, ceramic, chrome, dark, paper, plastic_light, rubber, screen, vinyl, wood |
| `stool_bar.glb` | floor, centred under the post | round, no front (seat top 0.76; foot ring 0.40 across at 0.30) | 0.42 x 0.42 x 0.76 | black, chrome, rubber, vinyl |
| `stool_low.glb` | floor, centred under the post | round, no front (seat top 0.64; foot ring 0.34 across at 0.24) | 0.40 x 0.40 x 0.64 | black, chrome, rubber, vinyl |
| `table_square.glb` | floor, centred under the column | square top edges along X and Y, foot arms on the diagonals | 0.80 x 0.80 x 0.78 | black, rubber, wood |
| `table_round.glb` | floor, centred under the column | round (table 28) | 1.70 x 1.70 x 0.78 | black, wood |
| `pendant.glb` | top centre of the shade, where the cord goes in; everything hangs below it | round, opens downward | 0.48 x 0.48 x 0.20 | black, bulb, dark, plastic_light |
| `pool_table.glb` | floor, centred under the table; the bed (playing surface) is at 0.80, the rail tops at 0.848 | long axis X; coin slide and ball return on the +X end | 2.22 x 1.30 x 0.87 | black, brass, chrome, felt, plastic_light, rubber, wood_dark |
| `pool_light.glb` | top centre of the hood; everything hangs below it | long axis X, opens downward | 1.60 x 0.40 x 0.16 | black, bulb, dark, plastic_light |
| `tv.glb` (`tv`, `cable`) | on the wall, behind the middle of the screen (the bracket holds the set 45 mm off the wall); `cable` is its lead, down to a cable outlet on the wall under the right-hand side | screen +Y | 1.24 x 0.10 x 0.84 | black, plastic_light, screen |
| `jukebox.glb` | on the wall, at the bottom centre of its back | front +Y | 0.62 x 0.30 x 1.05 | black, chrome, dark, juke_light, paper, rubber, screen |
| `dartboard.glb` (`dartboard`, `darts`) | on the wall, behind the bull (the centre of the cabinet back); `darts` is three darts in the board | board +Y, doors standing open about 165 deg | 1.14 x 0.21 x 0.68 | black, brass, chrome, felt, paper, vinyl, wood_dark |
