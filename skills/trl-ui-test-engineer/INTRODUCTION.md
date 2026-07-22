---
skill: trl-ui-test-engineer
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
  - codex
  - grok
last_updated: 2026-07-15
---

# UI Test Engineer — Introduction

Architects non-fragile frontend UI test suites, Cypress-centric. It turns an app repo (with or without an existing Cypress setup) into a layered test architecture: a `data-cy*` semantic selector contract shipped in the app, a retrying command vocabulary, flow-level step libraries, backend fixture seams for deterministic data, and validated programmatic sessions. It serves engineers bootstrapping suites, fixing flake, or migrating selector-soup tests, and agents running attribute audits or spec authoring.

## Input Contract

```yaml
inputs:
  arguments:
    - name: task
      type: freeform
      required: true
      description: "What to do: bootstrap suite, audit attributes, author a flow spec, triage a flaky test, design fixture seams"
      example: "audit data-cy coverage on the checkout routes and open a gap PR"

  file_conventions:
    - pattern: "cypress.config.{ts,js}, cypress/**"
      format: custom
      description: "Optional existing Cypress setup (component and/or e2e); absence means bootstrap from assets/"
    - pattern: "docs/**/cypress-attributes.md (or equivalent)"
      format: markdown
      description: "Optional project attribute-schema doc; if present, reconcile with references/selector-schema.md"
      schema: "Six-attribute contract: data-cy, data-cy-id, data-cy-for, data-cy-value, data-cy-scope, data-cy-flag-*"
      example: |
        data-cy="product-card" data-cy-id="sku-123"
        data-cy="stars" data-cy-value="3.6"

  context_expectations:
    - "Frontend app repo (any framework; worked examples are React + Vite)"
    - "Reachable backend or willingness to add gated test-support seams"
    - "Node toolchain able to run Cypress 13/14"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Attribute audit report"
      path: "cypress/audit/coverage-report.md (or project-designated docs dir)"
      format: markdown
      description: "Per-route data-cy* coverage %, ranked gaps, proposed annotations"
    - name: "Command layer"
      path: "cypress/support/commands.ts (+ index.d.ts, support files)"
      format: custom
      description: "Retrying query commands: getByCy, getByCyId, getByCyFor, withinScope, assertion helpers"
    - name: "Step libraries"
      path: "cypress/steps/**/*.ts, cypress/regions/**/*.ts"
      format: custom
      description: "Flow step functions and page-region objects"
    - name: "Fixture-seam design"
      path: "docs or backend PR (e.g. test_support app + endpoints)"
      format: custom
      description: "Gated seed/reset/create endpoints + Cypress seed() wrapper"
    - name: "Specs"
      path: "cypress/e2e/**/*.cy.ts, src/**/*.cy.tsx"
      format: custom
      description: "Flow specs (e2e) and component specs following the three-layer rule"

  side_effects:
    - "Attribute-gap PRs touch app JSX (cyAttrs-only additions, always separate from spec PRs)"
    - "Fixture seams add a gated test-support surface to the backend"

  handoff:
    - skill: trl-story-to-release
      artifact: "Specs"
      description: "Encoded flows become the regression evidence for acceptance-criteria verification"
    - skill: trl-site-walkthrough
      artifact: "Attribute audit report"
      description: "Annotated routes make agent-driven usability walkthroughs navigable"
    - skill: trl-react-engineer
      artifact: "Attribute-gap PR"
      description: "Component owners land cyAttrs annotations during feature work"
```

## Conventions

```yaml
conventions:
  naming:
    - "All data-cy roles and ids are kebab-case; data-cy-id is business-stable (slug/db id), never an array index"
    - "Step files: cypress/steps/<flow>.ts; region files: cypress/regions/<region>.ts"
  structure:
    - "Three-layer rule: selectors only in commands; navigation only in steps/specs; specs never touch raw selectors"
    - "Attribute-gap PRs are annotation-only — never bundled with spec changes"
  anti_patterns:
    - "No cy.wait(ms); no ordered/dependent tests; no conditional testing; no builder-chain DSLs"
    - "Never strip data-cy* from prod builds; never automate the OAuth provider UI; never enable fixture seams in prod"
    - "after() is best-effort courtesy, never the primary cleanup mechanism"
  prerequisites:
    - "For live-backend e2e tiers: fixture seams must exist (or be built first per references/fixture-seams.md)"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you're reading it now) |
| 2 (before executing) | `SKILL.md` | Core stances, decision router, quick-start paths |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | Running a specific workflow |
| 4 (as needed) | `references/*.md` per the SKILL.md decision router | Task-specific depth |
| 5 (bootstrap) | `assets/cypress-commands-starter.md`, `assets/cy-attrs-util.md` | Dropping in the starter kit |

## Quick Examples

### Bootstrap
`/trl-ui-test-engineer bootstrap a Cypress e2e suite for this repo — it currently only has component tests`

### Flake triage
`/trl-ui-test-engineer checkout-spec fails 1 in 5 runs on CI, passes locally — triage it`

### Attribute audit
`/trl-ui-test-engineer audit data-cy coverage on /products and /checkout, open an annotation-only PR`
