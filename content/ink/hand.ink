// His hand: what he carries, and what he makes of a thing he's holding.
// (bible/11_SKELETON.md, What he carries, and Handling. The skeleton's third milestone: Claude's
// draft, PROPOSED in bible/05_LOG.md.)
//
// His pockets are the inventory: a jacket with two outside pockets and an inside one, and his
// jeans, where his wallet is (his licence, his cash). Each holds one thing, or a few small ones.
// What's in the right outside pocket is in his hand fastest; what's in the inside pocket nobody
// sees until somebody pats him down. What he puts down for later is in the lost-and-found drawer
// behind the bar, or up in room twelve. The engine shows all of it on his notes (Game.pockets),
// with what each thing is in content/data/props.yaml.
//
// Handling (DECIDED: "look at something in their hand and choose what to do with it/what to think
// about it"). Every time he holds something the player makes two choices. What to do with it is
// the scene's own choices. What to think about it is the voices': each seated voice reads the thing,
// and he keeps one read, or none. A scene offers the reads with a thread beside its own choices:
//
//     - (opts)
//     <- reads_keys(-> opts)
//     * [Behind the bar, in the drawer.] ...
//
// A read is a choice tagged #read: <voice> <thing>. It takes no time; it comes back to the scene's
// choices with the reads gone. The engine keeps it (his notes put it beside the thing), and the
// voice is heeded from then on: it speaks up more often (prototype/web/src/core/barks.js). The Ink
// can ask kept_read("thing") (the voice, or "") and heeded(voice) (how many reads of his he's kept).
// The engine only offers the reads of voices that are in the room, so write one for each.

// What he can carry, or put down for later. (The pint he pours himself, the fifty from table 28, the
// TV remote and the big man's phone are things he holds for a moment and has read, but never
// carries: content/data/props.yaml.) The big man's jacket and GOOD SHOES's wallet are room.ink's.
LIST things = flashlight, room_key, gary_shirt, straw, truck_keys, float_bag, beer_mat, ferry_tickets, minor_card, aikido_book, last_jacket, bm_coat, gs_wallet

// On him. The flashlight's his own, from his last door. Gary's shirt goes inside his jacket in the
// office, if he takes it, and the key to twelve in his jeans with his wallet (office.ink).
VAR in_right = (flashlight)
VAR in_left = ()
VAR in_inside = ()
VAR in_jeans = ()
// Put down for later: the lost-and-found drawer behind the bar, and room twelve, over the deck.
// The last doorman's jacket and the paperback are in the drawer already (drawer.ink), and the
// jacket's own pockets have what he left in them.
VAR in_drawer = (last_jacket, aikido_book)
VAR in_twelve = ()
VAR in_jacket = (float_bag, beer_mat, ferry_tickets, minor_card)
VAR drawer_seen = false     // he's had the drawer open: his notes show what's in it

// What he does with what's in his hands tonight
VAR float_how = 0           // the last doorman's float bag: 1 gave it to her, 2 put it back, 3 took the money
VAR jacket_done = false     // he's been through the last doorman's jacket
VAR jacket_how = 0          // the jacket itself: 1 back in the drawer, 2 took it up to twelve
VAR showed_her = ()         // the jacket's things he showed the bartender
VAR keys_how = 0            // the big man's keys: 1 the drawer, 2 his own pocket, 3 the daughter
VAR keys_back = 0           // at the hotel door at two: 1 gave them back, -1 kept them
VAR she_poured = 0          // drinks she poured him on shift (bar.ink, the shift drink)
VAR poured_self = 0         // drinks he poured himself behind her bar (bar.ink, the pour)
VAR pour_how = 0            // the pint he poured himself: 1 drank it and rinsed the glass, 2 took it to the ledge, 3 poured it down the sink; -1 she caught him
VAR watched_bar = false     // he watched her bar while she changed the keg
VAR lager_down = false      // she went down the trapdoor to change the lager (bar.ink)

=== function on_him(t)
~ return in_right ? t || in_left ? t || in_inside ? t || in_jeans ? t

