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

// ------------------------------------------------------------------ the set dressing
// What's on the walls and the floor (godot/world/dressing.gd): the beer posters and the calendar,
// the signs, the corkboard, the beer clock, the neon, the glasses and the glasswasher, the hall's
// hole, the signs by the door and what's on the gravel, the Esso's window. The brands are made up.

=== function toy_poster_boors(what)
{stopping:
- BOORS LIGHT. COLD AS YOUR EX. A blonde in a bikini the colour of a glacier, standing in snow to her shins in nothing else, the can up by her ear as if it had said something. The window had taken the blue out of the top half of her. Somebody had put a piece of tape back over the bottom corner where she'd come away from the wall.
- Still cold. So was the ex.
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
    He flipped it back. The amber lamp came on, the motor caught, and the belt took up where it had left off as if it hadn't noticed.
- else:
    {shuffle:On. The hum came back and the room sank under it.|He switched it on again. The belt went on.}
}

=== function toy_wall_hole(what)
{stopping:
- A hole in the hall side of the wall at about the height of a big man's fist, the paper of the board torn back round it, and a beer mat taped over half of it, as if that was the half that mattered.
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
- Ads taped to the outside of the Esso's window, the sun and the squeegee gone over them: ICE, 2 BAGS $5, it is still just water. LOTTO MOST, $40 MILLION, somebody has to. SMOKES behind the counter, ask, PRICES UP AGAIN, not our fault, ask Ottawa. ROLLER GRILL 2 for $4, since this morning. On the door, WE ID everyone under 30, and anyone who argues.
- Ice, smokes, the lotto. Since this morning.
}
