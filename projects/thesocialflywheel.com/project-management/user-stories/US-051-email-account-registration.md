---
id: US-051
title: "Email Account Registration"
slug: email-account-registration
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [registration, email, onboarding]
---

# US-051: Email Account Registration

## User Story

**As a** cautious newcomer
**I want to** register with my email address and a chosen password
**So that** I can create an account without linking any third-party service

## Acceptance Criteria

- **Given** I am on the sign-up page
  **When** I submit a valid email, a password meeting strength requirements, and confirm the password
  **Then** a verification email is sent and I am shown a confirmation screen

- **Given** I submit an email already registered
  **When** I attempt to create the account
  **Then** I see an error message that does not confirm whether the email exists (to prevent enumeration)

## Notes
Verification email must expire after 24 hours. Unverified accounts cannot post.
