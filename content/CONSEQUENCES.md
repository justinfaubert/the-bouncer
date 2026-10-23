# What every choice changes

Written by `node tools/audit.mjs --map` from the Ink. Each choice, where it is, and what it changes that the night reads later: state (a VAR, or a LIST item), a labelled choice whose visit count is read, a task in his notes, a check, or a different scene. "time" is pass() and what the clock moves with it. Nothing here is hand-written; rebuild it after changing the Ink.


## office.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 43 | interview.arrive | Sit down. | sat_how, stat_cha, stat_con |
| 49 | interview.arrive | Look round the room first. | sat_how, stat_gut, stat_int |
| 56 | interview.arrive | Lift the chair back a foot, and turn it. Then sit. | sat_how, stat_wis, stat_str |
| 72 | interview.the_room | Hand it to him. | licence_how |
| 75 | interview.the_room | Put it on the desk. | licence_how |
| 92 | interview.where_before | "A door in the city. Ten years." | told_gary:tg_city, stat_str, stat_cha |
| 99 | interview.where_before | "Up island." | told_gary:tg_up_island, stat_con, stat_wis |
| 106 | interview.where_before | "Around." | told_gary:tg_around, stat_dex, stat_gut |
| 112 | interview.where_before | "My father worked doors. I worked them with him." | told_gary:tg_father, stat_wis, stat_cha |
| 126 | interview.why_left | "The owner shorted me." | told_gary:tg_shorted, stat_int, stat_cha |
| 133 | interview.why_left | "Something happened." | told_gary:tg_something, stat_gut, stat_con |
| 141 | interview.why_left | "Long story." | told_gary:tg_long, stat_wis, stat_gut |
| 146 | interview.why_left | Say nothing. | told_gary:tg_quiet, stat_con, stat_str |
| 158 | interview.fights | "Plenty." | stat_str, stat_con |
| 163 | interview.fights | "When I have to." | stat_wis, stat_dex |
| 168 | interview.fights | "I stop them." | stat_cha, stat_dex |
| 173 | interview.fights | "Never." | told_gary:tg_never, lies_caught |
| 179 | interview.fights | "Want to find out?" | to threat_two; threat |
| 188 | interview.threat_two | "I'm kidding." | to the_call |
| 192 | interview.threat_two | Hold his eye. | to not_hired; threat |
| 203 | interview.the_call | Wait. | call_did, stat_wis, stat_con |
| 209 | interview.the_call | Look at the photo behind Gary. | call_did, knows:senior_photo, stat_gut, stat_wis |
| 217 | interview.the_call | Say something to the bookkeeper. | call_did, stat_cha, stat_int |
| 225 | interview.the_call | Read Gary's desk upside down. | call_did, knows:notice_read, stat_int, stat_gut |
| 234 | interview.the_call | Get up and go. | to walking_out |
| 244 | interview.walking_out | "The washroom." | call_did |
| 248 | interview.walking_out | Sit back down. | call_did |
| 252 | interview.walking_out | "Forget it." | to not_hired |
| 258 | interview.do_you_drink | "Yes." | stat_con, stat_cha |
| 263 | interview.do_you_drink | "Depends who's buying." | stat_cha, stat_int |
| 268 | interview.do_you_drink | "Not on a shift." | stat_wis, stat_con |
| 272 | interview.do_you_drink | "No." | told_gary:tg_dry, lies_caught |
| 286 | interview.do_you_drink | Drink it. | gary_rye |
| 291 | interview.do_you_drink | Hold it, and don't drink it. | gary_rye |
| 296 | interview.do_you_drink | Push it back. | gary_rye |
| 301 | interview.do_you_drink | Drink it, and hold out the glass. | gary_rye |
| 314 | interview.the_rule | "Water. And I sit with him a while." | scenario, stat_cha, stat_wis |
| 320 | interview.the_rule | "Whatever they want." | scenario, stat_int, stat_con |
| 326 | interview.the_rule | "How's he getting home?" | scenario, stat_wis, stat_gut |
| 332 | interview.the_rule | "Put him out." | scenario, stat_str, stat_dex |
| 338 | interview.the_rule | "Must be nice. Owning a bar you never set foot in." | rude; (rude_gary) is read |
| 347 | interview.any_questions | "What happened to the last guy?" | knows:old_doorman, knows:jacket_heard |
| 352 | interview.any_questions | "What's on the fourteenth?" | to dodged |
| 354 | interview.any_questions | "Anything I should know about?" | to dodged |
| 356 | interview.any_questions | "When do I get paid?" | asked_pay |
| 361 | interview.any_questions | "No." | (no_questions) is read |
| 386 | interview.the_deal | "Six, you said." | rent_called |
| 392 | interview.the_deal | "Was anybody talking to you?" | to not_hired; rude; (rude_bk) is read |
| 398 | interview.the_deal | Let it go. | (let_go) is read |
| 409 | interview.the_shirt | Take it. | shirt, things:gary_shirt |
| 414 | interview.the_shirt | "I've got my own." | shirt |
| 425 | interview.paperwork | Fill it in. | pay_how |
| 428 | interview.paperwork | "Cash is fine." | pay_how |
| 433 | interview.paperwork | Read it first. | pay_how, knows:form_uniform, task |

## walk.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 32 | dusk | Cross over to the wharf. | to wharf |
| 34 | dusk | Go along the highway. | to highway; knows:endbar_wharf |
| 49 | dusk.wharf | "Word gets around." | wharf_how |
| 52 | dusk.wharf | "Who's asking?" | wharf_how |
| 55 | dusk.wharf | Say nothing. Look at the water with him. | wharf_how |
| 67 | dusk.highway | Stop at the Esso. | to esso_lot |
| 69 | dusk.highway | Keep walking. | to the_sov; ate, here |
| 82 | dusk.esso_lot | Get something to eat. | ate, cash |
| 87 | dusk.esso_lot | Ask the kid what he's looking at. | to kid_sky |
| 89 | dusk.esso_lot | Ask the kid if he's working. | to kid_rater |
| 91 | dusk.esso_lot | Go on to the Sov. | to the_sov; ate, knows:esso_sky, knows:esso_rater |
| 118 | dusk.kid_rater | The one on the left. | rated |
| 121 | dusk.kid_rater | The one on the right. | rated |
| 124 | dusk.kid_rater | "Neither." | rated |
| 139 | dusk.the_sov | Sit on the seawall and watch it. | to watching |
| 141 | dusk.the_sov | Go up to the room. | to twelve, cross; knows:sov_watched, knows:coat_scouting, knows:coaster, here, from_room, knows:terry |
| 173 | dusk.twelve | Sign for it. | terry_signed |
| 177 | dusk.twelve | "Gary didn't say anything about signing." | terry_signed |
| 299 | dusk.shirt_room | Put it on, over the black one. | shirt_on, things:gary_shirt |
| 303 | dusk.shirt_room | Leave it on the chair. | shirt_on, things:gary_shirt |

## prologue.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 52 | prologue.vestibule | Put it on, over the black one. | shirt_on, things:gary_shirt |
| 56 | prologue.vestibule | Leave it in the jacket. | shirt_on |
| 101 | prologue.before_eight | "Where do you want me?" | to where_want |
| 104 | prologue.before_eight | Count the room. | to count_first |
| 106 | prologue.before_eight | Take the stool by the door. | to the_truck; here, knows:coaster, knows:kitchen_gap, knows:hotel_gap |
| 124 | prologue.where_want | {knows ? old_doorman:"Gary says the last one walked out."/"What happened to the last doorman?"} | knows:old_doorman, knows:jacket_heard; (asked_last) is read |
| 136 | prologue.where_want | "Anyone I should know about?" | (asked_anyone) is read |
| 141 | prologue.where_want | "Okay." | to before_eight |
| 143 | prologue.where_want | Leave her to the limes. | to before_eight |

