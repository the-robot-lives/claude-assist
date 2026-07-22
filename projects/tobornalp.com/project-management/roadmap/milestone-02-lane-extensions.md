---
title: "Milestone 2 — Single-Lane Extensions"
milestone: 2
status: draft
generated: 2026-07-16
---

## Goal

43 stories, max parallel width. Every dependency is either within-lane (sequenced against
another M2 story in the same lane) or on the lane's own M1 story — plus the three explicit
cross-lane contracts below. Each epic's daily-use surface becomes functional.

## Entry Criteria

- M1 exit criteria met for every lane touched here: A, C, F, J read models published; J's
  agent assignee reference published; foundational entity + CRUD live in each lane's routes.
- PRD pass complete for all 43 M2 stories (Flag 4).
- WS-L notification service (M1 platform enablement) live for WS-E/WS-J consumption.

## Exit Criteria

- Every epic's daily-use surface is functional (not just the M1 vertical slice).
- Permission model (US-077) live — this gates M3 entry (deploy approval, prompt sharing,
  and other M3 stories consume agent/human permission checks).
- Shared changelog-generation service (US-044) published for WS-G's M3 US-061 to consume.

---

## WS-A — Personal Items & Habits

### US-012 — Recurring habits with configurable frequency
- Persona(s): Alex Russo
- Size: M
- Dependencies: US-011 (M1)
- Story: [../user-stories/US-012-recurring-habits.md](../user-stories/US-012-recurring-habits.md)

Tasks:
1. Schema/migration `200`: `habits` table (frequency config, completion log) as an item-behavior extension, not a separate entity type.
2. Backend: `domains/personal` — schedule-matching service (habit shows on today view only on scheduled days), check-off endpoint that appends to completion log.
3. Frontend: habit icon/color treatment in `components/personal/**`; habit overview screen under `app/app/[orgId]/personal/**`.
4. Tests: unit tests for weekday/custom schedule matching; Cypress check-off flow on today view.

### US-014 — Habit streak tracking with visual indicators
- Persona(s): Alex Russo
- Size: M
- Dependencies: US-012 (sequenced within lane)
- Story: [../user-stories/US-014-habit-streaks.md](../user-stories/US-014-habit-streaks.md)

Tasks:
1. Schema/migration `201`: extend `habits` with streak fields (current, longest, grace_period_days) — computed from `200`'s completion log.
2. Backend: streak calculation service, streak-break notification trigger (via WS-L notification service).
3. Frontend: heatmap component + flame-icon streak badge in `components/personal/**`.
4. Tests: unit tests for grace-period edge cases; Cypress test asserting badge updates after check-off.

### US-015 — Smart lists with auto-filtering rules
- Persona(s): Maya Chen
- Size: M
- Dependencies: US-011 (M1)
- Story: [../user-stories/US-015-smart-lists.md](../user-stories/US-015-smart-lists.md)

Tasks:
1. Schema/migration `202`: `smart_lists` table (nested AND/OR rule tree as JSON, name, owner).
2. Backend: real-time filter-evaluation service (no manual refresh) against the items table.
3. Frontend: rule builder + "save current filter as smart list" shortcut in `components/personal/**`, sidebar nav entry.
4. Tests: unit tests for nested AND/OR rule evaluation; Cypress test for save-from-filter flow.

### US-016 — Personal lists alongside work without mixing contexts
- Persona(s): Raj Patel, Alex Russo
- Size: M
- Dependencies: US-011 (M1)
- Story: [../user-stories/US-016-life-alongside-work.md](../user-stories/US-016-life-alongside-work.md)

Tasks:
1. Schema/migration `203`: `context` enum column on `items` (personal/work) with hard visibility enforcement at the data-access layer, not just a filter.
2. Backend: access-layer guard ensuring personal-context items never leak into team/project queries regardless of filter state.
3. Frontend: context toggle (personal/work/all) in today view + sidebar; simple-checklist mode variant in `components/personal/**`.
4. Tests: unit tests proving personal items are excluded even when project-scope queries request "all"; Cypress toggle test.

### US-017 — Time blocking for focused work
- Persona(s): Alex Russo
- Size: L
- Dependencies: US-011 (M1)
- Story: [../user-stories/US-017-time-blocking.md](../user-stories/US-017-time-blocking.md)

Tasks:
1. Schema/migration `204`: `time_blocks` table (scheduling layer linking to an item, does not mutate the item itself).
2. Backend: read-only external calendar sync adapter (Google/Outlook), AI suggest-schedule service using priority/duration/energy-pattern preferences.
3. Frontend: daily timeline drag-and-drop view in `app/app/[orgId]/personal/**`, conflict-highlight styling in `components/personal/**`.
4. Tests: unit tests for conflict detection; Cypress drag-to-timeline test.

