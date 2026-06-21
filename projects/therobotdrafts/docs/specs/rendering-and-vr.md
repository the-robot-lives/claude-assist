# Rendering & VR Specification

> This document specifies the two halves of The Robot Draft's visual subsystem: the **layout
> engine** that positions a unified software model in 3D as nested packed spheres ("bubbles"),
> and the **render/performance pipeline** that draws that layout fast enough to hold a VR frame
> budget on million-element graphs. It is written for Unity and graphics engineers building the
> system. It assumes familiarity with Unity's render loop, compute shaders, and the DOTS stack.

Read this alongside [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (the end-to-end pipeline and where
layout/render sit in it), [`../CONCEPTS.md`](../CONCEPTS.md) (what a *bubble*, *HLOD proxy*, and
*model vs. projection* mean), and [`design-conventions.md`](design-conventions.md) (visual
treatment, color, and label rules). This spec owns the *how* of positioning and drawing; those
documents own the *what* and *why*.

---

## 1. Overview

The visual subsystem is two stages in one direction: **layout produces positions, rendering
consumes them.** The layout engine reads the Unified Model — a graph of packages, classes,
methods, and their relationships — and assigns every element a position, a radius, and a
containment parent. The render pipeline takes those positions and draws them, every frame, within
a fixed time budget regardless of graph size.

| Half | Input | Output | Runs | Frequency |
|------|-------|--------|------|-----------|
| **Layout engine** (§2) | Unified Model graph | Positions, radii, containment, edge routes | Off the frame loop | On model change, then incrementally |
| **Render pipeline** (§3) | Positions + camera + view state | Pixels in both eyes | On the frame loop | Every frame (90 Hz target) |

The two halves are decoupled by design. Layout is allowed to be slow and is amortized across many
frames; the render pipeline must never block on it. This separation is the same rule stated in
[`../ARCHITECTURE.md`](../ARCHITECTURE.md): *heavy work is decoupled from the frame loop.* The
shared contract between them is a set of tightly packed GPU buffers (node positions, radii, colors,
LOD tiers, edge endpoints) that layout writes and rendering reads.

The dominant constraint is VR. At a 90 Hz target the entire frame — both eyes, minus compositor
overhead — must complete in **~11.1 ms** (§4). Everything below is shaped by that number.

---

## 2. Layout engine

The layout engine answers one question per element: *where in space does this go, and how big is
it?* Different questions about the model want different answers, so the engine is not a single
algorithm but a small family, each tuned to a view. The default view — the one the product is
named for — is the **bubble view**.

### 2.1 The bubble view: sphere packing

The bubble view encodes two things the model carries strongly: **containment** (a method is inside
a class is inside a package) and a **node metric** (size, significance, complexity). Sphere packing
expresses both directly. Each element is a sphere; a parent sphere physically contains its
children; a sphere's radius encodes its metric.

The algorithm is **enclosure-based circle packing extruded into 3D** — the D3 `pack` layout's
sphere analogue. It packs children inside a parent recursively, bottom-up:

1. **Leaf sizing.** Each leaf (method, field) gets a radius from its node metric (default: a
   function of LOC or cyclomatic complexity; see [`design-conventions.md`](design-conventions.md)).
2. **Child packing.** For each internal node, pack its already-sized children into the smallest
   enclosing sphere using a front-advancing pack (the 3D generalization of Wang et al.'s
   front-chain circle packing). The enclosing radius becomes that node's radius.
3. **Recurse to root.** Repeat up the tree until the root package is packed. The result is a single
   nested hierarchy of spheres, stable for a given tree.

| Property | Value | Why it matters |
|----------|-------|----------------|
| Hierarchy | Full, strict tree | Matches code containment exactly |
| Metric channels | One (radius) | Encodes a single chosen metric per element |
| Scale | 10²–10⁴ per packed level | Comfortable; deep trees handled by HLOD (§3) |
| Stability | High (deterministic for a fixed tree) | Stable addresses across edits enable evolution views |
| 3D/VR fit | Moderate–high | Strong gestalt; sphere **self-occlusion** is the main limit |

The known weakness is self-occlusion: a sphere hides what is behind and inside it. The render
pipeline mitigates this with transparency/shell rendering for ancestor bubbles and with drill-down
(flying *into* a bubble dissolves its shell). Layout itself does not try to solve occlusion — that
is a rendering and interaction concern.

**Stable addresses.** Packing is deterministic given a tree, but small model changes (a new method)
must not reshuffle the whole world. The engine seeds each node's pack order from a stable key
(qualified name hash), so adding a child perturbs only its siblings' local packing, not distant
subtrees. This is what makes evolution views legible: a class stays roughly where it was between
commits.

### 2.2 Drill-down and complementary views

The bubble view is the home view, not the only one. When the user asks a question the bubble view
answers poorly — "what calls this?", "what is the inheritance chain?", "what is semantically near
this?" — the engine projects the relevant subgraph into a view built for that question. These run
on demand over a selected region, not over the whole model.

| View | Algorithm family | Answers | When invoked |
|------|------------------|---------|--------------|
| **Bubble** (home) | Sphere packing | Containment + metric structure | Default |
| **Call / inheritance** | Hierarchical / Sugiyama (rank → Z, stacked planes) | Directed flow: call chains, build order, inheritance | "Trace calls", "show hierarchy" |
| **Dependency cloud** | Multilevel force-directed (FM³ / sfdp / Yifan Hu) | Macro shape of a huge dependency graph | Whole-system structural overview |
| **Semantic cloud** | UMAP-3D (or MDS) over code embeddings | Similarity, co-change, conceptual proximity | "What's like this?", co-change analysis |
| **Community macro-view** | Louvain / Leiden clustering | Emergent module/architecture boundaries | Architecture review |

Sugiyama is **stable** and maps cleanly to 3D by assigning rank to the Z axis and laying each rank
on a plane — ideal for call, build, and inheritance graphs. Force-directed layouts give the best
*cluster* gestalt but the **worst edge occlusion**, so they are reserved for overview clouds where
individual edges are not the point. The multilevel variants scale to 10⁵–10⁶+ nodes using a
**Barnes-Hut octree** for the N-body force approximation — and that octree is reused as the
render/picking spatial index (§3.4), so the layout cost is not wasted.

### 2.3 Edge strategy

Edges are the hard problem in 3D software visualization. Drawing every dependency as a line
produces an unreadable, occluding cloud. The engine never draws all edges at once. Three rules:

1. **On-demand and hop-limited.** Edges appear in response to selection or query, limited to N hops
   from the focus. The resting bubble world shows containment (spatial) and little else.
2. **Bundled.** When many edges are shown, they are routed with **Hierarchical Edge Bundling** along
   the containment tree — a near-perfect fit, since the code tree is exactly the hierarchy HEB
   needs. Bundling collapses parallel edges into shared paths, cutting both visual clutter and
   render overdraw. Bundle control paths (FDEB) are precomputed off the frame loop.
3. **Promoted to a dedicated view for tracing.** When the user genuinely needs to follow every
   edge in a flow, the answer is to switch to the Sugiyama call view (§2.2), not to flood the
   bubble view.

Edge *rendering* (how a routed edge becomes pixels, edge LOD, culling) is specified in §3.6.

### 2.4 Layout family reference

The full design space, for engineers choosing a layout for a new view:

| Family | Best data profile | Hierarchy | Scale | Stable | 3D/VR fit | Software-viz use |
|--------|-------------------|-----------|-------|--------|-----------|------------------|
| Force-directed (FR, ForceAtlas2, stress) | General clustered | None | 10²–10⁵ (Barnes-Hut octree) | No | High cluster fit / **worst edge occlusion** | Dependency clouds |
| Multilevel force-directed (FM³, sfdp, Yifan Hu) | Large undirected | None | 10⁵–10⁶+ | No | Overview only | Huge dependency graphs |
| Hierarchical / Sugiyama (dot, dagre, ELK) | Directed DAGs | Ranked | 10²–10⁴ | **Yes** | Moderate (rank → Z, stacked planes) | Call / build / inheritance |
| Treemap (squarified) / 3D treemap | Strict tree + metric | Full | 10³–10⁴ | Yes | High | Containment + metrics (code cities) |
| **Circle / sphere packing (D3 pack)** | Strict tree + 1 metric | Full | 10²–10⁴ | Yes | Moderate–high (**self-occlusion**) | **The nested bubble view** |
| Community clustering (Louvain / Leiden) | Large modular | Emergent | 10⁴–10⁶ | — | — | Macro-architecture |
| MDS / UMAP-3D | Similarity / embedding | None | Varies | — | Cloud | Semantic point clouds, co-change |

### 2.5 Prior art

The bubble view sits in the lineage of **code-city** visualization. CodeCity (Wettel & Lanza) maps
class → building, package → district, and a metric → building height, packed with a treemap; it was
empirically validated to beat an IDE baseline on correctness and time. The family extends through
**EvoStreets** (street layout with stable addresses for evolution) and **CodeMetropolis** (renders
the city in Minecraft). City metaphors encode containment and node metrics well and inter-class
**edges poorly** (clutter, occlusion) — the same trade-off that shapes our edge strategy (§2.3).

On the VR side, the relevant prior art is **Primitive** (commercial multi-user VR code viz, defunct
~2020), **ExplorViz** (live-trace visualization on Kieker, collaborative VR/AR over WebXR), **VR
City**, **IslandViz** (OSGi modules as an archipelago), and the broader *Immersive Software
Analytics* line. What works in immersive viz: containment/gestalt overviews, spatial memory,
collaboration, and live dynamics. The documented limits: **text legibility** (low HMD
pixels-per-degree), wayfinding, cybersickness, edge occlusion, and interaction precision. The
lesson is that **3D's advantage over a good 2D view is conditional, not universal** — which is why
the product pairs the 3D world with a 2D HUD for text and reserves 2D-friendly notations for the
diagram projection subsystem.

---

## 3. Rendering pipeline

The render pipeline turns positions into pixels every frame. At million-element scale, the naive
Unity approach — one GameObject per bubble — fails before the GPU is even involved. The pipeline is
built around three cost centers and the techniques that defeat each.

### 3.1 The three cost centers

| Cost center | What it is | Where it bites |
|-------------|-----------|----------------|
| **Per-object CPU overhead** | The cost of *iterating* objects: Transform updates, culling, draw setup | The wall you hit before the GPU is busy; ~1–2 KB + per GameObject |
| **Draw-call / state-change overhead** | CPU cost of submitting draws and switching material/mesh state | Thousands of draws stall the render thread |
| **Overdraw / fill** | Fragments shaded, especially overlapping/transparent ones | Brutal at ~2× VR resolution (§4); transparent bubble shells multiply it |

Every technique below targets one or more of these. The through-line: **stop the CPU from iterating
per object, collapse draws to a handful, and aggressively cut fill.**

### 3.2 LOD and HLOD

**Discrete `LODGroup` does not scale.** It is per-GameObject — it presumes you have a GameObject per
object, which is exactly what we cannot afford. All LOD selection happens in **Burst jobs or compute
shaders** over arrays, never via `LODGroup`.

Two LOD axes:

| LOD type | Technique | Effect |
|----------|-----------|--------|
| **Geometry LOD** | **Sphere impostors / billboards** — a sphere rendered as a single fragment-shaded quad, near-indistinguishable from a mesh sphere at distance | Highest-leverage geometry LOD; turns a mesh into one quad |
| **Label / text LOD** | Show a label only above a screen-size threshold; **budget-cap** visible labels to top-K by centrality/focus; render with SDF/MSDF (TextMeshPro) | Keeps text legible and bounded; text is the scarcest VR resource |

**HLOD is the key technique.** Hierarchical LOD collapses a whole package into a single aggregate
bubble at distance — one mesh plus a `"package X (412 classes)"` label — instead of drawing its
hundreds of children. It aligns exactly to the code hierarchy, so the same containment tree that
drives layout drives HLOD. Benefits compound:

- Cuts node count, draw calls, and CPU iteration by **orders of magnitude**.
- **Semantic HLOD doubles as UX**: a collapsed package *is* the overview the user wants at distance.
- It must be built by us — Unity's `LODGroup` is per-object and has no hierarchical mode.

The reference architecture for this class of GPU-driven, hierarchical, cluster-collapsing rendering
is **Unreal's Nanite**. **Unity has no Nanite equivalent.** We build the analogue ourselves from
compute shaders and indirect draws (§3.3) plus the octree HLOD (§3.4). This is a load-bearing fact,
not a footnote — see §5.

### 3.3 GPU instancing and indirect draws

Bubbles move (layout updates, drill-down animation), so static and dynamic batching are out. The
path to millions is **indirect drawing**.

| Technique | Per-draw count | Mechanism | Verdict for us |
|-----------|----------------|-----------|----------------|
| Static / dynamic batching | Low | CPU merges meshes | No — nodes move |
| GPU Instancing | ~1023 / draw | `MaterialPropertyBlock` | Limited |
| SRP Batcher | — | Lowers per-draw CPU, **not draw count** | Helps, insufficient alone |
| `DrawMeshInstanced` | 1023 / call | CPU-supplied array | Limited |
| **`RenderMeshIndirect` / `DrawMeshInstancedIndirect`** | **Millions** | GPU reads instance count from a `ComputeBuffer` | **The scalable path** |
| `BatchRendererGroup` | Millions | Underpins Entities Graphics | Viable (via DOTS, §3.5) |

The indirect-draw loop, which the CPU never iterates per instance:

1. Node data lives in `ComputeBuffer`s (position, radius, color, LOD tier).
2. A **compute shader** culls (§3.4), selects LOD, **appends survivors** to per-bucket append
   buffers, and writes the survivor **count** into an indirect-args buffer.
3. The GPU issues `RenderMeshIndirect`, reading the count from the buffer — it draws exactly the
   survivors, with zero CPU per-instance work.

**Bucketing.** Survivors are bucketed by `(mesh LOD) × (material)` so each bucket is one indirect
draw. The whole frame collapses to a handful of draws.

**Pack instance data tightly.** Bandwidth is a real limit on mobile (Quest). Pack position + radius
into a single `float4`, color as a `uint`, LOD/flags into spare bits. Minimizing per-instance bytes
directly lowers the compute and draw cost.

### 3.4 Culling

| Culling type | Method | Notes |
|--------------|--------|-------|
| **Frustum** | Burst jobs over arrays; GPU compute; **hierarchical over the octree/BVH** | The hierarchical form rejects a whole subtree in one test |
| **Occlusion** | **GPU Hi-Z** (hierarchical depth buffer, compute test, two-pass) | Unity's baked Umbra occlusion is **static-only** — useless for a dynamic graph |

Hierarchical frustum culling is the big win: test a parent bubble's bounds once and reject (or
accept) its entire subtree without touching the children. The octree (§3.5) makes this O(visible)
rather than O(total).

