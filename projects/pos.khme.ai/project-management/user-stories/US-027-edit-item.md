---
id: US-027
title: "Edit existing catalog item"
slug: "edit-item"
personas: [P-002, P-003]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "S"
tags: [catalog, edit]
---

# US-027: Edit existing catalog item

## User Story

**As a** minimart owner (P-002),
**I want to** update an item's name, price, category, or photo after it's already in the catalog,
**So that** I can correct mistakes and react to supplier price changes without recreating the item and losing its sales/stock history.

## Acceptance Criteria

- [ ] Given an item exists in the catalog, when I open it and change the price, then the new price applies to future sales only — past receipts and reports still show the price at time of sale.
- [ ] Given I edit an item while offline, when connectivity returns, then the change syncs and, if another device edited the same item in the meantime, the most recent edit wins and the overwritten version is retained in the audit log (not silently discarded).
- [ ] Given a cashier (P-003) without manager permissions opens an item, when they try to change price or cost, then the field is read-only or requires a manager PIN, per the store's permission settings.

## Notes

Price-change audit entries feed the store-wide audit trail (Staff & Admin epic, US-051–075) — this story only covers the edit UI and versioning, not the audit log display itself. Related: [[US-026]], [[US-028]].
