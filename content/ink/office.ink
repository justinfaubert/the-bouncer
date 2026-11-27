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
NARRATOR: He started on a Wednesday. Gary tried doormen out on Wednesdays because it was dead, and if a new guy screwed up there'd be nobody in to see it.
NARRATOR: Gary told this part for years, to anyone who'd sit still for it, and got a lot of it wrong. But he was there first.
VAN DUSEN HOLDINGS was the front room of Gary Van Dusen's mother's house on the old main street. Across the road was the bank, which had been a cafe for eleven years. It was four in the afternoon and the lamp was on. His mother's china dogs were still on the mantel, next to a box of T-shirts and the beer rep's calendar, a girl in a bikini straddling a keg.
It had been raining since noon. The bookkeeper sat at the other desk typing invoices with one finger. Her mug was from the bank.
Somebody came up the porch steps and filled the glass in the door. From inside, the gold letters on it read SGNIDLOH NESUD NAV.
TILL: Here's twenty an hour.
-> arrive

= arrive
# sfx: door
He ducked, coming in. #portrait: him
He was big. Gary had watched the gym kind come off the ferry every summer, built out of powder and needles, with zits all over their backs. This one was big all the way through, like a fridge. Thirty-five, maybe more. His hair was dark and down to his shoulders, wet from the walk. He had a string of wooden beads round his neck with a tassel on the end, and a work jacket open over a black T-shirt that somebody had ironed.
SENIOR: Hair like a girl's. In my day we'd have called him a fairy and given him the door.
TILL: Long hair. That's a complaint a week.
SENIOR: Ironed his T-shirt. Your mother ironed yours till you were thirty, Junior.
OWNER: Come in, come in. Gary. Grab a seat.
* [Sit down.]
    ~ sat_how = 1
    ~ stat_up(stat_cha)
    ~ stat_up(stat_con)
    He sat. The chair creaked. He put his hands on his knees and waited for Gary to start.
    TILL: Doesn't fidget. Fidgeters steal.
* [Look round the room first.]
    ~ sat_how = 2
    ~ stat_up(stat_gut)
    ~ stat_up(stat_int)
    He stood and looked at the room first: the window, the bookkeeper, the box in the corner, the girl on the keg, the photo on the wall behind Gary's head. Then Gary's laptop. It was open on Island Rants and Raves, the town's Facebook group, on a picture of a rat beside the Sov's dumpster. Two hundred and fourteen comments. Gary had read all of them. He shut the laptop, and the big man sat down.
    SENIOR: He's casing it.
    TILL: Or pricing it.
* [Lift the chair back a foot, and turn it. Then sit.]
    ~ sat_how = 3
    ~ stat_up(stat_wis)
    ~ stat_up(stat_str)
    The chair was solid oak. He picked it up by one arm and put it down a foot further back, turned so he could see the door, and sat. It hadn't made a sound on Gary's mother's floor.
    SENIOR: Lifted it. Didn't drag it.
    TILL: That floor's eight thousand dollars.
- -> the_room

// "The owner had mentioned that before he'd mentioned anything else" (closing.ink, go_upstairs).
= the_room
OWNER: So. First thing. There's a room.
OWNER: Upstairs at the Sov, end of the second floor, over the deck. Comes with the job. Six a month, and it comes off the top.
The bookkeeper wrote it down.
SENIOR: Six. I charged the last one four, and he still left.
OWNER: You got your licence on you? The security one.
* [Hand it to him.]
    ~ licence_how = 1
    He took it out of his wallet and held it out across the desk, and kept hold of it a second after Gary took it.
* [Put it on the desk.]
    ~ licence_how = 2
    He put it face up on the desk and slid it the last few inches with two fingers.
    SENIOR: Makes you reach for it.
- -> licence_look

// The door, turned round: Gary does to him what he'll do to everyone (bible/11_SKELETON.md).
= licence_look
Gary looked at the card, then at him, then at the card again. #prop: his_licence
SECURITY WORKER, it said, with a seal in the corner, a number, a photo, and a name under Gary's thumb.
In the photo his head was shaved to the skin. Army, Gary thought. Or jail.
SENIOR: That's a jail haircut.
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
    He named a town. Gary knew it from the highway, a gas station and a sign for the ferry.
    TILL: Up island wages. He'll take twenty and say thanks.
* ["Around."]
    ~ told_gary += tg_around
    ~ stat_up(stat_dex)
    ~ stat_up(stat_gut)
    OWNER: Around. Okay. Around.
    SENIOR: Around means he owes money.
