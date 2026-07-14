# Unity 6.x Engine Core, Editor & Scripting

*Currency: Unity 6 / `6000.x` (2024–2026). Verified against `docs.unity3d.com/6000.x`. Items that could not be re-verified live are flagged.*

## 1. Release Timeline, Versioning & LTS Model

Unity ended the calendar-style `YYYY.x` naming (last was **Unity 2023 LTS**, folded into Unity 6) and moved to a product-style major version: **Unity 6**, with engine version strings in the **`6000.x`** family.

- **Unity 6.0 launched October 17, 2024** (`6000.0`). The leading `6000` maps to the "Unity 6" line (replacing the `2023.x` codepath). Patch builds keep the familiar suffix, e.g. `6000.0.71f1` (`f` = final/release).
- **"6.1 / 6.2 / 6.3" = `6000.1` / `6000.2` / `6000.3`** — marketing names collapsed into the `6000.x` numbering.

| Release | Version | Status / Date | Confidence |
|---|---|---|---|
| Unity 6.0 | `6000.0` | Released **Oct 17, 2024**; now an **LTS** line | High |
| Unity 6.1 | `6000.1` | Released **2025** (~GDC/April 2025) | Medium |
| Unity 6.2 | `6000.2` | Released **2025**; major AI + accessibility additions | Medium |
| Unity 6.3 | `6000.3` | Shipped as an **LTS** (~early 2026) | Medium |

- **LTS model:** the final minor in a cycle becomes the **LTS**, supported ~2 years of patches (Industry/Enterprise get +1 year). Multiple LTS lines can be supported in parallel with the mainline.
- **Cadence:** roughly annual feature ("minor") releases with an LTS at the end.

> Flag: exact 6.1/6.2 public release dates could not be re-verified via live fetch (unity.com returns 403 to automated fetch). Verify on unity.com.

## 2. Runtime Fee (Cancelled) & Licensing

**Runtime Fee — dead.** Announced Sept 2023 (per-install royalty), walked back, and **fully cancelled September 2024** under CEO Matthew Bromberg. Replacement: a return to the **traditional subscription model** with annual price increases on paid plans instead of per-install fees.

| Tier | Audience | Cap | Indicative price |
|---|---|---|---|
| **Personal** | Hobbyists/small teams | revenue/funding **< $200,000** | Free |
| **Pro** | Commercial over the cap | none | ~$2,200/seat/yr |
| **Enterprise** | Large studios (source access, support) | none | Custom |
| **Industry** | Non-games (AEC, mfg, sim; bundles Pixyz/Asset Transformer) | none | ~$4,950/seat/yr |

Other changes: **"Made with Unity" splash no longer mandatory on Personal**; **Unity Plus discontinued** (folded into Personal/Pro). Industrial customers (>$1M/yr revenue) **cannot buy Pro** — routed to Industry. (Dollar figures approximate — verify on unity.com/pricing.)

## 3. Render Pipelines & Project Foundations

| Pipeline | Package | Best for | Unity 6 status |
|---|---|---|---|
| **Built-in (BiRP)** | core engine | Legacy/simple, max plugin compat | **Deprecated** (still supported through LTS) |
| **URP** | `com.unity.render-pipelines.universal` (17.x) | Mobile→console→desktop/XR; most new projects | Default & recommended |
| **HDRP** | `com.unity.render-pipelines.high-definition` (17.x) | High-fidelity, high-end PC/console only | SRP |

URP/HDRP are **Scriptable Render Pipelines (SRP)** atop `com.unity.render-pipelines.core`. Hub templates: **Universal 3D** (URP), **HD 3D** (HDRP), **Universal 2D**. Choose early — switching URP↔HDRP is costly.

**Package Manager (UPM):** `Packages/manifest.json` holds `dependencies`, `scopedRegistries`, `enableLockFile`. Sources: Unity Registry (`"com.unity.x":"1.2.3"`), scoped registry (OpenUPM/npm), Git URL (`...git?path=/sub#tag` — manifest-only), local (`file:...`). Commit **`packages-lock.json`** for deterministic resolution. Asset Store content imports as `.unitypackage` into `Assets/`, separate from UPM.

