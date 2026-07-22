---
id: US-070
title: "Sales by Hour/Day"
slug: "sales-by-hour-day"
personas: [P-002, P-004]
epic: "Reporting & Insights"
priority: "should-have"
complexity: "M"
tags: [reporting, sales, staffing]
---

# US-070: Sales by Hour/Day

## User Story

**As a** minimart owner (P-002),
**I want to** see a heatmap-style view of when sales actually happen across the day and week,
**So that** I can schedule staff to match real demand instead of guessing, and know when it's safe to run with a single cashier.

## Acceptance Criteria

- [ ] Given the owner opens the "Sales by Time" view, when a date range is selected, then the app renders a grid of hour-of-day by day-of-week with cell intensity mapped to sales volume.
- [ ] Given the owner taps a specific cell, when it expands, then it shows the actual revenue and transaction count for that hour/day slot.
- [ ] Given the owner switches between "revenue" and "transaction count" as the intensity metric, when toggled, then the heatmap recomputes accordingly.
- [ ] Given a store has fewer than a minimum threshold of days of data, when the view is opened, then the app shows a plain message that more data is needed rather than a misleadingly sparse heatmap.

## Notes

Depends on transaction timestamps from Register/Checkout (US-001–025). Complements [[US-068]] by showing distribution rather than totals. Useful input for future staffing/scheduling features (out of current scope).
