---
id: US-078
title: "Apply expense markup"
slug: apply-expense-markup
personas: [P-002, P-005]
epic: "Expense Rebilling"
priority: could-have
complexity: medium
tags: [expenses, rebilling]
---

# US-078: Apply expense markup

## User Story

**As a** billing operator  
**I want to** set markup and tax treatment for rebilled expenses  
**So that** rebill costs accurately

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the apply expense markup flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
