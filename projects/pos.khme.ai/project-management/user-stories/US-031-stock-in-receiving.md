---
id: US-031
title: "Record stock-in when receiving goods"
slug: "stock-in-receiving"
personas: [P-005, P-002]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "M"
tags: [inventory, stock-in, receiving]
---

# US-031: Record stock-in when receiving goods

## User Story

**As a** stockroom clerk (P-005),
**I want to** record new stock arriving into an item's count, with quantity and optional unit cost,
**So that** the shop's stock levels stay accurate as soon as goods physically arrive, without waiting for the owner.

## Acceptance Criteria

- [ ] Given I select an item (or scan its barcode), when I enter a quantity received and confirm, then the item's stock level increases immediately and a stock-in entry is logged with who, when, quantity, and source ("manual" or "against PO").
- [ ] Given a purchase order exists for a supplier delivery, when I record stock-in against that PO, then received quantities are matched to expected quantities and any shortfall/overage is flagged rather than silently accepted.
- [ ] Given unit cost is entered at stock-in, when the item's cost basis differs from the previous batch, then the system tracks the new cost for margin reporting without retroactively changing the cost of already-sold units.
- [ ] Given I am offline in the stockroom, when I record stock-in, then it saves locally and syncs when connectivity returns, without blocking further work.

## Notes

Ties to companion-app receiving flow ([[US-040]]) which is the mobile-first version of this same action. PO matching depends on [[US-048]]. Related: [[US-030]].
