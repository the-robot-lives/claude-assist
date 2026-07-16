---
title: "Milestone 3 — Cross-Lane Integration & First AI Wave"
milestone: M3
status: draft
generated: 2026-07-16
---

# M3 — Cross-Lane Integration & First AI Wave

33 stories, 11 active lanes (WS-B idle — capture pipeline has no M3 story; fold WS-B
workers into WS-D or WS-G for the milestone). Layers AI-assist onto every major epic and
lands the first wave of genuine cross-lane consumption. Unlike M1/M2, most stories here
read data another lane owns — every such read goes through a contract published at
milestone start, never a direct edit into another lane's paths (Roadmap Principle 3).

## Entry Criteria

- M2 exit criteria met: every epic's daily-use surface is functional; permission model
  (US-077 ✓M2) is live — M3 gates on it for approval/sharing flows.
- PRDs exist for all 33 M3 stories (Flag 4 — PRD pass runs pipelined against M2 implementation).
- Agent runtime contract (M0) stable enough to host AI-assist agents in every lane.
- WS-E's shared changelog-generation service (US-044 ✓M2) is merged — WS-G's US-061 depends
  on it directly (Flag 2).

## Exit Criteria

- AI-assist features live in every major epic (one per active lane, minimum).
- genai usage/cost instrumentation in place across all agent invocations this milestone —
  feeds US-085 (agent cost tracking, M4).
- WS-J's agent audit-emit contract (US-078) is consumed by every agent-invoking story
  landed this milestone.
- US-095 either lands in-lane or is explicitly slipped to M4 per the Flag 3 rule below —
  not left half-done.

---

## WS-A — Personal Items & Habits

### US-018 — AI-assisted morning planning routine
- Persona(s): Alex Russo
- Size: M
- Deps: US-011 ✓M1 (todo base); US-014/US-015/US-017 ✓M2 (streaks/smart-lists/time-blocking
  feed the ranking signal); agent runtime contract ✓M0
- Story: [../user-stories/US-018-morning-planning.md](../user-stories/US-018-morning-planning.md)

Tasks:
- Schema/migration `300`: `personal_daily_plan` + `personal_daily_plan_item` (suggested order, rationale, accept/edit/remove state)
- Backend: `domains/personal/planning` context; `PlannerAgent` scoring backlog+due+streak+prior-day signals; `POST /api/personal/plans` generate, `PATCH /api/personal/plans/:id` confirm/edit
- Frontend: "Plan My Day" action + accept/reorder review UI under `app/app/[orgId]/personal/**`
- Tests: domain unit tests for the balance/energy/urgency heuristic; Cypress generate→edit→confirm flow
- Contract: confirmed plan writes into WS-L's today read-model with an `ai-planned` flag — publish via the read-model API, do not touch `app/app/[orgId]/today`

### US-019 — AI-generated weekly review
- Persona(s): Alex Russo
- Size: M
- Deps: US-018 (same lane, same milestone — reuses planning-agent scoring signals); US-020 ✓M2 (archive, source of completed items); US-014 ✓M2 (streak status)
- Story: [../user-stories/US-019-weekly-review-ai.md](../user-stories/US-019-weekly-review-ai.md)

Tasks:
- Schema/migration `301`: `personal_weekly_review` (structured report, insights, user annotations, archived flag)
- Backend: `ReviewAgent` compiling completed/missed/streak/time-allocation sections; `POST /api/personal/reviews/generate`, configurable schedule trigger (default Sunday evening)
- Frontend: weekly review page + annotation editor under `app/app/[orgId]/personal/reviews`
- Tests: report-compilation unit tests against fixture item sets; Cypress annotate-and-archive flow
- Contract: none — fully in-lane; reads only WS-A-owned tables

---

## WS-C — Projects & Delivery

### US-023 — AI-assisted sprint planning
- Persona(s): Sarah Kim
- Size: L
- Deps: US-021 ✓M1 (project/methodology base); US-022 ✓M2 (kanban, source of velocity data); US-024 ✓M2 (assign-to-agent/human — workload input); agent runtime contract ✓M0
- Story: [../user-stories/US-023-sprint-planning-ai.md](../user-stories/US-023-sprint-planning-ai.md)

Tasks:
- Schema/migration `310`: `project_sprint_plan_draft` (proposed items, capacity assumption, per-item rationale, accept/regen state)
- Backend: `SprintPlannerAgent` computing rolling velocity, dependency/blocked-item filtering, workload skew flags; `POST /api/projects/:id/sprints/draft`, `POST .../sprints/finalize`
- Frontend: draft sprint review panel (accept/modify/regenerate-with-params) under `app/app/[orgId]/projects/**`
- Tests: velocity-fallback unit test (no-history case); Cypress draft→finalize→notify-assignees flow
- Contract: reads WS-J's assignee/workload contract (from US-024) for capacity input — read-only

