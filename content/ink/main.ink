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
INCLUDE things.ink

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
VAR count_in = 0            // everyone he let in past the stool

// ------------------------------------------------------------------ the doors

VAR door_away = 0           // minutes the main door has gone unwatched
VAR walk_ins = 0            // people who drifted in while he was away from the door
VAR walk_ins_seen = 0       // how many of them he's seen the signs of, back at the door
VAR uncounted = 0           // people inside who never came past him at the front door
VAR room_count = 13         // how many are actually in the building's bar
VAR deck_door = true        // propped open with a folded coaster
VAR kitchen_door = true     // propped by the cook for air
VAR hotel_door = true       // propped by the night clerk
VAR kitchen_shut_at = 0     // when he last shut the kitchen door: the cook opens it again while he's on (sim.ink)
VAR hotel_shut_at = 0       // when he last kicked the hotel door's wedge out: the night clerk puts it back
VAR terry_asked = false     // he asked the night clerk to leave the hotel door shut, and it stays shut
LIST reprop = rp_kitchen, rp_hotel
VAR reprops = ()            // doors somebody opened again behind him, till the next time he walks past one
LIST door_left = left_deck, left_kitchen, left_hotel
VAR doors_left = ()         // doors he walked, saw propped, and left that way (floor.ink): the night remembers

// ------------------------------------------------------------------ the room

VAR pool_heat = 1           // 0 calm ... 10 violence
VAR pool_mins = 0
VAR t28_rounds = 3          // they've been here since two
VAR last_count = 0          // the clock when he last counted the room
VAR last_room_line = 0      // the clock when the floor last got a line about the room
VAR juke_low = false        // the bartender turned the jukebox down a notch when he asked (pool.ink)

// ------------------------------------------------------------------ standing, by code
// Each group judges him by its own code (bible/02_SYSTEMS.md). -5 .. +5. Nobody sees these.

VAR rep_t28 = 0             // table 28: loyalty, generosity, we were here first
VAR rep_kids = 0            // the kids: don't be fake, don't be a rat
VAR rep_staff = 0           // the bartender: have each other's backs
VAR rep_owner = 0           // the owner: money
VAR rep_cook = 0            // the cook: don't make my night worse

// ------------------------------------------------------------------ what he knows

LIST knows = eighty_six, coaster, kid_photo, kitchen_gap, hotel_gap, the_note, t28_rat, walter_name, pool_lefty, pool_hustle, bigman_dad, kid_legal, kid_why, truck, endbar_seen, endbar_invite, keg_hole, dennis, hivis_room, banned_face, knot_seen, old_doorman, card_in_truck, vape_no_id, vape_read, vape_misread, vape_cans, hivis_upstairs, binder_hers, banned_story, ardagh, terry, transmission, bait_office, rat_numbers, cook_advice, cook_fries, office_seen, t28_nine, doorman_stories, aa_wall, endbar_dock, mill_closing, lost_jacket, juke_top, pool_seen

// ------------------------------------------------------------------ the family at the pool table (draft storyline)

LIST fam = hoodie_refused, hoodie_admitted, hoodie_conditions, sister_met, sister_refused, sister_admitted, sister_fetched, via_deck, kid_found, kid_opened, dad_told, dad_went, dad_stayed, dad_ejected, dad_drove, vape_ejected, pool_fight, lot_scene, kids_waiting, hoodie_rapport, earbuds_out, kid_kept_out, kid_home, dad_walked, all_out, told_wait, sister_gave_up
VAR kids_in = 0             // how many of the three are inside: kept by move() in sim.ink, from where they are
// Where each of the three is, exactly, so no line puts one of them somewhere they aren't (the
// pickup at the edge of the lot, being carded, waiting in the vestibule, by the jukebox, locked in
// the single washroom, at the rail by the pool table, at the bar, loose in the lot, or gone).
// move() keeps kids_in and room_count in step with it. godot/world/stage.gd stages them from it.
LIST spot = s_truck, s_door, s_vestibule, s_jukebox, s_single, s_rail, s_bar, s_lot, s_gone
VAR kid_at = s_truck
VAR sister_at = s_truck
VAR vape_at = s_truck
VAR truck_gone = false      // the pickup has left the lot
VAR sister_wait_at = 0      // when she started waiting in the vestibule for him to bring her father out
VAR gave_up_seen = false    // he's seen that she gave up waiting in the vestibule
VAR kid_ease = 0            // room he's given the kid (letting things go, leaving him be) less the times he pushed
VAR kid_terms = 0           // the conditions he let the kid in on: 1 no drinking, 2 where he can see him, 3 his sister comes in too
VAR phone_scans = 0         // times he held the kid's phone under the scanner
VAR vape_backs = 0          // times the boyfriend came back in the back after being put out the front
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
VAR bigman_ease = 0         // how the big man takes him: losing on purpose, small talk, letting him keep his dignity
VAR promised_bigman = false // the big man asked him to say he wasn't here, and he said he would (or let him think so)
VAR promise_kept = 0        // 1 he told the daughter her father wasn't here (2 once the big man's thanked him for it); -1 he went and got him anyway

// ------------------------------------------------------------------ the other arrivals

