---
id: US-006
title: "Cart line-item edit"
slug: "cart-line-item-edit"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "S"
tags: [cart, editing]
---

# US-006: Cart Line-Item Edit

## User Story

**As a** cashier (P-003),
**I want to** change the quantity of a cart line or remove it entirely,
**So that** I can correct a customer's order before payment without restarting the sale.

## Acceptance Criteria

- [ ] Given an item is in the cart, when I tap it, then quantity +/- controls and a remove option appear.
- [ ] Given I reduce quantity to zero, when the change is confirmed, then the line is removed from the cart and the total recalculates.
- [ ] Given I remove the last item in the cart, when the cart becomes empty, then the sell screen returns to its default empty state.

## Notes

Distinct from voiding a completed sale (US-014); this covers pre-payment cart editing only. Depends on US-001.
