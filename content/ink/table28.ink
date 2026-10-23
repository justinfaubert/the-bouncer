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
{dennis_gone():Four|Five} faces turned up at him at once, like a jury.
// HUTCH: Table 28 is yours. What do they actually talk about on a Wednesday at eight? What's the first thing they say to a new doorman? Give each of the five one quirk from life (changed enough).
TABLE28: Here he is!
TABLE28: Look at the size of him!
// Gary's shirt (office.ink): nobody on this island ever wore a shirt that said what he was.
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
    * * ["Up island. A long time ago."]
        CARDIGAN: What was his name? If you don't mind my asking.
        * * * [Tell them.]
            ~ father_named = true
            // HUTCH: The father's name is open. When you pick it, this is where it's said out loud for the first time.
            He told them.
            Nobody at the table knew it. The one in the cardigan said it once more, to himself, quietly, like he was putting it somewhere he could find it again.
            FATHER: Now it's out.
            ~ rep(rep_t28, 2)
        * * * ["Doesn't matter."]
            CARDIGAN: I think it always matters. To somebody.
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
He sat down. The chair was too small for him. Everything at the Sov was too small for him.
TEAM_JACKET: Get the big fella a rye.
Nobody moved, and a rye arrived anyway. The bartender put it down in front of him without a word and went back.
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
    He held it and didn't drink it. They noticed. They noticed everything; they'd had forty years of practice at a table in a window.
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
They talked. Table 28 talked the way the rain came down: all at once, from everywhere, without stopping to see if anyone wanted it.
The price of diesel. The mill, which was on its last contract, everyone knew, nobody had said. The news from the capital, which was lies, which was all lies, which one of them had read the whole of in the paper that morning and had views on.
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
    CARDIGAN: I think he let somebody in that he shouldn't have. That's all it was. It happens to all of them, sooner or later.
    WRONGMAN: Now that's a story.
    FATHER: They're all true. That's how a place like this works. Every story's true and none of them happened.
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
        He was quick for a big man. It was quick for the rat, too.
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
    The ryes kept arriving. Nobody at the table had ordered one, and nobody paid, and they kept arriving.
}
{ drinks >= 3:
    FATHER: {Num(drinks)}. I counted. You're counting too, or you should be.
}
{ at_t28.another == 1:
    The talk went round. He stopped hearing it as five men and started hearing it as one thing that happened to be sitting in five chairs. It had views. It was sure. It had been here first.
- else:
    The talk went round again, and this time he went round with it.
}
{ pull_table >= 3 && at_t28.another <= 2:
    For a moment he could hear what they'd say before they said it.
}
TEAM_JACKET: {shuffle:He's all right, this one!|You're all right, son. You're all right.|Atta boy.}
{ knows !? dennis:
    The bartender came over with a round nobody had ordered and said "Dennis, you're driving?" to the one in the big glasses, who said "Never," and everyone laughed.
    ~ knows += dennis
}
// The TABLE voice: tipping to own you.
{ at_t28.tip_offer == 0: -> tip_offer }
-> topics

= tip_offer
The one in the team jacket reached over and put something in his shirt pocket. A folded fifty.
TEAM_JACKET: For looking after us.
FATHER: That's not a tip. That's a leash.
- (tp)
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
    The bartender saw. She didn't say anything. She didn't have to.
- -> topics

= standing
~ pass(4)
He stood at the end of the table with his arms folded. They talked around him, and at him, and about him while he was standing there.
TABLE28: He's a stander.
TEAM_JACKET: The last one was a leaner. Leaned on the jukebox all night. We liked him.
HEARING_AID: Liked him.
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
    He said it. The table went quiet, and then it laughed, all five, together, for a long time.
- else:
    He said it, and it came out wrong, like a question.
}
TABLE28: Cut off!
TEAM_JACKET: Son, I've been cut off by better than you. I've been cut off by a judge.
Behind the bar, the bartender had put down her rag.
BARTENDER: Not them.
She said it to the doorman, quietly, across the room, and went back to the rag.
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
    They went on talking as if he wasn't there, which at table 28 was the same as a shout.
}
- (t_opts)
<- moves(t28)
+ [Sit down with them. #hand: {at_t28.sit > 0:drink}]
    { at_t28.sit == 0:
        -> sit
    - else:
        -> another
    }
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
    The one who scratched lottery tickets looked at him, and then looked at the table, and didn't say anything either. Table 28 had never had a doorman who fed Walter.
    TABLE28: Look at that. Look at that.
    -> again_loop
+ ["How's everybody doing?"]
    ~ pass(2)
    ~ how_doing++
    { how_doing == 1:
        ~ rep(rep_t28, 1)
        TABLE28: {shuffle:Never better!|Thirsty!|Cheated by the referees!}
        TEAM_JACKET: Nobody asks us that. The last one never asked us that.
        -> again_loop
    }
    {
    - walter == 0:
        Nobody answered. The one who'd fed Walter looked at the hole in the baseboard.
    - walter == 3:
        SCRATCH: Walter didn't want his fry.
        He said it to the table.
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
    Nobody explained. Nobody at the table seemed to think it needed explaining.
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
Nobody looked up. The fry basket in the middle of the table had gone cold and nobody had dropped anything under it.
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
    It wasn't rude. It was the voice of someone who'd done this before, in this room, before he was born.
    He stopped.
* (let_her) [Leave it. She's not trouble.]
    ~ pass(1)
- The one in the big glasses put his coat on, finishing his drink with it half on, and followed her out. Table 28 went on talking over the place where he'd been sitting.
{ not wife_stopped:
    At the door she stopped beside the empty stool and looked at the doorman, as if she was going to say something about it, and then she did.
    RAINCOAT: Thirty years he's sat at that table. You'd think one of you would stop him at the door.
}
TABLE28: Where was the door?
TEAM_JACKET: Nothing personal, son. But where was the door.
~ rep(rep_t28, -1)
-> carry_on
