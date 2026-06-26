---
id: US-735
title: "Opt Out of Specific Notification Types Entirely"
slug: opt-out-notification-types
personas: [P-010]
epic: "Notifications"
priority: must-have
complexity: low
tags: [opt-out, preferences, notifications, control]
---

# US-735: Opt Out of Specific Notification Types Entirely

## User Story

**As a** Skeptical Switcher
**I want to** completely disable specific categories of notifications across all channels (push, email, in-app)
**So that** I have full control over my notification experience without needing to manage each channel separately

## Acceptance Criteria

- **Given** I am in notification preferences and disable a notification category (e.g., "Reactions")
  **When** I save the preference
  **Then** no push, email, or in-app notification is generated for reaction events from that point on

- **Given** I have a category disabled
  **When** I re-enable it
  **Then** notifications for that category resume immediately; no backfill of missed events is sent

## Notes
The UI should present a "master switch" per category that collapses per-channel controls when turned off.
