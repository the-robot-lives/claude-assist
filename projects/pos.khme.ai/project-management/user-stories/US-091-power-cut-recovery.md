---
id: US-091
title: "Power-cut/low-battery recovery mid-sale"
slug: "power-cut-recovery"
personas: [P-008]
epic: "Sync, Performance & Edge Cases"
priority: "must-have"
complexity: "M"
tags: [sync, offline, resilience]
---

# US-091: Power-cut/low-battery recovery mid-sale

## User Story

**As a** rural pharmacy owner (P-008) whose power is unreliable,
**I want** an in-progress sale to survive a sudden device shutdown or battery death,
**So that** I don't lose the transaction or end up with a half-charged customer.

## Acceptance Criteria

- [ ] Given a sale is in progress (items added, payment not yet confirmed), when the device loses power abruptly, then on next boot the app restores the in-progress sale exactly as it was, prompting the cashier to resume or cancel.
- [ ] Given a sale was fully paid but the receipt/confirmation step was interrupted by shutdown, when the device restarts, then the app shows the completed sale as already recorded (not duplicated) and offers to reprint/resend the receipt.
- [ ] Given battery drops below a low threshold during an active sale, when the app detects it, then a warning is shown so the cashier can finish or safely pause the transaction before forced shutdown.

## Notes

Depends on US-089's local transaction store. Critical for P-008's persona — power cuts are a stated recurring condition, not an edge case, in rural pharmacy contexts.
