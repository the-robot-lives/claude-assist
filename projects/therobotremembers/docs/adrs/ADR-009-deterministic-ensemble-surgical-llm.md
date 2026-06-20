---
id: ADR-009
title: "Deterministic Ensemble with Surgical LLM"
status: accepted
date: 2026-06-21
---

# ADR-009: Deterministic Ensemble with Surgical LLM

## Context

The persona documentation (10 personas) and ADR-003 describe eight "synthetic agents" with
emotional dispositions and emergent tensions. Read literally, this suggests eight autonomous,
LLM-reasoning agents. That reading is incompatible with the system's own latency budgets and with
operating cost:

- Tangential insertion must return in **< 100 ms**; active recall in **< 2 s** P95; capture in
  **< 200 ms**. An LLM call (hundreds of ms to seconds) on any of these paths breaks them.
- Eight always-on LLM loops are expensive, non-deterministic, and effectively untestable.
- The actual work most agents do is **arithmetic**: decay curves, cosine/L2 similarity,
  rank fusion, rolling statistics, ACL checks. None of it needs a language model.

We need a model of "how agentic" each agent is that preserves the project's identity (goal #4 —
emergent behavior from agent tensions) without paying for autonomy we don't use.

## Decision

**The ensemble is deterministic algorithms (~85%) with surgical LLM calls at exactly four seams,
all asynchronous and off every hot path.**

### Deterministic (no LLM)

| Agent | Deterministic responsibility |
|-------|------------------------------|
| Monitor | Rolling-window stats; EMA of mood/hormones; frustration index; z-score anomaly detection |
| Archivist (hot) | Contextual metadata computation; use caller-supplied mood as-is; schema fill |
| Guardian (hot) | JSON-schema validation; injection/poisoning regex + heuristics; cheap cosine contradiction (pgvector top-k vs same-compartment) |
| Weaver | Similarity-thresholded linking across 5 dimensions; Hebbian weight math; edge decay |
| Curator | Effective-half-life decay math; prune/archive/promote rules; merge detection |
| Sentinel | Compartment/classification ACL; field redaction (reuse `Authz.PolicyEvaluator`) |
| Recall Agent | Multi-path retrieval; RRF fusion; emotional-resonance boost; MMR winnow; XML/parenthetical formatting |

### Surgical LLM (via `genai`, async/off-hot-path)

| Seam | Agent | When | Latency tolerance |
|------|-------|------|-------------------|
| (a) Mood inference when caller omits mood | Archivist | Oban enrich job; capture already returned with `confidence: low` | seconds |
| (b) Deep semantic contradiction | Guardian | Oban job, only when cheap cosine is *ambiguous* | seconds |
| (c) Consolidation / synthesis | Dreamer | Oban cron + on-demand; the one genuinely generative agent | minutes |
| (d) Sparse-active-recall synthesis | Recall Agent | active mode only, only if results sparse, **off by default** behind a flag | < 2 s (active only) |

Tangential insertion **never** calls an LLM.

### Dispositions as real parameters (how tensions stay emergent)

Each agent's "emotional disposition" is encoded as concrete, tunable thresholds — not flavor text:

- Guardian's high cortisol baseline **lowers** its contradiction/quarantine threshold (more
  suspicious).
- Dreamer's high dopamine **raises** its speculative-link propensity.
- Curator's stability bias **raises** its prune grace period; Sentinel's caution **tightens**
  redaction defaults.

The documented tensions (Guardian↔Archivist throughput, Weaver↔Curator connectivity-vs-pruning,
Sentinel↔Weaver/Dreamer privacy-vs-association) then **emerge deterministically** from competing
thresholds operating on the same data — exactly ADR-003's claim, achieved without LLM autonomy.
Thresholds are runtime config with per-tenant overrides, tunable without a deploy (`tune_config`
MCP/operator tool). Every agent action emits a narrated event (`source_agent`, human-readable
`reason`) so the dashboard and `agent_logs` tool tell the agents' "story."

## Alternatives Considered

- **Fully LLM-driven autonomous agents** (one ReAct loop per agent). Rejected: breaks the latency
  budgets, expensive, non-deterministic, untestable. Most faithful to a literal reading of the
  personas, least faithful to the system's stated requirements.
- **No LLM at all (pure algorithmic) for v1.** Considered and partially adopted: v1 (Phases 0–2)
  is in fact pure algorithmic; the four LLM seams arrive in Phases 3–4. This ADR defines the
  end-state; the roadmap defers the seams.

## Consequences

- **Positive:** Fast, cheap, deterministic, testable. Latency budgets are achievable. The
  generative magic (Dreamer) is preserved where it fits the archetype. Identity/narrative survive
  as tuning parameters + narrated events.
- **Negative:** Agents are less "alive" than a literal persona reading implies; their personalities
  live in numbers and logs, not in free-form LLM monologue. Mood inference quality depends on a
  cheap model and is async (memories may carry `confidence: low` until enriched).
- **Risks:** Mis-tuned dispositions could produce pathology (mutual rejection, runaway Hebbian
  reinforcement). Mitigation: weight clamps `[0.05, 1.0]`, Curator prune-guards, Dreamer
  diversity injection, Monitor anomaly alarms, and per-tenant tunable thresholds.

## Related

- ADR-003: Multi-Agent Ensemble — the conceptual model this ADR makes buildable
- ADR-008: Elixir/OTP Implementation — the runtime the agents map onto
- ADR-010: Hot/Async Ingest Split — why seams (a) and (b) are off the hot path
- ADR-002: Emotional Metadata Model — the dispositions/resonance vector
