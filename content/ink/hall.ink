// The back hall: the men's, the women's, the single washroom with a lock that works, a dead
// payphone, and the hotel door at the end. Half the plot is in the bathroom checks
// (bible/02_SYSTEMS.md). The kid talks here, if he talks anywhere, and that's where THE KID
// voice comes from (pull_kid).

// Where they are is in main.ink (kid_at, sister_at, vape_at). The kid locks himself in by twenty to
// ten if he's left alone by the jukebox (sim.ink), or straight away if the doorman pushes him there.
=== function kid_locked_in()
~ return kid_at == s_single && not fam_done

=== function vape_in_mens()
~ return vape_at == s_bar && not fam_done && clock >= 1290 && not at_hall.vape_line

=== function sister_in_womens()
~ return sister_at == s_rail && not fam_done && fam !? dad_told && clock >= 1320 && not at_hall.sister_sink

=== function hivis_on_stairs()
~ return arrivals ? hivis_out && arrivals !? hivis_hotel && arrivals !? hivis_in && hotel_door && clock >= 1320 && not at_hall.hivis_stairs


=== at_hall ===
~ here = hall
{ due(): -> hub }
{ at_hall == 1:
    The back hall ran from the end of the pool table to the hotel door. The men's, the women's, and a single washroom with a lock that worked, which was the one that mattered. A payphone on the wall with no dial tone, and around it, in pen and marker, forty years of phone numbers.
- else:
    {shuffle:
    - The back hall. Bleach, and the payphone.
    - He went down the back hall, past the payphone.
    - The back hall, three doors and a dead phone.
    }
}
{ kid_locked_in():
    The single washroom was locked. The little window in the handle said OCCUPIED.
}
{ reprops ? rp_hotel && hotel_door:
    ~ reprops -= rp_hotel
    The wedge was back under the hotel door at the end of the hall. Through the gap, whoever was on the front desk had his view of the bar's TV back.
}
-> h_opts

