# The Ink

Everything that happens on a night at the Sov is written here, in [Ink](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md). The engine in `prototype/web/src/core/` only reads it: it shows the lines, rolls the checks, runs the voices in his head, plays the sounds and saves the game. Nothing in the Ink depends on the browser, so the same files can move to another engine later (Godot has an Ink runtime).

```
node tools/build.mjs            compile, check, and write prototype/web/content.js and content/WRITING_PROMPTS.md
node tools/bots.mjs --runs 400  play 400 nights at random; report scenes never reached and anything that broke
node tools/bots.mjs --trace 11 --policy explore   print one whole night as a transcript
```

## The files

| File | What's in it |
|---|---|
| `main.ink` | Every VAR and LIST: what the world remembers. Read this first. |
| `sim.ink` | `pass(m)`, the only thing that moves the clock, and everything that happens while he isn't looking. `due()` and the `events` tunnel. `num()` for writing numbers out. |
| `prologue.ink` | Arriving, the bartender, the note, the first look at the room. |
| `floor.ink` | The hub: where he stands between things. Counting the room, walking the doors. |
| `door.ink` | The stool and everyone who comes to it: the kid, his sister, HI-VIS, GOOD SHOES, RAINCOAT. |
| `table28.ink` | Table 28 and Walter. |
| `pool.ink` | The big man, his buddy, the fight, telling him about the hospital. |
| `bar.ink` | The bartender, the binder, the card machine, the owner's call. |
| `rats.ink` | The kitchen, the keg room, the knot in the wall, bait and traps, the rat on the carpet. |
| `toys.ink` | What the player's hands do between choices: the clicker's idle clicks and its knob, `toy_<thing>(what)`. |
| `hall.ink` | The washrooms, the payphone, the kid in the single washroom. |
| `deck.ink` | The deck, the one in the cardigan, the pickup in the lot. |
| `closing.ink` | Last call, clearing the room, the count, the incident log, after hours, the parley, upstairs, the voices at night, the ledger. |

## How a line is written

```
He took the stool inside the front door.            narration
BARTENDER: Clicker.                                 a character (id from content/data/characters.yaml)
FATHER: A picture of a card isn't a card.           a voice in his head (id from content/data/voices.yaml)
NARRATOR: He'd stand out there most nights.         the teller, years later
```

A voice only speaks if it's in the room (seated). Its lines are dropped otherwise, so write them freely: a player who bounced THE MANUAL out never hears it. Tag a line `#always` to make a voice speak even when it isn't seated (the voices knocking at night do this).

## Tags

On a choice (inside the brackets):