## door.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 70 | door_quiet | Stay on the door. | to at_door |
| 123 | door_hoodie.read | Take the phone and look at the photo. | knows:kid_legal; (took) is read |
| 131 | door_hoodie.read | Swipe to the next photo. | knows:kid_photo, rep_kids, kid_ease; (swiped) is read |
| 142 | door_hoodie.read | Look at him, not the phone. | check father 12; father_misread, psyche |
| 155 | door_hoodie.read | Look past him at the truck. | check wrongman 12; knows:truck |
| 167 | door_hoodie.read | "Rough night to be out in." | fam:hoodie_rapport |
| 178 | door_hoodie.read | "Take the earbuds out." | fam:earbuds_out |
| 188 | door_hoodie.read | "Where's the card?" | knows:card_in_truck |
| 194 | door_hoodie.read | "Who's in the truck?" | knows:truck |
| 201 | door_hoodie.read | "What are you here for? It's a Wednesday." | more choices |
| 205 | door_hoodie.read | "Who?" | kid_ease |
| 213 | door_hoodie.read | Let it go. | kid_ease |
| 217 | door_hoodie.read | Scan the phone. | phone_scans, scans:scan_phone, kid_ease |
| 231 | door_hoodie.read | "In you go." | to admit |
| 233 | door_hoodie.read | "Not without the card." | to refuse |
| 235 | door_hoodie.read | "Go get the card. I'll be here." | to fetch |
| 237 | door_hoodie.read | "You can come in. On conditions." | to conditions, at_door; fam:hoodie_admitted, kid_at, spot:s_jukebox, count_in, incident:inc_no_id, rep_kids, rep_staff, fam:hoodie_refused, incident:inc_kid_refused, spot:s_truck, knows:kid_legal, knows:card_in_truck, scans:scan_card, knows:truck |
| 317 | door_hoodie.conditions | "You're in. No drinking tonight." | kid_terms |
| 321 | door_hoodie.conditions | "You're in. You stay where I can see you." | kid_terms |
| 325 | door_hoodie.conditions | "You're in if your sister comes in with you." | kid_terms, knows:truck |
| 381 | ev_sister.sister_opts | Look from the card to her face. | knows:bigman_dad |
| 392 | ev_sister.sister_opts | "Get who?" | knows:bigman_dad |
| 398 | ev_sister.sister_opts | "What's it about?" | knows:kid_why, knows:bigman_dad |
| 410 | ev_sister.sister_opts | Look at the boyfriend. | check fighter:wis 10; knows:vape_read, knows:vape_misread |
| 421 | ev_sister.sister_opts | "ID for him too." | knows:vape_no_id |
| 429 | ev_sister.sister_opts | "He's not here." | to sister_lie |
| 431 | ev_sister.sister_opts | "You can go in. He can't." | to sister_alone |
| 433 | ev_sister.sister_opts | "I'll go get him for you." | to sister_fetch |
| 435 | ev_sister.sister_opts | "All three of you, in. Find him and go." | to sister_all |
| 437 | ev_sister.sister_opts | "Both of you, in. Find him and go." | to sister_all |
| 439 | ev_sister.sister_opts | "Nobody else tonight." | to sister_no, at_door, sister_brother; promise_kept, fam:sister_refused, fam:kids_waiting, sister_at, spot:s_truck, vape_at, incident:inc_kid_refused, rep_kids, fam:sister_admitted, spot:s_rail, count_in, spot:s_door |
| 485 | ev_sister.sister_brother | "Get him." | to at_door; fam:hoodie_admitted, kid_at, spot:s_jukebox, count_in, rep_kids, scans:scan_card, knows:kid_legal, incident:inc_no_id, rep_staff, sister_at, spot:s_rail |
| 502 | ev_sister.sister_brother | "If he brings the actual card." | to at_door; fam:hoodie_admitted, knows:card_in_truck, knows:kid_legal, scans:scan_card, kid_at, spot:s_jukebox, count_in, rep_kids, rep_staff, sister_at, spot:s_rail |
| 517 | ev_sister.sister_brother | "Just you." | to at_door; fam:kid_kept_out, rep_kids, sister_at, spot:s_rail, fam:sister_admitted, incident:inc_no_id, promise_kept, vape_at, spot:s_bar, fam:hoodie_admitted, kid_at, spot:s_jukebox, count_in, scans:scan_card, knows:kid_legal, rep_staff, fam:sister_fetched, sister_wait_at, spot:s_vestibule, spot:s_truck, task, fam:sister_refused, fam:kids_waiting, incident:inc_kid_refused |
| 621 | door_hivis | Count his drinks. | check father 10 |
| 630 | door_hivis | Signs of intoxication. | check manual 10 |
| 639 | door_hivis | "Where are you coming from?" | knows:hivis_room, knows:hivis_upstairs, knows:mill_closing |
| 649 | door_hivis | "You can't bring that in." | knows:hivis_upstairs; (no_beer) is read |
| 657 | door_hivis | "Go on in." | to at_door; arrivals:hivis_in, count_in, incident:inc_hivis, rep_staff |
| 671 | door_hivis | "Leave the beer with me and go on in." | to at_door; arrivals:hivis_in, arrivals:hivis_cond, count_in, rep_staff |
| 681 | door_hivis | "Take it up to your room. You can come down after." | to at_door; arrivals:hivis_out |
| 690 | door_hivis | "Not tonight. You've had enough." | to at_door; arrivals:hivis_out, knows:hivis_upstairs, incident:inc_hivis, arrivals:hivis_hotel |
| 736 | door_banned.place | Place the face. | check manual 12; to known, unknown; knows:banned_face |
| 746 | door_banned.place | Let it go. | to unknown |
| 749 | door_banned.place | Hold the licence up by his face. | to recognised, known; knows:banned_face |
| 762 | door_banned.unknown | Scan the licence. | scans:scan_goodshoes |
| 768 | door_banned.unknown | "Been here before?" | (asked_before) is read |
| 772 | door_banned.unknown | Look at him again, harder. | check manual 12; to known; knows:banned_face |
| 783 | door_banned.unknown | Hold the licence up by his face. | to recognised |
| 785 | door_banned.unknown | "Go ahead." | to let_in |
| 787 | door_banned.unknown | "Give me a second." Go check the binder. | to known; here, knows:banned_face |
| 796 | door_banned.unknown | "Give me a second." Ask the bartender. | to known; here, knows:banned_face, knows:eighty_six, rep_staff |
| 820 | door_banned.known | "What did you do?" | knows:banned_story |
| 826 | door_banned.known | "I'll call the owner." | owner_missed, here |
| 835 | door_banned.known | "Not tonight. Not any night." | to turn_away |
| 837 | door_banned.known | "The binder says no. The binder wins." | to turn_away |
| 839 | door_banned.known | "I hear she'd have you shot. So, no." | to turn_away |
| 841 | door_banned.known | "One drink. You sit where I can see you." | to at_door; arrivals:banned_in, banned_one, count_in, incident:inc_banned, rep_staff, rep_owner |
| 855 | door_banned.known | "Go ahead." | to let_in, at_door; arrivals:banned_in, count_in, incident:inc_banned, rep_staff, rep_owner, arrivals:banned_out |
| 900 | ev_banned_inside | Walk him out quietly. | check father:cha 12; to carry_on; here, rep_staff, rep_t28, arrivals:banned_out |
| 919 | ev_banned_inside | Put him out. | check fighter 10; to carry_on; here, rep_staff, incident:inc_fight, bar_scuffle, rep_t28, arrivals:banned_out |
| 939 | ev_banned_inside | "He says the owner lifted it." | knows:binder_hers |
| 944 | ev_banned_inside | Leave him. It's not worth the scene. | to carry_on; rep_staff, arrivals:banned_in |
| 957 | ev_one_drink | Walk him out. One was the deal. | check father:cha 11; to carry_on; banned_held, arrivals:banned_out, here, rep_staff, rep_t28 |
| 976 | ev_one_drink | "That's the last one, then." | to carry_on; banned_held, rep_staff |
| 984 | ev_one_drink | Let it go. He's no trouble. | to carry_on; banned_held, rep_staff |
| 1011 | door_wife | "Which one's Dennis?" | check manual 10 |
| 1021 | door_wife | "He's not here." | to at_door; arrivals:wife_lied, knows:dennis, rep_t28, task |
| 1032 | door_wife | "I'll tell him you're here." | to carry_on; arrivals:wife_told, knows:dennis, here, rep_t28 |
| 1045 | door_wife | "Go on in. He's by the window." | to at_door; arrivals:wife_in, knows:dennis, incident:inc_wife, rep_t28 |

