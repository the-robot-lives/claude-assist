---
id: US-044
title: "Write off invoice balance"
slug: write-off-invoice-balance
personas: [P-002, P-005]
epic: "Invoices and Delivery"
priority: should-have
complexity: medium
tags: [invoices, delivery]
---

# US-044: Write off invoice balance

## User Story

**As a** billing operator  
**I want to** write off uncollectible balances with audit trail  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the write off invoice balance flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
