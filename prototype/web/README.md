# The browser build

The game as it runs in a browser: the engine in `src/core/` (no DOM; the bots run the same code in Node) and the page in `src/ui/`. The story itself is in `content/ink/`, and `content.js` here is generated from it.

## Play it

- **In the Claude app:** https://claude.ai/artifact/J7S3kXF1LcQh3W8Z4u2nfi (private to Hutch).
- **On this machine:** `node tools/build.mjs`, then serve the project root and open `prototype/web/index.html`, for example `python3 -m http.server 8000` and http://localhost:8000/prototype/web/.

In the game, **Menu → Inspector** shows the world state, every check rolled, the voices, and the night so far, and can jump to any scene. **Menu → Copy the night** copies the whole playthrough as text.

## Add art and sound

Every cue the Ink can fire has a slot in `content/data/assets.yaml`. Put the file at the path given there (under `audio/` or `art/`) and run `node tools/build.mjs`. The game uses the file from then on and the placeholder until then: a synthesized sound, silence for music, a lettered card for a portrait. Nothing in the Ink changes.

## Publish a new version

```
node tools/build.mjs --dist
```

This writes `dist/`: `artifact.html` (the page as the Artifact host wants it), `files.json` (every file it loads), and copies of those files, art and sound included. Publish `artifact.html` with those files to the same artifact URL so the link and the player's save carry over. `dist/` is generated and not committed.

## Saves

One slot, written after every choice, in the browser's storage (`bouncer.save.v1`). Settings → **Save to my Claude account** also writes it to the artifact's database at `data/users/<player>/save`, where Claude can read how a night went. The save format is in `src/core/game.js` (`serialize`).
