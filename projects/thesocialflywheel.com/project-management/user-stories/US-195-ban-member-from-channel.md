---
id: US-195
title: "Ban a Member from Channel"
slug: ban-member-from-channel
personas: [P-007]
epic: "Interest Channels"
priority: must-have
complexity: medium
tags: [channels, moderation, ban, safety]
---

# US-195: Ban a Member from Channel

## User Story

**As a** Channel Moderator
**I want to** permanently ban a member from the channel
**So that** repeat offenders cannot return and disrupt the community after being removed

## Acceptance Criteria

- **Given** I select a member in the moderator panel and choose "Ban from Channel"
  **When** I confirm the action
  **Then** the member is removed from the channel, added to the channel ban list, and cannot rejoin via any method (direct join, invite link, or approval)

- **Given** a banned member tries to join via a valid invite link
  **When** they tap "Join"
  **Then** they receive an error message stating they are not permitted to join this channel

- **Given** I want to reverse a ban
  **When** I navigate to the channel ban list in moderation settings and select "Unban"
  **Then** the member is removed from the ban list and can rejoin the channel normally

## Notes
Channel bans are channel-scoped and do not affect platform-level membership. Bans are permanent until lifted by a moderator or the owner. Ban list is visible only to moderators and the owner.
