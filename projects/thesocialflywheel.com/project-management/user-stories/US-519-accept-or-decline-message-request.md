---
id: US-519
title: "Accept or Decline Message Request"
slug: accept-or-decline-message-request
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [message-request, safety, new-mutuals]
---

# US-519: Accept or Decline Message Request

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** review and explicitly accept or decline a first-message request from a new mutual
**So that** I control who can start a conversation with me

## Acceptance Criteria

- **Given** a new mutual sends me a first message
  **When** I open my Message Requests inbox
  **Then** I see a preview of the sender's name, avatar, and the first line of their message, with Accept and Decline buttons

- **Given** I tap "Accept"
  **When** the action is confirmed
  **Then** the full DM thread opens and the sender can continue messaging normally

- **Given** I tap "Decline"
  **When** the action is confirmed
  **Then** the request is dismissed, the thread is not created, and the sender is not notified of the decline

## Notes
Declined senders are not blocked; they can still follow in the Mutuals lane but cannot send another message request for 7 days.
