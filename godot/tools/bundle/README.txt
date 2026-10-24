THE BOUNCER
Wednesday, from the interview to close. The third Godot build of 24 October 2026.


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

    Go somewhere      click the floor. In the bar he walks there, round the tables and whoever's
                      standing, and a pale ring on the floor shows where he'd end up. The floor
                      round a place (his stool, the bar, table 28, the pool table, the jukebox)
                      takes him to it. Or click the place's name in the column, under GO WHERE
                      HE LOOKS. E with nothing under his eyes walks him to the floor he's
                      looking at; Space on the way hurries him
    Choose            click a choice, or press its number
    Go on             Space or Enter, where the night stops to let a moment land
    Look round        drag across the room, or the arrows (or W A S D); the wheel narrows his eyes
    Look at a thing   rest the pointer on what a choice is about and the choice lights up;
                      E or a click makes it. Rest it on anything else whose name comes up,
                      fainter, and E or a click looks at it
    Throw the dice    hold Space or the mouse button to shake, let go to throw
    In his hands      click it to turn it over (drag a licence to tip it to the light), E to look
                      closer, Q and R to go through it, Esc to put it down. What the voices make
                      of it is above what he does with it: keep one, or none
    Notes, sketch     Tab (Q or E turns to the page of what's on him), M
    Pause, settings   Esc. Every choice is saved as it's made; there are three nights.
    On a pad          either stick looks round; the d-pad goes through the choices and A makes one;
                      Y walks him to the floor he's looking at

Saves and settings are in ~/.local/share/The Bouncer/. A night saved by an earlier build was
saved under a story that has changed since. If you continue it, the column says so and it goes on
from the floor rather than from the middle of a scene, and some of it won't line up. Start
Wednesday over for the night as it is now, with everyone in their own voice from the first line.


WHAT'S NEW SINCE THE SECOND BUILD OF 24 OCTOBER

The room's sound, and its talk.

- The room goes on by itself while he stands there. Table 28 laughs at something and slaps the
  table, looks up at the hockey together and goes up for a goal or groans at a near one. The
  bartender wipes the bar down, pulls a pint at the taps and sets it down, rings something
  through the till. Someone coughs; a smoker on the deck lights up; now and then a glass goes over
  at a table and whoever's near looks. The pool game goes on shot by shot while the table's out
  of his sight, with a new break every so often.
- People go to the washroom: up from their place with the stool scraped back, down the back hall,
  the door, a minute or two, the flush, and back to where they were.
- Every sound comes from where it happens: louder near it, from its side as he turns his head,
  and lower and duller through a wall or the floor. The cook has a radio on in the kitchen till
  he goes at eleven.
- He overhears the room. A few lines at a time, written over the heads of whoever's saying it as
  they say it, their mouths going and the others turning to them: table 28 on the price of diesel
  and the new kid on the door, the big man's buddy talking too much, the woman from room nine on
  her drip, two at the bar on HAARP, the light over the mainland or the big one being overdue.
  Near him it's clear, further off or over a full room it's fainter, and out of earshot it isn't
  heard. Talk behind him shows at the edge, on the side it's coming from. One conversation at a
  time, each once a night, and never at the table he's at.
- Once he's heard one through, a voice in his head can have something to say about it.
- None of it moves the clock: the night still goes by what he does.
- The overheard lines are drafts, each in its speaker's voice, in content/rules/talk.yaml in the
  repo, for you to rewrite, cut, or add to.
- Every sound is still a placeholder. godot-project/docs/SOUNDS.md lists every one: what it's
  for, where and when it plays, and how to put your own recordings in.
- The voices' answers to the talk are new rules, so a night saved before says the story has
  changed when you continue it, and goes on from the floor.


WHAT'S NEW SINCE THE FIRST BUILD OF 24 OCTOBER

The people are alive.

- Everyone breathes, shifts their weight, and looks about: at whoever they're with, at whoever's
  talking, at their phone or their glass, round the room. The eyes go first and the head
  follows; they blink, and the lids follow the eyes down.
- They look at him: when he comes close, when he's been watching them a while, and while they
  talk to him. Some hold it (the constable stares it out); the kid meets it for a second and
  keeps away from it after.
- Their mouths go with what they say, line by line as the column prints them. In Gary's office
  the man across the desk says the answers you pick for him.
- Whoever has a drink lifts it now and then. At table 28 each of them has a glass near the edge
  now: they lean in for it, drink, and put it back.
- Nothing in the story changed, so a night saved before goes on where it was.


WHAT'S NEW SINCE THE FOURTH BUILD OF 23 OCTOBER

New faces.

- Everyone's head is new, made from scratch on the measurements of real heads, and a woman's on a
  woman's. No more square jaws: the jaw narrows to the chin, the skull is long enough at the back,
  the ears lie close, and the neck comes up under the skull, not under the ears.
- A face comes from who they are: their age, heavy or lean, and the small differences everyone
  has, drawn from their name, so nobody shares a face and each person keeps theirs wherever they
  turn up. The old have longer ears and noses, thinner lips, hooded eyes with bags under them.
- The eyes have lids over them, and the lips, the lashes and the brows are drawn. Hair shows under
  caps and toques, thinning hair is a horseshoe, and fair hair doesn't vanish into the skin.
- Nothing else changed, so a night saved before goes on where it was.


WHAT'S NEW SINCE THE THIRD BUILD OF 23 OCTOBER

The fix for counting the room.

- After a count, "That's enough counting." left only "Count the room." in the column, because
  the ways round the room were all out in the room itself. Clicking it started the count over, so
  it went round and round. Now the column names every place he can go, under GO WHERE HE LOOKS:
  the door, table 28, the pool table, the bar, the back hall, the kitchen, the deck. Click a name
  and he goes there, the same as clicking the place in the room. Rest the pointer on a name and
  the place lights up in the room, with the night's words for it, if it's in front of him. The
  names aren't numbered: the number keys are still for what he does where he is.
- The floor doesn't offer to count the room again for ten minutes after a count. It hasn't
  changed yet.


WHAT'S NEW SINCE THE SECOND BUILD OF 23 OCTOBER

The skeleton's third milestone: his hand.

- Handling's two choices, as you decided: whenever he's holding something, what to do with it and
  what to think about it. What the voices make of it is above what he does with it, under WHAT HE
  MAKES OF IT, each in its own hand: his father, the manual, the fighter, the wrong man, and table
  28 and the kid if he's let them into his head. Keep one, or none. A read he keeps takes no time,
  goes in the column and on his notes beside the thing, and that voice speaks up more for the rest
  of the night. There are reads for Gary's shirt, his flashlight in the keg room, table 28's folded
  fifty, the straw off the office mirror, the big man's keys, the pint he pours himself, and each
  thing in the last doorman's jacket.
- His pockets. His notes have a second page, ON HIM (Q or E turns to it): his jacket's right pocket
  (the flashlight from his last door), its left and inside pockets, his jeans (his wallet and the
  key to twelve), what he's left in the lost-and-found drawer, and what's up in room twelve. Click
  a thing there for whose it is, the trouble he's in if he's found with it, what it's good for,
  what it's worth, and the read he kept. The summary at the end of the night says what was on him.
- The lost-and-found drawer under the till. Once Gary or the bartender has told him the last one
  left his jacket, ask her where it is and she pulls the drawer out for him: three winters of
  toques and phone chargers, and at the bottom, folded, the last doorman's jacket. After that it's
  his to open whenever he's at the bar, to put things in or take them out; or after hours, when
  she tells him where the jacket is.
- The jacket has a thing in it for each of table 28's four stories about him, and every one of
  them is true. The door float, with his sum on the back of the till tape: two Fridays in September
  paid short, two hundred and eight left (give it to her, put it back, or take it). A beer mat with
  his count of the rats, doubling, and the knot drawn, BEHIND 28 (it shows the way in the
  crawlspace). Two ferry tickets, foot passengers, the last boat on the Friday he went, neither one
  torn. And the licence of the boy he let in, who's on page eight of her binder. Who the woman was,
  the jacket doesn't say; she's yours, if you want her. Under the glove there's a paperback on
  aikido, with a flyer from the community hall in it for a bookmark.
- The first temptations. From ten the lager spits foam, and if he hasn't changed the keg himself
  she goes down the trapdoor to do it and leaves him her bar for two minutes. Watch it, go back to
  his door (and table 28 helps itself), or pour himself a pint: drink it down before she's up (his
  Dexterity against the clock), take it to the ledge as if she'd poured it, or tip it down the
  sink. She counts when she comes up. And every drink he asks her for, she's in it with him: write
  his drinking in the log the way it happened and it says how many she poured, and she has
  something to say about that.
