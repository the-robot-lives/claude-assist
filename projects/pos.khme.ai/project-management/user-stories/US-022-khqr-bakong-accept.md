---
id: US-022
title: "KHQR/Bakong QR payment accept"
slug: "khqr-bakong-accept"
personas: [P-002, P-003, P-004]
epic: "Payments & Currency"
priority: "must-have"
complexity: "L"
tags: [khqr, bakong, qr-payment]
---

# US-022: KHQR/Bakong QR Payment Accept

## User Story

**As a** minimart owner (P-002),
**I want to** generate a KHQR code for a sale that customers can scan with their banking app,
**So that** I can accept cashless payment through Cambodia's national QR standard.

## Acceptance Criteria

- [ ] Given a sale total is finalized, when I select KHQR as the tender method, then a KHQR-compliant QR code renders on screen (or a connected customer-facing display) with the correct amount and merchant identifier.
- [ ] Given the QR is displayed, when the customer's banking app scans it, then the amount and currency shown to the customer match the sale total exactly.
- [ ] Given the register has no network connectivity, when KHQR is selected, then the app clearly disables QR generation and directs the cashier to an alternate tender method, per US-024.

## Notes

Requires Bakong merchant registration/certification (open question in the product README); this story assumes credentials are already provisioned. Depends on US-023 for confirming payment receipt.