* ["My father worked doors. I worked them with him."]
    ~ told_gary += tg_father
    ~ stat_up(stat_wis)
    ~ stat_up(stat_cha)
    OWNER: Yeah? Where?
    Up island, he said, when he was a kid.
    SENIOR: His father taught him.
    SENIOR: I taught you to count a till, Junior. That's what I taught you.
- -> why_left

// The bartender asks him the same thing at close (closing.ink, door_story), and he'll have had
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
    Gary put a hand up before he could say what.
    OWNER: I don't need the how.
    TILL: The last time something happened it was eleven thousand dollars.
    SENIOR: I had a doorman in '64 say that to me. He'd put a fellow through the front window of the Legion.
* ["Long story."]
    ~ told_gary += tg_long
    ~ stat_up(stat_wis)
    ~ stat_up(stat_gut)
    OWNER: They all are, buddy. They all are.
* [Say nothing.]
    ~ told_gary += tg_quiet
    ~ stat_up(stat_con)
    ~ stat_up(stat_str)
    He looked at Gary. The bookkeeper stopped typing.
    TILL: Fine. Cheaper.
- -> fights

= fights
OWNER: You on anything? Gear? Ha. I don't care what you put in your ass, buddy. I care what goes through my window.
OWNER: You been in fights?
SENIOR: Look at his hands.
Gary looked. There was an old scar on every knuckle, white and shiny.
* ["Plenty."]
    ~ stat_up(stat_str)
    ~ stat_up(stat_con)
    OWNER: Plenty. Okay. Not in my bar, plenty.
    TILL: Plenty. There goes the insurance.
* ["When I have to."]
    ~ stat_up(stat_wis)
    ~ stat_up(stat_dex)
    OWNER: Good. Good man.
    SENIOR: They all say that. Ask him how often he has to.
* ["I stop them."]
    ~ stat_up(stat_cha)
    ~ stat_up(stat_dex)
    OWNER: That's what I'm paying for. Stopping them.
    TILL: Twenty an hour to stop them. The detachment's forty minutes out.
* ["Never."]
    ~ told_gary += tg_never
    ~ lies_caught++
    Gary looked at the knuckles again and laughed through his nose.
    OWNER: Never. Okay.
    SENIOR: He can't lie. Good. Your mother's brother could lie, and he took me for nine thousand dollars in 1971.
* ["Want to find out?"]
    ~ threat = 1
    He said it quietly. The bookkeeper's finger stopped over the keyboard.
    TILL: Twenty an hour to say that to a drunk. To me?
    SENIOR: Get him out of your mother's house.
    -> threat_two
- -> the_call

= threat_two
* ["I'm kidding."]
    He smiled, and Gary laughed, too loud.
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
    He waited. He looked at the calendar for a while, and then at the rain.
    SENIOR: Patient. The last one wasn't.
* [Look at the photo behind Gary.]
    ~ call_did = 2
    ~ knows += senior_photo
    ~ stat_up(stat_gut)
    ~ stat_up(stat_wis)
    He looked past Gary at the wall behind him, and kept looking.
    SENIOR: He's looking at me.
    It was the Sov in 1958, three storeys of new paint, SOVEREIGN on the roof with every letter lit. A man in a hat stood in front of the door with his hands behind his back. He'd paid cash for the place that spring.
* [Say something to the bookkeeper.]
    ~ call_did = 3
    ~ stat_up(stat_cha)
    ~ stat_up(stat_int)
    He turned in the chair and asked her how long she'd been doing Gary's books.
    BOOKKEEPER: His father's, and then his. Forty-one years in March. Before that I was at the bank.
    She looked at him over her glasses.
    BOOKKEEPER: Across the road. When it was a bank.
