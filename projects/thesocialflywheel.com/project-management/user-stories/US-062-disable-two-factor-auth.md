---
id: US-062
title: "Disable Two-Factor Authentication"
slug: disable-two-factor-auth
personas: [P-010]
epic: "Authentication & Security"
priority: must-have
complexity: low
tags: [2fa, security, settings]
---

# US-062: Disable Two-Factor Authentication

## User Story

**As a** skeptical switcher
**I want to** disable two-factor authentication from my security settings
**So that** I can remove it if I change how I manage account security

## Acceptance Criteria

- **Given** 2FA is currently enabled
  **When** I choose to disable it and re-authenticate with my password and current 2FA code
  **Then** 2FA is turned off and I receive an email notification of the change

- **Given** I attempt to disable 2FA without providing a valid 2FA code
  **When** I submit the form
  **Then** the request is rejected and 2FA remains active
