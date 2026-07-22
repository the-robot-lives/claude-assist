---
id: US-006
title: "Assign role permissions"
slug: assign-role-permissions
personas: [P-001, P-002]
epic: "Onboarding and Access"
priority: must-have
complexity: high
tags: [auth, workspace]
---

# US-006: Assign role permissions

## User Story

**As a** workspace owner  
**I want to** assign permissions by role  
**So that** separate finance, delivery, and admin responsibilities

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the assign role permissions flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
