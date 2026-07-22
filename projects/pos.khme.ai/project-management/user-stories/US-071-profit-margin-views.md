---
id: US-071
title: "Profit Margin Views"
slug: "profit-margin-views"
personas: [P-002, P-006]
epic: "Reporting & Insights"
priority: "should-have"
complexity: "L"
tags: [reporting, profitability, bookkeeping]
---

# US-071: Profit Margin Views

## User Story

**As a** bookkeeper (P-006),
**I want to** see gross profit margin by item, category, and overall store, based on cost price vs. sale price,
**So that** I can tell the owner which products are actually making money, not just which sell the most.

## Acceptance Criteria

- [ ] Given cost price is recorded for an item (per Inventory epic, US-026–050), when the owner or bookkeeper views its report line, then unit margin and margin percentage are shown alongside units sold and revenue.
- [ ] Given an item has no cost price recorded, when it appears in margin views, then it is clearly flagged as "cost unknown" rather than silently showing 0% or 100% margin.
- [ ] Given the bookkeeper selects a category or the whole store, when viewing margin, then a weighted average margin is computed and shown, distinct from a simple average across items.
- [ ] Given a period-over-period comparison is requested, when selected, then margin trend (improving/declining) is shown per item or category.

## Notes

Depends on cost-price data from Inventory epic (US-026–050) and sales data from Register/Checkout (US-001–025). Margin accuracy is only as good as cost-price data entry discipline — flag "cost unknown" prominently rather than masking gaps.
