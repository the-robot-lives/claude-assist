---
id: US-044
title: "Onboarding Progress Persists Across Devices"
slug: onboarding-progress-persists-across-devices
personas: [P-004, P-010]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: medium
tags: [cross-device, persistence, onboarding]
---

# US-044: Onboarding Progress Persists Across Devices

## User Story

**As a** new user who started onboarding on mobile and switched to desktop
**I want to** my onboarding progress to be available on the new device
**So that** I do not repeat steps already done

## Acceptance Criteria

- **Given** I completed 4 of 7 onboarding steps on my phone
  **When** I log in on desktop web
  **Then** I land on step 5 with steps 1–4 marked complete.

- **Given** I complete the remaining steps on desktop
  **When** I later open the mobile app
  **Then** the checklist reflects all steps complete.

## Notes
Onboarding state is stored server-side against the account, not the device. Conflicting partial states (e.g. different interests selected on each device) resolve to the most recently saved version.
