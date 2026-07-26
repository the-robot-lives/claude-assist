# Stage Promotion Checklist — Carpet Grand Prix

Promoted from `flesh/carpet-grand-prix/` on 2026-07-27.

Unlike the other staged games, this one arrived with a working implementation
rather than only a design tree, so Phase 11 below tracks code as well as docs.

---

## Phase 1: Directory Scaffolding

- [x] `stage/carpet-grand-prix/` created
- [x] `README.md` — standalone GDD plus index linking every subfolder document
- [x] `CHECKLIST.md` — this file
- [x] `design/` with core-loop, meta-loop, mechanics/, economy/, monetization/
- [x] `narrative/` with story-spine, characters/, dialogue/
- [x] `world/` with world-bible, geography/, lore/
- [x] `players/` with persona-mapping, player-journeys/, user-stories/
- [x] `production/` with tech-stack, team-plan, milestones, budget, risks
- [x] `platform/` with architecture + scope note
- [x] `assets/` with art-direction, audio-direction, references/
- [x] `flesh/carpet-grand-prix/` retained as the origin record (promotion is additive)

## Phase 2: Design Extraction

### Core Design
- [x] `design/core-loop.md` — loop diagram, 9-step table, session length, failure philosophy, three mastery layers
- [x] `design/meta-loop.md` — progression axes, unlock cadence, ghost system, medal tiers with shipped values
- [x] `design/mechanics/primary-mechanic.md` — the handset-as-tilting-table model, one input driving three systems, constraints table, skill ceiling
- [x] `design/mechanics/secondary-mechanics.md` — grip, boost, sticky, ramps, open edges, rail bounce, car mass, checkpoints
- [x] `design/mechanics/difficulty-progression.md` — 7-room escalation table + the "one new hazard verb per room" rule

### Economy & Monetization
- [x] `design/monetization/revenue-model.md` — premium $4.99, SKU table, four revenue scenarios, KPI targets
- [x] `design/economy/README.md` — documents the deliberate *absence* of a currency/economy
- [ ] `design/economy/currency-design.md` — **N/A**, no currency exists
- [ ] `design/economy/balance-sheet.md` — **N/A**, no economy to balance
- [ ] `design/monetization/iap-catalog.md` — **N/A**, premium model, no IAP

## Phase 3: World Building

- [x] `world/world-bible.md` — rules of the fiction, scale, track as scarce resource
- [x] `world/geography/room-index.md` — 7 rooms, unlock gates, hazard vocabulary
- [x] `world/geography/house-map.md` — floor plan and progression graph
- [x] `world/lore/timeline.md` — dated relative to Night 1
- [ ] `world/bestiary/` — **N/A**, no creatures
- [ ] `world/factions/` — **N/A**, no factions
- [ ] `world/items/` — **N/A**, no item system

## Phase 4: Narrative

- [x] `narrative/story-spine.md` — 8-point spine expanded shot by shot, 7-axis tone spectrum
- [x] `narrative/characters/character-index.md` — all 8 handling classes
- [x] `narrative/characters/{red-7,the-loaf,bit,the-boxed-one}.md` — the four story-load-bearing cars
- [x] `narrative/dialogue/tone-guide.md` — how a wordless game holds tone
- [ ] Individual files for Chrome, Wasp, Rustbucket, Sparks — index entries only, deferred to M6
- [ ] `narrative/quests/` — **N/A**, no quest structure

**Resolved during promotion:** the GDD's spine table has 8 beats but the game
unlocks 9 vignettes. Beat 8 (Resolution) is split into two vignettes — the box
reopening, and the new track being laid — since the GDD prose already describes
two distinct visual beats. Documented in `story-spine.md` so it does not read as
an error later.

## Phase 5: Player Research

- [x] `players/persona-mapping.md` — P-011, P-002, P-008, P-018 mapped to features
- [x] `players/player-journeys/` — one first-session journey per persona (4 files)
- [x] `players/user-stories/user-story-index.md` — all 36 stories, IDs US-001…US-036
- [x] Stories split into core-mechanics / progression / narrative / accessibility / onboarding
- [x] No new personas invented; all references by existing ID

**Known gap:** the GDD's monetization rationale cites P-015 (parent-buyer)
without that persona being defined in the library. Not invented; the
parent-buyer framing leans on P-002 alone.

## Phase 6: Production Planning

- [x] `production/tech-stack.md` — rewritten for native Swift/Metal, with a 10-entry decision log
- [x] `production/team-plan.md` — re-cast from the GDD's Unity team for a native build
- [x] `production/milestone-schedule.md` — M1–M12 plus M15/M21, exit criteria per milestone
- [x] `production/budget-breakdown.md` — adjusted for the team change
- [x] `production/risk-register.md` — 10 risks scored, owned, with triggers

**Corrected during promotion:** the GDD's team table sums to 9.5 heads but was
labelled 8.5. The column was right and the label was wrong; both the flesh and
stage documents now read 9.5.

## Phase 7: Asset Direction

