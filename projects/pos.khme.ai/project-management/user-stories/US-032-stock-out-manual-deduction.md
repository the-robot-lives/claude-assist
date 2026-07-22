---
id: US-032
title: "Record manual stock-out"
slug: "stock-out-manual-deduction"
personas: [P-005, P-002]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "S"
tags: [inventory, stock-out]
---

# US-032: Record manual stock-out

## User Story

**As a** stockroom clerk (P-005),
**I want to** manually remove quantity from an item's stock for reasons other than a sale (breakage, gift, internal use, expired disposal),
**So that** stock counts stay truthful even when goods leave the shop outside a normal transaction.

## Acceptance Criteria

- [ ] Given I select an item, when I record a stock-out with a quantity and reason, then stock decreases immediately and the entry is logged with who, when, quantity, and reason.
- [ ] Given the stock-out quantity would take the item below zero, when I confirm, then I get a warning ("only 3 left, you entered 5") requiring explicit confirmation before it proceeds — never a silent negative-stock save.
- [ ] Given I am offline, when I record a stock-out, then it applies locally immediately and syncs later, consistent with sale behavior.

## Notes

Manual stock-out uses the same reason-code list as adjustments ([[US-033]]) for consistency — this story exists separately because it's a distinct, single-purpose action clerks reach for often. Related: [[US-030]], [[US-034]].
