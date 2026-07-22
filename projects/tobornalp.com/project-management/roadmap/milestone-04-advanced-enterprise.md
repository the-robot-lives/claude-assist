---
title: "Milestone 4 — Advanced, Portfolio & Enterprise"
milestone: M4
status: draft
generated: 2026-07-16
---

# M4 — Advanced, Portfolio & Enterprise

13 stories, 6 active lanes (WS-C, WS-D, WS-F, WS-I, WS-J, WS-K). WS-A/B/E/G/H/L are idle
this milestone — fold their freed workers into the active six rather than inventing new
scope. Closes out the business/enterprise persona journeys: James Oduya (agency owner) and
Lin Zhao (AI-forward platform engineer).

## Entry Criteria

- M3 exit criteria met: AI-assist features live in every major epic; genai usage/cost
  instrumentation in place from M3's agent invocations.
- WS-J's audit-emit contract (US-078 ✓M3) is stable — several M4 stories (US-031, US-054,
  US-084) depend on it for governance trails.
- US-095 resolved one way or the other per its Flag 3 slip rule — if it slipped from M3, it
  re-enters WS-K's M4 lane ahead of this milestone's own K stories.
- PRDs exist for all 13 M4 stories (Flag 4, pipelined against M3 implementation).

## Exit Criteria

- Business/enterprise persona journeys (James Oduya, Lin Zhao) complete end-to-end.
- Agent cost tracking (US-085) live — closes the instrumentation gap M3 left open for
  US-080's ROI calc.
- Cross-project dependency governance (US-031) and multi-agent protocol execution (US-084)
  both produce auditable traces via WS-J's log.

---

## WS-C — Projects & Delivery

### US-027 — Agent-generated sprint retrospective analysis
- Persona(s): Sarah Kim
- Size: M
- Deps: US-022 ✓M2 (kanban); US-023 ✓M3 (sprint planning — shares velocity/estimation data); agent runtime contract ✓M0
- Story: [../user-stories/US-027-sprint-retro-agent.md](../user-stories/US-027-sprint-retro-agent.md)

Tasks:
- Schema/migration `410`: `project_sprint_retro` (velocity trend, blocker patterns, workload-imbalance findings, annotations, carried-forward action items)
- Backend: `RetroAgent` computing 3-5 sprint trend windows, pattern detection (recurring blockers, estimation accuracy, human/agent workload skew); auto-generate on sprint close
- Frontend: editable retro report + annotation + cross-sprint action-item tracking under `app/app/[orgId]/projects/**`
- Tests: pattern-detection unit test (recurring-blocker threshold); Cypress annotate→carry-action-item-to-next-sprint flow
- Contract: none — fully in-lane, reads only WS-C-owned sprint/kanban data

### US-029 — Gantt view with milestone tracking for client projects
- Persona(s): James Oduya
- Size: L
- Deps: US-021 ✓M1 (methodology base); US-026 ✓M2 (per-project methodology)
- Story: [../user-stories/US-029-gantt-view-clients.md](../user-stories/US-029-gantt-view-clients.md)

Tasks:
- Schema/migration `411`: `project_gantt_milestone` (deliverable link, status: upcoming/at-risk/completed/missed, auto-status rule)
- Backend: dependency-aware date recalculation on drag; critical-path computation
- Frontend: Gantt chart (bars, connector lines, milestone diamonds, critical-path highlight) + PDF/image export under `app/app/[orgId]/projects/**`
- Tests: dependency-recalculation-with-conflict-highlight unit test; Cypress drag-adjust→critical-path-updates flow
- Contract: exports feed US-032's client report (same lane, same milestone — in-lane data reuse, no cross-lane contract)

### US-031 — Cross-project dependency tracking
- Persona(s): James Oduya, Lin Zhao
- Size: M
- Deps: US-025 ✓M2 (portfolio dashboard — health-indicator target); US-078 ✓M3 (audit log — governance trail requirement)
- Story: [../user-stories/US-031-cross-project-dependencies.md](../user-stories/US-031-cross-project-dependencies.md)

