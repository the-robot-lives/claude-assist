---
id: US-064
title: "Mark invoice paid"
slug: mark-invoice-paid
personas: [P-001, P-002]
epic: "Payments and Credits"
priority: must-have
complexity: medium
tags: [payments, credits, stripe]
---

# US-064: Mark invoice paid

## User Story

**As a** finance operator  
**I want to** close invoice balance when payments cover total  
**So that** keep balances correct and collectible

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the mark invoice paid flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
