---
id: US-723
title: "Group Notifications by Channel in Notification Center"
slug: smart-notification-grouping
personas: [P-010]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [grouping, notification-center, channel]
---

# US-723: Group Notifications by Channel in Notification Center

## User Story

**As a** Skeptical Switcher
**I want to** see my notifications grouped by channel or type in the notification center
**So that** I can triage activity channel-by-channel rather than through a flat chronological list

## Acceptance Criteria

- **Given** I switch the notification center to "grouped" view
  **When** the view renders
  **Then** notifications are displayed in collapsible groups by channel/source, each with a count badge

- **Given** I expand a group
  **When** it opens
  **Then** individual notifications are shown in reverse chronological order and each can be acted on inline

## Notes
"Grouped" and "Timeline" views are equally accessible via a toggle at the top of the notification center.
