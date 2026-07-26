# Carpet Grand Prix — Tech Stack

## Design Philosophy

**No engine.** The whole game is one mechanic — tilt drives gravity and viewpoint
simultaneously — rendered as a layered 2D diorama with a height field. Unity or
Godot would contribute an asset pipeline we do not need, a physics engine we
would have to fight (the car is 40 lines of vector maths, not a rigid body), a
scene graph for a scene that is one static mesh, and 60 MB of runtime for a game
whose entire content is procedurally generated. It would also put a layer
between us and `CMDeviceMotion`, which is the single most latency-sensitive
input path in the product.

Native Swift with a hand-written Metal renderer costs more up front in graphics
engineering and buys three things that matter here:

1. **Direct sensor access.** Gravity vector to physics to pixels with nothing in
   between. Frame-accurate control over how sensor samples map to ticks.
2. **A renderer shaped like the game.** The parallax *is* the vertex shader.
   There is no perspective matrix, no 3D geometry, no depth buffer, no culling
   pass. Eight draws per frame over a static mesh.
3. **A simulation core with no dependencies.** `Game/` imports Foundation and
   simd and nothing else, so the physics is directly unit-testable and ghost
   determinism is provable rather than hoped for.

The cost is honest: we own everything, including the parts an engine would have
given us free. That trade only makes sense because the surface area is small.

---

## Platform Stack

| Layer | Choice | Notes |
|---|---|---|
| Language | Swift 5.9 | Strict concurrency enabled |
| UI shell | SwiftUI | Menus, HUD, settings, results |
| Rendering | Metal 3 + MSL | `MTKView`, one render pass, no depth attachment |
| Input | CoreMotion `CMDeviceMotion.gravity` | Not Euler angles — see below |
| Persistence | `UserDefaults` + JSON files | Best times, medals, ghost recordings |
| Textures | Core Graphics at load time | Zero binary image assets shipped |
| Audio | AVAudioEngine | Not yet implemented |
| Project generation | XcodeGen (`project.yml`) | `.xcodeproj` is a build artefact, gitignored |
| Testing | XCTest | Physics, track generation, medals, ghosts |
| Minimum OS | iOS 16.0 | |
| Dependencies | **None** | No SPM packages, no CocoaPods, no Carthage |

---

## Component Specifications

### 1. Simulation core — `Game/`

Pure Swift. Imports only `Foundation` and `simd`. Knows nothing about Metal,
CoreMotion, SwiftUI or the clock.

| File | Owns |
|---|---|
| `Tuning.swift` | Every gameplay constant, in one place |
| `Course.swift` | Course definitions, deterministic track generation, track queries |
| `Car.swift` | The eight handling classes |
| `Physics.swift` | `CarState` and the fixed-step integrator |
| `GameSession.swift` | Run lifecycle, clock, camera, event dispatch |

**Track generation** is a seeded `mulberry32` walk, so a course is reproducible
from a 32-bit seed and layout is never persisted. The generator enforces two
invariants that the control scheme depends on, both covered by tests:

- Heading stays within ~54° of +Y, so the course never doubles back up the
  screen. This is what makes "tip the phone away from you" reliably mean "go
  faster."
- Elevation decreases monotonically. Every course is a descent.

**Physics** runs at a fixed 120 Hz accumulator decoupled from display rate, so a
time set on a 60 Hz iPhone is directly comparable to one set on a ProMotion
device. The model:

```
a  = tableGravity · sin(tilt · fullLock) · carMass      // the handset as a table
   + tangent · (grade · slopeGravity)                   // the track's own pitch
   + tangent · boost
v  = (v + a·dt) · (1 − (dragLinear + dragQuad·|v|)·dt)
v  = tangent·(v·tangent) + normal·(v·normal)·e^(−grip·dt)   // tyres bite
```

### 2. Input — `Input/MotionController.swift`

Reads `CMDeviceMotion.gravity` at 120 Hz under the `.xArbitraryZVertical`
reference frame.

