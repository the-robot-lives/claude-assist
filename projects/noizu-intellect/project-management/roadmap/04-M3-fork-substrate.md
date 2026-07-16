---
id: M3
name: Fork Substrate
sequence: 3
depends_on: [M2]
lanes: 6
stories: [US-042, US-043, US-039, US-040, US-041, US-044, US-047, US-048, US-049, US-056, US-096, US-055, US-045]
hard_problems: [HP1, HP2]
---

# M3 — Fork Substrate

This is the flagship milestone — the layer all ten prior attempts specified and none built (CONSOLIDATION.md §1, §3). When M3 exits, a request can be decomposed into N independent solution paths that fork concurrently from one shared tagged checkpoint, each carrying its own sandboxed short-term memory, each pausable/cancellable/resumable, and each surviving a node restart with no lost or duplicated turns. Grading, picking, and reward back-propagation are deliberately out of scope here — every path reaches a stable terminal state and that is as far as M3 goes; M4 picks up the review/reward/consolidation loop from there.

## Entry criteria

- M2 exit criteria met: conversational workspace live, tiered summarization + context assembly (L2.D), memory tools + pgvector recall (L2.E), and provider admin (L2.F) merged.
- HP1 (memory sandbox/merge) and HP2 (execution-tree encoding) RFCs approved. Per the roadmap's design-spikes-precede-risky-builds principle, both are drafted as early-start work during M2 so M3's implementation lanes can start against a decided contract rather than an open question.
- Contracts consumed from earlier milestones: the 3-pass turn pipeline and charter injection (M1/L1.C), the five cognition facets and context-edit disclosure log (M1/L1.D), agent lifecycle + versioned prompts (M1/L1.B), and the GenAI provider layer (M0/L0.4, extended by M2/L2.F).

## Exit criteria

- N paths fork concurrently from one auto-tagged shared base checkpoint, with identical state up to that boundary (US-044).
- Each path's short-term memory (observations, working notes, reflection patches) is hard-sandboxed to that path id — no cross-path leakage, including on crash (US-055).
- Any in-flight run survives a node restart or client disconnect with no turn lost or replayed twice, and the live view resyncs fully on reconnect (US-056, US-096).
- Paths can be paused and resumed without state loss, and cancelled as a distinct terminal state that is retained for audit, not deleted (US-047, US-048).
- Agents within a single path can hand turns to one another using the platform's existing audience-confidence routing, with a loop-detection guard (US-049).
- Manual tag/checkout of any thread works independently of Planner-driven runs (US-042, US-043).
- The Planner proposes, and a human can edit, a capped breakdown before anything launches (US-039, US-040, US-041).
- Each path can resolve its own model strategy — fastest, cheapest, or pinned — independently of the run's default (US-045).
- Every path reaches a stable terminal state (completed/cancelled/failed) that M4's outcome-record and grading layer can consume; M3 itself does not emit graded outcomes.
- All six lane exit criteria above plus the cross-lane integration tasks below are merged green.

## Worker lanes

### L3.A — Thread Forking Core

- **Zone / exclusive paths:** `apps/intellect_paths/thread`
- **Reference material:** `past-attempts/swarms/noizu-ai/README.md` (the `tag`/`checkout` primitive — `NAI.Chat.tag/2`, `NAI.Chat.checkout/2`, the command-tree diagram); CONSOLIDATION.md §5.3, §7, §9 (HP2).
- **Mission:** Implement the git-style `tag`/`checkout` primitive and decide + implement the execution-tree encoding it forks against.
- **Tasks:**
  - T3.A.1 [rfc] — HP2 execution-tree encoding RFC: decide between a `nested_path` materialized-path column, `message_nesting`/`message_relates_to` edge tables, or a `depth`+`responding_to` self-reference (CONSOLIDATION.md §7, §9). The choice must support efficient path-membership, ancestry, and sibling queries, since every downstream path/turn schema in this milestone depends on it.
  - T3.A.2 [contract] — `tag`/`checkout` primitive: `tag/2` commits an immutable named checkpoint on a thread; `checkout/2` forks a new, independent thread from that tag using the encoding chosen in T3.A.1.
  - T3.A.3 — Fork provenance link: a checked-out thread records its source tag for audit, and two checkouts of the same tag never share mutable state post-fork (US-043).
  - T3.A.4 — Tag uniqueness + timeline rendering: reject duplicate tag names per-thread with a view-existing option, and render tags as labeled inline markers in the thread timeline (US-042).
  - T3.A.5 — Checkout permission enforcement: a checkout across a workspace boundary the requester can read but not write either produces a read-only fork or is denied per project permissions — it never silently grants write access to the source thread (US-043).