### US-020 — Archive completed items with searchable history
- Persona(s): Raj Patel
- Size: S
- Dependencies: US-011 (M1)
- Story: [../user-stories/US-020-archive-completed.md](../user-stories/US-020-archive-completed.md)

Tasks:
1. Schema: none — archiving is a status transition on the existing `items` table, not a new entity; add archive-delay to the existing user-preferences store.
2. Backend: delayed-archive scheduler job, full-text search over archived items, bulk archive/restore endpoints.
3. Frontend: archive view (date/tag/project/type filters) in `app/app/[orgId]/personal/**`.
4. Tests: unit tests for delay-config variants (immediate/1d/7d/30d/never); Cypress bulk archive + restore flow.

---

## WS-B — Inbox & Capture

### US-007 — Mobile capture for on-the-go ideas
- Persona(s): Raj Patel, Alex Russo
- Size: M
- Dependencies: US-006 (M1)
- Story: [../user-stories/US-007-mobile-capture.md](../user-stories/US-007-mobile-capture.md)

Tasks:
1. Schema: none — reuses US-006's `inbox_items`; client-side offline queue only.
2. Backend: `domains/inbox` — share-sheet intake endpoint, offline-sync reconciliation on reconnect.
3. Frontend: installable PWA capture screen, share-sheet integration (iOS/Android) in `components/capture/**`.
4. Tests: unit tests for offline-queue sync ordering; Cypress test for photo-attach + sync-within-5s assertion (mocked network).

### US-008 — AI triage agent for inbox items
- Persona(s): Sarah Kim
- Size: L
- Dependencies: US-006 (M1)
- Story: [../user-stories/US-008-ai-inbox-triage.md](../user-stories/US-008-ai-inbox-triage.md)

Tasks:
1. Schema/migration `205`: `triage_suggestions` table (project/priority/tags/type suggestion, confidence score, accept/reject feedback log).
2. Backend: classifier service with tunable confidence threshold, feedback loop that improves future suggestions, "needs human triage" fallback path.
3. Frontend: dismissable suggestion overlay + batch triage rapid-fire queue in `components/capture/**`.
4. Tests: unit tests for confidence-threshold fallback; Cypress batch-triage accept/reject flow.
5. Contract touchpoint: none new — consumes WS-B's own inbox schema only.

### US-009 — Email forwarding to inbox
- Persona(s): Diana Kovacs
- Size: M
- Dependencies: US-006 (M1), US-008 (same milestone, for triage of email-sourced items)
- Story: [../user-stories/US-009-email-to-inbox.md](../user-stories/US-009-email-to-inbox.md)

Tasks:
1. Schema/migration `206`: `inbox_email_addresses` table (per-user alias) + digest-preference column.
2. Backend: inbound email parser (subject→title, body→description, attachments preserved), sender-domain project-association heuristic, rate-limit/spam filter.
3. Frontend: email-alias display + daily-digest toggle in inbox settings.
4. Tests: unit tests for metadata extraction ("by Friday" → due date) and spam-filter thresholds; Cypress digest-mode toggle test.

### US-010 — Voice-to-item capture
- Persona(s): Alex Russo
- Size: M
- Dependencies: US-006 (M1), US-007 (capture infrastructure)
- Story: [../user-stories/US-010-voice-capture.md](../user-stories/US-010-voice-capture.md)

Tasks:
1. Schema: none — reuses inbox item pipeline; transcription is a client-side/API pre-processing step.
2. Backend: STT integration (Web Speech API / cloud provider), structured voice-command parser for "add a task... due Friday tagged legal" phrasing.
3. Frontend: mic button + review-before-submit UI in `components/capture/**` and mobile PWA.
4. Tests: unit tests for structured-command parsing; Cypress test for record → review-edit → submit flow (mocked STT).

---

## WS-C — Projects & Delivery

### US-022 — Kanban board view with drag-and-drop
- Persona(s): Maya Chen, Sarah Kim
- Size: L
- Dependencies: US-021 (M1)
- Story: [../user-stories/US-022-kanban-board-view.md](../user-stories/US-022-kanban-board-view.md)

Tasks:
1. Schema/migration `210`: board column config + WIP-limit fields on `workflow_states`.
2. Backend: `domains/projects` — drag-and-drop transition endpoint with optimistic-update support, per-user-per-project filter persistence.
3. Frontend: `app/app/[orgId]/projects/**` board with keyboard-first nav; `components/pm/**` card component (agent-assigned visual indicator).
4. Tests: unit tests for WIP-limit violation detection; Cypress drag-and-drop + keyboard-move-to-column test.

