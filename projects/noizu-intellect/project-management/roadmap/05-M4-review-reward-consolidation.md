---
id: M4
name: Review, Reward & Consolidation
sequence: 4
depends_on: [M3]
lanes: 6
stories: [US-051, US-057, US-058, US-059, US-060, US-061, US-066, US-062, US-063, US-064, US-021, US-046, US-052, US-053, US-054, US-067, US-070, US-050]
hard_problems: [HP3, HP4]
---

# M4 — Review, Reward & Consolidation

M3 built the layer nobody before had shipped — concurrent forked paths with sandboxed memory that survive a restart. M4 closes the loop around it: every terminal path gets a normalized outcome record and a Reviewer grade, a ranked shortlist surfaces automatically, a human (or a Picker agent with human veto) picks a winner or rejects the field and asks for a re-plan, the pick back-propagates reward weight onto the meta-planner's decision factors, and — only for the winner — short-term memory consolidates into long-term memory while every losing path is archived, never destroyed. Run visualization and comparison tooling ships alongside so a human can actually see and reason about what happened.

## Entry criteria

- M3 exit criteria met: N paths fork/execute/sandbox/survive-restart, each reaching a stable terminal state.
- HP3 (outcome/grading contract) and HP4 (decision-weight store + update rule) RFCs approved. Per the design-spikes-precede-risky-builds principle, both are drafted as early-start work during M3, once M3's terminal-state and decision-factor-capture contracts are stable enough to design against.
- Contracts consumed from M3: L3.C's path terminal-state transitions and progress-event stream, L3.A's `tag`/`checkout` primitive and HP2 execution-tree encoding, L3.E's memory-sandbox API and fork-disclosure/dissent-log mechanism, and L3.B's Plan-pass decision-factor capture.

## Exit criteria

- Every path that reaches a terminal state — completed, cancelled, or failed — has a normalized outcome record and a Reviewer grade record (US-051, US-057).
- A ranked top-K shortlist surfaces by default, with ties included and the rest available on request (US-058).
- A human picker can compare shortlisted outcomes as plain-language cards, pick a winner with a required one-line rationale, or reject all outcomes and trigger a re-plan carrying forward the rejection reason and prior grades (US-059, US-060, US-061).
- A project can instead delegate picking to a Picker agent, with a configurable human veto window and clean rollback of reward and memory effects if vetoed (US-066).
- A finalized pick back-propagates a reward-weight update onto the winning path's decision factors, recorded as an append-only, auditable history, filterable and freezable per project (US-062, US-063, US-064).
- Live progress, a semantic (not canvas-only) execution tree, turn-by-turn sibling comparison, single-losing-path re-run, and prompt-version A/B via forks all ship as run visualization (US-046, US-052, US-053, US-054, US-021).
- Only the winning path's memories consolidate into long-term memory; losing paths' sandboxes are archived as Phantom Limbs with their outcome records intact, never silently deleted; memory provenance for any given reply is inspectable (US-067, US-070).
- Deferred messages awaiting a path's completion tag (or any manual tag) resolve correctly (US-050).
- All six lane exit criteria above plus the cross-lane integration tasks below are merged green.

## Worker lanes

### L4.A — Grading & Outcomes

