// 7:40 pm. The lot, the building, the bartender, the note, the voices. Ten minutes before the first read at the door.

=== prologue ===
~ here = lot
# amb: rain_lot
// HUTCH: These opening lines are the first thing anyone reads. Rewrite them in the voice of whoever turns out to be telling this story, years later, at a bar.
NARRATOR: He started on a Wednesday. The Sov tried out doormen on Wednesdays, on a night slow enough that a mistake would only hurt a little.
NARRATOR: Of the thirty days, it was the one nobody else remembered.
The rain had come across the strait with the last ferry and hadn't let up. It hit the gravel lot hard enough to bounce.
On the roof the sign said SOVEREIGN in red neon with the second E dead. Under it, HOTEL, all four letters working.
Three storeys of old wood, painted a red that had faded to the colour of brick. The cold beer and wine store at one end with its lights on. Trucks parked nose-in along the front, wipers stopped where they'd been switched off. The highway behind him, and past the highway, the water.
FATHER: Look at a building before you go into it. It'll tell you what kind of night it has.
It told him Wednesday. #pause
-> inside

= inside
~ here = floor
# amb: room_quiet
# music: jukebox_early
He went in.
Beer, cleaner, piss, old wood and dust. The carpet had had a pattern once. By the bar rail it gave a little under his boots, where thirty years of spills had soaked through to the underlay.
A woman behind the bar was cutting limes. She looked at him, looked at the size of him, and went back to the limes. #portrait: bartender
// HUTCH: The lifer's first words to a new doorman. What does she actually say, and what does she not bother saying?
BARTENDER: You're the new one.
BARTENDER: Clicker. #sfx: clicker
She put it on the bar: a chrome tally counter with the numbers worn off the button.
BARTENDER: Count them in, count them out. If the numbers don't match at close, you find out why before you go home.
BARTENDER: Owner left you a note.
It was taped to the till in black marker. RATS. DEAL WITH IT. INSPECTOR ON THE 14TH. # task: rats :: Deal with the rats before the inspector comes on the 14th.
~ knows += the_note
# task: count :: Count them in, count them out.
He turned around and looked at the room.
Five men at a round table in the front window, with the best view of the door and the TV. They were talking about the price of diesel, all at once, in one voice. The table had a number screwed to its edge: 28.
At the pool table, a big man and a smaller one were playing for money, the bills tucked under the rail.
Two women in slippers at the near end of the bar with a bottle of white wine between them. An old man at the far end, by the trapdoor, with a glass he wasn't drinking.
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
BARTENDER: Front door's yours. That's the one that counts.
BARTENDER: Hotel door's at the end of the back hall. Residents come down that way. The night clerk props it so he can hear the TV.
BARTENDER: Deck door for the smokers. Kitchen door, the cook opens it because the fryer runs about a hundred degrees.
BARTENDER: They're all locked at night.
She cut another lime in half.
BARTENDER: Mostly.
FATHER: Four doors, and one of them's yours. That's three you're answerable for and can't see.
~ knows += coaster
~ knows += kitchen_gap
~ knows += hotel_gap
- (where_more)
* (asked_last) ["What happened to the last doorman?"]
    ~ pass(2)
    BARTENDER: Walked out in the middle of a Friday. Left his jacket.
    BARTENDER: Ask table 28 why. They'll give you three different stories and all of them will have happened.
    ~ knows += old_doorman
    -> where_more
* (asked_anyone) ["Anyone I should know about?"]
    ~ pass(2)
    She tapped the underside of the bar with the knife.
    BARTENDER: Binder under the till. The eighty-sixes. Photos, most of them. Read it before somebody in it reads you.
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
