---
id: US-014
title: "Void a sale or line item"
slug: "void-sale-line-item"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "S"
tags: [void, checkout]
---

# US-014: Void a Sale or Line Item

## User Story

**As a** cashier (P-003),
**I want to** void an item or an entire uncompleted sale before payment is finalized,
**So that** I can correct mistakes without leaving a false completed-sale record.

## Acceptance Criteria

- [ ] Given a sale is not yet paid, when I void the whole sale, then no sale record is created and the register returns to an empty cart.
- [ ] Given a sale has already been paid, when a void is attempted, then the app blocks it and directs the cashier to the refund flow (US-013) instead.
- [ ] Given a void occurs, when it happens, then it is written to the audit trail with cashier ID and timestamp, even though no sale was completed.

## Notes

Distinct from refund (US-013), which applies only to completed sales.
