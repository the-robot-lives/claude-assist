---
id: US-099
title: "Concurrent Session Limit"
slug: concurrent-session-limit
personas: [P-007]
epic: "Authentication & Security"
priority: could-have
complexity: medium
tags: [session-management, security, moderator]
---

# US-099: Concurrent Session Limit

## User Story

**As a** channel moderator
**I want to** know that there is a reasonable limit on how many concurrent sessions an account can hold
**So that** shared-credential or account-takeover abuse is harder to sustain

## Acceptance Criteria

- **Given** an account already has 10 active sessions
  **When** an 11th login is attempted
  **Then** the oldest non-trusted session is automatically invalidated and the user is notified

- **Given** a session is automatically invalidated due to the limit
  **When** the affected user views their session list
  **Then** they see that a session was "auto-expired (session limit)" with the device and time recorded
