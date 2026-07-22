---
id: US-085
title: "KHR/USD exchange-rate convention config"
slug: "exchange-rate-convention-config"
personas: [P-001, P-002, P-006]
epic: "Settings & Localization"
priority: "must-have"
complexity: "M"
tags: [localization, currency, settings]
---

# US-085: KHR/USD exchange-rate convention config

## User Story

**As a** market-stall owner (P-001),
**I want to** set my store's KHR/USD exchange-rate convention,
**So that** prices and change calculations match the local street-rate convention my customers expect.

## Acceptance Criteria

- [ ] Given Settings > Currency, when the user sets a fixed exchange rate (e.g., 4,000 riel = $1 USD), then all mixed-currency totals and change-due calculations on the sell screen use that rate.
- [ ] Given a store owner updates the exchange rate, when the change is saved, then it applies only to future transactions — historical receipts retain the rate that was active at time of sale.
- [ ] Given a customer pays with a mix of KHR and USD, when the cashier enters both tendered amounts, then the sell screen computes correct change in the store's preferred currency rounding convention (e.g., riel rounded to nearest 100).

## Notes

Dual currency is explicitly called out as "native, not an afterthought" in the README — must-have. Related: cash register balance reconciliation across two currencies (Cash & Audit epic, other agent's range).
