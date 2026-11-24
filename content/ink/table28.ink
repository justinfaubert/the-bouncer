// Table 28. Five high-functioning alcoholics in the front window, every day but Sunday.
// One voice most of the time, with small individual quirks. Loud. They own the place.
// (Hutch's, DECIDED. The five individuals below are Claude's placeholders.)
//
// Sitting down with them is how he learns them. Drinking with them is how their voice starts
// to get into his head (pull_table). Their code: loyalty, generosity, we were here first.

// Dennis has gone home: his wife came for him, or he was told she had, or he got her message.
=== function dennis_gone()
~ return arrivals ? wife_in || arrivals ? wife_told || dog_told

=== at_t28 ===
~ here = t28
{ due(): -> hub }
{ at_t28 == 1: -> first }
{ dennis_gone() && at_t28.after_dennis == 0: -> after_dennis }
{ walter == 0 && at_t28.after_walter == 0: -> after_walter }
{ poison && knows ? t28_rat && walter_alive() && rat_scene && at_t28.after_poison == 0: -> after_poison }
-> again

= first
{dennis_gone():Four|Five} faces turned up at him at once. They'd been arguing about diesel and didn't stop all the way.
// HUTCH: Table 28 is yours. What do they actually talk about on a Wednesday at eight? What's the first thing they say to a new doorman? Give each of the five one quirk from life (changed enough).
TABLE28: Here he is!
TABLE28: Look at the size of him!
SCRATCH: Junior's gone and bought a fridge.
// Gary's shirt (office.ink): put SECURITY on a man in this town and they'll line up to have a go at him.
{ shirt_on:
    TEAM_JACKET: It says SECURITY on him, boys. In case we were wondering what he was.
    TABLE28: Security!
    HEARING_AID: What's it say?
    ~ rep(rep_t28, -1)
}
TEAM_JACKET: They're getting bigger, the doormen. The last one was a big lad too, and a lot of good it did him.
HEARING_AID: Who?
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
    All of them laughed on the same beat, except the one with the hearing aid, who laughed a beat late and at something else.
* ["My father worked doors."]
    ~ claims += said_father
    ~ rats_heard += h_father
    FATHER: Don't.
    TABLE28: Ah.
    The one in the team jacket put his glass down.
    CARDIGAN: Here? On the island, I mean.
    * * ["Up island. A long time ago."]
        CARDIGAN: What was his name? If you don't mind my asking.
        * * * [Tell them.]
            ~ father_named = true
            // HUTCH: The father's name is open. When you pick it, this is where it's said out loud for the first time.
            He told them.
            Nobody at the table knew it. The one in the cardigan said it over once, to himself.
            FATHER: Now it's out.
            ~ rep(rep_t28, 2)
        * * * ["Doesn't matter."]
            CARDIGAN: Fair enough. Mine was Harold. Nobody remembers him either.
            ~ rep(rep_t28, 1)
    * * ["All over."]
        TABLE28: A travelling man!
        ~ rep(rep_t28, 1)
- TEAM_JACKET: Well, sit down, then, big fella. Nobody stands at this table.
-> offer

= offer
~ pass(3)
* [Sit down.]
    -> sit
* ["I'm working."]
    TABLE28: He's working!
    They thought that was very funny.
    TEAM_JACKET: The last one was working too, son. Look where it got him.
    ~ rep(rep_t28, -1)
    FATHER: Good. Stay standing. Once you sit at a table like that you're furniture.
    -> standing
* [Stay standing, but stay.]
    -> standing

