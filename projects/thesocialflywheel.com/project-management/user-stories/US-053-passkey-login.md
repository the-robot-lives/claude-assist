---
id: US-053
title: "Passkey Login"
slug: passkey-login
personas: [P-008]
epic: "Authentication & Security"
priority: should-have
complexity: high
tags: [passkey, webauthn, accessibility, login]
---

# US-053: Passkey Login

## User Story

**As an** accessibility-first user
**I want to** log in using a passkey stored on my device or hardware key
**So that** I can authenticate without typing a password

## Acceptance Criteria

- **Given** I have previously registered a passkey
  **When** I select "Use passkey" on the login screen and complete the device prompt
  **Then** I am authenticated and redirected to my home feed

- **Given** my device does not support WebAuthn
  **When** I visit the login screen
  **Then** the passkey option is hidden and only email/social options are shown