### US-024 — Assign items to agents or humans from same interface
- Persona(s): Sarah Kim
- Size: M
- Dependencies: US-021 (M1); consumes WS-J agent assignee reference contract (published M1)
- Story: [../user-stories/US-024-assign-to-agents-or-humans.md](../user-stories/US-024-assign-to-agents-or-humans.md)

Tasks:
1. Schema/migration `211`: `assignee_type` (human/agent) + `assignee_id` on `items`; agent task-intake acknowledgment log.
2. Backend: unified assignee-picker API merging human team members with WS-J's agent reference data; agent decline-with-explanation path.
3. Frontend: unified assignee dropdown in `components/pm/**` with agent icon/badge and capability-hover tooltip.
4. Tests: unit tests for reassignment history preservation (human↔agent, either direction); Cypress assign-to-agent + real-time status test.
5. Contract touchpoint: consumes WS-J agent assignee reference (M1 contract) — do not query WS-J's tables directly, read through the published reference.

### US-025 — Multi-project portfolio dashboard
- Persona(s): James Oduya
- Size: L
- Dependencies: US-021 (M1)
- Story: [../user-stories/US-025-multi-project-portfolio.md](../user-stories/US-025-multi-project-portfolio.md)

Tasks:
1. Schema/migration `212`: `portfolio_health_signals` table (configurable weights: burndown trajectory, overdue count, blocked count, SLA compliance, agent risk flags).
2. Backend: health-score computation service with transparent factor breakdown.
3. Frontend: portfolio card/row grid with filter+sort in `app/app/[orgId]/projects/**`; breadcrumb drill-down.
4. Tests: unit tests for health-score weighting; Cypress filter/sort + drill-down-and-back test.

### US-026 — Per-project methodology independence
- Persona(s): James Oduya
- Size: M
- Dependencies: US-021 (M1), US-025 (portfolio aggregation must normalize across methodologies)
- Story: [../user-stories/US-026-per-project-methodology.md](../user-stories/US-026-per-project-methodology.md)

Tasks:
1. Schema: none — reuses US-021's per-project methodology config; verify isolation (no shared mutable state across projects).
2. Backend: status-taxonomy normalization layer so cross-project views render methodology-appropriate labels.
3. Frontend: methodology-specific UI affordance switch (Kanban vs. Gantt) on project switch.
4. Tests: unit tests confirming one project's workflow change has zero effect on another; Cypress cross-project view label test.

### US-030 — Create and apply project templates
- Persona(s): James Oduya
- Size: L
- Dependencies: US-021 (M1), US-026
- Story: [../user-stories/US-030-project-templates.md](../user-stories/US-030-project-templates.md)

Tasks:
1. Schema/migration `213`: `project_templates` table (methodology config, item templates with relative dates, role/agent config, tag taxonomy, version).
2. Backend: save-as-template service, apply-template setup wizard with parameterized value substitution, template diff-on-update view.
3. Frontend: template library UI in `app/app/[orgId]/projects/**`; setup-wizard form in `components/pm/**`.
4. Tests: unit tests for parameterized-item substitution; Cypress save-template → apply-to-new-project flow.
5. Contract touchpoint: template schema is consumed by WS-H's M3 US-067 unified template library.

---

## WS-D — Bugs & Quality

### US-033 — Bug report auto-enrichment
- Persona(s): Maya Chen
- Size: L
- Dependencies: WS-C/WS-A item base (M1, WS-D was idle in M1)
- Story: [../user-stories/US-033-bug-auto-enrichment.md](../user-stories/US-033-bug-auto-enrichment.md)

Tasks:
1. Schema/migration `215`: `bug_enrichment` table (env fields, log/trace snippets, related-item links) as an "Auto-Context" append to the bug item.
2. Backend: `domains/bugs` context — enrichment agent (log/trace search within bug timeframe, related-item matcher), 10s completion budget, non-blocking submit.
3. Frontend: `app/app/[orgId]/bugs/**` bug form with integrated-tool auto-populate; collapsible Auto-Context section in `components/bugs/**`.
4. Tests: unit tests for related-item matching heuristics; Cypress test asserting non-blocking submit + async Auto-Context population.
5. Contract touchpoint: MCP integrations (Sentry, DataDog, GitHub) coordinated via WS-L's MCP plane.

### US-036 — Bug SLA compliance tracking
- Persona(s): James Oduya
- Size: L
- Dependencies: US-033 (same lane, bug entity must exist)
- Story: [../user-stories/US-036-bug-sla-tracking.md](../user-stories/US-036-bug-sla-tracking.md)

