# Wednesday: three scenes, before and after the style guide

*18 November 2026. The test for `bible/13_STYLE.md`. Nothing here is in the game yet. Each scene is the original Ink, then a revision against the guide, then what changed and why. Every fact, choice, variable and tag the original carries is kept, so a revision can be dropped into the `.ink` file as it stands. Anything new to the world is marked PROPOSED.*

Read the before and after of each and say which is better and why. If the after isn't better, the guide is wrong, not you.

---

## 1. The lot and the building (`prologue.ink`, `prologue` and the start of `inside`)

The first thing anyone reads after Gary's office.

### Before

```ink
=== prologue ===
~ here = lot
# amb: rain_lot
{
- knows ? sov_watched:
    He crossed the highway with the rain coming down hard enough to bounce on the gravel, and walked up the lot between the trucks.
- from_room:
    The rain had come back across the strait with the last ferry. It hit the gravel lot hard enough to bounce.
- else:
    NARRATOR: He started on a Wednesday. The Sov tried out doormen on Wednesdays, on a night slow enough that a mistake would only hurt a little.
    NARRATOR: Of the thirty days, it was the one nobody else remembered.
    The rain had come across the strait with the last ferry and hadn't let up. It hit the gravel lot hard enough to bounce.
}
{ not (knows ? sov_watched):
    On the roof the sign said SOVEREIGN in red neon with the second E dead. Under it, HOTEL, all five letters working.
    Three storeys of old wood, painted a red that had faded to the colour of brick. The cold beer and wine store at one end with its lights on. Trucks parked nose-in along the front, wipers stopped where they'd been switched off. The highway behind him, and past the highway, the water.
}
{ knows ? sov_watched:
    FATHER: Two hours and a half. It's told you all it's going to from out there.
- else:
    FATHER: Look at a building before you go into it. It'll tell you what kind of night it has.
}
It told him Wednesday. #pause

= inside
He went in.
Beer, cleaner, piss, old wood and dust. The carpet had had a pattern once. By the bar rail it gave a little under his boots, where thirty years of spills had soaked through to the underlay.
A woman behind the bar was cutting limes. She looked at him, looked at the size of him, and went back to the limes. #portrait: bartender
```

### After

```ink
=== prologue ===
~ here = lot
# amb: rain_lot
{
- knows ? sov_watched:
    He crossed the highway and walked up the lot between the trucks. The rain was coming down hard enough to bounce on the gravel.
- from_room:
    The rain had come back across the strait with the last ferry. It bounced on the gravel.
- else:
    NARRATOR: He started on a Wednesday. The Sov tried out doormen on Wednesdays, on a night slow enough that a mistake would only hurt a little.
    The rain had come across the strait with the last ferry and hadn't let up. It bounced on the gravel.
}
NARRATOR: Four weeks from that night, to the hour, the ground moved, and he was standing at that door when it did.
{ not (knows ? sov_watched):
    On the roof the sign said SOVEREIGN in red neon with the second E dead, buzzing loud enough to hear over the rain. Under it, HOTEL, all five letters working.
    Three storeys of old wood, painted a red gone the colour of brick. The cold beer and wine store at one end, lit, with a sheet of paper taped inside the glass: DEBIT DOWN. CASH ONLY. There were marks round it from old tape, other times.
    Trucks parked nose-in along the front, their wipers stopped wherever they'd been switched off. The highway behind him, and past the highway, the water.
}
While he stood there the dead E came on, held for about a second, and went out. He waited. It didn't do it again.
{ knows ? sov_watched:
    FATHER: Two hours and a half. It's told you all it's going to from out there.
- else:
    FATHER: Look at a building before you go into it. It'll tell you what kind of night it has.
}
FATHER: Old wiring. Every bar on this coast is held up with tape and old wiring.
WRONGMAN: The man who told it said the lights went first. Before anything else.

= inside
He went in.
Beer, cleaner, piss, old wood and dust. The carpet had had a pattern once. By the bar rail it gave under his boots, where thirty years of spills had soaked through to the underlay. On the back bar the clean glasses stood upside down on a towel, in rows.
A woman behind the bar was cutting limes. She looked at him, looked at the size of him, and went back to the limes. #portrait: bartender
```

