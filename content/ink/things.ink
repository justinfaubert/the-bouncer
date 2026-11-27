// Things: what he sees when he looks at something in the building that nothing on offer is about.
// Every object he can see, he can reach (bible/11_SKELETON.md, DECIDED: Hutch found the jukebox
// couldn't be clicked). The things, and where each one is, are in content/data/things.yaml; in
// the Godot build a click on one (or E) calls its toy_<thing>("look") here, the way handling a
// thing he's been handed calls toys.ink. The clock doesn't move, and nothing here changes the
// night: a look is a look. A voice can answer one (toy:<thing>:look in content/rules/barks.yaml).
//
// The first look is the long one; after that, a line. Claude's drafts, all of it.


// ------------------------------------------------------------------ the room

// The beer mats on the bar (godot/game/beer_mats.gd): the first look is this; the next, he flips one.
=== function toy_coasters(what)
{stopping:
- A pile of beer mats on the bar in the gap by the rails, SEAWALL LAGER in a ring on every one. The brewery sent them up by the hundred and nobody'd put one under a glass in years. The top one had a phone number on it and a name that had been scribbled out hard enough to go through.
- The beer mats. The top one hanging a little over the edge, for flipping.
}

// The wine glasses on the bar (godot/game/wine_glasses.gd): the first look is this; the next, he plays them.
=== function toy_wineglasses(what)
{stopping:
- Eight wine glasses upside down on a bar towel in the gap across from the taps, none of them from the same set. Jim kept them for the one woman a year who ordered wine and then asked what kind. His clip-on tuner was on the water jug's handle behind them, where he'd left it after tuning a snare at the bar on a Monday.
- The wine glasses on their towel. Anybody who'd ever been bored in a restaurant knew what you could do with one.
}

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
- The back bar: three shelves of bottles against the mirror, the rail stuff on the bottom where the bartender could reach it without looking, and up top the good scotch, dusty at the shoulders.{here != hall: In the mirror, between the bottles, the room, and him in it.}
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
    The dimmer inside the front door, a brass plate and a dial, left where the bartender had it: a quarter up.
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

