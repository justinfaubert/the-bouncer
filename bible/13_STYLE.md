# Style

*The house style for the writing, the picture and the sound, drawn from the writers and shows Hutch named on 18 November 2026: Philip K. Dick, Haruki Murakami, Goethe, Jonathan Carroll, Ted Chiang, The Twilight Zone, Twin Peaks, The X-Files, Tarkovsky and Věra Chytilová's Daisies. [PROPOSED] until Hutch has judged the three revised scenes in `content/revisions/`.*

Read this with `01_PILLARS.md` (the rules), `10_VOICES.md` (how each person talks) and `11_SKELETON.md` (what happens). This file is about how it's told.

## What's wrong now

Wednesday is about 75,000 words of Ink. It's competent, and it's flat in one consistent way: every scene is in the same clipped, wry, watchful register, and almost nothing in it is strange. Counted on 18 November:

- **"the way" 138 times.** Lines close on a soft simile: "the way water closes", "the way a man comes down to his own kitchen", "the way you'd tell someone the time". One is good. A hundred and thirty-eight is a tic, and every moment lands with the same small thud.
- **"nobody" 151 times.** The prose keeps saying what people don't do and don't say. That's the teller's knowingness leaking into every line, and it makes the night feel already summed up.
- **The teller speaks 11 times all night.** The voice that is supposed to foreshadow the Big One is nearly absent. The tells (the glasses ringing, the light over the strait, the rats) are there, but nothing frames them, so they read as set dressing.
- **Every scene ends on a button**: a dry last line that closes it ("Table 28 filed everything away."). Closing every scene tells the reader nothing is left open.

None of the sources below would write a night like that. Each is in here for what it does that we don't.

## The rules that come out of it

The short version, for every line written from now on. The sources follow, with the reasons.

1. **Cut the soft simile at the end of a line.** If an image is needed, put it first and plain. No more than one "the way" a scene.
2. **Say what is there, not what isn't.** "Nobody" and "never" belong to the teller, and the teller is rationed.
3. **The strange comes in through ordinary things**: a price, a card machine, a clock, a glass ringing on the back bar. Never through spectacle, and never explained in the scene it appears.
4. **Routine is written with care.** The count, the mop, the till tape. The strange only lands against something we believe.
5. **The teller opens and closes each night, and says plainly what's coming.** Two or three lines, cold, before anything else. Dread comes from knowing, not from mystery.
6. **Each night has one turn**, a moment that changes what the night meant. Know it before writing the night.
7. **Leave scenes open.** End on the last thing that happened, not on a line about it.
8. **Hold some moments too long.** A beat where nothing is chosen and nothing is said, and the room goes on.
9. **Warm first, the bill later.** People are written so the reader likes them before the town turns on itself.
10. **Every strange thing gets two readings, and the game keeps both.** The plain one and the strange one, from two voices.
11. **The best talker in the game is the one we think is wrong.** The Rat King, the conspiracy man, Gary's money. No caricatures.
12. **One rule per strange thing, kept.** If the rats hear through walls, they hear through every wall, and never through glass.

---

## What reads like a machine

*Hutch, 21 November 2026, after the harder-dial rewrite of Wednesday: "better, the writing still reads AI too much though overall". This section is what came of it: the tells, how many there were and how many are left, and how each voice gets out of them. [PROPOSED]*

Nobody notices one tell. They notice the same move made a hundred times, and after that they stop trusting the page. Each move below is fine once in a scene.

### The tells, counted

`python3 tools/tells.py` counts them over the Ink's narration, lines and choices (`--show 'the way'` lists the lines). Wednesday before and after the pass of 21 November, 52,652 words before and 50,746 after:

| Tell | Before | After | The kind that went |
|---|---|---|---|
| "the way" | 122 | 58 | "the way you'd tell someone the time". Nearly all of the 58 left are literal (all the way, on the way, the way it happened) or in the narration about the bartender |
| "as if", "as though" | 36 | 5 | "as if he'd only just found out what he was holding" |
| "Not X. Y.", "It wasn't X. It was Y." | 39 | 25 | "Not the quiet of men who've stopped talking. The quiet of men in church." Most left are in people's mouths |
| "for a long time", "for a moment" | 36 | 26 | the stock pause |
| ", which" | 45 | 27 | the wry aside: ", which was worse than if he'd shouted" |
| "That's how/what/all/the" | 69 | 42 | "That's the whole job, done backwards." |
| "always" | 50 | 33 | "That kind always calls." |
| "nobody", "no one" | 145 | 122 | "Nobody counts the ones who come in while nobody's counting." |
| lists of three | 414 | 386 | the tidy triple; most left are real lists |

What's left is mostly the bartender's lines and the narration about her, which wait for her rewrite as Jim.

### The echo

*Hutch, 23 November 2026: "X was the Y. X was always the Y". lots of examples of that.* Two sentences side by side that open the same way, the second the first with a word slipped in: "It hears them. It hears everyone." "He didn't point. He didn't have to." "It would be forty minutes. It was always forty minutes out here." `python3 tools/echoes.py` lists them. In a narrator's mouth, never; in a drunk's, sometimes, because people do repeat themselves. The pass that cleared them is in `content/revisions/days_writing_pass_2026-11-23.md`.

### The narrator

- **End on the last concrete thing.** Cut the line that comments on it: "Then he sat.", "He didn't need to.", "That was the thing about him", "Table 28 said a great many things."
- **No simile tails.** A concrete detail usually does the job: "the way you'd lift a sack you had some respect for" became "The coat was cashmere, and wet through at the seat."
- **No stated takeaways.** "Nearly a day late, somebody told him" became what he told him: the hospital, since the morning, her heart.
- **No stock body reports:** "for a long moment", "stood very still", "without a word", "a sound he felt more than heard", "his face said he'd remember that". Say what the body did: "The big man stood in the rain with his hands at his sides."
- **When a voice reads someone wrong, the narrator doesn't correct it.** He puts down the detail that contradicts it: "The boyfriend's knuckles were scabbed over, both hands."
- **Repeats across files read as a template.** "Heavier than he looked" was in three scenes and "the way a drunk man drives when he knows he's drunk" in two. Search before reusing an image.

### The voices

The worst of it was the voices talking in aphorisms, lines that would fit on a mug. Real people mostly don't talk like that. Each voice has its own way out:

