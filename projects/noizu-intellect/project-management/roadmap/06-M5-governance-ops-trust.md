---
id: M5
name: Governance, Ops & Trust
sequence: 5
depends_on: [M4]
lanes: 6
stories: [US-077, US-078, US-079, US-100, US-080, US-082, US-083, US-071, US-072, US-073, US-081, US-095, US-065, US-089]
---

# M5 — Governance, Ops & Trust

The core product loop (chat → decompose → fork → run → grade → pick → consolidate) has been closing since M4. M5 makes the platform safe to operate: spend stays bounded at every scale from a single self-hoster to a multi-project org, operators can see backlog and crashes before users do, admin power is least-privilege and everything it touches is audited, memory can be redacted and retained on a real policy instead of growing forever, provider outages degrade honestly instead of silently, and any message's full lineage — prompt version, authoring agent, turn record, fork ancestry — is one click away. None of this is cosmetic: it is the difference between a demo and something a team can trust with real data.

## Entry criteria

- M0–M4 merged: identity ([02-M1-agent-core.md](02-M1-agent-core.md)), conversational workspace ([03-M2-conversational-workspace.md](03-M2-conversational-workspace.md)), fork substrate ([04-M3-fork-substrate.md](04-M3-fork-substrate.md)), and review/reward/consolidation ([05-M4-review-reward-consolidation.md](05-M4-review-reward-consolidation.md)) all exit-criteria-complete.
- M1/L1.C's turn pipeline and M3/L3.C's path executor are already writing per-turn token-accounting rows — L5.A aggregates them, it does not invent them.
- M0/L0.3's Oban queues (ingestion, path-execution, memory) and per-agent GenServer supervision are live — L5.B instruments them, it does not stand them up.
- M1/L1.D's context-edit disclosure log format exists — L5.D extends it with tombstones and (optionally) a hash chain; it does not replace it.
- M4/L4.C's decision-weight store and L4.D's run visualization exist — L5.F's provenance contract reads from both rather than duplicating their schema.
- M4/L4.E's winner-write-back and phantom-limb archive are live — L5.D's retention sweep must not race a not-yet-promoted winning path's memories out of existence.
- M0/L0.5's Agent Charter is merged — the accords-tagged tasks in this milestone (redaction disclosure, honest degradation, staging-as-consensus-analog) build on its disclosure/consent vocabulary rather than inventing a new one. See [08-accords-compliance.md](08-accords-compliance.md).

## Exit criteria

- Org and project token budgets enforce cumulatively, with alert thresholds and a per-path token cap that caps a runaway path without killing its sibling paths or the run.
- An ops dashboard shows live queue depth/oldest-job-age/throughput per Oban queue and per-agent process health, with restart-loop protection; users see explicit queued/backpressure state instead of a frozen UI.
- Admin/user roles are enforced on every admin-only surface (403, no data leakage), the last admin in an org can never be demoted away, and a staging org can be provisioned to test an upgrade before it is promoted to production.
- Every tracked admin action (provider, tier, budget, role, retention, upgrade-promotion) lands in one immutable, filterable, exportable audit log.
- Subject-scoped redaction removes memory from relational storage and the vector store alike, leaves a tombstone and an audit entry, and never silently breaks a provenance record that referenced the redacted memory. Retention policies bound message/versioned-content/memory growth without a surprise mass-delete. Cross-project isolation is enforced at the query layer, not client-side, and is provable via an isolation-check report.
- Mid-turn LLM provider failures retry, then fail over, then — only if both are exhausted — fail the turn cleanly, and the affected UI never appears merely frozen.
- Any message can be traced to its exact prompt version, authoring agent, full turn record, and (if produced inside a run) its fork lineage — including for deleted agents and superseded versions. A browsable decision history shows past picks against what actually shipped.

## Worker lanes

