// The bar: the bartender, the binder, the shift drink, and the old man at the end.
// The bartender is his partner and his witness (bible/02_SYSTEMS.md): she sees everything he does.
// Her respect (rep_staff) is the hardest thing in the game to earn.

// From ten till somebody changes the keg, him in the keg room (rats.ink) or her (lager_out, below).
=== function lager_off()
~ return clock >= 1320 && not at_keg.change_keg && not at_bar.lager_out

=== at_bar ===
~ here = bar
{ due(): -> hub }
{ at_bar == 1:
    He leaned on the bar in the gap in the stools where staff stood, out of the way of the taps. #look: bartender
- else:
    {shuffle:
    - He went back to the gap in the stools. #look: bartender
    - He leaned on the bar, out of the way of the taps. #look: bartender
    - The gap in the stools. She was pulling a pint and didn't look up. #look: bartender
    }
}
{ rep_staff <= -3:
    She served him the same way she served everyone, and not one bit more.
}
// he ran across her floor since she last had him at the bar (toys.ink, toy_legs) (Claude's draft).
// The first time it goes down with her, and the third, and that's the word on him (word.yaml).
{ ran_room > ran_seen:
    ~ ran_seen = ran_room
    { stopping:
    - BARTENDER: Door. You don't run on my floor. Half the room just looked round for the fight.
        ~ rep(rep_staff, -1)
    - BARTENDER: Walk, Door.
    - BARTENDER: Again with the running.
        ~ rep(rep_staff, -1)
    - BARTENDER: Again with the running.
    }
}
{ lager_off():
    -> lager_out
}
-> opts

= opts
{ due(): -> hub }
<- moves(bar)
* {knows !? eighty_six || knows !? banned_face} [Read the binder under the till.]
    -> binder
* ["Anything I should know about this place?"]
    -> know
* ["Who's the old man at the end?"]
    -> who_endbar
* {knows ? the_note} ["What's the story with the rats?"]
    -> rats_talk
* ["How long have you worked here?"]
    -> how_long
* {at_bar.how_long > 0} ["What do I call you?"]
    -> name
* {knows ? jacket_heard && not drawer_seen} ["Where's the jacket the last one left?"]
    -> jacket_ask
+ {drawer_seen} [The lost-and-found drawer.]
    ~ drawer_from = 1
    -> the_drawer
