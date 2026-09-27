// The bar: the bartender, the binder, the shift drink, and the old man at the end.
// The bartender is his partner and his witness (bible/02_SYSTEMS.md): she sees everything he does.
// Her respect (rep_staff) is the hardest thing in the game to earn.

=== at_bar ===
~ here = bar
{ due(): -> hub }
{ at_bar == 1:
    He leaned on the bar at the service end, out of the way of the taps.
- else:
    {shuffle:
    - He went back to the service end of the bar.
    - He leaned on the bar, out of the way of the taps.
    - The service end of the bar. She was pulling a pint and didn't look up.
    }
}
{ rep_staff <= -3:
    She served him the same way she served everyone, and not one bit more.
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
+ [{drinks == 0:"Pour me one."|"Another."} #hand: drink]
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
* [Fix the faces in his head. #check: manual 6 #toy: binder all]
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
BARTENDER: Table 28 doesn't get cut off. Owner's rule.
BARTENDER: The cook's all right, he's just hot. Leave the kitchen door alone unless you want to hear about it.
BARTENDER: Night clerk's name is Terry. He props the hotel door so he can watch our TV from the desk. Don't tell him I told you that.
BARTENDER: And if the card machine goes down, it's cash, and if they haven't got cash, they haven't got a drink.
// HUTCH: The lifer's house rules. What would she tell a new doorman, and what would she let him find out for himself?
~ knows += hotel_gap
~ knows += kitchen_gap
FATHER: Every bar's got its rules and none of them are written down. The written ones are for the inspector.
-> opts

= who_endbar
~ pass(2)
~ knows += endbar_seen
She didn't look down the bar. She didn't need to.
BARTENDER: Him? He was coming in before I started, and I started when I was nineteen.
BARTENDER: Don't ask me his name. I've never known it. He buys one glass and he doesn't drink it.
BARTENDER: He's no trouble.
She wiped the bar where it didn't need wiping.
BARTENDER: He's the only one in here who's never been any trouble.
WRONGMAN: Everybody said that about somebody, in the story.
-> opts

= rats_talk
~ pass(3)
BARTENDER: Owner wants them dead. Cook wants them dead. Inspector's on the fourteenth.
BARTENDER: Table 28 feeds one. They think I don't know.
BARTENDER: They come up through the keg room. There's a trapdoor behind me. Third step's rotten.
~ knows += keg_hole
BARTENDER: Me, I want a quiet night. Deal with them however you want, but don't do it in front of the customers.
FATHER: That's the job. Not dealing with it. Not being seen to.
-> opts

= how_long
~ pass(2)
BARTENDER: Thirty-one years. Thirty-two in March.
BARTENDER: I've seen nine doormen. You're ten.
BARTENDER: Table 28 have seen more than that. They were the young ones, when I started. They were worse than any kids you'll see tonight.
~ knows += dennis
BARTENDER: That's Dennis in the big glasses. His wife'll come in around one. She always does.
// HUTCH: The lifer's history with table 28. She knew them when they were young. What were they like?
-> opts

= name
~ pass(1)
She looked at him for a second longer than she needed to.
BARTENDER: Last a week. Then ask me.
// HUTCH: Her name. Or keep it back until he's earned it.
-> opts

= shift_drink
~ pass(3)
{
- drinks == 0:
    She poured a rye and put it on the ledge, not the bar, where the customers couldn't see it. #sfx: glass
    BARTENDER: One's fine. Nobody's fine on two.
    ~ drink()
    FATHER: One.
- drinks == 1:
    She poured it. She put it on the ledge. She didn't say anything this time, which was worse. #sfx: glass
    ~ drink()
    ~ rep(rep_staff, -1)
    FATHER: Two. Two is how it starts. One is a drink and two is a decision.
- drinks == 2:
    She looked at him. Then she poured it, because she was a bartender and he was a grown man, and she'd seen nine doormen. #sfx: glass
    ~ drink()
    ~ rep(rep_staff, -1)
    FIGHTER: Loose. Good. You're better loose.
    FATHER: I stopped. You know I stopped. You know what it cost me to stop.
- else:
    BARTENDER: No.
    She put a glass of water on the ledge.
    BARTENDER: Drink that, and go and stand at your door.
    ~ rep(rep_staff, -1)
}
-> opts

= endbar
~ pass(5)
{
- at_bar.endbar == 1:
    He went and stood by the old man at the end of the bar, near the trapdoor. Up close he was older than he'd looked, and cleaner, in a jacket that had been good fifty years ago. The glass in front of him was full to the brim. Nothing had been drunk out of it. #portrait: endbar
    // HUTCH: The man who seems to speak for the rats. How does he talk? He's been coming in longer than the bartender has worked there.
    ENDBAR: You're the new door.
    ENDBAR: It was a cannery, this, before it was a hotel. Did anyone tell you that? The tide came in under the floor. Twice a day, right under where you're standing. Fish heads and salt.
    ENDBAR: They built the hotel on the pilings and the pilings are still there. So's everything that lived in them.
    FATHER: He's drunk.
    But the glass was full.
- at_bar.endbar == 2:
    ENDBAR: The owner wants you to deal with them.
    He said it like he'd read the note. Maybe he had. It was taped to the till.
    ENDBAR: People always think it's a matter of poison. It's a matter of terms.
    ENDBAR: Go down, after, when it's quiet. If you want to talk about it.
    WRONGMAN: Talk about it. With who.
    ~ knows += keg_hole
    ~ knows += endbar_invite
- else:
    ENDBAR: {shuffle:Still raining.|They're listening, you know. In the walls. They hear everything table 28 says.|Terms. That's all it ever is.}
}
-> opts


// ------------------------------------------------------------------ 8:15 the card machine goes down

=== ev_card ===
~ ev_card_done = true
~ here = bar
The card machine beeped three times and its screen went blank. Then the one at the other end of the bar did it too. #sfx: till
BARTENDER: And there it goes.
BARTENDER: Network's down. Third time this week. It's cash, everybody.
TABLE28: Cash is king!
They'd never paid any other way. Table 28 thought cards were a fad.
The TV over the bar had cut to a panel of men in suits talking in front of a map. The sound was off. The banner under them said something about the capital that nobody in the bar read.
// HUTCH: The empire ending shows up as modern things failing (decided: a modern setting). What else stops working first, in a town like yours?
SLIPPERS: I haven't got cash.
One of the two women from upstairs, with an empty wine glass, standing at the bar in her slippers.
SLIPPERS: I never have cash. Who has cash?
- (card)
* (lent) [Lend her twenty.]
    ~ cash -= 20
    She took it and looked at it like she'd forgotten what they looked like.
    SLIPPERS: I'm in nine. I'll get it to you. I will.
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
- ~ pass(3)
-> hub


// ------------------------------------------------------------------ midnight: the owner calls

=== ev_owner ===
~ ev_owner_done = true
~ here = bar
The bar phone rang. It was the kind of phone with a cord. #sfx: phone
The bartender answered, listened, said "He's fine," listened, and held it out across the bar.
BARTENDER: For you.
// HUTCH: The owner, on the phone, at midnight. The money code. What does an owner who's never there actually ask?
OWNER: How's my new door.
OWNER: Quiet? Wednesday's quiet. Did you do something about the rats?
- (oc)
* {poison} ["Poison's down."]
    OWNER: Good man. That's what I like to hear.
    ~ rep(rep_owner, 2)
* {traps} ["Traps are set."]
    OWNER: Traps. Fine. Traps are fine.
    ~ rep(rep_owner, 1)
* {rats_killed > 0 && not poison && not traps} ["I've killed {rats_killed == 1:one|a couple}."]
    OWNER: One at a time. There's hundreds of them. The inspector's on the fourteenth.
* {not poison && not traps} ["It's handled."]
    ~ owner_lie = true
    OWNER: Good. I'll hold you to that. Inspector's on the fourteenth.
    ~ rep(rep_owner, 1)
    FATHER: It isn't handled. Now it's a lie with a date on it.
* ["Not yet."]
    OWNER: Not yet. The inspector is on the fourteenth. Not yet is not a thing I can put in front of an inspector.
    ~ rep(rep_owner, -1)
- OWNER: And listen. Table 28. Whatever they want.
{
- arrivals ? banned_in:
    OWNER: And a fella might come in tonight, good coat. He's all right now. Let him in.
    The doorman looked down the bar at the good coat, already in.
- arrivals ? banned_out:
    -> turned_away
}
-> hang_up

= turned_away
OWNER: Did a fella come in tonight, good coat? He says you turned him away.
* ["The book says not ever."]
    OWNER: The book's old.
    OWNER: Fine. Fine. We'll talk about it.
    ~ rep(rep_owner, -1)
    ~ rep(rep_staff, 1)
    The bartender, who could hear every word, didn't look up.
* ["I'll let him in next time."]
    OWNER: Good man.
    ~ rep(rep_owner, 1)
    ~ rep(rep_staff, -2)
    The bartender could hear every word. She didn't look up. She stopped wiping the bar.
- -> hang_up

= hang_up
OWNER: Right. Good. Put her back on.
He handed the phone back. She listened, said "Yep," and "Yep," and hung up.
~ pass(4)
-> hub
