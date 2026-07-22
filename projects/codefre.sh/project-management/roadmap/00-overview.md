# CodeFresh Roadmap — Overview

## Mission

This roadmap sequences the 146 active user stories of CodeFresh (150 authored − 4
cancelled: US-111, US-112, US-113, US-117) into seven dependency-ordered milestones so a
fleet of agents can build them with maximum parallelism and zero merge conflicts. Work is
ordered by **what must be true before a milestone can start**, never by calendar time.
The authoring primitives (prompts, rubrics, personas) come before the script graph; the
script graph and agent connectors come before the runner; the runner comes before every
results, review, and telemetry surface — because a run is the atom every downstream
system consumes.

The roadmap is the milestone-level view of `docs/IMPLEMENTATION-PLAN.md` (the 16-stage
vertical-slice build plan). Stages map to milestones as shown below; the implementation
plan remains the source of truth for per-story execution sequence and schema details.

## Core principles

1. **Sequence, not schedule.** A milestone's position is fixed by its dependencies, not
   by duration. No dates or estimates appear in this document set — only entry gates
   (what must already be merged) and exit gates (what must be demonstrably true).
2. **Contracts are the cut points.** M0 freezes the four foundational contracts — the
   OpenAPI spec, the YAML script schema, the rubric DSL JSON-schema, and the OTLP
   receiver contract. Later lanes consume frozen interfaces and fan out without
   renegotiation.
3. **One owner per path.** Every lane lists the surfaces it exclusively owns (backend
   context, frontend feature area, CLI, SDK package). Two lanes never share a writable
   surface; contested surfaces are promoted to contract work or a named integration task.
4. **Priority orders within a lane, not across milestones.** P0 before P1/P2/P3 inside a
   lane's story list. Priority never moves a story between milestones — dependency does.
   (This is why a handful of Wave-2/3 stories appear early — e.g. API tokens US-096/097
   are forward-loaded into M0 because the CLI login contract depends on them — and why
   some Wave-2 analytics tails land late.)
5. **Stub-then-finalize is explicit.** Cross-primitive references (US-011 prompt-in-node,
   US-034 rubric-on-expectation, US-051 persona-layered expectations) are schema-stubbed
   in M1 and finalized in M2 when the script graph lands. Analytic tails (US-054, US-059,
   US-060, US-121) are finalized in M4 when the results layer exists. Each story is still
   owned by exactly one milestone — the one where it is *finished*.
6. **Integration is a named task, not a hope.** Every multi-lane milestone ends with an
   explicit cross-lane task that proves the lanes compose end-to-end.

## Milestone summary

| ID | Name | Mission | Lanes | Stories | Impl-plan stages |
|---|---|---|---|---|---|
| M0 | Foundation & Contract Freeze | Run the staged migrations, stand up CI/Oban/auth/API tokens, and freeze the four contracts everything else consumes. | 2 | 4 | 0, 0.5 |
| M1 | Authoring Primitives | Ship the three versioned primitives — prompts, rubrics, personas — with create/publish/version flows in UI and API. | 3 | 21 | 1, 2a, 2b |
| M2 | Script Graph & Agent Connectors | Ship the graph editor (the hero surface), script versioning + YAML round-trip, and the agent adapter layer. | 2 | 25 | 3, 4 |
| M3 | Execution Engine: Runs & Freeball | Deliver the runner: real-time runs, step scoring, cost caps, persona fan-out, and the Freeball Protocol (the moat). | 3 | 27 | 5 |
| M4 | Results, Dashboards & CLI | Close the MVP: run list/detail/diff, trend dashboards, analytic tails, and the CLI + CI/CD templates. | 2 | 28 | 6, 7 |
| M5 | Review, Datasets & Captures | Open the learning loop: freeball review/promotion, dataset evals, and manually flagged captures. | 3 | 22 | 8, 9 |
| M6 | Telemetry, SDKs & Enterprise | Ship OTel ingestion/query + auto-flagging, the three SDK cores + webhooks, and enterprise tenancy (SSO, audit export). | 3 | 19 | 10, 10+, 11, 12 |

Story count check: M0=4, M1=21, M2=25, M3=27, M4=28, M5=22, M6=19 → 146, matching the
146-story active corpus. See [`story-coverage.md`](story-coverage.md) for the full
traceability matrix.

**Current status:** M0 is in progress (implementation-plan Stage 0 🟡 — auth + invite
tokens implemented; migrations written but not yet executed; CI/Cypress absent). M1–M6
pending.

## How to read this roadmap

1. Open your milestone's doc; read its **Entry criteria** — everything it depends on
   must already be satisfied and merged before you start.
2. Find your lane; its **Zone / exclusive surfaces** line is the only code you may edit.
3. Work the lane's story list in priority order (P0 → P3).
4. A milestone is not done from one lane's view — exit requires every lane's exit
   criteria plus the cross-lane integration task.

## Traceability

Every one of the 146 active user stories is assigned to exactly one primary
milestone/lane; a supporting lane is recorded only in the **Notes** column of the matrix
when it materially contributes (e.g. the results lane finalizing a rubric-analytics
story). See [`story-coverage.md`](story-coverage.md).
