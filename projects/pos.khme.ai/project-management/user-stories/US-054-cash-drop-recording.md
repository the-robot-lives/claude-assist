---
id: US-054
title: "Cash Drop Recording"
slug: "cash-drop-recording"
personas: [P-002, P-003]
epic: "Cash & Audit"
priority: "must-have"
complexity: "S"
tags: [cash-management, dual-currency, shift]
---

# US-054: Cash Drop Recording

## User Story

**As a** cashier (P-003),
**I want to** record when I remove cash from the drawer mid-shift to move it to a safe,
**So that** the drawer's expected balance stays accurate and the owner can see excess cash was secured, not missing.

## Acceptance Criteria

- [ ] Given the drawer is open, when the cashier taps "Cash Drop," then they enter the amount by currency (KHR and/or USD) and an optional note.
- [ ] Given a drop is submitted, when it is saved, then it is timestamped, tied to the active shift, and immediately reduces the expected drawer balance used in [[US-052]] reconciliation.
- [ ] Given a drop is recorded, when it is saved, then it is written to the audit trail as a "cash_drop" event with staff ID, amount, and note, and cannot be edited or deleted afterward.
- [ ] Given a cashier attempts to drop more cash than the drawer's currently expected balance in that currency, when they submit, then the app warns before allowing the drop to proceed.

## Notes

Drops are typically used when drawer cash exceeds a comfort threshold (theft mitigation). Feeds [[US-052]] and [[US-056]]. Related: [[US-055]] (payouts, the inverse flow — cash leaving for expenses rather than safekeeping).
