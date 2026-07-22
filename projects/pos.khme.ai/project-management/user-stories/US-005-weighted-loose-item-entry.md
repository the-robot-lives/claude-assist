---
id: US-005
title: "Weighted/loose item entry"
slug: "weighted-loose-item-entry"
personas: [P-001, P-008]
epic: "Register & Checkout"
priority: "should-have"
complexity: "M"
tags: [weighted-items, loose-goods, checkout]
---

# US-005: Weighted/Loose Item Entry

## User Story

**As a** market-stall owner (P-001),
**I want to** enter a weight or quantity for loose items like rice or produce,
**So that** the price calculates correctly per kilogram or unit instead of a fixed price.

## Acceptance Criteria

- [ ] Given an item is configured as weight-priced, when I select it, then a numeric entry pad appears for weight (kg/g) instead of adding a flat-price line.
- [ ] Given I enter a weight, when I confirm, then the line total calculates as weight × configured unit price, rounded per the merchant's rounding rule.
- [ ] Given no connected scale is present, when weight entry is manual, then the app clearly labels the entry as manual (not scale-verified) on the receipt.

## Notes

Scale integration (Bluetooth/USB scale hardware) is out of scope for v1 — manual entry only. Related: US-020 (rounding convention).
