// The room's things: what's within reach in the Sov, and what each one does to the night.
// Hutch (23 October): "there needs to be more and they should be consequential." So every thing
// here changes something later. The empties on the rail, the house cues on the wall and the darts
// in the board are what's to hand when it goes at the pool table (pool.ink, ev_pool). The TV
// decides whether table 28 are quiet at eleven or set off. The wet tiles inside the door put
// somebody on the floor. The extinguisher in the back hall is the inspector's, on the fourteenth.
// The dimmer at last call is how fast the room empties. And what people leave behind (the big
// man's jacket with his phone in it, GOOD SHOES's wallet) brings somebody back for it.
// The VARs are in main.ink, under the room's things. Claude's draft, all of it, PROPOSED in
// bible/05_LOG.md.


// ------------------------------------------------------------------ the empties on the rail

// The rail along the wall by the pool table, where the players and whoever's watching put their
// glasses down. She cleared it at ten past seven, and she's on her own behind the bar: it gains a
// glass every twenty minutes till somebody carries them over.
=== function ledge_glasses()
~ temp n = (clock - ledge_at) / 20
{ n > 6:
    ~ n = 6
}
{ n < 0:
    ~ n = 0
}
~ return n

// He carries them over. The first time, she notices; the second, table 28 do.
=== bus ===
~ temp n = ledge_glasses()
~ pass(2)
~ ledge_at = clock
~ bussed++
~ here = bar
He stacked the empties off the rail, {num(n)} of them, one inside the next the way you carry glasses when there are more of them than hands, and took them over to the bar and set them down by the glass washer. #sfx: glass #look: bartender
{ bussed:
- 1:
    She looked at the glasses, and at him.
    BARTENDER: You don't have to do that.
    She racked them anyway, and ran the washer, and when it was going she said the rest of it to the steam.
    BARTENDER: Nine doormen. Not one of them ever carried a glass.
    ~ rep(rep_staff, 1)
    FATHER: Glasses off the rail. Every one you carry is one nobody throws.
- 2:
    TABLE28: Busboy!
    TEAM_JACKET: Atta boy! Bring us one back while you're over there!
    She slid the rack along the bar to him without a word.
- else:
    BARTENDER: Mm.
}
-> at_bar.opts


// ------------------------------------------------------------------ the cue rack and the darts

// Four house cues in the rack on the wall by the pool table (the big man and his buddy play with
// their own), a chain through them and a padlock hanging open on the end of it; the key's on her
// ring. Lock it and nobody's taking a cue off the wall. The big man sees why.
=== lock_rack ===
~ pass(1)
~ rack_locked = true
~ bigman_ease--
~ here = pool
There was a chain through the four house cues in the rack, and a padlock hanging open on the end of it, the way it had hung open since the key went on her ring. He snapped it shut.
The big man watched him do it over his cue, and straightened up.
BIGMAN: Expecting company, bud?
FIGHTER: Four clubs on the wall. Now there's none.
-> at_pool.opts

// The three darts in the board, from whenever anybody last played. She keeps them behind the till.
=== pull_darts ===
~ pass(2)
~ darts_pulled = true
~ here = bar
He pulled the three darts out of the board and took them over to the bar, points down in his fist, and she put them in the pint glass by the till with the pens and the bottle opener without asking him why. #look: bartender
BARTENDER: Nobody's thrown since the league folded.
BARTENDER: There was a league, Thursdays. Then there wasn't.
-> at_bar.opts


// ------------------------------------------------------------------ what's to hand when it goes

// What's within reach of the pool table when it goes (pool.ink, ev_pool): the empties on the rail
// once there are a few, the house cues if the rack's open, the darts if they're in the board.
=== function within_reach()
~ temp r = ()
{ ledge_glasses() >= 3:
    ~ r += r_glass
}
{ not rack_locked:
    ~ r += r_cue
}
{ not darts_pulled:
    ~ r += r_darts
}
~ return r

// On every hand he puts in at the pool table: nothing in reach, two easier; all three, one harder.
=== function reach_mod()
~ return 2 - LIST_COUNT(within_reach())

// The Fighter counts what's in reach as it starts.
=== function reach_line()
~ temp r = within_reach()
{ LIST_COUNT(r) == 0:
    FIGHTER: Rail's clear. Rack's locked. Board's empty. Nothing in that corner but hands.
- else:
    FIGHTER: {reach_words(r)}. Count them before they do.
}