= sit
~ pass(10)
~ pull_table++
~ rep(rep_t28, 1)
He sat down. The chair was too small for him.
TEAM_JACKET: Get the big fella a rye.
Nobody moved, and a rye arrived anyway. The bartender put it down in front of him on a coaster from a brewery that had closed in 2009, and went back.
FATHER: You know what that is.
FIGHTER: It's a drink. Drink it. They'll trust you or they won't.
- (the_rye)
* [Drink it. #hand: drink]
    ~ drink()
    ~ pull_table++
    ~ rep(rep_t28, 1)
    It was the cheap rye, with too much ice. It was fine.
    TABLE28: There he is!
    FATHER: One.
* [Nurse it.]
    ~ nursed = true
    ~ rat_favour++
    He held it and didn't drink it. All five of them watched him not drink it.
    SCRATCH: He's savouring it. Let him. It's bad luck to rush the first one.
    { knows ? endbar_seen:
        Down at the end of the bar the old man was holding his own glass the same way, full, not drinking it, and for a second he seemed to be looking at the doorman's.
    }
* [Push it back to the middle of the table.]
    ~ rep(rep_t28, -1)
    TABLE28: Oh-ho.
    TEAM_JACKET: More for us, then.
    And it went, in two seconds, and nobody was sure afterward who'd had it.
- -> stories

= stories
~ pass(8)
They talked, all of them, at once.
// The edge pass (Hutch, 2026-11-20): what a table like this says, said plainly, and nobody at it wins.
TEAM_JACKET: Two-eleven a litre for diesel. Two dollars and eleven cents! We should join the States and be done with it. At least down there you can fill a truck.
TABLE28: Fifty-first!
CARDIGAN: My father was at Ortona.
TEAM_JACKET: Your father never paid two-eleven for diesel.
SCRATCH: My grandson's in Fort Mac on eighteen hundred a week, and he still can't buy a house down here.
TEAM_JACKET: Nobody can buy a house. The Chinese bought them all, with cash, in hockey bags. It was on the news.
TABLE28: Hockey bags!
HEARING_AID: Who's playing?
Nobody mentioned the mill.
FATHER: Let them talk. A man who's on about diesel isn't fighting anybody.
~ knows += old_doorman
- (topics)
* ["What happened to the last doorman?"]
    ~ pass(4)
    ~ knows += doorman_stories
    // HUTCH: The rumour system in miniature: every version of the last doorman in circulation. Keep them or replace them with the kind of stories your regulars actually tell.
    TEAM_JACKET: Owner shorted him two weeks running. Walked out on a Friday with the float in his pocket. I was sitting right here.
    SCRATCH: He saw the big rat, down in the keg room. Came up white as a sheet. You don't come back from a sign like that.
    HEARING_AID: Woman.
    TABLE28: A woman!
    TEAM_JACKET: Lorraine, in six. He went up to ask her to keep it down and came back an hour later with his shirt on inside out.
    CARDIGAN: I think he let somebody in he shouldn't have. A friend of somebody's.
    WRONGMAN: Now that's a story.
    FATHER: The one about the float. That's the one I'd believe. Doormen steal.
    -> topics
* {knows !? t28_rat} [Something moves under the table.]
    -> walter_intro
* {knows ? t28_rat} ["How long has he been coming to this table?"]
    ~ pass(2)
    ~ rats_heard += h_walter
    ~ rep(rep_t28, 1)
    SCRATCH: Walter? Longer than you, kid. Longer than any rat's got a right to.
    TEAM_JACKET: Longer than the owner.
    TABLE28: We were here first. Then Walter. Then everybody else.
    -> topics
* {pull_table >= 2} [Stay for another. #hand: drink]
    -> another
+ [Get up.]
    TEAM_JACKET: Don't be a stranger, son.
    TABLE28: He'll be back! They always come back!
    ~ pass(1)
    -> hub

= walter_intro
~ pass(3)
~ knows += t28_rat
~ knows += walter_name
Something moved against his boot. He looked down.
A rat, big, glossy, eating a french fry held in both hands, as neat as a squirrel. Above it, the one who scratched lottery tickets was lowering another fry under the table without looking.
// HUTCH: What do they call the rat, and how long have they been feeding it? "Walter" is a placeholder.
SCRATCH: That's Walter.
TABLE28: Walter!
TEAM_JACKET: Don't tell the owner.
FATHER: That's the rat problem. It's eating a fry in front of you.
MANUAL: The presence of rodents in a food service area is a violation. The feeding of rodents by patrons is not addressed in the manual.
FIGHTER: One boot.
- (w)
* [Leave Walter alone.]
    ~ rats_heard += h_leave_walter
    ~ rep(rep_t28, 1)
    TABLE28: Hear, hear!
    Walter finished his fry and went into the wall behind the table, through a hole in the baseboard the size of a fist that he'd plainly been using for years.
    ~ knows += keg_hole
* ["The owner wants them gone."]
    ~ rats_heard += h_owner_rats
    TABLE28: The owner!
    TEAM_JACKET: The owner's never met Walter.
    SCRATCH: The owner's never met anybody. He's in town.
    CARDIGAN: They were here before him, you know. The rats. Before the hotel, I'd think. This was a cannery once, built out over the water, and the tide went in and out under the floor. You don't get rid of rats in a building like this. You come to an arrangement with them.
    WRONGMAN: An arrangement.
    ~ knows += keg_hole
    -> w
* [Put a boot on him. #check: fighter:dex 12]
    ~ rats_heard += h_boot
    { passed:
        He was quick. The boot came down on Walter's back.
        ~ walter = 0
        ~ rats = war
        ~ rep(rep_t28, -4)
        ~ incident += inc_rat
        The table went completely silent, for the first time since two o'clock that afternoon.
        SCRATCH: That was Walter.
        TEAM_JACKET: Get away from our table.
        He got away from their table. -> hub
    - else:
        Walter was gone before his boot came down, into the hole in the baseboard, and the boot hit the leg of the table and slopped five drinks.
        TABLE28: Hey!
        ~ rep(rep_t28, -2)
        ~ rats = war
        TEAM_JACKET: You'll pay for those.
        He did. Five drinks. Cash, because the machine was being funny.
        ~ cash -= 20
        ~ knows += keg_hole
        -> hub
    }
- -> topics

= another
~ pass(15)
~ drink()
~ pull_table++
~ rep(rep_t28, 1)
{ at_t28.another == 1:
    Another rye arrived without anyone ordering it.
- else:
    The ryes kept arriving, unordered and unpaid for.
}
{ drinks >= 3:
    FATHER: {Num(drinks)}. I counted. You're counting too, or you should be.
}
{
- at_t28.another == 1:
    The talk went round. After a while he stopped hearing five men and heard one, in five chairs, sure about everything.
- at_t28.another == 2:
    The talk went round again, and this time he went round with it.
    TEAM_JACKET: How do you sink a Newfie submarine?
    TABLE28: Knock on the door!
    The one with the hearing aid laughed the hardest. He was from Twillingate.
- else:
    The talk went round again, and this time he went round with it.
}
{ pull_table >= 3 && at_t28.another <= 2:
    For a moment he could hear what they'd say before they said it.
}
{ at_t28.another == 1:
    -> the_phone ->
}
TEAM_JACKET: {shuffle:He's all right, this one!|You're all right, son. You're all right.|Atta boy.}
{ knows !? dennis:
    The bartender came over with a round nobody had ordered and said "Dennis, you're driving?" to the one in the big glasses, who said "Never," and everyone laughed.
    ~ knows += dennis
}
// The TABLE voice: tipping to own you.
{ at_t28.tip_offer == 0: -> tip_offer }
-> topics

// Scratch's phone: where the table gets its news now (Claude's draft, PROPOSED). Read back the
// next time he comes to the table (slop_back).
= the_phone
The one who scratched lottery tickets held his phone out across the table, at arm's length because of his eyes.
A soldier with no legs, in a wheelchair, saluting, behind a cake that said HAPPY 100 BIRTHDAY SOLDIER in blue icing. Over it: WHY DON'T PICTURES LIKE THIS EVER TREND? Forty-one thousand people had liked it.
SCRATCH: A hundred years old. And nobody wished him happy birthday.
He'd written under it himself, with the caps lock on: HAPPY BIRTHDAY SIR THANK YOU FOR YOUR SERVICE, and a flag.
FIGHTER: Count the fingers on the salute.
{ knows ? esso_rater:
    The kid at the Esso would have known before he'd finished looking.
}
* ["It's not real. He's got six fingers."]
    ~ t28_slop = 1
    ~ rep(rep_t28, -1)
    The one with the lottery tickets turned the phone round and counted. It took him a while.
    SCRATCH: It's the thought, though.
    TABLE28: The expert!
    He put the phone in his shirt pocket and did the button up over it.
* ["Happy birthday, sir."]
    ~ t28_slop = 2
    ~ rep(rep_t28, 1)
    He said it to the phone. The one with the lottery tickets nodded, and put the phone away carefully.
    SCRATCH: There. That's all he wanted.
    TABLE28: Happy birthday!
* [Push the phone back across the table.]
    ~ t28_slop = 3
    The one with the lottery tickets looked at the soldier a while longer himself, and then showed him to the one in the team jacket, who'd seen him already.
-
->->

// The next time at the table, Scratch remembers what he said to the soldier.
= slop_back
{ t28_slop:
- 1:
    The one with the lottery tickets had his phone out under the edge of the table, and turned it face down when the doorman got there.
- 2:
    SCRATCH: You'll like this one.
    It was Jesus, made out of shrimp, with his arms out over a beach. Eleven thousand people had typed AMEN under it.
    SCRATCH: Somebody made that out of shrimp. By hand.
- 3:
    The one with the lottery tickets had found another soldier. He showed it to the one in the cardigan.
}
->->

= tip_offer
The one in the team jacket reached over and tucked something into the pocket of his jacket. He took it out and looked at it: a fifty, folded small. #prop: fifty
TEAM_JACKET: For looking after us.
- (tp)
<- reads_fifty(-> tp)
* [Keep it.]
    ~ tip(50)
    ~ rep(rep_t28, 1)
    TABLE28: Hear, hear!
* [Give it back.]
    ~ rep(rep_t28, -1)
    TEAM_JACKET: Your loss, big fella.
    He took it back without any offence at all. It went into the next round.
* [Put it in the bartender's jar on the way past.]
    ~ rep(rep_staff, 1)
    The bartender saw, and put the jar back under the bar where the next man couldn't get at it.
- -> topics

= standing
~ pass(4)
He stood at the end of the table with his arms folded. They talked around him, and at him, and about him while he was standing there.
TABLE28: He's a stander.
TEAM_JACKET: The last one was a leaner. Leaned on the jukebox all night. We liked him.
HEARING_AID: He owed me twenty.
SCRATCH: Look at him. Stands like he's got a pool cue up his arse.
HEARING_AID: Arse.
- (st)
* ["Anything you need, you let me know."]
    TABLE28: Oh, we will.
    ~ rep(rep_t28, 1)
* {count_body.count_glasses > 0} ["You're over the limit. All of you." #check: manual:cha 10]
    -> cut_off
* ["What do you know about the rats?"]
    ~ rats_heard += h_no_rats
    SCRATCH: What rats?
    TABLE28: There's no rats here.
    Something under the table crunched a fry.
    ~ knows += t28_rat
// A stander who never sits: they'll have a name for that by close (closing.ink).
+ (left_standing) [Leave them to it.]
    ~ pass(1)
    -> hub
- ~ pass(2)
-> st

= cut_off
~ pass(3)
{ passed:
    MANUAL: A licensee must not permit a person to become intoxicated on the premises. They were intoxicated at two o'clock.
    The table went quiet, and then all five of them laughed.
- else:
    It came out wrong, going up at the end.
}
TABLE28: Cut off!
TEAM_JACKET: Son, I've been cut off by better than you. I've been cut off by a judge.
Behind the bar, the bartender had put down his rag.
BARTENDER: Not them.
The bartender said it to the doorman, quietly, across the room, and went back to the rag.
BARTENDER: Junior's rule, Door. Table 28 don't get cut off. They paid for half this carpet.
~ rep(rep_t28, -2)
~ rep(rep_owner, -1)
MANUAL: The rule is still the rule.
FATHER: The rule is whoever pays for the carpet. I told you.
-> hub

= again
~ pass(2)
// he ran across the room since they last had him over (toys.ink, toy_legs): table 28 saw (Claude's draft)
{ ran_room > ran_seen:
    ~ ran_seen = ran_room
    TABLE28: {stopping:Where's the fire, Big Fella?|Slow down! You'll spill somebody!|There he goes again!}
}
// What he said to Scratch's soldier (the_phone).
{ t28_slop > 0 && slop_back == 0:
    -> slop_back ->
}
{ pull_table >= 3:
    {stopping:
    - They made room for him before he got there.
    - Somebody hooked a chair out for him with a boot.
    - TABLE28: {shuffle:There he is!|Sit down, you're blocking the hockey!}
    }
- else:
    TABLE28: {shuffle:He's back!|The doorman!|Big fella!}
}
{
- rep_t28 >= 3:
    TEAM_JACKET: {stopping:Sit, sit. You're one of us now, God help you.|Sit, sit.}
- rep_t28 <= -2:
    They went on talking and didn't look up.
}
- (t_opts)
<- moves(t28)
+ [Sit down with them. #hand: {at_t28.sit > 0:drink}]
    { at_t28.sit == 0:
        -> sit
    - else:
        -> another
    }
// The late news has set them off (room.ink, t28_news).
+ {t28_off > 0} ["What's all this?"]
    -> t28_news
+ {walter_alive() && knows ? t28_rat} [Ask after Walter.]
    ~ pass(2)
    ~ rats_heard += h_walter
    { walter == 3:
        SCRATCH: He came out and didn't want his fry. He always wants his fry.
        SCRATCH: Went straight back in the wall.
        FATHER: You know why.
    - else:
        SCRATCH: {shuffle:He's in the wall. He'll be out when the fries come, you can bet on it.|Having a lie-down.|Busy. Counting his winnings.}
    }
    -> again_loop
+ {fries == 1 && walter_alive() && knows ? t28_rat} [Put the basket of fries under the table for Walter.]
    ~ pass(2)
    ~ fries = 2
    ~ rat_favour++
    ~ rep(rep_t28, 2)
    He put the basket down on the carpet under the table, by the hole in the baseboard, without saying anything about it.
    The one who scratched lottery tickets looked at him, and then at the table, and didn't say anything either.
    TABLE28: Look at that. Look at that.
    -> again_loop
+ ["How's everybody doing?"]
    ~ pass(2)
    ~ how_doing++
    { how_doing == 1:
        ~ rep(rep_t28, 1)
        TABLE28: {shuffle:Never better!|Thirsty!|Cheated by the referees!|Dying!}
        TEAM_JACKET: Nobody asks us that. The last one never asked us that.
        -> again_loop
    }
    {
    - walter == 0:
        Nobody answered. The one who'd fed Walter looked at the hole in the baseboard.
    - walter == 3:
        SCRATCH: Walter didn't want his fry.
        He was holding the fry, cold, between two fingers.
    - dennis_gone():
        TABLE28: Down one!
        TEAM_JACKET: Dennis has been called home. It happens to the best of us. It happens to Dennis about twice a week.
    - fam ? pool_fight:
        TABLE28: Better than the pool table!
    - cardigan_go == 1:
        CARDIGAN: I've been thinking, that's all.
        The others looked at him. He didn't say what about.
    - pull_table >= 3:
        TABLE28: Same as you!
    - else:
        TABLE28: {shuffle:Same as an hour ago!|Still thirsty!|Ask us again at last call!}
    }
    -> again_loop
// RAINCOAT's message, the one he said he'd pass on when he told her Dennis wasn't here (door.ink).
+ {arrivals ? wife_lied && not dennis_gone()} [Tell Dennis about the dog.]
    ~ pass(2)
    ~ dog_told = true
    ~ room_count--
    ~ rep(rep_t28, 1)
    He bent down by the big glasses and said it quietly, the way she'd said it: the dog's been sick on the bed.
    Dennis didn't say anything for a second. Then he put his coat on, and finished his drink with it half on, and went.
    SCRATCH: That dog's been dead since the flood.
    # done: dog
    -> again_loop

= again_loop
{ due(): -> hub }
-> t_opts

// The first time back at the table after Dennis went home, however he went.
= after_dennis
~ pass(2)
The gap where Dennis had been sitting was still there. Nobody had moved into it. His glass was still in front of it, {arrivals ? wife_in && not ev_wife_inside:half full|empty}.
{
- dog_told:
    TABLE28: Here's the vet!
    TEAM_JACKET: Dennis says thank you. Dennis won't say it himself, but he says it.
- arrivals ? wife_told:
    TABLE28: Here's the traitor!
    TEAM_JACKET: Nothing personal. Dennis would have done the same. Dennis has done the same, to me.
- ev_wife_inside:
    TABLE28: Here's the man who wasn't on the door.
    TEAM_JACKET: Nothing personal. But somebody has to be on the door, son. That's the whole job.
- else:
    TABLE28: Here's the man who let her in.
    TEAM_JACKET: Nothing personal. Dennis would say the same. Dennis will say the same, on Thursday, when he's allowed out.
}
-> again

= after_walter
~ pass(1)
None of them looked up. The fry basket in the middle of the table had gone cold, and nothing had been dropped under it.
-> again

= after_poison
~ pass(1)
SCRATCH: Walter hasn't come out.
He said it to the table, not to the doorman.
SCRATCH: He always comes out when the fries come.
FATHER: You know why.
-> again


// RAINCOAT came in while nobody was on the door.
=== ev_wife_inside ===
~ arrivals += wife_in
~ knows += dennis
~ room_count--
A woman in a long raincoat walked across the carpet from the front door, past the empty stool, straight to table 28, and stood behind the one in the big glasses without saying anything. #look: raincoat
Nobody had been on the door.
* [Go over.]
    ~ pass(2)
    ~ wife_stopped = true
    ~ rep(rep_t28, -1)
    { here == t28:
        He moved, and she looked at him.
    - else:
        ~ here = floor
        He was halfway there when she looked at him. #look: raincoat
    }
    RAINCOAT: Don't.
    She'd been coming in here after Dennis since before he was born.
    He stopped.
* (let_her) [Leave it. She's not trouble.]
    ~ pass(1)
- The one in the big glasses put his coat on, finishing his drink with it half on, and followed her out. Table 28 went on talking over the place where he'd been sitting.
{ not wife_stopped:
    At the door she stopped beside the empty stool and looked at the doorman.
    RAINCOAT: Thirty years he's sat at that table. You'd think one of you would stop him at the door.
}
TABLE28: Where was the door?
TEAM_JACKET: Nothing personal, son. But where was the door.
~ rep(rep_t28, -1)
-> carry_on
