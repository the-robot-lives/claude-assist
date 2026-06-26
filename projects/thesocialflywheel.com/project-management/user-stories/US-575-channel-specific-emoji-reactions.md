---
id: US-575
title: "Use Channel-Specific Emoji Reactions"
slug: channel-specific-emoji-reactions
personas: [P-007]
epic: "Reactions & Engagement"
priority: could-have
complexity: high
tags: [reactions, channels, moderation, custom-emoji]
---

# US-575: Use Channel-Specific Emoji Reactions

## User Story

**As a** Channel Moderator
**I want to** configure a supplemental emoji set for my channel
**So that** reactions reflect the channel's culture and in-group vocabulary

## Acceptance Criteria

- **Given** I am a channel moderator
  **When** I visit Channel Settings → Reactions
  **Then** I can add up to 10 custom emojis via image upload that appear in the picker for that channel only

- **Given** a custom emoji is added
  **When** any member opens the reaction picker in that channel
  **Then** the custom emoji appears in a "Channel" section at the top of the picker above the platform set

## Notes
Custom emoji are additive; the platform set is always available beneath channel emojis. Image moderation applies to all uploads. Emoji names must be unique within the channel.
