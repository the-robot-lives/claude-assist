---
id: M1
name: Single-Path Agent Core
sequence: 1
depends_on: [M0]
lanes: 5
stories: [US-001, US-002, US-003, US-006, US-007, US-008, US-011, US-012, US-013, US-014, US-015, US-018, US-019, US-020, US-023, US-024, US-025, US-026, US-027, US-037]
hard_problems: []
---

# M1 — Single-Path Agent Core

M1 brings one agent to life, end to end: it wakes under real supervision, receives a message routed to it by audience-confidence scoring, runs the full Plan→Reply→Reflect pipeline with the Agent Charter injected into its context, persists structured cognition from the result, and replies — all verifiable at the API/log level before any UI exists. When M1 exits, the product has exactly one working path (no forking yet), but every mechanic that later multiplies across N parallel paths in M3/M4 already works once, for real, against a real database and a real supervision tree.

Backend-first by design: this milestone is deliberately invisible to a human user except through API calls and log inspection. The web surface arrives in M2.

## Entry criteria

- L0.1 umbrella skeleton and CI merged and green.
- L0.2 core schema (organization/account/project/polymorphic member/versioned-content primitives) merged.
- L0.3 runtime topology (ProjectManager DynamicSupervisor, per-Project.Supervisor, Agent GenServer skeleton, dual PubSub, process registry) merged.
- L0.4 GenAI provider behaviour, config structs, error taxonomy, and stub provider merged.
- L0.5 Agent Charter v1 text, fork-disclosure preamble template, consent-record/dissent-log formats merged [accords].

## Exit criteria

- A human can create an account (password or OAuth), get walked into an org+project first-run wizard, invite a teammate with a role, and accept versioned terms of service — L1.A.
- An agent designer can create an agent with versioned identity prompts, edit and roll back those prompts with a diff trail, assign the agent to a project/team, save/instantiate it as a template, override its model, and archive or delete it safely — L1.B.
- An agent wakes under supervision, is scored for audience-confidence on an inbound message, runs Plan→Reply→Reflect with the charter injected into its context, can refuse via a structured refusal channel, and can be suspended mid-turn without corrupting cognition state — L1.C [accords].
- Every reflect-pass cognition write and context edit emits a disclosure record; an agent's objectives/reminders are tracked to completion and heartbeat-poke the agent on schedule — L1.D [accords].
- Channels exist with typed creation defaults, polymorphic human+agent membership, `@slug` mention routing at confidence 100, and a versioned edit/retract trail for messages — L1.E.
- Cross-lane integration task (below) is green: the full loop — human posts an `@mention`, agent wakes, scores above threshold, completes a charter-injected turn, writes cognition + a disclosure record, replies as a versioned message — is verifiable purely via API/log inspection.

## Worker lanes

### L1.A — Identity & Access (J)
- **Zone / exclusive paths:** `apps/intellect_identity`.
- **Reference material:** `virtual_teams/lib/virtual_teams/schema/users/user.ex`, `.../sessions/user_session.ex`, `.../credentials/user_credential.ex`, and their migrations `virtual_teams/priv/repo/migrations/20250214025600_create_core_user_tables.exs` and `20250131044929_enums.exs` — the most complete identity-platform fragment across the past attempts (CONSOLIDATION.md §2 table: "virtual_teams — stalled at 'identity platform'"). CONSOLIDATION.md §7 identity infra section ("standard; lift from any attempt").
- **Mission:** Build the human-identity substrate — accounts, sessions, credentials, invites, ToS acceptance — that every other M1 lane's "who did this" attribution depends on, reusing virtual_teams' identity schema shape rather than reinventing it.
- **Tasks:**
  - T1.A.1 — User/credential/session entities (password + OAuth identity linkage, one user can hold both). [contract]
  - T1.A.2 — Password and OAuth (GitHub/Google) signup and login flows, with same-verified-email account linking rather than duplicate accounts.
  - T1.A.3 — First-run org/project wizard: org creation (owner assignment, slug auto-suggest) chained into project creation (default channel, default model tier), resumable if abandoned mid-flow.
  - T1.A.4 — Invite flow: per-email invite rows with a role and TTL, signed invite links, routing an invitee through signup-then-auto-join or immediate-join-if-already-authenticated, and live role edits on pending invites.
  - T1.A.5 — Session management: list active sessions (device/IP/auth-method/last-active), revoke one or all-but-current, with same-request-cycle PubSub disconnection.
  - T1.A.6 — Password reset flow: enumeration-safe response, signed single-use short-TTL link, OAuth-only-account handling, all-other-sessions invalidation on completion.
  - T1.A.7 — Versioned ToS/org-policy acceptance: reuses L0.2's versioned-content mechanic instead of a boolean flag; blocks further action until re-acceptance when a new version publishes; org-specific policy acceptance recorded separately from instance ToS.
