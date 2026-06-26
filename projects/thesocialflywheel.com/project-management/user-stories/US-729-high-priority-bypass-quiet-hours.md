---
id: US-729
title: "Allow High-Priority Notifications to Bypass Quiet Hours"
slug: high-priority-bypass-quiet-hours
personas: [P-003]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [priority, quiet-hours, notifications, override]
---

# US-729: Allow High-Priority Notifications to Bypass Quiet Hours

## User Story

**As a** Social Connector
**I want to** optionally allow high-priority notifications (new moot matches, direct messages) to bypass my quiet hours
**So that** I do not miss time-sensitive social events even during my usual sleep window

## Acceptance Criteria

- **Given** quiet hours are active and I have "high-priority bypass" enabled
  **When** a high-priority event occurs (DM from moot, swipe match)
  **Then** a push notification is delivered immediately despite quiet hours being active

- **Given** quiet hours are active and I have "high-priority bypass" disabled
  **When** any notification arrives regardless of priority
  **Then** all notifications are held until quiet hours end

## Notes
"High-priority bypass" is opt-in and off by default so quiet hours are respected unless the user explicitly chooses otherwise.
