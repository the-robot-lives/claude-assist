---
id: US-065
title: "Apply customer credit"
slug: apply-customer-credit
personas: [P-002, P-005]
epic: "Payments and Credits"
priority: should-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-065: Apply customer credit

## User Story

**As a** finance operator  
**I want to** apply available credit to an invoice  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the apply customer credit flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
