# M1 — Walking Skeleton — Load & View

**Objective.** Prove the whole stack end-to-end with the thinnest useful vertical: import a
GraphDocument from a `.trd-yaml` fixture, persist it with versioning, serve it over `/api/v1`, and
render it as a navigable sphere-packed 3D graph the user can orbit, focus, recenter, and drill. This
milestone lands every P0 navigation/orientation verb and the first-run import call-to-action, so a
user can load a model and find their way around it — no editing, search, or ingestion yet.

## Entry criteria

- M0 exit: GraphDocument schema, patch format, REST surface, channel protocol, `IRenderer`/`ILayout`
  interfaces, and the ingestion behaviour are frozen; scaffold builds; CI is green; the fixture pack
  validates.
- Renderer is client-only: mounted via `next/dynamic` with `ssr: false` (repo precedent — robotwars
  `hero-diorama.tsx`). Babylon.js runs on its WebGL2 engine behind `IRenderer`.

## Gate tasks

Two small, front-loaded gates decouple the client rendering path from backend implementation so five
lanes can proceed against contracts rather than each other's code:

- **M1-FE-GRAPH-01 — Freeze the renderer-facing scene payload.** Concrete shape of the scene-graph +
  LOD node/edge payload that `ILayout` hands `IRenderer` (positions, radii, containment, label refs,
  LOD bands). Unblocks all of FE-GL. `depends: M0 exit` · `size: S` · `stories: —`
- **M1-BE-API-01 — Fixture-backed doc stub.** A `/api/v1/docs` + `/api/v1/docs/:id` endpoint served
  from a static fixture, so FE-SHELL builds its client against a live contract before BE-CORE
  persistence lands. `depends: M0 exit` · `size: S` · `stories: —`

## Lanes & tasks

### BE-CORE — domain model + persistence

- **M1-BE-CORE-01 — Document tables.** Liquibase changelog for `graph_documents` and
  `graph_document_versions` (append-on-write version rows). `depends: M0 exit` · `size: M`
  · `stories: —`
- **M1-BE-CORE-02 — Docs context.** `HoloGraph.Docs` create/get/list with version-on-write; the
  authoritative read/write path behind BE-API. `depends: M1-BE-CORE-01` · `size: M` · `stories: —`
- **M1-BE-CORE-03 — `.trd-yaml` loader.** Deserialize a fixture / `.trd-yaml` file into a canonical
  GraphDocument and persist it as v1. `depends: M1-BE-CORE-02` · `size: M` · `stories: US-019`

### BE-API — REST surface

- **M1-BE-API-01 — (gate) fixture-backed doc stub.** See Gate tasks. `size: S` · `stories: —`
- **M1-BE-API-02 — Docs read endpoints.** `GET /api/v1/docs`, `GET /api/v1/docs/:id` wired to
  `HoloGraph.Docs`; JSON views conform to the GraphDocument schema. `depends: M1-BE-CORE-02,
  M1-BE-API-01` · `size: M` · `stories: US-002`
- **M1-BE-API-03 — Import endpoint.** `POST /api/v1/docs` accepts a `.trd-yaml`/fixture upload →
  loader → persisted doc; backs the import CTA. `depends: M1-BE-CORE-03` · `size: M`
  · `stories: US-019`

### FE-SHELL — app UX, non-3D UI, API client

- **M1-FE-SHELL-01 — API client + auth.** Typed client over `/api/v1` with Guardian JWT
  access+refresh from the start-app baseline. `depends: M1-BE-API-01` · `size: M` · `stories: —`
- **M1-FE-SHELL-02 — Project / doc list.** Landing screen listing projects and their documents.
  `depends: M1-FE-SHELL-01` · `size: S` · `stories: —`
- **M1-FE-SHELL-03 — Doc-open route + renderer mount.** Route that loads a doc and mounts the
  client-only renderer (`next/dynamic`, `ssr: false`), passing the fetched doc to the layout/render
  pipeline. `depends: M1-FE-SHELL-01, M1-FE-GL-02` · `size: M` · `stories: —`
- **M1-FE-SHELL-04 — Detail panel.** Selecting a node shows its class members (fields/methods,
  visibility) in a side panel, fed by renderer picking. `depends: M1-FE-SHELL-03, M1-FE-GL-08`
  · `size: M` · `stories: US-034`
- **M1-FE-SHELL-05 — Import CTA / empty state.** First-run "Import a repo" call-to-action that, for
  M1, imports a `.trd-yaml`/fixture (real repo ingestion arrives in M4); routes to the new doc.
  `depends: M1-FE-SHELL-02, M1-BE-API-03` · `size: M` · `stories: US-019`

### FE-GL — WebGL renderer (Babylon behind IRenderer)

- **M1-FE-GL-01 — Engine bootstrap.** Babylon WebGL2 engine + scene + render loop behind `IRenderer`,
  client-only. `depends: M0 exit` · `size: M` · `stories: —`
- **M1-FE-GL-02 — Node/edge render.** Draw sphere-packed nodes and edges from the M1-FE-GRAPH-01
  scene payload. `depends: M1-FE-GL-01, M1-FE-GRAPH-01` · `size: L` · `stories: US-002`
- **M1-FE-GL-03 — Orbit camera.** Orbit the whole system to survey clusters. `depends: M1-FE-GL-02`
  · `size: M` · `stories: US-022`