### US-028 — AI-assisted backlog grooming
- Persona(s): Sarah Kim
- Size: M
- Deps: US-022 ✓M2 (kanban/backlog); US-023 (same lane, same milestone — shares estimation-similarity model)
- Story: [../user-stories/US-028-backlog-grooming-ai.md](../user-stories/US-028-backlog-grooming-ai.md)

Tasks:
- Schema/migration `311`: `project_grooming_suggestion` (priority/estimate/grouping suggestion, confidence, accept/reject, per-item reference)
- Backend: `GroomingAgent` similarity-based estimate suggestion + staleness detection; `POST /api/projects/:id/groom`, bulk accept/undo endpoint
- Frontend: side-by-side diff view + "grooming mode" walkthrough under `app/app/[orgId]/projects/**`
- Tests: staleness-threshold unit test; Cypress bulk-accept-with-undo flow
- Contract: none — fully in-lane

---

## WS-D — Bugs & Quality

### US-034 — AI auto-triage incoming bugs
- Persona(s): Sarah Kim
- Size: M
- Deps: US-033 ✓M2 (bug capture+enrichment baseline); agent runtime contract ✓M0; WS-L notification service ✓M0
- Story: [../user-stories/US-034-ai-auto-triage.md](../user-stories/US-034-ai-auto-triage.md)

Tasks:
- Schema/migration `315`: `bug_triage_suggestion` (suggested severity, confidence, rationale, override, suggested assignee)
- Backend: `TriageAgent` running within 30s of bug create (keywords/component-criticality/impact/SLA/similarity); override feedback loop into training signal
- Frontend: severity badge + one-click override + low-confidence triage-review queue under `app/app/[orgId]/bugs/**`
- Tests: confidence-threshold routing unit test; Cypress override-feeds-back-to-model flow (assert override recorded)
- Contract: critical/high triage results push through WS-L's notification service to on-call/lead — consume, do not extend the notification schema directly

### US-035 — Link bugs to monitoring incidents
- Persona(s): Maya Chen
- Size: S
- Deps: US-033 ✓M2; WS-F incident data (US-048 ✓M1 uptime dashboard, US-049 ✓M2 alert-to-incident)
- Story: [../user-stories/US-035-bug-incident-link.md](../user-stories/US-035-bug-incident-link.md)

Tasks:
- Schema/migration `316`: `bug_incident_link` (bidirectional, incident source ref, resolution-verification flag)
- Backend: incident search/auto-suggest via WS-F's MCP monitoring adapter; bidirectional link API in `domains/bugs`
- Frontend: "Incidents" section on bug detail rendering live incident data (title/severity/status)
- Tests: bidirectional-link integrity test; Cypress link→incident-resolves→verification-flag flow
- Contract: consumes WS-F's incident-reference contract (read-only, real-time via MCP) — WS-F owns the incident schema, WS-D only stores the link

### US-037 — Automatic duplicate bug detection
- Persona(s): Lin Zhao
- Size: L
- Deps: US-033 ✓M2; pgvector infra decision ✓M0
- Story: [../user-stories/US-037-duplicate-detection.md](../user-stories/US-037-duplicate-detection.md)

Tasks:
- Schema/migration `317`: `bug_embedding` (pgvector column) + `bug_duplicate_cluster`
- Backend: embedding generation on bug create/edit; real-time similarity search (<500ms budget); background cluster-scan job for missed duplicates
- Frontend: inline duplicate-candidate panel during creation (link-as-duplicate / proceed / merge-context) under `app/app/[orgId]/bugs/**`
- Tests: embedding-similarity ranking unit test; Cypress creation-time duplicate-suggestion flow
- Contract: none — pgvector infra is shared platform capability (M0), not another lane's owned code

### US-038 — Root cause linking for bug pattern analysis
- Persona(s): Lin Zhao
- Size: M
- Deps: item polymorphism decision ✓M0 (root cause = item with a relationship type, not a new entity); US-037 (same lane, same milestone — shares similarity infra)
- Story: [../user-stories/US-038-root-cause-linking.md](../user-stories/US-038-root-cause-linking.md)

Tasks:
- Schema/migration `318`: `item_relationship` type `root-cause` (generic relationship, not a bug-only table) + `root_cause_impact_summary` materialized view
- Backend: root-cause designation API, impact-summary aggregation, `RootCauseAgent` grouping suggestion (stack-trace/component/timing correlation)
- Frontend: root-cause analysis dashboard (top causes by impact, trending patterns) under `app/app/[orgId]/bugs/**`
- Tests: bulk-transition-on-resolve unit test; Cypress root-cause-link→resolve→verify-symptoms flow
- Contract: none — fully in-lane, built on M0's item-relationship primitive

