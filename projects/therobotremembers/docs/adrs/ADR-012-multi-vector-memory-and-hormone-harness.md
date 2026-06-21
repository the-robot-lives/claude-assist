---
id: ADR-012
title: "Multi-Vector Memory + Hormone-Harness Emotion Model"
status: accepted
date: 2026-06-21
---

# ADR-012: Multi-Vector Memory + Hormone-Harness Emotion Model

> Builds on ADR-008 (Elixir/OTP), ADR-010 (hot/async ingest), ADR-011 (durability), and refines
> ADR-001 (storage), ADR-002 (emotional model), and ADR-004 (retrieval). This is the consolidated
> record of the multi-vector + hormone-harness enhancement.

## Context

The original design embedded a single `content` text per memory and asked the agent to supply a
full 7-dimensional emotional reading (VAD + four hormones). Two refinements emerged from how
agents actually form memories:

1. **A memory has several facets, not one.** When an agent registers a memory it can say more than
   *what happened*: it can describe *what it was doing at the time*, *how it felt about it*, and
   *what it was reminded of*. Each facet is a legitimate, independent way the memory might later be
   retrieved — and collapsing them into one blob loses that.
2. **An agent cannot meaningfully self-report numeric hormone levels.** Asking the caller for
   `cortisol: 0.6` per memory is both unnatural and noisy. Hormones are better modeled as a slow
   internal state of the "robot" that *drifts with experience* and is *sampled* at the moment a
   memory forms — which is also exactly the "emotional signature of the moment" the project is
   built on.

## Decision

### 1. Four agent-authored texts → four OpenAI named vectors

On `remember`, the agent supplies up to four texts (only `content` is required; the rest are
optional but strongly encouraged):

| Field | What it is | Retrieval role |
|-------|-----------|----------------|
| `content` | The memory / event itself | primary semantic match |
| `context` | **What the agent was doing** when the memory was registered (situational/activity) | situational match ("when I was refactoring auth") |
| `reflection` | The agent's brief thoughts/feelings/mood **in words** | affective/first-person match |
| `tangent` | What else the memory makes the agent think of | associative-leap match |

Each text is embedded with **OpenAI `text-embedding-3-small` (1536-d)** behind the
`Memory.Embeddings` behaviour (ADR-010 §embeddings). The **four texts are stored in Postgres**
(system of record + `pg_trgm` lexical fallback); the **four vectors are stored in Weaviate as
named vectors** (`content`/`context`/`reflection`/`tangent`, `vectorizer: none` / BYO) on one
object keyed by the memory UUID. (`noizu_weaviate`'s DSL does not expose named vectors → use a
thin `req`-based BYO-vector client; fallback is four objects/collections sharing `memory_id`.)

`context` is **distinct from the structured contextual metadata** (domain, collaborators,
time-of-day, session, modality), which remains for filtering. `context` is a free-text situational
descriptor that becomes its own semantic retrieval path.

**Recall** embeds the query once and searches all four named vectors, fusing them as four RRF
rank-lists with per-facet weights (default `content 1.0 / context 0.8 / tangent 0.8 /
reflection 0.7`), alongside the emotional/temporal/graph paths (ADR-004).

### 2. The tangent seeds an association

Beyond being searchable, the `tangent` is the agent **authoring a link**. On the async path the
**Weaver** embeds the tangent, finds the existing memory whose `content`/`reflection` it most
resonates with, and creates an explicit `tangent`-type association edge. This operationalizes the
"free-association web" from first-person intent rather than inferred similarity alone. (`context`
similarity may additionally feed the Weaver's normal `contextual` linking, but does not seed a
dedicated edge.)

### 3. Hormones are harness-maintained; VAD is agent-supplied

The 7-dimensional emotional vector (ADR-002) is split by *who provides it*:

- **VAD (valence, arousal, dominance) — agent-supplied** per memory (the agent's self-assessed
  mood at the moment; may be inferred from `reflection` as a fallback if omitted).
- **Hormones (cortisol, dopamine, oxytocin, serotonin) — harness state owned by the Monitor.**
  The Monitor maintains a per-agent running hormone level that **adjusts to interactions** and
  **relaxes toward a disposition baseline** (ADR-009) over time:

  | Hormone | Rises on | Models |
  |---------|----------|--------|
  | Cortisol | contradiction / quarantine / anomaly / sustained frustration | stress, alarm |
  | Dopamine | successful recall / reinforcement / positive feedback | reward, breakthrough |
  | Oxytocin | collaborative interactions (multiple collaborators, positive social context) | trust, bonding |
  | Serotonin | calm, low-conflict, stable stretches | steady-state contentment |

At formation, each memory is **stamped with the Monitor's current hormone snapshot**, so the
stored 7-d resonance vector is `agent VAD ++ Monitor hormones`. Emotional resonance recall
(ADR-002/ADR-004) is unchanged — it still operates on the full 7-d vector.

## Alternatives Considered

- **One concatenated text + one vector.** Rejected: loses the ability to match on a single facet
  (e.g. a query that only resonates with *what the agent was doing* or *what it was reminded of*),
  which is the whole point of capturing the facets separately.
- **Agent supplies hormones too (original ADR-002).** Rejected: agents can't reliably assign
  numeric hormone values; per-memory self-report is noisy and unnatural. Harness-maintained
  hormones are easier for the caller and produce a genuine temporal/affective signature shared
  across memories formed in the same "stretch."
- **Hormones inferred per memory by an LLM at formation.** Rejected for the hot path (LLM latency,
  ADR-010); the Monitor's deterministic state machine is cheaper, faster, and gives the desired
  cross-memory continuity. (LLM inference remains available for VAD as an async fallback.)
- **`context`/`reflection`/`tangent` as plain metadata, not vectors.** Rejected: they are most
  valuable as *retrieval coordinates*; embedding them is what lets recall find a memory through
  any facet.

## Consequences

- **Positive:** Much richer retrieval surface — a memory can be found by what happened, what the
  agent was doing, how it felt, or what it evoked. The tangent turns recall into genuine
  association authored by the agent. Hormones-as-harness-state is more faithful and removes an
  impossible burden from the caller; it elevates the **Monitor** to keeper of the emotional state
  that drives both formation stamping and tangential-recall bucketing.
- **Negative:** Four embeddings per memory ⇒ ~4× embedding cost/latency and more Weaviate write
  volume (all on the async tail, ADR-010, so not on the capture hot path). The cross-store
  consistency surface (ADR-001) now covers four named vectors per object. Provider swaps
  re-vectorize four columns (the versioned backfill job, ADR-010, handles this).
- **Risks:** A miscalibrated hormone state machine could skew every memory's emotional signature.
  Mitigation: bounded per-event deltas, relaxation to baseline, and `tune_config` runtime
  tuning (ADR-009); the four raw texts are retained so any vector can be recomputed.

## Related

- ADR-002: Emotional Metadata Model — amended: VAD agent-supplied, hormones harness-maintained
- ADR-001: Storage Architecture — amended: four named text vectors in Weaviate (BYO)
- ADR-004: Dual Retrieval Modes — recall fuses four semantic rank-lists; tangent/context paths
- ADR-009: Deterministic Ensemble + Surgical LLM — the Monitor's hormone state machine; dispositions
- ADR-010: Hot/Async Ingest Split — embeddings + Weaviate upsert run on the async tail
