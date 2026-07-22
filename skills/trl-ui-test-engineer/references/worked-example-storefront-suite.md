# Worked Example — Storefront Checkout Through the Full Stack

One flow, every layer: attribute audit → annotation → command layer → steps/regions → seeded session spec. The app is a React 18 + Vite SSR storefront with a DRF backend (`Authorization: Token` auth).

## 1. Audit Finding

Agent audit (per `agentic-exploration.md`) on `/checkout`:

```markdown
| Route     | Interactive w/ data-cy | Regions scoped | Score |
|-----------|-----------------------|----------------|-------|
| /checkout | 6/11 (55%)            | 0/2            | 41%   |

Ranked gaps:
1. shipping form: line1/city/zip inputs + continue button unannotated  — HIGH
2. no data-cy-scope on shipping-form / payment regions                 — MED
3. saved-card tile missing data-cy-id (uses card last4 in text only)   — MED
```

## 2. Annotation (gap PR — attributes only)

```tsx
// src/pages/checkout/ShippingForm.tsx
import { cyAttrs } from '@/utils/cypress';

export function ShippingForm({ onContinue }: Props) {
  return (
    <section {...cyAttrs({ cy: 'shipping-form', cyScope: 'checkout' })}>
      <input {...cyAttrs({ cy: 'address-line1' })} {...register('line1')} />
      <input {...cyAttrs({ cy: 'address-city' })} {...register('city')} />
      <input {...cyAttrs({ cy: 'address-zip' })} {...register('zip')} />
      <button {...cyAttrs({ cy: 'shipping-continue' })} type="submit">Continue</button>
    </section>
  );
}

// src/pages/checkout/PaymentStep.tsx
{cards.map((card) => (
  <button key={card.id} {...cyAttrs({ cy: 'saved-card', cyId: card.id })}>
    •••• {card.last4}
  </button>
))}
<span {...cyAttrs({ cy: 'order-total', cyValue: totalCents })}>{formatPrice(totalCents)}</span>
<button {...cyAttrs({ cy: 'place-order' })}>Place order</button>
```

Zero behavior change; reviewed and merged same day, independent of any spec work.

## 3. Command Layer (already in place)

From `command-layer.md` / `assets/cypress-commands-starter.md`: `getByCy`, `getByCyId`, `withinScope`, `shouldHaveCyValue`, `shouldHaveCyFlag` — shared by component and e2e support files. Nothing flow-specific is added here; the vocabulary is generic on purpose.

## 4. Seeding + Session Preamble

Backend scenario (in the gated `test_support` app, see `fixture-seams.md`):

```python
# test_support/scenarios.py
def checkout_baseline(namespace: str) -> dict:
    catalog = ensure_products(namespace, slugs=["camp-stove", "anodized-camp-mug"])
    return {"products": [p.slug for p in catalog]}
```

Note the seed does NOT create the user or the saved card — `create-account` with profile `returning-shopper` does (a returning shopper *is* a user with an address and a saved card). Seams stay orthogonal: scenarios own catalog/world state; profiles own account state.

## 5. Regions and Steps

```ts
// cypress/regions/cart-drawer.ts — see step-libraries.md for the full listing
export const cartDrawer = {
  open() {
    cy.getByCy('cart-toggle').click();
    cy.getByCy('cart-drawer').shouldHaveCyFlag('open');
  },
  line: (sku: string) => cy.getByCyId('cart-line', sku),
  subtotal: () => cy.getByCy('cart-subtotal'),
};
```

```ts
// cypress/steps/checkout.ts
import { cartDrawer } from '../regions/cart-drawer';

export function addToCart(sku: string) {
  cy.intercept('POST', '/api/cart/lines/').as('addLine');
  cy.getByCyId('product-card', sku).within(() => cy.getByCy('add-to-cart').click());
  cy.wait('@addLine').its('response.statusCode').should('eq', 201);
}

export function beginCheckout() {
  cartDrawer.open();
  cy.getByCy('begin-checkout').click();
  cy.location('pathname').should('eq', '/checkout');
}

export function fillShipping(a: { line1: string; city: string; zip: string }) {
  cy.withinScope('shipping-form', () => {
    cy.getByCy('address-line1').clear().type(a.line1);
    cy.getByCy('address-city').clear().type(a.city);
    cy.getByCy('address-zip').clear().type(a.zip);
    cy.getByCy('shipping-continue').click();
  });
}

export function payWithSavedCard(cardId: string) {
  cy.intercept('POST', '/api/orders/').as('placeOrder');
  cy.getByCyId('saved-card', cardId).click();
  cy.getByCy('place-order').click();
  cy.wait('@placeOrder').its('response.statusCode').should('eq', 201);
}
```

## 6. The Spec

```ts
// cypress/e2e/checkout.cy.ts
import { addToCart, beginCheckout, fillShipping, payWithSavedCard } from '../steps/checkout';
import { cartDrawer } from '../regions/cart-drawer';

describe('checkout', () => {
  beforeEach(() => {
    cy.seed('checkout-baseline');
    cy.loginAs('returning-shopper');            // cy.session: API token → localStorage, validated
    cy.visitHydrated('/products/camping');       // SSR guard: waits data-cy-flag-hydrated
  });

  it('returning shopper pays with a saved card', function () {
    addToCart('camp-stove');
    addToCart('anodized-camp-mug');

    cartDrawer.open();
    cartDrawer.subtotal().shouldHaveCyValue(7900).and('contain', '$79.00'); // machine + human

    beginCheckout();
    fillShipping({ line1: '1 Main St', city: 'Boston', zip: '02110' });

    payWithSavedCard('card-primary'); // profile seam creates the card with this deterministic id

    // terminal state: one user-visible assertion, then checkpoints
    cy.getByCy('order-confirmation')
      .should('be.visible')
      .and('contain', 'Thanks for your order');
    cy.getByCy('order-number').should(($el) => {
      expect($el.attr('data-cy-value')).to.match(/^ORD-\d+$/);
    });
    cy.injectAxe();
    cy.checkA11y('[data-cy="order-confirmation"]');
    cy.getByCy('order-confirmation').screenshot('checkout-confirmation');
  });

  it('shows a payment failure without losing the cart', () => {
    addToCart('camp-stove');
    beginCheckout();
    fillShipping({ line1: '1 Main St', city: 'Boston', zip: '02110' });

    // edge tier: live baseline + stubbed failure (never seed a "broken" backend)
    cy.intercept('POST', '/api/orders/', {
      statusCode: 402,
      body: { detail: 'card_declined' },
    }).as('placeOrder');

    cy.getByCy('place-order').click();
    cy.wait('@placeOrder');

    cy.getByCy('payment-error').should('be.visible').and('contain', 'declined');
    cy.getByCy('cart-count').shouldHaveCyValue(1);   // cart survived the failure
  });
});
```

## What Each Layer Bought

| Change later | Diff required |
|--------------|---------------|
| Cart drawer becomes a `/cart` page | `cartDrawer.open()` only |
| antd → different component lib | Nothing (roles survive; classes were never referenced) |
| Copy/i18n overhaul | Only the two deliberate user-visible assertions — re-point to the new copy |
| Checkout API returns new shape | `payWithSavedCard` + the seed scenario |
| Login form redesign | Nothing (login is programmatic; the form has its own dedicated spec) |

The spec reads as the product manager would narrate the flow — that's the acceptance test for the architecture itself.
