---
id: US-508
title: "Set Own Online Presence Status"
slug: set-own-online-presence-status
personas: [P-006]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [presence, privacy, settings]
---

# US-508: Set Own Online Presence Status

## User Story

**As a** Quiet Consumer (P-006)
**I want to** set my presence status to "Invisible" or a custom status
**So that** I can browse and read content without signalling that I am available for conversation

## Acceptance Criteria

- **Given** I open Privacy or Status settings
  **When** I select "Invisible"
  **Then** all mutuals see me as offline and my typing indicators are suppressed

- **Given** I set a custom status (e.g., "In a meeting 🎯")
  **When** a mutual views my profile or DM header
  **Then** the custom text is shown beneath my name instead of the default presence label

## Notes
Custom statuses expire after a user-chosen duration (1 hour, 8 hours, until cleared).
