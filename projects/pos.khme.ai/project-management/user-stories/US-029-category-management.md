---
id: US-029
title: "Manage catalog categories"
slug: "category-management"
personas: [P-002, P-004]
epic: "Inventory & Catalog"
priority: "should-have"
complexity: "M"
tags: [catalog, categories, organization]
---

# US-029: Manage catalog categories

## User Story

**As a** minimart owner (P-002),
**I want to** create, rename, reorder, and merge product categories,
**So that** my catalog stays browsable on the sell screen and my stock/sales reports group items in a way that matches how I actually think about my shop.

## Acceptance Criteria

- [ ] Given I am adding a new item, when no matching category exists, then I can create one inline without leaving the item form, and it immediately becomes available for future items.
- [ ] Given I have categories with items assigned, when I reorder categories via drag-and-drop, then the sell screen tab order updates to match, for all staff on all devices after next sync.
- [ ] Given I merge category "Drinks" into "Beverages," when I confirm the merge, then all items reassign to "Beverages," the "Drinks" category is removed, and this reassignment is logged in the audit trail.
- [ ] Given a multi-store operator (P-004) manages categories at the chain level, when they edit a shared category, then all stores using it see the update, but a store may add its own store-only subcategories without affecting siblings.

## Notes

Category set is intentionally small and merchant-defined (not a fixed taxonomy) to fit market-stall vendors selling loosely related goods. Related: [[US-026]], [[US-045]] (reorder suggestions can be filtered by category).
