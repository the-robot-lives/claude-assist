---
id: US-517
title: "Mute a DM Conversation"
slug: mute-a-dm-conversation
personas: [P-006]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [mute, direct-messages, notifications, quiet]
---

# US-517: Mute a DM Conversation

## User Story

**As a** Quiet Consumer (P-006)
**I want to** mute a specific DM conversation
**So that** I stop receiving notifications from it without blocking or removing the mutual

## Acceptance Criteria

- **Given** I view a DM conversation
  **When** I open the conversation settings and choose "Mute"
  **Then** I can select a mute duration (1 hour, 8 hours, 1 week, Until I turn it off) and notifications cease for that period

- **Given** a conversation is muted
  **When** I receive new messages in it
  **Then** the thread still shows new-message indicators in the conversation list but no push/sound notification fires

- **Given** the mute period expires
  **When** the next message arrives
  **Then** normal notifications resume without any action from me

## Notes
Muting does not hide the conversation from the list, only suppresses notifications.
