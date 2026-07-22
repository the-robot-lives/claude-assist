---
id: US-055
title: "Cash Payout Recording"
slug: "cash-payout-recording"
personas: [P-002, P-003]
epic: "Cash & Audit"
priority: "should-have"
complexity: "S"
tags: [cash-management, dual-currency, shift]
---

# US-055: Cash Payout Recording

## User Story

**As a** cashier (P-003),
**I want to** record small cash payouts from the drawer for things like a supplier delivery or petty expense,
**So that** the drawer's expected balance reflects real cash-outs and I'm not left explaining a shortfall that was actually an approved expense.

## Acceptance Criteria

- [ ] Given the drawer is open, when the cashier taps "Payout," then they enter the amount by currency, a required reason/category, and optionally attach a photo of a receipt.
- [ ] Given a payout is submitted, when it is saved, then it reduces the expected drawer balance used in [[US-052]] reconciliation for that currency.
- [ ] Given a payout exceeds a store-configured limit, when the cashier submits it, then the app requires manager PIN approval before it is recorded (per [[US-062]]).
- [ ] Given a payout is recorded, when it is saved, then it is written to the audit trail as a "cash_payout" event with staff ID, amount, reason, and optional receipt image, and cannot be edited afterward.

## Notes

Distinct from [[US-054]] drops: payouts represent money leaving the business, drops represent money moving to safekeeping. Depends on [[US-062]] for over-limit approvals.
