# Carpet Grand Prix — Core Loop

The primary gameplay loop for a single run: **45–120 seconds** of play, repeated **3–5
times** per sitting for a **4–7 minute** session. The loop is deliberately short enough
to fit inside a single subway stop and shallow enough that the fourth run of the day
starts with zero ramp-up.

```
                 ┌──────────────────────────────┐
                 │  PICK A COURSE  (5s)         │
                 │  see your ghost + medal tier │
                 └──────────────┬───────────────┘
                                ▼
                 ┌──────────────────────────────┐
                 │  CALIBRATE  (2s)             │
                 │  hold phone at rest pose,    │
                 │  3-2-1 countdown             │
                 └──────────────┬───────────────┘
                                ▼
        ┌───────────────────────────────────────────────┐
        │            THE RUN  (40–110s)                 │
        │                                               │
        │   tip away ──► gravity accelerates the car    │
        │        │                                      │
        │        ▼                                      │
        │   read the grade ahead (parallax height)      │
        │        │                                      │
        │        ▼                                      │
        │   tilt sideways ──► pick your line             │
        │        │                                      │
        │        ├──► hit boost strip     (+speed)      │
        │        ├──► clip rail           (−speed)      │
        │        ├──► miss the gap        (+2.0s)       │
        │        └──► launch off ramp     (airtime)     │
        │        │                                      │
        │        ▼                                      │
        │   ease back before the corner ──► carve it    │
        └───────────────────────┬───────────────────────┘
                                ▼
                 ┌──────────────────────────────┐
                 │  FINISH  (6s)                 │
                 │  time, delta vs ghost,        │
                 │  medal, one unlock beat       │
                 └──────────────┬───────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
              "Run It Again"          "Next Course"
```

## Per-step breakdown

| # | Step | Duration | Player action | System response | Skill expression |
|---|---|---|---|---|---|
| 1 | Pick | ~5s | Tap a course card | Card shows best time, medal tier, ghost availability, and which car is equipped | Course/car matchup reading (heavy car for a straight-heavy course, light car for a technical one) |
| 2 | Calibrate | ~2s | Hold the phone in whatever position is comfortable, tap once | A bubble-level indicator centres; that pose becomes the run's "neutral." 3-2-1 countdown to launch | None yet — this step exists precisely so skill starts at zero regardless of posture |
| 3 | Launch | continuous | Tip the top of the phone away from the body | Gravity accelerates the car; engine pitch rises with speed | Committing to a tilt angle before you can see what's ahead |
| 4 | Read | continuous | Look at how high the track floats off the carpet | Steeper grade renders the deck visibly higher in the parallax stack ahead of the car | Reading elevation as a proxy for upcoming speed change, 1–2 seconds before it matters |
| 5 | Line | continuous | Roll the handset left/right | Car slides across the lane against tyre grip; tyres scrub audibly near the grip limit | Choosing the fast (wide, drifting) line versus the safe (centred) line per corner |
| 6 | Commit | continuous | Hold full tilt down a straight | Speed streaks render, camera pulls back slightly, rails blur at the screen edge | Knowing which straights tolerate full commitment and which end in a hairpin |
| 7 | Bail | continuous | Ease the phone back toward flat before a hairpin | Car sheds speed and grip returns | Timing the ease-off early enough that grip has returned *before* the apex, not at it |
| 8 | Recover | as needed | After a fall, re-find neutral tilt | Car respawns at the last checkpoint, +2.0s penalty, brief screen flash | Not panicking — a fall is a time cost, not a run-ending event |
| 9 | Bank | ~6s | Cross the finish gate | Time, delta vs. ghost, medal tier, and a confetti burst of plastic sprues render | None — this is the payoff beat, deliberately effort-free |

## Session length

| Unit | Length | Design intent |
|---|---|---|
| Single run | 45–120s | Fits inside one commute interval (a subway stop, a red light, a kettle boiling) |
| Sitting | 4–7 minutes, 3–5 runs | Matches the arm-fatigue ceiling on sustained tilt input (see `mechanics/primary-mechanic.md`) |
| Course length band | 40–110s of active driving | Everything outside this band is treated as a tuning bug, not a design choice |

The 45–120 second band is a hard constraint, not a target — level design (`mechanics/difficulty-progression.md`)
is tuned against it per room, and a course that runs long is cut for length before it is
cut for anything else.

## Failure philosophy: time cost, never crash-out

**There is no crash-out and no lives system in Carpet Grand Prix.** Every mistake costs
time, never the run itself:

| Mistake | Cost | Why a cost and not a stop |
|---|---|---|
| Clip a rail | 20% speed scrub (see `mechanics/secondary-mechanics.md` — Rail bounce) | Cheap enough to shrug off once, expensive enough to avoid on purpose |
| Miss a gap / go off an open edge | +2.0s, respawn at last checkpoint | The only true hazard in the game, and it still finishes the run |
| Sideways ramp landing | Speed scrub on landing, no penalty beyond that | Punishes sloppy airtime without ending the attempt |
| Sticky patch contact | Grip and drag penalty for the duration of contact only | A local, recoverable slowdown, not a run-ending trap |

The course **always finishes**. A player who holds the phone dead flat the entire run
still crosses the line — slowly, with no medal, but with a completed run and a number to
beat next time. This is the mechanical expression of the game's premise: it is a toy, not
an obstacle course with a game-over screen. Punishment is replaced entirely by the
medal-tier ladder (`meta-loop.md`) — bronze absorbs anyone, gold and Sprue absorb ambition.

## The three mastery layers

Skill in Carpet Grand Prix is entirely about *tilt discipline*, and it stacks in three
layers, each roughly ten hours of play apart:

1. **Hold it steady.** Beginners over-tilt in both axes at once and pinball between the
   rails, converting every straight into a series of rail-bounce speed scrubs. The first
   ten hours are spent learning that small, held inputs beat large, corrective ones.
2. **Ease off early.** Grip is a finite, draining resource under load (see tyre grip in
   `mechanics/secondary-mechanics.md`). The fast line brakes *with* the tilt before the
   apex, not at it — players in this layer are gold-capable but bleed 1–3 seconds per
   course to late braking.
3. **Read the height.** Experts pre-load tilt for a grade change they can see in the
   parallax two seconds before the car physically reaches it, because the deck's height
   above the carpet telegraphs the slope ahead. This is the layer that separates gold
   from Sprue (developer) times, and it is the mechanic the Achievement Hunter persona
   (P-008) is explicitly buying the game for.
