---
id: US-037
title: "Set item prices in dual currency"
slug: "dual-currency-pricing"
personas: [P-001, P-002]
epic: "Inventory & Catalog"
priority: "must-have"
complexity: "M"
tags: [catalog, currency, pricing]
---

# US-037: Set item prices in dual currency

## User Story

**As a** market-stall owner (P-001),
**I want to** set an item's price once and have it show correctly in both KHR and USD,
**So that** I can quote and charge in whichever currency the customer hands me, without doing mental math at the register.

## Acceptance Criteria

- [ ] Given a shop-level exchange rate is configured (default 4,000៛ = $1, editable by the owner), when I enter a price in either currency, then the other currency's price auto-calculates and displays alongside it on the item form.
- [ ] Given rounding conventions differ (USD typically rounds to $0.25 or $0.50 for cash change, KHR to nearest 100៛), when a price auto-converts, then it rounds using the shop's configured rounding rule rather than showing raw fractional currency.
- [ ] Given the owner updates the shop-wide exchange rate, when the rate changes, then existing item prices are NOT silently recalculated — the owner must explicitly choose "reprice catalog at new rate" as a separate confirmed action, to avoid surprise price changes.
- [ ] Given an item's price is displayed anywhere in the app (sell screen, catalog, reports), when dual currency is enabled, then both values are always shown together, never just one, so staff and customers see the same number.

## Notes

This is foundational to the "dual currency is native" product principle — pricing, not just tendering, must be currency-aware. Cross-epic: mixed-tender cash handling at checkout is covered in Register & Checkout (US-001–025); this story is catalog-side price definition only. Related: [[US-026]].
