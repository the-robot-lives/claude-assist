---
id: US-659
title: "Timeout User from Channel"
slug: timeout-user-from-channel
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [moderation, mod-actions, timeout]
---

# US-659: Timeout User from Channel

## User Story

**As a** channel moderator
**I want to** apply a time-limited posting restriction to a user within my channel
**So that** disruptive behaviour is paused without permanently removing the member

## Acceptance Criteria

- **Given** I select "Timeout" on a channel member
  **When** I choose a duration (1 hour, 24 hours, 7 days, custom) and confirm
  **Then** the user's ability to post or react in that channel is suspended for the selected period while they retain read access

- **Given** a timeout is active
  **When** the user attempts to post
  **Then** they see a clear message stating the timeout duration and expiry time

- **Given** a timeout expires
  **When** the clock reaches the end time
  **Then** posting rights are automatically restored with no additional mod action required

## Notes
Timeouts are channel-scoped only; the user retains full access to all other channels.
