// The pool table. The big man and his buddy, playing for money since before the shift.
// Draft storyline: the big man is the father of the kid in the hoodie and the young woman in the
// truck. Their mother went into hospital this morning and he isn't answering his phone.
// Whether he finds out, from whom, and how, is the spine of Wednesday.

=== at_pool ===
~ here = pool
{ due(): -> hub }
{ fam ? dad_went || fam ? dad_ejected:
    -> after_gone
}
{
- at_pool == 1:
    The table had a lean to it that the regulars played. The cloth was burned in two places. Four twenties were tucked under the rail at the big man's end.
    The big man played left-handed, and badly, the way a good player plays badly: on purpose, and only on the shots that mattered. #sfx: balls #portrait: bigman
    His buddy was small and quick and kept looking at the door.
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
+ [Watch them play.]
    -> watch
* {knows ? kid_why && not fam_done} [Tell the big man about the hospital.]
    -> tell
* {fam ? sister_fetched && knows !? kid_why && not fam_done} [Tell the big man his daughter's at the door.]
    -> tell
+ {at_pool.watch > 0 && at_pool.talk == 0 && not fam_done} [Talk to the big man.]
    -> talk
+ {cash >= 20 && at_pool.play == 0 && not fam_done} [Put twenty on the next game.]
    -> play
+ {kids_in > 0 && fam ? hoodie_admitted && fam !? kid_opened && fam !? kid_found && at_pool.kid_jukebox == 0} [The kid by the jukebox.]
    -> kid_jukebox
+ [Back to the floor.]
    ~ pass(1)
    -> hub

= watch
~ pass(10)
{ pool_heat > 0:
    ~ pool_heat--
}
{ at_pool.watch > 1:
    -> watch_again
}
He leaned on the pillar by the dartboard and watched a game and a half.
The big man missed the shots he needed and made the ones that didn't matter. Every time he missed, his left hand went flat on the rail and stayed there a second too long. When the buddy won, the big man paid him from the bills under the rail, and neither of them looked at the money.
~ knows += pool_lefty
FIGHTER: Left hand. Flat on the rail. That's where it comes from, if it comes.
* [Read the game. #check: father 8]
    { passed:
        ~ knows += pool_hustle
        FATHER: He's not losing. He's paying. That's a debt, going across the rail twenty at a time, so neither of them has to say what it's for.
        FATHER: And he's drinking doubles out of a pint of cola so it looks like one drink. I did that for six years.
    - else:
        FATHER: He's bad at pool.
        The Father had never been interested in pool.
    }
* [Leave it.]
- -> opts

= watch_again
{ shuffle:
- The buddy won again. The big man paid him again.
- The big man went to the bar for another cola with nothing in it you'd want to call cola.
- They were playing slower now. The big man took a long time over every shot, looking at the table like it had asked him something.
}
{ kids_in > 0 && not fam_done:
    The big man hadn't looked at the jukebox once. That took effort. You could see it take effort.
}
-> opts

= talk
~ pass(4)
He waited until the big man was chalking his cue.
BIGMAN: You're the new one.
BIGMAN: Lot of doors in this place for one fella.
- (tk)
* ["You're a regular?"]
    BIGMAN: Wednesdays. Most days, lately.
    -> tk
* {knows ? pool_hustle} ["You're paying him, not playing him."]
    The big man looked at him for the first time, properly.
    BIGMAN: That's between me and him.
    BUDDY: He owes me for a transmission. Big deal.
    BIGMAN: It's between me and him.
    ~ rep(rep_owner, 0)
    -> tk
* [Ask how his night's going. #check: father 8]
    { passed:
        He asked it the way the Father used to, like it didn't matter, and it got an answer.
        BIGMAN: Rough week.
        BIGMAN: Family stuff. You know.
        He didn't say anything else about it. He put the chalk down.
        BIGMAN: Do me a favour, eh. Anybody comes in here looking for me tonight, I'm not here.
        FATHER: There it is.
        ~ knows += bigman_dad
    - else:
        BIGMAN: Fine.
        He bent over the table and took a shot that didn't need taking.
    }
    -> tk
+ [Leave him to his game.]
    -> opts

= play
~ pass(15)
He put a twenty on the rail. The buddy looked relieved to sit one out.
BIGMAN: You any good?
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
    He played badly enough that the big man noticed, and liked him for it.
    ~ cash -= 20
- { pool_heat > 1:
    ~ pool_heat -= 2
}
While they racked, the big man spoke to the table, not to him.
BIGMAN: You got kids?
- (kq)
* ["No."]
    BIGMAN: Don't.
    BIGMAN: No. That's not right. They're fine. It's me that's the problem.
* ["Not that I know of."]
    The big man laughed, once, like a cough.
* ["Do you?"]
    BIGMAN: Two. Grown, near enough. They're better than me.
    BIGMAN: Low bar.
    He broke. The balls went everywhere and none of them dropped.
- ~ knows += bigman_dad
{ kids_in > 0 && fam ? hoodie_admitted && fam !? kid_opened:
    He didn't look at the jukebox. The kid at the jukebox didn't look at him. Two people not looking at each other across twenty feet of carpet.
    FATHER: That's his.
}
-> opts

= kid_jukebox
~ pass(3)
The kid was standing by the jukebox with one earbud in, not choosing anything. The jukebox cycled through its screens: albums, then the ad for the jukebox, then albums.
HOODIE: i'm not doing anything
* [Stand next to him and say nothing.]
    ~ pass(3)
    He stood there. The kid stood there. After a while the kid took the other earbud out.
    HOODIE: that's my dad
    He didn't point. He didn't have to.
    ~ knows += bigman_dad
    ~ pull_kid++
    HOODIE: i'm supposed to tell him something. my sister's supposed to. she sent me in because she thought he wouldn't make a scene with me
    HOODIE: i need to piss
    He went down the back hall. The single washroom door shut and locked.
    ~ fam += kid_found
* ["Who are you looking for?"]
    HOODIE: no one
    He put the earbud back in and went down the back hall toward the bathrooms. The single washroom door shut and locked.
    ~ fam += kid_found
* ["That your dad?" #check: wrongman 8]
    { passed:
        WRONGMAN: Ask it like you already know. People answer what you already know.
        HOODIE: ...yeah
        ~ knows += bigman_dad
        ~ pull_kid++
    - else:
        HOODIE: what? no
        It was too fast to be true.
    }
    He went down the back hall. The single washroom door shut and locked.
    ~ fam += kid_found
- -> opts

= tell
~ pass(2)
FATHER: Not in front of his friend. Never tell a man anything in front of his friend.
* [Tell him right here, at the table. #check: father 10]
    ~ pool_heat += 2
    -> told(true)
* ["Got a second? Over here." #check: father 8]
    -> told(false)
* ["Your daughter's at the door." Just that. #check: father 7]
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
- fam ? sister_fetched || fam ? kids_waiting:
    He went out the front door into the rain without his jacket. Through the glass the doorman saw the driver's door of the pickup open and his daughter get out and stand there, and then the big man had his arms around her, in the rain, in the lot, with the headlights on them both. {fam ? hoodie_admitted && fam !? hoodie_refused:The kid came out from the back hall and went past the doorman and out to them.}
- fam ? sister_admitted || kids_in >= 2:
    He crossed the room to where they were. He said something to his daughter nobody else heard. He put a hand on the back of his son's neck, the way you'd hold a dog you'd found on the highway, and the three of them went out the front door together{kids_in >= 3:, and the boyfriend after them, late, holding the door}.
- else:
    He crossed the room to the jukebox. He put a hand on the back of his son's neck, the way you'd hold a dog you'd found on the highway, and the two of them went out the front door together, toward the pickup in the lot.
}
{ kids_in > 0:
    ~ room_count -= kids_in
    ~ kids_in = 0
}
~ room_count--
~ rep(rep_kids, 2)
~ rep(rep_staff, 1)
The pickup's lights came on and it pulled out onto the highway, going toward town. #sfx: door
BUDDY: He left the money.
Four twenties under the rail. The buddy looked at them for a long time and then put them in the tip jar at the bar, all four, and left too.
~ room_count--
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
BIGMAN: I'll finish the game.
BIGMAN: Tell them I'll come by after. Tell them I'm coming.
FATHER: He's not coming. I wasn't.
{
- fam ? sister_fetched || fam ? kids_waiting:
    He went back to the door and told the young woman waiting in the vestibule that her father would come after.
    DRIVER: After what.
    She didn't wait for an answer. She went back to the truck and the truck pulled out onto the highway, and her brother wasn't in it, or he was; the doorman couldn't see.
    ~ fam -= kids_waiting
- kids_in > 1:
    He went to the kids and told them. The sister closed her eyes for a second. Then she took her brother by the sleeve and walked him out{kids_in >= 3:, and the boyfriend after them}.
    ~ room_count -= kids_in
    ~ kids_in = 0
- kids_in == 1:
    He went to the kid by the jukebox and told him. The kid put his hood up and went out the front door into the rain, toward the pickup, without looking at the pool table.
    ~ room_count -= kids_in
    ~ kids_in = 0
}
# done: fetch
~ rep(rep_kids, 1)
WRONGMAN: In the story, the doorman carried a message once, and the man said he'd come after, and he did come after. And that was worse.
-> hub

= blew_up
~ pool_heat = 9
He barely got the first sentence out. The big man turned and hit the rack with the butt of his cue, hard, and the triangle went across the floor, and the whole room turned around.
BIGMAN: Who asked you.
-> ev_pool.fight

= after_gone
~ pass(2)
The pool table was empty. Somebody had racked the balls and nobody was playing. The cue was still lying across the table where the big man had left it.
{ fam ? dad_ejected:
    There was chalk on the carpet, and a smear on the cloth nobody had cleaned up.
}
+ [Back to the floor.]
    -> hub


// ------------------------------------------------------------------ when it goes

=== ev_pool ===
~ here = pool
~ fam += pool_fight
~ incident += inc_fight
# sfx: balls
{ kids_in > 0:
    It started the way they start: afterward nobody could have told you how.
    { fam ? sister_admitted:
        The sister had gone to the pool table. She was standing at the big man's elbow saying something with her hands in fists at her sides. The big man was looking at the table.
        BUDDY: Not now, sweetheart. Your dad's working.
        { kids_in >= 3:
            VAPE: the fuck did you call her
        }
    - else:
        The kid had come away from the jukebox and was standing at the end of the pool table, in the way of a shot, with his earbuds out.
        HOODIE: mom's in the hospital
        He said it too quietly. The buddy laughed, not at that, at something else, and the big man put his hand flat on the rail.
    }
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
* {kids_in >= 3} [Take the boyfriend out first. #check: fighter 6]
    ~ pass(2)
    { passed:
        He took the boyfriend by the back of the hoodie and the belt and walked him the length of the room and out the front door onto the gravel before the boyfriend's feet caught up with what was happening. #sfx: door
        ~ fam += vape_ejected
        ~ vape_out_at = clock
        ~ kids_in--
        ~ room_count--
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
        The big man shoved {kids_in >= 3:the boyfriend|the buddy} into the table and a cue went over and the doorman was in it now whether he liked it or not. #sfx: hit
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
        { kids_in >= 3:
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
BARTENDER: Do I call it?
* [Call it.]
    ~ rep(rep_owner, -1)
    ~ police_called = true
    BARTENDER: Okay.
    She dialled. It would be forty minutes. It was always forty minutes out here.
    MANUAL: Correct.
    FATHER: Now it's on paper. Now it's the owner's night, and the owner's insurance.
* ["Don't. I've got it."]
    ~ rep(rep_owner, 1)
    She put the phone down.
    BARTENDER: Your name on the log, then.
- -> sort_out

= sort_out
* {fam !? dad_ejected} [Put the big man out.]
    ~ pass(3)
    ~ fam += dad_ejected
    ~ fam_done = true
    ~ room_count--
    He walked the big man to the door. The big man let him. At the door he stopped, and turned, and the doorman thought he was going to say something, and he didn't.
    { kids_in > 0:
        The kids went out after him. In the lot, in the rain, the three of them stood by the pickup and argued, and then the big man got into the passenger side, and the truck pulled out toward town.
        ~ room_count -= kids_in
        ~ kids_in = 0
        ~ fam += dad_went
        FATHER: Sometimes you throw a man out and it's the kindest thing anybody's done for him all year.
    - else:
        He went out into the rain without his jacket and stood in the lot, and then walked off along the highway toward town.
    }
    ~ rep(rep_t28, 1)
    -> hub
* {kids_in > 0} [Put the kids out. All of them.]
    ~ pass(3)
    ~ fam += kids_waiting
    ~ room_count -= kids_in
    ~ kids_in = 0
    ~ rep(rep_kids, -3)
    He walked them out. The sister didn't fight it. At the door she looked at him the way you look at a wall you've walked into.
    DRIVER: He's the one who hit someone.
    The pickup didn't leave. It sat at the edge of the lot with its engine running, waiting.
    -> hub
* [Everybody who was in that, out.]
    ~ pass(4)
    ~ fam += dad_ejected
    ~ fam_done = true
    ~ room_count -= (kids_in + 2)
    ~ kids_in = 0
    ~ rep(rep_t28, 1)
    ~ rep(rep_staff, 1)
    He put them all out: the big man, the buddy, the kids. Out in the lot, the family stood around the pickup in the rain for a long time. Then they all got in it, the big man too, and it went.
    FATHER: Fair. Fair's not the same as right.
    -> hub
* {fam !? dad_ejected} [Sit the big man down and get him a coffee. #check: father 8]
    ~ pass(5)
    { passed:
        He sat him down at an empty table and the bartender, without being asked, brought a coffee. The big man held it with both hands. { knows ? kid_why || kids_in > 0:After a while he said "where are they," and the doorman told him, and he got up and went.| After a while he got up, paid, and went.}
        ~ fam += dad_went
        ~ fam_done = true
        ~ room_count--
        { kids_in > 0:
            ~ room_count -= kids_in
            ~ kids_in = 0
        }
        ~ rep(rep_staff, 2)
        ~ rep(rep_kids, 1)
    - else:
        He sat him down. The big man sat for about as long as it took the doorman to turn around, and then he was back at the pool table with the cue in his hand, as if none of it had happened.
        ~ fam += dad_stayed
        ~ fam_done = true
    }
    -> hub
