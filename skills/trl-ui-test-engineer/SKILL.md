---
name: trl-ui-test-engineer
description: >
  Architect non-fragile frontend UI test suites — Cypress-centric selector schemas, command
  layers, step libraries, fixture seams, and anti-flake discipline. Use this skill
  (/trl-ui-test-engineer) to design UI test architecture, write Cypress e2e/component tests,
  add data-cy attributes, fix flaky tests, build test commands or page/step objects, design
  fixture seams, or audit attribute coverage — even without the words "test architecture."
  Also trigger on: cy.session, cy.intercept, selector strategy, test isolation, seeded test
  data. NOT for unit-test frameworks, usability walkthroughs (trl-site-walkthrough), acceptance-
  criteria verification (trl-story-to-release), or React implementation (trl-react-engineer).
---

# UI Test Engineer

Build UI test suites that survive redesigns: semantic selectors, a fluent command vocabulary, seeded fixture seams, and zero tolerance for flake.

## Overview

Most UI test suites die the same death: selectors coupled to markup, waits coupled to timing, data coupled to whatever happened to be in the database. This skill teaches a target architecture where the app exposes a stable semantic contract (`data-cy*` attributes), tests speak a three-layer language (commands → steps → specs), and test data flows through explicit backend seams instead of shared mutable state. It provides:

- **Selector schema** — a six-attribute `data-cy*` contract that decouples tests from markup, styling, and copy
- **Command layer** — retrying query commands (`getByCy`, `getByCyId`, `withinScope`) that make specs read like English
- **Step libraries** — flow-level functions and page-region objects with bounded blast radius under redesign
- **Fixture seams** — gated backend endpoints for seed/reset/create so tests own their data
- **Anti-flake discipline** — intercept-first networking, `cy.session` with validation, retry-ability rules
- **Agentic workflows** — agent-driven attribute audits, exploration traces, spec codegen, and failure triage

## Core Philosophy

1. **Three-layer rule** — Commands are *vocabulary*, steps are *sentences*, specs are *paragraphs*. No command embeds navigation. No step embeds selectors. No spec touches raw selectors. Each layer only speaks the layer below it.
2. **The app ships its test contract** — `data-cy*` attributes ship to production. They power agentic exploration, prod smoke tests, and support tooling; the byte cost is noise. Never gate them by `NODE_ENV`.
3. **Fluent means functions, not builders** — "Fluent" = well-named plain functions plus retrying query commands. Builder-pattern method chains (`page.openCart().addItem().checkout()`) fight Cypress's command queue and retry model; reject them.
4. **Attributes supplement, never replace, the user's view** — `data-cy-value` gives machine-readable assertions, but every flow keeps at least one user-visible assertion (visible text, visible state). Otherwise you build a shadow API that passes while the UI is broken.
5. **Determinism over cleverness** — Every test owns its data (seeded via fixture seams), its session (programmatic, validated), and its network expectations (aliased intercepts). Nothing depends on another test having run.

## When to Use This Skill

- **Bootstrapping a suite** — new app or an app with tests worth throwing away; you want the target architecture from day one
- **Fixing flaky tests** — intermittent failures, timing hacks, `cy.wait(3000)` graveyards
- **Attribute annotation** — adding or auditing `data-cy*` coverage across components
- **Authoring flows** — writing e2e or component specs for a specific user journey
- **Designing fixture seams** — the backend has no test-support endpoints and tests share state
- **Migrating a rough suite** — component-only Cypress, selector soup, documented-but-unimplemented commands

> For verifying a shipped story against its acceptance criteria, see **trl-story-to-release** (`skills/trl-story-to-release/SKILL.md`). For human-lens usability walkthroughs, see **trl-site-walkthrough** (`skills/trl-site-walkthrough/SKILL.md`). For implementing the React components themselves, see **trl-react-engineer** (`skills/trl-react-engineer/SKILL.md`).

## Core Stances (Non-Negotiable)

