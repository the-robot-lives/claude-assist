---
id: US-032
title: "Forgot Password / Account Recovery"
slug: forgot-password-account-recovery
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [password, recovery, authentication]
---

# US-032: Forgot Password / Account Recovery

## User Story

**As a** returning user who forgot my password
**I want to** reset it via email or SMS
**So that** I can regain access to my account without losing my data

## Acceptance Criteria

- **Given** I tap "Forgot password" on the login screen
  **When** I enter my email or phone
  **Then** I receive a reset link or OTP within 2 minutes.

- **Given** I complete the reset flow
  **When** I set a new password and submit
  **Then** I am logged in and my onboarding progress (if incomplete) is restored.

## Notes
Reset links expire in 1 hour. Invalidate all other active sessions on password reset (with a notice to the user). Do not reveal whether an email/phone is registered — use a generic "if this account exists, you'll receive a message" pattern.
