---
id: US-036
title: "Set Notification Preferences During Onboarding"
slug: set-notification-preferences-onboarding
personas: [P-004, P-006, P-008]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [notifications, preferences, onboarding]
---

# US-036: Set Notification Preferences During Onboarding

## User Story

**As a** cautious newcomer
**I want to** choose which types of notifications I receive before they start arriving
**So that** my device is not overwhelmed from day one

## Acceptance Criteria

- **Given** I am on the notification preferences step
  **When** I toggle off "New mutual request"
  **Then** I will not receive push notifications for that event type.

- **Given** I deny push notification permission at the OS level
  **When** onboarding resumes
  **Then** the in-app notification preferences screen still saves my choices for future use if I grant permission later.

## Notes
Offer coarse presets ("Essential only", "Balanced", "All") plus a custom toggle list. Default to "Balanced". Notification preferences are editable in settings at any time.