For occlusion, **do not use Unity's baked occlusion culling** — it bakes static geometry and our
graph is dynamic. Use **GPU Hi-Z**: build a hierarchical depth pyramid, test bounds against it in
compute, in the standard two-pass form (draw last-frame-visible set, build Hi-Z, re-test the rest).
This is the same approach Nanite and Unity 6's GPU occlusion use.

### 3.5 Spatial structures and DOTS

**Spatial structures.** Build them in `NativeArray`s, process them in Burst.

| Structure | Primary use | Role |
|-----------|-------------|------|
| Uniform grid / spatial hash | Neighbor queries, GPU broad-phase | Layout proximity, collision |
| **Octree** | Hierarchical frustum cull + HLOD + Barnes-Hut layout | **Recommended primary structure** — reused across layout, cull, and HLOD |
| BVH | Raycast / picking | VR controller selection in O(log n) |
| k-d tree | Static nearest-neighbor | Static analyses only |

The **octree is the spine** of the system: it indexes layout (Barnes-Hut, §2.2), drives
hierarchical culling (§3.4), and defines HLOD cells (§3.2) and streaming residency (§3.7). One
structure, four jobs. The BVH is the picking companion for VR controller rays.

**DOTS is the load-bearing engine decision.** Classic GameObject/MonoBehaviour tops out at a few
*thousand* moving, rendered objects: ~1–2 KB + overhead each, Transform churn, cache-unfriendly
layout, and — fatally for VR — **GC hitches that cause judder.** In VR, judder is intolerable.