* [Read Gary's desk upside down.]
    ~ call_did = 4
    ~ knows += notice_read
    ~ stat_up(stat_int)
    ~ stat_up(stat_gut)
    He read the papers on Gary's desk upside down, and Gary watched him do it.
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
    TILL: Changed his mind.
* ["Forget it."]
    -> not_hired
- -> the_call.call_done

= do_you_drink
OWNER: You drink?
* ["Yes."]
    ~ stat_up(stat_con)
    ~ stat_up(stat_cha)
    OWNER: Good. Good man. Not on my till.
    TILL: There's his shift beer. Four nights a week.
* ["Depends who's buying."]
    ~ stat_up(stat_cha)
    ~ stat_up(stat_int)
    OWNER: Ha! Not me, buddy.
    SENIOR: A comedian. My last comedian drank the float.
* ["Not on a shift."]
    ~ stat_up(stat_wis)
    ~ stat_up(stat_con)
    SENIOR: Not on a shift. After it, in my bar, on the house.
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
    TILL: Three dollars of rye, gone.
    SENIOR: I'd have hired him for that.
* [Hold it, and don't drink it.]
    ~ gary_rye = 2
    He held the glass and didn't drink.
    SENIOR: Holds it like the old fellow at the end of the bar.
    SENIOR: He held his like that in 1958.
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
OWNER: Five guys in the front window, every day but Sunday, since about the Flood. Two of them have had the stroke already. They don't get cut off. That's the rule.
SENIOR: That's my rule.
OWNER: That's my dad's rule. So one of them's had enough. More than. What do you do?
* ["Water. And I sit with him a while."]
    ~ scenario = 1
    ~ stat_up(stat_cha)
    ~ stat_up(stat_wis)
    OWNER: Water. Okay. Water doesn't go through the till, buddy.
    TILL: Water. That's a stool for three hours at nothing an hour.
* ["Whatever they want."]
    ~ scenario = 2
    ~ stat_up(stat_int)
    ~ stat_up(stat_con)
    OWNER: Good. Good man.
    SENIOR: That's what I said. I went to two of their funerals.
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
    SENIOR: Put one out and the other four go with him. They did it to me in '87. A month at the Legion.
* (rude_gary) ["Must be nice. Owning a bar you never set foot in."]
    ~ rude++
    SENIOR: He's not wrong, Junior.
    Gary laughed, a second late.
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
    TILL: Asks about the money. Good.
* (no_questions) ["No."]
    OWNER: Good. Good man.
    TILL: No questions. The ones with questions want a raise by Christmas.
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
OWNER: Twenty an hour. Tonight's cash, it's a test. After that it's Wednesday to Saturday, on the books, and the room comes off the top.
BOOKKEEPER: Six hundred and fifty. A month. With the hydro.
She read it off her pad.
TILL: Hydro, fifty. Six hundred less fifty, six hundred.
// A passive read (bible/11_SKELETON.md): past a threshold, he notices without being asked.
{ stat_int >= 5:
    He heard it. Gary saw him hear it.
- else:
    He didn't seem to notice.
}
* {stat_int >= 5} ["Six, you said."]
    ~ rent_called = true
    OWNER: Did I? Well. Hydro.
    BOOKKEEPER: Mm-hm.
    She wrote something else down.
    SENIOR: He counts. Watch him.
* (rude_bk) ["Was anybody talking to you?"]
    ~ rude++
    The bookkeeper looked at him over her glasses and smiled.
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
SENIOR: Put SECURITY on a man in this town and they'll line up to have a go at him.
* [Take it.]
    ~ shirt = 1
    ~ stow(gary_shirt, in_inside)
    He folded it in four and put it inside his jacket.
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
    He turned it over and read both sides. Near the bottom, in the small print: UNIFORM, TO BE DEDUCTED FROM FIRST PAY, $24.00. # task: uniform :: Twenty-four dollars off Friday's cheque, for the shirt.
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
OWNER: And one more thing. Don't fuck the staff.
OWNER: Or do, I'm not your mother. Just don't make it my problem. The last time it was my problem it was my problem for a year.
The bookkeeper's finger went on with the invoices.
* (staff_wasnt) ["Wasn't planning on it."]
    ~ staff_warned = 1
    OWNER: Nobody plans on it, buddy. Ha.
* (staff_who) ["Who's the staff?"]
    ~ staff_warned = 2
    OWNER: Ha! You'll see. Ha. Jesus.
    SENIOR: That's how your mother came to work for me, Junior. Behind that bar.
* (staff_quiet) [Pick up the key.]
    ~ staff_warned = 3
    He picked up the key and put it in his jeans.
    SENIOR: That's a yes, Junior.
-
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
    Gary watched him go down the porch steps into the rain, and gave him a week.
- call_did == 1 || call_did == 6:
    Gary watched him go down the porch steps into the rain and thought, he'll sit. Put him on a stool and he'll sit there all night.
- else:
    Gary watched him go down the porch steps into the rain and thought, he'll do.
}
Then he went back to his laptop, and the picture of the rat by the Sov's dumpster. Two hundred and twenty-one comments.
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
    He held Gary's eye. The bookkeeper picked up the phone on her desk and held it. She didn't dial.
    OWNER: Okay, buddy. Okay. I think we're done.
- rude >= 2:
    OWNER: Okay, buddy.
    He said it to the desk.
    BOOKKEEPER: Thank you so much.
- else:
    OWNER: Yeah. Okay. Suit yourself, buddy.
    He went out, and the gold letters rattled in the door behind him, and Gary went back to Ron about the prime rib.
}
TILL: Twenty an hour, saved.
SENIOR: Christ, Junior.
NARRATOR: So I didn't get the job.
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
