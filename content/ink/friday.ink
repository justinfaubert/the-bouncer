// Day 3, Friday: the first real shift. The whole bar.
//
// What it's for (the pace and length doc; bible/11_SKELETON.md, The waves): the door stops being a
// set of conversations and becomes the job. A line in the rain behind the glass, most of them a quick
// read, one or two a story; every slow read costs the line two more. Jim on the bar with her, counting
// out loud. The cheque, short. Prime rib night, sliced thin. The Preacher with his tracts.
//
// Wednesday is still in it: the big man, GOOD SHOES and his wallet, Lorraine's "maybe Friday", the key
// from the trap.
//
// Claude's draft, PROPOSED. Every BARTENDER and JIM line is Hutch's to rewrite.

VAR cheque_how = 0          // the bookkeeper's envelope: 1 signed for it, 2 put his finger on the twenty-four, 3 counted it in front of her
VAR rib_how = 0             // his prime rib: 1 ate it, 2 held a slice up to the light, 3 took it back to the cook
VAR in_line = 0                // people in the rain behind the glass, during the wave
VAR let_wrong = 0           // the ones he let through who shouldn't have come in
VAR lost_line = 0           // the ones who gave up on the line and went down the road to the Legion
LIST wave = w_mill, w_girl, w_suit, w_hat, w_legion, w_shoes, w_couple
VAR wave_in = ()            // who from the wave he let in
VAR suit_how = 0            // the man in the wedding suit: 1 let him in, 2 asked whose wedding, -1 turned him away
VAR preacher_how = 0        // the Preacher's tract: 1 took it, 2 read it, -1 "Not in here"
VAR hat_how = 0             // the red cap with 51 on it: 1 let him in wearing it, 2 made him take it off, -1 turned him away
VAR seven_how = 0           // room seven, after close: 1 he went in, 2 he stood at the door and didn't


=== friday ===
~ new_day(3)
~ clock = 735
~ here = upstairs
FRIDAY #class: day
{ hangover > 0:
    Eleven's crib game was in his head, in the back, keeping score.
}
Rain on the window again. Down in the lot a delivery truck was backing up to the kitchen door, beeping.
{ knows ? key_seven:
    The key from the trap was on the sill where he'd left it. SOVEREIGN HOTEL. 7.
}
+ [Go down at four.]
    -> cheque


// ------------------------------------------------------------------ the cheque

// The bookkeeper brings the cheques to the bar on Fridays at four. His is for the test shift, less the
// shirt (bible/11_SKELETON.md: she'll write it short anyway; the small print took twenty-four).
=== cheque ===
~ here = bar
~ clock = 960
# amb: room_quiet
The bookkeeper was at the end of the bar with her coat on and a shoebox of envelopes. She had a pen on a string round her neck. #portrait: bookkeeper
BOOKKEEPER: Twelve.
She walked one finger along the envelopes and stopped on his. On the window it said 96.00, crossed out, and 72.00 under it.
{ pay_how == 3:
    He'd read the form. He knew where the twenty-four had gone before she said anything.
}
{ shirt == 2:
    He'd told Gary he had his own shirt. The twenty-four was gone anyway.
}
+ [Sign the book and take it.]
    ~ cheque_how = 1
    ~ cash += 72
    He signed. She blew on it.
    BOOKKEEPER: Good boy.
+ ["Eleven-dollar shirt."]
    ~ cheque_how = 2
    ~ cash += 72
    She looked at him over her glasses. Forty-one years at the bank, and a column that didn't add.
    BOOKKEEPER: Uniform and laundering. It's on the form you signed.
    { pay_how == 3:
        BOOKKEEPER: You read it, too. I watched you read it.
    }
    { shirt == 2:
        BOOKKEEPER: Whether you wear it is your business.
    }
    She held the pen out till he took it.
+ [Open it and count it in front of her.]
    ~ cheque_how = 3
    ~ cash += 72
    Seventy-two, the stub said. Rent for twelve was on there too, taken off first, and the line under it said BALANCE OWING.
    He looked up. She'd already moved on to the next envelope.
    FATHER: First one's always short. It's so you come back for the second one.
