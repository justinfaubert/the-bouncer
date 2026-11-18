# The voice script

Made by `tools/vo_script.py` from `content/ink/` and the barks and overheard talk in `content/rules/`. Don't edit by hand: run it again after the Ink changes.

Each line's recording goes in `godot/audio/` under the name given, as .ogg, .wav or .mp3. A second take
of the same line goes under the same name with `_2`, `_3` on the end, and the game picks between them.
Lines said the same way in more than one place share a file. Record the teller first: his lines are few
and they carry the most.

Besides the lines, each speaker can have **barks**, `bark_<id>` (a sound under their breath: a grunt, a
laugh, a word that isn't in the script), which play now and then under their unrecorded lines, and each
voice in his head a **whisper**, `whisper_<id>`, the same for theirs. A few takes of each go a long way.

1596 lines to record (1537 files) for 36 speakers. 13 more change with the night and are listed after each speaker.

| Speaker | id | Lines | Changing | Bark file |
|---|---|---|---|---|
| The teller (NARRATOR) | teller | 11 | 0 |  |
| The Father (a voice in his head) | father | 247 | 3 | `whisper_father` |
| The Manual (a voice in his head) | manual | 103 | 3 | `whisper_manual` |
| The Wrong Man (a voice in his head) | wrongman | 85 | 0 | `whisper_wrongman` |
| The Fighter (a voice in his head) | fighter | 74 | 2 | `whisper_fighter` |
| The Till (a voice in his head) | till | 35 | 0 | `whisper_till` |
| Senior (a voice in his head) | senior | 34 | 0 | `whisper_senior` |
| The Table (a voice in his head) | table | 11 | 0 | `whisper_table` |
| The Kid (a voice in his head) | kid | 9 | 0 | `whisper_kid` |
| The Bartender | bartender | 227 | 2 | `bark_bartender` |
| Team Jacket | team_jacket | 91 | 0 | `bark_team_jacket` |
| Table 28 | table28 | 85 | 0 | `bark_table28` |
| End Of The Bar | endbar | 85 | 1 | `bark_endbar` |
| Gary | owner | 83 | 1 | `bark_owner` |
| Hoodie | hoodie | 69 | 0 | `bark_hoodie` |
| The Driver | driver | 57 | 0 | `bark_driver` |
| The Big Man | bigman | 46 | 0 | `bark_bigman` |
| Scratch | scratch | 37 | 0 | `bark_scratch` |
| Cardigan | cardigan | 28 | 0 | `bark_cardigan` |
| The Cook | cook | 25 | 0 | `bark_cook` |
| Vape | vape | 21 | 0 | `bark_vape` |
| a | a | 21 | 0 | `bark_a` |
| Terry | terry | 14 | 0 | `bark_terry` |
| b | b | 14 | 0 | `bark_b` |
| Hearing Aid | hearing_aid | 13 | 0 | `bark_hearing_aid` |
| Slippers | slippers | 12 | 0 | `bark_slippers` |
| The Bookkeeper | bookkeeper | 12 | 0 | `bark_bookkeeper` |
| The Esso Kid | essokid | 11 | 0 | `bark_essokid` |
| The Buddy | buddy | 8 | 0 | `bark_buddy` |
| Raincoat | raincoat | 6 | 0 | `bark_raincoat` |
| The Constable | constable | 6 | 0 | `bark_constable` |
| A Smoker | smoker | 5 | 0 | `bark_smoker` |
| Glasses | glasses | 4 | 1 | `bark_glasses` |
| Hi-Vis | hivis | 3 | 0 | `bark_hivis` |
| slippers_b | slippers_b | 2 | 0 | `bark_slippers_b` |
| Good Shoes | goodshoes | 2 | 0 | `bark_goodshoes` |

## The teller (`teller`)

- `vo_teller_8a152849` That was Wednesday. The way he tells it now, nothing much happened.  _(closing.ink:1945)_
- `vo_teller_2dcbc367` That was Wednesday. The one nobody else remembers. He remembers all of it.  _(closing.ink:1947)_
- `vo_teller_db44e93c` That was Wednesday. The one nobody else remembers.  _(closing.ink:1949)_
- `vo_teller_1874ccce` He'd stand out there most nights for the next month. That was the first time.  _(deck.ink:65)_
- `vo_teller_1e6ace18` He started on a Wednesday. The Sov tried out doormen on Wednesdays, on a night slow enough that a mistake would only hurt a little.  _(office.ink:26)_
- `vo_teller_e9f5f2f0` Of the thirty days, it was the one nobody else remembered.  _(office.ink:27)_
- `vo_teller_2634e6ea` Except Gary. Gary was there first, and Gary told it for years, so it starts with Gary.  _(office.ink:28)_
- `vo_teller_849ad926` I didn't get the job. That's it. That's the story.  _(office.ink:505)_
- `vo_teller_f89468c4` That was how Gary told it. From the porch steps on, it goes the way the doorman told it, which was less often.  _(walk.ink:15)_

## The Father (`father`)

- `vo_father_4894833a` The ones they write NOT EVER about, they come back. They always come back. That's why somebody wrote it.  _(bar.ink:95)_
- `vo_father_dfb0b049` Every bar's got its rules and none of them are written down. The written ones are for the inspector.  _(bar.ink:109)_
- `vo_father_e6cf9337` That's the job. Not dealing with it. Not being seen to.  _(bar.ink:131)_
- `vo_father_194d30ae` One.  _(bar.ink:172)_
- `vo_father_4d58fba7` And Gary's, at four. Don't think I didn't count those.  _(bar.ink:174)_
- `vo_father_d263e689` Two. Two is how it starts. One is a drink and two is a decision.  _(bar.ink:181)_
- `vo_father_340cf74e` I stopped. You know I stopped. You know what it cost me to stop.  _(bar.ink:188)_
- `vo_father_8bf9f173` He's drunk.  _(bar.ink:318)_
- `vo_father_d8515133` You'll never see it again.  _(bar.ink:365)_
- `vo_father_492599a6` He'll have the till tape in the morning. You'll have said busy.  _(bar.ink:419)_
- `vo_father_87f04907` It isn't handled. Now it's a lie with a date on it.  _(bar.ink:436)_
- `vo_father_728c60d5` There. He spent it.  _(bar.ink:462)_
- `vo_father_b9dc27c3` Last call's easy. It's the half hour after it that's the job.  _(closing.ink:279)_
- `vo_father_ada7efd9` There. I told you he would.  _(closing.ink:434)_
- `vo_father_f4a2d8ff` I drove home drunk for twenty years. Nobody ever took my keys. I used to think that was respect.  _(closing.ink:436)_
- `vo_father_27f8241a` Nobody ever did that for me.  _(closing.ink:494)_
- `vo_father_011c77b6` I'd have hit anybody who tried.  _(closing.ink:495)_
- `vo_father_7418772d` You walked him to it. That's more than carrying a message.  _(closing.ink:540)_
- `vo_father_6af4a4d1` He went. You said it, and he went. I wouldn't have.  _(closing.ink:542)_
- `vo_father_5106edf2` He asked you one thing.  _(closing.ink:792)_
- `vo_father_97971abd` You took one set of keys tonight. You can't take four sets off table 28. You'd be taking the whole town's.  _(closing.ink:814)_
- `vo_father_cf0d1d0b` You took one set of keys tonight. You can't take five sets off table 28. You'd be taking the whole town's.  _(closing.ink:814)_
- `vo_father_63cd611c` You can't take four sets off table 28. You'd be taking the whole town's.  _(closing.ink:814)_
- `vo_father_723de66b` You can't take five sets off table 28. You'd be taking the whole town's.  _(closing.ink:814)_
- `vo_father_502099a1` A door's only a door when somebody's standing in it.  _(closing.ink:938)_
- `vo_father_bdc919c5` Good.  _(closing.ink:1090)_
- `vo_father_5ba9b7e4` Not tonight, I said. It's still tonight.  _(closing.ink:1314)_
- `vo_father_cc0b0499` Twenty years nobody took my keys. The one night somebody did, I'd have walked back for them too.  _(closing.ink:1333)_
- `vo_father_d3e179ba` Go back up.  _(closing.ink:1405)_
- `vo_father_81884f1e` Every bar I worked had an arrangement with somebody. The owner, the cops, the bikers. This is the first one I'd have trusted to keep it.  _(closing.ink:1602)_
- `vo_father_62ee171b` You shouldn't have said that. Not because it was wrong. Because you meant it, and now it knows.  _(closing.ink:1643)_
- `vo_father_57b6fb91` Every door you leave open, something comes in. This time you know what.  _(closing.ink:1666)_
- `vo_father_f0427378` Don't let that in.  _(closing.ink:1785)_
- `vo_father_589083b4` The man on the docks, who told me he'd seen one. He had a good jacket too. I never asked his name either.  _(closing.ink:1837)_
- `vo_father_cd713f31` You told that kid I died before you worked it out.  _(closing.ink:1839)_
- `vo_father_3fdfeb23` Worked what out?  _(closing.ink:1840)_
- `vo_father_5279612e` I said that boy was high. He hadn't slept. I was wrong about him.  _(closing.ink:1842)_
- `vo_father_81107ef4` I don't say that. Don't get used to it.  _(closing.ink:1843)_
- `vo_father_9b0d7916` The phone in the hall. There's nobody on the other end of that. I used to pick it up anyway.  _(closing.ink:1845)_
- `vo_father_db56d8a5` He drove. Lie there and listen for the sirens. I'll listen with you. I owe somebody that.  _(closing.ink:1847)_
- `vo_father_78a4315f` It helped everybody else, you told him. That's the nicest thing you ever said about me, and you said it to a stranger in a toilet.  _(closing.ink:1849)_
- `vo_father_bfc08f3d` Thirty years, she said, and not one of you ever stopped him at the door.  _(closing.ink:1851)_
- `vo_father_538233bf` I'd have hated any man who tried. I'd have gone home, though.  _(closing.ink:1852)_
- `vo_father_5bb0a327` You pushed it back. I never pushed one back in my life. I just stopped picking them up.  _(closing.ink:1854)_
- `vo_father_ed34a965` Tuesdays at seven. You looked at that one longer than you looked at the phone numbers.  _(closing.ink:1856)_
- `vo_father_a2b7d6c7` Tuesdays at seven. I wonder if it's still the same coffee.  _(closing.ink:1858)_
- `vo_father_b360d43c` Not one. Not one, all night. I don't know what to do with that.  _(closing.ink:1862)_
- `vo_father_d16f8335` You'll do. That's what I'd have said. You'll do.  _(closing.ink:1864)_
- `vo_father_ff5f5dda` Now they come past you or they don't come.  _(deck.ink:50)_
- `vo_father_5b1b4223` The kid you turned away. He didn't go home. He came round the back, and he brought his family.  _(deck.ink:58)_
- `vo_father_0795ea1d` He's asking you. He doesn't know he's asking you.  _(deck.ink:121)_
- `vo_father_0f2b9673` You put him out and let him back in. Now he knows what your out is worth.  _(deck.ink:172)_
- `vo_father_4e66a6d0` You walked the doors. You stood at that one and left the coaster in it.  _(deck.ink:183)_
- `vo_father_cd51daaa` The deck. You knew about the coaster.  _(deck.ink:185)_
- `vo_father_eea6faac` You looked right at that coaster and left it in.  _(deck.ink:347)_
- `vo_father_3615757b` You left the coaster in.  _(deck.ink:349)_
- `vo_father_17a1eecb` Half an hour, she gave you. That's more than I ever gave anybody.  _(door.ink:27)_
- `vo_father_21adaf75` A picture of a card isn't a card.  _(door.ink:120)_
- `vo_father_beb2203f` Now you know something you weren't handed.  _(door.ink:147)_
- `vo_father_a3c1455c` Look at his eyes. Red, and too wide. He's on something, and he's been on it a while. You don't let that in on a Wednesday to see what it does.  _(door.ink:152)_
- `vo_father_87bd35d9` Can't read him. That's a read. Something's wrong with a man who won't look at you.  _(door.ink:158)_
- `vo_father_9c034f71` That's it. You get a minute with each of them. Be decent in it, and the no goes down easier.  _(door.ink:183)_
- `vo_father_d0ef6d71` Then it's in the truck, and so is he.  _(door.ink:199)_
- `vo_father_32b316be` He's not here to drink. He's here for somebody inside. That's worse.  _(door.ink:222)_
- `vo_father_f8ab46b4` There's a coaster in the deck door. You know that.  _(door.ink:291)_
- `vo_father_5e531681` His sister's still out there with the engine running. Wonder why.  _(door.ink:313)_
- `vo_father_7f909d84` Can't. He said can't first.  _(door.ink:337)_
- `vo_father_ba5ade73` So that's whose they are.  _(door.ink:394)_
- `vo_father_a9b0ed9e` The big one with the left hand.  _(door.ink:402)_
- `vo_father_83751f48` He never answered either.  _(door.ink:413)_
- `vo_father_b605c882` It's always in the other pants.  _(door.ink:433)_
- `vo_father_0565498c` You lied for a drunk to his daughter. He'll thank you for it. Remember that he did.  _(door.ink:465)_
- `vo_father_abefd58f` You let the weather in.  _(door.ink:567)_
- `vo_father_7ec80818` Now it's your errand. You carry it right or you carry it wrong, but you're carrying it.  _(door.ink:586)_
- `vo_father_557a4b2e` Four. Maybe five. Tired, not drunk. He'll be fine till someone makes him not fine.  _(door.ink:631)_
- `vo_father_6ef5e2ee` Drunk.  _(door.ink:633)_
- `vo_father_cfb86224` Then he can take it upstairs through the hotel door. Like he'd do anyway if you weren't here.  _(door.ink:661)_
- `vo_father_1df193e2` And he'll come down the back stairs through the hotel door and you'll never know. Unless you lock it.  _(door.ink:694)_
- `vo_father_fefcb73d` Too clean for a Wednesday.  _(door.ink:771)_
- `vo_father_15e8f757` There it is.  _(door.ink:822)_
- `vo_father_1e0a6219` One. You said one. He heard you, and so did she.  _(door.ink:866)_
- `vo_father_6beeeda0` You weren't on the door. This is what not being on the door costs.  _(door.ink:914)_
- `vo_father_8cd39fa0` One, you said.  _(door.ink:976)_
- `vo_father_a3e865e8` One was the deal. Now there isn't a deal. There's just him.  _(door.ink:1011)_
- `vo_father_a80411fd` You lied for a drunk to his wife. Remember that you did that.  _(door.ink:1051)_
- `vo_father_5f52abb5` All true. I told you.  _(drawer.ink:174)_
- `vo_father_329edc9e` That's how you find out what the room thinks of your door.  _(floor.ink:302)_
- `vo_father_5da0ba18` The Manual's right about table 28 and it doesn't matter. Nobody cuts off table 28. You'll see.  _(floor.ink:357)_
- `vo_father_db380816` He'll open it again.  _(floor.ink:442)_
- `vo_father_054bea4a` Now he's broke and angry instead of high and angry. That's your call. It's not a good one or a bad one. It's just yours.  _(hall.ink:119)_
- `vo_father_4403f561` You just left a lit match in the room.  _(hall.ink:126)_
- `vo_father_222b7a76` Good. Rules.  _(hall.ink:244)_
- `vo_father_70e02a79` That's mine to tell. Not yours.  _(hall.ink:345)_
- `vo_father_6eae3a5b` ...  _(hall.ink:356)_
- `vo_father_e5623db5` That's what I'd have done. Picked the cue back up.  _(hall.ink:425)_
- `vo_father_1662043f` He went. I wouldn't have.  _(hall.ink:444)_
- `vo_father_b34aa957` I went to those.  _(hall.ink:456)_
- `vo_father_c349d229` For a year. Then I stopped going and kept on not drinking, and everybody said that was worse. They were probably right.  _(hall.ink:457)_
- `vo_father_7fb59afe` She told you not to tell him she told you. You told him.  _(hall.ink:497)_
- `vo_father_ecfd3bd2` That's the door. Everybody through it. Even the ones who live here.  _(hall.ink:522)_
- `vo_father_89aea30d` He's not losing. He's paying. That's a debt, going across the rail twenty at a time, so neither of them has to say what it's for.  _(pool.ink:121)_
- `vo_father_356f7464` And he's drinking doubles out of a pint of cola so it looks like one drink. I did that for six years.  _(pool.ink:122)_
- `vo_father_4c561945` He's bad at pool.  _(pool.ink:124)_
- `vo_father_e8b8e2d0` He throws everything. Watch what he's keeping.  _(pool.ink:207)_
- `vo_father_a803b901` That's his.  _(pool.ink:235)_
- `vo_father_5b14ea3e` He's had enough of you for one night. You did that at the door.  _(pool.ink:259)_
- `vo_father_0849b624` Not in front of his friend. Never tell a man anything in front of his friend.  _(pool.ink:294)_
- `vo_father_36667c24` You carried it right.  _(pool.ink:375)_
- `vo_father_50ffb71f` I never would have gone.  _(pool.ink:376)_
- `vo_father_5454298e` He's not coming. I wasn't.  _(pool.ink:393)_
- `vo_father_752f2f58` That's the voice. You've got it or you haven't.  _(pool.ink:525)_
- `vo_father_0db2a7df` Now it's on paper. Now it's the owner's night, and the owner's insurance.  _(pool.ink:583)_
- `vo_father_e9243fa1` Sometimes you throw a man out and it's the kindest thing anybody's done for him all year.  _(pool.ink:603)_
- `vo_father_b8ff0217` They'll follow him all the way home like that. Kids do. I know.  _(pool.ink:607)_
- `vo_father_3631d707` Fair. Fair's not the same as right.  _(pool.ink:645)_
- `vo_father_766c1f73` You told it straight to a cop. Remember what it felt like. You won't always.  _(pool.ink:719)_
- `vo_father_9b55e758` She knows. They always know. She's just got eleven other calls.  _(pool.ink:728)_
- `vo_father_a7ef2a2c` You gave her the hard part. She'll remember whose part it was.  _(pool.ink:734)_
- `vo_father_e0c79261` You haven't earned that across a room yet.  _(pool.ink:800)_
- `vo_father_0e7df2a3` Two hours and a half. It's told you all it's going to from out there.  _(prologue.ink:27)_
- `vo_father_1fbf6143` Look at a building before you go into it. It'll tell you what kind of night it has.  _(prologue.ink:29)_
- `vo_father_fe91494b` Two at four o'clock. That's one still in you, whatever you think.  _(prologue.ink:36)_
- `vo_father_87788e0c` Count the room before it counts you. Those five in the window already think they own you.  _(prologue.ink:93)_
- `vo_father_fd9a23e0` Four doors, and one of them's yours. That's three you're answerable for and can't see.  _(prologue.ink:119)_
- `vo_father_719fa18b` Heads first. Then faces. Then hands. Then the doors.  _(prologue.ink:148)_
- `vo_father_fef17431` He's not wrong. A week of stink in a bar is a week of nobody coming in.  _(rats.ink:95)_
- `vo_father_738c4999` Remove food sources. In a kitchen.  _(rats.ink:114)_
- `vo_father_6694f20a` That's how everybody leaves a door. The way they found it.  _(rats.ink:162)_
- `vo_father_b92a9652` Every bar. Every single bar.  _(rats.ink:240)_
- `vo_father_dc4299a2` Now it's yours. That's what wiping it does.  _(rats.ink:263)_
- `vo_father_d0d042c8` Where the cook said. He'll hear you listened.  _(rats.ink:296)_
- `vo_father_5e579edb` Poison's how you do it when you don't want to be there when it happens.  _(rats.ink:330)_
- `vo_father_13fcf9c8` You'll catch three, the cook said.  _(rats.ink:340)_
- `vo_father_1a794dc3` Along the wall. They run the walls. They don't cross open floor if they can help it.  _(rats.ink:346)_
- `vo_father_e60014af` You know what'll walk into that first.  _(rats.ink:358)_
- `vo_father_f3c18949` Don't go in there.  _(rats.ink:405)_
- `vo_father_ea548499` A man on the docks told me he'd seen one, once. We all said he was drunk. He was drunk.  _(rats.ink:438)_
- `vo_father_7c83f057` No. It had you.  _(rats.ink:449)_
- `vo_father_6dfacd74` You're paying them. There's a difference, and they know it.  _(rats.ink:510)_
- `vo_father_ced8a0bd` They took it home. That's where they'll die, in the walls where you can't get at them. Then you'll smell it.  _(rats.ink:522)_
- `vo_father_04e06cd9` One. Out of however many there are.  _(rats.ink:529)_
- `vo_father_318b35f4` Do the job that's in front of you. The rest comes to you.  _(rats.ink:550)_
- `vo_father_3fba728c` Whatever you do, do it like it's nothing.  _(rats.ink:567)_
- `vo_father_483a587a` Keep your voice down and people will believe anything you tell them.  _(rats.ink:613)_
- `vo_father_0331ab13` You didn't have to watch it. You watched it.  _(rats.ink:653)_
- `vo_father_ce755d2d` And you put down more. So it's yours now.  _(rats.ink:674)_
- `vo_father_7b55ba25` You put it down. So this is yours.  _(rats.ink:676)_
- `vo_father_d59f9fd9` That's the least you owed it.  _(rats.ink:713)_
- `vo_father_79bab2e6` Now it's the owner's rat and your hand. Tables remember the hand.  _(rats.ink:750)_
- `vo_father_1dd7efc0` They won't mention it. That's not the same as forgetting it.  _(rats.ink:783)_
- `vo_father_da8706b5` Glasses off the rail. Every one you carry is one nobody throws.  _(room.ink:43)_
- `vo_father_363686c6` You saw it lying there. You left it lying there.  _(room.ink:175)_
- `vo_father_ffeb06ed` You never went near that corner to see what was lying in it.  _(room.ink:177)_
- `vo_father_67712d31` You haven't earned her remote. You haven't earned her ice.  _(room.ink:230)_
- `vo_father_bf0f1125` Give a room something to look at, and it won't look at you.  _(room.ink:264)_
- `vo_father_ad7eb31f` TV off is how you close a room. It's not how you keep one.  _(room.ink:302)_
- `vo_father_ae9d6164` Never take a side at a table. You'll be sitting at it for life.  _(room.ink:347)_
- `vo_father_7e4b52d4` The floor inside the door is the door's. Anybody goes down on it, they went down on you.  _(room.ink:390)_
- `vo_father_b80418c5` He's got one on you now. Watch him spend it.  _(room.ink:423)_
- `vo_father_eb0183c0` Nobody reads those till the night they need one.  _(room.ink:463)_
- `vo_father_eb34ef43` Lights up, music down. Nobody stays in a room they can see.  _(room.ink:513)_
- `vo_father_18c205de` She can wait. I said that for twenty years.  _(room.ink:588)_
- `vo_father_c68a5e3c` He went. That's the part they'll remember.  _(room.ink:670)_
- `vo_father_97fec02a` You heard it ringing in there. So did whoever took it.  _(room.ink:681)_
- `vo_father_9c0ea691` Somebody came in past your stool tonight that you never saw. They saw the coat.  _(room.ink:683)_
- `vo_father_0a981561` He's been in twice tonight now. The second time, you held the door.  _(room.ink:778)_
- `vo_father_5839a2fe` He'll call. That kind always calls.  _(room.ink:785)_
- `vo_father_55c8d399` Now he owns a piece of you. Fifty dollars' worth.  _(room.ink:809)_
- `vo_father_c024f44e` Fifty dollars. That's what you cost.  _(room.ink:817)_
- `vo_father_92c349c6` They'll hold you to that, you know. Ten years. Somebody here knows somebody in the city.  _(table28.ink:57)_
- `vo_father_46f9d37c` Don't.  _(table28.ink:67)_
- `vo_father_a86d30ac` Now it's out.  _(table28.ink:78)_
- `vo_father_05cfa65b` Good. Stay standing. Once you sit at a table like that you're furniture.  _(table28.ink:98)_
- `vo_father_ca0594da` You know what that is.  _(table28.ink:110)_
- `vo_father_74182bc2` They're all true. That's how a place like this works. Every story's true and none of them happened.  _(table28.ink:151)_
- `vo_father_e4b6e414` That's the rat problem. It's eating a fry in front of you.  _(table28.ink:181)_
- `vo_father_764a003a` The rule is whoever pays for the carpet. I told you.  _(table28.ink:315)_
- `vo_father_df9042e8` You know why.  _(table28.ink:357)_
- `vo_father_32bb9927` You sat with your back to his door. Never sit with your back to a door.  _(walk.ink:21)_
- `vo_father_e2cf62e2` You turned his chair so you could see his door. Good. Somebody's always coming through it.  _(walk.ink:23)_
- `vo_father_9e835fa9` You made him reach for your licence. Good. Make them reach.  _(walk.ink:25)_
- `vo_father_d2cfd92e` You looked at his room before you sat down in it. Good.  _(walk.ink:27)_
- `vo_father_b741b755` Walk to a new door, the first time. See what they walk past to get to you.  _(walk.ink:31)_
- `vo_father_67d2fc18` Eat. You won't get the chance after.  _(walk.ink:80)_
- `vo_father_6a196c6e` Watch it from outside before you work it. Once you're in it, you're part of what you're watching.  _(walk.ink:150)_
- `vo_father_2419c31c` That's a man looking to see who's on the door.  _(walk.ink:156)_
- `vo_father_feeaebe8` An hour off the door. The door doesn't care that you had reasons.  _(barks.yaml door_hour_off)_
- `vo_father_5cd23cd4` His kid's twenty feet away and he knows exactly where.  _(barks.yaml pool_his_kid)_
- `vo_father_7dc4e5f7` His daughter's sitting out in that truck with the engine running, and he's chalking his cue.  _(barks.yaml pool_his_daughter_waiting)_
- `vo_father_4f432061` They'll keep them coming. That's how they pay you.  _(barks.yaml t28_leash)_
- `vo_father_03c935f6` I stopped at three once. Once.  _(barks.yaml bar_three)_
- `vo_father_b9d13017` That coaster's in the latch for somebody, and it isn't you.  _(barks.yaml deck_coaster)_
- `vo_father_179f570e` The ones who wait in the lot are the ones who remember you.  _(barks.yaml lot_remember)_
- `vo_father_4df2cd47` Nine. Whoever comes in after nine came to stay.  _(barks.yaml hour_nine)_
- `vo_father_3e3ac7b6` Half an hour to last call. Everything you let slide comes back now.  _(barks.yaml hour_one)_
- `vo_father_4728b683` Don't let them all talk at once.  _(barks.yaml tension_up_father)_
- `vo_father_44d2c82d` I'd have said less.  _(barks.yaml fail_father)_
- `vo_father_bc772324` The book's right more often than I ever let on.  _(barks.yaml pass_manual_father)_
- `vo_father_17cd5707` He got paid to fight. You get paid so there isn't one.  _(barks.yaml ans_father_fighter_1)_
- `vo_father_addd2769` The first one decides it. Then the police decide the rest.  _(barks.yaml ans_father_fighter_2)_
- `vo_father_ff98424c` Book's right. It just won't be standing next to you.  _(barks.yaml ans_father_manual_1)_
- `vo_father_c84a3019` Listen to it. I didn't, and I learned all of it the long way.  _(barks.yaml ans_father_manual_2)_
- `vo_father_801cef60` Drunks tell it better than it happened. Doesn't mean it didn't.  _(barks.yaml ans_father_wrongman_1)_
- `vo_father_4660d5eb` Every door I worked had a story like that. Every one of them was true somewhere.  _(barks.yaml ans_father_wrongman_2)_
- `vo_father_8941e421` Water under the laminate, and the picture still moves through it. Wet. Not fake.  _(barks.yaml toy_hoodie_card_tilt)_
- `vo_father_bebf6d48` It's real. They mostly are. Now hold it up by her face. The card was never the question.  _(barks.yaml toy_driver_card_tilt)_
- `vo_father_de56e1fe` Turn it over. The ones who make them never bother with the back.  _(barks.yaml toy_card_flip)_
- `vo_father_8cc43d7d` Card, then face. Look at the ears. People change their hair. Nobody changes their ears.  _(barks.yaml toy_card_look_father)_
- `vo_father_14cc5209` Same card as page three. He's not hiding from anybody.  _(barks.yaml toy_goodshoes_look_known)_
- `vo_father_d85917d3` Darts are fine till somebody's drinking. Then they're three knives and a reason.  _(barks.yaml look_dartboard)_
- `vo_father_64def61b` Every door's got its exceptions. They're just not on the sign.  _(barks.yaml look_id_sign)_
- `vo_father_daf62c91` Whoever turns that dial up, the room hates for a minute. Better you than her.  _(barks.yaml look_dimmer)_
- `vo_father_619f196e` Never run on the floor. A doorman running tells the whole room there's trouble, and then the room goes looking for it.  _(barks.yaml legs_ran_father)_
- `vo_father_8677901c` They talk about you so you'll hear it. Don't let them see you heard it.  _(barks.yaml ears_new_kid)_
- `vo_father_e1de8cad` That's not a funny drunk. That's a drunk they're used to.  _(barks.yaml ears_dennis)_
- `vo_father_a85de6d5` A man who says the owner's name twice wants you to hear it once.  _(barks.yaml ears_goodshoes)_
- `vo_father_680bac82` Eyes on the door. The sky's somebody else's job.  _(barks.yaml ears_light)_
- `vo_father_173b3394` Nobody has to take the first one.  _(barks.yaml hand_drink_first)_
- `vo_father_de8d41d5` I know that hand. I had that hand.  _(barks.yaml hand_drink_hand)_
- `vo_father_2bbddf01` You're counting the door. Count these.  _(barks.yaml hand_drink_count)_
- `vo_father_9cb92f31` You looked at it, though.  _(barks.yaml hand_resisted_drink_father)_
- `vo_father_b5019477` I wrote mine so they read better. For years.  _(barks.yaml hand_shade_father)_
- `vo_father_2a2ecdbd` What you leave out, you carry.  _(barks.yaml hand_omit_father)_
- `vo_father_6cf2bad4` That's how it happened. Leave it like that.  _(barks.yaml hand_resisted_shade)_
- `vo_father_931cab0d` Put it all in. You'll sleep.  _(barks.yaml hand_resisted_omit)_
- `vo_father_8f1362b6` Hands down till you've said something.  _(barks.yaml hand_check_fighter_father)_
- `vo_father_b4006add` I've stood where you're standing. Let me.  _(barks.yaml hand_check_father_own)_
- `vo_father_8a295343` You learned that from me. Putting people out.  _(barks.yaml hand_out_father)_
- `vo_father_4b5d83da` They'll sit in your head the way they sit in those chairs. For good.  _(barks.yaml hand_in_table_father)_
- `vo_father_27381add` Somebody walks in the second you go.  _(barks.yaml hand_door_father)_
- `vo_father_35839cbc` Walk over slow. Let him see you coming.  _(barks.yaml hand_loc_pool_father)_
- `vo_father_a9688489` They'll pour and you'll drink. That's the table.  _(barks.yaml hand_loc_t28)_
- `vo_father_0aa86c3e` Nobody waits in a lot for a good reason.  _(barks.yaml hand_loc_lot)_
- `vo_father_dde36da8` Washrooms. Look under the doors. Feet tell you everything.  _(barks.yaml hand_loc_hall)_
- `vo_father_5882a0d1` You're not going over there for water.  _(barks.yaml hand_loc_bar)_
- `vo_father_a18e8bfa` Pick one and stand by it.  _(barks.yaml hand_wait_father)_
- `vo_father_87109e53` Don't look back there. Look at the door.  _(barks.yaml hand_reread_father)_
- `vo_father_ac5f5a82` You went somewhere.  _(barks.yaml hand_back_father)_
- `vo_father_a346975e` Slow down. You're not reading them.  _(barks.yaml hand_rush_father)_
- `vo_father_90bb4e05` They don't know it's you shaking them.  _(barks.yaml hand_shake_father)_

Changing with the night (record the bark instead, or ask for these to be split):

- {Num(drinks)}. After hours still counts.  _(closing.ink:1070)_
- {Num(drinks)}. I counted. You'll count them again tomorrow, in the mirror.  _(closing.ink:1860)_
- {Num(drinks)}. I counted. You're counting too, or you should be.  _(table28.ink:236)_

## The Manual (`manual`)

- `vo_manual_5e308e5d` Memorise the barred list at the start of every shift. Page three. Page seven. Page eleven, the one with the tattoo on his neck.  _(bar.ink:87)_
- `vo_manual_faf7eb0b` Licensed hours end at two. Every minute after that is the licensee's problem, and yours.  _(closing.ink:295)_
- `vo_manual_c15310f8` A licensee who knowingly allows an intoxicated patron to drive may be held liable.  _(closing.ink:554)_
- `vo_manual_01e7beb5` Keys held by staff are held for the licensee. The patron's condition is assessed at the time of return.  _(closing.ink:1316)_
- `vo_manual_d774cde6` The licensee's duty of care ends at the door of the licensed premises. You are past it.  _(closing.ink:1699)_
- `vo_manual_7f6202e9` Nothing to report. The manual has no section on how that feels.  _(closing.ink:1815)_
- `vo_manual_5b565abe` The incident log is a legal document. Every entry in it is accurate. This is rarer than you would think.  _(closing.ink:1821)_
- `vo_manual_789c7ab5` Three persons on the premises who were not admitted. One refused entry. One with no identification presented.  _(deck.ink:187)_
- `vo_manual_3f2cf70b` For the record, one of them has no identification.  _(deck.ink:235)_
- `vo_manual_0fcb74cb` Acceptable identification is a valid government-issued card with a photograph, presented in person. When in doubt, two pieces. You're in doubt.  _(door.ink:121)_
- `vo_manual_82b110a0` Nineteen by three weeks. Legal. The photograph is still not identification.  _(door.ink:135)_
- `vo_manual_138c7db4` The scanner reads cards. It does not read photographs of cards. The scanner is, in this respect, correct.  _(door.ink:230)_
- `vo_manual_b1ed969b` The scanner keeps a record of every card it is shown, with the time. It now has two of these.  _(door.ink:235)_
- `vo_manual_293ba8a1` For the record, you did not verify his age.  _(door.ink:261)_
- `vo_manual_4f837ca8` For the record, you verified his age from a photograph. The record will say photograph.  _(door.ink:263)_
- `vo_manual_90aebd60` Valid. Nineteen. Thank you.  _(door.ink:310)_
- `vo_manual_e69de38c` Photograph matches bearer. Valid.  _(door.ink:396)_
- `vo_manual_6da43043` For the record: an hour ago he was refused for want of a card. He still has no card.  _(door.ink:505)_
- `vo_manual_218b1148` You asked him for identification. He had none. He is now inside, and ordering.  _(door.ink:562)_
- `vo_manual_f64b5cf2` The one with no identification is now inside and ordering.  _(door.ink:565)_
- `vo_manual_921323ee` Speech clear. Gait steady within reason. Eyes glassy. Odour of alcohol. Carrying alcohol, which may not be brought onto licensed premises. Refuse entry with the product, or require him to leave it.  _(door.ink:640)_
- `vo_manual_896dd9a2` Refer to section four. Signs of intoxication include, but are not limited to, the following.  _(door.ink:642)_
- `vo_manual_25eac0ba` You told him he could not bring it in. Then he brought it in. She heard both.  _(door.ink:673)_
- `vo_manual_0889489b` Binder. Page three. Photocopy of a licence. Barred.  _(door.ink:751)_
- `vo_manual_b512ccc4` Valid. Fifty-one years of age. The scanner does not check the barred list. The barred list is in a binder, under the till.  _(door.ink:778)_
- `vo_manual_faa88ac5` Binder. Page three. Barred.  _(door.ink:788)_
- `vo_manual_348ae378` The owner is unavailable. The barred list is available.  _(door.ink:844)_
- `vo_manual_4c45b3e3` You are not required to disclose the identity of any patron.  _(door.ink:1036)_
- `vo_manual_4dd0b3b0` Refer to privacy.  _(door.ink:1039)_
- `vo_manual_0a746fd6` Occupancy is within the licensed maximum. Occupancy is far within the licensed maximum. It's Wednesday.  _(floor.ink:305)_
- `vo_manual_62b055af` The big man at the pool table is drinking doubles and pouring them into a pint of cola so they look like one drink.  _(floor.ink:354)_
- `vo_manual_26ccf855` Everyone is drinking. That is the purpose of the premises.  _(floor.ink:359)_
- `vo_manual_19f8a2e6` Access between the licensed premises and the residential floors should be controlled.  _(floor.ink:412)_
- `vo_manual_c04ef0ff` The licensee must not permit the use of illicit drugs on the premises. Remove the person. Record the incident.  _(hall.ink:94)_
- `vo_manual_8d1a6a11` Staff may enter a locked washroom where there is reasonable concern for a patron's safety.  _(hall.ink:253)_
- `vo_manual_1919e7be` Correct.  _(pool.ink:582)_
- `vo_manual_5257a251` The licensee's duty of care begins at the threshold. You are the threshold.  _(prologue.ink:95)_
- `vo_manual_f5cc1277` A single sighting indicates an established population.  _(rats.ink:89)_
- `vo_manual_4669ad6d` Evidence of rodent activity. Droppings, fresh, concentrated along the wall. Gnaw marks at the base of the door frame. Grease marks at the pipe penetration. The pipe penetration is not sealed.  _(rats.ink:110)_
- `vo_manual_e10f812e` Seal all penetrations. Remove food sources. Then bait.  _(rats.ink:113)_
- `vo_manual_25584ffe` Harbourage outside the premises. Keep dumpster lids closed.  _(rats.ink:140)_
- `vo_manual_7b8e50c3` The use of controlled substances by staff on the premises is grounds for dismissal and must be recorded.  _(rats.ink:241)_
- `vo_manual_c6efae65` Wear gloves. Place in tamper-resistant stations only. Never where it can contaminate food.  _(rats.ink:289)_
- `vo_manual_c151a10b` Never where it can contaminate food.  _(rats.ink:302)_
- `vo_manual_bfa129d0` Chewed wiring is a fire hazard. The inspector will close you for the wiring before he closes you for the rats.  _(rats.ink:403)_
- `vo_manual_234c1895` There is no section for this.  _(rats.ink:437)_
- `vo_manual_72563397` Rat bites carry a serious risk of infection. Seek medical attention.  _(rats.ink:455)_
- `vo_manual_60c567ec` Bait uptake indicates an active population. Replenish.  _(rats.ink:521)_
- `vo_manual_66355b27` Slide a coaster underneath.  _(rats.ink:596)_
- `vo_manual_a1dfd92f` Anticoagulant bait causes internal bleeding over several days. Affected animals become lethargic, disoriented and thirsty, and may be seen in the open.  _(rats.ink:671)_
- `vo_manual_f65a215b` Several days. This one ate bait somebody put down before you came.  _(rats.ink:673)_
- `vo_manual_81e69beb` Where a weapon is used on licensed premises, police are called. There is no discretion.  _(room.ink:173)_
- `vo_manual_b03a6173` A hazard that cannot be removed must be marked. Marking a hazard is not removing it.  _(room.ink:404)_
- `vo_manual_9bdd67cc` Portable extinguishers are inspected monthly and serviced annually by a certified technician. The tag is the record.  _(room.ink:462)_
- `vo_manual_af80632f` The presence of rodents in a food service area is a violation. The feeding of rodents by patrons is not addressed in the manual.  _(table28.ink:182)_
- `vo_manual_bf98c2d0` A licensee must not permit a person to become intoxicated on the premises. They were intoxicated at two o'clock.  _(table28.ink:301)_
- `vo_manual_5bc70b53` The rule is still the rule.  _(table28.ink:314)_
- `vo_manual_8ec08168` A choice with a voice's name on it is a check. That voice makes the call, and two dice have to reach the number beside it. The odds are printed. Read them.  _(barks.yaml teach_check)_
- `vo_manual_51bc8c63` When the voices are at odds it gets loud in here, and loud makes every roll swing wider, good and bad. The average does not move. See diagram.  _(barks.yaml teach_tension)_
- `vo_manual_ab7c0f73` Every group on the premises keeps its own opinion of staff, by its own rules. You will not be told what they think. You will hear what they say.  _(barks.yaml teach_word)_
- `vo_manual_d25e73aa` Occupancy in here is limited to five. Some choices let a voice in or put one out. The note under the choice says what it will do to the noise.  _(barks.yaml teach_room)_
- `vo_manual_91711040` Before you commit to a choice, rest a hand on it. Point at it, or press and hold. A voice with something to say about it will say it.  _(barks.yaml teach_hand)_
- `vo_manual_07d30d58` Maintain a visible presence at the point of entry. Visible means sitting up.  _(barks.yaml door_first_quiet)_
- `vo_manual_7a389944` De-escalation is most effective before physical contact. Before is now.  _(barks.yaml pool_early)_
- `vo_manual_07991622` Nobody has ever been refused service at this table. There is no section for that.  _(barks.yaml t28_never_cut)_
- `vo_manual_06a72daf` Check washrooms at regular intervals and record the time. You have not been recording the time.  _(barks.yaml hall_intervals)_
- `vo_manual_a4b70973` Exterior doors must not be propped open during licensed hours.  _(barks.yaml kitchen_propped)_
- `vo_manual_98f51037` Inspect bait stations daily. Record uptake.  _(barks.yaml keg_stations)_
- `vo_manual_3f90e988` Staff shall not consume alcohol while on duty. You will be the one writing the log.  _(barks.yaml drink_log)_
- `vo_manual_41514c9f` After eleven, walk the premises at least once an hour.  _(barks.yaml hour_eleven)_
- `vo_manual_2cc83d22` Quieter.  _(barks.yaml tension_down_manual)_
- `vo_manual_f723ff64` This was covered on the Saturday. You were at the back.  _(barks.yaml fail_manual)_
- `vo_manual_4f3acac2` Consistent with the course material.  _(barks.yaml ans_manual_father_1)_
- `vo_manual_0f3f8235` That is in the binder as well. With a diagram.  _(barks.yaml ans_manual_father_2)_
- `vo_manual_a6db69ed` Force must be reasonable, necessary and proportionate. He has not read those words.  _(barks.yaml ans_manual_fighter_1)_
- `vo_manual_435f45a5` Physical intervention is last on the list. It is last for a reason.  _(barks.yaml ans_manual_fighter_2)_
- `vo_manual_021eab9d` An anecdote is not evidence. Record what you observe.  _(barks.yaml ans_manual_wrongman_1)_
- `vo_manual_dd42be8e` The incident log has no field for a feeling.  _(barks.yaml ans_manual_wrongman_2)_
- `vo_manual_aad89931` Tip it under the light. On a real one the hologram moves. On a printed one it sits there.  _(barks.yaml toy_card_tilt)_
- `vo_manual_648270ed` Genuine. The scanner agrees. Neither the hologram nor the scanner has read the binder under the till.  _(barks.yaml toy_goodshoes_card_tilt)_
- `vo_manual_265d3e2b` Born the fourteenth of October, two thousand and seven. Nineteen years and twenty-one days. Legal.  _(barks.yaml toy_hoodie_card_look)_
- `vo_manual_2e023dda` Photograph matches bearer. Fifty-one years of age. Valid.  _(barks.yaml toy_goodshoes_look_clean)_
- `vo_manual_8d28380a` Staff are advised to work out the date at the start of each shift. Arithmetic at the door is a leading cause of error.  _(barks.yaml look_tape)_
- `vo_manual_a07fbe14` Extinguishers are inspected monthly and the tag is punched. Read the tag.  _(barks.yaml look_extinguisher)_
- `vo_manual_c8d10acc` Staff will move through the licensed area at a walking pace. A running employee may itself occasion an incident.  _(barks.yaml legs_ran_manual)_
- `vo_manual_f47982bf` Staff are reminded that the ionosphere is outside the licensed premises.  _(barks.yaml ears_haarp)_
- `vo_manual_a1b0354b` Sightings of vermin are to be reported to the licensee, who will be glad to hear it.  _(barks.yaml ears_rat)_
- `vo_manual_d5ae52cd` Staff may accept a drink from a patron and hold it without drinking it. See Refusals.  _(barks.yaml hand_drink_manual)_
- `vo_manual_73952ab8` The incident log may be requested by the police, the owner or the licensing branch.  _(barks.yaml hand_shade_manual)_
- `vo_manual_0f1363d2` An incident that is not recorded is an incident the house cannot defend.  _(barks.yaml hand_omit_manual)_
- `vo_manual_2202a381` If you put hands on him, you write it up. All of it.  _(barks.yaml hand_check_fighter_manual)_
- `vo_manual_f1a4c516` This is covered. Page nine.  _(barks.yaml hand_check_manual_own)_
- `vo_manual_13001c6f` Observe what is in front of you, not what happened to somebody's brother.  _(barks.yaml hand_check_wrongman_manual)_
- `vo_manual_487affeb` Responsibility for the premises remains with you.  _(barks.yaml hand_out_manual)_
- `vo_manual_ed890ada` Your post is the door. It says so on the schedule.  _(barks.yaml hand_door_manual)_
- `vo_manual_46e27ba9` Nobody asked you to go back there.  _(barks.yaml hand_loc_keg)_
- `vo_manual_f7926bfc` A propped door is an unmonitored entrance.  _(barks.yaml hand_loc_deck)_
- `vo_manual_92b294f2` Somebody propped it. The log will want to know who.  _(barks.yaml hand_loc_kitchen)_
- `vo_manual_4c86f091` They are still standing there.  _(barks.yaml hand_wait_door)_
- `vo_manual_78a7f550` Reviewing the log is good practice. The shift is still on.  _(barks.yaml hand_reread_manual)_
- `vo_manual_db7c7d8e` Nothing was logged while you were away.  _(barks.yaml hand_back_manual)_
- `vo_manual_3090aca2` You are not reading.  _(barks.yaml hand_rush_manual)_
- `vo_manual_5ce73d16` How long they are shaken has no bearing on the outcome.  _(barks.yaml hand_shake_manual)_

Changing with the night (record the bark instead, or ask for these to be split):

- The incident log is a legal document. {Num(LIST_COUNT(left_out))} {LIST_COUNT(left_out) == 1:incident is\|incidents are} not in it.  _(closing.ink:1817)_
- The incident log is a legal document. It now contains {num(LIST_COUNT(shaded))} {LIST_COUNT(shaded) == 1:statement\|statements} that {LIST_COUNT(shaded) == 1:is\|are} not quite true.  _(closing.ink:1819)_
- Table 28 are on round {t28_rounds} since two o'clock. By any written standard, all {dennis_gone():four\|five} are intoxicated. By any written standard, you should refuse them service.  _(floor.ink:352)_

## The Wrong Man (`wrongman`)

- `vo_wrongman_bff35b1d` Everybody said that about somebody, in the story.  _(bar.ink:121)_
- `vo_wrongman_8f337edc` Talk about it. With who.  _(bar.ink:325)_
- `vo_wrongman_140bf510` Or you will, and it'll be the worst twenty you ever got back.  _(bar.ink:366)_
- `vo_wrongman_501f3c6f` Twenty dollars. In the story it was always about twenty dollars, once you got to the bottom of it.  _(bar.ink:376)_
- `vo_wrongman_d828329a` Everybody in the story drove home. Everybody always does, until the one who doesn't.  _(closing.ink:555)_
- `vo_wrongman_d322f6c4` The last one. He made it last four hours. In the story there was always one who did that.  _(closing.ink:579)_
- `vo_wrongman_4bf8f37f` Every door you lock, you end up holding open for somebody.  _(closing.ink:670)_
- `vo_wrongman_592b061c` After, he said. When it's quiet.  _(closing.ink:687)_
- `vo_wrongman_556c5543` The one you didn't count. It's always the one you didn't count.  _(closing.ink:945)_
- `vo_wrongman_4858f4db` In the story, the doorman opened the door. In the story, the doorman always opens the door.  _(closing.ink:1320)_
- `vo_wrongman_b56a4e21` This is the story. This is the one they'll tell about you.  _(closing.ink:1406)_
- `vo_wrongman_166afaa1` You bargained with it. In the story nobody bargained. That's why it's a story.  _(closing.ink:1617)_
- `vo_wrongman_80bc152e` Day one. In the story the deal was broken on day one, too. That's how you knew it was a deal.  _(closing.ink:1669)_
- `vo_wrongman_e713a783` Somebody got in tonight you never saw. In the story there was always one.  _(closing.ink:1825)_
- `vo_wrongman_a01af004` Nobody believes the one who saw it. So don't say.  _(closing.ink:1827)_
- `vo_wrongman_19c6c424` You went down. In the story he went down too. Nobody remembered what he said down there, only that he came back up.  _(closing.ink:1829)_
- `vo_wrongman_1383b47f` You didn't ask her which story was true. Good. In the story, the one who asks is the next one gone.  _(closing.ink:1831)_
- `vo_wrongman_180ff7b4` Wednesday. Nothing happens on a Wednesday. That's what they'll say.  _(closing.ink:1833)_
- `vo_wrongman_1d0a13c4` Everybody in that story came in out of the rain. Every one of them.  _(door.ink:122)_
- `vo_wrongman_59ad02f9` The wrong one's never the one in front of you. That's the whole story. Look at who's waiting.  _(door.ink:166)_
- `vo_wrongman_b703a6d6` Could be anyone in there. In the story it could have been anyone. That was the point.  _(door.ink:171)_
- `vo_wrongman_9c7f1a75` He had a nice face, the one in the story. Everybody said so after.  _(door.ink:772)_
- `vo_wrongman_29d7b455` He'd paid for it. They always had.  _(door.ink:837)_
- `vo_wrongman_3bcaef6c` That's how it starts in the story. You don't know. That's the whole point of the story.  _(door.ink:886)_
- `vo_wrongman_789e001b` The last one. Everybody in the story had a last one. Some of them had six.  _(door.ink:1004)_
- `vo_wrongman_2e8be3f1` In the story, they find his jacket. They never find him.  _(drawer.ink:178)_
- `vo_wrongman_8b17bffa` Count the one you didn't count. That's who it always is.  _(floor.ink:320)_
- `vo_wrongman_95d36b10` The night clerk will prop it again the minute you're gone. That's the story of every door.  _(floor.ink:413)_
- `vo_wrongman_c31be18b` The night clerk will wedge it again the minute you're gone. That's every door.  _(hall.ink:65)_
- `vo_wrongman_3c6e2751` In the story he saw it too, and said nothing too. That's how the story starts.  _(hall.ink:131)_
- `vo_wrongman_e08d6097` That's an invitation. In the story nobody ever got one.  _(hall.ink:227)_
- `vo_wrongman_2072b0af` The wrong man was the one doing the reading.  _(hall.ink:285)_
- `vo_wrongman_eda59bf6` Ask it like you already know. People answer what you already know.  _(pool.ink:279)_
- `vo_wrongman_bb82276a` A transmission. In a tip jar.  _(pool.ink:373)_
- `vo_wrongman_a7d77e63` In the story, the doorman carried a message once, and the man said he'd come after, and he did come after. And that was worse.  _(pool.ink:419)_
- `vo_wrongman_47ea0a10` The wrong man's never the one you're watching.  _(pool.ink:538)_
- `vo_wrongman_3c3033fd` That's the story. You waited to see. Everyone in the story waited to see.  _(pool.ink:551)_
- `vo_wrongman_92a55b8a` In the story the police came too. Forty minutes after. Everybody had gone home by then.  _(pool.ink:736)_
- `vo_wrongman_625054ae` Somebody plays that when there's nobody here to see them play it. In the story, that's the one you want to know about.  _(pool.ink:786)_
- `vo_wrongman_00b9aa6d` It was a slow night in the story too. The man who told it said his brother didn't even look up when the wrong one came in.  _(prologue.ink:96)_
- `vo_wrongman_3fffbbe7` Somebody always writes it down, in the story. Then everybody knows who.  _(rats.ink:258)_
- `vo_wrongman_fe0fefa7` Somebody always sees. In the story it was the one nobody was watching.  _(rats.ink:312)_
- `vo_wrongman_c4ad810d` Don't tell anyone. Nobody believes the one who saw it.  _(rats.ink:439)_
- `vo_wrongman_47c42f32` You're feeding them now.  _(rats.ink:509)_
- `vo_wrongman_03d45846` Manners.  _(rats.ink:515)_
- `vo_wrongman_c5dc68f1` Leave it where the others can see it. In the story that's a message. Nobody ever says what it means.  _(rats.ink:541)_
- `vo_wrongman_0a46453a` Every rat in the building knows that table.  _(rats.ink:630)_
- `vo_wrongman_d2de980a` You gave one back. Somebody down there counts things like that.  _(rats.ink:661)_
- `vo_wrongman_79eda6c7` In the story, the doorman carried the body out himself. He never forgot the weight. This one's lighter.  _(rats.ink:723)_
- `vo_wrongman_ce899f2b` Now that's a story.  _(table28.ink:150)_
- `vo_wrongman_bed31b7c` An arrangement.  _(table28.ink:197)_
- `vo_wrongman_ca2d7f71` In the story, the doorman heard them talking about him the first night. He should have shut the window.  _(walk.ink:288)_
- `vo_wrongman_c1b1351b` People in you never saw. In the story it only took one.  _(barks.yaml door_uncounted)_
- `vo_wrongman_85e60e91` The man in the kid's photo. Left hand on the rail, same as the picture.  _(barks.yaml pool_kid_photo)_
- `vo_wrongman_d972f503` In the story it was a dog under the table. Everybody fed it. Same thing.  _(barks.yaml t28_walter)_
- `vo_wrongman_8089bd09` A locked door with a kid behind it. That's a story nobody wants to finish.  _(barks.yaml hall_locked)_
- `vo_wrongman_40402246` This is where it always starts. Somebody out for a smoke, and the door left open behind them.  _(barks.yaml deck_story)_
- `vo_wrongman_1b6b09cd` You've seen it now. You can't go back to not having seen it.  _(barks.yaml keg_seen)_
- `vo_wrongman_7eeb6a0a` The doorman in the story was sober. It didn't help him either.  _(barks.yaml drink_story)_
- `vo_wrongman_062ef42e` Midnight. In the story it was always after midnight.  _(barks.yaml hour_midnight)_
- `vo_wrongman_46d518a4` He knew the story. Every doorman knows the story.  _(barks.yaml ans_wrongman_father_1)_
- `vo_wrongman_b8538396` Listen to him. The one in the story had nobody to listen to.  _(barks.yaml ans_wrongman_father_2)_
- `vo_wrongman_7d1c3741` The doorman in the story was ready for a fight. That isn't what came in.  _(barks.yaml ans_wrongman_fighter_1)_
- `vo_wrongman_fe20394d` The wrong man is never the one squaring up to you.  _(barks.yaml ans_wrongman_fighter_2)_
- `vo_wrongman_c75444b4` The doorman in the story had his licence. It was in his wallet the whole time.  _(barks.yaml ans_wrongman_manual_1)_
- `vo_wrongman_2f31b436` There's no page in there for what came through that door.  _(barks.yaml ans_wrongman_manual_2)_
- `vo_wrongman_f5e0729d` In the story the doorman checked his licence, and he was exactly who he said he was.  _(barks.yaml toy_card_look_wrongman)_
- `vo_wrongman_540be542` In the story the doorman watched the whole room in the mirror behind the bar, and never once looked at himself in it.  _(barks.yaml look_bottles)_
- `vo_wrongman_785cc505` In the story there was a coat on a hook all night. Everybody saw it. Nobody wondered whose.  _(barks.yaml look_coat_hook)_
- `vo_wrongman_30764636` In the story the doorman ran, and by the time he got there everybody was already standing.  _(barks.yaml legs_ran_wrongman)_
- `vo_wrongman_04c6969c` In the story, the table that's turned on you never says it to your face. It says it to the table.  _(barks.yaml ears_new_kid_bad)_
- `vo_wrongman_d13f868c` The doorman in the story had one with them too. To be friendly.  _(barks.yaml hand_drink_wrongman)_
- `vo_wrongman_9d7ca7f9` In the story he said no the first time too.  _(barks.yaml hand_resisted_drink_wrongman)_
- `vo_wrongman_f4b1c58d` The log in the story read fine. That was the trouble with it.  _(barks.yaml hand_shade_wrongman)_
- `vo_wrongman_6d7605dd` He left one thing out of his log, in the story. Guess which.  _(barks.yaml hand_omit_wrongman)_
- `vo_wrongman_81f9a2d6` In the story the doorman won the fight. He still let the wrong man in.  _(barks.yaml hand_check_fighter_wrongman)_
- `vo_wrongman_746f21c7` The book's never met anybody from here.  _(barks.yaml hand_check_manual_wrongman)_
- `vo_wrongman_468fd88b` I know how this one goes.  _(barks.yaml hand_check_wrongman_own)_
- `vo_wrongman_86b8b6ce` You'll still let him in. You just won't know it's him.  _(barks.yaml hand_out_wrongman)_
- `vo_wrongman_f2e2f789` That's when he got in, in the story. When the doorman went to look at something.  _(barks.yaml hand_door_wrongman)_
- `vo_wrongman_1cd2a16f` You know what's behind that wall now.  _(barks.yaml hand_loc_keg_seen)_
- `vo_wrongman_0ad32a6b` The doorman in the story stood there thinking, too.  _(barks.yaml hand_wait_wrongman)_
- `vo_wrongman_d5a30764` It happened the way it happened. Reading it again won't change it.  _(barks.yaml hand_reread_wrongman)_
- `vo_wrongman_fff57eef` Where were you? That's what they'll ask you.  _(barks.yaml hand_back_wrongman)_
- `vo_wrongman_a468c1d8` Everybody in the story thought they could feel it coming.  _(barks.yaml hand_shake_wrongman)_

## The Fighter (`fighter`)

- `vo_fighter_c4785480` Loose. Good. You're better loose.  _(bar.ink:187)_
- `vo_fighter_5604f7a4` Keep the glass between you. He's wet through, and angry, and he's walked a mile to stand there.  _(closing.ink:1318)_
- `vo_fighter_35c656b5` You made a deal with rats.  _(closing.ink:1603)_
- `vo_fighter_bdc919c5` Good.  _(closing.ink:1632)_
- `vo_fighter_f9779650` The eye'll close by morning. Ice it. Or don't, and let them see it on Friday.  _(closing.ink:1805)_
- `vo_fighter_a070cdd7` You were first. That's all it ever is. Be first.  _(closing.ink:1807)_
- `vo_fighter_259d1054` Nobody swung at you. Friday somebody will.  _(closing.ink:1811)_
- `vo_fighter_c19833c2` The ones you put out the front come in the back. Every time.  _(deck.ink:144)_
- `vo_fighter_60e916a6` Watch the boyfriend.  _(deck.ink:236)_
- `vo_fighter_26439562` The boyfriend. It'll be the boyfriend.  _(deck.ink:245)_
- `vo_fighter_ba61db20` Nine. He's had nine. He'll swing slow and wide.  _(deck.ink:312)_
- `vo_fighter_36b9540b` He's had eight and he wants a ninth. Weight on his heels, chin up. He's the one who'll swing if anyone does, and he'll swing at the biggest fucker in the bar: You.  _(door.ink:421)_
- `vo_fighter_653e825c` Soft. Drunk. Nothing.  _(door.ink:424)_
- `vo_fighter_ffd12a0b` The big man at the pool table's a lefty. Every time he misses, the left hand goes flat on the rail and stays there. That's where it'll come from, if it comes.  _(floor.ink:333)_
- `vo_fighter_453fd24d` The boyfriend's hands won't stay still. He keeps touching his own face. He's working himself up to something.  _(floor.ink:338)_
- `vo_fighter_10175bd2` Nobody in here tonight with anything in their hands but a glass.  _(floor.ink:341)_
- `vo_fighter_26051115` Everybody's got two.  _(floor.ink:344)_
- `vo_fighter_a57f6f7a` He's the one who'll swing. Now he'll swing harder.  _(hall.ink:93)_
- `vo_fighter_3f989495` Left hand. Flat on the rail. That's where it comes from, if it comes.  _(pool.ink:116)_
- `vo_fighter_591b9442` Now they're both looking at you. That's what saying it out loud costs.  _(pool.ink:163)_
- `vo_fighter_b85272b0` He threw it.  _(pool.ink:206)_
- `vo_fighter_d13a016d` Now. Now, now, now.  _(pool.ink:484)_
- `vo_fighter_129b7e99` That's it. That's all it takes if you're first.  _(pool.ink:492)_
- `vo_fighter_ba483d85` The one who's going to swing. Always the one who's going to swing.  _(pool.ink:511)_
- `vo_fighter_ab5da03c` Good. Loud's for them. You want to hear it start.  _(pool.ink:797)_
- `vo_fighter_69dab290` Don't stand like that for long.  _(pool.ink:814)_
- `vo_fighter_d27d3432` Big one at the pool table. Watch his left hand.  _(prologue.ink:94)_
- `vo_fighter_995d241c` They're not scared of you.  _(rats.ink:139)_
- `vo_fighter_d3a3254d` Good. Finish it.  _(rats.ink:329)_
- `vo_fighter_d7cba458` Go in there.  _(rats.ink:406)_
- `vo_fighter_e442bb92` You had it.  _(rats.ink:448)_
- `vo_fighter_d2fde9e0` Now. While it's in the open.  _(rats.ink:566)_
- `vo_fighter_40bbeb94` You let it walk.  _(rats.ink:631)_
- `vo_fighter_e2bcda84` Done.  _(rats.ink:652)_
- `vo_fighter_203a703c` Four clubs on the wall. Now there's none.  _(room.ink:67)_
- `vo_fighter_0ab8bddc` Rail's clear. Rack's locked. Board's empty. Nothing in that corner but hands.  _(room.ink:106)_
- `vo_fighter_7754bfa7` Hand out of the coat. Slow. Now.  _(room.ink:605)_
- `vo_fighter_56e5f93d` It's a drink. Drink it. They'll trust you or they won't.  _(table28.ink:111)_
- `vo_fighter_11f5914b` One boot.  _(table28.ink:183)_
- `vo_fighter_69ee4642` Left hand. Flat on the rail. It hasn't moved.  _(barks.yaml pool_left_hand)_
- `vo_fighter_8a571e55` She's not watching your back now. Nobody behind that bar is.  _(barks.yaml bar_cold)_
- `vo_fighter_7121557d` You started it. Finish it where they live.  _(barks.yaml kitchen_war)_
- `vo_fighter_fcd04f4d` Low ceiling. Don't stand up fast.  _(barks.yaml keg_head)_
- `vo_fighter_f71b21d6` Two's good. Two loosens the shoulders.  _(barks.yaml drink_two)_
- `vo_fighter_452c446b` Slow. You got slow.  _(barks.yaml fail_fighter)_
- `vo_fighter_4c76a3c4` A story's no use in a fight. Still. Fair enough.  _(barks.yaml pass_wrongman_fighter)_
- `vo_fighter_ac3aa991` Thirty years of doors and he still thinks it's in the eyes. It's in the feet.  _(barks.yaml ans_fighter_father_1)_
- `vo_fighter_3ab9b124` He'd stand there reading a man till the man hit him.  _(barks.yaml ans_fighter_father_2)_
- `vo_fighter_d1c95625` Nobody in that conference room ever got hit.  _(barks.yaml ans_fighter_manual_1)_
- `vo_fighter_705a1e27` Read him that when he's got you by the collar.  _(barks.yaml ans_fighter_manual_2)_
- `vo_fighter_470f8007` Stories. Watch the room.  _(barks.yaml ans_fighter_wrongman_1)_
- `vo_fighter_0734641a` Forget the brother. Watch the hands in front of you.  _(barks.yaml ans_fighter_wrongman_2)_
- `vo_fighter_4ff8ddd3` Him, you don't walk out quietly.  _(barks.yaml toy_binder_page11)_
- `vo_fighter_e4bfe974` A cue's a stick. Watch who picks one up by the thin end.  _(barks.yaml look_cues)_
- `vo_fighter_5b073ad1` A pint glass is a weapon with the beer gone out of it.  _(barks.yaml look_empties)_
- `vo_fighter_fbd1c9dd` Wet tile's worse than ice. On ice you know.  _(barks.yaml look_mop)_
- `vo_fighter_824d8fb8` Somebody's coming back for that, and he'll want to know whose hands have been on it.  _(barks.yaml look_wallet)_
- `vo_fighter_66e45099` Shoulders up round his ears and he's not looking at the ball. That's not a man playing pool.  _(barks.yaml ears_pool_quiet)_
- `vo_fighter_563d63bc` Feet under you. Always. You never know which way a floor's going to go.  _(barks.yaml ears_overdue)_
- `vo_fighter_6a482168` Take it. They're watching to see if you will.  _(barks.yaml hand_drink_fighter)_
- `vo_fighter_cc094582` Suit yourself.  _(barks.yaml hand_resisted_drink_fighter)_
- `vo_fighter_9a1d03f7` Nobody reads them.  _(barks.yaml hand_shade_fighter)_
- `vo_fighter_094b92e7` Mine. Let me have it.  _(barks.yaml hand_check_fighter_own)_
- `vo_fighter_791387ba` He'll still be talking when it lands.  _(barks.yaml hand_check_father_fighter)_
- `vo_fighter_6d914583` You going to read it to him?  _(barks.yaml hand_check_manual_fighter)_
- `vo_fighter_221a7511` You'll want me back the first time it goes wrong.  _(barks.yaml hand_out_fighter)_
- `vo_fighter_d68f64fc` A kid. In here.  _(barks.yaml hand_in_kid_fighter)_
- `vo_fighter_094c4393` Go. The door'll keep.  _(barks.yaml hand_door_fighter)_
- `vo_fighter_f1f8aabb` Now we're talking.  _(barks.yaml hand_loc_pool_fighter)_
- `vo_fighter_0bda5bf6` Decide, or somebody decides for you.  _(barks.yaml hand_wait_fighter)_
- `vo_fighter_027543ae` Back. Eyes up.  _(barks.yaml hand_back_fighter)_
- `vo_fighter_266d073d` Fast. Good. Don't think.  _(barks.yaml hand_rush_fighter)_
- `vo_fighter_84e1a929` Throw them.  _(barks.yaml hand_shake_fighter)_

Changing with the night (record the bark instead, or ask for these to be split):

- {Num(rats_killed)}. Out of how many.  _(closing.ink:1809)_
- {reach_words(r)}. Count them before they do.  _(room.ink:108)_

## The Till (`till`)

- `vo_till_0390b32e` Here's twenty an hour.  _(office.ink:32)_
- `vo_till_20215227` Long hair. That's a complaint a week.  _(office.ink:40)_
- `vo_till_e552f641` Doesn't fidget. Fidgeters steal.  _(office.ink:48)_
- `vo_till_8d38d4fe` Or pricing it.  _(office.ink:55)_
- `vo_till_959db94b` That floor's eight thousand dollars.  _(office.ink:62)_
- `vo_till_db038d4b` Good till next October. That's a year I don't pay for a course.  _(office.ink:87)_
- `vo_till_a46c5b88` City money. He'll want city money.  _(office.ink:97)_
- `vo_till_ae5504f3` Up island wages. He'll take twenty and say thanks.  _(office.ink:105)_
- `vo_till_b40848b7` Something happened is a lawyer.  _(office.ink:139)_
- `vo_till_ecf8a07e` Fine. Cheaper.  _(office.ink:151)_
- `vo_till_75576d3a` Plenty is a lawsuit.  _(office.ink:162)_
- `vo_till_75d9d475` Twenty an hour to stop them. Thirty to start them, in the city.  _(office.ink:172)_
- `vo_till_9f88566b` Twenty an hour to say that to a drunk. To me?  _(office.ink:182)_
- `vo_till_7ebda0b5` Forty pounds at fourteen a pound.  _(office.ink:202)_
- `vo_till_52f6cac1` Reading my desk.  _(office.ink:232)_
- `vo_till_387e9798` Changed his mind. They do.  _(office.ink:251)_
- `vo_till_0e40ee9b` Honest. Costs me.  _(office.ink:262)_
- `vo_till_c9aeff9d` Liar. They all drink.  _(office.ink:281)_
- `vo_till_5f9f4002` Drinks it like water.  _(office.ink:289)_
- `vo_till_66d1e6d2` Back in the bottle.  _(office.ink:299)_
- `vo_till_6e786ae6` Two at four o'clock. On the floor by midnight.  _(office.ink:305)_
- `vo_till_ff7873ba` Water's free. Free costs.  _(office.ink:319)_
- `vo_till_008320b7` Keys in the lot are on us.  _(office.ink:331)_
- `vo_till_15e8f757` There it is.  _(office.ink:340)_
- `vo_till_804ce580` Owes me a jacket.  _(office.ink:351)_
- `vo_till_beea1be5` Asks about money. Good. You know where you are with that.  _(office.ink:360)_
- `vo_till_20cedb15` No questions. No questions is cheap.  _(office.ink:363)_
- `vo_till_c25465ba` Hydro's fifty. Hydro was always fifty.  _(office.ink:379)_
- `vo_till_159caae4` That's his first cheque.  _(office.ink:397)_
- `vo_till_7603b562` Six-fifty.  _(office.ink:399)_
- `vo_till_206288fc` Eleven dollars a shirt. Forty-eight shirts.  _(office.ink:407)_
- `vo_till_4372a418` Eleven dollars, back in the box.  _(office.ink:418)_
- `vo_till_830368dd` Twenty-four dollars. Eleven-dollar shirt.  _(office.ink:438)_
- `vo_till_b49d83d0` Didn't take the shirt. Reads the form.  _(office.ink:440)_
- `vo_till_0a352fac` Twenty an hour, saved.  _(office.ink:502)_

## Senior (`senior`)

- `vo_senior_ea91e7a9` Ironed a T-shirt.  _(office.ink:39)_
- `vo_senior_6cedb758` Your mother ironed yours till you were thirty, Junior.  _(office.ink:41)_
- `vo_senior_1754886b` He's casing it.  _(office.ink:54)_
- `vo_senior_d39e097a` Lifted it. Didn't drag it.  _(office.ink:61)_
- `vo_senior_834d304a` Six. I charged the last one four, and he still left.  _(office.ink:70)_
- `vo_senior_26505a4c` Makes you reach for it.  _(office.ink:78)_
- `vo_senior_1e4b2625` Short hair, then. Something happened between that and this.  _(office.ink:86)_
- `vo_senior_b8928d5f` Ten years in the city, and he's here. Ask him why.  _(office.ink:98)_
- `vo_senior_fe75ee1f` Around is a place you leave in the night.  _(office.ink:111)_
- `vo_senior_9293a8b8` His father taught him.  _(office.ink:118)_
- `vo_senior_99def1ca` I taught you to count a till, Junior. That's what I taught you.  _(office.ink:119)_
- `vo_senior_6a1560f3` Something happened to all of them. Something happened to me.  _(office.ink:140)_
- `vo_senior_e01b39f7` Look at his hands.  _(office.ink:156)_
- `vo_senior_c3fe1071` That's the answer. Nobody means it.  _(office.ink:167)_
- `vo_senior_4e50d005` A terrible liar. Good. It's the good ones that cost you.  _(office.ink:178)_
- `vo_senior_f058e743` Get him out of your mother's house.  _(office.ink:183)_
- `vo_senior_ccd1ba9d` Patient. The last one wasn't.  _(office.ink:208)_
- `vo_senior_7a48d27d` He's looking at me.  _(office.ink:215)_
- `vo_senior_1cee76b4` Let him. It's his problem from tonight.  _(office.ink:233)_
- `vo_senior_422f6e1e` That one's funny. Watch the funny ones.  _(office.ink:267)_
- `vo_senior_20f63419` That's the right answer. Nobody means that one either.  _(office.ink:271)_
- `vo_senior_687d40dc` Two. He couldn't lie to save his life. Hire him.  _(office.ink:279)_
- `vo_senior_5bb1823d` I'd have hired him for that.  _(office.ink:290)_
- `vo_senior_9341ba64` Holds it like the old fellow at the end of the bar.  _(office.ink:294)_
- `vo_senior_4dbeb923` He held his like that in my day, too.  _(office.ink:295)_
- `vo_senior_c10e6b4b` Your mother would have liked him.  _(office.ink:300)_
- `vo_senior_2b6d94e2` That's my rule.  _(office.ink:312)_
- `vo_senior_f7cdaa32` That's what I said. I buried two of them, saying it.  _(office.ink:325)_
- `vo_senior_51671154` Put one out and they all go, and the money goes with them.  _(office.ink:337)_
- `vo_senior_fa62879c` Don't say rats.  _(office.ink:369)_
- `vo_senior_f38b0f09` He counts. Watch him.  _(office.ink:391)_
- `vo_senior_6d60f51d` Nobody on this island ever wore a shirt that said what he was.  _(office.ink:408)_
- `vo_senior_55ed4864` She was mine.  _(office.ink:450)_
- `vo_senior_579329bf` Christ, Junior.  _(office.ink:503)_

## The Table (`table`)

- `vo_table_59869bbe` Two in the morning! Told you! Every time!  _(closing.ink:1322)_
- `vo_table_681fad6c` We were here first.  _(closing.ink:1773)_
- `vo_table_dbfe549f` Sit down. Nobody stands at this table.  _(closing.ink:1774)_
- `vo_table_538e6aa6` We were nine, once. There's a chair.  _(closing.ink:1776)_
- `vo_table_e525ca02` There he is!  _(closing.ink:1893)_
- `vo_table_aa889696` Get it down you, big fella!  _(barks.yaml hand_drink_table)_
- `vo_table_1b6ab2ba` Next time, big fella.  _(barks.yaml hand_resisted_drink_table)_
- `vo_table_48c70d3b` We'll be at the table.  _(barks.yaml hand_out_table)_
- `vo_table_08f6ed81` Come on, big fella, it's going warm.  _(barks.yaml hand_wait_table)_
- `vo_table_c85270a7` Come on, big fella, let 'em go!  _(barks.yaml hand_shake_table)_

## The Kid (`kid`)

- `vo_kid_a2aff455` he did that at my door once. knocking like that. flat hand  _(closing.ink:1324)_
- `vo_kid_0b606130` i'm not high  _(closing.ink:1781)_
- `vo_kid_7ff2f196` i just haven't slept  _(closing.ink:1782)_
- `vo_kid_7a85f476` ok  _(closing.ink:1895)_
- `vo_kid_953e5d4a` you can just hold it. nobody checks  _(barks.yaml hand_drink_kid)_
- `vo_kid_f5cad9e8` you can take as long as you want. they won't  _(barks.yaml hand_wait_kid)_
- `vo_kid_0b71de2a` i do that too  _(barks.yaml hand_reread_kid)_
- `vo_kid_3f22f652` just throw them  _(barks.yaml hand_shake_kid)_
- `vo_kid_6f3cf1ab` they all look at the door before they look at you  _(barks.yaml kid_door)_

## The Bartender (`bartender`)

- `vo_bartender_bbc9c050` Door. You don't run on my floor. Half the room just looked round for the fight.  _(bar.ink:29)_
- `vo_bartender_a21b2a88` Walk, Door.  _(bar.ink:31)_
- `vo_bartender_68184166` Again with the running.  _(bar.ink:32)_
- `vo_bartender_0a80a6d3` Table 28 don't get cut off. That's Junior's rule, so don't look at me.  _(bar.ink:101)_
- `vo_bartender_25738ced` Cook's all right, he's just hot, and you'd be hot. Leave his kitchen door alone unless you want an earful.  _(bar.ink:102)_
- `vo_bartender_96161b3f` Night clerk's Terry. Props the hotel door so he can watch our TV off the desk. You didn't hear that from me.  _(bar.ink:103)_
- `vo_bartender_499d47bc` And when the card machine goes down, and it will, it's cash, and if they haven't got cash, they haven't got a drink.  _(bar.ink:104)_
- `vo_bartender_9c973613` Him? He was coming in before I started, and I started when I was nineteen.  _(bar.ink:116)_
- `vo_bartender_e1116bad` Don't ask me his name. Thirty-one years and I never got it. Buys one glass and doesn't touch it.  _(bar.ink:117)_
- `vo_bartender_010ee339` He's no trouble.  _(bar.ink:118)_
- `vo_bartender_c00cfe5e` He's the only one in here who's never been any trouble.  _(bar.ink:120)_
- `vo_bartender_68929277` Junior wants them dead, the cook wants them dead, and the inspector's on the fourteenth.  _(bar.ink:126)_
- `vo_bartender_019cdc06` Table 28 feed one, under the table. They think I don't know.  _(bar.ink:127)_
- `vo_bartender_47312349` They come up through the keg room. Trapdoor's behind me, and mind the third step, it's rotten.  _(bar.ink:128)_
- `vo_bartender_f176947a` Me, I want a quiet night. Deal with them however you want, but don't do it in front of the customers.  _(bar.ink:130)_
- `vo_bartender_a519893a` Thirty-one years. Thirty-two in March, God help me.  _(bar.ink:136)_
- `vo_bartender_2064fd38` I've had nine doormen. You're ten.  _(bar.ink:137)_
- `vo_bartender_460063d7` Table 28's had more than that. They were the young ones when I started, and they were worse than any kids you'll see tonight, believe me.  _(bar.ink:138)_
- `vo_bartender_6a360305` That's Dennis, in the big glasses. His wife'll be in for him around one. She always is.  _(bar.ink:140)_
- `vo_bartender_c006415d` Last a week, Door. Then ask me.  _(bar.ink:148)_
- `vo_bartender_826fa012` Lost-and-found. Bottom of the drawer, under three winters of toques.  _(bar.ink:157)_
- `vo_bartender_b1944b16` Nobody's been through the pockets. I never wanted to know.  _(bar.ink:158)_
- `vo_bartender_7732c139` That's your one. On the ledge, not the bar, and you don't come back for two.  _(bar.ink:169)_
- `vo_bartender_b8b9f136` No.  _(bar.ink:190)_
- `vo_bartender_62dbe9af` Drink that, and go and stand at your door.  _(bar.ink:193)_
- `vo_bartender_6dd398e2` Your door's still there.  _(bar.ink:195)_
- `vo_bartender_f6d3edc4` Fuckin' lager.  _(bar.ink:209)_
- `vo_bartender_73f736f3` Watch my bar, Door. Two minutes.  _(bar.ink:210)_
- `vo_bartender_b6bcb963` Lager's back.  _(bar.ink:253)_
- `vo_bartender_c1e6ab2b` You want one, you ask me. Nobody pours in my bar. Nobody.  _(bar.ink:259)_
- `vo_bartender_ce2e3db3` Seven-fifty. Call it seven.  _(bar.ink:262)_
- `vo_bartender_648d811e` Seven-fifty. Call it seven. Next time you ask me, Door.  _(bar.ink:268)_
- `vo_bartender_7307d442` Mm.  _(bar.ink:271)_
- `vo_bartender_c9e1c878` Mm. Thanks.  _(bar.ink:277)_
- `vo_bartender_934c65b7` Out.  _(bar.ink:290)_
- `vo_bartender_a081d252` And there she goes.  _(bar.ink:341)_
- `vo_bartender_b1c83a56` Network's down, third time this week. Cash only, folks. Cash only.  _(bar.ink:342)_
- `vo_bartender_bd07bc84` Truck didn't come off the ferry with half my order. Again.  _(bar.ink:354)_
- `vo_bartender_acf3381e` She can run a tab till the day she dies, and she will.  _(bar.ink:368)_
- `vo_bartender_25f0093d` Sorry, hon.  _(bar.ink:374)_
- `vo_bartender_5956b588` It's Junior. For you.  _(bar.ink:392)_
- `vo_bartender_e670e6b8` Last call!  _(closing.ink:241)_
- `vo_bartender_47c12486` Past two, folks! Drink 'em up.  _(closing.ink:291)_
- `vo_bartender_cf159d9a` That's two, folks! Drink 'em up.  _(closing.ink:293)_
- `vo_bartender_90bb4ff9` Nope. We're closed.  _(closing.ink:583)_
- `vo_bartender_bea968d3` He's in eleven.  _(closing.ink:620)_
- `vo_bartender_39421190` Nope. I'm not locking up with him in here.  _(closing.ink:648)_
- `vo_bartender_bb0ed31f` Anybody get past you, Door?  _(closing.ink:850)_
- `vo_bartender_bf92ff19` So go find out how. I'll be counting.  _(closing.ink:853)_
- `vo_bartender_8b4f8e76` So we don't know who.  _(closing.ink:949)_
- `vo_bartender_2e00bb96` Yep. Write it.  _(closing.ink:952)_
- `vo_bartender_a1c16010` Ten of you now, and that's the first time I've seen that on a first night.  _(closing.ink:969)_
- `vo_bartender_31293ac5` You wrote down the office.  _(closing.ink:1017)_
- `vo_bartender_96d004e8` Junior reads that, he doesn't fire whoever it was. He fires all of us and starts again. That's all that line does.  _(closing.ink:1019)_
- `vo_bartender_8f0982f4` Office left untidy.  _(closing.ink:1021)_
- `vo_bartender_a1554813` Your name on it, I said. There's nothing on it.  _(closing.ink:1025)_
- `vo_bartender_e5b7bd01` Poured by the bartender.  _(closing.ink:1029)_
- `vo_bartender_e70c1def` Nine of you wrote in that, and not one of you put me in it.  _(closing.ink:1030)_
- `vo_bartender_6ed1eb5a` Huh.  _(closing.ink:1035)_
- `vo_bartender_8f2e65f3` Junior'll hate that. Every word of it's true.  _(closing.ink:1037)_
- `vo_bartender_a3911158` That's not what happened.  _(closing.ink:1040)_
- `vo_bartender_a4b2f13b` Your book, Door. You write what you want in it.  _(closing.ink:1041)_
- `vo_bartender_cc094582` Suit yourself.  _(closing.ink:1079)_
- `vo_bartender_afd5b982` Nope.  _(closing.ink:1093)_
- `vo_bartender_72f940b4` So. Why'd you leave your last door?  _(closing.ink:1098)_
- `vo_bartender_760621fa` I've had what you told Junior. I'm asking you.  _(closing.ink:1101)_
- `vo_bartender_28b12ff8` Twelve's over the deck. I forgot.  _(closing.ink:1107)_
- `vo_bartender_b825867b` Then you heard what I said about it. I'm not saying it twice.  _(closing.ink:1108)_
- `vo_bartender_9928e3dd` They all short you. You'll find out.  _(closing.ink:1123)_
- `vo_bartender_68ce4ddd` Yep. They're all long stories.  _(closing.ink:1129)_
- `vo_bartender_6e38a202` Same as you told Junior. Good.  _(closing.ink:1138)_
- `vo_bartender_7b237c95` That's not what you told Junior. Pick one, Door.  _(closing.ink:1140)_
- `vo_bartender_58f07de3` Table 28 says you did ten years on a door with a line outside it.  _(closing.ink:1145)_
- `vo_bartender_e55fc82a` By Friday it'll be twenty, and you'll have put a hockey player through a window.  _(closing.ink:1146)_
- `vo_bartender_4c9895a9` Table 28 says you did ten years on a door in the city, and you won't say which.  _(closing.ink:1148)_
- `vo_bartender_4575629f` That's worse than any door you could have named. They'll fill it in themselves.  _(closing.ink:1149)_
- `vo_bartender_f366f0c2` Table 28 says your old man worked doors. The one in the cardigan's been saying his name to himself all night, like he's trying to place it.  _(closing.ink:1151)_
- `vo_bartender_e8baf94d` Table 28 says your old man worked doors.  _(closing.ink:1151)_
- `vo_bartender_7da52981` Up island, table 28 says. Everybody's from up island.  _(closing.ink:1153)_
- `vo_bartender_01468f94` Table 28 have decided you're from Around. That's what they're calling it now. Around.  _(closing.ink:1155)_
- `vo_bartender_a7f65af9` Table 28 don't know where you're from. You never went over.  _(closing.ink:1157)_
- `vo_bartender_8562b9e1` That'll eat them alive by Friday.  _(closing.ink:1158)_
- `vo_bartender_fe7a9afe` Same as you told Junior, at least.  _(closing.ink:1185)_
- `vo_bartender_99a9a136` And Junior had it different again. Pick one before Friday, or they'll pick it for you.  _(closing.ink:1187)_
- `vo_bartender_b98bfd63` Ten years on a door, and something happened. Don't give them that part. They'll have it worse than it was by Friday.  _(closing.ink:1192)_
- `vo_bartender_63627044` From Around, and not saying. You'll fit in here.  _(closing.ink:1194)_
- `vo_bartender_d1e1ae5f` Shorted you. And you told this one it was busy. You'll get on.  _(closing.ink:1196)_
- `vo_bartender_27393866` Somebody's been tidying in the office.  _(closing.ink:1203)_
- `vo_bartender_243b421d` Left them the straw, though. So they'd know.  _(closing.ink:1205)_
- `vo_bartender_1617d61e` Straw and all.  _(closing.ink:1207)_
- `vo_bartender_f5c78df5` He'll be in for these at noon, sorry for himself.  _(closing.ink:1215)_
- `vo_bartender_7c17503a` You'll be asleep upstairs. I'll be here.  _(closing.ink:1216)_
- `vo_bartender_32f572c0` You've still got his keys on you. The big fella's.  _(closing.ink:1219)_
- `vo_bartender_3957fa66` Then it's you he comes looking for. Not me.  _(closing.ink:1220)_
- `vo_bartender_c05414e7` You gave his keys to his girl. Yep. That's where they go.  _(closing.ink:1223)_
- `vo_bartender_c67445d3` Busy, you told him.  _(closing.ink:1227)_
- `vo_bartender_a15105b0` He'll have this at nine.  _(closing.ink:1229)_
- `vo_bartender_f863efb0` It's handled, you told him. The rats.  _(closing.ink:1233)_
- `vo_bartender_07e5b739` Inspector's on the fourteenth. I'd get it handled.  _(closing.ink:1234)_
- `vo_bartender_67b0d2e1` You told that girl her father wasn't here.  _(closing.ink:1238)_
- `vo_bartender_3e66c93b` I saw her face. Through two doors, I saw it.  _(closing.ink:1239)_
- `vo_bartender_f27d1c15` One drink, and you put him out after it.  _(closing.ink:1243)_
- `vo_bartender_3b111569` Nine doormen. Not one of them ever did what they said with that man.  _(closing.ink:1244)_
- `vo_bartender_cb4d89c1` You scanned his licence. Ardagh. The machine keeps them, with the time.  _(closing.ink:1249)_
- `vo_bartender_47f1f54c` So if the owner ever wants to know who let him in, it's on there.  _(closing.ink:1250)_
- `vo_bartender_51db95c3` You scanned his licence before you sent him off. Good. If he says he was never here, the machine says he was.  _(closing.ink:1252)_
- `vo_bartender_b858c472` He tell you what he did? Ardagh?  _(closing.ink:1257)_
- `vo_bartender_7f1c129d` He says that.  _(closing.ink:1259)_
- `vo_bartender_90500e9a` He says it like you did it to his face.  _(closing.ink:1265)_
- `vo_bartender_546436a9` You lent nine twenty.  _(closing.ink:1269)_
- `vo_bartender_5dce4c40` She'll pay you back. That's the worst part.  _(closing.ink:1270)_
- `vo_bartender_a7e1a69b` And there's a two-four behind my front door.  _(closing.ink:1274)_
- `vo_bartender_a24f162a` That's mine now. If he asks, it was always mine.  _(closing.ink:1275)_
- `vo_bartender_9c0d2ec0` Junior'll call me in the morning and ask how you did.  _(closing.ink:1280)_
- `vo_bartender_b89a8b86` I'll tell him you'll do.  _(closing.ink:1284)_
- `vo_bartender_47bfdf70` I'll tell him you showed up and you're still here. Two of the last nine didn't manage that.  _(closing.ink:1288)_
- `vo_bartender_32bfcded` I'm going to tell him what I saw.  _(closing.ink:1291)_
- `vo_bartender_c5444f99` Friday's different. Friday's everybody.  _(closing.ink:1294)_
- `vo_bartender_30ee9bc2` Which ones did they tell you?  _(closing.ink:1350)_
- `vo_bartender_5aa78f9f` His jacket's in the lost-and-found. Folded at the bottom of the drawer, under three winters of toques and phone chargers. Nobody's been through the pockets.  _(closing.ink:1353)_
- `vo_bartender_0ec04176` You want to know which one's true, that's where it'll be. I never wanted to know.  _(closing.ink:1354)_
- `vo_bartender_85e77c2d` And you asked me something, earlier.  _(closing.ink:1373)_
- `vo_bartender_d35372a5` Ask me Friday.  _(closing.ink:1374)_
- `vo_bartender_aa060eb5` Go on up. Get some sleep, Door.  _(closing.ink:1376)_
- `vo_bartender_b42eb09b` Binder, page three. Not ever.  _(door.ink:813)_
- `vo_bartender_9b4f52a8` There's a man at my bar who is not allowed at my bar.  _(door.ink:909)_
- `vo_bartender_8bf2b028` Page three. I'm not serving him and I'm not asking him. That's your job, Door.  _(door.ink:911)_
- `vo_bartender_ba8a4b9c` Junior didn't write it. I did.  _(door.ink:962)_
- `vo_bartender_86f793bb` Yep.  _(door.ink:968)_
- `vo_bartender_4d0f52d9` Ninety-six, two Fridays running.  _(drawer.ink:93)_
- `vo_bartender_3cf0955b` That's not Junior. Junior can't add.  _(drawer.ink:94)_
- `vo_bartender_f6875523` Eleven-fifteen. Last boat.  _(drawer.ink:140)_
- `vo_bartender_a64cfeca` Page eight.  _(drawer.ink:165)_
- `vo_bartender_ef8bc91f` Three months, and that's till his birthday, so don't look at me like that.  _(drawer.ink:167)_
- `vo_bartender_0b08c28a` Thirty-three days. Take it.  _(drawer.ink:186)_
- `vo_bartender_e9fac2c6` Door. Do I call it or not?  _(pool.ink:574)_
- `vo_bartender_57d476c1` Your name goes on the log, then. Not mine.  _(pool.ink:588)_
- `vo_bartender_de202abe` You'll be the door, then. Hang on.  _(prologue.ink:69)_
- `vo_bartender_48cfaea0` Every drink in this room goes through my till. Anybody I pour for who didn't come past you, you find out how before you go home.  _(prologue.ink:71)_
- `vo_bartender_dbe8ec90` Junior left you a note. The owner, I mean. I worked for his dad.  _(prologue.ink:72)_
- `vo_bartender_68ee43e8` Junior left you a note. I worked for his dad.  _(prologue.ink:72)_
- `vo_bartender_4c6c6564` Front door's yours, that's the one that counts.  _(prologue.ink:113)_
- `vo_bartender_b35026d5` Hotel door's at the end of the back hall. Residents come down that way, and the night clerk props it so he can hear the TV.  _(prologue.ink:114)_
- `vo_bartender_1b20c16e` Deck door's for the smokers. Kitchen door, the cook props that open, his fryer runs about a hundred degrees back there.  _(prologue.ink:115)_
- `vo_bartender_9f18c69a` They're all locked at night.  _(prologue.ink:116)_
- `vo_bartender_07452ea6` Mostly.  _(prologue.ink:118)_
- `vo_bartender_4ff37384` Friday, middle of the rush, and left his jacket. That's Junior's version.  _(prologue.ink:127)_
- `vo_bartender_346f92dc` Ask table 28. You'll get three more, and the hell of it is they all happened.  _(prologue.ink:128)_
- `vo_bartender_4d4a8ba0` Walked out on a Friday, middle of the rush, and left his jacket.  _(prologue.ink:130)_
- `vo_bartender_28d047e7` Ask table 28 why. You'll get three stories, and the hell of it is they all happened.  _(prologue.ink:131)_
- `vo_bartender_d141f7bf` Binder under the till, the eighty-sixes. Photos, most of them, and for how long. You read it before you sit on that stool.  _(prologue.ink:139)_
- `vo_bartender_ed11be06` One of Junior's shirts. Christ.  _(prologue.ink:169)_
- `vo_bartender_58ef0e1c` You sat on that wall two and a half hours. I saw you. Everybody saw you.  _(prologue.ink:172)_
- `vo_bartender_1312159b` Junior rang. Says you've got a mouth on you.  _(prologue.ink:180)_
- `vo_bartender_4a196119` Junior rang. Says you've never been in a fight.  _(prologue.ink:182)_
- `vo_bartender_d4f11595` Junior rang. Says you don't drink.  _(prologue.ink:185)_
- `vo_bartender_f13e2729` Junior rang. Ten years on a door in the city, he says.  _(prologue.ink:188)_
- `vo_bartender_3d77d7aa` Junior rang. Says you can drink.  _(prologue.ink:190)_
- `vo_bartender_f8b5833e` Junior rang. Says your dad did doors.  _(prologue.ink:192)_
- `vo_bartender_e30c28ad` Junior rang. Says you'll do.  _(prologue.ink:194)_
- `vo_bartender_3c1141e0` Third step.  _(rats.ink:188)_
- `vo_bartender_ba160bcf` Not where they can see it. I said.  _(rats.ink:383)_
- `vo_bartender_388082cf` Door! You're wanted.  _(rats.ink:393)_
- `vo_bartender_3ae8d098` Find anything?  _(rats.ink:420)_
- `vo_bartender_04622349` I know they're down there. Thirty-one years I've known.  _(rats.ink:425)_
- `vo_bartender_e139a1c8` Not in front of the customers. I said.  _(rats.ink:577)_
- `vo_bartender_ff25203a` Nice.  _(rats.ink:602)_
- `vo_bartender_93fc397a` Jesus Christ.  _(rats.ink:702)_
- `vo_bartender_27ef2095` You don't have to do that.  _(room.ink:39)_
- `vo_bartender_c296590d` Nine doormen. Not one of them ever carried a glass.  _(room.ink:41)_
- `vo_bartender_237539e9` Nobody's thrown since the league folded.  _(room.ink:76)_
- `vo_bartender_b3685528` There was a league, Thursdays. Then there wasn't.  _(room.ink:77)_
- `vo_bartender_4246eac8` Somebody picked something up, Door. That's not mine to sit on, and it's not yours.  _(room.ink:172)_
- `vo_bartender_bd637f15` Don't you put the curling on. They'll be here till four.  _(room.ink:235)_
- `vo_bartender_7a16d51b` That's not your job, Door.  _(room.ink:386)_
- `vo_bartender_6099fe71` Thanks.  _(room.ink:388)_
- `vo_bartender_0f5afbc6` Two years.  _(room.ink:472)_
- `vo_bartender_aeb08d5e` Since the grease fire. That was the last time anybody pulled the pin on one of those, and Junior's father was alive.  _(room.ink:474)_
- `vo_bartender_aad90c90` That's Junior's list. He reads it the night before the inspector, every time.  _(room.ink:476)_
- `vo_bartender_6cd3fd0b` Mm. Somebody's done this before.  _(room.ink:508)_
- `vo_bartender_a56338e4` My lights, Door. You ask me first.  _(room.ink:510)_
- `vo_bartender_66a7df2c` Quarter to. Not before.  _(room.ink:518)_
- `vo_bartender_854a0cb8` Moffat's. Drawer. He'll be back for it, or one of the kids will.  _(room.ink:641)_
- `vo_bartender_e7714160` He'll be back for that. That kind always comes back for the wallet.  _(room.ink:721)_
- `vo_bartender_5bf31af7` Not them.  _(table28.ink:309)_
- `vo_bartender_fea60dc0` Junior's rule, Door. Table 28 don't get cut off. They paid for half this carpet.  _(table28.ink:311)_
- `vo_bartender_035fdf28` Yep. Mm. No, I'm out back. Go.  _(walk.ink:190)_
- `vo_bartender_7183748f` He's what? Long hair? Christ, Junior.  _(walk.ink:191)_
- `vo_bartender_70078496` He said that? To you? Ha.  _(walk.ink:195)_
- `vo_bartender_7081304b` He said that to her. Good.  _(walk.ink:200)_
- `vo_bartender_8b39b0f1` He asked if you wanted to find out. And then he was kidding. They're always kidding.  _(walk.ink:204)_
- `vo_bartender_4d2d8718` Never been in a fight. Sure. And I've never had a drink.  _(walk.ink:208)_
- `vo_bartender_fa9b21a6` Doesn't drink. Doug says different. Doug says a lot, but.  _(walk.ink:212)_
- `vo_bartender_be5bd630` Ten years on a door in the city. Mm. They've all done ten years in the city.  _(walk.ink:218)_
- `vo_bartender_b0d80d36` Up island. Who isn't.  _(walk.ink:220)_
- `vo_bartender_8380cec4` Around. Around's not a place, Junior.  _(walk.ink:222)_
- `vo_bartender_50eeb5bf` His dad did doors. Did he.  _(walk.ink:224)_
- `vo_bartender_8712fda5` The owner shorted him. And you laughed. Course you laughed.  _(walk.ink:231)_
- `vo_bartender_360da2bb` Something happened. Something always happened, Junior.  _(walk.ink:233)_
- `vo_bartender_01f164c4` Long story. Mine's thirty-one years.  _(walk.ink:235)_
- `vo_bartender_f7d7db61` He just sat there? Good.  _(walk.ink:237)_
- `vo_bartender_1bf8db2b` Drank it straight down. Mm.  _(walk.ink:244)_
- `vo_bartender_039a424d` He held it and didn't drink it. Huh.  _(walk.ink:246)_
- `vo_bartender_ac2d6f2f` Pushed it back. Your rye. Huh.  _(walk.ink:248)_
- `vo_bartender_97ea588b` Two? At four o'clock? Christ.  _(walk.ink:250)_
- `vo_bartender_aec3fc5c` You gave him one of those shirts. Junior. Nobody wears those shirts.  _(walk.ink:255)_
- `vo_bartender_517e9449` He wouldn't take the shirt? Good for him.  _(walk.ink:259)_
- `vo_bartender_abc2f416` He caught her on the rent? Did he. Did he really.  _(walk.ink:263)_
- `vo_bartender_7935c24b` He asked when he gets paid. Good. Nobody asks till they're short.  _(walk.ink:267)_
- `vo_bartender_a8c0c2fd` Made you reach for it. Ha.  _(walk.ink:271)_
- `vo_bartender_214fc84e` Water. Yep. Water I can do.  _(walk.ink:276)_
- `vo_bartender_ec80adf8` Whatever they want. That's what you'd say.  _(walk.ink:278)_
- `vo_bartender_379ec474` How's he getting home. Huh. Nobody's asked that in thirty-one years.  _(walk.ink:280)_
- `vo_bartender_3d6987de` Put him out. Table 28. He'll learn.  _(walk.ink:282)_
- `vo_bartender_45a2ae80` Yep. Seven-thirty. I'll show him.  _(walk.ink:285)_
- `vo_bartender_91c661a1` No. No, Junior. I'll show him. Nine doormen, I've shown.  _(walk.ink:286)_
- `vo_bartender_469eba74` That's the cooler, hon.  _(talk.yaml endbar_tide)_
- `vo_bartender_414815dc` Same box, sweetheart. Same Tuesday.  _(talk.yaml slippers_wine)_
- `vo_bartender_883be059` Ask the fuckin' card machine, hon. It decides.  _(talk.yaml card_machine)_

Changing with the night (record the bark instead, or ask for these to be split):

- {Num(drinks)}. I counted too.  _(closing.ink:1087)_
- The cook says you shut his door on him {kitchen_door_shut == 2:twice\|{num(kitchen_door_shut)} times}.  _(closing.ink:1264)_

## Team Jacket (`team_jacket`)

- `vo_team_jacket_44336ee9` Lager's off!  _(bar.ink:291)_
- `vo_team_jacket_88c94bf2` Took the man's keys. In this town. I did that once, in 'eighty-one. Once.  _(closing.ink:709)_
- `vo_team_jacket_24bdd992` I'd start my truck careful for a week or two, son, if I were you.  _(closing.ink:710)_
- `vo_team_jacket_1de7136f` You let him drive, son.  _(closing.ink:713)_
- `vo_team_jacket_1af1421f` Sent him home with his kids, did you. Huh.  _(closing.ink:716)_
- `vo_team_jacket_ac130d1b` Dennis's wife stopped you with one word, son. I saw it. I was sitting right here.  _(closing.ink:722)_
- `vo_team_jacket_ed6d3df4` She's stopped bigger.  _(closing.ink:723)_
- `vo_team_jacket_69ff1ed1` Here's the stander. Never did sit down with us, did you, big fella.  _(closing.ink:727)_
- `vo_team_jacket_48d5dc6a` An hour, though. She'll have the chain on.  _(closing.ink:741)_
- `vo_team_jacket_5e29c923` Even so. She'll have the chain on.  _(closing.ink:741)_
- `vo_team_jacket_a61c203c` The last one said that. Word for word.  _(closing.ink:768)_
- `vo_team_jacket_dd76f97b` Where'd you get to earlier, anyway? You were gone half an hour.  _(closing.ink:777)_
- `vo_team_jacket_0d8af317` Half an hour in the can! At our age that's a medical event.  _(closing.ink:779)_
- `vo_team_jacket_63b87a0c` Smoking! He quit!  _(closing.ink:789)_
- `vo_team_jacket_7959ac19` The kind with a line outside, he says. I've stood in that line. I never saw him.  _(rats.ink:469)_
- `vo_team_jacket_a9c21ad4` I've stood in a line.  _(rats.ink:471)_
- `vo_team_jacket_bd485267` Ten years on a door in the city, and he won't say which door. You notice he wouldn't say which.  _(rats.ink:473)_
- `vo_team_jacket_f3bd9680` Ten years in the city, he says. Nobody does ten years on a city door and ends up here.  _(rats.ink:477)_
- `vo_team_jacket_28bdcbee` Around. What kind of an answer is around.  _(rats.ink:485)_
- `vo_team_jacket_4958610a` Where's the new kid got to?  _(rats.ink:487)_
- `vo_team_jacket_d4777cd4` Give him a week.  _(rats.ink:496)_
- `vo_team_jacket_41423fe4` That's not Walter. Walter's twice the size.  _(rats.ink:581)_
- `vo_team_jacket_d17ee5ab` Who put poison down.  _(rats.ink:741)_
- `vo_team_jacket_73d04fd5` Well.  _(rats.ink:745)_
- `vo_team_jacket_88149809` At least you said so.  _(rats.ink:746)_
- `vo_team_jacket_e21a3ef7` The owner's never met Walter.  _(rats.ink:749)_
- `vo_team_jacket_787fa286` Who put a trap under our table.  _(rats.ink:770)_
- `vo_team_jacket_da0847ad` Atta boy! Bring us one back while you're over there!  _(room.ink:46)_
- `vo_team_jacket_510a05d9` We know how this one ends, son. Two to one.  _(room.ink:257)_
- `vo_team_jacket_711b1e7d` Now that's a sport.  _(room.ink:273)_
- `vo_team_jacket_3d794c26` Two nights! Two nights, same place!  _(room.ink:289)_
- `vo_team_jacket_a85decb5` Forty years that TV's been on! Forty years!  _(room.ink:300)_
- `vo_team_jacket_ed02f466` The light. Over the strait. On the news two nights running, same place. What is it?  _(room.ink:315)_
- `vo_team_jacket_344b59b1` Two nights in the same place! What's it tied to?  _(room.ink:319)_
- `vo_team_jacket_a0cda6f0` Then it's working!  _(room.ink:321)_
- `vo_team_jacket_f4ce9cd6` Two to one! And that second goal was offside!  _(room.ink:335)_
- `vo_team_jacket_3f52bb92` There's a thing in the sky, son, and he wants the score.  _(room.ink:340)_
- `vo_team_jacket_afe3eb34` The last one never mopped! Never mopped a thing!  _(room.ink:385)_
- `vo_team_jacket_5c6091ec` Forty years I've been walking out that door, son. Never once on my backside.  _(room.ink:447)_
- `vo_team_jacket_9443b8f7` It says SECURITY on him, boys. In case we were wondering what he was.  _(table28.ink:28)_
- `vo_team_jacket_a3bf56e0` They're getting bigger, the doormen. The last one was a big lad too, and a lot of good it did him.  _(table28.ink:33)_
- `vo_team_jacket_a83d2cf4` Try us. We've drunk everywhere.  _(table28.ink:51)_
- `vo_team_jacket_1a73da43` He's from Around. I've been to Around. Terrible place.  _(table28.ink:62)_
- `vo_team_jacket_13c88a84` Well, sit down, then, big fella. Nobody stands at this table.  _(table28.ink:86)_
- `vo_team_jacket_9f4e40e9` The last one was working too, son. Look where it got him.  _(table28.ink:96)_
- `vo_team_jacket_fd51f746` Get the big fella a rye.  _(table28.ink:108)_
- `vo_team_jacket_ca6e83db` More for us, then.  _(table28.ink:131)_
- `vo_team_jacket_e039672a` Owner shorted him two weeks running. Walked out on a Friday with the float in his pocket. I was sitting right here.  _(table28.ink:145)_
- `vo_team_jacket_7f7a0311` Longer than the owner.  _(table28.ink:160)_
- `vo_team_jacket_20be069b` Don't be a stranger, son.  _(table28.ink:166)_
- `vo_team_jacket_722f7862` Don't tell the owner.  _(table28.ink:180)_
- `vo_team_jacket_c265e374` Get away from our table.  _(table28.ink:210)_
- `vo_team_jacket_ba71bdb0` You'll pay for those.  _(table28.ink:217)_
- `vo_team_jacket_f1386f1d` He's all right, this one!  _(table28.ink:246)_
- `vo_team_jacket_7be95145` You're all right, son. You're all right.  _(table28.ink:246)_
- `vo_team_jacket_73ae1e50` Atta boy.  _(table28.ink:246)_
- `vo_team_jacket_63f3d342` For looking after us.  _(table28.ink:257)_
- `vo_team_jacket_ab130880` Your loss, big fella.  _(table28.ink:266)_
- `vo_team_jacket_213ea353` The last one was a leaner. Leaned on the jukebox all night. We liked him.  _(table28.ink:277)_
- `vo_team_jacket_3f842157` Son, I've been cut off by better than you. I've been cut off by a judge.  _(table28.ink:307)_
- `vo_team_jacket_4dc19c42` Sit, sit. You're one of us now, God help you.  _(table28.ink:336)_
- `vo_team_jacket_4d944b5f` Sit, sit.  _(table28.ink:336)_
- `vo_team_jacket_27bd7a68` Nobody asks us that. The last one never asked us that.  _(table28.ink:377)_
- `vo_team_jacket_f82ccc8e` Dennis has been called home. It happens to the best of us. It happens to Dennis about twice a week.  _(table28.ink:388)_
- `vo_team_jacket_948098a5` Dennis says thank you. Dennis won't say it himself, but he says it.  _(table28.ink:424)_
- `vo_team_jacket_3eedaa4b` Nothing personal. Dennis would have done the same. Dennis has done the same, to me.  _(table28.ink:427)_
- `vo_team_jacket_0cfae586` Nothing personal. But somebody has to be on the door, son. That's the whole job.  _(table28.ink:430)_
- `vo_team_jacket_adc8db1c` Nothing personal. Dennis would say the same. Dennis will say the same, on Thursday, when he's allowed out.  _(table28.ink:433)_
- `vo_team_jacket_d52f0ccc` Nothing personal, son. But where was the door.  _(table28.ink:479)_
- `vo_team_jacket_b60e6363` A dollar ninety-one for diesel at the Esso. A dollar ninety-one!  _(talk.yaml t28_diesel)_
- `vo_team_jacket_cbf2ec49` Due, he says! It's due!  _(talk.yaml t28_diesel)_
- `vo_team_jacket_1641bc1b` You couldn't get in the door! We had this one, mind.  _(talk.yaml t28_mill)_
- `vo_team_jacket_ec98bf1e` Back in the day you got a pickled egg and a slap on the back for a dollar.  _(talk.yaml t28_eggs)_
- `vo_team_jacket_89c04821` A dollar ten! He's counting my eggs now!  _(talk.yaml t28_eggs)_
- `vo_team_jacket_ac1edc0e` So. The new kid. What do we think?  _(talk.yaml t28_new_kid)_
- `vo_team_jacket_4dc9239d` Give him a week. A week, tops!  _(talk.yaml t28_new_kid)_
- `vo_team_jacket_d7453692` The new kid's all right. Isn't he? He's all right!  _(talk.yaml t28_new_kid_good)_
- `vo_team_jacket_065b5529` Somebody buy the big fella a drink. Not me. Somebody.  _(talk.yaml t28_new_kid_good)_
- `vo_team_jacket_84cd20f7` That one on the door. Not one of ours, that one.  _(talk.yaml t28_new_kid_bad)_
- `vo_team_jacket_19850dea` Ten doormen since spring. Ten! We'll see the eleventh by Friday.  _(talk.yaml t28_new_kid_bad)_
- `vo_team_jacket_667e2728` We know what she says, Dennis. The whole island knows what she says.  _(talk.yaml t28_dennis)_
- `vo_team_jacket_a6b5ed5e` To the Sov! And to the ones who aren't here to see it!  _(talk.yaml t28_toast)_
- `vo_team_jacket_654fa3d8` Two nights! Same place! That's not a plane!  _(talk.yaml t28_news_light)_
- `vo_team_jacket_2ce39712` Seeding's for the hail! That's Alberta!  _(talk.yaml t28_news_light)_
- `vo_team_jacket_88e74ca2` A balloon! What's it tied to?  _(talk.yaml t28_news_balloon)_
- `vo_team_jacket_58692d53` Look at him sweep. Look at that.  _(talk.yaml t28_curling)_
- `vo_team_jacket_23df197e` Who wants to hear that!  _(talk.yaml t28_tv_off)_

## Table 28 (`table28`)

- `vo_table28_ad021c5d` Hear, hear!  _(bar.ink:292)_
- `vo_table28_fcac3bf2` Cash is king!  _(bar.ink:343)_
- `vo_table28_258567ff` It's the diesel!  _(bar.ink:355)_
- `vo_table28_f4093f5b` Two each!  _(closing.ink:242)_
- `vo_table28_e5209e6c` Careful!  _(closing.ink:711)_
- `vo_table28_ff26cd30` Drink up, gentlemen!  _(closing.ink:750)_
- `vo_table28_446b1b64` He's all right, the new kid! Isn't he? He's all right!  _(closing.ink:764)_
- `vo_table28_8fc7529a` A medical event!  _(closing.ink:783)_
- `vo_table28_fb92536a` The deck!  _(closing.ink:788)_
- `vo_table28_e6e65e48` No Dennis here! Never heard of him!  _(door.ink:1029)_
- `vo_table28_3ef89d88` Traitor!  _(door.ink:1061)_
- `vo_table28_cce89558` That's on you, new kid! That's on you!  _(door.ink:1075)_
- `vo_table28_d86c4a30` Something happened.  _(rats.ink:475)_
- `vo_table28_3a9f66b3` He's all right, though.  _(rats.ink:492)_
- `vo_table28_f6b83b9f` He won't last.  _(rats.ink:494)_
- `vo_table28_e525ca02` There he is!  _(rats.ink:583)_
- `vo_table28_d3687816` Walter!  _(rats.ink:587)_
- `vo_table28_1b97b950` Busboy!  _(room.ink:45)_
- `vo_table28_c4d4268d` The game!  _(room.ink:256)_
- `vo_table28_d2388c3d` He's one of us! He wants to know!  _(room.ink:282)_
- `vo_table28_eb87c0fe` There it is!  _(room.ink:288)_
- `vo_table28_0ba64e3b` Boo!  _(room.ink:299)_
- `vo_table28_22fb4ed8` Big fella! Settle this!  _(room.ink:314)_
- `vo_table28_b1acdf94` He's back! Ask him!  _(room.ink:323)_
- `vo_table28_8a27136e` Here's the expert!  _(room.ink:323)_
- `vo_table28_4dfed0d1` Big fella! Tell him!  _(room.ink:323)_
- `vo_table28_9af978a7` Offside!  _(room.ink:336)_
- `vo_table28_b8f43c6c` Who cares about the game!  _(room.ink:339)_
- `vo_table28_82d86692` Look at him go!  _(room.ink:384)_
- `vo_table28_32ded342` Oh-ho!  _(room.ink:415)_
- `vo_table28_9679f8b8` Lights! At half past one!  _(room.ink:505)_
- `vo_table28_5a145e7f` Here he is!  _(table28.ink:24)_
- `vo_table28_ef5326a6` Look at the size of him!  _(table28.ink:25)_
- `vo_table28_eb60469e` Security!  _(table28.ink:29)_
- `vo_table28_ff4bdebf` Where'd they dig you up?  _(table28.ink:35)_
- `vo_table28_cd0f6fbf` Up island!  _(table28.ink:41)_
- `vo_table28_f9b0a114` Which one?  _(table28.ink:48)_
- `vo_table28_ffeba888` Oooh.  _(table28.ink:55)_
- `vo_table28_1ee1ae7b` Around!  _(table28.ink:61)_
- `vo_table28_cab61f9a` Ah.  _(table28.ink:68)_
- `vo_table28_dbce23fb` A travelling man!  _(table28.ink:84)_
- `vo_table28_f61ba405` He's working!  _(table28.ink:94)_
- `vo_table28_7a9ef0f1` Oh-ho.  _(table28.ink:130)_
- `vo_table28_c380d42c` A woman!  _(table28.ink:148)_
- `vo_table28_664b1845` We were here first. Then Walter. Then everybody else.  _(table28.ink:161)_
- `vo_table28_6a9ba388` He'll be back! They always come back!  _(table28.ink:167)_
- `vo_table28_53e692e8` The owner!  _(table28.ink:193)_
- `vo_table28_c812b378` Hey!  _(table28.ink:214)_
- `vo_table28_47fe33c7` He's a stander.  _(table28.ink:276)_
- `vo_table28_312d60a2` Oh, we will.  _(table28.ink:281)_
- `vo_table28_b9c331f5` There's no rats here.  _(table28.ink:288)_
- `vo_table28_e540f322` Cut off!  _(table28.ink:306)_
- `vo_table28_7ef6ded0` Where's the fire, Big Fella?  _(table28.ink:323)_
- `vo_table28_140cc1ed` Slow down! You'll spill somebody!  _(table28.ink:323)_
- `vo_table28_70db3056` There he goes again!  _(table28.ink:323)_
- `vo_table28_59140fc9` Sit down, you're blocking the hockey!  _(table28.ink:329)_
- `vo_table28_814d1c42` He's back!  _(table28.ink:332)_
- `vo_table28_eb612ef1` The doorman!  _(table28.ink:332)_
- `vo_table28_8642e613` Big fella!  _(table28.ink:332)_
- `vo_table28_c9709856` Look at that. Look at that.  _(table28.ink:369)_
- `vo_table28_f8166638` Never better!  _(table28.ink:376)_
- `vo_table28_cd060d3b` Thirsty!  _(table28.ink:376)_
- `vo_table28_3ce40e39` Cheated by the referees!  _(table28.ink:376)_
- `vo_table28_5cd05415` Down one!  _(table28.ink:387)_
- `vo_table28_a1fdc188` Better than the pool table!  _(table28.ink:390)_
- `vo_table28_9cef42d6` Same as you!  _(table28.ink:395)_
- `vo_table28_091916ec` Same as an hour ago!  _(table28.ink:397)_
- `vo_table28_881a7206` Still thirsty!  _(table28.ink:397)_
- `vo_table28_849bd02b` Ask us again at last call!  _(table28.ink:397)_
- `vo_table28_1c9da61b` Here's the vet!  _(table28.ink:423)_
- `vo_table28_f8d469d8` Here's the traitor!  _(table28.ink:426)_
- `vo_table28_aea18e80` Here's the man who wasn't on the door.  _(table28.ink:429)_
- `vo_table28_70ae7ece` Here's the man who let her in.  _(table28.ink:432)_
- `vo_table28_59727774` Where was the door?  _(table28.ink:478)_

## End Of The Bar (`endbar`)

- `vo_endbar_c31d33e5` Word gets around, you said, on the wharf. It does. Underneath.  _(bar.ink:305)_
- `vo_endbar_8606bdfc` You asked me on the wharf who was asking. It is the right question at a door. It is the wrong one on a wharf.  _(bar.ink:307)_
- `vo_endbar_fb16d687` You looked at the water with me, on the wharf. Very few do. They look at their phones, or at me.  _(bar.ink:309)_
- `vo_endbar_22549328` You are the new door.  _(bar.ink:311)_
- `vo_endbar_3136be7b` This was a cannery, before it was a hotel. Did no one tell you? The tide came in under the floor twice a day, right under where you are standing. Fish heads and salt.  _(bar.ink:313)_
- `vo_endbar_4ca03e66` They built the hotel on the pilings, and the pilings are still there. So is everything that lived in them.  _(bar.ink:314)_
- `vo_endbar_c0b5eb1b` You held a rye at that table and did not drink it. Not many can. I saw.  _(bar.ink:316)_
- `vo_endbar_fcd4d2cc` The owner would like you to deal with them.  _(bar.ink:321)_
- `vo_endbar_7be15ece` People always think it is a matter of poison. It is a matter of terms.  _(bar.ink:323)_
- `vo_endbar_84f3b4ba` Go down, after, when it is quiet. If you would care to talk about it.  _(bar.ink:324)_
- `vo_endbar_e60b76af` Still raining. High water at two, and the wind behind it.  _(bar.ink:329)_
- `vo_endbar_25dfc984` They are listening, you know. In the walls. They hear every word table 28 says.  _(bar.ink:329)_
- `vo_endbar_661afdb1` Terms. It is only ever a matter of terms.  _(bar.ink:329)_
- `vo_endbar_883021e8` You came down, Doorman.  _(closing.ink:1402)_
- `vo_endbar_088dd2fd` You have started a war. That is all right. Most do, the first night.  _(closing.ink:1413)_
- `vo_endbar_dda1eda6` There is poison down. Some of them have eaten it. They will go into the walls to die, and on Friday you will smell them, and so will your customers, and so will the man from the health.  _(closing.ink:1416)_
- `vo_endbar_3ed904b3` And you killed the one at the table. The one they fed. That one had a name. Names cost more.  _(closing.ink:1419)_
- `vo_endbar_c5a8e6cd` And you put it in the one hole the one at the table goes in and out of. He has eaten it. He will be days about it, in the wall behind their chairs. That one had a name. Names cost more.  _(closing.ink:1422)_
- `vo_endbar_25c55d34` You have been courteous. That is noticed.  _(closing.ink:1425)_
- `vo_endbar_fcfc0ec7` You held a glass at that table and did not drink it. Like me.  _(closing.ink:1430)_
- `vo_endbar_74dcd49f` And you left hers standing full on the bar, after. Twice in a night.  _(closing.ink:1434)_
- `vo_endbar_e86a16d6` And you left hers standing full on the bar, after. Like me.  _(closing.ink:1434)_
- `vo_endbar_103d53ff` You poured yourself a glass of her red, behind her bar, and put it down her sink. Very few would.  _(closing.ink:1439)_
- `vo_endbar_45a979d2` You poured yourself a glass of her red with your back to her mirror. A mirror is not the only thing behind a bar.  _(closing.ink:1443)_
- `vo_endbar_c8e5ed58` Two hundred and eight dollars, out of his jacket. He took what he was owed, that one, and not a cent past it. One hears a drawer, through a floor.  _(closing.ink:1447)_
- `vo_endbar_d02a1367` You have his mat in your pocket. He drew us. He was the last who did.  _(closing.ink:1451)_
- `vo_endbar_9d9d7df3` There is a straw in your pocket, Doorman, with somebody else's night on it.  _(closing.ink:1455)_
- `vo_endbar_5e466e24` You reset the traps after the first one. That is noticed too. Differently.  _(closing.ink:1459)_
- `vo_endbar_a567f153` You put the bait where the cook told you. Where we live. The cook should be careful what he tells people.  _(closing.ink:1463)_
- `vo_endbar_2da5b491` You let the lid down on the bins. So tomorrow night I go up that alley in the rain and prop it again. At my age.  _(closing.ink:1467)_
- `vo_endbar_b8691c60` The cook fries an extra basket on Wednesdays. He thinks nobody knows. Now you know, and we know you know.  _(closing.ink:1471)_
- `vo_endbar_bbd2e144` Fifty for every one you see, the cook told you. The cook cannot count.  _(closing.ink:1475)_
- `vo_endbar_ea7d29cf` I am the one who comes down.  _(closing.ink:1483)_
- `vo_endbar_e48bd01c` I was coming in here before she started. Before the owner's father owned it. Before it was a hotel, I was on the dock they built it on.  _(closing.ink:1484)_
- `vo_endbar_9c53fc25` What anyone wants. To eat, and not be killed.  _(closing.ink:1488)_
- `vo_endbar_81500bee` Food on the third step, every night you are on. The kitchen door on the latch after the cook goes home. And you take up what you put down.  _(closing.ink:1489)_
- `vo_endbar_678bcf88` Food on the third step, every night you are on. The kitchen door on the latch after the cook goes home. And no poison. Not in this building.  _(closing.ink:1489)_
- `vo_endbar_9148dc7a` Quiet. Nobody sees one of them on the fourteenth. Not the inspector, not a customer, not the cook.  _(closing.ink:1492)_
- `vo_endbar_7f667210` And they hear everything. Every word said at that table, and under every table, and behind every door in this building. You would be surprised what gets said about a doorman.  _(closing.ink:1493)_
- `vo_endbar_cb7f41c8` Then you know what you are talking to.  _(closing.ink:1498)_
- `vo_endbar_c85c285a` It has been in that wall longer than there has been a wall. The table feeds it and does not know they do. It hears them. It hears everyone.  _(closing.ink:1499)_
- `vo_endbar_df8d3f27` About you?  _(closing.ink:1516)_
- `vo_endbar_33cece15` Everything you said tonight where there was a floor under you or a wall beside you.  _(closing.ink:1517)_
- `vo_endbar_8f45ebca` You put your boot down at that table. On one of ours.  _(closing.ink:1521)_
- `vo_endbar_e1f90586` You told the table your father worked doors, and you told them his name.  _(closing.ink:1525)_
- `vo_endbar_6ca74e5b` You told the table your father worked doors.  _(closing.ink:1525)_
- `vo_endbar_9c53abf8` And in the washroom, to the boy, you said your father died before you had worked it out.  _(closing.ink:1529)_
- `vo_endbar_70bbba44` And in the washroom, to the boy, you said your father drank for twenty years and then stopped.  _(closing.ink:1529)_
- `vo_endbar_37281872` And in the washroom, to the boy, you said your father worked doors, like you.  _(closing.ink:1529)_
- `vo_endbar_5d9eca0b` Ten years on a door in the city, you told them, and you would not say which. They have been talking about it underneath it since.  _(closing.ink:1533)_
- `vo_endbar_e57b8eed` Ten years on a door in the city, you told them, the kind with a line outside. They have been talking about it underneath it since.  _(closing.ink:1533)_
- `vo_endbar_2c81fed3` Ten years on a door in the city, you told them. They have been talking about it underneath it since.  _(closing.ink:1533)_
- `vo_endbar_96100519` You told the man at the pool table you have no children. He believed you.  _(closing.ink:1537)_
- `vo_endbar_676df2fb` You said leave him, at the table. About one of ours. They liked that. So did we.  _(closing.ink:1541)_
- `vo_endbar_23c4812e` You told the table the owner wants us gone. We know what the owner wants. We have known three owners.  _(closing.ink:1545)_
- `vo_endbar_26c93065` You asked them about rats, and they told you there were none. That is the arrangement.  _(closing.ink:1549)_
- `vo_endbar_98a40043` You asked how long he had been coming to that table. Nobody asks.  _(closing.ink:1553)_
- `vo_endbar_0af206c4` She asked if you had found anything down here, and you said no.  _(closing.ink:1557)_
- `vo_endbar_9fa780a7` You told her we are down here. She has always known.  _(closing.ink:1561)_
- `vo_endbar_a688458d` You put the lid back on the bucket, and the traps back on the shelf.  _(closing.ink:1567)_
- `vo_endbar_4f64a236` You put the traps back on the shelf, in their plastic.  _(closing.ink:1569)_
- `vo_endbar_8a3d9ad3` You put the lid back on the bucket.  _(closing.ink:1571)_
- `vo_endbar_c7789847` You left one in the trap where the others would see it. They saw it.  _(closing.ink:1576)_
- `vo_endbar_1c28fb51` Not much. You do not say much. That is noticed too.  _(closing.ink:1579)_
- `vo_endbar_c12633a3` And when the owner rang, she said Yep, twice. You heard her. You did not hear what he asked.  _(closing.ink:1583)_
- `vo_endbar_432115ae` He asked her if you were any good. Yep. Then he asked her to tell him if you were not. Yep.  _(closing.ink:1585)_
- `vo_endbar_e7c7a39d` He asked her if you would last the week. Yep. Then he asked her if that was a good thing, and she said Yep again, the same way, and he could not tell. Neither could we.  _(closing.ink:1587)_
- `vo_endbar_7612729b` Very good.  _(closing.ink:1595)_
- `vo_endbar_52a2a4af` The step, then. And no poison. We will find our own doors.  _(closing.ink:1608)_
- `vo_endbar_e3a1dff3` Then no terms. Not tonight.  _(closing.ink:1619)_
- `vo_endbar_fbbc3399` Come down again when you are ready to talk like somebody who needs something.  _(closing.ink:1620)_
- `vo_endbar_36d866ad` Then it is the long way.  _(closing.ink:1628)_
- `vo_endbar_c308dcc6` It is always the long way, the first time.  _(closing.ink:1630)_
- `vo_endbar_b3107bad` Then you will burn the hotel down with them. They are in every wall. They were here before the walls.  _(closing.ink:1639)_
- `vo_endbar_7b31ffaf` That is the first time I have done that.  _(closing.ink:1641)_
- `vo_endbar_14296bea` Think, then. They will not wait for you. They will double while you think. They always do.  _(closing.ink:1648)_
- `vo_endbar_462267e2` Good evening.  _(walk.ink:43)_
- `vo_endbar_54feeeac` One hears the Sovereign has a doorman again.  _(walk.ink:44)_
- `vo_endbar_58fa9a0c` Everything gets around, in a town on pilings. It is all underneath, going back and forth.  _(walk.ink:51)_
- `vo_endbar_3f2f50e3` Nobody is asking, Doorman. I am telling you I heard.  _(walk.ink:54)_
- `vo_endbar_6df3ace6` Just so.  _(walk.ink:58)_
- `vo_endbar_fedfed40` Another, if you would. The same as before.  _(talk.yaml endbar_tide)_
- `vo_endbar_844603f8` The tide is on the turn. One can hear it under the floor.  _(talk.yaml endbar_tide)_

Changing with the night (record the bark instead, or ask for these to be split):

- {rats_killed == 1:You have killed one\|You have killed {num(rats_killed)}}. That is noticed too.  _(closing.ink:1478)_

## Gary (`owner`)

- `vo_owner_f5d734e0` How is it tonight?  _(bar.ink:396)_
- `vo_owner_6cae7a19` That's a Wednesday. I can live with a Wednesday.  _(bar.ink:405)_
- `vo_owner_991dcc15` Quiet. Sure. Wednesday's quiet, I know Wednesday's quiet. I just like to hear it.  _(bar.ink:412)_
- `vo_owner_716fa1eb` Busy. Good. That's what I like to hear, buddy.  _(bar.ink:417)_
- `vo_owner_2fd58ebd` Now. The rats. Did we do something about the rats?  _(bar.ink:420)_
- `vo_owner_11a6b573` Good man. That's what I like to hear.  _(bar.ink:423)_
- `vo_owner_80ac091d` Traps. Fine, fine. Traps are a start.  _(bar.ink:426)_
- `vo_owner_40316e4f` One at a time. Buddy, there's hundreds of them, and the inspector's on the fourteenth.  _(bar.ink:429)_
- `vo_owner_c01c237e` There's a bucket of bait in the office. I paid for that bait. Put it down.  _(bar.ink:430)_
- `vo_owner_5558c6b3` Good. I'm going to hold you to that. The fourteenth.  _(bar.ink:434)_
- `vo_owner_d1a3661f` Not yet. The inspector is on the fourteenth. Not yet is not a thing I can put in front of an inspector.  _(bar.ink:438)_
- `vo_owner_0bcc4792` And listen. Table 28 get whatever they want. That's half my Wednesday right there.  _(bar.ink:440)_
- `vo_owner_015d0764` And a fella might come by tonight, good coat. Graham. That'll be what you rang about. We had a talk. He's all right now, let him in.  _(bar.ink:443)_
- `vo_owner_b1d2f63e` And a fella might come by tonight, good coat. We had a talk. He's all right now, let him in.  _(bar.ink:443)_
- `vo_owner_c17ca203` And whatever you rang about, it can't have been much. Nobody's called me about it.  _(bar.ink:448)_
- `vo_owner_eba7e23b` Fella in a good coat called me. Graham. Says you let him in for one and then put him out. That'll be what you rang about.  _(bar.ink:454)_
- `vo_owner_36c9093b` Fella in a good coat tried to come in tonight? Says you turned him away at the door. That'll be what you rang about.  _(bar.ink:456)_
- `vo_owner_a87ecf2b` Fella in a good coat tried to come in tonight? Says you turned him away at the door.  _(bar.ink:456)_
- `vo_owner_0f696ee6` And he says he went down on our floor, in the door. Flat on his back in a good coat. Is that right?  _(bar.ink:460)_
- `vo_owner_2dcfd2cc` That book's old, buddy.  _(bar.ink:465)_
- `vo_owner_61b9735c` Fine, fine. We'll talk about it.  _(bar.ink:466)_
- `vo_owner_b6cbba6d` She writes a lot of things.  _(bar.ink:472)_
- `vo_owner_4beab923` Put her on.  _(bar.ink:474)_
- `vo_owner_e937d59e` Good man.  _(bar.ink:480)_
- `vo_owner_f65adee2` Good. Good. Put her back on, my food's here.  _(bar.ink:491)_
- `vo_owner_3b0dc12f` Come in, come in. Gary. Grab a seat.  _(office.ink:42)_
- `vo_owner_8be7dbdc` So. First thing. There's a room.  _(office.ink:67)_
- `vo_owner_61e8e6d8` Upstairs at the Sov, end of the second floor, over the deck. Comes with the job. Six a month, and it comes off the top.  _(office.ink:68)_
- `vo_owner_ec973ab5` You got your licence on you? The security one.  _(office.ink:71)_
- `vo_owner_685c6168` So where were you before this?  _(office.ink:91)_
- `vo_owner_f596dee9` Ten years. In the city.  _(office.ink:96)_
- `vo_owner_f98b845d` Where up island?  _(office.ink:103)_
- `vo_owner_b46abde3` Around. Okay. Around.  _(office.ink:110)_
- `vo_owner_4acc522e` Yeah? Where?  _(office.ink:116)_
- `vo_owner_684cefd3` And why'd you leave?  _(office.ink:125)_
- `vo_owner_121aba6c` Ha. Well. That's not a thing here.  _(office.ink:130)_
- `vo_owner_0daac0d8` I don't need the how.  _(office.ink:138)_
- `vo_owner_b5398b25` They all are, buddy. They all are.  _(office.ink:145)_
- `vo_owner_c009de26` You been in fights?  _(office.ink:155)_
- `vo_owner_5e6b696e` Plenty. Okay. Not in my bar, plenty.  _(office.ink:161)_
- `vo_owner_40efda7f` Good. Good man.  _(office.ink:166)_
- `vo_owner_726d6501` That's what I'm paying for. Stopping them.  _(office.ink:171)_
- `vo_owner_384143e0` Never. Okay.  _(office.ink:177)_
- `vo_owner_3f34fed4` Ha. Okay. Ha. Jesus.  _(office.ink:190)_
- `vo_owner_34ed470e` Sorry. I gotta. Two minutes.  _(office.ink:200)_
- `vo_owner_0988a8ed` Yeah. No. No, the halibut's Thursday. Friday's the prime rib. Friday, Ron. Friday is the prime rib.  _(office.ink:201)_
- `vo_owner_4dfd7927` Yeah. Yeah. Okay. Friday, Ron.  _(office.ink:236)_
- `vo_owner_ac630080` Sorry. Suppliers. Where were we.  _(office.ink:238)_
- `vo_owner_18d60cce` Where you going?  _(office.ink:243)_
- `vo_owner_1eaffbd3` You drink?  _(office.ink:257)_
- `vo_owner_9d388559` Good. Good man. Not on my till.  _(office.ink:261)_
- `vo_owner_8d56c794` Ha! Not me, buddy.  _(office.ink:266)_
- `vo_owner_0c2ad6ad` Ha. Doug would know.  _(office.ink:277)_
- `vo_owner_0d59ff61` It's four o'clock somewhere. It's four o'clock here.  _(office.ink:284)_
- `vo_owner_d10bce78` Ha! Okay! Okay.  _(office.ink:304)_
- `vo_owner_e750de0c` Okay. Table 28.  _(office.ink:310)_
- `vo_owner_a6c00ea6` Five guys in the front window, every day but Sunday, since about the Flood. They don't get cut off. That's the rule.  _(office.ink:311)_
- `vo_owner_04d48513` That's my dad's rule. So one of them's had enough. More than. What do you do?  _(office.ink:313)_
- `vo_owner_61ad7382` Water. Okay. Water doesn't go through the till, buddy.  _(office.ink:318)_
- `vo_owner_d8a004dc` He walks. They all walk. Mostly.  _(office.ink:330)_
- `vo_owner_6689081b` Whoa. No. No no. That's not a thing.  _(office.ink:336)_
- `vo_owner_86a7c49d` I'm there. I'm there when I'm there, buddy.  _(office.ink:342)_
- `vo_owner_d3c994ff` Questions? Anything?  _(office.ink:346)_
- `vo_owner_eec2b212` He left. Friday, middle of the rush. Left his jacket.  _(office.ink:350)_
- `vo_owner_76745b0b` There's an inspector. The fourteenth. Routine. There's a few. Things.  _(office.ink:370)_
- `vo_owner_4d15820a` You'll see a note.  _(office.ink:371)_
- `vo_owner_593f9239` Okay. Here's what it is.  _(office.ink:375)_
- `vo_owner_f3ef0eff` Twenty an hour. Tonight's cash, it's a test. After that it's Wednesday to Saturday, and the room comes off the top.  _(office.ink:376)_
- `vo_owner_ec709855` Did I? Well. Hydro.  _(office.ink:388)_
- `vo_owner_10b47090` And wear this.  _(office.ink:405)_
- `vo_owner_638eb6e7` Good. Good man. Professional.  _(office.ink:413)_
- `vo_owner_cc094582` Suit yourself.  _(office.ink:416)_
- `vo_owner_fc854dad` Tonight's cash. After that she does it her way. Everybody does it her way.  _(office.ink:431)_
- `vo_owner_7485411c` Twelve. End of the hall, over the deck. Terry's got the other key. Terry's got every key.  _(office.ink:447)_
- `vo_owner_5626c45b` Seven-thirty, quarter to eight. She'll show you. She was my dad's.  _(office.ink:449)_
- `vo_owner_4f852bd2` Okay, buddy. Okay. I think we're done.  _(office.ink:493)_
- `vo_owner_cd1e9ae7` Okay, buddy.  _(office.ink:495)_
- `vo_owner_b3ac33d3` Yeah. Okay. Suit yourself, buddy.  _(office.ink:499)_
- `vo_owner_0f5afbc6` Two years.  _(room.ink:487)_
- `vo_owner_4547b36d` Jesus. That's the first thing he'll look at, after the kitchen and the rats. Before the fourteenth, that has to be.  _(room.ink:488)_
- `vo_owner_ff91be83` I'll have a guy out. Good man.  _(room.ink:489)_

Changing with the night (record the bark instead, or ask for these to be split):

- Somebody rang me from the bar phone at {q_words(owner_missed)}. I'm at dinner here.  _(bar.ink:398)_

## Hoodie (`hoodie`)

- `vo_hoodie_e029e41f` yeah  _(door.ink:112)_
- `vo_hoodie_d08328a5` nice shirt  _(door.ink:117)_
- `vo_hoodie_082e32d1` hey. that's my phone  _(door.ink:143)_
- `vo_hoodie_784b8e1c` it's been raining since tuesday  _(door.ink:182)_
- `vo_hoodie_a110e6b9` what  _(door.ink:193)_
- `vo_hoodie_7a4d63b1` truck  _(door.ink:198)_
- `vo_hoodie_b9d3cfe3` my sister  _(door.ink:204)_
- `vo_hoodie_d3adc33a` and her boyfriend. he's not coming in. he's like, asleep  _(door.ink:206)_
- `vo_hoodie_5b474922` looking for someone  _(door.ink:211)_
- `vo_hoodie_2433c568` just someone  _(door.ink:214)_
- `vo_hoodie_c26ce703` it's not gonna work  _(door.ink:232)_
- `vo_hoodie_37c11ede` it didn't work the first time either. it's a picture  _(door.ink:233)_
- `vo_hoodie_f6fb648d` it's literally in the truck though  _(door.ink:277)_
- `vo_hoodie_36c36eb7` yeah ok. fair  _(door.ink:282)_
- `vo_hoodie_13fbd79c` k  _(door.ink:286)_
- `vo_hoodie_2a1b875b` fine  _(door.ink:326)_
- `vo_hoodie_4fdf01e9` she's not gonna  _(door.ink:335)_
- `vo_hoodie_2fed66b9` she can't. i mean she won't  _(door.ink:336)_
- `vo_hoodie_55400ffe` told you  _(door.ink:520)_
- `vo_hoodie_060d1cfe` occupied  _(hall.ink:190)_
- `vo_hoodie_22076940` you said where you can see me  _(hall.ink:193)_
- `vo_hoodie_d5b32a74` you can see the door  _(hall.ink:194)_
- `vo_hoodie_319fa7a3` is he still out there  _(hall.ink:201)_
- `vo_hoodie_7a85f476` ok  _(hall.ink:239)_
- `vo_hoodie_e144df8b` what the fuck man  _(hall.ink:252)_
- `vo_hoodie_2282a829` i'm not doing anything. i'm sitting  _(hall.ink:254)_
- `vo_hoodie_d869db7f` whatever  _(hall.ink:256)_
- `vo_hoodie_0b606130` i'm not high  _(hall.ink:270)_
- `vo_hoodie_e7aab894` everybody thinks i'm high. i just haven't slept  _(hall.ink:271)_
- `vo_hoodie_a2a2be14` and i didn't drink. you said  _(hall.ink:273)_
- `vo_hoodie_c9788055` monday i think  _(hall.ink:279)_
- `vo_hoodie_e7260b41` she was bad all night. we called the ambulance at like six. then we were at the hospital all day. they don't tell you anything. you just sit there  _(hall.ink:280)_
- `vo_hoodie_477262b2` they think it's her heart. or they thought that and now they don't know. she's fifty-one  _(hall.ink:292)_
- `vo_hoodie_21737fef` she told us to come get him. she said he'd want to know. she said he'd want to be there  _(hall.ink:293)_
- `vo_hoodie_aeb4893d` i don't think he'd want to be there  _(hall.ink:294)_
- `vo_hoodie_c276e132` cause he won't make a scene with me. with her he makes a scene. with kyle he'd, like. kyle would end up outside  _(hall.ink:299)_
- `vo_hoodie_cf5abb79` i'm the one who doesn't say anything. so they thought if i said something he'd listen  _(hall.ink:300)_
- `vo_hoodie_f110a3f7` i haven't said anything  _(hall.ink:301)_
- `vo_hoodie_da28a960` her playlist  _(hall.ink:309)_
- `vo_hoodie_0b523202` my mom's. it's on the family account. she made it for the car so we'd stop fighting about the aux  _(hall.ink:310)_
- `vo_hoodie_acc06041` i've had it on since the ambulance  _(hall.ink:311)_
- `vo_hoodie_6e3f5ad7` thanks  _(hall.ink:317)_
- `vo_hoodie_954f22b3` like drank drank?  _(hall.ink:331)_
- `vo_hoodie_2ef66c84` did it help  _(hall.ink:334)_
- `vo_hoodie_4a3c5bd3` that's something i guess  _(hall.ink:337)_
- `vo_hoodie_dd7b1d02` sorry  _(hall.ink:343)_
- `vo_hoodie_4c5a185f` that's shit  _(hall.ink:344)_
- `vo_hoodie_e03a691e` so you're like him  _(hall.ink:348)_
- `vo_hoodie_ff339055` same  _(hall.ink:355)_
- `vo_hoodie_e3c93d74` i don't know  _(hall.ink:361)_
- `vo_hoodie_e1cb047d` i want to go home and sleep. i want my mom to not be in the hospital. i want him to just come, without me having to make him  _(hall.ink:362)_
- `vo_hoodie_17b538b2` ok. thanks  _(hall.ink:365)_
- `vo_hoodie_8a02495f` mom's in the hospital  _(hall.ink:397)_
- `vo_hoodie_701c45ba` in town. since this morning. we've been trying to call you  _(hall.ink:402)_
- `vo_hoodie_c9bc849a` now  _(hall.ink:410)_
- `vo_hoodie_7f550a9f` hey  _(pool.ink:245)_
- `vo_hoodie_35bacaf6` i'm not doing anything  _(pool.ink:248)_
- `vo_hoodie_0134950b` that's my dad  _(pool.ink:263)_
- `vo_hoodie_ccb41520` i'm supposed to tell him something. well my sister's supposed to. she sent me in cause she thought he wouldn't make a scene with me or whatever  _(pool.ink:267)_
- `vo_hoodie_cd25d7d4` i need to piss  _(pool.ink:268)_
- `vo_hoodie_64b4b162` no one  _(pool.ink:273)_
- `vo_hoodie_9e715a00` yeah. i mean yeah  _(pool.ink:280)_
- `vo_hoodie_9842aec8` what? no  _(pool.ink:284)_

## The Driver (`driver`)

- `vo_driver_174534c6` Thank you.  _(closing.ink:510)_
- `vo_driver_0dab6041` We're not here to drink. Our dad's at the pool table. Our mom's in the hospital in town, since this morning, and he won't answer his phone.  _(deck.ink:198)_
- `vo_driver_83e12f07` You wouldn't let my brother in. So.  _(deck.ink:199)_
- `vo_driver_b85b9d76` Our mom's in the hospital in town. Since this morning. He doesn't know. That's all this is.  _(deck.ink:210)_
- `vo_driver_4371ac30` Okay.  _(deck.ink:216)_
- `vo_driver_e571d83f` We've been waiting in the truck. Since eight.  _(deck.ink:221)_
- `vo_driver_2522d957` He'll say he's coming after.  _(deck.ink:253)_
- `vo_driver_ccd543f9` He always says after.  _(deck.ink:254)_
- `vo_driver_1d8e7592` What.  _(deck.ink:266)_
- `vo_driver_7251ae43` Is my brother okay?  _(deck.ink:268)_
- `vo_driver_7e2a41fc` You said wait in the truck. We're waiting in the truck.  _(deck.ink:271)_
- `vo_driver_cceab3d8` Our mom's in the hospital in town. Since this morning. He's not answering his phone.  _(deck.ink:276)_
- `vo_driver_8343615f` He never answers when he's in there.  _(deck.ink:277)_
- `vo_driver_9be9207e` He won't come.  _(deck.ink:285)_
- `vo_driver_afffe726` But okay. Thank you.  _(deck.ink:286)_
- `vo_driver_3c82beed` We'll be here.  _(deck.ink:316)_
- `vo_driver_b8175e48` You said no.  _(deck.ink:320)_
- `vo_driver_c685db50` Okay. Good for you.  _(deck.ink:327)_
- `vo_driver_3b8e261c` My brother was just at this door. His licence is in the truck. It's been in the truck the whole time.  _(door.ink:370)_
- `vo_driver_8aae63f9` My brother was just here. He said you were decent about it. Thank you for that.  _(door.ink:372)_
- `vo_driver_1aebe310` My brother was just at this door, and you told him no. That's fine. That's not why I'm here.  _(door.ink:374)_
- `vo_driver_210a5d14` My brother texted me. He says he can only stay if I come in. So I'm here.  _(door.ink:376)_
- `vo_driver_25b864e7` My brother's in there. Grey hoodie, nineteen. He's with me.  _(door.ink:378)_
- `vo_driver_880d4849` Shut up, Kyle.  _(door.ink:382)_
- `vo_driver_e4f87110` Our dad. Big guy. He'll be at the pool table, he's always at the pool table.  _(door.ink:401)_
- `vo_driver_45bab0eb` Our mom's in the hospital in town. Since this morning. He's not answering his phone. He's not answering anybody.  _(door.ink:408)_
- `vo_driver_65ec04f7` He doesn't answer when he's here.  _(door.ink:409)_
- `vo_driver_8cfc45a1` His truck's right there.  _(door.ink:458)_
- `vo_driver_a7c0678a` Okay. He's not here.  _(door.ink:461)_
- `vo_driver_32353313` Kyle.  _(door.ink:463)_
- `vo_driver_9a04daa9` Kyle. Truck.  _(door.ink:479)_
- `vo_driver_9a79fce0` Can my brother come in, please. He's nineteen. You saw the picture.  _(door.ink:491)_
- `vo_driver_5fd81928` It's in the glovebox. It's been in the glovebox all night.  _(door.ink:510)_
- `vo_driver_9fe099df` You'd do that? Okay. Thank you.  _(door.ink:579)_
- `vo_driver_406257ca` Tell my brother to come out too, please. He's no use in there. He won't even talk to him.  _(door.ink:583)_
- `vo_driver_174778fb` Okay. Thank you.  _(door.ink:598)_
- `vo_driver_f6e87d35` You told him he could stay if I came in.  _(door.ink:600)_
- `vo_driver_06f3f3d0` So which is it.  _(door.ink:601)_
- `vo_driver_ca69a7e6` One second, please.  _(hall.ink:151)_
- `vo_driver_734e894c` He saw me. He looked right at me, and went back to his shot.  _(hall.ink:153)_
- `vo_driver_28ed18fd` Our mom's in the hospital in town. Since this morning. They don't know what it is yet. He's her husband, and he doesn't know. Or he knows, and he's playing pool.  _(hall.ink:155)_
- `vo_driver_f1b8f038` Would you.  _(hall.ink:161)_
- `vo_driver_b7838684` He's had since six this morning.  _(hall.ink:167)_
- `vo_driver_f98abd0e` That's what my mom says.  _(hall.ink:170)_
- `vo_driver_3ebc05a6` After what.  _(pool.ink:398)_
- `vo_driver_28896bd4` We didn't hit anybody. He did.  _(pool.ink:623)_
- `vo_driver_98e5c330` He left his jacket. His phone's in it.  _(room.ink:657)_
- `vo_driver_ba9067e0` The hospital keeps calling it, and he hasn't got it, and he won't use mine. So.  _(room.ink:658)_
- `vo_driver_c72e2562` She's okay. They're keeping her. It's not her heart, they think now. They don't know what it is.  _(room.ink:668)_
- `vo_driver_49d83254` It was in the pocket.  _(room.ink:675)_
- `vo_driver_f9e6ab79` It was in that pocket all night. I called it twenty-six times.  _(room.ink:676)_

## The Big Man (`bigman`)

- `vo_bigman_31e8cd8b` One more.  _(closing.ink:326)_
- `vo_bigman_363e8433` I know, bud. I know she is.  _(closing.ink:362)_
- `vo_bigman_c8f70629` And do what, eh. Sit there.  _(closing.ink:363)_
- `vo_bigman_a802bac5` You told her I wasn't here.  _(closing.ink:432)_
- `vo_bigman_64e6dc68` Thanks, bud.  _(closing.ink:433)_
- `vo_bigman_8a107311` You haven't got kids. You said. So don't.  _(closing.ink:454)_
- `vo_bigman_2b4ca95f` Not that you know of, you said. Then you don't know.  _(closing.ink:456)_
- `vo_bigman_b4f3494d` You asked me if I had kids.  _(closing.ink:458)_
- `vo_bigman_ca39585e` Look at 'em. Better than me, I told you. They'll manage.  _(closing.ink:460)_
- `vo_bigman_05f67742` Bud. Bud. My keys.  _(closing.ink:1307)_
- `vo_bigman_cd672569` Yeah, okay.  _(closing.ink:1339)_
- `vo_bigman_02a687f0` Where.  _(hall.ink:401)_
- `vo_bigman_b0170c4a` I'll come by after, bud.  _(hall.ink:407)_
- `vo_bigman_46f9d37c` Don't.  _(hall.ink:414)_
- `vo_bigman_b5ac4cfd` You'd be the new one, bud.  _(pool.ink:150)_
- `vo_bigman_22b62533` Lot of doors in this old place for one fella.  _(pool.ink:151)_
- `vo_bigman_88a4139f` Wednesdays. Well. Most days, lately.  _(pool.ink:154)_
- `vo_bigman_67a10e0a` Now that's between me and him.  _(pool.ink:160)_
- `vo_bigman_7ae684ec` Me and him.  _(pool.ink:162)_
- `vo_bigman_873a59c5` Ah, it's been a week, bud. One of them weeks.  _(pool.ink:168)_
- `vo_bigman_a99a279a` Family stuff. You know how it is.  _(pool.ink:169)_
- `vo_bigman_19c98d02` Do me a favour, eh. Anybody comes in here looking for me tonight, I'm not here. You never saw me.  _(pool.ink:171)_
- `vo_bigman_721d0b3c` Ah, can't complain.  _(pool.ink:176)_
- `vo_bigman_6a81a199` Appreciate it.  _(pool.ink:187)_
- `vo_bigman_dff3953b` Sure. Forget I asked, then.  _(pool.ink:194)_
- `vo_bigman_99c97a2a` Rack 'em, then. You any good?  _(pool.ink:201)_
- `vo_bigman_274bb193` You got kids yourself?  _(pool.ink:218)_
- `vo_bigman_d478b944` Nah. That's not right. They're good kids. It's me that's the problem.  _(pool.ink:223)_
- `vo_bigman_33ca144f` Two. My girl and the boy. Grown, near enough, and better than me.  _(pool.ink:229)_
- `vo_bigman_2b2e316b` Low bar.  _(pool.ink:230)_
- `vo_bigman_f6ebbc7b` One thing, bud. I asked you one thing.  _(pool.ink:298)_
- `vo_bigman_b7a90013` Since when.  _(pool.ink:331)_
- `vo_bigman_af9977e5` Where are they.  _(pool.ink:338)_
- `vo_bigman_26dc46c8` Yeah, okay. I'll just finish this game.  _(pool.ink:391)_
- `vo_bigman_f5a05242` Tell 'em I'll come by after, eh. Tell 'em I'm coming.  _(pool.ink:392)_
- `vo_bigman_8c8d4f56` Who asked you.  _(pool.ink:431)_
- `vo_bigman_4f1fe598` Expecting company, bud?  _(room.ink:66)_
- `vo_bigman_6b18dafe` Yeah. Let it go, bud.  _(room.ink:585)_
- `vo_bigman_6d604030` That'll be my girl. She can wait.  _(room.ink:587)_
- `vo_bigman_7d3f5702` That's my coat, bud.  _(room.ink:603)_
- `vo_bigman_0cf192de` I left you that.  _(talk.yaml pool_double)_
- `vo_bigman_9c335068` Rack 'em, bud.  _(talk.yaml pool_double)_
- `vo_bigman_c906b8be` Shoot your ball.  _(talk.yaml pool_quiet)_

## Scratch (`scratch`)

- `vo_scratch_8b757cfd` That dog's been dead since the flood.  _(closing.ink:740)_
- `vo_scratch_047b359b` That's poison.  _(closing.ink:822)_
- `vo_scratch_e81cbfae` That was in Walter's door.  _(closing.ink:823)_
- `vo_scratch_33f63856` You were never in the city.  _(rats.ink:470)_
- `vo_scratch_d86c4a30` Something happened.  _(rats.ink:474)_
- `vo_scratch_4f9c4bb0` Unless something happened.  _(rats.ink:478)_
- `vo_scratch_45c3de46` Up island. They're all from up island.  _(rats.ink:483)_
- `vo_scratch_3c92003e` Keg room. I saw him go down. Bad luck, that keg room.  _(rats.ink:488)_
- `vo_scratch_c77ec08e` Is that Walter? That's not Walter.  _(rats.ink:580)_
- `vo_scratch_b3217233` That's Walter.  _(rats.ink:680)_
- `vo_scratch_cfc1730d` HAARP. They've got the thing in Alaska pointed right at us.  _(room.ink:316)_
- `vo_scratch_e2564efe` Or it's a psyop. They put it up there to see if we'll argue about it.  _(room.ink:320)_
- `vo_scratch_fea9ed0d` That's what they say. That's exactly what they'd say.  _(room.ink:327)_
- `vo_scratch_8fcd1166` Everybody's from up island, kid. I'd have bet on it.  _(table28.ink:43)_
- `vo_scratch_842f4f0f` He's savouring it. Let him. It's bad luck to rush the first one.  _(table28.ink:124)_
- `vo_scratch_feca901e` He saw the big rat, down in the keg room. Came up white as a sheet. You don't come back from a sign like that.  _(table28.ink:146)_
- `vo_scratch_f8462c07` Walter? Longer than you, kid. Longer than any rat's got a right to.  _(table28.ink:159)_
- `vo_scratch_be73daea` The owner's never met anybody. He's in town.  _(table28.ink:195)_
- `vo_scratch_3ad8d072` That was Walter.  _(table28.ink:209)_
- `vo_scratch_6cce5450` What rats?  _(table28.ink:287)_
- `vo_scratch_63c0e29a` He came out and didn't want his fry. He always wants his fry.  _(table28.ink:355)_
- `vo_scratch_62f4a787` Went straight back in the wall.  _(table28.ink:356)_
- `vo_scratch_64695611` He's in the wall. He'll be out when the fries come, you can bet on it.  _(table28.ink:359)_
- `vo_scratch_e780c2b9` Having a lie-down.  _(table28.ink:359)_
- `vo_scratch_f81d81d2` Busy. Counting his winnings.  _(table28.ink:359)_
- `vo_scratch_04fca8b9` Walter didn't want his fry.  _(table28.ink:384)_
- `vo_scratch_2bb7fdff` Walter hasn't come out.  _(table28.ink:444)_
- `vo_scratch_8a4e46dd` He always comes out when the fries come.  _(table28.ink:446)_
- `vo_scratch_4b855f95` It'll come down. It's due.  _(talk.yaml t28_diesel)_
- `vo_scratch_b7eb8e54` A dollar ten.  _(talk.yaml t28_eggs)_
- `vo_scratch_b40767b6` He's big. Big's a good sign on a door.  _(talk.yaml t28_new_kid)_
- `vo_scratch_64975fca` I don't like his numbers.  _(talk.yaml t28_new_kid_bad)_
- `vo_scratch_0d75d03c` It's HAARP. They've got it pointed right at us.  _(talk.yaml t28_news_light)_
- `vo_scratch_c7050f0a` That's exactly what they'd say.  _(talk.yaml t28_news_balloon)_
- `vo_scratch_2ee364de` He's got it. He's got it. He hasn't got it.  _(talk.yaml t28_curling)_

## Cardigan (`cardigan`)

- `vo_cardigan_9ed00054` The washroom.  _(closing.ink:778)_
- `vo_cardigan_6948d084` I've quit a good many times.  _(closing.ink:790)_
- `vo_cardigan_a3f316f6` Please don't tell them I'm out here. They think I've gone to the washroom.  _(deck.ink:104)_
- `vo_cardigan_339aa772` Since the mill was three shifts. There were nine of us at that table, once. You couldn't get a chair.  _(deck.ink:109)_
- `vo_cardigan_aafc0547` Now there's five. Four, some days.  _(deck.ink:110)_
- `vo_cardigan_0d4c6ccd` What always happens. Two of them died. One is in the home in town and doesn't know anybody. And one went to Alberta to be near his grandchildren, and we never heard from him again. Not once. As if he'd died, except he hadn't.  _(deck.ink:113)_
- `vo_cardigan_5e19a2b4` The table closed up the gap. It always does.  _(deck.ink:114)_
- `vo_cardigan_c82a9318` My daughter wants me in Calgary.  _(deck.ink:116)_
- `vo_cardigan_acedd23e` I don't know.  _(deck.ink:119)_
- `vo_cardigan_bb2d7250` If I go, they'll close up the gap. If I stay, I'll die at that table. Those are the choices. Everyone at that table has had them.  _(deck.ink:120)_
- `vo_cardigan_b2f44ed3` It's easy for you to say, I suppose.  _(deck.ink:124)_
- `vo_cardigan_c53c562d` Yes.  _(deck.ink:128)_
- `vo_cardigan_990dddcd` Yes. That's what they would say.  _(deck.ink:129)_
- `vo_cardigan_f862c206` No. Nobody does.  _(deck.ink:132)_
- `vo_cardigan_2f0d7d95` Not a word to them, please.  _(deck.ink:136)_
- `vo_cardigan_840caf8f` His father worked doors. You can see it on him. He stands as if somebody's watching him do it.  _(rats.ink:481)_
- `vo_cardigan_c415c179` My brother-in-law says the Air Force told the paper it's a weather balloon.  _(room.ink:318)_
- `vo_cardigan_a170982c` Ten years is a long time to stand outside a building.  _(table28.ink:56)_
- `vo_cardigan_5ffa13fa` Here? On the island, I mean.  _(table28.ink:70)_
- `vo_cardigan_9f35132d` What was his name? If you don't mind my asking.  _(table28.ink:72)_
- `vo_cardigan_35d58dbd` I think it always matters. To somebody.  _(table28.ink:81)_
- `vo_cardigan_c43d88c5` I think he let somebody in that he shouldn't have. That's all it was. It happens to all of them, sooner or later.  _(table28.ink:149)_
- `vo_cardigan_71f40cce` They were here before him, you know. The rats. Before the hotel, I'd think. This was a cannery once, built out over the water, and the tide went in and out under the floor. You don't get rid of rats in a building like this. You come to an arrangement with them.  _(table28.ink:196)_
- `vo_cardigan_c9e939f3` I've been thinking, that's all.  _(table28.ink:392)_
- `vo_cardigan_626191a6` When the mill ran three shifts, you couldn't get a table in here on a Wednesday.  _(talk.yaml t28_mill)_
- `vo_cardigan_c40d9560` He said good evening to me. I can't remember the last one who did that.  _(talk.yaml t28_new_kid)_
- `vo_cardigan_48c3b112` My brother-in-law says the Air Force told the paper it's a balloon.  _(talk.yaml t28_news_balloon)_
- `vo_cardigan_42548021` It's nice, actually, without it. You can hear yourself think.  _(talk.yaml t28_tv_off)_

## The Cook (`cook`)

- `vo_cook_229d2ec3` Hey. Hey! That door is my air, Security.  _(floor.ink:439)_
- `vo_cook_41a1a0db` It's a hundred and ten on the line. A hundred and ten! It stays open or I cook.  _(floor.ink:441)_
- `vo_cook_37199d80` Every time I turn around! Every goddamn time!  _(floor.ink:445)_
- `vo_cook_db5c26d7` Security, eh? Behind you. Behind!  _(rats.ink:37)_
- `vo_cook_537a2a85` Don't lean on anything. It's all hot or it's all wet, and that flat-top's a bastard, it'll have your hand off.  _(rats.ink:38)_
- `vo_cook_83658daf` Dealt with. Dealt with! Sure.  _(rats.ink:74)_
- `vo_cook_3f591830` Pipe chase behind the walk-in, up from the keg room. Every morning, droppings on my prep table, every morning I'm bleaching the son of a bitch before I've had a coffee.  _(rats.ink:75)_
- `vo_cook_32241a91` Inspector finds one dropping, he shuts the kitchen. Kitchen's shut, I don't get paid, and I've got a, never mind. So yeah. Dealt with would be nice.  _(rats.ink:76)_
- `vo_cook_5fa296d4` Bucket of bait in the office, downstairs, past the kegs. Owner bought it in the summer. Box of traps right beside it, still in the plastic.  _(rats.ink:81)_
- `vo_cook_15634ddf` She won't let anybody put it down. Something about table 28 and their goddamn pet.  _(rats.ink:82)_
- `vo_cook_234cf833` I'm not getting into it with table 28. I work here. Some of us work here.  _(rats.ink:84)_
- `vo_cook_c0d648f0` You see one, there's fifty. Me? I've seen a lot more than one, Security.  _(rats.ink:88)_
- `vo_cook_a7855987` Bait. Keg room, where they live. They eat it, they crawl in the walls and die, it stinks for a week, done.  _(rats.ink:93)_
- `vo_cook_53c7a21b` Traps are for people who want to feel useful. You'll catch three.  _(rats.ink:94)_
- `vo_cook_be9d2013` I know they do. Who do you think fries the fries?  _(rats.ink:99)_
- `vo_cook_246148d5` An extra basket, Wednesdays. Don't tell her.  _(rats.ink:100)_
- `vo_cook_b232df35` I don't care what they feed. I care what's on my prep table at seven in the morning.  _(rats.ink:101)_
- `vo_cook_591a7809` Don't touch anything back there! That compressor's held together with tape.  _(rats.ink:119)_
- `vo_cook_c6af562a` Take 'em, take 'em. Nobody's eating those.  _(rats.ink:127)_
- `vo_cook_4866620c` Table 28'll want 'em for the rat.  _(rats.ink:129)_
- `vo_cook_f4bfa212` Thanks, Security.  _(rats.ink:151)_
- `vo_cook_c523e01b` Are you kidding me? The inspector sees that, it's my kitchen he shuts, not yours.  _(rats.ink:304)_
- `vo_cook_45194164` Great. Beautiful. Now I lose a finger.  _(rats.ink:352)_
- `vo_cook_183f75e6` Not through my kitchen! Not by the tail! Come on, Security, I've got food out.  _(rats.ink:535)_
- `vo_cook_80ccbca1` You're kidding me. You're kidding me, right?  _(rats.ink:640)_

## Vape (`vape`)

- `vo_vape_feb7f899` bro. i was just out here  _(deck.ink:142)_
- `vo_vape_924fea87` i've been out here the WHOLE time my guy  _(deck.ink:143)_
- `vo_vape_b1cef045` she's not gonna let me in  _(deck.ink:147)_
- `vo_vape_26607019` it's LOCKED  _(deck.ink:151)_
- `vo_vape_256d5525` she locked it bro. she locked me out  _(deck.ink:152)_
- `vo_vape_7b044652` appreciate you chief  _(deck.ink:170)_
- `vo_vape_af76c904` i'm sleeping  _(deck.ink:308)_
- `vo_vape_7d6b9ed4` we're just here to get her DAD bro. two minutes. in and out  _(door.ink:381)_
- `vo_vape_b72404eb` bro come on  _(door.ink:431)_
- `vo_vape_652dcfa6` it's in my other pants my guy  _(door.ink:432)_
- `vo_vape_502ad7e1` bro he's literally  _(door.ink:462)_
- `vo_vape_e5fa5f41` are you SERIOUS right now  _(door.ink:478)_
- `vo_vape_6be5cebf` appreciate you big dog  _(door.ink:558)_
- `vo_vape_cf160e1a` bro he's gonna do it WRONG. he doesn't even know what he looks like  _(door.ink:580)_
- `vo_vape_40408c3f` unreal. this guy  _(door.ink:606)_
- `vo_vape_36dc3e31` bro  _(hall.ink:90)_
- `vo_vape_543d2913` my guy it's not even MINE. i'm holding it for somebody  _(hall.ink:91)_
- `vo_vape_eac52180` that was SIXTY bucks  _(hall.ink:117)_
- `vo_vape_0428c2ba` bro. that was sixty bucks. you owe me sixty bucks  _(hall.ink:118)_
- `vo_vape_a887bde5` yeah yeah yeah. ok chief  _(hall.ink:124)_
- `vo_vape_34818e00` the fuck did you just CALL her  _(pool.ink:468)_

## a (`a`)

- `vo_a_fd0b0cd4` Card machine working tonight?  _(talk.yaml card_machine)_
- `vo_a_d84a4cae` Can't complain. You on at the mill?  _(talk.yaml hivis_room)_
- `vo_a_2bd95799` Upstairs here? Christ.  _(talk.yaml hivis_room)_
- `vo_a_37a98c87` Sure.  _(talk.yaml goodshoes_gary)_
- `vo_a_ee77f155` HAARP. Alaska. Look it up.  _(talk.yaml haarp)_
- `vo_a_7e5b3835` A hundred and eighty antennas in a field, all pointed up.  _(talk.yaml haarp)_
- `vo_a_dfc893e1` They seed the clouds in Alberta. That's not a theory, that's a contract.  _(talk.yaml seeding)_
- `vo_a_fc415fe1` And the rain in November '21? That just happened, did it?  _(talk.yaml seeding)_
- `vo_a_992b50ca` The Air Force gave a bar owner fake saucer pictures. A bar owner.  _(talk.yaml saucers)_
- `vo_a_483f146d` Not this one. One down by Area 51. It was in the paper.  _(talk.yaml saucers)_
- `vo_a_1c9db288` That light's out over the mainland again. Two nights now.  _(talk.yaml the_light)_
- `vo_a_6314cb09` Planes blink. It doesn't blink.  _(talk.yaml the_light)_
- `vo_a_c49f0508` They say we're overdue. The big one. Three hundred years.  _(talk.yaml overdue)_
- `vo_a_cb35512c` Well. It's more overdue now, then.  _(talk.yaml overdue)_
- `vo_a_14bb38e6` They're saying two shifts at the mill again by spring.  _(talk.yaml two_shifts)_
- `vo_a_304b9515` Now they're saying it in November.  _(talk.yaml two_shifts)_
- `vo_a_6297d09a` Ferry was late again. Forty minutes.  _(talk.yaml ferry)_
- `vo_a_5a047b59` That the new doorman?  _(talk.yaml about_him)_
- `vo_a_8731ac36` Big.  _(talk.yaml about_him)_
- `vo_a_242c325b` Did you see that? By the jukebox. Something went under.  _(talk.yaml rat_seen)_
- `vo_a_6a35b0aa` I never said rats.  _(talk.yaml rat_seen)_

## Terry (`terry`)

- `vo_terry_76a2771d` Hey, pal. You never did say what was wrong.  _(closing.ink:676)_
- `vo_terry_2fc8c531` Oh, hey, twelve. You signed. Something wrong? What's the score?  _(hall.ink:475)_
- `vo_terry_7766857b` Oh. Twelve. Something wrong? What's the score?  _(hall.ink:477)_
- `vo_terry_d60d9d2a` Oh, hey. Something wrong? What's the score?  _(hall.ink:479)_
- `vo_terry_7818d4df` Oh, they're only going to the bar, pal.  _(hall.ink:484)_
- `vo_terry_9c57439a` Sure, sure. You bet. I'll get the game on my phone, eh. It runs a minute behind, but.  _(hall.ink:485)_
- `vo_terry_ba292c9c` Oh, no no. They live here, pal. That's what the door's for.  _(hall.ink:488)_
- `vo_terry_0a14e76e` Oh. She told you that.  _(hall.ink:492)_
- `vo_terry_766e1333` Sure. Door stays shut, then. You tell her thanks from me.  _(hall.ink:494)_
- `vo_terry_73283569` Okay, pal. You know where I am.  _(hall.ink:499)_
- `vo_terry_868616de` Oh, hey. You'll be the new door, eh. What's the score?  _(walk.ink:170)_
- `vo_terry_ebf6a80f` Terry. Night desk. I come on at five and I'm on till the bread truck. Gary give you twelve? You'll want to sign for it, pal. Here. Nobody signs. I like people to sign.  _(walk.ink:172)_
- `vo_terry_097d98b5` Oh, sure, sure. You bet. That's how it's supposed to go.  _(walk.ink:176)_
- `vo_terry_492e829f` Oh, no no, he wouldn't. Gary wouldn't.  _(walk.ink:179)_

## b (`b`)

- `vo_b_63742a8c` I'm not looking anything up.  _(talk.yaml haarp)_
- `vo_b_18b64eba` Where else would you point them?  _(talk.yaml haarp)_
- `vo_b_0dacdeda` That's for the hail. That's over Calgary.  _(talk.yaml seeding)_
- `vo_b_4f3e1949` That was rain. It rains here.  _(talk.yaml seeding)_
- `vo_b_1272aa0f` Which bar?  _(talk.yaml saucers)_
- `vo_b_c43ea92d` Gary'd have them framed behind the till.  _(talk.yaml saucers)_
- `vo_b_378ee0a2` It's a plane.  _(talk.yaml the_light)_
- `vo_b_4e0ecfb3` Then it's a star. Drink your drink.  _(talk.yaml the_light)_
- `vo_b_3bf5cc77` They've been saying overdue since I was in school.  _(talk.yaml overdue)_
- `vo_b_52222c6a` They said that in March.  _(talk.yaml two_shifts)_
- `vo_b_9e373914` Forty's not late. Forty's the ferry.  _(talk.yaml ferry)_
- `vo_b_3eb788c1` Second one this month.  _(talk.yaml about_him)_
- `vo_b_1eb95ff2` The last one was big too. Lasted a Friday.  _(talk.yaml about_him)_
- `vo_b_69fdfca1` There's no rats in here.  _(talk.yaml rat_seen)_

## Hearing Aid (`hearing_aid`)

- `vo_hearing_aid_471698ce` Stander.  _(closing.ink:728)_
- `vo_hearing_aid_6df4abbe` Week.  _(rats.ink:498)_
- `vo_hearing_aid_e078a95a` Sport.  _(room.ink:274)_
- `vo_hearing_aid_83498f8f` Seeding.  _(room.ink:317)_
- `vo_hearing_aid_6050c4cd` Backside.  _(room.ink:448)_
- `vo_hearing_aid_7a3029be` Security.  _(table28.ink:30)_
- `vo_hearing_aid_26e114f0` Him.  _(table28.ink:34)_
- `vo_hearing_aid_3aaaea95` Woman.  _(table28.ink:147)_
- `vo_hearing_aid_7cb2660a` Liked him.  _(table28.ink:278)_
- `vo_hearing_aid_6e61aff2` Ninety-one.  _(talk.yaml t28_diesel)_
- `vo_hearing_aid_4e6b3c20` This one.  _(talk.yaml t28_mill)_
- `vo_hearing_aid_61f2ed59` Sweep.  _(talk.yaml t28_curling)_

## Slippers (`slippers`)

- `vo_slippers_7378f5b0` Cash? I haven't got cash.  _(bar.ink:357)_
- `vo_slippers_9772a209` I never have cash. My husband always carried the cash.  _(bar.ink:359)_
- `vo_slippers_4b7d11d5` I'm in nine, dear. I'll get it to you. I will.  _(bar.ink:364)_
- `vo_slippers_76b0ee2b` Nine, dear. I'm in nine. You'll get it, don't you worry.  _(closing.ink:663)_
- `vo_slippers_a95f78cb` A mouse.  _(rats.ink:609)_
- `vo_slippers_04185222` That was a big mouse, dear.  _(rats.ink:610)_
- `vo_slippers_6a3c1fd6` That's not a mouse, dear. I've lived upstairs eleven years.  _(rats.ink:615)_
- `vo_slippers_8ddb4bc9` Room nine has had that drip since August. Since the long weekend.  _(talk.yaml slippers_drip)_
- `vo_slippers_4dc0a9c6` I told Terry. Terry tells the drip.  _(talk.yaml slippers_drip)_
- `vo_slippers_c23b942b` My husband would have had that door shut by nine. Nine, and not a minute after.  _(talk.yaml slippers_door)_
- `vo_slippers_7be59e6c` He had standards, dear. It looked like temper from the outside.  _(talk.yaml slippers_door)_
- `vo_slippers_61a69899` Is this the same bottle as Tuesday, dear? It tastes like Tuesday.  _(talk.yaml slippers_wine)_

## The Bookkeeper (`bookkeeper`)

- `vo_bookkeeper_4c3d3578` Mm-hm.  _(office.ink:131)_
- `vo_bookkeeper_61eeb258` His father's, and then his. Forty-one years in March. Before that I was at the bank.  _(office.ink:222)_
- `vo_bookkeeper_e3364f9a` Across the road. When it was a bank.  _(office.ink:224)_
- `vo_bookkeeper_b6ad5ebe` Down the hall on the left. Jiggle it.  _(office.ink:246)_
- `vo_bookkeeper_a02c796e` Doug says a big fellow with hair closed the Legion last night.  _(office.ink:275)_
- `vo_bookkeeper_4dbb69ea` Fridays. By cheque. The first one's prorated.  _(office.ink:358)_
- `vo_bookkeeper_027b826a` Six hundred and fifty. A month. With the hydro.  _(office.ink:377)_
- `vo_bookkeeper_6369bfb9` Thank you so much.  _(office.ink:395)_
- `vo_bookkeeper_f1ed9e5f` I'll need the new one's numbers, Gary. For the file.  _(office.ink:423)_
- `vo_bookkeeper_06de4407` That's not how it works.  _(office.ink:430)_

## The Esso Kid (`essokid`)

- `vo_essokid_3d595846` That one. Over the mainland.  _(walk.ink:102)_
- `vo_essokid_8bcbe0a9` Planes blink. Satellites move. It was there last night, same place, same time. Stars don't stay in the same place, man. That's like the whole thing about stars.  _(walk.ink:104)_
- `vo_essokid_21c0afea` I filmed it. You can't see anything on the video. You never can.  _(walk.ink:108)_
- `vo_essokid_f476e82b` Kind of. Both.  _(walk.ink:114)_
- `vo_essokid_4a54f9cd` I rate them. Which one sounds more like a person. It's a site. Four cents an answer. I've done like eleven thousand.  _(walk.ink:116)_
- `vo_essokid_210fbd50` Go on. Which one?  _(walk.ink:117)_
- `vo_essokid_6e1fe20c` Huh. Yeah. That's the one I'd have picked.  _(walk.ink:120)_
- `vo_essokid_67d0605f` Yeah? Huh. Okay.  _(walk.ink:123)_
- `vo_essokid_432ea543` Yeah, that's not one of the buttons.  _(walk.ink:126)_
- `vo_essokid_5f4c86ee` They're both it, by the way. There's no person one. You're just saying which is more like.  _(walk.ink:127)_
- `vo_essokid_bfd1ee65` It's getting hard to tell.  _(walk.ink:129)_

## The Buddy (`buddy`)

- `vo_buddy_d9caf16e` He left it. He left his money.  _(hall.ink:441)_
- `vo_buddy_13d89771` No no no, it's nothing, pal. He owes me for a transmission, is all.  _(pool.ink:161)_
- `vo_buddy_ff81c540` He left it. He left the money.  _(pool.ink:369)_
- `vo_buddy_4225c23c` No no, not now, sweetheart. Your dad's working, okay? He's working.  _(pool.ink:466)_
- `vo_buddy_021e7084` Yeah yeah, no, that's mine, you left me that, that's mine.  _(talk.yaml pool_double)_
- `vo_buddy_e9121e47` Twenty bucks. Listen. Listen. Double or nothing.  _(talk.yaml pool_double)_
- `vo_buddy_7ec577e9` You're quiet tonight. Am I talking too much? I'm talking too much.  _(talk.yaml pool_quiet)_
- `vo_buddy_9598f264` Yeah yeah. No. Shooting.  _(talk.yaml pool_quiet)_

## Raincoat (`raincoat`)

- `vo_raincoat_909da1ae` Is Dennis here.  _(door.ink:1022)_
- `vo_raincoat_fa5875b7` The one pretending he can't see me.  _(door.ink:1041)_
- `vo_raincoat_8a18203f` His truck's in your lot. Same spot as always.  _(door.ink:1048)_
- `vo_raincoat_37d90e80` Tell him the dog's been sick on the bed. He'll know what that means.  _(door.ink:1049)_
- `vo_raincoat_46f9d37c` Don't.  _(table28.ink:468)_
- `vo_raincoat_8d806fbb` Thirty years he's sat at that table. You'd think one of you would stop him at the door.  _(table28.ink:476)_

## The Constable (`constable`)

- `vo_constable_5116897d` Okay. So. We had a call about a fight.  _(pool.ink:694)_
- `vo_constable_07d99edb` Forty minutes. I know. I've got one car for the whole valley.  _(pool.ink:696)_
- `vo_constable_dbe64678` Got it. And the eye, sir?  _(pool.ink:715)_
- `vo_constable_1cb10f29` Alright. First time I've had one in order from a doorman.  _(pool.ink:718)_
- `vo_constable_7f663330` Sorted itself out.  _(pool.ink:726)_

## A Smoker (`smoker`)

- `vo_smoker_6d4a0c85` Graham Ardagh's back. I saw his car at the Esso.  _(deck.ink:80)_
- `vo_smoker_b054b2d0` She'd have him shot. She'd do it herself, with the soda gun.  _(deck.ink:81)_
- `vo_smoker_3cca51fe` That pickup's been sitting there since eight with the engine going. Somebody's waiting on somebody.  _(deck.ink:88)_
- `vo_smoker_a69d6620` They're saying the mill's done at Christmas. My brother-in-law says Christmas.  _(deck.ink:94)_
- `vo_smoker_7bcd619f` They've been saying Christmas for six years.  _(deck.ink:95)_

## Glasses (`glasses`)

- `vo_glasses_fd4c4ec8` She'll have her keys out. Thirty years, she's had her keys out.  _(door.ink:1063)_
- `vo_glasses_9ea4bb73` He's all right. He's a good, he's.  _(talk.yaml t28_new_kid_good)_
- `vo_glasses_481ff6c7` My wife says to me, she says, Dennis. She says, you're.  _(talk.yaml t28_dennis)_
- `vo_glasses_7745de05` Thirty years. Thirty years, and she still.  _(talk.yaml t28_dennis)_

Changing with the night (record the bark instead, or ask for these to be split):

- At {q_words(wife_at)}.  _(closing.ink:738)_

## Hi-Vis (`hivis`)

- `vo_hivis_39d27d11` How's she goin'.  _(talk.yaml hivis_room)_
- `vo_hivis_638fd762` Contract. Six weeks. I'm in room eleven, so.  _(talk.yaml hivis_room)_
- `vo_hivis_35878b38` Fair enough.  _(talk.yaml hivis_room)_

## slippers_b (`slippers_b`)

- `vo_slippers_b_31f55c44` You should tell Terry.  _(talk.yaml slippers_drip)_
- `vo_slippers_b_e7d8ed30` Your husband had a temper.  _(talk.yaml slippers_door)_

## Good Shoes (`goodshoes`)

- `vo_goodshoes_086e016f` Gary and I go back. I completely understand the caution, of course.  _(talk.yaml goodshoes_gary)_
- `vo_goodshoes_f7f214bc` He's a reasonable man, Gary. I'm a reasonable man.  _(talk.yaml goodshoes_gary)_
