// Friday, day 3: the first real shift, at the door (bible/11_SKELETON.md, "What to build first":
// the town, its licences, and a Friday's waves at the door). The rest of Friday, the room and the
// fight and the first cheque, short, is a later milestone, and so is Thursday by day: for now
// Thursday goes by in two of the teller's lines, and Friday is the door's, from seven to last call.
//
// The waves are the town's (content/rules/door.yaml, nights): the prime rib till eight, the beer
// league's late game at half nine, the mill's swing shift and the hospital's evening shift at
// twenty to twelve, the Legion shutting at midnight, the last boat at quarter to one, and everybody
// else in between. The line is line.ink's. What happens round the door while he's on it is here:
// the bartender's rundown, the kids she finds at the bar, Gary's call, the boy on page eight come for
// his licence, a shot from the beer league, last call, and the door's own tape.
//
// Claude's draft, all of it (PROPOSED).

=== friday ===
~ day = 3
~ clock = 1150
~ here = door
~ door_away = 0
~ drinks = 0
~ drinks_before = 0
~ count_in = 0
~ uncounted = 0
~ walk_ins = 0
~ walk_ins_seen = 0
// Two days on, whatever Wednesday did to him has healed by one.
{ hurt > 0:
    ~ hurt--
}
// Who's in when he comes on: table 28, the end of the bar, and the first of the prime rib.
~ fri_start = 19
~ room_count = fri_start
// HUTCH: Thursday is a milestone of its own (the strip, the napkin, his room, the first paper). Until it's written, the teller passes over it.
NARRATOR: Thursday was his. He slept most of it, and what he did with the rest is another story. #night: 3 #screen: none
NARRATOR: Friday he was on the stool at ten past seven, the way she'd told him, and it was raining again.
# amb: rain_lot
The room behind him was filling already. Table 28 were where they always were. The prime rib was on, and the window tables had old couples at them in their good sweaters, cutting their meat small. #look: t28
-> rundown

= rundown
The bartender came over from the bar with a glass of water and put it on the ledge by the stool. #portrait: bartender #look: bartender
BARTENDER: Door. Here's your Friday, so you're not surprised.
BARTENDER: Prime rib till eight, so it's the old ones first. They don't need carding and they'll tell you so.
BARTENDER: The beer league's got the late ice at the arena. They're done about half nine, and they come in loud, and they come in together.
BARTENDER: Twenty to twelve it's the swing shift off the mill and the evening shift off the hill, at the same time, and they race each other to the lot. Nurses tip. Mill guys don't, but they drink.
BARTENDER: Legion shuts at midnight and sends us whoever it's got left. Last boat's in about quarter to one. Whoever's on that's had a day.
BARTENDER: In between it's everybody else. And it's Friday, so the kids'll try it, and every one of them's got a big sister.
- (ru)
* ["Who don't I let in?"]
    ~ fri_rules = true
    BARTENDER: Anybody in the binder. Anybody who's had enough, and you'll know.
    BARTENDER: And nobody under nineteen. The inspector finds one in here on the fourteenth, I lose my licence, Junior loses his, and you lose your job. In that order.
    -> ru
* ["How many on a Friday?"]
    ~ fri_how_many = true
    BARTENDER: Through that door? Hundred, hundred and twenty. Not all at once.
    BARTENDER: Mostly all at once.
    -> ru
* {asked_name && verdict == 2} ["It's Friday."]
    -> her_name ->
    -> ru
+ ["Got it."]
    BARTENDER: Mm. Don't let the line get to the highway. They walk to the Legion, and Junior hears about it.
    She went back to her bar.
    -> fri_door

// "Last a week, Door. Then ask me." (bar.ink), and on Wednesday night, if she was telling Gary he'd
// do, "Ask me Friday." (closing.ink). From here she's PAIGE on the page.
= her_name
She knew what he meant. She looked at him the way she had on Wednesday, a second longer than she needed to.
// HUTCH: The moment she tells him her name. Rewrite it, or move it.
BARTENDER: Paige.
~ bartender_named = true
BARTENDER: Don't wear it out, Door.
~ rep(rep_staff, 1)
->->