| DOTS layer | What it gives |
|------------|---------------|
| **ECS** | Archetype chunks; millions of entities is routine; cache-friendly |
| **Burst** | SIMD-compiled native code, 10–100× over managed C# |
| **Jobs** | Safe multicore parallelism |
| **Entities Graphics** | `BatchRendererGroup`-based instancing + LOD |

Recommended flow: **ECS data → Burst jobs (layout, cull, LOD) → Entities Graphics *or* custom
`RenderMeshIndirect` + compute.** Use the custom indirect path where you need GPU-driven Hi-Z and
HLOD beyond what Entities Graphics offers; a hybrid (Entities Graphics for the simple case, custom
indirect for the deep GPU-driven path) is common and expected.

### 3.6 Edge rendering

Layout decides *which* edges exist and how they route (§2.3); this section draws them.

**Never use `LineRenderer`.** It is per-object and fatal at scale. All edges are GPU geometry drawn
via `RenderMeshIndirect`: a vertex/geometry shader expands each edge into a screen-space-thickened
quad; only near or selected edges become true tubes.

| Edge LOD tier | Representation |
|---------------|----------------|
| Near | Thickened tube |
| Mid | Screen-space quad line |
| Far | 1 px line, or omitted |
| Package collapsed (HLOD) | **Aggregate bundle edge** — `"47 dependencies"` |

