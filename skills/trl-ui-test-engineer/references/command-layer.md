# Command Layer — Retrying Vocabulary

The command layer is the ONLY place selectors exist. It exposes a small vocabulary of retrying queries plus assertion helpers, and it must work identically in component and e2e modes.

## Queries vs Actions — the Load-Bearing Distinction

| API | Retries? | Use for |
|-----|----------|---------|
| `Cypress.Commands.addQuery` | **Yes** — the returned function is re-invoked until assertions pass or timeout | Anything that *locates* elements (`getByCy*`) |
| `Cypress.Commands.add` | **No** — runs once, only inner queries retry | Actions and composition (`withinScope`, seeding, login) |

If you implement `getByCy` with `add`, the selector resolves once; a re-render that replaces the element yields detached-element flake. **Locators are always queries.** This single mistake is the most common cause of "our custom commands made things flakier."

## commands.ts (full implementation)

```ts
// cypress/support/commands.ts  — shared by component AND e2e support files
/// <reference types="cypress" />

type QueryOpts = { timeout?: number; log?: boolean };

function cyState(key: string): any {
  return (cy as any).state(key);
}

function describeSiblings(role: string): string {
  const doc: Document = cyState('document');
  const ids = Cypress.$(`[data-cy="${role}"]`, doc)
    .map((_, el) => el.getAttribute('data-cy-id') ?? '(no id)')
    .get();
  return ids.length
    ? `Existing [data-cy="${role}"] instances: ${ids.join(', ')}`
    : `No [data-cy="${role}"] elements exist in the DOM.`;
}

function makeQuery(
  name: string,
  message: string,
  selector: string,
  role: string,
  opts: QueryOpts = {},
) {
  return function (this: Cypress.Command) {
    const log =
      opts.log !== false &&
      Cypress.log({ name, message, type: 'parent', timeout: opts.timeout });
    this.set('timeout', opts.timeout ?? Cypress.config('defaultCommandTimeout'));

    return (subject?: JQuery<HTMLElement>) => {
      const doc: Document = cyState('document');
      const $el: JQuery<HTMLElement> = subject?.length
        ? subject.find(selector)
        : Cypress.$(selector, doc);

      if ($el.length === 0) {
        // Thrown errors are retried until timeout; the LAST error is what the
        // developer reads — so make it name the semantic role and its siblings.
        throw new Error(`${name}: expected ${selector}. ${describeSiblings(role)}`);
      }
      if (log) {
        log.set({
          $el,
          consoleProps: () => ({ Selector: selector, Yielded: $el, Count: $el.length }),
        });
      }
      return $el;
    };
  };
}

Cypress.Commands.addQuery('getByCy', function (role: string, opts: QueryOpts = {}) {
  return makeQuery('getByCy', role, `[data-cy="${role}"]`, role, opts).call(this);
});

Cypress.Commands.addQuery('getByCyId', function (role: string, id: string | number, opts: QueryOpts = {}) {
  const sel = `[data-cy="${role}"][data-cy-id="${id}"]`;
  return makeQuery('getByCyId', `${role}#${id}`, sel, role, opts).call(this);
});

Cypress.Commands.addQuery('getByCyFor', function (role: string, forId: string | number, opts: QueryOpts = {}) {
  const sel = `[data-cy="${role}"][data-cy-for="${forId}"]`;
  return makeQuery('getByCyFor', `${role}→${forId}`, sel, role, opts).call(this);
});

// Composition: not a locator, so a plain command. Inner getByCy retries.
Cypress.Commands.add('withinScope', (scope: string, fn: () => void) => {
  cy.get(`[data-cy="${scope}"][data-cy-scope]`, { log: false }).within(fn);
});

// Cross-linked pair (trigger + portaled mate) — yields both, retried as a unit.
Cypress.Commands.addQuery('pair', function (role: string, id: string | number) {
  const rootSel = `[data-cy="${role}"][data-cy-id="${id}"]`;
  const mateSel = `[data-cy="${role}-list"][data-cy-for="${id}"]`;
  Cypress.log({ name: 'pair', message: `${role}#${id}` });
  return () => {
    const doc: Document = cyState('document');
    const root = Cypress.$(rootSel, doc);
    const mate = Cypress.$(mateSel, doc);
    if (!root.length || !mate.length) {
      throw new Error(`pair: missing ${!root.length ? rootSel : mateSel}. ${describeSiblings(role)}`);
    }
    return { root, mate };
  };
});

// Assertion helpers — child commands wrapping .should so specs stay English.
Cypress.Commands.add(
  'shouldHaveCyValue',
  { prevSubject: 'element' },
  (subject, expected: string | number) =>
    cy.wrap(subject, { log: false }).should('have.attr', 'data-cy-value', String(expected)),
);

Cypress.Commands.add(
  'shouldHaveCyFlag',
  { prevSubject: 'element' },
  (subject, flag: string, expected: string = 'true') =>
    cy.wrap(subject, { log: false }).should('have.attr', `data-cy-flag-${flag}`, expected),
);
```

Type declarations and both support files: `assets/cypress-commands-starter.md`.

## Design Rules

1. **One `Cypress.log` per command.** The inner resolution runs `log: false`; the command's own log entry carries a consolidated `consoleProps` table (selector, yielded, count). Command Log noise is a real cost — a spec of 40 commands should read like 40 lines of English, not 200 lines of `get`.
2. **Failure messages are diagnostics.** "Expected `[data-cy="cart-line"][data-cy-id="mug"]`. Existing cart-line instances: `tent, stove`" tells you *the seed put the wrong items in the cart* without opening the runner.
3. **Dual-mode by construction.** Commands resolve relative to the current subject/`within` context, never call `cy.visit`, and never reference URLs. The same `commands.ts` is imported by `cypress/support/component.ts` and `cypress/support/e2e.ts`. Navigation belongs to steps/specs.
4. **No element caching.** Queries yield fresh jQuery results on every retry; never store `$el` in a variable across commands.

## Positioning vs @testing-library/cypress

Complementary, not competing:

| Concern | Tool |
|---------|------|
| "Is this component accessible — does it expose the right roles/names?" | `findByRole` / `findByLabelText` in **component tests** (asserts the a11y contract) |
| "Locate instance `sku-123` of role `product-card` in a full app flow" | `getByCyId` in **e2e** (plumbing that must not depend on copy or locale) |

Use both: component tests prove the a11y contract with Testing Library; e2e flows navigate via `data-cy` so i18n and copy edits can't break them.

## Worked Example: Before / After

**Before — selector soup (real pattern from a rough suite):**

```ts
it('removes an item', () => {
  cy.get('.cart-drawer .ant-list-item').eq(1).find('.anticon-delete').click();
  cy.wait(500);
  cy.get('.cart-drawer .ant-badge-count').should('contain', '1');
});
```

Breaks on: antd upgrade, item reorder, icon swap, a slow network beat.

**After — fluent vocabulary:**

```ts
it('removes an item', () => {
  cy.intercept('DELETE', '/api/cart/lines/*').as('removeLine');
  cy.withinScope('cart-drawer', () => {
    cy.getByCyId('cart-line', 'camp-stove').within(() => {
      cy.getByCy('remove-line').click();
    });
  });
  cy.wait('@removeLine').its('response.statusCode').should('eq', 204);
  cy.getByCy('cart-count').shouldHaveCyValue(1).and('contain', '1'); // machine + human
});
```

Every locator retries; the network wait is deterministic; the assertion is both machine-readable and user-visible.