+ [{drinks - drinks_before == 0:"Pour me one."|"Another."} #hand: drink]
    -> shift_drink
+ {knows ? endbar_seen && at_bar.endbar < 3} [Go and stand by the old man at the end of the bar.]
    -> endbar

= binder
~ pass(5)
~ knows += eighty_six
She slid it along the bar to him without being asked twice. A two-inch binder, the plastic sleeves gone cloudy. Photocopied licences, phone photos printed on the office printer, a few real photographs. Under each one, in marker, in her handwriting: a date, sometimes a reason, always a length. SIX MONTHS. ONE YEAR. LIFE.
// HUTCH: What's actually written in a bar's 86 book? Reasons, shorthand, the ones that are funny and the ones that aren't. (They go on the binder's pages, in content/data/props.yaml; the pages carry dates and lengths until then.)
Page three was a man in his fifties with a good haircut, photographed off his driver's licence. Under it, not a date or a reason. Just: NO. NOT EVER. #prop: binder
// Leafing through to the last sleeve makes the first choice; staying on page three makes the second.
* [Fix the faces in his head. #check: manual 10 #toy: binder all]
    { passed:
        MANUAL: Memorise the barred list at the start of every shift. Page three. Page seven. Page eleven, the one with the tattoo on his neck.
        ~ knows += banned_face
    - else:
        He went through it twice. Forty faces, most of them the same man in bad light. They'd blur by ten o'clock. He knew that about himself.
    }
* [Just page three. #toy: binder page3]
    He looked at page three for a long time.
    ~ knows += banned_face
    FATHER: The ones they write NOT EVER about, they come back. They always come back. That's why somebody wrote it.
- She took the binder back and put it under the till.
-> opts

= know
~ pass(3)
BARTENDER: Table 28 don't get cut off. That's Junior's rule, so don't look at me.
BARTENDER: Cook's all right, he's just hot, and you'd be hot. Leave his kitchen door alone unless you want an earful.
BARTENDER: Night clerk's Terry. Props the hotel door so he can watch our TV off the desk. You didn't hear that from me.
BARTENDER: And when the card machine goes down, and it will, it's cash, and if they haven't got cash, they haven't got a drink.
// HUTCH: The lifer's house rules. What would she tell a new doorman, and what would she let him find out for himself?
~ knows += hotel_gap
~ knows += kitchen_gap
~ knows += terry
FATHER: Every bar's got its rules and none of them are written down. The written ones are for the inspector.
-> opts

= who_endbar
~ pass(2)
~ knows += endbar_seen
She didn't look down the bar. She didn't need to.
BARTENDER: Him? He was coming in before I started, and I started when I was nineteen.
BARTENDER: Don't ask me his name. Thirty-one years and I never got it. Buys one glass and doesn't touch it.
BARTENDER: He's no trouble.
She wiped the bar where it didn't need wiping.
BARTENDER: He's the only one in here who's never been any trouble.
WRONGMAN: Everybody said that about somebody, in the story.
-> opts

= rats_talk
~ pass(3)
BARTENDER: Junior wants them dead, the cook wants them dead, and the inspector's on the fourteenth.
BARTENDER: Table 28 feed one, under the table. They think I don't know.
BARTENDER: They come up through the keg room. Trapdoor's behind me, and mind the third step, it's rotten.
~ knows += keg_hole
BARTENDER: Me, I want a quiet night. Deal with them however you want, but don't do it in front of the customers.
FATHER: That's the job. Not dealing with it. Not being seen to.
-> opts

= how_long
~ pass(2)
BARTENDER: Thirty-one years. Thirty-two in March, God help me.
BARTENDER: I've had nine doormen. You're ten.
BARTENDER: Table 28's had more than that. They were the young ones when I started, and they were worse than any kids you'll see tonight, believe me.
~ knows += dennis
BARTENDER: That's Dennis, in the big glasses. His wife'll be in for him around one. She always is.
// HUTCH: The lifer's history with table 28. She knew them when they were young. What were they like?
-> opts

= name
~ pass(1)
~ asked_name = true
She looked at him for a second longer than she needed to.
BARTENDER: Last a week, Door. Then ask me.
// HUTCH: Her name. Or keep it back until he's earned it.
-> opts

// He's heard the last one left his jacket (office.ink, prologue.ink). Claude's draft, PROPOSED.
= jacket_ask
~ pass(1)
~ knows += lost_jacket
She pointed down with the knife, at the drawer under the till.
BARTENDER: Lost-and-found. Bottom of the drawer, under three winters of toques.
BARTENDER: Nobody's been through the pockets. I never wanted to know.
~ drawer_from = 1
-> the_drawer

// Counted from the start of the shift: Gary's two at four o'clock aren't hers to count (prologue.ink).
// Every one she pours him, she's in it with him (she_poured): the log can say so (closing.ink).
= shift_drink
~ pass(3)
{
- drinks - drinks_before == 0:
    She poured a rye and put it on the ledge, not the bar, where the customers couldn't see it. #sfx: glass
    BARTENDER: That's your one. On the ledge, not the bar, and you don't come back for two.
    ~ she_poured++
    ~ drink()
    FATHER: One.
    { drinks_before:
        FATHER: And Gary's, at four. Don't think I didn't count those.
    }
- drinks - drinks_before == 1:
    She poured it. She put it on the ledge. She didn't say anything this time, which was worse. #sfx: glass
    ~ she_poured++
    ~ drink()
    ~ rep(rep_staff, -1)
    FATHER: Two. Two is how it starts. One is a drink and two is a decision.
- drinks - drinks_before == 2:
    She looked at him. Then she poured it, because she was a bartender and he was a grown man, and she'd seen nine doormen. #sfx: glass
    ~ she_poured++
    ~ drink()
    ~ rep(rep_staff, -1)
    FIGHTER: Loose. Good. You're better loose.
    FATHER: I stopped. You know I stopped. You know what it cost me to stop.
- else:
    BARTENDER: No.
    {stopping:
    - She put a glass of water on the ledge.
        BARTENDER: Drink that, and go and stand at your door.
    - She pushed the glass of water along the ledge an inch, toward him.
        BARTENDER: Your door's still there.
    }
    ~ rep(rep_staff, -1)
}
-> opts

// From ten the lager's been spitting foam (things.ink, toy_taps). If he hasn't changed the keg
// himself (rats.ink, at_keg.change_keg), she goes down and does it, and her bar is his while she's
// down there. Hutch (14 October): "there should be other temptations as well, like pouring ourself
// a beer when the bartender isn't looking or asking the bartender and implicating them"
// (bible/11_SKELETON.md, Temptations). Claude's draft, PROPOSED.
= lager_out
~ pass(1)
She pulled a lager and it came out foam, and she tipped it in the sink and pulled again, and it was foam again. #look: bartender
BARTENDER: Fuckin' lager.
BARTENDER: Watch my bar, Door. Two minutes.
~ lager_down = true
She lifted the trapdoor and went down, minding the third step, and he heard the keg room door bang shut under his feet.
For two minutes it was his: the taps, the till, the rail, the well. Nobody at the bar wanted anything. In the back-bar mirror, between the bottles, the room, and him in it, at her bar with nobody behind it.
* (watched) [Watch her bar.]
    ~ watched_bar = true
    ~ pass(2)
    He stood in the gap in the stools with his back to her taps and watched the room, and the room watched the hockey.
    -> lager_up
* [Go round and pour himself one. #hand: drink]
    -> self_pour
* (left_bar) [Back to his door.]
    -> lager_left

// The pint he pulled himself is in his hand, and the voices read it (hand.ink, reads_pint).
= self_pour
~ poured_self++
~ pass(1)
He went round behind the bar and took a pint glass off the stack and pulled himself a red, because the lager was off and the red was nearest. It came up clean, with a head you could stand a coin on. #prop: pint
- (pr)
<- reads_pint(-> pr)
* [Drink it down and rinse the glass, before she's up. #hand: drink #check: fighter:dex 12]
    ~ drink()
    { passed:
        ~ pour_how = 1
        He drank it in four swallows standing behind her taps, and rinsed the glass, and put it upside down on the rack with the others, and was back in the gap in the stools with the back of his hand across his mouth when the trapdoor came up.
    - else:
        ~ pour_how = -1
        He had it half down when the trapdoor came up, and her head after it.
    }
* [Take it round to the ledge, where she puts his. #hand: drink]
    ~ pour_how = 2
    ~ drink()
    He put it on the ledge, not the bar, where she put his, and went back round to the gap in the stools and drank it there as if she'd poured it.
* [Pour it down the sink.]
    ~ pour_how = 3
    He looked at it a while. Then he tipped it down the bar sink, and rinsed the glass, and put it on the rack with the others.
- -> lager_up

// She comes up from the keg room, and she counts.
= lager_up
~ lager_down = false
The trapdoor came up, and she came up after it, wiping her hands on the bar towel. #look: bartender
BARTENDER: Lager's back.
She said it to the room. Then she looked at the till, and the rail, and him.
{
- pour_how == -1:
    ~ rep(rep_staff, -2)
    She looked at the glass in his hand, and at the red tap, and at him.
    BARTENDER: You want one, you ask me. Nobody pours in my bar. Nobody.
    She took the glass out of his hand and put it in the sink, half full, and rang it in. #sfx: till
    ~ cash -= 7
    BARTENDER: Seven-fifty. Call it seven.
- pour_how == 2:
    ~ rep(rep_staff, -1)
    She looked at the pint on the ledge, which she hadn't poured.
    She rang it in without asking him what it was. She knew what it was. #sfx: till
    ~ cash -= 7
    BARTENDER: Seven-fifty. Call it seven. Next time you ask me, Door.
- pour_how == 1:
    She looked at the rack, where one glass was wet with the others dry, and at him, and he looked at the room.
    BARTENDER: Mm.
- pour_how == 3:
    She looked at the rack, where one glass was wet with the others dry.
    BARTENDER: Mm.
- watched_bar:
    ~ rep(rep_staff, 1)
    BARTENDER: Mm. Thanks.
    Nine doormen, she'd had, and every one of them had helped himself to something while she was down there.
}
-> opts

// He went back to his door and left her bar to itself, and table 28 helped themselves.
= lager_left
~ rep(rep_staff, -1)
~ here = door
He went back to his door.
From the stool he watched the one in the team jacket get up from table 28 and go round behind the bar, the way he must have done it in nineteen eighty-one, and start pulling a round.
~ lager_down = false
The trapdoor came up, and she came up after it, and stood there with the bar towel in her hand.
BARTENDER: Out.
TEAM_JACKET: Lager's off!
TABLE28: Hear, hear!
He went, and she poured their round, and when she'd done it she looked down the room at the doorman on his stool, and didn't say anything.
-> carry_on

= endbar
~ pass(5)
{
- at_bar.endbar == 1:
    He went and stood by the old man at the end of the bar, near the trapdoor. Up close he was older than he'd looked{knows ? endbar_wharf: on the wharf}, and cleaner, in a jacket that had been good fifty years ago{knows ? endbar_wharf:, and dry}. The glass in front of him was full to the brim. Nothing had been drunk out of it. #portrait: endbar
    // HUTCH: The man who seems to speak for the rats. How does he talk? He's been coming in longer than the bartender has worked there.
    // On the wharf at dusk (walk.ink), he'd heard the Sov had a doorman before anyone told him.
    {
    - wharf_how == 1:
        ENDBAR: Word gets around, you said, on the wharf. It does. Underneath.
    - wharf_how == 2:
        ENDBAR: You asked me on the wharf who was asking. It is the right question at a door. It is the wrong one on a wharf.
    - wharf_how == 3:
        ENDBAR: You looked at the water with me, on the wharf. Very few do. They look at their phones, or at me.
    - else:
        ENDBAR: You are the new door.
    }
    ENDBAR: This was a cannery, before it was a hotel. Did no one tell you? The tide came in under the floor twice a day, right under where you are standing. Fish heads and salt.
    ENDBAR: They built the hotel on the pilings, and the pilings are still there. So is everything that lived in them.
    { nursed:
        ENDBAR: You held a rye at that table and did not drink it. Not many can. I saw.
    }
    FATHER: He's drunk.
    But the glass was full.
- at_bar.endbar == 2:
    ENDBAR: The owner would like you to deal with them.
    He said it like he'd read the note. Maybe he had. It was taped to the till.
    ENDBAR: People always think it is a matter of poison. It is a matter of terms.
    ENDBAR: Go down, after, when it is quiet. If you would care to talk about it.
    WRONGMAN: Talk about it. With who.
    ~ knows += keg_hole
    ~ knows += endbar_invite
- else:
    ENDBAR: {shuffle:Still raining. High water at two, and the wind behind it.|They are listening, you know. In the walls. They hear every word table 28 says.|Terms. It is only ever a matter of terms.}
}
-> opts


// ------------------------------------------------------------------ 8:15 the card machine goes down

// Heard from wherever he is; then he goes and stands by her, the way a doorman does when the money
// stops, since that's where the arguing will be.
=== ev_card ===
~ ev_card_done = true
The card machine beeped three times and its screen went blank. Then the one at the other end of the bar did it too. #sfx: till #look: bartender
BARTENDER: And there she goes.
BARTENDER: Network's down, third time this week. Cash only, folks. Cash only.
TABLE28: Cash is king!
They'd never paid any other way. Table 28 thought cards were a fad.
{ here != bar:
    ~ here = bar
    He went and stood in the gap in the stools, where the arguments would come. #look: bartender
}
The TV over the bar had cut to a panel of men in suits talking in front of a map. The sound was off. The banner under them said something about the capital that nobody in the bar read.
// Hutch, in director mode (27 Sept), on what stops working first in a town like his: it's an island, so
// it's the shipments from the mainland. When diesel's too dear for the trucks to make sense, things
// start disappearing off the shelves, slowly, and then all at once. (Worked in by Claude.)
The limes had come in short again. She was cutting them into eighths instead of quarters, and there was a strip of cardboard taped over one of the taps with NO MORE TIL TUES on it in marker.
BARTENDER: Truck didn't come off the ferry with half my order. Again.
TABLE28: It's the diesel!
They'd been saying it since two o'clock. It was the first thing they'd said all day that everyone in the room agreed with.
SLIPPERS: Cash? I haven't got cash.
One of the two women from upstairs, with an empty wine glass, standing at the bar in her slippers.
SLIPPERS: I never have cash. My husband always carried the cash.
- (card)
* (lent) [Lend her twenty.]
    ~ cash -= 20
    She took it and looked at it like she'd forgotten what they looked like.
    SLIPPERS: I'm in nine, dear. I'll get it to you. I will.
    FATHER: You'll never see it again.
    WRONGMAN: Or you will, and it'll be the worst twenty you ever got back.
* ["Can she run a tab till it's back up?"]
    BARTENDER: She can run a tab till the day she dies, and she will.
    She started one on a napkin.
    ~ rep(rep_staff, 1)
* [Stay out of it.]
    ~ slippers_upstairs = true
    ~ room_count--
    BARTENDER: Sorry, hon.
    The woman went back upstairs in her slippers. Her friend stayed with the bottle.
    WRONGMAN: Twenty dollars. In the story it was always about twenty dollars, once you got to the bottom of it.
- ~ pass(3)
-> carry_on


// ------------------------------------------------------------------ midnight: the owner calls

=== ev_owner ===
~ ev_owner_done = true
The bar phone rang. It was the kind of phone with a cord. #sfx: phone #look: bartender
{ here == bar:
    The bartender answered, listened, said "He's fine," listened, and held it out across the bar.
- else:
    The bartender answered, listened, said "He's fine," listened, and held it up where he could see it, the cord stretched across the bar.
    ~ here = bar
}
BARTENDER: It's Junior. For you. #look: bartender
// Hutch, in director mode (27 Sept): an owner who's never there asks "How is it tonight?", and means
// how busy is it, how much money am I making. What the doorman tells him, the till tells him too in
// the morning. (Worked in by Claude.)
OWNER: How is it tonight?
{ owner_missed:
    OWNER: Somebody rang me from the bar phone at {q_words(owner_missed)}. I'm at dinner here.
}
// The door's number: everyone he let in, and the thirteen. Short of the room by whoever got past
// him, and the bartender, who rings in every drink, knows it.
* [Give him the door's number.]
    ~ owner_count = 1
    He gave him the number: everyone he'd let in past the stool, and the thirteen who'd been in when he came on.
    OWNER: That's a Wednesday. I can live with a Wednesday.
    { uncounted > 0:
        Behind the bar, the bartender, who'd rung in drinks tonight for more faces than that, didn't say anything.
    }
    ~ rep(rep_owner, 1)
* ["Quiet."]
    ~ owner_count = 0
    OWNER: Quiet. Sure. Wednesday's quiet, I know Wednesday's quiet. I just like to hear it.
* ["Busy."]
    ~ owner_count = -1
    ~ rep(rep_owner, 1)
    ~ rep(rep_staff, -1)
    OWNER: Busy. Good. That's what I like to hear, buddy.
    The bartender, who'd rung in every drink, looked at him over the till.
    FATHER: He'll have the till tape in the morning. You'll have said busy.
- OWNER: Now. The rats. Did we do something about the rats?
- (oc)
* (told_poison) {poison} ["Poison's down."]
    OWNER: Good man. That's what I like to hear.
    ~ rep(rep_owner, 2)
* {traps} ["Traps are set."]
    OWNER: Traps. Fine, fine. Traps are a start.
    ~ rep(rep_owner, 1)
* {rats_killed > 0 && not poison && not traps} ["I've killed {rats_killed == 1:one|a couple}."]
    OWNER: One at a time. Buddy, there's hundreds of them, and the inspector's on the fourteenth.
    OWNER: There's a bucket of bait in the office. I paid for that bait. Put it down.
    # task: bait :: The owner wants the bait down. It's in the office in the keg room.
* {not poison && not traps} ["It's handled."]
    ~ owner_lie = true
    OWNER: Good. I'm going to hold you to that. The fourteenth.
    ~ rep(rep_owner, 1)
    FATHER: It isn't handled. Now it's a lie with a date on it.
* ["Not yet."]
    OWNER: Not yet. The inspector is on the fourteenth. Not yet is not a thing I can put in front of an inspector.
    ~ rep(rep_owner, -1)
- OWNER: And listen. Table 28 get whatever they want. That's half my Wednesday right there.
{
- arrivals ? banned_in && arrivals !? banned_out:
    OWNER: And a fella might come by tonight, good coat. {owner_missed:Graham. That'll be what you rang about. }We had a talk. He's all right now, let him in.
    The doorman looked down the bar at the good coat, already in.
- arrivals ? banned_out:
    -> turned_away
- owner_missed:
    OWNER: And whatever you rang about, it can't have been much. Nobody's called me about it.
}
-> hang_up

= turned_away
{ arrivals ? banned_in:
    OWNER: Fella in a good coat called me. Graham. Says you let him in for one and then put him out. That'll be what you rang about.
- else:
    OWNER: Fella in a good coat tried to come in tonight? Says you turned him away at the door. {owner_missed:That'll be what you rang about.}
}
* ["The book says not ever."]
    OWNER: That book's old, buddy.
    OWNER: Fine, fine. We'll talk about it.
    ~ rep(rep_owner, -1)
    ~ rep(rep_staff, 1)
    The bartender, who could hear every word, didn't look up.
// Learned when GOOD SHOES got in without him (door.ink): "The owner didn't write it. I did."
* {knows ? binder_hers} ["She wrote it. Not you."]
    OWNER: She writes a lot of things.
    There was a long breath at the other end, the sound of a man deciding what a thing was going to cost him.
    OWNER: Put her on.
    ~ rep(rep_owner, -2)
    ~ rep(rep_staff, 2)
    The bartender took the phone. She listened, and said "Yep," and "No," and "Not ever," and hung up, and went back to wiping the bar as if she'd never stopped.
    -> carry_on
* ["I'll let him in next time."]
    OWNER: Good man.
    ~ rep(rep_owner, 1)
    ~ rep(rep_staff, -2)
    The bartender could hear every word. She didn't look up. She stopped wiping the bar.
- -> hang_up

= hang_up
OWNER: Good. Good. Put her back on, my food's here.
He handed the phone back. She listened, said "Yep," and "Yep," and hung up.
~ pass(4)
-> carry_on
