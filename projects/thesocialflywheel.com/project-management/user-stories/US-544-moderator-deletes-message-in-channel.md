---
id: US-544
title: "Moderator Deletes Message in Channel"
slug: moderator-deletes-message-in-channel
personas: [P-007]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [moderation, delete, channel-chat, trust-and-safety]
---

# US-544: Moderator Deletes Message in Channel

## User Story

**As a** Channel Moderator (P-007)
**I want to** delete any member's message in my channel
**So that** I can quickly remove content that violates community rules

## Acceptance Criteria

- **Given** I am viewing a message in a channel I moderate
  **When** I open the message context menu and choose "Delete (Moderator)"
  **Then** the message is instantly removed for all viewers, replaced with "[Message removed by a moderator]", and the deletion is logged in the moderation audit trail

- **Given** a message has been flagged via a user report
  **When** I review it in the moderation dashboard and choose "Delete"
  **Then** the same removal applies and the reporter receives a "We took action" notification (without details)

- **Given** the author of the deleted message views the channel
  **When** they see the removal placeholder
  **Then** they receive an in-app notification: "Your message was removed by a moderator" with a link to the channel rules

## Notes
Moderator delete is non-reversible from the UI; platform admins can restore via internal tooling only.
