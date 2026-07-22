---
id: US-066
title: "Create credit note"
slug: create-credit-note
personas: [P-002, P-005]
epic: "Payments and Credits"
priority: should-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-066: Create credit note

## User Story

**As a** finance operator  
**I want to** issue a credit note tied to customer and invoice context  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the create credit note flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