**Assembly Definitions:** `.asmdef` = a separate compiled assembly per folder; `.asmref` points another folder at an existing asmdef. Benefit: only changed assemblies + dependents recompile (vs the monolithic `Assembly-CSharp.dll`). Features: explicit references (cycles disallowed), platform include/exclude, **Editor-only** assemblies, **Version Defines** (conditional symbols when a dependency ≥ X is present), `Auto Referenced` toggle. Gotcha: predefined assemblies can't reference asmdef assemblies; adding an asmdef can break previously-working references.

**Scripting backends:**

| | Mono (JIT) | IL2CPP (AOT) |
|---|---|---|
| Builds | Fast; supports `Reflection.Emit` | Slow; no runtime codegen |
| Runtime | Baseline | Faster, leaner, harder to decompile |
| Platforms | Desktop | **Required**: iOS, WebGL, consoles, UWP/ARM |

IL2CPP **managed code stripping** levels: Disabled / Minimal / Low / Medium / High. Preserve reflection-only code with `[Preserve]` or `link.xml`.

**.NET / C# support (Unity 6 LTS today):** Roslyn compiler, **C# 9.0** (note: `record`/`init` unusable — `IsExternalInit` missing; don't use records in serialized types). API Compatibility Levels: **.NET Standard 2.1** (default, smaller) or **.NET Framework 4.8** (superset, for legacy plugins). **CoreCLR roadmap** (flag — version approximate): Unity is migrating Mono→**CoreCLR** bringing **.NET 8+, modern JIT/GC, C# 12/13**, targeted around the 6.x cycle (experimental, broad availability later); shipping LTS today is still Mono/IL2CPP + C# 9.

## 4. New Editor & Rendering Features (Unity 6.x)

**GPU Resident Drawer** (URP/HDRP, 6.0): auto-uses BatchRendererGroup + GPU instancing to slash draw calls and free the main thread. Requires **Forward+/Deferred+**, **SRP Batcher on**, compute-shader API (no OpenGL ES / visionOS). **MeshRenderer only** (no Skinned/Terrain/Particle/Line/Trail); no MaterialPropertyBlocks; ≤128 materials. Enable: *Project Settings > Graphics > Shader Stripping → BatchRendererGroup Variants = Keep All*; URP Asset → *GPU Resident Drawer = Instanced Drawing*; Renderer → *Rendering Path = Forward+*.

**GPU Occlusion Culling** (6.0): GPU-side culling of occluded objects. Requires GPU Resident Drawer; enable *GPU Occlusion* on the Universal Renderer. Best for high-occlusion, many-instance scenes; can add GPU cost in low-occlusion scenes.

**Render Graph** (6.0): the new default SRP authoring API (URP + HDRP) — automatic GPU resource allocation/reuse + pass scheduling. The legacy path is **"Compatibility Mode (Render Graph Disabled)"** under *Project Settings > Graphics*, deprecated/slated for removal. **Render Graph Viewer**: *Window > Analysis > Render Graph Viewer*. (See `rendering-graphics.md` for the migration API.)

**STP (Spatial-Temporal Post-processing)** (6.0): cross-platform compute-based temporal upscaler + TAA, quality comparable to DLSS2/FSR2, mobile-first, vendor-agnostic. Requires SM5.0 + compute (no OpenGL ES).

**Build Profiles** (6.0): *File > Build Profiles* replaces the legacy Build Settings window. Per-platform/per-release config **assets** (VCS-friendly) with **custom scene lists** and **Player Settings overrides** per profile.

**Multiplayer tooling (6.0):** Multiplayer Center, Multiplayer Play Mode (up to 4 in-editor players), NGO 2.x with Distributed Authority. (See `ai-tooling-ecosystem.md`.)

**Other UX:** Overlays framework; Create menu split (MonoBehaviour / ScriptableObject / Blank Script); **Piercing Menu** (Ctrl+Right-click to pick overlapping GameObjects); search field in context menus; Project Settings reorg.

## 5. Scripting Fundamentals & Idioms

**MonoBehaviour lifecycle:** `Awake` (once, even if disabled) → `OnEnable` → `Start` (once, before first Update) → `FixedUpdate` (0..N, physics) → `Update` → `LateUpdate` → `OnDisable` → `OnDestroy`. All `Awake`s run before any `Start` globally.

