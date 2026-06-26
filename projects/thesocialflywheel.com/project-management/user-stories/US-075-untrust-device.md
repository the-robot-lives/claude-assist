---
id: US-075
title: "Untrust a Device"
slug: untrust-device
personas: [P-010]
epic: "Authentication & Security"
priority: should-have
complexity: low
tags: [trusted-devices, security, session-management]
---

# US-075: Untrust a Device

## User Story

**As a** skeptical switcher
**I want to** remove a device from my trusted devices list
**So that** future logins from that device require 2FA again

## Acceptance Criteria

- **Given** I view my trusted devices list in Security Settings
  **When** I click "Remove trust" on a device and confirm
  **Then** the device is removed from the list and the next login from that device will require 2FA