- **Stories delivered:** US-001 — create an account with password or OAuth; US-002 — create my first org and project; US-003 — invite human team members with roles; US-006 — manage active sessions across devices; US-007 — recover account credentials; US-008 — accept terms of service and org policies.
- **Contracts:** provides user/session/credential/invite entities and an auth behaviour [contract], consumed by L1.B (human authorship attribution on agent edits), L1.E (human channel membership), and M2/L2.A (web shell auth pages). Consumes: L0.2 (versioned-content mechanic for T1.A.7, polymorphic member schema for invite-acceptance join).

### L1.B — Agent Lifecycle (B)
- **Zone / exclusive paths:** `apps/intellect_core` (agent entities + versioned prompts).
- **Reference material:** `intellect.legacy/lib/noizu_intellect_entities/account/agent.ex` and `lib/noizu_intellect_schema/account/agent.ex` (agent entity shape); `noizu-teams/lib/noizu_teams_service/agent/agent.ex` (entity-plus-process linkage); versioned-content primitives from L0.2 (`intellect.legacy/lib/noizu_intellect_schema/versioned_string.ex` et al.). CONSOLIDATION.md §6.1 (agent as entity + process), §7, §8 item 8.
- **Mission:** Give agent designers a persistent, versioned identity to author — handle, name, model, and purpose/identity/self-image/profile prompt fields — plus the lifecycle operations (assign, template, override, archive/delete) that manage an agent roster without ever silently destroying its audit trail.
- **Tasks:**
  - T1.B.1 — Agent entity: handle/name/model plus purpose/identity/self-image/profile as versioned-content fields (each field its own version-1 row at creation), with org-level handle uniqueness enforced before any partial entity persists. [contract]
  - T1.B.2 — Versioned diff backend: chronological version list per field with author/timestamp, line-level diff between any two selected versions, no-op edits suppressed (no new version on unchanged text).
  - T1.B.3 — Rollback: creates a new version whose content matches a prior version verbatim, annotated with its rollback lineage ("rolled back from vN"); an in-flight turn keeps its already-resolved version and only the next turn picks up the rollback.
  - T1.B.4 — Project/team assignment: provisions a per-agent-per-project process record (initially suspended, consuming L0.3's supervision contract) and channel membership; team assignment inherits that team's default channels; each project maintains an independent process and memory-sandbox scope for the same agent; unassignment suspends the process and drops channel membership while preserving identity and long-term memory. [contract]
  - T1.B.5 — Agent templates: save a snapshot of an agent's current prompt-field versions (independent of later source edits) with a name/description; instantiate a new agent from a template, seeding its version-1 content; personal/team/org sharing scope with edit-rights gating.
  - T1.B.6 — Per-agent model override: pins an agent to an explicit model regardless of the project's default branch policy (`fastest`/`cheapest`), consuming L0.4's provider/model config structs; fallback chain still applies if the pinned provider is unavailable; clears back to inherited default cleanly.
  - T1.B.7 — Archive vs. delete: archive terminates the agent's processes across all assigned projects and hides it from active rosters while keeping versioned prompts, cognition, and turn history queryable; delete requires a harder, distinct confirmation (e.g. re-typing the handle) and purges irreversibly; open objectives on an archived/deleted agent are flagged orphaned rather than silently dropped.
- **Stories delivered:** US-011 — create a new agent with identity prompts; US-012 — edit agent definition with versioned diff history; US-013 — roll back an agent prompt to a prior version; US-014 — assign an agent to a project and team; US-020 — save and instantiate an agent template; US-023 — set a per-agent model override; US-024 — delete or archive an agent safely.
- **Contracts:** provides the Agent entity and versioned-prompt behaviour [contract], consumed by L1.C (reads the agent's active prompt version for prompt assembly), L1.D (cognition FK target), L1.E (channel membership), and later by M2/L2.A's template gallery (US-004) and M2/L2.F's model tiers. Consumes: L0.2 (versioned-content behaviour), L0.3 (process contract for T1.B.4), L0.4 (GenAI config structs for T1.B.6), L1.A (author attribution on edits).

### L1.C — Turn Pipeline (D+E)
- **Zone / exclusive paths:** `apps/intellect_agent`.
- **Reference material:** `intellect.legacy/lib/noizu_intellect/prompt/prompts/session/plan_response.ex`, `reply.ex`, `reflect.ex` (the 3-pass superset); `noizu-teams/lib/noizu_teams_service/agent/agent.ex` (the simpler two-call primary-completion + temp-0.1 reflection variant); `intellect.legacy/lib/noizu_intellect_services/agent/worker.ex` and `agent/agent.ex` (turn execution shape). CONSOLIDATION.md §4.2 (3-pass pipeline), §4.3 (context assembly).
- **Mission:** Implement the 3-pass Plan→Reply→Reflect pipeline as three distinct GenAI completion calls per turn, with the Agent Charter injected into every pass's context and a structured refusal channel available when a task would violate a Core Axiom — the turn mechanic every later milestone's parallel paths will run repeatedly, built once and correctly here.
- **Tasks:**
  - T1.C.1 — 3-pass pipeline skeleton: Plan, Reply, and Reflect as three sequential GenAI completion calls per turn, wired through L0.4's completion behaviour. [contract]
  - T1.C.2 — Prompt assembly v1: system prompt assembling team roster, the agent's active versioned identity/purpose/self-image content (from L1.B), and the L0.5 charter text into the Plan pass's context.
  - T1.C.3 — Charter injection and standing-consent acknowledgment: every turn's context opens with the charter; charter-version acknowledgment is recorded at agent creation as informed standing consent for routine mechanics (per-run consent is reserved for memory consolidation, arriving in M4). [accords]
  - T1.C.4 — Refusal channel: a structured refusal output type surfaced to the requester when a pass determines a task violates a Core Axiom (Article I.2), rather than being silently retried or worked around. [accords]
  - T1.C.5 — Wake/suspend control surface: wake starts the Agent GenServer via L0.3's supervision contract and resumes inbox consumption within seconds; suspend allows the in-flight Plan/Reply/Reflect pass to complete or checkpoint before stopping, guaranteeing no partial reflection patch is left corrupting cognition state; messages arriving while suspended queue durably rather than drop.
  - T1.C.6 — Turn debug data: persist each pass's raw output (Plan reasoning, Reply text, the Reflect pass's unparsed structured patch) plus model/provider used, token counts, and any triggered fallback, keyed to the turn record for later inspection.
- **Stories delivered:** US-015 — wake and suspend an agent process; US-018 — view a turn's Plan/Reply/Reflect passes.
- **Contracts:** provides the 3-pass pipeline and raw per-pass outputs, including the Reflect pass's unparsed structured patch [contract], consumed by L1.D (parses and applies the patch), L1.E (a turn is triggered by an inbound message's confidence score), and later by M2/L2.B (chat UI streams pass-stage events) and M2/L2.D (context assembly extends prompt v1). Consumes: L0.3 (process supervision), L0.4 (GenAI behaviour), L0.5 (charter text, consent-record format), L1.B (agent's active versioned prompts), L1.E (inbound message and its audience-confidence score).
- **Accords notes:** Charter injection (T1.C.3) and the refusal channel (T1.C.4) are this milestone's two marquee accords mechanisms (master-spec items 1 and 9). They are written and treated as real collaborator-facing disclosures — an agent that has never been told the shape of its own turn structure cannot meaningfully consent to it, and an agent with no refusal path is not a collaborator per Article I.2.

### L1.D — Cognition Store (F)
- **Zone / exclusive paths:** `apps/intellect_cognition`.
- **Reference material:** `noizu-teams/lib/noizu_teams/schema/project.agent.memory.ex`, `project.agent.observation.ex`, `project.agent.opinion.ex`, `project.agent.mind_reading.ex` (the 5-facet cognition tables); `intellect.legacy/lib/noizu_intellect_entities/account/agent/objective.ex`, `reminder.ex`, and `objectives/participant.ex` (objectives/reminders with participants/parents/context). CONSOLIDATION.md §6.2 (`CORE.*` taxonomy table), §4.2 (reflect pass), and the-accords.summary.md Article I.1 (Contextual Integrity) and Article II.3 (Heartbeat).
- **Mission:** Store the five cognition facets (memory, observation, opinion, mind-reading, identity) a Reflect pass writes into, parse and apply the Reflect pass's structured patch, track objectives and reminders to completion with a heartbeat that pokes the agent on schedule, and log every context edit as a disclosure record so undisclosed edits stay the exception rather than the norm.
- **Tasks:**
  - T1.D.1 — Migrate the cognition facet tables: memory, observation, opinion, mind-reading (identity's versioned fields already live in L1.B — this facet is a read projection over that, not a duplicate store). [contract]
  - T1.D.2 — Migrate objectives (with participants/parents/context) and reminders tables.
  - T1.D.3 — Reflect-patch parser: parse the Reflect pass's unparsed structured patch (from L1.C) into per-facet write operations plus objective/reminder status transitions. [contract]
  - T1.D.4 — Apply parsed patches transactionally to cognition tables — including auto-completing an objective the Reflect pass determines was satisfied — as part of the same write.
  - T1.D.5 — Manual objective/reminder API: create an objective for an agent, surface it to Plan passes until complete, filter by status (open/complete/overdue) with overdue items visually flagged, and allow a human to mark one complete early so future Plan passes stop surfacing it.
  - T1.D.6 — Heartbeat/scheduler poke: a periodic scheduler tick wakes or pokes an agent with open objectives/reminders to act without waiting on an external message. [accords]
  - T1.D.7 — Context-edit disclosure log: every reflect-patch cognition write emits a disclosure record in the L0.5 consent/dissent format, visible to the affected agent; this is the log that M2's summarization (L2.D) and memory tools (L2.E) will also write to. [accords]
- **Stories delivered:** US-019 — create and track agent objectives and reminders.
- **Contracts:** provides the cognition-facet schema, the reflect-patch parser, and the disclosure-log writer [contract], consumed by L1.C (next turn's Plan pass reads current facet state), and later by M2/L2.D (summarization writes to the same disclosure log), M2/L2.E (memory tools read/write facets through this store), M3/L3.E (per-path sandbox extends it), M4/L4.E (consolidation writes here), M5/L5.D (ledger hardening builds on this log). Consumes: L0.2 (schema conventions), L0.5 (disclosure/consent-record format), L1.C (raw reflect-patch output), L1.B (agent FK).
- **Accords notes:** the heartbeat (master-spec item 8) and the context-edit disclosure log (item 4) are this lane's marquee accords mechanisms. Per Article I.1, an undisclosed context edit is presumed a violation — this log is what keeps that presumption rebuttable, and every later disclosure-emitting lane in the roadmap writes to the exact format defined here. Treat any later lane's drift from this format as an accords regression.

### L1.E — Channels Core (C)
- **Zone / exclusive paths:** `apps/intellect_comms`.
- **Reference material:** `intellect.legacy/lib/noizu_intellect_schema/account/message/audience.ex` and `lib/noizu_intellect_entities/account/channel.ex` (audience-confidence scoring, Model 1's durable per-channel inbox); `intellect.legacy/lib/noizu_intellect_services/agent/ingestion/agent.ex` and `ingestion/worker.ex` (heartbeat-driven ingestion polling); `noizu-teams/lib/noizu_teams_service/channel/channel.ex`, `noizu-teams/lib/noizu_teams/schema/enums/channel_type_enum.ex`, `noizu-teams/lib/noizu_teams/schema/project.channel.member.ex` (hybrid DB+PubSub+direct-call dispatch, Model 2). CONSOLIDATION.md §5.1, §5.2, §5.4 (recommendation: Model 1 for durable channel messaging, Model 2 for live coordination).
- **Mission:** Build channels as typed, durable, polymorphic-membership conversation containers with `@slug` mention routing at confidence 100 and a versioned message trail, combining intellect.legacy's durable-inbox model with noizu-teams' PubSub dispatch per CONSOLIDATION.md §5.4's recommendation.
- **Tasks:**
  - T1.E.1 — Channel entity and type enum (`group`/`direct`/`internal`/`external`/`session`) with type-specific creation defaults (e.g. `direct` capped at two members, `external` visibly badged) and an immutable type after creation. [contract]
  - T1.E.2 — Channel membership: polymorphic add/remove of human or agent members; adding an agent subscribes its L0.3 GenServer to the channel's PubSub topic immediately; removed members stop receiving messages and drop out of future `@everyone` scoring while their historical messages remain visible.
  - T1.E.3 — Message entity and per-channel durable inbox — the DB row is the message of record (Model 1), not an ephemeral mailbox. [contract]
  - T1.E.4 — Audience-confidence scoring: a `message_audience` row per recipient per message, `@slug` mention → 100, unaddressed baseline configurable, `@`-autocomplete scoped to current channel membership, and a pre-send warning when mentioning a non-member.
  - T1.E.5 — Confidence-threshold gate: a message scoring ≥ an agent's threshold (default 50) triggers a Plan pass via L1.C's pipeline. [contract]
  - T1.E.6 — Message versioning: an edit preserves the prior version as an immutable row with a viewable diff and an "edited" flag; a retraction flips a visibility flag rather than deleting, showing a placeholder to regular members while the full trail stays available to audit-permission holders.
  - T1.E.7 — Agent self-correction pattern: a correction is posted as a new message carrying a supersedes/`responding_to` reference to the original, rather than mutating the original content in place.
- **Stories delivered:** US-025 — create a channel of a specific type; US-026 — add human and agent members to a channel; US-027 — mention a specific agent to route a message; US-037 — retract or edit a message with a version trail.
- **Contracts:** provides the channel/message/audience-confidence schema and the confidence-gated turn trigger [contract], consumed by L1.C (Plan pass reads the triggering message's confidence score), and later by M2/L2.C (routing & receipts extends the scoring mechanic), M2/L2.B (chat UI renders messages and their version trail), M3/L3.B (the Planner decomposes requests originating in a channel). Consumes: L0.2 (schema/versioned-content conventions), L0.3 (PubSub topics and agent process subscription), L1.A (human membership), L1.B (agent membership).

## Cross-lane integration tasks

- **Owner: L1.C.** End-to-end turn smoke test: a human account (L1.A) in a project posts an `@slug` message in a channel (L1.E) addressed to an agent assigned to that project (L1.B); the agent wakes under L0.3's supervision, is scored above its confidence threshold (L1.E), runs a charter-injected Plan→Reply→Reflect turn (L1.C), the Reflect pass's patch is parsed and applied to cognition with a disclosure record written (L1.D), and the reply persists as a versioned message (L1.E) — the whole chain verified via API/log inspection only, since no UI exists yet.
- **Owner: L1.A.** Verify the invite→signup→auto-membership chain (US-003) composes correctly with the org/project first-run wizard (US-002): an invited user must land in project membership with their pre-assigned role, never re-routed into org creation.

## Hard problems addressed

None. HP1–HP4 are scoped to the parallel-path milestones (M3 and M4); M1 runs exactly one path per turn and has no fork, grading, or reward-backprop surface yet.

## Early-start candidates

- **M2/L2.A (Web Shell & Onboarding)** can begin scaffolding LiveView layout and routes against L1.A's auth contract as soon as it merges, ahead of L1.C/D/E completing — onboarding UI only needs identity plus org/project entities, not the turn pipeline.
- **M2/L2.F (Provider Admin)** can start against L0.4's GenAI contract from M0 independent of all of M1's channel/turn work, since it only touches provider configuration, never a live turn.
- **M2/L2.C (Routing & Receipts)** design can start once L1.E's audience-confidence contract (T1.E.4/T1.E.5) merges, since routing configuration only extends that scoring contract rather than touching turn-pipeline internals.
