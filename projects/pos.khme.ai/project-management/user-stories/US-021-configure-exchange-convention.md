---
id: US-021
title: "Configure default exchange convention"
slug: "configure-exchange-convention"
personas: [P-002, P-004]
epic: "Payments & Currency"
priority: "should-have"
complexity: "S"
tags: [dual-currency, configuration]
---

# US-021: Configure Default Exchange Convention

## User Story

**As a** multi-store operator (P-004),
**I want to** set and adjust the KHR/USD exchange rate convention used at checkout,
**So that** my stores' change calculations stay accurate as the informal market rate shifts.

## Acceptance Criteria

- [ ] Given I am an authorized owner/manager, when I open currency settings, then I can view and edit the current riel-per-dollar convention (default 4,000).
- [ ] Given I update the rate, when I save it, then all registers under that store apply the new rate on their next sale, including offline registers once they resync.
- [ ] Given a rate change is saved, when viewed in the audit trail, then it is logged with who changed it and when.

## Notes

Depends on US-020, which consumes the configured rate. Overlaps with the Settings epic (US-076-100) but scoped here as it is core to dual-currency payment correctness.
