---
id: US-007
title: "Email Verification After Signup"
slug: email-verification
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: low
tags: [email, verification, signup]
---

# US-007: Email Verification After Signup

## User Story

**As a** new user
**I want to** verify my email address
**So that** my account is secured and I can recover it if I lose access

## Acceptance Criteria

- **Given** I signed up with email
  **When** I open the verification link in my inbox
  **Then** my email is marked verified and I am redirected back into the app to continue onboarding.

- **Given** I have not verified within 24 hours
  **When** I next open the app
  **Then** I see a dismissible banner with a resend option.

## Notes
Verification link expires in 72 hours. Resend is rate-limited to 3 per hour. Verified status unlocks posting in public channels.
