# Unity for CAD / Industrial / Enterprise Visualization (Priority)

> **Currency:** Researched June 2026, Unity 6.x era. Firm facts corroborated by official Unity/Pixyz docs. Items flagged ⚠️ should be re-verified directly with Unity — this domain shifts fast and Unity rebranded products through 2025–2026.

## TL;DR — The Big Shifts

1. **Pixyz is now "Unity Asset Transformer."** The Pixyz line was rebranded in 2025. The Unity Editor package is now the **Asset Transformer Toolkit** (`com.unity.industry.toolkit`).
2. **Unity Reflect is DEAD.** End-of-sale/EOL (≈mid-2024 ⚠️). No turnkey replacement — AEC/BIM now goes through Asset Transformer + a self-built Unity app.
3. **Industrial customers cannot buy Unity Pro.** Companies over $1M/yr total revenue are routed to **Unity Industry** (~$4,950/seat/yr).
4. **Unity 6** added **GPU Resident Drawer + GPU Occlusion Culling** — the key tech for rendering massive multi-million-part CAD assemblies.

## 1. Unity Industry License

Enterprise tier for **non-game/industrial** customers. Since April 2023 segmentation, industrial customers **cannot purchase Unity Pro** — required onto Industry. Threshold: **>$1M/yr total company revenue** (not just Unity-derived).

**A seat includes:** Unity Enterprise editor (full Pro/Enterprise + source access + cloud collaboration); **Unity Asset Transformer Toolkit** (formerly Pixyz Plugin — CAD/BIM/point-cloud ingestion, tessellation, decimation, LOD, optimization — the headline value-add); AR/VR/XR tooling (current path: **PolySpatial** for visionOS/Quest/Android XR; ⚠️ older listings still name deprecated Unity MARS); Unity Cloud/DevOps (VCS, asset management, build servers); premium support; **+1 extra year of LTS** (3 years total); 300+ hrs training; floating-license option.

**Targets:** manufacturing, automotive, AEC, aerospace, energy, defense — any non-gaming real-time 3D.

| Tier | Figure | Notes |
|---|---|---|
| **Unity Industry** | ~$4,950/seat/yr | Industrial customers required onto it |
| Unity Pro (reference) | ~$2,200/yr/seat | Industrial customers **barred** |
| Unity Enterprise | revenue >$25M/yr | Priced on demand |

⚠️ **2025 revenue-fee (single-source, verify):** Unity reportedly reintroduced a revenue-based **"Distribution License"** for commercial runtime distribution of non-gaming industrial apps (~$450/month/seat + 4% of software revenue). Confirm with Unity sales — policy here is volatile.

## 2. Pixyz → Unity Asset Transformer Product Family

One shared CAD-prep engine underlies all products (Pixyz acquired by Unity 2020, rebranded 2025).

| New Name (2025–26) | Old Pixyz Name | Latest | Role |
|---|---|---|---|
| **Asset Transformer SDK** | Pixyz SDK | 2026.4 | Python/C# library + file-to-file batching engine (Win/Linux/macOS). Headless automation. |
| **Asset Transformer Studio** | Pixyz Studio | 2026.4 | Standalone desktop CAD prep/optimization GUI + viewer. |
| **Asset Transformer Toolkit** | Pixyz Plugin | 3.3.0 | Unity Editor package (`com.unity.industry.toolkit`), entitled to active Industry subscribers. |

