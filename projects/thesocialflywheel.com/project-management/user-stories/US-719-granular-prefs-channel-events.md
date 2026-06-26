---
id: US-719
title: "Configure Granular Notification Preferences for Channel Events"
slug: granular-prefs-channel-events
personas: [P-006]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [preferences, granular, channel, notifications]
---

# US-719: Configure Granular Notification Preferences for Channel Events

## User Story

**As a** Quiet Consumer
**I want to** control channel notifications at a per-event-type level
**So that** I can follow many channels without being overwhelmed by notifications I do not want

## Acceptance Criteria

- **Given** I open notification preferences and select a specific channel
  **When** the channel settings load
  **Then** I can independently configure: Mentions (all / off), Replies to my posts (on / off), Activity spikes (on / off), All messages (on / off)

- **Given** I set a channel to "mentions only"
  **When** a regular (non-mention) message is posted
  **Then** no notification is generated for me for that message

## Notes
Per-channel settings override global channel notification defaults.
