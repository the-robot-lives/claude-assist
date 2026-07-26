# Carpet Grand Prix — Production: Milestone Schedule

11-month production timeline, M1 through M12 launch, plus two post-launch
beats. Every milestone below assumes the native Swift + Metal build described
in `platform/PLATFORM-ARCHITECTURE.md` — there is no engine-upgrade risk on
this schedule, but there is real risk in the renderer and the sensor layer,
which is why both are staffed from M2 (see `production/team-plan.md`) and
why the feel-lock gate sits at M3, not later.

**Where the build already stands.** A working codebase already exists under
`app/CarpetGrandPrix/` — the physics core, track generation, medals, and
ghost recording are implemented and unit-tested; the Metal renderer and
CoreMotion input are implemented but have never been confirmed running on a
physical device (the Simulator has no gyroscope, and `Shaders.metal` has
never been compiled by a working MSL toolchain on the machine that wrote it).
That existing code is a head start on M1–M2, not a completed M1–M2. Nothing
on this schedule is "done" until it has been run on hardware.

| Month | Milestone | Exit criteria |
|---|---|---|
| M1 | Concept lock | This document set (design/production/platform) signed off. `prototype/index.html` validated on 6 handsets for feel baseline. MSL toolchain confirmed working end-to-end: `Shaders.metal` compiles and renders one course on a physical iPhone, not the Simulator. |
| M2 | Vertical slice — feel | Tilt → gravity → parallax loop is shippable-quality on one course, on physical hardware. Rest-pose calibration and re-centre work. Frame budget holds 60 fps on the minimum-spec device (iPhone 11) with all eight draws per frame present. |
| M3 | **Feel lock (gate)** | 20 external testers, on a physical device build, unprompted. **If fewer than 70% describe the controls as "natural" without being led, the scope cuts to 24 courses / 4 rooms / 8 cars and the plan rebuilds at ~$480,000.** See gate detail below. This decision is made and acted on at M3 — not discovered at M9 with seven months of the wrong scope already built. |
| M4 | Content pipeline | Track authoring tool operational (deterministic `Track.generate(for:)` plus an external authoring format — see M6). One room fully art-directed end to end: theme parameters tuned, procedural textures final, hazard vocabulary for that room locked. |
| M5 | Rooms 1–2 playable | 9 courses. Medals and ghosts (already engine-complete per the existing `Support/Persistence.swift`) wired to the SwiftUI HUD and results screen. |
| M6 | Track editor architecture | The internal course-authoring tool — used by the level designer for the remaining 29 courses — is built as the same tool that ships free to players at M15. Building it twice is not budgeted; it is built once, correctly, here. |
| M7 | Rooms 3–5 playable | 26 courses. **Alpha — feature complete.** Physics, rendering, input, and persistence are all proven on-device across the full room set that exists so far; nothing added after this point is a new *system*, only new *content*. |
| M8 | Rooms 6–7 + Audio Mode | 38 courses complete. Accessibility pass 1: Audio Course Mode stereo field (lane position as panning, rail proximity as tick rate, grade as engine pitch) implemented on the 14 courses committed to as audio-playable. |
| M9 | Vignettes + full audio | All 9 wordless vignettes in. Full 7-stem music arrangement layered via AVFoundation (no middleware — see `platform/PLATFORM-ARCHITECTURE.md` for why the audio stack, like the renderer, is hand-rolled rather than engine-provided). |
| M10 | **Beta / content lock** | Full 14-device matrix passed. Medal thresholds (bronze/silver/gold/sprue) tuned from playtest telemetry, not designer guesses. |
| M11 | Polish + certification | Accessibility pass 2 (independent audit). App Store Connect submission prepared: metadata, screenshots, TestFlight beta closed out. Metal shader validation completed across the full device matrix — the specific gap flagged as open in `app/README.md` today must be closed well before this point, not discovered here. |
| M12 | **Launch** | Free demo (4 Playroom courses) and the $4.99 paid SKU both live. Hotfix window open through the first two weeks. |
| M15 | Track editor update | Ships free. Player-authored courses shareable via deep link — the same tool built internally at M6, exposed to players. |
| M21 | The Garage Sale | Paid expansion, $2.99: 12 courses across 3 new rooms (Shed, Loft, Driveway), 4 new cars, 3 new vignettes. |

---

## The M3 gate, in detail

Twenty external testers play a physical-device build of the Playroom (Room 1,
4 courses) with no coaching on how to hold the phone. They are asked, open-
ended, what they thought of the controls. **The bar is 70%: at least 14 of 20
must describe the controls as "natural" — words to that effect, unprompted —
before anyone is asked "did tilting feel natural?" as a leading question.**

This is a pass/fail gate on the entire premise of the game, not a
soft checkpoint. The core loop, the meta loop, the world design, and the
monetization model all assume the tilt-as-gravity mechanic reads as intuitive
within seconds of picking the phone up (see GDD §3–§5). If it doesn't, no
amount of additional content fixes that — the honest response is to cut
scope, not push through.

**If the gate fails:**

- Scope cuts to **24 courses / 4 rooms / 8 cars** (roughly the Playroom,
  Kitchen, Hallway, and Attic; the eight starter-through-Basement-unlock
  cars).
- The animated vignettes drop to stills; the story spine is told in fewer,
  cheaper beats.
- The plan rebuilds at **~$480,000** total — a full re-cut of
  `production/budget-breakdown.md` and `production/team-plan.md`, not a
  proportional trim.
- **This decision is made at M3.** The GDD is explicit that the wrong place
  to discover a feel problem is M9, six months and most of the art budget
  later. The schedule above staffs the graphics and gameplay engineers from
  M2 specifically so this gate can be evaluated on real hardware, on
  schedule, at M3.
