// Toys: things the player can pick up and play with between choices. A card held out at the door,
// the kid's phone, the binder under the till. (content/ink/README.md, "Toys".)
//
// Handling a thing does one of two things.
//
// If a choice on offer carries a #toy: tag for it, handling it that way makes that choice, the
// same as clicking the words: [Take the phone and look at the photo. #toy: hoodie_phone look].
// Add #unlisted and the choice isn't in the list at all; the only way to make it is with your
// hands (swiping the kid's phone to the next photo). That's how a thing sets the story going.
//
// If no choice is waiting for it, the engine calls the thing's function, toy_<thing>(what), if
// one is written here, which changes what it changes and prints what happens, if anything. The
// clock doesn't move. (None are written yet: on Wednesday every thing he's handed either moves the
// night on, or a voice answers it.)
//
// Either way the voices can answer: toy:<thing>:<what> in content/rules/barks.yaml.
// Claude's drafts, all of it.
