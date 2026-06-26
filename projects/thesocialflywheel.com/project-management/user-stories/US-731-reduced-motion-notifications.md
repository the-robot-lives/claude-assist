---
id: US-731
title: "Respect Reduced Motion Preferences in Notification Animations"
slug: reduced-motion-notifications
personas: [P-001]
epic: "Notifications"
priority: must-have
complexity: low
tags: [accessibility, reduced-motion, a11y, notifications]
---

# US-731: Respect Reduced Motion Preferences in Notification Animations

## User Story

**As a** Bridge Builder with vestibular sensitivities
**I want to** have notification toasts and banners animate without distracting motion effects
**So that** I can receive notifications without triggering discomfort or disorientation

## Acceptance Criteria

- **Given** I have "Reduce Motion" enabled at the OS level
  **When** an in-app notification toast appears or dismisses
  **Then** the toast fades in and out (opacity transition only) with no slide, bounce, or scale animation

- **Given** I have the app's built-in reduced motion preference enabled
  **When** the notification center loads or updates
  **Then** list additions and removals use a simple opacity crossfade rather than positional slide animations

## Notes
Reduced motion preference in-app overrides any platform default and is persisted to the user's profile so it works across devices.
