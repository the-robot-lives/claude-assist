---
id: US-011
title: "Thermal receipt printing"
slug: "thermal-receipt-printing"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "M"
tags: [receipt, printing, hardware]
---

# US-011: Thermal Receipt Printing

## User Story

**As a** minimart owner (P-002),
**I want to** print a paper receipt on a connected thermal printer,
**So that** customers who expect a physical receipt get one, matching local retail norms.

## Acceptance Criteria

- [ ] Given a supported Bluetooth/USB thermal printer is paired, when a sale completes, then a receipt prints automatically showing itemized lines, dual-currency totals, and tender breakdown.
- [ ] Given no printer is paired or the printer is offline, when a sale completes, then the app shows a clear "not printed" state and offers retry without losing the completed-sale record.
- [ ] Given the merchant sets receipt language, when a receipt prints, then item names and totals render in the configured language (Khmer, English, or both).

## Notes

Printer pairing/setup itself may live under the Settings epic (US-076-100); this story covers the print-on-sale-complete behavior.
