---
id: US-264
title: "Daily Swipe Limit Notification"
slug: daily-swipe-limit-notification
personas: [P-002]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [daily-limit, notification, rate-limiting]
---

# US-264: Daily Swipe Limit Notification

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** be notified when I am approaching and when I have reached my daily swipe limit
**So that** I can pace myself and know when to return tomorrow

## Acceptance Criteria

- **Given** I have used 80% of my daily swipe quota
  **When** the next card is presented
  **Then** a subtle banner informs me that I have N swipes remaining today

- **Given** I have used all daily swipes
  **When** I attempt any swipe action
  **Then** the swipe lane is locked with a countdown showing time until reset and a dismiss option