- **THE FATHER remembers instead of pronouncing.** Specific, petty, and usually against himself: "Ray Sinclair used to tip me fifty. I let him drive home three times I shouldn't have." "I never touched that. I had the rye. Rye's legal." A few plain door rules stay, said like a man giving instructions ("Right pocket, every door I ever worked"). His places so far: the Legion, Campbell River, Courtenay, the Fraser boys. The doorman's mother comes up, but not every time.
- **SENIOR** (Gary's dead father) is petty, with years and dollar amounts: "Your mother's brother could lie, and he took me for nine thousand dollars in 1971."
- **THE TILL** gives numbers, not opinions: "Three dollars of rye, gone."
- **THE MANUAL** is binder text with section numbers, never wise and never sarcastic. If it's funny, it doesn't know it. Sections so far: 2 The Door, 3 Service, 4 Premises, 5 Liability, 7 Use of Force, Part 6 (suspension and offences), and Module 3, on the Saturday.
- **THE WRONG MAN** is a drunk's story, retold. He's never sure of it, he contradicts himself, or somebody contradicts him: "The drunk said the keys were still in it. Then he said they weren't." "The drunk's wife said it was him that never came." Never a moral.
- **THE FIGHTER** reads bodies, weights and distances: "A hundred and forty pounds, maybe. You could carry him out under one arm."
- **THE TABLE and table 28** shout, and echo half as often as they did. A callback beats a repeated word: "A woman! Lorraine, in six!"
- **The one with the hearing aid** mishears instead of echoing: "What about Expo?", "In the walk-in clinic?", "Who fell?" He gets one "Arse."
- **THE KID** writes in lowercase and talks about his family. No "that's the thing".

---

## The sources

Each source gets: what it does, where that goes in The Bouncer (writing, structure, picture, sound), and what not to take. The "where" is the point. A technique with no place in the game is trivia.

### Philip K. Dick

**What he does.** Reality fails at the level of junk. In *Ubik* the cigarettes go stale and the coins carry the wrong face before anyone admits the world is wrong. The objects decay backwards, and the ads for Ubik at the top of each chapter are the voice of the thing holding the world together. His people are repairmen and salesmen, tired, in debt, worried about a boss and an ex-wife while the universe comes apart. In *Do Androids Dream of Electric Sheep?* empathy is the test that separates people from machines, and the test is a machine. Kipple, the junk that breeds when nobody's looking, fills every flat. And his line that reality is the thing that doesn't go away when you stop believing in it.

**Where it goes.**
- *Writing.* The empire's end shows first in cheap things, never in headlines: the card machine declines and then accepts the same card; the price of a two-four is up two dollars since Monday and the store clerk says it's always been that; the TV's crawl repeats a story from yesterday with one word changed. Each night adds one small wrongness to the objects, and nobody in the scene remarks on it. The tells list in `11_SKELETON.md` gets a junk layer.
- *The door as Voight-Kampff.* Checking a licence is an empathy test run by a machine (the scanner). The game already lets him look past the card to the face. Build on it: the scanner says yes and the face says no, and the choice is which one to believe.
- *The voices as ads.* Some voices in his head come from pamphlets and products. Let one of them talk like a Ubik epigraph: a sales voice that is sure of everything and is, now and then, the only thing that's right.
- *His people.* The doorman is a working man first. Money, rent, the shirt that's too small. The Big One happens to a man worried about his shift.
- *Picture.* Misregistration as reality slipping. Today the plates drift when he's drunk. Let them drift, a little more each week, when he's sober too, so by week four the print itself is going wrong.
- *Sound.* The scanner's beeps, the till's printer and the card machine are the machines' voices. They should be the cleanest, most certain sounds in the game.

**Don't take.** The pulp: precogs, androids, alternate presidents. Nothing in the Sov is science fiction. His wrongness is in the objects, and that's all we want.

### Haruki Murakami

**What he does.** A calm, flat first person reports the impossible in the same tone as boiling spaghetti. In *The Wind-Up Bird Chronicle* Toru Okada cooks, looks for a lost cat and takes strange phone calls, then sits for days at the bottom of a dry well and comes out with a mark on his cheek. The other world is entered through ordinary places: a well, a hotel room, a corridor. In *Dance Dance Dance* the Dolphin Hotel has a dark floor that isn't always there, where the Sheep Man lives. Long stories told by strangers sit inside the books whole (Lieutenant Mamiya's war story in *Wind-Up Bird* runs for a chapter, in his voice). Music is specific and named. Mysteries stay open at the end, and the books are better for it. He ran a jazz bar for seven years before he wrote; the bar's routines are in all of it.

**Where it goes.**
- *Writing.* The doorman's routines are written with full attention: the count, how he folds the incident log, the mop and the yellow sign. Then the strange arrives in the same sentence rhythm, with no change of tone. "He mopped the tiles inside the door, put the sign out, and heard the glasses on the back bar ring once, though there was no truck on the highway." No exclamation, no voice leaping in, no "the way".
- *The Sov is a hotel.* Room twelve, the rooms upstairs, the back stairs. One of them is our Dolphin Hotel floor: a room that isn't always there, or is there only to him, late. The Rat King's place is the well.
- *Retold stories, whole.* The pillars say voices come from memories retold by patrons. Murakami shows how: let a patron tell one story at length, in his own voice, uninterrupted, and let it matter later. The old man's story of 1946, and of 1700, should be written as a Mamiya chapter.
- *Leave it open.* The game already gives two readings of the Big One. Murakami gives permission never to settle anything else either: who the Rat King is, what was in room twelve.
- *Picture.* Empty, clean, quiet frames. The bar before open, the back hall at four in the morning. The print can go nearly bare: one ink, a lot of paper.
- *Sound.* Specific songs, by name, on the jukebox. The room tone of an empty bar. Silence that has a hum in it.

**Don't take.** The passive man to whom things happen, the women who exist to lead him somewhere, and the cats as decoration. Our doorman acts; that's the job.

