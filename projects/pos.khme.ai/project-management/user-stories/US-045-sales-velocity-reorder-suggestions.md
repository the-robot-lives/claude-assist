---
id: US-045
title: "Get sales-velocity-based reorder suggestions"
slug: "sales-velocity-reorder-suggestions"
personas: [P-002, P-004]
epic: "Forecasting & Resupply"
priority: "should-have"
complexity: "L"
tags: [forecasting, reorder, sales-velocity]
---

# US-045: Get sales-velocity-based reorder suggestions

## User Story

**As a** minimart owner (P-002),
**I want to** see, for each item, how soon I'll run out based on recent sales pace and how much I should reorder,
**So that** I restock before I lose sales, without having to eyeball spreadsheets or guess.

## Acceptance Criteria

- [ ] Given an item has at least 14 days of consistent sales history, when I open the reorder dashboard, then it shows "out of X in ~N days" using a rolling average of recent daily sales velocity, with the calculation window configurable (e.g. 7/14/30 days).
- [ ] Given the projected days-to-empty falls under a merchant-set threshold (default 7 days), when I view the dashboard, then that item is surfaced with a suggested reorder quantity, calculated from velocity plus a configurable safety buffer.
- [ ] Given an item has too little sales history (new item, or sparse sales) to project reliably, when I view the dashboard, then it's shown separately as "not enough data yet" rather than given a misleading estimate.
- [ ] Given a multi-store operator (P-004) views reorder suggestions, when they select "all stores," then suggestions are shown per store (velocity differs by location) with an option to roll up into one combined purchase order per shared supplier.

## Notes

This is the highest-complexity forecasting story — velocity calculation, threshold configuration, and confidence gating all need real design work; start with a simple moving average before anything more sophisticated. Feeds [[US-048]] (turn a suggestion into a PO) and [[US-046]] (alerts are the notification layer on top of this same calculation). Related: [[US-049]], [[US-050]].
