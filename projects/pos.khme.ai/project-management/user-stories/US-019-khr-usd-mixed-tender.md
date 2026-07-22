---
id: US-019
title: "KHR/USD mixed tender"
slug: "khr-usd-mixed-tender"
personas: [P-001, P-002, P-008]
epic: "Payments & Currency"
priority: "must-have"
complexity: "L"
tags: [dual-currency, payment, cash]
---

# US-019: KHR/USD Mixed Tender

## User Story

**As a** market-stall owner (P-001),
**I want to** accept payment split across Cambodian riel and US dollars in a single transaction,
**So that** I can complete a sale the way customers actually pay in Cambodia.

## Acceptance Criteria

- [ ] Given a sale total, when I enter tender in USD, then I can also enter a KHR amount for the remainder and the app tracks both amounts against the same sale.
- [ ] Given mixed tender is entered, when the total tendered (converted to a common currency using the configured rate) meets or exceeds the sale total, then payment can be confirmed.
- [ ] Given the receipt is generated, when mixed tender was used, then it itemizes exactly how much was received in each currency.

## Notes

Depends on US-020 for change calculation. Foundational to the Payments & Currency epic — most other payment stories build on this line-item model.
