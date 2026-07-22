---
id: US-024
title: "Payment failure handling offline"
slug: "payment-failure-offline"
personas: [P-001, P-002, P-003]
epic: "Payments & Currency"
priority: "must-have"
complexity: "M"
tags: [offline-first, payment-failure, resilience]
---

# US-024: Payment Failure Handling Offline

## User Story

**As a** market-stall owner (P-001),
**I want to** have the register handle a failed or unconfirmable digital payment gracefully when I lose connectivity,
**So that** I know whether to trust that a sale is paid before letting the customer leave.

## Acceptance Criteria

- [ ] Given a KHQR payment is initiated and connectivity drops before confirmation, when the drop occurs, then the app shows an explicit "unconfirmed — do not release goods" state rather than assuming success or silently failing.
- [ ] Given connectivity returns after an unconfirmed payment, when the app reconnects, then it automatically re-checks the payment status and updates the sale record accordingly.
- [ ] Given a payment ultimately cannot be confirmed, when the cashier chooses to cancel, then no sale record is finalized and the cashier is prompted to collect an alternate tender (cash).

## Notes

Depends on US-015, US-022, US-023. This is a safety-critical edge case — ambiguity here directly risks merchant revenue loss.
