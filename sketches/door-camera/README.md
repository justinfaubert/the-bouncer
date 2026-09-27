# The door post, through his eyes: a camera test

A small Godot 4.7 project that builds the pub, the vestibule and the lot out of grey shapes and renders what he sees from his stool by the main door at 7:50 pm on Wednesday. It tests the form Hutch picked on 27 September 2026 (through his eyes, from his posts; `bible/08_FUTURE_FORM.md`). It is not the look: no art, no print, no sound.

## The frames

- `frames/1-door.jpg`: out through the door glass. The pickup nosed in with its lights on, the sister in the cab under the dome light, the kid crossing the gravel in the rain. His ledge in the corner.
- `frames/2-kid.jpg`: the kid in front of the stool with his phone up, at arm's length. The Wrong Man's line from `door.ink` carries `#mark: door.door`, so his broken box is drawn round the door itself.
- `frames/3-room.jpg`: turned to the room. The Father's line here, "He's in front of you. Not over there.", is Claude's stand-in, to show a voice noticing where he looks. Every other line in the column is from `content/ink/door.ink`.
- `frames/turn.webp`: the head turn from the kid to the room. The mark stays on the door as the view swings away from it.

## What it found

- The stool works beside the door, not square in front of it. Square on, the view was all door frame. Beside it, the door sits at an angle with the lot through the glass, his ledge is under his right hand, and one turn of the head takes in the floor.
- From the door the bar is behind his right shoulder, as in the build's floor sketch, so it isn't in the room view. That fits the posts: the end of the bar by the till is a post of its own.
- A voice's mark can live in the room, tied to the thing it marks, and stay there when he looks away.

## The layout

It follows the floor sketch in the browser build (`prototype/web/src/ui/views.js`): the bar along the side wall from near the back to near the main door, his stool just inside the door, table 28 in the front window, the pool table in the middle, the kitchen behind the bar, the washrooms off the back, the deck door on the far wall. The measurements are made up. They change when Hutch's photographs and measurements of a real room come in.

## Running it

Open the folder in Godot 4.7 and press play, or run `godot --path sketches/door-camera`. It renders into `renders/` and quits. In Claude's cloud workspace, which has no GPU:

```
xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1600x900 --path sketches/door-camera
```

It uses the Compatibility renderer so it runs the same in the cloud and on Hutch's machine. The fonts are the build's own (SIL Open Font License, `fonts/OFL.txt`).