### What changed

- **The teller frames the night, cold, and says what's coming** (rules 5; Chiang's "Story of Your Life", Serling's frame). On every route, not only the one without Gary's office. "Four weeks from that night, to the hour" is canon: day 29, during his shift, at the door. The line stands alone: an earlier draft added "He didn't know that. He thought it was a job.", and the review below caught it as the same two-beat turn the close ends on, so it went.
- **"The one nobody else remembered" is gone from here.** It's the same thought the close ends on, and saying it twice in one night spends it. It stays at the close (scene 3).
- **The empire's end in junk** (Dick): DEBIT DOWN, CASH ONLY in the beer store window, with old tape marks round it, so it's happened before. Nobody remarks on it. It sets up the bartender's "Network's down, third time this week" in `bar.ink`.
- **One strange thing, reported flat** (Murakami): the dead E comes on for a second. No voice gasps, nothing is explained.
- **Two readings** (The X-Files): the father says old wiring; the wrong man, whose voice comes from retold stories, says the lights went first. Neither wins. The father seeing mist and willows is Goethe's Erl-King.
- **Electricity is present from the first minute** (Twin Peaks): the neon buzzes over the rain. Power is what fails on day 29.
- **The glasses on the back bar** are planted in rows, upside down, so that when they ring later in the month the reader has already seen them.
- **The button is cut:** "It told him Wednesday." was a good line doing a button's job, closing the scene with a wink. The scene now ends on the voices, and he goes in.
- **New to the world (PROPOSED):** the sign in the beer store, the E coming on, the glasses on the towel.

---

## 2. Table 28's welcome (`table28.ink`, `first` and `where_from`)

The HUTCH prompt here stays where it is: what table 28 actually talk about, and each man's quirk from life, are yours. This revision is a draft for you to cut, and shows what the guide does to the register, not what they'd really say.

### Before

```ink
= first
{dennis_gone():Four|Five} faces turned up at him at once, like a jury.
// HUTCH: Table 28 is yours. ...
TABLE28: Here he is!
TABLE28: Look at the size of him!
{ shirt_on:
    TEAM_JACKET: It says SECURITY on him, boys. In case we were wondering what he was.
    TABLE28: Security!
    HEARING_AID: Security.
    ~ rep(rep_t28, -1)
}
TEAM_JACKET: They're getting bigger, the doormen. The last one was a big lad too, and a lot of good it did him.
HEARING_AID: Him.
TABLE28: Where'd they dig you up?
-> where_from

= where_from
* ["Up island."]
    ~ claims += said_up_island
    TABLE28: Up island!
    They said it like it explained a great deal, none of it good.
    SCRATCH: Everybody's from up island, kid. I'd have bet on it.
    ~ rep(rep_t28, 1)
* ["I worked a door in the city. Ten years."]
    ~ claims += said_city_door
    ~ rats_heard += h_city
    TABLE28: Which one?
    * * ["You wouldn't know it."]
        ~ claims += said_city_unnamed
        TEAM_JACKET: Try us. We've drunk everywhere.
        He didn't. They filed that away. Table 28 filed everything away.
    * * ["The kind with a line outside."]
        ~ claims += said_city_line
        TABLE28: Oooh.
        CARDIGAN: Ten years is a long time to stand outside a building.
        FATHER: They'll hold you to that, you know. Ten years. Somebody here knows somebody in the city.
    - - ~ rep(rep_t28, 1)
* ["Around."]
    ~ claims += said_around
    TABLE28: Around!
    TEAM_JACKET: He's from Around. I've been to Around. Terrible place.
    They laughed together, on the beat, the way a family laughs.
* ["My father worked doors."]
    ~ claims += said_father
    ~ rats_heard += h_father
    FATHER: Don't.
    TABLE28: Ah.
    It changed them, a little. Something went round the table.
    CARDIGAN: Here? On the island, I mean.
```

### After

