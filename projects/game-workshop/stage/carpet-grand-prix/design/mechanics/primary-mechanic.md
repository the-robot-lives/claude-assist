# Carpet Grand Prix — Primary Mechanic: The Handset as a Tilting Table

Every system in Carpet Grand Prix derives from a single input: the device's orientation
relative to a **rest pose** captured at the start of each run. There is no steering
stick, no lane-switch button, no drift trigger — tilt is the entire input surface, and it
is deliberately made to do three jobs at once so that the screen stops reading as a
picture of a racetrack and starts reading as an object sitting on the floor in front of
the player.

The game ships as a **native iOS app written in Swift with a custom Metal renderer** —
no game engine and no third-party dependencies. The layered diorama look (carpet, deck,
posts, rails, car, ghost) is built as a hand-rolled Metal render pipeline specifically
because that structure is what keeps the parallax math cheap enough to hold 60 fps (see
the fill-rate discussion in the platform technical docs). A working implementation
already exists at `stage/carpet-grand-prix/app/`.

## The model: one input, three systems

```
                        ┌─► GRAVITY   a = TABLE_G · sin(tilt)      → physics
   tilt (pitch, roll) ──┼─► VIEWPOINT offset = height · sin(tilt)  → parallax
                        └─► CAMERA    subtle lead on the roll axis → framing
```

Nothing in the diorama moves because a "camera" panned. Everything moves because the
table it's sitting on tipped, and the game computes gravity and viewpoint from the exact
same tilt sample every frame. This is the whole trick, and it is why the effect reads as
physical rather than as a screen effect layered on top of a normal racer.

### Inputs

| Signal | Source | Range used |
|---|---|---|
| `pitch` | `DeviceOrientationEvent`-equivalent beta − rest beta | ±32° = full lock |
| `roll` | `DeviceOrientationEvent`-equivalent gamma − rest gamma | ±32° = full lock |
| screen angle | current screen orientation | remaps pitch/roll for landscape holds |

Both channels are low-passed at **α = 0.16 per frame** — enough to kill sensor jitter,
not enough to feel laggy. Measured settling time is **~55 ms to reach 90% of a step
input**, which is fast enough that a snap correction (over-tilt, catch yourself) reads as
instantaneous.

### Output 1 — Gravity

The handset *is* the table the track is bolted to. Accelerations `ax = G·sin(roll)`,
`ay = G·sin(pitch)` are applied in world space, un-rotated by the camera — tilting right
always pulls the car right on screen, regardless of viewpoint. Track grade contributes a
further `a = SLOPE_G · dz/ds` along the tangent of the course. At full pitch on a 20%
grade, the car pulls **~430 u/s², terminal ~318 u/s** (≈133 mph at toy scale) — the number
every other tuning constant in `secondary-mechanics.md` is calibrated against.

### Output 2 — Viewpoint

Everything in the diorama renders at a height above the carpet plane: the floor sits at
`h=0`, the track deck floats at `h≈74`, the rails extrude a further `27`, and the car
itself sits at `h≈83`. Screen position is `p + h · sin(viewAngle)`, where `viewAngle` is
the current tilt plus a fixed **0.46 baseline**. Tip the phone and the deck slides
bodily across the rendered carpet texture, the support posts splay apart, and the rails
lean — this is the entire "3D" effect. There is no 3D geometry and no perspective matrix
anywhere in the renderer, only correct positional parallax across a set of flat, layered
sprites at fixed heights.

### Output 3 — Grade legibility

Deck height is drawn *relative to the car's own elevation* —
`h = BASE + (z − z_camera) · 0.5` — so the track ahead of the car visibly sinks toward
the carpet on a descent and rises on a crest, before the car physically reaches that
point. This is the mechanism behind the "read the grade" step in the core loop: a player
reads upcoming gradient by how far off the floor the track is drawn, exactly the way a
kid reads a real toy track by eye.

## Constraints and edge cases

| Case | Handling | Why it matters |
|---|---|---|
| **Flat hold** — player lies down or holds the phone flat on a table | Rest pose is captured relative to whatever position the phone is in at calibration, so any comfortable pose becomes "neutral" | Removes the single biggest accessibility and comfort barrier to a tilt game — you never have to hold the phone a specific way |
| **Mid-run rotation** — player rolls over in bed or shifts posture | A single tap on the playfield re-centres rest pose without pausing the run | Keeps a mistake of *posture* from becoming a mistake of *score* |
| **Landscape hold** | Pitch/roll axes are swapped by the current screen orientation angle before being fed to the physics | Controls must never invert unexpectedly, which is an explicit user story (US-012 in the source GDD) |
| **Sensor unavailable / permission denied** | Falls back to touch-drag and arrow-key input; the run still counts but is flagged in the stored ghost data | A denied permission must never hard-block play, only degrade it honestly |
| **Passenger in a moving vehicle** | "Vehicle Mode" removes low-frequency drift with a 4-second rolling rest-pose average | The single biggest real-world complaint a tilt game gets — motion noise from the vehicle itself — solved with a filter, not a warning label |
| **Sustained full lock / arm fatigue** | Tilt response is normalised at ±32° full-lock, so a tired, lazy ±18° grip still reaches ~55% control authority | Session length is capped by arm fatigue on purpose (see `core-loop.md`); the response curve is tuned so fatigue degrades performance gracefully instead of cutting control off a cliff |

## Skill ceiling

The tilt system has a genuine, three-layer skill ceiling built entirely out of one input
axis pair — no secondary systems are needed to keep it deep:

1. **Hold it steady.** New players over-tilt and ping-pong between the rails.
2. **Ease off early.** Grip is finite under load; the fast line brakes *with* the tilt
   before the apex rather than at it.
3. **Read the height.** Experts pre-load tilt for a grade change they can see in the
   parallax roughly two seconds before the car physically reaches it — a skill that is
   only possible because Output 2 and Output 3 above are driven by the same tilt signal
   as Output 1, so the visual language of the diorama and the physics of the car are
   never lying to each other.

This is why the tilt-diorama look is treated as the marketing asset ahead of the racing
itself in `monetization/revenue-model.md` — the parallax effect *is* the mechanic, not a
skin on top of it.
