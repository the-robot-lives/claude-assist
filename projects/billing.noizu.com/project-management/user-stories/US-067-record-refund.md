---
id: US-067
title: "Record refund"
slug: record-refund
personas: [P-002, P-005]
epic: "Payments and Credits"
priority: should-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-067: Record refund

## User Story

**As a** finance operator  
**I want to** record a refund against a payment  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the record refund flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
