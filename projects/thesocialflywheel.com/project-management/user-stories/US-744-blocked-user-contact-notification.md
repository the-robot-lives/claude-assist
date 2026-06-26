---
id: US-744
title: "Notify User When a Blocked Account Attempts Contact"
slug: blocked-user-contact-notification
personas: [P-001]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [safety, blocking, notifications, trust]
---

# US-744: Notify User When a Blocked Account Attempts Contact

## User Story

**As a** Bridge Builder
**I want to** receive a low-key notification when a blocked user attempts to send me a message or moot request
**So that** I am aware of persistent contact attempts and can escalate to a report if needed

## Acceptance Criteria

- **Given** I have blocked User A
  **When** User A attempts to send me a direct message
  **Then** User A's message is silently rejected and I receive a low-priority in-app notification: "A blocked account attempted to contact you."

- **Given** multiple contact attempts occur from the same blocked user
  **When** the notifications are delivered
  **Then** they are batched into a daily summary: "[N] contact attempts from blocked accounts" rather than individual alerts

## Notes
Do not identify the blocked user in the notification to avoid inadvertently revealing block status to third parties via side channels.