**Cull edges in compute**: drop any edge under ~1 px or with **both endpoints culled** before it
reaches the rasterizer. **Bundle** (HEB along the code tree; FDEB precomputed) to cut clutter and
overdraw. Use **additive blending** for order-independent glow (no sort needed), and **cap the
visible edge count** the same way labels are capped.

### 3.7 Streaming

Million-element graphs are out-of-core. Keep resident only the **focus neighborhood** plus the
**visible HLOD proxies**; page distant detail by octree cell or subgraph.

- **Predict** what to page in from **gaze and velocity** — load ahead of where the user is heading.
- **Page** via Addressables or Entities subscene streaming, asynchronously.
- **Amortize** per frame: cap entities created and bytes uploaded per frame so a load never blows
  the budget.
- **Reuse buffers** — pooled `ComputeBuffer`s and `NativeArray`s, **zero per-frame allocation**, so
  the GC never runs and never stalls a frame.
- **Hysteresis** on residency thresholds to avoid load/unload thrash at boundaries.

---

## 4. VR specifics

VR is the constraint that shapes every choice above. The frame must render **both eyes** and clear
the **compositor** within the refresh budget.

| Target | Refresh | Per-frame budget (both eyes, minus compositor) |
|--------|---------|-----------------------------------------------|
| Quest | 72 fps | ~13.9 ms |
| Standard | 90 fps | **~11.1 ms** |
| High | 120 fps | ~8.3 ms |

