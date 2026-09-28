# State of the door: a review before the polish pass

*28 September 2026. Hutch asked for everything in the Godot door scene to be gone over honestly before it's polished into a playable build. This is that review. The same text, with the marked-up frames laid out, is the artifact "State of the Door" (https://claude.ai/artifact/NaKyMWZE4Yrf4ZkGSRB6yi). Everything in it is [PROPOSED] until Hutch says otherwise.*

Covered: the Godot look test (`sketches/door-look`), the browser build it grew out of (`prototype/web`, v5), all of Wednesday's Ink (`content/ink`), the engine (`prototype/web/src/core`), the data and rules (`content/data`, `content/rules`) and the code that makes the models (`sketches/door-look/tools`).

## The short of it

- **The print works.** The door, the rain on the glass, the gold leaf read backwards, the tape with the night's sum. Nobody else's game looks like this, and it holds up in stills.
- **The people don't work yet.** The kid is the weakest thing on screen: a grown man's shoulders, mitten hands, and a face that's nearly bare paper while everything around it is cut in strokes.
- **The thing the scene is about doesn't read.** The licence on the kid's phone prints as grey noise.
- **It's a picture of a game.** Nothing moves, nothing can be touched, no Ink runs, and it's one post of eleven. The whole of Wednesday still lives only in the browser build.
- **So the job is bigger than polish.** It's carrying all of Wednesday into this look, and making the room something you read and handle, so the 3D earns its place beside the text instead of being wallpaper next to it.

## Keep: what looks right

- **Three inks and the paper.** The light picks the ink: amber under lamps, red for the sign and for blood, blue-black in shadow, bare stock where it's brightest. It's coherent, and cheap to make, which was the point.
- **The door.** SOVEREIGN over PUB, backwards from inside, rain streaking the glass, the pickup's lights beyond it. The best frame in the project.
- **The tape by the door, `19 = NOV 4 07`.** A real doorman's crib, and it does story work: the kid passes by three weeks, if the licence is his.
- **The sconces' scallops of light, and the pendants drawn in white keyline** against the dark room.
- **The grain stays on the world**, so turning your head doesn't make the paper swim.
- **The drunk slip.** Four drinks in, the plates come out of register. It tells you about him without a meter.
- **The Wrong Man's broken box round the door.** A voice drawing on the world is the right idea, and it should become a system.
- **The column's type.** Each voice in its own face and colour, old paragraphs dimming, choices numbered in red.

From the browser build, what has to survive the move: the dice you hold and wait on, the ID you handle, the voices marking up the pictures, the clicker, the ledger as a till tape, the Head's five seats and their pulls on each other, and the writing, all 175 knots of it.

## Needs work: the look

Marked-up frames are in `bible/review/` (red: needs work; green: keep).

### Frame 2, the kid at the door (`review/kid.jpg`)

1. **The licence doesn't read.** At arm's length the photo on his phone prints as grey noise, and it's the object the scene turns on. Story objects should print clean, with no grain or strokes over their faces, and when he takes the phone it should come up into his hand, close enough to read the name and the date of birth.
2. **The face is barely printed.** It's a flat paper-coloured mask with sticker eyes, while the hoodie, the wall and the door are all cut in strokes. It reads as a cruder technique pasted in. The face needs the same cut as everything else: strokes that follow the skull, keylines at the brow and jaw, shadow in the sockets.
3. **A grown man's build on a kid.** The shoulders fill the doorway and the chest is a barrel. He's nineteen at most, maybe less, and should read slight and a little hunched against the rain.
4. **Mitten hands, arms hung stiff.** The hand holding up the phone is the second most looked-at thing in the frame.
5. **He melts into the door.** His hoodie and the door behind him are hatched in the same level strokes, so figure and ground merge. On people the strokes should wrap round the form; on the door's stiles they should run up and down.
6. Keep the tape, and let him lean in to read it.
7. Keep the Wrong Man's box, and make the marks a system (idea 5 below).
8. Keep the gold leaf.
9. **The check tag lost its odds.** The browser build prints "even" or "unlikely" beside the number. In Godot it says only "Medium 8". The odds word should come back, and hovering the tag should show where the number comes from.

