# Log

Update this file at the end of every session: add a session entry, move items between the registers, and revise the open questions.

## Session log

### 2026-09-25 (Friday night), cloud session with no access to Hutch's files

- Claude proposed an oracle deck built on the 34 signed pentagons. Hutch turned it toward a game that takes Disco Elysium's framework somewhere else.
- Claude pitched a doorman protagonist with a relational psyche. Hutch named it *The Bouncer* and set the brief (`01_PILLARS.md`).
- Hutch set day 1 (a Wednesday test shift with rats), the first real shift on Friday, and the optional early shifts.
- Claude proposed the systems, the narrator frame, Godot with GDScript, the printed art direction, and the production and legal notes.
- Hutch asked for the plan to be carried over to a session linked to his machine. These files are that handoff.

### 2026-09-26 (Saturday), Hutch's machine and the project thread

- Hutch answered the Blocking Wednesday questions one or two at a time (the 2026-09-26 entries under DECIDED).
- Hutch asked to start building day 1: every thread on the night (the count, the big man at the pool table, the rats, table 28) branching into sub-choices with real outcomes, writing prompts left for him to write and rewrite, and the software bones (menus, and room to add art and music on top later).
- Claude wrote Wednesday in Ink: twelve files in `content/ink/`, about 24,000 words, from the prologue to the dawn ledger. The 33 places that need Hutch's material or voice are listed in `content/WRITING_PROMPTS.md`.
- Claude built the engine and a browser build around it (`prototype/web/`): title screen, the story page, the floor sketch, the voices in his head, his notes, the menu and settings, the incident log and the ledger, placeholder sound, and a slot for every piece of music, ambience, sound and portrait (`content/data/assets.yaml`).
- `tools/bots.mjs` played hundreds of nights: every scene reached, every night ends at 3:20 am.
- Published for Hutch to play as a private claude.ai artifact: https://claude.ai/artifact/J7S3kXF1LcQh3W8Z4u2nfi

### 2026-09-26 (Saturday evening), round two of the build

- Hutch asked for the build on his hard drive, writing prompts that fold easily into the game, a way to direct and edit seamlessly, harder work on the systems and the visual presentation, and design tips from Disco Elysium, improved on.
- Offline: one HTML file that plays with no connection (`releases/The-Bouncer.html`).
- Director mode: rewrite, cut, add or note any line while playing, reword choices, answer writing prompts in place, step back a choice to try the other branch. The Director's desk sends the edits to Claude, and `tools/director.mjs` merges them into the Ink.
- Systems: the voices answer each other by how they get on; a choice that lets a voice in or puts one out shows first what it does to his head; the floor sketch became his notes, with the time he saw each thing, fading as they go stale.
- Look: printed plates for eleven places, drawn as each place is when he walks in and tinted by the hour; faces from parts for the ten people with portraits; the page's light follows the shift clock.
- 1,000 bot nights: every knot and stitch reached, no problems.
- The reasoning is in `07_ENGAGEMENT.md`.

### 2026-09-26 to 27 (Saturday night), the polish pass

