---
id: US-043
title: "Void sent invoice"
slug: void-sent-invoice
personas: [P-002, P-005]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-043: Void sent invoice

## User Story

**As a** billing operator  
**I want to** void an invoice with a required reason  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the void sent invoice flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