**Why gravity rather than pitch/roll.** Gravity is exactly the quantity the
fiction needs — "which way is down, relative to the phone." Euler angles would
add gimbal degeneracy near vertical, a ±180° wrap discontinuity, and an
axis-remapping table for device rotation, in exchange for nothing. The gravity
vector's in-plane components *are* the table tilt:

```
tilt.x =  (g.x − rest.x) / sin(fullLockDegrees)     // device +X = screen right
tilt.y = −(g.y − rest.y) / sin(fullLockDegrees)     // device +Y = screen up
```

The rest pose is captured per run and re-capturable with a tap mid-run, so any
comfortable grip works. Vehicle Mode re-estimates it from a 4-second rolling
average so a train's motion does not read as steering. `fullLockDegrees` is
driven by the accessibility slider (12°–45°), which is why it divides into the
normalisation rather than being baked into `Tuning`.

Low-pass at α = 0.16 per tick: ~55 ms to 90% of a step input. Enough to kill
sensor jitter, not enough to feel laggy.

### 3. Renderer — `Render/`

One render pass, eight draws, zero per-frame geometry work.

| File | Owns |
|---|---|
| `ShaderTypes.h` | CPU/GPU shared structs, included from both Swift and MSL |
| `Shaders.metal` | Five shader pairs: diorama, boost, carpet, sprite, shadow |
| `DioramaBuilder.swift` | Builds the static track mesh once per course |
| `TextureFactory.swift` | Procedural carpet and car textures via Core Graphics |
| `Renderer.swift` | `MTKViewDelegate`, uniforms, draw submission |
| `MetalView.swift` | `UIViewRepresentable` wrapper, touch fallback |

**The parallax is the vertex shader.** Every vertex carries its height above the
carpet. `diorama_vertex` computes:

```metal
deck   = clamp(baseHeight + (elevation − cameraElevation) · gradeRead, 8, 210);
height = floorPinned ? 0 : deck + heightOffset;
screen = (position − cameraXY) · scale + centre + height · scale · viewVector;
```

`viewVector` is derived from the tilt. Tilting the handset displaces every
raised surface in proportion to its height: the deck slides across the carpet,
the support posts splay (their feet are floor-pinned, their heads are not), and
the rails lean. That is the entire 3D effect. No perspective matrix, no depth
attachment, no 3D geometry anywhere in the app.

Deck height is computed *relative to the camera's elevation*, which is what
makes gradient readable — track ahead of you is lower and sinks toward the
floor; track behind you rises.

**Static mesh.** A course is a few hundred samples, uploaded once at load into
eight `shared` buffers (shadow, posts, underside, deck, dashes, boost, left
rail, right rail). Each emits exactly six vertices per segment; absent features
emit a degenerate zero-area quad rather than being skipped, so the stride stays
uniform and the per-frame visible range is a single multiply. Per frame we
update one uniform struct and issue eight `drawPrimitives` calls over a
contiguous vertex range.

Uniforms and sprite instances are triple-buffered behind a `DispatchSemaphore`.

**Textures** are generated at load time in Core Graphics — seeded noise for the
carpet, primitives for the car — so the app ships no binary image assets. A new
room palette or car livery is a few lines of code, not an art round-trip.

### 4. Persistence — `Support/Persistence.swift`

`UserDefaults` for best times, medals and settings; JSON files in Application
Support for ghost recordings. No account, no server, no network, no analytics
SDK. A time set on a train with no signal counts exactly the same as one set at
home.

**Ghosts store sampled position, not input.** Replaying input would mean any
future change to a tuning constant silently invalidates every stored time.
Storing position at 40 Hz means the ghost always draws the line that was
actually driven. Raw tilt is recorded alongside it for display only — which is
the feature the completionist persona (P-008) will want when analysing a lost
tenth.

---

## Device Targets

