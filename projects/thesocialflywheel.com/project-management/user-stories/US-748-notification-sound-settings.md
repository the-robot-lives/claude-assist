---
id: US-748
title: "Configure Notification Sound and Vibration"
slug: notification-sound-settings
personas: [P-006]
epic: "Notifications"
priority: could-have
complexity: low
tags: [notifications, sound, vibration, preferences]
---

# US-748: Configure Notification Sound and Vibration

## User Story

**As a** Quiet Consumer
**I want to** set a custom sound (or silence) for different notification priority levels
**So that** I can distinguish important notifications by sound without looking at my screen

## Acceptance Criteria

- **Given** I am in notification sound settings
  **When** I choose a sound for high-priority notifications
  **Then** subsequent high-priority push notifications play that sound on both iOS and Android

- **Given** I set low-priority notifications to "vibrate only"
  **When** a low-priority push notification arrives
  **Then** the device vibrates without playing audio

## Notes
Sound options include: Default, Chime, Ping, Silent. Custom audio upload is not supported in v1.