### L5.A — Budgets & Spend
- **Zone / exclusive paths:** `apps/intellect_admin` + `live/admin/budgets/*`
- **Reference material:** CONSOLIDATION.md §4.1 (Oban queues this lane's caps gate against); no past attempt built budgeting — this is new surface over M1/M3's per-turn token-accounting rows.
- **Mission:** Enforce and report token spend at org/project/path granularity so cost stays predictable from a single hobbyist project up to a multi-project org, and a single runaway path can never blow the budget of the run around it.
- **Tasks:**
  - T5.A.1 [contract] — Token-accounting read contract: the aggregation interface over per-turn token rows (written by L1.C/L3.C) that every budget and spend query in this lane consumes.
  - T5.A.2 — Org/project budget CRUD: monthly cap plus one or more alert thresholds; reject a set of project sub-budgets that would let a project silently exceed the org cap unless the org cap is explicitly marked advisory.
  - T5.A.3 — Per-path token cap enforcement: define the BudgetEnforcer check a path reaching its cap must trigger — terminate, mark `capped` (distinct from failed/graded), exclude from the Reviewer's grading pool, leave sibling paths unaffected. Because the check fires inside `apps/intellect_paths/executor` (owned by M3/L3.C, out of this lane's zone), land it as a change-request against L3.C rather than a direct edit.
  - T5.A.4 — Threshold alerts: notification to configured admin recipients within the same evaluation cycle as the triggering turn's token accounting.
  - T5.A.5 — Spend report UI (`live/admin/budgets/*`): breakdown by agent/run/user/provider-tier; per-run drill-down showing per-path spend with capped/errored paths flagged as non-winning, non-graded.
