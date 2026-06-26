---
id: US-717
title: "Filter Notifications by Type in the Notification Center"
slug: notification-center-filtering
personas: [P-010]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [notification-center, filtering, in-app]
---

# US-717: Filter Notifications by Type in the Notification Center

## User Story

**As a** Skeptical Switcher
**I want to** filter my notification center by category (moots, messages, reactions, moderation)
**So that** I can quickly find the notification type I care about without scrolling through unrelated items

## Acceptance Criteria

- **Given** I am in the notification center
  **When** I select a filter chip (e.g., "Moots")
  **Then** the list is immediately narrowed to only moot-related notifications

- **Given** I apply a filter and there are no matching notifications
  **When** the filtered list renders
  **Then** I see an empty-state message explaining the filter is active and how to clear it

## Notes
Filters persist within the session but reset on next app open unless the user saves a preference.
