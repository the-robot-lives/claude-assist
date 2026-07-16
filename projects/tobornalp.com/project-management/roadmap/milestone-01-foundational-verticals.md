---
title: "Milestone 1 — Foundational Verticals"
milestone: 1
status: draft
generated: 2026-07-16
---

## Goal

Every active lane lands its core entity + CRUD API + basic UI. 10 stories, 10 lanes in
parallel, all dependency-free. This is the vertical slice that proves the scale-free item
model end-to-end in each domain before M2 fans out into single-lane extensions.

## Entry Criteria

- M0 exit criteria met: platform contracts published, FE app shell (`/app/[orgId]`) merged,
  audit matrix published mapping existing 241 backend files + changelogs 001–035 to stories,
  lane ownership + migration allocation ratified, core Item polymorphism decision made,
  `components/ui/**` base set generated from styleguide primitives.
- PRD pass complete for all 10 M1 stories (Flag 4).

## Exit Criteria

- Each vertical is demo-able end-to-end (create/read/update via UI) in its owned routes.
- Cross-lane read contracts published: today-view read models (A/C/F/J → L), agent assignee
  reference (J → C), incident refs (F → D). See contract table below.
- WS-L nav entries for all new route segments merged; notification plumbing live.

---

## WS-A — Personal Items & Habits

### US-011 — Personal todo with due date, tags, and recurrence
- Persona(s): Raj Patel
- Size: M
- Dependencies: none
- Story: [../user-stories/US-011-personal-todo-due-date.md](../user-stories/US-011-personal-todo-due-date.md)

Tasks:
1. Schema/migration `100`: base `items` table (scale-free entity: type, title, due_date, tags[], context) + `101` recurrence rules (frequency, cron-like expr, next-occurrence link).
2. Backend: `domains/personal` context — CRUD API, recurrence engine with timezone-aware next-occurrence generation on completion.
3. Frontend: `app/app/[orgId]/personal/**` list + item form; `components/personal/**` due-date picker (NL parsing) and tag input.
4. Tests: unit coverage for recurrence date math across timezones; Cypress happy-path create/complete/recur flow with `data-cy` on item card and due-date badge.
5. Contract touchpoint: expose personal-items read model for WS-L's today-view aggregation (consumed by US-001 in M2).

---

## WS-B — Inbox & Capture

### US-006 — Quick-capture from any screen via keyboard shortcut
- Persona(s): Raj Patel
- Size: S
- Dependencies: none
- Story: [../user-stories/US-006-quick-capture-anywhere.md](../user-stories/US-006-quick-capture-anywhere.md)

Tasks:
1. Schema/migration `105`: `inbox_items` table (raw text, parsed metadata, source, triage status).
2. Backend: `domains/inbox` context — capture endpoint with inline-metadata parser (`#tag`, `@project`, `/date`).
3. Frontend: global `Cmd+K` modal overlay (WS-L shell hook for keybinding registration) + `components/capture/**` modal, sub-300ms submit-to-dismiss.
4. Tests: unit tests for metadata parser edge cases; Cypress test asserting focus-return timing and multi-line Shift+Enter input.
5. Contract touchpoint: inbox item shape is the base capture contract WS-B extends in M2 (mobile, email, voice all write through this same endpoint).

---

## WS-C — Projects & Delivery

### US-021 — Create a project with a chosen methodology
- Persona(s): Sarah Kim
- Size: L
- Dependencies: none
- Story: [../user-stories/US-021-create-project-methodology.md](../user-stories/US-021-create-project-methodology.md)

Tasks:
1. Schema/migration `110`: `projects` table (methodology enum, config); `111`: `workflow_states` table (per-project states/transitions, auto-provisioned per methodology).
2. Backend: `domains/projects` context — creation wizard API, methodology provisioning service (Scrum/Kanban/Waterfall/Custom presets), methodology-change migration prompt for in-flight items.
3. Frontend: `app/app/[orgId]/projects/**` creation wizard; `components/pm/**` methodology preview cards.
4. Tests: unit tests per methodology preset provisioning; Cypress wizard flow covering all 4 methodology options and the later-change prompt.
5. Contract touchpoint: publish project read model (id, name, methodology, workflow_states) for WS-L today-view and for WS-D's M2 bug-capture base.

---

## WS-D — Bugs & Quality (idle)

