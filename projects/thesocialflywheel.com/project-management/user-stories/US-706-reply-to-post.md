---
id: US-706
title: "Notify User of Reply to Their Post"
slug: reply-to-post
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: low
tags: [replies, channel, notifications]
---

# US-706: Notify User of Reply to Their Post

## User Story

**As a** Social Connector
**I want to** receive a notification when someone replies to one of my posts
**So that** I can keep conversations going and stay engaged with my audience

## Acceptance Criteria

- **Given** I have reply notifications enabled
  **When** a user replies directly to my post in a channel
  **Then** I receive a notification with the replier's handle and a preview of their reply text

- **Given** multiple users reply to the same post within a short window
  **When** the system delivers notifications
  **Then** replies are batched into a single notification reading "[N] people replied to your post in #channel-name"

## Notes
Batching threshold default is 3+ replies within 60 seconds. This is user-configurable.
