---
id: US-275
title: "Match Notification on Interest Accepted"
slug: match-notification-on-interest-accepted
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [notification, match, mutuals]
---

# US-275: Match Notification on Interest Accepted

## User Story

**As a** Social Connector (P-003)
**I want to** receive a notification when someone accepts my expressed interest
**So that** I know we are now mutuals and can start engaging with each other's posts

## Acceptance Criteria

- **Given** I previously swiped right on someone
  **When** they accept my interest
  **Then** I receive an in-app notification and (if enabled) a push notification stating we are now mutuals

- **Given** I receive a match notification
  **When** I tap it
  **Then** I am taken to their profile with a "New Mutual" badge and their recent posts visible in my feed