## floor.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 22 | hub | {door_label()} | to at_door |
| 25 | hub | {count_label()} | to count_room |
| 27 | hub | {t28_label()} | to at_t28 |
| 30 | hub | {pool_label()} | to at_pool |
| 33 | hub | {bar_label()} | to at_bar |
| 36 | hub | {hall_label()} | to at_hall |
| 39 | hub | {kitchen_label()} | to at_kitchen |
| 42 | hub | Go down to the keg room. | to at_keg |
| 45 | hub | {deck_label()} | to at_deck |
| 48 | hub | Go out to the pickup in the lot. | to at_lot |
| 54 | hub | Walk across the room. | a way out: the clock |
| 65 | moves | The floor | a way out: the clock |
| 68 | moves | {door_away >= 30:Back on the door/The door} | to walk, at_door |
| 70 | moves | Count the room | to walk, count_room |
| 72 | moves | Table 28 | to walk, at_t28 |
| 74 | moves | The pool table | to walk, at_pool |
| 76 | moves | The jukebox | to walk, at_jukebox |
| 78 | moves | The bar | to walk, at_bar |
| 80 | moves | The back hall | to walk, at_hall |
| 82 | moves | The kitchen | to walk, at_kitchen |
| 84 | moves | The keg room | to walk, at_keg |
| 86 | moves | The deck | to walk, at_deck |
| 88 | moves | The pickup in the lot | to walk, at_lot |
| 277 | count_body | Heads. | last_count |
| 293 | count_body | Faces. | last_count, knows:endbar_seen |
| 307 | count_body | The doors. | to doors |
| 312 | count_body | Hands. | check fighter:wis 11; last_count, knows:pool_lefty, knows:vape_read, knows:vape_misread:- |
| 333 | count_body | Glasses. | check manual 11; last_count, knows:pool_hustle; (count_glasses) is read |
| 347 | count_body | That's enough counting. | a way out: the clock |
| 380 | doors | Pull the coaster out of the deck door. | deck_door, rep_t28 |
| 387 | doors | Shut the kitchen door. | to kitchen_door_shut |
| 391 | doors | Kick the wedge out from under the hotel door. | hotel_door, hotel_shut_at |
| 400 | doors | Leave them. | doors_left:left_deck, doors_left:left_kitchen, doors_left:left_hotel |

## table28.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 39 | at_t28.where_from | "Up island." | claims:said_up_island, rep_t28 |
| 45 | at_t28.where_from | "I worked a door in the city. Ten years." | more choices; claims:said_city_door, rats_heard:h_city |
| 49 | at_t28.where_from | "You wouldn't know it." | claims:said_city_unnamed |
| 53 | at_t28.where_from | "The kind with a line outside." | claims:said_city_line |
| 59 | at_t28.where_from | "Around." | claims:said_around |
| 64 | at_t28.where_from | "My father worked doors." | more choices; claims:said_father, rats_heard:h_father |
| 71 | at_t28.where_from | "Up island. A long time ago." | more choices; father_named, rep_t28 |
| 73 | at_t28.where_from | Tell them. | father_named, rep_t28 |
| 80 | at_t28.where_from | "Doesn't matter." | rep_t28 |
| 83 | at_t28.where_from | "All over." | rep_t28 |
| 91 | at_t28.offer | Sit down. | to sit |
| 93 | at_t28.offer | "I'm working." | to standing; rep_t28 |
| 100 | at_t28.offer | Stay standing, but stay. | to standing; pull_table, rep_t28 |
| 113 | at_t28.sit | Drink it. | drinks, incident:inc_drinking, pull_table, rep_t28 |
| 120 | at_t28.sit | Nurse it. | nursed, rat_favour |
| 128 | at_t28.sit | Push it back to the middle of the table. | rep_t28 |
| 141 | at_t28.stories | "What happened to the last doorman?" | knows:doorman_stories |
| 153 | at_t28.stories | Something moves under the table. | to walter_intro |
| 155 | at_t28.stories | "How long has he been coming to this table?" | rats_heard:h_walter, rep_t28 |
| 163 | at_t28.stories | Stay for another. | to another |
| 165 | at_t28.stories | Get up. | knows:t28_rat, knows:walter_name |
| 185 | at_t28.walter_intro | Leave Walter alone. | rats_heard:h_leave_walter, rep_t28, knows:keg_hole |
| 191 | at_t28.walter_intro | "The owner wants them gone." | rats_heard:h_owner_rats, knows:keg_hole |
| 200 | at_t28.walter_intro | Put a boot on him. | check fighter:dex 12; rats_heard:h_boot, walter, rats, rep_t28, incident:inc_rat, cash, knows:keg_hole |
| 260 | at_t28.tip_offer | Keep it. | cash, rep_t28 |
| 264 | at_t28.tip_offer | Give it back. | rep_t28 |
| 268 | at_t28.tip_offer | Put it in the bartender's jar on the way past. | rep_staff |
| 280 | at_t28.standing | "Anything you need, you let me know." | rep_t28 |
| 283 | at_t28.standing | "You're over the limit. All of you." | check manual:cha 10; to cut_off |
| 285 | at_t28.standing | "What do you know about the rats?" | rats_heard:h_no_rats, knows:t28_rat |
| 292 | at_t28.standing | Leave them to it. | (left_standing) is read |
| 342 | at_t28.again | Sit down with them. | to sit, another |
| 348 | at_t28.again | Ask after Walter. | to again_loop; rats_heard:h_walter |
| 359 | at_t28.again | Put the basket of fries under the table for Walter. | to again_loop; fries, rat_favour, rep_t28 |
| 368 | at_t28.again | "How's everybody doing?" | to again_loop; how_doing, rep_t28 |
| 398 | at_t28.again | Tell Dennis about the dog. | to again_loop; dog_told, rep_t28, task |
| 455 | ev_wife_inside | Go over. | wife_stopped, rep_t28, here |
| 468 | ev_wife_inside | Leave it. She's not trouble. | (let_her) is read |

