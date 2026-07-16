# M5 — Projection & Interchange v1

Objective: Turn a region of the 3D model into standard 2D diagram notation and get it out of the tool in the formats engineers actually share. This milestone builds the projection engine (region → notation → 2D diagram model), the first diagram families (component, deployment, class, sequence, audience-simplified), and the export pipeline (PlantUML, Mermaid, DOT, SVG, high-resolution render, annotated PNG/PDF, and a headless export API). It reuses the reverse-engineered Unity interchange concepts as spec: the `IxModel` IR, the `.trd-yaml` native format, the `tools/trd-converter` .NET CLI (PlantUML ↔ `.trd-yaml`) wrapped server-side, and the `docs/diagrams/` corpus (172 `.puml`/`.trd-yaml` round-trip pairs across 43 diagram types) as fixtures. Identity-preserving enterprise formats (XMI/Rose/EA/BPMN) are M7; this milestone is export-oriented. Parallel track B, running after M3 alongside M4 and M6.

## Entry criteria

- `M3 exit`: model, versions, and authoring are live; M0 contracts (GraphDocument schema aligned with `.trd-yaml`, `/api/v1` surface, `IRenderer`/`ILayout` TS interfaces) are in force.
- M2 comprehension tooling (regions, traversal, metrics) is available for region selection.
- Cross-cutting a11y constraints from M3 apply: projected diagrams must encode kind/edge-type beyond color and be keyboard-reachable; the sequence stepper must respect reduced-motion.

## Gate tasks

- **M5-GATE-01** (BE-INT) — Freeze projection contract. Region descriptor (sub-graph selector, e.g. "this package and its callers") + target notation → a projected 2D diagram model (`IxModel`-shaped). Enumerate v1 families: component, deployment, class/pattern, sequence, audience-simplified. Projection is non-destructive (reads the model, produces a view). `depends: M3 exit` `size: M` `stories:`
- **M5-GATE-02** (BE-INT) — Freeze the trd-converter service-wrapper interface. Server-side invocation of the `net10.0` `trd-converter` CLI as the PlantUML↔`.trd-yaml` bridge, with `--check` (round-trip validation, exit 2 on drift) and `--stats` available in CI; declare `IxModel` as the interchange IR and the export format matrix (PlantUML, Mermaid, DOT, SVG). `depends: M3 exit` `size: M` `stories:`
- **M5-GATE-03** (BE-API) — Freeze projection/export REST contract. `/api/v1` endpoints: create projection, export by format, headless export, and render capture. `depends: M5-GATE-01` `size: S` `stories:`

## Lanes & tasks

### BE-INT — interchange + 2D projection (`backend/lib/holograph/interchange/`, `.../projection/`, trd-converter wrapper)

- **M5-BE-INT-01** — Projection engine (component). Select a sub-graph + notation → `IxModel` diagram, laid out by the relational layout engine; component is the reference family. `depends: M5-GATE-01` `size: L` `stories: US-006`
- **M5-BE-INT-02** — Deployment projection. Services/nodes → deployment diagram (host volumes containing artifacts + communication edges). `depends: M5-BE-INT-01` `size: M` `stories: US-016`
- **M5-BE-INT-03** — Class/pattern projection. A reference-pattern region → class diagram (type bubbles + member sub-bubbles). `depends: M5-BE-INT-01` `size: M` `stories: US-081`
- **M5-BE-INT-04** — Audience-simplified lens. Reduced-detail projection for a non-technical audience (collapse internals, keep top-level structure). `depends: M5-BE-INT-01` `size: M` `stories: US-042`
- **M5-BE-INT-05** — Sequence projection + step model. CFG/interaction region → sequence diagram (lifeline lanes, time-ordered messages, activation segments) with ordered step metadata for stepping. `depends: M5-BE-INT-01` `size: M` `stories: US-087`
- **M5-BE-INT-06** — trd-converter service wrapper. Server-side wrap of the .NET CLI; `IxModel` ↔ `.trd-yaml` ↔ PlantUML; expose `--check` on the corpus as a CI gate. `depends: M5-GATE-02` `size: M` `stories: US-007`
- **M5-BE-INT-07** — Mermaid + DOT exporters. `IxModel` → Mermaid (`classDiagram`) and DOT; deterministic (fixed-point `W2 == W3`). `depends: M5-GATE-02, M5-BE-INT-06` `size: M` `stories: US-070`
- **M5-BE-INT-08** — PlantUML export. Projected diagram → PlantUML via the wrapper. `depends: M5-BE-INT-06` `size: S` `stories: US-007`
- **M5-BE-INT-09** — Headless SVG/PlantUML render. Server-side SVG + PlantUML output for automation, no browser required. `depends: M5-BE-INT-06, M5-BE-INT-07` `size: M` `stories: US-091`

