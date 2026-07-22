---
id: US-003
title: "Keep me signed in across sessions"
slug: session-persistence
personas: [P-001, P-003]
epic: "Onboarding & Auth"
priority: must-have
complexity: low
tags: [auth, jwt, session]
---

# US-003: Keep me signed in across sessions

## User Story

**As a** returning user
**I want to** stay signed in until my session expires
**So that** I don't re-authenticate on every visit

## Acceptance Criteria

- **Given** I authenticated successfully
  **When** I return within the token validity window
  **Then** I remain signed in without re-entering credentials
- **Given** my JWT is near expiry
  **When** I make an authenticated request
  **Then** the session is refreshed transparently where possible
- **Given** my token is expired or invalid
  **When** I load an authed page
  **Then** I am redirected to sign in

## Notes
Uses existing Guardian JWT lifecycle.