---

## WS-E — CI/CD & Deploy

### US-043 — Trigger rollback from Plans on deploy regression
- Persona(s): Lin Zhao
- Size: M
- Deps: US-041 ✓M1 (pipeline status); US-042 ✓M2 (deploy-aware transitions); US-047 (same lane, same milestone — rollback respects the approval workflow when configured; land US-047 first or degrade gracefully if not yet merged)
- Story: [../user-stories/US-043-rollback-trigger.md](../user-stories/US-043-rollback-trigger.md)

Tasks:
- Schema/migration `320`: `deploy_rollback` (initiator, reason, target version, outcome, audit fields)
- Backend: rollback action via existing CI/CD provider adapter; impact preview (affected linked items); post-rollback auto-transition
- Frontend: "Rollback" action + confirmation modal (current/target version, impact) on deploy item under `app/app/[orgId]/pipelines/**`
- Tests: dry-run-mode unit test; Cypress rollback→approval-gate-respected (when US-047 active)→post-rollback-annotation flow
- Contract: reads US-047's approval-gate contract when configured — gate check is a function call into WS-E's own module, no cross-lane dependency

### US-047 — Require approval before production deploys
- Persona(s): Sarah Kim, Lin Zhao
- Size: M
- Deps: US-077 ✓M2 (roles/permissions — approvers can be humans by role or agents); US-044 ✓M2 (deploy changelog, approvers see rich summary)
- Story: [../user-stories/US-047-deploy-approval-workflow.md](../user-stories/US-047-deploy-approval-workflow.md)

Tasks:
- Schema/migration `321`: `deploy_approval_gate` (per-environment config) + `deploy_approval` (approver identity, decision, timestamp, comment)
- Backend: gate evaluation on deploy trigger; agent-as-approver support (criteria-based); timeout/expiry job
- Frontend: pending-approval promotion into approver's Today view + deploy summary card under `app/app/[orgId]/pipelines/**`
- Tests: agent-approver-criteria unit test; Cypress approve/reject-with-audit-trail flow
- Contract: consumes WS-J's roles/permissions model (US-077) for approver identity resolution; consumes WS-E's own US-044 changelog for the summary shown to approvers (in-lane); pending approvals surface via WS-L's Today read-model (publish, don't edit)

---

## WS-F — Monitoring & Incidents

### US-051 — View reconstructed incident timeline with correlated events
- Persona(s): Lin Zhao
- Size: L
- Deps: US-049 ✓M2 (alert-to-incident); WS-E deploy events (US-042/US-044 ✓M2); WS-J agent-intervention log (US-078, same milestone)
- Story: [../user-stories/US-051-incident-timeline.md](../user-stories/US-051-incident-timeline.md)

Tasks:
- Schema/migration `325`: `incident_timeline_event` (source type, service lane, payload ref, causation-confidence)
- Backend: event aggregation from alerts/deploys/status-changes/manual-actions/agent actions; causation-annotation heuristic (temporal proximity + service deps)
- Frontend: service-laned chronological timeline with expandable event detail under `app/app/[orgId]/monitoring/**`
- Tests: multi-source correlation unit test; Cypress timeline-render→expand-event→export-markdown flow
- Contract: reads WS-E's deploy-event stream (US-042/US-044) and WS-J's agent-action log (US-078) — both read-only source feeds into WS-F's own timeline table

### US-052 — Integrate on-call schedule for incident routing
- Persona(s): Sarah Kim
- Size: M
- Deps: US-049 ✓M2 (incident creation, routing target); WS-J agent-as-L1 pattern (agent runtime ✓M0)
- Story: [../user-stories/US-052-oncall-integration.md](../user-stories/US-052-oncall-integration.md)

Tasks:
- Schema/migration `326`: `oncall_schedule` + `oncall_rotation` + `oncall_swap`
- Backend: native rotation engine + PagerDuty/OpsGenie import adapters; auto-assign-on-incident-create with escalation timeout
- Frontend: on-call roster widget (current/next/swap-history) under `app/app/[orgId]/monitoring/**`
- Tests: escalation-timeout unit test; Cypress shift-swap-updates-schedule flow
- Contract: on-call load feeds WS-C's sprint-planning workload input (US-023, this milestone) — publish as a read model, WS-C consumes, no direct edit

