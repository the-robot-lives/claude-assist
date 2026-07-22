---
id: US-004
title: "Log out"
slug: logout
personas: [P-001, P-003]
epic: "Onboarding & Auth"
priority: must-have
complexity: low
tags: [auth, logout, session]
---

# US-004: Log out

## User Story

**As a** signed-in user
**I want to** log out
**So that** my account is secure on shared devices

## Acceptance Criteria

- **Given** I am signed in
  **When** I choose "Log out"
  **Then** my session/token is invalidated and I am returned to a public page
- **Given** I have logged out
  **When** I try to open an authed route
  **Then** I am redirected to sign in
- **Given** I log out
  **When** the action completes
  **Then** no residual session state remains in the client

## Notes