- -> rib


// ------------------------------------------------------------------ prime rib night

// The cooks are slicing it thin and taking the rest home (Hutch's story 4). Tonight it doesn't run out.
=== rib ===
~ here = kitchen
~ pass(40)
The kitchen door was propped with a pail. PRIME RIB FRIDAY on the whiteboard, $24.95, and somebody had drawn a cow under it with a happy face.
COOK: Staff plate. Eat it here, I'm not running it out. #portrait: cook
The young one did the slicing. Long strokes, a lot of them. The plate he put down had four slices fanned out over the mash to cover it.
+ [Eat.]
    ~ rib_how = 1
    ~ ate = 1
    He ate it standing up. It was good. There wasn't much of it.
+ [Hold a slice up to the light.]
    ~ rib_how = 2
    ~ knows += prime_thin
    He held one up on the fork. He could see the cook through it.
    The young one stopped slicing.
    COOK: What, you want a menu?
    FATHER: You don't say it. You've seen it. That's enough for a Friday.
+ [Take it back to the board. "Is this a staff cut, or is this the cut?"]
    ~ rib_how = 3
    ~ knows += prime_thin
    ~ rep(rep_cook, -2)
    The cook didn't look up.
    COOK: It's the cut. You're security, not the Sysco guy.
    The young one went to the walk-in and stayed there.
- { rats == war:
    Under the fryer smell there was another one, sweet and wrong, coming up the stairs from the keg room.
    COOK: Don't. I know.
  }
-> jim


// ------------------------------------------------------------------ Jim

// Jim's on the bar with her on Fridays. Drummer in cover bands. Meek, reliable, very particular.
=== jim ===
~ here = bar
~ pass(30)
There was a second one behind the bar tonight: a thin guy in a ball cap, turning every bottle on the back shelf so the labels faced out. When he'd done a shelf he started it again from the left. #portrait: jim
BARTENDER: That's Jim. Fridays. Don't talk to him while he's counting.
JIM: Hi. Sorry. Hi. Forty, forty-one. Sorry.
+ ["What are you counting?"]
    ~ knows += jim_count
    JIM: The Fireball. We had forty-three Tuesday. That's not a problem, that's just a number.
    He wrote 41 on his hand in pen, under some other numbers.
+ [Leave him to it.]
    He left him to it. Jim nodded at the bottles, thanking them, or counting.
- -> preacher


// ------------------------------------------------------------------ the Preacher

// A lay preacher from the church on the highway. Fridays, with tracts; buys the drunks coffee. He sat
// in the sixth chair at table 28 once, before he quit. (bible/11_SKELETON.md, the six eccentrics.)
=== preacher ===
~ here = door
~ clock = 1130
# amb: room_quiet
At ten to seven a man in a windbreaker came in out of the rain with a plastic grocery bag held against his chest to keep it dry. Fifty, shaved so close he shone. #portrait: preacher
PREACHER: Evening. I don't drink. I'm here for the ones who do.
He opened the bag a few inches so the doorman could see: a stack of folded paper, held with an elastic.
On top, in a font somebody had picked carefully: APOCALYPSE MEANS UNCOVERING.
+ [Take one.]
    ~ preacher_how = 1
    He took one. The Preacher put a hand on his arm, light.
    PREACHER: You don't have to read it. Most don't. It's the taking.
+ [Read the top one where he stands.]
    ~ preacher_how = 2
    ~ pass(2)
    It was about a word in Greek that meant lifting a lid. Somebody had underlined lid in ballpoint, on every copy, by hand. At the bottom it said the lid comes off whether you're ready or not, and that you could get ready, and gave the church's hours.
    PREACHER: That's the one. I did three hundred of those on the church's machine before it jammed. Pastor Dave thinks I'm at the Safeway.
    WRONGMAN: The drunk said a man like this came in that night. Or the night before. He said the man knew.