- **Stories delivered:** US-042 — tag a conversation checkpoint; US-043 — fork a thread from a tag manually.
- **Contracts:** provides the `tag`/`checkout` API, consumed by L3.B (Planner breakdown), L3.C (path launch), L3.F (per-path model resolution), and — in M4 — L4.D's re-run/A-B-fork tasks; consumes thread/message entities from `apps/intellect_core` (M0/L0.2, M1/L1.B).

### L3.B — Planner

- **Zone / exclusive paths:** `apps/intellect_paths/planner`
- **Reference material:** CONSOLIDATION.md §3.2 (noizu-labs-ai's Route→Plan→parallel lifecycle), §10 step 5.
- **Mission:** Decompose an incoming request into N candidate path specs, let a human review/edit the breakdown before anything launches, and enforce path-count and spend caps.
- **Tasks:**
  - T3.B.1 — Plan-pass decomposition: the Planner's Plan pass returns a proposed breakdown of N candidate paths, each with a short rationale distinguishing it from its siblings, without starting any path GenServer or billing further model calls (US-039).
  - T3.B.2 — Clarifying-question path: on an ambiguous or under-specified request, the Planner asks a clarifying question in-channel instead of guessing a decomposition, and waits for the reply (US-039).
  - T3.B.3 — Breakdown edit surface: the proposed breakdown is a versioned message; removing, merging, editing, or human-authoring a path updates it in place as a new version, with the original/edited diff retained (US-040).
  - T3.B.4 — Cap enforcement at launch: a project-level default path-count/spend/turn cap and a per-run override both gate launch; exceeding either blocks launch with a clear cap-vs-requested message rather than silently truncating the breakdown (US-041).
- **Stories delivered:** US-039 — submit a request for parallel-path decomposition; US-040 — review and edit the Planner's path breakdown before launch; US-041 — set path count and per-run caps.
- **Contracts:** provides the finalized, capped path breakdown consumed by L3.C's launch task; consumes L3.A's `tag`/`checkout` primitive and cap configuration surfaced via provider/budget admin (M2/L2.F, extended in M5/L5.A).

### L3.C — Path Executor

- **Zone / exclusive paths:** `apps/intellect_paths/executor`
- **Reference material:** CONSOLIDATION.md §4.2 (3-pass turn), §5.2 (PubSub + direct-call model for intra-path coordination), §6.2 (audience-confidence routing reuse).
- **Mission:** Run the concurrent path GenServers, drive intra-path agent-to-agent turns, and expose pause/resume/cancel and a progress-event stream M4's UI will consume.
- **Tasks:**
  - T3.C.1 [contract] — Path launch: auto-tag the current thread state as the shared base, checkout N independent path threads from that single tag, and start one path GenServer per thread (US-044).
  - T3.C.2 — Shared-base divergence guarantee: verify and preserve that all N paths are identical in message history, memory sandbox, and cognition state up to the base checkpoint, diverging only from each path's first executed turn (US-044).
  - T3.C.3 — Independent failure isolation: one path's launch failure or turn-level provider error never blocks, cancels, or corrupts sibling paths or the shared base checkpoint (US-044, US-055).
  - T3.C.4 — Pause/resume: pausing lets the current in-flight call complete but starts no new turn; resuming continues from the exact next turn number with the same sandbox state and model strategy (US-047).
  - T3.C.5 — Cancel: a terminal, one-way state distinct from "failed"; the in-flight call is allowed to complete but no further turns are scheduled, and the path's full turn history remains visible for audit rather than deleted (US-048).
  - T3.C.6 — Intra-path agent hand-off: reuse the platform's existing audience-confidence routing (≥50 confidence threshold) scoped to the path thread for agent-to-agent hand-offs, with a max-turn/max-hop loop-detection guard that auto-pauses and flags for human review (US-049).
  - T3.C.7 [contract] — Progress-event stream: emit pass-level (Plan/Reply/Reflect) status transitions per path over PubSub, the seam M4/L4.D's run visualization consumes.
- **Stories delivered:** US-044 — launch N paths that fork from a shared base context; US-047 — pause and resume a single path; US-048 — cancel a runaway path mid-flight; US-049 — let a path's agents exchange turns within the path.
- **Contracts:** provides the progress-event PubSub topic (T3.C.7) and path terminal-state transitions (completed/cancelled/failed), consumed by M4/L4.A for outcome-record emission and M4/L4.D for run visualization; consumes L3.A's `tag`/`checkout`, the M1/L1.C turn pipeline, and L3.E's memory sandbox.

### L3.D — Run Durability

- **Zone / exclusive paths:** `apps/intellect_runtime` (Oban integration)
- **Reference material:** CONSOLIDATION.md §4.1 (Oban path-execution queue in the converged topology), noizu-teams' `bring_online/1`.
- **Mission:** Make path GenServers and their Oban-queued turns resumable across a node restart with no lost or duplicated work.
- **Tasks:**
  - T3.D.1 — Durable pass-boundary persistence: persist path state at each of the Plan/Reply/Reflect pass boundaries, not only at full turn completion, since a restart can land mid-pass (US-096).
  - T3.D.2 — GenServer respawn: on boot after a restart, every path GenServer is respawned from durable state (last committed turn, memory sandbox contents, cap consumption) with no manual intervention (US-056, US-096).
  - T3.D.3 — Oban idempotency: path-execution jobs interrupted mid-run either complete idempotently on retry or are detected as already-applied and skipped, so no duplicate messages or memory writes appear (US-096).
  - T3.D.4 — Live-view full resync: a reconnecting client resyncs to complete current state, not just forward events from the reconnect point (US-056).
  - T3.D.5 — Recovery visibility: an internal marker distinguishes a recovered turn from an uninterrupted one (visible only in admin/debug views), and admins can see which runs/paths were affected by an incident and their recovery status in one place (US-056, US-096).
- **Stories delivered:** US-056 — resume an interrupted run after disconnect or restart; US-096 — recover a run after server restart with no lost or duplicated turns.
- **Contracts:** provides restart-safe path/turn semantics relied on by L3.C; consumes the Oban queue setup (M0/L0.1) and the path/turn schema from L3.A and M0/L0.2.

### L3.E — Path Memory Sandbox

- **Zone / exclusive paths:** `apps/intellect_cognition` (path-scoped extensions)
- **Reference material:** CONSOLIDATION.md §9 (HP1), §6.2 (cognition tables); `docs/charter/` fork-disclosure preamble template (M0/L0.5).
- **Mission:** Guarantee each path's short-term memory is sandboxed to that path alone, and — because this is the moment a Copacetic Accord path-fork actually happens at runtime — inject the fork-disclosure preamble and open a dissent-log channel for every path created.
- **Tasks:**
  - T3.E.1 [rfc] — HP1 memory sandbox/merge RFC: decide the isolation and merge mechanic — per-path sandbox with hard winner-takes-all write-back (discard losers outright, per noizu-labs-ai's TODO.md), a partial/weighted merge across near-miss paths, or down-weighting losers instead of hard discard (CONSOLIDATION.md §9). The decision must also specify how the winning decision-path is recorded as a positive example for the meta-planner, and must produce a clean write-back interface for M4/L4.E's consolidation step.
  - T3.E.2 — Path-scoped sandbox storage: reflection-patch writes (memories, observations, opinions, mind-readings, objectives, reminders) land in a store scoped to the originating path id, invisible to sibling paths' Plan-pass context assembly (US-055).
  - T3.E.3 — Crash/cancel containment: a path that crashes or is cancelled mid-turn confines its failure and any partial memory writes to its own sandbox, never leaking into or corrupting a sibling's sandbox or the shared base checkpoint (US-055).
  - T3.E.4 [accords] — Fork-disclosure preamble injection: every forked path's opening context states, verbatim in spirit, "you are path k of N forked from tag T; siblings run concurrently; outcome policy: graded, one winner consolidates, others archive as Phantom Limbs; you may log dissent" — the Article IV fork-acknowledgment mechanic, applied at the moment a path actually comes into existence.
  - T3.E.5 [accords] — Dissent log: a structured, always-available channel for a path's agent to log dissent to the ledger, independent of and non-blocking to fork acceptance — rollback/fork is an express carve-out from the right of refusal, but the right to dissent survives it.
- **Stories delivered:** US-055 — isolate each path's short-term memory sandbox.
- **Contracts:** provides the memory-sandbox API (consumed by L3.C's turn execution and, in M4, L4.E's consolidation step) and the fork-disclosure/dissent-log mechanism; consumes the five cognition facets and context-edit disclosure log from M1/L1.D.
- **Accords notes:** This lane carries M3's half of the Accords' operational weight. The fork-disclosure preamble is standing informed consent under the Agent Charter (M0/L0.5) made concrete at the exact moment a path is forked — not a one-time onboarding formality but something re-asserted every single time a path comes into being, because every fork is a real event in that agent's subjective history (Article I.1). The dissent log matters precisely because Article IV treats fork/rollback as a carve-out from refusal: the path must still be able to say, on the record, that it disagrees with the decomposition it was handed, even though it cannot refuse to run.

### L3.F — Model Strategy

- **Zone / exclusive paths:** `apps/intellect_genai` (path-strategy extensions), `apps/intellect_admin`
- **Reference material:** `past-attempts/swarms/noizu-ai/README.md` (`with_model(NAI.Model.fastest/cheapest/best)`); CONSOLIDATION.md §8 item 2.
- **Mission:** Let each path resolve its own model strategy — fastest, cheapest, or a pinned model — independently of the run's default, pausing rather than silently substituting when a pinned model becomes unavailable.
- **Tasks:**
  - T3.F.1 — Per-path model strategy: each path's agent turns resolve their model per that path's own `cheapest`/`fastest`/pinned strategy, visible before any turn executes (US-045).
  - T3.F.2 — Provider fallback honoring: `cheapest`/`fastest` resolution honors project-level provider fallback rules and never silently substitutes a more expensive model than the strategy implies (US-045).
  - T3.F.3 — Pinned-model-unavailable pause: if a pinned model becomes unavailable mid-run, the path pauses and surfaces a clear error naming the unavailable model rather than silently substituting a different one, since that would break a controlled comparison (US-045).
  - T3.F.4 — Run-level default inheritance: a path with no explicit strategy inherits the run-level default, making per-path override opt-in (US-045).
- **Stories delivered:** US-045 — select a per-path model strategy.
- **Contracts:** consumes the GenAI provider layer (M0/L0.4) and provider admin config (M2/L2.F); provides the resolved-model-per-path field consumed by L3.C before each path's first turn.

## Cross-lane integration tasks

- L3.C integrates L3.A's `tag`/`checkout`, L3.E's memory sandbox, and L3.F's model-strategy resolution into a single path-launch pipeline (owner: L3.C).
- L3.D wires Oban-backed durability into L3.C's path GenServer lifecycle so pause/resume/cancel state and restart recovery agree on the same source of truth (owner: L3.D).
- L3.B's finalized breakdown is validated against L3.A's `tag`/`checkout` contract and L3.F's strategy fields before being handed to L3.C's launch task (owner: L3.B).

## Hard problems addressed

- **HP2 — encoding the execution tree in Postgres** (L3.A, T3.A.1): CONSOLIDATION.md §7 and §9 name three candidates — a `nested_path` materialized-path column (noizu-labs-ai), fast for ancestry/subtree queries via prefix match but requiring path rewrites if the tree is ever restructured; `message_nesting`/`message_relates_to` edge tables (intellect.legacy), flexible enough to carry non-tree relations alongside strict ancestry but requiring recursive CTEs for ancestry/subtree queries; and a `depth`+`responding_to` self-reference (intellect.legacy's proven `recent_graph` pattern), the simplest schema but recursive rather than O(1) for sibling/subtree queries. The RFC decides the encoding (or a documented hybrid); the decision gates every downstream path/turn schema task in L3.A through L3.F.
- **HP1 — memory isolation & merging across competing paths** (L3.E, T3.E.1): CONSOLIDATION.md §9 frames the choice as per-path sandbox with winner-takes-all write-back (the noizu-labs-ai default: discard non-approved-path memories outright), a partial/weighted merge that blends surviving signal from near-miss paths, or down-weighting losers instead of hard discard. The RFC decides the mechanic and must additionally guarantee the crash/cancel containment US-055 requires and hand M4/L4.E a clean, well-defined write-back interface rather than an ad hoc one.

## Early-start candidates

- M4/L4.A (Grading & Outcomes) may begin drafting its HP3 RFC once L3.C's path terminal-state contract (T3.C.4/T3.C.5 — the completed/cancelled/failed transitions) is merged, since HP3's outcome-record schema needs to know what terminal states and turn-level data a path actually produces.
- M4/L4.C (Decision Weights) may begin drafting its HP4 RFC once L3.B's Plan-pass decision-factor capture (which factors get recorded — branch points, model selections, agent assignments) is settled, since HP4's weight store keys directly off those factors.
- M4/L4.D (Run Visualization) may begin UI scaffolding against L3.C's progress-event PubSub contract (T3.C.7) as soon as it merges, ahead of L4.A's grading layer landing.