// The cigarette machine on the east wall, under the news (godot/game/cig_machine.gd): the first look is this; the
// next one, he goes and stands at it, and it plays. Nobody in the Ink says so.
=== function toy_cigmachine(what)
{stopping:
- The cigarette machine against the east wall under the TV, on the way out to the deck: twelve brands behind twelve little windows, a knob under each, a strip of mirror gone grey at the corners. IT'S THE LAW, 19 TO BUY, on a sticker somebody had gone at with a key. They'd unplugged it the year of the ban and coiled the cord on top and taped it. Somebody had written ON over the coin slot in marker, and under it OFF, and under that a question mark.
- The cigarette machine. Its cord was still taped up on top. He'd have sworn the windows were lit a second ago.
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


// ------------------------------------------------------------------ before the night: the old main street, the Lesso, the seawall

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
    - A payphone on the Lesso's end wall, the last one on this end of the island, a steel cord, a coin slot jammed with a folded receipt. Sharpied across the hood: CALL YR MOTHER.
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

// ------------------------------------------------------------------ the set dressing
// What's on the walls and the floor (godot/world/dressing.gd): the beer posters and the calendar,
// the signs, the corkboard, the beer clock, the neon, the glasses and the glasswasher, the hall's
// hole, the signs by the door and what's on the gravel, the Lesso's window. The brands are made up.

=== function toy_poster_boors(what)
{stopping:
- BOORS LIGHT. COLD AS YOUR EX. A blonde in a bikini the colour of a glacier, standing in snow to her shins in nothing else, the can up by her ear as if it had said something. The window had taken the blue out of the top half of her. Somebody had put a piece of tape back over the bottom corner where she'd come away from the wall.
- The glacier girl, with the tape on her corner. Somebody had drawn a moustache on her and somebody else had tried to rub it off with a thumb.
}

=== function toy_poster_mildcat(what)
{stopping:
- MILDCAT. UNLEASH THE MILD. A brunette on a bar stool in a leopard bikini, her legs crossed, the can up by her mouth like a microphone. Across her shins, in black marker, in capitals pressed hard into the paper: SHITTY KITTY. And an arrow. The arrow pointed at the can, not at her. Whoever wrote it had principles.
- SHITTY KITTY. It was still the second-best seller in the place.
}

=== function toy_calendar(what)
{stopping:
- The Unlucky Lager calendar on its nail under the lamp. Miss March: a redhead leaned on the fender of a pickup with a bottle at her hip. GET UNLUCKY. MARCH 1998. Somebody had crossed the days off in ballpoint, one X each, the first to the thirteenth, and then stopped. On the fourteenth, in pencil, small: D.
- The truck in it was jade green. He'd had one that colour once, a long time ago, and sold it for parts.
- March 1998, crossed off to the thirteenth. D.
}

=== function toy_poster_lochness(what)
{stopping:
- LOCHNESS. SOMETHING DARK LIVES IN HERE. A pint of stout, the cream on it, and coming up out of the cream two humps and a neck. Irish-ish, it said. Brewed in the dark since 1759, probably. Nobody in the Sov drank it but the old soldier, who said it was the only one with any food in it.
- Seen it? Neither has anyone sober.
}

=== function toy_labutt(what)
{stopping:
- A tin sign up near the ceiling, LABUTT BLUE, OUT OF THE BLUE. INTO THE DITCH., rusted out round its screws and dented in the middle where something had been thrown at it from about where the pool table was. One corner had come off its screw and stood out from the wall.
- Labutt Blue. Into the ditch.
}

// The first look, the board; after that, a flyer at a time.
=== function toy_corkboard(what)
{stopping:
- The corkboard by the way to the hall, every inch of it somebody's, pinned over somebody else's. On top, newest, a sheet with four of its six phone tabs torn off: SMOKER, at the fish plant, Sunday, eight. Three rounds. Two hundred dollars to the last man standing. Bring your own mouthguard. No referee. No refunds.
- {cycle:
    - THE DOWNSTROKES, Saturday, nine, at the Sov. Classic rock, covers of covers. No cover. (Get it.) JIM ON DRUMS, along the bottom, in smaller letters than the rest, as if he'd made it himself and hadn't wanted to presume.
    - LOST CAT. PICKLES. Answers to nothing. Has done this before. A photocopy of a photo of a cat, mostly toner, and one tab gone.
    - In loving memory, DARLENE. A celebration of life, at the Sov, Saturday March 28, two o'clock. Potluck. Bring a story. Under it, in another pen: she would have hated this.
    - ROOM FOR RENT, upstairs, weekly, shared bath, no drugs no pets no drama. Ask at the bar. Drama was underlined twice.
    - KARAOKE TUESDAYS with DJ SANDY. You are not as good as you think you are. Sing anyway.
    - MEAT DRAW, every Sunday at four, Royal Canadian Legion, Branch 71. Hams, roasts, a turkey, and the 50/50. Proceeds to the poppy fund.
    - A business card in the corner. PREMIUM DRYWALL. No job too small. Holes punched in walls a specialty. Darrell.
    - SMOKER, at the fish plant. Two tabs left.
  }
}

=== function toy_sign_reserve(what)
{stopping:
- Over the back bar, a printed sign: WE RESERVE THE RIGHT TO REFUSE SERVICE TO ANYONE. Under it, in marker, in Gary's hand: and we do. - G. He'd been hired to be the and we do.
- And we do.
}

=== function toy_sign_forget(what)
{stopping:
- Over the kitchen door: IF YOU ARE DRINKING TO FORGET, PLEASE PAY IN ADVANCE. Everyone laughed at it once. Nobody paid in advance.
- Please pay in advance.
}

=== function toy_beer_clock(what)
{stopping:
- The beer clock over the end of the bar, OLD MILDEW, IT'S ALWAYS TIME, lit from inside, the face gone the yellow of a smoker's ceiling and five dead flies in the bottom of it. It ran seven minutes fast. That way last call came early, and nobody argues with a clock.
- Bar time. Seven minutes fast, and nobody arguing.
}

=== function toy_window_neon(what)
{stopping:
- In the window, BOORS LIGHT in blue neon, to the lot, the H going on and off in its own time. From inside it was backwards and said nothing at all.
- The H, on. Then not.
}

=== function toy_clean_glasses(what)
{stopping:
- Pints upside down on the rubber mat on the back bar, three rows of them, all the same way round. One gap in the third row where somebody had taken one and not put it back, which would bother somebody behind the bar more than it should.
- The clean glasses. The gap, still.
}

=== function toy_glasswasher(what)
{
- not washer_on:
    The glasswasher, off, the belt stopped where it had been, a rack of empties half in under the strips, the amber lamp dark.
- washer_back:
    ~ washer_back = false
    The glasswasher, running again. Nobody had seen it switched back on. The bartender was across the bar, not looking at it, very carefully.
- else:
    {stopping:
    - The glasswasher on the end of the back bar, a conveyor machine out of a hotel kitchen and much too big for here. Racks of empties went in at one end under a curtain of plastic strips, the spray hissed inside, and they came out the other end clean and steaming. The belt ticked over. Somebody had bought it when the Sov did a hundred covers a night, and nobody since had had a reason to move it.
    - {shuffle:The belt ticking over, a rack going in under the strips.|A rack out at the end, steaming.|The hum, which you stopped hearing after the first hour.}
    }
}

// The switch: by the time this is said, he's flipped it (godot/game/main.gd), and washer_on is
// what it is now.
=== function toy_washer_switch(what)
{
- not washer_on && washer_flips == 1:
    He leaned over the bar and flipped the switch on the front of the glasswasher. The amber lamp went out. The motor ran down through one long falling note, the spray stopped, and for a second the whole bar could hear itself: the cooler, the hockey, somebody at table 28 saying "and then he says" into nothing. The bartender looked at the switch, and then at him.
- not washer_on:
    {shuffle:Off. The hum ran down, and the room came up under it.|Off again. The bartender didn't look this time, which was worse.|He switched it off. Nobody said anything about it.}
- washer_flips == 2:
    He flipped it back. The amber lamp came on, the motor caught, and the belt took up where it had left off, the half-in rack first, dripping.
- else:
    {shuffle:On. The hum came back and the room sank under it.|He switched it on again. The belt went on.}
}

=== function toy_wall_hole(what)
{stopping:
- A hole in the hall side of the wall at about the height of a big man's fist, the paper of the board torn back round it, and a beer mat taped over half of it, with a phone number on the mat and the last two digits torn off.
- The hole, and the mat over half of it.
}

=== function toy_door_signs(what)
{stopping:
- By the door, at the height of someone deciding whether to come in: MINORS PROHIBITED, with the licence number under it; and NO SHIRT NO SHOES NO SERVICE, and under that in marker, no pants: ask Gary. Nobody had ever asked Gary. Probably.
- No pants: ask Gary.
}

=== function toy_lot_trash(what)
{stopping:
- Butts all round the step, a thousand nights of them, ground into the gravel where people stood to finish one before going in, or after being put out. A can crushed flat by a tire. A scratch ticket, scratched. The rain had pushed everything that floated up against the front of the building.
- The butts round the step. Somebody's always last.
}

=== function toy_esso_ads(what)
{stopping:
- Ads taped to the outside of the Lesso's window, the sun and the squeegee gone over them: ICE, 2 BAGS $5, it is still just water. LOTTO MOST, $40 MILLION, somebody has to. SMOKES behind the counter, ask, PRICES UP AGAIN, not our fault, ask Ottawa. ROLLER GRILL 2 for $4, since this morning. On the door, WE ID everyone under 30, and anyone who argues.
- Ice, smokes, the lotto. Since this morning.
}

// ---------------------------------------------------------------- the second layer (godot/world/dressing.gd, _lived_in)

=== function toy_poster_teeth(what)
{stopping:
- ALEXANDER TEETH'S INDIA PALE ALE. A sea captain, all head, his beard a cloud he was sinking into, and in the middle of it more teeth than a man has, two rows, each one drawn on its own. His eyes had gone off to the side, past you, at something by the door. FOR THE MAN WHO HAS STOPPED EXPLAINING HIMSELF. Nobody in the Sov drank it. The rep had stopped coming round in about 2004.
- The captain was still looking past him at the door.
}

=== function toy_poster_cokanee(what)
{stopping:
- COKANEE. MOUNTAIN FRESH. LEGALLY. A glacier, and along the very top of the ridge one fine white line, drawn with a ruler. Under the can, in small print: Do not snort. Somebody had tried to peel the small print off and given up at the D.
- Mountain fresh. Legally.
}

=== function toy_poster_hockey(what)
{stopping:
- HOCKEY NIGHT AT THE SOV. WINGS 35¢, crossed out in marker, 60¢ over it. Every game. Even those ones. Down in the corner, in the same marker, NO OILERS JERSEYS. Under that, in pencil, somebody had written why, and somebody else had scratched it out.
- Wings were a dollar ten now. The sign still said sixty.
}

=== function toy_poster_zero(what)
{stopping:
- A small poster by the jukebox, gone the yellow of a smoker's ceiling, the corners eaten. BOORS ZERO. NEW! NOW WITH ZERO. No alcohol. No barley. No water. Contains Boors. Along the bottom: AVAILABLE SUMMER 2031. He read the year twice. The tape on its corners had gone brown and brittle. Thirty years of sun on it, at least.
- Summer 2031. The tape was older than he was, nearly.
}

=== function toy_founder(what)
{stopping:
- A portrait in a gilt frame between the washroom doors, in oils gone the brown of strong tea. A man in a frock coat, a watch chain across him, his hands folded on a cane. Where his face should have been the painter had put a disc of black, perfectly round, and varnished it till it shone. The hall was in it: the tube light, small and bent, and in the middle a shape that was him. The plate said R. H. SOVEREIGN, PROPRIETOR, 1911, and a dash, and nothing after the dash.
- R. H. Sovereign, 1911 to nothing yet. The hall was still in his face, and him in the middle of it.
- He looked for the brush strokes round the edge of the black. There weren't any. The frock coat had them, the cane, the watch chain, every button. The black had been put on after, or before.
}

=== function toy_painting_1952(what)
{stopping:
- Over the drink rail, a painting on board, the varnish gone amber, its own brass lamp over it: this room, from the back, the same beams, the same lamps hanging, the pool table with its felt the colour of pond water. Two shapes at the far end that might have been men, or coats. In a door in the far wall, filling it, a man with the light behind him. Bottom corner: E. M. 1952.
- He found the far wall in the room and then in the painting. In the room there was no door in it. The Sov had been a dining room in 1952, the old soldier said, white tablecloths. Gary had bought the pool table in 1988.
- The man was still in the door. He looked to have come a step further in.
}

=== function toy_velvet(what)
{stopping:
- On black velvet in a frame sprayed gold: a woman on a bar stool, her back to the room, looking over her shoulder at whoever had just come in. Nothing on. The painter had put the light only where it fell on her, a hot amber down her spine, a rose at the shoulder, and left the rest to the velvet. A crescent moon, for no reason. Signed Rocco. Under the blacklight Gary had put over her the amber came up and burned.
- Rocco's woman, still looking over her shoulder at the door, the moon over her.
}

=== function toy_hall_clock(what)
{stopping:
- A school clock over the hall, SOVEREIGN across the face, TIME, GENTLEMEN under the middle. He watched the red second hand go round once. It went the wrong way, and the minute hand had gone back a notch by the time it got to the top.
- The hall clock, going back. It met the beer clock at six and at twelve, give or take the beer clock's seven minutes.
}

=== function toy_scrawl(what)
{stopping:
- The wall by the phone, everything people write while they wait for a phone that doesn't ring or a washroom that's busy: pen, marker, a key. DARLENE 338-1979, and under it, ask for the other Darlene.
- {cycle:
    - GARY IS A COWARD, in capitals, and under it, small and neat: no I'm not - G.
    - RENT IN THIS TOWN IS A HATE CRIME, in blue paint pen. Under it, agreed, in two different hands, one of them in red.
    - A tally, sixteen days in fives, and a red line through all of it, and under the line, days.
    - YOU ARE THE MAIN CHARACTER, and under it, smaller: (of this hallway). He was the only one in it.
    - THIS PHONE DOESNT WORK. Neither does Kevin. Under that, in a third pen, very neat: I'm on disability - Kevin.
    - for a good time call your mother. Somebody had added: she's lonely and she's been asking.
    - A heart keyed into the paint, T + and the other letter scratched out so hard the plaster showed.
    - a computer wrote this wall. Under it, in purple: then whose hand is this. The purple went on down the wall a foot past the last word, in one line, and stopped at the baseboard.
    - An eye, drawn carefully, lashes and all, low, at about a seated man's height. Under it: it hears you flush.
    - DARLENE 338-1979. Ask for the other Darlene.
  }
}

=== function toy_helmet(what)
{stopping:
- On top of the jukebox, a brass diving helmet, the old kind with the round windows and the bolts, green at every seam. Nobody knew whose. It had been there before Gary. Through the front window, inside it, a lime, fresh, cut in half.
- The lime in the helmet was fresh again. The helmet had no way in but the neck, and the neck was bolted to the plate.
}

=== function toy_table_tents(what)
{stopping:
- A folded card on the table, red: CLAM-A-LOT. THE CAESAR. Canada's national cocktail and only defence. $6.50. On the back: ASK ABOUT OUR WINGS, and under it, smaller, (don't). A ring on it from somebody's glass.
- Ask about our wings. Don't.
}

=== function toy_ceiling_stain(what)
{stopping:
- Over the middle of the room the ceiling tiles had a stain on them, a brown bloom with three tide lines in it where it had spread and dried and spread again. Every winter it got a ring bigger. Nobody had been upstairs to see what was over it.
- The stain on the ceiling. He counted the tide lines. Four.
}

// ---------------------------------------------------------------- the Lesso (godot/world/dressing.gd, _lesso)

=== function toy_lesso_sign(what)
{stopping:
- Up on the price sign's pole, over the numbers, a lit oval, red in a blue ring: LESSO. It had been something else once, with an E and a tiger. The company had changed the name in a year when everything got smaller and the price stayed, and nobody had ever said what the L stood for. At night you could see it from the Sov's step, the one red thing on the highway.
- LESSO. Less of everything. The oval hummed.
}

=== function toy_lesso_standee(what)
{stopping:
- A cardboard woman in front of the window, life-size and leaning back on her easel, in a red bikini three summers out of date, holding out a slush the colour of a cherry nobody has ever eaten. NEW! CHERRY BLAST. BRAIN FREEZE, ANY SIZE 99¢. Feel nothing for a minute. The sun through the glass had taken the blue out of her first. Somebody had drawn a moustache on her and somebody else had rubbed it off with their thumb.
- The cardboard woman, still holding it out. Ninety-nine cents to feel nothing for a minute was the best deal on the island.
- He looked at her a while longer than he meant to. Her eyes were printed looking over his shoulder, at whoever was behind him at the pumps.
}

=== function toy_lesso_board(what)
{stopping:
- A chalk board out by the road, on its legs, for the cars. LIVE BAIT. COLD POP. ICE. NALOXONE, and under it, free. ask. no lecture. In the corner, (the worms are $4.99). The rain had got the bottom of it and the chalk had run.
- The back of the board, for the cars going north. NIGHTCRAWLERS, $4.99 a dozen. Our worms are local. (so are we. sorry.) ASK ABOUT OUR HOT DOGS. They're fine.
- Worms, pop, ice, and the kit for bringing a man back from the dead, on one board. No lecture.
}

=== function toy_lesso_ev(what)
{stopping:
- At the end of the lot, a car charger in its own bay painted green, and over its head a black garbage bag, taped round its neck with packing tape. On the bag, on a sheet of paper: OUT OF ORDER, since the rebate ended, - mgmt. Under it in a different pen: the gas pumps work fine :)
- The charger with the bag over its head, taped at the neck. Nobody had charged anything since spring.
}

