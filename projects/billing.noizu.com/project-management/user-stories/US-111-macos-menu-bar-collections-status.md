---
id: US-111
title: "macOS menu bar collections status"
slug: macos-menu-bar-collections-status
personas: [P-006, P-009]
epic: "Cross-Platform Apps"
priority: could-have
complexity: medium
tags: [macos, menu-bar, collections]
---

# US-111: macOS menu bar collections status

## User Story

**As a** desktop finance power user  
**I want to** see a compact collections status in the macOS menu bar  
**So that** overdue and payment activity stays visible while I work in other apps

## Acceptance Criteria

- **Given** I enable the menu bar extra  
  **When** receivables status changes  
  **Then** the menu bar popover shows overdue count, amount at risk, recent payments, and links into the full macOS app

## Notes
Keep the menu bar surface informational and low-noise. Destructive or external actions should open the full app for confirmation.
