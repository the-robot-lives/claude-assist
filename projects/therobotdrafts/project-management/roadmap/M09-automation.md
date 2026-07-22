# M9 — Automation & CI Integration

Harden the headless surface built in M4 (and the export surface in M5) into a dependable
programmatic product for the ARIA automation persona: structured errors and exit codes across the
REST API and a thin CLI, cancellable and time-bounded long operations, and a structural-rule gate
that can fail a CI build. This is a deliberately **light** milestone — three small gate contracts,
straightforward implementations behind them, and a packaged CLI.

## Entry criteria

- **M4 exit.** The headless remodel API and commit webhook (US-089), deterministic codegen
  (US-090), env/secret configuration (US-094), and the ingestion/analysis Oban workers all exist.
- **M5 (available, not required).** The headless SVG/PlantUML export API (US-091) landed in M5; the
  CLI's `export` subcommand surfaces it if M5 has merged, otherwise it is stubbed behind a capability
  flag until M5 lands. No M5 work is created here.
- The REST `/api/v1` surface and OpenAPI document (M0) are frozen; the error envelope is standardized
  in this milestone.

## Gate tasks

Three small contract freezes, all front-loaded.

**M9-BE-API-01 — Error + exit-code taxonomy** (size: S)
Define the structured error envelope (RFC 9457 `problem+json`: `type`/`title`/`status`/`detail`/
`instance` plus a stable machine `code`) and the API-error → process-exit-code mapping the CLI will
use. Unblocks the BE error refactor, the CLI, and QA.
depends: M4 exit · stories: US-092

**M9-BE-API-02 — Operation lifecycle contract** (size: S)
Define cancellation and timeout semantics for long operations: a job handle, a cancel endpoint, a
timeout configuration, and the terminal states — shared by the API workers and the CLI.
depends: M4 exit · stories: US-093

**M9-BE-CORE-01 — Structural rule schema** (size: S)
Define the structural-rule format (rule id, selector over the graph model, severity, message) and
the pass/fail evaluation result. Unblocks the rule engine and the CI gate.
depends: M4 exit · stories: US-095

## Lanes & tasks

### BE-API — structured errors, job control, rule endpoint

**M9-BE-API-03 — Structured errors across the REST surface** (size: M)
Apply the M9-BE-API-01 envelope to every `/api/v1` controller and plug, map domain errors to stable
machine codes, and update the OpenAPI document.
depends: M9-BE-API-01 · stories: US-092

**M9-BE-API-04 — Cancellation + timeout API** (size: M)
Job-handle endpoints (start returns a handle; cancel; status), enforced timeouts, and terminal
states per M9-BE-API-02.
depends: M9-BE-API-02 · stories: US-093

**M9-BE-API-05 — Structural rule evaluation endpoint** (size: M)
Run a ruleset against a document/version and return pass/fail plus violations, per the rule schema.
depends: M9-BE-CORE-02 · stories: US-095

### BE-ING / BE-CORE — cancellable jobs and the rule engine

**M9-BE-ING-01 — Cancellable, bounded Oban jobs** (size: M)
Make the ingest/analysis/codegen jobs honor cancellation tokens and timeouts and emit structured
terminal errors, with no partial commit on abort.
depends: M9-BE-API-02 · stories: US-093

**M9-BE-CORE-02 — Structural rule engine** (size: M)
Evaluate rules (dependency cycles, layering violations, boundary/trust rules, metric thresholds)
over the graph model, reusing the M2 traversal, cycle-detection, and metric primitives.
Deterministic given a document version.
depends: M9-BE-CORE-01 · stories: US-095

### INFRA — thin CLI and CI gate

**M9-INFRA-01 — Thin CLI package** (size: L)
A Node/TS CLI wrapping `/api/v1`, reusing the frontend api-client types and the OpenAPI schema.
Subcommands: `remodel` (US-089), `codegen` (US-090), `export` (US-091 via M5), `rules-check`
(US-095); configuration via env/secret (US-094). Structured stderr and exit codes per the taxonomy.
Recommended over an escript because it can share the frontend's generated types and OpenAPI.
depends: M9-BE-API-01, M9-BE-API-03 · stories: US-092, US-093, US-095

**M9-INFRA-02 — CLI cancellation/timeout wiring** (size: S)
Signal handling (`SIGINT`) cancels the in-flight API operation; a `--timeout` flag bounds it; the
process exits non-zero on cancel or timeout.
depends: M9-INFRA-01, M9-BE-API-04 · stories: US-093

**M9-INFRA-03 — Structural-rule CI gate** (size: S)
A CI step invoking `cli rules-check`; a non-zero exit fails the build and violations are annotated.
depends: M9-INFRA-01, M9-BE-API-05 · stories: US-095

### QA — headless verification

**M9-QA-01 — Structured-error/exit-code tests** (size: M)
Assert every error path returns the envelope and that the CLI maps each to the documented exit code.
depends: M9-BE-API-03, M9-INFRA-01 · stories: US-092

**M9-QA-02 — Cancellation/timeout tests** (size: M)
Start a long operation, cancel it and separately time it out, and assert the terminal state, exit
code, and absence of a partial commit.
depends: M9-BE-API-04, M9-BE-ING-01, M9-INFRA-02 · stories: US-093

**M9-QA-03 — Rule-gate tests** (size: S)
A document violating a structural rule fails `rules-check` and the CI gate; a clean document passes.
depends: M9-BE-API-05, M9-INFRA-03 · stories: US-095

## Integration & exit criteria

**M9-INT-01 — CLI ↔ API ↔ CI integration** (size: M) — joins BE-API, BE-CORE, BE-ING, INFRA, QA.
Full path against a running backend: CLI `remodel` / `codegen` / `export` / `rules-check` return
structured errors and exit codes end-to-end; the rule gate fails a seeded-violation build and passes
a clean one; a cancelled/timed-out operation exits non-zero with no partial write.
depends: all M9 lane tasks · stories: US-092, US-093, US-095

**Exit checklist**
- US-092: structured errors and exit codes across the API and CLI, demonstrable headlessly.
- US-093: long operations cancel and time out cleanly, leaving no partial state.
- US-095: a structural-rule violation fails the build; a clean model passes.
- The CLI is packaged and versioned, configured via env/secret.

**Demo script.** From a terminal: run `cli remodel` against a repo and watch a structured success;
force an error and read the `problem+json`-shaped stderr and non-zero exit; start a long
`rules-check`, press Ctrl-C, and confirm a clean cancel; run the CI gate against a model with a
deliberate layering violation and watch the build fail with an annotated report.

## Parallelization notes

- **Workers supported:** ~2–3 (a BE-API/BE-CORE/BE-ING pair, an INFRA/CLI worker, QA).
- **Gate order:** the three small gates (error taxonomy, operation lifecycle, rule schema) freeze
  first and are independent of one another, so they can be authored in parallel.
- **Lane isolation:** BE owns `backend/`, INFRA owns the CLI package and CI files, QA owns the tests.
  No shared directories.
- **Track placement:** M9 depends only on M4 and runs concurrently with the M5/M6/M7 and M8/M10
  tracks — it is the lightest of the parallel post-M3 milestones.
- **Merge order:** gates → BE implementations → CLI → CI gate → INT-01.

## Stories delivered

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-092 | P1 | ARIA | Return structured errors and exit codes |
| US-093 | P1 | ARIA | Cancel and time out long operations |
| US-095 | P2 | ARIA | Fail the build on a structural rule violation |