No story assigned in M1 — bug capture depends on the items/projects base landing first.
Staff WS-D workers into other lanes or into M0 audit follow-ups for this milestone. WS-D
resumes in M2 with US-033 and US-036, consuming the item/project contracts published here.

---

## WS-E — CI/CD & Deploy

### US-041 — View CI/CD pipeline status per project
- Persona(s): Maya Chen
- Size: M
- Dependencies: none
- Story: [../user-stories/US-041-pipeline-status-view.md](../user-stories/US-041-pipeline-status-view.md)

Tasks:
1. Schema/migration `120`: `pipelines` + `pipeline_runs` tables (status, stage breakdown, durations, provider adapter source).
2. Backend: `domains/cicd` context — provider adapter interface (GitHub Actions, GitLab CI) via MCP integration layer, WebSocket/polling status feed.
3. Frontend: `app/app/[orgId]/pipelines/**` summary view + stage drill-down; `components/cicd/**` status badges (WCAG AA contrast in dark mode).
4. Tests: unit tests for adapter status normalization; Cypress test for `g p` keyboard nav and live status update via mocked WS feed.
5. Contract touchpoint: failed-pipeline items surfaced to WS-L today-view as actionable entries.

---

## WS-F — Monitoring & Incidents

### US-048 — View uptime monitoring dashboard with response time graphs
- Persona(s): Maya Chen
- Size: M
- Dependencies: none
- Story: [../user-stories/US-048-uptime-dashboard.md](../user-stories/US-048-uptime-dashboard.md)

Tasks:
1. Schema/migration `125`: `monitored_endpoints` table; `126`: `uptime_checks` table (downsampled response-time series, p50/p95/p99).
2. Backend: `domains/monitoring` context — provider adapters (UptimeRobot, Pingdom) + built-in synthetic monitor, downsampling for 90d ranges.
3. Frontend: `app/app/[orgId]/monitoring/**` dashboard with keyboard-navigable endpoint list; `components/monitoring/**` latency graphs and downtime timeline bar.
4. Tests: unit tests for downsampling correctness; Cypress arrow-key/Enter/Escape navigation test.
5. Contract touchpoint: publish endpoint/incident-ref read model — consumed by WS-D in M3 (US-035 bug↔incident link) and by WS-L today-view.

---

## WS-G — Docs & Knowledge

### US-056 — Create structured wiki with hierarchy and version history
- Persona(s): Sarah Kim
- Size: M
- Dependencies: none
- Story: [../user-stories/US-056-structured-wiki.md](../user-stories/US-056-structured-wiki.md)

Tasks:
1. Schema/migration `130`: `wiki_pages` table (hierarchy via parent_id, permissions scope); `131`: `wiki_page_versions` table (diff, author, edit summary).
2. Backend: `domains/docs` context — `[[page-title]]` and `[[US-041]]` cross-link resolver with autocomplete, full-text search index, per-page/subtree permissions.
3. Frontend: `app/app/[orgId]/wiki/**` sidebar tree nav + Markdown editor with diff view; `components/docs/**` link autocomplete.
4. Tests: unit tests for version restore and permission scoping; Cypress test for create/edit/restore-version flow.
5. Contract touchpoint: wiki page schema underpins WS-G's M2 stories (ADR tracking, doc templates) and WS-H's M3 template-library consumption.

---

## WS-H — Checklists & Templates

### US-064 — Create reusable checklists attachable to any item type
- Persona(s): James Oduya
- Size: M
- Dependencies: none
- Story: [../user-stories/US-064-reusable-checklists.md](../user-stories/US-064-reusable-checklists.md)

