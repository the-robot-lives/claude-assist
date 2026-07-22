---
id: US-004
title: "Invite billing teammate"
slug: invite-billing-teammate
personas: [P-001, P-002]
epic: "Onboarding and Access"
priority: must-have
complexity: medium
tags: [auth, workspace]
---

# US-004: Invite billing teammate

## User Story

**As a** workspace owner  
**I want to** invite a teammate by email and role  
**So that** delegate billing work safely

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the invite billing teammate flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
