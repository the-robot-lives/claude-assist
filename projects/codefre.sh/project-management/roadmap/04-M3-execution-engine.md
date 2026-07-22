# M3 — Execution Engine: Runs & Freeball

**Impl-plan stage:** 5 · **Stories:** 27

## Mission

Deliver the runner — the atom every later milestone consumes — and the Freeball
Protocol, the product's moat. A published script version executes against a published
agent version: steps stream in real time, expectations are scored, cost caps enforce,
personas fan out, and when no authored edge matches the agent's response, the freeball
runner improvises follow-ups as tentative auto-scored nodes.

This is the largest-risk milestone; its three lanes share the `runs` context boundary,
so the runner-core contract (run/step/score record shapes and the runner's node-advance
hook) freezes first, then Lanes B and C build against it.

## Entry criteria

- M2 exit: publishable script versions (with expectations) and agent versions.
- M1 rubrics: LLM-as-judge scoring callable for a single expectation.
- M0: Oban running (scheduler/worker infrastructure).

## Exit criteria

- End-to-end: trigger a run from the editor, watch steps + scores stream live, get a
  run-level pass/warn/fail verdict, cancel mid-flight, hit a cost cap and see
  auto-cancel.
- Freeball: a response matching no authored edge falls through to the freeball runner,
  produces tentative nodes with confidence, respects depth caps and strict/require
  modes.
- A run fans out across ≥2 personas in parallel with per-persona step streams.

## Lane A — Runner core (13 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/runs/` (worker, scheduler),
`results` write-path, run-trigger modal + live run detail in `app/frontend/`.

| Story | Title | Pri |
|---|---|---|
| US-015 | Trigger a one-off run from the editor | P0 |
| US-016 | View run status update in real time | P0 |
| US-017 | See each step's prompt and agent response in run detail | P0 |
| US-018 | Cancel an in-flight run | P0 |
| US-019 | Get run-level pass/warn/fail verdict | P0 |
| US-020 | See individual step scores | P0 |
| US-021 | See aggregate score summary for a run | P0 |
| US-066 | Retry a failed run from the failing step | P1 |
| US-067 | Enforce run-level cost cap (auto-cancel when exceeded) | P1 |
| US-068 | Stream scores in real time alongside the step stream | P1 |
| US-069 | Schedule recurring runs via cron expression | P1 |
| US-070 | Trigger a batch run against multiple agents | P1 |
| US-124 | Cost prediction before a run is triggered | P2 |

(US-125, dataset-run persona fan-out, is owned by **M5** with the datasets lane.)

## Lane B — Freeball engine (12 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/` freeball modules
(freeball_nodes, freeball_expectations, runner-agent orchestration), freeball surfaces
in run detail.

| Story | Title | Pri |
|---|---|---|
| US-022 | Fall through to freeball when no authored edge matches | P0 |
| US-023 | See freeball-generated prompt in run detail | P0 |
| US-024 | See freeball runner confidence per tentative node | P0 |
| US-071 | Configure the freeball runner model and prompt per organization | P1 |
| US-072 | Enforce a freeball depth cap / budget | P1 |
| US-073 | Support freeball-within-freeball nesting | P1 |
| US-074 | Enforce strict mode on a node (reject freeball) | P1 |
| US-075 | Require freeball mode on a node (force freeball) | P1 |
| US-076 | Warn when freeball runner model is weaker than the target agent | P1 |
| US-126 | Freeball confidence distribution histograms | P3 |
| US-127 | Freeball learning mode (promoted paths tune the runner) | P3 |
| US-128 | Adaptive freeball depth based on confidence | P3 |

US-127 depends on M5 promotion data; schedule it last in this lane and finalize once
M5's promotion records exist (impl-plan lists it as a deferred tail).

## Lane C — Persona runtime (2 stories)

**Zone / exclusive surfaces:** run_personas fan-out path in the runner, persona
selection in the run-trigger modal.

| Story | Title | Pri |
|---|---|---|
| US-052 | Fan out a run across multiple personas in parallel | P1 |
| US-118 | Per-step persona switching mid-run | P3 |

## Cross-lane integration task

One demo run: a script with a freeball-anchor node, fanned across two personas, against
the OpenAI agent — live streams show per-persona steps and scores, one branch falls
through to freeball, produces confidence-tagged tentative nodes, and the run lands a
verdict under its cost cap.
