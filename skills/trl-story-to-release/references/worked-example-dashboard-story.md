# Worked Example — US-042 Metrics Dashboard, Backlog to Release

One realistic story taken through all six phases. Project: an admin console for a SaaS service, with `project-management/` artifacts generated upstream (trl-user-experience-engineer / `/generate-personas-and-stories` + `/extract-screens`) and a styleguide-engine theme under `design/theme/theme-admin/`.

---

## Input Artifacts (as found in the project)

### The story — `project-management/user-stories/US-042-metrics-dashboard.md`

```markdown
---
id: US-042
title: "Metrics dashboard"
slug: "metrics-dashboard"
personas: [P-003]
epic: "Admin Console"
priority: "must-have"
complexity: "L"
tags: [admin, observability]
---

# US-042: Metrics Dashboard

## User Story
**As a** first-time admin (P-003),
**I want to** see a metrics dashboard when I open the admin console,
**So that** I can tell at a glance whether the service is healthy.

## Acceptance Criteria
- [ ] Given a logged-in admin, when they open /admin, then a dashboard of key metrics renders
- [ ] Dashboard loads fast
- [ ] Given metrics data is unavailable, when the dashboard loads, then an explanatory state is shown

## Notes
Related: US-051 (alert configuration). Should match the new design system.
```

### The persona — `project-management/personas/P-003-dana-first-time-admin.md` (excerpt)

```markdown
---
id: P-003
name: "Dana Okafor"
archetype: "First-Time Admin"
segment: "primary"
---
# Dana Okafor — First-Time Admin

| Field | Value |
|-------|-------|
| **Age** | 29-36 |
| **Role** | Office manager who inherited the admin role |
| **Technical Level** | Novice |
| **Location** | Works on a 1366×768 office laptop |

## Goals
1. Know whether "everything is fine" without asking engineering
2. Handle routine admin tasks without breaking anything

## Frustrations
1. Dashboards that assume operational context she doesn't have
2. Jargon and bare acronyms ("p95", "QPS")
3. Screens that show "No data" with no hint of what to do

## Job to Be Done
> "When I open the admin console, I want an immediate health verdict,
> so I can get back to my actual job or escalate confidently."
```

### The style guide — `design/theme/theme-admin/` (excerpt)

```yaml
# style-guide.vars.yaml
vars:
  groups:
    colors: { primary: "#1a56db", accent: "#0e9f6e", danger: "#e02424", warning: "#c27803" }
    semantics: { radius: "6px", font-family: "Inter, sans-serif" }
# branding.yaml
tone: "plain-spoken, confidence-building; avoid ops jargon on admin surfaces"
# style-guide.color-modes.yaml defines light + dark surface/text/border tokens
```

### The screen — `project-management/screens/07-admin-dashboard.md` (excerpt)

```markdown
# Admin Dashboard
| **ID** | `admin-dashboard` | **Type** | Dashboard | **User Stories** | US-042, US-051 |
## Key Components
- **MetricTile** — single metric with trend (US-042)
- **PageShell** — admin chrome with sidebar nav
```

---

## Phase 1 — Story Intake & Grooming

| Gate | Result | Note |
|------|--------|------|
| R1 Identity | PASS | |
| R2 Persona link | PASS | P-003 exists. Grooming question: should on-call SREs be served too? User linked **P-007 (on-call SRE, expert)** as secondary. |
| R3 Testable criteria | FAIL → fixed | AC-2 "loads fast" → "Given a warm session, when /admin is opened, then metric cards render within 2s on a mid-range laptop" |
| R4 Sized | PASS | L; single screen, no split |
| R5 Unambiguous | FAIL → resolved | See ambiguity log |
| R6 Screen mapping | PASS | `07-admin-dashboard.md` |
| R7 Dependencies | PASS | US-051 is Related, not Depends |

Ambiguity log:

| # | Question | Blocking? | Default proposed | Resolution |
|---|----------|-----------|------------------|------------|
| A1 | Which metrics are "key"? | Yes | active users 24h, error rate, p95 latency, queue depth | Confirmed |
| A2 | Time range? | No | fixed 24h; picker deferred | Accepted |
| A3 | Non-admin hits /admin? | Yes | 403 + sign-in redirect | Confirmed |

**Verdict: READY.** `grooming.md` written.

## Phase 2 — Constraint Binding

Style sources: engine YAML above → binding **FULL**. Checklist (frozen):

| ID | Constraint | Source (rank) | Pass condition |
|----|-----------|---------------|----------------|
| AF-1 | 0 critical/serious axe violations on /admin | Floor (2) | axe scan |
| AF-2 | Contrast ≥4.5:1 both color modes | Floor (2) | measured |
| AF-3 | Keyboard-only walkthrough completes | Floor (2) | manual pass |
| PC-1 | Metric labels plain-English with units; no bare acronyms | P-003 §Frustrations (3) | copy review |
| PC-2 | Unavailable state says what's happening + one next action | P-003 §Frustrations (3) | state review |
| PC-3 | Health verdict above the fold at 1366×768 | P-003 §JTBD (3) | viewport check |
| PC-4 | Raw values + trend accessible for experts | P-007 §Goals (3) | card detail exists |
| SG-1 | Cards via sanctioned `StyleGuideCard`/`MetricTile`; no bespoke card CSS | component inventory (5) | import audit |
| SG-2 | Status colors from tokens (accent/danger/warning); no ad-hoc hex | vars.groups.colors (4) | grep surface |
| SG-3 | Copy tone per branding.yaml | branding.yaml (4) | tone review |

