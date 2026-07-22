---
id: US-092
title: "Empty states (new store, no sales yet)"
slug: "empty-states"
personas: [P-001]
epic: "Sync, Performance & Edge Cases"
priority: "should-have"
complexity: "S"
tags: [ux, empty-state]
---

# US-092: Empty states (new store, no sales yet)

## User Story

**As a** market-stall owner (P-001) who just finished setup,
**I want** clear, encouraging guidance when my store has no sales or inventory yet,
**So that** I know what to do next instead of seeing a blank or broken-looking screen.

## Acceptance Criteria

- [ ] Given a store has zero catalog items, when the user opens the sell screen, then an empty state prompts them to add their first item (linking to catalog quick-start, US-079) instead of showing a blank grid.
- [ ] Given a store has items but zero completed sales, when the user opens the reports/history screen, then an empty state explains that reports will populate after the first sale, rather than showing an empty chart with no context.
- [ ] Given the empty state is dismissed or the first item/sale is created, when the user returns to that screen, then the empty state does not reappear.

## Notes

Small but high-leverage for the "no manual required" principle — first impressions matter most for novice users like P-001. Depends on US-079.
