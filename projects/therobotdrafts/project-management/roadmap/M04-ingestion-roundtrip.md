# M4 — Source Ingestion & Code Round-Trip

Objective: Turn a real source repository into a live `HoloGraph` bubble model and close the loop back to code. This milestone builds the source-ingestion backends (broad + high-fidelity adapters), the unified code-graph merge, incremental re-ingest as a diff against the existing model, entry-point/trust-boundary classification, deterministic model→code generation, and the headless/automation surface (commit-triggered remodel, env/secret config). Binary/decompiler ingestion is explicitly out of scope here — it lands in M7. This is parallel track A, running after M3 alongside M5 and M6.

## Entry criteria

- `M3 exit`: patch protocol, `graph_document_versions`, authoring, and single-user channel echo are live; the frozen M0 contracts (GraphDocument JSON schema aligned with `.trd-yaml`, patch-operation format, `/api/v1` surface, `graph:doc:*` channel, ingestion adapter behaviour, fixture pack) are in force.
- M1 `.trd-yaml`/fixture import path exists (real repo ingestion replaces the placeholder import here).
- Cross-cutting accessibility constraints from M3 (reduced-motion, non-color encoding, keyboard reachability) apply to every new UI surface.

## Gate tasks

Front-loaded contract-freeze tasks. They unblock BE-ING, BE-CORE, BE-API, and the FE lanes; keep them small and land them first.

