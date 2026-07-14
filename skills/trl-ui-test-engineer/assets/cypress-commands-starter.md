# Cypress Commands Starter Kit

Four files: shared commands, type declarations, dual support files, and a config with BOTH component and e2e blocks. Rationale and design rules in `references/command-layer.md`.

## cypress/support/commands.ts

```ts
/// <reference types="cypress" />
// Shared by component AND e2e support files. Locators are QUERIES (retry);
// composition/actions are commands (no retry — their inner queries retry).

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

Cypress.Commands.add('withinScope', (scope: string, fn: () => void) => {
  cy.get(`[data-cy="${scope}"][data-cy-scope]`, { log: false }).within(fn);
});

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

export {};
```

## cypress/support/index.d.ts

```ts
/// <reference types="cypress" />

declare global {
  namespace Cypress {
    interface Chainable<Subject = any> {
      /** Query (retries): all elements with data-cy=role, within current subject if any */
      getByCy(role: string, opts?: { timeout?: number; log?: boolean }): Chainable<JQuery<HTMLElement>>;
      /** Query (retries): the instance data-cy=role + data-cy-id=id */
      getByCyId(role: string, id: string | number, opts?: { timeout?: number; log?: boolean }): Chainable<JQuery<HTMLElement>>;
      /** Query (retries): the element data-cy=role linked via data-cy-for=forId */
      getByCyFor(role: string, forId: string | number, opts?: { timeout?: number; log?: boolean }): Chainable<JQuery<HTMLElement>>;
      /** Scope a callback to a data-cy-scope region */
      withinScope(scope: string, fn: () => void): Chainable<void>;
      /** Assert data-cy-value equals expected (retries via .should) */
      shouldHaveCyValue(expected: string | number): Chainable<JQuery<HTMLElement>>;
      /** Assert data-cy-flag-<flag> equals expected (default 'true') */
      shouldHaveCyFlag(flag: string, expected?: string): Chainable<JQuery<HTMLElement>>;
      /** Visit and wait for the SSR hydration flag (e2e support only) */
      visitHydrated(path: string): Chainable<void>;
    }
  }
}

export {};
```

## cypress/support/component.ts

```ts
import './commands';
import '@testing-library/cypress/add-commands'; // findByRole etc. — a11y contract in component tests
import { mount } from 'cypress/react18';

Cypress.Commands.add('mount', mount);

declare global {
  namespace Cypress {
    interface Chainable {
      mount: typeof mount;
    }
  }
}
```

## cypress/support/e2e.ts

```ts
import './commands';
// e2e-only plumbing lives here — commands.ts stays navigation-free by design:
// import './auth';   // loginAs (references/jump-to-sut.md)
// import './seams';  // seed/createAccount (references/fixture-seams.md)

Cypress.Commands.add('visitHydrated', (path: string) => {
  cy.visit(path);
  cy.get('[data-cy-flag-hydrated="true"]', { timeout: 10_000 });
});
```

## cypress.config.ts

```ts
import { defineConfig } from 'cypress';

export default defineConfig({
  video: false,
  retries: { runMode: 1, openMode: 0 }, // 1 CI retry surfaces flake without hiding it; triage anything that needed the retry

  e2e: {
    baseUrl: 'http://localhost:5173',
    supportFile: 'cypress/support/e2e.ts',
    specPattern: 'cypress/e2e/**/*.cy.{ts,tsx}',
    testIsolation: true, // stays ON — cy.session + seams make isolation cheap
    env: {
      apiUrl: 'http://localhost:8000',
      testSupportKey: process.env.TEST_SUPPORT_KEY, // never hardcode; never set in prod
      runId: process.env.CI ? `ci-${process.env.CI_RUN_ID}` : undefined,
    },
  },

  component: {
    devServer: { framework: 'react', bundler: 'vite' },
    supportFile: 'cypress/support/component.ts',
    specPattern: 'src/**/*.cy.{ts,tsx}',
  },
});
```

## Install Notes

- Dependencies: `cypress` (13/14), `@testing-library/cypress` (component tier), `typescript`.
- Add `cypress/support/index.d.ts` to the tsconfig `include` used by spec files.
- Adapt `baseUrl`/`apiUrl`/dev-server framework to the project; nothing else should need editing.
