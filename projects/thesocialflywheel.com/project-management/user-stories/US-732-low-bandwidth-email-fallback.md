---
id: US-732
title: "Fall Back to Email Notifications on Low Bandwidth"
slug: low-bandwidth-email-fallback
personas: [P-010]
epic: "Notifications"
priority: should-have
complexity: high
tags: [low-bandwidth, email, fallback, notifications]
---

# US-732: Fall Back to Email Notifications on Low Bandwidth

## User Story

**As a** Skeptical Switcher who sometimes uses the app in low-connectivity areas
**I want to** receive email notifications for critical events when push delivery is unreliable
**So that** I do not miss important platform activity just because my connection is poor

## Acceptance Criteria

- **Given** I have email fallback enabled in notification preferences
  **When** a high-priority push notification has not been acknowledged within 15 minutes (indicating delivery failure)
  **Then** the system sends an email notification for that event to my registered email address

- **Given** the email fallback fires
  **When** I later open the app on a better connection
  **Then** the original push notification is marked delivered and the event is visible in the notification center (no duplicate in-app notification)

## Notes
Email fallback only activates for high-priority events. Low-priority events are silently dropped if push fails in low-bandwidth conditions.
