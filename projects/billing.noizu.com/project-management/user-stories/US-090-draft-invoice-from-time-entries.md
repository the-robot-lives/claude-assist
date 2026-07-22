---
id: US-090
title: "Draft invoice from time entries"
slug: draft-invoice-from-time-entries
personas: [P-001, P-002, P-003]
epic: "Agent-Assisted Billing"
priority: could-have
complexity: high
tags: [agent-assisted, automation]
---

# US-090: Draft invoice from time entries

## User Story

**As a** billing operator  
**I want to** generate invoice lines from timely.noizu.com entries  
**So that** save time while keeping human approval on financial actions

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the draft invoice from time entries flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
