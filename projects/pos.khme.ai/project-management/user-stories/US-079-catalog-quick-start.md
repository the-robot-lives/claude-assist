---
id: US-079
title: "Catalog quick-start (photograph shelves / scan first items)"
slug: "catalog-quick-start"
personas: [P-001, P-005]
epic: "Onboarding & Setup"
priority: "must-have"
complexity: "L"
tags: [onboarding, catalog, scan, ai]
---

# US-079: Catalog quick-start (photograph shelves / scan first items)

## User Story

**As a** market-stall owner (P-001),
**I want to** quickly build my initial catalog by photographing my shelves or scanning barcodes,
**So that** I don't have to manually type in every item before I can start selling.

## Acceptance Criteria

- [ ] Given the store setup wizard reaches the catalog step, when the user chooses "scan barcode," then each successful scan adds an item with AI-suggested name/category/price fields pre-filled for confirmation.
- [ ] Given the user chooses "photograph shelf" instead, when a photo is uploaded, then the app returns a list of detected candidate items for the user to confirm or discard individually.
- [ ] Given the user has scanned or photographed at least one item, when they tap "finish later," then the catalog quick-start can be resumed from Settings > Catalog without losing progress.

## Notes

Uses the same AI-assisted identification pipeline as the register's "scan unknown item" feature (Inventory epic, other agent's range). Complexity is L due to the AI confirmation UX; decompose further if detection accuracy work grows. Depends on US-077.