## pool.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 73 | at_pool.opts | Watch them play. | to watch |
| 75 | at_pool.opts | Tell the big man about the hospital. | to tell |
| 77 | at_pool.opts | Tell the big man his daughter's {sister_at == s_vestibule:at the door/out in the lot}. | to tell |
| 79 | at_pool.opts | Talk to the big man. | to talk |
| 81 | at_pool.opts | Put twenty on the next game. | to play |
| 83 | at_pool.opts | The kid by the jukebox. | to kid_jukebox |
| 85 | at_pool.opts | The jukebox | to at_jukebox, watch_again; heat(), knows:pool_lefty |
| 99 | at_pool.watch | Read the game. | check father 12; knows:pool_hustle |
| 109 | at_pool.watch | Leave it. | heat() |
| 134 | at_pool.talk | "You're a regular?" | to tk; (asked_regular) is read |
| 137 | at_pool.talk | "You're paying him, not playing him." | to tk; knows:transmission, heat() |
| 146 | at_pool.talk | Ask how his night's going. | check father:cha 12; to favour, tk; knows:bigman_dad |
| 161 | at_pool.talk | Leave him to his game. | a way out: the clock |
| 166 | at_pool.favour | "All right." | promised_bigman |
| 170 | at_pool.favour | Say nothing. | promised_bigman |
| 173 | at_pool.favour | "Depends who's asking." | bigman_ease |
| 183 | at_pool.play | Play to win. | check fighter:dex 12; cash |
| 193 | at_pool.play | Play to lose. | bigman_ease, cash |
| 201 | at_pool.play | "No." | claims:said_no_kids |
| 205 | at_pool.play | "Not that I know of." | claims:said_maybe_kids |
| 208 | at_pool.play | "Do you?" | claims:said_asked_back |
| 234 | at_pool.kid_jukebox | Stand next to him and say nothing. | fam:kid_found, kid_at, spot:s_single, knows:bigman_dad, pull_kid |
| 253 | at_pool.kid_jukebox | "Who are you looking for?" | fam:kid_found, kid_at, spot:s_single |
| 258 | at_pool.kid_jukebox | "That your dad?" | check wrongman 12; knows:bigman_dad, pull_kid, fam:kid_found, kid_at, spot:s_single |
| 281 | at_pool.tell | Tell him right here, at the table. | check father:cha 14; to told; heat() |
| 284 | at_pool.tell | "Got a second? Over here." | check father:cha 12; to told |
| 286 | at_pool.tell | "Your daughter's {her_place()}." Just that. | check father:cha 11; to told, went, blew_up, stayed, carry_on, ev_pool.fight; fam:dad_told, fam:dad_went, fam_done, task, rep_kids, rep_staff, fam:dad_stayed, here, fam:kids_waiting:-, fam:pool_fight, incident:inc_fight |
| 445 | ev_pool.fight | Get between them. | check fighter:dex 12; to after_fight; here, hurt, incident:inc_hurt |
| 459 | ev_pool.fight | Take the boyfriend out first. | check fighter 10; to after_fight; here, fam:vape_ejected, vape_out_at, vape_returned, vape_seen, vape_at, spot:s_lot, hurt, incident:inc_hurt |
| 478 | ev_pool.fight | "Everybody stop." | check father:cha 14; to after_fight; here, hurt, incident:inc_hurt |
| 493 | ev_pool.fight | Wait one more second to see who starts it. | check wrongman 12; to after_fight, call_it, sort_out; here, incident:inc_hurt |
| 527 | ev_pool.call_it | Call it. | rep_owner, police_called, police_at, incident:inc_police |
| 536 | ev_pool.call_it | "Don't. I've got it." | rep_owner, name_on_log |
| 544 | ev_pool.sort_out | Put the big man out. | to carry_on; fam:dad_ejected, fam_done, here, fam:dad_went, fam:dad_walked, rep_t28 |
| 566 | ev_pool.sort_out | Put the kids out. All of them. | to carry_on; fam:kids_waiting, rep_kids, here |
| 581 | ev_pool.sort_out | Everybody who was in that, out. | to carry_on; fam:dad_ejected, fam:all_out, fam:dad_went, fam_done, rep_t28, rep_staff, here |
| 599 | ev_pool.sort_out | Sit the big man down and get him a coffee. | check father:cha 12; to carry_on; here, fam:dad_went, fam_done, rep_staff, rep_kids, fam:dad_stayed, fam:kids_waiting |
| 661 | ev_police | Tell her the way it happened. | told_police, rep_staff |
| 672 | ev_police | Tell her less than that. | told_police, cocoon |
| 681 | ev_police | "She called it. Ask her." | told_police, rep_staff |
| 722 | at_jukebox.j_opts | The pool table | to at_pool |
| 724 | at_jukebox.j_opts | See what's played most here. | to most_played |
| 726 | at_jukebox.j_opts | Get it turned down a notch. | to turn_down |
| 728 | at_jukebox.j_opts | Stand at it like you're picking a song. | to stand_at; knows:juke_top, juke_low, heat(), knows:pool_seen |

## bar.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 45 | at_bar.opts | Read the binder under the till. | to binder |
| 47 | at_bar.opts | "Anything I should know about this place?" | to know |
| 49 | at_bar.opts | "Who's the old man at the end?" | to who_endbar |
| 51 | at_bar.opts | "What's the story with the rats?" | to rats_talk |
| 53 | at_bar.opts | "How long have you worked here?" | to how_long |
| 55 | at_bar.opts | "What do I call you?" | to name |
| 57 | at_bar.opts | "Where's the jacket the last one left?" | to jacket_ask |
| 59 | at_bar.opts | The lost-and-found drawer. | to the_drawer; drawer_from |
| 62 | at_bar.opts | {drinks - drinks_before == 0:"Pour me one."/"Another."} | to shift_drink |
| 64 | at_bar.opts | Go and stand by the old man at the end of the bar. | to endbar; knows:eighty_six |
| 74 | at_bar.binder | Fix the faces in his head. | check manual 10; knows:banned_face |
| 81 | at_bar.binder | Just page three. | knows:banned_face |
| 203 | at_bar.lager_out | Watch her bar. | to lager_up; watched_bar |
| 208 | at_bar.lager_out | Go round and pour himself one. | to self_pour |
| 210 | at_bar.lager_out | Back to his door. | to lager_left; poured_self |
| 220 | at_bar.self_pour | Drink it down and rinse the glass, before she's up. | check fighter:dex 12; drinks, incident:inc_drinking, pour_how |
| 229 | at_bar.self_pour | Take it round to the ledge, where she puts his. | pour_how, drinks, incident:inc_drinking |
| 233 | at_bar.self_pour | Pour it down the sink. | pour_how |
| 350 | ev_card | Lend her twenty. | cash; (lent) is read |
| 356 | ev_card | "Can she run a tab till it's back up?" | rep_staff |
| 360 | ev_card | Stay out of it. | slippers_upstairs |
| 391 | ev_owner | Give him the door's number. | owner_count, rep_owner |
| 399 | ev_owner | "Quiet." | owner_count |
| 402 | ev_owner | "Busy." | owner_count, rep_owner, rep_staff |
| 411 | ev_owner | "Poison's down." | rep_owner; (told_poison) is read |
| 414 | ev_owner | "Traps are set." | rep_owner |
| 417 | ev_owner | "I've killed {rats_killed == 1:one/a couple}." | task |
| 421 | ev_owner | "It's handled." | owner_lie, rep_owner |
| 426 | ev_owner | "Not yet." | rep_owner |
| 447 | ev_owner.turned_away | "The book says not ever." | rep_owner, rep_staff |
| 454 | ev_owner.turned_away | "She wrote it. Not you." | to carry_on; rep_owner, rep_staff |
| 462 | ev_owner.turned_away | "I'll let him in next time." | rep_owner, rep_staff |