These hold even when no reference file is loaded:

| Stance | Rule |
|--------|------|
| Three-layer rule | Commands = vocabulary, steps = sentences, specs = paragraphs. Selectors live ONLY in the command layer; navigation lives ONLY in steps/specs. |
| Ship attributes to prod | `data-cy*` attributes are part of the production build. Zero visual impact, minuscule payload, huge exploration/debugging upside. |
| Fluent ≠ builder chains | Plain named functions + `Cypress.Commands.addQuery` retrying queries. Builder DSLs that return `this` break retry-ability and queue semantics. |
| One human assertion per flow | `data-cy-value`/`data-cy-flag-*` assertions are supplements. Every flow asserts at least one thing a user actually sees. |
| Stub-vs-live tiering | Component tests: fully stubbed. E2e happy paths: live backend via fixture seams. E2e error/edge paths: `cy.intercept` stubs. |
| Sessions are programmatic and validated | `cy.session` setup logs in via API (never the form), ALWAYS provides a `validate` callback, and sets `cacheAcrossSpecs` deliberately. `testIsolation` stays ON. |

**Hard rejects** — refuse these patterns and explain why:

- `cy.wait(<ms>)` — wait on an aliased intercept or an observable state flag instead
- Ordered/dependent tests — every spec runs green in isolation and in any order
- Conditional testing (`if element exists then...`) — tests assert known state; seed it
- Stripping `data-cy*` in production builds
- Automating the Google/OAuth provider UI — use a programmatic token; at most one stubbed OAuth smoke test
- `after()`/`afterEach()` as the primary cleanup mechanism — cleanup is seed-owned (reset before, not after); `after()` is best-effort courtesy only

## Decision Router

| Situation | Go to |
|-----------|-------|
| Annotating components / choosing attribute names | `references/selector-schema.md` |
| Writing or reviewing custom commands | `references/command-layer.md` |
| Organizing steps, page regions, flow functions | `references/step-libraries.md` |
| Tests share data / no way to seed state | `references/fixture-seams.md` |
| Login is slow / sessions go stale / deep-linking | `references/jump-to-sut.md` |
| A test is flaky / timing hacks / SSR hydration races | `references/network-and-antiflake.md` |
| Using an agent to explore, audit, or triage | `references/agentic-exploration.md` |
| Starting from scratch or migrating a rough suite | `references/migration-guide.md` |
| Want the whole picture end to end | `references/worked-example-storefront-suite.md` |

## The Three Layers at a Glance

```
spec (paragraph)      "a returning shopper checks out with a saved card"
  │  calls steps, asserts outcomes, owns the narrative
  ▼
steps (sentences)     addToCart(sku) · openCartDrawer() · payWithSavedCard()
  │  compose commands into flow verbs; own navigation
  ▼
commands (vocabulary) cy.getByCy('cart-drawer') · cy.getByCyId('cart-line', sku)
  │  own ALL selectors; retrying queries; no navigation
  ▼
app contract          data-cy · data-cy-id · data-cy-for · data-cy-value ·
                      data-cy-scope · data-cy-flag-*
```

## Stub vs Live Policy

| Tier | Backend | Data | Purpose |
|------|---------|------|---------|
| Component tests | Fully stubbed (`cy.intercept` everything) | Inline fixtures | Contract of one component |
| E2e happy paths | Live backend | Seeded via fixture seams | Prove the integrated flow |
| E2e error/edge paths | `cy.intercept` stubs for the failing call | Seeded baseline + stubbed failure | 500s, timeouts, empty states |
| Prod/staging smoke | Live, read-mostly | Real (no seams in prod, ever) | Deployment gate |

## Quick Start Guides

### Bootstrap a suite (new or throwaway-quality existing)
1. Read `references/migration-guide.md` for the ROI ordering
2. Drop in `assets/cy-attrs-util.md` (React util) and `assets/cypress-commands-starter.md` (commands + dual config)
3. Annotate the two or three highest-traffic routes per `references/selector-schema.md`
4. Implement programmatic login per `references/jump-to-sut.md`
5. Author the first happy-path spec per `references/step-libraries.md` + `references/worked-example-storefront-suite.md`

