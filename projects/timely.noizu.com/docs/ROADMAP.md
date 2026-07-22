# Timely Roadmap

**Domain:** timely.noizu.com
**Status:** draft
**Last updated:** 2026-07-22

Timely should ship in layers that prove trust before adding scale. The product is valuable because it can reconstruct fragmented work, but that same capability is privacy-sensitive. The roadmap therefore prioritizes local capture, visible consent, fast correction, and auditable evidence before team dashboards, approvals, integrations, or AI labeling.

## Product Thesis

Timely is an evidence-backed activity ledger for interrupt-driven knowledge work. It should make time review faster and more accurate than manual timers without making users feel watched.

## North Star

Reviewed billable hours per active user per week, backed by confidence and evidence controls.

Supporting metrics:

| Metric | Target Direction | Why It Matters |
|--------|------------------|----------------|
| Review completion rate | Up | Users trust and finish their day ledger. |
| Median daily review time | Down | Evidence beats recall only if correction is fast. |
| Unresolved idle gaps | Down | Idle/resume handling is core differentiation. |
| Manual correction rate | Initially high, then lower | Early correction teaches capture quality; long-term reduction proves inference quality. |
| Redaction and pause usage | Measured, not minimized | Privacy controls are healthy trust signals. |
| Exported approved hours | Up | Billing is the strongest willingness-to-pay path. |

## Roadmap Principles

1. Trust before automation.
2. Single-user billing before team oversight.
3. Timeline correction before analytics.
4. Explicit confidence before AI labeling.
5. Local-first capture before cloud-dependent features.

## Phase 0: Product And Design Foundation

**Goal:** Make the concept implementation-ready without building production capture yet.

**Primary users:** P-001 independent consultant, P-004 solo founder, P-005 privacy-conscious designer, P-007 neurodivergent developer.

**Scope:**

| Workstream | Deliverables |
|------------|--------------|
| Product spec | Tight MVP scope, out-of-scope list, pricing hypothesis, alpha acceptance criteria. |
| IA and flows | Validate `design/SITEMAP.md`; define first-run, daily capture, daily review, and billing happy paths. |
| Wireframes | Grayscale wireframes for SCR-01, SCR-03, SCR-04, SCR-05, SCR-07, SCR-08, SCR-14, SCR-17. |
| Design system | Minimal Tech 80%, Editorial 20%; dense operational UI; component states for timeline, confidence, redaction, and idle prompts. |
| Data model | Client, project, task, interval, overlap, screenshot, evidence, idle event, audit event, export. |
| Trust model | Consent copy, capture policy summary, local-only screenshot option, retention defaults, redaction semantics. |

**Exit gate:**

- Daily review path can be explained from screen to screen without missing states.
- Timeline interval states are defined: captured, inferred, manual, private, disputed, approved.
- Screenshot storage and redaction rules are unambiguous.
- MVP explicitly excludes team approvals, integrations, and AI labeling unless needed for alpha learning.

## Phase 1: Private Alpha, Single-User Capture

**Goal:** Prove that Timely can capture enough context for one person to reconstruct a day.

**Target shape:** macOS desktop agent plus web dashboard, used by the founder and a few trusted alpha users.

**Core screens:** SCR-01, SCR-03, SCR-04, SCR-05, SCR-06, SCR-07, SCR-08, SCR-16, SCR-17, SCR-20.

**Must-have stories:** US-001, US-004 through US-007, US-009 through US-034, US-041 through US-049, US-051 through US-056, US-069 through US-075, US-078 through US-081, US-093 through US-100.

**Feature scope:**

