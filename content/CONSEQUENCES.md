# What every choice changes

Written by `node tools/audit.mjs --map` from the Ink. Each choice, where it is, and what it changes that the night reads later: state (a VAR, or a LIST item), a labelled choice whose visit count is read, a task in his notes, a check, or a different scene. "time" is pass() and what the clock moves with it. Nothing here is hand-written; rebuild it after changing the Ink.


## prologue.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 44 | prologue.before_eight | "Where do you want me?" | to where_want |
| 47 | prologue.before_eight | Count the room. | to count_first |
| 49 | prologue.before_eight | Take the stool by the door. | to the_truck; here, knows:coaster, knows:kitchen_gap, knows:hotel_gap |
| 67 | prologue.where_want | "What happened to the last doorman?" | knows:old_doorman; (asked_last) is read |
| 73 | prologue.where_want | "Anyone I should know about?" | (asked_anyone) is read |
| 78 | prologue.where_want | "Okay." | to before_eight |
| 80 | prologue.where_want | Leave her to the limes. | to before_eight |

## door.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 70 | door_quiet | Stay on the door. | to at_door |
| 117 | door_hoodie.read | Take the phone and look at the photo. | knows:kid_legal; (took) is read |
| 125 | door_hoodie.read | Swipe to the next photo. | knows:kid_photo, rep_kids, kid_ease; (swiped) is read |
| 136 | door_hoodie.read | Look at him, not the phone. | check father 8; father_misread, psyche |
| 149 | door_hoodie.read | Look past him at the truck. | check wrongman 8; knows:truck |
| 161 | door_hoodie.read | "Rough night to be out in." | fam:hoodie_rapport |
| 172 | door_hoodie.read | "Take the earbuds out." | fam:earbuds_out |
| 182 | door_hoodie.read | "Where's the card?" | knows:card_in_truck |
| 188 | door_hoodie.read | "Who's in the truck?" | knows:truck |
| 195 | door_hoodie.read | "What are you here for? It's a Wednesday." | more choices |
| 199 | door_hoodie.read | "Who?" | kid_ease |
| 207 | door_hoodie.read | Let it go. | kid_ease |
| 211 | door_hoodie.read | Scan the phone. | phone_scans, scans:scan_phone, kid_ease |
| 225 | door_hoodie.read | "In you go." | to admit |
| 227 | door_hoodie.read | "Not without the card." | to refuse |
| 229 | door_hoodie.read | "Go get the card. I'll be here." | to fetch |
| 231 | door_hoodie.read | "You can come in. On conditions." | to conditions; fam:hoodie_admitted, kid_at, spot:s_jukebox, count_in, incident:inc_no_id, rep_kids, rep_staff, fam:hoodie_refused, incident:inc_kid_refused, spot:s_truck, knows:kid_legal, knows:card_in_truck, scans:scan_card, knows:truck |
| 297 | door_hoodie.conditions | "You're in. No drinking tonight." | kid_terms |
| 301 | door_hoodie.conditions | "You're in. You stay where I can see you." | kid_terms |
| 305 | door_hoodie.conditions | "You're in if your sister comes in with you." | kid_terms, knows:truck |
| 359 | ev_sister.sister_opts | Look from the card to her face. | knows:bigman_dad |
| 370 | ev_sister.sister_opts | "Get who?" | knows:bigman_dad |
| 376 | ev_sister.sister_opts | "What's it about?" | knows:kid_why, knows:bigman_dad |
| 388 | ev_sister.sister_opts | Look at the boyfriend. | check fighter 6; knows:vape_read, knows:vape_misread |
| 399 | ev_sister.sister_opts | "ID for him too." | knows:vape_no_id |
| 407 | ev_sister.sister_opts | "He's not here." | to sister_lie |
| 409 | ev_sister.sister_opts | "You can go in. He can't." | to sister_alone |
| 411 | ev_sister.sister_opts | "I'll go get him for you." | to sister_fetch |
| 413 | ev_sister.sister_opts | "All three of you, in. Find him and go." | to sister_all |
| 415 | ev_sister.sister_opts | "Both of you, in. Find him and go." | to sister_all |
| 417 | ev_sister.sister_opts | "Nobody else tonight." | to sister_no, sister_brother; promise_kept, fam:sister_refused, fam:kids_waiting, sister_at, spot:s_truck, vape_at, incident:inc_kid_refused, rep_kids, fam:sister_admitted, spot:s_rail, count_in |
| 462 | ev_sister.sister_brother | "Get him." | fam:hoodie_admitted, kid_at, spot:s_jukebox, count_in, rep_kids, scans:scan_card, knows:kid_legal, incident:inc_no_id, rep_staff |
| 478 | ev_sister.sister_brother | "If he brings the actual card." | fam:hoodie_admitted, knows:card_in_truck, knows:kid_legal, scans:scan_card, kid_at, spot:s_jukebox, count_in, rep_kids, rep_staff |
| 492 | ev_sister.sister_brother | "Just you." | fam:kid_kept_out, rep_kids, fam:sister_admitted, incident:inc_no_id, promise_kept, sister_at, spot:s_rail, vape_at, spot:s_bar, fam:hoodie_admitted, kid_at, spot:s_jukebox, count_in, scans:scan_card, knows:kid_legal, rep_staff, fam:sister_fetched, sister_wait_at, spot:s_vestibule, spot:s_truck, task, fam:sister_refused, fam:kids_waiting, incident:inc_kid_refused |
| 590 | door_hivis | Count his drinks. | check father 6 |
| 599 | door_hivis | Signs of intoxication. | check manual 6 |
| 608 | door_hivis | "Where are you coming from?" | knows:hivis_room, knows:hivis_upstairs, knows:mill_closing |
| 618 | door_hivis | "You can't bring that in." | knows:hivis_upstairs; (no_beer) is read |
| 626 | door_hivis | "Go on in." | arrivals:hivis_in, count_in, incident:inc_hivis, rep_staff |
| 640 | door_hivis | "Leave the beer with me and go on in." | arrivals:hivis_in, arrivals:hivis_cond, count_in, rep_staff |
| 650 | door_hivis | "Take it up to your room. You can come down after." | arrivals:hivis_out |
| 659 | door_hivis | "Not tonight. You've had enough." | arrivals:hivis_out, knows:hivis_upstairs, incident:inc_hivis, arrivals:hivis_hotel |
| 701 | door_banned.place | Place the face. | check manual 8; to known, unknown; knows:banned_face |
| 711 | door_banned.place | Let it go. | to unknown |
| 714 | door_banned.place | Hold the licence up by his face. | to recognised, known; knows:banned_face |
| 727 | door_banned.unknown | Scan the licence. | scans:scan_goodshoes |
| 733 | door_banned.unknown | "Been here before?" | (asked_before) is read |
| 737 | door_banned.unknown | Look at him again, harder. | check manual 8; to known; knows:banned_face |
| 748 | door_banned.unknown | Hold the licence up by his face. | to recognised |
| 750 | door_banned.unknown | "Go ahead." | to let_in |
| 752 | door_banned.unknown | "Give me a second." Go check the binder. | to known; knows:banned_face |
| 759 | door_banned.unknown | "Give me a second." Ask the bartender. | to known; knows:banned_face, knows:eighty_six, rep_staff |
| 780 | door_banned.known | "What did you do?" | knows:banned_story |
| 786 | door_banned.known | "I'll call the owner." | owner_missed |
| 792 | door_banned.known | "Not tonight. Not any night." | to turn_away |
| 794 | door_banned.known | "The binder says no. The binder wins." | to turn_away |
| 796 | door_banned.known | "I hear she'd have you shot. So, no." | to turn_away |
| 798 | door_banned.known | "One drink. You sit where I can see you." | arrivals:banned_in, banned_one, count_in, incident:inc_banned, rep_staff, rep_owner |
| 812 | door_banned.known | "Go ahead." | to let_in; arrivals:banned_in, count_in, incident:inc_banned, rep_staff, rep_owner, arrivals:banned_out |
| 857 | ev_banned_inside | Walk him out quietly. | check father 8; rep_staff, rep_t28, arrivals:banned_out |
| 874 | ev_banned_inside | Put him out. | check fighter 6; rep_staff, incident:inc_fight, bar_scuffle, rep_t28, arrivals:banned_out |
| 889 | ev_banned_inside | "He says the owner lifted it." | knows:binder_hers |
| 894 | ev_banned_inside | Leave him. It's not worth the scene. | rep_staff, arrivals:banned_in |
| 908 | ev_one_drink | Walk him out. One was the deal. | check father 7; banned_held, arrivals:banned_out, rep_staff, rep_t28 |
| 925 | ev_one_drink | "That's the last one, then." | banned_held, rep_staff |
| 933 | ev_one_drink | Let it go. He's no trouble. | banned_held, rep_staff |
| 960 | door_wife | "Which one's Dennis?" | check manual 6 |
| 970 | door_wife | "He's not here." | arrivals:wife_lied, knows:dennis, rep_t28, task |
| 981 | door_wife | "I'll tell him you're here." | arrivals:wife_told, knows:dennis, rep_t28 |
| 993 | door_wife | "Go on in. He's by the window." | arrivals:wife_in, knows:dennis, incident:inc_wife, rep_t28 |

