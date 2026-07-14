# Story Readiness Checklist (Phase 1 Gate)

- **Story**: US-{NNN} — {title}
- **Groomed by**: {agent/human} on {date}
- **Verdict**: ☐ READY ☐ READY-WITH-WAIVERS ☐ NOT-READY

## Gate R1–R7

| # | Gate | Test | Result | Note / remediation |
|---|------|------|--------|--------------------|
| R1 | Identity | Story has ID + title and lives at `project-management/user-stories/US-{NNN}-{slug}.md` | ☐ PASS ☐ FAIL | |
| R2 | Persona link | `personas:` frontmatter non-empty; every `P-XXX` file exists under `project-management/personas/` | ☐ PASS ☐ FAIL | Never invent a persona — ask |
| R3 | Testable criteria | Every acceptance criterion is Given/When/Then with an observable "then" | ☐ PASS ☐ FAIL | List rewrites below |
| R4 | Sized | Complexity S/M/L (XL must be split first) | ☐ PASS ☐ FAIL | Split proposal below |
| R5 | Unambiguous | No blocking open questions remain | ☐ PASS ☐ FAIL | Ambiguity log below |
| R6 | Screen mapping | Screens touched exist in `project-management/screens/` or are declared NET-NEW | ☐ PASS ☐ FAIL | |
| R7 | Dependencies | Every "Depends on US-XXX" is shipped or explicitly out of scope | ☐ PASS ☐ FAIL | |

## Criteria Audit

| # | Criterion (as written) | Class (testable / vague / missing-context) | Rewrite (if needed) | Accepted? |
|---|------------------------|--------------------------------------------|---------------------|-----------|
| AC-1 | | | | ☐ |
| AC-2 | | | | ☐ |

## Ambiguity Log

| # | Question | Blocking? | Proposed default | Resolution |
|---|----------|-----------|------------------|------------|
| A1 | | ☐ yes ☐ no | | |

## Split Decision

☐ No split needed
☐ Split proposed along seam: ☐ criterion clusters ☐ persona ☐ screen ☐ happy-path-first

| Child story | Scope | Independently shippable? |
|-------------|-------|--------------------------|
| US-{NNN}a | | ☐ |

## Waivers (READY-WITH-WAIVERS only)

| Gate | Rationale | Approved by |
|------|-----------|-------------|
| | | |
