# Step Libraries — Sentences Built From Vocabulary

Steps are the middle layer: plain named functions that compose commands into flow verbs. They own navigation; they never own selectors (those live in commands) and never own assertions about business outcomes (those live in specs).

## Two Shapes

| Shape | What it is | When |
|-------|-----------|------|
| **Step function** | A verb: `addToCart(sku)`, `payWithSavedCard()` | The unit of flow reuse; used by ≥2 specs or ≥3 commands long |
| **Page-region object** | A noun with query methods: `cartDrawer.line(sku)`, `cartDrawer.open()` | A region many flows touch; groups its verbs + locator shorthands |

Both are **plain functions/objects of functions**. Each call enqueues Cypress commands and returns `void` (or a chainable when the caller must assert on it). They are NOT classes holding element references, and NOT builder chains.

## When Step vs Region vs Inline Command

```
Is it one command long and used once?          → inline the command in the spec
Is it a multi-command verb reused by flows?    → step function (steps/<flow>.ts)
Is it a region several flows interact with?    → page-region object (regions/<region>.ts)
Does it need a selector not in the vocabulary? → STOP: extend the command layer or the
                                                 attribute schema first, never inline a raw selector
```

## The Blast-Radius Principle

Design steps so that any single UI change forces edits in exactly **one** function. If a redesign of the cart drawer requires touching five specs, the flow knowledge was smeared across the spec layer — pull it down into a step. If it requires touching five steps, the region knowledge was smeared across the step layer — pull it into a region object.

## Anti-Pattern: Builder-Chain DSLs

```ts
// REJECT — fights the command queue
new CheckoutPage().openCart().removeItem('stove').expectCount(1).checkout();
```

Why it's wrong:
- Methods run **synchronously at enqueue time**; any state they capture (`this.count`, saved elements) is stale by the time commands execute.
- Saved element references defeat query retry-ability → detached-element flake.
- The chain implies ordering guarantees Cypress doesn't provide and hides where assertions actually run.

Plain functions get you the same readability with none of the hazards:

```ts
openCartDrawer();
removeCartLine('camp-stove');
cy.getByCy('cart-count').shouldHaveCyValue(1);
checkout();
```

## Worked Example: Checkout Flow

```ts
// cypress/regions/cart-drawer.ts
export const cartDrawer = {
  open() {
    cy.getByCy('cart-toggle').click();
    cy.getByCy('cart-drawer').shouldHaveCyFlag('open');
  },
  line(sku: string) {
    return cy.getByCyId('cart-line', sku);
  },
  removeLine(sku: string) {
    cy.intercept('DELETE', '/api/cart/lines/*').as('removeLine');
    this.line(sku).within(() => cy.getByCy('remove-line').click());
    cy.wait('@removeLine').its('response.statusCode').should('eq', 204);
  },
  subtotal() {
    return cy.getByCy('cart-subtotal');
  },
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
  cy.location('pathname').should('eq', '/checkout');   // navigation lives HERE, not in commands
}

export function fillShipping(address: ShippingAddress) {
  cy.withinScope('shipping-form', () => {
    cy.getByCy('address-line1').type(address.line1);
    cy.getByCy('address-city').type(address.city);
    cy.getByCy('address-zip').type(address.zip);
    cy.getByCy('shipping-continue').click();
  });
}

export function payWithSavedCard() {
  cy.intercept('POST', '/api/orders/').as('placeOrder');
  cy.getByCy('saved-card').click();
  cy.getByCy('place-order').click();
  cy.wait('@placeOrder').its('response.statusCode').should('eq', 201);
}
```

```ts
// cypress/e2e/checkout.cy.ts — the paragraph
import { addToCart, beginCheckout, fillShipping, payWithSavedCard } from '../steps/checkout';
import { cartDrawer } from '../regions/cart-drawer';

it('returning shopper checks out with a saved card', () => {
  cy.seed('checkout-baseline');            // fixture seam, see fixture-seams.md
  cy.loginAs('returning-shopper');         // cy.session, see jump-to-sut.md
  cy.visit('/products/camping');

  addToCart('camp-stove');
  addToCart('anodized-camp-mug');
  cartDrawer.open();
  cartDrawer.removeLine('camp-stove');
  cartDrawer.subtotal().shouldHaveCyValue(2400).and('contain', '$24'); // machine + human

  beginCheckout();
  fillShipping(fixtures.address);
  payWithSavedCard();

  cy.getByCy('order-confirmation').should('be.visible').and('contain', 'Thanks'); // user-visible
});
```

## The Redesign Test

Now simulate a redesign: the cart drawer becomes a full cart *page* at `/cart`, with the same roles annotated.

**Exactly one function changes:**

```ts
// cypress/regions/cart-drawer.ts — only `open` knows how the cart is reached
open() {
  cy.getByCy('cart-toggle').click();
  cy.location('pathname').should('eq', '/cart');
  cy.getByCy('cart-page').should('be.visible');
},
```

`line`, `removeLine`, `subtotal`, every step, and every spec are untouched — because they addressed roles (`cart-line`, `remove-line`) that survived the redesign, and only `open()` knew the drawer was a drawer. That is the blast-radius principle working: measure your step library by how small this diff is.