### Goethe

**What he does.** *Faust* is a wager: Mephistopheles may have Faust's soul if Faust ever says to a passing moment "stay, you are so beautiful". Mephistopheles is the best talker in the book, and he describes himself as part of the power that always wills evil and always works good. In Auerbach's Cellar, Mephistopheles takes Faust to a tavern of drunk students, bores holes in the table and pours whatever wine each one wants, then makes it burn. Walpurgis Night is a whole witches' carnival on a mountain. In *Wilhelm Meister's Apprenticeship* a secret society, the Tower, has been watching and steering Wilhelm's education all along and finally hands him a certificate of apprenticeship. In *Elective Affinities* four people pair and repel like chemicals. "The Sorcerer's Apprentice" starts the water and can't stop it. In "The Erl-King" a father rides through the night with his son, who sees the Erl-King and hears him, and the father sees only mist and willows; the son is dead when they arrive. And his *Theory of Colours* treats colour as feeling: yellow near and warm, blue cold and far, shadows tinted by the light that casts them.

**Where it goes.**
- *The Rat King's parleys are the wager.* Write each parley as Mephistopheles would talk: courtly, funny, completely persuasive, and right about the town. Terms with the rats always will evil and work good, or the reverse, and the old man knows it and says so.
- *The moment he'd ask to stay.* A Faust mechanic, quiet: once a week the game offers him a moment of plain contentment (the bar at two with the chairs up, a drink after, the lifer laughing). He can stay in it. Staying costs something he doesn't see until later. It's never flagged as a choice that matters.
- *Auerbach's Cellar is a Saturday.* A night where the drinks seem to come from nowhere and everyone gets exactly what they want, and then it burns. The mill's wake on day 24 is our Walpurgis Night: the biggest crowd of the month, a strange drug going round, the town's whole carnival in one room and the lot.
- *The apprenticeship.* Table 28 and the lifer are the Tower. They have been watching and testing him from the first night, and near the end someone tells him so, or hands him something that amounts to a certificate (a key, his name said aloud). The rumour system is their file on him.
- *The flood is the Sorcerer's Apprentice.* Day 17: he starts something in the keg room he can't stop. The voice that knows the spell isn't in the room.
- *The father is the Erl-King's father.* THE FATHER voice reasons; it sees mist and willows. Give the doorman a voice that sees and hears what the father won't, and make the father wrong in the one case where it matters.
- *The voices in his head pair and repel.* That's already the psyche math. *Elective Affinities* gives the language for it in the writing: some voices bond in his head and push a third one out.
- *Picture.* The five inks get meanings from the *Theory of Colours*: the lamp's yellow near and warm (the bar, people), the cold's blue-green far (the back hall, screens, the mainland), the neon's red for heightened moments only, the earth for wood and the old, the night ink for the dark. Shadows take a tint from the light that throws them, which the press can do.
- *Sound.* Songs sung in the story, the way Mignon's and the Harper's songs are inside *Wilhelm Meister*. The bartender's closing song is ours.

**Don't take.** The grandeur, the abstraction of *Faust Part Two*, and the length. Goethe is here for structure and for a few great devices.

### Jonathan Carroll

**What he does.** Chatty, warm, specific first-person voices that you like immediately, in lives full of food, friends, dogs and jokes, and then the floor goes. In *The Land of Laughs* Thomas Abbey goes to the small town of Galen, Missouri, to write the biography of a dead children's author, and finds that the town and its people came out of the author's writing, and want him to keep writing them. His dogs talk, and it's treated as normal. The fantasy isn't explained; it's met in conversation. The turn comes late and hard, and you realise the charm had a bill attached the whole time.

