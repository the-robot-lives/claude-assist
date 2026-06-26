---
id: US-092
title: "Moderator Session Revocation for Banned Accounts"
slug: moderator-session-revocation
personas: [P-007]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [moderator, session-management, ban, security]
---

# US-092: Moderator Session Revocation for Banned Accounts

## User Story

**As a** channel moderator
**I want to** ensure that banning an account immediately revokes all of the user's active sessions
**So that** a banned user cannot continue activity already in progress

## Acceptance Criteria

- **Given** I issue a ban on an account
  **When** the ban is confirmed
  **Then** all active sessions for that account are invalidated within 30 seconds and the user is shown a ban notice if currently logged in
