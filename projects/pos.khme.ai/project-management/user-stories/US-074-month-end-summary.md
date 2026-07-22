---
id: US-074
title: "Month-End Summary"
slug: "month-end-summary"
personas: [P-006, P-002]
epic: "Reporting & Insights"
priority: "should-have"
complexity: "M"
tags: [reporting, bookkeeping, monthly]
---

# US-074: Month-End Summary

## User Story

**As a** bookkeeper (P-006),
**I want to** generate a single month-end summary showing total revenue, cost of goods, gross margin, cash variances, and payouts for the month,
**So that** I have one authoritative document to close the books against instead of assembling it from several daily reports.

## Acceptance Criteria

- [ ] Given the bookkeeper selects a month, when they generate the summary, then it shows total revenue, total cost of goods sold, gross profit, total cash variance (over/short), total payouts, and transaction count — all in both KHR and USD.
- [ ] Given the month is not yet complete (current month, in progress), when the summary is viewed, then it is clearly labeled "month to date" rather than presented as a final close.
- [ ] Given the summary is generated, when the bookkeeper requests it, then it can be exported alongside the [[US-073]] CSV export or shared as a formatted document.
- [ ] Given a store had a discrepancy flagged per [[US-059]] during the month, when the summary is viewed, then flagged incidents are listed in a dedicated section rather than silently folded into the totals.

## Notes

Rolls up [[US-068]], [[US-071]], [[US-073]] into a single period view. Depends on cost-price data quality per [[US-071]]'s "cost unknown" flag.
