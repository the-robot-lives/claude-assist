---
id: US-644
title: "Blocked User Cannot View Your Profile"
slug: blocked-user-cannot-view-your-profile
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, blocking, privacy]
---

# US-644: Blocked User Cannot View Your Profile

## User Story

**As a** cautious newcomer
**I want to** ensure that a user I have blocked cannot view my profile page
**So that** blocking provides real profile-level privacy, not just feed filtering

## Acceptance Criteria

- **Given** I have blocked User X
  **When** User X navigates directly to my profile URL
  **Then** they see a "User not found" or generic unavailable page — identical to a non-existent account

- **Given** User X is logged out and visits my profile
  **When** the page loads
  **Then** my profile is still publicly visible (block applies only to authenticated blocked users)

## Notes
The "user not found" response must not confirm or deny that a block exists.
