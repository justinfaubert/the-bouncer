// The lost-and-found: the drawer under the till, where the bartender puts whatever the night
// leaves behind (bible/11_SKELETON.md, What he carries: the lost-and-found box is his, DECIDED).
// He opens it from the bar (bar.ink: asking where the last doorman's jacket is, and after that
// whenever he's at the bar), and after hours, when he tells him the jacket's in it (closing.ink,
// last_doorman). What's in it, and what he puts in it or takes out, is hand.ink's (in_drawer).
//
// The last doorman's jacket is folded at the bottom, and nobody's been through the pockets.
// Claude's draft, PROPOSED in bible/05_LOG.md: there's a thing in the jacket for each of table 28's
// four stories about him (table28.ink, stories), and every one of them is true.
//   the pay      the door float in its bag, right pocket: four hundred, less two Fridays he was
//                paid short, with his sum on the back of the till tape
//   the big rat  a beer mat, left pocket: his count of them, doubling, and the knot, drawn
//   the woman    two ferry tickets, inside pocket: foot passengers, one way, the last boat on the
//                Friday he went, and neither one torn
//   let him in   a licence behind them: the boy he let in, who's in his binder now (page eight)
// Who the woman was, the jacket doesn't say (a writing prompt, at the inside pocket).
// Under the glove, a paperback on aikido (the skeleton's THE CIRCLE, for later).

VAR drawer_from = 0         // where he opened the drawer from: 1 the bar, mid-shift; 2 after hours
VAR book_seen = false       // he's had the paperback out from under the glove

// The last doorman drew where they are on his beer mat: it's easier to find them with the way drawn.
=== function mat_mod()
{ knows ? mat_seen:
    ~ return 2
}
~ return 0

// What's in the drawer to take out: not the jacket, which goes or stays whole, and not the paperback
// till he's found it under the glove.
=== function drawer_loose()
~ temp l = in_drawer - last_jacket - bm_coat
{ not book_seen:
    ~ l -= aikido_book
}
~ return l


=== the_drawer ===
~ here = bar
~ drawer_seen = true
~ pass(1)
{ the_drawer == 1:
    The bartender pulled the drawer out from under the till for him, and went back to {clock < CLOSE_TIME:his taps|the twenties}. #look: bartender
    Three winters of toques and phone chargers. A single glove, a pair of reading glasses, a baby's shoe, a lanyard from the mill, a phone with a cracked screen that nobody had come back for.
    At the bottom, folded under all of it, a man's work jacket, brown canvas, the elbows gone pale.
- else:
    The lost-and-found drawer under the till: the toques, the chargers, the glove{in_drawer ? last_jacket:, and the jacket folded at the bottom}.
}
-> dr_opts

