---
id: US-020
title: "Change calculation across currencies with 4,000៛ convention"
slug: "change-calculation-dual-currency"
personas: [P-001, P-003]
epic: "Payments & Currency"
priority: "must-have"
complexity: "M"
tags: [dual-currency, change, rounding]
---

# US-020: Change Calculation Across Currencies with 4,000៛ Convention

## User Story

**As a** cashier (P-003),
**I want to** have change calculated correctly across KHR and USD using the merchant's configured exchange convention (e.g., 4,000៛ = $1),
**So that** I never shortchange a customer or lose money on rounding.

## Acceptance Criteria

- [ ] Given a sale is tendered in a mix of currencies, when change is due, then the app calculates it using the merchant-configured rate and shows the recommended currency split for giving change (e.g., dollars first, riel remainder).
- [ ] Given the configured rate is changed in settings, when a new sale is rung up, then the new rate applies immediately with no stale cached rate used.
- [ ] Given change due in riel doesn't divide evenly by standard riel note denominations, when displayed, then the app rounds per the merchant's configured rounding rule and shows the rounding adjustment as a visible line, not silently.

## Notes

Depends on US-019. Rate configuration UI belongs to the Settings epic (US-076-100); this story covers the calculation and display logic at checkout. Related: US-021.
