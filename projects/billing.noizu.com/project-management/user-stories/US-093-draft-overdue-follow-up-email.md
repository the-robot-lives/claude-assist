---
id: US-093
title: "Draft overdue follow-up email"
slug: draft-overdue-follow-up-email
personas: [P-002, P-006]
epic: "Agent-Assisted Billing"
priority: should-have
complexity: medium
tags: [agent-assisted, automation]
---

# US-093: Draft overdue follow-up email

## User Story

**As a** billing operator  
**I want to** write a polite editable reminder for overdue invoices  
**So that** save time while keeping human approval on financial actions

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the draft overdue follow-up email flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
