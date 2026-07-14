# Unity 6.x Version, Rebrand & Gotcha Cheat-Sheet

Fast lookup for "what is this called now / what version / what breaks." Cross-cuts all domain references. **Always confirm against the in-Editor Package Manager** — package versions are pinned to editor version in 6.x.

## Version Decoder
- Unity 6 ships as **`6000.x`**: `6000.0`=6.0 (Oct 17 2024, LTS), `6000.1`=6.1, `6000.2`=6.2, `6000.3`=6.3 LTS.
- SRP (URP/HDRP/Shader Graph) versioned together as **17.x**, pinned to editor.
- Final minor of a cycle = **LTS** (~2 yr patches; Industry/Enterprise +1 yr).

## Rebrand / Rename Map (don't use the old names on new editors)
| You might know it as | Current name | Package |
|---|---|---|
| Muse Chat | Unity AI Assistant | `com.unity.ai.assistant` |
| Muse Sprite/Texture/Animate | AI Generators | `com.unity.ai.generators` |
| Muse Behavior | Unity Behavior (free) | `com.unity.behavior` |
| Sentis / Barracuda | Inference Engine | `com.unity.ai.inference` |
| Pixyz Plugin | Asset Transformer Toolkit | `com.unity.industry.toolkit` |
| Pixyz Studio / SDK | Asset Transformer Studio / SDK | (2026.4) |
| Pixyz Scenario | Asset Transformer SDK file-to-file batching | (deprecated) |
| Plastic SCM | Unity Version Control (UVCS) | — |
| Cloud Build | Unity Build Automation | — |
| Build Settings window | Build Profiles | `File > Build Profiles` |
| Hybrid Renderer | Entities Graphics | `com.unity.entities.graphics` |
| XR Rig | XR Origin | XRI 3.x |
| Light Layers | Rendering Layers | URP/HDRP |
| NavMesh window | AI Navigation (`NavMeshSurface`) | `com.unity.ai.navigation` |

## Discontinued / Deprecated (don't build on these)
- **Unity Reflect** — EOL ≈mid-2024. **Unity MARS** — deprecated. **Windows Mixed Reality** — EOL (Win11 24H2). **Unity Plus** tier — discontinued. **Runtime Fee** — cancelled Sept 2024.
- **`IAspect`** (DOTS) — deprecated. **XRI Affordance System** — deprecated. **Vector Graphics package** — perpetual preview, "not for production." **Built-in Render Pipeline** — deprecated (still supported). **`Physics.RaycastNonAlloc`** → `RaycastCommand`. **Render Graph Compatibility Mode** — deprecated.

## Key Package Versions (Editor 6000.2 baseline; verify in-editor)
| Package | Version |
|---|---|
| URP/HDRP/Shader Graph | 17.x |
| Entities / Collections / Physics / Entities Graphics | 6.5.x |
| Burst | 1.8.x · Mathematics 1.3.x · Netcode for Entities 6.6.x |
| XR Interaction Toolkit | 3.2.2 |
| AR Foundation / ARCore / ARKit | 6.2.x |
| OpenXR plugin | 1.15.1 · XR Hands 1.5.1 |
| PolySpatial | 2.4.3 |
| Cinemachine | 3.1.7 · Input System 1.14.2 · Splines 2.7.2 · AI Navigation 2.0.13 |
| Inference Engine | 2.2.2 · Behavior 1.0+ |
| Addressables | ~2.3 (asset) / 3.1 (cited elsewhere — verify) |
| Netcode for GameObjects | 2.x (~2.4) |
| Localization | ~1.5.x |
| 2D: Animation / Pixel Perfect / Tilemap Extras | 12.x / 5.x / 8.x |
| Asset Transformer Toolkit / Studio+SDK | 3.3.0 / 2026.4 |

## Top "Black Magic" Gotchas (cross-domain)
1. **Fake null** — never use `?.`/`??`/`ReferenceEquals` on destroyed `UnityEngine.Object`s; Unity overloads `==`.
2. **`.meta` GUIDs are asset identity** — always commit them; changed script GUID = "missing script."
3. **Render Graph migration** — `Execute()` → `RecordRenderGraph()`; render func must be static-safe. Compatibility Mode is deprecated.
4. **GPU Resident Drawer** needs Forward+ + SRP Batcher + compute API; MeshRenderer-only; `MaterialPropertyBlock`/runtime `material` mutation break batching.
5. **Cinemachine 2→3** — namespace + component renames break Timeline/Animation; run the Upgrader.
6. **Input System "Both"** during migration or input silently no-ops.
7. **IL2CPP stripping** kills reflection-only code (works in editor, NRE in build) → `[Preserve]`/`link.xml`.
8. **Awaitable** is pooled — don't await twice; use `destroyCancellationToken`.
9. **PolySpatial RealityKit modes = Shader Graph only** (→MaterialX); hand-written shaders silently fail.
10. **VR single-pass stereo** needs `UNITY_VERTEX_OUTPUT_STEREO` macros or renders mono/left-eye-only.
11. **2D unlit sprites black under 2D lights** — need Global light + correct Target Sorting Layers + Sprite-Lit material.
12. **Addressables remote profile + Build Profiles** misconfig → "works in editor, 404 in build."
13. **Box2D v3** (Unity 6) — re-tune stacking/restitution/joints when upgrading old 2D projects.
14. **CAD prep is mandatory upstream** — raw CAD must be tessellated/decimated via Asset Transformer before rendering tech performs.
15. **GC is non-compacting (Boehm)** — heap only grows; drive per-frame allocs toward 0; audit boxing/LINQ/closures.

## Pipeline Decision (fast)
- Cross-platform game / mobile / XR / 2D → **URP**.
- AAA fidelity, fixed high-end PC/console, ray tracing → **HDRP**.
- Big CAD viz on desktop → **HDRP** (fidelity) or **URP** (if XR headset target).
- App/dashboard/kiosk UI → URP + **UI Toolkit (runtime)**.
- Legacy project only → **BiRP** (deprecated; don't start new projects here).