**Where it goes.**
- *Warm first.* Table 28, the lifer, Terry, the regulars: written for two weeks as people you want to drink with, funny the way real people are funny, with jokes that go on too long. The pillars ask for the very good times. Carroll shows that they're not a break from the stakes; they are the stakes.
- *The bill.* In week four, the same warmth costs: the table won't leave when the water comes, and you understand why, because you've sat with them.
- *The town was made by someone.* *The Land of Laughs* is the closest any book comes to our ending: a town whose people were written from someone's stories, and the game says at the end that a man who worked the door told his stories to a machine and the machine made them into this. Carroll shows how to land that without a wink: as a plain fact the characters live with.
- *Strange things in conversation.* When something impossible happens, people talk about it the way they talk about the weather and the hockey, in the same breath. The spiral over the strait argued about between rounds.
- *Picture and sound.* Warm light and real laughter early, so their absence later is felt.

**Don't take.** The whimsy. Carroll's charm can go cute. Our warmth is a bar's warmth: loud, crude, generous, a bit sad.

### Ted Chiang

**What he does.** One premise, followed honestly to every consequence. In "Story of Your Life" Louise learns an alien language that lets her perceive time all at once, so she knows from the start how her daughter's life will end, and chooses it anyway; the structure of the story is the language's structure. In "Exhalation" a mechanical scientist dissects his own brain and finds his world runs on air pressure that is slowly equalising, so his whole civilisation will stop, and he writes it down for whoever comes after. In "The Merchant and the Alchemist's Gate" a man tells a caliph nested stories about a gate into the past, where the past can't be changed but can be understood. In "The Truth of Fact, the Truth of Feeling" a man with a recorded life finds his memory of a fight with his daughter was wrong, side by side with a story of a people meeting writing for the first time. "Hell Is the Absence of God" treats angelic visitations like earthquakes, with insurance and casualties. "Liking What You See" is told as a documentary of many voices. No villains, no speeches, and story notes at the end of each book saying where the idea came from.

**Where it goes.**
- *The teller is Louise.* He knows how the month ends, and he chooses to tell it in order. Let him say it plainly, early: "Four weeks from that night the ground moved." The dread is watching a man walk towards something we already know about. That's how the teller's two or three lines a night work.
- *Exhalation is the empire.* A civilisation running down by a physical law, noticed by someone careful, written for whoever comes after. The Big One and the empire's end are pressure equalising: slow, lawful, no villain. The Lightkeeper's log can read like the scientist's notes.
- *The till tape against the teller.* "The Truth of Fact, the Truth of Feeling" is our two records: the till's tape and the incident log say what happened; the teller says what it meant. Sometimes they disagree, and the game shows both. The reckoning at the end, with every night's tape on the spike, is where it pays off.
- *Nested tales told to a listener.* The teller is telling someone at a bar, a story with stories inside it. "The Merchant" is a model for the frame.
- *One rule per strange thing.* What the rats can hear, what the old man knows, what the spiral was: each gets one rule, written down in the bible, and the writing never cheats it.
- *Many voices.* "Liking What You See" is the rumour system as a form: what each regular says about the doorman, in their own words, side by side.
- *Picture and sound.* Restraint. Nothing gets louder or brighter to tell you it's important.

**Don't take.** The science-fiction premises and the dry essay voice. Chiang is here for honesty and structure.

### The Twilight Zone

**What it does.** Rod Serling steps into the frame, in a suit, and tells you plainly who this man is and what's about to happen to him, then steps out. Ordinary people in small towns and ordinary jobs, pushed. Twenty-five minutes, no fat. The turn at the end is moral: it shows you what the people were. In "The Monsters Are Due on Maple Street" the power fails on a suburban street, the cars won't start, and in one evening the neighbours turn on each other; then the camera pulls back to the ones who cut the power, who say that's all it takes. In "Eye of the Beholder" the faces of the doctors and nurses are kept in shadow for the whole episode, until the reveal. In "Time Enough at Last" a man who only wants time to read gets it, and breaks his glasses. In "Walking Distance" a tired man walks back into the town of his childhood.

