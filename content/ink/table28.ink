// Table 28. Five high-functioning alcoholics in the front window, every day but Sunday.
// One voice most of the time, with small individual quirks. Loud. They own the place.
// (Hutch's, DECIDED. The five individuals below are Claude's placeholders.)
//
// Sitting down with them is how he learns them. Drinking with them is how their voice starts
// to get into his head (pull_table). Their code: loyalty, generosity, we were here first.

=== at_t28 ===
~ here = t28
{ due(): -> hub }
{ at_t28 == 1: -> first }
{ arrivals ? wife_in && at_t28.after_wife == 0: -> after_wife }
{ walter == 0 && at_t28.after_walter == 0: -> after_walter }
{ poison && knows ? t28_rat && walter_alive() && rat_scene && at_t28.after_poison == 0: -> after_poison }
-> again

= first
Five faces turned up at him at once, like a jury.
// HUTCH: Table 28 is yours. What do they actually talk about on a Wednesday at eight? What's the first thing they say to a new doorman? Give each of the five one quirk from life (changed enough).
TABLE28: Here he is.
TABLE28: Look at the size of him.
TEAM_JACKET: They're getting bigger. The last one was a big lad too. Didn't help him.
HEARING_AID: Him.
TABLE28: Where'd they find you?
-> where_from

= where_from
* ["Up island."]
    ~ claims += said_up_island
    TABLE28: Up island!
    They said it like it explained a great deal, none of it good.
    SCRATCH: Everyone's from up island. I'm from up island.
    ~ rep(rep_t28, 1)
* ["I worked a door in the city. Ten years."]
    ~ claims += said_city_door
    TABLE28: Which one?
    * * ["You wouldn't know it."]
        TEAM_JACKET: Try us. We've drunk everywhere.
        He didn't. They filed that away. Table 28 filed everything away.
    * * ["The kind with a line outside."]
        TABLE28: Oooh.
        CARDIGAN: Ten years is a long time to stand outside.
        FATHER: They'll hold you to that, you know. Ten years. Somebody here knows somebody in the city.
    - - ~ rep(rep_t28, 1)
* ["Around."]
    ~ claims += said_around
    TABLE28: Around!
    TEAM_JACKET: He's from Around. I've been to Around. Terrible place.
    They laughed together, on the beat, the way a family laughs.
* ["My father worked doors."]
    ~ claims += said_father
    FATHER: Don't.
    TABLE28: Ah.
    It changed them, a little. Something went round the table.
    CARDIGAN: Here?
    * * ["Up island. A long time ago."]
        CARDIGAN: What was his name?
        * * * [Tell them.]
            ~ father_named = true
            // HUTCH: The father's name is open. When you pick it, this is where it's said out loud for the first time.
            He told them.
            Nobody at the table knew it. The one in the cardigan said it once more, to himself, quietly, like he was putting it somewhere he could find it again.
            FATHER: Now it's out.
            ~ rep(rep_t28, 2)
        * * * ["Doesn't matter."]
            CARDIGAN: It always matters.
            ~ rep(rep_t28, 1)
    * * ["All over."]
        TABLE28: A travelling man.
        ~ rep(rep_t28, 1)
- TEAM_JACKET: Well. Sit down, then. Nobody stands at this table.
-> offer

= offer
~ pass(3)
* [Sit down.]
    -> sit
* ["I'm working."]
    TABLE28: He's working!
    They thought that was very funny.
    TEAM_JACKET: The last one was working too.
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
* [Drink it.]
    ~ drink()
    ~ pull_table++
    ~ rep(rep_t28, 1)
    It was the cheap rye, with too much ice. It was fine.
    TABLE28: There he is!
    FATHER: One.
* [Nurse it.]
    He held it and didn't drink it. They noticed. They noticed everything; they'd had forty years of practice at a table in a window.
    SCRATCH: He's savouring it.
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
    // HUTCH: The rumour system in miniature: every version of the last doorman in circulation. Keep them or replace them with the kind of stories your regulars actually tell.
    TEAM_JACKET: Owner shorted his pay. Two weeks running. He walked out on a Friday with the float in his pocket.
    SCRATCH: He saw the big rat. In the keg room. Came up the stairs white as a sheet and never went back down.
    HEARING_AID: Woman.
    TABLE28: A woman!
    CARDIGAN: He let somebody in he shouldn't have. That's all. It happens to all of them eventually.
    WRONGMAN: Now that's a story.
    FATHER: They're all true. That's how a place like this works. Every story's true and none of them happened.
    -> topics
* {knows !? t28_rat} [Something moves under the table.]
    -> walter_intro
* {knows ? t28_rat} ["How long has he been coming to this table?"]
    ~ pass(2)
    SCRATCH: Walter? Longer than you.
    TEAM_JACKET: Longer than the owner.
    TABLE28: We were here first. Then Walter. Then everybody else.
    -> topics
