# M8 — Performance & Scale

Take the walking-skeleton renderer (M1) and the comprehension tools (M2) to production scale:
interactive frame rates on a million-element graph. This milestone adds GPU instancing and sphere
impostors, hierarchical frustum plus occlusion culling, LOD/HLOD, a bounded label atlas,
off-main-thread layout, and chunked streaming — all behind the frozen `IRenderer`/`ILayout`
interfaces — and measures every change with a perf-budget CI harness. An optional Babylon WebGPU
engine swap is included as a stretch task and is the practical bridge to VR later (M11). The
performance techniques are ported from the Unity `rendering-and-vr` spec as *targets*, not code:
octree spine, HLOD proxies, impostors, indirect/instanced draws, edge bundling, streaming residency.

## Entry criteria

- **M2 exit.** FE-GL renders the sphere-packed graph with orbit/focus/recenter/drill (M1) plus
  highlight-and-trace, the compass gizmo, and the metric-coloring pipeline (M2). FE-GRAPH provides
  sphere packing v1, the scene-graph LOD tree, traversal/reachability, cycle detection, and metrics.
- `IRenderer` and `ILayout` (frozen at M0) remain the abstraction boundary; all perf work lands
  behind them so the shell and graph algorithms are unaffected by the renderer internals.
- The M0 fixture pack is present; its large synthetic graph document is the seed that M8 scales up.
- **A11y invariants carry in.** M8 depends only on M2 (per the DAG it is an independent track that
  may run before or beside M3), so the M3 accessibility work may not have merged yet. Every LOD,
  HLOD, impostor, and label path built here MUST preserve non-color kind/edge encodings and honor
  reduced-motion, so the M3 accessibility stories drop in without renderer rework. Treat this as a
  standing acceptance constraint on every task below.

## Gate tasks

Front-loaded contract freezes. These unblock the lanes and are kept deliberately small.

**M8-QA-01 — Perf budget & telemetry contract** (size: S)
Define the frame-time budget (reference desktop target and headroom, plus interaction latency), the
telemetry schema (frame time, draw calls, live instance count, visible label count, culled ratio,
GPU memory, worker layout time), and how these are sampled headlessly. Unblocks the QA harness and
FE-GL instrumentation.
depends: M2 exit · stories: US-011 (enabling)

**M8-BE-API-01 — Chunked doc-load / paging protocol** (size: M)
Freeze the region/octree-cell paging contract: how a client requests a document by octree cell, LOD
tier, and focus neighborhood; the chunk envelope; and the continuation cursor. Aligns with the
GraphDocument JSON schema (M0). Unblocks server chunked reads and the FE streaming client.
depends: M2 exit · stories: US-011 (enabling)

## Lanes & tasks

### FE-GRAPH — spatial index, HLOD, off-main-thread layout

FE-GRAPH-01 is the internal spine gate: the octree it builds unblocks FE-GL culling/HLOD and
FE-GRAPH streaming, so it runs first within the lane.

**M8-FE-GRAPH-01 — Octree spatial index** (size: L)
Build an octree over node positions as the shared spine — it drives hierarchical culling (FE-GL),
HLOD cell definition, and streaming residency. One structure, three consumers.
depends: M2 exit · stories: US-011

**M8-FE-GRAPH-02 — HLOD tree** (size: L)
Aggregate each package subtree into an HLOD proxy (bounds, descendant count, representative metric)
aligned to the containment tree, so a collapsed package can render as one proxy instead of its
descendants.
depends: M8-FE-GRAPH-01 · stories: US-011

**M8-FE-GRAPH-03 — Edge bundling precompute** (size: M)
Compute Hierarchical Edge Bundling control paths along the containment tree, off the frame loop, so
edge rendering (FE-GL) can collapse parallel edges and cut overdraw.
depends: M8-FE-GRAPH-01 · stories: US-011

**M8-FE-GRAPH-04 — Off-main-thread layout** (size: L)
Move sphere packing and octree construction into a Web Worker and compile the hot path to WASM;
transfer tightly packed buffers (position+radius as a `float4`, color as a `uint`) to the main
thread so layout never stalls a frame.
depends: M8-FE-GRAPH-01 · stories: US-011