Tasks:
1. Schema/migration `216`: `sla_policies` table (per project/client, severity→target time) + `sla_clock_events` audit log (pause/resume).
2. Backend: business-hours/timezone-aware SLA clock, escalation-chain notifier (via WS-L notification service), clock-pause on waiting/blocked-external status.
3. Frontend: SLA countdown badge (green→yellow→red) on bug cards; compliance dashboard in `components/bugs/**`.
4. Tests: unit tests for clock pause/resume and business-hours math; Cypress test for breach-escalation notification trigger.
5. Contract touchpoint: compliance dashboard export feeds WS-C's M4 US-032 client-facing reports.

---

## WS-E — CI/CD & Deploy

### US-042 — Auto-transition items on deploy success or failure
- Persona(s): Sarah Kim
- Size: M
- Dependencies: US-041 (M1)
- Story: [../user-stories/US-042-deploy-aware-transitions.md](../user-stories/US-042-deploy-aware-transitions.md)

Tasks:
1. Schema/migration `220`: `deploy_transition_rules` table (per-project, per-environment target status) + activity-log entry on each auto-transition.
2. Backend: `domains/cicd` — commit/branch/PR-to-item linker, transition-rule evaluator on deploy webhook, manual-override/pause path.
3. Frontend: transition-rule config UI in `app/app/[orgId]/pipelines/**`.
4. Tests: unit tests for rule evaluation per environment; Cypress test for auto-transition + manual-revert flow.

### US-044 — Auto-generate deploy changelogs from linked items
- Persona(s): Maya Chen
- Size: L
- Dependencies: US-041 (M1)
- Story: [../user-stories/US-044-deploy-changelog.md](../user-stories/US-044-deploy-changelog.md)

Tasks:
1. Schema/migration `221`: `deploy_changelogs` table (grouped by category, format config) stored as items, linked to the deploy item.
2. Backend: build as a standalone, lane-agnostic **shared changelog-generation service** in `domains/cicd` — commit-range diff + item-link aggregation + conventional-commit fallback parsing, agent enrichment pass for human-readable summaries. This service is the M2 deliverable that WS-G's M3 US-061 will consume for its docs-surface auto-changelog (Flag 2) — design the service interface generically (input: repo range + linked-item set; output: structured changelog) rather than CI/CD-specific, and publish it as a contract at milestone end.
3. Frontend: changelog draft/review UI in `app/app/[orgId]/pipelines/**`; export/copy action.
4. Tests: unit tests for commit-message dedup against linked items; Cypress draft-changelog-before-deploy review flow.
5. Contract touchpoint: publish shared changelog-generation service → consumed by WS-G US-061 (M3).

### US-045 — View environment status dashboard
- Persona(s): Lin Zhao
- Size: M
- Dependencies: US-041 (M1)
- Story: [../user-stories/US-045-environment-dashboard.md](../user-stories/US-045-environment-dashboard.md)

Tasks:
1. Schema/migration `222`: `environments` table + `environment_deployments` (current version/SHA per service, deployer, health).
2. Backend: version-drift computation between environments, agent-queryable structured endpoint ("what version is in production?").
3. Frontend: single-pane environment grid with drift highlighting in `app/app/[orgId]/pipelines/**`; project/service filter.
4. Tests: unit tests for drift computation; Cypress project-scoped filter test.

### US-046 — Pipeline failure notifications with full context
- Persona(s): Maya Chen
- Size: M
- Dependencies: US-041 (M1); consumes WS-L notification service
- Story: [../user-stories/US-046-pipeline-failure-context.md](../user-stories/US-046-pipeline-failure-context.md)

Tasks:
1. Schema/migration `223`: `pipeline_failure_annotations` (log excerpt, likely-cause suggestion, linked commit/PR).
2. Backend: log-excerpt extractor (intelligent truncation, not mid-stack-trace), monitor-agent cause-analysis pass, priority-boost flag for today-view surfacing.
3. Frontend: syntax-highlighted log excerpt panel in `components/cicd/**`; today-view priority-boost badge.
4. Tests: unit tests for truncation boundaries; Cypress test for notification delivery channel routing (in-app/email/push).
5. Contract touchpoint: delivery routed through WS-L's notification service (M1 platform enablement) — do not build a parallel delivery path.

---

## WS-F — Monitoring & Incidents

### US-049 — Auto-create incidents from monitoring alerts
- Persona(s): Maya Chen
- Size: L
- Dependencies: US-048 (M1)
- Story: [../user-stories/US-049-alert-to-incident.md](../user-stories/US-049-alert-to-incident.md)