- The big man's keys, taken off him at close, are in his hand to decide: his daughter, while she's
  in the lot; the drawer; or his own pocket. If the big man walked, he's back at two in the
  morning, soaked, knocking on the glass of the front door under the light. Give them back, or
  tell him noon through the glass.
- The things are drawn, and in his hand: in his open hand, palm up (the flashlight, the key to
  twelve, the big man's keys, the straw, Gary's shirt, the float bag, the paperback), held up the
  way he holds a licence (the beer mat, the ferry tickets, the fifty), or round a pint. Click one
  to turn it over in his fingers, E to bring it closer. The jacket lies folded on the bar.
- The boy on page eight of the binder has his cap on now, the way she'd have taken his picture at
  the door; on his licence it's off, the way they make you for the photo.
- The old man at the end of the bar notices what was in his hands, and what he did behind her bar.
- The story has changed (the jacket, the drawer, the pour, the keys), so a night you're partway
  through goes on from the floor.


WHAT'S NEW SINCE THE FIRST BUILD OF 23 OCTOBER

The skeleton's second milestone: going where he looks.

- He goes where you point. Click the floor anywhere in the bar and he walks there, at a walk,
  round the tables, the stools and whoever's standing, and stops there still looking the way he
  was. A pale ring on the carpet shows where a click would take him, and another stays where he's
  going till he's there. A walk across the room costs a minute of the night, so whatever's due
  happens while he's at it; a step or two costs nothing. Wherever he's standing, the dice tray
  goes down a step off him.
