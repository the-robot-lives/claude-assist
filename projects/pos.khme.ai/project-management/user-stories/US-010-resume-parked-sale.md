---
id: US-010
title: "Resume a parked sale"
slug: "resume-parked-sale"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "should-have"
complexity: "S"
tags: [park-sale, hold, checkout]
---

# US-010: Resume a Parked Sale

## User Story

**As a** cashier (P-003),
**I want to** reopen a parked sale exactly as I left it,
**So that** I can finish checking out that customer once they are ready.

## Acceptance Criteria

- [ ] Given a sale is parked, when I select it from the held-sales list, then it loads into the active cart with all items, quantities, and discounts intact.
- [ ] Given I resume a parked sale, when I complete payment, then it is removed from the held-sales list.
- [ ] Given a parked sale is older than a merchant-configured threshold, when viewed in the list, then it is visually flagged as stale.

## Notes

Depends on US-009.