- [x] `assets/art-direction.md` — four pillars, per-room palette table, procedural texture pipeline
- [x] `assets/audio-direction.md` — 7-stem accumulating arrangement, Audio Course Mode brief
- [x] `assets/references/mood-board.md` — written reference direction
- [ ] `assets/prompts/` — no generated media yet. Deferred; the game ships no
      binary image assets by design, so this directory serves marketing and
      concept work only, not production art.

## Phase 8: Genre-Specific Gate

**Genre: tilt-controlled arcade racer / time-attack**

- [x] Control scheme fully specified down to the sensor channel and filter constant
- [x] Rest-pose calibration and re-centring documented
- [x] Failure model documented (time cost, never crash-out, no lives)
- [x] Medal tiers defined with shipped numeric thresholds
- [x] Ghost/replay determinism strategy documented and implemented
- [x] Accessibility: tilt sensitivity range, parallax decoupling, Audio Course Mode
- [ ] Audio Course Mode prototyped — spec only, no implementation
- [ ] Medal times tuned from telemetry — placeholders until M10

## Phase 9: Platform Layer

- [x] `platform/PLATFORM-ARCHITECTURE.md` — describes the real app, not an aspiration
- [x] `platform/README.md` — states plainly why the other platform docs are N/A
- [ ] `platform/AGENT-SYSTEM.md` — **N/A**, no agents
- [ ] `platform/ECONOMY.md` — **N/A**, no economy
- [ ] `platform/GAME-API.md` — **N/A**, no server, no API
- [ ] `platform/MARKETPLACE.md` — **N/A**, no marketplace

Single-player, premium, fully offline. The absence of these four documents is a
decision, not an omission.

## Phase 10: Final Review

- [x] Engine corrected from Unity 6 to native Swift/Metal across every document
- [x] Origin record in `flesh/` amended in place rather than left silently wrong
- [x] Cross-references between stage documents resolve
- [x] Medal thresholds in docs reconciled against `Course.swift` (code is source of truth)
- [x] No "TBD" cells or placeholder rows
- [ ] Independent read-through by someone other than the author

## Phase 11: Implementation

### Written
- [x] `app/` — native iOS app, Swift + Metal, no dependencies
- [x] Simulation core (`Game/`) importing only Foundation + simd
- [x] Deterministic seeded track generation with invariant tests
- [x] Fixed 120 Hz physics accumulator decoupled from display rate
- [x] CoreMotion gravity-vector input, rest pose, re-centre, Vehicle Mode
- [x] Metal renderer: static mesh, vertex-shader parallax, 8 draws/frame
- [x] Procedural Core Graphics textures (carpet, car) — no binary assets
- [x] Persistence: best times, medals, ghost recordings, accessibility settings
- [x] SwiftUI shell: course select, car picker, HUD, results, settings
- [x] XcodeGen project spec + Makefile
- [x] Unit tests for track generation, physics, medals, ghosts

### Verified
- [x] `swiftc -typecheck` passes against the iOS 16 simulator SDK (Xcode 26.4.1)
- [ ] **`Shaders.metal` has never been compiled** — Xcode 26 moved the MSL
      compiler into a separate component (`xcodebuild -downloadComponent
      MetalToolchain`) that is not installed on the dev machine
- [ ] Test target has never been built (`@testable import` needs a real build)
- [ ] `make generate` / `make build` never run — `xcodegen` not installed
- [ ] **The app has never rendered a frame.** The renderer is unproven.
- [ ] Never run on a physical device, so the tilt feel is entirely untested

### Not started
- [ ] Audio (engine sound, music stems, Audio Course Mode)
- [ ] Rooms 2–7 (3 vertical-slice courses exist against a planned 38)
- [ ] Cars beyond the 8 handling classes (6 cosmetic variants)
- [ ] Story vignettes
- [ ] VoiceOver audit
- [ ] Android

---

## Completion Summary

| Phase | Status | Notes |
|---|---|---|
| 1. Scaffolding | ✅ | 39 documents |
| 2. Design | ✅ | Economy sections N/A by design |
| 3. World | ✅ | Bestiary/factions/items N/A |
| 4. Narrative | ✅ | 4 of 8 character files written; rest are index entries |
| 5. Players | ✅ | 36 stories, 4 personas, 4 journeys |
| 6. Production | ✅ | Re-cast for native Swift/Metal |
| 7. Assets | 🟡 | Direction complete; no generated media |
| 8. Genre gate | 🟡 | Audio Course Mode is spec-only; medal times are placeholders |
| 9. Platform | ✅ | 4 of 6 documents deliberately N/A |
| 10. Final review | 🟡 | Not independently read |
| 11. Implementation | 🟡 | Compiles; **shaders unvalidated, never executed** |

**The single most important open item:** nothing has rendered. Until
`MetalToolchain` is installed and the app has drawn a frame on hardware, the
entire rendering approach — which is the game's whole differentiator — is
unproven. Everything else on this list is subordinate to that.