**Where it goes.**
- *Maple Street is our last night.* The power fails, the phones die, and the door becomes the town's first border. Serling wrote that episode for exactly this: people under a dead sky deciding who's one of them. Day 29 should be written with it open beside us.
- *Serling's frame is the teller's.* Cold open on one image, then the teller in two or three plain lines saying who and what's coming, then out. Same at close. Every night.
- *Economy.* Each night's scenes should be cut to the bone. If a scene doesn't change something someone says later, it goes (that's already a pillar).
- *The turn.* One per night, moral, not a trick: the moment that shows who someone is. The sister at the door. The big man's coat.
- *Faces withheld.* "Eye of the Beholder" in the picture: a face we don't see until it matters. The Rat King's man, seen only from behind or in shadow until the first parley.
- *Picture.* The colour plates drop away at the turn of each night: a few seconds in the key block alone, black on cream.
- *Sound.* A sting at the turn, short, one instrument.

**Don't take.** The twist for its own sake, and the moral spelled out in a closing speech. Serling's narration said the moral; our teller never does.

### Twin Peaks

**What it does.** A small town's secret life, centred on its diner and its roadhouse, where a band plays at the end of the night. Soap opera and horror in the same scene, played straight. Cooper talks into his tape recorder to Diane, who we never see. A dead girl is the absence at the centre of every scene. Sincere delight in ordinary things: damn fine coffee, cherry pie, the trees. Eccentrics who know something (the Log Lady's log hears things). "The owls are not what they seem." The Giant: "It is happening again." Lynch holds shots far past comfort: in *The Return* a man sweeps the Roadhouse floor for two minutes while the music plays. The hum of electricity, the flicker of a fluorescent tube, as dread. Badalamenti's "Laura Palmer's Theme" goes from a low synth sadness to a swell that's almost too beautiful, and back.

**Where it goes.**
- *The Sov is the Roadhouse.* A band on Saturdays (open question 22) gives us the end-of-night performance. The jukebox's closing song does it the other nights.
- *The teller is Cooper talking to Diane.* A voice speaking to a listener we never see, and the end tells us who the listener was. Keep the teller's lines addressed to someone: "You'd have liked her."
- *Sincere delight.* The doorman can love things without irony: a good pour, the first cold air at the door, fries from the cook at midnight. It isn't quippy if it's sincere. Lynch is the proof.
- *The eccentrics.* The Lightkeeper, the Faller, the old man: each one sees one face of what's coming, as the skeleton says. Write them as Log Lady figures, taken completely seriously by the game, laughed at by some of the room.
- *Held moments.* Once a night, a beat held too long on purpose: the clock, the empties on the rail, the lifer wiping the same spot. In the Godot build, a moment where the column waits and the room goes on.
- *Electricity.* The back hall's tube, the neon's dead E, the hum of the coolers. Power is the thing that fails on day 29, so make it present from day 1.
- *Picture.* The neon red used rarely and on purpose. A room at the back that looks wrong. Curtains and the old hotel's carpet.
- *Sound.* Room tone as dread. The tube buzzing in the back hall. A theme for the teller that moves from low and sad to a swell and back.

**Don't take.** The Red Room's iconography (the zigzag floor, the curtains, backwards speech), Bob, and the FBI. Lynch's surface is so recognisable that borrowing it reads as homage. Take the method, not the look.

### The X-Files

**What it does.** A case of the week carried on a mythology that runs for seasons. A cold open, usually with a victim, before the titles. Two people take two readings of every case, the believer and the sceptic, and the show keeps both alive for years. Its best episodes break the form. In "Jose Chung's From Outer Space" an author interviews the witnesses to an abduction, and every account contradicts the others. In "Bad Blood" Mulder and Scully each tell the same case and each makes the other the fool. In "Clyde Bruckman's Final Repose" an insurance salesman can see how everyone will die, and it doesn't make him happy. Torches in the dark, a flashlight beam crossing a room.

**Where it goes.**
- *Each night is a case.* The sister at the door, the coat, the inspector, the flood: one case a night, solved or not, carried on the arc of the sky, the rats and the ground.
- *Cold open with a victim.* Before the teller frames it, the night opens on someone it's going to go wrong for, seen for a moment.
- *Believer and sceptic in his head.* Two of his voices take the two readings of every strange thing, in every scene it appears. Neither wins. The skeleton already decides that the game never chooses; this is the device that carries it.
- *Jose Chung and Bad Blood are the rumour system.* What happened at the door on Wednesday, told by table 28, the kids, the lifer and the cook, each version different and each sure. A scene built entirely of contradicting accounts is the most X-Files thing we could do, and the system for it already exists.
- *Clyde Bruckman is the teller.* He knows how everyone ends. Give him that sadness, not wisdom.
- *Picture.* Light as a thing in the dark: his torch in the keg room, headlights sweeping the lot, the TV's glow on table 28's faces.
- *Sound.* The cold open's sting. A theme that whistles.

