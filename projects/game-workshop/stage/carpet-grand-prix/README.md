# Carpet Grand Prix

> The floor is the racetrack. The phone is the floor.

A tilt-controlled arcade racer for iPhone. You do not drive the car — you tilt
the *world*, and the car obeys gravity the way a real die-cast car does.

**Status:** promoted to `stage/` on 2026-07-27. Playable Swift/Metal
implementation exists at [`app/`](app/). Design origin:
[`flesh/carpet-grand-prix/`](../../flesh/carpet-grand-prix/README.md).

---

## Quick Facts

| Field | Value |
|---|---|
| Genre | Tilt-controlled arcade racer / time-attack |
| Sub-genre | Physical-toy simulation ("diorama racer") |
| **Engine** | **None — native Swift + hand-written Metal renderer** |
| Platform | iOS 16+ (iPhone 11 and newer), portrait, one-handed |
| Android | Rewrite of the platform layers, 6 months post-launch |
| Input | Device gravity vector (CoreMotion). Touch is menu-only. |
| Monetization | Premium $4.99. No ads, no IAP, no currency. |
| Rating | ESRB E / PEGI 3 / App Store 4+ |
| Session | 45–120 s per run; 4–7 min per sitting |
| Scope | 38 courses, 7 rooms, 14 cars, ~3.5 h to credits |
| Budget / timeline | $919,000 / 12 months to launch, 9.5 peak heads |

---

## Documents

| Area | Documents |
|---|---|
| **Design** | [core-loop](design/core-loop.md) · [meta-loop](design/meta-loop.md) · [primary mechanic](design/mechanics/primary-mechanic.md) · [secondary mechanics](design/mechanics/secondary-mechanics.md) · [difficulty progression](design/mechanics/difficulty-progression.md) · [revenue model](design/monetization/revenue-model.md) · [economy (deliberately none)](design/economy/README.md) |
| **Narrative** | [story spine](narrative/story-spine.md) · [character index](narrative/characters/character-index.md) · [tone guide](narrative/dialogue/tone-guide.md) |
| **World** | [world bible](world/world-bible.md) · [room index](world/geography/room-index.md) · [house map](world/geography/house-map.md) · [timeline](world/lore/timeline.md) |
| **Players** | [persona mapping](players/persona-mapping.md) · [journeys](players/player-journeys/) · [user stories](players/user-stories/user-story-index.md) |
| **Production** | [tech stack](production/tech-stack.md) · [team plan](production/team-plan.md) · [milestones](production/milestone-schedule.md) · [budget](production/budget-breakdown.md) · [risks](production/risk-register.md) |
| **Platform** | [architecture](platform/PLATFORM-ARCHITECTURE.md) · [scope note](platform/README.md) |
| **Assets** | [art direction](assets/art-direction.md) · [audio direction](assets/audio-direction.md) · [mood board](assets/references/mood-board.md) |
| **Implementation** | [app/README.md](app/README.md) |

---

## Vision

Carpet Grand Prix is what it feels like to be eight years old, lying on the
living-room floor with a plastic orange track running from the couch cushion
down to the kitchen tile. Because the game reads the handset's true orientation,
tipping the phone does two things at once: it feeds gravity into the physics,
and it moves your viewpoint over a floating diorama, so the track visibly slides
across the carpet beneath it and the rails lean away from you. The result is a
racer where the screen stops reading as a picture and starts reading as an
object sitting on the floor in front of you.

It exists because tilt controls on mobile have been treated as a cheap
accelerometer gimmick for fifteen years, and nobody has yet made the tilt *be*
the fiction.

---

## Core Loop

Target session: 45–120 s per run, 4–7 min per sitting.

```
PICK A COURSE ──► CALIBRATE ──► THE RUN ──► FINISH ──► again / next
   (5s)             (2s)        (40-110s)     (6s)

   inside the run:
     tip away ──────► gravity accelerates the car
     read the grade ─► parallax height shows what is coming
     tilt sideways ─► pick your line
     ease off ──────► carve the corner instead of sliding
```

There is no crash-out and no lives. Every mistake is a *time* cost: a rail costs
20% of your speed, a fall costs 2.0 s plus the re-accelerate. The course always
finishes. See [core-loop.md](design/core-loop.md).

---

## Meta Loop

| Axis | What grows |
|---|---|
| Times | Per-course best + ghost replay of your own best line |
| Medals | Bronze / Silver / Gold / Sprue per course |
| Rooms | 7 rooms unlock at medal thresholds (4/10/18/26/34/44) |
| Cars | 14 cars with genuinely different handling — tools, not upgrades |
| Track skins | Cosmetic; earned, never sold |
| The Box | 9 wordless story vignettes |

There is no currency in this game at all. See [meta-loop.md](design/meta-loop.md).

---

## The Mechanic

One input — the handset's gravity vector — drives three systems at once:

1. **Gravity.** The phone *is* the table the track is bolted to. Tilt produces
   world-space acceleration; track grade adds its own pull along the tangent.
2. **Viewpoint.** The carpet is at height 0, the deck floats ~74 units above it
   on visible posts, rails extrude another 27. Screen position is
   `world + height × viewVector`, and `viewVector` comes from the tilt. Raised
   things slide over the floor in proportion to their height.
3. **Gradient legibility.** Deck height is drawn *relative to the car's
   elevation*, so track ahead sinks toward the carpet on a descent. You read
   gradient the way you read a real Hot Wheels run — by how far off the floor
   it is.