=== function reach_words(r)
~ temp g = Num(ledge_glasses()) + " empties on the rail"
{
- r == (r_glass, r_cue, r_darts):
    ~ return g + ", four cues on the wall, three darts in the board"
- r == (r_glass, r_cue):
    ~ return g + ", four cues on the wall"
- r == (r_glass, r_darts):
    ~ return g + ", three darts in the board"
- r == (r_glass):
    ~ return g
- r == (r_cue, r_darts):
    ~ return "Four cues on the wall, three darts in the board"
- r == (r_cue):
    ~ return "Four cues on the wall"
- r == (r_darts):
    ~ return "Three darts in the board"
}
~ return ""

// When it goes bad, somebody picks up whatever's nearest to hand (pool.ink, after_fight): with the
// boyfriend in it, the darts in the board he's standing by, and then the empties; with only the big
// man and his buddy, the house cues off the wall, and then the empties. Afterward nobody could have
// told you who.
=== function reach_used()
~ temp r = within_reach()
{ indoors(vape_at):
    {
    - r ? r_darts:
        ~ used += r_darts
    - r ? r_glass:
        ~ used += r_glass
    - r ? r_cue:
        ~ used += r_cue
    }
- else:
    {
    - r ? r_cue:
        ~ used += r_cue
    - r ? r_glass:
        ~ used += r_glass
    - r ? r_darts:
        ~ used += r_darts
    }
}
{
- used ? r_glass:
    Somebody had one of the empties off the rail. It went on the corner of the table and came up in two pieces, and somebody put an arm up, and there was blood on the felt, a line of it, before anybody had decided anything.
- used ? r_cue:
    Somebody had a house cue off the wall by the thin end. It came round once and broke across somebody's back, and it was the noise of it breaking that stopped the room.
- used ? r_darts:
    Somebody had the darts out of the board, all three, in a fist with the points out, and stood there with them as if he'd only just found out what he was holding. The doorman had to take them off him one at a time.
}

// Something got picked up. She doesn't ask him this time (pool.ink, after_fight).
=== weapon_call ===
~ police_called = true
~ police_at = clock
~ incident += inc_police
~ rep(rep_owner, -1)
She didn't ask him this time.
BARTENDER: Somebody picked something up, Door. That's not mine to sit on, and it's not yours.
MANUAL: Where a weapon is used on licensed premises, police are called. There is no discretion.
{ at_pool > 0:
    FATHER: You saw it lying there. You left it lying there.
- else:
    FATHER: You never went near that corner to see what was lying in it.
}
-> ev_pool.sort_out

// For the incident log (closing.ink, inc_text): what was picked up.
=== function used_said()
{
- used ? r_glass:
    ~ return "A glass off the rail broken in it, and somebody cut"
- used ? r_cue:
    ~ return "A house cue broken in it"
- used ? r_darts:
    ~ return "The darts out of the board in it"
}
~ return ""


// ------------------------------------------------------------------ the TV over the back wall

// The hockey's over at eleven, and the goals go round till half past. Then it's the late news on
// the big TV (sim.ink, pass()), unless somebody's put something else on, and the late news has the
// light over the strait in it, two nights running (bible/11_SKELETON.md: the object in the sky,
// argued about in fragments and never explained). Table 28 watch that TV the way they watch the
// door. The hockey keeps them quiet. The news sets them off.

// What's on it now, in a line, for the late room (floor.ink, room_line).
=== function tv_words()
{
- tv_on == 1:
    ~ return "The late news on the big TV: the rainfall warning, and the light over the strait again."
- tv_on == 2:
    ~ return "The game on again from the start, and table 28 watching it as if it might come out different."
- tv_on == 3:
    ~ return "The big TV off, a dark square over the back wall, and table 28 talking to each other for want of it."
- tv_on == 4:
    ~ return "Curling on the big TV, and table 28 watching it in the silence of men in church."
}
~ return "The same four songs again. The TV showing the goals from the game everybody had just watched."

=== function remote_label()
{ t28_off > 0:
    ~ return "Ask her for the TV remote. Table 28 and the news."
}
~ return "Ask her for the TV remote."

// She keeps the remote under the bar rag by the till: the black one, not the jukebox's.
=== the_remote ===
~ pass(1)
~ here = bar
{ rep_staff <= -3:
    ~ remote_how = -1
    BARTENDER: Nope.
    She didn't look up. The remote stayed under the rag, under her hand.
    FATHER: You haven't earned her remote. You haven't earned her ice.
    -> at_bar.opts
}
~ remote_how = 1
She found it under the bar rag and held it out to him, the black one, not the jukebox's. #prop: remote
BARTENDER: Don't you put the curling on. They'll be here till four.
- (rm)
<- reads_remote(-> rm)
* {tv_on != 2} [Put the game on again from the start. The sports channel runs it at night.]
    -> replay
