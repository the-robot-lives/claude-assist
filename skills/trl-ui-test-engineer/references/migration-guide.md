# Migration Guide — Rough → Ideal, ROI-Ordered

You rarely start from zero; you start from a suite that half-exists. This is the sequencing that pays for itself at every step — each stage delivers standalone value even if you stop there.

## The Reference Starting State

The worked ordering below is keyed to a realistic "rough" storefront (composite of common real-world states):

| Aspect | Rough state |
|--------|-------------|
| App | React 18 + Vite SSR storefront, antd + bootstrap mixed |
| Cypress | v14, **component-mode only** — no e2e config block at all |
| Attributes | `cyAttrs` already spread through 175 files (good bones!) |
| Commands | Fluent commands **documented but unimplemented** — specs use raw `cy.get('[data-cy=...]')` and worse |
| Fixtures | **Zero seams** — component tests stub inline; nothing can seed a backend |
| Auth | Django/DRF, `Authorization: Token` from localStorage; form login + Google OAuth; no `cy.session` |

Diagnosis: the *app contract* (attributes) is ahead of the *test architecture* (no vocabulary, no e2e, no seams, no sessions). The plan exploits that: attributes are the expensive part and they're already there.

## The Six Stages

| # | Stage | Effort | Unlocks | Reference |
|---|-------|--------|---------|-----------|
| 1 | **Implement the command layer** | Hours | Every existing component test can migrate to `getByCy*`; the documented API becomes real | `command-layer.md`, starter in `assets/cypress-commands-starter.md` |
| 2 | **Add the e2e config block** alongside component | Hours | `cypress open --e2e` works; shared support file means commands work in both modes immediately | `assets/cypress-commands-starter.md` |
| 3 | **Programmatic-login `cy.session`** | ~1 day | Authenticated e2e without form click-through; the DRF token pattern drops straight in | `jump-to-sut.md` |
| 4 | **Carve fixture seams** | Days (backend PR) | Deterministic e2e data; the gated `test_support` app + `cy.seed` wrapper | `fixture-seams.md` |
| 5 | **Step libraries** | Per-flow | Specs become paragraphs; blast-radius bounded for the redesigns that are coming | `step-libraries.md` |
| 6 | **Agent attribute audit** | Cheap, repeatable | Finds the gaps in those 175 files (annotation ≠ compliance); gap PRs raise the floor for all future flows | `agentic-exploration.md` |

Why this order:
- **1 before everything**: without vocabulary, every later artifact is written in selector soup you'll rewrite.
- **2 before 3/4**: sessions and seams only matter to e2e; the config block is an hour of work.
- **3 before 4**: login is the single biggest per-spec time sink and needs no backend changes (the token endpoint exists); seams need a backend PR cycle.
- **4 before 5 at scale**: you can write one or two happy-path steps against manually-arranged data, but a step *library* against nondeterministic data just industrializes flake.
- **6 whenever**: read-only and compounding — run it as soon as an agent and a seeded environment exist; formally it's last because gap PRs are most valuable once flows are being authored.

**Anti-pattern**: starting with "rewrite all the old specs." Old specs migrate opportunistically — when they flake or when their flow gets a step library. Rewriting first burns the budget before any architecture exists.

## Test-Tier Taxonomy & CI Budget

| Tier | What | Backend | Runtime target |
|------|------|---------|----------------|
| Component | One component's contract, Testing Library + stubs | Fully stubbed | < 5 min total |
| Smoke e2e | Login session + 3–5 critical happy paths | Live + seams | < 5 min |
| Core flows | All primary journeys (checkout, account, search) | Live + seams | < 20 min |
| Edge/error e2e | 500s, timeouts, empty states via intercept stubs | Live baseline + stubs | < 20 min |
| Full matrix | Everything + a11y + visual checkpoints + browsers | Live + seams | Nightly-scale |

**CI budget:**

| Gate | Runs |
|------|------|
| Every PR | Component + smoke e2e (~10 min ceiling — beyond this, engineers stop waiting and start bypassing) |
| Merge to main | Core flows + edge/error |
| Nightly | Full matrix, 3× repetition on recently-changed specs (flake detection) |

## Worked Example: First Two Weeks on the Reference Storefront

**Week 1**
1. Land `commands.ts` + `index.d.ts` from the starter kit; wire into the existing `cypress/support/component.ts` (stage 1). Migrate the 3 noisiest component specs to `getByCy*` as proof.
2. Add the `e2e` block to `cypress.config.ts` with `baseUrl` pointing at the dev server; shared support imports (stage 2). First e2e spec: unauthenticated smoke — home page renders, `data-cy-flag-hydrated` flips true (this immediately surfaces the SSR hydration race — fix per `network-and-antiflake.md`).
3. Implement `loginAs` with `cy.session` against the existing DRF token endpoint; module token cache + `validate` hitting `/api/users/me/` (stage 3). Second e2e spec: authenticated smoke. Add the one stubbed Google OAuth callback test; delete any ambition to automate the real provider.

**Week 2**
4. Backend PR: `test_support` app with `create-account` / `seed-entities` / `reset-state`, gated by `TEST_SUPPORT_ENABLED` + `X-Test-Support-Key`, run-id namespacing (stage 4). Meanwhile: ESLint selector bans land (`assets/eslint-selector-rules.md`) — warn-level first, error after the noisy specs migrate.
5. Seams merged → first real flow: checkout happy path as `steps/checkout.ts` + `regions/cart-drawer.ts` + one paragraph spec (stage 5, full listing in `worked-example-storefront-suite.md`). 3 consecutive green runs before it gates anything.
6. Agent audit over `/products` and `/checkout` (stage 6): despite `cyAttrs` in 175 files, the checkout form scores ~40% — annotation-only gap PR opened, reviewed in minutes.

End state after two weeks: PR gate = component + 2 smoke specs; merge gate = checkout flow; a compliance report that tells you exactly where the next flow will hurt. Every subsequent flow is now a per-flow cost, not an architecture cost.
