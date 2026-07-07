---
id: ADR-013
title: "Apache AGE Projection Layer for the Association Graph"
status: accepted
date: 2026-07-05
---

# ADR-013: Apache AGE Projection Layer for the Association Graph

> Amends ADR-006 (Graph Storage in PostgreSQL). ADR-006 named Apache AGE as the
> scale-out target to "evaluate first" behind the `GraphStore` seam. This ADR settles the
> role AGE plays now that the production DB image ships it: AGE is a **projection** of the
> canonical relational graph, not a replacement for it, and recall stays on the recursive CTE.

## Context

The association graph is canonical in PostgreSQL (ADR-006): `memories` and `association_edges`,
both `uuid`-keyed. Each edge carries a `weight real` in `[0,1]`, an `edge_type` enum
(`semantic | emotional | temporal | causal | co_occurrence | synthetic | contextual | tangent`),
and Hebbian reinforcement bookkeeping that adjusts `weight` over time (ADR-005). Recall is a
Weaviate-seeded, recursive-CTE **spreading activation**: from seed memories, walk ≤ 3 hops
following edges with `weight >= 0.2`, capped at a per-node fan-out of 8, scoring each path by the
**product of its edge weights** (ADR-004).

ADR-006 chose the recursive CTE over a dedicated graph DB and deliberately left a swappable
`GraphStore` seam, naming AGE as the first thing to evaluate if the CTE degraded — with the caveat
that AGE "is not available in all managed PostgreSQL offerings." That caveat no longer applies: the
production database image (`timescaledb-ha-with-age`, PostgreSQL 17.9 / **AGE 1.7.0**) already ships
the extension. AGE is therefore available at no new operational surface. The open question this ADR
answers is: given AGE is in the image, what should it actually do?

## Decision

### AGE is a projection, not the system of record

The PostgreSQL tables remain the single source of truth for the graph. AGE holds a **derived mirror**
of them, maintained by a `GraphMirror` worker:

- **Vertices** — one `Memory` label per memory, keyed by `ext_id` = the shared memory `uuid`. The
  AGE vertex is a thin handle back to the canonical row, not a copy of memory content.
- **Edges** — **one AGE edge label per `edge_type`** (`semantic`, `emotional`, … `tangent`), with
  properties `weight`, `reinforcement_count`, and `last_reinforced_at`.
- **Only edges with `weight >= 0.2` are mirrored** — the same threshold recall traverses. An edge is
  removed from AGE when Hebbian decay (ADR-005) drops it below the threshold, and (re)added when
  reinforcement lifts it back. A periodic **reconcile sweep** repairs drift and handles PostgreSQL
  cascade-deletes, which do not propagate into AGE automatically.

### Recall stays on the recursive CTE

The recall hot path is **not** moved to AGE. AGE's variable-length edge (VLE) expansion is a poor fit
for weighted, capped, bounded spreading activation for concrete reasons:

- VLE traversal **bypasses indexes** (`apache/age#195`) — the CTE instead rides **partial
  `(source_memory_id, weight DESC)` indexes** applied at every hop.
- VLE **cannot express the per-node fan-out cap** (top-8 neighbours by weight) — a first-class part
  of the recall algorithm.
- VLE **enumerates all matching paths before filtering**, rather than pruning as it walks.
- AGE has **no native weighted shortest path** (no Dijkstra/A*). Weighted traversal in AGE has to be
  written as a `MATCH` over a variable-length path plus `reduce()`/`sum` over `relationships(p)` — and
  `reduce()` itself requires **AGE >= 1.7.0** (satisfied by the shipped image, but still slower and
  less selective than the indexed CTE).

### Where AGE is used

AGE earns its place on queries the CTE expresses badly — heterogeneous, multi-label pattern matching
and offline graph work:

- **Dreamer / consolidation** — multi-label Cypher pattern queries that generate `causal`,
  `co_occurrence`, and `synthetic` edges.
