# Release Notes & Rollout

Phase 6: package the verified story for shipping — release notes written per audience, a changelog entry, a rollout/flag strategy chosen by risk, and a post-release validation checklist. Output is `release-notes.md`.

> This phase produces *release communication and rollout mechanics*. For launch/marketing content (announcement posts, campaigns), hand the notes to **trl-marketing**. For deep editorial polish of user-facing docs, see **trl-technical-writer**.

## Per-Audience Release Notes

One release, several tellings. Write each audience section from what *they* can now do — the personas tell you who the end-user audiences are:

| Audience | Source of truth | Voice & content | Skip when |
|----------|-----------------|-----------------|-----------|
| **End users** (per persona segment) | Story's "So that" + persona goals | Benefit-first, persona vocabulary, zero internal jargon; one screenshot-worthy sentence per capability | Feature is invisible to them |
| **Operators / admins** | Config, flags, migrations, dashboards touched | What changed operationally: new envs/flags, migration steps, alert/metric changes, rollback lever | No ops surface changed |
| **Developers** | API/schema/component changes | Contract deltas, deprecations, upgrade notes, changelog link | No programmatic surface changed |

Rule of thumb: if a sentence would work in all three sections, it's too vague for any of them.

## Changelog Entry

Keep-a-Changelog style, one entry per story, referencing the story ID:

```markdown
## [Unreleased]
### Added
- Admin metrics dashboard at /admin: active users, error rate, slowest responses (p95),
  queue depth over a 24h window, with per-metric unavailable states. (US-042)
### Changed
- `MetricTile` component gains `unit` and `trend` props (backward compatible).
```

## Rollout Strategy Selection

Choose by risk, not habit:

| Strategy | Choose when | Mechanics | Rollback |
|----------|-------------|-----------|----------|
| **Direct** | Additive surface, no data migration, small blast radius, criteria fully verified | Ship on next deploy | Revert commit / redeploy |
| **Flagged** | New surface replacing or sitting beside an existing flow; want a kill switch | Feature flag default-off → on for team → on for all | Flip flag off |
| **Percentage** | Performance/scale uncertainty (new hot endpoint, heavy query) | 5% → 25% → 100% gated on metrics | Dial to 0% |
| **Cohort** | Behavior differs by persona segment (novice vs power org); want feedback from the served persona first | Enable for the story's primary persona segment/org list first | Remove cohort |

Modifiers:

| Signal | Adjustment |
|--------|------------|
| Data migration involved | Never direct; migration must be reversible or dual-write first |
| Story was READY-WITH-WAIVERS | At least flagged — waived rows are your likeliest incident source |
| must-have priority + hotfix pressure | Direct is acceptable *only* with a green matrix and a rollback lever named |

## Post-Release Validation

Written *before* shipping, executed after:

| Check | Definition |
|-------|------------|
| **Smoke path per persona** | The primary persona walkthrough from the verification matrix, re-run in production (or prod-like) once live |
| **Metrics to watch** | 2–4 concrete signals tied to the criteria (e.g. /admin p95, dashboard endpoint error rate, empty-state impression count) with a watch window (24–72h) |
| **Rollback trigger** | The specific threshold that flips the flag / reverts (e.g. endpoint error rate >1% for 10 min) — decided now, not during the incident |
| **Follow-up intake** | Non-blocking friction notes from phase 5 filed as candidate stories back into the backlog |

## Worked Example (US-042, abridged `release-notes.md`)

```markdown
# Release — US-042: Admin Metrics Dashboard

## For admins (end users — P-003 segment)
Open the admin console and see service health at a glance: a headline verdict
("All systems normal") plus four cards — active users, error rate, slowest
responses, and queue depth — for the last 24 hours. If metrics are still
warming up, the dashboard tells you what's happening and where to check.

## For operators
- New endpoint `GET /api/admin/metrics/summary` (30s cache). Watch its p95 + error rate.
- Feature flag `admin_metrics_dashboard` (default ON after cohort phase).
- No migrations. Rollback: flip the flag off.

## For developers
- `MetricTile` gains optional `unit`, `trend` props (non-breaking).
- Changelog entry under [Unreleased] → Added. (US-042)

## Rollout
Cohort → all: enable for the internal admin org for 48h (primary persona segment
gets it first), then default ON. Rationale: new hot endpoint (percentage-style
caution) + persona-segment feedback wanted; cohort covers both.

## Post-release validation
- [ ] Re-run P-003 smoke path in prod: login → /admin → verdict + 4 cards <2s
- [ ] Watch 72h: summary endpoint p95 <300ms, error rate <0.5%
- [ ] Rollback trigger: endpoint error rate >1% for 10 min → flag off
- [ ] File follow-ups: US-042-f1 keyboard shortcut for card detail (P-007 friction)

## Handoffs
- trl-marketing: announcement post from the "For admins" section
- trl-technical-writer: admin-guide page for the dashboard
```
