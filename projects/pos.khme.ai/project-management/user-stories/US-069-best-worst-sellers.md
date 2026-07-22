---
id: US-069
title: "Best/Worst Sellers"
slug: "best-worst-sellers"
personas: [P-002, P-006]
epic: "Reporting & Insights"
priority: "should-have"
complexity: "M"
tags: [reporting, sales, inventory]
---

# US-069: Best/Worst Sellers

## User Story

**As a** minimart owner (P-002),
**I want to** see which items sell the most and which barely move, over a period I choose,
**So that** I know what to keep stocked up on and what's quietly tying up shelf space and cash.

## Acceptance Criteria

- [ ] Given the owner opens the best/worst sellers view, when they select a date range, then the app ranks items by units sold and by revenue, with both views toggleable.
- [ ] Given an item has zero or near-zero sales in the selected range, when the "worst sellers" list is shown, then it surfaces those items with current stock-on-hand alongside so the owner can decide whether to discount or drop them.
- [ ] Given the owner filters by category, when applied, then rankings recompute within that category only.
- [ ] Given an item is trending down sharply compared to the prior period, when viewing the list, then it is flagged with a simple indicator (e.g. a down arrow) rather than requiring the owner to compare two reports manually.

## Notes

Depends on transaction data from Register/Checkout (US-001–025) and stock levels from Inventory (US-026–050). Related: [[US-071]] (profit margin adds a "profitable but low-volume" lens on top of raw units/revenue).
