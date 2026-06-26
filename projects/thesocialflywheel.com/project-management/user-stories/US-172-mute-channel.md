---
id: US-172
title: "Mute a Channel"
slug: mute-channel
personas: [P-006]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, mute, notifications, feed]
---

# US-172: Mute a Channel

## User Story

**As a** Quiet Consumer
**I want to** mute a channel I'm a member of
**So that** its posts stop appearing in my main feed and I stop receiving notifications without having to leave the community

## Acceptance Criteria

- **Given** I am a member of a channel
  **When** I open the channel menu and select "Mute Channel"
  **Then** the channel's posts are removed from my main feed and all notifications from it are silenced

- **Given** I have muted a channel
  **When** I visit my channels list
  **Then** the channel is still visible in my list with a muted icon indicator, allowing me to visit it intentionally

## Notes
Muting is distinct from leaving (US-155) — the user remains a member and their posts within the channel are unchanged. Muted channels should appear at the bottom of the channels sidebar, below active channels.
