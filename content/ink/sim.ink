// The room keeps going when he isn't looking.
//
// Every action costs minutes, and pass() is the only thing that moves the clock. While he's
// away from the main door people drift in uncounted, the pool table heats up, table 28 keeps
// drinking, and anyone arriving at a door he isn't watching finds another way in. That is the
// precedence Hutch asked for: whatever he doesn't attend to happens without him.

=== function pass(m)
~ clock += m
{ here != door:
    ~ door_away += m
}

// People drift in while the main door is unwatched: one every 45 unwatched minutes after 8:30, four at most on a Wednesday.
// Not once the front door's locked for the night.
{ clock >= 1230 && walk_ins < 4 && door_away / 45 > walk_ins && not lock_up:
    ~ walk_ins++
    ~ uncounted++
    ~ room_count++
}

// Table 28 orders a round about every 45 minutes. They've been here since two.
~ t28_rounds = 3 + (clock - OPEN_TIME) / 45

// The pool table heats up after nine, twice as fast while the kids are in the room and nothing's settled.
{ clock >= 1260 && pool_heat < 10:
    ~ pool_mins += m
    ~ temp step = 45
    { kids_in > 0 && not fam_done:
        ~ step = 25
    }
    { pool_mins >= step:
        ~ pool_heat += pool_mins / step
        ~ pool_mins = pool_mins mod step
    }
    { pool_heat > 10:
        ~ pool_heat = 10
    }
}

// Turned away at the front, the kids try the deck, if it's still propped.
{ fam ? hoodie_refused && fam !? sister_met && fam !? via_deck && deck_door && clock >= 1240:
    ~ fam += via_deck
    ~ kids_in = 3
    ~ uncounted += 3
    ~ room_count += 3
    ~ incident += inc_deck
}

// Put out the front, the boyfriend comes back in the back, if the deck's still propped.
{ fam ? vape_ejected && deck_door && not fam_done && not vape_returned && clock >= vape_out_at + 30:
    ~ vape_returned = true
    ~ fam -= vape_ejected
    ~ kids_in++
    ~ uncounted++
    ~ room_count++
    ~ heat(2)
}

// Bait in the hole behind table 28: Walter finds it within the hour. It takes days after that.
{ poison_at ? t28 && walter == 1 && clock >= poison_laid + 45:
    ~ walter = 3
}

// HI-VIS was due at nine. Nobody at the door by 9:40, so he comes in through the hotel.
{ clock >= 1300 && arrivals !? hivis_done:
    ~ arrivals += hivis_done
    { hotel_door:
        ~ arrivals += hivis_hotel
        ~ uncounted++
        ~ room_count++
    - else:
        ~ arrivals += hivis_out
    }
}

// GOOD SHOES was due at 10:30. Nobody at the door by 10:50, so he's at the bar.
{ clock >= 1370 && arrivals !? banned_done:
    ~ arrivals += banned_done
    ~ arrivals += banned_inside
    ~ uncounted++
    ~ room_count++
    ~ incident += inc_banned
}

// RAINCOAT was due at 12:40. Nobody at the door by one, so she walks straight to table 28.
{ clock >= 1500 && arrivals !? wife_done:
    ~ arrivals += wife_done
    ~ arrivals += wife_inside
    ~ incident += inc_wife
}


// ------------------------------------------------------------------ small helpers

=== function rep(ref x, n)
~ x += n
{ x > 5:
    ~ x = 5
}
{ x < -5:
    ~ x = -5
}

// Numbers in the narration are written out. The incident log can use digits.
=== function num(n)
~ return num_cap(n, false)

// The same, for the start of a sentence.
=== function Num(n)
~ return num_cap(n, true)

=== function num_cap(n, cap)
{ n < 0:
    ~ return "minus " + num(0 - n)
}
{ n >= 100:
    ~ return "" + n
}
{ n < 20:
    ~ return small_num(n, cap)
}
~ temp word = tens_num(n / 10, cap)
{ n mod 10 > 0:
    ~ word = word + "-" + small_num(n mod 10, false)
}
~ return word

=== function cap_pick(cap, upper, lower)
{ cap:
    ~ return upper
}
~ return lower

