---
id: US-055
title: "Persistent Remember-Me Session"
slug: persistent-remember-me-session
personas: [P-006]
epic: "Authentication & Security"
priority: should-have
complexity: low
tags: [session, remember-me, cookies]
---

# US-055: Persistent Remember-Me Session

## User Story

**As a** quiet consumer
**I want to** opt into staying logged in across browser restarts
**So that** I don't have to re-enter credentials every visit

## Acceptance Criteria

- **Given** I check "Remember me" at login
  **When** I close and reopen my browser
  **Then** I remain logged in for up to 30 days without re-authenticating

- **Given** a remember-me session is active
  **When** I explicitly log out
  **Then** the persistent token is revoked and I must log in again

## Notes
Persistent tokens must be rotated on each use to prevent token theft.
