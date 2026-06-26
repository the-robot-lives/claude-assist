---
id: US-733
title: "Send Email When Push Notification Fails to Deliver"
slug: push-failure-email-fallback
personas: [P-006]
epic: "Notifications"
priority: could-have
complexity: medium
tags: [push-notifications, email, fallback, reliability]
---

# US-733: Send Email When Push Notification Fails to Deliver

## User Story

**As a** Quiet Consumer who prefers minimal notifications
**I want to** receive a fallback email for critical events if push delivery fails
**So that** I am not silently left out of important social events due to technical failure

## Acceptance Criteria

- **Given** a push notification token is expired or revoked (device unregistered)
  **When** a high-priority event occurs
  **Then** the system detects the failed push delivery and queues an email notification within 5 minutes

- **Given** the user re-registers their push token (reinstalls app)
  **When** they first open the app
  **Then** any pending email-fallback notifications that have not yet been sent are cancelled and delivered in-app instead

## Notes
Email fallback emails should use a minimal plain-text template to maximise deliverability across email clients.
