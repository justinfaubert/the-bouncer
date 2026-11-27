// The grounds round the Sov at night, on his own feet (godot/world/grounds.gd): round the back, the
// alley, the hotel's front door, across the highway to the seawall and down onto the beach, and
// down the shoulder to the Lesso. He's still out front as far as the night goes (here = lot): every
// minute out here is a minute nobody's on the stool, and door_away counts it (sim.ink).
//
// What's lying about out there is looked at the way things in the building are (things.yaml, its
// near: is how close he has to walk to find it). A few of them are more than a look: handling them
// takes an unlisted choice in at_front's options (deck.ink, #toy: <thing> look), which comes here.
//
// One thread runs through four of them, to be found in any order or not at all: a white cross on the
// shoulder that says DARLENE; the man fishing off the seawall with nothing on his hook, who was her
// husband; a licence in the kelp on the beach with her face on it, not expired; and the buzzers by
// the hotel's front door, where room seven's name has been scratched out with a key. Nothing here
// says what it means. It's the first question of the grounds, and a later night answers it.
//
// Claude's drafts, all of it.

LIST out_clue = cl_cross, cl_wife, cl_flowers, cl_card, cl_seven, cl_paper, cl_rat_front, cl_rat_back, cl_caps, cl_phone, cl_trail, cl_freezer
VAR out_found = ()
VAR card_kept = 0           // her licence: 1 in his pocket, -1 put back in the kelp, 2 given to Merle
VAR caps_how = 0            // the rats' spiral of bottle caps: 1 left it, 2 took the brass one, 3 kicked it apart
VAR esso_rang = false       // the payphone at the Lesso rang as he came down the shoulder (the engine sets it)
VAR esso_answered = 0       // 1 he picked it up, -1 he let it ring
VAR esso_price = 0          // how many times he's read the Lesso's price sign tonight: it goes up
VAR smokes = 0              // packs bought at the Lesso's night window
VAR scratched = 0           // scratch tickets bought there
VAR fire_how = 0            // the fire on the beach: 1 warmed his hands, 2 kicked sand over it


// ------------------------------------------------------------------ Merle, on the seawall

=== out_merle ===
~ pass(1)
{ out_merle == 1:
    A man was fishing off the seawall in the rain, in a green rain jacket with the hood down and the rain in his hair. A kerosene lantern on the wall beside him. A white bucket at his feet with nothing in it. The line went out from the tip of a long rod into the dark over the water, and he didn't look round.
    MERLE: You're the new one. At the Sov.
    MERLE: Merle.
- else:
    {shuffle:
    - Merle was still at the wall. The lantern had burned down a finger.
    - Merle hadn't moved. The rod tip nodded with the swell and he let it.
    - Merle was pouring coffee out of a thermos lid into the thermos lid. He didn't offer any.
    }
}
- (talk)
* ["What are you fishing for?"]
    MERLE: Nothing.
    He reeled in, a long way, and held the end of the line up in the lantern light. A hook, bright, nothing on it.
    MERLE: Forty years I fished this wall with bait. In March I stopped putting it on. Now I get to stand here and nobody asks me what I'm doing.
    He cast it out again, overhand, a long way.
    MERLE: Present company.
    -> talk
* {out_found ? cl_cross} ["There's a cross up the shoulder. Darlene."]
    ~ out_found += cl_wife
    MERLE: My wife.
    He watched the rod tip.
    MERLE: She went in off this wall in March. The fourteenth. About there. They said she'd had eleven drinks at the Sov. I said who counts.
    MERLE: You do. That's your job now. Counting.
    WRONGMAN: In the story the doorman let a woman walk out alone at last call. The drunk said she lived across the road. Then he said there was nothing across the road but the water.
    -> talk
* {out_found ? cl_wife} ["Do you put the flowers on it?"]
    ~ out_found += cl_flowers
    MERLE: I've never put a flower anywhere in my life.
    MERLE: Somebody does. New ones every week, Tuesdays. Plastic, but new. I've never seen who.
    MERLE: I've stood here every night since March and I've never seen who.
    -> talk
* {card_kept == 1} ["I found her licence. Down on the beach, in the kelp."]
    -> merle_card
* {out_found ? cl_seven && out_found ? cl_wife} ["Did she live at the hotel? Room seven?"]
    MERLE: We had the house up on Fourth, till we didn't. Then she had seven, and I had the truck.
    MERLE: Gary's kept it empty since. Paid up to Christmas, he says, and won't say who by. Her name was on the buzzer till somebody took a key to it.
    He turned the reel's handle once, for nothing.
    MERLE: Wasn't me.
    -> talk
