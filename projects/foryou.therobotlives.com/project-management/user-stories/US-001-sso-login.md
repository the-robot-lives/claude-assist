---
id: US-001
title: "Log in via SSO"
slug: sso-login
personas: [P-001, P-002, P-003]
epic: "Onboarding & Auth"
priority: must-have
complexity: low
tags: [auth, sso, login]
---

# US-001: Log in via SSO

## User Story

**As a** returning user
**I want to** sign in with single sign-on (SSO)
**So that** I can access my account without a separate password

## Acceptance Criteria

- **Given** I have an SSO identity
  **When** I click "Sign in with SSO" and complete the provider flow
  **Then** I am authenticated and redirected into `/app`
- **Given** SSO returns a first-time identity
  **When** authentication succeeds
  **Then** an account is created and linked to that identity
- **Given** the SSO flow fails or is cancelled
  **When** I return to foryou
  **Then** I see a clear error and remain signed out

## Notes
Backed by existing Guardian JWT + SSO auth. On success, run the signup
reconcile-by-email hook (see US-050).
