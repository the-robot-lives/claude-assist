# Unity 6.4 → 6.5 Delta (from the 6.3 LTS baseline)

> What changed in **Unity 6.4 (`6000.4`)** and **Unity 6.5 (`6000.5`)** relative to the
> [Unity 6.3 LTS baseline](unity-6.3-baseline.md). The team's editor is now **`6000.5.1f1`**
> (installed Jun 2026), so this doc records the deltas — and the breaking changes — that the 6.3
> baseline did not cover. Read it **with** the 6.3 doc, which still holds for everything not
> contradicted here.
>
> **Reading rule (unchanged from the baseline):** every claim is sourced to a primary Unity page
> (`docs.unity3d.com` Manual *What's new* / *Upgrade guide* pages, package CHANGELOGs,
> `discussions.unity.com`, `endoflife.date/unity`). Items not confirmed from a fetched primary
> page are marked **`⚠ UNVERIFIED`** and must be validated in a live editor before we rely on
> them — they are **not** filled from memory. `unity.com/blog` and `unity.com/releases` continue
> to block automated fetching; affected items are sourced from docs pages instead.

See also: [unity-6.3-baseline.md](unity-6.3-baseline.md) · [rendering-and-vr.md](rendering-and-vr.md) · [ADR-001](../adrs/ADR-001-unity-dots-rendering.md)

---

## 0. TL;DR — the decisions this forces

1. **6.4 and 6.5 are *"Supported" (Tech Stream) releases, NOT LTS. 6.3 is the LTS.** Unity's own
   term is "Supported release": it gets the same bug-fix / critical-platform support as an LTS, but
   **only until the next release ships** (~3 months). So 6.4's support **already ended** (17 Jun 2026,
   when 6.5 shipped) and 6.5's will end when 6.6 ships. 6.3 (LTS) has security support to **04 Dec
   2027** (extended Dec 2028). The next LTS after 6.3 is **6.7** — referenced as "Unity 6.7 LTS" in
   the 6.5 Built-in-RP deprecation note (planned; exact date ⚠ unverified).
   → **Decision point:** developing on `6000.5.1f1` is fine for velocity, but **shipping** builds
   should target an LTS — either pin **6.3 LTS** for release branches, or plan to jump to **6.7
   LTS** when it lands. Don't ship a product on 6.5. *Source: endoflife.date/unity.*