* [The curling.]
    -> curling
* {tv_on == 0} [Put the news on.]
    -> news
* {tv_on == 1} [Leave it on the news, and watch it with them.]
    -> news
* [Turn it off.]
    -> off

= replay
~ temp calmed = t28_off > 0
~ tv_on = 2
~ t28_off = 0
He found it, the game from the start, the anthem and the same faces lined up along the blue line, and put it up on the big TV. #look: t28
{ calmed:
    It took table 28 about a minute to notice, and then the argument stopped in the middle of a word.
    TABLE28: The game!
    TEAM_JACKET: We know how this one ends, son. Two to one.
    They watched it anyway, every minute of it.
    ~ rep(rep_t28, 1)
- else:
    TABLE28: The game!
    They watched it again from the anthem on, as if they didn't know how it came out.
}
FATHER: Give a room something to look at, and it won't look at you.
-> remote_back

= curling
~ tv_on = 4
~ t28_off = 0
He went through the channels till he found the curling: a bonspiel on the prairies somewhere, eight men in sweaters, and a stone going down the ice as slow as a ferry. #look: t28
She looked at the TV, and at him, and didn't say anything, because she'd said it already.
Table 28 went quiet. Not the quiet of men who've stopped talking. The quiet of men in church.
TEAM_JACKET: Now that's a sport.
HEARING_AID: Sport.
-> remote_back

= news
{ tv_on == 1:
    ~ pass(5)
    ~ pull_table++
    He stood at the end of the bar with the remote in his hand and watched it with them: the rainfall warning, the ferry cancellations, and the light over the strait, somebody's phone from the deck of the evening sailing, a white point in the dark that didn't blink and didn't move. A man from the Air Force said it was a weather balloon. Table 28 said a great many things.
    TABLE28: He's one of us! He wants to know!
- else:
    ~ tv_on = 1
    ~ t28_off = clock
    ~ t28_extra++
    He found the news. The rainfall warning, and then the light over the strait, somebody's phone from the deck of the evening sailing, a white point in the dark that didn't blink. #look: t28
    TABLE28: There it is!
    TEAM_JACKET: Two nights! Two nights, same place!
    And they were off, all of them at once, and somebody signalled the bar for a round to argue it over.
}
-> remote_back

= off
~ tv_on = 3
~ t28_off = 0
~ rep(rep_t28, -1)
He turned it off. The big TV over the back wall went to a black square with the room in it, small. #look: t28
TABLE28: Boo!
TEAM_JACKET: Forty years that TV's been on! Forty years!
They turned their chairs back round to the table and talked to each other instead, louder, because there was nothing to talk over.
FATHER: TV off is how you close a room. It's not how you keep one.
-> remote_back

= remote_back
He gave it back. She put it under the rag without asking what he'd done with it. She could see the TV from where she stood.
-> at_bar.opts

// Table 28 and the news, once it's set them off: they want the doorman on their side.
=== t28_news ===
~ pass(3)
~ here = t28
{ t28_news == 1:
    TABLE28: Big fella! Settle this!
    TEAM_JACKET: The light. Over the strait. On the news two nights running, same place. What is it?
    SCRATCH: HAARP. They've got the thing in Alaska pointed right at us.
    HEARING_AID: Seeding.
    CARDIGAN: My brother-in-law says the Air Force told the paper it's a weather balloon.
    TEAM_JACKET: Two nights in the same place! What's it tied to?
    SCRATCH: Or it's a psyop. They put it up there to see if we'll argue about it.
    TEAM_JACKET: Then it's working!
- else:
    TABLE28: {shuffle:He's back! Ask him!|Here's the expert!|Big fella! Tell him!}
}
* ["A satellite."]
    ~ t28_extra++
    SCRATCH: That's what they say. That's exactly what they'd say.
    TABLE28: Boo!
    It went round the table again and came back bigger, and somebody signalled the bar for another round to argue it over.
