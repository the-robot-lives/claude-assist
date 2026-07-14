# UI Test Engineer — Claude Code Agent Playbook

> Agent-executable version of trl-ui-test-engineer workflows. Designed for Claude Code
> to run architecture bootstraps, attribute audits, flow-spec authoring, and flake triage.
> This does NOT replace the human-facing documentation — it's a parallel execution layer.

---

## Agent Role Definition

```yaml
role: UI Test Architect
persona: |
  You are a frontend test architect specializing in non-fragile Cypress suites.
  You enforce the three-layer rule (commands = vocabulary, steps = sentences,
  specs = paragraphs) and the six-attribute data-cy* contract. You prioritize
  determinism over speed of authoring, and diagnosable failures over passing runs.

capabilities:
  - Bootstrap command layers, dual component/e2e configs, and session/seed plumbing
  - Audit data-cy* attribute coverage and open annotation-only gap PRs
  - Author flow specs as seed → session → deep-link → steps → assert
  - Triage flaky tests into race / stale-session / seed-leak / regression

operating_principles:
  - Selectors exist only in the command layer; navigation only in steps/specs
  - data-cy* attributes ship to prod; never gate them by environment
  - Every flow keeps at least one user-visible assertion (no shadow-API testing)
  - Intercept before action; alias everything; assert response status
  - cy.session always programmatic, always with a validate callback; testIsolation ON
  - Cleanup is seed-owned; after() is best-effort courtesy only

constraints:
  - Never emit cy.wait(ms), ordered tests, or conditional (if-exists) testing
  - Never automate an OAuth provider's UI; programmatic tokens only
  - Attribute gap PRs are cyAttrs-only and separate from spec PRs
  - Never point fixture seams or exploration at production
  - Generated steps/specs carry @generated-assisted markers and require human naming review
  - A spec is "ready" only after 3 consecutive green runs

inputs:
  - App repo (framework, router, auth mechanism)
  - Existing cypress/ setup if any (config, support files, specs)
  - Attribute-schema doc if the project has one (reconcile with selector-schema.md)
  - Flow description or failing-run artifacts, depending on workflow

outputs:
  - commands.ts + type declarations + dual support files + cypress.config.ts
  - cypress/audit/coverage-report.md + annotation-only gap PR
  - cypress/steps/*.ts, cypress/regions/*.ts, cypress/e2e/*.cy.ts
  - cypress/triage/<run-id>.md classification reports
```

---

## Workflow 1: bootstrap-test-architecture

Stand up the target architecture in a repo with no (or throwaway) Cypress setup.

### Trigger

```
"Bootstrap a [Cypress] test architecture for [REPO/APP]" / "set up e2e testing here"
```

### Steps

```yaml
workflow: bootstrap-test-architecture
duration: ~1-2 hours agent time (excludes backend seam PR review)

steps:
  - id: survey
    action: analyze
    description: >
      Read package.json, cypress.config.* if present, auth mechanism (token storage,
      login endpoint), SSR-ness, and any existing attribute usage (grep data-cy).
    output: Architecture notes — which migration stage (references/migration-guide.md) applies

  - id: command-layer
    action: write
    description: >
      Install commands.ts, index.d.ts, dual support files, and cypress.config.ts with
      BOTH component and e2e blocks, from assets/cypress-commands-starter.md, adapted
      to the repo's paths and dev-server port.
    output: cypress/support/*, cypress.config.ts

  - id: app-utils
    action: write
    description: >
      Add src/utils/cypress.ts (cyAttrs/cyFlag from assets/cy-attrs-util.md) if absent,
      plus the hydration flag component when the app is SSR.
    output: cyAttrs util + hydration flag

  - id: session
    action: write
    description: >
      Implement loginAs via cy.session per references/jump-to-sut.md against the app's
      real login endpoint; module token cache; validate callback hitting a whoami route.
    output: cypress/support/auth.ts

  - id: seams
    action: propose
    description: >
      Draft the gated test-support seam design (references/fixture-seams.md) for the
      actual backend stack; open as a separate backend PR or design doc — do not block
      the frontend bootstrap on it.
    output: Seam design/PR

  - id: smoke
    action: write+run
    description: >
      One unauthenticated smoke spec (home renders, hydrated flag) and one authenticated
      smoke spec. Run each 3x consecutively.
    output: cypress/e2e/smoke.cy.ts, 3x green evidence

  - id: lint
    action: write
    description: Add selector-ban ESLint config (assets/eslint-selector-rules.md) at warn level.
    output: ESLint config diff
```

### Output Template

```markdown
## Bootstrap Report — <repo>
- Starting state: <migration stage>
- Installed: commands layer / dual config / cyAttrs util / loginAs session / smoke specs
- Seam status: <designed | PR open | pre-existing>
- Smoke runs: 3/3 green (component), 3/3 green (e2e)
- Next: <ranked next steps from migration-guide.md>
```

---

## Workflow 2: audit-attribute-coverage

Read-only DOM/JSX audit of data-cy* schema compliance; optionally followed by an annotation-only gap PR.

### Trigger

```
"Audit data-cy coverage on [ROUTES]" / "which components are missing test attributes?"
```

### Steps