## rats.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 56 | at_kitchen.k_opts | "The owner wants the rats dealt with." | to cook_rats |
| 58 | at_kitchen.k_opts | Look behind the walk-in. | check manual 11; to behind_walkin |
| 60 | at_kitchen.k_opts | Take the fries going soft under the heat lamp. | to take_fries |
| 62 | at_kitchen.k_opts | Take the garbage out for him. | to garbage |
| 64 | at_kitchen.k_opts | Take the milk crate out of the back door. | to kitchen_door_shut; knows:kitchen_gap, knows:keg_hole |
| 79 | at_kitchen.cook_rats | "So why hasn't anybody?" | knows:bait_office |
| 86 | at_kitchen.cook_rats | "How many are there?" | knows:rat_numbers |
| 91 | at_kitchen.cook_rats | "What would you do?" | knows:cook_advice |
| 97 | at_kitchen.cook_rats | "Table 28 feeds one." | knows:cook_fries |
| 103 | at_kitchen.cook_rats | Leave him to it. | knows:keg_hole, fries, rep_cook |
| 143 | at_kitchen.garbage | Take the brick out. | (brick_out) is read |
| 145 | at_kitchen.garbage | Leave the brick where it is. | rat_favour |
| 168 | at_kitchen.dark | Take the milk crate out and lock the back door. | kitchen_door |
| 173 | at_kitchen.dark | Take the fries left under the dead heat lamp. | fries |
| 209 | at_keg.kg_opts | The office. | to keg_office |
| 211 | at_keg.kg_opts | Look around with the flashlight. | to look |
| 213 | at_keg.kg_opts | Follow the scratching into the crawlspace. | check wrongman 12; to crawl |
| 215 | at_keg.kg_opts | Leave the fries on the third step. | to leave_fries |
| 217 | at_keg.kg_opts | Check the bait. | to check_bait |
| 219 | at_keg.kg_opts | Check the traps. | to check_traps |
| 221 | at_keg.kg_opts | Change the lager. It's been spitting foam since ten. | to change_keg, look; knows:office_seen, knows:bait_office |
| 255 | at_keg.office_opts | Note it. It goes in the book. | incident:inc_office |
| 260 | at_keg.office_opts | Wipe the mirror clean. | to straw_held; office_wiped |
| 265 | at_keg.office_opts | Take the bait. | to lay_poison |
| 267 | at_keg.office_opts | Take the traps. | to set_traps |
| 269 | at_keg.office_opts | Out of the office. | a way out: the clock |
| 277 | at_keg.straw_held | Put it in his pocket. | things:straw |
| 280 | at_keg.straw_held | Put it back on the desk, beside the clean mirror. | (straw_back) is read |
| 282 | at_keg.straw_held | Snap it and drop it in the empties. | (straw_snapped) is read |
| 291 | at_keg.lay_poison | Here in the keg room, where they live. | poison_at:keg, rep_cook |
| 298 | at_keg.lay_poison | Along the pipes behind the walk-in. | to carry_up; poison_at:kitchen, rep_cook |
| 307 | at_keg.lay_poison | In the hole in the baseboard behind table 28. | to carry_up; poison_at:t28 |
| 313 | at_keg.lay_poison | Put the lid back on. | rat_favour, rats_heard:h_lid; (lid_back) is read |
| 343 | at_keg.set_traps | Set them here in the keg room. | trap_at:keg |
| 347 | at_keg.set_traps | Set them behind the walk-in. | to carry_up; trap_at:kitchen |
| 354 | at_keg.set_traps | Set one under table 28. | to carry_up; trap_at:t28 |
| 359 | at_keg.set_traps | Put them back on the shelf. | rat_favour, rats_heard:h_lid; (traps_back) is read |
| 421 | at_keg.crawl | "No." | rats_heard:h_said_no |
| 423 | at_keg.crawl | "They're down there." | rats_heard:h_said_down |
| 442 | at_keg.knot | Put the light out and listen to the floor. | to listen_t28 |
| 444 | at_keg.knot | Reach into the gap. | check fighter:dex 13; hurt, incident:inc_hurt, rat_favour |
| 459 | at_keg.knot | Back out slowly. | fries, fries_step, rat_favour, rats_killed |
| 530 | at_keg.check_traps | Put it in the dumpster and reset the traps. | traps_reset, rep_cook |
| 538 | at_keg.check_traps | Leave it where it is. | rat_favour, rats_heard:h_left_trap |
| 568 | ev_rat.bold | Stamp on it. | check fighter:dex 11; here, rats_killed, incident:inc_rat, rats, rep_staff, knows:t28_rat |
| 591 | ev_rat.bold | Drop a pint glass over it. | check fighter:dex 12; to glass_rat; here |
| 604 | ev_rat.bold | Tell the woman in slippers it's a mouse. | check father:cha 10; here, rep_staff, slippers_both, slippers_upstairs |
| 625 | ev_rat.bold | Let it go. | knows:t28_rat |
| 635 | ev_rat.glass_rat | Take it out the back and let it go in the alley. | here, rep_cook |
| 643 | ev_rat.glass_rat | Drown it in the mop bucket. | rats_killed, rats, here, rep_cook |
| 654 | ev_rat.glass_rat | Take it down to the keg room and let it go there. | rat_favour, knows:keg_hole, here |
| 686 | ev_rat.sick | Finish it quickly. | check fighter 10; rats_killed, incident:inc_rat, here, rep_staff, rep_t28 |
| 705 | ev_rat.sick | Pick it up in a bar towel and carry it out. | incident:inc_rat, here, rep_staff |
| 714 | ev_rat.sick | Pick him up in a bar towel and give him to Scratch. | incident:inc_rat, here, rep_t28 |
| 724 | ev_rat.sick | Leave it. It won't be long. | incident:inc_rat, rep_staff, rep_t28 |
| 743 | ev_rat.who_poison | "I did." | rep_t28 |
| 747 | ev_rat.who_poison | "Owner's orders." | rep_t28 |
| 751 | ev_rat.who_poison | Say nothing. | rep_t28 |
| 772 | ev_trap_t28 | "I did." | rep_t28 |
| 776 | ev_trap_t28 | "Owner's orders." | rep_t28 |
| 779 | ev_trap_t28 | Say nothing. | rep_t28 |

