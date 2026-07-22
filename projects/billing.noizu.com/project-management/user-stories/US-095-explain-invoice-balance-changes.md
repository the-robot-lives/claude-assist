---
id: US-095
title: "Explain invoice balance changes"
slug: explain-invoice-balance-changes
personas: [P-002, P-005, P-007]
epic: "Agent-Assisted Billing"
priority: should-have
complexity: medium
tags: [agent-assisted, automation]
---

# US-095: Explain invoice balance changes

## User Story

**As a** billing operator  
**I want to** summarize why an invoice balance changed  
**So that** save time while keeping human approval on financial actions

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the explain invoice balance changes flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
