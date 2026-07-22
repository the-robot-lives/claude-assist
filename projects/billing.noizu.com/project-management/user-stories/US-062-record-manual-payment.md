---
id: US-062
title: "Record manual payment"
slug: record-manual-payment
personas: [P-002, P-005]
epic: "Payments and Credits"
priority: must-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-062: Record manual payment

## User Story

**As a** finance operator  
**I want to** enter ACH, wire, check, cash, or external payment  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the record manual payment flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
