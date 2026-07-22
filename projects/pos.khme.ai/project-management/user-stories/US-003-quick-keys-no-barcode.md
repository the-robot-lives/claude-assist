---
id: US-003
title: "Quick-keys for non-barcoded goods"
slug: "quick-keys-no-barcode"
personas: [P-001, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "M"
tags: [quick-keys, checkout, no-barcode]
---

# US-003: Quick-Keys for Non-Barcoded Goods

## User Story

**As a** market-stall owner (P-001),
**I want to** use a grid of large tappable buttons for common items that have no barcode,
**So that** I can ring up produce and loose goods as fast as packaged items.

## Acceptance Criteria

- [ ] Given the sell screen is open, when I view the quick-key grid, then it shows merchant-configured items with photo, name, and price, sized for thumb tapping.
- [ ] Given I tap a quick-key item, when the tap registers, then it is added to the cart the same way a scanned item would be.
- [ ] Given the merchant reorders or resizes the grid in settings, when I return to the sell screen, then the new layout persists across app restarts.

## Notes

Quick-key configuration itself belongs to the Settings epic (US-076-100); this story covers register-side rendering and tap behavior only.