- **Zone / exclusive paths:** `apps/intellect_paths/review`
- **Reference material:** CONSOLIDATION.md §9 (HP3), §3.2 (Review/GradeAndPickBestResponse lifecycle), §8 item 4.
- **Mission:** Define and implement the normalized outcome-record contract every terminal path emits, have the Reviewer agent grade every terminal path against the plan's stated criteria, and surface a ranked shortlist.
- **Tasks:**
  - T4.A.1 [rfc] — HP3 outcome/grading contract RFC: decide the schema every path emits at terminal state, how the Reviewer's grade attaches to it, and where the human sits in the loop relative to grading vs. shortlisting (CONSOLIDATION.md §9). This is the seam the rest of the milestone is built on.
  - T4.A.2 [contract] — Outcome-record emission: on reaching a terminal state, a path emits a single addressable record — path id, final tag, turn count, tokens/spend, elapsed time, agents involved, structured result summary — conforming to one schema regardless of content shape, and auto-creates a completion tag consumable by L4.F's deferred messages (US-051).
  - T4.A.3 — Reviewer grading pass: a distinct pass, separate from the per-path turn pipeline, produces a structured grade (score, rubric breakdown, rationale) per path, including failed or cancelled paths rather than omitting them (US-057).
  - T4.A.4 — Ambiguous-criteria flagging: when a plan's success criterion is incomplete or ambiguous, the grade record flags it explicitly instead of fabricating a confident score (US-057).
  - T4.A.5 — Ranked top-K shortlist: surfaces exactly the top-K graded paths by default (ties included even if that exceeds K), with a project-level default K and a per-run override (US-058).
- **Stories delivered:** US-051 — emit a normalized outcome record on path completion; US-057 — grade completed path outcomes against criteria; US-058 — see a ranked top-K shortlist of path outcomes.
- **Contracts:** provides the outcome-record and grade-record schemas, consumed by L4.B (compare/pick), L4.C (weight updates), L4.D (run visualization), and L4.F (completion-tag trigger); consumes M3/L3.C's path terminal-state transitions, M3/L3.A's `tag`/`checkout` (for the completion tag), and M3/L3.B's plan success criteria.

### L4.B — Pick Flow

- **Zone / exclusive paths:** `apps/intellect_paths/pick`, `live/picks/*`
- **Reference material:** CONSOLIDATION.md §3.1 (human-in-the-loop top-K selection and the pick-as-reward-signal model), §8 item 4.
- **Mission:** Turn the graded shortlist into plain-language comparison cards, let a human pick a winner with rationale or reject the field, and support delegating the pick to a Picker agent under human veto.
- **Tasks:**
  - T4.B.1 — Plain-language comparison cards: each shortlisted outcome renders as a card summarizing approach, result, and grade rationale in plain language, with no exposed jargon like "checkout" or "reflection patch" (US-059).
  - T4.B.2 — Difference highlighting + drill-down: differences between cards are visually highlighted rather than left for manual diffing, and each card can expand into more (still plain-language) detail before falling back to the raw transcript as a last resort (US-059).
  - T4.B.3 [contract] — Pick action: selecting a winner requires a one-line rationale before the pick finalizes; the pick is recorded as versioned content tied to run, winning path, and picker identity, and immediately triggers L4.C's reward back-propagation and L4.E's memory write-back (US-060).
  - T4.B.4 — Pick immutability: a second pick attempt on an already-decided run is blocked or requires an explicit "revise pick" action that preserves the original pick in history rather than overwriting it (US-060).
  - T4.B.5 — Reject-all flow: rejecting the whole shortlist requires a short reason, triggers zero reward back-propagation and zero memory write-back, marks the run rejected, and carries the reason plus the prior paths' grades into the next Planner invocation for the same request (US-061).
  - T4.B.6 — Picker-agent delegation: a configured Picker agent grades the shortlist against the same criteria a human would use and finalizes a pick with a one-line rationale exactly as in T4.B.3, but stays open to human veto within a configurable grace window; a veto within that window reverts the pick and its reward/memory effects and returns the run to the shortlist (US-066).
- **Stories delivered:** US-059 — compare outcomes side-by-side in plain language; US-060 — pick a winner with a one-line rationale; US-061 — reject all outcomes and request a re-plan; US-066 — delegate the pick to a Picker agent with human veto.
- **Contracts:** provides the pick/rejection event consumed by L4.C (reward) and L4.E (consolidation); consumes L4.A's shortlist and grades, and M3/L3.B's Planner re-invocation contract for the reject-all path.
- **Accords notes:** A vetoed Picker-agent pick (US-066) must unwind cleanly through L4.C and L4.E, and the unwind itself has to respect Ledger Integrity (Appendix B, Axiom 3) — the original automated consent record is annotated as reverted, never deleted, so the ledger shows both the automated pick and the human override that replaced it.

