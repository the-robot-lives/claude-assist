---
id: US-052
title: "Social OAuth Login"
slug: social-oauth-login
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [oauth, login, social-auth]
---

# US-052: Social OAuth Login

## User Story

**As a** skeptical switcher
**I want to** log in with an existing social account (Google, Apple, GitHub)
**So that** I can access Flywheel without managing a separate password

## Acceptance Criteria

- **Given** I click "Continue with Google" on the login screen
  **When** I complete the OAuth consent flow
  **Then** I am logged into Flywheel and returned to the page I came from

- **Given** the OAuth provider returns an error or I deny consent
  **When** I am redirected back to Flywheel
  **Then** I see a clear error message and am returned to the login screen

## Notes
Show which permissions are requested before redirecting to provider.
