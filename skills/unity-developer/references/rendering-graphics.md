# Unity 6 Rendering & Graphics Pipeline

*Current as of Unity 6.0 (`6000.0`) / 6.1 / 6.2 — SRP packages v17.x. Verify exact patch behavior against your installed editor; 6.1/6.2 deltas are flagged where uncertain.*

## 1. Render Pipelines: BiRP vs URP vs HDRP

In Unity 6, **URP and HDRP are SRP-based** (scriptable in C#), versioned together as **package v17.x** (`com.unity.render-pipelines.universal` / `.high-definition`). The **Built-in Render Pipeline (BiRP)** is legacy and frozen (no new features) but still supported.

| Concern | Built-in (BiRP) | URP (v17) | HDRP (v17) |
|---|---|---|---|
| Target platforms | All (legacy) | Mobile, WebGL/WebGPU, Switch, XR, mid-spec PC/console | High-end PC, PS5, Xbox Series (no mobile/web) |
| Customization | Limited | High (ScriptableRendererFeature, Render Graph) | Highest (full SRP + frame settings) |
| Visual ceiling | Moderate | Good, scalable | Cutting-edge (PBR, ray/path tracing) |
| Ray/path tracing | No | No | Yes (DXR) |
| Scalability | Manual | Excellent (Quality tiers, render scale) | Poor (high-end only) |
| When to choose | Existing BiRP project | **Default for new cross-platform games** | AAA-fidelity on fixed high-end HW |

**Guidance:** New projects → **URP** unless you specifically target only high-end hardware and need HDRP-exclusive features (volumetric clouds/fog, physical lights/camera, SSGI, ray/path tracing). **BiRP→SRP migration is non-trivial** (materials/shaders/lighting re-authored). **You cannot easily switch URP↔HDRP** — choose early. APV, Volume framework, Shader Graph, SRP Batcher, and STP exist in both.

## 2. Render Graph (URP/HDRP, Unity 6)

In Unity 6, **Render Graph is the default execution model**. The legacy path is retained as **Compatibility Mode (Render Graph Disabled)**, which is **deprecated** and slated for removal.

- **Toggle:** `Project Settings > Graphics > Render Graph > Compatibility Mode (Render Graph Disabled)`. GPU Resident Drawer, GPU occlusion culling, and Native Render Pass merging require Render Graph (Compatibility Mode **off**).
- **Render Graph Viewer:** dedicated window — visualizes passes, resource lifetimes, and merges.

**What it does:** automatic GPU resource management — allocates a texture only just before its first writing pass, frees after its last reader; reuses memory; **culls passes whose output is unused**; **merges passes into a single native render pass** on tile-based (mobile) GPUs (big mobile bandwidth win).

**Writing a ScriptableRenderPass (Render Graph API):** the old `Execute(ScriptableRenderContext, ref RenderingData)` is replaced by **`RecordRenderGraph(RenderGraph, ContextContainer)`**.

```csharp
class MyPass : ScriptableRenderPass {
  class PassData { public TextureHandle src; }

  public override void RecordRenderGraph(RenderGraph rg, ContextContainer frameData) {
    var resources = frameData.Get<UniversalResourceData>();   // camera color/depth, etc.
    using (var builder = rg.AddRasterRenderPass<PassData>("My Pass", out var data)) {
      data.src = resources.activeColorTexture;
      builder.UseTexture(data.src);                                  // declare read
      builder.SetRenderAttachment(resources.activeColorTexture, 0); // declare write
      builder.SetRenderFunc((PassData d, RasterGraphContext ctx) => {  // MUST be static-safe
        Blitter.BlitTexture(ctx.cmd, d.src, new Vector4(1,1,0,0), 0, false);
      });
    }
  }
}
```

**Key API:** pass builders `AddRasterRenderPass<T>`, `AddComputePass<T>`, `AddUnsafePass<T>` (legacy `SetRenderTarget` escape hatch). Builder: `UseTexture`, `UseBuffer`, `SetRenderAttachment`, `SetRenderAttachmentDepth`, `AllowPassCulling`. Frame data via `ContextContainer`: `UniversalResourceData`, `UniversalCameraData`, `UniversalLightData`. Inject via a `ScriptableRendererFeature` calling `renderer.EnqueuePass(pass)`.

## 3. Shaders

URP/HDRP shaders are HLSL inside ShaderLab; **Shader Graph** (`com.unity.shadergraph` v17.x) is the visual path. All generated shaders run under Render Graph.

**Shader Graph (v17):** Targets declared in Graph Settings (URP/HDRP/BiRP). **Heatmap color mode** tints nodes by instruction cost. Sub Graphs (reusable clusters, dropdown branch nodes), Custom Interpolators, per-node live preview, Custom Render Texture graph type.

**HLSL for URP (SRP) — SRP Batcher compatible:**
```hlsl
Shader "Example/URPUnlit" {
  Properties { _BaseColor("Color", Color) = (1,1,1,1) }
  SubShader {
    Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }  // required tag
    Pass {
      HLSLPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
      CBUFFER_START(UnityPerMaterial)   // <-- required for SRP Batcher
        half4 _BaseColor;
      CBUFFER_END
      struct Attributes { float4 positionOS : POSITION; };
      struct Varyings  { float4 positionHCS : SV_POSITION; };
      Varyings vert(Attributes IN){ Varyings o; o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); return o; }
      half4 frag() : SV_Target { return _BaseColor; }
      ENDHLSL
    }
  }
}
```
**Never mix** BiRP `UnityCG.cginc` with SRP includes. All per-material props must sit in `CBUFFER_START(UnityPerMaterial)…CBUFFER_END` with identical layout across passes, or the object drops out of the SRP Batcher.

**GPU instancing (HLSL):** `#pragma multi_compile_instancing`, `UNITY_INSTANCING_BUFFER_START/END`, `UNITY_DEFINE_INSTANCED_PROP`, `UNITY_SETUP_INSTANCE_ID`, `UNITY_ACCESS_INSTANCED_PROP`. Struct needs `UNITY_VERTEX_INPUT_INSTANCE_ID`. Enable per-material "Enable GPU Instancing."

**Compute shaders:** `.compute` asset with `#pragma kernel CSMain`, `[numthreads(8,8,1)]`, `RWStructuredBuffer<T>`. From C#: `GraphicsBuffer`, `shader.SetBuffer`, `shader.Dispatch(kernel, gx, gy, gz)`. Dispatch inside Render Graph via `AddComputePass`.

**BRG / DOTS Instancing:** BRG shaders must support DOTS Instancing: `#pragma multi_compile _ DOTS_INSTANCING_ON`, `UNITY_DOTS_INSTANCING_START/END`, `UNITY_ACCESS_DOTS_INSTANCED_PROP`.

**Variant management:** `shader_feature` (only used variants kept) vs `multi_compile` (all combos, for runtime keyword switching). Stage-scoped suffixes (`shader_feature_fragment`, `_vertex`) cut counts. Build-time stripping via `IPreprocessShaders.OnProcessShader`; warm with `ShaderVariantCollection`.

## 4. Lighting & Global Illumination

Unity 6 centers indirect lighting on **Adaptive Probe Volumes (APV)**, superseding manually-placed Light Probe Groups.

**APV:** auto-places probes by scene geometry density using a **brick** structure (64 probes / 4×4×4 brick; adaptive spacing). **Per-pixel sampling** (each pixel reads its 8 nearest probes) → fewer seams, less leaking.

| Step | Path |
|---|---|
| Enable | Active **Render Pipeline Asset** → `Lighting > Light Probe System = Adaptive Probe Volumes` |
| Add volume | `GameObject > Light > Adaptive Probe Volume` (Mode = Global) |
| Bake | `Window > Rendering > Lighting` → **Baked Global Illumination** → **Adaptive Probe Volumes** tab → **Generate Lighting** |

Scenes group into a **Baking Set**. Fine-tune with the **Probe Adjustment Volume**. **Streaming** (both new in Unity 6): **GPU Streaming** (CPU→GPU) and **Disk Streaming** (disk→CPU). **Lighting Scenarios** store separate baked setups (day/night), blended at runtime via `ProbeReferenceVolume.BlendLightingScenario(name, factor)` (probe positions must match across scenarios). **Sky Occlusion** bakes per-probe occlusion (requires Progressive GPU Lightmapper).

**Rendering Layers** (replaces "Light Layers") restrict which objects a Light/Decal affects; Unity 6 added Rendering Layers support to APV to cut interior/exterior leaking. **Progressive GPU Lightmapper** is now production. **Reflection Probes** (baked/realtime) + HDRP screen-space reflections. Mixed lighting: Baked Indirect, Subtractive, Shadowmask, Distance Shadowmask.

## 5. Post-Processing & Upscaling

Both pipelines use the **Volume framework**: a **Volume** component → **Volume Profile** → **Volume Overrides**. **Global** volumes affect everywhere; **Local** volumes blend by collider proximity. Blend by **priority** + per-camera **weight**.

**URP effects:** Bloom, Tonemapping, Color Adjustments/Grading (LUT), White Balance, Curves, Vignette, Depth of Field, Motion Blur, Film Grain, Chromatic Aberration, Lens Distortion, Panini Projection. Camera needs **Post Processing** enabled. **HDRP adds:** physical Exposure, Screen Space Lens Flare, PBR/screen-space DoF, HDR-output grading.

**Custom post:** URP → **Full Screen Pass Renderer Feature** (Fullscreen Shader Graph or HLSL via `Blitter`). HDRP → subclass **`CustomPostProcessVolumeComponent`**.

**AA & upscalers:** MSAA (hardware), FXAA/SMAA (cheap→sharp), TAA (incompatible w/ MSAA + camera stacking), **FSR 1.0** (spatial, URP), **STP** (Unity 6 headline — cross-platform compute temporal upscaler+TAA; URP Asset → Upscaling Filter = Spatial-Temporal Post-Processing, requires SM5.0+compute, no GLES, auto-enables camera TAA, render at Render Scale <1), **DLSS/FSR2** (HDRP dynamic-res upscaler; DLSS = NVIDIA RTX).

## 6. Performance & Batching ("black magic")

**SRP Batcher:** batches bind/draw for objects sharing the **same shader variant** (not same material); persists material data in GPU buffers. URP/HDRP only. Requires `CBUFFER(UnityPerMaterial)`. **Breakers:** per-renderer `MaterialPropertyBlock`, malformed CBUFFER, excessive variants. Takes priority over GPU instancing when active.

**GPU Resident Drawer (URP/HDRP):** auto-applies GPU instancing via BatchRendererGroup → fewer draw calls, less CPU. Requires **Forward+**, compute API (not GLES), Mesh Renderers only. Enable order: (1) `Project Settings > Graphics > Shader Stripping > BatchRendererGroup Variants = Keep All`; (2) URP Asset → SRP Batcher on; (3) URP Asset → GPU Resident Drawer = Instanced Drawing; (4) Universal Renderer → Rendering Path = Forward+.

**GPU Occlusion Culling (URP):** GPU-side culling using current+previous depth. Requires GPU Resident Drawer **and** Render Graph. Enable: Universal Renderer → GPU Occlusion. **Gotcha:** in low-occlusion scenes overhead can *reduce* FPS.

**BatchRendererGroup (BRG):** low-level data-oriented rendering API (engine behind GPU Resident Drawer + Entities Graphics). Per-instance data in a `GraphicsBuffer`; shaders must support DOTS Instancing.

| Method | Mechanism | Limits |
|---|---|---|
| Static batching | Combines static meshes (world space) | ≤64k verts/buffer; higher memory |
| Dynamic batching | CPU world-transforms small meshes into one call | ≤300 verts; **not in HDRP**; rarely worth it |
| GPU instancing | One call for many copies of same mesh+material | No Skinned Mesh; per-material toggle |

**LOD & mesh:** LOD Group swaps meshes by screen-height ratio; Cross Fade mode dithers/blends. **Texture/Mipmap Streaming** loads only needed mips (`Texture2D.streamingMipmaps`, `requestedMipmapLevel`).

**Profiling:** **Frame Debugger** (step every draw, diagnose batch breaks); **Profiler** (CPU/GPU/Memory/Rendering, Deep Profile); **`ProfilerRecorder`** API + **Profile Analyzer** package; **Rendering Debugger** (runtime SRP visualization — overdraw, GPU Resident Drawer stats, STP); **Render Graph Viewer**.

> Uncertainty: HDRP-specific menu paths for APV/scenarios and DLSS/FSR2 specifics not directly fetched; some Shader Graph 17 feature names from release notes. Confirm 6.1/6.2 deltas (e.g. WebGPU maturity) against your editor.
