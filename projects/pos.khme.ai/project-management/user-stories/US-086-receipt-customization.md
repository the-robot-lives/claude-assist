---
id: US-086
title: "Receipt customization (store name/logo)"
slug: "receipt-customization"
personas: [P-002, P-004]
epic: "Settings & Localization"
priority: "should-have"
complexity: "S"
tags: [localization, settings, receipts]
---

# US-086: Receipt customization (store name/logo)

## User Story

**As a** minimart owner (P-002),
**I want to** put my store name and logo on printed and digital receipts,
**So that** my business looks professional and customers can identify where they shopped.

## Acceptance Criteria

- [ ] Given Settings > Receipt, when the user uploads a logo image and enters a store name/address, then subsequent receipts (printed and digital) display that logo and info in the header.
- [ ] Given a store has no logo uploaded, when a receipt is generated, then it falls back to a text-only header with the store name, with no broken image or placeholder shown.
- [ ] Given the user changes the receipt logo, when they tap "preview," then a sample receipt renders with the updated branding before any real sale uses it.

## Notes

Depends on US-082 for the physical print path; the digital receipt path is independent.
