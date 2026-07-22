---
id: US-041
title: "Run a quick spot-check count"
slug: "spot-check-count"
personas: [P-005, P-004]
epic: "Companion App"
priority: "should-have"
complexity: "M"
tags: [companion-app, counting, spot-check]
---

# US-041: Run a quick spot-check count

## User Story

**As a** stockroom clerk (P-005),
**I want to** quickly count a small, targeted set of items (e.g. high-value or frequently-adjusted ones) without running a full shelf count,
**So that** I can catch problems between full counts with a task that takes minutes, not hours.

## Acceptance Criteria

- [ ] Given I start a spot check, when I choose "suggested items" (system-picked: high shrinkage history, high value, or overdue for count), then I get a short list of 5-15 items rather than the full catalog.
- [ ] Given I count each suggested item, when I enter a quantity, then any delta is shown immediately and, on submission, generates a "count-correction" adjustment just like a full count session ([[US-039]]).
- [ ] Given a multi-store operator (P-004) wants oversight, when they view spot-check history across stores, then they can see how often each store runs spot checks and the average discrepancy rate, as a lightweight trust signal.
- [ ] Given I want to spot-check a specific item myself rather than use suggestions, when I search and select it manually, then it behaves identically to a suggested item.

## Notes

Reuses the counting mechanics of [[US-039]] at smaller scale; "suggested items" logic can start simple (items with any shrinkage in the last 30 days) and doesn't need forecasting-epic sophistication. Related: [[US-034]].
