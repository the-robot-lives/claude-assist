# Unity 6.3 LTS Engine Baseline

> The verified Unity engine baseline The Robot Draft builds against: **Unity 6.3 LTS**
> (`6000.3`), released **4 Dec 2025**, supported through **Dec 2027** (Enterprise/Industry
> +1 yr). This doc records the engine facts — graphics, DOTS, XR, scripting, tooling — that
> shape our rendering and ingestion design, each pinned to a primary Unity source.
>
> **Reading rule:** every claim below is sourced from a fetched `docs.unity3d.com` /
> `discussions.unity.com` / Meta page. Items we could **not** confirm from a primary page are
> marked **`⚠ UNVERIFIED`** and must be validated empirically before we rely on them — they are
> not filled from memory. Unity's `unity.com/blog` and `/releases` pages blocked automated
> fetching (HTTP 403), so marketing-level claims are corroborated from docs pages or flagged.

See also: [rendering-and-vr.md](rendering-and-vr.md) · [reverse-engineering.md](reverse-engineering.md) · [ADR-001](../adrs/ADR-001-unity-dots-rendering.md) · [ARCHITECTURE.md](../ARCHITECTURE.md)

---

## 1. Version timeline & support

| Version | Type | Released | Security support ends | Extended LTS ends |
|---------|------|----------|-----------------------|-------------------|
| Unity 6.0 | LTS | GA **17 Oct 2024** | 16 Oct 2026 | 16 Oct 2027 |
| Unity 6.1 | Supported update | 23 Apr 2025 | ended at 6.2 release | — |
| Unity 6.2 | Supported update | 12 Aug 2025 | ended at 6.3 release | — |
| **Unity 6.3** | **LTS** | **04 Dec 2025** | **04 Dec 2027** | **04 Dec 2028** |

Release model: standard updates are supported only until the next release; LTS versions get two
years (plus one for Enterprise/Industry). **Build The Robot Draft on 6.3 LTS, not 6.0 LTS** —
6.0 sunsets Oct 2026, and the GPU-driven and XR features we depend on matured across 6.1–6.3.
*Source: endoflife.date/unity; docs.unity3d.com WhatsNew pages; Unity investor press release (6.0 GA = 17 Oct 2024).*

---

## 2. Why 6.3 — the load-bearing engine facts

The Robot Draft is a GPU-driven, DOTS-based, VR renderer (see [ADR-001](../adrs/ADR-001-unity-dots-rendering.md)).
Five 6.x facts shape the whole design:

1. **`Graphics.RenderMeshIndirect` is the current GPU-driven draw API; `DrawMeshInstancedIndirect` is obsolete.**
2. **GPU Occlusion Culling only culls meshes managed by Unity's GPU Resident Drawer** — neither a hand-rolled indirect/BRG path **nor Entities Graphics** is auto-culled by it (Entities Graphics is a separate BRG user). We must roll our own GPU occlusion (Hi-Z).
3. **Render Graph is effectively mandatory** from 6.3 (URP Compatibility Mode is removed and stripped).
4. **The GPU Resident Drawer / occlusion / STP all require compute shaders and exclude OpenGL ES and visionOS** → on Quest we must ship **Vulkan**.
5. **DOTS (Entities) is stable on the 1.4.x line for 6.3, and becomes a core engine package in 6.4** — a strong production-readiness signal.

---

## 3. Graphics & rendering

### GPU Resident Drawer
Automatically uses BatchRendererGroup (BRG) to draw GameObjects with GPU instancing, cutting
draw calls and CPU time. URP + HDRP (SRP) only; **Built-in support ⚠ UNVERIFIED**.
- **URP** requires Renderers on **Forward+** (6.0) or **Deferred+** (added 6.1) paths; enable via
  *Graphics → BatchRendererGroup Variants = Keep All* + SRP Batcher + *GPU Resident Drawer =
  Instanced Drawing*.
- **Hard platform gate:** works only where **compute shaders** are supported, **except OpenGL ES
  and visionOS**. WebGL 2.0 lacks the required features. → **Quest = Vulkan only.**