Tasks:
- Schema/migration `412`: `cross_project_dependency` (blocks/blocked-by, target-owner confirmation state, circular-dependency guard)
- Backend: cross-project graph API with cycle detection at creation; owner-confirmation gate; impact notification on blocking-item status change
- Frontend: dependency-radar graph view (scoped to current user's projects) under `app/app/[orgId]/projects/**`
- Tests: circular-dependency-rejected unit test; Cypress creation-requires-target-owner-confirmation flow
- Contract: writes into WS-J's audit log (US-078) for every dependency create/resolve; updates WS-C's own portfolio dashboard (US-025) risk indicator (in-lane); dependent-owner notifications route through WS-L's notification service

### US-032 — Auto-generate client-facing project status reports
- Persona(s): James Oduya
- Size: M
- Deps: US-029 (same lane, same milestone — Gantt visuals feed the report); agent runtime contract ✓M0
- Story: [../user-stories/US-032-client-facing-reports.md](../user-stories/US-032-client-facing-reports.md)

Tasks:
- Schema/migration `413`: `client_status_report` (per-client template config, draft/approved state, period-over-period diff)
- Backend: `ReportAgent` drafting exec summary/milestones/risks in client-appropriate language; PDF export, email, client-portal publish
- Frontend: draft review/edit/approve workflow + per-client template customization under `app/app/[orgId]/projects/**`
- Tests: jargon-free-language unit test (no raw ticket IDs in output); Cypress draft→approve→publish-to-portal flow
- Contract: consumes US-029's Gantt export for visual timeline inclusion (in-lane)

---

## WS-D — Bugs & Quality

### US-039 — Bug-to-deploy lifecycle tracking
- Persona(s): Maya Chen
- Size: L
- Deps: US-033 ✓M2 (bug capture); WS-E deploy/pipeline webhook contract (US-041 ✓M1, US-042 ✓M2, US-044 ✓M2)
- Story: [../user-stories/US-039-bug-to-deploy-pipeline.md](../user-stories/US-039-bug-to-deploy-pipeline.md)

Tasks:
- Schema/migration `415`: `bug_lifecycle_stage` (Reported→Triaged→In Progress→Fix Ready→In Review→Merged→Deployed→Verified) + `bug_lifecycle_event`
- Backend: branch/PR-link auto-detection (git/MCP integration); deploy-stage detection via WS-E webhook match on commit/PR; explicit verify-in-production confirmation gate
- Frontend: lifecycle pipeline visualization + cycle-time timeline on bug detail under `app/app/[orgId]/bugs/**`
- Tests: stale-stage-alert unit test; Cypress webhook-triggers-stage-transition flow
- Contract: **consumes WS-E's deploy/pipeline webhook contract** (US-041/US-042/US-044) to auto-detect the Deployed stage — subscribe only, no edit into `domains/cicd`

### US-040 — Customer bug intake via external form
- Persona(s): James Oduya
- Size: M
- Deps: US-037 ✓M3 (duplicate detection); US-034 ✓M3 (auto-triage, with client SLA context); WS-L router (public route registration)
- Story: [../user-stories/US-040-customer-bug-intake.md](../user-stories/US-040-customer-bug-intake.md)

Tasks:
- Schema/migration `416`: `bug_intake_form_config` (per-project/client branding, public token) + `customer-reported` bug tag/attribution
- Backend: unauthenticated public submission endpoint with rate-limiting/spam prevention; auto-route to project + run through US-037 duplicate check and US-034 triage
- Frontend: embeddable branded intake form + minimal public status page (stage + ETA only, no internal detail)
- Tests: dedup-before-create unit test; Cypress public-submit→confirmation-email→status-page-lookup flow
- Contract: **public route requires an interface ticket to WS-L** (router.ex is a single-owner hotspot file, Convention 4) — WS-D implements the handler, WS-L wires the route; reuses WS-D's own US-037/US-034 in-lane

---

## WS-F — Monitoring & Incidents

### US-054 — AI-powered anomaly correlation across services
- Persona(s): Lin Zhao
- Size: L
- Deps: US-049 ✓M2 (alert-to-incident); US-051 ✓M3 (incident timeline — reasoning/evidence pattern reused); US-078 ✓M3 (audit trail for correlation reasoning)
- Story: [../user-stories/US-054-anomaly-correlation.md](../user-stories/US-054-anomaly-correlation.md)

Tasks:
- Schema/migration `425`: `anomaly_correlation_cluster` (member anomalies, confidence score, hypothesized root cause, service-topology edges used)
- Backend: statistical anomaly detection (configurable baselines) per service; correlation engine (temporal proximity + service-dependency topology); prior-resolution matching on repeat patterns
- Frontend: correlation-cluster view (confidence score, reasoning trail) + one-click promote-to-incident under `app/app/[orgId]/monitoring/**`
- Tests: false-positive-rate tracking test (quality metric, not just functional); Cypress cluster-detected→promote-to-incident-prepopulated flow
- Contract: every correlation writes its reasoning evidence into WS-J's audit log (US-078) — no black-box "these are related" without a logged trail; promote-to-incident reuses WS-F's own US-049 creation API (in-lane)

---

## WS-I — Goals & OKRs

### US-075 — AI-generated goal retrospective with pattern recommendations
- Persona(s): Lin Zhao
- Size: M
- Deps: US-073 ✓M3 (OKR scoring); merged US-013/074 ✓M3 (personal+team OKR model); US-085 (WS-J, same milestone, in-flight — ROI section)
- Story: [../user-stories/US-075-goal-retrospective.md](../user-stories/US-075-goal-retrospective.md)

Tasks:
- Schema/migration `440`: `goal_retrospective` (achievements/misses/root-causes/patterns, evidence citations, agent-cost-and-contribution section)
- Backend: `RetroAgent` producing quantitative analysis (score distribution, velocity trend, blocker frequency) with cited evidence per finding
- Frontend: retrospective document (living, annotatable) under `app/app/[orgId]/goals/**`
- Tests: evidence-citation-required unit test (every finding must reference a specific item/event); Cypress annotate-and-discuss flow
- Contract: **soft-consumes WS-J's US-085 cost data (same milestone, in-flight)** for the ROI-awareness section — degrade to "cost data pending" if US-085 has not landed yet in-lane at WS-I's entry point, do not block the retrospective on it

---

## WS-J — Agent Platform & Governance

### US-084 — Define collaboration protocols between agents
- Persona(s): Lin Zhao
- Size: L
- Deps: US-076 ✓M1 (agent registry); US-077 ✓M2 (roles/permissions); US-078 ✓M3 (audit log — protocol execution trace); WS-K eval domain (US-097 ✓M3, for protocol performance measurement)
- Story: [../user-stories/US-084-agent-collaboration.md](../user-stories/US-084-agent-collaboration.md)

Tasks:
- Schema/migration `445`: `agent_protocol` (versioned, declarative handoff graph) + `agent_protocol_step` (trigger, data passed, timeout, fallback) + `agent_protocol_execution_trace`
- Backend: visual-protocol-builder backend (declarative graph, not imperative code); conditional escalation routing; dead-letter handling for crashed mid-protocol agents
- Frontend: protocol builder (handoff chain, escalation rules) + execution trace viewer under `app/app/[orgId]/agents/**`
- Tests: dead-letter-no-silent-drop unit test; Cypress build-protocol→A/B-clone→compare flow
- Contract: every protocol execution step writes to WS-J's own US-078 audit log (in-lane); protocol performance measurement reads WS-K's eval-score contract (US-097 ✓M3) — read-only cross-lane consumption

### US-085 — Track per-agent compute and API costs
- Persona(s): Maya Chen, Diana Kovacs
- Size: M
- Deps: agent runtime cost/token accounting hook (extends M0 contract); US-080 ✓M3 (performance metrics — cost dimension was partial, this closes the gap)
- Story: [../user-stories/US-085-agent-cost-tracking.md](../user-stories/US-085-agent-cost-tracking.md)

Tasks:
- Schema/migration `446`: `agent_cost_ledger` (per-call token/compute/API cost, client/project tag) + `agent_budget_cap` (warn/pause/hard-stop action)
- Backend: cost-metering hook into the agent runtime (graceful degradation to token-count-and-estimate when exact provider cost is unavailable); budget-threshold alerting (50/80/100%)
- Frontend: real-time per-agent cost counter + spend-trend dashboard (filter by agent/project/client) under `app/app/[orgId]/agents/**`
- Tests: graceful-degradation unit test (no exact cost available → estimate shown, not blank); Cypress budget-threshold-alert flow
- Contract: **feeds WS-J's own US-080 (M3) ROI calc** (in-lane, closes the M3 gap) and is **soft-consumed by WS-I's US-075** (same milestone) for retrospective ROI sections; client/project cost tagging is the input WS-C would need for future billing (explicitly out of scope — see Diana Kovacs backlog-reconciliation note in M5)

---

## WS-K — Prompts & Evaluation

### US-091 — Maintain a shared prompt template library
- Persona(s): James Oduya
- Size: M
- Deps: US-067 ✓M3 (WS-H's unified template library — fork-and-track UX pattern precedent); US-086 ✓M1 (prompt versioning); US-077 ✓M2 (library-level access controls)
- Story: [../user-stories/US-091-prompt-template-library.md](../user-stories/US-091-prompt-template-library.md)

Tasks:
- Schema/migration `450`: `prompt_template` (category, base prompt, recommended tool permissions, default constraints) + `prompt_template_fork` (link to base, selective-pull state)
- Backend: fork-and-track model (package-manager-style: base templates upstream, project instances pinned with local patches); cherry-pick-update propagation; starter template seed set
- Frontend: category-organized template library + fork/upstream-update UI under `app/app/[orgId]/prompts/**`
- Tests: selective-cherry-pick-not-forced-update unit test; Cypress fork→customize→pull-selective-upstream-change flow
- Contract: reuses WS-H's US-067 fork/parameterization UX pattern as design precedent (interface ticket if shared UI components from `components/generated/**` are reused) and WS-J's US-077 permission model for library-level access scoping (agency-wide/team-private/client-specific)

### US-098 — View eval dashboard with quality trend charts
- Persona(s): Sarah Kim
- Size: M
- Deps: US-096 ✓M2 (human ratings); US-097 ✓M3 (automated rubric scores); US-089 ✓M3 (prompt comparison — regression detection links back to it)
- Story: [../user-stories/US-098-eval-dashboard.md](../user-stories/US-098-eval-dashboard.md)

Tasks:
- Schema/migration `451`: `eval_dashboard_snapshot` (aggregate score time-series, daily/weekly/monthly rollup, confidence-interval for sparse data)
- Backend: score aggregation (human ratings + rubric scores) with role/agent/task-type/project/version grouping; regression-detection correlating score drops to prompt/config-change timestamps
- Frontend: trend charts + per-agent summary cards ("team health" rollup) under `app/app/[orgId]/evals/**`, `<3s` load for 10-agent/10k-task scale
- Tests: regression-detection-correlates-to-prompt-change unit test; perf test at 10-agent/10k-task scale
- Contract: none — fully in-lane, reads only WS-K-owned prompt/eval tables

### US-099 — A/B test agent prompt variants
- Persona(s): Lin Zhao
- Size: L
- Deps: US-086 ✓M1 (prompt versioning); US-097 ✓M3 (eval scoring pipeline — statistical comparison source)
- Story: [../user-stories/US-099-ab-test-prompts.md](../user-stories/US-099-ab-test-prompts.md)

Tasks:
- Schema/migration `452`: `prompt_ab_test` (variant pair, traffic split, deterministic seed) + `prompt_ab_test_result` (score comparison, significance indicator)
- Backend: deterministic randomized traffic assignment (never mid-task variant switch); real-time significance calc (p-value or equivalent); early-stop-on-significance / manual-stop-inconclusive
- Frontend: test setup + live comparison dashboard (confidence intervals, significance indicator) under `app/app/[orgId]/evals/**`
- Tests: deterministic-seed-reproducibility unit test; small-sample-size-warning unit test
- Contract: test results link permanently into WS-K's own prompt-archival timeline (US-086, in-lane) — no cross-lane write

---

## Cross-lane contracts agreed at milestone start

| Producer lane | Consumer lane(s) | Contract | Purpose |
|---|---|---|---|
| WS-E | WS-D | Deploy/pipeline webhook contract (US-041/US-042/US-044) | US-039 auto-detects the Deployed lifecycle stage |
| WS-L | WS-D | Public unauthenticated route registration (interface ticket) | US-040 customer intake form and status page |
| WS-J | WS-C | Audit-log contract (US-078 ✓M3) | Governance trail for cross-project dependency creation/resolution (US-031) |
| WS-L | WS-C | Notification service | Dependent-owner alerts when a blocking item changes (US-031) |
| WS-J | WS-F | Audit-log contract (US-078 ✓M3) | Reasoning/evidence trail for anomaly-correlation clusters (US-054) |
| WS-K | WS-J | Eval-score contract (US-097 ✓M3) | End-to-end protocol performance measurement (US-084) |
| WS-J | WS-I | Agent cost-tracking data (US-085, same milestone, in-flight) | ROI section of goal retrospective (US-075) — soft dependency, degrades gracefully |
| WS-H | WS-K | Template-library fork/parameterization UX pattern (US-067 ✓M3) | Design precedent for prompt template library (US-091) |
