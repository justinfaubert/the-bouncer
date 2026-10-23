// 4:00 pm. Gary Van Dusen's office on the old main street: the interview, the way Gary saw it.
//
// DECIDED (Hutch, 14 October): the game opens on a job interview with the boss, Gary Van Dusen,
// "as a POV of the boss"; his office isn't in the Sov's building; and the game can end right here
// if the player goes out of their way to be a dick: "hard not to get hired but not impossible".
// The rest is Claude's draft, PROPOSED in bible/05_LOG.md:
//   - The camera is Gary's eyes and the player answers as the doorman. The teller hands Gary the
//     opening because Gary was there first.
//   - Gary's reads of him show the way the voices in his head will, later: THE TILL (the money)
//     and SENIOR (his father, who bought the Sov in 1958). They're Gary's (voices.yaml, whose:
//     gary), only ever in this room, and never the doorman's.
//   - Nothing is rolled here. What he says sets his seven stats: a base (stats_base), and a point
//     on two of them for each answer that says something about him (stat_up), none past 7.
//   - What he claims is a fact Gary passes on (told_gary). The bartender has it by the time he
//     walks in (prologue.ink), and holds him to it at close (closing.ink, door_story).
//   - It ends badly only three ways: meaning a threat, walking out, or being rude to the two of
//     them twice. Caught lies cost him with Gary, but don't lose him the job: Gary needs a doorman
//     tonight, because the last one walked.

=== interview ===
~ here = office
~ clock = 960
~ stats_base()
# amb: office
// HUTCH: These opening lines are the first thing anyone reads. Rewrite them in the voice of whoever turns out to be telling this story, years later, at a bar.
NARRATOR: He started on a Wednesday. The Sov tried out doormen on Wednesdays, on a night slow enough that a mistake would only hurt a little.
NARRATOR: Of the thirty days, it was the one nobody else remembered.
NARRATOR: Except Gary. Gary was there first, and Gary told it for years, so it starts with Gary.
Four in the afternoon, and the lamp already on. VAN DUSEN HOLDINGS was the front room of Gary Van Dusen's mother's house on the old main street, across the road from the bank that had been a cafe for eleven years.
The rain had been at the window since noon. At the other desk the bookkeeper entered invoices with one finger, out of a mug from the bank.
Somebody came up the porch steps and filled the glass in the door, behind the gold letters, which from in here read SGNIDLOH NESUD NAV, the way they'd read for twenty years.
TILL: Here's twenty an hour.
-> arrive

= arrive
# sfx: door
He had to duck a little, coming in, and didn't make anything of it. #portrait: him
A big man. Not the kind they make on the mainland out of powder in a tub: big the way a fridge is big, all the way through. The long side of thirty. Hair to his shoulders, dark, wet from the walk. A string of wooden beads round his neck with a tassel on it. A work jacket, open, over a black T-shirt somebody had ironed.
SENIOR: Ironed a T-shirt.
TILL: Long hair. That's a complaint a week.
SENIOR: Your mother ironed yours till you were thirty, Junior.
OWNER: Come in, come in. Gary. Grab a seat.
* [Sit down.]
    ~ sat_how = 1
    ~ stat_up(stat_cha)
    ~ stat_up(stat_con)
    He sat, and the chair said something about it. He sat the way a man sits who's sat across a lot of desks and expected nothing from any of them.
    TILL: Doesn't fidget. Fidgeters steal.
* [Look round the room first.]
    ~ sat_how = 2
    ~ stat_up(stat_gut)
    ~ stat_up(stat_int)
    He didn't sit. He looked at the room first: the window, the bookkeeper, the box in the corner, the photo on the wall behind Gary's head, the way you'd look at a bar before you went into it. Then he sat.
    SENIOR: He's casing it.
    TILL: Or pricing it.