// ------------------------------------------------------------------ the door, seven to last call

=== fri_door ===
~ here = door
{ clock >= LAST_CALL:
    -> fri_last_call
}
// Paige, with a kid she found at her bar who got in past him
{ door_act("found"):
    -> fri_found_one -> fri_door
}
~ temp e = fri_ready()
{
- e == "gary":
    -> fri_gary -> fri_door
- e == "ballcap":
    -> fri_ballcap -> fri_door
- e == "shot":
    -> fri_shot_ev -> fri_door
- e == "pace":
    -> fri_pace -> fri_door
}
// whoever's gone from the line, or past him, while he was busy
{door_say("news")}
~ temp w = door_wave()
{ w != "":
    -> wave_in(w) ->
}
{ door_n("waiting") > 0:
    -> door_front -> fri_door
}
-> fri_quiet

=== fri_quiet ===
{ fri_still() }
+ [Wait for the next one.]
    ~ pass(door_n("wait"))
    -> fri_door
+ [Look in at the room.]
    ~ pass(1)
    { fri_room() }
    -> fri_door

// What's due round the door, in the order it matters.
=== function fri_ready()
{
- fri_seen !? fd_gary && clock >= 1385:
    ~ return "gary"
- fri_seen !? fd_ballcap && clock >= 1365:
    ~ return "ballcap"
- fri_seen !? fd_shot && clock >= 1340 && door_n("in_arena") > 0:
    ~ return "shot"
- fri_seen !? fd_pace && door_n("waiting") >= 7:
    ~ return "pace"
}
~ return ""


// ------------------------------------------------------------------ the waves coming in

=== wave_in(w) ===
{
- w == "dinner":
    The prime rib came in twos, under umbrellas, the men holding the door for the women and the women letting them. #look: door
- w == "arena":
    Headlights came down the highway in a string from the arena, and the lot filled all at once: pickups with hockey bags in the backs, doors slamming, somebody singing already. #look: door
    { stopping:
    - FIGHTER: Here they come. Twelve of them, and they won. Or they lost. Either way.
    -
    }
- w == "swing":
    At twenty to twelve the mill's swing shift came across the highway in their work clothes, with the noise of the mill still in their shoulders. Behind them, down off the hill, the hospital's evening shift, in their coats over their scrubs. #look: door
    { stopping:
    - FATHER: The ones off a shift are tired, and the tired ones are the ones who go off. Read them.
    -
    }
- w == "legion":
    At midnight the Legion shut, and its drinkers came up the highway on foot in the rain, in twos and threes, holding each other up, poppies on their coats. #look: door
    { stopping:
    - FATHER: They've had the Legion's last call already. You're giving them a second one.
    -
    }
- w == "ferry":
    The last boat was in. Its people came up from the terminal in the dark: the ones who'd been on the mainland all day, and the crew, and a woman with a suitcase who looked like she'd changed her mind about something. #look: door
}
->->


// ------------------------------------------------------------------ the kids she finds at her bar

// One of the under-nineteens who got past him, found by the bartender at her bar half an hour or
// more after (Folk.Door, find): she walks them out to the door herself.
=== fri_found_one ===
~ fri_found++
~ room_count--
~ rep(rep_staff, -1)
The inner door opened behind him, and the bartender came through it with {door_word("other:a_person")} by the elbow, {door_word("other:in_top")}. #portrait: door_other #look: bartender
BARTENDER: Door.
{ fri_found == 1:
    BARTENDER: {door_word("other:Age")}. I know {door_word("other:his")} mother.
- else:
    BARTENDER: Here's another one. {door_word("other:Age")}.
}
OTHER: {door_say("found")}
{
- door_has("other:how:nod"):
    BARTENDER: You nodded {door_word("other:him")} in. I watched you do it.
- door_has("other:how:wave"):
    BARTENDER: Walked in with {door_word("other:his")} friends, and you waved the lot of them.
- door_has("other:how:glance"):
    BARTENDER: You looked at {door_word("other:his")} card. You looked right at it.
- door_has("other:how:read"):
    BARTENDER: You read it and everything. So it's a good one, or you're not.
- door_has("other:how:missed"):
    BARTENDER: Walked in past an empty stool.
- else:
    BARTENDER: Walked in past you while you were busy with somebody's birthday. You didn't see. I did.
}
BARTENDER: I served {door_word("other:him")} a vodka cran before I looked at {door_word("other:him")} properly, so that's both of us.
{ fri_found == 2:
    BARTENDER: That's two. The inspector's on the fourteenth.
}
- (fo)
+ ["Sorry. It won't happen again."]
    ~ fri_owned++
    ~ rep(rep_staff, 1)
    BARTENDER: It will. Just not with that one.
