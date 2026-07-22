---
id: US-072
title: "Send payment receipt"
slug: send-payment-receipt
personas: [P-002, P-004]
epic: "Payments and Credits"
priority: should-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-072: Send payment receipt

## User Story

**As a** finance operator  
**I want to** email payment confirmation to billing contacts  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the send payment receipt flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
