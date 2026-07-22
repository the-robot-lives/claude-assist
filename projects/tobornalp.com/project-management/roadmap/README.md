---
title: tobornalp.com Implementation Roadmap
milestone: M0-M5
status: draft
generated: 2026-07-16
---

# tobornalp.com Implementation Roadmap

## Purpose

`therobotplans` (internal name for tobornalp.com) is an AI-native operational-life
platform — todos, projects, CI/CD, bugs, monitoring, wiki, and OKRs, with AI agents
as first-class team members. The backend (Elixir/Phoenix, 241 `.ex` files) is
substantially built out; the frontend (Next.js 16) has a solid auth/onboarding flow
but a thin `/app/[orgId]` product surface. 100 user stories (US-001..US-100) are
specified against 7 personas, ~76 screens, and ~78 components.

This roadmap sequences those 100 stories into 6 milestones (M0–M5) across 12
persistent workstream lanes, so that any number of engineers or AI agent workers
can build in parallel with near-zero merge conflict, and so cross-lane dependencies
are resolved through published contracts rather than shared-file edits.

## Roadmap principles

1. **Sequence, not timeline.** Milestones are dependency gates: milestone N+1 starts
   only when its entry criteria (a subset of N's exit criteria) are met. No dates or
   estimates beyond S/M/L sizing.
2. **Lane ownership = merge safety.** Work is organized into 12 persistent workstream
   lanes (WS-A..WS-L). Each lane exclusively owns disjoint code areas (backend domain
   modules, frontend route segments, component namespaces). Within a milestone, any
   number of lanes run in parallel with near-zero file overlap. A lane may be staffed
   by 1..n workers; intra-lane parallelism is the lane owner's problem and stays
   inside owned paths.
3. **Contract-first cross-lane.** Any story needing another lane's data consumes it
   through a published API/event contract, agreed at milestone start, never by
   editing the other lane's code.
4. **Shared/hotspot files have a single owner** (WS-L Platform): Phoenix router, FE
   nav/shell, `mix.exs` / `package.json` deps, liquibase master changelog include,
   shared generated components. Other lanes request changes via interface tickets to
   WS-L.
5. **Audit before build.** The backend already implements parts of several epics
   (items-queues, OKRs, notifications changelogs exist). M0 maps existing code to
   stories so lanes extend rather than duplicate.

## Lane ownership

| Lane | Name | Backend ownership (`app/backend/lib/therobotplans/...`) | Frontend ownership (`app/frontend/src/...`) |
|------|------|------|------|
| WS-A | Personal Items & Habits | `domains/personal` (items, habits, smart lists, time blocks, archive) | `app/app/[orgId]/personal/**`, `components/personal/**` |
| WS-B | Inbox & Capture | `domains/inbox` (capture, triage, email/voice ingestion) | `app/app/[orgId]/inbox/**`, `components/capture/**` |
| WS-C | Projects & Delivery | `domains/projects` (methodology, sprint, kanban, portfolio, gantt, templates) | `app/app/[orgId]/projects/**`, `components/pm/**` |
| WS-D | Bugs & Quality | `domains/bugs` | `app/app/[orgId]/bugs/**`, `components/bugs/**` |
| WS-E | CI/CD & Deploy | `domains/cicd` (pipelines, deploys, environments, approvals) | `app/app/[orgId]/pipelines/**`, `components/cicd/**` |
| WS-F | Monitoring & Incidents | `domains/monitoring` (uptime, SLO, incidents, status page) | `app/app/[orgId]/monitoring/**`, `app/status/**` (public), `components/monitoring/**` |
| WS-G | Docs & Knowledge | `domains/docs` (wiki, ADR, runbooks, kb-search) | `app/app/[orgId]/wiki/**`, `components/docs/**` |
| WS-H | Checklists & Templates | `domains/checklists` | `components/checklists/**` (embedded UI; no own route until US-067) |
| WS-I | Goals & OKRs | `domains/okrs` (extend existing) | `app/app/[orgId]/goals/**`, `components/okr/**` |
| WS-J | Agent Platform & Governance | `domains/agents` (registry, roles, audit, queue, metrics, orchestration) | `app/app/[orgId]/agents/**`, `components/agents/**` |
| WS-K | Prompts & Evaluation | `domains/prompts`, `domains/evals` | `app/app/[orgId]/prompts/**`, `app/app/[orgId]/evals/**`, `components/prompts/**` |
| WS-L | Platform Shell & Cross-Domain | `router.ex`, endpoint plugs, notifications service, search infra, event bus, MCP plane coordination, master changelog | app shell: `app/app/[orgId]/{layout,page}`, `today/**`, nav, `components/generated/**`, `components/ui/**` |

Cross-cutting conventions owned by WS-L: auth context reuse (existing), org scoping,
websocket channel naming, telemetry, i18n message catalogs (per-lane namespaced
files are lane-owned; the loader config is WS-L).

## Milestone summaries

**M0 — Baseline Audit & Platform Contracts.** A small crew (WS-L plus one auditor per
epic cluster) does enabling work only — no user stories are delivered. It audits the
241 existing backend files and changelogs 001–035 against the 100 stories, decides the
core Item polymorphism model, publishes the event-bus/notification and agent-runtime
contracts, stands up the `/app/[orgId]` shell and route-segment convention, maps
component specs to `@noizu/styleguide` primitives, and sets test/CI conventions. Exit:
contracts published, shell merged, audit matrix published — lanes can start M1 without
touching shared files.

**M1 — Foundational Verticals.** 10 stories, one per active lane (WS-D idle — bugs need
an items/projects base), all dependency-free. Every lane lands its core entity plus
CRUD API plus basic UI, demoable end-to-end. WS-L publishes cross-lane read-model
contracts (today-view aggregation, agent assignee reference, incident refs) that M2
consumes.

**M2 — Single-Lane Extensions.** 43 stories, maximum parallel width — every dependency
is either within-lane or on an M1 story. Each lane rounds out its epic's daily-use
surface (habits/streaks, mobile/AI/email/voice capture, kanban/portfolio/templates,
bug SLA, deploy transitions/changelog, alert-to-incident/SLO/status page, doc
linking/ADR/templates, checklist enforcement, KR auto-progress, agent roles/queue,
prompt history/tags/export). WS-L delivers the unified today dashboard (US-001),
aggregating M1 read models from WS-A, WS-C, WS-F, WS-J. Agent roles/permissions
(US-077) goes live here and gates M3.

**M3 — Cross-Lane Integration & First AI Wave.** 33 stories. Cross-lane dependencies
here consume M2 outputs, all satisfied at milestone entry except one soft same-
milestone dependency (US-095 on US-078, see Flags). This is the first wave of AI-assist
features across every epic (morning planning, sprint planning, auto-triage, duplicate
detection, rollback trigger, incident timeline, runbook/changelog/KB-search, OKR
check-in agent, agent audit log, prompt comparison/sharing) plus WS-L's expansion of
the today view (activity feed, drag reorder, cross-project summary, unified stream).
Exit: AI-assist live in every major epic; genai cost/usage instrumentation in place.

**M4 — Advanced, Portfolio & Enterprise.** 13 stories, ~6 active lanes; workers freed
from quieter lanes fold into these. Covers portfolio/enterprise-facing depth: sprint
retro agent, gantt for clients, cross-project dependencies, client-facing reports,
bug-to-deploy lifecycle, customer bug intake, anomaly correlation, goal retrospective,
agent collaboration protocols and cost tracking, prompt template library, eval
dashboard, A/B prompt variants. Exit: business/enterprise persona journeys (James,
Lin) complete.

**M5 — Closing the Loop & Release Readiness.** The capstone story, US-100
(eval→prompt feedback loop), plus roadmap-wide hardening: persona journey validation
against all 74 screen specs (Cypress e2e per persona), accessibility pass,
load/perf pass, helm/deploy hardening, docs, and backlog reconciliation for the
Diana Kovacs time-tracking/billing gap (filed as new stories, explicitly out of this
roadmap's scope). Exit: all 100 stories done or explicitly re-scoped; release
candidate deployable via the existing helm chart and monorepo deploy pipeline.

## Story assignment matrix

All 100 stories. Sizes for M1 are as specified in the source plan; sizes for
M2–M5 are roadmap-author estimates (S/M/L) pending refinement in the PRD pass
(Flag 4). "Depends on" reflects story-content-inferred sequencing (Flag 8), not a
frontmatter field.

| Story | Title (short) | Lane | Milestone | Size | Depends on |
|-------|---------------|------|-----------|------|------------|
| [US-001](../user-stories/US-001-unified-today-dashboard.md) | Unified today dashboard | WS-L | M2 | L | US-011, US-021, US-048, US-076 |
| [US-002](../user-stories/US-002-agent-activity-feed.md) | Agent activity feed in today | WS-L | M3 | S | US-001, US-076 |
| [US-003](../user-stories/US-003-drag-reorder-priorities.md) | Drag reorder priorities | WS-L | M3 | S | US-001 |
| [US-004](../user-stories/US-004-cross-project-today-summary.md) | Cross-project today summary | WS-L | M3 | M | US-001, US-021 |
| [US-005](../user-stories/US-005-personal-team-unified-stream.md) | Personal+team unified stream | WS-L | M3 | M | US-001 |
| [US-006](../user-stories/US-006-quick-capture-anywhere.md) | Quick capture anywhere | WS-B | M1 | S | none (M0 exit criteria only) |
| [US-007](../user-stories/US-007-mobile-capture.md) | Mobile capture | WS-B | M2 | S | US-006 |
| [US-008](../user-stories/US-008-ai-inbox-triage.md) | AI inbox triage | WS-B | M2 | L | US-006 |
| [US-009](../user-stories/US-009-email-to-inbox.md) | Email-to-inbox | WS-B | M2 | M | US-006 |
| [US-010](../user-stories/US-010-voice-capture.md) | Voice capture | WS-B | M2 | M | US-006 |
| [US-011](../user-stories/US-011-personal-todo-due-date.md) | Personal todo w/ due date | WS-A | M1 | M | none (M0 exit criteria only) |
| [US-012](../user-stories/US-012-recurring-habits.md) | Recurring habits | WS-A | M2 | M | US-011 |
| [US-013](../user-stories/US-013-personal-okrs.md) | Personal OKRs | WS-I | M3 | M | US-069; merged w/ US-074 (Flag 1) |
| [US-014](../user-stories/US-014-habit-streaks.md) | Habit streaks | WS-A | M2 | S | US-012 |
| [US-015](../user-stories/US-015-smart-lists.md) | Smart lists | WS-A | M2 | M | US-011 |
| [US-016](../user-stories/US-016-life-alongside-work.md) | Life-alongside-work view | WS-A | M2 | S | US-011 |
| [US-017](../user-stories/US-017-time-blocking.md) | Time blocking | WS-A | M2 | M | US-011 |
| [US-018](../user-stories/US-018-morning-planning.md) | AI morning planning | WS-A | M3 | M | M2 WS-A stories |
| [US-019](../user-stories/US-019-weekly-review-ai.md) | AI weekly review | WS-A | M3 | M | M2 WS-A stories |
| [US-020](../user-stories/US-020-archive-completed.md) | Archive completed | WS-A | M2 | S | US-011 |
| [US-021](../user-stories/US-021-create-project-methodology.md) | Create project w/ methodology | WS-C | M1 | L | none (M0 exit criteria only) |
| [US-022](../user-stories/US-022-kanban-board-view.md) | Kanban board view | WS-C | M2 | M | US-021 |
| [US-023](../user-stories/US-023-sprint-planning-ai.md) | AI sprint planning | WS-C | M3 | L | US-022 |
| [US-024](../user-stories/US-024-assign-to-agents-or-humans.md) | Assign to agents or humans | WS-C | M2 | M | US-021; WS-J assignee contract (US-076) |
| [US-025](../user-stories/US-025-multi-project-portfolio.md) | Multi-project portfolio dashboard | WS-C | M2 | L | US-021 |
| [US-026](../user-stories/US-026-per-project-methodology.md) | Per-project methodology | WS-C | M2 | M | US-021 |
| [US-027](../user-stories/US-027-sprint-retro-agent.md) | Sprint retro agent | WS-C | M4 | M | US-023 |
| [US-028](../user-stories/US-028-backlog-grooming-ai.md) | AI backlog grooming | WS-C | M3 | M | US-021 |
| [US-029](../user-stories/US-029-gantt-view-clients.md) | Gantt view for clients | WS-C | M4 | M | US-021 |
| [US-030](../user-stories/US-030-project-templates.md) | Project templates | WS-C | M2 | M | US-021 |
| [US-031](../user-stories/US-031-cross-project-dependencies.md) | Cross-project dependencies | WS-C | M4 | L | US-021, US-025 |
| [US-032](../user-stories/US-032-client-facing-reports.md) | Client-facing reports | WS-C | M4 | M | US-025 |
| [US-033](../user-stories/US-033-bug-auto-enrichment.md) | Bug capture + auto-enrichment | WS-D | M2 | M | US-011, US-021 (items/projects base) |
| [US-034](../user-stories/US-034-ai-auto-triage.md) | AI auto-triage | WS-D | M3 | M | US-033 |
| [US-035](../user-stories/US-035-bug-incident-link.md) | Bug↔incident link | WS-D | M3 | S | WS-F contract (US-048) |
| [US-036](../user-stories/US-036-bug-sla-tracking.md) | Bug SLA tracking | WS-D | M2 | M | US-033 |
| [US-037](../user-stories/US-037-duplicate-detection.md) | Duplicate detection (pgvector) | WS-D | M3 | L | US-033 |
| [US-038](../user-stories/US-038-root-cause-linking.md) | Root-cause linking | WS-D | M3 | M | US-033 |
| [US-039](../user-stories/US-039-bug-to-deploy-pipeline.md) | Bug-to-deploy lifecycle | WS-D | M4 | M | WS-E contract (US-042) |
| [US-040](../user-stories/US-040-customer-bug-intake.md) | Customer bug intake (public) | WS-D | M4 | M | US-033 |
| [US-041](../user-stories/US-041-pipeline-status-view.md) | Pipeline status view | WS-E | M1 | M | none (M0 exit criteria only) |
| [US-042](../user-stories/US-042-deploy-aware-transitions.md) | Deploy-aware transitions | WS-E | M2 | M | US-041 |
| [US-043](../user-stories/US-043-rollback-trigger.md) | Rollback trigger | WS-E | M3 | M | US-042 |
| [US-044](../user-stories/US-044-deploy-changelog.md) | Deploy changelog | WS-E | M2 | M | US-041; builds shared changelog service (Flag 2) |
| [US-045](../user-stories/US-045-environment-dashboard.md) | Environment dashboard | WS-E | M2 | M | US-041 |
| [US-046](../user-stories/US-046-pipeline-failure-context.md) | Pipeline failure notifications | WS-E | M2 | S | US-041; WS-L notification contract |
| [US-047](../user-stories/US-047-deploy-approval-workflow.md) | Deploy approval workflow | WS-E | M3 | M | US-042; US-077 ✓M2 |
| [US-048](../user-stories/US-048-uptime-dashboard.md) | Uptime dashboard | WS-F | M1 | M | none (M0 exit criteria only) |
| [US-049](../user-stories/US-049-alert-to-incident.md) | Alert-to-incident | WS-F | M2 | M | US-048 |
| [US-050](../user-stories/US-050-slo-tracking.md) | SLO tracking | WS-F | M2 | M | US-048 |
| [US-051](../user-stories/US-051-incident-timeline.md) | Incident timeline | WS-F | M3 | M | US-049 |
| [US-052](../user-stories/US-052-oncall-integration.md) | On-call integration | WS-F | M3 | M | US-049 |
| [US-053](../user-stories/US-053-status-page-gen.md) | Status page (public) | WS-F | M2 | M | US-048 |
| [US-054](../user-stories/US-054-anomaly-correlation.md) | AI anomaly correlation | WS-F | M4 | L | US-050 |
| [US-055](../user-stories/US-055-post-incident-review.md) | Post-incident review template | WS-F | M3 | S | US-049 |
| [US-056](../user-stories/US-056-structured-wiki.md) | Structured wiki | WS-G | M1 | M | none (M0 exit criteria only) |
| [US-057](../user-stories/US-057-living-docs-code-link.md) | Living docs / code link | WS-G | M2 | M | US-056 |
| [US-058](../user-stories/US-058-adr-tracking.md) | ADR tracking | WS-G | M2 | S | US-056 |
| [US-059](../user-stories/US-059-runbook-management.md) | Runbook management | WS-G | M3 | M | US-056 |
| [US-060](../user-stories/US-060-stale-doc-detection.md) | Stale doc agent | WS-G | M2 | M | US-056 |
| [US-061](../user-stories/US-061-auto-changelog.md) | Auto changelog from commits | WS-G | M3 | M | US-044; consumes shared changelog service (Flag 2) |
| [US-062](../user-stories/US-062-knowledge-base-search.md) | Knowledge base search | WS-G | M3 | L | US-056 (pgvector/full-text) |
| [US-063](../user-stories/US-063-doc-templates.md) | Doc templates | WS-G | M2 | S | US-056 |
| [US-064](../user-stories/US-064-reusable-checklists.md) | Reusable checklists | WS-H | M1 | M | none (M0 exit criteria only) |
| [US-065](../user-stories/US-065-checklist-enforcement.md) | Checklist enforcement | WS-H | M2 | S | US-064 |
| [US-066](../user-stories/US-066-agent-generated-checklists.md) | Agent-generated checklists | WS-H | M2 | M | US-064 |
| [US-067](../user-stories/US-067-template-library.md) | Unified template library | WS-H | M3 | M | US-030, US-063 contracts |
| [US-068](../user-stories/US-068-pre-deploy-checklist.md) | Pre-deploy checklist | WS-H | M3 | S | WS-E contract (US-041/US-042) |
| [US-069](../user-stories/US-069-okr-hierarchy.md) | OKR hierarchy | WS-I | M1 | L | none (M0 exit criteria only); extends existing okrs schema |
| [US-070](../user-stories/US-070-auto-progress-krs.md) | Auto-progress KRs | WS-I | M2 | M | US-069 |
| [US-071](../user-stories/US-071-okr-checkin-agent.md) | OKR check-in agent | WS-I | M3 | M | US-069 |
| [US-072](../user-stories/US-072-goal-alignment-viz.md) | Goal alignment viz | WS-I | M2 | M | US-069 |
| [US-073](../user-stories/US-073-okr-scoring.md) | OKR scoring | WS-I | M3 | M | US-069, US-070 |
| [US-074](../user-stories/US-074-personal-alongside-team-okrs.md) | Personal OKRs visibility layer | WS-I | M3 | M | US-013; merged delivery (Flag 1) |
| [US-075](../user-stories/US-075-goal-retrospective.md) | AI goal retrospective | WS-I | M4 | M | US-073 |
| [US-076](../user-stories/US-076-agent-team-dashboard.md) | Agent team dashboard | WS-J | M1 | M | none (M0 exit criteria only) |
| [US-077](../user-stories/US-077-agent-roles-permissions.md) | Agent roles/permissions | WS-J | M2 | L | US-076; gates M3 (US-047, US-092) |
| [US-078](../user-stories/US-078-agent-audit-log.md) | Agent audit log | WS-J | M3 | M | US-076 |
| [US-079](../user-stories/US-079-agent-task-queue.md) | Agent task queue | WS-J | M2 | M | US-076 |
| [US-080](../user-stories/US-080-agent-performance-metrics.md) | Agent performance metrics | WS-J | M3 | M | US-076 |
| [US-081](../user-stories/US-081-pause-resume-agents.md) | Pause/resume agents | WS-J | M2 | S | US-076 |
| [US-082](../user-stories/US-082-agent-notification-prefs.md) | Agent notification prefs | WS-J | M2 | S | US-076 |
| [US-083](../user-stories/US-083-custom-agent-creation.md) | Custom agent creation | WS-J | M3 | L | US-076, US-077 |
| [US-084](../user-stories/US-084-agent-collaboration.md) | Agent collaboration protocols | WS-J | M4 | L | US-076, US-077 |
| [US-085](../user-stories/US-085-agent-cost-tracking.md) | Agent cost tracking | WS-J | M4 | M | US-076 |
| [US-086](../user-stories/US-086-prompt-versioning.md) | Prompt versioning | WS-K | M1 | M | none (M0 exit criteria only) |
| [US-087](../user-stories/US-087-browse-prompt-history.md) | Browse prompt history | WS-K | M2 | S | US-086 |
| [US-088](../user-stories/US-088-tag-categorize-prompts.md) | Tag/categorize prompts | WS-K | M2 | S | US-086 |
| [US-089](../user-stories/US-089-compare-prompt-versions.md) | Compare prompt versions | WS-K | M3 | S | US-087 |
| [US-090](../user-stories/US-090-restore-prompt-version.md) | Restore prompt version | WS-K | M2 | S | US-086, US-087 |
| [US-091](../user-stories/US-091-prompt-template-library.md) | Prompt template library | WS-K | M4 | M | US-067 ✓M3 |
| [US-092](../user-stories/US-092-prompt-sharing.md) | Prompt sharing | WS-K | M3 | S | US-077 ✓M2 |
| [US-093](../user-stories/US-093-prompt-effectiveness-annotations.md) | Prompt effectiveness annotations | WS-K | M2 | M | US-086 |
| [US-094](../user-stories/US-094-export-prompt-archives.md) | Export prompt archives | WS-K | M2 | S | US-086 |
| [US-095](../user-stories/US-095-prompt-audit-trail.md) | Prompt compliance audit trail | WS-K | M3 | M | US-078 (soft same-milestone dep, sequence last — Flag 3) |
| [US-096](../user-stories/US-096-rate-agent-output.md) | Rate agent output | WS-K | M2 | M | US-086; WS-J data contract (US-076) |
| [US-097](../user-stories/US-097-automated-eval-rubrics.md) | Automated eval rubrics | WS-K | M3 | L | US-086 |
| [US-098](../user-stories/US-098-eval-dashboard.md) | Eval dashboard | WS-K | M4 | M | US-097 |
| [US-099](../user-stories/US-099-ab-test-prompts.md) | A/B test prompts | WS-K | M4 | M | US-097 |
| [US-100](../user-stories/US-100-eval-feedback-loop.md) | Eval→prompt feedback loop | WS-K | M5 | L | US-097 ✓M4, US-099 ✓M4 (capstone) |

## Migration ID allocation

Existing changelogs: 001–~035 (do not touch). Scheme: milestone number is the
hundreds digit; each lane gets a fixed 5-slot block within the milestone. Unused
slots stay unused.

Block offsets within a milestone (`Mx` ⇒ `x00 + offset`):

| Lane | Offset |
|------|--------|
| WS-A | 00–04 |
| WS-B | 05–09 |
| WS-C | 10–14 |
| WS-D | 15–19 |
| WS-E | 20–24 |
| WS-F | 25–29 |
| WS-G | 30–34 |
| WS-H | 35–39 |
| WS-I | 40–44 |
| WS-J | 45–49 |
| WS-K | 50–54 |
| WS-L | 55–59 |

Example: M1 WS-C migrations are 110–114; M3 WS-K migrations are 350–354. M0
(audit/contracts) uses 090–099, WS-L only. Each lane maintains its own changelog
include file (`db/changelog/lanes/<lane>.yaml` or equivalent); WS-L owns the master
include.

## Flags / decisions

1. **US-013 vs US-074 near-duplicate** — deliver as one merged implementation in M3
   WS-I (US-074 is the visibility layer on top of US-013).
2. **US-044 vs US-061 overlap** — single shared changelog-generation service: WS-E
   builds it in M2 (US-044); US-061 in M3 consumes it and adds the docs-surface.
   Contract note required in both milestone docs.
3. **US-095 soft same-milestone dependency on US-078** (both M3) — sequence US-095
   last in the WS-K lane; if US-078 slips, US-095 slips to M4.
4. **PRD pass required before implementation.** Stories are uniformly product-level
   (identical 5-bullet AC templates); each needs a PRD pass (`npl-prd-editor`
   pipeline) before implementation. Milestone entry criterion: PRDs exist for that
   milestone's stories. PRD authoring for milestone N+1 runs in parallel with
   implementation of milestone N (pipelined).
5. **Persona gap** — Diana Kovacs' JTBD includes time tracking/billing; zero backlog
   coverage. Flagged, not scheduled (see M5 backlog reconciliation).
6. **Cosmetic fix** — `user-stories/index.yaml` header says "12 domains," actually 13.
7. **Sibling project flag** — `projects/tobarnalp.com` is a stale typo-duplicate of
   this project; flagged for a removal decision, out of roadmap scope.
8. **Dependency inference caveat** — dependencies were inferred from story content
   (no dependency field exists in frontmatter). Treat sequencing in this roadmap as
   a strong hypothesis; the PRD pass may adjust it.

## How to use this roadmap

**For human developers:**
1. Pick your lane (WS-A..WS-L) — check the [lane ownership](#lane-ownership) table
   for your owned backend/frontend paths.
2. Work milestone-by-milestone. Don't start a milestone's stories until its entry
   criteria (the prior milestone's relevant exit criteria) are met — check the
   per-milestone doc (`milestone-0N-*.md`).
3. Stay inside owned paths. If a story needs data or behavior from another lane,
   consume it through that lane's published contract (see the per-milestone contract
   tables) — never edit another lane's files directly.
4. Need a shared/hotspot file touched (router, nav shell, deps, master changelog
   include)? File an interface ticket to WS-L rather than editing it yourself.
5. Claim your migration ID block for the milestone you're working in (see
   [Migration ID allocation](#migration-id-allocation)) before writing a changelog.

**For AI agent workers:**
1. Same lane-first rule applies — an agent assigned to a lane operates only within
   that lane's owned paths for the duration of its task.
2. Before implementing a story, confirm a PRD exists for it (Flag 4). If not, that's
   a signal to request/trigger the PRD pass rather than implement against the raw
   user story.
3. Pipeline PRD authoring for milestone N+1 alongside implementation of milestone N
   — don't block one on the other.
4. When a story's task breakdown lists a contract touchpoint, treat the contract as
   the interface boundary: read/write only through it, and if the contract doesn't
   cover what's needed, raise it as a cross-lane ticket instead of reaching into the
   other lane's code.
5. Respect the soft-dependency and merge notes in Flags 1–3 — they affect sequencing
   within a milestone even though the story is technically "in" that milestone.
