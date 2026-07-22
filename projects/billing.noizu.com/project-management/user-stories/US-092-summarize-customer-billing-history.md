---
id: US-092
title: "Summarize customer billing history"
slug: summarize-customer-billing-history
personas: [P-002, P-006]
epic: "Agent-Assisted Billing"
priority: should-have
complexity: medium
tags: [agent-assisted, automation]
---

# US-092: Summarize customer billing history

## User Story

**As a** billing operator  
**I want to** create a concise customer billing summary  
**So that** save time while keeping human approval on financial actions

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the summarize customer billing history flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
