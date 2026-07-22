---
id: US-063
title: "Record partial payment"
slug: record-partial-payment
personas: [P-002, P-004]
epic: "Payments and Credits"
priority: must-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-063: Record partial payment

## User Story

**As a** finance operator  
**I want to** apply a payment smaller than invoice balance  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the record partial payment flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
