---
id: US-037
title: "Validate invoice before send"
slug: validate-invoice-before-send
personas: [P-002, P-007]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-037: Validate invoice before send

## User Story

**As a** billing operator  
**I want to** catch missing tax IDs, addresses, and payment terms  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the validate invoice before send flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
