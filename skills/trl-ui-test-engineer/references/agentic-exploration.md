# Agentic Exploration — The Six-Stage Hybrid Loop

Because `data-cy*` attributes ship to prod and fixture seams are HTTP, an agent with browser automation can explore, audit, and triage the same app your specs test — using the same contract. This is the loop; prompt templates live in `assets/agent-audit-prompts.md`.

```
(1) explore ──► (2) attribute audit ──► (3) gap PR ──► (4) step codegen ──► (5) spec authoring ──► (6) failure triage
     │                                                                                                  │
     └────────────────────────── seams + schema shared with the human-authored suite ◄──────────────────┘
```

## Stage 1 — Explore

Agent (browser automation) walks the app **from a seeded state**, using the SAME fixture seams as specs (`POST /__test__/seed/` etc.) — never ad-hoc data. It records what it did as an interaction trace.

**Artifact:** `cypress/flows/<flow>.yaml`

```yaml
flow: checkout-saved-card
seed: checkout-baseline
profile: returning-shopper
entry: /products/camping
trace:
  - act: click
    target: { cy: add-to-cart, cyFor: camp-stove }
    observed: { cy: cart-count, cyValue: "1" }
  - act: click
    target: { cy: cart-toggle }
    observed: { cy: cart-drawer, cyFlag: { open: "true" } }
  - act: click
    target: { cy: begin-checkout }
    observed: { path: /checkout }
terminal: { cy: order-confirmation, visibleText: "Thanks" }
gaps:
  - route: /checkout
    element: "shipping form city input"
    problem: "no data-cy; located by placeholder text"
```

## Stage 2 — Attribute Audit

DOM walk per route checking schema compliance (`selector-schema.md`): interactive elements carry `data-cy`; list items carry business-stable `data-cy-id`; regions carry `data-cy-scope`; asserted values mirrored in `data-cy-value`. **Read-only** — audits never modify the app.

**Artifact:** `cypress/audit/coverage-report.md`

```markdown
| Route | Interactive w/ data-cy | List items w/ stable id | Regions scoped | Score |
|-------|-----------------------|------------------------|----------------|-------|
| /products/camping | 14/16 (88%) | 12/12 | 2/3 | 86% |
| /checkout | 6/11 (55%) | n/a | 0/2 | 41% |

## Ranked gaps
1. /checkout shipping-form: 5 unannotated inputs (blocks checkout flow specs)  — HIGH
2. /checkout missing data-cy-scope regions                                     — MED
3. /products sort dropdown portal missing data-cy-for                          — MED
```

## Stage 3 — Gap PR

Fix gaps with `cyAttrs`-only additions to JSX. **ALWAYS a separate PR from spec changes** — annotation PRs are trivially reviewable (zero behavior change, spread-only diffs) and land fast; mixing them with specs couples an easy review to a hard one.

## Stage 4 — Step Codegen

Generate step functions from the flow YAML: each `act` group becomes a step body using the command vocabulary; `observed` entries become the step's internal waits. **A human reviews the naming before merge — names are API.** `addToCart` vs `clickAddButton` is the difference between a step library and a macro recorder; the agent proposes, the human names.

## Stage 5 — Spec Authoring

Compose the standard skeleton: `seed → session → deep-link → steps → assert` (with at least one user-visible assertion at the terminal state). A generated spec is **ready** only after **3 consecutive green runs** — one green run proves nothing about a race.

## Stage 6 — Failure Triage

On a red run, the agent reproduces interactively (same seed, same profile, same entry), then classifies per the taxonomy in `network-and-antiflake.md`: **race / stale-session / seed-leak / regression**.

**Artifact:** `cypress/triage/<run-id>.md`

```markdown
# Triage: run 8841 — checkout.cy.ts "pays with saved card"
- Reproduced: yes (2/5 interactive attempts, same seed)
- Classification: race
- Evidence: click on [data-cy=place-order] fired before @placeOrder intercept registered;
  passes when intercept moved above payWithSavedCard()
- Fix: move cy.intercept into payWithSavedCard (steps/checkout.ts:31) — PR #412
- Not a regression: order API returns 201 in all reproductions
```

## Guardrails

- **Never point exploration at prod seams** — prod has no seams (see `fixture-seams.md` gating); exploration runs against local/CI/staging-with-seams only.
- **Mark generated code**: `/** @generated-assisted — reviewed by <human> */` on codegen'd steps/specs, so future readers know the provenance.
- **Audits are read-only**; only Stage 3 touches app code, and only with `cyAttrs` spreads.
- Agent runs use their own run-id namespace so their seeds never collide with spec runs.

## Investment Ordering

Stages **2 (audit)** and **6 (triage)** compound — every audit raises the floor for all future flows, and every triage hardens the suite. Stage 1 discovery is largely **one-time per app area**; stages 4–5 are per-flow. So: run the audit early and repeatedly (it's cheap and read-only), wire triage into CI failure handling, and treat exploration as a bootstrap tool rather than a perpetual process.
