// The smoking deck, on the water side, and the gravel lot out front.
// The deck door is propped with a folded coaster every night. Things come in that way, people
// go out that way to fight, and people come back in that way who were put out the front
// (bible/06_THE_HOTEL.md). The lot is where the pickup waits.

=== function vape_on_deck()
~ return vape_at == s_lot && fam ? vape_ejected && not deck_door && clock >= vape_out_at + 20 && not fam_done && not at_deck.vape_back

=== function cardigan_on_deck()
~ return clock < 1350 && not at_deck.cardigan && arrivals !? wife_in


=== at_deck ===
~ here = deck
{ due(): -> hub }
# amb: deck
{ at_deck == 1:
    He went out through the deck door. {deck_door:A folded coaster was wedged in the latch so it wouldn't lock behind anyone.|It was locked. He let himself out with the key on his ring.}
    A covered deck on the water side of the building. Plastic chairs, a coffee can full of butts, a tin awning the rain came off in ropes. Under one of the chairs, a pink lighter and the torn foil off a condom. Across the highway, past the seawall, the strait, black, and the lights of the far shore.
    // HUTCH: The smoking deck. What happens out there that doesn't happen inside?
- else:
    {shuffle:
    - Out on the deck the rain came off the awning in ropes.
    - Somebody had left a full beer on the deck rail, in the rain.
    - It was cold on the deck after the room.
    }
}
{ fam ? via_deck && not at_deck.prints:
    -> prints
}
-> d_opts

= d_opts
{ due(): -> hub }
<- moves(deck)
{ cardigan_on_deck():
    The quiet one from table 28, the one in the cardigan, was at the rail with his back to the building and the room, smoking.
}
* {cardigan_on_deck()} [Stand at the rail beside him.]
    -> cardigan
* {vape_on_deck()} [Somebody's trying the deck door from outside.]
    -> vape_back
+ [Stand in the air a minute.]
    -> air
// Walking about the deck on his own feet (godot/game/feet.gd): only his legs make this.
+ [Walk about the deck. #toy: legs walk #unlisted]
    ~ pass(1)
    -> d_opts
+ {deck_door} [Pull the coaster out of the latch.]
    ~ pass(1)
    ~ deck_door = false
    He pulled the coaster out and let the door shut and lock behind him. A woman smoking by the steps watched him do it and put her cigarette out on the rail.
    ~ rep(rep_t28, -1)
    FATHER: Now they come past you or they don't come.
    -> d_opts

= prints
He looked down. On the boards by the steps, and then on the carpet inside the door, going away from it, were wet prints. Sneakers, three pairs, from the deck steps to the door and in.
{ deck_door:
    And the coaster in the latch.
}
FATHER: The kid you turned away. He didn't go home. He came round the back, and he brought his family.
-> d_opts

= air
~ pass(5)
{ stopping:
- He stood at the rail. Out on the strait {clock < 1320:the last ferry was going across, lit up like a building on its side|a tug was pushing a barge up the dark with one light at each end}.
    NARRATOR: He stood out there most nights after that.
- He stood at the rail. A car went by on the highway, slow, and its lights went along the seawall.
- He stood at the rail and let the cold get into him. Behind him, through the glass, table 28 laughed at something, together.
- He stood at the rail. The rain.
}
{ drinks >= 2 && at_deck.air == 1:
    The air helped. It helped less than he'd have liked.
}
// What the smokers say with him standing there, as if a doorman were a post. (Claude's draft.)
// godot/world/stage.gd stands whoever's next to talk out there (deck_smokers), by the same tests.
{
- arrivals !? banned_done && knows !? ardagh && clock >= 1230:
    ~ deck_smokers = 1
    ~ smokers_at = clock
    Two women were smoking under the awning by the steps. They didn't lower their voices for him.
    SMOKER: Graham Ardagh's back. I saw his car at the Esso.
    SMOKER: She'd have him shot. She'd do it herself, with the soda gun.
    They both looked through the glass at the bartender, and then didn't.
    ~ knows += ardagh
- knows !? truck && not truck_gone:
    ~ deck_smokers = 2
    ~ smokers_at = clock
    A man smoking by the steps was watching the lot.
    SMOKER: That pickup's been sitting there since eight with the engine going. Somebody's waiting on somebody.
    SMOKER: Last time a truck sat out there like that it was Darlene's husband, with his rifle on the seat. He was only going to scare her, he said.
    ~ knows += truck
- knows !? mill_closing:
    ~ deck_smokers = 3
    ~ smokers_at = clock
    Two of the mill crew were smoking at the far end of the deck, one of them still in his vest.
    SMOKER: They're saying the mill's done at Christmas. My brother-in-law says Christmas.
    SMOKER: They've been saying Christmas for six years.
    SMOKER: Forty-five percent the Yanks are charging on a board now. And the logs go out raw off the dock in Nanaimo, on a Chinese boat, past the mill. I've watched them go.
    ~ knows += mill_closing
}
-> d_opts

= cardigan
~ pass(8)
~ pull_table++
Away from the table the man looked smaller, and older, and more like one man.
CARDIGAN: Please don't tell them I'm out here. They think I've gone to the washroom.
// HUTCH: The quiet one at table 28, away from the table. What does one of the hive say when he's on his own?
- (cg)
* ["How long have you been coming here?"]
    ~ knows += t28_nine
    CARDIGAN: Since the mill was three shifts. There were nine of us at that table, once. You couldn't get a chair.
    CARDIGAN: Now there's five. Four, some days.
    -> cg
* (four) ["What happened to the other four?"]
    CARDIGAN: What always happens. Two of them died. Les went off the road past the Esso, driving home from that table, and Bob took the long way, with his liver, upstairs at the hospital in town. One is in the home and doesn't know anybody. And one went to Alberta to be near his grandchildren, and we never heard from him again. Not a Christmas card.
    CARDIGAN: We moved the chairs round.
    He looked at the end of his cigarette.
    CARDIGAN: My daughter wants me in Calgary.
    -> cg
* {four} ["Will you go?"]
    CARDIGAN: I don't know.
    CARDIGAN: If I go, they'll move the chairs round. If I stay, I'll die at that table, like Bob.
    FATHER: He wants you to tell him.
    * * ["Go."]
        ~ cardigan_go = 1
        CARDIGAN: It's easy for you to say, I suppose.
        No heat in it. He put the cigarette out on the rail and put the butt in his pocket, not in the can.
    * * ["Stay."]
        ~ cardigan_go = -1
        CARDIGAN: Yes.
        CARDIGAN: Yes. That's what they would say.
    * * ["I don't know either."]
        ~ cardigan_go = 2
        CARDIGAN: No. Nobody does.
    - - -> cg
+ [Leave him to his smoke.]
    ~ cardigan_secret = true
    CARDIGAN: Not a word to them, please.
    -> d_opts

= vape_back
~ pass(2)
The boyfriend had come up the deck steps in the rain and was rattling the door he'd have walked straight through an hour ago, if the coaster had still been in it. He'd come round the building from the lot. When he saw the doorman through the glass he tried to look like he'd been out here smoking the whole time.
VAPE: bro. i was just out here
VAPE: i've been out here the WHOLE time my guy
FIGHTER: He's been round the whole building in the rain for this.
* ["Go sit in the truck."]
    { in_truck(sister_at):
        VAPE: she's not gonna let me in
        He went anyway, round the side of the building, with his hood up. A while later the pickup's back door opened, and shut.
        ~ move(vape_at, s_truck)
    - else:
        VAPE: it's LOCKED
        VAPE: she locked it bro. she locked me out
        He went anyway, round the side of the building, with his hood up, and stood by the locked pickup in the rain.
    }
* [Walk him round to the lot. #check: fighter 10 {vape_mod()}]
    { passed:
        He took him by the arm and walked him round the side of the building to the pickup, and stood there until he'd got in the back, and then stood there a minute longer.
        ~ move(vape_at, s_truck)
    - else:
        The boyfriend pulled his arm away and swung, wild, and missed, and went down the deck steps on his own. He lay in the gravel for a second, and then got up and went round to the lot holding his wrist. #sfx: hit
        ~ incident += inc_hurt
    }
// In past the stool he wasn't on: one more who didn't come past him at the door, the same as if he'd let himself in.
* [Let him back in.]
    ~ fam -= vape_ejected
    ~ move(vape_at, s_bar)
    ~ uncounted++
    ~ vape_backs++
    ~ heat(2)
    VAPE: appreciate you chief
    He went straight to the bar.
    FATHER: You put him out and let him back in. Now he knows what your out is worth.
- -> d_opts


// ------------------------------------------------------------------ the three who came in the back

=== ev_deck_kids ===
~ deck_kids_seen = true
The kid in the hoodie was standing by the jukebox. #look: hoodie
The kid he'd turned away at the door with the photo of his ID. His sister was at the rail by the pool table with her car keys in her fist, and the boyfriend was at the bar trying to get served. None of them had come past the stool. Their sneakers had left dark prints on the carpet from the back of the room.
{ doors_left ? left_deck:
    FATHER: You walked the doors. You stood at that one and left the coaster in it.
- else:
    FATHER: The deck. You knew about the coaster.
}
MANUAL: Three persons on the premises who were not admitted. One refused entry. One with no identification presented.
- (dk)
* [Talk to the sister first.]
    ~ pass(3)
    ~ fam += sister_met
    ~ knows += kid_why
    ~ knows += bigman_dad
    ~ knows += truck
    ~ here = pool
    #portrait: driver
    She didn't wait for him to start.
    DRIVER: We're not here to drink. Our dad's at the pool table. Our mom's in the hospital in town, since this morning, and he won't answer his phone.
    DRIVER: You wouldn't let my brother in. So.
    // HUTCH: The family came in the back after the door said no. What does she say to the doorman who turned her brother away?
    -> dk
* [Put all three of them out.]
    ~ pass(4)
    ~ fam += sister_met
    ~ fam += kids_waiting
    ~ kids_out()
    ~ rep(rep_kids, -2)
    ~ here = door
    He walked them to the front door, the three of them, and none of them argued. The sister went last. At the door she stopped.
    DRIVER: Our mom's in the hospital in town. Since this morning. He doesn't know. That's all this is.
    ~ knows += kid_why
    ~ knows += bigman_dad
    * * ["Then I'll tell him."]
        ~ fam += sister_fetched
        # task: fetch :: Tell the big man at the pool table about his wife.
        DRIVER: Okay.
    * * ["Wait in the truck."]
        ~ fam += told_wait
        ~ rep(rep_kids, -1)
        DRIVER: We've been waiting in the truck. Since eight.
    - - They went back across the lot. The pickup didn't leave.
    -> carry_on
// Letting them in now, in the middle of the room, takes them off the list of the ones who got past him.
* (counted) ["You came in the back. Fine. You're in now, on me."]
    ~ pass(3)
    ~ fam += sister_met
    ~ fam += sister_admitted
    ~ fam += hoodie_admitted
    ~ count_in += kids_in
    ~ uncounted -= kids_in
    ~ rep(rep_kids, 2)
    ~ here = floor
    He looked at the three of them one at a time, the way he'd have looked at them at the door, standing there in the middle of the room, and the kid in the hoodie looked back at him.
    MANUAL: For the record, one of them has no identification.
    FIGHTER: Watch the boyfriend.
    -> carry_on
* [Leave them. Watch.]
    ~ pass(1)
    ~ fam += sister_met
    ~ fam += sister_admitted
    ~ fam += hoodie_admitted
    ~ here = floor
    He went back to where he could see the pool table and the jukebox and the bar all at once, and watched.
    FIGHTER: The boyfriend. It'll be the boyfriend.
    -> carry_on
* {knows ? kid_why} ["I'll tell him for you."]
    ~ pass(1)
    ~ fam += sister_admitted
    ~ fam += hoodie_admitted
    ~ fam += sister_fetched
    # task: fetch :: Tell the big man at the pool table about his wife.
    DRIVER: He'll say he's coming after.
    DRIVER: He always says after.
    -> carry_on


// ------------------------------------------------------------------ the pickup in the lot

// Out the front, under the sign, for the air: the lot, the highway, the seawall across it and the
// strait past that. Walked about on his own feet in the 3D build (godot/game/feet.gd). While he's
// out here nobody's on the stool, and door_away counts it (sim.ink).
=== at_front ===
~ here = lot
{ due(): -> hub }
# amb: rain_lot
{ at_front == 1:
    He went out through the vestibule and stood under the sign, and the door swung shut on the room behind him. The rain had gone to a mist that hung in the light off the roof. Across the highway, the seawall, and past it the strait, and past that nothing at all. Up the road the Esso's canopy was the brightest thing for a mile.
    His breath went out white. He hadn't known how loud it was in there until it stopped.
- else:
    {shuffle:
    - He stood out front under the sign. Up on the roof it buzzed, one letter a beat behind the others.
    - Out front the mist hung in the sign's light. Red, then not, then red.
    - Out front it was quiet. The room was a bass line through the wall and nothing else.
    - He stood out front. Somebody had written CALL ME DADDY in the dirt on the beer store's window, and under it, in a different hand, NO.
    }
}
-> f_opts

= f_opts
{ due(): -> hub }
<- moves(lot)
+ [Stand in the air a minute.]
    -> f_air
+ [Walk about the lot. #toy: legs walk #unlisted]
    ~ pass(1)
    -> f_opts
// out on the grounds (grounds.ink): handling one of these things out there is more than a look
+ {out_merle < 6} [The man fishing off the seawall. #toy: merle look #unlisted] -> out_merle
+ {not out_cross} [The cross on the shoulder. #toy: cross look #unlisted] -> out_cross
+ {not out_kelp} [Something in the kelp. #toy: kelp look #unlisted] -> out_kelp
+ [The buzzers by the hotel door. #toy: buzzers look #unlisted] -> out_buzzers
+ {not out_caps} [The bottle caps by the vent. #toy: caps look #unlisted] -> out_caps
+ {esso_rang && esso_answered == 0} [The Esso's payphone, ringing. #toy: esso_phone look #unlisted] -> out_payphone
+ [The Esso's night window. #toy: esso_clerk look #unlisted] -> out_clerk
+ {not out_fire} [The fire on the beach. #toy: beach_fire look #unlisted] -> out_fire
+ {kitchen_door} [The kitchen's back door, propped. #toy: kitchen_door look #unlisted] -> out_kitchen_door

= f_air
~ pass(3)
{ stopping:
- A pickup went by on the highway with a man standing up in the bed, holding the roll bar, shouting at the sea. It went round the bend and took the shouting with it.
    FATHER: Nobody's on the stool.
- Two kids were sitting on the hood of a Civic at the far end of the lot, passing a vape back and forth and filming each other doing nothing. One of them saw him and put the phone face down on his leg, like a hand of cards.
- A couple were arguing in a car with the windows up and the dome light on, a play with the sound off. She hit the dashboard twice with the flat of her hand. He looked at his phone until she stopped.
- Somebody had been sick against the dumpster earlier, and the rain hadn't got all of it. A gull was seeing to the rest.
- A woman came out of the Esso with a two-four on her shoulder and walked straight across the highway without looking either way. Nothing hit her. She didn't look like she'd expected anything to.
- {clock >= 1440:Up the road the Esso kid was out by the pumps with his head back, looking at the sky over the strait. By the time he looked up too, there was only the cloud.|He stood in the mist. A truck went by, and the wet came up off the road behind it like a sheet shaken out.}
- He stood in the mist and let the cold get in under the jacket.
}
{ drinks >= 3 && f_air == 1:
    Out here the drink was louder than the room had been.
}
-> f_opts

=== at_lot ===
~ here = lot
{ due(): -> hub }
# amb: rain_lot
He went out across the gravel to the pickup at the edge of the lot with the rain going down his collar. The engine was running. The windows had fogged from the inside, except for a clear patch the size of a hand on the driver's side.
The window came down four inches. #portrait: driver
DRIVER: What.
{ indoors(kid_at):
    DRIVER: Is my brother okay?
}
{ fam ? told_wait && at_lot == 1:
    DRIVER: You said wait in the truck. We're waiting in the truck.
}
- (lt)
* {knows !? kid_why} ["What do you need to tell him?"]
    ~ pass(2)
    DRIVER: Our mom's in the hospital in town. Since this morning. He's not answering his phone.
    DRIVER: He never answers when he's in there.
    ~ knows += kid_why
    ~ knows += bigman_dad
    -> lt
* {fam !? sister_fetched} ["I'll tell him. I'll send him out."]
    ~ pass(1)
    ~ fam += sister_fetched
    # task: fetch :: Tell the big man at the pool table his family's waiting in the lot.
    DRIVER: He won't come.
    DRIVER: But okay. Thank you.
    -> lt
* ["Come in. Just you. Bring him out."]
    ~ pass(2)
    ~ fam -= kids_waiting
    ~ fam += sister_admitted
    ~ move(sister_at, s_rail)
    ~ count_in++
    ~ rep(rep_kids, 2)
    { promised_bigman:
        ~ promise_kept = -1
    }
    She turned the engine off. It was the first time it had been off all night.
    { fam ? sister_refused:
        -> you_said_no
    }
    -> goes_in
// What's in the back seat counts for the Fighter, later, if it comes to hands (vape_mod() in sim.ink).
* {in_truck(vape_at)} [Look in the back seat.]
    ~ pass(1)
    ~ knows += vape_cans
    The boyfriend was lying across the back seat with his hood over his face and the vape on his chest, going up and down with his breathing. Tallboys on the floor, eight or nine of them, rolling when he moved.
    VAPE: i'm sleeping
    { in_truck(kid_at):
        The kid was in the front, in the passenger seat, with his hood up and his earbuds in, not looking at anybody.
    }
    FIGHTER: Nine. He's had nine. He'll swing slow and wide.
    -> lt
+ [Go back in.]
    ~ pass(2)
    DRIVER: We'll be here.
    -> hub

= you_said_no
DRIVER: You said no.
* ["I was wrong."]
    ~ owned_it++
    She looked at him to see if he meant it.
    ~ rep(rep_kids, 1)
* ["I'm saying yes now."]
    ~ owned_it--
    DRIVER: Okay. Good for you.
- -> goes_in

= goes_in
She went in past him, into the room, and straight to the pool table.
~ heat(1)
-> hub


// ------------------------------------------------------------------ put out the front, back in the back

=== ev_vape_back ===
~ vape_seen = true
{ vape_backs > 1:
    The boyfriend was at the bar again, wet to the knees this time, and grinning at him. #look: vape
- else:
    The boyfriend was at the bar again, dripping, with his hood up, trying to get served. He hadn't come past the stool. There were wet sneaker prints on the carpet from the deck door. #look: vape
}
FIGHTER: The ones you put out the front come in the back. Every time.
{ doors_left ? left_deck:
    FATHER: You looked right at that coaster and left it in.
- else:
    FATHER: You left the coaster in.
}
* [Put him out again, and pull the coaster this time.]
    ~ pass(4)
    ~ fam += vape_ejected
    ~ vape_out_at = clock
    ~ vape_returned = false
    ~ vape_seen = false
    ~ move(vape_at, s_lot)
    ~ deck_door = false
    ~ here = door
    He walked him out the front again, the same way, the same length of the room, and this time the boyfriend didn't talk.
    ~ here = deck
    Then he went to the deck door and pulled the folded coaster out of the latch and let it lock. #sfx: door
    ~ rep(rep_t28, -1)
    FATHER: Now they come past you or they don't come.
* [Put him out again.]
    ~ pass(3)
    ~ fam += vape_ejected
    ~ vape_out_at = clock
    ~ vape_returned = false
    ~ vape_seen = false
    ~ move(vape_at, s_lot)
    ~ here = door
    { vape_backs > 1:
        He walked him out the front again. Neither of them said anything this time. On the gravel the boyfriend stood and looked at the deck, all the way round the side of the building, and then at the doorman, and went and sat on the step of the beer store instead. #sfx: door
    - else:
        He walked him out the front again. The boyfriend laughed the whole way. #sfx: door
    }
* [Leave him. He's back. Watch him.]
    ~ pass(1)
    ~ heat(1)
    The bartender served him. He looked at the doorman while he did it.
    ~ rep(rep_staff, -1)
- -> carry_on
