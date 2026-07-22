---
id: US-012
title: "Digital/QR receipt"
slug: "digital-qr-receipt"
personas: [P-002, P-004]
epic: "Register & Checkout"
priority: "should-have"
complexity: "M"
tags: [receipt, digital, qr-code]
---

# US-012: Digital/QR Receipt

## User Story

**As a** minimart owner (P-002),
**I want to** offer a digital receipt via QR code or SMS link instead of paper,
**So that** I can cut printer supply costs and give customers a record they can't lose.

## Acceptance Criteria

- [ ] Given a sale completes, when I choose digital receipt, then a QR code displays that the customer can scan with their phone to view/download the receipt.
- [ ] Given the register is offline, when a digital receipt is generated, then it queues for delivery and the QR still resolves to a locally cached view.
- [ ] Given both paper and digital receipt options are enabled, when a sale completes, then the cashier can choose either or both per transaction.

## Notes

Related: US-011. Depends on the offline queue (US-015) for delivery once connectivity returns.
