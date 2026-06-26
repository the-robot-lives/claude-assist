---
id: US-703
title: "Notify User of New Swipe Match"
slug: new-swipe-match
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: low
tags: [swipe-to-match, notifications, matching]
---

# US-703: Notify User of New Swipe Match

## User Story

**As a** Social Connector
**I want to** receive a notification the moment a swipe match is formed (both parties expressed interest)
**So that** I can capitalize on the momentum and start a conversation while interest is high

## Acceptance Criteria

- **Given** I swiped right on a user who has also swiped right on me
  **When** the mutual interest is detected
  **Then** I receive a high-priority push notification reading "You matched with [Name]! Say hello."

- **Given** I tap the match notification
  **When** the app opens
  **Then** I land on a new conversation thread pre-loaded with the matched user's profile card

## Notes
Match notifications are high-priority and exempt from batching but still respect do-not-disturb.
