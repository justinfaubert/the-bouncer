// Closing: last call at 1:30, the room cleared by two, the count and the search, the incident
// log, after-hours with the bartender, and, if the old man asked him down, the parley in the
// keg room. Then the room upstairs, the voices, and the ledger.
// Closing the room without an incident is a skill of its own, and after-hours is where the
// best writing will live (bible/02_SYSTEMS.md).

=== function pool_still()
~ return fam !? dad_went && fam !? dad_ejected && fam !? lot_scene && fam !? dad_drove

=== function hivis_still()
~ return (arrivals ? hivis_in || arrivals ? hivis_hotel) && cleared !? cl_hivis

=== function left_to_clear()
~ temp n = 0
{ pool_still() && cleared !? cl_pool:
    ~ n++
}
{ arrivals ? banned_in && cleared !? cl_banned:
    ~ n++
}
{ hivis_still():
    ~ n++
}
{ cleared !? cl_res:
    ~ n++
}
{ cleared !? cl_t28:
    ~ n++
}
~ return n

// What the bartender sees from behind the bar, for the incident log.
=== function she_saw()
~ return (inc_banned, inc_fight, inc_rat, inc_drinking, inc_poison, inc_hurt, inc_after, inc_hivis)

=== function inc_text(x)
{
- x == inc_kid_refused:
    { fam ? hoodie_refused:
        Refused entry: a young man with a photograph of his ID and not the ID. {fam ? sister_refused:Later, his sister and her boyfriend.}
    - else:
        Refused entry: a young woman and her boyfriend, looking for her father. Her brother was already inside.
    }
- x == inc_deck:
    Three people in through the deck door, not past the front. Found inside.
- x == inc_banned:
    A man from the binder, page three, NOT EVER, on the premises and served. {arrivals ? banned_in:He let him in.|He came in while nobody was on the door.}
- x == inc_rat:
    A rat, in the bar, during service, in front of customers.
- x == inc_fight:
    A fight at the pool table.
- x == inc_hivis:
    A resident from the mill crew. {arrivals ? hivis_cond:His beer held at the door.|{arrivals ? hivis_in:Let in carrying his own beer.|Refused.}}
- x == inc_wife:
    A patron's wife, looking for him, after midnight.
- x == inc_lot:
    At close: the man from the pool table, drunk, in the lot, with his keys.
- x == inc_drinking:
    Staff drinking on shift. {drinks} {drinks == 1:drink|drinks}. Him.
- x == inc_poison:
    Rat poison put down {poison_at ? t28:behind table 28|{poison_at ? kitchen:in the kitchen|in the keg room}}.
- x == inc_hurt:
    Someone hurt. {hurt > 0:Him, among others.}
- x == inc_drugs:
    A patron using drugs in the men's washroom.
- x == inc_after:
    Customers still inside after two.
}


// ------------------------------------------------------------------ 1:30 last call

=== last_call ===
~ here = bar
{ clock < LAST_CALL:
    ~ clock = LAST_CALL
}
# music: jukebox_late
# amb: room_busy
The bartender reached up and rang the brass bell over the till, twice. #sfx: bell
BARTENDER: Last call!
TABLE28: Two each!
Everybody who was going to leave started thinking about leaving. Table 28 ordered.
// HUTCH: Last call at the Sov. What really happens in a room like this when the bell goes?
{ pool_still():
    At the pool table the big man was racking again, as if he hadn't heard it.
}
{ arrivals ? banned_in:
    GOOD SHOES was still at the bar in his good coat, pleasant to everyone.
}
{ knows ? endbar_seen:
    The stool at the end of the bar was empty. The glass was still there, full.
}
FATHER: Last call's easy. It's the half hour after it that's the job.
-> clear