+ [Leave him to it.]
    { out_merle == 1:
        MERLE: Mind the road going back. They don't slow down for the Sov. Never have.
    }
    -> at_front.f_opts

= merle_card
He held it out. Merle looked at it a long time without taking it, and then he took it, and turned it to the lantern.
MERLE: That's her.
MERLE: She let hers lapse. She wasn't driving. She'd have told you she wasn't allowed.
He turned it over, and over again, and held it closer to the glass of the lantern.
MERLE: Issued the ninth of June.
MERLE: They had her out of the water on the sixteenth of March.
FIGHTER: His hands are steady. He's the only steady thing on this wall.
* [Let him keep it.]
    ~ card_kept = 2
    He put it in the breast pocket of the rain jacket and did the snap up over it.
    MERLE: Thank you.
    He went back to watching the rod tip, and the doorman stood there till it was clear that was all.
* [Take it back.]
    He held out his hand. Merle looked at it, and gave the licence back.
    MERLE: Put it in your lost-and-found. That's where she'd look.
    MANUAL: Identification found on or near the premises is retained in the lost-and-found for thirty days, then destroyed.
- -> at_front.f_opts


// ------------------------------------------------------------------ the cross on the shoulder

=== out_cross ===
~ pass(1)
~ out_found += cl_cross
A white cross zip-tied to a guardrail post on the shoulder, leaning toward the road. DARLENE on the crosspiece in marker gone grey. Under it a photograph in a sandwich bag, bleached by the sun to a white square with a smile in it. Six plastic roses wired to the post, and they were new: the price sticker was still on one. A blue scarf, tied on.
FATHER: There's one of these every couple of miles up island. Your mother made me stop at all of them once, Nanaimo to Port Hardy. We got there in the dark and the motel had given our room away.
- (look)
* [Straighten it.]
    ~ pass(1)
    He pushed the cross upright against the post. The zip tie let it lean back the moment he let go.
    -> look
* [Read the price sticker.]
    $3.99, DOLLAR GIANT, COURTENAY. Somebody had driven forty minutes for plastic roses and not taken the sticker off.
    -> look
+ [Leave it.]
    -> at_front.f_opts


// ------------------------------------------------------------------ the licence in the kelp

=== out_kelp ===
~ pass(2)
~ out_found += cl_card
In the kelp line, face up in the wet, a driver's licence. He crouched and picked it up. The laminate was clean, no sand in it. The hologram still caught what light there was: the crown, the mountains, the crown.
PAQUETTE, DARLENE ROSE. Born in sixty-one. The address was the Sovereign Hotel, room seven. It didn't expire for years.
In the photograph she was trying not to smile at the camera, and losing, and she had a blue scarf on.
{ out_found ? cl_cross:
    WRONGMAN: The drunk said a woman came in every night for a year after she was dead. Then he said it was her sister. Then he said she didn't have one.
- else:
    KID: someone's gonna want that
}
MANUAL: Identification found on or near the premises is retained in the lost-and-found for thirty days, then destroyed.
* [Keep it.]
    ~ card_kept = 1
    He put it in the inside pocket of his jacket, on the left, against his chest, where it was a flat cold thing for a while and then wasn't.
* [Put it back where it was.]
    ~ card_kept = -1
    He put it back in the kelp, face up, where he'd found it. The next tide would have it, or whoever had dropped it would.
- -> at_front.f_opts


// ------------------------------------------------------------------ the buzzers by the hotel's own door

=== out_buzzers ===
~ pass(1)
{ out_buzzers == 1:
    The buzzers by the hotel's front door: a brass plate with twelve buttons and twelve names in little windows. Most were typed, on a typewriter, a long time ago. 1 PRATT. 3 L. HOWE. 4 the window empty. 9 B & B SINCLAIR. Twelve was a strip of masking tape with DOORMAN on it in Gary's capitals.
    Seven's window had been scratched with a key until there was nothing in it but brass.
    ~ out_found += cl_seven
- else:
    The buzzers. DOORMAN on twelve. Seven scratched to the brass.
}
{ card_kept != 0 && out_buzzers == 1:
    Room seven, the licence said.
}
- (press)
* [Press seven.]
    ~ pass(1)
    He pressed it. Up in the building a buzzer went, a long way off. Nothing. Then the grille by his face clicked, and he heard a room: rain on a window, and a record turning past the end of its side, the needle going round in the run-out groove, round, round.
    Nobody said anything. The grille clicked off.
    FATHER: Never press a buzzer at night. That's how you meet people.
    -> press