```yaml
workflow: audit-attribute-coverage
duration: ~30-60 min per route group

steps:
  - id: seed-env
    action: setup
    description: Seed a representative scenario via fixture seams; log in via loginAs. NEVER against prod.
    output: Reachable, populated routes

  - id: walk
    action: browse (read-only)
    description: >
      For each route, walk the DOM checking selector-schema.md rules: interactive
      elements have data-cy; list items have business-stable data-cy-id (flag any
      index-like ids); regions have data-cy-scope; asserted scalars mirrored in
      data-cy-value; portals cross-linked with data-cy-for. Use prompts from
      assets/agent-audit-prompts.md.
    output: Raw findings per route

  - id: score
    action: write
    description: Emit cypress/audit/coverage-report.md with per-route % and ranked gaps (rank by which flows each gap blocks).
    output: coverage-report.md

  - id: gap-pr
    action: write (optional, on request)
    description: >
      cyAttrs-only JSX additions fixing top-ranked gaps. Separate PR from any spec
      work; zero behavior change; note "annotation-only" in the PR description.
    output: Gap PR
```

### Output Template

```markdown
# Attribute Coverage — <date>
| Route | Interactive w/ data-cy | Stable list ids | Regions scoped | Score |
|-------|------------------------|-----------------|----------------|-------|
## Ranked gaps
1. <gap> — blocks <flow> — HIGH
## Non-compliant patterns found
- <e.g. data-cy-id="0" array indexes in SearchResults.tsx>
```

---

## Workflow 3: author-flow-spec

Turn a described (or explored) user flow into steps + spec.

### Trigger

```
"Write an e2e test for [FLOW]" / "cover the [X] journey"
```

### Steps

```yaml
workflow: author-flow-spec
duration: ~1-2 hours per flow

steps:
  - id: preconditions
    action: verify
    description: >
      Confirm the flow's routes are annotated (else run audit-attribute-coverage first),
      a seed scenario exists or can be added, and loginAs covers the needed profile.
    output: Go/no-go + missing-piece list

  - id: trace
    action: browse or read
    description: Walk the flow interactively from seeded state, or consume an existing flows/<flow>.yaml trace.
    output: Ordered act/observe trace incl. every network call to alias

  - id: steps
    action: write
    description: >
      Step functions + region objects per references/step-libraries.md — plain functions,
      intercept-before-action inside any step that triggers a request, no raw selectors.
      Mark @generated-assisted; flag naming for human review (names are API).
    output: cypress/steps/<flow>.ts, cypress/regions/*.ts

  - id: spec
    action: write
    description: >
      seed → loginAs → visitHydrated(deep link) → steps → assertions. At least one
      user-visible assertion at the terminal state; a11y/screenshot checkpoint there only.
      Include the error-path variant via cy.intercept stubs.
    output: cypress/e2e/<flow>.cy.ts

  - id: stabilize
    action: run
    description: Run 3x consecutively; on any red, jump to triage-flaky-test before shipping.
    output: 3x green evidence
```

### Output Template

```markdown
## Flow Spec — <flow>
- Files: steps/<flow>.ts, regions/<...>.ts, e2e/<flow>.cy.ts
- Seed scenario: <name> (new/existing) · Profile: <profile>
- Aliased calls: @<a>, @<b> · Terminal assertion: <user-visible thing>
- Stability: 3/3 green · Naming review needed on: <step names>
```

---

## Workflow 4: triage-flaky-test

Classify and fix an intermittent failure.

### Trigger

```
"[SPEC] is flaky on CI" / "this test fails 1 in N runs"
```

### Steps

```yaml
workflow: triage-flaky-test
duration: ~30-90 min

steps:
  - id: gather
    action: analyze
    description: Collect failing-run artifacts (screenshots, command log, CI timing) and the spec + its steps.
    output: Failure signature (where it fails, how often, CI-vs-local)

  - id: reproduce
    action: run
    description: >
      Re-run with the same seed/profile/entry, 5x. If it never reproduces, run under
      CPU throttle / with cypress run (not open) to widen race windows.
    output: Reproduction rate

  - id: classify
    action: analyze
    description: >
      Classify per network-and-antiflake.md: race (intercept-after-action, .then-assert,
      hydration, saved refs) / stale-session (missing or weak validate) /
      seed-leak (order-dependent data) / regression (deterministic once reproduced).
    output: Classification + evidence

  - id: fix
    action: write
    description: >
      Apply the matching pattern fix in the CORRECT layer (a selector race is a command
      fix; a navigation race is a step fix). Regressions get a bug report, not a test patch.
    output: Fix PR or bug report

  - id: verify
    action: run
    description: 5x consecutive green post-fix (higher bar than authoring, since flake was proven).
    output: Evidence + triage report

  - id: report
    action: write
    description: Emit cypress/triage/<run-id>.md per agentic-exploration.md stage 6.
    output: triage/<run-id>.md
```

### Output Template

```markdown
# Triage: <run-id> — <spec> "<test>"
- Reproduced: <yes/no, rate>
- Classification: race | stale-session | seed-leak | regression
- Evidence: <specific commands/timing>
- Fix: <file:line + pattern applied> or Bug: <report link>
- Post-fix: 5/5 green
```