2. **The ECS deprecations the 6.3 doc told us to avoid are now *removed* (hard compile errors) in
   6.5:** `Entities.ForEach`, `IAspect`, `Job.WithCode`. Our renderer must use `IJobEntity` +
   `SystemAPI.Query` + `IJob` from day one (ADR-001 already pointed this way — now it's mandatory).
3. **URP Compatibility Mode is permanently gone (6.4) and the *legacy* Render Graph API is removed
   (6.5).** All custom passes = Render Graph + `AddRenderPasses`, no exceptions. (Already our plan.)
4. **`EntityId` (8-byte) replaces `InstanceID`; storing IDs as `int` breaks.** Audit any
   serialization/interop that assumed 4-byte int instance IDs. *(6.4 introduced, 6.5 made it an error.)*
5. **Built-in DOTS:** Entities / Entities Graphics / Collections / Mathematics are now **core
   packages renumbered to the editor** (6.4.0 / 6.5.0); `Unity.Mathematics` is a **built-in module**
   in 6.5. No more manual `1.4.x` package pins — the baseline's §4 version table is superseded.
6. **Our "Coming Soon" stub still runs on 6.5.** It uses the Built-in Render Pipeline + uGUI; both
   are **deprecated but still supported through 6.7 LTS** (see §2, §5). The production shell is URP
   anyway, so this only affects the throwaway splash.

---

## 1. Release facts & support

| Version | Type | Released | Security support | LTS? |
|---------|------|----------|------------------|------|
| **6.3** | **LTS** | 04 Dec 2025 | **to 04 Dec 2027** (ext. Dec 2028) | **Yes — our release target** |
| 6.4 | Supported (Tech Stream) | **17 Mar 2026** | **ended 17 Jun 2026** | No |
| 6.5 | Supported (Tech Stream) | **15 Jun 2026** | active until 6.6 ships | No |

- **Dates VERIFIED** from Unity's announcement posts: 6.4 = **Mar 17, 2026**
  (`discussions.unity.com/t/unity-6-4-is-now-available/1713245`, which now banners "reached end of
  life — upgrade to 6.5"); 6.5 = **Jun 15, 2026** (`.../unity-6-5-is-now-available/1723176`).
  `endoflife.date/unity` lists 18 Mar / 15 Jun (±1 day). *(The `com.unity.entities` 6.4.0 changelog's
  `2025-10-16` is the package **tag** date, not the editor GA — not a conflict.)*
- A **"Supported release"** = LTS-level support, but only until the next release publishes. *Source:
  endoflife.date/unity; Unity Discussions 6.4 & 6.5 "is now available" posts.*

---

## 2. Graphics / rendering (URP + Render Graph)

| Change | Ver | Note for us | Source |
|--------|-----|-------------|--------|
| **URP Compatibility Mode fully removed** — `URP_COMPATIBILITY_MODE` define gone; dependent methods are now hard `Obsolete(true)` compile errors | 6.4 | All custom `ScriptableRenderPass` must be Render Graph. Confirms baseline §3. | UpgradeGuideUnity64 |
| **Legacy Render Graph API removed** — use native render pass support | 6.5 | Use current `RenderGraphModule` API only | UpgradeGuideUnity65 |
| **Built-In Render Pipeline deprecated** (supported through **6.7 LTS**, obsolete later) | 6.5 | Our stub uses BiRP → fine for now; real app is URP | WhatsNewUnity65 / UpgradeGuideUnity65 |
| **Dynamic Batching deprecated** (removal later) | 6.5 | We're GPU-driven/BRG — not affected | WhatsNewUnity65 |
| **On-Tile Post-Processing on *all* platforms** + "Tile-Only Mode" validation | 6.5 | Direct win for Quest tile GPUs — tone-map/grade/vignette in one tile pass | WhatsNewUnity65 |
| **Meta Quest shader optimizations** (GPU time, instruction count, bandwidth, occupancy) + new **`UNITY_PLATFORM_META_QUEST`** shader macro | 6.5 | Review custom indirect/bubble shaders for Quest-specific branches | WhatsNewUnity65 |
| **Mesh LOD now compatible with Entities Graphics** | 6.5 | Relevant to our HLOD/LOD plan on the ECS render path | WhatsNewUnity65 |
| **Rendering Statistics window renovated** (SRP Batcher, GPU Resident Drawer, BRG, instancing counts, accurate frame time) | 6.4 | Better triage for our draw-call budget | WhatsNewUnity64 |
| **PSO tracing additions** — `GraphicsStateCollection` edit-without-retrace, generate from Mesh/Material arrays, WebGPU support (6.4); codeless `traceCacheMisses`, `VariantsUploadedToGpuLastFrame` (6.5) | 6.4–6.5 | Useful to kill first-use shader hitches in VR | WhatsNewUnity64 / 65 |
| **DirectStorage** — Windows Standalone fast asset load (6.4); `AsyncReadManager` DirectStorage + Player setting (6.5) | 6.4–6.5 | Faster load of large model/mesh/entities data | WhatsNewUnity64 / 65 |
| **PVRTC texture format removed** → ASTC/ETC | 6.4 | N/A (we target Vulkan/ASTC on Quest) | WhatsNewUnity64 |
| **`IVolume` interface removed**; `LightShadowCasterMode` enum members renamed | 6.4 | Minor API migration if referenced | UpgradeGuideUnity64 |
| **OptiX denoiser deprecated** (removed 6.7) → OIDN | 6.5 | Only affects baked lighting tooling | WhatsNewUnity65 |

**URP ≈ `17.2.x` in the 6.4 era (changelog fetched):** the URP `17.2` changelog shows **refinements,
not redesigns** of our load-bearing features — **APV Disk Streaming enabled in URP**; STP fixes (TAA
frame-index mismatch on history reset; shader-stripping so non-Windows→Windows builds don't fail);
**foveated rendering enabled for the UberPost pass when it's last**; LOD-crossfade fix under
BatchRendererGroup. The **GPU Resident Drawer / GPU Occlusion Culling docs restate the baseline §3
requirements verbatim** (Forward+/Deferred+, compute-only, excludes OpenGL ES + visionOS; GRD is a
prerequisite for GPU occlusion). **VRS / Shading Rate API is a 6.1 feature, not re-surfaced as new in
6.4/6.5.** → **Baseline §3 stands.** *Source: com.unity.render-pipelines.universal@17.2 CHANGELOG;
/6000.4/urp/gpu-resident-drawer.html & gpu-culling.html.* **⚠** exact URP version on `6000.5.x` (17.3?
18.x?) unconfirmed.

---

## 3. DOTS / ECS — biggest breaking surface

The 6.3 baseline (§4) predicted the 6.4 core-package renumber. **It happened.** And the obsolete
APIs it warned against are now **gone**.

### Core-package renumber (supersedes baseline §4 version table)
- `com.unity.entities` → **6.4.0** (core, editor-embedded; changelog dated 2025-10-16); **6.5.0** present.
- `com.unity.entities.graphics` → **6.4.0** / **6.5.0** (core).
- **Entities / Collections / Mathematics / Entities Graphics ship as core packages** with the editor.
- **`Unity.Mathematics` is a built-in *module* in 6.5** (no package install; adds implicit conversions
  between `UnityEngine` and `Unity.Mathematics` types).
- `com.unity.collections` → **6.4.0** (core, "embedded in Unity", changelog fetched). `com.unity.mathematics`
  is named by the 6.4 manual as one of the four renumbered core packages, but **⚠ its own changelog is
  stale on the public mirror (tops at 1.3.2) — the 6.4.x version is asserted by the manual, not confirmed
  from the mathematics changelog.**
- *Source: com.unity.entities@6.4 / @6.5 CHANGELOG; com.unity.entities.graphics@6.4 / @6.5 CHANGELOG;
  WhatsNewUnity64; WhatsNewUnity65.*

### Removed in 6.5 (hard breaks — mandatory migration)
| Removed | Migrate to | Source |
|---------|-----------|--------|
| `Entities.ForEach` | `IJobEntity` + `SystemAPI.Query` | UpgradeGuideUnity65 |
| `IAspect` | Component / `EntityQuery` APIs directly | UpgradeGuideUnity65 |
| `Job.WithCode` | `IJob` | UpgradeGuideUnity65 |

### `EntityId` replaces the engine-wide `InstanceID`
**⚠ Naming trap:** despite the name, this is the **`UnityEngine.Object` instance identifier** (the
value from `Object.GetInstanceID()`) — **not** the ECS `Entity` struct. Don't conflate them.
- **6.4:** `EntityId` introduced; the `InstanceID` property/APIs deprecated; `EntityId`
  **cannot cast to/from `int`**.
- **6.5:** all `InstanceID` APIs are **compile errors**; `EntityId` is **8 bytes** (was a 4-byte
  `int`). Any code persisting/serializing object instance IDs as `int` must migrate. *Source:
  WhatsNewUnity64; UpgradeGuideUnity65.*

### ECS Editor / tooling (6.5)
- Systems window gets a dedicated query/dependency panel + namespace-filtered search; System Groups
  expand by default. New **Hierarchy window** can show entities / entity worlds / subscenes
  (opt-in preference). **Orange Data Mode picker, Components window, Archetype window removed.**
  **Entities Journaling deprecated.** *Source: WhatsNewUnity65.*

**⚠ UNVERIFIED:** GPU Resident Drawer ↔ Entities Graphics interop is *unchanged* as far as the brief
6.4/6.5 changelog entries show — i.e. the baseline's "they don't interact; build our own Hi-Z
occlusion" conclusion still stands until a detailed changelog says otherwise.

---

## 4. XR / VR

- **OpenXR plugin (`com.unity.xr.openxr`):** **1.15.x** landed in the 6.4 window, **1.16.x**
  (1.16.0 = 2025-10-15, 1.16.1 = 2025-11-21) with 6.4 GA, and **1.17.0 = 2026-04-09** is current in the
  6.5 era. **1.17.0 changes the default Foveated Rendering Method to the SRP API** (exactly the path
  the baseline §5 told us to use) and fixes a Mono-API deprecation for **Unity 6000.5+**. It's
  independently versioned, so **⚠ the exact bundled-by-default version for `6000.4.x`/`6000.5.x` is
  still UNVERIFIED** — confirm in Package Manager. *Source: com.unity.xr.openxr@1.17 / @1.16 / @1.15 CHANGELOG.*
- **New OpenXR features across 1.15–1.16 relevant to our 90 fps target:**
  - Application SpaceWarp **URP** settings + component (1.15.0)
  - **Multiview Render Regions "All Passes"** mode (1.15.0-pre.2) — extends the optimization beyond the final pass (Vulkan + Single-Pass-Instanced, Symmetric Projection)
  - **Latency Optimization** setting + "Use OpenXR Predicted Time" (1.15.0)
  - **Automatic Viewport Dynamic Resolution** (1.16.0-pre.1) — directly serves the frame-rate target
  - **Subsampled Layout on Vulkan** with runtime control (1.16.0-pre.1); **MSAA for Windows+Vulkan** (1.16.0-pre.1)
  - Eye-tracked foveation **sleep/wake crash fixed** (1.16.1); `XrResult` → `OpenXRResultStatus` API rename (1.16.0, pre-release APIs)
  - *Source: com.unity.xr.openxr@1.15 / @1.16 CHANGELOG.*
- **VR Module completely removed (6.5)** — the legacy built-in `UnityEngine.XR` VR module; use the XR
  packages/templates (OpenXR). *Source: UpgradeGuideUnity65.*
- **HoloLens 2 platform/plug-in deprecated (6.4)** → OpenXR; **HoloLens Microsoft Hand Interaction
  Profile deprecated** (OpenXR 1.16.0-pre.2). Not a target for us. *Source: UpgradeGuideUnity64; OpenXR@1.16.*
- **Android XR (`com.unity.xr.androidxr-openxr`):** Multiview Render Regions "All Passes", Bounding
  Box subsystem, 16 KB page size (Android 15+) in 1.1.0-pre.1; foveation **gracefully degrades when
  eye-tracking is unavailable** (1.2.0, avoids Play Store filtering). *Source: androidxr-openxr@1.2 CHANGELOG.*
- **Meta OpenXR (`com.unity.xr.meta-openxr`)** 2.3→2.5 (AR/MR: GPU camera image capture, plane provider
  selection, AR Foundation 6.5 dependency). *Source: meta-openxr@2.5 CHANGELOG.*
- **XR Interaction Toolkit (XRI):** current is **3.5.1 (2026-06-02)** (with a 3.3.x maintenance line at
  3.3.2); **minimum editor raised to 6000.0 LTS**. Recent adds relevant to us: UI Toolkit **world-space**
  support for the XR Ray Interactor + Near-Far Interactor (hover/scroll/poke), Android XR hand-visualizer
  prefabs. *Source: com.unity.xr.interaction.toolkit@3.5 / @3.3 CHANGELOG.*
- **visionOS / PolySpatial:** current GA is the **2.x line (`com.unity.polyspatial.visionos` 2.4.3,
  2025-09-29)** — bug-fix/perf focused; requires Unity Pro/Enterprise/Industry. *(My earlier draft's
  "3.1.0" was a bad secondary source — corrected.)* Not a target platform for us yet.

---

## 5. Scripting / runtime

- **C# version / .NET profile: unchanged from 6.3 as far as the fetched pages show** — Mono + IL2CPP
  backends, .NET Standard 2.1. **⚠ The exact C# language version on 6.5 (still C# 9?) is UNVERIFIED** —
  confirm in the 6.5 scripting docs. Treat baseline §6 (C# 9.0) as current-until-disproven.
- **CoreCLR is still NOT in 6.4/6.5.** 6.5 adds **Lifecycle Management API** groundwork
  (`OnCodeLoadedAttribute`, `OnCodeDeinitializingAttribute`, `AutoStaticsCleanup`, …) for the eventual
  CoreCLR transition. Timeline unchanged: experimental **CoreCLR Desktop Player in 6.7**, **Mono removal
  + .NET 10 / C# 14 in 6.8**. *Source: WhatsNewUnity65; discussions.unity.com "Path to CoreCLR (2026)".*
- **Fast Enter Play Mode is still opt-in** in 6.4/6.5 (becomes default for new projects in **6.6**).
  Enable it manually for iteration speed. *Source: "Path to CoreCLR (2026)".*
- **New built-in BCL assemblies (6.5):** `System.Text.Json`, `System.Collections.Immutable`,
  `System.Runtime.CompilerServices.Unsafe`, `System.Reflection.Metadata` — **the internal versions take
  precedence; user packages providing them are dropped from builds.** Watch for conflicts if a
  dependency vendored these. *Source: UpgradeGuideUnity65.*
- **`com.unity.serialization` is now a core package (6.5).** *Source: WhatsNewUnity65.*
- **Serialization rules tightened:** `[SerializeReference]` ancestor classes now need `[Serializable]`
  (Editor warning, 6.4); a **Serialization Rules Roslyn analyzer** flags missing `[Serializable]`,
  invalid `[SerializeReference]`, unsupported collections at compile time (6.5). *Source: WhatsNew64/65.*
- **30+ legacy `GameObject`/`Component` accessors removed (6.5)** — `.rigidbody`, `.camera`, `.renderer`,
  …, and `AddComponent(string)`. Use `GetComponent<T>()`. *(Our stub already uses `AddComponent<T>()`.)*
  *Source: UpgradeGuideUnity65.*
- **IL2CPP:** LTO mode for Linux/Embedded Linux; Android LTO for `libunity.so`; Web metadata
  optimizations (smaller/faster). *Source: WhatsNewUnity65.*

---

## 6. Tooling / platforms

- **Android (6.5):** **min API level → 26 (Android 8.0)** (23–25 warn); **x86-64 removed** (ARM64 only);
  **Gradle 9.1.0 + AGP 9.0.0**; edge-to-edge / insets APIs. *Quest builds are ARM64 — confirm build
  configs.* (6.4 min API was 25.) *Source: UpgradeGuideUnity65; system-requirements 6.4/6.5.*
- **Editor system requirements unchanged from 6.3:** Win 10 19043+, **macOS Ventura 13+**, Ubuntu
  22.04/24.04. *Source: system-requirements 6.4/6.5.*
- **Build Profiles:** platform list hideable + Platform Browser categories (6.4); **`CreateBuildProfile`
  scripting API** with auto package install (6.5) — good for CI desktop/VR profiles. *Source: WhatsNew64/65.*
- **Profiling:** **Project Auditor built into the Editor** (6.4, flags obsolete APIs between versions —
  handy for this very migration); Profiler **"Ask Assistant"** AI button, **2D Profiler module**,
  experimental **USS Stats Profiler**, QNX physical-RAM memory view (6.5). *Source: WhatsNew64/65.*
- **WebGPU: still experimental** (no promotion to stable found); UI Toolkit mesh management improved for
  WebGL/WebGPU (6.5). A WebXR/WebGPU port stays gated on WebGPU leaving experimental, as the baseline said.
  **⚠ UNVERIFIED** that it did *not* graduate — not stated either way on the fetched pages. *Source: WhatsNew64/65.*

---

## 7. What this changes for The Robot Draft

| Area | Baseline (6.3) said | Now (6.5) |
|------|---------------------|-----------|
| **Release version** | Build on 6.3 LTS | **6.3 is still the LTS to ship on.** Dev on 6.5 is fine; **don't ship on 6.5** (no LTS). Next LTS ≈ 6.7. |
| **ECS API** | *Avoid* `Entities.ForEach`/`IAspect` (obsolete) | **They're removed** — `IJobEntity` + `SystemAPI.Query` + `IJob` are the only option. |
| **DOTS packages** | Pin `com.unity.entities` 1.4.7 etc. | **Core packages, renumbered to 6.4.0/6.5.0; Mathematics is built-in.** Drop the manual 1.4.x pins. |
| **Entity IDs** | (n/a) | **`EntityId` is 8 bytes, not int-castable.** Don't persist entity IDs as `int`. |
| **Render pipeline** | URP + Render Graph + `AddRenderPasses`; Compatibility Mode gone | Same, **and the legacy Render Graph API is also gone (6.5).** BiRP is now *deprecated* (our stub only). |
| **Quest perf** | FFR fixed in 6.3; STP/GRD usable | **Add on-tile post (all platforms), Meta Quest shader opts (`UNITY_PLATFORM_META_QUEST`), Auto Viewport Dynamic Resolution, Multiview "All Passes".** |
| **VR module** | (used implicitly via XR) | **Built-in VR module removed (6.5).** OpenXR only — already our plan. |
| **Scripting** | C# 9, .NET Std 2.1, IL2CPP; CoreCLR at 6.7/6.8 | Unchanged; **6.5 adds CoreCLR lifecycle-API groundwork.** Watch the **new built-in BCL assemblies** for dependency conflicts. |
| **Tooling** | 6.3 Profiler Highlights etc. | **Project Auditor is built-in** — run it to catch obsolete-API usage during the 6.3→6.5 migration. |

**Net:** 6.5 doesn't change our architecture — it *hardens* it. Everything ADR-001 chose (URP + Render
Graph, custom GPU-driven indirect + our own Hi-Z occlusion, OpenXR, `IJobEntity`/`SystemAPI.Query`) is
now the *only* supported path rather than the recommended one. The one real governance decision is
**LTS vs Tech Stream**: keep a 6.3-LTS (or future 6.7-LTS) release branch even while developing on 6.5.

---

## 8. Verification status

**Confirmed from primary pages:** 6.4/6.5 support type (Update, not LTS); URP Compatibility Mode &
legacy Render Graph API removal; BiRP/Dynamic Batching deprecation; on-tile post + Quest shader opts;
ECS core-package renumber; `Entities.ForEach`/`IAspect`/`Job.WithCode` removal; `EntityId` change;
built-in `Unity.Mathematics`; OpenXR 1.15/1.16 feature set; VR module removal; Android min-API 26 /
x86-64 removal / Gradle 9; built-in BCL assemblies; CoreCLR-still-absent + lifecycle API; Project Auditor.

**Resolved since first draft** (second-pass corroboration): 6.4/6.5 GA dates (Mar 17 / Jun 15 2026,
Unity announcement posts); "Supported release" semantics; URP ≈ 17.2 with only refinements to
GRD/occlusion/STP/APV (baseline §3 stands); `collections` 6.4.0; OpenXR current = 1.17.0 (default
foveation → SRP API); XRI current = 3.5.1 (min editor 6000.0); PolySpatial = 2.x GA (corrected from 3.1.0).

**Still ⚠ open (validate in a live `6000.5.1f1` editor — low blast radius):**
1. **C# language version** on 6.5 (assume C# 9 until confirmed).
2. **Exact default-bundled** OpenXR / XRI / URP versions for `6000.5.x` specifically (current package
   versions are known; the editor→package pin is not).
3. Whether **WebGPU** graduated from experimental.
4. `com.unity.mathematics` exact 6.4.x version string (manual asserts it; own changelog mirror is stale).

### Sources (primary, fetched)
`endoflife.date/unity`; `discussions.unity.com` "Unity 6.4 is now available" & "Unity 6.5 is now
available" announcement posts + "Path to CoreCLR (2026) upgrade guide"; `docs.unity3d.com/6000.4`
WhatsNewUnity64 / UpgradeGuideUnity64 / system-requirements / urp gpu-resident-drawer & gpu-culling;
`docs.unity3d.com/6000.5` WhatsNewUnity65 / UpgradeGuideUnity65 / system-requirements; package
CHANGELOGs — `com.unity.entities@6.4` & `@6.5`, `com.unity.entities.graphics@6.4` & `@6.5` & `@1.4`,
`com.unity.collections@6.4`, `com.unity.render-pipelines.universal@17.2`, `com.unity.xr.openxr@1.15`
& `@1.16` & `@1.17`, `com.unity.xr.interaction.toolkit@3.5` & `@3.3`, `com.unity.xr.meta-openxr@2.5`,
`com.unity.xr.androidxr-openxr@1.2` & `@1.3`, `com.unity.polyspatial.visionos@2.4`. `unity.com/releases`
& `/blog` continue to 403 automated fetch (per baseline); the `com.unity.mathematics` 6.4.x version and
AR Foundation 6.4/6.5 details rest on the manual / secondary snippets and are flagged ⚠ above.
