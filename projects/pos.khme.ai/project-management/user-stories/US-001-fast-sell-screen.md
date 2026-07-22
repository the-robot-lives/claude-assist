---
id: US-001
title: "Fast sell screen — add items to running cart"
slug: "fast-sell-screen"
personas: [P-001, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "M"
tags: [checkout, cart, core-flow]
---

# US-001: Fast Sell Screen — Add Items to Running Cart

## User Story

**As a** market-stall owner (P-001),
**I want to** add items to a running sale with minimal taps,
**So that** I can serve customers as fast as I would tallying cash by hand.

## Acceptance Criteria

- [ ] Given the register is on the sell screen, when I tap an item tile or scan a barcode, then it is added to the cart with quantity 1 and the running total updates instantly.
- [ ] Given an item is already in the cart, when I add it again, then its quantity increments rather than creating a duplicate line.
- [ ] Given the UI language is set to Khmer, when the sell screen renders, then all item names, buttons, and totals display in Khmer script with no English fallback text visible.

## Notes

Screen must remain usable one-handed on a single Android phone; this is the anchor screen most other register stories build on. Related: US-002, US-003.
