---
id: US-068
title: "Daily Sales Summary"
slug: "daily-sales-summary"
personas: [P-001, P-002]
epic: "Reporting & Insights"
priority: "must-have"
complexity: "M"
tags: [reporting, sales, dual-currency]
---

# US-068: Daily Sales Summary

## User Story

**As a** market-stall owner (P-001),
**I want to** see a simple summary of today's total sales, transaction count, and payment method split as soon as I close up,
**So that** I know how the day went without needing to understand anything about reports — just the numbers that matter.

## Acceptance Criteria

- [ ] Given the owner opens the "Today" view, when sales exist for the day, then it shows total revenue (KHR and USD), transaction count, and average sale size, updating live as sales happen.
- [ ] Given the owner views the payment breakdown, when they look at the summary, then cash, KHQR/QR, and card totals are each shown separately alongside the combined total.
- [ ] Given the owner wants to see a prior day, when they navigate to a specific date, then the same summary format applies with a clear "past day, view-only" indication.
- [ ] Given the summary is displayed, when totals span multiple shifts, then the figures reconcile with the sum of each shift's [[US-053]] cash-up report for that day.

## Notes

This is the entry-point report — must be legible to a novice, phone-only, Khmer-only user like P-001 with zero learning curve. Rolls up shift-level data from [[US-053]]. Related: [[US-070]] (hourly breakdown), Register/Checkout epic for the underlying transaction records (US-001–025).