- **Recall explanation** — subgraph extraction and path explanation in recall output.
- **Offline analytics** — community detection and hub detection.
- **Phase-D graph-view API** — the per-agent memory-graph view.

### Promotion criteria (Phase C)

AGE is promoted onto the recall hot path only if it earns it. Phase C runs a **side-by-side benchmark
of the recursive CTE vs AGE traversal** on the real edge distribution at **>= 100k** and **>= 1M**
edges. AGE replaces the CTE for recall **only if** the recall **p99 stays under the 1 s budget**
(ADR-006's alert threshold). Absent that result, recall stays on the CTE and AGE remains a projection.

### Operational notes

- `CREATE EXTENSION age` runs **only in the TRR database** on the shared instance — not cluster-wide.
- Each session runs `LOAD 'age'` and sets `search_path` (with `ag_catalog` **last**) via the Ecto
  `Repo` `after_connect` hook (ADR-008), gated by an **`AGE_GRAPH_ENABLED`** runtime flag so the
  projection can be switched off without a deploy.
- Labels are **pre-declared** before use.
- **Indexes are created before data load** (`apache/age#1010`) — building them after bulk insert is a
  known pathology.
- Bulk backfill is **batched**; past ~1M edges, use **AGEFreighter** for the initial load.

### Tenancy: a shared graph, owner-scoped reads

The association graph — and therefore its AGE projection — is a **shared substrate, not an
owner-partitioned store.** `association_edges` are not scoped by owner: recall traverses them
owner-agnostically, and Hebbian reinforcement (ADR-005) **deliberately** wires `co_occurrence` edges
across owners when an owner-less recall over `classification = open` memories co-recalls memories of
different agents. This is intentional — it lets shared/open memories accrue a cross-agent
associative web.

Isolation is enforced on **read**, not in the edge data. `Memory.Recall` re-scopes every result
through `base_scope/1` plus the `Sentinel.authorize/2` backstop, so a cross-owner edge can influence
ranking but never surfaces another owner's memory (an owned recall returns only the owner's rows; an
owner-less recall returns only `open` rows; `restricted`/`sealed` never enter the shared set). The
Phase-D graph-view API is owner-scoped defensively on top of this: `GET …/graph` returns only the
agent's own nodes and only edges whose **both** endpoints are owned, and edge `PATCH` rejects any
edge touching a non-owned memory (see `docs/memory-ui-api-contract.md`). Any future traversal that
returns graph-reached rows must preserve these read guards, or it would leak across owners. This is
the accepted decision recorded in **ADR-014**.

## Alternatives Considered

- **AGE as the system of record.** Rejected. It forfeits the FK **cascade semantics** that keep the
  graph consistent with `memories`, the Ecto ergonomics the rest of the app relies on (ADR-008), and
  the battle-tested CTE recall path — while adding `agtype` storage/serialization overhead.
- **CTE only, no AGE at all.** Rejected. The roadmap (consolidation pattern generation, path
  explanation, community/hub analytics, the graph-view API) needs **Cypher ergonomics** for
  heterogeneous multi-label pattern queries that are painful to express as recursive SQL.
- **Mirror all edges (no threshold).** Rejected. Sub-0.2 edges are **recall-irrelevant by policy**
  (recall never traverses them) and mirroring them only **bloats the un-indexable VLE expansion**,
  making the AGE-side queries slower for no benefit.

## Consequences

- **Positive:** AGE is available for the graph queries that genuinely need Cypher, with no new
  database to operate. Recall keeps its indexed, capped, weight-pruned CTE and its performance
  characteristics are unchanged. The projection is disposable — it can be dropped and rebuilt from the
  canonical tables at any time, and gated off entirely via `AGE_GRAPH_ENABLED`. The `GraphStore` seam
  from ADR-006 is realized without committing recall to a new engine.
