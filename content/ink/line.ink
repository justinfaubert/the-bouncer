// The line at the front door, one at a time: whoever's next comes up to the stool, and he lets
// them in on a nod, or on a look at the card, or reads it properly, or turns them away
// (bible/11_SKELETON.md, "The waves" and "Licences from the town"). Who they are, when they come,
// the card they hand him and what they say are the town's (prototype/web/src/core/folk.js,
// Folk.Door; the words, content/rules/door.yaml). What he does with them is here. Everything he
// does takes a minute but the handling, and the line builds in the rain behind them while he does
// it (PROPOSED since 27 September: slow checking builds a line, fast checking lets mistakes through).
//
// The door is asked through the externals in main.ink ("the door"). In a line, AT_DOOR: is
// whoever's at the stool, and OTHER: whoever else the door's talking about (a kid Paige found
// inside). The page names them by what he's tagged them (CANVAS COAT, TOQUE) till he's read the
// name on their card, and by that name from then on, tonight and the next time.
//
// Claude's draft, all of it (PROPOSED).

// Whoever's next in the line, from the stool to in or out. A tunnel: -> door_front -> wherever.
// Nobody waiting, and it comes straight back.
=== door_front ===
~ here = door
{ not door_next():
    ->->
}
{door_say("arrive")} #portrait: door
{
- door_has("why:card"):
    -> for_card
- door_has("why:back"):
    -> card
- door_has("known"):
    AT_DOOR: {door_say("known")}
- else:
    AT_DOOR: {door_say("greet")}
}
-> front

= front
+ [Nod {door_word("him")} through.]
    -> nod
+ {door_n("party") > 0} [Nod {door_word("him")} through, and the {num(door_n("party"))} with {door_word("him")}.]
    -> nod_all
+ ["ID, please."]
    -> card

= nod
~ pass(1)
~ door_act("nod")
~ let_in(1)
AT_DOOR: {door_say("nod_in")}
->->

= nod_all
~ pass(1)
~ temp k = door_act("nodall")
~ let_in(k)
AT_DOOR: {door_say("nod_in")}
{ stopping:
- The rest went in behind {door_word("him")}, shaking the rain off on the carpet, and he didn't look at any of them twice.
- The rest went in behind {door_word("him")}.
}
->->


// ------------------------------------------------------------------ the card

= card
~ pass(1)
{
- door_has("nocard"):
    -> no_card
- door_has("phone"):
    -> phone
}
{door_say("card_out")} #prop: {door_card()}
{ door_n("read") == 0 && day > 1:
    MANUAL: Look at the card. Then the face. Then the card. Ask what is on it. Those who memorised it answer quickly. Those who own it answer bored.
}
-> held_out

= held_out
+ [A look, and hand it back.]
    -> glance
+ [Read it properly.]
    -> take
+ [Scan it.]
    ~ door_act("take")
    -> scan

= glance
~ pass(1)
~ temp c = door_card()
{ door_act("glance"):
    ~ let_in(1)
    { cycle:
    - He looked at the card, at the face, at the card, and gave it back. #prop: {c} back
    - Card, face, card. He gave it back. #prop: {c} back
    - He gave it a look, and gave it back. #prop: {c} back
    }
    AT_DOOR: {door_say("in")}
    ->->
}
// A look was enough to stop his hand on the way back.
{door_say("caught")}
{ stopping:
- FATHER: That's why you look. Now read it.
- FATHER: Read it.
-
}
~ door_act("take")
-> read

= take
~ pass(1)
~ door_act("take")
{ cycle:
- He took it off {door_word("him")} and held it under the light over the stool.
- He took it and read it.
- He held it to the light.
}
-> read


// ------------------------------------------------------------------ reading it properly

