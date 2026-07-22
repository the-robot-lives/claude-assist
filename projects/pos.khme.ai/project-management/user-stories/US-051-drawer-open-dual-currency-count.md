---
id: US-051
title: "Drawer Open with Dual-Currency Starting Count"
slug: "drawer-open-dual-currency-count"
personas: [P-002, P-003]
epic: "Cash & Audit"
priority: "must-have"
complexity: "M"
tags: [cash-management, dual-currency, shift]
---

# US-051: Drawer Open with Dual-Currency Starting Count

## User Story

**As a** cashier (P-003),
**I want to** count and record my starting cash drawer in both KHR and USD when I open my shift,
**So that** there's an agreed, timestamped baseline for later reconciliation and no dispute about what I started with.

## Acceptance Criteria

- [ ] Given a cashier is starting a shift, when they tap "Open Drawer," then the app presents a denomination-by-denomination count entry for both KHR and USD.
- [ ] Given the cashier enters counts for each denomination, when they submit, then the app computes and displays the total in both currencies plus a combined USD-equivalent using the store's configured exchange convention (e.g. 4,000៛/$1).
- [ ] Given the starting count is submitted, when it is saved, then it is written to the audit trail as a "drawer_open" event with staff ID, timestamp, and full denomination breakdown, and cannot be edited afterward.
- [ ] Given a drawer is already open for the register, when a cashier attempts to open a new one without closing the prior shift, then the app blocks the action and prompts to resolve the open shift first.

## Notes

Denomination list is configurable per store (KHR notes/coins in circulation, USD notes accepted). Feeds directly into [[US-052]] (close reconciliation) and [[US-063]] (shift open). Related: [[US-056]] (audit trail).
