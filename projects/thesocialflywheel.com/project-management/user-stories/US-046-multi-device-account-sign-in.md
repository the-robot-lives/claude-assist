---
id: US-046
title: "Multi-Device Account Sign-In"
slug: multi-device-account-sign-in
personas: [P-010, P-004]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [multi-device, authentication, sign-in]
---

# US-046: Multi-Device Account Sign-In

## User Story

**As a** skeptical switcher
**I want to** sign into my existing account on a new device
**So that** I can use Flywheel on both my phone and laptop with the same data

## Acceptance Criteria

- **Given** I install the app on a second device
  **When** I sign in with my credentials
  **Then** all my interests, moots, and channels load on the new device within a few seconds.

- **Given** I sign in on a new device
  **When** confirmed
  **Then** I receive a security notification on previously active devices listing the new device type and approximate location.

## Notes
Do not auto-sign-out existing sessions unless the user explicitly requests it. Provide a "Sign out of all devices" option in security settings.