+ ["Not in here."]
    ~ preacher_how = -1
    PREACHER: Fair enough. Gary lets me. You can ask Gary.
    He went in anyway, to the end by the jukebox, and bought the one in the cardigan a coffee he hadn't asked for.
- He went down the room shaking hands. At table 28 he stood behind the sixth chair, the empty one, with his hands on it, and didn't sit.
{ cardigan_go != 0:
    CARDIGAN: Sit down or don't, Ray.
}
-> door_early


// ------------------------------------------------------------------ the door before the wave

=== door_early ===
~ here = door
~ clock = 1200
# amb: room_busy
By eight the room was louder than Wednesday's loudest.
{ d2_done ? d2_lot:
    He knew half the trucks in the lot from the seawall. The blue Ranger with the grey door was in the handicapped spot again.
} The hockey was on both TVs. Jim had a cloth over his shoulder and was saying numbers under his breath.
-> big_man_friday


// The big man from Wednesday, sober, at the door. What he does depends on what the doorman did.
=== big_man_friday ===
{
- promise_kept == -1:
    The big man's truck went by on the highway, slowly, and slowed more at the lot, and didn't turn in.
    FATHER: He'll come in again. Not this month.
- fam ? dad_ejected:
    The big man was outside the glass in a clean jacket, not coming in. He held up a hand. #portrait: bigman
    BIGMAN: I'm not here. I'm telling you I'm not here, so it's true this time.
    He went back to the truck. The daughter was in the driver's seat with both hands on the wheel, facing the highway.
    { kayla_thu == 1:
        She lifted two fingers off the wheel at the doorman, and put them back.
    }
- promise_kept >= 1 || (fam ? dad_went && not took_keys):
    The big man came in and stopped at the stool and put a folded twenty on the corner of it. #portrait: bigman
    BIGMAN: For Wednesday. I'll have the one and go.
    { kayla_thu == 1:
        BIGMAN: Kayla says you jumped the truck. I'm not allowed to buy you a beer. She was very clear.
    }
    { kayla_thu == 2:
        BIGMAN: Kayla says you asked was I sober. I am. It's eight o'clock.
    }
    -> twenty
- kayla_thu == -1:
    The big man didn't come in. Where his work truck had been at the edge of the gravel there was an oil stain the shape of Saskatchewan, and the tow's tire marks.
- else:
    The big man didn't come in. The school photo was still in the visor of the truck at the edge of the gravel, and the parking ticket under the wiper had gone soft in the rain.
}
-> wave_start

= twenty
* [Take it.]
    ~ cash += 20
    He put it in his shirt.
    FATHER: You got paid twice today.
* [Push it back. "Have your one."]
    ~ bigman_ease++
    The big man put it back in his wallet, and then took his cap off and put it back on.
    BIGMAN: Okay. Okay.
- -> wave_start


// ------------------------------------------------------------------ the wave

// The hockey ends at twenty to ten and the room empties out onto the deck to smoke, and then the
// Legion's crowd comes up the highway in the rain. A line behind the glass. Every slow read lets two
// more in behind it (PROPOSED since 27 September: slow checking builds a line, fast lets mistakes in).
// A slow read lets the line grow behind it.
=== function slow()
~ in_line += 2
~ pass(3)

=== function fast()
{ in_line > 0:
    ~ in_line--
}
~ pass(1)


=== wave_start ===
~ clock = 1300
~ in_line = 6
The game ended on a power play. The room groaned all together, and then a car horn went outside, and another.
Through the front glass he could see them coming across the lot under umbrellas and jackets pulled up over their heads.
JIM: Here they come. Okay. Here they come.
-> the_line

