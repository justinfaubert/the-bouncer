// Things: what he sees when he looks at something in the building that nothing on offer is about.
// Every object he can see, he can reach (bible/11_SKELETON.md, DECIDED: Hutch found the jukebox
// couldn't be clicked). The things, and where each one is, are in content/data/things.yaml; in
// the Godot build a click on one (or E) calls its toy_<thing>("look") here, the way handling a
// thing he's been handed calls toys.ink. The clock doesn't move, and nothing here changes the
// night: a look is a look. A voice can answer one (toy:<thing>:look in content/rules/barks.yaml).
//
// The first look is the long one; after that, a line. Claude's drafts, all of it.


// ------------------------------------------------------------------ the room

=== function toy_jukebox(what)
{ juke_low:
    The jukebox, a notch down, and the room coming through under it.
    ~ return
}
{stopping:
- The jukebox on the back wall, lit pink round the edges, MOST PLAYED HERE across the top of the screen and CREDITS 0 along the bottom.
- {shuffle:The jukebox, between songs.|The jukebox, on somebody's song.|The same song as an hour ago, or one like it.}
}

=== function toy_dartboard(what)
{ darts_pulled:
    The dartboard, with nothing in it now but the holes.
    ~ return
}
{stopping:
- The dartboard on the east wall, in its cabinet with the doors open, and the line on the carpet where you stood to throw. Three darts in the board, in nothing much. Nobody had played tonight. Taped inside one of the cabinet doors, a wedding photo with the bride's face darted down to the cork, and the groom's left alone.
- The three darts, where they'd been.
}

// What's on it is room.ink's (tv_on): the late news comes on at half past eleven, unless he's changed it.
=== function toy_tv(what)
{
- tv_on == 1:
    {stopping:
    - The late news, with the sound off and the captions on: the rainfall warning, the ferries, and then the light over the strait again, somebody's phone from the deck of the evening sailing, a white point in the dark. A man from the Air Force, and the word BALLOON in the captions.
    - The light over the strait, going round again.
    }
- tv_on == 2:
    {stopping:
    - The game again from the start, on the sports channel's night replay. Table 28 cheered the first goal again.
    - The game again. Still nothing in it.
    }
- tv_on == 3:
    The TV over the back wall, off: a dark square with the room in it, small.
- tv_on == 4:
    {stopping:
    - The curling, from the prairies somewhere: a stone going down the ice, slow, and two men sweeping hard in front of it.
    - The curling. Another end.
    }
- clock < 1380:
    {stopping:
    - The TV over the back wall, on the hockey with the sound off: home two, away one, in the second. Table 28 watched it all at once, and only when something happened.
    - Still two to one.
    }
- else:
    {stopping:
    - The game was over. They were showing the goals again, each one from three angles, and table 28 watched every one.
    - The goals, again.
    }
}

=== function toy_tv_news(what)
{stopping:
- The other TV, on the east wall, on the news with nobody watching it: a rainfall warning for the east coast of the island, tonight into Thursday, fifty to seventy millimetres, and a line going round along the bottom. The nine-fifteen sailing cancelled. Water over the highway somewhere.
- The rainfall warning, going round.
}

=== function toy_cues(what)
{stopping:
- Four house cues in the rack on the back wall, each one warped its own way, and one with no tip. The ones who could play brought their own. {rack_locked:A chain through all four, and the padlock shut on it.|A chain through all four, and a padlock hanging open on the end of it.}
- The house cues, in the rack{rack_locked:, locked}.
}

// The rail along the wall by the pool table, and whatever's gathered on it (room.ink).
=== function toy_empties(what)
{ ledge_glasses() == 0:
    The rail along the wall by the pool table, wiped, with nothing on it but the rings.
    ~ return
}
{Num(ledge_glasses())} empties on the rail by the pool table, pint glasses with the foam dried down the insides{ledge_glasses() >= 4:, crowding the end of it where the big man stood}.

// The big man's work coat, on its hook by the dartboard (room.ink).
=== function toy_coat_hook(what)
{
- in_drawer ? bm_coat || back_for > 0 || (fam ? lot_scene):
    The coat hooks by the dartboard, with nothing on them.
- cell_ringing():
    A canvas work coat on the hooks by the dartboard, soft at the cuffs, and the phone in it buzzing against the wood again.
- else:
    A canvas work coat on the hooks by the dartboard, soft at the cuffs, hanging crooked{cell_how != 3: with the weight of the phone in it}.
}

// GOOD SHOES's wallet, by his stool, if he left it (room.ink).
=== function toy_wallet(what)
A wallet on the carpet by the stool where GOOD SHOES had sat.

=== function toy_pool_table(what)
{stopping:
- The pool table, under its light, with a lean to it that everyone who played here knew about and nobody else did.
- The pool table{pool_still():, the big man walking round it|, nobody at it}.
}

=== function toy_t28(what)
{stopping:
- Table 28, the big round one in the front window, {num(t28_rounds)} rounds in. The one in the team jacket was talking. The rest were waiting to.
- Table 28, {num(t28_rounds)} rounds in.
}

=== function toy_window(what)
{ here == lot:
    {stopping:
    - The front window from out in the rain, the room lit behind it, and table 28 in the middle of the glass: all of them talking, none of them looking out. From out here it looked like somewhere you'd want to be.
    - Table 28 in the window, lit.
    }
- else:
    {stopping:
    - The front window, table 28's, running with rain. Through it the lot, past the lot the highway, and past the highway the dark, which was the water.
    - {shuffle:Rain on the window.|Headlights on the highway, slow in the rain.}
    }
}

=== function toy_bottles(what)
// HUTCH: What's on the back bar at a place like yours: what gets poured, and what's been up there for years?
{stopping:
- The back bar: three shelves of bottles against the mirror, the rail stuff on the bottom where she could reach it without looking, and up top the good scotch, dusty at the shoulders.{here != hall: In the mirror, between the bottles, the room, and him in it.}
- The bottles{here != hall:, and him in the mirror behind them}.
}

=== function toy_taps(what)
// HUTCH: What's on tap at a pub like yours?
{stopping:
- Six taps on the steel bar, their handles facing the room in the brewers' colours: two lagers, a pale ale, a red, a stout, a cider.
- The taps.
}
{ lager_off():
    The lager on the end had been spitting foam since ten.
}

=== function toy_lotto(what)
{stopping:
- The lottery screen on the bar by the till: a draw every few minutes, twenty numbers lit out of eighty, and the next one counting down. Table 28 had been playing it since two in the afternoon. One of them had a system, and the rest had heard it.
- {shuffle:Another draw. Nobody at table 28 had won it, by the sound of them.|Another twenty numbers, near enough the same twenty.}
}


// ------------------------------------------------------------------ by the door

=== function toy_tape(what)
{stopping:
- A strip of masking tape on the frame by the door, at the height of his eyes on the stool, in black marker: 19 = NOV 4 07. Born on or before, they could drink tonight.
- NOV 4 07. Anybody born on the fifth was going home.
}

=== function toy_id_sign(what)
{stopping:
- The sign on the screen by the door: NO MINORS. TWO PIECES OF ID, ONE WITH A PHOTO. NO PHOTOCOPIES. NO PICTURES ON PHONES. NO EXCEPTIONS.
- NO EXCEPTIONS, in the smallest letters on it.
}

=== function toy_scanner(what)
{stopping:
- The ID scanner on the ledge, a slot with a green light and a red one. It read a card in about a second and kept it, with the time, for longer than anyone would ever need it to.
- The scanner, waiting.
}
{ phone_scans > 0:
    It had a photograph of a licence in it from tonight{phone_scans > 1:, twice}, and the red light it had given it.
}

// The mop and the yellow sign, in the corner of the vestibule (room.ink).
=== function toy_mop(what)
{ wet_sign:
    The mop in its bucket in the corner of the vestibule, and the yellow sign out on the tiles: CAUTION WET FLOOR, in two languages, and the little man falling over backwards.
- else:
    The mop in its yellow bucket in the corner of the vestibule, with the wringer up, and the sign folded behind it.
}
{ wet() >= 2:
    The tiles had gone grey with the wet.
}

// The house lights' dimmer, inside the front door (room.ink, lights_at_last).
=== function toy_dimmer(what)
{
- lights == 1 || (lights == 2 && clock >= 1545) || clock >= CLOSE_TIME:
    The dimmer inside the front door, a brass plate and a dial, turned all the way up.
- lights == -1:
    The dimmer inside the front door, a brass plate and a dial, left where she had it: a quarter up.
- else:
    The dimmer inside the front door, a brass plate and a dial, down to a quarter since eight o'clock.
}

=== function toy_book(what)
{stopping:
- The incident book on the ledge, a hardcover with a pen tied to the spine on a string. Other men's handwriting all the way back, and room left for his.
- The book, shut, the pen on its string.
}


// ------------------------------------------------------------------ the back hall, the kitchen, the keg room

// The extinguisher at the end of the back hall (room.ink).
=== function toy_extinguisher(what)
{ ext_how > 0:
    The extinguisher on its bracket at the end of the hall, two years since anybody punched its tag.
- else:
    The extinguisher on its bracket at the end of the hall, across from the payphone, with an inspection tag on a string round its neck.
}

=== function toy_hotel_door(what)
{ hotel_door:
    The hotel door at the end of the hall, propped on a wedge, and through it the front desk and the bottom of the stairs.
- else:
    The hotel door at the end of the hall, shut, with a small window in it at head height and the front desk's light in the window.
}

=== function toy_pass(what)
{stopping:
- The pass under the heat lamp, and four tickets on the rail over it in the cook's hand, which only the cook could read. {fries == 0:Under the lamp, a basket of fries going soft that nobody had come for.|Under the lamp, nothing, kept warm.}
- {fries == 0:The fries, going soft.|The heat lamp, over nothing.}
}

=== function toy_fryer(what)
{stopping:
- The fryer, its baskets hung up over the oil to drain. The oil was the colour of strong tea, and older than it should have been.
- The fryer, running hot.
}

=== function toy_radio(what)
{stopping:
- The cook's radio on the shelf over the flat-top, on a station from the mainland that came and went with the weather. Tonight it was mostly weather.
- The radio, between stations.
}

=== function toy_walk_in(what)
{stopping:
- The walk-in's steel door at the end of the kitchen, with the crates stacked by it, and a hasp for a padlock and no padlock.
- The walk-in.
}

=== function toy_compressor(what)
{stopping:
- The compressor in the corner, ticking over, held together with grey tape in three places.
- The compressor, ticking.
}

=== function toy_gas(what)
{stopping:
- Two gas cylinders chained to the wall, for the lines. One of them was frosted at the valve.
- The gas, chained to the wall.
}

=== function toy_pilings(what)
{stopping:
- Past the last of the kegs the concrete gave out to dirt, and the old pilings stood up out of it in no kind of order, black, where they'd been driven into the beach before there was any building on it. The dirt was damp. The water wasn't far.
- The pilings, in the dark past the bulb.
}


// ------------------------------------------------------------------ outside

=== function toy_rail(what)
{stopping:
- The deck rail, wet, and past it the lot, the highway, and the strait, which tonight was only a sound.
- The rail, and the strait past it.
}

=== function toy_butt_can(what)
{stopping:
- A coffee can of sand by the rail for the butts, and more butts round it than in it.
- The can, and the butts round it.
}

=== function toy_roof_sign(what)
{stopping:
- The sign on the roof: SOVEREIGN in red neon, with the second E dead, so from the highway it said SOVER IGN. Under it HOTEL, all five letters working.
- SOVER IGN.
}

=== function toy_store(what)
{stopping:
- The cold beer and wine store at the west end of the building, still lit, the brightest thing on the lot.
- The beer store, lit.
}

=== function toy_work_truck(what)
{stopping:
- A work truck nose in by the beer store, a toolbox bolted across the bed, mud up the doors.
- The work truck.
}

=== function toy_his_window(what)
{stopping:
- His window, upstairs at the east end of the building, dark. From down here it looked like anybody's.
- His window.
}


// ------------------------------------------------------------------ his room

=== function toy_up_window(what)
{stopping:
- The lot from up here: the puddles, the sign's red in them, the highway, and nobody on it.
- The lot, and the sign's red in the puddles.
}


// ------------------------------------------------------------------ before the night: Gary's front room
// The camera's Gary's in here (office.ink), so these are what Gary sees.

=== function toy_office_photo(what)
{stopping:
- His father's picture of the Sov, August 1958, on the wall behind Gary's chair, where the man across the desk had to look at it and Gary didn't. Three storeys of new paint, every letter on the roof lit, and Senior in front of the door in his hat.
- Senior, in front of the Sov, every letter lit.
}

=== function toy_office_licence(what)
{stopping:
- The first licence, framed by the door: beer by the glass, in the beverage room of the Sovereign Hotel, for the year 1958. Senior had framed the first one and filed every one after it.
- The first licence, 1958.
}

=== function toy_office_notice(what)
{stopping:
- The notice from the health authority, square in front of Gary on the desk, where he'd see it every time he looked down, which was the idea. A routine inspection, Saturday the fourteenth, while they were open. Further down he'd circled PEST, and then circled it again.
- The fourteenth. PEST, twice.
}

=== function toy_office_lamp(what)
{stopping:
- The brass lamp on the desk, with its pleated shade, on since lunch. In November on the island it was four in the afternoon from about eleven in the morning.
- The lamp, on.
}

=== function toy_office_window(what)
{stopping:
- The front window, the blinds half up and the rain on the glass. Across the road, the bank that had been a cafe for eleven years, BANK still cut in the stone over the door and the cafe's lights on underneath it.
- Rain, and the cafe across the road.
}

=== function toy_office_calendar(what)
{stopping:
- The calendar over the bookkeeper's desk: a fish boat at the dock, in better weather than this, and November under it.
- November.
}

=== function toy_office_safe(what)
{stopping:
- The safe by the filing cabinet, black and older than Gary, still on Senior's combination, which was Gary's mother's birthday.
- The safe.
}

=== function toy_office_shirts(what)
{stopping:
- The carton of shirts by the door, from a supplier on the mainland: black, SECURITY across the back of every one in white letters a hand high. Eleven dollars each, by the dozen.
- The shirts, in their carton.
}

=== function toy_bk_mug(what)
{stopping:
- The bookkeeper's mug, from the bank across the road when it was a bank, its name washed nearly off. Tea, gone cold by the ledger.
- Her mug, from the bank.
}


// ------------------------------------------------------------------ before the night: the old main street, the Esso, the seawall

=== function toy_street_library(what)
{stopping:
- The library, brick, up its flight of steps, PUBLIC LIBRARY carved in the stone over the door, and a lamp on in one of the tall windows for whoever came in next.
- The library, one lamp on.
}

=== function toy_street_legion(what)
{stopping:
- The Legion, set back behind its lawn, long and low, its windows up high where nobody could see in and the bar behind them lit already.
- The Legion, its bar lit.
}

=== function toy_street_gun(what)
{stopping:
- A field gun on a concrete plinth on the Legion's lawn, its barrel aimed up the road at the bank. Whoever set it there had either not thought about that, or had.
- The gun, still aimed at the bank.
}

=== function toy_street_bank(what)
// HUTCH: The old main street in a town like yours: what's on it that nobody from away would notice?
{stopping:
- BANK, cut in the stone over the columns, and under it a cafe for eleven years: a chalkboard on the sidewalk, SOUP TODAY, CLAM CHOWDER, PIE $4.50, COFFEE $2.25, and the lights on behind the glass doors{call_did == 3:, where the bookkeeper had been a teller}.
- BANK, over the cafe.
}

=== function toy_street_church(what)
{stopping:
- The white church at the top of the street, wooden, its spire going up into the rain, and its sign: SIGN BROKEN, COME INSIDE FOR MESSAGE. The stone one at the bottom had a realtor's board on the lawn.
- SIGN BROKEN.
}

=== function toy_street_wharf(what)
{stopping:
- The government wharf, across the highway at the foot of the street: wet planks, crab traps stacked at its head, a few fish boats tied up, and the light at the end with somebody standing under it, not fishing.
- {knows ? endbar_wharf:The old man, still at the end of the wharf.|The wharf, and somebody under the light at the end.}
}

=== function toy_street_pickup(what)
{stopping:
- A pickup outside the cafe with its wipers stopped halfway up the glass, which meant whoever owned it had only meant to be a minute, about an hour ago.
- The pickup, still waiting.
}

=== function toy_esso_canopy(what)
{stopping:
- The canopy, lit white from underneath, over two islands of pumps and nobody at them. Under it there was no rain and too much light.
- The canopy, lit.
}

=== function toy_esso_prices(what)
{stopping:
- The price sign by the road, in plain digits a foot high: 179.9, 193.9, 188.9. They'd gone up twice since the summer and come down once, by a tenth of a cent.
- 179.9.
}

=== function toy_esso_window(what)
{stopping:
- The store's window, full of signs: two for one, lotto, propane exchange, ice, a lost cat from August. Behind them the shelves, the till, and the clock over it that didn't agree with anything.
- The store, lit.
}

=== function toy_esso_ice(what)
{stopping:
- The ice freezer by the door, ICE on its front, and the kid sitting on the lid with his heels against the C. It was November and raining and nobody was going to buy ice, which was probably why it was his.
- The kid, on the ice.
}

=== function toy_seawall_water(what)
{stopping:
- The strait past the seawall, the tide high and the rain on it, and the far shore's lights laid along the top of the dark.{knows ? esso_sky: Over the mainland the kid's light, where it had been.} Every few minutes a log truck went by behind him and the wall shook a little.
- The water, and the far shore.
}



