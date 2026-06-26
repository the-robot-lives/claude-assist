---
id: US-148
title: "Vanity handle availability check"
slug: vanity-handle-availability-check
personas: [P-003]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, identity, handle]
---

# US-148: Vanity Handle Availability Check

## User Story

**As a** social connector
**I want to** check whether a vanity handle is available before committing to it
**So that** I can secure a memorable handle without trial-and-error rejections

## Acceptance Criteria

- **Given** I type a candidate handle
  **When** I finish entering it
  **Then** I see a real-time indicator of whether it is available, taken, or invalid

- **Given** a handle is unavailable
  **When** the check completes
  **Then** I am offered a few available alternatives close to my choice

- **Given** an available handle
  **When** I confirm it
  **Then** the handle is reserved to me and reflected across my profile

## Notes
Availability check enforces reserved-word and formatting rules in addition to uniqueness.