## floor.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 13 | hub | {door_label()} | to at_door |
| 16 | hub | {count_label()} | to count_room |
| 18 | hub | {t28_label()} | to at_t28 |
| 21 | hub | {pool_label()} | to at_pool |
| 24 | hub | {bar_label()} | to at_bar |
| 27 | hub | {hall_label()} | to at_hall |
| 30 | hub | {kitchen_label()} | to at_kitchen |
| 33 | hub | Go down to the keg room. | to at_keg |
| 36 | hub | {deck_label()} | to at_deck |
| 39 | hub | Go out to the pickup in the lot. | to at_lot |
| 50 | moves | The floor | a way out: the clock |
| 53 | moves | {door_away >= 30:Back on the door/The door} | to walk, at_door |
| 55 | moves | Count the room | to walk, count_room |
| 57 | moves | Table 28 | to walk, at_t28 |
| 59 | moves | The pool table | to walk, at_pool |
| 61 | moves | The bar | to walk, at_bar |
| 63 | moves | The back hall | to walk, at_hall |
| 65 | moves | The kitchen | to walk, at_kitchen |
| 67 | moves | The keg room | to walk, at_keg |
| 69 | moves | The deck | to walk, at_deck |
| 71 | moves | The pickup in the lot | to walk, at_lot |
| 244 | count_body | Heads. | last_count |
| 264 | count_body | Faces. | last_count, knows:endbar_seen |
| 278 | count_body | The doors. | to doors |
| 283 | count_body | Hands. | check fighter 7; last_count, knows:pool_lefty, knows:vape_read, knows:vape_misread:- |
| 304 | count_body | Glasses. | check manual 7; last_count, knows:pool_hustle; (count_glasses) is read |
| 318 | count_body | That's enough counting. | a way out: the clock |
| 351 | doors | Pull the coaster out of the deck door. | deck_door, rep_t28 |
| 358 | doors | Shut the kitchen door. | to kitchen_door_shut |
| 362 | doors | Kick the wedge out from under the hotel door. | hotel_door, hotel_shut_at |
| 371 | doors | Leave them. | doors_left:left_deck, doors_left:left_kitchen, doors_left:left_hotel |

