---
id: US-002
title: "Social OAuth Signup via Google or Apple"
slug: social-oauth-signup
personas: [P-003, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [signup, oauth, google, apple]
---

# US-002: Social OAuth Signup via Google or Apple

## User Story

**As a** social connector
**I want to** sign up using my existing Google or Apple account
**So that** I can get started without creating yet another password

## Acceptance Criteria

- **Given** I tap "Continue with Google"
  **When** I complete the Google OAuth flow
  **Then** an account is created (or linked if email already exists) and I land on the next onboarding step.

- **Given** the OAuth provider returns an error
  **When** I am redirected back
  **Then** I see a descriptive error and a fallback option to sign up with email.

## Notes
Apple Sign-In must support the relay email option. Linking to an existing email account must require a confirmation step.