=== clear ===
~ here = floor
{ clock >= CLOSE_TIME && not two_called:
    ~ two_called = true
    BARTENDER: It's two.
    MANUAL: Licensed hours end at two. Every minute after that is the licensee's problem, and yours.
}
{ left_to_clear() == 0:
    -> lock_up
}
* {pool_still()} [The big man at the pool table. #loc: pool]
    -> close_pool
* {arrivals ? banned_in} [GOOD SHOES, still at the bar. #loc: bar]
    -> close_banned
* {hivis_still()} [HI-VIS, asleep on his arms at the bar. #loc: bar]
    -> close_hivis
* [The women from upstairs, finishing the bottle. #loc: bar]
    -> close_residents
* {knows ? endbar_seen} [The full glass at the end of the bar. #loc: bar]
    -> close_endbar
* [Table 28. #loc: t28]
    -> close_t28
* -> lock_up


// ------------------------------------------------------------------ the pool table, and the lot

=== close_pool ===
~ cleared += cl_pool
~ here = pool
~ pass(3)
{ fam ? dad_stayed:
    The big man was still at the pool table. He'd said he'd go after. It was after.
- else:
    The big man was racking for one more game, as if the bell hadn't gone.
}
BIGMAN: One more.
{ kids_in > 0:
    { fam ? sister_admitted:
        His daughter was at the rail with her keys in her fist.
    - else:
        His son was by the jukebox with his hood up.
    }
}
{ fam ? kids_waiting:
    Through the front window, out in the lot, the pickup's lights were still on. It had been there all night.
}
* {knows ? kid_why && fam !? dad_told} [Tell him about the hospital. Now. #check: father 7]
    ~ fam += dad_told
    { passed:
        He told him, low, at the end of the table. Nearly a day late, somebody told him.
        The big man put the cue down.
    - else:
        He told him. The big man heard it the way you hear the weather.
        BIGMAN: I know. I know she is.
        BIGMAN: What am I going to do there. Sit there.
    }
* ["We're closed. Time to go."]
    ~ pass(2)
    BIGMAN: One more.
    The doorman said it again, and the big man put the cue in the rack on the wall as if it weighed a lot.
* [Take the cue out of his hands. #check: fighter 7]
    { passed:
        He took it, gently, the way you'd take something off a table in someone else's house, and put it in the rack on the wall. The big man looked at his empty hands.
    - else:
        The big man held on. For a second they both had it. Then he let go, and his face said he'd remember that.
        ~ rep(rep_kids, -1)
    }
- -> the_lot

= the_lot
~ pass(5)
~ here = lot
~ family_in_lot = fam ? kids_waiting || kids_in > 0
~ fam += lot_scene
~ fam_done = true
~ incident += inc_lot
# amb: rain_lot
The big man got his jacket off the hook by the pool table and went out the front door into the lot, and the doorman went out behind him and stood under the light over the door.
{ family_in_lot:
    He didn't go to the pickup.
}
He went to his own truck, a work truck with a toolbox across the bed, parked nose-in by the beer store. He got his keys out, and dropped them in the gravel, and picked them up.
{
- fam ? kids_waiting:
    Across the lot the pickup's headlights came on full. The driver's door opened, and his daughter got out and stood in the rain and didn't come any closer.
- kids_in > 0:
    His kids had come out behind him and stood under the awning. Nobody said anything.
}
~ room_count -= kids_in + 2
~ kids_in = 0
FATHER: I drove home drunk for twenty years. Nobody ever took my keys. I used to think that was respect.
* [Take his keys. #check: father 8]
    { passed:
        He went across the gravel and stood in front of him and held out his hand. The big man looked at the hand for a long time. Then he put the keys in it.
        -> keys
    - else:
        He held out his hand. The big man looked at it and said no. He said it quietly, which was worse than if he'd shouted.
        -> keys_refused
    }
* {family_in_lot} [Walk him to his daughter's truck.]
    -> walk_him
* [Let him go.]
    -> drives

= keys_refused
* [Take them anyway. #check: fighter 7]
    { passed:
        He took the big man's wrist and opened his hand and took the keys out of it, and the big man let him, the way a man lets you when he's glad somebody finally did.
        -> keys
    - else:
        The big man's elbow came round, a shove more than a swing, and the doorman went back a step into a puddle, and the keys went into the big man's pocket. #sfx: hit
        ~ hurt++
        ~ incident += inc_hurt
        -> drives
    }
* {family_in_lot} [Walk him to his daughter's truck.]
    -> walk_him
* [Let him go.]
    -> drives

= walk_him
He put a hand flat on the big man's back, between the shoulders, and walked him across the gravel to the pickup, and the big man let himself be walked.
-> to_pickup

= keys
~ took_keys = true
{ family_in_lot:
    -> to_pickup
}
The big man stood there in the rain without his keys. Then he started walking, along the shoulder of the highway toward town, and the doorman watched him until the dark had him.
He put the keys behind the bar, in the drawer with the lost-and-found, for the morning.
FATHER: Nobody ever did that for me.
FATHER: I'd have hit anybody who tried.
-> clear

= to_pickup
~ fam += dad_went
# done: fetch
The daughter opened the passenger door for him and he got in. {fam ? hoodie_admitted || fam ? via_deck:The kid in the hoodie got in beside him, in the middle, where he'd have sat when he was small.}
The pickup pulled out of the lot, slowly, onto the highway toward town.
{ took_keys:
    He had the big man's keys in his hand. He put them behind the bar, in the drawer with the lost-and-found, for the morning.
    FATHER: Nobody ever did that for me.
    FATHER: I'd have hit anybody who tried.
- else:
    FATHER: You walked him to it. That's more than carrying a message.
}
-> clear

= drives
~ fam += dad_drove
He got into the work truck. It took him three tries to get the door shut. The lights came on and it backed out, slowly, the way a drunk man drives when he knows he's drunk, and turned onto the highway toward town.
{ family_in_lot:
    The pickup pulled out after him and followed a hundred yards back, all the way to the bend.
}
MANUAL: A licensee who knowingly allows an intoxicated patron to drive may be held liable.
WRONGMAN: Everybody in the story drove home. Everybody always does, until the one who doesn't.
-> clear


// ------------------------------------------------------------------ everybody else

=== close_banned ===
~ cleared += cl_banned
~ pass(5)
GOOD SHOES had had six drinks, and they'd changed him the way drink changes men like that. He'd got more polite. He was telling {cleared ? cl_res:the bartender|the woman in slippers} about property values.
GOOD SHOES: One more. For the road. And one for the lady, and one for the staff.
BARTENDER: We're closed.
She said it to the till.
GOOD SHOES: I was talking to the doorman.
- (cb)
* ["You heard her." #check: father 7]
    { passed:
        He said it the way you'd tell someone the time. GOOD SHOES looked at him and did the arithmetic again, the same as at the door, and got the same answer.
        GOOD SHOES: Goodnight, then. Goodnight, all.
        He put a twenty on the bar for the bartender. She left it there.
    - else:
        GOOD SHOES: I heard her. I'm asking you.
        -> cb
    }
* [Walk him out. #check: fighter 6]
    { passed:
        He took the coat off the stool and held it open for him, which is a thing a man can't refuse without looking like a fool, and walked him to the door in it. #sfx: door
    - else:
        GOOD SHOES: Don't touch me. I know the owner.
        He said it loudly enough that table 28 turned round. The doorman walked him out anyway, with the man talking the whole way, and it took three times as long as it should have. #sfx: door
        ~ rep(rep_t28, 1)
    }
* ["One more. Then you go."]
    ~ rep(rep_staff, -2)
    ~ pass(10)
    The bartender looked at the doorman for a long time, and then she poured it and slid it down the bar so it stopped in front of GOOD SHOES without her having to go near him.
    He drank it slowly. Then he went.
- -> clear

=== close_hivis ===
~ cleared += cl_hivis
~ pass(3)
HI-VIS was asleep at the bar with his head on his arms and his vest folded under his cheek.
BARTENDER: Room eleven.
- (ch)
* [Wake him and walk him up.]
    ~ pass(8)
    ~ rep(rep_staff, 1)
    He walked him up the back stairs to eleven. The mill crew's rooms were all on the second floor, doors open, a card game going in one of them with the TV on and nobody watching it. Somebody at the card table said "There he is," and HI-VIS said "Here I am," and went in and sat down and was dealt a hand.
* [Wake him and point him at the stairs.]
    ~ pass(2)
    He went. He found the stairs on the second try.
* [Leave him. He lives here.]
    BARTENDER: I'm not locking up with him in here.
    -> ch
- -> clear

=== close_residents ===
~ cleared += cl_res
~ pass(3)
{ slippers_upstairs:
    The one who'd stayed with the bottle finished it and went up through the hotel door in her slippers, carrying the wine glass, which the bartender allowed because it always came back.
- else:
    The two women from upstairs had finished the bottle. They went up through the hotel door in their slippers, one holding the other's elbow, carrying the wine glasses, which the bartender allowed because they always came back.
}
{ ev_card.lent && not slippers_upstairs:
    SLIPPERS: Nine. Remember. I'm in nine. You'll get it.
}
{ not hotel_door:
    The hotel door was locked. He unlocked it for {slippers_upstairs:her|them} and held it, and {slippers_upstairs:she|they} went up, and he locked it again behind {slippers_upstairs:her|them}.
    WRONGMAN: Every door you lock, you end up holding open for somebody.
}
-> clear

=== close_endbar ===
~ pass(1)
The glass was still at the end of the bar, full to the brim. Nobody had seen the old man go. Nobody had seen him come, either.
The bartender picked the glass up and poured it down the sink without looking at it, the way she'd done every night for thirty-one years, by the look of it.
{ knows ? endbar_invite:
    WRONGMAN: After, he said. When it's quiet.
}
-> clear

=== close_t28 ===
~ cleared += cl_t28
~ here = t28
~ pass(5)
Table 28 did not hurry for last call. Table 28 had never hurried for anything. They had their two each lined up in front of them and they were working through them at the speed of conversation.
{ arrivals ? wife_in || arrivals ? wife_told || arrivals ? wife_inside:
    Four of them. The gap where Dennis sat was still a gap.
}
{ walter == 0:
    They didn't talk to him. They talked in front of him.
}
{ walter == 3:
    -> t28_find_bait ->
}
TEAM_JACKET: We're going. We're going. Look at us going.
* ["Drink up, gentlemen." #check: father 7]
    { passed:
        He said it the way the Father used to say it, like a favour to them, and they drank up and stood and got their coats, in the order they always did, and went out together into the rain.
        ~ rep(rep_staff, 1)
    - else:
        TABLE28: Drink up, gentlemen!
        They said it back to him in one voice, delighted, and didn't drink up. It was twenty past two before they went.
        ~ pass(15)
    }
* ["Take your time."]
    ~ rep(rep_t28, 1)
    ~ pass(25)
    They took it. The bartender put the chairs up on the tables around them and they didn't notice, or noticed and didn't care, and at half past two they went, together, the way they'd come.
* {walter != 0 || rep_t28 >= 0} [Sit down with them for the last one.]
    ~ pass(15)
    ~ pull_table++
    ~ drink()
    ~ rep(rep_t28, 1)
    He sat down. Somebody pushed a rye at him. The talk went round, and he let it go through him, and for a minute he couldn't have told you where table 28 stopped and he started.
    TABLE28: He's all right.
* ["Now. All of you."]
    ~ rep(rep_t28, -2)
    ~ rep(rep_staff, 1)
    TEAM_JACKET: The last one said that.
    They went, slowly, to make the point. At the door the one in the team jacket stopped and patted him twice on the arm, the way you'd pat a horse that wasn't yours.
- { cardigan_go == 1:
    The one in the cardigan went out last. At the door he nodded to the doorman, once, as if they'd agreed on something.
}
They went out to their trucks, and all of them drove. Everybody drove, out here.
FATHER: You can't take five sets of keys off table 28. You'd be taking the whole town's.
-> clear


// Bait in Walter's hole. Scratch finds what's left of it when he leaves the last fry.
=== t28_find_bait ===
The one who scratched lottery tickets bent down to put the last fry of the night by the hole in the baseboard, the way he must have done a thousand nights. He stayed down there longer than it took.
He came up with something green between his finger and thumb. Half a block of bait, gnawed down to the hole in the middle.
SCRATCH: That's poison.
SCRATCH: That was in Walter's door.
-> ev_rat.who_poison ->
->->


// ------------------------------------------------------------------ the count

=== lock_up ===
~ here = door
~ pass(5)
He locked the front door behind the last of them and turned the sign over. #sfx: door
# amb: empty_bar
{ clock > CLOSE_TIME + 20:
    ~ incident += inc_after
}
BARTENDER: Numbers.
In, by the door: {num(count_in + 13)}, counting the thirteen who were here when he came on.
Out, by the door and the back stairs: {num(count_in + 13 + uncounted)}.
{ uncounted == 0:
    It matched.
    The bartender looked at the clicker, and at him, and didn't say anything, which from her was a lot.
    ~ rep(rep_staff, 1)
    -> incident_log
}
{uncounted == 1:One more|{Num(uncounted)} more} out than in.
BARTENDER: So find out why.
-> search

=== search ===
~ here = floor
- (s)
* {deck_door || fam ? via_deck} [The deck door.]
    ~ pass(2)
    { fam ? via_deck:
        The prints on the carpet from the deck door had dried to a tide line. Three pairs.
    }
    { deck_door:
        The coaster was still in the latch. He took it out, and the door locked.
        ~ deck_door = false
    - else:
        Locked.
    }
    -> s
* {hotel_door || arrivals ? hivis_hotel} [The hotel door.]
    ~ pass(2)
    { arrivals ? hivis_hotel:
        HI-VIS had come down that way. {at_hall.hivis_stairs:He'd watched him do it.|He hadn't seen him do it.}
    }
    { hotel_door:
        The wedge was still under it. He kicked it out, and the door latched.
        ~ hotel_door = false
    }
    -> s
* {kitchen_door} [The kitchen door.]
    ~ pass(3)
    The milk crate was still in the back door, and the rain was coming in on the tiles. He took it out, and locked the door, and checked it twice.
    ~ kitchen_door = false
    -> s
* {arrivals ? banned_inside} [The front door, while he was away from it.]
    ~ pass(1)
    GOOD SHOES had come in the front, past the empty stool, while he was somewhere else.
    FATHER: A door's only a door when somebody's standing in it.
    -> s
* {walk_ins > 0} [The single washroom.]
    ~ pass(3)
    A man he'd never seen before was asleep on the floor of the single washroom, with his head on a roll of paper towel. He'd never passed the door. Nobody knew him, and he didn't know where he was.
    He woke him and walked him out to the lot and pointed him at the highway.
    WRONGMAN: The one you didn't count. It's always the one you didn't count.
    -> s
+ [That's enough. Write the log.]
    -> incident_log


// ------------------------------------------------------------------ the incident log

=== incident_log ===
~ here = bar
# screen: log
The incident log was a hardback ledger that lived under the till with the binder. Every doorman before him had written in it, in nine different hands, going back further than the owner.
The bartender pushed it along the bar to him with a pen.
// HUTCH: What does a real incident log look like? The book, the wording, what gets written down and what never does.
{ LIST_COUNT(incident) == 0:
    Nothing had happened. He wrote the date and NOTHING TO REPORT, and she read it upside down.
    BARTENDER: First time I've seen that on a first night.
    -> log_close
}
-> log_next

= log_next
~ temp todo = incident - logged - shaded - left_out
{ LIST_COUNT(todo) == 0:
    -> log_done
}
~ temp x = LIST_MIN(todo)
{ inc_text(x) } #class: entry
+ [Write it down the way it happened.]
    ~ logged += x
    { x == inc_drinking || x == inc_hurt:
        ~ cocoon--
    }
+ [Write it so it reads better.]
    ~ shaded += x
    { x == inc_drinking || x == inc_hurt || x == inc_banned || x == inc_deck:
        ~ cocoon++
    }
+ [Leave it out.]
    ~ left_out += x
    ~ cocoon++
- -> log_next

= log_done
She turned the book round and read it.
{
- LIST_COUNT(shaded) + LIST_COUNT(left_out) == 0:
    BARTENDER: Huh.
    She turned it back.
    BARTENDER: The owner'll hate that. Every word of it's true.
    ~ rep(rep_staff, 1)
- LIST_COUNT((shaded + left_out) ^ she_saw()) > 0:
    BARTENDER: That's not what happened.
    BARTENDER: It's your book. But that's not what happened.
    ~ rep(rep_staff, -1)
- else:
    She turned it back and didn't say anything.
}
-> log_close

= log_close
# screen: none
-> after_hours


// ------------------------------------------------------------------ after hours

=== after_hours ===
~ here = bar
# music: after_hours
The chairs went up on the tables. The bartender put one song on the jukebox, the same one, he'd find out, every night, and counted the till with a rye at her elbow. #sfx: till
// HUTCH: The song she puts on for the count. Yours to pick, or to write.
She'd poured two. She pushed the other one along the bar to him without looking up from the twenties.
* [Drink it.]
    ~ drink()
    FATHER: {Num(drinks)}. After hours still counts.
* [Leave it where it is.]
    She didn't say anything about it. When she'd finished the count she drank it herself.
* [Push it back.]
    BARTENDER: Suit yourself.
    She drank it.
- BARTENDER: Why'd you leave your last door?
// HUTCH: Why DID he leave his last door? Every answer below becomes true once he says it. Is one of them the real one?
* ["The owner shorted me."]
    ~ claims += said_left_bad_owner
    BARTENDER: They all short you. You'll find out.
* ["Something happened."]
    ~ claims += said_left_something
    She waited. He didn't say what. She nodded as if that was an answer, which in a bar it is.
* ["Long story."]
    ~ claims += said_left_long_story
    BARTENDER: They're all long stories. Nobody ever left a door over a short one.
* [Say nothing.]
    ~ claims += said_nothing
    She looked at him over the rye, and went back to the count.
- (compare)
{
- claims ? said_city_door:
    BARTENDER: Table 28 says you did ten years on a door in the city.
    BARTENDER: By Friday it'll be twenty, and you'll have put a hockey player through a window.
- claims ? said_father:
    BARTENDER: Table 28 says your old man worked doors. {father_named:The one in the cardigan's been saying his name to himself all night, like he's trying to place it.}
- claims ? said_up_island:
    BARTENDER: Up island, table 28 says. Everybody's from up island.
- claims ? said_around:
    BARTENDER: Table 28 have decided you're from Around. That's what they're calling it now. Around.
}
BARTENDER: Owner'll call me in the morning and ask how you did.
{
- rep_staff >= 3:
    ~ verdict = 2
    BARTENDER: I'll tell him you'll do.
    It was, he found out later, the best thing she'd said about a doorman on his first night in thirty-one years. She said it to the till.
- rep_staff >= 0:
    ~ verdict = 1
    BARTENDER: I'll tell him you showed up and you're still here. Two of the last nine didn't manage that.
- else:
    ~ verdict = -1
    BARTENDER: I'm going to tell him what I saw.
    She didn't say what that was. She didn't need to.
}
BARTENDER: Friday's different. Friday's everybody.
BARTENDER: Go up. Get some sleep.
{ knows ? endbar_invite || knows ? knot_seen:
    -> choose
}
-> go_upstairs

= choose
* [Go up to bed.]
    -> go_upstairs
* [Wait till she's gone. Then go down to the keg room.]
    -> keg_parley


// ------------------------------------------------------------------ 3 am: the parley

=== keg_parley ===
~ here = keg
{ clock < 1620:
    ~ clock = 1620
}
# amb: keg_room
# music: keg_room
She locked up and went out the front, and he heard her car start in the lot and go. #sfx: door
He waited until the building was quiet. The coolers. The rain. Then he lifted the trapdoor.
The light at the bottom of the stairs was on. He hadn't left it on.
The old man from the end of the bar was sitting on an upturned keg between the rows, in his old good jacket, with the full glass on the floor beside his shoe. #portrait: endbar
ENDBAR: You came down.
Past the last keg, in the dark toward the front of the building, a sound like a lot of hands being rubbed together. It stopped when the old man lifted one finger. #sfx: scratch
// HUTCH: The first parley with the Rat King. The terms here are drafts. What would they want from a doorman, and what could they give him?
FATHER: Go back up.
WRONGMAN: This is the story. This is the one they'll tell about you.
-> terms

= terms
{ rats == war:
    ENDBAR: You've started a war. That's all right. Most do, the first night.
}
{ poison:
    ENDBAR: There's poison down. Some of them have eaten it. They'll go into the walls to die, and on Friday you'll smell them, and so will your customers, and so will the man from the health.
}
{ walter == 0:
    ENDBAR: And you killed the one at the table. The one they fed. That one had a name. Names cost more.
}
{ walter == 3:
    ENDBAR: And you put it in the one hole the one at the table goes in and out of. He's eaten it. He'll be days about it, in the wall behind their chairs. That one had a name. Names cost more.
}
{ rat_favour > 0:
    ENDBAR: You've been courteous. That's noticed.
}
{ rats_killed > 0 && walter != 0:
    ENDBAR: {rats_killed == 1:You've killed one|You've killed {num(rats_killed)}}. That's noticed too.
}
- (t)
* ["Who are you?"]
    ENDBAR: I'm the one who comes down.
    ENDBAR: I was coming in here before she started. Before the owner's father owned it. Before it was a hotel, I was on the dock they built it on.
    He didn't look old enough for that. He didn't look young enough for anything else.
    -> t
* (want) ["What do they want?"]
    ENDBAR: What anyone wants. To eat, and not be killed.
    ENDBAR: Food on the third step, every night you're on. The kitchen door on the latch after the cook goes home. {poison:And you take up what you put down.|And no poison. Not in this building.}
    -> t
* ["What do I get?"]
    ENDBAR: Quiet. Nobody sees one of them on the fourteenth. Not the inspector, not a customer, not the cook.
    ENDBAR: And they hear everything. Every word said at that table, and under every table, and behind every door in this building. You'd be surprised what gets said about a doorman.
    -> t
* {knows ? knot_seen} ["I saw it. In the wall."]
    ENDBAR: Then you know what you're talking to.
    ENDBAR: It's been in that wall longer than there's been a wall. The table feeds it and doesn't know they do. It hears them. It hears everyone.
    -> t
+ {want} ["Done. Those terms."]
    -> deal
* {want} ["The step, and no poison. Not the kitchen door." #check: wrongman 8]
    -> bargain
+ ["No. They're going."]
    -> refuse
* [Tell him you'll burn them out.]
    -> threaten
+ ["I'll think about it."]
    -> think

= deal
~ parley = 2
~ rats = truce
ENDBAR: Good.
He didn't offer his hand. He picked the full glass up off the floor, looked at it, and put it down again, which seemed to be the same thing.
{ poison:
    # task: terms :: Your terms with the rats: food on the third step every night you're on, the kitchen door on the latch after the cook goes, and the poison taken up.
- else:
    # task: terms :: Your terms with the rats: food on the third step every night you're on, and the kitchen door on the latch after the cook goes.
}
FATHER: Every bar I worked had an arrangement with somebody. The owner, the cops, the bikers. This is the first one I'd have trusted to keep it.
FIGHTER: You made a deal with rats.
-> after_parley

= bargain
{ passed:
    ENDBAR: The step, then. And no poison. We'll find our own doors.
    ~ parley = 2
    ~ rats = truce
    ~ terms_door = false
    { poison:
        # task: terms :: Your terms with the rats: food on the third step every night you're on, and the poison taken up.
    - else:
        # task: terms :: Your terms with the rats: food on the third step every night you're on, and no poison.
    }
    WRONGMAN: You bargained with it. In the story nobody bargained. That's why it's a story.
- else:
    ENDBAR: Then no terms. Not tonight.
    ENDBAR: Come down again when you're ready to talk like somebody who needs something.
    ~ parley = 1
}
-> after_parley

= refuse
~ parley = 1
~ go_to_war()
ENDBAR: Then it's the long way.
He stood up. His knees cracked. He left the full glass on the floor.
ENDBAR: It's always the long way, the first time.
When the doorman looked back from the stairs, the light was off, and the keg was only a keg.
FIGHTER: Good.
-> after_parley

= threaten
~ parley = 1
~ rats = hostile
He said it. He said he'd burn them out.
ENDBAR: Then you'll burn the hotel down with them. They're in every wall. They were here before the walls.
He stood up, slowly, and picked up the full glass, and poured it out on the dirt, all of it, and set the empty glass on the keg.
ENDBAR: That's the first time I've done that.
When the doorman looked back from the stairs, the light was off.
FATHER: You shouldn't have said that. Not because it was wrong. Because you meant it, and now it knows.
-> after_parley

= think
~ parley = 1
ENDBAR: Think, then. They won't wait for you. They'll double while you think. They always do.
-> after_parley

= after_parley
He went back up the stairs, stepping over the third one. Behind him the scratching started again, and went on, and he could still hear it from the top.
-> go_upstairs


// ------------------------------------------------------------------ upstairs

=== go_upstairs ===
~ here = upstairs
{ clock < 1640:
    ~ clock = 1640
}
# music: none
# amb: none
He went up through the hotel door and two flights of stairs that smelled of other people's cooking, to the room that came with the job, at the end of the second floor, over the deck.
A bed, a chair, a sink in the corner, and a window onto the lot and the highway and the water. The rent came off his pay. The owner had mentioned that before he'd mentioned anything else.
// HUTCH: His room. What does a room that comes with a bar job look like, and what did he bring with him?
{ rats == undecided:
    ~ rats = ignored
}
{ rats == ignored:
    ~ rat_count = rat_count * 2
}
{ poison_at ? t28 && walter == 1:
    ~ walter = 3
}
He lay down on the bed in his clothes. Under the floor, under all the floors, in the walls, something was moving. #sfx: scratch
-> voices_at_night


// ------------------------------------------------------------------ the voices at night

=== function wants_table()
~ return pull_table >= 3

=== function wants_kid()
~ return pull_kid >= 3

=== voices_at_night ===
{ wants_table():
    ~ learn("table")
}
{ wants_kid():
    ~ learn("kid")
}
{ not wants_table() && not wants_kid():
    The voices went back over the night, all of them, the way they did. The Father first, and last.
    -> ledger
}
There was somebody new in his head, talking over the others.
{ wants_table():
    TABLE: We were here first. #always
    TABLE: Sit down. Nobody stands at this table. #always
    It wasn't one of them. It was all five at once, sure of everything, and it had come in with the rye.
}
{ wants_kid():
    KID: i'm not high #always
    KID: i just haven't slept #always
    It was the kid in the washroom. It didn't say much. What it said, it said about things the others couldn't see.
}
FATHER: Don't let that in.
- (vs)
* {wants_table()} [Let THE TABLE in.]
    -> let_voice_in("table")
* {wants_kid()} [Let THE KID in.]
    -> let_voice_in("kid")
+ [Sleep.]
    { new_voice == "":
        The new voice went on talking outside the room for a while. Then he was asleep.
    - else:
        He was asleep before the voices were finished with him.
    }
    -> ledger

=== let_voice_in(v) ===
{ seats_free() > 0:
    ~ seat(v)
    -> welcomed(v)
}
The room held five, and it had five. Somebody would have to go.
+ {seated("fighter")} [Put THE FIGHTER out.]
    ~ unseat("fighter")
+ {seated("manual")} [Put THE MANUAL out.]
    ~ unseat("manual")
+ {seated("wrongman")} [Put THE WRONG MAN out.]
    ~ unseat("wrongman")
+ {seated("table")} [Put THE TABLE out.]
    ~ unseat("table")
+ {seated("father")} [Put THE FATHER out.]
    ~ unseat("father")
    It was quiet where he'd been. It was the quietest his head had been since the funeral.
+ [Nobody. Keep the room as it is.]
    -> voices_at_night.vs
- ~ seat(v)
-> welcomed(v)

=== welcomed(v) ===
~ new_voice = v
{ v == "table":
    TABLE: Good man. #always
- else:
    KID: ok #always
}
-> voices_at_night.vs


// ------------------------------------------------------------------ dawn: the ledger

=== ledger ===
~ here = upstairs
# screen: ledger
NARRATOR: That was Wednesday. The one nobody else remembers.
WEDNESDAY. THE TEST SHIFT.
The door: {count_in} in past the stool{uncounted > 0:, and {uncounted} more some other way|, and nobody got past him}.
{ cash >= 0:
    In his pocket: ${cash}.
- else:
    In his pocket: nothing. He's ${0 - cash} down on the night.
}
{
- drinks == 0:
    He didn't drink.
- drinks == 1:
    He had one.
- else:
    He had {num(drinks)}. {drinks >= 3:He'll feel them on Friday.}
}
{
- hurt == 1:
    Knocked about. Nothing that won't heal by Friday.
- hurt == 2:
    Hurt. His hand, his face. Friday will know about it.
- hurt >= 3:
    Badly hurt.
}
{
- fam ? dad_went && fam ? lot_scene:
    The big man from the pool table went to the hospital in his daughter's truck at two in the morning. {took_keys:His keys are in the lost-and-found drawer.}
- fam ? dad_went:
    The big man from the pool table went to the hospital with his kids.
- fam ? dad_drove:
    The big man drove himself home drunk. {family_in_lot:His kids followed him.}
- fam ? dad_ejected:
    He put the big man out.
- fam ? lot_scene && took_keys:
    The big man walked home along the highway. His keys are in the lost-and-found drawer.
- fam ? dad_stayed:
    The big man finished his game. His family went without him.
}
{
- rats == truce:
    The rats: terms. Food on the third step, every night he's on.
- rats == war:
    The rats: war. {poison:Poison down.} {traps:Traps set.} {rats_killed > 0:{Num(rats_killed)} dead that he knows of.}
- rats == hostile:
    The rats: he threatened to burn them out. The old man poured his glass out on the dirt.
- rats == ignored:
    The rats: ignored. By Friday there'll be twice as many.
}
{ walter == 0:
    Walter is dead.
}
{ walter == 3:
    Walter has eaten the bait. It takes days. He'll go into the wall behind table 28 to do it.
}
The log: {LIST_COUNT(logged)} written as it happened, {LIST_COUNT(shaded)} shaded, {LIST_COUNT(left_out)} left out.
{
- verdict == 2:
    The bartender will tell the owner he'll do.
- verdict == 1:
    The bartender will tell the owner he showed up.
- verdict == -1:
    The bartender will tell the owner what she saw.
}
{
- rep_t28 >= 3:
    Table 28 made room for him.
- rep_t28 >= 1:
    Table 28 have decided he'll do, for now.
- rep_t28 >= -1:
    Table 28 haven't made up their minds.
- else:
    Table 28 talk around him.
}
{
- rep_kids >= 3:
    The kids think he's real.
- rep_kids <= -2:
    The kids think he's another one.
}
{
- rep_cook >= 2:
    The cook said thanks, once.
- rep_cook <= -2:
    The cook has him down as one more thing that makes his night worse.
}
{ cardigan_go == 1:
    The one in the cardigan is thinking about Calgary.
}
{ LIST_COUNT(claims) > 0:
    What he's said about himself, which is true now: {claims ? said_up_island:that he's from up island. }{claims ? said_city_door:That he did ten years on a door in the city. }{claims ? said_around:That he's from around. }{claims ? said_father:That his father worked doors{father_named:, and his father's name}. }{claims ? said_left_bad_owner:That he left his last door because the owner shorted him. }{claims ? said_left_something:That something happened at his last door. }{claims ? said_left_long_story:That leaving his last door is a long story. }{claims ? said_nothing:He hasn't said why he left his last door.}
}
{ seated("table") || seated("kid"):
    In his head: {seated("table"):THE TABLE, new, }{seated("kid"):THE KID, new, }{seated("father"):THE FATHER, }{seated("fighter"):THE FIGHTER, }{seated("manual"):THE MANUAL, }{seated("wrongman"):THE WRONG MAN}.
}
Friday is two nights away. Friday's everybody.
END OF THE TEST SHIFT
-> END
