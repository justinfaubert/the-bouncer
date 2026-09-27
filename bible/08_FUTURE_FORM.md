# The future form

*Written 27 September 2026, after Hutch asked for something better than the HTML build and more than a Claude artifact: a more immersive world, perhaps in Godot. Everything here is [PROPOSED] until Hutch says otherwise. The same, with the evidence marked up, as a page: https://claude.ai/artifact/YL6FR7cPoxNWihnWchgztT*

## The short answer

Godot, yes. But HTML isn't why the plates and faces look amateur. I drew them in code, and code draws like a machine. The same drawings in Godot would be sharper, not better.

Greatness here comes from four things, and the engine is only one of them:

1. **One room made with total conviction.** A single hotel over thirty nights is a size a small team can finish to the edge.
2. **The reality only Hutch has:** how the door goes, what the room sounds like, what it looks like before open.
3. **One artist's hand** behind the faces and the look.
4. **Godot, to put that room around the player:** light that follows the clock, rain on the door glass, his drink slipping the inks, the voices marking the room itself, his heart in the player's hands.

The first thing to build is one scene at final quality, not a port of the whole night: the door at 7:50, the kid with his phone.

## Why the pictures read as amateur

What works and what doesn't, in the build as it stands (version 5):

- **The ID works.** The licence photographed on a kitchen table, the mug ring, the phone at 6%. It's graphic design: type, layout, a screen. Code is good at design.
- **The plates don't.** Every bottle on the back bar is the same bottle. The hi-vis man is a flat cut-out with no weight. The perspective is perfect and nothing in it is worn. One halftone screen lies evenly over everything, so it reads as a filter over clip art rather than a print.
- **The faces don't.** One skull under every face; the eyes, nose and mouth are the same parts moved around, and only hair, beards and clothes change. They sit in an uncanny middle: too realistic in intent for code to carry, not stylised enough to be a style.

Faces and rooms are drawing, and drawing needs a hand: someone deciding what to leave out. That's true in any engine. Hutch called the style a plus and the execution amateur, and that's the right read. Keep the style; change who makes the pictures.

## Why Godot anyway

Real art would lift the browser build too. What the browser can't give cheaply is the room around the player, and a game Hutch owns outright.

- **The room is a space, not a page.** Real light from the sign, the bar, the TVs and the headlights through the door; smoke; rain on the glass; people moving in the room behind him, at the screen's full resolution.
- **The print gets better.** The print renderer becomes a shader over the live room: the inks separated and screened at print resolution, a different screen for wood, skin and dark, the paper under everything, the plates slipping out of register with drink. A shader does every frame what the browser build does once per picture.
- **Sound in the room.** The jukebox and the room noise come from where they are. The tiled washroom rings, the keg room is stone, the deck is rain on an awning. Where he looks is what he hears: look at table 28 and their talk comes up out of the room.
- **Things in his hands, in 3D.** The licence tilts under the vestibule's real light and the hologram catches it. The dice are real dice, thrown on the cigarette-burned ledge, and the second one can hang on the edge.
- **His body.** A controller's rumble carries his heart while the dice are in his hand.
- **A game Hutch owns.** A normal Godot project in a git repo that's theirs, built for Linux, Windows and the Steam Deck, headed for Steam. Claude is a collaborator in the repo, not the host.
- **An editor Hutch can work in.** Open the scenes, move the lights, put the glasses on table 28 by hand.
- **It suits working with Claude.** Godot's scenes and scripts are plain text, so Claude writes and reviews them directly. Godot 4.7.2 runs and renders in Claude's cloud workspace (checked 2026-09-27), so the bots and tests keep running there.

**What carries over as it is:** the Ink (all of Wednesday), the YAML rules and data, the writing prompts, and the design of every system in `07_ENGAGEMENT.md`.

**What gets rewritten:** the code that runs them. The browser build is about 11,600 lines of JavaScript; about 3,500 of them draw the stand-in pictures and don't come over at all. The rest is rewritten in GDScript against the same content.

**What the move costs:** the Godot build plays on Hutch's machine, not in the Claude app. The browser build stays as the writers' room for reading, answering prompts and directing, until the Godot build has its own director mode.

## The form: through his eyes, from his posts

This decides the camera, the art list and the first scene.

