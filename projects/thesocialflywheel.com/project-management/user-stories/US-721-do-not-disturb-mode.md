---
id: US-721
title: "Enable Manual Do-Not-Disturb Mode"
slug: do-not-disturb-mode
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: low
tags: [do-not-disturb, notifications, focus]
---

# US-721: Enable Manual Do-Not-Disturb Mode

## User Story

**As a** Quiet Consumer
**I want to** toggle an on-demand do-not-disturb mode independently of scheduled quiet hours
**So that** I can silence all notifications instantly when I need focused time

## Acceptance Criteria

- **Given** I enable do-not-disturb manually from settings or the app header
  **When** DND activates
  **Then** all push notifications are suppressed immediately and a DND indicator appears in the app header

- **Given** DND is active with an optional expiry time set
  **When** the timer expires
  **Then** notifications automatically resume and I receive a brief summary of what arrived during DND

## Notes
DND is distinct from quiet hours. When both are active simultaneously, DND takes precedence.
