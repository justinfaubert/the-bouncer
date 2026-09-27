# Engagement: what holds a player

*Written 26 September 2026, with round two of the browser build, and added to on 27 September with the polish pass (sections 7 to 10) and round three (sections 11 to 14). Everything here is [PROPOSED] until Hutch says otherwise. "Built" means it plays in the browser build now.*

`01_PILLARS.md` says what we keep from Disco Elysium and what we change. This file is narrower: the devices that keep a player leaning in, what each one does in Disco, where it falls short, and what this game does instead. The advantage we have is what the game already is: one building, one night at a time, and a job where attention is the scarce thing.

## 1. The voices answer each other

**Disco:** the skills interrupt, often brilliantly, but they talk to Harry, rarely to each other, and how they get on never changes.

**Here:** the voices in his head have relationships (`02_SYSTEMS.md`), so when one speaks up, another seated voice can answer it, and what it says depends on whether they're allies or at odds. A bond or a rift on the night changes which answers can come. The player learns the room in his head by overhearing it.

- **Built:** 24 answers among the four starting voices, about six exchanges a night (`content/rules/barks.yaml`, "answers").
- **Next:** answers for THE TABLE and THE KID; answers written for after a bond or a rift.

## 2. The build is who he listens to

**Disco:** skill points. A 72% check is a 72% check, and the way to win is to pump the number.

**Here:** there are no points. The odds come from the voice's source, what he's had and whether he's hurt, and the louder the room in his head, the wider the dice swing, both ways. Letting a voice in or putting one out is the only character build, and it's a choice made in the story, at a cost: five seats.

- **Built:** a choice that lets a voice in or puts one out says first what it will do to the room ("In his head: uneasy to arguing"; "His head is full. Someone has to go first."). The Ink marks those choices with `#room`.

## 3. What he knows is a drawing, and it goes stale

**Disco:** the map is the truth, always up to date, whether Harry looked or not.

**Here:** the floor sketch is his pencil notes on the back of the incident log. It shows only what he's seen, with the time he saw it: the last count ("13 at 9:05"), the pool table ringed when it's heating up, table 28's rounds as a tally, the doors he found propped or shut, how long the front door has gone unwatched. Notes fade as they age. The player sees the gap between what he knows and what he'd need to know, and that gap is the job.

- **Built** (`Game.sketch` in `src/core/game.js`, drawn in `src/ui/views.js`).
- **Built:** back on the door after a while away, wet footprints on the mat say people got in while he was gone.

## 4. The pictures are evidence

**Disco:** painted places that change with the time of day, for mood.

**Here:** a printed plate when he walks into a place, drawn as the place is at that moment. The room fills in over the night, table 28's glasses stack up, the eyes in the keg-room wall multiply as the rats double, a propped door shows open or shut. A place gets a new plate only when it has changed, so a new plate means look again. The hour tints the plates and the page: grey dusk while it's quiet, the room's amber as it fills, redder after midnight, flat and green when the lights come up, blue after close.

- **Built:** plates for the eleven places he goes, drawn in code and screened the way a cheap two-colour press would print them (`src/ui/print.js`, `src/ui/plates.js`), as stand-ins until there's art. A file in `content/data/assets.yaml` replaces a drawing.
- **Built:** faces for the ten people with portraits, assembled from parts the way Papers, Please builds its faces (`look:` in `content/data/characters.yaml`). They look at him warmer or colder as he stands with their group (`standing:`). Hand-made portraits replace them one at a time.

## 5. Time costs something

**Disco:** a day is long, and the city waits while Harry wanders.

**Here:** the shift ends at two. Every choice moves the clock, and the room doesn't wait: people walk in while he's away from the door, the rats double, the pool table heats up. Whatever he's attending to, he isn't attending to something else. (Built since round one, `content/ink/sim.ink`.)

## 6. One save, and the only rewrite is his

**Disco:** you can reload any red check.

**Here:** one save slot, written after every choice. The only place the night gets rewritten is the incident log at close, in his words, and the bartender knows what she saw. (Built since round one.)

## 7. The word on him

**Disco, and the genre:** what people think of you is a hidden tally, or at most a notice that something counted ("they will remember that"), and you see what it counted for hours later with no thread back to it.

**Here:** when something he does lands with one of the groups that judge him, what they'll say about him shows right under the line where it happened, in their own words: table 28 by loyalty and who was here first, the kids by don't be fake, the bartender by having each other's backs, the owner by money, the cook by don't make my night worse. The numbers stay hidden. One act can be honour to one group and betrayal to another, and then both show. By the end of the night the ledger prints what each of them is saying about him.

- **Built** (`content/rules/word.yaml`, Claude's drafts in each group's voice; rewrite freely).

