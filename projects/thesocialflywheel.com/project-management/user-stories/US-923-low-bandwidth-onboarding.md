---
id: US-923
title: "Low-Bandwidth Onboarding Flow"
slug: low-bandwidth-onboarding
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [onboarding, bandwidth, first-run, performance]
---

# US-923: Low-Bandwidth Onboarding Flow

## User Story

**As a** skeptical switcher signing up from a device with a slow data connection
**I want to** complete account creation and initial setup without loading heavy assets
**So that** I can get into the app quickly without being blocked by slow-loading onboarding screens

## Acceptance Criteria

- **Given** I am onboarding for the first time on a connection below 1 Mbps
  **When** I progress through onboarding steps
  **Then** each onboarding screen loads under 2 seconds with text-first layout and deferred decorative images

- **Given** the onboarding flow asks me to choose interest channels
  **When** the channel list renders
  **Then** channel icons load lazily as I scroll and channel names display immediately as text

## Notes
Strip all animations from onboarding for connections below 1 Mbps. Onboarding total data budget: < 500 KB for the critical path.
