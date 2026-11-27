# Pool (PROPOSED, 22 to 23 November 2026)

What Hutch asked for: a deep pool system with 8-ball and 9-ball, physics, cue handling, scoring and its own UI. It needs a place in the story, and it has to be something repeatable that rewards the player: tournaments, exhibitions, money. It follows the darts rule: let the player be precise, with just the right amount of pushback, and no timing bar.

## What's built

**The physics** (`godot/game/pool_sim.gd`) are event-based and exact. They aren't the engine's and they aren't steps: each ball moves on a curve that can be written down (sliding, rolling, spinning on the spot, in the air), and the sim jumps from one meeting to the next. The cushion is Han's model, struck above the ball's middle, so running and reverse english and the shortened angle off a hard hit all come out of it. Ball-on-ball friction gives throw. Squirt comes from the cue's end mass. Swerve, massé and jump come from the butt being raised. The pockets have faced jaws that rattle. A break works out in about 70 ms, and the same shot comes out the same every time. `godot/tests/pool_sim.gd` checks all of this against real numbers: stun, draw, follow, the 30° rule, throw, cushion english, squirt, massé, jump, and the jaws.

**The Sov's table** (`godot/game/pool_table.gd`) is built to the sim's own measures. It has a lean of about 0.05° that shows on slow rolls, worn slow cloth, dead rails, and two burns that drag a ball and turn it a hair. The coin-op's cue ball is the big bar ball, which follows well and draws badly. Pocketed balls come down to the window at the foot of the table.

**The stroke** (`godot/game/pool.gd`):
- The mouse aims, with Shift for fine work. Up and down moves his head.
- Right drag puts the tip on the ball. The ring on the tip card shows where it slips off on this cue with this chalk.
- The wheel lifts the butt. The butt rides up on its own over the rail or a ball in the way.
- Hold and pull back to draw. The draw length is the power. Sideways drift in the pull steers the shot off line.
- C chalks. The tip goes dry over four or five shots.
- Q and E change cues. There are four house cues (sound, warped, mushroomed tip, heavy) and any he's bought.
- The pushback is his tremor (drink, hour, hurt, nerves, cold, money on it) and the cues.

**The rules** (`godot/game/pool_rules.gd`) cover the Sov's chalked eight-ball (call the eight, scratch goes in hand behind the line, the eight on the break wins, slop counts, no jumping on the house cues), league eight-ball, nine-ball (with the push-out and three fouls), practice, and trick shots.

**The man across the table** (`godot/game/pool_ai.gd`) thinks on the same physics. He works through every ball and pocket that's on, three paces and three tips each, and corrects his aim for throw by trying it. Then he weighs how sure he is against where the cue ball ends up, or plays safe. His hands have their own spread. There are ten people. The big man throws the ones that matter.

**Its own UI** (`godot/game/pool_ui.gd`):
- the scoreboard, with each player's balls as they stand on the table
- the tip card: the cue ball's face, the slip ring, the butt's lift, the draw, the chalk
- what happened, in his words and the teller's
- the end card

## Round two (23 November, after Hutch played it)

- **The balls wear their numbers in the game you play.** The export was dropping the ball pictures (they were imported as textures, and the table reads the raw files), so every ball came out blank. They're kept as they are now, like every other picture, and a test checks each ball has its picture.
- **An eight-foot bar box** (88 by 44 inches) instead of the seven: still a coin-op, a size bars do have, and it fills the room better. The walk map is redone round it.
- **Nothing goes through the table.** Both cues, his and the other man's, go by one rule in the sim (`PoolSim.min_elev`): the cue's own thickness kept over the cushion, the wooden rail and any ball behind, and a hand's thickness more when he bridges on the rail. The other man's stroke is a real one now: practice strokes, a pause at the back, through the ball and a short follow-through that stops short of the cloth. His head stays out of the rail when he gets down low near it. The render test checks both cues against the table and the balls on every frame of his stroke.
- **Smoother aim.** The cue follows the hand a moment behind, like a cue settling on the bridge, so the line doesn't twitch. Down on the shot the hand turns it less than stood up. Held A and D give the last hair. The head only rises and falls when the hand moves mostly up and down, so turning the cue doesn't bob it.
- **The table's own sounds** (`tools/pool_sounds.py`): the click of two balls, the tip, the break, the cushion, the jaws, the drop into the gully, the run down the return, a ball on the floor. Kept low and round, heard from a stool.

## Its place in the story

"Put twenty on the next game" with the big man on Wednesday is now a real rack (`#game: pool bigman win|lose` in `content/ink/pool.ink`). Playing to win against a man who's throwing games means he hands you the eight, and the Ink says so. Playing to lose has to be done well enough. A ball that touches nothing, or the eight in early, and he sees it: "Don't do me any favours, bud." Honest misses and he likes you for it. What came of it is in `pool_result`, `pool_threw` and `pool_dumped` for later scenes.

## The loop (Games > Pool, kept in the settings)

- **His purse.** He starts with $40, the forty he came with.
- **The chalk ladder.** Scratch ($5), Hi-vis ($10), the buddy ($20), the cook (nine-ball, $20), Jim (league, after close, $10), the big man playing straight ($50), and the man from Nanaimo. Nanaimo loses the first one for ten, badly, then wants a hundred and plays it for real.
- **Good Shoes.** Keep it close and he doubles the stakes. Beat him by five or more and he's gone for the week.
- **The Sunday draw.** $10 in, three rounds of league rules, $50 to the winner and $20 to the runner-up, and a line on the trophy shelf.
- **Trick shots table 28 bets on.** Down the rail, two in the side, round the eight (massé), over the top (jump). Three tries each.
- **The pawn window.** Every item is a real difference in the physics:
  - a straight two-piece cue
  - a low-deflection shaft (half the squirt)
  - a break cue (hits like a hammer, holds no spin)
  - a bridge glove (less drift)
  - his own chalk (lasts twice as long)

## Next

- The opponent's body at the table. For now he's a cue on the line, with the figure standing by.
- Nights that bring pool in: the Sunday draw as a day, Nanaimo turning up, money from the table into the night's cash.
- The bar reacting to a good shot.
- Pool sounds of its own. It borrows the room's for now.
- The house rules chalked on the board in the room.