- **Per-object constraints:** Mesh Renderer, DOTS-instancing-compatible shader, static GI only, no
  `MaterialPropertyBlock`, no per-instance callbacks, ≤128 materials; a *Disallow GPU Driven
  Rendering* component excludes a hierarchy.
- **VR caveat (the one documented VR statement):** improves CPU but **slightly increases GPU
  workload, felt more strongly on lower-end mobile/VR GPUs**; can raise overdraw on non-tiled GPUs.
- Introduced 6.0 / URP 17. *Source: URP/HDRP GPU Resident Drawer manual pages.*

### GPU Occlusion Culling
GPU-side culling of occluded objects using current + previous frame depth (culls only objects
occluded in **both** frames).
- **It is a sub-feature of the GPU Resident Drawer and requires it enabled.** Critically, **only
  meshes drawn through the Resident Drawer are occlusion-culled** — meshes drawn via
  `Graphics.RenderMeshInstanced`/custom indirect can act as *occluders* but are **not themselves
  culled** (Unity staff). **→ Our custom indirect path needs its own GPU culling.**
- Requires Render Graph ON (Compatibility Mode off), compute shaders, Forward+/Deferred+; can
  *increase* cost in low-occlusion scenes. Introduced 6.0 / URP 17. *Source: URP gpu-culling; HDRP 17.3.*

### Render Graph — now effectively mandatory
- **6.1:** default in new URP projects; Unity stops improving the non-Render-Graph path.
- **6.2:** Compatibility Mode is maintenance-only; URP **`SetupRenderPasses` deprecated** → use
  `AddRenderPasses`.
- **6.3:** **Compatibility Mode removed and code-stripped by default**;
  `RenderGraphSettings.enableRenderCompatibilityMode` is **read-only / returns `false`**. The
  `URP_COMPATIBILITY_MODE` define only *converts* a project in 6.3 and **stops working in 6.4**.
- API namespace **`UnityEngine.Rendering.RenderGraphModule`** (stable, SRP Core 17.x); contexts
  `RasterGraphContext`, `ComputeGraphContext`, `UnsafeGraphContext`.
- **→ Build all custom passes on Render Graph + `AddRenderPasses` from day one.** *Source: URP upgrade guides 6.1–6.3; SRP Core 17.3 API.*

### Indirect / instanced drawing APIs
- **Use `Graphics.RenderMeshIndirect`** — GPU instancing with command args from a `GraphicsBuffer`
  (CPU- or **GPU-written**); one buffer can hold multiple draw commands
  (`commandCount`/`startCommand`); args layout via **`GraphicsBuffer.IndirectDrawIndexedArgs`**;
  **requires compute-shader support**.
- **`Graphics.DrawMeshInstancedIndirect` is obsolete** → "Use `Graphics.RenderMeshIndirect`."
- `Graphics.RenderMeshPrimitives` (CPU-supplied counts) is **not** deprecated.
- For full GPU-driven control beyond the Resident Drawer's "Instanced Drawing" mode, drive
  **BatchRendererGroup directly**. *Source: ScriptReference RenderMeshIndirect / DrawMeshInstancedIndirect / RenderMeshPrimitives.*

### Variable Rate Shading (Shading Rate API) — new in 6.1
Decouples shading rate from raster rate. URP integrates via Render Graph
(`SetShadingRateAttachment`); HDRP via Command Buffer (`SetShadingRateFragmentSize` /
`SetShadingRateImage`); ~10% GPU-time reduction in a demo. Requires DX12 (Windows), Vulkan
(Android, with fragment-shading-rate), PS5, Xbox Series.
- **Critical VR limit:** **Quest/Android XR foveation uses a different Vulkan extension (Fragment
  Density) and is incompatible with the new VRS Shading Rate API.** Drive Quest foveation through
  the OpenXR/SRP foveation path instead (see §5). 6.3 adds **Frame Debugger VRS visualization**
  (DX12 + Vulkan). *Source: URP whats-new 17.1; Unity Discussions VRS thread.*