Tyres bleed lateral velocity at 5.0/s, so the car carves rather than sliding
like a marble; push past ~70% lateral load and it drifts.

Full detail: [primary-mechanic.md](design/mechanics/primary-mechanic.md).

---

## Rooms

| # | Room | Courses | Lane | Grade | New hazard vocabulary |
|---|---|---|---|---|---|
| 1 | Playroom | 4 | 95 u | 12% | Rails only |
| 2 | Kitchen | 5 | 95 u | 16% | Boost strips, spilled juice |
| 3 | Hallway | 5 | 88 u | 14% | Long straights, hairpins, rug seams |
| 4 | Attic | 6 | 84 u | 22% | Ramps, airtime, rafter gaps |
| 5 | Garage | 6 | 80 u | 19% | Oil slicks, tool hazards |
| 6 | Basement | 6 | 73 u | 27% | Open edges over a void, darkness |
| 7 | Garden | 6 | 70 u | 24% | Wind, wet grass, the finale |

Escalation is width down, grade up, one new hazard verb per room. Never a
tighter timer. See [difficulty-progression.md](design/mechanics/difficulty-progression.md).

---

## Story

Wordless. Nine vignettes, 8–14 seconds each, no dialogue or narrator anywhere.

A kid outgrows their toy cars. A box marked DONATE appears. The cars start
moving at night, stealing back one piece of track at a time and running it
through the house. At the midpoint the kid comes downstairs at 2 a.m., sees the
track running through the kitchen, steps over it, and never mentions it.

The resolution: the box is open on the patio, nothing was thrown away, and the
kid — older, taller — is laying new track across the grass for someone smaller
standing behind them.

Tone: playful, grounded, warm, intimate, sincere, with a gentle melancholy
underneath. See [story-spine.md](narrative/story-spine.md).

---

## Players

Four target personas from the workshop library:

| Persona | Why | What they will skip |
|---|---|---|
| **P-011** Maria Rodriguez — commuter | 50 s run = one station gap; fully offline | Everything past Room 3 |
| **P-002** Sarah Chen — micro-gamer, parent | 3–6 min windows, no energy gate, kids watch | The Basement's hard golds |
| **P-008** David Park — completionist | 38 × 4 medal grid, hard developer times | Nothing |
| **P-018** Rachel Green — legally blind | Audio Course Mode: tilt is proprioceptive, the course is a 1-D line | 24 of 38 courses, honestly stated |

P-018 is a design constraint, not a marketing claim — the store page states
exactly which 14 courses are audio-playable. See
[persona-mapping.md](players/persona-mapping.md).

---

## Monetization

Premium **$4.99**. No ads, no IAP, no currency. Free 4-course demo carries the
conversion load. One paid expansion at $2.99 in month 21; a free track editor in
month 15.

The fiction is a child's toy box, aimed at an audience that includes parents
buying for children. Every F2P instrument — energy gates, gacha cars, ad breaks
— destroys the two things this game sells: a 50-second session you can start any
time, and toys that are *yours*. Arm fatigue also caps sessions at ~7 minutes,
which caps ad and IAP exposure well below what an F2P economy needs.

| Scenario | Demo installs | Conv. | Units | Net total |
|---|---|---|---|---|
| Floor | 60,000 | 3.5% | 2,100 | $5,674 |
| Modest | 250,000 | 5.0% | 12,500 | $35,350 |
| Good | 900,000 | 6.5% | 58,500 | $170,345 |
| Breakout | 4,200,000 | 8.0% | 336,000 | $1,006,040 |

The budget only closes in *Good* or better. See
[revenue-model.md](design/monetization/revenue-model.md).

---

## Production

12 months to launch, 9.5 peak heads, $919,000 all-in.

The load-bearing gate is **M3 — feel lock**. Twenty external testers, and ≥70%
must describe the controls as natural unprompted. If that fails, the correct
decision is to cut to 24 courses / 4 rooms / 8 cars, drop animated vignettes to
stills, and rebuild at ~$480,000. That decision belongs at M3, not M9.

See [milestone-schedule.md](production/milestone-schedule.md) and
[risk-register.md](production/risk-register.md).

---

## Technical

Native Swift, no engine, no third-party dependencies, no binary assets.

- `Game/` imports only Foundation and simd — the physics is directly unit-testable
- Fixed 120 Hz physics accumulator, decoupled from display rate
- Parallax computed in the vertex shader over a static mesh; eight draws per
  frame, zero per-frame geometry work
- CoreMotion gravity vector rather than Euler angles — no gimbal, no wrap, no
  axis remapping
- Ghosts store sampled position, not input, so a tuning change never invalidates
  a stored time
- Local-only persistence: no account, no server, no network

The single largest technical risk is **sensor variance across Android OEMs**,
which is why Android launches six months late and ships a data-driven per-device
profile table. See [tech-stack.md](production/tech-stack.md) and
[PLATFORM-ARCHITECTURE.md](platform/PLATFORM-ARCHITECTURE.md).

---

## Known Gaps

The implementation in `app/` type-checks but **has never rendered a frame**. The
Metal shaders have not been compiled — Xcode 26 moved the MSL compiler into a
separate component that is not installed on the development machine. Treat the
renderer as unproven until it has run on hardware. Full status in
[app/README.md](app/README.md) and [CHECKLIST.md](CHECKLIST.md).
