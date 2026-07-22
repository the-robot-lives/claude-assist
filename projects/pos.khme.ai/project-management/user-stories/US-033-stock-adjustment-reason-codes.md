---
id: US-033
title: "Adjust stock counts with reason codes"
slug: "stock-adjustment-reason-codes"
personas: [P-005, P-002]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "M"
tags: [inventory, adjustment, accountability]
---

# US-033: Adjust stock counts with reason codes

## User Story

**As a** minimart owner (P-002),
**I want to** correct an item's stock count to match reality and be required to select why (damage, theft, expiry, count-correction, gift/sample, other),
**So that** I understand *why* stock is drifting, not just that it is, and can hold staff accountable.

## Acceptance Criteria

- [ ] Given I set a new stock count for an item, when the new count differs from the system count, then I must select a reason code before saving; "no reason" is not a valid option.
- [ ] Given I select "other" as the reason, when I confirm, then a free-text note is required (Khmer or English) so the adjustment isn't left unexplained.
- [ ] Given an adjustment is saved, when I view the item's history, then I see a chronological log of every adjustment with reason, delta, staff member, and timestamp — matching the audit-trail behavior used store-wide.
- [ ] Given a walk-the-shelves count session (companion app) finds a discrepancy, when the clerk submits the count, then it generates adjustment entries automatically using reason code "count-correction," without a separate manual step.

## Notes

Reason-code taxonomy is shared across [[US-032]] (manual stock-out) and this story. Feeds directly into [[US-034]] shrinkage visibility. Cross-epic: full audit trail display lives in Staff & Admin (US-051–075); this story only covers the reason-code capture at point of adjustment.
