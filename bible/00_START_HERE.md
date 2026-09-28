# The Bouncer: start here

*Working title. Bible v0.1, written 25 September 2026.*

A narrative RPG in the tradition of Disco Elysium, taken somewhere else. You play a new bouncer at a rowdy bar during the last thirty days of an empire. The voices in his head come from the people he learns from, and from books, pamphlets and the stories patrons retell. The job is the door and the floor: deciding who gets in, reading the room, and stepping into violence or stopping it. A narrator, telling the story years later, foreshadows an event that changes everything. Every choice changes the world, and the ending reflects the whole playthrough.

Made by **Hutch** (showrunner with final cut, music, sound, voice) and **Claude** (staff writer, systems design, engineering). Planned on the night of Friday, 25 September 2026, in a cloud session with no access to Hutch's files. These documents carry that session over to one linked to his machine.

## How to use these files

`the-bouncer.zip` unpacks as the start of the project folder: `bible/` (these six documents), `tools/` and `data/`. Unzip it where you keep projects, point the linked session at it, and say: "Read `bible/00_START_HERE.md` and `bible/05_LOG.md`, then continue." If you're attaching files instead, attach all six documents.

| File | Contents |
|---|---|
| `bible/HANDOFF_TO_CLAUDE.md` | A note from the planning session to the next Claude session: who Hutch is, how he works, traps to avoid. Read first. |
| `bible/00_START_HERE.md` | This: summary, working agreements, next steps |
| `bible/01_PILLARS.md` | Hutch's brief in his own words, the premise, writing rules |
| `bible/02_SYSTEMS.md` | The loop, voices, the psyche math, reputation, haunting, money, world state |
| `bible/03_WORLD.md` | Setting options, the bar, the calendar, day one and the rats, the narrator, the cast |
| `bible/04_PRODUCTION.md` | Engine, content pipeline, folder layout, tools, art, sound, legal, milestones |
| `bible/06_THE_HOTEL.md` | The building: the four doors, the pub, the rats' routes, the rooms upstairs |
| `bible/05_LOG.md` | Session log, decisions register, open questions |
| `bible/07_ENGAGEMENT.md` | What holds a player: the devices taken from Disco Elysium and what this game does past them |
| `bible/08_FUTURE_FORM.md` | The game past the prototype: Godot, the view through his eyes, the print made real, who makes the pictures, and the path |
| `bible/09_REVIEW.md` | The honest review before the Godot polish pass (28 September 2026): what works, what doesn't, what to invent, and what the pass builds; marked-up frames in `bible/review/` |
| `tools/psyche_census.py` | Generates the 34 psyche states and checks the math (zip only) |
| `data/psyche_states.json` | Its output (zip only) |

## Status markers

Every design statement carries one:

- **[DECIDED]**: Hutch said so. Canon.
- **[PROPOSED]**: Claude suggested it and Hutch hasn't confirmed it. Not canon.
- **[OPEN]**: an unanswered question.

Nothing moves from PROPOSED to DECIDED without Hutch's explicit OK.

## Working agreements

1. **Continuity lives in files.** Claude remembers nothing between sessions except what's written here. Every session opens by reading this file and `05_LOG.md`, and closes by updating `05_LOG.md` (session entry, decisions, open questions) and any other document that changed.
2. **Hutch has final cut.** Claude drafts in volume; Hutch cuts. His voice wins every argument about the writing. Anything that sounds like a chatbot gets cut.
3. **Play before writing.** Early sessions are played tabletop-style in chat: Hutch plays the bouncer, and Claude runs the room, the patrons and the voices. Logs go in `sessions/` and get mined for canon. Disco Elysium's world came out of years of tabletop play the same way.
4. **Depth before breadth.** Nothing new gets built until the current milestone plays end to end.
5. **Straight talk.** No flattery, no hedging. Disagree with reasons; update when outargued.
6. **Real people become composites.** Change names and details. Recognizable to Hutch and nobody else.

## Where things stand

- The brief, the premise, the thirty-day frame and the Wednesday rats prologue are DECIDED.
- The systems, the narrator, the engine and the art direction are PROPOSED and waiting on Hutch.
- Wednesday is written in Ink (`content/ink/`) and plays in the browser (`prototype/web/`, published as a private artifact), with director mode for editing it while playing. The folder is a git repo. (Updated 2026-09-26.)

## Next steps (linked session)

1. Unzip into `the-bouncer/` (or create it and put the documents in `bible/`), run `git init`, and add the rest of the folder layout from `04_PRODUCTION.md`.
2. Answer the questions blocking Wednesday (`05_LOG.md`, "Blocking Wednesday").
3. Play Wednesday as a tabletop session in chat. Log it in `sessions/`.
4. Build milestone M1: a text prototype of Wednesday that runs in a browser, with the door queue, the rats, a small floor, the closing count, the incident log and a state inspector.