- **M4-GATE-01** (BE-CORE) — Freeze code-graph fact-schema delta. Extend the M0 GraphDocument schema with ingestion facts: node kinds (package/module/type/method/field/param), edge classes (reference/call/type/CFG), and the load-bearing call-edge provenance enum `static-resolved | static-candidate | dynamic-observed | synthetic`. Aligns with `.trd-yaml` element/edge vocabulary and the KDM-shaped Code/Structure/Data organizing schema from `docs/specs/reverse-engineering.md`. `depends: M3 exit` `size: M` `stories:`
- **M4-GATE-02** (BE-ING) — Freeze ingestion adapter contract v1 (concrete). Make the M0 adapter behaviour executable: adapter input (source root) → emits code-graph facts; job lifecycle (`queued/running/diff-ready/failed`); same-fact-shape invariant across adapters. Selects the v1 adapter roster (see BE-ING-01/02/03). `depends: M4-GATE-01` `size: M` `stories:`
- **M4-GATE-03** (BE-CORE) — Define entry-point & trust-boundary annotation model. These are net-new concepts (absent from current specs), so freeze them here: external entry points (exported symbols, HTTP routes, `main`/public API surface) and trust boundaries (marked module/package crossings) as first-class code-graph annotations. `depends: M4-GATE-01` `size: S` `stories: US-053`
- **M4-GATE-04** (BE-CORE) — Freeze deterministic codegen template contract. Model element → source skeleton mapping (C#/Java/TS/Python), member ordering, and the determinism guarantee: byte-stable output for an identical model. Ports the Unity `CodeSkeleton` concept as spec, not code. `depends: M3 exit` `size: S` `stories: US-090`
- **M4-GATE-05** (BE-API) — Freeze ingestion/remodel/codegen REST + webhook contract. `/api/v1` endpoints for ingest jobs, re-ingest, headless remodel webhook, deterministic codegen, and the source-blob/editor-link resolver; enumerate the env/secret config keys. `depends: M4-GATE-01` `size: M` `stories:`

## Lanes & tasks

### BE-ING — ingestion + graph analysis (`backend/lib/holograph/ingest/`, `.../analysis/`, Oban)

- **M4-BE-ING-01** — Broad substrate: tree-sitter + SCIP. Parse an arbitrary repo tree into an entity inventory + reference edges via a SCIP/stack-graphs index; error-tolerant, polyglot, degrades on broken code. Chosen as the default first path (justification: breadth, incremental GLR parsing, graceful degradation — per `reverse-engineering.md §3.4`). Runs as an Oban worker. `depends: M4-GATE-02` `size: L` `stories: US-001`
- **M4-BE-ING-02** — High-fidelity adapter: TypeScript Compiler API. Resolved symbols, types, and call edges for TS/JS via `Program`/`TypeChecker`; dogfoodable against the vnext frontend. `depends: M4-GATE-02` `size: L` `stories: US-001`
- **M4-BE-ING-03** — Second-ecosystem source adapter: Elixir. One additional source adapter over the vnext backend itself (tree-sitter-elixir + resolver), proving the merge across heterogeneous adapters. `depends: M4-GATE-02` `size: M` `stories: US-051`
- **M4-BE-ING-04** — Unified code-graph merge. Merge facts from all adapters into one graph with stable node identities and the same-fact-shape invariant, so downstream never branches on source language. `depends: M4-BE-ING-01, M4-BE-ING-02, M4-BE-ING-03` `size: L` `stories: US-051`
- **M4-BE-ING-05** — Monorepo-scale ingest. Chunked/streamed ingest of a large monorepo with job progress and back-pressure; validated against a real multi-language repo fixture. `depends: M4-BE-ING-01, M4-BE-ING-04` `size: M` `stories: US-001`
- **M4-BE-ING-06** — Incremental re-ingest / diff. Re-analyze changed files into a graph *diff* (not a rebuild), preserving node identity; emit a patch-shaped delta so open views survive. `depends: M4-BE-ING-04, M4-GATE-01` `size: L` `stories: US-010`
- **M4-BE-ING-07** — Entry-point & trust-boundary classifier. Analysis pass tagging external entry points and trust boundaries per M4-GATE-03. `depends: M4-GATE-03, M4-BE-ING-04` `size: M` `stories: US-053`

### BE-CORE — domain model + persistence (`backend/lib/holograph/{graph,draft}/`, `db/changelog/`)

- **M4-BE-CORE-01** — Persist ingestion facts. Extend the graph domain + Liquibase changelog with provenance flags and entry-point/trust annotations per the gate schema. `depends: M4-GATE-01` `size: M` `stories: US-001, US-053`
- **M4-BE-CORE-02** — Apply re-ingest delta as a version. Land an ingest delta as a new `graph_document_version` preserving identity, feeding incremental re-derivation. `depends: M4-BE-CORE-01, M4-BE-ING-06` `size: M` `stories: US-010`
- **M4-BE-CORE-03** — Deterministic codegen (draft domain). Port `CodeSkeleton`: model element → byte-stable source skeleton (TS/Java/Python/C#), with an optional LLM-elaboration seam that never affects the deterministic baseline. `depends: M4-GATE-04` `size: L` `stories: US-090`

### BE-API — REST surface (`backend/lib/holograph_web/{controllers,plugs}/`)

- **M4-BE-API-01** — Ingestion job endpoints. `POST` create ingest, `GET` status/result, list; wired to Oban. `depends: M4-GATE-05, M4-BE-ING-01` `size: M` `stories: US-001`
- **M4-BE-API-02** — Headless remodel webhook. Commit-triggered, signed webhook returning a job handle; idempotent per commit. `depends: M4-GATE-05, M4-BE-ING-06` `size: M` `stories: US-089`
- **M4-BE-API-03** — Deterministic codegen endpoint. `POST` model region → generated source; deterministic, cache-keyed by model hash. `depends: M4-GATE-05, M4-BE-CORE-03` `size: M` `stories: US-090`
- **M4-BE-API-04** — Source-blob + editor-link resolver. Serve ingested source by node id for the side-by-side panel and resolve a node to an editor deep-link/shadow-file. `depends: M4-GATE-05` `size: S` `stories: US-033, US-083`
- **M4-BE-API-05** — Env/secret runtime config surface. Resolve LLM/repo endpoints and keys from env/secret; documented key list; never echo secret values in responses. `depends: M4-GATE-05` `size: S` `stories: US-094`

### BE-AI — LLM/agents (`backend/lib/holograph/agents/`)

- **M4-BE-AI-01** — LLM parse fallback. Non-deterministic structured-JSON parser for files the deterministic path can't resolve; sits behind the adapter contract and flags output `synthetic`/low-confidence so it is never silently upgraded. `depends: M4-GATE-02` `size: M` `stories: US-001`

### FE-SHELL — app UX, non-3D UI, API client (`frontend/src/app/`, `.../components/`, `.../lib/`)

- **M4-FE-SHELL-01** — Ingestion/import flow. Promote the M1 import CTA to real repo ingestion; job progress and error surfacing. `depends: M4-GATE-05` `size: M` `stories: US-001, US-019`
- **M4-FE-SHELL-02** — Side-by-side code panel. Code view docked to the 3D selection, fetching the source blob by node. `depends: M4-BE-API-04` `size: M` `stories: US-083`
- **M4-FE-SHELL-03** — Open-in-editor deep link. Resolve a node to an editor URI (e.g. `vscode://file/...`) or shadow-file download; configurable editor. `depends: M4-BE-API-04` `size: S` `stories: US-033`
- **M4-FE-SHELL-04** — Entry-point / trust-boundary surfacing. Non-color-encoded overlay + filter for entry points and trust boundaries. `depends: M4-BE-CORE-01, M4-BE-ING-07` `size: M` `stories: US-053`

### FE-GRAPH — graph/layout algorithms, pure TS (`frontend/src/graph/`)

- **M4-FE-GRAPH-01** — Incremental graph-diff application. Apply a re-ingest delta to the in-memory graph + LOD tree without a full rebuild, preserving camera and selection. `depends: M4-BE-CORE-02` `size: M` `stories: US-010`

### INFRA — scaffold, CI, deploy (`.infra-config.yaml`, `helm/`, `nginx/`, CI)

- **M4-INFRA-01** — Ingestion toolchain in the backend image. Bundle tree-sitter grammars, the SCIP/stack-graphs indexer, and Node (for the TS checker) into the backend Docker image; add the Oban migration to the deploy path. `depends: M0 exit` `size: M` `stories:`
- **M4-INFRA-02** — Secret/env wiring for automation config. Plumb LLM/repo keys via Infisical/env into helm + docker-compose per US-094. `depends: M4-BE-API-05` `size: S` `stories: US-094`

### QA — e2e + fixtures + perf harness (`frontend/cypress/`, `backend/test/integration/`, `vnext/fixtures/`)

- **M4-QA-01** — Ingestion fixtures. Curated small/medium repo samples (TS, Elixir, mixed) with expected code-graph snapshots. `depends: M4-GATE-02` `size: M` `stories:`
- **M4-QA-02** — Round-trip codegen tests. Assert byte-stable model→code output across repeated runs (the determinism contract). `depends: M4-BE-CORE-03` `size: M` `stories: US-090`
- **M4-QA-03** — Re-ingest / headless remodel e2e. Commit → webhook → diff → re-derived views, with identity preserved. `depends: M4-INT-01, M4-INT-02` `size: M` `stories: US-010, US-089`

## Integration & exit criteria

Integration tasks close the milestone and name the lanes they join.

- **M4-INT-01** (BE-ING + BE-CORE + FE-GRAPH) — Live re-ingest loop. End-to-end incremental re-ingest updating open views without rebuild. `stories: US-010, US-089`
- **M4-INT-02** (BE-CORE + BE-API + FE-SHELL) — Round-trip codegen demo. Model edit → deterministic source → open-in-editor → side-by-side. `stories: US-090, US-033, US-083`
- **M4-INT-03** (BE-ING + FE-SHELL) — Monorepo ingest + entry-point map. Ingest a real monorepo, unify mixed artifacts, surface entry points/trust boundaries. `stories: US-001, US-051, US-053`

Exit criteria:

- A real multi-language repo ingests into a navigable HoloGraph model (US-001), mixed adapters merge into one graph (US-051), and entry points/trust boundaries are visible and filterable (US-053).
- Re-ingesting changed code produces a diff that updates open views live (US-010); a commit webhook drives the same path headlessly (US-089).
- Model→code generation is byte-deterministic (US-090); a node opens in the editor and shows code side-by-side (US-033, US-083).
- Automation config (endpoints/keys) resolves from env/secret with no secret leakage (US-094).
- Every story is covered by at least one test at the API or e2e layer; a11y constraints hold on all new UI.

Demo script: import a monorepo → orbit the model → filter to entry points → edit a class in-model → generate deterministic code → open it in the editor → push a commit and watch the webhook re-ingest and update the open view.

## Parallelization notes

- Supports ~6-8 concurrent workers: BE-ING (largest, may be a pair), BE-CORE, BE-API, BE-AI, FE-SHELL, FE-GRAPH, INFRA, QA.
- Gate tasks land first; GATE-01 unblocks the schema-dependent lanes, GATE-02 unblocks all adapters, GATE-05 unblocks BE-API and the FE lanes.
- Lane isolation is clean: BE-ING owns `ingest/`+`analysis/`, BE-CORE owns `graph/`+`draft/`+`db/changelog/`, BE-API owns controllers, FE lanes own their frontend subtrees. No two lanes edit the same directory.
- Merge order: gate tasks → BE-ING adapters + BE-CORE schema in parallel → BE-ING-04 merge → BE-API + FE lanes → integration tasks last.
- Carry-over: US-019's import CTA (introduced M1) is completed here against real ingestion.

## Stories delivered

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-001 | P0 | Dana (systems architect) | Reverse-engineer a monorepo into a bubble model |
| US-089 | P0 | ARIA (automation agent) | Re-model a repo headlessly on commit |
| US-090 | P0 | ARIA (automation agent) | Generate code from model edits deterministically |
| US-010 | P1 | Dana (systems architect) | Re-ingest changed code to keep the model live |
| US-033 | P1 | Marcus (onboarding engineer) | Open the code behind a bubble in my editor |
| US-051 | P1 | Sven (reverse-engineer) | Unify mixed artifact types into one code-graph |
| US-053 | P1 | Sven (reverse-engineer) | Identify external entry points and trust boundaries |
| US-083 | P1 | Elena (CS educator) | Show code and model side by side |
| US-094 | P1 | ARIA (automation agent) | Configure endpoints and keys via env/secret |
