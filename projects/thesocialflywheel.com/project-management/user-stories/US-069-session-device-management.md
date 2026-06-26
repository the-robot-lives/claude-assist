---
id: US-069
title: "Session and Device Management"
slug: session-device-management
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [session-management, devices, security]
---

# US-069: Session and Device Management

## User Story

**As a** skeptical switcher
**I want to** view all active sessions with device type, location, and last-active time
**So that** I can identify any sessions I did not authorize

## Acceptance Criteria

- **Given** I open Security Settings
  **When** I view the "Active Sessions" section
  **Then** I see a list showing browser/OS, approximate location, and last-active timestamp for each session, with the current session highlighted

- **Given** I see an unfamiliar session
  **When** I click "Revoke" for that session
  **Then** that session is immediately invalidated