## hall.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 45 | at_hall.h_opts | Check the men's. | to mens |
| 47 | at_hall.h_opts | Knock on the women's. | to womens |
| 49 | at_hall.h_opts | Knock on the single washroom. | to single |
| 51 | at_hall.h_opts | Check the single washroom. | to single_empty |
| 53 | at_hall.h_opts | Read the wall around the payphone. | to payphone |
| 55 | at_hall.h_opts | Somebody's coming down the hotel stairs. | to hivis_stairs |
| 57 | at_hall.h_opts | Kick the wedge out from under the hotel door. | hotel_door, hotel_shut_at |
| 65 | at_hall.h_opts | Go through and ask Terry to leave the door shut. | to night_clerk, vape_line; incident:inc_drugs |
| 92 | at_hall.vape_line | Put him out. Now. | fam:vape_ejected, vape_out_at, vape_returned, vape_seen, vape_at, spot:s_lot, heat(), rep_kids |
| 109 | at_hall.vape_line | Take it off him and flush it. | heat(), rep_kids |
| 117 | at_hall.vape_line | "Not in here. Not tonight." Walk away. | heat(), rep_kids |
| 124 | at_hall.vape_line | Say nothing and walk out. | heat(), incident:inc_drugs:- |
| 157 | at_hall.sister_sink | "Want me to tell him?" | fam:sister_fetched, task |
| 162 | at_hall.sister_sink | "Give him a minute." | heat() |
| 166 | at_hall.sister_sink | "Go home. He'll come or he won't." | rep_kids |
| 194 | at_hall.single | "It's the door. You all right in there?" | knows:bigman_dad |
| 206 | at_hall.single | Slide down the wall and sit on the carpet with your back to the door. | to sit_outside |
| 208 | at_hall.single | "You've got two minutes, then I open it." | to two_minutes |
| 210 | at_hall.single | Open it with a coin. | to coin |
| 212 | at_hall.single | Leave him be. | kid_ease; (left_be) is read |
| 225 | at_hall.sit_outside | Stay where you are. | pull_kid |
| 229 | at_hall.sit_outside | Go in. | kid_ease |
| 252 | at_hall.coin | "Sorry. I had to check." | kid_out, kid_at, spot:s_jukebox |
| 258 | at_hall.coin | Stay. Lean on the sink. | to kid_talk; fam:kid_opened, fam:kid_found, knows:bigman_dad |
| 273 | at_hall.kid_talk | "When did you last sleep?" | pull_kid, knows:kid_why |
| 285 | at_hall.kid_talk | {knows ? kid_why:"How's your mom?"/"What's going on?"} | pull_kid, knows:kid_why |
| 293 | at_hall.kid_talk | "Why'd they send you in, and not your sister?" | pull_kid |
| 300 | at_hall.kid_talk | "My old man drank." | to own_father |
| 303 | at_hall.kid_talk | "What were you listening to, at the door?" | pull_kid |
| 310 | at_hall.kid_talk | Give him the fries. | fries, pull_kid |
| 316 | at_hall.kid_talk | "What do you want to do?" | to kid_decides |
| 318 | at_hall.kid_talk | Leave him be. | kid_out, kid_at, spot:s_jukebox, pull_kid |
| 329 | at_hall.own_father | "Twenty years. Then he stopped." | more choices; claims:said_father_stopped |
| 332 | at_hall.own_father | "It helped everybody else." | claims:said_helped_others |
| 335 | at_hall.own_father | "No." | claims:said_didnt_help |
| 338 | at_hall.own_father | "I don't know. He died before I worked it out." | claims:said_father_dead |
| 343 | at_hall.own_father | "He worked doors. Like this." | more choices; claims:said_father_doors |
| 346 | at_hall.own_father | "No." | claims:said_not_like_him |
| 350 | at_hall.own_father | "I'm trying not to be." | claims:said_trying_not |
| 360 | at_hall.kid_decides | "I'll tell him. You don't have to." | kid_out, kid_at, spot:s_jukebox, fam:sister_fetched, task |
| 369 | at_hall.kid_decides | "You tell him. I'll stand right there." | to kid_tells |
| 371 | at_hall.kid_decides | "You tell him. On your own. You can." | to kid_tells |
| 373 | at_hall.kid_decides | "Go home and sleep. I'll make sure he knows." | to kid_leave; kid_out, fam:kid_home, fam:sister_fetched, kid_at, spot:s_truck, task, spot:s_rail, fam:dad_told, fam:dad_stayed, fam_done, rep_kids, fam:dad_went, knows:aa_wall |
| 456 | at_hall.payphone | Pick up the receiver. | picked_receiver |
| 460 | at_hall.payphone | Leave it. | (left_receiver) is read |
| 479 | at_hall.night_clerk | "Residents come down that way. I can't count them." | check father:cha 11; terry_asked |
| 488 | at_hall.night_clerk | "She says you prop it for the TV." | terry_asked, rep_staff |
| 495 | at_hall.night_clerk | Never mind. | (never_mind) is read |
| 512 | at_hall.hivis_stairs | "Leave the can and go round the front. I'll let you in." | arrivals:hivis_in, count_in, rep_staff |
| 520 | at_hall.hivis_stairs | "Fine. Leave the can." | arrivals:hivis_hotel |
| 525 | at_hall.hivis_stairs | "Back upstairs. Not tonight." | rep_owner |

## deck.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 39 | at_deck.d_opts | Stand at the rail beside him. | to cardigan |
| 41 | at_deck.d_opts | Somebody's trying the deck door from outside. | to vape_back |
| 43 | at_deck.d_opts | Stand in the air a minute. | to air |
| 45 | at_deck.d_opts | Pull the coaster out of the latch. | deck_door, rep_t28, deck_smokers, smokers_at, knows:ardagh, knows:truck, knows:mill_closing, pull_table |
| 107 | at_deck.cardigan | "How long have you been coming here?" | knows:t28_nine |
| 112 | at_deck.cardigan | "What happened to the other four?" | (four) is read |
| 118 | at_deck.cardigan | "Will you go?" | more choices |
| 122 | at_deck.cardigan | "Go." | cardigan_go |
| 126 | at_deck.cardigan | "Stay." | cardigan_go |
| 130 | at_deck.cardigan | "I don't know either." | cardigan_go |
| 134 | at_deck.cardigan | Leave him to his smoke. | cardigan_secret |
| 145 | at_deck.vape_back | "Go sit in the truck." | vape_at, spot:s_truck |
| 155 | at_deck.vape_back | Walk him round to the lot. | check fighter 10; vape_at, spot:s_truck, incident:inc_hurt |
| 164 | at_deck.vape_back | Let him back in. | fam:vape_ejected:-, vape_at, spot:s_bar, vape_backs, heat() |
| 189 | ev_deck_kids | Talk to the sister first. | fam:sister_met, knows:kid_why, knows:bigman_dad, knows:truck, here |
| 202 | ev_deck_kids | Put all three of them out. | more choices; fam:sister_met, fam:kids_waiting, rep_kids, here, knows:kid_why, knows:bigman_dad |
| 213 | ev_deck_kids | "Then I'll tell him." | fam:sister_fetched, task |
| 218 | ev_deck_kids | "Wait in the truck." | fam:told_wait, rep_kids |
| 225 | ev_deck_kids | "You came in the back. Fine. You're in now, on me." | to carry_on; fam:sister_met, fam:sister_admitted, fam:hoodie_admitted, count_in, rep_kids, here; (counted) is read |
| 238 | ev_deck_kids | Leave them. Watch. | to carry_on; fam:sister_met, fam:sister_admitted, fam:hoodie_admitted, here |
| 247 | ev_deck_kids | "I'll tell him for you." | to carry_on; fam:sister_admitted, fam:hoodie_admitted, fam:sister_fetched, task |
| 274 | at_lot | "What do you need to tell him?" | knows:kid_why, knows:bigman_dad |
| 281 | at_lot | "I'll tell him. I'll send him out." | fam:sister_fetched, task |
| 288 | at_lot | "Come in. Just you. Bring him out." | to you_said_no, goes_in; fam:kids_waiting:-, fam:sister_admitted, sister_at, spot:s_rail, count_in, rep_kids, promise_kept |
| 304 | at_lot | Look in the back seat. | knows:vape_cans |
| 314 | at_lot | Go back in. | a way out: the clock |
| 321 | at_lot.you_said_no | "I was wrong." | owned_it, rep_kids |
| 325 | at_lot.you_said_no | "I'm saying yes now." | owned_it |
| 351 | ev_vape_back | Put him out again, and pull the coaster this time. | fam:vape_ejected, vape_out_at, vape_returned, vape_seen, vape_at, spot:s_lot, deck_door, here, rep_t28 |
| 365 | ev_vape_back | Put him out again. | fam:vape_ejected, vape_out_at, vape_returned, vape_seen, vape_at, spot:s_lot, here |
| 378 | ev_vape_back | Leave him. He's back. Watch him. | heat(), rep_staff |

