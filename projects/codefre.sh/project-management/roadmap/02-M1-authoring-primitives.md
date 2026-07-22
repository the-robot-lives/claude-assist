# M1 — Authoring Primitives: Prompts, Rubrics, Personas

**Impl-plan stages:** 1, 2a, 2b · **Stories:** 21

## Mission

Ship the three versioned primitives the script graph will reference. Each lane delivers
the same shape: create → edit → publish version → browse/reuse, in both UI and API.
The three lanes are mutually independent and run fully in parallel.

## Entry criteria

- M0 exit: migrations live, CI green, auth + org membership working.
- OpenAPI spec and rubric DSL JSON-schema frozen (M0 Lane B).

## Exit criteria

- Each primitive can be created, versioned, published, and listed via UI and API.
- Cross-primitive reference stubs exist in schema (US-011, US-034, US-051) — finalized
  in M2 when script nodes/expectations land.
- Rubric preview scoring (US-058) works against a sample response with LLM-as-judge.

## Lane A — Prompts (8 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/prompts/`, prompt library +
detail screens in `app/frontend/`.

| Story | Title | Pri |
|---|---|---|
| US-009 | Create a standalone prompt | P0 |
| US-010 | Publish a new prompt version | P0 |
| US-011 | Reference a published prompt from a script node (stub; finalize M2) | P0 |
| US-048 | Define template variables on a prompt | P1 |
| US-049 | Define tool/function schemas on a prompt | P1 |
| US-050 | Browse the prompt library and reuse across scripts | P1 |
| US-114 | Prompt testing sandbox | P2 |
| US-115 | Loops and conditionals in prompt templating | P3 |

## Lane B — Rubrics (7 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/rubrics/`, rubric list/detail
screens.

| Story | Title | Pri |
|---|---|---|
| US-033 | Create a simple rubric with LLM-as-judge scoring | P0 |
| US-034 | Attach a rubric to an expectation (stub; finalize M2) | P0 |
| US-056 | Define a weighted multi-criterion rubric | P1 |
| US-057 | Configure a rubric to use a ladder / enum scoring scale | P1 |
| US-058 | Preview a rubric by scoring a sample response | P1 |
| US-119 | Import a rubric from a shared marketplace | P2 |
| US-120 | Rubric confidence bands on scores | P2 |

Analytic tails US-059/US-060/US-121 (re-scoring, cross-version comparison, disagreement
analytics) are owned by **M4** — they require the results layer.

## Lane C — Personas (6 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/personas/`, persona
list/detail screens.

| Story | Title | Pri |
|---|---|---|
| US-035 | Create a basic persona with a tone tag | P0 |
| US-036 | Attach a persona to a run (schema-side; runtime in M3) | P0 |
| US-051 | Attach persona-layered expectations to script nodes (stub; finalize M2) | P1 |
| US-053 | Attach a system-prompt preamble to a persona | P1 |
| US-055 | Import a persona from a shared starter library | P1 |
| US-116 | Import a persona from a shared marketplace | P2 |

Runtime persona stories US-052 (fan-out) and US-118 (mid-run switching) are owned by
**M3**; per-persona results breakdown US-054 by **M4**.

## Cross-lane integration task

One API walkthrough that creates a prompt, a rubric, and a persona, publishes a version
of each, and verifies the stub references resolve (prompt-id, rubric-id, persona-id are
addressable from the not-yet-built script-node schema fixtures).