**Legacy:** **Pixyz Scenario/Scenario Processor → DEPRECATED** (replaced by the SDK's file-to-file batching; migrate `PiXYZScenarioProcessor.exe myScript.py` → `python myScript.py`). **Pixyz Review** → ⚠️ presumed discontinued. **Toolkit components:** Toolbox (prep/transform), Rule Engine (automation), LOD Generator, UV Viewer. ⚠️ Legacy Pixyz Plugin 2.0 had to be updated to 2.0.12 before Nov 28, 2025 to migrate.

## 3. CAD Import — Supported Formats

SDK/Studio/Toolkit share the import engine. CAD stores **exact parametric geometry** (B-rep, NURBS, CSG) — **non-tessellated**, must be converted to meshes for real-time.

| Format | Extensions | Version Range |
|---|---|---|
| **CATIA V5** | .CATPart, .CATProduct | up to V5-6R2026 |
| CATIA V4 / V6 / 3DXML | .model, .3dxml | V4 ≤4.2.5 / 3DXML |
| **NX / Unigraphics** | .prt | UG11 → NX2512 |
| **Creo / Pro-E** | .asm, .prt, .neu | Pro/E 19 → Creo 11 |
| **SolidWorks** | .sldasm, .sldprt | 97 → 2026 |
| **STEP** | .step, .stp, .stpz | AP203/AP214/AP242 |
| IGES | .iges, .igs | 5.1–5.3 |
| **JT** | .jt | up to v10.6 |
| **IFC** | .ifc, .ifczip | IFC2 ≤2.3 / IFC4 ≤4.0.2 |
| **Revit** | .rvt, .rfa | 2015 → 2025 |
| Alias | .wire | up to 2024 (Win-only) |
| Parasolid | .x_t, .x_b | up to 38.0 |
| Inventor | .iam, .ipt | up to 2025 |
| Solid Edge | .par, .asm | up to 2026 |
| Rhino3D | .3dm | 4 → 8 |
| ACIS | .sat, .sab | up to 2025 |
| AutoCAD 3D | .dwg, .dxf | up to 2024 |
| Navisworks | .nwc, .nwd, .nwf | 2012 → 2025 |

**Mesh/exchange/point cloud:** 3DS, 3MF, COLLADA, FBX, **glTF/GLB 2.0**, OBJ, PLY, STL, U3D, **USD/USDZ**, VRML, .pxz, PRC, PDF; point clouds E57, PTS, PTX, ReCap (.rcp/.rcs). **Export:** 3DXML, COLLADA, FBX, glTF/GLB, JT, OBJ, PDF, PRC, .pxz, STL, USD, **Unity Prefab (.prefab)** (Win-only: Alias, SketchUp, CreoView, ReCap, VRED, Prefab).

**Tessellation (B-rep→mesh):** CAD faces are `BRepShape`; output `TessellatedShape`. Controlled by three classic parameters (low/medium/high/custom presets): **Max sag** (chordal deviation), **Max angle** (facet normal deviation), **Max length** (max edge length). ⚠️ Exact 2026.4 API parameter names — verify in the Python API reference.

## 4. Data Prep & Optimization for Massive Assemblies

The standard **six-phase dataprep workflow** (the core industrial "black magic"):

1. **Import** — CAD → tessellated meshes.
2. **Fix (Healing)** — repair geometry.
3. **Stage** — enrich to 100%: UV generation, materials, **AO baking** → master (LOD0).
4. **Optimize** — reduce poly/file size of LOD0.
5. **Generate LODs** — aggressive decimation → LOD0/1/2/3+.
6. **Export** — compressed (GLB with **Draco** geometry + **KTX2** textures).

SDK algorithm categories: **CAD · Healing · Optimization · Combine and bake · Reconstruction · UVs.**

| Capability | Notes |
|---|---|
| Decimation / mesh reduction | Optimize + LOD steps |
| Defeaturing | Removes holes/fillets/small features |
| **Hidden/interior removal** | Occlusion-based removal of unseen geometry — critical for assemblies |
| UV generation + AO bake | Stage phase |
| Retopology | "Reconstruction" |
| LOD generation | Dedicated phase + LOD Generator |
| Instancing & merging | "Combine and bake" — cut draw calls |
| Metadata / PMI / hierarchy | Engineering metadata + **PMI** preserved; product structure preserved |

**Large-assembly gotcha:** files >10,000 meshes trigger a complexity warning recommending **Scene** import mode over **Prefab** mode.

**Import pipeline (Toolkit 3.3):** Toolbox → Import Model → creates a **CAD Importer ScriptableObject** in `3DModels/` (source link + params) → configure Model/Rule Engine/LOD tabs → choose Import Mode (Prefab default, Scene for >10k meshes) → Import (re-importable by editing the ScriptableObject + Re-import).

## 5. Unity Reflect — DISCONTINUED
Former AEC/BIM family (Reflect Review/Develop/Viewer with live Revit/Navisworks/BIM 360 sync). **Status: end-of-sale/EOL ≈June 2024** ⚠️. **No drop-in replacement** — decomposed into **Asset Transformer (ingestion/optimization)** + **Unity Industry (self-built app)**. No automatic migration.

## 6. Digital Twins, Industrial XR & Rendering at Scale

**Digital twins:** Unity ships **no monolithic twin product** — engine + Asset Transformer + connectors as a **platform**. Real-time/IoT via Unity networking, REST, MQTT, OPC-UA, custom connectors (⚠️ no first-party "IoT SDK"). Simulation via synthetic-data tools, ML-Agents, physics. AEC/BIM flows through Asset Transformer.

**Industrial XR:** **PolySpatial** (visionOS/Vision Pro + Quest + Android XR) for high-fidelity design review & training; **Meta Quest** via OpenXR; **AR Foundation** for on-site field AR overlaying BIM/CAD; **remote collaboration** built on Unity multiplayer (Netcode) or partners (no packaged Reflect-style collab app remains).

**Rendering large models in Unity 6:**
| Feature | Why it matters for CAD |
|---|---|
| **GPU Resident Drawer** | Renders very high part counts without CPU draw-call bottleneck |
| **BatchRendererGroup** | Foundation for millions of parts |
| **GPU Occlusion Culling** | Skips occluded interior parts of dense models |
| **GPU Instancing** | Repeated fasteners/bolts/beams in one draw |
| **Mesh LOD / LOD Groups** | Triangle-budget management |
| **HDRP** | Photorealistic design review |

**Gotchas:** GPU Resident Drawer requires SRP Batcher + URP/HDRP with Render Graph + supported platforms. **HDRP is too heavy for standalone XR (Quest)** — use **URP** for headsets; the high-fidelity path and XR path often diverge (plan two pipelines). **Asset Transformer prep is effectively mandatory upstream** — raw CAD must be tessellated/decimated/cleaned before any rendering tech performs well.

> Confidence: High — Pixyz→Asset Transformer rebrand + versions; CAD format table; six-phase workflow; Industry $4,950/seat + segmentation; Reflect discontinued; GPU Resident Drawer/BRG/occlusion. Verify directly: exact Reflect EOL date, 2025 revenue-fee terms, PolySpatial/Quest/Android-XR timeline, exact XR SKU bundled in Industry.
