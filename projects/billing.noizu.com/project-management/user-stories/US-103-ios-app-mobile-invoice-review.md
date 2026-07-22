---
id: US-103
title: "iOS app mobile invoice review"
slug: ios-app-mobile-invoice-review
personas: [P-001, P-008]
epic: "Cross-Platform Apps"
priority: should-have
complexity: high
tags: [ios, mobile, invoices]
---

# US-103: iOS app mobile invoice review

## User Story

**As a** mobile approval operator  
**I want to** review invoice drafts and sent invoice status in a native iOS app  
**So that** I can approve or defer billing actions while away from my desk

## Acceptance Criteria

- **Given** I am signed into the iOS app  
  **When** I open an invoice from the dashboard, search, or a deep link  
  **Then** I can read customer, amount, due date, line item summary, PDF preview, and approval state in an iOS-native layout

## Notes
Use SwiftUI-native navigation and confirmation patterns. Editing can be limited in the first iOS release, but review and safe approval must be polished.