// ------------------------------------------------------------------ the grounds at night (grounds.ink, godot/world/grounds.gd)
// Found by walking up to them (things.yaml near:). A few are more than a look: the man fishing, the
// cross, the licence, the buzzers, the caps, the payphone, the night window, the fire, the kitchen's
// door take a choice in at_front instead, when it's there to take, and come here once it's not.

=== function toy_rat_gap(what)
~ out_found += cl_rat_front
{stopping:
- Under the front window, where the siding stopped short of the gravel, a gap the height of a fist, and the edge of the board worn smooth and dark, like a banister. A crust of something on the gravel in front of it, and nothing round it at all, not even a footprint, as if whatever went in and out of there wiped its feet.{knows ? keg_hole: Under the window was under table 28.}
- The gap under the window. The edge of the board, polished.
}

=== function toy_lot_pole(what)
{stopping:
- A power pole at the edge of the lot with forty years of staples in it, a beard of them, and over the staples the posters of this autumn: a cover band at the Legion, SUNDOWN DRIVE, with a drummer in the back of the photo who looked like Jim; LOST: GREY CAT, ANSWERS TO NOTHING; GOD HAS NOT FORGOTTEN THIS TOWN; and a sheet with the same phone number torn off it twelve times, and nothing else on it. Nobody had taken any of the number.{out_found ? cl_wife: Low down on the pole, under the staples, a woman's face on a poster gone to pulp. Only the scarf was left.}
- The pole and its posters. The torn-off tabs, all there.
}

=== function toy_news_box(what)
~ out_found += cl_paper
{stopping:
- A newspaper box by the hotel's steps, the Valley Record, and through the scratched window the front page from last Friday: SEAWALL TO CLOSE AFTER WINTER, REGIONAL DISTRICT SAYS. Under it a photograph from the summer of a man fishing off the wall with the Sov's sign behind him. He was in a green jacket and he wasn't looking at the camera. The box took two dollars. Nobody had put any in since Friday.
- The paper in the box. SEAWALL TO CLOSE. The man in the photo, not looking.
}

=== function toy_hotel_urn(what)
{stopping:
- The ashtray by the hotel's door, a cylinder of sand gone to cement, every butt in it smoked to the filter and stood up on end, a little graveyard of them in rows. Somebody upstairs did that every night and that was who they were.
- The ashtray, the butts in their rows. One more row since.
}

=== function toy_kitchen_door(what)
{stopping:
- The kitchen's back door, shut, a grey steel door with KEEP CLOSED stencilled on it and a dent at kicking height where it had been kept open anyway. A brick by the step, for next time.
- The kitchen door, shut. The brick by the step.
}

=== function toy_cook_crate(what)
{stopping:
- A milk crate turned over by the kitchen step, the cook's seat, a coffee can of butts beside it and a scratch ticket stuck to the wet gravel, scratched, nothing. Somebody had carved the crate's plastic with a knife into the shape of a woman, carefully, a long time ago, and then crossed it out.
- The cook's crate, and the can of butts.
}

=== function toy_dumpster(what)
{stopping:
- The dumpster, lid up, full past full: flattened boxes, the fryer oil in its jug, the night's bags split open by something with hands. On the side in the rust somebody had written FUCK GARY and under it, in a better marker, FUCK YOU BRIAN, and under that, small, both.
- The dumpster. Something in it, moving, then not.
}

=== function toy_drums(what)
{stopping:
- Two blue drums against the beer store's wall, FRYER OIL USED stencilled on them, and a smell off them like a ghost of every chip ever made. One lid had been prised up and put back wrong. Inside something floated and he didn't look at what.
- The drums.
}

=== function toy_back_freezer(what)
~ out_found += cl_freezer
{stopping:
- A chest freezer out in the yard on two pallets, running, an orange cord across the gravel to an outlet on the hotel's wall. A padlock on the lid, new, a good one. It hummed, and every so often it shuddered and hummed lower, the way a fridge does at four in the morning when you're the only one up.{card_kept == 1: The licence in his pocket was nothing to do with it, and he thought of it anyway.}
    FIGHTER: Nobody padlocks a freezer for what's in it. They padlock it for who'd look.
- The freezer, humming. The padlock.
}

=== function toy_vent(what)
~ out_found += cl_rat_back
{stopping:
- A vent low in the back wall under the kitchen, the louvres pushed in, and warm air coming out of it that smelled of the keg room: wet concrete, old beer, something sweet underneath. The gravel in front of it was worn into a little road.{out_found ? cl_rat_front: In the front, out under the window. Out the back, here. Whatever it was had the run of the place.}
- The vent, breathing out.
}

=== function toy_caps(what)
{
- caps_how == 1:
    The spiral of caps, as it was. A new one on the end of it since, a Lucky, face up.
- caps_how == 2:
    The spiral of caps, with nothing in the middle.
- caps_how == 3:
    The caps where he'd kicked them, and some of them, he'd have sworn, put back.
- else:
    The caps in their spiral.
}

=== function toy_fence(what)
{stopping:
- A chain-link fence along the back of the yard, sagging between the posts, the top rail bent down in two places where people had climbed it. Behind it the brambles, and behind the brambles the hill going up black with firs. Caught in the wire, at the height of a face, a hair tie.
- The fence, and the hill behind it.
}

=== function toy_trail(what)
~ out_found += cl_trail
{stopping:
- Where the fence met the last post it had been cut and folded back, neatly, and a trail went up through the brambles into the firs, beaten flat, used. A plastic grocery bag tied to a branch at the start of it as a marker. It went up the hill toward nothing that was up the hill.
    FATHER: A trail is people who didn't want to be seen on the road.
- The trail, going up into the dark. The bag on its branch.
}

=== function toy_back_tv(what)
{stopping:
- A television in the weeds, the old deep kind, face up to the rain. Its screen had a puddle on it, and in the puddle the hotel's one lit window, so that for a second it looked like it was on.
- The TV in the weeds, showing the window.
}

=== function toy_blocks_car(what)
{stopping:
- A Pontiac on blocks at the end of the yard, no wheels, the windows fogged from inside. A sleeping bag on the back seat, the shape of somebody in it or of nobody, a pair of boots on the floor under the dash with the laces tucked in. A cardboard sign in the back window: NOT ABANDONED.
- The Pontiac. NOT ABANDONED. The shape in the back, or not.
}

=== function toy_mattress(what)
{stopping:
- A mattress against the fence, soaked through, a map of old stains on it that the rain was redrawing. Somebody had written on it in marker, big, HERE LIES, and then not finished.
- The mattress. HERE LIES.
}

=== function toy_hotel_back(what)
{stopping:
- The back of the Sovereign from the yard, three storeys of it, the rooms' windows black but one, where a TV was going blue on a ceiling. The fire escape came down the wall in zigzags and stopped two metres off the ground. On the brick at the top, ghosting through two coats of paint, the old sign: SOVEREIGN HOTEL ROOMS BY THE WEEK. Somebody had painted out WEEK and somebody else had painted it back.
- The back of the hotel. The one window, going blue.
}

=== function toy_buzzers(what)
The buzzers. DOORMAN on twelve. Seven scratched to the brass.

=== function toy_cross(what)
The cross, leaning to the road. DARLENE. The roses, new.

=== function toy_merle(what)
{shuffle:
- Merle, at the wall, watching nothing come up on the line.
- Merle, his back to the Sov, the lantern at his feet.
}

=== function toy_plaque(what)
{stopping:
- A brass plaque set in the seawall's top: THIS SEAWALL WAS CONSTRUCTED BY THE PEOPLE OF THE PROVINCE, 1958, TO HOLD BACK THE SEA. Under it, scratched in with something sharp, IT WONT.
- The plaque. IT WONT.
}

=== function toy_sea_steps(what)
{stopping:
- Concrete steps down through the wall to the beach, green with weed on the bottom four, and a chain across the top with a sign on it, NO BEACH ACCESS AFTER DARK, that everybody had been stepping over so long the chain had a shine where their legs went.
- The steps down, and the chain with its shine.
}

=== function toy_beach_fire(what)
{
- fire_how == 1:
    The fire, down to the last of it, and his own warmth still in his hands.
- fire_how == 2:
    The sand where the fire was. A thread of smoke coming up through it anyway.
- else:
    Somebody's fire.
}

=== function toy_kelp(what)
{ card_kept == -1:
    The kelp line. The licence, face up where he'd put it, the tide not to it yet.
- else:
    The kelp line, a long black braid of it, popping when he stood on it.
}

=== function toy_beach_cart(what)
{stopping:
- A shopping cart from the Save-On, on its side at the tide line, half full of sand and kelp and one child's rubber boot. It had come a long way or someone had pushed it a long way and he couldn't tell which was sadder.
- The cart, filling with sand.
}

=== function toy_far_shore(what)
{stopping:
- Across the strait the mainland, or where it would be: a line of lights along the bottom of the dark, a town, a mill, a ferry dock, and above them the dark again all the way up. {knows ? esso_sky:Over the mountains the kid's light, where it had been, and then not.|Something blinked up in the black above the lights, red, and didn't blink again.}
- The far shore. Its lights.
}

=== function toy_esso_phone(what)
{
- esso_answered == 1:
    The payphone on its steel cord. He'd put the receiver back. It was warm.
- esso_answered == -1:
    The payphone, quiet now, and a sticker on its side: THIS PHONE DOES NOT ACCEPT INCOMING CALLS.
- else:
    {stopping:
    - A payphone on the Esso's end wall, the last one on this end of the island, a steel cord, a coin slot jammed with a folded receipt. Sharpied across the hood: CALL YR MOTHER.
    - The payphone. CALL YR MOTHER.
    }
}

=== function toy_esso_pumps(what)
{stopping:
- Two islands of pumps under the canopy, nobody at them, and a sign on each: PAY INSIDE AFTER 10 PM / NIGHT WINDOW. On one nozzle somebody had left a single child's mitten on the handle like a puppet.
- The pumps, nobody at them.
}

=== function toy_esso_clerk(what)
The night window. The kid behind it, lit from under by his phone.

=== function toy_esso_prices_n(what)
~ esso_price++
{
- esso_price == 1:
    The price sign by the road, the digits a foot high and red at night: 179.9. They'd been 179.9 at dusk.
- esso_price == 2:
    The price sign. 181.9. He hadn't seen anybody change it.
- esso_price == 3:
    The price sign. 186.9.
    WRONGMAN: The drunk said the price went up every time you looked at it. Then he said that's just what prices are.
- else:
    The price sign. {esso_price * 2 + 180}.9. He stopped looking at it, which didn't help either.
}
