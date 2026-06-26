---
id: US-349
title: "Opposing-View Notification Digest (Not Real-Time)"
slug: opposing-view-notification-digest
personas: [P-006]
epic: "Opposing-Views Lane"
priority: could-have
complexity: medium
tags: [opposing-views, notifications, digest, quiet-consumer]
---

# US-349: Opposing-View Notification Digest (Not Real-Time)

## User Story

**As a** quiet consumer
**I want to** receive a periodic digest notification when new opposing-view posts are available in my lane rather than real-time alerts
**So that** I can check in on my own schedule without being interrupted during the day

## Acceptance Criteria

- **Given** new opposing-view posts have appeared in my lane since my last visit
  **When** the digest schedule triggers (e.g. once daily)
  **Then** I receive a single notification summarising "X new opposing-view posts on your interests"

- **Given** I have opted out of the Opposing-Views Lane
  **When** the digest schedule runs
  **Then** no digest notification is sent

## Notes
Digest frequency must be user-configurable (daily, weekly, never). Real-time push notifications for opposing-view content must not be sent regardless of this setting.