### BE-API — REST surface (`backend/lib/holograph_web/{controllers,plugs}/`)

- **M5-BE-API-01** — Projection endpoints. Create a projection from a region descriptor; return the projected diagram model. `depends: M5-GATE-03, M5-BE-INT-01` `size: M` `stories: US-006`
- **M5-BE-API-02** — Export endpoints. PlantUML/Mermaid/DOT/SVG export of a projected diagram. `depends: M5-BE-INT-06, M5-BE-INT-07, M5-BE-INT-09` `size: M` `stories: US-007, US-070`
- **M5-BE-API-03** — Headless export API. SVG + PlantUML export callable headlessly for ARIA. `depends: M5-BE-INT-09` `size: S` `stories: US-091`

### FE-SHELL — app UX, non-3D UI (`frontend/src/app/`, `.../components/`)

- **M5-FE-SHELL-01** — Projection UI. Region select → diagram-type picker → open the 2D diagram viewer. `depends: M5-BE-API-01, M5-FE-GRAPH-01` `size: L` `stories: US-006`
- **M5-FE-SHELL-02** — 2D diagram viewer component. Render a projected diagram with non-color encoding of kind/edge-type and keyboard reachability. `depends: M5-FE-SHELL-01` `size: M` `stories: US-006, US-016, US-081`
- **M5-FE-SHELL-03** — Sequence stepper UI. Step through a pattern's collaboration sequence; reduced-motion aware. `depends: M5-BE-INT-05, M5-FE-SHELL-02` `size: M` `stories: US-087`
- **M5-FE-SHELL-04** — Export controls + audience-mode toggle. Export menu (PlantUML/Mermaid/DOT/SVG) and the non-technical-audience lens toggle. `depends: M5-BE-API-02` `size: M` `stories: US-007, US-042, US-070`
- **M5-FE-SHELL-05** — Annotated PNG/PDF export. Compose the current view + annotations → PNG/PDF. `depends: M5-FE-GL-01` `size: M` `stories: US-043`

### FE-GL — WebGL renderer (`frontend/src/renderer/`)

- **M5-FE-GL-01** — High-resolution region render capture. Offscreen/supersampled WebGL capture of a selected region → PNG at export resolution. `depends: M3 exit` `size: M` `stories: US-017`

### FE-GRAPH — graph/layout algorithms, pure TS (`frontend/src/graph/`)

- **M5-FE-GRAPH-01** — Region sub-graph extraction. Pure-TS selector producing the projection input sub-graph (e.g. a package plus its callers) from a user selection. `depends: M5-GATE-01` `size: M` `stories: US-006`
- **M5-FE-GRAPH-02** — 2D projection preview layout (optional). Lightweight client-side 2D layout for an instant preview before the authoritative server render. `depends: M5-FE-GRAPH-01` `size: M` `stories: US-006`

### QA — e2e + fixtures (`frontend/cypress/`, `backend/test/integration/`, `vnext/fixtures/`)

