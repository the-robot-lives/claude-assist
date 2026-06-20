---
id: ADR-008
title: "Elixir/OTP as Primary Implementation Language"
status: accepted
date: 2026-06-21
supersedes: ADR-007
---

# ADR-008: Elixir/OTP as Primary Implementation Language

> **Supersedes [ADR-007](./ADR-007-typescript-implementation-language.md).** ADR-007 chose
> TypeScript "as a pragmatic choice, not a technical one," explicitly stating that *"Elixir's
> concurrency model is superior for agent orchestration"* and that the agent runtime should be
> *"extract[ed] into an Elixir service in a future phase."* That future is now: the application
> has been re-scaffolded onto Elixir/Phoenix (`start-app`). This ADR makes that the decision of
> record and explains why the previously-cited TypeScript advantages no longer outweigh it.

## Context

The Robot Remembers is an ensemble of eight stateful, concurrent, long-lived agents that
communicate over an event bus, run scheduled background work (decay, consolidation), and must
degrade gracefully under partial failure. ADR-003 had to specify — by hand, in TypeScript — agent
lifecycle, a typed event bus with "guaranteed order + at-least-once + idempotency," and worried
that the bus was a single point of failure. ADR-007 itself enumerated everything OTP would have
given for free (supervision trees, GenServer+Registry, lightweight processes, Phoenix PubSub, the
existing Noizu framework) and chose TypeScript anyway for four reasons: LLM SDK maturity, portfolio
alignment, contributor pool, and the Weaviate client.

Three things changed that decision:

1. **The app was re-scaffolded onto Elixir 1.15 / Phoenix 1.8** with the full toolchain already
   wired: `Oban` (durable jobs + cron), `Phoenix.PubSub`, `syn`, `pgvector`, `redix`, `guardian`,
   `genai`, `noizu_labs_entities`, OpenTelemetry, `hammer`.
2. **The agent model is being right-sized to deterministic mechanics + surgical LLM** (see
   ADR-009). The system is *not* eight autonomous LLM loops; it is mostly math (decay, similarity,
   fusion, stats) with LLM at four narrow, asynchronous seams. This collapses ADR-007's central
   premise — "LLM SDK maturity" — to a minor concern: only the Dreamer, async enrichment, and
   optional sparse-recall synthesis call an LLM, and `genai` (or MCP sampling) covers them.
3. **A production MCP server library exists in-house** (`noizu_mcp`, used by NoizuPromptLingo),
   removing the need to build the agent's tool surface on the TypeScript MCP SDK.

## Decision

**Elixir / Phoenix / OTP** for the backend memory service, with:

- **The 8 agents mapped to the cheapest correct OTP construct**, not reflexively to 8 GenServers:

  | Agent | Execution shape |
  |-------|-----------------|
  | Archivist | inline `fast_enrich` + store (hot path); Oban job for async embed/mood |
  | Guardian | inline gate (schema + injection regex + cheap cosine); Oban job for deep contradiction |
  | Sentinel | inline ACL/redaction (reuse `Authz.PolicyEvaluator`) |
  | Recall Agent | inline retrieval pipeline on query |
  | Weaver | Oban `LinkJob` on `memory.stored`; weight updates |
  | Curator | Oban **cron** (decay / prune-archive / passive-edge-decay / weekly near-dup merge) |
  | Monitor | per-tenant **GenServer** via `noizu_labs_services` pool; state mirrored to ETS + Redis |
  | Dreamer | Oban cron + on-demand consolidation/synthesis |

- **`Oban`** as the durable spine for all work that must not be lost (see ADR-011).
- **`Phoenix.PubSub`** as the ephemeral event bus for notifications and cache-refresh triggers.
- **`noizu_labs_services`** (over `syn`) for per-tenant stateful agent pools (Monitor, optionally
  Weaver) — discovered cluster-wide, lazily spawned, single-instance-per-ref.
- **`noizu_mcp`** for the MCP tool surface (Streamable-HTTP + stdio, OAuth2.1, Discovery tools),
  mirroring the NoizuPromptLingo domain-server pattern.
- **`genai`** for the four LLM seams (background only); MCP **sampling** as an opt-in for
  interactive tools so the client pays for inference.
- The **house entity/`Schema.*` split** (`noizu_labs_entities`) and **Liquibase** for canonical
  schema, matching the rest of the monorepo.

## Re-evaluating ADR-007's Reasons for TypeScript

1. **LLM SDK maturity** — Largely moot under ADR-009 (LLM at four async seams, not per-agent
   loops). `genai` and MCP sampling cover them; latency/streaming aren't on any hot path.
2. **Portfolio alignment** — Inverted. Keith's primary stack is Elixir, and the closest sibling
   service (NoizuPromptLingo) is Elixir/Phoenix with the exact MCP, entity, and auth patterns we
   reuse here. Alignment now *favors* Elixir.
3. **Contributor pool** — A real but secondary trade-off for a solo/portfolio incubator project;
   outweighed by the orders-of-magnitude reduction in bespoke concurrency/lifecycle code.
4. **Weaviate client** — The semantic store stays Weaviate (per the storage decision), reached via
   an Elixir client (`noizu_weaviate` / thin `req` client per
   `skills/noizu-frameworks/kb/07-elixir-weaviate.md`). It sits behind a `Memory.VectorStore`
   behaviour, so the client's maturity is a contained dependency, not an architectural driver.

## Alternatives Considered

- **Stay on TypeScript (ADR-007).** Rejected: requires hand-building exactly the agent
  lifecycle / event-bus / supervision machinery that BEAM provides natively, and the app has
  already moved off it.
- **Polyglot: TypeScript API + Elixir agent runtime.** Rejected: two runtimes, two deploy
  artifacts, a cross-language event boundary — all cost, no benefit now that one runtime does
  everything well.
- **Python.** Rejected for the same reasons as ADR-007 (GIL, packaging, not a primary language),
  and unnecessary given the LLM surface is now small.

## Consequences

- **Positive:** Supervision, retries, back-pressure, distribution, and idempotency become
  infrastructure rather than application code. The ensemble maps directly to processes/jobs. The
  "event bus is a SPOF" risk disappears (PubSub is in-VM/self-healing; durability lives in
  Postgres-backed Oban). Maximum code reuse from NoizuPromptLingo (MCP, entities, auth, Redis,
  Oban).
- **Negative:** Smaller contributor pool than TypeScript. Embeddings must be integrated directly
  (`genai` has no embeddings API) — see ADR for embeddings/§ storage. The Weaviate Elixir client
  is community-grade and wrapped behind a behaviour.
- **Risks:** `noizu_mcp` targets Elixir ≥ 1.18 while the scaffold declares `~> 1.15` — the
  version requirement must be reconciled before adding the dep. Mitigation: bump `mix.exs` and the
  `.tool-versions` pin and verify the toolchain.

## Related

- ADR-007: TypeScript as Primary Implementation Language — **superseded by this ADR**
- ADR-003: Multi-Agent Ensemble — agents now map to OTP constructs (table above)
- ADR-009: Deterministic Ensemble + Surgical LLM — why the LLM surface is small
- ADR-010: Hot/Async Ingest Split — what runs inline vs in Oban
- ADR-011: Durability — Oban (durable) vs PubSub (ephemeral)
- ADR-001: Storage Architecture — amended to the hybrid topology
