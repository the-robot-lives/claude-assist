---
title: "Milestone 5 — Closing the Loop & Release Readiness"
milestone: M5
status: draft
generated: 2026-07-16
---

# M5 — Closing the Loop & Release Readiness

1 story (the capstone) plus cross-cutting release-readiness work spanning every lane. No
new lane-owned feature scope opens here — the goal is closing the last epic, proving every
persona's journey against the real screen inventory, and hardening for deploy.

## Entry Criteria

- M4 exit criteria met: business/enterprise persona journeys (James Oduya, Lin Zhao)
  complete end-to-end.
- US-097 (automated eval rubrics, ✓M3) and US-099 (A/B test prompts, ✓M4) both live — US-100
  depends on both for its failure-pattern and suggestion-confidence inputs.
- All 99 non-capstone stories in a Done or explicitly re-scoped state (see backlog
  reconciliation below for the one known scope gap).

## Exit Criteria

- All 100 stories done or explicitly re-scoped.
- Release candidate deployable via the existing `helm/therobotplans` chart and the
  monorepo's standard `deploy-service` pipeline — no bespoke M5-only deploy path.
- Every persona's primary journey validated end-to-end against the 74 screen specs.
- Accessibility and load/perf passes complete with no release-blocking findings open.

---

## WS-K — Prompts & Evaluation

### US-100 — Eval results feed back into prompt refinement suggestions (capstone)
- Persona(s): Lin Zhao
- Size: L
- Deps: US-097 ✓M3 (automated eval rubrics — failure-pattern source); US-099 ✓M4 (A/B test
  prompts — confidence-scoring precedent); US-095 (prompt-archival audit trail — wherever it
  landed, M3 or its M4 slip); US-096 ✓M2 (agent output ratings, cited per-example)
- Story: [../user-stories/US-100-eval-feedback-loop.md](../user-stories/US-100-eval-feedback-loop.md)

This is the story that closes the loop between the three domains built across M2-M4:
agent-eval detects quality issues, prompt-archival holds the version/audit history, and
this feedback mechanism turns the former into actionable, human-approved changes to the
latter. No new domain is created — this is pure integration atop WS-K's own tables.

Tasks:
- Schema/migration `550`: `prompt_refinement_suggestion` (threshold trigger, failure-pattern evidence with concrete examples, proposed diff, confidence score, approval state) + `prompt_audit_log` change-type extension (`suggestion-applied`, linking back to the triggering eval data)
- Backend: threshold-triggered failure-pattern analysis job (e.g. "7 of 12 low-rated code reviews missed null-check edge cases") producing grounded, example-cited suggestions — never vague ("improve accuracy") suggestions; proposed-diff generation against the current prompt version
- Backend: human-in-the-loop approval gate — suggestions are **never** auto-applied; one-click apply creates a new prompt version via US-086's versioning API and is logged as a distinct audit change-type via US-095's audit trail
- Frontend: suggestion review UI (diff view, confidence score, apply/dismiss) under `app/app/[orgId]/prompts/**`
- Tests: no-auto-apply enforcement test (suggestion cannot become a version without explicit approval, checked at the API layer, not just UI); example-grounding test (every generated suggestion must cite at least one concrete failure instance, reject generation otherwise)
- Contract: writes new prompt versions through WS-K's own US-086 API and audit entries through WS-K's own US-095 audit trail — fully in-lane; reads eval failure data from WS-K's own US-096/US-097/US-099 tables, no cross-lane dependency

---

## All-Lane Release Readiness

Not lane-owned feature work — every lane contributes its own slice under its existing
code ownership. Coordinate scheduling through WS-L; do not create a 12th lane for this.

### Persona journey validation (all lanes)
- Run a goal-directed task-flow validation per persona (Alex Russo, Maya Chen, Sarah Kim,
  Lin Zhao, James Oduya, Diana Kovacs, Raj Patel) against the full 74-screen inventory —
  use the `trl-site-walkthrough` methodology to generate task graphs and journey logs.
- Each lane authors Cypress e2e specs for the journey segments that touch its owned routes;
  WS-L stitches cross-lane journeys (e.g., Alex's morning-planning → today-view → OKR
  check-in) that cross route-segment boundaries.
- Output: a journey-log report per persona flagging any screen with no reachable task path
  or a broken cross-lane handoff — feed findings back as bug items (WS-D), not silent fixes.
- No new migrations — this is test-authorship and defect-filing work against existing schema.

### Accessibility pass (all lanes)
- WCAG audit against `@noizu/styleguide` primitives and each lane's owned components,
  prioritized by the persona journey map (screens with no accessible path block release).
- Keyboard-navigation and screen-reader spot checks on the highest-traffic surfaces: today
  view (WS-L), kanban/Gantt (WS-C), agent activity feed (WS-J/WS-L).
- Findings filed as bug items in WS-D's pipeline, triaged through the same US-034 auto-triage
  agent already live since M3 — no separate accessibility-bug workflow.

### Load/perf pass (all lanes)
- Validate the perf budgets already asserted in-story (US-062 `<2s` search at 10k docs,
  US-098 `<3s` dashboard at 10-agent/10k-task scale) hold at realistic multi-tenant volume.
- WS-L coordinates a combined-load scenario exercising the unified today view under
  cross-lane read-model load (US-001/US-002/US-004/US-005 all aggregating simultaneously).
- pgvector-backed search (US-037 duplicate detection, US-062 knowledge base) gets explicit
  index/query-plan review given embedding-search cost grows with corpus size.

### Helm/deploy hardening
- Verify `helm/therobotplans` chart values map correctly to every domain's config surface
  added since M0 (new env vars, new InfisicalSecret references, new liquibase changelog
  includes across all 12 lane-owned changelog files).
- Confirm WS-L's master changelog include picks up every lane's changelog file added
  M1 through M5 (`db/changelog/lanes/<lane>.yaml`) — audit for any lane that drifted from
  its allocated ID block (see the migration allocation scheme in the roadmap README).
- Dry-run the full `deploy-service` pipeline against a staging namespace; confirm no
  M5-specific deploy steps were introduced outside the existing monorepo pipeline.
- Docs: update `app/docs/PROJ-ARCH.md`, `PROJ-LAYOUT.md`, `PROJ-SCHEMA.md` for everything
  landed M1-M5 (delegate to the `update-arch-doc`/`update-layout-doc`/`update-schema-doc`
  skills rather than hand-editing).

---

## Backlog reconciliation

**Diana Kovacs time-tracking/billing gap (Flag 5):** Diana's JTBD explicitly includes time
tracking and client billing, and zero stories in the 100-story backlog cover it. This
surfaced concretely in M3 (US-004's cross-project today summary degrades planned-vs-actual
hours to estimates only, no real time-tracking) and M4 (US-085's cost/client tagging is
agent-compute cost, not human time-tracking or invoicing).

Action: file new stories for a time-tracking/billing epic against WS-A (personal time
entries) and a new or extended lane for client billing/invoicing — **explicitly out of
scope for this roadmap**. Do not fold this work into M5; it re-enters as a future milestone
proposal once scoped. Track as a known gap in the release notes so Diana's persona journey
validation above can flag the workaround (estimate-based hours) rather than mask it as
complete.
