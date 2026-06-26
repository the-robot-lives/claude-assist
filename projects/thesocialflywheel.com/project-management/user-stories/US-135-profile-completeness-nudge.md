---
id: US-135
title: "Profile completeness onboarding nudge"
slug: profile-completeness-nudge
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, onboarding, identity]
---

# US-135: Profile Completeness Onboarding Nudge

## User Story

**As a** cautious newcomer
**I want to** see a gentle nudge showing what is missing from my profile after signup
**So that** I can build a complete profile at my own pace without feeling pressured

## Acceptance Criteria

- **Given** I have just signed up with an incomplete profile
  **When** I land on my home view
  **Then** a completeness indicator shows my progress and the remaining suggested steps

- **Given** I dismiss or complete a suggested step
  **When** I return later
  **Then** the nudge reflects updated progress and stops surfacing once the profile is sufficiently complete

## Notes
Nudges must be dismissible and never block usage; emphasize encouragement over urgency for cautious users.
