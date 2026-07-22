---
id: US-007
title: "Switch between workspaces"
slug: switch-between-workspaces
personas: [P-001, P-002]
epic: "Onboarding and Access"
priority: should-have
complexity: medium
tags: [auth, workspace]
---

# US-007: Switch between workspaces

## User Story

**As a** multi-entity operator  
**I want to** switch between workspaces cleanly  
**So that** avoid cross-entity billing mistakes

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the switch between workspaces flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
