---
id: US-500
title: "Receive a notification when a mutual posts for the first time today"
slug: mutual-first-post-today-notification
personas: [P-003, P-006]
epic: "Feed & Ranking"
priority: could-have
complexity: medium
tags: [notification, mutuals, feed, engagement]
---

# US-500: Receive a Notification When a Mutual Posts for the First Time Today

## User Story

**As a** social connector (P-003)
**I want to** optionally receive a daily digest notification when mutuals I haven't seen post recently have new content
**So that** I don't miss posts from close friends who post infrequently

## Acceptance Criteria

- **Given** I enable "Daily mutual digest" notifications
  **When** a mutual I follow posts their first post of the day
  **Then** I receive a push notification summarising up to 3 mutuals' new posts (batched, not one-per-post)

- **Given** the digest fires
  **When** I tap the notification
  **Then** the app opens to the home feed scrolled to the first unread mutual post

- **Given** I have disabled all notifications
  **When** a mutual posts
  **Then** no push notification is sent; the new-post indicator in the feed (US-463) is the only signal

## Notes
Digest notifications are capped at once per day per user regardless of mutual activity volume.