// Out of wherever it was: his pockets, the drawer, room twelve, the last doorman's jacket.
=== function unstow(t)
~ in_right -= t
~ in_left -= t
~ in_inside -= t
~ in_jeans -= t
~ in_drawer -= t
~ in_twelve -= t
~ in_jacket -= t

// Into one of those, out of wherever it was before.
=== function stow(t, ref into)
~ unstow(t)
~ into += t

// Into his own pockets, where a thing like that goes: the small hard things in the left outside
// pocket (the right's the flashlight's), paper and the rest inside.
=== function pocket(t)
{
- t == straw || t == truck_keys:
    ~ stow(t, in_left)
- else:
    ~ stow(t, in_inside)
}

// What a thing's called in a line: "Put {the_thing(straw)} in the drawer."
=== function the_thing(t)
{
- t == flashlight:
    ~ return "his flashlight"
- t == room_key:
    ~ return "the key to twelve"
- t == gary_shirt:
    ~ return "Gary's shirt"
- t == straw:
    ~ return "the straw"
- t == truck_keys:
    ~ return "the big man's keys"
- t == float_bag:
    ~ return "the float bag"
- t == beer_mat:
    ~ return "the beer mat"
- t == ferry_tickets:
    ~ return "the ferry tickets"
- t == minor_card:
    ~ return "the boy's licence"
- t == aikido_book:
    ~ return "the paperback"
- t == last_jacket:
    ~ return "the last doorman's jacket"
- t == bm_coat:
    ~ return "the big man's jacket"
- t == gs_wallet:
    ~ return "GOOD SHOES's wallet"
}
~ return "it"

// Whose reads he kept tonight, for the till tape (closing.ink, ledger): "THE FATHER three times,
// THE MANUAL once". The habits of mind a night makes, one thing at a time.
=== function heeds()
~ temp s = ""
~ s = heed_of(s, "father", "THE FATHER")
~ s = heed_of(s, "manual", "THE MANUAL")
~ s = heed_of(s, "fighter", "THE FIGHTER")
~ s = heed_of(s, "wrongman", "THE WRONG MAN")
~ s = heed_of(s, "table", "THE TABLE")
~ s = heed_of(s, "kid", "THE KID")
~ return s

=== function heed_of(s, v, label)
~ temp n = heeded(v)
{
- n == 0:
    ~ return s
- n == 1:
    ~ return comma(s) + label + " once"
- n == 2:
    ~ return comma(s) + label + " twice"
}
~ return comma(s) + label + " " + num(n) + " times"

// A list of them in a line: "the straw, the beer mat and the big man's keys".
=== function things_said(l)
{ LIST_COUNT(l):
- 0:
    ~ return ""
- 1:
    ~ return the_thing(l)
- 2:
    ~ return the_thing(LIST_MIN(l)) + " and " + the_thing(LIST_MAX(l))
- else:
    ~ return the_thing(LIST_MIN(l)) + ", " + things_said(l - LIST_MIN(l))
}


// ------------------------------------------------------------------ the reads
// One knot a thing. The voices in his head, in their own registers (bible/10_VOICES.md): THE FATHER's
// short door rules, THE MANUAL's course binder, THE FIGHTER's body read, THE WRONG MAN's retold
// story, and the two he can take home tonight, THE TABLE (all at once) and THE KID (lowercase).

