---
id: US-002
title: "Barcode scan at register"
slug: "barcode-scan-register"
personas: [P-002, P-003]
epic: "Register & Checkout"
priority: "must-have"
complexity: "M"
tags: [barcode, scanning, checkout]
---

# US-002: Barcode Scan at Register

## User Story

**As a** minimart owner (P-002),
**I want to** scan a product barcode using the device camera,
**So that** I can add it to the cart without searching a catalog list.

## Acceptance Criteria

- [ ] Given the camera scanner is active, when a valid barcode is in frame, then the matching item is added to the cart within 1 second with a confirmation sound/vibration.
- [ ] Given a scanned barcode has no catalog match, when the scan completes, then the system prompts a quick-add flow instead of silently failing.
- [ ] Given low light or a damaged label, when the camera cannot decode the barcode after 3 seconds, then a manual barcode-entry keypad is offered as fallback.

## Notes

Depends on catalog lookup being available offline (local cache). Related: US-026 (unknown-item quick-add, owned by Inventory epic).