* {pull_table >= 2} [Stay for another.]
    -> another
+ [Get up.]
    TEAM_JACKET: Don't be a stranger.
    TABLE28: He'll be back.
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
    ~ rep(rep_t28, 1)
    TABLE28: Good man.
    Walter finished his fry and went into the wall behind the table, through a hole in the baseboard the size of a fist that he'd plainly been using for years.
    ~ knows += keg_hole
* ["The owner wants them gone."]
    TABLE28: The owner!
    TEAM_JACKET: The owner's never met Walter.
    SCRATCH: The owner's never met anybody. He's in town.
    CARDIGAN: They were here before him, you know. The rats. Before the hotel, probably. It was a cannery, this, before the hotel. Fish guts in the tide under the floor. You don't get rid of rats in a building like this. You come to an arrangement.
    WRONGMAN: An arrangement.
    ~ knows += keg_hole
    -> w
* [Put a boot on him. #check: fighter 8]
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
Another rye arrived without anyone ordering it.
{ drinks >= 3:
    FATHER: {Num(drinks)}. I counted. You're counting too, or you should be.
}
The talk went round. He stopped hearing it as five men and started hearing it as one thing that happened to be sitting in five chairs. It had views. It was sure. It had been here first.
{ pull_table >= 3:
    For a moment he could hear what they'd say before they said it.
}
TEAM_JACKET: {shuffle:He's all right, this one.|You're all right.|He'll do.}
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
    TABLE28: Good man.
* [Give it back.]
    ~ rep(rep_t28, -1)
    TEAM_JACKET: Suit yourself.
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
* {count_body.count_glasses > 0} ["You're over the limit. All of you." #check: manual 6]
    -> cut_off
* ["What do you know about the rats?"]
    SCRATCH: What rats?
    TABLE28: There's no rats here.
    Something under the table crunched a fry.
    ~ knows += t28_rat
+ [Leave them to it.]
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
BARTENDER: Owner's rule. Table 28 doesn't get cut off. They paid for half this carpet.
~ rep(rep_t28, -2)
~ rep(rep_owner, -1)
MANUAL: The rule is still the rule.
FATHER: The rule is whoever pays for the carpet. I told you.
-> hub

= again
~ pass(2)
{ pull_table >= 3:
    {stopping:
    - They made room for him before he got there.
    - Somebody hooked a chair out for him with a boot.
    - TABLE28: {shuffle:There he is.|Sit down, you're blocking the TV.}
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
+ [Sit down with them.]
    { at_t28.sit == 0:
        -> sit
    - else:
        -> another
    }
+ {walter_alive() && knows ? t28_rat} [Ask after Walter.]
    ~ pass(2)
    { walter == 3:
        SCRATCH: He came out and didn't want his fry. He always wants his fry.
        SCRATCH: Went straight back in the wall.
        FATHER: You know why.
    - else:
        SCRATCH: {shuffle:He's in the wall. He'll be out when the fries come.|Having a lie-down.|Busy.}
    }
    -> again_loop
+ {fries == 1 && walter_alive() && knows ? t28_rat} [Put the basket of fries under the table for Walter.]
    ~ pass(2)
    ~ fries = 2
    ~ rat_favour++
    ~ rep(rep_t28, 2)
    He put the basket down on the carpet under the table, by the hole in the baseboard, without saying anything about it.
    The one who scratched lottery tickets looked at him, and then looked at the table, and didn't say anything either. Table 28 had never had a doorman who fed Walter.
    TABLE28: Good man.
    -> again_loop
+ ["How's everybody doing?"]
    ~ pass(2)
    TABLE28: {shuffle:Never better!|Thirsty!|Cheated by the referees!}
    -> again_loop

= again_loop
{ due(): -> hub }
-> t_opts

= after_wife
~ pass(2)
The gap where Dennis had been sitting was still there. Nobody had moved into it. His glass was still in front of it, half full.
TABLE28: Here's the man who let her in.
TEAM_JACKET: Nothing personal. Dennis would say the same. Dennis will say the same, on Thursday, when he's allowed out.
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
~ here = floor
A woman in a long raincoat walked across the carpet from the front door, past the empty stool, straight to table 28, and stood behind the one in the big glasses without saying anything.
Nobody had been on the door.
~ knows += dennis
* [Go over.]
    ~ pass(2)
    He was halfway there when she looked at him.
    RAINCOAT: Don't.
    It wasn't rude. It was the voice of someone who'd done this before, in this room, before he was born.
    He stopped.
* [Leave it. She's not trouble.]
    ~ pass(1)
- The one in the big glasses put his coat on, finishing his drink with it half on, and followed her out. Table 28 closed up the gap where he'd been sitting without a word about it.
TABLE28: Where was the door?
TEAM_JACKET: Nothing personal, son. But where was the door.
~ rep(rep_t28, -1)
-> hub