| Area | Ship |
|------|------|
| Agent | Install, permission checks, active capture status, pause/resume, crash recovery. |
| Capture | Screenshot interval, app/window/URL metadata where available, local buffering. |
| Tasks | Manual client/project/task setup, task switcher, primary/secondary task classification. |
| Timeline | Daily timeline, screenshot strip, split/merge/reassign intervals, notes, billable state. |
| Idle/resume | Idle detection, return prompt, resume last task suggestion, discard/keep/classify idle time. |
| Privacy | Delete screenshot, blur region, app/domain exclusion rules, retention settings, local-only mode. |
| Accessibility | Keyboard navigation, screen reader labels, reduced motion, high contrast, long task names, localized date/time formats. |

**Do not ship yet:**

- Team utilization.
- Approval workflows.
- Invoice-system integrations.
- AI task labeling.
- Manager-facing surveillance-style dashboards.

**Success criteria:**

- Alpha users can complete first-run setup without support.
- One full workday can be captured and reviewed.
- Daily review takes less than 10 minutes for a normal 6-10 hour workday.
- Users can explain what was captured and how to pause/redact/delete it.
- Exported CSV totals match reviewed timeline intervals.

## Phase 2: Billing Beta

**Goal:** Turn reviewed time into client-ready billing output.

**Primary users:** P-001 independent consultant, P-006 finance and billing admin, P-002 agency operations lead.

**Core screens:** SCR-10, SCR-11, SCR-14, SCR-15, SCR-16, plus mature SCR-05.

**Key stories:** US-057 through US-068, US-079 through US-085.

**Feature scope:**

| Area | Ship |
|------|------|
| Dashboard | Today summary, unresolved review queue, confidence warnings, billable/non-billable totals. |
| Weekly summary | Focus quality, interruption count, idle time, project/client breakdown. |
| Reports | Filter by client/project/date/confidence/evidence; CSV and PDF export. |
| Evidence | Optional screenshot attachment picker with private evidence exclusion. |
| Billing | Rates, billing codes, invoice summary, export history, invoice status. |
| Review controls | Lock reviewed day, reopen approved report, undo timeline edit, bulk edit intervals. |

**Success criteria:**

- A consultant can generate a client-ready weekly report in under 5 minutes after daily review.
- Report confidence warnings are visible before export.
- Private screenshots are excluded by default.
- Export history preserves what was sent, when, and with what evidence level.

## Phase 3: Team And Policy Beta

**Goal:** Support small teams without violating the product's trust promise.

**Primary users:** P-002 agency operations lead, P-003 software team lead, P-008 compliance reviewer, P-005 privacy-conscious designer.

**Core screens:** SCR-02, SCR-12, SCR-13, SCR-17, SCR-18.

**Key stories:** US-002, US-003, US-067, US-074 through US-077, US-082, US-083.

**Feature scope:**

| Area | Ship |
|------|------|
| Consent | Invitation acceptance with capture policy summary before joining. |
| Team policies | Team-level screenshot intervals, retention, local-only constraints, exclusion defaults. |
| Roles | Role matrix for owner, manager, member, finance, compliance. |
| Approvals | Timesheet approval queue, dispute/reopen path, audit log. |
| Team analytics | Privacy-aware utilization and project burn, with no raw screenshot browsing by default. |
| Compliance | Audit log for policy changes, redactions, deletions, approvals, exports. |

**Success criteria:**

- Invited members understand what managers can and cannot see before accepting.
- Managers can approve time without needing raw surveillance evidence.
- Audit trail answers who changed policy, visibility, approvals, exports, and redactions.
- Team analytics are useful at aggregate level while preserving individual privacy defaults.

## Phase 4: Integrations And Assisted Classification

**Goal:** Reduce manual correction by importing external context, while keeping users in control.

**Primary users:** P-001, P-002, P-003, P-004.

**Core screens:** SCR-19, SCR-08, SCR-05, SCR-14.

**Key stories:** US-086 through US-092, US-060.

**Feature scope:**

