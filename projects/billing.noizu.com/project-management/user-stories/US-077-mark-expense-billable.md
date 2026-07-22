---
id: US-077
title: "Mark expense billable"
slug: mark-expense-billable
personas: [P-002, P-003]
epic: "Expense Rebilling"
priority: should-have
complexity: low
tags: [expenses, rebilling]
---

# US-077: Mark expense billable

## User Story

**As a** billing operator  
**I want to** mark whether an expense should be rebilled  
**So that** rebill costs accurately

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the mark expense billable flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
