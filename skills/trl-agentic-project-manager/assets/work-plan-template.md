# Work Plan — {feature-slug}

> Fill every section. IDs (U/C/T/G) are stable — tickets and room messages reference them.
> A plan with dates in it is wrong; only blocking edges express order.

## Intake

- **Story/PRD**: {link or path}
- **Deliverables**: {enumerated list — what exists when this is done}
- **Acceptance criteria**: {verifiable list}
- **Out of scope**: {explicit exclusions}

## Phase 0 — Contracts (serial)

| ID | Contract | Format | Owner | Consumers | Freeze status |
|----|----------|--------|-------|-----------|---------------|
| C1 | API interface spec | OpenAPI/typespec | | T1, T2, T4, T5 | ☐ draft ☐ frozen |
| C2 | UX spec + screen inventory | markdown | | T1 | ☐ draft ☐ frozen |
| C3 | Selector schema (data-cy) | yaml/markdown | | T1, T3 | ☐ draft ☐ frozen |
| C4 | Data-model deltas | migration plan | | T2 | ☐ draft ☐ frozen |
| C5 | Fixtures / stub definitions | fixtures | | T3, T4 | ☐ draft ☐ frozen |

## Work DAG

```
{Adjacency list or mermaid — work units and their TRUE blocking edges only.}
C1,C2,C3 ──▶ U1 (frontend impl)
C1,C4    ──▶ U2 (backend impl)
C3,C5    ──▶ U3 (e2e specs)
C1,C5    ──▶ U4 (backend tests)
U1,U2    ──▶ G1 (front↔back)
...
```

### Edge audit
For each edge, record why it survived the attack ("could a contract/stub/fixture remove this?"):

| Edge | Class (data / contract / resource / habit) | Kept because |
|------|--------------------------------------------|--------------|
| | | |

## Tracks

| ID | Track | Work units | Owner (agent) | Exclusive file ownership (globs) |
|----|-------|-----------|---------------|----------------------------------|
| T1 | Frontend | | | |
| T2 | Backend | | | |
| T3 | E2E tests | | | |
| T4 | Backend tests | | | |
| T5 | Fixtures/stubs | | | |

**Ownership check**: ☐ every path touched by the plan maps to exactly one track, or to `contract:` / `integration:`
**Contested paths → resolution**: {list any path two tracks wanted, and how it was split}

## Gates

| ID | Gate | Joins | Entry criteria (verifiable) | Merge order |
|----|------|-------|-----------------------------|-------------|
| G1 | front↔back | T1+T2 | contract conformance tests pass both sides | |
| G2 | e2e↔front | T3+T1 | cypress green against real FE, mocked API | |
| G3 | api-tests↔back | T4+T2 | API suite green against real BE | |
| G4 | full integration | all | integrated suite green end-to-end | |

## Coordination

- **tobor session**: {uuid}
- **Story/epic**: {id}
- **Tickets**: {U-id → ticket-id map}
- **Room**: {room id} — charter posted ☐

## Risks / open questions

- {…}
