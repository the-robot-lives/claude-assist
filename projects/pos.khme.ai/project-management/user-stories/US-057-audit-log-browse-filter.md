---
id: US-057
title: "Audit Log Browsing and Filtering"
slug: "audit-log-browse-filter"
personas: [P-002, P-004, P-006]
epic: "Cash & Audit"
priority: "should-have"
complexity: "M"
tags: [audit, trust, reporting]
---

# US-057: Audit Log Browsing and Filtering

## User Story

**As a** multi-store operator (P-004),
**I want to** browse and filter the audit log by store, staff member, action type, and date range,
**So that** I can quickly investigate a specific incident (like a suspicious void pattern) without scrolling through thousands of unrelated events.

## Acceptance Criteria

- [ ] Given the owner opens the audit log, when no filters are applied, then events display newest-first with staff name, action type, a plain-language summary, and timestamp.
- [ ] Given the owner applies filters (store, staff, action type, date range), when they apply them, then the list updates to show only matching events, and the filter combination is shareable/re-runnable.
- [ ] Given the owner taps an individual event, when it expands, then it shows full before/after detail (e.g. old price vs. new price, void reason, drawer variance).
- [ ] Given the owner searches by a specific transaction or item ID, when they enter it, then all related audit events across categories (price change, void, stock adjustment) are surfaced together.

## Notes

Read-only view over the log built by [[US-056]]. For multi-store operators, filtering must scope correctly per [[US-067]] (multi-store staff assignment) so an operator only sees stores they're authorized for.