Tasks:
1. Schema/migration `135`: `checklist_templates` table; `136`: `checklist_instances` table (independent copy on attach, one-level nested sub-items).
2. Backend: `domains/checklists` context — attach-to-item API, completion-percentage rollup exposed to parent item.
3. Frontend: embedded checklist widget in `components/checklists/**` (no own route yet — attaches into item detail views owned by other lanes via a shared slot contract).
4. Tests: unit tests confirming template-instance independence (editing instance doesn't mutate template); Cypress test for attach + check-off + completion % on parent card.
5. Contract touchpoint: checklist-attach slot is a shared UI contract every item-owning lane (A, C, D, E) integrates against — coordinate via WS-L interface ticket.

---

## WS-I — Goals & OKRs

### US-069 — Multi-level OKR hierarchy with roll-up
- Persona(s): Sarah Kim
- Size: L
- Dependencies: none — extends existing `okrs` schema per M0 audit
- Story: [../user-stories/US-069-okr-hierarchy.md](../user-stories/US-069-okr-hierarchy.md)

Tasks:
1. Schema/migration `140`: alter existing `okrs` tables — add hierarchy_level (org/team/individual), parent_objective_id, rollup_config (weighted/min/custom).
2. Backend: `domains/okrs` context — roll-up calculation service, circular-dependency detection on the OKR graph.
3. Frontend: `app/app/[orgId]/goals/**` tree view + flat filtered list; `components/okr/**` hierarchy visualizer.
4. Tests: unit tests for each roll-up formula and cycle detection; Cypress test for tree/list toggle and roll-up display.
5. Contract touchpoint: KR-to-item linking contract established here feeds WS-I's M2 auto-progress (US-070) and any lane's items that link to a KR.

---

## WS-J — Agent Platform & Governance

### US-076 — Agent team dashboard showing status, task, and health
- Persona(s): Maya Chen
- Size: M
- Dependencies: none — consumes M0's agent runtime contract
- Story: [../user-stories/US-076-agent-team-dashboard.md](../user-stories/US-076-agent-team-dashboard.md)

Tasks:
1. Schema/migration `145`: `agents` table (name, role, status, uptime); `146`: `agent_activity_log` table (health/error-rate/queue-depth source).
2. Backend: `domains/agents` context — status/health aggregation service, real-time push (<5s) via event bus (M0 contract).
3. Frontend: `app/app/[orgId]/agents/**` card grid + detail panel; `components/agents/**` status/health indicators (dark-mode, keyboard nav).
4. Tests: unit tests for health-indicator computation; Cypress test for real-time status update and detail-panel open.
5. Contract touchpoint: publish agent-assignee reference (agent id, name, avatar, capabilities) consumed by WS-C's M2 US-024 and WS-K's M2 US-096.

---

## WS-K — Prompts & Evaluation

### US-086 — Archive agent prompts with automatic versioning
- Persona(s): Lin Zhao
- Size: M
- Dependencies: none — foundational story for the prompt-archival domain
- Story: [../user-stories/US-086-prompt-versioning.md](../user-stories/US-086-prompt-versioning.md)

Tasks:
1. Schema/migration `150`: `prompt_versions` table (content-addressed, monotonic version number, author, timestamp, auto-generated change summary).
2. Backend: `domains/prompts` context — atomic charter versioning (system prompt + tool permissions + constraints as one unit), syntax-aware diff service.
3. Frontend: `app/app/[orgId]/prompts/**` version list + diff view; `components/prompts/**` diff renderer.
4. Tests: unit tests for atomic versioning and diff correctness; Cypress test for edit → new version → diff-view flow.
5. Contract touchpoint: versioning schema is the base every WS-K M2 story (history browsing, tags, restore, annotations, export) builds directly on top of.

---

## WS-L — Platform Shell & Cross-Domain (no story)

WS-L has no user story in M1 but delivers the platform enablement every other lane depends
on:
1. Notification plumbing: base notification service (event → delivery channel routing), consumed by WS-E's M2 US-046 and WS-J's M2 US-082.
2. Nav entries for all 9 new M1 route segments (`personal`, `inbox`, `projects`, `pipelines`, `monitoring`, `wiki`, `goals`, `agents`, `prompts`) in the shared shell — single-owner file, other lanes request via interface ticket.
3. Read-model conventions: define the shape each lane's M1 read model must expose (id, title, priority, source, link) so WS-L's M2 US-001 can aggregate them uniformly.
4. Master liquibase changelog include updated with lane include files for slots 100–150 used above.

---

## Cross-lane contracts agreed at milestone start

| Producer lane(s) | Consumer lane | Contract | Purpose |
|---|---|---|---|
| WS-A, WS-C, WS-F, WS-J | WS-L | Today-view read models (id, title, priority, source, link) | Feeds M2 US-001 unified today dashboard |
| WS-J | WS-C | Agent assignee reference (agent id, name, avatar, capabilities) | Feeds M2 US-024 unified human/agent assignee picker |
| WS-F | WS-D | Incident refs (endpoint/incident id, service, severity) | Enables M3 US-035 bug↔incident link |
| WS-C | WS-D | Project/item base schema | Unblocks WS-D's M2 entry (US-033, US-036), idle in M1 |
| WS-H | WS-A, WS-C, WS-D, WS-E | Checklist-attach UI slot | Shared attach point on any item detail view, coordinated via WS-L |