## closing.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 292 | clear | The big man at the pool table. | to close_pool |
| 294 | clear | GOOD SHOES, still at the bar. | to close_banned |
| 296 | clear | HI-VIS, asleep on his arms at the bar. | to close_hivis |
| 298 | clear | {slippers_upstairs:The woman from upstairs, finishing the bottle./The women from upstairs, finishing the bottle.} | to close_residents |
| 300 | clear | The full glass at the end of the bar. | to close_endbar |
| 302 | clear | Table 28. | to close_t28 |
| 304 | clear | -> lock_up | to lock_up |
| 342 | close_pool | {knows ? kid_why:Tell him about the hospital. Now./"Your daughter's {her_place()}. She's been waiting all night."} | check father:cha 11; to the_lot; fam:dad_told |
| 356 | close_pool | "We're closed. Time to go." | bigman_ease |
| 361 | close_pool | Take the cue out of his hands. | check fighter:dex 11; bigman_ease, rep_kids |
| 429 | close_pool.the_lot | Take his keys. | check father:cha 12; to keys, keys_refused |
| 437 | close_pool.the_lot | Walk him to his daughter's truck. | to walk_him |
| 439 | close_pool.the_lot | Let him go. | to drives |
| 454 | close_pool.keys_refused | Take them anyway. | check fighter 11; to keys, drives; hurt, incident:inc_hurt |
| 464 | close_pool.keys_refused | Walk him to his daughter's truck. | to walk_him |
| 466 | close_pool.keys_refused | Let him go. | to drives, to_pickup, hold_keys, clear; took_keys, fam:dad_walked, task |
| 497 | close_pool.hold_keys | Give them to his daughter. | keys_how, things:truck_keys, rep_kids |
| 504 | close_pool.hold_keys | Behind the bar, in the lost-and-found drawer. | keys_how, drawer_seen, things:truck_keys |
| 508 | close_pool.hold_keys | In his own pocket. | keys_how, things:truck_keys |
| 579 | close_banned | "You heard her." | check father:cha 11 |
| 588 | close_banned | Walk him out. | check fighter:dex 10; here, rep_t28 |
| 597 | close_banned | "One more. Then you go." | rep_staff |
| 617 | close_hivis | Wake him and walk him up. | rep_staff, case_back; (walked_up) is read |
| 628 | close_hivis | Wake him and point him at the stairs. | hivis_landing, case_back |
| 638 | close_hivis | Leave him. He lives here. | rep_staff |
| 724 | close_t28 | Tell Dennis about the dog. {late_words(wife_at)} | dog_told, rep_t28, task; (dog_late) is read |
| 736 | close_t28 | "Drink up, gentlemen." | check father:cha 11; rep_staff |
| 745 | close_t28 | "Take your time." | rep_t28 |
| 749 | close_t28 | Sit down with them for the last one. | pull_table, drinks, incident:inc_drinking, rep_t28 |
| 756 | close_t28 | "Now. All of you." | rep_t28, rep_staff |
| 772 | close_t28.secret | Say nothing. | secret_kept |
| 776 | close_t28.secret | "He was out on the deck with me." | secret_kept, rep_t28 |
| 865 | search | The deck door. | found_why:why_deck, deck_door |
| 889 | search | The hotel door. | found_why:why_hotel, hotel_door |
| 905 | search | The kitchen door. | kitchen_door |
| 910 | search | The front door, while he was away from it. | found_why:why_front |
| 924 | search | The single washroom. | found_why:why_sleeper |
| 931 | search | That's enough. Write the log. | to incident_log; rep_staff |
| 968 | incident_log.log_next | Write it down the way it happened. | logged, cocoon, rep_staff |
| 977 | incident_log.log_next | Write it so it reads better. | shaded, cocoon, rep_staff |
| 986 | incident_log.log_next | Leave it out. | left_out, cocoon, rep_staff |
| 1051 | after_hours | Drink it. | last_glass, drinks, incident:inc_drinking |
| 1055 | after_hours | Leave it standing. | last_glass |
| 1061 | after_hours | Push it back. | last_glass |
| 1072 | after_hours.water | Drink the water. | (drank_water) is read |
| 1075 | after_hours.water | Ask for a rye. | rep_staff |
| 1088 | after_hours.door_story | "You had it from Gary, on the deck. I was up in twelve." | rep_staff, claims:said_left_bad_owner, claims:said_left_something, claims:said_left_long_story, claims:said_nothing; (owned_up) is read |
| 1105 | after_hours.door_story | "The owner shorted me." | claims:said_left_bad_owner |
| 1108 | after_hours.door_story | "Something happened." | claims:said_left_something |
| 1111 | after_hours.door_story | "Long story." | claims:said_left_long_story |
| 1114 | after_hours.door_story | Say nothing. | claims:said_nothing |
| 1310 | after_hours.keys_at_two | {from_drawer:Get them out of the drawer and take them out to him./Take them out to him.} | keys_back, things:truck_keys, rep_staff |
| 1318 | after_hours.keys_at_two | Through the glass: {from_drawer:"She'll have them for you at noon."/"Noon. You'll get them at noon."} | keys_back, rep_staff |
| 1333 | after_hours.last_doorman | "Table 28 told me about the last doorman. Which one's true?" | to jacket_now; knows:lost_jacket |
| 1344 | after_hours.last_doorman | Don't ask. | (didnt_ask) is read |
| 1348 | after_hours.jacket_now | Go through the jacket's pockets. | to the_drawer; drawer_from |
| 1351 | after_hours.jacket_now | Leave it be. | to goodnight, choose, go_upstairs |
| 1367 | after_hours.choose | Go up to bed. | to go_upstairs |
| 1369 | after_hours.choose | Wait till she's gone. Then go down to the keg room. | to keg_parley |
| 1465 | keg_parley.terms | "Who are you?" | knows:endbar_dock |
| 1471 | keg_parley.terms | "What do they want?" | (want) is read |
| 1475 | keg_parley.terms | "What do I get?" | (what_get) is read |
| 1479 | keg_parley.terms | "What have they heard?" | to overheard |
| 1481 | keg_parley.terms | "I saw it. In the wall." | (saw_it) is read |
| 1485 | keg_parley.terms | "Done. Those terms." | to deal |
| 1488 | keg_parley.terms | "The step, and no poison. Not the kitchen door." | check wrongman 12; to bargain |
| 1490 | keg_parley.terms | "No. They're going." | to refuse |
| 1492 | keg_parley.terms | Tell him you'll burn them out. | to threaten |
| 1494 | keg_parley.terms | "I'll think about it." | to think, after_parley, latch, go_upstairs; parley, rats, task, terms_door |
| 1646 | keg_parley.latch | Put the back door on the latch, the way he said. | terms_kept, kitchen_door |
| 1651 | keg_parley.latch | Leave it. Go up. | terms_kept |
| 1675 | go_upstairs.landing | Get him up the rest of the way to eleven. | hivis_landing |
| 1681 | go_upstairs.landing | Step over him. | (stepped_over) is read |
| 1771 | voices_at_night | Let THE TABLE in. | to let_voice_in |
| 1773 | voices_at_night | Let THE KID in. | to let_voice_in |
| 1775 | voices_at_night | Sleep. | to ledger |
| 1858 | let_voice_in | Put THE FIGHTER out. | psyche |
| 1860 | let_voice_in | Put THE MANUAL out. | psyche |
| 1862 | let_voice_in | Put THE WRONG MAN out. | psyche |
| 1864 | let_voice_in | Put THE TABLE out. | psyche |
| 1866 | let_voice_in | Put THE FATHER out. | psyche |
| 1869 | let_voice_in | Nobody. Keep the room as it is. | to voices_at_night.vs |

