# Unity XR — VR / AR / MR (Unity 6.x)

Verified June 2026 against Unity package docs + Meta Horizon docs. Confirmed versions: **XRI 3.2.2**, **AR Foundation 6.2.1**, **OpenXR plugin 1.15.1**, **XR Hands 1.5.1**, **PolySpatial 2.4.3**. Unity 6.0 (`6000.0` LTS), 6.1, 6.2. Numbers not doc-confirmed are flagged `[verify]`.

## 1. XR Plugin Architecture

Provider-plugin model via **XR Plugin Management** (`com.unity.xr.management`). Enable providers per build target under **Project Settings → XR Plug-in Management** (separate tabs per platform).

| Provider | Package | Use |
|---|---|---|
| **OpenXR** | `com.unity.xr.openxr` (1.15.1) | Cross-vendor; recommended default for PC VR, Quest, HoloLens 2, Magic Leap 2, SteamVR, Android XR |
| **Meta (OpenXR)** | Unity OpenXR: Meta (2.2) | Meta-specific OpenXR feature group for Quest |
| **ARCore** | `com.unity.xr.arcore` (6.2) | Android AR |
| **ARKit** | `com.unity.xr.arkit` (6.2) | iOS AR |
| **Apple visionOS** | `com.unity.xr.visionos` | Vision Pro |
| **Android XR** | Unity OpenXR: Android XR (1.0) | Google/Samsung Android XR |
| **Windows MR** | — | **Deprecated/EOL** (removed in Win11 24H2, Nov 2024) |

**Legacy XR removed:** the old built-in VR (`UnityEngine.XR` legacy subsystems, `VRSettings`) is fully removed; everything goes through XR Plugin Management + a provider. The standalone Oculus XR Plugin is legacy — Meta now ships features as an OpenXR feature group.

**OpenXR concepts:** providers expose **Features** (toggleable) and **Interaction Profiles** (controller binding sets: Oculus Touch, Valve Index, HTC Vive, Microsoft Motion, Khronos Simple, HP Reverb G2, Hand Interaction, Eye Gaze). Enabling a profile registers the Input System device + bindings.

## 2. XR Interaction Toolkit (XRI) 3.x

`com.unity.xr.interaction.toolkit` 3.2.2. Depends on Input System, Mathematics, uGUI, XR Core Utilities.

**XR Origin** (replaced XR Rig): root hierarchy `XR Origin` → `Camera Offset` → `Main Camera` (`Tracked Pose Driver (Input System)`) + controllers. Tracking origin mode (Floor/Device) on the XR Origin. Add via *GameObject → XR → XR Origin*.

**Interactors (3.x modular interactor + filter model):**
- **Near-Far Interactor** (3.x flagship) — unifies ray + direct; switches far (ray) ↔ near (grab) via interaction casters.
- **Ray Interactor** (distance select/UI/teleport), **Poke Interactor** (press), **Direct Interactor** (grab on overlap), **Gaze Interactor** (dwell).

**Interactables:** **XR Grab Interactable** (rigidbody grab, attach transforms, throw velocity, movement types Instantaneous/Kinematic/VelocityTracking), **XR Simple Interactable**, **Teleportation Area/Anchor**, **Climb Interactable**, **XR Poke Filter**. Gated by **Interaction Layer Masks** + pluggable filters (`IXRSelectFilter`, `IXRHoverFilter`).

**Input Readers (3.x key change):** moved off "action-based vs device-based" toward **Input Readers** — serialized `XRInputValueReader<T>`/`XRInputButtonReader` fields binding to Input System actions or device controls. **XR Input Modality Manager** auto-swaps controllers ↔ tracked hands. **XR Interaction Group** arbitrates which interactor on a hand is active.

