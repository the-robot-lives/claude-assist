---
id: US-097
title: "Configure payment methods"
slug: configure-payment-methods
personas: [P-001, P-002]
epic: "Settings, Audit, and Accessibility"
priority: must-have
complexity: high
tags: [settings, audit, accessibility]
---

# US-097: Configure payment methods

## User Story

**As a** workspace operator  
**I want to** enable Stripe card or ACH collection per workspace  
**So that** run billing safely and inclusively

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the configure payment methods flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