### US-055 — Generate pre-filled post-incident review template
- Persona(s): Sarah Kim
- Size: M
- Deps: US-051 (same lane, same milestone — sequence after; timeline is the primary input); US-056 ✓M1 (wiki/docs storage)
- Story: [../user-stories/US-055-post-incident-review.md](../user-stories/US-055-post-incident-review.md)

Tasks:
- Schema/migration `327`: `incident_review` (structured sections, 5-whys draft, blameless-mode flag)
- Backend: "Generate Review" action pulling timeline+activity+affected-items; action items created as trackable items linked back to the incident
- Frontend: editable review document (root cause/contributing factors/action items) under `app/app/[orgId]/monitoring/**`
- Tests: blameless-mode redaction unit test; Cypress generate→edit→action-items-created-in-backlog flow
- Contract: stores completed review into WS-G's wiki/docs system (US-056) via the standard doc-creation API; action items are created as generic items — may land in any lane's backlog (WS-A/WS-C), created via the shared item-creation API, not a direct table write

---

## WS-G — Docs & Knowledge

### US-059 — Manage runbooks with version control and incident linking
- Persona(s): Lin Zhao
- Size: M
- Deps: US-056 ✓M1 (wiki base); WS-F incident data (for suggestion + usage-tracking linkage)
- Story: [../user-stories/US-059-runbook-management.md](../user-stories/US-059-runbook-management.md)

Tasks:
- Schema/migration `330`: `runbook` + `runbook_version` + `runbook_usage_link`
- Backend: structured-template CRUD with versioning; agent runbook-suggestion on incident create/escalate; usage-tracking on reference
- Frontend: runbook editor + version history + "runbook drill" rehearsal mode under `app/app/[orgId]/wiki/**`
- Tests: version-immutability unit test; Cypress incident-suggests-runbook→reference-tracked flow
- Contract: consumes WS-F's incident-create/escalate event (read-only trigger) to surface suggestions; executable-step execution (data-model-ready, not implemented this milestone) will route through WS-J's agent-governance approval gate in a later milestone

### US-061 — Auto-generate changelog from commits and linked items
- Persona(s): Maya Chen
- Size: S
- Deps: US-044 ✓M2 (shared changelog-generation service — HARD REQUIREMENT, see Flag 2)
- Story: [../user-stories/US-061-auto-changelog.md](../user-stories/US-061-auto-changelog.md)

Tasks:
- Schema/migration `331`: `docs_changelog_publication` (wiki-page ref, source changelog-service run ID) — no commit-parsing tables; that logic lives in WS-E's US-044 service
- Backend: `domains/docs` thin adapter calling WS-E's shared changelog service (do not re-implement conventional-commit parsing or dedup — Flag 2); adds docs-surface only: AI-suggested user-facing rewrite pass, incremental-generation trigger
- Frontend: changelog review/edit + "publish to wiki" action under `app/app/[orgId]/wiki/**`
- Tests: adapter-contract test asserting no duplicate parsing logic exists in WS-G; Cypress generate→rewrite→publish-to-wiki flow
- Contract: **consumes WS-E's shared changelog-generation service (US-044) as-is** — WS-G owns only the docs-surface (rewrite UX + wiki publication), WS-E owns generation; any parsing change is an interface ticket to WS-E, not a WS-G edit

### US-062 — Full-text search across wiki, docs, runbooks, and ADRs
- Persona(s): Diana Kovacs
- Size: M
- Deps: US-056 ✓M1; US-058 ✓M2 (ADR tracking); US-059 (same lane, same milestone — sequence after, indexes runbooks); pgvector/full-text infra decision ✓M0; auth context reuse ✓WS-L
- Story: [../user-stories/US-062-knowledge-base-search.md](../user-stories/US-062-knowledge-base-search.md)

Tasks:
- Schema/migration `332`: `docs_search_index` (trigram/tsvector index across wiki/runbook/ADR/doc tables, workspace-scoped)
- Backend: unified search API with relevance ranking + snippet extraction, `<2s` for 10k-doc corpora; type/project/author/date filters
- Frontend: cross-document search UI with deep-linking to matched section under `app/app/[orgId]/wiki/**`
- Tests: workspace-boundary isolation test (no cross-client leakage); perf test at 10k-doc corpus
- Contract: reuses WS-L's auth/workspace-scoping context (no new access model) — read-only integration

---

## WS-H — Checklists & Templates

### US-067 — Manage library of item, project, and workflow templates
- Persona(s): James Oduya
- Size: L
- Deps: US-030 ✓M2 (project templates — contract input); US-063 ✓M2 (doc templates — contract input)
- Story: [../user-stories/US-067-template-library.md](../user-stories/US-067-template-library.md)

