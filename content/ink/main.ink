// THE BOUNCER — Day 1: Wednesday, the test shift.
//
// Everything the world remembers lives in the VARs and LISTs below. The engine
// (prototype/web/src/core/game.js) reads a few of them, owns the voices in his head,
// and rolls the checks. Conventions are in content/ink/README.md.
//
// Status: this is Claude's first full draft of Wednesday. Hutch has final cut.
// Every `// HUTCH:` comment is a writing prompt; they're collected in content/WRITING_PROMPTS.md.

INCLUDE sim.ink
INCLUDE prologue.ink
INCLUDE door.ink
INCLUDE floor.ink
INCLUDE table28.ink
INCLUDE pool.ink
INCLUDE bar.ink
INCLUDE rats.ink
INCLUDE hall.ink
INCLUDE deck.ink
INCLUDE closing.ink
INCLUDE toys.ink

-> prologue


// ------------------------------------------------------------------ time and place

VAR day = 1
VAR clock = 1180            // minutes since the midnight before the shift: 1180 is 7:40 pm
CONST OPEN_TIME = 1180
CONST LAST_CALL = 1530      // 1:30 am
CONST CLOSE_TIME = 1560     // 2:00 am

LIST where = floor, door, bar, t28, pool, hall, kitchen, keg, deck, lot, upstairs
VAR here = floor

// ------------------------------------------------------------------ read by the engine

VAR passed = false          // the last check: set by the engine when a check choice is picked
VAR crit = 0                // 1 on double six, -1 on double one
VAR cash = 40               // dollars in his pocket. He came with forty.
VAR drinks = 0              // drinks in him tonight
VAR hurt = 0                // 0 fine, 1 knocked about, 2 hurt, 3 badly hurt
VAR count_in = 0            // the clicker: everyone he clicked in
VAR fidget = 0              // clicks on the clicker that weren't anybody (the player, playing with it: toys.ink)
VAR zeroed = 0              // what the clicker said when the knob on its side was last turned back to nothing

// ------------------------------------------------------------------ the doors

VAR door_away = 0           // minutes the main door has gone unwatched
VAR walk_ins = 0            // people who drifted in while he was away from the door
VAR walk_ins_seen = 0       // how many of them he's seen the signs of, back at the door
VAR uncounted = 0           // people inside who never passed his clicker
VAR room_count = 13         // how many are actually in the building's bar
VAR deck_door = true        // propped open with a folded coaster
VAR kitchen_door = true     // propped by the cook for air
VAR hotel_door = true       // propped by the night clerk

// ------------------------------------------------------------------ the room

VAR pool_heat = 1           // 0 calm ... 10 violence
VAR pool_mins = 0
VAR t28_rounds = 3          // they've been here since two
VAR last_count = 0          // the clock when he last counted the room
VAR last_room_line = 0      // the clock when the floor last got a line about the room

// ------------------------------------------------------------------ standing, by code
// Each group judges him by its own code (bible/02_SYSTEMS.md). -5 .. +5. Nobody sees these.

VAR rep_t28 = 0             // table 28: loyalty, generosity, we were here first
VAR rep_kids = 0            // the kids: don't be fake, don't be a rat
VAR rep_staff = 0           // the bartender: have each other's backs
VAR rep_owner = 0           // the owner: money
VAR rep_cook = 0            // the cook: don't make my night worse

// ------------------------------------------------------------------ what he knows

LIST knows = eighty_six, coaster, kid_photo, kitchen_gap, hotel_gap, the_note, t28_rat, walter_name, pool_lefty, pool_hustle, bigman_dad, kid_legal, kid_why, truck, endbar_seen, endbar_invite, keg_hole, dennis, hivis_room, banned_face, knot_seen, old_doorman

// ------------------------------------------------------------------ the family at the pool table (draft storyline)

LIST fam = hoodie_refused, hoodie_admitted, hoodie_conditions, sister_met, sister_refused, sister_admitted, sister_fetched, via_deck, kid_found, kid_opened, dad_told, dad_went, dad_stayed, dad_ejected, dad_drove, vape_ejected, pool_fight, lot_scene, kids_waiting, hoodie_rapport
VAR kids_in = 0             // how many of the three are inside
VAR fam_done = false
VAR vape_out_at = 0         // when the boyfriend was put out
VAR vape_returned = false   // he came back in through the deck
VAR vape_seen = false
VAR kid_out = false         // the kid has come out of the single washroom
VAR deck_kids_seen = false  // he's found the three who came in the back
VAR door_reads = 0          // how many reads he's taken of the kid at the door
VAR father_misread = false  // the Father read the kid as high at the door. He'd been awake two days.
VAR family_in_lot = false   // at close, his kids were there in the lot
VAR took_keys = false