* [Press twelve.]
    He pressed his own. Nothing. He wasn't in.
    -> press
+ [Leave them.]
    -> at_front.f_opts


// ------------------------------------------------------------------ round the back: the caps by the rats' vent

=== out_caps ===
~ pass(1)
~ out_found += cl_caps
In front of the vent under the kitchen, on a patch of gravel smoothed flat, somebody had laid bottle caps out in a spiral the size of a dinner plate, every one face up. Kokanee, Lucky, Pilsner, Kokanee, Lucky. Round and in, twenty-six of them. In the middle a brass one he didn't know, with a crown stamped on it.
The gravel round the spiral was printed all over with feet the size of his thumbnail.
{ knows ? keg_hole:
    FIGHTER: That vent's the other end of the hole in the keg room. They go in here and come out under table 28.
}
* [Leave it be.]
    ~ caps_how = 1
    ~ rat_favour += 1
    He left it. When he looked back from the corner of the building something was sitting in the middle of it, where the brass cap was. Then it wasn't.
* [Take the brass one from the middle.]
    ~ caps_how = 2
    He picked the brass cap out of the middle. It was warm. The spiral without it was just caps.
    WRONGMAN: The drunk said he took a coin off a grave once and his dog died. Then he said he never had a dog.
* [Kick it apart.]
    ~ caps_how = 3
    ~ rat_favour -= 1
    He put his boot through it. The caps went skittering over the gravel and one rang off the dumpster round the corner.
    Under the kitchen floor something moved, a lot of something, all at once, and then it was quiet.
    FATHER: You don't kick what you can't count.
- -> at_front.f_opts


// ------------------------------------------------------------------ the payphone at the Lesso

=== out_payphone ===
~ pass(1)
The payphone on the end wall of the Lesso was ringing, the old kind on a steel cord, and it had been ringing since he came round the bend.
* [Pick it up.]
    ~ esso_answered = 1
    ~ out_found += cl_phone
    He picked it up. A room on the line: glasses, a jukebox, a laugh he knew from table 28. Close to the mouthpiece someone breathing through their nose.
    VOICE: Is he there? The new one?
    * * ["Who is this?"]
        The breathing stopped. Somebody far back in the room shouted for a jug of something.
        VOICE: Tell him the door's open.
    * * ["I'm here."]
        VOICE: Yeah. We can see you.
    - - The line clicked and went to nothing, not even a tone.
    MANUAL: The payphone in the rear hallway is not in service.
    He looked up the highway. A hundred and fifty metres of dark, and the red of the sign, and the window lit along the front.
* [Let it ring.]
    ~ esso_answered = -1
    He let it ring. It rang twenty more times, and then it stopped between one ring and the next, and the rain was louder than it had been.
    FATHER: Anybody who wants you that bad can wait.
- -> at_front.f_opts


// ------------------------------------------------------------------ the Lesso's night window

