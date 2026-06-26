---
id: US-513
title: "Delete a Message"
slug: delete-a-message
personas: [P-007]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [delete, message-management, moderation]
---

# US-513: Delete a Message

## User Story

**As a** Channel Moderator (P-007)
**I want to** delete any message in a channel I moderate (or my own messages anywhere)
**So that** I can remove harmful or off-topic content promptly

## Acceptance Criteria

- **Given** I am a moderator viewing a channel message
  **When** I choose "Delete message" from the message context menu
  **Then** the message is removed from view for all participants and replaced with "[Message removed by moderator]"

- **Given** I delete one of my own messages in a DM or channel
  **When** the deletion is confirmed
  **Then** the message is removed entirely (no placeholder) for all parties

## Notes
Moderator deletions are logged in the moderation audit trail. Authors receive a notification that their message was removed.