+ {door_has("other:how:glance") || door_has("other:how:read")} ["{door_word("other:He")} had a card."]
    BARTENDER: Then the card was better than you.
+ [Say nothing.]
    She didn't wait for him to say anything.
- She took {door_word("other:his")} picture on her phone on the way past, for the binder, and put {door_word("other:him")} out into the rain. {door_word("other:He")} went down the steps without looking at either of them.
->->


// ------------------------------------------------------------------ eleven: Gary's call

// Hutch's "How is it tonight?" (bar.ink, ev_owner), on a Friday. Going to the phone leaves the door
// for the length of a call, and whoever's waited in the line a few minutes walks in past the stool.
=== fri_gary ===
~ fri_seen += fd_gary
Over the noise, the bar phone rang, the one with the cord. The bartender answered it, listened, and found him down the length of the room. #sfx: phone #look: bartender
BARTENDER: Door! Junior!
{ door_n("waiting") > 0:
    She held it up. Behind him the line was {num(door_n("waiting"))} deep in the rain.
- else:
    She held it up.
}
+ [Go and take it.]
    ~ fri_gary = 1
    ~ here = bar
    He left the stool and went across the room for it.
    ~ pass(1)
    -> call
+ [Point at the line. He's on the door.]
    ~ fri_gary = 2
    ~ fri_told = 4
    ~ pass(1)
    ~ rep(rep_owner, -1)
    ~ rep(rep_staff, 1)
    She said something into the phone, and listened, and said something else, and laughed at it, and hung up.
    BARTENDER: He wanted to know how is it tonight. I told him busy.
    BARTENDER: That's all he wants. Busy.
    ->->

= call
OWNER: How is it tonight?
+ [Give him the door's number.]
    ~ fri_told = 1
    He gave him the number: {num(count_in)} past the stool since seven, and the {num(fri_start)} who were in for the prime rib before that.
    { count_in >= 30:
        OWNER: That's a Friday. Good. Good man.
        ~ rep(rep_owner, 2)
    - else:
        OWNER: That's it? On a Friday? What's the Legion doing, giving it away?
    }
+ ["Busy."]
    ~ fri_told = 2
    ~ rep(rep_owner, 1)
    OWNER: Busy. Good. Busy is what I like to hear, buddy.
+ ["Quiet."]
    ~ fri_told = 3
    ~ rep(rep_owner, -1)
    ~ rep(rep_staff, -1)
    OWNER: Quiet. On a Friday. Buddy, nothing is quiet on a Friday.
    The bartender, who'd rung in every drink since four, took the phone off him and turned her back to tell Gary different.
- OWNER: And listen. Nobody under nineteen. Not one. The inspector's on the fourteenth, and I don't need the how.
{ fri_found > 0:
    OWNER: She says she's walked {fri_found == 1:one|{num(fri_found)}} out already. Don't make a habit of it, buddy.
}
OWNER: Good. Put her back on.
He gave her the phone back. She listened, said "Yep," and "Yep," and hung up.
~ pass(2)
~ here = door
He went back to the stool.
->->


// ------------------------------------------------------------------ the boy on page eight

// The licence in the last doorman's jacket (drawer.ink): the boy he let in on it, put in the binder
// by the bartender for three months, which runs out on his birthday. He's come for it. He's
// eighteen, and nineteen on the second of January (content/data/props.yaml, minor_card).
=== fri_ballcap ===
~ fri_seen += fd_ballcap
A kid in a ball cap came up the steps with his hands in the pouch of his hoodie, and stopped a step short of the stool, the way they do when they know they're not getting in. #portrait: ballcap
{ the_drawer.licence:
    He knew the face, younger and without the cap: the licence behind the ferry tickets in the last doorman's jacket.
}
BALLCAP: hey. i'm not trying to come in. i know
BALLCAP: the guy before you had my licence. he said i'd get it back when i'm nineteen. but i need it now. i drive for my uncle
-> bc

= bc
+ {on_him(minor_card)} [Give it to him.]
    ~ fri_ballcap = 1
    ~ unstow(minor_card)
    ~ rep(rep_kids, 1)
    He took it out of his inside pocket and gave it to him. The kid looked at the photo like he'd forgotten what he looked like without the cap.
    BALLCAP: oh my god. thanks. thank you
    BALLCAP: january. i know. i'll be here
    MANUAL: Identification taken at the door is surrendered to police or returned to the issuing office. It is not handed back on the steps.
    FATHER: It was his. That's the end of it.
    ->->
+ {minor_binder()} ["The bartender's got it. You'll get it back in January."]
    ~ fri_ballcap = 2
    ~ rep(rep_kids, -1)
    BALLCAP: paige has it? oh no
    BALLCAP: january. that's literally the one month i don't need it
    He went back down the steps.
    ->->
+ {in_jacket ? minor_card && the_drawer.licence} [Go and get it out of the lost-and-found.]
    -> drawer
+ ["Never seen it."]
    { the_drawer.licence:
        ~ fri_ballcap = 3
    - else:
        ~ fri_ballcap = 4
    }
    BALLCAP: ok
    BALLCAP: ok. thanks anyway
    He went back down the steps with his hands still in his pouch.
    { fri_ballcap == 3:
        WRONGMAN: In the story the doorman said he'd never seen him, either.
    }
    ->->

// Off the stool for as long as it takes to go behind the bar and through a jacket.
= drawer
~ fri_ballcap = 1
~ here = bar
He went across to the bar and round behind it, to the drawer under the till, and found the jacket at the bottom and the licence behind the tickets.
~ pass(3)
~ unstow(minor_card)
~ rep(rep_kids, 1)
The bartender watched him do it and didn't ask.
~ here = door
He came back and gave it to the kid on the steps.
BALLCAP: oh my god. thanks. thank you
BALLCAP: january. i know. i'll be here
FATHER: It was his. That's the end of it.
->->

// The boy's licence is in her binder: he showed it to her, out of the jacket, and she kept it.
=== function minor_binder()
~ return the_drawer.licence && not on_him(minor_card) && in_jacket !? minor_card && in_drawer !? minor_card && in_twelve !? minor_card


// ------------------------------------------------------------------ a shot from the beer league

=== fri_shot_ev ===
~ fri_seen += fd_shot
~ door_act("pick:arena")
The inner door opened behind him and {door_word("other:a_person")} from the beer league came out into the vestibule with two shots of something brown, and held one out to him across the stool. #portrait: door_other
OTHER: {door_say("shot")}
+ [Drink it.]
    ~ fri_shot = 1
    ~ drink()
    It went down like a lit match.
    OTHER: That's it. That's the stuff.
    FATHER: One. On the door. That's how it starts, and it never once started any other way.
+ ["I'm on."]
    ~ fri_shot = 2
    OTHER: More for me, then.
    {door_word("other:He")} drank them both, one after the other, and went back in.
- ->->


// ------------------------------------------------------------------ the bartender, about the line

=== fri_pace ===
~ fri_seen += fd_pace
The inner door opened a crack behind him, and the bartender put her head out. #look: bartender
BARTENDER: Door. You've got {num(door_n("waiting"))} in the rain.
BARTENDER: They'll walk to the Legion. The Legion's got a meat draw.
FATHER: Slow is how you're right. Fast is how you keep a door. Pick one.
->->


// ------------------------------------------------------------------ on the stool, nobody in front of him

=== function fri_still()
{
- clock < 1230:
    { shuffle:
    - Through the glass, the lot under the light, and the rain coming down across it in sheets, and nobody in it yet.
    - Behind him the prime rib, and the scrape of knives on plates, and table 28 telling somebody at the next table to try the horseradish.
    - The jukebox, turned down for the dinner crowd. Somebody's Patsy Cline.
    }
- clock < 1380:
    { shuffle:
    - Headlights on the highway, slowing for the lot, and going on by.
    - In the black of the front window he could see the room behind him, backwards, fuller than Wednesday's by a long way.
    - The bartender, through the inner door, pouring four at once.
    }
- clock < 1470:
    { shuffle:
    - The room behind him was loud enough now that he could feel it in the stool.
    - A couple came out to the vestibule to argue, saw him, and went back in to argue there.
    - Somebody was trying to get the jukebox to play the same song a third time, and somebody else was trying to stop them.
    }
- else:
    { shuffle:
    - Past one the door went the other way. Everybody who came through it now was going out.
    - The lot was full of cars with people asleep in them, and one with the engine running and the lights on and nobody in it.
    - The rain had eased off to the kind you only see under the light over the door.
    }
}

// The room through the inner door, by the hour. He can't count it from the stool on a Friday.
=== function fri_room()
{
- clock < 1260:
    The window tables at their prime rib, table 28 at theirs, the end of the bar, and the bartender with one eye on all of it. Nobody standing yet.
- clock < 1410:
    Standing room at the bar now, two deep. The beer league had the pool table and the corner, and the bartender had given up on the window tables being anybody's.
- clock < 1480:
    Everybody. The mill at the bar, the hospital by the window in their coats, the Legion at the end of it, and table 28 holding their table like a fort.
- else:
    Fuller than it should be, louder than it needed to be, and somewhere in it, the bartender, keeping it all from going over.
}


// ------------------------------------------------------------------ last call, and the door's tape

=== fri_last_call ===
~ here = door
BARTENDER: Last call! #sfx: bell
{ door_n("waiting") > 0:
    ~ temp k = door_act("close")
    He put an arm across the door. The {num(k)} still in the line looked at him, and at the rain, and went back to their cars, or up the highway, or nowhere.
}
FATHER: Now get them out. All of them. Same as you let them in: one at a time, and no hurry they can see.
-> fri_close

=== fri_close ===
~ pass(45)
~ here = floor
It took till a quarter past two to empty the room. The last of the Legion had to be walked to the door, one on each arm.
~ room_count = 0
~ here = door
He locked the front door behind the last of them and turned the sign over. #sfx: door
# amb: empty_bar
The bartender came round the bar with her tray of twenties and sat on the stool by the till to count them. #look: bartender
BARTENDER: How many, Door?
- (hm)
+ [Give her the door's number.]
    He told her: {num(count_in)} past the stool, and the {num(fri_start)} who were in when he came on.
    { uncounted > 0:
        BARTENDER: And {num(uncounted)} more you didn't count. I rang them in. Some nights that's the number.
    - else:
        BARTENDER: Mm. That's about what I rang in.
        ~ rep(rep_staff, 1)
    }
+ ["Too many."]
    BARTENDER: That's a Friday. Wait till the mill goes.
* {asked_name && verdict == 2 && not bartender_named} ["It's Friday. You said to ask you."]
    -> friday.her_name ->
    -> hm
- { door_n("kept_out") > 0:
    -> ledge
}
-> fri_tape

// The cards he kept tonight, face down on the ledge under the scanner (line.ink, keep).
= ledge
She looked past him at the ledge under the scanner, at the {door_n("kept_out") == 1:card|{num(door_n("kept_out"))} cards} face down on it.
BARTENDER: And {door_n("kept_out") == 1:that|those}.
+ [Give them to her for the binder.]
    ~ fri_cards = 1
    She went through them like a hand she'd been dealt, and turned each one face up on the bar, and took its picture with her phone.
    BARTENDER: {door_word("kept_names")}. I know every one of them.
    BARTENDER: They'll be in the binder by Saturday, and they won't get past you twice.
    ~ rep(rep_staff, 1)
+ [Put them in an envelope for the constable.]
    ~ fri_cards = 2
    He put them in an envelope from behind the till and wrote the date on it, and the time.
    BARTENDER: She'll love that. Put the envelope by the till where she'll see it.
+ [Put them in the lost-and-found.]
    ~ fri_cards = 3
    BARTENDER: Then they'll come back for them, and you'll be here, and you'll give them back.
    BARTENDER: Your door, Door.
- -> fri_tape


// ------------------------------------------------------------------ the tape

// Friday's tally prints like Wednesday's (closing.ink, ledger): everything on it is something he did,
// or didn't, at the door.
=== fri_tape ===
~ here = upstairs
# plate: lot
{
- door_n("minors_in") > fri_found:
    NARRATOR: That was the first Friday. He'd remember the faces for a month. The ones he let in, he'd remember longer.
- else:
    NARRATOR: That was the first Friday. He'd remember the faces for a month.
}
# screen: ledger
THE SOVEREIGN HOTEL #class: head
FRIDAY. THE FIRST REAL ONE. #class: head
The door: {count_in} in past the stool #class: row
{ door_n("read") > 0 || door_n("glanced") > 0:
    {door_n("read")} cards read, {door_n("glanced")} looked at, and the rest on a nod. #class: sub
}
{ uncounted > 0:
    And {uncounted} more who got in without him. #class: sub
- else:
    Nobody got past him. #class: sub
}
Turned away: {door_n("refused")} #class: row
{ door_n("kept") > 0:
    {door_n("kept") == 1:One card|{door_n("kept")} cards} kept{fri_cards == 1:, and in the binder|}{fri_cards == 2:, in an envelope for the constable|}{fri_cards == 3:, in the lost-and-found|}. #class: sub
}
Gave up on the line: {door_n("left")} #class: row
The longest the line got: {door_n("longest")} #class: row
{ door_n("minors_in") > 0:
    Under nineteen, inside: {door_n("minors_in")} #class: row
    { fri_found > 0:
        The bartender walked out {fri_found}. #class: sub
    }
    { door_n("minors_in") > fri_found:
        Nobody caught the rest. #class: sub
    }
- else:
    Under nineteen, inside: none #class: row
}
{ door_n("caught") > 0:
    Under nineteen, turned away at the door: {door_n("caught")} #class: row
}
{
- fri_told == 1:
    Gary: the door's number #class: row
- fri_told == 2:
    Gary: busy #class: row
- fri_told == 3:
    Gary: quiet #class: row
    It wasn't. She told him different. #class: sub
- fri_told == 4:
    Gary: busy, from her #class: row
}
{
- fri_ballcap == 1:
    The boy on page eight has his licence back. #class: sub
- fri_ballcap == 2:
    The boy on page eight gets his licence back in January. #class: sub
- fri_ballcap == 3:
    He told the boy on page eight he'd never seen his licence. #class: sub
}
{ cash >= 0:
    In his pocket: ${cash} #class: row
- else:
    In his pocket: nothing #class: row
}
{ drinks == 0:
    Drinks: none #class: row
- else:
    Drinks: {drinks} #class: row
    { fri_shot == 1:
        One of them on the door, from the beer league. #class: sub
    }
}
{ any_word():
    WHAT THEY'RE SAYING
    { last_word("t28") != "":
        Table 28: “{last_word("t28")}” #class: row
    }
    { last_word("kids") != "":
        The kids: “{last_word("kids")}” #class: row
    }
    { last_word("owner") != "":
        The owner: “{last_word("owner")}” #class: row
    }
    { last_word("staff") != "":
        {bartender_named:Paige|The bartender}: “{last_word("staff")}” #class: row
    }
}
{
- rep_staff >= 3:
    {bartender_named:Paige|The bartender} will tell Gary he can keep the door. #class: total
- rep_staff >= 0:
    {bartender_named:Paige|The bartender} will tell Gary he got through a Friday. #class: total
- else:
    {bartender_named:Paige|The bartender} will tell Gary what she saw. #class: total
}
Saturday's the meat draw.
END OF THE FIRST FRIDAY #class: end
-> END
