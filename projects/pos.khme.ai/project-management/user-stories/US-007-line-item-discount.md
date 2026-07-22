---
id: US-007
title: "Line-item discount"
slug: "line-item-discount"
personas: [P-002, P-004]
epic: "Register & Checkout"
priority: "should-have"
complexity: "S"
tags: [discount, pricing]
---

# US-007: Line-Item Discount

## User Story

**As a** minimart owner (P-002),
**I want to** apply a percentage or fixed-amount discount to a single line item,
**So that** I can honor a damaged-goods markdown or promo without changing the catalog price.

## Acceptance Criteria

- [ ] Given a line item is selected, when I apply a discount, then I can choose percent-off or amount-off and see the adjusted line total immediately.
- [ ] Given a discount exceeds the line total, when applied, then the system rejects it and shows the maximum allowed discount.
- [ ] Given a discount is applied, when the receipt prints, then the original price, discount, and net price all appear as separate entries.

## Notes

Discount limits (max %, staff permission to discount) belong to the Staff & Admin epic (US-051-075); this story covers register-side application only.