Tasks:
- Schema/migration `335`: `template_library_entry` (type: item/project/workflow, parameterized-variable schema, version)
- Backend: template CRUD + parameterized instantiation resolver; versioning (updates don't retroact onto instantiated projects)
- Frontend: **first WS-H-owned route** — library browse/search/tag UI at `app/app/[orgId]/templates/**` (new route segment)
- Tests: parameterization-resolution unit test; Cypress instantiate-from-template→verify-child-project-structure flow
- Contract: consumes WS-C's project-template contract (US-030) and WS-G's doc-template contract (US-063) as inputs, read-only; new route segment requires an interface ticket to WS-L for nav-entry registration (WS-L owns nav, per Convention 4)

### US-068 — Automated pre-deploy checklist with verification gates
- Persona(s): Maya Chen
- Size: M
- Deps: US-065 ✓M2 (checklist enforcement base); WS-E pipeline/deploy contract (US-041 ✓M1, US-042 ✓M2)
- Story: [../user-stories/US-068-pre-deploy-checklist.md](../user-stories/US-068-pre-deploy-checklist.md)

Tasks:
- Schema/migration `336`: `deploy_checklist` (auto-populated items, automated/manual verification type, gate state) persisted as a deploy record
- Backend: change-detection auto-population (code/config/infra/docs diff); CI-webhook-driven automated item resolution; deploy-gate enforcement hook
- Frontend: pre-deploy checklist panel (embedded in deploy flow, not a standalone route) under `components/checklists/**`
- Tests: gate-blocks-deploy-until-green unit test; Cypress override-with-explicit-confirmation flow
- Contract: consumes WS-E's pipeline-status/deploy-trigger contract to gate the deploy action — WS-E exposes a pre-deploy hook, WS-H does not modify `domains/cicd`

---

## WS-I — Goals & OKRs

### US-013 + US-074 — Personal OKRs with visibility controls (MERGED)
- Persona(s): Alex Russo
- Size: L
- Deps: US-069 ✓M1 (OKR hierarchy — extended, not rebuilt); US-070 ✓M2 (auto-progress KRs)
- Story: [../user-stories/US-013-personal-okrs.md](../user-stories/US-013-personal-okrs.md), [../user-stories/US-074-personal-alongside-team-okrs.md](../user-stories/US-074-personal-alongside-team-okrs.md)

Delivered as one implementation per Flag 1 — US-074 is the visibility layer on top of US-013's
personal-OKR data model; there is no separate "personal goals" feature.

Tasks:
- Schema/migration `340`: extends `okr_objective`/`okr_key_result` (✓M1/M2 tables) with `visibility` enum (private/shared/public), `shared_with` join table — no new parallel goal entity
- Backend: numeric/binary/milestone KR progress types; visibility-scoped query layer enforced at the repo boundary (never at the UI layer) so private goals cannot leak into search, reports, or agent output
- Frontend: quarterly review (red/yellow/green scoring) + visibility toggle + combined personal/team view under `app/app/[orgId]/goals/**`
- Tests: visibility-leak regression suite (search/report/agent-output paths all assert private-goal exclusion) — this is the highest-risk test in the lane
- Contract: publishes a visibility-scoped read model consumed by WS-L's unified today view (US-001 ✓M2) — WS-L must honor the visibility flag before rendering; private-by-default is the safe failure mode

### US-071 — Planner agent drafts OKR check-in summaries with risk flags
- Persona(s): Alex Russo
- Size: M
- Deps: merged US-013/074 (same lane, same milestone — sequence after); agent runtime contract ✓M0
- Story: [../user-stories/US-071-okr-checkin-agent.md](../user-stories/US-071-okr-checkin-agent.md)

Tasks:
- Schema/migration `341`: `okr_checkin_draft` (progress snapshot, velocity trend, risk flags with evidence, on-track/at-risk/off-track)
- Backend: `CheckinAgent` on configurable schedule (default weekly), risk-flag evidence citation (blocked-item duration etc.)
- Frontend: check-in draft review (accept/edit/discard) + timeline-over-cycle view under `app/app/[orgId]/goals/**`
- Tests: risk-flag-evidence-citation unit test; Cypress accept-draft-becomes-official-record flow
- Contract: covers both personal and team goals in one session per US-074's visibility model — reads the same visibility-scoped model, no separate contract

### US-073 — Score OKRs at end of cycle with historical comparison
- Persona(s): Sarah Kim
- Size: M
- Deps: US-069 ✓M1, US-070 ✓M2
- Story: [../user-stories/US-073-okr-scoring.md](../user-stories/US-073-okr-scoring.md)

Tasks:
- Schema/migration `342`: `okr_cycle_score` (0.0-1.0 per KR, self/lead-assessment, discrepancy flag, archived)
- Backend: end-of-cycle scoring workflow with auto-suggested values; calibration-analysis agent (pattern vs. prior cycles)
- Frontend: scoring workflow + historical trend visualization (quarter-over-quarter) under `app/app/[orgId]/goals/**`
- Tests: calibration-suggestion unit test; Cypress self-vs-lead-discrepancy-highlight flow
- Contract: none — fully in-lane; historical data designed for long-term accumulation from this milestone forward

---

## WS-J — Agent Platform & Governance

### US-078 — Agent activity audit log with filtering
- Persona(s): Lin Zhao
- Size: M
- Deps: agent runtime contract ✓M0 (source of loggable actions)
- Story: [../user-stories/US-078-agent-audit-log.md](../user-stories/US-078-agent-audit-log.md)

Tasks:
- Schema/migration `345`: `agent_audit_log` (append-only, tamper-evident — no UPDATE/DELETE grants at the DB role level)
- Backend: audit-emit API published as a **cross-lane contract** (every agent-invoking story this milestone must call it); filter/query API (agent/action/resource/time/outcome); JSON/CSV export
- Frontend: audit log viewer (filterable) under `app/app/[orgId]/agents/**`
- Tests: append-only enforcement test (attempt update/delete must fail at DB layer, not just app layer); Cypress filter-and-export flow
- Contract: **WS-J publishes the audit-emit API at milestone start** — WS-A/C/D/F/G/H/I stories that invoke agents this milestone (US-018/019/023/028/034/037/038/051/055/059/067/071) all call it; WS-K's US-095 has a soft dependency on this contract (Flag 3, see below)

### US-080 — Track agent performance metrics and ROI
- Persona(s): Lin Zhao
- Size: M
- Deps: US-078 (same lane, same milestone — sequence after; "pairs with US-078 as the data source" per story notes); US-076 ✓M1 (agent registry)
- Story: [../user-stories/US-080-agent-performance-metrics.md](../user-stories/US-080-agent-performance-metrics.md)

Tasks:
- Schema/migration `346`: `agent_performance_metric` (tasks completed, error rate, time-to-completion, override rate, per-period aggregation)
- Backend: metrics rollup job reading the audit log; ROI calc against historical human-baseline estimate; threshold alerting
- Frontend: agent performance dashboard (trend indicators) under `app/app/[orgId]/agents/**`
- Tests: override-rate-as-trust-proxy unit test; Cypress threshold-alert-fires flow
- Contract: reads WS-J's own US-078 log (in-lane); cost dimension is partial this milestone — full cost data lands with US-085 (M4); note the gap in the dashboard rather than block on it

### US-083 — Create custom agents with user-defined roles and constraints
- Persona(s): Lin Zhao
- Size: L
- Deps: US-076 ✓M1 (agent registry); US-077 ✓M2 (roles/permissions — tool-access matrix builds on it)
- Story: [../user-stories/US-083-custom-agent-creation.md](../user-stories/US-083-custom-agent-creation.md)

Tasks:
- Schema/migration `347`: `custom_agent_definition` (system prompt, tool permission matrix, behavioral constraints, versioned charter) + `custom_agent_template`
- Backend: agent builder API; **enforced** (not advisory) tool-access gating at the MCP invocation layer; dry-run harness against sample tasks
- Frontend: custom agent builder (permission matrix, constraint editor, dry-run panel) under `app/app/[orgId]/agents/**`
- Tests: enforced-denial test (denied tool call must be physically blocked, not just logged); Cypress dry-run→activate flow
- Contract: agent "charter" (prompt+constraints) is versioned in a way that anticipates WS-K's prompt-archival domain — data shape aligned with US-086 ✓M1, no shared table yet

---

## WS-K — Prompts & Evaluation

### US-089 — Compare prompt versions side-by-side with performance delta
- Persona(s): Lin Zhao
- Size: M
- Deps: US-086 ✓M1 (prompt versioning); US-096 ✓M2 (agent output ratings — available at milestone start); US-097 (same lane, same milestone — enriches the performance panel once rubric scores land, best-effort at milestone start)
- Story: [../user-stories/US-089-compare-prompt-versions.md](../user-stories/US-089-compare-prompt-versions.md)

Tasks:
- Schema/migration `350`: `prompt_comparison_report` (version pair, diff, metric snapshot, export ref)
- Backend: inline diff engine; performance-metric join (quality score, completion rate, escalation frequency, cost); auto-generated plain-language summary; eval-methodology-change flag
- Frontend: side-by-side diff + performance panel + export (Markdown/PDF) under `app/app/[orgId]/prompts/**`
- Tests: cross-agent-same-role comparison unit test; Cypress select-two-versions→export flow
- Contract: reads WS-K's own US-096 (M2) and US-097 (this milestone, in-lane) eval scores — intra-lane, no cross-lane dependency

### US-092 — Share prompts across team members with permissions
- Persona(s): Sarah Kim
- Size: M
- Deps: US-077 ✓M2 (roles/permissions — reused for view/clone/edit levels); US-086 ✓M1 (prompt versioning — edit attribution)
- Story: [../user-stories/US-092-prompt-sharing.md](../user-stories/US-092-prompt-sharing.md)

Tasks:
- Schema/migration `351`: `prompt_share` (view/clone/edit, revocable, source-attribution)
- Backend: share/revoke API; clone-creates-independent-copy semantics; edit-permission attribution into version history
- Frontend: share dialog + recipient library indicator (source author, permission level) under `app/app/[orgId]/prompts/**`
- Tests: revocation-does-not-affect-clones unit test; Cypress share→clone→independent-edit flow
- Contract: consumes WS-J's US-077 permission model directly (three-level simplification, not full RBAC) — read-only reuse

### US-097 — Define automated evaluation rubrics for agent tasks
- Persona(s): Lin Zhao
- Size: L
- Deps: US-086 ✓M1 (prompt versioning); agent runtime task-completion event ✓M0
- Story: [../user-stories/US-097-automated-eval-rubrics.md](../user-stories/US-097-automated-eval-rubrics.md)

Tasks:
- Schema/migration `352`: `eval_rubric` (versioned, weighted dimensions) + `eval_rubric_score` (per-task, immutable once scored)
- Backend: rubric builder (binary/numeric/threshold scoring); async post-completion scorer; deterministic checks first (regex/timestamp/checklist-coverage), LLM-as-judge layered in for subjective dimensions; rubric test-mode against historical outputs
- Frontend: rubric builder + test-mode preview under `app/app/[orgId]/evals/**`
- Tests: versioning-does-not-retroact unit test (change rubric, assert historical scores untouched); Cypress build→test-mode→activate flow
- Contract: consumes WS-J's agent task-completion event (M0 contract) to trigger scoring — read-only hook, no edit into `domains/agents`

### US-095 — Compliance-grade audit trail for prompt changes
- Persona(s): Lin Zhao
- Size: L
- Deps: US-086 ✓M1 (direct dependency — "the audit trail wraps around the versioning system," per story notes); **SOFT DEP: US-078 (WS-J, same milestone, in-flight)**
- Story: [../user-stories/US-095-prompt-audit-trail.md](../user-stories/US-095-prompt-audit-trail.md)

**Sequencing rule (Flag 3):** scheduled **last** in WS-K's M3 lane, after US-089/US-092/US-097.
This story consumes WS-J's audit-emit contract (US-078) rather than building a parallel
compliance-log mechanism. If WS-J's US-078 contract is not stable and merged by the time
WS-K reaches this story in-lane, **US-095 slips to M4 in full** — do not partially build
against an unstable contract or fork a second audit-log implementation.

Tasks:
- Schema/migration `353`: `prompt_audit_log` (append-only, hash-chained, mandatory rationale field, actor/timestamp/before-after state)
- Backend: audit-emit hook on every prompt mutation (create/edit/restore/delete) reusing WS-J's US-078 append-only pattern; hash-chain export (CSV/JSON Lines) with integrity verification; admin+secondary-approval deletion gate
- Frontend: compliance audit viewer (actor/date/agent/change-type/rationale search) under `app/app/[orgId]/prompts/**`
- Tests: hash-chain integrity test (tamper detection on export); append-only enforcement test (admin cannot bypass without secondary approval)
- Contract: **soft-consumes WS-J's US-078 audit-emit contract** for the append-only/tamper-evident pattern — if unavailable at lane-entry, slip to M4 rather than reimplementing independently

---

## WS-L — Platform Shell & Cross-Domain

### US-002 — Agent activity feed in today view
- Persona(s): Maya Chen
- Size: M
- Deps: US-001 ✓M2 (unified today dashboard — base surface); WS-J agent status stream (new contract, this milestone)
- Story: [../user-stories/US-002-agent-activity-feed.md](../user-stories/US-002-agent-activity-feed.md)

Tasks:
- Schema/migration `355`: `today_agent_activity_snapshot` (denormalized read-model row, not a duplicate of WS-J's agent state)
- Backend: WebSocket/SSE relay subscribing to WS-J's agent-status events; error-state promotion logic
- Frontend: collapsible agent activity panel (compact/expanded modes) in `app/app/[orgId]/today/**`
- Tests: real-time-update unit test (no page refresh); Cypress error-state-promotes-to-top flow
- Contract: **consumes WS-J's agent-activity/status contract** (websocket channel — naming convention owned by WS-L per Cross-cutting Conventions) — WS-J publishes, WS-L subscribes only

### US-003 — Drag to reorder daily priorities
- Persona(s): Alex Russo
- Size: S
- Deps: US-001 ✓M2
- Story: [../user-stories/US-003-drag-reorder-priorities.md](../user-stories/US-003-drag-reorder-priorities.md)

Tasks:
- Schema/migration `356`: `today_priority_rank` (ephemeral daily rank, does not alter item's intrinsic priority)
- Backend: rank-persistence API; "reset to default order" restoring AI-suggested/priority-based sort
- Frontend: drag-and-drop + Alt+Up/Down keyboard reordering in `app/app/[orgId]/today/**`
- Tests: keyboard-accessibility unit test; Cypress reorder-persists-across-reload flow
- Contract: none — self-contained UI-layer feature on WS-L's own surface

### US-004 — Cross-project today summary for multi-client work
- Persona(s): Diana Kovacs
- Size: M
- Deps: US-001 ✓M2; WS-C project/client model ✓M1
- Story: [../user-stories/US-004-cross-project-today-summary.md](../user-stories/US-004-cross-project-today-summary.md)

Tasks:
- Schema/migration `357`: `today_project_summary_view` (per-project grouping, deadline-conflict flag)
- Backend: cross-project grouping + overlapping-deadline detection; active/paused-project filter
- Frontend: collapsible per-project header (item count, nearest deadline) + client filter in `app/app/[orgId]/today/**`
- Tests: deadline-conflict-detection unit test; Cypress toggle-inactive-projects flow
- Contract: reads WS-C's project/client model (read-only); **time-allocation (planned vs. actual hours) degrades to estimated-hours only** — real time-tracking is an unbuilt gap (Diana Kovacs persona flag, see M5 backlog reconciliation), do not block this story on it

### US-005 — Personal and team items in unified stream
- Persona(s): Sarah Kim, Raj Patel
- Size: M
- Deps: US-001 ✓M2; WS-A personal-item domain badge ✓M1/M2; WS-C team assignee/status ✓M1/M2
- Story: [../user-stories/US-005-personal-team-unified-stream.md](../user-stories/US-005-personal-team-unified-stream.md)

Tasks:
- Schema/migration `358`: `today_stream_domain_filter_pref` (persisted personal/team/all toggle)
- Backend: unified stream assembly across personal + team read models; action-required promotion (approvals/reviews)
- Frontend: domain-badged item rendering + persistent filter toggle in `app/app/[orgId]/today/**`
- Tests: domain-badge-correctness unit test; Cypress filter-persists-across-session flow
- Contract: reads WS-A's personal-item read model and WS-C's team-item/assignee read model (both published at M1/M2) — read-only aggregation, WS-L does not write into either lane's tables

---

## Cross-lane contracts agreed at milestone start

| Producer lane | Consumer lane(s) | Contract | Purpose |
|---|---|---|---|
| WS-J | all agent-invoking lanes (A, C, D, F, G, H, I) | Agent audit-emit API (US-078) | Every agent action logged append-only; foundation for compliance and metrics |
| WS-J | WS-L | Agent activity/status stream (websocket) | Powers US-002's real-time agent activity panel |
| WS-J | WS-K | Audit-emit contract (US-078, in-flight) | Soft dependency for US-095; slips to M4 if not stable (Flag 3) |
| WS-E | WS-G | Shared changelog-generation service (US-044 ✓M2) | US-061 consumes as-is; WS-G owns docs-surface only, no re-implementation (Flag 2) |
| WS-E | WS-D (US-035) | Approval-gate contract (US-047, in-lane) | US-043 rollback respects approval gate when configured |
| WS-F | WS-D | Incident reference (MCP monitoring source, read-only) | US-035 bug↔incident bidirectional link |
| WS-J | WS-E | Roles/permissions model (US-077 ✓M2) | US-047 resolves human/agent approver identity |
| WS-C (US-030) + WS-G (US-063) | WS-H | Project-template / doc-template contracts (✓M2) | Inputs to US-067's unified template library |
| WS-E | WS-H | Pipeline/deploy status contract (US-041/US-042) | Automated verification items in US-068's pre-deploy checklist |
| WS-I | WS-L | Visibility-scoped goal read model (merged US-013/074) | US-001 today aggregation must honor private/shared/public before rendering |
| WS-A | WS-L | Personal-item read model (✓M1/M2) | US-005 unified stream aggregation |
| WS-C | WS-L | Team-item/assignee read model (✓M1/M2) | US-005 unified stream aggregation |