**M8-FE-GRAPH-05 — Streaming residency selection** (size: M)
From camera position and velocity, select octree cells to page in/out (focus neighborhood plus
visible HLOD proxies), predict prefetch ahead of motion, and apply hysteresis thresholds to avoid
load/unload thrash at boundaries.
depends: M8-FE-GRAPH-01, M8-BE-API-01 · stories: US-011

### FE-GL — instancing, culling, HLOD, labels, edges

**M8-FE-GL-01 — Thin-instance + impostor node rendering** (size: L)
Replace per-node meshes with Babylon thin instances and add a sphere-impostor billboard shader so
distant/low-LOD nodes draw as a single fragment-shaded quad. Removes the per-object CPU iteration
that is the first scaling wall.
depends: M8-QA-01 · stories: US-011

**M8-FE-GL-02 — Hierarchical frustum culling over the octree** (size: L)
Cull whole subtrees by testing a parent's bounds once; feed only survivors into the instance
buffers, making the cost O(visible) rather than O(total).
depends: M8-FE-GRAPH-01, M8-FE-GL-01 · stories: US-011

**M8-FE-GL-03 — Occlusion culling** (size: L)
On WebGL2, use Babylon GPU occlusion queries against HLOD proxies in a two-pass last-visible-set
form; on the WebGPU path (FE-GL-07) use a Hi-Z compute test. Static baked occlusion is unusable —
the graph is dynamic.
depends: M8-FE-GL-02 · stories: US-011

**M8-FE-GL-04 — HLOD proxy rendering** (size: L)
Draw a collapsed package as one aggregate impostor plus a `"package X (N classes)"` count label
instead of its descendants; swap proxy/expanded by screen size with hysteresis. This is the largest
single win for both draw count and the overview UX.
depends: M8-FE-GRAPH-02, M8-FE-GL-01 · stories: US-011

**M8-FE-GL-05 — Bounded label atlas** (size: M)
Render labels as MSDF quads from a shared atlas; budget-cap visible labels to top-K by
centrality/focus; keep labels legible at overview zoom (re-verifies US-024 at scale) and preserve
non-color kind/status glyphs so the a11y encoding survives LOD.
depends: M8-QA-01 · stories: US-011, US-024

**M8-FE-GL-06 — Edge rendering at scale** (size: M)
Draw edges as GPU-instanced geometry with edge LOD (near tube / mid screen-space quad / far 1px /
omitted), additive blending for order-independent glow, a visible-edge cap, and compute-side drop of
sub-pixel edges or those with both endpoints culled. Consumes the FE-GRAPH bundling precompute.
depends: M8-FE-GL-02, M8-FE-GRAPH-03 · stories: US-011

**M8-FE-GL-07 — Babylon WebGPU engine flag behind IRenderer** (size: L, optional)
Swap the WebGL2 engine for the Babylon WebGPU engine via config, enabling the compute-driven
cull/Hi-Z path; feature-detect and fall back to WebGL2. Not required for milestone exit; it is the
groundwork for VR (M11).
depends: M8-FE-GL-03 · stories: US-011 (enabling)

**M8-FE-GL-08 — Renderer instrumentation** (size: S)
Emit the M8-QA-01 telemetry (frame time, draw calls, instance/label counts, culled ratio, GPU
memory) from the render loop for the harness and the dev HUD.
depends: M8-QA-01 · stories: US-011

### FE-SHELL — streaming client and residency

**M8-FE-SHELL-01 — Chunked/streamed doc-load client** (size: M)
Consume the M8-BE-API-01 paging protocol, assembling chunks into the in-memory model incrementally
and amortizing application (cap entities and bytes applied per frame) so a large load never blows the
frame budget.
depends: M8-BE-API-01 · stories: US-011

**M8-FE-SHELL-02 — Residency manager + perf HUD** (size: M)
Drive FE-GRAPH residency selection from the camera and surface a perf HUD (frame time, live counts)
behind a dev flag for on-device profiling.
depends: M8-FE-SHELL-01, M8-FE-GRAPH-05 · stories: US-011

### BE-API / BE-CORE — server-side chunked reads

**M8-BE-API-02 — Chunked doc read endpoint** (size: M)
Serve a graph document by region / octree cell / LOD tier per the M8-BE-API-01 contract, streaming
large documents without loading a whole version into memory.
depends: M8-BE-API-01 · stories: US-011