### Frame 3, the room from his stool (`review/room.jpg`)

1. **One block of flat night.** The ceiling and back wall fill nearly half the frame with unbroken dark, and there's almost nothing between lamp and shadow. The room needs its middle tones: pendants lighting their tables, the bar's glow, the TVs, a little light off the carpet, so the depth reads.
2. **The same mannequin, over and over.** Dark silhouettes with keylines, no faces, one build, nobody moving. You can't tell the big man from his buddy.
3. **You can't tell which table is 28**, or that it sits in the front window. The window itself doesn't read.
4. **Red is spent on the carpet.** Red ink should be rare and mean something: the sign, blood, the Fighter. The carpet can print in amber and night.
5. Keep the lamps drawn in light.
6. Keep the sconce scallops.

### Frame 1, out through the door (`review/door.jpg`)

1. **Bare paper reads as unfinished.** The vestibule's right wall blows out to blank stock. The brightest light should be bare paper, but only in small doses.
2. **Who's in the truck doesn't read.** The sister at the wheel and her boyfriend in the back are the reason to look past the kid, and they're lost behind the glare.
3. **The column sits empty until the end.** Text starts at the bottom and climbs, leaving two thirds of the panel bare. It should start at the top and read down, like a page.
4. Keep the rain on the glass, and give it sound.
5. Keep the sticker on the door.

### Frame 4, four drinks in (`review/drunk.jpg`)

1. Keep the slip, and build the rest of his body into the print the same way (idea 1 below).

### Not in any frame

- **It's never been seen moving.** The stills are good, but walking through fine strokes and keylines can shimmer and crawl. It has to be tested in motion, at the frame rate Hutch's machine runs.
- **One post of eleven.** The bar, table 28, the pool table, the hall, the kitchen, the keg room, the deck, the lot and upstairs don't exist in 3D yet.
- **No body of his own.** It's first person with nothing of him in view: no hands, no sleeves, no stool under him.
- **Silent.** The browser build has a room you can hear. The Godot scene has nothing.

## Needs work: the game