Fill is computed at roughly **2× display resolution** (super-sampling for lens distortion), which
is why overdraw (§3.1) is the harshest cost center.

**Stereo rendering.**

- Cull **once** against a single combined frustum that bounds both eyes — never cull per eye.
- Use **Single-Pass Instanced** (PC) / **Multiview** (Quest) to halve draw-submission CPU.
- Custom indirect shaders **must be stereo-aware**: read `unity_StereoEyeIndex` and emit per-eye
  geometry correctly. This is a common source of "renders in editor, broken in headset" bugs.

**Foveation.** Render the periphery cheaper.

- **FFR** (Fixed Foveated Rendering) cuts peripheral fill unconditionally.
- **ETFR** (Eye-Tracked Foveated Rendering, Quest Pro / PSVR2) follows the gaze for a larger saving.
- **Pair foveation with gaze-driven LOD and labels** (§3.2): the same gaze signal that lowers
  peripheral shading should lower peripheral geometry detail and suppress peripheral labels.

**Reprojection is a safety net, not a plan.** ASW / AppSW (Quest half-rate synthesis from motion
vectors + depth) catches a dropped frame, but it smears on disocclusion and is not a substitute for
hitting the budget. If you rely on custom indirect shaders, they **must emit correct motion
vectors**, or AppSW will produce artifacts.

