---
id: US-388
title: "Manually Trigger Rotation Reset"
slug: manually-trigger-rotation-reset
personas: [P-002]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, rotation, controls]
---

# US-388: Manually Trigger Rotation Reset

## User Story

**As a** Niche Enthusiast
**I want to** manually trigger a rotation reset before the monthly schedule
**So that** I can refresh my discovery topics when I feel the current set has become stale

## Acceptance Criteria

- **Given** I navigate to Discovery Settings
  **When** I tap "Reset Rotation Now"
  **Then** the engine computes a new adjacent topic set as if the monthly event had fired and a confirmation message is shown

- **Given** I trigger a manual rotation reset
  **When** the next scheduled monthly rotation would have occurred
  **Then** the monthly schedule continues from the date of my manual reset (i.e., next auto-rotation is one month after my manual reset, not the original calendar date)

## Notes
Manual reset is limited to once every 7 days to prevent abuse of the rotation mechanism.
