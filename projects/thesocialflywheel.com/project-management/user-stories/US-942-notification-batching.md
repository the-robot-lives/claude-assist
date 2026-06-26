---
id: US-942
title: "Notification Batching to Reduce Noise and Requests"
slug: notification-batching
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [notifications, batching, performance, api-efficiency]
---

# US-942: Notification Batching to Reduce Noise and Requests

## User Story

**As a** quiet consumer who gets many likes and follows in bursts
**I want to** receive batched notification summaries rather than individual push notifications for every event
**So that** my phone isn't overwhelmed with pings and the app doesn't fire dozens of API calls at once

## Acceptance Criteria

- **Given** I receive 10 likes on a post within a 30-second window
  **When** notifications are processed
  **Then** I receive a single push notification saying "10 people liked your post" rather than 10 separate notifications

- **Given** a notification batch is delivered
  **When** I tap it
  **Then** I am taken to a notifications screen showing all individual events in the batch with timestamps

## Notes
Batch window: 30 seconds server-side before dispatch. Collapse same-event-type notifications per entity (post, follow). Real-time dot indicator on notification bell updates immediately; push notification batches.
