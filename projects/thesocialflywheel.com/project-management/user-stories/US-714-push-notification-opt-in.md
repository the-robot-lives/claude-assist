---
id: US-714
title: "Prompt User to Enable Push Notifications at Right Moment"
slug: push-notification-opt-in
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: low
tags: [push-notifications, onboarding, permissions]
---

# US-714: Prompt User to Enable Push Notifications at Right Moment

## User Story

**As a** Social Connector
**I want to** be asked to enable push notifications at a meaningful moment
**So that** I understand the value before granting permission and do not feel nagged on first launch

## Acceptance Criteria

- **Given** I am a new user who has completed profile setup
  **When** I receive my first moot request
  **Then** the app displays a contextual prompt explaining what push notifications enable, before triggering the OS permission dialog

- **Given** I decline the OS push permission
  **When** I later navigate to notification settings
  **Then** I see a banner offering to reopen OS settings so I can enable push notifications manually

## Notes
Do not request push permission on first app launch. Trigger after a meaningful social event to maximise opt-in rate.