- The places are in the room now, not in a list. The row of ways to go at the bottom of the column
  is gone, and the column says GO WHERE HE LOOKS instead. Rest the pointer on the door, the bar,
  table 28, the pool table or the hall's doorway and it lights up, as before. Click the floor
  round a place (his stool by the door, the bar and its stools, table 28, the pool table, the
  jukebox) and he goes there, the same as clicking the place itself. From a place, a click on the
  open floor is the way back onto it, and he walks out to where you clicked. The sketch (M) still
  takes him anywhere lit on it.
- In the middle of something (someone talking to him, a check, someone at the door), a click on
  the floor only turns his head there. He goes when the night lets him.
- The places are places to settle. He sits on his stool, and at the bar he leans on it now, on
  his forearms in the gap in the stools, the way the story always said he did, and you hear his
  weight go onto it. Back onto the floor from a place, he takes a step or two off it into the room
  instead of going back to one spot in the middle.
- A doorman doesn't run in a bar. Space still hurries him, and across the bar's floor the room sees
  it: heads come round, his father has something to say about it (keep doing it and the manual
  and the wrong man do too), table 28 wants to know where the fire is next time he's over, and
  the bartender tells him off at the bar. That costs him with her, the first time and the third.
- The clock at the top of the column runs up to the night's a minute at a time as he walks and
  the lines come in, instead of jumping: ten minutes take a couple of seconds, an hour about five.
  His notes and the menu stop it.
- The rail by the pool table, the skeleton's third place to settle, waits for the room's next
  pass at its furniture. For now he stands at the corner of the table to watch.
