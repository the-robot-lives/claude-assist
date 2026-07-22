---
id: US-052
title: "Drawer Close with Expected-vs-Actual Reconciliation"
slug: "drawer-close-expected-vs-actual"
personas: [P-002, P-003]
epic: "Cash & Audit"
priority: "must-have"
complexity: "L"
tags: [cash-management, dual-currency, reconciliation, shift]
---

# US-052: Drawer Close with Expected-vs-Actual Reconciliation

## User Story

**As a** cashier (P-003),
**I want to** count my drawer at end of shift and see it compared against what the system expects based on recorded sales, drops, and payouts,
**So that** I know immediately whether I'm balanced, and can explain any difference before I walk away — not get blamed for a mismatch discovered days later.

## Acceptance Criteria

- [ ] Given a cashier taps "Close Drawer," when the count screen opens, then the app shows the expected KHR and USD totals (opening count + cash sales − drops − payouts + payins) without revealing them until the cashier submits their own physical count first (blind count).
- [ ] Given the cashier enters their physical denomination count, when they submit, then the app shows expected vs. actual per currency and the variance (over/short) in both KHR and USD-equivalent.
- [ ] Given a variance exists, when the cashier closes the drawer, then the app requires a short reason/note before the shift can be finalized.
- [ ] Given the drawer is closed, when it is saved, then it is written to the audit trail as an immutable "drawer_close" event including both counts, variance, and reason, feeding [[US-053]]'s cash-up report.
- [ ] Given a variance exceeds a store-configured threshold, when the drawer closes, then a discrepancy alert is triggered per [[US-059]].

## Notes

Blind count (cashier counts before seeing expected total) reduces anchoring and is core to the trust-through-transparency principle. Depends on [[US-051]]. Related: [[US-054]], [[US-055]] (drops/payouts feed the expected total).
