---
id: US-017
title: "End-of-sale / next-customer flow"
slug: "end-of-sale-flow"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "S"
tags: [checkout, workflow]
---

# US-017: End-of-Sale / Next-Customer Flow

## User Story

**As a** cashier (P-003),
**I want to** have the register clearly close out a completed sale and reset for the next customer,
**So that** I never accidentally add a new customer's items to a prior transaction.

## Acceptance Criteria

- [ ] Given payment is confirmed, when the sale completes, then a clear success confirmation displays (amount, change due, receipt status) before the cart clears.
- [ ] Given the confirmation is dismissed or times out, when the next screen loads, then the cart is guaranteed empty with no leftover items or discounts.
- [ ] Given a shift handover occurs mid-flow, when a new cashier logs in, then the sell screen still reflects a clean, correctly reset state.

## Notes

Depends on US-019/US-020 for payment confirmation content. Related: shift-handover stories in the Staff & Admin epic (US-051-075).