### STP (Spatial-Temporal Post-processing) upscaler
Software spatial+temporal upscaler, higher quality than TAAU; URP **and** HDRP; requires Shader
Model 5.0 + compute; **no OpenGL ES**; auto-enables TAA. Landed 6.0 / SRP 17.
**Stereo/VR: SUPPORTED (source-verified).** The manual pages omit XR, but the Unity Graphics
source code wires STP to XR: `STP.cs` defines `kMaxPerViewConfigs = 2` (one per eye) and an
`enableTexArray` flag for 2D-array textures "usually due to XR," and URP's `StpUtils.cs` sets
`config.enableTexArray = cameraData.xr.enabled && cameraData.xr.singlePassEnabled` and loops per
view — i.e. STP handles both single-pass-instanced and multipass XR. *Source: Unity Graphics repo
STP.cs / StpUtils.cs (master); URP/HDRP STP manual pages.*

### Adaptive Probe Volumes (APV)
- **Sky occlusion (6.3, URP + HDRP)** for day-night cycles with static probes; **requires the GPU
  Lightmapper**.
- **GPU Streaming + Disk Streaming** let APV bake data exceed CPU/GPU memory — the right primitive
  for lighting scenes larger than VRAM, but **mutually exclusive with AssetBundle/Addressable
  loading**. *Source: URP probevolumes-skyocclusion; HDRP APV streaming 17.2.*
- **6.3:** GPU Lightmapper becomes the **default** light-baking backend for new projects.

---

## 4. DOTS / ECS — the data-oriented foundation

The Robot Draft's million-element scale depends on DOTS ([ADR-001](../adrs/ADR-001-unity-dots-rendering.md)).

### Package versions (target for Unity 6.3 = the external `1.4.x` line)
| Package | Version verified on the 1.4.x line |
|---------|-------------------------------------|
| `com.unity.entities` | **1.4.7** — "released for Unity Editor version 6000.3" (verified) |
| `com.unity.entities.graphics` | **1.4.x** (latest seen 1.4.20) |
| `com.unity.burst` | **1.8.x** (latest seen 1.8.29) |
| `com.unity.collections` | **2.6.x** |
| `com.unity.mathematics` | **1.3.2** |

- **Entities 1.x is stable** (out of pre-release). Minimum editor across these packages: 2022.3.20f1.
- **In Unity 6.4, Entities / Collections / Mathematics / Entities Graphics become *core* packages**
  shipped with the editor and renumbered to match the editor (Entities `6.4.x`) — a deeper-engine-
  integration / production-readiness signal. **No explicit "production-ready" wording ⚠ UNVERIFIED.**
- **Entities 1.4.7 is the verified patch for 6.3** — the Unity 6.3 Entities manual page states
  "Package version 1.4.7 is released for Unity Editor version 6000.3." *Source: docs.unity3d.com/6000.3
  com.unity.entities.html; Entities/Entities Graphics/Burst changelogs; pack-core 6.4 manual.*

### Entities Graphics (the BRG render path for ECS)
- **MeshLOD** added 1.4.12, culling Burst-compiled.
- Burst-based masked **occlusion culling** + occlusion-browser tool present; `OnPerformCulling`
  Burst-optimized.
- **`DisableRendering`** tag component excludes entities from rendering.
- Late-cycle fixes: culling correctness for entities far from origin (8000 m+), chunk-fragmentation,
  motion-vector + APV support.
- **GPU Resident Drawer interop with Entities Graphics: NONE — they are separate (confirmed).**
  Entities Graphics and the GPU Resident Drawer are independent BatchRendererGroup users that "do not
  interact in any way"; enabling the GPU Resident Drawer has no effect on sub-scene entities, and
  Unity's built-in **GPU occlusion culling does not cull entities** — only GameObjects. *(This makes
  our own-Hi-Z decision unavoidable: whether we render via Entities Graphics or a custom indirect
  path, Unity's built-in GPU occlusion will not cull our meshes.)* *Source: Unity Discussions ECS+GRD
  and "GPU Occlusion Culling doesn't work for Entities" threads (community-confirmed; no contrary Unity-staff statement found).*

### Entities API (notable, cumulative over the 1.x line)
- **Deprecated:** `Entities.ForEach` and `IAspect` are **obsolete** → migrate to `IJobEntity` +
  `SystemAPI.Query`. `EntityManager.CopyEntities()` deprecated.