// ------------------------------------------------------------------ the other arrivals

LIST arrivals = hivis_done, hivis_in, hivis_out, hivis_cond, hivis_hotel, banned_done, banned_in, banned_out, banned_inside, wife_done, wife_in, wife_lied, wife_told, wife_inside
VAR banned_stage = 0

// ------------------------------------------------------------------ rats

LIST rat_way = undecided, war, truce, ignored, hostile
VAR rats = undecided
VAR rat_count = 30          // a guess. Ignored, they double.
VAR poison = false
VAR traps = false
VAR walter = 1              // table 28's rat: 1 alive, 0 dead, 3 he's eaten the bait (anticoagulant: days, not hours)
VAR rat_scene = false       // the rat on the carpet has happened
VAR parley = 0              // 0 never, 1 talked terms, 2 made a deal
VAR terms_door = true       // the terms include the kitchen door on the latch
VAR poison_at = ()          // where he put the bait (keg, kitchen, t28)
VAR trap_at = ()            // where he set the traps
VAR poison_laid = 0         // the clock when he put it down
VAR traps_set = 0
VAR trap_sprung = false     // the trap under table 28 has gone off
VAR rat_favour = 0          // courtesies: food on the step, one given back
VAR rats_killed = 0
VAR fries = 0               // 0 none, 1 carrying a basket from the kitchen, 2 given away
VAR fries_step = 0          // the clock when he left them on the third step
VAR slippers_upstairs = false

// ------------------------------------------------------------------ incidents, and the log he writes

LIST incident = inc_kid_refused, inc_deck, inc_banned, inc_rat, inc_fight, inc_hivis, inc_wife, inc_lot, inc_drinking, inc_poison, inc_hurt, inc_drugs, inc_after
VAR logged = ()
VAR shaded = ()
VAR left_out = ()
VAR cocoon = 0              // the hidden measure: whether he lies to himself (bible/02_SYSTEMS.md). Never shown.

// ------------------------------------------------------------------ his past, as he tells it
// What he invents becomes fact, and people compare notes (bible/02_SYSTEMS.md).

LIST claim = said_up_island, said_city_door, said_around, said_father, said_left_bad_owner, said_left_something, said_left_long_story, said_nothing
VAR claims = ()
VAR father_named = false

// ------------------------------------------------------------------ voices trying to get in

VAR pull_table = 0          // time and drinks with table 28
VAR pull_kid = 0            // real talk with the kid
VAR new_voice = ""
VAR cardigan_go = 0         // he told the one in the cardigan to go to Calgary (1) or to stay (-1)

// ------------------------------------------------------------------ the end of the night

VAR owner_lie = false       // he told the owner the rats were handled
VAR police_called = false    // the bartender called it in after the fight
VAR verdict = 0             // what the bartender tells the owner: 2 he'll do, 1 he showed up, -1 what she saw
LIST cleared = cl_pool, cl_banned, cl_hivis, cl_res, cl_t28
VAR two_called = false


// ------------------------------------------------------------------ the engine

// The voices in his head are the engine's (content/data/voices.yaml).
EXTERNAL seated(voice)          // is this voice in the room?
EXTERNAL seat(voice)            // let a voice in (fails if the room is full)
EXTERNAL unseat(voice)          // bounce a voice out
EXTERNAL learn(voice)           // he has the voice, in the room or not
EXTERNAL bond(a, b, sign)       // two voices become allied (1) or at odds (-1)
EXTERNAL tension()              // 0 quiet ... 4 a riot
EXTERNAL seats_free()
// What a group is saying about him by now, from content/rules/word.yaml ("" if nothing yet).
EXTERNAL last_word(group)

// Fallbacks so the story also runs in Inky, where there's no engine.
=== function seated(voice)
~ return voice == "father" || voice == "fighter" || voice == "manual" || voice == "wrongman"
=== function seat(voice)
~ return true
=== function unseat(voice)
~ return true
=== function learn(voice)
~ return true
=== function bond(a, b, sign)
~ return true
=== function tension()
~ return 1
=== function seats_free()
~ return 1
=== function last_word(group)
~ return ""
