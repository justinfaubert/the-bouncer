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

- **The door as a hands-on loop.** Each walk-in at the door is a printed face and a card: the birthdate against tonight's date, the photo against the face, the regular who never carries one, the kid who's nineteen in two days. Slow checking builds a line in the rain; fast checking lets mistakes through.
- **The spike.** Every night's tape goes on the receipt spike behind the bar. The player can leaf back through the month, and the last night's reckoning reads the whole stack.
- **The print slips as he drinks.** The page and the plates go a hair further out of register with each drink, the way a cheap press misses. Off with a switch.
- **Voices remember across days.** On Friday THE FATHER answers something THE FIGHTER said on Wednesday.
- **The bar recorded in layers.** A quiet room, a busy room, the pool table, the jukebox through the wall, rain on the glass, recorded separately so the mix can keep following the crowd with real sound.

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
11. Art: does Hutch draw? Is there a local painter or printmaker? A budget?
12. Which way does the game go on AI disclosure?
13. Violence: Hutch describes how it actually goes.

### Later

14. The empire, the city, the factions and the politics.
15. A title check before any store page.