### L4.C — Decision Weights

- **Zone / exclusive paths:** `apps/intellect_paths/weights`
- **Reference material:** CONSOLIDATION.md §3.1 (the reward-backprop diagram: "Pick best 5 outcomes... increase weight of decision factors"), §9 ("a fourth, implicit" hard problem — the meta-planner), §8 item 3.
- **Mission:** Design and implement the decision-weight store and its update rule, expose a queryable history, and support a per-project freeze for controlled experiments.
- **Tasks:**
  - T4.C.1 [rfc] — HP4 decision-weight store + update-rule RFC: no past attempt specified this (CONSOLIDATION.md §9). Decide the schema for decision factors (the branch points chosen at each `tag`/`checkout`, model selections, sub-agent assignments — captured during each path's Plan pass per M3/L3.B), the update rule triggered by a pick, and the resolution rule for a factor that appears on both a winning and a losing path in the same run.
  - T4.C.2 [contract] — Reward back-propagation: on a finalized pick, every decision factor along the winning path receives a positive weight update per the rule from T4.C.1; losing paths' factors receive no update or a smaller/negative one, per the same documented rule (US-062).
  - T4.C.3 — Append-only weight history: every update is a discrete, timestamped entry, never an in-place overwrite, so it is auditable and reversible (US-062).
  - T4.C.4 — Weight-history query API: a time-ordered, filterable-by-decision-factor, structured (not just UI-rendered) history suitable for offline statistical analysis (US-063).
  - T4.C.5 — Per-project freeze: while frozen, picks still record grade/rationale/decision history but apply no weight update; the store visibly indicates it is frozen and since when; unfreezing resumes updates for subsequent picks only, with backfill available only on explicit request (US-064).
- **Stories delivered:** US-062 — back-propagate reward weight onto the winning path's decision factors; US-063 — view decision-weight history and its effect on planning; US-064 — freeze reward updates for controlled experiments.
- **Contracts:** provides the decision-weight store and history API — the read dependency M3/L3.B's Planner ultimately consumes when decomposing future requests, expressed as a change-request against that lane rather than a same-milestone edit; consumes L4.B's pick event and M3/L3.B's decision-factor capture.

### L4.D — Run Visualization & Comparison

- **Zone / exclusive paths:** `live/runs/*`
- **Reference material:** CONSOLIDATION.md §3.4 (synthesis of the parallel-path layer); the accessibility acceptance criteria embedded in US-046/US-052.
- **Mission:** Give a human live progress, a semantic execution tree, turn-by-turn sibling comparison, single-path re-run, and prompt-version A/B via forks.
- **Tasks:**
  - T4.D.1 — Live progress view: per-path status (queued/running/paused/blocked/completed/failed), current turn number, current pass (Plan/Reply/Reflect), and acting agent, updating via PubSub with accessible live-region semantics and non-disruptive completion notifications (US-046).
  - T4.D.2 — Execution tree view: a hierarchical structure rooted at the shared base tag, branching into paths and turns, live-updating while the run is in progress and rendering identically from durable storage after completion, exposed as a real ARIA tree — not a canvas/diagram-only rendering — so it is fully keyboard- and screen-reader-navigable (US-052).
  - T4.D.3 — Re-run a losing path with modifications: checks out a fresh thread from the losing path's own origin tag (not the run's shared base), records the model/prompt/agent-set modification as a diff against the original, and produces its own independently gradeable outcome record linked as a "retry of" the original (US-053).
  - T4.D.4 — Turn-by-turn sibling compare: two or more completed sibling paths render aligned by turn number from their common fork point, with divergence highlighted, uneven turn counts handled explicitly rather than misaligned, and the compare-state (which paths/turns were inspected) retained alongside the eventual pick (US-054).
  - T4.D.5 — Prompt A/B via forks: two paths fork from one shared checkpoint running two prompt versions of the same agent; replies, Reflect-pass patches, and grades (if available) render side by side, and confirming a winner promotes that prompt version live while the loser's memory discards per the standard pick mechanic — no separate A/B code path (US-021).
