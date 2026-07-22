---
id: US-034
title: "See shrinkage summary across the shop"
slug: "shrinkage-visibility"
personas: [P-002, P-006]
epic: "Inventory & Catalog"
priority: "should-have"
complexity: "M"
tags: [inventory, shrinkage, reporting]
---

# US-034: See shrinkage summary across the shop

## User Story

**As a** minimart owner (P-002),
**I want to** see a summary of stock lost to damage, theft, and expiry over a chosen time period, broken down by item and reason,
**So that** I can spot patterns (a specific item, a specific shift, a specific staff member) and act before losses grow.

## Acceptance Criteria

- [ ] Given a date range, when I open the shrinkage summary, then I see total shrinkage value (in both KHR and USD) broken down by reason code, ranked by highest-value items first.
- [ ] Given I filter by staff member, when a specific cashier or clerk processed the adjustments, then I can see if shrinkage clusters around their shifts, without this being framed as an accusation — just a data view.
- [ ] Given shrinkage for an item exceeds a merchant-configurable threshold (e.g. >5% of stock in 30 days), when I open the dashboard, then that item is flagged for attention.
- [ ] Given a bookkeeper (P-006) reviewing monthly numbers, when they export the shrinkage summary, then it's available as a simple CSV/PDF alongside other financial reports.

## Notes

Reads from the adjustment log built by [[US-033]] and [[US-032]]; does not introduce new data capture, only aggregation. Cross-epic: sits alongside the broader Reporting epic (US-051–075) and may be surfaced there too — this story defines the inventory-specific view.
