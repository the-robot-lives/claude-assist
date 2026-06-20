---
id: ADR-010
title: "Hot/Async Ingest Split"
status: accepted
date: 2026-06-21
---

# ADR-010: Hot/Async Ingest Split

## Context

The user stories impose two requirements on memory capture that, taken together, are
contradictory:

- **story-001:** capture a memory *with full emotional metadata* in **< 200 ms**.
- **story-005:** run **contradiction detection** against existing memories at ingest in < 500 ms,
  with severity classification.

But high-fidelity mood inference and semantic contradiction classification need LLM calls
(seconds), and generating a content embedding via a remote model can alone consume the entire
200 ms budget. If capture blocks on any of these, it cannot meet its latency target and becomes
fragile to LLM/embedder latency or outage. ADR-001 already noted Weaviate writes should be
"fire-and-forget with retry queue" — this ADR generalizes that principle to the whole enrichment
tail.

## Decision

**Split ingest into a fast synchronous head and a durable asynchronous tail.**

### Synchronous head (the hot path — target < 200 ms, no network LLM)

1. **Compute the emotional vector** — pure arithmetic from the supplied/observed VAD + hormone
   values (no network). This means emotional-resonance recall works *immediately*, before any
   embedding exists.
2. **Cheap Guardian gate** — JSON-schema validation + injection/poisoning regex/heuristics +
   *cheap* contradiction (a pgvector cosine top-k against same-compartment memories). Pass →
   store; suspicious → quarantine.
3. **Store** the memory row (`state = consolidating`, `content_embedding = null`,
   `confidence = low` if mood was inferred-pending) and **return** the id + status to the caller.

### Asynchronous tail (Oban jobs — seconds-tolerant, durable, retryable)

- **EmbeddingWorker:** generate the content embedding, upsert it to Weaviate (keyed by memory
  UUID), flip `state → active`.
- **EnrichJob (Archivist):** mood inference via `genai` when the caller omitted mood; updates the
  emotional vector and raises `confidence`.
- **LinkJob (Weaver):** discover and write association edges across the five dimensions.
- **DeepCheckJob (Guardian):** LLM contradiction classification when the cheap cosine signal was
  ambiguous; may quarantine or raise `integrity.contradiction` after the fact.

State transitions: `consolidating → active` (embedding landed) — and the **partial HNSW index
covers `state IN ('active','consolidating')`** so the memory is indexable as soon as its vector
exists. A memory is recallable by emotion the instant it is stored, and by content the instant the
embedding tail completes.

## Alternatives Considered

- **Fully synchronous ingest** (embed + mood + contradiction inline). Rejected: cannot meet the
  200 ms budget; fragile to external-service latency/outage; couples capture availability to LLM
  availability.
- **Fully asynchronous ingest** (return before any validation). Rejected: Guardian's cheap gate
  (schema + injection) is a safety control that must run before a memory is visible — we keep it
  on the hot path because it is cheap.
- **Synchronous embed, async everything else.** Viable for batch import with a local embedder, but
  rejected as the default because a remote embedder blows the budget. Embedding placement is a
  per-call/policy flag; default is async.

## Consequences

- **Positive:** Capture is genuinely fast and resilient. Emotional recall is available instantly.
  Enrichment quality improves behind the scenes without blocking the caller. The expensive LLM
  seams (ADR-009 a, b) live here, off the hot path.
- **Negative:** A memory is briefly "thin" (no content embedding, possibly `confidence: low`)
  between the head and the tail completing — content recall and full metadata are eventually
  consistent. Callers must treat `confidence`/`state` accordingly.
- **Risks:** Tail backlog under load delays embedding/linking. Mitigation: Oban queue concurrency
  caps + Hammer rate-limits as back-pressure; `state`/`confidence` make thin memories observable;
  EmbeddingWorker batches to cut per-item cost.

## Related

- ADR-009: Deterministic Ensemble + Surgical LLM — the LLM seams that live in the async tail
- ADR-011: Durability — why the tail is Oban (durable), not PubSub
- ADR-001: Storage Architecture — partial HNSW over `active`/`consolidating`; Weaviate upsert
- story-001, story-004, story-005, story-006 — the requirements reconciled here
