---
id: US-786
title: "Revoke a Session"
slug: revoke-a-session
personas: [P-010]
epic: "Settings & Preferences"
priority: must-have
complexity: low
tags: [security, sessions, account, revoke]
---

# US-786: Revoke a Session

## User Story

**As a** skeptical switcher
**I want to** revoke a specific active session
**So that** I can immediately log out a device I no longer control

## Acceptance Criteria

- **Given** I am viewing my active sessions list
  **When** I tap "Revoke" on a session that is not my current session
  **Then** that session token is invalidated and the device is logged out within 30 seconds.

- **Given** I tap "Revoke All Other Sessions"
  **When** I confirm
  **Then** all sessions except my current one are invalidated simultaneously.

## Notes
