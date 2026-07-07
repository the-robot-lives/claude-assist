---
id: ADR-014
title: "Cross-Owner Association Edges Are Intentional (Shared Open-Memory Graph)"
status: accepted
date: 2026-07-05
---

# ADR-014: Cross-Owner Association Edges Are Intentional (Shared Open-Memory Graph)

> Records a tenant-isolation decision surfaced during Phase-A verification of the AGE projection
> (ADR-013): the recall path can co-recall memories belonging to different owners, and Hebbian
> reinforcement then wires them together. This ADR settles whether that is a leak or a feature.
> ADR-013's "Tenancy" section and `docs/CONCEPTS.md` carry the tight in-context summary; this is the
> full decision record.

## Context

Two existing behaviors interact:

- **Recall scoping.** `Memory.Recall.base_scope/1` restricts candidates by owner when the caller has
  one, and **falls back to `classification = 'open'` across all owners when it does not**:

  ```elixir
  defp base_scope(owner) do
    q = from(m in Memory, where: m.state in @active_states)
    if owner, do: where(q, [m], m.owner_agent == ^owner), else: where(q, [m], m.classification == :open)
  end
  ```

  `Agents.Sentinel` is the policy authority: `owner_scope/1` yields the owner or `nil`, and
  `authorize/2` is the post-fusion backstop (`owner == nil → classification :open`; otherwise
  `mem_owner == owner`). Every recall path applies both the in-query scope (`base_scope` /
  `hydrate`) **and** the `Sentinel.authorize/2` backstop.

- **Hebbian reinforcement.** After a recall, `Workers.ReinforcementWorker.hebbian/1` takes the top-6
  co-recalled memory ids and inserts a `co_occurrence` edge for **every** unordered pair (initial
  weight `0.3`, `created_by: "hebbian"`, `on_conflict: :nothing`). It does **not** filter the pairs
  by owner.

The interaction: an **owner-less (agentless) recall** returns `:open` memories that may belong to
different owners; Hebbian reinforcement then creates **cross-owner `co_occurrence` edges** among
them. Those edges persist, are mirrored into AGE (they clear the `0.2` mirror threshold, ADR-013),
and are traversed by the recall CTE, which walks `association_edges` **owner-agnostically**.

The question: is a cross-owner edge a tenant-isolation leak that must be prevented, or the intended
mechanism of a shared memory graph?

## Decision

**Accept cross-owner `co_occurrence` edges as intentional shared-open-memory design.** They only
ever connect memories that were *co-recalled in the owner-less path*, which by construction are
`classification = 'open'` — i.e. shared/public memories. Wiring the open corpus into a shared
associative web (co-recalled open memories become linked, so future recall surfaces them together)
is a feature of the shared memory, not a defect.

Crucially, the edges do **not** widen what any caller can read, because the recall paths confine
results independently of the edge topology:

- **Owned recall** — `hydrate/2` re-applies `base_scope(owner)` (`owner_agent == owner`) and
  `Sentinel.authorize/2` drops any non-owned row. A cross-owner edge can therefore influence the
  graph path's contribution to **ranking** (its target id may enter the fused candidate list) but
  can **never** surface another owner's memory in the results — the id is filtered at `hydrate`
  and again at `authorize`.
- **Owner-less recall** — `hydrate`/`authorize` confine results to `classification = 'open'`, so
  only open↔open structure is ever exposed.

Restricted and sealed memories never enter the owner-less co-recall set, so cross-owner edges never
encode non-open content.

**Defense in depth (Phase-D graph API).** The per-agent graph API owner-scopes reads regardless of
this decision: `GET …/graph` returns only the agent's own nodes and only edges whose **both**
endpoints are in that node set, and edge `PATCH` returns `403` for any edge touching a memory the
agent does not own. So cross-owner edges are neither exposed nor editable through the per-agent view.

### Invariant to preserve

The safety of cross-owner edges is a property of the **recall guards**, not of the edge data. Any
future recall (or graph-view) path that traverses `association_edges` MUST, before returning rows:
(1) rely on `base_scope(nil)` filtering `classification = 'open'`; (2) re-apply `base_scope(owner)`
via `hydrate/2`; and (3) pass rows through `Sentinel.authorize/2`. A path that returns a memory
reached purely by graph traversal, without the owner/classification filter, would leak across
owners. New traversal features (Phase B/D) must not bypass these three guards.

## Alternatives Considered

- **(a) Filter Hebbian edge creation to same-owner pairs.** Rejected. It would stop the shared open
  corpus from ever developing cross-agent associations — defeating the shared-memory design — and
  add an owner lookup to the hot reinforcement pair loop. Because the edges are not a read leak (see
  Decision), the filter solves a non-problem.
- **(b) Owner guard on the owner-less recall path (forbid agentless recall).** Rejected. The
  owner-less path *is* the intended open/shared read surface — agentless callers and cross-agent
  shared knowledge. Removing it would break shared-memory recall, and the `classification = 'open'`
  gate already bounds what it can return.
- **(c) Accept cross-owner edges as intentional shared-memory design.** **Chosen** — no code change;
  reads remain owner/classification-safe through the existing guards.

## Consequences

- **Positive:** The open corpus accrues an emergent shared associative web; agentless and cross-agent
  recall benefit from open co-occurrence structure. No code change and no new failure mode; reads
  stay owner/classification-safe via guards that already exist and are already tested.
- **Negative:** `association_edges` is **not** owner-partitioned. A cross-owner edge can influence the
  RRF graph rank-list of an owned recall (its id occupies a candidate slot that is then filtered out
  at `hydrate`). Cross-owner edges accumulate from any open co-recall, including unauthenticated
  agentless traffic, so the open subgraph's shape is shaped in part by anonymous usage.
- **Risks:** Isolation depends on the recall guards, not the data — a future path that returns
  graph-reached rows without re-scoping would leak across owners (see the Invariant). Mitigations:
  the invariant above; `Sentinel` as the single policy authority and final filter; the graph API's
  defensive owner-scoping. Separately, a memory must never be re-classified/downgraded to `open`
  while carrying content that should stay private, or it would join the shared set.

## Related

- ADR-005: Hebbian-Like Weight Dynamics — the `co_occurrence` edge policy that produces these edges
- ADR-004: Dual Retrieval Modes — the recall paths and the `Sentinel.authorize/2` backstop that keep
  results owner/classification-safe despite owner-agnostic graph traversal
- ADR-001: Three-Layer Storage Architecture — the `open`/`restricted`/`sealed` classification levels
- ADR-013: Apache AGE Projection Layer (Tenancy section) — cross-owner edges are mirrored like any
  other `>= 0.2` edge; the AGE-side traversal is likewise owner-agnostic (isolation is enforced on
  read, not in the graph)
- Phase-D Memory UI / MCP API contract (`docs/memory-ui-api-contract.md`) — graph reads are
  owner-scoped defensively and edge edits reject cross-owner endpoints
