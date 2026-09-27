// The main door. Each person is a short read: ID, how drunk, who they're with, what they want.
// In, out, or in on conditions. Arrivals: HOODIE 7:50, the sister 8:50 or 9:40, HI-VIS 9:00,
// GOOD SHOES 10:30, RAINCOAT 12:40. If he isn't at the door when they come, see sim.ink.

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
{ once:
- He sat on the stool with the clicker in his fist. The rain ran down the glass. A truck went by on the highway and its lights went across the ceiling.
- Nothing came in for a while. The ice machine dumped a load behind the bar. Table 28 laughed at something on the TV, together, on the same beat.
- Two men came in out of the rain, shaking it off, regulars by the way they didn't look at him. He clicked them in. #sfx: clicker
    ~ count_in += 2
    ~ room_count += 2
- A woman came in to buy smokes from the machine by the door and went out again without looking at anybody.
- The door swung in and nobody came through it. Wind.
- A man he'd clicked in an hour ago went out to his truck, sat in it with the engine running for ten minutes, and came back in. He let him past without clicking. Once in is once in.
- The lot was empty except for the pickup at the edge of it. {fam ? kids_waiting:The pickup was still there with its engine running.|}
}
{fam ? kids_waiting && knows !? truck:
    The pickup that had brought the kid was still out there at the edge of the lot, engine running, wipers on intermittent.
    ~ knows += truck
}
<- moves(door)
+ [Stay on the door.]
    ~ pass(15)
    -> door_quiet


// ------------------------------------------------------------------ 7:50 HOODIE

=== door_hoodie ===
~ here = door
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
    HOODIE: hey
    The kid took the phone back. He didn't snatch it. He put it in the pouch of his sweatshirt and kept his hand in there with it.
    ~ rep(rep_kids, -1)
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
    The kid looked at him properly for the first time, and took one earbud out.
    HOODIE: it's been raining since tuesday
    FATHER: That's it. You get a minute with each of them. Be decent in it, and the no goes down easier.
    -> read
* ["Take the earbuds out."]
    ~ pass(1)
    The kid took one out. Something loud and sad leaked out of it, tinny, a woman's voice.
    HOODIE: what
    -> read
* ["Where's the card?"]
    ~ pass(1)
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
        HOODIE: just someone
        He put the earbud back in.
    * * [Let it go.]
    - - FATHER: He's not here to drink. He's here for somebody inside. That's worse.
    -> read
+ {not swiped} [Scan the phone.]
    ~ pass(1)
    He held the phone under the scanner. It thought about it and gave him the red light. #sfx: scanner_bad
    MANUAL: The scanner reads cards. It does not read photographs of cards. The scanner is, in this respect, correct.
    -> read
+ ["In you go."]
    -> admit
+ ["Not without the card."]
    -> refuse
+ {door_reads > 1} ["Go get the card. I'll be here."]
    -> fetch
+ {door_reads > 2} ["You can come in. On conditions."]
    -> conditions

= admit
~ pass(1)
~ fam += hoodie_admitted
~ kids_in = 1
~ count_in++
~ room_count++
~ rep(rep_kids, 1)
He stood aside. The kid went past him without a word and stopped just inside, dripping on the carpet, looking at the room. #sfx: clicker
{ knows !? kid_legal:
    ~ rep(rep_staff, -1)
    Behind the bar, the bartender had stopped cutting limes. She'd seen the phone. She didn't say anything. She started cutting again.
    MANUAL: For the record, you did not verify his age.
}
The kid went and stood by the jukebox with his hood still up. He didn't order. He didn't sit.
-> hub

= refuse
~ pass(1)
~ fam += hoodie_refused
~ incident += inc_kid_refused
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
-> hub

= fetch
~ pass(5)
~ fam += hoodie_admitted
~ kids_in = 1
~ knows += kid_legal
~ count_in++
~ room_count++
~ rep(rep_kids, 1)
~ rep(rep_staff, 1)
The kid went back across the lot. The driver's window came down. There was a conversation, short, with a lot of hand in it from the driver's side. The window went up.
He came back with a wet wallet and held out a licence, the real one. The scanner gave it a green light. #sfx: scanner_ok #prop: hoodie_card
MANUAL: Valid. Nineteen. Thank you.
He went past into the room and stood by the jukebox with his hood still up, dripping on the carpet. He didn't order. #sfx: clicker
FATHER: His sister's still out there with the engine running. Wonder why.
~ knows += truck
-> hub

