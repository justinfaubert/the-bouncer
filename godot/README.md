# The Bouncer in Godot

Wednesday, the test shift, first person from his posts, in the printed look. This is where the
game goes past the browser build (`prototype/web`), which stays playable as it is and is still the
writers' room: the Ink, the rules and Hutch's director edits all come in through `content/`.

## Playing it

Download the build for your machine from the thread (or export it yourself, below):

- **Linux, the zip** (`The-Bouncer-<date>.zip`, made by `tools/bundle/make.sh`): unzip it anywhere
  and run `./play.sh`. `./open-in-godot.sh` opens the Godot project that's in it, with a Godot 4.7
  if there is one, and otherwise offers to fetch the official 4.7.2 editor and checks its
  fingerprint. Its `README.txt` has the keys and what's new.
- **Linux**: `TheBouncer.x86_64`. Mark it executable (`chmod +x TheBouncer.x86_64`) and run it.
  Wayland is fine; Godot runs through XWayland unless you start it with `--display-driver wayland`.
- **Windows**: `TheBouncer.exe`. It isn't signed, so SmartScreen asks first: More info, Run anyway.
- **In a browser**: the page linked in the thread. It downloads about 39 MB the first time; click
  into the picture once it opens, for the keys and the sound. Its saves stay in that browser.

Or open this folder in Godot 4.7 and press Play.

It runs on OpenGL 3.3 (the Compatibility renderer), so any graphics card from the last ten years
does. The settings have the print's detail, the grain, the field of view, the sway when he's
drunk, and fullscreen.

### Hands on

| | |
|---|---|
| Choose | click a choice, or its number |
| Go on, where the night stops to let a moment land | Space or Enter |
| Look round | drag across the room, or the arrow keys (or W A S D); the wheel narrows his eyes |
| Look at a thing | rest the pointer on what a choice is about: the choice lights up, and E or a click does it. On anything else whose name comes up, fainter, E or a click looks at it |
| Throw the dice | hold Space or the mouse button to shake, let go to throw |
| Something in his hands | drag to turn it, E to look closer, Q and R to go through it, Esc to put it down |
| His notes, the floor sketch | Tab, M |
| The pause, the settings, saving | Esc. Every choice is saved as it's made; there are three nights |
| On a pad | either stick looks round; the d-pad goes through the choices and A makes the lit one (with none lit, A goes on and throws the dice); B is Esc, Y is E, Back his notes, the left shoulder the sketch |

### Where things are kept

