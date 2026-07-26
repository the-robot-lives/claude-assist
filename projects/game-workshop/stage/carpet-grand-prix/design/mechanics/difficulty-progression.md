# Carpet Grand Prix — Difficulty Progression

Seven rooms, 38 courses. Escalation runs across three axes at once — lane width, average
grade, and hazard vocabulary — and deliberately never touches a fourth: time pressure.

## Room-by-room escalation

| Room | # Courses | Lane width | Avg grade | New vocabulary | Target gold time |
|---|---|---|---|---|---|
| 1. Playroom | 4 | 95 u | 12% | Rails only. Wide, forgiving, no hazards. | 38–46 s |
| 2. Kitchen | 5 | 95 u | 16% | Boost strips; first spilled-juice sticky patches | 42–55 s |
| 3. Hallway | 5 | 88 u | 14% | Long straights, hairpin turnarounds, rug seams | 55–70 s |
| 4. Attic | 6 | 84 u | 22% | Ramps and airtime; rafter gaps | 48–62 s |
| 5. Garage | 6 | 80 u | 19% | Oil slicks (extreme sticky), tool hazards | 60–78 s |
| 6. Basement | 6 | 73 u | 27% | Open edges over a void; darkness, headlight cone | 52–68 s |
| 7. Garden | 6 | 70 u | 24% | Wind (constant lateral bias), wet grass, downhill finale | 70–95 s |

## The design rule

> **Width down, grade up, one new hazard verb per room, never a tighter timer.**

This rule is enforced as a hard constraint during level design, not a loose guideline:

- **Width down.** Lane width falls from 95 u in the Playroom to 70 u in the Garden — a
  25% reduction in the physical margin for error, which alone accounts for most of the
  late-game difficulty increase without adding a single new system.
- **Grade up, but not monotonically.** Average grade rises overall (12% → 24%) but is
  allowed to dip room-to-room (Attic's 22% down to Garage's 19%, then back up) — the
  curve tracks *cumulative hazard load*, not a straight line, so no two adjacent rooms
  feel like the same difficulty with a new coat of paint.
- **One new hazard verb per room, everything prior reused.** Boost strips (Kitchen),
  sticky patches (Kitchen), ramps (Attic), oil slicks (Garage), open edges (Basement),
  and wind (Garden) each appear exactly once as a *new* introduction and then persist as
  background vocabulary in every room after. By the Garden, a course can combine wind,
  wet grass, a narrow lane, and a downhill grade — but the player has already learned
  each ingredient in isolation.
- **Never a tighter timer.** There is no course timer at all beyond the player's own
  stopwatch and medal thresholds (`meta-loop.md`). Difficulty is never expressed as "go
  faster or fail" — it is expressed entirely through track geometry and hazard density,
  which keeps the failure philosophy in `core-loop.md` (time cost, never crash-out) true
  at every difficulty level, including the hardest Sprue times in the Garden.

## Why this ordering

The room sequence (Playroom → Kitchen → Hallway → Attic, branching to Garage → Basement →
Garden) is spatial, not purely mechanical — see the world design docs for the house
layout — but the mechanical escalation is deliberately front-loaded onto the two branches
independently: Attic teaches airtime while Garage teaches extreme sticky surfaces, so a
player who takes either branch first meets exactly one new hazard verb, never two at
once. Both branches converge on Basement, which is tuned as the hardest room in the base
game specifically because it is the only room whose signature hazard (open edges) has no
softer, earlier version to have practiced against.
