---
id: US-043
title: "Complete a guided quick-add for a new item"
slug: "guided-quick-add"
personas: [P-005, P-001]
epic: "Companion App"
priority: "should-have"
complexity: "M"
tags: [companion-app, catalog, onboarding]
---

# US-043: Complete a guided quick-add for a new item

## User Story

**As a** stockroom clerk (P-005),
**I want to** finish adding a newly-identified item to the catalog through a short, guided step-by-step flow,
**So that** I go from "unknown scanned item" to "sellable catalog item with stock" in as few taps as possible.

## Acceptance Criteria

- [ ] Given an item has been identified (via AI suggestion [[US-042]] or manual search), when I proceed to quick-add, then I'm walked through exactly the required fields in sequence (name → category → price → initial quantity), one screen at a time, with sensible defaults pre-filled where possible.
- [ ] Given I accept all AI/system suggestions without editing anything, when I reach the last step, then the whole flow takes no more than 4 taps to complete.
- [ ] Given I want to skip a non-required field (e.g. photo, barcode), when I reach that step, then a clearly labeled "skip" option is always available and never blocks completion.
- [ ] Given a first-time, low-literacy user (P-001) uses quick-add at the register (not just companion app), when the flow renders, then it uses the same icon-first, Khmer-labeled pattern as [[US-026]] for consistency across entry points.
- [ ] Given quick-add completes, when I confirm the final step, then the item is immediately sellable and its initial quantity is recorded as a stock-in entry ([[US-031]]), not silently assumed.

## Notes

This is the "guided quick-add" referenced in the README's scan-unknown-item feature — the destination of the flow started in [[US-042]], but also reachable standalone for items identified by other means (e.g. barcode DB hit with no photo needed). Related: [[US-026]], [[US-038]].
