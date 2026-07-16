# M0 — Foundation & Contracts

**Objective.** Stand up the vnext application skeleton and freeze the cross-lane contracts that every
downstream milestone builds against. M0 delivers no product stories — every task is enabling. It is
deliberately narrow: one INFRA worker scaffolds and wires deployment while one architect authors the
contract-freeze documents. Nothing fans out until these contracts exist, because the whole
parallelization model (lanes owning disjoint code behind frozen interfaces) depends on them. Once M0
exits, the project can run five to seven lanes concurrently in M1.

## Entry criteria

- Repo access; `components/start-app` and the `start-app-scaffold` utility are available.
- Target directory confirmed: `projects/therobotdrafts/vnext/app/{backend,frontend,nginx,helm}`.
  `vnext.md` writes `vnexti/`; that is a typo — the empty `vnext/` directory is the target. (Stated
  once here; the overview `README.md` carries the canonical note.)
- Unity vertical-slice docs (`docs/arch/implementation-status.md`, `ARCHITECTURE.md`,
  `docs/specs/*`) are available as concept/spec donors only — no Unity code is migrated.
- `projects/therobotdrafts/tools/trd-converter` (.NET PlantUML ↔ `.trd-yaml` CLI) is present and will
  be wrapped server-side in later milestones; M0 only records its interface, does not integrate it.

## Gate tasks

M0 *is* the gate milestone: its contract documents unblock every lane in M1–M3. They are authored by
the single architect, front-loaded, and each is ID'd to the lane that will own the contract downstream
so the ownership boundary is unambiguous from day one. All are `depends: M0-INFRA-01` only in that they
live in the scaffolded tree; they do not depend on each other and are written in parallel.

- **M0-BE-CORE-01 — GraphDocument JSON schema.** Canonical document model (`projects`,
  `graph_documents`, `graph_document_versions`, `collab_events`) with node/edge/containment shapes,
  aligned field-for-field with `.trd-yaml` interchange semantics so fixtures and the Unity corpus load
  losslessly. `size: L` · `stories: —`
- **M0-BE-CORE-02 — Patch-operation format.** The mutation vocabulary (add/connect/rename/re-parent/
  re-type/delete) as an ordered, server-validatable op list; one op list = one undo step; version-bump
  rule per applied batch. Ports the Unity `Authoring/Commands` + `Authoring/Rules` semantics.
  `size: M` · `stories: —`
- **M0-BE-API-01 — REST `/api/v1` surface (OpenAPI sketch).** Resource shapes and status/error
  envelope for docs, versions, patches, search, export; Guardian JWT access+refresh per start-app.
  `size: M` · `stories: —`
- **M0-BE-RT-01 — Channel protocol `graph:doc:*`.** Event catalog (`doc:join`/`doc:leave`,
  `patch:apply`/`patch:reject`, `cursor:move`, `presence:state`) with payloads and the single-user vs
  multi-user boundary flagged. `size: M` · `stories: —`
- **M0-FE-GL-01 — `IRenderer` TypeScript interface.** Renderer abstraction (scene load, camera ops,
  picking, highlight/trace sets, label layer, gizmos) with Babylon-on-WebGL2 as the M1 implementation
  and a documented WebGPU-engine swap point (M8). `size: M` · `stories: —`
- **M0-FE-GRAPH-01 — `ILayout` TypeScript interface.** Layout/algorithm boundary (sphere packing,
  scene-graph LOD tree, traversal/metric result payloads) as pure TS with no DOM/renderer coupling.
  `size: M` · `stories: —`
- **M0-BE-ING-01 — Ingestion adapter behaviour (Elixir).** The `@behaviour` an ingestion source
  implements to emit a GraphDocument (used first in M4); records only the contract, no adapter.
  `size: S` · `stories: —`
- **M0-QA-01 — Fixture pack.** Small / medium / large synthetic GraphDocuments plus a curated subset
  of the `docs/diagrams/` corpus, each validating against the GraphDocument schema; the shared test
  substrate for M1+ e2e, perf, and interchange work. `size: M` · `stories: —`

## Lanes & tasks

