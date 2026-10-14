THE BOUNCER
Wednesday, the test shift. The Godot build of 14 October 2026.


PLAY IT

    ./play.sh                 in a terminal in this folder (or: sh play.sh)
    ./play.sh --fullscreen    straight to fullscreen; the pause menu has it too

The whole game is the one file in game/. It runs on OpenGL 3.3 (Godot's Compatibility
renderer), so the 3080 has it easy. Wayland is fine: it runs through XWayland, or natively with
./play.sh --display-driver wayland.


OPEN IT IN GODOT

    ./open-in-godot.sh

That opens godot-project/ in the Godot editor. The project was made in Godot 4.7.2. If the
machine has a Godot 4.7 (Arch's godot package, or the Flatpak) it uses that. If it doesn't, it
offers to fetch the official 4.7.2 editor (78 MB) into tools/ here, checks it against its
fingerprint, and keeps it for next time. The first time the project opens, the editor spends a
minute importing the models and textures. Press F5 in the editor to play from there.

By hand instead: open Godot 4.7, Import, and pick godot-project/project.godot.

To export a build of your own from the editor, it needs the export templates once (Editor >
Manage Export Templates > Download); the Linux, Windows and Web presets are already set up
(Project > Export). godot-project/README.md has the rest: what each folder is, the checks, the
export steps.

The story itself is written in Ink, in the GitHub repo (justinfaubert/the-bouncer, content/ink).
godot-project/data/content.json is that Ink compiled, with every rule; node tools/build.mjs in the
repo writes it, and the browser build plays the same file.


HANDS ON

    Choose            click a choice, or press its number
    Go on             Space or Enter, where the night stops to let a moment land
    Look round        drag across the room, or the arrows (or W A S D); the wheel narrows his eyes
    Look at a thing   rest the pointer on what a choice is about and the choice lights up;
                      E or a click makes it
    Throw the dice    hold Space or the mouse button to shake, let go to throw
    In his hands      drag to turn it, E to look closer, Q and R to go through it,
                      Esc to put it down
    Notes, sketch     Tab, M
    Pause, settings   Esc. Every choice is saved as it's made; there are three nights.
    On a pad          either stick looks round; the d-pad goes through the choices and A makes one

Saves and settings are in ~/.local/share/The Bouncer/. A night saved by an earlier build was
saved under a story that has changed since. If you continue it, the column says so and it goes on
from the floor rather than from the middle of a scene, and some of it won't line up. Start
Wednesday over for the night as it is now, with everyone in their own voice from the first line.


WHAT'S NEW SINCE 5 OCTOBER

- The hologram shows. It only gleamed, as you said: its lines came out about a pixel and a half
  wide on the screen, and a sheen over the whole card washed out what was left. Now the foil is
  drawn bold and only the foil lights. Pick up a licence and tip it toward the lamp: the waves
  ripple down the card in colour, the seal over the corner of the photo lights ring by ring with
  a light running round it as the card turns, the face comes back in the foil, and the birthday
  runs along the bottom in tiny print. Away from the lamp it's a pale outline in the laminate. A
  fake's hologram is printed ink and sits still however you tip it.
- The cards print CLASS 5 and 183 cm, not CLASS 5.0 and 183.0 cm.
- The browser build's licences have the same hologram.
- His hand is as it was. The grain is the print's strokes running round his fingers, and it stays.
- The story hasn't changed, so a night you're partway through carries on where you left it.


WHAT'S NEW SINCE 4 OCTOBER

Your notes on the last build, one at a time:

- The text column reads clean. The paper's grain and mottle belong to the picture of the room;
  the column is now one even ink with the words knocked out of it, and only the paper's slowest
  drift, broader than a paragraph, comes through.
- No more empty blocks. Rest the pointer on a choice and a voice can lean in with a line; its box
  was being laid out two thousand pixels tall, which is what showed as a big empty block in the
  column. The box now fits what's said, beside the choice. The word on him (what a group says
  under a line) sits at the right with its stamp and wraps properly when it's long.
- The receipt lines up like a till's: what, a run of dots, and how much, on one grid of
  characters. When the how-much won't fit on the line, the dots run to the edge and it prints
  underneath, indented, instead of being squeezed down the far margin a letter at a time.
- The clicker is gone, and the counting chore with it. Nobody hands it to him. The door still
  counts: everyone he lets in past the stool is on the till tape, and the ones who got in some
  other way still come back to him at close.
- The licences have a real hologram. Pick one up and tip it toward the lamp (drag, or turn it in
  your hand): the foil wakes, its colours run through the spectrum as the card turns, and a
  bright band crosses it where the foil catches the light square on. Away from the lamp it's a
  pale outline in the laminate. The fakes' holograms are printed ink and sit still however you
  tip them, which is how you tell.