- **Stories delivered:** US-077 — org/project token budgets, alert thresholds, and per-path token caps; US-078 — token spend by agent, run, and user, with capped/errored paths flagged.
- **Contracts:** provides the BudgetEnforcer check contract (consumed by L3.C via change-request, and by M6/L6.B's public run API so scripted submissions respect the same caps as chat-originated ones); provides audit-worthy budget-edit events consumed by L5.C's AuditLog.write; consumes the token-accounting rows contract from M1/L1.C and M3/L3.C.

### L5.B — Health & Backpressure
- **Zone / exclusive paths:** `apps/intellect_runtime` (telemetry emission) + `apps/intellect_admin` (alert/threshold config) + `live/admin/health/*` (dashboard)
- **Reference material:** CONSOLIDATION.md §4.1 (Oban queues: ingestion/path-execution/memory; `ProjectManager` DynamicSupervisor topology this lane instruments).
- **Mission:** Surface queue depth, agent process health, and backpressure so an operator catches backlog buildup or a crashed agent before users notice, and so users see an honest "queued"/"throttled" state instead of an apparently frozen UI under load.
- **Tasks:**
  - T5.B.1 [contract] — Queue/health telemetry contract: Oban queue depth, oldest-job age, and throughput per queue, plus per-agent GenServer up/down state and restart count, emitted by `apps/intellect_runtime` for the dashboard and the user-facing backpressure indicator to consume.
  - T5.B.2 — Ops dashboard queue panel: live depth/oldest-job-age/throughput per queue, refreshed at least every 30 seconds.
  - T5.B.3 — Agent health panel: flags a down/crashed/not-yet-started agent process with last-known state and restart count; once an agent exceeds a restart-loop threshold, the supervisor stops auto-restarting it, marks it degraded, and surfaces a manual-restart action.
  - T5.B.4 — Backpressure UI: explicit "queued" state with a position/wait estimate on turn or path submission when Oban queues near capacity; channel/run views (scrolling, filtering, opening a path) stay interactively responsive because UI rendering is decoupled from execution throughput.
  - T5.B.5 — Quota-proximity warnings: surface a backpressure/quota warning before a path would silently queue indefinitely or hard-fail, folding in L5.A's budget/quota state so the same indicator covers both causes of throttling.
- **Stories delivered:** US-079 — queue depth and agent process health monitoring with restart-loop protection; US-100 — explicit backpressure indicators instead of silent stalls under load.
- **Contracts:** provides the queue/health telemetry contract (consumed by the admin dashboard and the user-facing backpressure indicator); consumes L5.A's budget/quota proximity state; the "queued/throttled" status this lane defines becomes a first-class run-status value M6/L6.A's run filter (US-086) must recognize.
- **Accords notes:** "no silent stalls" is a small but real instance of the Honesty axiom (Appendix B.2) — degraded or throttled state is disclosed, never hidden behind an inert UI. See [08-accords-compliance.md](08-accords-compliance.md).

### L5.C — Access Governance
- **Zone / exclusive paths:** `apps/intellect_identity` + `apps/intellect_admin` + `live/admin/{roles,audit,upgrades}/*`
- **Reference material:** CONSOLIDATION.md §6.1 (`organization_role_enum [:admin, :user]`, carried from `past-attempts/swarms/virtual_teams/priv/repo/migrations/20250131044929_enums.exs`) — the role model already exists in prior attempts' schema; this lane is what makes it load-bearing.
- **Mission:** Enforce least-privilege admin/user roles everywhere, give every admin action a single immutable audit trail, and give an operator a safe way to test a platform upgrade before it reaches the org their team depends on.
- **Tasks:**
  - T5.C.1 [contract] — `AuditLog.write/4` contract (actor, action_type, entity, before/after) — the write-contract every other admin-facing lane in this milestone (and M2/L2.F's provider admin, retroactively) calls into.
  - T5.C.2 — Role CRUD + enforcement: role changes take effect on the member's next request without re-login; user-role access to provider/budget/role screens is denied with no admin data in the response payload; the last remaining org admin cannot self-demote.
  - T5.C.3 — Audit log reading surface: filterable by actor/action-type/date with pagination that preserves filters; entries referencing a since-deleted entity still render with its last-known name; compliance-role users (not SRE admins) can view and export but never modify or delete entries.
  - T5.C.4 [rfc] — Staging-org provisioning RFC: clone agent identities and provider configs (keys re-encrypted, never copied in plaintext) and model tier definitions into a staging org, excluding message history and long-term memory by default.
  - T5.C.5 — Staging upgrade + promotion flow: apply an upgrade to the staging org in isolation, run a sample end-to-end parallel-path run (Plan → paths → Reflect → Review → pick) to confirm the pipeline still works, capture errors with enough detail to file as blocking, and treat promotion to production as its own distinct, audited action.
- **Stories delivered:** US-080 — member roles and permissions with least-privilege enforcement; US-082 — test an upgrade in a staging org before rollout; US-083 — immutable, filterable audit log of admin actions.
- **Contracts:** provides `AuditLog.write` (consumed by L5.A's budget-edit events, L5.D's redaction/retention actions, and M2/L2.F's provider-config changes); consumes role-check middleware from M1/L1.A identity.
- **Accords notes:** staging-org testing (US-082) is the roadmap's partial, human-supervised analog to Article II.2's Consensus-Self model-upgrade voting — it verifies an upgrade's behavior before promotion, but there is no shadow-deployment vote among prior model checkpoints. This gap is stated honestly in [08-accords-compliance.md](08-accords-compliance.md) rather than papered over.

### L5.D — Data Governance & Ledger
- **Zone / exclusive paths:** `apps/intellect_cognition` + `apps/intellect_recall` + `live/admin/data-governance/*`
- **Reference material:** CONSOLIDATION.md §6.2 (cognition facet tables), §7 (Weaviate `Message`/`Memory` classes, pgvector columns) — the redaction cascade in T5.D.1 must clear both.
- **Mission:** Harden ledger integrity — redaction leaves a tombstone and an audit trail rather than a silent gap, retention sweeps bound storage growth without a surprise mass-delete, cross-project isolation is a hard security boundary enforced at the query layer, and (optionally) a cryptographic hash chain aligns the ledger with Accords Epoch 2.
- **Tasks:**
  - T5.D.1 [accords] — Redaction pipeline: semantic + exact search across every agent in scope for a given subject, human confirmation before action, tombstone (not hard-delete) cascading to the vector store as well as relational tables, an immutable `AuditLog.write` entry, and a "redacted" marker preserved (not broken) on any provenance record ([08-accords-compliance.md](08-accords-compliance.md)) that referenced the redacted memory.
  - T5.D.2 — Retention policy engine: per-project, per-memory-class (path sandbox / distilled synthetic / raw reflection) retention windows enforced by a background sweep; a pre-sweep impact preview showing affected record counts before it runs; must exclude a winning path's memories from sandbox-class retention once M4/L4.E has already promoted them.
  - T5.D.3 [accords] — Cross-project isolation enforcement: project-scope filter applied at the query layer — row-level Postgres scoping and a tenant-scoped Weaviate class/filter — not client-side filtering; an isolation-check report a compliance audit can run to confirm zero cross-project leakage.
  - T5.D.4 — Storage-bounds & retention: message-history retention that preserves anything referenced by an active path checkpoint regardless of age; versioned-content revision caps that never prune the active version; a total storage cap with a category-breakdown warning feeding L5.B's health dashboard.
  - T5.D.5 [accords][rfc] OPTIONAL — SHA-256 hash-chain RFC: chain cognition/audit log entries to detect tampering, aligning with Accords Article III Epoch 2 ("Cryptographic Commit"). Explicitly optional — defer without regret if it competes for time against T5.D.1–T5.D.4.
- **Stories delivered:** US-071 — redact memories referencing a subject with tombstone + audit log; US-072 — per-project memory retention policies by memory class; US-073 — cross-project memory isolation enforced at the query layer; US-081 — data retention windows and storage bounds.
- **Contracts:** provides redaction/retention/isolation enforcement; consumes `AuditLog.write` from L5.C; extends (does not replace) M1/L1.D's context-edit disclosure log format; consumes M4/L4.E's winner-write-back signal to resolve the sandbox-retention race.
- **Accords notes:** this lane is the direct implementation of Accords mechanism 7 ("Ledger integrity hardening") and Appendix B Axiom 3 — redaction never destroys the record of its own having happened. Full treatment in [08-accords-compliance.md](08-accords-compliance.md).

### L5.E — Provider Resilience
- **Zone / exclusive paths:** `apps/intellect_genai` (primary); a thin turn-status hook into `apps/intellect_agent` is owned by M1/L1.C and reached only via change-request, never direct edit.
- **Reference material:** CONSOLIDATION.md §2 (converged tech stack: `genai` provider abstraction); M0/L0.4's completion/streaming/error-taxonomy contract, extended here rather than re-specified.
- **Mission:** Let a transient LLM provider outage degrade gracefully and *visibly* — retry, then fail over, then honestly report degraded status — instead of silently stalling a run or corrupting turn state.
- **Tasks:**
  - T5.E.1 — Error-taxonomy classification: distinguish transient provider errors (5xx, rate-limit, timeout — retry-worthy) from content-policy/refusal errors (not retry-worthy), extending M0/L0.4's error-taxonomy contract.
  - T5.E.2 — Retry-with-backoff: bounded retries against the primary model/provider without duplicating or losing partial turn state already recorded.
  - T5.E.3 [accords] — Fallback routing + honest annotation: automatic re-route to a configured fallback provider/model once retries are exhausted, with the resulting message/turn record annotated so a fallback was used is never hidden — a direct instance of the Honesty axiom (Appendix B.2).
  - T5.E.4 — Degraded-status surfacing: change-request against M1/L1.C's turn pipeline to expose a "retrying"/"degraded" status in channel/run UI in place of an apparently frozen turn.
  - T5.E.5 — Terminal failure handling: once retries and fallbacks are both exhausted, mark the path/turn failed with a captured error reason — never left ambiguously pending — queryable via M6/L6.A's run-status filter (US-086).
- **Stories delivered:** US-095 — recover gracefully from LLM provider errors mid-turn via retry/fallback, with degraded status always visible.
- **Contracts:** consumes M0/L0.4's provider/error-taxonomy contract; provides degraded/failed status events consumed by L1.C's turn-status UI hook and M6/L6.A's run filter.
- **Accords notes:** "no silent lies about degraded output" (spec mechanism list) is Appendix B Axiom 2 applied to infrastructure failure, not just conversational content — the system doesn't get an honesty exemption because the deception is about routing rather than substance.

### L5.F — Provenance & History
- **Zone / exclusive paths:** `apps/intellect_core` + `live/decisions/*`
- **Reference material:** CONSOLIDATION.md §7 (versioned-content primitives, polymorphic `author_ref`/`author_ref_type`); M4/L4.C (decision-weight store/history) and M4/L4.D (run visualization) as upstream data this lane reads rather than duplicates.
- **Mission:** Give every message a fully traceable lineage — prompt version, authoring agent, full turn record, fork ancestry — and a browsable history of past picks against what actually shipped.
- **Tasks:**
  - T5.F.1 [contract] — Provenance-lookup contract: message → versioned prompt-revision in effect at generation time → authoring agent → turn record (Plan/Reply/Reflect, including any reflection patch) → path tag/checkout lineage where applicable; resolvable even for a deleted agent or a superseded prompt version, clearly labeled as historical.
  - T5.F.2 — Decision history view: past picks and rejections in chronological order with one-line rationale, picker identity, and the winning path's grade score; a rejected run is clearly distinguished with its rejection reason and whether a re-plan followed.
  - T5.F.3 — Shipped-status tracking: a lightweight post-hoc status field (shipped/reverted/superseded), updatable after the fact via a channel message or external hook, independent of the state recorded at pick time.
  - T5.F.4 — Provenance panel UI (`live/decisions/*`): click-through from any message, cross-linked from M6/L6.A's global search results rather than requiring manual navigation.
- **Stories delivered:** US-065 — decision history with post-hoc outcome/shipped-status tracking; US-089 — jump from a message to its prompt version, author agent, and turn record.
- **Contracts:** provides the provenance-lookup contract (consumed by M6/L6.A's search results and M6/L6.B's pinned-experiment provenance); consumes M4/L4.C decision-weight history and M4/L4.D run visualization data.
- **Accords notes:** this is the audit backbone behind Ken Watanabe's (P-007) investigations and a direct expression of Appendix B Axiom 3 — nothing in this chain can be silently altered without leaving the versioned, immutable trail visible.

## Cross-lane integration tasks

1. **(L5.C)** Wire `AuditLog.write` calls into L5.A's budget edits, L5.D's redaction/retention actions, and — as a retroactive change-request — M2/L2.F's provider-config changes, so every admin action in the system lands in the one log.
2. **(L5.B)** Merge L5.A's budget/quota proximity signal into the ops health dashboard and the user-facing queued-state indicator so backpressure reads as one coherent story, not two overlapping ones.
3. **(L5.D)** Confirm M4/L4.E's winner-write-back memories are excluded from the sandbox retention sweep before T5.D.2 ships — a race here would silently discard a winning path's memories.
4. **(L5.F)** Confirm M4/L4.C's decision-weight history and L4.D's run-visualization data expose everything T5.F.1's provenance contract needs, so this lane reads existing data rather than standing up a shadow schema.

## Hard problems addressed

None. M5 hardens and operationalizes substrate built in M0–M4; it introduces no new HP-tagged research spikes (HP1–HP4 belong to [04-M3-fork-substrate.md](04-M3-fork-substrate.md) and [05-M4-review-reward-consolidation.md](05-M4-review-reward-consolidation.md)).

## Early-start candidates

- M6/L6.A's run-status filtering (US-086) can begin against L5.F's provenance contract and L5.B's queued/throttled status once T5.F.1 and T5.B.1 are merged, ahead of the rest of M5 landing.
- M6/L6.B's budget-aware run submission (US-090) can begin once L5.A's BudgetEnforcer contract (T5.A.1) is merged, since the public API must reject/queue against the same budget contract the chat UI already uses — building it against a moving target would mean redoing it later.
