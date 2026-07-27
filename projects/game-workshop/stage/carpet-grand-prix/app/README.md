# Carpet Grand Prix — iOS app

Native Swift + Metal. No engine, no third-party dependencies, no binary assets.

```
make generate     # xcodegen generate  (needs: brew install xcodegen)
make build        # build for the simulator
make test         # run the physics/track unit tests
make devices      # list simulator destinations
```

The `.xcodeproj` is generated from `project.yml` and gitignored — a checked-in
`project.pbxproj` is a merge-conflict generator on a team of more than one.

> **The Simulator has no gyroscope.** It falls back to drag-to-steer, which is
> enough to check that the game runs but tells you nothing about how it feels.
> Every tuning judgement has to be made on a physical device.

---

## Layout

```
CarpetGrandPrix/
├── App/          SwiftUI shell — menu, HUD, results, settings
├── Game/         Pure simulation: tuning, courses, tracks, cars, physics
├── Input/        CoreMotion → a single normalised tilt vector
├── Render/       Metal: shaders, mesh builder, textures, renderer
└── Support/      Best times, medals, ghost recordings
Tests/            Physics and track-generation tests
```

`Game/` imports only Foundation and simd. It has no idea Metal or CoreMotion
exist, which is why the physics is directly unit-testable.

---

## How the parallax works

The floor is at height 0. The track deck floats ~74 world units above it on
visible support posts; rails extrude another 27; the car sits on top of that.
Every vertex carries its height, and `diorama_vertex` displaces it:

```
deck   = baseHeight + (elevation − cameraElevation) × gradeRead
height = floorPinned ? 0 : deck + heightOffset
screen = (position − camera) × scale + centre + height × scale × viewVector
```

`viewVector` comes from the handset's gravity vector. Tilt the phone and every
raised surface slides across the carpet in proportion to how far off the floor
it sits — the deck shifts, the posts splay, the rails lean. There is no
perspective matrix and no 3D geometry anywhere in the app.

Two consequences worth knowing:

- **Height encodes gradient.** Deck height is measured *relative to the camera's
  elevation*, so track ahead of you (lower) sinks toward the carpet and track
  behind you rises. You read the gradient by looking at how far off the floor
  the track is, exactly as you would with a real plastic track.
- **The mesh is static.** The whole course is a few hundred samples, uploaded
  once when the course loads. Per frame we update one uniform struct and issue
  eight draws over a contiguous vertex range. There is no per-frame geometry
  work and no culling pass — absent features (a missing rail, a segment with no
  support post) are emitted as degenerate quads to keep the stride uniform, so
  the visible slice is a single multiply.

---

## How the input works

`MotionController` reads `CMDeviceMotion.gravity` rather than Euler angles.
Gravity is precisely the quantity the fiction needs — "which way is down,
relative to the phone" — and it has no gimbal degeneracy, no ±180° wrap, and no
axis-remapping when the device rotates.

The rest pose is captured at the start of each run and is re-capturable with a
tap mid-run, so any comfortable grip works. Vehicle Mode re-estimates it from a
4-second rolling average, so a train's motion does not read as steering.

Tilt then drives three things from one signal: gravity in the physics, the
parallax view vector, and the on-screen bubble level.

---

## Simulation

Fixed 120 Hz accumulator, decoupled from display rate, so a time set on a 60 Hz
iPhone is comparable to one set on a ProMotion device. Ghosts store sampled
*position* rather than input, so changing a tuning constant never silently
invalidates a stored time — the ghost still draws the line that was driven. Raw
tilt is recorded alongside it for display only.

---

## Status

| Piece | State |
|---|---|
| Track generation, physics, medals, ghosts | Implemented, unit-tested |
| Metal renderer, parallax, diorama mesh | Implemented, compiles — **never executed** |
| CoreMotion input, rest pose, Vehicle Mode | Implemented — **never run on device** |
| SwiftUI shell, HUD, settings | Implemented |
| Audio | Not started |
| Rooms 2–7, cars beyond the first 8, story vignettes | Not started |

### Verified (2026-07-27, Xcode 26.4.1)

- `xcodegen generate` produces a valid project
- `Shaders.metal` compiles clean — **zero errors, zero warnings**
- `xcodebuild build -destination 'generic/platform=iOS Simulator'` →
  **BUILD SUCCEEDED**, zero errors, zero real warnings

Prerequisites, both of which had to be installed:

```
xcodebuild -downloadComponent MetalToolchain   # Xcode 26 split out the MSL compiler
xcodebuild -downloadPlatform iOS               # ~8.5 GB
brew install xcodegen
```

### Not verified

**The app has never rendered a frame.** Compiling and linking is not the same
as working: the parallax could still be mis-scaled, inverted, or invisible, and
none of the tuning constants have been felt by a human.

- No simulator runtime is currently installed (see note below), so nothing has
  been launched.
- Device install requires an Apple ID signed into Xcode — there is no signing
  identity on this machine. See "Running on a device".
- The test target has never been built or run.

## Running on a device

The Simulator has no gyroscope, so it can only ever prove the renderer works,
never how the game feels. Every tuning judgement has to happen on hardware.

1. **Xcode → Settings → Accounts → +** → Apple ID. A free account is enough.
2. **On the iPhone:** Settings → Privacy & Security → Developer Mode → on,
   then restart the phone.
3. `open CarpetGrandPrix.xcodeproj` → target **CarpetGrandPrix** → *Signing &
   Capabilities* → tick *Automatically manage signing* → pick your team. If
   `com.noizu.carpetgrandprix` is taken, change the bundle identifier.
4. Select your device as the destination and press ⌘R.
5. First launch only: iPhone Settings → General → VPN & Device Management →
   trust the developer certificate.

Apps signed with a free personal team expire after 7 days and need reinstalling.

Once signed in, the whole thing works headlessly:

```
xcodebuild build -project CarpetGrandPrix.xcodeproj -scheme CarpetGrandPrix \
  -destination 'id=<device-udid>' -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=<your-team-id>
```

Add `DEVELOPMENT_TEAM` to `project.yml` to make that permanent.
