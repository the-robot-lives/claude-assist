---
id: US-739
title: "Receive Push Notifications in Desktop Browser"
slug: desktop-push-notification
personas: [P-003]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [push-notifications, desktop, web, browser]
---

# US-739: Receive Push Notifications in Desktop Browser

## User Story

**As a** Social Connector who uses Flywheel Social on a desktop browser
**I want to** receive push notifications via the browser's native Web Push API
**So that** I stay connected to social activity even when the app tab is not in focus

## Acceptance Criteria

- **Given** I have granted browser notification permission on desktop
  **When** a high-priority event occurs (DM, moot match, mention)
  **Then** a native browser notification appears on my desktop with the event summary and an action button

- **Given** I click the browser notification
  **When** the action fires
  **Then** the Flywheel Social tab is focused (or opened if closed) and I am navigated to the relevant content

## Notes
Web Push requires HTTPS. Gracefully degrade to in-app-only notification for browsers that block Web Push (Firefox strict mode, Safari pre-16.1).