= h_opts
{ due(): -> hub }
<- moves(hall)
+ [Check the men's.]
    -> mens
+ [Knock on the women's.]
    -> womens
+ {kid_locked_in()} [Knock on the single washroom.]
    -> single
+ {not kid_locked_in()} [Check the single washroom.]
    -> single_empty
* [Read the wall around the payphone.]
    -> payphone
// The inspector's on the fourteenth (room.ink).
* [Look at the extinguisher at the end of the hall.]
    -> extinguisher
+ {hivis_on_stairs()} [Somebody's coming down the hotel stairs.]
    -> hivis_stairs
+ {hotel_door} [Kick the wedge out from under the hotel door.]
    ~ pass(1)
    ~ hotel_door = false
    ~ hotel_shut_at = clock
    He kicked the wedge out. The door eased shut on its closer and latched. On the other side, somebody who'd been watching the hockey through the gap said one word to nobody.
    WRONGMAN: The night clerk will wedge it again the minute you're gone. That's every door.
    -> h_opts
// The bartender told him the night clerk's name, and why he props it (bar.ink). Don't tell him I told you.
* {knows ? terry && not terry_asked} [Go through and ask Terry to leave the door shut.]
    -> night_clerk


// ------------------------------------------------------------------ the men's

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
    ~ pass(3)
    ~ fam += vape_ejected
    ~ vape_out_at = clock
    ~ vape_returned = false
    ~ vape_seen = false
    ~ move(vape_at, s_lot)
    ~ heat(-2)
    He took him by the back of the hoodie and walked him down the hall, past the pool table and the jukebox, and out the front door onto the gravel, and the boyfriend talked the whole way and none of it was words. #sfx: door
    { sister_at == s_rail:
        His girlfriend watched it happen from the rail by the pool table. She didn't go after him.
        DRIVER: Thank you.
        She said it to the carpet.
        ~ rep(rep_kids, 1)
    - else:
        ~ rep(rep_kids, -1)
    }
* [Take it off him and flush it.]
    ~ pass(2)
    ~ heat(1)
    ~ rep(rep_kids, 1)
    He held his hand out. The boyfriend looked at it for a long time and then put the little bag in it, and the doorman dropped it in the bowl and flushed, and they both watched it go.
    VAPE: that was SIXTY bucks
    VAPE: bro. that was sixty bucks. you owe me sixty bucks
    FATHER: Now he's broke and angry instead of high and angry. That's your call. It's not a good one or a bad one. It's just yours.
* ["Not in here. Not tonight." Walk away.]
    ~ pass(1)
    ~ heat(2)
    ~ rep(rep_kids, 1)
    VAPE: yeah yeah yeah. ok chief
    He was still doing it when the door swung shut.
    FATHER: You just left a lit match in the room.
* [Say nothing and walk out.]
    ~ pass(1)
    ~ heat(3)
    ~ incident -= inc_drugs
    WRONGMAN: In the story he saw it too, and said nothing too. That's how the story starts.
- -> h_opts


// ------------------------------------------------------------------ the women's

= womens
~ pass(2)
He knocked and pushed the door open a hand's width and said "Door staff," to the tiles.
{ sister_in_womens():
    -> sister_sink
}
{ stopping:
- Nobody answered. Two stalls, both doors open. A sign on the mirror in the bartender's handwriting: PLEASE DO NOT FLUSH ANYTHING. WE MEAN ANYTHING.
- Nobody. A tap was running. He went in and turned it off.
- Empty.
}
-> h_opts

= sister_sink
DRIVER: One second, please.
She was at the sink with the cold tap running over her wrists. She didn't turn round. She looked at him in the mirror.
DRIVER: He saw me. He looked right at me, and went back to his shot.
{ knows !? kid_why:
    DRIVER: Our mom's in the hospital in town. Since this morning. They don't know what it is yet. He's her husband, and he doesn't know. Or he knows, and he's playing pool.
    ~ knows += kid_why
    ~ knows += bigman_dad
}
// HUTCH: The sister in the women's. What does someone say to a doorman when she's been sent to get her father out of a bar and he won't come?
* ["Want me to tell him?"]
    DRIVER: Would you.
    It wasn't really a question. It was a thing she'd stopped expecting from anyone.
    ~ fam += sister_fetched
    # task: fetch :: Tell the big man at the pool table about his wife.
* ["Give him a minute."]
    ~ heat(1)
    DRIVER: He's had since six this morning.
    She turned the tap off, and went back out to the rail, and stood closer to the pool table than she had been.
* ["Go home. He'll come or he won't."]
    DRIVER: That's what my mom says.
    She dried her hands on her jeans and went out past him. She didn't go home.
    ~ rep(rep_kids, -1)
- -> h_opts


// ------------------------------------------------------------------ the single washroom

= single_empty
~ pass(2)
{ stopping:
- The single washroom was empty. It smelled of bleach, and under the bleach, of whatever the bleach was for. A lock that worked, a mirror bolted to the wall, and a shelf over the sink that somebody had wiped clean recently, which in a bar washroom is its own kind of evidence.
- Empty. The shelf wiped clean again.
- Empty.
}
-> h_opts

= single
~ pass(1)
He knocked.
HOODIE: occupied
// The condition he let the kid in on (door.ink).
{ kid_terms == 2 && single == 1:
    HOODIE: you said where you can see me
    HOODIE: you can see the door
}
- (kd)
* ["It's the door. You all right in there?"]
    ~ pass(1)
    HOODIE: yeah
    Then, after a while, closer to the door:
    HOODIE: is he still out there
    { knows ? bigman_dad:
        He knew who he meant.
    - else:
        He didn't know who he meant. Then he did. The big man at the pool table, who hadn't looked at the jukebox once all night.
        ~ knows += bigman_dad
    }
    -> kd
* [Slide down the wall and sit on the carpet with your back to the door.]
    -> sit_outside
* ["You've got two minutes, then I open it."]
    -> two_minutes
* [Open it with a coin.]
    -> coin
+ (left_be) [Leave him be.]
    ~ pass(1)
    { left_be == 1:
        ~ kid_ease++
    }
    -> h_opts

= sit_outside
~ pass(5)
He sat down on the carpet in the back hall, with his back against the washroom door and his legs out across the hall, so that anyone going to the men's had to step over them.
He didn't say anything. The jukebox came through the wall. Somebody at the pool table swore at a shot.
After a while the lock clicked. Nobody opened the door. It was just unlocked.
WRONGMAN: That's an invitation. In the story nobody ever got one.
* [Stay where you are.]
    ~ pass(5)
    ~ pull_kid++
    He stayed where he was. After another while the kid spoke through the door, low, close to it, as if he was sitting on the floor on the other side of it too.
* [Go in.]
    ~ kid_ease--
    He went in and shut the door behind him. The kid was sitting on the closed lid of the toilet with his hood up and his phone face down on his knee. He wasn't doing anything. That was the thing about him. He never seemed to be doing anything.
- -> kid_talk

= two_minutes
~ pass(2)
HOODIE: ok
Two minutes later, to the second, the lock clicked and the kid came out past him without a word and went back to the jukebox. His eyes were red. He hadn't been doing anything in there. That was the thing about him.
~ kid_out = true
~ move(kid_at, s_jukebox)
~ rep(rep_kids, -1)
FATHER: Good. Rules.
-> h_opts

= coin
~ pass(1)
~ rep(rep_kids, -2)
He turned the lock from the outside with a dime, the way every doorman learns in his first month, and opened the door.
The kid was sitting on the closed lid with his hood up and his phone face down on his knee. He wasn't doing anything.
HOODIE: what the fuck man
MANUAL: Staff may enter a locked washroom where there is reasonable concern for a patron's safety.
HOODIE: i'm not doing anything. i'm sitting
* ["Sorry. I had to check."]
    HOODIE: whatever
    He got up and went past the doorman, back to the jukebox.
    ~ kid_out = true
    ~ move(kid_at, s_jukebox)
    -> h_opts
* [Stay. Lean on the sink.]
    He leaned on the sink. The kid looked at him, and then at his phone, and then at the floor, and seemed to decide that the doorman was going to be there whether he liked it or not, like weather.
    -> kid_talk

= kid_talk
~ fam += kid_opened
~ fam += kid_found
~ knows += bigman_dad
// HUTCH: The kid talks, for once. THE KID voice comes out of this scene. How do nineteen-year-olds you've known actually talk when they finally do?
HOODIE: i'm not high
HOODIE: everybody thinks i'm high. i just haven't slept
{ kid_terms == 1:
    HOODIE: and i didn't drink. you said
}
- (kt)
* ["When did you last sleep?"]
    ~ pass(3)
    ~ pull_kid++
    HOODIE: monday i think
    HOODIE: she was bad all night. we called the ambulance at like six. then we were at the hospital all day. they don't tell you anything. you just sit there
    ~ knows += kid_why
    { father_misread:
        The Father had looked this kid in the eye at the door and said he was on something. The Father had been sure.
        The Father didn't say anything now.
        WRONGMAN: The wrong man was the one doing the reading.
    }
    -> kt
* [{knows ? kid_why:"How's your mom?"|"What's going on?"}]
    ~ pass(3)
    ~ pull_kid++
    ~ knows += kid_why
    HOODIE: they think it's her heart. or they thought that and now they don't know. she's fifty-one
    HOODIE: she told us to come get him. she said he'd want to know. she said he'd want to be there
    HOODIE: i don't think he'd want to be there
    -> kt
* ["Why'd they send you in, and not your sister?"]
    ~ pass(2)
    ~ pull_kid++
    HOODIE: cause he won't make a scene with me. with her he makes a scene. with kyle he'd, like. kyle would end up outside
    HOODIE: i'm the one who doesn't say anything. so they thought if i said something he'd listen
    HOODIE: i haven't said anything
    -> kt
* ["My old man drank."]
    -> own_father
// He heard it leaking out of the earbuds at the door, when he made the kid take them out (door.ink).
* {fam ? earbuds_out} ["What were you listening to, at the door?"]
    ~ pass(2)
    ~ pull_kid++
    HOODIE: her playlist
    HOODIE: my mom's. it's on the family account. she made it for the car so we'd stop fighting about the aux
    HOODIE: i've had it on since the ambulance
    -> kt
* {fries == 1} [Give him the fries.]
    ~ fries = 2
    ~ pull_kid++
    He gave him the basket. The kid looked at it, and then ate every one of them, fast, without looking up, the way you eat when you'd forgotten you were hungry until there's food in front of you.
    HOODIE: thanks
    -> kt
* {pull_kid >= 2} ["What do you want to do?"]
    -> kid_decides
+ {pull_kid < 2} [Leave him be.]
    ~ kid_out = true
    ~ move(kid_at, s_jukebox)
    He left him there. When he looked back from the end of the hall, the kid was back by the jukebox.
    -> h_opts

= own_father
~ pass(4)
~ pull_kid++
He hadn't meant to say it. It came out the way things come out in bathrooms.
HOODIE: like drank drank?
* ["Twenty years. Then he stopped."]
    ~ claims += said_father_stopped
    HOODIE: did it help
    * * ["It helped everybody else."]
        ~ claims += said_helped_others
        HOODIE: that's something i guess
    * * ["No."]
        ~ claims += said_didnt_help
        The kid nodded like that was the answer he'd been expecting his whole life.
    * * ["I don't know. He died before I worked it out."]
        ~ claims += said_father_dead
        HOODIE: sorry
        HOODIE: that's shit
    - - FATHER: That's mine to tell. Not yours.
* ["He worked doors. Like this."]
    ~ claims += said_father_doors
    HOODIE: so you're like him
    * * ["No."]
        ~ claims += said_not_like_him
        HOODIE: ok
        The kid didn't believe him, and didn't seem to mind.
    * * ["I'm trying not to be."]
        ~ claims += said_trying_not
        HOODIE: same
    - - FATHER: ...
- -> kid_talk.kt

= kid_decides
~ pass(2)
HOODIE: i don't know
HOODIE: i want to go home and sleep. i want my mom to not be in the hospital. i want him to just come, without me having to make him
* ["I'll tell him. You don't have to."]
    HOODIE: ok
    HOODIE: ok. thanks
    ~ kid_out = true
    ~ move(kid_at, s_jukebox)
    ~ fam += sister_fetched
    # task: fetch :: Tell the big man at the pool table about his wife.
    He came out of the washroom behind the doorman and went and stood by the jukebox again, closer to the pool table this time.
    -> h_opts
* ["You tell him. I'll stand right there."]
    -> kid_tells(true)
* ["You tell him. On your own. You can."]
    -> kid_tells(false)
* ["Go home and sleep. I'll make sure he knows."]
    ~ kid_out = true
    ~ fam += kid_home
    ~ fam += sister_fetched
    ~ move(kid_at, s_truck)
    # task: fetch :: Tell the big man at the pool table about his wife.
    { hotel_door:
        He went out through the hotel door at the end of the hall, and round the building in the rain to the pickup, so he wouldn't have to walk past the pool table.
    - else:
        He went out the front, with his hood up, the long way round the room so he wouldn't have to walk past the pool table, and across the lot to the pickup.
    }
    The pickup didn't leave. Home was a word. His sister had the keys.
    -> h_opts

= kid_tells(with)
~ pass(3)
~ kid_out = true
~ move(kid_at, s_rail)
~ fam += dad_told
He went out to the pool table with his hood down, for the first time all night. {with:The doorman went with him, and stood a step behind him where the big man could see him.|The doorman stayed at the end of the hall and watched.}
The big man was lining up a shot. The kid stood at the end of the table, in the way of it, until his father had to look up.
HOODIE: mom's in the hospital
He said it too quietly, and then he said it again, loud enough. The buddy stopped chalking his cue.
{ with || pool_heat < 5:
    The big man looked at his son for a long time. Then he laid his cue down across the table, in the middle of the game, which is a thing people don't do.
    BIGMAN: Where.
    HOODIE: in town. since this morning. we've been trying to call you
    The big man took out his phone and looked at it and put it away again, without saying anything about what he saw on it.
    -> kid_leave
}
The big man looked at the table.
BIGMAN: I'll come by after, bud.
The kid stood there. Then he reached over and took the cue out of his father's hands, and laid it down across the balls.
{ pull_kid >= 3:
    HOODIE: now
    The big man looked at the cue on the table, and then at his son, as if he'd never seen either of them before. Then he went.
    -> kid_leave
}
BIGMAN: Don't.
The kid let go of the cue. He went out the front door into the rain without looking back, and the big man picked the cue back up.
{ sister_at == s_rail:
    His sister went after him{indoors(vape_at):, and the boyfriend after her}.
}
Out in the lot the pickup's lights came on, and after a minute it went.
~ fam += dad_stayed
~ fam_done = true
~ family_gone()
# done: fetch
~ rep(rep_kids, 1)
FATHER: That's what I'd have done. Picked the cue back up.
-> hub

= kid_leave
~ fam += dad_went
~ fam_done = true
# done: fetch
{ sister_at == s_rail:
    The big man went to his daughter at the rail and said something to her that nobody else heard. {indoors(vape_at):The three of them went out the front door together, and the boyfriend after them, holding the door.|They went out the front door together, the three of them.}
- else:
    The big man went out the front door with his son, into the rain, without his jacket. Through the glass the doorman watched the pickup's door open, and the young woman get out, and the three of them stand in the headlights. Then they all got in.
}
~ family_gone()
~ room_count--
~ rep(rep_kids, 2)
The pickup pulled out onto the highway toward town. #sfx: door
BUDDY: He left it. He left his money.
Four twenties under the rail. The buddy looked at them for a while, then took them to the bar and put them in the tip jar, all four, and left too.
~ room_count--
FATHER: He went. I wouldn't have.
-> hub


// ------------------------------------------------------------------ the payphone

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


// ------------------------------------------------------------------ the night clerk

// Terry, at the front desk on the other side of the hotel door, with the hockey on.
= night_clerk
~ pass(4)
He went through the hotel door. On the other side was the front desk, a counter with a bell on it and a key board with most of the keys still on their hooks, and the night clerk on a stool behind it with his chin on his fist, {hotel_door:watching the bar's TV through the gap where the door had been propped|looking at the shut door the way you'd look at a TV somebody had switched off}. #portrait: terry
{
- terry_signed == 1:
    TERRY: Oh, hey, twelve. You signed. Something wrong? What's the score?
- terry_signed == -1:
    TERRY: Oh. Twelve. Something wrong? What's the score?
- else:
    TERRY: Oh, hey. Something wrong? What's the score?
}
// He signed Terry's key book at quarter past five (walk.ink): Terry likes people who sign.
* ["Residents come down that way. I can't count them." #check: father:cha 11 {terry_signed == 1:2|{terry_signed == -1:-1|0}}]
    { passed:
        TERRY: Oh, they're only going to the bar, pal.
        TERRY: Sure, sure. You bet. I'll get the game on my phone, eh. It runs a minute behind, but.
        ~ terry_asked = true
    - else:
        TERRY: Oh, no no. They live here, pal. That's what the door's for.
        {hotel_door:He went back to the hockey|He went back to looking at the door}. He hadn't been rude about it. He just wasn't going to.
    }
* ["She says you prop it for the TV."]
    TERRY: Oh. She told you that.
    He looked past the doorman down the hall toward the bar, for a while.
    TERRY: Sure. Door stays shut, then. You tell her thanks from me.
    ~ terry_asked = true
    ~ rep(rep_staff, -1)
    FATHER: She told you not to tell him she told you. You told him.
* (never_mind) [Never mind.]
    TERRY: Okay, pal. You know where I am.
- { terry_asked:
    ~ hotel_door = false
    ~ hotel_shut_at = clock
    He pulled the door to behind him on the way back, and it latched, and for the rest of the night nobody propped it.
}
-> h_opts


// ------------------------------------------------------------------ HI-VIS on the back stairs

= hivis_stairs
~ pass(2)
The hotel door opened and HI-VIS came through it in his sock feet, without the vest, with a can of his own beer in his hand, the way a man comes down to his own kitchen.
HI-VIS: Oh. It's you.
HI-VIS: You said I could come down after. It's after.
* ["Leave the can and go round the front. I'll let you in."]
    HI-VIS: Round the front. In my socks. In the rain.
    He looked at the can, and at the doorman, and went back up the stairs. Five minutes later he was at the front door in his boots with no can, and the doorman let him in.
    ~ arrivals += hivis_in
    ~ count_in++
    ~ room_count++
    ~ rep(rep_staff, 1)
    FATHER: That's the door. Everybody through it. Even the ones who live here.
* ["Fine. Leave the can."]
    He finished it in one go and set the empty on top of the payphone and went through into the bar.
    ~ arrivals += hivis_hotel
    ~ uncounted++
    ~ room_count++
* ["Back upstairs. Not tonight."]
    HI-VIS: I pay rent here.
    HI-VIS: I pay rent here, and there's a bar in my building, and I'm not allowed in it.
    He went back up. Not fast.
    ~ rep(rep_owner, -1)
- -> h_opts
