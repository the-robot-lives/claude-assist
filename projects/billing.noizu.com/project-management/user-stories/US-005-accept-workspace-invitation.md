---
id: US-005
title: "Accept workspace invitation"
slug: accept-workspace-invitation
personas: [P-002, P-003, P-006]
epic: "Onboarding and Access"
priority: must-have
complexity: low
tags: [auth, workspace]
---

# US-005: Accept workspace invitation

## User Story

**As a** invited teammate  
**I want to** accept an invitation into the right workspace  
**So that** begin work with correct access

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the accept workspace invitation flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
