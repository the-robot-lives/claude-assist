---
id: US-058
title: "TOTP Two-Factor Authentication Setup"
slug: totp-two-factor-setup
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [2fa, totp, security]
---

# US-058: TOTP Two-Factor Authentication Setup

## User Story

**As a** skeptical switcher
**I want to** enable time-based one-time password (TOTP) two-factor authentication
**So that** my account requires both my password and my authenticator app to log in

## Acceptance Criteria

- **Given** I navigate to Security Settings
  **When** I select "Enable Authenticator App" and scan the QR code in my authenticator app
  **Then** I must enter a valid 6-digit code to confirm setup before 2FA is activated

- **Given** 2FA is enabled
  **When** I log in with correct credentials
  **Then** I am prompted for a TOTP code before gaining access
