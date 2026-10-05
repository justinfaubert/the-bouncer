// The rats. The owner's note says deal with it. The cook wants them dead, table 28 feeds one,
// the bartender wants a quiet night, and the old man at the end of the bar talks about terms.
//
// Hutch's rules (DECIDED): ignored, they double. He can parley with the Rat King at points
// through the game, until the colony gets too big or he decides to exterminate them, which
// costs him in other ways. The Rat King is both the knot of rats in the wall behind table 28
// and a man who seems to speak for it.
//
// Wednesday: bait or traps start a war (rats = war). The first parley is after close
// (closing.ink). Small courtesies count toward terms (rat_favour); kills count against
// (rats_killed). Still undecided at dawn means ignored, and the count doubles.
//
// The bait and the traps are in the office, which is in the keg room (Hutch, 27 Sept). Laying them
// down there costs nothing but the war; carrying them up through the trapdoor behind the bar means
// carrying them past her (carry_up).

=== function cook_here()
~ return clock < 1380

=== function go_to_war()
{ rats == undecided || rats == ignored:
    ~ rats = war
}


// ------------------------------------------------------------------ the kitchen

=== at_kitchen ===
~ here = kitchen
{ due(): -> hub }
{ not cook_here(): -> dark }
{ at_kitchen == 1:
    He pushed through the swing door at the end of the bar, and the heat met him in the doorway like a hand on his chest.
    A fryer, a flat-top, a steel prep table, the walk-in humming at the back. {kitchen_door:The back door to the alley was propped open with a milk crate, and the steam went out through it and the rain came in.|The back door to the alley was shut, and the kitchen was hotter for it.}
    The cook was a man about forty in a t-shirt soaked dark down the back, shaking a basket of wings over the fryer. Wednesday was wing night. He'd made a hundred and sold thirty. #portrait: cook
    // HUTCH: The cook. What's a pub kitchen like on a Wednesday where you've worked? The menu, the heat, what the cook complains about, what he says to a new doorman standing in his kitchen.
    COOK: Security, eh? Behind you. Behind!
    COOK: Don't lean on anything. It's all hot or it's all wet, and that flat-top's a bastard, it'll have your hand off.
- else:
    {shuffle:
    - The heat met him in the doorway again.
    - The kitchen. The fryer, the cook, the heat.
    - The cook looked up, saw who it was, and went back to the wings.
    }
}
{ reprops ? rp_kitchen && kitchen_door:
    ~ reprops -= rp_kitchen
    The milk crate was back in the alley door. The cook didn't look at him about it, which was looking at him about it.
}
-> k_opts

= k_opts
{ due(): -> hub }
{ not cook_here(): -> dark }
<- moves(kitchen)
* ["The owner wants the rats dealt with."]
    -> cook_rats
