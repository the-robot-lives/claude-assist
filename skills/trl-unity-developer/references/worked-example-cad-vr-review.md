# Worked Example: CAD Design-Review App (Asset Transformer → Unity → Quest VR)

End-to-end demonstration spanning the **CAD/industrial** and **XR/VR** domains — the harder, niche path. Shows licensing reality, the dataprep pipeline, and the pipeline-divergence gotcha.

## Request
> "We have a 1.8-million-part CATIA assembly of an engine. We want engineers to walk around it in VR on Quest 3 for design review, hide/show subsystems, and read part metadata. How do we get it into Unity and make it run on a headset?"

## Step 1 — Licensing reality check (Workflow 5)
- Company is well over $1M/yr revenue and this is non-game → **Unity Industry license required** (cannot use Pro). Industry bundles the **Asset Transformer Toolkit** (formerly Pixyz Plugin) — which is exactly the CAD ingestion tool needed. Flag the ~$4,950/seat/yr and the ⚠️ unverified 2025 "Distribution License" revenue fee for runtime distribution; tell them to confirm with Unity sales.
- **Unity Reflect is EOL** — there is no turnkey CAD review app anymore; we build it on engine + Asset Transformer.

## Step 2 — Pipeline divergence decision
- Fidelity wants HDRP, but **the target is a standalone Quest 3 headset → HDRP is too heavy. Use URP.** This is the key trade-off: photoreal desktop review and headset review are different builds. We optimize for the headset (URP, mobile constraints).

## Step 3 — Dataprep (the six-phase workflow — where the project is won or lost)
1.8M parts will never render raw on a mobile GPU. Run Asset Transformer dataprep, ideally headless via the **Asset Transformer SDK** (Python, file-to-file batching) so it's repeatable:
1. **Import** — CATIA (.CATProduct) → tessellated meshes. Tune tessellation (Max sag / Max angle / Max length) to a medium preset; over-fine tessellation is the #1 cause of bloated CAD imports.
2. **Heal** — repair geometry.
3. **Stage** — generate UVs, bake AO, assign materials → master LOD0.
4. **Optimize** — **hidden/interior removal** (engines are mostly occluded internals — this can drop part/triangle count dramatically), **defeaturing** (remove tiny fillets/holes/fasteners below a size threshold), **instancing & merging** of repeated parts (bolts/brackets).
5. **Generate LODs** — LOD0–3 via decimation.
6. **Export** — Unity Prefab (or GLB w/ Draco+KTX2). **Preserve PMI + product hierarchy + part metadata** so subsystems stay selectable and readable.

> In-editor alternative: Toolkit → Toolbox → Import Model → CAD Importer ScriptableObject. With >10k meshes, choose **Scene import mode**, not Prefab mode.

## Step 4 — Scene structure for show/hide + metadata
- Keep the imported hierarchy (Asset Transformer preserves occurrence/component structure). Subsystem nodes map to GameObjects you can toggle.
- Store imported metadata (part number, material, PMI) on a component per part; read it on selection.
```csharp
public class PartMetadata : MonoBehaviour {     // populated from imported metadata at build time
    public string PartNumber, Subsystem, Material;
    [TextArea] public string Pmi;
}
```

## Step 5 — Rendering at scale (URP, Unity 6)
Enable the draw-call killers (engine has huge instanced/occluded part counts):
1. *Project Settings → Graphics → Shader Stripping → BatchRendererGroup Variants = Keep All*.
2. URP Asset → **SRP Batcher** on, **GPU Resident Drawer = Instanced Drawing**.
3. Universal Renderer → **Rendering Path = Forward+**, **GPU Occlusion Culling** on (huge win for a dense, self-occluding engine).
4. Ensure **Render Graph** is enabled (Compatibility Mode off) — required for the above.
5. Confirm LOD Groups from dataprep are intact; tune transition distances.

## Step 6 — VR setup (Workflow 4)
1. XR Plug-in Management → Android tab → enable **OpenXR** + **Unity OpenXR: Meta**; add the Quest interaction profile.
2. Add **XR Origin**, import **XRI Starter Assets**, wire **Input Readers**.
3. Interactors: **Near-Far Interactor** per hand (ray to point at distant parts, grab up close); **Poke** for the in-world UI panel. Locomotion: **Teleportation Provider** + Teleportation Area on the floor, plus Continuous Move for fine inspection.
4. Selection → raycast hit → read `PartMetadata` → show in a world-space panel (uGUI world-space canvas with Tracked Device Graphic Raycaster, or a UI Toolkit world-space panel — verify maturity).

## Step 7 — VR performance (mobile constraints)
- **Single Pass Instanced** stereo rendering (required).
- **4x MSAA**, **Fixed/Eye-tracked Foveated Rendering** (`XRDisplaySubsystem.foveatedRenderingLevel`).
- Graphics API **Vulkan**; avoid full-screen post; baked lighting.
- Budget: aim well under the per-frame draw-call/triangle ceiling for 72–90Hz; this is why dataprep decimation + occlusion removal in Step 3 is non-negotiable.

## Gotchas hit
- **"It imported but Unity froze / the build is 40GB"** → tessellation too fine and no decimation; the project lives or dies on Step 3. Prefer headless SDK batching so settings are tracked in git.
- **"HDRP looked amazing on desktop but won't run on Quest"** → expected; headset target must be URP. Two pipelines if you also want a desktop photoreal build.
- **Picked the wrong license** → industrial customers can't buy Pro; Industry is mandatory and is what gives you Asset Transformer anyway.
- **Lost part metadata** → ensure metadata/PMI preservation is on during import; it's how selection/inspection works.

## Result
A Quest 3 VR design-review app: 1.8M-part CATIA assembly reduced via the Asset Transformer six-phase pipeline (heal → UV/AO → hidden-removal + defeature + instance → LODs), rendered in URP with GPU Resident Drawer + occlusion culling, navigated with XRI 3.x Near-Far interactors + teleport, with per-part metadata/PMI surfaced on selection — all on the Unity Industry license that bundles the CAD tooling.
