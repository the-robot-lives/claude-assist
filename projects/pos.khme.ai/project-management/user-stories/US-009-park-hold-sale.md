---
id: US-009
title: "Park/hold a sale"
slug: "park-hold-sale"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "should-have"
complexity: "M"
tags: [park-sale, hold, multitasking]
---

# US-009: Park/Hold a Sale

## User Story

**As a** cashier (P-003),
**I want to** park an in-progress sale and start a new one,
**So that** I can serve a second customer while the first is still deciding or finding cash.

## Acceptance Criteria

- [ ] Given a cart has items and is not yet paid, when I tap "park sale," then the cart is saved to a held-sales list and the sell screen clears for a new sale.
- [ ] Given one or more sales are parked, when I open the held-sales list, then each entry shows time parked, item count, and total.
- [ ] Given the register goes offline while a sale is parked, when connectivity is unavailable, then the parked sale remains accessible locally without data loss.

## Notes

Depends on US-001. Related: US-010.
