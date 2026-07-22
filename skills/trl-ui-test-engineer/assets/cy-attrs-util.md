# cyAttrs / cyFlag — Drop-In React Utility

Copy to `src/utils/cypress.ts`. Spread into any JSX element or prop-forwarding component. See `references/selector-schema.md` for the attribute contract these implement.

```ts
// src/utils/cypress.ts
// Test attribute utility — implements the six-attribute data-cy* contract.
// These attributes SHIP TO PROD. Do not gate by NODE_ENV.

type Cy = {
  /** Semantic role: what the element IS (kebab-case). e.g. 'product-card' */
  cy?: string;
  /** Business-stable instance id (slug/db id — NEVER an array index) */
  cyId?: string | number;
  /** Relationship pointer to another element's data-cy-id (portals, menus, modals) */
  cyFor?: string | number;
  /** Machine-readable scalar for assertions (rating, count, cents) */
  cyValue?: string | number;
  /** Marks a logical region for within()-scoping; value names the scope */
  cyScope?: string;
  /** Observable state flags: { hydrated: 'true', open: 'false' } → data-cy-flag-* */
  cyFlags?: Record<string, string>;
};

/** Single state flag: {...cyFlag('hydrated', String(isHydrated))} */
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

## Usage

```tsx
import { cyAttrs, cyFlag } from '@/utils/cypress';

// role only
<button {...cyAttrs({ cy: 'submit-order' })}>Place order</button>

// role + stable instance id
<article {...cyAttrs({ cy: 'product-card', cyId: product.slug })} />

// scoped region
<section {...cyAttrs({ cy: 'checkout', cyScope: 'checkout' })} />

// asserted value (i18n-proof)
<span {...cyAttrs({ cy: 'stars', cyValue: rating })}>{renderStars(rating)}</span>

// portal cross-link
<MenuButton {...cyAttrs({ cy: 'dropdown-menu', cyId: 'account-menu' })} />
<MenuList   {...cyAttrs({ cy: 'dropdown-menu-list', cyFor: 'account-menu' })} />

// state flag
<div {...cyFlag('hydrated', String(isHydrated))} />
```

## SSR Hydration Flag Companion

For SSR apps (see `references/network-and-antiflake.md`), mount once in the app shell:

```tsx
// src/components/HydrationFlag.tsx
import { useEffect, useState } from 'react';
import { cyFlag } from '@/utils/cypress';

export function HydrationFlag() {
  const [hydrated, setHydrated] = useState(false);
  useEffect(() => setHydrated(true), []); // effects only run post-hydration
  return <div style={{ display: 'contents' }} {...cyFlag('hydrated', String(hydrated))} />;
}
```

## Reusable-Component Contract

Components that render an addressable thing accept and forward `cy` / `cyId` / `cyFor`; list-item components require a stable `id`/`slug`:

```tsx
type CardProps = React.PropsWithChildren<{ slug: string; cy?: string }>;

export function Card({ slug, cy = 'card', children }: CardProps) {
  return <div {...cyAttrs({ cy, cyId: slug })}>{children}</div>;
}
```
