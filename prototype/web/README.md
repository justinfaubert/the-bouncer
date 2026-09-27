# The browser build

The game as it runs in a browser: the engine in `src/core/` (no DOM; the bots run the same code in Node) and the page in `src/ui/`. The story itself is in `content/ink/`, and `content.js` here is generated from it.

## Play it

- **In the Claude app:** https://claude.ai/artifact/J7S3kXF1LcQh3W8Z4u2nfi (private to Hutch).
- **On this machine:** `node tools/build.mjs`, then serve the project root and open `prototype/web/index.html`, for example `python3 -m http.server 8000` and http://localhost:8000/prototype/web/.

In the game, **Menu → Inspector** shows the world state, every check rolled, the voices, and the night so far, and can jump to any scene. **Menu → Copy the night** copies the whole playthrough as text.

- **Offline:** `node tools/build.mjs --offline` writes `releases/The-Bouncer.html`, one file with everything inlined that plays from the hard drive. The published build offers it too (Director's desk → Send → Save a copy to play offline).

## Direct it while you play

**Menu → Director mode** (or the D key). Tap any line to rewrite it, cut it, add a line after it in any voice, or leave a note; reword a choice with the Reword button beside it; answer a writing prompt where it shows. **Step back** (B) undoes the last choice so the other branch can be tried. Edits show in the game at once, stay in the browser, and go to the artifact's database when the account connection is on. The **Director's desk** lists them all and sends them to Claude.

Merging them into the Ink: `node tools/director.mjs <edits.json> --apply` finds each line in `content/ink/` and changes it there, lists what it couldn't place, and records what went in (`content/director/merged.json`), so the game stops laying those edits over the text. The rules for writing lines the tool can find are in `content/ink/README.md`.

## What's on the page

- **Plates** (`src/ui/plates.js`, screened like a two-colour press by `src/ui/print.js`): a print of each place when he walks in, drawn in code as it is at that moment (how full the room is, table 28's glasses, the rats, which doors are propped), tinted by the hour. A place gets a new plate only when it has changed; otherwise a small one marks the move and the time. Faces for people with portraits are assembled from parts, and look at him warmer or colder as he stands with their group. Settings → Pictures turns them off.
- **Checks** (`src/ui/roll.js`): the dice wait in his hand (hold to shake them, let go to throw), tumble, hang, and the result is stamped; the room dims while they're in the air. Settings → Dice sets the pace; a tap skips.
- **The voices and the player's hand** (`src/ui/hand.js`): a voice leans in on the choice the pointer rests on (press and hold on a phone), and notices waiting, reading back and coming back. Settings → The voices notice you.
- **Marks** (`src/ui/marks.js`): a voice rings a detail of a plate and writes beside it (`content/data/marks.yaml`).
- **Things in his hands** (`src/ui/props.js`, `src/ui/toys.js`): the clicker, licences, the kid's phone and the binder, handed over by `#prop:` in the Ink (`content/data/props.yaml`). A choice marked `#toy:` is made by handling the thing.
- **His skin** (`src/ui/skin.js`): drink, hurt, his heartbeat and the rain on the door's glass, laid over the page. Settings → In his skin.
- **The word on him:** what a group says about him when something lands with them, under the line where it happened (`content/rules/word.yaml`).
- **The floor sketch** carries his notes: what he last saw and when (`Game.sketch`), fading as it goes stale.
- **The light of the night:** the page's wash follows the shift clock (`data-phase` and `data-here` on `.app`, in `style.css`).
- **The sound of the room** (`src/ui/audio.js`, `AMB.bar`): the crowd, the pool table, the jukebox, the rats and the rain follow the night, mixed by where he's standing.
- **The ledger** prints like the till's tape at close, a line at a time, and tears off (`printTape` in `src/ui/app.js`). Space, enter or a tap prints the rest.

The design reasons are in `bible/07_ENGAGEMENT.md`.

## Add art and sound

Every cue the Ink can fire has a slot in `content/data/assets.yaml`. Put the file at the path given there (under `audio/` or `art/`) and run `node tools/build.mjs`. The game uses the file from then on and the placeholder until then: a synthesized sound, silence for music, a face drawn from parts for a portrait. Nothing in the Ink changes.

## Publish a new version

```
node tools/build.mjs --dist
```

This writes `dist/`: `artifact.html` (the page as the Artifact host wants it), `files.json` (every file it loads), and copies of those files, art and sound included. Publish `artifact.html` with those files to the same artifact URL so the link and the player's save carry over. `dist/` is generated and not committed.

## Saves

One slot, written after every choice, in the browser's storage (`bouncer.save.v1`). Settings → **Save to my Claude account** also writes it to the artifact's database at `data/users/<player>/save`, where Claude can read how a night went. The save format is in `src/core/game.js` (`serialize`).