Only **INFRA** has code-lane work in M0; the contract tasks above are the architect's parallel track.

### INFRA — scaffold, module identity, deploy wiring, CI

- **M0-INFRA-01 — Scaffold via `start-app-scaffold`.** Hydrate `vnext/app/` (Phoenix 1.8 API + Next.js
  16 / React 19 / Tailwind v4 + nginx; Guardian JWT; Phoenix channels; Liquibase canonical schema;
  `@noizu/styleguide` YAML design system). Blocks everything. `size: M` · `stories: —`
- **M0-INFRA-02 — Confirm module identity.** Working Elixir module `HoloGraph` / slug `holograph`;
  confirm no collision with the Hologram framework (the "HoloGraph" product codename is unrelated).
  `depends: M0-INFRA-01` · `size: S` · `stories: —`
- **M0-INFRA-03 — `.infra-config.yaml` two-service entry.** Backend + frontend as one composite
  project, one helm chart, tier 3 / `apps-ns`, following the `start-app` block shape.
  `depends: M0-INFRA-01` · `size: M` · `stories: —`
- **M0-INFRA-04 — Liquibase target + changelog skeleton.** One `liquibase_targets` entry (service,
  port-forward, changelog path); empty `backend/db/changelog/` master changelog ready for BE-CORE M1
  migrations. `depends: M0-INFRA-01` · `size: S` · `stories: —`
- **M0-INFRA-05 — Helm chart wiring.** Single chart serving backend + frontend; Postgres via shared
  `app-timescaledb`; env/secret placeholders (no InfisicalSecret CRDs authored yet).
  `depends: M0-INFRA-03` · `size: M` · `stories: —`
- **M0-INFRA-06 — CI pipeline.** `mix test`, `next build`, and Cypress smoke run green on the bare
  scaffold; pipeline is the standing gate for every later milestone's exit. `depends: M0-INFRA-01`
  · `size: M` · `stories: —`
- **M0-INFRA-07 — Local dev environment.** `docker-compose` for Postgres/timescaledb + backend +
  frontend + nginx; `.env` wiring from the scaffold summary; documented run recipe.
  `depends: M0-INFRA-01` · `size: S` · `stories: —`

## Integration & exit criteria

- **Scaffold builds and boots.** `mix test`, `next build`, and the Cypress smoke suite pass in CI on
  the scaffolded app (M0-INFRA-06 green).
- **All eight contract documents merged and reviewed**, versioned under
  `project-management/roadmap/` (or `docs/specs/` as the architect prefers) and referenced from the
  overview `README.md`.
- **Fixtures validate.** Every fixture in the M0-QA-01 pack loads and validates against the
  GraphDocument schema (M0-BE-CORE-01); the large fixture is oversized-by-design for M8 perf use.
- **Deploy path exists on paper.** `.infra-config.yaml` two-service entry, liquibase target, and helm
  chart are present and lint-clean; no live deploy required to exit M0.
- **Exit gate:** an M1 lane owner can begin against a frozen contract without further architect input.
  This is the objective test for "M0 done."

Demo script: run `docker-compose up`, hit the scaffold's health/login route, run the Cypress smoke —
then open each contract doc and confirm a fixture round-trips through the GraphDocument schema.

## Parallelization notes

- **Worker count: 1–2.** One INFRA worker; one architect. This is the only milestone that does not
  fan out — by design, since its outputs are what make fan-out safe.
- **Lane isolation.** INFRA owns repo-root `.infra-config.yaml`, `helm/`, `nginx/`, `docker-compose*`,
  `Makefile`, and CI files plus the scaffolded tree. The architect writes documents only (no code),
  so the two tracks never touch the same file. If a single worker runs M0, do INFRA-01 first (it
  blocks all else), then interleave the contract docs with the remaining INFRA tasks.
- **Merge order:** M0-INFRA-01 → (remaining INFRA tasks ∥ all contract docs) → CI green. Contract docs
  can merge independently as each is reviewed; they gate M1, not each other.

## Stories delivered

None. M0 is an enabling milestone; all tasks carry `stories: —`. The first product stories land in M1.