Saves and settings: `~/.local/share/The Bouncer/` on Linux, `%APPDATA%\The Bouncer\` on Windows.

### Putting in your own sound

Every sound is a placeholder made in code (`tools/sounds.py`) until Hutch records the real ones.
To swap one, put a file with the same name, as `.wav`, `.ogg` or `.mp3`, in a folder called
`audio` next to the game (or in `audio` inside the saves folder). A file there wins over the
placeholder. More takes of the same sound go in as `card_2`, `card_3` and so on, and the game
picks among them. The names are the files in `audio/`: the room's layers are the `amb_` ones
(rain on the glass, the room's talk in two layers, the jukebox through the wall, the fryer, the
cellar), and the rest are things (the scanner's beeps, the door, the dice, the pen).

## What's in here

- `game/`: what's on the screen. `main.gd` runs a night: the Ink's lines down the column
  (`column.gd`), choices, checks and the dice (`dice.gd`, thrown by hand; `dice_sim.gd` works out
  how two cubes fall, off the surface, its walls, the glasses on it and each other), things in his
  hands (`props.gd`: the licences, with a hologram in the laminate, the kid's phone, the binder),
  the voices marking up the room (`marks.gd`), looking as choosing (`hotspots.gd`, `hand.gd`), his
  notes and the floor sketch, the title and pause and settings (`menus.gd`), saves (`store.gd`),
  sound (`sound.gd`). `view.gd` is his eyes: the posts, walking between them, and the press that
  prints what he sees.
- `world/`: the Sovereign in 3D, built in code (`pub.gd`), the posts he stands at and the doors
  he goes through (`posts.gd`), the way across the ground floor round everything in it and
  everyone (`nav.gd`, on the walk map `textures/walk_grid.png`), and the people, staged by the
  clock and the story (`stage.gd`, to the spec in `docs/STAGING.md`). Ten of them walk in and out
  (each has a `<id>_walk.glb`, a walk made by `sketches/door-look/tools/export_walkers.py`), the
  bartender comes along behind the bar, and the rest change between glances, while he isn't
  looking.
- `look/`: the shaders. `press.gdshader` is the print: three inks on cream stock, picked by the
  colour of the light (`press/separation.png`, made by `sketches/door-look/tools/press.py`).
  `column.gdshader` is the text column, one even ink so the words read clean (the paper's grain
  stays in the room's print), and `licence.gdshader` is a licence's face, laminate and hologram.
- `models/`: the props and the people, made in code (`sketches/door-look/tools/`), loaded
  straight from their `.glb` files: one model for each pose, with where their heads, hands, phones
  and cards are in a `.json` beside it, and his own hands (`his_*`), seen from his eyes.
- `ink/ink.gd`: the Ink runtime, ported from inkjs 2.3.2 (the version the browser build ships in
  `prototype/web/lib/ink.js`, with its one patch: an invisible default choice keeps its flag across
  a save). It plays the same story the same way, to the letter.
- `engine/`: the game's engine, ported from `prototype/web/src/core/` line for line: the room in
  his head (`psyche.gd`), checks (`checks.gd`), the voices' barks (`barks.gd`), the word on him
  (`word.gd`), and the game itself (`game.gd`: lines, checks, the hand, toys, the sketch, saves).
- `data/content.json`: the story and every rule, written by `node tools/build.mjs` from
  `content/`. Rebuild it after changing the Ink, and both builds play the change.

The pictures, sounds, fonts and models are kept as they are in an export (their `.import` files
say `keep`), and the game reads them itself, so there's nothing for the editor to import first.

## Checking it

Whole nights, played headless by a random player who also handles what he's given, throws the
dice, and saves and reloads now and then; it fails on any script error:

```
godot --headless --path godot -s res://tests/smoke.gd -- --seed 7 --steps 400
```

The room against what's on offer, and the dice against the room, headless:

```
godot --headless --path godot -s res://tests/reach.gd -- --seeds 1-12 --steps 400 [--all]
godot --headless --path godot -s res://tests/looks.gd        # what each thing he can look at says
godot --headless --path godot -s res://tests/head.gd         # what turns his head, and what doesn't
godot --headless --path godot -s res://tests/walks.gd        # every walk, from every post to every other
godot --headless --path godot -s res://tests/dice_floor.gd   # every throw against everything drawn
godot --headless --path godot -s res://tests/tray_spots.gd   # where the tray can go down
```

`reach.gd` checks every choice's pin, and every thing he can look at, from every post with a line
of sight; on 17 October 2026 it found none wrong over twelve nights. `walks.gd` walks him from every
post to every other (306 walks) and through two places at once, the way the page sends him, and
fails a walk that goes through anything, goes faster than he walks, or gets to a door before it's
open; it also fails a post with somebody's spot under it. `tray_spots.gd` prints the table of tray
spots for `game/dice.gd`, and `walk_grid.gd` writes the walk map: run both again when the room
changes.

Pictures of the title and every post (needs a display; `xvfb-run` works):

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
  --path godot -s res://tests/shots.gd -- --out /tmp/shots --posts lot,door,floor,bar,t28,lot:pickup
```

`tests/shots_reach.gd` takes pictures of his eyes on things, the jukebox and the payphone seen
from where he stands at them, and the dice thrown at each post. An exported build takes
`--grab /tmp/title.png` to save a picture of its title and quit.
`tests/pad.gd` plays the start of a night on a pad (the d-pad, A, B and a stick), headless.

Against the browser build: both of these play whole nights with a seeded player and compare every
line with the browser build's engine running the same nights in Node.

```
godot --headless --path godot -s res://tests/ink_run.gd -- --from 1 --to 40 --out /tmp/ink
node tools/ink_diff.mjs --from 1 --to 40 --godot /tmp/ink          # the Ink alone, and its saves

godot --headless --path godot -s res://tests/engine_run.gd -- --from 1 --to 40 --out /tmp/eng
node tools/engine_diff.mjs --from 1 --to 40 --godot /tmp/eng       # the whole engine
```

On 17 October 2026 both came out identical for 40 nights of 40.

## Exporting

The presets are in `export_presets.cfg` (Linux, Windows and Web); the export templates for 4.7.2
have to be installed.

```
godot --headless --path godot --export-release "Linux" ../build/linux/TheBouncer.x86_64
godot --headless --path godot --export-release "Windows" ../build/windows/TheBouncer.exe
```

Both come out as one file with the game packed inside.

The zip to play from on Linux, with `play.sh`, this project and `open-in-godot.sh` beside the game
(`tools/bundle/`), from the repo's root:

```
sh godot/tools/bundle/make.sh            # writes releases/The-Bouncer-<date>.zip
```

The web build is the same game in a page. Godot's web files are too big for a Claude artifact as
they come, so `tools/web/pack.py` gzips them and cuts them into parts, and the page it writes
(`tools/web/page.html`) puts them back together as they download:

```
godot --headless --path godot --export-release "Web" ../build/web/index.html
python3 godot/tools/web/pack.py build/web build/web-artifact
```

Publish `the-bouncer.html` from `build/web-artifact` with the files beside it. `local.html` there is
the same page as a whole document, for trying it with any static server.