- **M1-FE-GL-04 — Focus / frame.** `F` focuses and frames the selected node. `depends: M1-FE-GL-03`
  · `size: S` · `stories: US-023`
- **M1-FE-GL-05 — Recenter / home.** One action recenters the camera to the whole-system home pose to
  recover from being lost. `depends: M1-FE-GL-03` · `size: S` · `stories: US-025`
- **M1-FE-GL-06 — Overview framing.** Frame the whole-system overview as the default entry pose.
  `depends: M1-FE-GL-02` · `size: S` · `stories: US-002`
- **M1-FE-GL-07 — Drill in / out.** Drill from system overview into a container down to a single
  function, and back, keeping camera continuity. `depends: M1-FE-GL-03, M1-FE-GRAPH-03` · `size: M`
  · `stories: US-005`
- **M1-FE-GL-08 — Label legibility + picking.** SDF-style labels that stay legible when zoomed out;
  GPU/raycast picking that feeds selection to the detail panel. `depends: M1-FE-GL-02` · `size: M`
  · `stories: US-024`

### FE-GRAPH — graph/layout algorithms (pure TS)

- **M1-FE-GRAPH-01 — (gate) scene payload contract.** See Gate tasks. `size: S` · `stories: —`
- **M1-FE-GRAPH-02 — Sphere packing v1.** Containment-driven sphere packer (parent owns child
  placement per ADR-003 concept); pure TS, no DOM. `depends: M1-FE-GRAPH-01` · `size: L`
  · `stories: US-002`
- **M1-FE-GRAPH-03 — Scene-graph LOD tree.** Build the LOD/scene-graph tree from the packed model and
  emit the renderer payload; supports drill. `depends: M1-FE-GRAPH-02` · `size: M` · `stories: US-005`

### QA — e2e + fixtures + harness

- **M1-QA-01 — Fixture wiring.** Wire the M0 fixture pack into the Cypress/e2e harness and a headless
  API test path. `depends: M0 exit` · `size: S` · `stories: —`
- **M1-QA-02 — Smoke e2e.** Import fixture → doc opens → renders → orbit / focus / recenter / drill →
  detail panel shows members. `depends: M1-INT-01` · `size: M`
  · `stories: US-002, US-005, US-022, US-023, US-024, US-025, US-034`

## Integration & exit criteria

- **M1-INT-01 — Live vertical.** Replace the FE-SHELL stub client with the live BE-API doc endpoints;
  fetched doc → `ILayout` pack → `IRenderer` render in the running app. Joins **FE-SHELL + BE-API +
  FE-GRAPH + FE-GL**. `depends: M1-BE-API-02, M1-FE-SHELL-03, M1-FE-GRAPH-03, M1-FE-GL-08` · `size: M`
- **M1-INT-02 — Green smoke.** M1-QA-02 passes end-to-end in CI over the demo script. Joins **QA + all
  lanes**. `depends: M1-QA-02`
- **Demo script:** open app → "Import a repo" imports a fixture → whole-system overview is framed →
  orbit to survey clusters → click a node → detail panel shows its members → press `F` to frame it →
  drill into a function and back → recenter to home.
- **Story acceptance checklist:** US-002, US-005, US-019, US-022, US-023, US-024, US-025, US-034 —
  each demonstrable in-app (or via headless API for import) and covered by at least one test at the
  appropriate layer.
- **Forward constraint (from M0's a11y direction, enforced from here):** camera transitions must be
  interruptible and will gain a reduced-motion path in M3; labels must not rely on color alone. M1
  need not implement the toggle but must not design against it.

## Parallelization notes

- **Worker count: 5–6** (BE-CORE, BE-API, FE-SHELL, FE-GL, FE-GRAPH, QA), running concurrently.
- **Gate-decoupled starts.** FE-GL is briefly blocked only on the M1-FE-GRAPH-01 payload gate; FE-SHELL
  is briefly blocked only on the M1-BE-API-01 stub gate. Both gates are `S` and front-loaded, so once
  they land no lane waits on another lane's *implementation* — they build against contracts.
- **Lane isolation.** BE-CORE owns `backend/lib/holograph/{docs,graph}/` + `db/changelog/`; BE-API owns
  `backend/lib/holograph_web/controllers` + JSON views; FE-SHELL owns `frontend/src/app` +
  non-3D `components/` + `lib/`; FE-GL owns `frontend/src/renderer/`; FE-GRAPH owns
  `frontend/src/graph/`; QA owns `frontend/cypress/` + `backend/test/integration/` + `vnext/fixtures/`.
  No two lanes edit the same directory.
- **Merge order:** gates (M1-FE-GRAPH-01, M1-BE-API-01) → lane bodies → M1-INT-01 → M1-INT-02.

## Stories delivered

| ID | Priority | Persona | Title |
|------|------|---------|-------|
| US-002 | P0 | Dana | Frame the whole-system overview |
| US-005 | P0 | Dana | Drill from system overview to a single function and back |
| US-019 | P0 | Marcus | Offer an 'Import a repo' call-to-action on first run |
| US-022 | P0 | Marcus | Orbit the whole system to survey its clusters |
| US-023 | P0 | Marcus | Focus and frame the selected node with F |
| US-024 | P0 | Marcus | Keep node labels legible when zoomed out |
| US-025 | P0 | Marcus | Recenter to recover from being lost in space |
| US-034 | P1 | Marcus | Read a class's members in a detail panel |