| Tag | Meaning |
|---|---|
| `#check: father 8` | A check lent by that voice, target 8 on 2d6 (7 Easy, 9 Medium, 11 Hard). Optional third number: a situational bonus or penalty. The engine rolls, then sets `passed` (and `crit`: 1 double six, -1 double one) before the choice's content runs. A check from a voice that isn't seated is hidden. |
| `#loc: pool` | Where this takes him. Lights up that spot on the floor sketch and fires the `visit:pool` bark event. |
| `#room: -fighter +{v}` | Who this choice puts out of his head and lets in. The page shows, under the choice, how loud the room would be after (the tension words, not numbers). Tags can hold `{variables}`. |
| `#class: move` | A way out of the place he's in. These go in a row of places under the other choices. |
| `#toy: goodshoes_card look` | Handling a thing that way makes this choice, the same as clicking its words: tapping the kid's phone, holding a licence up by the face, staying on page three of the binder. The things, and what can be done with each, are in `content/data/props.yaml`; `clicker click` and `clicker zero` are the clicker in his fist. |
| `#unlisted` | With `#toy:`, the choice isn't in the list at all: the only way to make it is with the player's hands (swiping the kid's phone to the next photo). Give it words anyway, for the director and the bots. |

On a line (or on its own line, which attaches it to the next line of text):

| Tag | Meaning |
|---|---|
| `#sfx: clicker` `#music: jukebox_late` `#amb: rain_lot` `#portrait: cook` | Sound and art slots from `content/data/assets.yaml`. `none` stops music or ambience. Until a portrait has art, the face is drawn from the character's `look:` in `content/data/characters.yaml`. |
| `#screen: log` / `#screen: none` | Switches the page to a special screen (the incident log, the ledger) and back. |
| `#plate: lot` | A printed picture of a place he isn't in, as it is right now. The ledger opens on the hotel from the lot after close, his window the one lit. |
| `#class: row` | On the ledger: a line written `What: how much` prints as a till-tape row with dots between. `#class: sub` is a small line under the row above it, `#class: head` the top of the tape, `#class: total` the bartender's word (the printer stops before it), and `#class: end` the stamp at the bottom. |
| `#task: fetch :: Tell the big man his family's waiting.` | Adds a line to his notes. The id comes before `::`. |
| `#done: fetch` | Crosses it off. |
| `#bark: some_event` | Offers a named event to the barks in `content/rules/barks.yaml`. |
| `#pause` | The page waits for a tap before going on. |
| `#prompt: text` | A writing prompt that shows in the game when Settings → Show writing prompts is on. |
| `#prop: hoodie_phone` | A thing he's handed, drawn under the line for the player to handle (`content/data/props.yaml`, `prototype/web/src/ui/props.js`): a licence to turn over, tip to the light and hold up by a face; a phone to look at closer and swipe; the binder to leaf through. It stays in his hands while the choices it came with are on offer, or while a choice is waiting for it (`#toy:`). A second word says how it's shown: `#prop: hoodie_phone held`. |
| `#mark: pool.lefthand` | On a voice's line: that voice marks the spot on the place's picture, in its own hand (`content/data/marks.yaml`). |

## Writing prompts

`// HUTCH: What does the cook complain about?` anywhere in the Ink puts a numbered prompt in `content/WRITING_PROMPTS.md` the next time the build runs. Rewrite the lines under it, delete the comment, rebuild, and it drops off the list.

Hutch can also answer a prompt inside the game, on the card where it comes up (or from the Director's desk). The answer arrives with the rest of the director's edits; working it into the scene is Claude's job, and the prompt comment comes out when it's done.

## Director's edits

In director mode (key D in the game) Hutch rewrites, cuts and adds lines, rewords choices and leaves notes, all while playing. Each edit is keyed on the line exactly as the game printed it, so keep a line's words on one line of Ink where you can: `node tools/director.mjs <edits.json> --apply` merges edits on fixed lines by itself, and lists the ones on lines built from `{logic}`, or whose words appear in more than one place, for a hand merge. Merged edit ids go in `content/director/merged.json`, and the batch itself in `content/director/inbox/`.

## The rules the night runs on

- **Time.** Every choice that takes time calls `~ pass(minutes)`. `pass()` also runs the world: walk-ins while the door is empty, table 28's rounds, the pool table heating up, the kids trying the deck, people arriving at a door nobody's watching. So whatever he doesn't attend to happens without him.
- **Events.** Things that happen at a time (the card machine at 8:15, the owner's call at midnight) wait in `ev_ready()` in `sim.ink`. Every location starts with `{ due(): -> hub }`, and the hub runs `-> events ->` before anything else, so an event interrupts wherever he is and the floor gets a line saying he's back (`back_line()`).
- **Last call** is at 1:30 (`LAST_CALL`). `due()` includes it, so every loop returns to the hub, which goes to `last_call`.
- **Counting.** `count_in` is the clicker. `uncounted` is everyone who got in some other way. `room_count` is who's actually in the room. Anyone who comes in or leaves has to move these, or the count at close won't add up.
- **Numbers in narration** are written out: `{num(room_count)}`, or `{Num(x)}` at the start of a sentence. The incident log and the ledger can use digits.
- **The word on him.** Moving one of the `rep_` numbers (`rep_t28`, `rep_kids`, `rep_staff`, `rep_owner`, `rep_cook`) puts that group's word on him under the line where it happened, from `content/rules/word.yaml`. `last_word("t28")` gives back what they're saying about him by now (`""` if they haven't said anything), for the ledger.
- **The hidden measure.** `cocoon` goes up when he writes the log to read better than what happened, and never shows on screen.

## Ink things that bit us

- Tags can't contain `|`. That's why tasks use `::`.
- A choice inside a `{ condition: }` block needs its own divert, and a gather (`-`) inside a conditional is read as another condition. Put the choices in their own stitch and divert to it.
- `{ a: ... - b: ... }` isn't valid. For more than one condition use `{ - a: ... - b: ... - else: ... }`.
- The first content (`-> prologue`) has to come before any knot or function, so `main.ink` has the INCLUDEs, then `-> prologue`, then the VARs, and the fallback functions at the very end.
- Knots, stitches, VARs and LIST items share one namespace. A knot called `upstairs` collides with the LIST item `upstairs`. Check `main.ink` before naming anything.
- **Visit counts don't go up when you divert to a container you're already inside.** A stitch that loops back to itself, or `-> at_kitchen` from inside `at_kitchen`, won't count again. Use a VAR (like `door_reads`), or a labelled choice, which counts each time it's chosen.
- A stitch's gather labels are reachable from other stitches in the same knot (`-> t_opts` from `again_loop`).
- Choice labels share the namespace with functions too: a choice labelled `(stairs)` won't build next to a function `stairs()`.
- A choice with no words at all is a fallback, taken on its own when nothing else is left. An `#unlisted` choice needs words.
- Ink trims the spaces at the ends of lines. To join text across two lines, use glue: `<>`.