## hand.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 160 | reads_shirt | A man who needs a shirt to tell them hasn't got the job yet. | to back; read |
| 162 | reads_shirt | Security workers must be identifiable to the public while on duty. The licensee supplies the uniform. | to back; read |
| 164 | reads_shirt | Too small across the shoulders. You can't swing in it. Maybe that's the idea. | to back; read |
| 166 | reads_shirt | In the story, the wrong man came to the door in one of these. He said he was the new one. | to back; read |
| 173 | reads_flashlight | Right pocket, every door I ever worked. You don't go looking for it when you need it. | to back; read |
| 175 | reads_flashlight | A flashlight is an inspection tool. Used to strike a person, it is a weapon, and the security worker may be charged. | to back; read |
| 177 | reads_flashlight | Steel, with the weight at the end. It's a club that happens to have a light in it. | to back; read |
| 179 | reads_flashlight | In the story, the doorman shone his light into the dark down there, and something shone it back. | to back; read |
| 181 | reads_flashlight | Look at him! Like the cops! | to back; read |
| 183 | reads_flashlight | put a licence under one and the hologram like jumps. you can see if it's real | to back; read |
| 190 | reads_fifty | That's not a tip. That's a leash. | to back; read |
| 192 | reads_fifty | Gratuities from patrons are accepted only where the licensee's policy allows them. Ask before you keep it. | to back; read |
| 194 | reads_fifty | He put his hand in your pocket and you let him. Nobody gets that close. | to back; read |
| 196 | reads_fifty | In the story, the doorman kept the first fifty. After that nobody had to ask him for anything. | to back; read |
| 198 | reads_fifty | On us! He's one of us now! On us! | to back; read |
| 200 | reads_fifty | my dad does that. folds it small so you don't see how much till after | to back; read |
| 207 | reads_straw | I never touched that. I had the rye. Every man picks his poison and calls the other man's dirty. | to back; read |
| 209 | reads_straw | Possession of a controlled substance, or of anything carrying one, is an offence. A licence is no exemption. | to back; read |
| 211 | reads_straw | Two inches. Somebody downstairs has done this a lot. | to back; read |
| 213 | reads_straw | In the story, they found it on him after. Nobody remembered he'd been the one to clean up. | to back; read |
| 215 | reads_straw | The office! Like the mill office at Christmas! | to back; read |
| 217 | reads_straw | that's kyle's. or it's whoever kyle buys off | to back; read |
| 224 | reads_keys | That's a man's pride in your hand. Give it to his girl, not to him. Not tonight. | to back; read |
| 226 | reads_keys | If he drives, it's on the Sov. Keys held by staff are held for the licensee, and so is anything that happens after. | to back; read |
| 228 | reads_keys | Close your hand on them. Now they're a fist. | to back; read |
| 230 | reads_keys | A rabbit's foot off a kid's hockey bag, on a ring with a Ford key. In the story, that's the part they find in the ditch. | to back; read |
| 232 | reads_keys | He'll be back for those! Two in the morning, every time! Every time! | to back; read |
| 234 | reads_keys | the foot's off my hockey bag. he took it off when i quit | to back; read |
| 241 | reads_pint | Behind somebody's back. That's how I drank for twenty years. Behind somebody's back. | to back; read |
| 243 | reads_pint | Staff may not serve themselves. Every drink poured on the premises is rung through the till. | to back; read |
| 245 | reads_pint | Cold, and it's yours. Drink it before she's up the stairs. | to back; read |
| 247 | reads_pint | In the story, the doorman was behind the bar with a glass in his hand when the wrong man walked in. | to back; read |
| 249 | reads_pint | Atta boy! Never wait to be served! Never! | to back; read |
| 251 | reads_pint | she'd have poured you one if you asked. that's the thing | to back; read |
| 258 | reads_float | He took what he was owed and left the rest where anybody could take it. An honest man, or one who wanted it known he was. | to back; read |
| 260 | reads_float | Cash discrepancies are reported to management in writing, the same night. | to back; read |
| 262 | reads_float | Two hundred and eight dollars nobody's counted since October. | to back; read |
| 264 | reads_float | In the story, the money's still there after. That's how they knew he didn't leave on his own. | to back; read |
| 266 | reads_float | The float! Told you! I was sitting right there! | to back; read |
| 268 | reads_float | he could've taken all of it. he didn't. that's kind of the whole thing | to back; read |
| 275 | reads_mat | A man counts what he's afraid of. I counted drinks for twenty years. | to back; read |
| 277 | reads_mat | Pest sightings: date, location, and a report to the licensee. He did two of the three. | to back; read |
| 279 | reads_mat | That's not a count. That's an army coming. | to back; read |
| 281 | reads_mat | In the story, the doorman who saw it drew it once, so he could stop seeing it. It didn't work. | to back; read |
| 283 | reads_mat | Scratch was right! The big rat! He's never right and he was right! | to back; read |
| 285 | reads_mat | everything doubles if you leave it alone long enough | to back; read |
| 292 | reads_tickets | Two tickets and one jacket. Somebody didn't get on that boat. | to back; read |
| 294 | reads_tickets | Personal effects left on the premises are held thirty days, then disposed of. It's been thirty-three. | to back; read |
| 296 | reads_tickets | A woman. A man walks out over a woman, not over money. | to back; read |
| 298 | reads_tickets | In the story, he bought two and waited at the terminal, and she never came. Or she waited, and he never did. | to back; read |
| 300 | reads_tickets | A woman! What did he say? A woman! | to back; read |
| 302 | reads_tickets | the last boat's eleven fifteen. you miss it you're here till morning | to back; read |
| 310 | reads_card | He took the card and let the boy in anyway. That's the whole job, done backwards. | to back; read |
| 312 | reads_card | Identification taken at the door is surrendered to police or returned to the issuing office. It is not kept. | to back; read |
| 314 | reads_card | Eighteen. Old enough to sign up. Not old enough for a beer. | to back; read |
| 316 | reads_card | In the story, the wrong man's a boy, at first. That's why they let him in. | to back; read |
| 318 | reads_card | That's the Macaulay kid! In here every Friday till they caught him! | to back; read |
| 320 | reads_card | he was the year under me. everybody knew he got in here | to back; read |
| 327 | reads_book | I never read a book about the door. You learn the door on the door. | to back; read |
| 329 | reads_book | Force must be proportionate. Restraint techniques are to be taught by a qualified instructor. | to back; read |
| 331 | reads_book | Wrist locks. Pretty. You'll be on your back while you're being pretty. | to back; read |
| 333 | reads_book | In the story, the doorman learned to put a man down without hurting him. It was the one time he should have hurt him. | to back; read |
| 335 | reads_book | Karate! Look at him! The Karate Kid! | to back; read |
| 337 | reads_book | my sister did that for like a year. she can still do the wrist thing | to back; read |

## drawer.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 55 | the_drawer.dr_opts | Go through the jacket's pockets. | to jacket |
| 57 | the_drawer.dr_opts | The paperback under the glove. | to book |
| 59 | the_drawer.dr_opts | Shut the drawer. | to shut, after_hours.goodnight, at_bar.opts, right_pocket; jacket_done |
| 88 | the_drawer.right_pocket | Give it to her. | float_how, things:float_bag, rep_staff |
| 96 | the_drawer.right_pocket | Put it back in the jacket. | float_how, things:float_bag |
| 100 | the_drawer.right_pocket | Take the money. | float_how, cash |
| 117 | the_drawer.left_pocket | Keep it. | things:beer_mat |
| 120 | the_drawer.left_pocket | Put it back in the jacket. | things:beer_mat |
| 131 | the_drawer.inside_pocket | Keep them. | things:ferry_tickets |
| 134 | the_drawer.inside_pocket | Put them back. | things:ferry_tickets |
| 137 | the_drawer.inside_pocket | Show her. | showed_her:ferry_tickets, things:ferry_tickets |
| 157 | the_drawer.licence | Keep it. | things:minor_card |
| 160 | the_drawer.licence | Put it back. | things:minor_card |
| 163 | the_drawer.licence | Show her. | things:minor_card |
| 179 | the_drawer.jacket_back | Fold it and put it back at the bottom of the drawer. | jacket_how |
| 182 | the_drawer.jacket_back | Take it up to twelve, after. | jacket_how, things:last_jacket |
| 200 | the_drawer.book | Keep it. | things:aikido_book |
| 203 | the_drawer.book | Leave it under the glove. | things:aikido_book |
| 217 | drawer_takes | Take {the_thing(t)} out of the drawer. | to back; in_inside |
| 227 | drawer_puts | Put {the_thing(t)} in the drawer. | to back; in_drawer |
