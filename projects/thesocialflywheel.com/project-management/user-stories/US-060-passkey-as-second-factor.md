---
id: US-060
title: "Passkey as Second Factor"
slug: passkey-as-second-factor
personas: [P-008]
epic: "Authentication & Security"
priority: should-have
complexity: high
tags: [2fa, passkey, webauthn, accessibility]
---

# US-060: Passkey as Second Factor

## User Story

**As an** accessibility-first user
**I want to** use a passkey or hardware security key as my second authentication factor
**So that** I can complete 2FA without relying on SMS or typing codes

## Acceptance Criteria

- **Given** I have registered a security key in Security Settings
  **When** I log in with password and am prompted for 2FA
  **Then** I can tap or insert my security key to complete authentication

- **Given** my security key is unavailable
  **When** I am at the 2FA prompt
  **Then** I can fall back to TOTP or backup codes
