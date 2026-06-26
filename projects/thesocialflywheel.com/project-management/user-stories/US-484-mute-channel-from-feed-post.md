---
id: US-484
title: "Mute a channel directly from a feed post"
slug: mute-channel-from-feed-post
personas: [P-006, P-004]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [mute, channel, feed-control, quick-action]
---

# US-484: Mute a Channel Directly from a Feed Post

## User Story

**As a** quiet consumer (P-006)
**I want to** mute a channel from the context menu of any post in that channel
**So that** I can silence a noisy channel without navigating to channel settings

## Acceptance Criteria

- **Given** I long-press or tap the menu on a feed post
  **When** the action sheet appears
  **Then** a "Mute #channel-name" option is present

- **Given** I tap "Mute #channel-name"
  **When** I confirm in the prompt
  **Then** all posts from that channel vanish from the feed immediately and a toast confirms "Muted #channel-name"

- **Given** I mute a channel from the feed
  **When** I navigate to Channel Settings
  **Then** the channel shows as muted, and I can unmute it there

## Notes
Muting from the feed is a reversible soft-mute, not an unsubscription.
