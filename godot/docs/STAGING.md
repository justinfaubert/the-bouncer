# Who is where on Wednesday: a staging spec from the Ink

This covers every file under `/mnt/project-files/the-bouncer/content/ink/`, plus `content/data/characters.yaml`, `props.yaml` and `marks.yaml`, and the door-look sketch. References are `file:line` under `/mnt/project-files/the-bouncer/content/ink/`. Conditions use the Ink's own names. A stitch visit count is written `knot.stitch` and can be read like a variable. Inside tables, "and" and "or" stand for `&&` and `||`.

The short version: most figures sit at fixed spots, and a small set of flags moves them. The three kids were the hard case; the Ink now keeps where each of them is (section 4). Section 18 lists places where the Ink contradicts itself, with my best reading for each.

## 0. Rules that apply to every figure

1. **Clock marks (minutes since midnight):**
   - 1180 (7:40 pm): open. He's in the lot (prologue.ink:4).
   - 1190: the pickup pulls in and the kid comes to the stool (prologue.ink:89-96).
   - 1215: the card machine goes down (sim.ink:258).
   - 1230: walk-ins can start (sim.ink:16).
   - 1240: refused kids try the deck (sim.ink:42).
   - 1250 or 1300: the sister comes (sim.ink:240-243).
   - 1260: HI-VIS is due and pool heat starts (door.ink:20, sim.ink:26).
   - 1290: the rat on the carpet (sim.ink:256).
   - 1300: HI-VIS fallback (sim.ink:66); the kid locks himself in (hall.ink:7).
   - 1320: the sister in the women's and HI-VIS on the stairs become possible (hall.ink:13, 16).
   - 1350: GOOD SHOES is due (door.ink:21); Cardigan's deck window ends (deck.ink:10).
   - 1370: GOOD SHOES fallback (sim.ink:78).
   - 1380: the cook goes home (rats.ink:14).
   - 1440: the owner calls (sim.ink:260).
   - 1480: RAINCOAT is due (door.ink:22).
   - 1500: RAINCOAT fallback (sim.ink:87).
   - 1530 last call, 1560 "It's two", 1620 or later the keg parley, 1640 or later upstairs (closing.ink:75, 99, 658, 790).
2. **Arrivals reach the stool only when he enters `at_door` after they're due** (door.ink:19-23).
   - "Stay on the door" loops `door_quiet` without checking again (door.ink:49-51).
   - The sim fallbacks don't look at `here` (sim.ink:65-91).
   - So HI-VIS, GOOD SHOES and RAINCOAT can arrive "while nobody was on the door" even when he's sitting on the stool. Stage them from `arrivals`, not from `here`.
3. **Timed events run one per hub visit**, in the priority order at sim.ink:239-264. A sim flag can therefore be set a few minutes before the scene that shows it.
4. **Some states only exist when he walks in on them:** Cardigan on the deck, Hearing Aid at the trough, Vape in the men's, the sister in the women's, HI-VIS on the stairs, and Vape on the deck steps.
   - Best reading: they're at their usual spot, and at the discovered spot when he arrives while the condition holds. This matches bible/09_REVIEW.md:89 ("the bigger moves happen between glances").
   - The kid in the single washroom is different. It's continuous: the room line says the door has been locked "for a while now" (floor.ink:130-134).
5. **The Ink's own "Faces" head count (floor.ink:245-247) is not reliable.**
   - Table 28 is always five.
   - The big man, the buddy and the old man are always listed.
   - "The kid by the jukebox" appears whenever `kids_in > 0`, even if it's only the sister inside.
   - GOOD SHOES appears whenever `banned_inside` is set, even after `banned_out`.

## 1. The bartender
She's behind the bar all night except in the cases below. She's never counted in `room_count`.

