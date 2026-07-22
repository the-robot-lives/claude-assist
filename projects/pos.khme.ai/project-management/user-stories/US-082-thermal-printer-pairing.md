---
id: US-082
title: "Thermal printer pairing"
slug: "thermal-printer-pairing"
personas: [P-002, P-003]
epic: "Onboarding & Setup"
priority: "should-have"
complexity: "M"
tags: [onboarding, hardware, printer]
---

# US-082: Thermal printer pairing

## User Story

**As a** minimart owner (P-002),
**I want to** pair a Bluetooth thermal receipt printer with my register,
**So that** I can hand customers a physical receipt without relying on a full-size printer.

## Acceptance Criteria

- [ ] Given the user opens Settings > Hardware > Printer, when they tap "Add printer," then nearby Bluetooth thermal printers are listed for selection.
- [ ] Given a printer is selected, when pairing succeeds, then a test receipt is printed automatically for the user to confirm alignment and paper width.
- [ ] Given a printer was previously paired, when it goes out of range or is powered off, then the sell screen shows a clear "printer offline" indicator and falls back to a digital/skip-receipt option without blocking the sale.

## Notes

Must not block checkout if the printer is unavailable — receipts are optional per the README's open questions. Related: US-086 (receipt customization).
