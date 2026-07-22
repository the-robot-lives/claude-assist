---
id: US-070
title: "Show payment history"
slug: show-payment-history
personas: [P-001, P-002, P-006]
epic: "Payments and Credits"
priority: must-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-070: Show payment history

## User Story

**As a** finance operator  
**I want to** see all payments for a customer or invoice  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the show payment history flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