* [Lift the chair back a foot, and turn it. Then sit.]
    ~ sat_how = 3
    ~ stat_up(stat_wis)
    ~ stat_up(stat_str)
    He picked the chair up by one arm, a solid oak thing, and set it down a foot back and turned a quarter, without a sound on Gary's mother's floor, so the door was in the side of his eye. Then he sat.
    SENIOR: Lifted it. Didn't drag it.
    TILL: That floor's eight thousand dollars.
- -> the_room

// "The owner had mentioned that before he'd mentioned anything else" (closing.ink, go_upstairs).
= the_room
OWNER: So. First thing. There's a room.
OWNER: Upstairs at the Sov, end of the second floor, over the deck. Comes with the job. Six a month, and it comes off the top.
The bookkeeper wrote something down without being asked.
SENIOR: Six. I charged the last one four, and he still left.
OWNER: You got your licence on you? The security one.
* [Hand it to him.]
    ~ licence_how = 1
    He took it out of his wallet and held it out across the desk, the way you hand a man something you expect back.
* [Put it on the desk.]
    ~ licence_how = 2
    He put it on the desk, face up, and slid it the last few inches with two fingers, and left it for Gary to pick up.
    SENIOR: Makes you reach for it.
- -> licence_look

// The door, turned round: Gary does to him what he'll do to everyone (bible/11_SKELETON.md).
= licence_look
Gary did what he'd watched a hundred doormen do. He looked at the card, and at him, and at the card. #prop: his_licence
SECURITY WORKER, it said, with a seal in the corner, a number, a photo, and a name under Gary's thumb.
In the photo his hair was cropped short, the way they do it in the army, or after something.
SENIOR: Short hair, then. Something happened between that and this.
TILL: Good till next October. That's a year I don't pay for a course.
-> where_before

= where_before
OWNER: So where were you before this?
* ["A door in the city. Ten years."]
    ~ told_gary += tg_city
    ~ stat_up(stat_str)
    ~ stat_up(stat_cha)
    OWNER: Ten years. In the city.
    TILL: City money. He'll want city money.
    SENIOR: Ten years in the city, and he's here. Ask him why.
* ["Up island."]
    ~ told_gary += tg_up_island
    ~ stat_up(stat_con)
    ~ stat_up(stat_wis)
    OWNER: Where up island?
    He named a town. Gary had driven through it once, and not stopped.
    TILL: Up island wages. He'll take twenty and say thanks.
* ["Around."]
    ~ told_gary += tg_around
    ~ stat_up(stat_dex)
    ~ stat_up(stat_gut)
    OWNER: Around. Okay. Around.
    SENIOR: Around is a place you leave in the night.
* ["My father worked doors. I worked them with him."]
    ~ told_gary += tg_father
    ~ stat_up(stat_wis)
    ~ stat_up(stat_cha)
    OWNER: Yeah? Where?
    Up island, he said, a long time ago, and nothing after it.
    SENIOR: His father taught him.
    SENIOR: I taught you to count a till, Junior. That's what I taught you.
- -> why_left

// The bartender asks him the same thing at close (closing.ink, door_story), and she'll have had
// this answer from Gary by then.
= why_left
OWNER: And why'd you leave?
* ["The owner shorted me."]
    ~ told_gary += tg_shorted
    ~ stat_up(stat_int)
    ~ stat_up(stat_cha)
    OWNER: Ha. Well. That's not a thing here.
    BOOKKEEPER: Mm-hm.
    She didn't look up.
* ["Something happened."]
    ~ told_gary += tg_something
    ~ stat_up(stat_gut)
    ~ stat_up(stat_con)
    He didn't say what. Gary held up a hand before he could.
    OWNER: I don't need the how.
    TILL: Something happened is a lawyer.
    SENIOR: Something happened to all of them. Something happened to me.
* ["Long story."]
    ~ told_gary += tg_long
    ~ stat_up(stat_wis)
    ~ stat_up(stat_gut)
    OWNER: They all are, buddy. They all are.
* [Say nothing.]
    ~ told_gary += tg_quiet
    ~ stat_up(stat_con)
    ~ stat_up(stat_str)
    He looked at Gary and didn't say anything, for long enough that the bookkeeper stopped typing.
    TILL: Fine. Cheaper.
