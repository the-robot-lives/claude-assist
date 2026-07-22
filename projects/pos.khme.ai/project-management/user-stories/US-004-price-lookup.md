---
id: US-004
title: "Price lookup without adding to cart"
slug: "price-lookup"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "should-have"
complexity: "S"
tags: [price-check, lookup]
---

# US-004: Price Lookup Without Adding to Cart

## User Story

**As a** cashier (P-003),
**I want to** check an item's price by scanning or searching without adding it to the current sale,
**So that** I can answer a customer's price question mid-transaction.

## Acceptance Criteria

- [ ] Given a sale is in progress, when I open price-check mode and scan an item, then its price displays in an overlay without modifying the cart.
- [ ] Given price-check mode is open, when I dismiss it, then I return to the exact cart state I left, with no items added.
- [ ] Given the item is not found, when the lookup completes, then a clear "not found" message displays in the active UI language.

## Notes

Must not interrupt or reset an in-progress sale — a common failure mode in cheaper POS apps. Related: US-001.