= dr_opts
<- drawer_takes(drawer_loose(), -> dr_opts)
<- drawer_puts(in_left + in_inside - gary_shirt, -> dr_opts)
* {in_drawer ? last_jacket} [Go through the jacket's pockets.]
    -> jacket
* {in_drawer ? aikido_book} [The paperback under the glove.]
    -> book
+ [Shut the drawer.]
    -> shut

= shut
{ drawer_from == 2:
    -> after_hours.goodnight
}
-> at_bar.opts


// ------------------------------------------------------------------ the last doorman's jacket

= jacket
~ jacket_done = true
~ pass(2)
He went round behind the bar and lifted the jacket out from under everything, and shook it out. It had been folded a long time, and the creases stayed in. #prop: last_jacket
{ knows ? doorman_stories:
    Four stories, table 28 had told him. Three pockets.
}
-> right_pocket

// The pay: TEAM JACKET's "Owner shorted him two weeks running. Walked out on a Friday with the
// float in his pocket." The float was in his pocket. The pocket was in the jacket. Who wrote his
// cheques short, the bartender has an idea (bible/11_SKELETON.md, the bookkeeper).
= right_pocket
In the right pocket was a bank bag, the clear plastic kind with a zip, with money in it and a strip of till tape round the money. The door float. #prop: float_bag
On the back of the tape, in pencil: four hundred, less ninety-six, less ninety-six. Under the line, two hundred and eight. By each ninety-six, a Friday in September.
- (fl)
<- reads_float(-> fl)
* [Give it to the bartender.]
    ~ float_how = 1
    ~ unstow(float_bag)
    ~ rep(rep_staff, 1)
    The bartender counted it without looking like he was counting it, and read the tape, and turned it over and read the sum again.
    BARTENDER: Ninety-six, two Fridays running.
    BARTENDER: That's not Junior. Junior can't add.
    He put it in the till, under the tray, where the night's float went.
* [Put it back in the jacket.]
    ~ float_how = 2
    ~ stow(float_bag, in_jacket)
    He zipped it shut and put it back where it had been.
* [Take the money.]
    ~ float_how = 3
    ~ cash += 208
    He took the money out of the bag and put it in his wallet, and put the bag back in the pocket with the tape in it.
    The bartender had his back to him. In the back-bar mirror, between the bottles, a big man was going through another man's jacket.
- -> left_pocket

// The big rat: SCRATCH's "He saw the big rat, down in the keg room."
= left_pocket
~ knows += mat_seen
In the left pocket was a Sov beer mat, gone soft with carrying. On the back, in the same pencil, a column: the end of July, four. August, nine, and seventeen. The middle of September, thirty-five, with a ring round it. #prop: beer_mat
Under the column, gone over and over in places, a ring of rats with their heads out and their tails in the middle, knotted. Under the drawing: BEHIND 28.
{ knows ? knot_seen:
    He'd had his flashlight on that, under the front of the building. The last doorman had got the knot right.
}
- (mt)
<- reads_mat(-> mt)
* [Keep it.]
    ~ pocket(beer_mat)
    He put it in the inside pocket of his own jacket.
* [Put it back in the jacket.]
    ~ stow(beer_mat, in_jacket)
    He put it back where it had been.
- -> inside_pocket

// The woman: HEARING AID's "Woman."
// HUTCH: The woman the ferry tickets were for. Who was she, and why did neither of them get on the boat? The jacket doesn't say, and nothing in the night does yet. Yours, if you want her.
= inside_pocket
In the inside pocket were two ferry tickets, the paper kind from the machine at the terminal. Foot passengers, one way, the last sailing on Friday the second of October. Neither one had been torn. #prop: ferry_tickets
- (tk)
<- reads_tickets(-> tk)
* [Keep them.]
    ~ pocket(ferry_tickets)
    He put them in his own inside pocket.
* [Put them back.]
    ~ stow(ferry_tickets, in_jacket)
    He put them back where they'd been.
* [Show her.]
    ~ showed_her += ferry_tickets
    She looked at them a long time.
    BARTENDER: Eleven-fifteen. Last boat.
    The bartender gave them back to him and went {clock < CLOSE_TIME:down the bar to somebody who didn't need anything|back to the twenties, and counted the same ones twice}.
    ~ stow(ferry_tickets, in_jacket)
    He put them back in the jacket.
- -> licence

// The one he let in: CARDIGAN's "I think he let somebody in he shouldn't have." He held the
// boy's card at the door, the way some doormen do, and let him in on it. The bartender put the boy
// in the binder for three months, which runs out on his nineteenth birthday (content/data/props.yaml:
// binder, sleeve 8).
= licence
Behind the tickets was a driver's licence: a boy with his hair flat from a cap they'd made him take off for the photo. The birthday made him eighteen, nineteen in January. #prop: minor_card
{ knows ? eighty_six:
    He knew the face. Page eight of the binder, and under it, in the bartender's marker: THREE MONTHS.
}
- (lc)
<- reads_card(-> lc)
* [Keep it.]
    ~ pocket(minor_card)
    He put it in his own inside pocket.
* [Put it back.]
    ~ stow(minor_card, in_jacket)
    He put it back behind the tickets.
* [Show her.]
    ~ unstow(minor_card)
    BARTENDER: Page eight.
    He didn't need the binder.
    BARTENDER: Three months, and that's till his birthday, so don't look at me like that.
    The bartender took it off him and put it in the binder under the till, in the sleeve with the boy's picture.
- -> jacket_back

= jacket_back
That was all of it.
{ knows ? doorman_stories:
    { float_how == 3:
        FATHER: Now you're the doorman who took the float.
    - else:
        FATHER: I had him down for a thief.
    }
}
WRONGMAN: In the story somebody found the jacket too. The drunk couldn't remember if they ever found the man.
* [Fold it and put it back at the bottom of the drawer.]
    ~ jacket_how = 1
    He folded it along the old creases and put it back at the bottom with everything on top of it.
* [Take it up to twelve, after.]
    ~ jacket_how = 2
    ~ stow(last_jacket, in_twelve)
    He hung it on the hook behind the bar, by her coat, to take up after.
    BARTENDER: Thirty-three days. Take it.
- -> dr_opts


// ------------------------------------------------------------------ the paperback

// The skeleton's THE CIRCLE starts here: aikido, "from a paperback in the lost-and-found box or the
// class at the community hall" (bible/11_SKELETON.md, The voices). Reading it is for a later night.
= book
~ book_seen = true
~ pass(1)
Under the glove was a paperback with the cover half off: a man in white with his hands open, and another man going over his hip through the air. AIKIDO, in yellow. Folded in it for a bookmark, a flyer from the community hall: Tuesdays, seven o'clock, fifteen dollars, beginners welcome. #prop: aikido_book
- (bk)
<- reads_book(-> bk)
* [Keep it.]
    ~ pocket(aikido_book)
    He put it in the inside pocket of his jacket. It stuck out an inch.
* [Leave it under the glove.]
    ~ stow(aikido_book, in_drawer)
    He put it back under the glove.
- -> dr_opts


// ------------------------------------------------------------------ in and out

// A choice for each thing in the list. A thread can't loop, so each one threads itself again for
// the rest, smallest first.
=== drawer_takes(l, -> back)
{ LIST_COUNT(l) == 0: -> DONE }
~ temp t = LIST_MAX(l)
<- drawer_takes(l - t, back)
+ [Take {the_thing(t)} out of the drawer.]
    ~ pocket(t)
    He took {the_thing(t)} out of the drawer and put {t == ferry_tickets:them|it} in his pocket.
    -> back
-> DONE

=== drawer_puts(l, -> back)
{ LIST_COUNT(l) == 0: -> DONE }
~ temp t = LIST_MAX(l)
<- drawer_puts(l - t, back)
+ [Put {the_thing(t)} in the drawer.]
    ~ stow(t, in_drawer)
    He put {the_thing(t)} in the drawer, under a toque, for later.
    -> back
-> DONE
