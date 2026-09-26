# Engagement: what holds a player

*Written 26 September 2026, with round two of the browser build. Everything here is [PROPOSED] until Hutch says otherwise. "Built" means it plays in the browser build now.*

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
- **Next:** when he gets back to the door after a while away, the page says what happened while he was gone.

## 4. The pictures are evidence

**Disco:** painted places that change with the time of day, for mood.

**Here:** a printed plate when he walks into a place, drawn as the place is at that moment. The room fills in over the night, table 28's glasses stack up, the eyes in the keg-room wall multiply as the rats double, a propped door shows open or shut. A place gets a new plate only when it has changed, so a new plate means look again. The hour tints the plates and the page: grey dusk while it's quiet, the room's amber as it fills, redder after midnight, flat and green when the lights come up, blue after close.

- **Built:** plates for the eleven places he goes, drawn in code in the printed style (`src/ui/plates.js`) as stand-ins until there's art. A file in `content/data/assets.yaml` replaces a drawing.
- **Built:** faces for the ten people with portraits, assembled from parts the way Papers, Please builds its faces (`look:` in `content/data/characters.yaml`). Hand-made portraits replace them one at a time.

## 5. Time costs something

**Disco:** a day is long, and the city waits while Harry wanders.

**Here:** the shift ends at two. Every choice moves the clock, and the room doesn't wait: people walk in while he's away from the door, the rats double, the pool table heats up. Whatever he's attending to, he isn't attending to something else. (Built since round one, `content/ink/sim.ink`.)

## 6. One save, and the only rewrite is his

**Disco:** you can reload any red check.

**Here:** one save slot, written after every choice. The only place the night gets rewritten is the incident log at close, in his words, and the bartender knows what she saw. (Built since round one.)

## Next, not built

- **The print goes out of register as he drinks.** The plates and the page double-print by a hair, the way a cheap print misses. It's true to the printed look, and it's off with a switch.
- **Faces change on the night.** The bartender's portrait after she's read his incident log.
- **Voices remember across days.** On Friday, the Father answers what the Fighter said on Wednesday.
- **The dawn ledger gets a plate:** the room empty, chairs up, the count.
