---
id: US-079
title: "Convert expenses to invoice lines"
slug: convert-expenses-to-invoice-lines
personas: [P-001, P-002, P-003]
epic: "Expense Rebilling"
priority: should-have
complexity: high
tags: [expenses, rebilling]
---

# US-079: Convert expenses to invoice lines

## User Story

**As a** billing operator  
**I want to** add approved billable expenses to invoice drafts  
**So that** rebill costs accurately

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the convert expenses to invoice lines flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