=== function toy_lesso_air(what)
{stopping:
- An air machine on the corner of the store, yellow, its hose in a coil on its hook. AIR $2. It used to be free. So did a lot of things.
- Air, two dollars. He breathed some of the other kind.
}

=== function toy_lesso_news(what)
{stopping:
- A paper box by the door, blue, the front page through its window: THE ISLAND SENTINEL. TOMORROW, $2.50, WEATHER: YES. LOCAL MAN READS HEADLINE, LEAVES. A photograph under it of a man from behind, going.
- He read the date again. It said tomorrow. The box took coins only, and he had none.
- LOCAL MAN READS HEADLINE, LEAVES. He stood there. Ferry cancelled, A3.
}

=== function toy_lesso_wood(what)
{stopping:
- Firewood on a pallet against the end of the store, in net bundles. FIREWOOD $9, dry-ish, honour system. (there is a camera). (it is a box). The box was up under the eave, a cardboard one, painted black, with a bottle cap for a lens.
- The firewood. One bundle short since the last time he looked, and the honour system still up.
}

=== function toy_lesso_fluid(what)
{stopping:
- Blue jugs of washer fluid stacked by the ice. -40° WASHER, 2 FOR $9. It has never once been -40 here. But you never know, do you.
- Minus forty. It was eight above and raining.
}

=== function toy_lesso_pump(what)
{stopping:
- A note taped to the pump over the card slot: PAY INSIDE. The card reader has feelings. Swipe gently.
- The card reader, and its feelings.
}

=== function toy_lesso_phone_wall(what)
{stopping:
- The end wall round the payphone, written on in Sharpie and key, a phone's worth of waiting. THIS PHONE HAS NOT BEEN CONNECTED SINCE 2012, and under it, so who keeps calling.
- {cycle:
    - GAS WAS $1.09. I was there. Under it, in red: you're old.
    - The kid inside is a robot. Under it, in green: I'm not. - the kid. And under that: (four cents).
    - GOD IS A PAYPHONE, in purple, the letters gone over twice. You have to put something in. Somebody had added: and nobody picks up.
    - TAXES DONE, cash, no questions. Ask for Ron. (Not that Ron.)
    - I'm leaving this island. Signed, in a different hand: everybody, every spring.
    - CALL YR MOTHER, big, across the bottom, and under it, smaller: she knows you read this.
    - A sticker, BRING BACK THE MILL, half peeled. The mill had been gone since before the phone.
  }
}