// Gary's shirt, held up. In room twelve before the shift (walk.ink), or in the vestibule (prologue.ink).
=== reads_shirt(-> back)
{ kept_read("gary_shirt") != "": -> DONE }
+ [A man who needs a shirt to tell them hasn't got the job yet. #read: father gary_shirt]
    -> back
+ [Security workers must be identifiable to the public while on duty. The licensee supplies the uniform. #read: manual gary_shirt]
    -> back
+ [Too small across the shoulders. You can't swing in it. Maybe that's the idea. #read: fighter gary_shirt]
    -> back
+ [In the story, the wrong man came to the door in one of these. He said he was the new one. #read: wrongman gary_shirt]
    -> back
-> DONE

// His flashlight, out of his right pocket in the keg room (rats.ink).
=== reads_flashlight(-> back)
{ kept_read("flashlight") != "": -> DONE }
+ [Right pocket, every door I ever worked. You don't go looking for it when you need it. #read: father flashlight]
    -> back
+ [A flashlight is an inspection tool. Used to strike a person, it is a weapon, and the security worker may be charged. #read: manual flashlight]
    -> back
+ [Steel, with the weight at the end. It's a club that happens to have a light in it. #read: fighter flashlight]
    -> back
+ [In the story, the doorman shone his light into the dark down there, and something shone it back. #read: wrongman flashlight]
    -> back
+ [Look at him! Like the cops! #read: table flashlight]
    -> back
+ [put a licence under one and the hologram like jumps. you can see if it's real #read: kid flashlight]
    -> back
-> DONE

// The folded fifty the one in the team jacket tucks in his jacket pocket (table28.ink, tip_offer).
=== reads_fifty(-> back)
{ kept_read("fifty") != "": -> DONE }
+ [That's not a tip. That's a leash. #read: father fifty]
    -> back
+ [Gratuities from patrons are accepted only where the licensee's policy allows them. Ask before you keep it. #read: manual fifty]
    -> back
+ [He put his hand in your pocket and you let him. Nobody gets that close. #read: fighter fifty]
    -> back
+ [In the story, the doorman kept the first fifty. After that nobody had to ask him for anything. #read: wrongman fifty]
    -> back
+ [On us! He's one of us now! On us! #read: table fifty]
    -> back
+ [my dad does that. folds it small so you don't see how much till after #read: kid fifty]
    -> back
-> DONE

// A straw cut down to two inches, off the mirror in the office in the keg room (rats.ink).
=== reads_straw(-> back)
{ kept_read("straw") != "": -> DONE }
+ [I never touched that. I had the rye. Every man picks his poison and calls the other man's dirty. #read: father straw]
    -> back
+ [Possession of a controlled substance, or of anything carrying one, is an offence. A licence is no exemption. #read: manual straw]
    -> back
+ [Two inches. Somebody downstairs has done this a lot. #read: fighter straw]
    -> back
+ [In the story, they found it on him after. Nobody remembered he'd been the one to clean up. #read: wrongman straw]
    -> back
+ [The office! Like the mill office at Christmas! #read: table straw]
    -> back
+ [that's kyle's. or it's whoever kyle buys off #read: kid straw]
    -> back
-> DONE

// The big man's truck keys, at close (closing.ink). The skeleton's own example of handling.
=== reads_keys(-> back)
{ kept_read("truck_keys") != "": -> DONE }
+ [That's a man's pride in your hand. Give it to his girl, not to him. Not tonight. #read: father truck_keys]
    -> back
+ [If he drives, it's on the Sov. Keys held by staff are held for the licensee, and so is anything that happens after. #read: manual truck_keys]
    -> back
+ [Close your hand on them. Now they're a fist. #read: fighter truck_keys]
    -> back
+ [A rabbit's foot off a kid's hockey bag, on a ring with a Ford key. In the story, that's the part they find in the ditch. #read: wrongman truck_keys]
    -> back
+ [He'll be back for those! Two in the morning, every time! Every time! #read: table truck_keys]
    -> back
+ [the foot's off my hockey bag. he took it off when i quit #read: kid truck_keys]
    -> back
-> DONE

// The pint he pulled himself behind her bar while she was down the trapdoor (bar.ink).
=== reads_pint(-> back)
{ kept_read("pint") != "": -> DONE }
+ [Behind somebody's back. That's how I drank for twenty years. Behind somebody's back. #read: father pint]
    -> back
+ [Staff may not serve themselves. Every drink poured on the premises is rung through the till. #read: manual pint]
    -> back
+ [Cold, and it's yours. Drink it before she's up the stairs. #read: fighter pint]
    -> back
+ [In the story, the doorman was behind the bar with a glass in his hand when the wrong man walked in. #read: wrongman pint]
    -> back
+ [Atta boy! Never wait to be served! Never! #read: table pint]
    -> back
+ [she'd have poured you one if you asked. that's the thing #read: kid pint]
    -> back
-> DONE

// The last doorman's jacket (drawer.ink): the float bag from its right pocket.
=== reads_float(-> back)
{ kept_read("float_bag") != "": -> DONE }
+ [He took what he was owed and left the rest where anybody could take it. An honest man, or one who wanted it known he was. #read: father float_bag]
    -> back
+ [Cash discrepancies are reported to management in writing, the same night. #read: manual float_bag]
    -> back
+ [Two hundred and eight dollars nobody's counted since October. #read: fighter float_bag]
    -> back
+ [In the story, the money's still there after. That's how they knew he didn't leave on his own. #read: wrongman float_bag]
    -> back
+ [The float! Told you! I was sitting right there! #read: table float_bag]
    -> back
+ [he could've taken all of it. he didn't. that's kind of the whole thing #read: kid float_bag]
    -> back
-> DONE

// The beer mat from its left pocket, with his count of them on it, and the drawing.
=== reads_mat(-> back)
{ kept_read("beer_mat") != "": -> DONE }
+ [A man counts what he's afraid of. I counted drinks for twenty years. #read: father beer_mat]
    -> back
+ [Pest sightings: date, location, and a report to the licensee. He did two of the three. #read: manual beer_mat]
    -> back
+ [That's not a count. That's an army coming. #read: fighter beer_mat]
    -> back
+ [In the story, the doorman who saw it drew it once, so he could stop seeing it. It didn't work. #read: wrongman beer_mat]
    -> back
+ [Scratch was right! The big rat! He's never right and he was right! #read: table beer_mat]
    -> back
+ [everything doubles if you leave it alone long enough #read: kid beer_mat]
    -> back
-> DONE

// The two ferry tickets from its inside pocket.
=== reads_tickets(-> back)
{ kept_read("ferry_tickets") != "": -> DONE }
+ [Two tickets and one jacket. Somebody didn't get on that boat. #read: father ferry_tickets]
    -> back
+ [Personal effects left on the premises are held thirty days, then disposed of. It's been thirty-three. #read: manual ferry_tickets]
    -> back
+ [A woman. A man walks out over a woman, not over money. #read: fighter ferry_tickets]
    -> back
+ [In the story, he bought two and waited at the terminal, and she never came. Or she waited, and he never did. #read: wrongman ferry_tickets]
    -> back
+ [A woman! What did he say? A woman! #read: table ferry_tickets]
    -> back
+ [the last boat's eleven fifteen. you miss it you're here till morning #read: kid ferry_tickets]
    -> back
-> DONE

// The licence from its inside pocket: the one he let in. (Macaulay is the name on it in
// content/data/props.yaml, Claude's draft. HUTCH: rename.)
=== reads_card(-> back)
{ kept_read("minor_card") != "": -> DONE }
+ [He took the card and let the boy in anyway. That's the whole job, done backwards. #read: father minor_card]
    -> back
+ [Identification taken at the door is surrendered to police or returned to the issuing office. It is not kept. #read: manual minor_card]
    -> back
+ [Eighteen. Old enough to sign up. Not old enough for a beer. #read: fighter minor_card]
    -> back
+ [In the story, the wrong man's a boy, at first. That's why they let him in. #read: wrongman minor_card]
    -> back
+ [That's the Macaulay kid! In here every Friday till they caught him! #read: table minor_card]
    -> back
+ [he was the year under me. everybody knew he got in here #read: kid minor_card]
    -> back
-> DONE

// The paperback at the bottom of the drawer, under the glove.
=== reads_book(-> back)
{ kept_read("aikido_book") != "": -> DONE }
+ [I never read a book about the door. You learn the door on the door. #read: father aikido_book]
    -> back
+ [Force must be proportionate. Restraint techniques are to be taught by a qualified instructor. #read: manual aikido_book]
    -> back
+ [Wrist locks. Pretty. You'll be on your back while you're being pretty. #read: fighter aikido_book]
    -> back
+ [In the story, the doorman learned to put a man down without hurting him. It was the one time he should have hurt him. #read: wrongman aikido_book]
    -> back
+ [Karate! Look at him! The Karate Kid! #read: table aikido_book]
    -> back
+ [my sister did that for like a year. she can still do the wrist thing #read: kid aikido_book]
    -> back
-> DONE

// The TV remote, from under her bar rag at eleven (room.ink, the_remote).
=== reads_remote(-> back)
{ kept_read("remote") != "": -> DONE }
+ [Whoever has that decides what the room looks at. Make it look at something that isn't you. #read: father remote]
    -> back
+ [Programming shown on licensed premises is the licensee's responsibility. Sport and weather are recommended. #read: manual remote]
    -> back
+ [Five of them watching your thumb. Good. A hand's easier to read than a face. #read: fighter remote]
    -> back
+ [In the story, somebody turned the TV off, and that's when everybody heard it start. #read: wrongman remote]
    -> back
+ [The game! Put the game back on! The game! #read: table remote]
    -> back
+ [dad falls asleep with it on his chest. you can't get it off him, he wakes up #read: kid remote]
    -> back
-> DONE

// The big man's phone, out of his jacket on the hook, with his daughter on it (room.ink, the_cell).
=== reads_cell(-> back)
{ kept_read("bm_cell") != "": -> DONE }
+ [Your mother rang the Legion every night for a year. I told them to tell her I'd gone. #read: father bm_cell]
    -> back
+ [Staff may handle a patron's property only to secure it. Reading it is a breach of the patron's privacy. #read: manual bm_cell]
    -> back
+ [It's his. If he turns round now, you're a man with his hand in another man's coat. #read: fighter bm_cell]
    -> back
+ [In the story, the phone rang all night in the coat, and the man who should have answered it was right there, playing pool. #read: wrongman bm_cell]
    -> back
+ [Answer it! Tell her he's not here! #read: table bm_cell]
    -> back
+ [that's kayla. she'll call till it dies. she did it to me in the summer #read: kid bm_cell]
    -> back
-> DONE

// GOOD SHOES's wallet, off the carpet by his stool (room.ink, the_wallet).
=== reads_wallet(-> back)
{ kept_read("gs_wallet") != "": -> DONE }
+ [A man's wallet is the whole of him, folded. Give it back the way you found it. #read: father gs_wallet]
    -> back
+ [Lost property is logged, secured, and returned to its owner on proof of identity. His identity is page three. #read: manual gs_wallet]
    -> back
+ [Thick. He'll be back for that inside the hour, and he won't be smiling when he finds out who's got it. #read: fighter gs_wallet]
    -> back
+ [In the story, the wrong man came back for his wallet. That's how he got in the second time. #read: wrongman gs_wallet]
    -> back
+ [Drinks are on the barred fella! On him! #read: table gs_wallet]
    -> back
+ [my dad's wallet is held together with a hair elastic. mom's #read: kid gs_wallet]
    -> back
-> DONE

// The big man's jacket, off the hook once he's gone without it (room.ink, take_coat).
=== reads_coat(-> back)
{ kept_read("bm_coat") != "": -> DONE }
+ [He went out without it. That's how you know where he was going mattered. #read: father bm_coat]
    -> back
+ [Clothing left on the premises is recorded by date and description and stored securely until claimed. #read: manual bm_coat]
    -> back
+ [Wet at the shoulders. Heavy. Same size as you. #read: fighter bm_coat]
    -> back
+ [In the story, the coat stayed on the hook a year. Nobody moved it. Nobody wanted to be the one. #read: wrongman bm_coat]
    -> back
+ [That's Moffat's! The mill coat! He'll be back for that! #read: table bm_coat]
    -> back
+ [mom got him that for christmas. he says it's too good for work so he wears it to the bar #read: kid bm_coat]
    -> back
-> DONE
