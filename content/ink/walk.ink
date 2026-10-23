// 4:40 to 7:40 pm. From Gary's porch steps to the Sov: the first time he's on the town's streets.
//
// PROPOSED (bible/05_LOG.md): the camera is his from the porch steps on, and his voices come with
// it. The walk teaches looking and going without saying so (bible/11_SKELETON.md): the old main
// street, the highway, the Esso's lights, the Sov's sign. He has three hours before he's due, and
// where he spends them is what he walks in knowing: the old man on the wharf, the kid at the Esso
// and the light over the strait, the Sov's front from across the highway, or his room, with the
// bartender on the deck under it, on the phone to Gary.

=== dusk ===
~ here = street
~ clock = 1000
# amb: street
// What the interview made of him (office.ink), printed once, where the camera becomes his.
NARRATOR: That was how Gary told it. From the porch steps on, it goes the way the doorman told it, which was less often. #stats
The rain had eased off to the kind you could only see under a lamp, and the lamps were coming on down the old main street, one and then the next, as if somebody were walking ahead of him switching them on.
// The first thing in his own head all day: his father, who was in the office with him, and kept
// quiet, and saw how he sat.
{
- sat_how == 1:
    FATHER: You sat with your back to his door. Never sit with your back to a door.
- sat_how == 3:
    FATHER: You turned his chair so you could see his door. Good. Somebody's always coming through it.
- licence_how == 2:
    FATHER: You made him reach for your licence. Good. Make them reach.
- else:
    FATHER: You looked at his room before you sat down in it. Good.
}
The street ran downhill to the highway. The library, brick, one window lit. The Legion, long and low, with a field gun on a plinth out front pointed at the bank. He'd closed the Legion last night. The bank had been a cafe for eleven years and still said BANK over the door, cut in the stone. A thrift store. A video store with the posters still up from the year it shut. A white wooden church at one end and a grey stone one at the other.
At the bottom, across the highway, the government wharf went out into the strait on its pilings, with a few fish boats tied along it and a light coming on at the end.
FATHER: Walk to a new door, the first time. See what they walk past to get to you.
* [Cross over to the wharf.]
    -> wharf
* [Go along the highway.]
    -> highway

// The old man from the end of the bar is on the wharf at dusk and at his place by the trapdoor at
// 7:40, and nobody sees him go between them (prologue.ink).
= wharf
~ knows += endbar_wharf
He went down and across the highway between two log trucks, and out along the wharf. The planks were wet, and the tide was in, high enough to hear it underneath, working at the pilings.
At the end, under the light, an old man stood at the rail in a jacket that had been good a long time ago, and no coat over it, and didn't seem to mind the rain. No rod, no dog, no boat. #portrait: endbar
ENDBAR: Good evening.
ENDBAR: One hears the Sovereign has a doorman again.
He didn't look round to say it. He was looking down at the pilings, where the water went in and out between them, as if he were counting something.
{ stat_gut >= 5:
    He had the feeling, which he'd learn to trust and never to explain, that the old man had been out there a while waiting for him, and had known how long he'd be.
}
* ["Word gets around."]
    ~ wharf_how = 1
    ENDBAR: Everything gets around, in a town on pilings. It is all underneath, going back and forth.
* ["Who's asking?"]
    ~ wharf_how = 2
    ENDBAR: Nobody is asking, Doorman. I am telling you I heard.
* [Say nothing. Look at the water with him.]
    ~ wharf_how = 3
    They looked at it together for a while. It went in under the wharf and came out again.
    ENDBAR: Just so.
- He went back along the planks. When he looked from the highway the old man was where he'd been, under the light, looking down.
-> highway

= highway
~ clock = MAX(clock, 1012)
He walked north along the shoulder with the water on his right and the trucks throwing it up off the road, toward the Sov's sign a long way down, small and red, the second E dead even from here.
The Esso came first, on the left. A canopy lit white from underneath, two islands of pumps, the store behind them with its window full of signs, and a kid in a toque and the Esso's vest sitting on the ice freezer by the door with his phone. #portrait: essokid
He hadn't eaten since the morning.
* [Stop at the Esso.]
    -> esso_lot
* [Keep walking.]
    ~ ate = -1
    -> the_sov

// The kid at the Esso (bible/11_SKELETON.md, the eccentrics): twenty, on nights, physics on his
// phone, and a gig rating a machine's answers. The clocks are Island Time.
= esso_lot
~ here = esso
~ clock = MAX(clock, 1015)
# amb: esso
Under the canopy the light was white and flat and made everything look like a photo of itself. There was a clock over the till inside, a clock on the screen of every pump, and the one on his phone, and none of them agreed.
FATHER: Eat. You won't get the chance after.
- (esso_hub)
* {ate == 0} [Get something to eat.]
    ~ ate = 1
    ~ cash -= 9
    He got two hot dogs off the roller and a coffee, nine dollars, and ate standing up under the canopy.
    -> esso_hub
