---
id: US-343
title: "Channel Moderator Can Disable Lane for Their Channel"
slug: moderator-disable-lane-for-channel
personas: [P-007]
epic: "Opposing-Views Lane"
priority: should-have
complexity: medium
tags: [opposing-views, moderation, channel, moderator-control]
---

# US-343: Channel Moderator Can Disable Lane for Their Channel

## User Story

**As a** channel moderator
**I want to** disable the Opposing-Views Lane entirely for my channel
**So that** I can protect channel members from opposing-view exposure when my channel's topic is particularly sensitive or community-focused

## Acceptance Criteria

- **Given** I am a moderator of channel C
  **When** I open channel moderation settings
  **Then** I have the option to disable the Opposing-Views Lane for channel C

- **Given** the lane is disabled at channel level
  **When** any member views channel C
  **Then** the Opposing-Views Lane is absent regardless of each member's individual lane settings

## Notes
Channel-level disable is absolute and cannot be overridden by individual member settings. Platform admins retain the ability to override channel moderator decisions.