**Through his eyes. [DECIDED 2026-09-27, Hutch's pick]** The player sees what he sees, from where he stands. He works from posts: the stool at the door, the end of the bar by the till, table 28, the wall by the pool table, the back hall, the kitchen, the deck, the keg room, the lot. At a post the player looks around; going to another post is a short walk through the room, and the clock moves. The text column stays: the teller's narration, the voices, the choices.

- **The job is watching.** What the player looks at, and for how long, is the game. The pointer is his attention: on the room it's where he looks, on a choice it's his hand, and the voices notice both, the way they notice a hand resting on a choice now (the photo held against the face, the look that keeps going back to the sister).
- **The door is face to face.** The kid stands in the doorway, close, lit by the vestibule light, and hands over his phone. The encounters that define the job happen at arm's length.
- **The voices mark up the world.** The ring around the big man's left hand is drawn in the room itself, in the voice's ink.
- **He's seen only in reflections:** the door glass at night, the mirror behind the bottles, the washroom mirror. His face changes over the night with the drink and the hurt. The back-bar mirror is also a tool of the trade: from the bar, the room behind him is in it.
- **It puts the player in his skin,** which is what round three asked for.
- **It needs the least art per view.** Each post is one composed view, finished like a painting, instead of a whole room that has to hold up from every angle.
- Drink goes into the print (the inks slipping and doubling), not the camera, so it doesn't make anyone sick.

**From above.** Disco's view: the player walks him around a painted room. It shows his size in the doorway, which matters for a bouncer. It invites the direct comparison with Disco, which had a team of painters, and it needs every character animated head to toe.

**Free walk.** First person, walking anywhere in the hotel. The most immersive, and the most art to make: every corner has to hold up at every distance.

## The look: the print, made real

Keep the print. It's the game's identity, and it belongs to a world of pamphlets, IDs and till tape. Make it real by putting real sources under it.

- **The room is built from the real kind of room.** Measurements and photographs of an empty bar Hutch knows, before open and with no one in it: the door from the stool, the bar and the mirror, a window table, the carpet, the hall to the washrooms. Claude builds the room in 3D from them; the textures come from the photographs.
- **The faces are painted by one artist,** a few expressions each, and printed through the same press so they sit in the same world. Close up (at the door, across the table) a person is the artist's painting, set into the scene. At a distance the crowd is simple figures that the print turns into shapes and dots.
- **Everything designed is Claude's:** the IDs, the phone, the till tape, the binder, the clicker, the incident log, the posters, the menus, the type.
- **The print does what a picture can't:** the hour's light, the rain, drink, hurt, the heartbeat, the voices' marks.
- **AI-generated images stay out of the game** (private mood boards at most, as `04_PRODUCTION.md` already says). They'd make it look finished fast and generic for good, the opposite of singular, and Steam asks for them to be disclosed.

Three routes to the faces:

1. **An artist Hutch commissions** (recommended): a painter or printmaker whose work Hutch loves, ideally someone local who can sit in the kind of room we're making. Wednesday has ten people with portraits. Prices vary a lot by artist; expect low thousands of dollars for ten, not hundreds, and get quotes.
2. **Hutch's own hand,** if Hutch draws, paints or carves.
3. **Photographed sitters,** printed like the photos on licences. It fits a job made of ID photos, but the sitters are real people who have to agree to it, and a photograph can't exaggerate the way a painting can.

## Sound

Hutch's, recorded, as already proposed: the jukebox songs Hutch plays; the empty bar recorded in layers (coolers, ice machine, a quiet room, a busy room, the pool table, the jukebox through the wall, rain); Hutch's voice for the teller if the narrator frame stays. Godot places each sound in the room and mixes by where he stands and what he's looking at.

## Who does what

| Who | Does |
|---|---|
| Hutch | Director and writer with final cut. The music, the recordings, the teller's voice. The reality: photographs, measurements, how the door really goes. |
| Claude | The Godot game: engine, systems, the print renderer and shaders, the room's build and light, every designed object, the tools (director mode, bots), and drafts for Hutch to cut. |
| One artist | The faces, and the look of the people in the room. |

## The path

1. **Pick the form and the route to the faces.** The conversation of 27 September.
2. **Give the game a home Hutch owns.** A private GitHub repo with everything in it (bible, Ink, tools, the browser build, the Godot project), attached to the project. Hutch's Arch machine connected with Remote Control (`claude remote-control` in the game's folder), so Claude works in Godot there, on the 3080, while Hutch watches it in the editor. Claude's cloud workspace can't reach github.com or godotengine.org (Godot 4.7.2 came from the SourceForge mirror); adding those hosts to the allowed domains in the project's environment settings lets the cloud threads build too. If Hutch built the Godot bridge they designed in April 2026, use it.
3. **One scene at final quality: the door, 7:50 pm.** The vestibule from his stool, the lot through the glass in the rain, the room behind him, the kid with his phone and then his licence, a check thrown on the ledge, the voices, Hutch's recordings. A stand-in face, marked as one, until the artist's arrives. It proves the form, the look, the sound, the head in the world and the hands. It becomes the artist's brief, the first thing on a store page, and the yardstick for everything after.
4. **Then Wednesday, post by post,** in that form: the checks, the psyche, the word on him, the voices, the sketch, director mode and the bots, rewritten in GDScript against the same Ink. The Ink runs through inkgd (pure GDScript, with no official Godot 4 release yet, so it has to pass a smoke test on Wednesday first), with the C# runtime as the fallback.
5. **Then Thursday and Friday,** written in Ink as before and played in Godot.

This swaps M3 and M4 in `04_PRODUCTION.md`: the look first, on one scene, then the port. Porting the whole night with placeholder art first would give a Godot build that looks as amateur as the browser one, and the look would get decided by default.

Nothing widens until the door scene is as good as it can be made.

## Open, for Hutch

1. Does Hutch draw, paint or carve?
2. Is there money for an artist, and is there anyone whose work Hutch would want?
3. ~~Through his eyes, from above, or free walk?~~ Through his eyes (Hutch, 2026-09-27).
4. When Hutch can: a dozen photographs of an empty bar Hutch knows, before open.
