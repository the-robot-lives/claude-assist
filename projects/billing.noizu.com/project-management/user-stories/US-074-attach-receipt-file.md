---
id: US-074
title: "Attach receipt file"
slug: attach-receipt-file
personas: [P-002, P-005]
epic: "Expense Rebilling"
priority: should-have
complexity: medium
tags: [expenses, rebilling]
---

# US-074: Attach receipt file

## User Story

**As a** billing operator  
**I want to** upload receipt evidence to object storage  
**So that** rebill costs accurately

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the attach receipt file flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
