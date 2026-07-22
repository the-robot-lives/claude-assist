---
id: US-072
title: "Multi-Store Consolidated Dashboard"
slug: "multi-store-consolidated-dashboard"
personas: [P-004]
epic: "Reporting & Insights"
priority: "should-have"
complexity: "L"
tags: [reporting, multi-store, dashboard]
---

# US-072: Multi-Store Consolidated Dashboard

## User Story

**As a** multi-store operator (P-004),
**I want to** see combined sales, cash variance, and staff activity across all my stores in one dashboard, with the ability to drill into any single store,
**So that** I can spot which locations are underperforming or at risk without logging into each store separately.

## Acceptance Criteria

- [ ] Given the operator opens the consolidated dashboard, when it loads, then it shows combined revenue, transaction count, and cash variance totals across all assigned stores for the selected period.
- [ ] Given the dashboard is displayed, when the operator views the store list, then each store shows its own headline numbers side-by-side for quick comparison, sorted by a selectable metric (e.g. revenue, variance).
- [ ] Given the operator taps into a single store, when selected, then they land on that store's own [[US-068]] daily summary and [[US-057]] audit log, scoped correctly.
- [ ] Given a store has no data for the selected period (e.g. newly opened), when shown in the list, then it displays a clear "no data" state rather than a blank or zero that could be mistaken for zero sales.

## Notes

Aggregates [[US-068]], [[US-053]], and [[US-065]] across stores the operator is assigned to. Depends on [[US-067]] for store-scoping. Currency convention: totals combine KHR/USD using each store's configured exchange rate at time of sale, not a single blended rate.
