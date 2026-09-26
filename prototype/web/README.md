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

- **Plates** (`src/ui/plates.js`): a print of each place when he walks in, drawn in code as it is at that moment (how full the room is, table 28's glasses, the rats, which doors are propped), tinted by the hour. A place gets a new plate only when it has changed; otherwise a small one marks the move and the time. Faces for people with portraits are assembled from parts. Settings → Pictures turns them off.
- **The floor sketch** carries his notes: what he last saw and when (`Game.sketch`), fading as it goes stale.
- **The light of the night:** the page's wash follows the shift clock (`data-phase` and `data-here` on `.app`, in `style.css`).

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
