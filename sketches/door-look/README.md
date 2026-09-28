# The door post, printed: a look test

The door scene from `sketches/door-camera` (his stool beside the main door, 7:50 pm on Wednesday, the kid coming in out of the rain), built properly and run through the press. It answers Hutch's ask of 27 September 2026: "a coherent, novel visual design that feels good to look at while being a way to get away with a lack of visual complexity", with the modelling and texturing done by Claude, since Hutch isn't a visual artist. Every model, texture and shader in it was made in code. All of it is [PROPOSED] (`bible/05_LOG.md`).

## The frames

- `frames/1-door.jpg`: out through the door glass. SOVEREIGN over PUB in gold leaf, backwards from inside; the pickup nosed in with its lights on, the sister at the wheel under the dome light, her boyfriend in the back; the kid crossing the gravel in the rain.
- `frames/2-kid.jpg`: the kid at arm's length with his phone up, the photo of his licence on it (Tyler James Moffat, class 7N, from `content/data/props.yaml`). Behind him, the Wrong Man's broken box round the door. Beside the door, the masking tape with the night's sum in marker. Across the vestibule, the house rule: no pictures on phones.
- `frames/3-room.jpg`: turned to the room. Table 28 in the window, the big man and his buddy at the coin-op pool table, the crew at their table, the woman in slippers at the jukebox, the hockey on the TV table 28 watches and the news on the other (a rainfall warning for the east coast of the island), the sconces on the walls.
- `frames/4-drunk.jpg`: the kid again, four drinks in. The plates slip out of register.
- `frames/turn.webp`: the head turn from the kid to the room. The grain stays on the world, not the screen, so turning your head doesn't make it swim.

## The look: the night, printed

Every view is a print on cream stock in three inks: night (blue-black), lamp (amber) and neon (red). The light picks the ink. Lamplight prints amber, the sign and anything red print red, shadow prints night, and the brightest light is the bare paper. A table in `press/separation.png` says how much of each ink every rendered colour gets.

The dark is cut like a lino block. The night ink goes down in strokes that follow the surfaces: level on walls and people, across the floor from the door, along each object's own grain. The strokes stay the same distance apart on screen at any depth; where they would crowd, the cutter drops every other one, like an engraver. Edges and creases are keylines, printed white where there's ink and dark where there isn't. The ink lies in grain, with the paper's tooth under everything. Drink pushes the plates out of register (frame 4).

This is how it gets away with simple models. The eye reads the print, not the polygons: flat inks, cut strokes and a keyline round every shape make a few planes look deliberate, the way Return of the Obra Dinn's one-bit screen did. Detail goes where the story is: the licence on the phone, the tape by the door, the ID sign, the gold leaf. Everything else stays plain.

## What's in the room, and where it comes from

- **The people** are sculpted in code (`tools/people.py` on `tools/sdf.py`): each one a signed distance field built from the same `look` the browser build draws faces from (`content/data/characters.yaml`), with a skeleton and a pose (standing, sitting at a table or the bar, phone out, reaching), clothes as parts with their own materials, and a head with sockets, lids and irises. Each material is meshed on its own with marching cubes, so the seams between them are clean, then decimated in Blender (`tools/export_people.py`). Seventeen figures: the kid at the door and again on the lot, table 28, the big man and his buddy, the bartender, the hi-vis man, the old man at the end of the bar, the crew, the woman in slippers, and the sister and her boyfriend in the truck.
- **The things** are modelled by script in Blender (`tools/models_set.py`; sizes, origins and materials in `models/README.md`): the pickup, the door and its frame, the ledge's scanner, clicker, incident book, lighter and mug, the stools and tables, the pendants, the pool table and its lamp, the TVs, the jukebox and the dartboard.
- **The textures** are drawn in code (`tools/textures.py`): the carpet (an old hotel pattern, maroon with a navy trellis and gold rosettes, worn to the backing past the door mat and along the bar), the wood, the bar top, the wainscot, the plaster, the ID sign, the door's gold leaf, the licence on the phone, the hockey and the news on the TVs, the lottery screen, the jukebox's screen, the tape and the map of where the carpet's worn.
- **The tape by the door** says `19 = NOV 4 07`: on Wednesday 4 November 2026, anyone born on or before 4 November 2007 is nineteen. The kid was born on 14 October 2007, so he passes by three weeks, if the licence is his.
- **The sconces** are from when the pub was the hotel's dining room. They throw scallops of light up and down the walls with hard edges, which the press cuts cleanly.

## Stand-ins

- The faces are carved in code, like whittled figures, so they read as a style rather than failed realism. How the game's faces are made is still open (`bible/08_FUTURE_FORM.md`).
- The measurements are made up, and the layout follows the browser build's floor sketch. Both change when photographs and measurements of a real room come in.
- The Father's line in the room view ("He's in front of you. Not over there.") is Claude's stand-in, as in the camera test. Every other line in the column is from `content/ink/door.ink`.

## Running it

Open the folder in Godot 4.7 and press play, or run `godot --path sketches/door-look`. It renders the four stills and the 25 frames of the turn into `renders/` and quits. `SHOT=1` renders only the stills; `RAW=1` also saves the unprinted view and the press's mask. In Claude's cloud workspace, which has no GPU:

```
xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 --path sketches/door-look
```

It uses the Compatibility renderer so it runs the same in the cloud and on Hutch's machine. It loads the models and textures straight from their files, so it runs without the editor importing anything.

How the picture is made is written at the top of `main.gd`: a camera on the room, a second camera that sees how the key block is cut on every surface (`look/surface.gdshader`) and finds the keylines in the depth (`look/lines.gdshader`), and the press over both (`look/press.gdshader`).

## Remaking the models and textures

```
python3 tools/press.py                       # the separation table, grain and paper (numpy, Pillow)
python3 tools/textures.py                    # every texture (numpy, Pillow)
python3 tools/models_set.py                  # the things (Blender's Python module, bpy 5.0)
python3 tools/export_people.py [name]        # the people (numpy, scikit-image, bpy 5.0); --preview renders each
python3 tools/head_test.py '{"hair": "short"}' head.png    # one head from three sides, for working on faces
```

The fonts are the build's own, under the SIL Open Font License (`fonts/OFL.txt`, `tools/fonts/OFL.txt`).
