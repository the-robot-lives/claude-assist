---
id: US-038
title: "Assign a barcode to a catalog item"
slug: "barcode-assignment"
personas: [P-005, P-002]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "M"
tags: [catalog, barcode, scanning]
---

# US-038: Assign a barcode to a catalog item

## User Story

**As a** minimart owner (P-002),
**I want to** link a printed barcode (existing manufacturer barcode or a store-generated one) to a catalog item or variant,
**So that** scanning it at the register or during stock counts instantly identifies the right item.

## Acceptance Criteria

- [ ] Given an item is open for editing, when I scan a barcode using the device camera, then the code is captured and saved against that item/variant without manual typing.
- [ ] Given an item has no manufacturer barcode (common for loose produce or homemade goods), when I choose "generate barcode," then the system creates a unique store-internal code I can print on a sticker.
- [ ] Given I scan a barcode that's already assigned to a different item, when I try to save, then I get a clear conflict warning naming the existing item, preventing accidental duplicate assignment.
- [ ] Given a variant-level item (e.g. different sizes), when I assign barcodes, then each variant can have its own distinct barcode, and scanning correctly resolves to the specific variant, not just the parent item.

## Notes

Feeds the register's scan-to-sell flow (Register & Checkout, US-001–025) and the companion app's scan-unknown-item flow ([[US-042]]), which is the inverse case: unrecognized barcode → identify → create. Related: [[US-026]].
