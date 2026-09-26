# Systems

Everything here is **[PROPOSED]** unless marked otherwise. Hutch's requirements are marked [DECIDED] where a system answers one of them.

## The loop

Thirty days, three phases a day. [DECIDED: thirty days; a satisfying, engaging loop is the top requirement]

### Daylight

The room upstairs where he lives, the hangover, the voices arguing over last night. Errands, rent, learning from someone, reading. The empire's news arrives by radio, paper and pamphlet.

- The bar opens early. Whether to take the early shift is mostly the player's call, and taking it costs time he'd otherwise spend preparing for the night. [DECIDED]
- The early shift is table 28's shift: money and time with them, paid for with preparation. [PROPOSED]

### The shift (the core of the game)

1. **The door.** A queue, and each person is a 10- to 30-second read: ID, how drunk they are, who they're with, what they're carrying, whether they're on the 86 list. In, out, or in on conditions. It's paced like Papers, Please, and like Papers, Please, the *player* gets better at it, not just the character. The door decides who's in the room.
2. **The floor.** The room is a live system. Tables have relationships, tension rises with drink and time, and he can only be in one place. Attention is the scarce resource, and whatever he doesn't attend to keeps happening without him. This is the precedence Hutch asked for: things and people take precedence over others. [DECIDED: precedence] Tasks (bathroom checks, kegs, spills, ice) cost attention and hide discoveries. Half the plot is in the bathroom checks.
3. **Incidents.** Fights and crises are a short, high-stakes mode (see Violence).
4. **Closing.** Clearing the room without an incident is a skill of its own. Then the count, the incident log, and after-hours, which is where the best writing will live.

### Night

The voices process the day. Dreams are optional.

### Rhythm

Paydays, Fridays, and Sundays. Table 28 never comes on Sundays [DECIDED], so Sundays are the bar without its anchor, and they make natural chapter breaks [PROPOSED]. The game saves automatically at dawn (see World state).

## Voices and skills

- **Sources.** Voices come from people, books, pamphlets, and memories retold by patrons, including what other people said to them. [DECIDED]
- **Learning is social.** Every skill has a source. Spend time with the old boxer and his voice comes along with his right hook.
- **Fidelity.** Firsthand voices are reliable. A pamphlet voice is a zealot. A retold voice, like a patron's story of what his father's sergeant said, is a copy of a copy: worse on facts, stronger on feeling.
- **Songs.** The jukebox can be a source too.
- **The old can't read the young.** Voices learned from table 28's generation misfire on the kids. Reading the kids takes their voices, which means actually talking to them.

## The room in his head: a relational psyche

He collects many voices, but five are "in the room" at a time. Between five voices there are ten relationships, and each is allied (+) or at odds (−). No voice has a level; only the relationships exist. (It's Hutch's Delta Ontology as a character sheet: relation before substance.)

### The math

Verified by exhaustive enumeration in `tools/psyche_census.py`. The output is in `data/psyche_states.json`.

- There are 2^10 = **1,024** possible configurations of the room.
- Up to relabeling the voices, they fold into **34 states**. That's the same count as graphs on five points: the conflicts are the lines.
- Up to **switching**, one voice reversing all of its loyalties at once (allies become enemies and enemies become allies), the 34 fold into **7 classes**. These are the seven "two-graphs" on five points.
- **Tension** is the fewest conflicts left after any combination of loyalty reversals. Mathematicians call it the frustration index. It runs from 0 to 4.

| Class | States | Share of random rooms | Tension | Mirror class |
|---|---|---|---|---|
| A | 3 | 16 / 1024 (1.6%) | 0 | G |
| B | 6 | 160 / 1024 (15.6%) | 1 | E |
| C | 6 | 240 / 1024 (23.4%) | 2 | D |
| D | 6 | 240 / 1024 (23.4%) | 2 | C |
| E | 6 | 160 / 1024 (15.6%) | 3 | B |
| F | 4 | 192 / 1024 (18.75%) | 3 | F (itself) |
| G | 3 | 16 / 1024 (1.6%) | 4 | A |

"Mirror" means every relationship reversed at once. Classes are ordered by tension and then by spectrum (see the tool).

### Properties the design can rely on (all checked by the tool)

- **One reconciliation or one falling-out always moves tension exactly one step**, up or down. Reversing one voice's loyalties flips four relationships, an even number, so every configuration in a class has the same parity of conflicts, and a single change has to cross a step.
- **One voice reversing all its loyalties never changes tension.** It's a revolution that swaps every alliance and leaves the frustration exactly where it was. In a game descended from Disco, that's the joke and the tragedy at once.
- **Mirrors.** Reversing every relationship pairs A with G, B with E and C with D. Class F maps to itself. Only two of the 34 states are their own mirror: the one where the conflicts form a five-cycle, and the "bull."
- **Tension 0 (class A)** means at most two camps, where the enemy of my enemy is my friend. The math treats it as equivalent to total agreement.

