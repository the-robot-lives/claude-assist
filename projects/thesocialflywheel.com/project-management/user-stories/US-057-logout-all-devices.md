---
id: US-057
title: "Logout All Devices"
slug: logout-all-devices
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [logout, session-management, security]
---

# US-057: Logout All Devices

## User Story

**As a** skeptical switcher
**I want to** sign out of every device in one action
**So that** I can quickly secure my account if I suspect unauthorized access

## Acceptance Criteria

- **Given** I navigate to Security Settings
  **When** I click "Sign out of all devices" and confirm
  **Then** all active sessions except the current one are immediately invalidated

- **Given** I choose "Sign out of all devices including this one"
  **When** I confirm
  **Then** all sessions including the current one are invalidated and I am redirected to the login page
