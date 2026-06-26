---
id: US-329
title: "Disable Opposing-View Lane for a Specific Channel"
slug: disable-lane-per-channel
personas: [P-005]
epic: "Opposing-Views Lane"
priority: should-have
complexity: low
tags: [opposing-views, channel, settings, opt-out]
---

# US-329: Disable Opposing-View Lane for a Specific Channel

## User Story

**As a** debate seeker
**I want to** turn off the Opposing-Views Lane for individual channels where I prefer a focused same-view discussion
**So that** I can curate my experience channel by channel without affecting other channels

## Acceptance Criteria

- **Given** I open channel settings
  **When** I toggle "Opposing-Views Lane" to off for this channel
  **Then** the lane disappears in this channel only and other channels are unaffected

- **Given** the lane is disabled for channel C
  **When** I enter channel C
  **Then** no opposing-view section appears in the feed layout

## Notes
Per-channel opt-out is independent of the global opt-out. Re-enabling the global opt-out does not override a channel-level disable.
