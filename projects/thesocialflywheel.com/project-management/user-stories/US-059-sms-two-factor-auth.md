---
id: US-059
title: "SMS Two-Factor Authentication"
slug: sms-two-factor-auth
personas: [P-004]
epic: "Authentication & Security"
priority: should-have
complexity: medium
tags: [2fa, sms, security]
---

# US-059: SMS Two-Factor Authentication

## User Story

**As a** cautious newcomer
**I want to** receive a one-time code by SMS as my second factor
**So that** I can enable 2FA without needing a separate authenticator app

## Acceptance Criteria

- **Given** I add and verify my phone number in Security Settings
  **When** I enable SMS 2FA
  **Then** login requires both my password and an SMS code sent to my verified number

- **Given** I request an SMS code during login
  **When** I do not receive it within 60 seconds
  **Then** I can request a resend without being locked out

## Notes
Warn users that SMS 2FA is less secure than TOTP or passkey 2FA.