- The story has changed a little (the walk across the room, what's said when he runs), so a night
  you're partway through goes on from the floor.


WHAT'S NEW SINCE 17 OCTOBER

The skeleton's first milestone: Gary's office, and the walk to the Sov at dusk.

- The game starts in Gary's office now, as you decided. Wednesday, four in the afternoon, Van
  Dusen Holdings: the front room of his mother's house on the old main street, across from the
  bank that's been a cafe for eleven years. You see the doorman through Gary's eyes, across the
  desk, and answer for him: how he sits, his licence, where he was before, why he left, fights,
  what he does while Gary's on the phone about the prime rib, the rye from the bottom drawer, the
  rule about table 28, any questions, the rent, the shirt, the form. Gary hears two voices of his
  own while he sizes him up: THE TILL, which prices everything, and SENIOR, his dead father, who
  calls him Junior. They're never heard again after the office.
- The office is built, in 3D: Gary's desk and his lamp, the chair across it, the bookkeeper at
  her desk writing in her ledger, the Sov in 1958 on the wall behind him beside the first
  licence, the box of shirts, rain on the window and the old bank across the street. From his
  chair Gary watches the doorman in the doorway, then across the desk, and turns to the
  bookkeeper while she does the papers. The licence is in Gary's own hand, older and paler than
  the doorman's, with a signet ring and a blue cuff, his thumb over the name. The health
  inspector's notice on his desk is the one the doorman reads upside down, with PEST circled
  twice.
- It's hard not to get hired, but not impossible: mean the threat, walk out, or be rude to both of
  them, and the game ends there. Lies Gary catches cost him with Gary, not the job.
- His stats. Strength, Constitution, Dexterity, Intelligence, Wisdom, Charisma and Gut Brain, out
  of 10. Your answers set them: each answer that says something about him puts a point on two of
  them, and he comes out of the office between 2 and 7. They print on a card as he goes down the
  porch steps, and they're in his notes (Tab) from then on, with any old number struck through when
  one moves.
- Every check in the night uses one now. The choice says which, and his number for it; the dice
  say where every point came from. The targets went up by four, an ordinary man's 4, so a man
  like that has the odds the night always gave him.
- Constitution holds his drink. A big man takes a couple before they show; the top of the column
  says "feels like" when he's holding some off, and only the ones that show reach the dice and the
  print. Eat at the Esso and he holds one more. Walk past it hungry and he's a point worse in the
  body all night, and a point sharper in the gut.
- The walk to the Sov at dusk, his own eyes from the porch steps, and the town built for it: the
  old main street down the hill (the library, the Legion with its field gun aimed at the bank, BANK
  still cut in the stone over the cafe and its chalkboard, the thrift store, the video store shut
  for years, two churches), the old man from the end of the bar at the rail under the light at the
  end of the wharf, the highway along the water, the Esso and its kid up on the ice freezer, who's
  watching a light over the mainland that hasn't moved in two nights and rates a machine's answers
  at four cents each, the Sov's sign with its dead E, and then the seawall, to watch the door from
  outside for two hours, or up to his room. What he sees comes back during the night.
- The light goes by the clock: grey rain at four, the street lamps coming on from half past, dusk
  by ten past five and dark by six. The first time he gets to the Sov from the town he's facing
  its front in the lot, the door and the windows and the sign; after that his head's his own again.
- Rest the pointer on things in the office and along the walk and their names come up, as at the
  Sov: twenty-one of them, and in the office it's Gary who looks.
- His security licence, the one Gary looks at: SECURITY WORKER, his licence number, the dates, and
  his name drawn as bars, since the name is yours to give.
- The sketch (M) is the town while he's walking, and the Sov's floor once he's in. The notes (Tab)
  and the sketch had been coming up as blank pages: the paper was drawn over what was on it. Fixed.
- Sound for the new places: rain on Gary's window and the bookkeeper's one-finger typing, the
  Esso's canopy buzzing over the pumps and the highway, the water and the road on the seawall.
- Two writing prompts for you in the new parts: the opening lines, which are read in the office
  now, and the old main street (look at the bank across from Gary's porch).
- The title says Start Wednesday.
- The story has changed (a new opening, and stats in every check), so a night you're partway
  through goes on from the floor.


WHAT'S NEW SINCE 15 OCTOBER

Your notes on the last build, and what came up fixing them:

- The kid. Once you'd taken his phone and let him in, the doorman got up and walked off toward
  the pool table with the phone still in his hand, and the kid was gone. Now he hands the phone
  back (or the card, if the kid went and got it) and stays on his stool, and the kid walks in past
  him to the jukebox. Turned away, the kid walks back across the lot and gets in the pickup, and
  his sister walks up from it later with her card in her hand. When she comes back to the door to
  ask about her brother, she's at the door; she used to ask it from the pool table.
- Walking. He used to glide from post to post on rails, through the stools and whoever was in the
  way. Now he walks the room the way a big man gets round a full bar: round the tables, the stools
  and the people, through the doors (they open as he gets to them and swing to behind him), at a
  walk in the room and a bit quicker across the building. Hold Space while he's walking and he
  hurries. Down to the keg room he lifts the trapdoor back first, and the page still goes blank
  for the ladder and the stairs.
- He goes where the page sends him, when it does. Whenever something happened (the card machine,
  the phone, a rat, a fight starting) he used to be moved to it before a word was said, and
  between scenes he'd wander out onto the floor on his own. Now he stays where he is, his head
  turns to what's happening if he can see it, and he goes on the line that sends him. Sent two
  places at once (over to the bar to ask, then back to the door), he stops at the first, on his
  feet, for a moment, and goes on.
- When he gets to someone, his eyes are on them: the bartender when he leans on the bar or she
  holds the phone out to him, Dennis's wife at table 28. Anywhere else he still gets there looking
  the way you left him.
- People walk. Ten of them do now: the kid, his sister, her boyfriend, GOOD SHOES, HI-VIS,
  Dennis's wife, the constable, the big man, his buddy and Dennis. They come in from the lot,
  walk to where they're going, and walk out to the pickup or off into the dark, instead of
  appearing and vanishing. The bartender comes along behind the bar to wherever he's standing at
  it. Everyone else still moves between one look and the next.
- A licence held out to him from across the room is in his hand when he gets there, not on the
  way, and one held out by someone still walking up to the door is in his hand when they get
  there. A card or a phone he's handed back goes back.
- The bellies. The heavy men had a ball stuck on the front of them. Now the weight is in the
  body: it comes out from under the ribs in a long slope, sits lowest a hand below the navel and
  tucks back under the belt, with no seam. Their shoulders slope from the neck instead of standing
  out square, and their arms carry less of it than their middles.
- Where he stands. At the bar he was standing on whoever was on the stool beside him, with the
  back of a head filling the bottom of the picture. The bar has a gap in its stools now, across
  from the bartender, where staff stand and people come to order, with a steel rail either side
  of it on the bar top; he stands in it, and the dice roll between the rails. The boyfriend, at
  the bar, stands at the till end, where you pay. At the pool table he was standing in the kid's
  sister, and at the end of table 28 in whoever was watching the game; they've moved, and a check
  now makes sure nobody's spot is ever under his feet. Going to table 28 he stands at the end of it
  until he sits down with them.
- The crates in the kitchen were in the doorway he walks through; they're stacked by the walk-in.
- The story has changed (where he goes and when), so a night you're partway through goes on from
  the floor.


WHAT'S NEW SINCE 14 OCTOBER

- The jukebox. It couldn't be clicked: nothing on offer was about it, so nothing in the room was
  pinned to it. Now "The jukebox" is somewhere to go from the pool table and from across the room,
  and he walks over and stands at it. There's a scene there: the list it keeps of what's been
  played most in the building, getting it turned down a notch from the till (with it down he hears
  the pool table start before it starts), and standing at it like you're picking a song, watching
  the room in the dark of the screen. The top of that list comes back at close.
- Every choice that's about something in the room is pinned to it, and each one has been checked
  from every post, over twelve nights, for a clear line from his eyes. From the back hall the room
  is only what's through its doorway; from the deck the lot is what's past the corner of the
  building; the trapdoor is marked over the bar, where you'd look for it. A choice that takes him
  somewhere he can't see from here is pinned to the door, the opening or the ladder he'd go by.
- The rest of the building answers too. About thirty things nothing on offer is about, from the
  dartboard and the tape on the door frame to the pilings in the keg room and the sign on the
  roof: rest the pointer on one and its name comes up; click, and the column says what he sees,
  and now and then a voice answers it. The clock doesn't move for a look. The lines are Claude's
  drafts; two of them (the back bar, the taps) ask you what's really up there.
- The payphone at the end of the back hall: he walks round to it and reads the wall, where before
  he read it round a corner. Up close it's a payphone now, its card, its keys, the handset on its
  steel cord, and the wall round it has forty years of ink on it: what the scene names (the truck
  for sale, the heart and the initials scratched out, the meeting at the church hall up high) and
  the numbers under it, gone faint.
- The dice on the ground. Where there's nothing in front of him to throw onto (the floor, the hall,
  the keg room, the deck, the lot, his room), a tray goes down a step away first, a server's round
  one, cork inside a black rim, and they're thrown into it and stay in it. On the ledge by the
  door, the bar, the tables and the felt they go down where they always did. Ground only, as you
  picked.
- His head stays where you leave it. He walks looking where he's going, unless you look somewhere
  else on the way, and gets there still looking the way he was: the place no longer turns him to a
  view of its own. Nothing turns his head for him but what would turn a man's: someone coming into
  it, the dice going down (his eyes go to them, and back where you had them after), and sitting
  down. Look away at any time and nothing pulls you back.
- The story has changed (the jukebox, the looks), so a night you're partway through goes on from
  the floor.


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

Every sound is still a placeholder made in code, holding the place for a recording.
godot-project/docs/SOUNDS.md lists every one: what it stands for, where and when it plays, and
how many takes it has. To put one of yours in, give it the same name (.wav, .ogg or .mp3) and
put it in a folder called audio inside game/ (next to the game), or in
~/.local/share/The Bouncer/audio/, where it carries over to the next build; it's used from the
next start. More takes of one sound go in as laugh_2, laugh_3 and so on, and the game picks among
them. Mono for anything in the room, since the game puts it where it happens. The names:

    the room's layers   amb_room_tone amb_talk_a amb_talk_b amb_shout amb_juke amb_rain_glass
                        amb_rain_out amb_rain_roof amb_fryer amb_fan amb_radio amb_tube
                        amb_cellar amb_rats amb_sea amb_keys amb_canopy amb_traffic
    the room's own      glass_down clink laugh laugh_one slap cheer groan cough stool pour wipe
                        till door_wc flush cue clack pocket break lighter spill
    his                 beep_ok beep_bad (the scanner) thump (the door) thud glass scratch ring
                        bell rattle tick tock (the dice) stamp printer tear pen page card swipe
                        whisper steps choose click_ui
