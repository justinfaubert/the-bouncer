// 7:40 pm. The lot, the building, the bartender, the note, the voices. Ten minutes before the first read at the door.
//
// He comes to it from Gary's office (office.ink) by way of the walk (walk.ink): across the highway
// from the seawall, or down from room twelve and round the front. A game started here, without
// the office, gets the night as it always was.

=== prologue ===
~ here = lot
# amb: rain_lot
{
- knows ? sov_watched:
    He crossed the highway with the rain coming down hard enough to bounce on the gravel, and walked up the lot between the trucks.
- from_room:
    The rain had come back across the strait with the last ferry. It hit the gravel lot hard enough to bounce.
- else:
    // The opening lines from Gary's office (office.ink, interview), for a night started here without it.
    // Hutch's prompt for them is there, where they're read first now.
    NARRATOR: He started on a Wednesday. The Sov tried out doormen on Wednesdays, on a night slow enough that a mistake would only hurt a little.
    NARRATOR: Of the thirty days, it was the one nobody else remembered.
    The rain had come across the strait with the last ferry and hadn't let up. It hit the gravel lot hard enough to bounce.
}
{ not (knows ? sov_watched):
    On the roof the sign said SOVEREIGN in red neon with the second E dead. Under it, HOTEL, all five letters working.
    Three storeys of old wood, painted a red that had faded to the colour of brick. The cold beer and wine store at one end with its lights on. Trucks parked nose-in along the front, wipers stopped where they'd been switched off. The highway behind him, and past the highway, the water.
}
{ knows ? sov_watched:
    FATHER: Two hours and a half. It's told you all it's going to from out there.
- else:
    FATHER: Look at a building before you go into it. It'll tell you what kind of night it has.
}
It told him Wednesday. #pause
// Gary's two at four o'clock (office.ink, do_you_drink): one of them's still in him.
{ gary_rye == 4:
    ~ drinks = 1
    ~ drinks_before = 1
    FATHER: Two at four o'clock. That's one still in you, whatever you think.
}
{ ate == -1:
    He hadn't eaten since the morning. It was a long way to two.
}
{ shirt == 1 && not from_room:
    -> vestibule
}
-> inside

// Gary's shirt, folded in four inside his jacket since the office (office.ink, the_shirt). In
// room twelve he's already put it on or left it on the chair (walk.ink).
= vestibule
In the vestibule, between the two doors, he took Gary's shirt out of his jacket.
* [Put it on, over the black one.]
    ~ shirt_on = true
    He put it on. It was a size too small across the shoulders, the way they always are.
* [Leave it in the jacket.]
    ~ shirt_on = false
    He left it where it was.
- -> inside

= inside
~ here = floor
# amb: room_quiet
# music: jukebox_early
He went in.
Beer, cleaner, piss, old wood and dust. The carpet had had a pattern once. By the bar rail it gave a little under his boots, where thirty years of spills had soaked through to the underlay.
A woman behind the bar was cutting limes. She looked at him, looked at the size of him, and went back to the limes. #portrait: bartender
// HUTCH: The lifer's first words to a new doorman. What does she actually say, and what does she not bother saying?
BARTENDER: You'll be the door, then. Hang on.
-> junior_rang ->
BARTENDER: Every drink in this room goes through my till. Anybody I pour for who didn't come past you, you find out how before you go home.
BARTENDER: Junior left you a note.{not stats_set: The owner, I mean.} I worked for his dad.
It was taped to the till in black marker. RATS. DEAL WITH IT. INSPECTOR ON THE 14TH. # task: rats :: Deal with the rats before the inspector comes on the 14th.
~ knows += the_note
{
- knows ? notice_read:
    The fourteenth, and the word on Gary's desk, circled twice.
- knows ? gary_dodged:
    So those were the few things.
}
# task: past :: Anybody who gets in without coming past him: find out how, before he goes home.
He turned around and looked at the room.
Five men at a round table in the front window, with the best view of the door and the TV. They were talking about the price of diesel, all at once, in one voice. The table had a number screwed to its edge: 28.
At the pool table, a big man and a smaller one were playing for money, the bills tucked under the rail.
Two women in slippers at the near end of the bar with a bottle of white wine between them. An old man at the far end, by the trapdoor, with a glass he wasn't drinking.
// The old man from the wharf (walk.ink): nobody sees him go between the two.
{ knows ? endbar_wharf:
    It was the old man from the wharf. His jacket was dry.
}
{ knows ? sov_watched:
    He'd watched the front of the building from across the highway since ten past five. Nobody like that had gone in at any door he could see.
}
FATHER: Count the room before it counts you. Those five in the window already think they own you.
FIGHTER: Big one at the pool table. Watch his left hand.
MANUAL: The licensee's duty of care begins at the threshold. You are the threshold.
WRONGMAN: It was a slow night in the story too. The man who told it said his brother didn't even look up when the wrong one came in.
-> before_eight