## table28.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 32 | at_t28.where_from | "Up island." | claims:said_up_island, rep_t28 |
| 38 | at_t28.where_from | "I worked a door in the city. Ten years." | more choices; claims:said_city_door, rats_heard:h_city |
| 42 | at_t28.where_from | "You wouldn't know it." | claims:said_city_unnamed |
| 46 | at_t28.where_from | "The kind with a line outside." | claims:said_city_line |
| 52 | at_t28.where_from | "Around." | claims:said_around |
| 57 | at_t28.where_from | "My father worked doors." | more choices; claims:said_father, rats_heard:h_father |
| 64 | at_t28.where_from | "Up island. A long time ago." | more choices; father_named, rep_t28 |
| 66 | at_t28.where_from | Tell them. | father_named, rep_t28 |
| 73 | at_t28.where_from | "Doesn't matter." | rep_t28 |
| 76 | at_t28.where_from | "All over." | rep_t28 |
| 84 | at_t28.offer | Sit down. | to sit |
| 86 | at_t28.offer | "I'm working." | to standing; rep_t28 |
| 93 | at_t28.offer | Stay standing, but stay. | to standing; pull_table, rep_t28 |
| 106 | at_t28.sit | Drink it. | drinks, incident:inc_drinking, pull_table, rep_t28 |
| 113 | at_t28.sit | Nurse it. | nursed, rat_favour |
| 121 | at_t28.sit | Push it back to the middle of the table. | rep_t28 |
| 134 | at_t28.stories | "What happened to the last doorman?" | knows:doorman_stories |
| 146 | at_t28.stories | Something moves under the table. | to walter_intro |
| 148 | at_t28.stories | "How long has he been coming to this table?" | rats_heard:h_walter, rep_t28 |
| 156 | at_t28.stories | Stay for another. | to another |
| 158 | at_t28.stories | Get up. | knows:t28_rat, knows:walter_name |
| 178 | at_t28.walter_intro | Leave Walter alone. | rats_heard:h_leave_walter, rep_t28, knows:keg_hole |
| 184 | at_t28.walter_intro | "The owner wants them gone." | rats_heard:h_owner_rats, knows:keg_hole |
| 193 | at_t28.walter_intro | Put a boot on him. | check fighter 8; rats_heard:h_boot, walter, rats, rep_t28, incident:inc_rat, cash, knows:keg_hole |
| 253 | at_t28.tip_offer | Keep it. | cash, rep_t28 |
| 257 | at_t28.tip_offer | Give it back. | rep_t28 |
| 261 | at_t28.tip_offer | Put it in the bartender's jar on the way past. | rep_staff |
| 273 | at_t28.standing | "Anything you need, you let me know." | rep_t28 |
| 276 | at_t28.standing | "You're over the limit. All of you." | check manual 6; to cut_off |
| 278 | at_t28.standing | "What do you know about the rats?" | rats_heard:h_no_rats, knows:t28_rat |
| 285 | at_t28.standing | Leave them to it. | (left_standing) is read |
| 330 | at_t28.again | Sit down with them. | to sit, another |
| 336 | at_t28.again | Ask after Walter. | to again_loop; rats_heard:h_walter |
| 347 | at_t28.again | Put the basket of fries under the table for Walter. | to again_loop; fries, rat_favour, rep_t28 |
| 356 | at_t28.again | "How's everybody doing?" | to again_loop; how_doing, rep_t28 |
| 386 | at_t28.again | Tell Dennis about the dog. | to again_loop; dog_told, rep_t28, task |
| 444 | ev_wife_inside | Go over. | wife_stopped, rep_t28 |
| 452 | ev_wife_inside | Leave it. She's not trouble. | (let_her) is read |

