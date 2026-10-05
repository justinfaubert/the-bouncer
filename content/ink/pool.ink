// The pool table. The big man and his buddy, playing for money since before the shift.
// Draft storyline: the big man is the father of the kid in the hoodie and the young woman in the
// truck. Their mother went into hospital this morning and he isn't answering his phone.
// Whether he finds out, from whom, and how, is the spine of Wednesday.

// How the big man takes the doorman, as a bonus or penalty on anything the doorman asks of him:
// losing to him on purpose, letting him keep his dignity, and whether a promise got kept.
=== function bigman_mod()
~ temp m = bigman_ease
{ promise_kept == -1:
    ~ m--
}
{ m > 2:
    ~ m = 2
}
{ m < -2:
    ~ m = -2
}
~ return m

// The room the doorman gave the kid at the door, less the times he pushed, as the same.
=== function kid_mod()
{ kid_ease > 2:
    ~ return 2
}
{ kid_ease < -2:
    ~ return -2
}
~ return kid_ease

// Where his daughter is, as the doorman would tell him.
=== function her_place()
{
- sister_at == s_vestibule:
    ~ return "at the door"
- sister_at == s_rail:
    ~ return "right there at the rail"
- in_truck(sister_at):
    ~ return "out in the truck"
}
~ return "looking for you"

=== at_pool ===
~ here = pool
{ due(): -> hub }
{ fam ? dad_went || fam ? dad_ejected || fam ? dad_walked:
    -> after_gone
}
{
- at_pool == 1:
    The table had a lean to it that the regulars played. The cloth was burned in two places. Four twenties were tucked under the rail at the big man's end.
    The big man played left-handed, and badly, the way a good player plays badly: on purpose, and only on the shots that mattered. #sfx: balls #portrait: bigman
    { knows ? kid_photo:
        He'd seen it already, on the kid's phone, from the lot: the lamp, the green, the left hand flat on the rail.
    }
    His buddy was small and quick and kept looking at the door.
- fam ? dad_stayed:
    The big man was playing on his own now, both ends of the table. The buddy racked for him and didn't say anything.
- pool_heat >= 6 && not fam_done:
    The two of them weren't playing so much as taking turns at the table. Neither one was talking.
- else:
    {shuffle:
    - The big man was lining up a shot he meant to miss.
    - The buddy was racking. The big man chalked his cue and watched the door.
    - The click of the balls, the lean of the table, the twenties under the rail.
    }
}
-> opts

= opts
{ due(): -> hub }
<- moves(pool)
+ [Watch them play.]
    -> watch
* {knows ? kid_why && not fam_done} [Tell the big man about the hospital.]
    -> tell