- **The Godot scene doesn't run the game.** No Ink, no choices, no dice, no Head, no saves. Godot can't read Ink out of the box and the usual add-on can't be fetched from the cloud workspace, so the Ink runtime gets written in GDScript and checked against the browser's, line for line, over thousands of random nights.
- **Every system has to come across whole.** The Head (the five seats, their pulls on each other, and the tension that makes checks swing), checks and their odds, the voices' barks and lean-ins, the word on him, his notes, the floor sketch, drink, hurt, money, the clock, and saves.
- **The picture has to earn its place.** In the browser the plates illustrate the text. In 3D, if the room only sits beside the column, it's a slower browser build. The room should carry what the text doesn't (who's where, what they're doing, the licence in his hand, the truck idling) and the player should act in it: look, take, walk, throw.
- **Some teaching is written for the browser.** "Tap a lit spot to go there" and the like need versions for a room you walk, and the Manual has to teach looking and handling too.
- **Ten choices at the door is a lot to hold in a narrow column.** They all stay (it's the genre, and each one is real), but several are acts you should be able to do in the room: take the phone, scan it, look past him at the truck.
- **The Head works better felt than read.** The graph in the browser's sidebar is clear, but it's a diagram you check, not something you feel. It can stay as a page in his notes while the tension moves into the print itself.
- **The stand-in lines are Claude's.** The Father's line in the room view ("He's in front of you. Not over there.") is a placeholder. Hutch's writing prompts stay untouched.

The browser build at the same moment (`review/browser.jpg`): 1, keep the floor sketch as the paper in his pocket and let the room itself be how he moves; 2, keep the Head's graph as a page in his notes and move the tension into the print; 3, keep all ten choices and let the room answer some of them; 4, keep the clicker in his hand.

## Invent: what only this game would do

1. **The print is his body** (this pass). Drink already slips the plates. Push it all the way: tension coarsens the cut and lets the red bleed, hurt thickens the red at the edges of his sight, his heart pulses the ink when his head is loud, and late in the night the ink starves and the strokes break. You read his state off the picture, with no meters.
2. **Looking is choosing** (this pass). "Look at him, not the phone" becomes something you do. Rest your eyes on his face and that choice lights up, and the voices lean in on whatever you're looking at, the way they lean in on the browser's pointer. The numbered list stays, for keys and clicks.
3. **Things in his hands** (this pass). Take the phone and it comes up to your eyes. Tilt a licence under the lamp and hold it beside the tape. Thumb the clicker. Flip the binder. Looking hard at the right thing is how you earn the edge on a check.
4. **The room moves when you're not looking** (this pass). While you watch, people breathe, shift and turn their heads. The bigger moves happen between glances, so looking back is like pulling a fresh print: someone's sat down, someone's gone out for a smoke. It's how a doorman takes in a room, it suits the print, and it lets the figures keep held poses.
5. **The voices draw on the room** (this pass). Each in its own hand. The Father rings things, the Wrong Man boxes them in broken lines, the Fighter slashes, the Manual labels. A mark stays on what a voice has noticed until it's dealt with.
6. **Dice on the ledge** (this pass). Real dice, thrown from his hand onto the ledge by the door or the bar top or the table, lit by the room and printed like everything else. You still hold, shake, and wait.
7. **The night as a proof sheet** (later). At closing, the ledger becomes a stack of prints of the night, one for each moment that mattered, printed the way he saw it: drunk, calm or hurt.

## Quality of life

- Autosave at every choice, Continue on the title, three save slots.
- Settings: text size, how fast text appears, mouse sensitivity and inversion, field of view, sway off, grain strength, fullscreen, volume.
- Keys for everything: 1 to 9 to choose, Space to go on, E to take or use, Tab for his notes and the Head, M for the floor sketch, Esc to pause. Mouse works throughout, and a controller covers the basics.
- Scroll back through the whole night's text.
- Each check explains its number: the voice, drink, hurt, the moment and his tension.
- A way to hurry text you've already read.
- A setting that turns off the sway for anyone the drunk effects make queasy.

## Immersion

- First person from his stool, with his hands and the stool under him.
- Walk the room between posts, or pick a spot on the floor sketch and he walks there.
- The room fills and empties with the clock, and the light follows it. Last call brings the lights up.
- People who breathe, glance at him, drink and lean, and move between glances.
- The door lets the weather in: a gust, the rain loud for a second and then cut off.
- The clicker as the room's count, clicked as people pass him.
- Placeholder sound for the rain, the room, the door, the clicker and the dice, marked for Hutch's own audio.

## What this pass builds, in order

1. Ink running in Godot, checked against the browser build's to the letter.
2. The engine: the Head, checks, barks, the word on him, his notes, the floor sketch, saves.
3. The pub in 3D: the door post fixed as above, then the bar, table 28, the pool table, the hall, the kitchen, the keg room, the deck, the lot and the stairs up, with people placed by the clock and the story.
4. Playing in it: the column, the dice, things in his hands, the marks, the print as his body, looking as choosing.
5. Around it: title, pause, settings, saves, placeholder sound.
6. Downloads for Linux and Windows, and a version that plays in the browser if Godot's web export fits in an artifact. The browser build stays playable at its link. Then log it all as PROPOSED, commit and push.

### Waits for later

- Director mode inside Godot. Keep editing in the browser build: both read the same Ink, so Hutch's edits reach both.
- Faces beyond the carved style, Hutch's own audio, and photos of real bar surfaces.
- Full animation. People keep held poses, moving between glances.
- Days two onward.

### Defaults picked, Hutch's to overturn

- The column stays on the right at about a third of the screen.
- Three inks, carved faces.
- Claude's stand-in lines stay marked as Claude's until Hutch rewrites or keeps them.
