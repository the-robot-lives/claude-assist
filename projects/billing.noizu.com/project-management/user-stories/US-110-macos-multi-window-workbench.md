---
id: US-110
title: "macOS multi-window workbench"
slug: macos-multi-window-workbench
personas: [P-002, P-005, P-009]
epic: "Cross-Platform Apps"
priority: could-have
complexity: high
tags: [macos, multi-window, reconciliation]
---

# US-110: macOS multi-window workbench

## User Story

**As a** desktop finance power user  
**I want to** open customers, invoices, payments, and reports in separate macOS windows  
**So that** reconciliation and review work can happen side by side

## Acceptance Criteria

- **Given** I am using the macOS app  
  **When** I open a record or report in a new window  
  **Then** each window preserves its own state, refreshes safely, and does not corrupt shared financial data

## Notes
Each window needs isolated view state with shared authenticated data services. This is a desktop productivity feature, not an MVP web requirement.