**M8-BE-CORE-01 — Chunk-friendly document reads** (size: M)
Provide region- and tier-scoped reads over `graph_document_versions` (a spatial or hierarchical
index over stored nodes) so the endpoint can page without a full scan.
depends: M8-BE-API-01 · stories: US-011

### QA — fixtures, harness, acceptance

**M8-QA-02 — Million-element synthetic fixture** (size: M)
Generate a deterministic, versioned ≥10⁶-element synthetic graph document (scaling the M0 large
fixture) under `vnext/fixtures/`, plus intermediate scales for regression curves.
depends: M8-QA-01 · stories: US-011

**M8-QA-03 — Perf budget CI harness** (size: L)
Headless run (Playwright + Babylon instrumentation) that loads fixtures at increasing scale, samples
the M8-QA-01 telemetry, asserts frame-time and interaction-latency budgets, and emits a perf report.
depends: M8-QA-01, M8-QA-02 · stories: US-011

**M8-QA-04 — US-011 acceptance + US-024 re-verification** (size: M)
E2E: load the million-element fixture and orbit/focus/drill within budget (US-011); assert labels
stay legible and budget-capped at maximum zoom-out on the large fixture (US-024 re-verified at
scale).
depends: M8-QA-03, M8-FE-GL-04, M8-FE-GL-05, M8-FE-SHELL-01 · stories: US-011, US-024

## Integration & exit criteria

**M8-INT-01 — End-to-end scale integration** (size: L) — joins FE-GRAPH, FE-GL, FE-SHELL,
BE-API/BE-CORE, QA.
Wire the full path on the million-element fixture: chunked load → worker layout → octree cull →
HLOD → instanced impostor draw → capped labels and edges. Hold the interactive frame budget on
reference desktop hardware.
depends: all M8 lane tasks · stories: US-011

**M8-INT-02 — Perf gate wired to CI** (size: S) — joins QA, INFRA.
Run the QA harness on the branch; a regression past budget fails CI and the report is attached.
depends: M8-QA-03, M8-INT-01 · stories: US-011

**Exit checklist**
- US-011 demonstrable: navigate a ≥10⁶-element graph at interactive frame rate on reference
  hardware, verified by the harness.
- US-024 re-verified at scale: labels legible and bounded at overview zoom on the large fixture.
- Perf budget CI gate active and blocking on regression.
- A11y invariants preserved: non-color kind/edge encodings and reduced-motion survive every LOD /
  HLOD / impostor / label path.
- Optional: the WebGPU engine flag builds and passes the same harness where supported (not required
  for exit).

**Demo script.** Open the million-element fixture; watch it stream in; orbit the whole system;
double-click a distant HLOD package to expand and drill into a leaf; toggle the perf HUD to show
frame time holding under budget; zoom fully out to confirm labels remain legible and capped.

## Parallelization notes

- **Workers supported:** ~4–6 (an FE-GL pair, an FE-GRAPH pair, FE-SHELL, one BE, QA).
- **Gate order:** M8-QA-01 (telemetry) and M8-BE-API-01 (paging) freeze first. FE-GRAPH-01 (octree)
  is the internal spine gate that unblocks FE-GL culling/HLOD and FE-GRAPH streaming; sequence it
  ahead of the rest of its lane.
- **Lane isolation:** FE-GL owns `frontend/src/renderer/`, FE-GRAPH owns `frontend/src/graph/`,
  FE-SHELL owns `frontend/src/lib/` + `app/`, BE owns `backend/`, QA owns `frontend/cypress/`,
  `backend/test/integration/`, and `vnext/fixtures/`. No two lanes touch the same directory.
- **Cross-milestone contention:** FE-GL and FE-SHELL are also needed by M10. To avoid
  `frontend/src/renderer/` contention, land M8's FE-GL work before M10's small FE-GL
  contrast/monochrome/fly-through tasks (ideally the same FE-GL worker carries both, sequentially).
- **Merge order:** octree (FE-GRAPH-01) → FE-GL cull/HLOD → INT-01; worker layout and streaming
  develop independently and converge at INT-01.

## Stories delivered

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-011 | P1 | Dana | Navigate a million-element graph at interactive frame rates |

> US-024 (P0, Marcus — *Keep node labels legible when zoomed out*) is **delivered in M1** and
> **re-verified at scale here** (M8-FE-GL-05, M8-QA-04); it is not re-allocated to M8.