= conditions
~ pass(1)
He held up a hand.
* ["You're in. No drinking tonight."]
    HOODIE: fine
    It was clearly fine. He hadn't come to drink.
* ["You're in. You stay where I can see you."]
    HOODIE: k
* ["You're in if your sister comes in with you."]
    The kid looked back at the truck for a long moment.
    HOODIE: she's not gonna
    HOODIE: she can't. i mean she won't
    FATHER: Can't. He said can't first.
    ~ knows += truck
- ~ fam += hoodie_admitted
~ fam += hoodie_conditions
~ kids_in = 1
~ count_in++
~ room_count++
~ rep(rep_kids, 1)
~ rep(rep_staff, 1)
He let him past. The kid went and stood by the jukebox. He watched the pool table the way you watch a dog you don't know. #sfx: clicker
-> hub


// ------------------------------------------------------------------ the sister: 8:50 if HOODIE was turned away, 9:40 if he was let in

=== ev_sister ===
~ here = door
~ door_away = 0
~ fam += sister_met
~ knows += truck
The bartender caught his eye and pointed her chin at the front door.
A young woman stood in the vestibule with car keys in her fist and rain in her hair. Behind her, holding the door open with his shoulder, a guy in a soaked hoodie with a vape in his hand. #portrait: driver
{ fam ? hoodie_refused:
    { fam ? hoodie_rapport:
        DRIVER: My brother was just here. He said you were all right about it.
    - else:
        DRIVER: My brother was just here. You told him no.
    }
- else:
    DRIVER: My brother's in there. Kid in the grey hoodie.
}
She had her licence out already, held up at eye level, not a photo, the card. Twenty-two. #prop: driver_card
VAPE: we're just here to get her dad bro. two minutes
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
    DRIVER: Our dad. Big guy. At the pool table, I'd bet my life.
    FATHER: The big one with the left hand.
    ~ knows += bigman_dad
    -> sister_opts
* ["What's it about?"]
    ~ pass(2)
    She looked at him like she was deciding how much he was owed.
    DRIVER: Our mom's in the hospital in town. Since this morning. He's not answering his phone.
    DRIVER: He doesn't answer when he's here.
    // HUTCH: Draft reason. Replace with whatever you've actually seen bring family into a bar after someone.
    ~ knows += kid_why
    ~ knows += bigman_dad
    FATHER: He never answered either.
    It wasn't clear which of them the Father meant.
    -> sister_opts
