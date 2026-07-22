---
id: US-001
title: "Create an account with password or OAuth"
slug: create-an-account-with-password-or-oauth
personas: [P-001]
epic: "Onboarding & Identity"
priority: must-have
complexity: medium
tags: [signup, auth, oauth]
---

# US-001: Create an Account with Password or OAuth

## User Story

**As a** solo staff engineer standing up a self-hosted instance
**I want to** create my account with either an email/password or an OAuth provider (GitHub/Google)
**So that** I can get into the workspace using whichever credential I already trust, without the system forcing one auth path

## Acceptance Criteria

- **Given** a fresh Noizu Intellect instance with no accounts yet
  **When** I submit a valid email and password on the signup form
  **Then** an account is created, my email is queued for verification, and I land on the first-run org/project setup flow

- **Given** the instance has an OAuth provider (GitHub or Google) configured by the admin
  **When** I choose "Continue with GitHub/Google" and complete the provider's consent screen
  **Then** an account is created (or linked, if the email already exists) without a password being set, and I land on the same first-run setup flow as a password signup

- **Given** I already have a password account
  **When** I later authenticate via OAuth using the same verified email
  **Then** the OAuth identity is linked to my existing account rather than creating a duplicate

- **Given** I submit a password shorter than the configured minimum or a malformed email
  **Then** the form rejects the submission inline with a specific error and no account row is created

## Notes
Account identity is distinct from the "Agent" entity concept — a human account here is the root identity a member later attaches to org membership rows. First password vs. OAuth choice should not gate which epics/features are available downstream. Duplicate-email linking should log an audit event for [[Ken Watanabe / P-007]]-style review later, even though this story doesn't build the audit UI.
