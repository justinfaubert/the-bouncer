// Closing: last call at 1:30, the room cleared by two, the count and the search, the incident
// log, after-hours with the bartender, and, if the old man asked him down, the parley in the
// keg room. Then the room upstairs, the voices, and the ledger.
// Closing the room without an incident is a skill of its own, and after-hours is where the
// best writing will live (bible/02_SYSTEMS.md).
//
// This is where the night comes back to him. What he did at the door, at the pool table, at table
// 28 and in the keg room is said back to him here by the people he did it to: the big man in the
// lot, table 28 on their way out, the bartender reading the book and counting the till, the old man
// in the keg room, the voices in the dark. The ledger at the end is the till tape of all of it.

=== function pool_still()
~ return fam !? dad_went && fam !? dad_ejected && fam !? lot_scene && fam !? dad_drove && fam !? dad_walked

=== function hivis_still()
~ return (arrivals ? hivis_in || arrivals ? hivis_hotel) && cleared !? cl_hivis

=== function banned_still()
~ return arrivals ? banned_in && arrivals !? banned_out

// Somebody from the pickup is still waiting on the big man: in the truck, in the vestibule, or inside.
=== function family_waiting()
~ return in_truck(sister_at) || sister_at == s_vestibule || kids_count() > 0

=== function left_to_clear()
~ temp n = 0
{ pool_still() && cleared !? cl_pool:
    ~ n++
}
{ banned_still() && cleared !? cl_banned:
    ~ n++
}
{ hivis_still():
    ~ n++
}
{ cleared !? cl_res && not slippers_both:
    ~ n++
}
{ cleared !? cl_t28:
    ~ n++
}
~ return n


// ------------------------------------------------------------------ what goes in the book

// What the bartender saw from behind the bar, so she'll know what he shaded or left out of the log.
// The bait only if he carried it up past her or told the owner on her phone; the ones let in without
// a card only if she watched it done, or the scanner can tell her.
=== function she_saw()
~ temp s = (inc_banned, inc_fight, inc_rat, inc_drinking, inc_hurt, inc_after, inc_hivis, inc_police)
{ poison_at ? kitchen || poison_at ? t28 || ev_owner.told_poison:
    ~ s += inc_poison
}
{ scans ? scan_phone || door_hoodie.admit || (ev_sister.sister_all && knows ? vape_no_id):
    ~ s += inc_no_id
}
~ return s

// The kid, let in on the photograph of his licence and never on the licence.
=== function kid_no_id()
~ return fam ? hoodie_admitted && scans !? scan_card && fam !? via_deck

