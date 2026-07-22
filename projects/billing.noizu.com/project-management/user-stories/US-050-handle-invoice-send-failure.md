---
id: US-050
title: "Handle invoice send failure"
slug: handle-invoice-send-failure
personas: [P-002, P-007]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-050: Handle invoice send failure

## User Story

**As a** billing operator  
**I want to** recover gracefully when email or PDF generation fails  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the handle invoice send failure flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
