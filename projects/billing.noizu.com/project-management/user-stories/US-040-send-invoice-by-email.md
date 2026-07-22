---
id: US-040
title: "Send invoice by email"
slug: send-invoice-by-email
personas: [P-001, P-002, P-004]
epic: "Invoices and Delivery"
priority: must-have
complexity: high
tags: [invoices, delivery]
---

# US-040: Send invoice by email

## User Story

**As a** billing operator  
**I want to** send the invoice to billing contacts  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the send invoice by email flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
