---
id: US-134
title: "Private profile viewing mode"
slug: private-profile-viewing
personas: [P-006]
epic: "Profile & Identity"
priority: could-have
complexity: high
tags: [profile, privacy]
---

# US-134: Private Profile Viewing Mode

## User Story

**As a** quiet consumer
**I want to** browse other profiles without leaving a footprint
**So that** I can explore the network privately without signaling interest or being tracked

## Acceptance Criteria

- **Given** I have enabled private viewing mode
  **When** I view another user's profile
  **Then** no "viewed by" record, notification, or analytics footprint is created for that visit

- **Given** private viewing mode is active
  **When** I navigate the network
  **Then** a persistent indicator reminds me the mode is on so I know my activity is not recorded

## Notes
Consider whether private viewing should be time-boxed or a per-session toggle to avoid users forgetting it is on.