```ink
= first
{dennis_gone():Four|Five} faces turned up at him at once. They'd been arguing about diesel and didn't stop all the way.
// HUTCH: Table 28 is yours. ...
TABLE28: Here he is!
TABLE28: Look at the size of him!
{ shirt_on:
    TEAM_JACKET: It says SECURITY on him, boys. In case we were wondering what he was.
    TABLE28: Security!
    HEARING_AID: Security.
    ~ rep(rep_t28, -1)
}
TEAM_JACKET: They're getting bigger, the doormen. The last one was a big lad too, and a lot of good it did him.
HEARING_AID: Him.
TABLE28: Where'd they dig you up?
-> where_from

= where_from
* ["Up island."]
    ~ claims += said_up_island
    TABLE28: Up island!
    TEAM_JACKET: I had a cousin up island. Drowned. Lovely fella.
    TABLE28: To the cousin!
    They drank to him, all {dennis_gone():four|five}, and went back to the diesel.
    SCRATCH: Everybody's from up island, kid. I'd have bet on it.
    ~ rep(rep_t28, 1)
* ["I worked a door in the city. Ten years."]
    ~ claims += said_city_door
    ~ rats_heard += h_city
    TABLE28: Which one?
    * * ["You wouldn't know it."]
        ~ claims += said_city_unnamed
        TEAM_JACKET: Try us. We've drunk everywhere.
        He didn't. The one in the cardigan wrote something on a coaster and put it in his shirt pocket.
    * * ["The kind with a line outside."]
        ~ claims += said_city_line
        TABLE28: Oooh.
        CARDIGAN: Ten years is a long time to stand outside a building.
        FATHER: They'll hold you to that. Ten years. Somebody here knows somebody in the city.
    - - ~ rep(rep_t28, 1)
* ["Around."]
    ~ claims += said_around
    TABLE28: Around!
    TEAM_JACKET: He's from Around. I've been to Around. Terrible place. They charge you for the ketchup.
    TABLE28: For the ketchup!
    All of them laughed on the same beat, except the one with the hearing aid, who laughed a beat late and at something else.
* ["My father worked doors."]
    ~ claims += said_father
    ~ rats_heard += h_father
    FATHER: Don't.
    TABLE28: Ah.
    Something went round the table. The one in the team jacket put his glass down.
    CARDIGAN: Here? On the island, I mean.
```

### What changed

- **Warm first** (Carroll): the cousin who drowned and the toast to him, the ketchup joke that goes one line too long, a table you'd like to drink with. Funny the way people are, not the way writing is. The pillars' "very good times" start here, and in week four this warmth is what it costs.
- **They're watching him** (Goethe's Tower in *Wilhelm Meister*): "They filed that away. Table 28 filed everything away." told us. Now the one in the cardigan writes something on a coaster and pockets it, which shows it and leaves it open. PROPOSED: the coaster turns up later, the table's file on him, and is one way the apprenticeship gets its certificate.
- **The empire in the talk** (Dick): they're arguing about the price of diesel and don't stop, which `inside` already set up.
- **Similes and buttons cut:** "like a jury", "They said it like it explained a great deal, none of it good", "the way a family laughs", "It changed them, a little". Each told us what to feel about a moment. The revisions show a thing (a glass put down, a man laughing late) and stop.
- **The hearing aid's quirk** works harder: he laughs late and at something else. It's a placeholder for the real quirk you'll give him.
- **New to the world (PROPOSED):** the drowned cousin, the ketchup, the coaster. All yours to cut.

---

## 3. Close (`closing.ink`, `lock_up` and the start of `ledger`)

### Before

```ink
=== lock_up ===
~ here = door
~ pass(5 + lock_extra())
He locked the front door behind the last of them and turned the sign over. #sfx: door
# amb: empty_bar
...
BARTENDER: Anybody get past you, Door?
{ uncounted > 0:
    He didn't have to answer. She'd rung in drinks tonight for {uncounted == 1:a face|faces} that never came past the stool, and she'd known it at the time.
    BARTENDER: So go find out how. I'll be counting.
    -> search
}
Nobody had. She'd been watching the door herself all night, between drinks, and she knew it as well as he did.
She didn't say anything, which from her was a lot.
~ rep(rep_staff, 1)
-> incident_log

=== ledger ===
~ here = upstairs
# plate: lot
{
- cocoon >= 3:
    NARRATOR: That was Wednesday. The way he tells it now, nothing much happened.
- cocoon <= -1:
    NARRATOR: That was Wednesday. The one nobody else remembers. He remembers all of it.
- else:
    NARRATOR: That was Wednesday. The one nobody else remembers.
}
# screen: ledger
```