Tasks:
1. Schema/migration `225`: `incidents` table (severity, affected service, trigger detail, dedup window) as an item type.
2. Backend: `domains/monitoring` — alert-to-incident creator with 5-minute dedup window (same service + check groups; different failure modes split), context enrichment (recent deploys, related items, historical incidents), resolution auto-annotation.
3. Frontend: incident card with priority-override styling in today view; `components/monitoring/**` incident detail.
4. Tests: unit tests for dedup-window grouping logic; Cypress test for alert→incident creation and today-view priority-override.

### US-050 — Track SLO compliance with burn rate alerts
- Persona(s): Lin Zhao
- Size: L
- Dependencies: US-048 (M1)
- Story: [../user-stories/US-050-slo-tracking.md](../user-stories/US-050-slo-tracking.md)

Tasks:
1. Schema/migration `226`: `slo_definitions` table (target, rolling window, error budget) per service.
2. Backend: burn-rate calculation + threshold alerting (auto-creates incidents via US-049), agent-queryable SLO status endpoint.
3. Frontend: SLO dashboard with burn-rate trend line in `app/app/[orgId]/monitoring/**`.
4. Tests: unit tests for burn-rate threshold math; Cypress dashboard render + export test.
5. Contract touchpoint: SLO status feeds WS-E's M3 US-047 deploy-approval decision.

### US-053 — Generate status pages from monitoring data
- Persona(s): Maya Chen
- Size: M
- Dependencies: US-048 (M1), US-049
- Story: [../user-stories/US-053-status-page-gen.md](../user-stories/US-053-status-page-gen.md)

Tasks:
1. Schema/migration `227`: `status_pages` table (public URL config, branding, grouped services).
2. Backend: public unauthenticated route generator, agent-drafted incident-summary service (editable pre-publish), 60s update SLA from state change.
3. Frontend: public status page under `app/status/**` (per lane ownership table) + internal authenticated variant; `components/monitoring/**` config UI.
4. Tests: unit tests for public/internal auth boundary; Cypress test for incident-appears-on-page-within-60s (mocked clock).

---

## WS-G — Docs & Knowledge

### US-057 — Link docs to code so changes flag docs for review
- Persona(s): Maya Chen
- Size: L
- Dependencies: US-056 (M1)
- Story: [../user-stories/US-057-living-docs-code-link.md](../user-stories/US-057-living-docs-code-link.md)

Tasks:
1. Schema/migration `230`: `doc_code_links` table (file/directory/symbol target, ignore-pattern config) + staleness flag on `wiki_pages`.
2. Backend: `domains/docs` — commit/PR-diff watcher that flags linked docs, agent-drafted-update suggestion service (accept/modify/dismiss).
3. Frontend: "potentially stale" review task surfaced in today view; coverage-gap dashboard in `app/app/[orgId]/wiki/**`.
4. Tests: unit tests for ignore-pattern false-positive suppression; Cypress accept/dismiss suggested-edit flow.

### US-058 — Create and track Architecture Decision Records
- Persona(s): Lin Zhao
- Size: M
- Dependencies: US-056 (M1)
- Story: [../user-stories/US-058-adr-tracking.md](../user-stories/US-058-adr-tracking.md)

Tasks:
1. Schema/migration `231`: ADR-specific fields on `wiki_pages` (status enum, supersession chain reference).
2. Backend: supersession cross-link updater (old ADR auto-status-updates to "superseded by"), agent surfacing of relevant ADRs during planning.
3. Frontend: ADR index view (filter by status/date/tag) in `app/app/[orgId]/wiki/**`.
4. Tests: unit tests for supersession chain integrity; Cypress ADR-create-from-template + supersede flow.

### US-060 — Docs agent detects stale documentation automatically
- Persona(s): Sarah Kim
- Size: L
- Dependencies: US-056 (M1), US-057 (staleness-flag mechanism)
- Story: [../user-stories/US-060-stale-doc-detection.md](../user-stories/US-060-stale-doc-detection.md)

Tasks:
1. Schema/migration `232`: `doc_staleness_scores` table (severity score, signal breakdown, "still accurate" acknowledgment timestamp).
2. Backend: periodic scan job (last-edit age, broken links, archived-reference drift), review-task auto-assignment to last editor/team-lead fallback.
3. Frontend: docs health dashboard (freshness, coverage gaps, trend) in `app/app/[orgId]/wiki/**`.
4. Tests: unit tests for severity scoring; Cypress "still accurate" acknowledgment reset test.

### US-063 — Create and manage document templates for common doc types
- Persona(s): James Oduya
- Size: M
- Dependencies: US-056 (M1)
- Story: [../user-stories/US-063-doc-templates.md](../user-stories/US-063-doc-templates.md)

