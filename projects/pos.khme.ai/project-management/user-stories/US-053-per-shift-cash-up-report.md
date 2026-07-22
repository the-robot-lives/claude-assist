---
id: US-053
title: "Per-Shift Cash-Up Report"
slug: "per-shift-cash-up-report"
personas: [P-002, P-006]
epic: "Cash & Audit"
priority: "must-have"
complexity: "M"
tags: [cash-management, reporting, reconciliation]
---

# US-053: Per-Shift Cash-Up Report

## User Story

**As a** minimart owner (P-002),
**I want to** view a single-page report for any completed shift showing opening count, sales breakdown, drops, payouts, closing count, and variance,
**So that** I can review each shift's cash health in one glance without piecing together raw transaction logs.

## Acceptance Criteria

- [ ] Given a shift has been closed, when the owner opens the cash-up report for that shift, then it shows opening balance, gross cash sales, card/QR sales, drops, payouts, expected close, actual close, and variance — each broken out in KHR and USD.
- [ ] Given the owner is viewing the report, when they tap the variance line, then they see the reason note the cashier entered at close (per [[US-052]]).
- [ ] Given multiple shifts occurred in a day, when the owner views the day's shift list, then each shift shows staff name, duration, and variance at a glance, sorted most recent first.
- [ ] Given a report is generated, when the owner requests it, then they can export or share it (e.g. as an image/PDF) for record-keeping.

## Notes

Consumed by [[US-065]] (staff activity summary) and rolled up into [[US-068]] (daily sales summary). Depends on [[US-051]] and [[US-052]].
