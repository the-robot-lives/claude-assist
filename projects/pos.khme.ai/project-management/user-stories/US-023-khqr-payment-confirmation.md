---
id: US-023
title: "KHQR payment confirmation"
slug: "khqr-payment-confirmation"
personas: [P-002, P-003]
epic: "Payments & Currency"
priority: "must-have"
complexity: "M"
tags: [khqr, bakong, qr-payment, confirmation]
---

# US-023: KHQR Payment Confirmation

## User Story

**As a** cashier (P-003),
**I want to** have the register automatically detect when a KHQR payment has been received,
**So that** I don't have to ask the customer to show proof or guess whether it went through.

## Acceptance Criteria

- [ ] Given a KHQR code is displayed and awaiting payment, when the payment is received, then the sell screen updates to a confirmed state within a few seconds without manual polling by the cashier.
- [ ] Given a payment confirmation has not arrived after a configurable timeout, when the timeout is reached, then the app shows a "not yet confirmed" state and offers manual confirmation-check or cancel.
- [ ] Given a payment is confirmed, when the sale completes, then the transaction record stores the KHQR reference/transaction ID for reconciliation.

## Notes

Depends on US-022. Related: US-024 for what happens if confirmation cannot reach the server.
