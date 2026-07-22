---
id: US-026
title: "Create catalog item with variants"
slug: "create-item-variant"
personas: [P-002, P-001]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "M"
tags: [catalog, variants, onboarding]
---

# US-026: Create catalog item with variants

## User Story

**As a** minimart owner (P-002),
**I want to** add a new item to my catalog, including any size/flavor/color variants it comes in,
**So that** I can start selling and tracking stock for it without re-entering shared details for every variant.

## Acceptance Criteria

- [ ] Given I am on the "Add item" screen, when I enter a name, category, unit (piece/kg/bottle), and price, then the item saves and appears in the catalog list immediately, offline or online.
- [ ] Given an item has variants (e.g. sizes S/M/L or flavors), when I add variants during creation, then each variant gets its own SKU, price override (optional, inherits base price if blank), and stock counter, while sharing the parent item's name/photo/category.
- [ ] Given I am a first-time user (P-001) with no prior POS experience, when I open "Add item" on my phone, then the form uses icons + Khmer labels and requires only name, price, and unit to save — all other fields are optional and clearly marked "skip for now."
- [ ] Given I try to save an item with a duplicate name in the same category, when I submit, then I get a non-blocking warning ("Similar item exists: ...") but can still save, since duplicate names are legal (e.g. two suppliers' same-named product).

## Notes

Variant creation reuses this same form rather than a separate flow — keeps the "one thing to learn" principle for novice users like Sokha. Barcode assignment is deferred to [[US-038]]. Related: [[US-029]] (categories must exist or be creatable inline), [[US-037]] (dual-currency price entry happens on this same screen).
