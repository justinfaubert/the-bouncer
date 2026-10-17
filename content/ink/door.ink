// The main door. Each person is a short read: ID, how drunk, who they're with, what they want.
// In, out, or in on conditions. Arrivals: HOODIE 7:50, the sister 8:50 or 9:40, HI-VIS 9:00,
// GOOD SHOES 10:30, RAINCOAT 12:40. If he isn't at the door when they come, see sim.ink.
//
// Where the three from the pickup are is kept exactly (kid_at, sister_at, vape_at in main.ink),
// and move() in sim.ink keeps the room's count in step with it. Whether he saw them come in is up
// to the line that moves them: count_in when he lets them in, uncounted when they got past him.

=== at_door ===
~ here = door
~ door_away = 0
// Back on the door after people came in without him: the signs of it. (Claude's draft.)
{ walk_ins > walk_ins_seen:
    { walk_ins - walk_ins_seen == 1:
        Wet footprints on the mat that weren't his, going in. Somebody had come through while he was gone.
    - else:
        Wet footprints on the mat, more than one set, none of them his, all going in.
    }
    ~ walk_ins_seen = walk_ins
}
// She gave him half an hour in the vestibule to bring her father out (sim.ink).
{ fam ? sister_gave_up && not gave_up_seen && not fam_done && not truck_gone:
    ~ gave_up_seen = true
    The vestibule was empty. Her wet prints went out across the mat, not in, and through the glass the pickup sat at the edge of the lot with its engine running and its wipers going.
    FATHER: Half an hour, she gave you. That's more than I ever gave anybody.
    # task: fetch :: Tell the big man at the pool table his daughter's waiting in the truck.
}
{ due(): -> hub }
{ clock >= LAST_CALL: -> hub }
{
- arrivals !? hivis_done && clock >= 1260: -> door_hivis
- arrivals !? banned_done && clock >= 1350: -> door_banned
- arrivals !? wife_done && clock >= 1480: -> door_wife
}
-> door_quiet


// ------------------------------------------------------------------ nobody yet

=== door_quiet ===
~ here = door
{ due(): -> hub }
{ clock >= LAST_CALL: -> hub }
{ stopping:
- He sat on the stool with his hands between his knees. The rain ran down the glass. A truck went by on the highway and its lights went across the ceiling.
- Nothing came in for a while. The ice machine dumped a load behind the bar. Table 28 laughed at something on the TV, together, on the same beat.
- Two men came in out of the rain, shaking it off, regulars by the way they didn't look at him. He nodded them through.
    ~ count_in += 2
    ~ room_count += 2
- A woman came in to buy smokes from the machine by the door and went out again without looking at anybody.
- The door swung in and nobody came through it. Wind.
- A man he'd clicked in an hour ago went out to his truck, sat in it with the engine running for ten minutes, and came back in. He let him past without clicking. Once in is once in.
- {truck_gone:The lot was empty. Where the pickup had sat all night there was a dry patch on the gravel, going dark in the rain.|The lot was empty except for the pickup at the edge of it{fam ? kids_waiting:, still there with its engine running}.}
- { door_still() }
}
{ room_line() }
{ sister_at == s_vestibule && not fam_done:
    {stopping:
    - The sister was still behind him in the vestibule with her keys, dripping on the mat, watching the pool table through the inner door.
    - She was still in the vestibule. She'd stopped watching the pool table and started watching him.
    - The sister, in the vestibule, looking at her phone without reading it.
    }
}
{fam ? kids_waiting && knows !? truck && not truck_gone:
    The pickup that had brought the kid was still out there at the edge of the lot, engine running, wipers on intermittent.
    ~ knows += truck
}
<- moves(door)
// Back through the door's own checks, so whoever is due at the door finds him on it.
+ [Stay on the door.]
    ~ pass(15)
    -> at_door


// On the door with nothing coming through it: what the stool sees, by the hour. (Claude's draft.)
=== function door_still()
{
- clock < 1320:
    {shuffle:
    - Headlights swung across the lot, stopped, and went away again. Somebody deciding against it.
    - A couple came as far as the vestibule, read the room through the glass, and went back out to their car.
    - In the black of the front window he could see the whole room behind him, backwards, with himself in the middle of it.
    }
- clock < 1440:
    {shuffle:
    - The highway had gone quiet. Every few minutes a truck, and the long hiss of it on the wet road after it had gone.
    - A cab pulled into the lot and sat there with its light on, and left with nobody in it.
    - In the black of the front window he could see the whole room behind him, backwards, with himself in the middle of it.
    }
- else:
    {shuffle:
    - Past midnight the door went the other way. Everybody who came through it now was going out.
    - The rain had eased off to the kind you only see under the light over the door.
    - Somebody's phone was ringing in a coat on a hook, and nobody went to it.
    }
}

// ------------------------------------------------------------------ 7:50 HOODIE

=== door_hoodie ===
~ here = door
~ move(kid_at, s_door)
The passenger door of the pickup opened. A kid got out and came across the gravel with his hood up and his hands in the pouch of his sweatshirt, not hurrying, getting soaked.
He stopped in front of the stool and held up his phone. On the screen was a photo of a driver's licence. #portrait: hoodie #prop: hoodie_phone
HOODIE: yeah
He had earbuds in. He didn't take them out.
FATHER: A picture of a card isn't a card.
MANUAL: Acceptable identification is a valid government-issued card with a photograph, presented in person. When in doubt, two pieces. You're in doubt.
WRONGMAN: Everybody in that story came in out of the rain. Every one of them. #mark: door.door
// Hutch, in director mode (27 Sept), on how a real doorman handles it: take the ID, size up the kid,
// look at the info, deny him if he doesn't have ID, and try to build a rapport in the short time the
// interaction lasts. The small talk below, and what it changes later, is Claude's draft from that.
-> read

