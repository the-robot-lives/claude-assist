---
id: US-660
title: "Ban User from Channel"
slug: ban-user-from-channel
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [moderation, mod-actions, ban]
---

# US-660: Ban User from Channel

## User Story

**As a** channel moderator
**I want to** permanently ban a user from my channel
**So that** seriously harmful members cannot continue participating even if they delete offending content

## Acceptance Criteria

- **Given** I select "Ban from Channel" on a member
  **When** I confirm with a stated reason
  **Then** the user is immediately removed from the member list, loses read and post access, and receives a system notification citing the rule violated

- **Given** a channel ban is applied
  **When** the banned user attempts to access the channel via direct link
  **Then** they see a "You are banned from this channel" screen with an appeal link

- **Given** a channel ban is in effect
  **When** the mod reviews the member list
  **Then** a "Banned" section shows all banned accounts with ban date and reason

## Notes
Channel bans do not affect the user's ability to access the platform or other channels.