* [Ask the kid what he's looking at.]
    -> kid_sky
* [Ask the kid if he's working.]
    -> kid_rater
* [Go on to the Sov.]
    { ate == 0:
        ~ ate = -1
    }
    -> the_sov

// What the town will argue about for a month, as fragments (bible/11_SKELETON.md, the end): it's
// never explained, and on day 1 it's only a light.
= kid_sky
~ knows += esso_sky
The kid didn't take his eyes off the sky over the strait. He pointed at it with his phone.
ESSOKID: That one. Over the mainland.
There was a light low over the water, where the cloud had torn. One light, white, not doing anything.
ESSOKID: Planes blink. Satellites move. It was there last night, same place, same time. Stars don't stay in the same place, man. That's like the whole thing about stars.
{ stat_gut >= 5:
    He looked at it for longer than he meant to. It didn't blink. He had the feeling, and couldn't have said where it came from, that it wasn't the only thing out there doing the looking.
}
ESSOKID: I filmed it. You can't see anything on the video. You never can.
-> esso_hub

// "The kind the Esso kid rated answers for" (bible/11_SKELETON.md, who's telling it).
= kid_rater
~ knows += esso_rater
ESSOKID: Kind of. Both.
He turned the phone round. Two paragraphs side by side, both answering the same question, which was something about a man whose father had died. A button under each.
ESSOKID: I rate them. Which one sounds more like a person. It's a site. Four cents an answer. I've done like eleven thousand.
ESSOKID: Go on. Which one?
* [The one on the left.]
    ~ rated = 1
    ESSOKID: Huh. Yeah. That's the one I'd have picked.
* [The one on the right.]
    ~ rated = 2
    ESSOKID: Yeah? Huh. Okay.
* ["Neither."]
    ~ rated = 3
    ESSOKID: Yeah, that's not one of the buttons.
- ESSOKID: They're both it, by the way. There's no person one. You're just saying which is more like.
He pressed {rated == 1:the left one|{rated == 2:the right one|one of them, after a while}}, and two new ones came up.
ESSOKID: It's getting hard to tell.
-> esso_hub

= the_sov
~ here = seawall
~ clock = MAX(clock, 1030)
# amb: seawall
The sign got bigger. SOVEREIGN, the second E dead, and under it HOTEL, all five letters working. {knows ? senior_photo:In the photo on Gary's wall every letter had been lit.} Three storeys of old wood painted a red that had gone to brick, the beer store at one end with its lights on, trucks nose-in along the front.
It was ten past five. He was due at half past seven, or quarter to eight, depending which of Gary's answers you went by.
Across the highway from it the seawall ran along the water, wide enough to sit on.
* [Sit on the seawall and watch it.]
    -> watching
* [Go up to the room.]
    -> twelve

// Watching the door from outside: who goes in, who comes out, who stands outside and thinks about
// it. What he sees comes back during the night (prologue.ink, door.ink).
= watching
~ knows += sov_watched
~ knows += coat_scouting
He sat on the seawall with the water at his back and watched the Sov the way you'd watch a door.
FATHER: Watch it from outside before you work it. Once you're in it, you're part of what you're watching.
At quarter past five a woman in an apron came out onto the deck at the side with a phone to her ear, and smoked, and talked, and laughed once, not happily, and went back in. #look: deck
At twenty to six a mill pickup pulled in and three men in hi-vis got out and went in at the hotel's end of the building, in no hurry, carrying their lunch kits.
At six somebody propped the deck door open with something small and folded, and went back in.
~ knows += coaster
At ten to seven a dark car came in off the highway, went once round the lot slowly, and left without stopping. At twenty past seven it did it again.
FATHER: That's a man looking to see who's on the door.
The lights went on in the windows upstairs, one at a time, and in the bar the TV came on, blue. Nobody went in or out of the front who looked like trouble, and nobody who looked like anything much.
At half past seven the rain came back across the strait, hard, the way it had been all afternoon. He sat in it another five minutes, because he'd said quarter to eight to himself, and then he went across.
-> cross

// Room twelve, at the end of the second floor, over the deck (closing.ink, go_upstairs). Terry's on
// the desk, and gives him the key board's procedure.
= twelve
~ here = upstairs
~ clock = MAX(clock, 1035)
~ from_room = true
~ knows += terry
He crossed the highway and went in at the hotel's end of the building, not the bar's.
There was a front desk with a bell on it and a board of keys behind it, most of them on their hooks, and a man on a stool behind it in a lanyard, watching a hockey game on a TV the size of a hardcover. #portrait: terry
TERRY: Oh, hey. You'll be the new door, eh. What's the score?
It was on the TV in front of him.
TERRY: Terry. Night desk. I come on at five and I'm on till the bread truck. Gary give you twelve? You'll want to sign for it, pal. Here. Nobody signs. I like people to sign.
* [Sign for it.]
    ~ terry_signed = 1
    He signed the book, under a column of names nobody had written in since August.
    TERRY: Oh, sure, sure. You bet. That's how it's supposed to go.
* ["Gary didn't say anything about signing."]
    ~ terry_signed = -1
    TERRY: Oh, no no, he wouldn't. Gary wouldn't.
    He closed the book, and looked at the hockey.
- He went up two flights that smelled of other people's cooking, and along the second floor to the end.
A bed, a chair, a sink in the corner, and a window onto the lot and the highway and the water. The radiator was on full and the knob had come off it a long time ago, so somebody had opened the window two inches and it wouldn't go any further.
He sat on the bed. Through the two inches came the rain, and the highway, and a woman's voice, from the deck right under the window, and her cigarette smoke with it.
-> under_window

// The bartender, on the phone to Gary about him: what he told Gary in the office, the way she
// takes it. She's the one who gets everything Gary hears (prologue.ink, closing.ink door_story).
= under_window
~ knows += heard_phone
BARTENDER: Yep. Mm. No, I'm out back. Go.
BARTENDER: He's what? Long hair? Christ, Junior.
~ temp n = 0
{ interview.the_rule.rude_gary:
    ~ n++
    BARTENDER: He said that? To you? Ha.
    She laughed, once, and coughed.
}
{ interview.the_deal.rude_bk && n < 3:
    ~ n++
    BARTENDER: He said that to her. Good.
}
{ threat == 1 && n < 3:
    ~ n++
    BARTENDER: He asked if you wanted to find out. And then he was kidding. They're always kidding.
}
{ told_gary ? tg_never && n < 3:
    ~ n++
    BARTENDER: Never been in a fight. Sure. And I've never had a drink.
}
{ told_gary ? tg_dry && n < 3:
    ~ n++
    BARTENDER: Doesn't drink. Doug says different. Doug says a lot, but.
}
{ n < 3:
    ~ n++
    {
    - told_gary ? tg_city:
        BARTENDER: Ten years on a door in the city. Mm. They've all done ten years in the city.
    - told_gary ? tg_up_island:
        BARTENDER: Up island. Who isn't.
    - told_gary ? tg_around:
        BARTENDER: Around. Around's not a place, Junior.
    - told_gary ? tg_father:
        BARTENDER: His dad did doors. Did he.
    }
}
{ n < 3:
    ~ n++
    {
    - told_gary ? tg_shorted:
        BARTENDER: The owner shorted him. And you laughed. Course you laughed.
    - told_gary ? tg_something:
        BARTENDER: Something happened. Something always happened, Junior.
    - told_gary ? tg_long:
        BARTENDER: Long story. Mine's thirty-one years.
    - told_gary ? tg_quiet:
        BARTENDER: He just sat there? Good.
    }
}
{ n < 3 && gary_rye != 0:
    ~ n++
    {
    - gary_rye == 1:
        BARTENDER: Drank it straight down. Mm.
    - gary_rye == 2:
        BARTENDER: He held it and didn't drink it. Huh.
    - gary_rye == 3:
        BARTENDER: Pushed it back. Your rye. Huh.
    - gary_rye == 4:
        BARTENDER: Two? At four o'clock? Christ.
    }
}
{ n < 3 && shirt == 1:
    ~ n++
    BARTENDER: You gave him one of those shirts. Junior. Nobody wears those shirts.
}
{ n < 3 && shirt == 2:
    ~ n++
    BARTENDER: He wouldn't take the shirt? Good for him.
}
{ n < 3 && rent_called:
    ~ n++
    BARTENDER: He caught her on the rent? Did he. Did he really.
}
{ n < 3 && asked_pay:
    ~ n++
    BARTENDER: He asked when he gets paid. Good. Nobody asks till they're short.
}
{ n < 3 && licence_how == 2:
    ~ n++
    BARTENDER: Made you reach for it. Ha.
}
{ n < 3:
    {
    - scenario == 1:
        BARTENDER: Water. Yep. Water I can do.
    - scenario == 2:
        BARTENDER: Whatever they want. That's what you'd say.
    - scenario == 3:
        BARTENDER: How's he getting home. Huh. Nobody's asked that in thirty-one years.
    - scenario == 4:
        BARTENDER: Put him out. Table 28. He'll learn.
    }
}
BARTENDER: Yep. Seven-thirty. I'll show him.
BARTENDER: No. No, Junior. I'll show him. Nine doormen, I've shown.
The deck door banged, and the smoke came up past the window without her.
WRONGMAN: In the story, the doorman heard them talking about him the first night. He should have shut the window.
{ shirt == 1:
    -> shirt_room
}
-> lie_down

// Gary's shirt, folded in four inside his jacket since the office (office.ink, the_shirt).
= shirt_room
Gary's shirt was still folded in four inside his jacket. He took it out and held it up. SECURITY, a hand high, in white.
* [Put it on, over the black one.]
    ~ shirt_on = true
    He put it on. It was a size too small across the shoulders, the way they always are.
* [Leave it on the chair.]
    ~ shirt_on = false
    He left it on the chair, folded, the word inside.
- -> lie_down

= lie_down
He lay down on the bed with his boots off the end of it and didn't sleep. The game went on downstairs on Terry's TV, and the room got dark, and the radiator ticked, and at half past seven the rain came back hard across the strait, the way it had been all afternoon.
At twenty to eight he went down past Terry, who asked him the score, and out the hotel's door into the rain, and round the front to the bar's door, because that was the door he'd be working.
-> cross

= cross
~ clock = 1180
-> prologue