**Don't take.** The government, the aliens and the conspiracy as plot. Our conspiracy theories belong to the people who hold them, and the no-caricatures rule gives each its best voice.

### Andrei Tarkovsky

**What he does.** He called his book *Sculpting in Time*: the rhythm of a film comes from the pressure of time running through each shot, not from the cutting. Long takes. Rain falling indoors, water dripping, objects lying in shallow water, wind moving across grass. In *Stalker* three men cross the Zone towards a room that grants your deepest wish; the guide tests each path by throwing a nut tied in a strip of bandage ahead and following where it falls; the world outside the Zone is sepia and the Zone is in colour. In *Solaris* the ocean makes the people you've lost and sends them to you. In *Mirror* memory and the present run together, a barn burns in the rain, and wind crosses a field towards a woman on a fence. In *Andrei Rublev* a boy who claims to know the secret of casting a bell bluffs his way through casting one, it rings, and then he admits his father never told him. In *Nostalghia* a man carries a lit candle across an empty mineral pool, in one take, starting over each time it goes out. In *The Sacrifice* a man bargains with God to undo a nuclear war and burns his house to keep his word. Eduard Artemyev's scores are made from real sounds worked on a synthesiser until they are half music.

**Where it goes.**
- *The bell is his test shift.* He told Gary he'd worked a door in the city for ten years. The claims system already tracks what he said. Rublev gives it a shape: the bluff that works, and the moment, much later, when he admits to someone (the lifer, the teller's listener) whether it was true.
- *The nut and the bandage are the dice.* A ritual for choosing a path through something you can't read. Write the dice that way: not luck, a way of asking.
- *The flood is our Tarkovsky set piece.* Day 17, the keg room: water across concrete, things floating, the light on it, a scene that is mostly time. In the Godot build, the camera and the column both slow down.
- *Nostalghia's candle is clearing the room.* The closing skill he practises every night, done as a futile task done right. On the last night it saves lives. Write the closing count as a ritual that gets one beat more serious each week.
- *The Sacrifice is "was it helped".* A bargain to undo a catastrophe. The rats' terms, the old man's knowledge, and whether anything the doorman did could have changed the ground. The game keeps it open.
- *Mirror is the teller.* His memory of the month and the present night bleed together: a line of what happened, then a line of how he remembers it, and one of them is wrong.
- *Solaris is the voices.* People from his past, sent back to him in his head. Write the father voice with that weight.
- *Picture.* Sepia outside the Zone, colour in it. The walk through town and the teller's memories print in one or two inks; the Sov gets all five. Rain and water as their own layer of strokes. Wind on the grass by the seawall.
- *Sound.* Artemyev's method is the brief for the score: real recordings (rain, the cooler's compressor, the organ) stretched and slowed until they're half music. Hutch's Hammond on a slow Leslie is ideal for it.

**Don't take.** The length of the takes as they are in the films (a game player who's waiting isn't watching), the religious argument spelled out, and the levitation. One held moment a night, not a whole night of them.

### Daisies (Sedmikrásky), Věra Chytilová, 1966

**What it does.** Two young women, both called Marie, decide that since the world is spoiled they'll be spoiled too. They let old men buy them dinners and then put them on trains; they cut each other up with scissors and float as cut-outs; they crawl into a banquet laid for someone else and destroy it, swinging from the chandelier. The colour changes from scene to scene, through filters, monochrome, collage and tinted stock (Jaroslav Kučera shot it; Ester Krumbachová co-wrote it and designed the look). At the end, punished, they try to put the banquet back together, whispering that they're happy now, and the chandelier falls on them. The film is dedicated to those who get upset only over a trampled lettuce. It was banned for wasting food. It was made two years before the Prague Spring and its end: the last free burst of a world about to close.