= before_eight
{ clock >= 1190: -> the_truck }
* ["Where do you want me?"]
    ~ pass(4)
    -> where_want
* [Count the room.]
    -> count_first
* [Take the stool by the door.]
    ~ here = door
    He took the stool inside the front door, where he could see the lot through the glass and the room over his shoulder.
    ~ clock = 1190
    -> the_truck

= where_want
BARTENDER: Front door's yours, that's the one that counts.
BARTENDER: Hotel door's at the end of the back hall. Residents come down that way, and the night clerk props it so he can hear the TV.
BARTENDER: Deck door's for the smokers. Kitchen door, the cook props that open, his fryer runs about a hundred degrees back there.
BARTENDER: They're all locked at night.
She cut another lime in half.
BARTENDER: Mostly.
FATHER: Four doors, and one of them's yours. That's three you're answerable for and can't see.
~ knows += coaster
~ knows += kitchen_gap
~ knows += hotel_gap
- (where_more)
* (asked_last) [{knows ? old_doorman:"Gary says the last one walked out."|"What happened to the last doorman?"}]
    ~ pass(2)
    { knows ? old_doorman:
        BARTENDER: Friday, middle of the rush, and left his jacket. That's Junior's version.
        BARTENDER: Ask table 28. You'll get three more, and the hell of it is they all happened.
    - else:
        BARTENDER: Walked out on a Friday, middle of the rush, and left his jacket.
        BARTENDER: Ask table 28 why. You'll get three stories, and the hell of it is they all happened.
    }
    ~ knows += old_doorman
    -> where_more
* (asked_anyone) ["Anyone I should know about?"]
    ~ pass(2)
    She tapped the underside of the bar with the knife.
    BARTENDER: Binder under the till, the eighty-sixes. Photos, most of them, and for how long. You read it before you sit on that stool.
    -> where_more
* {not asked_last && not asked_anyone} ["Okay."]
    -> before_eight
* {asked_last || asked_anyone} [Leave her to the limes.]
    -> before_eight
- -> before_eight

= count_first
FATHER: Heads first. Then faces. Then hands. Then the doors.
-> count_body ->
-> before_eight

= the_truck
~ here = door
{ clock < 1190:
    ~ clock = 1190
}
# sfx: door
Headlights swung across the front window and stopped. A pickup had pulled in at the edge of the lot and sat there with its engine running and its wipers going.
-> door_hoodie

// Gary rang her at quarter past five, from the office (walk.ink, under_window): she's had what he
// told Gary, the way Gary tells things. One of it, the one she'd pick.
= junior_rang
{ not stats_set:
    ->->
}
{ shirt_on:
    She looked at the shirt.
    BARTENDER: One of Junior's shirts. Christ.
}
{ knows ? sov_watched:
    BARTENDER: You sat on that wall two and a half hours. I saw you. Everybody saw you.
}
{ knows ? heard_phone:
    She looked at him the way you look at somebody you've only had described to you, and checked it against the description.
    ->->
}
{
- interview.the_rule.rude_gary || interview.the_deal.rude_bk:
    BARTENDER: Junior rang. Says you've got a mouth on you.
- told_gary ? tg_never:
    BARTENDER: Junior rang. Says you've never been in a fight.
    She looked at his hands while she said it.
- told_gary ? tg_dry:
    BARTENDER: Junior rang. Says you don't drink.
    She didn't say anything else about that.
- told_gary ? tg_city:
    BARTENDER: Junior rang. Ten years on a door in the city, he says.
- gary_rye == 4:
    BARTENDER: Junior rang. Says you can drink.
- told_gary ? tg_father:
    BARTENDER: Junior rang. Says your dad did doors.
- else:
    BARTENDER: Junior rang. Says you'll do.
}
->->
