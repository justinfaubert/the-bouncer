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
{stopping:
- The dartboard on the east wall, in its cabinet with the doors open, and the line on the carpet where you stood to throw. Three darts in the board, in nothing much. Nobody had played tonight.
- The three darts, where they'd been.
}

=== function toy_tv(what)
{
- clock < 1380:
    {stopping:
    - The TV over the back wall, on the hockey with the sound off: home two, away one, in the second. Table 28 watched it the way they watched the door, all of them at once, and only when something happened.
    - Still two to one.
    }
- else:
    {stopping:
    - The game was over. They were showing the goals again, each one from three angles, and table 28 watched as if one of them might come out different.
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
- Four house cues in the rack on the back wall, each one warped its own way, and one with no tip. The ones who could play brought their own.
- The house cues, in the rack.
}

=== function toy_pool_table(what)
{stopping:
- The pool table, under its light, with a lean to it that everyone who played here knew about and nobody else did.
- The pool table{pool_still():, the big man walking round it|, nobody at it}.
}

=== function toy_t28(what)
{stopping:
- Table 28, the big round one in the front window, {num(t28_rounds)} rounds in. Somebody at it was always talking and nobody was ever listening, and none of them ever missed a word.
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
- The back bar: three shelves of bottles against the mirror, the rail stuff on the bottom where she could reach it without looking, and up top the good scotch, dusty at the shoulders.{here != hall: In the mirror, between the bottles, the room, and him in it, bigger than he ever thought of himself.}
- The bottles{here != hall:, and him in the mirror behind them}.
}

=== function toy_taps(what)
// HUTCH: What's on tap at a pub like yours?
{stopping:
- Six taps on the steel bar, their handles facing the room in the brewers' colours: two lagers, a pale ale, a red, a stout, a cider.
- The taps.
}
{ clock >= 1320 && not at_keg.change_keg:
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

=== function toy_book(what)
{stopping:
- The incident book on the ledge, a hardcover with a pen tied to the spine on a string. Other men's handwriting all the way back, and room left for his.
- The book, shut, the pen on its string.
}


// ------------------------------------------------------------------ the back hall, the kitchen, the keg room

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
- Past the last of the kegs the concrete gave out to dirt, and the old pilings stood up out of it in no kind of order, black, the way they'd been driven into the beach before there was any building on it. The dirt was damp. The water wasn't far.
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
