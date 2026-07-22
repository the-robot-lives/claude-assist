---
id: US-091
title: "Flag overdue risk"
slug: flag-overdue-risk
personas: [P-001, P-002, P-006]
epic: "Agent-Assisted Billing"
priority: should-have
complexity: medium
tags: [agent-assisted, automation]
---

# US-091: Flag overdue risk

## User Story

**As a** billing operator  
**I want to** identify invoices likely to become overdue  
**So that** save time while keeping human approval on financial actions

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the flag overdue risk flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
