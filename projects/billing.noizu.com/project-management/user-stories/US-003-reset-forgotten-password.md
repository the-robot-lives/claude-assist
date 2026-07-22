---
id: US-003
title: "Reset forgotten password"
slug: reset-forgotten-password
personas: [P-002, P-007]
epic: "Onboarding and Access"
priority: must-have
complexity: low
tags: [auth, workspace]
---

# US-003: Reset forgotten password

## User Story

**As a** workspace member  
**I want to** reset my password through email verification  
**So that** recover access without exposing account data

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the reset forgotten password flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