Tasks:
1. Schema/migration `233`: `doc_templates` table (placeholder variables, workspace/org visibility scope, usage count, last-used).
2. Backend: template-clone/archive service, placeholder auto-populate on create-from-template.
3. Frontend: template library UI in `app/app/[orgId]/wiki/**`.
4. Tests: unit tests for placeholder substitution; Cypress create-from-template flow.
5. Contract touchpoint: template schema shares shape with WS-C's US-030 — both feed WS-H's M3 US-067 unified template library.

---

## WS-H — Checklists & Templates

### US-065 — Enforce checklist completion before status transitions
- Persona(s): Sarah Kim
- Size: M
- Dependencies: US-064 (M1)
- Story: [../user-stories/US-065-checklist-enforcement.md](../user-stories/US-065-checklist-enforcement.md)

Tasks:
1. Schema/migration `235`: `transition_guards` table (checklist-completion rule per workflow/item-type/project) + override audit trail.
2. Backend: `domains/checklists` — transition-guard evaluator hooked into every lane's status-change path (via shared contract, not direct table access), admin override with reason capture.
3. Frontend: blocked-transition message listing incomplete items in `components/checklists/**`.
4. Tests: unit tests for override audit logging; Cypress blocked-transition + override flow.
5. Contract touchpoint: guard evaluator must be called by WS-C/WS-D/WS-E status-transition endpoints — coordinate hook contract via WS-L interface ticket; agents must respect the same guard (no bypass without explicit human approval).

### US-066 — Agents auto-generate contextual checklists based on item type and history
- Persona(s): Lin Zhao
- Size: L
- Dependencies: US-064 (M1), US-065
- Story: [../user-stories/US-066-agent-generated-checklists.md](../user-stories/US-066-agent-generated-checklists.md)

Tasks:
1. Schema/migration `236`: `generated_checklist_suggestions` table (confidence score + rationale per item, audit log of generating agent and inputs).
2. Backend: pattern-analysis service (item type, labels, linked items, project history), learning loop from accept/modify/reject feedback.
3. Frontend: suggestion-review UI (never auto-attached) with confidence/rationale hover in `components/checklists/**`.
4. Tests: unit tests for suggestion audit-trail completeness; Cypress suggest→approve flow.

---

## WS-I — Goals & OKRs

### US-070 — Key Results auto-progress from linked item completion
- Persona(s): Maya Chen
- Size: M
- Dependencies: US-069 (M1)
- Story: [../user-stories/US-070-auto-progress-krs.md](../user-stories/US-070-auto-progress-krs.md)

Tasks:
1. Schema/migration `240`: `kr_progress_log` table (auto-update timestamp, triggering item, manual-override flag).
2. Backend: `domains/okrs` — countable and percentage-based auto-progress calculators triggered on item completion; stale-progress detector.
3. Frontend: KR progress bar with auto/manual indicator in `components/okr/**`; at-risk flag on dashboard.
4. Tests: unit tests for both progress-calculation modes; Cypress manual-override flow.

### US-072 — Visualize goal alignment across teams and individuals
- Persona(s): James Oduya
- Size: L
- Dependencies: US-069 (M1), US-070
- Story: [../user-stories/US-072-goal-alignment-viz.md](../user-stories/US-072-goal-alignment-viz.md)

Tasks:
1. Schema: none — reads existing OKR hierarchy (US-069) and item-KR links; read-heavy, no new persistence.
2. Backend: orphan-detection query (work not linked to any OKR), node status color-coding computation.
3. Frontend: interactive tree/radial + force-directed graph views in `app/app/[orgId]/goals/**`, performant to 200+ nodes.
4. Tests: unit tests for orphan detection; Cypress filter-by-team/project/period test.

---

## WS-J — Agent Platform & Governance

### US-077 — Configure agent roles, permissions, and access boundaries
- Persona(s): Lin Zhao
- Size: L
- Dependencies: US-076 (M1)
- Story: [../user-stories/US-077-agent-roles-permissions.md](../user-stories/US-077-agent-roles-permissions.md)

Tasks:
1. Schema/migration `245`: `agent_roles`, `agent_permissions` (read/write/execute/approve per resource type, scoped to workspace/project/item-type/item), audit log.
2. Backend: `domains/agents` — permission-check middleware on every agent action path, default roles (observer/contributor/operator/admin), blocked-attempt logging.
3. Frontend: role/permission config UI in `app/app/[orgId]/agents/**`.
4. Tests: unit tests for scope resolution and blocked-action logging; Cypress role-assignment + immediate-effect test.
5. Contract touchpoint: this permission model is the M3 entry gate — deploy approval (US-047) and prompt sharing (US-092) both check against it.

