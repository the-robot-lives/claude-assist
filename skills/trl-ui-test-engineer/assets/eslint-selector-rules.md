# ESLint Selector Rules

Two rule groups: hard bans in spec files (fragile selectors, timing hacks), and a nudge in app JSX (annotate interactive elements). Roll out at `warn`, promote to `error` once existing violations are migrated.

## Spec-File Bans (flat config)

```js
// eslint.config.js (fragment)
export default [
  // ... base config
  {
    files: ['cypress/**/*.cy.{ts,tsx}', 'cypress/{steps,regions,support}/**/*.ts', 'src/**/*.cy.{ts,tsx}'],
    rules: {
      'no-restricted-syntax': [
        'error',
        {
          // cy.get('.class'), cy.get('#id'), cy.get('div.foo')
          selector:
            "CallExpression[callee.object.name='cy'][callee.property.name='get'] > Literal:first-child[value=/^[.#]|\\.[a-zA-Z][\\w-]*|\\[class/]",
          message:
            'Class/id selectors are banned in specs. Add a data-cy role and use cy.getByCy / cy.getByCyId.',
        },
        {
          // cy.get('...:nth-child(2)'), :eq(), :first, :last
          selector:
            "CallExpression[callee.object.name='cy'][callee.property.name='get'] > Literal:first-child[value=/:nth-|:eq\\(|:first|:last/]",
          message:
            'Positional selectors (nth/eq/first/last) are banned — ordering changes for non-behavioral reasons. Use data-cy-id with a business-stable id.',
        },
        {
          // cy.contains(...) as a locator
          selector:
            "CallExpression[callee.object.name='cy'][callee.property.name='contains']",
          message:
            'cy.contains as a locator is copy/i18n-fragile. Locate with getByCy*, then assert visible text with .should("contain", ...) where the text IS the assertion.',
        },
        {
          // cy.wait(1000) — numeric literal argument
          selector:
            "CallExpression[callee.object.name='cy'][callee.property.name='wait'] > Literal:first-child[raw=/^[0-9]/]",
          message:
            'cy.wait(ms) is banned. Wait on an aliased intercept (cy.wait("@alias")) or an observable data-cy-flag-* state.',
        },
        {
          // find('.class') chained inside specs
          selector:
            "CallExpression[callee.property.name='find'] > Literal:first-child[value=/^[.#]/]",
          message:
            '.find(".class") re-introduces markup coupling. Use .within() + getByCy, or extend the command layer.',
        },
      ],
    },
  },
];
```

Notes:
- The `cy.contains` ban is intentionally total in spec files; the sanctioned text-assertion form is `getByCy(...).should('contain', text)`, which the rule does not match.
- If steps/regions live elsewhere, extend `files` — the ban applies to the whole test codebase, not just `*.cy.*`.

## App JSX Nudge (warn)

Flags common interactive elements missing `data-cy` (via literal attribute or `cyAttrs` spread). Heuristic by design — it can't see through deep prop forwarding — so keep it at `warn` and pair with the PR checklist.

```js
  {
    files: ['src/**/*.{tsx,jsx}'],
    ignores: ['src/**/*.cy.{tsx,jsx}', 'src/**/*.test.{tsx,jsx}'],
    rules: {
      'no-restricted-syntax': [
        'warn',
        {
          selector:
            "JSXOpeningElement[name.name=/^(button|select|textarea)$/]" +
            ":not(:has(JSXAttribute[name.name='data-cy']))" +
            ":not(:has(JSXSpreadAttribute CallExpression[callee.name='cyAttrs']))",
          message:
            'Interactive element without a data-cy role. Spread {...cyAttrs({ cy: "<role>" })} (src/utils/cypress.ts).',
        },
        {
          selector:
            "JSXOpeningElement[name.name='input']" +
            ":not(:has(JSXAttribute[name.name='type'][value.value='hidden']))" +
            ":not(:has(JSXAttribute[name.name='data-cy']))" +
            ":not(:has(JSXSpreadAttribute CallExpression[callee.name='cyAttrs']))",
          message:
            'Visible input without a data-cy role. Spread {...cyAttrs({ cy: "<role>" })}.',
        },
      ],
    },
  },
```

## Rollout

1. Land both groups at `warn`; get a violation count baseline.
2. Migrate spec violations opportunistically (flaky spec → migrate while triaging).
3. Promote spec-file rules to `error` when count hits zero; the JSX nudge stays `warn` forever (heuristic).
4. Attribute audits (`references/agentic-exploration.md`) catch what the JSX heuristic can't — the two are complementary, not redundant.