- -> fights

= fights
OWNER: You been in fights?
SENIOR: Look at his hands.
Gary looked at his hands. The knuckles had been split and healed and split again, white over the bone.
* ["Plenty."]
    ~ stat_up(stat_str)
    ~ stat_up(stat_con)
    OWNER: Plenty. Okay. Not in my bar, plenty.
    TILL: Plenty is a lawsuit.
* ["When I have to."]
    ~ stat_up(stat_wis)
    ~ stat_up(stat_dex)
    OWNER: Good. Good man.
    SENIOR: That's the answer. Nobody means it.
* ["I stop them."]
    ~ stat_up(stat_cha)
    ~ stat_up(stat_dex)
    OWNER: That's what I'm paying for. Stopping them.
    TILL: Twenty an hour to stop them. Thirty to start them, in the city.
* ["Never."]
    ~ told_gary += tg_never
    ~ lies_caught++
    Gary looked at the knuckles again, and then at him, and laughed once through his nose.
    OWNER: Never. Okay.
    SENIOR: A terrible liar. Good. It's the good ones that cost you.
* ["Want to find out?"]
    ~ threat = 1
    He said it quietly. The bookkeeper's finger stopped over the keyboard.
    TILL: Twenty an hour to say that to a drunk. To me?
    SENIOR: Get him out of your mother's house.
    -> threat_two
- -> the_call

= threat_two
* ["I'm kidding."]
    He let it go out of his face, and Gary let himself laugh, too loud.
    OWNER: Ha. Okay. Ha. Jesus.
    -> the_call
* [Hold his eye.]
    ~ threat = 2
    -> not_hired

// Fridays are prime rib night (bible/12_FROM_THE_DOOR.md, Hutch's story 4): the supplier is
// fictional, and so is Ron.
= the_call
The phone on the desk buzzed against the wood. Gary turned it over and looked at it, and held up one finger.
OWNER: Sorry. I gotta. Two minutes.
OWNER: Yeah. No. No, the halibut's Thursday. Friday's the prime rib. Friday, Ron. Friday is the prime rib.
TILL: Forty pounds at fourteen a pound.
* [Wait.]
    ~ call_did = 1
    ~ stat_up(stat_wis)
    ~ stat_up(stat_con)
    He waited the way big men learn to, without taking up any more of the room than he already did.
    SENIOR: Patient. The last one wasn't.
* [Look at the photo behind Gary.]
    ~ call_did = 2
    ~ knows += senior_photo
    ~ stat_up(stat_gut)
    ~ stat_up(stat_wis)
    He looked past Gary at the wall behind him, and kept looking.
    SENIOR: He's looking at me.
    It was the Sov in 1958, three storeys of new paint, SOVEREIGN on the roof with every letter lit. A man in a hat stood in front of the door with his hands behind his back, as if he'd paid cash for all of it, which he had.
* [Say something to the bookkeeper.]
    ~ call_did = 3
    ~ stat_up(stat_cha)
    ~ stat_up(stat_int)
    He turned in the chair and asked her how long she'd been doing Gary's books.
    BOOKKEEPER: His father's, and then his. Forty-one years in March. Before that I was at the bank.
    She looked at him over her glasses, properly, for the first time.
    BOOKKEEPER: Across the road. When it was a bank.