Conflict resolved: PC-1 vs ops convention "p95" → label "Slowest responses (p95), ms" — persona rank wins, term kept but explained.

## Phase 3 — Implementation Planning

| Criterion | Screen | Components | API/data |
|-----------|--------|------------|----------|
| AC-1 | `07-admin-dashboard` | reuse `PageShell`, `StyleGuideCard`; **extend** `MetricTile` (`unit`, `trend`) | **new** `GET /api/admin/metrics/summary` (24h, 30s cache) |
| AC-2 | same | reuse `SkeletonCard` | single batched endpoint |
| AC-3 | same | **extend** `EmptyState` (action slot); per-card unavailable variant | 5xx + partial-null contract |
| (A3) | `403` route | reuse error page | authz middleware |

Task sequence: endpoint + contract test → `MetricTile` extension → assembly → states (loading/empty/partial/denied) → copy pass (SG-3). User confirmed (L story).

## Phase 4 — Persona-Conscious Implementation (checkpoint log)

| Criterion | Persona | Friction / action | Constraints ticked | Deviations |
|-----------|---------|-------------------|--------------------|------------|
| AC-1 | P-003 | "P95 LATENCY" label would stall Dana → relabeled with unit. Added headline verdict line ("All systems normal") so JTBD survives above the fold. | PC-1, PC-3, SG-1, SG-2 | none |
| AC-1 | P-007 | Wanted raw numbers → card click reveals detail w/ sparkline. | PC-4 | none |
| AC-2 | both | Skeletons on load; batched fetch measured 1.4s warm. | — | none |
| AC-3 | P-003 | "No data" reproduces frustration #3 → state: "Metrics are still warming up — data appears within a minute. Check collector status →" | PC-2, SG-3 | Wanted new amber hex for warming state → not in tokens; used `warning` token instead (deviation avoided) |

## Phase 5 — Verification

Persona × criteria matrix (2 personas × 3 criteria = 6 rows):

| Criterion | Persona | Walkthrough result | Style | Edge cases | Verdict |
|-----------|---------|--------------------|-------|-----------|---------|
| AC-1 | P-003 | Verdict read <1s; all labels understood unaided | ✓ | dark mode ✓ | PASS |
| AC-1 | P-007 | Detail density satisfied via card expand | ✓ | — | PASS |
| AC-2 | P-003 | 1.4s warm; skeletons; no layout shift | ✓ | throttled 3G: skeleton holds | PASS |
| AC-2 | P-007 | 1.4s | ✓ | — | PASS |
| AC-3 | P-003 | Warming-up state read and actioned | ✓ | **partial data → 2 blank cards: FAIL** | FAIL → fixed → PASS |
| AC-3 | P-007 | Wanted error detail → collector-status link suffices | ✓ | ✓ | PASS |

Fix: per-card unavailable variant for partial data; only AC-3 rows re-verified.
Style audit: 10/10 constraints met; 0 deviations shipped. Edge battery: axe 0 critical/serious; keyboard pass; 1366×768 fold check ✓; empty/partial/error/denied states ✓. `conformance.md` written; story checkboxes ticked.

## Phase 6 — Release

- **End users (P-003 segment):** "Open the admin console and see service health at a glance — a headline verdict plus four plain-English metric cards for the last 24 hours. If metrics are warming up, the dashboard says so and points you at the collector status."
- **Operators:** new endpoint `GET /api/admin/metrics/summary` (30s cache); flag `admin_metrics_dashboard`; no migrations; rollback = flag off.
- **Developers:** `MetricTile` gains `unit`/`trend` (non-breaking); changelog Added entry (US-042).
- **Rollout:** cohort — internal admin org 48h (primary persona segment first, new hot endpoint), then default ON.
- **Post-release:** P-003 smoke path in prod; watch endpoint p95 <300ms + error rate <0.5% for 72h; rollback trigger error rate >1% for 10 min; follow-up filed: US-042-f1 keyboard shortcut for card detail (P-007 friction).
- **Handoffs:** trl-marketing (announcement), trl-technical-writer (admin-guide page).

---

## Artifact Trail

```
project-management/releases/US-042/
├── grooming.md        # phase 1 verdict + ambiguity log
├── constraints.md     # phase 2 frozen checklist + deviation log
├── plan.md            # phase 3 map + sequence + phase 4 checkpoint log
├── conformance.md     # phase 5 matrix + style audit
└── release-notes.md   # phase 6 notes + rollout + validation
```
