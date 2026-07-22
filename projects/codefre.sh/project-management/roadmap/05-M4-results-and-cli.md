# M4 — Results, Dashboards & CLI (MVP close)

**Impl-plan stages:** 6, 7 · **Stories:** 28

## Mission

Close the MVP. Lane A is a query-only layer over run data: run list with filters, run
detail drill-down, run diff, trend dashboards — plus the analytic tails stubbed in
M1/M3 that needed real run data to finish. Lane B ships the open-source wedge: the
`codefresh` CLI with pass/fail exit codes and CI templates. Per the implementation plan,
the critical-path demo closes at the script trend chart (US-078).

## Entry criteria

- M3 exit: runs execute end-to-end with steps, scores, verdicts, personas, freeball.
- M0: API tokens (CLI login), frozen YAML script schema (CLI file runs), OpenAPI spec.

## Exit criteria

- Run list filterable by script/agent/status/date/persona; run detail with linear
  timeline and per-step JSON drill-down; two runs diffable side by side; JSON export.
- Script trend chart over historical runs renders (critical-path MVP demo).
- `codefresh run script.yaml` executes against the platform and exits 0/1; JUnit XML
  emitted; GitHub Actions workflow and GitLab CI template published.

## Lane A — Results & dashboards (18 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/results/` (query layer only —
no runner writes), run list/detail/diff + dashboard screens, chart components.

| Story | Title | Pri |
|---|---|---|
| US-025 | List recent runs for an organization | P0 |
| US-026 | Filter the run list by script | P0 |
| US-027 | Filter the run list by agent | P0 |
| US-028 | Filter the run list by status | P0 |
| US-029 | Open run detail from the list | P0 |
| US-030 | View the conversation as a linear timeline | P0 |
| US-031 | Drill down into a single step's full JSON payload | P0 |
| US-032 | Export a single run as JSON | P0 |
| US-077 | Side-by-side diff view of two runs | P1 |
| US-078 | Trend chart of aggregate scores over time for a script | P1 |
| US-079 | Filter the run list by date range | P1 |
| US-080 | Filter the run list by persona | P1 |
| US-054 | See per-persona results breakdown on a run (deferred tail from M1) | P1 |
| US-059 | Re-score a past run with a newer rubric version (deferred tail) | P1 |
| US-060 | Side-by-side score comparison across rubric versions (deferred tail) | P1 |
| US-129 | Cohort comparison across multiple runs | P2 |
| US-121 | Rubric disagreement analytics across runs (deferred tail) | P3 |
| US-130 | Custom dashboard builder | P3 |

## Lane B — CLI & CI/CD (10 stories)

**Zone / exclusive surfaces:** `cli/` (Elixir mix project), published CI templates.
No new backend schema — consumes the existing API only.

| Story | Title | Pri |
|---|---|---|
| US-037 | Run a script via codefresh CLI with a YAML file | P0 |
| US-038 | Get a pass/fail exit code from the CLI | P0 |
| US-083 | Emit JUnit XML from the CLI | P1 |
| US-084 | Run with --personas flag from the CLI | P1 |
| US-085 | Publish a GitHub Actions reusable workflow for CodeFresh | P1 |
| US-086 | Publish a GitLab CI template for CodeFresh | P1 |
| US-087 | codefresh login and local token management | P1 |
| US-134 | codefresh init — project scaffolding | P2 |
| US-135 | CLI watch mode for file changes | P3 |
| US-136 | TAP and Allure output formats from CLI | P3 |

## Cross-lane integration task

A GitHub Actions job runs `codefresh run` against a YAML script, fails the build on a
regression, and the same run appears in the dashboard's run list and trend chart — the
full "changed the system prompt, need to know what broke" loop from the primary persona
(Priya).
