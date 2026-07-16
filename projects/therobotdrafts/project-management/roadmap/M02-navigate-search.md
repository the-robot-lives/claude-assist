# M2 — Navigate, Search & Understand

**Objective.** Turn the viewer into a comprehension tool. Add graph-analysis power — directed
traversal and reachability (inbound/outbound dependencies, callers/callees, path-to-target), cycle
detection, and structural metrics — plus server-backed search and faceted filtering, rendered as
highlights, traces, and metric coloring, with a compass gizmo and drill breadcrumb for orientation.
The heavy algorithms live in pure-TS FE-GRAPH; the search/filter index lives in the backend; FE-GL
renders results; FE-SHELL owns the query and orientation UI.

## Entry criteria

- M1 exit: a doc loads, renders, and is navigable; renderer picking/selection works; `/api/v1` doc
  endpoints are live; the sphere-packed scene-graph/LOD tree is available to the renderer.
- `IRenderer` supports a highlight/trace-set input (from M0-FE-GL-01); `ILayout` exposes the built
  graph for algorithm passes.

## Gate tasks

- **M2-FE-GRAPH-01 — Freeze the traversal-result payload.** The shape FE-GRAPH hands FE-GL for
  rendering: highlight sets, ordered trace paths, dimmed/emphasis bands, and per-node metric scalars.
  Unblocks FE-GL. `depends: M1 exit` · `size: S` · `stories: —`
- **M2-BE-API-01 — Freeze the search/filter contract.** Query params and result envelope for
  qualified-name search and faceted filter (language / layer / package). Unblocks FE-SHELL.
  `depends: M1 exit` · `size: S` · `stories: —`

## Lanes & tasks

### FE-GRAPH — graph/layout algorithms (pure TS)

- **M2-FE-GRAPH-01 — (gate) traversal-result payload.** See Gate tasks. `size: S` · `stories: —`
- **M2-FE-GRAPH-02 — Directed traversal / reachability.** Inbound/outbound dependency walk, caller/
  callee cross-reference, and path-to-target across service/language boundaries; returns highlight +
  trace payloads. `depends: M2-FE-GRAPH-01` · `size: L`
  · `stories: US-003, US-012, US-027, US-052, US-057`
- **M2-FE-GRAPH-03 — Cycle detection.** Strongly-connected-component pass (Tarjan) surfacing
  dependency cycles as highlightable sets. `depends: M2-FE-GRAPH-01` · `size: M` · `stories: US-004`
- **M2-FE-GRAPH-04 — Structural metrics.** Fan-in/fan-out, coupling, and a centrality proxy per node;
  emitted as scalars for the coloring pipeline and for core-vs-peripheral emphasis.
  `depends: M2-FE-GRAPH-01` · `size: M` · `stories: US-013, US-028`

### BE-CORE — domain model + persistence

- **M2-BE-CORE-01 — Search / filter index.** Build a per-version index over the document
  (qualified-name lookup; language / layer / package facets) at version-write time; expose a query
  function for BE-API. `depends: M1 exit` · `size: M` · `stories: US-008, US-009, US-026`

### BE-API — REST surface

- **M2-BE-API-01 — (gate) search/filter contract.** See Gate tasks. `size: S` · `stories: —`
- **M2-BE-API-02 — Search endpoint.** `GET /api/v1/docs/:id/search` — qualified-name / class-name
  search returning focusable node refs. `depends: M2-BE-CORE-01, M2-BE-API-01` · `size: M`
  · `stories: US-008, US-026`
- **M2-BE-API-03 — Filter endpoint.** Faceted filter by language / layer / package returning a node
  subset for the client to isolate. `depends: M2-BE-CORE-01, M2-BE-API-01` · `size: S`
  · `stories: US-009`

### FE-SHELL — app UX, non-3D UI, API client

- **M2-FE-SHELL-01 — Search UI.** Search box → results → select routes a focus command to the
  renderer; covers both type-by-qualified-name and class-by-name. `depends: M2-BE-API-02` · `size: M`
  · `stories: US-008, US-026`
- **M2-FE-SHELL-02 — Filter panel.** Language / layer / package facet panel that isolates/dims the
  model to the filtered subset. `depends: M2-BE-API-03` · `size: M` · `stories: US-009`
- **M2-FE-SHELL-03 — Drill breadcrumb.** Breadcrumb of the current drill location, clickable to
  ascend. `depends: M1 exit` · `size: S` · `stories: US-032`

### FE-GL — WebGL renderer

- **M2-FE-GL-01 — Highlight / trace rendering.** Render dependency and call-path traces from the
  traversal payload — emphasize the path, dim the rest — for both dependency tracing and
  path-to-sensitive-module. `depends: M2-FE-GRAPH-01` · `size: L`
  · `stories: US-003, US-012, US-027, US-052, US-057`
