---
id: US-098
title: "Manage invoice numbering rules"
slug: manage-invoice-numbering-rules
personas: [P-002, P-005]
epic: "Settings, Audit, and Accessibility"
priority: must-have
complexity: medium
tags: [settings, audit, accessibility]
---

# US-098: Manage invoice numbering rules

## User Story

**As a** workspace operator  
**I want to** define invoice prefix and next number safely  
**So that** run billing safely and inclusively

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the manage invoice numbering rules flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