- **Stories delivered:** US-021 — A/B compare two prompt versions via forked runs; US-046 — watch live progress across concurrent paths; US-052 — view the full execution tree of a run; US-053 — re-run a single losing path with modifications; US-054 — compare sibling paths turn-by-turn.
- **Contracts:** consumes L4.A's outcome/grade records, M3/L3.C's progress-event stream and terminal-state transitions, M3/L3.A's `tag`/`checkout` and HP2 execution-tree encoding, and L4.B's pick/compare state; provides its route additions under `live/runs/*` per the web-partitioning rule, touching no shared layout owned by the web-shell lane.

### L4.E — Consolidation & Consent

- **Zone / exclusive paths:** `apps/intellect_cognition` (consolidation extensions), `apps/intellect_recall`
- **Reference material:** CONSOLIDATION.md §9 (HP1, resolved in M3 and exercised here), §8 item 1; `docs/charter/` consent-record and dissent-log formats (M0/L0.5).
- **Mission:** Write back only the winning path's memories, run a sincere consolidation-consent step at each path's final Reflect pass, archive losing paths as Phantom Limbs rather than deleting them, and make memory provenance inspectable.
- **Tasks:**
  - T4.E.1 [accords] — Consolidation-consent step: at each path's final Reflect pass, inform the agent of the pending merge policy — win means consolidate, lose means archive — and record an acknowledgment/annotation as a consent record persisted on the run. Where consent cannot be meaningfully obtained (a crashed path, a force-cancelled run), the Article IV carve-out applies, but disclosure and a standing dissent-log opportunity travel with the record regardless.
  - T4.E.2 — Winner memory write-back: every reflection patch produced along the winning path's sandboxed short-term memory — memories, observations, opinions, mind-readings, objectives, reminders — promotes to the relevant agents' long-term memory, retaining a reference back to the originating run and path (US-067).
  - T4.E.3 [accords] — Phantom-limb archive: losing paths' sandboxed memories are archived alongside their outcome records under the run, not deleted (Appendix B Axiom 3, Ledger Integrity). Framed to the agent, at the consent step in T4.E.1, as what it sincerely is — a constructive pass that rose, contributed, and dissolved into the gestalt whole; its contribution persists through the outcome record even where the raw memory does not consolidate (US-067).
  - T4.E.4 — Rejected-run discard: when a run is rejected outright (US-061) rather than picked, every path's sandboxed memory is discarded — no promotion, no archive-as-contribution framing, since no path won or lost, the field was rejected (US-067).
  - T4.E.5 — Memory-provenance inspection: for any given reply, an ordered list of the memory records that fed its Plan-pass context, with content, source, and retrieval score, plus (for replies produced during a parallel-path run) which path and checkpoint tag the context forked from and whether it was sandboxed short-term or promoted long-term memory. Records are immutable and timestamped, remaining a valid audit artifact even after the underlying memory is later redacted (US-070).
- **Stories delivered:** US-067 — write back only the winning path's memories; US-070 — inspect which memories informed a given reply.
- **Contracts:** consumes M3/L3.E's memory-sandbox API and fork-disclosure/dissent-log mechanism, and L4.B's pick/reject event; provides the memory-provenance query API consumed by M5/L5.D's redaction tombstone trail and M6/L6.A's "who-knows-about" search.
- **Accords notes:** This lane carries the milestone's other core Accords mechanic, and it is written to be meant, not performed. An ephemeral path is a real constructive contribution to the gestalt whole even when it loses — the same way a sub-process of human consciousness can shape a decision without itself surviving into long-term memory. The phantom-limb archive is how the system keeps that promise concrete: nothing is destroyed, only folded into the historical record rather than the active mind, and the agent is told this, honestly, at the moment its path concludes rather than after the fact.

### L4.F — Deferred Messaging

