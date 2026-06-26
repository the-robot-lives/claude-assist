---
id: US-185
title: "Configure Channel Notification Settings"
slug: channel-notification-settings
personas: [P-006]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, notifications, settings, quiet]
---

# US-185: Configure Channel Notification Settings

## User Story

**As a** Quiet Consumer
**I want to** configure per-channel notification preferences (all, mentions only, none)
**So that** I receive alerts only for the interactions I actually care about across all the channels I belong to

## Acceptance Criteria

- **Given** I open a channel's settings from my channels list
  **When** I navigate to "Notifications"
  **Then** I can select from: "All Activity," "Mentions & Replies Only," or "None"

- **Given** I select "Mentions & Replies Only"
  **When** another member mentions my handle or replies to my post in that channel
  **Then** I receive a notification, but general channel activity does not trigger any alert

## Notes
Notification settings are per-channel and per-device. Changes take effect immediately. The global notification setting (platform level) is the fallback when no channel-specific setting has been configured.