## pool.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 73 | at_pool.opts | Watch them play. | to watch |
| 75 | at_pool.opts | Tell the big man about the hospital. | to tell |
| 77 | at_pool.opts | Tell the big man his daughter's {sister_at == s_vestibule:at the door/out in the lot}. | to tell |
| 79 | at_pool.opts | Talk to the big man. | to talk |
| 81 | at_pool.opts | Put twenty on the next game. | to play |
| 83 | at_pool.opts | The kid by the jukebox. | to kid_jukebox, watch_again; heat(), knows:pool_lefty |
| 96 | at_pool.watch | Read the game. | check father 8; knows:pool_hustle |
| 106 | at_pool.watch | Leave it. | heat() |
| 131 | at_pool.talk | "You're a regular?" | (asked_regular) is read |
| 134 | at_pool.talk | "You're paying him, not playing him." | knows:transmission, heat() |
| 143 | at_pool.talk | Ask how his night's going. | check father 8; to favour; knows:bigman_dad |
| 158 | at_pool.talk | Leave him to his game. | a way out: the clock |
| 163 | at_pool.favour | "All right." | promised_bigman |
| 167 | at_pool.favour | Say nothing. | promised_bigman |
| 170 | at_pool.favour | "Depends who's asking." | bigman_ease |
| 180 | at_pool.play | Play to win. | check fighter 8; cash |
| 190 | at_pool.play | Play to lose. | bigman_ease, cash |
| 198 | at_pool.play | "No." | claims:said_no_kids |
| 202 | at_pool.play | "Not that I know of." | claims:said_maybe_kids |
| 205 | at_pool.play | "Do you?" | claims:said_asked_back |
| 231 | at_pool.kid_jukebox | Stand next to him and say nothing. | fam:kid_found, kid_at, spot:s_single, knows:bigman_dad, pull_kid |
| 250 | at_pool.kid_jukebox | "Who are you looking for?" | fam:kid_found, kid_at, spot:s_single |
| 255 | at_pool.kid_jukebox | "That your dad?" | check wrongman 8; knows:bigman_dad, pull_kid, fam:kid_found, kid_at, spot:s_single |
| 278 | at_pool.tell | Tell him right here, at the table. | check father 10; to told; heat() |
| 281 | at_pool.tell | "Got a second? Over here." | check father 8; to told |
| 283 | at_pool.tell | "Your daughter's {her_place()}." Just that. | check father 7; to told, went, blew_up, stayed, ev_pool.fight; fam:dad_told, fam:dad_went, fam_done, task, rep_kids, rep_staff, fam:dad_stayed, fam:kids_waiting:-, fam:pool_fight, incident:inc_fight |
| 439 | ev_pool.fight | Get between them. | check fighter 8; to after_fight; hurt, incident:inc_hurt |
| 452 | ev_pool.fight | Take the boyfriend out first. | check fighter 6; to after_fight; fam:vape_ejected, vape_out_at, vape_returned, vape_seen, vape_at, spot:s_lot, hurt, incident:inc_hurt |
| 469 | ev_pool.fight | "Everybody stop." | check father 10; to after_fight; hurt, incident:inc_hurt |
| 483 | ev_pool.fight | Wait one more second to see who starts it. | check wrongman 8; to after_fight, call_it, sort_out; incident:inc_hurt |
| 516 | ev_pool.call_it | Call it. | rep_owner, police_called, police_at, incident:inc_police |
| 525 | ev_pool.call_it | "Don't. I've got it." | rep_owner, name_on_log |
| 533 | ev_pool.sort_out | Put the big man out. | fam:dad_ejected, fam_done, fam:dad_went, fam:dad_walked, rep_t28 |
| 554 | ev_pool.sort_out | Put the kids out. All of them. | fam:kids_waiting, rep_kids |
| 568 | ev_pool.sort_out | Everybody who was in that, out. | fam:dad_ejected, fam:all_out, fam:dad_went, fam_done, rep_t28, rep_staff |
| 585 | ev_pool.sort_out | Sit the big man down and get him a coffee. | check father 8; fam:dad_went, fam_done, rep_staff, rep_kids, fam:dad_stayed, fam:kids_waiting |
| 644 | ev_police | Tell her the way it happened. | told_police, rep_staff |
| 655 | ev_police | Tell her less than that. | told_police, cocoon |
| 664 | ev_police | "She called it. Ask her." | told_police, rep_staff |