LIST arrivals = hivis_done, hivis_in, hivis_out, hivis_cond, hivis_hotel, banned_done, banned_in, banned_out, banned_inside, wife_done, wife_in, wife_lied, wife_told, wife_inside
VAR banned_stage = 0
VAR banned_one = 0          // he let GOOD SHOES in on one drink: the clock when he did, until it's settled
VAR banned_held = 0         // what he did about the second drink: 1 walked him out, 2 last one, -1 let it go
VAR owner_missed = 0        // when he rang the owner from the bar phone at the door, and nobody answered (0: he didn't)
VAR dog_told = false        // he gave Dennis his wife's message about the dog
VAR wife_at = 0             // when RAINCOAT came to the door, if she did (door.ink)
VAR wife_stopped = false    // he went over to table 28 when she came in, and she stopped him with a word
VAR case_back = 0           // HI-VIS's beer, held behind the door: 1 carried up to him, -1 left behind the door
VAR hivis_landing = false   // pointed at the stairs at close, HI-VIS didn't make it past the landing

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
VAR slippers_both = false     // the second of the two women in slippers has gone up too, after the rat
VAR traps_reset = false     // he reset the traps in the keg room after the first one went off
VAR nursed = false          // he held a rye at table 28 and didn't drink it, the way the old man holds his glass
VAR deck_smokers = 0        // who talked in front of him on the deck (deck.ink): 1 two women, 2 a man watching the lot, 3 two of the mill crew
VAR smokers_at = 0          // when they did: the Godot build keeps them out there till their smoke's done
// What the rats heard him say, at table 28 and in the walls (bible/06_THE_HOTEL.md: they hear everything
// said in the building). The old man knows all of it by the parley.
LIST heard = h_walter, h_leave_walter, h_owner_rats, h_no_rats, h_boot, h_said_no, h_said_down, h_lid, h_left_trap, h_city, h_father
VAR rats_heard = ()

// ------------------------------------------------------------------ incidents, and the log he writes

LIST incident = inc_kid_refused, inc_no_id, inc_deck, inc_banned, inc_rat, inc_fight, inc_police, inc_hivis, inc_wife, inc_lot, inc_drinking, inc_poison, inc_hurt, inc_drugs, inc_office, inc_after
VAR logged = ()
VAR shaded = ()
VAR left_out = ()
VAR cocoon = 0              // the hidden measure: whether he lies to himself (bible/02_SYSTEMS.md). Never shown.
// The scanner at the door keeps every card it's shown, with the time. She can read it back.
LIST scanned = scan_phone, scan_card, scan_goodshoes
VAR scans = ()
VAR police_at = 0           // the clock when the bartender called it in. It's always forty minutes out here.
VAR police_seen = false
VAR told_police = 0         // what he told the constable: 1 the way it happened, -1 less than that, 2 left it to her
VAR name_on_log = false     // he told her not to call it: "Your name on the log, then."
VAR bar_scuffle = false     // putting GOOD SHOES out went wrong: the stool went over
VAR office_wiped = false    // he wiped the mirror on the desk in the office downstairs
LIST found = why_deck, why_hotel, why_front, why_sleeper
VAR found_why = ()          // what the search at close turned up, toward why the numbers don't match

// ------------------------------------------------------------------ his past, as he tells it
// What he invents becomes fact, and people compare notes (bible/02_SYSTEMS.md).

LIST claim = said_up_island, said_city_door, said_city_unnamed, said_city_line, said_around, said_father, said_left_bad_owner, said_left_something, said_left_long_story, said_nothing, said_no_kids, said_maybe_kids, said_asked_back, said_father_stopped, said_helped_others, said_didnt_help, said_father_dead, said_father_doors, said_not_like_him, said_trying_not
VAR claims = ()
VAR father_named = false
VAR owned_it = 0            // owning a mistake out loud (+) or getting past it without (-): "I was wrong"

// ------------------------------------------------------------------ voices trying to get in

VAR pull_table = 0          // time and drinks with table 28
VAR pull_kid = 0            // real talk with the kid
VAR new_voice = ""
VAR cardigan_go = 0         // he told the one in the cardigan to go to Calgary (1), to stay (-1), or that he didn't know either (2)
VAR cardigan_secret = false // the one in the cardigan asked him not to tell the table he was out on the deck
VAR how_doing = 0           // times he's asked table 28 how everybody's doing
VAR picked_receiver = false // he picked up the dead payphone in the back hall
VAR secret_kept = 0         // at close table 28 asked where the one in the cardigan had been: 1 he kept it, -1 he told them

// ------------------------------------------------------------------ the end of the night

VAR owner_lie = false       // he told the owner the rats were handled
VAR owner_count = 0         // what he told the owner when he asked how it was tonight: 1 the door's number, 0 quiet, -1 busy (it wasn't)
VAR police_called = false    // the bartender called it in after the fight
VAR verdict = 0             // what the bartender tells the owner: 2 he'll do, 1 he showed up, -1 what she saw
LIST cleared = cl_pool, cl_banned, cl_hivis, cl_res, cl_t28
VAR two_called = false
VAR asked_name = false      // he asked the bartender what to call her
VAR terms_kept = 0          // the kitchen door on the latch, the night he made the terms: 1 he went and did it, -1 he went up
VAR last_glass = 0          // the glass she poured him after hours: 1 he drank it, 2 left it standing full, 3 pushed it back, 4 she gave him water


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
// Nothing but a beat: what comes after it (a walk, mostly) comes after the line before it, not
// under it. The engine runs it only once that line is out, so a move made after a scene's last
// line starts when the line's been shown, not with it.
EXTERNAL beat()

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
=== function beat()
~ return true
