---
id: US-173
title: "Configure Mute Duration for a Channel"
slug: configure-mute-duration
personas: [P-006]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, mute, notifications, settings]
---

# US-173: Configure Mute Duration for a Channel

## User Story

**As a** Quiet Consumer
**I want to** choose how long a channel stays muted (e.g., 24 hours, 1 week, indefinitely)
**So that** I can take a temporary break without forgetting to re-engage when I'm ready

## Acceptance Criteria

- **Given** I choose to mute a channel
  **When** the mute dialog appears
  **Then** I am offered duration options: 24 hours, 3 days, 1 week, and "Until I unmute it"

- **Given** I selected a timed mute
  **When** the mute duration expires
  **Then** the channel is automatically unmuted, its posts return to my feed, and I receive a brief notification that it has been re-enabled

## Notes
The mute expiry notification should be suppressible. Default duration if none is selected should be "Until I unmute it" to avoid surprises.
