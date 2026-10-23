# M4 the town: working design (Claude's notes, not canon)

## Engine (prototype/web/src/core/folk.js = B.Folk; godot/engine/folk.gd = Folk)
- Folk.make(seed, content) -> town. RNG new Rng(hash32(seed+':town')). Deterministic twin rules.
- Folk.night(town, day) -> arrivals [{at, wave, who:[ids], why}] sorted by at then first id.
  RNG hash32(seed+':night:'+day). Wed trickle (~6-12, only while he's at the door; missed ones dropped,
  sim.ink walk_ins covers the uncounted). Fri: waves dinner 1180-1245, arena ~1310, swing ~1395,
  legion ~1450, ferry ~1475, trickle; 2-4 minors (tries) 1320-1470.
- class Door (in folk.js): line (queue of person ids w/ joined-at), front, records {id: {at, did, how, ...}},
  waves announced, kept cards, per-event rng hash32(seed+':door:'+day+':'+key). serialize()/load().
- Game: this.folk (made at newGame/load from seed), this.door (per night). Externals (unsafe unless noted):
  door_open(day), door_tick() -> waiting count, door_next() -> group size, door_text(key) (safe-ish? no: marks lines used),
  door_ask(q), door_glance(), door_admit(), door_refuse(why), door_keep(), door_wave(), door_count(what) (safe) ...
- AT_DOOR: speaker label resolved by engine -> item.person, item.label (door tag: FLANNEL, BALL CAP...), item.look.
- Props: id "door:<presenter>:<variant>" built on demand by game.prop(id) (no save needed).
  variants: own, sib:<pid>, lifted, printed, phone, oop. toy events: toy:door_<variant>:<what> then toy:card:<what>.

## Fakes and tells
- sibling: older same-sex sibling's real card. Tells: photo/eyes/height (look), recognition if sibling met or inside
  tonight (scanner SEEN time), sign/year hesitation.
- lifted: own card, year lifted 2-4. Tells: tilt ridge at date; scanner reads real date (barcode).
- printed: own name, year shifted, holo printed (static on tilt); scanner green or red (cheap).
- phone: photo on a phone: always refused if read; glance catches.
- none: no ID ("in the truck").
- adults: expired (4%), old address (8%), ID card (no class), oop Alberta (alberta_plate detail), no ID tonight (2%).

## Choices at the front (line.ink)
- Nod through (no card). Card, quick (glance: hidden notice roll). Wave the rest through (batch glance).
- Slow read: take card (#prop) -> questions (middle, birthday, sign, postal, year), size up (#check gut {mod}),
  scan (time; scanner verdicts), say something (rapport), In / Not tonight / Keep the card.
- Each action pass(1..2). Line patience: wait > patience -> leave (owner money) or slip in (uncounted).

## Friday (friday.ink)
- After Wednesday's ledger: teller bridge (Thursday not told yet), Friday 7:20 arrival, Paige, door-only loop
  to LAST_CALL 1530, wave beats, minors discovered later (Paige), sibling owner comes for the card, close: door's tape.