- **Added:** `SystemAPI.TryGetComponent`; `WithSharedComponentFilterManaged<T>`; "Present" component
  constraint; managed components schedulable in `IJobEntity` (not `ScheduleParallel`); generic system
  registration now needs `[assembly: RegisterGenericSystemType()]`.
- **Baking:** `BlobAssetStore` GC-based; fewer unnecessary rebakes. *Source: Entities 1.3/1.4/6.5 changelogs.*

### Burst
LLVM **19** default backend (6.x); `FloatMode.Deterministic` (1.8.25) for lockstep/determinism;
Linux/ARM64 FP modes; Burst on Web; min editor 2022.3. Watch an alias-analysis perf regression
around 1.8.20–1.8.21. *Source: Burst 1.8 changelog.*

---

## 5. XR / VR — Quest + PC VR at 90 fps

Unity 6.x ships XR mainly via the **OpenXR plugin** and **XR Interaction Toolkit**, versioned
independently of the editor.

### OpenXR plugin
- **Target `com.unity.xr.openxr` 1.16.x** on Unity 6.3 (1.16.1, Nov 2025). Recommended Quest provider
  over the legacy Oculus XR Plugin.
- **Stereo:** **Single Pass Instanced / Multiview** (label updated in 1.16). **Multiview Render
  Regions** (added 1.14, "All Passes" in 1.15) skips shader work for off-view screen areas — requires
  **Symmetric Projection ON**, Single Pass Instanced/Multiview, **Vulkan only**.
- **1.15.0** added a Unity-native **URP Application SpaceWarp** path + RG16f motion-vector format.
  *Source: OpenXR 1.15/1.16 changelog & manual.*

### Foveated rendering (FFR & ETFR)
- Two API paths (OpenXR setting "Foveated Render API"): **SRP Foveation API** (URP **or** HDRP, all
  supported platforms, needs Unity 6+ and OpenXR ≥ 1.11.0) vs **Legacy** (Meta Core XR SDK,
  Quest-only).
