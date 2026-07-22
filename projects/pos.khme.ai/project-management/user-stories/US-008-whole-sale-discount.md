---
id: US-008
title: "Whole-sale discount"
slug: "whole-sale-discount"
personas: [P-002, P-004]
epic: "Register & Checkout"
priority: "could-have"
complexity: "S"
tags: [discount, pricing]
---

# US-008: Whole-Sale Discount

## User Story

**As a** minimart owner (P-002),
**I want to** apply a discount to the entire sale total,
**So that** I can offer a bulk-purchase or loyalty discount at checkout.

## Acceptance Criteria

- [ ] Given a cart has one or more items, when I apply a whole-sale discount, then it is calculated after line-item discounts and shown as a separate summary row.
- [ ] Given a whole-sale discount is applied, when payment is taken, then the discounted total (not the pre-discount total) is what tender is collected against.
- [ ] Given the discount would bring the total below zero, when applied, then the system caps it at the sale subtotal.

## Notes

Related: US-007. Could-have for v1 since line-item discounts cover the more common case.
