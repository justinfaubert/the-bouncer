# Every sound in the game

Every sound in the Godot build is a placeholder made in code (`godot/tools/sounds.py`), there to
hold the place where one of Hutch's recordings goes. This is the list: each file, what it stands
for, and where and when the game plays it. The files are in `godot/audio/`.

## Putting a recording in

- **Where.** A folder called `audio` inside the zip's `game/` folder (next to
  `TheBouncer.x86_64`), or `~/.local/share/The Bouncer/audio/` (beside the saves, so it carries
  over to every new build). A file there is used instead of the placeholder from the next start.
  To put recordings into the game for good, so they ship with it, send them over and they go into
  `godot/audio/` in place of the placeholders.
- **Names.** The file's name is the sound's, as in the tables below: `laugh.wav`, `amb_juke.ogg`.
  `.wav`, `.ogg` and `.mp3` all work, at any sample rate.
- **Takes.** More than one take of a sound goes in as `laugh.wav`, `laugh_2.wav`, `laugh_3.wav`
  and so on, as many as you like. The game picks one at random each time and never the same one
  twice running. Any take of a name in your folder replaces all of the placeholder's takes of it,
  so one real laugh takes the place of the three made-up ones. The `amb_` layers have one take
  each.
- **Mono** for anything that comes from a place (the room's own sounds, and the layers below that
  come from somewhere in the Sov): the game puts it where it happens and pans it as he turns his
  head, and a stereo file's own left and right fight that. The layers that are all round him can
  be stereo.
- **Loops.** The `amb_` layers loop: the end should run into the start without a click. Any
  length; the game starts each at a random point, and a longer loop (half a minute or more)
  repeats less noticeably than the placeholders, which are 6 to 16 seconds.
- **Level.** Record them clean and natural, peaking around -3 dB. The game sets how loud each one
  sits in the mix and how it falls away with distance and through walls (`LEVEL` and `FROM` in
  `godot/game/sound.gd`). If one of yours sits too loud or too quiet, that's a number to change.
- One-shots can be as long as the thing itself: trim the silence off the front, since the game
  plays them the moment they happen.

## Where a recording would change the most

1. `amb_talk_a` and `amb_talk_b`: the room's murmur and table 28's. They're under everything all
   night, and a made-up murmur is the most obviously made up.
2. The people: `laugh`, `laugh_one`, `cheer`, `groan`, `cough`.
3. The bar: `pour`, `glass_down`, `clink`, `wipe`, `till`, `stool`.
4. `amb_juke`: the jukebox (something you own or make; it plays a lot).
5. The pool game: `cue`, `clack`, `pocket`, `break`.

## The room's layers

Loops, under everything, mixed by where he is and how the night's going. A layer that comes from
a place is louder near it, comes from its side as he turns his head, and from another part of the
building is lower and dulled by what's between (the swing door, the walls, the floor). Some of it
fills the room as well, the way a real room does.

| File | What it stands for | Where it comes from | When it's up |
|---|---|---|---|
| `amb_room_tone` | the room's own hum: coolers, the vents, the mains | all round him, in the bar; dulled from the next room | always in the Sov, fuller as the room fills |
| `amb_talk_a` | the room's talk: everyone who isn't table 28 | two places across the room, the bar half and the pool half | with how many are in (full at 24); thinner when the Ink says the room's quiet, fuller when it's busy, gone in an empty bar |
| `amb_talk_b` | table 28's own talk | table 28, in the front window | while they're in; louder with each round |
| `amb_shout` | the pool game getting heated: raised voices | the pool table | from the third notch of heat at the table; gone when the game's off |
| `amb_juke` | the jukebox | the jukebox | early in the night; louder late; through the floor in the keg room; low once the card runs out after two; off after hours |
| `amb_rain_glass` | rain on the windows | the front glass, by table 28 and by the door | always in the bar; at Gary's office window; upstairs |
| `amb_rain_out` | rain outside, on the lot and the street | all round him | low at the door; the lot, the deck, the old main street, the Esso, the seawall |
| `amb_rain_roof` | rain on the roof | all round him | low on the floor, loud on the deck, upstairs |
| `amb_fryer` | the kitchen's fryer | the kitchen | until the cook goes at eleven, low after |
| `amb_fan` | the kitchen's hood fan | the kitchen | always |
| `amb_radio` | the cook's radio, small and tinny on a shelf | the kitchen | until the cook goes at eleven |
| `amb_tube` | the fluorescent tubes in the back hall | the back hall | always |
| `amb_cellar` | the keg room: the cooler's compressor, drips | the keg room, under the bar | always (through the floor); up when the story goes down there |
| `amb_rats` | rats in the walls | the keg room's back corner | louder as there are more of them |
| `amb_sea` | the sea across the highway | all round him | the deck, the lot, the old main street, the seawall |
| `amb_keys` | the bookkeeper typing with one finger | all round him | Gary's office |
| `amb_canopy` | the Esso's canopy: rain on it, the lights | all round him | the Esso |
| `amb_traffic` | the highway in the wet | all round him | the old main street, the Esso, the seawall |

## The room's own sounds

One at a time, each from where it happens, the same way as the layers: near and clear, or far
off, or through a wall. None of them is in the story; they're the room going on by itself
(`godot/world/doings.gd`), and none of it happens at the table he's at.

