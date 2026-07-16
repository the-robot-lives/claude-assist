---
id: M6
name: "Reach: Search, API & Accessibility"
sequence: 6
depends_on: [M5]
lanes: 5
stories: [US-036, US-084, US-085, US-086, US-087, US-088, US-090, US-091, US-092, US-093, US-094, US-098, US-099, US-097, US-074]
---

# M6 — Reach: Search, API & Accessibility

Everything the platform can *do* now needs to be findable, scriptable, accessible, and usable on a bad connection. M6 closes the roadmap: unified and semantic search across channels, messages, agents, and runs; a public REST API with webhooks, byte-for-byte reproducible pinned experiments, anonymized bulk export, and one external chat-platform bridge; a fully keyboard- and screen-reader-navigable path into the execution tree and outcome-picking flow; and a low-bandwidth mode that keeps the product usable on a metered or unreliable connection.

Several of this milestone's stories are marked must-have in their own acceptance criteria, yet they only land here, at the very end of the sequence — that is not a priority contradiction. MoSCoW ordering applies *within* a lane, not across milestones (spec principle 7). US-084/US-086's search and filtering need the full channel/message/run/decision-history substrate (M1–M5) to search over before "search" means anything. US-090/US-092's public API needs a stable run/path/pick data model (M3/M4) to expose — building it earlier would mean exposing a data model still in flux, or building it twice. US-098/US-099's accessibility work needs a real execution tree and pick flow (M3/M4) to make navigable; retrofitting accessibility onto a UI that doesn't exist yet isn't possible, and building it against the M4 UI (owned by L4.D) before that UI stabilizes would mean redoing the work once it does.

## Entry criteria

- M0–M5 merged: in particular [06-M5-governance-ops-trust.md](06-M5-governance-ops-trust.md)'s L5.F provenance-lookup contract (message → prompt version → turn record → fork lineage), L5.A's budget-enforcement contract, L5.B's health/backpressure telemetry and queued/throttled run-status value, and L5.D's redaction/retention state.
- M0/L0.2's core schema and versioned-content primitives, and M1/L1.E's channel/message model, are stable — this is what L6.A searches over.
- M3's execution-tree encoding (HP2 resolution, [04-M3-fork-substrate.md](04-M3-fork-substrate.md)) and M4/L4.B's pick flow are merged — L6.C re-renders both as semantic lists rather than inventing a new tree representation.
- M4/L4.A–D's outcome/grade/pick data model is stable — L6.B's public API and L6.E's research export both read it directly rather than defining a parallel schema.
- M2's PubSub streaming events are the baseline L6.D coalesces and L6.C batches at a linguistic boundary — both extend that stream, neither replaces it.

## Exit criteria

- Global search returns ranked, access-scoped results across channels, messages, agents, and runs from one query box; semantic (vector-similarity) search over message history works alongside exact keyword search with a documented degraded-mode fallback; roster-wide "who knows about X" memory search and an agent/template directory are both browsable.
- Runs are filterable by status, project, date range, and outcome with shareable query state.
- A public API can submit and poll a run, subscribe to lifecycle webhooks, run a byte-for-byte reproducible pinned-model/pinned-prompt experiment, bulk-export run data with an anonymization option, and bridge one external chat platform (Slack) inbound and outbound.
- The execution tree and outcome-picking flow are fully usable by keyboard alone, structured as semantic lists rather than a pointer-driven graph; a screen-reader digest mode announces sentence/paragraph-level chunks per agent with configurable per-agent verbosity, validated against real NVDA output.
- Low-bandwidth mode coalesces streaming updates and reconciles cleanly on reconnect without duplicating or losing in-progress content.
- A full-run structured export (messages, plan, per-path turns/reflections, grades, decision-weight updates) is available as a schema-versioned, streamable document.

## Worker lanes

