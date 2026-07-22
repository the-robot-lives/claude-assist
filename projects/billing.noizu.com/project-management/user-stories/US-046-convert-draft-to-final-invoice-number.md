---
id: US-046
title: "Convert draft to final invoice number"
slug: convert-draft-to-final-invoice-number
personas: [P-001, P-002, P-005]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-046: Convert draft to final invoice number

## User Story

**As a** billing operator  
**I want to** assign immutable invoice number at send time  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the convert draft to final invoice number flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
