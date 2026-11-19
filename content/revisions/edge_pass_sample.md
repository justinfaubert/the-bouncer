# The edge: two scenes, before and after

*19 November 2026. The first test of the edge Hutch asked for: "the world should be dreamlike and serious but there is a strange lack of adult oriented dialogue, situations, characters... It all needs a lot more edge. The right amount." Nothing here is in the game yet. Each scene is the Ink as it stands, then a rewrite, then what changed. The rewrite keeps every fact, choice, variable and tag the original carries, so it can be dropped into `hall.ink` as it stands. Anything new to the world is marked PROPOSED. The plan this belongs to is the doc "Last Call: pace, length and edge" (https://claude.ai/artifact/GEV8TQd4D2P4TTUYg8Q8Sz).*

Say whether it's too far, not far enough, or right. The rest of Wednesday gets written to whatever dial you set here.

The line I hold, so you know what you'd write yourself: nothing sexual involving minors; sex itself happens off the page; sexual violence is never written for heat; slurs only in characters' mouths when the scene is about them and the room answers. Everything else is mine to write.

---

## 1. The payphone wall (`hall.ink`, `= payphone`)

The wall around the dead payphone in the back hall. Hutch's question is still in the file: what's written on the wall around a dead payphone in a bar like his? His real walls will beat these. This is a stand-in until he answers.

### Before

```ink
= payphone
~ pass(3)
~ knows += aa_wall
// HUTCH: What's written on the wall around a dead payphone in a bar like yours?
The payphone had been dead since before anyone stopped needing it. The wall around it was covered in ink: phone numbers with names, phone numbers without names, a cab company that had closed years ago, TRUCK FOR SALE, a heart with two sets of initials, and a third set scratched in later and scratched out again.
High up, where you'd have to reach, in faded marker: TUESDAYS 7 PM. UNITED CHURCH HALL. YOU ARE NOT THE ONLY ONE.
FATHER: I went to those.
FATHER: For a year. Then I stopped going and kept on not drinking, and everybody said that was worse. They were probably right.
It was more than his father had said about it in the whole of his life.
* [Pick up the receiver.]
    ~ picked_receiver = true
    Nothing. Not even the hum. He held it to his ear anyway, longer than there was any reason to, and then he put it back.
// The Father has something to say about the wall at night, if he left the phone alone (closing.ink).
* (left_receiver) [Leave it.]
- -> h_opts
```

### After

```ink
= payphone
~ pass(3)
~ knows += aa_wall
// HUTCH: What's written on the wall around a dead payphone in a bar like yours? (Stand-ins below until you answer.)
The payphone had been dead since before anyone stopped needing it. The wall around it had kept on talking.
FOR A GOOD TIME CALL SHELLEY, and a number, and under it in another pen, SHE'S NOT THAT GOOD, and under that, in the first pen again, FUCK YOU DARREN.
KYLE B IS A NARC ran down the door frame in letters an inch high, gone over so many times the marker had soaked into the wood.
Somebody had drawn a cock and balls with real care, shading and all, and somebody else had given it a little top hat.
A cab company that had closed years ago. TRUCK FOR SALE, RUNS, NO TIRE KICKERS. KAYLA M IS A SLUT, and under it in purple gel pen, KAYLA M HAS A JOB AND A CAR. WHAT DO YOU HAVE. A heart with two sets of initials, and a third set scratched in later and scratched out again with a key.
OTTAWA DOESN'T KNOW WE EXIST. Under it: OTTAWA DOESN'T KNOW OTTAWA EXISTS.
RIP TYLER. Under it: HE OWED ME 20. Under that, in a third hand: KEEP IT.
JUNIOR'S DAD WAS A BETTER MAN.
WHO'S STILL HERE AT 2 AM, in pencil. Under it: ME. ME. ALWAYS. An arrow ran from ALWAYS up the wall to a card in a plastic sleeve, pinned higher than a drunk could reach, the marker gone brown: TUESDAYS 7 PM. UNITED CHURCH HALL. YOU ARE NOT THE ONLY ONE.
FATHER: I went to those.
FATHER: For a year. Then I stopped going and kept on not drinking, and everybody said that was worse. They were probably right.
It was more than his father had said about it in the whole of his life.
* [Pick up the receiver.]
    ~ picked_receiver = true
    Nothing. Not even the hum. He held it to his ear anyway, longer than there was any reason to, and then he put it back.
// The Father has something to say about the wall at night, if he left the phone alone (closing.ink).
* (left_receiver) [Leave it.]
// PROPOSED: a third way, with his hands. What he writes is kept, and on his next shift somebody has
// written under it (the town writes back; Dark Souls' messages, offline). Needs wall_wrote in main.ink.
* (wrote_wall) [Take the binder's pen and write under ALWAYS.]
    He wrote it small, under the three of them.
    ** [ME TOO.]
        ~ wall_wrote = 1
    ** [GO HOME.]
        ~ wall_wrote = 2
    ** [DOOR'S ON TILL 2.]
        ~ wall_wrote = 3
    -- WRONGMAN: In the story somebody answered. Somebody always answers.
    // PROPOSED, his next shift: ME TOO gets an arrow and a phone number. GO HOME gets YOU FIRST.
    // DOOR'S ON TILL 2 gets NOT ON TUESDAYS IT ISN'T, in the hand that pinned up the card.
- -> h_opts
```

### What changed

- **The wall is a conversation now, the way bar walls are.** Every line has an answer under it in another pen: a joke, an insult, a correction. That's the town talking to itself, which is what a wall like this is for.
- **The ugly stays and gets answered.** KAYLA M IS A SLUT is what's on a real wall; the purple gel pen under it is the room's answer. Kayla Moffat is the older sister whose licence is the commonest fake in town (the skeleton), so it ties in.
- **Gary turns up without being named.** The player heard Gary's dead father call him Junior in the office that afternoon; JUNIOR'S DAD WAS A BETTER MAN says the town agrees with the father.
- **The empire, in one joke.** OTTAWA DOESN'T KNOW WE EXIST is the outpost, said the way people here would say it.
- **The AA card keeps its job and gains a frame.** WHO'S STILL HERE AT 2 AM and its arrow point the reader up to it, so the Father's lines land harder.
- **New, PROPOSED:** he can write on the wall, and the next night it's answered. A small thing that makes the place feel lived in by people who aren't him.

---

## 2. The men's room (`hall.ink`, `= mens` and `= vape_line`)

The bathroom check, five visits deep, and the boyfriend with the vape.

### Before

```ink
= mens
~ pass(3)
{ vape_in_mens():
    -> vape_line
}
{ stopping:
- The men's was a trough urinal from when the hotel was built, and two stalls, one without a door. Empty. Somebody had written a phone number on the condom machine and somebody else had scratched it out with a key.
- The one from table 28 with the hearing aid was at the trough, taking his time. He nodded to the doorman in the mirror the way you nod to a man on a ferry.
- A man he'd let in earlier was asleep sitting up in the stall with no door, jeans up, fine. He woke him. The man said "Yep," and went back out to the bar as if he'd been sent for.
- Empty. The floor wet. The hand dryer had been broken so long that somebody had wired a roll of paper towel to it.
- Empty.
}
-> h_opts

= vape_line
The stall with no door. The boyfriend, the one with the vape, with his phone flat on the lid of the toilet tank and a rolled-up bill in his hand. He looked up. He didn't stop.
VAPE: bro
VAPE: my guy it's not even MINE. i'm holding it for somebody
~ incident += inc_drugs
FIGHTER: He's the one who'll swing. Now he'll swing harder.
MANUAL: The licensee must not permit the use of illicit drugs on the premises. Remove the person. Record the incident.
* [Put him out. Now.]
    (unchanged, see hall.ink)
* [Take it off him and flush it.]
    ~ pass(2)
    ~ heat(1)
    ~ rep(rep_kids, 1)
    He held his hand out. The boyfriend looked at it for a long time and then put the little bag in it, and the doorman dropped it in the bowl and flushed, and they both watched it go.
    VAPE: that was SIXTY bucks
    VAPE: bro. that was sixty bucks. you owe me sixty bucks
    FATHER: Now he's broke and angry instead of high and angry. That's your call. It's not a good one or a bad one. It's just yours.
* ["Not in here. Not tonight." Walk away.]
    (unchanged)
* [Say nothing and walk out.]
    (unchanged)
- -> h_opts
```

### After

```ink
= mens
~ pass(3)
{ vape_in_mens():
    -> vape_line
}
{ stopping:
- The men's was a steel trough from when the hotel was built, a pink cake in the drain older than some of the staff, and two stalls, one without a door. Empty. The mirror on the condom machine had been punched into a spiderweb, and somebody had written on the machine, in careful capitals: THIS GUM TASTES FUNNY.
- The one from table 28 with the hearing aid was at the trough, taking his time. He nodded to the doorman in the mirror the way you nod to a man on a ferry. "Prostate," he told the wall. "Don't get old."
- A man he'd let in earlier was asleep on the seat in the stall with no door, jeans round his boots, his phone still lit in his hand on a dating app, his thumb on some woman's face. He woke him. The man said "Yep," stood up, hiked his jeans and went back out to the bar as if he'd been sent for.
- Empty. The floor wet, and not with water. The hand dryer had been broken so long that somebody had wired a roll of paper towel to it. On the dryer, in marker: PUSH BUTTON FOR A MESSAGE FROM THE PRIME MINISTER.
- Empty. On the inside of the stall door, at sitting height, in pencil: THE MILL ISN'T CLOSING. Under it, in ballpoint: READ THE NOTICE. Under that: CAN'T READ. WORK AT THE MILL.
}
-> h_opts

= vape_line
The stall with no door. The boyfriend, the one with the vape, bent over the toilet tank with his phone flat on the lid, a line chopped out on the screen and a rolled-up twenty in his hand, the plastic kind that never stays rolled. He looked up. He didn't stop.
VAPE: bro
VAPE: bro. knock
VAPE: it's not even MINE. i'm holding it for a guy
VAPE: you want one? it's actually good. like actually
~ incident += inc_drugs
FIGHTER: He's the one who'll swing. Now he'll swing harder.
MANUAL: The licensee must not permit the use of illicit drugs on the premises. Remove the person. Record the incident.
* [Put him out. Now.]
    (unchanged, see hall.ink)
* [Take it off him and flush it.]
    ~ pass(2)
    ~ heat(1)
    ~ rep(rep_kids, 1)
    He held his hand out. The boyfriend looked at it for a long time and then put the little bag in it, and the doorman dropped it in the bowl and flushed, and they both watched it go round.
    VAPE: that was SIXTY bucks
    VAPE: bro. that was sixty fucking bucks. you owe me sixty bucks
    FATHER: Now he's broke and angry instead of high and angry. That's your call. It's not a good one or a bad one. It's just yours.
// PROPOSED: the offer, taken. The skeleton's temptation (a line in the office downstairs) arriving early
// and small. Needs a third clock beside the drink clocks (skeleton, Drink), here called high.
* [Take one.]
    ~ pass(1)
    ~ heat(1)
    ~ high += 1
    ~ rep(rep_kids, 2)
    He bent and took it off the phone screen. The boyfriend laughed and slapped him on the back and said "my GUY," and for about a minute the hall outside was the best hall he'd ever stood in.
    MANUAL: A security worker impaired on shift loses his licence. Not the night. The licence.
    FATHER: I know that feeling. It's the one that tells you you've got this.
* ["Not in here. Not tonight." Walk away.]
    (unchanged)
* [Say nothing and walk out.]
    (unchanged)
- -> h_opts
```

### What changed

- **The room smells and gets used.** The pink cake, the wet floor that isn't water, a man asleep with his jeans round his boots and a dating app lit in his hand. Before, the men's room was described from the doorway; now it's stood in.
- **Every visit has a joke on it, and the jokes are the town's.** THIS GUM TASTES FUNNY and the Prime Minister on the hand dryer are two of the oldest jokes on washroom walls anywhere, which is the point: this is a room where the same jokes have been written for fifty years. The mill line on the stall door is the town's denial, argued in three pens.
- **Table 28 gets a body.** "Prostate. Don't get old." is the first thing the hearing-aid man says to him, and it's funnier and sadder than the nod alone.
- **The drugs are on the page.** The line chopped out on a phone screen, the polymer twenty that won't stay rolled, the offer. The boyfriend swears like a twenty-year-old.
- **New, PROPOSED:** he can take one. It pays with the kids, costs a clock, and both his voices answer: the Manual with what it costs on paper and the Father with what it costs.