=== out_clerk ===
~ pass(1)
{ out_clerk == 1:
    The Lesso's door was locked, and taped to it a sign: NIGHT WINDOW, with an arrow. Through the glass the kid from the ice freezer was behind the counter now, on a stool, his phone flat on the counter in front of him, typing on it with one thumb. He slid the little window open without looking up.
    ESSOKID: Hey. The Sov guy.
    ESSOKID: Four cents an answer. I've done two hundred and eleven since eight. Ask me something, I'll tell you which one of me's lying.
    A Corolla pulled up to the pumps with its engine running and a woman got out in pyjama pants and a Canucks hoodie, a twenty folded long between two fingers, and stood behind him at the window like she'd been there first.
    "Two Lotto Max and the Pall Malls, hon. The real ones, not the slims. And you didn't see me, if Ron asks."
    ESSOKID: Who's Ron.
    "Good boy." She went back to the car. There was a baby seat in the back, facing the wrong way for a baby, with a case of Pilsner strapped into it.
- else:
    The kid slid the night window open.
    ESSOKID: Hey.
}
- (counter)
* {cash >= 16} [Smokes. Player's. (16 dollars)]
    ~ cash -= 16
    ~ smokes++
    He put the pack in the tray, and took the change, and the window, and slid it shut a little against the cold.
    ESSOKID: You don't look like you smoke.
    ESSOKID: Nobody does, now. It's all of us, though. It's everybody.
    -> counter
+ {cash >= 2} [A coffee. (2 dollars)]
    ~ cash -= 2
    ~ pass(2)
    A coffee from the machine in a cup with a lid that didn't fit. It was hot enough to hurt and that was the whole of what it did.
    { drinks >= 3:
        FIGHTER: It won't make you any less drunk. It'll make you a drunk who's awake.
    }
    -> counter
* {cash >= 4} [Two dogs off the roller grill. (4 dollars)]
    ~ cash -= 4
    ~ ate = 1
    ~ pass(3)
    ESSOKID: They've been going round since about six. They're fine. They're, like, structurally fine.
    He ate them at the window in the rain, one and then the other, with the mustard out of a pump that farted.
    { drinks >= 2:
        FATHER: Your grandmother called those Legion steaks. She'd have eaten four.
    }
    -> counter
* ["Worst thing anybody's bought at this window?"]
    ~ pass(2)
    ESSOKID: Oh, man. Okay. Guy comes up at like three, buys one condom and a lighter. Asks do they come in a bigger size.
    ESSOKID: The lighter. He meant the lighter. I'm pretty sure.
    ESSOKID: And a lady bought the whole roll of Crossword, like forty tickets, and won sixty bucks and cried. Good crying. I think good.
    -> counter
+ {cash >= 5 && scratched < 3} [A scratch ticket. (5 dollars)]
    ~ cash -= 5
    ~ scratched++
    ~ temp win = RANDOM(1, 20)
    He scratched it on the window's ledge with a quarter.
    { win:
    - 20:
        ~ cash += 100
        Three crowns. A hundred dollars. The kid looked at it for a while and then paid it out of the till in twenties, slowly.
        ESSOKID: Don't come back for a month, man. You used it up.
    - 15:
        ~ cash += 20
        Twenty dollars.
    - 9:
        ~ cash += 5
        Five dollars. His own money back. He put it in a different pocket from the rest.
    - else:
        Nothing. A cherry, a bell, a crown.
    }
    -> counter
* {out_found ? cl_cross} ["The cross up the shoulder. Darlene. Who puts the flowers on it?"]
    ESSOKID: The cross? Since like March.
    ESSOKID: Somebody comes Tuesdays. I hear a car pull onto the shoulder about four in the morning and in the morning they're new.
    ESSOKID: I don't look, man. I look at this. Four cents.
    ~ out_found += cl_flowers
    -> counter
* {esso_answered != 0} ["Your payphone was ringing."]
    ESSOKID: It does that.
    ESSOKID: Phone company says it's not connected. Like, there's no wire. They cut it in like twenty twelve.
    ESSOKID: I answered it once. It was a bar.
    -> counter
+ [That's all.]
    He slid the window shut.
    -> at_front.f_opts


// ------------------------------------------------------------------ the fire on the beach

=== out_fire ===
~ pass(1)
Somebody's fire, an hour old, in a ring of stones on the beach below the wall: driftwood burned down to the ends, the ends still glowing when the wind got under them. Two empties. One sneaker, a woman's, white, nearly new.
* [Warm his hands at it.]
    ~ fire_how = 1
    ~ pass(4)
    He crouched and held his hands over it. The heat came up into his palms and his wrists. Out on the water a light moved, a long way off, and stopped, and he watched it till it went on again.
    FATHER: Your mother and I had a fire on a beach like this the night before I started at the Legion. I don't remember a thing we said. I remember her feet in the sand. She had very ugly feet and she knew it.
* [Kick sand over it.]
    ~ fire_how = 2
    He kicked the sand over it until there was no light in it. Then he stood in the dark he'd made.
+ [Leave it.]
- -> at_front.f_opts


// ------------------------------------------------------------------ the kitchen's back door, from outside

=== out_kitchen_door ===
~ pass(1)
The kitchen's back door, propped open on a brick, the fryer's heat coming out into the rain in a sheet you could see. The light inside was green-white and hard. The radio was on the hockey.
* [Kick the brick out.]
    ~ kitchen_door = false
    ~ kitchen_shut_at = clock
    He hooked the brick out with his boot and the door swung to on its closer and latched.
    { cook_here():
        ~ rep(rep_cook, -1)
        COOK: Hey! HEY. Who did that?
        The door banged open again from inside, and shut again when nobody was there to hold it.
        COOK: I know it's you, Security! It's a hundred and ten in here!
    }
    FATHER: A back door's a front door with no one on it.
* [Leave it.]
    ~ doors_left += left_kitchen
    FIGHTER: Anybody you put out the front can walk round to here in a minute.
- -> at_front.f_opts
