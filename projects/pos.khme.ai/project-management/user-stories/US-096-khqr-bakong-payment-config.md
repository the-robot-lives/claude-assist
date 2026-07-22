---
id: US-096
title: "KHQR/Bakong payment provider configuration"
slug: "khqr-bakong-payment-config"
personas: [P-002, P-004]
epic: "Integrations & API"
priority: "should-have"
complexity: "L"
tags: [integration, payments, khqr]
---

# US-096: KHQR/Bakong payment provider configuration

## User Story

**As a** minimart owner (P-002),
**I want to** configure my store to accept KHQR/Bakong QR payments,
**So that** customers who prefer mobile payment over cash can pay directly through the register.

## Acceptance Criteria

- [ ] Given Settings > Payments, when the user enters their Bakong merchant credentials and completes provider verification, then KHQR appears as a payment option on the sell screen.
- [ ] Given a customer chooses to pay via KHQR at checkout, when the cashier generates the QR code for the sale total, then the sale is marked pending until payment confirmation is received (webhook or polling) or the cashier manually confirms.
- [ ] Given a KHQR payment is not confirmed within a configurable timeout, when the timeout elapses, then the sale reverts to unpaid status and the cashier is prompted to retry or switch to cash.

## Notes

Partner requirements/certification path is an open question in the README; this story covers in-app configuration and checkout flow assuming provider access exists. Complexity L — decompose further once Bakong integration specifics are confirmed. Depends on US-085.