## bar.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 25 | at_bar.opts | Read the binder under the till. | to binder |
| 27 | at_bar.opts | "Anything I should know about this place?" | to know |
| 29 | at_bar.opts | "Who's the old man at the end?" | to who_endbar |
| 31 | at_bar.opts | "What's the story with the rats?" | to rats_talk |
| 33 | at_bar.opts | "How long have you worked here?" | to how_long |
| 35 | at_bar.opts | "What do I call you?" | to name |
| 37 | at_bar.opts | {drinks == 0:"Pour me one."/"Another."} | to shift_drink |
| 39 | at_bar.opts | Go and stand by the old man at the end of the bar. | to endbar; knows:eighty_six |
| 49 | at_bar.binder | Fix the faces in his head. | check manual 6; knows:banned_face |
| 56 | at_bar.binder | Just page three. | knows:banned_face |
| 197 | ev_card | Lend her twenty. | cash; (lent) is read |
| 203 | ev_card | "Can she run a tab till it's back up?" | rep_staff |
| 207 | ev_card | Stay out of it. | slippers_upstairs |
| 233 | ev_owner | Give him the number on the clicker. | owner_count, rep_owner |
| 243 | ev_owner | "Quiet." | owner_count |
| 246 | ev_owner | "Busy." | owner_count, rep_owner, rep_staff |
| 255 | ev_owner | "Poison's down." | rep_owner; (told_poison) is read |
| 258 | ev_owner | "Traps are set." | rep_owner |
| 261 | ev_owner | "I've killed {rats_killed == 1:one/a couple}." | task |
| 265 | ev_owner | "It's handled." | owner_lie, rep_owner |
| 270 | ev_owner | "Not yet." | rep_owner |
| 291 | ev_owner.turned_away | "The book says not ever." | rep_owner, rep_staff |
| 298 | ev_owner.turned_away | "She wrote it. Not you." | rep_owner, rep_staff |
| 306 | ev_owner.turned_away | "I'll let him in next time." | rep_owner, rep_staff |

