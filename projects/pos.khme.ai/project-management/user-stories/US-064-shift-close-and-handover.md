---
id: US-064
title: "Shift Close and Handover"
slug: "shift-close-and-handover"
personas: [P-003, P-002]
epic: "Staff & Admin"
priority: "must-have"
complexity: "M"
tags: [staff, shift, cash-management]
---

# US-064: Shift Close and Handover

## User Story

**As a** cashier (P-003),
**I want to** close out my shift and hand the register to the next cashier with a clean, agreed baseline,
**So that** neither of us is responsible for cash that changed hands during the handover itself.

## Acceptance Criteria

- [ ] Given a cashier taps "End Shift," when they proceed, then they are taken into the [[US-052]] drawer-close reconciliation flow before the shift can be marked complete.
- [ ] Given reconciliation completes, when the shift closes, then the app records the end time and generates the [[US-053]] cash-up report automatically.
- [ ] Given a next cashier is ready to take over immediately, when the outgoing cashier finishes closing, then the app offers a direct "Hand Over" path into the incoming cashier's [[US-063]] shift-open flow, avoiding an idle/unattended register gap.
- [ ] Given a shift is closed, when the outgoing cashier logs out, then they can no longer perform register actions until they open a new shift.

## Notes

Depends on [[US-052]], [[US-053]], [[US-063]]. Blame-free handover (P-003's core concern) is achieved by making both counts explicit and attributable rather than assumed continuous.