= read
// whoever's gone from the line behind them while he does it
{door_say("news")}
+ {door_has("can:any")} [Ask {door_word("him")} what's on it.]
    -> ask
+ {not door_has("looked")} [Hold it up by {door_word("his")} face. #toy: door look]
    -> look
+ {not door_has("tilted") && not door_has("phone")} [Tip it under the light. #toy: door tilt]
    -> tilt
// Only the player's hands make this one: turning the card over.
+ {not door_has("flipped") && not door_has("phone")} [Turn it over. #toy: door flip #unlisted]
    -> flip
+ {not door_has("scanned")} [Scan it.]
    -> scan
+ {not door_has("sized")} [Size {door_word("him")} up. #check: father 11 {door_n("size_mod")}]
    -> size
+ {not door_has("chat")} ["{chat_q()}"]
    -> chat
+ ["In you go."]
    -> admit
+ ["Not tonight."]
    -> refuse
+ {door_has("doubt")} [Keep the card.]
    -> keep

= ask
+ {door_has("can:birthday")} ["When's your birthday?"]
    -> answer("birthday")
+ {door_has("can:year")} ["What year were you born?"]
    -> answer("year")
+ {door_has("can:sign")} ["What's your sign?"]
    -> answer("sign")
+ {door_has("can:middle")} ["What's your middle name?"]
    -> answer("middle")
+ {door_has("can:postal")} ["What's your postal code?"]
    -> answer("postal")
+ [Ask nothing.]
    -> read

// What they say, and what the card says, which he's holding. The Manual reads the card for him
// when they don't match; the Father hears it when they had to think.
= answer(q)
~ pass(1)
~ door_act("ask:" + q)
AT_DOOR: {door_say(q)}
{
- door_has("slip"):
    { stopping:
    - FATHER: {door_word("He")} said the real year first. People don't get their own year wrong. They get somebody else's right.
    - FATHER: The real year came out first. Hear it?
    }
- door_has("wrong") && q == "birthday":
    MANUAL: The card says the {door_word("card_day")} of {door_word("card_month")}.
- door_has("wrong") && q == "year":
    MANUAL: The card says {door_word("card_year")}.
- door_has("wrong") && q == "sign":
    MANUAL: The {door_word("card_day")} of {door_word("card_month")} is {door_word("card_sign")}. The course covered this. Nobody knows why.
- door_has("wrong") && q == "middle":
    MANUAL: The card says {door_word("card_middle")}.
- door_has("wrong") && q == "postal" && door_has("oldaddr"):
    MANUAL: The card says {door_word("card_postal")}. An address on a licence is the address on the day it was issued.
- door_has("wrong") && q == "postal":
    MANUAL: The card says {door_word("card_postal")}.
- door_has("hes") && door_has("drunk"):
    { stopping:
    - FATHER: {door_word("He")} had to think about it. Drink does that. So does a card that isn't yours. Which is it?
    -
    }
- door_has("hes"):
    { stopping:
    - FATHER: {door_word("He")} had to think about it. Nobody has to think about their own.
    - FATHER: Had to think.
    }
}
-> read

= look
~ door_act("look")
{door_say("look")}
{ door_has("looked:older"):
    { stopping:
    - WRONGMAN: Brothers lend brothers their licences. Sisters lend sisters. In the story the card was real. It just wasn't his.
    -
    }
}
-> read

= tilt
~ door_act("tilt")
{
- door_has("tilted:moves"):
    { cycle:
    - The hologram moved under the light the way it should: the waves ran, the seal turned over, and the sun came up out of the water.
    - The hologram moved the way it should.
    - It moved. Real foil.
    }
- door_has("tilted:still"):
    The hologram didn't move. At every angle it was the same flat shine, printed on top of the card like a picture of a hologram.
    { stopping:
    - MANUAL: A printed hologram does not move, because it cannot.
    -
    }
- door_has("tilted:ridge"):
    The hologram moved, but the light caught on something across the birthday: a ridge in the laminate, where it had been lifted and pressed down again.
    { stopping:
    - FATHER: Somebody's had a knife under that.
    -
    }
}
-> read

= flip
~ door_act("flip")
{
- door_has("flipped:blank"):
    The back was blank. White, nothing on it, the way the ones off the internet come when the printer only does one side.
- else:
    { cycle:
    - On the back, the barcode, the fine print, and the province's little crest.
    - The barcode on the back.
    }
}
-> read

= scan
~ pass(1)
~ door_act("scan")
{
- door_has("scan:ok"):
    { cycle:
    - The scanner on the ledge read the back and gave him a green light. #sfx: scanner_ok
    - Green. #sfx: scanner_ok
    - The scanner gave him green. #sfx: scanner_ok
    }
- door_has("scan:oop"):
    Green, and nothing else on its little screen. It had read a card from Alberta, and it didn't know what it was reading. #sfx: scanner_ok
    { stopping:
    - MANUAL: Identification from another province is acceptable. The scanner's opinion of it is not.
    -
    }
- door_has("scan:real"):
    Green, and on its little screen a birthday that wasn't the one on the front: {door_word("real_born")}. #sfx: scanner_ok
    { stopping:
    - MANUAL: The barcode is printed when the card is made. The front can be altered after. The back cannot, by the same person, with the same knife.
    -
    }
- door_has("scan:seen"):
    The scanner beeped twice and put a time up on its screen: {door_word("seen_at")}. It had had this card in it once already tonight. #sfx: scanner_bad
    { stopping:
    - MANUAL: The scanner keeps every card it is shown, with the time. This one has been shown twice.
    -
    }
- door_has("scan:expired"):
    The light came up amber: run out in {door_word("card_expired")}. #sfx: scanner_bad
- else:
    Red. Whatever was on the back, the scanner couldn't read it. #sfx: scanner_bad
    { door_has("phone"):
        { stopping:
        - MANUAL: The scanner reads cards. It does not read photographs of cards.
        -
        }
    }
}
-> read

= size
~ pass(1)
~ door_act("size")
{ passed:
    {door_say("size")}
- else:
    {door_say("size_fail")}
}
-> read

= chat
~ pass(1)
~ door_act("chat")
AT_DOOR: {door_say("chat")}
-> read


// ------------------------------------------------------------------ in, or out

= admit
~ pass(1)
~ temp c = door_card()
~ door_act("admit")
~ let_in(1)
{
- c != "" && door_had("phone"):
    He gave {door_word("him")} the phone back and stood aside. #prop: {c} back
- c != "":
    He gave {door_word("him")} the card back and stood aside. #prop: {c} back
- else:
    He stood aside.
}
AT_DOOR: {door_say("in")}
->->

= refuse
~ pass(1)
~ temp c = door_card()
~ door_act("refuse")
{
- c != "" && door_had("phone"):
    He gave {door_word("him")} the phone back and shook his head. #prop: {c} back
- c != "":
    He gave {door_word("him")} the card back and shook his head. #prop: {c} back
- else:
    He shook his head.
}
AT_DOOR: {door_say("refused")}
->->

// It doesn't go back to whoever handed it over. It goes on the ledge under the scanner, face down,
// for the bartender at close (friday.ink).
= keep
~ pass(1)
~ temp c = door_card()
~ door_act("keep")
He didn't give it back. He put it face down on the ledge under the scanner. #prop: {c} back
AT_DOOR: {door_say("kept")}
{ door_n("kept") == 1:
    MANUAL: Identification taken at the door is to be surrendered to police or returned to the issuing office. It is not to be kept. It is not to be given back.
}
->->


// ------------------------------------------------------------------ no card, or a picture of one

= no_card
AT_DOOR: {door_say("noid")}
+ ["Go and get it. I'll be here."]
    ~ pass(1)
    ~ door_act("back")
    {door_word("He")} went back down the steps into the rain.
    ->->
+ ["No card, no beer."]
    -> refuse
+ ["In you go. Bring it next time."]
    -> admit

= phone
{door_say("phone_out")} #prop: {door_card()}
{ stopping:
- FATHER: A picture of a card isn't a card.
-
}
-> phone_opts

= phone_opts
+ [Take the phone and look at the picture. #toy: door look]
    ~ pass(1)
    ~ door_act("take")
    -> look
+ ["A picture of a card isn't a card."]
    -> refuse
+ ["In you go."]
    -> admit


// ------------------------------------------------------------------ come for a card he kept

// A brother or a sister, whose licence the younger one brought to the door, come to get it back
// (Folk.Door, keep). It's on the ledge.
= for_card
AT_DOOR: {door_say("for_card")}
+ [Give it back.]
    ~ pass(1)
    ~ door_act("give")
    He took it off the ledge and gave it to {door_word("him")}. {door_word("He")} looked at the photo on it like {door_word("he")} was checking it was still {door_word("him")}.
    { stopping:
    - FATHER: That one's real. It just went out without its owner.
    -
    }
    -> front
+ ["It goes to the police. Your {door_word("teen_sib")} can tell them why {door_word("he")} had it."]
    ~ pass(1)
    ~ door_act("refuse")
    AT_DOOR: {door_say("refused")}
    ->->


// ------------------------------------------------------------------ helpers

// Everyone he let in past the stool goes on the door's count and into the room.
=== function let_in(n)
~ count_in += n
~ room_count += n

// What a doorman asks while he's holding the card, by who they look like. (Not by who they are:
// a teenager and a kid of twenty get the same question.)
=== function chat_q()
{
- door_has("wave:arena"):
    ~ return "How'd you do?"
- door_has("wave:swing"):
    ~ return "Long shift?"
- door_has("wave:legion"):
    ~ return "Legion put you out?"
- door_has("wave:ferry"):
    ~ return "Last boat?"
- door_has("wave:dinner"):
    ~ return "Here for the prime rib?"
- door_has("young"):
    ~ return "What's the occasion?"
}
~ return "How's your night been?"
