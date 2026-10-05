// The floor: where he stands when he isn't anywhere else. Every choice here costs time,
// and the events waiting in sim.ink get their turn first.

=== hub ===
~ temp from = here
~ here = floor
{ from != floor && due():
    { back_line(from, ev_ready()) }
}
-> events ->
{ clock >= LAST_CALL: -> last_call }
{ room_line() }
+ [{door_label()} #loc: door]
    ~ pass(1)
    -> at_door
+ [{count_label()} #loc: floor]
    -> count_room
+ [{t28_label()} #loc: t28]
    ~ pass(1)
    -> at_t28
+ [{pool_label()} #loc: pool]
    ~ pass(1)
    -> at_pool
+ [{bar_label()} #loc: bar]
    ~ pass(1)
    -> at_bar
+ [{hall_label()} #loc: hall]
    ~ pass(1)
    -> at_hall
+ [{kitchen_label()} #loc: kitchen]
    ~ pass(1)
    -> at_kitchen
+ {knows ? keg_hole || knows ? bait_office || parley > 0 || knows ? endbar_seen} [Go down to the keg room. #loc: keg]
    ~ pass(2)
    -> at_keg
+ [{deck_label()} #loc: deck]
    ~ pass(1)
    -> at_deck
+ {fam ? kids_waiting && not fam_done && not truck_gone} [Go out to the pickup in the lot. #loc: lot]
    ~ pass(2)
    -> at_lot

// ------------------------------------------------------------------ straight on

// The ways out of a place, straight to the next one, instead of back to the floor to choose again.
// Each costs what going by the floor did: the step back onto it and the walk over (and the stairs,
// up from the keg room). The page shows them under what there is to do in a place, as the ways
// out (#class: move). Whatever's waiting on the floor still gets its turn first.
=== moves(from) ===
+ [The floor #loc: floor #class: move]
    ~ pass(1 + stairs(from))
    -> hub
+ {from != door} [{door_away >= 30:Back on the door|The door} #loc: door #class: move]
    -> walk(from, -> at_door, 2)
+ [Count the room #class: move]
    -> walk(from, -> count_room, 1)
+ {from != t28} [Table 28 #loc: t28 #class: move]
    -> walk(from, -> at_t28, 2)
+ {from != pool} [The pool table #loc: pool #class: move]
    -> walk(from, -> at_pool, 2)
+ {from != bar} [The bar #loc: bar #class: move]
    -> walk(from, -> at_bar, 2)
+ {from != hall} [The back hall #loc: hall #class: move]
    -> walk(from, -> at_hall, 2)
+ {from != kitchen} [The kitchen #loc: kitchen #class: move]
    -> walk(from, -> at_kitchen, 2)
+ {from != keg && (knows ? keg_hole || knows ? bait_office || parley > 0 || knows ? endbar_seen)} [The keg room #loc: keg #class: move]
    -> walk(from, -> at_keg, 3)
+ {from != deck} [The deck #loc: deck #class: move]
    -> walk(from, -> at_deck, 2)
+ {fam ? kids_waiting && not fam_done && not truck_gone} [The pickup in the lot #loc: lot #class: move]
    -> walk(from, -> at_lot, 3)
- -> DONE

=== walk(from, -> to, m) ===
~ pass(m + stairs(from))
{ due(): -> hub }
-> to

=== function stairs(from)
{ from == keg:
    ~ return 1
}
~ return 0

// When something is about to happen on the floor, say he's back on it first.
// From the door: the sister and the constable come to it, so there's nothing to leave; the ones
// who walked in while he was away got past an empty stool; anything else, he turns round to.
=== function back_line(from, e)
{ from:
- door:
    {
    - e == "sister" || e == "police":
        ~ return
    - e == "wife" || e == "banned":
        He was on his way back to the stool.
    - else:
        He turned round on the stool.
    }
- bar: He stepped away from the bar.
- t28: He left table 28 to it.
- pool: He left the pool table.
- hall: He came back up the hall.
- kitchen: He came out through the kitchen.
- keg: He came up out of the keg room and let the trapdoor down.
- deck: He came in off the deck.
- lot: He came back in from the lot, wet.
}

// The room, every half hour or so. Not every time he turns around.
=== function room_line()
{ last_room_line > 0 && clock - last_room_line < 25:
    ~ return
}
~ last_room_line = clock
{
- clock < 1260:
    {shuffle:
    - Early. The TV on mute, the pool table clicking, table 28 loud about nothing in particular.
    - The jukebox between songs. Somebody at table 28 telling a story everyone at the table already knew the end of.
    - Rain on the front window. The ice machine. Wednesday.
    }
- clock < 1380:
    {shuffle:
    - The hockey had started. Table 28 had opinions about the refereeing, all of them the same opinion.
    - Glasses on the bar, the till drawer, the TV. A slow night filling up slowly.
    - Somebody had put money in the jukebox and picked the same song twice.
    }
- clock < LAST_CALL:
    {shuffle:
    - Late. The room had gone warm and loud the way it does, and the carpet had started to stick.
    - Table 28 were {num(t28_rounds)} rounds in and sounded it.
    - The same four songs again. The TV showing highlights of the game everybody had just watched.
    }
}
{ pool_heat >= 5 && fam !? pool_fight && not fam_done:
    Voices at the pool table, over the music. Not words yet.
}
{
- kid_locked_in():
    {stopping:
    - The single washroom in the back hall had been locked for a while now.
    - The single washroom was still locked.
    }
- kid_at == s_jukebox && not fam_done && fam !? kid_opened:
    {stopping:
    - The kid in the hoodie was by the jukebox, not playing it.
    - The kid was still by the jukebox.
    - The kid had moved to the other side of the jukebox. That was all.
    -
    }
}
{ vape_at == s_bar && not fam_done:
    {stopping:
    - The boyfriend was at the bar with his hood up, trying to catch the bartender's eye and not catching it.
    - The boyfriend, at the bar, on his phone, laughing at it.
    -
    }
}
{ arrivals ? banned_in && arrivals !? banned_out && fam !? pool_fight:
    {stopping:
    - GOOD SHOES was at the bar on another drink, pleasant to everyone.
    - GOOD SHOES was still at the bar.
    -
    }
}

=== function door_label()
{ door_away >= 60:
    ~ return "Get back on the door. It's been an hour."
}
{ door_away >= 30:
    ~ return "Get back on the door."
}
~ return "Stand at the door."

=== function count_label()
{ last_count == 0:
    ~ return "Count the room."
}
{ clock - last_count >= 90:
    ~ return "Count the room again. It's been a while."
}
~ return "Count the room."

=== function t28_label()
{ at_t28 == 0:
    ~ return "Table 28."
}
~ return "Go over to table 28."

=== function pool_label()
{ pool_heat >= 6 && not fam_done:
    ~ return "The pool table. It's getting loud."
}
~ return "Watch the pool table."

=== function bar_label()
{ at_bar == 0:
    ~ return "Talk to the bartender."
}
~ return "The bar."

=== function hall_label()
{ at_hall == 0:
    ~ return "Check the bathrooms."
}
~ return "Bathroom check."

=== function kitchen_label()
{ knows !? kitchen_gap:
    ~ return "The kitchen."
}
~ return "The kitchen, about the rats."

=== function deck_label()
{ at_deck == 0:
    ~ return "Out on the smoking deck."
}
~ return "The deck."


// ------------------------------------------------------------------ counting the room

=== count_room ===
~ here = floor
-> count_body ->
-> hub

// A tunnel, so the prologue can use it too. Heads, faces and the doors can be done again on every
// count, because the room changes; the two checks can't, because a second look doesn't see more.
=== count_body ===
~ temp did_heads = false
~ temp did_faces = false
~ temp did_doors = false
// A count is a look at the room, so the floor doesn't need to describe it again straight after.
~ last_room_line = clock
{shuffle:
- He put his back to the wall by the door, where he could see the whole room.
- He went and stood by the post at the end of the bar, where he could see all of it.
- He stood where he could see the whole room and let it come to him.
}
- (opts)
+ {not did_heads} [Heads.]
    ~ did_heads = true
    ~ pass(3)
    ~ last_count = clock
    // what it should be: the thirteen, and everyone he let in, less everyone he saw go
    ~ temp says = room_count - uncounted
    He counted from the door clockwise, the way the Father had taught him, and didn't count anyone twice. He got {num(room_count)}.
    {
    - says < room_count:
        The thirteen who'd been here when he came on, and the ones he'd let in, less the ones he'd seen go, made {num(says)}. {room_count - says == 1:One more in the room than had come past him.|{Num(room_count - says)} more in the room than had come past him.}
        FATHER: That's how you find out what the room thinks of your door.
    - else:
        The thirteen who'd been here when he came on, and the ones he'd let in, less the ones he'd seen go: the same. Everybody in the room had come past him.
        MANUAL: Occupancy is within the licensed maximum. Occupancy is far within the licensed maximum. It's Wednesday.
    }
    -> opts
+ {not did_faces} [Faces.]
    ~ did_faces = true
    ~ pass(8)
    ~ last_count = clock
    ~ knows += endbar_seen
    He went face by face. It's slower. It's the only count that tells you anything.
    Table 28: {dennis_gone():four, and the chair where Dennis had been with nobody in it|five}, in the same seats they'd been in since two o'clock, by the look of the glasses. One in a team jacket, one with a hearing aid, one scratching lottery tickets, a quiet one in a cardigan{not dennis_gone():, one in big glasses}.
    {pool_still():The big man at the pool table and his buddy.|Nobody at the pool table now.} {slippers_upstairs:One of the women in slippers, the one who'd stayed with the bottle.|The two women in slippers, hotel residents, the wine bottle lower.} {kid_at == s_jukebox:The kid by the jukebox with his hood up.}{kid_at == s_single:Not the kid. The single washroom in the back hall was locked.} {sister_at == s_rail:His sister, at the rail by the pool table, not playing.} {vape_at == s_bar:The boyfriend at the bar, working on a ninth.} {arrivals ? hivis_in || arrivals ? hivis_hotel:HI-VIS at the bar.} {(arrivals ? banned_in || arrivals ? banned_inside) && arrivals !? banned_out:GOOD SHOES, at the bar, pleasant.}
    And the old man at the end of the bar, by the trapdoor, with the same full glass.
    { at_bar == 0:
        He hadn't seen him come in. He hadn't seen anyone let him in.
    }
    WRONGMAN: Count the one you didn't count. That's who it always is.
    -> opts
+ {not did_doors} [The doors.]
    ~ did_doors = true
    ~ pass(6)
    -> doors ->
    -> opts
* [Hands. #check: fighter 7]
    ~ pass(4)
    ~ last_count = clock
    { passed:
        { pool_still():
            ~ knows += pool_lefty
            FIGHTER: The big man at the pool table's a lefty. Every time he misses, the left hand goes flat on the rail and stays there. That's where it'll come from, if it comes.
        }
        { indoors(vape_at) && not fam_done:
            ~ knows += vape_read
            ~ knows -= vape_misread
            FIGHTER: The boyfriend's hands won't stay still. He keeps touching his own face. He's working himself up to something.
        }
        { not pool_still() && not (indoors(vape_at) && not fam_done):
            FIGHTER: Nobody in here tonight with anything in their hands but a glass.
        }
    - else:
        FIGHTER: Everybody's got two.
        He didn't see anything. That was either good news or the Fighter was drunk on a memory.
    }
    -> opts
* (count_glasses) [Glasses. #check: manual 7]
    ~ pass(4)
    ~ last_count = clock
    { passed:
        MANUAL: Table 28 are on round {t28_rounds} since two o'clock. By any written standard, all {dennis_gone():four|five} are intoxicated. By any written standard, you should refuse them service.
        { pool_still():
            MANUAL: The big man at the pool table is drinking doubles and pouring them into a pint of cola so they look like one drink.
            ~ knows += pool_hustle
        }
        FATHER: The Manual's right about table 28 and it doesn't matter. Nobody cuts off table 28. You'll see.
    - else:
        MANUAL: Everyone is drinking. That is the purpose of the premises.
    }
    -> opts
+ [That's enough counting.]
    ->->

// Walking the doors. The loose rule: they're locked at night, mostly. The cook and the night clerk
// open theirs again behind him (sim.ink), and this is where he finds out they have.
=== doors ===
He walked the doors.
{ deck_door:
    The deck door had a folded coaster wedged in the latch. Cold air came through the gap, and cigarette smoke.
    ~ knows += coaster
}
{ kitchen_door && here != kitchen:
    { reprops ? rp_kitchen:
        Through the kitchen pass, the back door was propped with the milk crate again. Somebody had put it back.
        ~ reprops -= rp_kitchen
    - else:
        Through the kitchen pass, he could see the back door propped open with a milk crate. Steam went out; the rain didn't come in, much.
    }
    ~ knows += kitchen_gap
}
{ hotel_door:
    { reprops ? rp_hotel:
        At the end of the back hall the wedge was back under the hotel door. He hadn't heard anybody put it there.
        ~ reprops -= rp_hotel
    - else:
        At the end of the back hall, the door to the hotel stairs had a wooden wedge under it.
    }
    ~ knows += hotel_gap
}
{ not deck_door && not kitchen_door && not hotel_door:
    All three were shut. For now.
}
- (d)
+ {deck_door} [Pull the coaster out of the deck door.]
    ~ pass(1)
    ~ deck_door = false
    He pulled it out. The door clicked shut and locked. Out on the deck, one of the smokers watched him do it through the glass.
    FATHER: Now they come past you or they don't come.
    ~ rep(rep_t28, -1)
    -> d
+ {kitchen_door} [Shut the kitchen door.]
    ~ pass(2)
    -> kitchen_door_shut ->
    -> d
+ {hotel_door} [Kick the wedge out from under the hotel door.]
    ~ pass(1)
    ~ hotel_door = false
    ~ hotel_shut_at = clock
    He kicked the wedge out. The door eased shut on its closer and latched.
    MANUAL: Access between the licensed premises and the residential floors should be controlled.
    WRONGMAN: The night clerk will prop it again the minute you're gone. That's the story of every door.
    -> d
// Leaving them is a choice too: whatever comes through one he looked at and left, the night says so.
+ [Leave them.]
    { deck_door:
        ~ doors_left += left_deck
    }
    { kitchen_door:
        ~ doors_left += left_kitchen
    }
    { hotel_door:
        ~ doors_left += left_hotel
    }
    ->->

// Shutting the cook's back door. He opens it again twenty minutes later while he's on (sim.ink).
=== kitchen_door_shut ===
~ kitchen_door = false
~ kitchen_shut_at = clock
{ not cook_here():
    He went through the dark kitchen and took the milk crate out of the back door, and it shut, and he checked it twice.
    ->->
}
~ rep(rep_cook, -1)
{ kitchen_door_shut == 1:
    He went through the kitchen and took the milk crate out of the back door. It shut.
    COOK: Hey. Hey! That door is my air, Security.
    The cook was sweating through his shirt. The fryer ticked.
    COOK: It's a hundred and ten on the line. A hundred and ten! It stays open or I cook.
    FATHER: He'll open it again.
- else:
    He took the milk crate out of the back door again, and it shut again.
    COOK: Every time I turn around! Every goddamn time!
    The cook didn't look up from the fryer. He didn't need to.
}
->->
