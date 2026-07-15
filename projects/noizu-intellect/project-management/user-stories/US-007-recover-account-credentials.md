---
id: US-007
title: "Recover account credentials"
slug: recover-account-credentials
personas: [P-001]
epic: "Onboarding & Identity"
priority: should-have
complexity: low
tags: [recovery, password-reset, auth]
---

# US-007: Recover Account Credentials

## User Story

**As a** solo staff engineer who forgot my password
**I want to** request a password reset link by email and set a new password without losing my org memberships or agents
**So that** a forgotten credential doesn't lock me out of a workspace I've already invested setup time into

## Acceptance Criteria

- **Given** I am logged out and click "forgot password" with a valid, verified account email
  **When** I submit the email
  **Then** a signed, single-use reset link is emailed with a short TTL (default 1 hour), and the response is identical whether or not the email exists (no account enumeration)

- **Given** I follow a valid, unexpired reset link
  **When** I submit a new password meeting the minimum policy
  **Then** the password is updated, all other active sessions are invalidated per [[US-006]], and I am logged into a fresh session on the device I completed the reset from

- **Given** my account was created via OAuth only (no password ever set)
  **When** I request a password reset
  **Then** I'm told the account has no password and offered the OAuth sign-in path instead, rather than silently failing or creating a password that bypasses the OAuth link

- **Given** a reset link has expired or was already used
  **When** I try to use it again
  **Then** I get a clear expired/invalid message and a fresh "forgot password" entry point, with no partial state change to the account

## Notes
Enumeration-safe response (same message regardless of email existing) is a hard requirement, not a nice-to-have, given this is a self-hosted product that may sit on a public domain.
