---
id: US-041
title: "Resend invoice email"
slug: resend-invoice-email
personas: [P-002, P-006]
epic: "Invoices and Delivery"
priority: should-have
complexity: medium
tags: [invoices, delivery]
---

# US-041: Resend invoice email

## User Story

**As a** billing operator  
**I want to** resend an invoice with recorded delivery history  
**So that** send accurate invoices and preserve state

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the resend invoice email flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
