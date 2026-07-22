# Story Intake & Grooming

Phase 1 of the story-to-release pipeline: parse the story, audit its acceptance criteria, surface ambiguities, split it if oversized, and gate it through the R1–R7 readiness checklist before any effort is committed.

## Inputs

| Input | Path | Required |
|-------|------|----------|
| Story file | `project-management/user-stories/US-{NNN}-{slug}.md` | Yes |
| Story index | `project-management/user-stories/index.yaml` | Yes (dependency + epic context) |
| Linked personas | `project-management/personas/P-{NNN}-{slug}.md` | Yes — every ID in story frontmatter |
| Screen inventory | `project-management/screens/*.md` | Recommended |

## The Readiness Gate

Use `assets/story-readiness-checklist.md` as the worksheet. A story exits grooming as **READY**, **READY-WITH-WAIVERS** (each waiver logged with rationale), or **NOT-READY** (blocking questions returned to the user).

| # | Gate | Test | Typical failure & fix |
|---|------|------|-----------------------|
| R1 | Identity | ID, title, canonical location | Story is a chat message → route to `/generate-personas-and-stories` conventions first |
| R2 | Persona link | `personas: [...]` non-empty, files exist | Orphan story → ask which persona it serves; never invent one |
| R3 | Testable criteria | Every criterion is Given/When/Then with an observable "then" | "User can see profile" → rewrite: "Given a logged-in user, when they open /profile, then display name, avatar, and bio render" |
| R4 | Sized | S/M/L; XL blocked | XL → split (below) |
| R5 | Unambiguous | No blocking open questions | Undefined term ("recent", "fast") → propose default, confirm |
| R6 | Screen mapping | Touched screens exist in inventory or declared net-new | Missing screen doc → flag net-new in plan; suggest `/extract-screens` rerun |
| R7 | Dependency clear | `Depends on US-XXX` all shipped or out-of-scope | Blocked → re-order or narrow scope so the dependency is stubbed |

## Criterion Classification

Classify every acceptance criterion before gating:

| Class | Definition | Action |
|-------|------------|--------|
| **Testable** | Given/When/Then, observable outcome, bounded | Accept as-is |
| **Vague** | Outcome stated but not observable/bounded ("loads quickly", "easy to find") | Propose a measurable rewrite; original preserved in grooming log |
| **Missing-context** | References undefined states, roles, or data ("admin sees all metrics" — which metrics?) | Ambiguity-log entry; blocking if it changes implementation shape |

## Ambiguity Sweep

Run these probes against the story body and criteria:

| Probe | Question | Blocking when... |
|-------|----------|------------------|
| Undefined terms | Any adjective/noun without a definition? ("recent", "key metrics", "team") | The definition changes data model or API shape |
| Unstated states | Empty, loading, error, permission-denied covered? | The persona would hit the state on first run |
| Permission edges | Who else can reach this surface? What do THEY see? | Access control is implied but unspecified |
| Quantities | Limits, pagination, ranges specified? | Unbounded data can break layout or performance criteria |
| Device context | Do linked personas imply viewports/inputs the criteria ignore? | A linked persona is mobile/touch-primary |

Every ambiguity gets: the question, **blocking? yes/no**, a **proposed default** (so the user can just say "yes"), and the resolution.

## Splitting Oversized Stories

Split XL stories (or >~7 criteria spanning multiple screens) along the cleanest seam. Each child must be independently shippable and pass the gate on its own.

| Seam | Split when... | Example |
|------|---------------|---------|
| **Criterion clusters** | Criteria group into separable capabilities | "view dashboard" vs "customize dashboard" |
| **Persona** | Different personas need meaningfully different surfaces | novice guided view vs power-user dense view |
| **Screen** | Criteria touch disjoint screens | settings panel split from the main flow |
| **Happy path first** | Edge/error handling is half the size | US-042 core + US-042b degraded-data handling |

Anti-pattern splits: by layer (frontend story + backend story — neither is shippable), by task ("write tests" is not a story).

## Worked Example

Story as found in `project-management/user-stories/US-042-metrics-dashboard.md`:

```markdown
---
id: US-042
title: "Metrics dashboard"
personas: [P-003]
epic: "Admin Console"
priority: "must-have"
complexity: "L"
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

Grooming output (abridged `grooming.md`):

| Gate | Result | Note |
|------|--------|------|
| R1 | PASS | |
| R2 | PASS | P-003 (Dana, first-time admin, novice) exists |
| R3 | **FAIL → fixed** | AC-2 "loads fast" vague → rewritten: "Given a warm session, when /admin is opened, then metric cards render within 2s on a mid-range laptop" |
| R4 | PASS | L — large but coherent; no split (single screen, one persona) |
| R5 | **FAIL → resolved** | "key metrics" undefined — blocking. Proposed default: active users (24h), error rate, p95 latency, queue depth. User confirmed. |
| R6 | PASS | Screen `07-admin-dashboard.md` exists in inventory |
| R7 | PASS | US-051 is Related, not Depends — out of scope |

Ambiguity log excerpt:

| # | Question | Blocking? | Proposed default | Resolution |
|---|----------|-----------|------------------|------------|
| A1 | Which metrics are "key metrics"? | Yes | 4 metrics: active users, error rate, p95 latency, queue depth | Confirmed by user |
| A2 | Time range shown? | No | Fixed 24h window, range picker deferred to US-051 follow-up | Default accepted |
| A3 | What does a non-admin see at /admin? | Yes | 403 page with sign-in redirect | Confirmed |

**Verdict: READY** (after AC-2 rewrite and A1/A3 confirmation). Proceed to `constraint-binding.md`.

> The same story continues through all six phases in `worked-example-dashboard-story.md`.