## 8. The dice are a moment

**Disco:** a check resolves the moment you click it. The result is already in the text, and the drama is in whether it was a red check or a white one.

**Here:** the roll is something you wait on. The dice tumble onto the bar mat, the second can hang on an edge, a row shows which totals would pass, the room goes quiet and dim while they're in the air, and the result comes down as a stamp. A tap skips it for players who want the pace.

- **Built** (`src/ui/roll.js`). Settings has Rolled out, Quick and At once.

## 9. The game teaches in a voice

**Disco:** tooltips and a few pop-ups explain the systems from outside the fiction.

**Here:** THE MANUAL, the voice in his head that knows the job's rules, explains each system once, the first time it comes up: a check, the noise in his head, the word on him, a choice that changes who's in his head. If the Manual's been put out of his head, the explanation waits.

- **Built** (`teach:` lines in `content/rules/barks.yaml`, Claude's drafts).

## 10. The night gets totted up

**Disco:** a day ends when you sleep; the game moves on.

**Here:** the night ends on a reckoning. A plate of the hotel after close, his the only window lit, then the tally prints the way the till prints its tape at close: the door, his pocket, the drinks, the hurt, what happened, where he stands, what each group is saying about him, and a stop before the bartender's word to the owner, which prints as the total. Then the stamp, and the tape torn off.

- **Built** (the ledger in `content/ink/closing.ink`, printed by `src/ui/app.js`).

## 11. The head reaches for the player's hand

**Disco:** the skills speak when the story calls for a passive check, on the story's schedule. What the player does with the mouse means nothing until the click.

**Here:** the voices watch the player's hand. Resting on a choice before committing to it brings a voice to lean in on it, if one has something to say. Pulling away from a tempting choice, waiting a long time, scrolling back to read again, and coming back to the game after a while away all get noticed. On a phone, pressing and holding a choice does it without choosing. It's the head in the book reaching past him to the person holding it.

- **Built** (`src/ui/hand.js`, the `hand:` lines in `content/rules/barks.yaml`, Claude's drafts). Settings → The voices notice you.

## 12. The voices mark up the pictures

**Disco:** the skills talk in the text column; the painted world stays a backdrop.

**Here:** a voice can reach into a plate, pull a detail out, ring it in its own colour and write a note beside it, drawn on as the player watches: the latch on the deck door, the door everybody came in through, the big man's left hand on the rail. His head lays itself over the world, on the page.

- **Built:** 23 marks (`content/data/marks.yaml`, `#mark:` in the Ink, `src/ui/marks.js`).

## 13. Things to handle

**Disco:** objects are inventory icons and lines of dialogue.

**Here:** what he's handed comes onto the page as a thing. A licence to turn over, tip under the light for the hologram, and hold up beside the face of whoever handed it over. The kid's phone to take and swipe. The binder under the till, forty sleeves of barred faces to leaf through. The clicker to press and zero. The dice to shake and throw. Handling them is play in itself, and the voices answer it; some of it moves the story. Some choices can only be made with the hands: swiping on to the kid's next photo, or recognising a face from the binder by holding his licence up beside him.

- **Built** (`content/data/props.yaml`, `src/ui/props.js`, `src/ui/toys.js`, `#prop:`, `#toy:` and `#unlisted` in the Ink, `content/ink/toys.ink`).

## 14. In his skin

**Disco:** Harry's body is two numbers, health and morale, and a line of text when it matters.

**Here:** what the night is doing to him shows on the page itself. Drink puts the print out of register: the red slips off the black first, then the pictures and the words double, and from the fourth drink the page sways; each drink going down lurches it. Hurt makes the edges of the page throb, strongly while it's new and then on and off. On the door, rain runs down the glass in the margins. His heart comes up in his ears while the dice are in his hand and in the air, faster the worse his odds, and after each thing that happens while his head is arguing or worse; the edges of the page darken with each beat.

- **Built** (`src/ui/skin.js`). Settings → In his skin turns it off.

## Next, not built

- **The door as a hands-on loop.** Each walk-in is a printed face and a card: the birthdate against tonight's date, the photo against the face, the regular who never carries one, the kid who's nineteen in two days. The line builds in the rain while he checks; hurrying lets mistakes through. (The cards are built for the three people who hand one over, section 13.)
- **The spike.** Each night's tape goes on the receipt spike behind the bar, to leaf back through, and the last night's reckoning reads the whole stack.
- **Voices remember across days.** On Friday, the Father answers what the Fighter said on Wednesday.
- **The bartender's face after she's read his incident log.**
- **The bar recorded in layers**, so the room's noise can follow the crowd with real sound.
