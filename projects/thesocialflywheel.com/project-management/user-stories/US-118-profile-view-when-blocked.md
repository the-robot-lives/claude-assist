---
id: US-118
title: "Limit profile view when viewer is blocked"
slug: profile-view-when-blocked
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, safety, privacy]
---

# US-118: Limit Profile View When Viewer Is Blocked

## User Story

**As a** cautious newcomer
**I want to** ensure users I have blocked cannot view my profile
**So that** I stay protected from unwanted contact and visibility

## Acceptance Criteria

- **Given** I have blocked a user
  **When** they attempt to view my profile
  **Then** they see a restricted state that does not reveal my profile details

- **Given** a block cascade is enabled
  **When** the blocked user's close mutuals attempt to view my profile
  **Then** the cascade-defined restriction is applied to them as well

## Notes
The restricted state should not disclose that a block is the cause.