**Where it goes.**
- *The kids.* The pillars call the gen Z kids unsocialised and unpredictable. Chytilová shows the other side: play as revolt, wrecking things because it's fun and because the world's already wrecked. The kids get the Maries' energy, and their best voice, never menace for its own sake. The skeleton's young who lose a world that lived in their phones are the Maries after the chandelier.
- *The trampled lettuce.* Table 28 upset about the wrong things while the world ends: a spilled pint, the remote, the curling. That's the dedication, and it's comic and true, never mean.
- *The banquet.* One night the kids get into something laid for someone else (the mill's wake, Gary's private party upstairs, the walk-in) and wreck it with joy. Then the attempt to put it back.
- *End of an era.* 1966 Prague is the end of an empire in another key: the party's last year before the tanks. Use it as a tone, not a reference.
- *Picture.* Late at night and drunk, the print starts misbehaving on purpose: plates swap colour, a frame gets cut into strips and reassembled, a person becomes a flat cut-out for a moment. Today's drink slip is a start. Chytilová gives it rules: it should look like play, not like illness.
- *Sound.* Collage too: a sound from another part of the night cut in for a second, a song from the jukebox played back over the wrong scene.

**Don't take.** The bombing footage at the end, and anything that turns the kids into an allegory. They're people.

---

## Mixing them

These sources don't sit equally in every scene. A rough map:

| In the game | Leads | Under it |
|---|---|---|
| The door, every night | Dick (the scanner and the face), Twilight Zone (economy, the turn) | X-Files (the case) |
| Table 28 and the regulars | Carroll (warm, then the bill) | Goethe (the Tower watching him), Daisies (the lettuce) |
| The kids | Daisies | Dick (they live in the machines that fail) |
| The teller | Chiang (knows the end), Twilight Zone (the frame) | Twin Peaks (talking to Diane), Tarkovsky (Mirror) |
| The rats and the Rat King | Goethe (the wager) | Murakami (the well), Chiang (one rule) |
| The strange: the sky, the ground, the tells | Murakami (calm report), Dick (through junk) | X-Files (two readings) |
| The routines: count, mop, close | Murakami | Tarkovsky (the candle) |
| Set pieces: the flood, the wake, the last night | Tarkovsky (the flood), Goethe (Walpurgis Night), Twilight Zone (Maple Street) | Twin Peaks (the band) |
| The picture | Tarkovsky (sepia and colour), Goethe (colour as feeling) | Daisies (the print at play), Dick (misprints), Twilight Zone (black at the turn) |
| The sound | Tarkovsky and Artemyev (real sounds made music), Twin Peaks (room tone, the theme) | X-Files (the sting) |

## Checking a scene

Before a scene goes in, read it against this:

- [ ] How many "the way", "nobody", "never" and "a little"? One "the way" a scene at most.
- [ ] Does the scene end on a button? Cut back to the last thing that happened.
- [ ] Is there one ordinary object carrying the strange, or the empire's end, unremarked?
- [ ] Is anything explained that could be left open?
- [ ] Cover the name on each line (`10_VOICES.md`). Could it be anyone's?
- [ ] If something strange happens, do two voices read it two ways?
- [ ] Is someone we think is wrong given their best case?
- [ ] Is there a quip? Cut it. Humour is people being funny, never the writing winking.
- [ ] Run `python3 tools/tells.py` on the file. Every "as if", "Not X. Y." or simile tail left in the narration needs a reason.
- [ ] Would any voice's line fit on a mug? Make it a memory, a number, a section of the binder, or a rumour somebody got wrong.
- [ ] Read it aloud. Hutch will be voicing the teller.

## The test

Three Wednesday scenes are revised against this guide in `content/revisions/`, each next to the original: the lot and the building (the first thing anyone reads after Gary's office), table 28's welcome, and close. They're not in the game yet. If Hutch finds them better, the guide becomes DECIDED, the rest of Wednesday gets the same pass, and the guide becomes a skill every session loads before it writes. If not, the guide is wrong and gets fixed first.