| Platform | Minimum | Recommended | Frame rate |
|---|---|---|---|
| iOS | iPhone 11, iOS 16 | iPhone 13 or newer | 60 fps locked; 120 on ProMotion |
| iPadOS | iPad 9th gen | iPad Air M1 | 60 fps, portrait, letterboxed |
| Android (M18+) | Snapdragon 730G, Android 12, gyro required | Snapdragon 8 Gen 1+ | 60 fps |

Install size ≤ 220 MB (currently far below — there are no assets). Memory
ceiling 380 MB. `UIRequiredDeviceCapabilities` lists `gyroscope` and `metal`, so
devices that cannot play the game are never offered it.

---

## Android Port

The Android build is a **rewrite of the platform layers, not a port of the
engine** — there is no shared runtime.

| Layer | Reuse |
|---|---|
| Simulation core | Rewritten in Kotlin, line-for-line from `Game/`. Same constants, same tests. |
| Renderer | Vulkan; the vertex-shader parallax translates directly to GLSL |
| Input | `SensorManager` `TYPE_GRAVITY`, same normalisation |
| Shell | Jetpack Compose |

Android ships six months after iOS specifically to build the per-device sensor
profile table. Gyro fusion quality, sample rate and axis convention vary
enormously by OEM, and some vendors report at 20 Hz. The profile table is
shipped as data and updatable without a client release.

---

## Development Environment

```bash
brew install xcodegen
cd app && make generate && make build && make test
```

Requires Xcode 26+ with the Metal Toolchain component installed
(`xcodebuild -downloadComponent MetalToolchain`) — Xcode 26 moved the MSL
compiler out of the base install.

The Simulator has no gyroscope and falls back to drag-to-steer. It is enough to
verify the game runs; every tuning judgement has to be made on a device.

---

## Technology Decision Log

| # | Decision | Alternatives considered | Rationale |
|---|---|---|---|
| 1 | No engine; Swift + Metal | Unity 6, Godot 4, SpriteKit | One mechanic, no asset pipeline, needs direct sensor access and a bespoke renderer. Engine overhead buys nothing here. |
| 2 | Gravity vector, not Euler angles | `attitude.pitch/roll`, raw accelerometer | No gimbal degeneracy, no wrap discontinuity, no axis remapping. It is literally the quantity we want. |
| 3 | Parallax in the vertex shader | CPU transform per frame; real 3D with a perspective camera | Static mesh means zero per-frame geometry work. Real 3D would need art we do not have and would break the diorama read. |
| 4 | Fixed 120 Hz physics | Variable timestep tied to display | Ghost and leaderboard comparability across 60 and 120 Hz devices. |
| 5 | Ghosts store position | Store input and re-simulate | Re-simulation makes every stored time hostage to the next tuning change. |
| 6 | Procedural textures | Shipped PNG atlases | Zero asset pipeline, trivial re-theming, tiny binary. |
| 7 | XcodeGen | Checked-in `.xcodeproj` | `project.pbxproj` is a merge-conflict generator on a team of more than one. |
| 8 | No dependencies | SPM packages for maths/audio | Nothing we need is hard enough to justify a supply-chain surface. |
| 9 | Local-only persistence | CloudKit sync, Game Center leaderboards | Offline-first is a requirement for the commuter persona. Game Center is a candidate for a post-launch update, not launch. |
| 10 | Portrait lock | Support landscape | One-handed play is a pillar. Landscape would also require the axis remapping decision 2 exists to avoid. |

---

## Current Implementation Status

| Component | State |
|---|---|
| Track generation, physics, medals, ghosts | Implemented, unit-tested |
| Metal renderer, parallax, diorama mesh | Implemented, **never executed** |
| CoreMotion input, rest pose, Vehicle Mode | Implemented, **never run on device** |
| SwiftUI shell, HUD, settings | Implemented |
| Audio, rooms 2–7, story vignettes, Audio Course Mode | Not started |

`swiftc -typecheck` passes against the iOS 16 simulator SDK on Xcode 26.4.1.
`Shaders.metal` has **not** been compiled — the Metal Toolchain component is not
installed on the development machine. The renderer is unproven until it has
drawn a frame on hardware.