* {fam ? sister_fetched && knows !? kid_why && not fam_done} [Tell the big man his daughter's {sister_at == s_vestibule:at the door|out in the lot}.]
    -> tell
+ {at_pool.watch > 0 && at_pool.talk == 0 && not fam_done} [Talk to the big man.]
    -> talk
+ {cash >= 20 && at_pool.play == 0 && not fam_done} [Put twenty on the next game.]
    -> play
+ {kid_at == s_jukebox && fam !? kid_opened && fam !? kid_found && at_pool.kid_jukebox == 0 && not fam_done} [The kid by the jukebox.]
    -> kid_jukebox

= watch
~ pass(10)
~ heat(-1)
{ at_pool.watch > 1:
    -> watch_again
}
He leaned on the pillar by the dartboard and watched a game and a half.
The big man missed the shots he needed and made the ones that didn't matter. Every time he missed, his left hand went flat on the rail and stayed there a second too long. When the buddy won, the big man paid him from the bills under the rail, and neither of them looked at the money.
~ knows += pool_lefty
FIGHTER: Left hand. Flat on the rail. That's where it comes from, if it comes. #mark: pool.lefthand
* [Read the game. #check: father 8]
    { passed:
        ~ knows += pool_hustle
        FATHER: He's not losing. He's paying. That's a debt, going across the rail twenty at a time, so neither of them has to say what it's for.
        FATHER: And he's drinking doubles out of a pint of cola so it looks like one drink. I did that for six years.
    - else:
        FATHER: He's bad at pool.
        The Father had never been interested in pool.
    }
// Reading the game, or just being seen to watch it: they play more carefully with somebody watching.
* [Leave it.]
    ~ heat(-1)
    He went on watching, and they went on playing, a little more carefully for being watched.
- -> opts

= watch_again
{ shuffle:
- The buddy won again. The big man paid him again.
- The big man went to the bar for another cola with nothing in it you'd want to call cola.
- They were playing slower now. The big man took a long time over every shot, looking at the table like it had asked him something.
}
{
- sister_at == s_rail && not fam_done:
    His daughter was at the rail, a cue's length from him. He hadn't looked at her once. That took effort. You could see it take effort.
- kid_at == s_jukebox && not fam_done:
    The big man hadn't looked at the jukebox once. That took effort. You could see it take effort.
}
-> opts

= talk
~ pass(4)
He waited until the big man was chalking his cue.
BIGMAN: You'd be the new one, bud.
BIGMAN: Lot of doors in this old place for one fella.
- (tk)
* (asked_regular) ["You're a regular?"]
    BIGMAN: Wednesdays. Well. Most days, lately.
    -> tk
* {knows ? pool_hustle} ["You're paying him, not playing him."]
    ~ knows += transmission
    ~ heat(1)
    The big man looked at him for the first time, properly.
    BIGMAN: Now that's between me and him.
    BUDDY: No no no, it's nothing, pal. He owes me for a transmission, is all.
    BIGMAN: Me and him.
    FIGHTER: Now they're both looking at you. That's what saying it out loud costs.
    -> tk
* [Ask how his night's going. #check: father 8 {asked_regular:1|0}]
    { passed:
        He asked it the way the Father used to, like it didn't matter, and it got an answer.
        BIGMAN: Ah, it's been a week, bud. One of them weeks.
        BIGMAN: Family stuff. You know how it is.
        He didn't say anything else about it. He put the chalk down.
        BIGMAN: Do me a favour, eh. Anybody comes in here looking for me tonight, I'm not here. You never saw me.
        FATHER: There it is.
        ~ knows += bigman_dad
        -> favour
    - else:
        BIGMAN: Ah, can't complain.
        He bent over the table and took a shot that didn't need taking.
    }
    -> tk
+ [Leave him to his game.]
    -> opts

// What he says to the favour is a promise, or near enough, and his daughter is coming (door.ink).
= favour
* ["All right."]
    ~ promised_bigman = true
    BIGMAN: Appreciate it.
    He went back to the table.
* [Say nothing.]
    ~ promised_bigman = true
    He didn't say anything. The big man took that for a yes, the way men like him take most things.
* ["Depends who's asking."]
    ~ bigman_ease--
    BIGMAN: Sure. Forget I asked, then.
    He bent over the table again. He didn't forget he'd asked. Neither did the doorman.
- -> talk.tk

= play
~ pass(15)
He put a twenty on the rail. The buddy looked relieved to sit one out.
BIGMAN: Rack 'em, then. You any good?
* [Play to win. #check: fighter 8]
    { passed:
        He ran four balls, missed, and then the big man handed him the eight, deliberately, the way he'd been handing the buddy games all night.
        ~ tip(20)
        FIGHTER: He threw it.
        FATHER: He throws everything. Watch what he's keeping.
    - else:
        He was not good. The table had a lean he didn't know. The big man took his twenty and tucked it under the rail with the others.
        ~ cash -= 20
    }
* [Play to lose.]
    ~ bigman_ease++
    He played badly enough that the big man noticed, and liked him for it.
    ~ cash -= 20
- ~ heat(-2)
While they racked, the big man spoke to the table, not to him.
BIGMAN: You got kids yourself?
// What he says here is his now (main.ink, claims). It comes back in the lot at close.
* ["No."]
    ~ claims += said_no_kids
    BIGMAN: Don't.
    BIGMAN: Nah. That's not right. They're good kids. It's me that's the problem.
* ["Not that I know of."]
    ~ claims += said_maybe_kids
    The big man laughed, once, like a cough.
* ["Do you?"]
    ~ claims += said_asked_back
    BIGMAN: Two. My girl and the boy. Grown, near enough, and better than me.
    BIGMAN: Low bar.
    He broke. The balls went everywhere and none of them dropped.
- ~ knows += bigman_dad
{ kid_at == s_jukebox && fam !? kid_opened:
    He didn't look at the jukebox. The kid at the jukebox didn't look at him. Two people not looking at each other across twenty feet of carpet.
    FATHER: That's his.
}
-> opts

// How the kid takes him here depends on how the door went (kid_ease).
= kid_jukebox
~ pass(3)
The kid was standing by the jukebox with one earbud in, not choosing anything. The jukebox cycled through its screens: albums, then the ad for the jukebox, then albums.
{
- kid_ease > 0:
    HOODIE: hey
    He moved over a little, as if there was a queue for the jukebox and the doorman was in it.
- kid_ease < 0:
    HOODIE: i'm not doing anything
    He said it before the doorman had said anything, and turned a shoulder to him.
- else:
    HOODIE: i'm not doing anything
}
* [Stand next to him and say nothing.]
    ~ pass(3)
    { kid_ease < 0:
        He stood there. The kid stood there with his shoulder turned, and after a while he went down the back hall without a word. The single washroom door shut and locked.
        ~ fam += kid_found
        ~ move(kid_at, s_single)
        FATHER: He's had enough of you for one night. You did that at the door.
        -> opts
    }
    He stood there. The kid stood there. After a while the kid took the other earbud out.
    HOODIE: that's my dad
    He didn't point. He didn't have to.
    ~ knows += bigman_dad
    ~ pull_kid++
    HOODIE: i'm supposed to tell him something. well my sister's supposed to. she sent me in cause she thought he wouldn't make a scene with me or whatever
    HOODIE: i need to piss
    He went down the back hall. The single washroom door shut and locked.
    ~ fam += kid_found
    ~ move(kid_at, s_single)
* ["Who are you looking for?"]
    HOODIE: no one
    He put the earbud back in and went down the back hall toward the bathrooms. The single washroom door shut and locked.
    ~ fam += kid_found
    ~ move(kid_at, s_single)
* ["That your dad?" #check: wrongman 8 {kid_mod()}]
    { passed:
        WRONGMAN: Ask it like you already know. People answer what you already know.
        HOODIE: yeah. i mean yeah
        ~ knows += bigman_dad
        ~ pull_kid++
    - else:
        HOODIE: what? no
        It was too fast to be true.
    }
    He went down the back hall. The single washroom door shut and locked.
    ~ fam += kid_found
    ~ move(kid_at, s_single)
- -> opts

= tell
~ pass(2)
FATHER: Not in front of his friend. Never tell a man anything in front of his friend.
// He said he'd say the big man wasn't here, and then he let her in, or went to get him (door.ink).
{ promise_kept == -1:
    The big man saw him coming and knew what he was coming with.
    BIGMAN: One thing, bud. I asked you one thing.
}
* [Tell him right here, at the table. #check: father 10 {bigman_mod()}]
    ~ heat(2)
    -> told(true)
* ["Got a second? Over here." #check: father 8 {bigman_mod()}]
    -> told(false)
* ["Your daughter's {her_place()}." Just that. #check: father 7 {bigman_mod()}]
    -> told(false)

= told(public)
~ fam += dad_told
{ passed:
    -> went(public)
}
{ crit == -1:
    -> blew_up
}
-> stayed(public)

= went(public)
~ pass(3)
{ public:
    He said it at the table, in front of the buddy. The big man stood very still.
- else:
    He said it at the end of the bar, low, with his back to the room. The big man stood very still.
}
{ knows ? kid_why:
    BIGMAN: Since when.
    He told him since when.
}
The big man put his cue on the table, across the balls, in the middle of a game, which is a thing people don't do.
BIGMAN: Where are they.
~ fam += dad_went
~ fam_done = true
# done: fetch
{
- in_truck(sister_at) || sister_at == s_vestibule:
    He went out the front door into the rain without his jacket. Through the glass the doorman saw the driver's door of the pickup open and his daughter get out and stand there, and then the big man had his arms around her, in the rain, in the lot, with the headlights on them both.
    {
    - kid_at == s_single:
        The kid came out of the single washroom at the end of the back hall and went past the doorman and out to them.
    - kid_at == s_jukebox:
        The kid came away from the jukebox and went past the doorman and out to them.
    }
    { indoors(vape_at):
        The boyfriend went out after him, late.
    }
- sister_at == s_rail:
    He crossed the room to where they were. He said something to his daughter nobody else heard.
    { indoors(kid_at):
        He put a hand on the back of his son's neck, the way you'd hold a dog you'd found on the highway, and the three of them went out the front door together{indoors(vape_at):, and the boyfriend after them, late, holding the door}.
    - else:
        The two of them went out the front door together{indoors(vape_at):, and the boyfriend after them, late, holding the door}.
    }
- else:
    He crossed the room {kid_at == s_single:to the single washroom and knocked once, and said his son's name through the door, and the lock clicked|to the jukebox}. He put a hand on the back of his son's neck, the way you'd hold a dog you'd found on the highway, and the two of them went out the front door together, toward the pickup in the lot.
}
~ family_gone()
~ room_count--
~ rep(rep_kids, 2)
~ rep(rep_staff, 1)
The pickup's lights came on and it pulled out onto the highway, going toward town. #sfx: door
BUDDY: He left it. He left the money.
Four twenties under the rail. The buddy looked at them for a long time and then put them in the tip jar at the bar, all four, and left too.
~ room_count--
{ knows ? transmission:
    WRONGMAN: A transmission. In a tip jar.
}
FATHER: You carried it right.
FATHER: I never would have gone.
-> hub

= stayed(public)
~ pass(3)
~ fam += dad_stayed
~ fam_done = true
{ public:
    He said it at the table, in front of the buddy. The big man went on chalking his cue.
- else:
    He said it at the end of the bar, low. The big man listened to all of it and then looked past him at the pool table.
}
BIGMAN: Yeah, okay. I'll just finish this game.
BIGMAN: Tell 'em I'll come by after, eh. Tell 'em I'm coming.
FATHER: He's not coming. I wasn't.
{
- sister_at == s_vestibule:
    He went back to the door and told the young woman waiting in the vestibule that her father would come after.
    DRIVER: After what.
    She didn't wait for an answer. She went back to the truck.
- in_truck(sister_at):
    He went out across the gravel to the pickup and told her through four inches of window that her father would come after.
    DRIVER: After what.
    The window went up.
- sister_at == s_rail:
    He went to the rail and told her. The sister closed her eyes for a second. {kid_at == s_jukebox:Then she took her brother by the sleeve and walked him out|{kid_at == s_single:Then she knocked on the single washroom door until it opened, and walked her brother out|Then she walked out}}{indoors(vape_at):, and the boyfriend after them}.
}
{ indoors(kid_at) && sister_at != s_rail:
    {kid_at == s_single:The single washroom door opened.|} The kid came out past the pool table without looking at it and went out to the truck, and got in the back.
}
{ indoors(vape_at) && sister_at != s_rail:
    The boyfriend went out after him, taking his time about it.
}
The pickup pulled out onto the highway toward town. Its tail lights went along the seawall and round the bend. #sfx: door
~ family_gone()
~ fam -= kids_waiting
# done: fetch
~ rep(rep_kids, 1)
WRONGMAN: In the story, the doorman carried a message once, and the man said he'd come after, and he did come after. And that was worse.
-> hub

= blew_up
~ pool_heat = 9
~ fam += pool_fight
~ incident += inc_fight
He barely got the first sentence out. The big man turned and hit the rack with the butt of his cue, hard, and the triangle went across the floor, and the whole room turned around.
BIGMAN: Who asked you.
-> ev_pool.fight

= after_gone
~ pass(2)
{ at_pool.after_gone == 1:
    The pool table was empty. Somebody had racked the balls and nobody was playing. The cue was still lying across the table where the big man had left it.
- else:
    The pool table was still empty. Nobody had picked up the cue.
}
{ fam ? dad_ejected:
    There was chalk on the carpet, and a smear on the cloth nobody had cleaned up.
}
<- moves(pool)
-> DONE


// ------------------------------------------------------------------ when it goes

=== ev_pool ===
~ here = pool
~ fam += pool_fight
~ incident += inc_fight
# sfx: balls
{
- sister_at == s_rail:
    It started the way they start: afterward nobody could have told you how.
    The sister had gone to the pool table. She was standing at the big man's elbow saying something with her hands in fists at her sides. The big man was looking at the table.
    BUDDY: No no, not now, sweetheart. Your dad's working, okay? He's working.
    { indoors(vape_at):
        VAPE: the fuck did you just CALL her
    }
- kid_at == s_jukebox:
    It started the way they start: afterward nobody could have told you how.
    The kid had come away from the jukebox and was standing at the end of the pool table, in the way of a shot, with his earbuds out.
    HOODIE: mom's in the hospital
    He said it too quietly. The buddy laughed, not at that, at something else, and the big man put his hand flat on the rail.
- indoors(vape_at):
    It started the way they start: afterward nobody could have told you how.
    The boyfriend had drifted over from the bar to watch, and said something about the big man's last shot that he thought was funny, and then said it again louder. The big man put his hand flat on the rail.
- else:
    It was the money. The buddy picked up the twenties from under the rail, all of them, and said something about the big man throwing games like he was stupid, and the big man put his hand flat on the rail.
}
-> fight

= fight
FIGHTER: Now. Now, now, now.
* [Get between them. #check: fighter 8 {knows ? pool_lefty:2|0}]
    ~ pass(2)
    { passed:
        He was between them before the second thing happened. He had the big man's left wrist before it came off the rail, and he held it, not hard, just so the big man knew whose it was.
        FIGHTER: That's it. That's all it takes if you're first.
        -> after_fight(false)
    - else:
        He got there second. The big man's elbow caught him on the way through, over the eye, and the room went white and loud. #sfx: hit
        ~ hurt++
        ~ incident += inc_hurt
        -> after_fight(true)
    }
// What the Fighter made of the boyfriend at the door, and what was in the back seat, count here (vape_mod()).
* {indoors(vape_at)} [Take the boyfriend out first. #check: fighter 6 {vape_mod()}]
    ~ pass(2)
    { passed:
        He took the boyfriend by the back of the hoodie and the belt and walked him the length of the room and out the front door onto the gravel before the boyfriend's feet caught up with what was happening. #sfx: door
        ~ fam += vape_ejected
        ~ vape_out_at = clock
        ~ vape_returned = false
        ~ vape_seen = false
        ~ move(vape_at, s_lot)
        FIGHTER: The one who's going to swing. Always the one who's going to swing.
        -> after_fight(false)
    - else:
        The boyfriend saw him coming and swung first, at the biggest thing in the room, which was the doorman. It glanced off his shoulder. The big man shoved the boyfriend into the jukebox. #sfx: hit
        ~ hurt++
        ~ incident += inc_hurt
        -> after_fight(true)
    }
* ["Everybody stop." #check: father 10]
    ~ pass(1)
    { passed:
        He didn't shout it. He said it the way the Father used to say it, from the chest, so it went under the music and came up everywhere at once.
        The room stopped.
        FATHER: That's the voice. You've got it or you haven't.
        -> after_fight(false)
    - else:
        He said it. Nobody heard it. The jukebox was on the chorus.
        The big man shoved {indoors(vape_at):the boyfriend|the buddy} into the table and a cue went over and the doorman was in it now whether he liked it or not. #sfx: hit
        ~ hurt++
        ~ incident += inc_hurt
        -> after_fight(true)
    }
* [Wait one more second to see who starts it. #check: wrongman 8]
    ~ pass(1)
    { passed:
        WRONGMAN: The wrong man's never the one you're watching.
        It was the buddy. The buddy had a pool ball in his hand, down by his leg, where nobody was looking.
        He took it off him. Just took it, like taking keys off a drunk, and the buddy let him, and that was the end of it.
        -> after_fight(false)
    - else:
        He waited one second. That was the second it happened in. The big man's left hand came off the rail. #sfx: hit
        { indoors(vape_at):
            The boyfriend went down against the jukebox and stayed down, holding his face.
        - else:
            The buddy went down against the jukebox and stayed down, holding his face.
        }
        ~ incident += inc_hurt
        WRONGMAN: That's the story. You waited to see. Everyone in the story waited to see.
        -> after_fight(true)
    }

= after_fight(bad)
{ bad:
    It was over in the time it takes to say it. It always is. Then it's the long part.
- else:
    It was over before it started, which is the only kind of fight a doorman wins.
}
Table 28 had turned all the way around in their chairs to watch. The bartender had the phone in her hand and hadn't dialled it.
{ bad:
    -> call_it
}
-> sort_out

= call_it
BARTENDER: Door. Do I call it or not?
* [Call it.]
    ~ rep(rep_owner, -1)
    ~ police_called = true
    ~ police_at = clock
    ~ incident += inc_police
    BARTENDER: Yep.
    She dialled. It would be forty minutes. It was always forty minutes out here.
    MANUAL: Correct.
    FATHER: Now it's on paper. Now it's the owner's night, and the owner's insurance.
* ["Don't. I've got it."]
    ~ rep(rep_owner, 1)
    ~ name_on_log = true
    She put the phone down.
    BARTENDER: Your name goes on the log, then. Not mine.
- -> sort_out

= sort_out
* {fam !? dad_ejected} [Put the big man out.]
    ~ pass(3)
    ~ fam += dad_ejected
    ~ fam_done = true
    ~ room_count--
    He walked the big man to the door. The big man let him. At the door he stopped, and turned, and the doorman thought he was going to say something, and he didn't.
    {
    - kids_count() > 0:
        The kids went out after him. In the lot, in the rain, they stood by the pickup and argued, and then the big man got into the passenger side, and the truck pulled out toward town.
        ~ fam += dad_went
        FATHER: Sometimes you throw a man out and it's the kindest thing anybody's done for him all year.
    - else:
        He went out into the rain without his jacket and stood in the lot, and didn't go to the pickup. He walked off along the shoulder of the highway toward town. After a minute the pickup pulled out after him with its hazards on and followed him at a walking pace, all the way to the bend.
        ~ fam += dad_walked
        FATHER: They'll follow him all the way home like that. Kids do. I know.
    }
    ~ family_gone()
    The buddy took the twenties off the rail, all of them, and his jacket off the hook, and went out after him without a word to anybody.
    ~ room_count--
    ~ rep(rep_t28, 1)
    -> hub
* {kids_count() > 0} [Put the kids out. All of them.]
    ~ pass(3)
    ~ temp she_was = indoors(sister_at)
    ~ fam += kids_waiting
    ~ kids_out()
    ~ rep(rep_kids, -3)
    { she_was:
        He walked them out. The sister didn't fight it. At the door she looked at him the way you look at a wall you've walked into.
        DRIVER: We didn't hit anybody. He did.
    - else:
        He walked them out. Nobody fought it.
    }
    The pickup didn't leave. It sat at the edge of the lot with its engine running, waiting.
    -> hub
* [Everybody who was in that, out.]
    ~ pass(4)
    ~ fam += dad_ejected
    ~ fam += all_out
    ~ fam += dad_went
    ~ fam_done = true
    ~ room_count -= 2
    ~ rep(rep_t28, 1)
    ~ rep(rep_staff, 1)
    { kids_count() > 0:
        He put them all out: the big man, the buddy, the kids. Out in the lot, the family stood around the pickup in the rain for a long time. Then they all got in it, the big man too, and it went.
    - else:
        He put them both out, the big man and the buddy. Out in the lot the buddy went to his own car, and the big man stood in the rain by the pickup until the passenger door opened, and then he got in, and it went.
    }
    ~ family_gone()
    FATHER: Fair. Fair's not the same as right.
    -> hub
* {fam !? dad_ejected} [Sit the big man down and get him a coffee. #check: father 8 {bigman_mod()}]
    ~ pass(5)
    { passed:
        He sat him down at an empty table and the bartender, without being asked, brought a coffee. The big man held it with both hands. After a while he said "where are they," and the doorman told him, and he got up and went.
        ~ fam += dad_went
        ~ fam_done = true
        ~ room_count--
        ~ family_gone()
        ~ rep(rep_staff, 2)
        ~ rep(rep_kids, 1)
        The buddy sat on at the pool table on his own for a while, and then he went too.
        ~ room_count--
    - else:
        He sat him down. The big man sat for about as long as it took the doorman to turn around, and then he was back at the pool table with the cue in his hand, as if none of it had happened.
        ~ fam += dad_stayed
        ~ fam_done = true
        // Whoever of his family saw that goes out to the pickup, and the pickup waits (closing.ink).
        {
        - indoors(sister_at):
            His daughter watched him pick the cue back up. Then she went out to the truck{indoors(kid_at) || indoors(vape_at):, and the others went after her}.
        - indoors(kid_at):
            The kid watched him pick the cue back up, and went out to the truck{indoors(vape_at):, and the boyfriend after him}.
        - indoors(vape_at):
            The boyfriend went out to the truck.
        }
        { kids_count() > 0:
            ~ kids_out()
            ~ fam += kids_waiting
            The pickup didn't leave.
        }
    }
    -> hub


// ------------------------------------------------------------------ the constable, forty minutes after

// The bartender called it in after the fight (call_it). One car. It's always forty minutes out here.
// A tunnel: from the floor (sim.ink, events) while the bar's open, or from lock_up (closing.ink) if
// forty minutes runs past close and she knocks on the locked door.
=== ev_police ===
~ police_seen = true
~ here = door
~ door_away = 0
{ lock_up:
    Headlights came into the empty lot and stopped crooked across two spaces, and a constable got out and put her hat on in the rain, and knocked on the glass of the door he'd just locked. One car. It was always one car out here. #portrait: constable
    He let her in.
    CONSTABLE: Okay. So. We had a call about a fight.
    She looked at the room the way he'd been taught to look at one: heads, then faces, then hands. There was nobody in it but the bartender and him, and the chairs up on the tables.
    CONSTABLE: Forty minutes. I know. I've got one car for the whole valley.
- else:
    Headlights came into the lot slowly and stopped crooked across two spaces, and a constable got out and put her hat on in the rain. One car. It was always one car out here. #portrait: constable
    CONSTABLE: Okay. So. We had a call about a fight.
    She looked at the room the way he'd been taught to look at one: heads, then faces, then hands.
    { pool_still():
        At the pool table the big man was racking, as if none of it had been about him.
    - else:
        The pool table was empty. Whoever she'd come for had gone home.
    }
}
* [Tell her the way it happened.]
    ~ pass(8)
    ~ told_police = 1
    ~ rep(rep_staff, 1)
    He told her the way it happened, in order, with the names he had and without the ones he didn't. She wrote it in a notebook with a pencil, the way they did out here, where the laptops didn't get signal.
    { hurt > 0:
        CONSTABLE: Got it. And the eye, sir?
        He told her about the eye.
    }
    CONSTABLE: Alright. First time I've had one in order from a doorman.
    FATHER: You told it straight to a cop. Remember what it felt like. You won't always.
* [Tell her less than that.]
    ~ pass(4)
    ~ told_police = -1
    ~ cocoon++
    He told her it was a disagreement over a game, and it had sorted itself out, which was true as far as it went.
    She looked at him for a while, and then at the chalk on the carpet.
    CONSTABLE: Sorted itself out.
    She wrote down sorted itself out.
    FATHER: She knows. They always know. She's just got eleven other calls.
* ["She called it. Ask her."]
    ~ pass(5)
    ~ told_police = 2
    ~ rep(rep_staff, -1)
    He pointed his chin at the bartender. The constable went over, and the bartender told her, {lock_up:counting the till the whole time|wiping the bar the whole time} and not once looking at him.
    FATHER: You gave her the hard part. She'll remember whose part it was.
- She took the doorman's name and spelled it back to him, and went out to the car, and sat in it for a long time with the dome light on, writing. Then she went.
WRONGMAN: In the story the police came too. Forty minutes after. Everybody had gone home by then.
->->
