---
id: US-036
title: "Calculate invoice totals"
slug: calculate-invoice-totals
personas: [P-001, P-002, P-005]
epic: "Invoices and Delivery"
priority: must-have
complexity: medium
tags: [invoices, delivery]
---

# US-036: Calculate invoice totals

## User Story

**As a** billing operator  
**I want to** see subtotal, tax, discounts, credits, and balance due  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the calculate invoice totals flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
