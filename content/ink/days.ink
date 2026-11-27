// The days after Wednesday. The month runs on from the tape at close: what he did on Wednesday is
// still in every VAR and LIST, and the days read it. (bible/11_SKELETON.md, The month; the pace and
// length doc: thirty days at three speeds, DECIDED 19 November.)
//
//   day 2, Thursday    his own day. The daylight is the clock: sunset is at 4:48, and every outing
//                      spends some of it. The paper, the napkin, the wharf and the trap, the Lesso,
//                      table 28 by day, Lorraine in six, the sign coming on, eleven's crib game.
//   day 3, Friday      the first real shift (friday.ink)
//
// Claude's drafts, all of it, PROPOSED. Hutch has final cut; the `// HUTCH:` prompts are his.

INCLUDE friday.ink

CONST SUNSET = 1008         // 4:48 pm, Thursday 5 November, on the island

LIST d2 = d2_window, d2_lot, d2_step, d2_boots, d2_mirror, d2_paper, d2_paid, d2_napkin, d2_trap, d2_hauled, d2_esso, d2_ate, d2_t28, d2_slept, d2_sign, d2_lorraine, d2_crib, d2_early, d2_kayla
VAR d2_done = ()
LIST paper = pp_front, pp_blotter, pp_obit, pp_ads, pp_letter, pp_tide
VAR paper_read = ()
VAR trap_in = 0             // the clock when the old man's trap went in off the wharf (0: it didn't)
VAR lorraine_how = 0        // Lorraine at his door for a light: 1 gave her one, 2 "maybe Friday", -1 shut the door
VAR crib_won = 0            // dollars won (or lost, below 0) at crib in eleven
VAR key_left = false        // he left the key from the trap in the wire for the old man
VAR kayla_thu = 0          // the big man's daughter at his dead truck on Thursday: 1 he boosted it, 2 he asked if her dad was sober, -1 walked past
VAR hangover = 0            // what Thursday night leaves in him for Friday: drinks after ten


// A new day: what resets overnight, and what doesn't. Everything he's done and everyone he's met
// carries on; what's in his blood, the clock and the door's own counts start again.
=== function new_day(n)
~ day = n
~ drinks = 0
~ drinks_before = 0
~ door_away = 0
~ walk_ins = 0
~ walk_ins_seen = 0
~ uncounted = 0
~ count_in = 0
{ hurt > 0:
    ~ hurt--
}


// ------------------------------------------------------------------ dawn

// After the tape. He goes up the back stairs to twelve in the first grey.
=== dawn ===
~ here = upstairs
+ [Go up to twelve.]
    ~ d2_done += d2_boots
    He lay down on top of the blanket in his clothes, and his boots, and was gone before he'd got them off.