### US-079 — View and manage agent task assignment queue
- Persona(s): Sarah Kim
- Size: M
- Dependencies: US-076 (M1), US-077 (queue respects role boundaries)
- Story: [../user-stories/US-079-agent-task-queue.md](../user-stories/US-079-agent-task-queue.md)

Tasks:
1. Schema/migration `246`: `agent_task_queue` table (priority order, estimated-completion, status history).
2. Backend: priority-reorder API, contention/starvation detection, bulk pause/cancel/reprioritize.
3. Frontend: queue view embedded in `app/app/[orgId]/agents/**` / agent dashboard, drag-to-reorder in `components/agents/**`.
4. Tests: unit tests for starvation detection; Cypress drag-reorder + bulk-action test.

### US-081 — Pause and resume agents without losing context
- Persona(s): Maya Chen
- Size: M
- Dependencies: US-076 (M1)
- Story: [../user-stories/US-081-pause-resume-agents.md](../user-stories/US-081-pause-resume-agents.md)

Tasks:
1. Schema/migration `247`: `agent_paused_state` table (serialized conversation history, working memory, tool state).
2. Backend: atomic-operation-complete-then-pause semantics, sub-3s resume restore, zero compute/credit consumption while paused.
3. Frontend: pause action + distinct paused-state visual indicator in `components/agents/**`, keyboard shortcut.
4. Tests: unit tests for state serialization round-trip; Cypress pause→inspect-queue→resume timing test.

### US-082 — Configure per-agent notification preferences
- Persona(s): Sarah Kim
- Size: M
- Dependencies: US-076 (M1); consumes WS-L notification service
- Story: [../user-stories/US-082-agent-notification-prefs.md](../user-stories/US-082-agent-notification-prefs.md)

Tasks:
1. Schema/migration `248`: `agent_notification_prefs` table (per category: silent/in-app/push/escalate, threshold rules, team-level override).
2. Backend: threshold-rule evaluator (confidence/duration-based), immediate effect without agent restart.
3. Frontend: per-agent notification settings panel in `components/agents/**`, digest-mode toggle.
4. Tests: unit tests for threshold-rule evaluation; Cypress settings-change-takes-effect-immediately test.
5. Contract touchpoint: delivery routed through WS-L's notification service, same as WS-E US-046.

---

## WS-K — Prompts & Evaluation

### US-087 — Browse prompt history with timeline view
- Persona(s): Maya Chen
- Size: M
- Dependencies: US-086 (M1)
- Story: [../user-stories/US-087-browse-prompt-history.md](../user-stories/US-087-browse-prompt-history.md)

Tasks:
1. Schema: none — read view over US-086's `prompt_versions`; annotation join is forward-referenced for M4 eval-domain data.
2. Backend: `domains/prompts` — timeline query with date-range/author/change-type filters.
3. Frontend: reverse-chronological timeline with vim-style (j/k/Enter/Esc) nav in `app/app/[orgId]/prompts/**`, dark mode.
4. Tests: unit tests for filter combinations; Cypress keyboard-nav timeline test.

### US-088 — Tag and categorize archived prompts
- Persona(s): Sarah Kim
- Size: M
- Dependencies: US-086 (M1)
- Story: [../user-stories/US-088-tag-categorize-prompts.md](../user-stories/US-088-tag-categorize-prompts.md)

Tasks:
1. Schema/migration `250`: `prompt_tags` table (system-provided categories + custom labels, effectiveness tag).
2. Backend: boolean tag search (AND/OR/NOT), bulk-tagging endpoint, auto-populate from agent metadata.
3. Frontend: tag chips + global search-bar integration in `components/prompts/**`.
4. Tests: unit tests for boolean query parsing; Cypress bulk-tag-selection flow.

### US-090 — Restore a previous prompt version with one click
- Persona(s): Maya Chen
- Size: M
- Dependencies: US-086 (M1), US-087
- Story: [../user-stories/US-090-restore-prompt-version.md](../user-stories/US-090-restore-prompt-version.md)

Tasks:
1. Schema: none — restore creates a new `prompt_versions` row flagged as a restoration of version N (non-destructive, per US-086 versioning model).
2. Backend: restore endpoint with sub-5s active-prompt swap (no agent restart), 60s global undo window, eval-score-delta warning check.
3. Frontend: restore confirmation dialog (diff + eval-score warning) in `components/prompts/**`.
4. Tests: unit tests for restore-as-new-version semantics; Cypress restore + 60s-undo-window test.

### US-093 — Annotate prompts with effectiveness notes and failure modes
- Persona(s): Lin Zhao
- Size: M
- Dependencies: US-086 (M1), US-088
- Story: [../user-stories/US-093-prompt-effectiveness-annotations.md](../user-stories/US-093-prompt-effectiveness-annotations.md)

