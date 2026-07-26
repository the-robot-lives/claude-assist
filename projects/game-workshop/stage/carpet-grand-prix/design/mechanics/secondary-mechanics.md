# Carpet Grand Prix — Secondary Mechanics

Every mechanic below exists to give the primary tilt system (`primary-mechanic.md`)
something to push against. None of them introduce a second input — they all modify how
gravity, grip, or the car's own mass respond to the same tilt signal.

## Tyre grip

Lateral velocity bleeds off at **5.0 units/s**, which is what makes the car carve a line
instead of instantly translating sideways under roll input. Push past roughly **70% of
lateral load** and the tyres lose the fight with grip and the car begins to drift.

- Drifting is **faster through wide corners** — the car carries more of its straight-line
  speed through the turn than a fully gripped line would allow.
- Drifting is **fatal through tight corners** — the wider drift radius carries the car
  straight into a rail or an open edge on anything under Hallway-width lanes.
- Grip is the stat that separates the eight handling classes of car most sharply (see the
  cast table in the world design docs): Chrome has the sharpest grip in the game and is
  correspondingly the worst car on grade, while The Loaf has almost none.

## Boost strips

Boost strips apply **+620 u/s² along the track tangent** for the duration of contact.
They are rendered as cyan chevrons and are **always placed off the natural racing
line** — taking one is a deliberate detour that costs entry speed into whatever follows
it, never a freebie sitting on the fast line. A player who takes every boost strip on a
course without thinking about the line that leads out of it will consistently lose time
to a player who skips half of them.

## Sticky patches

Spilled juice, dust bunnies — grip drops to **1.4/s** (from the baseline 5.0/s) and drag
increases by **+2.6**. This is the one place in the game where the core feel inverts: the
car stops carving and starts sliding, an intentional "ice physics" moment dropped into an
otherwise high-grip game. Sticky patches first appear in the Kitchen (Room 2) and
escalate to "oil slicks," an extreme version of the same penalty, in the Garage (Room 5).

## Ramps and airtime

A ramp launches the car for **0.72 seconds of airtime**. Gravity continues to apply
during the jump (the arc is real, not scripted), but **grip does not** — steering input
during airtime has no lateral effect. Landing determines the outcome:

| Landing | Result |
|---|---|
| Clean (wheels-down, aligned with the deck) | All speed preserved |
| Sideways | Speed scrubbed on impact, same as a rail clip |

Ramps and the airtime they produce are the Attic's (Room 4) headline new hazard verb and
are the reason that room's average grade (22%) is the steepest of the first four rooms.

## Open edges

The **only true hazard** in the game. A flagged section of track has no rail on one side,
and missing the line there costs **+2.0 seconds and a checkpoint respawn** — identical in
cost to any other fall, but with no rail to bounce off first as a warning. Open edges are
withheld until the Basement (Room 6), specifically so the player has already internalised
every other failure mode before meeting the one hazard with no forgiving intermediate
state.

## Rail bounce

Contact with a rail returns **34% restitution** and scrubs **20% of current speed**.
Rails are deliberately cheap to *touch* — brushing one while carving a wide line barely
registers — and expensive to *lean* on, since repeated contact compounds the 20% scrub
every time. This asymmetry (cheap once, expensive repeated) is what makes "hold it
steady" the first mastery layer in `core-loop.md`: new players lean on rails through
entire straights and bleed speed continuously without realising it.

## Car mass

Mass scales **gravity response and grip independently**, not as a single "weight" stat:

- **Heavy** cars (The Loaf) get more gravity authority — they accelerate harder on grade
  — at the cost of grip, making them dominant on steep, straight-heavy courses and
  dangerous through anything technical.
- **Light** cars (Bit) are twitchy and corner hard, trading raw straight-line pull for
  cornering precision and, in Bit's case, a half-size hitbox that fits lines nothing else
  in the roster can take.

This independence is what makes car choice a real per-course decision rather than a
strictly-better-stats progression ladder — see the cast table in the world design docs
for how each of the eight handling classes expresses this trade-off.

## Checkpoints

Checkpoints are placed roughly every **28 position samples (~900 units)** along a course.
They exist purely as **respawn granularity** — a fall never rewinds the run clock, it
only returns the car to the most recent checkpoint and adds the flat time penalty for
that failure type. Checkpoint spacing is tuned per course so that no single fall can cost
more than a few seconds of re-acceleration on top of its penalty, keeping every mistake
inside the "time cost, never crash-out" failure philosophy described in `core-loop.md`.
