---
id: US-106
title: "Android app mobile invoice review"
slug: android-app-mobile-invoice-review
personas: [P-001, P-008]
epic: "Cross-Platform Apps"
priority: should-have
complexity: high
tags: [android, mobile, invoices]
---

# US-106: Android app mobile invoice review

## User Story

**As a** mobile approval operator  
**I want to** review invoice drafts and sent invoice status in a native Android app  
**So that** billing approval is not limited to desktop or iOS users

## Acceptance Criteria

- **Given** I am signed into the Android app  
  **When** I open an invoice from the dashboard, search, or a deep link  
  **Then** I can read customer, amount, due date, line item summary, PDF preview, and approval state in a Material 3 layout

## Notes
Use Jetpack Compose and adaptive Material 3 patterns. The Android flow should match iOS capability without copying iOS interaction conventions blindly.