=== the_line ===
~ here = door
{
- in_line >= 10:
    {Num(in_line)} behind the glass. Somebody slapped it, flat-handed, twice.
    ~ lost_line += 2
    ~ in_line -= 2
    ~ rep(rep_owner, -1)
    Two at the back gave up and went off down the shoulder toward the Legion with their hoods up.
- in_line >= 7:
    {Num(in_line)} behind the glass, steaming it up. Somebody wrote a word on it backwards with a finger.
- in_line > 0:
    {Num(in_line)} behind the glass.
}
{
- wave !? w_mill:
    -> mill
- wave !? w_girl:
    -> girl
- wave !? w_suit:
    -> suit
- wave !? w_hat:
    -> hat
- wave !? w_shoes && ((wallet_how == 3 && wallet_back == 0) || wallet_back == 3):
    -> shoes
- wave !? w_legion:
    -> legion
- wave !? w_couple:
    -> couple
- else:
    -> wave_end
}

// Two from the mill, regulars, in their work jackets. A quick read.
= mill
~ wave += w_mill
Two mill jackets, wet through, already arguing about the power play.
+ ["In you go." #door: in]
    ~ fast()
    ~ wave_in += w_mill
    ~ count_in += 2
    JIM: Fifty-one. Fifty-two.
+ [Card them anyway. #door: terms]
    ~ slow()
    ~ wave_in += w_mill
    ~ count_in += 2
    They looked at each other. They were sixty if they were a day. They got their wallets out, slowly, and held them up open.
    MILL: You want a urine sample too, bud?
- -> the_line


// The girl with her sister's card. A fast read lets her in.
= girl
~ wave += w_girl
A girl in a white puffer coat, hair straightened, holding a card out before he'd asked for it.
+ ["Thanks." #door: in]
    ~ fast()
    ~ wave_in += w_girl
    ~ count_in++
    ~ let_wrong++
    She went in past him smelling of vanilla and the rain.
    -> the_line
+ [Look at the card. #check: manual 11]
    ~ slow()
    { passed:
        ~ knows += girl_card
        Twenty-two, the card said. The girl on it had the same hair but her ears weren't pierced, and this one had three holes in the left.
        MANUAL: Compare features that do not change: ear shape, the hairline, the space between the eyes. Hair, makeup and piercings change.
    - else:
        Twenty-two, the card said. The photo looked like her, same hair, same chin, same expression of somebody at the DMV.
    }
    -> girl_choose
+ ["What's your birthday?" #check: father:cha 9]
    ~ slow()
    { passed:
        ~ knows += girl_card
        She said it right. Then she said it again, faster, and got the year wrong by one and heard herself do it.
        FATHER: The Fraser boys' cousin had the day cold and gave me nineteen-ninety for a ninety-one card. I let her in anyway. She bought me a rye.
    - else:
        She said it right, the day and the year, like she'd said it in the car.
    }
    -> girl_choose

= girl_choose
+ ["In you go." #door: in]
    ~ wave_in += w_girl
    ~ count_in++
    ~ let_wrong++
+ {knows ? girl_card} ["Tell your sister she's prettier than her picture." #door: out]
    ~ rep(rep_kids, 1)
    She took the card back. She went red from the neck up, and then she laughed. He hadn't expected that.
    GIRL: She's going to kill me.
+ ["Not tonight." #door: out]
    ~ rep(rep_kids, -1)
    GIRL: It's literally me. Okay. Okay, wow.
- -> the_line


// The man in a wedding suit, alone. First of three Fridays running (the returning deck).
= suit
~ wave += w_suit
A man in a grey suit with a white rose still in the buttonhole, gone brown at the edges. No coat. No umbrella. Sober, and wet to the skin.
+ ["In." #door: in]
    ~ fast()
    ~ suit_how = 1
    ~ wave_in += w_suit
    ~ count_in++
    He nodded and went in and stood at the bar, at the end, and ordered two of the same.
+ ["Whose wedding?"]
    ~ slow()
    ~ suit_how = 2
    ~ wave_in += w_suit
    ~ count_in++
    He thought about it.
    SUIT: Mine. Two o'clock. Sorry. Am I holding you up?
    He went in and stood at the bar, at the end, and ordered two of the same.
+ ["Not dressed like that." #door: out]
    ~ fast()
    ~ suit_how = -1
    He looked down at himself. Then he went and stood on the far side of the lot, under the sign, and he was still there when the doorman looked again.
- -> the_line


// A young guy in a red cap with 51 and a star on it. Table 28 have the best view of the door.
= hat
~ wave += w_hat
A young guy in a Carhartt and a red ball cap, gold stitching on the front: 51, and a star. He'd had it on backwards in the lot. At the glass he turned it round so the doorman could read it.
CAP51: Relax, bud. It's a bit. My sister married a Liberal. He bought me two drinks at Christmas to take it off.
Behind the doorman, through the front window, table 28 had seen it.
TEAM_JACKET: Fifty-one! Is that his age or his IQ!
HEARING_AID: Fifty-one? I'm seventy-eight!
+ ["In." #door: in]
    ~ fast()
    ~ hat_how = 1
    ~ wave_in += w_hat
    ~ count_in++
    He went in with it on, grinning, and table 28 booed him all the way to the bar, and one of them bought him a beer for having the balls.
+ ["The hat comes off, or you don't come in." #door: terms]
    ~ slow()
    ~ hat_how = 2
    ~ wave_in += w_hat
    ~ count_in++
    CAP51: Worth a shot.
    He folded it in half and put it in his back pocket, like a wallet, and went in with his hair flat in a ring.
+ ["Not tonight, pal." #door: out]
    ~ fast()
    ~ hat_how = -1
    CAP51: Seriously? It's a hat.
    TEAM_JACKET: Good man!
    GLASSES: That's politics! You can't put a man out for politics!
    TEAM_JACKET: It's a bar on a Friday. Everything's politics.
    The kid went down the shoulder toward the Legion, and turned the cap round backwards again, for the walk.
- -> the_line


// GOOD SHOES, for his wallet, if the doorman kept it on him on Wednesday.
= shoes
~ wave += w_shoes
GOOD SHOES was three back in the line, and he didn't wait to get to the front. #portrait: goodshoes
{ wallet_back == 3:
    GOODSHOES: You said tomorrow. That was yesterday.
- else:
    GOODSHOES: You've got something of mine.
}
{ wallet_cash > 0:
    FATHER: You know how much was in it. So does he.
}
+ [Hand it over.]
    ~ fast()
    ~ wallet_back = 1
    ~ wallet_how = 0
    He took it and opened it there at the door and counted it with his thumb.
    { wallet_cash > 0:
        GOODSHOES: Huh.
        He took out a business card, wrote the amount on the back of it, folded the wallet over it and put it away.
        GOODSHOES: I'll remember that.
    - else:
        GOODSHOES: All there. Huh. Okay. I owe you one, then.
    }
    He didn't come in. He wasn't allowed to, and he seemed to remember that.
+ ["Come back tomorrow. Day girl's got it."]
    ~ slow()
    ~ wallet_back = 3
    { wallet_how == 3:
        GOODSHOES: You've got it in your shirt. I can see it in your shirt.
    - else:
        GOODSHOES: That's what you said last time.
    }
    The line behind him laughed.
- -> the_line


// The one from the Legion who's had too many. Read him slowly or he gets in.
= legion
~ wave += w_legion
A man in a Legion windbreaker with the badge on it, holding the door frame. Seventies. Very polite.
LEGION: Good evening, young man. The other place has closed on me.
+ ["Go ahead." #door: in]
    ~ fast()
    ~ wave_in += w_legion
    ~ count_in++
    ~ let_wrong++
    He went in hand over hand along the wall.
    -> the_line
+ [Watch him let go of the frame. #check: father 9]
    ~ slow()
    { passed:
        He let go, and his hand found the frame again on its own.
        FATHER: Legion hands. Mine did that the last two years, and I let myself in every time. Get him a cab.
    - else:
        He let go and stood up fine, very straight, chin up, like a man on parade with a wet arse.
    }
    -> legion_choose
+ [Ask him his name. #check: wrongman 10]
    ~ slow()
    { passed:
        LEGION: Doug.
        Terry's napkin. Doug's at the Legion.
        WRONGMAN: In the story the old man at the door was somebody's father. The doorman's own, maybe. The drunk said he never found out.
    - else:
        LEGION: Douglas. Doug. Doug.
    }
    -> legion_choose

= legion_choose
+ ["Come on in, Doug." #door: in]
    ~ wave_in += w_legion
    ~ count_in++
    ~ let_wrong++
+ ["I'll call you a cab." #door: fetch]
    ~ rep(rep_t28, 1)
    He called it from the bar phone. Doug sat on the bench in the vestibule with his hands on his knees and told him about Cyprus, 1964. The cab came. He tipped the doorman two dollars and the cab driver nothing.
+ ["Not tonight, sir." #door: out]
    ~ rep(rep_t28, -1)
    LEGION: Quite right. Quite right.
    He went off along the shoulder in the rain, toward the Legion, which had closed on him, and past it.
    TEAM_JACKET: Was that Doug? You put Doug out? Doug was at Dieppe! Doug's father was at Dieppe!
- -> the_line


// A couple who are fighting before they get to the door.
= couple
~ wave += w_couple
A woman with her shoes in her hand and a man behind her still talking.
WOMAN: I am not going home with him. I'm telling you so you know.
+ ["Just you, then." #door: terms]
    ~ fast()
    ~ wave_in += w_couple
    ~ count_in++
    She went in. The man stood in the rain with his mouth open.
    MAN: That's my wife.
    FATHER: Your mother went into the Courtenay Elks without me once. I stood on the step and told the doorman she was my wife. He said he knew.
+ ["Both of you. Sort it out inside." #door: in]
    ~ fast()
    ~ wave_in += w_couple
    ~ count_in += 2
    ~ let_wrong++
+ ["Neither. Go home." #door: out]
    ~ fast()
    ~ rep(rep_owner, -1)
    WOMAN: Oh my God. Thanks a lot.
    They went off across the lot together, still at it, under the one umbrella.
- -> the_line


// ------------------------------------------------------------------ after the wave

=== wave_end ===
~ pass(10)
The glass was clear. Water ran down it. On the other side the lot was full and the rain came down on it, and on the far side of the lot, under the sign, nobody.
{ suit_how == -1:
    Except the man in the wedding suit. He was still there.
}
JIM: Okay. Okay. Hundred and four.
He held up the clicker the bartender gave him to count the bar with.
{ knows ? jim_count:
    There were more numbers on the back of his hand now, going up his wrist.
}
{
- let_wrong == 0:
    JIM: You?
    His own count was the same. Jim looked happy, and then embarrassed to be happy.
- let_wrong == 1:
    JIM: You? Okay. One off. That's fine. One's fine.
- else:
    JIM: You? Okay. That's {let_wrong} off. That's not fine.
}
{ lost_line > 0:
    JIM: We lost some to the Legion. That's okay. Gary counts the Legion, though. Gary counts the Legion's lot.
}
{ wave_in ? w_girl:
    -> girl_found
}
-> close_friday

// The girl with her sister's card, at the bar, doing a shot with somebody's brother.
= girl_found
The girl in the white puffer was at the bar with a shot in front of her and two guys from the mill crew on either side.
JIM: Um. She was in my sister's grade. My sister's in grade eleven.
MANUAL: The licensee is liable. The doorman is liable. The bartender is liable.
+ [Walk her out.]
    ~ rep(rep_staff, 1)
    ~ incident += inc_no_id
    She went without a word to the mill boys, who'd already turned back to the bar. At the door she zipped the puffer up to her chin and texted somebody with both thumbs, fast.
+ [Leave it. It's Friday.]
    ~ cocoon++
    ~ rep(rep_staff, -1)
    Jim turned the Fireball on the shelf so its label faced out, though it already did.
- -> close_friday


// ------------------------------------------------------------------ close

=== close_friday ===
~ here = floor
~ clock = 1560
# amb: room_quiet
At two the lights came up and the room was a room again: sticky, small, the carpet showing everything.
{
- preacher_how == 2:
    The Preacher's tracts were on every table, one each, and somebody had folded one into a hat and left it on the jukebox. He'd read it, so he knew what the hat said.
- preacher_how == 1:
    The tract was still in his back pocket, folded in four. He hadn't read it. The Preacher had watched him take it, and had nodded like a man getting a signature.
- preacher_how == -1:
    The Preacher's tracts were on every table anyway, one each. Gary let him.
}
{
- hat_how == 1:
    The red cap with the 51 on it was on the jukebox{preacher_how == 2:, next to the Preacher's tract folded into a hat}. Its owner had gone home without it.
- hat_how == 2:
    The kid in the Carhartt went out last, putting the cap on backwards on the step, and gave the doorman the finger, friendly, with the other hand.
}
{
- crib_won > 0:
    HI-VIS went by with his jacket over his arm and pointed at him. "Shark." He was still a little mad.
- crib_won < 0:
    HI-VIS went by and put four dollars on the stool. "Your crib money. I felt bad." Two of the four were Canadian Tire money.
}
{
- rib_how == 1:
    The cook came out through the kitchen door with his coat on and a garbage bag in one hand and a foil package in the other, and pushed the package at him.
    COOK: Take it. It's going in the garbage anyway.
    It was heavy and warm. There was a lot of it in there.
    { knows ? prime_thin:
        FATHER: The Legion cook did the same with the turkey every Remembrance Day. I ate it for a week and said nothing.
    }
- rib_how >= 2:
    The cook came out with his coat on and two foil packages under his arm, and went past the doorman with his eyes on the floor and out to his car.
    FATHER: Two. He had two.
}
{ lorraine_how == 2:
    -> lorraine_friday
}
-> after_close

= lorraine_friday
Lorraine was on the bottom stair in the hotel hall in a coat over the robe. #portrait: lorraine
LORRAINE: It's Friday.
* [Go up with her.]
    ~ lorraine_how = 3
    ~ cash -= 60
    He went up. She counted the money on the dresser before she took the clip out of her hair, and she was right about the rate.
    In the morning there was a mug of coffee on the floor by his side of the bed, and she was asleep with her back to him and one bare foot out of the blanket.
    -> friday_end
* ["Not tonight."]
    ~ lorraine_how = 4
    LORRAINE: That's what maybe means, Twelve. Don't feel bad.
    She went up ahead of him, one hand on the rail.
- -> after_close

= after_close
{ knows ? key_seven:
    -> seven
}
-> friday_end

// Room seven, empty since March. The key from the trap fits.
= seven
He went up past six and stopped at seven. The brass number had a screw missing and hung crooked.
* [Try the key.]
    ~ seven_how = 1
    It turned. Inside, the bed was made, tight, hospital corners. The radiator was warm. The window was open two inches and the rain came in and darkened the carpet under it.
    On the bedspread there was a record with no sleeve, black, no label in the middle. In the light from the hall it didn't shine.
    He didn't touch it. When he shut the door, from the hall, he heard the radiator knock three times, and then a needle set down on nothing.
    -> friday_end
* [Put the key back in his pocket.]
    ~ seven_how = 2
    He stood there till the light on the timer in the hall went off, and then he went up to twelve in the dark.
- -> friday_end


=== friday_end ===
NARRATOR: A hundred and four, Jim said, and I said a hundred and four, and one of us was wrong. #pause
{ let_wrong >= 2:
    NARRATOR: I let in people I shouldn't have that night. I couldn't pick most of them out of a lineup now. I could tell you what the glass smelled like.
}
{ seven_how == 1:
    NARRATOR: I asked Terry in the morning who'd had seven. He said nobody, since March. He said it twice, the second time a bit louder.
}
{ cheque_how == 3:
    NARRATOR: BALANCE OWING. After the first week I owed the Sov money. I owed it money at the end, too. Less.
}
{ key_left:
    NARRATOR: The old man never mentioned the key. By Saturday the trap was gone off the wharf, rope and all.
}
FRIDAY #class: end
-> END