**Comfort and locomotion.** Per the prior-art limits (§2.5): pair the 3D world with a 2D HUD for
text, offer a **table-top mode** (the model scaled down in front of a seated user), and use
**teleport locomotion** to avoid the vection that causes cybersickness.

---

## 5. Recommended architecture

The end-to-end runtime pipeline, in order. Each stage feeds the next; the CPU never iterates
instances past stage 2.

1. **Data.** DOTS ECS holds nodes and edges. An **octree** (cull / HLOD / layout) and a **BVH**
   (picking) live in `NativeArray`s.
2. **CPU (Burst, multicore).** HLOD selection, coarse subtree frustum cull, Barnes-Hut layout, and
   label top-K selection — all writing into **compacted GPU buffers**.
3. **GPU (compute).** Fine frustum + **Hi-Z occlusion** culling → **compaction** → indirect-args
   buffers, with **separate buffers per LOD bucket and for edges**.
4. **Draw.** A handful of `RenderMeshIndirect` calls under **Single-Pass Instanced / Multiview**
   stereo; labels as instanced SDF quads, budget-capped.
5. **VR.** FFR / ETFR foveation; AppSW with correct motion vectors as margin.
6. **Streaming.** Octree-cell residency, predictive (gaze/velocity) paging, amortized async loads,
   pooled buffers with **zero per-frame allocation**.

### Critical correctness notes

These are the mistakes that look fine in a prototype and fail at scale or in the headset. Treat them
as non-negotiable.

| Constraint | Wrong assumption | Correct approach |
|------------|------------------|------------------|
| **No Nanite in Unity** | "Unity has a Nanite-like GPU pipeline" | Build the GPU-driven equivalent: compute + indirect draws + Hi-Z + octree HLOD |
| **Baked occlusion is static-only** | "Use Unity occlusion culling" | Use **GPU Hi-Z** — baked Umbra cannot cull dynamic geometry |
| **`LODGroup` is per-GameObject** | "Use `LODGroup` for LOD/HLOD" | Do LOD **and** HLOD in Burst / compute over arrays |
| **`LineRenderer` is per-object** | "Draw edges with `LineRenderer`" | Edges as GPU geometry via `RenderMeshIndirect` |
| **GC hitches = VR judder** | "Allocate as needed; GC is fine" | **DOTS + zero per-frame allocation**, non-negotiable — the hardest VR constraint |

---

## See also

- [`../ARCHITECTURE.md`](../ARCHITECTURE.md) — the full pipeline and where layout/render sit in it.
- [`../CONCEPTS.md`](../CONCEPTS.md) — bubbles, containment, HLOD proxies, model vs. projection.
- [`design-conventions.md`](design-conventions.md) — visual treatment, color, metric-to-radius
  mapping, and label rules referenced throughout §2 and §3.
