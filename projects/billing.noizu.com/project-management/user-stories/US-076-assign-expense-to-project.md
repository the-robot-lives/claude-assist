---
id: US-076
title: "Assign expense to project"
slug: assign-expense-to-project
personas: [P-002, P-003]
epic: "Expense Rebilling"
priority: should-have
complexity: medium
tags: [expenses, rebilling]
---

# US-076: Assign expense to project

## User Story

**As a** billing operator  
**I want to** link expense to a project for billing context  
**So that** rebill costs accurately

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the assign expense to project flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
