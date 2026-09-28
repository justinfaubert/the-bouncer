# The Bouncer in Godot

Wednesday, the test shift, first person from his posts, in the printed look. This is where the
game goes past the browser build (`prototype/web`), which stays playable as it is.

It is being built now. What's here so far:

- `ink/ink.gd`: the Ink runtime, ported from inkjs 2.3.2 (the version the browser build ships in
  `prototype/web/lib/ink.js`, with its one patch: an invisible default choice keeps its flag across
  a save). It plays the same story the same way, to the letter.
- `engine/`: the game's engine, ported from `prototype/web/src/core/` line for line: the room in
  his head (`psyche.gd`), checks (`checks.gd`), the voices' barks (`barks.gd`), the word on him
  (`word.gd`), and the game itself (`game.gd`: lines, checks, the hand, toys, the sketch, saves).
- `data/content.json`: the story and every rule, written by `node tools/build.mjs` from `content/`.

## Checking it against the browser build

Both tests play whole nights with a seeded player and compare every line with the browser build's
engine running the same nights in Node:

```
godot --headless --path godot -s res://tests/ink_run.gd -- --from 1 --to 40 --out /tmp/ink
node tools/ink_diff.mjs --from 1 --to 40 --godot /tmp/ink          # the Ink alone, and its saves

godot --headless --path godot -s res://tests/engine_run.gd -- --from 1 --to 40 --out /tmp/eng
node tools/engine_diff.mjs --from 1 --to 40 --godot /tmp/eng       # the whole engine
```

The engine test's player also fidgets with the clicker, handles the things he's given, puts a hand
on choices (the voices lean in), and saves and reloads mid-night. On 28 September 2026 both came
out identical for 40 nights of 40 (7,265 choices).
