---
id: US-030
title: "View current stock levels per item and variant"
slug: "view-stock-levels"
personas: [P-002, P-005]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "M"
tags: [inventory, stock, visibility]
---

# US-030: View current stock levels per item and variant

## User Story

**As a** minimart owner (P-002),
**I want to** see how much of each item (and each of its variants) I currently have on hand,
**So that** I know what to reorder and can spot discrepancies before they become a problem.

## Acceptance Criteria

- [ ] Given I open the stock list, when the screen loads, then each item shows current quantity, unit, and a visual flag (color/icon) for low stock or out-of-stock, sourced from local device state without requiring network access.
- [ ] Given an item has variants, when I expand it, then I see per-variant quantities and a summed parent-level total.
- [ ] Given a sale, stock-in, stock-out, or adjustment has occurred on any synced device, when I view stock levels, then the number reflects the latest synced state and shows a "last updated" timestamp so I know if I'm viewing possibly-stale offline data.
- [ ] Given a stockroom clerk (P-005) views stock levels from the companion app, then the same data is presented in a count-friendly layout (large touch targets, sorted by shelf/category) rather than the register's sales-oriented layout.

## Notes

This is the read model that stock-in ([[US-031]]), stock-out ([[US-032]]), adjustments ([[US-033]]), and sales (Register & Checkout epic, US-001–025) all write into. Offline staleness indicator matters given intermittent connectivity per product principles.
