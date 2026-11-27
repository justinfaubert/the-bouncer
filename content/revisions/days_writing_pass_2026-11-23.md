# The days: writing pass, 23 November 2026

Hutch, 23 November, after playing the combined build: "a look at the story we have for the days so far and seeing where the writing could be improved and interesting ... a lot of the writing still has AIisms in it like.. 'X was the Y. X was always the Y'. lots of examples of that."

Claude's pass, PROPOSED. Hutch has final cut.

## What changed

**The echo.** `tools/echoes.py` is new. It finds two sentences side by side that open the same way ("It hears them. It hears everyone.", "He didn't point. He didn't have to.") and flags the worst kind, where the second is the first with one word slipped in. Every one the narrator owned is gone, and so is its cousin, the deadpan "always" line ("It would be forty minutes. It was always forty minutes out here.", "One car. It was always one car out here.", "Hydro was always fifty.", "The law comes after, if it comes. It always comes after."). Echoes left in people's mouths are how people talk ("Cash only, folks. Cash only.") and stay.

**The narrator's tics.** About sixty lines across Wednesday, Thursday, Friday and the toys:
- "He didn't say anything. He didn't have to/need to." and the bartender's eight silent looks. Each is now a thing his hands did: the glass set down upside down, the change counted coin by coin onto the wet bar, the coffee put down black.
- "He said it [to the till / to the table / like a question]." There were 35. The ones that repeated are rewritten or cut.
- Wry closers and stated takeaways: "which was worse", "which in a bar it is", "That was the idea.", "It was the taking.", "So was the ex.", "Later, he wished he had.", "She didn't argue, and that was worse."
- Simile tails: "the way you step around a sleeping dog", "the way you'd take something the dog brought in", "as if it hadn't noticed", "his face shut like a door".
- Two scenes shared "the way he'd done it every night for thirty-one years". One has a groove worn in the brass dimmer now; the other rinses the old man's glass and shelves it apart from the others.
- The day-end template "That was the Thursday. / That was the first Friday." is gone; the narrator starts on the fact.

**The voices.** The Father's aphorisms on Friday became memories ("The Fraser boys' cousin had the day cold and gave me nineteen-ninety for a ninety-one card. I let her in anyway. She bought me a rye."; the Courtenay Elks; Legion hands; the Legion cook's Remembrance Day turkey). The Fighter in darts reads distances ("Seven foot nine and a quarter to the board, and it hasn't moved") and not "Thinking is how you miss". The fight practice lines lost "That's all it ever is."

**The ogre on the deck** (fight_cards.gd). The end card is less tidy and harder: "The bruises are yours, the paperwork's yours, and when the man at the rail gets a lawyer, the lawyer will want the name of whoever was on the door. The RCMP come on Tuesday, with a clipboard."

**A little more life on Thursday.** The Esso woman's word search has found PENNY, ALMANAC and SOVEREIGN and is hunting for EMPIRE. If he read the classifieds, table 28 find his own job ad still running ("Gary's shopping around!" "Gary's been shopping around since 1994. Ask his wife."). In eleven, the man with the moustache blames Ottawa for the mill, his knees and his marriage.

**Jim.** Three leftover "she"s for the bartender are now he (the incident book at close, his car leaving before the parley, the weapon call).

## What I'd change next (for Hutch to pick)

1. **Two Jims on Friday.** DECIDED (Hutch, 23 November): leave Friday as it is for now.
2. **Thursday has a clock and nothing racing it.** Sunset spends the day, but nothing is lost by being slow. Give it one thing that happens at a set time and can be missed: the big man's daughter at the two o'clock ferry with his phone, or the bookkeeper walking to the bank with the Sov's deposit bag.
3. **Friday's line is six quick reads.** Let one face from the line come back changed on Saturday (different hair, the binder's 86 list), so the door remembers.
4. **The narrator is the self-aware hook.** "I've told it to you before anyone else" now opens Thursday. If the narrator is a man telling his month to a machine, he can correct himself at the day ends, admit the bar clock was wrong, get a name wrong and fix it. One per day, no more.
5. **The GDScript text.** Darts, fights, the cigarette machine and pool career text don't go through tells.py or echoes.py (they read Ink only). They were spot-checked by hand this time. Worth pulling those strings into a data file so the same checks cover them.

## Second pass, 25 November: edge, the walls, meat on the days

Hutch, 25 November: "Edge: needs more. I appreciated the pinup. the words around the payphone need to be more relatable, funnier, more timely and self-aware. similarly around the world ... the esso station is threadbare almost." And: "Writing is getting better but needs more on our next days there. Needs more meat and engaging beats."

- **The payphone wall** (hall.ink, and `godot/textures/phone_wall.png` from `sketches/door-look/tools/textures.py`, so it reads on the wall in the game too). Shelley answers back at 61. A ROBOT WROTE THIS WALL, and under it ROBOTS CAN SPELL, DARREN. Rent for a basement in Nanaimo with a window well. ELBOWS UP and 51st STATE MY ASS, with gas cheaper in Bellingham. HOW'S MY DRINKING? 1-800-EAT-SHIT (it's a church). Narcan in a first aid kit that doesn't exist, until Jim puts one on the shelf over the ice. THE NEW DOORMAN IS A, unfinished, and the pencil sharpened since. MILL CLOSES JAN 15, with nothing under it.
- **The scrawl by the washrooms** (things.ink, `dress_scrawl.png` from `godot/tools/dressing2.py`). Who puts the lime in the helmet? Ask the old guy at the end of the bar. What old guy. "told my wife I was at the gym", answered with "hi Deb". OTTAWA OWES ME A BEER, answered with "get in line".
- **The Esso night window** (grounds.ink). Deb in pyjama pants and a Canucks hoodie, buying Lotto Max and Pall Malls with a case of Pilsner strapped into the baby seat. Two roller dogs. The kid's worst-thing-ever-bought story.
- **Thursday: Kayla at the dead truck** (days.ink, `kayla_truck`). If the big man's truck is still on the gravel, his daughter is in it in the afternoon, turning the key on a flat battery. What she says depends on Wednesday: put out, lied to her for him, got him to the hospital. The grade-eight photo in the visor. The mickey goes in her purse. He can boost it with the beer store kid's cables, ask if her dad's sober, or walk past. Friday reads it (`kayla_thu`).
- **Friday: the red cap** (friday.ink, the wave). A kid in a Carhartt with 51 and a star on his cap, "a bit" for his Liberal brother-in-law, while table 28 heckle through the window. In, hat off, or out. Close reads it (`hat_how`).