- **Negative:** A second, eventually-consistent representation of the graph must be maintained. The
  `GraphMirror` worker, the threshold add/remove logic, and the reconcile sweep are new moving parts,
  and PostgreSQL cascade-deletes require the sweep to stay correct. Some write amplification: qualifying
  edge changes now touch AGE as well as the canonical row.
- **Risks:** Mirror drift (AGE diverging from `association_edges`) would corrupt analytics and the
  graph view. Mitigation: the reconcile sweep is authoritative and idempotent, and AGE is never the
  source of truth, so drift is repairable rather than data loss. If the Phase C benchmark shows AGE
  cannot hold the p99 budget, recall simply stays on the CTE — the projection role does not depend on
  that result.

## Phase C — Benchmark

The `mix trr.bench.graph` task (`TheRobotRemembers.Bench.GraphBench`) runs the side-by-side
comparison the promotion criteria call for: the recall recursive CTE vs. the AGE variable-length
traversal, on synthetic `association_edges` with a realistic weight distribution (~20% sub-`0.2`,
the rest a beta-ish bell in 0.3–0.7) across all eight edge types, over random Weaviate-sized
frontiers. Both backends run the same top-K on the same connection; the harness reports p50/p95/p99
per backend. The CTE side is copied verbatim from `Memory.Recall`; the AGE side is the un-capped
`MATCH p = (s:Memory)-[*1..3]-(m:Memory)` expansion (weighted via `UNWIND relationships(p)` +
`exp(sum(log(weight)))`) — the very form ADR-006 flags as index-bypassing and fan-out-uncapped.

Run against the AGE-provisioned TRR database (AGE installed + Liquibase 031 applied; the shared
instance needs a Postgres port-forward):

    AGE_GRAPH_ENABLED=true mix trr.bench.graph --scale-sweep --queries 50 --seed-size 40
    # single point:
    AGE_GRAPH_ENABLED=true mix trr.bench.graph --nodes 100000 --edges 500000 --queries 50 --seed-size 40

### Results (per-query latency, ms)

| edges | backend | p50 | p95 | p99 | mean |
|------:|---------|----:|----:|----:|-----:|
| 100k  | CTE     | _pending_ | _pending_ | _pending_ | _pending_ |
| 100k  | AGE     | _pending_ | _pending_ | _pending_ | _pending_ |
| 1M    | CTE     | _pending_ | _pending_ | _pending_ | _pending_ |
| 1M    | AGE     | _pending_ | _pending_ | _pending_ | _pending_ |

> Results pending a run against the AGE-enabled database — none was reachable from the build
> environment at authoring time (local Postgres refused; the shared instance needs a port-forward).
> Populate both rows per scale point from the harness's printed table.

### Decision rule

Promote AGE onto the recall hot path **iff AGE's p99 stays < 1 s at both >= 100k and >= 1M edges**
(ADR-006's alert threshold). Otherwise recall stays on the CTE and AGE remains a projection
(Dreamer/consolidation, path explanation, analytics, the graph-view API).

**Decision: PENDING** — awaiting the run above.

## Related

- ADR-006: Graph Storage in PostgreSQL — amended: AGE is adopted as a projection of the canonical
  tables (not a migration target that replaces the CTE); the shipped DB image resolves ADR-006's
  "not available in managed Postgres" caveat.
- ADR-004: Dual Retrieval Modes — recall's spreading-activation traversal stays on the recursive CTE.
- ADR-014: Cross-Owner Association Edges — the accepted decision that the graph is a shared substrate and isolation is enforced on read (the Tenancy section above is its summary).
- ADR-005: Hebbian-Like Weight Dynamics — decay/reinforcement drives the `weight >= 0.2` mirror
  threshold and the add/remove of AGE edges.
- ADR-008: Elixir/OTP Implementation — `Repo` `after_connect` session setup and the `GraphMirror`
  Oban worker.
- ADR-012: Multi-Vector Memory + Hormone Harness — Weaver-authored `tangent` edges are mirrored like
  any other edge type once they cross the threshold.
