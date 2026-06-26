---
id: US-548
title: "Slow Mode Limits Post Frequency"
slug: slow-mode-limits-post-frequency
personas: [P-007]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: medium
tags: [slow-mode, moderation, channel-chat, spam-prevention]
---

# US-548: Slow Mode Limits Post Frequency

## User Story

**As a** Channel Moderator (P-007)
**I want to** enable slow mode on a channel to restrict how frequently any individual member can post
**So that** I can prevent spam floods during high-traffic events

## Acceptance Criteria

- **Given** I open channel settings and enable Slow Mode with a cooldown of 30 seconds
  **When** a member sends a message
  **Then** their compose field is disabled for 30 seconds with a countdown timer visible

- **Given** slow mode is active
  **When** I (the moderator) send a message
  **Then** the cooldown does not apply to moderators or channel admins

- **Given** I change the slow mode interval from 30 seconds to 5 minutes
  **When** a member who is mid-cooldown sees the change
  **Then** their remaining cooldown resets to the new interval from the moment of their last send

## Notes
Available intervals: 5 s, 10 s, 30 s, 1 min, 5 min, 15 min, 1 hour. Disabling slow mode removes all cooldowns immediately.