* ["Who's got the score from the game?" #check: father:cha 11]
    { passed:
        ~ t28_off = 0
        ~ rep(rep_t28, 1)
        It was the right question asked the right way, and it went through them like a spoon on a glass.
        TEAM_JACKET: Two to one! And that second goal was offside!
        TABLE28: Offside!
        By the time the light over the strait came round on the news again, nobody at the table was looking at it.
    - else:
        TABLE28: Who cares about the game!
        TEAM_JACKET: There's a thing in the sky, son, and he wants the score.
    }
* [Pull a chair up and hear it out.]
    ~ pass(10)
    ~ pull_table++
    He pulled a chair up. They gave him all of it at once: HAARP, and the cloud seeding, and the Air Force, and a man up island who'd filmed it and had his phone taken off him at the ferry, and none of it went anywhere, and none of it stopped.
    TABLE28: He's one of us! He wants to know!
    FATHER: Never take a side at a table. You'll be sitting at it for life.
- -> carry_on


// ------------------------------------------------------------------ the tiles inside the door

// The rain comes in on everybody's boots. She mopped at half past seven, before he came on; every
// two who come in past the stool, and every two hours, the tiles inside the door get a step wetter,
// to three. He can mop them himself (the mop's in its bucket in the corner of the vestibule), and put
// the yellow sign out. A careful man reads a sign. A man going home after two each doesn't.
=== function wet()
~ temp w = (count_in + walk_ins - in_at_mop) / 2 + (clock - mopped_at) / 120
{ w > 3:
    ~ w = 3
}
~ return w

// Back on the door: how the tiles look now, once, as they get worse (door.ink, at_door).
=== function wet_line()
{ wet() < 2 || wet() <= wet_seen:
    ~ return
}
~ wet_seen = wet()
{ wet() >= 3:
    The tiles inside the door were one long puddle with boot prints in it. The mat had given up an hour ago.
- else:
    The tiles inside the door had gone grey with the wet, tracked in on everybody's boots, and there was a skid in it where somebody's heel had gone.
}

=== mop ===
~ pass(4)
~ mopped_at = clock
~ in_at_mop = count_in + walk_ins
~ wet_seen = 0
~ here = door
He got the mop out of the bucket in the corner of the vestibule and wrung it, and did the tiles from the inner door out, the way you mop a floor you don't want to walk back across.
{ mop == 1:
    TABLE28: Look at him go!
    TEAM_JACKET: The last one never mopped! Never mopped a thing!
    BARTENDER: That's not your job, Door.
    She watched him do it anyway, across the room, between pours.
    BARTENDER: Thanks.
    ~ rep(rep_staff, 1)
    FATHER: The floor inside the door is the door's. Anybody goes down on it, they went down on you.
- else:
    {shuffle:
    - The tiles again. The rain kept coming in on people's boots, and he kept taking it back out.
    - He did the tiles again, and stood the mop back in the bucket where he could reach it.
    }
}
-> door_quiet

=== wet_sign_out ===
~ pass(1)
~ wet_sign = true
~ here = door
He unfolded the yellow sign from behind the bucket and stood it on the tiles: a little man falling over backwards, and CAUTION WET FLOOR under him in two languages.
MANUAL: A hazard that cannot be removed must be marked. Marking a hazard is not removing it.
-> door_quiet

// GOOD SHOES, coming in at half past ten (door.ink, door_banned), when the tiles are at their worst
// and there's no sign out to read.
=== slipped ===
~ slip = 1
~ incident += inc_slip
~ pass(1)
His good shoes went out from under him on the wet tiles, both at once, the way it happens on ice, and he sat down hard in the vestibule with the umbrella still half shut. #sfx: hit
For a second he sat there in his good coat on the wet floor, and nobody in the room breathed, and then table 28 did.
TABLE28: Oh-ho!
* (helped_up) [Help him up.]
    He got him under the arm and up in one go, the way you'd lift a sack you had some respect for. The man was heavier than he looked, and steadier on his feet than he'd been a second ago.
    GOOD SHOES: Thank you, friend. Very kind.
    GOOD SHOES: You'll want to get a sign out on those. Somebody could be hurt.
* (let_up) [Let him get up on his own.]
    He let him get up on his own. It took a while, and the man did it with dignity, the way he did everything, and brushed off the back of his good coat with the flat of his hand.
    GOOD SHOES: Thank you so much for your help.
- FATHER: He's got one on you now. Watch him spend it.
->->

// What GOOD SHOES makes of the floor, when he's arguing his way in (door.ink, known).
=== function slip_lever()
{ slip != 1:
    ~ return
}
{ slipped.helped_up:
    GOOD SHOES: And you were kind enough to pick me up off your floor. I won't say a word to Gary about the floor. Of course I won't.
- else:
    GOOD SHOES: And I'll try not to say anything to Gary about your floor. I'll try.
}

// At close, table 28 on their way out (closing.ink, t28_out), if the tiles are at their worst and
// nobody's had GOOD SHOES on them already. A sign's no use at two in the morning.
=== function hearing_aid_slip()
{ wet() < 3 || slip != 0:
    ~ return
}
~ slip = 2
~ incident += inc_slip
~ rep(rep_t28, -1)
At the door the one with the hearing aid went on the wet tiles, both feet at once, and the one in the team jacket had him by the back of the coat before he was all the way down, the way he must have had him by the back of the coat a thousand times.
TEAM_JACKET: Forty years I've been walking out that door, son. Never once on my backside.
HEARING_AID: Backside.


// ------------------------------------------------------------------ the extinguisher in the back hall

// On its bracket at the end of the back hall, across from the payphone. The inspector is on the fourteenth (bar.ink, rats_talk; the notice
// on Gary's desk, things.ink), and the extinguishers are the first thing an inspector reads after
// the kitchen. Nobody's read this one's tag in two years.
=== extinguisher ===
~ pass(2)
~ ext_how = 1
~ here = hall
The extinguisher hung on its bracket at the end of the hall, across from the payphone and its forty years of phone numbers. The tag on its neck had a box for every month, and every box was punched for one year, and the year was two years ago. Somebody had held the pin in with a twist tie off a bread bag.
The needle on the gauge was in the green. Or it had stuck there.
MANUAL: Portable extinguishers are inspected monthly and serviced annually by a certified technician. The tag is the record.
FATHER: Nobody reads those till the night they need one.
-> at_hall.h_opts

// He tells her (bar.ink). She keeps the owner's list in the frame of the back-bar mirror.
=== ext_tell_her ===
~ pass(1)
~ ext_how = 2
~ rep(rep_staff, 1)
~ here = bar
BARTENDER: Two years.
She didn't sound surprised. She sounded like a woman adding something to a list.
BARTENDER: Since the grease fire. That was the last time anybody pulled the pin on one of those, and Junior's father was alive.
She wrote it on a coaster in marker, EXTINGUISHER HALL, and stuck it in the frame of the back-bar mirror with the others: KEG ROOM LIGHT. WOMEN'S LOCK. ICE MACHINE. THIRD STEP.
BARTENDER: That's Junior's list. He reads it the night before the inspector, every time.
-> at_bar.opts

// Junior on the bar phone at midnight (bar.ink, ev_owner), if he's read the tag by then.
=== owner_ext ===
* [Tell him the extinguisher in the back hall's two years out of date.]
    { ext_how == 2:
        Behind the bar, she looked at the coaster in the mirror frame, and then at him.
    }
    ~ ext_how = 3
    ~ rep(rep_owner, 1)
    OWNER: Two years.
    OWNER: Jesus. That's the first thing he'll look at, after the kitchen and the rats. Before the fourteenth, that has to be.
    OWNER: I'll have a guy out. Good man.
* (ext_quiet) [Leave it for another night.]
- ->->


// ------------------------------------------------------------------ the dimmer, at last call

// The house lights are on a dimmer on the wall inside the front door, a brass plate and a dial. She
// has them down to a quarter from eight o'clock; up full is how a room finds out it's over. The
// Godot build's lamps read what he did (godot/world/pub.gd, set_clock).
=== lights_at_last ===
The house lights were on a dimmer on the wall inside the front door, a brass plate with a dial, where she'd had them down to a quarter since eight o'clock.
* [Bring the house lights up. #loc: door]
    ~ lights = 1
    {here != door:He went to the door and turned|He turned} the dial all the way round. The room came up white and ordinary: the carpet and what was on it, the scuffs along the bar, table 28 twenty years older than they'd been a second ago.
    ~ here = door
    TABLE28: Lights! At half past one!
    ~ rep(rep_t28, -1)
    { rep_staff >= 2:
        BARTENDER: Mm. Somebody's done this before.
    - else:
        BARTENDER: My lights, Door. You ask me first.
        ~ rep(rep_staff, -1)
    }
    FATHER: Lights up, music down. Nobody stays in a room they can see.
* [Ask her to bring them up.]
    ~ lights = 2
    ~ rep(rep_staff, 1)
    He caught her eye and lifted his chin at the dimmer.
    BARTENDER: Quarter to. Not before.
    At quarter to she went and turned the dial up herself without looking at it, the way she'd done it every night for thirty-one years.
* [Leave them low.]
    ~ lights = -1
    He left them where they were. In the low light the room looked like it could go on for hours, and table 28 looked at it like that too.
- ->->

// How table 28 take "Drink up" at close (closing.ink, close_t28): the house lights, the TV, and
// whether the news still has them going.
=== function t28_close_mod()
~ temp m = 0
{
- lights == 1:
    ~ m += 2
- lights == 2:
    ~ m += 1
- lights == -1:
    ~ m -= 1
}
{
- tv_on == 3:
    ~ m += 1
- tv_on == 4:
    ~ m -= 2
}
{ t28_off > 0:
    ~ m -= 1
}
~ return m

// And how much longer, or shorter, "Take your time" takes.
=== function t28_linger()
~ temp t = 0
{ tv_on == 4:
    ~ t += 15
}
{ lights == 1:
    ~ t -= 10
}
{ lights == -1:
    ~ t += 5
}
~ return t

// Locking up with the lights left low: the last of them take their time about the door.
=== function lock_extra()
{ lights == -1:
    ~ return 10
}
~ return 0


// ------------------------------------------------------------------ the big man's jacket

// His work coat, on one of the coat hooks by the dartboard, with his phone in the inside pocket. His
// daughter rings it from the truck while she's out there, and he lets it ring.
=== function cell_ringing()
~ return not fam_done && pool_still() && clock >= 1220 && (in_truck(sister_at) || sister_at == s_vestibule) && cell_how == 0

=== the_cell ===
~ pass(1)
~ here = pool
His jacket was a canvas work coat gone soft at the cuffs, hung by its loop on one of the coat hooks by the dartboard, and the phone in its inside pocket was buzzing against the wood, and stopping, and starting again. #look: bigman
The big man had his back to it. He'd had his back to it all night.
* [Tell him his phone's going.]
    ~ cell_how = 1
    ~ knows += bigman_dad
    BIGMAN: Yeah. Let it go, bud.
    He chalked his cue and didn't look round.
    BIGMAN: That'll be my girl. She can wait.
    FATHER: She can wait. I said that for twenty years.
    -> at_pool.opts
* [Take the phone out and look at it. #check: fighter:dex 10]
    { passed:
        ~ cell_how = 2
        ~ knows += kid_why
        ~ knows += bigman_dad
        He had it out of the pocket and turned to the wall while the big man was bent over a shot. #prop: bm_cell
        The lock screen was full of them, one on top of the next, all from KAYLA. Eleven missed calls. The newest on top: We're outside in the truck. Tyler's going in to get you. Under it: She wants you there. We're coming to get you. Under that: They think it's her heart. And at the bottom, from the morning: Dad, call me. It's Mom. We're at the hospital.
        -> cell_held
    - else:
        ~ cell_how = -1
        ~ bigman_ease -= 2
        ~ heat(1)
        He had his hand in the jacket when the big man turned round.
        BIGMAN: That's my coat, bud.
        He said it quietly, the way you'd tell a dog no, and the buddy stopped with his cue halfway back.
        FIGHTER: Hand out of the coat. Slow. Now.
        -> at_pool.opts
    }
* (cell_left) [Leave it ringing.]
    It stopped. After a minute it started again.
    -> at_pool.opts

// The big man's phone in his hand, with his daughter on it (content/data/props.yaml, bm_cell).
= cell_held
- (ch)
<- reads_cell(-> ch)
* [Put it back in the pocket.]
    He put it back where it had been, and it started again before his hand was out of the jacket.
    -> at_pool.opts
* [Hold it out to the big man. #check: father:cha 10 {bigman_mod()}]
    ~ cell_how = 3
    -> at_pool.told(2)

// He went without it (pool.ink: told, or put out, or walked off): it's still on the hook. At close
// he'd have taken it (closing.ink, the_lot).
=== function bigman_left_coat()
~ return (fam ? dad_went || fam ? dad_ejected || fam ? dad_walked) && fam !? lot_scene

// From the empty pool table, once he's gone (pool.ink, after_gone).
=== take_coat ===
~ pass(1)
~ here = pool
He lifted the jacket off the hook. It was heavier than it looked, still wet across the shoulders from whenever he'd last come in out of the rain{cell_how != 3:, and heavier on the one side, where the phone was}. #prop: bm_coat
- (tc)
<- reads_coat(-> tc)
* [Take it behind the bar, to the lost-and-found.]
    ~ coat_how = 1
    ~ drawer_seen = true
    ~ stow(bm_coat, in_drawer)
    ~ here = bar
    He took it over to the bar. She looked at it and knew whose it was. #look: bartender
    BARTENDER: Moffat's. Drawer. He'll be back for it, or one of the kids will.
    He folded it in on top of the toques{cell_how != 3:, with the phone still in the pocket}.
    -> at_bar.opts
* [Hang it back on its hook.]
    ~ coat_how = -1
    He hung it back on the hook by its loop, the way he'd found it.
    -> carry_on

// After close, if they went to the hospital without it and his phone was still in it. A tunnel from
// lock_up (closing.ink).
=== back_for_coat ===
~ pass(4)
~ here = door
~ door_away = 0
Headlights came into the empty lot, and the pickup pulled up in front of the door with its wipers going, and the daughter got out and knocked on the glass of the door he'd just locked. #portrait: driver #look: door
He let her in as far as the vestibule.
DRIVER: He left his jacket. His phone's in it.
DRIVER: The hospital keeps calling it, and he hasn't got it, and he won't use mine. So.
// In the drawer, it's safe. On the hook, it's as safe as the door was: whoever came in past the
// empty stool tonight (walk_ins, sim.ink) had all night to see it.
{ coat_how == 1 || walk_ins == 0:
    ~ back_for = 1
    ~ unstow(bm_coat)
    ~ rep(rep_kids, 1)
    {coat_how == 1:He got it out of the lost-and-found from under the toques.|He got it off its hook by the dartboard.} The phone was in the pocket, where it had been all night.
    She checked it was there before she said anything. Then she said it.
    DRIVER: Thank you.
    DRIVER: She's okay. They're keeping her. It's not her heart, they think now. They don't know what it is.
    // HUTCH: The daughter, back for her father's jacket at two in the morning, and how her mother is. The draft keeps the mother in hospital, unexplained.
    FATHER: He went. That's the part they'll remember.
- else:
    ~ back_for = 2
    ~ rep(rep_kids, -1)
    He went and got it off its hook by the dartboard. It was lighter than it should have been. The inside pocket was empty.
    DRIVER: It was in the pocket.
    DRIVER: It was in that pocket all night. I called it twenty-six times.
    She looked at him the way she'd looked at him at the door, as if he was something she'd walked into.
    DRIVER: Okay.
    She took the jacket and went.
    { the_cell.cell_left:
        FATHER: You heard it ringing in there. So did whoever took it.
    - else:
        FATHER: Somebody came in past your stool tonight that you never saw. They saw the coat.
    }
}
The pickup's lights went along the seawall and round the bend toward town.
->->


// ------------------------------------------------------------------ what GOOD SHOES left

// Put out with a hand on him (door.ink: from inside the bar, or after the one drink), he leaves his
// wallet on the carpet by the stool. He's back for it before he's paid for his gas at the Esso
// (ev_wallet, sim.ink), unless the doorman takes it out to him first.
=== function wallet_there()
~ return wallet_dropped > 0 && wallet_how == 0 && wallet_back == 0

=== the_wallet ===
~ pass(1)
~ here = bar
He bent and picked it up off the carpet. A man's wallet, brown, good leather worn pale along the fold, still warm from his coat. #prop: gs_wallet
- (wl)
<- reads_wallet(-> wl)
* (looked) [Look inside.]
    ~ knows += ardagh
    Four hundred and sixty dollars in fifties and twenties, all facing the same way. His licence, ARDAGH, GRAHAM PETER, the good haircut. A gold card. And behind the cards a photograph gone soft at the corners: a woman and a girl of about nine on a beach somewhere warm, both squinting, and him behind them, younger, with the same haircut.
    -> wl
* {looked} [Take a fifty out of it.]
    ~ wallet_cash = 50
    ~ cash += 50
    He took one of the fifties and folded it into his own pocket, and squared the rest so the gap didn't show.
    Nobody at the bar was looking. In the mirror behind the bottles, the doorman was.
    -> wl
* [Take it out to him in the lot.]
    -> out_to_him
* [Give it to her for the drawer.]
    ~ wallet_how = 2
    ~ drawer_seen = true
    ~ stow(gs_wallet, in_drawer)
    She took it off him by one corner, the way you'd take something the dog brought in, and dropped it in the lost-and-found drawer under three winters of toques. #look: bartender
    BARTENDER: He'll be back for that. That kind always comes back for the wallet.
    -> at_bar.opts
* [Keep it on him till he comes back for it.]
    ~ wallet_how = 3
    ~ pocket(gs_wallet)
    He put it in the inside pocket of his jacket. It sat there heavier than his own.
    -> at_bar.opts

= out_to_him
~ pass(4)
~ wallet_back = 1
~ here = lot
He went out the front and across the wet gravel to the dark clean car under the light at the edge of the lot. The engine was running. GOOD SHOES watched him come the whole way, and let the window down two inches.
He held the wallet up to the gap.
GOOD SHOES: Thank you, friend. That's very decent of you.
He took it through the gap with two fingers.
{ wallet_cash > 0:
    He opened it on his knee and counted it, slowly, under the dome light, while the doorman stood in the rain.
    -> short_count ->
- else:
    He put it inside his coat without opening it.
}
The window went up, and the dark car pulled out of the lot onto the highway, going toward town, at exactly the limit.
-> carry_on

// The wallet, if he's back for it at the door before the doorman's taken it out to him.
=== ev_wallet ===
~ here = door
~ door_away = 0
GOOD SHOES was back in the vestibule, dry under his umbrella, knocking on the inner door's glass with one knuckle. #look: goodshoes
GOOD SHOES: I'm so sorry to trouble you, friend. I'm not coming in. I got as far as the Esso and went for my wallet to pay for my gas.
GOOD SHOES: I believe it's under my stool.
{
- wallet_how == 3:
    It was in his own inside pocket. He could feel it there.
- wallet_how == 2:
    It was in the lost-and-found drawer, under the toques.
- else:
    It was still on the carpet by the stool. The bartender hadn't touched it. Nobody had.
}
* [{wallet_how == 3:Give it to him.|Get it, and hand it out to him.}]
    ~ wallet_back = 1
    {
    - wallet_how == 3:
        ~ unstow(gs_wallet)
    - wallet_how == 2:
        ~ unstow(gs_wallet)
        She had it out of the drawer and on the bar before he got there, and didn't look at it, or at the vestibule.
    - else:
        He went and got it off the carpet, and table 28 watched him carry it the length of the room.
    }
    He handed it out through the inner door.
    GOOD SHOES: Thank you, friend. Truly.
* {wallet_how == 0} [Let him in to get it himself.]
    ~ wallet_back = 2
    ~ rep(rep_staff, -2)
    He held the door, and GOOD SHOES walked the length of her bar in his good coat, past her, and bent for it by his stool, and walked back, and thanked her on the way past. She didn't answer.
    FATHER: He's been in twice tonight now. The second time, you held the door.
* ["Come back tomorrow, when the owner's in."]
    ~ wallet_back = 3
    ~ rep(rep_owner, -1)
    GOOD SHOES: Of course. I completely understand.
    GOOD SHOES: I'll call Gary tonight, then, and he can bring it out to me himself.
    He smiled, and opened the golf umbrella in the vestibule again, and went.
    FATHER: He'll call. That kind always calls.
    -> carry_on
- { wallet_cash > 0:
    He opened it there in the vestibule and counted it, twice, without hurrying, under the light over the door.
    -> short_count ->
- else:
    He looked into it without counting, the way a man does who knows what's in it, and put it away inside his coat.
}
{ the_wallet.looked:
    Behind the cards, he knew, the woman and the girl on the beach, squinting, and the same haircut.
}
He opened the umbrella in the vestibule, which was bad luck, and went out to his car.
-> carry_on

// He counts it, the way he does everything, in front of you. Only if the doorman had a fifty out of it.
=== short_count ===
GOOD SHOES: There were four hundred and sixty dollars in here, friend. There are four hundred and ten.
He said it pleasantly, the way you'd tell someone the time.
* [Give him the fifty back.]
    ~ fifty_how = 1
    ~ owned_it++
    ~ cash -= 50
    He took the fifty out of his own pocket and held it out. GOOD SHOES took it, and smoothed it, and put it back with the others, facing the same way.
    GOOD SHOES: I completely understand. It's a long night, and they don't pay you what you're worth. I'll say nothing to Gary.
    FATHER: Now he owns a piece of you. Fifty dollars' worth.
* ["That's what was in it."]
    ~ fifty_how = -1
    ~ cocoon++
    ~ rep(rep_owner, -2)
    GOOD SHOES: Of course it was.
    He put the wallet away inside his good coat.
    GOOD SHOES: I'll mention it to Gary. He likes to know who he's got on his door.
    FATHER: Fifty dollars. That's what you cost.
- ->->