= read
~ door_reads++
* (took) {not swiped} [Take the phone and look at the photo. #toy: hoodie_phone look]
    ~ pass(1)
    He took the phone. The kid let him, but his hand stayed up for a second after, like he'd forgotten to lower it.
    The licence was a real one, photographed on a kitchen table. Same face, younger and with less hair in his eyes. The birthday made him nineteen by three weeks. #prop: hoodie_phone held
    ~ knows += kid_legal
    MANUAL: Nineteen by three weeks. Legal. The photograph is still not identification.
    -> read
// Only the player's hands make this one: swiping the kid's phone to the next photo (content/ink/toys.ink).
* (swiped) [Swipe to the next photo. #toy: hoodie_phone swipe #unlisted]
    ~ pass(1)
    ~ knows += kid_photo
    {took:He swiped to the next one.|He reached over and swiped the screen while the kid was still holding it up.}
    It wasn't a licence. It was the pool table, taken from the lot through the front window, at night, in the rain. The lamp over the table, the green of the cloth, and a big man bent over a shot with his left hand flat on the rail.
    HOODIE: hey. that's my phone
    The kid took the phone back. He didn't snatch it. He put it in the pouch of his sweatshirt and kept his hand in there with it.
    ~ rep(rep_kids, -1)
    ~ kid_ease--
    FATHER: Now you know something you weren't handed.
    -> read
* [Look at him, not the phone. #check: father 8]
    ~ pass(1)
    { passed:
        FATHER: Look at his eyes. Red, and too wide. He's on something, and he's been on it a while. You don't let that in on a Wednesday to see what it does.
        ~ father_misread = true
        The Father had never been wrong about a drunk. He'd been wrong about plenty of other things.
        ~ bond("father", "wrongman", 1)
    - else:
        He tried to read him and couldn't. The kid wouldn't hold his eyes long enough to be read. He looked at the doorman's chin, then his shoulder, then the room behind him.
        FATHER: Can't read him. That's a read. Something's wrong with a man who won't look at you.
    }
    // The kid isn't high. He's been awake for two days. The Father can't read the young (bible/02_SYSTEMS.md).
    -> read
* [Look past him at the truck. #check: wrongman 8]
    ~ pass(1)
    ~ knows += truck
    { passed:
        WRONGMAN: The wrong one's never the one in front of you. That's the whole story. Look at who's waiting.
        The driver's face was lit blue by her phone, but she wasn't looking at the phone. She was watching the door. Not the kid. The room behind the door.
        Someone was stretched out across the back seat with a hand hanging off it, holding a vape.
    - else:
        Rain on the windshield, wipers going, the dash lights. Someone in the driver's seat. Somebody else in the back.
        WRONGMAN: Could be anyone in there. In the story it could have been anyone. That was the point.
    }
    -> read
* ["Rough night to be out in."]
    ~ pass(1)
    ~ fam += hoodie_rapport
    { fam ? earbuds_out:
        The kid looked at him properly for the first time.
    - else:
        The kid looked at him properly for the first time, and took one earbud out.
    }
    HOODIE: it's been raining since tuesday
    FATHER: That's it. You get a minute with each of them. Be decent in it, and the no goes down easier.
    -> read
* ["Take the earbuds out."]
    ~ pass(1)
    ~ fam += earbuds_out
    { fam ? hoodie_rapport:
        The kid took the other one out too, and held them both in his fist. Something loud and sad leaked out of them, tinny, a woman's voice.
    - else:
        The kid took one out. Something loud and sad leaked out of it, tinny, a woman's voice.
    }
    HOODIE: what
    -> read
* ["Where's the card?"]
    ~ pass(1)
    ~ knows += card_in_truck
    HOODIE: truck
    FATHER: Then it's in the truck, and so is he.
    -> read
* ["Who's in the truck?"]
    ~ pass(1)
    ~ knows += truck
    HOODIE: my sister
    He looked at the door, not at the truck.
    HOODIE: and her boyfriend. he's not coming in. he's like, asleep
    -> read
* {door_reads > 1} ["What are you here for? It's a Wednesday."]
    ~ pass(1)
    The kid looked past him, into the room. Not at the bar. At the pool table.
    HOODIE: looking for someone
    * * ["Who?"]
        ~ kid_ease--
        HOODIE: just someone
        { fam ? earbuds_out || fam ? hoodie_rapport:
            He put the earbud back in.
        - else:
            He turned his music up. The doorman could hear it from the stool.
        }
    * * [Let it go.]
        ~ kid_ease++
    - - FATHER: He's not here to drink. He's here for somebody inside. That's worse.
    -> read
+ {not swiped && phone_scans < 2} [Scan the phone.]
    ~ pass(1)
    ~ phone_scans++
    ~ scans += scan_phone
    {phone_scans == 1:He held the phone under the scanner. It thought about it and gave him the red light.|He held it under the scanner again. The same red light, quicker this time.} #sfx: scanner_bad
    { phone_scans == 1:
        MANUAL: The scanner reads cards. It does not read photographs of cards. The scanner is, in this respect, correct.
    - else:
        HOODIE: it's not gonna work
        HOODIE: it didn't work the first time either. it's a picture
        ~ kid_ease--
        MANUAL: The scanner keeps a record of every card it is shown, with the time. It now has two of these.
    }
    -> read
+ ["In you go."]
    -> admit
+ ["Not without the card."]
    -> refuse
+ {door_reads > 1 || knows ? card_in_truck} ["Go get the card. I'll be here."]
    -> fetch
+ {door_reads > 2} ["You can come in. On conditions."]
    -> conditions

= admit
~ pass(1)
~ fam += hoodie_admitted
~ move(kid_at, s_jukebox)
~ count_in++
~ incident += inc_no_id
~ rep(rep_kids, 1)
{ read.took && not read.swiped:
    He gave the phone back. The kid put it in his pouch without looking at it. #prop: hoodie_phone back
}
He stood aside. The kid went past him without a word and stopped just inside, dripping on the carpet, looking at the room.
{ knows !? kid_legal:
    ~ rep(rep_staff, -1)
    Behind the bar, the bartender had stopped cutting limes. She'd seen the phone. She didn't say anything. She started cutting again.
    MANUAL: For the record, you did not verify his age.
- else:
    MANUAL: For the record, you verified his age from a photograph. The record will say photograph.
}
The kid went and stood by the jukebox with his hood still up. He didn't order. He didn't sit.
-> at_door

= refuse
~ pass(1)
~ fam += hoodie_refused
~ incident += inc_kid_refused
~ move(kid_at, s_truck)
{ read.took && not read.swiped:
    He gave the phone back. #prop: hoodie_phone back
}
{ knows ? card_in_truck:
    HOODIE: it's literally in the truck though
    He waited, in case the doorman was going to tell him to go and get it. The doorman wasn't.
    ~ rep(rep_kids, -1)
}
{ fam ? hoodie_rapport:
    HOODIE: yeah ok. fair
    He put the earbud back in. He looked past the doorman one more time, into the room, then went back across the lot with his hands in his pouch.
- else:
    ~ rep(rep_kids, -1)
    HOODIE: k
    He didn't argue. He looked past the doorman one more time, into the room, then went back across the lot with his hands in his pouch.
}
The passenger door opened and shut. The truck didn't leave.
{ deck_door && knows ? coaster:
    FATHER: There's a coaster in the deck door. You know that. #mark: deck.latch
}
-> at_door

= fetch
~ pass(5)
~ fam += hoodie_admitted
~ knows += kid_legal
~ knows += card_in_truck
~ scans += scan_card
~ move(kid_at, s_jukebox)
~ count_in++
~ rep(rep_kids, 1)
~ rep(rep_staff, 1)
{ read.took && not read.swiped:
    He gave the phone back. #prop: hoodie_phone back
}
The kid went back across the lot. The driver's window came down. There was a conversation, short, with a lot of hand in it from the driver's side. The window went up.
He came back with a wet wallet and held out a licence, the real one. The scanner gave it a green light. #sfx: scanner_ok #prop: hoodie_card
MANUAL: Valid. Nineteen. Thank you. #pause
He gave the card back. The kid put it in the wallet and the wallet in his pouch. #prop: hoodie_card back
He went past into the room and stood by the jukebox with his hood still up, dripping on the carpet. He didn't order.
FATHER: His sister's still out there with the engine running. Wonder why.
~ knows += truck
-> at_door

= conditions
~ pass(1)
{ read.took && not read.swiped:
    He gave the phone back, and held up a hand. #prop: hoodie_phone back
- else:
    He held up a hand.
}
* ["You're in. No drinking tonight."]
    ~ kid_terms = 1
    HOODIE: fine
    It was clearly fine. He hadn't come to drink.
* ["You're in. You stay where I can see you."]
    ~ kid_terms = 2
    HOODIE: k
    He looked over the room from the mat, as if he was working out where the stool could see.
* ["You're in if your sister comes in with you."]
    ~ kid_terms = 3
    The kid looked back at the truck for a long moment.
    HOODIE: she's not gonna
    HOODIE: she can't. i mean she won't
    FATHER: Can't. He said can't first.
    ~ knows += truck
- ~ fam += hoodie_admitted
~ fam += hoodie_conditions
~ move(kid_at, s_jukebox)
~ count_in++
~ incident += inc_no_id
~ rep(rep_kids, 1)
{ knows ? kid_legal:
    ~ rep(rep_staff, 1)
}
He let him past. The kid went and stood by the jukebox. He watched the pool table the way you watch a dog you don't know.
{ kid_terms == 3:
    Through the glass, the doorman watched him take his phone out and type something with both thumbs, and out in the lot the screen lit up in the driver's hand.
}
-> at_door


// ------------------------------------------------------------------ the sister: 8:50 if HOODIE was turned away, 9:40 if he was let in

=== ev_sister ===
~ door_away = 0
~ fam += sister_met
~ knows += truck
~ move(sister_at, s_door)
~ move(vape_at, s_door)
{ here != door:
    The bartender caught his eye and pointed her chin at the front door. #look: bartender
    ~ here = door
}
A young woman stood in the vestibule with car keys in her fist and rain in her hair. Behind her, holding the door open with his shoulder, a guy in a soaked hoodie with a vape in his hand. #portrait: driver
{
- fam ? hoodie_refused && knows ? card_in_truck:
    DRIVER: My brother was just at this door. His licence is in the truck. It's been in the truck the whole time.
- fam ? hoodie_refused && fam ? hoodie_rapport:
    DRIVER: My brother was just here. He said you were decent about it. Thank you for that.
- fam ? hoodie_refused:
    DRIVER: My brother was just at this door, and you told him no. That's fine. That's not why I'm here.
- kid_terms == 3:
    DRIVER: My brother texted me. He says he can only stay if I come in. So I'm here.
- else:
    DRIVER: My brother's in there. Grey hoodie, nineteen. He's with me.
}
She had her licence out already, held up at eye level, not a photo, the card. Twenty-two. #prop: driver_card
VAPE: we're just here to get her DAD bro. two minutes. in and out
DRIVER: Shut up, Kyle.
// HUTCH: The sister is the one who came to get their father out of a bar. You've seen family come in to fetch someone. How does that actually go at the door?
-> sister_opts

= sister_opts
// Only the player's hands make this one: holding her licence up by her face.
* [Look from the card to her face. #toy: driver_card look #unlisted]
    ~ pass(1)
    MOFFAT, KAYLA DAWN. Twenty-two, as advertised{knows ? kid_legal:, and the same surname as the kid's}. In the photo she had her hair pulled back, and without it in the way you could see the jaw.
    { at_pool:
        He'd seen that jaw already tonight, at the pool table, bent over a cue.
        ~ knows += bigman_dad
        FATHER: So that's whose they are.
    - else:
        MANUAL: Photograph matches bearer. Valid.
    }
    -> sister_opts
* ["Get who?"]
    ~ pass(1)
    DRIVER: Our dad. Big guy. He'll be at the pool table, he's always at the pool table.
    FATHER: The big one with the left hand.
    ~ knows += bigman_dad
    -> sister_opts
* ["What's it about?"]
    ~ pass(2)
    She looked at him like she was deciding how much he was owed.
    DRIVER: Our mom's in the hospital in town. Since this morning. He's not answering his phone. He's not answering anybody.
    DRIVER: He doesn't answer when he's here.
    // HUTCH: Draft reason. Replace with whatever you've actually seen bring family into a bar after someone.
    ~ knows += kid_why
    ~ knows += bigman_dad
    FATHER: He never answered either.
    It wasn't clear which of them the Father meant.
    -> sister_opts
// What the Fighter makes of him counts for and against every hand put on him later (vape_mod() in sim.ink).
* [Look at the boyfriend. #check: fighter 6]
    ~ pass(1)
    { passed:
        ~ knows += vape_read
        FIGHTER: He's had eight and he wants a ninth. Weight on his heels, chin up. He's the one who'll swing if anyone does, and he'll swing at the biggest fucker in the bar: You.
    - else:
        ~ knows += vape_misread
        FIGHTER: Soft. Drunk. Nothing.
        The Fighter was wrong about soft.
    }
    -> sister_opts
* ["ID for him too."]
    ~ pass(1)
    ~ knows += vape_no_id
    VAPE: bro come on
    VAPE: it's in my other pants my guy
    FATHER: It's always in the other pants.
    -> sister_opts
// He told the big man he'd say he wasn't here (pool.ink). This is where he finds out what that costs.
+ {promised_bigman && not fam_done} ["He's not here."]
    -> sister_lie
+ ["You can go in. He can't."]
    -> sister_alone
+ ["I'll go get him for you."]
    -> sister_fetch
+ {fam ? hoodie_refused} ["All three of you, in. Find him and go."]
    -> sister_all
+ {fam !? hoodie_refused} ["Both of you, in. Find him and go."]
    -> sister_all
+ ["Nobody else tonight."]
    -> sister_no

= sister_lie
~ pass(1)
~ promise_kept = 1
~ fam += sister_refused
~ fam += kids_waiting
~ move(sister_at, s_truck)
~ move(vape_at, s_truck)
~ incident += inc_kid_refused
~ rep(rep_kids, -2)
DRIVER: His truck's right there.
She didn't point at it. The work truck with the toolbox across the bed, nose-in by the beer store, with the rain beading on the hood.
She looked past him through the inner door, at the pool table, where a big man was bent over a shot with his back to the room, and she looked for a long time.
DRIVER: Okay. He's not here.
VAPE: bro he's literally
DRIVER: Kyle.
They went back across the lot. The engine was still running. It kept running.
FATHER: You lied for a drunk to his daughter. He'll thank you for it. Remember that he did.
-> at_door

= sister_alone
~ pass(1)
~ fam += sister_admitted
~ move(sister_at, s_rail)
~ move(vape_at, s_truck)
~ count_in++
~ rep(rep_kids, 1)
{ promised_bigman:
    ~ promise_kept = -1
}
VAPE: are you SERIOUS right now
DRIVER: Kyle. Truck.
He went. He took his time about it and the vape with him.
She went in past the doorman. She didn't look at the pool table right away. She looked at the floor first, like someone getting ready to lift something heavy.
{ fam ? hoodie_refused:
    -> sister_brother
}
-> at_door

// Her brother, still out in the truck with the photo of his licence.
= sister_brother
~ move(sister_at, s_door)
She came back to the door a minute later.
DRIVER: Can my brother come in, please. He's nineteen. You saw the picture.
* ["Get him."]
    ~ fam += hoodie_admitted
    ~ move(kid_at, s_jukebox)
    ~ count_in++
    ~ rep(rep_kids, 1)
    { knows ? card_in_truck:
        She waved at the truck. The kid came across the lot with a wet wallet, and this time he held out the card before he was asked. The scanner gave it a green light. #sfx: scanner_ok
        ~ scans += scan_card
        ~ knows += kid_legal
    - else:
        She waved at the truck. The kid came across the lot. He let him in, and this time the kid looked at him for almost a whole second.
        ~ incident += inc_no_id
        ~ rep(rep_staff, -1)
        MANUAL: For the record: an hour ago he was refused for want of a card. He still has no card.
    }
    ~ move(sister_at, s_rail)
    -> at_door
* {knows !? card_in_truck} ["If he brings the actual card."]
    DRIVER: It's in the glovebox. It's been in the glovebox all night.
    She went out and opened the passenger door and leaned in, and came back across the lot with her brother and his licence, the real one. The scanner gave it a green light. #sfx: scanner_ok
    ~ fam += hoodie_admitted
    ~ knows += card_in_truck
    ~ knows += kid_legal
    ~ scans += scan_card
    ~ move(kid_at, s_jukebox)
    ~ count_in++
    ~ rep(rep_kids, 1)
    ~ rep(rep_staff, 1)
    HOODIE: told you
    He hadn't told him anything. He went and stood by the jukebox.
    ~ move(sister_at, s_rail)
    -> at_door
* ["Just you."]
    ~ fam += kid_kept_out
    ~ rep(rep_kids, -1)
    DRIVER: Okay.
    She said it the way you say it when you're adding something to a list.
    ~ move(sister_at, s_rail)
    -> at_door

= sister_all
~ pass(1)
~ fam += sister_admitted
~ incident += inc_no_id
~ rep(rep_kids, 2)
{ promised_bigman:
    ~ promise_kept = -1
}
~ move(sister_at, s_rail)
~ move(vape_at, s_bar)
{ fam ? hoodie_refused:
    ~ fam += hoodie_admitted
    ~ move(kid_at, s_jukebox)
    ~ count_in += 3
    { knows ? card_in_truck:
        She waved at the truck. The kid came across the lot with his licence out this time, the real one, and held it up without being asked. #sfx: scanner_ok
        ~ scans += scan_card
        ~ knows += kid_legal
    - else:
        She waved at the truck. The kid came across the lot.
    }
    The three of them went in past him, the sister first.
- else:
    ~ count_in += 2
    The two of them went in past him.
}
VAPE: appreciate you big dog
He said it on his way to the bar, not the pool table.
{ knows ? vape_no_id:
    ~ rep(rep_staff, -1)
    MANUAL: You asked him for identification. He had none. He is now inside, and ordering.
    Behind the bar, the bartender had heard him ask. She'd heard the answer, too.
- else:
    MANUAL: The one with no identification is now inside and ordering.
}
FATHER: You let the weather in.
-> at_door

= sister_fetch
~ pass(2)
~ fam += sister_fetched
~ sister_wait_at = clock
~ move(sister_at, s_vestibule)
~ move(vape_at, s_truck)
{ promised_bigman:
    ~ promise_kept = -1
}
DRIVER: You'd do that? Okay. Thank you.
VAPE: bro he's gonna do it WRONG. he doesn't even know what he looks like
DRIVER: Kyle.
{ fam ? hoodie_admitted:
    DRIVER: Tell my brother to come out too, please. He's no use in there. He won't even talk to him.
}
She waited in the vestibule, dripping, with her keys. The boyfriend went back to the truck.
FATHER: Now it's your errand. You carry it right or you carry it wrong, but you're carrying it.
# task: fetch :: Tell the big man at the pool table his daughter's at the door.
-> at_door

= sister_no
~ pass(1)
~ fam += sister_refused
~ fam += kids_waiting
~ move(sister_at, s_truck)
~ move(vape_at, s_truck)
~ rep(rep_kids, -2)
~ incident += inc_kid_refused
DRIVER: Okay. Thank you.
{ kid_terms == 3:
    DRIVER: You told him he could stay if I came in.
    DRIVER: So which is it.
    He didn't say which it was.
    ~ rep(rep_kids, -1)
}
She didn't argue. She looked past him into the room for as long as she could, then turned around.
VAPE: unreal. this guy
They went back across the lot. The truck's engine was still running. It kept running.
{ indoors(kid_at):
    Her brother was still inside.
}
-> at_door


// ------------------------------------------------------------------ 9:00 HI-VIS

=== door_hivis ===
~ here = door
~ arrivals += hivis_done
A man in a hi-vis vest over a hoodie came in from the lot with a two-four of beer under one arm, the box going soft in the rain. Mill dust in the creases of his hands. #portrait: hivis
HI-VIS: How's she goin'.
He was steady on his feet. Mostly. He had the careful, deliberate walk of someone who knows exactly how many he's had.
- (hv)
* [Count his drinks. #check: father 6]
    ~ pass(1)
    { passed:
        FATHER: Four. Maybe five. Tired, not drunk. He'll be fine till someone makes him not fine.
    - else:
        FATHER: Drunk.
        The Father thought everyone was drunk. Most nights he'd been right.
    }
    -> hv
* [Signs of intoxication. #check: manual 6]
    ~ pass(1)
    { passed:
        MANUAL: Speech clear. Gait steady within reason. Eyes glassy. Odour of alcohol. Carrying alcohol, which may not be brought onto licensed premises. Refuse entry with the product, or require him to leave it.
    - else:
        MANUAL: Refer to section four. Signs of intoxication include, but are not limited to, the following.
        The Manual listed eleven of them. He'd stopped listening at four.
    }
    -> hv
* ["Where are you coming from?"]
    ~ pass(2)
    HI-VIS: Up the stairs, eventually. Room eleven. Crew's on the mill contract.
    HI-VIS: Last one, sounds like. Nobody's saying it. You can tell when nobody's saying it.
    ~ knows += hivis_room
    ~ knows += hivis_upstairs
    ~ knows += mill_closing
    He shifted the case of beer.
    HI-VIS: Beer run for the boys. Figured I'd have one down here first, where it's warm.
    -> hv
* (no_beer) ["You can't bring that in."]
    ~ pass(1)
    ~ knows += hivis_upstairs
    HI-VIS: It's for upstairs.
    {knows ? hotel_gap:
        FATHER: Then he can take it upstairs through the hotel door. Like he'd do anyway if you weren't here.
    }
    -> hv
+ ["Go on in."]
    ~ arrivals += hivis_in
    ~ count_in++
    ~ room_count++
    ~ incident += inc_hivis
    ~ pass(1)
    He went past with the case still under his arm and put it on the floor by a stool at the bar. The bartender looked at the case, then at the doorman.
    { no_beer:
        ~ rep(rep_staff, -2)
        MANUAL: You told him he could not bring it in. Then he brought it in. She heard both.
    - else:
        ~ rep(rep_staff, -1)
    }
    -> at_door
+ ["Leave the beer with me and go on in."]
    ~ arrivals += hivis_in
    ~ arrivals += hivis_cond
    ~ count_in++
    ~ room_count++
    ~ pass(1)
    HI-VIS: Fair enough.
    He set the case down by the stool. The doorman pushed it behind the door with his foot.
    ~ rep(rep_staff, 1)
    -> at_door
+ {knows ? hivis_upstairs} ["Take it up to your room. You can come down after."]
    ~ arrivals += hivis_out
    ~ pass(1)
    HI-VIS: Yeah. Yeah, all right.
    He went back out into the rain and around the side of the building, toward the hotel entrance.
    {hotel_door:
        FATHER: And he'll come down the back stairs through the hotel door and you'll never know. Unless you lock it.
    }
    -> at_door
+ ["Not tonight. You've had enough."]
    ~ arrivals += hivis_out
    ~ knows += hivis_upstairs
    ~ incident += inc_hivis
    ~ pass(1)
    HI-VIS: I've had four.
    HI-VIS: I live here.
    He stood there for a second, working out whether it was worth it. It wasn't. He went back out.
    {hotel_door:
        ~ arrivals += hivis_hotel
        ~ uncounted++
        ~ room_count++
        Twenty minutes later he was at the bar anyway, without the beer. He'd come down through the hotel door.
        ~ pass(0)
    }
    -> at_door


// ------------------------------------------------------------------ 10:30 GOOD SHOES

=== door_banned ===
~ here = door
~ arrivals += banned_done
A man in a good wool coat came in, closing a golf umbrella. Shaved that evening. Shoes that had never walked on gravel before tonight. #portrait: goodshoes
GOOD SHOES: Good evening. Filthy out there, isn't it.
He had his licence ready before he was asked, and he smiled like they'd met. #prop: goodshoes_card
{ knows ? banned_face:
    He had met him. In the binder. Page three, a photocopied driver's licence and the bartender's handwriting underneath: NO. NOT EVER.
    -> known
}
// Heard on the deck (deck.ink): the smokers had his name before the binder did.
{ knows ? ardagh:
    He read the name before he looked at the face. ARDAGH, GRAHAM PETER. He'd heard it already tonight, out on the deck, from a smoker who'd said the bartender would have him shot.
    -> known
}
{ knows ? eighty_six:
    Something about the face. He'd seen it recently, badly lit.
    -> place
}
-> unknown

= place
* [Place the face. #check: manual 8]
    ~ pass(1)
    { passed:
        MANUAL: Binder. Page three. Photocopy of a licence. Barred.
        ~ knows += banned_face
        -> known
    - else:
        It wouldn't come. Forty photocopied faces, all the same man in bad light.
        -> unknown
    }
* [Let it go.]
    -> unknown
// Only the player's hands make this one: holding his licence up by his face, and looking at the card.
* [Hold the licence up by his face. #toy: goodshoes_card look #unlisted]
    -> recognised

= recognised
~ pass(1)
~ knows += banned_face
He held the card up beside the man's face, the way you do, and then he stopped looking at the face and looked at the card. ARDAGH, GRAHAM PETER. The same card, the same photo, the same good haircut. He'd seen it on page three, gone grey in the photocopier, over the bartender's handwriting.
-> known

= unknown
FATHER: Too clean for a Wednesday.
WRONGMAN: He had a nice face, the one in the story. Everybody said so after.
- (gs)
* [Scan the licence.]
    ~ pass(1)
    ~ scans += scan_goodshoes
    The scanner gave it a green light. #sfx: scanner_ok
    MANUAL: Valid. Fifty-one years of age. The scanner does not check the barred list. The barred list is in a binder, under the till.
    -> gs
* (asked_before) ["Been here before?"]
    ~ pass(1)
    GOOD SHOES: Years ago, friend. It hasn't changed a bit, which I suppose is the charm.
    -> gs
* {asked_before && knows ? eighty_six} [Look at him again, harder. #check: manual 8 1]
    ~ pass(1)
    { passed:
        Years ago, he'd said. The good haircut, gone grey in a photocopier.
        MANUAL: Binder. Page three. Barred.
        ~ knows += banned_face
        -> known
    - else:
        He looked. It was a face. By ten o'clock they were all faces.
        -> gs
    }
* {knows ? eighty_six} [Hold the licence up by his face. #toy: goodshoes_card look #unlisted]
    -> recognised
+ ["Go ahead."]
    -> let_in
+ {knows ? eighty_six} ["Give me a second." Go check the binder.]
    ~ pass(3)
    ~ here = bar
    He left the man in the vestibule and went behind the bar to the binder. The bartender watched him come and knew why before he got there.
    Page three.
    ~ knows += banned_face
    ~ here = door
    He came back.
    -> known
+ {knows !? eighty_six} ["Give me a second." Ask the bartender.]
    ~ pass(2)
    ~ here = bar
    He went over to the bar. He didn't have to say anything. She looked past him at the man in the vestibule and her face shut like a door.
    BARTENDER: No.
    BARTENDER: Binder, page three. Not ever.
    ~ knows += banned_face
    ~ knows += eighty_six
    ~ rep(rep_staff, 1)
    ~ here = door
    He came back.
    -> known

= known
FATHER: There it is.
{ knows ? ardagh && knows !? banned_face:
    GOOD SHOES: I can see somebody's been talking about me. That's all right. People talk.
- else:
    GOOD SHOES: I can see you've got a book with pictures in it, friend.
}
He smiled.
GOOD SHOES: That's old, friend. I completely understand, but the owner and I have spoken. I'm allowed back. I'll put a couple of hundred over that bar tonight, and I'm no trouble to anyone.
// HUTCH: What did he do? The draft only says the bartender wrote NOT EVER under his photo. Decide what it was, or leave it unsaid.
- (gk)
* ["What did you do?"]
    ~ pass(1)
    ~ knows += banned_story
    GOOD SHOES: Something I'm not proud of, a long time ago, and I've paid for it. Believe me.
    WRONGMAN: He'd paid for it. They always had.
    -> gk
* ["I'll call the owner."]
    ~ owner_missed = clock
    ~ pass(2)
    ~ here = bar
    He went to the bar phone and rang the number taped to the wall. It rang until it stopped.
    MANUAL: The owner is unavailable. The barred list is available.
    ~ here = door
    He came back.
    -> gk
+ ["Not tonight. Not any night."]
    -> turn_away
+ {knows ? eighty_six || knows ? banned_face} ["The binder says no. The binder wins."]
    -> turn_away
+ {knows !? eighty_six && knows !? banned_face} ["I hear she'd have you shot. So, no."]
    -> turn_away
+ ["One drink. You sit where I can see you."]
    ~ arrivals += banned_in
    ~ banned_one = clock
    ~ count_in++
    ~ room_count++
    ~ incident += inc_banned
    ~ rep(rep_staff, -3)
    ~ rep(rep_owner, 1)
    ~ pass(1)
    GOOD SHOES: That's all I ask. Thank you, friend.
    He went to the bar. The bartender served him, because it was her job, and she didn't say one word while she did it.
    She didn't look at the doorman for the rest of the night.
    FATHER: One. You said one. He heard you, and so did she.
    -> at_door
+ ["Go ahead."]
    -> let_in

= let_in
~ arrivals += banned_in
~ count_in++
~ room_count++
~ incident += inc_banned
~ pass(1)
{ knows ? banned_face || knows ? ardagh:
    ~ rep(rep_staff, -4)
- else:
    ~ rep(rep_staff, -2)
}
~ rep(rep_owner, 1)
He went to the bar and put a fifty on it.
The bartender looked at the fifty and then at the man and then, over his shoulder, at the doorman. She served him. It was her job. She didn't say anything while she did it.
{ knows !? banned_face && knows !? ardagh:
    WRONGMAN: That's how it starts in the story. You don't know. That's the whole point of the story.
}
-> at_door

= turn_away
~ arrivals += banned_out
~ rep(rep_staff, 3)
~ rep(rep_owner, -1)
~ pass(2)
GOOD SHOES: The owner will hear about this.
He didn't answer. He let his size answer. The man looked at him for a while, opened his umbrella in the vestibule, which was bad luck, and went out.
The bartender didn't look up. After a while she brought him a glass of water he hadn't asked for and put it on the ledge by the stool.
-> at_door


// GOOD SHOES came in while nobody was on the door.
// She comes to him, wherever he is; he goes to the man.
=== ev_banned_inside ===
~ banned_stage = 1
The bartender came around the end of the bar, which she didn't do, and stood in front of him.
BARTENDER: There's a man at my bar who is not allowed at my bar.
She didn't point. She didn't have to. A good wool coat, a golf umbrella hooked on the rail, a fifty on the bar that she hadn't touched. #look: goodshoes
BARTENDER: Page three. I'm not serving him and I'm not asking him. That's your job, Door.
~ knows += banned_face
~ knows += eighty_six
FATHER: You weren't on the door. This is what not being on the door costs.
- (bi)
* [Walk him out quietly. #check: father 8]
    ~ pass(5)
    ~ here = bar
    { passed:
        He stood beside the stool, close, and said it low, so nobody else had to hear. Coat, umbrella, the door, now. The man looked at him for a long second and did the arithmetic.
        GOOD SHOES: Of course. I completely understand.
        He left the fifty on the bar. The bartender put it in the tip jar without looking at it.
        ~ rep(rep_staff, 2)
    - else:
        He said it low. The man didn't lower his voice back.
        GOOD SHOES: I have been given permission by the owner of this establishment.
        ~ here = door
        Table 28 went quiet to listen. He walked him out anyway, a hand on his elbow the whole way, and the man said "the owner will hear about this" three times before the door shut.
        ~ rep(rep_staff, 1)
        ~ rep(rep_t28, 1)
    }
    ~ arrivals += banned_out
    ~ room_count--
    -> carry_on
* [Put him out. #check: fighter 6]
    ~ pass(3)
    ~ here = bar
    { passed:
        He took the man's arm above the elbow and turned him off the stool.
        ~ here = door
        He walked him to the door at a pace he couldn't argue with. It was over before table 28 noticed. #sfx: door
        ~ rep(rep_staff, 1)
    - else:
        The man grabbed the bar rail. The stool went over.
        ~ here = door
        It took longer than it should have and everybody watched, and when the door swung shut the man was outside shouting about lawyers. #sfx: hit
        ~ incident += inc_fight
        ~ bar_scuffle = true
        ~ rep(rep_staff, 1)
        ~ rep(rep_t28, 1)
    }
    ~ arrivals += banned_out
    ~ room_count--
    -> carry_on
* ["He says the owner lifted it."]
    ~ pass(1)
    ~ knows += binder_hers
    BARTENDER: Junior didn't write it. I did.
    -> bi
* [Leave him. It's not worth the scene.]
    ~ pass(1)
    ~ rep(rep_staff, -4)
    ~ arrivals += banned_in
    BARTENDER: Yep.
    She went back behind the bar. She served the man's next drink herself, slowly, and for the rest of the night she didn't look at the doorman at all.
    -> carry_on


// GOOD SHOES, forty minutes into the one drink he was let in on.
=== ev_one_drink ===
GOOD SHOES had finished the one drink. He'd made it last forty minutes, which was its own kind of argument. Now he lifted one finger to the bartender, pleasantly, and she looked down the bar at the doorman and didn't move. #look: goodshoes
FATHER: One, you said.
* [Walk him out. One was the deal. #check: father 7]
    ~ pass(3)
    ~ banned_held = 1
    ~ arrivals += banned_out
    ~ room_count--
    ~ here = bar
    { passed:
        He went and stood at the man's elbow and said that was one. GOOD SHOES looked at the empty glass as if it had disappointed him personally, and then he got up and put his coat on.
        GOOD SHOES: A man of his word. That's rarer than you'd think, in this business. I'll mention it.
        ~ rep(rep_staff, 2)
    - else:
        GOOD SHOES: One more won't hurt anybody. It's a Wednesday.
        ~ here = door
        He said it loud enough for table 28. The doorman walked him out anyway, with the man explaining the whole way what the owner had told him, and it took longer than it should have. #sfx: door
        ~ rep(rep_staff, 1)
        ~ rep(rep_t28, 1)
    }
    The bartender wiped the bar where his glass had been, twice.
    -> carry_on
* ["That's the last one, then."]
    ~ pass(1)
    ~ banned_held = 2
    ~ rep(rep_staff, -1)
    GOOD SHOES: Of course. The last one.
    She poured it and put it down in front of him without letting go of it until he'd said thank you.
    WRONGMAN: The last one. Everybody in the story had a last one. Some of them had six.
    -> carry_on
* [Let it go. He's no trouble.]
    ~ pass(1)
    ~ banned_held = -1
    ~ rep(rep_staff, -2)
    She poured it. She looked at the doorman while she did, the whole time, and didn't spill a drop.
    FATHER: One was the deal. Now there isn't a deal. There's just him.
    -> carry_on


// ------------------------------------------------------------------ 12:40 RAINCOAT

=== door_wife ===
~ here = door
~ arrivals += wife_done
~ wife_at = clock
A woman in a long raincoat came to the door and stopped in the vestibule and didn't come further in. Sixties, car keys, a face that had done this before.
RAINCOAT: Is Dennis here.
It wasn't really a question.
{ knows ? dennis:
    Dennis was the one in the big glasses at table 28. The bartender had called him by name all night.
- else:
    He didn't know who Dennis was.
}
TABLE28: No Dennis here! Never heard of him!
Table 28 had heard her. Table 28 heard everything that came through the door, and they said it together, in one voice, and then they laughed.
// HUTCH: The wife coming to get one of table 28. Covering for a regular is part of the job and so is not covering for him. How does it go?
- (wf)
* ["Which one's Dennis?" #check: manual 6]
    ~ pass(1)
    { passed:
        MANUAL: You are not required to disclose the identity of any patron.
        Which was true, and no help.
    - else:
        MANUAL: Refer to privacy.
    }
    RAINCOAT: The one pretending he can't see me.
    -> wf
+ ["He's not here."]
    ~ arrivals += wife_lied
    ~ knows += dennis
    ~ rep(rep_t28, 2)
    ~ pass(1)
    RAINCOAT: His truck's in your lot. Same spot as always.
    RAINCOAT: Tell him the dog's been sick on the bed. He'll know what that means.
    She went. At table 28, the one in the big glasses raised his drink an inch toward the doorman, not looking at him.
    FATHER: You lied for a drunk to his wife. Remember that you did that.
    # task: dog :: Tell Dennis the dog's been sick on the bed.
    -> at_door
+ ["I'll tell him you're here."]
    ~ arrivals += wife_told
    ~ knows += dennis
    ~ room_count--
    ~ pass(3)
    ~ here = t28
    He walked over to table 28. Five faces turned up at him.
    TABLE28: Traitor!
    But they laughed, and the one in the big glasses put his coat on, slowly, finishing his drink with it half on.
    GLASSES: She'll have her keys out. Thirty years, she's had her keys out.
    He went. Table 28 went on talking over the place where he'd been sitting before the door had shut behind him, the way water closes.
    ~ rep(rep_t28, -1)
    -> carry_on
+ ["Go on in. He's by the window."]
    ~ arrivals += wife_in
    ~ knows += dennis
    ~ incident += inc_wife
    ~ room_count--
    ~ pass(2)
    She walked straight across the carpet to table 28 without taking off her raincoat and stood behind the one in the big glasses until he stood up.
    Nobody at table 28 said anything until the door had shut behind them both. Then all of them at once.
    TABLE28: That's on you, new kid! That's on you!
    ~ rep(rep_t28, -2)
    -> at_door