### Mechanics built on it

- **Tension sets volatility, not competence.** A tense psyche rolls wilder: bigger insights and worse failures at the same average. For example, more dice or a wider spread at higher tension.
- **Voices speak out of unresolved tension.** At tension 0 the room goes quiet, because there's nothing unresolved and nothing to say. That's Hutch's Pleroma argument made playable. At tension 4 the room is a riot.
- **The room holds five.** Letting a voice in when it's full means bouncing one out.
- **The 34 states are the deck, our Thought Cabinet.** Each state gets a card: a name, a glyph and a page of writing. The glyph is a pentagon with its inner star, solid lines for allied and broken lines for at odds, like I Ching lines. Rare states are really rare: a random room lands in A or G only 1.6% of the time each.
- **Origin.** Signed-graph balance comes from Fritz Heider's 1946 balance theory about who likes whom, formalized by Cartwright and Harary in 1956. It was invented to describe people.

## Reputation and conscience

No meter. Three layers. [DECIDED: a reputation and good-and-evil system that isn't a simple binary and conditions what's possible]

1. **Codes.** Every group judges by its own:
   - Table 28: loyalty, generosity, we were here first.
   - The kids: don't be fake, don't be a rat.
   - Staff: have each other's backs.
   - The owner: money.
   - The street: respect and debts.
   - The law: keep it quiet.

   One act can be honor to one group and betrayal to another. Standing with each group opens and closes options.
2. **Witnesses and rumor.** An act only counts where someone saw it or heard about it. Stories travel along the bar's relationships and change with each telling: you broke up a fight on day three, and by day seven you broke a man's arm. His reputation is every version of him in circulation. It's the same machinery as the retold voices, so what's said about him and what's said inside him run on one engine.
3. **One hidden measure: whether he lies to himself.** This is Trungpa's cocoon, the familiar patterns you hide in so you don't have to feel the fear. Trungpa's "setting-sun vision," a world run on fear, fits an empire's end. The player never sees the measure. It sets the narrator's tone and limits what he's capable of at the end.

## Haunting

A bad call leaves a presence: a person, an object or a voice that comes back at bad moments. It can't be erased, only carried. Carry it long enough and it turns into something useful. The kid you failed on day six becomes a voice that makes you better at seeing danger, at a cost in tension. He stays implicated and is never absolved, but it never becomes a death spiral. [DECIDED: haunt, but not enough to destroy ambition]

## Money

[DECIDED: money and skill-building in novel ways are a strong part of the game]

- **The currency fails.** As the empire ends, prices climb through the thirty days and savings rot. The last thing that holds value is people: favors, debts, standing.
- **Bar money.** Tips (table 28 tips to own you), the float, short tills, comps, walkouts, and the door bribe you take or don't.
- **The lost-and-found box.** Everything left behind is a story, a lead, or something to sell.

## Violence

The game runs from the very good times to having to step into violence or stop it. [DECIDED]

Most of the job is talking. Fights are fast and ugly, and they cost him legally, in reputation, in his body and in his head. **[OPEN]** Hutch describes how it actually goes (the techniques, how it escalates, the aftermath), and the system gets built around that.

## Other systems

- **The 86 list.** The bouncer's real power and the bar's moral ledger. Bans reshape the room, and banned people come back.
- **The incident log.** He writes it every night, and what he leaves out is a choice with consequences.
- **The body.** Injuries carry over: a broken hand on day nine changes the next two weeks. A drink on shift is always on offer.
- **The past.** Part of it is fixed and discoverable: a scar, a letter, a man who recognizes him in week two. Part of it he invents in conversation. What he invents becomes fact that people hold him to, and they compare notes. [DECIDED: semi-tabula rasa, recalling and inventing who he was and is]
- **The partner.** The head bartender sees everything he does, every night. This is the game's Kim Kitsuragi, and their respect is the hardest thing in the game to earn.

## World state: how every choice changes something

[DECIDED: a very detailed world-state change for every choice]

A branching tree can't do it; the branches multiply out of control. Instead:

- **Storylets**, Failbetter's approach in Fallen London and Sunless Sea. Scenes unlock when conditions are met instead of being wired to branches.
- **Rule-matched lines**, like Valve's dialogue system in Left 4 Dead. Hundreds of short lines, each tied to specific facts about the world, where the most specific match wins.
- **The minimum rule:** every choice changes something someone says later.
- **Design the state model first:**
  - people
  - relationships (signed and weighted)
  - rumors (versions and who carries them)
  - voices (source, fidelity, in the room or not)
  - money
  - the 86 list
  - the rats
  - the body
  - the calendar

  All of it saves to plain JSON.
- **One save slot**, saved automatically at dawn. If you can reload, nothing haunts.
