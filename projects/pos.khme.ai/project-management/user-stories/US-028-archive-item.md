---
id: US-028
title: "Archive a discontinued item"
slug: "archive-item"
personas: [P-002, P-004]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "S"
tags: [catalog, lifecycle, archive]
---

# US-028: Archive a discontinued item

## User Story

**As a** minimart owner (P-002),
**I want to** archive an item I no longer sell instead of deleting it,
**So that** it disappears from the sell screen and stock counts, but its sales history stays intact for reporting.

## Acceptance Criteria

- [ ] Given an item has stock or sales history, when I choose "Archive" instead of "Delete," then the item is hidden from the register sell screen, stock-count sessions, and reorder suggestions, but historical sales reports still reference it by name.
- [ ] Given an item still has stock on hand, when I try to archive it, then I get a warning showing the remaining quantity and a choice to zero it out (recorded as a shrinkage/write-off adjustment) or archive with stock still logged.
- [ ] Given an item is archived, when I search the catalog, then it does not appear by default but is findable via an "include archived" toggle, and can be unarchived from there.
- [ ] Given a multi-store operator (P-004) archives an item at the chain level, then it is archived across all linked stores unless a store has store-specific stock, in which case each store confirms independently.

## Notes

True deletion is intentionally not offered for items with any transaction history — this preserves report integrity. Zeroing stock on archive creates an adjustment with reason code "discontinued," reusing [[US-033]]. Related: [[US-026]], [[US-027]].
