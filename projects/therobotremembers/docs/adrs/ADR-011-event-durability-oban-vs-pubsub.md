---
id: ADR-011
title: "Event Durability: Oban (durable) vs PubSub (ephemeral)"
status: accepted
date: 2026-06-21
---

# ADR-011: Event Durability — Oban (durable) vs PubSub (ephemeral)

## Context

ADR-003 specifies a typed event bus with "guaranteed order + at-least-once delivery + idempotency
keys" and flags that the bus is a potential single point of failure. On the Elixir runtime
(ADR-008) the obvious bus is `Phoenix.PubSub` — but PubSub provides **none** of those guarantees:
it is fire-and-forget, in-memory, with no durability and no cross-process ordering. Encoding the
memory-formation state machine (observed → enriched → validated → stored → associated →
consolidated) as a chain of PubSub hops would be unsafe: a dropped message would silently skip
linking or consolidation.

We need a clear rule for which mechanism carries which kind of event so that correctness never
depends on a delivery guarantee the transport doesn't make.

## Decision

**Split events by durability requirement.**

### Oban = durable work that must happen (exactly-once-ish)

All state-advancing work runs as Oban jobs (Postgres-backed, retried with backoff,
`unique`-constrained, idempotent on an event id):

- content embedding → Weaviate upsert; async mood enrichment (ADR-010 tail)
- Weaver association linking
- Guardian deep contradiction check
- Curator decay / prune-archive / passive-edge-decay / near-dup merge (cron)
- Dreamer consolidation/synthesis (cron + on-demand)
- recall **reinforcement** (decision computed inline, write enqueued as a `unique` job per recall)

The durable formation tail (store → link → consolidate) is an Oban chain keyed by `memory_id`,
**not** PubSub choreography. Idempotency: every event carries a UUID; workers use
`unique: [keys: [:memory_id], ...]`; writes are upserts (`association_edges` has
`UNIQUE(source,target,type)`); reinforcement is clamped `LEAST/GREATEST` and deduped per
`recall_session_id`.

### PubSub = ephemeral notifications that self-heal

`Phoenix.PubSub` (topics `mem:{tenant}:{family}` — formation/association/lifecycle/recall/integrity)
carries only events where a loss self-heals:

- LiveView dashboard / operator live updates
- Monitor "nudge" signals (e.g. a quarantine spikes cortisol)
- hot-index cache-refresh triggers

PubSub→Oban **bridge subscribers** translate a notification into durable work when needed (e.g.
`memory.stored` → enqueue `Weaver.LinkJob`). The synchronous formation head (enrich → validate →
store) is plain sequential code inside one DB transaction, so its ordering is guaranteed trivially —
no bus involved.

## Alternatives Considered

- **Everything over PubSub** (ADR-003's implied design). Rejected: no durability/ordering; lost
  messages corrupt state; would require re-implementing a broker.
- **A dedicated broker (NATS / RabbitMQ / Redis Streams).** Rejected: adds operational surface and
  a real SPOF for guarantees Oban already provides on infrastructure we already run (Postgres).
- **`Oban` for everything, including notifications.** Rejected: dashboard ticks and cache-refresh
  hints don't need durability; PubSub is cheaper and lower-latency for those.

## Consequences

- **Positive:** Correctness lives in the DB transaction + Oban, so a lost broadcast can never
  corrupt state. The "bus is a SPOF" risk dissolves: PubSub is in-VM/distributed and self-healing;
  the durable spine is Postgres-backed and cluster-safe. Retries/backoff/uniqueness are free.
- **Negative:** Two mechanisms to reason about; developers must correctly classify each event as
  durable-work vs notification. Oban adds rows/load to Postgres (pruned by `Oban.Plugins.Pruner`).
- **Risks:** Mis-classifying a durable step as a PubSub notification reintroduces silent loss.
  Mitigation: the rule is documented here and enforced in review; the bridge-subscriber pattern is
  the single sanctioned PubSub→durable seam.

## Related

- ADR-003: Multi-Agent Ensemble — the event taxonomy this ADR makes durable
- ADR-008: Elixir/OTP Implementation — Oban + PubSub are already in the supervision tree
- ADR-010: Hot/Async Ingest Split — the async tail is Oban for exactly this reason