**Locomotion (new mediated architecture):** **Locomotion Mediator** (orchestrates Idle→Preparing→Moving), **Locomotion Provider** (base), **XR Body Transformer** (priority queue; `TryQueueTransformation(IXRBodyTransformation)`), **Gravity Provider** (new; sphere-cast ground detection). Providers: Teleportation, Continuous Move/Turn, Snap Turn, Grab Move, Two-Handed Grab Move, Climb.

**UI:** Ray/Poke interactors drive uGUI via **XR UI Input Module** + Tracked Device Graphic Raycaster on world-space canvases.

**Affordance System — DEPRECATED** in 3.x (use Interaction Feedback / Interactable Events + custom feedback).

**Starter Assets:** Package Manager → XRI → Samples → "Starter Assets" (presets, `XRI Default Input Actions`, hand/controller prefabs) + "Hands Interaction Demo". Full examples: GitHub `Unity-Technologies/XR-Interaction-Toolkit-Examples`.

## 3. Input System for XR
Uses the **Input System** package (legacy Input Manager unsupported). Devices: `XRController`, `XRHMD`, eye gaze, hands. Bind in an Input Actions asset (`<XRController>{LeftHand}/triggerPressed`, `/thumbstick`, `/grip`). Tracked pose via **Tracked Pose Driver (Input System)**. OpenXR action maps are auto-generated from enabled interaction profiles.

