---
id: US-074
title: "Trusted Device Registration"
slug: trusted-device-registration
personas: [P-010]
epic: "Authentication & Security"
priority: should-have
complexity: medium
tags: [trusted-devices, 2fa, login]
---

# US-074: Trusted Device Registration

## User Story

**As a** skeptical switcher
**I want to** mark a device as trusted after completing 2FA
**So that** I am not prompted for a second factor on every login from that device

## Acceptance Criteria

- **Given** I complete a 2FA challenge successfully
  **When** I check "Trust this device for 30 days"
  **Then** subsequent logins from the same device skip 2FA for up to 30 days

- **Given** I have trusted a device
  **When** I view my trusted devices list in Security Settings
  **Then** I can see the device name and expiry date and revoke trust at any time
