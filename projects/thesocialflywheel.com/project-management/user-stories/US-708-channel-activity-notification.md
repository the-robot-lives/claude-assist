---
id: US-708
title: "Notify User of Significant Channel Activity"
slug: channel-activity-notification
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [channel, activity, notifications]
---

# US-708: Notify User of Significant Channel Activity

## User Story

**As a** Quiet Consumer
**I want to** receive a notification only when a channel I follow sees a significant spike in activity
**So that** I can join trending conversations without being spammed by every individual message

## Acceptance Criteria

- **Given** I have channel activity notifications set to "highlights only"
  **When** a channel I follow crosses its activity threshold (e.g., 20 new posts in 10 minutes)
  **Then** I receive a single notification: "#channel-name is trending — [N] new posts"

- **Given** I am in quiet hours
  **When** a channel activity notification is generated
  **Then** it is held and delivered when quiet hours end, or discarded if it is older than 2 hours

## Notes
Activity thresholds are per-channel and can be adjusted in channel settings.
