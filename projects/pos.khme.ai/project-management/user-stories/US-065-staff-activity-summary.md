---
id: US-065
title: "Staff Activity Summary"
slug: "staff-activity-summary"
personas: [P-002, P-004]
epic: "Staff & Admin"
priority: "should-have"
complexity: "M"
tags: [staff, reporting, audit]
---

# US-065: Staff Activity Summary

## User Story

**As a** minimart owner (P-002),
**I want to** see a per-staff summary of shifts worked, sales rung up, voids/refunds issued, and cash variances over a time period,
**So that** I can spot patterns — like one cashier consistently short, or issuing far more voids than peers — without digging through individual shift reports one by one.

## Acceptance Criteria

- [ ] Given the owner opens the staff activity view, when they select a staff member and date range, then the app shows shift count, total hours, total sales rung, void/refund count and value, and cumulative cash variance.
- [ ] Given the owner views the store-wide staff list, when sorted by variance or void count, then outliers are visually flagged so problem patterns are easy to spot at a glance.
- [ ] Given the owner taps into a staff member's summary, when they drill down, then they land on the filtered [[US-057]] audit log for that staff member.
- [ ] Given a staff member works across multiple stores per [[US-067]], when the owner views their activity, then per-store breakdowns are shown alongside a combined total.

## Notes

Aggregates data from [[US-053]] cash-up reports and [[US-056]] audit events; no new raw data collection. Depends on [[US-063]]/[[US-064]] for shift boundaries.
