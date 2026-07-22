---
id: US-035
title: "Track batches and expiry dates for pharmacy stock"
slug: "batch-expiry-tracking"
personas: [P-008]
epic: "Inventory & Catalog"
priority: "should-have"
complexity: "L"
tags: [inventory, pharmacy, expiry, batch]
---

# US-035: Track batches and expiry dates for pharmacy stock

## User Story

**As a** rural pharmacy owner (P-008),
**I want to** record batch/lot numbers and expiry dates when stock arrives, and be warned as items approach expiry,
**So that** I never sell expired medicine, stay compliant, and can act (discount, return to supplier, dispose) before stock is a total loss.

## Acceptance Criteria

- [ ] Given an item is flagged as "batch-tracked" (typical for medicine), when I record stock-in, then batch/lot number and expiry date are required fields, and each batch is tracked as a distinct sub-quantity within the item's total stock.
- [ ] Given an item has multiple batches with different expiry dates, when a sale is made, then stock deducts using first-expiry-first-out (FEFO) by default, so older stock sells first without the cashier needing to choose manually.
- [ ] Given a batch is within a configurable window of expiry (default 30 days), when I open the dashboard, then that batch appears in an "expiring soon" list sorted by urgency, separate from the general low-stock list.
- [ ] Given a batch has passed its expiry date and is still in stock, when the daily sync runs, then it is automatically excluded from sale on the register (blocked, not just warned) and flagged for write-off via [[US-033]] with reason "expired."

## Notes

Highest-complexity story in this epic — batch as a sub-entity of stock, FEFO deduction logic, and register-side sale blocking all need design. Related: [[US-031]] (batch capture at stock-in), [[US-046]] (expiry could feed the same alert surface as low-stock).
