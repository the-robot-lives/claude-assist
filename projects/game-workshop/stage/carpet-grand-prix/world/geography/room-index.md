# Carpet Grand Prix — Room Index

Seven rooms, 38 courses. Escalation is width down, grade up, hazard count up — never
"more enemies" or "tighter timer." Every room adds exactly one new hazard verb to the
vocabulary and reuses everything established before it; nothing is ever retired.

## Room Progression Table

| Room | Unlock gate | Courses | Lane width | Avg grade | New hazard vocabulary | Target gold time |
|---|---|---|---|---|---|---|
| **1. Playroom** | Start | 4 | 95 u | 12% | None. Rails only — wide, forgiving, the room that teaches tilt-to-accelerate with zero hazards | 38–46 s |
| **2. Kitchen** | 4 medals | 5 | 95 u | 16% | Boost strips; first spilled-juice sticky patches | 42–55 s |
| **3. Hallway** | 10 medals | 5 | 88 u | 14% | Long straights, hairpin turnarounds, rug-seam drop-offs | 55–70 s |
| **4. Attic** | 18 medals | 6 | 84 u | 22% | Ramps and airtime; rafter gaps | 48–62 s |
| **5. Garage** | 26 medals | 6 | 80 u | 19% | Oil slicks (extreme sticky), tool hazards | 60–78 s |
| **6. Basement** | 34 medals | 6 | 73 u | 27% | Open edges over a void; darkness, headlight-cone visibility only | 52–68 s |
| **7. Garden** | 44 medals | 6 | 70 u | 24% | Wind (constant lateral bias), wet grass, downhill finale | 70–95 s |
| **The Box** (narrative epilogue) | All 38 golds, or 60 medals total | 0 (no new courses) | — | — | — | — |

Total: 38 courses across 7 playable rooms. The Box is a narrative gate only — it
unlocks Resolution vignettes 8 and 9, not new track.

## Reading the escalation

Every column moves in the same direction as the room number, on purpose:

- **Lane width** shrinks steadily from 95 u in the Playroom to 70 u in the Garden —
  the single cleanest measure of rising precision demand across the game.
- **Average grade** is not monotonic — it dips at Hallway (flat, wide, technical
  rather than steep) and again at Garage relative to Attic — because grade and
  hazard count are deliberately decoupled. A room can be hard through tight
  cornering (Hallway) or hard through elevation (Attic, Basement) or hard through
  a compounding hazard stack (Garden, which reintroduces grade *and* wind *and*
  a wet-grass grip penalty together for the game's hardest gold times).
- **Hazard vocabulary is strictly additive.** Kitchen's boost strips and sticky
  patches reappear, unchanged, in every room after it. Attic's ramps reappear in
  Garage and beyond. By the Garden, a single course can legitimately combine boost
  strips, sticky patches, rug-seam drop-offs, ramps, oil slicks, open edges, and
  wind in one 70–95 second run — every hazard the game has ever taught, stacked at
  once, which is exactly why Garden carries the highest gold-time target in the
  game.

## Per-room hazard vocabulary in detail

| Room | Hazard | What it does |
|---|---|---|
| Playroom | *(none)* | Deliberately hazard-free; the room exists to teach tilt-to-accelerate |
| Kitchen | Boost strip | +620 u/s² along the tangent while in contact; always off the natural line |
| Kitchen | Sticky patch (spilled juice) | Grip drops to 1.4/s, drag +2.6 |
| Hallway | Rug-seam drop-off | A visible edge where a runner rug meets hardwood; punishes an imprecise line the way an open edge does, but telegraphed well in advance |
| Attic | Ramp | 0.72 s airborne, gravity still applies, grip does not; clean landings keep all speed |
| Attic | Rafter gap | A narrow overhead constraint that forces a precise line on some courses; the room's signature technical hazard |
| Garage | Oil slick | Extreme version of the sticky patch — a harder grip and drag penalty than Kitchen's juice, introduced once the base mechanic is already second nature |
| Garage | Tool hazard | Loose tools and hardware scattered on the concrete; functions as a rail-adjacent obstacle requiring a clean line choice |
| Basement | Open edge | The only true hazard in the game with no speed-scrub mercy — rail is entirely absent on one flagged side; +2.0 s and a checkpoint respawn on a miss |
| Basement | Darkness / headlight-cone visibility | The room is lit only by the car's own headlights, meaning hazards ahead are legible only within the cone — the game's only visibility-based (rather than physics-based) hazard |
| Garden | Wind | Constant lateral bias the player must counter-tilt against continuously, unlike every prior hazard which is positional |
| Garden | Wet grass | A grip penalty applied to the entire course rather than to isolated patches — the room's baseline surface, not a hazard placed on top of a clean one |

Every room's course design is required to introduce its new hazard in isolation on
at least its first course before combining it with prior-room hazards on later
courses in the same room — the same "teach one thing before you teach two" principle
the Playroom uses for tilt itself.