- Hutch asked to stop and look over what still needs work, then polish: the visuals still too rudimentary, wanting a more stylized, higher-quality look; presentation that adds to the satisfaction of play; dice that make the player feel apprehension; and whatever would be innovative, engaging and immersive. Hutch is writing the writing prompts over the next few days.
- Claude named eight things and did all eight:
  1. **Checks you wait on.** The dice tumble onto the mat, the second can hang on an edge, a row shows which totals would pass, and the result comes down as a stamp. The room dims and goes quiet while they're in the air.
  2. **The pictures are printed.** A print renderer screens every place and face the way a cheap two-colour press would (black and the sign's red, a hair out of register, ink skipping), and the plates roll onto the page.
  3. **Fewer walking choices.** The ways out of a place go in a row under what there is to do there, so going from the bar to the deck is one choice.
  4. **Consequences show where they land.** When something he does lands with table 28, the kids, the bartender, the owner or the cook, what they'll say about him appears under the line, red when it went against him (`content/rules/word.yaml`). Their faces look at him warmer or colder as he stands with them. Wet footprints on the door mat show people got in while he was away.
  5. **The first minutes teach.** THE MANUAL explains a check, the noise in his head, the word on him and a choice that changes who's in his head, each once, the first time it comes up.
  6. **A reload brings back the whole night**, not just the last stretch.
  7. **The room's noise follows the crowd:** the talk, the glasses, the pool table heating up, the jukebox, the rats and the rain, mixed by where he's standing.
  8. **The ending lands harder.** A plate of the hotel after close, one window lit, then the tally prints like the till's tape: rows with dots, what each group is saying about him, a pause before the bartender's word to the owner, a stamp, and the tape torn off.
- The word on him and THE MANUAL's lessons are Claude's drafts, for Hutch to rewrite. The sound is still synthesized stand-ins; a recording dropped into its slot in `content/data/assets.yaml` replaces one.
- 1,000 bot nights: every knot and stitch reached, no problems. Hutch's saved night from round two loads in the new build and plays on to the end.
- Published as version 4 at the same link; the offline copy is `releases/The-Bouncer.html` again (the offline and publish builds had broken on the stamp's texture, and were fixed).
- The bigger ideas that aren't built are below under PROPOSED, and in `07_ENGAGEMENT.md`.

### 2026-09-27 (Sunday), round three: things to handle, his skin, a head that reaches the player

- Hutch, after the polish pass: "the more you do, the stranger and more singular and therefore interesting it gets." Then: the game needs things to interact with, toys and things that trigger events; fine detail to put the player in his skin, his surroundings and his head; and a Head mechanic more deeply embedded in the game world, one that reaches out and feels the player, and shows it.
- Built, in four parts:
  1. **The head reaches for the player's hand.** When the pointer rests on a choice, or a finger holds one on a phone, a voice with something to say about it leans in. The voices also notice a long wait, a tempting choice pulled away from, reading back, and coming back after a while away (`src/ui/hand.js`, the `hand:` lines in `content/rules/barks.yaml`). Settings → The voices notice you.
  2. **The voices mark up the pictures.** A voice rings a detail of a plate in its colour and writes beside it, drawn on as you watch, with the sound of the pen (23 marks, `content/data/marks.yaml`, `#mark:` in the Ink).
  3. **Things in his hands.** The clicker is a toy: press it, zero it with the knob, and the voices answer. The dice are thrown by hand: hold to shake, let go to throw. Licences are cards to turn over, tip under the light and hold up beside the face of whoever handed them over; the regular in the good shoes can be recognised from page three of the binder that way. The kid holds up his phone, and the next photo on it is the pool table, taken from the lot. The binder under the till has forty sleeves to leaf through. Some choices can only be made with the hands (`content/data/props.yaml`, `src/ui/props.js`, `#prop:`, `#toy:` and `#unlisted` in the Ink).
  4. **In his skin** (Settings → In his skin). Drink puts the print out of register: the red slips first, then the pictures and the words double, and from the fourth drink the page sways; each drink going down lurches it. Hurt makes the edges throb. On the door, rain runs down the glass in the margins. His heart comes up while the dice are in his hand and in the air, faster the worse his odds, and while his head is arguing or worse (`src/ui/skin.js`).
- Hutch answered the writing prompt on the kid with the photo of his ID, in director mode: take the ID, size up the kid, look at the info, deny him if he doesn't have ID, and try to build a rapport in the short time the interaction lasts. Merged by hand: the scene keeps that order and gains small talk ("Rough night to be out in."); after it, a no goes down easier, and his sister arrives knowing the doorman was all right about it. The new lines are Claude's drafts.
- 1,000 bot nights: every knot and stitch reached, no problems. Hutch's saved night loads in the new build and plays on.
- Published as version 5 at the same link, with the offline copy refreshed.

### 2026-09-27 (Sunday afternoon), the future form

- Hutch, after playing version 5: the system being built is wonderful and the ID graphic was well done; the plates and portraits are interesting in their style but look amateurish. Hutch wants to talk about the game's future form: better than HTML, a more immersive world, perhaps in Godot, and more than a Claude artifact. "Let's talk about how to achieve greatness."
- Claude's read: HTML isn't why the pictures look amateur. They're drawn in code, and code draws like a machine: the same bottle down the shelf, one skull under every face. The ID works because it's design. Godot is still the move, for the room around the player and a game Hutch owns, but the look needs one artist's hand and real sources.
- Written up in `08_FUTURE_FORM.md`, and as a page with the evidence marked up: https://claude.ai/artifact/YL6FR7cPoxNWihnWchgztT
- Checked: Godot 4.7.2 runs and renders frames in Claude's cloud workspace (under a virtual display, software OpenGL). github.com and godotengine.org are blocked there; Godot came from the SourceForge mirror.
- Hutch picked the form: through his eyes, from his posts (DECIDED below).
- Camera test: the door post at 7:50 blocked out in Godot in grey shapes, with the lines from `door.ink` in the column (`sketches/door-camera/`, frames in its `frames/`). It follows the build's floor sketch, not the older one in `06_THE_HOTEL.md`. Found: the stool works beside the door, not square in front of it; from the door the bar is behind his right shoulder, so the end of the bar is a post of its own; a voice's mark can stay on the thing it marks while he looks away.

### 2026-09-27 to 28 (Sunday night), the look

- Hutch: going through his eyes feels like the right move. Hutch isn't a visual artist (AI image generation or some photoshopping at most) and will do the audio and refine the writing. Hutch asked Claude to take a crack at the modelling and texturing: "a coherent, novel visual design that feels good to look at while being a way to get away with a lack of visual complexity". And to push everything to git; Hutch linked their GitHub account.
- Claude's suggestions: the night, printed (the look, PROPOSED below); Hutch directs, writes and does the sound, and Claude does the models, textures, look and code; photographs of real surfaces are the most useful thing Hutch can give the look; AI images kept out of what ships (Hutch's call, question 12); keep writing in the browser build's director mode, since the Godot build reads the same Ink.
- The look test, in `sketches/door-look/` (frames in its `frames/`): the door scene from the camera test built properly and run through the press. The view out through the door, the kid with his phone, the room, the kid four drinks in, and the head turn. Every model, texture and shader was made in code: the people sculpted as signed distance fields from their looks in `content/data/characters.yaml`, the things modelled by script in Blender, the textures drawn in Python.
- Git: Hutch made a private repo on GitHub, `justinfaubert/the-bouncer`, and on 28 September everything here went up to it with its history, through the GitHub connection (github.com itself is blocked in the cloud workspace). This folder's repo tracks it as `origin`.

### 2026-09-28 to 29 (Monday night), the polish pass and the first playable build in Godot

- Hutch: "this is good progress. I need you to polish and tighten everything here and publish a playable build, but only after you've honestly and thoroughly gone over every single aspect." On a decision card Hutch picked Godot for the playable build, over the browser game or both.
- The review came first: `09_REVIEW.md`, and a page with the frames marked up in pen (https://claude.ai/artifact/NaKyMWZE4Yrf4ZkGSRB6yi). The print works and the door is the best frame in the project. The people didn't work yet, the kid least of all; the licence on his phone printed as noise; and the Godot scene was a picture of a game, with no Ink and nothing to touch.
- The build, in `godot/` (its README says how to play it, check it and export it): all of Wednesday, first person from his posts, in the printed look. The Ink runs in Godot through a GDScript port of inkjs 2.3.2, and the browser build's engine is ported line for line. Played side by side over 40 seeded nights, the two builds agree on every line (7,265 choices). The whole Sov is built in code, with a post in each of the Ink's eleven places, and the people are placed by the clock and the story (`godot/docs/STAGING.md` says who is where, and why, from the Ink).
- Checked on the final build: five whole nights played headless by a random player who also handles what he's given and saves and reloads, with no script errors; the controller; the night in pictures from 7:50 to 10:37, with the arrivals at the door and the licences in his hand; the exported Linux build starts and quits normally; the web build runs in Chromium here, from a local server (inside the Claude app it hasn't been tried). Earlier in the pass: pictures of every post, and the night in pictures to midnight. The Windows build is exported the same way as the Linux one but hasn't been run on Windows.
- Delivered in the thread: the Linux and Windows builds as downloads (copies in `releases/`, which git leaves out), and the web build as a page, https://claude.ai/artifact/FB8yU3reaBzuJD5JMcrrzF
- Kept as it was: director mode stays in the browser build. Both builds read the same Ink, and `node tools/build.mjs` writes it into both, so Hutch's edits reach both.

### 2026-10-03 to 04 (Saturday night), every choice a consequence

- Hutch: "everything needs to have consequence, nothing is meaningless, even the more meaningless aspects", and a zip to play on Linux with the Godot project in it. Delivered on 4 October (eabee50): `releases/The-Bouncer-2026-10-04.zip`, both web builds republished, Hutch's five director-mode notes merged. What it built is under PROPOSED, "Proposed with the polish pass (2026-10-04)".

### 2026-10-05 (Monday), up to a professional level

- Hutch, on the 4 October build: "The positive things about this current build are innumerable and so I think you're doing great work on the right track. but let's bring this up to a professional level." Seven notes: the mottled paper filter looks good but obscures the text column; the dice don't have proper collision; the licences have no holographic sheen to inspect; the end-of-day receipt pushes some of the text to the far margin; some characters' responses come up as large empty blocks; the clicker is "unnecessarily tedious and really shouldn't be a thing"; and "The dialogue sounds the same across characters."
- All seven were found in the running game first. The empty blocks were a voice's note beside a choice, laid out about 2,100 pixels tall; the receipt was squeezing its amounts down the right margin a letter a line.
- What it built is under PROPOSED, "Proposed with the professional pass (2026-10-05)", except the clicker coming out, which is Hutch's call (DECIDED). Who talks how is `10_VOICES.md`.

## Decisions register

### DECIDED (Hutch)

- A collaborative worldbuilding, writing and game project that takes Disco Elysium's framework somewhere else. It starts small and grows as far as it wants.
- Working title *The Bouncer*; the protagonist is the new bouncer.
- Voices come from people, books, pamphlets, and memories retold by patrons.
- Setting: a contentious time at the end of an empire; a rowdy, dingy, lived-in bar; debauchery as it really is and no more.
- Thirty days. A narrator foreshadows an event that changes everything.
- Precedence: things and people take precedence over others. The culmination reflects the whole playthrough. Lots of interaction with people, objects and tasks.
- A reputation and morality system that isn't a binary and conditions what's possible.
- The top requirement: a satisfying, engaging loop, stakes in the writing, and a detailed world-state change for every choice.
- A protagonist with an identity, with Harry Du Bois as the template: semi-tabula rasa, recalling and inventing who he was and is.
- Cast drawn from Hutch's bartending and bouncing experience: table 28, the kids, and the regulars as anchors that change over time.
- Money and skill-building in novel ways. The range runs from the very good times to violence, stepping in or stopping it. Bad decisions haunt, but not enough to destroy ambition.
- Day 1 is a Wednesday test shift with rats, and the player can side with the rats. It's the prologue and tutorial. The first real shift is Friday. The bar opens early, and taking early shifts is the player's call, at a cost.
- Hutch can make the music and sound effects and do voice work.
- Setting (2026-09-26): unique and invented, reflecting modernity (today's technology) without veering into near-future cyberpunk. Rejects the historical routes.
- Place (2026-09-26): a town on the east coast of an island like Vancouver Island, modelled on Hutch's own town but generalized, taking features from the general coastal BC feeling.
- "The following Friday" is day 3. (2026-09-26)
- The bar is in a coastal hotel, which makes for recurring characters. It smells of beer, cleaner, piss, old wood and dust; carpeted floor, cheap stools, sturdy tables; four doors, the main one used, the others locked at night as a loose rule. (2026-09-26)
- The bouncer is a regular-ish big guy, not a hulking steroid type: thoughtful and self-aware enough to catch and engage with the details the game throws at him. Many real bouncers have a violent disposition and aggressive style; he isn't built as that type. (2026-09-26)
- The bouncer is experienced at door work, but an individual rather than a type. (2026-09-26)
- His father taught him the door. The father is dead: a former alcoholic turned dry alcoholic. (2026-09-26)
- The head bartender is a lifer, and drinks. The sober bartender is a narrative trope; the reality is the opposite. No one makes it out of the life unscathed. (2026-09-26)
- Table 28 sustains itself to the end, even if people in it desert. (2026-09-26)
- The rats: their numbers double if he ignores them. Throughout the game he has chances to parley with the Rat King, until the colony gets too huge or until he decides to exterminate them, which costs in other ways. (2026-09-26)
- The Rat King is both: a real rat king (rats with knotted tails) in the wall behind table 28, and a man who seems to speak for it. (2026-09-26)
- The bouncer drinks, and must immerse himself in the culture and the excess to understand what he's doing. (2026-09-26)
- The game is seen through his eyes: first person from his posts (the stool at the door, the bar, table 28 and the rest), not from above as in Disco and not a free walk. Hutch's pick on the form, 2026-09-27 (`08_FUTURE_FORM.md`).
- No clicker. Hutch, 2026-10-05: "the clicker mechanic is unnecessarily tedious and really shouldn't be a thing." Nobody hands him one and there's nothing to click. The door still counts (`count_in`, everyone he lets in past the stool), and the ones who got in some other way (`uncounted`) still come back to him at close.

### PROPOSED (waiting on Hutch)

- Immersion as learning: drinking with a group is how he earns their voices and reads them; the cost lands on the body, judgment and the next shift. The father's voice opposes it.
- The hotel draft in `06_THE_HOTEL.md`: the Sovereign Hotel ("the Sov"), the four doors, table 28's window, the rats in the wall behind it, the bouncer's room as leverage.

- The relational psyche: five voices in the room, signed relationships, tension 0 to 4, and the 34 states as the Thought Cabinet deck.
- Voices that carry their source and fidelity; the old voices can't read the young.
- The narrator as a teller at a bar years later, revealed at the end, with "he" turning into "I."
- Two endings in the calendar: the public date and the private event.
- Codes, witnesses and rumor, plus a hidden self-deception measure; haunting that turns into something useful.
- A failing currency, bar money, and the lost-and-found box.
- The 86 list, the incident log, the body, a past that's partly fixed and partly invented, the head bartender as partner, and the room upstairs.
- Storylets plus rule-matched lines; one save slot, saved automatically at dawn.
- Setting route 2: an invented world built on real history.
- Thursday teaches daylight; the early shift is table 28's shift; Sundays are chapter breaks.
- The rats: the informant double meaning, the omen payoff, the dead rat in the wall, the health inspector, the doubling numbers.
- Godot 4 with GDScript; Ink through inkgd and inkjs; rules authored in YAML and compiled to JSON; the folder layout.
- The printed art direction, a typeface per voice, strangers assembled from parts, and the floor as the bouncer's sketch.
- The jukebox as the score; Hutch voices the narrator; the cast stays in text; Suno for sketches only.

Proposed with the Wednesday draft (2026-09-26):

- One save slot, written after every choice, so there's no going back to try again. This replaces "saved automatically at dawn" above. A copy can go to the player's Claude account if they turn it on.
- The room on day 1: THE FATHER, THE FIGHTER, THE MANUAL and THE WRONG MAN seated, one seat empty. THE TABLE and THE KID can be earned on the night.
- Checks are two dice, moved by how reliable the voice's source is, how much he's had and whether he's hurt. There are no skill levels. The louder the room in his head, the wider the result swings, both ways. Voices also make passing remarks on drinks, the hour and where he goes (`content/rules/barks.yaml`).
- The head bartender is a woman in the draft.
- Walter is table 28's rat. Poison is an anticoagulant: if he takes the bait on Wednesday he dies over days, not hours, and it lands on day 3.
- At close he writes the incident log: the way it happened, so it reads better, or left out. The bartender reads it, and knows what she saw.
- The day ends on the ledger, printed like the till's Z-report.
- The browser build is the testbed; the Ink stays engine-free so it can move to Godot.

Proposed with round two (2026-09-26):

- The engagement devices in `07_ENGAGEMENT.md`: voices that answer each other, the head-room preview on choices, the floor sketch as what he knows and when, plates as evidence of what's changed, and the hour's light.
- Places and faces drawn in code in the printed style as stand-ins until there's art; a file dropped into its slot replaces a drawing.
- A look for each of the ten people with portraits (`content/data/characters.yaml`), matched to how the Ink describes them.
- Director mode and the merge tool as the way Hutch edits the game.

Proposed with the polish pass (2026-09-27). Built, to keep or cut:

- The word on him: each group's reaction shown in its own words where it happened, the numbers hidden, and faces that warm or cool with it.
- THE MANUAL as the tutorial, in its own voice, once per thing.
- The ledger as the till's tape, with a section for what each group is saying about him, and the bartender's word as the total. This replaces "printed like the till's Z-report" above.

Not built, for Hutch to say yes or no to:

- **The door as a hands-on loop.** Each walk-in at the door is a printed face and a card: the birthdate against tonight's date, the photo against the face, the regular who never carries one, the kid who's nineteen in two days. Slow checking builds a line in the rain; fast checking lets mistakes through. (Round three built the cards for the three people who hand one over; the line in the rain and the cost of speed aren't built.)
- **The spike.** Every night's tape goes on the receipt spike behind the bar. The player can leaf back through the month, and the last night's reckoning reads the whole stack.
- **Voices remember across days.** On Friday THE FATHER answers something THE FIGHTER said on Wednesday.
- **The bar recorded in layers.** A quiet room, a busy room, the pool table, the jukebox through the wall, rain on the glass, recorded separately so the mix can keep following the crowd with real sound.

Proposed with round three (2026-09-27). Built, to keep or cut:

- The voices leaning in on the choice under the player's hand, and noticing a wait, a pull-away, a reread and a return.
- The voices marking up the plates.
- Things to handle: the dice by hand, the licences, the kid's phone and the binder, with choices only the hands can make. (The clicker was one too, until it came out on 5 October: DECIDED.)
- In his skin: the print slipping and doubling with drink (the idea from the polish pass list), the throb when hurt, the rain on the door's glass, and his heartbeat with the dice and a loud head.
- Facts drafted for the props, all Claude's placeholders: Wednesday is 4 November 2026, so a licence's birthday has a date to count from and the month runs out on Thursday 3 December; the names and numbers on the cards (the kid and his sister are Tyler and Kayla Moffat, the regular in the good shoes is Graham Ardagh); the kid photographed his dad at the pool table from the lot; forty sleeves in the binder, the first eleven written out, with dates and lengths under them (the reasons are Hutch's to write, at the binder's prompt in `content/ink/bar.ink`).
- The small talk at the door, and what it changes, drafted from Hutch's answer.

Proposed with the future form (2026-09-27), in `08_FUTURE_FORM.md`:

- Godot 4.7 for the game. The browser build stays as the writers' room until the Godot build has its own director mode.
- With the view through his eyes (DECIDED above): the posts (the stool at the door, the end of the bar, table 28, the pool wall, the back hall, the kitchen, the deck, the keg room and the lot); the pointer as his attention; the voices marking the room itself; him seen only in reflections, the back-bar mirror among them; drink in the print, not the camera.
- The print made real: the room built in 3D from photographs and measurements of a real empty bar; faces painted by one commissioned artist and printed through the same press; everything designed stays Claude's; no AI-generated images in the game.
- The path: a home Hutch owns (a private GitHub repo attached to the project, Hutch's machine on Remote Control), then one scene at final quality (the door, 7:50 pm), then Wednesday post by post, then Thursday and Friday. This swaps M3 and M4 in `04_PRODUCTION.md`.

Proposed with the look test (2026-09-28), in `sketches/door-look/`:

- The look: the night, printed. Every view is a print on cream stock in three inks (night, lamp and neon), and the light picks the ink. The dark is cut like a lino block, in strokes that follow the surfaces; every edge takes a keyline; the grain stays on the world when he turns his head; drink pushes the plates out of register.
- Claude makes the models and textures in code, simple and cut rather than detailed, and spends the detail where the story is: the licence on the phone, the tape by the door, the signs, the gold leaf.
- The faces carved in code like whittled figures, a style of their own: a fourth route to the faces beside the three in `08_FUTURE_FORM.md`.
- The room's details: the old dining room's sconces; the carpet (maroon, a navy trellis, gold rosettes) worn to the backing past the mat and along the bar; a coin-op pool table; the wall jukebox that takes a card; the dartboard with the chalked scores on its doors; the hockey on one TV and the news on the other (a rainfall warning for the east coast of the island); SOVEREIGN over PUB in gold leaf on the door; the house rule on the ID sign, "no pictures on phones"; masking tape by the door with the night's sum in marker, `19 = NOV 4 07`.

Proposed with the playable build (2026-09-29), in `godot/`. Built, to keep or cut:

- The Godot build as the game from here, first person from his posts. The browser build stays at its link as the writers' room until Godot has a director mode of its own.
- The screen: the room through his eyes on the left, and the night's words in a column on the right third, knocked out of a solid of the night ink, with the voices in their own type and colour and the whole night there to scroll back through.
- Looking as choosing: a choice about something he can see (the kid's phone, the truck, the big man, the propped door) is pinned to it in the room. When his eyes rest on it the choice lights in the column and a voice may lean in; E or a click makes it. The numbered list stays.
- Dice thrown by hand onto whatever is in front of him (the ledge by the door, the bar, table 28, the felt, the kitchen's steel): hold to shake, let go to throw, and the second die can ride up onto an edge and hang there. The result was decided when the choice was made, as in the browser build.
- The voices marking the room itself in their own colours: a ring round the big man, a box round the propped door, a cross on the empty stool, a tally on the bar. A pen tick at the edge of his sight points to a mark he has turned away from.
- The print as his body, with no meters: drink pushes the plates out of register, nerves bring the red up in the dark, hurt thickens the red at the edges of his sight, his heart swells the ink when his head is loud, and late in the night the ink runs thin and the strokes break.
- The room moves between glances: people breathe and shift while he watches, and come and go while he looks elsewhere.
- Things in his hands in the room: a licence tipped to the lamp and held up beside the face of whoever handed it over, the kid's phone and the binder. (The clicker came out on 5 October.)
- The lot in three framings: arriving, with the whole hotel and the sign over it; the pickup's window; the big man at his work truck by the beer store.
- Claude's guesses at the back of the house, drawn from the Ink, for Hutch to correct from the real thing: the keg room (two rows of kegs on pallets under a board ceiling, the gas and the compressor, the concrete giving out to dirt and old pilings at the far end), the kitchen line, the deck facing the strait, and his room (a bed, a chair, a sink, a radiator, the one bag he came with, and the fire escape outside the window).
- The people re-carved, and eighteen more, all Claude's: a model for each pose the night needs (the kid at the door hunched against the rain, his sister with her card up and her keys in her fist, the boyfriend holding the door with his shoulder, HI-VIS with the two-four, GOOD SHOES with his licence out and later at the bar with a cola, RAINCOAT holding her coat shut, the cook at the pass, the two women from upstairs with their white wine, and six regulars who fill the room as the count goes up), with fingered hands, clothes with collars and cuffs, and faces carved like whittled figures. And his own hands, from his eyes: the licence or the kid's phone in his right. (His left held the clicker until it came out on 5 October.)
- Three nights of saves, each saved after every choice and played through once. This adds slots to "One save slot" above; a night still can't be replayed from a choice.
- Placeholder sound made in code. Hutch's recordings go in by dropping a file with the same name into a folder called `audio` next to the game; more takes of one sound are picked among.
- A controller covers the basics: either stick looks round, the d-pad goes through the choices and A makes one.

Proposed with the polish pass (2026-10-04), asked for by Hutch on 3 October ("everything needs to have consequence, nothing is meaningless"). Built, to keep or cut:

- The top requirement above, a world-state change for every choice, held to by a tool: `tools/audit.mjs` reads the Ink, the rules, the engine and the Godot scene, and lists any choice whose changes nothing ever reads, any state written and never read, and any read and never written. After this pass it lists none. The only choices that change nothing but the clock are the five plain ways out of a scene ("The floor", "That's enough counting.", "Leave him to his game.", "Out of the office.", "Go back in."). `--map` writes `content/CONSEQUENCES.md`.
- The kid, his sister and her boyfriend are each in one place at a time (`kid_at`, `sister_at`, `vape_at`: the door, the vestibule, the jukebox, the single washroom, the rail, the bar, the lot, the pickup), and every line about them reads it. The Godot scene stands them there.
- Nobody walks in past him while he's on the door. "Stay on the door" always has something in it, by the clock: headlights deciding against it, the highway gone quiet, the room behind him in the black of the window, after midnight the door going the other way.
- Doors he walked, saw propped and left (`doors_left`): the night says so when the kids come in by the deck, and at close when he searches.
- At the close, times come from the real clock in the words people use ("quarter past one", "half an hour late"), and the bartender's book reads what happened, down to the glass of water.
- Small things done or not done come back at two: table 28's dog, the payphone's receiver, the night clerk he never said it to ("Never did say what was wrong."), the old man's brick, the sister he let in to find her father.
- Hutch's five director-mode notes, merged: the island running short after the card machine goes down (the diesel, the truck that didn't come off the ferry, limes in eighths, NO MORE TIL TUES over a tap); "Stand at the door."; the keg room's office (the safe, the DUE BACK envelopes, the clamato, the empties, and the mirror on the desk, to note, wipe or leave); the Fighter's read of the boyfriend in Hutch's words; the owner's "How is it tonight?".
- A continuity fix: the Ink had a TV at the front desk and the night clerk propping the door to watch the bar's. There's no TV at the desk now. He watches the bar's through the gap, and gets the game on his phone once the door stays shut.
- Claude's guess at the hotel's front desk, through the hotel door at the end of the back hall, built in the Godot scene: a counter with the bell and the register on it, the key board with most of the keys on their hooks, a lamp, the stairs going up into the dark, the hotel's own front door shut for the night, a picture of the ferry. Terry (Claude's draft: slight, thinning, glasses, a blue flannel, a lanyard and key card) sits behind it with his chin on his fist, square to the doorway, so while it's propped he can be seen from the far end of the hall. Asking him to leave it shut walks the view through the door to the desk and back, and the door is shut after.
- The constable (Claude's draft: a woman from the detachment in town, cap and duty jacket) stands inside the door if the fight gets called in.
- The deck rebuilt in the Godot scene: level with the bar's floor through the door, two steps down its side to the gravel of the lot, and the plastic chairs turned toward the people in them. A woman smokes at the top of the steps (the one who watches him pull the coaster), and whoever the text has talking out there is out there till their smoke's done: the two women under the awning, the man by the steps watching the pickup, or two of the mill crew at the far end, one still in his vest (`deck_smokers`, `smokers_at`).
- The voices that talk about the family follow where they are, as the lines do: the Father's "His kid's twenty feet away and he knows exactly where." only while the kid's by the jukebox; a new one while the daughter waits in the truck ("His daughter's sitting out in that truck with the engine running, and he's chalking his cue."); the Wrong Man on the man in the kid's photo, and the Fighter on his left hand, only while he's at the table (Hutch's saved night from 27 September had the photo line at an empty table); "A locked door with a kid behind it" only while the kid is in there.
- A night saved under an older version of the story says so, on the title and when it's picked up, in both builds, and goes on from the floor rather than mid-scene. Continued mid-scene, a night saved by the 29 September build could lose its place and end early.
- A zip to play from on Linux: the game with `play.sh`, and the Godot project with `open-in-godot.sh`, which uses a Godot 4.7 if there is one and otherwise offers to fetch the official 4.7.2 editor and checks its fingerprint. `godot/tools/bundle/make.sh` makes it.

Proposed with the professional pass (2026-10-05), from Hutch's notes on the 4 October build. Built, to keep or cut:

- The text column as one even solid of the night ink, with the words knocked out of it. The paper's tooth and grain stay in the room's print; under a letter they read as dirt. All that comes through is the paper's slowest mottle, broader than a paragraph, and the block's edge a hair heavier where it meets the room (`godot/look/column.gdshader`).
- A voice's note beside a choice is a box the size of what it says, beside the choice. The word on him sits at the right of the page with its stamp after it, and a long one wraps in the room the stamp leaves.
- The till tape on a till's grid of characters: what, a run of dots, how much. When the how-much won't fit on its line the dots run to the edge and it prints underneath, indented. A heading too long to stay on one line spaced out isn't spaced out.
- A hologram in each licence's laminate, drawn once per card: a field of small waves, a seal over the corner of the photo, the face again, and the birthday in a line of tiny print. Away from the lamp it's a pale outline. Tipped toward the lamp the foil splits the light: its colours run through the spectrum as the card tips, and a bright band crosses it where the foil sits at the mirror angle. A fake's printed hologram (`holo: printed` in `props.yaml`) is ink, and sits still however the card is tipped (`godot/look/licence.gdshader`).
- The dice as two solid cubes with weight, bounce and grip (`godot/game/dice_sim.gd`), worked out before anyone sees them, so the same throw falls the same way every time: off the surface, its walls (the front wall behind the ledge, the pool table's cushions), the glasses on table 28's table, and each other. Each surface has its own bounce, grip and knock (wood, felt, steel, carpet). The surfaces and walls are fitted to the models (a die stops on a cushion's nose, the kitchen board ends where the board does), the balls lying on the felt are solid in the air too, and a throw only counts if both faces can be read from his eye. The number was settled when the choice was made, as before; the faces are dealt to the cubes after they land.
- The voice pass. `10_VOICES.md` sets down how each of them talks (rhythm, words, what they do with a question, what they never say) and how each says yes, no and fine, and every line from someone in the room was gone through against it: about 300 of 650 rewritten, and the word on him from each group in that group's voice. Every fact, number, name, promise, choice and condition is unchanged, and so is the story's shape; Hutch's own lines are word for word, and the `// HUTCH:` prompts are where they were (the draft lines under them are in voice now too, for Hutch to replace). Claude's, to keep or cut, among others:
  - The bartender calls the new man *Door*, never his name, until he's lasted a week, and the owner *Junior* behind his back: she worked for his father.
  - The old man at the end of the bar never uses a contraction, and calls him *Doorman*.
  - The big man calls him *bud*, and his own kids *my girl* and *the boy*; when something lands he goes to two words.
  - Table 28 talk about him in front of him: *the new kid*, *big fella*. Team Jacket is the table's mouth and keeps its books; *Hear, hear!* and *There he is!* are the table's, and *Good man.* is the owner's alone.
  - Terry asks the score before anything else and calls everyone *pal*. HI-VIS's greeting is the island's working one, *How's she goin'.*
  - The kids' word on him is lowercase, the way it'll be typed.

### REJECTED

- Setting routes 1 and 2 (real history; an invented world built on a historical era), including Claude's Soviet-collapse pick. Hutch, 2026-09-26.
- The locked phone as the bouncer's hidden past: "heavy handed and simplistic." Avoid a single object that holds his past. Hutch, 2026-09-26.
- A wise mentor-trainer ("no Mr. Miyagi"). Hutch, 2026-09-26.
- The head bartender who stopped drinking: a trope. Hutch, 2026-09-26.

## Open questions

### Blocking Wednesday

1. **The empire.** Place decided. Open: what the empire is, and how its end shows in modern technology (card machines, network, prices).
2. **The bar.** Drafted in `06_THE_HOTEL.md`; waiting on Hutch's cuts and the name.
3. **The bouncer's first-day facts.** Experienced, an individual (DECIDED). Open: how he got this job, why he left the last one, what people call him.
4. **The voices on day 1.** Who are the first five in the room?
5. **The head bartender.** A lifer (DECIDED). Open: who, exactly.
6. **The rats.** Structure DECIDED (doubling, recurring parley with the Rat King, extermination at a cost). The Rat King is both the knot and a man (DECIDED). Open: who the man is; the first parley.

### Soon

8. What is the event, and what is the public date?
9. Does the narrator frame stay?
10. Is the relational psyche the core system?
11. Art: Hutch isn't a visual artist (2026-09-27). Open: is there a local painter or printmaker, and a budget, or do the faces carved in code carry it (the look test)?
12. Which way does the game go on AI disclosure?
13. Violence: Hutch describes how it actually goes.

### Later

14. The empire, the city, the factions and the politics.
15. A title check before any store page.