### L6.A — Search
- **Zone / exclusive paths:** `apps/intellect_recall/search` + `live/search/*`
- **Reference material:** CONSOLIDATION.md §7 (Weaviate `Message`/`Memory` classes, pgvector columns); M2/L2.E's semantic memory search (US-069) as the direct precedent this lane extends from agent memory to messages, agents, and runs.
- **Mission:** Let a user find anything — a past decision, a message, an agent with relevant experience, a run — without knowing in advance which entity type it lives in, using both exact and semantic search.
- **Tasks:**
  - T6.A.1 — Single-channel keyword search: Postgres full-text search scoped to one channel's durable inbox, sender filter, current-vs-original-version toggle for edited messages, sub-2-second latency at typical channel scale.
  - T6.A.2 [contract] — Global search aggregation contract: cross-entity (channel/message/agent/run) query fan-out with per-type relevance ranking, access-scoped results (no cross-project or cross-membership leakage), an explicit empty state per entity type.
  - T6.A.3 — Semantic message search: embedding-similarity ranking against the vector index with a visible similarity score; the index stays current across message re-versioning so a stale embedding of a superseded version never surfaces as a current match; a degraded-mode notice with keyword-search fallback when the vector store is unavailable or still catching up.
  - T6.A.4 — Roster memory search ("who knows about X"): cross-agent semantic search over cognition tables, both raw and distilled/synthetic memories, with project-visibility exclusion enforced at the query layer — not merely hidden client-side.
  - T6.A.5 — Run filtering: status/project/date-range/outcome filters combining with AND semantics, reflected in shareable URL/query state, reusing L5.B's queued/throttled status as a first-class filter value.
  - T6.A.6 — Agent & template directory: filterable browse by purpose/model/project; template preview and one-click instantiate; archived/deprecated agents visually distinguished and excluded from the default view.
- **Stories delivered:** US-036 — search a single channel's durable message history; US-084 — global quick-find search across channels, messages, agents, and runs; US-085 — semantic (vector) search over message history; US-086 — filter runs by status, project, date, and outcome; US-087 — find which agent knows about a topic via roster memory search; US-088 — browse the agent and template directory.
- **Contracts:** provides the global-search aggregation contract (T6.A.2); consumes M5/L5.F's provenance-lookup contract for message-result click-through into US-089's provenance panel; consumes M5/L5.B's run-status/backpressure state for the queued/throttled filter value; consumes and extends M2/L2.E's semantic-search substrate.
- **Accords notes:** none directly — search is a discovery feature, not a governance mechanism — though M5/L5.D's cross-project isolation is a hard dependency this lane must never bypass for query convenience.

