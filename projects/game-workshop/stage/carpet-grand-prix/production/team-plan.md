# Carpet Grand Prix — Production: Team Plan

Re-cast from the GDD's Unity 6 team (§11) for the actual build: a native iOS app,
Swift throughout, hand-written Metal renderer, no engine, no third-party
dependencies. 9.5 peak heads, $692,500 salary cost over an 11-month production
window — within 5% of the GDD's $661,500, using the GDD's own role-count method
(see the note on headcount below).

| Role | Count | Phase | Monthly cost | Months | Total |
|---|---|---|---|---|---|
| Technical director / gameplay lead | 1 | M1–M11 | $12,000 | 11 | $132,000 |
| Gameplay engineer (physics, CoreMotion input, ghosts) | 1 | M2–M10 | $9,500 | 9 | $85,500 |
| Graphics engineer (Metal / MSL renderer) | 1 | M2–M11 | $10,500 | 10 | $105,000 |
| Art director | 1 | M1–M11 | $10,000 | 11 | $110,000 |
| Environment / track artist (room theming, procedural params) | 1 | M3–M9 | $7,500 | 7 | $52,500 |
| Animator (vignettes) | 1 | M6–M10 | $7,500 | 5 | $37,500 |
| Level designer (38 courses) | 1 | M4–M11 | $7,000 | 8 | $56,000 |
| Composer / sound design (contract) | 1 | M6–M10 | $6,000 | 5 | $30,000 |
| QA (device matrix, sensor + Metal testing) | 1 | M7–M12 | $5,000 | 6 | $30,000 |
| Producer (half-time) | 0.5 | M1–M12 | $4,500 | 12 | $54,000 |
| **Peak headcount** | **9.5** | | | | **$692,500** |

---

## Roles changed from the GDD's Unity plan, and why

**Dropped: "Engineer (UI, platform, audio integration)" as a generalist seat.**
In a Unity build this role exists because someone has to wrangle the engine's
UI Toolkit, its audio mixer graph, and its platform build settings — none of
which map to a specific piece of shippable code the way `Render/` or `Game/`
do. In the native build, the SwiftUI shell is a comparatively small surface
(the current `App/ContentView.swift` and its child views run under 500 lines
total) and platform integration is App Store Connect configuration, not engine
plumbing. That work is folded into the Technical Director's own time — hence
the TD's rate moving from $11,500/mo to $12,000/mo — rather than staffed as a
separate seat for eleven months of a generalist with no single system to own.

**Added: Graphics engineer (Metal / MSL renderer), replacing that seat.**
This is the role the GDD's plan doesn't have and the native build cannot ship
without. There is no URP, no Shader Graph, no built-in 2D parallax stack —
`Render/Shaders.metal` and the mesh builder in `Render/DioramaBuilder.swift`
*are* the renderer, hand-written. This is also the single highest-risk system
in the game (GDD §12, challenges #3 and #4 — motion-sickness-safe parallax and
fill-rate on a layered diorama), so the role starts at M2, not M4: the
vertical-slice and feel-lock milestones (M2–M3) cannot pass without a working
renderer on a physical device. It carries a premium over the physics
engineer's rate ($10,500 vs $9,500/mo) because MSL/Metal specialists are
scarcer in the mobile labor market than general iOS engineers, and a longer
span (M2–M11, 10 months, vs the old role's M4–M11, 8 months) to match.

**Trimmed: Environment / track artist, 8 months → 7 months.**
`Render/TextureFactory.swift` generates every texture in the game
procedurally at load time with Core Graphics — the carpet weave, the car
livery, the room fleck pattern — from a `RoomTheme` struct and a seed. There
is no imported texture atlas, no hand-painted diffuse map, no art
round-trip through an external DCC tool and back into the engine. The
environment artist's job shifts from asset production to tuning the
`RoomTheme` parameters (palette, fleck density, ambient tint, vignette) per
room and directing the shader-driven look — a lighter task that finishes a
month earlier than in a pipeline built around imported art.

**Unchanged, deliberately: no separate technical artist.** The GDD's Unity
plan doesn't have one either, but it's worth stating why the native build
doesn't need one where a studio might expect it to: there is no shader graph
to hand off between an artist and an engineer, no lighting-rig wrangling
inside an engine's inspector, no render-pipeline asset to configure. The
graphics engineer writes the shaders directly against the art director's
palette targets. Splitting that into "artist who describes the look" and
"engineer who owns the .shader file" only makes sense when there's an engine
layer between them; here there isn't one.

**Unchanged: art director, animator, level designer, composer, QA, producer.**
None of these roles are engine-dependent enough to change. QA's scope
absorbs Metal shader validation across the device matrix alongside sensor
testing (see `platform/PLATFORM-ARCHITECTURE.md` for why both are on the
critical path), but the seat, timing, and rate carry over unchanged.

---

## On the headcount number

The GDD prints "Peak headcount: 8.5," but summing its own Count column (nine
roles at 1.0 plus a half-time producer) gives 9.5, not 8.5 — an arithmetic
slip in the source document, not a deliberate design decision. This plan
reproduces the GDD's actual role-count method (sum of the Count column) and
gets 9.5, matching the GDD's real structure rather than its printed total.
See the risk register and the note in `production/budget-breakdown.md` for
how this affects budget-vs-revenue framing.