| Area | Ship |
|------|------|
| Calendar | Meeting classification and planned-vs-actual comparison. |
| GitHub | Pull request, commit, issue, and review context hints. |
| Jira/Linear | Issue/task mapping, billing code suggestions, project sync. |
| Slack | Interruption and incident context, with strict channel exclusions. |
| API/webhooks | Export events, report events, interval updates. |
| MCP | Time context query and task annotation surface for agents. |
| Assisted labeling | Suggested task/project labels with confidence explanation and one-keystroke correction. |

**Success criteria:**

- Suggested labels are clearly marked as inferred.
- Users can accept, edit, or reject suggestions without losing keyboard flow.
- Integrations improve review speed without silently changing approved time.
- Sync conflicts are visible and recoverable.

## Phase 5: Platform Hardening

**Goal:** Make Timely reliable enough for paid production teams.

**Scope:**

| Area | Ship |
|------|------|
| Reliability | Agent crash diagnostics, offline replay, duplicate event suppression, sync conflict resolution. |
| Security | Encryption at rest, screenshot access controls, signed exports, least-privilege integration scopes. |
| Administration | Workspace lifecycle, deletion requests, retention enforcement, billing plans. |
| Scale | Large timeline performance, screenshot storage tiering, background report generation. |
| Observability | Capture health, sync health, export job health, policy enforcement metrics. |

**Success criteria:**

- No data loss across sleep, offline periods, app restarts, or agent upgrades.
- Large daily timelines remain responsive with hundreds of intervals and screenshots.
- Retention and deletion policies are enforceable and auditable.
- Paid teams can self-serve setup, billing, export, and policy management.

## Suggested Release Order

| Release | Name | Outcome |
|---------|------|---------|
| R0 | Design-ready concept | Approved brief, roadmap, wireframes, data model, trust model. |
| R1 | Local capture alpha | Single user captures screenshots/context and sees agent health. |
| R2 | Reviewable day | Daily timeline supports idle/resume, split/merge, redaction, and confidence. |
| R3 | Billable week | Weekly reports, CSV/PDF exports, rates, and export history. |
| R4 | Small team beta | Invitations, consent, roles, approvals, audit trail, team policies. |
| R5 | Context-aware beta | Calendar/GitHub/issue tracker integrations and assisted labels. |
| R6 | Paid production | Security, reliability, retention enforcement, plans, and support surfaces. |

## Design Backlog By Priority

| Priority | Work |
|----------|------|
| P0 | TimelineCanvas interaction model, interval states, screenshot redaction flow, idle/resume prompt, capture policy summary. |
| P1 | Report builder, billing totals, export history, weekly summary, keyboard correction flow. |
| P2 | Team invitation consent, approvals, role matrix, audit log, team utilization. |
| P3 | Integrations hub, sync conflict resolver, assisted task labeling, MCP/API docs. |

## Implementation Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Capture feels invasive | Users churn before seeing value | Make pause, redaction, retention, and visibility explicit from first run. |
| Timeline is too dense | Review becomes slower than manual timers | Keyboard-first interactions, confidence filters, and progressive detail drawers. |
| Overlap model confuses billing | Reports lose credibility | Separate elapsed time, weighted time, billable time, and evidence coverage. |
| Screenshots create liability | Teams avoid adoption | Local-only option, retention defaults, exclusion rules, deletion audit events. |
| AI labels overreach | Users stop trusting reports | Treat AI as suggestions only; require visible confidence and audit trail. |
| Desktop agent instability | Core value fails | Ship agent health, offline buffer, crash recovery, and sync diagnostics early. |

## Next Actions

1. Produce grayscale wireframes for SCR-03, SCR-04, SCR-05, SCR-07, SCR-08, SCR-14, and SCR-17.
2. Define the interval/evidence/audit data model before implementation.
3. Create the styleguide engine YAML theme for Minimal Tech 80%, Editorial 20%.
4. Prototype `TimelineCanvas` keyboard correction with synthetic day data.
5. Validate the first-run privacy and consent copy with 3-5 target users before alpha.