* [Look at the boyfriend. #check: fighter 6]
    ~ pass(1)
    { passed:
        FIGHTER: He's had eight and he wants a ninth. Weight on his heels, chin up. He's the one who'll swing, and he'll swing at the biggest thing in the room.
    - else:
        FIGHTER: Soft. Drunk. Nothing.
        The Fighter was wrong about soft.
    }
    -> sister_opts
* ["ID for him too."]
    ~ pass(1)
    VAPE: bro
    VAPE: it's in my other pants
    FATHER: It's always in the other pants.
    -> sister_opts
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

= sister_alone
~ pass(1)
~ fam += sister_admitted
~ kids_in++
~ count_in++
~ room_count++
~ rep(rep_kids, 1)
VAPE: are you serious
DRIVER: Kyle. Truck.
He went. He took his time about it and the vape with him. #sfx: clicker
She went in past the doorman. She didn't look at the pool table right away. She looked at the floor first, like someone getting ready to lift something heavy.
{ fam ? hoodie_refused:
    She came back to the door a minute later.
    DRIVER: Can my brother come in. He's nineteen. You saw the picture.
    * ["Get him."]
        ~ fam += hoodie_admitted
        ~ kids_in++
        ~ count_in++
        ~ room_count++
        She waved at the truck. The kid came across the lot. He clicked him in, and this time the kid looked at him for almost a whole second. #sfx: clicker
        ~ rep(rep_kids, 1)
        -> hub
    * ["Just you."]
        DRIVER: Okay.
        She said it the way you say it when you're adding something to a list.
        -> hub
}
-> hub

= sister_all
~ pass(1)
~ fam += sister_admitted
~ rep(rep_kids, 2)
{ fam ? hoodie_refused:
    ~ fam += hoodie_admitted
    ~ kids_in += 3
    ~ count_in += 3
    ~ room_count += 3
    She waved at the truck. The kid came across the lot. The three of them went in past him, the sister first. #sfx: clicker
- else:
    ~ kids_in += 2
    ~ count_in += 2
    ~ room_count += 2
    The two of them went in past him. #sfx: clicker
}
VAPE: appreciate you bro
He said it on his way to the bar, not the pool table.
MANUAL: The one with no identification is now inside and ordering.
FATHER: You let the weather in.
-> hub

= sister_fetch
~ pass(2)
~ fam += sister_fetched
DRIVER: You'd do that?
VAPE: bro he's gonna do it wrong
DRIVER: Kyle.
{ fam ? hoodie_admitted:
    DRIVER: Tell my brother to come out too. He's useless in there. He won't even talk to him.
}
She waited in the vestibule, dripping, with her keys. The boyfriend went back to the truck.
FATHER: Now it's your errand. You carry it right or you carry it wrong, but you're carrying it.
# task: fetch :: Tell the big man at the pool table his daughter's at the door.
-> hub

= sister_no
~ pass(1)
~ fam += sister_refused
~ fam += kids_waiting
~ rep(rep_kids, -2)
~ incident += inc_kid_refused
DRIVER: Right.
She didn't argue. She looked past him into the room for as long as she could, then turned around.
VAPE: this guy
They went back across the lot. The truck's engine was still running. It kept running.
{ fam ? hoodie_admitted:
    Her brother was still inside.
}
-> hub


// ------------------------------------------------------------------ 9:00 HI-VIS

=== door_hivis ===
~ here = door
~ arrivals += hivis_done
A man in a hi-vis vest over a hoodie came in from the lot with a two-four of beer under one arm, the box going soft in the rain. Mill dust in the creases of his hands. #portrait: hivis
HI-VIS: Evening.
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
    HI-VIS: Up the stairs, eventually. I'm in room eleven. Crew's on the mill contract.
    HI-VIS: Last contract, sounds like. Nobody's saying it but that's what it sounds like.
    ~ knows += hivis_room
    He shifted the case of beer.
    HI-VIS: Went to the store for the boys. Thought I'd have one down here first where it's warm.
    -> hv
* ["You can't bring that in."]
    ~ pass(1)
    HI-VIS: It's for upstairs.
    {knows ? hotel_gap:
        FATHER: Then he can take it upstairs through the hotel door. Like he'd do anyway if you weren't here.
    }
    -> hv
+ ["Go on in."]
    ~ arrivals += hivis_in
    ~ count_in++
    ~ room_count++
    ~ pass(1)
    He went past with the case still under his arm and put it on the floor by a stool at the bar. The bartender looked at the case, then at the doorman. #sfx: clicker
    ~ rep(rep_staff, -1)
    ~ incident += inc_hivis
    -> hub
+ ["Leave the beer with me and go on in."]
    ~ arrivals += hivis_in
    ~ arrivals += hivis_cond
    ~ count_in++
    ~ room_count++
    ~ pass(1)
    HI-VIS: Fair.
    He set the case down by the stool. The doorman pushed it behind the door with his foot. #sfx: clicker
    ~ rep(rep_staff, 1)
    -> hub
+ ["Take it up to your room. You can come down after."]
    ~ arrivals += hivis_out
    ~ pass(1)
    HI-VIS: Yeah. Yeah, all right.
    He went back out into the rain and around the side of the building, toward the hotel entrance.
    {hotel_door:
        FATHER: And he'll come down the back stairs through the hotel door and you'll never know. Unless you lock it.
    }
    -> hub
+ ["Not tonight. You've had enough."]
    ~ arrivals += hivis_out
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
    -> hub


// ------------------------------------------------------------------ 10:30 GOOD SHOES

=== door_banned ===
~ here = door
~ arrivals += banned_done
A man in a good wool coat came in, closing a golf umbrella. Shaved that evening. Shoes that had never walked on gravel before tonight. #portrait: goodshoes
GOOD SHOES: Evening. Filthy out there.
He had his licence ready before he was asked, and he smiled like they'd met. #prop: goodshoes_card
{ knows ? banned_face:
    He had met him. In the binder. Page three, a photocopied driver's licence and the bartender's handwriting underneath: NO. NOT EVER.
    -> known
}
{ knows ? eighty_six:
    Something about the face. He'd seen it recently, badly lit.
    * [Place the face. #check: manual 8]
        ~ pass(1)
        { passed:
            MANUAL: Binder. Page three. Photocopy of a licence. Barred.
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
}
-> unknown

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
    The scanner gave it a green light. #sfx: scanner_ok
    MANUAL: Valid. Fifty-one years of age. The scanner does not check the barred list. The barred list is in a binder, under the till.
    -> gs
* ["Been here before?"]
    ~ pass(1)
    GOOD SHOES: Years ago. Place hasn't changed. That's the charm.
    -> gs
* {knows ? eighty_six} [Hold the licence up by his face. #toy: goodshoes_card look #unlisted]
    -> recognised
+ ["Go ahead."]
    -> let_in
+ {knows ? eighty_six} ["Give me a second." Go check the binder.]
    ~ pass(3)
    He left the man in the vestibule and went behind the bar to the binder. The bartender watched him come and knew why before he got there.
    Page three.
    ~ knows += banned_face
    He came back.
    -> known
+ {knows !? eighty_six} ["Give me a second." Ask the bartender.]
    ~ pass(2)
    He went over to the bar. He didn't have to say anything. She looked past him at the man in the vestibule and her face shut like a door.
    BARTENDER: No.
    BARTENDER: Binder, page three. Not ever.
    ~ knows += banned_face
    ~ knows += eighty_six
    ~ rep(rep_staff, 1)
    -> known

= known
FATHER: There it is.
GOOD SHOES: I can see you've got a book with pictures in it.
He smiled.
GOOD SHOES: That's old. Talk to the owner. We've spoken. I'm allowed back. I'll be putting a couple hundred over that bar tonight, and I'm not trouble to anyone.
// HUTCH: What did he do? The draft only says the bartender wrote NOT EVER under his photo. Decide what it was, or leave it unsaid.
- (gk)
* ["What did you do?"]
    ~ pass(1)
    GOOD SHOES: Something I'm not proud of. A long time ago. I've paid for it, believe me.
    WRONGMAN: He'd paid for it. They always had.
    -> gk
* ["I'll call the owner."]
    ~ pass(2)
    He went to the bar phone and rang the number taped to the wall. It rang until it stopped.
    MANUAL: The owner is unavailable. The barred list is available.
    -> gk
+ ["Not tonight. Not any night."]
    -> turn_away
+ ["The binder says no. The binder wins."]
    -> turn_away
+ ["One drink. You sit where I can see you."]
    ~ arrivals += banned_in
    ~ count_in++
    ~ room_count++
    ~ incident += inc_banned
    ~ rep(rep_staff, -3)
    ~ rep(rep_owner, 1)
    ~ pass(1)
    GOOD SHOES: That's all I ask.
    He went to the bar. The bartender served him, because it was her job, and she didn't say one word while she did it. #sfx: clicker
    She didn't look at the doorman for the rest of the night.
    -> hub
+ ["Go ahead."]
    -> let_in

= let_in
~ arrivals += banned_in
~ count_in++
~ room_count++
~ incident += inc_banned
~ pass(1)
{ knows ? banned_face:
    ~ rep(rep_staff, -4)
- else:
    ~ rep(rep_staff, -2)
}
~ rep(rep_owner, 1)
He went to the bar and put a fifty on it. #sfx: clicker
The bartender looked at the fifty and then at the man and then, over his shoulder, at the doorman. She served him. It was her job. She didn't say anything while she did it.
{ knows !? banned_face:
    WRONGMAN: That's how it starts in the story. You don't know. That's the whole point of the story.
}
-> hub

= turn_away
~ arrivals += banned_out
~ rep(rep_staff, 3)
~ rep(rep_owner, -1)
~ pass(2)
GOOD SHOES: The owner will hear about this.
He didn't answer. He let his size answer. The man looked at him for a while, opened his umbrella in the vestibule, which was bad luck, and went out.
The bartender didn't look up. After a while she brought him a glass of water he hadn't asked for and put it on the ledge by the stool.
-> hub


// GOOD SHOES came in while nobody was on the door.
=== ev_banned_inside ===
~ banned_stage = 1
~ here = bar
The bartender came around the end of the bar, which she didn't do, and stood in front of him.
BARTENDER: There's a man at my bar who is not allowed at my bar.
She didn't point. She didn't have to. A good wool coat, a golf umbrella hooked on the rail, a fifty on the bar that she hadn't touched.
BARTENDER: Page three. I'm not serving him and I'm not asking him. That's yours.
~ knows += banned_face
~ knows += eighty_six
FATHER: You weren't on the door. This is what not being on the door costs.
- (bi)
* [Walk him out quietly. #check: father 8]
    ~ pass(5)
    { passed:
        He stood beside the stool, close, and said it low, so nobody else had to hear. Coat, umbrella, the door, now. The man looked at him for a long second and did the arithmetic.
        GOOD SHOES: Fine.
        He left the fifty on the bar. The bartender put it in the tip jar without looking at it.
        ~ rep(rep_staff, 2)
    - else:
        He said it low. The man didn't lower his voice back.
        GOOD SHOES: I have been given permission by the owner of this establishment.
        Table 28 went quiet to listen. He walked him out anyway, a hand on his elbow the whole way, and the man said "the owner will hear about this" three times before the door shut.
        ~ rep(rep_staff, 1)
        ~ rep(rep_t28, 1)
    }
    ~ arrivals += banned_out
    ~ room_count--
    -> hub
* [Put him out. #check: fighter 6]
    ~ pass(3)
    { passed:
        He took the man's arm above the elbow, turned him off the stool, and walked him to the door at a pace he couldn't argue with. It was over before table 28 noticed. #sfx: door
        ~ rep(rep_staff, 1)
    - else:
        The man grabbed the bar rail. The stool went over. It took longer than it should have and everybody watched, and when the door swung shut the man was outside shouting about lawyers. #sfx: hit
        ~ incident += inc_fight
        ~ rep(rep_staff, 1)
        ~ rep(rep_t28, 1)
    }
    ~ arrivals += banned_out
    ~ room_count--
    -> hub
* ["He says the owner lifted it."]
    ~ pass(1)
    BARTENDER: The owner didn't write it. I did.
    -> bi
* [Leave him. It's not worth the scene.]
    ~ pass(1)
    ~ rep(rep_staff, -4)
    ~ arrivals += banned_in
    BARTENDER: Right.
    She went back behind the bar. She served the man's next drink herself, slowly, and for the rest of the night she didn't look at the doorman at all.
    -> hub


// ------------------------------------------------------------------ 12:40 RAINCOAT

=== door_wife ===
~ here = door
~ arrivals += wife_done
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
    ~ rep(rep_t28, 2)
    ~ pass(1)
    RAINCOAT: His truck's in your lot.
    RAINCOAT: Tell him the dog's been sick on the bed. He'll know what that means.
    She went. At table 28, the one in the big glasses raised his drink an inch toward the doorman, not looking at him.
    FATHER: You lied for a drunk to his wife. Remember that you did that.
    -> hub
+ ["I'll tell him you're here."]
    ~ arrivals += wife_told
    ~ pass(3)
    He walked over to table 28. Five faces turned up at him.
    TABLE28: Traitor!
    But they laughed, and the one in the big glasses put his coat on, slowly, finishing his drink with it half on.
    GLASSES: She'll have her keys out.
    ~ knows += dennis
    He went. Table 28 closed up the gap where he'd been sitting without a word about it, the way water closes.
    ~ rep(rep_t28, -1)
    -> hub
+ ["Go on in. He's by the window."]
    ~ arrivals += wife_in
    ~ incident += inc_wife
    ~ pass(2)
    She walked straight across the carpet to table 28 without taking off her raincoat and stood behind the one in the big glasses until he stood up.
    Nobody at table 28 said anything until the door had shut behind them both. Then all of them at once.
    TABLE28: That's on you, new guy.
    ~ rep(rep_t28, -2)
    -> hub