Tasks:
1. Schema/migration `251`: `prompt_annotations` table (effectiveness summary, failure modes, recommended/contraindicated contexts, attribution, timestamp).
2. Backend: failure-mode-to-eval-result/incident-report linker, auto-surface annotation summary on restore/clone selection.
3. Frontend: structured annotation form + comparison-view integration in `components/prompts/**`.
4. Tests: unit tests for multi-author annotation on same version; Cypress annotate + auto-surface-on-restore test.

### US-094 — Export prompt archives as structured files
- Persona(s): Diana Kovacs
- Size: M
- Dependencies: US-086 (M1)
- Story: [../user-stories/US-094-export-prompt-archives.md](../user-stories/US-094-export-prompt-archives.md)

Tasks:
1. Schema/migration `252`: `prompt_import_conflicts` audit log (skip/overwrite/merge resolution record).
2. Backend: YAML/JSON export (agent/version/library scope) with documented schema, credential-exclusion default, re-import with conflict resolution and missing-reference warnings.
3. Frontend: export scope picker + import conflict-resolution UI in `app/app/[orgId]/prompts/**`.
4. Tests: unit tests for credential-exclusion default and schema round-trip; Cypress export→import-into-new-workspace flow.

### US-096 — Rate agent outputs with thumbs up/down and feedback
- Persona(s): Maya Chen
- Size: S
- Dependencies: US-086 (M1); reads WS-J agent/task data via contract
- Story: [../user-stories/US-096-rate-agent-output.md](../user-stories/US-096-rate-agent-output.md)

Tasks:
1. Schema/migration `253`: `agent_output_ratings` table (agent, prompt version, task type, input/output ref, rating, optional text, timestamp).
2. Backend: `domains/evals` — always-visible inline rating capture (<2s interaction budget), aggregation per agent and per prompt version.
3. Frontend: thumbs up/down inline on every agent output surface + `Ctrl+Up`/`Ctrl+Down` shortcut in `components/prompts/**` (shared slot embedded into WS-J's agent output views).
4. Tests: unit tests for rating aggregation; Cypress inline-rate + keyboard-shortcut test.
5. Contract touchpoint: reads WS-J agent/task context (agent id, task ref) via the M1 agent reference contract — do not query WS-J's tables directly.

---

## WS-L — Platform Shell & Cross-Domain

### US-001 — Unified today dashboard
- Persona(s): Maya Chen, Raj Patel
- Size: L
- Dependencies: M1 read-model contracts from WS-A (US-011), WS-C (US-021), WS-F (US-048), WS-J (US-076)
- Story: [../user-stories/US-001-unified-today-dashboard.md](../user-stories/US-001-unified-today-dashboard.md)

Tasks:
1. Schema/migration `255`: `today_view_cache` materialized read-model table (aggregated, priority-sorted, source-tagged) — do not add foreign reads into other lanes' tables.
2. Backend: aggregation service consuming each lane's published today-view read model (per M1 contract), <2s load for 200 active items, empty-state logic for new users.
3. Frontend: single-page dashboard with source-indicator sections in `app/app/[orgId]/today/**`, `g t` keyboard shortcut, dark mode.
4. Tests: unit tests for priority-sort merge across sources; Cypress load-time-budget and empty-state tests.
5. Contract touchpoint: consumes the today-view read-model contract published at M1 milestone start by WS-A, WS-C, WS-F, WS-J — any lane changing its read-model shape must update the contract via WS-L interface ticket, not a direct schema change on this table.

---

## Cross-lane contracts agreed at milestone start

| Producer lane | Consumer lane | Contract | Purpose |
|---|---|---|---|
| WS-A, WS-C, WS-F, WS-J | WS-L | M1 today-view read models | WS-L US-001 unified dashboard aggregation |
| WS-J | WS-C | Agent assignee reference | WS-C US-024 unified human/agent assignee picker |
| WS-J | WS-K | Agent/task context reference | WS-K US-096 rate-agent-output needs agent+task identity |
| WS-L | WS-E | Notification service | WS-E US-046 pipeline-failure notification delivery |
| WS-L | WS-J | Notification service | WS-J US-082 per-agent notification preference delivery |
| WS-E | WS-G (M3) | Shared changelog-generation service (US-044, generic interface) | WS-G US-061 (M3) consumes it for docs-surface auto-changelog — see Flag 2 |
| WS-H | WS-C, WS-D, WS-E | Transition-guard evaluator hook | WS-H US-065 enforcement must be called from every lane's status-transition endpoint |
