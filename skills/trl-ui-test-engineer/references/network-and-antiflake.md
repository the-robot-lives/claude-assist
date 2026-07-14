# Network Discipline & Anti-Flake

Flake is almost never random — it's an unstated race made visible by load. This file is the discipline that removes the races.

## Intercept Discipline

| Rule | Why |
|------|-----|
| **Intercept BEFORE the action that triggers the request** | `cy.intercept` registered after the click can miss the request entirely — the canonical ordering race |
| **Alias everything you'll wait on** | `cy.intercept('POST', '/api/orders/').as('placeOrder')` — waits become deterministic and self-documenting |
| **Assert the response, not just receipt** | `cy.wait('@placeOrder').its('response.statusCode').should('eq', 201)` — a wait that "passed" on a 500 hides the actual failure behind a later DOM assertion |
| **`cy.wait('@alias')` over DOM-settling** | Waiting for a spinner to disappear couples the test to loading-UI implementation; waiting on the aliased request couples it to the actual dependency |
| **`cy.wait(ms)` is banned** | A fixed sleep is a race with a coin flip attached. There is always an observable event (intercept alias, `data-cy-flag-*`, element state) to wait on instead |

```ts
cy.intercept('GET', '/api/search*').as('search');   // 1. intercept
cy.getByCy('apply-filters').click();                 // 2. act
cy.wait('@search').its('response.statusCode').should('eq', 200); // 3. deterministic wait
cy.getByCy('filter-results').should('be.visible');   // 4. assert UI
```

## Retry-Ability Rules

Cypress retries **queries and the assertions chained to them** — anything that breaks that chain reintroduces flake:

1. **No saved element references.** `const btn = cy.getByCy(...)` then using `btn` later operates on a possibly-detached snapshot. Re-query every time; queries are cheap.
2. **Compound assertions go in `.should(callback)`**, which retries as a unit:
   ```ts
   cy.getByCy('cart-line').should(($lines) => {
     expect($lines).to.have.length(2);
     expect($lines.first().attr('data-cy-id')).to.eq('anodized-camp-mug');
   });
   ```
3. **No chain-breaking `.then()` mid-assertion.** `.then()` runs once and does NOT retry — using it to read a value and assert freezes the race:
   ```ts
   // WRONG: .then snapshots once
   cy.getByCy('cart-count').then(($el) => expect($el.text()).to.eq('2'));
   // RIGHT: retried until true or timeout
   cy.getByCy('cart-count').should('have.text', '2');
   ```
   `.then()` is for branching on a *settled* value (post-`cy.wait` response bodies), never for assertions on live DOM.
4. **Conditional testing is banned.** `if ($el.length) {...}` means the test doesn't know what state it's in — seed the state so you do.
5. **`testIsolation` stays ON.** Cross-test state reuse is what `cy.session` and fixture seams are for.

## Worked Example: The SSR Hydration Race

Symptom (Vite SSR, React 18): spec clicks "Add to cart" immediately after `cy.visit`; the click lands, nothing happens, no error — the spec times out waiting for the cart count. Passes locally, fails ~20% on CI.

Cause: with SSR, the element is **visible and actionable before React hydrates**. Cypress's actionability checks pass (it's a real, visible button) but no event handler is attached yet — the click is swallowed. Slower CI machines widen the pre-hydration window, hence the CI-only flake.

Fix — make hydration observable and gate on it:

```tsx
// App shell: flip a flag when hydration completes
function HydrationFlag() {
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => setHydrated(true), []);          // effects run only after hydration
  return <div style={{ display: 'contents' }} {...cyFlag('hydrated', String(hydrated))} />;
}
```

```ts
// support: one guard, used by the standard visit hook (see jump-to-sut.md)
Cypress.Commands.add('visitHydrated', (path: string) => {
  cy.visit(path);
  cy.get('[data-cy-flag-hydrated="true"]', { timeout: 10_000 });
});
```

Alternative when you can't touch the app shell: wait on the first data request the hydrated app always makes (`cy.intercept('GET', '/api/session').as('boot'); cy.visit(path); cy.wait('@boot')`). The flag is preferred — it observes hydration itself, not a proxy.

## Flake Triage Classification

| Class | Signature | Fix |
|-------|-----------|-----|
| **Race** | Fails on slow CI, passes locally; failure point wanders | Intercept-before-action; hydration guard; `.should` not `.then` |
| **Stale session** | First authenticated call 401s; fails only mid-run | Add/repair `cy.session` `validate` callback |
| **Seed leak** | Fails only after certain other specs; wrong entities present | Seed-owned reset; namespace by run id; kill `after()`-dependence |
| **Regression** | Fails deterministically once reproduced with same seed | It's a bug — file it; the test did its job |

Rule: reproduce before you patch; 3 consecutive green runs before you declare a fix.

## Terminal-State Checkpoints (Visual & A11y)

Run expensive whole-page checks only at **flow-terminal states** — the settled screens a flow ends on (order confirmation, populated dashboard) — not after every step:

```ts
payWithSavedCard();
cy.getByCy('order-confirmation').should('be.visible');
// terminal state reached — now checkpoint:
cy.injectAxe();
cy.checkA11y('[data-cy="order-confirmation"]');           // a11y at the settled screen
cy.getByCy('order-confirmation').screenshot('checkout-confirmation'); // visual baseline
```

Per-step screenshots and axe runs multiply runtime and produce diff noise from transient states; terminal-state checkpoints catch the same regressions at a fraction of the cost. Scope screenshots to a `data-cy` region, not the viewport, so unrelated page changes don't churn baselines.