## 4. Hand Tracking — XR Hands
`com.unity.xr.hands` 1.5.1. **`XRHandSubsystem`** → `XRHand` (per-hand), `XRHandJoint` (26 joints). Update via `updatedHands` + `UpdateSuccessFlags`. **Only the OpenXR plugin provides hand tracking** (OpenXR HandTracking feature); Meta pinch/aim via Meta Aim Hand (`MetaAimHand`). **Gestures sample** ships a **Static Hand Gesture** component + **XR Hand Shape**/**XR Hand Pose** ScriptableObjects (finger curl/flexion/abduction tolerances). Android needs `com.oculus.permission.HAND_TRACKING` manifest entries or the subsystem silently never updates.

## 5. AR Foundation
`com.unity.xr.arfoundation` 6.2.1 over provider subsystems (ARCore/ARKit/visionOS/OpenXR/Meta/Android XR). **Features** (per-platform availability): plane detection, bounding-box detection, point clouds, meshing, image tracking, object tracking (ARKit), face tracking (blendshapes), body tracking (ARKit), anchors (incl. persistent/cloud), raycasting against trackables, environment probes, **light estimation**, **occlusion** (human + environment depth; ARKit LiDAR, ARCore Depth API). Setup: **XR Origin (AR)** + `ARSession` + per-feature managers (`ARPlaneManager`, `ARTrackedImageManager`, `ARAnchorManager`, `ARMeshManager`, `AROcclusionManager`). **XR Simulation** tests plane/image in-Editor without a device.

## 6. Apple Vision Pro / visionOS — PolySpatial
`com.unity.polyspatial` 2.4.3 + `com.unity.polyspatial.visionos` + `com.unity.xr.visionos`. **Requires Unity Pro/Enterprise/Industry.**

**App/build modes:** (1) **Windowed** (2D window in Shared Space); (2) **Bounded volume (MR, RealityKit)** — simulated by Unity, **rendered by RealityKit** via PolySpatial; (3) **Unbounded/Immersive (MR, RealityKit)** — passthrough MR, RealityKit-rendered; (4) **Fully Immersive VR (Metal)** — Unity renders directly with Metal (CompositorServices), bypasses PolySpatial; (5) **Hybrid** — switch Metal ↔ RealityKit.

**Shader/material (RealityKit modes):** standard Unity surface/HLSL shaders **do not run** — you **must use Shader Graph**, which PolySpatial translates to **MaterialX**. Unsupported nodes won't translate (objects render pink/invisible). Supported materials: Lit, Unlit, Custom (Shader Graph→MaterialX). **Limitations:** no custom fullscreen post, transparent sorting quirks, no compute effects, partial particle/VFX support, RealityKit lighting differs, strict perf budget. **visionOS Simulator** has **no hand tracking, no passthrough** — use **Play to Device** + real headset for final validation.

## 7. Meta Quest specifics
Devices: Quest 2, Quest Pro (eye+face), Quest 3, Quest 3S (3/3S/Pro do color passthrough MR + Depth API). **Two SDK paths:** (1) **OpenXR + Unity OpenXR: Meta (2.2)** — recommended, standards-based, works with AR Foundation/XRI/XR Hands; (2) **Meta XR SDK** (`com.meta.xr.sdk.*` All-in-One: Core, Interaction, Audio, Platform) — richer Quest-specific features `[verify v7x line]`. **Building Blocks** — drag-and-drop prefab features via the Project Setup Tool. **Passthrough/MR:** `OVRPassthroughLayer` or AR Foundation camera. **Scene understanding** via Scene API + **MRUK** (room mesh, semantic-labeled anchors: floor/wall/ceiling/table/couch/door/window, Environment Raycasting, Space Sharing for colocated MP). **Depth API** drives dynamic occlusion.

## 8. VR Performance
| Lever | Detail |
|---|---|
| **Single-pass instanced (stereo)** | Default & required for Quest perf — both eyes in one draw via GPU instancing. Render Mode = Single Pass Instanced. Shaders need `UNITY_VERTEX_OUTPUT_STEREO` + `UNITY_SETUP_INSTANCE_ID` or render only to left eye. |
| **Fixed Foveated Rendering (FFR)** | Lower peripheral shading. SRP Foveation API (URP/HDRP, Unity 6+, OpenXR 1.11+): `XRDisplaySubsystem.foveatedRenderingLevel` (0–1). |
| **Eye-tracked FR (ETFR)** | Quest Pro/3 — `FoveatedRenderingFlags.GazeAllowed`; needs eye-tracking feature + permission. |
| **Application SpaceWarp (ASW)** | App renders at half rate; runtime synthesizes frames from motion vectors + depth. Needs motion-vector pass; transparent/animated content can artifact. `[verify URP maturity]` |
| **Refresh rates** | Quest 72/80/90/120 Hz. 90Hz ≈ 11.1ms, 72Hz ≈ 13.9ms budget. |
| **Budgets (mobile VR)** | Rough Quest 2/3: ~50–150 draw calls, ~350k–1M tris/frame `[verify per title]`. SRP Batcher + instancing + aggressive LODs + baked lighting + atlasing. |
| **MSAA** | **4x MSAA** on mobile VR (cheap on tiled GPUs); avoid post-process AA. |
| **Mobile VR constraints** | Tile-based GPU → avoid full-screen post, grab-pass, frequent RT switches, alpha overdraw. Use **Vulkan**. |

## 9. Gotchas / Black Magic
- **Don't mix providers** (OpenXR + legacy Oculus plugin → init conflict).
- **XRI 2→3 input mismatch:** input readers ≠ action-based components; re-import Starter Assets and rebind.
- **PolySpatial = Shader Graph only** in RealityKit modes; hand-written shaders silently fail.
- **visionOS Simulator has no hands/passthrough** — validate MR on real headset.
- **Single-pass stereo + custom shaders:** missing stereo macros → mono/left-eye-only.
- **Hand tracking permission/manifest** missing → `XRHandSubsystem` never updates on Quest.
- **WMR is dead** (Win11 24H2) — migrate to OpenXR/SteamVR.
- **AR Foundation feature gating:** unsupported subsystem returns null, not an error — check the per-platform support table.
- **Tracking origin mode** (Floor vs Device) changes camera Y — common "sunk into floor / floating" bug.

> Notes: package versions doc-confirmed except `[verify]` items (Meta XR SDK/MRUK major version, ASW URP maturity, per-title budgets). Biggest XRI 3.x shifts: Near-Far Interactor, Input Readers, mediated locomotion (Mediator + Body Transformer + Gravity Provider), deprecated Affordance System.
