---
id: US-075
title: "Assign expense to customer"
slug: assign-expense-to-customer
personas: [P-002]
epic: "Expense Rebilling"
priority: should-have
complexity: medium
tags: [expenses, rebilling]
---

# US-075: Assign expense to customer

## User Story

**As a** billing operator  
**I want to** link expense to a customer for rebilling  
**So that** rebill costs accurately

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the assign expense to customer flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