### Fix a flaky test
1. Read `references/network-and-antiflake.md`
2. Classify: race (intercept after action?), stale session (missing `validate`?), seed leak (shared data?), genuine regression
3. Apply the matching fix pattern; run 3 consecutive green runs before calling it fixed

### Run an attribute audit
1. Read `references/selector-schema.md` for the compliance rules
2. Follow the `audit-attribute-coverage` workflow in `references/agent-playbook.claude-code.md`, using prompts from `assets/agent-audit-prompts.md`
3. Ship gap fixes as an attributes-only PR — never mixed with spec changes

## Reference Guide

### When to Read Each Reference

| Task | Read These |
|------|-----------|
| **Attribute naming & annotation** | `selector-schema.md` |
| **Custom command design** | `command-layer.md` |
| **Step/page-region organization** | `step-libraries.md` |
| **Backend seed/reset endpoints** | `fixture-seams.md` |
| **Login, sessions, deep links** | `jump-to-sut.md` |
| **Flake triage, intercepts, SSR races** | `network-and-antiflake.md` |
| **Agent-driven audit/explore/triage** | `agentic-exploration.md` |
| **Migration sequencing & CI budget** | `migration-guide.md` |
| **Full end-to-end demonstration** | `worked-example-storefront-suite.md` |
| **Running agent workflows** | `agent-playbook.claude-code.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-story-to-release** — verifies acceptance criteria on shipped stories; hands flows here to be encoded as regression specs
- **trl-site-walkthrough** — human-lens usability walkthroughs; complementary to (not replaced by) automated flows
- **trl-react-engineer** — implements the components this skill annotates; receives attribute-gap PRs
- **trl-api-designer** — designs the real API surface; fixture-seam endpoints follow its conventions but are test-only
- **trl-threat-modeler** — review fixture-seam gating (env flag + shared secret) before exposing seams on shared environments

## Bundled Resources

### References
- [selector-schema.md](references/selector-schema.md) — the six-attribute `data-cy*` contract, `cyAttrs`/`cyFlag` util, ESLint bans
- [command-layer.md](references/command-layer.md) — retrying query commands, failure diagnostics, dual component/e2e construction
- [step-libraries.md](references/step-libraries.md) — step functions, page-region objects, blast-radius design
- [fixture-seams.md](references/fixture-seams.md) — gated backend test-support endpoints, seeding, cleanup ownership
- [jump-to-sut.md](references/jump-to-sut.md) — `cy.session`, programmatic login, deep-link entry, OAuth stance
- [network-and-antiflake.md](references/network-and-antiflake.md) — intercept discipline, retry-ability, SSR hydration, a11y/visual checkpoints
- [agentic-exploration.md](references/agentic-exploration.md) — six-stage hybrid loop: explore → audit → gap PR → codegen → author → triage
- [migration-guide.md](references/migration-guide.md) — ROI-ordered rough→ideal path, test-tier taxonomy, CI budget
- [worked-example-storefront-suite.md](references/worked-example-storefront-suite.md) — checkout flow through the full stack
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — agent role + 4 executable workflows

### Assets
- [cy-attrs-util.md](assets/cy-attrs-util.md) — drop-in typed `cyAttrs`/`cyFlag` React utility
- [cypress-commands-starter.md](assets/cypress-commands-starter.md) — commands.ts, type declarations, dual support files, cypress.config.ts
- [eslint-selector-rules.md](assets/eslint-selector-rules.md) — ready-to-paste selector bans + JSX annotation nudge
- [agent-audit-prompts.md](assets/agent-audit-prompts.md) — prompt templates for exploration, audit, and triage runs
- [project-tracker.md](assets/project-tracker.md) — progress tracking template
