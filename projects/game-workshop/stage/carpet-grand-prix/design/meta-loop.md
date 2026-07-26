# Carpet Grand Prix — Meta Loop

What carries between runs and between sittings. Carpet Grand Prix has **no currency** —
see `economy/README.md` for why — so every axis below is earned directly through play,
never purchased or farmed.

```
run finished ──► time recorded ──► medal assigned ──► ghost updated
                                          │
                                          ▼
                          medal total crosses a room threshold
                                          │
                                          ▼
                new room unlocked (floor, hazard verb, music stem, vignette)
                                          │
                                          ▼
                              next run, more options
```

## Progression axes

| Axis | What grows | How growth feels | Cap |
|---|---|---|---|
| **Times** | Per-course best time + ghost replay | The ghost is *you, yesterday* — beating it is the entire mid-game hook | No cap; times can always be shaved |
| **Medals** | Bronze / Silver / Gold / Sprue per course | A wall of medal icons fills in; every room shows a visible fraction complete | 4 tiers × 38 courses = 152 medal states |
| **Rooms** | 7 rooms unlock at medal thresholds | New floor material, new hazard vocabulary, new music stem, one story vignette | 7 rooms + The Box epilogue |
| **Cars** | 14 die-cast cars with genuinely different handling | Not upgrades — *tools*. A heavy car dominates the Attic's grade, struggles on the Basement's grip-limited edges | 14 cars, 8 with distinct handling classes + 6 cosmetic variants |
| **Track pieces** | Cosmetic track skins (orange classic, glow, wood, chrome) | Pure self-expression; earned, never sold | 4 skins at launch |
| **The Box** | Narrative beats unlock as rooms complete | Nine wordless vignettes about a kid outgrowing the toys | 9 vignettes, fixed |

## Unlock cadence

One meaningful unlock lands roughly **every 2–3 runs for the first hour**, tapering to
**one every 5–6 runs by hour two**. This is deliberately front-loaded: a new player's
first sitting should never go two runs without a new car, room, or medal state to chase,
while a ten-hour player is expected to be self-motivated by ghost deltas rather than
unlock density.

Room unlock gates are priced in medals, not currency:

| Room | Unlocks at | Cumulative medals required |
|---|---|---|
| Playroom | Start | 0 |
| Kitchen | Playroom progress | 4 |
| Hallway | Kitchen progress | 10 |
| Attic | Hallway progress | 18 |
| Garage | Attic progress | 26 |
| Basement | Garage progress | 34 |
| Garden | Basement progress | 44 |
| The Box | All rooms complete | 38 golds, or 60 medals total |

Because thresholds are *total medals*, not *gold medals*, a player who only ever earns
bronze still opens every room — the ladder rewards steady play as much as mastery.

## Ghost system

Every course records the player's best run as a **40 Hz sample stream of position and
tilt**. On replay, the ghost renders as a translucent second car sharing the same
diorama-height parallax as the live car, so a ghost that took a higher line on an
elevated section is visibly *above* the player's own car, not just ahead of it.

- Ghosts store raw tilt alongside position — not for physics replay (the ghost is
  positionally deterministic), but so an ambitious player can see *what input* produced
  the faster line, not just where it went. This is the single most-requested data point
  from the Achievement Hunter persona (P-008).
- A new personal-best run overwrites the stored ghost immediately at the finish line.
- The developer ("Sprue") ghost is always available even before it is beaten, rendered in
  a distinct colour, so a player can see exactly how far off the tightest possible line
  they are from run one.

## Medal tiers: bronze / silver / gold / sprue

Each course defines a **Target gold time band** (see `mechanics/difficulty-progression.md`
for the per-room bands, e.g. Playroom 38–46s, Basement 52–68s). Individual course medal
cutoffs are tuned inside that room's band during production, using a fixed multiplier
rule so every course in the game is legible the same way:

| Tier | Cutoff (relative to that course's tuned gold time, *G*) | Who reaches it |
|---|---|---|
| **Bronze** | Finish under 1.44 × *G* | Anyone who holds the phone reasonably still and finishes the course at all — this is the "everyone gets a medal" floor described in the core loop's failure philosophy |
| **Silver** | Finish under 1.20 × *G* | A player who has learned line choice and is easing off before corners rather than at them |
| **Gold** | Finish under *G* | Requires the full "ease off early" mastery layer — grip management through every corner on the course |
| **Sprue** (developer time) | Finish under 0.88 × *G* | Requires the "read the height" mastery layer — pre-loading tilt for grade changes the player can't yet see with the naked eye, only the parallax |

### Shipped values

The multiplier rule above is the *derivation*; the thresholds themselves are data,
declared per course in `app/CarpetGrandPrix/Game/Course.swift` as
`medalTimes: SIMD4<Double>(bronze, silver, gold, sprue)`. **The code is the source of
truth** — if a tuning pass moves a number, this table follows it, not the other way
round. The three courses implemented so far are the vertical-slice set, not the final 38:

| Course | Room | Length | Bronze | Silver | Gold | Sprue |
|---|---|---|---|---|---|---|
| Kitchen Cascade | Kitchen | 7,200 u | 70.0 s | 58.0 s | 48.0 s | 42.0 s |
| Attic Autobahn | Attic | 9,600 u | 88.0 s | 74.0 s | 62.0 s | 55.0 s |
| Basement Drop | Basement | 12,000 u | 112.0 s | 94.0 s | 78.0 s | 68.0 s |

These are hand-set placeholders standing in for telemetry. Medal times are properly tuned
at **M10 (beta / content lock)** from real player distributions — the intent is that gold
sits near the 85th percentile of runs by players who have finished the room, and Sprue
near the 99th.

Sprue is deliberately the only tier named after the game's own material fiction (the
plastic sprue a toy car is moulded on) rather than a generic medal colour — it is framed
in-game as "you drove it the way it was designed to be driven," not as a fourth medal but
as proof of developer-level mastery. The wall of medal icons on the room-select screen
never shows a fifth column for it; Sprue is a badge on top of a gold, not a separate slot.