## rats.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 56 | at_kitchen.k_opts | "The owner wants the rats dealt with." | to cook_rats |
| 58 | at_kitchen.k_opts | Look behind the walk-in. | check manual 7; to behind_walkin |
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
| 208 | at_keg.kg_opts | The office. | to office |
| 210 | at_keg.kg_opts | Look around with the flashlight. | to look |
| 212 | at_keg.kg_opts | Follow the scratching into the crawlspace. | check wrongman 8; to crawl |
| 214 | at_keg.kg_opts | Leave the fries on the third step. | to leave_fries |
| 216 | at_keg.kg_opts | Check the bait. | to check_bait |
| 218 | at_keg.kg_opts | Check the traps. | to check_traps |
| 220 | at_keg.kg_opts | Change the lager. It's been spitting foam since ten. | to change_keg; knows:office_seen, knows:bait_office |
| 248 | at_keg.office_opts | Note it. It goes in the book. | incident:inc_office |
| 253 | at_keg.office_opts | Wipe the mirror clean. | office_wiped |
| 258 | at_keg.office_opts | Take the bait. | to lay_poison |
| 260 | at_keg.office_opts | Take the traps. | to set_traps |
| 262 | at_keg.office_opts | Out of the office. | a way out: the clock |
| 270 | at_keg.lay_poison | Here in the keg room, where they live. | poison_at:keg, rep_cook |
| 277 | at_keg.lay_poison | Along the pipes behind the walk-in. | to carry_up; poison_at:kitchen, rep_cook |
| 286 | at_keg.lay_poison | In the hole in the baseboard behind table 28. | to carry_up; poison_at:t28 |
| 292 | at_keg.lay_poison | Put the lid back on. | rat_favour, rats_heard:h_lid; (lid_back) is read |
| 322 | at_keg.set_traps | Set them here in the keg room. | trap_at:keg |
| 326 | at_keg.set_traps | Set them behind the walk-in. | to carry_up; trap_at:kitchen |
| 333 | at_keg.set_traps | Set one under table 28. | to carry_up; trap_at:t28 |
| 338 | at_keg.set_traps | Put them back on the shelf. | rat_favour, rats_heard:h_lid; (traps_back) is read |
| 397 | at_keg.crawl | "No." | rats_heard:h_said_no |
| 399 | at_keg.crawl | "They're down there." | rats_heard:h_said_down |
| 418 | at_keg.knot | Put the light out and listen to the floor. | to listen_t28 |
| 420 | at_keg.knot | Reach into the gap. | check fighter 9; hurt, incident:inc_hurt, rat_favour |
| 435 | at_keg.knot | Back out slowly. | fries, fries_step, rat_favour, rats_killed |
| 506 | at_keg.check_traps | Put it in the dumpster and reset the traps. | traps_reset, rep_cook |
| 514 | at_keg.check_traps | Leave it where it is. | rat_favour, rats_heard:h_left_trap |
| 544 | ev_rat.bold | Stamp on it. | check fighter 7; rats_killed, incident:inc_rat, rats, rep_staff, knows:t28_rat |
| 566 | ev_rat.bold | Drop a pint glass over it. | check fighter 8; to glass_rat |
| 578 | ev_rat.bold | Tell the woman in slippers it's a mouse. | check father 6; rep_staff, slippers_both, slippers_upstairs |
| 598 | ev_rat.bold | Let it go. | knows:t28_rat |
| 608 | ev_rat.glass_rat | Take it out the back and let it go in the alley. | rep_cook |
| 615 | ev_rat.glass_rat | Drown it in the mop bucket. | rats_killed, rats, rep_cook |
| 625 | ev_rat.glass_rat | Take it down to the keg room and let it go there. | rat_favour, knows:keg_hole |
| 656 | ev_rat.sick | Finish it quickly. | check fighter 6; rats_killed, incident:inc_rat, rep_staff, rep_t28 |
| 674 | ev_rat.sick | Pick it up in a bar towel and carry it out. | incident:inc_rat, rep_staff |
| 681 | ev_rat.sick | Pick him up in a bar towel and give him to Scratch. | incident:inc_rat, rep_t28 |
| 688 | ev_rat.sick | Leave it. It won't be long. | incident:inc_rat, rep_staff, rep_t28 |
| 707 | ev_rat.who_poison | "I did." | rep_t28 |
| 711 | ev_rat.who_poison | "Owner's orders." | rep_t28 |
| 715 | ev_rat.who_poison | Say nothing. | rep_t28 |
| 736 | ev_trap_t28 | "I did." | rep_t28 |
| 740 | ev_trap_t28 | "Owner's orders." | rep_t28 |
| 743 | ev_trap_t28 | Say nothing. | rep_t28 |

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
| 471 | at_hall.night_clerk | "Residents come down that way. I can't count them." | check father 7; terry_asked |
| 480 | at_hall.night_clerk | "She says you prop it for the TV." | terry_asked, rep_staff |
| 487 | at_hall.night_clerk | Never mind. | (never_mind) is read |
| 504 | at_hall.hivis_stairs | "Leave the can and go round the front. I'll count you in." | arrivals:hivis_in, count_in, rep_staff |
| 512 | at_hall.hivis_stairs | "Fine. Leave the can." | arrivals:hivis_hotel |
| 517 | at_hall.hivis_stairs | "Back upstairs. Not tonight." | rep_owner |

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
| 155 | at_deck.vape_back | Walk him round to the lot. | check fighter 6; vape_at, spot:s_truck, incident:inc_hurt |
| 164 | at_deck.vape_back | Let him back in. | fam:vape_ejected:-, vape_at, spot:s_bar, vape_backs, heat() |
| 190 | ev_deck_kids | Talk to the sister first. | fam:sister_met, knows:kid_why, knows:bigman_dad, knows:truck |
| 202 | ev_deck_kids | Put all three of them out. | more choices; fam:sister_met, fam:kids_waiting, rep_kids, knows:kid_why, knows:bigman_dad |
| 212 | ev_deck_kids | "Then I'll tell him." | fam:sister_fetched, task |
| 217 | ev_deck_kids | "Wait in the truck." | fam:told_wait, rep_kids |
| 224 | ev_deck_kids | "You came in the back. Fine. Now you're counted." | fam:sister_met, fam:sister_admitted, fam:hoodie_admitted, count_in, rep_kids; (counted) is read |
| 236 | ev_deck_kids | Leave them. Watch. | fam:sister_met, fam:sister_admitted, fam:hoodie_admitted |
| 244 | ev_deck_kids | "I'll tell him for you." | fam:sister_admitted, fam:hoodie_admitted, fam:sister_fetched, task |
| 271 | at_lot | "What do you need to tell him?" | knows:kid_why, knows:bigman_dad |
| 278 | at_lot | "I'll tell him. I'll send him out." | fam:sister_fetched, task |
| 285 | at_lot | "Come in. Just you. Bring him out." | to you_said_no, goes_in; fam:kids_waiting:-, fam:sister_admitted, sister_at, spot:s_rail, count_in, rep_kids, promise_kept |
| 301 | at_lot | Look in the back seat. | knows:vape_cans |
| 311 | at_lot | Go back in. | a way out: the clock |
| 318 | at_lot.you_said_no | "I was wrong." | owned_it, rep_kids |
| 322 | at_lot.you_said_no | "I'm saying yes now." | owned_it |
| 349 | ev_vape_back | Put him out again, and pull the coaster this time. | fam:vape_ejected, vape_out_at, vape_returned, vape_seen, vape_at, spot:s_lot, deck_door, rep_t28 |
| 360 | ev_vape_back | Put him out again. | fam:vape_ejected, vape_out_at, vape_returned, vape_seen, vape_at, spot:s_lot |
| 372 | ev_vape_back | Leave him. He's back. Watch him. | heat(), rep_staff |

