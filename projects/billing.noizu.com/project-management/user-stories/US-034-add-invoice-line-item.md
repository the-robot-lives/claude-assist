---
id: US-034
title: "Add invoice line item"
slug: add-invoice-line-item
personas: [P-001, P-002, P-003]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-034: Add invoice line item

## User Story

**As a** billing operator  
**I want to** add quantity, unit price, tax, discount, and service period  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the add invoice line item flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