- The dice are objects now. Each throw is worked out as two cubes with weight, bounce and grip:
  off the ledge by the door and the wall behind it, the bar, the pool table's cushions, the
  glasses on table 28's table, the steel in the kitchen, the floor, and each other, until both
  lie still. The surfaces and walls are fitted to the models, so a die stops against a cushion's
  nose instead of inside it, and a throw only counts if both faces end up where he can read them
  from where he stands, not tucked under a rail.
- Everyone talks like themselves. Until now nearly everyone spoke the way the narration does:
  short, flat, and a lot of it landing as rules, which is the Father's register. Every line from
  someone in the room has been gone through (650 of them, about 300 rewritten), and the word on
  him from each group too. The bartender talks while she works, calls him Door and the owner
  Junior; the cook barks; the big man calls him bud and goes to two words when something lands;
  the old man at the end of the bar never uses a contraction; the kids are lowercase. The facts,
  the choices and what they lead to haven't changed. bible/10_VOICES.md in the repo is the guide
  to who talks how, and your writing prompts are where they were.

Everything new is logged as PROPOSED in the repo's bible/05_LOG.md, for you to keep or cut.


WHAT'S NEW SINCE THE FIRST GODOT BUILD (4 OCTOBER)

Every choice now has a consequence. Each one changes something the night comes back to later: a
line someone says, a person's mind about him, the word on him, what goes in the book, who's
where. A tool (tools/audit.mjs in the repo) reads the whole story and lists any choice whose
effects nothing ever reads. It lists none. The only choices that change nothing but the clock
are the five plain ways out of a scene.

Some of what that changed, in the order the night has it:

- The kid, his sister and her boyfriend are each in one place at a time, and the game knows where:
  at the door, in the vestibule, at the jukebox, locked in the single washroom, at the rail by the
  pool table, at the bar, in the lot, in the pickup. The room shows them there, and the voices
  keep up: nobody tells you the big man's kid is twenty feet away while the kid's out in the truck.
- Nobody walks in past him while he's on the door, and "Stay on the door" is never empty: the
  lot, the highway, the room behind him in the black of the window, and after midnight the door
  going the other way.
- Walk the doors and leave one propped, and the night remembers that he looked at it and left it:
  when the kids come in by the deck, and at close when he searches the building.
- Your five director-mode notes are in: the island running short after the card machine goes
  down (the diesel, the truck that didn't come off the ferry), "Stand at the door.", the keg
  room's office (the safe, the DUE BACK envelopes, the clamato, and the mirror on the desk, which
  he can put in the book, wipe clean, or leave), the Fighter's read of the boyfriend in your
  words, and the owner's "How is it tonight?".
- At close, times come out the way people say them ("quarter past one", "half an hour late")
  from the real clock, and the bartender's book reads what actually happened, down to the glass
  of water.
- Table 28's dog, the payphone, the night clerk, the old man's brick: small things you did or
  didn't do come back at two in the morning.
- Terry. Through the hotel door at the end of the back hall there's now a front desk: the
  counter with its bell and the register, the key board with most of the keys on their hooks,
  the stairs going up into the dark, and Terry on his stool with his chin on his fist. When the
  door's propped you can see him from the far end of the hall, watching the bar's TV. Go and ask
  him to leave it shut and you walk through to the desk, and the door's shut after.
- The constable, if the fight gets called in, stands inside the door in her duty jacket.
- The deck's rebuilt: level with the bar through the door, two steps down its side to the lot,
  and the chairs turned to the people sitting in them. A woman smokes at the top of the steps,
  and whoever the story has talking out there is out there: the two women under the awning,
  the man by the steps watching the pickup, or two of the mill crew at the far end.

Everything new is logged as PROPOSED in the repo's bible/05_LOG.md, for you to keep or cut.


SOUND

Every sound is still a placeholder made in code. A .wav, .ogg or .mp3 with the same name, in a
folder called audio inside game/ (next to the game), takes its place from the next start; more
takes of one sound go in as card_2, card_3 and so on. The names:

    the room   amb_rain_glass amb_rain_out amb_rain_roof amb_room_tone amb_talk_a amb_talk_b
               amb_shout amb_juke amb_pool amb_fryer amb_fan amb_tube amb_cellar amb_rats amb_sea
    things     beep_ok beep_bad (the scanner) thump (the door) gust rattle tick tock (the dice)
               clack (the balls) thud ring glass scratch till bell card page pen printer swipe
               tear stamp steps heart whisper lift choose click_ui
