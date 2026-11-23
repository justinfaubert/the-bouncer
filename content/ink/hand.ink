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
VAR she_poured = 0          // drinks he poured him on shift (bar.ink, the shift drink)
VAR poured_self = 0         // drinks he poured himself behind his bar (bar.ink, the pour)
VAR pour_how = 0            // the pint he poured himself: 1 drank it and rinsed the glass, 2 took it to the ledge, 3 poured it down the sink; -1 he caught him
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
// door rules and what he remembers of his own drinking, THE MANUAL's course binder, THE FIGHTER's body
// read, THE WRONG MAN's story as a drunk retold it (he was never sure of it), and the two he can take
// home tonight, THE TABLE (all at once) and THE KID (lowercase).

// Gary's shirt, held up. In room twelve before the shift (walk.ink), or in the vestibule (prologue.ink).
=== reads_shirt(-> back)
{ kept_read("gary_shirt") != "": -> DONE }
+ [I never wore one in thirty years. They knew who I was. #read: father gary_shirt]
    -> back
+ [Security workers must be identifiable to the public while on duty. The licensee supplies the uniform. #read: manual gary_shirt]
    -> back
+ [Too small across the shoulders. Lift your arms in it and the seams go. #read: fighter gary_shirt]
    -> back
+ [In the story the wrong man came to the door in one of these and said he was the new one. #read: wrongman gary_shirt]
    -> back
-> DONE

// His flashlight, out of his right pocket in the keg room (rats.ink).
=== reads_flashlight(-> back)
{ kept_read("flashlight") != "": -> DONE }
+ [Right pocket, every door I ever worked. You don't go looking for it when you need it. #read: father flashlight]
    -> back
+ [A flashlight is an inspection tool. Used to strike a person, it is a weapon, and the security worker may be charged. #read: manual flashlight]
    -> back
+ [Steel, three D batteries. Swing it backhand, low, at the knee. #read: fighter flashlight]
    -> back
+ [In the story the doorman went down the cellar with a light, and the drunk said there were eyes down there. A lot of eyes. He'd had a few by then. #read: wrongman flashlight]
    -> back
+ [Look at him! Like the cops! #read: table flashlight]
    -> back
+ [put a licence under one and the hologram like jumps. you can see if it's real #read: kid flashlight]
    -> back
-> DONE

// The folded fifty the one in the team jacket tucks in his jacket pocket (table28.ink, tip_offer).
=== reads_fifty(-> back)
{ kept_read("fifty") != "": -> DONE }
+ [Ray Sinclair used to tip me fifty. I let him drive home three times I shouldn't have. #read: father fifty]
    -> back
+ [Gratuities from patrons may be accepted only where the licensee's written policy allows them. #read: manual fifty]
    -> back
+ [He put his hand in your pocket and you let him. #read: fighter fifty]
    -> back
+ [In the story the doorman took a fifty off somebody his first night. The drunk couldn't remember who, only that it went bad after. #read: wrongman fifty]
    -> back
+ [On us! He's one of us now! #read: table fifty]
    -> back
+ [my dad does that. folds it small so you don't see how much till after #read: kid fifty]
    -> back
-> DONE

// A straw cut down to two inches, off the mirror in the office in the keg room (rats.ink).
=== reads_straw(-> back)
{ kept_read("straw") != "": -> DONE }
+ [I never touched that. I had the rye. Rye's legal. #read: father straw]
    -> back
+ [Possession of a controlled substance, or of anything carrying one, is an offence. A licence is no exemption. #read: manual straw]
    -> back
+ [Two inches. Somebody downstairs has done this a lot. #read: fighter straw]
    -> back
+ [In the story they found one of those on the doorman after, and that was him finished in this town. The drunk always said it wasn't his. #read: wrongman straw]
    -> back
+ [The office! Like the mill office at Christmas! #read: table straw]
    -> back
+ [that's kyle's. or it's whoever kyle buys off #read: kid straw]
    -> back
-> DONE

// The big man's truck keys, at close (closing.ink). The skeleton's own example of handling.
=== reads_keys(-> back)
{ kept_read("truck_keys") != "": -> DONE }
+ [Give them to his girl, not to him. I used to drive you to hockey like that. #read: father truck_keys]
    -> back
+ [Keys surrendered by a patron are held on behalf of the licensee. The licensee may be liable for harm done by an intoxicated patron after he leaves (see Section 5, Liability). #read: manual truck_keys]
    -> back
+ [Put the Ford key between two fingers and close your hand. #read: fighter truck_keys]
    -> back
+ [In the story a truck went in the ditch on the hill road. The drunk said the keys were still in it. Then he said they weren't. #read: wrongman truck_keys]
    -> back
+ [He'll be back for those at two in the morning! Every time! #read: table truck_keys]
    -> back
+ [the foot's off my hockey bag. he took it off when i quit #read: kid truck_keys]
    -> back
-> DONE

// The pint he pulled himself behind her bar while she was down the trapdoor (bar.ink).
=== reads_pint(-> back)
{ kept_read("pint") != "": -> DONE }
+ [I kept a mickey in the cistern at the Legion for six years. #read: father pint]
    -> back
+ [Staff may not serve themselves. Every drink poured on the premises is rung through the till. #read: manual pint]
    -> back
+ [Cold, and it's yours. Drink it before she's up the stairs. #read: fighter pint]
    -> back
+ [In the story the doorman was behind the bar with a glass in his hand when the wrong man walked in. #read: wrongman pint]
    -> back
+ [Atta boy! Pour one for Walter! #read: table pint]
    -> back
+ [she'd have poured you one if you asked #read: kid pint]
    -> back
-> DONE

// The last doorman's jacket (drawer.ink): the float bag from its right pocket.
=== reads_float(-> back)
{ kept_read("float_bag") != "": -> DONE }
+ [He paid himself back to the dollar. When they shorted me I paid myself back with interest. #read: father float_bag]
    -> back
+ [Cash discrepancies are reported to management in writing, the same night. #read: manual float_bag]
    -> back
+ [Two hundred and eight dollars nobody's counted since October. #read: fighter float_bag]
    -> back
+ [In the story the money was still there after, and the cops said that meant something. The drunk never found out what. #read: wrongman float_bag]
    -> back
+ [The float! Told you! I was sitting right there! #read: table float_bag]
    -> back
+ [he could've taken all of it. i would've #read: kid float_bag]
    -> back
-> DONE

// The beer mat from its left pocket, with his count of them on it, and the drawing.
=== reads_mat(-> back)
{ kept_read("beer_mat") != "": -> DONE }
+ [I counted my drinks on beer mats too. I stopped counting when the numbers got big. #read: father beer_mat]
    -> back
+ [Pest sightings are recorded by date and location and reported to the licensee the same day. #read: manual beer_mat]
    -> back
+ [Thirty-five of anything is too many to fight. #read: fighter beer_mat]
    -> back
+ [In the story the doorman drew it on everything after: napkins, the back of his hand. The drunk kept one of the napkins for years. #read: wrongman beer_mat]
    -> back
+ [Scratch was right! First time since 1990! #read: table beer_mat]
    -> back
+ [we did that in math. rice on a chessboard. you run out of chessboard #read: kid beer_mat]
    -> back
-> DONE

// The two ferry tickets from its inside pocket.
=== reads_tickets(-> back)
{ kept_read("ferry_tickets") != "": -> DONE }
+ [I bought two once. Your mother used hers. #read: father ferry_tickets]
    -> back
+ [Personal effects left on the premises are held for thirty days and then disposed of. #read: manual ferry_tickets]
    -> back
+ [One way, on foot, no car. That's how you leave when somebody's after you. #read: fighter ferry_tickets]
    -> back
+ [In the story he bought two and waited at the terminal, and she never came. The drunk's wife said it was him that never came. #read: wrongman ferry_tickets]
    -> back
+ [A woman! Lorraine, in six! #read: table ferry_tickets]
    -> back
+ [the last boat's eleven fifteen. you miss it you're here till morning #read: kid ferry_tickets]
    -> back
-> DONE

// The licence from its inside pocket: the one he let in. (Macaulay is the name on it in
// content/data/props.yaml, Claude's draft. HUTCH: rename.)
=== reads_card(-> back)
{ kept_read("minor_card") != "": -> DONE }
+ [Holding a kid's card is how a doorman gets paid to look the other way. I held a few. #read: father minor_card]
    -> back
+ [Identification taken at the door is surrendered to police or returned to the issuing office. It is not kept. #read: manual minor_card]
    -> back
+ [A hundred and forty pounds, maybe. You could carry him out under one arm. #read: fighter minor_card]
    -> back
+ [In the story the wrong man looked about sixteen. That's how he got in. #read: wrongman minor_card]
    -> back
+ [That's the Macaulay kid! In here every Friday till they caught him! #read: table minor_card]
    -> back
+ [he was the year under me. everybody knew he got in here #read: kid minor_card]
    -> back
-> DONE

// The paperback at the bottom of the drawer, under the glove.
=== reads_book(-> back)
{ kept_read("aikido_book") != "": -> DONE }
+ [Thirty years on doors and I never read a book about it. #read: father aikido_book]
    -> back
+ [Force must be proportionate. Restraint techniques are to be taught by a qualified instructor. #read: manual aikido_book]
    -> back
+ [Wrist locks. Try one on a drunk who goes two-forty and see where you end up. #read: fighter aikido_book]
    -> back
+ [In the story the doorman took some class at the hall and went soft, the drunk said. The drunk never took a class in his life. #read: wrongman aikido_book]
    -> back
+ [Karate! Wax on, wax off! #read: table aikido_book]
    -> back
+ [my sister did that for like a year. she can still do the wrist thing #read: kid aikido_book]
    -> back
-> DONE

// The TV remote, from under her bar rag at eleven (room.ink, the_remote).
=== reads_remote(-> back)
{ kept_read("remote") != "": -> DONE }
+ [Put the curling on. I never saw a fight over curling. #read: father remote]
    -> back
+ [Programming shown on licensed premises is the licensee's responsibility. Sport and weather are recommended. #read: manual remote]
    -> back
+ [Five of them watching your thumb and nobody watching the door. #read: fighter remote]
    -> back
+ [In the story somebody turned the TV off and the whole bar heard something under the floor. The drunk said like a lot of little feet. Then he said like rain. #read: wrongman remote]
    -> back
+ [Put the game back on! #read: table remote]
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
+ [In the story a phone rang in a coat on the hook all night and nobody answered it. The drunk said he should have. #read: wrongman bm_cell]
    -> back
+ [Answer it! Tell her he's not here! #read: table bm_cell]
    -> back
+ [that's kayla. she'll call till it dies. she did it to me in the summer #read: kid bm_cell]
    -> back
-> DONE

// GOOD SHOES's wallet, off the carpet by his stool (room.ink, the_wallet).
=== reads_wallet(-> back)
{ kept_read("gs_wallet") != "": -> DONE }
+ [Count it in front of him when you give it back. Then he can't say you took any. #read: father gs_wallet]
    -> back
+ [Lost property is logged, secured and returned to its owner on proof of identity. #read: manual gs_wallet]
    -> back
+ [Thick. He'll be back for it inside the hour, and he'll come in swinging. #read: fighter gs_wallet]
    -> back
+ [In the story the wrong man left his wallet on purpose, the drunk said, so he'd have a reason to come back in. #read: wrongman gs_wallet]
    -> back
+ [Drinks on the barred fella! #read: table gs_wallet]
    -> back
+ [my dad's wallet is held together with a hair elastic. mom's #read: kid gs_wallet]
    -> back
-> DONE

// The big man's jacket, off the hook once he's gone without it (room.ink, take_coat).
=== reads_coat(-> back)
{ kept_read("bm_coat") != "": -> DONE }
+ [He'll be back for it. I always went back for mine. #read: father bm_coat]
    -> back
+ [Clothing left on the premises is recorded by date and description and stored securely until claimed. #read: manual bm_coat]
    -> back
+ [Wet at the shoulders. Heavy. Same size as you. #read: fighter bm_coat]
    -> back
+ [In the story a coat hung on that hook for a year after. The drunk used to hang his on top of it. #read: wrongman bm_coat]
    -> back
+ [That's Moffat's! He'll be back for that! #read: table bm_coat]
    -> back
+ [mom got him that for christmas. he says it's too good for work so he wears it to the bar #read: kid bm_coat]
    -> back
-> DONE
