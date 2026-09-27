# Production

Everything here is **[PROPOSED]** unless marked otherwise.

## Team

- **Hutch:** showrunner and writer with final cut. He can make the music and sound effects and do voice work. [DECIDED]
- **Claude:** staff writer, systems design, engineering, tools and shaders.
- **Art** is the bottleneck. **[OPEN]** Does Hutch draw? Is there a local painter or printmaker? Is there a budget?

## Engine: Godot 4, written in GDScript

- The current stable release is 4.7.2 (18 August 2026).
- It's open source (MIT), with no fees or royalties, and it runs natively on Hutch's Arch Linux machine.
- Its scenes (`.tscn`) and scripts are plain text, so Claude can read and write them directly. Unreal keeps most of its work in binary asset files and visual Blueprints. This matters more than anything else, because Claude is half the team.
- 2D is Godot's strength, and this is a text-and-2D game.
- Hutch designed an LLM bridge for Godot in April 2026 (an MCP server plus an editor plugin). Reuse it if it was built.
- **GDScript, not C#.** C# projects still can't export to the web in any released Godot 4 (true as of 4.7), and browser builds are how we playtest.
- **Not recommended:**
  - Unreal: a photoreal 3D engine with binary assets, overkill for a mostly-text game.
  - Unity: closed, its 2023 pricing fight cost developers' trust, and it offers nothing Godot lacks here. Disco was made in it, but that isn't a reason.
  - RPG Maker: it would fight every custom system in `02_SYSTEMS.md`.

## Content pipeline: keep the writing out of the engine

- **Scenes are written in Ink**, inkle's open-source narrative scripting language, using Inky or any text editor.
- **In Godot, Ink runs through inkgd**, which is pure GDScript. Its README says it works with Godot 4.2+ through its `godot4` branch, but there's no official Godot 4 release yet, and it's slower than the C# runtime. Smoke-test it before committing. The fallbacks are godot-ink (needs C#, which kills web export) or a GDScript dialogue plugin.
- **In the browser prototype, Ink runs through inkjs**, the official JavaScript runtime. The same `.ink` sources feed both.
- **Storylets and rule-matched lines** live in plain data files. The proposal: author them in YAML, and have a build script validate them and compile them to JSON, which both JavaScript and Godot load natively.
- Everything goes in git, with binary assets under Git LFS once there are any.

## Folder layout

```
the-bouncer/
  bible/            these documents; canon lives here
  sessions/         logs of played sessions
  content/
    ink/            scenes (.ink)
    rules/          storylets and rule-matched lines (YAML)
    data/           characters, voices, items (YAML)
  data/             generated files (psyche_states.json, compiled rules)
  prototype/web/    M1 browser text prototype (HTML/JS + inkjs)
  godot/            the Godot project (from M3)
  tools/            census, build, validators, path walker, state inspector
  art/              (from M4)
  audio/            (from M4)
```

## Tools Claude builds

- **Path walker:** walks every path through the content and reports dead ends, text nobody can reach, unset variables and impossible checks.
- **State inspector:** shows the whole world state at any moment. In a game this reactive, it's the debugger.
- **Random playthrough bots:** make random choices to find broken states.
- **`psyche_census.py`:** generates the 34 psyche states and 7 classes and checks the math. It already exists.

## Art direction [OPEN, pending Hutch]

The rule for a small team is to pick a style that's cheap per asset and strong as a whole. Return of the Obra Dinn is the proof: one person, simple 3D models, and a look that lives mostly in a shader.

- **The pick is a printed look.** The whole game looks like it was run off in the bar's back room: linocut, halftone, two or three inks, plus one accent color for neon and blood. It's the same visual language as the pamphlets, which are already a source of voices, so the look belongs to the world. The images are simple 3D models from Blender run through shaders Claude writes, and the style forgives imprecision.
- **Typography is half the art in a text game.** Each voice gets its own typeface: the pamphlet voice in propaganda type, the boxer in something heavy. It costs almost nothing.
- **Portraits.** Named characters get hand-made portraits. Strangers at the door are assembled from parts, the way Papers, Please builds its faces.
- **The floor view** is the bouncer's own sketch of the room on the back of the incident log. It's cheap, readable and in character.
- **The bar is the main set.** It's one room across thirty nights, so the craft goes there: light, smoke, damage, rats.
- **If there's a painter or printmaker**, portraits are where the money goes. Real linocuts, scanned in, would give the game a look nobody else has.
- **AI images** are for private mood boards only. Don't ship them.
- **Stand-ins until there's art.** The browser build draws its places and faces in code in this printed style (`prototype/web/src/ui/plates.js`). They cost nothing and each is replaced by dropping a file into its slot in `content/data/assets.yaml`. [PROPOSED 2026-09-26]
- **The alternative** is a painted look like Disco's, which needs a painter.

## Sound and voice

- **The score is the jukebox:** music inside the world, which Hutch writes and plays. Songs from the empire's last years carry history, and a song can be a voice source just like a pamphlet.
- **Foley:** record the empty bar (ice machine, cooler hum, keg changes, glass racks). Never record patrons.
- **Hutch voices the narrator.** The person telling the story at a bar years later should sound like a bartender, and if the teller turns out to be the bouncer, the switch from "he" to "I" lands in Hutch's voice.
- **The cast stays in text**, the way Disco originally shipped. One performer across thirty characters tends to sound like one performer.
- **Suno is for sketches only**; what ships is what Hutch plays. Generated audio falls under Steam's AI disclosure.

## Legal and platform

- **AI disclosure [OPEN, decide early].** Steam asks developers to disclose AI-generated content that ships with the game and is consumed by players, and AI content in marketing. AI tools used behind the scenes, like help with code, are exempt (Steam's form, clarified January 2026). Text Claude drafts that ships probably counts. Separately, in the US, AI-generated text without enough human authorship may not be protected by copyright, while what Hutch writes or substantially rewrites is his. So the choice is: (a) the game says openly what it is, or (b) Claude stays in the machinery and every line that ships passes through Hutch's hands. Either is defensible. Drifting into one isn't.
- **Real people:** composites, with names and details changed. Don't record patrons.
- **The title** is already on Square's *The Bouncer*, a 2001 PS2 game. It's fine as a working title; check it before it goes on a store page.
- **Platform:** PC first (Steam, itch.io). The Steam Deck is a natural target, since Godot builds natively for Linux. Readable text sizes and translatable text from day one; retrofitting either into a text-heavy game is miserable.

## Milestones

| | Milestone |
|---|---|
| **M0** | Project folder and bible in place; questions blocking Wednesday answered. |
| **M1** | Wednesday as a browser text prototype: door queue, rats, small floor, closing count, incident log, state inspector. |
| **M2** | The first three days (Wednesday prologue, Thursday daylight, Friday first shift) playable as text. |
| **M3** | Port to Godot with placeholder visuals; inkgd in place. |
| **M4** | Style test: the print shader on a rough model of the bar, and one portrait. |
| **Then** | Week one. Then thirty days. |

Rule: nothing new gets built until the current milestone plays end to end.

[PROPOSED 2026-09-27] Swap M3 and M4: the look first, on one scene at final quality (the door, 7:50 pm), then the port. See `08_FUTURE_FORM.md`.