### L6.B — Public API & Integrations
- **Zone / exclusive paths:** `apps/intellect_api`
- **Reference material:** CONSOLIDATION.md §5.2/§5.4 (PubSub streaming events this lane's webhooks reuse rather than duplicate); `organization_role_enum`/`channel_type_enum [:external, :internal, :direct, :group, :other]` carried from `past-attempts/swarms/virtual_teams/priv/repo/migrations/20250131044929_enums.exs` — the `:external` channel type US-094's bridge builds on.
- **Mission:** Expose the same run/path/pick data model the chat UI already uses via a scripted, API-first surface — submit/poll runs, subscribe to lifecycle webhooks, run byte-for-byte reproducible pinned experiments, bulk-export with anonymization, and bridge one external chat platform.
- **Tasks:**
  - T6.B.1 [contract] — Public run API: `POST` submit (prompt, project id, optional decomposition/tier constraints) returns a run id immediately and enqueues the Planner decomposition asynchronously; `GET` status returns overall/per-path state and per-path spend refreshed to the latest DB state; `GET` a completed run returns the winning path's full turn history, grade, and rationale; malformed/invalid requests return a structured 4xx identifying the bad field with no run enqueued. Exposes the same data model the chat UI uses — no shadow representation.
  - T6.B.2 — Webhook subscriptions: project-scoped registration for `path.completed`/`review.ready`/`pick.made` with an immediate test ping; signed delivery within a bounded delay of the underlying state change; exponential-backoff retry to a configured max, after which the subscription is marked degraded; reuses the same PubSub events the live UI streams from rather than a parallel event bus.
  - T6.B.3 [accords] — Pinned scripted experiments: explicit `{provider, model_id}` and prompt-version pins that bypass tier-based dynamic selection and the agent's currently-active version entirely; a 4xx rejection when a pinned version doesn't exist; a provenance record (provider, model id, response metadata, prompt-version content hash) sufficient to reproduce the run byte-for-byte, built directly on M5/L5.F's provenance-lookup contract.
  - T6.B.4 — Bulk export with anonymization: async job id + poll, NDJSON archive of runs/paths/turns/grades/picks matching T6.B.1's data model; stable pseudonymous human ids under the anonymize option while agent identities remain intact (they are the object of study); pinned-experiment provenance preserved under anonymization since it is not personally identifying; respects M5/L5.D's retention/redaction boundaries so an export can never resurrect already-purged data.
  - T6.B.5 — Chat-platform bridge (Slack, inbound-first): a Slack workspace channel mapped to an internal channel as an `:external`-type member; inbound messages ingested into the durable inbox with the Slack author preserved as a polymorphic human member and normal audience-confidence routing applied; agent replies relayed back attributed to the originating agent; connectivity loss marks the bridge degraded, fires an admin alert reusing M5/L5.B's health-alert path, and queues messages for redelivery where the transport allows.
- **Stories delivered:** US-090 — submit and poll a parallel-path run via the API; US-091 — subscribe to webhooks for run lifecycle events; US-092 — run a scripted experiment with pinned models and prompt versions; US-093 — bulk export run data with anonymization options; US-094 — bridge an external chat platform (Slack) to a channel.
- **Contracts:** provides the public run/path/pick API surface; consumes M5/L5.A's budget-enforcement contract so API-submitted runs respect the same caps as chat-originated ones; consumes M5/L5.F's provenance contract; consumes M5/L5.D's redaction/retention state for export boundaries; consumes M5/L5.B's health-alert path for bridge degradation; shares its run-record schema with L6.E's single-run export (see cross-lane integration tasks).
- **Accords notes:** pinned-experiment provenance (T6.B.3) is a research-reproducibility instance of Appendix B Axioms 2 and 3 (Honesty, Ledger Integrity) — an experiment's exact configuration is never silently substituted, even for convenience.

### L6.C — Accessibility
- **Zone / exclusive paths:** semantic markup and ARIA structure across `live/*` — annotates existing chat/runs/picks routes in place; owns markup and semantics only, never transport/payload (that is L6.D's territory, and the two lanes must not touch each other's files). For this one milestone, the lanes that normally own `live/chat/*`, `live/runs/*`, and `live/picks/*` (L2.A/L2.B, L4.B, L4.D) deliberately go quiet so L6.C can retrofit markup across those namespaces without an ownership conflict — a scoped, milestone-specific exception to the normal exclusive-ownership rule, not a precedent for other lanes to reuse.
- **Reference material:** CONSOLIDATION.md §9 HP2 (execution-tree encoding) as the data T6.C.3 re-renders as a semantic list; M4/L4.D's run-visualization UI as the sighted-user baseline this lane provides a parallel accessible path alongside, not a replacement for.
- **Mission:** Make the two hardest-to-reach flows — live multi-agent streaming and the execution-tree/outcome-picking UI — fully usable by screen-reader and keyboard-only users, without regressing the sighted-user experience those flows already have.
- **Tasks:**
  - T6.C.1 [contract] — Digest-mode ARIA batching contract: sentence/paragraph-boundary batching (not per-token) into a distinct, agent-labeled live region per agent; shares a buffering primitive with L6.D's coalescing infrastructure but batches on a linguistic key, not a time/size key.
  - T6.C.2 — Screen-reader digest mode: per-agent-per-user verbosity setting (summary vs. full); heading/landmark-based navigation between agent turns so a user never has to listen through an entire stream sequentially.
  - T6.C.3 — Execution tree as semantic list: nested list/heading markup reflecting fork lineage over M3's execution-tree encoding, fully keyboard-traversable, with an expand-in-place turn sub-list that keeps focus at a predictable, announced position.
  - T6.C.4 — Keyboard-accessible outcome-picking flow: grade, rubric breakdown, and rationale reachable as semantic list items with a Tab/Enter "select as winner" action (no drag-and-drop or hover-only control); an ARIA live-region confirmation on pick announcing the winning path and that reward back-propagation has been triggered.
  - T6.C.5 — Validation at scale: test digest mode and tree navigation against real NVDA output and an 8-to-12-path, multi-level-fork execution tree — not a trivial two-path example.
- **Stories delivered:** US-098 — screen-reader digest mode with configurable per-agent verbosity; US-099 — navigate the execution tree and outcome-picking flow by keyboard as semantic lists.
- **Contracts:** consumes L6.D's coalescing/transport-shaping mechanism, batching the linguistic layer on top of it; consumes M3's execution-tree data read-only; provides no contract other lanes consume — this lane is markup/semantics only, per the web-partitioning rule.
- **Accords notes:** none directly, though the pick-confirmation live region ("confirmed without visual inspection") is a small instance of the disclosure principle underlying the whole Accords framework — an outcome-affecting action is never left ambiguous to the person performing it.

### L6.D — Low-bandwidth & Transport
- **Zone / exclusive paths:** `apps/intellect_comms` (PubSub/channel transport coalescing) + a thin client-side transport hook shared across `live/*` — payload/reconnect mechanics only; never markup (that is L6.C's territory).
- **Reference material:** CONSOLIDATION.md §5.2/§5.4 (PubSub + direct-call streaming model, `:stream`/`:stream_end` events from `noizu-teams`) as the baseline this lane throttles and coalesces.
- **Mission:** Keep the platform usable on an unreliable or metered connection — coalesced, reduced-frequency streaming updates and clean reconnect reconciliation in place of full token-by-token payloads and lost-place drops.
- **Tasks:**
  - T6.D.1 [contract] — Coalescing contract: time/size-windowed batched update events with measurably reduced payload size versus per-token streaming, distinct in batching key from (but sharing a buffer with) L6.C's linguistic-boundary batching.
  - T6.D.2 — Low-bandwidth mode toggle: per-channel or global user setting that still surfaces accurate live/"generating" status without full token streaming.
  - T6.D.3 — Reconnect reconciliation: on reconnect, fetch the durable-inbox delta since the last acknowledged message rather than replaying full history; render an in-progress message correctly as partial-if-still-streaming or complete-if-finished with no duplication or reordering.
- **Stories delivered:** US-097 — low-bandwidth mode with coalesced streaming and reconnect reconciliation.
- **Contracts:** provides the coalescing/reconnect contract, consumed by L6.C's digest mode as a shared buffering primitive under a different batching key; consumes M2's PubSub streaming events as the baseline it throttles.

### L6.E — Research Export
- **Zone / exclusive paths:** `apps/intellect_recall`
- **Reference material:** CONSOLIDATION.md §7 (versioned-content, cognition tables) as the data this export serializes; M4/L4.C (decision-weight updates) and M5/L5.D (redaction state) as upstream contracts it must respect.
- **Mission:** Give a researcher a complete, schema-versioned, streamable export of a run's full record — messages, plan decomposition, per-path turns/reflections, grades, decision-weight updates — for offline analysis or an external evaluation pipeline.
- **Tasks:**
  - T6.E.1 — Full-run structured export: messages, plan decomposition, per-path turn history plus reflection patches, Reviewer grade records, and decision-weight updates triggered by the pick, in one schema-versioned document.
  - T6.E.2 — Streaming/pagination: paginated or streamed generation so a large multi-agent or long-history run doesn't time out a synchronous request.
  - T6.E.3 — Redaction-safe export: respects M5/L5.D's redaction/tombstone state so a purged memory can never leak back out through an export.
- **Stories delivered:** US-074 — export a run's full record as schema-versioned structured data.
- **Contracts:** consumes M5/L5.D's redaction/retention state and M4/L4.C's decision-weight history; shares its run-scoped data model with L6.B's bulk export (T6.B.4) — L6.E is the single-run superset, T6.B.4 is the cross-run/bulk view, and the two must not diverge into separate schemas (see cross-lane integration tasks).

## Cross-lane integration tasks

1. **(L6.B)** Reconcile L6.E's single-run export schema (T6.E.1) with L6.B's bulk export schema (T6.B.4) so both consumers of "a run's record as structured data" (US-074, US-093) share one schema-versioned representation instead of two that drift apart.
2. **(L6.A)** Wire M5/L5.F's provenance-lookup contract into global search results (T6.A.2) so a message result opens directly into its provenance panel, per US-089's note that it should be "reachable from US-084 global search results directly."
3. **(L6.C)** Confirm L6.D's coalescing primitive (T6.D.1) is reused, not reimplemented, for T6.C.1's linguistic-boundary batching — one buffering mechanism, two independent batching keys.
4. **(L6.D)** Confirm reconnect reconciliation (T6.D.3) benefits general reliability, not only the low-bandwidth persona, before considering the task complete.

## Hard problems addressed

None. M6 consumes the HP1–HP4 resolutions from [04-M3-fork-substrate.md](04-M3-fork-substrate.md) and [05-M4-review-reward-consolidation.md](05-M4-review-reward-consolidation.md) — the execution-tree encoding (HP2) that L6.C re-renders, and the outcome/grading contract (HP3) that L6.A/L6.B/L6.E read — but resolves none itself.

## Early-start candidates

None — M6 is the final milestone in this roadmap; there is no subsequent milestone to early-start into.