## closing.ink

| Line | Where | Choice | Changes |
|---|---|---|---|
| 290 | clear | The big man at the pool table. | to close_pool |
| 292 | clear | GOOD SHOES, still at the bar. | to close_banned |
| 294 | clear | HI-VIS, asleep on his arms at the bar. | to close_hivis |
| 296 | clear | {slippers_upstairs:The woman from upstairs, finishing the bottle./The women from upstairs, finishing the bottle.} | to close_residents |
| 298 | clear | The full glass at the end of the bar. | to close_endbar |
| 300 | clear | Table 28. | to close_t28 |
| 302 | clear | -> lock_up | to lock_up |
| 340 | close_pool | {knows ? kid_why:Tell him about the hospital. Now./"Your daughter's {her_place()}. She's been waiting all night."} | check father 7; to the_lot; fam:dad_told |
| 354 | close_pool | "We're closed. Time to go." | bigman_ease |
| 359 | close_pool | Take the cue out of his hands. | check fighter 7; bigman_ease, rep_kids |
| 427 | close_pool.the_lot | Take his keys. | check father 8; to keys, keys_refused |
| 435 | close_pool.the_lot | Walk him to his daughter's truck. | to walk_him |
| 437 | close_pool.the_lot | Let him go. | to drives |
| 452 | close_pool.keys_refused | Take them anyway. | check fighter 7; to keys, drives; hurt, incident:inc_hurt |
| 462 | close_pool.keys_refused | Walk him to his daughter's truck. | to walk_him |
| 464 | close_pool.keys_refused | Let him go. | to drives, to_pickup, clear; took_keys, fam:dad_walked, task, fam:dad_went, fam:dad_drove |
| 544 | close_banned | "You heard her." | check father 7 |
| 553 | close_banned | Walk him out. | check fighter 6; rep_t28 |
| 561 | close_banned | "One more. Then you go." | rep_staff |
| 581 | close_hivis | Wake him and walk him up. | rep_staff, case_back; (walked_up) is read |
| 592 | close_hivis | Wake him and point him at the stairs. | hivis_landing, case_back |
| 602 | close_hivis | Leave him. He lives here. | rep_staff |
| 688 | close_t28 | Tell Dennis about the dog. {late_words(wife_at)} | dog_told, rep_t28, task; (dog_late) is read |
| 700 | close_t28 | "Drink up, gentlemen." | check father 7; rep_staff |
| 709 | close_t28 | "Take your time." | rep_t28 |
| 713 | close_t28 | Sit down with them for the last one. | pull_table, drinks, incident:inc_drinking, rep_t28 |
| 720 | close_t28 | "Now. All of you." | rep_t28, rep_staff |
| 736 | close_t28.secret | Say nothing. | secret_kept |
| 740 | close_t28.secret | "He was out on the deck with me." | secret_kept, rep_t28 |
| 845 | search | The deck door. | found_why:why_deck, deck_door |
| 869 | search | The hotel door. | found_why:why_hotel, hotel_door |
| 885 | search | The kitchen door. | kitchen_door |
| 890 | search | The front door, while he was away from it. | found_why:why_front |
| 904 | search | The single washroom. | found_why:why_sleeper |
| 911 | search | That's enough. Write the log. | to incident_log; rep_staff |
| 928 | still_in | The washrooms. | (by_wash) is read |
| 932 | still_in | Under the tables. | (by_tables) is read |
| 936 | still_in | The hotel stairs. | (by_stairs) is read |
| 940 | still_in | The keg room. | (by_kegs) is read |
| 947 | still_in | Tell her. | to own_up |
| 949 | still_in | That's enough. Write the log. | to incident_log; owned_it, rep_staff |
| 959 | still_in.own_up | "I was playing with it." | owned_it, rep_staff |
| 964 | still_in.own_up | "It must have stuck." | owned_it, cocoon |
| 970 | still_in.own_up | Say nothing. | owned_it, rep_staff |
| 1003 | incident_log.log_next | Write it down the way it happened. | logged, cocoon, rep_staff |
| 1012 | incident_log.log_next | Write it so it reads better. | shaded, cocoon, rep_staff |
| 1021 | incident_log.log_next | Leave it out. | left_out, cocoon, rep_staff |
| 1077 | after_hours | Drink it. | last_glass, drinks, incident:inc_drinking |
| 1081 | after_hours | Leave it standing. | last_glass |
| 1087 | after_hours | Push it back. | last_glass |
| 1098 | after_hours.water | Drink the water. | (drank_water) is read |
| 1101 | after_hours.water | Ask for a rye. | rep_staff |
| 1110 | after_hours.door_story | "The owner shorted me." | claims:said_left_bad_owner |
| 1113 | after_hours.door_story | "Something happened." | claims:said_left_something |
| 1116 | after_hours.door_story | "Long story." | claims:said_left_long_story |
| 1119 | after_hours.door_story | Say nothing. | claims:said_nothing |
| 1236 | after_hours.last_doorman | "Table 28 told me about the last doorman. Which one's true?" | knows:lost_jacket |
| 1246 | after_hours.last_doorman | Don't ask. | (didnt_ask) is read |
| 1262 | after_hours.choose | Go up to bed. | to go_upstairs |
| 1264 | after_hours.choose | Wait till she's gone. Then go down to the keg room. | to keg_parley |
| 1339 | keg_parley.terms | "Who are you?" | knows:endbar_dock |
| 1345 | keg_parley.terms | "What do they want?" | (want) is read |
| 1349 | keg_parley.terms | "What do I get?" | (what_get) is read |
| 1353 | keg_parley.terms | "What have they heard?" | to overheard |
| 1355 | keg_parley.terms | "I saw it. In the wall." | (saw_it) is read |
| 1359 | keg_parley.terms | "Done. Those terms." | to deal |
| 1362 | keg_parley.terms | "The step, and no poison. Not the kitchen door." | check wrongman 8; to bargain |
| 1364 | keg_parley.terms | "No. They're going." | to refuse |
| 1366 | keg_parley.terms | Tell him you'll burn them out. | to threaten |
| 1368 | keg_parley.terms | "I'll think about it." | to think, after_parley, latch, go_upstairs; parley, rats, task, terms_door |
| 1520 | keg_parley.latch | Put the back door on the latch, the way he said. | terms_kept, kitchen_door |
| 1525 | keg_parley.latch | Leave it. Go up. | terms_kept |
| 1549 | go_upstairs.landing | Get him up the rest of the way to eleven. | hivis_landing |
| 1555 | go_upstairs.landing | Step over him. | (stepped_over) is read |
| 1627 | voices_at_night | Let THE TABLE in. | to let_voice_in |
| 1629 | voices_at_night | Let THE KID in. | to let_voice_in |
| 1631 | voices_at_night | Sleep. | to ledger |
| 1714 | let_voice_in | Put THE FIGHTER out. | psyche |
| 1716 | let_voice_in | Put THE MANUAL out. | psyche |
| 1718 | let_voice_in | Put THE WRONG MAN out. | psyche |
| 1720 | let_voice_in | Put THE TABLE out. | psyche |
| 1722 | let_voice_in | Put THE FATHER out. | psyche |
| 1725 | let_voice_in | Nobody. Keep the room as it is. | to voices_at_night.vs |
