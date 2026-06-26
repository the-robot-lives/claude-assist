---
id: US-071
title: "Revoke All Other Sessions"
slug: revoke-all-other-sessions
personas: [P-007]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [session-management, revoke, security, moderator]
---

# US-071: Revoke All Other Sessions

## User Story

**As a** channel moderator
**I want to** revoke all sessions except my current one in a single action
**So that** I can quickly secure my moderator account if I suspect compromise

## Acceptance Criteria

- **Given** I am in Security Settings
  **When** I click "Revoke all other sessions" and confirm with my password
  **Then** all sessions except the current one are immediately invalidated and I see a count of sessions removed
