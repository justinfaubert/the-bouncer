// Toys: things the player can pick up and play with between choices. The clicker in his fist,
// a card held out at the door, the binder under the till. (content/ink/README.md, "Toys".)
//
// Handling a thing does one of two things.
//
// If a choice on offer carries a #toy: tag for it, handling it that way makes that choice, the
// same as clicking the words: [Take the phone and look at the photo. #toy: hoodie_phone look].
// Add #unlisted and the choice isn't in the list at all; the only way to make it is with your
// hands (swiping the kid's phone to the next photo). That's how a thing sets the story going.
//
// If no choice is waiting for it, the engine calls the thing's function below, toy_<thing>(what),
// which changes what it changes and prints what happens, if anything. The clock doesn't move.
//
// Either way the voices can answer: toy:<thing>:<what> in content/rules/barks.yaml.
// Claude's drafts, all of it.


// ------------------------------------------------------------------ the clicker

// What the clicker in his fist says: everyone he clicked in, and every click that wasn't anybody,
// since the knob was last turned back.
=== function clicker()
~ return count_in + fidget - zeroed

// what: "click", the button on top, or "zero", the knob on the side turned all the way round.
// Every idle click is somebody who never came in, as far as the count at close is concerned.
=== function toy_clicker(what)
{ what == "click":
    ~ fidget++
    { fidget == 1:
        He clicked it. Nobody had come in.
    }
    { fidget == 12 && in_the_room():
        BARTENDER: Are you going to do that all night?
    }
}
{ what == "zero":
    ~ zeroed = count_in + fidget
    He turned the knob on the side, and the numbers rolled back to nothing.
}

// the bar, the door, and the floor between them: one room, where the bartender can hear it
=== function in_the_room()
~ return here == door || here == floor || here == bar || here == t28 || here == pool