- **M5-QA-01** — Projection/export fixtures from the corpus. Wire the `docs/diagrams/` `.puml`/`.trd-yaml` pairs; run `trd-converter --check` as a drift gate and `--stats` as a coverage audit. `depends: M5-GATE-02` `size: M` `stories:`
- **M5-QA-02** — Export golden tests. Projected model → PlantUML/Mermaid/DOT/SVG golden compare, asserting export determinism (`W2 == W3`). `depends: M5-BE-INT-07, M5-BE-INT-08` `size: M` `stories: US-007, US-070`
- **M5-QA-03** — Headless export e2e. Region → headless SVG/PlantUML via the API. `depends: M5-BE-API-03` `size: S` `stories: US-091`

## Integration & exit criteria

- **M5-INT-01** (BE-INT + FE-GRAPH + FE-SHELL) — Component projection end-to-end. Select a region → project a component diagram → view it in 2D. `stories: US-006`
- **M5-INT-02** (BE-INT + BE-API) — Export matrix round-trip. Export the projected families to PlantUML/Mermaid/DOT/SVG and pass `trd-converter --check` on the corpus with zero drift. `stories: US-007, US-070, US-091`
- **M5-INT-03** (FE-GL + FE-SHELL) — Hi-res + annotated export. Capture a high-resolution region render and export an annotated PNG/PDF. `stories: US-017, US-043`

Exit criteria:

- A subsystem region projects to component (US-006), deployment (US-016), class/pattern (US-081), and audience-simplified (US-042) diagrams; a pattern's collaboration sequence can be stepped through (US-087).
- Projected diagrams export to PlantUML (US-007), Mermaid, and DOT (US-070), and headlessly to SVG/PlantUML (US-091), all deterministic and passing corpus `--check`.
- A region exports as a high-resolution render (US-017) and an annotated PNG/PDF (US-043).
- Each story has at least one test at the appropriate layer; projected diagrams satisfy non-color encoding and keyboard reachability.

Demo script: select a package region → project a component diagram → toggle audience-simplified → step a sequence projection → export PlantUML/Mermaid/DOT → capture a hi-res render → export annotated PDF → run `trd-converter --check` over the corpus.

## Parallelization notes

- Supports ~5-6 concurrent workers: BE-INT (largest, may be a pair), BE-API, FE-SHELL, FE-GL, FE-GRAPH, QA. BE-CORE and BE-RT have no work here.
- Gate tasks land first: GATE-01 unblocks projection + FE-GRAPH; GATE-02 unblocks the trd-converter wrapper and all exporters; GATE-03 unblocks BE-API.
- Lane isolation: BE-INT owns `interchange/`+`projection/`+the converter wrapper, FE-SHELL owns the 2D viewer/export UI, FE-GL owns render capture, FE-GRAPH owns region extraction. No shared directories.
- Merge order: gates → BE-INT projection families + exporters (intra-lane ordered after INT-01/06) → BE-API → FE lanes → integration. FE-GL-01 and FE-GRAPH-01 can start immediately after their gate.
- The trd-converter is reused as-is (a subprocess), not reimplemented; the wrapper is the only new server code touching it.

## Stories delivered

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-006 | P0 | Dana (systems architect) | Project a subsystem region to a UML component diagram |
| US-007 | P1 | Dana (systems architect) | Export a projected diagram to PlantUML |
| US-017 | P1 | Dana (systems architect) | Export a high-resolution render of a region |
| US-042 | P1 | Priya (tech lead) | Project a region for a non-technical audience |
| US-081 | P1 | Elena (CS educator) | Project a reference pattern's class diagram |
| US-091 | P1 | ARIA (automation agent) | Export diagrams headlessly to SVG and PlantUML |
| US-016 | P2 | Dana (systems architect) | Project a deployment diagram of services |
| US-043 | P2 | Priya (tech lead) | Export an annotated view to PNG/PDF |
| US-070 | P2 | Robert (legacy modeler) | Export Mermaid and DOT for lightweight sharing |
| US-087 | P2 | Elena (CS educator) | Step through a pattern's collaboration sequence |