| File | Takes now | What it is | Where and when |
|---|---|---|---|
| `glass_down` | 4 | a glass set down | whoever's drinking puts theirs back, at table 28, the bar, the tables; the bartender sets down the pint she's pulled |
| `clink` | 2 | glasses together | table 28's toast, when he overhears it |
| `laugh` | 3 | a table laughing, three or more | table 28, every half minute to a minute and a quarter, sooner as the rounds go; a conversation he overhears that ends in a laugh |
| `laugh_one` | 3 | one or two laughing | someone laughing at a spilled glass; a small conversation ending in a laugh |
| `slap` | 2 | a hand slapped on the table | now and then with table 28's laugh |
| `cheer` | 2 | table 28 going up for a goal | the hockey over the back wall, every few minutes, a time in three |
| `groan` | 2 | table 28 at a near miss | the hockey, a time in three |
| `cough` | 3 | a cough | anyone in the room, on the deck or in the hall, every minute or two |
| `stool` | 3 | a stool or chair scraped on the floor | someone getting up or sitting down |
| `pour` | 2 | a pint pulled at the taps | the bartender between serving, at the taps' end of the bar |
| `wipe` | 2 | a cloth on the bar, one stroke | the bartender wiping down, a stroke a second |
| `till` | 1 | the till | the bartender at the till; also the Ink's `till` |
| `door_wc` | 2 | a washroom door swinging | someone going in or out of the washrooms down the back hall |
| `flush` | 1 | a toilet flushing | before they come out |
| `cue` | 3 | the cue on the cue ball | the pool game, a shot every twenty seconds or so, quicker as it heats up; only while the table's out of his sight, since nobody's shown taking the shot |
| `clack` | 3 | the balls into each other | after each shot; also the Ink's `balls` |
| `pocket` | 2 | a ball dropping and rolling down the return | about a shot in three |
| `break` | 1 | the break | every seven to twelve shots |
| `lighter` | 2 | a lighter | a smoker on the deck lighting up, every minute or so |
| `spill` | 1 | a glass knocked over on a table | every six to twelve minutes at one of the tables; whoever's near looks, one of them laughs |

## The small sounds

In his ears, not placed anywhere: the story's own sounds (the Ink's `#sfx:` tags, by the names in
the last section), the dice, his notes, the paper.

| File | Takes now | What it is | When |
|---|---|---|---|
| `beep_ok` | 1 | the ID scanner taking a card | the Ink's `scanner_ok`, at the door |
| `beep_bad` | 1 | the scanner refusing one | the Ink's `scanner_bad` |
| `thump` | 1 | the door | the Ink's `door` (17 places); and very low when he comes to a place he sits or leans at and his weight goes onto it |
| `thud` | 2 | a body hitting something | the Ink's `hit` |
| `glass` | 2 | a glass knocked | the Ink's `glass`; a die off a glass on the bar |
| `scratch` | 3 | claws in the wall, close | the Ink's `scratch` |
| `ring` | 1 | the phone | the Ink's `phone`: the owner calling |
| `bell` | 1 | the last call bell | the Ink's `bell` |
| `rattle` | 4 | the dice shaken in his hand | before a throw |
| `tick` | 4 | a die knocking the tray, its rim or the other die | each knock of a throw |
| `tock` | 2 | a die landing for good | the last knock of each die |
| `stamp` | 1 | a stamp coming down | the check's result stamped on its card; the end of the night's ledger |
| `printer` | 3 | the till printing a row | the night's ledger at closing, a row at a time |
| `tear` | 2 | the tape torn off | the end of the ledger |
| `pen` | 3 | his pen | a note made or crossed off, a stat changing, writing in his notes |
| `page` | 3 | paper handled | his notes opened and turned, the sketch, a binder's pages |
| `card` | 3 | a card or a small thing handled | an ID, a card or a thing in his hand turned over or held up to look at |
| `swipe` | 1 | a finger across a phone's screen | a phone in his hand, its photos swiped through |
| `whisper` | 3 | a voice in his head, close | a voice reading what he's holding |
| `steps` | 2 | his steps | when he goes somewhere |
| `choose` | 1 | a choice taken | each choice he picks |
| `click_ui` | 1 | a menu button | the buttons of the menus |

## Made, but not played in this build

`click`, `heart`, `lift`, `gust`, `zero`, `rings` and `ratchet` are made by `sounds.py` and kept
for the browser build's sake or for later; the Godot build doesn't play them. No need to record
them yet.

## Retired

`amb_pool`, the pool game as a loop, is gone: the balls are struck one at a time now (`cue`,
`clack`, `pocket`, `break`) from the table, while it's out of his sight.

## The Ink's names

The Ink's `#sfx:` tags use the story's names; the game plays these files for them: `door` is
`thump`, `hit` is `thud`, `scanner_ok` and `scanner_bad` are `beep_ok` and `beep_bad`, `phone` is
`ring`, `balls` is `clack`, `dice_shake` is `rattle`, `die_tick` is `tick`, `die_land` is `tock`,
and `glass`, `scratch`, `till` and `bell` are themselves. The `#amb:` and `#music:` tags lean on
the room's mix (a quiet room, an empty bar, the jukebox late) without replacing it.
