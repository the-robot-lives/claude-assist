# Carpet Grand Prix — Art Direction

Visual design pillars, per-room palette and lighting specification, and the
procedural-texture pipeline that produces every surface the player sees.

## Engine correction

Carpet Grand Prix is **not** a Unity 6 project. It is a native iOS application
written in Swift with a custom Metal renderer (see `app/CarpetGrandPrix/Render/`).
Everything in this document assumes that pipeline. There is no 3D geometry anywhere
in the game — the "diorama" look is entirely correct positional parallax on a
layered 2D scene, produced by the tilt-driven viewpoint math described in the flesh
GDD's primary mechanic section. Any reference to "3D," "camera," or "depth" in this
document or elsewhere in the design corpus refers to that layered-parallax effect,
never to a perspective-projected 3D scene.

## Art Direction Pillars

| Pillar | Description |
|---|---|
| **Die-cast, not photoreal.** | Cars have visible seam lines, a base plate, and a chip in the paint. The track is scuffed orange plastic with stress marks at the joins. Nothing in the game is rendered to look like a photograph of a real car or a real house — everything is rendered to look like a toy of that thing, at toy fidelity, on purpose. |
| **The floor is real, the track is a toy.** | Carpet, tile, and floorboards are rendered at high fidelity with real fibre noise and material variation; the track above it stays flat, saturated, and unmistakably moulded plastic. The contrast between a photographically-textured floor and a flat-shaded toy is the entire visual joke of the game, and every room's art pass is graded to preserve that contrast, never to soften it. |
| **Light comes from the room, not the game.** | Each room has exactly one dominant practical light source, and that source casts the track's shadow onto the real floor beneath it in a single, fixed, consistent direction for that room. There is no game-authored rim light, no character-silhouette backlight, no UI-driven light source anywhere in a playable scene — every visible light has a diegetic, in-room origin (a window, a bulb, a fluorescent tube, headlights, dusk). |
| **Height reads as colour.** | Track sections sitting higher off the floor are lit brighter; sections near the floor fall into the room's ambient shadow. This pillar is not just an aesthetic choice — it is how the primary tilt mechanic communicates grade to the player before they reach it (see the flesh GDD's parallax-height grade-legibility system), so palette and lighting design for every course must keep this readable at a glance, in motion, at speed. |

## Per-room palette, light, and floor

| Room | Floor | Palette | Light source |
|---|---|---|---|
| Playroom | Short shag, blue-grey | Orange track, cyan rails | Afternoon window, warm |
| Kitchen | Vinyl tile, gloss | Amber track, pink rails | Overhead fluorescent, cold |
| Hallway | Runner rug + hardwood | Deep orange, white rails | Door gaps, striped |
| Attic | Bare plywood, dust | Ochre track, red rails | Single bulb, swinging |
| Garage | Sealed concrete, oil | Grey-blue track, yellow rails | Strip light, buzzing |
| Basement | Bare slab, dark | Violet track, mint rails | Car's own headlights only |
| Garden | Wet grass, patio slab | Green-white track, orange rails | Dusk, long shadows |

Palette shifts room to room on two axes simultaneously: the floor material moves
from soft-domestic (shag, tile, rug) toward hard-industrial (plywood, concrete,
bare slab) as the player descends toward Basement, then resolves outward into
Garden's organic grass and stone; and the light source moves from soft ambient
(window, fluorescent) toward harsh or absent (swinging bulb, headlights-only) at
the same rate, bottoming out at Basement before the Garden's dusk light restores
warmth for the finale. This mirrors the story spine's own emotional arc — the
Basement, mechanically and narratively the low point, is also the visual low point,
lit only by the player's own car.

## Procedural textures — no binary image assets ship

Every texture in Carpet Grand Prix is generated at load time in Core Graphics and
uploaded directly to a Metal texture (`TextureFactory.swift`). The game ships with
zero binary image assets — no PNGs, no sprite sheets, no baked normal maps, nothing
an art tool exported. A room's carpet, a car's livery, and every other surface in
the game exist only as generation code plus a small set of numeric parameters (a
palette, a seed, a noise density) until the moment the app draws them.

**What this constrains:**

- No hand-painted texture detail. An artist cannot add a scuff, a highlight, or a
  logo the way they would in a paint tool — every visual flourish has to be
  expressed as a drawing routine (rectangles, noise fields, gradients, primitive
  shapes) rather than a brush stroke, which caps fine detail well below what a
  photobashed or hand-painted texture could achieve.
- No off-device content pipeline. There is no exported PSD, no texture-atlas build
  step, no artist handoff file that a non-programmer can open and edit directly —
  every texture change is a code change, reviewed and shipped the same way gameplay
  code is.
- Texture identity is tied to a seed, not a file. A "specific" carpet texture is
  really a (theme, seed) pair — reproducible and diffable in code review, but not
  something you can crop, retouch, or composite in an external tool the way a PNG
  can be.

**What this buys:**

- Zero art-asset weight against the 220 MB install-size ceiling in the flesh GDD's
  technical requirements — every surface in the game costs kilobytes of Swift, not
  megabytes of texture data.
- A new room theme or car livery is a code change on the order of minutes, not an
  art-team round trip through concepting, painting, exporting, and importing — the
  same texture factory that produces the Kitchen's amber track can produce a new
  room's palette by changing the theme struct's colour values, with no new asset
  pipeline work.
- Every texture is seeded and therefore deterministic and reproducible — the same
  room always generates the identical carpet weave on every device, every session,
  with no asset-versioning or CDN dependency, which also means ghosts and course
  screenshots are visually consistent across every player's device without a texture
  download step.
- Trivial localisation and accessibility variants — a colour-blind-safe palette or a
  high-contrast mode is a parameter swap on the same generation code, not a
  re-export of every affected asset.

This pipeline is the art department's central constraint and its central advantage
at once: nothing in this game's visual identity can rely on painterly, one-off
detail work, but everything in it can be tuned, varied, and shipped at negligible
size and near-zero iteration cost. Art direction for every room and every car has to
be authored as *rules*, not as individual images — this document's pillars and
tables exist to be that rule set.
