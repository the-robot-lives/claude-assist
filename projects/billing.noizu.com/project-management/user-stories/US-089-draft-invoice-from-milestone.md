---
id: US-089
title: "Draft invoice from milestone"
slug: draft-invoice-from-milestone
personas: [P-001, P-003]
epic: "Agent-Assisted Billing"
priority: could-have
complexity: high
tags: [agent-assisted, automation]
---

# US-089: Draft invoice from milestone

## User Story

**As a** billing operator  
**I want to** generate a draft invoice from approved project milestones  
**So that** save time while keeping human approval on financial actions

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the draft invoice from milestone flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