**ScriptableObjects:** serializable data assets (`: ScriptableObject`, `[CreateAssetMenu]`) living in the project, not on GameObjects — shared config, data-driven design, event channels; one in-memory copy referenced by many.

**Serialization:** `[SerializeField]` serializes private fields. Unity serializes primitives, strings, enums, `UnityEngine.Object` refs, `[Serializable]` structs/classes, and lists/arrays of these. It **does not** serialize dictionaries, polymorphic refs, properties, statics. Use **`[SerializeReference]`** for polymorphic/null/shared/interface references.

**Coroutines vs async/await vs Awaitable (new in Unity 6):**
- Coroutines: `IEnumerator`/`yield`, tied to MonoBehaviour lifetime, allocate.
- `Task`: not Unity-aware, resumes on thread pool, more GC.
- **`UnityEngine.Awaitable`**: pooled (low/no GC), main-thread-aware. Helpers: `NextFrameAsync`, `WaitForSecondsAsync`, `EndOfFrameAsync`, `FixedUpdateAsync`, `BackgroundThreadAsync`, `MainThreadAsync`. Cancellation via `CancellationToken` / `destroyCancellationToken`. **Gotcha: a pooled instance is not safe to `await` twice.**

```csharp
async Awaitable Demo(CancellationToken ct) {
    await Awaitable.WaitForSecondsAsync(1f, ct);
    await Awaitable.BackgroundThreadAsync();   // off main thread
    int r = HeavyCompute();
    await Awaitable.MainThreadAsync();          // back for Unity API
    transform.position = Vector3.one * r;
}
```

**Execution order:** undefined between scripts except Awake-before-Start globally; override via *Project Settings > Script Execution Order* or `[DefaultExecutionOrder(int)]` (lower runs earlier).

**Prefabs:** instances keep a link + per-instance overrides. **Variants** inherit a base (like subclassing). **Nested prefabs** keep their own links. Override resolution: instance > variant > base.

## 6. Gotchas & Black Magic

**Serialization:** Dictionaries never serialize (use parallel lists + `ISerializationCallbackReceiver`). **"Fake null"**: destroyed `UnityEngine.Object`s aren't real null — Unity overloads `==`; **never use `?.` or `??` on Unity objects** (they bypass the overload); `ReferenceEquals(obj,null)` lies. **`.meta` GUIDs are asset identity** — always commit them; deleting/regenerating breaks every reference ("missing script" = changed script GUID).

**Performance/GC:** cache `GetComponent` and `Camera.main`; avoid string concat/interpolation/`tag ==` (use `CompareTag`, `StringBuilder`) in hot paths; beware boxing of structs/enums into `object`. **VSync overrides `targetFrameRate`** — set `QualitySettings.vSyncCount = 0` to honor it. In `FixedUpdate`, `Time.deltaTime` returns `fixedDeltaTime`; read input in `Update`.

**Editor vs build:** guard `UnityEditor` code with `#if UNITY_EDITOR` or `Editor/` folders; `AssetDatabase`/`PrefabUtility` are editor-only. Prefer **Addressables** over `Resources`. Scenes must be in Build Profiles/Addressables to load in a build. `DontDestroyOnLoad` singletons duplicate on re-entering the bootstrap scene — guard in `Awake`.

**Unity 6 specifics:**
- **Render Graph breaks custom render features** (see `rendering-graphics.md`).
- **GPU Resident Drawer**: MeshRenderer-only; per-object `MaterialPropertyBlock` edits and runtime `material` mutation break batching.
- **Awaitable**: pooled (don't await twice); use `destroyCancellationToken` so async auto-cancels on destroy.
- **IL2CPP stripping breaks reflection**: code reached only via reflection/`Type.GetType`/JSON-to-type gets stripped (works in editor, NRE in build) — fix with `[Preserve]` or `link.xml`.

**Black magic:** ScriptableObject event channels (decouple via SO + `UnityEvent`/`Action`); `[ContextMenu]` / `[ContextMenuItem]` for editor-time actions; `OnValidate` for inspector-time validation/clamping; `[ExecuteAlways]` for edit-mode tools (guard with `Application.isPlaying`); `EditorApplication.update/.playModeStateChanged/.delayCall` hooks; **Job System + Burst** for hot paths (see `dots-ecs-performance.md`).