+ [Sit on the back step till it's light.]
    ~ d2_done += d2_step
    He sat on the step by the dumpster with his jacket round him. The gulls came first, and then the bread truck, and then the light, grey, from behind the hill.
- NARRATOR: He slept till noon. He dreamed about the water off the wharf, and something coming up out of it, round and black and wet, without a ripple. I've told it to you before anyone else. #pause
~ new_day(2)
~ clock = 705
-> thursday


// ------------------------------------------------------------------ Thursday

=== thursday ===
~ here = upstairs
THURSDAY #class: day
Grey light, off the water, through the two inches the window would open. Somebody in the lot was scraping a windshield with a credit card.
{ hurt >= 1:
    He sat up and his ribs told him about last night.
}
{ d2_done ? d2_boots:
    He still had his boots on. One lace had come undone in the night and nothing else had.
}
{ d2_done ? d2_step:
    There was grit from the back step still pressed into the heel of his hand.
}
{ wallet_how == 3:
    GOOD SHOES's wallet was on the edge of the sink, where he'd put it at three in the morning so he'd see it.
}
{ shirt == 1 && not shirt_on:
    The black shirt was on the chair, still folded the way it came out of the box.
}
- (room)
* [Look out the window.]
    ~ pass(2)
    ~ d2_done += d2_window
    {
    - not truck_gone:
        The lot was nearly empty. Where the pickup had been there was a cigarette pack and a puddle with a rainbow on it.
    - else:
        The lot was nearly empty. A gull was working at a burger box by the dumpster.
    }
    { fam !? dad_drove && fam !? dad_walked:
        The big man's work truck was still at the edge of the gravel, with a parking ticket under the wiper and the school photo in the visor.
    }
    Past the highway the strait was the colour of a sink. A tug pulled a boom of logs north, so slowly it didn't seem to be moving.
    -> room
* (mirror) [The sink.]
    ~ pass(3)
    ~ d2_done += d2_mirror
    The mirror over the sink had lost its silver in one corner. He ran the cold till it was cold, and looked.
    { claims ? said_city_door:
        A big man who'd told Gary ten years on a city door, and looked it this morning.
    - else:
        A big man with his hair wet at the front and two days of beard, who'd look like this at forty.
    }
    { stat_con >= 6:
        He felt all right. He usually did, the morning after. Two ex-girlfriends had held it against him.
    - else:
        Behind his eyes there was a small dry ache he knew would be there till about three.
    }
    FATHER: Comb that. You'll be in the paper someday.
    -> room
* [Lie back down.]
    ~ d2_done += d2_slept
    ~ pass(150)
    He lay back down. Through the wall, six had the marine forecast on. Gale warning continued, Haro Strait. Seas three metres, building. He slept through all of it.
    When he woke it was nearly three, and the room had gone a darker grey.
    -> desk
+ [Go down.]
    -> desk


// The front desk by day. Terry's on doubles: the day girl has the flu.
=== desk ===
~ here = hall
~ pass(3)
Terry was on his stool behind the desk in yesterday's lanyard. The TV the size of a hardcover had curling on it. #portrait: terry
{ terry_signed == 1:
    TERRY: Oh, hey. Twelve. Shauna's got the flu, so I'm on doubles, eh. You sleep? You signed, so I knew where you were. That's what the book's for.
- else:
    TERRY: Oh, hey. Twelve, right? Shauna's got the flu, so I'm on doubles. I had to look you up. You didn't sign, so I looked you up by the key.
}
On the end of the desk there was a stack of the Shoreline with a coffee can beside it. HONOUR SYSTEM $2, on masking tape. The can had a toonie in it and a button.
- (desk_hub)
* {d2_done !? d2_paper} [Put a toonie in the can and take a paper.]
    ~ cash -= 2
    ~ d2_done += d2_paid
    ~ d2_done += d2_paper
    TERRY: There you go. See, now that's two.
    -> paper_read_it
* {d2_done !? d2_paper} [Take a paper.]
    ~ d2_done += d2_paper
    He took one off the top. Terry watched the can, and then the curling.
    TERRY: Oh, sure. Sure.
    -> paper_read_it
* ["Where do I get something to eat round here?"]
    ~ d2_done += d2_napkin
    Terry pulled a paper napkin out of a box under the desk and drew on it with a pen from a bank, slowly, with his tongue in the corner of his mouth.
    A line for the highway. A square for the Sov, with an X in it. North of it, a circle. LESSO, and under it, HOT DOGS OK. Up the hill, THRIFT and HARDWARE. At the top, a square he shaded in hard till the pen went through.
    TERRY: Don't go to the Legion. #prop: napkin
    TERRY: That's not a rule, that's just me. Doug's at the Legion.
    -> desk_hub
+ [Go out.]
    -> strip


// The Shoreline, Thursday 5 November. Most of it went to press on Tuesday, so the week it's about
// is last week. What he did on Wednesday is in it a week from now, wrong (bible/11_SKELETON.md).
=== paper_read_it ===
THE SHORELINE. Serving the Island since 1911. Thursday, November 5. #prop: shoreline
- (pages)
* [The front page.]
    ~ pass(2)
    ~ paper_read += pp_front
    MILL TALKS "PRODUCTIVE", SAYS UNION. A photo of two men shaking hands in front of a flag, neither of them looking at the other.
    Under the fold: SEWER RATE TO RISE 9%.
    -> pages
* [The police blotter.]
    ~ pass(2)
    ~ paper_read += pp_blotter
    October 28, 11:40 p.m. Police attended a licensed premises on the Island Highway for a report of an intoxicated male refusing to leave. The male had left by the time police arrived.
    October 31. A quantity of copper wire was reported stolen from the mill's north yard.
    November 1, 3:10 a.m. A resident reported a light over the strait, stationary, "like a star but too low". Police attended and observed nothing.
    MANUAL: Police attendance is to be requested for any incident involving violence or the threat of violence. Expect a delay.
    -> pages
* [The obituaries.]
    ~ pass(2)
    ~ paper_read += pp_obit
    PELLETIER, Irene Margaret, 1934 to 2026. Peacefully. Irene danced at the Sovereign on its opening night in 1958 and liked to say she was in the photo. She is survived by a son in Nanaimo and her cat, Dutch.
    FATHER: She's not in the photo. Everybody says they're in the photo.
    -> pages
* [The classifieds.]
    ~ pass(2)
    ~ paper_read += pp_ads
    FOR SALE. Craftsman tools, the whole chest. Husband's. Offers. Ask for Darlene, Sov, Fridays.
    LOST. Hearing aid, left ear, Sovereign Hotel area. Reward.
    WANTED. Doorman, Sovereign Hotel, nights. Apply in person to G. Van Dusen.
    That one was him. They hadn't taken it out yet.
    -> pages
* [The letters.]
    ~ pass(3)
    ~ paper_read += pp_letter
    Sir, the clock on the old bank has lost eleven minutes since Labour Day. I have written to the Village twice. Either somebody is responsible for that clock or nobody is, and I would like to know which. R. Haig, Wharf Street.
    WRONGMAN: The drunk said the bar clock was fast. Then he said it was the only one right.
    -> pages
* [The tide table.]
    ~ pass(2)
    ~ paper_read += pp_tide
    Five columns of times and heights, small. Thursday's low was 0.3 metres at 11:52. Next Wednesday's column was empty, the box printed and nothing in it.
    He read it twice. He tilted it to the window. Wednesday's box was still empty.
    -> pages
+ [Fold it into his back pocket.]
    -> desk.desk_hub


// ------------------------------------------------------------------ the strip, by daylight

// Where he can go, as long as the light lasts. Sunset is at 4:48.
=== strip ===
~ here = street
{ clock >= SUNSET:
    -> the_sign
}
{
- clock < 840:
    { d2_done ? d2_window:
        The tug he'd watched from the window was off the point now, still towing, still not seeming to move.
    }
    Out on the highway's shoulder it was bright without any sun. Gulls stood on the seawall facing the same way, into the wind.
- clock < 930:
    The cloud had come down over the hill. The cars on the highway had their lights on, in the afternoon.
- else:
    The light was going already. The Lesso's canopy was on, white, at the far end of it.
}
- (go)
* {trap_in == 0} [Down to the wharf.]
    -> wharf_day
* {trap_in > 0 && d2_done !? d2_hauled && clock >= trap_in + 120} [Back to the wharf, to haul the trap.]
    -> haul
* [Up to the Lesso.]
    -> esso_day
* {clock >= 840 && fam !? dad_drove && fam !? dad_walked && d2_done !? d2_kayla} [The big man's truck. Somebody's in it, turning the key.]
    -> kayla_truck
* {clock >= 840} [Into the Sov by the front. Table 28 will be in.]
    -> t28_day
+ [Back up to twelve.]
    -> twelve_day
+ {clock >= SUNSET - 40} [Cross to the seawall and watch the sign come on.]
    -> the_sign


// The old man on the wharf, by day. He has a crab trap, and arms, he says, that the tide doesn't
// remember any more. The trap comes up at dusk with something in it besides crabs.
=== wharf_day ===
~ here = street
~ pass(8)
He went across the highway and out along the planks. The tide was out, a long way out, and the pilings stood up black and bearded with weed out of mud that steamed a little.
{ wharf_how > 0:
    The old man was at the rail where he'd been last night, in the same jacket. A crab trap sat on the planks beside him: a cage of wire and rope, a fish head tied inside it with string. #portrait: endbar
    ENDBAR: Doorman. You survived the Wednesday.
- else:
    At the end, at the rail, there was an old man in a tweed jacket with leather on the elbows. A crab trap sat on the planks beside him: a cage of wire and rope, a fish head tied inside it with string. #portrait: endbar
    ENDBAR: Doorman. One saw you at the end of the bar last night, and one sees you here.
}
{
- rats == truce:
    ENDBAR: They were pleased with the step. I am to say so.
- rats == war:
    ENDBAR: There is a smell in the keg room this morning. You will know it by Friday.
- rats == ignored:
    ENDBAR: You let them be. They will take that as an invitation. They take most things as an invitation.
}
ENDBAR: I would be obliged if you would put this over for me. My arms are not what they were, and the tide is low.
* [Lower the trap over the rail.]
    ~ trap_in = clock
    ~ d2_done += d2_trap
    He let the rope run through his hands. The trap went down past the weed and into the brown water and the rope went slack.
    ENDBAR: Tie it off. There. It will want till the light goes.
    ENDBAR: Whatever comes up, Doorman, it came up on your rope.
* ["Do it yourself."]
    ~ trap_in = -1
    ENDBAR: As you like.
    He didn't move to do it. He stood there with the trap at his feet and looked at the mud, and when the doorman looked back from the highway it was still there on the planks.
- -> strip


// Dusk: the trap comes up. Crabs, three, one of them a keeper; and a hotel key on a brass fob.
=== haul ===
~ here = street
~ pass(6)
~ d2_done += d2_hauled
The tide had come in under the wharf while he was gone. The old man wasn't at the rail. The rope was tied where he'd tied it, wet and tight.
He hauled. It came up heavy, streaming, with three crabs in it, all clinging to the fish head. Two were small and one was a keeper.
In the corner of the trap, caught in the wire, there was a key on a brass fob shaped like a shield. SOVEREIGN HOTEL. 7. #prop: key_seven
FATHER: Seven's the one that's empty since March.
* [Keep the key.]
    ~ knows += key_seven
    He worked it out of the wire and put it in his pocket. It was colder than the water it came out of.
* [Leave it in the trap for the old man.]
    ~ key_left = true
    He left it hanging in the wire, and the crabs, and tied the trap off on the planks where the old man would find it.
- -> strip


// The Lesso by day: the woman on days at the till. The kid comes on at four.
=== esso_day ===
~ here = esso
~ pass(10)
# amb: esso
Under the canopy by day the white light was still on. A woman in a Lesso vest was on the till inside, doing a word search with a highlighter. She'd found PENNY, ALMANAC and SOVEREIGN, and was going over the grid a line at a time for EMPIRE.
* {d2_done !? d2_ate} [Something to eat.]
    ~ d2_done += d2_ate
    ~ ate = 1
    ~ cash -= 7
    He got a breakfast sandwich out of the warmer, seven dollars, that had been in there since breakfast. It was fine.
* {clock >= 960} [The kid's coming on shift.]
    ~ d2_done += d2_esso
    The kid in the toque came across the apron with a backpack on one shoulder and sat down on the ice freezer before he'd even gone in. #portrait: essokid
    { knows ? esso_sky:
        ESSOKID: It wasn't there last night. The light. First night in eleven it wasn't there.
        ESSOKID: The night you started, man. I'm not saying anything. I'm just saying.
    - else:
        ESSOKID: Oh hey. You're the doorman at the Sov. My cousin says you're like, huge. You're not that huge.
        ESSOKID: That's a compliment, by the way.
    }
- -> strip


// The big man's daughter, Kayla, come for his work truck, which has sat at the edge of the gravel
// since Wednesday with the dome light on. Whatever the doorman did on Wednesday, she's heard about it.
=== kayla_truck ===
~ here = lot
~ pass(12)
~ d2_done += d2_kayla
The big man's daughter was in the cab of his work truck with the door open and one boot on the gravel, turning the key. Click. Click. The dome light was on, a dead yellow, and had been since Wednesday. #portrait: driver
She saw him and stopped turning it.
{
- fam ? dad_ejected:
    DRIVER: Oh, perfect. You put him out, and now his truck won't go either. Banner week for the Moffats.
- promise_kept >= 1:
    DRIVER: You told me he wasn't there. He told me you told me. He thinks you're a good guy for it.
    DRIVER: Don't be a good guy for him, okay? Be a prick. It's easier on everybody.
- fam ? dad_went:
    DRIVER: You're the door guy. He went, in the end. Sat in the hallway at the hospital till four with his cap in his hands. She's okay. She's furious, so she's okay.
- else:
    DRIVER: You're the door guy. He leaves the dome light on so he can find his smokes, and then he forgets, every single time. Thirty years.
}
She pulled the visor down. The school photo was her: grade eight, braces, a perm somebody should have stopped.
DRIVER: Twenty-four in March. He's never changed it.
She took the mickey out of the door pocket, held it up to see the level, and put it in her purse.
* [Get cables off the beer store kid and boost it.]
    ~ kayla_thu = 1
    ~ pass(20)
    The kid on the beer store's till had a lip ring and a Civic with cables in the trunk, still in the package. They hooked it up in the rain. It caught on the second go and she gave it far too much gas, and a cloud of black came out the back over both of them.
    DRIVER: He's going to ask who jumped it. I'm going to tell him. He'll want to buy you a beer.
    DRIVER: Don't let him.
* ["Is he sober yet?"]
    ~ kayla_thu = 2
    She laughed, not nicely.
    DRIVER: He's sober every morning at six. He's been sober every morning at six since I was born. It's the afternoons.
    She got her phone out and called a tow off a fridge magnet in the ashtray. A hundred and forty. She said yes like she'd said it before.
* [Leave her to it.]
    ~ kayla_thu = -1
    He went back across the lot. Behind him, all the way to the highway, the key going click, and click.
- -> strip


// Table 28 by day. They've been in since two, and they've read the paper, out loud, to each other.
=== t28_day ===
~ here = t28
~ pass(5)
# amb: room_quiet
The Sov at three in the afternoon was a different room: the lights all on, the carpet showing every stain, a vacuum cleaner standing by the pool table with its cord wound round it. Table 28 had the Shoreline spread across both tables.
TEAM_JACKET: Here he is! The man himself! Big fella, you're not in it. Nobody's in it on a Wednesday!
{
- last_word("t28") != "":
    TABLE28: “{last_word("t28")}”
}
{ paper_read ? pp_obit:
    SCRATCH: Irene Pelletier. Eighty-nine for Irene. I had her at eighty-five, in the pool.
}
{ paper_read ? pp_ads:
    GLASSES: Page nine! WANTED, doorman! He's still in the classifieds, boys. Gary's shopping around!
    TEAM_JACKET: Gary's been shopping around since 1994. Ask his wife.
}
GLASSES: You'll have one with us. You'll have one. He's having one.
* [Have one. Sit down.]
    ~ d2_done += d2_t28
    ~ drinks++
    ~ rep(rep_t28, 1)
    ~ pass(40)
    He sat. A Kokanee came, and then the one in the team jacket told him about the time a man rode a horse into the Sov in 1977, and the horse was barred, and the man wasn't.
    HEARING_AID: Horse?
    TEAM_JACKET: He's still barred, the horse!
    { cardigan_go != 0:
        The one in the cardigan caught his eye once, across the table, and looked back at his rye.
    }
* ["I'm off tonight. Another time."]
    ~ rep(rep_t28, -1)
    TABLE28: Boo! Off! He's off!
    TEAM_JACKET: Friday, then. Friday you're ours.
- -> strip


// His room in the afternoon. Lorraine in six comes to the door for a light.
=== twelve_day ===
~ here = upstairs
~ pass(4)
He went up the two flights. In twelve the radiator ticked. The light from the window lay across the bed.
{ d2_done !? d2_lorraine:
    -> lorraine
}
-> twelve_rest

= lorraine
~ d2_done += d2_lorraine
Somebody knocked twice, lightly, with a ring on.
A woman in a satin robe the colour of a bruise, with her hair up in a clip and a cigarette between two fingers, unlit.
LORRAINE: You've got a light, I bet. You look like a man with a light.
LORRAINE: I'm Lorraine. Six. Terry's told you about six. Terry tells everybody about six.
She looked past him at the room, at the hole in the wall with the face drawn round it.
LORRAINE: The last one did that. Your predecessor. He paid for it, too, in the end.
LORRAINE: Staff rate's half, for the record. That's not an offer, it's information.
* [Light her cigarette.]
    ~ lorraine_how = 1
    He lit it. She held his wrist while he did, a second longer than the lighter needed.
    LORRAINE: Thank you, Twelve.
    She went back along the hall with the smoke going up over her head, and six's door shut, and the radio came up.
* ["Maybe Friday."]
    ~ lorraine_how = 2
    She laughed, once, through her nose.
    LORRAINE: Everybody's maybe Friday. Friday's a busy night for maybe.
    She took the cigarette back out of her mouth and went down the hall to ask eleven.
* [Shut the door.]
    ~ lorraine_how = -1
    He shut it. Her slippers went back along the hall. Six's door. The radio.
    FATHER: You don't shit where you eat. That's not morals, that's plumbing.
- -> twelve_rest

= twelve_rest
* {clock < SUNSET - 60} [Sleep till the light goes.]
    ~ d2_done += d2_slept
    ~ pass(SUNSET - 20 - clock)
    He lay on top of the blanket with his boots on. When he woke the window had gone blue.
    -> strip
+ [Go back out.]
    -> strip


// ------------------------------------------------------------------ the sign comes on

// 4:48. The neon on the roof comes on a letter at a time, from the S, and the second E doesn't. On
// day 11 the N goes, and the big nights take a letter each until the roof says OVER (the pace doc).
=== the_sign ===
~ here = seawall
{ clock < SUNSET:
    ~ pass(SUNSET - clock)
}
# amb: seawall
He sat on the seawall across the highway with the water behind him. The Sov's windows were lit and the lot was filling with pickups, one at a time.
At twelve minutes to five the sign on the roof came on. It buzzed. The S lit, and then the O, red, and then the rest of them in a row, ticking, one after another.
* [Count the letters.]
    ~ d2_done += d2_sign
    S, O, V, E, R. The next E stayed dark. I, G, N.
    Eight. He counted again and got eight again.
    WRONGMAN: In the story the sign was the first thing you saw from the ferry. It had all its letters then. Or it didn't. The drunk said it was a different sign.
* [Watch the lot fill instead.]
    ~ d2_done += d2_lot
    A Ford with a ladder rack. A blue Ranger with one grey door. A minivan with a hockey bag tied on the roof, and the man who got out of it kissed the woman driving and walked in like he was late for work. Behind him the sign buzzed.
- -> evening


// ------------------------------------------------------------------ the evening

=== evening ===
~ here = upstairs
~ pass(30)
He ate what he had, in twelve, sitting on the bed. Below the floor the Sov was filling up: the jukebox, a laugh going round table 28, the bell for a round.
Through the other wall, eleven were dealing cards.
* [Knock on eleven.]
    -> crib
* [An early night. Friday's everybody.]
    ~ d2_done += d2_early
    He was asleep by nine. Under him the Sov went on till two without him.
    -> thursday_close

// The mill crew in eleven, three of them on the contract, and the hi-vis man from Wednesday among them
// if he came back from the door.
= crib
~ d2_done += d2_crib
~ pass(90)
Three men from the mill in their socks round a crib board on a suitcase, with a two-four on the floor and the window open for the smoke.
{ arrivals ? hivis_done:
    HI-VIS: How's she goin'. It's the door. Sit down, door. You're not the door in here.
- else:
    The biggest of them looked up from his cards.
    HI-VIS: How's she goin'. You're the new door. Sit down. You're not the door in here.
}
{ arrivals ? hivis_out:
    HI-VIS: You put me out last night. I'm not mad. I'm a little mad.
}
They dealt him in. Fifteen two, fifteen four, and a pair is six. They played for a dollar a game and talked about the mill without saying the word closing.
HI-VIS: Six weeks on, one off. Used to be I'd go home for the one.
The one with the moustache said the mill was going because of Ottawa. He said that about his knees, too, and his marriage. Fifteen two.
* [Play to win.]
    ~ crib_won = 6
    ~ cash += 6
    ~ hangover = 1
    He won three games and they stopped liking him for it, and then started again.
* [Lose a few.]
    ~ crib_won = -4
    ~ cash -= 4
    ~ hangover = 1
    He lost four dollars, slowly, and they were glad to have him.
* [One beer and go.]
    ~ crib_won = 0
    He had the one and went, at ten. Through the wall he heard them count the next hand.
- -> thursday_close

=== thursday_close ===
NARRATOR: I've told the Thursday shorter than it was. On the island a Thursday is a long day, and it was the last slow one. #pause
{ knows ? key_seven:
    NARRATOR: I kept the key in my pocket the whole month. I'd put my hand on it at the door, when somebody's card was wrong.
}
{ d2_done ? d2_slept && d2_done !? d2_trap && d2_done !? d2_t28:
    NARRATOR: I slept through most of it. I've thought since that I should have been out there in what light there was. There weren't many more days like that.
}
-> friday
