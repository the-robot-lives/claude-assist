---
id: US-526
title: "Customize Message Notification Preferences"
slug: customize-message-notification-preferences
personas: [P-006]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [notifications, settings, customization]
---

# US-526: Customize Message Notification Preferences

## User Story

**As a** Quiet Consumer (P-006)
**I want to** individually configure notification settings for DMs, group chats, and channels
**So that** I only get alerted for conversations I genuinely care about

## Acceptance Criteria

- **Given** I open Notification Settings
  **When** I view the Message section
  **Then** I can toggle push, email, and in-app notifications independently for: all DMs, specific DMs, group chats, and channel chat mentions

- **Given** I set a channel to "Mentions only"
  **When** a message is posted in that channel
  **Then** I receive a notification only if my @handle is mentioned; all other messages are silent

- **Given** I set a DM to "Off"
  **When** new messages arrive in that thread
  **Then** no push, sound, or badge is produced for that thread alone

## Notes
Per-conversation overrides take precedence over global settings.
