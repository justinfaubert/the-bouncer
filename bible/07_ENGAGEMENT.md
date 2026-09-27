# Engagement: what holds a player

*Written 26 September 2026, with round two of the browser build, and added to on 27 September with the polish pass (sections 7 to 10). Everything here is [PROPOSED] until Hutch says otherwise. "Built" means it plays in the browser build now.*

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

## Next, not built

- **The door as a hands-on loop.** Each walk-in is a printed face and a card: the birthdate against tonight's date, the photo against the face, the regular who never carries one, the kid who's nineteen in two days. The line builds in the rain while he checks; hurrying lets mistakes through.
- **The spike.** Each night's tape goes on the receipt spike behind the bar, to leaf back through, and the last night's reckoning reads the whole stack.
- **The print goes out of register as he drinks.** The plates and the page double-print by a hair more with each drink, the way a cheap print misses. It's true to the printed look, and it's off with a switch.
- **Voices remember across days.** On Friday, the Father answers what the Fighter said on Wednesday.
- **The bartender's face after she's read his incident log.**
- **The bar recorded in layers**, so the room's noise can follow the crowd with real sound.
