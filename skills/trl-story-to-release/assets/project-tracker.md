# Story to Release — Project Tracker

## Story Metadata

- **Story**: US-{NNN} — {title}
- **Project**: {project}
- **Personas**: {P-XXX, P-XXX}
- **Priority / Complexity**: {must-have|should-have|could-have} / {S|M|L}
- **Target release**: {date or milestone}
- **Status**: Grooming / Constraint Binding / Planning / Implementation / Verification / Release / Shipped

## Phase Checklist

| Phase | Status | Verdict / Gate | Artifact | Completed |
|-------|--------|----------------|----------|-----------|
| 1. Intake & grooming | ☐ Not Started | READY / READY-WITH-WAIVERS / NOT-READY | `releases/US-{NNN}/grooming.md` | — |
| 2. Constraint binding | ☐ Not Started | FULL / DEGRADED, frozen {date} | `releases/US-{NNN}/constraints.md` | — |
| 3. Implementation planning | ☐ Not Started | plan confirmed (L stories) | `releases/US-{NNN}/plan.md` | — |
| 4. Implementation | ☐ Not Started | all tasks done/deferred-with-log | code + checkpoint log | — |
| 5. Verification | ☐ Not Started | {n}/{n} matrix rows PASS, {w} waived | `releases/US-{NNN}/conformance.md` | — |
| 6. Release | ☐ Not Started | rollout: {direct/flagged/percentage/cohort} | `releases/US-{NNN}/release-notes.md` | — |

## Readiness Waivers

| Gate | Waived because | Approved by | Date |
|------|----------------|-------------|------|
| — | — | — | — |

## Open Ambiguities

| # | Question | Blocking? | Status |
|---|----------|-----------|--------|
| — | — | — | — |

## Deviation Log Summary

| Constraint | Deviation | Verdict (justified / fixed) |
|-----------|-----------|------------------------------|
| — | — | — |

## Verification Snapshot

| Metric | Value |
|--------|-------|
| Matrix rows (personas × criteria) | — / — PASS |
| Waived rows | — |
| Style constraints met | — / — |
| Edge-case battery | ☐ a11y ☐ device ☐ expertise ☐ data |

## Post-Release Watch

| Check | Window | Result |
|-------|--------|--------|
| Persona smoke path in prod | — | ☐ |
| Metric: {name} {threshold} | — | ☐ |
| Rollback trigger armed | — | ☐ |
| Follow-up stories filed | — | ☐ |