- **Technique by platform:** OpenXR/**Quest → VRS uniform raster, shaders need no change**;
  visionOS/Metal → VRR non-uniform raster (screen-space-math shaders need remap helpers like
  `FoveatedRemapLinearToNonUniform`). **Not supported in Built-in RP.** PC needs DX12 or Vulkan.
- **API:** `XRDisplaySubsystem.foveatedRenderingLevel` (0–1), `...foveatedRenderingFlags =
  FoveatedRenderingFlags.GazeAllowed` (eye-tracked); can take up to 3 frames to initialize.
- **FFR-on-Quest corruption bug — acknowledged and reportedly fixed in 6.3.** Affected 6.1/6.2 + URP
  17.0.3 + Vulkan + OpenXR 1.15.1. Unity staff acknowledged it (bug IN-115870; not publicly indexed);
  the OpenXR plugin **1.15.0/1.15.1** changelogs fixed "foveation data corruption … when the swapchain
  was frequently resized," and a developer confirmed the issue **resolved in Unity 6000.3.0f1 (6.3)**
  on Quest. ⚠ Still reported on non-Quest hardware (Pico 4U) — validate on our target devices.
  *Source: Unity Discussions FFR thread; OpenXR 1.15 changelog.*

### Application SpaceWarp (AppSW) — Quest
Depth + motion-vector frame extrapolation (~70% extra compute headroom per Meta); **Vulkan only**;
backed by `XR_FB_space_warp` (and OVRPlugin v34+). **Every custom shader must include a
motion-vectors pass** or AppSW produces artifacts — the tag is **`LightMode="MotionVectors"`** on
Meta's Core-SDK path and **`LightMode="XRMotionVectors"`** on the OpenXR-plugin URP path (1.15+;
the wrong-NDC-handedness bug was fixed in 1.15.0, so the device's NDC convention must be specified).
Set Mesh Renderer **Motion Vector Generation Mode** (Per Object Motion for movers, Camera Motion
Only for static). URP includes SpaceWarp support by default with Render Graph since 6000.0.9f1; Meta
recommends 6000.4.0f1+. **A serious commitment — treat as a render-pipeline-wide change.**
**→ Our custom indirect shaders must emit motion vectors (`XRMotionVectors` pass) if we adopt AppSW.**
*Source: Meta unity-asw (live); OpenXR 1.15 SpaceWarp-shaders page + 1.15/1.16 changelog.*

### 6.3 XR performance features
- **On-tile post-processing** — run some URP post FX on untethered XR (Quest/Android XR) at reduced
  GPU cost.
- **Automatic Viewport Dynamic Resolution for OpenXR** — auto-adjust resolution to hold frame rate
  (directly serves the 90 fps target).
- **Render Graph Viewer on-device** — profile render-graph GPU bandwidth on Quest 3.
- **XR Interaction Toolkit 3.x** (latest 3.1.3): Near-Far Interactor, XR Body Transformer, XR
  Interaction Simulator, gravity/jump locomotion. *Source: WhatsNew 6.3; XRI 3.1 changelog.*

---

## 6. Scripting & runtime baseline

- **API compatibility:** **.NET Standard 2.1 (default)** or **.NET Framework 4.8 + .NET Standard 2.1
  APIs**. Unity recommends .NET Standard for new projects → **The Robot Draft targets .NET Standard 2.1.**
- **Backends:** **Mono** and **IL2CPP** (nearly identical API surface). Ship players on **IL2CPP**
  (AOT, required/strongly preferred for Quest and console; best runtime perf).
- **CoreCLR / .NET modernization — NOT in 6.3.** Per Unity's "Path to CoreCLR (2026)" guide:
  experimental **CoreCLR Desktop Player in 6.7**; **CoreCLR editor + Mono removal in 6.8** with
  **.NET 10 / C# 14**; Fast Enter Play Mode becomes default (6.6) then only option (6.8). **6.3 stays
  Mono/IL2CPP on .NET Standard 2.1.** *(Plan a future migration pass when we reach 6.7/6.8.)*
- **C# language version: C# 9.0** (Roslyn), for both Mono and IL2CPP. Known caveats Unity calls out:
  don't use `record` types in serialized types; `init`/`record` need a manual
  `System.Runtime.CompilerServices.IsExternalInit` declaration; C# 10+ is unsupported. *Source:
  docs.unity3d.com/6000.3 csharp-compiler.html.*
- *Source: dotnet-profile-support 6.3; scripting-backends-intro; Unity Discussions CoreCLR guide + Mar 2026 status.*

### Notable deprecations/removals affecting us
- **6.3:** URP Compatibility Mode **removed**; experimental lightmapping API removed
  (`AdditionalBakedProbes`; `CustomBake` → `LightTransport.IProbeIntegrator`); `[SerializeField]` on
  non-fields is now a **compile error**; `AccessibilityRole` flags→standard enum; several
  `int`→`EntityId`/`SceneHandle`/`byte` type changes require **recompiling precompiled assemblies**.
- **6.1:** `_FORWARD_PLUS` shader keyword → `_CLUSTER_LIGHT_LOOP`; PVRTC deprecated; DX12 default on
  Windows.
- **6.2:** URP `SetupRenderPasses` deprecated; `VisualElement.transform` deprecated. *Source: 6.1/6.2/6.3 upgrade guides.*

---

## 7. Tooling, platforms & services

- **Build Profiles** is the default build workflow (renamed from Build Settings): per-profile scenes,
  defines, and **graphics/quality overrides (6.1)**, **diagnostics overrides incl. Win/macOS (6.2)**,
  selective "Add Settings" + a **scriptable `BuildProfile` C# API (6.3) for CI**. → ship **separate
  desktop and VR build profiles**.
- **Profiling (6.3):** Profiler **Captures List**, **Highlights details pane** (CPU- vs GPU-bound
  triage — central to VR frame-budget work), **Frame Debugger VRS** view; **Memory Profiler** package
  shows graphics/GPU memory + "Shortest Path To Root"; native allocation callstacks via
  `-enable-memoryprofiler-callstacks` (6.3+). Build time: Burst+IL2CPP up to ~22% faster.
- **Web: WebGPU is EXPERIMENTAL through 6.3** (not production); **WebGL 2.0 remains the default**.
  WebGPU adds compute/indirect/GPU-skinning but lacks async compute and synchronous GPU readback. For
  a desktop+VR-first tool, web is secondary; **a future WebXR/WebGPU port is gated on WebGPU leaving
  experimental.**
- **Platform support:** Android min API → **25 (Android 7.1)** in 6.3; `UnityWebRequest` HTTP/2 by
  default; Dedicated Server Arm64 on Linux. **Magic Leap** full support ends after 6.2; **Facebook
  Instant Games** deprecated in 6.3.
- **AI:** **Sentis** (package id `com.unity.ai.inference`; display name went Sentis → "Inference
  Engine" → back to **Sentis**) is the shipping on-device inference path. **Unity Muse is sunset**,
  replaced by **Unity AI** (Assistant + Generators; open beta May 2026). *(Relevant only if we add
  in-tool ML, e.g. UMAP/code-embedding inference — see [rendering-and-vr.md](rendering-and-vr.md).)*
- **Adaptive Performance** is a built-in core Editor module in 6.3 with a cross-platform Basic provider
  (framerate capture) — useful for desktop+VR thermal/perf scaling (desktop/VR throttling specifics
  ⚠ UNVERIFIED). *Source: 6.1–6.3 WhatsNew/upgrade pages; package changelogs; Unity Discussions.*

### Editor system requirements (6.3)
- **Windows:** Win 10 21H1 (19043)+ x64 / Win 11 21H2 (22000)+ Arm64; SSE2 or Arm64 CPU; DX10/11/12 or
  Vulkan GPU.
- **macOS:** Ventura 13+; Intel SSE2 or Apple M1+; Metal GPU.
- **Linux:** Ubuntu 22.04 / 24.04; x64 SSE2; OpenGL 3.2+ or Vulkan (Nvidia/AMD).
- **RAM:** 8 GB minimum recommended.
- **Change vs 6.1/6.2:** only the **macOS minimum rose — Big Sur 11 → Ventura 13** in 6.3; Windows,
  Linux, RAM, and GPU/API requirements are unchanged. *Source: docs.unity3d.com system-requirements 6.1/6.2/6.3.*

---

## 8. What this changes in our design

| Area | Decision impact |
|------|-----------------|
| **GPU-driven draws** | Use `Graphics.RenderMeshIndirect` (GPU-written `IndirectDrawIndexedArgs`) or BRG directly — never `DrawMeshInstancedIndirect`. |
| **Occlusion culling** | Unity's GPU occlusion culling will **not** cull our custom indirect meshes. Build our own **Hi-Z compute occlusion** (as ADR-001 already plans), or route through the Resident Drawer. |
| **Render pipeline** | Commit to **URP + Render Graph + `AddRenderPasses`** from day one; Compatibility Mode is gone. URP Forward+/Deferred+ only. |
| **Platform/API** | **Vulkan on Quest** (GPU Resident Drawer / occlusion / STP exclude GLES + visionOS). DX12/Vulkan on desktop. |
| **DOTS** | Target Entities **1.4.x** on 6.3; avoid `Entities.ForEach`/`IAspect` (obsolete) — use `IJobEntity` + `SystemAPI.Query`. Plan for the 6.4 core-package renumber. |
| **VR foveation** | Use the **OpenXR SRP Foveation API** (not the 6.1 VRS Shading Rate API, which is incompatible with Quest foveation). The Quest FFR corruption bug is fixed in 6.3 — still re-test on our target devices. |
| **AppSW (optional)** | If adopted, our custom indirect shaders **must emit motion vectors** (`XRMotionVectors` pass on the OpenXR URP path); Vulkan only — budget the pipeline work. |
| **Scripting** | **C# 9.0**, .NET Standard 2.1 + IL2CPP now; schedule a **CoreCLR/.NET 10/C# 14 migration** when we move to 6.7/6.8. |
| **Frame-budget tooling** | Use the 6.3 Profiler **Highlights** (CPU/GPU-bound), Frame Debugger VRS, and Memory Profiler GPU-memory views as our standing VR-perf instruments. |
| **STP in VR** | **Confirmed stereo-capable** (source-verified — single-pass-instanced + multipass). Usable as our VR upscaler; still benchmark quality/cost in-headset. |

---

## 9. Verification status

A second alternative-source pass (GitHub Unity Graphics source, package manifests, the Android XR
performance guide, Unity Discussions, and Unity's investor relations page — since `unity.com/blog`
and `/releases` and `web.archive.org` content were all unreachable to automated fetching) **resolved
the items originally flagged UNVERIFIED:**

| Item | Resolution | Source |
|------|-----------|--------|
| STP stereo/VR support | **Confirmed supported** (single-pass-instanced + multipass) | Unity Graphics repo `STP.cs` / `StpUtils.cs` |
| GPU Resident Drawer + occlusion under stereo | **Works in VR; recommended for Android XR** (profile the occlusion path) | Android XR Unity performance guide |
| GPU Resident Drawer ↔ Entities Graphics | **Separate** — no interop; GPU occlusion does not cull entities | Unity Discussions (community-confirmed) |
| Quest FFR corruption | **Acknowledged (IN-115870); fixed in 6.3** (still seen on Pico 4U) | Unity Discussions; OpenXR 1.15 changelog |
| Entities patch for 6.3 | **1.4.7** ("released for 6000.3") | docs.unity3d.com/6000.3 entities manual |
| C# language version | **C# 9.0** | docs.unity3d.com/6000.3 csharp-compiler |
| Unity 6.0 GA date | **17 Oct 2024** | Unity investor press release |
| Editor min-spec change | **macOS Big Sur 11 → Ventura 13**; rest unchanged | system-requirements 6.1/6.2/6.3 |
| AppSW shader requirement | **Confirmed** — `XRMotionVectors`/`MotionVectors` pass, Vulkan only | Meta unity-asw; OpenXR 1.15 |

**Still genuinely open** (validate empirically; low blast-radius):
1. **STP and GPU Resident Drawer in-headset quality/cost** — capability is confirmed; tune against our frame budget.
2. **The `4 GB` Wasm memory ceiling and native web-view embedding** — no primary source located (only relevant to a future WebGPU/WebXR port).
3. **A named "6.2 Dynamic Refresh Rate" feature** — the API exists (`XRDisplaySubsystem.TryGetDisplayRefreshRate`; `XRDevice.refreshRate` is obsolete), but no Unity page confirms it as a named 6.2 feature; the runtime *request* API is provider-specific (Meta/Android XR OpenXR).
4. **6.4 Compatibility Mode full removal** specifics (we target 6.3; plan ahead).

---

### Sources (primary)
Unity Manual WhatsNew/Upgrade 6.1/6.2/6.3; `dotnet-profile-support`, `scripting-backends-intro`,
`system-requirements` (6.3); URP/HDRP GPU Resident Drawer, gpu-culling, compatibility-mode, STP,
probevolumes pages; SRP Core 17.3 RenderGraphModule API; ScriptReference RenderMeshIndirect /
DrawMeshInstancedIndirect / RenderMeshPrimitives; Entities / Entities Graphics / Burst changelogs
(1.4.x / 1.8.x) + `pack-core` (6.4); OpenXR plugin 1.15/1.16, XRI 3.1, xr-foveated-rendering (6.2),
Meta `unity-asw`; Unity Discussions "Path to CoreCLR (2026)" + "CoreCLR/ECS status (Mar 2026)";
Memory Profiler / Netcode / Addressables / AI (`com.unity.ai.inference`) changelogs; endoflife.date/unity.

**Alternative sources (2nd pass, for items the 403'd `unity.com/blog` and `/releases` pages blocked):**
Unity Graphics GitHub repo source (`STP.cs`, `StpUtils.cs`); `needle-mirror/com.unity.entities`
manifests + `docs.unity3d.com/6000.3` entities/`csharp-compiler`/`system-requirements` manual pages;
Android XR Unity performance guide (developer.android.com); Unity Discussions (ECS+GRD interop, GPU
occlusion vs entities, Quest FFR/IN-115870); OpenXR plugin 1.15 SpaceWarp-shaders page + changelog;
Meta `unity-asw` (live); Unity investor-relations press release (6.0 GA = 17 Oct 2024); third-party
corroboration (cgchannel, 80.lv, gamefromscratch).
*`unity.com/blog`/`releases` and `web.archive.org` content were unreachable to automated fetching;
the items they would have confirmed were sourced from the alternatives above instead — see §9.*