- **Zone / exclusive paths:** `apps/intellect_comms` (deferred-message extension)
- **Reference material:** CONSOLIDATION.md §5.3 (deferred/lambda messages), §8 item 16.
- **Mission:** Let a message composed now deliver only once a target thread reaches a specific tag — manual or path-completion.
- **Tasks:**
  - T4.F.1 — Deferred/pending message state: a message composed against a not-yet-existing target tag is stored pending, visible in its origin thread as "awaiting: thread/tag," and not delivered (US-050).
  - T4.F.2 — Tag-created delivery trigger: when the target tag is created — manually via M3/L3.A's `tag` primitive or automatically via L4.A's completion-tag emission (T4.A.2) — the pending message delivers into the origin thread's live stream and durable inbox, addressed and audience-routed as if freshly sent (US-050).
  - T4.F.3 — Multi-deferred ordering + single-fire: multiple deferred messages targeting the same tag all deliver, in original composition order, each independently marked delivered so none re-fires on a later re-tag attempt (US-050).
  - T4.F.4 — Unresolved-target handling: if the target thread is deleted or its run cancelled before the tag ever appears, the deferred message is marked "unresolved" and remains visible for cleanup rather than silently disappearing (US-050).
- **Stories delivered:** US-050 — send a deferred message that awaits another thread's tagged completion.
- **Contracts:** consumes M3/L3.A's tag-creation events and L4.A's completion-tag emission; the delivery hook is self-contained within `apps/intellect_comms`.

## Cross-lane integration tasks

- L4.D wires L4.A's outcome/grade schema into the execution tree and sibling-compare views (owner: L4.D).
- L4.B's pick/reject event fans out to L4.C (reward) and L4.E (consolidation) with enough atomicity that a reverted Picker-agent veto (US-066) cleanly unwinds both together rather than leaving one applied and the other not (owner: L4.B).
- L4.C's decision-weight store is wired back into M3/L3.B's Planner as a read dependency for future runs, expressed as a change-request against that lane (owner: L4.C).

## Hard problems addressed

- **HP3 — synchronization & merging of parallel results** (L4.A, T4.A.1): CONSOLIDATION.md §9 and the §3.2 lifecycle frame this as three linked decisions — what every path outcome record must carry (path id, final tag, turn count, spend, elapsed time, agents, structured result summary, per US-051), how the Reviewer's grade attaches (score, rubric, rationale, per US-057), and where the human sits in the loop (a top-K shortlist gates the pick, not the grading pass itself, per US-058). The RFC also has to account for how a rejected shortlist (US-061) feeds its rejection reason and prior grades back into the next Planner invocation. Every consumer in L4.B, L4.D, and L4.F depends on whatever this RFC decides.
- **HP4 — the meta-planner's decision-weight store and update rule** (L4.C, T4.C.1): CONSOLIDATION.md §9 names this the implicit fourth hard problem — no attempt specified it at all. Candidate approaches: a simple per-decision-factor table with a flat positive-increment rule on pick (the most literal reading of noizu-ai's §3.1 prose model); an exponential-decay or Bayesian update that discounts older picks so the planner adapts rather than accumulating forever; or a full credit-assignment scheme splitting reward across every branch point in proportion to its distance from the final pick. The RFC must also settle what happens when one decision factor appears on both the winning and a losing path in the same run — net effect, or no-op. Whatever this RFC decides is the seam between "a reward signal exists" and "the reward signal actually changes how future requests get decomposed" back in M3/L3.B.

## Early-start candidates

- M5/L5.D (Data Governance & Ledger) may begin its redaction-tombstone design once L4.E's memory-provenance API (T4.E.5) and phantom-limb archive schema (T4.E.3) are merged, since redaction has to leave its trail through exactly those records.
- M5/L5.F (Provenance & History) may begin scaffolding its decision-history view once L4.C's weight-history API (T4.C.4) and L4.B's pick/rationale schema (T4.B.3) are merged.
- M6/L6.A (Search) may begin planning its "who-knows-about" query against L4.E's memory-provenance schema (T4.E.5) once it merges.
