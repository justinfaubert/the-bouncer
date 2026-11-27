# The teaser

A teaser for LAST CALL cut to "Slow Heavy Mercy" by Mallvvays (Hutch's track, not in the repo).
Every picture in it comes out of the game itself: the rooms, the people, the press and the
night-stock film, with the darts, the pool, the cigarette machine, the fights and the truck run by
their own code. Only the camera's been taken off his head and put on rails.

## The pieces

- `analyze.py`: reads the track with librosa (tempo, beats, bars, onsets, the energy second by
  second, the sections) into `analysis.json`.
- `cut.py`: the cut. `SHOTS` lists every shot and when it starts in the teaser, on the bars of the
  music; `plan` turns that into frame counts (`cut.json`), `music` makes the edit of the track,
  `film` puts the frames, the game's own sounds and the title together into the MP4.
- `../../trailer/trailer.gd`: renders the shots in Godot, frame by frame at 24 a second, one
  folder of JPGs each. `../../trailer/director.gd` is the camera on rails.

## What the track does, and the cut

136 BPM, a bar every 1.79 s. No drums to 0:09.7, then the band; a loud last push at 4:01; the
drums drop out at 4:08.8 for two bars and come back at 4:12.5 for sixteen; they stop at 4:42.1 and
the chord rings to 4:51. The teaser is 0:00 to 0:38.4, two beats of the last-call bell in the dark,
then 4:01.5 to the end: 88.8 s.

- intro, no drums: the Sov from the seawall, the bar before the doors, the kid at the door
- drums in: a cut every two bars, the game as it's played (the door, the room, talk, his walk,
  darts, pool, the machine, the glasswasher, the truck, a fight, the payphone wall)
- the bell, black
- the last push: a cut every half bar
- the break: the Listener comes up out of the strait
- sixteen bars, two a shot: into it, the room stopped dead, Friday's line, the fight, the table,
  the hall, the sign, the seawall
- the drums stop: LAST CALL

Gameplay shots keep the whole 16:9 frame with the page and the game's own UI; everything else is
cut to 2.39:1 (`FULL`, `CROP_Y` in `cut.py`).

## Making it

Godot 4.7.2, under xvfb with lavapipe for Vulkan (about 3 to 5 s a frame on the cloud's CPUs, so
two processes with their own user data dirs, run side by side, take about two hours for all of it):

    pip install librosa soundfile fonttools brotli pillow
    python3 analyze.py track.mp3                       # writes analysis.json, prints the sections
    python3 cut.py plan --out /tmp/trailer/cut.json
    python3 cut.py music --track track.mp3 --out /tmp/trailer/music.wav
    export VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json
    XDG_DATA_HOME=/tmp/trailer/xdg1 xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver vulkan \
      --resolution 1920x1080 --fixed-fps 24 --path godot -s res://trailer/trailer.gd -- \
      --cut /tmp/trailer/cut.json --out /tmp/trailer/frames [--only a,b] [--stills]
    python3 cut.py film --cut /tmp/trailer/cut.json --frames /tmp/trailer/frames \
      --music /tmp/trailer/music.wav --work /tmp/trailer/work --out teaser.mp4

`--stills` renders each shot at a quarter of the frames and keeps three pictures of it, to frame
things up; `/tmp/trailer` stands for any scratch folder. Shots that share a setup (the darts, the
pool, the machine, the fight) render in one process, in the order `trailer.gd` lists them.

Look at every frame before it goes anywhere: the camera's on rails through a room full of people,
and nothing stops it going through a head.