| Place | Condition | Notes (scenes with him) | Evidence |
|---|---|---|---|
| Behind the bar cutting limes | 1180 prologue | Hands him the clicker; the owner's note is on the till. He's at the bar with her, though `here` is floor. | prologue.ink:22-31, 55-82 |
| Service end of the bar, talking | `here == bar` (at_bar: binder, house rules, rats, "how long", name, shift drinks) | Shift drinks go on the ledge, not the bar. | bar.ink:9-15, 42-139 |
| Behind the bar | ev_card (clock ≥ 1215); ev_owner (clock ≥ 1440) | For the owner she holds the corded bar phone out across the bar. | bar.ink:168-258 |
| Round the end of the bar, in front of him | ev_banned_inside (`arrivals ? banned_inside` and `banned_stage == 0`) | Goes back behind the bar after "Leave him." | door.ink:628, 676 |
| Ledge by his stool, glass of water | After door_banned turn_away | "After a while." | door.ink:620 |
| At table 28 | at_t28.sit (brings the rye); at_t28.another while `knows !? dennis` (brings a round) | Brief. | table28.ink:94, 214 |
| Behind the bar, phone in hand | ev_pool.after_fight; she dials if he picks "Call it." (`police_called`) | | pool.ink:389, 396-403 |
| Empty table with a coffee | sort_out coffee, check passed | | pool.ink:452 |
| At the trapdoor behind the bar | First at_keg ("Third step"); called_up (stamps whenever `due()` while he's below); crawl failed ("Find anything?"); change_keg ("Lager's back") | | rats.ink:247-248, 282-285, 307, 418-419 |
| Out on the carpet | ev_rat bold stamp passed (paper towel); ev_rat.sick "Finish it" (holds out the mop); ev_rat.sick "Leave it" (on her knees under the radiator by table 28). The sick branches need `poison`. | | rats.ink:445, 561, 580-581 |
| Rings the bell over the till | last_call | | closing.ink:80 |
| Chairs up around table 28 | close_t28 "Take your time" | | closing.ink:364 |
| Far end of the bar, pours the full glass away | close_endbar (`knows ? endbar_seen`) | | closing.ink:331 |
| Takes the clicker from him at the door | lock_up with `zeroed >= 6` | | closing.ink:429 |
| End of the bar, till drawer on her hip | still_in.own_up | | closing.ink:511 |
| Log on the bar; one song on the jukebox; counts the till with a rye | incident_log, after_hours | | closing.ink:531, 589-591 |
| Out the front; her car leaves the lot | keg_parley only (1620 or later) | On the go_upstairs path she's still at the till when he goes up. | closing.ink:663 |

## 2. Table 28 and Walter
All five sit at the round table in the front window from open (they've been there since 2 pm) until close_t28. They are 5 of the 13 in `room_count`.

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| All five at table 28 | From open until `cleared ? cl_t28` | `t28_rounds = 3 + (clock-1180)/45`. At `here == t28` he either stands at the end of the table with his arms folded or sits in a too-small chair. | prologue.ink:33; sim.ink:23; table28.ink:18, 88-94, 239-241 |
| GLASSES (Dennis) gone: empty chair with his half-full glass | `arrivals ? wife_told` or `wife_in` or `wife_inside` (the Ink's own test) | Leaves with RAINCOAT by the front door. `room_count` never goes down for him. The text says both "closed up the gap" and "the gap was still there"; best reading is an empty seat. | door.ink:719-732; table28.ink:337, 371; closing.ink:342-343 |
| GLASSES raising his drink an inch at him | `wife_lied` | He stays until close. | door.ink:713 |
| CARDIGAN at the deck rail, back to the building and the room, smoking (in the plastic chair at the rail, `deck_chair_rail`, turned to the rail) | `cardigan_on_deck()`: `clock < 1350` and `not at_deck.cardigan` and `arrivals !? wife_in`, while he's on the deck | "They think I'm in the can." After the talk he's back at the table. `cardigan_go` (1 means "Go" to Calgary, -1 means stay) does not send him anywhere tonight. | deck.ink:9-10, 36-39, 75-109 |
| CARDIGAN last out, nods at him at the door | close_t28 with `cardigan_go == 1` | | closing.ink:377-379 |
| HEARING AID at the men's trough | The second men's check that isn't the Vape scene (a `stopping` list) | Nods to him in the mirror. | hall.ink:61-72 |
| SCRATCH lowering fries under the table | walter_intro; ev_rat bold "Let it go" | | table28.ink:153; rats.ink:490 |
| SCRATCH on the deck with Walter (trap and all) in a bar towel, about 20 min | ev_trap_t28: `trap_at ? t28` and `walter_alive()` and `not trap_sprung` and `clock >= traps_set + 40`, at the next hub visit | The Ink stores no clock for this; record the clock when `trap_sprung` flips. | sim.ink:254; rats.ink:612-637 |
| SCRATCH down at the baseboard hole | close_t28 when `walter == 3` | | closing.ink:348-350, 386-392 |
| TEAM JACKET at the front door, patting his arm | close_t28 "Now. All of you." | | closing.ink:372-376 |
| Out to their trucks; all of them drive | After close_t28. Extra time: +5; "Drink up" failed +15; "Take your time" +25; he sits with them +15. | If Dennis left with his wife, his truck is still in the lot (best reading of door.ink:711). | closing.ink:337-382 |
| All five turned round in their chairs, or lifting their feet together | ev_rat stamp (passed or failed); ev_pool.after_fight | | rats.ink:445, 455; pool.ink:389 |

- **Not reachable on Wednesday:** Scratch carrying the poisoned Walter out to the deck needs `day >= 3` (rats.ink:527, 570-574).
- **Walter:**
  - Under the table at his boot eating a fry, then into the fist-sized hole in the baseboard: at_t28 "Something moves under the table", when `knows !? t28_rat` (table28.ink:148-165).
  - Dead when `walter == 0`, from the boot check passing or from the trap (table28.ink:175-185; rats.ink:617).
  - When `walter == 3` (ate the bait) he stays in the wall (table28.ink:309-312; sim.ink:61-63).
  - A fry basket sits on the carpet by the hole after "Put the basket of fries under the table" (table28.ink:317-325).

## 3. The big man and the buddy

**The big man**

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| At the pool table: left-handed, four twenties under the rail, jacket on the hook by the table | `pool_still()`: `fam !? dad_went` and `!? dad_ejected` and `!? lot_scene` and `!? dad_drove`. This is still true with `dad_stayed`. | Pose from `pool_heat`: 5+ raised voices; 6+ "taking turns… neither one was talking"; left hand flat on the rail. Occasionally at the bar for a "cola". | closing.ink:7-8; floor.ink:126-128; pool.ink:14-26, 74; closing.ink:175 |
| With him at the pool table | at_pool: watch (he leans on the pillar by the dartboard), talk (the big man chalking), play (he takes the buddy's turn), "Tell him right here, at the table" | | pool.ink:47-152, 190 |
| End of the bar with him, low, backs to the room | tell "Got a second? Over here." or "Your daughter's at the door." | Then either went or stayed. | pool.ink:193-196, 213, 254 |
| Fighting at the pool table | ev_pool: `not fam_done` and `fam !? pool_fight`, and either (`kids_in > 0` and `pool_heat >= 7`) or (`kids_in == 0` and `pool_heat >= 9`). Also at_pool.blew_up (`crit == -1` on the tell). | | sim.ink:248-251; pool.ink:279-381 |
| Empty table with a coffee | sort_out coffee | Passed: leaves with the kids (`dad_went`). Failed: back at the pool table (`dad_stayed`). | pool.ink:449-466 |
| Walked to the front door, stops, turns | sort_out "Put the big man out" (`dad_ejected`) | With `kids_in > 0`: they argue by the pickup, he gets in the passenger side, it leaves (adds `dad_went`). Otherwise he walks off along the highway toward town. | pool.ink:411-425 |
| Everyone into the pickup, gone | sort_out "Everybody who was in that, out." (`dad_ejected`, no `dad_went`) | Same flags as the walk-off above when `kids_in` was 0. | pool.ink:438-448 |
| Out the front to the lot and the pickup, toward town | at_pool.went (`dad_went`) | If his daughter's in the pickup or the vestibule: hugs her in the lot in the headlights, and the kid comes out to them. If she's at the rail: crosses to them and they go out together. Else: hand on the kid's neck (at the jukebox, or knocking on the single washroom), out together. Leaves without his jacket. | pool.ink, went |
| With the kid at the pool table | at_hall.kid_tells | Ends in kid_leave (`dad_went`) or "I'll come by after" (`dad_stayed`). | hall.ink:342-393 |
| Stays at the pool table after being told | `dad_stayed` (from stayed, kid_tells, or coffee failed) | | pool.ink:247-277 |
| At close: pool table, then out to his own work truck (toolbox across the bed, nose-in by the beer store); drops his keys | close_pool (only offered if `pool_still()` at last call), then the_lot (`lot_scene`) | See section 16. | closing.ink:124-200 |
| Gone at close | In the pickup (`dad_went` and `lot_scene`); in his work truck (`dad_drove`); walking the highway (`took_keys` without `dad_went`) | If `took_keys`, the keys go in the lost-and-found drawer behind the bar. | closing.ink:222-255, 939-948 |

**The buddy**

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| At the pool table: small, quick, keeps looking at the door | While the big man is at the table | | pool.ink:19 |
| In the fight | ev_pool | Picks up the twenties (when `kids_in == 0`); has a pool ball down by his leg (Wrong Man check passed); goes down against the jukebox (Wrong Man check failed, `kids_in < 3`). | pool.ink:316, 368, 376 |
| Takes the four twenties to the tip jar at the bar, then leaves by the front door | at_pool.went or at_hall.kid_leave (`room_count--`) | | pool.ink:240-242; hall.ink:389-391 |
| Out | "Everybody who was in that, out"; the_lot (in `room_count -= kids_in + 2`) | The Ink doesn't narrate him in the lot. | pool.ink:442; closing.ink:186 |
| Not placed, but still counted | After "Put the big man out" or coffee passed. The pool table is "empty" (after_gone). | Best reading: at the bar, leaves with the crowd at close. | pool.ink:285-290 |

## 4. The three kids

**Where each of them is.** Since 3 October 2026 the Ink keeps it exactly, one spot each, so nothing here has to be worked out: `kid_at`, `sister_at` and `vape_at`, each one item of `LIST spot = s_truck, s_door, s_vestibule, s_jukebox, s_single, s_rail, s_bar, s_lot, s_gone` (main.ink). Every move goes through `move(ref who, to)` in sim.ink, which keeps `kids_in` and `room_count` in step; `indoors()` is the jukebox, the single washroom, the rail and the bar; `family_gone()` sends all three to `s_gone` and sets `truck_gone`. `stage.gd` stages each of them straight from their spot:

| Spot | The kid | The sister | The boyfriend |
|---|---|---|---|
| `s_truck` | in the pickup, out of sight (at the stool instead before anything's been decided, for the title) | at the wheel | across the back seat |
| `s_door` | in front of the stool, phone up | in front of the stool, card up | behind her, holding the door |
| `s_vestibule` | | waiting in the vestibule | behind her |
| `s_jukebox` | by the jukebox | | |
| `s_single` | locked in, out of sight | | |
| `s_rail` | by the pool table with his father | at the rail by the pool table | |
| `s_bar` | | | at the bar, trying to get served |
| `s_lot` | loose in the lot | out of the truck, in the headlights | rattling round the lot |
| `s_gone` | gone | gone | gone |

The older rule, worked out from `kids_in` and the family's flags, is in this file's git history; nothing needs it now. The tables below still give the scenes and the evidence for each place.

**The pickup.** It's theirs: engine running, wipers going, at the edge of the lot from 1190 (prologue.ink:95), until `truck_gone` (every departure calls `family_gone()`).
- Its engine goes off only after at_lot "Come in" (deck.ink:247).
- `kids_waiting` only controls whether he can walk out to the pickup (floor.ink:39). It doesn't mean all three are in the truck.

**HOODIE (the kid)**

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| Pickup, passenger seat | From 1190 until he gets out. Later whenever K is 0 and the pickup is there. | Best reading: after "Go home and sleep" he goes to the pickup too. | door.ink:58, 185-191 |
| In front of the stool | door_hoodie, from 1190 until `hoodie_admitted` or `hoodie_refused` is set | Phone up; hood up; earbuds in; other hand in the pouch. See section 15. | door.ink:56-161 |
| To the driver's window and back, then to the stool with the real card | fetch: `pass(5)` first, then the flags are set | | door.ink:197-212 |
| Crosses the lot and walks past the stool, no ID | sister_alone "Get him." or sister_all, both with `hoodie_refused` | | door.ink:333-338, 357 |
| Through the deck (seen only as sneaker prints) | via_deck (sim, clock ≥ 1240: `hoodie_refused` and `fam !? sister_met` and `deck_door`) | This is his only time on the deck: three pairs of prints. | sim.ink:41-48; deck.ink:53-59 |
| By the jukebox, hood up, not playing it | K, and none of the rows below apply | After kid_decides "I'll tell him", he's "closer to the pool table this time". | door.ink:176, 209, 235; floor.ink:135-141; hall.ink:323 |
| At the jukebox with the doorman | at_pool.kid_jukebox (`kids_in > 0` and `hoodie_admitted` and `!? kid_opened` and `!? kid_found` and `at_pool.kid_jukebox == 0`) | Then he goes down the back hall and locks himself in (`kid_found`). | pool.ink:44-45, 154-185 |
| Locked in the single washroom | K and `kid_locked_in()`: `kids_in > 0` and `hoodie_admitted` and `!? kid_opened` and `not fam_done` and `not kid_out` and (`kid_found` or `clock >= 1300`) | Continuous. The doorman knocks and talks through the door; or sits on the hall carpet with his back to the door (sit_outside); or goes in / opens it with a dime. Inside, the kid sits on the closed lid, hood up, phone face down on his knee, and the doorman leans on the sink (kid_talk sets `kid_opened`). | hall.ink:6-7, 172-236 |
| Back to the jukebox | `kid_out` set by two_minutes, coin "Sorry", kid_talk "Leave him be", or kid_decides "I'll tell him" | | hall.ink:215, 231, 285, 323 |
| End of the pool table, in the way of a shot | ev_pool when `fam !? sister_admitted`; at_hall.kid_tells (hood down) | This applies even if he was locked in; best reading, he comes out. | pool.ink:310-313; hall.ink:346-348 |
| Out through the hotel door (if `hotel_door`), otherwise the long way round to the front | kid_decides "Go home and sleep" (`kid_out`, `kids_in--`) | No unique flag marks this choice; only the drop in `kids_in` does. | hall.ink:329-340 |
| Leaves with his family | Section 3 departures; stayed (pool.ink:262-272); kid_tells "Don't." (hall.ink:366) | | pool.ink:224-239, 417-421, 446, 452; hall.ink:380-388 |
| Under the awning at close, then in the pickup's middle seat | the_lot with `kids_in > 0`; to_pickup when `hoodie_admitted` or `via_deck` | | closing.ink:183-184, 236 |

**THE DRIVER (his sister)**

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| At the wheel of the pickup, face lit by her phone, watching the door | Pickup there, S is 0, and she isn't in the ev_sister scene or the vestibule wait | Window down for the kid during fetch. With `kids_waiting` and `not fam_done` the doorman can walk out to her window (at_lot); it comes down four inches. | door.ink:108, 206; deck.ink:214-260 |
| Vestibule, in front of the stool | ev_sister at 1250 (`hoodie_refused`, `!? via_deck`, deck door shut) or 1300 (`hoodie_admitted` or `hoodie_conditions`). From `sister_met` until the choice; variable test: `sister_met` and `!? via_deck` and `!? sister_admitted` and `!? sister_refused` and `ev_sister.sister_fetch == 0`. | Keys in her fist, licence card at eye level. | door.ink:241-317 |
| Waiting in the vestibule, dripping, with her keys | `ev_sister.sister_fetch > 0` and `!? sister_admitted` and `!? kids_waiting` and `not fam_done` | No timeout. at_pool.stayed has him go back to the door to tell her. | door.ink:370-382; pool.ink:261 |
| Back to the door a minute later, waves at the truck | sister_alone when `hoodie_refused` | | door.ink:330-345 |
| At the rail by the pool table, keys in her fist | S | | floor.ink:246; deck.ink:146; hall.ink:91; closing.ink:136 |
| Straight to the pool table | at_lot "Come in. Just you" (`at_lot.goes_in`) | Engine off. | deck.ink:239-273 |
| At the big man's elbow at the pool table | ev_pool with `sister_admitted` | | pool.ink:304-306 |
| Women's washroom, at the sink, cold tap over her wrists | `sister_in_womens()`: `sister_admitted` and `kids_in > 0` and `not fam_done` and `!? dad_told` and `clock >= 1320` and `not at_hall.sister_sink` | Found when he knocks. "Go home" sends her out past him; she doesn't go home. | hall.ink:12-13, 136-158 |
| At the front door being put out; stops to speak | ev_deck_kids "Put all three out" (she goes last); sort_out "Put the kids out" | | deck.ink:162-181; pool.ink:428-437 |
| In the lot, out of the driver's door, in the headlights | at_pool.went (`sister_fetched` or `kids_waiting`); at_hall.kid_leave (`kids_waiting` or `!? sister_admitted`); the_lot with `kids_waiting` | At close she stands in the rain and doesn't come closer; in to_pickup she opens the passenger door. | pool.ink:226; hall.ink:381; closing.ink:181-182, 236 |

**VAPE (her boyfriend)**

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| Stretched across the pickup's back seat, vape in hand or on his chest | Pickup there, V is 0, `fam !? vape_ejected`, and not in the ev_sister scene | "He's like, asleep." | door.ink:109, 137; deck.ink:252-256 |
| Vestibule, behind her, holding the door open with his shoulder | ev_sister | Vape in hand, no ID ("in my other pants"). Goes back to the truck on sister_alone, sister_fetch or sister_no. | door.ink:247, 302-306, 327-328, 379, 393 |
| At the bar trying to get served | V (his default) | | door.ink:364-365; deck.ink:135, 146, 281 |
| Men's, the stall with no door | `vape_in_mens()`: `kids_in >= 3` and `!? vape_ejected` and `not fam_done` and `clock >= 1290` and `not at_hall.vape_line` | Phone flat on the tank lid, rolled-up bill. If the doorman flushes it, says "Not in here" or says nothing, he stays in. | hall.ink:9-10, 61-118 |
| At the pool table in the fight | ev_pool with `kids_in >= 3` | Failed checks shove him into the jukebox or the table. | pool.ink:307-309, 345, 359, 374 |
| Walked the length of the room and out the front onto the gravel; then in the lot ("she locked it") | `vape_ejected` (and `vape_out_at = clock`): vape_line "Put him out"; ev_pool "Take the boyfriend out first" (passed); ev_vape_back "Put him out again" | | hall.ink:82-97; pool.ink:334-343; deck.ink:284-301 |
| Back at the bar, dripping, prints from the deck door | Sim: `vape_ejected` and `deck_door` and `not fam_done` and `not vape_returned` and `clock >= vape_out_at + 30` sets `vape_returned`. ev_vape_back plays if `not vape_seen`. | "Put him out again" without pulling the coaster resets `vape_returned`, so he can come back again silently. | sim.ink:50-58, 252; deck.ink:278-307 |
| Up the deck steps, rattling the locked deck door | `vape_on_deck()`: `vape_ejected` and `not deck_door` and `clock >= vape_out_at + 20` and `not fam_done` and `not at_deck.vape_back` | Next: round the side to the pickup; or walked there by the doorman; or falls down the steps into the gravel; or let back in (goes to the bar). | deck.ink:6-7, 111-137 |
| Last out with the family, holding the door | Family departures with `kids_in >= 3` | | pool.ink:228, 266; hall.ink:383 |

## 5. HI-VIS (and the work crew)

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| Not in the building (at the beer store) | `arrivals !? hivis_done` | "Went to the store for the boys." | door.ink:433 |
| In front of the stool | door_hivis: entering at_door with `!? hivis_done` and clock ≥ 1260 | Two-four of beer under one arm. See section 15. | door.ink:402-441 |
| At the bar, the case on the floor by his bar stool | `hivis_in` and `!? hivis_cond` ("Go on in.") | | door.ink:442-450 |
| At the bar; the case pushed behind the front door | `hivis_in` and `hivis_cond` | | door.ink:451-460 |
| Out round the side to the hotel entrance, then upstairs | `hivis_out` and `!? hivis_hotel` and `!? hivis_in` | From "Take it up to your room", or "Not tonight" when the hotel door is shut, or the sim fallback when the hotel door is shut. | door.ink:461-476; sim.ink:72-73 |
| At the bar, about 20 minutes later, down the hotel stairs without the beer | "Not tonight" with `hotel_door`: `hivis_out` and `hivis_hotel` are set at once (`pass(0)`) | The flag is set about 20 minutes before he appears. | door.ink:477-482 |
| At the bar, came in through the hotel | Sim at clock ≥ 1300 with `hotel_door` (`hivis_hotel`) | | sim.ink:65-71 |
| Hotel door at the end of the back hall: sock feet, no vest, a can of his own beer | `hivis_on_stairs()`: `hivis_out` and `!? hivis_hotel` and `!? hivis_in` and `hotel_door` and `clock >= 1320` and `not at_hall.hivis_stairs` | Found when he's in the hall. "Go round the front": about 5 minutes later he's at the front door in boots, clicked in (`hivis_in`). "Fine. Leave the can.": the empty goes on top of the payphone and he goes into the bar (`hivis_hotel`). "Back upstairs": stays up. | hall.ink:15-16, 414-437 |
| Asleep at the bar, head on his arms, vest folded under his cheek | `hivis_still()` at last call, until `cleared ? cl_hivis` | | closing.ink:10-11, 293-309 |
| Walked up the back stairs to room eleven, or pointed at the stairs | close_hivis | The doorman goes up with him for 8 minutes. | closing.ink:299-305 |

- **The work crew** are only ever upstairs: second-floor rooms, doors open, a card game in one of them with the TV on (closing.ink:302; door.ink:429-433). They never come into the bar.

## 6. GOOD SHOES

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| In front of the stool | door_banned: entering at_door with `!? banned_done` and clock ≥ 1350 | See section 15. | door.ink:489-537 |
| Waiting in the vestibule | While the doorman checks the binder behind the bar (3 min), asks the bartender (2 min), or rings the owner on the bar phone (2 min) | | door.ink:541-574 |
| At the bar: a fifty on it, umbrella hooked on the rail | `banned_in`, or (`banned_inside` and `!? banned_out`), until `cleared ? cl_banned` | `banned_inside` is the sim fallback at 1370 or later. During ev_banned_inside the bartender comes round and the doorman stands by his stool. | door.ink:579-611, 625-677; sim.ink:77-84; floor.ink:143-149 |
| Out the front | `banned_out` (turned away: opens the umbrella in the vestibule; walked out; put out, with the stool going over on a failed check) | | door.ink:613-621, 636-666 |
| At the bar at close, telling the woman in slippers about property values (or the bartender, if `cleared ? cl_res`), then out the front | close_banned | "One more" adds 10 minutes. | closing.ink:260-291 |

## 7. RAINCOAT (Dennis's wife)
She's never counted in `room_count`.

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| Vestibule, comes no further in | door_wife: entering at_door with `!? wife_done` and clock ≥ 1480 | Long raincoat, car keys. | door.ink:682-706 |
| Leaves alone | `wife_lied` | Dennis stays. | door.ink:707-715 |
| Waits in the vestibule; Dennis comes to her and they go | `wife_told` | The doorman walks over to table 28 (3 min). | door.ink:716-726 |
| Straight across the carpet to table 28, stands behind GLASSES until he gets up; both leave | `wife_in` from the door | | door.ink:727-735 |
| The same, walking past the empty stool unannounced | Sim at 1500 sets `wife_inside`; ev_wife_inside then adds `wife_in` | If he picks "Go over" he stops halfway there ("Don't."). | sim.ink:86-91, 262; table28.ink:357-375 |

## 8. END OF THE BAR and the Rat King

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| Stool at the far end of the bar by the trapdoor, a full glass he never drinks | From open until last call | Nobody sees him come in. | prologue.ink:35; floor.ink:247-250 |
| The doorman standing beside him | at_bar.endbar (`knows ? endbar_seen` and `at_bar.endbar < 3`) | At most three visits. | bar.ink:39-40, 141-163 |
| Gone; his stool empty, the full glass still there | From last call | The text only shows if `knows ? endbar_seen`; best reading is that he's gone regardless. The glass stays until the bartender pours it away in close_endbar. | closing.ink:91-93, 328-335 |
| Keg room, on an upturned keg between the rows, full glass by his shoe, the stair light on | keg_parley (offered if `endbar_invite` or `knot_seen`), clock 1620 or later | If the doorman refuses or threatens, he's gone when the doorman looks back from the stairs (light off). If threatened, he pours the glass on the dirt first. | closing.ink:642-651, 656-783 |
| The Rat King itself: a ring of rats with their tails knotted, in a gap in the foundation under the front of the building, right under table 28 | Seen only on at_keg.crawl passed (`knot_seen`) | The doorman is on his hands and knees in the crawlspace. | rats.ink:6-7, 299-351 |

## 9. SLIPPERS (two women from upstairs)

| Place | Condition | Notes | Evidence |
|---|---|---|---|
| Both on stools at the near end of the bar, a bottle of white wine | From open until `cleared ? cl_res` | Only one remains once `slippers_upstairs` is set. | prologue.ink:35; floor.ink:246 |
| One standing at the bar with an empty glass and no cash | ev_card | "Stay out of it" sends her upstairs (`slippers_upstairs`). | bar.ink:178-196 |
| One with her feet up on her stool's rung; clapping; hands over her mouth | ev_rat | "Mouse": he leans on the bar beside her. If that check fails she goes up through the hotel door (`slippers_upstairs`). | rats.ink:435, 466, 475, 482-486, 544 |
| Up through the hotel door (back hall) carrying the wine glasses | close_residents | If `not hotel_door`, the doorman unlocks it and holds it for them. | closing.ink:311-326 |

- The one he lends money to lives in room nine (bar.ink:185).

## 10. The cook

| Place | Condition | Evidence |
|---|---|---|
| Kitchen, at the fryer shaking wings; back door propped with a milk crate | `cook_here()` = `clock < 1380` | rats.ink:13-14, 28-42 |
| On the back step in the alley, smoking in his apron | at_kitchen.garbage while `cook_here()` | rats.ink:196-209 |
| Gone home by the back door; the kitchen is dark | `clock >= 1380` | rats.ink:212-218 |

- He never comes into the bar.

## 11. The owner, the night clerk, the police
- **The owner** is only ever a voice on the phone: ev_owner at 1440 or later, and the unanswered call from the door (bar.ink:203-258; door.ink:570-574). He's "in town" (table28.ink:170).
- **The night clerk (Terry)** is on his stool behind the hotel's front desk all night, through the hotel door at the end of the back hall, with his chin on his fist (spot `desk_stool`, model `terry`). The desk is in line with the doorway, so while the door's propped he can be seen from the far end of the hall, watching the bar's TV through the gap; when it's shut, he can't (bar.ink:67; hall.ink:38, 466-490). While he talks to the doorman (at_hall.night_clerk) the view walks through the door to the front desk (`Posts.FRAMES["hall:clerk"]`, picked in main.gd while the choices come from that stitch) and back to the hall post after.
- **The police:** "Call it." sets `police_called` and "It would be forty minutes" (pool.ink:395-403). The constable comes in ev_police and stands inside the door while she asks about it (spot `door_front`, model `constable`).

## 12. Rats

- **The rat on the carpet:** ev_rat, when `not rat_scene` and clock ≥ 1290 (rats.ink:426-590).
  - Without `poison`: a young, thin rat with a torn ear comes out from under the bar rail and crosses in runs, stopping under the stools. It ends up:
    - dead under his boot;
    - under table 28;
    - under a pint glass on a coaster, then carried to the alley, drowned in the kitchen mop bucket, or let go in the keg room;
    - into the back hall;
    - or along the baseboard, past the jukebox, into table 28's hole.
  - With `poison`: a sick rat walks into the open and stops by the pool table. It's killed there, carried in a bar towel to the alley under the back stairs, or crawls under the radiator by table 28.
- **Keg room:** you mostly hear them, not see them. What's visible:
  - A dead young rat in a trap (`trap_at ? keg` and clock ≥ `traps_set + 60`, at_keg.check_traps).
  - "Something moved behind the kegs" at close (still_in, `rats !? war`).
  - The fries on the third step gone 30 minutes after `fries_step`.
  - Evidence: rats.ink:260-262, 390-412; closing.ink:498-504.
- **Alley:** eight or nine rats on the bags in the dumpster (garbage) (rats.ink:200).
- `rats` and `rat_count` don't drive any visible rats in the Ink.

## 13. Unnamed people
- **Three unnamed patrons at open.** `room_count` is 13 but only 10 people are named. The Ink never describes the other three; best reading, unnamed regulars.
- **Two regulars** come in on the third `door_quiet` beat (door.ink:36-38).
- **A woman buying smokes** at the machine by the door, then leaving (door.ink:39).
- **A man he clicked in earlier** goes out to sit in his truck for 10 minutes and comes back (door.ink:41).
- **A sleeper** in the men's doorless stall on the third men's check (non-Vape); he goes back to the bar (hall.ink:69).
- **Walk-ins** (`walk_ins`, 0 to 4) come in uncounted while the door is unwatched after 8:30 (sim.ink:16-20).
  - The nth one needs a single unbroken absence of 45×n minutes.
  - He finds wet prints on the mat (door.ink:9-16).
  - After close, if `walk_ins > 0`, one of them is asleep on the single washroom floor. The doorman finds him in the search and walks him out to the lot (closing.ink:470-475).
- **Deck smokers.** While he's on the deck before last call: a woman smoking at the top of the deck steps (`deck_steps`, patron_d), the one who watches him pull the coaster (deck.ink, d_opts); and whoever's next to talk in front of him in at_deck.air, by the same tests the Ink uses (`_deck_smokers` in stage.gd): the two women with the news about GOOD SHOES (patron_f in the chair at the rail, or the far chair if Cardigan has it), the man watching the pickup (patron_c at the top of the steps, facing the lot, `deck_steps_lot`), or two of the mill crew in the chairs at the back (crew_a, still in his vest, and crew_b). Once they've talked (`deck_smokers`, `smokers_at`), they stay out for twenty minutes, a smoke's worth. Floor.ink's "a woman smoking by the steps" (floor.ink:289, 307) is her too. The deck steps are two down off the side of the deck between its last two posts, onto the gravel along the side of the building that goes from the hotel's front door to the lot.

## 14. `room_count`
- **What it counts** ("actually in the building's bar", main.ink:54): patrons in the room, the back-hall washrooms and on the deck.
  - Cardigan "in the can", the kid locked in and Vape in the men's all count.
  - Staff, the doorman, and anyone in the vestibule, the lot or upstairs don't count.
- **Never changed for:**
  - Dennis leaving (so it's one too high after he goes);
  - RAINCOAT (never added);
  - END OF THE BAR vanishing at last call;
  - the buddy in the unplaced case (section 3);
  - anyone who leaves during `clear` except the_lot (`-= kids_in + 2`);
  - the walk-in taken out during the search.
  - So after 1530 it's stale.
- **Can drop twice for one person:** if both ev_card "Stay out of it" and ev_rat "mouse" (failed) happen, it goes down by 2 while only one slippers woman leaves.
- **Unnamed people to fill the room** = `room_count` minus the named figures present, counting Dennis and the unplaced buddy as present. That comes to 3, plus 2 once the regulars have come in, plus `walk_ins`.

## 15. In front of the stool, and what's in their hands
- **HOODIE** (door.ink:58-89, 149-153, 207). He holds up his phone showing a photo of his licence (`#prop: hoodie_phone`).
  - If the doorman takes it, the doorman holds it (`held`).
  - If he scans it, it goes under the scanner and gets a red light.
  - If the doorman swipes to the next photo, the kid takes the phone back into his pouch.
  - After fetch, the kid holds out his real licence from a wet wallet (`hoodie_card`), which scans green.
- **DRIVER** (door.ink:247, 257, 265): car keys in her fist and her licence card at eye level (`driver_card`); the doorman can hold it up by her face.
- **VAPE** (door.ink:247) is behind her, holding the door open with his shoulder, vape in hand.
- **HI-VIS** (door.ink:405, 458) has a two-four of beer under one arm and no ID. With `hivis_cond` the case ends up behind the front door. Later he may come to the front door again in boots with no can (hall.ink:421).
- **GOOD SHOES** (door.ink:492-531) has his licence ready before he's asked (`goodshoes_card`; can be held up by his face; scans green), is closing a golf umbrella, and wears a wool coat.
- **RAINCOAT** (door.ink:685) has car keys.
- **The regulars, the woman buying smokes and the man going to his truck** also pass the stool (door.ink:36-41).
- **The bartender** brings a glass of water to the ledge by the stool (door.ink:620).

People going out past the stool:
- Vape when ejected.
- GOOD SHOES.
- The kids when put out; the sister stops at the door.
- The big man when put out; he stops and turns (pool.ink:416).
- Dennis with RAINCOAT.
- Table 28 at close (Team Jacket's pat, Cardigan's nod).

## 16. The lot and the pickup at close
This only happens through close_pool, which is offered only when `pool_still()` is true at last call. The scene is the_lot (closing.ink:167-255).
- **The big man** takes his jacket from the hook, goes out the front, and heads to his work truck by the beer store. He drops his keys in the gravel.
- **The doorman** stands under the light over the door, then crosses the gravel.
- **If `kids_waiting`:** the pickup's headlights come on full and the Driver gets out and stands in the rain. Anyone not inside (by the section 4 rule) is in the pickup, or loose in the lot if `vape_ejected`.
- **If `kids_in > 0`:** the ones inside come out behind him and stand under the awning.
- **The buddy** is subtracted from `room_count` here, but the Ink doesn't narrate him.
- **How it ends:**
  - to_pickup: the daughter opens the passenger door, the kid sits in the middle if `hoodie_admitted` or `via_deck`, and the pickup leaves toward town.
  - keys taken with no family there: the big man walks the highway toward town.
  - drives: the work truck leaves, and the pickup follows it if `family_in_lot`.
- **Also crossing the lot during `clear`,** in whatever order the player picks: table 28 to their trucks, GOOD SHOES, and later the walk-in from the search. The residents and HI-VIS go up through the hotel door instead.
- **The bartender's car** leaves at about 3:00 on the parley path only.
- **Left in the lot overnight:** the work truck unless `dad_drove`, and Dennis's truck if he left with his wife.

## 17. Where the doorman actually is when `here` says otherwise
- door_banned: behind the bar at the binder, or at the bar asking the bartender, or at the bar phone, while `here` is door. door_wife "tell him": he walks to table 28.
- at_pool.tell (private): end of the bar. at_pool.went: by the front door, looking through the glass. at_pool.stayed: the vestibule, or with the kids.
- Put-outs (ev_pool, sort_out, ev_deck_kids, ev_vape_back, ev_banned_inside, vape_line): he walks them to the front door. The coffee choice: at an empty table.
- Back hall: sitting on the carpet against the single washroom door (sit_outside); inside the washroom (coin, "Go in"); a step behind the kid at the pool table (kid_tells(true)); at the front door clicking HI-VIS in (the stairs scene).
- deck vape_back "Walk him round": in the lot by the pickup.
- Kitchen: in the alley at the dumpster (garbage). Bait and traps go in the keg room, behind the walk-in, or at table 28's baseboard. glass_rat and the sick rat take him to the alley, the mop bucket, or the keg room.
- ev_wife_inside "Go over": halfway to table 28.
- The floor's `doors`, `search` and `still_in` send him round the doors, washrooms, stairs and keg room with `here` still floor.
- In `clear`: the GOOD SHOES, HI-VIS, residents and end-of-bar scenes happen at the bar though `here` is floor (their choices carry `#loc: bar`). Walking HI-VIS up puts him upstairs. A locked hotel door puts him at the hotel door. close_t28 "Now." ends at the front door.

## 18. Ink gaps and conflicts that affect staging
1. Arrivals are missed while he loops on "Stay on the door" (section 0.2).
2. After Dennis leaves, `room_count` stays the same, and the text says both that the gap closed and that it's still there.
3. The buddy isn't placed after "Put the big man out" or coffee passed. "Put the big man out" with `kids_in` 0 and "Everybody out" leave identical flags.
4. The sister's vestibule wait never times out. at_pool.went branch 1 fires on `sister_fetched` even when she's inside, and narrates her in the pickup. stayed branch 1 says she's in the vestibule even when `kids_waiting` puts her in the truck, sends the truck off "with or without" her brother, and still leaves `kids_in` counting anyone inside. the_lot can then offer "his daughter's truck" after it has left.
5. `kid_locked_in()` can be true while the kid is in the truck (section 4). ev_pool and close_pool describe him at the pool table or the jukebox while the lock flag is still set.
6. "Go home and sleep" has no unique flag.
7. `slippers_upstairs` can be set twice, dropping `room_count` by 2 for one person.
8. Vape can come back a second time with no scene. at_pool.blew_up skips setting `pool_fight`, so the fight can fire again after "Put the kids out".
9. Some flags lead the scene they describe. HI-VIS "Not tonight": the flag is 20 minutes early. The stairs scene "round the front": 5 minutes early. Scratch's 20 minutes on the deck, and the trap and wife events, store no clock at all.
10. The cook complains about the kitchen door after 11 pm if the doorman shuts it through the floor's doors walk (floor.ink:311-333).
11. "Put the big man out" with `kids_in` 0 while `kids_waiting`: he walks off and the Ink never says what the pickup does.
12. The door-look sketch disagrees with the Ink (`/mnt/project-files/the-bouncer/sketches/door-look/main.gd:799-805`):
    - It has HI-VIS at the bar at 7:50; he isn't due until 9:00.
    - It has two crew at a table; the crew never come downstairs.
    - It has the slippers woman at the jukebox; both women are at the near end of the bar, and the jukebox is the kid's spot.