- **M2-FE-GL-02 — Cycle highlight.** Render detected cycles as a distinct highlight set (non-color
  redundant channel per the forward a11y constraint). `depends: M2-FE-GRAPH-01, M2-FE-GRAPH-03`
  · `size: M` · `stories: US-004`
- **M2-FE-GL-03 — Metric coloring pipeline.** Map per-node metric scalars to a color ramp *plus* a
  redundant non-color channel (size/glyph), and a core-vs-peripheral emphasis mode.
  `depends: M2-FE-GRAPH-04` · `size: M` · `stories: US-013, US-028`
- **M2-FE-GL-04 — Compass / horizon gizmo.** Persistent orientation gizmo showing camera heading and
  horizon. `depends: M1 exit` · `size: S` · `stories: US-029`

### QA — e2e + fixtures + harness

- **M2-QA-01 — Comprehension e2e.** Fixtures with known cycles and metric values; assert search→focus,
  filter, dependency/call-path trace, cycle highlight, metric coloring, breadcrumb.
  `depends: M2-INT-01` · `size: M`
  · `stories: US-003, US-004, US-008, US-009, US-012, US-013, US-026, US-027, US-028, US-029, US-032, US-052, US-057`

## Integration & exit criteria

- **M2-INT-01 — Query → traverse → render.** Search/select result feeds a FE-GRAPH traversal whose
  payload FE-GL renders as a highlight/trace. Joins **FE-SHELL + FE-GRAPH + FE-GL**.
  `depends: M2-FE-SHELL-01, M2-FE-GRAPH-02, M2-FE-GL-01` · `size: M`
- **M2-INT-02 — Live search/filter.** FE-SHELL search and filter panels run over the live server
  index end-to-end. Joins **BE-CORE + BE-API + FE-SHELL**. `depends: M2-BE-API-02, M2-BE-API-03,
  M2-FE-SHELL-02` · `size: S`
- **Demo script:** search a type by qualified name → focus it; trace its inbound/outbound deps; run a
  call-path trace across a service boundary; highlight a dependency cycle; color nodes by fan-in and
  spot the bottleneck; filter to one language; read the breadcrumb while drilling; check heading on
  the compass.
- **Story acceptance checklist:** all 13 M2 stories demonstrable and each covered by at least one test.
- **A11y forward constraint (from M1, enforced here):** every new visual encoding introduced in M2 —
  cycle highlight, metric coloring, trace emphasis — must carry a redundant non-color channel, and
  camera moves triggered by focus/trace must respect the reduced-motion path arriving in M3. These are
  acceptance constraints on M2 tasks, not deferred to M3.

## Parallelization notes

- **Worker count: 5–6** (FE-GRAPH, BE-CORE, BE-API, FE-SHELL, FE-GL, QA).
- **FE-GRAPH is the pacing lane.** The traversal/metric algorithms gate FE-GL's rendering, so
  M2-FE-GRAPH-01 (the payload freeze) is front-loaded and small; FE-GL then builds render code against
  the frozen payload while FE-GRAPH fills in the algorithm bodies. Backend search/filter runs as a
  fully independent sub-track behind M2-BE-API-01.
- **Lane isolation.** FE-GRAPH owns `frontend/src/graph/`; FE-GL owns `frontend/src/renderer/`;
  FE-SHELL owns `app/` + non-3D `components/` + `lib/`; BE-CORE owns `backend/lib/holograph/` +
  changelog; BE-API owns `backend/lib/holograph_web/controllers`. No shared directories; the only
  cross-lane coupling is the two frozen payloads.
- **Merge order:** gates (M2-FE-GRAPH-01, M2-BE-API-01) → lane bodies → M2-INT-01 / M2-INT-02 → QA.

## Stories delivered

| ID | Priority | Persona | Title |
|------|------|---------|-------|
| US-003 | P0 | Dana | Trace a service's inbound and outbound dependencies |
| US-004 | P1 | Dana | Detect and highlight dependency cycles |
| US-008 | P0 | Dana | Search a type by qualified name and focus it |
| US-009 | P1 | Dana | Filter the model by language, layer, or package |
| US-012 | P0 | Dana | Trace a call path across service and language boundaries |
| US-013 | P1 | Dana | Color nodes by a structural metric to spot bottlenecks |
| US-026 | P0 | Marcus | Search a class by name and jump to it |
| US-027 | P0 | Marcus | Trace the callers of a class to scope a bug |
| US-028 | P1 | Marcus | Distinguish core modules from peripheral ones |
| US-029 | P1 | Marcus | Show a compass/horizon orientation gizmo |
| US-032 | P1 | Marcus | Show a breadcrumb of the current drill location |
| US-052 | P0 | Sven | Trace every path that reaches a sensitive module |
| US-057 | P0 | Sven | Cross-reference a suspicious function's callers and callees |