### After

```ink
=== lock_up ===
~ here = door
~ pass(5 + lock_extra())
He locked the front door behind the last of them and turned the sign over. #sfx: door
# amb: empty_bar
The coolers. The rain on the glass. Behind the bar she was putting the clean glasses back in rows on the towel, upside down, one at a time. #pause
...
BARTENDER: Anybody get past you, Door?
{ uncounted > 0:
    He didn't have to answer. She'd rung in drinks tonight for {uncounted == 1:a face|faces} that never came past the stool, and she'd known it at the time.
    BARTENDER: So go find out how. I'll be counting.
    -> search
}
Nobody had. She'd watched the door herself all night, between drinks.
She looked at him for a moment, and went back to the glasses.
~ rep(rep_staff, 1)
-> incident_log

=== ledger ===
~ here = upstairs
# plate: lot
{
- cocoon >= 3:
    NARRATOR: That was Wednesday. When he tells it now, nothing much happened.
- cocoon <= -1:
    NARRATOR: That was Wednesday. Everyone else had forgotten it by Friday. He kept all of it.
- else:
    NARRATOR: That was Wednesday. Everyone else had forgotten it by Friday.
}
NARRATOR: He thought he had a month. He had four weeks, to the night.
# screen: ledger
```

### What changed

- **A held moment** (Twin Peaks, Tarkovsky): the door locked, and then nothing chosen and nothing said, only the coolers, the rain and her putting the glasses back one at a time. `#pause` holds it in both builds. It's the first quiet in the night, and it's earned.
- **The routine, written with care** (Murakami): the glasses back on the towel, closing the image from the first scene. Same glasses, so if they ring later in the month, they're ours.
- **The button is cut:** "She didn't say anything, which from her was a lot." was a wry line telling us what her silence meant. Now she looks at him and goes back to work. The reader can read her.
- **The teller closes the night and points forward** (Serling's close, Chiang's knowing teller): "He thought he had a month. He had four weeks, to the night." The night ends on what's coming, not on a summary of what went.
- **"Nobody" and "the way" are gone from the teller's lines** without losing what they meant: what he told himself (cocoon) still decides how he tells it.
- **New to the world (PROPOSED):** nothing. It's all from the night.

---

## Counts

| | "the way" | "nobody" | Teller's lines | Scene-ending buttons |
|---|---|---|---|---|
| Before (the three scenes) | 2 | 4 | 5 | 5 |
| After | 0 | 1 | 6 | 0 |

Teller's lines count every branch as written; coming from Gary's office, a player heard one of them before, and hears three after.

## Checked for machine habits

Run through the anti-ai-writing review (strict mode) on 18 November, on the three "After" blocks (803 words of story). Verdict: **passes with flags.** No banned words, no dashes. Four structural flags, one fixed:

- **Fixed.** The same two-beat turn three times ("He waited. It didn't do it again." / "He didn't know that. He thought it was a job." / "He thought he had a month. He had four weeks, to the night."). The middle one is cut; the close keeps the strongest.
- **Kept, on purpose.** Feeling shown by a body instead of named ("The one in the team jacket put his glass down", "She looked at him for a moment"). The review prefers named feelings; for this game the guide wants the reader to read people, so these stay. Hutch's call.
- **Kept, on purpose.** Opening on the rain and the gravel, and the held moment at close. The review calls these atmospheric; here they're the place and the one quiet beat the guide asks for.
- **Noted.** Nothing escalates across the three. That's Wednesday's job (a slow night), but it's the habit to watch when Friday is written: a machine's nights all sit at one volume.
