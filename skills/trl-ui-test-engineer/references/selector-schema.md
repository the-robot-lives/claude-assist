# Selector Schema — The Six-Attribute Contract

Tests break when they depend on things that change for non-behavioral reasons: class names (styling), DOM position (layout), visible text (copy/i18n). The fix is a semantic attribute contract the app ships as part of its public surface.

## The Six Attributes

| Attribute | Meaning | Cardinality | Example |
|-----------|---------|-------------|---------|
| `data-cy="<role>"` | Semantic **role** of the element (what it *is*) | Many elements share a role | `data-cy="product-card"` |
| `data-cy-id="<id>"` | Unique **instance** identifier | Unique among siblings sharing a role | `data-cy-id="anodized-mug"` |
| `data-cy-for="<id>"` | **Relationship** pointer to another element's `data-cy-id` (like `<label for>`) — expresses logical nesting when DOM nesting is absent (portals, modals, flyout menus) | One per linked element | `data-cy-for="account-menu"` |
| `data-cy-value="<scalar>"` | Machine-readable **asserted value** (rating, count, price) — avoids brittle text parsing, i18n-proof | Optional, on value-bearing elements | `data-cy-value="3.6"` |
| `data-cy-scope` | Marks a container as a logical **region** for `within()` scoping | One per major page region | `data-cy="checkout" data-cy-scope` |
| `data-cy-flag-<name>="<state>"` | Observable **state flag** (hydrated, loading, dirty, open) — turns invisible app state into something tests can wait on | Any number per element | `data-cy-flag-hydrated="true"` |

## Rules

1. **kebab-case** for all roles, ids, and flag names.
2. **`data-cy-id` is business-stable**: slugs, database ids, SKUs. **Never array indexes** — an index encodes ordering, and ordering changes for non-behavioral reasons (sorting, pagination, A/B tests).
3. **Roles describe function, not appearance**: `data-cy="remove-line"`, not `data-cy="red-x-button"`.
4. **`data-cy-value` supplements, never replaces, user-visible assertions.** If a test only reads `data-cy-value`, you've built a shadow API: the attribute can be correct while the rendered UI is broken. Every flow asserts at least one thing a user actually sees.
5. **Ship to prod.** No `NODE_ENV` gating. The attributes power agentic exploration, prod smoke tests, and support tooling reading customer screenshots. Payload cost is bytes; the debugging upside is enormous.
6. **Portals don't matter.** `cy.get('[data-cy=...]')` is document-wide; `data-cy-for` records the *logical* parent so tests (and agents) can traverse the relationship.

## The `cyAttrs` / `cyFlag` Spread Utility

One utility so authors can't mistype attribute names. Drop-in copy in `assets/cy-attrs-util.md`.

```ts
// src/utils/cypress.ts
type Cy = {
  cy?: string;
  cyId?: string | number;
  cyFor?: string | number;
  cyValue?: string | number;
  cyScope?: string;
  cyFlags?: Record<string, string>;
};

export const cyFlag = (flag: string, value: string = 'true') => ({
  [`data-cy-flag-${flag}`]: value,
});

export const cyAttrs = ({ cy, cyId, cyFor, cyValue, cyScope, cyFlags }: Cy = {}) => ({
  ...(cy && { 'data-cy': cy }),
  ...(cyId !== undefined && { 'data-cy-id': String(cyId) }),
  ...(cyFor !== undefined && { 'data-cy-for': String(cyFor) }),
  ...(cyValue !== undefined && { 'data-cy-value': String(cyValue) }),
  ...(cyScope && { 'data-cy-scope': cyScope }),
  ...(cyFlags &&
    Object.fromEntries(
      Object.entries(cyFlags).map(([k, v]) => [`data-cy-flag-${k}`, v]),
    )),
});
```

Design points:
- **Spreadable** — merges cleanly into any JSX element or component that forwards props: `<Button {...cyAttrs({ cy: 'submit-order' })}>`.
- **Reusable components accept `cy`, `cyId`, `cyFor` props** and forward them to the root (or the interactive element if more appropriate). List-item components take a **required** stable `id`/`slug` prop used as `cyId`.
- `cyFlag` is for one-off state flags (`{...cyFlag('hydrated', String(isHydrated))}`); `cyFlags` batches several.

## Enforcement

- ESLint bans class/`nth-*`/text selectors in spec files and nudges annotation on interactive JSX — ready config in `assets/eslint-selector-rules.md`.
- PR checklist: new interactive controls and page regions carry `data-cy`; new list components use domain ids for `data-cy-id`.
- Attribute audits (see `agentic-exploration.md`) measure per-route compliance and rank gaps.

## Worked Example: One Product Card, Three Ways

**Stage 0 — class/index coupling (breaks on restyle or resort):**

```ts
cy.get('.product-grid > div:nth-child(3)').find('.btn-primary').click();
cy.get('.product-grid > div:nth-child(3) .rating').should('contain', '3.6');
```

**Stage 1 — text coupling (breaks on copy change or locale):**

```ts
cy.contains('Anodized Camp Mug').parent().contains('Add to cart').click();
cy.contains('Anodized Camp Mug').parent().should('contain', '3.6 stars');
```

**Stage 2 — full schema (breaks only when behavior breaks):**

```tsx
// ProductCard.tsx
import { cyAttrs } from '@/utils/cypress';

export function ProductCard({ product }: { product: Product }) {
  return (
    <article {...cyAttrs({ cy: 'product-card', cyId: product.slug })}>
      <h3 {...cyAttrs({ cy: 'product-name' })}>{product.name}</h3>
      <span {...cyAttrs({ cy: 'stars', cyValue: product.rating })}>
        {renderStars(product.rating)}
      </span>
      <span {...cyAttrs({ cy: 'price', cyValue: product.priceCents })}>
        {formatPrice(product.priceCents)}
      </span>
      <button {...cyAttrs({ cy: 'add-to-cart', cyFor: product.slug })}>
        Add to cart
      </button>
    </article>
  );
}
```

```ts
// spec — via the command layer (see command-layer.md)
cy.getByCyId('product-card', 'anodized-camp-mug').within(() => {
  cy.getByCy('stars').shouldHaveCyValue(3.6);
  cy.getByCy('price').should('be.visible').and('contain', '$24'); // user-visible assertion
  cy.getByCy('add-to-cart').click();
});
```

Restyle the card, reorder the grid, translate the copy — the Stage 2 spec keeps passing. It fails only when the card's *behavior* fails.

## Cross-Linked (Portaled) UI

```tsx
<MenuButton {...cyAttrs({ cy: 'dropdown-menu', cyId: 'account-menu' })}>Account</MenuButton>
{/* rendered elsewhere via a portal: */}
<MenuList {...cyAttrs({ cy: 'dropdown-menu-list', cyFor: 'account-menu' })}>
  <a {...cyAttrs({ cy: 'dropdown-item', cyId: 'orders' })}>Orders</a>
</MenuList>
```

```ts
cy.getByCyId('dropdown-menu', 'account-menu').click();
cy.getByCyFor('dropdown-menu-list', 'account-menu')
  .should('be.visible')
  .within(() => cy.getByCyId('dropdown-item', 'orders').click());
```

The shared id links trigger and portal regardless of where the portal mounts in the DOM.