// What's in front of him on the page before he writes: what he's deciding about.
=== function inc_name(x)
{
- x == inc_kid_refused:
    {fam ? hoodie_refused:The kid with the photograph of his licence{fam ? sister_refused:, and then his sister}.|The kid's sister and her boyfriend, at the door.}
- x == inc_no_id:
    The ones he let in without a card.
- x == inc_deck:
    The three who came in by the deck.
- x == inc_banned:
    GOOD SHOES. Page three.
- x == inc_rat:
    The rat, in the bar, in front of everybody.
- x == inc_fight:
    {fam ? pool_fight:The pool table.|The stool that went over at the bar.}
- x == inc_police:
    The constable.
- x == inc_hivis:
    HI-VIS, and his two-four.
- x == inc_wife:
    Dennis's wife.
- x == inc_lot:
    The big man in the lot, with his keys.
- x == inc_drinking:
    What he drank.
- x == inc_poison:
    The bait.
- x == inc_hurt:
    Who got hurt.
- x == inc_drugs:
    The boyfriend, in the men's.
- x == inc_office:
    The mirror on the desk in the office.
- x == inc_after:
    The last of them out after two.
}

// The entry the way it happened.
=== function inc_text(x)
{
- x == inc_kid_refused:
    {
    - fam ? hoodie_refused && fam ? sister_refused:
        Refused entry: a young man with a photograph of his licence and not the licence{knows ? card_in_truck:, which was in the truck}. Later his sister and her boyfriend, looking for her father{promise_kept >= 1:. Told he wasn't here. He was}.
    - fam ? hoodie_refused:
        Refused entry: a young man with a photograph of his licence and not the licence{knows ? card_in_truck:, which was in the truck}.
    - else:
        Refused entry: a young woman and her boyfriend, looking for her father{promise_kept >= 1:. Told he wasn't here. He was}. {fam ? hoodie_admitted:Her brother was already inside.}
    }
- x == inc_no_id:
    {
    - kid_no_id() && ev_sister.sister_all:
        Admitted without identification: a young man on a photograph of his licence, and his sister's boyfriend on nothing at all.
    - kid_no_id():
        Admitted without identification: a young man, on a photograph of his licence{knows ? kid_legal:. Nineteen, by the photograph}.
    - else:
        Admitted without identification: a young woman's boyfriend, on nothing at all{knows ? vape_no_id:. His was in his other pants}.
    }
- x == inc_deck:
    Three people in by the deck door, one of them refused at the front an hour before. None of them came past the door. The deck door was propped with a coaster.
- x == inc_banned:
    {
    - arrivals ? banned_inside && arrivals ? banned_out:
        A barred man, page three, NOT EVER, came in the front while nobody was on it, and was served. Put out.
    - arrivals ? banned_inside:
        A barred man, page three, NOT EVER, came in the front while nobody was on it, and was served. Left at the bar till close.
    - banned_held == 1:
        A barred man, page three, NOT EVER. Let in on one drink, and walked out after it.
    - banned_held == 2:
        A barred man, page three, NOT EVER. Let in on one drink, and then one more.
    - banned_held == -1:
        A barred man, page three, NOT EVER. Let in on one drink, and then as many as he liked.
    - banned_one > 0:
        A barred man, page three, NOT EVER. Let in on one drink, which lasted till close.
    - else:
        A barred man, page three, NOT EVER. Let in at the door, and served till close.
    }
- x == inc_rat:
    A rat in the bar, during service, in front of customers{walter == 0:. The one table 28 call Walter is dead}.
- x == inc_fight:
    {fam ? pool_fight:A fight at the pool table{name_on_log:. Not called in. His name on it}.} {bar_scuffle:A scuffle at the bar putting a barred man out. A stool went over.}
- x == inc_police:
    Police attended, forty minutes after the call. {told_police == 1:He gave the constable an account, in order.|{told_police == -1:He told the constable it had sorted itself out.|The bartender gave the account.}}
- x == inc_hivis:
    {
    - arrivals ? hivis_in && at_hall.hivis_stairs:
        A resident from the mill crew, refused at the door. He came down the back stairs later, and was sent round to the front and counted in.
    - arrivals ? hivis_hotel && at_hall.hivis_stairs:
        A resident from the mill crew, refused at the door. He came down the back stairs later and drank at the bar.
    - arrivals ? hivis_in:
        A resident from the mill crew, admitted with a case of his own beer.
    - arrivals ? hivis_hotel:
        A resident from the mill crew, refused at the door. He came down the back stairs twenty minutes later and drank at the bar anyway.
    - else:
        A resident from the mill crew, refused at the door of the building he lives in.
    }
- x == inc_wife:
    A patron's wife, looking for him, after midnight{arrivals ? wife_inside:. She came in while nobody was on the door|. Let in}. He left with her.
- x == inc_lot:
    {
    - took_keys && fam ? dad_went:
        At close: the man from the pool table, drunk, in the lot, with his keys. Keys taken. He left with his family, in their truck.
    - took_keys:
        At close: the man from the pool table, drunk, in the lot, with his keys. Keys taken. He walked.
    - fam ? dad_drove:
        At close: the man from the pool table, drunk, in the lot, with his keys. He drove.
    - else:
        At close: the man from the pool table, drunk, in the lot. He left with his family, in their truck.
    }
- x == inc_drinking:
    Staff drinking on shift. {Num(drinks - drinks_before)} drinks. Him.
- x == inc_poison:
    Rat poison put down {poison_at ? t28:in the hole in the baseboard behind table 28|{poison_at ? kitchen:behind the walk-in in the kitchen|in the keg room}}.
- x == inc_hurt:
    {hurt > 0:Injured on the premises: the doorman{fam ? pool_fight:, and others, at the pool table}.|Injured on the premises: a patron.}
- x == inc_drugs:
    A patron using drugs in the men's washroom.
- x == inc_office:
    In the office in the keg room, on the desk: a mirror, a straw cut down to two inches, and a white dust in one corner of the mirror.
- x == inc_after:
    Customers still inside after two.
}

// The same entry, the way it reads better. Shaded is not the same as false. Mostly.
=== function inc_shade(x)
{
- x == inc_kid_refused:
    Refused entry: no valid identification. Left without incident.
- x == inc_no_id:
    Admitted: identification checked at the door.
- x == inc_deck:
    Three persons found inside who had not been admitted at the front. Dealt with.
- x == inc_banned:
    A patron from the barred list, who says the owner has lifted it.
- x == inc_rat:
    Pest sighting. Dealt with.
- x == inc_fight:
    {fam ? pool_fight:A disagreement at the pool table. Resolved.|A patron asked to leave. Left.}
- x == inc_police:
    Police attended. No further action.
- x == inc_hivis:
    A resident, at the bar. No issue.
- x == inc_wife:
    A patron's wife collected him. No issue.
- x == inc_lot:
    {fam ? dad_drove:A patron left at close. Advised not to drive.|A patron left at close. No issue.}
- x == inc_drinking:
    Shift drink.
- x == inc_poison:
    Pest control measures in place.
- x == inc_hurt:
    Minor injury. No first aid required.
- x == inc_drugs:
    A patron asked to leave the washroom.
- x == inc_office:
    Office left untidy.
- x == inc_after:
    Closed on time.
}


// ------------------------------------------------------------------ 1:30 last call

// The bell's heard everywhere in the room: he hears it where he is.
=== last_call ===
{ clock < LAST_CALL:
    ~ clock = LAST_CALL
}
# music: jukebox_late
# amb: room_busy
The bartender reached up and rang the brass bell over the till, twice. #sfx: bell
BARTENDER: Last call!
TABLE28: Two each!
Everybody who was going to leave started thinking about leaving. Table 28 ordered.
{ dennis_gone():
    The one in the team jacket ordered two for Dennis, too, out of respect, and lined them up in front of the empty chair, and drank them himself.
}
// HUTCH: Last call at the Sov. What really happens in a room like this when the bell goes?
{ pool_still():
    { fam ? dad_stayed:
        At the pool table the big man was playing both ends of the table. He didn't look up at the bell.
    - else:
        At the pool table the big man was racking again. He didn't look up at the bell.
    }
}
{
- kid_locked_in():
    The single washroom in the back hall was still locked.
- kid_at == s_jukebox:
    By the jukebox the kid hadn't moved, waiting for something that wasn't the bell.
}
{ in_truck(sister_at) && pool_still():
    Out in the lot the pickup was still there with its engine running. It had been there all night.
}
{ banned_still():
    {
    - banned_held == 2:
        GOOD SHOES was still at the bar with the last one in front of him, and it was still the last one.
    - banned_held == -1:
        GOOD SHOES was at the bar on his sixth, pleasant to everyone. One drink, it had been, once.
    - banned_one > 0:
        GOOD SHOES had had his one drink. He'd had it for a while.
    - else:
        GOOD SHOES had his good coat over the back of the stool, and no sign of putting it on.
    }
}
{ knows ? endbar_seen:
    The stool at the end of the bar was empty. The glass was still there, full.
}
FATHER: Last call's easy. It's the half hour after it that's the job.
-> clear

// Between the ones he's clearing, he steps back out onto the floor, once the last thing's been said.
=== clear ===
~ beat()
~ here = floor
{ clock >= CLOSE_TIME && not two_called:
    ~ two_called = true
    { clock >= CLOSE_TIME + 15:
        BARTENDER: Past two, folks! Drink 'em up.
    - else:
        BARTENDER: That's two, folks! Drink 'em up.
    }
    MANUAL: Licensed hours end at two. Every minute after that is the licensee's problem, and yours.
}
{ left_to_clear() == 0:
    -> lock_up
}
* {pool_still()} [The big man at the pool table. #loc: pool]
    -> close_pool
* {banned_still()} [GOOD SHOES, still at the bar. #loc: bar]
    -> close_banned
* {hivis_still()} [HI-VIS, asleep on his arms at the bar. #loc: bar]
    -> close_hivis
* {not slippers_both} [{slippers_upstairs:The woman from upstairs, finishing the bottle.|The women from upstairs, finishing the bottle.} #loc: bar]
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
    The big man had the rack off and was chalking his cue for the break.
}
BIGMAN: One more.
{ sister_at == s_rail:
    { fam ? sister_admitted:
        His daughter was at the rail with her keys in her fist, where she'd stood since he let her in to find him.
    - else:
        His daughter was at the rail with her keys in her fist.
    }
}
{
- kid_at == s_jukebox:
    His son was by the jukebox with his hood up.
- kid_locked_in():
    His son was still locked in the single washroom at the end of the back hall.
}
{ vape_at == s_bar:
    The boyfriend was at the bar on his phone, waiting to be told.
}
{
- sister_at == s_vestibule:
    His daughter was still in the vestibule with her keys, watching him through the inner door.
- in_truck(sister_at):
    The big man stood with his back to the front window, and the pickup's lights were in it.
}
// The errand, if it's still his to carry: the hospital if he knows, his daughter if he doesn't.
* {fam !? dad_told && family_waiting() && (knows ? kid_why || fam ? sister_fetched)} [{knows ? kid_why:Tell him about the hospital. Now.|"Your daughter's {her_place()}. She's been waiting all night."} #check: father:cha 11 {bigman_mod()}]
    ~ fam += dad_told
    { passed:
        { knows ? kid_why:
            He told him, low, at the end of the table. Nearly a day late, somebody told him.
        - else:
            He said it, low, at the end of the table, and the big man heard what he wasn't saying.
        }
        The big man put the cue down across the balls, in the middle of the game.
        -> the_lot(true)
    }
    He told him. The big man heard it the way you hear the weather.
    BIGMAN: I know, bud. I know she is.
    BIGMAN: And do what, eh. Sit there.
* ["We're closed. Time to go."]
    ~ pass(2)
    ~ bigman_ease++
    BIGMAN: One more.
    The doorman said it again, the same way, as if it was the first time. The big man put the cue in the rack on the wall as if it weighed a lot.
* [Take the cue out of his hands. #check: fighter:dex 11]
    { passed:
        He took it, gently, the way you'd take something off a table in someone else's house, and put it in the rack on the wall. The big man looked at his empty hands.
    - else:
        The big man held on. For a second they both had it. Then he let go, and his face said he'd remember that.
        ~ bigman_ease--
        ~ rep(rep_kids, -1)
    }
- -> the_lot(false)

// He goes out to the lot. If he's going to them (told just now, and it landed), he goes to the pickup.
// Otherwise he goes to his own truck, with his keys, and what the doorman said to him all night comes
// back with him: whether he lost to him on purpose, whether the promise was kept, what he said about
// kids (pool.ink).
= the_lot(to_them)
~ pass(5)
~ here = lot
~ temp kid_was_in = indoors(kid_at)
~ temp sis_was_in = indoors(sister_at)
~ temp vape_was_in = indoors(vape_at)
~ family_in_lot = family_waiting()
~ kids_out()
{ sister_at == s_vestibule:
    ~ move(sister_at, s_truck)
}
~ fam += lot_scene
~ fam_done = true
~ room_count -= 2
~ incident += inc_lot
# amb: rain_lot
The big man got his jacket off the hook by the pool table and went out the front door into the lot, and the doorman went out behind him and stood under the light over the door.
The buddy went out ahead of them both with his collar up{knows ? transmission: and the twenties from under the rail in his fist, a transmission, or some of it}, and got into a car at the far end of the lot, and didn't wait to see.
{
- kid_was_in && sis_was_in:
    His kids came out behind him and stood under the awning{vape_was_in:, and the boyfriend after them, lighting his vape}.
- kid_was_in:
    His son came out behind him and stood under the awning with his hood up.
- sis_was_in:
    His daughter came out behind him and stood under the awning with her keys{vape_was_in:, and the boyfriend after her, lighting his vape}.
- vape_was_in:
    The boyfriend came out after him, lighting his vape, and went and stood by the pickup.
}
{ vape_at == s_lot:
    The boyfriend was sitting on the step of the beer store out of the rain, where he'd been since he was put out, watching.
}
{ cleared !? cl_t28:
    Table 28 watched through the front window, all of them, the way they watched the hockey.
}
{ to_them:
    He didn't go to his own truck. He went across the gravel to the pickup and stood by the passenger door in the rain, and waited for somebody to open it.
    -> to_pickup
}
{ family_in_lot:
    He didn't go to the pickup.
}
He went to his own truck, a work truck with a toolbox across the bed, parked nose-in by the beer store. He got his keys out, and dropped them in the gravel, and picked them up.
{ family_in_lot && not kid_was_in && not sis_was_in:
    Across the lot the pickup's headlights came on full. The driver's door opened, and his daughter got out and stood in the rain and didn't come any closer.
}
// He said he'd say the big man wasn't here, and he did (door.ink). The Father said he'd be thanked.
{ promise_kept == 1:
    ~ promise_kept = 2
    He stopped with his hand on the door of the truck and looked back at the doorman under the light.
    BIGMAN: You told her I wasn't here.
    BIGMAN: Thanks, bud.
    FATHER: There. I told you he would.
}
FATHER: I drove home drunk for twenty years. Nobody ever took my keys. I used to think that was respect.
* [Take his keys. #check: father:cha 12 {bigman_mod()}]
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

// What he said at the pool table about kids, when the big man asked him, comes back now.
= keys_refused
{
- claims ? said_no_kids:
    BIGMAN: You haven't got kids. You said. So don't.
- claims ? said_maybe_kids:
    BIGMAN: Not that you know of, you said. Then you don't know.
- claims ? said_asked_back && family_in_lot:
    BIGMAN: You asked me if I had kids.
    He looked across the lot at the pickup in the rain.
    BIGMAN: Look at 'em. Better than me, I told you. They'll manage.
}
* [Take them anyway. #check: fighter 11]
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
~ fam += dad_walked
# done: fetch
The big man stood there in the rain without his keys. Then he started walking, along the shoulder of the highway toward town, and the doorman watched him until the dark had him.
There was no cab to call. The cab company on the wall by the payphone had closed years ago.
He put the keys behind the bar, in the drawer with the lost-and-found, for the morning.
FATHER: Nobody ever did that for me.
FATHER: I'd have hit anybody who tried.
-> clear

= to_pickup
~ fam += dad_went
# done: fetch
The daughter opened the passenger door for him and he got in. {in_truck(kid_at):The kid in the hoodie got in beside him, in the middle, where he'd have sat when he was small.} {vape_at == s_lot || in_truck(vape_at):The boyfriend got in the back without being told.}
~ family_gone()
The pickup pulled out of the lot, slowly, onto the highway toward town.
{
- took_keys:
    He had the big man's keys in his hand. He put them behind the bar, in the drawer with the lost-and-found, for the morning.
    FATHER: Nobody ever did that for me.
    FATHER: I'd have hit anybody who tried.
- close_pool.walk_him:
    FATHER: You walked him to it. That's more than carrying a message.
- else:
    FATHER: He went. You said it, and he went. I wouldn't have.
}
-> clear

= drives
~ fam += dad_drove
# done: fetch
He got into the work truck. It took him three tries to get the door shut. The lights came on and it backed out, slowly, the way a drunk man drives when he knows he's drunk, and turned onto the highway toward town.
{ family_in_lot:
    The pickup pulled out after him and followed a hundred yards back, all the way to the bend.
}
~ family_gone()
MANUAL: A licensee who knowingly allows an intoxicated patron to drive may be held liable.
WRONGMAN: Everybody in the story drove home. Everybody always does, until the one who doesn't.
-> clear


// ------------------------------------------------------------------ everybody else

=== close_banned ===
~ cleared += cl_banned
~ here = bar
~ pass(5)
{
- banned_held == 2:
    GOOD SHOES still had the last one in front of him, a third of it. He'd been making it last since before the bell.
- banned_one > 0 && banned_held == 0:
    GOOD SHOES had made the one drink last. It was still the one drink, or he said it was.
- else:
    GOOD SHOES had had six drinks, and they'd changed him the way drink changes men like that. He'd got more polite.
}
He was telling {cleared ? cl_res || slippers_both:the bartender|the woman in slippers} about property values.
// "That's the last one, then" (door.ink): he holds to it, to the letter, and makes sure everyone sees him do it.
{ banned_held == 2:
    GOOD SHOES: The last one. As agreed.
    He finished it, and stood, and got into his good coat without any help.
    GOOD SHOES: A man of his word, your doorman. I'll mention it to the owner.
    WRONGMAN: The last one. He made it last four hours. In the story there was always one who did that.
    -> clear
}
GOOD SHOES: One more, I think. For the road. And one for the lady, of course, and one for the staff.
BARTENDER: Nope. We're closed.
She said it to the till.
GOOD SHOES: With respect, I was talking to the doorman.
- (cb)
* ["You heard her." #check: father:cha 11]
    { passed:
        He said it the way you'd tell someone the time. GOOD SHOES looked at him and did the arithmetic again, the same as at the door, and got the same answer.
        GOOD SHOES: Goodnight, then. Goodnight, all.
        He put a twenty on the bar for the bartender. She left it there.
    - else:
        GOOD SHOES: I heard her, friend. I'm asking you.
        -> cb
    }
* [Walk him out. #check: fighter:dex 10]
    ~ here = door
    { passed:
        He took the coat off the stool and held it open for him, which is a thing a man can't refuse without looking like a fool, and walked him to the door in it. #sfx: door
    - else:
        GOOD SHOES: Please take your hand off me. I'm a friend of the owner's.
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
~ here = bar
~ pass(3)
HI-VIS was asleep at the bar with his head on his arms and his vest folded under his cheek.
{ knows ? hivis_room:
    Room eleven. He'd said so at the door.
- else:
    BARTENDER: He's in eleven.
    ~ knows += hivis_room
}
// His beer, if it was held at the door, is still behind the door (door.ink).
- (ch)
* (walked_up) [Wake him and walk him up.]
    ~ pass(8)
    ~ rep(rep_staff, 1)
    He walked him up the back stairs to eleven{arrivals ? hivis_cond:, with his two-four from behind the front door under the other arm}. The mill crew's rooms were all on the second floor, doors open, a card game going in one of them with the TV on and nobody watching it. Somebody at the card table said "There he is," and HI-VIS said "Here I am," and went in and sat down and was dealt a hand.
    { arrivals ? hivis_cond:
        ~ case_back = 1
        He put the case on the card table. Nobody said thank you. Somebody opened it.
    }
    { knows ? mill_closing:
        Nobody at the table was talking about Christmas. You could tell from the way nobody was talking about it.
    }
* [Wake him and point him at the stairs.]
    ~ pass(2)
    ~ hivis_landing = true
    { arrivals ? hivis_cond:
        ~ case_back = -1
    }
    He went. He found the stairs on the second try.
    { arrivals ? hivis_cond:
        His two-four was still behind the front door. Neither of them thought of it.
    }
* [Leave him. He lives here.]
    ~ rep(rep_staff, -1)
    BARTENDER: Nope. I'm not locking up with him in here.
    -> ch
- -> clear

=== close_residents ===
~ cleared += cl_res
~ here = bar
~ pass(3)
{ slippers_upstairs:
    The one who'd stayed with the bottle finished it and went up through the hotel door in her slippers, carrying the wine glass, which the bartender allowed because it always came back.
- else:
    The two women from upstairs had finished the bottle. They went up through the hotel door in their slippers, one holding the other's elbow, carrying the wine glasses, which the bartender allowed because they always came back.
}
// The twenty he lent at the card machine (bar.ink).
{ ev_card.lent && not slippers_upstairs:
    SLIPPERS: Nine, dear. I'm in nine. You'll get it, don't you worry.
}
{ not hotel_door:
    The hotel door was locked. He unlocked it for {slippers_upstairs:her|them} and held it, and {slippers_upstairs:she|they} went up, and he locked it again behind {slippers_upstairs:her|them}.
    { terry_asked:
        On the other side, at the desk, Terry was watching the game on his phone. He lifted a hand without looking up.
    }
    WRONGMAN: Every door you lock, you end up holding open for somebody.
- else:
    The hotel door was still wedged open, and {slippers_upstairs:she|they} went up through it.
    // He went through to ask Terry about the door, earlier, and then didn't (hall.ink).
    { at_hall.night_clerk.never_mind:
        On the other side, at the desk, Terry looked up from the highlights.
        TERRY: Hey, pal. You never did say what was wrong.
    }
}
-> clear

=== close_endbar ===
~ here = bar
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
{ dennis_gone():
    Four of them. The gap where Dennis sat was still a gap.
}
{ walter == 0:
    They didn't talk to him. They talked in front of him.
}
{ walter == 3:
    -> t28_find_bait ->
}
// They watched the lot through the front window, if they were still here when the big man went.
{ fam ? lot_scene && cleared ? cl_pool:
    {
    - took_keys:
        TEAM_JACKET: Took the man's keys. In this town. I did that once, in 'eighty-one. Once.
        TEAM_JACKET: I'd start my truck careful for a week or two, son, if I were you.
        TABLE28: Careful!
    - fam ? dad_drove:
        TEAM_JACKET: You let him drive, son.
        Nobody at the table said anything else about it. They'd all driven home like that. They'd be driving home like that in ten minutes.
    - else:
        TEAM_JACKET: Sent him home with his kids, did you. Huh.
        TABLE28: Hear, hear!
    }
}
// He started across the room when Dennis's wife came in, and she stopped him with a word (table28.ink).
{ wife_stopped:
    TEAM_JACKET: Dennis's wife stopped you with one word, son. I saw it. I was sitting right here.
    TEAM_JACKET: She's stopped bigger.
}
// He stood at the end of their table, earlier, and never did sit (table28.ink).
{ at_t28.standing.left_standing && not at_t28.sit:
    TEAM_JACKET: Here's the stander. Never did sit down with us, did you, big fella.
    HEARING_AID: Stander.
}
- (tt)
// RAINCOAT's message, if he never passed it on (door.ink). It's late now, by however long he sat on it.
* (dog_late) {arrivals ? wife_lied && not dennis_gone()} [Tell Dennis about the dog. {late_words(wife_at)}]
    ~ pass(2)
    ~ dog_told = true
    ~ room_count--
    ~ rep(rep_t28, -1)
    He bent down by the big glasses and said it: the dog's been sick on the bed. She'd said it at {q_words(wife_at)}.
    GLASSES: At {q_words(wife_at)}.
    Dennis looked at his watch, and then at the doorman, and got his coat on without finishing the two he had lined up.
    SCRATCH: That dog's been dead since the flood.
    TEAM_JACKET: {clock - wife_at >= 50:An hour, though|Even so}. She'll have the chain on.
    # done: dog
    -> tt
* ["Drink up, gentlemen." #check: father:cha 11]
    { passed:
        He said it the way the Father used to say it, like a favour to them, and they drank up and stood and got their coats, in the order they always did, and went out together into the rain.
        ~ rep(rep_staff, 1)
    - else:
        TABLE28: Drink up, gentlemen!
        ~ pass(15)
        They said it back to him in one voice, delighted, and didn't drink up. It was {q_words(clock)} before they went.
    }
* ["Take your time."]
    ~ rep(rep_t28, 1)
    ~ pass(25)
    They took it. The bartender put the chairs up on the tables around them and they didn't notice, or noticed and didn't care, and at {q_words(clock)} they went, together, the way they'd come.
* {walter != 0 || rep_t28 >= 0} [Sit down with them for the last one. #hand: drink]
    ~ pass(15)
    ~ pull_table++
    ~ drink()
    ~ rep(rep_t28, 1)
    He sat down. Somebody pushed a rye at him. The talk went round, and he let it go through him, and for a minute he couldn't have told you where table 28 stopped and he started.
    TABLE28: He's all right, the new kid! Isn't he? He's all right!
* ["Now. All of you."]
    ~ rep(rep_t28, -2)
    ~ rep(rep_staff, 1)
    TEAM_JACKET: The last one said that. Word for word.
    They went, slowly, to make the point. At the door the one in the team jacket stopped and patted him twice on the arm, the way you'd pat a horse that wasn't yours.
- { cardigan_secret:
    -> secret
}
-> t28_out

// The one in the cardigan asked him on the deck not to tell the table where he was (deck.ink).
= secret
TEAM_JACKET: Where'd you get to earlier, anyway? You were gone half an hour.
CARDIGAN: The washroom.
TEAM_JACKET: Half an hour in the can! At our age that's a medical event.
The one in the cardigan didn't look at the doorman.
* [Say nothing.]
    ~ secret_kept = 1
    TABLE28: A medical event!
    They let it go. They'd let worse go.
* ["He was out on the deck with me."]
    ~ secret_kept = -1
    ~ rep(rep_t28, 1)
    TABLE28: The deck!
    TEAM_JACKET: Smoking! He quit!
    CARDIGAN: I've quit a good many times.
    They gave him a hard time about it all the way to the door, and loved it, and he took it.
    FATHER: He asked you one thing.
- -> t28_out

= t28_out
{
- secret_kept == -1:
    The one in the cardigan went out in the middle of them, being given a hard time, and didn't look back at the doorman.
- cardigan_go == 1:
    The one in the cardigan went out last. At the door he nodded to the doorman, once, as if they'd agreed on something.
- cardigan_go == -1:
    The one in the cardigan went out in the middle of them, where he always went. He'd be in his chair on Thursday.
- cardigan_go == 2:
    The one in the cardigan stopped at the door and looked back at the table, with the chairs up on it now, for a while. Then he went after them.
- secret_kept == 1:
    The one in the cardigan went out last, and touched the doorman's arm on the way past, once, without looking at him.
}
They went out to their trucks, and all of them drove. Everybody drove, out here.
{ knows ? t28_nine:
    There had been nine of them once, the one in the cardigan had said. You couldn't get a chair.
}
FATHER: {took_keys:You took one set of keys tonight. }You can't take {dennis_gone():four|five} sets off table 28. You'd be taking the whole town's.
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
// The bartender called it in after the fight, and it's forty minutes out here: sometimes that's after close.
{ police_called && not police_seen:
    -> ev_police ->
}
// Who got past him tonight: the bartender rings in every drink, and she knows whose faces she
// served that never came past the stool. Nobody did, and that's the end of it; somebody did, and
// she wants to know how before he writes the log.
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

// What turns up explains the ones who got past him (found_why). Whether it explains all of them is
// what she wants to know before he writes the log (search_missed).
=== function search_missed()
{ ((fam ? via_deck && not ev_deck_kids.counted) || vape_backs > 0) && found_why !? why_deck:
    ~ return true
}
{ arrivals ? hivis_hotel && found_why !? why_hotel:
    ~ return true
}
{ (arrivals ? banned_inside || walk_ins > 0) && found_why !? why_front:
    ~ return true
}
{ walk_ins > 0 && found_why !? why_sleeper:
    ~ return true
}
~ return false

=== search ===
~ here = floor
- (s)
* {deck_door || fam ? via_deck || vape_backs > 0} [The deck door.]
    ~ pass(2)
    { fam ? via_deck:
        The prints on the carpet from the deck door had dried to a tide line. Three pairs, going in.
        { ev_deck_kids.counted:
            He'd let those three in himself, after, in the middle of the room. They weren't the ones.
        }
    }
    { vape_backs > 0:
        And another pair, bigger, {vape_backs > 1:twice over, }on top of the rest. The boyfriend, coming back in the back.
    }
    { (fam ? via_deck && not ev_deck_kids.counted) || vape_backs > 0:
        ~ found_why += why_deck
    }
    { deck_door:
        The coaster was still in the latch. He took it out, and the door locked.
        ~ deck_door = false
    - else:
        Locked.
    }
    { doors_left ? left_deck && found_why ? why_deck:
        He'd stood at this door earlier, on his walk, and looked at the coaster, and left it.
    }
    -> s
* {hotel_door || arrivals ? hivis_hotel} [The hotel door.]
    ~ pass(2)
    { arrivals ? hivis_hotel:
        ~ found_why += why_hotel
        HI-VIS had come down that way. {at_hall.hivis_stairs:He'd watched him do it.|He hadn't seen him do it.}
        { doors_left ? left_hotel:
            He'd seen the wedge under it on his walk, and left it there.
        }
    }
    { hotel_door:
        The wedge was still under it. He kicked it out, and the door latched.
        ~ hotel_door = false
    - else:
        Shut{terry_asked:, the way Terry had said he'd leave it}.
    }
    -> s
* {kitchen_door} [The kitchen door.]
    ~ pass(3)
    The milk crate was still in the back door, and the rain was coming in on the tiles. {doors_left ? left_kitchen:It was where it had been when he walked the doors and left it.} He took it out, and locked the door, and checked it twice.
    ~ kitchen_door = false
    -> s
* {arrivals ? banned_inside || walk_ins > 0} [The front door, while he was away from it.]
    ~ pass(1)
    ~ found_why += why_front
    { arrivals ? banned_inside:
        GOOD SHOES had come in the front, past the empty stool, while he was somewhere else.
    }
    {
    - walk_ins > 0 && walk_ins_seen > 0:
        {arrivals ? banned_inside:So had whoever left the wet prints on the mat he'd come back to.|Whoever left the wet prints on the mat he'd come back to had come in the front while he was somewhere else.}
    - walk_ins > 0:
        {arrivals ? banned_inside:And others, maybe.|Somebody had come in the front while he was away, maybe. More than one.} Nobody counts the ones who come in while nobody's counting.
    }
    FATHER: A door's only a door when somebody's standing in it.
    -> s
* {walk_ins > 0} [The single washroom.]
    ~ pass(3)
    ~ found_why += why_sleeper
    A man he'd never seen before was asleep on the floor of the single washroom, with his head on a roll of paper towel. He'd never passed the door. Nobody knew him, and he didn't know where he was.
    He woke him and walked him out to the lot and pointed him at the highway.
    WRONGMAN: The one you didn't count. It's always the one you didn't count.
    -> s
+ [That's enough. Write the log.]
    { search_missed():
        BARTENDER: So we don't know who.
        ~ rep(rep_staff, -1)
    - else:
        BARTENDER: Yep. Write it.
        ~ rep(rep_staff, 1)
    }
    -> incident_log


// ------------------------------------------------------------------ the incident log

=== incident_log ===
~ here = bar
# done: past
# screen: log
The incident log was a hardback ledger that lived under the till with the binder. Every doorman before him had written in it, in nine different hands, going back further than the owner.
The bartender pushed it along the bar to him with a pen.
// HUTCH: What does a real incident log look like? The book, the wording, what gets written down and what never does.
{ LIST_COUNT(incident) == 0:
    Nothing had happened. He wrote the date and NOTHING TO REPORT, and she read it upside down.
    BARTENDER: Ten of you now, and that's the first time I've seen that on a first night.
    -> log_close
}
-> log_next

// One incident at a time: what it is, what he writes, in his own hand. Writing the office down
// costs the staff (whoever it was, the owner fires all of them); leaving it out is having their backs,
// not lying to himself. Leaving the fight out, after she said "your name on the log", is a lie to her.
= log_next
~ temp todo = incident - logged - shaded - left_out
{ LIST_COUNT(todo) == 0:
    -> log_done
}
~ temp x = LIST_MIN(todo)
{inc_name(x)}
+ [Write it down the way it happened.]
    ~ logged += x
    { x == inc_drinking || x == inc_hurt:
        ~ cocoon--
    }
    { x == inc_office:
        ~ rep(rep_staff, -2)
    }
    {inc_text(x)} #class: entry
+ [Write it so it reads better. #hand: shade]
    ~ shaded += x
    { x == inc_drinking || x == inc_hurt || x == inc_banned || x == inc_deck || x == inc_no_id || x == inc_police || x == inc_lot:
        ~ cocoon++
    }
    { x == inc_office:
        ~ rep(rep_staff, -1)
    }
    {inc_shade(x)} #class: entry
+ [Leave it out. #hand: omit]
    ~ left_out += x
    { x != inc_office:
        ~ cocoon++
    }
    { x == inc_fight && name_on_log:
        ~ rep(rep_staff, -2)
    }
    He {stopping:didn't write it.|left that one out too.|left it out.}
- -> log_next

= log_done
She turned the book round and read it.
{
- logged ? inc_office:
    BARTENDER: You wrote down the office.
    She looked at the line for a long time.
    BARTENDER: Junior reads that, he doesn't fire whoever it was. He fires all of us and starts again. That's all that line does.
- shaded ? inc_office:
    BARTENDER: Office left untidy.
    She almost laughed.
}
{ left_out ? inc_fight && name_on_log:
    BARTENDER: Your name on it, I said. There's nothing on it.
}
{
- LIST_COUNT(shaded) + LIST_COUNT(left_out) == 0:
    BARTENDER: Huh.
    She turned it back.
    BARTENDER: Junior'll hate that. Every word of it's true.
    ~ rep(rep_staff, 1)
- LIST_COUNT((shaded + left_out) ^ she_saw()) > 0:
    BARTENDER: That's not what happened.
    BARTENDER: Your book, Door. You write what you want in it.
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
{ knows ? juke_top:
    It was the one at the top of the jukebox's list, the one he'd never seen anybody choose.
}
{ drinks >= 3:
    -> water
}
She'd poured two. She pushed the other one along the bar to him without looking up from the twenties.
* [Drink it. #hand: drink]
    ~ last_glass = 1
    ~ drink()
    FATHER: {Num(drinks)}. After hours still counts.
* [Leave it standing.]
    ~ last_glass = 2
    He left it where it was, full, on the bar. She didn't say anything about it.
    { knows ? endbar_seen:
        It looked like the old man's glass, down at the end. It looked exactly like it.
    }
* [Push it back.]
    ~ last_glass = 3
    BARTENDER: Suit yourself.
    She drank it, and then she drank hers.
- -> door_story

// He's had three or more. She's counted.
= water
~ last_glass = 4
She'd poured herself a rye. For him she put a pint glass of water on the bar, without looking up from the twenties.
BARTENDER: {Num(drinks)}. I counted too.
* (drank_water) [Drink the water.]
    He drank all of it. It was the best thing he'd had all night.
    FATHER: Good.
* [Ask for a rye. #hand: drink]
    ~ rep(rep_staff, -1)
    BARTENDER: Nope.
    She didn't look up.
- -> door_story

= door_story
BARTENDER: So. Why'd you leave your last door?
// She's had what he told Gary, from Gary, on the phone at quarter past five (walk.ink, under_window).
{ told_why():
    BARTENDER: I've had what you told Junior. I'm asking you.
}
// HUTCH: Why DID he leave his last door? Every answer below becomes true once he says it. Is one of them the real one?
* (owned_up) {knows ? heard_phone} ["You had it from Gary, on the deck. I was up in twelve."]
    ~ rep(rep_staff, 1)
    She stopped counting.
    BARTENDER: Twelve's over the deck. I forgot.
    BARTENDER: Then you heard what I said about it. I'm not saying it twice.
    // what he told Gary is what's true, then
    {
    - told_gary ? tg_shorted:
        ~ claims += said_left_bad_owner
    - told_gary ? tg_something:
        ~ claims += said_left_something
    - told_gary ? tg_long:
        ~ claims += said_left_long_story
    - told_gary ? tg_quiet:
        ~ claims += said_nothing
    }
    She went back to the twenties.
* ["The owner shorted me."]
    ~ claims += said_left_bad_owner
    BARTENDER: They all short you. You'll find out.
* ["Something happened."]
    ~ claims += said_left_something
    She waited. He didn't say what. She nodded as if that was an answer, which in a bar it is.
* ["Long story."]
    ~ claims += said_left_long_story
    BARTENDER: Yep. They're all long stories.
* [Say nothing.]
    ~ claims += said_nothing
    She looked at him over the rye, and went back to the count.
// People compare notes (bible/02_SYSTEMS.md): what he told Gary in the office, and what he told
// table 28, put next to what he just told her.
- { not owned_up && told_why():
    {
    - (told_gary ? tg_shorted && claims ? said_left_bad_owner) || (told_gary ? tg_something && claims ? said_left_something) || (told_gary ? tg_long && claims ? said_left_long_story) || (told_gary ? tg_quiet && claims ? said_nothing):
        BARTENDER: Same as you told Junior. Good.
    - else:
        BARTENDER: That's not what you told Junior. Pick one, Door.
    }
}
{
- claims ? said_city_line:
    BARTENDER: Table 28 says you did ten years on a door with a line outside it.
    BARTENDER: By Friday it'll be twenty, and you'll have put a hockey player through a window.
- claims ? said_city_unnamed:
    BARTENDER: Table 28 says you did ten years on a door in the city, and you won't say which.
    BARTENDER: That's worse than any door you could have named. They'll fill it in themselves.
- claims ? said_father:
    BARTENDER: Table 28 says your old man worked doors. {father_named:The one in the cardigan's been saying his name to himself all night, like he's trying to place it.}
- claims ? said_up_island:
    BARTENDER: Up island, table 28 says. Everybody's from up island.
- claims ? said_around:
    BARTENDER: Table 28 have decided you're from Around. That's what they're calling it now. Around.
- else:
    BARTENDER: Table 28 don't know where you're from. You never went over.
    BARTENDER: That'll eat them alive by Friday.
}
// Where he told Gary he was from, against where he told table 28.
~ temp gw = 0
~ temp tw = 0
{
- told_gary ? tg_city:
    ~ gw = 1
- told_gary ? tg_up_island:
    ~ gw = 2
- told_gary ? tg_around:
    ~ gw = 3
- told_gary ? tg_father:
    ~ gw = 4
}
{
- claims ? said_city_door:
    ~ tw = 1
- claims ? said_up_island:
    ~ tw = 2
- claims ? said_around:
    ~ tw = 3
- claims ? said_father:
    ~ tw = 4
}
{ gw > 0 && tw > 0:
    { gw == tw:
        BARTENDER: Same as you told Junior, at least.
    - else:
        BARTENDER: And Junior had it different again. Pick one before Friday, or they'll pick it for you.
    }
}
{
- claims ? said_left_something && (claims ? said_city_unnamed || claims ? said_city_line):
    BARTENDER: Ten years on a door, and something happened. Don't give them that part. They'll have it worse than it was by Friday.
- claims ? said_nothing && claims ? said_around:
    BARTENDER: From Around, and not saying. You'll fit in here.
- claims ? said_left_bad_owner && owner_count == -1:
    BARTENDER: Shorted you. And you told this one it was busy. You'll get on.
}
// What she says about the night: two things at most, the ones that matter most to her.
~ temp said = 0
{ office_wiped:
    ~ said++
    She'd been down to put the float in the safe. She came back up the stairs and stopped at the top with the trapdoor open, and looked at him.
    BARTENDER: Somebody's been tidying in the office.
    She didn't say whose it was. She didn't say thanks, either, in so many words.
}
{ took_keys && said < 2:
    ~ said++
    She found the big man's keys in the lost-and-found drawer when she put the float bag away, and held them up.
    BARTENDER: He'll be in for these at noon, sorry for himself.
    BARTENDER: You'll be asleep upstairs. I'll be here.
}
{ owner_count == -1 && said < 2:
    ~ said++
    BARTENDER: Busy, you told him.
    She tapped the till tape.
    BARTENDER: He'll have this at nine.
}
{ owner_lie && said < 2:
    ~ said++
    BARTENDER: It's handled, you told him. The rats.
    BARTENDER: Inspector's on the fourteenth. I'd get it handled.
}
{ promise_kept >= 1 && said < 2:
    ~ said++
    BARTENDER: You told that girl her father wasn't here.
    BARTENDER: I saw her face. Through two doors, I saw it.
}
{ banned_held == 1 && said < 2:
    ~ said++
    BARTENDER: One drink, and you put him out after it.
    BARTENDER: Nine doormen. Not one of them ever did what they said with that man.
}
{ scans ? scan_goodshoes && said < 2:
    ~ said++
    { arrivals ? banned_in:
        BARTENDER: You scanned his licence. Ardagh. The machine keeps them, with the time.
        BARTENDER: So if the owner ever wants to know who let him in, it's on there.
    - else:
        BARTENDER: You scanned his licence before you sent him off. Good. If he says he was never here, the machine says he was.
    }
}
{ knows ? banned_story && said < 2:
    ~ said++
    BARTENDER: He tell you what he did? Ardagh?
    He said the man had said he'd paid for it.
    BARTENDER: He says that.
    She didn't say what it was. She'd written NOT EVER under his picture instead, and that was all she was going to say about it, then or ever.
}
{ kitchen_door_shut > 1 && said < 2:
    ~ said++
    BARTENDER: The cook says you shut his door on him {kitchen_door_shut == 2:twice|{num(kitchen_door_shut)} times}.
    BARTENDER: He says it like you did it to his face.
}
{ ev_card.lent && said < 2:
    ~ said++
    BARTENDER: You lent nine twenty.
    BARTENDER: She'll pay you back. That's the worst part.
}
{ case_back == -1 && said < 2:
    ~ said++
    BARTENDER: And there's a two-four behind my front door.
    BARTENDER: That's mine now. If he asks, it was always mine.
}
BARTENDER: Junior'll call me in the morning and ask how you did.
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
{ knows ? doorman_stories:
    -> last_doorman
}
-> goodnight

// Table 28 told him four stories about the last doorman (table28.ink).
= last_doorman
* ["Table 28 told me about the last doorman. Which one's true?"]
    BARTENDER: Which ones did they tell you?
    He told her. The pay, the big rat, the woman, the one he let in.
    She laughed, once, at the till.
    BARTENDER: His jacket's in the lost-and-found. Folded at the bottom of the drawer, under three winters of toques and phone chargers. Nobody's been through the pockets.
    BARTENDER: You want to know which one's true, that's where it'll be. I never wanted to know.
    ~ knows += lost_jacket
    { took_keys:
        The big man's keys were in the same drawer now, on top of it.
    }
* (didnt_ask) [Don't ask.]
- -> goodnight

= goodnight
// "Last a week. Then ask me" (bar.ink). If she's telling the owner he'll do, she shortens it.
{ asked_name && verdict == 2:
    BARTENDER: And you asked me something, earlier.
    BARTENDER: Ask me Friday.
}
BARTENDER: Go on up. Get some sleep, Door.
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
ENDBAR: You came down, Doorman.
Past the last keg, in the dark toward the front of the building, a sound like a lot of hands being rubbed together. It stopped when the old man lifted one finger. #sfx: scratch
// HUTCH: The first parley with the Rat King. The terms here are drafts. What would they want from a doorman, and what could they give him?
FATHER: Go back up.
WRONGMAN: This is the story. This is the one they'll tell about you.
-> terms

// What the old man has to say about the night comes first: the war, the bait, Walter, and the
// courtesies and the kills. Two of the small things he noticed, at most, and he notices a lot.
= terms
{ rats == war:
    ENDBAR: You have started a war. That is all right. Most do, the first night.
}
{ poison:
    ENDBAR: There is poison down. Some of them have eaten it. They will go into the walls to die, and on Friday you will smell them, and so will your customers, and so will the man from the health.
}
{ walter == 0:
    ENDBAR: And you killed the one at the table. The one they fed. That one had a name. Names cost more.
}
{ walter == 3:
    ENDBAR: And you put it in the one hole the one at the table goes in and out of. He has eaten it. He will be days about it, in the wall behind their chairs. That one had a name. Names cost more.
}
{ rat_favour > 0:
    ENDBAR: You have been courteous. That is noticed.
}
~ temp noticed = 0
{ nursed:
    ~ noticed++
    ENDBAR: You held a glass at that table and did not drink it. Like me.
}
{ last_glass == 2 && noticed < 2:
    ~ noticed++
    ENDBAR: And you left hers standing full on the bar, after. {nursed:Twice in a night.|Like me.}
}
{ traps_reset && noticed < 2:
    ~ noticed++
    ENDBAR: You reset the traps after the first one. That is noticed too. Differently.
}
{ poison_at ? keg && knows ? cook_advice && noticed < 2:
    ~ noticed++
    ENDBAR: You put the bait where the cook told you. Where we live. The cook should be careful what he tells people.
}
{ at_kitchen.garbage.brick_out && noticed < 2:
    ~ noticed++
    ENDBAR: You let the lid down on the bins. So tomorrow night I go up that alley in the rain and prop it again. At my age.
}
{ knows ? cook_fries && noticed < 2:
    ~ noticed++
    ENDBAR: The cook fries an extra basket on Wednesdays. He thinks nobody knows. Now you know, and we know you know.
}
{ knows ? rat_numbers && noticed < 2:
    ~ noticed++
    ENDBAR: Fifty for every one you see, the cook told you. The cook cannot count.
}
{ rats_killed > 0 && walter != 0:
    ENDBAR: {rats_killed == 1:You have killed one|You have killed {num(rats_killed)}}. That is noticed too.
}
- (t)
* (asked_who) ["Who are you?"]
    ~ knows += endbar_dock
    ENDBAR: I am the one who comes down.
    ENDBAR: I was coming in here before she started. Before the owner's father owned it. Before it was a hotel, I was on the dock they built it on.
    He didn't look old enough for that. He didn't look young enough for anything else.
    -> t
* (want) ["What do they want?"]
    ENDBAR: What anyone wants. To eat, and not be killed.
    ENDBAR: Food on the third step, every night you are on. The kitchen door on the latch after the cook goes home. {poison:And you take up what you put down.|And no poison. Not in this building.}
    -> t
* (what_get) ["What do I get?"]
    ENDBAR: Quiet. Nobody sees one of them on the fourteenth. Not the inspector, not a customer, not the cook.
    ENDBAR: And they hear everything. Every word said at that table, and under every table, and behind every door in this building. You would be surprised what gets said about a doorman.
    -> t
* {what_get} ["What have they heard?"]
    -> overheard
* (saw_it) {knows ? knot_seen} ["I saw it. In the wall."]
    ENDBAR: Then you know what you are talking to.
    ENDBAR: It has been in that wall longer than there has been a wall. The table feeds it and does not know they do. It hears them. It hears everyone.
    -> t
+ {want} ["Done. Those terms."]
    -> deal
// Having seen the thing in the wall, he knows what he's bargaining with.
* {want} ["The step, and no poison. Not the kitchen door." #check: wrongman 12 {saw_it:1|0}]
    -> bargain
+ ["No. They're going."]
    -> refuse
* [Tell him you'll burn them out.]
    -> threaten
+ ["I'll think about it."]
    -> think

// What the rats heard him say tonight (rats_heard, and the claims he made where there was a wall
// or a floor beside him), four things at most; and what they heard her say on the phone to the owner.
= overheard
ENDBAR: About you?
ENDBAR: Everything you said tonight where there was a floor under you or a wall beside you.
~ temp n = 0
{ rats_heard ? h_boot:
    ~ n++
    ENDBAR: You put your boot down at that table. On one of ours.
}
{ rats_heard ? h_father:
    ~ n++
    ENDBAR: You told the table your father worked doors{father_named:, and you told them his name}.
}
{ n < 4 && (claims ? said_father_stopped || claims ? said_father_doors):
    ~ n++
    ENDBAR: And in the washroom, to the boy, you said {claims ? said_father_dead:your father died before you had worked it out|{claims ? said_father_stopped:your father drank for twenty years and then stopped|your father worked doors, like you}}.
}
{ n < 4 && rats_heard ? h_city:
    ~ n++
    ENDBAR: Ten years on a door in the city, you told them{claims ? said_city_unnamed:, and you would not say which|{claims ? said_city_line:, the kind with a line outside}}. They have been talking about it underneath it since.
}
{ n < 4 && claims ? said_no_kids:
    ~ n++
    ENDBAR: You told the man at the pool table you have no children. He believed you.
}
{ n < 4 && rats_heard ? h_leave_walter:
    ~ n++
    ENDBAR: You said leave him, at the table. About one of ours. They liked that. So did we.
}
{ n < 4 && rats_heard ? h_owner_rats:
    ~ n++
    ENDBAR: You told the table the owner wants us gone. We know what the owner wants. We have known three owners.
}
{ n < 4 && rats_heard ? h_no_rats:
    ~ n++
    ENDBAR: You asked them about rats, and they told you there were none. That is the arrangement.
}
{ n < 4 && rats_heard ? h_walter:
    ~ n++
    ENDBAR: You asked how long he had been coming to that table. Nobody asks.
}
{ n < 4 && rats_heard ? h_said_no:
    ~ n++
    ENDBAR: She asked if you had found anything down here, and you said no.
}
{ n < 4 && rats_heard ? h_said_down:
    ~ n++
    ENDBAR: You told her we are down here. She has always known.
}
{ n < 4 && rats_heard ? h_lid:
    ~ n++
    {
    - at_keg.lay_poison.lid_back && at_keg.set_traps.traps_back:
        ENDBAR: You put the lid back on the bucket, and the traps back on the shelf.
    - at_keg.set_traps.traps_back:
        ENDBAR: You put the traps back on the shelf, in their plastic.
    - else:
        ENDBAR: You put the lid back on the bucket.
    }
}
{ n < 4 && rats_heard ? h_left_trap:
    ~ n++
    ENDBAR: You left one in the trap where the others would see it. They saw it.
}
{ n == 0:
    ENDBAR: Not much. You do not say much. That is noticed too.
}
// "Yep," and "Yep" (bar.ink, hang_up): what the owner asked her, about him.
{ ev_owner.hang_up:
    ENDBAR: And when the owner rang, she said Yep, twice. You heard her. You did not hear what he asked.
    { rep_staff >= 0:
        ENDBAR: He asked her if you were any good. Yep. Then he asked her to tell him if you were not. Yep.
    - else:
        ENDBAR: He asked her if you would last the week. Yep. Then he asked her if that was a good thing, and she said Yep again, the same way, and he could not tell. Neither could we.
    }
}
-> t

= deal
~ parley = 2
~ rats = truce
ENDBAR: Very good.
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
    ENDBAR: The step, then. And no poison. We will find our own doors.
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
    ENDBAR: Come down again when you are ready to talk like somebody who needs something.
    ~ parley = 1
}
-> after_parley

= refuse
~ parley = 1
~ go_to_war()
ENDBAR: Then it is the long way.
He stood up. His knees cracked. He left the full glass on the floor.
ENDBAR: It is always the long way, the first time.
When the doorman looked back from the stairs, the light was off, and the keg was only a keg.
FIGHTER: Good.
-> after_parley

= threaten
~ parley = 1
~ rats = hostile
He said it. He said he'd burn them out.
ENDBAR: Then you will burn the hotel down with them. They are in every wall. They were here before the walls.
He stood up, slowly, and picked up the full glass, and poured it out on the dirt, all of it, and set the empty glass on the keg.
ENDBAR: That is the first time I have done that.
When the doorman looked back from the stairs, the light was off.
FATHER: You shouldn't have said that. Not because it was wrong. Because you meant it, and now it knows.
-> after_parley

= think
~ parley = 1
ENDBAR: Think, then. They will not wait for you. They will double while you think. They always do.
-> after_parley

// Terms that include the kitchen door start tonight: the cook's gone home.
= after_parley
{ parley == 2 && terms_door:
    -> latch
}
He went back up the stairs, stepping over the third one. Behind him the scratching started again, and went on, and he could still hear it from the top.
-> go_upstairs

= latch
He went back up the stairs, stepping over the third one. Behind him the scratching started again.
The kitchen was dark. {kitchen_door:The milk crate was still in the back door, where the cook had left it.|The back door was locked, the way he'd left it.}
* [Put the back door on the latch, the way he said.]
    ~ terms_kept = 1
    ~ kitchen_door = true
    He went through the dark kitchen and set the back door on the latch, so it would give to a push from the alley, and left it like that.
    FATHER: Every door you leave open, something comes in. This time you know what.
* [Leave it. Go up.]
    ~ terms_kept = -1
    WRONGMAN: Day one. In the story the deal was broken on day one, too. That's how you knew it was a deal.
- -> go_upstairs


// ------------------------------------------------------------------ upstairs

=== go_upstairs ===
~ here = upstairs
{ clock < 1640:
    ~ clock = 1640
}
# music: none
# amb: none
He went up through the hotel door and the stairs that smelled of other people's cooking.
// Pointed at the stairs at close, HI-VIS got as far as the landing (close_hivis).
{ hivis_landing:
    -> landing
}
-> crew

= landing
On the first landing HI-VIS was asleep sitting up against the wall, with his boots on and his vest folded under his head. He'd made it that far.
* [Get him up the rest of the way to eleven.]
    ~ pass(5)
    ~ hivis_landing = false
    He got an arm under him and walked him up the last flight and along the hall to eleven, and put him through his own door, and shut it on him.
    HI-VIS: Here I am.
    He said it to the dark room. There was nobody in it to say it to.
* (stepped_over) [Step over him.]
    He stepped over him. HI-VIS said "Night," without waking up.
    MANUAL: The licensee's duty of care ends at the door of the licensed premises. You are past it.
- -> crew

// The mill crew's card game on the second floor, which HI-VIS may or may not have made it back to.
= crew
{
- close_hivis.walked_up:
    Along the second floor, the card game in the mill crew's room was still going, with the door open and the TV on. {case_back == 1:The two-four he'd carried up was half gone.} Nobody looked up.
- arrivals !? hivis_in && arrivals !? hivis_hotel:
    Along the second floor the mill crew's doors were open, and a card game was going in one of them with the TV on and nobody watching it. HI-VIS was at the card table in his socks, with a can of his own beer. He lifted it an inch at the doorman going past.
    { incident ? inc_hivis:
        It could have meant no hard feelings. It could have meant all of them.
    }
- else:
    Along the second floor the mill crew's doors were open, and a card game was going in one of them with the TV on and nobody watching it.
}
{ knows ? mill_closing:
    Somebody at the table said Christmas, and somebody else said they'd been saying Christmas for six years, and somebody dealt.
}
// He may have been up already, before the shift (walk.ink, twelve).
{ from_room:
    His room was at the end of the second floor, over the deck, where he'd lain on the bed before the shift and listened to the bartender tell Gary about him through two inches of window.
    { shirt == 1 && not shirt_on:
        Gary's shirt was on the chair where he'd left it, folded, the word inside.
    }
- else:
    His room was at the end of the second floor, over the deck. It came with the job.
    A bed, a chair, a sink in the corner, and a window onto the lot and the highway and the water. The rent came off his pay. The owner had mentioned that before he'd mentioned anything else.
}
// HUTCH: His room. What does a room that comes with a bar job look like, and what did he bring with him?
// The light the kid at the Esso showed him at dusk (walk.ink, kid_sky).
{ knows ? esso_sky:
    Out the window, low over the strait where the cloud had torn again, was the light the kid at the Esso had shown him. It hadn't moved. He watched it until he was sure it hadn't, and for a while after that.
}
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
-> night_talk ->
{ not wants_table() && not wants_kid():
    -> ledger
}
There was somebody new in his head, talking over the others.
{ wants_table():
    TABLE: We were here first. #always
    TABLE: Sit down. Nobody stands at this table. #always
    { knows ? t28_nine:
        TABLE: We were nine, once. There's a chair. #always
    }
    It wasn't one of them. It was all five at once, sure of everything, and it had come in with the rye.
}
{ wants_kid():
    KID: i'm not high #always
    KID: i just haven't slept #always
    It was the kid in the washroom. It didn't say much. What it said, it said about things the others couldn't see.
}
FATHER: Don't let that in.
- (vs)
* {wants_table()} [Let THE TABLE in. #room: +table]
    -> let_voice_in("table")
* {wants_kid()} [Let THE KID in. #room: +kid]
    -> let_voice_in("kid")
+ [Sleep.]
    { new_voice == "":
        The new voice went on talking outside the room for a while. Then he was asleep.
    - else:
        He was asleep before the voices were finished with him.
    }
    -> ledger

// The voices go back over the night, one thing each, the Father last. A voice that isn't in the room
// doesn't get to say it (content/ink/README.md).
=== night_talk ===
The voices went back over the night, the way they did. The Father last.
{
- hurt > 0:
    FIGHTER: The eye'll close by morning. Ice it. Or don't, and let them see it on Friday.
- fam ? pool_fight:
    FIGHTER: You were first. That's all it ever is. Be first.
- rats_killed > 0:
    FIGHTER: {Num(rats_killed)}. Out of how many.
- else:
    FIGHTER: Nobody swung at you. Friday somebody will.
}
{
- LIST_COUNT(incident) == 0:
    MANUAL: Nothing to report. The manual has no section on how that feels.
- LIST_COUNT(left_out) > 0:
    MANUAL: The incident log is a legal document. {Num(LIST_COUNT(left_out))} {LIST_COUNT(left_out) == 1:incident is|incidents are} not in it.
- LIST_COUNT(shaded) > 0:
    MANUAL: The incident log is a legal document. It now contains {num(LIST_COUNT(shaded))} {LIST_COUNT(shaded) == 1:statement|statements} that {LIST_COUNT(shaded) == 1:is|are} not quite true.
- else:
    MANUAL: The incident log is a legal document. Every entry in it is accurate. This is rarer than you would think.
}
{
- uncounted > 0 && search_missed():
    WRONGMAN: Somebody got in tonight you never saw. In the story there was always one.
- knows ? knot_seen:
    WRONGMAN: Nobody believes the one who saw it. So don't say.
- parley > 0:
    WRONGMAN: You went down. In the story he went down too. Nobody remembered what he said down there, only that he came back up.
- after_hours.didnt_ask:
    WRONGMAN: You didn't ask her which story was true. Good. In the story, the one who asks is the next one gone.
- else:
    WRONGMAN: Wednesday. Nothing happens on a Wednesday. That's what they'll say.
}
{
- knows ? endbar_dock && knows ? knot_seen:
    FATHER: The man on the docks, who told me he'd seen one. He had a good jacket too. I never asked his name either.
- claims ? said_father_dead:
    FATHER: You told that kid I died before you worked it out.
    FATHER: Worked what out?
- father_misread && at_hall.kid_talk:
    FATHER: I said that boy was high. He hadn't slept. I was wrong about him.
    FATHER: I don't say that. Don't get used to it.
- picked_receiver:
    FATHER: The phone in the hall. There's nobody on the other end of that. I used to pick it up anyway.
- fam ? dad_drove:
    FATHER: He drove. Lie there and listen for the sirens. I'll listen with you. I owe somebody that.
- claims ? said_helped_others:
    FATHER: It helped everybody else, you told him. That's the nicest thing you ever said about me, and you said it to a stranger in a toilet.
- ev_wife_inside.let_her:
    FATHER: Thirty years, she said, and not one of you ever stopped him at the door.
    FATHER: I'd have hated any man who tried. I'd have gone home, though.
- last_glass == 3:
    FATHER: You pushed it back. I never pushed one back in my life. I just stopped picking them up.
- at_hall.payphone.left_receiver && drinks >= 2:
    FATHER: Tuesdays at seven. You looked at that one longer than you looked at the phone numbers.
- knows ? aa_wall && not picked_receiver:
    FATHER: Tuesdays at seven. I wonder if it's still the same coffee.
- drinks >= 3:
    FATHER: {Num(drinks)}. I counted. You'll count them again tomorrow, in the mirror.
- drinks == 0:
    FATHER: Not one. Not one, all night. I don't know what to do with that.
- else:
    FATHER: You'll do. That's what I'd have said. You'll do.
}
->->

=== let_voice_in(v) ===
{ seats_free() > 0:
    ~ seat(v)
    -> welcomed(v)
}
The room held five, and it had five. Somebody would have to go.
+ {seated("fighter")} [Put THE FIGHTER out. #room: -fighter +{v}]
    ~ unseat("fighter")
+ {seated("manual")} [Put THE MANUAL out. #room: -manual +{v}]
    ~ unseat("manual")
+ {seated("wrongman")} [Put THE WRONG MAN out. #room: -wrongman +{v}]
    ~ unseat("wrongman")
+ {seated("table")} [Put THE TABLE out. #room: -table +{v}]
    ~ unseat("table")
+ {seated("father")} [Put THE FATHER out. #room: -father +{v}]
    ~ unseat("father")
    It was quiet where he'd been. It was the quietest his head had been since the funeral.
+ [Nobody. Keep the room as it is.]
    -> voices_at_night.vs
- ~ seat(v)
-> welcomed(v)

=== welcomed(v) ===
~ new_voice = v
{ v == "table":
    TABLE: There he is! #always
- else:
    KID: ok #always
}
-> voices_at_night.vs


// ------------------------------------------------------------------ 3:20 am: the ledger

// The night's tally prints like a till tape (#screen: ledger), under a picture of the hotel from the
// lot after close. A line tagged #class: row is "What: how much", printed with dots between; the
// other classes are in content/ink/README.md. The printer stops for a moment before the bartender's
// word (#class: total). Everything on it is something he did, or didn't.

// Who's in his head at dawn, for the till tape: the new ones first, marked.
=== function heads()
~ temp s = ""
{ seated("table"):
    ~ s = comma(s) + "THE TABLE (new)"
}
{ seated("kid"):
    ~ s = comma(s) + "THE KID (new)"
}
{ seated("father"):
    ~ s = comma(s) + "THE FATHER"
}
{ seated("fighter"):
    ~ s = comma(s) + "THE FIGHTER"
}
{ seated("manual"):
    ~ s = comma(s) + "THE MANUAL"
}
{ seated("wrongman"):
    ~ s = comma(s) + "THE WRONG MAN"
}
~ return s

=== function comma(s)
{ s == "":
    ~ return ""
}
~ return s + ", "

=== function any_word()
~ return last_word("t28") != "" || last_word("kids") != "" || last_word("cook") != "" || last_word("owner") != "" || last_word("staff") != ""

=== ledger ===
~ here = upstairs
# plate: lot
// How he tells it, years later, depends on what he told himself tonight (cocoon: the log, the constable).
{
- cocoon >= 3:
    NARRATOR: That was Wednesday. The way he tells it now, nothing much happened.
- cocoon <= -1:
    NARRATOR: That was Wednesday. The one nobody else remembers. He remembers all of it.
- else:
    NARRATOR: That was Wednesday. The one nobody else remembers.
}
# screen: ledger
THE SOVEREIGN HOTEL #class: head
WEDNESDAY. THE TEST SHIFT. #class: head
The door: {count_in} in past the stool #class: row
{ uncounted > 0:
    And {uncounted} more some other way. #class: sub
- else:
    Nobody got past him. #class: sub
}
{ cash >= 0:
    In his pocket: ${cash} #class: row
- else:
    In his pocket: nothing #class: row
    He's ${0 - cash} down on the night. #class: sub
}
{ office_wiped:
    And a straw, cut down to two inches. #class: sub
}
{ ev_card.lent:
    Twenty more is in room nine. #class: sub
}
// Gary's office (office.ink): the room, the shirt, the form.
{
- rent_called:
    The room: six hundred a month, the way Gary said it first. The bookkeeper wrote something down. #class: sub
- interview.the_deal.let_go:
    The room: six-fifty a month, with the hydro, off the top. He let it go. #class: sub
- stats_set:
    The room: six-fifty a month, with the hydro, off the top. #class: sub
}
{ knows ? form_uniform:
    Twenty-four dollars off Friday's cheque, for the shirt. #class: sub
}
{ pay_how == 2:
    He asked to be paid cash. The bookkeeper wrote that down too. #class: sub
}
{ drinks == 0:
    Drinks: none #class: row
- else:
    Drinks: {drinks} #class: row
    { drinks_before:
        One of them is Gary's two, at four o'clock. #class: sub
    }
    { drinks >= 3:
        He'll feel them on Friday{after_hours.water.drank_water:, less for the pint of water}. #class: sub
    }
}
{ last_glass == 2:
    And one he left standing on the bar. #class: sub
}
{
- hurt == 1:
    Hurt: knocked about #class: row
    Nothing that won't heal by Friday. #class: sub
- hurt == 2:
    Hurt: his hand, his face #class: row
    Friday will know about it. #class: sub
- hurt >= 3:
    Hurt: badly #class: row
}
{
- fam ? dad_went && fam ? lot_scene:
    The big man from the pool table went to the hospital in his daughter's truck at two in the morning. {took_keys:His keys are in the lost-and-found drawer.}
- fam ? dad_went && fam ? all_out:
    He put them all out, the big man too, and they went to the hospital together in the pickup.
- fam ? dad_went && fam ? dad_ejected:
    He put the big man out. His kids took him to the hospital.
- fam ? dad_went:
    The big man from the pool table went to the hospital with his kids.
- fam ? dad_drove:
    The big man drove himself home drunk{fam ? dad_stayed && not family_in_lot:, after his family had gone without him}. {family_in_lot:His kids followed him.}
- fam ? dad_walked && took_keys:
    The big man walked home along the highway. His keys are in the lost-and-found drawer.
- fam ? dad_walked:
    He put the big man out. The big man walked home along the highway, and his kids followed him in the pickup with the hazards on.
- fam ? dad_ejected:
    He put the big man out.
- fam ? dad_stayed:
    The big man finished his game. His family went without him.
}
{ promise_kept >= 1:
    He told the big man's daughter her father wasn't there.{promise_kept == 2: The big man thanked him for it.} #class: sub
}
{ fam ? kid_kept_out:
    The kid in the hoodie waited in the truck through all of it. #class: sub
}
{
- fam ? kid_home && fam ? dad_told:
    He told the kid to go home and sleep, that he'd make sure his father knew. He made sure. #class: sub
- fam ? kid_home:
    He told the kid to go home and sleep, that he'd make sure his father knew. His father never heard it from him. #class: sub
}
{ scans ? scan_phone:
    The scanner has a photograph of a licence on it{phone_scans > 1:, twice}, and a red light. #class: sub
}
{
- arrivals ? banned_out && arrivals !? banned_in && arrivals !? banned_inside:
    GOOD SHOES was turned away at the door.
- banned_held == 1:
    GOOD SHOES had one drink, as agreed, and was walked out after it.
- banned_held == 2:
    GOOD SHOES had his one drink, and then the last one, and then he went.
- banned_held == -1:
    GOOD SHOES had his one drink, and then he had the rest.
- arrivals ? banned_inside && arrivals ? banned_out:
    GOOD SHOES got in past the empty stool. He was put out.
- arrivals ? banned_inside:
    GOOD SHOES got in past the empty stool, and drank at the bar till close.
- arrivals ? banned_in:
    He let GOOD SHOES in. GOOD SHOES drank at the bar till close.
}
{ scans ? scan_goodshoes:
    The scanner has his licence on it, with the time. #class: sub
}
{
- case_back == 1:
    HI-VIS's two-four went up to eleven with him.
- case_back == -1:
    HI-VIS's two-four is behind the bartender's front door. It's hers now.
}
{ hivis_landing:
    HI-VIS slept on the landing.
    { go_upstairs.landing.stepped_over:
        He stepped over him on his way up to bed. #class: sub
    }
}
{
- arrivals ? wife_lied && dog_told:
    Dennis got the message about the dog{close_t28.dog_late:, late}.
- arrivals ? wife_lied:
    Dennis never got the message about the dog.
}
{
- told_police == 1:
    The constable has it the way it happened.
- told_police == -1:
    The constable has it that it sorted itself out.
- told_police == 2:
    The constable has it from the bartender.
- name_on_log:
    Nobody called the police. His name's on it instead.
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
{
- terms_kept == 1:
    The kitchen door is on the latch. #class: sub
- terms_kept == -1:
    The kitchen door is locked. Day one of the terms. #class: sub
}
{ walter == 0:
    Walter is dead.
}
{ walter == 3:
    Walter has eaten the bait. It takes days. He'll go into the wall behind table 28 to do it.
}
The log: {LIST_COUNT(logged)} written as it happened, {LIST_COUNT(shaded)} shaded, {LIST_COUNT(left_out)} left out.
{
- office_wiped:
    The mirror in the office is clean. #class: sub
- left_out ? inc_office:
    The mirror in the office isn't in the book. #class: sub
- knows ? office_seen && incident !? inc_office:
    He saw the mirror in the office, and left it how he found it. #class: sub
}
{
- rep_t28 >= 3 && at_t28.sit:
    Table 28 made room for him.
- rep_t28 >= 3:
    Table 28 like what they've seen of him from across the room. They'll want him at the table Friday.
- rep_t28 >= 1:
    Table 28 have decided he'll do, for now.
- rep_t28 >= -1:
    Table 28 haven't made up their minds.
- else:
    Table 28 talk around him.
}
{
- secret_kept == 1:
    The one in the cardigan's secret is safe with him. #class: sub
- secret_kept == -1:
    Table 28 know where the one in the cardigan goes when he says he's in the can. #class: sub
}
{
- cardigan_go == 1:
    The one in the cardigan is thinking about Calgary.
- cardigan_go == -1:
    The one in the cardigan will be in his chair on Thursday.
- cardigan_go == 2:
    The one in the cardigan doesn't know either.
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
{ knows ? lost_jacket:
    The last doorman's jacket is in the lost-and-found. Nobody's been through the pockets.
}
{ knows ? esso_rater:
    The kid at the Esso gets four cents an answer for saying which of a machine's sounds more like a person. {rated == 3:He said neither.|It's getting hard to tell, he says.} #class: sub
}
{ owned_it > 0:
    He told somebody he was wrong. That isn't nothing.
}
{ LIST_COUNT(claims) > 0:
    WHAT HE'S SAID, WHICH IS TRUE NOW
    { claims ? said_up_island:
        That he's from up island. #class: sub
    }
    { claims ? said_around:
        That he's from around. #class: sub
    }
    { claims ? said_city_door:
        That he did ten years on a door in the city{claims ? said_city_unnamed:, and won't say which|{claims ? said_city_line:, the kind with a line outside}}. #class: sub
    }
    { claims ? said_father || claims ? said_father_doors:
        That his father worked doors{father_named:, and his father's name}{claims ? said_not_like_him:, and he's not like him}{claims ? said_trying_not:, and he's trying not to be}. #class: sub
    }
    { claims ? said_father_stopped:
        That his father drank for twenty years and then stopped{claims ? said_helped_others:, and it helped everybody else}{claims ? said_didnt_help:, and it didn't help}{claims ? said_father_dead:, and died before he worked it out}. #class: sub
    }
    { claims ? said_no_kids:
        That he hasn't got kids. #class: sub
    }
    { claims ? said_maybe_kids:
        That he hasn't got kids, that he knows of. #class: sub
    }
    { claims ? said_left_bad_owner:
        That he left his last door because the owner shorted him. #class: sub
    }
    { claims ? said_left_something:
        That something happened at his last door. #class: sub
    }
    { claims ? said_left_long_story:
        That leaving his last door is a long story. #class: sub
    }
    { claims ? said_nothing:
        Nothing about why he left his last door. #class: sub
    }
}
{ LIST_COUNT(told_gary) > 0:
    WHAT HE TOLD GARY, WHICH GARY TOLD HER
    { told_gary ? tg_city:
        That he did ten years on a door in the city. #class: sub
    }
    { told_gary ? tg_up_island:
        That he's from up island. #class: sub
    }
    { told_gary ? tg_around:
        That he's from around. #class: sub
    }
    { told_gary ? tg_father:
        That his father worked doors, and he worked them with him. #class: sub
    }
    { told_gary ? tg_shorted:
        That his last owner shorted him. #class: sub
    }
    { told_gary ? tg_something:
        That something happened. #class: sub
    }
    { told_gary ? tg_long:
        That it's a long story. #class: sub
    }
    { told_gary ? tg_quiet:
        Nothing, about why he left. #class: sub
    }
    { told_gary ? tg_never:
        That he's never been in a fight. Nobody believed it. #class: sub
    }
    { told_gary ? tg_dry:
        That he doesn't drink. Doug at the Legion says otherwise. #class: sub
    }
}
{ seated("table") || seated("kid"):
    In his head: {heads()}.
}
{ any_word():
    WHAT THEY'RE SAYING
    { last_word("t28") != "":
        Table 28: “{last_word("t28")}” #class: row
    }
    { last_word("kids") != "":
        The kids: “{last_word("kids")}” #class: row
    }
    { last_word("cook") != "":
        The cook: “{last_word("cook")}” #class: row
    }
    { last_word("owner") != "":
        The owner: “{last_word("owner")}” #class: row
    }
    { last_word("staff") != "":
        The bartender: “{last_word("staff")}” #class: row
    }
}
{
- verdict == 2:
    The bartender will tell the owner he'll do. #class: total
- verdict == 1:
    The bartender will tell the owner he showed up. #class: total
- verdict == -1:
    The bartender will tell the owner what she saw. #class: total
}
Friday is two nights away. Friday's everybody.
END OF THE TEST SHIFT #class: end
-> END