* [Read Gary's desk upside down.]
    ~ call_did = 4
    ~ knows += notice_read
    ~ stat_up(stat_int)
    ~ stat_up(stat_gut)
    His eyes went down to the papers on the desk and read them upside down, the way you read a licence across a ledge. Gary watched him do it.
    The top one was from the health authority. NOTICE OF ROUTINE INSPECTION. The fourteenth, and one word further down circled twice in pen: PEST.
    TILL: Reading my desk.
    SENIOR: Let him. It's his problem from tonight.
* [Get up and go.]
    -> walking_out
- (call_done) OWNER: Yeah. Yeah. Okay. Friday, Ron.
He put the phone back on its face.
OWNER: Sorry. Suppliers. Where were we.
-> do_you_drink

= walking_out
He stood up. Gary put a hand over the phone.
OWNER: Where you going?
* ["The washroom."]
    ~ call_did = 5
    BOOKKEEPER: Down the hall on the left. Jiggle it.
    He was back before Gary was done with Ron.
* [Sit back down.]
    ~ call_did = 6
    He sat back down, and Gary watched him for the rest of the call.
    TILL: Changed his mind. They do.
* ["Forget it."]
    -> not_hired
- -> the_call.call_done

= do_you_drink
OWNER: You drink?
* ["Yes."]
    ~ stat_up(stat_con)
    ~ stat_up(stat_cha)
    OWNER: Good. Good man. Not on my till.
    TILL: Honest. Costs me.
* ["Depends who's buying."]
    ~ stat_up(stat_cha)
    ~ stat_up(stat_int)
    OWNER: Ha! Not me, buddy.
    SENIOR: That one's funny. Watch the funny ones.
* ["Not on a shift."]
    ~ stat_up(stat_wis)
    ~ stat_up(stat_con)
    SENIOR: That's the right answer. Nobody means that one either.
* ["No."]
    ~ told_gary += tg_dry
    ~ lies_caught++
    BOOKKEEPER: Doug says a big fellow with hair closed the Legion last night.
    She said it to her screen.
    OWNER: Ha. Doug would know.
    { lies_caught > 1:
        SENIOR: Two. He couldn't lie to save his life. Hire him.
    - else:
        TILL: Liar. They all drink.
    }
- Gary opened the bottom drawer of the desk and came up with a bottle in a purple bag and two glasses that didn't match.
OWNER: It's four o'clock somewhere. It's four o'clock here.
He poured two fingers in each and pushed one across.
* [Drink it.]
    ~ gary_rye = 1
    He drank it in one, and put the glass back down where it had been.
    TILL: Drinks it like water.
    SENIOR: I'd have hired him for that.
* [Hold it, and don't drink it.]
    ~ gary_rye = 2
    He held the glass, and didn't drink from it, and didn't put it down.
    SENIOR: Holds it like the old fellow at the end of the bar.
    SENIOR: He held his like that in my day, too.
* [Push it back.]
    ~ gary_rye = 3
    He pushed it back across the desk with one finger.
    TILL: Back in the bottle.
    SENIOR: Your mother would have liked him.
* [Drink it, and hold out the glass.]
    ~ gary_rye = 4
    He drank it, and held out the glass. Gary laughed and filled it again, and he drank that too.
    OWNER: Ha! Okay! Okay.
    TILL: Two at four o'clock. On the floor by midnight.
- -> the_rule

// Table 28 don't get cut off: Junior's rule (bible/10_VOICES.md, the bartender), and his father's.
= the_rule
OWNER: Okay. Table 28.
OWNER: Five guys in the front window, every day but Sunday, since about the Flood. They don't get cut off. That's the rule.
SENIOR: That's my rule.
OWNER: That's my dad's rule. So one of them's had enough. More than. What do you do?
* ["Water. And I sit with him a while."]
    ~ scenario = 1
    ~ stat_up(stat_cha)
    ~ stat_up(stat_wis)
    OWNER: Water. Okay. Water doesn't go through the till, buddy.
    TILL: Water's free. Free costs.
* ["Whatever they want."]
    ~ scenario = 2
    ~ stat_up(stat_int)
    ~ stat_up(stat_con)
    OWNER: Good. Good man.
    SENIOR: That's what I said. I buried two of them, saying it.
* ["How's he getting home?"]
    ~ scenario = 3
    ~ stat_up(stat_wis)
    ~ stat_up(stat_gut)
    OWNER: He walks. They all walk. Mostly.
    TILL: Keys in the lot are on us.
* ["Put him out."]
    ~ scenario = 4
    ~ stat_up(stat_str)
    ~ stat_up(stat_dex)
    OWNER: Whoa. No. No no. That's not a thing.
    SENIOR: Put one out and they all go, and the money goes with them.
* (rude_gary) ["Must be nice. Owning a bar you never set foot in."]
    ~ rude++
    TILL: There it is.
    Gary's smile stayed where it was a second longer than a smile should.
    OWNER: I'm there. I'm there when I'm there, buddy.
- -> any_questions

= any_questions
OWNER: Questions? Anything?
* ["What happened to the last guy?"]
    ~ knows += old_doorman
    ~ knows += jacket_heard
    OWNER: He left. Friday, middle of the rush. Left his jacket.
    TILL: Owes me a jacket.
* {knows ? notice_read} ["What's on the fourteenth?"]
    -> dodged
* {knows !? notice_read} ["Anything I should know about?"]
    -> dodged
* ["When do I get paid?"]
    ~ asked_pay = true
    BOOKKEEPER: Fridays. By cheque. The first one's prorated.
    She said it the way she'd said things across a counter at the bank, to people who'd come in hoping for something else.
    TILL: Asks about money. Good. You know where you are with that.
* (no_questions) ["No."]
    OWNER: Good. Good man.
    TILL: No questions. No questions is cheap.
- -> the_deal

// The note on the till (prologue.ink) says what Gary won't say to his face.
= dodged
~ knows += gary_dodged
SENIOR: Don't say rats.
OWNER: There's an inspector. The fourteenth. Routine. There's a few. Things.
OWNER: You'll see a note.
-> the_deal

= the_deal
OWNER: Okay. Here's what it is.
OWNER: Twenty an hour. Tonight's cash, it's a test. After that it's Wednesday to Saturday, and the room comes off the top.
BOOKKEEPER: Six hundred and fifty. A month. With the hydro.
She read it off what she'd written, slowly, a number at a time, as if he might want to count along.
TILL: Hydro's fifty. Hydro was always fifty.
// A passive read (bible/11_SKELETON.md): past a threshold, he notices without being asked.
{ stat_int >= 5:
    He heard it. Gary saw him hear it.
- else:
    If he heard it, he didn't show it. Most of them didn't.
}
* {stat_int >= 5} ["Six, you said."]
    ~ rent_called = true
    OWNER: Did I? Well. Hydro.
    BOOKKEEPER: Mm-hm.
    She wrote something else down.
    SENIOR: He counts. Watch him.
* (rude_bk) ["Was anybody talking to you?"]
    ~ rude++
    The bookkeeper looked at him over her glasses, and smiled, which was worse.
    BOOKKEEPER: Thank you so much.
    { rude >= 2: -> not_hired }
    TILL: That's his first cheque.
* (let_go) [Let it go.]
    TILL: Six-fifty.
- -> the_shirt

// Hutch (14 October): "youd be hard-pressed for instance to find a doorman with the word
// 'SECURITY' on his shirt." The box in the corner is the mainland mistake (bible/11_SKELETON.md).
= the_shirt
OWNER: And wear this.
He reached over to the box in the corner and came up with a black T-shirt, and shook it out so he could see the back. SECURITY, in white letters a hand high.
TILL: Eleven dollars a shirt. Forty-eight shirts.
SENIOR: Nobody on this island ever wore a shirt that said what he was.
* [Take it.]
    ~ shirt = 1
    ~ stow(gary_shirt, in_inside)
    He took it, and folded it in four, and put it inside his jacket.
    OWNER: Good. Good man. Professional.
* ["I've got my own."]
    ~ shirt = 2
    OWNER: Suit yourself.
    Gary dropped it back in the box.
    TILL: Eleven dollars, back in the box.
- -> paperwork

// She writes his first cheque short on Friday (bible/11_SKELETON.md).
= paperwork
BOOKKEEPER: I'll need the new one's numbers, Gary. For the file.
She held a form out across the gap between the desks, to Gary, without looking at either of them. #look: bookkeeper
* [Fill it in.]
    ~ pay_how = 1
    He filled it in on his knee, in capitals, and gave it back. She read every line before it went in her drawer.
* ["Cash is fine."]
    ~ pay_how = 2
    BOOKKEEPER: That's not how it works.
    OWNER: Tonight's cash. After that she does it her way. Everybody does it her way.
    He filled it in.
* [Read it first.]
    ~ pay_how = 3
    ~ knows += form_uniform
    He read it first, both sides, which nobody did. Near the bottom, in the small print: UNIFORM, TO BE DEDUCTED FROM FIRST PAY, $24.00. # task: uniform :: Twenty-four dollars off Friday's cheque, for the shirt.
    { shirt == 1:
        TILL: Twenty-four dollars. Eleven-dollar shirt.
    - else:
        TILL: Didn't take the shirt. Reads the form.
    }
    He filled it in.
- -> the_key

= the_key
Gary took a key off a hook behind him, on a plastic tag with 12 on it in marker, and put it on the desk between them. #look: him
OWNER: Twelve. End of the hall, over the deck. Terry's got the other key. Terry's got every key.
~ stow(room_key, in_jeans)
OWNER: Seven-thirty, quarter to eight. She'll show you. She was my dad's.
SENIOR: She was mine.
~ stats_done()
// What Gary will say about him, once, as the door shuts: the owner's code is the money.
~ temp g = 0
{ scenario == 2:
    ~ g += 2
}
{ scenario == 1 || scenario == 4 || rent_called:
    ~ g -= 1
}
{ rude > 0:
    ~ g -= 2
}
{ threat > 0:
    ~ g -= 1
}
~ g -= lies_caught
{ gary_rye == 1 || gary_rye == 4:
    ~ g += 1
}
{ any_questions.no_questions:
    ~ g += 1
}
{
- rude > 0 || threat > 0 || lies_caught > 1:
    Gary watched him go down the porch steps into the rain and gave it a week. He was wrong about that, and about most of it.
- call_did == 1 || call_did == 6:
    Gary watched him go down the porch steps into the rain and thought: he'll sit there. He'll sit there all night if you let him. He was right about that, and wrong about most of the rest.
- else:
    Gary watched him go down the porch steps into the rain and thought: he'll do. He was right about that, and wrong about most of the rest.
}
{ g != 0:
    ~ rep(rep_owner, g)
}
-> dusk

// Three ways only, all of them on purpose: he meant the threat, he walked out, or he was rude to
// both of them. The teller's "he" turns into "I" at the end of every telling (PROPOSED); this is
// the shortest one.
= not_hired
{
- threat == 2:
    He held Gary's eye, and didn't say anything, and didn't need to. The bookkeeper picked up the phone on her desk and didn't dial it, and held it.
    OWNER: Okay, buddy. Okay. I think we're done.
- rude >= 2:
    OWNER: Okay, buddy.
    He said it to the desk. The interview had been over a while before Gary said so.
    BOOKKEEPER: Thank you so much.
- else:
    OWNER: Yeah. Okay. Suit yourself, buddy.
    He went out, and the gold letters rattled in the door behind him, and Gary went back to Ron about the prime rib.
}
TILL: Twenty an hour, saved.
SENIOR: Christ, Junior.
The rain kept on at the window, the way it does.
NARRATOR: I didn't get the job. That's it. That's the story.
NOT HIRED #class: end
-> END


// ------------------------------------------------------------------ the stats

// Where the interview starts him: a big man's body, and everything else a little under an
// ordinary man's 4, for his answers to make up.
=== function stats_base()
~ stat_str = 3
~ stat_con = 3
~ stat_dex = 2
~ stat_int = 2
~ stat_wis = 2
~ stat_cha = 2
~ stat_gut = 2

// a point on one of them, for something he said: he starts no higher than 7
=== function stat_up(ref s)
~ s = MIN(s + 1, 7)

// the interview's over: the page in his notes is his from here, and what moves it is struck through
=== function stats_done()
~ stats_set = true

// he told Gary why he left his last door (the bartender asks him the same at close)
=== function told_why()
~ return LIST_COUNT(told_gary ^ (tg_shorted, tg_something, tg_long, tg_quiet)) > 0
