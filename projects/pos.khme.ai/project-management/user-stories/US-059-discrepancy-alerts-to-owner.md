---
id: US-059
title: "Discrepancy Alerts to Owner"
slug: "discrepancy-alerts-to-owner"
personas: [P-002, P-004]
epic: "Cash & Audit"
priority: "should-have"
complexity: "M"
tags: [audit, notifications, reconciliation]
---

# US-059: Discrepancy Alerts to Owner

## User Story

**As a** minimart owner (P-002),
**I want to** get notified as soon as a cash variance, unusual void pattern, or large stock adjustment happens,
**So that** I can follow up same-day instead of discovering a problem weeks later when it's much harder to trace.

## Acceptance Criteria

- [ ] Given a drawer closes with a variance exceeding the store-configured threshold, when reconciliation completes, then the owner receives an in-app (and, if configured, push) notification naming the shift, staff member, and variance amount.
- [ ] Given a staff member issues an unusually high number of voids or refunds within a shift (configurable threshold), when the threshold is crossed, then the owner is alerted with a link to the relevant audit events.
- [ ] Given an owner configures alert thresholds, when they save changes, then thresholds apply per-store for owners managing multiple locations.
- [ ] Given an alert is triggered, when the owner taps it, then they land directly on the relevant [[US-053]] cash-up report or [[US-057]] filtered audit log, not a generic dashboard.

## Notes

Depends on [[US-052]] (variance detection) and [[US-057]] (audit filtering) as the underlying data sources. Threshold configuration lives alongside store settings (Onboarding/Settings epic, US-076–100).
