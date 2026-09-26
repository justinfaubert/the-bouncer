// The smoking deck, on the water side, and the gravel lot out front.
// The deck door is propped with a folded coaster every night. Things come in that way, people
// go out that way to fight, and people come back in that way who were put out the front
// (bible/06_THE_HOTEL.md). The lot is where the pickup waits.

=== function vape_on_deck()
~ return fam ? vape_ejected && not deck_door && clock >= vape_out_at + 20 && not fam_done && not at_deck.vape_back

=== function cardigan_on_deck()
~ return clock < 1350 && not at_deck.cardigan && arrivals !? wife_in


=== at_deck ===
~ here = deck
{ due(): -> hub }
# amb: deck
{ at_deck == 1:
    He went out through the deck door. {deck_door:A folded coaster was wedged in the latch so it wouldn't lock behind anyone.|It was locked. He let himself out with the key on his ring.}
    A covered deck on the water side of the building. Plastic chairs, a coffee can full of butts, a tin awning the rain came off in ropes. Across the highway, past the seawall, the strait, black, and the lights of the far shore.
    // HUTCH: The smoking deck. What happens out there that doesn't happen inside?
- else:
    {shuffle:
    - Out on the deck the rain came off the awning in ropes.
    - The deck. Wet plastic chairs, the coffee can, the lights of the far shore.
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
    The quiet one from table 28, the one in the cardigan, was at the rail with his back to the building, smoking alone.
}
* {cardigan_on_deck()} [Stand at the rail beside him.]
    -> cardigan
* {vape_on_deck()} [Somebody's trying the deck door from outside.]
    -> vape_back
+ [Stand in the air a minute.]
    -> air
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
- He stood at the rail. The rain came off the awning in ropes. Out on the strait the last ferry was going across, lit up like a building on its side.
    NARRATOR: He'd stand out there most nights for the next month. That was the first time.
- He stood at the rail. A car went by on the highway, slow, and its lights went along the seawall.
- He stood at the rail and let the cold get into him. Behind him, through the glass, table 28 laughed at something, together.
- He stood at the rail. The rain.
}
{ drinks >= 2 && at_deck.air == 1:
    The air helped. It helped less than he'd have liked.
}
-> d_opts

= cardigan
~ pass(8)
~ pull_table++
Away from the table the man looked smaller, and older, and more like one man.
CARDIGAN: Don't tell them I'm out here. They think I'm in the can.
// HUTCH: The quiet one at table 28, away from the table. What does one of the hive say when he's on his own?
- (cg)
* ["How long have you been coming here?"]
    CARDIGAN: Since the mill was three shifts. There were nine of us at that table once. Nine. You couldn't get a chair.
    CARDIGAN: Now there's five. Four, some days.
    -> cg
* (four) ["What happened to the other four?"]
    CARDIGAN: What happens. Two dead. One in the home in town who doesn't know anybody. One went to Alberta to be near his grandkids, and we never heard from him again, not once. Like he'd died, except he hadn't.
    CARDIGAN: The table closed up the gap. It always does.
    He looked at the end of his cigarette.
    CARDIGAN: My daughter wants me in Calgary.
    -> cg
* {four} ["Will you go?"]
    CARDIGAN: I don't know.
    CARDIGAN: If I go, they'll close up the gap. If I stay, I'll die at that table. Those are the choices. Everyone at that table has had them.
    FATHER: He's asking you. He doesn't know he's asking you.
    * * ["Go."]
        ~ cardigan_go = 1
        CARDIGAN: Easy for you to say.
        He said it without any heat. He put the cigarette out on the rail and put the butt in his pocket, not in the can.
    * * ["Stay."]
        ~ cardigan_go = -1
        CARDIGAN: Yeah.
        CARDIGAN: Yeah. That's what they'd say.
    * * ["I don't know either."]
        CARDIGAN: No. Nobody does.
    - - -> cg
+ [Leave him to his smoke.]
    CARDIGAN: Not a word to them.
    -> d_opts

= vape_back
~ pass(2)
The boyfriend was on the deck steps in the rain, rattling the door he'd have walked straight through an hour ago, if the coaster had still been in it. He'd come round the building from the lot. When he saw the doorman through the glass he tried to look like he'd been out here smoking the whole time.
VAPE: bro i was just out here
VAPE: i've been out here the whole time
FIGHTER: The ones you put out the front come in the back. Every time.
* ["Go sit in the truck."]
    VAPE: it's locked
    VAPE: she locked it
    He went anyway, round the side of the building, with his hood up.
* [Walk him round to the lot. #check: fighter 6]
    { passed:
        He took him by the arm and walked him round the side of the building to the pickup, and stood there until he'd got in the back, and then stood there a minute longer.
    - else:
        The boyfriend pulled his arm away and swung, wild, and missed, and went down the deck steps on his own. He lay in the gravel for a second, and then got up and went round to the lot holding his wrist. #sfx: hit
        ~ incident += inc_hurt
    }
* [Let him back in.]
    ~ fam -= vape_ejected
    ~ kids_in++
    ~ room_count++
    ~ uncounted++
    ~ heat(2)
    VAPE: appreciate you
    He went straight to the bar.
    FATHER: You put him out and let him back in. Now he knows what your out is worth.
- -> d_opts


// ------------------------------------------------------------------ the three who came in the back

=== ev_deck_kids ===
~ deck_kids_seen = true
~ here = floor
The kid in the hoodie was standing by the jukebox.
The kid he'd turned away at the door with the photo of his ID. His sister was at the rail by the pool table with her car keys in her fist, and the boyfriend was at the bar trying to get served. None of them had come past the stool. Their sneakers had left dark prints on the carpet from the back of the room.
FATHER: The deck. You knew about the coaster.
MANUAL: Three persons on the premises who were not admitted. One refused entry. One with no identification presented.
- (dk)
* [Talk to the sister first.]
    ~ pass(3)
    ~ fam += sister_met
    ~ knows += kid_why
    ~ knows += bigman_dad
    ~ knows += truck
    #portrait: driver
    She didn't wait for him to start.
    DRIVER: We're not here to drink. Our dad's at the pool table. Our mom's in the hospital since this morning and he won't answer his phone.
    DRIVER: You wouldn't let my brother in. So.
    // HUTCH: The family came in the back after the door said no. What does she say to the doorman who turned her brother away?
    -> dk
* [Put all three of them out.]
    ~ pass(4)
    ~ fam += sister_met
    ~ fam += kids_waiting
    ~ room_count -= kids_in
    ~ kids_in = 0
    ~ rep(rep_kids, -2)
    He walked them to the front door, the three of them, and none of them argued. The sister went last. At the door she stopped.
    DRIVER: Our mom's in the hospital. He doesn't know. That's all this is.
    ~ knows += kid_why
    ~ knows += bigman_dad
    * * ["Then I'll tell him."]
        ~ fam += sister_fetched
        # task: fetch :: Tell the big man at the pool table about his wife.
        DRIVER: Okay.
        She said it the way you say it when you've stopped expecting anything and something happens anyway.
    * * ["Wait in the truck."]
        DRIVER: We've been waiting in the truck.
    - - They went back across the lot. The pickup didn't leave.
    -> hub
* ["You came in the back. Fine. Now you're counted."]
    ~ pass(3)
    ~ fam += sister_met
    ~ fam += sister_admitted
    ~ fam += hoodie_admitted
    ~ count_in += kids_in
    ~ rep(rep_kids, 2)
    He clicked the clicker three times, standing there in the middle of the room, and the kid in the hoodie looked at him for almost a whole second. #sfx: clicker
    MANUAL: For the record, one of them has no identification.
    FIGHTER: Watch the boyfriend.
    -> hub
* [Leave them. Watch.]
    ~ pass(1)
    ~ fam += sister_met
    ~ fam += sister_admitted
    ~ fam += hoodie_admitted
    He went back to where he could see the pool table and the jukebox and the bar all at once, and watched.
    FIGHTER: The boyfriend. It'll be the boyfriend.
    -> hub
* {knows ? kid_why} ["I'll tell him for you."]
    ~ pass(1)
    ~ fam += sister_admitted
    ~ fam += hoodie_admitted
    ~ fam += sister_fetched
    # task: fetch :: Tell the big man at the pool table about his wife.
    DRIVER: He'll say he's coming after.
    DRIVER: He always says after.
    -> hub


// ------------------------------------------------------------------ the pickup in the lot

=== at_lot ===
~ here = lot
{ due(): -> hub }
# amb: rain_lot
He went out across the gravel to the pickup at the edge of the lot with the rain going down his collar. The engine was running. The windows had fogged from the inside, except for a clear patch the size of a hand on the driver's side.
The window came down four inches. #portrait: driver
DRIVER: What.
{ kids_in > 0 && fam ? hoodie_admitted:
    DRIVER: Is my brother okay?
}
- (lt)
* {knows !? kid_why} ["What do you need to tell him?"]
    ~ pass(2)
    DRIVER: Our mom's in the hospital. Since this morning. He's not answering.
    DRIVER: He never answers when he's in there.
    ~ knows += kid_why
    ~ knows += bigman_dad
    -> lt
* {fam !? sister_fetched} ["I'll tell him. I'll send him out."]
    ~ pass(1)
    ~ fam += sister_fetched
    # task: fetch :: Tell the big man at the pool table his family's waiting in the lot.
    DRIVER: He won't come.
    DRIVER: But okay.
    -> lt
* ["Come in. Just you. Bring him out."]
    ~ pass(2)
    ~ fam -= kids_waiting
    ~ fam += sister_admitted
    ~ kids_in++
    ~ count_in++
    ~ room_count++
    ~ rep(rep_kids, 2)
    She turned the engine off. It was the first time it had been off all night. #sfx: clicker
    { fam ? sister_refused:
        -> you_said_no
    }
    -> goes_in
* {fam !? vape_ejected} [Look in the back seat.]
    ~ pass(1)
    The boyfriend was lying across the back seat with his hood over his face and the vape on his chest, going up and down with his breathing.
    VAPE: i'm sleeping
    -> lt
+ [Go back in.]
    ~ pass(2)
    DRIVER: We'll be here.
    -> hub

= you_said_no
DRIVER: You said no.
* ["I was wrong."]
    She looked at him to see if he meant it.
    ~ rep(rep_kids, 1)
* ["I'm saying yes now."]
- -> goes_in

= goes_in
She went in past him, into the room, and straight to the pool table.
~ heat(1)
-> hub


// ------------------------------------------------------------------ put out the front, back in the back

=== ev_vape_back ===
~ vape_seen = true
~ here = floor
The boyfriend was at the bar again, dripping, with his hood up, trying to get served. He hadn't come past the stool. There were wet sneaker prints on the carpet from the deck door.
FIGHTER: The ones you put out the front come in the back. Every time.
FATHER: You left the coaster in.
* [Put him out again, and pull the coaster this time.]
    ~ pass(4)
    ~ fam += vape_ejected
    ~ vape_out_at = clock
    ~ kids_in--
    ~ room_count--
    ~ deck_door = false
    He walked him out the front again, the same way, the same length of the room, and this time the boyfriend didn't talk. Then he went to the deck door and pulled the folded coaster out of the latch and let it lock. #sfx: door
    ~ rep(rep_t28, -1)
    FATHER: Now they come past you or they don't come.
* [Put him out again.]
    ~ pass(3)
    ~ fam += vape_ejected
    ~ vape_out_at = clock
    ~ vape_returned = false
    ~ kids_in--
    ~ room_count--
    He walked him out the front again. The boyfriend laughed the whole way, as if they both knew how this went. #sfx: door
* [Leave him. He's back. Watch him.]
    ~ pass(1)
    ~ heat(1)
    The bartender served him. She looked at the doorman while she did it.
    ~ rep(rep_staff, -1)
- -> hub
