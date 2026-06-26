---
id: US-718
title: "Configure Granular Notification Preferences for Moot Events"
slug: granular-prefs-moot-events
personas: [P-010]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [preferences, granular, mutuals, notifications]
---

# US-718: Configure Granular Notification Preferences for Moot Events

## User Story

**As a** Skeptical Switcher
**I want to** independently toggle notifications for each moot-related event
**So that** I receive only the social signals that matter to me

## Acceptance Criteria

- **Given** I am in notification preferences and expand the "Moots" section
  **When** the section expands
  **Then** I see individual toggles for: Request received, Request accepted, Moot removed — each with push and in-app sub-options

- **Given** I disable "Request received" push but leave in-app enabled
  **When** someone sends me a moot request
  **Then** no push notification fires but the event appears in the notification center

## Notes
Each toggle should include a one-line description explaining what event triggers it.
