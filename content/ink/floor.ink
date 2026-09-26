// The floor: where he stands when he isn't anywhere else. Every choice here costs time,
// and the events waiting in sim.ink get their turn first.

=== hub ===
~ temp from = here
~ here = floor
{ from != floor && due():
    { back_line(from) }
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
+ {knows ? keg_hole || parley > 0 || knows ? endbar_seen} [Go down to the keg room. #loc: keg]
    ~ pass(2)
    -> at_keg
+ [{deck_label()} #loc: deck]
    ~ pass(1)
    -> at_deck
+ {fam ? kids_waiting && not fam_done} [Go out to the pickup in the lot. #loc: lot]
    ~ pass(2)
    -> at_lot

// When something is about to happen on the floor, say he's back on it first.
=== function back_line(from)
{ from:
- door: He left the door.
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
- kids_in > 0 && not fam_done && fam ? hoodie_admitted && fam !? kid_opened:
    {stopping:
    - The kid in the hoodie was by the jukebox, not playing it.
    - The kid was still by the jukebox.
    - The kid had moved to the other side of the jukebox. That was all.
    -
    }
}
{ arrivals ? banned_in && fam !? pool_fight:
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
~ return "Stand the door."

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

// A tunnel, so the prologue can use it too.
=== count_body ===
{shuffle:
- He put his back to the wall by the door, where he could see the whole room.
- He went and stood by the post at the end of the bar, where he could see all of it.
- He stood where he could see the whole room and let it come to him.
}
- (opts)
* [Heads.]
    ~ pass(3)
    ~ last_count = clock
    He counted from the door clockwise, the way the Father had taught him, and didn't count anyone twice. He got {num(room_count)}.
    { uncounted > 0:
        The clicker, plus the thirteen who'd been here when he came on, less the ones he'd seen go, said {num(room_count - uncounted)}. {uncounted == 1:One more in the room than had come past him.|{Num(uncounted)} more in the room than had come past him.}
        FATHER: That's how you find out what the room thinks of your door.
    - else:
        The clicker, plus the thirteen who'd been here when he came on, less the ones he'd seen go, said the same. It matched.
        MANUAL: Occupancy is within the licensed maximum. Occupancy is far within the licensed maximum. It's Wednesday.
    }
    -> opts
* [Faces.]
    ~ pass(8)
    ~ last_count = clock
    ~ knows += endbar_seen
    He went face by face. It's slower. It's the only count that tells you anything.
    Table 28: five, in the same seats they'd been in since two o'clock, by the look of the glasses. One in a team jacket, one with a hearing aid, one scratching lottery tickets, a quiet one in a cardigan, one in big glasses.
    The big man at the pool table and his buddy. {slippers_upstairs:One of the women in slippers, the one who'd stayed with the bottle.|The two women in slippers, hotel residents, the wine bottle lower.} {kids_in > 0:The kid by the jukebox with his hood up.} {fam ? sister_admitted:His sister, at the rail by the pool table, not playing.} {arrivals ? hivis_in || arrivals ? hivis_hotel:HI-VIS at the bar.} {arrivals ? banned_in || arrivals ? banned_inside:GOOD SHOES, at the bar, pleasant.}
    And the old man at the end of the bar, by the trapdoor, with the same full glass.
    { at_bar == 0:
        He hadn't seen him come in. He hadn't seen anyone let him in.
    }
    WRONGMAN: Count the one you didn't count. That's who it always is.
    -> opts
* [The doors.]
    ~ pass(6)
    -> doors ->
    -> opts
* [Hands. #check: fighter 7]
    ~ pass(4)
    ~ last_count = clock
    { passed:
        ~ knows += pool_lefty
        FIGHTER: The big man at the pool table's a lefty. Every time he misses, the left hand goes flat on the rail and stays there. That's where it'll come from, if it comes.
        { kids_in >= 2 && fam ? sister_admitted:
            FIGHTER: The boyfriend's hands won't stay still. He keeps touching his own face. He's working himself up to something.
        }
    - else:
        FIGHTER: Everybody's got two.
        He didn't see anything. That was either good news or the Fighter was drunk on a memory.
    }
    -> opts
* (count_glasses) [Glasses. #check: manual 7]
    ~ pass(4)
    { passed:
        MANUAL: Table 28 are on round {t28_rounds} since two o'clock. By any written standard, all five are intoxicated. By any written standard, you should refuse them service.
        MANUAL: The big man at the pool table is drinking doubles and pouring them into a pint of cola so they look like one drink.
        ~ knows += pool_hustle
        FATHER: The Manual's right about table 28 and it doesn't matter. Nobody cuts off table 28. You'll see.
    - else:
        MANUAL: Everyone is drinking. That is the purpose of the premises.
    }
    -> opts
+ [That's enough counting.]
    ->->

// Walking the doors. The loose rule: they're locked at night, mostly.
=== doors ===
He walked the doors.
{ deck_door:
    The deck door had a folded coaster wedged in the latch. Cold air came through the gap, and cigarette smoke.
    ~ knows += coaster
}
{ kitchen_door && here != kitchen:
    Through the kitchen pass, he could see the back door propped open with a milk crate. Steam went out; the rain didn't come in, much.
    ~ knows += kitchen_gap
}
{ hotel_door:
    At the end of the back hall, the door to the hotel stairs had a wooden wedge under it.
    ~ knows += hotel_gap
}
{ not deck_door && not kitchen_door && not hotel_door:
    All three were shut. For now.
}
- (d)
* {deck_door} [Pull the coaster out of the deck door.]
    ~ pass(1)
    ~ deck_door = false
    He pulled it out. The door clicked shut and locked. Out on the deck, one of the smokers watched him do it through the glass.
    FATHER: Now they come past you or they don't come.
    ~ rep(rep_t28, -1)
    -> d
* {kitchen_door} [Shut the kitchen door.]
    ~ pass(2)
    -> kitchen_door_shut ->
    -> d
* {hotel_door} [Kick the wedge out from under the hotel door.]
    ~ pass(1)
    ~ hotel_door = false
    He kicked the wedge out. The door eased shut on its closer and latched.
    MANUAL: Access between the licensed premises and the residential floors should be controlled.
    WRONGMAN: The night clerk will prop it again the minute you're gone. That's the story of every door.
    -> d
+ [Leave them.]
    ->->

=== kitchen_door_shut ===
~ kitchen_door = false
~ rep(rep_cook, -1)
He went through the kitchen and took the milk crate out of the back door. It shut.
COOK: Are you serious.
The cook was sweating through his shirt. The fryer ticked.
COOK: It's a hundred and ten in here.
FATHER: He'll open it again.
->->
