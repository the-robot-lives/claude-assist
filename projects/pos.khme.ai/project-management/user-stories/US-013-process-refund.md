---
id: US-013
title: "Process a refund"
slug: "process-refund"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "M"
tags: [refund, checkout]
---

# US-013: Process a Refund

## User Story

**As a** cashier (P-003),
**I want to** process a full or partial refund against a completed sale,
**So that** I can handle returns correctly and keep cash and inventory records accurate.

## Acceptance Criteria

- [ ] Given a completed sale is looked up by receipt ID or recent-sales list, when I select items to refund, then the refund amount calculates automatically per item and currency originally tendered.
- [ ] Given a refund is issued, when it completes, then it is logged to the audit trail with cashier ID, timestamp, and reason.
- [ ] Given the original sale was paid via KHQR, when a refund is issued, then the app flags that a cash refund may be required if QR reversal is unavailable, rather than silently assuming success.

## Notes

Depends on US-019 (mixed tender) and the audit trail (owned by Cash & Audit epic, US-051-075) for full traceability.