=== function small_num(n, cap)
{ n:
- 0:
    ~ return cap_pick(cap, "Zero", "zero")
- 1:
    ~ return cap_pick(cap, "One", "one")
- 2:
    ~ return cap_pick(cap, "Two", "two")
- 3:
    ~ return cap_pick(cap, "Three", "three")
- 4:
    ~ return cap_pick(cap, "Four", "four")
- 5:
    ~ return cap_pick(cap, "Five", "five")
- 6:
    ~ return cap_pick(cap, "Six", "six")
- 7:
    ~ return cap_pick(cap, "Seven", "seven")
- 8:
    ~ return cap_pick(cap, "Eight", "eight")
- 9:
    ~ return cap_pick(cap, "Nine", "nine")
- 10:
    ~ return cap_pick(cap, "Ten", "ten")
- 11:
    ~ return cap_pick(cap, "Eleven", "eleven")
- 12:
    ~ return cap_pick(cap, "Twelve", "twelve")
- 13:
    ~ return cap_pick(cap, "Thirteen", "thirteen")
- 14:
    ~ return cap_pick(cap, "Fourteen", "fourteen")
- 15:
    ~ return cap_pick(cap, "Fifteen", "fifteen")
- 16:
    ~ return cap_pick(cap, "Sixteen", "sixteen")
- 17:
    ~ return cap_pick(cap, "Seventeen", "seventeen")
- 18:
    ~ return cap_pick(cap, "Eighteen", "eighteen")
- 19:
    ~ return cap_pick(cap, "Nineteen", "nineteen")
}
~ return "" + n

=== function tens_num(t, cap)
{ t:
- 2:
    ~ return cap_pick(cap, "Twenty", "twenty")
- 3:
    ~ return cap_pick(cap, "Thirty", "thirty")
- 4:
    ~ return cap_pick(cap, "Forty", "forty")
- 5:
    ~ return cap_pick(cap, "Fifty", "fifty")
- 6:
    ~ return cap_pick(cap, "Sixty", "sixty")
- 7:
    ~ return cap_pick(cap, "Seventy", "seventy")
- 8:
    ~ return cap_pick(cap, "Eighty", "eighty")
- 9:
    ~ return cap_pick(cap, "Ninety", "ninety")
}
~ return "" + (t * 10)

=== function walter_alive()
~ return walter == 1 || walter == 3

// Nudge the pool table's heat, and keep it between 0 and 10.
=== function heat(n)
~ pool_heat += n
{ pool_heat > 10:
    ~ pool_heat = 10
}
{ pool_heat < 0:
    ~ pool_heat = 0
}

=== function drink()
~ drinks++
{ here != upstairs && clock < CLOSE_TIME && drinks >= 2:
    ~ incident += inc_drinking
}

=== function tip(n)
~ cash += n

=== function clock_text()
~ temp m = clock mod 1440
~ temp h = m / 60
~ temp mm = m mod 60
~ temp h12 = h mod 12
{ h12 == 0:
    ~ h12 = 12
}
{h12}:{mm < 10:0}{mm} {h < 12:am|pm}

// Anything waiting to interrupt him? Location loops check this and go back to the floor.
=== function due()
~ return ev_ready() != "" || clock >= LAST_CALL

// Which forced event, if any, is ready. Order is priority.
=== function ev_ready()
{
- fam !? sister_met && fam !? via_deck && fam ? hoodie_refused && not fam_done && clock >= 1250:
    ~ return "sister"
- fam !? sister_met && (fam ? hoodie_admitted || fam ? hoodie_conditions) && not fam_done && clock >= 1300:
    ~ return "sister"
- fam ? via_deck && not deck_kids_seen && kids_in > 0 && not fam_done:
    ~ return "deckkids"
- arrivals ? banned_inside && banned_stage == 0:
    ~ return "banned"
- not fam_done && kids_in > 0 && pool_heat >= 7 && fam !? pool_fight:
    ~ return "pool"
- not fam_done && kids_in == 0 && pool_heat >= 9 && fam !? pool_fight:
    ~ return "pool"
- vape_returned && not vape_seen && not fam_done && kids_in > 0:
    ~ return "vapeback"
- trap_at ? t28 && walter_alive() && not trap_sprung && clock >= traps_set + 40:
    ~ return "trap"
- not rat_scene && clock >= 1290:
    ~ return "rat"
- clock >= 1215 && ev_card_done == false:
    ~ return "card"
- clock >= 1440 && ev_owner_done == false:
    ~ return "owner"
- arrivals ? wife_inside && arrivals !? wife_in && arrivals !? wife_told && arrivals !? wife_lied:
    ~ return "wife"
}
~ return ""

VAR ev_card_done = false
VAR ev_owner_done = false

// The interrupting events run from the floor, one at a time.
=== events ===
~ temp e = ev_ready()
{
- e == "sister": -> ev_sister ->
- e == "deckkids": -> ev_deck_kids ->
- e == "trap": -> ev_trap_t28 ->
- e == "vapeback": -> ev_vape_back ->
- e == "banned": -> ev_banned_inside ->
- e == "pool": -> ev_pool ->
- e == "rat": -> ev_rat ->
- e == "card": -> ev_card ->
- e == "owner": -> ev_owner ->
- e == "wife": -> ev_wife_inside ->
}
->->