* [Look behind the walk-in. #check: manual 7]
    -> behind_walkin
+ {fries == 0} [Take the fries going soft under the heat lamp.]
    -> take_fries
* [Take the garbage out for him.]
    -> garbage
+ {kitchen_door} [Take the milk crate out of the back door.]
    ~ pass(2)
    -> kitchen_door_shut ->
    -> k_opts

= cook_rats
~ pass(4)
~ knows += kitchen_gap
~ knows += keg_hole
The cook didn't stop working to answer. He didn't stop working for anything.
COOK: Dealt with. Dealt with! Sure.
COOK: Pipe chase behind the walk-in, up from the keg room. Every morning, droppings on my prep table, every morning I'm bleaching the son of a bitch before I've had a coffee.
COOK: Inspector finds one dropping, he shuts the kitchen. Kitchen's shut, I don't get paid, and I've got a, never mind. So yeah. Dealt with would be nice.
// HUTCH: How does a bar really deal with rats? Who gets called, what gets put down, what the inspector looks for, and what the staff do in the meantime.
- (cr)
* ["So why hasn't anybody?"]
    ~ knows += bait_office
    COOK: Bucket of bait in the office, downstairs, past the kegs. Owner bought it in the summer. Box of traps right beside it, still in the plastic.
    COOK: She won't let anybody put it down. Something about table 28 and their goddamn pet.
    He tipped the wings into a bowl and rang the bell on the pass.
    COOK: I'm not getting into it with table 28. I work here. Some of us work here.
    -> cr
* ["How many are there?"]
    ~ knows += rat_numbers
    COOK: You see one, there's fifty. Me? I've seen a lot more than one, Security.
    MANUAL: A single sighting indicates an established population.
    -> cr
* ["What would you do?"]
    ~ knows += cook_advice
    COOK: Bait. Keg room, where they live. They eat it, they crawl in the walls and die, it stinks for a week, done.
    COOK: Traps are for people who want to feel useful. You'll catch three.
    FATHER: He's not wrong. A week of stink in a bar is a week of nobody coming in.
    -> cr
* {knows ? t28_rat} ["Table 28 feeds one."]
    ~ knows += cook_fries
    COOK: I know they do. Who do you think fries the fries?
    COOK: An extra basket, Wednesdays. Don't tell her.
    COOK: I don't care what they feed. I care what's on my prep table at seven in the morning.
    -> cr
+ [Leave him to it.]
    -> k_opts

= behind_walkin
~ pass(4)
He got down on one knee beside the walk-in, where the compressor blew warm air along the floor.
{ passed:
    MANUAL: Evidence of rodent activity. Droppings, fresh, concentrated along the wall. Gnaw marks at the base of the door frame. Grease marks at the pipe penetration. The pipe penetration is not sealed.
    There was a gap where the pipes went down through the floor, the edge of it rubbed dark and smooth by bodies going through. Warm air came up out of it, and the smell of the keg room.
    ~ knows += keg_hole
    MANUAL: Seal all penetrations. Remove food sources. Then bait.
    FATHER: Remove food sources. In a kitchen.
- else:
    It was dark back there and the compressor was loud. He saw droppings, and then more of them, and then he stopped counting.
}
{ cook_here():
    COOK: Don't touch anything back there! That compressor's held together with tape.
}
-> k_opts

= take_fries
~ pass(1)
~ fries = 1
He took the basket of fries that had been going soft under the heat lamp since seven.
COOK: Take 'em, take 'em. Nobody's eating those.
{ knows ? t28_rat:
    COOK: Table 28'll want 'em for the rat.
}
-> k_opts

= garbage
~ pass(8)
~ rep(rep_cook, 1)
He took the two bags from beside the dish pit out the back door into the alley. {not kitchen_door:He had to hold the door with his foot to get them through.}
The dumpster was twenty feet up the alley under a light that buzzed. When he lifted the lid, the rats on top of the bags didn't run. They looked at him. Eight or nine of them, and more at the back in the dark, where he could hear them and not see them.
He put the bags in on top of them. They moved just enough to let the bags down.
FIGHTER: They're not scared of you.
MANUAL: Harbourage outside the premises. Keep dumpster lids closed.
The lid had been propped open with a brick.
// Somebody props it every night (closing.ink: the old man says who, if he's asked down).
* (brick_out) [Take the brick out.]
    He took the brick out and let the lid down.
* [Leave the brick where it is.]
    // Whoever propped it was feeding them. Leaving it is a courtesy, and somebody down there counts those.
    ~ rat_favour++
    He left it. Somebody had put it there on purpose, and it wasn't the cook.
- { cook_here():
    The cook was on the back step when he came in, smoking in the rain with his apron on.
    COOK: Thanks, Security.
    It sounded like he didn't say it much.
}
-> k_opts

= dark
~ here = kitchen
{ at_kitchen.dark == 1:
    The kitchen was dark. The cook had cleaned down and gone home. The fryer ticked as it cooled, and the only light was the little green one on the walk-in.
    { kitchen_door:
        The back door was still propped with the milk crate. The cook had gone out that way and left it the way he'd found it.
        FATHER: That's how everybody leaves a door. The way they found it.
    }
}
- (d_opts)
{ due(): -> hub }
<- moves(kitchen)
+ {kitchen_door} [Take the milk crate out and lock the back door.]
    ~ pass(1)
    ~ kitchen_door = false
    The door swung shut and he checked it twice. Out in the alley something knocked over a can.
    -> d_opts
+ {fries == 0} [Take the fries left under the dead heat lamp.]
    ~ pass(1)
    ~ fries = 1
    The fries were cold. They'd do.
    -> d_opts


// ------------------------------------------------------------------ the keg room

=== at_keg ===
~ here = keg
{ due(): -> called_up }
# amb: keg_room
{ at_keg == 1:
    He lifted the trapdoor behind the bar. The bartender stepped around the hole without looking down, the way you step around a sleeping dog.
    BARTENDER: Third step.
    The third step was soft. So was the fourth.
    A stone foundation, sweating. Kegs on pallets in two rows, the beer lines going up through the ceiling to the taps. The compressor ticking over. It smelled of wet stone and old beer and, under that, something sweet and stale that he knew from other cellars.
    Past the last row of kegs the concrete gave out to dirt, and the foundation ran on into the dark toward the front of the building, over the black stumps of old pilings.
    In the corner by the stairs somebody had built a room out of plywood, with a door that locked and a desk lamp left on that you could see through the gap at the top. The office.
- else:
    {shuffle:
    - He went down through the trapdoor, over the third step. The cold, the compressor, the smell.
    - He went down, stepping over the third step. The kegs sweated in the flashlight.
    - Down the trapdoor. Somewhere past the kegs, something stopped moving when he did.
    }
}
{ fries_step > 0 && not at_keg.fries_gone && clock >= fries_step + 30:
    -> fries_gone
}
-> kg_opts

= kg_opts
{ due(): -> called_up }
<- moves(keg)
+ [The office.]
    -> office
* [Look around with the flashlight.]
    -> look
* {at_keg.look} [Follow the scratching into the crawlspace. #check: wrongman 8]
    -> crawl
+ {fries == 1} [Leave the fries on the third step.]
    -> leave_fries
+ {poison_at ? keg && clock >= poison_laid + 60 && not at_keg.check_bait} [Check the bait.]
    -> check_bait
+ {trap_at ? keg && clock >= traps_set + 60 && not at_keg.check_traps} [Check the traps.]
    -> check_traps
* {clock >= 1320} [Change the lager. It's been spitting foam since ten.]
    -> change_keg

// Hutch, in director mode (27 Sept), on what's in a keg room the customers never see: rats, empties,
// cases of clamato and tomato and the other juices for mix, napkins, straws, and an office where the
// money's kept, the servers' due-backs, and somewhere to do cocaine. (Worked in by Claude.)
= office
~ pass(2)
~ knows += office_seen
{ at_keg.office == 1:
    The office was a plywood box with a desk in it, built into the corner by somebody with a weekend and a sheet of ply. A safe under the desk. A coffee can of pens. On the wall, the schedule, with his name on it for Wednesday and Friday in the bartender's writing, and a row of brown envelopes on bulldog clips, one for each server, DUE BACK across the top of every one.
    Stacked to the ceiling around it: cases of clamato, tomato juice, orange, the grapefruit nobody ordered; boxes of napkins and straws; the empties going back, sticky, in their cases.
    On the desk, a little square mirror, wiped. Not quite wiped. A dust of white in one corner of it, and a straw cut down to two inches lying beside it.
    FATHER: Every bar. Every single bar.
    MANUAL: The use of controlled substances by staff on the premises is grounds for dismissal and must be recorded.
    { knows ? bait_office:
        The bucket the cook had talked about was on the floor under the schedule, and the box of traps on the shelf beside it, still in the plastic.
    - else:
        On the floor under the schedule there was a white bucket with a lid, RODENTICIDE on the side, and a box of rat traps on the shelf beside it, still in the plastic.
        ~ knows += bait_office
    }
- else:
    The office. The safe, the envelopes, the juice, the bucket under the schedule.
}
-> office_opts

= office_opts
// The mirror on the desk: a thing for the book, or a thing he wiped, or a thing he never saw.
* {not office_wiped} [Note it. It goes in the book.]
    ~ incident += inc_office
    He looked at it long enough to be able to say what it was, and left it where it was.
    WRONGMAN: Somebody always writes it down, in the story. Then everybody knows who.
    -> office_opts
* {incident !? inc_office} [Wipe the mirror clean.]
    ~ office_wiped = true
    He wiped it with the side of his hand until it was only a mirror, and put the straw in his pocket.
    FATHER: Now it's yours. That's what wiping it does.
    -> office_opts
+ {not poison} [Take the bait.]
    -> lay_poison
+ {not traps} [Take the traps.]
    -> set_traps
+ [Out of the office.]
    -> kg_opts

= lay_poison
~ pass(3)
The bait was in the white bucket on the office floor, with a lid that didn't want to come off. Inside were green blocks the size of a thumb, each with a hole through the middle. The bucket was half empty.
MANUAL: Wear gloves. Place in tamper-resistant stations only. Never where it can contaminate food.
- (where_bait)
* [Here in the keg room, where they live.]
    ~ poison_at += keg
    He put the blocks along the foundation wall and in the dark past the kegs, where the droppings were thickest. There were old blocks down there already, gnawed down to the holes.
    { knows ? cook_advice:
        ~ rep(rep_cook, 1)
        FATHER: Where the cook said. He'll hear you listened.
    }
* [Along the pipes behind the walk-in.]
    ~ poison_at += kitchen
    -> carry_up ->
    He pushed the blocks into the gap around the pipes, as far in as he could reach.
    MANUAL: Never where it can contaminate food.
    { cook_here():
        COOK: Are you kidding me? The inspector sees that, it's my kitchen he shuts, not yours.
        ~ rep(rep_cook, -1)
    }
* {knows ? t28_rat} [In the hole in the baseboard behind table 28.]
    ~ poison_at += t28
    -> carry_up ->
    He waited until table 28 were watching the hockey and put two blocks into the hole in the baseboard where Walter went in and out, and pushed them in with the side of his boot.
    Nobody saw. That was the idea.
    WRONGMAN: Somebody always sees. In the story it was the one nobody was watching.
+ (lid_back) [Put the lid back on.]
    He put the lid back on the bucket and pushed it back under the schedule with his foot.
    { lid_back == 1:
        ~ rat_favour++
        ~ rats_heard += h_lid
        Past the kegs, in the dark, the scratching stopped, for about as long as it takes to notice something.
    }
    -> office_opts
- ~ poison = true
~ poison_laid = clock
~ go_to_war()
~ incident += inc_poison
{ cook_here():
    ~ rep(rep_cook, 2)
}
# done: bait
FIGHTER: Good. Finish it.
FATHER: Poison's how you do it when you don't want to be there when it happens.
{ poison_at ? keg:
    -> kg_opts
}
-> hub

= set_traps
~ pass(3)
The traps were in a box on the office shelf, twelve of them, still in the plastic. The owner had bought them the same day as the bait, going by the receipt taped to the box.
{ knows ? cook_advice:
    FATHER: You'll catch three, the cook said.
}
- (where_traps)
* [Set them here in the keg room.]
    ~ trap_at += keg
    He set them along the foundation wall, with peanut butter from the walk-in on the triggers, the way his father had done it in the garage.
    FATHER: Along the wall. They run the walls. They don't cross open floor if they can help it.
* [Set them behind the walk-in.]
    ~ trap_at += kitchen
    -> carry_up ->
    He set them in a row along the wall behind the walk-in, where the droppings were.
    { cook_here():
        COOK: Great. Beautiful. Now I lose a finger.
    }
* {knows ? t28_rat} [Set one under table 28.]
    ~ trap_at += t28
    -> carry_up ->
    He set one in the dark under the radiator beside table 28, a foot from the hole in the baseboard, while they argued about the power play.
    FATHER: You know what'll walk into that first.
+ (traps_back) [Put them back on the shelf.]
    He put the box back on the shelf, still in the plastic.
    { traps_back == 1:
        ~ rat_favour++
        ~ rats_heard += h_lid
    }
    -> office_opts
- ~ traps = true
~ traps_set = clock
~ go_to_war()
{ cook_here():
    ~ rep(rep_cook, 1)
}
{ trap_at ? keg:
    -> kg_opts
}
-> hub

// Up the stairs from the keg room with the bucket or the box, out of the trapdoor behind the bar,
// past her. She said deal with them however you want, but not in front of the customers.
= carry_up
~ pass(2)
He came up the stairs with it, over the third step, and out of the trapdoor behind the bar. The bartender looked at what he was carrying, and then at him, and stepped around the hole.
{ at_keg.carry_up == 1:
    BARTENDER: Not where they can see it. I said.
}
~ rep(rep_staff, -1)
->->

= called_up
{stopping:
- Somebody was stamping on the trapdoor over his head. The bartender.
- The stamping again, over his head.
}
BARTENDER: Door! You're wanted.
~ pass(1)
-> hub

= look
~ pass(5)
~ knows += keg_hole
He ran the flashlight along the bottom of the walls.
Droppings everywhere, like spilled rice. The bottom of every cardboard case gnawed through. A path worn along the foundation, and a dark line of grease on the stone at exactly the height of a rat's back, from the floor drain to a hole where the wall met the dirt.
On the post by the stairs, the wiring had been chewed down to the copper in two places.
MANUAL: Chewed wiring is a fire hazard. The inspector will close you for the wiring before he closes you for the rats.
From the dark past the kegs, from the front of the building, came a sound like somebody rubbing their hands together. A lot of somebodies. #sfx: scratch
FATHER: Don't go in there.
FIGHTER: Go in there.
-> kg_opts

= crawl
~ pass(10)
He went past the last keg and got down on his hands and knees on the dirt. The floor joists were a foot above his back. He went toward the sound.
{ passed:
    -> knot
}
The sound was everywhere and nowhere, and then it stopped all at once, the way a room goes quiet when you walk in.
He cracked his head on a joist backing out, and came up the stairs with dirt on his knees and nothing to show for it.
BARTENDER: Find anything?
* ["No."]
    ~ rats_heard += h_said_no
* ["They're down there."]
    ~ rats_heard += h_said_down
    BARTENDER: I know they're down there. Thirty-one years I've known.
- -> hub

= knot
~ knows += knot_seen
~ knows += keg_hole
Under the front of the building, where the outside wall came down onto the old foundation, the sound was coming out of the wall itself, through a gap where a stone had fallen out.
He put the flashlight into the gap.
There was a hollow in the wall, between the studs, and they were in it. Rats, more than a dozen, packed together in a ring with their heads out and their tails in the middle. The tails were knotted. Not tangled. Knotted, into one cord, pulled tight, with filth and hair worked into it, like a rope that has been wet for years.
They were alive. They didn't run. They couldn't. The ring turned a little in the light, all of it together, like one animal trying to find him.
Around it, other rats, coming and going. Bringing things. A fry. A crust.
And through the floor over his head, as clear as if he were sitting with them, table 28.
MANUAL: There is no section for this.
FATHER: A man on the docks told me he'd seen one, once. We all said he was drunk. He was drunk.
WRONGMAN: Don't tell anyone. Nobody believes the one who saw it.
The Fighter didn't say anything. There was nothing in it to hit.
- (kn)
* [Put the light out and listen to the floor.]
    -> listen_t28
* [Reach into the gap. #check: fighter 9]
    { passed:
        He got his hand into the gap and closed it on the cord of tails, and felt the whole ring pull against him at once, like a rope with a boat on the other end of it.
        He let go. He didn't know why. His hand decided before he did.
        FIGHTER: You had it.
        FATHER: No. It had you.
    - else:
        Something in the ring turned faster than he did, and teeth went through the web of his thumb. #sfx: hit
        ~ hurt++
        ~ incident += inc_hurt
        He came back out of the gap with his hand jammed in his armpit, swearing through his teeth, and the ring pulled back into the wall where the light couldn't follow.
        MANUAL: Rat bites carry a serious risk of infection. Seek medical attention.
    }
    ~ rat_favour--
    -> kg_opts
* [Back out slowly.]
    He backed out on his hands and knees with the light on the gap until the gap was too far away to see. The sound started up again behind him before he got to the kegs.
    -> kg_opts

= listen_t28
~ pass(5)
He put the light out. The dark was total. The ring breathed.
Over him, a foot from his face, boots on the floor. Table 28.
{
- claims ? said_city_line:
    TEAM_JACKET: The kind with a line outside, he says. I've stood in that line. I never saw him.
    SCRATCH: You were never in the city.
    TEAM_JACKET: I've stood in a line.
- claims ? said_city_unnamed:
    TEAM_JACKET: Ten years on a door in the city, and he won't say which door. You notice he wouldn't say which.
    SCRATCH: Something happened.
    TABLE28: Something happened.
- claims ? said_city_door:
    TEAM_JACKET: Ten years in the city, he says. Nobody does ten years on a city door and ends up here.
    SCRATCH: Unless something happened.
    TABLE28: Something happened.
- claims ? said_father:
    CARDIGAN: His father worked doors. You can see it on him. He stands as if somebody's watching him do it.
- claims ? said_up_island:
    SCRATCH: Up island. They're all from up island.
- claims ? said_around:
    TEAM_JACKET: Around. What kind of an answer is around.
- else:
    TEAM_JACKET: Where's the new kid got to?
    SCRATCH: Keg room. I saw him go down. Bad luck, that keg room.
}
{
- rep_t28 >= 3:
    TABLE28: He's all right, though.
- rep_t28 <= -2:
    TABLE28: He won't last.
- else:
    TEAM_JACKET: Give him a week.
}
HEARING_AID: Week.
In the wall the ring turned toward the sound of them. It had been listening to table 28 for longer than he'd been alive.
// The informant double meaning (bible/06_THE_HOTEL.md): the rats hear everything table 28 says.
-> knot.kn

= leave_fries
~ pass(2)
~ fries = 2
~ fries_step = clock
~ rat_favour++
He put the basket on the third step, the soft one, and went back up.
WRONGMAN: You're feeding them now.
FATHER: You're paying them. There's a difference, and they know it.
-> hub

= fries_gone
The basket was still on the third step, and it was empty. Not a crumb. It had been pushed back square to the middle of the step, the way you'd leave a plate you'd finished with.
WRONGMAN: Manners.
-> kg_opts

= check_bait
~ pass(3)
The blocks he'd put along the foundation were gone. Every one. Not scattered. Gone, and the dust where they'd been had been swept by something dragging.
MANUAL: Bait uptake indicates an active population. Replenish.
FATHER: They took it home. That's where they'll die, in the walls where you can't get at them. Then you'll smell it.
-> kg_opts

= check_traps
~ pass(3)
~ rats_killed++
Two of the traps along the wall had gone off. One had a young rat in it, the bar across its neck. The other was sprung and empty, the peanut butter licked off the trigger clean as a plate.
FATHER: One. Out of however many there are.
* [Put it in the dumpster and reset the traps.]
    ~ pass(5)
    ~ traps_reset = true
    He carried it up through the kitchen by the tail and out to the alley, and came back and reset both traps with fresh peanut butter.
    { cook_here():
        COOK: Not through my kitchen! Not by the tail! Come on, Security, I've got food out.
        ~ rep(rep_cook, -1)
    }
* [Leave it where it is.]
    ~ rat_favour--
    ~ rats_heard += h_left_trap
    WRONGMAN: Leave it where the others can see it. In the story that's a message. Nobody ever says what it means.
- -> kg_opts

= change_keg
~ pass(6)
~ rep(rep_staff, 1)
The lager was the keg at the end of the first row. He rocked it and it was light. He twisted the coupler off, rolled a full one into its place, put the coupler on and pulled the handle down, the way he'd done it at his last door, and the one before that.
BARTENDER: Lager's back.
She said it to the customers, but she'd said it down the hole first.
FATHER: Do the job that's in front of you. The rest comes to you.
-> kg_opts


// ------------------------------------------------------------------ 9:30 the rat on the carpet

=== ev_rat ===
~ rat_scene = true
~ here = floor
{ poison: -> sick }
-> bold

= bold
Something came out from under the bar rail and crossed the carpet in three quick runs, stopping under the stools between runs, the way they do.
A rat. {knows ? t28_rat:Not Walter. A young one, thin, with a torn ear.|A young one, thin, with a torn ear.} Out in the light at half past nine, with the room half full.
{slippers_upstairs:The woman in slippers, the one who'd stayed with the bottle,|One of the women in slippers} lifted her feet onto the rung of her stool and didn't make a sound. Nobody else had seen it. Yet.
FIGHTER: Now. While it's in the open.
FATHER: Whatever you do, do it like it's nothing.
* [Stamp on it. #check: fighter 7]
    ~ pass(1)
    { passed:
        He was quicker than it was. It was over under his boot, with a sound he felt more than heard.
        ~ rats_killed++
        ~ incident += inc_rat
        ~ go_to_war()
        The woman in slippers put her hand over her mouth. Table 28 turned all the way round in their chairs. The bartender came down the bar with a roll of paper towel and a garbage bag and her face set.
        BARTENDER: Not in front of the customers. I said.
        ~ rep(rep_staff, -1)
        { knows ? t28_rat:
            SCRATCH: Is that Walter? That's not Walter.
            TEAM_JACKET: That's not Walter. Walter's twice the size.
        - else:
            TABLE28: There he is!
        }
    - else:
        His boot came down on carpet. The rat went under table 28 at a flat run, and table 28 lifted their feet, all five, together, like they'd practised it.
        TABLE28: Walter!
        It wasn't Walter. They didn't care. Every rat was Walter to table 28.
        ~ knows += t28_rat
    }
* [Drop a pint glass over it. #check: fighter 8]
    ~ pass(2)
    { passed:
        He took an empty pint glass off the nearest table and brought it down over the rat mid-run, and then it was under the glass on the carpet, up on its back legs with its hands flat on the inside.
        MANUAL: Slide a coaster underneath.
        He slid a coaster underneath and picked the whole thing up, glass and coaster and rat, the weight of it going round and round inside.
        The woman in slippers clapped, twice, quietly.
        -> glass_rat
    - else:
        The glass came down on the carpet a foot behind it and bounced. The rat went into the back hall and was gone.
        BARTENDER: Nice.
    }
* [Tell the woman in slippers it's a mouse. #check: father 6]
    ~ pass(1)
    { passed:
        He leaned on the bar beside her and said, low, that it was a mouse, that they came in out of the rain, that it was more scared of her. She put her feet back down, slowly.
        SLIPPERS: A mouse.
        SLIPPERS: That was a big mouse, dear.
        But she stayed where she was and she didn't tell anyone, and by the time anyone else looked it was gone into the back hall.
        ~ rep(rep_staff, 1)
        FATHER: Keep your voice down and people will believe anything you tell them.
    - else:
        SLIPPERS: That's not a mouse, dear. I've lived upstairs eleven years.
        { slippers_upstairs:
            She took her glass and went up through the hotel door in her slippers, after her friend. The bottle stayed on the bar, a third of it left.
            ~ slippers_both = true
        - else:
            She took her glass and went up through the hotel door in her slippers. Her friend stayed with the bottle.
            ~ slippers_upstairs = true
        }
        ~ room_count--
    }
* [Let it go.]
    ~ pass(1)
    He let it go. It went along the baseboard, past the jukebox, and into the hole behind table 28 as if it had somewhere to be.
    The one scratching lottery tickets dropped a fry under the table without looking down.
    ~ knows += t28_rat
    WRONGMAN: Every rat in the building knows that table.
    FIGHTER: You let it walk.
- -> hub

= glass_rat
* [Take it out the back and let it go in the alley.]
    ~ pass(4)
    He carried it through the kitchen and out the back door and lifted the glass in the alley. The rat sat on the coaster for a second, as if to show him it could, and then went up the alley toward the dumpster.
    { cook_here():
        COOK: You're kidding me. You're kidding me, right?
        ~ rep(rep_cook, -1)
    }
* [Drown it in the mop bucket.]
    ~ pass(3)
    ~ rats_killed++
    ~ go_to_war()
    He took it into the kitchen and put the glass mouth down in the mop bucket and held it there. It took longer than he expected. Everything like that does.
    { cook_here():
        ~ rep(rep_cook, 1)
    }
    FIGHTER: Done.
    FATHER: You didn't have to watch it. You watched it.
* [Take it down to the keg room and let it go there.]
    ~ pass(4)
    ~ rat_favour++
    ~ knows += keg_hole
    He went down through the trapdoor and set the glass on the dirt past the last keg and lifted it. The rat went into the dark toward the front of the building without hurrying.
    From the dark, for a second, a sound like a lot of hands being rubbed together. Then nothing. #sfx: scratch
    WRONGMAN: You gave one back. Somebody down there counts things like that.
- -> hub

// If there's poison down, the rat that comes out is dying. Poisoned rats get thirsty and lose
// their fear and come out into the light, which is the last thing the bartender wanted.
= sick
// Walter only comes out like this once the bait's had its days (Friday on). Tonight's is a stranger.
~ temp is_walter = day >= 3 && walter == 3
A rat came out from under the bar rail and walked across the middle of the carpet, in the light.
Rats don't do that. It was walking wrong, slow, its back end swinging, and it stopped in the open by the pool table and sat there as if it had forgotten where it was going.
MANUAL: Anticoagulant bait causes internal bleeding over several days. Affected animals become lethargic, disoriented and thirsty, and may be seen in the open.
{ day < 3:
    MANUAL: Several days. This one ate bait somebody put down before you came.
    FATHER: And you put down more. So it's yours now.
- else:
    FATHER: You put it down. So this is yours.
}
{ is_walter:
    The one who scratched lottery tickets stood up so fast his chair went over behind him.
    SCRATCH: That's Walter.
    It was. The size of him. The nick out of his ear.
    ~ knows += t28_rat
    ~ knows += walter_name
}
The whole room was looking at it now. The woman in slippers had both hands over her mouth.
* [Finish it quickly. #check: fighter 6]
    ~ pass(1)
    ~ rats_killed++
    ~ incident += inc_rat
    { passed:
        He did it with one boot, fast, and it was over before most of the room understood what it was looking at.
    - else:
        He didn't do it cleanly. It took two, and everyone heard both.
        ~ rep(rep_staff, -1)
    }
    ~ rep(rep_staff, -1)
    { is_walter:
        ~ rep(rep_t28, -3)
        Table 28 didn't say anything. The one who'd stood up picked up his chair and sat back down in it and looked at the table.
    - else:
        BARTENDER: Jesus Christ.
        She got the mop out from behind the bar and held it out to him, handle first.
    }
* [Pick it up in a bar towel and carry it out.]
    ~ pass(4)
    ~ incident += inc_rat
    He knelt and put a bar towel over it and picked it up. It hardly weighed anything. It didn't fight him.
    He carried it out through the kitchen to the alley and put it down under the back stairs, out of the rain, and left it there.
    ~ rep(rep_staff, 1)
    FATHER: That's the least you owed it.
* {is_walter} [Pick him up in a bar towel and give him to Scratch.]
    ~ pass(4)
    ~ incident += inc_rat
    He knelt and put a bar towel over Walter and picked him up and carried him to table 28, and put him in the lap of the man who'd been feeding him fries for years.
    The man held him. Nobody at the table said anything. After a while he took Walter out onto the deck, in the towel, and he didn't come back in for a long time.
    ~ rep(rep_t28, 1)
    WRONGMAN: In the story, the doorman carried the body out himself. He never forgot the weight. This one's lighter.
* [Leave it. It won't be long.]
    ~ pass(1)
    ~ incident += inc_rat
    It went under the radiator by table 28, and they could all hear it for a while, and then they couldn't.
    The bartender had to go in after it with the dustpan, on her knees, in front of everybody.
    ~ rep(rep_staff, -2)
    { is_walter:
        ~ rep(rep_t28, -2)
    }
- { is_walter:
    ~ walter = 0
    -> who_poison ->
}
-> hub

// A tunnel: the rat on the carpet (Friday on) and the bait found at close both come here.
= who_poison
TEAM_JACKET: Who put poison down.
Nobody at the bar said anything. The bartender looked at the kitchen door, and then at the doorman.
* ["I did."]
    ~ rep(rep_t28, -1)
    TEAM_JACKET: Well.
    TEAM_JACKET: At least you said so.
* ["Owner's orders."]
    ~ rep(rep_t28, -2)
    TEAM_JACKET: The owner's never met Walter.
    FATHER: Now it's the owner's rat and your hand. Tables remember the hand.
* [Say nothing.]
    ~ rep(rep_t28, -3)
    They worked it out. It didn't take them long. Table 28 had worked out every doorman they'd ever had.
- ->->


// ------------------------------------------------------------------ a trap under table 28

=== ev_trap_t28 ===
~ trap_sprung = true
~ here = t28
From under table 28 came a snap like a knuckle cracking, loud enough to hear over the jukebox, and then a sound that was worse.
The one who scratched lottery tickets was under the table before anyone else had moved. He came up with the trap in both hands, and Walter in it.
~ walter = 0
~ rats_killed++
~ incident += inc_rat
~ knows += t28_rat
~ knows += walter_name
Table 28 went quiet for the first time since two o'clock that afternoon.
TEAM_JACKET: Who put a trap under our table.
He didn't need to ask. He was looking at the doorman.
* ["I did."]
    ~ rep(rep_t28, -3)
    TEAM_JACKET: Well.
    TEAM_JACKET: At least you said so.
* ["Owner's orders."]
    ~ rep(rep_t28, -4)
    TEAM_JACKET: The owner's never met Walter.
* [Say nothing.]
    ~ rep(rep_t28, -5)
    Nobody at table 28 said anything else to him for the rest of the night.
- The one who fed him wrapped Walter in a bar towel, trap and all, and took him out onto the deck, and he was gone twenty minutes. When he came back he sat down and ordered a round, and nobody at the table mentioned it again.
FATHER: They won't mention it. That's not the same as forgetting it.
-> hub
